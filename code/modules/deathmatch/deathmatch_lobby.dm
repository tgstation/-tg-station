/datum/deathmatch_lobby
	/// Ckey of the host
	var/host
	/// Assoc list of ckey to list()
	var/list/players = list()
	/// Assoc list of ckey to list()
	var/list/observers = list()
	/// The current chosen map
	var/datum/lazy_template/deathmatch/map
	/// Our turf reservation AKA where the arena is
	var/datum/turf_reservation/location
	/// Whether the lobby is currently playing
	var/playing = DEATHMATCH_NOT_PLAYING
	/// Number of total ready players
	var/ready_count
	/// List of loadouts, either gotten from the deathmatch controller or the map
	var/list/loadouts
	/// Current map player spawn locations, cleared after spawning
	var/list/player_spawns = list()
	/// A list of paths of modifiers enabled for the match.
	var/list/modifiers = list()
	/// Is the modifiers modal menu open (for the host)
	var/mod_menu_open = FALSE
	/// artificial time padding when we start loading to give lighting a breather (admin starts will set this to 0)
	var/start_time = 8 SECONDS

/datum/deathmatch_lobby/New(mob/player)
	. = ..()
	if (!player)
		stack_trace("Attempted to create a deathmatch lobby without a host.")
		return qdel(src)
	host = player.ckey
	map = GLOB.deathmatch_game.maps[pick(GLOB.deathmatch_game.maps)]
	log_game("[host] created a deathmatch lobby.")
	if (map.allowed_loadouts)
		loadouts = map.allowed_loadouts
	else
		loadouts = GLOB.deathmatch_game.loadouts
	add_player(player, loadouts[1], TRUE)
	ui_interact(player)
	addtimer(CALLBACK(src, PROC_REF(lobby_afk_probably)), 5 MINUTES) // being generous here

/datum/deathmatch_lobby/Destroy(force, ...)
	. = ..()
	for (var/key in players+observers)
		var/datum/tgui/ui = SStgui.get_open_ui(get_mob_by_ckey(key), src)
		if (ui) ui.close()
		remove_ckey_from_play(key)
	if(playing && !isnull(location))
		clear_reservation()
	players = null
	observers = null
	map?.template_in_use = FALSE //just incase
	map = null
	location = null
	loadouts = null
	modifiers = null

/datum/deathmatch_lobby/proc/start_game()
	if (playing)
		return
	if(map.template_in_use)
		to_chat(get_mob_by_ckey(host), span_warning("This map is currently loading for another lobby. Please wait until that other map finishes loading. It would be a disaster if these two mixed up."))
		return
	playing = DEATHMATCH_PRE_PLAYING

	map.template_in_use = TRUE
	RegisterSignal(map, COMSIG_LAZY_TEMPLATE_LOADED, PROC_REF(find_spawns_and_start_delay))
	location = map.lazy_load()
	if (!location)
		to_chat(get_mob_by_ckey(host), span_warning("Couldn't reserve/load a map location (all locations used?), try again later, or contact a coder."))
		playing = FALSE
		map.template_in_use = FALSE
		UnregisterSignal(map, COMSIG_LAZY_TEMPLATE_LOADED)
		return FALSE

/datum/deathmatch_lobby/proc/find_spawns_and_start_delay(datum/lazy_template/source, list/atoms)
	SIGNAL_HANDLER
	for(var/thing in atoms)
		if(istype(thing, /obj/effect/landmark/deathmatch_player_spawn))
			player_spawns += thing

	UnregisterSignal(source, COMSIG_LAZY_TEMPLATE_LOADED)
	map.template_in_use = FALSE
	addtimer(CALLBACK(src, PROC_REF(start_game_after_delay)), start_time)

