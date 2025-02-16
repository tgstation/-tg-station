/*
	New methods:
	pulse - sends a pulse into a wire for hacking purposes
	cut - cuts a wire and makes any necessary state changes
	mend - mends a wire and makes any necessary state changes
	canAIControl - 1 if the AI can control the airlock, 0 if not (then check canAIHack to see if it can hack in)
	canAIHack - 1 if the AI can hack into the airlock to recover control, 0 if not. Also returns 0 if the AI does not *need* to hack it.
	hasPower - 1 if the main or backup power are functioning, 0 if not.
	requiresIDs - 1 if the airlock is requiring IDs, 0 if not
	isAllPowerCut - 1 if the main and backup power both have cut wires.
	regainMainPower - handles the effect of main power coming back on.
	loseMainPower - handles the effect of main power going offline. Usually (if one isn't already running) spawn a thread to count down how long it will be offline - counting down won't happen if main power was completely cut along with backup power, though, the thread will just sleep.
	loseBackupPower - handles the effect of backup power going offline.
	regainBackupPower - handles the effect of main power coming back on.
	shock - has a chance of electrocuting its target.
	isSecure - 1 if there some form of shielding in front of the airlock wires.
*/

/// Overlay cache.  Why isn't this just in /obj/machinery/door/airlock?  Because its used just a
/// tiny bit in door_assembly.dm  Refactored so you don't have to make a null copy of airlock
/// to get to the damn thing
/// Someone, for the love of god, profile this.  Is there a reason to cache mutable_appearance
/// if so, why are we JUST doing the airlocks when we can put this in mutable_appearance.dm for
/// everything
/proc/get_airlock_overlay(icon_state, icon_file, atom/offset_spokesman, em_block)
	var/static/list/airlock_overlays = list()

	var/base_icon_key = "[icon_state][REF(icon_file)]"
	if(!(. = airlock_overlays[base_icon_key]))
		. = airlock_overlays[base_icon_key] = mutable_appearance(icon_file, icon_state)
	if(isnull(em_block))
		return

	var/turf/our_turf = get_turf(offset_spokesman)

	var/em_block_key = "[base_icon_key][em_block][GET_TURF_PLANE_OFFSET(our_turf)]"
	var/mutable_appearance/em_blocker = airlock_overlays[em_block_key]
	if(!em_blocker)
		em_blocker = airlock_overlays[em_block_key] = mutable_appearance(icon_file, icon_state, offset_spokesman = offset_spokesman, plane = EMISSIVE_PLANE, appearance_flags = EMISSIVE_APPEARANCE_FLAGS)
		em_blocker.color = em_block ? GLOB.em_block_color : GLOB.emissive_color

	return list(., em_blocker)

// Before you say this is a bad implmentation, look at what it was before then ask yourself
// "Would this be better with a global var"

// Wires for the airlock are located in the datum folder, inside the wires datum folder.

#define AIRLOCK_FRAME_CLOSED "closed"
#define AIRLOCK_FRAME_CLOSING "closing"
#define AIRLOCK_FRAME_OPEN "open"
#define AIRLOCK_FRAME_OPENING "opening"

#define AIRLOCK_SECURITY_NONE 0 //Normal airlock //Wires are not secured
#define AIRLOCK_SECURITY_IRON 1 //Medium security airlock //There is a simple iron plate over wires (use welder)
#define AIRLOCK_SECURITY_PLASTEEL_I_S 2 //Sliced inner plating (use crowbar), jumps to 0
#define AIRLOCK_SECURITY_PLASTEEL_I 3 //Removed outer plating, second layer here (use welder)
#define AIRLOCK_SECURITY_PLASTEEL_O_S 4 //Sliced outer plating (use crowbar)
#define AIRLOCK_SECURITY_PLASTEEL_O 5 //There is first layer of plasteel (use welder)
#define AIRLOCK_SECURITY_PLASTEEL 6 //Max security airlock //Fully secured wires (use wirecutters to remove grille, that is electrified)

#define AIRLOCK_INTEGRITY_N  300 // Normal airlock integrity
#define AIRLOCK_INTEGRITY_MULTIPLIER 1.5 // How much reinforced doors health increases
/// How much extra health airlocks get when braced with a seal
#define AIRLOCK_SEAL_MULTIPLIER  2
#define AIRLOCK_DAMAGE_DEFLECTION_N  21  // Normal airlock damage deflection
#define AIRLOCK_DAMAGE_DEFLECTION_R  30  // Reinforced airlock damage deflection

#define AIRLOCK_DENY_ANIMATION_TIME (0.6 SECONDS) /// The amount of time for the airlock deny animation to show

#define DOOR_CLOSE_WAIT 60 /// Time before a door closes, if not overridden

#define DOOR_VISION_DISTANCE 11 ///The maximum distance a door will see out to

/obj/machinery/door/airlock
	name = "Airlock"
	icon = 'icons/obj/doors/airlocks/station/public.dmi'
	icon_state = "closed"
	max_integrity = 300
	var/normal_integrity = AIRLOCK_INTEGRITY_N
	integrity_failure = 0.25
	damage_deflection = AIRLOCK_DAMAGE_DEFLECTION_N
	autoclose = TRUE
	explosion_block = 1
	hud_possible = list(DIAG_AIRLOCK_HUD)
	smoothing_groups = SMOOTH_GROUP_AIRLOCK

	interaction_flags_machine = INTERACT_MACHINE_WIRES_IF_OPEN | INTERACT_MACHINE_ALLOW_SILICON | INTERACT_MACHINE_OPEN_SILICON | INTERACT_MACHINE_OPEN
	interaction_flags_click = ALLOW_SILICON_REACH
	blocks_emissive = EMISSIVE_BLOCK_NONE // Custom emissive blocker. We don't want the normal behavior.

	///The type of door frame to drop during deconstruction
	var/assemblytype = /obj/structure/door_assembly
	/// How much are wires secured
	var/security_level = 0
	/// If 1, AI control is disabled until the AI hacks back in and disables the lock. If 2, the AI has bypassed the lock. If -1, the control is enabled but the AI had bypassed it earlier, so if it is disabled again the AI would have no trouble getting back in.
	var/aiControlDisabled = AI_WIRE_NORMAL
	/// If true, this door can't be hacked by the AI
	var/hackProof = FALSE
	/// Timer id, active when we are actively waiting for the main power to be restored
	var/main_power_timer = 0
	/// Paired with main_power_timer. Records its remaining time when something happens to interrupt power regen
	var/main_power_time
	/// Timer id, active when we are actively waiting for the backup power to be restored
	var/backup_power_timer = 0
	/// Paired with backup_power_timer. Records its remaining time when something happens to interrupt power regen
	var/backup_power_time
	/// Bolt lights show by default
	var/lights = TRUE
	var/aiDisabledIdScanner = FALSE
	var/aiHacking = FALSE
	/// Cyclelinking for airlocks that aren't on the same x or y coord as the target.
	var/closeOtherId
	var/obj/machinery/door/airlock/closeOther
	var/list/obj/machinery/door/airlock/close_others = list()
	var/obj/item/electronics/airlock/electronics
	COOLDOWN_DECLARE(shockCooldown)
	/// Any papers pinned to the airlock
	var/obj/item/note
	/// The seal on the airlock
	var/obj/item/seal
	var/abandoned = FALSE
	/// Controls if the door closes quickly or not. FALSE = the door autocloses in 1.5 seconds, TRUE = 8 seconds - see autoclose_in()
	var/normalspeed = TRUE
	var/cutAiWire = FALSE
	var/autoname = FALSE
	var/doorOpen = 'sound/machines/airlock/airlock.ogg'
	var/doorClose = 'sound/machines/airlock/airlockclose.ogg'
	var/doorDeni = 'sound/machines/beep/deniedbeep.ogg' // i'm thinkin' Deni's
	var/boltUp = 'sound/machines/airlock/boltsup.ogg'
	var/boltDown = 'sound/machines/airlock/boltsdown.ogg'
	var/noPower = 'sound/machines/airlock/doorclick.ogg'
	/// What airlock assembly mineral plating was applied to
	var/previous_airlock = /obj/structure/door_assembly
	/// Material of inner filling; if its an airlock with glass, this should be set to "glass"
	var/airlock_material
	var/overlays_file = 'icons/obj/doors/airlocks/station/overlays.dmi'
	/// Used for papers and photos pinned to the airlock
	var/note_overlay_file = 'icons/obj/doors/airlocks/station/overlays.dmi'

	/// Airlock pump that overrides airlock controlls when set up for cycling
	var/obj/machinery/atmospherics/components/unary/airlock_pump/cycle_pump

	var/cyclelinkeddir = 0
	var/obj/machinery/door/airlock/cyclelinkedairlock
	var/shuttledocked = 0
	/// TRUE means the door will automatically close the next time it's opened.
	var/delayed_close_requested = FALSE
	/// TRUE means density will be set as soon as the door begins to close
	var/air_tight = FALSE
	var/prying_so_hard = FALSE
	/// Logging for door electrification.
	var/shockedby
	/// How many seconds remain until the door is no longer electrified. -1/MACHINE_ELECTRIFIED_PERMANENT = permanently electrified until someone fixes it.
	var/secondsElectrified = MACHINE_NOT_ELECTRIFIED

	flags_1 = HTML_USE_INITAL_ICON_1
	rad_insulation = RAD_MEDIUM_INSULATION

/obj/machinery/door/airlock/Initialize(mapload)
	. = ..()

	set_wires(get_wires())
	if(glass)
		airlock_material = "glass"
	if(security_level > AIRLOCK_SECURITY_IRON)
		atom_integrity = normal_integrity * AIRLOCK_INTEGRITY_MULTIPLIER
		max_integrity = normal_integrity * AIRLOCK_INTEGRITY_MULTIPLIER
	else
		atom_integrity = normal_integrity
		max_integrity = normal_integrity
	if(damage_deflection == AIRLOCK_DAMAGE_DEFLECTION_N && security_level > AIRLOCK_SECURITY_IRON)
		damage_deflection = AIRLOCK_DAMAGE_DEFLECTION_R

	prepare_huds()
	for(var/datum/atom_hud/data/diagnostic/diag_hud in GLOB.huds)
		diag_hud.add_atom_to_hud(src)

	diag_hud_set_electrified()

	// Click on the floor to close airlocks
	AddComponent(/datum/component/redirect_attack_hand_from_turf)

	AddElement(/datum/element/nav_computer_icon, 'icons/effects/nav_computer_indicators.dmi', "airlock", TRUE)

	RegisterSignal(src, COMSIG_MACHINERY_BROKEN, PROC_REF(on_break))

	RegisterSignal(SSdcs, COMSIG_GLOB_GREY_TIDE, PROC_REF(grey_tide))

/obj/machinery/door/airlock/proc/grey_tide(datum/source, list/grey_tide_areas)
	SIGNAL_HANDLER

	if(!is_station_level(z) || critical_machine)
		return //Skip doors in critical positions, such as the SM chamber.

	for(var/area_type in grey_tide_areas)
		if(!istype(get_area(src), area_type))
			continue
		INVOKE_ASYNC(src, PROC_REF(prison_open)) //Sleep gets called further down in open(), so we have to invoke async

/obj/machinery/door/airlock/connect_to_shuttle(mapload, obj/docking_port/mobile/port, obj/docking_port/stationary/dock)
	if(id_tag)
		id_tag = "[port.shuttle_id]_[id_tag]"

/obj/machinery/door/airlock/proc/update_other_id()
	for(var/obj/machinery/door/airlock/Airlock as anything in SSmachines.get_machines_by_type_and_subtypes(/obj/machinery/door/airlock))
		if(Airlock.closeOtherId == closeOtherId && Airlock != src)
			if(!(Airlock in close_others))
				close_others += Airlock
			if(!(src in Airlock.close_others))
				Airlock.close_others += src

/obj/machinery/door/airlock/proc/cyclelinkairlock()
	if (cyclelinkedairlock)
		cyclelinkedairlock.cyclelinkedairlock = null
		cyclelinkedairlock = null
	if (!cyclelinkeddir)
		return
	var/limit = DOOR_VISION_DISTANCE
	var/turf/T = get_turf(src)
	var/obj/machinery/door/airlock/FoundDoor
	do
		T = get_step(T, cyclelinkeddir)
		FoundDoor = locate() in T
		if (FoundDoor && FoundDoor.cyclelinkeddir != get_dir(FoundDoor, src))
			FoundDoor = null
		limit--
	while(!FoundDoor && limit)
	if (!FoundDoor)
		log_mapping("[src] at [AREACOORD(src)] failed to find a valid airlock to cyclelink with!")
		return
	FoundDoor.cyclelinkedairlock = src
	cyclelinkedairlock = FoundDoor

/obj/machinery/door/airlock/vv_edit_var(var_name, vval)
	. = ..()
	switch (var_name)
		if (NAMEOF(src, cyclelinkeddir))
			cyclelinkairlock()
		if (NAMEOF(src, secondsElectrified))
			set_electrified(vval < MACHINE_NOT_ELECTRIFIED ? MACHINE_ELECTRIFIED_PERMANENT : vval) //negative values are bad mkay (unless they're the intended negative value!)

/obj/machinery/door/airlock/lock()
	bolt()

/obj/machinery/door/airlock/proc/bolt()
	if(locked)
		return
	set_bolt(TRUE)
	playsound(src,boltDown,30,FALSE,3)
	audible_message(span_hear("You hear a click from the bottom of the door."), null,  1)
	update_appearance()

