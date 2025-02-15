/// Stores an override value for the order cooldown to be used by the Dpt. Order Cooldown button in the secrets menu. When null, the override is not active.
GLOBAL_VAR(department_cd_override)

/datum/computer_file/program/department_order
	filename = "dept_order"
	filedesc = "Departmental Orders"
	can_run_on_flags = PROGRAM_CONSOLE
	downloader_category = PROGRAM_CATEGORY_SUPPLY
	program_open_overlay = "request"
	extended_desc = "Allows for departments to order supplied from Cargo for free, with a cooldown between orders."
	size = 10
	tgui_id = "NtosDeptOrder"
	program_icon = FA_ICON_CART_FLATBED
	alert_able = TRUE

	// Filled via set_linked_department. Also serves as "who can cancel the order".
	download_access = list(ACCESS_COMMAND)
	// Anyone can open, not everyone can use.
	run_access = list()
	/// Filled via set_linked_department. Serves as "who can place orders".
	VAR_PRIVATE/list/use_access = list()

	/// The department we are linked to, typepath.
	VAR_PRIVATE/datum/job_department/linked_department
	/// Stores the time when we can next place an order for each department.
	VAR_PRIVATE/static/list/department_cooldowns = list(
		/datum/job_department/engineering = 0,
		/datum/job_department/medical = 0,
		/datum/job_department/science = 0,
		/datum/job_department/security = 0,
		/datum/job_department/service = 0,
	)
	/// Reference to the order we've made UNTIL it gets sent on the supply shuttle. this is so heads can cancel it
	VAR_PRIVATE/datum/supply_order/department_order
	/// The radio channel we will speak into by default.
	VAR_PRIVATE/radio_channel
	/// Maps what department should report to what radio channel
	/// I could've put this on the job department datum but it felt unnecessary
	VAR_PRIVATE/static/list/dept_to_radio_channel = list(
		/datum/job_department/engineering = RADIO_CHANNEL_ENGINEERING,
		/datum/job_department/medical = RADIO_CHANNEL_MEDICAL,
		/datum/job_department/science = RADIO_CHANNEL_SCIENCE,
		/datum/job_department/security = RADIO_CHANNEL_SECURITY,
		/datum/job_department/service = RADIO_CHANNEL_SERVICE,
	)

/// Sets the passed department type as the active department for this computer file.
/datum/computer_file/program/department_order/proc/set_linked_department(datum/job_department/department)
	linked_department = department
	var/datum/job_department/linked_department_real = SSjob.get_department_type(linked_department)
	// Heads of staff can download
	download_access |= linked_department_real.head_of_staff_access
	// Heads of staff + anyone in the dept can run it
	use_access |= linked_department_real.head_of_staff_access
	use_access |= linked_department_real.department_access
	// Also set up the radio
	if(dept_to_radio_channel[linked_department])
		radio_channel = dept_to_radio_channel[linked_department] || RADIO_CHANNEL_SUPPLY
	computer.update_static_data_for_all_viewers()

/datum/computer_file/program/department_order/ui_interact(mob/user, datum/tgui/ui)
	check_cooldown()

/datum/computer_file/program/department_order/ui_data(mob/user)
	var/list/data = list()
	data["no_link"] = !linked_department
	data["id_inside"] = !!computer.computer_id_slot
	data["time_left"] = department_cooldowns[linked_department] ? DisplayTimeText(max(department_cooldowns[linked_department] - world.time, 0), 1) : null
	data["can_override"] = !!department_order
	return data

/datum/computer_file/program/department_order/ui_static_data(mob/user)
	var/datum/job_department/linked_department_real = SSjob.get_department_type(linked_department)
	if(isnull(linked_department_real))
		return list("supplies" = list())

	var/list/data = list()

	var/list/supply_data = list()
	for(var/group in linked_department_real.associated_cargo_groups)
		supply_data[group] = list()

	for(var/pack_key in SSshuttle.supply_packs)
		var/datum/supply_pack/pack = SSshuttle.supply_packs[pack_key]
		if(!islist(supply_data[pack.group]) || !can_see_pack(pack))
			continue

		UNTYPED_LIST_ADD(supply_data[pack.group], list(
			"name" = pack.name,
			"cost" = pack.get_cost(),
			"id" = pack.id,
			"desc" = pack.desc || pack.name, // If there is a description, use it. Otherwise use the pack's name.
		))

	var/list/supply_data_flattened = list()
	for(var/group in supply_data)
		UNTYPED_LIST_ADD(supply_data_flattened, list(
			"name" = group,
			"packs" = supply_data[group],
		))

	data["supplies"] = supply_data_flattened
	return data

