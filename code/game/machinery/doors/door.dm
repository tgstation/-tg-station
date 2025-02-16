#define DOOR_CLOSE_WAIT 60 ///Default wait until doors autoclose
/obj/machinery/door
	name = "door"
	desc = "It opens and closes."
	icon = 'icons/obj/doors/doorint.dmi'
	icon_state = "door_closed"
	base_icon_state = "door"
	opacity = TRUE
	density = TRUE
	move_resist = MOVE_FORCE_VERY_STRONG
	layer = OPEN_DOOR_LAYER
	power_channel = AREA_USAGE_ENVIRON
	pass_flags_self = PASSDOORS
	max_integrity = 350
	armor_type = /datum/armor/machinery_door
	can_atmos_pass = ATMOS_PASS_DENSITY
	flags_1 = PREVENT_CLICK_UNDER_1
	receive_ricochet_chance_mod = 0.8
	damage_deflection = 10

	interaction_flags_atom = INTERACT_ATOM_UI_INTERACT
	blocks_emissive = EMISSIVE_BLOCK_UNIQUE

	idle_power_usage = BASE_MACHINE_IDLE_CONSUMPTION * 0.1
	active_power_usage = BASE_MACHINE_ACTIVE_CONSUMPTION * 0.2

	/// The animation we're currently playing, if any
	var/animation
	var/visible = TRUE
	var/operating = FALSE
	var/glass = FALSE
	/// If something isn't a glass door but doesn't have a fill_closed icon (no glass slots), this prevents it from being used
	var/can_be_glass = TRUE
	/// Do we need to keep track of a filler panel with the airlock
	var/multi_tile
	/// A filler object used to fill the space of multi-tile airlocks
	var/obj/structure/fluff/airlock_filler/filler
	var/welded = FALSE
	///Whether this door has a panel or not; FALSE also stops the examine blurb about the panel from showing up
	var/has_access_panel = TRUE
	/// For rglass-windowed airlocks and firedoors
	var/heat_proof = FALSE
	/// Emergency access override
	var/emergency = FALSE
	/// true if it's meant to go under another door.
	var/sub_door = FALSE
	var/closingLayer = CLOSED_DOOR_LAYER
	///does it automatically close after some time
	var/autoclose = FALSE
	///whether the door detects things and mobs in its way and reopen or crushes them.
	var/safe = TRUE
	///whether the door is bolted or not.
	var/locked = FALSE
	var/datum/effect_system/spark_spread/spark_system
	///ignore this, just use explosion_block
	var/real_explosion_block
	///if TRUE, this door will always open on red alert
	var/red_alert_access = FALSE
	/// Checks to see if this airlock has an unrestricted "sensor" within (will set to TRUE if present).
	var/unres_sensor = FALSE
	/// Unrestricted sides. A bitflag for which direction (if any) can open the door with no access
	var/unres_sides = NONE
	/// Whether or not the door can crush mobs.
	var/can_crush = TRUE
	/// Whether or not the door can be opened by hand (used for blast doors and shutters)
	var/can_open_with_hands = TRUE
	/// Whether or not this door can be opened through a door remote, ever
	var/opens_with_door_remote = FALSE
	/// Special operating mode for elevator doors
	var/elevator_mode = FALSE
	/// Current elevator status for processing
	var/elevator_status
	/// What specific lift ID do we link with?
	var/transport_linked_id

/datum/armor/machinery_door
	melee = 30
	bullet = 30
	laser = 20
	energy = 20
	bomb = 10
	fire = 80
	acid = 70

