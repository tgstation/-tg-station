#define HEATER_MODE_STANDBY "standby"
#define HEATER_MODE_HEAT "heat"
#define HEATER_MODE_COOL "cool"
#define HEATER_MODE_AUTO "auto"
#define BASE_HEATING_ENERGY (40 KILO JOULES)

/obj/machinery/space_heater
	anchored = FALSE
	density = TRUE
	interaction_flags_machine = INTERACT_MACHINE_WIRES_IF_OPEN | INTERACT_MACHINE_ALLOW_SILICON | INTERACT_MACHINE_OPEN
	icon = 'icons/obj/pipes_n_cables/atmos.dmi'
	icon_state = "sheater-off"
	base_icon_state = "sheater"
	name = "space heater"
	desc = "Made by Space Amish using traditional space techniques, this heater/cooler is guaranteed not to set the station on fire. Warranty void if used in engines."
	max_integrity = 250
	armor_type = /datum/armor/machinery_space_heater
	circuit = /obj/item/circuitboard/machine/space_heater
	interaction_flags_click = ALLOW_SILICON_REACH
	//We don't use area power, we always use the cell
	use_power = NO_POWER_USE
	///The cell we spawn with
	var/obj/item/stock_parts/power_store/cell = /obj/item/stock_parts/power_store/cell/high
	///Is the machine on?
	var/on = FALSE
	///What is the mode we are in now?
	var/mode = HEATER_MODE_STANDBY
	///Anything other than "heat" or "cool" is considered auto.
	var/set_mode = HEATER_MODE_AUTO
	///The temperature we trying to get to
	var/target_temperature = T20C
	///How much heat/cold we can deliver
	var/heating_energy = BASE_HEATING_ENERGY
	///How efficiently we can deliver that heat/cold (higher indicates less cell consumption)
	var/efficiency = 20 MEGA JOULES / STANDARD_CELL_CHARGE
	///The amount of degrees above and below the target temperature for us to change mode to heater or cooler
	var/temperature_tolerance = 1
	///What's the middle point of our settable temperature (30 °C)
	var/settable_temperature_median = 30 + T0C
	///Range of temperatures above and below the median that we can set our target temperature (increase by upgrading the capacitors)
	var/settable_temperature_range = 30
	///Should we add an overlay for open spaceheaters
	var/display_panel = TRUE

/datum/armor/machinery_space_heater
	fire = 80
	acid = 10

/obj/machinery/space_heater/get_cell()
	return cell

/obj/machinery/space_heater/Initialize(mapload)
	. = ..()
	if(ispath(cell))
		cell = new cell(src)
	update_appearance()
	SSair.start_processing_machine(src)

	AddElement( \
		/datum/element/contextual_screentip_bare_hands, \
		rmb_text = "Toggle power", \
	)

	var/static/list/tool_behaviors = list(
		TOOL_SCREWDRIVER = list(
			SCREENTIP_CONTEXT_LMB = "Open hatch",
		),

		TOOL_WRENCH = list(
			SCREENTIP_CONTEXT_LMB = "Anchor",
		),
	)
	AddElement(/datum/element/contextual_screentip_tools, tool_behaviors)
	AddElement(/datum/element/climbable)
	AddElement(/datum/element/elevation, pixel_shift = 8)

/obj/machinery/space_heater/Destroy()
	SSair.stop_processing_machine(src)
	QDEL_NULL(cell)
	return..()

/obj/machinery/space_heater/on_construction()
	set_panel_open(TRUE)
	QDEL_NULL(cell)

/obj/machinery/space_heater/on_deconstruction(disassembled)
	if(cell)
		LAZYADD(component_parts, cell)
		cell = null
	return ..()

/obj/machinery/space_heater/examine(mob/user)
	. = ..()
	. += "\The [src] is [on ? "on" : "off"], and the hatch is [panel_open ? "open" : "closed"]."
	if(cell)
		. += "The charge meter reads [cell ? round(cell.percent(), 1) : 0]%."
	else
		. += span_warning("There is no power cell installed.")
	if(in_range(user, src) || isobserver(user))
		. += heating_examine()
		. += span_notice("<b>Right-click</b> to toggle [on ? "off" : "on"].")

