/// How many more items does `max_items` get increased by per rating point.
#define MAX_ITEMS_PER_RATING 10
/// How many items are converted per cycle, per rating point of the manipulator used.
#define PROCESSED_ITEMS_PER_RATING 5

/obj/machinery/biogenerator
	name = "biogenerator"
	desc = "Converts plants into biomass, which can be used to construct useful items."
	icon = 'icons/obj/machines/biogenerator.dmi'
	icon_state = "biogenerator"
	density = TRUE
	circuit = /obj/item/circuitboard/machine/biogenerator
	processing_flags = START_PROCESSING_MANUALLY
	interaction_flags_click = FORBID_TELEKINESIS_REACH
	/// Whether the biogenerator is currently processing biomass or not.
	var/processing = FALSE
	/// The reagent container that is currently inside of the biomass generator. Can be null.
	var/obj/item/reagent_containers/cup/beaker = null
	/// The amount of biomass that's currently stored in the biogenerator.
	var/biomass = 0
	/// The amount by which the biomass consumption will be divided.
	var/efficiency = 1
	/// The conversion factor for nutrient to biomass, and the amount of additional items that will be processed at once per cycle.
	var/productivity = 1
	/// The amount of items that will be converted into biomass per processing cycle.
	var/processed_items_per_cycle = 5
	/// The maximum amount of items the biogenerator can hold for biomass conversion purposes.
	var/max_items = 20
	/// The current amount of items that can be converted into biomass that the biogenerator is holding.
	var/current_item_count = 0
	/// The maximum amount of biomass that will affect the visuals of the biogenerator.
	var/max_visual_biomass = 5000
	/// The maximum amount of reagents that the biogenerator can output to a container at once.
	var/max_output = 50
	/// The research that is stored within this biogenerator.
	var/datum/techweb/stored_research
	/// The different visual categories for the biogenerator, for the tabs.
	var/list/show_categories = list(
		RND_CATEGORY_BIO_FOOD,
		RND_CATEGORY_BIO_CHEMICALS,
		RND_CATEGORY_BIO_MATERIALS,
	)
	/// The category that's currently selected in the UI.
	var/selected_cat
	/// The sound loop that can be heard when the generator is processing.
	var/datum/looping_sound/generator/soundloop
	/// Whether the biogen is welded down to the floor disabling unwrenching
	var/welded_down = FALSE

/obj/machinery/biogenerator/Initialize(mapload)
	. = ..()
	if(!GLOB.autounlock_techwebs[/datum/techweb/autounlocking/biogenerator])
		GLOB.autounlock_techwebs[/datum/techweb/autounlocking/biogenerator] = new /datum/techweb/autounlocking/biogenerator
	stored_research = GLOB.autounlock_techwebs[/datum/techweb/autounlocking/biogenerator]
	soundloop = new(src, processing)
	if(mapload)
		welded_down = TRUE

/obj/machinery/biogenerator/can_be_unfasten_wrench(mob/user, silent)
	if(welded_down)
		to_chat(user, span_warning("[src] is welded to the floor!"))
		return FAILED_UNFASTEN
	return ..()

/obj/machinery/biogenerator/set_anchored(anchorvalue)
	. = ..()
	if(!anchored && welded_down) //make sure they're keep in sync in case it was forcibly unanchored by badmins or by a megafauna.
		welded_down = FALSE

/obj/machinery/biogenerator/welder_act(mob/living/user, obj/item/tool)
	..()
	if(welded_down)
		if(!tool.tool_start_check(user, amount=2))
			return TRUE
		user.visible_message(
			span_notice("[user.name] starts to cut \the [src] free from the floor."),
			span_notice("You start to cut [src] free from the floor..."),
			span_hear("You hear welding."),
		)
		if(!tool.use_tool(src, user, 10 SECONDS, volume=100))
			return FALSE
		welded_down = FALSE
		to_chat(user, span_notice("You cut [src] free from the floor."))
		return TRUE
	if(!anchored)
		to_chat(user, span_warning("[src] needs to be wrenched to the floor!"))
		return TRUE
	if(!tool.tool_start_check(user, amount=2))
		return TRUE
	user.visible_message(
		span_notice("[user.name] starts to weld \the [src] to the floor."),
		span_notice("You start to weld [src] to the floor..."),
		span_hear("You hear welding."),
	)
	if(!tool.use_tool(src, user, 10 SECONDS, volume=100))
		balloon_alert(user, "cancelled!")
		return FALSE
	welded_down = TRUE
	to_chat(user, span_notice("You weld [src] to the floor."))
	return TRUE

/obj/machinery/biogenerator/Destroy()
	QDEL_NULL(beaker)
	QDEL_NULL(soundloop)
	return ..()