/obj/machinery/door/airlock/proc/set_bolt(should_bolt)
	if(locked == should_bolt)
		return
	SEND_SIGNAL(src, COMSIG_AIRLOCK_SET_BOLT, should_bolt)
	. = locked
	locked = should_bolt

/obj/machinery/door/airlock/unlock()
	unbolt()

/obj/machinery/door/airlock/proc/unbolt()
	if(!locked)
		return
	set_bolt(FALSE)
	playsound(src,boltUp,30,FALSE,3)
	audible_message(span_hear("You hear a click from the bottom of the door."), null,  1)
	update_appearance()

/obj/machinery/door/airlock/narsie_act()
	var/turf/T = get_turf(src)
	var/obj/machinery/door/airlock/cult/A
	if(GLOB.cult_narsie)
		var/runed = prob(20)
		if(glass)
			if(runed)
				A = new/obj/machinery/door/airlock/cult/glass(T)
			else
				A = new/obj/machinery/door/airlock/cult/unruned/glass(T)
		else
			if(runed)
				A = new/obj/machinery/door/airlock/cult(T)
			else
				A = new/obj/machinery/door/airlock/cult/unruned(T)
		A.name = name
	else
		A = new /obj/machinery/door/airlock/cult/weak(T)
	qdel(src)

/obj/machinery/door/airlock/Destroy()
	QDEL_NULL(electronics)
	if (cyclelinkedairlock)
		if (cyclelinkedairlock.cyclelinkedairlock == src)
			cyclelinkedairlock.cyclelinkedairlock = null
		cyclelinkedairlock = null
	if(close_others) //remove this airlock from the list of every linked airlock
		closeOtherId = null
		for(var/obj/machinery/door/airlock/otherlock as anything in close_others)
			otherlock.close_others -= src
		close_others.Cut()
	QDEL_NULL(note)
	QDEL_NULL(seal)
	for(var/datum/atom_hud/data/diagnostic/diag_hud in GLOB.huds)
		diag_hud.remove_atom_from_hud(src)
	return ..()

/obj/machinery/door/airlock/Exited(atom/movable/gone, direction)
	. = ..()
	if(gone == note)
		note = null
		update_appearance()
	if(gone == seal)
		seal = null
		update_appearance()

/obj/machinery/door/airlock/bumpopen(mob/living/user)
	if(!hasPower())
		return

	if(issilicon(user) || !iscarbon(user))
		return ..()

	if(isElectrified() && shock(user, 100))
		return

	if(SEND_SIGNAL(user, COMSIG_CARBON_BUMPED_AIRLOCK_OPEN, src) & STOP_BUMP)
		return

	return ..()

/obj/machinery/door/airlock/proc/isElectrified()
	return (secondsElectrified != MACHINE_NOT_ELECTRIFIED)

/obj/machinery/door/airlock/proc/canAIControl(mob/user)
	return ((aiControlDisabled != AI_WIRE_DISABLED) && !isAllPowerCut())

/obj/machinery/door/airlock/proc/canAIHack()
	return ((aiControlDisabled == AI_WIRE_DISABLED) && (!hackProof) && (!isAllPowerCut()));

/obj/machinery/door/airlock/hasPower()
	return ((!remaining_main_outage() || !remaining_backup_outage()) && !(machine_stat & NOPOWER))

/obj/machinery/door/airlock/requiresID()
	return !(wires.is_cut(WIRE_IDSCAN) || aiDisabledIdScanner)

/obj/machinery/door/airlock/proc/isAllPowerCut()
	if((wires.is_cut(WIRE_POWER1) || wires.is_cut(WIRE_POWER2)) && (wires.is_cut(WIRE_BACKUP1) || wires.is_cut(WIRE_BACKUP2)))
		return TRUE

/// Returns the amount of time we have to wait before main power comes back
/// Assuming it was actively regenerating
/// Returns 0 if it is active
/obj/machinery/door/airlock/proc/remaining_main_outage()
	if(main_power_timer)
		return timeleft(main_power_timer)
	return main_power_time

/// Returns the amount of time we have to wait before backup power comes back
/// Assuming it was actively regenerating
/// Returns 0 if it is active
/obj/machinery/door/airlock/proc/remaining_backup_outage()
	if(backup_power_timer)
		return timeleft(backup_power_timer)
	return backup_power_time

/obj/machinery/door/airlock/proc/set_main_outage(delay)
	// Clear out the timer so we don't accidentially take from it later
	if(main_power_timer)
		deltimer(main_power_timer)
		main_power_timer = null
	var/old_time = main_power_time
	main_power_time = delay
	handle_main_power()
	if(!!old_time != !!delay)
		update_appearance()

/obj/machinery/door/airlock/proc/set_backup_outage(delay)
	// Clear out the timer so we don't accidentially take from it later
	if(backup_power_timer)
		deltimer(backup_power_timer)
		backup_power_timer = null
	var/old_time = backup_power_time
	backup_power_time = delay
	handle_backup_power()
	if(!!old_time != !!delay)
		update_appearance()

/// Call to update our main power outage timer
/// Will trigger a proper timer if we're actively restoring power, if not we'll dump the remaining time in a var on the airlock
/obj/machinery/door/airlock/proc/handle_main_power()
	if(main_power_time <= 0)
		deltimer(main_power_timer)
		main_power_timer = null
		return

	// If we can, we'll start a timer that hits when we're done
	if(!wires.is_cut(WIRE_POWER1) && !wires.is_cut(WIRE_POWER2))
		if(!main_power_timer || timeleft(main_power_timer) != main_power_time)
			main_power_timer = addtimer(CALLBACK(src, PROC_REF(regainMainPower)), main_power_time, TIMER_UNIQUE|TIMER_OVERRIDE|TIMER_STOPPABLE|TIMER_DELETE_ME)
	// Otherwise, we'll ensure the timer matches main_power_time
	else if(main_power_timer)
		main_power_time = timeleft(main_power_timer)
		deltimer(main_power_timer)
		main_power_timer = null

/// Call to update our backup power outage timer
/// Will trigger a proper timer if we're actively restoring power, if not we'll dump the remaining time in a var on the airlock
/obj/machinery/door/airlock/proc/handle_backup_power()
	if(backup_power_time <= 0)
		deltimer(backup_power_timer)
		backup_power_timer = null
		return

	// If we can, we'll start a timer that hits when we're done
	if(!wires.is_cut(WIRE_BACKUP1) && !wires.is_cut(WIRE_BACKUP2))
		if(!backup_power_timer || timeleft(backup_power_timer) != backup_power_time)
			backup_power_timer = addtimer(CALLBACK(src, PROC_REF(regainBackupPower)), backup_power_time, TIMER_UNIQUE|TIMER_OVERRIDE|TIMER_STOPPABLE|TIMER_DELETE_ME)
	// Otherwise, we'll ensure the timer matches backup_power_time
	else if(backup_power_timer)
		backup_power_time = timeleft(backup_power_timer)
		deltimer(backup_power_timer)
		backup_power_timer = null

// Alright, we're gonna do a meme here
/obj/machinery/door/airlock/set_wires(datum/wires/new_wires)
	if(wires)
		UnregisterSignal(wires, list(
			COMSIG_CUT_WIRE(WIRE_POWER1),
			COMSIG_CUT_WIRE(WIRE_POWER2),
			COMSIG_CUT_WIRE(WIRE_BACKUP1),
			COMSIG_CUT_WIRE(WIRE_BACKUP2),
			COMSIG_MEND_WIRE(WIRE_POWER1),
			COMSIG_MEND_WIRE(WIRE_POWER2),
			COMSIG_MEND_WIRE(WIRE_BACKUP1),
			COMSIG_MEND_WIRE(WIRE_BACKUP2),
		))
	. = ..()
	if(new_wires)
		RegisterSignals(new_wires, list(
			COMSIG_CUT_WIRE(WIRE_POWER1),
			COMSIG_CUT_WIRE(WIRE_POWER2),
			COMSIG_CUT_WIRE(WIRE_BACKUP1),
			COMSIG_CUT_WIRE(WIRE_BACKUP2),
			COMSIG_MEND_WIRE(WIRE_POWER1),
			COMSIG_MEND_WIRE(WIRE_POWER2),
			COMSIG_MEND_WIRE(WIRE_BACKUP1),
			COMSIG_MEND_WIRE(WIRE_BACKUP2),
		), PROC_REF(power_wires_changed))

/// If our power wires have changed, then our backup/main power regen may have failed, so let's just check in yeah?
/obj/machinery/door/airlock/proc/power_wires_changed(datum/source, wire)
	SIGNAL_HANDLER
	handle_main_power()
	handle_backup_power()

/obj/machinery/door/airlock/proc/regainMainPower()
	set_main_outage(0 SECONDS)

/obj/machinery/door/airlock/proc/loseMainPower()
	if(!remaining_main_outage())
		set_main_outage(60 SECONDS)
		if(remaining_backup_outage() < 10 SECONDS)
			set_backup_outage(10 SECONDS)

/obj/machinery/door/airlock/proc/loseBackupPower()
	if(remaining_backup_outage() < 60 SECONDS)
		set_backup_outage(60 SECONDS)

/obj/machinery/door/airlock/proc/regainBackupPower()
	set_backup_outage(0 SECONDS)

// shock user with probability prb (if all connections & power are working)
// returns TRUE if shocked, FALSE otherwise
// The preceding comment was borrowed from the grille's shock script
/obj/machinery/door/airlock/proc/shock(mob/living/user, prb)
	if(!istype(user) || !hasPower()) // unpowered, no shock
		return FALSE
	if(HAS_TRAIT(user, TRAIT_AIRLOCK_SHOCKIMMUNE)) // Be a bit more clever man come on
		return FALSE
	if(!COOLDOWN_FINISHED(src, shockCooldown))
		return FALSE //Already shocked someone recently?
	if(!prob(prb))
		return FALSE //you lucked out, no shock for you
	do_sparks(5, TRUE, src)
	var/check_range = TRUE
	if(electrocute_mob(user, get_area(src), src, 1, check_range))
		COOLDOWN_START(src, shockCooldown, 1 SECONDS)
		// Provides timed airlock shock immunity, to prevent overly cheesy deathtraps
		ADD_TRAIT(user, TRAIT_AIRLOCK_SHOCKIMMUNE, REF(src))
		addtimer(TRAIT_CALLBACK_REMOVE(user, TRAIT_AIRLOCK_SHOCKIMMUNE, REF(src)), 1 SECONDS)
		return TRUE
	else
		return FALSE

/obj/machinery/door/airlock/proc/is_secure()
	return (security_level > 0)

/obj/machinery/door/airlock/update_icon(updates=ALL, state=0, override=FALSE)
	if(operating && !override)
		return

	if(!state)
		state = density ? AIRLOCK_CLOSED : AIRLOCK_OPEN
	airlock_state = state

	. = ..()

/obj/machinery/door/airlock/update_icon_state()
	. = ..()
	switch(airlock_state)
		if(AIRLOCK_OPEN, AIRLOCK_CLOSED)
			icon_state = ""
		if(AIRLOCK_DENY, AIRLOCK_OPENING, AIRLOCK_CLOSING, AIRLOCK_EMAG)
			icon_state = "nonexistenticonstate" //MADNESS

/obj/machinery/door/airlock/update_overlays()
	. = ..()

	var/frame_state
	var/light_state
	switch(airlock_state)
		if(AIRLOCK_CLOSED)
			frame_state = AIRLOCK_FRAME_CLOSED
			if(locked)
				light_state = AIRLOCK_LIGHT_BOLTS
			else if(emergency)
				light_state = AIRLOCK_LIGHT_EMERGENCY
		if(AIRLOCK_DENY)
			frame_state = AIRLOCK_FRAME_CLOSED
			light_state = AIRLOCK_LIGHT_DENIED
		if(AIRLOCK_EMAG)
			frame_state = AIRLOCK_FRAME_CLOSED
		if(AIRLOCK_CLOSING)
			frame_state = AIRLOCK_FRAME_CLOSING
			light_state = AIRLOCK_LIGHT_CLOSING
		if(AIRLOCK_OPEN)
			frame_state = AIRLOCK_FRAME_OPEN
		if(AIRLOCK_OPENING)
			frame_state = AIRLOCK_FRAME_OPENING
			light_state = AIRLOCK_LIGHT_OPENING

	. += get_airlock_overlay(frame_state, icon, src, em_block = TRUE)
	if(airlock_material)
		. += get_airlock_overlay("[airlock_material]_[frame_state]", overlays_file, src, em_block = TRUE)
	else
		. += get_airlock_overlay("fill_[frame_state]", icon, src, em_block = TRUE)

	if(lights && hasPower() && light_state)
		. += get_airlock_overlay("lights_[light_state]", overlays_file, src, em_block = FALSE)

	if(panel_open)
		. += get_airlock_overlay("panel_[frame_state][security_level ? "_protected" : null]", overlays_file, src, em_block = TRUE)
	if(frame_state == AIRLOCK_FRAME_CLOSED && welded)
		. += get_airlock_overlay("welded", overlays_file, src, em_block = TRUE)

	if(airlock_state == AIRLOCK_EMAG)
		. += get_airlock_overlay("sparks", overlays_file, src, em_block = FALSE)

	if(hasPower())
		if(frame_state == AIRLOCK_FRAME_CLOSED)
			if(atom_integrity < integrity_failure * max_integrity)
				. += get_airlock_overlay("sparks_broken", overlays_file, src, em_block = FALSE)
			else if(atom_integrity < (0.75 * max_integrity))
				. += get_airlock_overlay("sparks_damaged", overlays_file, src, em_block = FALSE)
		else if(frame_state == AIRLOCK_FRAME_OPEN)
			if(atom_integrity < (0.75 * max_integrity))
				. += get_airlock_overlay("sparks_open", overlays_file, src, em_block = FALSE)

	if(note)
		. += get_airlock_overlay(get_note_state(frame_state), note_overlay_file, src, em_block = TRUE)

	if(frame_state == AIRLOCK_FRAME_CLOSED && seal)
		. += get_airlock_overlay("sealed", overlays_file, src, em_block = TRUE)

	if(hasPower() && unres_sides)
		for(var/heading in list(NORTH,SOUTH,EAST,WEST))
			if(!(unres_sides & heading))
				continue
			var/mutable_appearance/floorlight = mutable_appearance('icons/obj/doors/airlocks/station/overlays.dmi', "unres_[heading]", FLOAT_LAYER, src, ABOVE_LIGHTING_PLANE)
			switch (heading)
				if (NORTH)
					floorlight.pixel_x = 0
					floorlight.pixel_y = 32
				if (SOUTH)
					floorlight.pixel_x = 0
					floorlight.pixel_y = -32
				if (EAST)
					floorlight.pixel_x = 32
					floorlight.pixel_y = 0
				if (WEST)
					floorlight.pixel_x = -32
					floorlight.pixel_y = 0
			. += floorlight