/datum/deathmatch_lobby/proc/start_game_after_delay()
	if (!length(player_spawns) || length(player_spawns) < length(players))
		stack_trace("Failed to get spawns when loading deathmatch map [map.name] for lobby [host].")
		clear_reservation()
		playing = FALSE
		return FALSE

	for(var/modpath in modifiers)
		GLOB.deathmatch_game.modifiers[modpath].on_start_game(src)

	for (var/key in players)
		var/mob/dead/observer/observer = players[key]["mob"]
		if (isnull(observer) || !observer.client)
			log_game("Removed player [key] from deathmatch lobby [host], as they couldn't be found.")
			remove_ckey_from_play(key)
			continue

		// pick spawn and remove it.
		var/picked_spawn = pick_n_take(player_spawns)
		spawn_observer_as_player(key, get_turf(picked_spawn))
		qdel(picked_spawn)

	// Remove rest of spawns.
	QDEL_LIST(player_spawns)

	for (var/observer_key in observers)
		var/mob/observer = observers[observer_key]["mob"]
		observer.forceMove(pick(location.reserved_turfs))

	playing = DEATHMATCH_PLAYING
	addtimer(CALLBACK(src, PROC_REF(game_took_too_long)), initial(map.automatic_gameend_time))
	log_game("Deathmatch game [host] started.")
	announce(span_reallybig("GO!"))
	if(length(modifiers))
		var/list/modifier_names = list()
		for(var/datum/deathmatch_modifier/modifier as anything in modifiers)
			modifier_names += uppertext(initial(modifier.name))
		announce(span_boldnicegreen("THIS MATCH MODIFIERS: [english_list(modifier_names, and_text = " ,")]."))
	return TRUE

/datum/deathmatch_lobby/proc/spawn_observer_as_player(ckey, loc)
	var/list/players_info = players[ckey]
	var/mob/dead/observer/observer = players_info["mob"]
	if (isnull(observer) || !observer.client)
		remove_ckey_from_play(ckey)
		return

	// equip player
	var/datum/outfit/deathmatch_loadout/loadout = players_info["loadout"]
	if (!(loadout in loadouts))
		loadout = loadouts[1]

	var/mob/living/carbon/human/new_player = new(loc)
	observer.client?.prefs.safe_transfer_prefs_to(new_player)
	new_player.dna.update_dna_identity()
	new_player.updateappearance(icon_update = TRUE, mutcolor_update = TRUE, mutations_overlay_update = TRUE)
	new_player.add_traits(list(TRAIT_CANNOT_CRYSTALIZE, TRAIT_PERMANENTLY_MORTAL, TRAIT_TEMPORARY_BODY), INNATE_TRAIT)
	if(observer.mind)
		new_player.AddComponent( \
			/datum/component/temporary_body, \
			old_mind = observer.mind, \
			old_body = observer.mind.current, \
		)
	new_player.equipOutfit(loadout) // Loadout
	new_player.PossessByPlayer(ckey)
	players_info["mob"] = new_player

	for(var/datum/deathmatch_modifier/modifier as anything in modifiers)
		GLOB.deathmatch_game.modifiers[modifier].apply(new_player, src)

	// register death handling.
	register_player_signals(new_player)

/datum/deathmatch_lobby/proc/register_player_signals(new_player)
	RegisterSignals(new_player, list(COMSIG_LIVING_DEATH, COMSIG_QDELETING, COMSIG_MOB_GHOSTIZED), PROC_REF(player_died))
	RegisterSignal(new_player, COMSIG_LIVING_ON_WABBAJACKED, PROC_REF(player_wabbajacked))

/datum/deathmatch_lobby/proc/unregister_player_signals(new_player)
	UnregisterSignal(new_player, list(COMSIG_LIVING_DEATH, COMSIG_QDELETING, COMSIG_MOB_GHOSTIZED, COMSIG_LIVING_ON_WABBAJACKED))

/datum/deathmatch_lobby/proc/game_took_too_long()
	if (!location || QDELING(src))
		return
	announce(span_reallybig("The players have took too long! Game ending!"))
	end_game()