/obj/machinery/door/Initialize(mapload)
	AddElement(/datum/element/blocks_explosives)
	. = ..()
	set_init_door_layer()
	if(multi_tile)
		set_bounds()
		set_filler()
		update_overlays()
	update_freelook_sight()
	air_update_turf(TRUE, TRUE)
	register_context()
	if(elevator_mode)
		if(transport_linked_id)
			elevator_status = LIFT_PLATFORM_LOCKED
			GLOB.elevator_doors += src
		else
			stack_trace("Elevator door [src] ([x],[y],[z]) has no linked elevator ID!")
	spark_system = new /datum/effect_system/spark_spread
	spark_system.set_up(2, 1, src)
	if(density)
		flags_1 |= PREVENT_CLICK_UNDER_1
	else
		flags_1 &= ~PREVENT_CLICK_UNDER_1

	if(glass)
		passwindow_on(src, INNATE_TRAIT)
	//doors only block while dense though so we have to use the proc
	real_explosion_block = explosion_block
	update_explosive_block()
	RegisterSignal(SSsecurity_level, COMSIG_SECURITY_LEVEL_CHANGED, PROC_REF(check_security_level))

	var/static/list/loc_connections = list(
		COMSIG_ATOM_MAGICALLY_UNLOCKED = PROC_REF(on_magic_unlock),
	)
	AddElement(/datum/element/connect_loc, loc_connections)
	AddElement(/datum/element/can_barricade)

/obj/machinery/door/examine(mob/user)
	. = ..()
	if(red_alert_access)
		if(SSsecurity_level.get_current_level_as_number() >= SEC_LEVEL_RED)
			. += span_notice("Due to a security threat, its access requirements have been lifted!")
		else
			. += span_notice("In the event of a red alert, its access requirements will automatically lift.")
	if(has_access_panel)
		. += span_notice("Its maintenance panel is [panel_open ? "open" : "<b>screwed</b> in place"].")

/obj/machinery/door/add_context(atom/source, list/context, obj/item/held_item, mob/user)
	. = ..()

	if(!can_open_with_hands)
		return .

	if(isaicamera(user) || HAS_SILICON_ACCESS(user))
		return .

	if(isnull(held_item) && Adjacent(user))
		context[SCREENTIP_CONTEXT_LMB] = "Open"
		return CONTEXTUAL_SCREENTIP_SET

/obj/machinery/door/check_access_list(list/access_list)
	if(red_alert_access && SSsecurity_level.get_current_level_as_number() >= SEC_LEVEL_RED)
		return TRUE
	return ..()

/obj/machinery/door/proc/set_init_door_layer()
	if(density)
		layer = closingLayer
	else
		layer = initial(layer)

/obj/machinery/door/Destroy()
	update_freelook_sight()
	if(elevator_mode)
		GLOB.elevator_doors -= src
	if(spark_system)
		qdel(spark_system)
		spark_system = null
	QDEL_NULL(filler)
	air_update_turf(TRUE, FALSE)
	return ..()

/obj/machinery/door/Move()
	if(multi_tile)
		set_filler()
	return ..()

/**
 * Sets the bounds of the airlock. For use with multi-tile airlocks.
 * If the airlock is multi-tile, it will set the bounds to be the size of the airlock.
 * If the airlock doesn't already have a filler object, it will create one.
 * If the airlock already has a filler object, it will move it to the correct location.
 */
/obj/machinery/door/proc/set_filler()
	if(!multi_tile)
		return
	if(!filler)
		filler = new(get_step(src, get_adjusted_dir(dir)))
		filler.pair_airlock(src)
	else
		filler.loc = get_step(src, get_adjusted_dir(dir))

	filler.density = density
	filler.set_opacity(opacity)

/**
 * Checks which way the airlock is facing and adjusts the direction accordingly.
 * For use with multi-tile airlocks.
 *
 * @param dir direction to adjust
 * @return adjusted direction
 */
/obj/machinery/door/proc/get_adjusted_dir(dir)
	if(dir in list(NORTH, SOUTH))
		return EAST
	else
		return NORTH

/**
 * Signal handler for checking if we notify our surrounding that access requirements are lifted accordingly to a newly set security level
 *
 * Arguments:
 * * source The datum source of the signal
 * * new_level The new security level that is in effect
 */