///Returns the heating power of this machine as an examine
/obj/machinery/space_heater/proc/heating_examine()
	var/target_temp = round(target_temperature - T0C, 1)
	var/min_temp = max(settable_temperature_median - settable_temperature_range, TCMB) - T0C
	var/max_temp = settable_temperature_median + settable_temperature_range - T0C
	return span_notice("The status display reads:<br>Heating power: <b>[display_power(heating_energy, convert = TRUE, scheduler = SSair)] at [(efficiency / 20) * 100]% efficiency.</b><br>Target temperature: <b>[target_temp]°C [min_temp]°C - [max_temp]°C]</b>\n")

/obj/machinery/space_heater/update_icon_state()
	. = ..()
	icon_state = "[base_icon_state]-[on ? mode : "off"]"

/obj/machinery/space_heater/update_overlays()
	. = ..()
	if(panel_open && display_panel)
		. += "[base_icon_state]-open"

/obj/machinery/space_heater/on_set_panel_open()
	update_appearance()
	return ..()

/obj/machinery/space_heater/process_atmos()
	if(!on || !is_operational || QDELETED(cell) || cell.charge <= 1)
		if (on) // If it's broken, turn it off too
			on = FALSE
			update_appearance()
		return PROCESS_KILL

	var/turf/local_turf = loc
	if(!istype(local_turf))
		if(mode != HEATER_MODE_STANDBY)
			mode = HEATER_MODE_STANDBY
			update_appearance()
		return

	var/datum/gas_mixture/enviroment = local_turf.return_air()

	var/new_mode = HEATER_MODE_STANDBY
	if(set_mode != HEATER_MODE_COOL && enviroment.temperature < target_temperature - temperature_tolerance)
		new_mode = HEATER_MODE_HEAT
	else if(set_mode != HEATER_MODE_HEAT && enviroment.temperature > target_temperature + temperature_tolerance)
		new_mode = HEATER_MODE_COOL

	if(mode != new_mode)
		mode = new_mode
		update_appearance()

	if(mode == HEATER_MODE_STANDBY)
		return

	var/list/turfs = (local_turf.atmos_adjacent_turfs || list()) + local_turf
	var/required_energy = abs(enviroment.temperature - target_temperature) * enviroment.heat_capacity()
	required_energy = min(required_energy, heating_energy, (cell.charge * efficiency) / length(turfs))
	if(required_energy < 1)
		return

	var/delta_energy = required_energy
	if(mode == HEATER_MODE_COOL)
		delta_energy *= -1
	if(delta_energy == 0)
		return

	for(var/turf/open/turf in turfs)
		var/datum/gas_mixture/turf_gasmix = turf.return_air()
		turf_gasmix.temperature += delta_energy / turf_gasmix.heat_capacity()
		air_update_turf(FALSE, FALSE)
	cell.use((required_energy * length(turfs)) / efficiency, force = TRUE)

/obj/machinery/space_heater/RefreshParts()
	. = ..()
	var/laser = 0
	var/cap = 0
	for(var/datum/stock_part/micro_laser/micro_laser in component_parts)
		laser += micro_laser.tier
	for(var/datum/stock_part/capacitor/capacitor in component_parts)
		cap += capacitor.tier

	heating_energy = laser * initial(heating_energy)

	settable_temperature_range = cap * initial(settable_temperature_range)
	efficiency = (cap + 1) * initial(efficiency) * 0.5

	target_temperature = clamp(target_temperature,
		max(settable_temperature_median - settable_temperature_range, TCMB),
		settable_temperature_median + settable_temperature_range)

/obj/machinery/space_heater/emp_act(severity)
	. = ..()
	if(machine_stat & (NOPOWER|BROKEN) || . & EMP_PROTECT_CONTENTS)
		return
	if(cell)
		cell.emp_act(severity)

/obj/machinery/space_heater/wrench_act(mob/living/user, obj/item/tool)
	. = ..()
	default_unfasten_wrench(user, tool)
	return ITEM_INTERACT_SUCCESS

