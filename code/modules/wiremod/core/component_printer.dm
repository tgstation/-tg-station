/// Component printer, creates components for integrated circuits.
/obj/machinery/component_printer
	name = "component printer"
	desc = "Produces components for the creation of integrated circuits."
	icon = 'icons/obj/machines/wiremod_fab.dmi'
	icon_state = "fab-idle"
	circuit = /obj/item/circuitboard/machine/component_printer

	/// The internal material bus
	var/datum/component/remote_materials/materials

	density = TRUE

	/// The techweb the printer will get researched designs from
	var/datum/techweb/techweb

	/// The current unlocked circuit component designs. Used by integrated circuits to print off circuit components remotely.
	var/list/current_unlocked_designs = list()

	/// The efficiency of this machine
	var/efficiency_coeff = 1

/obj/machinery/component_printer/Initialize(mapload)
	. = ..()
	materials = AddComponent(/datum/component/remote_materials, mapload)

/obj/machinery/component_printer/post_machine_initialize()
	. = ..()
	if(!CONFIG_GET(flag/no_default_techweb_link) && !techweb)
		CONNECT_TO_RND_SERVER_ROUNDSTART(techweb, src)
	if(techweb)
		on_connected_techweb()

/obj/machinery/component_printer/proc/connect_techweb(datum/techweb/new_techweb)
	if(techweb)
		UnregisterSignal(techweb, list(COMSIG_TECHWEB_ADD_DESIGN, COMSIG_TECHWEB_REMOVE_DESIGN))
	techweb = new_techweb
	if(!isnull(techweb))
		on_connected_techweb()

/obj/machinery/component_printer/proc/on_connected_techweb()
	for (var/researched_design_id in techweb.researched_designs)
		var/datum/design/design = SSresearch.techweb_design_by_id(researched_design_id)
		if (!(design.build_type & COMPONENT_PRINTER) || !ispath(design.build_path, /obj/item/circuit_component))
			continue

		current_unlocked_designs[design.build_path] = design.id

	RegisterSignal(techweb, COMSIG_TECHWEB_ADD_DESIGN, PROC_REF(on_research))
	RegisterSignal(techweb, COMSIG_TECHWEB_REMOVE_DESIGN, PROC_REF(on_removed))

/obj/machinery/component_printer/multitool_act(mob/living/user, obj/item/multitool/tool)
	if(!QDELETED(tool.buffer) && istype(tool.buffer, /datum/techweb))
		connect_techweb(tool.buffer)
	return TRUE

/obj/machinery/component_printer/proc/on_research(datum/source, datum/design/added_design, custom)
	SIGNAL_HANDLER
	if (!(added_design.build_type & COMPONENT_PRINTER) || !ispath(added_design.build_path, /obj/item/circuit_component))
		return
	current_unlocked_designs[added_design.build_path] = added_design.id

/obj/machinery/component_printer/proc/on_removed(datum/source, datum/design/added_design, custom)
	SIGNAL_HANDLER
	if (!(added_design.build_type & COMPONENT_PRINTER) || !ispath(added_design.build_path, /obj/item/circuit_component))
		return
	current_unlocked_designs -= added_design.build_path

/obj/machinery/component_printer/base_item_interaction(mob/living/user, obj/item/tool, list/modifiers)
	//to allow quick recycling of circuits
	if(istype(tool, /obj/item/circuit_component))
		var/amount_inserted = materials.insert_item(tool)

		if(amount_inserted)
			to_chat(user, span_notice("[tool] worth [amount_inserted / SHEET_MATERIAL_AMOUNT] sheets of material was consumed by [src]"))
		else
			to_chat(user, span_warning("[tool] was rejected by [src]"))

		return amount_inserted > 0 ? ITEM_INTERACT_SUCCESS : ITEM_INTERACT_FAILURE

	return ..()

/obj/machinery/component_printer/ui_interact(mob/user, datum/tgui/ui)
	ui = SStgui.try_update_ui(user, src, ui)
	if(!ui)
		ui = new(user, src, "ComponentPrinter", name)
		ui.open()

