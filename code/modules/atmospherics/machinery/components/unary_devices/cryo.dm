///Max temperature allowed inside the cryotube, should break before reaching this heat
#define MAX_TEMPERATURE 4000
// Multiply factor is used with efficiency to multiply Tx quantity
// Tx quantity is how much volume should be removed from the cell's beaker - multiplied by seconds_per_tick
// Throttle Counter Max is how many calls of process() between ones that inject reagents.
// These three defines control how fast and efficient cryo is
#define CRYO_MULTIPLY_FACTOR 25
#define CRYO_TX_QTY 0.5
// The minimum O2 moles in the cryotube before it switches off.
#define CRYO_MIN_GAS_MOLES 5
#define CRYO_BREAKOUT_TIME (30 SECONDS)

/// This is a visual helper that shows the occupant inside the cryo cell.
/atom/movable/visual/cryo_occupant
	icon = 'icons/obj/medical/cryogenics.dmi'
	// Must be tall, otherwise the filter will consider this as a 32x32 tile
	// and will crop the head off.
	icon_state = "mask_bg"
	layer = ABOVE_MOB_LAYER
	mouse_opacity = MOUSE_OPACITY_TRANSPARENT
	pixel_y = 22
	appearance_flags = KEEP_TOGETHER
	/// The current occupant being presented
	var/mob/living/occupant

/atom/movable/visual/cryo_occupant/Initialize(mapload, obj/machinery/cryo_cell/parent)
	. = ..()
	// Alpha masking
	// It will follow this as the animation goes, but that's no problem as the "mask" icon state
	// already accounts for this.
	add_filter("alpha_mask", 1, list("type" = "alpha", "icon" = icon('icons/obj/medical/cryogenics.dmi', "mask"), "y" = -22))
	RegisterSignal(parent, COMSIG_MACHINERY_SET_OCCUPANT, PROC_REF(on_set_occupant))
	RegisterSignal(parent, COMSIG_CRYO_SET_ON, PROC_REF(on_set_on))

/// COMSIG_MACHINERY_SET_OCCUPANT callback
/atom/movable/visual/cryo_occupant/proc/on_set_occupant(datum/source, mob/living/new_occupant)
	SIGNAL_HANDLER

	if(occupant)
		vis_contents -= occupant
		occupant.vis_flags &= ~VIS_INHERIT_PLANE
		occupant.remove_traits(list(TRAIT_IMMOBILIZED, TRAIT_FORCED_STANDING), CRYO_TRAIT)

	occupant = new_occupant
	if(!occupant)
		return

	occupant.setDir(SOUTH)
	// We want to pull our occupant up to our plane so we look right
	occupant.vis_flags |= VIS_INHERIT_PLANE
	vis_contents += occupant
	pixel_y = 22
	// Keep them standing! They'll go sideways in the tube when they fall asleep otherwise.
	occupant.add_traits(list(TRAIT_IMMOBILIZED, TRAIT_FORCED_STANDING), CRYO_TRAIT)

/// COMSIG_CRYO_SET_ON callback
/atom/movable/visual/cryo_occupant/proc/on_set_on(datum/source, on)
	SIGNAL_HANDLER

	if(on)
		animate(src, pixel_y = 24, time = 20, loop = -1)
		animate(pixel_y = 22, time = 20)
	else
		animate(src)

