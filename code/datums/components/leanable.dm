/// Things with this component can be leaned onto, optionally exclusive to RMB dragging
/datum/component/leanable
	/// How much will mobs that lean onto this object be offset
	var/leaning_offset = 11
	/// List of mobs currently leaning on our parent
	var/list/leaning_mobs = list()
	/// Is this object currently leanable?
	var/is_currently_leanable = TRUE

/datum/component/leanable/Initialize(mob/living/leaner, leaning_offset = 11)
	. = ..()
	src.leaning_offset = leaning_offset
	mousedrop_receive(parent, leaner, leaner)

/datum/component/leanable/RegisterWithParent()
	RegisterSignal(parent, COMSIG_MOUSEDROPPED_ONTO, PROC_REF(mousedrop_receive))
	RegisterSignal(parent, COMSIG_MOVABLE_MOVED, PROC_REF(on_moved))
	RegisterSignal(parent, COMSIG_ATOM_DENSITY_CHANGED, PROC_REF(on_density_change))
	var/atom/leanable_atom = parent
	is_currently_leanable = leanable_atom.density

/datum/component/leanable/UnregisterFromParent()
	. = ..()
	UnregisterSignal(parent, list(
		COMSIG_MOVABLE_MOVED,
		COMSIG_MOUSEDROPPED_ONTO,
		COMSIG_ATOM_DENSITY_CHANGED,
	))

/datum/component/leanable/UnregisterFromParent()
	UnregisterSignal(parent, list(COMSIG_MOUSEDROPPED_ONTO, COMSIG_MOVABLE_MOVED))

/datum/component/leanable/Destroy(force)
	stop_leaning_leaners()
	return ..()

/datum/component/leanable/proc/stop_leaning_leaners(fall)
	for (var/mob/living/leaner as anything in leaning_mobs)
		leaner.stop_leaning()
		if(fall)
			to_chat(leaner, span_danger("You lose balance!"))
			leaner.Paralyze(0.5 SECONDS)
	leaning_mobs = null

/datum/component/leanable/proc/on_moved(datum/source)
	SIGNAL_HANDLER

	for (var/mob/living/leaner as anything in leaning_mobs)
		leaner.stop_leaning()

/datum/component/leanable/proc/mousedrop_receive(atom/source, atom/movable/dropped, mob/user, params)
	if (dropped != user)
		return
	if (!iscarbon(dropped) && !iscyborg(dropped))
		return
	var/mob/living/leaner = dropped
	if (INCAPACITATED_IGNORING(leaner, INCAPABLE_RESTRAINTS) || leaner.stat != CONSCIOUS || HAS_TRAIT(leaner, TRAIT_NO_TRANSFORM))
		return
	if (HAS_TRAIT_FROM(leaner, TRAIT_UNDENSE, LEANING_TRAIT))
		return
	var/turf/checked_turf = get_step(leaner, REVERSE_DIR(leaner.dir))
	if (checked_turf != get_turf(source))
		return
	if(!is_currently_leanable)
		return COMPONENT_CANCEL_MOUSEDROPPED_ONTO
	leaner.start_leaning(source, leaning_offset)
	leaning_mobs += leaner
	RegisterSignals(leaner, list(COMSIG_LIVING_STOPPED_LEANING, COMSIG_QDELETING), PROC_REF(stopped_leaning))
	return COMPONENT_CANCEL_MOUSEDROPPED_ONTO

/datum/component/leanable/proc/stopped_leaning(datum/source)
	SIGNAL_HANDLER
	leaning_mobs -= source
	UnregisterSignal(source, list(COMSIG_LIVING_STOPPED_LEANING, COMSIG_QDELETING))

/**
 * Makes the mob lean on an atom
 * Arguments
 *
 * * atom/lean_target - the target the mob is trying to lean on
 * * leaning_offset - pixel offset to apply on the mob when leaning
 */
/mob/living/proc/start_leaning(atom/lean_target, leaning_offset)
	var/new_x = 0
	var/new_y = 0
	switch(dir)
		if(SOUTH)
			new_y += leaning_offset
		if(NORTH)
			new_y -= leaning_offset
		if(WEST)
			new_x += leaning_offset
		if(EAST)
			new_x -= leaning_offset

	add_offsets(LEANING_TRAIT, x_add = new_x, y_add = new_y)
	add_traits(list(TRAIT_UNDENSE, TRAIT_EXPANDED_FOV), LEANING_TRAIT)
	visible_message(
		span_notice("[src] leans against [lean_target]."),
		span_notice("You lean against [lean_target]."),
	)
	RegisterSignals(src, list(
		COMSIG_MOB_CLIENT_PRE_MOVE,
		COMSIG_LIVING_DISARM_HIT,
		COMSIG_LIVING_GET_PULLED,
	), PROC_REF(stop_leaning))

	RegisterSignal(src, COMSIG_MOVABLE_TELEPORTED, PROC_REF(teleport_away_while_leaning))
	RegisterSignal(src, COMSIG_ATOM_POST_DIR_CHANGE, PROC_REF(lean_dir_changed))
	update_fov()

/// You fall on your face if you get teleported while leaning
/mob/living/proc/teleport_away_while_leaning()
	SIGNAL_HANDLER

	// Make sure we unregister signal handlers and reset animation
	stop_leaning()
	// -1000 aura
	visible_message(span_notice("[src] falls flat on [p_their()] face from losing [p_their()] balance!"), span_warning("You fall suddenly as the object you were leaning on vanishes from contact with you!"))
	Knockdown(3 SECONDS)

/mob/living/proc/stop_leaning()
	SIGNAL_HANDLER

	UnregisterSignal(src, list(
		COMSIG_MOB_CLIENT_PRE_MOVE,
		COMSIG_LIVING_DISARM_HIT,
		COMSIG_LIVING_GET_PULLED,
		COMSIG_ATOM_POST_DIR_CHANGE,
		COMSIG_MOVABLE_TELEPORTED,
	))
	remove_offsets(LEANING_TRAIT)
	remove_traits(list(TRAIT_UNDENSE, TRAIT_EXPANDED_FOV), LEANING_TRAIT)
	SEND_SIGNAL(src, COMSIG_LIVING_STOPPED_LEANING)
	update_fov()

/mob/living/proc/lean_dir_changed(atom/source, old_dir, new_dir)
	SIGNAL_HANDLER

	if (old_dir != new_dir)
		INVOKE_ASYNC(src, PROC_REF(stop_leaning))

/datum/component/leanable/proc/on_density_change()
	SIGNAL_HANDLER
	is_currently_leanable = !is_currently_leanable
	if(!is_currently_leanable)
		stop_leaning_leaners(fall = TRUE)
		return
	stop_leaning_leaners()
