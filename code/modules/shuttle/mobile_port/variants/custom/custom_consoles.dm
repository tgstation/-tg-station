GLOBAL_LIST_INIT(custom_shuttle_station_area_whitelist, list(/area/station/asteroid))

/obj/machinery/computer/shuttle/custom_shuttle
	desc = "A shuttle control computer."
	icon_screen = "shuttle"
	icon_keyboard = "tech_key"
	shuttleId = ""
	light_color = LIGHT_COLOR_CYAN
	req_access = list()
	interaction_flags_machine = INTERACT_MACHINE_ALLOW_SILICON
	possible_destinations = "whiteship_home;"
	var/static/list/connections = list(COMSIG_TURF_ADDED_TO_SHUTTLE = PROC_REF(on_loc_added_to_shuttle))

/obj/machinery/computer/shuttle/custom_shuttle/on_construction(mob/user)
	circuit.configure_machine(src)
	if(!shuttleId)
		AddElement(/datum/element/connect_loc, connections)

/obj/machinery/computer/shuttle/custom_shuttle/proc/on_loc_added_to_shuttle(turf/source, obj/docking_port/mobile/custom/port)
	SIGNAL_HANDLER
	if(!istype(port))
		say("Cannot link to this kind of shuttle!")
	else
		if(connect_to_shuttle(TRUE, port))
			RemoveElement(/datum/element/connect_loc, connections)

/obj/machinery/computer/shuttle/custom_shuttle/connect_to_shuttle(mapload, obj/docking_port/mobile/port, obj/docking_port/stationary/dock)
	var/obj/docking_port/mobile/custom/custom_port = port
	if(istype(custom_port))
		if(custom_port.control_console?.resolve())
			say("Control console already present!")
			return FALSE
	. = ..()
	if(!.)
		return
	if(istype(custom_port))
		custom_port.control_console = WEAKREF(src)
	name = "[port.name] console"

/obj/machinery/computer/shuttle/custom_shuttle/proc/linkShuttle(new_id)
	if(shuttleId=="")
		shuttleId = new_id
		possible_destinations = "whiteship_home;shuttle[new_id]_custom;"
		return TRUE
	return FALSE


//docking cam
/obj/machinery/computer/camera_advanced/shuttle_docker/custom
	lock_override = NONE
	jump_to_ports = list("whiteship_home" = 1)
	designate_time = 100
	circuit = /obj/item/circuitboard/computer/shuttle/docker
	var/static/list/connections = list(COMSIG_TURF_ADDED_TO_SHUTTLE = PROC_REF(on_loc_added_to_shuttle))

/obj/machinery/computer/camera_advanced/shuttle_docker/custom/on_construction(mob/user)
	circuit.configure_machine(src)
	if(!shuttleId)
		AddElement(/datum/element/connect_loc, connections)

/obj/machinery/computer/camera_advanced/shuttle_docker/custom/proc/on_loc_added_to_shuttle(turf/source, obj/docking_port/mobile/custom/port)
	SIGNAL_HANDLER
	if(!istype(port))
		say("Cannot link to this kind of shuttle!")
	else
		if(connect_to_shuttle(TRUE, port))
			RemoveElement(/datum/element/connect_loc, connections)

/obj/machinery/computer/camera_advanced/shuttle_docker/custom/Initialize(mapload)
	. = ..()
	GLOB.jam_on_wardec += src

/obj/machinery/computer/camera_advanced/shuttle_docker/custom/Destroy()
	GLOB.jam_on_wardec -= src
	return ..()

