/// Offsets applied for people riding something
#define RIDING_SOURCE "riding"
/// Offsets applied for something being ridden
#define BEING_RIDDEN_SOURCE "being_ridden"

/**
 * This is the riding component, which is applied to a movable atom by the [ridable element][/datum/element/ridable] when a mob is successfully buckled to said movable.
 *
 * This component lives for as long as at least one mob is buckled to the parent. Once all mobs are unbuckled, the component is deleted, until another mob is buckled in
 * and we make a new riding component, so on and so forth until the sun explodes.
 */


/datum/component/riding
	dupe_mode = COMPONENT_DUPE_UNIQUE

	/// Tick delay between movements, lower = faster, higher = slower
	var/vehicle_move_delay = 2
	/**
	 * If the driver needs a certain item in hand (or inserted, for vehicles) to drive this. For vehicles, this must be duplicated on the actual vehicle object in their
	 * [/obj/vehicle/var/key_type] variable because the vehicle objects still have a few special checks/functions of their own I'm not porting over to the riding component
	 * quite yet. Make sure if you define it on the vehicle, you define it here too.
	 */
	var/keytype
	/// allow typecache for only certain turfs, forbid to allow all but those. allow only certain turfs will take precedence.
	var/list/allowed_turf_typecache
	/// allow typecache for only certain turfs, forbid to allow all but those. allow only certain turfs will take precedence.
	var/list/forbid_turf_typecache
	/// additional traits to add to anyone riding this vehicle
	var/list/rider_traits = list(TRAIT_NO_FLOATING_ANIM)
	/// We don't need roads where we're going if this is TRUE, allow normal movement in space tiles
	var/override_allow_spacemove = FALSE
	/// can anyone other than the rider unbuckle the rider?
	var/can_force_unbuckle = TRUE

	/**
	 * Ride check flags defined for the specific riding component types, so we know if we need arms, legs, or whatever.
	 * Takes additional flags from the ridable element and the buckle proc (buckle_mob_flags) for riding cyborgs/humans in case we need to reserve arms
	 */
	var/ride_check_flags = NONE
	/// For telling someone they can't drive
	COOLDOWN_DECLARE(message_cooldown)
	/// For telling someone they can't drive
	COOLDOWN_DECLARE(vehicle_move_cooldown)


/datum/component/riding/Initialize(mob/living/riding_mob, force = FALSE, buckle_mob_flags = NONE)
	if(!ismovable(parent))
		return COMPONENT_INCOMPATIBLE

	riding_mob.updating_glide_size = FALSE
	ride_check_flags |= buckle_mob_flags

	if(HAS_TRAIT(parent, TRAIT_SPEED_POTIONED))
		vehicle_move_delay = round(CONFIG_GET(number/movedelay/run_delay) * 0.85, 0.01)

/datum/component/riding/RegisterWithParent()
	. = ..()
	RegisterSignal(parent, COMSIG_ATOM_DIR_CHANGE, PROC_REF(vehicle_turned))
	RegisterSignal(parent, COMSIG_MOVABLE_UNBUCKLE, PROC_REF(vehicle_mob_unbuckle))
	RegisterSignal(parent, COMSIG_MOVABLE_BUCKLE, PROC_REF(vehicle_mob_buckle))
	RegisterSignal(parent, COMSIG_MOVABLE_MOVED, PROC_REF(vehicle_moved))
	RegisterSignal(parent, COMSIG_MOVABLE_BUMP, PROC_REF(vehicle_bump))
	RegisterSignal(parent, COMSIG_BUCKLED_CAN_Z_MOVE, PROC_REF(riding_can_z_move))
	RegisterSignals(parent, GLOB.movement_type_addtrait_signals, PROC_REF(on_movement_type_trait_gain))
	RegisterSignals(parent, GLOB.movement_type_removetrait_signals, PROC_REF(on_movement_type_trait_loss))
	RegisterSignal(parent, COMSIG_SUPERMATTER_CONSUMED, PROC_REF(on_entered_supermatter))
	if(!can_force_unbuckle)
		RegisterSignal(parent, COMSIG_ATOM_ATTACK_HAND, PROC_REF(force_unbuckle))

