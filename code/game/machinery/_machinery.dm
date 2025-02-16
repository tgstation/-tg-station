/**
 * Machines in the world, such as computers, pipes, and airlocks.
 *
 *Overview:
 *  Used to create objects that need a per step proc call.  Default definition of 'Initialize()'
 *  stores a reference to src machine in global 'machines list'.  Default definition
 *  of 'Destroy' removes reference to src machine in global 'machines list'.
 *
 *Class Variables:
 *  use_power (num)
 *     current state of auto power use.
 *     Possible Values:
 *        NO_POWER_USE -- no auto power use
 *        IDLE_POWER_USE -- machine is using power at its idle power level
 *        ACTIVE_POWER_USE -- machine is using power at its active power level
 *
 *  active_power_usage (num)
 *     Value for the amount of power to use when in active power mode
 *
 *  idle_power_usage (num)
 *     Value for the amount of power to use when in idle power mode
 *
 *  power_channel (num)
 *     What channel to draw from when drawing power for power mode
 *     Possible Values:
 *        AREA_USAGE_EQUIP:1 -- Equipment Channel
 *        AREA_USAGE_LIGHT:2 -- Lighting Channel
 *        AREA_USAGE_ENVIRON:3 -- Environment Channel
 *
 *  component_parts (list)
 *     A list of component parts of machine used by frame based machines.
 *
 *  stat (bitflag)
 *     Machine status bit flags.
 *     Possible bit flags:
 *        BROKEN -- Machine is broken
 *        NOPOWER -- No power is being supplied to machine.
 *        MAINT -- machine is currently under going maintenance.
 *        EMPED -- temporary broken by EMP pulse
 *
 *Class Procs:
 *  Initialize()
 *
 *  Destroy()
 *
 *	update_mode_power_usage()
 *		updates the static_power_usage var of this machine and makes its static power usage from its area accurate.
 *		called after the idle or active power usage has been changed.
 *
 *	update_power_channel()
 *		updates the static_power_usage var of this machine and makes its static power usage from its area accurate.
 *		called after the power_channel var has been changed or called to change the var itself.
 *
 *	unset_static_power()
 *		completely removes the current static power usage of this machine from its area.
 *		used in the other power updating procs to then readd the correct power usage.
 *
 *
 *     Default definition uses 'use_power', 'power_channel', 'active_power_usage',
 *     'idle_power_usage', 'powered()', and 'use_energy()' implement behavior.
 *
 *  powered(chan = -1)         'modules/power/power.dm'
 *     Checks to see if area that contains the object has power available for power
 *     channel given in 'chan'. -1 defaults to power_channel
 *
 *  use_energy(amount, chan=-1)   'modules/power/power.dm'
 *     Deducts 'amount' from the power channel 'chan' of the area that contains the object.
 *
 *  power_change()               'modules/power/power.dm'
 *     Called by the area that contains the object when ever that area under goes a
 *     power state change (area runs out of power, or area channel is turned off).
 *
 *  RefreshParts()               'game/machinery/machine.dm'
 *     Called to refresh the variables in the machine that are contributed to by parts
 *     contained in the component_parts list. (example: glass and material amounts for
 *     the autolathe)
 *
 *     Default definition does nothing.
 *
 *  process()                  'game/machinery/machine.dm'
 *     Called by the 'machinery subsystem' once per machinery tick for each machine that is listed in its 'machines' list.
 *
 *  process_atmos()
 *     Called by the 'air subsystem' once per atmos tick for each machine that is listed in its 'atmos_machines' list.
 * Compiled by Aygar
 */
/obj/machinery
	name = "machinery"
	icon = 'icons/obj/machines/fax.dmi'
	desc = "Some kind of machine."
	verb_say = "beeps"
	verb_yell = "blares"
	pressure_resistance = 15
	pass_flags_self = PASSMACHINE | LETPASSCLICKS
	max_integrity = 200
	layer = BELOW_OBJ_LAYER //keeps shit coming out of the machine from ending up underneath it.
	flags_ricochet = RICOCHET_HARD
	receive_ricochet_chance_mod = 0.3
	anchored = TRUE
	interaction_flags_atom = INTERACT_ATOM_ATTACK_HAND | INTERACT_ATOM_UI_INTERACT
	blocks_emissive = EMISSIVE_BLOCK_GENERIC
	initial_language_holder = /datum/language_holder/speaking_machine
	armor_type = /datum/armor/obj_machinery

	///see code/__DEFINES/stat.dm
	var/machine_stat = NONE
	///see code/__DEFINES/machines.dm
	var/use_power = IDLE_POWER_USE
	///the amount of static power load this machine adds to its area's power_usage list when use_power = IDLE_POWER_USE
	var/idle_power_usage = BASE_MACHINE_IDLE_CONSUMPTION
	///the amount of static power load this machine adds to its area's power_usage list when use_power = ACTIVE_POWER_USE
	var/active_power_usage = BASE_MACHINE_ACTIVE_CONSUMPTION
	///the current amount of static power usage this machine is taking from its area
	var/static_power_usage = 0
	//AREA_USAGE_EQUIP,AREA_USAGE_ENVIRON or AREA_USAGE_LIGHT
	var/power_channel = AREA_USAGE_EQUIP
	///A combination of factors such as having power, not being broken and so on. Boolean.
	var/is_operational = TRUE
	///list of all the parts used to build it, if made from certain kinds of frames.
	var/list/component_parts = null
	///Is the machines maintainence panel open.
	var/panel_open = FALSE
	///Is the machine open or closed
	var/state_open = FALSE
	///If this machine is critical to station operation and should have the area be excempted from power failures.
	var/critical_machine = FALSE
	///if set, turned into typecache in Initialize, other wise, defaults to mob/living typecache
	var/list/occupant_typecache
	///The mob that is sealed inside the machine
	var/atom/movable/occupant = null
	///Viable flags to go here are START_PROCESSING_ON_INIT, or START_PROCESSING_MANUALLY. See code\__DEFINES\machines.dm for more information on these flags.
	var/processing_flags = START_PROCESSING_ON_INIT
	///What subsystem this machine will use, which is generally SSmachines or SSfastprocess. By default all machinery use SSmachines. This fires a machine's process() roughly every 2 seconds.
	var/subsystem_type = /datum/controller/subsystem/machines
	///Circuit to be created and inserted when the machinery is created
	var/obj/item/circuitboard/circuit
	///See code/DEFINES/interaction_flags.dm
	var/interaction_flags_machine = INTERACT_MACHINE_WIRES_IF_OPEN | INTERACT_MACHINE_ALLOW_SILICON | INTERACT_MACHINE_OPEN_SILICON
	///The department we are paying to use this machine
	var/payment_department = ACCOUNT_ENG
	///Used in NAP violation, pay fine
	var/fair_market_price = 5
	///Is this machine currently in the atmos machinery queue?
	var/atmos_processing = FALSE
	///world.time of last use by [/mob/living]
	var/last_used_time = 0
	///Mobtype of last user. Typecast to [/mob/living] for initial() usage
	var/mob/living/last_user_mobtype
	///Do we want to hook into on_enter_area and on_exit_area?
	///Disables some optimizations
	var/always_area_sensitive = FALSE
	///What was our power state the last time we updated its appearance?
	///TRUE for on, FALSE for off, -1 for never checked
	var/appearance_power_state = -1

