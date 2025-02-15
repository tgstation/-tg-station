///Minimum pressure of gases pumped through the turbine
#define MINIMUM_TURBINE_PRESSURE 0.01
///Returns the minimum pressure if it falls below the value
#define PRESSURE_MAX(value)(max((value), MINIMUM_TURBINE_PRESSURE))

/obj/machinery/power/turbine
	icon = 'icons/obj/machines/engine/turbine.dmi'
	density = TRUE
	resistance_flags = FIRE_PROOF
	can_atmos_pass = ATMOS_PASS_DENSITY
	processing_flags = START_PROCESSING_MANUALLY

	///The cached efficiency of this turbines installed part
	var/efficiency = 0
	///Reference to our turbine part
	var/obj/item/turbine_parts/installed_part
	///Path of the turbine part we can install
	var/obj/item/turbine_parts/part_path
	///The gas mixture this turbine part is storing
	var/datum/gas_mixture/machine_gasmix

/obj/machinery/power/turbine/Initialize(mapload, gas_theoretical_volume)
	. = ..()

	machine_gasmix = new
	machine_gasmix.volume = gas_theoretical_volume

	if(mapload)
		installed_part = new part_path(src)
		efficiency = installed_part.get_tier_value(TURBINE_MAX_EFFICIENCY)

	air_update_turf(TRUE)

	update_appearance(UPDATE_OVERLAYS)

	register_context()

/obj/machinery/power/turbine/post_machine_initialize()
	. = ..()

	activate_parts()

/obj/machinery/power/turbine/Destroy()
	air_update_turf(TRUE)

	if(installed_part)
		QDEL_NULL(installed_part)

	if(machine_gasmix)
		QDEL_NULL(machine_gasmix)

	deactivate_parts()
	return ..()

/obj/machinery/power/turbine/on_deconstruction(disassembled)
	installed_part?.forceMove(loc)
	return ..()

/obj/machinery/power/turbine/add_context(atom/source, list/context, obj/item/held_item, mob/user)
	if(isnull(held_item))
		return NONE

	if(panel_open && istype(held_item, part_path))
		context[SCREENTIP_CONTEXT_CTRL_LMB] = "[installed_part ? "Replace" : "Install"] part"
		return CONTEXTUAL_SCREENTIP_SET

	if(held_item.tool_behaviour == TOOL_SCREWDRIVER)
		context[SCREENTIP_CONTEXT_CTRL_LMB] = "[panel_open ? "Close" : "Open"] panel"
		return CONTEXTUAL_SCREENTIP_SET

	if(held_item.tool_behaviour == TOOL_WRENCH && panel_open)
		context[SCREENTIP_CONTEXT_CTRL_LMB] = "Rotate"
		return CONTEXTUAL_SCREENTIP_SET

	if(held_item.tool_behaviour == TOOL_CROWBAR)
		if(installed_part)
			context[SCREENTIP_CONTEXT_CTRL_RMB] = "Remove part"
		if(panel_open)
			context[SCREENTIP_CONTEXT_CTRL_LMB] = "Deconstruct"
		return CONTEXTUAL_SCREENTIP_SET

	if(held_item.tool_behaviour == TOOL_MULTITOOL)
		if(panel_open)
			context[SCREENTIP_CONTEXT_CTRL_LMB] = "Change cable layer"
		else
			context[SCREENTIP_CONTEXT_CTRL_LMB] = "Link parts"
		return CONTEXTUAL_SCREENTIP_SET

