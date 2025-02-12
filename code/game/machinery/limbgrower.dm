/// The limbgrower. Makes organd and limbs with synthflesh and chems.
/// See [limbgrower_designs.dm] for everything we can make.
/obj/machinery/limbgrower
	name = "limb grower"
	desc = "It grows new limbs using Synthflesh."
	icon = 'icons/obj/machines/limbgrower.dmi'
	icon_state = "limbgrower_idleoff"
	density = TRUE
	circuit = /obj/item/circuitboard/machine/limbgrower
	interaction_flags_atom = parent_type::interaction_flags_atom | INTERACT_ATOM_REQUIRES_ANCHORED

	/// The category of limbs we're browing in our UI.
	var/selected_category = SPECIES_HUMAN
	/// If we're currently printing something.
	var/busy = FALSE
	/// How efficient our machine is. Better parts = less chemicals used and less power used. Range of 1 to 0.25.
	var/production_coefficient = 1
	/// How long it takes for us to print a limb. Affected by production_coefficient.
	var/production_speed = 3 SECONDS
	/// The design we're printing currently.
	var/datum/design/being_built
	/// Our internal techweb for limbgrower designs.
	var/datum/techweb/autounlocking/stored_research
	/// All the categories of organs we can print.
	var/list/categories = list(SPECIES_HUMAN, SPECIES_LIZARD, SPECIES_MOTH, SPECIES_PLASMAMAN, SPECIES_ETHEREAL, RND_CATEGORY_LIMBS_OTHER, RND_CATEGORY_LIMBS_DIGITIGRADE)
	///Designs imported from technology disks that we can print.
	var/list/imported_designs = list()

/obj/machinery/limbgrower/Initialize(mapload)
	create_reagents(100, OPENCONTAINER)
	if(!GLOB.autounlock_techwebs[/datum/techweb/autounlocking/limbgrower])
		GLOB.autounlock_techwebs[/datum/techweb/autounlocking/limbgrower] = new /datum/techweb/autounlocking/limbgrower
	stored_research = GLOB.autounlock_techwebs[/datum/techweb/autounlocking/limbgrower]
	. = ..()
	AddComponent(/datum/component/plumbing/simple_demand)
	AddComponent(/datum/component/simple_rotation)
	register_context()

/obj/machinery/limbgrower/add_context(atom/source, list/context, obj/item/held_item, mob/user)
	. = ..()
	if(!held_item)
		return NONE

	switch(held_item.tool_behaviour)
		if(TOOL_SCREWDRIVER)
			context[SCREENTIP_CONTEXT_LMB] = "[panel_open ? "Close" : "Open"] panel"
			. = CONTEXTUAL_SCREENTIP_SET
		if(TOOL_WRENCH)
			context[SCREENTIP_CONTEXT_LMB] = "[anchored ? "Unan" : "An"]chor"
			. = CONTEXTUAL_SCREENTIP_SET

	if(istype(held_item, /obj/item/disk/design_disk/limbs))
		context[SCREENTIP_CONTEXT_LMB] = "Load limb designs"
		. = CONTEXTUAL_SCREENTIP_SET

/// Emagging a limbgrower allows you to build synthetic armblades.
/obj/machinery/limbgrower/emag_act(mob/user, obj/item/card/emag/emag_card)
	. = ..()
	if(obj_flags & EMAGGED)
		return FALSE
	obj_flags |= EMAGGED
	update_static_data(user)
	balloon_alert(user, "illegal limb production enabled")
	return TRUE

/obj/machinery/limbgrower/ui_interact(mob/user, datum/tgui/ui)
	. = ..()
	ui = SStgui.try_update_ui(user, src, ui)
	if(!ui)
		ui = new(user, src, "Limbgrower")
		ui.open()

/obj/machinery/limbgrower/ui_state(mob/user)
	return GLOB.physical_state

/obj/machinery/limbgrower/ui_data(mob/user)
	var/list/data = list()

	for(var/datum/reagent/reagent_id in reagents.reagent_list)
		var/list/reagent_data = list(
			reagent_name = reagent_id.name,
			reagent_amount = reagent_id.volume,
			reagent_type = reagent_id.type
		)
		data["reagents"] += list(reagent_data)

	data["total_reagents"] = reagents.total_volume
	data["max_reagents"] = reagents.maximum_volume
	data["busy"] = busy

	return data