/obj/machinery/door/proc/check_security_level(datum/source, new_level)
	SIGNAL_HANDLER

	if(new_level <= SEC_LEVEL_BLUE)
		return
	if(!red_alert_access)
		return
	audible_message(span_notice("[src] whirr[p_s()] as [p_they()] automatically lift[p_s()] access requirements!"))
	playsound(src, 'sound/machines/airlock/boltsup.ogg', 50, TRUE)

/obj/machinery/door/proc/try_safety_unlock(mob/user)
	return FALSE

/**
 * Called when attempting to remove the seal from an airlock
 *
 * Here because we need to call it and return if there was a seal so we don't try to open the door
 * or try its safety lock while it's sealed
 * Arguments:
 * * user - the mob attempting to remove the seal
 */
/obj/machinery/door/proc/try_remove_seal(mob/user)
	return

/obj/machinery/door/Bumped(atom/movable/AM)
	. = ..()
	if(operating || (obj_flags & EMAGGED) || (!can_open_with_hands && density))
		return
	if(ismob(AM))
		var/mob/B = AM
		if((isdrone(B) || iscyborg(B)) && B.stat)
			return
		if(isliving(AM))
			var/mob/living/M = AM
			//Can bump-open maybe 3 airlocks per second. This is to prevent weird mass door openings
			//While keeping things feeling snappy
			if(world.time - M.last_bumped <= 0.3 SECONDS)
				return
			M.last_bumped = world.time
			if(HAS_TRAIT(M, TRAIT_HANDS_BLOCKED) && !check_access(null) && !emergency)
				return
			if(try_safety_unlock(M))
				return
			bumpopen(M)
			return
		return

	if(isitem(AM))
		var/obj/item/I = AM
		if(!density || (I.w_class < WEIGHT_CLASS_NORMAL && !LAZYLEN(I.GetAccess())))
			return
		if(requiresID() && check_access(I))
			open()
		else
			run_animation(DOOR_DENY_ANIMATION)
		return

/obj/machinery/door/Move()
	var/turf/T = loc
	. = ..()
	if(density) //Gotta be closed my friend
		move_update_air(T)

/obj/machinery/door/CanAllowThrough(atom/movable/mover, border_dir)
	. = ..()
	if(.)
		return
	// Snowflake handling for PASSGLASS.
	if(istype(mover) && (mover.pass_flags & PASSGLASS))
		return !opacity

/obj/machinery/door/proc/bumpopen(mob/user)
	if(operating || !can_open_with_hands)
		return

	add_fingerprint(user)
	if(!density || (obj_flags & EMAGGED))
		return

	if(elevator_mode && elevator_status == LIFT_PLATFORM_UNLOCKED)
		open()
	else if(requiresID() && allowed(user))
		open()
	else
		run_animation(DOOR_DENY_ANIMATION)

/obj/machinery/door/attack_hand(mob/user, list/modifiers)
	. = ..()
	if(.)
		return
	if(try_remove_seal(user))
		return
	if(try_safety_unlock(user))
		return
	return try_to_activate_door(user)

/obj/machinery/door/attack_tk(mob/user)
	if(requiresID() && !allowed(null))
		return
	return ..()

/obj/machinery/door/proc/try_to_activate_door(mob/user, access_bypass = FALSE)
	add_fingerprint(user)
	if(operating || (obj_flags & EMAGGED) || !can_open_with_hands)
		return
	if(access_bypass || (requiresID() && allowed(user)))
		if(density)
			open()
		else
			close()
		return TRUE
	if(density)
		run_animation(DOOR_DENY_ANIMATION)

/obj/machinery/door/allowed(mob/M)
	if(emergency)
		return TRUE
	if(unrestricted_side(M))
		return TRUE
	return ..()

/obj/machinery/door/proc/unrestricted_side(mob/opener) //Allows for specific side of airlocks to be unrestrected (IE, can exit maint freely, but need access to enter)
	return get_dir(src, opener) & unres_sides

