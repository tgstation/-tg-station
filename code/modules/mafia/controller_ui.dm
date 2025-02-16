// 'user' can be a modPC, hence why it's pathed to the atom
/datum/mafia_controller/ui_static_data(atom/user)
	var/list/data = list()

	if(usr?.client?.holder)
		data["admin_controls"] = TRUE //show admin buttons to start/setup/stop
	data["is_observer"] = isobserver(user)
	data["all_roles"] = current_setup_text

	if(phase == MAFIA_PHASE_SETUP)
		return data

	var/datum/mafia_role/user_role = get_role_player(user)
	if(user_role)
		data["roleinfo"] = list(
			"role" = user_role.name,
			"desc" = user_role.desc,
			"hud_icon" = user_role.hud_icon,
			"revealed_icon" = user_role.revealed_icon,
		)

	return data

// 'user' can be a modPC, hence why it's pathed to the atom
/datum/mafia_controller/ui_data(atom/user)
	var/list/data = list()

	data["phase"] = phase
	if(turn)
		data["turn"] = " - Day [turn]"

	if(phase == MAFIA_PHASE_JUDGEMENT)
		data["person_voted_up_ref"] = REF(on_trial)
	if(phase == MAFIA_PHASE_SETUP)
		data["lobbydata"] = list()
		for(var/key in GLOB.mafia_signup + GLOB.mafia_bad_signup + GLOB.pda_mafia_signup)
			var/list/lobby_member = list()
			lobby_member["name"] = key
			lobby_member["status"] = (key in GLOB.mafia_bad_signup) ? "Disconnected" : "Ready"
			data["lobbydata"] += list(lobby_member)
		return data

	data["timeleft"] = next_phase_timer ? timeleft(next_phase_timer) : 0

	var/datum/mafia_role/user_role = get_role_player(user)

	if(user_role)
		data["user_notes"] = user_role.written_notes
		data["player_voted_up"] = (user_role == on_trial)
		var/list/ui_messages = list()
		for(var/i = user_role.role_messages.len to 1 step -1)
			ui_messages.Add(list(list(
				"msg" = user_role.role_messages[i],
			)))
		data["messages"] = ui_messages

	data["players"] = list()
	for(var/datum/mafia_role/role as anything in all_roles)
		var/list/player_info = list()
		player_info["name"] = role.body.real_name
		player_info["ref"] = REF(role)
		player_info["alive"] = role.game_status == MAFIA_ALIVE
		player_info["role_revealed"] = FALSE
		if(role.role_flags & ROLE_REVEALED)
			player_info["role_revealed"] = role.name
		player_info["possible_actions"] = list()

		if(user_role) //not observer
			player_info["is_you"] = (role.body.real_name == user_role.body.real_name)
			for(var/datum/mafia_ability/action as anything in user_role.role_unique_actions)
				if(action.validate_action_target(src, potential_target = role, silent = TRUE))
					player_info["possible_actions"] += list(list("name" = action, "ref" = REF(action)))

		data["players"] += list(player_info)

	return data

/datum/mafia_controller/ui_assets(mob/user)
	return list(
		get_asset_datum(/datum/asset/spritesheet_batched/mafia),
	)

