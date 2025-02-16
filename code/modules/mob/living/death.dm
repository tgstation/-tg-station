/**
 * Blow up the mob into giblets
 *
 * drop_bitflags: (see code/__DEFINES/blood.dm)
 * * DROP_BRAIN - Gibbed mob will drop a brain
 * * DROP_ORGANS - Gibbed mob will drop organs
 * * DROP_BODYPARTS - Gibbed mob will drop bodyparts (arms, legs, etc.)
 * * DROP_ITEMS - Gibbed mob will drop carried items (otherwise they get deleted)
 * * DROP_ALL_REMAINS - Gibbed mob will drop everything
**/
/mob/living/proc/gib(drop_bitflags=NONE)
	var/prev_lying = lying_angle
	spawn_gibs(drop_bitflags)

	if(!prev_lying)
		gib_animation()

	if(stat != DEAD)
		death(TRUE)

	ghostize()
	spill_organs(drop_bitflags)

	if(drop_bitflags & DROP_BODYPARTS)
		spread_bodyparts(drop_bitflags)

	SEND_SIGNAL(src, COMSIG_LIVING_GIBBED, drop_bitflags)
	qdel(src)

// Plays an animation that makes mobs appear to inflate before finally gibbing
/mob/living/proc/inflate_gib(drop_bitflags=DROP_BRAIN|DROP_ORGANS|DROP_ITEMS, gib_time = 2.5 SECONDS, anim_time = 4 SECONDS)
	addtimer(CALLBACK(src, PROC_REF(gib), drop_bitflags), gib_time)
	var/matrix/M = matrix()
	M.Scale(1.8, 1.2)
	animate(src, time = anim_time, transform = M, easing = SINE_EASING)

/mob/living/proc/gib_animation()
	return

/**
 * Spawn bloody gib mess on the floor
 *
 * drop_bitflags: (see code/__DEFINES/blood.dm)
 * * DROP_BODYPARTS - Gibs will spawn with bodypart limbs present
**/
/mob/living/proc/spawn_gibs(drop_bitflags=NONE)
	if(flags_1 & HOLOGRAM_1)
		return
	new /obj/effect/gibspawner/generic(drop_location(), src, get_static_viruses())

/**
 * Drops a mob's organs on the floor
 *
 * drop_bitflags: (see code/__DEFINES/blood.dm)
 * * DROP_BRAIN - Mob will drop a brain
 * * DROP_ORGANS - Mob will drop organs
 * * DROP_BODYPARTS - Mob will drop bodyparts (arms, legs, etc.)
 * * DROP_ALL_REMAINS - Mob will drop everything
**/
/mob/living/proc/spill_organs(drop_bitflags=NONE)
	return

/**
 * Launches all bodyparts away from the mob
 *
 * drop_bitflags: (see code/__DEFINES/blood.dm)
 * * DROP_BRAIN - Detaches the head from the mob and launches it away from the body
**/
/mob/living/proc/spread_bodyparts(drop_bitflags=NONE)
	return

/// Length of the animation in dust_animation.dmi
#define DUST_ANIMATION_TIME 1.3 SECONDS

/**
 * This is the proc for turning an atom into ash.
 * Dusting robots does not eject the MMI, so it's a bit more powerful than gib()
 *
 * Arguments: (Only used for mobs)
 * * just_ash - If TRUE, ash will spawn where the mob was, as opposed to remains
 * * drop_items - Should the mob drop their items before dusting?
 * * force - Should this mob be FORCABLY dusted?
*/
/atom/movable/proc/dust(just_ash, drop_items, force)
	dust_animation()
	// since this is sometimes called in the middle of movement, allow half a second for movement to finish, ghosting to happen and animation to play.
	// Looks much nicer and doesn't cause multiple runtimes.
	QDEL_IN(src, DUST_ANIMATION_TIME)

/mob/living/dust(just_ash, drop_items, force)
	..()
	if(body_position == STANDING_UP)
		// keep us upright so the animation fits.
		ADD_TRAIT(src, TRAIT_FORCED_STANDING, TRAIT_GENERIC)
	death(TRUE)

	if(drop_items)
		unequip_everything()

	if(buckled)
		buckled.unbuckle_mob(src, force = TRUE)

	addtimer(CALLBACK(src, PROC_REF(spawn_dust), just_ash), DUST_ANIMATION_TIME - 0.3 SECONDS)
	ghostize()