/obj/machinery/door/proc/try_to_weld(obj/item/weldingtool/W, mob/user)
	return

/// Called when the user right-clicks on the door with a welding tool.
/obj/machinery/door/proc/try_to_weld_secondary(obj/item/weldingtool/tool, mob/user)
	return


/obj/machinery/door/proc/try_to_crowbar(obj/item/acting_object, mob/user, forced = FALSE)
	return

/// Called when the user right-clicks on the door with a crowbar.
/obj/machinery/door/proc/try_to_crowbar_secondary(obj/item/acting_object, mob/user)
	return

/obj/machinery/door/welder_act(mob/living/user, obj/item/tool)
	try_to_weld(tool, user)
	return ITEM_INTERACT_SUCCESS

/obj/machinery/door/crowbar_act(mob/living/user, obj/item/tool)
	if(user.combat_mode)
		return

	var/forced_open = FALSE
	if(istype(tool, /obj/item/crowbar))
		var/obj/item/crowbar/crowbar = tool
		forced_open = crowbar.force_opens
	try_to_crowbar(tool, user, forced_open)
	return ITEM_INTERACT_SUCCESS

/obj/machinery/door/attackby(obj/item/weapon, mob/living/user, params)
	if(istype(weapon, /obj/item/access_key))
		var/obj/item/access_key/key = weapon
		return key.attempt_open_door(user, src)
	else if(!user.combat_mode && istype(weapon, /obj/item/fireaxe))
		try_to_crowbar(weapon, user, FALSE)
		return TRUE
	else if(weapon.item_flags & NOBLUDGEON || user.combat_mode)
		return ..()
	else if(!user.combat_mode && istype(weapon, /obj/item/stack/sheet/mineral/wood))
		return ..() // we need this so our can_barricade element can be called using COMSIG_ATOM_ATTACKBY
	else if(try_to_activate_door(user))
		return TRUE
	return ..()

/obj/machinery/door/item_interaction_secondary(mob/living/user, obj/item/tool, list/modifiers)
	// allows you to crowbar doors while in combat mode
	if(user.combat_mode && tool.tool_behaviour == TOOL_CROWBAR)
		return crowbar_act_secondary(user, tool)
	return ..()

/obj/machinery/door/welder_act_secondary(mob/living/user, obj/item/tool)
	try_to_weld_secondary(tool, user)
	return ITEM_INTERACT_SUCCESS

/obj/machinery/door/crowbar_act_secondary(mob/living/user, obj/item/tool)
	var/forced_open = FALSE
	if(istype(tool, /obj/item/crowbar))
		var/obj/item/crowbar/crowbar = tool
		forced_open = crowbar.force_opens
	try_to_crowbar_secondary(tool, user, forced_open)
	return ITEM_INTERACT_SUCCESS

/obj/machinery/door/take_damage(damage_amount, damage_type = BRUTE, damage_flag = 0, sound_effect = 1, attack_dir)
	. = ..()
	if(. && atom_integrity > 0)
		if(damage_amount >= 10 && prob(30))
			spark_system.start()

/obj/machinery/door/play_attack_sound(damage_amount, damage_type = BRUTE, damage_flag = 0)
	switch(damage_type)
		if(BRUTE)
			if(glass)
				playsound(loc, 'sound/effects/glass/glasshit.ogg', 90, TRUE)
			else if(damage_amount)
				playsound(loc, 'sound/items/weapons/smash.ogg', 50, TRUE)
			else
				playsound(src, 'sound/items/weapons/tap.ogg', 50, TRUE)
		if(BURN)
			playsound(src.loc, 'sound/items/tools/welder.ogg', 100, TRUE)

