/obj/vehicle/ridden/wheelchair/motorized
	name = "motorized wheelchair"
	desc = "A chair with big wheels. It seems to have a motor in it."
	icon_state = "motorized_wheelchair"
	overlay_icon = "motorized_wheelchair_overlay"
	foldabletype = null
	max_integrity = 150
	///How "fast" the wheelchair goes only affects ramming
	var/speed = 2
	///Self explanatory, ratio of how much power we use
	var/power_efficiency = 1
	///How much energy we use
	var/energy_usage = 0.1 * STANDARD_CELL_CHARGE
	///whether the panel is open so a user can take out the cell
	var/panel_open = FALSE
	///Parts used in building the wheelchair
	var/list/required_parts = list(
		/datum/stock_part/servo,
		/datum/stock_part/servo,
		/datum/stock_part/capacitor,
	)
	///power cell we draw power from
	var/obj/item/stock_parts/power_store/power_cell
	///stock parts for this chair
	var/list/component_parts = list()

/obj/vehicle/ridden/wheelchair/motorized/Initialize(mapload)
	. = ..()
	add_component_parts()
	refresh_parts()

/obj/vehicle/ridden/wheelchair/motorized/proc/add_component_parts()
	// Add tier 1 stock parts so that non-crafted wheelchairs aren't empty
	component_parts += GLOB.stock_part_datums[/datum/stock_part/capacitor]
	component_parts += GLOB.stock_part_datums[/datum/stock_part/servo]
	component_parts += GLOB.stock_part_datums[/datum/stock_part/servo]
	power_cell = new /obj/item/stock_parts/power_store/cell(src)

/obj/vehicle/ridden/wheelchair/motorized/make_ridable()
	AddElement(/datum/element/ridable, /datum/component/riding/vehicle/wheelchair/motorized)

/obj/vehicle/ridden/wheelchair/motorized/on_craft_completion(list/components, datum/crafting_recipe/current_recipe, atom/crafter)
	// This wheelchair was crafted, so clean out default parts
	qdel(power_cell)
	component_parts = list()

	for(var/obj/item/stock_parts/part in contents)
		if(istype(part, /obj/item/stock_parts/power_store/cell)) // power cell, physically moves into the wheelchair
			power_cell = part
			continue

		// find matching datum/stock_part for this part and add to component list
		var/datum/stock_part/newstockpart = GLOB.stock_part_datums_per_object[part.type]
		if(isnull(newstockpart))
			CRASH("No corresponding datum/stock_part for [part.type]")
		component_parts += newstockpart
	refresh_parts()

	return ..()

/obj/vehicle/ridden/wheelchair/motorized/proc/refresh_parts()
	speed = 1 // Should never be under 1
	for(var/datum/stock_part/servo/servo in component_parts)
		speed += servo.tier
	var/chair_icon = "motorized_wheelchair[speed > delay_multiplier ? "_fast" : ""]"
	if(icon_state != chair_icon)
		overlay_icon = chair_icon + "_overlay"

	icon_state = chair_icon

	for(var/datum/stock_part/capacitor/capacitor in component_parts)
		power_efficiency = capacitor.tier

/obj/vehicle/ridden/wheelchair/motorized/get_cell()
	return power_cell

/obj/vehicle/ridden/wheelchair/motorized/atom_destruction(damage_flag)
	for(var/datum/stock_part/part in component_parts)
		new part.physical_object_type(drop_location())
	if(!isnull(power_cell))
		power_cell.forceMove(drop_location())
		power_cell = null
	return ..()

/obj/vehicle/ridden/wheelchair/motorized/relaymove(mob/living/user, direction)
	if(!power_cell)
		to_chat(user, span_warning("There seems to be no cell installed in [src]."))
		canmove = FALSE
		addtimer(VARSET_CALLBACK(src, canmove, TRUE), 2 SECONDS)
		return FALSE
	if(power_cell.charge < energy_usage / max(power_efficiency, 1))
		to_chat(user, span_warning("The display on [src] blinks 'Out of Power'."))
		canmove = FALSE
		addtimer(VARSET_CALLBACK(src, canmove, TRUE), 2 SECONDS)
		return FALSE
	return ..()

/obj/vehicle/ridden/wheelchair/motorized/attack_hand(mob/living/user, list/modifiers)
	if(!power_cell || !panel_open)
		return ..()
	to_chat(user, span_notice("You remove [power_cell] from [src]."))
	user.put_in_hands(power_cell)
	power_cell = null

/obj/vehicle/ridden/wheelchair/motorized/attackby(obj/item/attacking_item, mob/user, params)
	if(!panel_open)
		return ..()

	if(istype(attacking_item, /obj/item/stock_parts/power_store/cell))
		if(power_cell)
			to_chat(user, span_warning("There is a power cell already installed."))
		else
			attacking_item.forceMove(src)
			power_cell = attacking_item
			to_chat(user, span_notice("You install the [attacking_item]."))
		refresh_parts()
		return
	if(!istype(attacking_item, /obj/item/stock_parts))
		return ..()

	var/datum/stock_part/newstockpart = GLOB.stock_part_datums_per_object[attacking_item.type]
	if(isnull(newstockpart))
		CRASH("No corresponding datum/stock_part for [newstockpart.type]")
	for(var/datum/stock_part/oldstockpart in component_parts)
		var/type_to_check
		for(var/pathtype in required_parts)
			if(ispath(oldstockpart.type, pathtype))
				type_to_check = pathtype
				break
		if(istype(newstockpart, type_to_check) && istype(oldstockpart, type_to_check))
			if(newstockpart.tier > oldstockpart.tier)
				// delete the part in the users hand and add the datum part to the component_list
				qdel(attacking_item)
				component_parts += newstockpart
				// create an new instance of the old datum stock part physical type & put it in the users hand
				var/obj/item/stock_parts/part = new oldstockpart.physical_object_type
				user.put_in_hands(part)
				component_parts -= oldstockpart
				// user message
				user.visible_message(span_notice("[user] replaces [oldstockpart.name()] with [newstockpart.name()] in [src]."), span_notice("You replace [oldstockpart.name()] with [newstockpart.name()]."))
				break
	refresh_parts()

