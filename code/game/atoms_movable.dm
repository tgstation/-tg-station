/atom/movable
	layer = OBJ_LAYER
	glide_size = 8
	appearance_flags = TILE_BOUND|PIXEL_SCALE|LONG_GLIDE

	var/last_move = null
	/// A list containing arguments for Moved().
	VAR_PRIVATE/tmp/list/active_movement
	var/anchored = FALSE
	var/move_resist = MOVE_RESIST_DEFAULT
	var/move_force = MOVE_FORCE_DEFAULT
	var/pull_force = PULL_FORCE_DEFAULT
	var/datum/thrownthing/throwing = null
	var/throw_speed = 2 //How many tiles to move per ds when being thrown. Float values are fully supported
	var/throw_range = 7
	///Max range this atom can be thrown via telekinesis
	var/tk_throw_range = 10
	var/mob/pulledby = null
	/// What language holder type to init as
	var/initial_language_holder = /datum/language_holder/atom_basic
	/// Holds all languages this mob can speak and understand
	VAR_PRIVATE/datum/language_holder/language_holder
	/// The list of factions this atom belongs to
	var/list/faction

	/// Use get_default_say_verb() in say.dm instead of reading verb_say.
	var/verb_say = "says"
	var/verb_ask = "asks"
	var/verb_exclaim = "exclaims"
	var/verb_whisper = "whispers"
	var/verb_sing = "sings"
	var/verb_yell = "yells"
	var/speech_span
	///Are we moving with inertia? Mostly used as an optimization
	var/inertia_moving = FALSE
	///Multiplier for inertia based movement in space
	var/inertia_move_multiplier = 1
	///Object "weight", higher weight reduces acceleration applied to the object
	var/inertia_force_weight = 1
	///The last time we pushed off something
	///This is a hack to get around dumb him him me scenarios
	var/last_pushoff
	/// Things we can pass through while moving. If any of this matches the thing we're trying to pass's [pass_flags_self], then we can pass through.
	var/pass_flags = NONE
	/// If false makes [CanPass][/atom/proc/CanPass] call [CanPassThrough][/atom/movable/proc/CanPassThrough] on this type instead of using default behaviour
	var/generic_canpass = TRUE
	///0: not doing a diagonal move. 1 and 2: doing the first/second step of the diagonal move
	var/moving_diagonally = 0
	///attempt to resume grab after moving instead of before.
	var/atom/movable/moving_from_pull
	///Holds information about any movement loops currently running/waiting to run on the movable. Lazy, will be null if nothing's going on
	var/datum/movement_packet/move_packet
	/**
	 * an associative lazylist of relevant nested contents by "channel", the list is of the form: list(channel = list(important nested contents of that type))
	 * each channel has a specific purpose and is meant to replace potentially expensive nested contents iteration.
	 * do NOT add channels to this for little reason as it can add considerable memory usage.
	 */
	var/list/important_recursive_contents
	///contains every client mob corresponding to every client eye in this container. lazily updated by SSparallax and is sparse:
	///only the last container of a client eye has this list assuming no movement since SSparallax's last fire
	var/list/client_mobs_in_contents

	/// String representing the spatial grid groups we want to be held in.
	/// acts as a key to the list of spatial grid contents types we exist in via SSspatial_grid.spatial_grid_categories.
	/// We do it like this to prevent people trying to mutate them and to save memory on holding the lists ourselves
	var/spatial_grid_key

	/**
	  * In case you have multiple types, you automatically use the most useful one.
	  * IE: Skating on ice, flippers on water, flying over chasm/space, etc.
	  * I recommend you use the movetype_handler system and not modify this directly, especially for living mobs.
	  */
	var/movement_type = GROUND

	var/atom/movable/pulling
	var/grab_state = GRAB_PASSIVE
	/// The strongest grab we can acomplish
	var/max_grab = GRAB_PASSIVE
	var/throwforce = 0
	var/datum/component/orbiter/orbiting

	///is the mob currently ascending or descending through z levels?
	var/currently_z_moving

	/// Either [EMISSIVE_BLOCK_NONE], [EMISSIVE_BLOCK_GENERIC], or [EMISSIVE_BLOCK_UNIQUE]
	var/blocks_emissive = EMISSIVE_BLOCK_NONE
	///Internal holder for emissive blocker object, do not use directly use blocks_emissive
	var/atom/movable/render_step/emissive_blocker/em_block

	///Used for the calculate_adjacencies proc for icon smoothing.
	var/can_be_unanchored = FALSE

	///Lazylist to keep track on the sources of illumination.
	var/list/affected_dynamic_lights
	///Highest-intensity light affecting us, which determines our visibility.
	var/affecting_dynamic_lumi = 0

	/// Whether this atom should have its dir automatically changed when it moves. Setting this to FALSE allows for things such as directional windows to retain dir on moving without snowflake code all of the place.
	var/set_dir_on_move = TRUE

	/// The degree of thermal insulation that mobs in list/contents have from the external environment, between 0 and 1
	var/contents_thermal_insulation = 0
	/// The degree of pressure protection that mobs in list/contents have from the external environment, between 0 and 1
	var/contents_pressure_protection = 0

	/// The voice that this movable makes when speaking
	var/voice

	/// The pitch adjustment that this movable uses when speaking.
	var/pitch = 0

	/// Datum that keeps all data related to zero-g drifting and handles related code/comsigs
	var/datum/drift_handler/drift_handler

	/// The filter to apply to the voice when processing the TTS audio message.
	var/voice_filter = ""

	/// Set to anything other than "" to activate the silicon voice effect for TTS messages.
	var/tts_silicon_voice_effect = ""

	/// Value used to increment ex_act() if reactionary_explosions is on
	/// How much we as a source block explosions by
	/// Will not automatically apply to the turf below you, you need to apply /datum/element/block_explosives in conjunction with this
	var/explosion_block = 0

	// Access levels, used in modules\jobs\access.dm
	/// List of accesses needed to use this object: The user must possess all accesses in this list in order to use the object.
	/// Example: If req_access = list(ACCESS_ENGINE, ACCESS_CE)- then the user must have both ACCESS_ENGINE and ACCESS_CE in order to use the object.
	var/list/req_access
	/// List of accesses needed to use this object: The user must possess at least one access in this list in order to use the object.
	/// Example: If req_one_access = list(ACCESS_ENGINE, ACCESS_CE)- then the user must have either ACCESS_ENGINE or ACCESS_CE in order to use the object.
	var/list/req_one_access

/mutable_appearance/emissive_blocker

/mutable_appearance/emissive_blocker/New()
	. = ..()
	// Need to do this here because it's overridden by the parent call
	color = EM_BLOCK_COLOR
	appearance_flags = EMISSIVE_APPEARANCE_FLAGS

/atom/movable/Initialize(mapload, ...)
	. = ..()
#ifdef UNIT_TESTS
	if(explosion_block && !HAS_TRAIT(src, TRAIT_BLOCKING_EXPLOSIVES))
		stack_trace("[type] blocks explosives, but does not have the managing element applied")
#endif

#if EMISSIVE_BLOCK_GENERIC != 0
	#error EMISSIVE_BLOCK_GENERIC is expected to be 0 to facilitate a weird optimization hack where we rely on it being the most common.
	#error Read the comment in code/game/atoms_movable.dm for details.
#endif

	// This one is incredible.
	// `if (x) else { /* code */ }` is surprisingly fast, and it's faster than a switch, which is seemingly not a jump table.
	// From what I can tell, a switch case checks every single branch individually, although sane, is slow in a hot proc like this.
	// So, we make the most common `blocks_emissive` value, EMISSIVE_BLOCK_GENERIC, 0, getting to the fast else branch quickly.
	// If it fails, then we can check over every value it can be (here, EMISSIVE_BLOCK_UNIQUE is the only one that matters).
	// This saves several hundred milliseconds of init time.
	if (blocks_emissive)
		if (blocks_emissive == EMISSIVE_BLOCK_UNIQUE)
			render_target = ref(src)
			em_block = new(null, src)
			overlays += em_block
			if(managed_overlays)
				if(islist(managed_overlays))
					managed_overlays += em_block
				else
					managed_overlays = list(managed_overlays, em_block)
			else
				managed_overlays = em_block
	else
		var/static/mutable_appearance/emissive_blocker/blocker = new()
		blocker.icon = icon
		blocker.icon_state = icon_state
		blocker.dir = dir
		blocker.appearance_flags |= appearance_flags
		blocker.plane = GET_NEW_PLANE(EMISSIVE_PLANE, PLANE_TO_OFFSET(plane))
		// Ok so this is really cursed, but I want to set with this blocker cheaply while
		// Still allowing it to be removed from the overlays list later
		// So I'm gonna flatten it, then insert the flattened overlay into overlays AND the managed overlays list, directly
		// I'm sorry
		var/mutable_appearance/flat = blocker.appearance
		overlays += flat
		if(managed_overlays)
			if(islist(managed_overlays))
				managed_overlays += flat
			else
				managed_overlays = list(managed_overlays, flat)
		else
			managed_overlays = flat

	if(opacity)
		AddElement(/datum/element/light_blocking)
	switch(light_system)
		if(OVERLAY_LIGHT)
			AddComponent(/datum/component/overlay_lighting)
		if(OVERLAY_LIGHT_DIRECTIONAL)
			AddComponent(/datum/component/overlay_lighting, is_directional = TRUE)
		if(OVERLAY_LIGHT_BEAM)
			AddComponent(/datum/component/overlay_lighting, is_directional = TRUE, is_beam = TRUE)

/atom/movable/Destroy(force)
	QDEL_NULL(language_holder)
	QDEL_NULL(em_block)
	QDEL_NULL(drift_handler)

	unbuckle_all_mobs(force = TRUE)

	if(loc)
		//Restore air flow if we were blocking it (movables with ATMOS_PASS_PROC will need to do this manually if necessary)
		if(((can_atmos_pass == ATMOS_PASS_DENSITY && density) || can_atmos_pass == ATMOS_PASS_NO) && isturf(loc))
			can_atmos_pass = ATMOS_PASS_YES
			air_update_turf(TRUE, FALSE)

	if(opacity)
		RemoveElement(/datum/element/light_blocking)

	invisibility = INVISIBILITY_ABSTRACT

	if(pulledby)
		pulledby.stop_pulling()
	if(pulling)
		stop_pulling()

	if(orbiting)
		orbiting.end_orbit(src)
		orbiting = null

	if(move_packet)
		if(!QDELETED(move_packet))
			qdel(move_packet)
		move_packet = null

	if(spatial_grid_key)
		SSspatial_grid.force_remove_from_grid(src)

	LAZYNULL(client_mobs_in_contents)