/obj/machinery/component_printer/ui_assets(mob/user)
	return list(
		get_asset_datum(/datum/asset/spritesheet_batched/sheetmaterials)
	)

/obj/machinery/component_printer/RefreshParts()
	. = ..()

	if(materials)
		var/total_storage = 0

		for(var/datum/stock_part/matter_bin/bin in component_parts)
			total_storage += bin.tier * (37.5*SHEET_MATERIAL_AMOUNT)

		materials.set_local_size(total_storage)

	efficiency_coeff = 0

	for(var/datum/stock_part/servo/servo in component_parts)
		///we do -1 because normal manipulators rating of 1 gives us 1-1=0 i.e no decrement in cost
		efficiency_coeff += servo.tier-1

	///linear interpolation between full cost i.e 1 & 1/8th the cost i.e 0.125
	///we do it in 6 steps because maximum rating of 2 manipulators is 8 but -1 gives us 6
	efficiency_coeff = 1.0+((0.125-1.0)*(efficiency_coeff / 6))

	update_static_data_for_all_viewers()

/obj/machinery/component_printer/proc/print_component(typepath)
	var/design_id = current_unlocked_designs[typepath]

	var/datum/design/design = SSresearch.techweb_design_by_id(design_id)
	if (!(design.build_type & COMPONENT_PRINTER))
		return

	if (materials.on_hold())
		return

	if (!materials.mat_container.has_materials(design.materials, efficiency_coeff))
		return

	materials.use_materials(design.materials, efficiency_coeff, 1, "printed", "[design.name]")
	return new design.build_path(drop_location())

/obj/machinery/component_printer/ui_act(action, list/params, datum/tgui/ui, datum/ui_state/state)
	. = ..()
	if (.)
		return

	switch (action)
		if ("print")
			var/design_id = params["designId"]
			if (!techweb.researched_designs[design_id])
				return TRUE

			var/datum/design/design = SSresearch.techweb_design_by_id(design_id)
			if (!(design.build_type & COMPONENT_PRINTER))
				return TRUE

			if (materials.on_hold())
				say("Mineral access is on hold, please contact the quartermaster.")
				return TRUE

			if (!materials.mat_container.has_materials(design.materials, efficiency_coeff))
				say("Not enough materials.")
				return TRUE

			balloon_alert_to_viewers("printed [design.name]")

			materials.use_materials(design.materials, efficiency_coeff, 1, "printed", "[design.name]")
			var/atom/printed_design = new design.build_path(drop_location())
			printed_design.pixel_x = printed_design.base_pixel_x + rand(-5, 5)
			printed_design.pixel_y = printed_design.base_pixel_y + rand(-5, 5)
		if ("remove_mat")
			var/datum/material/material = locate(params["ref"])
			var/amount = text2num(params["amount"])
			// SAFETY: eject_sheets checks for valid mats
			materials.eject_sheets(material, amount)

	return TRUE

/obj/machinery/component_printer/ui_data(mob/user)
	var/list/data = list()
	data["materials"] = materials.mat_container.ui_data()
	return data

/obj/machinery/component_printer/ui_static_data(mob/user)
	var/list/data = materials.mat_container.ui_static_data()

	var/list/designs = list()

	var/datum/asset/spritesheet_batched/research_designs/spritesheet = get_asset_datum(/datum/asset/spritesheet_batched/research_designs)
	var/size32x32 = "[spritesheet.name]32x32"

	// for (var/datum/design/component/component_design_type as anything in subtypesof(/datum/design/component))
	for (var/researched_design_id in techweb.researched_designs)
		var/datum/design/design = SSresearch.techweb_design_by_id(researched_design_id)
		if (!(design.build_type & COMPONENT_PRINTER))
			continue

		var/list/cost = list()
		for(var/datum/material/mat in design.materials)
			cost[mat.name] = OPTIMAL_COST(design.materials[mat] * efficiency_coeff)

		var/icon_size = spritesheet.icon_size_id(design.id)
		designs[researched_design_id] = list(
			"name" = design.name,
			"desc" = design.desc,
			"cost" = cost,
			"id" = researched_design_id,
			"categories" = design.category,
			"icon" = "[icon_size == size32x32 ? "" : "[icon_size] "][design.id]"
		)

	data["designs"] = designs

	return data