/// Cryo cell
/obj/machinery/cryo_cell
	name = "cryo cell"
	icon = 'icons/obj/medical/cryogenics.dmi'
	icon_state = "pod-off"
	density = TRUE
	max_integrity = 350
	armor_type = /datum/armor/unary_cryo_cell
	circuit = /obj/item/circuitboard/machine/cryo_tube
	occupant_typecache = list(/mob/living/carbon, /mob/living/simple_animal)
	processing_flags = NONE
	payment_department = ACCOUNT_MED
	use_power = IDLE_POWER_USE
	idle_power_usage = BASE_MACHINE_IDLE_CONSUMPTION * 0.75
	active_power_usage = BASE_MACHINE_ACTIVE_CONSUMPTION * 1.5
	flags_1 = PREVENT_CLICK_UNDER_1 | IGNORE_TURF_PIXEL_OFFSET_1
	interaction_flags_mouse_drop = NEED_DEXTERITY

	///If TRUE will eject the mob once healing is complete
	var/autoeject = TRUE
	///Increased via upgraded parts, higher values will provide better healing and use smaller cryoxodane
	var/efficiency = 1
	///Our approximation of a mob's heat capacity. Higher tier parts will provide better cooling for mobs
	var/heat_capacity = 20000
	///Works with heat capacity and is increased with higher tier parts. How quickly the mobs temperature changes in the chamber
	var/conduction_coefficient = 0.3
	///The beaker usually contains cryoxadone that is pumped into the mob
	var/obj/item/reagent_containers/cup/beaker = null
	/// Visual content - Occupant
	var/atom/movable/visual/cryo_occupant/occupant_vis
	///Cryo will continue to treat people with 0 damage but existing wounds, but will sound off when damage healing is done in case doctors want to directly treat the wounds instead
	var/treating_wounds = FALSE
	/// Reference to the datum connector we're using to interface with the pipe network
	var/datum/gas_machine_connector/internal_connector
	/// Check if the machine has been turned on
	var/on = FALSE
	/// The sound loop that can be heard when the generator is processing.
	var/datum/looping_sound/cryo_cell/soundloop
	/// For away sites, custom or admin events
	var/broadcast_channel = RADIO_CHANNEL_MEDICAL

/datum/armor/unary_cryo_cell
	energy = 100
	fire = 30
	acid = 30

/obj/machinery/cryo_cell/Initialize(mapload)
	. = ..()

	occupant_vis = new(mapload, src)
	vis_contents += occupant_vis
	internal_connector = new(loc, src, dir, CELL_VOLUME * 0.5)
	soundloop = new(src)

	register_context()

/obj/machinery/cryo_cell/Destroy()
	on = FALSE

	vis_contents.Cut()
	QDEL_NULL(occupant_vis)
	QDEL_NULL(beaker)
	QDEL_NULL(internal_connector)
	QDEL_NULL(soundloop)

	return ..()

/obj/machinery/cryo_cell/handle_deconstruct(disassembled)
	SHOULD_NOT_OVERRIDE(TRUE)

	if(!QDELETED(occupant))
		occupant.vis_flags &= ~VIS_INHERIT_PLANE
		REMOVE_TRAIT(occupant, TRAIT_IMMOBILIZED, CRYO_TRAIT)
		REMOVE_TRAIT(occupant, TRAIT_FORCED_STANDING, CRYO_TRAIT)

	return ..()

/obj/machinery/cryo_cell/on_deconstruction(disassembled)
	if(beaker)
		beaker.forceMove(drop_location())

/obj/machinery/cryo_cell/contents_explosion(severity, target)
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

/obj/machinery/cryo_cell/Exited(atom/movable/gone, direction)
	. = ..()
	if(gone == beaker)
		beaker = null

/obj/machinery/cryo_cell/add_context(atom/source, list/context, obj/item/held_item, mob/user)
	context[SCREENTIP_CONTEXT_CTRL_LMB] = "Turn [on ? "off" : "on"]"
	context[SCREENTIP_CONTEXT_ALT_LMB] = "[state_open ? "Close" : "Open"] door"
	if(isnull(held_item))
		return CONTEXTUAL_SCREENTIP_SET

	if(QDELETED(beaker) && istype(held_item, /obj/item/reagent_containers/cup))
		context[SCREENTIP_CONTEXT_LMB] = "Insert beaker"
		return CONTEXTUAL_SCREENTIP_SET

	switch(held_item.tool_behaviour)
		if(TOOL_SCREWDRIVER)
			context[SCREENTIP_CONTEXT_LMB] = "[panel_open ? "Close" : "Open"] panel"
		if(TOOL_CROWBAR)
			if(!state_open && !panel_open && !is_operational)
				context[SCREENTIP_CONTEXT_LMB] = "Pry Open"
			else if(panel_open)
				context[SCREENTIP_CONTEXT_LMB] = "Deconstruct"
		if(TOOL_WRENCH)
			context[SCREENTIP_CONTEXT_LMB] = "[panel_open ? "Rotate" : ""]"
	return CONTEXTUAL_SCREENTIP_SET

