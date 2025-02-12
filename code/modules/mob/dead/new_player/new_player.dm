///Cooldown for the Reset Lobby Menu HUD verb
#define RESET_HUD_INTERVAL 15 SECONDS
/mob/dead/new_player
	flags_1 = NONE
	invisibility = INVISIBILITY_ABSTRACT
	density = FALSE
	stat = DEAD
	hud_type = /datum/hud/new_player
	hud_possible = list()

	var/ready = FALSE
	/// Referenced when you want to delete the new_player later on in the code.
	var/spawning = FALSE
	/// For instant transfer once the round is set up
	var/mob/living/new_character
	///Used to make sure someone doesn't get spammed with messages if they're ineligible for roles.
	var/ineligible_for_roles = FALSE
	/// Used to track if the player's jobs menu sent a message saying it successfully mounted.
	var/jobs_menu_mounted = FALSE
	///Cooldown for the Reset Lobby Menu HUD verb
	COOLDOWN_DECLARE(reset_hud_cooldown)

/mob/dead/new_player/Initialize(mapload)
	if(client && SSticker.state == GAME_STATE_STARTUP)
		var/atom/movable/screen/splash/fade_out = new(null, null, client, TRUE)
		fade_out.Fade(TRUE)

	if(length(GLOB.newplayer_start))
		forceMove(pick(GLOB.newplayer_start))
	else
		forceMove(locate(1,1,1))

	. = ..()

	GLOB.new_player_list += src
	add_verb(src, /mob/dead/new_player/proc/reset_menu_hud)

/mob/dead/new_player/Destroy()
	GLOB.new_player_list -= src

	return ..()

/mob/dead/new_player/mob_negates_gravity()
	return TRUE //no need to calculate if they have gravity.

/mob/dead/new_player/prepare_huds()
	return

/mob/dead/new_player/Topic(href, href_list)
	if (usr != src)
		return

	if (!client)
		return

	if (client.interviewee)
		return

	if (href_list["viewpoll"])
		var/datum/poll_question/poll = locate(href_list["viewpoll"]) in GLOB.polls
		poll_player(poll)

	if (href_list["votepollref"])
		var/datum/poll_question/poll = locate(href_list["votepollref"]) in GLOB.polls
		vote_on_poll_handler(poll, href_list)

//When you cop out of the round (NB: this HAS A SLEEP FOR PLAYER INPUT IN IT)
/mob/dead/new_player/proc/make_me_an_observer()
	if(QDELETED(src) || !src.client)
		ready = PLAYER_NOT_READY
		return FALSE

	var/less_input_message
	if(SSlag_switch.measures[DISABLE_DEAD_KEYLOOP])
		less_input_message = " - Notice: Observer freelook is currently disabled."
	// Don't convert this to tgui please, it's way too important
	var/this_is_like_playing_right = alert(usr, "Are you sure you wish to observe? You will not be able to play this round![less_input_message]", "Observe", "Yes", "No")
	if(QDELETED(src) || !src.client || this_is_like_playing_right != "Yes")
		ready = PLAYER_NOT_READY
		return FALSE

	var/mob/dead/observer/observer = new()
	spawning = TRUE

	observer.started_as_observer = TRUE
	var/obj/effect/landmark/observer_start/O = locate(/obj/effect/landmark/observer_start) in GLOB.landmarks_list
	to_chat(src, span_notice("Now teleporting."))
	if (O)
		observer.forceMove(O.loc)
	else
		to_chat(src, span_notice("Teleporting failed. Ahelp an admin please"))
		stack_trace("There's no freaking observer landmark available on this map or you're making observers before the map is initialised")

	observer.PossessByPlayer(key)
	observer.client = client
	observer.set_ghost_appearance()
	if(observer.client && observer.client.prefs)
		observer.real_name = observer.client.prefs.read_preference(/datum/preference/name/real_name)
		observer.name = observer.real_name
		observer.client.init_verbs()
		observer.persistent_client.time_of_death = world.time

	observer.update_appearance()
	observer.stop_sound_channel(CHANNEL_LOBBYMUSIC)
	deadchat_broadcast(" has observed.", "<b>[observer.real_name]</b>", follow_target = observer, turf_target = get_turf(observer), message_type = DEADCHAT_DEATHRATTLE)
	QDEL_NULL(mind)
	qdel(src)
	return TRUE