/obj/machinery/component_printer/attackby(obj/item/weapon, mob/living/user, params)
	if (user.combat_mode)
		return ..()

	var/obj/item/integrated_circuit/circuit
	if(istype(weapon, /obj/item/integrated_circuit))
		circuit = weapon
	else if (istype(weapon, /obj/item/circuit_component/module))
		var/obj/item/circuit_component/module/module = weapon
		circuit = module.internal_circuit
	if (isnull(circuit))
		return ..()

	circuit.linked_component_printer = WEAKREF(src)
	circuit.update_static_data_for_all_viewers()
	balloon_alert(user, "successfully linked to the integrated circuit")


/obj/machinery/component_printer/crowbar_act(mob/living/user, obj/item/tool)
	if(..())
		return TRUE
	return default_deconstruction_crowbar(tool)

/obj/machinery/component_printer/screwdriver_act(mob/living/user, obj/item/tool)
	if(..())
		return TRUE
	return default_deconstruction_screwdriver(user, "fab-o", "fab-idle", tool)

/obj/machinery/component_printer/proc/get_material_cost_data(list/materials, efficiency_coeff)
	var/list/data = list()

	for (var/datum/material/material_type as anything in materials)
		data[initial(material_type.name)] = materials[material_type] * efficiency_coeff

	return data

/obj/machinery/debug_component_printer
	name = "debug component printer"
	desc = "Produces components for the creation of integrated circuits."
	icon = 'icons/obj/machines/wiremod_fab.dmi'
	icon_state = "fab-idle"

	/// All of the possible circuit designs stored by this debug printer
	var/list/all_circuit_designs

	density = TRUE

/obj/machinery/debug_component_printer/Initialize(mapload)
	. = ..()
	all_circuit_designs = list()

	for(var/id in SSresearch.techweb_designs)
		var/datum/design/design = SSresearch.techweb_design_by_id(id)
		if((design.build_type & COMPONENT_PRINTER) && design.build_path)
			all_circuit_designs[design.build_path] = list(
				"name" = design.name,
				"description" = design.desc,
				"materials" = design.materials,
				"categories" = design.category
			)

	for(var/obj/item/circuit_component/component as anything in subtypesof(/obj/item/circuit_component))
		var/categories = list("Inaccessible")
		if(initial(component.circuit_flags) & CIRCUIT_FLAG_ADMIN)
			categories = list("Admin")
		if(!(component in all_circuit_designs))
			all_circuit_designs[component] = list(
				"name" = initial(component.display_name),
				"description" = initial(component.desc),
				"materials" = list(),
				"categories" = categories,
			)

/obj/machinery/debug_component_printer/ui_interact(mob/user, datum/tgui/ui)
	ui = SStgui.try_update_ui(user, src, ui)
	if(!ui)
		ui = new(user, src, "ComponentPrinter", name)
		ui.open()

/obj/machinery/debug_component_printer/ui_assets(mob/user)
	return list(
		get_asset_datum(/datum/asset/spritesheet_batched/sheetmaterials),
		get_asset_datum(/datum/asset/spritesheet_batched/research_designs)
	)

/obj/machinery/debug_component_printer/ui_act(action, list/params, datum/tgui/ui, datum/ui_state/state)
	. = ..()
	if (.)
		return

	switch (action)
		if ("print")
			var/build_path = text2path(params["designId"])
			if (!build_path)
				return TRUE

			var/list/design = all_circuit_designs[build_path]
			if(!design)
				return TRUE

			balloon_alert_to_viewers("printed [design["name"]]")
			var/atom/printed_design = new build_path(drop_location())
			printed_design.pixel_x = printed_design.base_pixel_x + rand(-5, 5)
			printed_design.pixel_y = printed_design.base_pixel_y + rand(-5, 5)

	return TRUE

