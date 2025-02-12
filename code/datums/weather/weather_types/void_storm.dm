/datum/weather/void_storm
	name = "void storm"
	desc = "A rare and highly anomalous event often accompanied by unknown entities shredding spacetime continouum. We'd advise you to start running."

	telegraph_duration = 2 SECONDS
	telegraph_overlay = "light_snow"

	weather_message = span_hypnophrase("You feel the air around you getting colder... and void's sweet embrace...")
	weather_overlay = "light_snow"
	weather_color = COLOR_BLACK
	weather_duration_lower = 1 MINUTES
	weather_duration_upper = 2 MINUTES

	use_glow = FALSE

	end_duration = 10 SECONDS

	area_type = /area
	protect_indoors = FALSE
	target_trait = ZTRAIT_VOIDSTORM

	barometer_predictable = FALSE
	perpetual = TRUE