/obj/machinery/power/turbine/examine(mob/user)
	. = ..()
	if(installed_part)
		. += span_notice("Currently at tier [installed_part.current_tier].")
		if(installed_part.current_tier + 1 < TURBINE_PART_TIER_FOUR)
			. += span_notice("Can be upgraded by using a tier [installed_part.current_tier + 1] part.")
		. += span_notice("\The [installed_part] can be [EXAMINE_HINT("pried")] out.")
	else
		. += span_warning("Is missing a [initial(part_path.name)].")
	. += span_notice("Its maintainence panel can be [EXAMINE_HINT("screwed")] [panel_open ? "closed" : "open"].")
	if(panel_open)
		. += span_notice("It can rotated with a [EXAMINE_HINT("wrench")]")
		. += span_notice("The full machine can be [EXAMINE_HINT("pried")] apart")

///Is this machine currently running
/obj/machinery/power/turbine/proc/is_active()
	SHOULD_BE_PURE(TRUE)
	PROTECTED_PROC(TRUE)

	return FALSE

/**
 * Adds overlays to this turbines appearance
 * Arguments
 *
 * * list/overlays - the list of overlays to add to
 */
/obj/machinery/power/turbine/proc/set_overlays(list/overlays)
	PROTECTED_PROC(TRUE)

	overlays += "[base_icon_state]_[is_active() ? "on" : "off"]"

/obj/machinery/power/turbine/update_overlays()
	. = ..()

	if(panel_open)
		. += "[base_icon_state]_open"

	set_overlays(.)

/**
 * Handles all the calculations needed for the gases, work done, temperature increase/decrease
 *
 * Arguments
 * * datum/gas_mixture/input_mix - the gas from the environment or from another part of the turbine
 * * datum/gas_mixture/output_mix - the gas that got pumped into this part from the input mix.
 * ideally should be same as input mix but varying texmperatur & pressures can cause varying results
 * * work_amount_to_remove - the amount of work to subtract from the actual work done to pump in the input mixture.
 * For e.g. if gas was transfered from the inlet compressor to the rotor we want to subtract the work done
 * by the inlet from the rotor to get the true work done
 * * intake_size - the percentage of gas to be fed into an turbine part, controlled by turbine computer for inlet compressor only
 */
/obj/machinery/power/turbine/proc/transfer_gases(datum/gas_mixture/input_mix, datum/gas_mixture/output_mix, work_amount_to_remove, intake_size = 1)
	PROTECTED_PROC(TRUE)

	//pump gases. if no gases were transferred then no work was done
	var/output_pressure = PRESSURE_MAX(output_mix.return_pressure())
	var/datum/gas_mixture/transferred_gases = input_mix.pump_gas_to(output_mix, input_mix.return_pressure() * intake_size)
	if(!transferred_gases)
		return 0

	//compute work done
	var/work_done = QUANTIZE(transferred_gases.total_moles()) * R_IDEAL_GAS_EQUATION * transferred_gases.temperature * log((transferred_gases.volume * PRESSURE_MAX(transferred_gases.return_pressure())) / (output_mix.volume * output_pressure)) * TURBINE_WORK_CONVERSION_MULTIPLIER
	if(work_amount_to_remove)
		work_done = work_done - work_amount_to_remove

	//compute temperature & work from temperature if that is a lower value
	var/output_mix_heat_capacity = output_mix.heat_capacity()
	if(!output_mix_heat_capacity)
		return 0
	work_done = min(work_done, (output_mix_heat_capacity * output_mix.temperature - output_mix_heat_capacity * TCMB) / TURBINE_HEAT_CONVERSION_MULTIPLIER)
	output_mix.temperature = max((output_mix.temperature * output_mix_heat_capacity + work_done * TURBINE_HEAT_CONVERSION_MULTIPLIER) / output_mix_heat_capacity, TCMB)
	return work_done

/obj/machinery/power/turbine/block_superconductivity()
	return TRUE

/obj/machinery/power/turbine/screwdriver_act(mob/living/user, obj/item/tool)
	. = ITEM_INTERACT_BLOCKING
	if(is_active())
		balloon_alert(user, "turn it off!")
		return
	if(!anchored)
		balloon_alert(user, "anchor first!")
		return

	tool.play_tool_sound(src, 50)
	toggle_panel_open()
	if(panel_open)
		deactivate_parts(user)
	else
		activate_parts(user)
	update_appearance(UPDATE_OVERLAYS)

	return ITEM_INTERACT_SUCCESS