/obj/machinery/debug_component_printer/ui_static_data(mob/user)
	var/list/data = list()

	data["materials"] = list()
	data["designs"] = all_circuit_designs

	return data

/// Module duplicator, allows you to save and recreate module components.
/obj/machinery/module_duplicator
	name = "module duplicator"
	desc = "Allows you to duplicate module components so that you don't have to recreate them. Scan a module component over this machine to add it as an entry."
	icon = 'icons/obj/machines/wiremod_fab.dmi'
	icon_state = "module-fab-idle"
	circuit = /obj/item/circuitboard/machine/module_duplicator
	density = TRUE

	///The internal material bus
	var/datum/component/remote_materials/materials
	///List of designs scanned and saved
	var/list/scanned_designs = list()
	///Constant material cost per component
	var/cost_per_component = SHEET_MATERIAL_AMOUNT / 10
	///Cost efficiency of this machine
	var/efficiency_coeff = 1

/obj/machinery/module_duplicator/Initialize(mapload)
	. = ..()

	materials = AddComponent(/datum/component/remote_materials, mapload)

/obj/machinery/module_duplicator/ui_interact(mob/user, datum/tgui/ui)
	ui = SStgui.try_update_ui(user, src, ui)
	if(!ui)
		ui = new(user, src, "ComponentPrinter", name)
		ui.open()

/obj/machinery/module_duplicator/ui_assets(mob/user)
	return list(
		get_asset_datum(/datum/asset/spritesheet_batched/sheetmaterials),
		get_asset_datum(/datum/asset/spritesheet_batched/research_designs)
	)

/obj/machinery/module_duplicator/RefreshParts()
	. = ..()

	if(materials)
		var/total_storage = 0

		for(var/datum/stock_part/matter_bin/bin in component_parts)
			total_storage += bin.tier * (37.5*SHEET_MATERIAL_AMOUNT)

		materials.set_local_size(total_storage)

	efficiency_coeff = 0

	for(var/datum/stock_part/servo/servo in component_parts)
		///we do -1 because normal manipulators rating of 1 gives us 1-1=0 i.e no decrement in cost
		efficiency_coeff += servo.tier - 1

	///linear interpolation between full cost i.e 1 & 1/8th the cost i.e 0.125
	///we do it in 6 steps because maximum rating of 2 manipulators is 8 but -1 gives us 6
	efficiency_coeff = 1.0 + ((0.125 - 1.0) * (efficiency_coeff / 6))

	update_static_data_for_all_viewers()

/obj/machinery/module_duplicator/ui_act(action, list/params, datum/tgui/ui, datum/ui_state/state)
	. = ..()
	if (.)
		return

	switch (action)
		if ("print")
			var/design_id = text2num(params["designId"])

			if (design_id < 1 || design_id > length(scanned_designs))
				return TRUE

			var/list/design = scanned_designs[design_id]

			if (materials.on_hold())
				say("Mineral access is on hold, please contact the quartermaster.")
				return TRUE

			if (!materials.mat_container.has_materials(design["materials"], efficiency_coeff))
				say("Not enough materials.")
				return TRUE

			materials.use_materials(design["materials"], efficiency_coeff, 1, design["name"], design["materials"])
			print_module(design)
			balloon_alert_to_viewers("printed [design["name"]]")
		if ("remove_mat")
			var/datum/material/material = locate(params["ref"])
			var/amount = text2num(params["amount"])
			// SAFETY: eject_sheets checks for valid mats
			materials.eject_sheets(material, amount)

	return TRUE

/obj/machinery/module_duplicator/proc/print_module(list/design)
	flick("module-fab-print", src)
	addtimer(CALLBACK(src, PROC_REF(finish_module_print), design), 1.6 SECONDS)