#ifndef DISABLE_DREAMLUAU
	// These lists cease existing when src does, so we need to clear any lua refs to them that exist.
	DREAMLUAU_CLEAR_REF_USERDATA(vis_contents)
	DREAMLUAU_CLEAR_REF_USERDATA(vis_locs)
#endif

	. = ..()

	for(var/movable_content in contents)
		qdel(movable_content)

	moveToNullspace()

	//This absolutely must be after moveToNullspace()
	//We rely on Entered and Exited to manage this list, and the copy of this list that is on any /atom/movable "Containers"
	//If we clear this before the nullspace move, a ref to this object will be hung in any of its movable containers
	LAZYNULL(important_recursive_contents)


	vis_locs = null //clears this atom out of all viscontents

	// Checking length(vis_contents) before cutting has significant speed benefits
	if (length(vis_contents))
		vis_contents.Cut()

/atom/movable/proc/update_emissive_block()
	// This one is incredible.
	// `if (x) else { /* code */ }` is surprisingly fast, and it's faster than a switch, which is seemingly not a jump table.
	// From what I can tell, a switch case checks every single branch individually, although sane, is slow in a hot proc like this.
	// So, we make the most common `blocks_emissive` value, EMISSIVE_BLOCK_GENERIC, 0, getting to the fast else branch quickly.
	// If it fails, then we can check over every value it can be (here, EMISSIVE_BLOCK_UNIQUE is the only one that matters).
	// This saves several hundred milliseconds of init time.
	if (blocks_emissive)
		if (blocks_emissive == EMISSIVE_BLOCK_UNIQUE)
			if(em_block)
				SET_PLANE(em_block, EMISSIVE_PLANE, src)
			else if(!QDELETED(src))
				render_target = ref(src)
				em_block = new(null, src)
			return em_block
		// Implied else if (blocks_emissive == EMISSIVE_BLOCK_NONE) -> return
	// EMISSIVE_BLOCK_GENERIC == 0
	else
		return fast_emissive_blocker(src)

/// Generates a space underlay for a turf
/// This provides proper lighting support alongside just looking nice
/// Accepts the appearance to make "spaceish", and the turf we're doing this for
/proc/generate_space_underlay(mutable_appearance/underlay_appearance, turf/generate_for)
	underlay_appearance.icon = 'icons/turf/space.dmi'
	underlay_appearance.icon_state = "space"
	SET_PLANE(underlay_appearance, PLANE_SPACE, generate_for)
	if(!generate_for.render_target)
		generate_for.render_target = ref(generate_for)
	var/atom/movable/render_step/emissive_blocker/em_block = new(null, generate_for)
	underlay_appearance.overlays += em_block
	// We used it because it's convienient and easy, but it's gotta go now or it'll hang refs
	QDEL_NULL(em_block)
	// We're gonna build a light, and mask it with the base turf's appearance
	// grab a 32x32 square of it
	// I would like to use GLOB.starbright_overlays here
	// But that breaks down for... some? reason. I think receiving a render relay breaks keep_together or something
	// So we're just gonna accept  that this'll break with starlight color changing. hardly matters since this is really only for offset stuff, but I'd love to fix it someday
	var/mutable_appearance/light = new(GLOB.starlight_objects[GET_TURF_PLANE_OFFSET(generate_for) + 1])
	light.render_target = ""
	light.appearance_flags |= KEEP_TOGETHER
	// Now apply a copy of the turf, set to multiply
	// This will multiply against our light, so we only light up the bits that aren't "on" the wall
	var/mutable_appearance/mask = new(generate_for.appearance)
	mask.blend_mode = BLEND_MULTIPLY
	mask.render_target = ""
	mask.pixel_x = 0
	mask.pixel_y = 0
	mask.pixel_w = 0
	mask.pixel_z = 0
	mask.transform = null
	mask.underlays = list() // Begone foul lighting overlay
	SET_PLANE(mask, FLOAT_PLANE, generate_for)
	mask.layer = FLOAT_LAYER

	// Bump the opacity to full, will this work?
	mask.color = list(0,0,0,0, 0,0,0,0, 0,0,0,0, 0,0,0,255, 0,0,0,0)
	light.overlays += mask
	underlay_appearance.overlays += light

	// Now, we're going to make a copy of the mask. Instead of using it to multiply against our light
	// We're going to use it to multiply against the turf lighting plane. Going to mask away the turf light
	// And rely on LIGHTING_MASK_LAYER to ensure we mask ONLY that bit
	var/mutable_appearance/turf_mask = new(mask.appearance)
	SET_PLANE(turf_mask, LIGHTING_PLANE, generate_for)
	turf_mask.layer = LIGHTING_MASK_LAYER
	/// Any color becomes white. Anything else is black, and it's fully opaque
	/// Ought to work
	turf_mask.color = list(255,255,255,0, 255,255,255,0, 255,255,255,0, 0,0,0,0, 0,0,0,255)
	underlay_appearance.overlays += turf_mask

/atom/movable/update_overlays()
	var/list/overlays = ..()
	var/emissive_block = update_emissive_block()
	if(emissive_block)
		// Emissive block should always go at the beginning of the list
		overlays.Insert(1, emissive_block)
	return overlays

/atom/movable/proc/onZImpact(turf/impacted_turf, levels, impact_flags = NONE)
	SHOULD_CALL_PARENT(TRUE)
	if(!(impact_flags & ZIMPACT_NO_MESSAGE))
		visible_message(
			span_danger("[src] crashes into [impacted_turf]!"),
			span_userdanger("You crash into [impacted_turf]!"),
		)
	if(!(impact_flags & ZIMPACT_NO_SPIN))
		INVOKE_ASYNC(src, PROC_REF(SpinAnimation), 5, 2)
	SEND_SIGNAL(src, COMSIG_ATOM_ON_Z_IMPACT, impacted_turf, levels)
	return TRUE

/*
 * Attempts to move using zMove if direction is UP or DOWN, step if not
 *
 * Args:
 * direction: The direction to go
 * z_move_flags: bitflags used for checks in zMove and can_z_move
*/
/atom/movable/proc/try_step_multiz(direction, z_move_flags = ZMOVE_FLIGHT_FLAGS)
	if(direction == UP || direction == DOWN)
		return zMove(direction, null, z_move_flags)
	return step(src, direction)

/*
 * The core multi-z movement proc. Used to move a movable through z levels.
 * If target is null, it'll be determined by the can_z_move proc, which can potentially return null if
 * conditions aren't met (see z_move_flags defines in __DEFINES/movement.dm for info) or if dir isn't set.
 * Bear in mind you don't need to set both target and dir when calling this proc, but at least one or two.
 * This will set the currently_z_moving to CURRENTLY_Z_MOVING_GENERIC if unset, and then clear it after
 * Forcemove().
 *
 *
 * Args:
 * * dir: the direction to go, UP or DOWN, only relevant if target is null.
 * * target: The target turf to move the src to. Set by can_z_move() if null.
 * * z_move_flags: bitflags used for various checks in both this proc and can_z_move(). See __DEFINES/movement.dm.
 */
/atom/movable/proc/zMove(dir, turf/target, z_move_flags = ZMOVE_FLIGHT_FLAGS)
	if(!target)
		target = can_z_move(dir, get_turf(src), null, z_move_flags)
		if(!target)
			set_currently_z_moving(FALSE, TRUE)
			return FALSE

	var/list/moving_movs = get_z_move_affected(z_move_flags)

	for(var/atom/movable/movable as anything in moving_movs)
		movable.currently_z_moving = currently_z_moving || CURRENTLY_Z_MOVING_GENERIC
		movable.forceMove(target)
		movable.set_currently_z_moving(FALSE, TRUE)
	// This is run after ALL movables have been moved, so pulls don't get broken unless they are actually out of range.
	if(z_move_flags & ZMOVE_CHECK_PULLS)
		for(var/atom/movable/moved_mov as anything in moving_movs)
			if(z_move_flags & ZMOVE_CHECK_PULLEDBY && moved_mov.pulledby && (moved_mov.z != moved_mov.pulledby.z || get_dist(moved_mov, moved_mov.pulledby) > 1))
				moved_mov.pulledby.stop_pulling()
			if(z_move_flags & ZMOVE_CHECK_PULLING)
				moved_mov.check_pulling(TRUE)
	return TRUE

/// Returns a list of movables that should also be affected when src moves through zlevels, and src.
/atom/movable/proc/get_z_move_affected(z_move_flags)
	. = list(src)
	if(buckled_mobs)
		. |= buckled_mobs
	if(!(z_move_flags & ZMOVE_INCLUDE_PULLED))
		return
	for(var/mob/living/buckled as anything in buckled_mobs)
		if(buckled.pulling)
			. |= buckled.pulling
	if(pulling)
		. |= pulling
		if (pulling.buckled_mobs)
			. |= pulling.buckled_mobs

		//makes conga lines work with ladders and flying up and down; checks if the guy you are pulling is pulling someone,
		//then uses recursion to run the same function again
		if (pulling.pulling)
			. |= pulling.pulling.get_z_move_affected(z_move_flags)

/**
 * Checks if the destination turf is elegible for z movement from the start turf to a given direction and returns it if so.
 * Args:
 * * direction: the direction to go, UP or DOWN, only relevant if target is null.
 * * start: Each destination has a starting point on the other end. This is it. Most of the times the location of the source.
 * * z_move_flags: bitflags used for various checks. See __DEFINES/movement.dm.
 * * rider: A living mob in control of the movable. Only non-null when a mob is riding a vehicle through z-levels.
 */
