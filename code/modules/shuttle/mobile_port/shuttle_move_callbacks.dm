/*
All ShuttleMove procs go here
*/

/************************************Base procs************************************/

// Called on every turf in the shuttle region, returns a bitflag for allowed movements of that turf
// returns the new move_mode (based on the old)
/turf/proc/fromShuttleMove(turf/newT, move_mode)
	if(!(move_mode & MOVE_AREA) || !isshuttleturf(src))
		return move_mode

	return move_mode | MOVE_TURF | MOVE_CONTENTS

// Called from the new turf before anything has been moved
// Only gets called if fromShuttleMove returns true first
// returns the new move_mode (based on the old)
/turf/proc/toShuttleMove(turf/oldT, move_mode, obj/docking_port/mobile/shuttle)
	. = move_mode
	if(!(. & MOVE_TURF))
		return

	var/shuttle_dir = shuttle.dir
	for(var/atom/movable/thing as anything in contents)
		if(thing.resistance_flags & SHUTTLE_CRUSH_PROOF)
			continue
		if(isliving(thing))
			var/mob/living/living_thing = thing
			if(living_thing.incorporeal_move) // Don't crush incorporeal things
				continue
			living_thing.buckled?.unbuckle_mob(living_thing, force = TRUE)
			living_thing.pulledby?.stop_pulling()
			living_thing.stop_pulling()
			living_thing.visible_message(span_warning("[shuttle] slams into [living_thing]!"))
			SSblackbox.record_feedback("tally", "shuttle_gib", 1, living_thing.type)
			log_shuttle("[key_name(living_thing)] was shuttle gibbed by [shuttle].")
			living_thing.investigate_log("has been gibbed by [shuttle].", INVESTIGATE_DEATHS)
			living_thing.gib(DROP_ALL_REMAINS)
		else if(!ismob(thing)) //non-living mobs shouldn't be affected by shuttles, which is why this is an else
			if(!thing.anchored)
				step(thing, shuttle_dir)
			else
				qdel(thing)

// Called on the old turf to move the turf data
/turf/proc/onShuttleMove(turf/newT, list/movement_force, move_dir)
	if(newT == src) // In case of in place shuttle rotation shenanigans.
		return
	// Destination turf changes.
	// Baseturfs is definitely a list or this proc wouldnt be called.
	var/shuttle_depth = depth_to_find_baseturf(/turf/baseturf_skipover/shuttle)

	if(!shuttle_depth)
		CRASH("A turf queued to move via shuttle somehow had no skipover in baseturfs. [src]([type]):[loc]")
	newT.CopyOnTop(src, 1, shuttle_depth, TRUE)
	newT.blocks_air = TRUE
	newT.air_update_turf(TRUE, FALSE)
	blocks_air = TRUE
	air_update_turf(TRUE, TRUE)
	if(isopenturf(newT))
		var/turf/open/new_open = newT
		new_open.copy_air_with_tile(src)
	SEND_SIGNAL(src, COMSIG_TURF_ON_SHUTTLE_MOVE, newT)

	return TRUE

// Called on the new turf after everything has been moved
/turf/proc/afterShuttleMove(turf/oldT, rotation)
	//Dealing with the turf we left behind
	oldT.TransferComponents(src)

	SSexplosions.wipe_turf(src)
	var/shuttle_depth = depth_to_find_baseturf(/turf/baseturf_skipover/shuttle)

	if(shuttle_depth)
		oldT.ScrapeAway(shuttle_depth)

	if(rotation)
		shuttleRotate(rotation) //see shuttle_rotate.dm

	return TRUE

/turf/proc/lateShuttleMove(turf/oldT)
	blocks_air = initial(blocks_air)
	air_update_turf(TRUE, blocks_air)
	oldT.blocks_air = initial(oldT.blocks_air)
	oldT.air_update_turf(TRUE, oldT.blocks_air)


/////////////////////////////////////////////////////////////////////////////////////