/obj/machinery/door/airlock/run_animation(animation)
	switch(animation)
		if(DOOR_OPENING_ANIMATION)
			update_icon(ALL, AIRLOCK_OPENING)
		if(DOOR_OPENING_ANIMATION)
			update_icon(ALL, AIRLOCK_CLOSING)
		if(DOOR_DENY_ANIMATION)
			if(!machine_stat)
				update_icon(ALL, AIRLOCK_DENY)
				playsound(src,doorDeni,50,FALSE,3)
				addtimer(CALLBACK(src, PROC_REF(handle_deny_end)), AIRLOCK_DENY_ANIMATION_TIME)

/obj/machinery/door/airlock/proc/handle_deny_end()
	if(airlock_state == AIRLOCK_DENY)
		update_icon(ALL, AIRLOCK_CLOSED)

/obj/machinery/door/airlock/animation_length(animation)
	switch(animation)
		if(DOOR_OPENING_ANIMATION)
			return 0.6 SECONDS
		if(DOOR_CLOSING_ANIMATION)
			return 0.6 SECONDS

/obj/machinery/door/airlock/animation_segment_delay(animation)
	switch(animation)
		if(AIRLOCK_OPENING_TRANSPARENT)
			return 0.1 SECONDS
		if(AIRLOCK_OPENING_PASSABLE)
			return 0.5 SECONDS
		if(AIRLOCK_OPENING_FINISHED)
			return 0.6 SECONDS
		if(AIRLOCK_CLOSING_UNPASSABLE)
			return 0.2 SECONDS
		if(AIRLOCK_CLOSING_OPAQUE)
			return 0.5 SECONDS
		if(AIRLOCK_CLOSING_FINISHED)
			return 0.6 SECONDS

/obj/machinery/door/airlock/examine(mob/user)
	. = ..()
	if(closeOtherId)
		. += span_warning("This airlock cycles on ID: [sanitize(closeOtherId)].")
	else if(cyclelinkedairlock)
		. += span_warning("This airlock cycles with: [cyclelinkedairlock.name].")
	else
		. += span_warning("This airlock does not cycle.")
	if(obj_flags & EMAGGED)
		. += span_warning("Its access panel is smoking slightly.")
	if(note)
		if(!in_range(user, src))
			. += "There's a [note.name] pinned to the front. You can't read it from here."
		else
			. += "There's a [note.name] pinned to the front..."
			. += note.examine(user)
	if(seal)
		. += "It's been braced with \a [seal]."
	if(welded)
		. += "It's welded shut."
	if(panel_open)
		switch(security_level)
			if(AIRLOCK_SECURITY_NONE)
				. += "Its wires are exposed!"
			if(AIRLOCK_SECURITY_IRON)
				. += "Its wires are hidden behind a welded iron cover."
			if(AIRLOCK_SECURITY_PLASTEEL_I_S)
				. += "There is some shredded plasteel inside."
			if(AIRLOCK_SECURITY_PLASTEEL_I)
				. += "Its wires are behind an inner layer of plasteel."
			if(AIRLOCK_SECURITY_PLASTEEL_O_S)
				. += "There is some shredded plasteel inside."
			if(AIRLOCK_SECURITY_PLASTEEL_O)
				. += "There is a welded plasteel cover hiding its wires."
			if(AIRLOCK_SECURITY_PLASTEEL)
				. += "There is a protective grille over its panel."
	else if(security_level)
		if(security_level == AIRLOCK_SECURITY_IRON)
			. += "It looks a bit stronger."
		else
			. += "It looks very robust."

	if(issilicon(user) && !(machine_stat & BROKEN))
		. += span_notice("Shift-click [src] to [ density ? "open" : "close"] it.")
		. += span_notice("Ctrl-click [src] to [ locked ? "raise" : "drop"] its bolts.")
		. += span_notice("Alt-click [src] to [ secondsElectrified ? "un-electrify" : "permanently electrify"] it.")
		. += span_notice("Ctrl-Shift-click [src] to [ emergency ? "disable" : "enable"] emergency access.")

/obj/machinery/door/airlock/add_context(atom/source, list/context, obj/item/held_item, mob/user)
	. = ..()

	if(isAI(user) || iscyborg(user))
		if(!(machine_stat & BROKEN))
			var/ui = SStgui.try_update_ui(user, src)
			if(!ui && !held_item)
				context[SCREENTIP_CONTEXT_LMB] = "Open UI"
			context[SCREENTIP_CONTEXT_SHIFT_LMB] = density ? "Open" : "Close"
			context[SCREENTIP_CONTEXT_CTRL_LMB] = locked ? "Unbolt" : "Bolt"
			context[SCREENTIP_CONTEXT_ALT_LMB] = isElectrified() ? "Unelectrify" : "Electrify"
			context[SCREENTIP_CONTEXT_CTRL_SHIFT_LMB] = emergency ? "Unset emergency access" : "Set emergency access"
			. = CONTEXTUAL_SCREENTIP_SET

	if(!isliving(user))
		return .

	if(!Adjacent(user))
		return .

	switch (held_item?.tool_behaviour)
		if (TOOL_SCREWDRIVER)
			if(has_access_panel)
				context[SCREENTIP_CONTEXT_LMB] = panel_open ? "Close panel" : "Open panel"
				return CONTEXTUAL_SCREENTIP_SET
		if (TOOL_CROWBAR)
			if (panel_open)
				if (security_level == AIRLOCK_SECURITY_PLASTEEL_O_S || security_level == AIRLOCK_SECURITY_PLASTEEL_I_S)
					context[SCREENTIP_CONTEXT_LMB] = "Remove shielding"
					return CONTEXTUAL_SCREENTIP_SET
				else if (should_try_removing_electronics())
					context[SCREENTIP_CONTEXT_LMB] = "Remove electronics"
					return CONTEXTUAL_SCREENTIP_SET

			// Not always contextually true, but is contextually false in ways that make gameplay interesting.
			// For example, trying to pry open an airlock, only for the bolts to be down and the lights off.
			context[SCREENTIP_CONTEXT_LMB] = "Pry open"

			return CONTEXTUAL_SCREENTIP_SET
		if (TOOL_WELDER)
			context[SCREENTIP_CONTEXT_RMB] = "Weld shut"

			if (panel_open)
				switch (security_level)
					if (AIRLOCK_SECURITY_IRON, AIRLOCK_SECURITY_PLASTEEL_I, AIRLOCK_SECURITY_PLASTEEL_O)
						context[SCREENTIP_CONTEXT_LMB] = "Cut shielding"
						return CONTEXTUAL_SCREENTIP_SET

			context[SCREENTIP_CONTEXT_LMB] = "Repair"
			return CONTEXTUAL_SCREENTIP_SET
	if(istype(held_item, /obj/item/wrench/bolter))
		if(locked)
			context[SCREENTIP_CONTEXT_LMB] = "Raise bolts"
			return CONTEXTUAL_SCREENTIP_SET

		return CONTEXTUAL_SCREENTIP_SET
	return .

/obj/machinery/door/airlock/attack_ai(mob/user)
	if(!canAIControl(user))
		if(canAIHack())
			hack(user)
			return
		else
			to_chat(user, span_warning("Airlock AI control has been blocked with a firewall. Unable to hack."))
	if(obj_flags & EMAGGED)
		to_chat(user, span_warning("Unable to interface: Airlock is unresponsive."))
		return

	ui_interact(user)

///Performs basic checks to make sure we are still able to hack an airlock. If control is restored early through outside means, opens the airlock's control interface.
/obj/machinery/door/airlock/proc/check_hacking(mob/user, success_message)
	if(QDELETED(src))
		to_chat(user, span_warning("Connection lost! Unable to locate airlock on network."))
		aiHacking = FALSE
		return FALSE
	if(canAIControl(user))
		to_chat(user, span_notice("Alert cancelled. Airlock control has been restored without our assistance."))
		aiHacking = FALSE
		if(user)
			attack_ai(user) //bring up airlock dialog
		return
	else if(!canAIHack())
		to_chat(user, span_warning("Connection lost! Unable to hack airlock."))
		aiHacking = FALSE
		return
	if(success_message)
		to_chat(user, span_notice(success_message))
	return TRUE

///Attemps to override airlocks that have the AI control wire disabled.
/obj/machinery/door/airlock/proc/hack(mob/user)
	set waitfor = 0
	if(!aiHacking)
		aiHacking = TRUE
		to_chat(user, span_warning("Airlock AI control has been blocked. Beginning fault-detection."))
		sleep(5 SECONDS)

		if(!check_hacking(user, "Fault confirmed: airlock control wire disabled or cut."))
			return
		sleep(2 SECONDS)

		if(!check_hacking(user, "Attempting to hack into airlock. This may take some time."))
			return
		sleep(20 SECONDS)

		if(!check_hacking(user, "Upload access confirmed. Loading control program into airlock software."))
			return
		sleep(17 SECONDS)

		if(!check_hacking(user,"Transfer complete. Forcing airlock to execute program."))
			return
		sleep(5 SECONDS)

		if(!check_hacking(user, "Receiving control information from airlock."))
			return
		aiControlDisabled = AI_WIRE_HACKED //disable blocked control
		sleep(1 SECONDS)

		aiHacking = FALSE
		if(QDELETED(src))
			to_chat(user, span_warning("Connection lost! Unable to locate airlock on network."))
			return
		if(user)
			attack_ai(user) //bring up airlock dialog

/obj/machinery/door/airlock/attack_animal(mob/user, list/modifiers)
	if(isElectrified() && shock(user, 100))
		return
	return ..()

/obj/machinery/door/airlock/attack_paw(mob/user, list/modifiers)
	return attack_hand(user, modifiers)

/obj/machinery/door/airlock/attack_hand(mob/user, list/modifiers)
	. = ..()
	if(.)
		return
	if(!HAS_SILICON_ACCESS(user))
		if(isElectrified() && shock(user, 100))
			return

	if(ishuman(user) && prob(40) && density)
		var/mob/living/carbon/human/H = user
		if((HAS_TRAIT(H, TRAIT_DUMB)) && Adjacent(user))
			playsound(src, 'sound/effects/bang.ogg', 25, TRUE)
			if(!istype(H.head, /obj/item/clothing/head/helmet))
				H.visible_message(span_danger("[user] headbutts the airlock."), \
									span_userdanger("You headbutt the airlock!"))
				H.Paralyze(100)
				H.apply_damage(10, BRUTE, BODY_ZONE_HEAD)
			else
				visible_message(span_danger("[user] headbutts the airlock. Good thing [user.p_theyre()] wearing a helmet."))

/obj/machinery/door/airlock/attempt_wire_interaction(mob/user)
	if(security_level)
		to_chat(user, span_warning("Wires are protected!"))
		return WIRE_INTERACTION_FAIL
	return ..()

/obj/machinery/door/airlock/proc/electrified_loop()
	while (secondsElectrified > MACHINE_NOT_ELECTRIFIED)
		sleep(1 SECONDS)
		if(QDELETED(src))
			return

		if(secondsElectrified <= MACHINE_NOT_ELECTRIFIED) //make sure they weren't unelectrified during the sleep.
			break
		secondsElectrified = max(MACHINE_NOT_ELECTRIFIED, secondsElectrified - 1) //safety to make sure we don't end up permanently electrified during a timed electrification.
	// This is to protect against changing to permanent, mid loop.
	if(secondsElectrified == MACHINE_NOT_ELECTRIFIED)
		set_electrified(MACHINE_NOT_ELECTRIFIED)
	else
		set_electrified(MACHINE_ELECTRIFIED_PERMANENT)

/obj/machinery/door/airlock/screwdriver_act(mob/living/user, obj/item/tool)
	if(!has_access_panel)
		to_chat(user, span_warning("[src] has no maintenance panel!"))
		return ITEM_INTERACT_SUCCESS
	toggle_panel_open()
	to_chat(user, span_notice("You [panel_open ? "open":"close"] the maintenance panel of the airlock."))
	tool.play_tool_sound(src)
	update_appearance()
	return ITEM_INTERACT_SUCCESS

