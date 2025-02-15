#define WEATHER_ALERT_CLEAR 0
#define WEATHER_ALERT_INCOMING 1
#define WEATHER_ALERT_IMMINENT_OR_ACTIVE 2

/// Component which makes you yell about what the weather is
/datum/component/weather_announcer
	/// Currently displayed warning level
	var/warning_level = WEATHER_ALERT_CLEAR
	/// Whether the incoming weather is actually going to harm you
	var/is_weather_dangerous = TRUE
	/// Are we actually turned on right now?
	var/enabled = TRUE
	/// Overlay added when things are alright
	var/state_normal
	/// Overlay added when you should start looking for shelter
	var/state_warning
	/// Overlay added when you are in danger
	var/state_danger

/datum/component/weather_announcer/Initialize(
	state_normal,
	state_warning,
	state_danger,
)
	. = ..()
	if (!ismovable(parent))
		return COMPONENT_INCOMPATIBLE

	START_PROCESSING(SSprocessing, src)
	RegisterSignal(parent, COMSIG_ATOM_UPDATE_OVERLAYS, PROC_REF(on_update_overlays))
	RegisterSignal(parent, COMSIG_MACHINERY_POWER_RESTORED, PROC_REF(on_powered))
	RegisterSignal(parent, COMSIG_MACHINERY_POWER_LOST, PROC_REF(on_power_lost))

	src.state_normal = state_normal
	src.state_warning = state_warning
	src.state_danger = state_danger
	var/atom/speaker = parent
	speaker.update_appearance(UPDATE_ICON)
	update_light_color()

/datum/component/weather_announcer/Destroy(force)
	STOP_PROCESSING(SSprocessing, src)
	return ..()

/// Add appropriate overlays
/datum/component/weather_announcer/proc/on_update_overlays(atom/parent_atom, list/overlays)
	SIGNAL_HANDLER
	if (!enabled || !state_normal || !state_warning || !state_danger)
		return

	switch (warning_level)
		if(WEATHER_ALERT_CLEAR)
			overlays += state_normal
		if(WEATHER_ALERT_INCOMING)
			overlays += state_warning
		if(WEATHER_ALERT_IMMINENT_OR_ACTIVE)
			overlays += (is_weather_dangerous) ? state_danger : state_warning

/// If powered, receive updates
/datum/component/weather_announcer/proc/on_powered()
	SIGNAL_HANDLER
	enabled = TRUE
	var/atom/speaker = parent
	speaker.update_appearance(UPDATE_ICON)

/// If no power, don't receive updates
/datum/component/weather_announcer/proc/on_power_lost()
	SIGNAL_HANDLER
	enabled = FALSE
	var/atom/speaker = parent
	speaker.update_appearance(UPDATE_ICON)

/datum/component/weather_announcer/process(seconds_per_tick)
	if (!enabled)
		return

	var/previous_level = warning_level
	var/previous_danger = is_weather_dangerous
	set_current_alert_level()
	if(previous_level == warning_level && previous_danger == is_weather_dangerous)
		return // No change
	var/atom/movable/speaker = parent
	var/msg = get_warning_message()
	var/obj/machinery/announcement_system/aas = get_announcement_system(/datum/aas_config_entry/weather, speaker)
	// Active AAS will override default announcement lines
	if (aas)
		msg = aas.compile_config_message(/datum/aas_config_entry/weather, list(), !is_weather_dangerous ? 4 : warning_level + 1)
		// Stop toggling on radios for it, please!
		aas.broadcast(msg, list(RADIO_CHANNEL_SUPPLY))
	// Still say it, because you can be not on our level
	speaker.say(msg)
	speaker.update_appearance(UPDATE_ICON)
	update_light_color()

/datum/component/weather_announcer/proc/update_light_color()
	var/atom/movable/light = parent
	switch(warning_level)
		if(WEATHER_ALERT_CLEAR)
			light.set_light_color(LIGHT_COLOR_GREEN)
		if(WEATHER_ALERT_INCOMING)
			light.set_light_color(LIGHT_COLOR_DIM_YELLOW)
		if(WEATHER_ALERT_IMMINENT_OR_ACTIVE)
			light.set_light_color(LIGHT_COLOR_INTENSE_RED)
	light.update_light()

