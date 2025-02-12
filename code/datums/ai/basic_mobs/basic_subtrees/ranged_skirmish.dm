/// Fire a ranged attack without interrupting movement.
/datum/ai_planning_subtree/ranged_skirmish
	operational_datums = list(/datum/component/ranged_attacks)
	/// Blackboard key holding target atom
	var/target_key = BB_BASIC_MOB_CURRENT_TARGET
	/// What AI behaviour do we actually run?
	var/attack_behavior = /datum/ai_behavior/ranged_skirmish
	/// If target is further away than this we don't fire
	var/max_range = 9
	/// If target is closer than this we don't fire
	var/min_range = 2

/datum/ai_planning_subtree/ranged_skirmish/SelectBehaviors(datum/ai_controller/controller, seconds_per_tick)
	. = ..()
	if(!controller.blackboard_key_exists(target_key))
		return
	controller.queue_behavior(attack_behavior, target_key, BB_TARGETING_STRATEGY, BB_BASIC_MOB_CURRENT_TARGET_HIDING_LOCATION, max_range, min_range)

/// How often will we try to perform our ranged attack?
/datum/ai_behavior/ranged_skirmish
	action_cooldown = 0.5 SECONDS

/datum/ai_behavior/ranged_skirmish/setup(datum/ai_controller/controller, target_key, targeting_strategy_key, hiding_location_key, max_range, min_range)
	. = ..()
	var/atom/target = controller.blackboard[hiding_location_key] || controller.blackboard[target_key]
	return !QDELETED(target)

/datum/ai_behavior/ranged_skirmish/perform(seconds_per_tick, datum/ai_controller/controller, target_key, targeting_strategy_key, hiding_location_key, max_range, min_range)
	var/atom/target = controller.blackboard[target_key]
	if (QDELETED(target))
		return AI_BEHAVIOR_DELAY | AI_BEHAVIOR_FAILED

	var/datum/targeting_strategy/targeting_strategy = GET_TARGETING_STRATEGY(controller.blackboard[targeting_strategy_key])
	if(!targeting_strategy.can_attack(controller.pawn, target))
		return AI_BEHAVIOR_DELAY | AI_BEHAVIOR_FAILED

	var/hiding_target = targeting_strategy.find_hidden_mobs(controller.pawn, target)
	controller.set_blackboard_key(hiding_location_key, hiding_target)

	target = hiding_target || target

	var/distance = get_dist(controller.pawn, target)
	if (distance > max_range || distance < min_range)
		return AI_BEHAVIOR_DELAY | AI_BEHAVIOR_FAILED

	controller.ai_interact(target = target, combat_mode = TRUE)
	return AI_BEHAVIOR_DELAY | AI_BEHAVIOR_SUCCEEDED

/datum/ai_planning_subtree/ranged_skirmish/no_minimum
	min_range = 0