/obj/machinery/door/emp_act(severity)
	. = ..()
	if (. & EMP_PROTECT_SELF)
		return
	if(prob(20/severity) && (istype(src, /obj/machinery/door/airlock) || istype(src, /obj/machinery/door/window)) )
		INVOKE_ASYNC(src, PROC_REF(open))

/obj/machinery/door/update_icon_state()
	. = ..()
	switch(animation)
		if(DOOR_OPENING_ANIMATION)
			if(panel_open)
				icon_state = "o_door_opening"
			else
				icon_state = "door_opening"
		if(DOOR_CLOSING_ANIMATION)
			if(panel_open)
				icon_state = "o_door_closing"
			else
				icon_state = "door_closing"
		if(DOOR_DENY_ANIMATION)
			if(!machine_stat)
				icon_state = "door_deny"
		else
			icon_state = "[base_icon_state]_[density ? "closed" : "open"]"

/obj/machinery/door/update_overlays()
	. = ..()
	if(panel_open)
		. += mutable_appearance(icon, "panel_open")

/// Returns the delay to use for the passed in animation
/// We'll do our cleanup once the delay runs out
/obj/machinery/door/proc/animation_length(animation)
	switch(animation)
		if(DOOR_OPENING_ANIMATION)
			return 0.6 SECONDS
		if(DOOR_CLOSING_ANIMATION)
			return 0.6 SECONDS
		if(DOOR_DENY_ANIMATION)
			return 0.3 SECONDS

/// Returns the time required to hit particular points in an animation
/// Used to manage delays for opening/closing and such
/obj/machinery/door/proc/animation_segment_delay(animation)
	switch(animation)
		if(DOOR_OPENING_PASSABLE)
			return 0.5 SECONDS
		if(DOOR_OPENING_FINISHED)
			return 0.6 SECONDS
		if(DOOR_CLOSING_UNPASSABLE)
			return 0.2 SECONDS
		if(DOOR_CLOSING_FINISHED)
			return 0.6 SECONDS

/// Override this to do misc tasks on animation start
/obj/machinery/door/proc/animation_effects(animation)
	return

/// Used to start a new animation
/// Accepts the animation to start as an arg
/obj/machinery/door/proc/run_animation(animation)
	set_animation(animation)
	addtimer(CALLBACK(src, PROC_REF(set_animation), null), animation_length(animation), TIMER_UNIQUE|TIMER_OVERRIDE)
	animation_effects(animation)

// React to our animation changing
/obj/machinery/door/proc/set_animation(animation)
	src.animation = animation
	update_appearance()

/// Public proc that simply handles opening the door. Returns TRUE if the door was opened, FALSE otherwise.
/// Use argument "forced" in conjunction with try_to_force_door_open if you want/need additional checks depending on how sorely you need the door opened.
/obj/machinery/door/proc/open(forced = DEFAULT_DOOR_CHECKS)
	if(!density)
		return TRUE
	if(operating)
		return FALSE
	operating = TRUE
	use_energy(active_power_usage)
	run_animation(DOOR_OPENING_ANIMATION)
	set_opacity(0)
	var/passable_delay = animation_segment_delay(DOOR_OPENING_PASSABLE)
	SLEEP_NOT_DEL(passable_delay)
	set_density(FALSE)
	flags_1 &= ~PREVENT_CLICK_UNDER_1
	var/open_delay = animation_segment_delay(DOOR_OPENING_FINISHED) - passable_delay
	SLEEP_NOT_DEL(open_delay)
	layer = initial(layer)
	update_appearance()
	set_opacity(0)
	operating = FALSE
	air_update_turf(TRUE, FALSE)
	update_freelook_sight()
	if(autoclose)
		autoclose_in(DOOR_CLOSE_WAIT)
	return TRUE