// Return the move_move (based on the old), without any side effects.
// This is for checking what would be moved if src is on a shuttle being moved.
/atom/movable/proc/hypotheticalShuttleMove(rotation, move_mode, obj/docking_port/mobile/moving_dock)
	return move_mode

// Called on every atom in shuttle turf contents before anything has been moved
// returns the new move_mode (based on the old)
// WARNING: Do not leave turf contents in beforeShuttleMove or dock() will runtime
/atom/movable/proc/beforeShuttleMove(turf/newT, rotation, move_mode, obj/docking_port/mobile/moving_dock)
	return move_mode

/// Called on atoms to move the atom to the new location
/atom/movable/proc/onShuttleMove(turf/newT, turf/oldT, list/movement_force, move_dir, obj/docking_port/stationary/old_dock, obj/docking_port/mobile/moving_dock)
	if(newT == oldT) // In case of in place shuttle rotation shenanigans.
		return

	if(loc != oldT) // This is for multi tile objects
		return

	abstract_move(newT)

	return TRUE

// Called on atoms after everything has been moved
/atom/movable/proc/afterShuttleMove(turf/oldT, list/movement_force, shuttle_dir, shuttle_preferred_direction, move_dir, rotation)
	SEND_SIGNAL(src, COMSIG_ATOM_AFTER_SHUTTLE_MOVE, oldT)
	if(light)
		update_light()
	if(rotation)
		shuttleRotate(rotation)

	update_parallax_contents()

	return TRUE

/atom/movable/proc/lateShuttleMove(turf/oldT, list/movement_force, move_dir)
	if(!movement_force || anchored)
		return
	var/throw_force = movement_force["THROW"]
	if(!throw_force)
		return
	var/turf/target = get_edge_target_turf(src, move_dir)
	var/range = throw_force * 10
	range = CEILING(rand(range-(range*0.1), range+(range*0.1)), 10)/10
	var/speed = range/5
	safe_throw_at(target, range, speed, force = MOVE_FORCE_EXTREMELY_STRONG)

/////////////////////////////////////////////////////////////////////////////////////

// Called on areas before anything has been moved
// returns the new move_mode (based on the old)
/area/proc/beforeShuttleMove(list/shuttle_areas)
	if(!shuttle_areas[src])
		return NONE
	return MOVE_AREA

// Called on areas to move their turf between areas
/area/proc/onShuttleMove(turf/oldT, turf/newT, obj/docking_port/mobile/shuttle, area/fallback_area)
	if(newT == oldT) // In case of in place shuttle rotation shenanigans.
		return TRUE

	var/area/underlying_area = shuttle.underlying_areas_by_turf[oldT]
	oldT.change_area(src, underlying_area || fallback_area)
	shuttle.underlying_areas_by_turf -= oldT
	//The old turf has now been given back to the area that turf originaly belonged to

	var/area/old_dest_area = newT.loc
	parallax_movedir = old_dest_area.parallax_movedir
	newT.change_area(old_dest_area, src)
	shuttle.underlying_areas_by_turf[newT] = old_dest_area
	return TRUE

// Called on areas after everything has been moved
/area/proc/afterShuttleMove(new_parallax_dir)
	parallax_movedir = new_parallax_dir
	return TRUE

/area/proc/lateShuttleMove()
	return

/************************************Turf move procs************************************/

/************************************Area move procs************************************/

/************************************Machinery move procs************************************/

/obj/machinery/door/airlock/beforeShuttleMove(turf/newT, rotation, move_mode, obj/docking_port/mobile/moving_dock)
	. = ..()

	if (cycle_pump)
		INVOKE_ASYNC(cycle_pump, TYPE_PROC_REF(/obj/machinery/atmospherics/components/unary/airlock_pump, undock))

	for(var/obj/machinery/door/airlock/other_airlock in range(2, src))  // includes src, extended because some escape pods have 1 plating turf exposed to space
		other_airlock.shuttledocked = FALSE
		other_airlock.air_tight = TRUE
		if (other_airlock.cycle_pump)
			INVOKE_ASYNC(other_airlock.cycle_pump, TYPE_PROC_REF(/obj/machinery/atmospherics/components/unary/airlock_pump, undock))
			continue
		INVOKE_ASYNC(other_airlock, TYPE_PROC_REF(/obj/machinery/door/, close), FALSE, TRUE) // force crush

