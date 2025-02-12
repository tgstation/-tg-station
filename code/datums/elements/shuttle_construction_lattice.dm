/// Element used to specify that a lattice is part of an incomplete shuttle frame
/datum/element/shuttle_construction_lattice
	element_flags = ELEMENT_DETACH_ON_HOST_DESTROY
	var/list/lattices_by_turf = list()

/datum/element/shuttle_construction_lattice/Attach(obj/structure/lattice/target)
	. = ..()
	if(!istype(target))
		return ELEMENT_INCOMPATIBLE
	var/turf/target_turf = target.loc
	if(!istype(target_turf))
		return ELEMENT_INCOMPATIBLE
	target_turf.AddElementTrait(TRAIT_SHUTTLE_CONSTRUCTION_TURF, REF(target), eletype = /datum/element/shuttle_construction_turf)
	lattices_by_turf[target_turf] = target
	RegisterSignal(target, COMSIG_ATOM_EXAMINE, PROC_REF(on_examined))
	RegisterSignal(target, COMSIG_MOVABLE_MOVED, PROC_REF(on_moved))
	RegisterSignal(target, COMSIG_LATTICE_PRE_REPLACE_WITH_CATWALK, PROC_REF(on_replacing_with_catwalk))
	RegisterSignal(target_turf, COMSIG_TURF_ADDED_TO_SHUTTLE, PROC_REF(on_turf_added_to_shuttle))

/datum/element/shuttle_construction_lattice/Detach(obj/source, ...)
	. = ..()
	var/turf/source_turf = source.loc
	if(istype(source_turf))
		REMOVE_TRAIT(source_turf, TRAIT_SHUTTLE_CONSTRUCTION_TURF, REF(source))
		lattices_by_turf -= source_turf
		UnregisterSignal(source_turf, COMSIG_TURF_ADDED_TO_SHUTTLE)
	UnregisterSignal(source, list(COMSIG_ATOM_EXAMINE, COMSIG_MOVABLE_MOVED, COMSIG_LATTICE_PRE_REPLACE_WITH_CATWALK))

/datum/element/shuttle_construction_lattice/proc/on_examined(obj/source, mob/user, list/examine_list)
	SIGNAL_HANDLER
	examine_list += span_notice("Cutting this [source.name] will <i>ruin the treatment that makes it suitable for shuttle construction</i>.")

/datum/element/shuttle_construction_lattice/proc/on_moved(obj/source, atom/old_loc)
	SIGNAL_HANDLER
	var/trait_source = REF(source)
	if(isturf(old_loc))
		REMOVE_TRAIT(old_loc, TRAIT_SHUTTLE_CONSTRUCTION_TURF, trait_source)
		UnregisterSignal(old_loc, COMSIG_TURF_ADDED_TO_SHUTTLE)
		lattices_by_turf -= old_loc
	var/turf/new_turf = source.loc
	if(istype(new_turf))
		new_turf.AddElementTrait(TRAIT_SHUTTLE_CONSTRUCTION_TURF, trait_source, /datum/element/shuttle_construction_turf)
		RegisterSignal(new_turf, COMSIG_TURF_ADDED_TO_SHUTTLE, PROC_REF(on_turf_added_to_shuttle))
		lattices_by_turf[new_turf] = source

/datum/element/shuttle_construction_lattice/proc/on_replacing_with_catwalk(obj/source, list/callbacks)
	SIGNAL_HANDLER
	callbacks += CALLBACK(src, PROC_REF(register_catwalk))

/datum/element/shuttle_construction_lattice/proc/register_catwalk(obj/structure/lattice/catwalk/new_catwalk)
	new_catwalk.AddElement(/datum/element/shuttle_construction_lattice)

/datum/element/shuttle_construction_lattice/proc/on_turf_added_to_shuttle(turf/source)
	var/obj/structure/lattice/turf_lattice = lattices_by_turf[source]
	turf_lattice?.RemoveElement(/datum/element/shuttle_construction_lattice)
