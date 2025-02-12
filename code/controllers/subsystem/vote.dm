/// Define to mimic a span macro but for the purple font that vote specifically uses.
#define vote_font(text) ("<font color='purple'>" + text + "</font>")

SUBSYSTEM_DEF(vote)
	name = "Vote"
	wait = 1 SECONDS
	flags = SS_KEEP_TIMING
	init_order = INIT_ORDER_VOTE
	runlevels = RUNLEVEL_LOBBY | RUNLEVELS_DEFAULT

	/// A list of all generated action buttons
	var/list/datum/action/generated_actions = list()
	/// All votes that we can possible vote for.
	var/list/datum/vote/possible_votes = list()
	/// The vote we're currently voting on.
	var/datum/vote/current_vote
	/// A list of all ckeys who have voted for the current vote.
	var/list/voted = list()
	/// A list of all ckeys currently voting for the current vote.
	var/list/voting = list()
	/// World.time we started our last vote
	var/last_vote_time = -INFINITY

/datum/controller/subsystem/vote/Initialize()
	for(var/vote_type in subtypesof(/datum/vote))
		var/datum/vote/vote = new vote_type()
		if(!vote.is_accessible_vote())
			qdel(vote)
			continue

		possible_votes[vote.name] = vote

	return SS_INIT_SUCCESS

// Called by master_controller
/datum/controller/subsystem/vote/fire()
	if(!current_vote)
		return
	current_vote.time_remaining = round((current_vote.started_time + CONFIG_GET(number/vote_period) - world.time) / 10)
	if(current_vote.time_remaining < 0)
		end_vote()

/// Ends the current vote.
/datum/controller/subsystem/vote/proc/end_vote()
	ASSERT(current_vote)
	process_vote_result()
	SStgui.close_uis(src)
	reset()

/// Resets all of our vars after votes conclude / are cancelled.
/datum/controller/subsystem/vote/proc/reset()
	voted.Cut()
	voting.Cut()

	current_vote?.reset()
	current_vote = null

	QDEL_LIST(generated_actions)

	SStgui.update_uis(src)

/**
 * Process the results of the vote.
 * Collects all the winners, breaks any ties that occur,
 * prints the results of the vote to the world,
 * and finally follows through with the effects of the vote.
 */
/datum/controller/subsystem/vote/proc/process_vote_result()

	// First collect all the non-voters we have.
	var/list/non_voters = GLOB.directory.Copy() - voted
	// Remove AFK or clientless non-voters.
	for(var/non_voter_ckey in non_voters)
		var/client/non_voter_client = non_voters[non_voter_ckey]
		if(!istype(non_voter_client) || non_voter_client.is_afk())
			non_voters -= non_voter_ckey

	// Now get the result of the vote.
	// This is a list, as we could have a tie (multiple winners).
	var/list/winners = current_vote.get_vote_result(non_voters)

	// Now we should determine who actually won the vote.
	var/final_winner
	// 1 winner? That's the winning option
	if(length(winners) == 1)
		final_winner = winners[1]

	// More than 1 winner? Tiebreaker between all the winners
	else if(length(winners) > 1)
		final_winner = current_vote.tiebreaker(winners)

	// Announce the results of the vote to the world.
	var/to_display = current_vote.get_result_text(winners, final_winner, non_voters)

	var/total_votes = 0
	var/list/vote_choice_data = list()
	for(var/choice in current_vote.choices)
		var/choice_votes = current_vote.choices[choice]
		total_votes += choice_votes
		vote_choice_data["[choice]"] = choice_votes

	// stringify the winners to prevent potential unimplemented serialization errors.
	// Perhaps this can be removed in the future and we assert that vote choices must implement serialization.
	var/final_winner_string = (final_winner && "[final_winner]") || "NO WINNER"
	var/list/winners_string = list()

	if(length(winners))
		for(var/winner in winners)
			winners_string += "[winner]"
	else
		winners_string = list("NO WINNER")

	var/list/vote_log_data = list(
		"type" = "[current_vote.type]",
		"choices" = vote_choice_data,
		"total" = total_votes,
		"winners" = winners_string,
		"final_winner" = final_winner_string,
	)
	log_vote("vote finalized", vote_log_data)
	if(to_display)
		to_chat(world, span_infoplain(vote_font("[to_display]")))

	// Finally, doing any effects on vote completion
	current_vote.finalize_vote(final_winner)

