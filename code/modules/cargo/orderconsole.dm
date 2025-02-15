/obj/machinery/computer/cargo
	name = "supply console"
	desc = "Used to order supplies, approve requests, and control the shuttle."
	icon_screen = "supply"
	circuit = /obj/item/circuitboard/computer/cargo
	light_color = COLOR_BRIGHT_ORANGE

	///Can the supply console send the shuttle back and forth? Used in the UI backend.
	var/can_send = TRUE
	///Can this console only send requests?
	var/requestonly = FALSE
	///Can you approve requests placed for cargo? Works differently between the app and the computer.
	var/can_approve_requests = TRUE
	var/contraband = FALSE
	var/self_paid = FALSE
	var/safety_warning = "For safety and ethical reasons, the automated supply shuttle cannot transport live organisms, \
		human remains, classified nuclear weaponry, mail, undelivered departmental order crates, syndicate bombs, \
		homing beacons, unstable eigenstates, fax machines, or machinery housing any form of artificial intelligence."
	var/blockade_warning = "Bluespace instability detected. Shuttle movement impossible."
	/// var that tracks message cooldown
	var/message_cooldown
	var/list/loaded_coupons
	/// var that makes express console use rockets
	var/is_express = FALSE
	///The name of the shuttle template being used as the cargo shuttle. 'cargo' is default and contains critical code. Don't change this unless you know what you're doing.
	var/cargo_shuttle = "cargo"
	///The docking port called when returning to the station.
	var/docking_home = "cargo_home"
	///The docking port called when leaving the station.
	var/docking_away = "cargo_away"
	///If this console can loan the cargo shuttle. Set to false to disable.
	var/stationcargo = TRUE
	///The account this console processes and displays. Independent from the account the shuttle processes.
	var/cargo_account = ACCOUNT_CAR
	///Interface name for the ui_interact call for different subtypes.
	var/interface_type = "Cargo"

/obj/machinery/computer/cargo/request
	name = "supply request console"
	desc = "Used to request supplies from cargo."
	icon_screen = "request"
	circuit = /obj/item/circuitboard/computer/cargo/request
	can_send = FALSE
	can_approve_requests = FALSE
	requestonly = TRUE

/obj/machinery/computer/cargo/attacked_by(obj/item/I, mob/living/user)
	if(istype(I,/obj/item/trade_chip))
		var/obj/item/trade_chip/contract = I
		contract.try_to_unlock_contract(user)
		return TRUE
	else
		return ..()

/obj/machinery/computer/cargo/emag_act(mob/user, obj/item/card/emag/emag_card)
	if(obj_flags & EMAGGED)
		return FALSE
	if(user)
		if (emag_card)
			user.visible_message(span_warning("[user] swipes [emag_card] through [src]!"))
		to_chat(user, span_notice("You adjust [src]'s routing and receiver spectrum, unlocking special supplies and contraband."))

	obj_flags |= EMAGGED
	contraband = TRUE

	// This also permanently sets this on the circuit board
	var/obj/item/circuitboard/computer/cargo/board = circuit
	board.contraband = TRUE
	board.obj_flags |= EMAGGED
	update_static_data(user)
	return TRUE

/obj/machinery/computer/cargo/on_construction(mob/user)
	. = ..()
	circuit.configure_machine(src)

/obj/machinery/computer/cargo/ui_interact(mob/user, datum/tgui/ui)
	. = ..()
	ui = SStgui.try_update_ui(user, src, ui)
	if(!ui)
		ui = new(user, src, interface_type, name)
		ui.open()