/datum/deathmatch_lobby/proc/lobby_afk_probably()
	if (QDELING(src) || playing)
		return
	announce(span_warning("Lobby ([host]) was closed due to not starting after 5 minutes, being potentially AFK. Please be faster next time."))
	GLOB.deathmatch_game.remove_lobby(host)

/datum/deathmatch_lobby/proc/end_game()
	if (!location)
		CRASH("Reservation of deathmatch game [host] deleted during game.")
	var/mob/winner
	if(players.len)
		var/list/winner_info = players[pick(players)]
		if(!isnull(winner_info["mob"]))
			winner = winner_info["mob"] //only one should remain anyway but incase of a draw

	announce(span_reallybig("THE GAME HAS ENDED.<BR>THE WINNER IS: [winner ? winner.real_name : "no one"]."))

	for(var/ckey in players)
		var/mob/loser = players[ckey]["mob"]
		unregister_player_signals(loser)
		players[ckey]["mob"] = null
		loser.ghostize(can_reenter_corpse = FALSE)
		qdel(loser)

	for(var/datum/deathmatch_modifier/modifier in modifiers)
		GLOB.deathmatch_game.modifiers[modifier].on_end_game(src)

	clear_reservation()
	GLOB.deathmatch_game.remove_lobby(host)
	log_game("Deathmatch game [host] ended.")

/datum/deathmatch_lobby/proc/player_wabbajacked(mob/living/player, mob/living/new_mob)
	SIGNAL_HANDLER
	unregister_player_signals(player)
	players[player.ckey]["mob"] = new_mob
	register_player_signals(new_mob)

/datum/deathmatch_lobby/proc/player_died(mob/living/player, gibbed)
	SIGNAL_HANDLER
	if(isnull(player) || QDELING(src) || HAS_TRAIT_FROM(player, TRAIT_NO_TRANSFORM, MAGIC_TRAIT)) //this trait check fixes polymorphing
		return

	var/ckey = player.ckey ? player.ckey : player.mind?.key
	if(!islist(players[ckey])) // potentially the player info could hold a reference to this mob so we can figure the ckey out without worrying about ghosting and suicides n such
		for(var/potential_ckey in players)
			var/list/player_info = players[potential_ckey]
			if(player_info["mob"] && player_info["mob"] == player)
				ckey = potential_ckey
				break

	if(!islist(players[ckey])) // if we STILL didnt find a good ckey
		return

	players -= ckey

	var/mob/dead/observer/ghost = !player.client ? player.get_ghost() : player.ghostize() //this doesnt work on those who used the ghost verb
	if(!isnull(ghost))
		add_observer(ghost, (host == ckey))

	announce(span_reallybig("[player.real_name] HAS DIED.<br>[players.len] REMAIN."))

	if(!gibbed && !QDELING(player) && !isdead(player))
		if(!HAS_TRAIT(src, TRAIT_DEATHMATCH_EXPLOSIVE_IMPLANTS))
			unregister_player_signals(player)
			player.dust(TRUE, TRUE, TRUE)
	if (players.len <= 1)
		end_game()

/datum/deathmatch_lobby/proc/add_observer(mob/mob, host = FALSE)
	if (players[mob.ckey])
		CRASH("Tried to add [mob.ckey] as an observer while being a player.")
	observers[mob.ckey] = list("mob" = mob, "host" = host)

/datum/deathmatch_lobby/proc/add_player(mob/mob, loadout, host = FALSE)
	if (observers[mob.ckey])
		CRASH("Tried to add [mob.ckey] as a player while being an observer.")
	players[mob.ckey] = list("mob" = mob, "host" = host, "ready" = FALSE, "loadout" = loadout)

/datum/deathmatch_lobby/proc/remove_ckey_from_play(ckey)
	var/is_likely_player = (ckey in players)
	var/list/main_list = is_likely_player ? players : observers
	var/list/info = main_list[ckey]
	if(is_likely_player && islist(info))
		ready_count -= info["ready"]
	main_list -= ckey