/obj/machinery/door/airlock/afterShuttleMove(turf/oldT, list/movement_force, shuttle_dir, shuttle_preferred_direction, move_dir, rotation)
	. = ..()
	var/current_area = get_area(src)
	var/turf/local_turf
	var/tile_air_pressure
	for(var/obj/machinery/door/airlock/other_airlock in orange(2, src))  // does not include src, extended because some escape pods have 1 plating turf exposed to space
		if(get_area(other_airlock) != current_area)  // does not include double-wide airlocks unless actually docked
			// Cycle linking is only disabled if we are actually adjacent to another airlock
			shuttledocked = TRUE
			other_airlock.shuttledocked = TRUE
			if (other_airlock.cycle_pump)
				local_turf = get_step(src, REVERSE_DIR(other_airlock.cycle_pump.dir))
				tile_air_pressure = 0
				if (local_turf)
					tile_air_pressure = max(0, local_turf.return_air().return_pressure())
				INVOKE_ASYNC(other_airlock.cycle_pump, TYPE_PROC_REF(/obj/machinery/atmospherics/components/unary/airlock_pump, on_dock_request), tile_air_pressure)
			// Save external airlocks turf in case our own docking purpouses
			local_turf = get_turf(other_airlock)

	if (cycle_pump)
		tile_air_pressure = 0
		if (local_turf)
			local_turf = get_step(local_turf, REVERSE_DIR(cycle_pump.dir))
			if (local_turf)
				tile_air_pressure = max(0, local_turf.return_air().return_pressure())
			INVOKE_ASYNC(cycle_pump, TYPE_PROC_REF(/obj/machinery/atmospherics/components/unary/airlock_pump, on_dock_request), tile_air_pressure)
		else
			// In case, somebody decides to build an airlock on evac shuttle, we count CentComs blastdoors as valid docking airlock
			local_turf = get_step(src, REVERSE_DIR(cycle_pump.dir))
			if (local_turf)
				for(var/obj/machinery/door/poddoor/shuttledock/centcom_airlock in local_turf)
					// For some reason on docking moment those tiles are vacuum, and pump denies safe_dock attempt
					// To fix this we're lying, that external pressure is nominal
					INVOKE_ASYNC(cycle_pump, TYPE_PROC_REF(/obj/machinery/atmospherics/components/unary/airlock_pump, on_dock_request), ONE_ATMOSPHERE)
					break


/obj/machinery/camera/hypotheticalShuttleMove(rotation, move_mode, obj/docking_port/mobile/moving_dock)
	. = ..()
	if(. & MOVE_AREA)
		. |= MOVE_CONTENTS

/obj/machinery/camera/beforeShuttleMove(turf/newT, rotation, move_mode, obj/docking_port/mobile/moving_dock)
	. = ..()
	if(. & MOVE_AREA)
		. |= MOVE_CONTENTS
		GLOB.cameranet.removeCamera(src)

/obj/machinery/camera/afterShuttleMove(turf/oldT, list/movement_force, shuttle_dir, shuttle_preferred_direction, move_dir, rotation)
	. = ..()
	GLOB.cameranet.addCamera(src)

/obj/machinery/mech_bay_recharge_port/afterShuttleMove(turf/oldT, list/movement_force, shuttle_dir, shuttle_preferred_direction, move_dir)
	. = ..()
	recharging_turf = get_step(loc, dir)

/obj/machinery/computer/auxiliary_base/afterShuttleMove(turf/oldT, list/movement_force, shuttle_dir, shuttle_preferred_direction, move_dir, rotation)
	. = ..()
	if(is_mining_level(z)) //Avoids double logging and landing on other Z-levels due to badminnery
		SSblackbox.record_feedback("associative", "colonies_dropped", 1, list("x" = x, "y" = y, "z" = z))