/datum/armor/obj_machinery
	melee = 25
	bullet = 10
	laser = 10
	fire = 50
	acid = 70

/obj/machinery/Initialize(mapload)
	. = ..()
	SSmachines.register_machine(src)

	if(ispath(circuit, /obj/item/circuitboard))
		circuit = new circuit(src)
		circuit.apply_default_parts(src)

	if(processing_flags & START_PROCESSING_ON_INIT)
		begin_processing()

	if(occupant_typecache)
		occupant_typecache = typecacheof(occupant_typecache)

	if((resistance_flags & INDESTRUCTIBLE) && component_parts){ // This is needed to prevent indestructible machinery still blowing up. If an explosion occurs on the same tile as the indestructible machinery without the PREVENT_CONTENTS_EXPLOSION_1 flag, /datum/controller/subsystem/explosions/proc/propagate_blastwave will call ex_act on all movable atoms inside the machine, including the circuit board and component parts. However, if those parts get deleted, the entire machine gets deleted, allowing for INDESTRUCTIBLE machines to be destroyed. (See #62164 for more info)
		flags_1 |= PREVENT_CONTENTS_EXPLOSION_1
	}

	if(HAS_TRAIT(SSstation, STATION_TRAIT_MACHINES_GLITCHED) && mapload)
		randomize_language_if_on_station()
	SEND_GLOBAL_SIGNAL(COMSIG_GLOB_NEW_MACHINE, src)

	return INITIALIZE_HINT_LATELOAD

/obj/machinery/LateInitialize()
	SHOULD_NOT_OVERRIDE(TRUE)
	post_machine_initialize()

/**
 * Called in LateInitialize meant to be the machine replacement to it
 * This sets up power for the machine and requires parent be called,
 * ensuring power works on all machines unless exempted with NO_POWER_USE.
 * This is the proc to override if you want to do anything in LateInitialize.
 */
/obj/machinery/proc/post_machine_initialize()
	PROTECTED_PROC(TRUE)
	SHOULD_CALL_PARENT(TRUE)

	power_change()
	if(use_power == NO_POWER_USE)
		return
	update_current_power_usage()
	setup_area_power_relationship()


/obj/machinery/Destroy(force)
	SSmachines.unregister_machine(src)
	end_processing()

	clear_components()
	unset_static_power()

	return ..()

/**
 * proc to call when the machine starts to require power after a duration of not requiring power
 * sets up power related connections to its area if it exists and becomes area sensitive
 * does not affect power usage itself
 *
 * Returns TRUE if it triggered a full registration, FALSE otherwise
 * We do this so machinery that want to sidestep the area sensitiveity optimization can
 */
/obj/machinery/proc/setup_area_power_relationship()
	var/area/our_area = get_area(src)
	if(our_area)
		RegisterSignal(our_area, COMSIG_AREA_POWER_CHANGE, PROC_REF(power_change))

	if(HAS_TRAIT_FROM(src, TRAIT_AREA_SENSITIVE, INNATE_TRAIT)) // If we for some reason have not lost our area sensitivity, there's no reason to set it back up
		return FALSE

	become_area_sensitive(INNATE_TRAIT)
	RegisterSignal(src, COMSIG_ENTER_AREA, PROC_REF(on_enter_area))
	RegisterSignal(src, COMSIG_EXIT_AREA, PROC_REF(on_exit_area))
	return TRUE

/**
 * proc to call when the machine stops requiring power after a duration of requiring power
 * saves memory by removing the power relationship with its area if it exists and loses area sensitivity
 * does not affect power usage itself
 */
/obj/machinery/proc/remove_area_power_relationship()
	var/area/our_area = get_area(src)
	if(our_area)
		UnregisterSignal(our_area, COMSIG_AREA_POWER_CHANGE)

	if(always_area_sensitive)
		return

	lose_area_sensitivity(INNATE_TRAIT)
	UnregisterSignal(src, COMSIG_ENTER_AREA)
	UnregisterSignal(src, COMSIG_EXIT_AREA)

/obj/machinery/proc/on_enter_area(datum/source, area/area_to_register)
	SIGNAL_HANDLER
	// If we're always area sensitive, and this is called while we have no power usage, do nothing and return
	if(always_area_sensitive && use_power == NO_POWER_USE)
		return
	update_current_power_usage()
	power_change()
	RegisterSignal(area_to_register, COMSIG_AREA_POWER_CHANGE, PROC_REF(power_change))

/obj/machinery/proc/on_exit_area(datum/source, area/area_to_unregister)
	SIGNAL_HANDLER
	// If we're always area sensitive, and this is called while we have no power usage, do nothing and return
	if(always_area_sensitive && use_power == NO_POWER_USE)
		return
	unset_static_power()
	UnregisterSignal(area_to_unregister, COMSIG_AREA_POWER_CHANGE)

/obj/machinery/proc/set_occupant(atom/movable/new_occupant)
	SHOULD_CALL_PARENT(TRUE)

	SEND_SIGNAL(src, COMSIG_MACHINERY_SET_OCCUPANT, new_occupant)
	occupant = new_occupant

/// Helper proc for telling a machine to start processing
/obj/machinery/proc/begin_processing()
	var/datum/controller/subsystem/processing/subsystem = locate(subsystem_type) in Master.subsystems
	START_PROCESSING(subsystem, src)