/obj/machinery/power/turbine/wrench_act(mob/living/user, obj/item/tool)
	. = ITEM_INTERACT_BLOCKING
	if(default_change_direction_wrench(user, tool))
		return ITEM_INTERACT_SUCCESS

/obj/machinery/power/turbine/crowbar_act(mob/living/user, obj/item/tool)
	. = ITEM_INTERACT_BLOCKING
	if(default_deconstruction_crowbar(tool))
		return ITEM_INTERACT_SUCCESS

/obj/machinery/power/turbine/crowbar_act_secondary(mob/living/user, obj/item/tool)
	. = ITEM_INTERACT_BLOCKING
	if(!panel_open)
		balloon_alert(user, "panel is closed!")
		return
	if(!installed_part)
		balloon_alert(user, "no rotor installed!")
		return
	if(is_active())
		balloon_alert(user, "[src] is on!")
		return

	user.put_in_hands(installed_part)
	return ITEM_INTERACT_SUCCESS

/**
 * Allow easy enabling of each machine for connection to the main controller
 *
 * Arguments
 * * mob/user - the player who activated the parts
 * * check_only - if TRUE it will not activate the machine but will only check if it can be activated
 */
/obj/machinery/power/turbine/proc/activate_parts(mob/user, check_only = FALSE)
	SHOULD_CALL_PARENT(TRUE)

	set_machine_stat(machine_stat & ~MAINT)

	return TRUE

/**
 * Allow easy disabling of each machine from the main controller
 *
 * Arguments
 * * mob/user - the player who deactivated the parts
 */
/obj/machinery/power/turbine/proc/deactivate_parts(mob/user)
	SHOULD_CALL_PARENT(TRUE)

	set_machine_stat(machine_stat | MAINT)

	return TRUE

/obj/machinery/power/turbine/Moved(atom/old_loc, movement_dir, forced, list/old_locs, momentum_change = TRUE)
	. = ..()
	set_panel_open(TRUE)
	update_appearance(UPDATE_OVERLAYS)
	deactivate_parts()
	old_loc.air_update_turf(TRUE)
	air_update_turf(TRUE)

/obj/machinery/power/turbine/Exited(atom/movable/gone, direction)
	. = ..()
	if(gone == installed_part)
		installed_part = null

/obj/machinery/power/turbine/item_interaction(mob/living/user, obj/item/turbine_parts/object, list/modifiers)
	. = NONE
	if(!istype(object, part_path))
		return

	//not in a state to accept the part. block so we don't bash the machine and damage it
	if(is_active())
		balloon_alert(user, "turn off the machine first!")
		return ITEM_INTERACT_BLOCKING
	if(!panel_open)
		balloon_alert(user, "open the maintenance hatch first!")
		return ITEM_INTERACT_BLOCKING

	//install the part
	if(!do_after(user, 2 SECONDS, src))
		return ITEM_INTERACT_BLOCKING
	if(installed_part)
		user.put_in_hands(installed_part)
		balloon_alert(user, "replaced part with the one in hand")
	else
		balloon_alert(user, "installed new part")
	user.transferItemToLoc(object, src)
	installed_part = object
	efficiency = installed_part.get_tier_value(TURBINE_MAX_EFFICIENCY)

	return ITEM_INTERACT_SUCCESS

/obj/machinery/power/turbine/inlet_compressor
	name = "inlet compressor"
	desc = "The input side of a turbine generator, contains the compressor."
	icon_state = "inlet_compressor"
	base_icon_state = "inlet"
	circuit = /obj/item/circuitboard/machine/turbine_compressor
	part_path = /obj/item/turbine_parts/compressor

	/// The rotor this inlet is linked to
	var/obj/machinery/power/turbine/core_rotor/rotor
	/// The turf from which it absorbs gases from
	var/turf/open/input_turf
	/// Work acheived during compression
	var/compressor_work
	/// Pressure of gases absorbed
	var/compressor_pressure
	///Ratio of gases going in the turbine
	var/intake_regulator = 0.5