/obj/machinery/space_heater/attackby(obj/item/I, mob/user, params)
	add_fingerprint(user)

	if(default_deconstruction_screwdriver(user, icon_state, icon_state, I))
		user.visible_message(span_notice("\The [user] [panel_open ? "opens" : "closes"] the hatch on \the [src]."), span_notice("You [panel_open ? "open" : "close"] the hatch on \the [src]."))
		update_appearance()
		return TRUE

	if(default_deconstruction_crowbar(I))
		return TRUE

	if(istype(I, /obj/item/stock_parts/power_store/cell))
		if(!panel_open)
			to_chat(user, span_warning("The hatch must be open to insert a power cell!"))
			return
		if(cell)
			to_chat(user, span_warning("There is already a power cell inside!"))
			return
		if(!user.transferItemToLoc(I, src))
			return
		cell = I
		I.add_fingerprint(usr)
		user.visible_message(span_notice("\The [user] inserts a power cell into \the [src]."), span_notice("You insert the power cell into \the [src]."))
		SStgui.update_uis(src)
		return TRUE
	return ..()

/obj/machinery/space_heater/attack_hand_secondary(mob/user, list/modifiers)
	if(!can_interact(user))
		return SECONDARY_ATTACK_CANCEL_ATTACK_CHAIN
	toggle_power(user)
	return SECONDARY_ATTACK_CANCEL_ATTACK_CHAIN

/obj/machinery/space_heater/ui_interact(mob/user, datum/tgui/ui)
	ui = SStgui.try_update_ui(user, src, ui)
	if(!ui)
		ui = new(user, src, "SpaceHeater", name)
		ui.open()

/obj/machinery/space_heater/ui_data()
	var/list/data = list()
	data["open"] = panel_open
	data["on"] = on
	data["mode"] = set_mode
	data["hasPowercell"] = !!cell
	data["chemHacked"] = FALSE
	if(cell)
		data["powerLevel"] = round(cell.percent(), 1)
	data["targetTemp"] = round(target_temperature - T0C, 1)
	data["minTemp"] = max(settable_temperature_median - settable_temperature_range, TCMB) - T0C
	data["maxTemp"] = settable_temperature_median + settable_temperature_range - T0C

	var/turf/local_turf = get_turf(loc)
	var/current_temperature
	if(istype(local_turf))
		var/datum/gas_mixture/enviroment = local_turf.return_air()
		current_temperature = enviroment.temperature
	else if(isturf(local_turf))
		current_temperature = local_turf.temperature
	if(isnull(current_temperature))
		data["currentTemp"] = "N/A"
	else
		data["currentTemp"] = round(current_temperature - T0C, 1)
	return data

/obj/machinery/space_heater/ui_act(action, list/params, datum/tgui/ui, datum/ui_state/state)
	. = ..()
	if(.)
		return

	switch(action)
		if("power")
			toggle_power()
			. = TRUE
		if("mode")
			set_mode = params["mode"]
			. = TRUE
		if("target")
			if(!panel_open)
				return
			var/target = params["target"]
			if(text2num(target) != null)
				target= text2num(target) + T0C
				. = TRUE
			if(.)
				target_temperature = clamp(round(target),
					max(settable_temperature_median - settable_temperature_range, TCMB),
					settable_temperature_median + settable_temperature_range)
		if("eject")
			if(panel_open && cell)
				usr.put_in_hands(cell)
				cell = null
				. = TRUE

/obj/machinery/space_heater/proc/toggle_power(user)
	on = !on
	mode = HEATER_MODE_STANDBY
	if(!isnull(user))
		if(QDELETED(cell))
			balloon_alert(user, "no cell!")
		else if(!cell.charge())
			balloon_alert(user, "no charge!")
		else if(!is_operational)
			balloon_alert(user, "not operational!")
		else
			balloon_alert(user, "turned [on ? "on" : "off"]")
	update_appearance()
	if(on)
		SSair.start_processing_machine(src)

