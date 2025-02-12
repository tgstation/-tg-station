ADMIN_VERB(debug_traitor_objectives, R_DEBUG, "Debug Traitor Objectives", "Verify functionality of traitor goals.", ADMIN_CATEGORY_DEBUG)
	SStraitor.traitor_debug_panel?.ui_interact(user.mob)

/datum/traitor_objective_debug
	var/list/all_objectives

/datum/traitor_objective_debug/New(datum/traitor_category_handler/category_handler)
	. = ..()
	all_objectives = list()
	for(var/datum/traitor_objective_category/category as anything in category_handler.all_categories)
		var/list/generated_list = list()
		var/list/current_list = category.objectives
		for(var/value in category.objectives)
			if(islist(value))
				generated_list += list(list(
					"objectives" = recursive_list_generate(value),
					"weight" = current_list[value]
				))
			else
				generated_list += list(generate_objective_data(value, current_list[value]))
		all_objectives += list(list(
			"name" = category.name,
			"objectives" = generated_list,
			"weight" = category.weight,
		))

/datum/traitor_objective_debug/proc/recursive_list_generate(list/to_check)
	var/list/generated_list = list()
	for(var/value in to_check)
		if(islist(value))
			generated_list += list(list(
				"objectives" = recursive_list_generate(value),
				"weight" = to_check[value]
			))
		else
			generated_list += list(generate_objective_data(value, to_check[value]))
	return generated_list

/datum/traitor_objective_debug/proc/generate_objective_data(datum/traitor_objective/objective_type, weight)
	// Need to set this to false before we create the new objective to prevent init from fucking it up
	SStraitor.generate_objectives = FALSE
	var/datum/traitor_objective/objective = new objective_type()
	var/list/return_data = list(
		"name" = objective.name,
		"description" = objective.description,
		"progression_minimum" = objective.progression_minimum,
		"progression_maximum" = objective.progression_maximum,
		"global_progression" = objective.global_progression_deviance_required,
		"global_progression_limit_coeff" = objective.global_progression_limit_coeff,
		"global_progression_influence_intensity" = objective.global_progression_influence_intensity,
		"progression_reward" = objective.progression_reward,
		"telecrystal_reward" = objective.telecrystal_reward,
		"telecrystal_penalty" = objective.telecrystal_penalty,
		"weight" = weight,
		"type" = objective.type,
	)
	qdel(objective)
	SStraitor.generate_objectives = TRUE
	return return_data

/datum/traitor_objective_debug/ui_interact(mob/user, datum/tgui/ui)
	ui = SStgui.try_update_ui(user, src, ui)
	if(!ui)
		ui = new(user, src, "TraitorObjectiveDebug")
		ui.open()

/datum/traitor_objective_debug/ui_data(mob/user)
	var/list/data = list()
	data["current_progression"] = SStraitor.current_global_progression
	var/list/handlers = SStraitor.uplink_handlers
	var/list/handler_data = list()
	for(var/datum/uplink_handler/handler as anything in handlers)
		var/total_progression_from_objectives = 0
		for(var/datum/traitor_objective/objective as anything in handler.completed_objectives)
			if(objective.objective_state != OBJECTIVE_STATE_COMPLETED)
				continue
			total_progression_from_objectives += objective.progression_reward
		handler_data += list(list(
			"player" = handler.owner?.key,
			"progression_points" = handler.progression_points,
			"total_progression_from_objectives" = total_progression_from_objectives
		))
	data["player_data"] = handler_data
	return data

/datum/traitor_objective_debug/ui_static_data(mob/user)
	var/list/data = list()
	data["objective_data"] = all_objectives
	data["progression_scaling_deviance"] = SStraitor.progression_scaling_deviance
	return data

/datum/traitor_objective_debug/ui_state(mob/user)
	return admin_state(R_DEBUG)

/datum/traitor_objective_debug/ui_act(action, list/params, datum/tgui/ui, datum/ui_state/state)
	. = ..()
	if(.)
		return

	switch(action)
		if("set_current_expected_progression")
			SStraitor.current_global_progression = text2num(params["new_expected_progression"])
			return TRUE
		if("generate_json")
			var/temp_file = file("data/TraitorObjectiveDownloadTempFile")
			fdel(temp_file)
			WRITE_FILE(temp_file, all_objectives)
			DIRECT_OUTPUT(ui.user, ftp(temp_file, "TraitorObjectiveData.json"))
			return TRUE
