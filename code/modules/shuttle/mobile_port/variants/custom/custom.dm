/obj/docking_port/mobile/custom
	name = "custom shuttle"
	shuttle_id = "custom"
	var/datum/weakref/master_blueprint
	var/area/default_area
	var/datum/weakref/control_console
	var/datum/weakref/navigation_console

/obj/docking_port/mobile/custom/Initialize(mapload, list/areas)
	. = ..()
	default_area = areas[1]

/obj/docking_port/mobile/custom/canMove()
	return ..() && (current_engine_power > 0)

/obj/docking_port/mobile/custom/get_engine_coeff()
	var/thrust_ratio = (current_engine_power * CUSTOM_ENGINE_POWER_MULTIPLIER)/(turf_count + CUSTOM_ENGINE_POWER_TURF_COUNT_OFFSET)
	var/calculated_multiplier = 2*(1-(NUM_E ** -thrust_ratio))
	return clamp(1/calculated_multiplier, CUSTOM_ENGINE_COEFF_MIN, CUSTOM_ENGINE_COEFF_MAX)