///For use with heating reagents in a ghetto way
/obj/machinery/space_heater/improvised_chem_heater
	icon = 'icons/obj/medical/chemical.dmi'
	icon_state = "sheater-off"
	name = "Improvised chem heater"
	desc = "A space heater hacked to reroute heating to a water bath on the top."
	panel_open = TRUE //This is always open - since we've injected wires in the panel
	//We inherit the cell from the heater prior
	cell = null
	interaction_flags_click = FORBID_TELEKINESIS_REACH
	display_panel = FALSE
	settable_temperature_range = 50
	///The beaker within the heater
	var/obj/item/reagent_containers/beaker = null
	/// How quickly it delivers heat to the reagents. In watts per joule of the thermal energy difference of the reagent from the temperature difference of the current and target temperatures.
	var/beaker_conduction_power = 0.1
	/// The subsystem we're being processed by.
	var/datum/controller/subsystem/processing/our_subsystem

/obj/machinery/space_heater/improvised_chem_heater/Initialize(mapload)
	our_subsystem = locate(subsystem_type) in Master.subsystems
	. = ..()

/obj/machinery/space_heater/improvised_chem_heater/Destroy()
	. = ..()
	QDEL_NULL(beaker)

/obj/machinery/space_heater/improvised_chem_heater/on_craft_completion(list/components, datum/crafting_recipe/current_recipe, atom/crafter)
	. = ..()
	if(!isliving(crafter))
		return
	var/mob/living/user = crafter
	var/obj/item/stock_parts/power_store/cell/cell = (locate() in range(1)) || user.is_holding_item_of_type(/obj/item/stock_parts/power_store/cell)
	if(!cell)
		return
	var/turf/turf = get_turf(cell)
	forceMove(turf)
	attackby(cell, user) //puts it into the heater

/obj/machinery/space_heater/improvised_chem_heater/heating_examine()
	. = ..()
	// Conducted energy per joule of thermal energy difference in a tick.
	var/conduction_energy = beaker_conduction_power * (set_mode == HEATER_MODE_AUTO ? 0.5 : 1) * our_subsystem.wait / (1 SECONDS)
	// This accounts for the timestep inaccuracy.
	. += span_notice("Reagent conduction power: <b>[conduction_energy < 1 ? display_power(-log(1 - conduction_energy) SECONDS / our_subsystem.wait, convert = FALSE) : "∞W"]/J</b>")

/obj/machinery/space_heater/improvised_chem_heater/toggle_power(user)
	. = ..()
	if(on)
		begin_processing()

/obj/machinery/space_heater/improvised_chem_heater/process(seconds_per_tick)
	if(!on || !is_operational || QDELETED(cell) || cell.charge <= 1 || QDELETED(beaker))
		if (on) // If it's broken, turn it off too
			on = FALSE
			update_appearance()
		return PROCESS_KILL

	if(beaker.reagents.total_volume)
		var/conduction_modifier = beaker_conduction_power
		switch(set_mode)
			if(HEATER_MODE_AUTO)
				conduction_modifier *= 0.5
			if(HEATER_MODE_HEAT)
				if(target_temperature < beaker.reagents.chem_temp)
					return
			if(HEATER_MODE_COOL)
				if(target_temperature > beaker.reagents.chem_temp)
					return

		var/required_energy = abs(target_temperature - beaker.reagents.chem_temp) * conduction_modifier * seconds_per_tick * beaker.reagents.heat_capacity()
		required_energy = min(required_energy, heating_energy, cell.charge * efficiency)
		if(required_energy < 1)
			return

		var/delta_energy = required_energy
		if(mode == HEATER_MODE_COOL)
			delta_energy *= -1
		if(delta_energy == 0)
			return

		beaker.reagents.adjust_thermal_energy(delta_energy)
		beaker.reagents.handle_reactions()
		cell.use(required_energy / efficiency, force = TRUE)
	update_appearance()

/obj/machinery/space_heater/improvised_chem_heater/ui_data()
	. = ..()
	.["chemHacked"] = TRUE
	.["beaker"] = beaker
	.["currentTemp"] = beaker ? (round(beaker.reagents.chem_temp - T0C)) : "N/A"

/obj/machinery/space_heater/improvised_chem_heater/ui_act(action, list/params, datum/tgui/ui, datum/ui_state/state)
	. = ..()
	if(.)
		return
	switch(action)
		if("ejectBeaker")
			//Eject doesn't turn it off, so you can preheat for beaker swapping
			replace_beaker(usr)
			. = TRUE