/**
 * One selection per person, and the selection with the most votes wins.
 */
/datum/controller/subsystem/vote/proc/submit_single_vote(mob/voter, their_vote)
	if(!current_vote)
		return
	if(!voter?.ckey)
		return
	if(CONFIG_GET(flag/no_dead_vote) && voter.stat == DEAD && !voter.client?.holder)
		return

	// If user has already voted, remove their specific vote
	if(voter.ckey in current_vote.choices_by_ckey)
		var/their_old_vote = current_vote.choices_by_ckey[voter.ckey]
		current_vote.choices[their_old_vote]--

	else
		voted += voter.ckey

	current_vote.choices_by_ckey[voter.ckey] = their_vote
	current_vote.choices[their_vote]++

	return TRUE

/**
 * Any number of selections per person, and the selection with the most votes wins.
 */
/datum/controller/subsystem/vote/proc/submit_multi_vote(mob/voter, their_vote)
	if(!current_vote)
		return
	if(!voter?.ckey)
		return
	if(CONFIG_GET(flag/no_dead_vote) && voter.stat == DEAD && !voter.client?.holder)
		return

	else
		voted += voter.ckey

	if(current_vote.choices_by_ckey[voter.ckey + their_vote] == 1)
		current_vote.choices_by_ckey[voter.ckey + their_vote] = 0
		current_vote.choices[their_vote]--

	else
		current_vote.choices_by_ckey[voter.ckey + their_vote] = 1
		current_vote.choices[their_vote]++

	return TRUE

/**
 * Initiates a vote, allowing all players to vote on something.
 *
 * * vote_type - The type of vote to initiate. Can be a [/datum/vote] typepath, a [/datum/vote] instance, or the name of a vote datum.
 * * vote_initiator_name - The ckey (if player initiated) or name that initiated a vote. Ex: "UristMcAdmin", "the server"
 * * vote_initiator - If a person / mob initiated the vote, this is the mob that did it
 * * forced - Whether we're forcing the vote to go through regardless of existing votes or other circumstances.
 */
/datum/controller/subsystem/vote/proc/initiate_vote(vote_type, vote_initiator_name, mob/vote_initiator, forced = FALSE)
	if(!can_vote_start(vote_initiator, forced))
		return FALSE

	// Get our actual datum
	var/datum/vote/to_vote
	// If we were passed a path: find the path in possible_votes
	if(ispath(vote_type, /datum/vote))
		var/datum/vote/vote_path = vote_type
		to_vote = possible_votes[initial(vote_path.name)]

	// If we were passed an instance: use the instance
	else if(istype(vote_type, /datum/vote))
		to_vote = vote_type

	// If we got neither a path or an instance, it could be a vote name, but is likely just an error / null
	else
		to_vote = possible_votes[vote_type]
		if(!to_vote)
			stack_trace("Voting initiate_vote was passed an invalid vote type. (Got: [vote_type || "null"])")

	// No valid vote found? No vote
	if(!istype(to_vote))
		if(vote_initiator)
			to_chat(vote_initiator, span_warning("Invalid voting choice."))
		return FALSE

	// Vote can't be initiated in our circumstances? No vote
	if(to_vote.can_be_initiated(forced) != VOTE_AVAILABLE)
		return FALSE

	// Okay, we're ready to actually create a vote -
	// Do a reset, just to make sure
	reset()

	// Try to create the vote. If the creation fails, no vote
	if(!to_vote.create_vote(vote_initiator))
		return FALSE

	if(!vote_initiator_name && vote_initiator)
		vote_initiator_name = vote_initiator.key

	// Okay, the vote's happening now, for real. Set it up.
	current_vote = to_vote
	last_vote_time = world.time

	var/duration = CONFIG_GET(number/vote_period)
	var/to_display = current_vote.initiate_vote(vote_initiator_name, duration)

	log_vote(to_display)
	to_chat(world, custom_boxed_message("purple_box center", span_infoplain(vote_font("[span_bold(to_display)]<br>\
		Type <b>vote</b> or click <a href='byond://winset?command=vote'>here</a> to place your votes.\n\
		You have [DisplayTimeText(duration)] to vote."))))

	// And now that it's going, give everyone a voter action
	for(var/client/new_voter as anything in GLOB.clients)
		var/datum/action/vote/voting_action = new()
		voting_action.name = "Vote: [current_vote.override_question || current_vote.name]"
		voting_action.Grant(new_voter.mob)

		new_voter.player_details.player_actions += voting_action
		generated_actions += voting_action
		if(current_vote.vote_sound && new_voter.prefs.read_preference(/datum/preference/toggle/sound_announcements))
			SEND_SOUND(new_voter, sound(current_vote.vote_sound))

	return TRUE

