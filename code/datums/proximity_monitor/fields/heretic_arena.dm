GLOBAL_LIST_EMPTY(heretic_arenas)

// Invisible effect that doesnt exist outside of containing the prox monitor
/obj/effect/abstract/heretic_arena
	icon = null
	icon_state = null
	alpha = 0
	invisibility = INVISIBILITY_ABSTRACT
	mouse_opacity = MOUSE_OPACITY_TRANSPARENT
	anchored = TRUE
	resistance_flags = INDESTRUCTIBLE
	/// Proximity monitor that handles the effects we are looking for
	var/datum/proximity_monitor/advanced/heretic_arena/arena

/obj/effect/abstract/heretic_arena/Initialize(mapload, range, duration, caster)
	. = ..()
	arena = new(src, range)
	QDEL_IN(src, duration)
	arena.set_caster(caster)
	GLOB.heretic_arenas += src

/obj/effect/abstract/heretic_arena/Destroy(force)
	QDEL_NULL(arena)
	GLOB.heretic_arenas -= src
	. = ..()

/datum/proximity_monitor/advanced/heretic_arena
	/// Reference to the caster, the spell collapses if they leave the arena
	var/arena_caster
	/// List of mobs inside our arena
	var/list/contained_mobs = list()
	/// List of border walls we have placed on the edges of the monitor
	var/list/border_walls = list()
	/// List of blades we've so generously handed out to the participants
	var/list/welfare_blades = list()
	/// List of immunities given to our combatants
	var/static/list/given_immunities = list(
		TRAIT_BOMBIMMUNE,
		TRAIT_IGNORESLOWDOWN,
		TRAIT_NO_SLIP_ALL,
		TRAIT_NOBREATH,
		TRAIT_PIERCEIMMUNE,
		TRAIT_PUSHIMMUNE,
		TRAIT_RADIMMUNE,
		TRAIT_RESISTCOLD,
		TRAIT_RESISTHEAT,
		TRAIT_RESISTHIGHPRESSURE,
		TRAIT_RESISTLOWPRESSURE,
		TRAIT_SHOCKIMMUNE,
		TRAIT_SLEEPIMMUNE,
		TRAIT_STUNIMMUNE,
		TRAIT_FORCED_GRAVITY,
	)

/datum/proximity_monitor/advanced/heretic_arena/New(atom/_host, range, _ignore_if_not_on_turf)
	. = ..()
	recalculate_field(full_recalc = TRUE)
	var/list/things_in_range = range(range)
	for(var/mob/living/carbon/human/human_in_range in things_in_range)
		human_in_range.add_traits(given_immunities, HERETIC_ARENA_TRAIT)
		contained_mobs += human_in_range
		if(!IS_HERETIC(human_in_range))
			var/obj/item/melee/sickly_blade/training/new_blade = new(get_turf(human_in_range))
			welfare_blades += new_blade
			INVOKE_ASYNC(human_in_range, TYPE_PROC_REF(/mob, put_in_hands), new_blade)
			human_in_range.mind?.add_antag_datum(/datum/antagonist/heretic_arena_participant)
		human_in_range.apply_status_effect(/datum/status_effect/arena_tracker)
		RegisterSignal(human_in_range, COMSIG_CAN_Z_MOVE, PROC_REF(on_try_z_move))
		RegisterSignal(human_in_range, COMSIG_LADDER_TRAVEL, PROC_REF(on_try_ladder))
		RegisterSignal(human_in_range, COMSIG_MOVABLE_PRE_MOVE, PROC_REF(on_pre_move))
		RegisterSignal(human_in_range, COMSIG_MOVABLE_POST_TELEPORT, PROC_REF(on_teleport))

/datum/proximity_monitor/advanced/heretic_arena/Destroy()
	for(var/mob/living/carbon/human/mob in contained_mobs)
		mob.remove_traits(given_immunities, HERETIC_ARENA_TRAIT)
		mob.remove_status_effect(/datum/status_effect/arena_tracker)
		UnregisterSignal(mob, list(COMSIG_CAN_Z_MOVE, COMSIG_LADDER_TRAVEL, COMSIG_MOVABLE_PRE_MOVE, COMSIG_MOVABLE_POST_TELEPORT))
		if(mob.mind?.has_antag_datum(/datum/antagonist/heretic_arena_participant))
			mob.mind.remove_antag_datum(/datum/antagonist/heretic_arena_participant)
	for(var/turf/to_restore in border_walls)
		to_restore.ChangeTurf(border_walls[to_restore])
	for(var/obj/to_refund as anything in welfare_blades)
		qdel(to_refund)
	arena_caster = null
	return ..()

/datum/proximity_monitor/advanced/heretic_arena/setup_edge_turf(turf/target)
	. = ..()
	var/old_turf = target.type
	target.ChangeTurf(/turf/closed/indestructible/heretic_wall)
	border_walls += target
	border_walls[target] += old_turf