/obj/machinery/cryo_cell/examine(mob/user) //this is leaving out everything but efficiency since they follow the same idea of "better beaker, better results"
	. = ..()
	if(in_range(user, src) || isobserver(user))
		. += span_notice("The status display reads: Efficiency at <b>[efficiency * 100]</b>%.")
		if(occupant)
			if(on)
				. += span_notice("Someone's inside [src]!")
			else
				. += span_notice("You can barely make out a form floating in [src].")
		else
			. += span_notice("[src] seems empty.")
		if(beaker)
			. += span_notice("A beaker of [beaker.reagents.maximum_volume]u capacity is located inside.")
		else
			. += span_warning("Its missing a beaker.")

		. += span_notice("Use [EXAMINE_HINT("Alt-Click")] to [state_open ? "Close" : "Open"] the machine.")
		. += span_notice("Use [EXAMINE_HINT("Ctrl-Click")] to turn [on ? "Off" : "On"] the machine.")

		. += span_notice("Its maintainence panel can be [EXAMINE_HINT("screwed")] open.")
		if(panel_open)
			. += span_notice("[src] can be [EXAMINE_HINT("pried")] apart.")
			. += span_notice("[src] can be rotated with a [EXAMINE_HINT("wrench")].")
		else if(machine_stat & NOPOWER)
			. += span_notice("[src] can be [EXAMINE_HINT("pried")] open.")

/obj/machinery/cryo_cell/update_icon()
	SET_PLANE_IMPLICIT(src, initial(plane))
	return ..()

/obj/machinery/cryo_cell/update_icon_state()
	icon_state = state_open ? "pod-open" : ((on && is_operational) ? "pod-on" : "pod-off")
	return ..()

/obj/machinery/cryo_cell/update_overlays()
	. = ..()
	if(panel_open)
		. += "pod-panel"
	if(state_open)
		return
	. += mutable_appearance('icons/obj/medical/cryogenics.dmi', "cover-[on && is_operational ? "on" : "off"]", ABOVE_ALL_MOB_LAYER, src, plane = ABOVE_GAME_PLANE)

/obj/machinery/cryo_cell/item_interaction(mob/living/user, obj/item/tool, list/modifiers)
	. = NONE
	if(user.combat_mode || (tool.item_flags & ABSTRACT) || (tool.flags_1 & HOLOGRAM_1) || !user.can_perform_action(src, ALLOW_SILICON_REACH | FORBID_TELEKINESIS_REACH))
		return ITEM_INTERACT_SKIP_TO_ATTACK

	if(!istype(tool, /obj/item/reagent_containers/cup))
		return
	if(!QDELETED(beaker))
		balloon_alert(user, "beaker present!")
		return ITEM_INTERACT_BLOCKING
	if(!user.transferItemToLoc(tool, src))
		return ITEM_INTERACT_BLOCKING

	beaker = tool
	balloon_alert(user, "beaker inserted")
	user.log_message("added \a [tool] to cryo containing [pretty_string_from_reagent_list(tool.reagents.reagent_list)].", LOG_GAME)
	return ITEM_INTERACT_SUCCESS

/obj/machinery/cryo_cell/screwdriver_act(mob/living/user, obj/item/tool)
	. = ITEM_INTERACT_BLOCKING
	if(on)
		balloon_alert(user, "turn off!")
		return
	if(occupant)
		balloon_alert(user, "occupant inside!")
		return

	if(default_deconstruction_screwdriver(user, "pod-off", "pod-off", tool))
		update_appearance()
		return ITEM_INTERACT_SUCCESS

