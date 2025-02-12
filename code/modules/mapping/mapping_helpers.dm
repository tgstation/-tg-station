//Landmarks and other helpers which speed up the mapping process and reduce the number of unique instances/subtypes of items/turf/ect



/obj/effect/baseturf_helper //Set the baseturfs of every turf in the /area/ it is placed.
	name = "baseturf editor"
	icon = 'icons/effects/mapping_helpers.dmi'
	icon_state = ""
	/// Replacing a specific turf
	var/list/baseturf_to_replace
	/// The desired bottom turf
	var/baseturf

	plane = POINT_PLANE

/obj/effect/baseturf_helper/Initialize(mapload)
	. = ..()
	return INITIALIZE_HINT_LATELOAD

/obj/effect/baseturf_helper/LateInitialize()
	if(!baseturf_to_replace)
		baseturf_to_replace = typecacheof(list(/turf/open/space,/turf/baseturf_bottom))
	else if(!length(baseturf_to_replace))
		baseturf_to_replace = list(baseturf_to_replace = TRUE)
	else if(baseturf_to_replace[baseturf_to_replace[1]] != TRUE) // It's not associative
		var/list/formatted = list()
		for(var/i in baseturf_to_replace)
			formatted[i] = TRUE
		baseturf_to_replace = formatted

	var/area/our_area = get_area(src)
	for(var/i in get_area_turfs(our_area, z))
		replace_baseturf(i)

	qdel(src)

/// Replaces all the requested baseturfs (usually space/baseturfbottom) with the desired baseturf. Skips if its already there
/obj/effect/baseturf_helper/proc/replace_baseturf(turf/thing)
	thing.remove_baseturfs_from_typecache(baseturf_to_replace)

	if(length(thing.baseturfs))
		var/turf/tile = thing.baseturfs[1]
		if(tile == baseturf)
			return

	thing.place_on_bottom(baseturf)

/obj/effect/baseturf_helper/space
	name = "space baseturf editor"
	baseturf = /turf/open/space

/obj/effect/baseturf_helper/asteroid
	name = "asteroid baseturf editor"
	baseturf = /turf/open/misc/asteroid

/obj/effect/baseturf_helper/asteroid/airless
	name = "asteroid airless baseturf editor"
	baseturf = /turf/open/misc/asteroid/airless

/obj/effect/baseturf_helper/asteroid/basalt
	name = "asteroid basalt baseturf editor"
	baseturf = /turf/open/misc/asteroid/basalt

/obj/effect/baseturf_helper/asteroid/snow
	name = "asteroid snow baseturf editor"
	baseturf = /turf/open/misc/asteroid/snow

/obj/effect/baseturf_helper/asteroid/moon
	name = "lunar sand baseturf editor"
	baseturf = /turf/open/misc/asteroid/moon

/obj/effect/baseturf_helper/beach/sand
	name = "beach sand baseturf editor"
	baseturf = /turf/open/misc/beach/sand

/obj/effect/baseturf_helper/beach/water
	name = "water baseturf editor"
	baseturf = /turf/open/water/beach

/obj/effect/baseturf_helper/lava
	name = "lava baseturf editor"
	baseturf = /turf/open/lava/smooth

/obj/effect/baseturf_helper/lava_land/surface
	name = "lavaland baseturf editor"
	baseturf = /turf/open/lava/smooth/lava_land_surface

/obj/effect/baseturf_helper/reinforced_plating
	name = "reinforced plating baseturf editor"
	baseturf = /turf/open/floor/plating/reinforced
	baseturf_to_replace = list(/turf/open/floor/plating)

/obj/effect/baseturf_helper/reinforced_plating/replace_baseturf(turf/thing)
	if(istype(thing, /turf/open/floor/plating))
		return //Plates should not be placed under other plates
	thing.stack_ontop_of_baseturf(/turf/open/floor/plating, baseturf)

//This applies the reinforced plating to the above Z level for every tile in the area where this is placed
/obj/effect/baseturf_helper/reinforced_plating/ceiling
	name = "reinforced ceiling plating baseturf editor"

/obj/effect/baseturf_helper/reinforced_plating/ceiling/replace_baseturf(turf/thing)
	var/turf/ceiling = get_step_multiz(thing, UP)
	if(isnull(ceiling))
		CRASH("baseturf helper is attempting to modify the Z level above but there is no Z level above it.")
	if(isspaceturf(ceiling) || istype(ceiling, /turf/open/openspace))
		return
	return ..(ceiling)

///Used for marking mapping errors. These should only be created by cases explicitly caught by unit tests, and should NEVER actually appear in production.
/obj/effect/mapping_error
	name = "I AM ERROR"
	desc = "IF YOU SEE ME, YELL AT A MAPPER!!!"
	icon = 'icons/effects/mapping_helpers.dmi'
	icon_state = "mapping_error"

/obj/effect/mapping_helpers
	icon = 'icons/effects/mapping_helpers.dmi'
	icon_state = ""
	anchored = TRUE
	// Unless otherwise specified, layer above everything
	layer = ABOVE_ALL_MOB_LAYER
	var/late = FALSE

/obj/effect/mapping_helpers/Initialize(mapload)
	..()
	return late ? INITIALIZE_HINT_LATELOAD : INITIALIZE_HINT_QDEL

//airlock helpers
/obj/effect/mapping_helpers/airlock
	layer = DOOR_HELPER_LAYER
	late = TRUE
	/// If TRUE we will apply to every windoor in the loc if we can't find an airlock.
	var/apply_to_windoors = FALSE

/obj/effect/mapping_helpers/airlock/Initialize(mapload)
	. = ..()
	if(!mapload)
		log_mapping("[src] spawned outside of mapload!")
		return

	var/obj/machinery/door/airlock/airlock = locate(/obj/machinery/door/airlock) in loc
	if(!airlock)
		if(apply_to_windoors)
			var/any_found = FALSE
			for(var/obj/machinery/door/window/windoor in loc)
				payload(windoor)
				any_found = TRUE
			if(!any_found)
				log_mapping("[src] failed to find an airlock at [AREACOORD(src)], AND no windoors were found.")
			return

		log_mapping("[src] failed to find an airlock at [AREACOORD(src)]")
		return

	payload(airlock)

/obj/effect/mapping_helpers/airlock/LateInitialize()
	var/obj/machinery/door/airlock/airlock = locate(/obj/machinery/door/airlock) in loc
	if(!airlock)
		qdel(src)
		return
	if(airlock.cyclelinkeddir)
		airlock.cyclelinkairlock()
	if(airlock.closeOtherId)
		airlock.update_other_id()
	if(airlock.abandoned)
		var/outcome = rand(1,100)
		switch(outcome)
			if(1 to 9)
				var/turf/here = get_turf(src)
				for(var/turf/closed/T in range(2, src))
					here.place_on_top(T.type)
					qdel(airlock)
					qdel(src)
					return
				here.place_on_top(/turf/closed/wall)
				qdel(airlock)
				qdel(src)
				return
			if(9 to 11)
				airlock.lights = FALSE
				// These do not use airlock.bolt() because we want to pretend it was always locked. That means no sound effects.
				airlock.locked = TRUE
			if(12 to 15)
				airlock.locked = TRUE
			if(16 to 23)
				airlock.welded = TRUE
			if(24 to 30)
				airlock.set_panel_open(TRUE)
	if(airlock.cutAiWire)
		airlock.wires.cut(WIRE_AI)
	if(airlock.autoname)
		airlock.name = get_area_name(src, TRUE)
	airlock.update_appearance()
	qdel(src)

/obj/effect/mapping_helpers/airlock/proc/payload(obj/machinery/door/airlock/payload)
	return

/obj/effect/mapping_helpers/airlock/cyclelink_helper
	name = "airlock cyclelink helper"
	icon_state = "airlock_cyclelink_helper"