/atom/movable/proc/can_z_move(direction, turf/start, turf/destination, z_move_flags = ZMOVE_FLIGHT_FLAGS, mob/living/rider)
	if(!start)
		start = get_turf(src)
		if(!start)
			return FALSE
	if(!direction)
		if(!destination)
			return FALSE
		direction = get_dir_multiz(start, destination)
	if(direction != UP && direction != DOWN)
		return FALSE
	if(!destination)
		destination = get_step_multiz(start, direction)
		if(!destination)
			if(z_move_flags & ZMOVE_FEEDBACK)
				to_chat(rider || src, span_warning("There's nowhere to go in that direction!"))
			return FALSE
	if(SEND_SIGNAL(src, COMSIG_CAN_Z_MOVE, start, destination) & COMPONENT_CANT_Z_MOVE)
		return FALSE
	if(z_move_flags & ZMOVE_FALL_CHECKS && (throwing || (movement_type & (FLYING|FLOATING)) || !has_gravity(start)))
		return FALSE
	if(z_move_flags & ZMOVE_CAN_FLY_CHECKS && !(movement_type & (FLYING|FLOATING)) && has_gravity(start))
		if(z_move_flags & ZMOVE_FEEDBACK)
			if(rider)
				to_chat(rider, span_warning("[src] [p_are()] incapable of flight."))
			else
				to_chat(src, span_warning("You are not Superman."))
		return FALSE
	if((!(z_move_flags & ZMOVE_IGNORE_OBSTACLES) && !(start.zPassOut(direction) && destination.zPassIn(direction))) || (!(z_move_flags & ZMOVE_ALLOW_ANCHORED) && anchored))
		if(z_move_flags & ZMOVE_FEEDBACK)
			to_chat(rider || src, span_warning("You couldn't move there!"))
		return FALSE
	return destination //used by some child types checks and zMove()

/atom/movable/vv_edit_var(var_name, var_value)
	var/static/list/banned_edits = list(NAMEOF_STATIC(src, step_x) = TRUE, NAMEOF_STATIC(src, step_y) = TRUE, NAMEOF_STATIC(src, step_size) = TRUE, NAMEOF_STATIC(src, bounds) = TRUE)
	var/static/list/careful_edits = list(NAMEOF_STATIC(src, bound_x) = TRUE, NAMEOF_STATIC(src, bound_y) = TRUE, NAMEOF_STATIC(src, bound_width) = TRUE, NAMEOF_STATIC(src, bound_height) = TRUE)
	var/static/list/not_falsey_edits = list(NAMEOF_STATIC(src, bound_width) = TRUE, NAMEOF_STATIC(src, bound_height) = TRUE)
	if(banned_edits[var_name])
		return FALSE //PLEASE no.
	if(careful_edits[var_name] && (var_value % ICON_SIZE_ALL) != 0)
		return FALSE
	if(not_falsey_edits[var_name] && !var_value)
		return FALSE

	switch(var_name)
		if(NAMEOF(src, x))
			var/turf/current_turf = locate(var_value, y, z)
			if(current_turf)
				admin_teleport(current_turf)
				return TRUE
			return FALSE
		if(NAMEOF(src, y))
			var/turf/T = locate(x, var_value, z)
			if(T)
				admin_teleport(T)
				return TRUE
			return FALSE
		if(NAMEOF(src, z))
			var/turf/T = locate(x, y, var_value)
			if(T)
				admin_teleport(T)
				return TRUE
			return FALSE
		if(NAMEOF(src, loc))
			if(isatom(var_value) || isnull(var_value))
				admin_teleport(var_value)
				return TRUE
			return FALSE
		if(NAMEOF(src, anchored))
			set_anchored(var_value)
			. = TRUE
		if(NAMEOF(src, pulledby))
			set_pulledby(var_value)
			. = TRUE
		if(NAMEOF(src, glide_size))
			set_glide_size(var_value)
			. = TRUE

	if(!isnull(.))
		datum_flags |= DF_VAR_EDITED
		return

	return ..()


/atom/movable/proc/start_pulling(atom/movable/pulled_atom, state, force = move_force, supress_message = FALSE)
	if(QDELETED(pulled_atom))
		return FALSE
	if(!(pulled_atom.can_be_pulled(src, force)))
		return FALSE

	// If we're pulling something then drop what we're currently pulling and pull this instead.
	if(pulling)
		if(state == 0)
			stop_pulling()
			return FALSE
		// Are we trying to pull something we are already pulling? Then enter grab cycle and end.
		if(pulled_atom == pulling)
			setGrabState(state)
			if(istype(pulled_atom,/mob/living))
				var/mob/living/pulled_mob = pulled_atom
				pulled_mob.grabbedby(src)
			return TRUE
		stop_pulling()

	if(pulled_atom.pulledby)
		log_combat(pulled_atom, pulled_atom.pulledby, "pulled from", src)
		pulled_atom.pulledby.stop_pulling() //an object can't be pulled by two mobs at once.
	pulling = pulled_atom
	pulled_atom.set_pulledby(src)
	SEND_SIGNAL(src, COMSIG_ATOM_START_PULL, pulled_atom, state, force)
	setGrabState(state)
	if(ismob(pulled_atom))
		var/mob/pulled_mob = pulled_atom
		log_combat(src, pulled_mob, "grabbed", addition="passive grab")
		if(!supress_message)
			pulled_mob.visible_message(span_warning("[src] grabs [pulled_mob] passively."), \
				span_danger("[src] grabs you passively."))
	return TRUE

/atom/movable/proc/stop_pulling()
	if(!pulling)
		return
	pulling.set_pulledby(null)
	setGrabState(GRAB_PASSIVE)
	var/atom/movable/old_pulling = pulling
	pulling = null
	SEND_SIGNAL(old_pulling, COMSIG_ATOM_NO_LONGER_PULLED, src)
	SEND_SIGNAL(src, COMSIG_ATOM_NO_LONGER_PULLING, old_pulling)

///Reports the event of the change in value of the pulledby variable.
/atom/movable/proc/set_pulledby(new_pulledby)
	if(new_pulledby == pulledby)
		return FALSE //null signals there was a change, be sure to return FALSE if none happened here.
	. = pulledby
	pulledby = new_pulledby


/atom/movable/proc/Move_Pulled(atom/moving_atom)
	if(!pulling)
		return FALSE
	if(pulling.anchored || pulling.move_resist > move_force || !pulling.Adjacent(src, src, pulling))
		stop_pulling()
		return FALSE
	if(isliving(pulling))
		var/mob/living/pulling_mob = pulling
		if(pulling_mob.buckled && pulling_mob.buckled.buckle_prevents_pull) //if they're buckled to something that disallows pulling, prevent it
			stop_pulling()
			return FALSE
	if(moving_atom == loc && pulling.density)
		return FALSE
	var/move_dir = get_dir(pulling.loc, moving_atom)
	if(!Process_Spacemove(move_dir))
		return FALSE
	pulling.Move(get_step(pulling.loc, move_dir), move_dir, glide_size)
	return TRUE

/mob/living/Move_Pulled(atom/moving_atom)
	. = ..()
	if(!. || !isliving(moving_atom))
		return
	var/mob/living/pulled_mob = moving_atom
	set_pull_offsets(pulled_mob, grab_state, animate = FALSE)

/**
 * Checks if the pulling and pulledby should be stopped because they're out of reach.
 * If z_allowed is TRUE, the z level of the pulling will be ignored.This is to allow things to be dragged up and down stairs.
 */
/atom/movable/proc/check_pulling(only_pulling = FALSE, z_allowed = FALSE)
	if(pulling)
		if(get_dist(src, pulling) > 1 || (z != pulling.z && !z_allowed))
			stop_pulling()
		else if(!isturf(loc))
			stop_pulling()
		else if(pulling && !isturf(pulling.loc) && pulling.loc != loc) //to be removed once all code that changes an object's loc uses forceMove().
			log_game("DEBUG:[src]'s pull on [pulling] wasn't broken despite [pulling] being in [pulling.loc]. Pull stopped manually.")
			stop_pulling()
		else if(pulling.anchored || pulling.move_resist > move_force)
			stop_pulling()
	if(!only_pulling && pulledby && moving_diagonally != FIRST_DIAG_STEP && (get_dist(src, pulledby) > 1 || (z != pulledby.z && !z_allowed))) //separated from our puller and not in the middle of a diagonal move.
		pulledby.stop_pulling()

/atom/movable/proc/set_glide_size(target = 8)
	if (HAS_TRAIT(src, TRAIT_NO_GLIDE))
		return
	SEND_SIGNAL(src, COMSIG_MOVABLE_UPDATE_GLIDE_SIZE, target)
	glide_size = target

	for(var/mob/buckled_mob as anything in buckled_mobs)
		buckled_mob.set_glide_size(target)

/**
 * meant for movement with zero side effects. only use for objects that are supposed to move "invisibly" (like eye mobs or ghosts)
 * if you want something to move onto a tile with a beartrap or recycler or tripmine or mouse without that object knowing about it at all, use this
 * most of the time you want forceMove()
 */
/atom/movable/proc/abstract_move(atom/new_loc)
	RESOLVE_ACTIVE_MOVEMENT // This should NEVER happen, but, just in case...
	var/atom/old_loc = loc
	var/direction = get_dir(old_loc, new_loc)
	loc = new_loc
	Moved(old_loc, direction, TRUE, momentum_change = FALSE)

////////////////////////////////////////
// Here's where we rewrite how byond handles movement except slightly different
// To be removed on step_ conversion
// All this work to prevent a second bump
/atom/movable/Move(atom/newloc, direction, glide_size_override = 0, update_dir = TRUE)
	. = FALSE
	if(!newloc || newloc == loc)
		return

	// A mid-movement... movement... occurred, resolve that first.
	RESOLVE_ACTIVE_MOVEMENT

	if(!direction)
		direction = get_dir(src, newloc)

	if(set_dir_on_move && dir != direction && update_dir)
		setDir(direction)

	var/is_multi_tile_object = is_multi_tile_object(src)

	var/list/old_locs
	if(is_multi_tile_object && isturf(loc))
		old_locs = locs // locs is a special list, this is effectively the same as .Copy() but with less steps
		for(var/atom/exiting_loc as anything in old_locs)
			if(!exiting_loc.Exit(src, direction))
				return
	else
		if(!loc.Exit(src, direction))
			return

	var/list/new_locs
	if(is_multi_tile_object && isturf(newloc))
		var/dx = newloc.x
		var/dy = newloc.y
		var/dz = newloc.z
		new_locs = block(
			dx, dy, dz,
			dx + ceil(bound_width / 32), dy + ceil(bound_height / 32), dz
		) // If this is a multi-tile object then we need to predict the new locs and check if they allow our entrance.
		for(var/atom/entering_loc as anything in new_locs)
			if(!entering_loc.Enter(src))
				return
			if(SEND_SIGNAL(src, COMSIG_MOVABLE_PRE_MOVE, entering_loc) & COMPONENT_MOVABLE_BLOCK_PRE_MOVE)
				return
	else // Else just try to enter the single destination.
		if(!newloc.Enter(src))
			return
		if(SEND_SIGNAL(src, COMSIG_MOVABLE_PRE_MOVE, newloc) & COMPONENT_MOVABLE_BLOCK_PRE_MOVE)
			return

	// Past this is the point of no return
	var/atom/oldloc = loc
	var/area/oldarea = get_area(oldloc)
	var/area/newarea = get_area(newloc)

	SET_ACTIVE_MOVEMENT(oldloc, direction, FALSE, old_locs)
	loc = newloc

	. = TRUE

	if(old_locs) // This condition will only be true if it is a multi-tile object.
		for(var/atom/exited_loc as anything in (old_locs - new_locs))
			exited_loc.Exited(src, direction)
	else // Else there's just one loc to be exited.
		oldloc.Exited(src, direction)
	if(oldarea != newarea)
		oldarea.Exited(src, direction)

	if(new_locs) // Same here, only if multi-tile.
		for(var/atom/entered_loc as anything in (new_locs - old_locs))
			entered_loc.Entered(src, oldloc, old_locs)
	else
		newloc.Entered(src, oldloc, old_locs)
	if(oldarea != newarea)
		newarea.Entered(src, oldarea)

	RESOLVE_ACTIVE_MOVEMENT