/obj/machinery/limbgrower/ui_static_data(mob/user)
	var/list/data = list()
	data["categories"] = list()

	var/species_categories = categories.Copy()
	for(var/species in species_categories)
		species_categories[species] = list()

	var/list/available_nodes = stored_research.researched_designs.Copy()
	if(imported_designs.len)
		available_nodes |= imported_designs
	if(obj_flags & EMAGGED)
		available_nodes |= stored_research.hacked_designs

	for(var/design_id in available_nodes)
		var/datum/design/limb_design = SSresearch.techweb_design_by_id(design_id)
		for(var/found_category in species_categories)
			if(found_category in limb_design.category)
				species_categories[found_category] += limb_design

	for(var/category in species_categories)
		var/list/category_data = list(
			name = category,
			designs = list(),
		)
		for(var/datum/design/found_design in species_categories[category])
			var/list/all_reagents = list()
			for(var/reagent_typepath in found_design.reagents_list)
				var/datum/reagent/reagent_id = find_reagent_object_from_type(reagent_typepath)
				var/list/reagent_data = list(
					name = reagent_id.name,
					amount = (found_design.reagents_list[reagent_typepath] * production_coefficient),
				)
				all_reagents += list(reagent_data)

			category_data["designs"] += list(list(
				parent_category = category,
				name = found_design.name,
				id = found_design.id,
				needed_reagents = all_reagents,
			))

		data["categories"] += list(category_data)

	return data

/obj/machinery/limbgrower/on_deconstruction(disassembled)
	for(var/obj/item/reagent_containers/cup/our_beaker in component_parts)
		reagents.trans_to(our_beaker, our_beaker.reagents.maximum_volume)
	return ..()

/obj/machinery/limbgrower/item_interaction(mob/living/user, obj/item/tool, list/modifiers)
	. = ..()
	if(user.combat_mode)
		return ITEM_INTERACT_SKIP_TO_ATTACK

	if(check_busy(user))
		return ITEM_INTERACT_BLOCKING

	if(istype(tool, /obj/item/disk/design_disk/limbs))
		user.visible_message(span_notice("[user] begins to load \the [tool] in \the [src]..."),
			span_notice("You begin to load designs from \the [tool]..."),
			span_hear("You hear the clatter of a floppy drive."))
		busy = TRUE
		var/obj/item/disk/design_disk/limbs/limb_design_disk = tool
		if(do_after(user, 2 SECONDS, target = src))
			for(var/datum/design/found_design in limb_design_disk.blueprints)
				imported_designs[found_design.id] = TRUE
			update_static_data(user)
		busy = FALSE
		return ITEM_INTERACT_SUCCESS

/obj/machinery/limbgrower/screwdriver_act(mob/living/user, obj/item/tool)
	. = ..()
	if(check_busy(user))
		return ITEM_INTERACT_BLOCKING

	. = default_deconstruction_screwdriver(user, "limbgrower_panelopen", "limbgrower_idleoff", tool)
	if(.)
		ui_close(user)

/obj/machinery/limbgrower/crowbar_act(mob/living/user, obj/item/tool)
	. = ..()
	if(check_busy(user))
		return ITEM_INTERACT_BLOCKING

	return default_deconstruction_crowbar(tool)

/obj/machinery/limbgrower/wrench_act(mob/living/user, obj/item/tool)
	. = ..()
	if(check_busy(user))
		return ITEM_INTERACT_BLOCKING

	if(default_unfasten_wrench(user, tool))
		return ITEM_INTERACT_SUCCESS

/obj/machinery/limbgrower/ui_act(action, list/params, datum/tgui/ui, datum/ui_state/state)
	. = ..()
	if(.)
		return

	if (check_busy(usr))
		return

	switch(action)

		if("empty_reagent")
			reagents.del_reagent(text2path(params["reagent_type"]))
			. = TRUE

		if("make_limb")
			var/design_id = params["design_id"]
			if(!stored_research.researched_designs.Find(design_id) && !stored_research.hacked_designs.Find(design_id) && !imported_designs.Find(design_id))
				return
			being_built = SSresearch.techweb_design_by_id(design_id)
			// All the reagents we're using to make our organ.
			var/list/consumed_reagents_list = being_built.reagents_list.Copy()
			/// The amount of power we're going to use, based on how much reagent we use.
			var/power = 0

			for(var/reagent_id in consumed_reagents_list)
				consumed_reagents_list[reagent_id] *= production_coefficient
				if(!reagents.has_reagent(reagent_id, consumed_reagents_list[reagent_id]))
					audible_message(span_notice("[src] buzzes."))
					playsound(src, 'sound/machines/buzz/buzz-sigh.ogg', 50, FALSE)
					return

				power = max(active_power_usage, (power + consumed_reagents_list[reagent_id]))

			busy = TRUE
			use_energy(power)
			flick("limbgrower_fill", src)
			icon_state = "limbgrower_idleon"
			var/temp_category = params["active_tab"]
			if( ! (temp_category in categories) )
				return FALSE //seriously come on
			selected_category = temp_category
			addtimer(CALLBACK(src, PROC_REF(build_item), consumed_reagents_list), production_speed * production_coefficient)
			return TRUE

