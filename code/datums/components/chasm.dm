// Used by /turf/open/chasm and subtypes to implement the "dropping" mechanic
/datum/component/chasm
	var/turf/target_turf
	var/obj/effect/abstract/chasm_storage/storage
	var/fall_message = "GAH! Ah... where are you?"
	var/oblivion_message = "You stumble and stare into the abyss before you. It stares back, and you fall into the enveloping dark."

	/// List of refs to falling objects -> how many levels deep we've fallen
	var/static/list/falling_atoms = list()
	var/static/list/forbidden_types = typecacheof(list(
		/obj/docking_port,
		/obj/effect/abstract,
		/obj/effect/collapse,
		/obj/effect/constructing_effect,
		/obj/effect/dummy/phased_mob,
		/obj/effect/ebeam,
		/obj/effect/fishing_float,
		/obj/effect/hotspot,
		/obj/effect/landmark,
		/obj/effect/light_emitter/tendril,
		/obj/effect/mapping_helpers,
		/obj/effect/particle_effect/ion_trails,
		/obj/effect/particle_effect/sparks,
		/obj/effect/portal,
		/obj/effect/projectile,
		/obj/effect/spectre_of_resurrection,
		/obj/effect/temp_visual,
		/obj/effect/wisp,
		/obj/energy_ball,
		/obj/narsie,
		/obj/projectile,
		/obj/singularity,
		/obj/structure/lattice,
		/obj/structure/stone_tile,
		/obj/structure/ore_vent,
	))

/datum/component/chasm/Initialize(turf/target, mapload)
	if(!isturf(parent))
		return COMPONENT_INCOMPATIBLE
	RegisterSignal(parent, SIGNAL_ADDTRAIT(TRAIT_CHASM_STOPPED), PROC_REF(on_chasm_stopped))
	RegisterSignal(parent, SIGNAL_REMOVETRAIT(TRAIT_CHASM_STOPPED), PROC_REF(on_chasm_no_longer_stopped))
	target_turf = target
	RegisterSignal(parent, COMSIG_ATOM_ABSTRACT_ENTERED, PROC_REF(entered))
	RegisterSignal(parent, COMSIG_ATOM_ABSTRACT_EXITED, PROC_REF(exited))
	RegisterSignal(parent, COMSIG_ATOM_AFTER_SUCCESSFUL_INITIALIZED_ON, PROC_REF(initialized_on))
	RegisterSignal(parent, COMSIG_ATOM_INTERCEPT_TELEPORTING, PROC_REF(block_teleport))
	//allow catwalks to give the turf the CHASM_STOPPED trait before dropping stuff when the turf is changed.
	//otherwise don't do anything because turfs and areas are initialized before movables.
	if(!mapload)
		addtimer(CALLBACK(src, PROC_REF(drop_stuff)), 0)
	parent.AddComponent(/datum/component/fishing_spot, GLOB.preset_fish_sources[/datum/fish_source/chasm])

/datum/component/chasm/UnregisterFromParent()
	storage = null

/datum/component/chasm/proc/entered(datum/source, atom/movable/arrived, atom/old_loc, list/atom/old_locs)
	SIGNAL_HANDLER
	drop_stuff()

/datum/component/chasm/proc/exited(datum/source, atom/movable/exited)
	SIGNAL_HANDLER
	UnregisterSignal(exited, list(COMSIG_MOVETYPE_FLAG_DISABLED, COMSIG_LIVING_SET_BUCKLED, COMSIG_MOVABLE_THROW_LANDED))

/datum/component/chasm/proc/initialized_on(datum/source, atom/movable/movable, mapload)
	SIGNAL_HANDLER
	drop_stuff(movable)

/datum/component/chasm/proc/block_teleport()
	return COMPONENT_BLOCK_TELEPORT

/datum/component/chasm/proc/on_chasm_stopped(datum/source)
	SIGNAL_HANDLER
	UnregisterSignal(source, list(COMSIG_ATOM_ENTERED, COMSIG_ATOM_EXITED, COMSIG_ATOM_AFTER_SUCCESSFUL_INITIALIZED_ON))
	for(var/atom/movable/movable as anything in source)
		UnregisterSignal(movable, list(COMSIG_MOVETYPE_FLAG_DISABLED, COMSIG_LIVING_SET_BUCKLED, COMSIG_MOVABLE_THROW_LANDED))

