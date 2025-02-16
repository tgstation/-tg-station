/obj/machinery/computer/camera_advanced/shuttle_docker
	name = "navigation computer"
	desc = "Used to designate a precise transit location for a spacecraft."
	jump_action = null
	should_supress_view_changes = FALSE

	// Docking cameras should only interact with their current z-level.
	move_up_action = null
	move_down_action = null

	var/shuttleId = ""
	var/shuttlePortId = ""
	var/shuttlePortName = "custom location"
	/// Hashset of ports to jump to and ignore for collision purposes
	var/list/jump_to_ports = list()
	/// The custom docking port placed by this console
	var/obj/docking_port/stationary/my_port
	/// The mobile docking port of the connected shuttle
	var/obj/docking_port/mobile/shuttle_port
	// Traits forbided for custom docking
	var/list/locked_traits = list(ZTRAIT_RESERVED, ZTRAIT_CENTCOM, ZTRAIT_AWAY)
	var/view_range = 0
	///x offset for where the camera eye will spawn. Starts from shuttle's docking port
	var/x_offset = 0
	///y offset for where the camera eye will spawn. Starts from the shuttle's docking port
	var/y_offset = 0
	var/list/whitelist_turfs = list(/turf/open/space, /turf/open/floor/plating, /turf/open/lava, /turf/open/openspace, /turf/open/misc)
	var/see_hidden = FALSE
	var/designate_time = 0
	var/turf/designating_target_loc
	var/jammed = FALSE

/obj/machinery/computer/camera_advanced/shuttle_docker/Initialize(mapload)
	. = ..()
	actions += new /datum/action/innate/shuttledocker_rotate(src)
	actions += new /datum/action/innate/shuttledocker_place(src)
	AddElement(/datum/element/nav_computer_icon, 'icons/effects/nav_computer_indicators.dmi', "computer", FALSE)
	set_init_ports()

	if(connect_to_shuttle(mapload, SSshuttle.get_containing_shuttle(src)))
		for(var/obj/docking_port/stationary/port as anything in SSshuttle.stationary_docking_ports)
			if(port.shuttle_id == shuttleId)
				add_jumpable_port(port.shuttle_id)

	for(var/obj/docking_port/stationary/port as anything in SSshuttle.stationary_docking_ports)
		if(!port)
			continue
		if(jump_to_ports[port.shuttle_id])
			z_lock |= port.z
	whitelist_turfs = typecacheof(whitelist_turfs)

/obj/machinery/computer/camera_advanced/shuttle_docker/Destroy()
	. = ..()
	if(my_port?.get_docked())
		my_port.delete_after = TRUE
		my_port.shuttle_id = null
		my_port.name = "Old [my_port.name]"
		my_port = null
	else
		QDEL_NULL(my_port)

/obj/machinery/computer/camera_advanced/shuttle_docker/vv_edit_var(vname, vval)
	. = ..()
	if(vname in list(NAMEOF(src, view_range), NAMEOF(src, x_offset), NAMEOF(src, y_offset), NAMEOF(src, see_hidden)))
		refresh_eye()

/// Destroys the eyeobj of this console, safely refreshing it if the console is currently being used.
/obj/machinery/computer/camera_advanced/shuttle_docker/proc/refresh_eye()
	var/mob/living/user = current_user
	if(user)
		remove_eye_control(user)
	QDEL_NULL(eyeobj)
	if(user)
		attack_hand(user)

/// "Initializes" any default port ids we have, done so add_jumpable_port can be a proper setter
/obj/machinery/computer/camera_advanced/shuttle_docker/proc/set_init_ports()
	var/list/init_ports = jump_to_ports.Copy()
	jump_to_ports = list() //Reset it so we don't get dupes
	for(var/port_id in init_ports)
		add_jumpable_port(port_id)

