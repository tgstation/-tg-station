/**
 * Causes weather to occur on a z level in certain area types
 *
 * The effects of weather occur across an entire z-level. For instance, lavaland has periodic ash storms that scorch most unprotected creatures.
 * Weather always occurs on different z levels at different times, regardless of weather type.
 * Can have custom durations, targets, and can automatically protect indoor areas.
 *
 */

/datum/weather
	/// name of weather
	var/name = "space wind"
	/// description of weather
	var/desc = "Heavy gusts of wind blanket the area, periodically knocking down anyone caught in the open."
	/// The message displayed in chat to foreshadow the weather's beginning
	var/telegraph_message = span_warning("The wind begins to pick up.")
	/// How long from the beginning of the telegraph until the weather begins
	var/telegraph_duration = 30 SECONDS
	/// The sound file played to everyone on an affected z-level
	var/telegraph_sound
	/// The overlay applied to all tiles on the z-level
	var/telegraph_overlay

	/// Displayed in chat once the weather begins in earnest
	var/weather_message = span_userdanger("The wind begins to blow ferociously!")
	/// How long the weather lasts once it begins
	var/weather_duration = 2 MINUTES
	/// See above - this is the lowest possible duration
	var/weather_duration_lower = 2 MINUTES
	/// See above - this is the highest possible duration
	var/weather_duration_upper = 2.5 MINUTES
	/// Looping sound while weather is occuring
	var/weather_sound
	/// Area overlay while the weather is occuring
	var/weather_overlay
	/// Color to apply to the area while weather is occuring
	var/weather_color = null

	/// Displayed once the weather is over
	var/end_message = span_danger("The wind relents its assault.")
	/// How long the "wind-down" graphic will appear before vanishing entirely
	var/end_duration = 30 SECONDS
	/// Sound that plays while weather is ending
	var/end_sound
	/// Area overlay while weather is ending
	var/end_overlay

	/// Types of area to affect
	var/area_type = /area/space
	/// TRUE value protects areas with outdoors marked as false, regardless of area type
	var/protect_indoors = FALSE
	/// Areas to be affected by the weather, calculated when the weather begins
	var/list/impacted_areas = list()
	/// Areas affected by weather have their blend modes changed
	var/list/impacted_areas_blend_modes = list()
	/// Areas that are protected and excluded from the affected areas.
	var/list/protected_areas = list()
	/// The list of z-levels that this weather is actively affecting
	var/impacted_z_levels

	/// Since it's above everything else, this is the layer used by default.
	var/overlay_layer = AREA_LAYER
	/// Plane for the overlay
	var/overlay_plane = WEATHER_PLANE
	/// If the weather has no purpose other than looks
	var/aesthetic = FALSE
	/// Used by mobs (or movables containing mobs, such as enviro bags) to prevent them from being affected by the weather.
	var/immunity_type
	/// If this bit of weather should also draw an overlay that's uneffected by lighting onto the area
	/// Taken from weather_glow.dmi
	var/use_glow = TRUE
	/// List of all overlays to apply to our turfs
	var/list/overlay_cache

	/// The stage of the weather, from 1-4
	var/stage = END_STAGE

	/// Weight amongst other eligible weather. If zero, will never happen randomly.
	var/probability = 0
	/// The z-level trait to affect when run randomly or when not overridden.
	var/target_trait = ZTRAIT_STATION

	/// Whether a barometer can predict when the weather will happen
	var/barometer_predictable = FALSE
	/// For barometers to know when the next storm will hit
	var/next_hit_time = 0
	/// This causes the weather to only end if forced to
	var/perpetual = FALSE

/datum/weather/New(z_levels)
	..()
	impacted_z_levels = z_levels

/**
 * Telegraphs the beginning of the weather on the impacted z levels
 *
 * Sends sounds and details to mobs in the area
 * Calculates duration and hit areas, and makes a callback for the actual weather to start
 *
 */
/datum/weather/proc/telegraph()
	if(stage == STARTUP_STAGE)
		return
	SEND_GLOBAL_SIGNAL(COMSIG_WEATHER_TELEGRAPH(type), src)
	stage = STARTUP_STAGE
	var/list/affectareas = list()
	for(var/area/selected_area as anything in get_areas(area_type))
		affectareas += selected_area
	for(var/area/protected_area as anything in protected_areas)
		affectareas -= get_areas(protected_area)
	for(var/area/affected_area as anything in affectareas)
		if(protect_indoors && !affected_area.outdoors)
			continue

		for(var/z in impacted_z_levels)
			if(length(affected_area.turfs_by_zlevel) >= z && length(affected_area.turfs_by_zlevel[z]))
				impacted_areas |= affected_area
				continue

	weather_duration = rand(weather_duration_lower, weather_duration_upper)
	SSweather.processing |= src
	update_areas()
	if(telegraph_duration)
		send_alert(telegraph_message, telegraph_sound)
	addtimer(CALLBACK(src, PROC_REF(start)), telegraph_duration)

/**
 * Starts the actual weather and effects from it
 *
 * Updates area overlays and sends sounds and messages to mobs to notify them
 * Begins dealing effects from weather to mobs in the area
 *
 */
/datum/weather/proc/start()
	if(stage >= MAIN_STAGE)
		return
	SEND_GLOBAL_SIGNAL(COMSIG_WEATHER_START(type), src)
	stage = MAIN_STAGE
	update_areas()
	send_alert(weather_message, weather_sound)
	if(!perpetual)
		addtimer(CALLBACK(src, PROC_REF(wind_down)), weather_duration)
	for(var/area/impacted_area as anything in impacted_areas)
		SEND_SIGNAL(impacted_area, COMSIG_WEATHER_BEGAN_IN_AREA(type), src)