/obj/machinery/door/airlock/wirecutter_act(mob/living/user, obj/item/tool)
	if(panel_open && security_level == AIRLOCK_SECURITY_PLASTEEL)
		. = ITEM_INTERACT_SUCCESS  // everything after this shouldn't result in attackby
		if(hasPower() && shock(user, 60)) // Protective grille of wiring is electrified
			return .
		to_chat(user, span_notice("You start cutting through the outer grille."))
		if(!tool.use_tool(src, user, 10, volume=100))
			return .
		if(!panel_open)  // double check it wasn't closed while we were trying to snip
			return .
		user.visible_message(span_notice("[user] cut through [src]'s outer grille."),
							span_notice("You cut through [src]'s outer grille."))
		security_level = AIRLOCK_SECURITY_PLASTEEL_O
		return .
	if(note)
		if(user.CanReach(src))
			user.visible_message(span_notice("[user] cuts down [note] from [src]."), span_notice("You remove [note] from [src]."))
		else //telekinesis
			visible_message(span_notice("[tool] cuts down [note] from [src]."))
		tool.play_tool_sound(src)
		note.forceMove(tool.drop_location())
		note = null
		update_appearance()
		return ITEM_INTERACT_SUCCESS

/obj/machinery/door/airlock/crowbar_act(mob/living/user, obj/item/tool)

	if(!panel_open || security_level == AIRLOCK_SECURITY_NONE)
		return ..()

	var/layer_flavor
	var/next_level
	var/starting_level = security_level

	switch(security_level)
		if(AIRLOCK_SECURITY_PLASTEEL_O_S)
			layer_flavor = "outer layer of shielding"
			next_level = AIRLOCK_SECURITY_PLASTEEL_I

		if(AIRLOCK_SECURITY_PLASTEEL_I_S)
			layer_flavor = "inner layer of shielding"
			next_level = AIRLOCK_SECURITY_NONE
		else
			return ITEM_INTERACT_SUCCESS

	user.visible_message(span_notice("You start prying away [src]'s [layer_flavor]."))
	if(!tool.use_tool(src, user, 40, volume=100))
		return ITEM_INTERACT_SUCCESS
	if(!panel_open || security_level != starting_level)
		// if the plating's already been broken, don't break it again
		return ITEM_INTERACT_SUCCESS
	user.visible_message(span_notice("[user] removes [src]'s shielding."),
							span_notice("You remove [src]'s [layer_flavor]."))
	security_level = next_level
	spawn_atom_to_turf(/obj/item/stack/sheet/plasteel, user.loc, 1)
	if(next_level == AIRLOCK_SECURITY_NONE)
		modify_max_integrity(max_integrity / AIRLOCK_INTEGRITY_MULTIPLIER)
		damage_deflection = AIRLOCK_DAMAGE_DEFLECTION_N
		update_appearance()
	return ITEM_INTERACT_SUCCESS

/obj/machinery/door/airlock/wrench_act(mob/living/user, obj/item/tool)
	if(!locked)
		return
	if(!panel_open)
		balloon_alert(user, "panel is closed!")
		return
	if(security_level != AIRLOCK_SECURITY_NONE)
		balloon_alert(user, "airlock is reinforced!")
		return

	if(istype(tool, /obj/item/wrench/bolter))
		balloon_alert(user, "raising bolts...")
		if(!do_after(user, 5 SECONDS, src))
			return
		unbolt()

	return ITEM_INTERACT_SUCCESS

/obj/machinery/door/airlock/welder_act(mob/living/user, obj/item/tool)

	if(!panel_open || security_level == AIRLOCK_SECURITY_NONE)
		return ..()

	var/layer_flavor
	var/next_level
	var/starting_level = security_level

	var/material_to_spawn
	var/amount_to_spawn

	switch(security_level)
		if(AIRLOCK_SECURITY_IRON)
			layer_flavor = "panel's shielding"
			next_level = AIRLOCK_SECURITY_NONE
			material_to_spawn = /obj/item/stack/sheet/iron
			amount_to_spawn = 2
		if(AIRLOCK_SECURITY_PLASTEEL_O)
			layer_flavor = "outer layer of shielding"
			next_level = AIRLOCK_SECURITY_PLASTEEL_O_S
		if(AIRLOCK_SECURITY_PLASTEEL_I)
			layer_flavor = "inner layer of shielding"
			next_level = AIRLOCK_SECURITY_PLASTEEL_I_S
		else
			return ITEM_INTERACT_SUCCESS

	if(!tool.tool_start_check(user, amount=1))
		return ITEM_INTERACT_SUCCESS

	to_chat(user, span_notice("You begin cutting the [layer_flavor]..."))

	if(!tool.use_tool(src, user, 4 SECONDS, volume=50))
		return ITEM_INTERACT_SUCCESS

	if(!panel_open || security_level != starting_level)
		// see if anyone's screwing with us
		return ITEM_INTERACT_SUCCESS

	user.visible_message(
		span_notice("[user] cuts through [src]'s shielding."),  // passers-by don't get the full picture
		span_notice("You cut through [src]'s [layer_flavor]."),
		span_hear("You hear welding.")
	)

	security_level = next_level

	if(material_to_spawn)
		spawn_atom_to_turf(material_to_spawn, user.loc, amount_to_spawn)

	if(security_level == AIRLOCK_SECURITY_NONE)
		update_appearance()

	return ITEM_INTERACT_SUCCESS

/obj/machinery/door/airlock/proc/try_reinforce(mob/user, obj/item/stack/sheet/material, amt_required, new_security_level)
	if(material.get_amount() < amt_required)
		to_chat(user, span_warning("You need at least [amt_required] sheets of [material] to reinforce [src]."))
		return FALSE
	to_chat(user, span_notice("You start reinforcing [src]."))
	if(!do_after(user, 2 SECONDS, src))
		return FALSE
	if(!panel_open || !material.use(amt_required))
		return FALSE
	user.visible_message(span_notice("[user] reinforces [src] with [material]."),
						span_notice("You reinforce [src] with [material]."))
	security_level = new_security_level
	update_appearance()
	return TRUE

/obj/machinery/door/airlock/attackby(obj/item/C, mob/user, params)
	if(!HAS_SILICON_ACCESS(user))
		if(isElectrified() && (C.obj_flags & CONDUCTS_ELECTRICITY) && shock(user, 75))
			return
	add_fingerprint(user)

	if(is_wire_tool(C) && panel_open)
		attempt_wire_interaction(user)
		return
	else if(panel_open && security_level == AIRLOCK_SECURITY_NONE && istype(C, /obj/item/stack/sheet))
		if(istype(C, /obj/item/stack/sheet/iron))
			return try_reinforce(user, C, 2, AIRLOCK_SECURITY_IRON)

		else if(istype(C, /obj/item/stack/sheet/plasteel))
			if(!try_reinforce(user, C, 2, AIRLOCK_SECURITY_PLASTEEL))
				return FALSE
			modify_max_integrity(max_integrity * AIRLOCK_INTEGRITY_MULTIPLIER)
			damage_deflection = AIRLOCK_DAMAGE_DEFLECTION_R
			update_appearance()
			return TRUE

	else if(istype(C, /obj/item/pai_cable))
		var/obj/item/pai_cable/cable = C
		cable.plugin(src, user)
	else if(istype(C, /obj/item/airlock_painter))
		change_paintjob(C, user)
	else if(istype(C, /obj/item/door_seal)) //adding the seal
		var/obj/item/door_seal/airlockseal = C
		if(!density)
			to_chat(user, span_warning("[src] must be closed before you can seal it!"))
			return
		if(seal)
			to_chat(user, span_warning("[src] has already been sealed!"))
			return
		user.visible_message(span_notice("[user] begins sealing [src]."), span_notice("You begin sealing [src]."))
		playsound(src, 'sound/items/tools/jaws_pry.ogg', 30, TRUE)
		if(!do_after(user, airlockseal.seal_time, target = src))
			return
		if(!density)
			to_chat(user, span_warning("[src] must be closed before you can seal it!"))
			return
		if(seal)
			to_chat(user, span_warning("[src] has already been sealed!"))
			return
		if(!user.transferItemToLoc(airlockseal, src))
			to_chat(user, span_warning("For some reason, you can't attach [airlockseal]!"))
			return
		playsound(src, 'sound/machines/airlock/airlockforced.ogg', 30, TRUE)
		user.visible_message(span_notice("[user] finishes sealing [src]."), span_notice("You finish sealing [src]."))
		seal = airlockseal
		modify_max_integrity(max_integrity * AIRLOCK_SEAL_MULTIPLIER)
		update_appearance()

	else if(istype(C, /obj/item/paper) || istype(C, /obj/item/photo))
		if(note)
			to_chat(user, span_warning("There's already something pinned to this airlock! Use wirecutters to remove it."))
			return
		if(!user.transferItemToLoc(C, src))
			to_chat(user, span_warning("For some reason, you can't attach [C]!"))
			return
		user.visible_message(span_notice("[user] pins [C] to [src]."), span_notice("You pin [C] to [src]."))
		note = C
		update_appearance()
	else
		return ..()


/obj/machinery/door/airlock/try_to_weld(obj/item/weldingtool/W, mob/living/user)
	if(!operating && density)
		if(seal)
			to_chat(user, span_warning("[src] is blocked by a seal!"))
			return

		if(atom_integrity < max_integrity)
			if(!W.tool_start_check(user, amount=1))
				return
			user.visible_message(span_notice("[user] begins welding the airlock."), \
							span_notice("You begin repairing the airlock..."), \
							span_hear("You hear welding."))
			if(W.use_tool(src, user, 40, volume=50, extra_checks = CALLBACK(src, PROC_REF(weld_checks), W, user)))
				atom_integrity = max_integrity
				set_machine_stat(machine_stat & ~BROKEN)
				user.visible_message(span_notice("[user] finishes welding [src]."), \
									span_notice("You finish repairing the airlock."))
				update_appearance()
		else
			to_chat(user, span_notice("The airlock doesn't need repairing."))

/obj/machinery/door/airlock/try_to_weld_secondary(obj/item/weldingtool/tool, mob/user)
	if(!tool.tool_start_check(user, amount=1))
		return
	user.visible_message(span_notice("[user] begins [welded ? "unwelding":"welding"] the airlock."), \
		span_notice("You begin [welded ? "unwelding":"welding"] the airlock..."), \
		span_hear("You hear welding."))
	if(!tool.use_tool(src, user, 40, volume=50, extra_checks = CALLBACK(src, PROC_REF(weld_checks), tool, user)))
		return
	welded = !welded
	user.visible_message(span_notice("[user] [welded? "welds shut":"unwelds"] [src]."), \
		span_notice("You [welded ? "weld the airlock shut":"unweld the airlock"]."))
	user.log_message("[welded ? "welded":"unwelded"] airlock [src] with [tool].", LOG_GAME)
	update_appearance()

/obj/machinery/door/airlock/proc/weld_checks(obj/item/weldingtool/W, mob/user)
	return !operating && density

/**
 * Used when attempting to remove a seal from an airlock
 *
 * Called when attacking an airlock with an empty hand, returns TRUE (there was a seal and we removed it, or failed to remove it)
 * or FALSE (there was no seal)
 * Arguments:
 * * user - Whoever is attempting to remove the seal
 */
/obj/machinery/door/airlock/try_remove_seal(mob/living/user)
	if(!seal)
		return FALSE
	var/obj/item/door_seal/airlockseal = seal
	if(!ishuman(user))
		to_chat(user, span_warning("You don't have the dexterity to remove the seal!"))
		return TRUE
	user.visible_message(span_notice("[user] begins removing the seal from [src]."), span_notice("You begin removing [src]'s pneumatic seal."))
	playsound(src, 'sound/machines/airlock/airlockforced.ogg', 30, TRUE)
	if(!do_after(user, airlockseal.unseal_time, target = src))
		return TRUE
	if(!seal)
		return TRUE
	playsound(src, 'sound/items/tools/jaws_pry.ogg', 30, TRUE)
	airlockseal.forceMove(get_turf(user))
	user.visible_message(span_notice("[user] finishes removing the seal from [src]."), span_notice("You finish removing [src]'s pneumatic seal."))
	seal = null
	modify_max_integrity(max_integrity / AIRLOCK_SEAL_MULTIPLIER)
	update_appearance()
	return TRUE

/// Returns if a crowbar would remove the airlock electronics
/obj/machinery/door/airlock/proc/should_try_removing_electronics()
	if (security_level != 0)
		return FALSE

	if (!panel_open)
		return FALSE

	if (obj_flags & EMAGGED)
		return TRUE

	if (!density)
		return FALSE

	if (!welded)
		return FALSE

	if (hasPower())
		return FALSE

	if (locked)
		return FALSE

	return TRUE

