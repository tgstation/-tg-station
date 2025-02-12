/*!
 * Contains the spell "Wolves among Sheep"
 * Handles the creation of the "arena", in terms of visuals. Banishes windows/airlocks and puts down the floors
 * For the functionality of the spell itself see [/obj/effect/abstract/heretic_arena] which is created during [/proc/create_arena()]
 */
/datum/action/cooldown/spell/wolves_among_sheep
	name = "Wolves among Sheep"
	desc = "Alters the fabric of reality, conjuring a magical arena unpassable to outsiders, \
		all participants are trapped and immune to any form of crowd control or enviromental hazards; \
		trapped participants are granted a Blade and are unable to leave or jaunt until they score a critical hit."
	background_icon_state = "bg_heretic"
	overlay_icon_state = null
	button_icon = 'icons/mob/actions/actions_ecult.dmi'
	button_icon_state = "among_sheep"

	school = SCHOOL_FORBIDDEN
	cooldown_time = 2 MINUTES

	invocation = "D`M``N `XP`NS``N!"
	invocation_type = INVOCATION_SHOUT
	spell_requirements = NONE
	/// Max distance our effect is expected to reach
	var/max_range = 9
	/// Max distance our effect has *actually* reached
	var/greatest_dist = 0
	/// Central turf where the spell was initially casted
	var/turf/center_turf
	/// List of all the turfs we've affected, built during /cast(). We use this to make things appear/disappear and revert once the spell expires
	var/list/to_transform = list()
	/// List of airlocks we've removed, so we can re-place them once the effect expires
	var/list/banished_airlocks = list()
	/// Timer before the effects of the spell ends. It's a variable here so we can end it prematurely
	var/revert_timer
	/// Reference to the arena so we can clear it if we need to
	var/ongoing_arena

/datum/action/cooldown/spell/wolves_among_sheep/cast(atom/cast_on)
	. = ..()
	center_turf = get_turf(owner)
	playsound(center_turf,'sound/machines/airlock/airlockopen.ogg', 750, TRUE)
	to_transform = list()
	new /obj/effect/heretic_rune/big(center_turf)
	addtimer(CALLBACK(src, PROC_REF(create_arena), center_turf), 1 SECONDS)
	revert_timer = addtimer(CALLBACK(src, PROC_REF(revert_effects)), 61 SECONDS, TIMER_STOPPABLE) // 1 second to spread out, 60 seconds to fight

	// Loop to make the spreading floor effect before finalizing our arena
	for(var/turf/transform_turf as anything in RANGE_TURFS(max_range, center_turf))
		var/turf_distance = get_dist(center_turf, transform_turf)
		if(turf_distance > greatest_dist)
			greatest_dist = turf_distance
			if(greatest_dist > max_range)
				stack_trace("greatest_dist ([greatest_dist]) has somehow exceeded the expected maximum range ([max_range])")
		if(!to_transform["[turf_distance]"])
			to_transform["[turf_distance]"] = list()
		to_transform["[turf_distance]"] += transform_turf
	for(var/iterator in 1 to greatest_dist)
		if(!to_transform["[iterator]"])
			continue
		addtimer(CALLBACK(src, PROC_REF(apply_visual), to_transform["[iterator]"]), 1 * iterator) // 0.9 SECONDS to convert our area

	// Loop doesnt catch src.loc so we have to handle it manually
	apply_visual(list(center_turf))

/datum/action/cooldown/spell/wolves_among_sheep/can_cast_spell(feedback)
	. = ..()
	for(var/obj/nearby_arena in GLOB.heretic_arenas)
		// We can't allow arenas to overlap because they break each other during cleanup.
		// If any future coder wants to allow arenas to merge or fight like domains, feel free to implement it.
		if(get_dist(owner, nearby_arena) <= 25)
			if(feedback)
				owner.balloon_alert(owner, "another arena nearby!")
			return FALSE