////////////////////////////////////////

/atom/movable/Move(atom/newloc, direct, glide_size_override = 0, update_dir = TRUE)
	var/atom/movable/pullee = pulling
	var/turf/current_turf = loc
	if(!moving_from_pull)
		check_pulling(z_allowed = TRUE)
	if(!loc || !newloc)
		return FALSE
	var/atom/oldloc = loc
	//Early override for some cases like diagonal movement
	if(glide_size_override && glide_size != glide_size_override)
		set_glide_size(glide_size_override)

	if(loc != newloc)
		if (!(direct & (direct - 1))) //Cardinal move
			. = ..()
		else //Diagonal move, split it into cardinal moves
			moving_diagonally = FIRST_DIAG_STEP
			var/first_step_dir
			// The `&& moving_diagonally` checks are so that a forceMove taking
			// place due to a Crossed, Bumped, etc. call will interrupt
			// the second half of the diagonal movement, or the second attempt
			// at a first half if step() fails because we hit something.
			if (direct & NORTH)
				if (direct & EAST)
					if (step(src, NORTH) && moving_diagonally)
						first_step_dir = NORTH
						moving_diagonally = SECOND_DIAG_STEP
						. = step(src, EAST)
					else if (moving_diagonally && step(src, EAST))
						first_step_dir = EAST
						moving_diagonally = SECOND_DIAG_STEP
						. = step(src, NORTH)
				else if (direct & WEST)
					if (step(src, NORTH) && moving_diagonally)
						first_step_dir = NORTH
						moving_diagonally = SECOND_DIAG_STEP
						. = step(src, WEST)
					else if (moving_diagonally && step(src, WEST))
						first_step_dir = WEST
						moving_diagonally = SECOND_DIAG_STEP
						. = step(src, NORTH)
			else if (direct & SOUTH)
				if (direct & EAST)
					if (step(src, SOUTH) && moving_diagonally)
						first_step_dir = SOUTH
						moving_diagonally = SECOND_DIAG_STEP
						. = step(src, EAST)
					else if (moving_diagonally && step(src, EAST))
						first_step_dir = EAST
						moving_diagonally = SECOND_DIAG_STEP
						. = step(src, SOUTH)
				else if (direct & WEST)
					if (step(src, SOUTH) && moving_diagonally)
						first_step_dir = SOUTH
						moving_diagonally = SECOND_DIAG_STEP
						. = step(src, WEST)
					else if (moving_diagonally && step(src, WEST))
						first_step_dir = WEST
						moving_diagonally = SECOND_DIAG_STEP
						. = step(src, SOUTH)
			if(moving_diagonally == SECOND_DIAG_STEP)
				if(!. && set_dir_on_move && update_dir)
					setDir(first_step_dir)
				else if(!inertia_moving)
					newtonian_move(dir2angle(direct))
				if(client_mobs_in_contents)
					update_parallax_contents()
			moving_diagonally = 0
			return

	if(!loc || (loc == oldloc && oldloc != newloc))
		last_move = 0
		set_currently_z_moving(FALSE, TRUE)
		return

	if(. && pulling && pulling == pullee && pulling != moving_from_pull) //we were pulling a thing and didn't lose it during our move.
		if(pulling.anchored)
			stop_pulling()
		else
			//puller and pullee more than one tile away or in diagonal position and whatever the pullee is pulling isn't already moving from a pull as it'll most likely result in an infinite loop a la ouroborus.
			if(!pulling.pulling?.moving_from_pull)
				var/pull_dir = get_dir(pulling, src)
				var/target_turf = current_turf

				// Pulling things down/up stairs. zMove() has flags for check_pulling and stop_pulling calls.
				// You may wonder why we're not just forcemoving the pulling movable and regrabbing it.
				// The answer is simple. forcemoving and regrabbing is ugly and breaks conga lines.
				if(pulling.z != z)
					target_turf = get_step(pulling, get_dir(pulling, current_turf))

				if(target_turf != current_turf || (moving_diagonally != SECOND_DIAG_STEP && ISDIAGONALDIR(pull_dir)) || get_dist(src, pulling) > 1)
					pulling.move_from_pull(src, target_turf, glide_size)
			if (pulledby)
				if (pulledby.currently_z_moving)
					check_pulling(z_allowed = TRUE)
				//don't call check_pulling() here at all if there is a pulledby that is not currently z moving
				//because it breaks stair conga lines, for some fucking reason.
				//it's fine because the pull will be checked when this whole proc is called by the mob doing the pulling anyways
			else
				check_pulling()

	//glide_size strangely enough can change mid movement animation and update correctly while the animation is playing
	//This means that if you don't override it late like this, it will just be set back by the movement update that's called when you move turfs.
	if(glide_size_override)
		set_glide_size(glide_size_override)

	last_move = direct

	if(set_dir_on_move && dir != direct && update_dir)
		setDir(direct)
	if(. && has_buckled_mobs() && !handle_buckled_mob_movement(loc, direct, glide_size_override)) //movement failed due to buckled mob(s)
		. = FALSE

	if(currently_z_moving)
		if(. && loc == newloc)
			var/turf/pitfall = get_turf(src)
			pitfall.zFall(src, falling_from_move = TRUE)
		else
			set_currently_z_moving(FALSE, TRUE)

/// Called when src is being moved to a target turf because another movable (puller) is moving around.
/atom/movable/proc/move_from_pull(atom/movable/puller, turf/target_turf, glide_size_override)
	moving_from_pull = puller
	Move(target_turf, get_dir(src, target_turf), glide_size_override)
	moving_from_pull = null

/**
 * Called after a successful Move(). By this point, we've already moved.
 * Arguments:
 * * old_loc is the location prior to the move. Can be null to indicate nullspace.
 * * movement_dir is the direction the movement took place. Can be NONE if it was some sort of teleport.
 * * The forced flag indicates whether this was a forced move, which skips many checks of regular movement.
 * * The old_locs is an optional argument, in case the moved movable was present in multiple locations before the movement.
 * * momentum_change represents whether this movement is due to a "new" force if TRUE or an already "existing" force if FALSE
 **/
/atom/movable/proc/Moved(atom/old_loc, movement_dir, forced, list/old_locs, momentum_change = TRUE)
	SHOULD_CALL_PARENT(TRUE)

	if (!moving_diagonally && !inertia_moving && momentum_change && movement_dir)
		newtonian_move(dir2angle(movement_dir))
	// If we ain't moving diagonally right now, update our parallax
	// We don't do this all the time because diag movements should trigger one call to this, not two
	// Waste of cpu time, and it fucks the animate
	if (!moving_diagonally && client_mobs_in_contents)
		update_parallax_contents()

	SEND_SIGNAL(src, COMSIG_MOVABLE_MOVED, old_loc, movement_dir, forced, old_locs, momentum_change)

	if(old_loc)
		SEND_SIGNAL(old_loc, COMSIG_ATOM_ABSTRACT_EXITED, src, movement_dir)
	if(loc)
		SEND_SIGNAL(loc, COMSIG_ATOM_ABSTRACT_ENTERED, src, old_loc, old_locs)

	var/turf/old_turf = get_turf(old_loc)
	var/turf/new_turf = get_turf(src)

	if (old_turf?.z != new_turf?.z)
		var/same_z_layer = (GET_TURF_PLANE_OFFSET(old_turf) == GET_TURF_PLANE_OFFSET(new_turf))
		on_changed_z_level(old_turf, new_turf, same_z_layer)

	if(HAS_SPATIAL_GRID_CONTENTS(src))
		if(old_turf && new_turf && (old_turf.z != new_turf.z \
			|| GET_SPATIAL_INDEX(old_turf.x) != GET_SPATIAL_INDEX(new_turf.x) \
			|| GET_SPATIAL_INDEX(old_turf.y) != GET_SPATIAL_INDEX(new_turf.y)))

			SSspatial_grid.exit_cell(src, old_turf)
			SSspatial_grid.enter_cell(src, new_turf)

		else if(old_turf && !new_turf)
			SSspatial_grid.exit_cell(src, old_turf)

		else if(new_turf && !old_turf)
			SSspatial_grid.enter_cell(src, new_turf)

	return TRUE

// Make sure you know what you're doing if you call this
// You probably want CanPass()
/atom/movable/Cross(atom/movable/crossed_atom)
	if(SEND_SIGNAL(src, COMSIG_MOVABLE_CROSS, crossed_atom) & COMPONENT_BLOCK_CROSS)
		return FALSE
	if(SEND_SIGNAL(crossed_atom, COMSIG_MOVABLE_CROSS_OVER, src) & COMPONENT_BLOCK_CROSS)
		return FALSE
	return CanPass(crossed_atom, get_dir(src, crossed_atom))

///default byond proc that is deprecated for us in lieu of signals. do not call
/atom/movable/Crossed(atom/movable/crossed_atom, oldloc)
	SHOULD_NOT_OVERRIDE(TRUE)
	CRASH("atom/movable/Crossed() was called!")