/// Returns a string we should display to communicate what you should be doing
/datum/component/weather_announcer/proc/get_warning_message()
	if (!is_weather_dangerous)
		return "No risk expected from incoming weather front."
	switch(warning_level)
		if(WEATHER_ALERT_CLEAR)
			return "All clear, no weather alerts to report."
		if(WEATHER_ALERT_INCOMING)
			return "Weather front incoming, begin to seek shelter."
		if(WEATHER_ALERT_IMMINENT_OR_ACTIVE)
			return "Weather front imminent, find shelter immediately."
	return "Error in meteorological calculation. Please report this deviation to a trained programmer."

/datum/component/weather_announcer/proc/time_till_storm()
	var/list/mining_z_levels = SSmapping.levels_by_trait(ZTRAIT_MINING)
	if(!length(mining_z_levels))
		return // No problems if there are no mining z levels


	for(var/datum/weather/check_weather as anything in SSweather.processing)
		if(!check_weather.barometer_predictable || check_weather.stage == WIND_DOWN_STAGE || check_weather.stage == END_STAGE)
			continue
		for (var/mining_level in mining_z_levels)
			if(mining_level in check_weather.impacted_z_levels)
				warning_level = WEATHER_ALERT_IMMINENT_OR_ACTIVE
				return 0

	var/time_until_next = INFINITY
	for(var/mining_level in mining_z_levels)
		var/next_time = timeleft(SSweather.next_hit_by_zlevel["[mining_level ]"]) || INFINITY
		if (next_time && next_time < time_until_next)
			time_until_next = next_time
	return time_until_next

/// Polls existing weather for what kind of warnings we should be displaying.
/datum/component/weather_announcer/proc/set_current_alert_level()
	var/time_until_next = time_till_storm()
	if(isnull(time_until_next))
		return // No problems if there are no mining z levels
	if(time_until_next >= 2 MINUTES)
		warning_level = WEATHER_ALERT_CLEAR
		return

	if(time_until_next >= 30 SECONDS)
		warning_level = WEATHER_ALERT_INCOMING
		return

	// Weather is here, now we need to figure out if it is dangerous
	warning_level = WEATHER_ALERT_IMMINENT_OR_ACTIVE

	for(var/datum/weather/check_weather as anything in SSweather.processing)
		if(!check_weather.barometer_predictable || check_weather.stage == WIND_DOWN_STAGE || check_weather.stage == END_STAGE)
			continue
		var/list/mining_z_levels = SSmapping.levels_by_trait(ZTRAIT_MINING)
		for(var/mining_level in mining_z_levels)
			if(mining_level in check_weather.impacted_z_levels)
				is_weather_dangerous = !check_weather.aesthetic
				return

/datum/component/weather_announcer/proc/on_examine(atom/radio, mob/examiner, list/examine_texts)
	var/time_until_next = time_till_storm()
	if(isnull(time_until_next))
		return
	if (time_until_next == 0)
		examine_texts += span_warning ("A storm is currently active, please seek shelter.")
	else
		examine_texts += span_notice("The next storm is inbound in [DisplayTimeText(time_until_next)].")

/datum/component/weather_announcer/RegisterWithParent()
	RegisterSignal(parent, COMSIG_ATOM_EXAMINE, PROC_REF(on_examine))

/datum/component/weather_announcer/UnregisterFromParent()
	.=..()
	UnregisterSignal(parent, COMSIG_ATOM_EXAMINE)

/datum/aas_config_entry/weather
	name = "Cargo Alert: Weather Forecast"
	general_tooltip = "Allows the radio to announce incoming weather."
	announcement_lines_map = list(
		"Clear" = "All clear, no weather alerts to report.",
		"Incoming" = "Weather front incoming, begin to seek shelter.",
		"Imminent or Active" = "Weather front imminent, find shelter immediately.",
		"Safe" = "No risk expected from incoming weather front.",
	)


#undef WEATHER_ALERT_CLEAR
#undef WEATHER_ALERT_INCOMING
#undef WEATHER_ALERT_IMMINENT_OR_ACTIVE