/datum/component/chasm/proc/on_chasm_no_longer_stopped(datum/source)
	SIGNAL_HANDLER
	RegisterSignal(parent, COMSIG_ATOM_ENTERED, PROC_REF(entered))
	RegisterSignal(parent, COMSIG_ATOM_EXITED, PROC_REF(exited))
	RegisterSignal(parent, COMSIG_ATOM_AFTER_SUCCESSFUL_INITIALIZED_ON, PROC_REF(initialized_on))
	drop_stuff()

#define CHASM_NOT_DROPPING 0
#define CHASM_DROPPING 1
///Doesn't drop the movable, but registers a few signals to try again if the conditions change.
#define CHASM_REGISTER_SIGNALS 2

/datum/component/chasm/proc/drop_stuff(atom/movable/dropped_thing)
	if(HAS_TRAIT(parent, TRAIT_CHASM_STOPPED))
		return
	var/atom/atom_parent = parent
	var/to_check = dropped_thing ? list(dropped_thing) : atom_parent.contents
	for (var/atom/movable/thing as anything in to_check)
		var/dropping = droppable(thing)
		switch(dropping)
			if(CHASM_DROPPING)
				INVOKE_ASYNC(src, PROC_REF(drop), thing)
			if(CHASM_REGISTER_SIGNALS)
				RegisterSignals(thing, list(COMSIG_MOVETYPE_FLAG_DISABLED, COMSIG_LIVING_SET_BUCKLED, COMSIG_MOVABLE_THROW_LANDED), PROC_REF(drop_stuff), TRUE)

/datum/component/chasm/proc/droppable(atom/movable/dropped_thing)
	var/datum/weakref/falling_ref = WEAKREF(dropped_thing)
	// avoid an infinite loop, but allow falling a large distance
	if(falling_atoms[falling_ref] && falling_atoms[falling_ref] > 30)
		return CHASM_NOT_DROPPING
	if(is_type_in_typecache(dropped_thing, forbidden_types) || (!isliving(dropped_thing) && !isobj(dropped_thing)))
		return CHASM_NOT_DROPPING
	if(dropped_thing.throwing || (dropped_thing.movement_type & MOVETYPES_NOT_TOUCHING_GROUND))
		return CHASM_REGISTER_SIGNALS
	for(var/atom/thing_to_check as anything in parent)
		if(HAS_TRAIT(thing_to_check, TRAIT_CHASM_STOPPER))
			return CHASM_NOT_DROPPING

	//Flies right over the chasm
	if(ismob(dropped_thing))
		var/mob/M = dropped_thing
		if(M.buckled) //middle statement to prevent infinite loops just in case!
			var/mob/buckled_to = M.buckled
			if((!ismob(M.buckled) || (buckled_to.buckled != M)) && !droppable(M.buckled))
				return CHASM_REGISTER_SIGNALS
		if(ishuman(dropped_thing))
			var/mob/living/carbon/human/victim = dropped_thing
			if(istype(victim.belt, /obj/item/wormhole_jaunter))
				var/obj/item/wormhole_jaunter/jaunter = victim.belt
				var/turf/chasm = get_turf(victim)
				var/fall_into_chasm = jaunter.chasm_react(victim)
				if(!fall_into_chasm)
					chasm.visible_message(span_boldwarning("[victim] falls into the [chasm]!")) //To freak out any bystanders
				return fall_into_chasm ? CHASM_DROPPING : CHASM_NOT_DROPPING
	return CHASM_DROPPING

#undef CHASM_NOT_DROPPING
#undef CHASM_DROPPING
#undef CHASM_REGISTER_SIGNALS