/**
 * Weather enters the winding down phase, stops effects
 *
 * Updates areas to be in the winding down phase
 * Sends sounds and messages to mobs to notify them
 *
 */
/datum/weather/proc/wind_down()
	if(stage >= WIND_DOWN_STAGE)
		return
	SEND_GLOBAL_SIGNAL(COMSIG_WEATHER_WINDDOWN(type), src)
	stage = WIND_DOWN_STAGE
	update_areas()
	send_alert(end_message, end_sound)
	addtimer(CALLBACK(src, PROC_REF(end)), end_duration)

/**
 * Fully ends the weather
 *
 * Effects no longer occur and area overlays are removed
 * Removes weather from processing completely
 *
 */
/datum/weather/proc/end()
	if(stage == END_STAGE)
		return
	SEND_GLOBAL_SIGNAL(COMSIG_WEATHER_END(type), src)
	stage = END_STAGE
	SSweather.processing -= src
	update_areas()
	for(var/area/impacted_area as anything in impacted_areas)
		SEND_SIGNAL(impacted_area, COMSIG_WEATHER_ENDED_IN_AREA(type), src)

// handles sending all alerts
/datum/weather/proc/send_alert(alert_msg, alert_sfx)
	for(var/z_level in impacted_z_levels)
		for(var/mob/player as anything in SSmobs.clients_by_zlevel[z_level])
			if(!can_get_alert(player))
				continue
			if(alert_msg)
				to_chat(player, alert_msg)
			if(alert_sfx)
				SEND_SOUND(player, sound(alert_sfx))

// the checks for if a mob should receive alerts, returns TRUE if can
/datum/weather/proc/can_get_alert(mob/player)
	var/turf/mob_turf = get_turf(player)
	return !isnull(mob_turf)

/**
 * Returns TRUE if the living mob can be affected by the weather
 *
 */
/datum/weather/proc/can_weather_act(mob/living/mob_to_check)
	var/turf/mob_turf = get_turf(mob_to_check)

	if(!mob_turf)
		return

	if(!(mob_turf.z in impacted_z_levels))
		return

	if((immunity_type && HAS_TRAIT(mob_to_check, immunity_type)) || HAS_TRAIT(mob_to_check, TRAIT_WEATHER_IMMUNE))
		return

	var/atom/loc_to_check = mob_to_check.loc
	while(loc_to_check != mob_turf)
		if((immunity_type && HAS_TRAIT(loc_to_check, immunity_type)) || HAS_TRAIT(loc_to_check, TRAIT_WEATHER_IMMUNE))
			return
		loc_to_check = loc_to_check.loc

	if(!(get_area(mob_to_check) in impacted_areas))
		return

	return TRUE

/**
 * Affects the mob with whatever the weather does
 *
 */
/datum/weather/proc/weather_act(mob/living/L)
	return

/**
 * Updates the overlays on impacted areas
 *
 */
/datum/weather/proc/update_areas()
	var/list/new_overlay_cache = generate_overlay_cache()
	for(var/area/impacted as anything in impacted_areas)
		if(length(overlay_cache))
			impacted.overlays -= overlay_cache
			if(impacted_areas_blend_modes[impacted])
				// revert the blend mode to the old state
				impacted.blend_mode = impacted_areas_blend_modes[impacted]
				impacted_areas_blend_modes[impacted] = null
		if(length(new_overlay_cache))
			impacted.overlays += new_overlay_cache
			// only change the blend mode if it's not default or overlay
			if(impacted.blend_mode > BLEND_OVERLAY)
				// save the old blend mode state
				impacted_areas_blend_modes[impacted] = impacted.blend_mode
				impacted.blend_mode = BLEND_OVERLAY

	overlay_cache = new_overlay_cache

/// Returns a list of visual offset -> overlays to use
/datum/weather/proc/generate_overlay_cache()
	// We're ending, so no overlays at all
	if(stage == END_STAGE)
		return list()

	var/weather_state = ""
	switch(stage)
		if(STARTUP_STAGE)
			weather_state = telegraph_overlay
		if(MAIN_STAGE)
			weather_state = weather_overlay
		if(WIND_DOWN_STAGE)
			weather_state = end_overlay

	// Use all possible offsets
	// Yes this is a bit annoying, but it's too slow to calculate and store these from turfs, and it shouldn't (I hope) look weird
	var/list/gen_overlay_cache = list()
	for(var/offset in 0 to SSmapping.max_plane_offset)
		// Note: what we do here is effectively apply two overlays to each area, for every unique multiz layer they inhabit
		// One is the base, which will be masked by lighting. the other is "glowing", and provides a nice contrast
		// This method of applying one overlay per z layer has some minor downsides, in that it could lead to improperly doubled effects if some have alpha
		// I prefer it to creating 2 extra plane masters however, so it's a cost I'm willing to pay
		// LU
		if(use_glow)
			var/mutable_appearance/glow_overlay = mutable_appearance('icons/effects/glow_weather.dmi', weather_state, overlay_layer, null, WEATHER_GLOW_PLANE, 100, offset_const = offset)
			glow_overlay.color = weather_color
			gen_overlay_cache += glow_overlay

		var/mutable_appearance/new_weather_overlay = mutable_appearance('icons/effects/weather_effects.dmi', weather_state, overlay_layer, plane = overlay_plane, offset_const = offset)
		new_weather_overlay.color = weather_color
		gen_overlay_cache += new_weather_overlay

	return gen_overlay_cache