/**
 * `Uncross()` is a default BYOND proc that is called when something is *going*
 * to exit this atom's turf. It is prefered over `Uncrossed` when you want to
 * deny that movement, such as in the case of border objects, objects that allow
 * you to walk through them in any direction except the one they block
 * (think side windows).
 *
 * While being seemingly harmless, most everything doesn't actually want to
 * use this, meaning that we are wasting proc calls for every single atom
 * on a turf, every single time something exits it, when basically nothing
 * cares.
 *
 * This overhead caused real problems on Sybil round #159709, where lag
 * attributed to Uncross was so bad that the entire master controller
 * collapsed and people made Among Us lobbies in OOC.
 *
 * If you want to replicate the old `Uncross()` behavior, the most apt
 * replacement is [`/datum/element/connect_loc`] while hooking onto
 * [`COMSIG_ATOM_EXIT`].
 */
/atom/movable/Uncross()
	SHOULD_NOT_OVERRIDE(TRUE)
	CRASH("Uncross() should not be being called, please read the doc-comment for it for why.")

/**
 * default byond proc that is normally called on everything inside the previous turf
 * a movable was in after moving to its current turf
 * this is wasteful since the vast majority of objects do not use Uncrossed
 * use connect_loc to register to COMSIG_ATOM_EXITED instead
 */
/atom/movable/Uncrossed(atom/movable/uncrossed_atom)
	SHOULD_NOT_OVERRIDE(TRUE)
	CRASH("/atom/movable/Uncrossed() was called")

/atom/movable/Bump(atom/bumped_atom)
	if(!bumped_atom)
		CRASH("Bump was called with no argument.")
	if(SEND_SIGNAL(src, COMSIG_MOVABLE_BUMP, bumped_atom) & COMPONENT_INTERCEPT_BUMPED)
		return
	. = ..()
	if(!QDELETED(throwing))
		throwing.finalize(hit = TRUE, target = bumped_atom)
		. = TRUE
		if(QDELETED(bumped_atom))
			return
	bumped_atom.Bumped(src)

/atom/movable/Exited(atom/movable/gone, direction)
	. = ..()

	if(!LAZYLEN(gone.important_recursive_contents))
		return
	var/list/nested_locs = get_nested_locs(src) + src
	for(var/channel in gone.important_recursive_contents)
		for(var/atom/movable/location as anything in nested_locs)
			LAZYINITLIST(location.important_recursive_contents)
			var/list/recursive_contents = location.important_recursive_contents // blue hedgehog velocity
			LAZYINITLIST(recursive_contents[channel])
			recursive_contents[channel] -= gone.important_recursive_contents[channel]
			switch(channel)
				if(RECURSIVE_CONTENTS_CLIENT_MOBS, RECURSIVE_CONTENTS_HEARING_SENSITIVE)
					if(!length(recursive_contents[channel]))
						// This relies on a nice property of the linked recursive and gridmap types
						// They're defined in relation to each other, so they have the same value
						SSspatial_grid.remove_grid_awareness(location, channel)
			ASSOC_UNSETEMPTY(recursive_contents, channel)
			UNSETEMPTY(location.important_recursive_contents)

/atom/movable/Entered(atom/movable/arrived, atom/old_loc, list/atom/old_locs)
	. = ..()

	if(!LAZYLEN(arrived.important_recursive_contents))
		return
	var/list/nested_locs = get_nested_locs(src) + src
	for(var/channel in arrived.important_recursive_contents)
		for(var/atom/movable/location as anything in nested_locs)
			LAZYINITLIST(location.important_recursive_contents)
			var/list/recursive_contents = location.important_recursive_contents // blue hedgehog velocity
			LAZYINITLIST(recursive_contents[channel])
			switch(channel)
				if(RECURSIVE_CONTENTS_CLIENT_MOBS, RECURSIVE_CONTENTS_HEARING_SENSITIVE)
					if(!length(recursive_contents[channel]))
						SSspatial_grid.add_grid_awareness(location, channel)
			recursive_contents[channel] |= arrived.important_recursive_contents[channel]

///allows this movable to hear and adds itself to the important_recursive_contents list of itself and every movable loc its in
/atom/movable/proc/become_hearing_sensitive(trait_source = TRAIT_GENERIC)
	ADD_TRAIT(src, TRAIT_HEARING_SENSITIVE, trait_source)
	if(!HAS_TRAIT(src, TRAIT_HEARING_SENSITIVE))
		return

	for(var/atom/movable/location as anything in get_nested_locs(src) + src)
		LAZYINITLIST(location.important_recursive_contents)
		var/list/recursive_contents = location.important_recursive_contents // blue hedgehog velocity
		if(!length(recursive_contents[RECURSIVE_CONTENTS_HEARING_SENSITIVE]))
			SSspatial_grid.add_grid_awareness(location, SPATIAL_GRID_CONTENTS_TYPE_HEARING)
		recursive_contents[RECURSIVE_CONTENTS_HEARING_SENSITIVE] += list(src)

	var/turf/our_turf = get_turf(src)
	SSspatial_grid.add_grid_membership(src, our_turf, SPATIAL_GRID_CONTENTS_TYPE_HEARING)

/**
 * removes the hearing sensitivity channel from the important_recursive_contents list of this and all nested locs containing us if there are no more sources of the trait left
 * since RECURSIVE_CONTENTS_HEARING_SENSITIVE is also a spatial grid content type, removes us from the spatial grid if the trait is removed
 *
 * * trait_source - trait source define or ALL, if ALL, force removes hearing sensitivity. if a trait source define, removes hearing sensitivity only if the trait is removed
 */
/atom/movable/proc/lose_hearing_sensitivity(trait_source = TRAIT_GENERIC)
	if(!HAS_TRAIT(src, TRAIT_HEARING_SENSITIVE))
		return
	REMOVE_TRAIT(src, TRAIT_HEARING_SENSITIVE, trait_source)
	if(HAS_TRAIT(src, TRAIT_HEARING_SENSITIVE))
		return

	var/turf/our_turf = get_turf(src)
	/// We get our awareness updated by the important recursive contents stuff, here we remove our membership
	SSspatial_grid.remove_grid_membership(src, our_turf, SPATIAL_GRID_CONTENTS_TYPE_HEARING)

	for(var/atom/movable/location as anything in get_nested_locs(src) + src)
		var/list/recursive_contents = location.important_recursive_contents // blue hedgehog velocity
		recursive_contents[RECURSIVE_CONTENTS_HEARING_SENSITIVE] -= src
		if(!length(recursive_contents[RECURSIVE_CONTENTS_HEARING_SENSITIVE]))
			SSspatial_grid.remove_grid_awareness(location, SPATIAL_GRID_CONTENTS_TYPE_HEARING)
		ASSOC_UNSETEMPTY(recursive_contents, RECURSIVE_CONTENTS_HEARING_SENSITIVE)
		UNSETEMPTY(location.important_recursive_contents)

///allows this movable to know when it has "entered" another area no matter how many movable atoms its stuffed into, uses important_recursive_contents
/atom/movable/proc/become_area_sensitive(trait_source = TRAIT_GENERIC)
	if(!HAS_TRAIT(src, TRAIT_AREA_SENSITIVE))
		for(var/atom/movable/location as anything in get_nested_locs(src) + src)
			LAZYADDASSOCLIST(location.important_recursive_contents, RECURSIVE_CONTENTS_AREA_SENSITIVE, src)
	ADD_TRAIT(src, TRAIT_AREA_SENSITIVE, trait_source)

///removes the area sensitive channel from the important_recursive_contents list of this and all nested locs containing us if there are no more source of the trait left
/atom/movable/proc/lose_area_sensitivity(trait_source = TRAIT_GENERIC)
	if(!HAS_TRAIT(src, TRAIT_AREA_SENSITIVE))
		return
	REMOVE_TRAIT(src, TRAIT_AREA_SENSITIVE, trait_source)
	if(HAS_TRAIT(src, TRAIT_AREA_SENSITIVE))
		return

	for(var/atom/movable/location as anything in get_nested_locs(src) + src)
		LAZYREMOVEASSOC(location.important_recursive_contents, RECURSIVE_CONTENTS_AREA_SENSITIVE, src)

///propogates ourselves through our nested contents, similar to other important_recursive_contents procs
///main difference is that client contents need to possibly duplicate recursive contents for the clients mob AND its eye
/mob/proc/enable_client_mobs_in_contents()
	for(var/atom/movable/movable_loc as anything in get_nested_locs(src) + src)
		LAZYINITLIST(movable_loc.important_recursive_contents)
		var/list/recursive_contents = movable_loc.important_recursive_contents // blue hedgehog velocity
		if(!length(recursive_contents[RECURSIVE_CONTENTS_CLIENT_MOBS]))
			SSspatial_grid.add_grid_awareness(movable_loc, SPATIAL_GRID_CONTENTS_TYPE_CLIENTS)
		LAZYINITLIST(recursive_contents[RECURSIVE_CONTENTS_CLIENT_MOBS])
		recursive_contents[RECURSIVE_CONTENTS_CLIENT_MOBS] |= src

	var/turf/our_turf = get_turf(src)
	/// We got our awareness updated by the important recursive contents stuff, now we add our membership
	SSspatial_grid.add_grid_membership(src, our_turf, SPATIAL_GRID_CONTENTS_TYPE_CLIENTS)

///Clears the clients channel of this mob
/mob/proc/clear_important_client_contents()
	var/turf/our_turf = get_turf(src)
	SSspatial_grid.remove_grid_membership(src, our_turf, SPATIAL_GRID_CONTENTS_TYPE_CLIENTS)

	for(var/atom/movable/movable_loc as anything in get_nested_locs(src) + src)
		LAZYINITLIST(movable_loc.important_recursive_contents)
		var/list/recursive_contents = movable_loc.important_recursive_contents // blue hedgehog velocity
		LAZYINITLIST(recursive_contents[RECURSIVE_CONTENTS_CLIENT_MOBS])
		recursive_contents[RECURSIVE_CONTENTS_CLIENT_MOBS] -= src
		if(!length(recursive_contents[RECURSIVE_CONTENTS_CLIENT_MOBS]))
			SSspatial_grid.remove_grid_awareness(movable_loc, SPATIAL_GRID_CONTENTS_TYPE_CLIENTS)
		ASSOC_UNSETEMPTY(recursive_contents, RECURSIVE_CONTENTS_CLIENT_MOBS)
		UNSETEMPTY(movable_loc.important_recursive_contents)

