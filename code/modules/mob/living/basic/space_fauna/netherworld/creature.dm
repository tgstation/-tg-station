/mob/living/basic/creature
	name = "creature"
	desc = "A sanity-destroying otherthing from the netherworld."
	icon_state = "otherthing"
	icon_living = "otherthing"
	icon_dead = "otherthing-dead"
	health = 50
	maxHealth = 50
	obj_damage = 50
	melee_damage_lower = 20
	melee_damage_upper = 30
	speed = 2
	attack_verb_continuous = "slashes"
	attack_verb_simple = "slash"
	gold_core_spawnable = HOSTILE_SPAWN
	attack_sound = 'sound/items/weapons/bite.ogg'
	attack_vis_effect = ATTACK_EFFECT_BITE
	melee_attack_cooldown = 1 SECONDS
	faction = list(FACTION_NETHER)
	speak_emote = list("screams")
	death_message = "gets his head split open."
	unsuitable_atmos_damage = 0
	unsuitable_cold_damage = 0
	unsuitable_heat_damage = 0
	// Green and blue, bit dim cause yaknow morphlike
	lighting_cutoff_red = 5
	lighting_cutoff_green = 25
	lighting_cutoff_blue = 15

	ai_controller = /datum/ai_controller/basic_controller/simple/simple_hostile_obstacles
	var/health_scaling = TRUE

/mob/living/basic/creature/Initialize(mapload)
	. = ..()
	AddElement(/datum/element/swabable, CELL_LINE_TABLE_NETHER, CELL_VIRUS_TABLE_GENERIC_MOB, 1, 0)
	if(health_scaling)
		AddComponent(
			/datum/component/health_scaling_effects,\
			min_health_attack_modifier_lower = 15,\
			min_health_attack_modifier_upper = 30,\
			min_health_slowdown = -1.5,\
		)

	GRANT_ACTION(/datum/action/cooldown/spell/jaunt/creature_teleport)

/mob/living/basic/creature/proc/can_be_seen(turf/location)
	// Check for darkness
	if(location?.lighting_object)
		if(location.get_lumcount() < 0.1) // No one can see us in the darkness, right?
			return null

	// We aren't in darkness, loop for viewers.
	var/list/check_list = list(src)
	if(location)
		check_list += location

	// This loop will, at most, loop twice.
	for(var/atom/check in check_list)
		for(var/mob/living/mob_target in oview(src, 7)) // They probably cannot see us if we cannot see them... can they?
			if(mob_target.client && !mob_target.is_blind() && !HAS_TRAIT(mob_target, TRAIT_UNOBSERVANT))
				return mob_target
		for(var/obj/vehicle/sealed/mecha/mecha_mob_target in oview(src, 7))
			for(var/mob/mechamob_target as anything in mecha_mob_target.occupants)
				if(mechamob_target.client && !mechamob_target.is_blind())
					return mechamob_target
	return null

/// Jaunt spell used by creature. Can only jaunt or unjaunt if nothing can see you.
/datum/action/cooldown/spell/jaunt/creature_teleport
	name = "Uncanny Movement"
	desc = "Enter or leave an alternate plane where you can travel through walls. You can only enter or emerge if unobserved."
	button_icon = 'icons/mob/actions/actions_spells.dmi'
	button_icon_state = "blink"
	background_icon_state = "bg_default"
	overlay_icon_state = "bg_default_border"
	spell_requirements = NONE
	/// Component which prevents this action being used while visible
	var/datum/component/unobserved_actor/observed_blocker

/datum/action/cooldown/spell/jaunt/creature_teleport/Grant(mob/grant_to)
	. = ..()
	if (!owner)
		return
	observed_blocker = owner.AddComponent(/datum/component/unobserved_actor, unobserved_flags = NO_OBSERVED_ACTIONS, affected_actions = list(type))

/datum/action/cooldown/spell/jaunt/creature_teleport/Remove(mob/living/remove_from)
	QDEL_NULL(observed_blocker)
	return ..()

/datum/action/cooldown/spell/jaunt/creature_teleport/before_cast(atom/cast_on)
	if (!owner)
		return SPELL_CANCEL_CAST
	if (!do_after(owner, 6 SECONDS, target = owner.loc))
		owner.balloon_alert(owner, "interrupted!")
		return SPELL_CANCEL_CAST
	return ..()

/datum/action/cooldown/spell/jaunt/creature_teleport/cast(atom/cast_on)
	. = ..()
	playsound(get_turf(owner), 'sound/effects/podwoosh.ogg', 50, TRUE, -1)
	if(is_jaunting(cast_on))
		exit_jaunt(cast_on)
		return
	enter_jaunt(cast_on)

/mob/living/basic/creature/tiggles
	name = "Miss Tiggles"
	gold_core_spawnable = NO_SPAWN

/mob/living/basic/creature/hatchling
	name = "hatchling"
	health = 25
	maxHealth = 25
	health_scaling = FALSE
	initial_size = 0.85
