/datum/weather/snow_storm
	name = "snow storm"
	desc = "Harsh snowstorms roam the topside of this arctic planet, burying any area unfortunate enough to be in its path."
	probability = 90

	telegraph_message = span_warning("Drifting particles of snow begin to dust the surrounding area..")
	telegraph_duration = 30 SECONDS
	telegraph_overlay = "light_snow"

	weather_message = span_userdanger("<i>Harsh winds pick up as dense snow begins to fall from the sky! Seek shelter!</i>")
	weather_overlay = "snow_storm"
	weather_duration_lower = 1 MINUTES
	weather_duration_upper = 2.5 MINUTES
	use_glow = FALSE

	end_duration = 10 SECONDS
	end_message = span_bolddanger("The snowfall dies down, it should be safe to go outside again.")

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

// since snowstorm is on a station z level, add extra checks to not annoy everyone
/datum/weather/snow_storm/can_get_alert(mob/player)
	if(!..())
		return FALSE

	if(!is_station_level(player.z))
		return TRUE  // bypass checks

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
	telegraph_duration = 0
	perpetual = TRUE

	probability = 0

	cooling_lower = 5
	cooling_upper = 18
