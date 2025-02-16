///how many people can play basketball without issues (running out of spawns, procs not expecting more than this amount of people, etc)
#define BASKETBALL_MIN_PLAYER_COUNT 2
#define BASKETBALL_MAX_PLAYER_COUNT 7

#define BASKETBALL_TEAM_HOME "home"
#define BASKETBALL_TEAM_AWAY "away"

/// list of ghosts who want to play basketball, every time someone enters the list it checks to see if enough are in
GLOBAL_LIST_EMPTY(basketball_signup)
/// list of ghosts who want to play basketball that have since disconnected. They are kept in the lobby, but not counted for starting a game.
GLOBAL_LIST_EMPTY(basketball_bad_signup)
/// the current global basketball game running.
GLOBAL_VAR(basketball_game)

/**
 * The basketball controller handles the basketball minigame in progress.
 * It is first created when the first ghost signs up to play.
 */
/datum/basketball_controller
	/// Template picked when the game starts. used for the name and desc reading
	var/datum/map_template/basketball/current_map
	/// Map generation tool that deletes the current map after the game finishes
	var/datum/map_generator/massdelete/map_deleter
	/// Total amount of time basketball is played for
	var/game_duration = 3 MINUTES

	/// List of all players ckeys involved in the minigame
	var/list/minigame_players = list()

	/// Spawn points for home team players
	var/list/home_team_landmarks = list()
	/// List of home team players ckeys
	var/list/home_team_players = list()
	/// The basketball hoop used by home team
	var/obj/structure/hoop/minigame/home_hoop

	/// Spawn points for away team players
	var/list/away_team_landmarks = list()
	/// List of away team players ckeys
	var/list/away_team_players = list()
	/// The basketball hoop used by away team
	var/obj/structure/hoop/minigame/away_hoop

	/// Spawn point for referee (there should only be one spot on minigame map)
	var/list/referee_landmark = list()

/datum/basketball_controller/New()
	. = ..()
	GLOB.basketball_game = src
	map_deleter = new

/datum/basketball_controller/Destroy(force)
	. = ..()
	GLOB.basketball_game = null
	end_game()
	qdel(map_deleter)

/**
 * Triggers at beginning of the game when there is a confirmed list of valid, ready players.
 * Creates a 100% ready game that has NOT started (no players in bodies)
 * Followed by start game
 *
 * Does the following:
 * * Picks map, and loads it
 * * Grabs landmarks if it is the first time it's loading
 * * Puts players in each team randomly
 * Arguments:
 * * ready_players: list of filtered, sane players (so not playing or disconnected) for the game to put into roles
 */
/datum/basketball_controller/proc/prepare_game(ready_players)
	var/list/possible_maps = subtypesof(/datum/map_template/basketball)
	var/turf/spawn_area = get_turf(locate(/obj/effect/landmark/basketball/game_area) in GLOB.landmarks_list)

	current_map = pick(possible_maps)
	current_map = new current_map

	if(!spawn_area)
		CRASH("No spawn area detected for Basketball Minigame!")
	var/list/bounds = current_map.load(spawn_area)
	if(!bounds)
		CRASH("Loading basketball map failed!")
	map_deleter.defineRegion(spawn_area, locate(spawn_area.x + 23, spawn_area.y + 25, spawn_area.z), replace = TRUE) //so we're ready to mass delete when round ends

	var/turf/home_hoop_turf = get_turf(locate(/obj/effect/landmark/basketball/team_spawn/home_hoop) in GLOB.landmarks_list)
	if(!home_hoop_turf)
		CRASH("No home landmark for basketball hoop detected!")
	home_hoop = (locate(/obj/structure/hoop/minigame) in home_hoop_turf)
	if(!home_hoop)
		CRASH("No minigame basketball hoop detected for home team!")

	if(!home_team_landmarks.len)
		for(var/obj/effect/landmark/basketball/team_spawn/home/possible_spawn in GLOB.landmarks_list)
			home_team_landmarks += possible_spawn

	var/turf/away_hoop_turf = get_turf(locate(/obj/effect/landmark/basketball/team_spawn/away_hoop) in GLOB.landmarks_list)
	if(!away_hoop_turf)
		CRASH("No away landmark for basketball hoop detected!")
	away_hoop = (locate(/obj/structure/hoop/minigame) in away_hoop_turf)
	if(!away_hoop)
		CRASH("No minigame basketball hoop detected for away team!")

	if(!away_team_landmarks.len)
		for(var/obj/effect/landmark/basketball/team_spawn/away/possible_spawn in GLOB.landmarks_list)
			away_team_landmarks += possible_spawn

	for(var/obj/effect/landmark/basketball/team_spawn/referee/possible_spawn in GLOB.landmarks_list)
		referee_landmark += possible_spawn

	start_game(ready_players)

