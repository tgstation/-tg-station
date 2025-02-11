/// The most basic AI tree which just finds a guy and then runs at them to click them
/datum/ai_controller/basic_controller/simple_hostile
	blackboard = list(
		BB_TARGETING_STRATEGY = /datum/targeting_strategy/basic,
	)

	ai_movement = /datum/ai_movement/basic_avoidance
	idle_behavior = /datum/idle_behavior/idle_random_walk
	planning_subtrees = list(
		/datum/ai_planning_subtree/simple_find_target,
		/datum/ai_planning_subtree/basic_melee_attack_subtree,
	)

/// Find a target, walk at target, attack intervening obstacles
/datum/ai_controller/basic_controller/simple_hostile_obstacles
	blackboard = list(
		BB_TARGETING_STRATEGY = /datum/targeting_strategy/basic,
	)

	ai_movement = /datum/ai_movement/basic_avoidance
	idle_behavior = /datum/idle_behavior/idle_random_walk
	planning_subtrees = list(
		/datum/ai_planning_subtree/simple_find_target,
		/datum/ai_planning_subtree/attack_obstacle_in_path,
		/datum/ai_planning_subtree/basic_melee_attack_subtree,
	)

/// Literally does nothing except random speedh
/datum/ai_controller/basic_controller/talk
	idle_behavior = null
	planning_subtrees = list(
		/datum/ai_planning_subtree/random_speech/blackboard,
	)