/obj/effect/mapping_helpers/airlock/cyclelink_helper/payload(obj/machinery/door/airlock/airlock)
	if(airlock.cyclelinkeddir)
		log_mapping("[src] at [AREACOORD(src)] tried to set [airlock] cyclelinkeddir, but it's already set!")
	else
		airlock.cyclelinkeddir = dir

/obj/effect/mapping_helpers/airlock/cyclelink_helper_multi
	name = "airlock multi-cyclelink helper"
	icon_state = "airlock_multicyclelink_helper"
	var/cycle_id

/obj/effect/mapping_helpers/airlock/cyclelink_helper_multi/payload(obj/machinery/door/airlock/airlock)
	if(airlock.closeOtherId)
		log_mapping("[src] at [AREACOORD(src)] tried to set [airlock] closeOtherId, but it's already set!")
	else if(!cycle_id)
		log_mapping("[src] at [AREACOORD(src)] doesn't have a cycle_id to assign to [airlock]!")
	else
		airlock.closeOtherId = cycle_id

/obj/effect/mapping_helpers/airlock/locked
	name = "airlock lock helper"
	icon_state = "airlock_locked_helper"

/obj/effect/mapping_helpers/airlock/locked/payload(obj/machinery/door/airlock/airlock)
	if(airlock.locked)
		log_mapping("[src] at [AREACOORD(src)] tried to bolt [airlock] but it's already locked!")
	else
		// Used instead of bolt so that we can pretend it was always locked, i.e. no sound effects on init.
		airlock.locked = TRUE

/obj/effect/mapping_helpers/airlock/unres
	name = "airlock unrestricted side helper"
	icon_state = "airlock_unres_helper"

/obj/effect/mapping_helpers/airlock/unres/payload(obj/machinery/door/airlock/airlock)
	airlock.unres_sides ^= dir
	airlock.unres_sensor = TRUE

/obj/effect/mapping_helpers/airlock/abandoned
	name = "airlock abandoned helper"
	icon_state = "airlock_abandoned"

/obj/effect/mapping_helpers/airlock/abandoned/payload(obj/machinery/door/airlock/airlock)
	if(airlock.abandoned)
		log_mapping("[src] at [AREACOORD(src)] tried to make [airlock] abandoned but it's already abandoned!")
	else
		airlock.abandoned = TRUE

/obj/effect/mapping_helpers/airlock/welded
	name = "airlock welded helper"
	icon_state = "airlock_welded"

/obj/effect/mapping_helpers/airlock/welded/payload(obj/machinery/door/airlock/airlock)
	if(airlock.welded)
		log_mapping("[src] at [AREACOORD(src)] tried to make [airlock] welded but it's already welded closed!")
	airlock.welded = TRUE

/obj/effect/mapping_helpers/airlock/cutaiwire
	name = "airlock cut ai wire helper"
	icon_state = "airlock_cutaiwire"

/obj/effect/mapping_helpers/airlock/cutaiwire/payload(obj/machinery/door/airlock/airlock)
	if(airlock.cutAiWire)
		log_mapping("[src] at [AREACOORD(src)] tried to cut the ai wire on [airlock] but it's already cut!")
	else
		airlock.cutAiWire = TRUE

/obj/effect/mapping_helpers/airlock/autoname
	name = "airlock autoname helper"
	icon_state = "airlock_autoname"

/obj/effect/mapping_helpers/airlock/autoname/payload(obj/machinery/door/airlock/airlock)
	if(airlock.autoname)
		log_mapping("[src] at [AREACOORD(src)] tried to autoname the [airlock] but it's already autonamed!")
	else
		airlock.autoname = TRUE

/obj/effect/mapping_helpers/airlock/inaccessible
	name = "airlock inaccessible helper"
	icon_state = "airlock_inaccessible"

/obj/effect/mapping_helpers/airlock/inaccessible/payload(obj/machinery/door/airlock/airlock)
	if(airlock.req_one_access != null)
		log_mapping("[src] at [AREACOORD(src)] tried to set req_access, but req__one_access was already set!")
	else
		airlock.req_access += list(ACCESS_INACCESSIBLE)

/obj/effect/mapping_helpers/airlock/red_alert_access
	name = "airlock red alert access helper"
	icon_state = "airlock_red_alert_access"
	apply_to_windoors = TRUE

/obj/effect/mapping_helpers/airlock/red_alert_access/payload(obj/machinery/door/airlock)
	airlock.red_alert_access = TRUE

//air alarm helpers
/obj/effect/mapping_helpers/airalarm
	desc = "You shouldn't see this. Report it please."
	late = TRUE

/obj/effect/mapping_helpers/airalarm/Initialize(mapload)
	. = ..()
	if(!mapload)
		log_mapping("[src] spawned outside of mapload!")
		return INITIALIZE_HINT_QDEL

	var/obj/machinery/airalarm/target = locate(/obj/machinery/airalarm) in loc
	if(isnull(target))
		var/area/target_area = get_area(src)
		log_mapping("[src] failed to find an air alarm at [AREACOORD(src)] ([target_area.type]).")
	else
		payload(target)

	return INITIALIZE_HINT_LATELOAD

/obj/effect/mapping_helpers/airalarm/LateInitialize()
	var/obj/machinery/airalarm/target = locate(/obj/machinery/airalarm) in loc

	if(isnull(target))
		qdel(src)
		return
	if(target.unlocked)
		target.unlock()

	if(target.tlv_cold_room)
		target.set_tlv_cold_room()
	if(target.tlv_kitchen)
		target.set_tlv_kitchen()
	if(target.tlv_no_checks)
		target.set_tlv_no_checks()
	if(target.tlv_no_checks + target.tlv_cold_room + target.tlv_kitchen > 1)
		CRASH("Tried to apply incompatible air alarm threshold helpers!")

	if(target.syndicate_access)
		target.give_syndicate_access()
	if(target.away_general_access)
		target.give_away_general_access()
	if(target.engine_access)
		target.give_engine_access()
	if(target.mixingchamber_access)
		target.give_mixingchamber_access()
	if(target.all_access)
		target.give_all_access()
	if(target.syndicate_access + target.away_general_access + target.engine_access + target.mixingchamber_access + target.all_access > 1)
		CRASH("Tried to combine incompatible air alarm access helpers!")

	target.update_appearance()
	qdel(src)

/obj/effect/mapping_helpers/airalarm/proc/payload(obj/machinery/airalarm/target)
	return

/obj/effect/mapping_helpers/airalarm/unlocked
	name = "airalarm unlocked interface helper"
	icon_state = "airalarm_unlocked_interface_helper"

/obj/effect/mapping_helpers/airalarm/unlocked/payload(obj/machinery/airalarm/target)
	if(target.unlocked)
		var/area/area = get_area(target)
		log_mapping("[src] at [AREACOORD(src)] [(area.type)] tried to unlock the [target] but it's already unlocked!")
	target.unlocked = TRUE

/obj/effect/mapping_helpers/airalarm/syndicate_access
	name = "airalarm syndicate access helper"
	icon_state = "airalarm_syndicate_access_helper"

/obj/effect/mapping_helpers/airalarm/syndicate_access/payload(obj/machinery/airalarm/target)
	if(target.syndicate_access)
		var/area/area = get_area(target)
		log_mapping("[src] at [AREACOORD(src)] [(area.type)] tried to adjust [target]'s access to syndicate but it's already changed!")
	target.syndicate_access = TRUE

/obj/effect/mapping_helpers/airalarm/away_general_access
	name = "airalarm away access helper"
	icon_state = "airalarm_away_general_access_helper"

/obj/effect/mapping_helpers/airalarm/away_general_access/payload(obj/machinery/airalarm/target)
	if(target.away_general_access)
		var/area/area = get_area(target)
		log_mapping("[src] at [AREACOORD(src)] [(area.type)] tried to adjust [target]'s access to away_general but it's already changed!")
	target.away_general_access = TRUE

