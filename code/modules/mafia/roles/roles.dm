/datum/mafia_role
	var/name = JOB_ASSISTANT
	var/desc = "You are a crewmember without any special abilities."
	var/win_condition = "kill all mafia and solo killing roles."
	var/team = MAFIA_TEAM_TOWN
	///how the random setup chooses which roles get put in
	var/role_type = TOWN_OVERFLOW
	///role flags (special status of roles like detection immune)
	var/role_flags = NONE

	///The mafia popup we edit text to give different alerts for (such as when to vote).
	var/atom/movable/screen/mafia_popup/mafia_alert
	///List of all mafia abilities this role is able to perform.
	var/list/datum/mafia_ability/role_unique_actions = list()
	///The player's written notes, that they can send to chat at any time.
	var/written_notes

	///The ckey of the person playing as this Mafia role, CAN BE NULL IN FAVOR OF player_pda.
	var/player_key
	///The PDA of the person playing as this Mafia role, CAN BE NULL IN FAVOR OF player_key.
	var/obj/item/modular_computer/player_pda

	///List of all messages this role got throughout the game.
	var/list/role_messages = list()


	var/mob/living/carbon/human/body
	var/obj/effect/landmark/mafia/assigned_landmark

	///The Mafia innate action panel that allows players to view the game's state.
	var/datum/action/innate/mafia_panel/mafia_panel

	///how many votes submitted when you vote. used in voting and deciding victory.
	var/vote_power = 1
	///what they get equipped with when they are revealed
	var/datum/outfit/revealed_outfit = /datum/outfit/mafia/assistant
	///what the role gets when it wins a game
	var/winner_award = /datum/award/achievement/mafia/assistant

	///so mafia have to also kill them to have a majority
	var/game_status = MAFIA_ALIVE

	///icon state in the mafia dmi of the hud of the role, used in the mafia ui
	var/hud_icon = "hudassistant"
	///icon state in the mafia dmi of the hud of the role, used in the mafia ui
	var/revealed_icon = "assistant"
	///set this to something cool for antagonists and their window will look different
	var/special_ui_theme

	///The cooldown between being able to send your will in chat.
	COOLDOWN_DECLARE(note_chat_sending_cooldown)

/datum/mafia_role/New(datum/mafia_controller/game)
	. = ..()
	mafia_panel = new(null, game)
	for(var/datum/mafia_ability/abilities as anything in role_unique_actions + /datum/mafia_ability/voting)
		role_unique_actions += new abilities(game, src)
		role_unique_actions -= abilities

/datum/mafia_role/Destroy(force)
	UnregisterSignal(body, COMSIG_MOB_SAY)
	QDEL_NULL(mafia_alert)
	QDEL_NULL(mafia_panel)
	QDEL_LIST(role_unique_actions)
	//we null these instead of qdel because Mafia controller's mapdeleter deletes it all.
	assigned_landmark = null
	body = null
	role_messages.Cut()
	return ..()

/datum/mafia_role/proc/register_body(mob/living/carbon/human/new_body)
	if(body)
		UnregisterSignal(new_body, COMSIG_MOB_SAY)
		mafia_panel.Remove(body)
	body = new_body
	RegisterSignal(new_body, COMSIG_MOB_SAY, PROC_REF(handle_speech))
	mafia_panel.Grant(new_body)

/**
 * send_message_to_player
 *
 * Sends a message to a player, checking if they are playing through a PDA or not.
 * Args:
 * * message - The message to send to the person
 * * balloon_alert - Whether it should be as a balloon alert, only if it's to a non-PDA user.
 */
/datum/mafia_role/proc/send_message_to_player(message, balloon_alert = FALSE)
	if(player_pda)
		role_messages += message
		return
	if(balloon_alert)
		body.balloon_alert(body, message)
		return
	to_chat(body, message)

/**
 * handle_speech
 *
 * Handles Mafia roles talking in chat.
 * First it will go through their abilities for Ability-specific speech,
 * if none affects it, we will go to day chat.
 */