/obj/machinery/atmospherics/afterShuttleMove(turf/oldT, list/movement_force, shuttle_dir, shuttle_preferred_direction, move_dir, rotation)
	. = ..()
	if(pipe_vision_img)
		pipe_vision_img.loc = loc

	var/missing_nodes = FALSE
	for(var/i in 1 to device_type)
		if(nodes[i])
			var/obj/machinery/atmospherics/node = nodes[i]
			var/connected = FALSE
			for(var/D in GLOB.cardinals)
				if(node in get_step(src, D))
					connected = TRUE
					break

			if(!connected)
				nullify_node(i)

		if(!nodes[i])
			missing_nodes = TRUE

	if(missing_nodes)
		atmos_init()
		for(var/obj/machinery/atmospherics/A in pipeline_expansion())
			A.atmos_init()
			if(A.return_pipenet())
				A.add_member(src)
		SSair.add_to_rebuild_queue(src)
	else
		// atmos_init() calls update_appearance(), so we don't need to call it
		update_appearance()

/obj/machinery/navbeacon/beforeShuttleMove(turf/newT, rotation, move_mode, obj/docking_port/mobile/moving_dock)
	. = ..()
	GLOB.navbeacons["[z]"] -= src
	GLOB.deliverybeacons -= src

/obj/machinery/navbeacon/afterShuttleMove(turf/oldT, list/movement_force, shuttle_dir, shuttle_preferred_direction, move_dir, rotation)
	. = ..()

	if(codes[NAVBEACON_PATROL_MODE])
		if(!GLOB.navbeacons["[z]"])
			GLOB.navbeacons["[z]"] = list()
		GLOB.navbeacons["[z]"] += src //Register with the patrol list!
	if(codes[NAVBEACON_DELIVERY_MODE])
		GLOB.deliverybeacons += src
		GLOB.deliverybeacontags += location

/************************************Mob move procs************************************/

/mob/onShuttleMove(turf/newT, turf/oldT, list/movement_force, move_dir, obj/docking_port/stationary/old_dock, obj/docking_port/mobile/moving_dock)
	if(HAS_TRAIT(src, TRAIT_BLOCK_SHUTTLE_MOVEMENT))
		return
	. = ..()

/mob/afterShuttleMove(turf/oldT, list/movement_force, shuttle_dir, shuttle_preferred_direction, move_dir, rotation)
	if(HAS_TRAIT(src, TRAIT_BLOCK_SHUTTLE_MOVEMENT))
		return
	. = ..()
	if(client && movement_force)
		var/shake_force = max(movement_force["THROW"], movement_force["KNOCKDOWN"])
		if(buckled)
			shake_force *= 0.25
		shake_camera(src, shake_force, 1)

/mob/living/lateShuttleMove(turf/oldT, list/movement_force, move_dir)
	if(buckled)
		return

	. = ..()

	var/knockdown = movement_force["KNOCKDOWN"]
	if(knockdown)
		Paralyze(knockdown)


/mob/living/simple_animal/hostile/megafauna/onShuttleMove(turf/newT, turf/oldT, list/movement_force, move_dir, obj/docking_port/stationary/old_dock, obj/docking_port/mobile/moving_dock)
	. = ..()
	message_admins("Megafauna [src] [ADMIN_FLW(src)] moved via shuttle from [ADMIN_COORDJMP(oldT)] to [ADMIN_COORDJMP(loc)]")

/mob/living/basic/boss/onShuttleMove(turf/newT, turf/oldT, list/movement_force, move_dir, obj/docking_port/stationary/old_dock, obj/docking_port/mobile/moving_dock)
	. = ..()
	message_admins("Megafauna [src] [ADMIN_FLW(src)] moved via shuttle from [ADMIN_COORDJMP(oldT)] to [ADMIN_COORDJMP(loc)]")

/************************************Structure move procs************************************/

/obj/structure/grille/hypotheticalShuttleMove(rotation, move_mode, obj/docking_port/mobile/moving_dock)
	. = ..()
	if(. & MOVE_AREA)
		. |= MOVE_CONTENTS

