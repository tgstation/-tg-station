// Area signals. Format:
// When the signal is called: (signal arguments)
// All signals send the source datum of the signal as the first argument

///from base of area/proc/power_change(): ()
#define COMSIG_AREA_POWER_CHANGE "area_power_change"
///from base of area/Entered(): (atom/movable/arrived, area/old_area)
#define COMSIG_AREA_ENTERED "area_entered"
///from base of area/Exited(): (atom/movable/gone, direction)
#define COMSIG_AREA_EXITED "area_exited"
///from base of area/Entered(): (area/new_area). Sent to "area-sensitive" movables, see __DEFINES/traits.dm for info.
#define COMSIG_ENTER_AREA "enter_area"
///from base of area/Exited(): (area). Sent to "area-sensitive" movables, see __DEFINES/traits.dm for info.
#define COMSIG_EXIT_AREA "exit_area"

// Alarm listener datum signals
///Sent when an alarm is fired and an alarm listener has tracked onto it (alarm, area/source_area)
#define COMSIG_ALARM_LISTENER_TRIGGERED "alarm_listener_triggered"
///Send when an alarm source is cleared and an alarm listener has tracked onto it (alarm_type, area/source_area)
#define COMSIG_ALARM_LISTENER_CLEARED "alarm_listener_clear"

/// Called when an alarm handler fires an alarm
#define COMSIG_ALARM_TRIGGERED "alarm_triggered"
/// Called when an alarm handler clears an alarm
#define COMSIG_ALARM_CLEARED "alarm_cleared"

/// Called when the air alarm mode is updated
#define COMSIG_AIRALARM_UPDATE_MODE "airalarm_update_mode"

// Area fire signals
/// Sent when an area's fire var changes: (fire_value)
#define COMSIG_AREA_FIRE_CHANGED "area_fire_set"

/// Called when some weather starts in this area
#define COMSIG_WEATHER_BEGAN_IN_AREA(event_type) "weather_began_in_area_[event_type]"
/// Called when some weather ends in this area
#define COMSIG_WEATHER_ENDED_IN_AREA(event_type) "weather_ended_in_area_[event_type]"

///From base of area/update_beauty()
#define COMSIG_AREA_BEAUTY_UPDATED "area_beauty_updated"

/// From base of turf/change_area(area/old_area)
#define COMSIG_AREA_TURF_ADDED "area_turf_added"

/// From base of turf/change_area(area/new_area)
#define COMSIG_AREA_TURF_REMOVED "area_turf_removed"