/// Helper proc for telling a machine to stop processing
/obj/machinery/proc/end_processing()
	var/datum/controller/subsystem/processing/subsystem = locate(subsystem_type) in Master.subsystems
	STOP_PROCESSING(subsystem, src)

///Early process for machines added to SSmachines.processing_early to prioritize power draw
/obj/machinery/proc/process_early()
	set waitfor = FALSE
	return PROCESS_KILL

/obj/machinery/process()//If you dont use process or power why are you here
	return PROCESS_KILL

///Late process for machines added to SSmachines.processing_late to gather accurate recordings
/obj/machinery/proc/process_late()
	set waitfor = FALSE
	return PROCESS_KILL

/obj/machinery/proc/process_atmos()//If you dont use process why are you here
	set waitfor = FALSE
	return PROCESS_KILL

///Called when we want to change the value of the machine_stat variable. Holds bitflags.
/obj/machinery/proc/set_machine_stat(new_value)
	SHOULD_NOT_OVERRIDE(TRUE)

	if(new_value == machine_stat)
		return
	. = machine_stat
	machine_stat = new_value
	on_set_machine_stat(.)


///Called when the value of `machine_stat` changes, so we can react to it.
/obj/machinery/proc/on_set_machine_stat(old_value)
	PROTECTED_PROC(TRUE)

	//From off to on.
	if((old_value & (NOPOWER|BROKEN|MAINT)) && !(machine_stat & (NOPOWER|BROKEN|MAINT)))
		set_is_operational(TRUE)
		return
	//From on to off.
	if(machine_stat & (NOPOWER|BROKEN|MAINT))
		set_is_operational(FALSE)


/obj/machinery/emp_act(severity)
	. = ..()
	if(!use_power || machine_stat || (. & EMP_PROTECT_SELF))
		return
	use_energy(7.5 KILO JOULES / severity)
	new /obj/effect/temp_visual/emp(loc)

	if(!prob(70/severity))
		return
	if (!length(GLOB.uncommon_roundstart_languages))
		return
	remove_all_languages(source = LANGUAGE_EMP)
	grant_random_uncommon_language(source = LANGUAGE_EMP)

/**
 * Opens the machine.
 *
 * Will update the machine icon and any user interfaces currently open.
 * Arguments:
 * * drop - Boolean. Whether to drop any stored items in the machine. Does not include components.
 * * density - Boolean. Whether to make the object dense when it's open.
 */
/obj/machinery/proc/open_machine(drop = TRUE, density_to_set = FALSE)
	state_open = TRUE
	set_density(density_to_set)
	if(drop)
		dump_inventory_contents()
	update_appearance()

/**
 * Drop every movable atom in the machine's contents list, including any components and circuit.
 */
/obj/machinery/dump_contents()
	// Start by calling the dump_inventory_contents proc. Will allow machines with special contents
	// to handle their dropping.
	dump_inventory_contents()

	// Then we can clean up and drop everything else.
	var/turf/this_turf = get_turf(src)
	for(var/atom/movable/movable_atom in contents)
		movable_atom.forceMove(this_turf)

	// We'll have dropped the occupant, circuit and component parts as part of this.
	set_occupant(null)
	circuit = null
	LAZYCLEARLIST(component_parts)

/**
 * Drop every movable atom in the machine's contents list that is not a component_part.
 *
 * Proc does not drop components and will skip over anything in the component_parts list.
 * Call dump_contents() to drop all contents including components.
 * Arguments:
 * * subset - If this is not null, only atoms that are also contained within the subset list will be dropped.
 */
/obj/machinery/proc/dump_inventory_contents(list/subset = null)
	var/turf/this_turf = get_turf(src)
	for(var/atom/movable/movable_atom in contents)
		//so machines like microwaves dont dump out signalers after cooking
		if(wires && (movable_atom in flatten_list(wires.assemblies)))
			continue

		if(subset && !(movable_atom in subset))
			continue

		if(movable_atom in component_parts)
			continue

		movable_atom.forceMove(this_turf)

		if(occupant == movable_atom)
			set_occupant(null)

/**
 * Puts passed object in to user's hand
 *
 * Puts the passed object in to the users hand if they are adjacent.
 * If the user is not adjacent then place the object on top of the machine.
 *
 * Vars:
 * * object (obj) The object to be moved in to the users hand.
 * * user (mob/living) The user to recive the object
 */
/obj/machinery/proc/try_put_in_hand(obj/object, mob/living/user)
	if(!issilicon(user) && in_range(src, user))
		user.put_in_hands(object)
	else
		object.forceMove(drop_location())

/obj/machinery/proc/can_be_occupant(atom/movable/occupant_atom)
	return occupant_typecache ? is_type_in_typecache(occupant_atom, occupant_typecache) : isliving(occupant_atom)

/obj/machinery/proc/close_machine(atom/movable/target, density_to_set = TRUE)
	state_open = FALSE
	set_density(density_to_set)
	if (!density)
		update_appearance()
		return

	if(!target)
		for(var/atom in loc)
			if (!(can_be_occupant(atom)))
				continue
			var/atom/movable/current_atom = atom
			if(current_atom.has_buckled_mobs())
				continue
			if(isliving(current_atom))
				var/mob/living/current_mob = atom
				if(current_mob.buckled || current_mob.mob_size >= MOB_SIZE_LARGE)
					continue
			target = atom

	var/mob/living/mobtarget = target
	if(target && !target.has_buckled_mobs() && (!isliving(target) || !mobtarget.buckled))
		set_occupant(target)
		target.forceMove(src)
	update_appearance()

///updates the use_power var for this machine and updates its static power usage from its area to reflect the new value
/obj/machinery/proc/update_use_power(new_use_power)
	SHOULD_CALL_PARENT(TRUE)
	if(new_use_power == use_power)
		return FALSE

	unset_static_power()

	var/new_usage = 0
	switch(new_use_power)
		if(IDLE_POWER_USE)
			new_usage = idle_power_usage
		if(ACTIVE_POWER_USE)
			new_usage = active_power_usage

	if(use_power == NO_POWER_USE)
		setup_area_power_relationship()
	else if(new_use_power == NO_POWER_USE)
		remove_area_power_relationship()

	static_power_usage = new_usage

	if(new_usage)
		var/area/our_area = get_area(src)
		our_area?.addStaticPower(new_usage, DYNAMIC_TO_STATIC_CHANNEL(power_channel))

	use_power = new_use_power

	return TRUE