/**
 * Checks if we can start a vote.
 *
 * * vote_initiator - The mob that initiated the vote.
 * * forced - Whether we're forcing the vote to go through regardless of existing votes or other circumstances.
 *
 * Returns TRUE if we can start a vote, FALSE if we can't.
 */
/datum/controller/subsystem/vote/proc/can_vote_start(mob/vote_initiator, forced)
	// Even if it's forced we can't vote before we're set up
	if(!MC_RUNNING(init_stage))
		if(vote_initiator)
			to_chat(vote_initiator, span_warning("You cannot start a vote now, the server is not done initializing."))
		return FALSE

	if(forced)
		return TRUE

	var/next_allowed_time = last_vote_time + CONFIG_GET(number/vote_delay)
	if(next_allowed_time > world.time)
		if(vote_initiator)
			to_chat(vote_initiator, span_warning("A vote was initiated recently. You must wait [DisplayTimeText(next_allowed_time - world.time)] before a new vote can be started!"))
		return FALSE

	if(current_vote)
		if(vote_initiator)
			to_chat(vote_initiator, span_warning("There is already a vote in progress! Please wait for it to finish."))
		return FALSE

	return TRUE

/datum/controller/subsystem/vote/proc/toggle_dead_voting(mob/toggle_initiator)
	var/switch_deadvote_config = !CONFIG_GET(flag/no_dead_vote)
	CONFIG_SET(flag/no_dead_vote, switch_deadvote_config)
	var/text_verb = !switch_deadvote_config ? "enabled" : "disabled"
	log_admin("[key_name(toggle_initiator)] [text_verb] Dead Vote.")
	message_admins("[key_name_admin(toggle_initiator)] [text_verb] Dead Vote.")
	SSblackbox.record_feedback("nested tally", "admin_toggle", 1, list("Toggle Dead Vote", text_verb))

/datum/controller/subsystem/vote/ui_state()
	return GLOB.always_state

/datum/controller/subsystem/vote/ui_interact(mob/user, datum/tgui/ui)
	// Tracks who is currently voting
	voting |= user.client?.ckey
	ui = SStgui.try_update_ui(user, src, ui)
	if(!ui)
		ui = new(user, src, "VotePanel")
		ui.open()

/datum/controller/subsystem/vote/ui_data(mob/user)
	var/list/data = list()

	var/is_lower_admin = !!user.client?.holder
	var/is_upper_admin = check_rights_for(user.client, R_ADMIN)

	data["user"] = list(
		"ckey" = user.client?.ckey,
		"isGhost" = CONFIG_GET(flag/no_dead_vote) && user.stat == DEAD && !user.client?.holder,
		"isLowerAdmin" = is_lower_admin,
		"isUpperAdmin" = is_upper_admin,
		// What the current user has selected in any ongoing votes.
		"singleSelection" = current_vote?.choices_by_ckey[user.client?.ckey],
		"multiSelection" = current_vote?.choices_by_ckey,
	)

	data["voting"]= is_lower_admin ? voting : list()

	var/list/all_vote_data = list()
	for(var/vote_name in possible_votes)
		var/datum/vote/vote = possible_votes[vote_name]
		if(!istype(vote))
			continue

		var/can_vote = vote.can_be_initiated(is_lower_admin)
		var/list/vote_data = list(
			"name" = vote_name,
			"canBeInitiated" = can_vote == VOTE_AVAILABLE,
			"config" = vote.is_config_enabled(),
			"message" = can_vote == VOTE_AVAILABLE ? vote.default_message : can_vote,
		)

		if(vote == current_vote)
			var/list/choices = list()
			for(var/key in current_vote.choices)
				choices += list(list(
					"name" = key,
					"votes" = current_vote.choices[key],
				))

			data["currentVote"] = list(
				"name" = current_vote.name,
				"question" = current_vote.override_question,
				"timeRemaining" = current_vote.time_remaining,
				"countMethod" = current_vote.count_method,
				"displayStatistics" = current_vote.display_statistics,
				"choices" = choices,
				"vote" = vote_data,
			)

		all_vote_data += list(vote_data)

	data["possibleVotes"] = all_vote_data
	data["LastVoteTime"] = last_vote_time - world.time

	return data