/**
 * The game by this point is now all set up, and so we can put people in their bodies.
 */
/datum/basketball_controller/proc/start_game(ready_players)
	message_admins("The players have spoken! Voting has enabled the basketball minigame!")
	notify_ghosts(
		"Basketball minigame is about to start!",
		source = home_hoop,
		header = "Basketball Minigame",
		ghost_sound = 'sound/effects/ghost2.ogg',
		notify_volume = 75,
	)

	create_bodies(ready_players)
	addtimer(CALLBACK(src, PROC_REF(victory)), game_duration)
	for(var/i in 1 to 10)
		addtimer(CALLBACK(GLOBAL_PROC, GLOBAL_PROC_REF(playsound), home_hoop, 'sound/items/timer.ogg', 75, FALSE), game_duration - (i SECONDS))
		addtimer(CALLBACK(home_hoop, TYPE_PROC_REF(/atom/movable/, say), "[i] seconds left"), game_duration - (i SECONDS))

		addtimer(CALLBACK(GLOBAL_PROC, GLOBAL_PROC_REF(playsound), away_hoop, 'sound/items/timer.ogg', 75, FALSE), game_duration - (i SECONDS))
		addtimer(CALLBACK(away_hoop, TYPE_PROC_REF(/atom/movable/, say), "[i] seconds left"), game_duration - (i SECONDS))

/**
 * Called when the game is setting up, AFTER map is loaded but BEFORE the game start. Creates and places each body and gives the correct player key
 */
