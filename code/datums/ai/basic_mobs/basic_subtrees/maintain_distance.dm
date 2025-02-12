/// Step away if too close, or towards if too far
/datum/ai_planning_subtree/maintain_distance
	/// Blackboard key holding atom we want to stay away from
	var/target_key = BB_BASIC_MOB_CURRENT_TARGET
	/// How far do we look for our target?
	var/view_distance = 10
	/// the run away behavior we will use
	var/run_away_behavior = /datum/ai_behavior/step_away

/datum/ai_planning_subtree/maintain_distance/SelectBehaviors(datum/ai_controller/controller, seconds_per_tick)
	. = ..()

	var/mob/living/living_pawn = controller.pawn
	if(LAZYLEN(living_pawn.do_afters))
		return

	var/atom/target = controller.blackboard[target_key]
	if (!isliving(target) || !can_see(controller.pawn, target, view_distance))
		return // Don't run away from cucumbers, they're not snakes
	var/range = get_dist(controller.pawn, target)

	var/minimum_distance = controller.blackboard[BB_RANGED_SKIRMISH_MIN_DISTANCE] || 4
	var/maximum_distance = controller.blackboard[BB_RANGED_SKIRMISH_MAX_DISTANCE] || 6

	if (range < minimum_distance)
		controller.queue_behavior(run_away_behavior, target_key, minimum_distance)
		return
	if (range > maximum_distance)
		controller.queue_behavior(/datum/ai_behavior/pursue_to_range, target_key, maximum_distance)
		return

/datum/ai_planning_subtree/maintain_distance/cover_minimum_distance
	run_away_behavior = /datum/ai_behavior/cover_minimum_distance

/// Take one step away
/datum/ai_behavior/step_away
	behavior_flags = AI_BEHAVIOR_REQUIRE_MOVEMENT | AI_BEHAVIOR_CAN_PLAN_DURING_EXECUTION
	required_distance = 0
	action_cooldown = 0.2 SECONDS

/datum/ai_behavior/step_away/setup(datum/ai_controller/controller, target_key)
	. = ..()
	var/atom/current_target = controller.blackboard[target_key]
	if (QDELETED(current_target))
		return FALSE

	var/mob/living/our_pawn = controller.pawn
	our_pawn.face_atom(current_target)

	var/turf/next_step = get_step_away(controller.pawn, current_target)
	if (!isnull(next_step) && !next_step.is_blocked_turf(exclude_mobs = TRUE))
		set_movement_target(controller, target = next_step, new_movement = /datum/ai_movement/basic_avoidance/backstep)
		return TRUE

	var/list/all_dirs = GLOB.alldirs.Copy()
	all_dirs -= get_dir(controller.pawn, next_step)
	all_dirs -= get_dir(controller.pawn, current_target)
	shuffle_inplace(all_dirs)

	for (var/dir in all_dirs)
		next_step = get_step(controller.pawn, dir)
		if (!isnull(next_step) && !next_step.is_blocked_turf(exclude_mobs = TRUE))
			set_movement_target(controller, target = next_step, new_movement = /datum/ai_movement/basic_avoidance/backstep)
			return TRUE
	return FALSE

/datum/ai_behavior/step_away/perform(seconds_per_tick, datum/ai_controller/controller)
	return AI_BEHAVIOR_DELAY | AI_BEHAVIOR_SUCCEEDED

/datum/ai_behavior/step_away/finish_action(datum/ai_controller/controller, succeeded)
	. = ..()
	controller.change_ai_movement_type(initial(controller.ai_movement))

/// Pursue a target until we are within a provided range
/datum/ai_behavior/pursue_to_range
	behavior_flags = AI_BEHAVIOR_REQUIRE_MOVEMENT | AI_BEHAVIOR_CAN_PLAN_DURING_EXECUTION | AI_BEHAVIOR_MOVE_AND_PERFORM

/datum/ai_behavior/pursue_to_range/setup(datum/ai_controller/controller, target_key, range)
	. = ..()
	var/atom/current_target = controller.blackboard[target_key]
	if (QDELETED(current_target))
		return FALSE
	if (get_dist(controller.pawn, current_target) <= range)
		return FALSE
	set_movement_target(controller, current_target)

/datum/ai_behavior/pursue_to_range/perform(seconds_per_tick, datum/ai_controller/controller, target_key, range)
	var/atom/current_target = controller.blackboard[target_key]
	if (!QDELETED(current_target) && get_dist(controller.pawn, current_target) > range)
		return AI_BEHAVIOR_INSTANT
	return AI_BEHAVIOR_INSTANT | AI_BEHAVIOR_SUCCEEDED

///instead of taking a single step, we cover the entire distance
/datum/ai_behavior/cover_minimum_distance
	behavior_flags = AI_BEHAVIOR_REQUIRE_MOVEMENT | AI_BEHAVIOR_CAN_PLAN_DURING_EXECUTION
	required_distance = 0
	action_cooldown = 0.2 SECONDS

/datum/ai_behavior/cover_minimum_distance/setup(datum/ai_controller/controller, target_key, minimum_distance)
	. = ..()
	var/atom/target = controller.blackboard[target_key]
	if(QDELETED(target))
		return FALSE
	var/required_distance = minimum_distance - get_dist(controller.pawn, target) //the distance we need to move
	var/distance = 0
	var/turf/chosen_turf
	for(var/turf/open/potential_turf in oview(required_distance, controller.pawn))
		var/new_distance_from_target = get_dist(potential_turf, target)
		if(potential_turf.is_blocked_turf())
			continue
		if(new_distance_from_target > distance)
			chosen_turf = potential_turf
			distance = new_distance_from_target
	if(isnull(chosen_turf))
		return FALSE
	set_movement_target(controller, target = chosen_turf)

/datum/ai_behavior/cover_minimum_distance/perform(seconds_per_tick, datum/ai_controller/controller, target_key)
	return AI_BEHAVIOR_DELAY | AI_BEHAVIOR_SUCCEEDED
