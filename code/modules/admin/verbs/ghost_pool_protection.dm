//very similar to centcom_podlauncher in terms of how this is coded, so i kept a lot of comments from it

ADMIN_VERB(ghost_pool_protection, R_ADMIN, "Ghost Pool Protection", "Choose which ways people can get into the round, or just clear it out completely for admin events.", ADMIN_CATEGORY_EVENTS)
	var/datum/ghost_pool_menu/tgui = new(user)
	tgui.ui_interact(user.mob)

/datum/ghost_pool_menu
	var/client/holder //client of whoever is using this datum

	//when submitted, what the pool flags will be set to
	var/new_role_flags = ALL

	//EVERY TYPE OF WAY SOMEONE IS GETTING BACK INTO THE ROUND!
	//these are the same comments as the ones in admin.dm defines, please update those if you change them here
	/*
	var/events_or_midrounds = TRUE //ie fugitives, space dragon, etc. also includes dynamic midrounds as it's the same deal
	var/spawners = TRUE //ie ashwalkers, free golems, beach bums
	var/station_sentience = TRUE //ie posibrains, mind monkeys, sentience potion, etc.
	var/minigames = TRUE //ie mafia, ctf
	var/misc = TRUE //oddities like split personality and any animal ones like spiders, xenos
	*/

/datum/ghost_pool_menu/New(user)//user can either be a client or a mob due to byondcode(tm)
	if (istype(user, /client))
		var/client/user_client = user
		holder = user_client //if its a client, assign it to holder
	else
		var/mob/user_mob = user
		holder = user_mob.client //if its a mob, assign the mob's client to holder
	new_role_flags = GLOB.ghost_role_flags

/datum/ghost_pool_menu/ui_state(mob/user)
	return ADMIN_STATE(R_ADMIN)

/datum/ghost_pool_menu/ui_close()
	qdel(src)

/datum/ghost_pool_menu/ui_interact(mob/user, datum/tgui/ui)
	ui = SStgui.try_update_ui(user, src, ui)
	if(!ui)
		ui = new(user, src, "GhostPoolProtection")
		ui.open()

/datum/ghost_pool_menu/ui_data(mob/user)
	var/list/data = list()
	data["events_or_midrounds"] = (new_role_flags & GHOSTROLE_MIDROUND_EVENT)
	data["spawners"] = (new_role_flags & GHOSTROLE_SPAWNER)
	data["station_sentience"] = (new_role_flags & GHOSTROLE_STATION_SENTIENCE)
	data["silicons"] = (new_role_flags & GHOSTROLE_SILICONS)
	data["minigames"] = (new_role_flags & GHOSTROLE_MINIGAME)
	return data

/datum/ghost_pool_menu/ui_act(action, list/params, datum/tgui/ui, datum/ui_state/state)
	. = ..()
	if(.)
		return
	. = TRUE
	switch(action)
		if("toggle_events_or_midrounds")
			new_role_flags ^= GHOSTROLE_MIDROUND_EVENT
		if("toggle_spawners")
			new_role_flags ^= GHOSTROLE_SPAWNER
		if("toggle_station_sentience")
			new_role_flags ^= GHOSTROLE_STATION_SENTIENCE
		if("toggle_silicons")
			new_role_flags ^= GHOSTROLE_SILICONS
		if("toggle_minigames")
			new_role_flags ^= GHOSTROLE_MINIGAME
		if("all_roles")
			new_role_flags = ALL
		if("no_roles")
			new_role_flags = NONE
		if("apply_settings")
			to_chat(usr, "Settings Applied!")
			var/msg
			switch(new_role_flags)
				if(ALL)
					msg = "enabled all of"
				if(NONE)
					msg = "disabled all of"
				else
					msg = "modified"
			message_admins("[key_name_admin(holder)] has [msg] this round's allowed ghost roles.")
			GLOB.ghost_role_flags = new_role_flags
