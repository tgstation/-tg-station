/datum/vote/map_vote
	name = "Map"
	default_message = "Vote for next round's map!"
	count_method = VOTE_COUNT_METHOD_SINGLE
	winner_method = VOTE_WINNER_METHOD_NONE
	display_statistics = FALSE
	/// Amount of viable players during out last validity check
	var/cached_pop = -1

/datum/vote/map_vote/New()
	. = ..()
	cached_pop = length(GLOB.clients)
	default_choices = SSmap_vote.get_valid_map_vote_choices()

/datum/vote/map_vote/create_vote()
	cached_pop = length(GLOB.clients)
	default_choices = SSmap_vote.get_valid_map_vote_choices()
	. = ..()
	if(!.)
		return FALSE

	if(length(choices) == 1) // Only one choice, no need to vote. Let's just auto-rotate it to the only remaining map because it would just happen anyways.
		var/datum/map_config/change_me_out = global.config.maplist[choices[1]]
		finalize_vote(choices[1])// voted by not voting, very sad.
		to_chat(world, span_boldannounce("The map vote has been skipped because there is only one map left to vote for. \
			The map has been changed to [change_me_out.map_name]."))
		return FALSE
	if(length(choices) == 0)
		to_chat(world, span_boldannounce("A map vote was called, but there are no maps to vote for! \
			Players, complain to the admins. Admins, complain to the coders."))
		return FALSE

	return TRUE

/datum/vote/map_vote/toggle_votable()
	CONFIG_SET(flag/allow_vote_map, !CONFIG_GET(flag/allow_vote_map))

/datum/vote/map_vote/is_config_enabled()
	return CONFIG_GET(flag/allow_vote_map)

/datum/vote/map_vote/can_be_initiated(forced)
	. = ..()
	if(. != VOTE_AVAILABLE)
		return .

	if(SSmap_vote.next_map_config)
		return "The next map has already been selected."

	if (cached_pop != length(GLOB.clients))
		cached_pop = length(GLOB.clients)
		default_choices = SSmap_vote.get_valid_map_vote_choices()

	var/num_choices = length(default_choices)
	if(num_choices <= 1)
		return "There [num_choices == 1 ? "is only one map" : "are no maps"] to choose from."

	return VOTE_AVAILABLE

/datum/vote/map_vote/get_result_text(list/all_winners, real_winner, list/non_voters)
	return null

/datum/vote/map_vote/get_vote_result(list/non_voters)
	// Even if we have default no vote off,
	// if our default map is null for some reason, we shouldn't continue
	if(CONFIG_GET(flag/default_no_vote) || isnull(global.config.defaultmap))
		return ..()

	for(var/non_voter_ckey in non_voters)
		var/client/non_voter_client = non_voters[non_voter_ckey]
		// Non-voters will have their preferred map voted for automatically.
		var/their_preferred_map = non_voter_client?.prefs.read_preference(/datum/preference/choiced/preferred_map)
		// If the non-voter's preferred map is null for some reason, we just use the default map.
		var/voting_for = their_preferred_map || global.config.defaultmap.map_name

		if(voting_for in choices)
			choices[voting_for] += 1

	return ..()

/datum/vote/map_vote/finalize_vote(winning_option)
	SSmap_vote.finalize_map_vote(src)