/// Checks if we can "see" the passed supply pack
/datum/computer_file/program/department_order/proc/can_see_pack(datum/supply_pack/to_check)
	PROTECTED_PROC(TRUE)
	if(to_check.hidden && !(computer.obj_flags & EMAGGED))
		return FALSE
	if(to_check.special && !to_check.special_enabled)
		return FALSE
	if(to_check.drop_pod_only)
		return FALSE
	if(to_check.goody)
		return FALSE
	return TRUE

/// Looks through all possible departments and finds one this ID card "corresponds" to.
/datum/computer_file/program/department_order/proc/find_department_to_link(obj/item/card/id/id_card)
	PROTECTED_PROC(TRUE)
	if(id_card.type != /obj/item/card/id/advanced/silver)
		// I don't want to introduce weird "access order" behavior with Captain's ID / Chameleon ids / etc, so only silver IDs work
		return null
	var/list/access_to_depts = list()
	for(var/datum/job_department/department as anything in department_cooldowns)
		access_to_depts[initial(department.head_of_staff_access)] = department
	for(var/access_key in id_card.GetAccess())
		if(access_to_depts[access_key])
			return access_to_depts[access_key]
	return null

/datum/computer_file/program/department_order/ui_act(action, list/params, datum/tgui/ui, datum/ui_state/state)
	. = ..()
	if(.)
		return .

	var/mob/living/orderer = ui.user
	if(!istype(orderer))
		return .

	if(action == "link")
		if(!isnull(linked_department))
			return TRUE

		var/new_dept_type = find_department_to_link(computer.computer_id_slot)
		if(isnull(new_dept_type))
			computer.physical.balloon_alert(orderer, "no department found!")
			playsound(computer, 'sound/machines/buzz/buzz-sigh.ogg', 30, TRUE)
		else
			computer.physical.balloon_alert(orderer, "linked")
			playsound(computer, 'sound/machines/ping.ogg', 30, TRUE)
			set_linked_department(new_dept_type)
		return TRUE

	if(isnull(linked_department))
		return TRUE

	var/obj/item/card/id/id_card = computer.computer_id_slot || orderer.get_idcard(hand_first = TRUE)
	var/list/id_card_access = id_card?.GetAccess() || list()

	if(length(use_access & id_card_access) <= 0)
		computer.physical.balloon_alert(orderer, "access denied!")
		playsound(computer, 'sound/machines/buzz/buzz-sigh.ogg', 30, TRUE)
		return TRUE

	if(action == "override_order")
		if(isnull(department_order) || !(department_order in SSshuttle.shopping_list))
			return TRUE
		if(length(download_access & id_card_access) <= 0)
			computer.physical.balloon_alert(orderer, "requires head of staff access!")
			playsound(computer, 'sound/machines/buzz/buzz-sigh.ogg', 30, TRUE)
			return TRUE

		department_cooldowns[linked_department] = 0
		SSshuttle.shopping_list -= department_order
		department_order = null
		UnregisterSignal(SSshuttle, COMSIG_SUPPLY_SHUTTLE_BUY)
		return TRUE

	if(department_cooldowns[linked_department] > world.time)
		return TRUE

	submit_order(orderer, params["id"])
	return TRUE