/datum/basketball_controller/proc/create_bodies(ready_players)
	var/list/possible_away_teams = subtypesof(/datum/map_template/basketball) - current_map.type
	var/datum/map_template/basketball/away_map = pick(possible_away_teams)
	away_map = new away_map

	var/list/home_spawnpoints = home_team_landmarks.Copy()
	var/list/away_spawnpoints = away_team_landmarks.Copy()
	var/list/referee_spawnpoint = referee_landmark.Copy()
	var/obj/effect/landmark/basketball/team_spawn/spawn_landmark

	var/team_uniform
	var/team_name

	// rename the hoops to their appropriate teams names
	home_hoop.name = current_map.team_name
	away_hoop.name = away_map.team_name

	var/player_count = 0
	// if total players is odd number then the odd man out is a referee
	var/minigame_has_referee = length(ready_players) % 2

	for(var/player_key in ready_players)
		player_count++
		minigame_players |= player_key

		var/is_player_referee = (player_count == length(ready_players) && minigame_has_referee)

		if(is_player_referee)
			spawn_landmark = pick_n_take(referee_spawnpoint)
			team_uniform = /datum/outfit/basketball/referee
		else if(player_count % 2) // odd is home team
			spawn_landmark = pick_n_take(home_spawnpoints)
			home_team_players |= player_key
			away_hoop.team_ckeys |= player_key // to restrict scoring on opponents hoop rapidly
			team_uniform = current_map.home_team_uniform
			team_name = current_map.team_name
		else // even is away team
			spawn_landmark = pick_n_take(away_spawnpoints)
			away_team_players |= player_key
			home_hoop.team_ckeys |= player_key // to restrict scoring on opponents hoop rapidly
			team_uniform = away_map.home_team_uniform
			team_name = away_map.team_name

		var/mob/living/carbon/human/baller = new(get_turf(spawn_landmark))

		if(baller.dna.species.outfit_important_for_life)
			baller.set_species(/datum/species/human)

		ADD_TRAIT(baller, TRAIT_NOFIRE, BASKETBALL_MINIGAME_TRAIT)
		ADD_TRAIT(baller, TRAIT_NOBREATH, BASKETBALL_MINIGAME_TRAIT)
		ADD_TRAIT(baller, TRAIT_CANNOT_CRYSTALIZE, BASKETBALL_MINIGAME_TRAIT)
		// this is basketball, not a boxing match
		ADD_TRAIT(baller, TRAIT_PACIFISM, BASKETBALL_MINIGAME_TRAIT)

		baller.equipOutfit(team_uniform)

		var/client/player_client = GLOB.directory[player_key]
		if(player_client)
			player_client.prefs.safe_transfer_prefs_to(baller, is_antag = TRUE)
		if(player_client.mob.mind)
			baller.AddComponent( \
				/datum/component/temporary_body, \
				old_mind = player_client.mob.mind, \
				old_body = player_client.mob.mind.current, \
			)
		baller.PossessByPlayer(player_key)

		SEND_SOUND(baller, sound('sound/items/whistle/whistle.ogg', volume=30))
		if(is_player_referee)
			to_chat(baller, span_notice("You are a referee. Make sure the teams play fair and use your whistle to call fouls appropriately."))
		else
			to_chat(baller, span_notice("You are a basketball player for the [team_name]. Score as much as you can before time runs out."))
			to_chat(baller, span_info("LMB to pass the ball while on help intent (zero stamina cost/) - accuracy penalty when scoring)"))
			to_chat(baller, span_info("RMB to shoot the ball ([STAMINA_COST_SHOOTING] stamina cost) - this goes over players heads"))
			to_chat(baller, span_info("Click directly on hoop while adjacent to dunk ([STAMINA_COST_DUNKING] stamina cost)"))
			to_chat(baller, span_info("Spinning decreases other players disarm chance against you but reduces shooting accuracy ([STAMINA_COST_SPINNING] stamina cost)"))

/**
 * Called after the game is finished. Sends end game notifications to teams and dusts the losers.
 */
/datum/basketball_controller/proc/victory()
	var/is_game_draw
	var/list/winner_team_ckeys = list()
	var/list/loser_team_ckeys = list()
	var/winner_team_name

	if(home_hoop.total_score == away_hoop.total_score)
		is_game_draw = TRUE
		winner_team_ckeys |= home_team_players
		winner_team_ckeys |= away_team_players
	else if(home_hoop.total_score > away_hoop.total_score)
		winner_team_ckeys = away_team_players
		winner_team_name = away_hoop.name
		loser_team_ckeys = home_team_players
	else if(home_hoop.total_score < away_hoop.total_score)
		winner_team_ckeys = home_team_players
		winner_team_name = home_hoop.name
		loser_team_ckeys = away_team_players

	if(is_game_draw)
		for(var/ckey in winner_team_ckeys)
			var/mob/living/competitor = get_mob_by_ckey(ckey)
			var/area/mob_area = get_area(competitor)
			if(istype(competitor) && istype(mob_area, /area/centcom/basketball))
				to_chat(competitor, span_hypnophrase("The game resulted in a draw!"))
	else
		for(var/ckey in winner_team_ckeys)
			var/mob/living/competitor = get_mob_by_ckey(ckey)
			var/area/mob_area = get_area(competitor)
			if(istype(competitor) && istype(mob_area, /area/centcom/basketball))
				to_chat(competitor, span_hypnophrase("[winner_team_name] team wins!"))

		for(var/ckey in loser_team_ckeys)
			var/mob/living/competitor = get_mob_by_ckey(ckey)
			var/area/mob_area = get_area(competitor)
			if(istype(competitor) && istype(mob_area, /area/centcom/basketball))
				to_chat(competitor, span_hypnophrase("[winner_team_name] team wins!"))
				competitor.dust()

	addtimer(CALLBACK(src, PROC_REF(end_game)), 20 SECONDS) // give winners time for a victory lap