/obj/machinery/door/airlock/try_to_crowbar(obj/item/tool, mob/living/user, forced = FALSE)
	if(!isnull(tool) && tool.tool_behaviour == TOOL_CROWBAR && should_try_removing_electronics() && !operating)
		user.visible_message(span_notice("[user] removes the electronics from the airlock assembly."), \
			span_notice("You start to remove electronics from the airlock assembly..."))

		if(tool.use_tool(src, user, 40, volume = 100))
			deconstruct(TRUE, user)
			return

	if(seal)
		to_chat(user, span_warning("Remove the seal first!"))
		return
	if(locked)
		to_chat(user, span_warning("The airlock's bolts prevent it from being forced!"))
		return
	if(welded)
		to_chat(user, span_warning("It's welded, it won't budge!"))
		return

	if(!hasPower())
		if(operating)
			return

		if(istype(tool, /obj/item/fireaxe) && !HAS_TRAIT(tool, TRAIT_WIELDED)) //being fireaxe'd
			to_chat(user, span_warning("You need to be wielding [tool] to do that!"))
			return

		INVOKE_ASYNC(src, density ? PROC_REF(open) : PROC_REF(close), BYPASS_DOOR_CHECKS)
		return

	if(!forced)
		to_chat(user, span_warning("The airlock's motors resist your efforts to force it!"))
		return

	var/check_electrified = isElectrified() //setting this so we can check if the mob got shocked during the do_after below
	if(check_electrified && shock(user,100))
		return //it's like sticking a fork in a power socket

	if(!density)//already open
		return

	if(prying_so_hard)
		return

	var/time_to_open = 5 SECONDS
	playsound(src, 'sound/machines/airlock/airlock_alien_prying.ogg', 100, TRUE) //is it aliens or just the CE being a dick?
	prying_so_hard = TRUE

	if(!tool.use_tool(src, user, time_to_open, volume = 100))
		prying_so_hard = FALSE
		return

	prying_so_hard = FALSE

	if(check_electrified && shock(user, 100))
		return

	open(BYPASS_DOOR_CHECKS)
	take_damage(25, BRUTE, 0, 0) // Enough to sometimes spark
	if(density && !open(BYPASS_DOOR_CHECKS))
		to_chat(user, span_warning("Despite your attempts, [src] refuses to open."))

/obj/machinery/door/airlock/open(forced = DEFAULT_DOOR_CHECKS)
	if(cycle_pump && !operating && !welded && !seal && locked && density)
		cycle_pump.airlock_act(src)
		return FALSE // The rest will be handled by the pump

	if( operating || welded || locked || seal )
		return FALSE

	if(!density)
		return TRUE

	// Since we aren't physically held shut, do extra checks to see if we should open.
	if(!try_to_force_door_open(forced))
		return FALSE

	if(autoclose)
		autoclose_in(normalspeed ? 8 SECONDS : 1.5 SECONDS)

	if(closeOther != null && istype(closeOther, /obj/machinery/door/airlock))
		addtimer(CALLBACK(closeOther, PROC_REF(close)), BYPASS_DOOR_CHECKS)

	if(close_others)
		for(var/obj/machinery/door/airlock/otherlock as anything in close_others)
			if(!shuttledocked && !emergency && !otherlock.shuttledocked && !otherlock.emergency)
				if(otherlock.operating)
					otherlock.delayed_close_requested = TRUE
				else
					addtimer(CALLBACK(otherlock, PROC_REF(close)), BYPASS_DOOR_CHECKS)

	if(cyclelinkedairlock)
		if(!shuttledocked && !emergency && !cyclelinkedairlock.shuttledocked && !cyclelinkedairlock.emergency)
			if(cyclelinkedairlock.operating)
				cyclelinkedairlock.delayed_close_requested = TRUE
			else
				addtimer(CALLBACK(cyclelinkedairlock, PROC_REF(close)), BYPASS_DOOR_CHECKS)

	SEND_SIGNAL(src, COMSIG_AIRLOCK_OPEN, forced)
	operating = TRUE
	update_icon(ALL, AIRLOCK_OPENING, TRUE)
	var/transparent_delay = animation_segment_delay(AIRLOCK_OPENING_TRANSPARENT)
	sleep(transparent_delay)
	set_opacity(0)
	if(multi_tile)
		filler.set_opacity(FALSE)
	update_freelook_sight()
	var/passable_delay = animation_segment_delay(AIRLOCK_OPENING_PASSABLE) - transparent_delay
	sleep(passable_delay)
	set_density(FALSE)
	if(multi_tile)
		filler.set_density(FALSE)
	flags_1 &= ~PREVENT_CLICK_UNDER_1
	air_update_turf(TRUE, FALSE)
	var/open_delay = animation_segment_delay(AIRLOCK_OPENING_FINISHED) - transparent_delay - passable_delay
	sleep(open_delay)
	layer = OPEN_DOOR_LAYER
	update_icon(ALL, AIRLOCK_OPEN, TRUE)
	operating = FALSE
	if(delayed_close_requested)
		delayed_close_requested = FALSE
		addtimer(CALLBACK(src, PROC_REF(close)), FORCING_DOOR_CHECKS)
	return TRUE

/// Additional checks depending on what we want to happen to door (should we try and open it normally, or do we want this open at all costs?)
/obj/machinery/door/airlock/try_to_force_door_open(force_type = DEFAULT_DOOR_CHECKS)
	switch(force_type)
		if(DEFAULT_DOOR_CHECKS) // Regular behavior.
			if(!hasPower() || wires.is_cut(WIRE_OPEN) || (obj_flags & EMAGGED))
				return FALSE
			use_energy(50 JOULES)
			playsound(src, doorOpen, 30, TRUE)
			return TRUE

		if(FORCING_DOOR_CHECKS) // Only one check.
			if(obj_flags & EMAGGED)
				return FALSE
			use_energy(50 JOULES)
			playsound(src, doorOpen, 30, TRUE)
			return TRUE

		if(BYPASS_DOOR_CHECKS) // No power usage, special sound, get it open.
			playsound(src, 'sound/machines/airlock/airlockforced.ogg', 30, TRUE)
			return TRUE

		else
			stack_trace("Invalid forced argument '[force_type]' passed to open() on this airlock.")

	// If we got here, shit's fucked, hope parent can help us out here
	return ..()

/obj/machinery/door/airlock/close(forced = DEFAULT_DOOR_CHECKS, force_crush = FALSE)
	if(operating || welded || locked || seal)
		return FALSE
	if(density)
		return TRUE
	if(forced == DEFAULT_DOOR_CHECKS) // Do this up here and outside of try_to_force_door_shut because if we don't have power, we shouldn't be doing any dangerous_close stuff.
		if(!hasPower() || wires.is_cut(WIRE_BOLTS))
			return FALSE

	var/dangerous_close = !safe || force_crush
	if(!dangerous_close)
		for(var/turf/checked_turf in locs)
			for(var/atom/movable/blocking in checked_turf)
				if(blocking.density && blocking != src)
					autoclose_in(DOOR_CLOSE_WAIT)
					return FALSE

	if(!try_to_force_door_shut(forced))
		return FALSE

	var/obj/structure/window/killthis = (locate(/obj/structure/window) in get_turf(src))
	if(killthis)
		SSexplosions.med_mov_atom += killthis
	SEND_SIGNAL(src, COMSIG_AIRLOCK_CLOSE, forced)
	operating = TRUE
	update_icon(ALL, AIRLOCK_CLOSING, 1)
	layer = CLOSED_DOOR_LAYER
	if(air_tight)
		set_density(TRUE)
		if(multi_tile)
			filler.set_density(TRUE)
		flags_1 |= PREVENT_CLICK_UNDER_1
		air_update_turf(TRUE, TRUE)
	var/unpassable_delay = animation_segment_delay(AIRLOCK_CLOSING_UNPASSABLE)
	sleep(unpassable_delay)
	if(!air_tight)
		set_density(TRUE)
		if(multi_tile)
			filler.set_density(TRUE)
		flags_1 |= PREVENT_CLICK_UNDER_1
		air_update_turf(TRUE, TRUE)
	var/opaque_delay = animation_segment_delay(AIRLOCK_CLOSING_OPAQUE) - unpassable_delay
	sleep(opaque_delay)
	if(dangerous_close)
		crush()
	if(visible && !glass)
		set_opacity(TRUE)
		if(multi_tile)
			filler.set_opacity(TRUE)
	update_freelook_sight()
	var/close_delay = animation_segment_delay(AIRLOCK_CLOSING_FINISHED) - unpassable_delay - opaque_delay
	sleep(close_delay)
	update_icon(ALL, AIRLOCK_CLOSED, 1)
	operating = FALSE
	delayed_close_requested = FALSE
	if(!dangerous_close)
		CheckForMobs()
	return TRUE

/obj/machinery/door/airlock/try_to_force_door_shut(force_type = DEFAULT_DOOR_CHECKS)
	switch(force_type)
		if(DEFAULT_DOOR_CHECKS to FORCING_DOOR_CHECKS)
			if(obj_flags & EMAGGED)
				return FALSE
			use_energy(50 JOULES)
			playsound(src, doorClose, 30, TRUE)
			return TRUE

		if(BYPASS_DOOR_CHECKS)
			playsound(src, 'sound/machines/airlock/airlockforced.ogg', 30, TRUE)
			return TRUE

		else
			stack_trace("Invalid forced argument '[force_type]' passed to close() on this airlock.")

	// shit's fucked, let's hope parent has something to handle it.
	return ..()

/obj/machinery/door/airlock/proc/prison_open()
	if(obj_flags & EMAGGED)
		return
	if(locked)
		unbolt()
	open()
	bolt()
	return

// gets called when a player uses an airlock painter on this airlock
/obj/machinery/door/airlock/proc/change_paintjob(obj/item/airlock_painter/painter, mob/user)
	if((!in_range(src, user) && loc != user) || !painter.can_use(user)) // user should be adjacent to the airlock, and the painter should have a toner cartridge that isn't empty
		return

	// reads from the airlock painter's `available paintjob` list. lets the player choose a paint option, or cancel painting
	var/current_paintjob = tgui_input_list(user, "Paintjob for this airlock", "Customize", sort_list(painter.available_paint_jobs))
	if(isnull(current_paintjob)) // if the user clicked cancel on the popup, return
		return

	var/airlock_type = painter.available_paint_jobs["[current_paintjob]"] // get the airlock type path associated with the airlock name the user just chose
	var/obj/machinery/door/airlock/airlock = airlock_type // we need to create a new instance of the airlock and assembly to read vars from them
	var/obj/structure/door_assembly/assembly = initial(airlock.assemblytype)

	if(airlock_material == "glass" && initial(assembly.noglass)) // prevents painting glass airlocks with a paint job that doesn't have a glass version, such as the freezer
		to_chat(user, span_warning("This paint job can only be applied to non-glass airlocks."))
		return

	// applies the user-chosen airlock's icon, overlays and assemblytype to the src airlock
	painter.use_paint(user)
	if(initial(airlock.greyscale_config))
		greyscale_config = initial(airlock.greyscale_config)
		greyscale_colors = initial(airlock.greyscale_colors)
		update_greyscale()
	else
		icon = initial(airlock.icon)
	overlays_file = initial(airlock.overlays_file)
	assemblytype = initial(airlock.assemblytype)
	update_appearance()

/obj/machinery/door/airlock/CanAStarPass(to_dir, datum/can_pass_info/pass_info)
	//Airlock is passable if it is open (!density), bot has access, and is not bolted shut or powered off)
	return !density || (check_access_list(pass_info.access) && !locked && hasPower() && !pass_info.no_id)

/obj/machinery/door/airlock/emag_act(mob/user, obj/item/card/emag/emag_card)
	if(!operating && density && hasPower() && !(obj_flags & EMAGGED))
		if(istype(emag_card, /obj/item/card/emag/doorjack))
			var/obj/item/card/emag/doorjack/doorjack_card = emag_card
			doorjack_card.use_charge(user)
		operating = TRUE
		update_icon(ALL, AIRLOCK_EMAG, 1)
		addtimer(CALLBACK(src, PROC_REF(finish_emag_act)), 0.6 SECONDS)
		return TRUE
	return FALSE

/// Timer proc, called ~0.6 seconds after [emag_act]. Finishes the emag sequence by breaking the airlock, permanently locking it, and disabling power.
/obj/machinery/door/airlock/proc/finish_emag_act()
	if(QDELETED(src))
		return FALSE
	operating = FALSE
	if(!open())
		update_icon(ALL, AIRLOCK_CLOSED, 1)
	obj_flags |= EMAGGED
	lights = FALSE
	locked = TRUE
	loseMainPower()
	loseBackupPower()

/obj/machinery/door/airlock/attack_alien(mob/living/carbon/alien/adult/user, list/modifiers)
	if(isElectrified() && shock(user, 100)) //Mmm, fried xeno!
		add_fingerprint(user)
		return
	if(!density) //Already open
		return ..()
	if(user.combat_mode)
		return ..()
	if(locked || welded || seal) //Extremely generic, as aliens only understand the basics of how airlocks work.
		to_chat(user, span_warning("[src] refuses to budge!"))
		return
	add_fingerprint(user)
	user.visible_message(span_warning("[user] begins prying open [src]."),\
						span_noticealien("You begin digging your claws into [src] with all your might!"),\
						span_warning("You hear groaning metal..."))
	var/time_to_open = 5 //half a second
	if(hasPower())
		time_to_open = 5 SECONDS //Powered airlocks take longer to open, and are loud.
		playsound(src, 'sound/machines/airlock/airlock_alien_prying.ogg', 100, TRUE)


	if(do_after(user, time_to_open, src))
		if(density && !open(BYPASS_DOOR_CHECKS)) //The airlock is still closed, but something prevented it opening. (Another player noticed and bolted/welded the airlock in time!)
			to_chat(user, span_warning("Despite your efforts, [src] managed to resist your attempts to open it!"))