/obj/machinery/cryo_cell/crowbar_act(mob/living/user, obj/item/tool)
	. = ITEM_INTERACT_BLOCKING
	if(on)
		balloon_alert(user, "turn off!")
		return

	var/can_crowbar = FALSE
	if(!state_open && !panel_open && !is_operational) //can pry open
		can_crowbar = TRUE
	else if(panel_open) //can deconstruct
		can_crowbar = TRUE
	if(!can_crowbar)
		return

	var/obj/machinery/atmospherics/node = internal_connector.gas_connector.nodes[1]
	var/internal_pressure = 0

	if(istype(node, /obj/machinery/atmospherics/components/unary/portables_connector))
		var/obj/machinery/atmospherics/components/unary/portables_connector/portable_devices_connector = node
		internal_pressure = !portable_devices_connector.connected_device ? 1 : 0

	var/datum/gas_mixture/inside_air = internal_connector.gas_connector.airs[1]
	if(inside_air.total_moles() > 0)
		if(!node || internal_pressure > 0)
			var/datum/gas_mixture/environment_air = loc.return_air()
			internal_pressure = inside_air.return_pressure() - environment_air.return_pressure()

	var/unsafe_release = FALSE
	if(internal_pressure > 2 * ONE_ATMOSPHERE)
		to_chat(user, span_warning("As you begin prying \the [src] a gush of air blows in your face... maybe you should reconsider?"))
		if(!do_after(user, 2 SECONDS, target = src))
			return
		unsafe_release = TRUE

	var/deconstruct = FALSE
	if(!default_pry_open(tool))
		if(!default_deconstruction_crowbar(tool, custom_deconstruct = TRUE))
			return
		else
			deconstruct = TRUE

	if(unsafe_release)
		internal_connector.gas_connector.unsafe_pressure_release(user, internal_pressure)

	tool.play_tool_sound(src, 50)
	if(deconstruct)
		deconstruct(TRUE)
	return ITEM_INTERACT_SUCCESS

/obj/machinery/cryo_cell/wrench_act(mob/living/user, obj/item/tool)
	. = ITEM_INTERACT_BLOCKING
	if(on)
		balloon_alert(user, "turn off!")
		return
	if(occupant)
		balloon_alert(user, "occupant inside!")
		return
	if(state_open)
		balloon_alert(user, "close first!")
		return

	if(default_change_direction_wrench(user, tool))
		update_appearance()
		return ITEM_INTERACT_SUCCESS

/obj/machinery/cryo_cell/on_changed_z_level(turf/old_turf, turf/new_turf, same_z_layer, notify_contents)
	. = ..()
	if(same_z_layer)
		return
	SET_PLANE(occupant_vis, PLANE_TO_TRUE(occupant_vis.plane), new_turf)

/obj/machinery/cryo_cell/set_occupant(atom/movable/new_occupant)
	. = ..()
	update_appearance()

/obj/machinery/cryo_cell/RefreshParts()
	. = ..()

	var/max_tier = 0
	for(var/datum/stock_part/matter_bin/bin in component_parts)
		max_tier += bin.tier

	efficiency = initial(efficiency) * max_tier
	heat_capacity = initial(heat_capacity) / max_tier
	conduction_coefficient = initial(conduction_coefficient) * max_tier

/obj/machinery/cryo_cell/dump_inventory_contents(list/subset = list())
	//only drop mobs when opening the machine
	for (var/mob/living/living_guy in contents)
		subset += living_guy
	return ..(subset)

/**
 * Turns the machine on/off
 *
 * Arguments
 * * active - TRUE to turn the machine on, FALSE to turn it off
 */
/obj/machinery/cryo_cell/proc/set_on(active)
	PRIVATE_PROC(TRUE)

	if(on == active)
		return

	SEND_SIGNAL(src, COMSIG_CRYO_SET_ON, active)
	. = on
	on = active
	update_appearance()

	update_use_power(on ? ACTIVE_POWER_USE : IDLE_POWER_USE)
	if(on) //Turned on
		begin_processing()
	else //Turned off
		end_processing()

/obj/machinery/cryo_cell/begin_processing()
	. = ..()
	SSair.start_processing_machine(src)
	if(soundloop)
		soundloop.start()

/obj/machinery/cryo_cell/end_processing()
	. = ..()
	SSair.stop_processing_machine(src)
	if(soundloop)
		soundloop.stop()

/obj/machinery/cryo_cell/on_set_is_operational(old_value)
	//Turned off
	if(old_value)
		set_on(FALSE)