/proc/get_job_unavailable_error_message(retval, jobtitle)
	switch(retval)
		if(JOB_AVAILABLE)
			return "[jobtitle] is available."
		if(JOB_UNAVAILABLE_GENERIC)
			return "[jobtitle] is unavailable."
		if(JOB_UNAVAILABLE_BANNED)
			return "You are currently banned from [jobtitle]."
		if(JOB_UNAVAILABLE_PLAYTIME)
			return "You do not have enough relevant playtime for [jobtitle]."
		if(JOB_UNAVAILABLE_ACCOUNTAGE)
			return "Your account is not old enough for [jobtitle]."
		if(JOB_UNAVAILABLE_SLOTFULL)
			return "[jobtitle] is already filled to capacity."
		if(JOB_UNAVAILABLE_ANTAG_INCOMPAT)
			return "[jobtitle] is not compatible with some antagonist role assigned to you."
		if(JOB_UNAVAILABLE_AGE)
			return "Your character is not old enough for [jobtitle]."

	return GENERIC_JOB_UNAVAILABLE_ERROR

/mob/dead/new_player/proc/IsJobUnavailable(rank, latejoin = FALSE)
	var/datum/job/job = SSjob.get_job(rank)
	if(!(job.job_flags & JOB_NEW_PLAYER_JOINABLE))
		return JOB_UNAVAILABLE_GENERIC
	if((job.current_positions >= job.total_positions) && job.total_positions != -1)
		if(is_assistant_job(job))
			if(isnum(client.player_age) && client.player_age <= 14) //Newbies can always be assistants
				return JOB_AVAILABLE
			for(var/datum/job/other_job as anything in SSjob.joinable_occupations)
				if(other_job.current_positions < other_job.total_positions && other_job != job)
					return JOB_UNAVAILABLE_SLOTFULL
		else
			return JOB_UNAVAILABLE_SLOTFULL

	var/eligibility_check = SSjob.check_job_eligibility(src, job, "Mob IsJobUnavailable")
	if(eligibility_check != JOB_AVAILABLE)
		return eligibility_check

	if(latejoin && !job.special_check_latejoin(client))
		return JOB_UNAVAILABLE_GENERIC
	return JOB_AVAILABLE

