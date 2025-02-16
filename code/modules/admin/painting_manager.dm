ADMIN_VERB(painting_manager, R_ADMIN, "Paintings Manager", "View and redact paintings.", ADMIN_CATEGORY_MAIN)
	var/static/datum/paintings_manager/ui = new
	ui.ui_interact(user.mob)

/// Painting Admin Management Panel
/datum/paintings_manager

/datum/paintings_manager/ui_state(mob/user)
	return ADMIN_STATE(R_ADMIN)

/datum/paintings_manager/ui_close(mob/user)
	qdel(src)

/datum/paintings_manager/ui_interact(mob/user, datum/tgui/ui)
	ui = SStgui.try_update_ui(user, src, ui)
	if(!ui)
		ui = new(user, src, "PaintingAdminPanel")
		ui.open()

/datum/paintings_manager/ui_assets(mob/user)
	return list(
		get_asset_datum(/datum/asset/simple/portraits)
	)

/datum/paintings_manager/ui_data(mob/user)
	. = list()
	.["paintings"] = SSpersistent_paintings.painting_ui_data(filter = NONE, admin = TRUE)

/datum/paintings_manager/ui_act(action, list/params, datum/tgui/ui, datum/ui_state/state)
	if(..())
		return
	if (!check_rights(R_ADMIN))
		return
	var/mob/user = usr
	var/datum/painting/chosen_painting = locate(params["ref"]) in SSpersistent_paintings.paintings
	if(!chosen_painting)
		return
	switch(action)
		if("delete")
			//Delete the png file
			var/png = "data/paintings/images/[chosen_painting.md5].png"
			fdel(png)
			//Remove entry from paintings list
			SSpersistent_paintings.paintings -= chosen_painting
			SSpersistent_paintings.deleted_paintings_md5s |= chosen_painting.md5
			SSpersistent_paintings.save_to_file() // Save now so we don't have broken variations if this round crashes
			//Delete any painting instances in the current round
			for(var/obj/structure/sign/painting/painting as anything in SSpersistent_paintings.painting_frames)
				if(painting.current_canvas && painting.current_canvas.painting_metadata == chosen_painting)
					QDEL_NULL(painting.current_canvas)
					painting.update_appearance()
			log_admin("[key_name(user)] has deleted a persistent painting made by [chosen_painting.creator_ckey].")
			message_admins(span_notice("[key_name_admin(user)] has deleted persistent painting made by [chosen_painting.creator_ckey]."))
			return TRUE
		if("rename")
			//Modify the metadata
			var/old_title = chosen_painting.title
			var/new_title = tgui_input_text(user, "New painting title?", "Painting Rename", chosen_painting.title, max_length = MAX_NAME_LEN)
			if(!new_title)
				return
			chosen_painting.title = new_title
			log_admin("[key_name(user)] has renamed a persistent painting made by [chosen_painting.creator_ckey] with id [chosen_painting.md5] from [old_title] to [chosen_painting.title].")
			return TRUE
		if("rename_author")
			var/old_name = chosen_painting.creator_name
			var/new_name = tgui_input_text(user, "New painting author name?", "Painting Rename", chosen_painting.creator_name, max_length = MAX_NAME_LEN)
			if(!new_name)
				return
			chosen_painting.creator_name = new_name
			log_admin("[key_name(user)] has renamed a persistent painting author made by [chosen_painting.creator_name] with id [chosen_painting.md5] from [old_name] to [chosen_painting.creator_name].")
			return TRUE
		if("dumpit")
			//Modify the metadata
			chosen_painting.patron_name = ""
			chosen_painting.patron_ckey = ""
			chosen_painting.credit_value = 0
			chosen_painting.frame_type = initial(chosen_painting.frame_type)
			log_admin("[key_name(user)] has reset patronage data on a persistent painting made by [chosen_painting.creator_ckey] with id [chosen_painting.md5].")
			return TRUE
		if("remove_tag")
			if(chosen_painting.tags)
				chosen_painting.tags -= params["tag"]
			log_admin("[key_name(user)] has removed tag [params["tag"]] from persistent painting made by [chosen_painting.creator_ckey] with id [chosen_painting.md5].")
			return TRUE
		if("add_tag")
			var/tag_name = tgui_input_text(user, "New tag name?", "Add Tag", max_length = MAX_NAME_LEN)
			if(!tag_name)
				return
			if(!chosen_painting.tags)
				chosen_painting.tags = list()
			chosen_painting.tags |= tag_name
			log_admin("[key_name(user)] has added tag [tag_name] to persistent painting made by [chosen_painting.creator_ckey] with id [chosen_painting.md5].")
			return TRUE