/obj/effect/mapping_helpers/airalarm/engine_access
	name = "airalarm engine access helper"
	icon_state = "airalarm_engine_access_helper"

/obj/effect/mapping_helpers/airalarm/engine_access/payload(obj/machinery/airalarm/target)
	if(target.engine_access)
		var/area/area = get_area(target)
		log_mapping("[src] at [AREACOORD(src)] [(area.type)] tried to adjust [target]'s access to engine_access but it's already changed!")
	target.engine_access = TRUE

/obj/effect/mapping_helpers/airalarm/mixingchamber_access
	name = "airalarm mixingchamber access helper"
	icon_state = "airalarm_mixingchamber_access_helper"

/obj/effect/mapping_helpers/airalarm/mixingchamber_access/payload(obj/machinery/airalarm/target)
	if(target.mixingchamber_access)
		var/area/area = get_area(target)
		log_mapping("[src] at [AREACOORD(src)] [(area.type)] tried to adjust [target]'s access to mixingchamber_access but it's already changed!")
	target.mixingchamber_access = TRUE

/obj/effect/mapping_helpers/airalarm/all_access
	name = "airalarm all access helper"
	icon_state = "airalarm_all_access_helper"

/obj/effect/mapping_helpers/airalarm/all_access/payload(obj/machinery/airalarm/target)
	if(target.all_access)
		var/area/area = get_area(target)
		log_mapping("[src] at [AREACOORD(src)] [(area.type)] tried to adjust [target]'s access to all_access but it's already changed!")
	target.all_access = TRUE

/obj/effect/mapping_helpers/airalarm/tlv_cold_room
	name = "airalarm cold room tlv helper"
	icon_state = "airalarm_tlv_cold_room_helper"

/obj/effect/mapping_helpers/airalarm/tlv_cold_room/payload(obj/machinery/airalarm/target)
	if(target.tlv_cold_room)
		var/area/area = get_area(target)
		log_mapping("[src] at [AREACOORD(src)] [(area.type)] tried to adjust [target]'s tlv to cold_room but it's already changed!")
	target.tlv_cold_room = TRUE

/obj/effect/mapping_helpers/airalarm/tlv_kitchen
	name = "airalarm kitchen tlv helper"
	icon_state = "airalarm_tlv_kitchen_helper"

/obj/effect/mapping_helpers/airalarm/tlv_kitchen/payload(obj/machinery/airalarm/target)
	if(target.tlv_kitchen)
		var/area/area = get_area(target)
		log_mapping("[src] at [AREACOORD(src)] [(area.type)] tried to adjust [target]'s tlv to kitchen but it's already changed!")
	target.tlv_kitchen = TRUE

/obj/effect/mapping_helpers/airalarm/tlv_no_checks
	name = "airalarm no checks tlv helper"
	icon_state = "airalarm_tlv_no_checks_helper"

/obj/effect/mapping_helpers/airalarm/tlv_no_checks/payload(obj/machinery/airalarm/target)
	if(target.tlv_no_checks)
		var/area/area = get_area(target)
		log_mapping("[src] at [AREACOORD(src)] [(area.type)] tried to adjust [target]'s tlv to no_checks but it's already changed!")
	target.tlv_no_checks = TRUE

/obj/effect/mapping_helpers/airalarm/link
	name = "airalarm link helper"
	icon_state = "airalarm_link_helper"
	late = TRUE
	var/chamber_id = ""
	var/allow_link_change = FALSE

/obj/effect/mapping_helpers/airalarm/link/Initialize(mapload)
	. = ..()
	if(!mapload)
		log_mapping("[src] spawned outside of mapload!")
		return INITIALIZE_HINT_QDEL

/obj/effect/mapping_helpers/airalarm/link/LateInitialize(mapload)
	var/obj/machinery/airalarm/alarm = locate(/obj/machinery/airalarm) in loc
	if(!isnull(alarm))
		alarm.air_sensor_chamber_id = chamber_id
		alarm.allow_link_change = allow_link_change
		alarm.setup_chamber_link()
	else
		log_mapping("[src] failed to find air alarm at [AREACOORD(src)].")
	qdel(src)

//apc helpers
/obj/effect/mapping_helpers/apc
	desc = "You shouldn't see this. Report it please."
	late = TRUE

/obj/effect/mapping_helpers/apc/Initialize(mapload)
	. = ..()
	if(!mapload)
		log_mapping("[src] spawned outside of mapload!")
		return INITIALIZE_HINT_QDEL

	var/obj/machinery/power/apc/target = locate(/obj/machinery/power/apc) in loc
	if(isnull(target))
		var/area/target_area = get_area(src)
		log_mapping("[src] failed to find an apc at [AREACOORD(src)] ([target_area.type]).")
	else
		payload(target)

	return INITIALIZE_HINT_LATELOAD

/obj/effect/mapping_helpers/apc/LateInitialize()
	var/obj/machinery/power/apc/target = locate(/obj/machinery/power/apc) in loc

	if(isnull(target))
		qdel(src)
		return
	if(target.cut_AI_wire)
		target.wires.cut(WIRE_AI)
	if(target.cell_5k)
		target.install_cell_5k()
	if(target.cell_10k)
		target.install_cell_10k()
	if(target.unlocked)
		target.unlock()
	if(target.syndicate_access)
		target.give_syndicate_access()
	if(target.away_general_access)
		target.give_away_general_access()
	if(target.no_charge)
		target.set_no_charge()
	if(target.full_charge)
		target.set_full_charge()
	if(target.cell_5k && target.cell_10k)
		CRASH("Tried to combine non-combinable cell_5k and cell_10k APC helpers!")
	if(target.syndicate_access && target.away_general_access)
		CRASH("Tried to combine non-combinable syndicate_access and away_general_access APC helpers!")
	if(target.no_charge && target.full_charge)
		CRASH("Tried to combine non-combinable no_charge and full_charge APC helpers!")
	target.update_appearance()
	qdel(src)

/obj/effect/mapping_helpers/apc/proc/payload(obj/machinery/power/apc/target)
	return

/obj/effect/mapping_helpers/apc/cut_AI_wire
	name = "apc AI wire mended helper"
	icon_state = "apc_cut_AIwire_helper"

/obj/effect/mapping_helpers/apc/cut_AI_wire/payload(obj/machinery/power/apc/target)
	if(target.cut_AI_wire)
		var/area/apc_area = get_area(target)
		log_mapping("[src] at [AREACOORD(src)] [(apc_area.type)] tried to mend the AI wire on the [target] but it's already cut!")
	target.cut_AI_wire = TRUE

/obj/effect/mapping_helpers/apc/cell_5k
	name = "apc 5k cell helper"
	icon_state = "apc_5k_cell_helper"

/obj/effect/mapping_helpers/apc/cell_5k/payload(obj/machinery/power/apc/target)
	if(target.cell_5k)
		var/area/apc_area = get_area(target)
		log_mapping("[src] at [AREACOORD(src)] [(apc_area.type)] tried to change [target]'s cell to cell_5k but it's already changed!")
	target.cell_5k = TRUE

/obj/effect/mapping_helpers/apc/cell_10k
	name = "apc 10k cell helper"
	icon_state = "apc_10k_cell_helper"

/obj/effect/mapping_helpers/apc/cell_10k/payload(obj/machinery/power/apc/target)
	if(target.cell_10k)
		var/area/apc_area = get_area(target)
		log_mapping("[src] at [AREACOORD(src)] [(apc_area.type)] tried to change [target]'s cell to cell_10k but it's already changed!")
	target.cell_10k = TRUE

/obj/effect/mapping_helpers/apc/syndicate_access
	name = "apc syndicate access helper"
	icon_state = "apc_syndicate_access_helper"