/datum/component/chasm/proc/drop(atom/movable/dropped_thing)
	var/datum/weakref/falling_ref = WEAKREF(dropped_thing)
	//Make sure the item is still there after our sleep
	if(!dropped_thing || !falling_ref?.resolve())
		falling_atoms -= falling_ref
		return
	falling_atoms[falling_ref] = (falling_atoms[falling_ref] || 0) + 1
	var/turf/below_turf = target_turf
	var/atom/parent = src.parent

	if(falling_atoms[falling_ref] > 1)
		return // We're already handling this

	if(below_turf)
		if(HAS_TRAIT(dropped_thing, TRAIT_CHASM_DESTROYED))
			qdel(dropped_thing)
			return

		// send to the turf below
		dropped_thing.visible_message(span_boldwarning("[dropped_thing] falls into [parent]!"), span_userdanger("[fall_message]"))
		below_turf.visible_message(span_boldwarning("[dropped_thing] falls from above!"))
		dropped_thing.forceMove(below_turf)
		if(isliving(dropped_thing))
			var/mob/living/fallen = dropped_thing
			fallen.Paralyze(100)
			fallen.adjustBruteLoss(30)
		falling_atoms -= falling_ref
		return

	// send to oblivion
	dropped_thing.visible_message(span_boldwarning("[dropped_thing] falls into [parent]!"), span_userdanger("[oblivion_message]"))
	if (isliving(dropped_thing))
		var/mob/living/falling_mob = dropped_thing
		ADD_TRAIT(falling_mob, TRAIT_NO_TRANSFORM, REF(src))
		falling_mob.Paralyze(20 SECONDS)

	var/oldtransform = dropped_thing.transform
	var/oldcolor = dropped_thing.color
	var/oldalpha = dropped_thing.alpha
	var/oldoffset = dropped_thing.pixel_y

	animate(dropped_thing, transform = matrix() - matrix(), alpha = 0, color = rgb(0, 0, 0), time = 10)
	for(var/i in 1 to 5)
		//Make sure the item is still there after our sleep
		if(!dropped_thing || QDELETED(dropped_thing))
			return
		dropped_thing.pixel_y--
		sleep(0.2 SECONDS)

	//Make sure the item is still there after our sleep
	if(!dropped_thing || QDELETED(dropped_thing))
		return

	if(HAS_TRAIT(dropped_thing, TRAIT_CHASM_DESTROYED))
		qdel(dropped_thing)
		return

	if(!storage)
		storage = (locate() in parent) || new(parent)

	if(storage.contains(dropped_thing))
		return

	dropped_thing.alpha = oldalpha
	dropped_thing.color = oldcolor
	dropped_thing.transform = oldtransform
	dropped_thing.pixel_y = oldoffset

	if(!dropped_thing.forceMove(storage))
		parent.visible_message(span_boldwarning("[parent] spits out [dropped_thing]!"))
		dropped_thing.throw_at(get_edge_target_turf(parent, pick(GLOB.alldirs)), rand(1, 10), rand(1, 10))

	else if(isliving(dropped_thing))
		var/mob/living/fallen_mob = dropped_thing
		REMOVE_TRAIT(fallen_mob, TRAIT_NO_TRANSFORM, REF(src))
		if (fallen_mob.stat != DEAD)
			fallen_mob.investigate_log("has died from falling into a chasm.", INVESTIGATE_DEATHS)
			if(issilicon(fallen_mob))
				//Silicons are held together by hopes and dreams, unfortunately, I'm having a nightmare
				var/mob/living/silicon/robot/fallen_borg = fallen_mob
				fallen_borg.mmi = null
			fallen_mob.death(TRUE)
			fallen_mob.apply_damage(300)

	falling_atoms -= falling_ref

/**
 * Called when something has left the chasm depths storage.
 * Arguments
 *
 * * source - Chasm object holder.
 * * gone - Item which has just left the chasm contents.
 */
/datum/component/chasm/proc/left_chasm(atom/source, atom/movable/gone)
	SIGNAL_HANDLER
	UnregisterSignal(gone, COMSIG_LIVING_REVIVE)

///Global list needed to let fishermen with a rescue hook fish fallen mobs from any place
GLOBAL_LIST_EMPTY(chasm_fallen_mobs)

/**
 * An abstract object which is basically just a bag that the chasm puts people inside
 */