/obj/machinery/biogenerator/contents_explosion(severity, target)
	. = ..()
	if(!beaker)
		return

	switch(severity)
		if(EXPLODE_DEVASTATE)
			SSexplosions.high_mov_atom += beaker
		if(EXPLODE_HEAVY)
			SSexplosions.med_mov_atom += beaker
		if(EXPLODE_LIGHT)
			SSexplosions.low_mov_atom += beaker

/obj/machinery/biogenerator/Exited(atom/movable/gone, direction)
	. = ..()
	if(gone == beaker)
		beaker = null
		update_appearance()

/obj/machinery/biogenerator/RefreshParts()
	. = ..()

	var/new_efficiency = 0
	var/new_productivity = 0
	var/new_max_items = 10
	var/new_processed_items_per_cycle = 0

	for(var/datum/stock_part/matter_bin/bin in component_parts)
		new_max_items += MAX_ITEMS_PER_RATING * bin.tier

	for(var/datum/stock_part/servo/servo in component_parts)
		new_productivity += servo.tier
		new_efficiency += servo.tier
		new_processed_items_per_cycle += PROCESSED_ITEMS_PER_RATING * servo.tier

	max_items = new_max_items
	efficiency = new_efficiency
	productivity = new_productivity
	processed_items_per_cycle = new_processed_items_per_cycle

	update_appearance()


/obj/machinery/biogenerator/examine(mob/user)
	. = ..()

	if(in_range(user, src) || isobserver(user))
		. += span_notice("The status display reads:")
		. += span_notice(" - Productivity at <b>[productivity * 100]%</b>.")
		. += span_notice(" - Converting <b>[processed_items_per_cycle]</b> pieces of food per cycle.")
		. += span_notice(" - Matter consumption at <b>[1 / efficiency * 100]</b>%.")
		. += span_notice(" - Internal biomass converter capacity at <b>[max_items]</b> pieces of food, and currently holding <b>[current_item_count]</b>.")

	if(welded_down)
		. += span_info("It's moored firmly to the floor. You can unsecure its moorings with a <b>welder</b>.")

/obj/machinery/biogenerator/update_appearance()
	. = ..()

	var/power = machine_stat & (NOPOWER|BROKEN) ? 0 : 1 + min(biomass / max_visual_biomass, 1) + (processing & 1)
	set_light(MINIMUM_USEFUL_LIGHT_RANGE, power, LIGHT_COLOR_CYAN)


/obj/machinery/biogenerator/update_overlays()
	. = ..()

	if(panel_open)
		. += mutable_appearance(icon, "[icon_state]_o_panel")

	if(beaker)
		. += mutable_appearance(icon, "[icon_state]_o_container")

	if(biomass > 0)
		// Get current biomass volume adjusted with sine function (more biomass = less frequent icon changes)
		var/biomass_volume_sin = sin(min(biomass/max_visual_biomass, 1) * 90)
		// Round up to get the corresponding overlay icon
		var/biomass_level = ROUND_UP(biomass_volume_sin * 7)
		. += mutable_appearance(icon, "[icon_state]_o_biomass_[biomass_level]")
		. += emissive_appearance(icon, "[icon_state]_o_biomass_[biomass_level]", src)

	if(machine_stat & (NOPOWER|BROKEN))
		return

	if(processing)
		. += mutable_appearance(icon, "[icon_state]_o_process")
		. += emissive_appearance(icon, "[icon_state]_o_process", src)

	. += mutable_appearance(icon, "[icon_state]_o_screen")
	. += emissive_appearance(icon, "[icon_state]_o_screen", src)

/obj/machinery/biogenerator/wrench_act(mob/living/user, obj/item/tool)
	. = ..()
	default_unfasten_wrench(user, tool)
	return ITEM_INTERACT_SUCCESS