/obj/structure/grille/beforeShuttleMove(turf/newT, rotation, move_mode, obj/docking_port/mobile/moving_dock)
	. = ..()
	if(. & MOVE_AREA)
		. |= MOVE_CONTENTS

/obj/structure/lattice/hypotheticalShuttleMove(rotation, move_mode, obj/docking_port/mobile/moving_dock)
	. = ..()
	if(. & MOVE_AREA)
		. |= MOVE_CONTENTS

/obj/structure/lattice/beforeShuttleMove(turf/newT, rotation, move_mode, obj/docking_port/mobile/moving_dock)
	. = ..()
	if(. & MOVE_AREA)
		. |= MOVE_CONTENTS

/obj/structure/cable/beforeShuttleMove(turf/newT, rotation, move_mode, obj/docking_port/mobile/moving_dock)
	. = ..()
	cut_cable_from_powernet(FALSE)

/obj/structure/cable/afterShuttleMove(turf/oldT, list/movement_force, shuttle_dir, shuttle_preferred_direction, move_dir, rotation)
	. = ..()
	Connect_cable(TRUE)
	propagate_if_no_network()

/obj/machinery/power/shuttle_engine/hypotheticalShuttleMove(move_mode)
	. = ..()
	if(. & MOVE_AREA)
		. |= MOVE_CONTENTS

/obj/machinery/power/shuttle_engine/beforeShuttleMove(turf/newT, rotation, move_mode, obj/docking_port/mobile/moving_dock)
	. = ..()
	if(. & MOVE_AREA)
		. |= MOVE_CONTENTS

/obj/structure/ladder/beforeShuttleMove(turf/newT, rotation, move_mode, obj/docking_port/mobile/moving_dock)
	. = ..()
	if (!(resistance_flags & INDESTRUCTIBLE))
		disconnect()

/obj/structure/ladder/afterShuttleMove(turf/oldT, list/movement_force, shuttle_dir, shuttle_preferred_direction, move_dir, rotation)
	. = ..()
	if (!(resistance_flags & INDESTRUCTIBLE))
		LateInitialize()

/obj/structure/ladder/onShuttleMove(turf/newT, turf/oldT, list/movement_force, move_dir, obj/docking_port/stationary/old_dock, obj/docking_port/mobile/moving_dock)
	if (resistance_flags & INDESTRUCTIBLE)
		// simply don't be moved
		return FALSE
	return ..()

/************************************Misc move procs************************************/

/obj/docking_port/mobile/hypotheticalShuttleMove(rotation, move_mode, obj/docking_port/mobile/moving_dock)
	. = ..()
	if(moving_dock == src)
		. |= MOVE_CONTENTS

/obj/docking_port/mobile/beforeShuttleMove(turf/newT, rotation, move_mode, obj/docking_port/mobile/moving_dock)
	. = ..()
	if(moving_dock == src)
		. |= MOVE_CONTENTS

// Never move the stationary docking port, otherwise things get WEIRD
/obj/docking_port/stationary/onShuttleMove()
	return FALSE

// Holy shit go away
/obj/effect/abstract/z_holder/onShuttleMove()
	return FALSE

// Special movable stationary port, for your mothership shenanigans
/obj/docking_port/stationary/movable/onShuttleMove(turf/newT, turf/oldT, list/movement_force, move_dir, obj/docking_port/stationary/old_dock, obj/docking_port/mobile/moving_dock)
	if(!moving_dock.can_move_docking_ports || old_dock == src)
		return FALSE

	if(newT == oldT) // In case of in place shuttle rotation shenanigans.
		return

	if(loc != oldT) // This is for multi tile objects
		return

	abstract_move(newT)

	return TRUE

/obj/docking_port/stationary/public_mining_dock/onShuttleMove(turf/newT, turf/oldT, list/movement_force, move_dir, obj/docking_port/stationary/old_dock, obj/docking_port/mobile/moving_dock)
	shuttle_id = "mining_public" //It will not move with the base, but will become enabled as a docking point.
