/mob/living/basic/paper_wizard
	name = "Mjor the Creative"
	desc = "A wizard with a taste for the arts."
	mob_biotypes = MOB_ORGANIC|MOB_HUMANOID
	faction = list(FACTION_HOSTILE, FACTION_STICKMAN)
	icon = 'icons/mob/simple/simple_human.dmi'
	icon_state = "paperwizard"
	gender = MALE

	response_help_continuous = "brushes"
	response_help_simple = "brush"
	response_disarm_continuous = "pushes"
	response_disarm_simple = "push"
	basic_mob_flags = DEL_ON_DEATH

	maxHealth = 1000
	health = 1000
	melee_damage_lower = 10
	melee_damage_upper = 20
	obj_damage = 50
	attack_sound = 'sound/effects/hallucinations/growl1.ogg'
	ai_controller = /datum/ai_controller/basic_controller/paper_wizard
	///spell to summon minions
	var/datum/action/cooldown/spell/conjure/wizard_summon_minions/summon
	///spell to summon clones
	var/datum/action/cooldown/spell/pointed/wizard_mimic/mimic
	///the loot we will drop
	var/static/list/dropped_loot = list(/obj/effect/temp_visual/paperwiz_dying)


/mob/living/basic/paper_wizard/Initialize(mapload)
	. = ..()
	apply_dynamic_human_appearance(src, mob_spawn_path = /obj/effect/mob_spawn/corpse/human/wizard/paper)
	grant_abilities()
	grant_loot()
	AddElement(/datum/element/effect_trail, /obj/effect/temp_visual/paper_scatter)

/mob/living/basic/paper_wizard/proc/grant_abilities()
	var/static/list/innate_actions = list(
		/datum/action/cooldown/spell/conjure/wizard_summon_minions = BB_WIZARD_SUMMON_MINIONS,
		/datum/action/cooldown/spell/pointed/wizard_mimic = BB_WIZARD_MIMICS,
	)

	grant_actions_by_list(innate_actions)

/mob/living/basic/paper_wizard/proc/grant_loot()
	AddElement(/datum/element/death_drops, dropped_loot)

/datum/ai_controller/basic_controller/paper_wizard
	blackboard = list(
		BB_TARGETING_STRATEGY = /datum/targeting_strategy/basic,
		BB_WRITING_LIST = list(
			"I can turn the paper into gold and ink into diamonds!",
			"Your fate is written and sealed!",
			"You shall suffer the wrath of a thousand paper cuts!",
		)
	)

	ai_movement = /datum/ai_movement/basic_avoidance
	idle_behavior = /datum/idle_behavior/idle_random_walk/less_walking
	planning_subtrees = list(
		/datum/ai_planning_subtree/simple_find_target,
		/datum/ai_planning_subtree/targeted_mob_ability/wizard_mimic,
		/datum/ai_planning_subtree/use_mob_ability/wizard_summon_minions,
		/datum/ai_planning_subtree/basic_melee_attack_subtree,
		/datum/ai_planning_subtree/attack_obstacle_in_path/paper_wizard,
		/datum/ai_planning_subtree/find_paper_and_write,
	)

/datum/ai_planning_subtree/attack_obstacle_in_path/paper_wizard
	target_key = BB_FOUND_PAPER
	attack_behaviour = /datum/ai_behavior/attack_obstructions/paper_wizard

/datum/ai_behavior/attack_obstructions/paper_wizard
	action_cooldown = 0.4 SECONDS
	can_attack_turfs = TRUE
	can_attack_dense_objects = TRUE

/datum/ai_planning_subtree/targeted_mob_ability/wizard_mimic
	ability_key = BB_WIZARD_MIMICS
	finish_planning = FALSE

/datum/ai_planning_subtree/use_mob_ability/wizard_summon_minions
	ability_key = BB_WIZARD_SUMMON_MINIONS
	finish_planning = FALSE

/datum/ai_behavior/find_and_set/empty_paper
	action_cooldown = 10 SECONDS