/obj/machinery/power/turbine/inlet_compressor/Initialize(mapload)
	//Volume of gas mixture is 1000
	return ..(mapload, gas_theoretical_volume = 1000)

/obj/machinery/power/turbine/inlet_compressor/is_active()
	return QDELETED(rotor) ? FALSE : rotor.is_active()

/obj/machinery/power/turbine/inlet_compressor/deactivate_parts(mob/user)
	. = ..()
	if(!QDELETED(rotor))
		rotor.deactivate_parts()
	rotor = null
	input_turf = null

/**
 * transfers gases from its input turf to its internal gas mix
 * Returns temperature of the gas mix absorbed only if some work was done
 */
/obj/machinery/power/turbine/inlet_compressor/proc/compress_gases()
	SHOULD_NOT_OVERRIDE(TRUE)

	compressor_work = 0
	compressor_pressure = MINIMUM_TURBINE_PRESSURE
	if(QDELETED(input_turf))
		input_turf = get_step(loc, REVERSE_DIR(dir))

	var/datum/gas_mixture/input_turf_mixture = input_turf.return_air()
	if(!input_turf_mixture)
		return 0

	//the compressor compresses down the gases from 2500 L to 1000 L
	//the temperature and pressure rises up, you can regulate this to increase/decrease the amount of gas moved in.
	compressor_work = transfer_gases(input_turf_mixture, machine_gasmix, work_amount_to_remove = 0, intake_size = intake_regulator)
	input_turf.air_update_turf(TRUE)
	input_turf.update_visuals()
	compressor_pressure = PRESSURE_MAX(machine_gasmix.return_pressure())

	return input_turf_mixture.temperature

//===========================OUTLET==============================================
/obj/machinery/power/turbine/turbine_outlet
	name = "turbine outlet"
	desc = "The output side of a turbine generator, contains the turbine and the stator."
	icon_state = "turbine_outlet"
	base_icon_state = "outlet"
	circuit = /obj/item/circuitboard/machine/turbine_stator
	part_path = /obj/item/turbine_parts/stator

	/// The rotor this outlet is linked to
	var/obj/machinery/power/turbine/core_rotor/rotor
	/// The turf to puch the gases out into
	var/turf/open/output_turf

/obj/machinery/power/turbine/turbine_outlet/Initialize(mapload)
	//Volume of gas mixture is 6000
	return ..(mapload, gas_theoretical_volume = 6000)

/obj/machinery/power/turbine/turbine_outlet/is_active()
	return QDELETED(rotor) ? FALSE : rotor.is_active()

/obj/machinery/power/turbine/turbine_outlet/deactivate_parts(mob/user)
	. = ..()
	if(!QDELETED(rotor))
		rotor.deactivate_parts()
	rotor = null
	output_turf = null

/// push gases from its gas mix to output turf
/obj/machinery/power/turbine/turbine_outlet/proc/expel_gases()
	SHOULD_NOT_OVERRIDE(TRUE)

	if(QDELETED(output_turf))
		output_turf = get_step(loc, dir)
	//turf is blocked don't eject gases
	if(!TURF_SHARES(output_turf))
		return FALSE

	//eject gases and update turf if any was ejected
	var/datum/gas_mixture/ejected_gases = machine_gasmix.pump_gas_to(output_turf.air, machine_gasmix.return_pressure())
	if(ejected_gases)
		output_turf.air_update_turf(TRUE)
		output_turf.update_visuals()

	//return ejected gases
	return ejected_gases