/obj/effect/abstract/chasm_storage
	name = "chasm depths"
	desc = "The bottom of a hole. You shouldn't be able to interact with this."
	anchored = TRUE
	mouse_opacity = MOUSE_OPACITY_TRANSPARENT

/obj/effect/abstract/chasm_storage/Initialize(mapload)
	. = ..()
	ADD_TRAIT(src, TRAIT_SECLUDED_LOCATION, INNATE_TRAIT)

/obj/effect/abstract/chasm_storage/Entered(atom/movable/arrived)
	. = ..()
	if(isliving(arrived))
		//Mobs that have fallen in reserved area should be deleted to avoid fishing stuff from the deathmatch or VR.
		if(is_reserved_level(loc.z) && !istype(get_area(loc), /area/shuttle))
			qdel(arrived)
			return
		RegisterSignal(arrived, COMSIG_LIVING_REVIVE, PROC_REF(on_revive))
		LAZYADD(GLOB.chasm_fallen_mobs[get_chasm_category(loc)], arrived)

/obj/effect/abstract/chasm_storage/Exited(atom/movable/gone)
	. = ..()
	if(isliving(gone))
		UnregisterSignal(gone, COMSIG_LIVING_REVIVE)
		LAZYREMOVE(GLOB.chasm_fallen_mobs[get_chasm_category(loc)], gone)

/obj/effect/abstract/chasm_storage/on_changed_z_level(turf/old_turf, turf/new_turf, same_z_layer, notify_contents)
	. = ..()
	var/old_cat = get_chasm_category(old_turf)
	var/new_cat = get_chasm_category(new_turf)
	var/list/mobs = list()
	for(var/mob/fallen in src)
		mobs += fallen
	LAZYREMOVE(GLOB.chasm_fallen_mobs[old_cat], mobs)
	LAZYADD(GLOB.chasm_fallen_mobs[new_cat], mobs)

/**
 * Returns a key to store, remove and access fallen mobs depending on the z-level.
 * This stops rescuing people from places that are waaaaaaaay too far-fetched.
 */
/proc/get_chasm_category(turf/turf)
	var/z_level = turf?.z
	var/area/area = get_area(turf)
	if(istype(area, /area/shuttle)) //shuttle move between z-levels, so they're a special case.
		return area

	if(is_away_level(z_level))
		return ZTRAIT_AWAY
	if(is_mining_level(z_level))
		return ZTRAIT_MINING
	if(is_station_level(z_level))
		return ZTRAIT_STATION
	if(is_centcom_level(z_level))
		return ZTRAIT_CENTCOM
	if(is_reserved_level(z_level))
		return ZTRAIT_RESERVED

	return ZTRAIT_SPACE_RUINS

#define CHASM_TRAIT "chasm trait"
/**
 * Called if something comes back to life inside the pit. Expected sources are badmins and changelings.
 * Ethereals should take enough damage to be smashed and not revive.
 * Arguments
 * escapee - Lucky guy who just came back to life at the bottom of a hole.
 */
/obj/effect/abstract/chasm_storage/proc/on_revive(mob/living/escapee)
	SIGNAL_HANDLER
	var/turf/turf = get_turf(src)
	if(turf.GetComponent(/datum/component/chasm))
		turf.visible_message(span_boldwarning("After a long climb, [escapee] leaps out of [turf]!"))
	else
		playsound(turf, 'sound/effects/bang.ogg', 50, TRUE)
		turf.visible_message(span_boldwarning("[escapee] busts through [turf], leaping out of the chasm below"))
		turf.ScrapeAway(2, flags = CHANGETURF_INHERIT_AIR)
	ADD_TRAIT(escapee, TRAIT_MOVE_FLYING, CHASM_TRAIT) //Otherwise they instantly fall back in
	escapee.forceMove(turf)
	escapee.throw_at(get_edge_target_turf(turf, pick(GLOB.alldirs)), rand(1, 10), rand(1, 10))
	REMOVE_TRAIT(escapee, TRAIT_MOVE_FLYING, CHASM_TRAIT)
	escapee.Paralyze(20 SECONDS, TRUE)
	UnregisterSignal(escapee, COMSIG_LIVING_REVIVE)

#undef CHASM_TRAIT