/**
 * Cleans up the game, resetting variables back to the beginning and removing the map with the generator.
 */
/datum/basketball_controller/proc/end_game()
	for(var/ckey in minigame_players)
		var/mob/living/competitor = get_mob_by_ckey(ckey)
		var/area/mob_area = get_area(competitor)
		if(istype(competitor) && istype(mob_area, /area/centcom/basketball))
			QDEL_NULL(competitor)

	map_deleter.generate() //remove the map, it will be loaded at the start of the next one
	QDEL_NULL(current_map)

	//map gen does not deal with landmarks
	QDEL_LIST(home_team_landmarks)
	QDEL_LIST(away_team_landmarks)
	QDEL_LIST(referee_landmark)

/**
 * Called when enough players have signed up to fill a setup. DOESN'T NECESSARILY MEAN THE GAME WILL START.
 *
 * Checks for a custom setup, if so gets the required players from that and if not it sets the player requirement to BASKETBALL_MAX_PLAYER_COUNT and generates one IF basic setup starts a game.
 * Checks if everyone signed up is an observer, and is still connected. If people aren't, they're removed from the list.
 * If there aren't enough players post sanity, it aborts. otherwise, it selects enough people for the game and starts preparing the game for real.
 */
/datum/basketball_controller/proc/basic_setup()
	//final list for all the players who will be in this game
	var/list/filtered_keys = list()
	//cuts invalid players from signups (disconnected/not a ghost)
	var/list/possible_keys = list()
	for(var/key in GLOB.basketball_signup)
		if(GLOB.directory[key])
			var/client/C = GLOB.directory[key]
			if(isobserver(C.mob))
				possible_keys += key
				continue
		GLOB.basketball_signup -= key //not valid to play when we checked so remove them from signups

	//if there were not enough players, don't start. we already trimmed the list to now hold only valid signups
	if(length(possible_keys) < BASKETBALL_MIN_PLAYER_COUNT)
		return

	var/req_players = length(possible_keys) >= BASKETBALL_MAX_PLAYER_COUNT ? BASKETBALL_MAX_PLAYER_COUNT : length(possible_keys)

	//if there were too many players, still start but only make filtered keys as big as it needs to be (cut excess)
	//also removes people who do get into final player list from the signup so they have to sign up again when game ends
	for(var/i in 1 to req_players)
		var/chosen_key = pick_n_take(possible_keys)
		filtered_keys += chosen_key
		GLOB.basketball_signup -= chosen_key

	//small message about not getting into this game for clarity on why they didn't get in
	for(var/unpicked in possible_keys)
		var/client/unpicked_client = GLOB.directory[unpicked]
		to_chat(unpicked_client, span_danger("Sorry, the starting basketball game has too many players and you were not picked."))
		to_chat(unpicked_client, span_warning("You're still signed up, getting messages from the current round, and have another chance to join when the one starting now finishes."))

	prepare_game(filtered_keys)

/**
 * Filters inactive player into a different list until they reconnect, and removes players who are no longer ghosts.
 */