//===========================================CORE ROTOR=========================================
/obj/machinery/power/turbine/core_rotor
	name = "core rotor"
	desc = "The middle part of a turbine generator, contains the rotor and the main computer."
	icon_state = "core_rotor"
	base_icon_state = "core"
	can_change_cable_layer = TRUE
	circuit = /obj/item/circuitboard/machine/turbine_rotor
	part_path = /obj/item/turbine_parts/rotor

	///ID to easily connect the main part of the turbine to the computer
	var/mapping_id
	///Checks if the machine is processing or not
	var/active = FALSE
	///Reference to the compressor
	var/obj/machinery/power/turbine/inlet_compressor/compressor
	///Reference to the turbine
	var/obj/machinery/power/turbine/turbine_outlet/turbine
	///Rotation per minute the machine is doing
	var/rpm = 0
	///Amount of power the machine is producing
	var/produced_energy = 0
	///Check to see if all parts are connected to the core
	var/all_parts_connected = FALSE
	///Max rmp that the installed parts can handle, limits the rpms
	var/max_allowed_rpm = 0
	///Max temperature that the installed parts can handle, unlimited and causes damage to the machine
	var/max_allowed_temperature = 0
	///Amount of damage the machine has received
	var/damage = 0
	///Used to calculate the max damage received per tick and if the alarm should be called
	var/damage_archived = 0

	COOLDOWN_DECLARE(turbine_damage_alert)

/obj/machinery/power/turbine/core_rotor/Initialize(mapload)
	//Volume of gas mixture is 3000
	. = ..(mapload, gas_theoretical_volume = 3000)

	new /obj/item/paper/guides/jobs/atmos/turbine(loc)

/obj/machinery/power/turbine/core_rotor/add_context(atom/source, list/context, obj/item/held_item, mob/user)
	. = ..()
	if(. == NONE)
		return

	if(held_item.tool_behaviour == TOOL_MULTITOOL)
		if(panel_open)
			context[SCREENTIP_CONTEXT_CTRL_LMB] = "Change cable layer"
		else
			context[SCREENTIP_CONTEXT_CTRL_LMB] = "Link/Log parts"
		return CONTEXTUAL_SCREENTIP_SET

/obj/machinery/power/turbine/core_rotor/examine(mob/user)
	. = ..()
	if(!panel_open)
		. += span_notice("[EXAMINE_HINT("screw")] open its panel to change cable layer.")
	if(!all_parts_connected)
		. += span_warning("The parts need to be linked via a [EXAMINE_HINT("multitool")]")

///Adds overlays to this turbines appearance
/obj/machinery/power/turbine/core_rotor/set_overlays(list/overlays)
	if(active)
		overlays += "[base_icon_state]_on"
		overlays += emissive_appearance(icon, "[base_icon_state]_on", src)

/obj/machinery/power/turbine/core_rotor/is_active()
	return active

/obj/machinery/power/turbine/core_rotor/cable_layer_act(mob/living/user, obj/item/tool)
	if(!panel_open)
		balloon_alert(user, "open panel first!")
		return ITEM_INTERACT_BLOCKING
	return ..()

/obj/machinery/power/turbine/core_rotor/multitool_act(mob/living/user, obj/item/tool)
	//allow cable layer changing
	if(panel_open)
		return ..()

	//failed checks
	if(!activate_parts(user))
		return ITEM_INTERACT_SUCCESS

	//log rotor to link later to computer
	balloon_alert(user, "all parts linked")
	var/obj/item/multitool/multitool = tool
	multitool.set_buffer(src)
	to_chat(user, span_notice("You store linkage information in [tool]'s buffer."))

	//success
	return ITEM_INTERACT_SUCCESS

/obj/machinery/power/turbine/core_rotor/multitool_act_secondary(mob/living/user, obj/item/tool)
	//allow cable layer changing
	if(panel_open)
		return ..()

	//works same as regular left click
	return multitool_act(user, tool)

