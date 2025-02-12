
/turf/open/floor/engine/hull
	name = "exterior hull plating"
	desc = "Sturdy exterior hull plating that separates you from the uncaring vacuum of space."
	icon_state = "regular_hull"
	initial_gas_mix = AIRLESS_ATMOS
	temperature = TCMB

/turf/open/floor/engine/hull/ceiling
	name = "shuttle ceiling plating"

/turf/open/floor/engine/hull/ceiling/Initialize(mapload)
	. = ..()
	if(!istype(loc, /area/space))
		return
	if(istype(loc, /area/space/nearstation))
		return
	new /obj/effect/mapping_error (src) //We're in a normal space tile, meaning we aren't lit correct.
										///datum/unit_test/mapping_nearstation_test.dm SHOULD fail this case automatically
										//this is just here so the mapper responsible can easily see where the issues are directly on the map.

/turf/open/floor/engine/hull/reinforced
	name = "exterior reinforced hull plating"
	desc = "Extremely sturdy exterior hull plating that separates you from the uncaring vacuum of space."
	icon_state = "reinforced_hull"
	heat_capacity = INFINITY
