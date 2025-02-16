#define TRAM_DOOR_WARNING_TIME (0.9 SECONDS)
#define TRAM_DOOR_CYCLE_TIME (0.6 SECONDS)
#define TRAM_DOOR_CRUSH_TIME (0.7 SECONDS)
#define TRAM_DOOR_RECYCLE_TIME (2.7 SECONDS)

/obj/machinery/door/airlock/tram
	name = "tram door"
	icon = 'icons/obj/doors/airlocks/tram/tram.dmi'
	overlays_file = 'icons/obj/doors/airlocks/tram/tram-overlays.dmi'
	multi_tile = TRUE
	opacity = FALSE
	assemblytype = /obj/structure/door_assembly/multi_tile/door_assembly_tram
	can_be_glass = FALSE
	airlock_material = "glass"
	air_tight = TRUE
	req_access = list(ACCESS_TCOMMS)
	transport_linked_id = TRAMSTATION_LINE_1
	doorOpen = 'sound/machines/tram/tramopen.ogg'
	doorClose = 'sound/machines/tram/tramclose.ogg'
	autoclose = FALSE
	/// Weakref to the tram we're attached
	var/datum/weakref/transport_ref
	var/retry_counter
	var/crushing_in_progress = FALSE
	bound_width = 64

/obj/machinery/door/airlock/tram/Initialize(mapload)
	. = ..()
	if(!id_tag)
		id_tag = assign_random_name()

/obj/machinery/door/airlock/tram/open(forced = DEFAULT_DOOR_CHECKS)
	if(operating || welded || locked || seal)
		return FALSE

	if(!density)
		return TRUE

	if(forced == DEFAULT_DOOR_CHECKS && (!hasPower() || wires.is_cut(WIRE_OPEN)))
		return FALSE

	SEND_SIGNAL(src, COMSIG_AIRLOCK_OPEN, FALSE)
	operating = TRUE
	update_icon(ALL, AIRLOCK_OPENING, TRUE)

	if(forced >= BYPASS_DOOR_CHECKS)
		playsound(src, 'sound/machines/airlock/airlockforced.ogg', vol = 40, vary = FALSE)
		sleep(TRAM_DOOR_CYCLE_TIME)
	else
		playsound(src, doorOpen, vol = 40, vary = FALSE)
		sleep(TRAM_DOOR_WARNING_TIME)

	set_density(FALSE)
	if(!isnull(filler))
		filler.set_density(FALSE)
	update_freelook_sight()
	flags_1 &= ~PREVENT_CLICK_UNDER_1
	air_update_turf(TRUE, FALSE)
	sleep(TRAM_DOOR_WARNING_TIME)
	layer = OPEN_DOOR_LAYER
	update_icon(ALL, AIRLOCK_OPEN, TRUE)
	operating = FALSE

	return TRUE

/obj/machinery/door/airlock/tram/close(forced = DEFAULT_DOOR_CHECKS, force_crush = FALSE)
	retry_counter++
	if(retry_counter >= 3 || force_crush || forced == BYPASS_DOOR_CHECKS)
		try_to_close(forced = BYPASS_DOOR_CHECKS)
		return

	if(retry_counter == 1)
		playsound(src, 'sound/machines/chime.ogg', 40, vary = FALSE, extrarange = SHORT_RANGE_SOUND_EXTRARANGE)

	addtimer(CALLBACK(src, PROC_REF(verify_status)), TRAM_DOOR_RECYCLE_TIME)
	try_to_close()

/**
 * Perform a close attempt and report TRUE/FALSE if it worked
 *
 * Arguments:
 * * rapid - boolean: if TRUE will skip safety checks and crush whatever is in the way
 */
/obj/machinery/door/airlock/tram/proc/try_to_close(forced = DEFAULT_DOOR_CHECKS)
	if(operating || welded || locked || seal)
		return FALSE
	if(density)
		return TRUE
	crushing_in_progress = TRUE
	var/hungry_door = (forced == BYPASS_DOOR_CHECKS || !safe)
	if((obj_flags & EMAGGED) || !safe)
		do_sparks(3, TRUE, src)
		playsound(src, SFX_SPARKS, vol = 75, vary = FALSE, extrarange = SHORT_RANGE_SOUND_EXTRARANGE)
	use_energy(50 JOULES)
	playsound(src, doorClose, vol = 40, vary = FALSE)
	operating = TRUE
	layer = CLOSED_DOOR_LAYER
	update_icon(ALL, AIRLOCK_CLOSING, 1)
	sleep(TRAM_DOOR_WARNING_TIME)
	if(!hungry_door)
		for(var/turf/checked_turf in locs)
			for(var/atom/movable/blocker in checked_turf)
				if(blocker.density && blocker != src) //something is blocking the door
					say("Please stand clear of the doors!")
					playsound(src, 'sound/machines/buzz/buzz-sigh.ogg', 60, vary = FALSE, extrarange = SHORT_RANGE_SOUND_EXTRARANGE)
					layer = OPEN_DOOR_LAYER
					update_icon(ALL, AIRLOCK_OPEN, 1)
					operating = FALSE
					return FALSE
	SEND_SIGNAL(src, COMSIG_AIRLOCK_CLOSE)
	sleep(TRAM_DOOR_CRUSH_TIME)
	set_density(TRUE)
	if(!isnull(filler))
		filler.set_density(TRUE)
	update_freelook_sight()
	flags_1 |= PREVENT_CLICK_UNDER_1
	air_update_turf(TRUE, TRUE)
	crush()
	crushing_in_progress = FALSE
	sleep(TRAM_DOOR_WARNING_TIME)
	update_icon(ALL, AIRLOCK_CLOSED, 1)
	operating = FALSE
	retry_counter = 0
	return TRUE