/datum/ai_behavior/find_and_set/empty_paper/search_tactic(datum/ai_controller/controller, locate_path, search_range)
	var/list/empty_papers = list()

	for(var/obj/item/paper/target_paper in oview(search_range, controller.pawn))
		if(target_paper.is_empty())
			empty_papers += target_paper

	if(empty_papers.len)
		return pick(empty_papers)

/mob/living/basic/paper_wizard/copy
	desc = "'Tis a ruse!"
	health = 1
	maxHealth = 1
	alpha = 200
	faction = list(FACTION_STICKMAN)
	melee_damage_lower = 1
	melee_damage_upper = 5
	ai_controller = /datum/ai_controller/basic_controller/simple/simple_hostile

/mob/living/basic/paper_wizard/copy/Initialize(mapload)
	. = ..()
	AddElement(/datum/element/relay_attackers)
	RegisterSignal(src, COMSIG_ATOM_WAS_ATTACKED, PROC_REF(on_attacked))

/mob/living/basic/paper_wizard/copy/grant_abilities()
	return

/mob/living/basic/paper_wizard/copy/grant_loot()
	return

//Hit a fake? eat pain!
/mob/living/basic/paper_wizard/copy/proc/on_attacked(mob/source, mob/living/attacker, attack_flags)
	SIGNAL_HANDLER

	if(!(attack_flags & (ATTACKER_STAMINA_ATTACK|ATTACKER_SHOVING)))
		attacker.adjustBruteLoss(20)
		to_chat(attacker, span_warning("The clone casts a spell to damage you before he dies!"))


/mob/living/basic/paper_wizard/copy/examine(mob/user)
	. = ..()
	if(isobserver(user))
		. += span_notice("It's an illusion - what is it hiding?")
	else
		new /obj/effect/temp_visual/small_smoke/halfsecond(get_turf(src))
		qdel(src) //I see through your ruse!

//fancy effects
/obj/effect/temp_visual/paper_scatter
	name = "scattering paper"
	desc = "Pieces of paper scattering to the wind."
	layer = ABOVE_NORMAL_TURF_LAYER
	plane = GAME_PLANE
	icon = 'icons/effects/effects.dmi'
	icon_state = "paper_scatter"
	anchored = TRUE
	duration = 0.5 SECONDS
	randomdir = FALSE

/obj/effect/temp_visual/paperwiz_dying
	name = "craft portal"
	desc = "A wormhole sucking the wizard into the void. Neat."
	layer = ABOVE_NORMAL_TURF_LAYER
	plane = GAME_PLANE
	icon = 'icons/effects/effects.dmi'
	icon_state = "paperwiz_poof"
	anchored = TRUE
	duration = 1.8 SECONDS
	randomdir = FALSE

/obj/effect/temp_visual/paperwiz_dying/Initialize(mapload)
	. = ..()
	visible_message(span_bolddanger("The wizard cries out in pain as a gate appears behind him, sucking him in!"))
	playsound(get_turf(src), 'sound/effects/magic/mandswap.ogg', 50, vary = TRUE, pressure_affected = TRUE)
	playsound(get_turf(src), 'sound/effects/hallucinations/wail.ogg', 50, vary = TRUE, pressure_affected = TRUE)
	RegisterSignal(src, COMSIG_PREQDELETED, PROC_REF(on_delete))

/obj/effect/temp_visual/paperwiz_dying/proc/on_delete()
	SIGNAL_HANDLER

	for(var/mob/nearby in range(7, src))
		shake_camera(nearby, duration = 7 SECONDS, strength = 1)
	var/turf/current_turf = get_turf(src)
	playsound(current_turf,'sound/effects/magic/summon_magic.ogg', 50, vary = TRUE, vary = TRUE)
	new /obj/effect/temp_visual/paper_scatter(current_turf)
	new /obj/item/clothing/suit/wizrobe/paper(current_turf)
	new /obj/item/clothing/head/collectable/paper(current_turf)
