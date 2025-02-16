/datum/filter_editor
	var/atom/target

/datum/filter_editor/New(atom/target)
	src.target = target

/datum/filter_editor/ui_state(mob/user)
	return ADMIN_STATE(R_VAREDIT)

/datum/filter_editor/ui_interact(mob/user, datum/tgui/ui)
	ui = SStgui.try_update_ui(user, src, ui)
	if(!ui)
		ui = new(user, src, "Filteriffic")
		ui.open()

/datum/filter_editor/ui_static_data(mob/user)
	var/list/data = list()
	data["filter_info"] = GLOB.master_filter_info
	return data

/datum/filter_editor/ui_data()
	var/list/data = list()
	data["target_name"] = target.name
	data["target_filter_data"] = target.filter_data
	return data

/datum/filter_editor/ui_act(action, list/params, datum/tgui/ui, datum/ui_state/state)
	. = ..()
	if(.)
		return

	switch(action)
		if("add_filter")
			var/target_name = params["name"]
			while(target.filter_data && target.filter_data[target_name])
				target_name = "[target_name]-dupe"
			target.add_filter(target_name, params["priority"], list("type" = params["type"]))
			. = TRUE
		if("remove_filter")
			target.remove_filter(params["name"])
			. = TRUE
		if("rename_filter")
			var/list/filter_data = target.filter_data[params["name"]]
			target.remove_filter(params["name"])
			target.add_filter(params["new_name"], filter_data["priority"], filter_data)
			. = TRUE
		if("edit_filter")
			target.remove_filter(params["name"])
			target.add_filter(params["name"], params["priority"], params["new_filter"])
			. = TRUE
		if("change_priority")
			var/new_priority = params["new_priority"]
			target.change_filter_priority(params["name"], new_priority)
			. = TRUE
		if("transition_filter_value")
			target.transition_filter(params["name"], params["new_data"], 4)
			. = TRUE
		if("modify_filter_value")
			var/list/old_filter_data = target.filter_data[params["name"]]
			var/list/new_filter_data = old_filter_data.Copy()
			for(var/entry in params["new_data"])
				new_filter_data[entry] = params["new_data"][entry]
			for(var/entry in new_filter_data)
				if(entry == GLOB.master_filter_info[old_filter_data["type"]]["defaults"][entry])
					new_filter_data.Remove(entry)
			target.remove_filter(params["name"])
			target.add_filter(params["name"], old_filter_data["priority"], new_filter_data)
			. = TRUE
		if("modify_color_value")
			var/new_color = input(usr, "Pick new filter color", "Filteriffic Colors!") as color|null
			if(new_color)
				target.transition_filter(params["name"], list("color" = new_color), 4)
				. = TRUE
		if("modify_icon_value")
			var/icon/new_icon = input("Pick icon:", "Icon") as null|icon
			if(new_icon)
				target.filter_data[params["name"]]["icon"] = new_icon
				target.update_filters()
				. = TRUE
		if("mass_apply")
			if(!check_rights_for(usr.client, R_FUN))
				to_chat(usr, span_userdanger("Stay in your lane, jannie."))
				return
			var/target_path = text2path(params["path"])
			if(!target_path)
				return
			var/filters_to_copy = target.filters
			var/filter_data_to_copy = target.filter_data
			var/count = 0
			for(var/thing in world.contents)
				if(istype(thing, target_path))
					var/atom/thing_at = thing
					thing_at.filters = filters_to_copy
					thing_at.filter_data = filter_data_to_copy
					count += 1
			message_admins("LOCAL CLOWN [usr.ckey] JUST MASS FILTER EDITED [count] WITH PATH OF [params["path"]]!")
			log_admin("LOCAL CLOWN [usr.ckey] JUST MASS FILTER EDITED [count] WITH PATH OF [params["path"]]!")