/**
 * Crush the jerk holding up the tram from moving
 *
 * Tram doors need their own crush proc because the normal one
 * leaves you stunned far too long, leading to the doors crushing
 * you over and over, no escape!
 *
 * While funny to watch, not ideal for the player.
 */
/obj/machinery/door/airlock/tram/crush()
	for(var/turf/checked_turf in locs)
		for(var/mob/living/future_pancake in checked_turf)
			future_pancake.visible_message(span_warning("[src] beeps angrily and closes on [future_pancake]!"), span_userdanger("[src] beeps angrily and closes on you!"))
			SEND_SIGNAL(future_pancake, COMSIG_LIVING_DOORCRUSHED, src)
			if(ishuman(future_pancake))
				future_pancake.emote("scream")
				future_pancake.adjustBruteLoss(DOOR_CRUSH_DAMAGE * 2)
				future_pancake.Paralyze(2 SECONDS)

			else //for simple_animals & borgs
				future_pancake.adjustBruteLoss(DOOR_CRUSH_DAMAGE * 2)
				var/turf/location = get_turf(src)
				//add_blood doesn't work for borgs/xenos, but add_blood_floor does.
				future_pancake.add_splatter_floor(location)

			log_combat(src, future_pancake, "crushed")

		for(var/obj/vehicle/sealed/mecha/mech in checked_turf) // Your fancy metal won't save you here!
			mech.take_damage(DOOR_CRUSH_DAMAGE)
			log_combat(src, mech, "crushed")

/**
 * Checks if the door close action was successful. Retries if it failed
 *
 * If some jerk is blocking the doors, they've had enough warning by attempt 3,
 * take a chunk of skin, people have places to be!
 */
/obj/machinery/door/airlock/tram/proc/verify_status()
	if(airlock_state == AIRLOCK_CLOSED)
		return

	if(retry_counter < 2)
		close()
		return

	playsound(src, 'sound/machines/buzz/buzz-two.ogg', 60, vary = FALSE, extrarange = SHORT_RANGE_SOUND_EXTRARANGE)
	say("YOU'RE HOLDING UP THE TRAM, ASSHOLE!")
	close(forced = BYPASS_DOOR_CHECKS)

/**
 * Set the weakref for the tram we're attached to
 */
/obj/machinery/door/airlock/tram/proc/find_tram()
	for(var/datum/transport_controller/linear/tram/tram as anything in SStransport.transports_by_type[TRANSPORT_TYPE_TRAM])
		if(tram.specific_transport_id == transport_linked_id)
			transport_ref = WEAKREF(tram)

/obj/machinery/door/airlock/tram/Initialize(mapload, set_dir, unres_sides)
	. = ..()
	RemoveElement(/datum/element/atmos_sensitive, mapload)
	return INITIALIZE_HINT_LATELOAD

/obj/machinery/door/airlock/tram/post_machine_initialize()
	. = ..()
	INVOKE_ASYNC(src, PROC_REF(open))
	SStransport.doors += src
	find_tram()

/obj/machinery/door/airlock/tram/Destroy()
	SStransport.doors -= src
	return ..()

/**
 * Tram doors can be opened with hands when unpowered
 */
/obj/machinery/door/airlock/tram/examine(mob/user)
	. = ..()
	. += span_notice("It has an emergency mechanism to open using [EXAMINE_HINT("just your hands")] in the event of an emergency.")

/**
 * Tram doors can be opened with hands when unpowered
 */
/obj/machinery/door/airlock/tram/try_safety_unlock(mob/user)
	if(DOING_INTERACTION_WITH_TARGET(user, src))
		return

	if(!hasPower()  && density)
		balloon_alert(user, "pulling emergency exit...")
		if(do_after(user, 4 SECONDS, target = src))
			try_to_crowbar(null, user, TRUE)
			return TRUE

/**
 * If you pry (bump) the doors open midtravel, open quickly so you can jump out and make a daring escape.
 */
/obj/machinery/door/airlock/tram/bumpopen(mob/user, forced = BYPASS_DOOR_CHECKS)
	if(DOING_INTERACTION_WITH_TARGET(user, src))
		return

	if(operating || !density)
		return

	if(!hasPower())
		try_safety_unlock(user)
		return

	var/datum/transport_controller/linear/tram/tram_part = transport_ref?.resolve()
	add_fingerprint(user)
	if(!tram_part.controller_active)
		return
	if((tram_part.travel_remaining < DEFAULT_TRAM_LENGTH || tram_part.travel_remaining > tram_part.travel_trip_length - DEFAULT_TRAM_LENGTH) && tram_part.controller_active)
		return // we're already animating, don't reset that
	open(forced = BYPASS_DOOR_CHECKS)
	return

#undef TRAM_DOOR_WARNING_TIME
#undef TRAM_DOOR_CYCLE_TIME
#undef TRAM_DOOR_CRUSH_TIME
#undef TRAM_DOOR_RECYCLE_TIME