/datum/deathmatch_lobby/proc/announce(message)
	for (var/key in players+observers)
		var/mob/player = get_mob_by_ckey(key)
		if (!player.client)
			remove_ckey_from_play(key)
			continue
		to_chat(player.client, message)

/datum/deathmatch_lobby/proc/leave(ckey)
	if (host == ckey)
		var/total_count = players.len + observers.len
		if (total_count <= 1) // <= just in case.
			GLOB.deathmatch_game.remove_lobby(host)
			return
		else
			if (players[ckey] && players.len <= 1)
				for (var/key in observers)
					if (host == key)
						continue
					host = key
					observers[key]["host"] = TRUE
					break
			else
				for (var/key in players)
					if (host == key)
						continue
					host = key
					players[key]["host"] = TRUE
					break
			GLOB.deathmatch_game.passoff_lobby(ckey, host)

	remove_ckey_from_play(ckey)

/datum/deathmatch_lobby/proc/join(mob/player)
	if (playing || !player)
		return
	if(!(player.ckey in (players+observers)))
		if (players.len >= map.max_players)
			add_observer(player)
		else
			add_player(player, loadouts[1])
	ui_interact(player)

/datum/deathmatch_lobby/proc/spectate(mob/player)
	if (!playing || !location || !player)
		return
	if (!observers[player.ckey])
		add_observer(player)
	player.forceMove(pick(location.reserved_turfs))

/datum/deathmatch_lobby/proc/change_map(new_map)
	if (!new_map || !GLOB.deathmatch_game.maps[new_map])
		return
	map = GLOB.deathmatch_game.maps[new_map]
	var/max_players = map.max_players
	for (var/possible_unlucky_loser in players)
		max_players--
		if (max_players < 0)
			var/loser_mob = players[possible_unlucky_loser]["mob"]
			remove_ckey_from_play(possible_unlucky_loser)
			add_observer(loser_mob)

	loadouts = map.allowed_loadouts ? map.allowed_loadouts : GLOB.deathmatch_game.loadouts
	for (var/player_key in players)
		if (players[player_key]["loadout"] in loadouts)
			continue
		players[player_key]["loadout"] = loadouts[1]

	for(var/deathmatch_mod in modifiers)
		GLOB.deathmatch_game.modifiers[deathmatch_mod].on_map_changed(src)

/datum/deathmatch_lobby/proc/clear_reservation()
	if(isnull(location) || isnull(map))
		return
	for(var/turf/victimized_turf as anything in location.reserved_turfs) //remove this once clearing turf reservations is actually reliable
		victimized_turf.empty()
	map.reservations -= location
	qdel(location)

/datum/deathmatch_lobby/Topic(href, href_list) //This handles the chat Join button href, supposedly
	var/mob/dead/observer/ghost = usr
	if (!istype(ghost))
		return
	if(href_list["join"])
		join(ghost)

/datum/deathmatch_lobby/ui_state(mob/user)
	return GLOB.observer_state

/// fills the lobby with fake players for the sake of UI debug, can only be called via VV
/datum/deathmatch_lobby/proc/fakefill(count)
	for(var/i = 1 to count)
		players["[rand(1,999)]"] = list("mob" = usr, "host" = FALSE, "ready" = FALSE, "loadout" = pick(loadouts))

/datum/deathmatch_lobby/ui_interact(mob/user, datum/tgui/ui)
	ui = SStgui.try_update_ui(user, src, null)
	if(!ui)
		ui = new(user, src, "DeathmatchLobby")
		ui.open()

/datum/deathmatch_lobby/ui_static_data(mob/user)
	. = list()
	.["maps"] = list()
	for (var/map_key in GLOB.deathmatch_game.maps)
		.["maps"] += map_key
	.["maps"] = sort_list(.["maps"])


