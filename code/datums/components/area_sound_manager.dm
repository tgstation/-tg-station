///Allows you to set a theme for a set of areas without tying them to looping sounds explicitly
/datum/component/area_sound_manager
	dupe_mode = COMPONENT_DUPE_ALLOWED
	///area -> looping sound type
	var/list/area_to_looping_type = list()
	///Current sound loop
	var/datum/looping_sound/our_loop
	///A list of "acceptable" z levels to be on. If you leave this, we're gonna delete ourselves
	var/list/accepted_zs
	///The timer id of our current start delay, if it exists
	var/timerid

/datum/component/area_sound_manager/Initialize(area_loop_pairs, change_on, remove_on, acceptable_zs)
	if(!ismovable(parent))
		return
	area_to_looping_type = area_loop_pairs
	accepted_zs = acceptable_zs
	change_the_track()

	RegisterSignal(parent, COMSIG_MOVABLE_MOVED, PROC_REF(react_to_move))
	RegisterSignal(parent, COMSIG_MOVABLE_Z_CHANGED, PROC_REF(react_to_z_move))
	// change on can be a list of signals
	if(islist(change_on))
		RegisterSignals(parent, change_on, PROC_REF(handle_change))
	else if(!isnull(change_on))
		RegisterSignal(parent, change_on, PROC_REF(handle_change))
	// remove on can be a list of signals
	if(islist(remove_on))
		RegisterSignals(parent, remove_on, PROC_REF(handle_removal))
	else if(!isnull(remove_on))
		RegisterSignal(parent, remove_on, PROC_REF(handle_removal))

/datum/component/area_sound_manager/Destroy(force)
	QDEL_NULL(our_loop)
	. = ..()

/datum/component/area_sound_manager/proc/react_to_move(datum/source, atom/oldloc, dir, forced)
	SIGNAL_HANDLER
	var/list/loop_lookup = area_to_looping_type
	if(loop_lookup[get_area(oldloc)] == loop_lookup[get_area(parent)])
		return
	change_the_track(TRUE)

/datum/component/area_sound_manager/proc/react_to_z_move(datum/source, turf/old_turf, turf/new_turf)
	SIGNAL_HANDLER
	if(!length(accepted_zs) || (new_turf.z in accepted_zs))
		return
	qdel(src)

/datum/component/area_sound_manager/proc/handle_removal(datum/source)
	SIGNAL_HANDLER
	qdel(src)

/datum/component/area_sound_manager/proc/handle_change(datum/source)
	SIGNAL_HANDLER
	change_the_track()

/datum/component/area_sound_manager/proc/change_the_track(skip_start = FALSE)
	var/time_remaining = 0

	if(our_loop)
		var/our_id = our_loop.timer_id || timerid
		if(our_id)
			time_remaining = timeleft(our_id, SSsound_loops) || 0
			//Time left will sometimes return negative values, just ignore them and start a new sound loop now
			time_remaining = max(time_remaining, 0)
		QDEL_NULL(our_loop)

	var/area/our_area = get_area(parent)
	var/new_loop_type = area_to_looping_type[our_area]
	if(!new_loop_type)
		return

	our_loop = new new_loop_type(parent, FALSE, TRUE, skip_start)

	//If we're still playing, wait a bit before changing the sound so we don't double up
	if(time_remaining)
		timerid = addtimer(CALLBACK(src, PROC_REF(start_looping_sound)), time_remaining, TIMER_UNIQUE | TIMER_CLIENT_TIME | TIMER_STOPPABLE | TIMER_NO_HASH_WAIT | TIMER_DELETE_ME, SSsound_loops)
		return
	timerid = null
	our_loop.start()

/datum/component/area_sound_manager/proc/start_looping_sound()
	timerid = null
	if(our_loop)
		our_loop.start()