/mob/dead/new_player/proc/AttemptLateSpawn(rank)
	// Check that they're picking someone new for new character respawning
	if(CONFIG_GET(flag/allow_respawn) == RESPAWN_FLAG_NEW_CHARACTER)
		if("[client.prefs.default_slot]" in persistent_client.joined_as_slots)
			tgui_alert(usr, "You already have played this character in this round!")
			return FALSE

	var/error = IsJobUnavailable(rank)
	if(error != JOB_AVAILABLE)
		tgui_alert(usr, get_job_unavailable_error_message(error, rank))
		return FALSE

	if(SSshuttle.arrivals)
		if(SSshuttle.arrivals.damaged && CONFIG_GET(flag/arrivals_shuttle_require_safe_latejoin))
			tgui_alert(usr,"The arrivals shuttle is currently malfunctioning! You cannot join.")
			return FALSE

		if(CONFIG_GET(flag/arrivals_shuttle_require_undocked))
			SSshuttle.arrivals.RequireUndocked(src)

	//Remove the player from the join queue if he was in one and reset the timer
	SSticker.queued_players -= src
	SSticker.queue_delay = 4

	var/datum/job/job = SSjob.get_job(rank)

	if(!SSjob.assign_role(src, job, TRUE))
		tgui_alert(usr, "There was an unexpected error putting you into your requested job. If you cannot join with any job, you should contact an admin.")
		return FALSE

	mind.late_joiner = TRUE
	var/atom/destination = mind.assigned_role.get_latejoin_spawn_point()
	if(!destination)
		CRASH("Failed to find a latejoin spawn point.")
	var/mob/living/character = create_character(destination)
	if(!character)
		CRASH("Failed to create a character for latejoin.")
	transfer_character()

	SSjob.equip_rank(character, job, character.client)
	job.after_latejoin_spawn(character)

	#define IS_NOT_CAPTAIN 0
	#define IS_ACTING_CAPTAIN 1
	#define IS_FULL_CAPTAIN 2
	var/is_captain = IS_NOT_CAPTAIN
	var/captain_sound = 'sound/announcer/notice/notice2.ogg'
	// If we already have a captain, are they a "Captain" rank and are we allowing multiple of them to be assigned?
	if(is_captain_job(job))
		is_captain = IS_FULL_CAPTAIN
		captain_sound = 'sound/announcer/announcement/announce.ogg'
	// If we don't have an assigned cap yet, check if this person qualifies for some from of captaincy.
	else if(!SSjob.assigned_captain && ishuman(character) && SSjob.chain_of_command[rank] && !is_banned_from(character.ckey, list(JOB_CAPTAIN)))
		is_captain = IS_ACTING_CAPTAIN
	if(is_captain != IS_NOT_CAPTAIN)
		minor_announce(job.get_captaincy_announcement(character), sound_override = captain_sound)
		SSjob.promote_to_captain(character, is_captain == IS_ACTING_CAPTAIN)
	#undef IS_NOT_CAPTAIN
	#undef IS_ACTING_CAPTAIN
	#undef IS_FULL_CAPTAIN

	SSticker.minds += character.mind
	character.client.init_verbs() // init verbs for the late join
	var/mob/living/carbon/human/humanc
	if(ishuman(character))
		humanc = character //Let's retypecast the var to be human,

	if(humanc) //These procs all expect humans
		if(SSshuttle.arrivals)
			SSshuttle.arrivals.QueueAnnounce(humanc, rank)
		else
			announce_arrival(humanc, rank)
		AddEmploymentContract(humanc)

		humanc.increment_scar_slot()
		humanc.load_persistent_scars()

		if(GLOB.curse_of_madness_triggered)
			give_madness(humanc, GLOB.curse_of_madness_triggered)

	GLOB.joined_player_list += character.ckey

	if(CONFIG_GET(flag/allow_latejoin_antagonists) && humanc) //Borgs aren't allowed to be antags. Will need to be tweaked if we get true latejoin ais.
		if(SSshuttle.emergency)
			switch(SSshuttle.emergency.mode)
				if(SHUTTLE_RECALL, SHUTTLE_IDLE)
					SSdynamic.make_antag_chance(humanc)
				if(SHUTTLE_CALL)
					if(SSshuttle.emergency.timeLeft(1) > initial(SSshuttle.emergency_call_time)*0.5)
						SSdynamic.make_antag_chance(humanc)

	if((job.job_flags & JOB_ASSIGN_QUIRKS) && humanc && CONFIG_GET(flag/roundstart_traits))
		SSquirks.AssignQuirks(humanc, humanc.client)

	if(humanc) // Quirks may change manifest datapoints, so inject only after assigning quirks
		GLOB.manifest.inject(humanc)

	var/area/station/arrivals = GLOB.areas_by_type[/area/station/hallway/secondary/entry]
	if(humanc && arrivals && !arrivals.power_environ) //arrivals depowered
		humanc.put_in_hands(new /obj/item/crowbar/large/emergency(get_turf(humanc))) //if hands full then just drops on the floor
	log_manifest(character.mind.key, character.mind, character, latejoin = TRUE)

/mob/dead/new_player/proc/AddEmploymentContract(mob/living/carbon/human/employee)
	//TODO:  figure out a way to exclude wizards/nukeops/demons from this.
	for(var/C in GLOB.employmentCabinets)
		var/obj/structure/filingcabinet/employment/employmentCabinet = C
		if(!employmentCabinet.virgin)
			employmentCabinet.addFile(employee)

/// Creates, assigns and returns the new_character to spawn as. Assumes a valid mind.assigned_role exists.
/mob/dead/new_player/proc/create_character(atom/destination)
	spawning = TRUE

	mind.active = FALSE //we wish to transfer the key manually
	var/mob/living/spawning_mob = mind.assigned_role.get_spawn_mob(client, destination)
	if(QDELETED(src) || !HAS_CONNECTED_PLAYER(src))
		return // Disconnected while checking for the appearance ban.

	if(!isAI(spawning_mob)) // Unfortunately there's still snowflake AI code out there.
		// transfer_to sets mind to null
		var/datum/mind/preserved_mind = mind
		preserved_mind.original_character_slot_index = client.prefs.default_slot
		preserved_mind.transfer_to(spawning_mob) //won't transfer key since the mind is not active
		preserved_mind.set_original_character(spawning_mob)

	LAZYADD(persistent_client.joined_as_slots, "[client.prefs.default_slot]")
	client.init_verbs()
	. = spawning_mob
	new_character = .


/mob/dead/new_player/proc/transfer_character()
	. = new_character
	if(!.)
		return
	new_character.PossessByPlayer(key) //Manually transfer the key to log them in,
	new_character.stop_sound_channel(CHANNEL_LOBBYMUSIC)
	var/area/joined_area = get_area(new_character.loc)
	if(joined_area)
		joined_area.on_joining_game(new_character)
	SEND_GLOBAL_SIGNAL(COMSIG_GLOB_CREWMEMBER_JOINED, new_character, new_character.mind.assigned_role.title)
	new_character = null
	qdel(src)