/obj/machinery/door/airlock/hostile_lockdown(mob/origin)
	// Must be powered and have working AI wire.
	if(canAIControl(origin) && !machine_stat)
		locked = FALSE //For airlocks that were bolted open.
		safe = FALSE //DOOR CRUSH
		close()
		bolt() //Bolt it!
		set_electrified(MACHINE_ELECTRIFIED_PERMANENT)  //Shock it!
		if(origin)
			LAZYADD(shockedby, "\[[time_stamp()]\] [key_name(origin)]")


/obj/machinery/door/airlock/disable_lockdown()
	// Must be powered and have working AI wire.
	if(canAIControl() && !machine_stat)
		unbolt()
		set_electrified(MACHINE_NOT_ELECTRIFIED)
		open()
		safe = TRUE


/obj/machinery/door/airlock/proc/on_break()
	SIGNAL_HANDLER

	set_panel_open(TRUE)
	wires.cut_all()

/obj/machinery/door/airlock/emp_act(severity)
	. = ..()
	if (. & EMP_PROTECT_SELF)
		return
	if(prob(severity*10 - 20) && (secondsElectrified < 30) && (secondsElectrified != MACHINE_ELECTRIFIED_PERMANENT))
		set_electrified(30)
		LAZYADD(shockedby, "\[[time_stamp()]\]EM Pulse")

/obj/machinery/door/airlock/proc/set_electrified(seconds, mob/user)
	secondsElectrified = seconds
	diag_hud_set_electrified()
	if(secondsElectrified > MACHINE_NOT_ELECTRIFIED)
		INVOKE_ASYNC(src, PROC_REF(electrified_loop))

	if(user)
		var/message
		switch(secondsElectrified)
			if(MACHINE_ELECTRIFIED_PERMANENT)
				message = "permanently shocked"
			if(MACHINE_NOT_ELECTRIFIED)
				message = "unshocked"
			else
				message = "temp shocked for [secondsElectrified] seconds"
		LAZYADD(shockedby, "\[[time_stamp()]\] [key_name(user)] - ([uppertext(message)])")
		log_combat(user, src, message)
		add_hiddenprint(user)

/obj/machinery/door/airlock/take_damage(damage_amount, damage_type = BRUTE, damage_flag = 0, sound_effect = 1, attack_dir)
	if((damage_amount >= atom_integrity) && (damage_flag == BOMB))
		obj_flags |= NO_DEBRIS_AFTER_DECONSTRUCTION  //If an explosive took us out, don't drop the assembly
	. = ..()
	if(atom_integrity < (0.75 * max_integrity))
		update_appearance()

/obj/machinery/door/airlock/proc/prepare_deconstruction_assembly(obj/structure/door_assembly/assembly)
	assembly.heat_proof_finished = heat_proof //tracks whether there's rglass in
	assembly.set_anchored(TRUE)
	assembly.glass = glass
	assembly.state = AIRLOCK_ASSEMBLY_NEEDS_ELECTRONICS
	assembly.created_name = name
	assembly.previous_assembly = previous_airlock
	assembly.update_name()
	assembly.update_appearance()
	assembly.dir = dir

/obj/machinery/door/airlock/on_deconstruction(disassembled)
	var/obj/structure/door_assembly/A
	if(assemblytype)
		A = new assemblytype(loc)
	else
		A = new /obj/structure/door_assembly(loc)
		//If you come across a null assemblytype, it will produce the default assembly instead of disintegrating.
	prepare_deconstruction_assembly(A)

	if(!disassembled)
		A?.update_integrity(A.max_integrity * 0.5)

	else if(!(obj_flags & EMAGGED))
		var/obj/item/electronics/airlock/ae
		if(!electronics)
			ae = new/obj/item/electronics/airlock(loc)
			if(closeOtherId)
				ae.passed_cycle_id = closeOtherId
			if(length(req_one_access))
				ae.one_access = 1
				ae.accesses = req_one_access
			else if(length(req_access))
				ae.accesses = req_access
		else
			ae = electronics
			electronics = null
			ae.forceMove(drop_location())

/obj/machinery/door/airlock/rcd_vals(mob/user, obj/item/construction/rcd/the_rcd)
	switch(the_rcd.mode)
		if(RCD_DECONSTRUCT)
			if(seal)
				to_chat(user, span_notice("[src]'s seal needs to be removed first."))
				return FALSE
			if(security_level != AIRLOCK_SECURITY_NONE)
				to_chat(user, span_notice("[src]'s reinforcement needs to be removed first."))
				return FALSE
			return list("delay" = 5 SECONDS, "cost" = 32)
	return FALSE

/obj/machinery/door/airlock/rcd_act(mob/user, obj/item/construction/rcd/the_rcd, list/rcd_data)
	switch(rcd_data["[RCD_DESIGN_MODE]"])
		if(RCD_DECONSTRUCT)
			qdel(src)
			return TRUE
	return FALSE

/**
 * Returns a string representing the type of note pinned to this airlock
 * Arguments:
 * * frame_state - The AIRLOCK_FRAME_ value, as used in update_overlays()
 **/
/obj/machinery/door/airlock/proc/get_note_state(frame_state)
	if(!note)
		return
	else if(istype(note, /obj/item/paper))
		var/obj/item/paper/pinned_paper = note
		if(pinned_paper.get_total_length() && pinned_paper.show_written_words)
			return "note_words_[frame_state]"
		else
			return "note_[frame_state]"

	else if(istype(note, /obj/item/photo))
		return "photo_[frame_state]"

/obj/machinery/door/airlock/ui_interact(mob/user, datum/tgui/ui)
	ui = SStgui.try_update_ui(user, src, ui)
	if(!ui)
		ui = new(user, src, "AiAirlock", name)
		ui.open()
	return TRUE

/obj/machinery/door/airlock/ui_data()
	var/list/data = list()

	var/list/power = list()
	power["main"] = remaining_main_outage() ? 0 : 2 // boolean
	power["main_timeleft"] = round(remaining_main_outage() / 10)
	power["backup"] = remaining_backup_outage() ? 0 : 2 // boolean
	power["backup_timeleft"] = round(remaining_backup_outage() / 10)
	data["power"] = power

	data["shock"] = secondsElectrified == MACHINE_NOT_ELECTRIFIED ? 2 : 0
	data["shock_timeleft"] = secondsElectrified
	data["id_scanner"] = !aiDisabledIdScanner
	data["emergency"] = emergency // access
	data["locked"] = locked // bolted
	data["lights"] = lights // bolt lights
	data["safe"] = safe // safeties
	data["speed"] = normalspeed // safe speed
	data["welded"] = welded // welded
	data["opened"] = !density // opened

	var/list/wire = list()
	wire["main_1"] = !wires.is_cut(WIRE_POWER1)
	wire["main_2"] = !wires.is_cut(WIRE_POWER2)
	wire["backup_1"] = !wires.is_cut(WIRE_BACKUP1)
	wire["backup_2"] = !wires.is_cut(WIRE_BACKUP2)
	wire["shock"] = !wires.is_cut(WIRE_SHOCK)
	wire["id_scanner"] = !wires.is_cut(WIRE_IDSCAN)
	wire["bolts"] = !wires.is_cut(WIRE_BOLTS)
	wire["lights"] = !wires.is_cut(WIRE_BOLTLIGHT)
	wire["safe"] = !wires.is_cut(WIRE_SAFETY)
	wire["timing"] = !wires.is_cut(WIRE_TIMING)

	data["wires"] = wire
	return data

/obj/machinery/door/airlock/ui_act(action, list/params, datum/tgui/ui, datum/ui_state/state)
	. = ..()
	if(.)
		return

	if(!user_allowed(usr))
		return
	switch(action)
		if("disrupt-main")
			if(!main_power_timer)
				loseMainPower()
				update_appearance()
			else
				to_chat(usr, span_warning("Main power is already offline."))
			. = TRUE
		if("disrupt-backup")
			if(!backup_power_timer)
				loseBackupPower()
				update_appearance()
			else
				to_chat(usr, span_warning("Backup power is already offline."))
			. = TRUE
		if("shock-restore")
			shock_restore(usr)
			. = TRUE
		if("shock-temp")
			shock_temp(usr)
			. = TRUE
		if("shock-perm")
			shock_perm(usr)
			. = TRUE
		if("idscan-toggle")
			aiDisabledIdScanner = !aiDisabledIdScanner
			. = TRUE
		if("emergency-toggle")
			toggle_emergency(usr)
			. = TRUE
		if("bolt-toggle")
			toggle_bolt(usr)
			. = TRUE
		if("light-toggle")
			lights = !lights
			update_appearance()
			. = TRUE
		if("safe-toggle")
			safe = !safe
			. = TRUE
		if("speed-toggle")
			normalspeed = !normalspeed
			. = TRUE
		if("open-close")
			user_toggle_open(usr)
			. = TRUE

/obj/machinery/door/airlock/proc/user_allowed(mob/user)
	return (HAS_SILICON_ACCESS(user) && canAIControl(user)) || isAdminGhostAI(user)

/obj/machinery/door/airlock/proc/shock_restore(mob/user)
	if(!user_allowed(user))
		return
	if(wires.is_cut(WIRE_SHOCK))
		to_chat(user, span_warning("Can't un-electrify the airlock - The electrification wire is cut."))
	else if(isElectrified())
		set_electrified(MACHINE_NOT_ELECTRIFIED, user)

/obj/machinery/door/airlock/proc/shock_temp(mob/user)
	if(!user_allowed(user))
		return
	if(wires.is_cut(WIRE_SHOCK))
		to_chat(user, span_warning("The electrification wire has been cut."))
	else
		set_electrified(MACHINE_DEFAULT_ELECTRIFY_TIME, user)

/obj/machinery/door/airlock/proc/shock_perm(mob/user)
	if(!user_allowed(user))
		return
	if(wires.is_cut(WIRE_SHOCK))
		to_chat(user, span_warning("The electrification wire has been cut."))
	else
		set_electrified(MACHINE_ELECTRIFIED_PERMANENT, user)

/obj/machinery/door/airlock/proc/toggle_bolt(mob/user)
	if(!user_allowed(user))
		return
	if(wires.is_cut(WIRE_BOLTS))
		to_chat(user, span_warning("The door bolt drop wire is cut - you can't toggle the door bolts."))
		return
	if(locked)
		if(!hasPower())
			to_chat(user, span_warning("The door has no power - you can't raise the door bolts."))
		else
			unbolt()
			log_combat(user, src, "unbolted")
	else
		bolt()
		log_combat(user, src, "bolted")

/obj/machinery/door/airlock/proc/toggle_emergency(mob/user)
	if(!user_allowed(user))
		return
	emergency = !emergency
	update_appearance()

/obj/machinery/door/airlock/proc/user_toggle_open(mob/user)
	if(!user_allowed(user))
		return
	if(welded)
		to_chat(user, span_warning("The airlock has been welded shut!"))
	else if(locked)
		to_chat(user, span_warning("The door bolts are down!"))
	else if(!density)
		close()
	else
		open()

/**
 * Generates the airlock's wire layout based on the current area the airlock resides in.
 *
 * Returns a new /datum/wires/ with the appropriate wire layout based on the airlock_wires
 * of the area the airlock is in.
 */
/obj/machinery/door/airlock/proc/get_wires()
	var/area/source_area = get_area(src)
	return source_area?.airlock_wires ? new source_area.airlock_wires(src) : new /datum/wires/airlock(src)

/obj/structure/fluff/airlock_filler/Destroy(force)
	filled_airlock = null
	return ..()

/**
 * Create a ref to our parent airlock and listen for a QDEL, which we will al
 */
/obj/structure/fluff/airlock_filler/proc/pair_airlock(obj/machinery/door/parent_airlock)
	if(isnull(parent_airlock))
		stack_trace("Attempted to pair an airlock filler with no parent airlock specified!")
		return

	filled_airlock = parent_airlock
	RegisterSignal(filled_airlock, COMSIG_QDELETING, PROC_REF(no_airlock))

/**
 * Multi-tile airlocks pair with a filler panel, if one goes so does the other.
 */
/obj/structure/fluff/airlock_filler/proc/no_airlock()
	SIGNAL_HANDLER

	qdel(src)

/**
 * Multi-tile airlocks (using a filler panel) have special handling for movables with PASSGLASS
 */
/obj/structure/fluff/airlock_filler/CanAllowThrough(atom/movable/mover, turf/target)
	. = ..()
	if(.)
		return

	if(istype(mover) && (mover.pass_flags & PASSGLASS))
		return !opacity

/obj/structure/fluff/airlock_filler/can_be_pulled(user, force)
	return FALSE

/obj/structure/fluff/airlock_filler/singularity_act()
	return

/obj/structure/fluff/airlock_filler/singularity_pull(atom/singularity, current_size)
	return

/obj/machinery/door/airlock/proc/set_cycle_pump(obj/machinery/atmospherics/components/unary/airlock_pump/pump)
	RegisterSignal(pump, COMSIG_QDELETING, PROC_REF(unset_cycle_pump))
	cycle_pump = pump

/obj/machinery/door/airlock/proc/unset_cycle_pump()
	SIGNAL_HANDLER
	if(locked)
		unbolt()
		say("Link broken, unbolting.")
	cycle_pump = null

// Station Airlocks Regular