/*
 * The process of beginning to build a limb or organ.
 * Goes through and sanity checks that we actually have enough reagent to build our item.
 * Then, remove those reagents from our reagents datum.
 *
 * After the reagents are handled, we can proceede with making the limb or organ. (Limbs are handled in a separate proc)
 *
 * modified_consumed_reagents_list - the list of reagents we will consume on build, modified by the production coefficient.
 */
/obj/machinery/limbgrower/proc/build_item(list/modified_consumed_reagents_list)
	for(var/reagent_id in modified_consumed_reagents_list)
		if(!reagents.has_reagent(reagent_id, modified_consumed_reagents_list[reagent_id]))
			audible_message(span_notice("The [src] buzzes."))
			playsound(src, 'sound/machines/buzz/buzz-sigh.ogg', 50, FALSE)
			break

		reagents.remove_reagent(reagent_id, modified_consumed_reagents_list[reagent_id])

	var/built_typepath = being_built.build_path
	if(ispath(built_typepath, /obj/item/bodypart))
		build_limb(create_buildpath())
	else
		//Just build whatever it is
		new built_typepath(loc)

	busy = FALSE
	flick("limbgrower_unfill", src)
	icon_state = "limbgrower_idleoff"

/*
 * The process of putting together a limb.
 * This is called from after we remove the reagents, so this proc is just initializing the limb type.
 *
 * This proc handles skin / mutant color, greyscaling, names and descriptions, and various other limb creation steps.
 *
 * buildpath - the path of the bodypart we're building.
 */
/obj/machinery/limbgrower/proc/build_limb(buildpath)
	/// The limb we're making with our buildpath, so we can edit it.
	//i need to create a body part manually using a set icon (otherwise it doesn't appear)
	var/obj/item/bodypart/limb
	limb = new buildpath(loc)
	limb.name = "\improper synthetic [selected_category] [limb.plaintext_zone]"
	limb.limb_id = selected_category
	limb.species_color = "#62A262"
	limb.update_icon_dropped()

///Returns a valid limb typepath based on the selected option
/obj/machinery/limbgrower/proc/create_buildpath()
	var/part_type = being_built.id //their ids match bodypart typepaths
	var/species = selected_category
	var/path
	if(species == SPECIES_HUMAN) //Humans use the parent type.
		path = "/obj/item/bodypart/[part_type]"
	else
		path = "/obj/item/bodypart/[part_type]/[species]"
	return text2path(path)

/obj/machinery/limbgrower/RefreshParts()
	. = ..()
	reagents.maximum_volume = 0
	for(var/obj/item/reagent_containers/cup/our_beaker in component_parts)
		reagents.maximum_volume += our_beaker.volume
		our_beaker.reagents.trans_to(src, our_beaker.reagents.total_volume)
	production_coefficient = 1.25
	for(var/datum/stock_part/servo/our_servo in component_parts)
		production_coefficient -= our_servo.tier * 0.25
	production_coefficient = clamp(production_coefficient, 0, 1) // coefficient goes from 1 -> 0.75 -> 0.5 -> 0.25

/obj/machinery/limbgrower/examine(mob/user)
	. = ..()
	if(in_range(user, src) || isobserver(user))
		. += span_notice("The status display reads: Storing up to <b>[reagents.maximum_volume]u</b> of reagents.<br>Reagent consumption rate at <b>[production_coefficient * 100]%</b>.")

/**
 * Check if the limb grower is currently busy.
 *
 * user - user initiating the check.
 *
 * returns the value of src.busy.
 */
/obj/machinery/limbgrower/proc/check_busy(mob/user)
	. = busy
	if(.)
		to_chat(user, span_warning("The limb grower is busy. Please wait for completion of previous operation."))

/*
 * Checks our reagent list to see if a design can be built.
 *
 * limb_design - the design we're checking for buildability.
 *
 * returns TRUE if we have enough reagent to build it. Returns FALSE if we do not.
 */
/obj/machinery/limbgrower/proc/can_build(datum/design/limb_design)
	for(var/datum/reagent/reagent_id in limb_design.reagents_list)
		if(!reagents.has_reagent(reagent_id, limb_design.reagents_list[reagent_id] * production_coefficient))
			return FALSE
	return TRUE

/obj/machinery/limbgrower/fullupgrade //Inherently cheaper organ production. This is to NEVER be inherently emagged, no valids.
	desc = "It grows new limbs using Synthflesh. This alien model seems more efficient."
	circuit = /obj/item/circuitboard/machine/limbgrower/fullupgrade

/obj/machinery/limbgrower/fullupgrade/Initialize(mapload)
	. = ..()
	for(var/id in SSresearch.techweb_designs)
		var/datum/design/found_design = SSresearch.techweb_design_by_id(id)
		if((found_design.build_type & LIMBGROWER) && !(RND_CATEGORY_HACKED in found_design.category))
			imported_designs |= found_design.id
