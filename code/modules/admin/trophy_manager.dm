ADMIN_VERB(trophy_manager, R_ADMIN, "Trophy Manager", "View all trophies.", ADMIN_CATEGORY_MAIN)
	var/static/datum/trophy_manager/ui = new
	ui.ui_interact(user.mob)

/// Trophy Admin Management Panel
/datum/trophy_manager

/datum/trophy_manager/ui_state(mob/user)
	return ADMIN_STATE(R_ADMIN)

/datum/trophy_manager/ui_close(mob/user)
	qdel(src)

/datum/trophy_manager/ui_interact(mob/user, datum/tgui/ui)
	ui = SStgui.try_update_ui(user, src, ui)
	if(!ui)
		ui = new(user, src, "TrophyAdminPanel")
		ui.open()

/datum/trophy_manager/ui_data(mob/user)
	var/list/data = list()
	data["trophies"] = SSpersistence.trophy_ui_data()
	return data

/datum/trophy_manager/ui_act(action, list/params, datum/tgui/ui, datum/ui_state/state)
	if(..())
		return
	if (!check_rights(R_ADMIN))
		return
	var/mob/user = usr
	var/datum/trophy_data/trophy = locate(params["ref"]) in SSpersistence.saved_trophies
	if(!trophy)
		return
	switch(action)
		if("delete")
			SSpersistence.saved_trophies -= trophy
			log_admin("[key_name(user)] has deleted a trophy made by [trophy.placer_key].")
			message_admins(span_notice("[key_name_admin(user)] has deleted trophy made by [trophy.placer_key]."))
			return TRUE
		if("edit_message")
			var/old_message = trophy.message
			var/new_message = tgui_input_text(user, "New trophy message?", "Message Editing", trophy.message, max_length = MAX_PLAQUE_LEN)
			if(!new_message)
				return
			trophy.message = new_message
			log_admin("[key_name(user)] has edited the message of trophy made by [trophy.placer_key] from \"[old_message]\" to \"[new_message]\".")
			return TRUE
		if("edit_path")
			var/old_path = trophy.path
			var/new_path = tgui_input_text(user, "New trophy path?", "Path Editing", trophy.path)
			if(!new_path)
				return
			if(!text2path(new_path))
				to_chat(user, span_warning("Invalid path selected"))
				return
			trophy.path = new_path
			log_admin("[key_name(user)] has edited the item path of trophy made by [trophy.placer_key] from \"[old_path]\" to \"[new_path]\".")
			return TRUE