/obj/machinery/door/airlock/command
	name = "command airlock"
	icon = 'icons/obj/doors/airlocks/station/command.dmi'
	assemblytype = /obj/structure/door_assembly/door_assembly_com
	normal_integrity = 450

/obj/machinery/door/airlock/security
	name = "security airlock"
	icon = 'icons/obj/doors/airlocks/station/security.dmi'
	var/id = null
	assemblytype = /obj/structure/door_assembly/door_assembly_sec
	normal_integrity = 450

/obj/machinery/door/airlock/engineering
	name = "engineering airlock"
	icon = 'icons/obj/doors/airlocks/station/engineering.dmi'
	assemblytype = /obj/structure/door_assembly/door_assembly_eng

/obj/machinery/door/airlock/medical
	name = "medical airlock"
	icon = 'icons/obj/doors/airlocks/station/medical.dmi'
	assemblytype = /obj/structure/door_assembly/door_assembly_med

/obj/machinery/door/airlock/hydroponics	//Hydroponics front doors!
	name = "hydroponics airlock"
	icon = 'icons/obj/doors/airlocks/station/hydroponics.dmi'
	assemblytype = /obj/structure/door_assembly/door_assembly_hydro

/obj/machinery/door/airlock/maintenance
	name = "maintenance access"
	icon = 'icons/obj/doors/airlocks/station/maintenance.dmi'
	assemblytype = /obj/structure/door_assembly/door_assembly_mai
	normal_integrity = 250

/obj/machinery/door/airlock/maintenance/external
	name = "external airlock access"
	icon = 'icons/obj/doors/airlocks/station/maintenanceexternal.dmi'
	assemblytype = /obj/structure/door_assembly/door_assembly_extmai

/obj/machinery/door/airlock/mining
	name = "mining airlock"
	icon = 'icons/obj/doors/airlocks/station/mining.dmi'
	assemblytype = /obj/structure/door_assembly/door_assembly_min

/obj/machinery/door/airlock/atmos
	name = "atmospherics airlock"
	icon = 'icons/obj/doors/airlocks/station/atmos.dmi'
	assemblytype = /obj/structure/door_assembly/door_assembly_atmo

/obj/machinery/door/airlock/research
	name = "research airlock"
	icon = 'icons/obj/doors/airlocks/station/research.dmi'
	assemblytype = /obj/structure/door_assembly/door_assembly_research

/obj/machinery/door/airlock/freezer
	name = "freezer airlock"
	icon = 'icons/obj/doors/airlocks/station/freezer.dmi'
	assemblytype = /obj/structure/door_assembly/door_assembly_fre
	can_be_glass = FALSE

/obj/machinery/door/airlock/science
	name = "science airlock"
	icon = 'icons/obj/doors/airlocks/station/science.dmi'
	assemblytype = /obj/structure/door_assembly/door_assembly_science

/obj/machinery/door/airlock/virology
	name = "virology airlock"
	icon = 'icons/obj/doors/airlocks/station/virology.dmi'
	assemblytype = /obj/structure/door_assembly/door_assembly_viro

// Station Airlocks Glass

/obj/machinery/door/airlock/glass
	name = "glass airlock"
	opacity = FALSE
	glass = TRUE

/obj/machinery/door/airlock/glass/incinerator
	autoclose = FALSE
	heat_proof = TRUE
	req_access = list(ACCESS_SYNDICATE)

/obj/machinery/door/airlock/glass/incinerator/syndicatelava_interior
	name = "Turbine Interior Airlock"
	id_tag = INCINERATOR_SYNDICATELAVA_AIRLOCK_INTERIOR

/obj/machinery/door/airlock/glass/incinerator/syndicatelava_exterior
	name = "Turbine Exterior Airlock"
	id_tag = INCINERATOR_SYNDICATELAVA_AIRLOCK_EXTERIOR

/obj/machinery/door/airlock/command/glass
	name = "command glass airlock"
	opacity = FALSE
	glass = TRUE
	normal_integrity = 400

/obj/machinery/door/airlock/engineering/glass
	name = "engineering glass airlock"
	opacity = FALSE
	glass = TRUE

/obj/machinery/door/airlock/engineering/glass/critical
	critical_machine = TRUE //stops greytide virus from opening & bolting doors in critical positions, such as the SM chamber.

/obj/machinery/door/airlock/security/glass
	name = "security glass airlock"
	opacity = FALSE
	glass = TRUE
	normal_integrity = 400

/obj/machinery/door/airlock/medical/glass
	name = "medical glass airlock"
	opacity = FALSE
	glass = TRUE

/obj/machinery/door/airlock/hydroponics/glass //Uses same icon as medical/glass, maybe update it with its own unique icon one day?
	name = "hydroponics glass airlock"
	opacity = FALSE
	glass = TRUE

/obj/machinery/door/airlock/research/glass
	name = "research glass airlock"
	opacity = FALSE
	glass = TRUE

/obj/machinery/door/airlock/research/glass/incinerator
	autoclose = FALSE
	heat_proof = TRUE

/obj/machinery/door/airlock/research/glass/incinerator/ordmix_interior
	name = "Mixing Room Interior Airlock"
	id_tag = INCINERATOR_ORDMIX_AIRLOCK_INTERIOR

/obj/machinery/door/airlock/research/glass/incinerator/ordmix_exterior
	name = "Mixing Room Exterior Airlock"
	id_tag = INCINERATOR_ORDMIX_AIRLOCK_EXTERIOR

/obj/machinery/door/airlock/mining/glass
	name = "mining glass airlock"
	opacity = FALSE
	glass = TRUE

/obj/machinery/door/airlock/atmos/glass
	name = "atmospheric glass airlock"
	opacity = FALSE
	glass = TRUE

/obj/machinery/door/airlock/atmos/glass/critical
	critical_machine = TRUE //stops greytide virus from opening & bolting doors in critical positions, such as the SM chamber.

/obj/machinery/door/airlock/science/glass
	name = "science glass airlock"
	opacity = FALSE
	glass = TRUE

/obj/machinery/door/airlock/virology/glass
	name = "virology glass airlock"
	opacity = FALSE
	glass = TRUE

/obj/machinery/door/airlock/maintenance/glass
	name = "maintenance glass airlock"
	opacity = FALSE
	glass = TRUE

/obj/machinery/door/airlock/maintenance/external/glass
	name = "maintenance external glass airlock"
	opacity = FALSE
	glass = TRUE
	normal_integrity = 200

// Station Airlocks Mineral

/obj/machinery/door/airlock/gold
	name = "gold airlock"
	icon = 'icons/obj/doors/airlocks/station/gold.dmi'
	assemblytype = /obj/structure/door_assembly/door_assembly_gold

/obj/machinery/door/airlock/gold/discoinferno
	heat_proof = TRUE
	resistance_flags = FIRE_PROOF
	armor_type = /datum/armor/discoinferno_airlock

/datum/armor/discoinferno_airlock
	melee = 30
	bullet = 30
	laser = 20
	energy = 20
	bomb = 10
	fire = 100
	acid = 100

/obj/machinery/door/airlock/gold/glass
	opacity = FALSE
	glass = TRUE

/obj/machinery/door/airlock/silver
	name = "silver airlock"
	icon = 'icons/obj/doors/airlocks/station/silver.dmi'
	assemblytype = /obj/structure/door_assembly/door_assembly_silver

/obj/machinery/door/airlock/silver/glass
	opacity = FALSE
	glass = TRUE

/obj/machinery/door/airlock/diamond
	name = "diamond airlock"
	icon = 'icons/obj/doors/airlocks/station/diamond.dmi'
	assemblytype = /obj/structure/door_assembly/door_assembly_diamond
	normal_integrity = 1000
	explosion_block = 2

/obj/machinery/door/airlock/diamond/glass
	normal_integrity = 950
	opacity = FALSE
	glass = TRUE

/obj/machinery/door/airlock/uranium
	name = "uranium airlock"
	icon = 'icons/obj/doors/airlocks/station/uranium.dmi'
	assemblytype = /obj/structure/door_assembly/door_assembly_uranium
	var/last_event = 0
	//Is this airlock actually radioactive?
	var/actually_radioactive = TRUE

/obj/machinery/door/airlock/uranium/process()
	if(actually_radioactive && world.time > last_event+20)
		if(prob(50))
			radiate()
		last_event = world.time

/obj/machinery/door/airlock/uranium/proc/radiate()
	radiation_pulse(
		src,
		max_range = 2,
		threshold = RAD_LIGHT_INSULATION,
		chance = URANIUM_IRRADIATION_CHANCE,
		minimum_exposure_time = URANIUM_RADIATION_MINIMUM_EXPOSURE_TIME,
	)

/obj/machinery/door/airlock/uranium/glass
	opacity = FALSE
	glass = TRUE

/obj/machinery/door/airlock/uranium/safe
	actually_radioactive = FALSE

/obj/machinery/door/airlock/uranium/glass/safe
	actually_radioactive = FALSE

/obj/machinery/door/airlock/plasma
	name = "plasma airlock"
	desc = "No way this can end badly."
	icon = 'icons/obj/doors/airlocks/station/plasma.dmi'
	assemblytype = /obj/structure/door_assembly/door_assembly_plasma
	material_flags = MATERIAL_EFFECTS
	material_modifier = 0.25

/obj/machinery/door/airlock/plasma/Initialize(mapload)
	custom_materials = custom_materials ? custom_materials : list(/datum/material/plasma = SHEET_MATERIAL_AMOUNT * 10)
	. = ..()

/obj/machinery/door/airlock/plasma/block_superconductivity() //we don't stop the heat~
	return 0

/obj/machinery/door/airlock/plasma/glass
	opacity = FALSE
	glass = TRUE

/obj/machinery/door/airlock/bananium
	name = "bananium airlock"
	desc = "Honkhonkhonk"
	icon = 'icons/obj/doors/airlocks/station/bananium.dmi'
	assemblytype = /obj/structure/door_assembly/door_assembly_bananium
	doorOpen = 'sound/items/bikehorn.ogg'

/obj/machinery/door/airlock/bananium/glass
	opacity = FALSE
	glass = TRUE

/obj/machinery/door/airlock/sandstone
	name = "sandstone airlock"
	icon = 'icons/obj/doors/airlocks/station/sandstone.dmi'
	assemblytype = /obj/structure/door_assembly/door_assembly_sandstone

/obj/machinery/door/airlock/sandstone/glass
	opacity = FALSE
	glass = TRUE

/obj/machinery/door/airlock/wood
	name = "wooden airlock"
	icon = 'icons/obj/doors/airlocks/station/wood.dmi'
	assemblytype = /obj/structure/door_assembly/door_assembly_wood

/obj/machinery/door/airlock/wood/glass
	opacity = FALSE
	glass = TRUE

/obj/machinery/door/airlock/titanium
	name = "shuttle airlock"
	assemblytype = /obj/structure/door_assembly/door_assembly_titanium
	icon = 'icons/obj/doors/airlocks/shuttle/shuttle.dmi'
	overlays_file = 'icons/obj/doors/airlocks/shuttle/overlays.dmi'
	normal_integrity = 400

/obj/machinery/door/airlock/titanium/glass
	normal_integrity = 350
	opacity = FALSE
	glass = TRUE

/obj/machinery/door/airlock/bronze
	name = "bronze airlock"
	icon = 'icons/obj/doors/airlocks/clockwork/pinion_airlock.dmi'
	overlays_file = 'icons/obj/doors/airlocks/clockwork/overlays.dmi'
	assemblytype = /obj/structure/door_assembly/door_assembly_bronze

/obj/machinery/door/airlock/bronze/seethru
	assemblytype = /obj/structure/door_assembly/door_assembly_bronze/seethru
	opacity = FALSE
	glass = TRUE


// Public Airlocks

/obj/machinery/door/airlock/public
	name = "public airlock"
	icon = 'icons/obj/doors/airlocks/public/glass.dmi'
	overlays_file = 'icons/obj/doors/airlocks/public/overlays.dmi'
	assemblytype = /obj/structure/door_assembly/door_assembly_public

/obj/machinery/door/airlock/public/glass
	name = "public glass airlock"
	opacity = FALSE
	glass = TRUE

/obj/machinery/door/airlock/public/glass/incinerator
	autoclose = FALSE
	heat_proof = TRUE

/obj/machinery/door/airlock/public/glass/incinerator/atmos_interior
	name = "Turbine Interior Airlock"
	id_tag = INCINERATOR_ATMOS_AIRLOCK_INTERIOR

/obj/machinery/door/airlock/public/glass/incinerator/atmos_exterior
	name = "Turbine Exterior Airlock"
	id_tag = INCINERATOR_ATMOS_AIRLOCK_EXTERIOR

// External Airlocks

/obj/machinery/door/airlock/external
	name = "external airlock"
	icon = 'icons/obj/doors/airlocks/external/external.dmi'
	overlays_file = 'icons/obj/doors/airlocks/external/overlays.dmi'
	note_overlay_file = 'icons/obj/doors/airlocks/external/overlays.dmi'
	assemblytype = /obj/structure/door_assembly/door_assembly_ext

	/// Whether or not the airlock can be opened without access from a certain direction while powered, or with bare hands from any direction while unpowered OR pressurized.
	var/space_dir = null

/obj/machinery/door/airlock/external/Initialize(mapload, ...)
	// default setting is for mapping only, let overrides work
	if(!mapload)
		req_access = null

	return ..()