/datum/proximity_monitor/advanced/heretic_arena/field_edge_uncrossed(atom/movable/movable, turf/old_location, turf/new_location)
	if(!isliving(movable))
		return
	var/mob/living/living_mob = movable
	addtimer(CALLBACK(living_mob, TYPE_PROC_REF(/mob/living, remove_status_effect), /datum/status_effect/arena_tracker), 10 SECONDS)
	living_mob.remove_traits(given_immunities, HERETIC_ARENA_TRAIT)
	if(living_mob == arena_caster)
		QDEL_IN(host, 3 SECONDS)

/// Prevents using ladders
/datum/proximity_monitor/advanced/heretic_arena/proc/on_try_ladder(mob/climber)
	SIGNAL_HANDLER
	return LADDER_TRAVEL_BLOCK

/// If we try to enter a space turf that has a mirage, we will block the movement
/datum/proximity_monitor/advanced/heretic_arena/proc/on_pre_move(atom/movable/mover, atom/newloc)
	if(locate(/atom/movable/mirage_holder) in newloc.contents)
		return COMPONENT_MOVABLE_BLOCK_PRE_MOVE

/// Blocks Z movement to new z levels
/datum/proximity_monitor/advanced/heretic_arena/proc/on_try_z_move(atom/movable/source, turf/start, turf/destination)
	SIGNAL_HANDLER
	if(start.z == destination.z)
		return
	return COMPONENT_CANT_Z_MOVE

/// If our caster teleports away (after winning presumably) we'll collapse the arena so that it doens't needlessly linger
/datum/proximity_monitor/advanced/heretic_arena/proc/on_teleport(atom/teleportee, atom/destination, channel)
	if(teleportee == arena_caster)
		qdel(host)

/datum/proximity_monitor/advanced/heretic_arena/proc/set_caster(atom/caster)
	arena_caster = caster

/turf/closed/indestructible/heretic_wall
	name = "eldritch wall"
	desc = "A wall penning in the sheep amongst the wolves. It glows with malevolent energy - prodding it is likely unwise."
	icon = 'icons/turf/walls.dmi'
	icon_state = "eldritch_forcewall"
	opacity = FALSE
	pass_flags_self = NONE // No PASSCLOSEDTURF because only arena victors are allowed to go in or out

/turf/closed/indestructible/heretic_wall/CanAllowThrough(atom/movable/mover, border_dir)
	if(isliving(mover))
		var/mob/living/living_mover = mover
		var/datum/status_effect/arena_tracker/tracker = living_mover.has_status_effect(/datum/status_effect/arena_tracker)
		if(tracker?.arena_victor)
			return TRUE
	return ..()

/turf/closed/indestructible/heretic_wall/Bumped(atom/movable/bumped_atom)
	. = ..()
	if(!isliving(bumped_atom))
		return
	var/mob/living/living_mob = bumped_atom
	var/atom/target = get_edge_target_turf(living_mob, get_dir(src, get_step_away(living_mob, src)))
	living_mob.throw_at(target, 4, 5)
	to_chat(living_mob, span_userdanger("The wall repels you with tremendous force!"))

/// Called when you crit somebody to update your crown
/datum/status_effect/arena_tracker/proc/on_crit_somebody()
	owner.cut_overlay(crown_overlay)
	crown_overlay = mutable_appearance('icons/mob/effects/crown.dmi', "arena_victor", -HALO_LAYER)
	crown_overlay.pixel_y = 24
	owner.add_overlay(crown_overlay)
	owner.remove_traits(list(TRAIT_ELDRITCH_ARENA_PARTICIPANT, TRAIT_NO_TELEPORT), TRAIT_STATUS_EFFECT(id))

	// The mansus celebrates your efforts
	if(IS_HERETIC(owner))
		owner.heal_overall_damage(60, 60, 60)
		owner.adjustToxLoss(-60, forced = TRUE) // Slime heretics everywhere...
		owner.adjustOxyLoss(-60)
		if(iscarbon(owner))
			var/mob/living/carbon/carbon_owner = owner
			for(var/datum/wound/wound as anything in carbon_owner.all_wounds)
				wound.remove_wound()

	if(arena_victor) // No need to spam if we've already killed at least 1 person
		return
	if(IS_HERETIC(owner))
		to_chat(owner, span_big(span_hypnophrase("The mansus is pleased with your performance, you may leave now.")))
	else
		to_chat(owner, span_big(span_hypnophrase("You have done well, you may leave now.")))
	arena_victor = TRUE

/**
 * Status applied to every mob in the heretic arena.
 * Tracks the last person to damage owner.
 * When owner enters crit, we send a signal to last_attacker status so they can leave the arena
 */

