/datum/action/cooldown/mob_cooldown/mook_ability
	///are we a mook?
	var/is_mook = FALSE

/datum/action/cooldown/mob_cooldown/mook_ability/Grant(mob/grant_to)
	. = ..()
	if(isnull(owner))
		return
	is_mook = istype(owner, /mob/living/basic/mining/mook)

/datum/action/cooldown/mob_cooldown/mook_ability/IsAvailable(feedback)
	. = ..()

	if(!.)
		return FALSE

	if(!is_mook)
		return TRUE

	var/mob/living/basic/mining/mook/mook_owner = owner
	if(mook_owner.attack_state != MOOK_ATTACK_NEUTRAL)
		if(feedback)
			mook_owner.balloon_alert(mook_owner, "still recovering!")
		return FALSE
	return TRUE

/datum/action/cooldown/mob_cooldown/mook_ability/mook_leap
	name = "Mook leap"
	desc = "Leap towards the enemy!"
	cooldown_time = 7 SECONDS
	shared_cooldown = NONE
	///telegraph time before jumping
	var/wind_up_time = 2 SECONDS
	///intervals between each of our attacks
	var/attack_interval = 0.4 SECONDS
	///how many times do we attack if we reach the target?
	var/times_to_attack = 4

/datum/action/cooldown/mob_cooldown/mook_ability/mook_leap/Activate(atom/target)
	if(owner.CanReach(target))
		attack_combo(target)
		StartCooldown()
		return TRUE

	if(is_mook)
		var/mob/living/basic/mining/mook/mook_owner = owner
		mook_owner.change_combatant_state(state = MOOK_ATTACK_WARMUP)

	addtimer(CALLBACK(src, PROC_REF(launch_towards_target), target), wind_up_time)
	StartCooldown()
	return TRUE

/datum/action/cooldown/mob_cooldown/mook_ability/mook_leap/proc/launch_towards_target(atom/target)
	new /obj/effect/temp_visual/mook_dust(get_turf(owner))
	playsound(get_turf(owner), 'sound/items/weapons/thudswoosh.ogg', 25, TRUE)
	playsound(owner, 'sound/mobs/non-humanoids/mook/mook_leap_yell.ogg', 100, TRUE)
	var/turf/target_turf = get_turf(target)

	if(!target_turf.is_blocked_turf())
		owner.throw_at(target = target_turf, range = 7, speed = 1, spin = FALSE, callback = CALLBACK(src, PROC_REF(attack_combo), target))
		return

	var/list/open_turfs = list()

	for(var/turf/possible_turf in get_adjacent_open_turfs(target))
		if(possible_turf.is_blocked_turf())
			continue
		open_turfs += possible_turf

	if(!length(open_turfs))
		return

	var/turf/final_turf = get_closest_atom(/turf, open_turfs, owner)
	owner.throw_at(target = final_turf, range = 7, speed = 1, spin = FALSE, callback = CALLBACK(src, PROC_REF(attack_combo), target))

/datum/action/cooldown/mob_cooldown/mook_ability/mook_leap/proc/attack_combo(atom/target)
	if(!owner.CanReach(target))
		return FALSE

	for(var/i in 0 to (times_to_attack - 1))
		addtimer(CALLBACK(src, PROC_REF(attack_target), target), i * attack_interval)

/datum/action/cooldown/mob_cooldown/mook_ability/mook_leap/proc/attack_target(atom/target)
	if(!owner.CanReach(target) || owner.stat == DEAD)
		return
	var/mob/living/basic/basic_owner = owner
	basic_owner.melee_attack(target, ignore_cooldown = TRUE)

/datum/action/cooldown/mob_cooldown/mook_ability/mook_jump
	name = "Mook Jump"
	desc = "Soar high in the air!"
	cooldown_time = 14 SECONDS
	shared_cooldown = NONE
	click_to_activate = FALSE

/datum/action/cooldown/mob_cooldown/mook_ability/mook_jump/Activate(atom/target)
	var/obj/effect/landmark/drop_zone = locate(/obj/effect/landmark/mook_village) in GLOB.landmarks_list
	if(drop_zone?.z == owner.z)
		var/turf/jump_destination = get_turf(drop_zone)
		jump_to_turf(jump_destination)
		StartCooldown()
		return TRUE
	var/list/potential_turfs = list()
	for(var/turf/open_turf in oview(9, owner))
		if(!open_turf.is_blocked_turf())
			potential_turfs += open_turf
	if(!length(potential_turfs))
		return FALSE
	jump_to_turf(pick(potential_turfs))
	StartCooldown()
	return TRUE

/datum/action/cooldown/mob_cooldown/mook_ability/mook_jump/proc/jump_to_turf(turf/target)
	if(is_mook)
		var/mob/living/basic/mining/mook/mook_owner = owner
		mook_owner.change_combatant_state(state = MOOK_ATTACK_ACTIVE)
	new /obj/effect/temp_visual/mook_dust(get_turf(owner))
	playsound(owner, 'sound/items/weapons/thudswoosh.ogg', 50, TRUE)
	animate(owner, pixel_z = 146, time = 0.5 SECONDS, flags = ANIMATION_RELATIVE)
	addtimer(CALLBACK(src, PROC_REF(land_on_turf), target), 0.5 SECONDS)

/datum/action/cooldown/mob_cooldown/mook_ability/mook_jump/proc/land_on_turf(turf/target)
	do_teleport(owner, target, precision = 3,  no_effects = TRUE)
	animate(owner, pixel_z = -146, time = 0.5 SECONDS, flags = ANIMATION_RELATIVE)
	new /obj/effect/temp_visual/mook_dust(get_turf(owner))
	if(is_mook)
		addtimer(CALLBACK(owner, TYPE_PROC_REF(/mob/living/basic/mining/mook, change_combatant_state), MOOK_ATTACK_NEUTRAL), 0.5 SECONDS)

/obj/effect/temp_visual/mook_dust
	name = "dust"
	desc = "It's just a dust cloud!"
	icon = 'icons/mob/simple/jungle/mook.dmi'
	icon_state = "mook_leap_cloud"
	layer = BELOW_MOB_LAYER
	plane = GAME_PLANE
	pixel_x = -16
	pixel_y = -16
	base_pixel_y = -16
	base_pixel_x = -16
	duration = 1 SECONDS

/obj/effect/temp_visual/mook_dust/small

/obj/effect/temp_visual/mook_dust/small/Initialize(mapload)
	. = ..()
	transform = transform.Scale(0.5)
