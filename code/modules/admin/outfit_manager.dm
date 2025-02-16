ADMIN_VERB(outfit_manager, R_DEBUG|R_ADMIN, "Outfit Manager", "View and edit outfits.", ADMIN_CATEGORY_DEBUG)
	var/static/datum/outfit_manager/ui = new
	ui.ui_interact(user.mob)

/datum/outfit_manager

/datum/outfit_manager/ui_state(mob/user)
	return ADMIN_STATE(R_DEBUG | R_ADMIN)

/datum/outfit_manager/ui_interact(mob/user, datum/tgui/ui)
	ui = SStgui.try_update_ui(user, src, ui)
	if(!ui)
		ui = new(user, src, "OutfitManager")
		ui.open()

/datum/outfit_manager/proc/entry(datum/outfit/outfit)
	var/vv = FALSE
	var/datum/outfit/varedit/varoutfit = outfit
	if(istype(varoutfit))
		vv = length(varoutfit.vv_values)
	return list(
		"name" = "[outfit.name] [vv ? "(VV)" : ""]",
		"ref" = REF(outfit),
	)

/datum/outfit_manager/ui_data(mob/user)
	var/list/data = list()

	var/list/outfits = list()
	for(var/datum/outfit/custom_outfit in GLOB.custom_outfits)
		outfits += list(entry(custom_outfit))
	data["outfits"] = outfits

	return data

/datum/outfit_manager/ui_act(action, list/params, datum/tgui/ui, datum/ui_state/state)
	if(..())
		return
	. = TRUE

	switch(action)
		if("new")
			ui.user.client.open_outfit_editor(new /datum/outfit)
		if("load")
			ui.user.client.holder.load_outfit(ui.user)
		if("copy")
			var/datum/outfit/outfit = tgui_input_list(ui.user, "Pick an outfit to copy from", "Outfit Manager", subtypesof(/datum/outfit))
			if(isnull(outfit))
				return
			if(!ispath(outfit))
				return
			ui.user.client.open_outfit_editor(new outfit)

	var/datum/outfit/target_outfit = locate(params["outfit"])
	if(!istype(target_outfit))
		return
	switch(action) //wow we're switching through action again this is horrible optimization smh
		if("edit")
			ui.user.client.open_outfit_editor(target_outfit)
		if("save")
			ui.user.client.holder.save_outfit(ui.user, target_outfit)
		if("delete")
			ui.user.client.holder.delete_outfit(ui.user, target_outfit)