/obj/effect/mapping_helpers/apc/syndicate_access/payload(obj/machinery/power/apc/target)
	if(target.syndicate_access)
		var/area/apc_area = get_area(target)
		log_mapping("[src] at [AREACOORD(src)] [(apc_area.type)] tried to adjust [target]'s access to syndicate but it's already changed!")
	target.syndicate_access = TRUE

/obj/effect/mapping_helpers/apc/away_general_access
	name = "apc away access helper"
	icon_state = "apc_away_general_access_helper"

/obj/effect/mapping_helpers/apc/away_general_access/payload(obj/machinery/power/apc/target)
	if(target.away_general_access)
		var/area/apc_area = get_area(target)
		log_mapping("[src] at [AREACOORD(src)] [(apc_area.type)] tried to adjust [target]'s access to away_general but it's already changed!")
	target.away_general_access = TRUE

/obj/effect/mapping_helpers/apc/unlocked
	name = "apc unlocked interface helper"
	icon_state = "apc_unlocked_interface_helper"

/obj/effect/mapping_helpers/apc/unlocked/payload(obj/machinery/power/apc/target)
	if(target.unlocked)
		var/area/apc_area = get_area(target)
		log_mapping("[src] at [AREACOORD(src)] [(apc_area.type)] tried to unlock the [target] but it's already unlocked!")
	target.unlocked = TRUE

/obj/effect/mapping_helpers/apc/no_charge
	name = "apc no charge helper"
	icon_state = "apc_no_charge_helper"

/obj/effect/mapping_helpers/apc/no_charge/payload(obj/machinery/power/apc/target)
	if(target.no_charge)
		var/area/apc_area = get_area(target)
		log_mapping("[src] at [AREACOORD(src)] [(apc_area.type)] tried to set [target]'s charge to 0 but it's already at 0!")
	target.no_charge = TRUE

/obj/effect/mapping_helpers/apc/full_charge
	name = "apc full charge helper"
	icon_state = "apc_full_charge_helper"

/obj/effect/mapping_helpers/apc/full_charge/payload(obj/machinery/power/apc/target)
	if(target.full_charge)
		var/area/apc_area = get_area(target)
		log_mapping("[src] at [AREACOORD(src)] [(apc_area.type)] tried to set [target]'s charge to 100 but it's already at 100!")
	target.full_charge = TRUE

//Used to turn off lights with lightswitch in areas.
/obj/effect/mapping_helpers/turn_off_lights_with_lightswitch
	name = "area turned off lights helper"
	icon_state = "lights_off"

/obj/effect/mapping_helpers/turn_off_lights_with_lightswitch/Initialize(mapload)
	. = ..()
	if(!mapload)
		log_mapping("[src] spawned outside of mapload!")
		return INITIALIZE_HINT_QDEL
	return INITIALIZE_HINT_LATELOAD

/obj/effect/mapping_helpers/turn_off_lights_with_lightswitch/LateInitialize()
	var/area/needed_area = get_area(src)
	if(!needed_area.lightswitch)
		stack_trace("[src] at [AREACOORD(src)] [(needed_area.type)] tried to turn lights off but they are already off!")
	var/obj/machinery/light_switch/light_switch = locate(/obj/machinery/light_switch) in needed_area
	if(!light_switch)
		CRASH("Trying to turn off lights with lightswitch in area without lightswitches. In [(needed_area.type)] to be precise.")
	light_switch.set_lights(FALSE)
	qdel(src)

//needs to do its thing before spawn_rivers() is called
INITIALIZE_IMMEDIATE(/obj/effect/mapping_helpers/no_lava)

/obj/effect/mapping_helpers/no_lava
	icon_state = "no_lava"

/obj/effect/mapping_helpers/no_lava/Initialize(mapload)
	. = ..()
	var/turf/T = get_turf(src)
	T.turf_flags |= NO_LAVA_GEN

INITIALIZE_IMMEDIATE(/obj/effect/mapping_helpers/no_atoms_ontop)
/obj/effect/mapping_helpers/no_atoms_ontop
	icon_state = "no_atoms_ontop"

/obj/effect/mapping_helpers/no_atoms_ontop/Initialize(mapload)
	. = ..()
	var/turf/loc_turf = get_turf(src)
	loc_turf.turf_flags |= TURF_BLOCKS_POPULATE_TERRAIN_FLORAFEATURES

///Helpers used for injecting stuff into atoms on the map.
/obj/effect/mapping_helpers/atom_injector
	name = "Atom Injector"
	icon_state = "injector"
	late = TRUE
	///Will inject into all fitting the criteria if false, otherwise first found.
	var/first_match_only = TRUE
	///Will inject into atoms of this type.
	var/target_type
	///Will inject into atoms with this name.
	var/target_name

//Late init so everything is likely ready and loaded (no warranty)
/obj/effect/mapping_helpers/atom_injector/LateInitialize()
	if(!check_validity())
		return
	var/turf/target_turf = get_turf(src)
	var/matches_found = 0
	for(var/atom/atom_on_turf as anything in target_turf.get_all_contents())
		if(atom_on_turf == src)
			continue
		if(target_name && atom_on_turf.name != target_name)
			continue
		if(target_type && !istype(atom_on_turf, target_type))
			continue
		inject(atom_on_turf)
		matches_found++
		if(first_match_only)
			qdel(src)
			return
	if(!matches_found)
		stack_trace(generate_stack_trace())
	qdel(src)

///Checks if whatever we are trying to inject with is valid
/obj/effect/mapping_helpers/atom_injector/proc/check_validity()
	return TRUE

///Injects our stuff into the atom
/obj/effect/mapping_helpers/atom_injector/proc/inject(atom/target)
	return

///Generates text for our stack trace
/obj/effect/mapping_helpers/atom_injector/proc/generate_stack_trace()
	. = "[name] found no targets at ([x], [y], [z]). First Match Only: [first_match_only ? "true" : "false"] target type: [target_type] | target name: [target_name]"

/obj/effect/mapping_helpers/atom_injector/obj_flag
	name = "Obj Flag Injector"
	icon_state = "objflag_helper"
	var/inject_flags = NONE

/obj/effect/mapping_helpers/atom_injector/obj_flag/inject(atom/target)
	if(!isobj(target))
		return
	var/obj/obj_target = target
	obj_target.obj_flags |= inject_flags

///This helper applies components to things on the map directly.
/obj/effect/mapping_helpers/atom_injector/component_injector
	name = "Component Injector"
	icon_state = "component"
	///Typepath of the component.
	var/component_type
	///Arguments for the component.
	var/list/component_args = list()

/obj/effect/mapping_helpers/atom_injector/component_injector/check_validity()
	if(!ispath(component_type, /datum/component))
		CRASH("Wrong component type in [type] - [component_type] is not a component")
	return TRUE

/obj/effect/mapping_helpers/atom_injector/component_injector/inject(atom/target)
	var/arguments = list(component_type)
	arguments += component_args
	target._AddComponent(arguments)

/obj/effect/mapping_helpers/atom_injector/component_injector/generate_stack_trace()
	. = ..()
	. += " | component type: [component_type] | component arguments: [list2params(component_args)]"

///This helper applies elements to things on the map directly.
/obj/effect/mapping_helpers/atom_injector/element_injector
	name = "Element Injector"
	icon_state = "element"
	///Typepath of the element.
	var/element_type
	///Arguments for the element.
	var/list/element_args = list()

/obj/effect/mapping_helpers/atom_injector/element_injector/check_validity()
	if(!ispath(element_type, /datum/element))
		CRASH("Wrong element type in [type] - [element_type] is not a element")
	return TRUE

/obj/effect/mapping_helpers/atom_injector/element_injector/inject(atom/target)
	var/arguments = list(element_type)
	arguments += element_args
	target._AddElement(arguments)

/obj/effect/mapping_helpers/atom_injector/element_injector/generate_stack_trace()
	. = ..()
	. += " | element type: [element_type] | element arguments: [list2params(element_args)]"

