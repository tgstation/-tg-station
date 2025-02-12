/datum/weather/snow_storm
	name = "snow storm"
	desc = "Harsh snowstorms roam the topside of this arctic planet, burying any area unfortunate enough to be in its path."
	probability = 90

	telegraph_message = span_warning("Drifting particles of snow begin to dust the surrounding area..")
	telegraph_duration = 30 SECONDS
	telegraph_overlay = "light_snow"
	telegraph_sound = 'sound/ambience/weather/snowstorm/snow_start.ogg'
	telegraph_sound_vol = /datum/looping_sound/snowstorm::volume + 10

	weather_message = span_userdanger("<i>Harsh winds pick up as dense snow begins to fall from the sky! Seek shelter!</i>")
	weather_overlay = "snow_storm"
	weather_duration_lower = 60 SECONDS
	weather_duration_upper = 150 SECONDS
	use_glow = FALSE

	end_duration = 10 SECONDS
	end_message = span_bolddanger("The snowfall dies down, it should be safe to go outside again.")
	end_sound = 'sound/ambience/weather/snowstorm/snow_end.ogg'
	end_sound_vol = /datum/looping_sound/snowstorm::volume + 10

	area_type = /area
	protect_indoors = TRUE
	target_trait = ZTRAIT_SNOWSTORM

	immunity_type = TRAIT_SNOWSTORM_IMMUNE

	barometer_predictable = TRUE

	///Lowest we can cool someone randomly per weather act. Positive values only
	var/cooling_lower = 5
	///Highest we can cool someone randomly per weather act. Positive values only
	var/cooling_upper = 15

/datum/weather/snow_storm/weather_act(mob/living/living)
	living.adjust_bodytemperature(-rand(cooling_lower, cooling_upper))

/// Tracks where we should play snowstorm sounds for the area sound listener
GLOBAL_LIST_EMPTY(snowstorm_sounds)

/datum/weather/snow_storm/start()
	GLOB.snowstorm_sounds.Cut() // it's passed by ref
	for(var/area/impacted_area as anything in impacted_areas)
		GLOB.snowstorm_sounds[impacted_area] = /datum/looping_sound/snowstorm
	return ..()

/datum/weather/snow_storm/end()
	GLOB.snowstorm_sounds.Cut()
	return ..()

// since snowstorm is on a station z level, add extra checks to not annoy everyone
/datum/weather/snow_storm/can_get_alert(mob/player)
	if(!..())
		return FALSE

	if(!is_station_level(player.z))
		return TRUE // bypass checks

	if(isobserver(player))
		return TRUE

	if(HAS_MIND_TRAIT(player, TRAIT_DETECT_STORM))
		return TRUE

	if(istype(get_area(player), /area/mine))
		return TRUE

	for(var/area/snow_area in impacted_areas)
		if(locate(snow_area) in view(player))
			return TRUE

	return FALSE

///A storm that doesn't stop storming, and is a bit stronger
/datum/weather/snow_storm/forever_storm
	telegraph_duration = 0 SECONDS
	perpetual = TRUE

	probability = 0

	cooling_lower = 5
	cooling_upper = 18

/datum/looping_sound/snowstorm
	mid_sounds = list(
		'sound/ambience/weather/snowstorm/snow1.ogg' = 1,
		'sound/ambience/weather/snowstorm/snow2.ogg' = 1,
		'sound/ambience/weather/snowstorm/snow3.ogg' = 1,
		'sound/ambience/weather/snowstorm/snow4.ogg' = 1,
		'sound/ambience/weather/snowstorm/snow5.ogg' = 1,
		'sound/ambience/weather/snowstorm/snow6.ogg' = 1,
		'sound/ambience/weather/snowstorm/snow7.ogg' = 1,
		'sound/ambience/weather/snowstorm/snow8.ogg' = 1,
		'sound/ambience/weather/snowstorm/snow9.ogg' = 1,
	)
	mid_length = 10 SECONDS
	volume = 30
	sound_channel = CHANNEL_WEATHER
	/// Dynamically adjust the length of the sound to appropriate values
	var/list/sound_to_length = list(
		'sound/ambience/weather/snowstorm/snow1.ogg' = 11.3 SECONDS,
		'sound/ambience/weather/snowstorm/snow2.ogg' = 9.7 SECONDS,
		'sound/ambience/weather/snowstorm/snow3.ogg' = 9.7 SECONDS,
		'sound/ambience/weather/snowstorm/snow4.ogg' = 7.3 SECONDS,
		'sound/ambience/weather/snowstorm/snow5.ogg' = 7.3 SECONDS,
		'sound/ambience/weather/snowstorm/snow6.ogg' = 8.8 SECONDS,
		'sound/ambience/weather/snowstorm/snow7.ogg' = 11.6 SECONDS,
		'sound/ambience/weather/snowstorm/snow8.ogg' = 11.6 SECONDS,
		'sound/ambience/weather/snowstorm/snow9.ogg' = 7.3 SECONDS,
	)

// hijacking sound loop code to run loops of varying length
// doing this because set_mid_length can't run DURING a soundloop, which means we can't variably adjust the length of the sound
/datum/looping_sound/snowstorm/start_sound_loop()
	loop_started = TRUE
	sound_loop()

/datum/looping_sound/snowstorm/sound_loop(start_time)
	if(!loop_started)
		return
	var/picked_sound = get_sound()
	play(picked_sound)
	if(sound_to_length[picked_sound])
		timer_id = addtimer(CALLBACK(src, PROC_REF(sound_loop)), sound_to_length[picked_sound], TIMER_CLIENT_TIME | TIMER_STOPPABLE | TIMER_DELETE_ME, SSsound_loops)