/datum/mafia_role/proc/handle_speech(datum/source, list/speech_args)
	SIGNAL_HANDLER
	for(var/datum/mafia_ability/abilities as anything in role_unique_actions)
		if(abilities.handle_speech(source, speech_args))
			return
	var/datum/mafia_controller/mafia_game = GLOB.mafia_game
	if(!mafia_game || mafia_game.phase == MAFIA_PHASE_NIGHT)
		return
	var/message = "[source]: [html_decode(speech_args[SPEECH_MESSAGE])]"
	mafia_game.send_message(message, log_only = TRUE)

/**
 * Puts the player in their body and keeps track of their previous one to put them back in later.
 * Adds the playing_mafia trait so people examining them will know why they're currently lacking a soul.
 */
/datum/mafia_role/proc/put_player_in_body(client/player)
	if(player.mob.mind)
		body.AddComponent( \
			/datum/component/temporary_body, \
			old_mind = player.mob.mind, \
			old_body = player.mob.mind.current, \
		)
	body.PossessByPlayer(player.key)

/**
 * Tests kill immunities, if nothing prevents the kill, kills this role.
 *
 * Does not count as visiting, see visit proc.
 */
/datum/mafia_role/proc/kill(datum/mafia_controller/game, datum/mafia_role/attacker, lynch = FALSE)
	if(game_status == MAFIA_DEAD)
		return FALSE
	if(attacker && (attacker.role_flags & ROLE_ROLEBLOCKED))
		return FALSE
	if(SEND_SIGNAL(src, COMSIG_MAFIA_ON_KILL, game, attacker, lynch) & MAFIA_PREVENT_KILL)
		return FALSE
	game_status = MAFIA_DEAD
	body.death()
	if(lynch)
		reveal_role(game, verbose = TRUE)
	game.living_roles -= src
	return TRUE

/datum/mafia_role/proc/greet()
	mafia_alert = new(body, src)
	SEND_SOUND(body, 'sound/ambience/misc/ambifailure.ogg')
	to_chat(body, span_danger("You are the [name]."))
	to_chat(body, span_danger("[desc]"))
	switch(team)
		if(MAFIA_TEAM_MAFIA)
			to_chat(body,span_danger("You and your co-conspirators win if you outnumber crewmembers."))
		if(MAFIA_TEAM_TOWN)
			to_chat(body,span_danger("You are a crewmember. Find out and lynch the changelings!"))
		if(MAFIA_TEAM_SOLO)
			to_chat(body,span_danger("You are not aligned to town or mafia. Accomplish your own objectives!"))
	to_chat(body, "<span class='warningplain'><b>Be sure to read <a href=\"https://tgstation13.org/wiki/Mafia\">the wiki page</a> to learn more, if you have no idea what's going on.</b></span>")

/datum/mafia_role/proc/reveal_role(datum/mafia_controller/game, verbose = FALSE)
	if((role_flags & ROLE_REVEALED))
		return
	if(verbose)
		game.send_message("<span class='big bold notice'>It is revealed that the true role of [body] [game_status == MAFIA_ALIVE ? "is" : "was"] [name]!</span>")
	var/list/oldoutfit = body.get_equipped_items()
	for(var/thing in oldoutfit)
		qdel(thing)
	special_reveal_equip(game)
	body.equipOutfit(revealed_outfit)
	role_flags |= ROLE_REVEALED

/datum/mafia_role/proc/special_reveal_equip(datum/mafia_controller/game)
	return

/datum/mafia_role/proc/show_help(clueless)
	var/list/result = list()
	var/team_desc = ""
	var/team_span = ""
	var/the = TRUE
	switch(team)
		if(MAFIA_TEAM_TOWN)
			team_desc = "Town"
			team_span = "nicegreen"
		if(MAFIA_TEAM_MAFIA)
			team_desc = "Mafia"
			team_span = "red"
		if(MAFIA_TEAM_SOLO)
			team_desc = "Nobody"
			team_span = "comradio"
			the = FALSE
	result += span_notice("The [span_bold("[name]")] is aligned with [the ? "the " : ""]<span class='[team_span]'>[team_desc]</span>")
	result += "<span class='bold notice'>\"[initial(desc)]\"</span>"
	result += span_notice("[name] wins when they [win_condition]")
	to_chat(clueless, result.Join("</br>"))