///This helper applies traits to things on the map directly.
/obj/effect/mapping_helpers/atom_injector/trait_injector
	name = "Trait Injector"
	icon_state = "trait"
	///Name of the trait, in the lower-case text (NOT the upper-case define) form.
	var/trait_name

/obj/effect/mapping_helpers/atom_injector/trait_injector/check_validity()
	if(!istext(trait_name))
		CRASH("Wrong trait in [type] - [trait_name] is not a trait")
	if(!GLOB.global_trait_name_map)
		GLOB.global_trait_name_map = generate_global_trait_name_map()
	if(!GLOB.global_trait_name_map.Find(trait_name))
		stack_trace("Possibly wrong trait in [type] - [trait_name] is not a trait in the global trait list")
	return TRUE

/obj/effect/mapping_helpers/atom_injector/trait_injector/inject(atom/target)
	ADD_TRAIT(target, trait_name, MAPPING_HELPER_TRAIT)

/obj/effect/mapping_helpers/atom_injector/trait_injector/generate_stack_trace()
	. = ..()
	. += " | trait name: [trait_name]"

///This helper applies dynamic human icons to things on the map
/obj/effect/mapping_helpers/atom_injector/human_icon_injector
	name = "Human Icon Injector"
	icon_state = "icon"
	/// Path of the outfit we give the human.
	var/outfit_path
	/// Path of the species we give the human.
	var/species_path = /datum/species/human
	/// Path of the mob spawner we base the human off of.
	var/mob_spawn_path
	/// Path of the right hand item we give the human.
	var/r_hand = NO_REPLACE
	/// Path of the left hand item we give the human.
	var/l_hand = NO_REPLACE
	/// Which slots on the mob should be bloody?
	var/bloody_slots = NONE
	/// Do we draw more than one frame for the mob?
	var/animated = TRUE

/obj/effect/mapping_helpers/atom_injector/human_icon_injector/check_validity()
	if(!ispath(species_path, /datum/species))
		CRASH("Wrong species path in [type] - [species_path] is not a species")
	if(outfit_path && !ispath(outfit_path, /datum/outfit))
		CRASH("Wrong outfit path in [type] - [species_path] is not an outfit")
	if(mob_spawn_path && !ispath(mob_spawn_path, /obj/effect/mob_spawn))
		CRASH("Wrong mob spawn path in [type] - [mob_spawn_path] is not a mob spawner")
	if(l_hand && !ispath(l_hand, /obj/item))
		CRASH("Wrong left hand item path in [type] - [l_hand] is not an item")
	if(r_hand && !ispath(r_hand, /obj/item))
		CRASH("Wrong left hand item path in [type] - [r_hand] is not an item")
	return TRUE

/obj/effect/mapping_helpers/atom_injector/human_icon_injector/inject(atom/target)
	apply_dynamic_human_appearance(target, outfit_path, species_path, mob_spawn_path, r_hand, l_hand, bloody_slots, animated)

/obj/effect/mapping_helpers/atom_injector/human_icon_injector/generate_stack_trace()
	. = ..()
	. += " | outfit path: [outfit_path] | species path: [species_path] | mob spawner path: [mob_spawn_path] | right/left hand path: [r_hand]/[l_hand]"

///Fetches an external dmi and applies to the target object
/obj/effect/mapping_helpers/atom_injector/custom_icon
	name = "Custom Icon Injector"
	icon_state = "icon"
	///This is the var that will be set with the fetched icon. In case you want to set some secondary icon sheets like inhands and such.
	var/target_variable = "icon"
	///This should return raw dmi in response to http get request. For example: "https://github.com/tgstation/SS13-sprites/raw/master/mob/medu.dmi?raw=true"
	var/icon_url
	///The icon file we fetched from the http get request.
	var/icon_file

/obj/effect/mapping_helpers/atom_injector/custom_icon/check_validity()
	var/static/icon_cache = list()
	var/static/query_in_progress = FALSE //We're using a single tmp file so keep it linear.
	if(query_in_progress)
		UNTIL(!query_in_progress)
	if(icon_cache[icon_url])
		icon_file = icon_cache[icon_url]
		return TRUE
	log_asset("Custom Icon Helper fetching dmi from: [icon_url]")
	var/datum/http_request/request = new()
	var/file_name = "tmp/custom_map_icon.dmi"
	request.prepare(RUSTG_HTTP_METHOD_GET, icon_url, "", "", file_name)
	query_in_progress = TRUE
	request.begin_async()
	UNTIL(request.is_complete())
	var/datum/http_response/response = request.into_response()
	if(response.errored || response.status_code != 200)
		query_in_progress = FALSE
		CRASH("Failed to fetch mapped custom icon from url [icon_url], code: [response.status_code], error: [response.error]")
	var/icon/new_icon = new(file_name)
	icon_cache[icon_url] = new_icon
	query_in_progress = FALSE
	icon_file = new_icon
	return TRUE

/obj/effect/mapping_helpers/atom_injector/custom_icon/inject(atom/target)
	if(IsAdminAdvancedProcCall())
		return
	target.vars[target_variable] = icon_file

/obj/effect/mapping_helpers/atom_injector/custom_icon/generate_stack_trace()
	. = ..()
	. += " | target variable: [target_variable] | icon url: [icon_url]"

///Fetches an external sound and applies to the target object
/obj/effect/mapping_helpers/atom_injector/custom_sound
	name = "Custom Sound Injector"
	icon_state = "sound"
	///This is the var that will be set with the fetched sound.
	var/target_variable = "hitsound"
	///This should return raw sound in response to http get request. For example: "https://github.com/tgstation/tgstation/blob/master/sound/misc/bang.ogg?raw=true"
	var/sound_url
	///The sound file we fetched from the http get request.
	var/sound_file

/obj/effect/mapping_helpers/atom_injector/custom_sound/check_validity()
	var/static/sound_cache = list()
	var/static/query_in_progress = FALSE //We're using a single tmp file so keep it linear.
	if(query_in_progress)
		UNTIL(!query_in_progress)
	if(sound_cache[sound_url])
		sound_file = sound_cache[sound_url]
		return TRUE
	log_asset("Custom Sound Helper fetching sound from: [sound_url]")
	var/datum/http_request/request = new()
	var/file_name = "tmp/custom_map_sound.ogg"
	request.prepare(RUSTG_HTTP_METHOD_GET, sound_url, "", "", file_name)
	query_in_progress = TRUE
	request.begin_async()
	UNTIL(request.is_complete())
	var/datum/http_response/response = request.into_response()
	if(response.errored || response.status_code != 200)
		query_in_progress = FALSE
		CRASH("Failed to fetch mapped custom sound from url [sound_url], code: [response.status_code], error: [response.error]")
	var/sound/new_sound = new(file_name)
	sound_cache[sound_url] = new_sound
	query_in_progress = FALSE
	sound_file = new_sound
	return TRUE

/obj/effect/mapping_helpers/atom_injector/custom_sound/inject(atom/target)
	if(IsAdminAdvancedProcCall())
		return
	target.vars[target_variable] = sound_file

/obj/effect/mapping_helpers/atom_injector/custom_sound/generate_stack_trace()
	. = ..()
	. += " | target variable: [target_variable] | sound url: [sound_url]"

/obj/effect/mapping_helpers/dead_body_placer
	name = "Dead Body placer"
	late = TRUE
	icon_state = "deadbodyplacer"
	///if TRUE, was spawned out of mapload.
	var/admin_spawned
	///number of bodies to spawn
	var/bodycount = 3
	/// Corpse type we spawn thats always human
	var/datum/corpse_damage_class/morgue_body_class = /datum/corpse_damage_class/station/morgue

/obj/effect/mapping_helpers/dead_body_placer/Initialize(mapload)
	. = ..()
	if(mapload)
		return
	admin_spawned = TRUE