/obj/machinery/biogenerator/attackby(obj/item/attacking_item, mob/living/user, params)
	if(user.combat_mode)
		return ..()

	if(default_deconstruction_screwdriver(user, icon_state, icon_state, attacking_item))
		if(processing)
			stop_process(FALSE)

		if(beaker)
			beaker.forceMove(drop_location())
			beaker = null

		update_appearance(UPDATE_ICON)
		return

	var/turf/drop_location = drop_location()
	if(default_deconstruction_crowbar(attacking_item))
		if(biomass > 0)
			drop_location.visible_message(span_warning("Biomass spills from \the [src]'s biomass tank!"))
			playsound(drop_location, 'sound/effects/slosh.ogg', 25, vary = TRUE)
			new /obj/effect/decal/cleanable/greenglow(drop_location)

		return

	if(istype(attacking_item, /obj/item/reagent_containers/cup))
		if(panel_open)
			to_chat(user, span_warning("Close the maintenance panel first."))
		else
			insert_beaker(user, attacking_item)

		return TRUE

	else if(istype(attacking_item, /obj/item/storage/bag))
		if(current_item_count >= max_items)
			to_chat(user, span_warning("\The [src] is already full! Activate it to free up some space."))
			return TRUE

		var/obj/item/storage/bag/bag = attacking_item

		for(var/obj/item/food/item in bag.contents)
			if(current_item_count >= max_items)
				break

			if(bag.atom_storage.attempt_remove(item, src))
				current_item_count++

		if(bag.contents.len == 0)
			to_chat(user, span_info("You empty \the [bag] into \the [src]."))

		else if (current_item_count >= max_items)
			to_chat(user, span_info("You fill \the [src] from \the [bag] to its capacity."))

		else
			to_chat(user, span_info("You fill \the [src] from \the [bag]."))

		return TRUE //no afterattack

	else if(istype(attacking_item, /obj/item/food))
		if(current_item_count >= max_items)
			to_chat(user, span_warning("\The [src] is full! Activate it."))

		else
			if(user.transferItemToLoc(attacking_item, src))
				current_item_count++
				to_chat(user, span_info("You insert \the [attacking_item] in \the [src]"))

		return TRUE //no afterattack

	else
		to_chat(user, span_warning("You cannot put \the [attacking_item] in \the [src]!"))


/obj/machinery/biogenerator/click_alt(mob/living/user)
	eject_beaker(user)
	return CLICK_ACTION_SUCCESS


/// Activates biomass processing and converts all inserted food products into biomass
/obj/machinery/biogenerator/proc/start_process()
	if(machine_stat != NONE || panel_open)
		return

	if(processing)
		say("Already working!")
		return

	if(!(locate(/obj/item/food) in contents))
		say("No food items found!")
		return

	begin_processing()
	processing = TRUE
	soundloop.start()
	update_appearance()


/obj/machinery/biogenerator/process(seconds_per_tick)
	if(!processing)
		return

	if(machine_stat != NONE || panel_open)
		stop_process()
		return

	if(!current_item_count)
		stop_process()
		return

	for(var/i in 1 to processed_items_per_cycle)
		var/obj/item/food/food_to_convert = locate(/obj/item/food) in contents

		if(!food_to_convert)
			break

		if(food_to_convert.flags_1 & HOLOGRAM_1)
			qdel(food_to_convert)
			current_item_count = max(current_item_count - 1, 0)
			continue

		convert_to_biomass(food_to_convert)

	use_energy(active_power_usage * seconds_per_tick)

	if(!current_item_count)
		stop_process(FALSE)

	update_appearance()



/**
 * Simple helper proc that converts the given food item into biomass for the generator,
 * while also handling removing it and modifying the `current_item_count`.
 *
 * Arguments:
 * * food_to_convert - The food item that will be converted into biomass and
 * subsequently be deleted.
 */
/obj/machinery/biogenerator/proc/convert_to_biomass(obj/item/food/food_to_convert)
	var/nutriments = ROUND_UP(food_to_convert.reagents.get_reagent_amount(/datum/reagent/consumable/nutriment, type_check = REAGENT_PARENT_TYPE))
	qdel(food_to_convert)
	current_item_count = max(current_item_count - 1, 0)
	biomass += nutriments * productivity


/**
 * Simple helper to handle stopping the process of the biogenerator.
 *
 * Arguments:
 * * update_appearance - Whether or not we call `update_appearance()` here.
 * Defaults to `TRUE`.
 */
/obj/machinery/biogenerator/proc/stop_process(update_appearance = TRUE)
	end_processing()
	processing = FALSE
	soundloop.stop()

	if(update_appearance)
		update_appearance()


/obj/machinery/biogenerator/proc/use_biomass(list/materials, amount = 1, remove_biomass = TRUE)
	if(materials.len != 1 || materials[1] != GET_MATERIAL_REF(/datum/material/biomass))
		return FALSE

	var/cost = materials[GET_MATERIAL_REF(/datum/material/biomass)] * amount / efficiency
	if (cost > biomass)
		return FALSE


	if(remove_biomass)
		biomass -= cost

	update_appearance()
	return TRUE


/obj/machinery/biogenerator/proc/create_product(datum/design/design, amount)
	if(design.make_reagent)
		if(!beaker)
			return FALSE

		if(beaker.reagents.maximum_volume - beaker.reagents.total_volume < amount)
			say("Warning: Attached container does not have enough free capacity!")
			return FALSE

		if(!use_biomass(design.materials, amount))
			return FALSE

		beaker.reagents.add_reagent(design.make_reagent, amount, added_purity = BIOGEN_REAGENT_PURITY)

	if(design.build_path)
		if(!use_biomass(design.materials, amount))
			return FALSE

		if(istype(design.build_path, /obj/item/stack/sheet))
			new design.build_path(drop_location(), amount)

		else
			var/drop_location = drop_location()
			for(var/i in 1 to amount)
				new design.build_path(drop_location)

	return TRUE