/**
 * convinience proc for balloon alert which returns if viewer is null
 * Arguments
 *
 * * mob/viewer - the player receiving the message
 * * text - the message
 */
/obj/machinery/power/turbine/core_rotor/proc/feedback(mob/viewer, text)
	PRIVATE_PROC(TRUE)

	if(isnull(viewer))
		return
	balloon_alert(viewer, text)

///Called to activate the complete machine, checks for part presence, correct orientation and installed parts
/obj/machinery/power/turbine/core_rotor/activate_parts(mob/user, check_only = FALSE)
	//if this is not a checkup and all parts are connected then we have nothing to do
	if(!check_only && all_parts_connected)
		return TRUE

	//are we broken
	if(machine_stat & BROKEN)
		feedback(user, "rotor is broken!")
		return (all_parts_connected = FALSE)

	//locate compressor & turbine, when checking we simply check to see if they are still there
	if(!check_only)
		compressor = locate() in get_step(src, REVERSE_DIR(dir))
		turbine = locate() in get_step(src, dir)

		//maybe look for them the other way around. this means the rotor is facing the wrong way
		if(QDELETED(compressor) && QDELETED(turbine))
			compressor = locate() in get_step(src, dir)
			turbine = locate() in get_step(src, REVERSE_DIR(dir))

			//show corrective actions
			if(!QDELETED(compressor) || !QDELETED(turbine))
				feedback(user, "rotor is facing the wrong way!")
				return (all_parts_connected = FALSE)

	//sanity checks for compressor
	if(QDELETED(compressor))
		feedback(user, "missing compressor!")
		return (all_parts_connected = FALSE)
	if(compressor.dir != dir && compressor.dir != REVERSE_DIR(dir)) //make sure it's not perpendicular to the rotor
		feedback(user, "compressor not aligned with rotor!")
		return (all_parts_connected = FALSE)
	if(compressor.machine_stat & MAINT)
		feedback(user, "close compressor panel!")
		return (all_parts_connected = FALSE)
	if(compressor.machine_stat & BROKEN)
		feedback(user, "compressor is broken!")
		return (all_parts_connected = FALSE)
	if(!compressor.installed_part)
		feedback(user, "compressor has a missing part!")
		return (all_parts_connected = FALSE)

	//sanity checks for turbine
	if(QDELETED(turbine))
		feedback(user, "missing turbine!")
		return (all_parts_connected = FALSE)
	if(turbine.dir != dir && turbine.dir != REVERSE_DIR(dir)) //make sure it's not perpendicular to the rotor
		feedback(user, "turbine not aligned with rotor!")
		return (all_parts_connected = FALSE)
	if(turbine.machine_stat & MAINT)
		feedback(user, "close turbine panel!")
		return (all_parts_connected = FALSE)
	if(turbine.machine_stat & BROKEN)
		feedback(user, "turbine is broken!")
		return (all_parts_connected = FALSE)
	if(!turbine.installed_part)
		feedback(user, "turbine is missing stator part!")
		return (all_parts_connected = FALSE)

	//sanity check to make sure turbine & compressor are facing the same direction. From an visual perspective they will appear facing away from each other actually. I know blame spriter's
	if(compressor.dir != turbine.dir)
		feedback(user, "turbine & compressor are not facing away from each other!")
		return (all_parts_connected = FALSE)

	//all checks successfull remember result
	all_parts_connected = TRUE
	if(check_only)
		return TRUE

	compressor.rotor = src
	turbine.rotor = src
	max_allowed_rpm = (compressor.installed_part.get_tier_value(TURBINE_MAX_RPM) + turbine.installed_part.get_tier_value(TURBINE_MAX_RPM) + installed_part.get_tier_value(TURBINE_MAX_RPM)) / 3
	max_allowed_temperature = (compressor.installed_part.get_tier_value(TURBINE_MAX_TEMP) + turbine.installed_part.get_tier_value(TURBINE_MAX_TEMP) + installed_part.get_tier_value(TURBINE_MAX_TEMP)) / 3
	connect_to_network()

	return ..()