/obj/effect/mapping_helpers/dead_body_placer/LateInitialize()
	var/area/morgue_area = get_area(src)
	var/list/obj/structure/bodycontainer/morgue/trays = list()
	for (var/list/zlevel_turfs as anything in morgue_area.get_zlevel_turf_lists())
		for(var/turf/area_turf as anything in zlevel_turfs)
			var/obj/structure/bodycontainer/morgue/morgue_tray = locate() in area_turf
			if(isnull(morgue_tray) || !morgue_tray.beeper || morgue_tray.connected.loc != morgue_tray)
				continue
			trays += morgue_tray

	var/numtrays = length(trays)
	if(numtrays == 0)
		if(admin_spawned)
			message_admins("[src] spawned at [ADMIN_VERBOSEJMP(src)] failed to find a closed morgue to spawn a body!")
		else
			log_mapping("[src] at [x],[y] could not find any morgues.")
		return

	var/reuse_trays = (numtrays < bodycount) //are we going to spawn more trays than bodies?

	for (var/i in 1 to bodycount)
		var/obj/structure/bodycontainer/morgue/morgue_tray = reuse_trays ? pick(trays) : pick_n_take(trays)
		var/obj/structure/closet/body_bag/body_bag = new(morgue_tray.loc)
		var/mob/living/carbon/human/new_human = GLOB.lost_crew_manager.create_lost_crew(revivable = FALSE, forced_class = morgue_body_class)

		body_bag.insert(new_human, TRUE)
		body_bag.close()
		body_bag.handle_tag("[new_human.real_name][new_human.dna?.species ? " - [new_human.dna.species.name]" : " - Human"]")
		body_bag.forceMove(morgue_tray)

		morgue_tray.update_appearance()

	qdel(src)

//On Ian's birthday, the hop's office is decorated.
/obj/effect/mapping_helpers/ianbirthday
	name = "Ian's Bday Helper"
	late = TRUE
	icon_state = "iansbdayhelper"
	/// How many clusters of balloons to spawn.
	var/balloon_clusters = 2
	/// if TRUE, we give a map log warning if we can't find Ian's dogbed.
	var/map_warning = TRUE

/obj/effect/mapping_helpers/ianbirthday/LateInitialize()
	if(check_holidays(IAN_HOLIDAY))
		birthday()
	qdel(src)

/obj/effect/mapping_helpers/ianbirthday/proc/birthday()
	var/area/celebration_area = get_area(src)
	var/list/table_turfs = list()
	var/list/open_turfs = list()
	var/turf/dogbed_turf
	for (var/list/zlevel_turfs as anything in celebration_area.get_zlevel_turf_lists())
		for(var/turf/area_turf as anything in zlevel_turfs)
			if(locate(/obj/structure/table/reinforced) in area_turf)
				table_turfs += area_turf
			if(locate(/obj/structure/bed/dogbed/ian) in area_turf)
				dogbed_turf = area_turf
			if(isopenturf(area_turf))
				new /obj/effect/decal/cleanable/confetti(area_turf)
				open_turfs += area_turf

	if(isnull(dogbed_turf) && map_warning)
		log_mapping("[src] in [celebration_area] could not find Ian's dogbed.")

	else
		new /obj/item/toy/balloon/corgi(dogbed_turf)
		var/turf/food_turf = length(table_turfs) ? pick(table_turfs) : dogbed_turf
		new /obj/item/knife/kitchen(food_turf)
		var/obj/item/food/cake/birthday/iancake = new(food_turf)
		iancake.desc = "Happy birthday, Ian!"

	if(!length(open_turfs))
		return

	//some balloons! this picks an open turf and pops a few balloons in and around that turf, yay.
	for(var/i in 1 to balloon_clusters)
		var/turf/clusterspot = pick_n_take(open_turfs)
		new /obj/item/toy/balloon(clusterspot)
		var/balloons_left_to_give = 3 //the amount of balloons around the cluster
		var/list/dirs_to_balloon = GLOB.cardinals.Copy()
		while(balloons_left_to_give > 0)
			balloons_left_to_give--
			var/chosen_dir = pick_n_take(dirs_to_balloon)
			var/turf/balloonstep = get_step(clusterspot, chosen_dir)
			var/placed = FALSE
			if(isopenturf(balloonstep))
				var/obj/item/toy/balloon/B = new(balloonstep)//this clumps the cluster together
				placed = TRUE
				if(chosen_dir == NORTH)
					B.pixel_y -= 10
				if(chosen_dir == SOUTH)
					B.pixel_y += 10
				if(chosen_dir == EAST)
					B.pixel_x -= 10
				if(chosen_dir == WEST)
					B.pixel_x += 10
			if(!placed)
				new /obj/item/toy/balloon(clusterspot)
	//remind me to add wall decor!

/obj/effect/mapping_helpers/ianbirthday/admin//so admins may birthday any room
	name = "generic birthday setup"
	icon_state = "bdayhelper"
	map_warning = FALSE

/obj/effect/mapping_helpers/ianbirthday/admin/LateInitialize()
	birthday()
	qdel(src)

//Ian, like most dogs, loves a good new years eve party.
/obj/effect/mapping_helpers/iannewyear
	name = "Ian's New Years Helper"
	late = TRUE
	icon_state = "iansnewyrshelper"

/obj/effect/mapping_helpers/iannewyear/LateInitialize()
	if(check_holidays(NEW_YEAR))
		fireworks()
	qdel(src)

/obj/effect/mapping_helpers/iannewyear/proc/fireworks()
	var/area/celebration_area = get_area(src)
	var/list/table_turfs = list()
	var/turf/dogbed_turf
	for (var/list/zlevel_turfs as anything in celebration_area.get_zlevel_turf_lists())
		for(var/turf/area_turf as anything in zlevel_turfs)
			if(locate(/obj/structure/table/reinforced) in area_turf)
				table_turfs += area_turf
			if(locate(/obj/structure/bed/dogbed/ian) in area_turf)
				dogbed_turf = area_turf

	if(isnull(dogbed_turf))
		log_mapping("[src] in [celebration_area] could not find Ian's dogbed.")
		return

	new /obj/item/clothing/head/costume/festive(dogbed_turf)
	var/obj/item/reagent_containers/cup/glass/bottle/champagne/iandrink = new(dogbed_turf)
	iandrink.name = "dog champagne"
	iandrink.pixel_y += 8
	iandrink.pixel_x += 8

	var/turf/fireworks_turf = length(table_turfs) ? pick(table_turfs) : dogbed_turf
	var/obj/item/storage/box/matches/matchbox = new(fireworks_turf)
	matchbox.pixel_y += 8
	matchbox.pixel_x -= 3
	new /obj/item/storage/box/fireworks/dangerous(fireworks_turf) //dangerous version for extra holiday memes.

//lets mappers place notes on airlocks with custom info or a pre-made note from a path
/obj/effect/mapping_helpers/airlock_note_placer
	name = "Airlock Note Placer"
	late = TRUE
	icon_state = "airlocknoteplacer"
	var/note_info //for writing out custom notes without creating an extra paper subtype
	var/note_name //custom note name
	var/note_path //if you already have something wrote up in a paper subtype, put the path here

/obj/effect/mapping_helpers/airlock_note_placer/LateInitialize()
	var/turf/turf = get_turf(src)
	if(note_path && !ispath(note_path, /obj/item/paper)) //don't put non-paper in the paper slot thank you
		log_mapping("[src] at [x],[y] had an improper note_path path, could not place paper note.")
		qdel(src)
		return
	if(locate(/obj/machinery/door/airlock) in turf)
		var/obj/machinery/door/airlock/found_airlock = locate(/obj/machinery/door/airlock) in turf
		if(note_path)
			found_airlock.note = note_path
			found_airlock.update_appearance()
			qdel(src)
			return
		if(note_info)
			var/obj/item/paper/paper = new /obj/item/paper(src)
			if(note_name)
				paper.name = note_name
			paper.add_raw_text("[note_info]")
			paper.update_appearance()
			found_airlock.note = paper
			paper.forceMove(found_airlock)
			found_airlock.update_appearance()
			qdel(src)
			return
		log_mapping("[src] at [x],[y] had no note_path or note_info, cannot place paper note.")
		qdel(src)
		return
	log_mapping("[src] at [x],[y] could not find an airlock on current turf, cannot place paper note.")
	qdel(src)