///updates the power channel this machine uses. removes the static power usage from the old channel and readds it to the new channel
/obj/machinery/proc/update_power_channel(new_power_channel)
	SHOULD_CALL_PARENT(TRUE)
	if(new_power_channel == power_channel)
		return FALSE

	var/usage = unset_static_power()

	var/area/our_area = get_area(src)

	if(our_area && usage)
		our_area.addStaticPower(usage, DYNAMIC_TO_STATIC_CHANNEL(new_power_channel))

	power_channel = new_power_channel

	return TRUE

///internal proc that removes all static power usage from the current area
/obj/machinery/proc/unset_static_power()
	SHOULD_NOT_OVERRIDE(TRUE)

	var/old_usage = static_power_usage

	var/area/our_area = get_area(src)

	if(our_area && old_usage)
		our_area.removeStaticPower(old_usage, DYNAMIC_TO_STATIC_CHANNEL(power_channel))
		static_power_usage = 0

	return old_usage

/**
 * sets the power_usage linked to the specified use_power_mode to new_usage
 * e.g. update_mode_power_usage(ACTIVE_POWER_USE, 10) sets active_power_use = 10 and updates its power draw from the machines area if use_power == ACTIVE_POWER_USE
 *
 * Arguments:
 * * use_power_mode - the use_power power mode to change. if IDLE_POWER_USE changes idle_power_usage, ACTIVE_POWER_USE changes active_power_usage
 * * new_usage - the new value to set the specified power mode var to
 */
/obj/machinery/proc/update_mode_power_usage(use_power_mode, new_usage)
	SHOULD_CALL_PARENT(TRUE)
	if(use_power_mode == NO_POWER_USE)
		stack_trace("trying to set the power usage associated with NO_POWER_USE in update_mode_power_usage()!")
		return FALSE

	unset_static_power() //completely remove our static_power_usage from our area, then readd new_usage

	switch(use_power_mode)
		if(IDLE_POWER_USE)
			idle_power_usage = new_usage
		if(ACTIVE_POWER_USE)
			active_power_usage = new_usage

	if(use_power_mode == use_power)
		static_power_usage = new_usage

	var/area/our_area = get_area(src)

	if(our_area)
		our_area.addStaticPower(static_power_usage, DYNAMIC_TO_STATIC_CHANNEL(power_channel))

	return TRUE

///Get a valid powered area to reference for power use, mainly for wall-mounted machinery that isn't always mapped directly in a powered location.
/obj/machinery/proc/get_room_area()
	var/area/machine_area = get_area(src)
	if(isnull(machine_area))
		return null // ??

	// check our own loc first to see if its a powered area
	if(!machine_area.always_unpowered)
		return machine_area

	// loc area wasn't good, checking adjacent wall for a good area to use
	var/turf/mounted_wall = get_step(src, dir)
	if(isclosedturf(mounted_wall))
		var/area/wall_area = get_area(mounted_wall)
		if(!wall_area.always_unpowered)
			return wall_area

	// couldn't find a proper powered area on loc or adjacent wall, defaulting back to loc and blaming mappers
	return machine_area

///makes this machine draw power from its area according to which use_power mode it is set to
/obj/machinery/proc/update_current_power_usage()
	if(static_power_usage)
		unset_static_power()

	var/area/our_area = get_area(src)
	if(!our_area)
		return FALSE

	switch(use_power)
		if(IDLE_POWER_USE)
			static_power_usage = idle_power_usage
		if(ACTIVE_POWER_USE)
			static_power_usage = active_power_usage
		if(NO_POWER_USE)
			return

	if(static_power_usage)
		our_area.addStaticPower(static_power_usage, DYNAMIC_TO_STATIC_CHANNEL(power_channel))

	return TRUE

///Called when we want to change the value of the `is_operational` variable. Boolean.
/obj/machinery/proc/set_is_operational(new_value)
	SHOULD_NOT_OVERRIDE(TRUE)

	if(new_value == is_operational)
		return
	. = is_operational
	is_operational = new_value
	on_set_is_operational(.)


///Called when the value of `is_operational` changes, so we can react to it.
/obj/machinery/proc/on_set_is_operational(old_value)
	PROTECTED_PROC(TRUE)

	return

///Called when we want to change the value of the `panel_open` variable. Boolean.
/obj/machinery/proc/set_panel_open(new_value)
	SHOULD_NOT_OVERRIDE(TRUE)

	if(panel_open == new_value)
		return
	var/old_value = panel_open
	panel_open = new_value
	on_set_panel_open(old_value)

///Called when the value of `panel_open` changes, so we can react to it.
/obj/machinery/proc/on_set_panel_open(old_value)
	PROTECTED_PROC(TRUE)

	return

/// Toggles the panel_open var. Defined for convienience
/obj/machinery/proc/toggle_panel_open()
	SHOULD_NOT_OVERRIDE(TRUE)

	set_panel_open(!panel_open)