/datum/controller/subsystem/vote/ui_static_data(mob/user)
	var/list/data = list()
	data["VoteCD"] = CONFIG_GET(number/vote_delay)
	return data

/datum/controller/subsystem/vote/ui_act(action, list/params, datum/tgui/ui, datum/ui_state/state)
	. = ..()
	if(.)
		return

	var/mob/voter = usr

	switch(action)
		if("cancel")
			if(!voter.client?.holder)
				message_admins("[key_name(voter)] tried to cancel the current vote while having no admin holder, \
					this is potentially a malicious exploit and worth noting.")
				return

			voter.log_message("cancelled a vote.", LOG_ADMIN)
			message_admins("[key_name_admin(voter)] has cancelled the current vote.")
			SStgui.close_uis(src)
			reset()
			return TRUE

		if("endNow")
			if(!voter.client?.holder)
				message_admins("[key_name(voter)] tried to end the current vote while having no admin holder, \
					this is potentially a malicious exploit and worth noting.")
				return

			voter.log_message("ended the current vote early", LOG_ADMIN)
			message_admins("[key_name_admin(voter)] has ended the current vote.")
			end_vote()
			return TRUE

		if("toggleDeadVote")
			if(!check_rights_for(voter.client, R_ADMIN))
				message_admins("[key_name(voter)] tried to toggle vote abillity for ghosts while having improper rights, \
					this is potentially a malicious exploit and worth noting.")
				return

			toggle_dead_voting(voter)
			return TRUE

		if("toggleVote")
			var/datum/vote/selected = possible_votes[params["voteName"]]
			if(!istype(selected))
				return
			if(!check_rights_for(voter.client, R_ADMIN))
				message_admins("[key_name(voter)] tried to toggle vote availability while having improper rights, \
					this is potentially a malicious exploit and worth noting.")
				return

			return selected.toggle_votable()

		if("callVote")
			var/datum/vote/selected = possible_votes[params["voteName"]]
			if(!istype(selected))
				return

			// Whether the user actually can initiate this vote is checked in initiate_vote,
			// meaning you can't spoof initiate a vote you're not supposed to be able to
			return initiate_vote(
				vote_type = selected,
				vote_initiator_name = voter.key,
				vote_initiator = voter,
				forced = !!GLOB.admin_datums[voter.ckey],
			)

		if("voteSingle")
			return submit_single_vote(voter, params["voteOption"])

		if("voteMulti")
			return submit_multi_vote(voter, params["voteOption"])

		if("resetCooldown")
			if(!voter.client.holder)
				message_admins("[key_name(voter)] tried to reset the vote cooldown while having no admin holder, \
					this is potentially a malicious exploit and worth noting.")
				return

			last_vote_time = -INFINITY
			return TRUE

/datum/controller/subsystem/vote/ui_close(mob/user)
	voting -= user.client?.ckey

/// Mob level verb that allows players to vote on the current vote.
/mob/verb/vote()
	set category = "OOC"
	set name = "Vote"

	if(!SSvote.initialized)
		to_chat(usr, span_notice("<i>Voting is not set up yet!</i>"))
		return

	SSvote.ui_interact(usr)

/// Datum action given to mobs that allows players to vote on the current vote.
/datum/action/vote
	name = "Vote!"
	button_icon_state = "vote"
	show_to_observers = FALSE

/datum/action/vote/IsAvailable(feedback = FALSE)
	return TRUE // Democracy is always available to the free people

/datum/action/vote/Trigger(trigger_flags)
	. = ..()
	if(!.)
		return

	owner.vote()
	Remove(owner)

// We also need to remove our action from the player actions when we're cleaning up.
/datum/action/vote/Remove(mob/removed_from)
	if(removed_from.client)
		removed_from.client?.player_details.player_actions -= src

	else if(removed_from.ckey)
		var/datum/player_details/associated_details = GLOB.player_details[removed_from.ckey]
		associated_details?.player_actions -= src

	return ..()

#undef vote_font