/obj/machinery/computer/cargo/ui_data()
	var/list/data = list()
	data["department"] = "Cargo" // Hardcoded here, for customization in budgetordering.dm AKA NT IRN
	data["location"] = SSshuttle.supply.getStatusText()
	var/datum/bank_account/bank = SSeconomy.get_dep_account(cargo_account)
	if(bank)
		data["points"] = bank.account_balance
	data["grocery"] = SSshuttle.chef_groceries.len
	data["away"] = SSshuttle.supply.getDockedId() == docking_away
	data["self_paid"] = self_paid
	data["docked"] = SSshuttle.supply.mode == SHUTTLE_IDLE
	data["loan"] = !!SSshuttle.shuttle_loan
	data["loan_dispatched"] = SSshuttle.shuttle_loan && SSshuttle.shuttle_loan.dispatched
	data["can_send"] = can_send
	data["can_approve_requests"] = can_approve_requests
	var/message = "Remember to stamp and send back the supply manifests."
	if(SSshuttle.centcom_message)
		message = SSshuttle.centcom_message
	if(SSshuttle.supply_blocked)
		message = blockade_warning
	data["message"] = message

	var/list/amount_by_name = list()
	var/cart_list = list()
	for(var/datum/supply_order/order in SSshuttle.shopping_list)
		if(cart_list[order.pack.name])
			amount_by_name[order.pack.name] += 1
			cart_list[order.pack.name][1]["amount"]++
			cart_list[order.pack.name][1]["cost"] += order.get_final_cost()
			if(order.department_destination)
				cart_list[order.pack.name][1]["dep_order"]++
			if(!isnull(order.paying_account))
				cart_list[order.pack.name][1]["paid"]++
			continue

		amount_by_name[order.pack.name] += 1
		cart_list[order.pack.name] = list(list(
			"cost_type" = order.cost_type,
			"object" = order.pack.name,
			"cost" = order.get_final_cost(),
			"id" = order.id,
			"amount" = 1,
			"orderer" = order.orderer,
			"paid" = !isnull(order.paying_account) ? 1 : 0, //number of orders purchased privatly
			"dep_order" = order.department_destination ? 1 : 0, //number of orders purchased by a department
			"can_be_cancelled" = order.can_be_cancelled,
		))
	data["cart"] = list()
	for(var/item_id in cart_list)
		data["cart"] += cart_list[item_id]


	data["requests"] = list()
	for(var/datum/supply_order/order in SSshuttle.request_list)
		var/datum/supply_pack/pack = order.pack
		amount_by_name[pack.name] += 1
		data["requests"] += list(list(
			"object" = pack.name,
			"cost" = pack.get_cost(),
			"orderer" = order.orderer,
			"reason" = order.reason,
			"id" = order.id,
		))
	data["amount_by_name"] = amount_by_name

	return data

/obj/machinery/computer/cargo/ui_static_data(mob/user)
	var/list/data = list()
	data["max_order"] = CARGO_MAX_ORDER
	data["supplies"] = list()

	for(var/pack_id in SSshuttle.supply_packs)
		var/datum/supply_pack/pack = SSshuttle.supply_packs[pack_id]
		if(!data["supplies"][pack.group])
			data["supplies"][pack.group] = list(
				"name" = pack.group,
				"packs" = get_packs_data(pack.group),
			)

	return data

/**
 * returns a list of supply packs for a certain group
 * * group - the group of packs to return
 * * express - if this is an express console
 */
/obj/machinery/computer/cargo/proc/get_packs_data(group, express = FALSE)
	var/list/packs = list()
	for(var/pack_id in SSshuttle.supply_packs)
		var/datum/supply_pack/pack = SSshuttle.supply_packs[pack_id]
		if(pack.group != group)
			continue

		// Express console packs check
		if(express && (pack.hidden || pack.special))
			continue

		if(!express && ((pack.hidden && !(obj_flags & EMAGGED)) || (pack.special && !pack.special_enabled) || pack.drop_pod_only))
			continue

		if(pack.contraband && !contraband)
			continue

		var/obj/item/first_item = length(pack.contains) > 0 ? pack.contains[1] : null
		packs += list(list(
			"name" = pack.name,
			"cost" = pack.get_cost() * get_discount(),
			"id" = pack_id,
			"desc" = pack.desc || pack.name, // If there is a description, use it. Otherwise use the pack's name.
			"first_item_icon" = first_item?.icon,
			"first_item_icon_state" = first_item?.icon_state,
			"goody" = pack.goody,
			"access" = pack.access,
			"contraband" = pack.contraband,
			"contains" = pack.get_contents_ui_data(),
		))

	return packs