/obj/machinery/can_interact(mob/user)
	if(QDELETED(user))
		return FALSE

	if((machine_stat & (NOPOWER|BROKEN)) && !(interaction_flags_machine & INTERACT_MACHINE_OFFLINE)) // Check if the machine is broken, and if we can still interact with it if so
		return FALSE

	if(SEND_SIGNAL(user, COMSIG_TRY_USE_MACHINE, src) & COMPONENT_CANT_USE_MACHINE_INTERACT)
		return FALSE

	if(isAdminGhostAI(user))
		return TRUE //the Gods have unlimited power and do not care for things such as range or blindness

	if(!isliving(user))
		return FALSE //no ghosts allowed, sorry

	if(!HAS_SILICON_ACCESS(user) && !user.can_hold_items())
		return FALSE //spiders gtfo

	if(HAS_SILICON_ACCESS(user)) // If we are a silicon, make sure the machine allows silicons to interact with it
		if(!(interaction_flags_machine & INTERACT_MACHINE_ALLOW_SILICON))
			return FALSE

		if(panel_open && !(interaction_flags_machine & INTERACT_MACHINE_OPEN) && !(interaction_flags_machine & INTERACT_MACHINE_OPEN_SILICON))
			return FALSE

		return user.can_interact_with(src) //AIs don't care about petty mortal concerns like needing to be next to a machine to use it, but borgs do care somewhat

	. = ..()
	if(!.)
		return FALSE

	if((interaction_flags_machine & INTERACT_MACHINE_REQUIRES_SIGHT) && user.is_blind())
		to_chat(user, span_warning("This machine requires sight to use."))
		return FALSE

	// machines have their own lit up display screens and LED buttons so we don't need to check for light
	if((interaction_flags_machine & INTERACT_MACHINE_REQUIRES_LITERACY) && !user.can_read(src, READING_CHECK_LITERACY))
		return FALSE

	if(panel_open && !(interaction_flags_machine & INTERACT_MACHINE_OPEN))
		return FALSE

	if(interaction_flags_machine & INTERACT_MACHINE_REQUIRES_SILICON) //if the user was a silicon, we'd have returned out earlier, so the user must not be a silicon
		return FALSE

	if(interaction_flags_machine & INTERACT_MACHINE_REQUIRES_STANDING)
		var/mob/living/living_user = user
		if(!(living_user.mobility_flags & MOBILITY_MOVE))
			return FALSE

	return TRUE // If we passed all of those checks, woohoo! We can interact with this machine.

/**
 * Checks for NAP non aggression principle, an anarcho capitalist event triggered by admins
 * where using machines cost money
 */
/obj/machinery/proc/check_nap_violations()
	PROTECTED_PROC(TRUE)
	SHOULD_NOT_OVERRIDE(TRUE)

	if(!SSeconomy.full_ancap)
		return TRUE
	if(!occupant || state_open)
		return TRUE
	var/mob/living/occupant_mob = occupant
	var/obj/item/card/id/occupant_id = occupant_mob.get_idcard(TRUE)
	if(!occupant_id)
		say("Customer NAP Violation: No ID card found.")
		nap_violation(occupant_mob)
		return FALSE
	var/datum/bank_account/insurance = occupant_id.registered_account
	if(!insurance)
		say("Customer NAP Violation: No bank account found.")
		nap_violation(occupant_mob)
		return FALSE
	if(!insurance.adjust_money(-fair_market_price))
		say("Customer NAP Violation: Unable to pay.")
		nap_violation(occupant_mob)
		return FALSE
	var/datum/bank_account/department_account = SSeconomy.get_dep_account(payment_department)
	if(department_account)
		department_account.adjust_money(fair_market_price)
	return TRUE

/**
 * Actions to take in case of NAP violation
 * Arguments
 *
 * * mob/violator - the mob who violated the NAP aggrement
 */
/obj/machinery/proc/nap_violation(mob/violator)
	PROTECTED_PROC(TRUE)

	return

////////////////////////////////////////////////////////////////////////////////////////////

//Return a non FALSE value to interrupt attack_hand propagation to subtypes.
/obj/machinery/interact(mob/user)
	update_last_used(user)
	return ..()

/obj/machinery/ui_act(action, list/params, datum/tgui/ui, datum/ui_state/state)
	var/mob/user = ui.user
	add_fingerprint(user)
	update_last_used(user)
	if(isAI(user) && !GLOB.cameranet.checkTurfVis(get_turf(src))) //We check if they're an AI specifically here, so borgs/adminghosts/human wand can still access off-camera stuff.
		to_chat(user, span_warning("You can no longer connect to this device!"))
		return FALSE
	return ..()

/obj/machinery/Topic(href, href_list)
	..()
	if(!can_interact(usr))
		return TRUE
	if(!usr.can_perform_action(src, ALLOW_SILICON_REACH))
		return TRUE
	add_fingerprint(usr)
	update_last_used(usr)
	return FALSE

////////////////////////////////////////////////////////////////////////////////////////////

/obj/machinery/attack_paw(mob/living/user, list/modifiers)
	if(!user.combat_mode)
		return attack_hand(user)

	user.changeNext_move(CLICK_CD_MELEE)
	user.do_attack_animation(src, ATTACK_EFFECT_PUNCH)
	var/damage = take_damage(damage_amount = 4, damage_type = BRUTE, damage_flag = MELEE, sound_effect = TRUE, attack_dir = get_dir(user, src))

	var/hit_with_what_noun = "paws"
	var/obj/item/bodypart/arm/arm = user.get_active_hand()
	if(!isnull(arm))
		hit_with_what_noun = arm.appendage_noun // hit with "their hand"
		if(user.usable_hands > 1)
			hit_with_what_noun += plural_s(hit_with_what_noun) // hit with "their hands"

	user.visible_message(
		span_danger("[user] smashes [src] with [user.p_their()] [hit_with_what_noun][damage ? "." : ", [no_damage_feedback]!"]"),
		span_danger("You smash [src] with your [hit_with_what_noun][damage ? "." : ", [no_damage_feedback]!"]"),
		span_hear("You hear a [damage ? "smash" : "thud"]."),
		COMBAT_MESSAGE_RANGE,
	)
	return TRUE

/obj/machinery/attack_hulk(mob/living/carbon/user)
	. = ..()
	var/obj/item/bodypart/arm = user.get_active_hand()
	if(!arm || arm.bodypart_disabled)
		return
	user.apply_damage(damage_deflection * 0.1, BRUTE, arm, wound_bonus = CANT_WOUND)

/obj/machinery/attack_robot(mob/user)
	if(!(interaction_flags_machine & INTERACT_MACHINE_ALLOW_SILICON) && !isAdminGhostAI(user))
		return FALSE

	if(!Adjacent(user) || !can_buckle || !has_buckled_mobs()) //so that borgs (but not AIs, sadly (perhaps in a future PR?)) can unbuckle people from machines
		return _try_interact(user)

	if(length(buckled_mobs) <= 1)
		if(user_unbuckle_mob(buckled_mobs[1],user))
			return TRUE

	var/unbuckled = tgui_input_list(user, "Who do you wish to unbuckle?", "Unbuckle", sort_names(buckled_mobs))
	if(isnull(unbuckled))
		return FALSE
	if(user_unbuckle_mob(unbuckled,user))
		return TRUE

	return _try_interact(user)