///called when this movable becomes the parent of a storage component that is currently being viewed by a player. uses important_recursive_contents
/atom/movable/proc/become_active_storage(datum/storage/source)
	if(!HAS_TRAIT(src, TRAIT_ACTIVE_STORAGE))
		for(var/atom/movable/location as anything in get_nested_locs(src) + src)
			LAZYADDASSOCLIST(location.important_recursive_contents, RECURSIVE_CONTENTS_ACTIVE_STORAGE, src)
	ADD_TRAIT(src, TRAIT_ACTIVE_STORAGE, REF(source))

///called when this movable's storage component is no longer viewed by any players, unsets important_recursive_contents
/atom/movable/proc/lose_active_storage(datum/storage/source)
	if(!HAS_TRAIT(src, TRAIT_ACTIVE_STORAGE))
		return
	REMOVE_TRAIT(src, TRAIT_ACTIVE_STORAGE, REF(source))
	if(HAS_TRAIT(src, TRAIT_ACTIVE_STORAGE))
		return

	for(var/atom/movable/location as anything in get_nested_locs(src) + src)
		LAZYREMOVEASSOC(location.important_recursive_contents, RECURSIVE_CONTENTS_ACTIVE_STORAGE, src)

///Sets the anchored var and returns if it was successfully changed or not.
/atom/movable/proc/set_anchored(anchorvalue)
	SHOULD_CALL_PARENT(TRUE)
	if(anchored == anchorvalue)
		return
	. = anchored
	anchored = anchorvalue
	if(anchored && pulledby)
		pulledby.stop_pulling()
	SEND_SIGNAL(src, COMSIG_MOVABLE_SET_ANCHORED, anchorvalue)

/// Sets the currently_z_moving variable to a new value. Used to allow some zMovement sources to have precedence over others.
/atom/movable/proc/set_currently_z_moving(new_z_moving_value, forced = FALSE)
	if(forced)
		currently_z_moving = new_z_moving_value
		return TRUE
	var/old_z_moving_value = currently_z_moving
	currently_z_moving = max(currently_z_moving, new_z_moving_value)
	return currently_z_moving > old_z_moving_value

/atom/movable/proc/forceMove(atom/destination)
	. = FALSE
	if(destination)
		. = doMove(destination)
	else
		CRASH("No valid destination passed into forceMove")

/atom/movable/proc/moveToNullspace()
	return doMove(null)

/atom/movable/proc/doMove(atom/destination)
	. = FALSE
	RESOLVE_ACTIVE_MOVEMENT

	var/atom/oldloc = loc
	var/is_multi_tile = bound_width > ICON_SIZE_X || bound_height > ICON_SIZE_Y

	SET_ACTIVE_MOVEMENT(oldloc, NONE, TRUE, null)

	if(destination)
		///zMove already handles whether a pull from another movable should be broken.
		if(pulledby && !currently_z_moving)
			pulledby.stop_pulling()

		var/same_loc = oldloc == destination
		var/area/old_area = get_area(oldloc)
		var/area/destarea = get_area(destination)
		var/movement_dir = get_dir(src, destination)

		moving_diagonally = 0

		loc = destination

		if(!same_loc)
			if(loc == oldloc)
				// when attempting to move an atom A into an atom B which already contains A, BYOND seems
				// to silently refuse to move A to the new loc. This can really break stuff (see #77067)
				stack_trace("Attempt to move [src] to [destination] was rejected by BYOND, possibly due to cyclic contents")
				return FALSE

			if(is_multi_tile && isturf(destination))
				var/dx = destination.x
				var/dy = destination.y
				var/dz = destination.z
				var/list/new_locs = block(
					dx, dy, dz,
					dx + ROUND_UP(bound_width / ICON_SIZE_X), dy + ROUND_UP(bound_height / ICON_SIZE_Y), dz
				)
				if(old_area && old_area != destarea)
					old_area.Exited(src, movement_dir)
				for(var/atom/left_loc as anything in locs - new_locs)
					left_loc.Exited(src, movement_dir)

				for(var/atom/entering_loc as anything in new_locs - locs)
					entering_loc.Entered(src, movement_dir)

				if(old_area && old_area != destarea)
					destarea.Entered(src, movement_dir)
			else
				if(oldloc)
					oldloc.Exited(src, movement_dir)
					if(old_area && old_area != destarea)
						old_area.Exited(src, movement_dir)
				destination.Entered(src, oldloc)
				if(destarea && old_area != destarea)
					destarea.Entered(src, old_area)

		. = TRUE

	//If no destination, move the atom into nullspace (don't do this unless you know what you're doing)
	else
		. = TRUE

		if (oldloc)
			loc = null
			var/area/old_area = get_area(oldloc)
			if(is_multi_tile && isturf(oldloc))
				for(var/atom/old_loc as anything in locs)
					old_loc.Exited(src, NONE)
			else
				oldloc.Exited(src, NONE)

			if(old_area)
				old_area.Exited(src, NONE)

	RESOLVE_ACTIVE_MOVEMENT

/**
 * Called when a movable changes z-levels.
 *
 * Arguments:
 * * old_turf - The previous turf they were on before.
 * * new_turf - The turf they have now entered.
 * * same_z_layer - If their old and new z levels are on the same level of plane offsets or not
 * * notify_contents - Whether or not to notify the movable's contents that their z-level has changed. NOTE, IF YOU SET THIS, YOU NEED TO MANUALLY SET PLANE OF THE CONTENTS LATER
 */
/atom/movable/proc/on_changed_z_level(turf/old_turf, turf/new_turf, same_z_layer, notify_contents = TRUE)
	SHOULD_CALL_PARENT(TRUE)
	SEND_SIGNAL(src, COMSIG_MOVABLE_Z_CHANGED, old_turf, new_turf, same_z_layer)

	// If our turfs are on different z "layers", recalc our planes
	if(!same_z_layer && !QDELETED(src))
		SET_PLANE(src, PLANE_TO_TRUE(src.plane), new_turf)
		// a TON of overlays use planes, and thus require offsets
		// so we do this. sucks to suck
		update_appearance()

		if(update_on_z)
			// I so much wish this could be somewhere else. alas, no.
			for(var/image/update as anything in update_on_z)
				SET_PLANE(update, PLANE_TO_TRUE(update.plane), new_turf)
		if(update_overlays_on_z)
			// This EVEN more so
			cut_overlay(update_overlays_on_z)
			// This even more so
			for(var/mutable_appearance/update in update_overlays_on_z)
				SET_PLANE(update, PLANE_TO_TRUE(update.plane), new_turf)
			add_overlay(update_overlays_on_z)

	if(!notify_contents)
		return

	for (var/atom/movable/content as anything in src) // Notify contents of Z-transition.
		content.on_changed_z_level(old_turf, new_turf, same_z_layer)

/**
 * Called whenever an object moves and by mobs when they attempt to move themselves through space
 * And when an object or action applies a force on src, see [newtonian_move][/atom/movable/proc/newtonian_move]
 *
 * Return FALSE to have src start/keep drifting in a no-grav area and TRUE to stop/not start drifting
 *
 * Mobs should return 1 if they should be able to move of their own volition, see [/client/proc/Move]
 *
 * Arguments:
 * * movement_dir - 0 when stopping or any dir when trying to move
 * * continuous_move - If this check is coming from something in the context of already drifting
 */
/atom/movable/proc/Process_Spacemove(movement_dir = 0, continuous_move = FALSE)
	if(has_gravity())
		return TRUE

	if(SEND_SIGNAL(src, COMSIG_MOVABLE_SPACEMOVE, movement_dir, continuous_move) & COMSIG_MOVABLE_STOP_SPACEMOVE)
		return TRUE

	if(pulledby && (pulledby.pulledby != src || moving_from_pull))
		return TRUE

	if(throwing)
		return TRUE

	if(!isturf(loc))
		return TRUE

	if (handle_spacemove_grabbing())
		return TRUE

	return FALSE

/atom/movable/proc/handle_spacemove_grabbing()
	if(locate(/obj/structure/lattice) in range(1, get_turf(src))) //Not realistic but makes pushing things in space easier
		return TRUE

/// Only moves the object if it's under no gravity
/// Accepts the direction to move, if the push should be instant, and an optional parameter to fine tune the start delay
/// Drift force determines how much acceleration should be applied. Controlled cap, if set, will ensure that if the object was moving slower than the cap before, it cannot accelerate past the cap from this move.
/atom/movable/proc/newtonian_move(inertia_angle, instant = FALSE, start_delay = 0, drift_force = 1 NEWTONS, controlled_cap = null, force_loop = TRUE)
	if(!isturf(loc) || Process_Spacemove(angle2dir(inertia_angle), continuous_move = TRUE))
		return FALSE

	if (!isnull(drift_handler))
		if (drift_handler.newtonian_impulse(inertia_angle, start_delay, drift_force, controlled_cap, force_loop))
			return TRUE

	new /datum/drift_handler(src, inertia_angle, instant, start_delay, drift_force)
	// Something went wrong and it failed to create itself, most likely we have a higher priority loop already
	if (QDELETED(drift_handler))
		return FALSE
	return TRUE

/atom/movable/set_explosion_block(explosion_block)
	var/old_block = src.explosion_block
	explosive_resistance -= old_block
	src.explosion_block = explosion_block
	explosive_resistance += explosion_block
	SEND_SIGNAL(src, COMSIG_MOVABLE_EXPLOSION_BLOCK_CHANGED, old_block, explosion_block)

/atom/movable/proc/throw_impact(atom/hit_atom, datum/thrownthing/throwingdatum)
	set waitfor = FALSE
	var/hitpush = TRUE
	var/impact_flags = pre_impact(hit_atom, throwingdatum)
	if(impact_flags & COMPONENT_MOVABLE_IMPACT_NEVERMIND)
		return // in case a signal interceptor broke or deleted the thing before we could process our hit
	if(impact_flags & COMPONENT_MOVABLE_IMPACT_FLIP_HITPUSH)
		hitpush = FALSE
	var/caught = hit_atom.hitby(src, throwingdatum=throwingdatum, hitpush=hitpush)
	SEND_SIGNAL(src, COMSIG_MOVABLE_IMPACT, hit_atom, throwingdatum, caught)
	return caught

///Called before we attempt to call hitby and send the COMSIG_MOVABLE_IMPACT signal
/atom/movable/proc/pre_impact(atom/hit_atom, datum/thrownthing/throwingdatum)
	var/impact_flags = SEND_SIGNAL(src, COMSIG_MOVABLE_PRE_IMPACT, hit_atom, throwingdatum)
	var/target_flags = SEND_SIGNAL(hit_atom, COMSIG_ATOM_PREHITBY, src, throwingdatum)
	if(target_flags & COMSIG_HIT_PREVENTED)
		impact_flags |= COMPONENT_MOVABLE_IMPACT_NEVERMIND
	return impact_flags