/obj/machinery/computer/camera_advanced/shuttle_docker/proc/add_jumpable_port(port_id)
	if(!length(jump_to_ports))
		actions += new /datum/action/innate/camera_jump/shuttle_docker(src)
	jump_to_ports[port_id] = TRUE

/obj/machinery/computer/camera_advanced/shuttle_docker/proc/remove_jumpable_port(port_id)
	jump_to_ports -= port_id
	if(!length(jump_to_ports))
		var/datum/action/to_remove = locate(/datum/action/innate/camera_jump/shuttle_docker) in actions
		actions -= to_remove
		qdel(to_remove)

/obj/machinery/computer/camera_advanced/shuttle_docker/attack_hand(mob/user, list/modifiers)
	if(jammed)
		to_chat(user, span_warning("The Syndicate is jamming the console!"))
		return
	if(!shuttle_port && !SSshuttle.getShuttle(shuttleId))
		to_chat(user,span_warning("Warning: Shuttle connection severed!"))
		return
	return ..()

/obj/machinery/computer/camera_advanced/shuttle_docker/CreateEye()
	shuttle_port = SSshuttle.getShuttle(shuttleId)
	if(QDELETED(shuttle_port))
		shuttle_port = null
		return

	eyeobj = new /mob/eye/camera/remote/shuttle_docker(null, src)
	var/mob/eye/camera/remote/shuttle_docker/the_eye = eyeobj
	the_eye.setDir(shuttle_port.dir)
	var/turf/origin = locate(shuttle_port.x + x_offset, shuttle_port.y + y_offset, shuttle_port.z)
	for(var/area/shuttle_area as anything in shuttle_port.shuttle_areas)
		for (var/list/zlevel_turfs as anything in shuttle_area.get_zlevel_turf_lists())
			for(var/turf/shuttle_turf as anything in zlevel_turfs)
				if(shuttle_turf.z != origin.z)
					continue
				var/image/I = image('icons/effects/alphacolors.dmi', origin, "red")
				var/x_off = shuttle_turf.x - origin.x
				var/y_off = shuttle_turf.y - origin.y
				I.loc = locate(origin.x + x_off, origin.y + y_off, origin.z) //we have to set this after creating the image because it might be null, and images created in nullspace are immutable.
				I.layer = ABOVE_NORMAL_TURF_LAYER
				SET_PLANE(I, ABOVE_GAME_PLANE, shuttle_turf)
				I.mouse_opacity = MOUSE_OPACITY_TRANSPARENT
				the_eye.placement_images[I] = list(x_off, y_off)
	gatherNavComputerIcons()

	return TRUE

/obj/machinery/computer/camera_advanced/shuttle_docker/give_eye_control(mob/user)
	..()
	if(!QDELETED(user) && user.client)
		var/mob/eye/camera/remote/shuttle_docker/the_eye = eyeobj
		var/list/to_add = list()
		to_add += the_eye.placement_images
		to_add += the_eye.placed_images
		to_add += the_eye.extra_images
		if(!see_hidden)
			to_add += SSshuttle.hidden_shuttle_turf_images

		user.client.images += to_add
		user.client.view_size.setTo(view_range)

/obj/machinery/computer/camera_advanced/shuttle_docker/remove_eye_control(mob/living/user)
	..()
	if(!QDELETED(user) && user.client)
		var/mob/eye/camera/remote/shuttle_docker/the_eye = eyeobj
		var/list/to_remove = list()
		to_remove += the_eye.placement_images
		to_remove += the_eye.placed_images
		to_remove += the_eye.extra_images
		if(!see_hidden)
			to_remove += SSshuttle.hidden_shuttle_turf_images

		user.client.images -= to_remove
		user.client.view_size.resetToDefault()