/obj/machinery/attack_ai(mob/user)
	if(!(interaction_flags_machine & INTERACT_MACHINE_ALLOW_SILICON) && !isAdminGhostAI(user))
		return FALSE
	if(!(ROLE_SYNDICATE in user.faction))
		if((ACCESS_SYNDICATE in req_access) || (ACCESS_SYNDICATE_LEADER in req_access) || (ACCESS_SYNDICATE in req_one_access) || (ACCESS_SYNDICATE_LEADER in req_one_access))
			return FALSE
		if((onSyndieBase() && loc != user))
			return FALSE
	if(iscyborg(user))// For some reason attack_robot doesn't work
		return attack_robot(user)
	return _try_interact(user)

/obj/machinery/attackby(obj/item/weapon, mob/user, params)
	. = ..()
	if(.)
		return
	update_last_used(user)

/obj/machinery/attackby_secondary(obj/item/weapon, mob/user, params)
	. = ..()
	if(.)
		return
	update_last_used(user)

/obj/machinery/base_item_interaction(mob/living/user, obj/item/tool, list/modifiers)
	if(SEND_SIGNAL(user, COMSIG_TRY_USE_MACHINE, src) & COMPONENT_CANT_USE_MACHINE_TOOLS)
		return ITEM_INTERACT_BLOCKING

	//takes priority in case material container or other atoms that hook onto item interaction signals won't give it a chance
	if(istype(tool, /obj/item/storage/part_replacer))
		update_last_used(user)
		return tool.interact_with_atom(src, user, modifiers)

	. = ..()
	if(.)
		update_last_used(user)

/obj/machinery/_try_interact(mob/user)
	if((interaction_flags_machine & INTERACT_MACHINE_WIRES_IF_OPEN) && panel_open && (attempt_wire_interaction(user) == WIRE_INTERACTION_BLOCK))
		return TRUE
	if(SEND_SIGNAL(user, COMSIG_TRY_USE_MACHINE, src) & COMPONENT_CANT_USE_MACHINE_INTERACT)
		return TRUE
	return ..()

/obj/machinery/on_craft_completion(list/components, datum/crafting_recipe/current_recipe, atom/crafter)
	. = ..()
	RefreshParts()

/obj/machinery/proc/RefreshParts()
	SHOULD_CALL_PARENT(TRUE)
	//reset to baseline
	idle_power_usage = initial(idle_power_usage)
	active_power_usage = initial(active_power_usage)
	if(!component_parts || !component_parts.len)
		return
	var/parts_energy_rating = 0

	for(var/datum/stock_part/part in component_parts)
		parts_energy_rating += part.energy_rating()

	for(var/obj/item/stock_parts/part in component_parts)
		parts_energy_rating += part.energy_rating

	idle_power_usage = initial(idle_power_usage) * (1 + parts_energy_rating)
	active_power_usage = initial(active_power_usage) * (1 + parts_energy_rating)
	update_current_power_usage()
	SEND_SIGNAL(src, COMSIG_MACHINERY_REFRESH_PARTS)

/obj/machinery/proc/default_pry_open(obj/item/crowbar, close_after_pry = FALSE, open_density = FALSE, closed_density = TRUE)
	PROTECTED_PROC(TRUE)

	. = !(state_open || panel_open || is_operational) && crowbar.tool_behaviour == TOOL_CROWBAR
	if(!.)
		return
	crowbar.play_tool_sound(src, 50)
	visible_message(span_notice("[usr] pries open \the [src]."), span_notice("You pry open \the [src]."))
	open_machine(density_to_set = open_density)
	if (close_after_pry) //Should it immediately close after prying? (If not, it must be closed elsewhere)
		close_machine(density_to_set = closed_density)

/obj/machinery/proc/default_deconstruction_crowbar(obj/item/crowbar, ignore_panel = 0, custom_deconstruct = FALSE)
	PROTECTED_PROC(TRUE)

	. = (panel_open || ignore_panel) && crowbar.tool_behaviour == TOOL_CROWBAR
	if(!. || custom_deconstruct)
		return
	crowbar.play_tool_sound(src, 50)
	deconstruct(TRUE)

/obj/machinery/handle_deconstruct(disassembled = TRUE)
	SHOULD_NOT_OVERRIDE(TRUE)

	if(obj_flags & NO_DEBRIS_AFTER_DECONSTRUCTION)
		dump_inventory_contents() //drop stuff we consider important
		return //Just delete us, no need to call anything else.

	on_deconstruction(disassembled)

	if(circuit)
		spawn_frame(disassembled)

	if(!LAZYLEN(component_parts))
		dump_contents() //drop everything inside us
		return //we don't have any parts.

	for(var/part in component_parts)
		if(istype(part, /datum/stock_part))
			var/datum/stock_part/datum_part = part
			new datum_part.physical_object_type(loc)
		else
			var/obj/item/obj_part = part
			component_parts -= part
			obj_part.forceMove(loc)
			if(istype(obj_part, /obj/item/circuitboard/machine))
				var/obj/item/circuitboard/machine/board = obj_part
				for(var/component in board.req_components) //loop through all stack components and spawn them
					if(!ispath(component, /obj/item/stack))
						continue
					var/obj/item/stack/stack_path = component
					new stack_path(loc, board.req_components[component])
	LAZYCLEARLIST(component_parts)

	//drop everything inside us. we do this last to give machines a chance
	//to handle their contents before we dump them
	dump_contents()

/**
 * Spawns a frame where this machine is. If the machine was not disassmbled, the
 * frame is spawned damaged. If the frame couldn't exist on this turf, it's smashed
 * down to metal sheets.
 *
 * Arguments:
 * * disassembled - If FALSE, the machine was destroyed instead of disassembled and the frame spawns at reduced integrity.
 */
/obj/machinery/proc/spawn_frame(disassembled)
	var/obj/structure/frame/machine/new_frame = new /obj/structure/frame/machine(loc)

	new_frame.state = FRAME_STATE_WIRED

	// If the new frame shouldn't be able to fit here due to the turf being blocked, spawn the frame deconstructed.
	if(isturf(loc))
		var/turf/machine_turf = loc
		// We're spawning a frame before this machine is qdeleted, so we want to ignore it. We've also just spawned a new frame, so ignore that too.
		if(machine_turf.is_blocked_turf(TRUE, source_atom = new_frame, ignore_atoms = list(src)))
			new_frame.deconstruct(disassembled)
			return

	new_frame.update_appearance(UPDATE_ICON_STATE)
	. = new_frame
	new_frame.set_anchored(anchored)
	if(!disassembled)
		new_frame.update_integrity(new_frame.max_integrity * 0.5) //the frame is already half broken
	transfer_fingerprints_to(new_frame)