///Allows to null the various machines and references from the main core
/obj/machinery/power/turbine/core_rotor/deactivate_parts()
	toggle_power(force_off = TRUE)
	compressor?.rotor = null
	compressor = null
	turbine?.rotor = null
	turbine = null
	all_parts_connected = FALSE
	rpm = 0
	produced_energy = 0
	disconnect_from_network()

	return ..()

/obj/machinery/power/turbine/core_rotor/on_deconstruction(disassembled)
	deactivate_parts()
	return ..()

/// Toggle power on and off, not safe
/obj/machinery/power/turbine/core_rotor/proc/toggle_power(force_off)
	SHOULD_NOT_OVERRIDE(TRUE)

	//toggle status
	if(force_off)
		if(!active) //was already off
			return
		active = FALSE
	else
		active = !active

	//update operation status of parts
	update_appearance(UPDATE_OVERLAYS)
	if(!QDELETED(compressor))
		compressor.update_appearance(UPDATE_OVERLAYS)
	if(!QDELETED(turbine))
		turbine.update_appearance(UPDATE_OVERLAYS)

	//start or stop processing
	if(active)
		update_mode_power_usage(ACTIVE_POWER_USE, active_power_usage)
		begin_processing()
	else
		unset_static_power()
		end_processing()

/// Getter for turbine integrity, return the amount in %
/obj/machinery/power/turbine/core_rotor/proc/get_turbine_integrity()
	SHOULD_NOT_OVERRIDE(TRUE)

	return max(round(100 - (damage / 500) * 100, 0.01), 0)

/obj/machinery/power/turbine/core_rotor/process(seconds_per_tick)
	if(!active || !activate_parts(check_only = TRUE) || !powered(ignore_use_power = TRUE))
		deactivate_parts()
		return PROCESS_KILL

	//===============COMPRESSOR WORKING========//
	//Transfer gases from turf to compressor
	var/temperature = compressor.compress_gases()
	//Compute damage taken based on temperature
	damage_archived = damage
	var/temperature_difference = temperature - max_allowed_temperature
	var/damage_done = round(log(90, max(temperature_difference, 1)), 0.5)
	damage = max(damage + damage_done * 0.5, 0)
	damage = min(damage_archived + TURBINE_MAX_TAKEN_DAMAGE, damage)
	if(temperature_difference < 0)
		damage = max(damage - TURBINE_DAMAGE_HEALING, 0)
	//Apply damage if it passes threshold limits
	if((damage - damage_archived >= 2 || damage > TURBINE_DAMAGE_ALARM_START) && COOLDOWN_FINISHED(src, turbine_damage_alert))
		COOLDOWN_START(src, turbine_damage_alert, max(round(TURBINE_DAMAGE_ALARM_START - damage_done), 5) SECONDS)
		//Boom!
		var/integrity = get_turbine_integrity()
		if(integrity <= 0)
			deactivate_parts()
			if(rpm < TURBINE_MAX_BASE_RPM)
				explosion(src, 0, 1, 4)
				return PROCESS_KILL
			if(rpm < TURBINE_MAX_BASE_RPM * 2.5)
				explosion(src, 0, 2, 6)
				return PROCESS_KILL
			if(rpm < TURBINE_MAX_BASE_RPM * 2.5 * 2.5)
				explosion(src, 1, 3, 7)
				return PROCESS_KILL
			if(rpm < TURBINE_MAX_BASE_RPM * 2.5 * 2.5 * 2.5)
				explosion(src, 2, 5, 7)
			return PROCESS_KILL

		aas_config_announce(/datum/aas_config_entry/engineering_turbine_failure, list("INTEGRITY" = integrity, "LOCATION" = get_area_name(src)), src, list(RADIO_CHANNEL_ENGINEERING))
		playsound(src, 'sound/machines/engine_alert/engine_alert1.ogg', 100, FALSE, 30, 30, falloff_distance = 10)

	//================ROTOR WORKING============//
	//The Rotor moves the gases that expands from 1000 L to 3000 L, they cool down and both temperature and pressure lowers
	var/rotor_work = transfer_gases(compressor.machine_gasmix, machine_gasmix, compressor.compressor_work)
	//the turbine expands the gases more from 3000 L to 6000 L, cooling them down further.
	var/turbine_work = transfer_gases(machine_gasmix, turbine.machine_gasmix, abs(rotor_work))

	//================TURBINE WORKING============//
	//Calculate final power generated based on how much gas was ejected from the turbine
	var/datum/gas_mixture/ejected_gases = turbine.expel_gases()
	if(!ejected_gases) //output turf was blocked with high pressure/temperature gases or by some structure so no power generated
		rpm = 0
		produced_energy = 0
		return
	var/work_done =  QUANTIZE(ejected_gases.total_moles()) * R_IDEAL_GAS_EQUATION * ejected_gases.temperature * log(compressor.compressor_pressure / PRESSURE_MAX(ejected_gases.return_pressure()))
	//removing the work needed to move the compressor but adding back the turbine work that is the one generating most of the power.
	work_done = max(work_done - compressor.compressor_work * TURBINE_COMPRESSOR_STATOR_INTERACTION_MULTIPLIER - turbine_work, 0)
	//calculate final acheived rpm
	rpm = ((work_done * compressor.efficiency) ** turbine.efficiency) * efficiency / TURBINE_RPM_CONVERSION
	rpm = min(ROUND_UP(rpm), max_allowed_rpm)
	//add energy into the grid, also use part of it for turbine operation
	produced_energy = rpm * TURBINE_ENERGY_RECTIFICATION_MULTIPLIER * TURBINE_RPM_CONVERSION * seconds_per_tick
	add_avail(produced_energy)