/// This proc is called when a rider unbuckles, whether they chose to or not. If there's no more riders, this will be the riding component's death knell.
/datum/component/riding/proc/vehicle_mob_unbuckle(datum/source, mob/living/rider, force = FALSE)
	SIGNAL_HANDLER

	restore_rider_layer_and_offsets(rider)
	handle_unbuckle(rider)

	var/atom/movable/movable_parent = parent
	if(movable_parent.has_buckled_mobs())
		update_parent_layer_and_offsets(movable_parent.dir, animate = TRUE)
	else
		restore_parent_layer_and_offsets()
		qdel(src)

/datum/component/riding/proc/handle_unbuckle(mob/living/rider)
	unequip_buckle_inhands(rider)
	rider.updating_glide_size = TRUE
	UnregisterSignal(rider, COMSIG_LIVING_TRY_PULL)
	for (var/trait in GLOB.movement_type_trait_to_flag)
		if (HAS_TRAIT(parent, trait))
			REMOVE_TRAIT(rider, trait, REF(src))
	rider.remove_traits(rider_traits, REF(src))

/// This proc is called when a rider buckles, allowing for offsets to be set properly
/datum/component/riding/proc/vehicle_mob_buckle(datum/source, mob/living/rider, force = FALSE)
	SIGNAL_HANDLER

	var/atom/movable/movable_parent = parent
	update_parent_layer_and_offsets(movable_parent.dir, animate = TRUE)
	handle_buckle(rider)

/datum/component/riding/proc/handle_buckle(mob/living/rider)
	if(rider.pulling == parent)
		rider.stop_pulling()
	RegisterSignal(rider, COMSIG_LIVING_TRY_PULL, PROC_REF(on_rider_try_pull))

	for (var/trait in GLOB.movement_type_trait_to_flag)
		if (HAS_TRAIT(parent, trait))
			ADD_TRAIT(rider, trait, REF(src))
	rider.add_traits(rider_traits, REF(src))

/// This proc is called when the rider attempts to grab the thing they're riding, preventing them from doing so.
/datum/component/riding/proc/on_rider_try_pull(mob/living/rider_pulling, atom/movable/target, force)
	SIGNAL_HANDLER
	if(target == parent)
		var/mob/living/ridden = parent
		ridden.balloon_alert(rider_pulling, "not while riding it!")
		return COMSIG_LIVING_CANCEL_PULL

/// This is called after the ridden atom is successfully moved and is used to handle icon stuff
/datum/component/riding/proc/vehicle_moved(datum/source, oldloc, dir, forced)
	SIGNAL_HANDLER

	var/atom/movable/movable_parent = parent
	if (isnull(dir))
		dir = movable_parent.dir
	for (var/m in movable_parent.buckled_mobs)
		var/mob/buckled_mob = m
		ride_check(buckled_mob)
	if(QDELETED(src))
		return // runtimed with piggy's without this, look into this more
	update_parent_layer_and_offsets(dir)

/// Turning is like moving
/datum/component/riding/proc/vehicle_turned(datum/source, _old_dir, new_dir)
	SIGNAL_HANDLER

	vehicle_moved(source, null, new_dir)

/**
 * Check to see if we have all of the necessary bodyparts and not-falling-over statuses we need to stay onboard.
 * If not and if consequences is TRUE, well, there'll be consequences.
 */
/datum/component/riding/proc/ride_check(mob/living/rider, consequences = TRUE)
	return TRUE

#define GET_X_OFFSET(offsets) (length(offsets) >= 1 ? offsets[1] : 0)
#define GET_Y_OFFSET(offsets) (length(offsets) >= 2 ? offsets[2] : 0)
#define GET_LAYER(offsets, default) (length(offsets) >= 3 ? offsets[3] : default)