/obj/machinery/cryo_cell/process(seconds_per_tick)
	if(!on || QDELETED(occupant))
		//somehow an deleting mob is inside us. dump everything out
		if(!isnull(occupant) && QDELING(occupant))
			open_machine()
			on = FALSE //in case panel was open we need to set to FALSE explicitly

		//if not on end processing
		if(!on)
			set_on(FALSE) //this explicitly disables processing so is nessassary
			. = PROCESS_KILL

		return

	var/mob/living/mob_occupant = occupant
	if(mob_occupant.on_fire)
		mob_occupant.extinguish_mob()
	if(mob_occupant.stat == DEAD) // Notify doctors and potentially eject if the patient is dead
		set_on(FALSE)
		aas_config_announce(/datum/aas_config_entry/medical_cryo_announcements, list("EJECTING" = autoeject), src, list(broadcast_channel), "Deceased")
		if(autoeject) // Eject if configured.
			open_machine()
		playsound(src, 'sound/machines/cryo_warning.ogg', 100)
		return PROCESS_KILL

	// Don't bother with fully healed people.
	if(mob_occupant.get_organic_health() >= mob_occupant.getMaxHealth())
		if(iscarbon(mob_occupant))
			var/mob/living/carbon/C = mob_occupant
			if(C.all_wounds)
				if(!treating_wounds) // if we have wounds and haven't already alerted the doctors we're only dealing with the wounds, let them know
					treating_wounds = TRUE
					playsound(src, 'sound/machines/cryo_warning.ogg', 100) // Bug the doctors.
					aas_config_announce(/datum/aas_config_entry/medical_cryo_announcements, list(), src, list(broadcast_channel), "Wound Treatment")
			else // otherwise if we were only treating wounds and now we don't have any, turn off treating_wounds so we can boot 'em out
				treating_wounds = FALSE

		if(!treating_wounds)
			set_on(FALSE)
			playsound(src, 'sound/machines/cryo_warning.ogg', 100) // Bug the doctors.
			aas_config_announce(/datum/aas_config_entry/medical_cryo_announcements, list("EJECTING" = autoeject), src, list(broadcast_channel), "Fully Recovered")
			if(autoeject) // Eject if configured.
				open_machine()
			return PROCESS_KILL

	var/datum/gas_mixture/air1 = internal_connector.gas_connector.airs[1]
	if(!QDELETED(beaker) && air1.total_moles() > CRYO_MIN_GAS_MOLES)
		beaker.reagents.trans_to(
			occupant,
			(CRYO_TX_QTY / (efficiency * CRYO_MULTIPLY_FACTOR)) * seconds_per_tick,
			efficiency * CRYO_MULTIPLY_FACTOR,
			methods = VAPOR
		)

/obj/machinery/cryo_cell/process_atmos()
	if(!on)
		return PROCESS_KILL

	var/datum/gas_mixture/air1 = internal_connector.gas_connector.airs[1]

	//check for workable conditions
	if(!internal_connector.gas_connector.nodes[1] || !air1 || !air1.gases.len || air1.total_moles() < CRYO_MIN_GAS_MOLES) // Turn off if the machine won't work.
		set_on(FALSE)
		aas_config_announce(/datum/aas_config_entry/medical_cryo_announcements, list("EJECTING" = autoeject), src, list(broadcast_channel), "Insufficient Gas")
		if(autoeject) // Eject if configured.
			open_machine()
		return PROCESS_KILL

	//take damage from high temperatures
	if(air1.temperature > 2000)
		take_damage(clamp((air1.temperature) / 200, 10, 20), BURN)

	//adjust temperature of mob
	if(!QDELETED(occupant))
		var/mob/living/mob_occupant = occupant
		var/cold_protection = 0
		var/temperature_delta = air1.temperature - mob_occupant.bodytemperature // The only semi-realistic thing here: share temperature between the cell and the occupant.

		if(ishuman(mob_occupant))
			var/mob/living/carbon/human/H = mob_occupant
			cold_protection = H.get_cold_protection(air1.temperature)

		if(abs(temperature_delta) > 1)
			var/air_heat_capacity = air1.heat_capacity()
			var/heat = ((1 - cold_protection) * 0.1 + conduction_coefficient) * CALCULATE_CONDUCTION_ENERGY(temperature_delta, heat_capacity, air_heat_capacity)

			mob_occupant.adjust_bodytemperature(heat / heat_capacity, TCMB)
			air1.temperature = clamp(air1.temperature - heat / air_heat_capacity, TCMB, MAX_TEMPERATURE)

			//lets have the core temp match the body temp in humans
			if(ishuman(mob_occupant))
				var/mob/living/carbon/human/humi = mob_occupant
				humi.adjust_coretemperature(humi.bodytemperature - humi.coretemperature)

	//spread temperature changes throughout the pipenet
	internal_connector.gas_connector.update_parents()