/obj/machinery/module_duplicator/proc/finish_module_print(list/design)
	var/atom/movable/created_atom
	if(design["integrated_circuit"])
		var/obj/item/integrated_circuit/circuit = new(drop_location())
		var/list/errors = list()
		circuit.load_circuit_data(design["dupe_data"], errors)
		if(length(errors))
			stack_trace("Error loading user saved circuit [errors.Join(", ")].")
		created_atom = circuit
	else
		var/obj/item/circuit_component/module/module = new(drop_location())
		module.load_data_from_list(design["dupe_data"])
		created_atom = module
	created_atom.pixel_x = created_atom.base_pixel_x + rand(-5, 5)
	created_atom.pixel_y = created_atom.base_pixel_y + rand(-5, 5)

/obj/machinery/module_duplicator/attackby(obj/item/weapon, mob/user, params)
	var/list/data = list()

	if(istype(weapon, /obj/item/circuit_component/module))
		var/obj/item/circuit_component/module/module = weapon
		if(HAS_TRAIT(module, TRAIT_CIRCUIT_UNDUPABLE))
			balloon_alert(user, "integrated circuit cannot be saved!")
			return ..()

		data["dupe_data"] = list()
		module.save_data_to_list(data["dupe_data"])

		data["name"] = module.display_name
		data["desc"] = "A module that has been loaded in by [user]."
		data["materials"] = list(GET_MATERIAL_REF(/datum/material/glass) = module.circuit_size * cost_per_component)
	else if(istype(weapon, /obj/item/integrated_circuit))
		var/obj/item/integrated_circuit/integrated_circuit = weapon
		if(HAS_TRAIT(integrated_circuit, TRAIT_CIRCUIT_UNDUPABLE))
			balloon_alert(user, "integrated circuit cannot be saved!")
			return ..()
		data["dupe_data"] = integrated_circuit.convert_to_json()

		data["name"] = integrated_circuit.display_name
		data["desc"] = "An integrated circuit that has been loaded in by [user]."

		var/datum/design/integrated_circuit/circuit_design = SSresearch.techweb_design_by_id("integrated_circuit")
		var/materials = list(GET_MATERIAL_REF(/datum/material/glass) = integrated_circuit.current_size * cost_per_component)
		for(var/material_type in circuit_design.materials)
			materials[material_type] += circuit_design.materials[material_type]

		data["materials"] = materials
		data["integrated_circuit"] = TRUE

	if(!length(data))
		return ..()

	if(!data["name"])
		balloon_alert(user, "it needs a name!")
		return ..()

	for(var/list/component_data as anything in scanned_designs)
		if(component_data["name"] == data["name"])
			balloon_alert(user, "name already exists!")
			return ..()

	flick("module-fab-scan", src)
	addtimer(CALLBACK(src, PROC_REF(finish_module_scan), user, data), 1.4 SECONDS)

/obj/machinery/module_duplicator/proc/finish_module_scan(mob/user, data)
	scanned_designs += list(data)

	balloon_alert(user, "module has been saved.")
	playsound(src, 'sound/machines/ping.ogg', 50)

	update_static_data_for_all_viewers()

/obj/machinery/module_duplicator/ui_data(mob/user)
	var/list/data = list()
	data["materials"] = materials.mat_container.ui_data()
	return data

/obj/machinery/module_duplicator/ui_static_data(mob/user)
	var/list/data = materials.mat_container.ui_static_data()

	var/list/designs = list()

	var/index = 1
	for (var/list/design as anything in scanned_designs)

		var/list/cost = list()
		var/list/materials = design["materials"]
		for(var/datum/material/mat in materials)
			cost[mat.name] = OPTIMAL_COST(materials[mat] * efficiency_coeff)

		designs["[index]"] = list(
			"name" = design["name"],
			"desc" = design["desc"],
			"cost" = cost,
			"id" = "[index]",
			"icon" = "integrated_circuit",
			"categories" = list("/Saved Circuits"),
		)
		index++

	data["designs"] = designs

	return data

/obj/machinery/module_duplicator/crowbar_act(mob/living/user, obj/item/tool)
	if(..())
		return TRUE
	return default_deconstruction_crowbar(tool)

/obj/machinery/module_duplicator/screwdriver_act(mob/living/user, obj/item/tool)
	if(..())
		return TRUE
	return default_deconstruction_screwdriver(user, "module-fab-o", "module-fab-idle", tool)
