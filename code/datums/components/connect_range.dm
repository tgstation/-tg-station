/**
 * This component behaves similar to connect_loc_behalf but for all turfs in range, hooking into a signal on each of them.
 * Just like connect_loc_behalf, It can react to that signal on behalf of a separate listener.
 * Good for components, though it carries some overhead. Can't be an element as that may lead to bugs.
 */
/datum/component/connect_range
	dupe_mode = COMPONENT_DUPE_UNIQUE_PASSARGS

	/// An assoc list of signal -> procpath to register to the loc this object is on.
	var/list/connections
	/// The turfs currently connected to this component
	var/list/turfs = list()
	/**
	 * The atom the component is tracking. The component will delete itself if the tracked is deleted.
	 * Signals will also be updated whenever it moves (if it's a movable).
	 */
	var/atom/tracked

	/// The component will hook into signals only on turfs not farther from tracked than this.
	var/range
	/// Whether the component works when the movable isn't directly located on a turf.
	var/works_in_containers

/datum/component/connect_range/Initialize(atom/tracked, list/connections, range, works_in_containers = TRUE)
	if(!isatom(tracked) || isarea(tracked) || range < 0)
		return COMPONENT_INCOMPATIBLE
	src.connections = connections
	src.range = range
	set_tracked(tracked)
	src.works_in_containers = works_in_containers

/datum/component/connect_range/Destroy()
	set_tracked(null)
	return ..()

/datum/component/connect_range/InheritComponent(datum/component/component, original, atom/tracked, list/connections, range, works_in_containers)
	// Not equivalent. Checks if they are not the same list via shallow comparison.
	if(!compare_list(src.connections, connections))
		stack_trace("connect_range component attached to [parent] tried to inherit another connect_range component with different connections")
		return
	if(src.tracked != tracked)
		set_tracked(tracked)
	if(src.range == range && src.works_in_containers == works_in_containers)
		return
	//Unregister the signals with the old settings.
	unregister_signals(isturf(tracked) ? tracked : tracked.loc, turfs)
	src.range = range
	src.works_in_containers = works_in_containers
	//Re-register the signals with the new settings.
	update_signals(src.tracked)

/datum/component/connect_range/proc/set_tracked(atom/new_tracked)
	if(tracked) //Unregister the signals from the old tracked and its surroundings
		unregister_signals(isturf(tracked) ? tracked : tracked.loc, turfs)
		UnregisterSignal(tracked, list(
			COMSIG_MOVABLE_MOVED,
			COMSIG_QDELETING,
		))
	tracked = new_tracked
	if(!tracked)
		return
	//Register signals on the new tracked atom and its surroundings.
	RegisterSignal(tracked, COMSIG_MOVABLE_MOVED, PROC_REF(on_moved))
	RegisterSignal(tracked, COMSIG_QDELETING, PROC_REF(handle_tracked_qdel))
	update_signals(tracked)

/datum/component/connect_range/proc/handle_tracked_qdel()
	SIGNAL_HANDLER
	qdel(src)

/datum/component/connect_range/proc/update_signals(atom/target, atom/old_loc)
	var/turf/current_turf = get_turf(target)
	if(isnull(current_turf))
		unregister_signals(old_loc, turfs)
		turfs = list()
		return

	var/loc_is_movable = ismovable(target.loc)

	if(loc_is_movable)
		if(!works_in_containers)
			unregister_signals(old_loc, turfs)
			turfs = list()
			return

	//Only register/unregister turf signals if it's moved to a new turf.
	if(current_turf == get_turf(old_loc))
		unregister_signals(old_loc, null)
		return
	var/list/old_turfs = turfs
	turfs = RANGE_TURFS(range, current_turf)
	unregister_signals(old_loc, old_turfs - turfs)
	if(loc_is_movable)
		//Keep track of possible movement of all movables the target is in.
		for(var/atom/movable/container as anything in get_nested_locs(target))
			RegisterSignal(container, COMSIG_MOVABLE_MOVED, PROC_REF(on_moved))
	for(var/turf/target_turf as anything in turfs - old_turfs)
		for(var/signal in connections)
			parent.RegisterSignal(target_turf, signal, connections[signal])

/datum/component/connect_range/proc/unregister_signals(atom/location, list/remove_from)
	//The location is null or is a container and the component shouldn't have register signals on it
	if(isnull(location) || (!works_in_containers && !isturf(location)))
		return

	if(ismovable(location))
		for(var/atom/movable/target as anything in (get_nested_locs(location) + location))
			UnregisterSignal(target, COMSIG_MOVABLE_MOVED)

	if(!length(remove_from))
		return
	for(var/turf/target_turf as anything in remove_from)
		parent.UnregisterSignal(target_turf, connections)

/datum/component/connect_range/proc/on_moved(atom/movable/movable, atom/old_loc)
	SIGNAL_HANDLER
	update_signals(movable, old_loc)