/obj/machinery/cryo_cell/handle_internal_lifeform(mob/lifeform_inside_me, breath_request)
	if(breath_request <= 0)
		return null

	//return breathable air
	var/datum/gas_mixture/air1 = internal_connector.gas_connector.airs[1]
	var/breath_percentage = breath_request / air1.volume
	. = air1.remove(air1.total_moles() * breath_percentage)

	//update molar changes throughout the pipenet
	internal_connector.gas_connector.update_parents()

/obj/machinery/cryo_cell/assume_air(datum/gas_mixture/giver)
	internal_connector.gas_connector.airs[1].merge(giver)

/obj/machinery/cryo_cell/return_temperature()
	var/datum/gas_mixture/internal_air = internal_connector.gas_connector.airs[1]

	return internal_air.total_moles() > CRYO_MIN_GAS_MOLES ? internal_air.temperature : ..()

/obj/machinery/cryo_cell/open_machine(drop = TRUE, density_to_set = FALSE)
	if(!state_open && !panel_open)
		set_on(FALSE)
	flick("pod-open-anim", src)
	return ..()

/obj/machinery/cryo_cell/close_machine(mob/living/carbon/user, density_to_set = TRUE)
	treating_wounds = FALSE
	if(state_open && !panel_open)
		flick("pod-close-anim", src)
		. = ..()
		if(!QDELETED(occupant)) //auto on if an occupant is inside
			set_on(TRUE)

/obj/machinery/cryo_cell/container_resist_act(mob/living/user)
	user.changeNext_move(CLICK_CD_BREAKOUT)
	user.last_special = world.time + CLICK_CD_BREAKOUT
	user.visible_message(span_notice("You see [user] kicking against the glass of [src]!"), \
		span_notice("You struggle inside [src], kicking the release with your foot... (this will take about [DisplayTimeText(CRYO_BREAKOUT_TIME)].)"), \
		span_hear("You hear a thump from [src]."))
	if(do_after(user, CRYO_BREAKOUT_TIME, target = src, hidden = TRUE))
		if(!user || user.stat != CONSCIOUS || user.loc != src )
			return
		user.visible_message(span_warning("[user] successfully broke out of [src]!"), \
			span_notice("You successfully break out of [src]!"))
		open_machine()

/obj/machinery/cryo_cell/ui_state(mob/user)
	return GLOB.notcontained_state

/obj/machinery/cryo_cell/ui_interact(mob/user, datum/tgui/ui)
	ui = SStgui.try_update_ui(user, src, ui)
	if(!ui)
		ui = new(user, src, "Cryo", name)
		ui.open()

/obj/machinery/cryo_cell/ui_static_data(mob/user)
	. = list()
	.["T0C"] = T0C

/obj/machinery/cryo_cell/ui_data()
	. = list()
	.["isOperating"] = on
	.["isOpen"] = state_open
	.["autoEject"] = autoeject

	var/list/occupant_data = null
	if(!QDELETED(occupant))
		var/mob/living/mob_occupant = occupant
		occupant_data = list()

		occupant_data["name"] = mob_occupant.name
		if(mob_occupant.stat == DEAD)
			occupant_data["stat"] = "Dead"
		else if (HAS_TRAIT(mob_occupant, TRAIT_KNOCKEDOUT))
			occupant_data["stat"] = "Unconscious"
		else
			occupant_data["stat"] = "Conscious"

		occupant_data["bodyTemperature"] = round(mob_occupant.bodytemperature, 1)

		occupant_data["health"] = mob_occupant.health
		occupant_data["maxHealth"] = mob_occupant.maxHealth
		occupant_data["bruteLoss"] = mob_occupant.getBruteLoss()
		occupant_data["oxyLoss"] = mob_occupant.getOxyLoss()
		occupant_data["toxLoss"] = mob_occupant.getToxLoss()
		occupant_data["fireLoss"] = mob_occupant.getFireLoss()
	.["occupant"] = occupant_data

	var/datum/gas_mixture/air1 = internal_connector.gas_connector.airs[1]
	.["cellTemperature"] = air1.temperature

	var/list/beaker_data = null
	if(!QDELETED(beaker))
		beaker_data = list()
		beaker_data["maxVolume"] = beaker.volume
		beaker_data["currentVolume"] = beaker.reagents.total_volume
		var/list/beakerContents = list()
		if(length(beaker.reagents.reagent_list))
			for(var/datum/reagent/reagent in beaker.reagents.reagent_list)
				beakerContents += list(list("name" = reagent.name, "volume" = round(reagent.volume, CHEMICAL_VOLUME_ROUNDING))) // list in a list because Byond merges the first list...
		beaker_data["contents"] = beakerContents
	.["beaker"] = beaker_data