/// Private proc that runs a series of checks to see if we should forcibly open the door. Returns TRUE if we should open the door, FALSE otherwise. Implemented in child types.
/// In case a specific behavior isn't covered, we should default to TRUE just to be safe (simply put, this proc should have an explicit reason to return FALSE).
/obj/machinery/door/proc/try_to_force_door_open(force_type = DEFAULT_DOOR_CHECKS)
	return TRUE // the base "door" can always be forced open since there's no power or anything like emagging it to prevent an open, not even invoked on the base type anyways.

/// Public proc that simply handles closing the door. Returns TRUE if the door was closed, FALSE otherwise.
/// Use argument "forced" in conjuction with try_to_force_door_shut if you want/need additional checks depending on how sorely you need the door closed.
/obj/machinery/door/proc/close(forced = DEFAULT_DOOR_CHECKS)
	if(density)
		return TRUE
	if(operating || welded)
		return FALSE
	if(safe)
		for(var/atom/movable/M in get_turf(src))
			if(M.density && M != src) //something is blocking the door
				if(autoclose)
					autoclose_in(DOOR_CLOSE_WAIT)
				return FALSE

	operating = TRUE

	run_animation(DOOR_CLOSING_ANIMATION)
	layer = closingLayer
	var/unpassable_delay = animation_segment_delay(DOOR_CLOSING_UNPASSABLE)
	SLEEP_NOT_DEL(unpassable_delay)
	set_density(TRUE)
	flags_1 |= PREVENT_CLICK_UNDER_1
	var/close_delay = animation_segment_delay(DOOR_CLOSING_FINISHED) - unpassable_delay
	SLEEP_NOT_DEL(close_delay)
	update_appearance()
	if(visible && !glass)
		set_opacity(1)
	operating = FALSE
	air_update_turf(TRUE, TRUE)
	update_freelook_sight()

	if(!can_crush)
		return TRUE

	if(safe)
		CheckForMobs()
	else
		crush()
	return TRUE

/// Private proc that runs a series of checks to see if we should forcibly shut the door. Returns TRUE if we should shut the door, FALSE otherwise. Implemented in child types.
/// In case a specific behavior isn't covered, we should default to TRUE just to be safe (simply put, this proc should have an explicit reason to return FALSE).
/obj/machinery/door/proc/try_to_force_door_shut(force_type = DEFAULT_DOOR_CHECKS)
	return TRUE // the base "door" can always be forced shut

/obj/machinery/door/proc/CheckForMobs()
	if(locate(/mob/living) in get_turf(src))
		sleep(0.1 SECONDS)
		open()

/obj/machinery/door/proc/crush()
	for(var/turf/checked_turf in locs)
		for(var/mob/living/future_pancake in checked_turf)
			future_pancake.visible_message(span_warning("[src] closes on [future_pancake], crushing [future_pancake.p_them()]!"), span_userdanger("[src] closes on you and crushes you!"))
			SEND_SIGNAL(future_pancake, COMSIG_LIVING_DOORCRUSHED, src)
			if(isalien(future_pancake))  //For xenos
				future_pancake.adjustBruteLoss(DOOR_CRUSH_DAMAGE * 1.5) //Xenos go into crit after aproximately the same amount of crushes as humans.
				future_pancake.emote("roar")
			else if(ismonkey(future_pancake)) //For monkeys
				future_pancake.emote("screech")
				future_pancake.adjustBruteLoss(DOOR_CRUSH_DAMAGE)
				future_pancake.Paralyze(100)
			else if(ishuman(future_pancake)) //For humans
				future_pancake.adjustBruteLoss(DOOR_CRUSH_DAMAGE)
				future_pancake.emote("scream")
				future_pancake.Paralyze(100)
			else //for simple_animals & borgs
				future_pancake.adjustBruteLoss(DOOR_CRUSH_DAMAGE)
				var/turf/location = get_turf(src)
				//add_blood doesn't work for borgs/xenos, but add_blood_floor does.
				future_pancake.add_splatter_floor(location)
				log_combat(src, future_pancake, "crushed")
		for(var/obj/vehicle/sealed/mecha/mech in get_turf(src)) // Your fancy metal won't save you here!
			mech.take_damage(DOOR_CRUSH_DAMAGE)
			log_combat(src, mech, "crushed")

