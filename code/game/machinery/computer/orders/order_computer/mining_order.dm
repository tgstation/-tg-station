#define CREDIT_TYPE_MINING "mp"

/obj/machinery/computer/order_console/mining
	name = "mining equipment order console"
	desc = "An equipment shop for miners, points collected at an ore redemption machine can be spent here."
	icon = 'icons/obj/machines/mining_machines.dmi'
	icon_state = "mining"
	icon_keyboard = null
	icon_screen = null
	circuit = /obj/item/circuitboard/computer/order_console/mining
	cooldown_time = 10 SECONDS //just time to let you know your order went through.
	cargo_cost_multiplier = 0.65
	express_cost_multiplier = 1
	purchase_tooltip = @{"Your purchases will arrive at cargo,
	and hopefully get delivered by them.
	35% cheaper than express delivery."}
	express_tooltip = @{"Sends your purchases instantly."}
	credit_type = CREDIT_TYPE_MINING

	order_categories = list(
		CATEGORY_MINING,
		CATEGORY_CONSUMABLES,
		CATEGORY_TOYS_DRONE,
		CATEGORY_PKA,
	)
	blackbox_key = "mining"
	announcement_line = "A shaft miner has ordered equipment which will arrive on the cargo shuttle! Please make sure it gets to them as soon as possible!"

/obj/machinery/computer/order_console/mining/subtract_points(final_cost, obj/item/card/id/card)
	if(final_cost <= card.registered_account.mining_points)
		card.registered_account.mining_points -= final_cost
		return TRUE
	return FALSE

/obj/machinery/computer/order_console/mining/order_groceries(mob/living/purchaser, obj/item/card/id/card, list/groceries)
	var/list/things_to_order = list()
	for(var/datum/orderable_item/item as anything in groceries)
		things_to_order[item.purchase_path] = groceries[item]

	var/datum/supply_pack/custom/mining_pack = new(
		purchaser = purchaser, \
		cost = get_total_cost(), \
		contains = things_to_order,
	)
	var/datum/supply_order/disposable/new_order = new(
		pack = mining_pack,
		orderer = purchaser,
		orderer_rank = "Mining Vendor",
		orderer_ckey = purchaser.ckey,
		reason = "",
		paying_account = card.registered_account,
		department_destination = null,
		coupon = null,
		charge_on_purchase = FALSE,
		manifest_can_fail = FALSE,
		cost_type = credit_type,
		can_be_cancelled = FALSE,
	)
	say("Thank you for your purchase! It will arrive on the next cargo shuttle!")
	aas_config_announce(/datum/aas_config_entry/order_console, list(), src, list(radio_channel), capitalize(blackbox_key))
	SSshuttle.shopping_list += new_order

/obj/machinery/computer/order_console/mining/retrieve_points(obj/item/card/id/id_card)
	return round(id_card.registered_account.mining_points)

/obj/machinery/computer/order_console/mining/ui_act(action, list/params, datum/tgui/ui, datum/ui_state/state)
	. = ..()
	if(!.)
		flick("mining-deny", src)

/obj/machinery/computer/order_console/mining/attackby(obj/item/weapon, mob/user, params)
	if(istype(weapon, /obj/item/mining_voucher))
		redeem_voucher(weapon, user)
		return
	return ..()

/obj/machinery/computer/order_console/mining/update_icon_state()
	icon_state = "[initial(icon_state)][powered() ? null : "-off"]"
	return ..()


/**
 * Allows user to redeem a mining voucher for one set of a mining equipment
 *
 * * Arguments:
 * * voucher The mining voucher that is being used to redeem the mining equipment
 * * redeemer The mob that is redeeming the mining equipment
 */
/obj/machinery/computer/order_console/mining/proc/redeem_voucher(obj/item/mining_voucher/voucher, mob/redeemer)
	var/static/list/set_types
	if(!set_types)
		set_types = list()
		for(var/datum/voucher_set/static_set as anything in subtypesof(/datum/voucher_set))
			set_types[initial(static_set.name)] = new static_set

	var/list/items = list()
	for(var/set_name in set_types)
		var/datum/voucher_set/current_set = set_types[set_name]
		var/datum/radial_menu_choice/option = new
		option.image = image(icon = current_set.icon, icon_state = current_set.icon_state)
		option.info = span_boldnotice(current_set.description)
		items[set_name] = option

	var/selection = show_radial_menu(redeemer, src, items, custom_check = CALLBACK(src, PROC_REF(check_menu), voucher, redeemer), radius = 38, require_near = TRUE, tooltips = TRUE)
	if(!selection)
		return

	var/datum/voucher_set/chosen_set = set_types[selection]
	for(var/item in chosen_set.set_items)
		new item(drop_location())

	SSblackbox.record_feedback("tally", "mining_voucher_redeemed", 1, selection)
	qdel(voucher)

/**
 * Checks if we are allowed to interact with a radial menu
 *
 * * Arguments:
 * * voucher The mining voucher that is being used to redeem a mining equipment
 * * redeemer The living mob interacting with the menu
 */
/obj/machinery/computer/order_console/mining/proc/check_menu(obj/item/mining_voucher/voucher, mob/living/redeemer)
	if(!istype(redeemer))
		return FALSE
	if(redeemer.incapacitated)
		return FALSE
	if(QDELETED(voucher))
		return FALSE
	if(!redeemer.is_holding(voucher))
		return FALSE
	return TRUE

/**********************Mining Equipment Voucher**********************/

/obj/item/mining_voucher
	name = "mining voucher"
	desc = "A token to redeem a piece of equipment. Use it on a mining equipment vendor."
	icon = 'icons/obj/mining.dmi'
	icon_state = "mining_voucher"
	w_class = WEIGHT_CLASS_TINY

/**********************Mining Point Card**********************/

#define TO_USER_ID "Transfer Card → ID"
#define TO_POINT_CARD "ID → Transfer Card"

/obj/item/card/mining_point_card
	name = "mining point transfer card"
	desc = "A small, reusable card for transferring mining points. Swipe your ID card over it to start the process."
	icon_state = "data_1"

	///Amount of points this card contains.
	var/points = 0

/obj/item/card/mining_point_card/examine(mob/user)
	. = ..()
	. += span_notice("There's [points] point\s on the card.")

/obj/item/card/mining_point_card/attackby(obj/item/attacking_item, mob/user, params)
	if(!isidcard(attacking_item))
		return ..()
	var/obj/item/card/id/attacking_id = attacking_item
	balloon_alert(user, "starting transfer")
	var/point_movement = tgui_alert(user, "To ID (from card) or to card (from ID)?", "Mining Points Transfer", list(TO_USER_ID, TO_POINT_CARD))
	if(!point_movement)
		return
	var/amount = tgui_input_number(user, "How much do you want to transfer? ID Balance: [attacking_id.registered_account.mining_points], Card Balance: [points]", "Transfer Points", min_value = 0, round_value = 1)
	if(!amount)
		return
	switch(point_movement)
		if(TO_USER_ID)
			if(amount > points)
				amount = points
			attacking_id.registered_account.mining_points += amount
			points -= amount
			to_chat(user, span_notice("You transfer [amount] mining points from [src] to [attacking_id]."))
		if(TO_POINT_CARD)
			if(amount > attacking_id.registered_account.mining_points)
				amount = attacking_id.registered_account.mining_points
			attacking_id.registered_account.mining_points -= amount
			points += amount
			to_chat(user, span_notice("You transfer [amount] mining points from [attacking_id] to [src]."))

#undef CREDIT_TYPE_MINING
#undef TO_POINT_CARD
#undef TO_USER_ID