/datum/basketball_controller/proc/check_signups()
	for(var/bad_key in GLOB.basketball_bad_signup)
		var/client/signup_client = GLOB.directory[bad_key]
		if(signup_client) //they have reconnected if we can search their key and get a client
			GLOB.basketball_bad_signup -= bad_key
			GLOB.basketball_signup[bad_key] = TRUE
	for(var/key in GLOB.basketball_signup)
		var/client/signup_client = GLOB.directory[key]
		if(!signup_client) //vice versa but in a variable we use later
			GLOB.basketball_signup -= key
			GLOB.basketball_bad_signup[key] = TRUE
			continue
		if(!isobserver(signup_client.mob))
			//they are back to playing the game, remove them from the signups
			GLOB.basketball_signup -= key

/**
 * Called when someone signs up, and sees if there are enough people in the signup list to begin.
 *
 * Only checks if everyone is actually valid to start (still connected and an observer) if there are enough players (basic_setup)
 */
/datum/basketball_controller/proc/try_autostart()
	if(!(GLOB.ghost_role_flags & GHOSTROLE_MINIGAME))
		return
	if(GLOB.basketball_signup.len >= BASKETBALL_MIN_PLAYER_COUNT) //enough people to try and make something (or debug mode)
		basic_setup()

/datum/basketball_controller/ui_state(mob/user)
	return GLOB.always_state

/datum/basketball_controller/ui_interact(mob/user, datum/tgui/ui)
	check_signups()
	ui = SStgui.try_update_ui(user, src, ui)
	if(!ui)
		ui = new(user, src, "BasketballPanel")
		ui.set_autoupdate(FALSE)
		ui.open()

/datum/basketball_controller/ui_data(mob/user)
	. = ..()

	.["total_votes"] = GLOB.basketball_signup.len
	.["players_min"] = BASKETBALL_MIN_PLAYER_COUNT
	.["players_max"] = BASKETBALL_MAX_PLAYER_COUNT

	var/list/lobby_data = list()
	for(var/key in GLOB.basketball_signup + GLOB.basketball_bad_signup)
		var/list/lobby_member = list()
		lobby_member["ckey"] = key
		lobby_member["status"] = (key in GLOB.basketball_bad_signup) ? "Disconnected" : "Ready"
		lobby_data += list(lobby_member)
	.["lobbydata"] = lobby_data

/datum/basketball_controller/ui_act(action, list/params, datum/tgui/ui, datum/ui_state/state)
	. = ..()
	if(.)
		return

	var/mob/dead/observer/user = ui.user
	if(!istype(user)) // only ghosts
		return

	var/client/ghost_client = user.client
	if(!SSticker.HasRoundStarted())
		to_chat(ghost_client, span_warning("Wait for the round to start."))
		return

	switch(action)
		if("basketball_signup")
			if(GLOB.basketball_signup[ghost_client.ckey] || GLOB.basketball_bad_signup[ghost_client.ckey])
				GLOB.basketball_signup -= ghost_client.ckey
				GLOB.basketball_bad_signup -= ghost_client.ckey
				to_chat(ghost_client, span_notice("You unregister from basketball."))
			else
				GLOB.basketball_signup[ghost_client.ckey] = TRUE
				to_chat(ghost_client, span_notice("You sign up for basketball."))

			check_signups()
			return TRUE
		if("basketball_start")
			if(!GLOB.basketball_signup[ghost_client.ckey])
				to_chat(ghost_client, span_notice("You must sign up to start the game."))
				return
			if(current_map)
				to_chat(ghost_client, span_notice("Wait for current basketball game to finish."))
				return
			try_autostart()
			return TRUE


/**
 * Creates the global datum for playing basketball games, destroys the last if that's required and returns the new.
 */
/proc/create_basketball_game()
	if(GLOB.basketball_game)
		QDEL_NULL(GLOB.basketball_game)
	var/datum/basketball_controller/basketball_minigame = new()
	return basketball_minigame

#undef BASKETBALL_MIN_PLAYER_COUNT
#undef BASKETBALL_MAX_PLAYER_COUNT
#undef BASKETBALL_TEAM_HOME
#undef BASKETBALL_TEAM_AWAY
