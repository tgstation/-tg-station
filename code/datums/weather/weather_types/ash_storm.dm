//Ash storms happen frequently on lavaland. They heavily obscure vision, and cause high fire damage to anyone caught outside.
/datum/weather/ash_storm
	name = "ash storm"
	desc = "An intense atmospheric storm lifts ash off of the planet's surface and billows it down across the area, dealing intense fire damage to the unprotected."

	telegraph_message = span_boldwarning("An eerie moan rises on the wind. Sheets of burning ash blacken the horizon. Seek shelter.")
	telegraph_duration = 30 SECONDS
	telegraph_overlay = "light_ash"

	weather_message = span_userdanger("<i>Smoldering clouds of scorching ash billow down around you! Get inside!</i>")
	weather_duration_lower = 1 MINUTES
	weather_duration_upper = 2 MINUTES
	weather_overlay = "ash_storm"

	end_message = span_bolddanger("The shrieking wind whips away the last of the ash and falls to its usual murmur. It should be safe to go outside now.")
	end_duration = 30 SECONDS
	end_overlay = "light_ash"

	area_type = /area
	protect_indoors = TRUE
	target_trait = ZTRAIT_ASHSTORM

	immunity_type = TRAIT_ASHSTORM_IMMUNE

	probability = 90

	barometer_predictable = TRUE
	var/list/weak_sounds = list()
	var/list/strong_sounds = list()

/datum/weather/ash_storm/telegraph()
	var/list/eligible_areas = list()
	for (var/z in impacted_z_levels)
		eligible_areas += SSmapping.areas_in_z["[z]"]
	for(var/i in 1 to eligible_areas.len)
		var/area/place = eligible_areas[i]
		if(place.outdoors)
			weak_sounds[place] = /datum/looping_sound/weak_outside_ashstorm
			strong_sounds[place] = /datum/looping_sound/active_outside_ashstorm
		else
			weak_sounds[place] = /datum/looping_sound/weak_inside_ashstorm
			strong_sounds[place] = /datum/looping_sound/active_inside_ashstorm
		CHECK_TICK

	//We modify this list instead of setting it to weak/stron sounds in order to preserve things that hold a reference to it
	//It's essentially a playlist for a bunch of components that chose what sound to loop based on the area a player is in
	GLOB.ash_storm_sounds += weak_sounds
	return ..()

/datum/weather/ash_storm/start()
	GLOB.ash_storm_sounds -= weak_sounds
	GLOB.ash_storm_sounds += strong_sounds
	return ..()

/datum/weather/ash_storm/wind_down()
	GLOB.ash_storm_sounds -= strong_sounds
	GLOB.ash_storm_sounds += weak_sounds
	return ..()

/datum/weather/ash_storm/can_weather_act(mob/living/mob_to_check)
	. = ..()
	if(!. || !ishuman(mob_to_check))
		return
	var/mob/living/carbon/human/human_to_check = mob_to_check
	if(human_to_check.get_thermal_protection() >= FIRE_IMMUNITY_MAX_TEMP_PROTECT)
		return FALSE

/datum/weather/ash_storm/weather_act(mob/living/victim)
	victim.adjustFireLoss(4, required_bodytype = BODYTYPE_ORGANIC)

/datum/weather/ash_storm/end()
	GLOB.ash_storm_sounds -= weak_sounds
	for(var/turf/open/misc/asteroid/basalt/basalt as anything in GLOB.dug_up_basalt)
		if(!(basalt.loc in impacted_areas) || !(basalt.z in impacted_z_levels))
			continue
		basalt.refill_dug()
	return ..()

//Emberfalls are the result of an ash storm passing by close to the playable area of lavaland. They have a 10% chance to trigger in place of an ash storm.
/datum/weather/ash_storm/emberfall
	name = "emberfall"
	desc = "A passing ash storm blankets the area in harmless embers."

	weather_message = span_notice("Gentle embers waft down around you like grotesque snow. The storm seems to have passed you by...")
	weather_overlay = "light_ash"

	end_message = span_notice("The emberfall slows, stops. Another layer of hardened soot to the basalt beneath your feet.")
	end_sound = null

	aesthetic = TRUE

	probability = 10