/datum/component/riding/proc/update_parent_layer_and_offsets(dir, animate = FALSE)
	var/atom/movable/seat = parent
	if(!seat.has_buckled_mobs())
		return

	var/passindex = 0
	for(var/mob/living/buckled_mob as anything in seat.buckled_mobs)
		passindex++
		update_rider_layer_and_offsets(dir, passindex, buckled_mob)

	var/list/offsets = get_parent_offsets_and_layers()?["[dir]"]
	var/px = GET_X_OFFSET(offsets)
	var/py = GET_Y_OFFSET(offsets)
	var/layer = GET_LAYER(offsets, seat.layer)

	if(isliving(seat))
		var/mob/living/living_seat = seat
		living_seat.add_offsets(BEING_RIDDEN_SOURCE, x_add = px, y_add = py, animate = animate)
	else
		seat.pixel_x = px + seat.base_pixel_x
		seat.pixel_y = py + seat.base_pixel_y
	seat.layer = layer

/datum/component/riding/proc/update_rider_layer_and_offsets(dir, passindex, mob/living/rider, animate = FALSE)
	if(rider.dir != dir)
		rider.setDir(dir)

	var/list/diroffsets = get_rider_offsets_and_layers(passindex, rider)?["[dir]"]
	var/x_offset = GET_X_OFFSET(diroffsets)
	var/y_offset = GET_Y_OFFSET(diroffsets)
	var/layer = GET_LAYER(diroffsets, rider.layer)

	// if they are intended to be buckled, offset their existing offset
	var/atom/movable/seat = parent
	if(seat.buckle_lying && rider.body_position == LYING_DOWN)
		y_offset += (-1 * PIXEL_Y_OFFSET_LYING)

	rider.add_offsets(RIDING_SOURCE, x_add = x_offset, y_add = y_offset, animate = animate)
	rider.layer = layer

#undef GET_X_OFFSET
#undef GET_Y_OFFSET
#undef GET_LAYER

/**
 * Determines where riders get offset while riding
 *
 * * pass_index: The index of the rider in the list of buckled mobs
 * * mob/offsetter: The mob that is being offset
 */
/datum/component/riding/proc/get_rider_offsets_and_layers(pass_index, mob/offsetter) as /list // list(dir = x, y, layer)
	RETURN_TYPE(/list)
	return list(
		TEXT_NORTH = list(0, 0),
		TEXT_SOUTH = list(0, 0),
		TEXT_EAST =  list(0, 0),
		TEXT_WEST =  list(0, 0),
	)

/**
 * Determines where the parent gets offset while riders are riding
 */
/datum/component/riding/proc/get_parent_offsets_and_layers() as /list // list(dir = x, y, layer)
	RETURN_TYPE(/list)
	return list(
		TEXT_NORTH = list(0, 0, OBJ_LAYER),
		TEXT_SOUTH = list(0, 0, ABOVE_MOB_LAYER),
		TEXT_EAST =  list(0, 0, ABOVE_MOB_LAYER),
		TEXT_WEST =  list(0, 0, ABOVE_MOB_LAYER),
	)

/**
 * This proc is used to see if we have the appropriate key to drive this atom, if such a key is needed. Returns FALSE if we don't have what we need to drive.
 *
 * Still needs to be neatened up and spruced up with proper OOP, as a result of vehicles having their own key handling from other ridable atoms
 */
/datum/component/riding/proc/keycheck(mob/user)
	if(!keytype)
		return TRUE

	if(isvehicle(parent))
		var/obj/vehicle/vehicle_parent = parent
		return istype(vehicle_parent.inserted_key, keytype)

	return user.is_holding_item_of_type(keytype)

//BUCKLE HOOKS
/datum/component/riding/proc/restore_rider_layer_and_offsets(mob/living/buckled_mob)
	buckled_mob.remove_offsets(RIDING_SOURCE)
	buckled_mob.layer = initial(buckled_mob.layer)
	var/atom/source = parent
	SET_PLANE_EXPLICIT(buckled_mob, initial(buckled_mob.plane), source)
	buckled_mob.client?.view_size.resetToDefault()