/obj/machinery/atom_break(damage_flag)
	. = ..()
	if(!(machine_stat & BROKEN))
		set_machine_stat(machine_stat | BROKEN)
		SEND_SIGNAL(src, COMSIG_MACHINERY_BROKEN, damage_flag)
		update_appearance()
		return TRUE

/obj/machinery/contents_explosion(severity, target)
	if(!occupant)
		return

	switch(severity)
		if(EXPLODE_DEVASTATE)
			SSexplosions.high_mov_atom += occupant
		if(EXPLODE_HEAVY)
			SSexplosions.med_mov_atom += occupant
		if(EXPLODE_LIGHT)
			SSexplosions.low_mov_atom += occupant

/obj/machinery/Exited(atom/movable/gone, direction)
	. = ..()
	if(gone == occupant)
		set_occupant(null)
		update_appearance()

	// The circuit should also be in component parts, so don't early return.
	if(gone == circuit)
		circuit = null
	if((gone in component_parts) && !QDELETED(src))
		component_parts -= gone
		// It would be unusual for a component_part to be qdel'd ordinarily.
		deconstruct(FALSE)

/**
 * This should be called before mass qdeling components to make space for replacements.
 * If not done, things will go awry as Exited() destroys the machine when it detects
 * even a single component exiting the atom.
 */
/obj/machinery/proc/clear_components()
	if(!component_parts)
		return
	var/list/old_components = component_parts
	circuit = null
	component_parts = null
	for(var/atom/atom_part in old_components)
		qdel(atom_part)

/obj/machinery/proc/default_deconstruction_screwdriver(mob/user, icon_state_open, icon_state_closed, obj/item/screwdriver)
	if(screwdriver.tool_behaviour != TOOL_SCREWDRIVER)
		return FALSE

	screwdriver.play_tool_sound(src, 50)
	toggle_panel_open()
	if(panel_open)
		icon_state = icon_state_open
		to_chat(user, span_notice("You open the maintenance hatch of [src]."))
	else
		icon_state = icon_state_closed
		to_chat(user, span_notice("You close the maintenance hatch of [src]."))
	return TRUE

/obj/machinery/proc/default_change_direction_wrench(mob/user, obj/item/wrench)
	if(!panel_open || wrench.tool_behaviour != TOOL_WRENCH)
		return FALSE

	wrench.play_tool_sound(src, 50)
	setDir(turn(dir,-90))
	to_chat(user, span_notice("You rotate [src]."))
	SEND_SIGNAL(src, COMSIG_MACHINERY_DEFAULT_ROTATE_WRENCH, user, wrench)
	return TRUE

/obj/machinery/proc/exchange_parts(mob/user, obj/item/storage/part_replacer/replacer_tool)
	if(!istype(replacer_tool) || !component_parts)
		return FALSE

	var/works_from_distance = istype(replacer_tool, /obj/item/storage/part_replacer/bluespace)
	if(!panel_open && !works_from_distance)
		to_chat(user, display_parts(user))
		return FALSE

	var/obj/item/circuitboard/machine/machine_board = locate(/obj/item/circuitboard/machine) in component_parts
	if(works_from_distance)
		to_chat(user, display_parts(user))
	if(!machine_board)
		return FALSE
	/**
	 * sorting is very important especially because we are breaking out when required part is found in the inner for loop
	 * if the rped first picked up a tier 3 part AND THEN a tier 4 part
	 * tier 3 would be installed and the loop would break and check for the next required component thus
	 * completly ignoring the tier 4 component inside
	 * we also ignore stack components inside the RPED cause we dont exchange that
	 */
	var/shouldplaysound = FALSE
	var/list/part_list = replacer_tool.get_sorted_parts(ignore_stacks = TRUE)
	if(!part_list.len)
		return FALSE
	for(var/primary_part_base as anything in component_parts)
		//we exchanged all we could time to bail
		if(!part_list.len)
			break

		var/current_rating
		var/required_type

		//we dont exchange circuitboards cause thats dumb
		if(istype(primary_part_base, /obj/item/circuitboard))
			continue
		else if(istype(primary_part_base, /datum/stock_part))
			var/datum/stock_part/primary_stock_part = primary_part_base
			current_rating = primary_stock_part.tier
			required_type = primary_stock_part.physical_object_base_type
		else
			var/obj/item/primary_stock_part_item = primary_part_base
			current_rating = primary_stock_part_item.get_part_rating()
			for(var/design_type in machine_board.req_components)
				if(ispath(primary_stock_part_item.type, design_type))
					required_type = design_type
					break

		for(var/obj/item/secondary_part in part_list)
			if(!istype(secondary_part, required_type))
				continue
			// If it's a corrupt or rigged cell, attempting to send it through Bluespace could have unforeseen consequences.
			if(istype(secondary_part, /obj/item/stock_parts/power_store/cell) && works_from_distance)
				var/obj/item/stock_parts/power_store/cell/checked_cell = secondary_part
				// If it's rigged or corrupted, max the charge. Then explode it.
				if(checked_cell.rigged || checked_cell.corrupted)
					checked_cell.charge = checked_cell.maxcharge
					checked_cell.explode()
					break
			if(secondary_part.get_part_rating() > current_rating)
				//store name of part incase we qdel it below
				var/secondary_part_name = secondary_part.name
				if(replacer_tool.atom_storage.attempt_remove(secondary_part, src))
					if (istype(primary_part_base, /datum/stock_part))
						var/stock_part_datum = GLOB.stock_part_datums_per_object[secondary_part.type]
						if (isnull(stock_part_datum))
							CRASH("[secondary_part] ([secondary_part.type]) did not have a stock part datum (was trying to find [primary_part_base])")
						component_parts += stock_part_datum
						part_list -= secondary_part //have to manually remove cause we are no longer refering replacer_tool.contents
						qdel(secondary_part)
					else
						component_parts += secondary_part
						secondary_part.forceMove(src)
						part_list -= secondary_part //have to manually remove cause we are no longer refering replacer_tool.contents

				component_parts -= primary_part_base

				var/obj/physical_part
				if (istype(primary_part_base, /datum/stock_part))
					var/datum/stock_part/stock_part_datum = primary_part_base
					var/physical_object_type = stock_part_datum.physical_object_type
					physical_part = new physical_object_type
				else
					physical_part = primary_part_base

				replacer_tool.atom_storage.attempt_insert(physical_part, user, TRUE, force = STORAGE_SOFT_LOCKED)
				to_chat(user, span_notice("[capitalize(physical_part.name)] replaced with [secondary_part_name]."))
				shouldplaysound = TRUE //Only play the sound when parts are actually replaced!
				break

	RefreshParts()

	if(shouldplaysound)
		replacer_tool.play_rped_sound()
	return TRUE

