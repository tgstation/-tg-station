/**
 * The parent of this component will be destroyed if it's on the ground during a storm
 */
/datum/component/storm_hating
	/// Types of weather which trigger the effect
	var/static/list/stormy_weather = list(
		/datum/weather/ash_storm,
		/datum/weather/snow_storm,
		/datum/weather/void_storm,
	)

/datum/component/storm_hating/Initialize()
	. = ..()
	if (!isatom(parent))
		return COMPONENT_INCOMPATIBLE
	on_area_entered(parent, get_area(parent))

/datum/component/storm_hating/RegisterWithParent()
	. = ..()
	RegisterSignal(parent, COMSIG_ENTER_AREA, PROC_REF(on_area_entered))
	RegisterSignal(parent, COMSIG_EXIT_AREA, PROC_REF(on_area_exited))

/datum/component/storm_hating/UnregisterFromParent()
	. = ..()
	var/area/old_area = get_area(parent)
	if(!old_area)
		return
	on_area_exited(parent, old_area)
	UnregisterSignal(parent, list(COMSIG_ENTER_AREA, COMSIG_EXIT_AREA))

/datum/component/storm_hating/proc/on_area_entered(atom/source, area/new_area)
	SIGNAL_HANDLER
	for (var/weather in stormy_weather)
		RegisterSignal(new_area, COMSIG_WEATHER_BEGAN_IN_AREA(weather), PROC_REF(on_storm_event))
		RegisterSignal(new_area, COMSIG_WEATHER_ENDED_IN_AREA(weather), PROC_REF(on_storm_event))

/datum/component/storm_hating/proc/on_area_exited(atom/source, area/old_area)
	SIGNAL_HANDLER
	for (var/weather in stormy_weather)
		UnregisterSignal(old_area, COMSIG_WEATHER_BEGAN_IN_AREA(weather))
		UnregisterSignal(old_area, COMSIG_WEATHER_ENDED_IN_AREA(weather))

/datum/component/storm_hating/proc/on_storm_event()
	SIGNAL_HANDLER
	var/atom/parent_atom = parent
	if (!isturf(parent_atom.loc))
		return
	parent.AddElement(/datum/element/temporary_atom, life_time = 3 SECONDS, fade_time = 2 SECONDS)
	qdel(src)