/datum/status_effect/arena_tracker
	id = "arena_tracker"
	duration = STATUS_EFFECT_PERMANENT
	tick_interval = STATUS_EFFECT_NO_TICK
	status_type = STATUS_EFFECT_UNIQUE
	alert_type = null
	/// Tracks the last person who dealt damage to this mob
	var/datum/weakref/last_attacker
	/// If our mob is free to leave, set to true
	var/arena_victor = FALSE
	/// The overlay for our mob, changes color to indicate that they are a victor and are free to leave
	var/mutable_appearance/crown_overlay

/datum/status_effect/arena_tracker/on_apply()
	RegisterSignal(owner, SIGNAL_ADDTRAIT(TRAIT_CRITICAL_CONDITION), PROC_REF(on_enter_crit))
	RegisterSignal(owner, COMSIG_MOB_APPLY_DAMAGE, PROC_REF(damage_taken))
	owner.add_traits(list(TRAIT_ELDRITCH_ARENA_PARTICIPANT, TRAIT_NO_TELEPORT), TRAIT_STATUS_EFFECT(id))
	crown_overlay = mutable_appearance('icons/mob/effects/crown.dmi', "arena_fighter", -HALO_LAYER)
	crown_overlay.pixel_y = 24
	owner.add_overlay(crown_overlay)
	return TRUE

/datum/status_effect/arena_tracker/on_remove()
	UnregisterSignal(owner, list(SIGNAL_ADDTRAIT(TRAIT_CRITICAL_CONDITION), COMSIG_MOB_APPLY_DAMAGE))
	owner.remove_traits(list(TRAIT_ELDRITCH_ARENA_PARTICIPANT, TRAIT_NO_TELEPORT), TRAIT_STATUS_EFFECT(id))
	owner.cut_overlay(crown_overlay)
	crown_overlay = null

// If our last attacker is an arena participant, we let them know they've scored a critical hit
/datum/status_effect/arena_tracker/proc/on_enter_crit(mob/owner)
	SIGNAL_HANDLER
	if(!last_attacker)
		return // Safety check in case they somehow enter crit with *nobody* attacking them
	var/mob/living/our_attacker = last_attacker.resolve()
	if(!isliving(our_attacker) || our_attacker == owner) // We don't allow people to crit themselves as a valid way to escape
		return
	var/datum/status_effect/arena_tracker/their_tracker = our_attacker.has_status_effect(/datum/status_effect/arena_tracker)
	if(!their_tracker)
		return // Somebody killed us who isn't an arena participant
	their_tracker.on_crit_somebody()

/datum/status_effect/arena_tracker/proc/damage_taken(
	datum/source,
	damage_amount,
	damagetype,
	def_zone,
	blocked,
	wound_bonus,
	bare_wound_bonus,
	sharpness,
	attack_direction,
	attacking_item,
	wound_clothing,
)
	SIGNAL_HANDLER
	if(isnull(attacking_item))
		return
	if(!isobj(attacking_item))
		return
	var/obj/attacking_object = attacking_item

	// Track being hit by a mob holding a stick
	if(ismob(attacking_object.loc))
		last_attacker = WEAKREF(attacking_object.loc)
		return

	// Track being hit by a mob throwing a stick
	if(isitem(attacking_object))
		var/obj/item/thrown_item = attacking_item
		var/thrown_by = thrown_item.thrownby?.resolve()
		if(ismob(thrown_by))
			last_attacker = WEAKREF(thrown_by)
			return

	// Edge case. If our attacking_item is a gun which the owner has dropped we need to find out who shot us
	// Track being hit by a mob shooting a stick
	if(isprojectile(attacking_object))
		var/obj/projectile/attacking_projectile = attacking_object
		if(ismob(attacking_projectile.firer))
			last_attacker = WEAKREF(attacking_projectile.firer)

/datum/antagonist/heretic_arena_participant
	name = "Arena Participant"
	show_in_roundend = FALSE
	replace_banned = FALSE
	objectives = list()
	antag_hud_name = "brainwashed"
	block_midrounds = FALSE

/datum/antagonist/heretic_arena_participant/on_gain()
	forge_objectives()
	return ..()

/datum/antagonist/heretic_arena_participant/forge_objectives()
	var/datum/objective/survive = new /datum/objective
	survive.owner = owner
	survive.explanation_text = "You have been trapped in an arena. The only way out is to slaughter someone else. Kill your captor, or betray your friends - the choice is yours."
	objectives += survive
	var/datum/objective/fight_to_escape = new /datum/objective
	fight_to_escape.owner = owner
	fight_to_escape.explanation_text = "Escape is impossible. The only way out is to defeat another participant in this battle to the death. \
		A weapon has been bestowed unto you, granting you a fighting chance, it would be quite a shame were you to attempt to break it."
	objectives += fight_to_escape
