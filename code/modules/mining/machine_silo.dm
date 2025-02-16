/obj/machinery/ore_silo
	name = "ore silo"
	desc = "An all-in-one bluespace storage and transmission system for the station's mineral distribution needs."
	icon = 'icons/obj/machines/ore_silo.dmi'
	icon_state = "silo"
	density = TRUE
	circuit = /obj/item/circuitboard/machine/ore_silo
	interaction_flags_machine = INTERACT_MACHINE_WIRES_IF_OPEN|INTERACT_MACHINE_ALLOW_SILICON|INTERACT_MACHINE_OPEN_SILICON
	processing_flags = NONE

	/// List of all connected components that are on hold from accessing materials.
	var/list/holds = list()
	/// List of all components that are sharing ores with this silo.
	var/list/datum/component/remote_materials/ore_connected_machines = list()
	/// Material Container
	var/datum/component/material_container/materials

/obj/machinery/ore_silo/Initialize(mapload)
	. = ..()

	materials = AddComponent( \
		/datum/component/material_container, \
		SSmaterials.materials_by_category[MAT_CATEGORY_SILO], \
		INFINITY, \
		MATCONTAINER_EXAMINE, \
		container_signals = list( \
			COMSIG_MATCONTAINER_ITEM_CONSUMED = TYPE_PROC_REF(/obj/machinery/ore_silo, on_item_consumed), \
			COMSIG_MATCONTAINER_SHEETS_RETRIEVED = TYPE_PROC_REF(/obj/machinery/ore_silo, log_sheets_ejected), \
		), \
		allowed_items = /obj/item/stack \
	)
	if (!GLOB.ore_silo_default && mapload && is_station_level(z))
		GLOB.ore_silo_default = src
	register_context()

/obj/machinery/ore_silo/Destroy()
	if (GLOB.ore_silo_default == src)
		GLOB.ore_silo_default = null

	for(var/datum/component/remote_materials/mats as anything in ore_connected_machines)
		mats.disconnect_from(src)

	ore_connected_machines = null
	materials = null

	return ..()

/obj/machinery/ore_silo/examine(mob/user)
	. = ..()
	. += span_notice("It can be linked to techfabs, circuit printers and protolathes with a multitool.")
	. += span_notice("Its maintainence panel can be [EXAMINE_HINT("screwed")] [panel_open ? "closed" : "open"].")
	if(panel_open)
		. += span_notice("The whole machine can be [EXAMINE_HINT("pried")] apart.")

/obj/machinery/ore_silo/add_context(atom/source, list/context, obj/item/held_item, mob/user)
	. = NONE
	if(isnull(held_item))
		return

	if(held_item.tool_behaviour == TOOL_SCREWDRIVER)
		context[SCREENTIP_CONTEXT_LMB] = "[panel_open ? "Close" : "Open"] Panel"
		return CONTEXTUAL_SCREENTIP_SET

	if(held_item.tool_behaviour == TOOL_MULTITOOL)
		context[SCREENTIP_CONTEXT_LMB] = "Log Silo"
		return CONTEXTUAL_SCREENTIP_SET

	if(panel_open && held_item.tool_behaviour == TOOL_CROWBAR)
		context[SCREENTIP_CONTEXT_LMB] = "Deconstruct"
		return CONTEXTUAL_SCREENTIP_SET

/obj/machinery/ore_silo/proc/on_item_consumed(datum/component/material_container/container, obj/item/item_inserted, last_inserted_id, mats_consumed, amount_inserted, atom/context)
	SIGNAL_HANDLER

	silo_log(context, "deposited", amount_inserted, item_inserted.name, mats_consumed)

	SEND_SIGNAL(context, COMSIG_SILO_ITEM_CONSUMED, container, item_inserted, last_inserted_id, mats_consumed, amount_inserted)

/obj/machinery/ore_silo/proc/log_sheets_ejected(datum/component/material_container/container, obj/item/stack/sheet/sheets, atom/context)
	SIGNAL_HANDLER

	silo_log(context, "ejected", -sheets.amount, "[sheets.singular_name]", sheets.custom_materials)

/obj/machinery/ore_silo/screwdriver_act(mob/living/user, obj/item/tool)
	. = ITEM_INTERACT_BLOCKING
	if(default_deconstruction_screwdriver(user, icon_state, icon_state, tool))
		return ITEM_INTERACT_SUCCESS

/obj/machinery/ore_silo/crowbar_act(mob/living/user, obj/item/tool)
	. = ITEM_INTERACT_BLOCKING
	if(default_deconstruction_crowbar(tool))
		return ITEM_INTERACT_SUCCESS

/obj/machinery/ore_silo/multitool_act(mob/living/user, obj/item/multitool/I)
	I.set_buffer(src)
	balloon_alert(user, "saved to multitool buffer")
	return ITEM_INTERACT_SUCCESS

/obj/machinery/ore_silo/ui_assets(mob/user)
	return list(
		get_asset_datum(/datum/asset/spritesheet_batched/sheetmaterials)
	)

/obj/machinery/ore_silo/ui_interact(mob/user, datum/tgui/ui)
	ui = SStgui.try_update_ui(user, src, ui)
	if(!ui)
		ui = new(user, src, "OreSilo")
		ui.open()

/obj/machinery/ore_silo/ui_static_data(mob/user)
	return materials.ui_static_data()