/obj/machinery/proc/display_parts(mob/user)
	var/list/part_count = list()

	for(var/component_part in component_parts)
		var/obj/item/component_ref

		if (istype(component_part, /datum/stock_part))
			var/datum/stock_part/stock_part = component_part
			component_ref = stock_part.physical_object_reference
		else
			component_ref = component_part
			for(var/obj/item/counted_part in part_count)
				//e.g. 2 beakers though they have the same type are still 2 different objects so component_ref wont keep them unique so we look for that type ourselves and increment it
				if(istype(counted_part, component_ref.type))
					part_count[counted_part]++
					component_ref = null
					break
			//looks like we already counted an type of this obj reference, time to bail
			if(!component_ref)
				continue

		if(part_count[component_ref])
			part_count[component_ref]++
			continue
		part_count[component_ref] = 1

		// we infer the required stack stuff inside the machine from the circuitboards requested components
		if(istype(component_ref, /obj/item/circuitboard/machine))
			var/obj/item/circuitboard/machine/board = component_ref
			for(var/component as anything in board.req_components)
				if(!ispath(component, /obj/item/stack))
					continue
				part_count[component] = board.req_components[component]


	var/text = span_notice("It contains the following parts:")
	for(var/component_part in part_count)
		var/part_name
		var/icon/html_icon
		var/icon_state
		//infer name & icon of part. stacks are just type paths so we have to get their initial values
		if(ispath(component_part, /obj/item/stack))
			var/obj/item/stack/stack_ref = component_part
			part_name = initial(stack_ref.singular_name)
			html_icon = initial(stack_ref.icon)
			icon_state = initial(stack_ref.icon_state)
		else
			var/obj/item/part = component_part
			part_name = part.name
			html_icon = part.icon
			icon_state = part.icon_state
		//merge icon & name into text
		text += span_notice("[icon2html(html_icon, user, icon_state)] [part_count[component_part]] [part_name]\s.")

	return text

/obj/machinery/examine(mob/user)
	. = ..()
	if(machine_stat & BROKEN)
		. += span_notice("It looks broken and non-functional.")
	if(!(resistance_flags & INDESTRUCTIBLE))
		var/healthpercent = (atom_integrity/max_integrity) * 100
		switch(healthpercent)
			if(50 to 99)
				. += "It looks slightly damaged."
			if(25 to 50)
				. += "It appears heavily damaged."
			if(0 to 25)
				. += span_warning("It's falling apart!")

/obj/machinery/examine_descriptor(mob/user)
	return "machine"

/obj/machinery/examine_more(mob/user)
	. = ..()
	if(HAS_TRAIT(user, TRAIT_RESEARCH_SCANNER) && component_parts)
		. += display_parts(user, TRUE)

//called on machinery construction (i.e from frame to machinery) but not on initialization
/obj/machinery/proc/on_construction(mob/user)
	return

/**
 * called on deconstruction before the final deletion
 * Arguments
 *
 * * disassembled - if TRUE means we used tools to deconstruct it, FALSE means it got destroyed by other means
 */
/obj/machinery/proc/on_deconstruction(disassembled)
	PROTECTED_PROC(TRUE)
	return

/obj/machinery/zap_act(power, zap_flags)
	if(prob(85) && (zap_flags & ZAP_MACHINE_EXPLOSIVE) && !(resistance_flags & INDESTRUCTIBLE))
		explosion(src, devastation_range = 1, heavy_impact_range = 2, light_impact_range = 4, flame_range = 2, adminlog = TRUE, smoke = FALSE)
	else if(zap_flags & ZAP_OBJ_DAMAGE)
		take_damage(power * 2.5e-4, BURN, ENERGY)
		if(prob(40))
			emp_act(EMP_LIGHT)
		power -= power * 5e-4
	return ..()

/obj/machinery/proc/adjust_item_drop_location(atom/movable/dropped_atom) // Adjust item drop location to a 3x3 grid inside the tile, returns slot id from 0 to 8
	var/md5 = md5(dropped_atom.name) // Oh, and it's deterministic too. A specific item will always drop from the same slot.
	for (var/i in 1 to 32)
		. += hex2num(md5[i])
	. = . % 9
	dropped_atom.pixel_x = -8 + ((.%3)*8)
	dropped_atom.pixel_y = -8 + (round( . / 3)*8)

/obj/machinery/rust_heretic_act()
	take_damage(500, BRUTE, MELEE, 1)

/obj/machinery/vv_edit_var(vname, vval)
	if(vname == NAMEOF(src, occupant))
		set_occupant(vval)
		datum_flags |= DF_VAR_EDITED
		return TRUE
	if(vname == NAMEOF(src, machine_stat))
		set_machine_stat(vval)
		datum_flags |= DF_VAR_EDITED
		return TRUE

	return ..()

/**
 * Alerts the AI that a hack is in progress.
 *
 * Sends all AIs a message that a hack is occurring.  Specifically used for space ninja tampering as this proc was originally in the ninja files.
 * However, the proc may also be used elsewhere.
 */
/obj/machinery/proc/AI_notify_hack()
	var/alertstr = span_userdanger("Network Alert: Hacking attempt detected[get_area(src)?" in [get_area_name(src, TRUE)]":". Unable to pinpoint location"].")
	for(var/mob/living/silicon/ai/AI in GLOB.player_list)
		to_chat(AI, alertstr)

/obj/machinery/proc/update_last_used(mob/user)
	if(isliving(user))
		last_used_time = world.time
		last_user_mobtype = user.type

/// Called if this machine is supposed to be a sabotage machine objective.
/obj/machinery/proc/add_as_sabotage_target()
	return