/datum/deathmatch_lobby/ui_data(mob/user)
	var/list/data = list()

	var/is_player = !isnull(players[user.ckey])
	var/is_host = (user.ckey == host)
	var/is_admin = check_rights_for(user.client, R_ADMIN)
	var/has_auth = is_host || is_admin

	data["active_mods"] = "No modifiers selected"
	data["admin"] = is_admin
	data["host"] = is_host
	data["loadouts"] = list("Randomize")

	for (var/datum/outfit/deathmatch_loadout/loadout as anything in loadouts)
		data["loadouts"] += loadout::display_name

	data["map"] = list()
	data["map"]["name"] = map.name
	data["map"]["desc"] = map.desc
	data["map"]["time"] = map.automatic_gameend_time
	data["map"]["min_players"] = map.min_players
	data["map"]["max_players"] = map.max_players

	data["mod_menu_open"] = mod_menu_open
	data["modifiers"] = has_auth ? get_modifier_list(is_host, mod_menu_open) : list()
	data["observers"] = get_observer_list()
	data["players"] = get_player_list()
	data["playing"] = playing
	data["self"] = user.ckey

	if(length(modifiers))
		var/list/mod_names = list()
		for(var/datum/deathmatch_modifier/modpath as anything in modifiers)
			mod_names += modpath::name
		data["active_mods"] = "Selected modifiers: [english_list(mod_names)]"

	if(is_player && !isnull(players[user.ckey]["loadout"]))
		var/datum/outfit/deathmatch_loadout/loadout = players[user.ckey]["loadout"]
		data["loadoutdesc"] = loadout::desc
	else
		data["loadoutdesc"] = "You are an observer! As an observer, you can hear lobby announcements."

	return data

/datum/deathmatch_lobby/ui_act(action, list/params, datum/tgui/ui, datum/ui_state/state)
	. = ..()
	if(. || !isobserver(usr))
		return

	switch(action)
		if ("start_game")
			if (usr.ckey != host)
				return FALSE
			if (map.min_players > players.len)
				to_chat(usr, span_warning("Not enough players to start yet."))
				return FALSE
			start_game()
			return TRUE

		if ("leave_game")
			if (playing)
				return FALSE
			leave(usr.ckey)
			ui.close()
			GLOB.deathmatch_game.ui_interact(usr)
			return TRUE

		if ("change_loadout")
			if (playing)
				return FALSE
			if (params["player"] != usr.ckey && host != usr.ckey)
				return FALSE
			if (params["loadout"] == "Randomize")
				players[params["player"]]["loadout"] = pick(loadouts)
				return TRUE
			for (var/datum/outfit/deathmatch_loadout/possible_loadout as anything in loadouts)
				if (params["loadout"] != initial(possible_loadout.display_name))
					continue
				players[params["player"]]["loadout"] = possible_loadout
				break
			return TRUE

		if ("observe")
			if (playing)
				return FALSE
			if (players[usr.ckey])
				remove_ckey_from_play(usr.ckey)
				add_observer(usr, host == usr.ckey)
				return TRUE
			else if (observers[usr.ckey] && players.len < map.max_players)
				remove_ckey_from_play(usr.ckey)
				add_player(usr, loadouts[1], host == usr.ckey)
				return TRUE

		if ("ready")
			players[usr.ckey]["ready"] ^= 1 // Toggle.
			ready_count += (players[usr.ckey]["ready"] * 2) - 1 // scared?
			if (ready_count >= players.len && players.len >= map.min_players)
				start_game()
			return TRUE

		if ("host") // Host functions
			if (playing || (usr.ckey != host && !check_rights(R_ADMIN)))
				return FALSE
			var/uckey = params["id"]

			switch (params["func"])
				if ("Kick")
					leave(uckey)
					var/umob = get_mob_by_ckey(uckey)
					var/datum/tgui/uui = SStgui.get_open_ui(umob, src)
					uui?.close()
					GLOB.deathmatch_game.ui_interact(umob)
					return TRUE
				if ("Transfer host")
					if (host == uckey)
						return FALSE
					GLOB.deathmatch_game.passoff_lobby(host, uckey)
					host = uckey
					return TRUE
				if ("Toggle observe")
					var/umob = get_mob_by_ckey(uckey)
					if (players[uckey])
						remove_ckey_from_play(uckey)
						add_observer(umob, host == uckey)
					else if (observers[uckey] && players.len < map.max_players)
						remove_ckey_from_play(uckey)
						add_player(umob, loadouts[1], host == uckey)
					return TRUE
				if ("change_map")
					if (!(params["map"] in GLOB.deathmatch_game.maps))
						return FALSE
					change_map(params["map"])
					return TRUE

		if("open_mod_menu")
			mod_menu_open = TRUE
			return TRUE

		if("exit_mod_menu")
			mod_menu_open = FALSE
			return TRUE

		if("toggle_modifier")
			var/datum/deathmatch_modifier/modpath = text2path(params["modpath"])
			if(!ispath(modpath))
				return TRUE
			if(usr.ckey != host && !check_rights(R_ADMIN))
				return TRUE
			var/datum/deathmatch_modifier/chosen_modifier = GLOB.deathmatch_game.modifiers[modpath]
			if(modpath in modifiers)
				unselect_modifier(chosen_modifier)
				return TRUE
			if(chosen_modifier.selectable(src))
				select_modifier(chosen_modifier)
				return TRUE

		if ("admin") // Admin functions
			if (!check_rights(R_ADMIN))
				message_admins("[usr.key] has attempted to use admin functions in a deathmatch lobby without being an admin!")
				log_admin("[key_name(usr)] tried to use the deathmatch lobby admin functions without authorization.")
				return
			switch (params["func"])
				if ("Force start")
					log_admin("[key_name(usr)] force started deathmatch lobby [host].")
					start_time = 0
					start_game()

	return FALSE