/obj/machinery/computer/camera_advanced/shuttle_docker/proc/shuttle_turf_from_coords(list/coords)
	var/mob/eye/camera/remote/shuttle_docker/the_eye = eyeobj
	var/shuttleDir = shuttle_port.dir
	var/curDir = the_eye.dir
	var/list/adjustedCoords = coords.Copy()

	// Rotate coords so  they match the current shuttle docking port's dir
	if(turn(curDir, -90) == shuttleDir)
		adjustedCoords[1] = coords[2] + y_offset
		adjustedCoords[2] = -(coords[1] + x_offset)
	else if(turn(curDir, 90) == shuttleDir)
		adjustedCoords[1] = -(coords[2] + y_offset)
		adjustedCoords[2] = coords[1] + x_offset
	else if(turn(curDir, 180) == shuttleDir)
		adjustedCoords[1] = -(coords[1] + x_offset)
		adjustedCoords[2] = -(coords[2] + y_offset)
	else
		adjustedCoords[1] = coords[1] + x_offset
		adjustedCoords[2] = coords[2] + y_offset

	return locate(shuttle_port.x + adjustedCoords[1], shuttle_port.y + adjustedCoords[2], shuttle_port.z)

/obj/machinery/computer/camera_advanced/shuttle_docker/proc/gatherNavComputerIcons()
	var/mob/eye/camera/remote/shuttle_docker/the_eye = eyeobj
	var/list/placement_image_cache = the_eye.placement_images
	var/list/extra_image_cache = the_eye.extra_images
	for(var/i in 1 to placement_image_cache.len)
		var/image/placement_image = placement_image_cache[i]
		var/list/coords = placement_image_cache[placement_image]
		var/turf/shuttle_turf = shuttle_turf_from_coords(coords)
		var/list/images_to_add = list()
		for(var/atom/atom as anything in shuttle_turf)
			SEND_SIGNAL(atom, COMSIG_SHUTTLE_NAV_COMPUTER_IMAGE_REQUESTED, images_to_add)
		for(var/i2 in 1 to images_to_add.len)
			var/image/extra_image = images_to_add[i2]
			extra_image.dir = turn(extra_image.dir, dir2angle(the_eye.dir) - dir2angle(shuttle_port.dir))
			extra_image.loc = locate(the_eye.x + coords[1], the_eye.y + coords[2], the_eye.z)
			extra_image.layer = ABOVE_NORMAL_TURF_LAYER
			SET_PLANE(extra_image, ABOVE_GAME_PLANE, the_eye)
			extra_image.mouse_opacity = MOUSE_OPACITY_TRANSPARENT
			extra_image_cache[extra_image] = coords.Copy()