/atom/movable/hitby(atom/movable/hitting_atom, skipcatch, hitpush = TRUE, blocked, datum/thrownthing/throwingdatum)
	if(HAS_TRAIT(src, TRAIT_NO_THROW_HITPUSH))
		hitpush = FALSE
	if(!anchored && hitpush && (!throwingdatum || (throwingdatum.force >= (move_resist * MOVE_FORCE_PUSH_RATIO))))
		step(src, hitting_atom.dir)
	return ..()

// Calls throw_at after checking that the move strength is greater than the thrown atom's move resist. Identical args.
/atom/movable/proc/safe_throw_at(atom/target, range, speed, mob/thrower, spin = TRUE, diagonals_first = FALSE, datum/callback/callback, force = MOVE_FORCE_STRONG, gentle = FALSE)
	if((force < (move_resist * MOVE_FORCE_THROW_RATIO)) || (move_resist == INFINITY))
		return
	return throw_at(target, range, speed, thrower, spin, diagonals_first, callback, force, gentle)

///If this returns FALSE then callback will not be called.
/atom/movable/proc/throw_at(atom/target, range, speed, mob/thrower, spin = TRUE, diagonals_first = FALSE, datum/callback/callback, force = MOVE_FORCE_STRONG, gentle = FALSE, quickstart = TRUE)
	. = FALSE

	if(QDELETED(src))
		CRASH("Qdeleted thing being thrown around.")

	if (!target || speed <= 0)
		return

	if(SEND_SIGNAL(src, COMSIG_MOVABLE_PRE_THROW, args) & COMPONENT_CANCEL_THROW)
		return

	if (pulledby)
		pulledby.stop_pulling()

	//They are moving! Wouldn't it be cool if we calculated their momentum and added it to the throw?
	if (thrower && thrower.last_move && thrower.client && thrower.client.move_delay >= world.time + world.tick_lag*2)
		var/user_momentum = thrower.cached_multiplicative_slowdown
		if (!user_momentum) //no movement_delay, this means they move once per byond tick, lets calculate from that instead.
			user_momentum = world.tick_lag

		user_momentum = 1 / user_momentum // convert from ds to the tiles per ds that throw_at uses.

		if (get_dir(thrower, target) & last_move)
			user_momentum = user_momentum //basically a noop, but needed
		else if (get_dir(target, thrower) & last_move)
			user_momentum = -user_momentum //we are moving away from the target, lets slowdown the throw accordingly
		else
			user_momentum = 0


		if (user_momentum)
			//first lets add that momentum to range.
			range *= (user_momentum / speed) + 1
			//then lets add it to speed
			speed += user_momentum
			if (speed <= 0)
				return//no throw speed, the user was moving too fast.

	. = TRUE // No failure conditions past this point.

	var/target_zone
	if(QDELETED(thrower))
		thrower = null //Let's not pass a qdeleting reference if any.
	else
		target_zone = thrower.zone_selected

	var/datum/thrownthing/thrown_thing = new(src, target, get_dir(src, target), range, speed, thrower, diagonals_first, force, gentle, callback, target_zone)

	var/dist_x = abs(target.x - src.x)
	var/dist_y = abs(target.y - src.y)
	var/dx = (target.x > src.x) ? EAST : WEST
	var/dy = (target.y > src.y) ? NORTH : SOUTH

	if (dist_x == dist_y)
		thrown_thing.pure_diagonal = 1

	else if(dist_x <= dist_y)
		var/olddist_x = dist_x
		var/olddx = dx
		dist_x = dist_y
		dist_y = olddist_x
		dx = dy
		dy = olddx
	thrown_thing.dist_x = dist_x
	thrown_thing.dist_y = dist_y
	thrown_thing.dx = dx
	thrown_thing.dy = dy
	thrown_thing.diagonal_error = dist_x/2 - dist_y
	thrown_thing.start_time = world.time

	if(pulledby)
		pulledby.stop_pulling()
	if (quickstart && (throwing || SSthrowing.state == SS_RUNNING)) //Avoid stack overflow edgecases.
		quickstart = FALSE
	throwing = thrown_thing
	if(spin)
		SpinAnimation(5, 1)

	SEND_SIGNAL(src, COMSIG_MOVABLE_POST_THROW, thrown_thing, spin)
	SSthrowing.processing[src] = thrown_thing
	if (SSthrowing.state == SS_PAUSED && length(SSthrowing.currentrun))
		SSthrowing.currentrun[src] = thrown_thing
	if (quickstart)
		thrown_thing.tick()

/atom/movable/proc/handle_buckled_mob_movement(newloc, direct, glide_size_override)
	for(var/mob/living/buckled_mob as anything in buckled_mobs)
		if(!buckled_mob.Move(newloc, direct, glide_size_override)) //If a mob buckled to us can't make the same move as us
			Move(buckled_mob.loc, direct) //Move back to its location
			last_move = buckled_mob.last_move
			return FALSE
	return TRUE

/atom/movable/proc/force_pushed(atom/movable/pusher, force = MOVE_FORCE_DEFAULT, direction)
	return FALSE

/atom/movable/proc/force_push(atom/movable/pushed_atom, force = move_force, direction, silent = FALSE)
	. = pushed_atom.force_pushed(src, force, direction)
	if(!silent && .)
		visible_message(span_warning("[src] forcefully pushes against [pushed_atom]!"), span_warning("You forcefully push against [pushed_atom]!"))

/atom/movable/proc/move_crush(atom/movable/crushed_atom, force = move_force, direction, silent = FALSE)
	. = crushed_atom.move_crushed(src, force, direction)
	if(!silent && .)
		visible_message(span_danger("[src] crushes past [crushed_atom]!"), span_danger("You crush [crushed_atom]!"))

/atom/movable/proc/move_crushed(atom/movable/pusher, force = MOVE_FORCE_DEFAULT, direction)
	return FALSE

/atom/movable/CanAllowThrough(atom/movable/mover, border_dir)
	. = ..()
	if(mover in buckled_mobs)
		return TRUE

/// Returns true or false to allow src to move through the blocker, mover has final say
/atom/movable/proc/CanPassThrough(atom/blocker, movement_dir, blocker_opinion)
	SHOULD_CALL_PARENT(TRUE)
	SHOULD_BE_PURE(TRUE)

	var/blocking_signal = SEND_SIGNAL(src, COMSIG_MOVABLE_CAN_PASS_THROUGH, blocker, movement_dir)
	if(!blocking_signal)
		return blocker_opinion

	if(blocking_signal & COMSIG_COMPONENT_PERMIT_PASSAGE)
		return TRUE
	else //we have a COMSIG_COMPONENT_REFUSE_PASSAGE but like its either this or that, unlike someone wanna adds half-passing through but fuck you
		return FALSE

/// called when this atom is removed from a storage item, which is passed on as S. The loc variable is already set to the new destination before this is called.
/atom/movable/proc/on_exit_storage(datum/storage/master_storage)
	return

/// called when this atom is added into a storage item, which is passed on as S. The loc variable is already set to the storage item.
/atom/movable/proc/on_enter_storage(datum/storage/master_storage)
	return

/atom/movable/proc/get_spacemove_backup()
	var/atom/secondary_backup
	for(var/checked_range in orange(1, get_turf(src)))
		if(isarea(checked_range))
			continue
		if(isturf(checked_range))
			var/turf/turf = checked_range
			if(!turf.density)
				continue
			if (get_dir(src, turf) in GLOB.cardinals)
				return turf
			secondary_backup = turf
			continue
		var/atom/movable/checked_atom = checked_range
		if(checked_atom.density || !checked_atom.CanPass(src, get_dir(src, checked_atom)))
			if(checked_atom.last_pushoff == world.time)
				continue
			if (get_dir(src, checked_atom) in GLOB.cardinals)
				return checked_atom
			secondary_backup = checked_atom
	return secondary_backup

///called when a mob resists while inside a container that is itself inside something.
/atom/movable/proc/relay_container_resist_act(mob/living/user, obj/container)
	return


/atom/movable/proc/do_attack_animation(atom/attacked_atom, visual_effect_icon, obj/item/used_item, no_effect, fov_effect = TRUE, item_animation_override = null)
	if(!no_effect && (visual_effect_icon || used_item))
		var/animation_type = item_animation_override || ATTACK_ANIMATION_BLUNT
		if (used_item && !item_animation_override)
			switch(used_item.get_sharpness())
				if (SHARP_EDGED)
					animation_type = ATTACK_ANIMATION_SLASH
				if (SHARP_POINTY)
					animation_type = ATTACK_ANIMATION_PIERCE
		do_item_attack_animation(attacked_atom, visual_effect_icon, used_item, animation_type = animation_type)

	if(attacked_atom == src)
		return //don't do an animation if attacking self
	var/pixel_x_diff = 0
	var/pixel_y_diff = 0
	var/turn_dir = 1

	var/direction = get_dir(src, attacked_atom)
	if(direction & NORTH)
		pixel_y_diff = 8
		turn_dir = prob(50) ? -1 : 1
	else if(direction & SOUTH)
		pixel_y_diff = -8
		turn_dir = prob(50) ? -1 : 1

	if(direction & EAST)
		pixel_x_diff = 8
	else if(direction & WEST)
		pixel_x_diff = -8
		turn_dir = -1

	if(fov_effect)
		play_fov_effect(attacked_atom, 5, "attack")

	var/matrix/initial_transform = matrix(transform)
	var/matrix/rotated_transform = transform.Turn(15 * turn_dir)
	animate(src, pixel_x = pixel_x + pixel_x_diff, pixel_y = pixel_y + pixel_y_diff, transform=rotated_transform, time = 1, easing=BACK_EASING|EASE_IN, flags = ANIMATION_PARALLEL)
	animate(pixel_x = pixel_x - pixel_x_diff, pixel_y = pixel_y - pixel_y_diff, transform=initial_transform, time = 2, easing=SINE_EASING, flags = ANIMATION_PARALLEL)

/* Language procs
* Unless you are doing something very specific, these are the ones you want to use.
*/