/// Animates turning into dust.
/// Does not delete src afterwards, BUT it will become invisible (and grey), so ensure you handle that yourself
/atom/movable/proc/dust_animation(atom/anim_loc = src.loc)
	if(isnull(anim_loc)) // the effect breaks if we have a null loc
		return
	var/obj/effect/temp_visual/dust_animation_filter/dustfx = new(anim_loc, REF(src))
	add_filter("dust_animation", 1, displacement_map_filter(render_source = dustfx.render_target, size = 256))
	add_filter("dust_color", 1, color_matrix_filter())
	transition_filter("dust_color", color_matrix_filter(COLOR_MATRIX_GRAYSCALE), DUST_ANIMATION_TIME - 0.3 SECONDS)
	animate(src, alpha = 0, time = DUST_ANIMATION_TIME - 0.1 SECONDS, easing = SINE_EASING | EASE_IN)

/// Holds the dust animation filter effect, so we can animate it
/obj/effect/temp_visual/dust_animation_filter
	icon = 'icons/mob/dust_animation.dmi'
	icon_state = "dust.1"
	duration = DUST_ANIMATION_TIME
	randomdir = FALSE

/obj/effect/temp_visual/dust_animation_filter/Initialize(mapload, anim_id = "random_default_anti_collision_text")
	. = ..()
	// we manually animate this, rather than just using an animated icon state or flick, to work around byond animated state memes
	// (normally, all animated icon states are synced to the same time, which would bad here)
	for(var/i in 2 to duration)
		if(PERFORM_ALL_TESTS(focus_only/runtime_icon_states) && !icon_exists(icon, "dust.[i]"))
			stack_trace("Missing dust animation icon state: dust.[i]")
		animate(src, time = 1, icon_state = "dust.[i]", flags = ANIMATION_CONTINUE)
	if(PERFORM_ALL_TESTS(focus_only/runtime_icon_states) && icon_exists(icon, "dust.[duration + 1]"))
		stack_trace("Extra dust animation icon state: dust.[duration + 1]")
	render_target = "*dust-[anim_id]"

#undef DUST_ANIMATION_TIME

/**
 * Spawns dust / ash or remains where the mob was
 *
 * just_ash: If TRUE, just ash will spawn where the mob was, as opposed to remains
 */
/mob/living/proc/spawn_dust(just_ash = FALSE)
	var/ash_type = /obj/effect/decal/cleanable/ash
	if(mob_size >= MOB_SIZE_LARGE)
		ash_type = /obj/effect/decal/cleanable/ash/large

	var/obj/effect/decal/cleanable/ash/ash = new ash_type(loc)
	ash.pixel_z = -5
	ash.pixel_w = rand(-1, 1)

/*
 * Called when the mob dies. Can also be called manually to kill a mob.
 *
 * Arguments:
 * * gibbed - Was the mob gibbed?
*/
/mob/living/proc/death(gibbed)
	if(stat == DEAD)
		return FALSE

	if(!gibbed && (death_sound || death_message || (living_flags & ALWAYS_DEATHGASP)))
		INVOKE_ASYNC(src, TYPE_PROC_REF(/mob, emote), "deathgasp")

	set_stat(DEAD)
	timeofdeath = world.time
	station_timestamp_timeofdeath = station_time_timestamp()
	var/turf/death_turf = get_turf(src)
	var/area/death_area = get_area(src)
	// Display a death message if the mob is a player mob (has an active mind)
	var/player_mob_check = mind && mind.name && mind.active
	// and, display a death message if the area allows it (or if they're in nullspace)
	var/valid_area_check = !death_area || !(death_area.area_flags & NO_DEATH_MESSAGE)
	if(player_mob_check)
		if(valid_area_check)
			deadchat_broadcast(" has died at <b>[get_area_name(death_turf)]</b>.", "<b>[mind.name]</b>", follow_target = src, turf_target = death_turf, message_type=DEADCHAT_DEATHRATTLE)
		if(SSlag_switch.measures[DISABLE_DEAD_KEYLOOP] && !client?.holder)
			to_chat(src, span_deadsay(span_big("Observer freelook is disabled.\nPlease use Orbit, Teleport, and Jump to look around.")))
			ghostize(TRUE)
	set_disgust(0)
	SetSleeping(0, 0)
	reset_perspective(null)
	reload_fullscreen()
	update_mob_action_buttons()
	update_damage_hud()
	update_health_hud()
	med_hud_set_health()
	med_hud_set_status()
	stop_pulling()

	SEND_SIGNAL(src, COMSIG_LIVING_DEATH, gibbed)
	SEND_GLOBAL_SIGNAL(COMSIG_GLOB_MOB_DEATH, src, gibbed)

	if (client)
		client.move_delay = initial(client.move_delay)

	persistent_client?.time_of_death = timeofdeath

	return TRUE