/obj/machinery/computer/camera_advanced/shuttle_docker/proc/placeLandingSpot()
	if(designating_target_loc || !current_user)
		return

	var/mob/eye/camera/remote/shuttle_docker/the_eye = eyeobj
	var/landing_clear = checkLandingSpot()
	if(designate_time && (landing_clear != SHUTTLE_DOCKER_BLOCKED))
		to_chat(current_user, span_warning("Targeting transit location, please wait [DisplayTimeText(designate_time)]..."))
		designating_target_loc = the_eye.loc
		var/wait_completed = do_after(current_user, designate_time, designating_target_loc, timed_action_flags = IGNORE_HELD_ITEM, extra_checks = CALLBACK(src, TYPE_PROC_REF(/obj/machinery/computer/camera_advanced/shuttle_docker, canDesignateTarget)))
		designating_target_loc = null
		if(!current_user)
			return
		if(!wait_completed)
			to_chat(current_user, span_warning("Operation aborted."))
			return
		landing_clear = checkLandingSpot()

	if(landing_clear != SHUTTLE_DOCKER_LANDING_CLEAR)
		switch(landing_clear)
			if(SHUTTLE_DOCKER_BLOCKED)
				to_chat(current_user, span_warning("Invalid transit location."))
			if(SHUTTLE_DOCKER_BLOCKED_BY_HIDDEN_PORT)
				to_chat(current_user, span_warning("Unknown object detected in landing zone. Please designate another location."))
		return

	///Make one use port that deleted after fly off, to don't lose info that need on to properly fly off.
	if(my_port?.get_docked())
		my_port.unregister()
		my_port.delete_after = TRUE
		my_port.shuttle_id = null
		my_port.name = "Old [my_port.name]"
		my_port = null

	if(!my_port)
		my_port = new()
		my_port.unregister()
		my_port.name = shuttlePortName
		my_port.shuttle_id = shuttlePortId
		my_port.height = shuttle_port.height
		my_port.width = shuttle_port.width
		my_port.dheight = shuttle_port.dheight
		my_port.dwidth = shuttle_port.dwidth
		my_port.hidden = shuttle_port.hidden
		my_port.register(TRUE)
	my_port.setDir(the_eye.dir)
	my_port.forceMove(locate(eyeobj.x - x_offset, eyeobj.y - y_offset, eyeobj.z))

	if(current_user.client)
		current_user.client.images -= the_eye.placed_images

	LAZYCLEARLIST(the_eye.placed_images)

	for(var/image/place_spots as anything in the_eye.placement_images)
		var/image/newI = image('icons/effects/alphacolors.dmi', the_eye.loc, "blue")
		newI.loc = place_spots.loc //It is highly unlikely that any landing spot including a null tile will get this far, but better safe than sorry.
		newI.layer = NAVIGATION_EYE_LAYER
		SET_PLANE_EXPLICIT(newI, ABOVE_GAME_PLANE, place_spots)
		newI.mouse_opacity = 0
		the_eye.placed_images += newI

	if(current_user.client)
		current_user.client.images += the_eye.placed_images
		to_chat(current_user, span_notice("Transit location designated."))
	return TRUE

/obj/machinery/computer/camera_advanced/shuttle_docker/proc/canDesignateTarget()
	if(!designating_target_loc || !current_user || (eyeobj.loc != designating_target_loc) || (machine_stat & (NOPOWER|BROKEN)) )
		return FALSE
	return TRUE

/obj/machinery/computer/camera_advanced/shuttle_docker/proc/rotateLandingSpot()
	var/mob/eye/camera/remote/shuttle_docker/the_eye = eyeobj
	var/list/image_cache = the_eye.placement_images + the_eye.extra_images
	the_eye.setDir(turn(the_eye.dir, -90))
	for(var/i in 1 to image_cache.len)
		var/image/pic = image_cache[i]
		var/list/coords = image_cache[pic]
		var/Tmp = coords[1]
		coords[1] = coords[2]
		coords[2] = -Tmp
		pic.loc = locate(the_eye.x + coords[1], the_eye.y + coords[2], the_eye.z)
		pic.dir = turn(pic.dir, -90)
	var/Tmp = x_offset
	x_offset = y_offset
	y_offset = -Tmp
	checkLandingSpot()

/obj/machinery/computer/camera_advanced/shuttle_docker/proc/checkLandingSpot()
	var/mob/eye/camera/remote/shuttle_docker/the_eye = eyeobj
	var/turf/eyeturf = get_turf(the_eye)
	if(!eyeturf)
		return SHUTTLE_DOCKER_BLOCKED
	if(!eyeturf.z || SSmapping.level_has_any_trait(eyeturf.z, locked_traits))
		return SHUTTLE_DOCKER_BLOCKED

	. = SHUTTLE_DOCKER_LANDING_CLEAR
	var/list/bounds = shuttle_port.return_coords(the_eye.x - x_offset, the_eye.y - y_offset, the_eye.dir)
	var/list/overlappers = SSshuttle.get_dock_overlap(bounds[1], bounds[2], bounds[3], bounds[4], the_eye.z)
	var/list/image_cache = the_eye.placement_images
	for(var/i in 1 to image_cache.len)
		var/image/I = image_cache[i]
		var/list/coords = image_cache[I]
		var/turf/T = locate(eyeturf.x + coords[1], eyeturf.y + coords[2], eyeturf.z)
		I.loc = T
		switch(checkLandingTurf(T, overlappers))
			if(SHUTTLE_DOCKER_LANDING_CLEAR)
				I.icon_state = "green"
			if(SHUTTLE_DOCKER_BLOCKED_BY_HIDDEN_PORT)
				I.icon_state = "green"
				if(. == SHUTTLE_DOCKER_LANDING_CLEAR)
					. = SHUTTLE_DOCKER_BLOCKED_BY_HIDDEN_PORT
			else
				I.icon_state = "red"
				. = SHUTTLE_DOCKER_BLOCKED
	var/list/extra_image_cache = the_eye.extra_images
	for(var/i in 1 to extra_image_cache.len)
		var/image/image = extra_image_cache[i]
		var/list/coords = extra_image_cache[image]
		var/turf/turf = locate(eyeturf.x + coords[1], eyeturf.y + coords[2], eyeturf.z)
		image.loc = turf