/obj/machinery/cryo_cell/ui_act(action, params, datum/tgui/ui, datum/ui_state/state)
	. = ..()
	if(.)
		return

	switch(action)
		if("power")
			if(on)
				set_on(FALSE)
			else if(!state_open)
				set_on(TRUE)
			return TRUE

		if("door")
			if(state_open && get_turf(ui.user) != get_turf(src))
				close_machine()
			else
				open_machine()
			return TRUE

		if("autoeject")
			autoeject = !autoeject
			return TRUE

		if("eject")
			if(!QDELETED(beaker))
				var/mob/living/user = ui.user
				if(Adjacent(user) && !issilicon(user))
					user.put_in_hands(beaker)
				else
					beaker.forceMove(drop_location())
				return TRUE

/obj/machinery/cryo_cell/can_interact(mob/user)
	//must not be in the machine or on its turf to interact
	if(get_turf(user) == get_turf(src))
		return FALSE
	return ..()

/obj/machinery/cryo_cell/click_ctrl(mob/user)
	if(is_operational && !state_open)
		set_on(!on)
		balloon_alert(user, "turned [on ? "on" : "off"]")
		return CLICK_ACTION_SUCCESS
	return CLICK_ACTION_BLOCKING

/obj/machinery/cryo_cell/click_alt(mob/user)
	//Required so players don't close the cryo on themselves without a doctor's help
	if(get_turf(user) == get_turf(src))
		return CLICK_ACTION_BLOCKING

	if(state_open )
		close_machine()
	else
		open_machine()
	balloon_alert(user, "door [state_open ? "opened" : "closed"]")
	return CLICK_ACTION_SUCCESS

/obj/machinery/cryo_cell/mouse_drop_receive(mob/target, mob/user, params)
	if(!iscarbon(target))
		return

	if(isliving(target))
		var/mob/living/living_mob = target
		if(living_mob.incapacitated)
			close_machine(target)
		return

	user.visible_message(span_notice("[user] starts shoving [target] inside [src]."), span_notice("You start shoving [target] inside [src]."))
	if (do_after(user, 2.5 SECONDS, target=target))
		close_machine(target)

/obj/machinery/cryo_cell/get_remote_view_fullscreens(mob/user)
	user.overlay_fullscreen("remote_view", /atom/movable/screen/fullscreen/impaired, 1)

/datum/aas_config_entry/medical_cryo_announcements
	name = "Medical Alert: Cryogenics Reports"
	announcement_lines_map = list(
		"Autoejecting" = "Auto ejecting patient now.",
		"Deceased" = "Cryogenics report: Patient is deceased. %AUTOEJECTING",
		"Fully Recovered" = "Cryogenics report: Patient fully restored. %AUTOEJECTING",
		"Insufficient Gas" = "Cryogenics report: Insufficient cryogenic gas, shutting down. %AUTOEJECTING",
		"Wound Treatment" = "Cryogenics report: Patient vitals fully recovered, continuing automated wound treatment."
	)
	vars_and_tooltips_map = list(
		"AUTOEJECTING" = "will be replaced with Autoejecting line, if system reports it's necessity"
	)

/datum/aas_config_entry/medical_cryo_announcements/compile_announce(list/variables_map, announcement_line)
	variables_map["AUTOEJECTING"] = variables_map["EJECTING"] ? announcement_lines_map["Autoejecting"] : ""
	. = ..()
	// Why double replacetext_char? Well, to handle cases where variable in the middle of sentence like "also %AUTOEJECTING this", so there will be no double spaces
	// Yeah I am bad, at this, sorry (it should be a perfect place for regex usage, but I am weak)
	. = trim(replacetext_char(replacetext_char(., "\[NO DATA\] ", ""), "\[NO DATA\]", ""))

#undef MAX_TEMPERATURE
#undef CRYO_MULTIPLY_FACTOR
#undef CRYO_TX_QTY
#undef CRYO_MIN_GAS_MOLES
#undef CRYO_BREAKOUT_TIME
