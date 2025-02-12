// Turf signals. Format:
// When the signal is called: (signal arguments)
// All signals send the source datum of the signal as the first argument

/// from base of turf/ChangeTurf(): (path, list/new_baseturfs, flags, list/post_change_callbacks).
/// `post_change_callbacks` is a list that signal handlers can mutate to append `/datum/callback` objects.
/// They will be called with the new turf after the turf has changed.
#define COMSIG_TURF_CHANGE "turf_change"
///from base of atom/has_gravity(): (atom/asker, list/forced_gravities)
#define COMSIG_TURF_HAS_GRAVITY "turf_has_gravity"
///from base of turf/multiz_turf_del(): (turf/source, direction)
#define COMSIG_TURF_MULTIZ_DEL "turf_multiz_del"
///from base of turf/multiz_turf_new: (turf/source, direction)
#define COMSIG_TURF_MULTIZ_NEW "turf_multiz_new"
///from base of turf/proc/onShuttleMove(): (turf/new_turf)
#define COMSIG_TURF_ON_SHUTTLE_MOVE "turf_on_shuttle_move"
///from base of /datum/turf_reservation/proc/Release: (datum/turf_reservation/reservation)
#define COMSIG_TURF_RESERVATION_RELEASED "turf_reservation_released"
///from /turf/open/temperature_expose(datum/gas_mixture/air, exposed_temperature)
#define COMSIG_TURF_EXPOSE "turf_expose"
///from /turf/proc/immediate_calculate_adjacent_turfs()
#define COMSIG_TURF_CALCULATED_ADJACENT_ATMOS "turf_calculated_adjacent_atmos"
///called when an elevator enters this turf
#define COMSIG_TURF_INDUSTRIAL_LIFT_ENTER "turf_industrial_life_enter"

///from /datum/element/decal/Detach(): (description, cleanable, directional, mutable_appearance/pic)
#define COMSIG_TURF_DECAL_DETACHED "turf_decal_detached"

///from /obj/item/pushbroom/sweep(): (broom, user, items_to_sweep)
#define COMSIG_TURF_RECEIVE_SWEEPED_ITEMS "turf_receive_sweeped_items"

///from /datum/element/footstep/prepare_step(): (list/steps)
#define COMSIG_TURF_PREPARE_STEP_SOUND "turf_prepare_step_sound"
	//stops element/footstep/proc/prepare_step() from returning null if the turf itself has no sound
	#define FOOTSTEP_OVERRIDEN (1<<0)
///from base of datum/thrownthing/finalize(): (turf/turf, atom/movable/thrownthing) when something is thrown and lands on us
#define COMSIG_TURF_MOVABLE_THROW_LANDED "turf_movable_throw_landed"

///From element/elevation/reset_elevation(): (list/values)
#define COMSIG_TURF_RESET_ELEVATION "turf_reset_elevation"
	#define ELEVATION_CURRENT_PIXEL_SHIFT 1
	#define ELEVATION_MAX_PIXEL_SHIFT 2

///Called when turf no longer blocks light from passing through
#define COMSIG_TURF_NO_LONGER_BLOCK_LIGHT "turf_no_longer_block_light"

///from /turf/proc/attempt_lattice_replacement() : (list/post_successful_replacement_callbacks)
/// `post_successful_replacement_callbacks` is a list that signal handlers can mutate to append `/datum/callback` objects.
/// They will be called with the new catwalk if it is actually created.
#define COMSIG_TURF_ATTEMPT_LATTICE_REPLACEMENT "turf_replaced_with_lattice"

///from /turf/proc/change_area() : (area/old_area)
#define COMSIG_TURF_AREA_CHANGED "turf_area_changed"

///from /proc/create_shuttle() and /obj/docking_port/mobile/proc/add_turf() : (obj/docking_port/mobile/shuttle)
#define COMSIG_TURF_ADDED_TO_SHUTTLE "turf_added_to_shuttle"