/**
 * returns the discount multiplier applied to all supply packs,
 * the discount is calculated as follows: pack_cost * get_discount()
 */
/obj/machinery/computer/cargo/proc/get_discount()
	return 1

/**
 * adds an supply pack to the checkout cart
 * * user - the mobe doing this order
 * * id - the type of pack to order
 * * amount - the amount to order. You may not order more then 10 things at once
 */
/obj/machinery/computer/cargo/proc/add_item(mob/user, id, amount = 1)
	if(is_express)
		return
	id = text2path(id) || id
	var/datum/supply_pack/pack = SSshuttle.supply_packs[id]
	if(!istype(pack))
		CRASH("Unknown supply pack id given by order console ui. ID: [id]")
	if(amount > CARGO_MAX_ORDER || amount < 1) // Holy shit fuck off
		CRASH("Invalid amount passed into add_item")
	if((pack.hidden && !(obj_flags & EMAGGED)) || (pack.contraband && !contraband) || pack.drop_pod_only || (pack.special && !pack.special_enabled))
		return

	var/name = "*None Provided*"
	var/rank = "*None Provided*"
	var/ckey = user.ckey
	if(ishuman(user))
		var/mob/living/carbon/human/human = user
		name = human.get_authentification_name()
		rank = human.get_assignment(hand_first = TRUE)
	else if(HAS_SILICON_ACCESS(user))
		name = user.real_name
		rank = "Silicon"

	var/datum/bank_account/account
	if(self_paid && isliving(user))
		var/mob/living/living_user = user
		var/obj/item/card/id/id_card = living_user.get_idcard(TRUE)
		if(!istype(id_card))
			say("No ID card detected.")
			return
		if(IS_DEPARTMENTAL_CARD(id_card))
			say("The [src] rejects [id_card].")
			return
		account = id_card.registered_account
		if(!istype(account))
			say("Invalid bank account.")
			return
		var/list/access = id_card.GetAccess()
		if(pack.access_view && !(pack.access_view in access))
			say("[id_card] lacks the requisite access for this purchase.")
			return

	// The list we are operating on right now
	var/list/working_list = SSshuttle.shopping_list
	var/reason = ""
	if(requestonly && !self_paid)
		working_list = SSshuttle.request_list
		reason = tgui_input_text(user, "Reason", name, max_length = MAX_MESSAGE_LEN)
		if(isnull(reason))
			return

	if(pack.goody && !self_paid)
		playsound(src, 'sound/machines/buzz/buzz-sigh.ogg', 50, FALSE)
		say("ERROR: Small crates may only be purchased by private accounts.")
		return

	var/similar_count = SSshuttle.supply.get_order_count(pack)
	if(similar_count == OVER_ORDER_LIMIT)
		playsound(src, 'sound/machines/buzz/buzz-sigh.ogg', 50, FALSE)
		say("ERROR: No more then [CARGO_MAX_ORDER] of any pack may be ordered at once")
		return

	amount = clamp(amount, 1, CARGO_MAX_ORDER - similar_count)
	for(var/count in 1 to amount)
		var/obj/item/coupon/applied_coupon
		for(var/obj/item/coupon/coupon_check in loaded_coupons)
			if(pack.type == coupon_check.discounted_pack)
				say("Coupon found! [round(coupon_check.discount_pct_off * 100)]% off applied!")
				coupon_check.moveToNullspace()
				applied_coupon = coupon_check
				break

		var/datum/supply_order/order = new(
			pack = pack ,
			orderer = name,
			orderer_rank = rank,
			orderer_ckey = ckey,
			reason = reason,
			paying_account = account,
			coupon = applied_coupon,
		)
		working_list += order

	if(self_paid)
		say("Order processed. The price will be charged to [account.account_holder]'s bank account on delivery.")
	if(requestonly && message_cooldown < world.time)
		aas_config_announce(/datum/aas_config_entry/cargo_orders_announcement, list("AMOUNT" = amount), src, list(RADIO_CHANNEL_SUPPLY), amount == 1 ? "Single Order" : "Multiple Orders")
		message_cooldown = world.time + 30 SECONDS
	. = TRUE