/obj/item/paper/guides/jobs/atmos/turbine
	name = "paper- 'Quick guide on the new and improved turbine!'"
	default_raw_text = "<B>How to operate the turbine</B><BR>\
	-The new turbine is not much different from the old one, just put gases in the chamber, light them up and activate the machine from the nearby computer.\
	-There is a new parameter that's visible within the turbine computer's UI, damage. The turbine will be damaged when the heat gets too high, according to the tiers of the parts used. Make sure it doesn't get too hot!<BR>\
	-You can avoid the turbine critically failing by upgrading the parts of the machine, but not with stock parts as you might be used to. There are 3 all-new parts, one for each section of the turbine.<BR>\
	-These items are: the compressor part, the rotor part and the stator part. All of them can be printed in any engi lathes (both proto and auto).<BR>\
	-There are 4 tiers for these items, only the first tier can be printed. The next tier of each part can be made by using various materials on the part (clicking with the material in hand, on the part). The material required to reach the next tier is stated in the part's examine text, try shift clicking it!<BR>\
	-Each tier increases the efficiency (more power), the max reachable RPM, and the max temperature that the machine can process without taking damage (up to fusion temperatures at the last tier!).<BR>\
	-A word of warning, the machine is very inefficient in its gas consumption and many unburnt gases will pass through. If you want to be cheap you can either pre-burn the gases or add a filtering system to collect the unburnt gases and reuse them."

/datum/aas_config_entry/engineering_turbine_failure
	name = "Engineering Alert: Turbine Failure"
	announcement_lines_map = list(
		"Message" = "Warning, turbine at %LOCATION taking damage, current integrity at %INTEGRITY%!",
	)
	vars_and_tooltips_map = list(
		"LOCATION" = "will be replaced with location of the turbine.",
		"INTEGRITY" = "with the current integrity of the turbine.",
	)

#undef PRESSURE_MAX
#undef MINIMUM_TURBINE_PRESSURE