/obj/machinery/computer/camera_advanced/shuttle_docker/proc/checkLandingTurf(turf/T, list/overlappers)
	// Too close to the map edge is never allowed
	if(!T || T.x <= 10 || T.y <= 10 || T.x >= world.maxx - 10 || T.y >= world.maxy - 10)
		return SHUTTLE_DOCKER_BLOCKED
	// If it's one of our shuttle areas assume it's ok to be there
	if(shuttle_port.shuttle_areas[T.loc])
		return SHUTTLE_DOCKER_LANDING_CLEAR
	. = SHUTTLE_DOCKER_LANDING_CLEAR
	// See if the turf is hidden from us
	var/list/hidden_turf_info
	if(!see_hidden)
		hidden_turf_info = SSshuttle.hidden_shuttle_turfs[T]
		if(hidden_turf_info)
			. = SHUTTLE_DOCKER_BLOCKED_BY_HIDDEN_PORT

	if(length(whitelist_turfs))
		var/turf_type = hidden_turf_info ? hidden_turf_info[2] : T.type
		if(!is_type_in_typecache(turf_type, whitelist_turfs))
			return SHUTTLE_DOCKER_BLOCKED

	// Checking for overlapping dock boundaries
	for(var/i in 1 to overlappers.len)
		var/obj/docking_port/port = overlappers[i]
		if(port == my_port)
			continue
		var/port_hidden = !see_hidden && port.hidden
		var/list/overlap = overlappers[port]
		var/list/xs = overlap[1]
		var/list/ys = overlap[2]
		if(xs["[T.x]"] && ys["[T.y]"])
			if(port_hidden)
				. = SHUTTLE_DOCKER_BLOCKED_BY_HIDDEN_PORT
			else
				return SHUTTLE_DOCKER_BLOCKED

/obj/machinery/computer/camera_advanced/shuttle_docker/proc/update_hidden_docking_ports(list/remove_images, list/add_images)
	if(!see_hidden && current_user?.client)
		current_user.client.images -= remove_images
		current_user.client.images += add_images

/obj/machinery/computer/camera_advanced/shuttle_docker/connect_to_shuttle(mapload, obj/docking_port/mobile/port, obj/docking_port/stationary/dock)
	if(!mapload)
		return FALSE
	if(port)
		shuttleId = port.shuttle_id
		shuttlePortId = "[port.shuttle_id]_custom"
	if(dock)
		add_jumpable_port(dock.shuttle_id)
	return TRUE

/mob/eye/camera/remote/shuttle_docker
	use_visibility = FALSE
	var/list/image/placement_images = list()
	var/list/image/placed_images = list()
	var/list/image/extra_images = list()

/mob/eye/camera/remote/shuttle_docker/setLoc(turf/destination, force_update = FALSE)
	. = ..()
	var/obj/machinery/computer/camera_advanced/shuttle_docker/console = origin_ref?.resolve()
	console.checkLandingSpot()

