///List of all items that can be found in the different types of order consoles, to purchase.
GLOBAL_LIST_EMPTY(order_console_products)
#define CREDIT_TYPE_CREDIT "credit"

/obj/machinery/computer/order_console
	name = "Orders Console"
	desc = "An interface for ordering specific ingredients from Cargo, with an express option at the cost of more money."
	icon_screen = "request"
	icon_keyboard = "generic_key"
	light_color = LIGHT_COLOR_ORANGE
	///Tooltip for the express button in TGUI
	var/express_tooltip = @{"Sends your purchases instantly,
	but locks the console longer and increases the price!"}
	///Tooltip for the purchase button in TGUI
	var/purchase_tooltip = @{"Your purchases will arrive at cargo,
	and hopefully get delivered by them."}

	///Cooldown between order uses.
	COOLDOWN_DECLARE(order_cooldown)
	///Cooldown time between uses, express console will have extra time depending on express_cost_multiplier.
	var/cooldown_time = 60 SECONDS
	///The channel we will attempt to speak into through our radio.
	var/radio_channel = RADIO_CHANNEL_SUPPLY
	///What line we should announce on ordering_groceries
	var/announcement_line

	///The kind of cash does the console use.
	var/credit_type = CREDIT_TYPE_CREDIT
	///Whether the console can only use express mode ONLY
	var/forced_express = FALSE
	///Multiplied cost to use for cargo mode
	var/cargo_cost_multiplier = 1
	///Multiplied cost to use for express mode
	var/express_cost_multiplier = 2
	///The categories of orderable items this console can view and purchase.
	var/list/order_categories = list()
	///The current list of things we're trying to order, waiting for checkout.
	var/list/datum/orderable_item/grocery_list = list()
	///For blackbox logging, what kind of order is this? set nothing to not tally, like golem orders
	var/blackbox_key

/obj/machinery/computer/order_console/Initialize(mapload)
	. = ..()

	if(GLOB.order_console_products.len)
		return
	for(var/datum/orderable_item/path as anything in subtypesof(/datum/orderable_item))
		if(!initial(path.purchase_path))
			continue
		GLOB.order_console_products += new path

/obj/machinery/computer/order_console/proc/get_total_cost()
	var/cost = 0
	for(var/datum/orderable_item/item as anything in grocery_list)
		cost += grocery_list[item] * item.cost_per_order
	return cost

/obj/machinery/computer/order_console/ui_interact(mob/user, datum/tgui/ui)
	. = ..()
	ui = SStgui.try_update_ui(user, src, ui)
	if(!ui)
		ui = new(user, src, "ProduceConsole", name)
		ui.open()

/**
 * points is any type of currency this machine accepts(money, mining points etc) which is displayed on the ui
 * Args:
 * card - The ID card we retrieve these points from
 */
/obj/machinery/computer/order_console/proc/retrieve_points(obj/item/card/id/id_card)
	return round(id_card.registered_account?.account_balance)

/obj/machinery/computer/order_console/ui_data(mob/user)
	var/list/data = list()
	data["total_cost"] = get_total_cost()
	data["off_cooldown"] = COOLDOWN_FINISHED(src, order_cooldown)

	for(var/datum/orderable_item/item as anything in GLOB.order_console_products)
		if(!(item.category_index in order_categories))
			continue
		data["item_amts"] += list(list(
			"name" = item.name,
			"amt" = grocery_list[item],
		))
	if(isliving(user))
		var/mob/living/living_user = user
		var/obj/item/card/id/id_card = living_user.get_idcard(TRUE)
		if(id_card)
			data["points"] = retrieve_points(id_card)

	return data

/obj/machinery/computer/order_console/ui_static_data(mob/user)
	var/list/data = list()
	data["credit_type"] = credit_type
	data["express_tooltip"] = express_tooltip
	data["purchase_tooltip"] = purchase_tooltip
	data["forced_express"] = forced_express
	data["cargo_value"] = CARGO_CRATE_VALUE
	data["cargo_cost_multiplier"] = cargo_cost_multiplier
	data["express_cost_multiplier"] = express_cost_multiplier
	data["order_categories"] = order_categories
	data["order_datums"] = list()
	for(var/datum/orderable_item/item as anything in GLOB.order_console_products)
		if(!(item.category_index in order_categories))
			continue

		data["order_datums"] += list(list(
			"name" = item.name,
			"desc" = item.desc,
			"cat" = item.category_index,
			"ref" = REF(item),
			"cost" = round(item.cost_per_order * cargo_cost_multiplier),
			"icon" = item.purchase_path::icon,
			"icon_state" = item.purchase_path::icon_state,
		))
	return data

/obj/machinery/computer/order_console/ui_act(action, list/params, datum/tgui/ui, datum/ui_state/state)
	. = ..()
	if(.)
		return
	if(!isliving(usr))
		return
	var/mob/living/living_user = usr
	switch(action)
		if("add_one")
			var/datum/orderable_item/wanted_item = locate(params["target"]) in GLOB.order_console_products
			if(grocery_list[wanted_item] >= 20)
				return
			else
				grocery_list[wanted_item] += 1
		if("remove_one")
			var/datum/orderable_item/wanted_item = locate(params["target"]) in GLOB.order_console_products
			if(!grocery_list[wanted_item])
				return
			if(grocery_list[wanted_item] < 1)
				grocery_list[wanted_item] = 0
				return
			else
				grocery_list[wanted_item] -= 1
			if(!grocery_list[wanted_item])
				grocery_list -= wanted_item
		if("cart_set")
			//this is null if the action doesn't need it (purchase, quickpurchase)
			var/datum/orderable_item/wanted_item = locate(params["target"]) in GLOB.order_console_products
			grocery_list[wanted_item] = clamp(params["amt"], 0, 20)
			if(!grocery_list[wanted_item])
				grocery_list -= wanted_item
		if("purchase")
			if(!grocery_list.len || !COOLDOWN_FINISHED(src, order_cooldown))
				return
			if(forced_express)
				return ui_act(action = "express")
			//So miners cant spam buy crates for a very low price
			if(get_total_cost() < CARGO_CRATE_VALUE)
				return

			var/obj/item/card/id/used_id_card = living_user.get_idcard(TRUE)
			if(!used_id_card || !used_id_card.registered_account)
				say("No bank account detected!")
				return
			if(!purchase_items(used_id_card))
				return
			if(blackbox_key)
				SSblackbox.record_feedback("tally", "non_express_[blackbox_key]_order", 1, name)
			order_groceries(living_user, used_id_card, grocery_list)
			grocery_list.Cut()
			COOLDOWN_START(src, order_cooldown, cooldown_time)
		if("express")
			if(!grocery_list.len || !COOLDOWN_FINISHED(src, order_cooldown))
				return
			var/obj/item/card/id/used_id_card = living_user.get_idcard(TRUE)
			if(!used_id_card || !used_id_card.registered_account)
				say("No bank account detected!")
				return
			if(!purchase_items(used_id_card, express = TRUE))
				return
			var/say_message = "Thank you for your purchase!"
			if(express_cost_multiplier > 1)
				say_message += " Please note: The charge of this purchase and machine cooldown has been multiplied by [express_cost_multiplier]!"
			COOLDOWN_START(src, order_cooldown, cooldown_time * express_cost_multiplier)
			say(say_message)
			if(blackbox_key)
				SSblackbox.record_feedback("tally", "express_[blackbox_key]_order", 1, name)
			var/list/ordered_paths = list()
			for(var/datum/orderable_item/item as anything in grocery_list)//every order
				if(!(item.category_index in order_categories))
					stack_trace("[src] somehow delivered [item] which is not purchasable at this order console.")
					grocery_list.Remove(item)
					continue
				for(var/amt in 1 to grocery_list[item])//every order amount
					ordered_paths += item.purchase_path
			podspawn(list(
				"target" = get_turf(living_user),
				"style" = /datum/pod_style/advanced,
				"spawn" = ordered_paths,
			))
			grocery_list.Cut()
	return TRUE

/**
 * Checks if an ID card is able to afford the total cost of the current console's groceries
 * and deducts the cost if they can.
 * Args:
 * card - The ID card we check for balance
 * express - Boolean on whether we need to add the express cost mulitplier
 * returns TRUE if we can afford, FALSE otherwise.
 */
/obj/machinery/computer/order_console/proc/purchase_items(obj/item/card/id/card, express = FALSE)
	var/final_cost = round(get_total_cost() * (express ? express_cost_multiplier : cargo_cost_multiplier))
	if(subtract_points(final_cost, card))
		return TRUE
	say("Sorry, but you do not have enough [credit_type].")
	return FALSE

/**
 * whatever type of points was retrieved in retrieve_points() subtract those type of points from the card upon confirming order
 * Args:
 * final_cost - amount of points to subtract from this card
 * card - The ID card to subtract these points from
 * returns TRUE if successfull
 */
/obj/machinery/computer/order_console/proc/subtract_points(final_cost, obj/item/card/id/card)
	return card.registered_account.adjust_money(-final_cost, "[name]: Purchase")

/**
 * start of the shipment of your order
 * Args:
 * purchaser - The mob who is making this purchase
 * card - The card used to place this order
 * groceries - the list of orders to be placed
 */
/obj/machinery/computer/order_console/proc/order_groceries(mob/living/purchaser, obj/item/card/id/card, list/groceries)
	return

/datum/aas_config_entry/order_console
	name = "Local Ordering Console Announcements"
	announcement_lines_map = list()
	general_tooltip = "Used to make announces, when consoles listed here placing new order"

/datum/aas_config_entry/order_console/New()
	. = ..()
	for(var/obj/machinery/computer/order_console/subconsole as anything in subtypesof(/obj/machinery/computer/order_console))
		if(subconsole.blackbox_key)
			announcement_lines_map[capitalize(subconsole.blackbox_key)] = subconsole.announcement_line

/datum/aas_config_entry/order_console/compile_announce(list/variables_map, announcement_line)
	if (!announcement_lines_map.len)
		announcement_lines_map["Error"] = "Unknown Error happened, while we tried to procceed an order, please report this to Nanotrasen."
	. = ..()


#undef CREDIT_TYPE_CREDIT