/obj/vehicle/ridden/wheelchair/motorized/wrench_act(mob/living/user, obj/item/tool)
	balloon_alert(user, "disassembling")
	if(!tool.use_tool(src, user, 4 SECONDS, volume=50))
		return ITEM_INTERACT_SUCCESS
	to_chat(user, span_notice("You detach the wheels and deconstruct the chair."))
	new /obj/item/stack/rods(drop_location(), 8)
	new /obj/item/stack/sheet/iron(drop_location(), 10)
	for(var/datum/stock_part/part in component_parts)
		new part.physical_object_type(drop_location())
	if(!isnull(power_cell))
		power_cell.forceMove(drop_location())
		power_cell = null
	qdel(src)
	return ITEM_INTERACT_SUCCESS

/obj/vehicle/ridden/wheelchair/motorized/screwdriver_act(mob/living/user, obj/item/tool)
	tool.play_tool_sound(src)
	panel_open = !panel_open
	user.visible_message(span_notice("[user] [panel_open ? "opens" : "closes"] the maintenance panel on [src]."), span_notice("You [panel_open ? "open" : "close"] the maintenance panel."))
	return ITEM_INTERACT_SUCCESS

/obj/vehicle/ridden/wheelchair/motorized/examine(mob/user)
	. = ..()
	if((obj_flags & EMAGGED) && panel_open)
		. += "There is a bomb under the maintenance panel."
	. += "There is a small screen on it, [(in_range(user, src) || isobserver(user)) ? "[power_cell ? "it reads:" : "but it is dark."]" : "but you can't see it from here."]"
	if(!power_cell || (!in_range(user, src) && !isobserver(user)))
		return
	. += "Speed: [speed]"
	. += "Energy efficiency: [power_efficiency]"
	. += "Power: [power_cell.charge] out of [power_cell.maxcharge]"

/obj/vehicle/ridden/wheelchair/motorized/Move(newloc, direct)
	. = ..()
	if (.)
		return
	if (!has_buckled_mobs())
		return
	for (var/mob/living/guy in newloc)
		if(!(guy in buckled_mobs))
			Bump(guy)

/obj/vehicle/ridden/wheelchair/motorized/Bump(atom/bumped_atom)
	. = ..()
	// Here is the shitty emag functionality.
	if(obj_flags & EMAGGED && (isclosedturf(bumped_atom) || isliving(bumped_atom)))
		explosion(src, devastation_range = -1, heavy_impact_range = 1, light_impact_range = 3, flash_range = 2, adminlog = FALSE)
		visible_message(span_boldwarning("[src] explodes!!"))
		return
	// If the speed is higher than delay_multiplier throw the person on the wheelchair away
	if(bumped_atom.density && speed > delay_multiplier && has_buckled_mobs())
		var/mob/living/disabled = buckled_mobs[1]
		var/atom/throw_target = get_edge_target_turf(disabled, pick(GLOB.cardinals))
		unbuckle_mob(disabled)
		disabled.throw_at(throw_target, 2, 3)
		disabled.Knockdown(10 SECONDS)
		disabled.adjustStaminaLoss(40)
		if(isliving(bumped_atom))
			var/mob/living/ramtarget = bumped_atom
			throw_target = get_edge_target_turf(ramtarget, pick(GLOB.cardinals))
			ramtarget.throw_at(throw_target, 2, 3)
			ramtarget.Knockdown(8 SECONDS)
			ramtarget.adjustStaminaLoss(35)
			visible_message(span_danger("[src] crashes into [ramtarget], sending [disabled] and [ramtarget] flying!"))
		else
			visible_message(span_danger("[src] crashes into [bumped_atom], sending [disabled] flying!"))
		playsound(src, 'sound/effects/bang.ogg', 50, 1)

/obj/vehicle/ridden/wheelchair/motorized/emag_act(mob/user, obj/item/card/emag/emag_card)
	if (obj_flags & EMAGGED)
		return FALSE

	if (panel_open)
		balloon_alert(user, "open maintenance panel!")
		return FALSE

	balloon_alert(user, "bomb implanted...?")
	visible_message(span_warning("A bomb appears in [src], what the fuck?"))
	obj_flags |= EMAGGED
	return TRUE

///Version with slightly better components. Used by deathmatches.
/obj/vehicle/ridden/wheelchair/motorized/improved

/obj/vehicle/ridden/wheelchair/motorized/improved/add_component_parts()
	component_parts += GLOB.stock_part_datums[/datum/stock_part/capacitor]
	component_parts += GLOB.stock_part_datums[/datum/stock_part/servo/tier2]
	component_parts += GLOB.stock_part_datums[/datum/stock_part/servo]
	power_cell = new /obj/item/stock_parts/power_store/cell/upgraded/plus(src)