/mob/eye/camera/remote/shuttle_docker/update_remote_sight(mob/living/user)
	user.set_sight(BLIND|SEE_TURFS)
	// Pale blue, should look nice I think
	user.lighting_color_cutoffs = list(30, 40, 50)
	user.sync_lighting_plane_cutoff()
	return TRUE

/datum/action/innate/shuttledocker_rotate
	name = "Rotate"
	button_icon = 'icons/mob/actions/actions_mecha.dmi'
	button_icon_state = "mech_cycle_equip_off"

/datum/action/innate/shuttledocker_rotate/Activate()
	if(QDELETED(owner) || !isliving(owner))
		return
	var/mob/eye/camera/remote/remote_eye = owner.remote_control
	var/obj/machinery/computer/camera_advanced/shuttle_docker/origin = remote_eye.origin_ref.resolve()
	origin.rotateLandingSpot()

/datum/action/innate/shuttledocker_place
	name = "Place"
	button_icon = 'icons/mob/actions/actions_mecha.dmi'
	button_icon_state = "mech_zoom_off"

/datum/action/innate/shuttledocker_place/Activate()
	if(QDELETED(owner) || !isliving(owner))
		return
	var/mob/eye/camera/remote/remote_eye = owner.remote_control
	var/obj/machinery/computer/camera_advanced/shuttle_docker/origin = remote_eye.origin_ref.resolve()
	origin.placeLandingSpot(owner)

/datum/action/innate/camera_jump/shuttle_docker
	name = "Jump to Location"
	button_icon_state = "camera_jump"

/datum/action/innate/camera_jump/shuttle_docker/Activate()
	if(QDELETED(owner) || !isliving(owner))
		return
	var/mob/eye/camera/remote/remote_eye = owner.remote_control
	var/obj/machinery/computer/camera_advanced/shuttle_docker/console = remote_eye.origin_ref.resolve()

	playsound(console, 'sound/machines/terminal/terminal_prompt_deny.ogg', 25, FALSE)

	var/list/L = list()
	for(var/V in SSshuttle.stationary_docking_ports)
		if(!V)
			stack_trace("SSshuttle.stationary_docking_ports have null entry!")
			continue
		var/obj/docking_port/stationary/S = V
		if(console.z_lock.len && !(S.z in console.z_lock))
			continue
		if(console.jump_to_ports[S.shuttle_id])
			L["([L.len])[S.name]"] = S

	for(var/V in SSshuttle.beacon_list)
		if(!V)
			stack_trace("SSshuttle.beacon_list have null entry!")
			continue
		var/obj/machinery/spaceship_navigation_beacon/nav_beacon = V
		if(!nav_beacon.z || SSmapping.level_has_any_trait(nav_beacon.z, console.locked_traits))
			break
		if(!nav_beacon.locked)
			L["([L.len]) [nav_beacon.name] located: [nav_beacon.x] [nav_beacon.y] [nav_beacon.z]"] = nav_beacon
		else
			L["([L.len]) [nav_beacon.name] locked"] = null

	playsound(console, 'sound/machines/terminal/terminal_prompt.ogg', 25, FALSE)
	var/selected = tgui_input_list(usr, "Choose location to jump to", "Locations", sort_list(L))
	if(isnull(selected))
		playsound(console, 'sound/machines/terminal/terminal_prompt_deny.ogg', 25, FALSE)
		return
	if(QDELETED(src) || QDELETED(owner) || !isliving(owner))
		return
	playsound(src, SFX_TERMINAL_TYPE, 25, FALSE)
	var/turf/T = get_turf(L[selected])
	if(isnull(T))
		return
	playsound(console, 'sound/machines/terminal/terminal_prompt_confirm.ogg', 25, FALSE)
	remote_eye.setLoc(T)
	to_chat(owner, span_notice("Jumped to [selected]."))
	owner.overlay_fullscreen("flash", /atom/movable/screen/fullscreen/flash/static)
	owner.clear_fullscreen("flash", 3)
