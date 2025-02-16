/datum/skill_panel
	var/datum/mind/targetmind
	var/client/holder //client of whoever is using this datum

/datum/skill_panel/New(user, datum/mind/mind)//H can either be a client or a mob due to byondcode(tm)
	targetmind = mind
	if (istype(user,/client))
		var/client/userClient = user
		holder = userClient //if its a client, assign it to holder
	else
		var/mob/userMob = user
		holder = userMob.client //if its a mob, assign the mob's client to holder

/datum/skill_panel/ui_state(mob/user)
	return ADMIN_STATE(R_ADMIN)

/datum/skill_panel/ui_interact(mob/user, datum/tgui/ui)
	ui = SStgui.try_update_ui(user, src, ui)
	if(!ui)
		ui = new(user, src, "SkillPanel")
		ui.open()

/datum/skill_panel/ui_data(mob/user) //Sends info about the skills to UI
	. = list()
	if(user?.mind)
		for (var/type in GLOB.skill_types)
			var/datum/skill/S = GetSkillRef(type)
			var/lvl_num = targetmind.get_skill_level(type)
			var/lvl_name = uppertext(targetmind.get_skill_level_name(type))
			var/exp = targetmind.get_skill_exp(type)
			var/xp_prog_to_level = targetmind.exp_needed_to_level_up(type)
			var/xp_req_to_level = 0
			if (xp_prog_to_level)//is it even possible to level up?
				xp_req_to_level = SKILL_EXP_LIST[lvl_num+1] - SKILL_EXP_LIST[lvl_num]
			var/exp_percent = exp / SKILL_EXP_LIST[SKILL_LEVEL_LEGENDARY]
			.["skills"] += list(list("playername" = targetmind.current, "path" = type, "name" = S.name, "desc" = S.desc, "lvlnum" = lvl_num, "lvl" = lvl_name, "exp" = exp, "exp_prog" = xp_req_to_level - xp_prog_to_level, "exp_req" = xp_req_to_level, "exp_percent" = exp_percent, "max_exp" = SKILL_EXP_LIST[length(SKILL_EXP_LIST)]))

/datum/skill_panel/ui_act(action, list/params, datum/tgui/ui, datum/ui_state/state)
	. = ..()
	if(.)
		return
	switch (action)
		if ("adj_exp")
			var/skill = text2path(params["skill"])
			var/number = input("Please insert the amount of experience you'd like to add/subtract:") as num|null
			if (number)
				targetmind.adjust_experience(skill, number)
		if ("set_exp")
			var/skill = text2path(params["skill"])
			var/number = input("Please insert the number you want to set the player's exp to:") as num|null
			if (number)
				targetmind.set_experience(skill, number)
		if ("set_lvl")
			var/skill = text2path(params["skill"])
			var/max_skill = length(SKILL_EXP_LIST)
			var/number = input("Please insert a whole number between 1 (NONE) and [max_skill] (LEGENDARY) corresponding to the level you'd like to set the player to.") as num|null
			if (number > 0 && number <= max_skill )
				targetmind.set_level(skill, number)