/datum/component/riding/proc/restore_parent_layer_and_offsets()
	var/atom/movable/seat = parent
	if(isliving(seat))
		var/mob/living/living_seat = seat
		living_seat.remove_offsets(BEING_RIDDEN_SOURCE)
	else
		seat.pixel_x = seat.base_pixel_x
		seat.pixel_y = seat.base_pixel_y
	seat.layer = initial(seat.layer)

//MOVEMENT
/datum/component/riding/proc/turf_check(turf/next, turf/current)
	if(allowed_turf_typecache && !allowed_turf_typecache[next.type])
		return allowed_turf_typecache[current.type]
	else if(forbid_turf_typecache && forbid_turf_typecache[next.type])
		return !forbid_turf_typecache[current.type]
	return TRUE

/// Every time the driver tries to move, this is called to see if they can actually drive and move the vehicle (via relaymove)
/datum/component/riding/proc/driver_move(atom/movable/movable_parent, mob/living/user, direction)
	SIGNAL_HANDLER
	SHOULD_CALL_PARENT(TRUE)
	movable_parent.set_glide_size(DELAY_TO_GLIDE_SIZE(vehicle_move_delay))

/// So we can check all occupants when we bump a door to see if anyone has access
/datum/component/riding/proc/vehicle_bump(atom/movable/movable_parent, obj/machinery/door/possible_bumped_door)
	SIGNAL_HANDLER
	if(!istype(possible_bumped_door))
		return
	for(var/occupant in movable_parent.buckled_mobs)
		INVOKE_ASYNC(possible_bumped_door, TYPE_PROC_REF(/obj/machinery/door/, bumpopen), occupant)

/datum/component/riding/proc/Unbuckle(atom/movable/M)
	addtimer(CALLBACK(parent, TYPE_PROC_REF(/atom/movable/, unbuckle_mob), M), 0, TIMER_UNIQUE)

/datum/component/riding/proc/Process_Spacemove(direction, continuous_move)
	var/atom/movable/AM = parent
	return override_allow_spacemove || AM.has_gravity()

/// currently replicated from ridable because we need this behavior here too, see if we can deal with that
/datum/component/riding/proc/unequip_buckle_inhands(mob/living/carbon/user)
	var/atom/movable/AM = parent
	for(var/obj/item/riding_offhand/O in user.contents)
		if(O.parent != AM)
			CRASH("RIDING OFFHAND ON WRONG MOB")
		if(O.selfdeleting)
			continue
		else
			qdel(O)
	return TRUE

/// Extra checks before buckled.can_z_move can be called in mob/living/can_z_move()
/datum/component/riding/proc/riding_can_z_move(atom/movable/movable_parent, direction, turf/start, turf/destination, z_move_flags, mob/living/rider)
	SIGNAL_HANDLER
	return COMPONENT_RIDDEN_ALLOW_Z_MOVE

/// Called when our vehicle gains a movement trait, so we can apply it to the riders
/datum/component/riding/proc/on_movement_type_trait_gain(atom/movable/source, trait)
	SIGNAL_HANDLER
	var/atom/movable/movable_parent = parent
	for (var/mob/rider in movable_parent.buckled_mobs)
		ADD_TRAIT(rider, trait, REF(src))

/// Called when our vehicle loses a movement trait, so we can remove it from the riders
/datum/component/riding/proc/on_movement_type_trait_loss(atom/movable/source, trait)
	SIGNAL_HANDLER
	var/atom/movable/movable_parent = parent
	for (var/mob/rider in movable_parent.buckled_mobs)
		REMOVE_TRAIT(rider, trait, REF(src))

/datum/component/riding/proc/force_unbuckle(atom/movable/source, mob/living/living_hitter)
	SIGNAL_HANDLER

	if((living_hitter in source.buckled_mobs))
		return
	return COMPONENT_CANCEL_ATTACK_CHAIN

/// When we touch a crystal, kill everything inside us
/datum/component/riding/proc/on_entered_supermatter(atom/movable/ridden, atom/movable/supermatter)
	SIGNAL_HANDLER
	for (var/mob/passenger as anything in ridden.buckled_mobs)
		passenger.Bump(supermatter)

#undef RIDING_SOURCE
#undef BEING_RIDDEN_SOURCE
