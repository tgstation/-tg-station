////////////////////////////////
/proc/message_admins(msg)
	msg = "<span class=\"admin\"><span class=\"prefix\">ADMIN LOG:</span> <span class=\"message\">[msg]</span></span>"
	to_chat(GLOB.admins,
		type = MESSAGE_TYPE_ADMINLOG,
		html = msg,
		confidential = TRUE)

/proc/relay_msg_admins(msg)
	msg = "<span class=\"admin\"><span class=\"prefix\">RELAY:</span> <span class=\"message\">[msg]</span></span>"
	to_chat(GLOB.admins,
		type = MESSAGE_TYPE_ADMINLOG,
		html = msg,
		confidential = TRUE)

///////////////////////////////////////////////////////////////////////////////////////////////Panels

/datum/admins/proc/Game()
	if(!check_rights(0))
		return

	var/dat
	if(SSticker.current_state <= GAME_STATE_PREGAME)
		dat += "<A href='byond://?src=[REF(src)];[HrefToken()];f_dynamic_ruleset_manage=1'>(Manage Dynamic Rulesets)</A><br>"
		dat += "<A href='byond://?src=[REF(src)];[HrefToken()];f_dynamic_roundstart=1'>(Force Roundstart Rulesets)</A><br>"
		if (GLOB.dynamic_forced_roundstart_ruleset.len > 0)
			for(var/datum/dynamic_ruleset/roundstart/rule in GLOB.dynamic_forced_roundstart_ruleset)
				dat += {"<A href='byond://?src=[REF(src)];[HrefToken()];f_dynamic_roundstart_remove=[text_ref(rule)]'>-> [rule.name] <-</A><br>"}
			dat += "<A href='byond://?src=[REF(src)];[HrefToken()];f_dynamic_roundstart_clear=1'>(Clear Rulesets)</A><br>"
		dat += "<A href='byond://?src=[REF(src)];[HrefToken()];f_dynamic_options=1'>(Dynamic mode options)</A><br>"
		dat += "<hr/>"
	if(SSticker.IsRoundInProgress())
		dat += "<a href='byond://?src=[REF(src)];[HrefToken()];gamemode_panel=1'>(Game Mode Panel)</a><BR>"
		dat += "<A href='byond://?src=[REF(src)];[HrefToken()];f_dynamic_ruleset_manage=1'>(Manage Dynamic Rulesets)</A><br>"
		dat += "<hr/>"
	dat += {"
		<A href='byond://?src=[REF(src)];[HrefToken()];create_object=1'>Create Object</A><br>
		<A href='byond://?src=[REF(src)];[HrefToken()];quick_create_object=1'>Quick Create Object</A><br>
		<A href='byond://?src=[REF(src)];[HrefToken()];create_turf=1'>Create Turf</A><br>
		<A href='byond://?src=[REF(src)];[HrefToken()];create_mob=1'>Create Mob</A><br>
		"}

	if(marked_datum && istype(marked_datum, /atom))
		dat += "<A href='byond://?src=[REF(src)];[HrefToken()];dupe_marked_datum=1'>Duplicate Marked Datum</A><br>"

	var/datum/browser/browser = new(usr, "admin2", "Game Panel", 240, 280)
	browser.set_content(dat)
	browser.open()
	return

////////////////////////////////////////////////////////////////////////////////////////////////ADMIN HELPER PROCS

ADMIN_VERB(spawn_atom, R_SPAWN, "Spawn", "Spawn an atom.", ADMIN_CATEGORY_DEBUG, object as text)
	if(!object)
		return
	var/list/preparsed = splittext(object,":")
	var/path = preparsed[1]
	var/amount = 1
	if(preparsed.len > 1)
		amount = clamp(text2num(preparsed[2]),1,ADMIN_SPAWN_CAP)

	var/chosen = pick_closest_path(path)
	if(!chosen)
		return
	var/turf/T = get_turf(user.mob)

	if(ispath(chosen, /turf))
		T.ChangeTurf(chosen)
	else
		for(var/i in 1 to amount)
			var/atom/A = new chosen(T)
			A.flags_1 |= ADMIN_SPAWNED_1

	log_admin("[key_name(user)] spawned [amount] x [chosen] at [AREACOORD(user.mob)]")
	BLACKBOX_LOG_ADMIN_VERB("Spawn Atom")

ADMIN_VERB(spawn_atom_pod, R_SPAWN, "PodSpawn", "Spawn an atom via supply drop.", ADMIN_CATEGORY_DEBUG, object as text)
	var/chosen = pick_closest_path(object)
	if(!chosen)
		return
	var/turf/target_turf = get_turf(user.mob)

	if(ispath(chosen, /turf))
		target_turf.ChangeTurf(chosen)
	else
		var/obj/structure/closet/supplypod/pod = podspawn(list(
			"target" = target_turf,
			"path" = /obj/structure/closet/supplypod/centcompod,
		))
		//we need to set the admin spawn flag for the spawned items so we do it outside of the podspawn proc
		var/atom/A = new chosen(pod)
		A.flags_1 |= ADMIN_SPAWNED_1

	log_admin("[key_name(user)] pod-spawned [chosen] at [AREACOORD(user.mob)]")
	BLACKBOX_LOG_ADMIN_VERB("Podspawn Atom")

ADMIN_VERB(spawn_cargo, R_SPAWN, "Spawn Cargo", "Spawn a cargo crate.", ADMIN_CATEGORY_DEBUG, object as text)
	var/chosen = pick_closest_path(object, make_types_fancy(subtypesof(/datum/supply_pack)))
	if(!chosen)
		return
	var/datum/supply_pack/S = new chosen
	S.admin_spawned = TRUE
	S.generate(get_turf(user.mob))

	log_admin("[key_name(user)] spawned cargo pack [chosen] at [AREACOORD(user.mob)]")
	BLACKBOX_LOG_ADMIN_VERB("Spawn Cargo")

/datum/admins/proc/dynamic_mode_options(mob/user)
	var/dat = {"<h3>Common options</h3>
		<i>All these options can be changed midround.</i> <br/>
		<br/>
		<b>Force extended:</b> - Option is <a href='byond://?src=[REF(src)];[HrefToken()];f_dynamic_force_extended=1'> <b>[GLOB.dynamic_forced_extended ? "ON" : "OFF"]</a></b>.
		<br/>This will force the round to be extended. No rulesets will be drafted. <br/>
		<br/>
		<b>No stacking:</b> - Option is <a href='byond://?src=[REF(src)];[HrefToken()];f_dynamic_no_stacking=1'> <b>[GLOB.dynamic_no_stacking ? "ON" : "OFF"]</b></a>.
		<br/>Unless the threat goes above [GLOB.dynamic_stacking_limit], only one "round-ender" ruleset will be drafted. <br/>
		<br/>
		<b>Forced threat level:</b> Current value : <a href='byond://?src=[REF(src)];[HrefToken()];f_dynamic_forced_threat=1'><b>[GLOB.dynamic_forced_threat_level]</b></a>.
		<br/>The value threat is set to if it is higher than -1.<br/>
		<br/>
		<br/>
		<b>Stacking threeshold:</b> Current value : <a href='byond://?src=[REF(src)];[HrefToken()];f_dynamic_stacking_limit=1'><b>[GLOB.dynamic_stacking_limit]</b></a>.
		<br/>The threshold at which "round-ender" rulesets will stack. A value higher than 100 ensure this never happens. <br/>
	"}

	var/datum/browser/browser = new(user, "dyn_mode_options", "Dynamic Mode Options", 900, 650)
	browser.set_content(dat)
	browser.open()

/datum/admins/proc/dynamic_ruleset_manager(mob/user)
	var/datum/browser/browser = new(user, "dyn_mode_options", "Dynamic Ruleset Management", 900, 650)
	var/dat = {"
		Change these options to forcibly enable or disable dynamic rulesets.<br/>
		Disabled rulesets will never run, even if they would otherwise be valid.<br/>
		Enabled rulesets will run even if the qualifying minimum of threat or player count is not present, this does not guarantee that they will necessarily be chosen (for example their weight may be set to 0 in config).<br/>
		<A href='byond://?src=[REF(src)];[HrefToken()];f_dynamic_ruleset_force_all_on=1'>force enable all</A>
		<A href='byond://?src=[REF(src)];[HrefToken()];f_dynamic_ruleset_force_all_off=1'>force disable all</A>
		<A href='byond://?src=[REF(src)];[HrefToken()];f_dynamic_ruleset_force_all_reset=1'>reset all</A>
	"}

	if (SSticker.current_state <= GAME_STATE_PREGAME) // Don't bother displaying after the round has started
		var/static/list/rulesets_by_context = list()
		if (!length(rulesets_by_context))
			for (var/datum/dynamic_ruleset/rule as anything in subtypesof(/datum/dynamic_ruleset))
				if (initial(rule.name) == "")
					continue
				LAZYADD(rulesets_by_context[initial(rule.ruletype)], rule)

		dat += dynamic_ruleset_category_pre_start_display("Roundstart", rulesets_by_context[ROUNDSTART_RULESET])
		dat += dynamic_ruleset_category_pre_start_display("Latejoin", rulesets_by_context[LATEJOIN_RULESET])
		dat += dynamic_ruleset_category_pre_start_display("Midround", rulesets_by_context[MIDROUND_RULESET])
		browser.set_content(dat)
		browser.open()
		return

	var/pop_count = length(GLOB.alive_player_list)
	var/threat_level = SSdynamic.threat_level
	dat += dynamic_ruleset_category_during_round_display("Latejoin", SSdynamic.latejoin_rules, pop_count, threat_level)
	dat += dynamic_ruleset_category_during_round_display("Midround", SSdynamic.midround_rules, pop_count, threat_level)
	browser.set_content(dat)
	browser.open()

/datum/admins/proc/dynamic_ruleset_category_pre_start_display(title, list/rules)
	var/dat = "<B><h3>[title]</h3></B><table class='ml-2'>"
	for (var/datum/dynamic_ruleset/rule as anything in rules)
		var/forced = GLOB.dynamic_forced_rulesets[rule] || RULESET_NOT_FORCED
		var/color = COLOR_SILVER
		switch (forced)
			if (RULESET_FORCE_ENABLED)
				color = COLOR_GREEN
			if (RULESET_FORCE_DISABLED)
				color = COLOR_RED
		dat += "<tr><td><b>[initial(rule.name)]</b></td><td>\[<font color=[color]> [forced] </font>\]</td><td> \
			<A href='byond://?src=[REF(src)];[HrefToken()];f_dynamic_ruleset_force_on=[text_ref(rule)]'>force enabled</A> \
			<A href='byond://?src=[REF(src)];[HrefToken()];f_dynamic_ruleset_force_off=[text_ref(rule)]'>force disabled</A> \
			<A href='byond://?src=[REF(src)];[HrefToken()];f_dynamic_ruleset_force_reset=[text_ref(rule)]'>reset</A></td></tr>"
	dat += "</table>"
	return dat

/datum/admins/proc/dynamic_ruleset_category_during_round_display(title, list/rules, pop_count, threat_level)
	var/dat = "<B><h3>[title]</h3></B><table class='ml-2'>"
	for (var/datum/dynamic_ruleset/rule as anything in rules)
		var/active = rule.acceptable(population = pop_count, threat_level = threat_level) && rule.weight > 0
		var/forced = GLOB.dynamic_forced_rulesets[rule.type] || RULESET_NOT_FORCED
		var/color = (active) ? COLOR_GREEN : COLOR_RED
		var/explanation = ""
		if (!active)
			if (rule.weight <= 0)
				explanation = " - Weight is zero"
			else if (forced == RULESET_FORCE_DISABLED)
				explanation = " - Forcibly disabled"
			else if (forced == RULESET_FORCE_ENABLED)
				explanation = " - Failed spawn conditions"
			else if (!rule.is_valid_population(pop_count))
				explanation = " - Invalid player count"
			else if (!rule.is_valid_threat(pop_count, threat_level))
				explanation = " - Insufficient threat"
			else
				explanation = " - Failed spawn conditions"
		else if (forced == RULESET_FORCE_ENABLED)
			explanation = " - Forcibly enabled"
		active = active ? "Active" : "Inactive"

		dat += {"<tr><td><b>[rule.name]</b></td>
			<td>\[ Weight: [rule.weight] \]
			<td>\[<font color=[color]> [active][explanation] </font>\]</td><td>
			<A href='byond://?src=[REF(src)];[HrefToken()];f_dynamic_ruleset_force_on=[text_ref(rule.type)]'>force enabled</A>
			<A href='byond://?src=[REF(src)];[HrefToken()];f_dynamic_ruleset_force_off=[text_ref(rule.type)]'>force disabled</A>
			<A href='byond://?src=[REF(src)];[HrefToken()];f_dynamic_ruleset_force_reset=[text_ref(rule.type)]'>reset</A></td>
			<td><A href='byond://?src=[REF(src)];[HrefToken()];f_inspect_ruleset=[text_ref(rule)]'>VV</A></td></tr>
		"}
	dat += "</table>"
	return dat


/datum/admins/proc/force_all_rulesets(mob/user, force_value)
	if (force_value == RULESET_NOT_FORCED)
		GLOB.dynamic_forced_rulesets = list()
	else
		for (var/datum/dynamic_ruleset/rule as anything in subtypesof(/datum/dynamic_ruleset))
			GLOB.dynamic_forced_rulesets[rule] = force_value
	var/logged_message = "[key_name(user)] set all dynamic rulesets to [force_value]."
	log_admin(logged_message)
	message_admins(logged_message)
	dynamic_ruleset_manager(user)

/datum/admins/proc/set_dynamic_ruleset_forced(mob/user, datum/dynamic_ruleset/type, force_value)
	if (isnull(type))
		return
	GLOB.dynamic_forced_rulesets[type] = force_value
	dynamic_ruleset_manager(user)
	var/logged_message = "[key_name(user)] set '[initial(type.name)] ([initial(type.ruletype)])' to [GLOB.dynamic_forced_rulesets[type]]."
	log_admin(logged_message)
	message_admins(logged_message)

ADMIN_VERB(create_or_modify_area, R_DEBUG, "Create Or Modify Area", "Create of modify an area. wow.", ADMIN_CATEGORY_DEBUG)
	create_area(user.mob)

//Kicks all the clients currently in the lobby. The second parameter (kick_only_afk) determins if an is_afk() check is ran, or if all clients are kicked
//defaults to kicking everyone (afk + non afk clients in the lobby)
//returns a list of ckeys of the kicked clients
/proc/kick_clients_in_lobby(message, kick_only_afk = 0)
	var/list/kicked_client_names = list()
	for(var/client/C in GLOB.clients)
		if(isnewplayer(C.mob))
			if(kick_only_afk && !C.is_afk()) //Ignore clients who are not afk
				continue
			if(message)
				to_chat(C, message, confidential = TRUE)
			kicked_client_names.Add("[C.key]")
			qdel(C)
	return kicked_client_names

//returns TRUE to let the dragdrop code know we are trapping this event
//returns FALSE if we don't plan to trap the event
/datum/admins/proc/cmd_ghost_drag(mob/dead/observer/frommob, mob/tomob)

	//this is the exact two check rights checks required to edit a ckey with vv.
	if (!check_rights(R_VAREDIT,0) || !check_rights(R_SPAWN|R_DEBUG,0))
		return FALSE

	if (!frommob.ckey)
		return FALSE

	var/question = ""
	if (tomob.ckey)
		question = "This mob already has a user ([tomob.key]) in control of it! "
	question += "Are you sure you want to place [frommob.name]([frommob.key]) in control of [tomob.name]?"

	var/ask = tgui_alert(usr, question, "Place ghost in control of mob?", list("Yes", "No"))
	if (ask != "Yes")
		return TRUE

	if (!frommob || !tomob) //make sure the mobs don't go away while we waited for a response
		return TRUE

	// Disassociates observer mind from the body mind
	if(tomob.client)
		tomob.ghostize(FALSE)
	else
		for(var/mob/dead/observer/ghost in GLOB.dead_mob_list)
			if(tomob.mind == ghost.mind)
				ghost.mind = null

	message_admins(span_adminnotice("[key_name_admin(usr)] has put [frommob.key] in control of [tomob.name]."))
	log_admin("[key_name(usr)] stuffed [frommob.key] into [tomob.name].")
	BLACKBOX_LOG_ADMIN_VERB("Ghost Drag Control")

	tomob.PossessByPlayer(frommob.key)
	tomob.client?.init_verbs()
	qdel(frommob)

	return TRUE

/// Sends a message to adminchat when anyone with a holder logs in or logs out.
/// Is dependent on admin preferences and configuration settings, which means that this proc can fire without sending a message.
/client/proc/adminGreet(logout = FALSE)
	if(!SSticker.HasRoundStarted())
		return

	if(logout && CONFIG_GET(flag/announce_admin_logout))
		message_admins("Admin logout: [key_name(src)]")
		return

	if(!logout && CONFIG_GET(flag/announce_admin_login) && (prefs.toggles & ANNOUNCE_LOGIN))
		message_admins("Admin login: [key_name(src)]")
		return