/obj/machinery/door/airlock/external/post_machine_initialize()
	. = ..()
	if(space_dir)
		unres_sides |= space_dir

/obj/machinery/door/airlock/external/examine(mob/user)
	. = ..()
	if(space_dir)
		. += span_notice("It has labels indicating that it has an emergency mechanism to open from the [dir2text(space_dir)] side with <b>just your hands</b> even if there's no power.")

/obj/machinery/door/airlock/external/cyclelinkairlock()
	. = ..()
	var/obj/machinery/door/airlock/external/cycle_linked_external_airlock = cyclelinkedairlock
	if(istype(cycle_linked_external_airlock))
		cycle_linked_external_airlock.space_dir |= space_dir
		space_dir |= cycle_linked_external_airlock.space_dir

/obj/machinery/door/airlock/external/try_safety_unlock(mob/user)
	if(space_dir && density)
		if(!hasPower())
			to_chat(user, span_notice("You begin unlocking the airlock safety mechanism..."))
			if(do_after(user, 15 SECONDS, target = src))
				try_to_crowbar(null, user, TRUE)
				return TRUE
		else
			// always open from the space side
			// get_dir(src, user) & space_dir, checked in unresricted_sides
			var/should_safety_open = shuttledocked || cyclelinkedairlock?.shuttledocked || is_safe_turf(get_step(src, space_dir), TRUE, FALSE)
			return try_to_activate_door(user, should_safety_open)

	return ..()

// Access free external airlocks
/obj/machinery/door/airlock/external/ruin

/obj/machinery/door/airlock/external/glass
	name = "external glass airlock"
	opacity = FALSE
	glass = TRUE

/obj/machinery/door/airlock/external/glass/ruin

// CentCom Airlocks

/obj/machinery/door/airlock/centcom //Use grunge as a station side version, as these have special effects related to them via phobias and such.
	icon = 'icons/obj/doors/airlocks/centcom/centcom.dmi'
	overlays_file = 'icons/obj/doors/airlocks/centcom/overlays.dmi'
	assemblytype = /obj/structure/door_assembly/door_assembly_centcom
	can_be_glass = FALSE
	normal_integrity = 1000
	security_level = 6
	explosion_block = 2

/obj/machinery/door/airlock/grunge
	icon = 'icons/obj/doors/airlocks/centcom/centcom.dmi'
	overlays_file = 'icons/obj/doors/airlocks/centcom/overlays.dmi'
	assemblytype = /obj/structure/door_assembly/door_assembly_grunge
	can_be_glass = FALSE


// Vault Airlocks

/obj/machinery/door/airlock/vault
	name = "vault door"
	icon = 'icons/obj/doors/airlocks/vault/vault.dmi'
	overlays_file = 'icons/obj/doors/airlocks/vault/overlays.dmi'
	assemblytype = /obj/structure/door_assembly/door_assembly_vault
	can_be_glass = FALSE
	explosion_block = 2
	normal_integrity = 400 // reverse engieneerd: 400 * 1.5 (sec lvl 6) = 600 = original
	security_level = 6


// Hatch Airlocks

/obj/machinery/door/airlock/hatch
	name = "airtight hatch"
	icon = 'icons/obj/doors/airlocks/hatch/centcom.dmi'
	overlays_file = 'icons/obj/doors/airlocks/hatch/overlays.dmi'
	note_overlay_file = 'icons/obj/doors/airlocks/hatch/overlays.dmi'
	assemblytype = /obj/structure/door_assembly/door_assembly_hatch
	can_be_glass = FALSE

/obj/machinery/door/airlock/maintenance_hatch
	name = "maintenance hatch"
	icon = 'icons/obj/doors/airlocks/hatch/maintenance.dmi'
	overlays_file = 'icons/obj/doors/airlocks/hatch/overlays.dmi'
	note_overlay_file = 'icons/obj/doors/airlocks/hatch/overlays.dmi'
	assemblytype = /obj/structure/door_assembly/door_assembly_mhatch
	can_be_glass = FALSE

// High Security Airlocks

/obj/machinery/door/airlock/highsecurity
	name = "high tech security airlock"
	icon = 'icons/obj/doors/airlocks/highsec/highsec.dmi'
	overlays_file = 'icons/obj/doors/airlocks/highsec/overlays.dmi'
	assemblytype = /obj/structure/door_assembly/door_assembly_highsecurity
	can_be_glass = FALSE
	explosion_block = 2
	normal_integrity = 500
	security_level = 1
	damage_deflection = 30

// Shuttle Airlocks

/obj/machinery/door/airlock/shuttle
	name = "shuttle airlock"
	icon = 'icons/obj/doors/airlocks/shuttle/shuttle.dmi'
	overlays_file = 'icons/obj/doors/airlocks/shuttle/overlays.dmi'
	assemblytype = /obj/structure/door_assembly/door_assembly_shuttle

/obj/machinery/door/airlock/shuttle/glass
	opacity = FALSE
	glass = TRUE

/obj/machinery/door/airlock/abductor
	name = "alien airlock"
	desc = "With humanity's current technological level, it could take years to hack this advanced airlock... or maybe we should give a screwdriver a try?"
	icon = 'icons/obj/doors/airlocks/abductor/abductor_airlock.dmi'
	overlays_file = 'icons/obj/doors/airlocks/abductor/overlays.dmi'
	assemblytype = /obj/structure/door_assembly/door_assembly_abductor
	can_be_glass = FALSE
	note_overlay_file = 'icons/obj/doors/airlocks/external/overlays.dmi'
	damage_deflection = 30
	explosion_block = 3
	hackProof = TRUE
	aiControlDisabled = AI_WIRE_DISABLED
	normal_integrity = 700
	security_level = 1

// Cult Airlocks

/obj/machinery/door/airlock/cult
	name = "cult airlock"
	icon = 'icons/obj/doors/airlocks/cult/runed/cult.dmi'
	overlays_file = 'icons/obj/doors/airlocks/cult/runed/overlays.dmi'
	assemblytype = /obj/structure/door_assembly/door_assembly_cult
	hackProof = TRUE
	aiControlDisabled = AI_WIRE_DISABLED
	req_access = list(ACCESS_BLOODCULT)
	damage_deflection = 10
	var/openingoverlaytype = /obj/effect/temp_visual/cult/door
	var/friendly = FALSE
	var/stealthy = FALSE

/obj/machinery/door/airlock/cult/Initialize(mapload)
	. = ..()
	new openingoverlaytype(loc)
	AddElement(/datum/element/empprotection, EMP_PROTECT_ALL)

/obj/machinery/door/airlock/cult/canAIControl(mob/user)
	return (IS_CULTIST(user) && !isAllPowerCut())

/obj/machinery/door/airlock/cult/on_break()
	set_panel_open(TRUE)

/obj/machinery/door/airlock/cult/isElectrified()
	return FALSE

/obj/machinery/door/airlock/cult/hasPower()
	return TRUE

/obj/machinery/door/airlock/cult/allowed(mob/living/L)
	if(!density)
		return TRUE
	if(friendly || IS_CULTIST(L) || isshade(L) || isconstruct(L))
		if(!stealthy)
			new openingoverlaytype(loc)
		return TRUE
	else
		if(!stealthy)
			new /obj/effect/temp_visual/cult/sac(loc)
			var/atom/throwtarget
			throwtarget = get_edge_target_turf(src, get_dir(src, get_step_away(L, src)))
			SEND_SOUND(L, sound(SFX_HALLUCINATION_TURN_AROUND,0,1,50))
			flash_color(L, flash_color=COLOR_CULT_RED, flash_time=20)
			L.Paralyze(40)
			L.throw_at(throwtarget, 5, 1)
		return FALSE

/obj/machinery/door/airlock/cult/proc/conceal()
	icon = 'icons/obj/doors/airlocks/station/maintenance.dmi'
	overlays_file = 'icons/obj/doors/airlocks/station/overlays.dmi'
	name = "Airlock"
	desc = "It opens and closes."
	stealthy = TRUE
	update_appearance()

/obj/machinery/door/airlock/cult/proc/reveal()
	icon = initial(icon)
	overlays_file = initial(overlays_file)
	name = initial(name)
	desc = initial(desc)
	stealthy = initial(stealthy)
	update_appearance()

/obj/machinery/door/airlock/cult/narsie_act()
	return

/obj/machinery/door/airlock/cult/friendly
	friendly = TRUE

/obj/machinery/door/airlock/cult/glass
	glass = TRUE
	opacity = FALSE

/obj/machinery/door/airlock/cult/glass/friendly
	friendly = TRUE

/obj/machinery/door/airlock/cult/unruned
	icon = 'icons/obj/doors/airlocks/cult/unruned/cult.dmi'
	overlays_file = 'icons/obj/doors/airlocks/cult/unruned/overlays.dmi'
	assemblytype = /obj/structure/door_assembly/door_assembly_cult/unruned
	openingoverlaytype = /obj/effect/temp_visual/cult/door/unruned

/obj/machinery/door/airlock/cult/unruned/friendly
	friendly = TRUE

/obj/machinery/door/airlock/cult/unruned/glass
	glass = TRUE
	opacity = FALSE

/obj/machinery/door/airlock/cult/unruned/glass/friendly
	friendly = TRUE

/obj/machinery/door/airlock/cult/weak
	name = "brittle cult airlock"
	desc = "An airlock hastily corrupted by blood magic, it is unusually brittle in this state."
	normal_integrity = 150
	damage_deflection = 5
	armor_type = /datum/armor/none

// Material Airlocks

/obj/machinery/door/airlock/material
	name = "Airlock"
	material_flags = MATERIAL_EFFECTS | MATERIAL_ADD_PREFIX | MATERIAL_GREYSCALE | MATERIAL_AFFECT_STATISTICS
	greyscale_config = /datum/greyscale_config/material_airlock
	assemblytype = /obj/structure/door_assembly/door_assembly_material

/obj/machinery/door/airlock/material/close(forced, force_crush)
	. = ..()
	if(!.)
		return
	for(var/datum/material/mat in custom_materials)
		if(mat.alpha < 255)
			set_opacity(FALSE)
			break

/obj/machinery/door/airlock/material/prepare_deconstruction_assembly(obj/structure/door_assembly/assembly)
	assembly.set_custom_materials(custom_materials)
	..()

/obj/machinery/door/airlock/material/glass
	opacity = FALSE
	glass = TRUE

// Multi-tile (Large) Airlocks

/obj/machinery/door/airlock/multi_tile
	icon = 'icons/obj/doors/airlocks/multi_tile/public/glass.dmi'
	overlays_file = 'icons/obj/doors/airlocks/multi_tile/public/overlays.dmi'
	assemblytype = /obj/structure/door_assembly/multi_tile/door_assembly_public
	multi_tile = TRUE
	opacity = FALSE
	glass = TRUE

/obj/machinery/door/airlock/multi_tile/setDir(newdir)
	. = ..()
	set_bounds()

/obj/structure/fluff/airlock_filler
	name = "airlock fluff"
	desc = "You shouldn't be able to see this fluff!"
	icon = null
	icon_state = null
	density = TRUE
	opacity = TRUE
	anchored = TRUE
	invisibility = INVISIBILITY_MAXIMUM
	can_atmos_pass = ATMOS_PASS_DENSITY
	/// The door/airlock this fluff panel is attached to
	var/obj/machinery/door/filled_airlock

/obj/machinery/door/airlock/multi_tile/public/glass

/obj/machinery/door/airlock/multi_tile/narsie_act()
	return

/*
 * Subtype used in unit tests to ensure instant airlock opening/closing.
 *
 * Pretty much just excises everything that would delay the process or is un-needed
 * for the sake of the test (sleeps, icon animations).
*/
/obj/machinery/door/airlock/instant

// set_density on both open and close procs has a check and return builtin.

/obj/machinery/door/airlock/instant/open(forced = DEFAULT_DOOR_CHECKS)
	operating = TRUE
	SEND_SIGNAL(src, COMSIG_AIRLOCK_OPEN, forced)
	set_density(FALSE)
	operating = FALSE
	return TRUE

/obj/machinery/door/airlock/instant/close(forced = DEFAULT_DOOR_CHECKS, force_crush = FALSE)
	operating = TRUE
	SEND_SIGNAL(src, COMSIG_AIRLOCK_CLOSE, forced)
	set_density(TRUE)
	operating = FALSE
	return TRUE

#undef AIRLOCK_SECURITY_NONE
#undef AIRLOCK_SECURITY_IRON
#undef AIRLOCK_SECURITY_PLASTEEL_I_S
#undef AIRLOCK_SECURITY_PLASTEEL_I
#undef AIRLOCK_SECURITY_PLASTEEL_O_S
#undef AIRLOCK_SECURITY_PLASTEEL_O
#undef AIRLOCK_SECURITY_PLASTEEL

#undef AIRLOCK_INTEGRITY_N
#undef AIRLOCK_INTEGRITY_MULTIPLIER
#undef AIRLOCK_SEAL_MULTIPLIER
#undef AIRLOCK_DAMAGE_DEFLECTION_N
#undef AIRLOCK_DAMAGE_DEFLECTION_R

#undef AIRLOCK_DENY_ANIMATION_TIME

#undef DOOR_CLOSE_WAIT

#undef DOOR_VISION_DISTANCE

#undef AIRLOCK_FRAME_CLOSED
#undef AIRLOCK_FRAME_CLOSING
#undef AIRLOCK_FRAME_OPEN
#undef AIRLOCK_FRAME_OPENING