///Slightly modified to ignore the open_hatch - it's always open, we hacked it.
/obj/machinery/space_heater/improvised_chem_heater/attackby(obj/item/item, mob/user, params)
	add_fingerprint(user)
	if(default_deconstruction_crowbar(item))
		return
	if(istype(item, /obj/item/stock_parts/power_store/cell))
		if(cell)
			to_chat(user, span_warning("There is already a power cell inside!"))
			return
		else if(!user.transferItemToLoc(item, src))
			return
		cell = item
		item.add_fingerprint(usr)

		user.visible_message(span_notice("\The [user] inserts a power cell into \the [src]."), span_notice("You insert the power cell into \the [src]."))
		SStgui.update_uis(src)
	//reagent containers
	if(is_reagent_container(item) && !(item.item_flags & ABSTRACT) && item.is_open_container())
		. = TRUE //no afterattack
		var/obj/item/reagent_containers/container = item
		if(!user.transferItemToLoc(container, src))
			return
		replace_beaker(user, container)
		to_chat(user, span_notice("You add [container] to [src]'s water bath."))
		ui_interact(user)
		return
	//Dropper tools
	if(beaker)
		if(is_type_in_list(item, list(/obj/item/reagent_containers/dropper, /obj/item/ph_meter, /obj/item/ph_paper, /obj/item/reagent_containers/syringe)))
			item.interact_with_atom(beaker, user)
		return

/obj/machinery/space_heater/improvised_chem_heater/on_deconstruction(disassembled = TRUE)
	. = ..()
	if(disassembled)
		beaker?.forceMove(drop_location())
		beaker = null
	var/static/bonus_junk = list(
		/obj/item/stack/cable_coil = 2,
		/obj/item/stack/sheet/glass = 2,
		/obj/item/stack/sheet/iron = 2,
		/obj/item/thermometer = 1
		)
	for(var/item in bonus_junk)
		if(prob(80))
			new item(get_turf(loc))

/obj/machinery/space_heater/improvised_chem_heater/proc/replace_beaker(mob/living/user, obj/item/reagent_containers/new_beaker)
	if(!user)
		return FALSE
	if(beaker)
		try_put_in_hand(beaker, user)
		beaker = null
	if(new_beaker)
		beaker = new_beaker
	update_appearance()
	return TRUE

/obj/machinery/space_heater/improvised_chem_heater/click_alt(mob/living/user)
	replace_beaker(user)
	return CLICK_ACTION_SUCCESS

/obj/machinery/space_heater/improvised_chem_heater/update_icon_state()
	. = ..()
	if(!on || !beaker || !cell)
		icon_state = "sheater-off"
		return
	if(target_temperature < beaker.reagents.chem_temp)
		icon_state = "sheater-cool"
		return
	if(target_temperature > beaker.reagents.chem_temp)
		icon_state = "sheater-heat"
		return
	icon_state = "sheater-off"

/obj/machinery/space_heater/improvised_chem_heater/RefreshParts()
	. = ..()
	var/lasers_rating = 0
	var/capacitors_rating = 0
	for(var/datum/stock_part/micro_laser/laser in component_parts)
		lasers_rating += laser.tier
	for(var/datum/stock_part/capacitor/capacitor in component_parts)
		capacitors_rating += capacitor.tier

	heating_energy = lasers_rating * initial(heating_energy)

	settable_temperature_range = capacitors_rating * initial(settable_temperature_range) //-20 - 80 at base
	efficiency = (capacitors_rating + 1) * initial(efficiency) * 0.5

	target_temperature = clamp(target_temperature,
		max(settable_temperature_median - settable_temperature_range, TCMB),
		settable_temperature_median + settable_temperature_range)

	// No time integration is used, so we should clamp this to prevent being able to overshoot if there was a subtype with a high initial value.
	beaker_conduction_power = min((capacitors_rating + 1) * 0.5 * initial(beaker_conduction_power), 1 SECONDS / our_subsystem.wait)

#undef HEATER_MODE_STANDBY
#undef HEATER_MODE_HEAT
#undef HEATER_MODE_COOL
#undef HEATER_MODE_AUTO
#undef BASE_HEATING_ENERGY
