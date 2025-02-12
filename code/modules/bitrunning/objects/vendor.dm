#define CREDIT_TYPE_BITRUNNING "np"

/obj/machinery/computer/order_console/bitrunning
	name = "bitrunning supplies order console"
	desc = "NexaCache(tm)! Dubiously authentic gear for the digital daredevil."
	icon = 'icons/obj/machines/bitrunning.dmi'
	icon_state = "vendor"
	icon_keyboard = null
	icon_screen = null
	circuit = /obj/item/circuitboard/computer/order_console/bitrunning
	cooldown_time = 10 SECONDS
	cargo_cost_multiplier = 0.65
	express_cost_multiplier = 1
	purchase_tooltip = @{"Your purchases will arrive at cargo,
	and hopefully get delivered by them.
	35% cheaper than express delivery."}
	express_tooltip = @{"Sends your purchases instantly."}
	credit_type = CREDIT_TYPE_BITRUNNING

	order_categories = list(
		CATEGORY_BITRUNNING_FLAIR,
		CATEGORY_BITRUNNING_TECH,
		CATEGORY_BEPIS,
	)
	blackbox_key = "bitrunning"
	announcement_line = "A bitrunner has ordered equipment which will arrive on the cargo shuttle! Please make sure it gets to them as soon as possible!"

/obj/machinery/computer/order_console/bitrunning/subtract_points(final_cost, obj/item/card/id/card)
	if(final_cost <= card.registered_account.bitrunning_points)
		card.registered_account.bitrunning_points -= final_cost
		return TRUE
	return FALSE

/obj/machinery/computer/order_console/bitrunning/order_groceries(mob/living/purchaser, obj/item/card/id/card, list/groceries)
	var/list/things_to_order = list()
	for(var/datum/orderable_item/item as anything in groceries)
		things_to_order[item.purchase_path] = groceries[item]

	var/datum/supply_pack/bitrunning/pack = new(
		purchaser = purchaser, \
		cost = get_total_cost(), \
		contains = things_to_order,
	)

	var/datum/supply_order/new_order = new(
		pack = pack,
		orderer = purchaser,
		orderer_rank = "Bitrunning Vendor",
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

/obj/machinery/computer/order_console/bitrunning/retrieve_points(obj/item/card/id/id_card)
	return round(id_card.registered_account.bitrunning_points)

/obj/machinery/computer/order_console/bitrunning/ui_act(action, list/params, datum/tgui/ui, datum/ui_state/state)
	. = ..()
	if(!.)
		flick("vendor_off", src)

/obj/machinery/computer/order_console/bitrunning/update_icon_state()
	icon_state = "[initial(icon_state)][powered() ? null : "_off"]"
	return ..()

/datum/supply_pack/bitrunning
	name = "bitrunning order"
	hidden = TRUE
	crate_name = "bitrunning delivery crate"
	access = list(ACCESS_BIT_DEN)

/datum/supply_pack/bitrunning/New(purchaser, cost, list/contains)
	. = ..()
	name = "[purchaser]'s Bitrunning Order"
	src.cost = cost
	src.contains = contains

#undef CREDIT_TYPE_BITRUNNING