/// Applies a visual to each turf
/datum/action/cooldown/spell/wolves_among_sheep/proc/apply_visual(list/turfs)
	for(var/turf/target as anything in turfs)
		if(isopenturf(target))
			var/turf_icon = "rose_stone_" + "[pick(1, 2, 3, 4, 5, 6, 7, 8)]"
			target.add_alt_appearance(/datum/atom_hud/alternate_appearance/basic/everyone, "heretic_arena", image('icons/turf/floors/rose_stone_turf.dmi', target, turf_icon, layer = ABOVE_OPEN_TURF_LAYER))
		else if(isclosedturf(target))
			var/wall_icon = "rose_stone_" + "[pick(1, 2, 3, 4, 5, 6, 7, 8)]"
			target.add_alt_appearance(/datum/atom_hud/alternate_appearance/basic/everyone, "heretic_arena", image('icons/turf/walls/rose_stone_wall.dmi', target, wall_icon, layer = ABOVE_OPEN_TURF_LAYER))

		target.turf_flags |= NOJAUNT // We make the arena a NOJAUNT area so that stinky people cannot teleport in

		// Phase out the doors (restore them afterwards)
		for(var/obj/machinery/door/airlock/to_banish in target)
			banished_airlocks += to_banish
			banished_airlocks[to_banish] = to_banish.loc
			to_banish.moveToNullspace()
		// Windows will also get an alt appearance
		for(var/obj/structure/window/to_change in target)
			to_change.add_alt_appearance(/datum/atom_hud/alternate_appearance/basic/everyone, "heretic_arena", image('icons/obj/structures.dmi', to_change, "stone_window_pane", layer = ABOVE_OPEN_TURF_LAYER))

/// Sets up the proximity monitor which handles things that are within the area and leave once they get someone to crit
/datum/action/cooldown/spell/wolves_among_sheep/proc/create_arena(turf/target)
	RegisterSignals(owner, list(SIGNAL_ADDTRAIT(TRAIT_CRITICAL_CONDITION)), PROC_REF(on_caster_crit))

	// This is where most of the funcionality of the spell is
	ongoing_arena = new /obj/effect/abstract/heretic_arena(target, max_range, 60 SECONDS, owner)
	RegisterSignal(ongoing_arena, COMSIG_QDELETING, PROC_REF(on_arena_delete))

/// Clears the timer if the arena is deleted
/datum/action/cooldown/spell/wolves_among_sheep/proc/on_arena_delete()
	SIGNAL_HANDLER
	deltimer(revert_timer)
	ongoing_arena = null
	revert_effects()

/// If the caster goes into crit, the arena falls apart right away
/datum/action/cooldown/spell/wolves_among_sheep/proc/on_caster_crit()
	SIGNAL_HANDLER
	deltimer(revert_timer)
	revert_effects()

/// Undoes our changes
/datum/action/cooldown/spell/wolves_among_sheep/proc/revert_effects()
	UnregisterSignal(owner, list(SIGNAL_ADDTRAIT(TRAIT_CRITICAL_CONDITION)))
	for(var/iterator in 1 to greatest_dist)
		var/backwards_iterator = greatest_dist - iterator + 1 //We go backwards
		if(!to_transform["[backwards_iterator]"])
			continue
		addtimer(CALLBACK(src, PROC_REF(revert_terrain), to_transform["[backwards_iterator]"]), 1 * iterator)
	addtimer(CALLBACK(src, PROC_REF(revert_terrain), list(center_turf)), 1 SECONDS)
	if(ongoing_arena)
		QDEL_NULL(ongoing_arena)

/// Transforms all the turfs and restores the airlocks
/datum/action/cooldown/spell/wolves_among_sheep/proc/revert_terrain(list/turfs)
	for(var/turf/target as anything in turfs)
		target.remove_alt_appearance("heretic_arena")
		target.turf_flags = initial(target.turf_flags) // Restore flags to what they were
		for(var/obj/structure/window/to_revert in target)
			to_revert.remove_alt_appearance("heretic_arena")
	for(var/obj/machinery/door/airlock/to_restore in banished_airlocks)
		to_restore.forceMove(banished_airlocks[to_restore])
		banished_airlocks -= to_restore