/mob/dead/new_player/proc/ViewManifest()
	if(!client)
		return
	if(world.time < client.crew_manifest_delay)
		return
	client.crew_manifest_delay = world.time + (1 SECONDS)

	GLOB.manifest.ui_interact(src)

/mob/dead/new_player/Move()
	return 0

// Used to make sure that a player has a valid job preference setup, used to knock players out of eligibility for anything if their prefs don't make sense.
// A "valid job preference setup" in this situation means at least having one job set to low, or not having "return to lobby" enabled
// Prevents "antag rolling" by setting antag prefs on, all jobs to never, and "return to lobby if preferences not available"
// Doing so would previously allow you to roll for antag, then send you back to lobby if you didn't get an antag role
// This also does some admin notification and logging as well, as well as some extra logic to make sure things don't go wrong
/mob/dead/new_player/proc/check_preferences()
	if(!client)
		return FALSE //Not sure how this would get run without the mob having a client, but let's just be safe.
	if(client.prefs.read_preference(/datum/preference/choiced/jobless_role) != RETURNTOLOBBY)
		return TRUE
	// If they have antags enabled, they're potentially doing this on purpose instead of by accident. Notify admins if so.
	var/has_antags = FALSE
	if(client.prefs.be_special.len > 0)
		has_antags = TRUE
	if(client.prefs.job_preferences.len == 0)
		if(!ineligible_for_roles)
			to_chat(src, span_danger("You have no jobs enabled, along with return to lobby if job is unavailable. This makes you ineligible for any round start role, please update your job preferences."))
		ineligible_for_roles = TRUE
		ready = PLAYER_NOT_READY
		if(has_antags)
			log_admin("[src.ckey] has no jobs enabled, return to lobby if job is unavailable enabled and [client.prefs.be_special.len] antag preferences enabled. The player has been forcefully returned to the lobby.")
			message_admins("[src.ckey] has no jobs enabled, return to lobby if job is unavailable enabled and [client.prefs.be_special.len] antag preferences enabled. This is an old antag rolling technique. The player has been asked to update their job preferences and has been forcefully returned to the lobby.")
		return FALSE //This is the only case someone should actually be completely blocked from antag rolling as well
	return TRUE

/**
 * Prepares a client for the interview system, and provides them with a new interview
 *
 * This proc will both prepare the user by removing all verbs from them, as well as
 * giving them the interview form and forcing it to appear.
 */
/mob/dead/new_player/proc/register_for_interview()
	// First we detain them by removing all the verbs they have on client
	for (var/v in client.verbs)
		var/procpath/verb_path = v
		remove_verb(client, verb_path)

	// Then remove those on their mob as well
	for (var/v in verbs)
		var/procpath/verb_path = v
		remove_verb(src, verb_path)

	// Then we create the interview form and show it to the client
	var/datum/interview/I = GLOB.interviews.interview_for_client(client)
	if (I)
		I.ui_interact(src)

	// Add verb for re-opening the interview panel, fixing chat and re-init the verbs for the stat panel
	add_verb(src, /mob/dead/new_player/proc/open_interview)
	add_verb(client, /client/verb/fix_tgui_panel)

///Resets the Lobby Menu HUD, recreating and reassigning it to the new player
/mob/dead/new_player/proc/reset_menu_hud()
	set name = "Reset Lobby Menu HUD"
	set category = "OOC"
	var/mob/dead/new_player/new_player = usr
	if(!COOLDOWN_FINISHED(new_player, reset_hud_cooldown))
		to_chat(new_player, span_warning("You must wait <b>[DisplayTimeText(COOLDOWN_TIMELEFT(new_player, reset_hud_cooldown))]</b> before resetting the Lobby Menu HUD again!"))
		return
	if(!new_player?.client)
		return
	COOLDOWN_START(new_player, reset_hud_cooldown, RESET_HUD_INTERVAL)
	qdel(new_player.hud_used)
	create_mob_hud()
	to_chat(new_player, span_info("Lobby Menu HUD reset. You may reset the HUD again in <b>[DisplayTimeText(RESET_HUD_INTERVAL)]</b>."))
	hud_used.show_hud(hud_used.hud_version)

#undef RESET_HUD_INTERVAL