/*
 * Insert a new beaker into the biogenerator, replacing/swapping our current beaker if there is one.
 *
 * user - the mob inserting the beaker
 * inserted_beaker - the beaker we're inserting into the biogen
 */
/obj/machinery/biogenerator/proc/insert_beaker(mob/living/user, obj/item/reagent_containers/cup/inserted_beaker)
	if(!can_interact(user))
		return

	if(!user.transferItemToLoc(inserted_beaker, src))
		return

	if(beaker)
		to_chat(user, span_notice("You swap out [beaker] in [src] for [inserted_beaker]."))
		eject_beaker(user, silent = TRUE)

	else
		to_chat(user, span_notice("You add [inserted_beaker] to [src]."))

	beaker = inserted_beaker
	update_appearance(UPDATE_ICON)


/*
 * Eject the current stored beaker either into the user's hands or onto the ground.
 *
 * user - the mob ejecting the beaker
 * silent - whether to give a message to the user that the beaker was ejected.
 */
/obj/machinery/biogenerator/proc/eject_beaker(mob/living/user, silent = FALSE)
	if(!beaker)
		return

	if(!can_interact(user))
		return

	if(user.put_in_hands(beaker))
		if(!silent)
			to_chat(user, span_notice("You eject [beaker] from [src]."))

	else
		if(!silent)
			to_chat(user, span_notice("You eject [beaker] from [src] onto the ground."))

		beaker.forceMove(drop_location())

	beaker = null
	update_appearance(UPDATE_ICON)


/obj/machinery/biogenerator/ui_status(mob/user, datum/ui_state/state)
	if(machine_stat & BROKEN || panel_open)
		return UI_CLOSE

	return ..()


/obj/machinery/biogenerator/ui_assets(mob/user)
	return list(
		get_asset_datum(/datum/asset/spritesheet_batched/research_designs),
	)


/obj/machinery/biogenerator/ui_interact(mob/user, datum/tgui/ui)
	ui = SStgui.try_update_ui(user, src, ui)
	if(!ui)
		ui = new(user, src, "Biogenerator", name)
		ui.open()


/obj/machinery/biogenerator/ui_data(mob/user)
	var/list/data = list()
	data["beaker"] = beaker ? TRUE : FALSE
	data["biomass"] = biomass
	data["processing"] = processing
	data["max_output"] = max_output
	data["efficiency"] = efficiency
	data["can_process"] = !!current_item_count

	if(beaker)
		data["beakerCurrentVolume"] = round(beaker.reagents.total_volume, 0.01)
		data["beakerMaxVolume"] = beaker.volume
		data["reagent_color"] = mix_color_from_reagents(beaker.reagents.reagent_list)

	return data


/obj/machinery/biogenerator/ui_static_data(mob/user)
	var/list/data = list()
	data["categories"] = list()
	data["max_visual_biomass"] = max_visual_biomass

	var/categories = show_categories.Copy()
	for(var/category in categories)
		categories[category] = list()

	for(var/design_id in stored_research.researched_designs)
		var/datum/design/design = SSresearch.techweb_design_by_id(design_id)
		for(var/category in categories)
			if(category in design.category)
				categories[category] += design

	for(var/category in categories)
		var/list/cat = list(
			"name" = category,
			"items" = (category == selected_cat ? list() : null))

		for(var/item in categories[category])
			var/datum/design/design = item
			cat["items"] += list(list(
				"id" = design.id,
				"name" = design.name,
				"is_reagent" = design.make_reagent != null,
				"cost" = design.materials[GET_MATERIAL_REF(/datum/material/biomass)] / efficiency,
			))
		data["categories"] += list(cat)

	return data


/obj/machinery/biogenerator/ui_act(action, list/params, datum/tgui/ui, datum/ui_state/state)
	. = ..()
	if(.)
		return

	switch(action)
		if("activate")
			start_process()
			return TRUE

		if("eject")
			eject_beaker(usr)
			return TRUE

		if("create")
			var/amount = text2num(params["amount"])
			if(!amount)
				return

			var/id = params["id"]
			if(!stored_research.researched_designs.Find(id))
				stack_trace("ID did not map to a researched datum [id]")
				return

			var/datum/design/design = SSresearch.techweb_design_by_id(id)
			amount = clamp(amount, 1, (design.make_reagent && beaker ? beaker.reagents.maximum_volume - beaker.reagents.total_volume : max_output))

			if(design && !istype(design, /datum/design/error_design))
				create_product(design, amount)

			else
				stack_trace("ID could not be turned into a valid techweb design datum [id]")
				return

			return TRUE

		if("select")
			selected_cat = params["category"]
			return TRUE


#undef MAX_ITEMS_PER_RATING
#undef PROCESSED_ITEMS_PER_RATING