/obj/machinery/door/proc/autoclose()
	if(!QDELETED(src) && !density && !operating && !locked && !welded && autoclose)
		close()

/obj/machinery/door/proc/autoclose_in(wait)
	addtimer(CALLBACK(src, PROC_REF(autoclose)), wait, TIMER_UNIQUE | TIMER_NO_HASH_WAIT | TIMER_OVERRIDE)

/obj/machinery/door/proc/requiresID()
	return 1

/obj/machinery/door/proc/hasPower()
	return !(machine_stat & NOPOWER)

/obj/machinery/door/proc/update_freelook_sight()
	if(!glass && GLOB.cameranet)
		GLOB.cameranet.updateVisibility(src, 0)

/obj/machinery/door/block_superconductivity() // All non-glass airlocks block heat, this is intended.
	if(opacity || heat_proof)
		return 1
	return 0

/obj/machinery/door/morgue
	icon = 'icons/obj/doors/doormorgue.dmi'

/obj/machinery/door/morgue/Initialize(mapload)
	. = ..()
	AddComponent(/datum/component/redirect_attack_hand_from_turf)

/obj/machinery/door/get_dumping_location()
	return null

/obj/machinery/door/morgue/animation_length(animation)
	switch(animation)
		if(DOOR_OPENING_ANIMATION)
			return 1.5 SECONDS
		if(DOOR_CLOSING_ANIMATION)
			return 1.5 SECONDS
		if(DOOR_DENY_ANIMATION)
			return 0.1 SECONDS

/obj/machinery/door/morgue/animation_segment_delay(animation)
	switch(animation)
		if(DOOR_OPENING_PASSABLE)
			return 1.4 SECONDS
		if(DOOR_OPENING_FINISHED)
			return 1.5 SECONDS
		if(DOOR_CLOSING_UNPASSABLE)
			return 0.2 SECONDS
		if(DOOR_CLOSING_FINISHED)
			return 1.5 SECONDS

/obj/machinery/door/proc/lock()
	return

/obj/machinery/door/proc/unlock()
	return

/obj/machinery/door/proc/hostile_lockdown(mob/origin)
	if(!machine_stat) //So that only powered doors are closed.
		close() //Close ALL the doors!

/obj/machinery/door/proc/disable_lockdown()
	if(!machine_stat) //Opens only powered doors.
		open() //Open everything!

/obj/machinery/door/ex_act(severity, target)
	//if it blows up a wall it should blow up a door
	return ..(severity ? min(EXPLODE_DEVASTATE, severity + 1) : EXPLODE_NONE, target)

/obj/machinery/door/power_change()
	. = ..()
	if(. && !(machine_stat & NOPOWER))
		autoclose_in(DOOR_CLOSE_WAIT)

/obj/machinery/door/zap_act(power, zap_flags)
	zap_flags &= ~ZAP_OBJ_DAMAGE
	. = ..()

/// Signal proc for [COMSIG_ATOM_MAGICALLY_UNLOCKED]. Open up when someone casts knock.
/obj/machinery/door/proc/on_magic_unlock(datum/source, datum/action/cooldown/spell/aoe/knock/spell, atom/caster)
	SIGNAL_HANDLER

	INVOKE_ASYNC(src, PROC_REF(open))

/obj/machinery/door/set_density(new_value)
	. = ..()
	update_explosive_block()

/obj/machinery/door/proc/update_explosive_block()
	set_explosion_block(real_explosion_block)

// Kinda roundabout, essentially if we're dense, we respect real_explosion_block
// Otherwise, we block nothing
/obj/machinery/door/set_explosion_block(explosion_block)
	real_explosion_block = explosion_block
	if(density)
		return ..()
	return ..(0)

#undef DOOR_CLOSE_WAIT
