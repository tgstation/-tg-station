/datum/ai_controller/basic_controller/ice_demon
	blackboard = list(
		BB_TARGETING_STRATEGY = /datum/targeting_strategy/basic,
		BB_RANGED_SKIRMISH_MAX_DISTANCE = 7,
		BB_LIST_SCARY_ITEMS = list(
			/obj/item/weldingtool,
			/obj/item/flashlight/flare,
		),
	)

	ai_movement = /datum/ai_movement/basic_avoidance
	idle_behavior = /datum/idle_behavior/idle_random_walk
	planning_subtrees = list(
		/datum/ai_planning_subtree/simple_find_target,
		/datum/ai_planning_subtree/flee_target/ice_demon,
		/datum/ai_planning_subtree/ranged_skirmish/ice_demon,
		/datum/ai_planning_subtree/maintain_distance/cover_minimum_distance,
		/datum/ai_planning_subtree/teleport_away_from_target,
		/datum/ai_planning_subtree/find_and_hunt_target/teleport_destination,
		/datum/ai_planning_subtree/targeted_mob_ability/summon_afterimages,
	)

/datum/ai_planning_subtree/teleport_away_from_target
	ability_key = BB_DEMON_TELEPORT_ABILITY

/datum/ai_planning_subtree/find_and_hunt_target/teleport_destination
	target_key = BB_TELEPORT_DESTINATION
	hunting_behavior = /datum/ai_behavior/hunt_target/use_ability_on_target/demon_teleport
	finding_behavior = /datum/ai_behavior/find_valid_teleport_location
	hunt_targets = list(/turf/open)
	hunt_range = 3
	finish_planning = FALSE

/datum/ai_planning_subtree/find_and_hunt_target/teleport_destination/SelectBehaviors(datum/ai_controller/controller, seconds_per_tick)
	if(!controller.blackboard_key_exists(BB_BASIC_MOB_CURRENT_TARGET))
		return
	if(controller.blackboard_key_exists(BB_ESCAPE_DESTINATION))
		controller.clear_blackboard_key(BB_TELEPORT_DESTINATION)
		return
	var/datum/action/cooldown/ability = controller.blackboard[BB_DEMON_TELEPORT_ABILITY]
	if(!ability?.IsAvailable())
		return
	return ..()

/datum/ai_behavior/find_valid_teleport_location

/datum/ai_behavior/find_valid_teleport_location/perform(seconds_per_tick, datum/ai_controller/controller, hunting_target_key, types_to_hunt, hunt_range)
	var/mob/living/target = controller.blackboard[BB_BASIC_MOB_CURRENT_TARGET]
	var/list/possible_turfs = list()

	if(QDELETED(target))
		return AI_BEHAVIOR_DELAY | AI_BEHAVIOR_FAILED

	for(var/turf/open/potential_turf in oview(hunt_range, target)) //we check for turfs around the target
		if(potential_turf.is_blocked_turf())
			continue
		if(!can_see(target, potential_turf, hunt_range))
			continue
		possible_turfs += potential_turf

	if(!length(possible_turfs))
		return AI_BEHAVIOR_DELAY | AI_BEHAVIOR_FAILED

	controller.set_blackboard_key(hunting_target_key, pick(possible_turfs))
	return AI_BEHAVIOR_DELAY | AI_BEHAVIOR_SUCCEEDED

/datum/ai_behavior/hunt_target/use_ability_on_target/demon_teleport
	hunt_cooldown = 2 SECONDS
	ability_key = BB_DEMON_TELEPORT_ABILITY
	behavior_flags = NONE

/datum/ai_planning_subtree/targeted_mob_ability/summon_afterimages
	ability_key = BB_DEMON_CLONE_ABILITY

/datum/ai_planning_subtree/targeted_mob_ability/summon_afterimages/SelectBehaviors(datum/ai_controller/controller, seconds_per_tick)
	var/mob/living/living_pawn = controller.pawn
	if(living_pawn.health / living_pawn.maxHealth > 0.5) //only use this ability when under half health
		return
	return ..()

/datum/ai_planning_subtree/flee_target/ice_demon

/datum/ai_planning_subtree/flee_target/ice_demon/SelectBehaviors(datum/ai_controller/controller, seconds_per_tick)
	var/atom/target = controller.blackboard[BB_BASIC_MOB_CURRENT_TARGET]
	if(QDELETED(target))
		return
	if(!iscarbon(target))
		return
	var/mob/living/carbon/human_target = target

	for(var/obj/held_item in human_target.held_items)
		if(!is_type_in_list(held_item, controller.blackboard[BB_LIST_SCARY_ITEMS]))
			continue
		if(!held_item.light_on)
			continue
		var/datum/action/cooldown/slip_ability = controller.blackboard[BB_DEMON_SLIP_ABILITY]
		if(slip_ability?.IsAvailable())
			controller.queue_behavior(/datum/ai_behavior/use_mob_ability, BB_DEMON_SLIP_ABILITY)
		return ..()

/datum/ai_planning_subtree/ranged_skirmish/ice_demon
	min_range = 0

/datum/ai_controller/basic_controller/ice_demon/afterimage
	planning_subtrees = list(
		/datum/ai_planning_subtree/simple_find_target,
		/datum/ai_planning_subtree/flee_target/ice_demon, //even the afterimages are afraid of flames!
		/datum/ai_planning_subtree/basic_melee_attack_subtree,
	)