/**
 * ## trapdoor placer!
 *
 * This places an unlinked trapdoor in the tile its on (so someone with a remote needs to link it up first)
 * Pre-mapped trapdoors (unlike player-made ones) are not conspicuous by default so nothing stands out with them
 * Admins may spawn this in the round for additional trapdoors if they so desire
 * if YOU want to learn more about trapdoors, read about the component at trapdoor.dm
 * note: this is not a turf subtype because the trapdoor needs the type of the turf to turn back into
 */
/obj/effect/mapping_helpers/trapdoor_placer
	name = "trapdoor placer"
	icon_state = "trapdoor"
	late = TRUE

/obj/effect/mapping_helpers/trapdoor_placer/LateInitialize()
	var/turf/component_target = get_turf(src)
	component_target.AddComponent(/datum/component/trapdoor, starts_open = FALSE, conspicuous = FALSE)
	qdel(src)

/obj/effect/mapping_helpers/ztrait_injector
	name = "ztrait injector"
	icon_state = "ztrait"
	late = TRUE
	/// List of traits to add to this Z-level.
	var/list/traits_to_add = list()

/obj/effect/mapping_helpers/ztrait_injector/LateInitialize()
	var/datum/space_level/level = SSmapping.z_list[z]
	if(!level || !length(traits_to_add))
		return
	level.traits |= traits_to_add
	SSweather.update_z_level(level) //in case of someone adding a weather for the level, we want SSweather to update for that

/obj/effect/mapping_helpers/circuit_spawner
	name = "circuit spawner"
	icon_state = "circuit"
	/// The shell for the circuit.
	var/atom/movable/circuit_shell
	/// Capacity of the shell.
	var/shell_capacity = SHELL_CAPACITY_VERY_LARGE
	/// The url for the json. Example: "https://pastebin.com/raw/eH7VnP9d"
	var/json_url

/obj/effect/mapping_helpers/circuit_spawner/Initialize(mapload)
	. = ..()
	INVOKE_ASYNC(src, PROC_REF(spawn_circuit))

/obj/effect/mapping_helpers/circuit_spawner/proc/spawn_circuit()
	var/list/errors = list()
	var/obj/item/integrated_circuit/loaded/new_circuit = new(loc)
	var/json_data = load_data()
	new_circuit.load_circuit_data(json_data, errors)
	if(!circuit_shell)
		return
	circuit_shell = new(loc)
	var/datum/component/shell/shell_component = circuit_shell.GetComponent(/datum/component/shell)
	if(shell_component)
		shell_component.shell_flags |= SHELL_FLAG_CIRCUIT_UNMODIFIABLE|SHELL_FLAG_CIRCUIT_UNREMOVABLE
		shell_component.attach_circuit(new_circuit)
	else
		shell_component = circuit_shell.AddComponent(/datum/component/shell, \
			capacity = shell_capacity, \
			shell_flags = SHELL_FLAG_CIRCUIT_UNMODIFIABLE|SHELL_FLAG_CIRCUIT_UNREMOVABLE, \
			starting_circuit = new_circuit, \
			)

/obj/effect/mapping_helpers/circuit_spawner/proc/load_data()
	var/static/json_cache = list()
	var/static/query_in_progress = FALSE //We're using a single tmp file so keep it linear.
	if(query_in_progress)
		UNTIL(!query_in_progress)
	if(json_cache[json_url])
		return json_cache[json_url]
	log_asset("Circuit Spawner fetching json from: [json_url]")
	var/datum/http_request/request = new()
	request.prepare(RUSTG_HTTP_METHOD_GET, json_url, "")
	query_in_progress = TRUE
	request.begin_async()
	UNTIL(request.is_complete())
	var/datum/http_response/response = request.into_response()
	if(response.errored || response.status_code != 200)
		query_in_progress = FALSE
		CRASH("Failed to fetch mapped custom json from url [json_url], code: [response.status_code], error: [response.error]")
	var/json_data = response.body
	json_cache[json_url] = json_data
	query_in_progress = FALSE
	return json_data

/obj/effect/mapping_helpers/broken_floor
	name = "broken floor"
	icon = 'icons/turf/damaged.dmi'
	icon_state = "damaged1"
	layer = ABOVE_NORMAL_TURF_LAYER
	late = TRUE

/obj/effect/mapping_helpers/broken_floor/LateInitialize()
	var/turf/open/floor/floor = get_turf(src)
	floor.break_tile()
	qdel(src)

/obj/effect/mapping_helpers/burnt_floor
	name = "burnt floor"
	icon = 'icons/turf/damaged.dmi'
	icon_state = "floorscorched1"
	layer = ABOVE_NORMAL_TURF_LAYER
	late = TRUE

/obj/effect/mapping_helpers/burnt_floor/LateInitialize()
	var/turf/open/floor/floor = get_turf(src)
	floor.burn_tile()
	qdel(src)

///Applies BROKEN flag to the first found machine on a tile
/obj/effect/mapping_helpers/broken_machine
	name = "broken machine helper"
	icon_state = "broken_machine"
	late = TRUE

/obj/effect/mapping_helpers/broken_machine/Initialize(mapload)
	. = ..()
	if(!mapload)
		log_mapping("[src] spawned outside of mapload!")
		return INITIALIZE_HINT_QDEL

	var/obj/machinery/target = locate(/obj/machinery) in loc
	if(isnull(target))
		var/area/target_area = get_area(src)
		log_mapping("[src] failed to find a machine at [AREACOORD(src)] ([target_area.type]).")
	else
		payload(target)

	return INITIALIZE_HINT_LATELOAD

/obj/effect/mapping_helpers/broken_machine/LateInitialize()
	var/obj/machinery/target = locate(/obj/machinery) in loc

	if(isnull(target))
		qdel(src)
		return

	target.update_appearance()
	qdel(src)

/obj/effect/mapping_helpers/broken_machine/proc/payload(obj/machinery/airalarm/target)
	if(target.machine_stat & BROKEN)
		var/area/area = get_area(target)
		log_mapping("[src] at [AREACOORD(src)] [(area.type)] tried to break [target] but it's already broken!")
	target.set_machine_stat(target.machine_stat | BROKEN)

///Deals random damage to the first window found on a tile to appear cracked
/obj/effect/mapping_helpers/damaged_window
	name = "damaged window helper"
	icon_state = "damaged_window"
	late = TRUE
	/// Minimum roll of integrity damage in percents needed to show cracks
	var/integrity_damage_min = 0.25
	/// Maximum roll of integrity damage in percents needed to show cracks
	var/integrity_damage_max = 0.85

/obj/effect/mapping_helpers/damaged_window/Initialize(mapload)
	. = ..()
	if(!mapload)
		log_mapping("[src] spawned outside of mapload!")
		return INITIALIZE_HINT_QDEL
	return INITIALIZE_HINT_LATELOAD

/obj/effect/mapping_helpers/damaged_window/LateInitialize()
	var/obj/structure/window/target = locate(/obj/structure/window) in loc

	if(isnull(target))
		var/area/target_area = get_area(src)
		log_mapping("[src] failed to find a window at [AREACOORD(src)] ([target_area.type]).")
		qdel(src)
		return
	else
		payload(target)

	target.update_appearance()
	qdel(src)

/obj/effect/mapping_helpers/damaged_window/proc/payload(obj/structure/window/target)
	if(target.get_integrity() < target.max_integrity)
		var/area/area = get_area(target)
		log_mapping("[src] at [AREACOORD(src)] [(area.type)] tried to damage [target] but it's already damaged!")
	target.take_damage(rand(target.max_integrity * integrity_damage_min, target.max_integrity * integrity_damage_max))