/datum/mafia_controller/ui_act(action, list/params, datum/tgui/ui, datum/ui_state/state)
	. = ..()
	if(.)
		return
	var/datum/mafia_role/user_role = get_role_player(usr, ui)
	var/obj/item/modular_computer/modpc = ui.src_object
	if(!istype(modpc))
		modpc = null
	//Admin actions
	if(ui.user.client.holder)
		switch(action)
			if("new_game")
				if(phase == MAFIA_PHASE_SETUP)
					return
				basic_setup()
			if("nuke")
				qdel(src)
			if("next_phase")
				if(phase == MAFIA_PHASE_SETUP)
					return
				var/datum/timedevent/timer = SStimer.timer_id_dict[next_phase_timer]
				if(!timer.spent)
					var/datum/callback/tc = timer.callBack
					deltimer(next_phase_timer)
					tc.InvokeAsync()
				return TRUE
			if("players_home")
				var/list/failed = list()
				for(var/datum/mafia_role/player in all_roles)
					if(!player.body)
						failed += player
						continue
					player.body.forceMove(get_turf(player.assigned_landmark))
				if(failed.len)
					to_chat(usr, "List of players who no longer had a body (if you see this, the game is runtiming anyway so just hit \"New Game\" to end it)")
					for(var/datum/mafia_role/fail as anything in failed)
						to_chat(usr, fail.player_key || fail.player_pda)
			if("debug_setup")
				var/list/debug_setup = list()
				var/list/rolelist_dict = list("CANCEL", "FINISH") + GLOB.mafia_roles_by_name
				var/done = FALSE

				while(!done)
					to_chat(usr, "You have a total player count of [assoc_value_sum(debug_setup)] in this setup.")
					var/chosen_role_name = tgui_input_list(usr, "Select a role!", "Custom Setup Creation", rolelist_dict)
					if(!chosen_role_name)
						return
					switch(chosen_role_name)
						if("CANCEL")
							done = TRUE
							return
						if("FINISH")
							done = TRUE
							break
						else
							var/found_path = rolelist_dict[chosen_role_name]
							var/role_count = tgui_input_number(usr, "How many? Zero to cancel.", "Custom Setup Creation", 0, 12)
							if(role_count > 0)
								debug_setup[found_path] = role_count
				custom_setup = debug_setup
				early_start = TRUE
				try_autostart()//don't worry, this fails if there's a game in progress
			if("cancel_setup")
				custom_setup = list()
			if("start_now")
				forced_setup()

	switch(action) //both living and dead
		if("mf_lookup")
			var/role_lookup = params["role_name"]
			var/datum/mafia_role/helper
			for(var/datum/mafia_role/role as anything in all_roles)
				if(role_lookup == role.name)
					helper = role
					break
			helper.show_help(usr)

	if(!user_role)//just the dead
		switch(action)
			if("mf_signup")
				if(signup_mafia(usr, ui.user.client, modpc))
					return TRUE
			if("vote_to_start")
				var/client/ghost_client = ui.user.client
				if(phase != MAFIA_PHASE_SETUP)
					to_chat(usr, span_notice("You cannot vote to start while a game is underway!"))
					return
				if(isnull(modpc))
					if(!GLOB.mafia_signup[ghost_client.ckey])
						to_chat(usr, span_notice("You must be signed up for this game to vote!"))
						return
					if(GLOB.mafia_early_votes[ghost_client.ckey])
						GLOB.mafia_early_votes -= ghost_client.ckey
						to_chat(usr, span_notice("You are no longer voting to start the game early."))
					else
						GLOB.mafia_early_votes[ghost_client.ckey] = ghost_client
						to_chat(usr, span_notice("You vote to start the game early ([length(GLOB.mafia_early_votes)] out of [max(round(length(GLOB.mafia_signup + GLOB.pda_mafia_signup) / 2), round(MAFIA_MIN_PLAYER_COUNT / 2))])."))
						if(check_start_votes()) //See if we have enough votes to start
							forced_setup()
				else
					if(!GLOB.pda_mafia_signup[modpc])
						to_chat(usr, span_notice("You must be signed up for this game to vote!"))
						return
					if(GLOB.mafia_early_votes[modpc])
						GLOB.mafia_early_votes -= modpc
						to_chat(usr, span_notice("You are no longer voting to start the game early."))
					else
						GLOB.mafia_early_votes[modpc] = modpc
						to_chat(usr, span_notice("You vote to start the game early ([length(GLOB.mafia_early_votes)] out of [max(round(length(GLOB.mafia_signup + GLOB.pda_mafia_signup) / 2), round(MAFIA_MIN_PLAYER_COUNT / 2))])."))
						if(check_start_votes()) //See if we have enough votes to start
							forced_setup()
				return TRUE

	if(user_role && user_role.game_status == MAFIA_DEAD)
		return

	//User actions (just living)
	switch(action)
		if("change_notes")
			if(user_role.game_status == MAFIA_DEAD)
				return TRUE
			user_role.written_notes = sanitize_text(params["new_notes"])
			user_role.send_message_to_player("notes saved", balloon_alert = TRUE)
			return TRUE
		if("send_message_to_chat")
			if(user_role.game_status == MAFIA_DEAD)
				return TRUE
			var/message_said = sanitize_text(params["message"])
			user_role.body.say(message_said, forced = "mafia chat (sent by [ui.user.client])")
			return TRUE
		if("send_notes_to_chat")
			if(user_role.game_status == MAFIA_DEAD || !user_role.written_notes)
				return TRUE
			if(phase == MAFIA_PHASE_NIGHT)
				return TRUE
			if(!COOLDOWN_FINISHED(user_role, note_chat_sending_cooldown))
				return FALSE
			COOLDOWN_START(user_role, note_chat_sending_cooldown, MAFIA_NOTE_SENDING_COOLDOWN)
			user_role.body.say("[user_role.written_notes]", forced = "mafia notes sending")
			return TRUE
		if("perform_action")
			var/datum/mafia_role/target = locate(params["target"]) in all_roles
			if(!istype(target))
				return
			var/datum/mafia_ability/used_action = locate(params["action_ref"]) in user_role.role_unique_actions
			if(!used_action)
				return
			switch(phase)
				if(MAFIA_PHASE_DAY, MAFIA_PHASE_VOTING)
					used_action.using_ability = TRUE
					used_action.perform_action_target(src, target)
				if(MAFIA_PHASE_NIGHT)
					used_action.set_target(src, target)
			return TRUE

	if(user_role != on_trial)
		switch(action)
			if("vote_abstain")
				if(phase != MAFIA_PHASE_JUDGEMENT || (user_role in judgement_abstain_votes))
					return
				user_role.send_message_to_player("You have decided to abstain.")
				judgement_innocent_votes -= user_role
				judgement_guilty_votes -= user_role
				judgement_abstain_votes += user_role
			if("vote_innocent")
				if(phase != MAFIA_PHASE_JUDGEMENT || (user_role in judgement_innocent_votes))
					return
				user_role.send_message_to_player("Your vote on [on_trial.body.real_name] submitted as INNOCENT!")
				judgement_abstain_votes -= user_role//no fakers, and...
				judgement_guilty_votes -= user_role//no radical centrism
				judgement_innocent_votes += user_role
			if("vote_guilty")
				if(phase != MAFIA_PHASE_JUDGEMENT || (user_role in judgement_guilty_votes))
					return
				user_role.send_message_to_player("Your vote on [on_trial.body.real_name] submitted as GUILTY!")
				judgement_abstain_votes -= user_role//no fakers, and...
				judgement_innocent_votes -= user_role//no radical centrism
				judgement_guilty_votes += user_role

/datum/mafia_controller/ui_state(mob/user)
	return GLOB.always_state

/datum/mafia_controller/ui_interact(mob/user, datum/tgui/ui)
	ui = SStgui.try_update_ui(user, src, null)
	if(!ui)
		ui = new(user, src, "MafiaPanel")
		ui.open()