/obj/machinery/ore_silo/ui_data(mob/user)
	var/list/data = list()

	data["materials"] =  materials.ui_data()

	data["machines"] = list()
	for(var/datum/component/remote_materials/remote as anything in ore_connected_machines)
		var/atom/parent = remote.parent
		data["machines"] += list(
			list(
				"icon" = icon2base64(icon(initial(parent.icon), initial(parent.icon_state), frame = 1)),
				"name" = parent.name,
				"onHold" = !!holds[remote],
				"location" = get_area_name(parent, TRUE),
			)
		)

	data["logs"] = list()
	for(var/datum/ore_silo_log/entry as anything in GLOB.silo_access_logs[REF(src)])
		data["logs"] += list(
			list(
				"rawMaterials" = entry.get_raw_materials(""),
				"machineName" = entry.machine_name,
				"areaName" = entry.area_name,
				"action" = entry.action,
				"amount" = entry.amount,
				"time" = entry.timestamp,
				"noun" = entry.noun,
			)
		)

	return data

/obj/machinery/ore_silo/ui_act(action, list/params, datum/tgui/ui, datum/ui_state/state)
	. = ..()
	if(.)
		return

	switch(action)
		if("remove")
			var/index = params["id"]
			if(isnull(index))
				return

			index = text2num(index)
			if(isnull(index))
				return

			var/datum/component/remote_materials/remote = ore_connected_machines[index]
			if(isnull(remote))
				return

			remote.disconnect_from(src)
			return TRUE

		if("hold")
			var/index = params["id"]
			if(isnull(index))
				return

			index = text2num(index)
			if(isnull(index))
				return

			var/datum/component/remote_materials/remote = ore_connected_machines[index]
			if(isnull(remote))
				return

			remote.toggle_holding()
			return TRUE

		if("eject")
			var/datum/material/ejecting = locate(params["ref"])
			if(!istype(ejecting))
				return

			var/amount = params["amount"]
			if(isnull(amount))
				return

			amount = text2num(amount)
			if(isnull(amount))
				return

			materials.retrieve_sheets(amount, ejecting, drop_location())
			return TRUE

/**
 * Creates a log entry for depositing/withdrawing from the silo both ingame and in text based log
 *
 * Arguments:
 * - [M][/obj/machinery]: The machine performing the action.
 * - action: Text that visually describes the action (smelted/deposited/resupplied...)
 * - amount: The amount of sheets/objects deposited/withdrawn by this action. Positive for depositing, negative for withdrawing.
 * - noun: Name of the object the action was performed with (sheet, units, ore...)
 * - [mats][list]: Assoc list in format (material datum = amount of raw materials). Wants the actual amount of raw (iron, glass...) materials involved in this action. If you have 10 metal sheets each worth 100 iron you would pass a list with the iron material datum = 1000
 */
/obj/machinery/ore_silo/proc/silo_log(obj/machinery/M, action, amount, noun, list/mats)
	if (!length(mats))
		return

	var/datum/ore_silo_log/entry = new(M, action, amount, noun, mats)
	var/list/datum/ore_silo_log/logs = GLOB.silo_access_logs[REF(src)]
	if(!LAZYLEN(logs))
		GLOB.silo_access_logs[REF(src)] = logs = list(entry)
	else if(!logs[1].merge(entry))
		logs.Insert(1, entry)

	flick("silo_active", src)

///The log entry for an ore silo action
/datum/ore_silo_log
	///The time of action
	var/timestamp
	///The name of the machine that remotely acted on the ore silo
	var/machine_name
	///The area of the machine that remotely acted on the ore silo
	var/area_name
	///The actual action performed by the machine
	var/action
	///An short verb describing the action
	var/noun
	///The amount of items affected by this action e.g. print quantity, sheets ejected etc.
	var/amount
	///List of individual materials used in the action
	var/list/materials

/datum/ore_silo_log/New(obj/machinery/M, _action, _amount, _noun, list/mats=list())
	timestamp = station_time_timestamp()
	machine_name = M.name
	area_name = get_area_name(M, TRUE)
	action = _action
	amount = _amount
	noun = _noun
	materials = mats.Copy()
	var/list/data = list(
		"machine_name" = machine_name,
		"area_name" = AREACOORD(M),
		"action" = action,
		"amount" = abs(amount),
		"noun" = noun,
		"raw_materials" = get_raw_materials(""),
		"direction" = amount < 0 ? "withdrawn" : "deposited",
	)
	logger.Log(
		LOG_CATEGORY_SILO,
		"[machine_name] in \[[AREACOORD(M)]\] [action] [abs(amount)]x [noun] | [get_raw_materials("")]",
		data,
	)

/**
 * Merges a silo log entry with this one
 * Arguments
 *
 * * datum/ore_silo_log/other - the other silo entry we are trying to merge with this one
 */
/datum/ore_silo_log/proc/merge(datum/ore_silo_log/other)
	if (other == src || action != other.action || noun != other.noun)
		return FALSE
	if (machine_name != other.machine_name || area_name != other.area_name)
		return FALSE

	timestamp = other.timestamp
	amount += other.amount
	for(var/each in other.materials)
		materials[each] += other.materials[each]
	return TRUE

/**
 * Returns list/materials but with each entry joined by an seperator to create 1 string
 * Arguments
 *
 * * separator - the string used to concatenate all entries in list/materials
 */
/datum/ore_silo_log/proc/get_raw_materials(separator)
	var/list/msg = list()
	for(var/key in materials)
		var/datum/material/M = key
		var/val = round(materials[key])
		msg += separator
		separator = ", "
		msg += "[amount < 0 ? "-" : "+"][val] [M.name]"
	return msg.Join()