/// Gets or creates the relevant language holder. For mindless atoms, gets the local one. For atom with mind, gets the mind one.
/atom/movable/proc/get_language_holder()
	RETURN_TYPE(/datum/language_holder)
	if(QDELING(src))
		CRASH("get_language_holder() called on a QDELing atom, \
			this will try to re-instantiate the language holder that's about to be deleted, which is bad.")

	if(!language_holder)
		language_holder = new initial_language_holder(src)
	return language_holder

/// Grants the supplied language and sets omnitongue true.
/atom/movable/proc/grant_language(language, language_flags = ALL, source = LANGUAGE_ATOM)
	return get_language_holder().grant_language(language, language_flags, source)

/// Grants every language.
/atom/movable/proc/grant_all_languages(language_flags = ALL, grant_omnitongue = TRUE, source = LANGUAGE_MIND)
	return get_language_holder().grant_all_languages(language_flags, grant_omnitongue, source)

/// Removes a single language.
/atom/movable/proc/remove_language(language, language_flags = ALL, source = LANGUAGE_ALL)
	return get_language_holder().remove_language(language, language_flags, source)

/// Removes every language and sets omnitongue false.
/atom/movable/proc/remove_all_languages(source = LANGUAGE_ALL, remove_omnitongue = FALSE)
	return get_language_holder().remove_all_languages(source, remove_omnitongue)

/// Adds a language to the blocked language list. Use this over remove_language in cases where you will give languages back later.
/atom/movable/proc/add_blocked_language(language, source = LANGUAGE_ATOM)
	return get_language_holder().add_blocked_language(language, source)

/// Removes a language from the blocked language list.
/atom/movable/proc/remove_blocked_language(language, source = LANGUAGE_ATOM)
	return get_language_holder().remove_blocked_language(language, source)

/// Checks if atom has the language. If spoken is true, only checks if atom can speak the language.
/atom/movable/proc/has_language(language, flags_to_check)
	return get_language_holder().has_language(language, flags_to_check)

/// Checks if atom can speak the language.
/atom/movable/proc/can_speak_language(language)
	return get_language_holder().can_speak_language(language)

/// Returns the result of tongue specific limitations on spoken languages.
/atom/movable/proc/could_speak_language(datum/language/language_path)
	return TRUE

/// Returns selected language, if it can be spoken, or finds, sets and returns a new selected language if possible.
/atom/movable/proc/get_selected_language()
	return get_language_holder().get_selected_language()

/// Gets a random understood language, useful for hallucinations and such.
/atom/movable/proc/get_random_understood_language()
	return get_language_holder().get_random_understood_language()

/// Gets a random spoken language, useful for forced speech and such.
/atom/movable/proc/get_random_spoken_language()
	return get_language_holder().get_random_spoken_language()

/// Copies all languages into the supplied atom/language holder. Source should be overridden when you
/// do not want the language overwritten by later atom updates or want to avoid blocked languages.
/atom/movable/proc/copy_languages(datum/language_holder/from_holder, source_override)
	if(ismovable(from_holder))
		var/atom/movable/thing = from_holder
		from_holder = thing.get_language_holder()

	return get_language_holder().copy_languages(from_holder, source_override)

/// Sets the passed path as the active language
/// Returns the currently selected language if successful, if the language was not valid, returns null
/atom/movable/proc/set_active_language(language_path)
	var/datum/language_holder/our_holder = get_language_holder()
	our_holder.selected_language = language_path

	return our_holder.get_selected_language() // verifies its validity, returns it if successful.

/**
 * Randomizes our atom's language to an uncommon language if:
 * - They are on the station Z level
 * OR
 * - They are on the escape shuttle
 */
/atom/movable/proc/randomize_language_if_on_station()
	var/turf/atom_turf = get_turf(src)
	var/area/atom_area = get_area(src)

	if(!atom_turf) // some machines spawn in nullspace
		return FALSE

	if(!is_station_level(atom_turf.z) && !istype(atom_area, /area/shuttle/escape))
		// Why snowflake check for escape shuttle? Well, a lot of shuttles spawn with machines
		// but docked at centcom, and I wanted those machines to also speak funny languages
		return FALSE
	grant_random_uncommon_language()
	return TRUE

/// Teaches a random non-common language and sets it as the active language
/atom/movable/proc/grant_random_uncommon_language(source)
	if (!length(GLOB.uncommon_roundstart_languages))
		return FALSE
	var/picked = pick(GLOB.uncommon_roundstart_languages)
	grant_language(picked, source = source)
	set_active_language(picked)
	return TRUE

/* End language procs */

/**
 * Returns an atom's power cell, if it has one. Overload for individual items.
 * Args
 *
 * * /atom/movable/interface - the atom that is trying to interact with this cell
 * * mob/user - the mob that is holding the interface
 */
/atom/movable/proc/get_cell(atom/movable/interface, mob/user)
	return

/atom/movable/proc/can_be_pulled(user, force)
	if(src == user || !isturf(loc))
		return FALSE
	if(SEND_SIGNAL(src, COMSIG_ATOM_CAN_BE_PULLED, user) & COMSIG_ATOM_CANT_PULL)
		return FALSE
	if(anchored || throwing)
		return FALSE
	if(force < (move_resist * MOVE_FORCE_PULL_RATIO))
		return FALSE
	return TRUE

/**
 * Updates the grab state of the movable
 *
 * This exists to act as a hook for behaviour
 */
/atom/movable/proc/setGrabState(newstate)
	if(newstate == grab_state)
		return
	SEND_SIGNAL(src, COMSIG_MOVABLE_SET_GRAB_STATE, newstate)
	. = grab_state
	grab_state = newstate
	switch(grab_state) // Current state.
		if(GRAB_PASSIVE)
			pulling.remove_traits(list(TRAIT_IMMOBILIZED, TRAIT_HANDS_BLOCKED), CHOKEHOLD_TRAIT)
			if(. >= GRAB_NECK) // Previous state was a a neck-grab or higher.
				REMOVE_TRAIT(pulling, TRAIT_FLOORED, CHOKEHOLD_TRAIT)
		if(GRAB_AGGRESSIVE)
			if(. >= GRAB_NECK) // Grab got downgraded.
				REMOVE_TRAIT(pulling, TRAIT_FLOORED, CHOKEHOLD_TRAIT)
			else // Grab got upgraded from a passive one.
				pulling.add_traits(list(TRAIT_IMMOBILIZED, TRAIT_HANDS_BLOCKED), CHOKEHOLD_TRAIT)
		if(GRAB_NECK, GRAB_KILL)
			if(. <= GRAB_AGGRESSIVE)
				ADD_TRAIT(pulling, TRAIT_FLOORED, CHOKEHOLD_TRAIT)

/**
 * Adds the deadchat_plays component to this atom with simple movement commands.
 *
 * Returns the component added.
 * Arguments:
 * * mode - Either ANARCHY_MODE or DEMOCRACY_MODE passed to the deadchat_control component. See [/datum/component/deadchat_control] for more info.
 * * cooldown - The cooldown between command inputs passed to the deadchat_control component. See [/datum/component/deadchat_control] for more info.
 */
/atom/movable/proc/deadchat_plays(mode = ANARCHY_MODE, cooldown = 12 SECONDS)
	return AddComponent(/datum/component/deadchat_control/cardinal_movement, mode, list(), cooldown)

/atom/movable/vv_get_dropdown()
	. = ..()
	VV_DROPDOWN_OPTION("", "---------")
	VV_DROPDOWN_OPTION(VV_HK_OBSERVE_FOLLOW, "Observe Follow")
	VV_DROPDOWN_OPTION(VV_HK_GET_MOVABLE, "Get Movable")
	VV_DROPDOWN_OPTION(VV_HK_EDIT_PARTICLES, "Edit Particles")
	VV_DROPDOWN_OPTION(VV_HK_DEADCHAT_PLAYS, "Start/Stop Deadchat Plays")
	VV_DROPDOWN_OPTION(VV_HK_ADD_FANTASY_AFFIX, "Add Fantasy Affix")

/atom/movable/vv_do_topic(list/href_list)
	. = ..()

	if(!.)
		return

	if(href_list[VV_HK_OBSERVE_FOLLOW])
		if(!check_rights(R_ADMIN))
			return
		usr.client?.admin_follow(src)

	if(href_list[VV_HK_GET_MOVABLE])
		if(!check_rights(R_ADMIN))
			return
		if(QDELETED(src))
			return
		forceMove(get_turf(usr))

	if(href_list[VV_HK_EDIT_PARTICLES] && check_rights(R_VAREDIT))
		var/client/C = usr.client
		C?.open_particle_editor(src)

	if(href_list[VV_HK_DEADCHAT_PLAYS] && check_rights(R_FUN))
		if(tgui_alert(usr, "Allow deadchat to control [src] via chat commands?", "Deadchat Plays [src]", list("Allow", "Cancel")) != "Allow")
			return
		// Alert is async, so quick sanity check to make sure we should still be doing this.
		if(QDELETED(src))
			return
		// This should never happen, but if it does it should not be silent.
		if(deadchat_plays() == COMPONENT_INCOMPATIBLE)
			to_chat(usr, span_warning("Deadchat control not compatible with [src]."))
			CRASH("deadchat_control component incompatible with object of type: [type]")
		to_chat(usr, span_notice("Deadchat now control [src]."))
		log_admin("[key_name(usr)] has added deadchat control to [src]")
		message_admins(span_notice("[key_name(usr)] has added deadchat control to [src]"))

/**
* A wrapper for setDir that should only be able to fail by living mobs.
*
* Called from [/atom/movable/proc/keyLoop], this exists to be overwritten by living mobs with a check to see if we're actually alive enough to change directions
*/
/atom/movable/proc/keybind_face_direction(direction)
	setDir(direction)

/**
 * Check if the other atom/movable has any factions the same as us. Defined at the atom/movable level so it can be defined for just about anything.
 *
 * If exact match is set, then all our factions must match exactly
 */
/atom/movable/proc/faction_check_atom(atom/movable/target, exact_match)
	if(!exact_match)
		return faction_check(faction, target.faction, FALSE)

	var/list/faction_src = LAZYCOPY(faction)
	var/list/faction_target = LAZYCOPY(target.faction)
	if(!("[REF(src)]" in faction_target)) //if they don't have our ref faction, remove it from our factions list.
		faction_src -= "[REF(src)]" //if we don't do this, we'll never have an exact match.
	if(!("[REF(target)]" in faction_src))
		faction_target -= "[REF(target)]" //same thing here.
	return faction_check(faction_src, faction_target, TRUE)
