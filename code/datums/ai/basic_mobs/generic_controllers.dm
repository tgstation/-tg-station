/// Basetype with normal parameters
/datum/ai_controller/basic_controller/simple
	blackboard = list(
		BB_TARGETING_STRATEGY = /datum/targeting_strategy/basic,
	)

	ai_movement = /datum/ai_movement/basic_avoidance
	idle_behavior = /datum/idle_behavior/idle_random_walk

/// The most basic AI tree which just finds a guy and then runs at them to click them
/datum/ai_controller/basic_controller/simple/simple_hostile
	planning_subtrees = list(
		/datum/ai_planning_subtree/simple_find_target,
		/datum/ai_planning_subtree/basic_melee_attack_subtree,
	)

/// Find a target, walk at target, attack intervening obstacles
/datum/ai_controller/basic_controller/simple/simple_hostile_obstacles
	planning_subtrees = list(
		/datum/ai_planning_subtree/simple_find_target,
		/datum/ai_planning_subtree/attack_obstacle_in_path,
		/datum/ai_planning_subtree/basic_melee_attack_subtree,
	)

/// Find a target, walk at target, attack intervening obstacles
/datum/ai_controller/basic_controller/simple/simple_ranged
	planning_subtrees = list(
		/datum/ai_planning_subtree/simple_find_target,
		/datum/ai_planning_subtree/maintain_distance,
		/datum/ai_planning_subtree/ranged_skirmish,
	)

/datum/ai_controller/basic_controller/simple/simple_ranged_retaliate
	planning_subtrees = list(
		/datum/ai_planning_subtree/target_retaliate,
		/datum/ai_planning_subtree/maintain_distance,
		/datum/ai_planning_subtree/ranged_skirmish,
	)

/// Find a target, walk towards it AND shoot it
/datum/ai_controller/basic_controller/simple/simple_skirmisher
	planning_subtrees = list(
		/datum/ai_planning_subtree/simple_find_target,
		/datum/ai_planning_subtree/ranged_skirmish,
		/datum/ai_planning_subtree/attack_obstacle_in_path,
		/datum/ai_planning_subtree/basic_melee_attack_subtree,
	)

/// Use an ability on target on cooldown
/datum/ai_controller/basic_controller/simple/simple_ability
	planning_subtrees = list(
		/datum/ai_planning_subtree/simple_find_target,
		/datum/ai_planning_subtree/maintain_distance,
		/datum/ai_planning_subtree/targeted_mob_ability,
	)

/datum/ai_controller/basic_controller/simple/simple_ability_retaliate
	planning_subtrees = list(
		/datum/ai_planning_subtree/target_retaliate,
		/datum/ai_planning_subtree/maintain_distance,
		/datum/ai_planning_subtree/targeted_mob_ability,
	)

/// Use an ability on target on cooldown, then try to punch them
/datum/ai_controller/basic_controller/simple/simple_ability_melee
	planning_subtrees = list(
		/datum/ai_planning_subtree/simple_find_target,
		/datum/ai_planning_subtree/targeted_mob_ability,
		/datum/ai_planning_subtree/attack_obstacle_in_path,
		/datum/ai_planning_subtree/basic_melee_attack_subtree,
	)

/// Use an ability on target on cooldown, then try to shoot them
/datum/ai_controller/basic_controller/simple/simple_ability_ranged
	planning_subtrees = list(
		/datum/ai_planning_subtree/simple_find_target,
		/datum/ai_planning_subtree/maintain_distance,
		/datum/ai_planning_subtree/targeted_mob_ability,
		/datum/ai_planning_subtree/ranged_skirmish,
	)

/// Fight back if attacked
/datum/ai_controller/basic_controller/simple/simple_retaliate
	ai_traits = STOP_MOVING_WHEN_PULLED
	planning_subtrees = list(
		/datum/ai_planning_subtree/target_retaliate,
		/datum/ai_planning_subtree/basic_melee_attack_subtree,
	)

/// Get pissed at random people for no reason
/datum/ai_controller/basic_controller/simple/simple_capricious
	ai_traits = STOP_MOVING_WHEN_PULLED
	planning_subtrees = list(
		/datum/ai_planning_subtree/capricious_retaliate,
		/datum/ai_planning_subtree/target_retaliate,
		/datum/ai_planning_subtree/basic_melee_attack_subtree,
	)

/// Runs away from anyone it sees
/datum/ai_controller/basic_controller/simple/simple_fearful
	ai_traits = STOP_MOVING_WHEN_PULLED
	planning_subtrees = list(
		/datum/ai_planning_subtree/simple_find_nearest_target_to_flee,
		/datum/ai_planning_subtree/flee_target,
	)

/// Runs away when attacked
/datum/ai_controller/basic_controller/simple/simple_skittish
	ai_traits = STOP_MOVING_WHEN_PULLED
	planning_subtrees = list(
		/datum/ai_planning_subtree/find_nearest_thing_which_attacked_me_to_flee,
		/datum/ai_planning_subtree/flee_target,
	)

/// Does what it is told and protects da boss
/datum/ai_controller/basic_controller/simple/simple_goon
	blackboard = list(
		BB_TARGETING_STRATEGY = /datum/targeting_strategy/basic/not_friends,
		BB_PET_TARGETING_STRATEGY = /datum/targeting_strategy/basic/not_friends,
	)

	planning_subtrees = list(
		/datum/ai_planning_subtree/pet_planning,
	)
