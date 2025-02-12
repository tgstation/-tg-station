/obj/docking_port/mobile/assault_pod
	name = "assault pod"
	shuttle_id = "steel_rain"

/obj/docking_port/mobile/assault_pod/request(obj/docking_port/stationary/S)
	if(!(z in SSmapping.levels_by_trait(ZTRAIT_STATION))) //No launching pods that have already launched
		return ..()


/obj/docking_port/mobile/assault_pod/initiate_docking(obj/docking_port/stationary/S1, force=FALSE)
	. = ..()
	if(!istype(S1, /obj/docking_port/stationary/transit))
		playsound(get_turf(src.loc), 'sound/effects/explosion/explosion1.ogg',50,TRUE)



/obj/item/assault_pod
	name = "Assault Pod Targeting Device"
	icon = 'icons/obj/devices/remote.dmi'
	icon_state = "designator_syndicate"
	inhand_icon_state = "nukietalkie"
	lefthand_file = 'icons/mob/inhands/items/devices_lefthand.dmi'
	righthand_file = 'icons/mob/inhands/items/devices_righthand.dmi'
	desc = "Used to select a landing zone for assault pods."
	var/shuttle_id = "steel_rain"
	var/dwidth = 3
	var/dheight = 0
	var/width = 7
	var/height = 7
	var/lz_dir = 1
	var/lzname = "assault_pod"


/obj/item/assault_pod/attack_self(mob/living/user)
	var/target_area = tgui_input_list(user, "Area to land", "Landing Zone", GLOB.teleportlocs)
	if(isnull(target_area))
		return
	if(isnull(GLOB.teleportlocs[target_area]))
		return
	var/area/picked_area = GLOB.teleportlocs[target_area]
	if(!src || QDELETED(src))
		return

	var/list/turfs = get_area_turfs(picked_area)
	if (!length(turfs))
		return
	var/turf/T = pick(turfs)
	var/obj/docking_port/stationary/landing_zone = new /obj/docking_port/stationary(T)
	landing_zone.shuttle_id = "[lzname]([REF(src)])"
	landing_zone.port_destinations = "[lzname]([REF(src)])"
	landing_zone.name = "Landing Zone"
	landing_zone.dwidth = dwidth
	landing_zone.dheight = dheight
	landing_zone.width = width
	landing_zone.height = height
	landing_zone.setDir(lz_dir)

	for(var/obj/machinery/computer/shuttle/S in SSmachines.get_machines_by_type_and_subtypes(/obj/machinery/computer/shuttle))
		if(S.shuttleId == shuttle_id)
			S.possible_destinations = "[landing_zone.shuttle_id]"

	to_chat(user, span_notice("Landing zone set."))

	qdel(src)

/obj/item/assault_pod/medieval //for the medieval pirates
	name = "Shuttle placement designator"
	icon = 'icons/obj/scrolls.dmi'
	icon_state = "blueprints"
	inhand_icon_state = null
	desc = "A map of the station used to select where you want to land your shuttle."
	shuttle_id = "pirate"
	dwidth = 1
	dheight = 1
	width = 15
	height = 9
	lzname = "pirate"

/obj/item/assault_pod/medieval/Initialize(mapload)
	. = ..()
	var/counter = length(SSmachines.get_machines_by_type_and_subtypes(/obj/machinery/computer/shuttle/pirate))
	if(counter != 1)
		shuttle_id = "[shuttle_id]_[counter]"
		lzname = "[lzname] [counter]"