/**
 * removes an item from the checkout cart
 * * id - the id of the cart item to remove
 */
/obj/machinery/computer/cargo/proc/remove_item(id)
	for(var/datum/supply_order/order in SSshuttle.shopping_list)
		if(order.id != id)
			continue
		if(order.department_destination)
			say("Only the department that ordered this item may cancel it.")
			return FALSE
		if(order.applied_coupon)
			say("Coupon refunded.")
			order.applied_coupon.forceMove(get_turf(src))
		SSshuttle.shopping_list -= order
		qdel(order)
		return TRUE
	return FALSE
/**
 * maps the ordename displayed on the ui to its supply pack id
 * * order_name - the name of the order
 */
/obj/machinery/computer/cargo/proc/name_to_id(order_name)
	for(var/pack in SSshuttle.supply_packs)
		var/datum/supply_pack/supply = SSshuttle.supply_packs[pack]
		if(order_name == supply.name)
			return pack
	return null

/obj/machinery/computer/cargo/ui_act(action, list/params, datum/tgui/ui, datum/ui_state/state)
	. = ..()
	if(.)
		return

	switch(action)
		if("send")
			if(!SSshuttle.supply.canMove())
				say(safety_warning)
				return
			if(SSshuttle.supply_blocked)
				say(blockade_warning)
				return

			if(SSshuttle.supply.getDockedId() == docking_home)
				SSshuttle.moveShuttle(cargo_shuttle, docking_away, TRUE)
				say("The supply shuttle is departing.")
				ui.user.investigate_log("sent the supply shuttle away.", INVESTIGATE_CARGO)
			else
				//create the paper from the SSshuttle.shopping_list
				if(length(SSshuttle.shopping_list))
					var/obj/item/paper/requisition/requisition_paper = new(get_turf(src))
					requisition_paper.name = "requisition form - [station_time_timestamp()]"
					var/requisition_text = "<h2>[station_name()] Supply Requisition</h2>"
					requisition_text += "<hr/>"
					requisition_text += "Time of Order: [station_time_timestamp()]<br/><br/>"
					for(var/datum/supply_order/order as anything in SSshuttle.shopping_list)
						requisition_text += "<b>[order.pack.name]</b></br>"
						requisition_text += "- Order ID: [order.id]</br>"
						var/restrictions = SSid_access.get_access_desc(order.pack.access)
						if(restrictions)
							requisition_text += "- Access Restrictions: [restrictions]</br>"
						requisition_text += "- Ordered by: [order.orderer] ([order.orderer_rank])</br>"
						var/paying_account = order.paying_account
						if(paying_account)
							requisition_text += "- Paid Privately by: [order.paying_account.account_holder]<br/>"
						var/reason = order.reason
						if(reason)
							requisition_text += "- Reason Given: [reason]</br>"
						requisition_text += "</br></br>"
					requisition_paper.add_raw_text(requisition_text)
					requisition_paper.color = "#9ef5ff"
					requisition_paper.update_appearance()

				ui.user.investigate_log("called the supply shuttle.", INVESTIGATE_CARGO)
				say("The supply shuttle has been called and will arrive in [SSshuttle.supply.timeLeft(600)] minutes.")
				SSshuttle.moveShuttle(cargo_shuttle, docking_home, TRUE)

			. = TRUE
		if("loan")
			if(!SSshuttle.shuttle_loan)
				return
			if(SSshuttle.supply_blocked)
				say(blockade_warning)
				return
			else if(SSshuttle.supply.mode != SHUTTLE_IDLE)
				return
			else if(SSshuttle.supply.getDockedId() != docking_away)
				return
			else if(stationcargo != TRUE)
				return
			else
				SSshuttle.shuttle_loan.loan_shuttle()
				say("The supply shuttle has been loaned to CentCom.")
				ui.user.investigate_log("accepted a shuttle loan event.", INVESTIGATE_CARGO)
				ui.user.log_message("accepted a shuttle loan event.", LOG_GAME)
				. = TRUE
		if("add")
			return add_item(ui.user, params["id"])
		if("add_by_name")
			var/supply_pack_id = name_to_id(params["order_name"])
			if(!supply_pack_id)
				return
			return add_item(ui.user, supply_pack_id)
		if("remove")
			var/order_name = params["order_name"]
			//try removing at least one item with the specified name. An order may not be removed if it was from the department
			for(var/datum/supply_order/order in SSshuttle.shopping_list)
				if(order.pack.name != order_name)
					continue
				if(remove_item(order.id))
					return TRUE

			return TRUE
		if("modify")
			var/order_name = params["order_name"]

			//clear out all orders with the above mentioned order_name name to make space for the new amount
			for(var/datum/supply_order/order in SSshuttle.shopping_list) //find corresponding order id for the order name
				if(order.pack.name == order_name)
					remove_item(order.id)

			//now add the new amount stuff
			var/amount = text2num(params["amount"])
			if(amount == 0)
				return TRUE
			if(amount > CARGO_MAX_ORDER)
				return
			var/supply_pack_id = name_to_id(order_name) //map order name to supply pack id for adding
			if(!supply_pack_id)
				return
			return add_item(ui.user, supply_pack_id, amount)
		if("clear")
			//create copy of list else we will get runtimes when iterating & removing items on the same list SSshuttle.shopping_list
			var/list/shopping_cart = SSshuttle.shopping_list.Copy()
			for(var/datum/supply_order/cancelled_order in shopping_cart)
				if(cancelled_order.department_destination || !cancelled_order.can_be_cancelled)
					continue //don't cancel other department's orders or orders that can't be cancelled
				remove_item(cancelled_order.id) //remove & properly refund any coupons attached with this order
		if("approve")
			var/id = text2num(params["id"])
			for(var/datum/supply_order/SO in SSshuttle.request_list)
				if(SO.id == id)
					SSshuttle.request_list -= SO
					SSshuttle.shopping_list += SO
					. = TRUE
					break
		if("deny")
			var/id = text2num(params["id"])
			for(var/datum/supply_order/SO in SSshuttle.request_list)
				if(SO.id == id)
					SSshuttle.request_list -= SO
					. = TRUE
					break
		if("denyall")
			SSshuttle.request_list.Cut()
			. = TRUE
		if("toggleprivate")
			self_paid = !self_paid
			. = TRUE
	if(.)
		post_signal(cargo_shuttle)

/obj/machinery/computer/cargo/proc/post_signal(command)

	var/datum/radio_frequency/frequency = SSradio.return_frequency(FREQ_STATUS_DISPLAYS)

	if(!frequency)
		return

	var/datum/signal/status_signal = new(list("command" = command))
	frequency.post_signal(src, status_signal)

/datum/aas_config_entry/cargo_orders_announcement
	name = "Cargo Alert: New Orders"
	announcement_lines_map = list(
		"Single Order" = "A new order has been requested.",
		"Multiple Orders" = "%AMOUNT orders have been requested.",
	)
	vars_and_tooltips_map = list(
		"AMOUNT" = "will be replaced wuth number of orders.",
	)