/// Selects the passed modifier.
/datum/deathmatch_lobby/proc/select_modifier(datum/deathmatch_modifier/modifier)
	modifier.on_select(src)
	modifiers += modifier.type

/// Deselects the passed modifier.
/datum/deathmatch_lobby/proc/unselect_modifier(datum/deathmatch_modifier/modifier)
	modifier.unselect(src)
	modifiers -= modifier.type

/datum/deathmatch_lobby/ui_close(mob/user)
	. = ..()
	if(user.ckey == host)
		mod_menu_open = FALSE

/// Helper proc to get modifier data
/datum/deathmatch_lobby/proc/get_modifier_list(is_host, mod_menu_open)
	var/list/modifier_list = list()

	if(!mod_menu_open)
		return modifier_list

	for(var/modpath in GLOB.deathmatch_game.modifiers)
		var/datum/deathmatch_modifier/mod = GLOB.deathmatch_game.modifiers[modpath]

		UNTYPED_LIST_ADD(modifier_list, list(
			"name" = mod.name,
			"desc" = mod.description,
			"modpath" = "[modpath]",
			"selected" = (modpath in modifiers),
			"selectable" = is_host && mod.selectable(src),
		))

	return modifier_list


/// Helper proc for getting observer data
/datum/deathmatch_lobby/proc/get_observer_list()
	var/list/observer_list = list()

	for (var/observer_key in observers)
		var/list/observer_info = observers[observer_key]
		var/mob/observer_mob = observer_info["mob"]

		if (isnull(observer_mob) || !observer_mob.client)
			leave(observer_key)
			continue

		var/list/observer = observer_info.Copy()
		observer["key"] = observer_key

		UNTYPED_LIST_ADD(observer_list, observer)

	return observer_list


/// Helper proc for getting player data
/datum/deathmatch_lobby/proc/get_player_list()
	var/list/player_list = list()

	for (var/player_key in players)
		var/list/player_info = players[player_key]
		var/mob/player_mob = player_info["mob"]

		if (isnull(player_mob) || !player_mob.client)
			leave(player_key)
			continue

		var/list/player = player_info.Copy()

		var/datum/outfit/deathmatch_loadout/dm_loadout = player_info["loadout"]
		player["loadout"] = dm_loadout::display_name
		player["key"] = player_key

		UNTYPED_LIST_ADD(player_list, player)

	return player_list