//requests console helpers
/obj/effect/mapping_helpers/requests_console
	desc = "You shouldn't see this. Report it please."
	late = TRUE

/obj/effect/mapping_helpers/requests_console/Initialize(mapload)
	. = ..()
	if(!mapload)
		log_mapping("[src] spawned outside of mapload!")
		return INITIALIZE_HINT_QDEL

	return INITIALIZE_HINT_LATELOAD

/obj/effect/mapping_helpers/requests_console/LateInitialize()
	var/obj/machinery/airalarm/target = locate(/obj/machinery/requests_console) in loc
	if(isnull(target))
		var/area/target_area = get_area(src)
		log_mapping("[src] failed to find a requests console at [AREACOORD(src)] ([target_area.type]).")
	else
		payload(target)

	qdel(src)

/// Fills out the request console's variables
/obj/effect/mapping_helpers/requests_console/proc/payload(obj/machinery/requests_console/console)
	return

/obj/effect/mapping_helpers/requests_console/announcement
	name = "request console announcement helper"
	icon_state = "requests_console_announcement_helper"

/obj/effect/mapping_helpers/requests_console/announcement/payload(obj/machinery/requests_console/console)
	console.can_send_announcements = TRUE

/obj/effect/mapping_helpers/requests_console/assistance
	name = "request console assistance requestable helper"
	icon_state = "requests_console_assistance_helper"

/obj/effect/mapping_helpers/requests_console/assistance/payload(obj/machinery/requests_console/console)
	GLOB.req_console_assistance |= console.department

/obj/effect/mapping_helpers/requests_console/supplies
	name = "request console supplies requestable helper"
	icon_state = "requests_console_supplies_helper"

/obj/effect/mapping_helpers/requests_console/supplies/payload(obj/machinery/requests_console/console)
	GLOB.req_console_supplies |= console.department

/obj/effect/mapping_helpers/requests_console/information
	name = "request console information relayable helper"
	icon_state = "requests_console_information_helper"

/obj/effect/mapping_helpers/requests_console/information/payload(obj/machinery/requests_console/console)
	GLOB.req_console_information |= console.department

/obj/effect/mapping_helpers/requests_console/ore_update
	name = "request console ore update helper"
	icon_state = "requests_console_ore_update_helper"

/obj/effect/mapping_helpers/requests_console/ore_update/payload(obj/machinery/requests_console/console)
	console.receive_ore_updates = TRUE

/obj/effect/mapping_helpers/engraving
	name = "engraving helper"
	icon = 'icons/turf/wall_overlays.dmi'
	icon_state = "engraving2"
	late = TRUE
	layer = ABOVE_NORMAL_TURF_LAYER

/obj/effect/mapping_helpers/engraving/Initialize(mapload)
	. = ..()
	return INITIALIZE_HINT_LATELOAD

/obj/effect/mapping_helpers/engraving/LateInitialize()
	var/turf/closed/engraved_wall = get_turf(src)

	if(!isclosedturf(engraved_wall) || !SSpersistence.saved_engravings.len || HAS_TRAIT(engraved_wall, TRAIT_NOT_ENGRAVABLE))
		qdel(src)
		return

	var/engraving = pick_n_take(SSpersistence.saved_engravings)
	if(!islist(engraving))
		stack_trace("something's wrong with the engraving data! one of the saved engravings wasn't a list!")
		qdel(src)
		return

	engraved_wall.AddComponent(/datum/component/engraved, engraving["story"], FALSE, engraving["story_value"])
	qdel(src)

/// Apply to a wall (or floor, technically) to ensure it is instantly destroyed by any explosion, even if usually invulnerable
/obj/effect/mapping_helpers/bombable_wall
	name = "bombable wall helper"
	icon = 'icons/turf/overlays.dmi'
	icon_state = "explodable"

/obj/effect/mapping_helpers/bombable_wall/Initialize(mapload)
	. = ..()
	if(!mapload)
		log_mapping("[src] spawned outside of mapload!")
		return

	var/turf/our_turf = get_turf(src) // In case a locker ate us or something
	our_turf.AddElement(/datum/element/bombable_turf)
	return INITIALIZE_HINT_QDEL

/// this helper buckles all mobs on the tile to the first buckleable object
/obj/effect/mapping_helpers/mob_buckler
	name = "Buckle Mob"
	icon_state = "buckle"
	late = TRUE
	///whether we force a buckle
	var/force_buckle = FALSE

/obj/effect/mapping_helpers/mob_buckler/Initialize(mapload)
	. = ..()
	if(!mapload)
		log_mapping("[src] spawned outside of mapload!")
		return INITIALIZE_HINT_QDEL

	return INITIALIZE_HINT_LATELOAD

/obj/effect/mapping_helpers/mob_buckler/LateInitialize()
	var/atom/movable/buckle_to
	var/list/mobs = list()
	for(var/atom/movable/possible_buckle as anything in loc)
		if(isnull(buckle_to) && possible_buckle.can_buckle)
			buckle_to = possible_buckle
			continue

		if(isliving(possible_buckle))
			mobs += possible_buckle

	if(isnull(buckle_to))
		log_mapping("[type] at [x] [y] [z] did not find anything to buckle to")
		qdel(src)
		return

	for(var/mob/living/mob as anything in mobs)
		buckle_to.buckle_mob(mob, force = force_buckle)

	qdel(src)

///Basic mob flag helpers for things like deleting on death.
/obj/effect/mapping_helpers/basic_mob_flags
	name = "Basic mob flags helper"
	desc = "Used to apply basic_mob_flags to basic mobs on the same turf."
	late = TRUE

	///The basic mob flag that we're adding to all basic mobs on the turf.
	var/flag_to_give

/obj/effect/mapping_helpers/basic_mob_flags/Initialize(mapload)
	. = ..()
	if(!mapload)
		log_mapping("[src] spawned outside of mapload!")
		return INITIALIZE_HINT_QDEL

/obj/effect/mapping_helpers/basic_mob_flags/LateInitialize()
	var/had_any_mobs = FALSE
	for(var/mob/living/basic/basic_mobs in loc)
		had_any_mobs = TRUE
		basic_mobs.basic_mob_flags |= flag_to_give
	if(!had_any_mobs)
		CRASH("[src] called on a turf without any basic mobs.")
	qdel(src)

/obj/effect/mapping_helpers/basic_mob_flags/del_on_death
	name = "Basic mob del on death flag helper"
	icon_state = "basic_mob_del_on_death"
	flag_to_give = DEL_ON_DEATH

/obj/effect/mapping_helpers/basic_mob_flags/flip_on_death
	name = "Basic mob flip on death flag helper"
	icon_state = "basic_mob_flip_on_death"
	flag_to_give = FLIP_ON_DEATH

/obj/effect/mapping_helpers/basic_mob_flags/remain_dense_while_dead
	name = "Basic mob remain dense while dead flag helper"
	icon_state = "basic_mob_remain_dense_while_dead"
	flag_to_give = REMAIN_DENSE_WHILE_DEAD

/obj/effect/mapping_helpers/basic_mob_flags/flammable_mob
	name = "Basic mob flammable flag helper"
	icon_state = "basic_mob_flammable"
	flag_to_give = FLAMMABLE_MOB

/obj/effect/mapping_helpers/basic_mob_flags/immune_to_fists
	name = "Basic mob immune to fists flag helper"
	icon_state = "basic_mob_immune_to_fists"
	flag_to_give = IMMUNE_TO_FISTS

/obj/effect/mapping_helpers/basic_mob_flags/immune_to_getting_wet
	name = "Basic mob immune to getting wet flag helper"
	icon_state = "basic_mob_immune_to_getting_wet"
	flag_to_give = IMMUNE_TO_GETTING_WET