/obj/machinery/computer/camera_advanced/shuttle_docker/custom/connect_to_shuttle(mapload, obj/docking_port/mobile/port, obj/docking_port/stationary/dock)
	if(shuttleId) //We normally should only be connecting newly-created consoles to shuttles, but just in case...
		var/obj/docking_port/mobile/old_shuttle = SSshuttle.getShuttle(shuttleId)
		if(old_shuttle)
			UnregisterSignal(old_shuttle, COMSIG_SHUTTLE_EXPANDED)
	var/obj/docking_port/mobile/custom/custom_port = port
	if(istype(custom_port))
		if(custom_port.navigation_console?.resolve())
			say("Navigation console already present!")
			return FALSE
	. = ..()
	if(!.)
		return
	name = "[port.name] navigation computer"
	if(istype(custom_port))
		custom_port.navigation_console = WEAKREF(src)
	RegisterSignal(port, COMSIG_SHUTTLE_EXPANDED, PROC_REF(on_shuttle_expanded))
	recalculate_eye_view(port)

/obj/machinery/computer/camera_advanced/shuttle_docker/custom/proc/on_shuttle_expanded(obj/docking_port/mobile/source, list/turfs)
	SIGNAL_HANDLER
	recalculate_eye_view(source)
	if(my_port)
		var/here_x = source.x
		var/here_y = source.y
		var/there_x = my_port.x
		var/there_y = my_port.y
		var/target_z = my_port.z
		var/rotation = angle2dir_cardinal(dir2angle(my_port.dir) - dir2angle(source.dir))
		var/docked = my_port.get_docked() == source
		for(var/turf/turf as anything in turfs)
			var/turf/checked_turf
			if(docked)
				checked_turf = turf
			else
				var/offset_x = turf.x - here_x
				var/offset_y = turf.y - here_y
				var/target_x = there_x
				var/target_y = there_y
				switch(rotation)
					if(NORTH)
						target_x += offset_x
						target_y += offset_y
					if(SOUTH)
						target_x -= offset_x
						target_y -= offset_y
					if(EAST)
						target_x -= offset_y
						target_y += offset_x
					if(WEST)
						target_x += offset_y
						target_y -= offset_x
				checked_turf = locate(target_x, target_y, target_z)
			if(checkLandingTurf(checked_turf) != SHUTTLE_DOCKER_LANDING_CLEAR)
				if(docked)
					my_port.unregister()
					my_port.delete_after = TRUE
					my_port.shuttle_id = null
					my_port.name = "Old [my_port.name]"
					my_port = null
				else
					QDEL_NULL(my_port)
				break

/obj/machinery/computer/camera_advanced/shuttle_docker/custom/proc/recalculate_eye_view(obj/docking_port/mobile/shuttle)
	var/bigger_shuttle_dimension = max(shuttle.width, shuttle.height)
	var/list/viewsize = getviewsize(world.view)
	var/smaller_view_dimension = min(viewsize[1], viewsize[2])
	var/new_view_range = max(bigger_shuttle_dimension - smaller_view_dimension, 0)
	if(new_view_range != view_range)
		view_range = new_view_range

/obj/machinery/computer/camera_advanced/shuttle_docker/custom/placeLandingSpot()
	if(!shuttleId)
		return	//Only way this would happen is if someone else delinks the console while in use somehow
	var/obj/docking_port/mobile/M = SSshuttle.getShuttle(shuttleId)
	if(M?.mode != SHUTTLE_IDLE)
		to_chat(usr, "<span class='warning'>You cannot target locations while in transit.</span>")
		return
	..()

/obj/machinery/computer/camera_advanced/shuttle_docker/custom/checkLandingTurf(turf/T, list/overlappers)
	. = ..()
	var/area/area = get_area(T)
	if(!is_type_in_list(area, GLOB.custom_shuttle_station_area_whitelist) && is_type_in_list(area, GLOB.the_station_areas))
		return SHUTTLE_DOCKER_BLOCKED

/obj/machinery/computer/camera_advanced/shuttle_docker/custom/attack_hand(mob/user)
	if(!shuttleId)
		to_chat(user, "<span class='warning'>You must link the console to a shuttle first.</span>")
		return
	return ..()

/obj/machinery/computer/camera_advanced/shuttle_docker/custom/proc/linkShuttle(new_id)
	if(shuttleId=="")
		shuttleId = new_id
		return TRUE
	return FALSE
