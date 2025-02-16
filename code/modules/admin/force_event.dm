
ADMIN_VERB(force_event, R_FUN, "Trigger Event", "Forces an event to occur.", ADMIN_CATEGORY_EVENTS)
	user.holder.forceEvent()

///Opens up the Force Event Panel
/datum/admins/proc/forceEvent()
	if(!check_rights(R_FUN))
		return

	var/datum/force_event/ui = new(usr)
	ui.ui_interact(usr)

/// Force Event Panel
/datum/force_event

/datum/force_event/ui_interact(mob/user, datum/tgui/ui)
	ui = SStgui.try_update_ui(user, src, ui)
	if(!ui)
		ui = new(user, src, "ForceEvent")
		ui.open()

/datum/force_event/ui_state(mob/user)
	return ADMIN_STATE(R_FUN)

/datum/force_event/ui_static_data(mob/user)
	var/static/list/category_to_icons
	if(!category_to_icons)
		category_to_icons = list(
			EVENT_CATEGORY_AI = "robot",
			EVENT_CATEGORY_ANOMALIES = "cloud-bolt",
			EVENT_CATEGORY_BUREAUCRATIC = "print",
			EVENT_CATEGORY_ENGINEERING = "wrench",
			EVENT_CATEGORY_ENTITIES = "ghost",
			EVENT_CATEGORY_FRIENDLY = "face-smile",
			EVENT_CATEGORY_HEALTH = "brain",
			EVENT_CATEGORY_HOLIDAY = "calendar",
			EVENT_CATEGORY_INVASION = "user-group",
			EVENT_CATEGORY_JANITORIAL = "bath",
			EVENT_CATEGORY_SPACE = "meteor",
			EVENT_CATEGORY_WIZARD = "hat-wizard",
		)
	var/list/data = list()

	var/list/categories_seen = list()
	var/list/categories = list()

	var/list/events = list()

	for(var/datum/round_event_control/event_control as anything in SSevents.control)
		//add category
		if(!categories_seen[event_control.category])
			categories_seen[event_control.category] = TRUE
			UNTYPED_LIST_ADD(categories, list(
				"name" = event_control.category,
				"icon" = category_to_icons[event_control.category],
			))
		//add event, with one value matching up the category
		UNTYPED_LIST_ADD(events, list(
			"name" = event_control.name,
			"description" = event_control.description,
			"type" = event_control.type,
			"category" = event_control.category,
			"has_customization" = !!length(event_control.admin_setup),
		))
	data["categories"] = categories
	data["events"] = events
	return data

/datum/force_event/ui_act(action, list/params, datum/tgui/ui, datum/ui_state/state)
	if(..())
		return
	if(!check_rights(R_FUN))
		return
	switch(action)
		if("forceevent")
			var/announce_event = params["announce"]
			var/string_path = params["type"]
			if(!string_path)
				return
			var/event_to_run_type = text2path(string_path)
			if(!event_to_run_type)
				return
			var/datum/round_event_control/event = locate(event_to_run_type) in SSevents.control
			if(!event)
				return
			if(length(event.admin_setup))
				for(var/datum/event_admin_setup/admin_setup_datum as anything in event.admin_setup)
					if(admin_setup_datum.prompt_admins() == ADMIN_CANCEL_EVENT)
						return
			var/always_announce_chance = 100
			var/no_announce_chance = 0
			event.run_event(announce_chance_override = announce_event ? always_announce_chance : no_announce_chance, admin_forced = TRUE)
			message_admins("[key_name_admin(usr)] has triggered an event. ([event.name])")
			log_admin("[key_name(usr)] has triggered an event. ([event.name])")