/// Submits the order with the specified supply pack id as the specified orderer
/datum/computer_file/program/department_order/proc/submit_order(mob/living/orderer, id)
	id = text2path(id) || id

	var/datum/job_department/linked_department_real = SSjob.get_department_type(linked_department)
	var/datum/supply_pack/pack = SSshuttle.supply_packs[id]
	if(isnull(pack))
		computer.physical.say("Something went wrong!")
		CRASH("requested supply pack id \"[id]\" not found!")
	if(!can_see_pack(pack) || !(pack.group in linked_department_real.associated_cargo_groups))
		return
	var/name = "*None Provided*"
	var/rank = "*None Provided*"
	var/ckey = orderer.ckey
	if(ishuman(orderer))
		var/mob/living/carbon/human/human_orderer = orderer
		name = human_orderer.get_authentification_name()
		rank = human_orderer.get_assignment(hand_first = TRUE)
	else if(HAS_SILICON_ACCESS(orderer))
		name = orderer.real_name
		rank = "Silicon"
	var/already_signalled = !!department_order
	var/chosen_delivery_area
	for(var/delivery_area_type in linked_department_real.department_delivery_areas)
		if(GLOB.areas_by_type[delivery_area_type])
			chosen_delivery_area = delivery_area_type
			break

	if(SSshuttle.supply.get_order_count(pack) == OVER_ORDER_LIMIT)
		playsound(computer, 'sound/machines/buzz/buzz-sigh.ogg', 50, FALSE)
		computer.physical.say("ERROR: No more then [CARGO_MAX_ORDER] of any pack may be ordered at once!")
		return

	department_order = new(
		pack = pack,
		orderer = name,
		orderer_rank = rank,
		orderer_ckey = ckey,
		reason = "Departmental Order",
		paying_account = null,
		department_destination = chosen_delivery_area,
		coupon = null,
		manifest_can_fail = FALSE,
	)
	SSshuttle.shopping_list += department_order
	if(!already_signalled)
		RegisterSignal(SSshuttle, COMSIG_SUPPLY_SHUTTLE_BUY, PROC_REF(finalize_department_order))
	if(!alert_silenced && alert_able)
		aas_config_announce(/datum/aas_config_entry/department_orders, list("ORDER" = pack.name, "PERSON" = name), computer.physical, list(radio_channel), "Order Placed")
		aas_config_announce(/datum/aas_config_entry/department_orders_cargo, list("DEPARTMENT" = linked_department.department_name), computer.physical, list(RADIO_CHANNEL_SUPPLY))
	computer.physical.say("Order processed. Cargo will deliver the crate when it comes in on their shuttle. NOTICE: Heads of staff may override the order.")
	calculate_cooldown(pack.cost)

/// Signal when the supply shuttle begins to spawn orders. We forget the current order preventing it from being overridden (since it's already past the point of no return on undoing the order)
/datum/computer_file/program/department_order/proc/finalize_department_order(datum/subsystem)
	SIGNAL_HANDLER
	if(!isnull(department_order) && (department_order in SSshuttle.shopping_list))
		department_order = null
	UnregisterSignal(subsystem, COMSIG_SUPPLY_SHUTTLE_BUY)

/// Calculates the cooldown it will take for this department's free order, based on its credit cost
/datum/computer_file/program/department_order/proc/calculate_cooldown(credits)
	if(isnull(GLOB.department_cd_override))
		var/time_y = DEPARTMENTAL_ORDER_COOLDOWN_COEFFICIENT * (log(10, credits) ** DEPARTMENTAL_ORDER_COOLDOWN_EXPONENT) * (1 SECONDS)
		department_cooldowns[linked_department] = world.time + time_y
	else
		var/time_y = GLOB.department_cd_override SECONDS
		department_cooldowns[linked_department] = world.time + time_y

/datum/computer_file/program/department_order/process_tick(seconds_per_tick)
	if(!check_cooldown() || alert_silenced || !alert_able)
		return
	aas_config_announce(/datum/aas_config_entry/department_orders, list(), computer.physical, list(radio_channel), "Cooldown Reset")
	computer.alert_call(src, "Order cooldown expired!", 'sound/machines/ping.ogg')

/// Checks if the cooldown is up and resets it if so.
/datum/computer_file/program/department_order/proc/check_cooldown()
	if(department_cooldowns[linked_department] > 0 && department_cooldowns[linked_department] <= world.time)
		department_cooldowns[linked_department] = 0
		return TRUE
	return FALSE

/datum/aas_config_entry/department_orders
	name = "Departmental Order Announcement"
	announcement_lines_map = list(
		"Order Placed" = "A department order has been placed by %PERSON for %ORDER.",
		"Cooldown Reset" = "Department order cooldown has expired! A new order may now be placed!",
	)
	vars_and_tooltips_map = list(
		"ORDER" = "will be replaced with the package name",
		"PERSON" = "with the orderer's name",
	)

/datum/aas_config_entry/department_orders_cargo
	name = "Cargo Alert: New Departmental Order"
	announcement_lines_map = list(
		"Message" = "New %DEPARTMENT departmental order has been placed"
	)
	vars_and_tooltips_map = list(
		"DEPARTMENT" = "will be replaced with orderer's department."
	)
