/**
 * Logs a message to the mob_tags log, including the mobs tag
 * Arguments:
 * * text - text to log.
 */
/mob/proc/log_mob_tag(text, list/data)
	logger.Log(LOG_CATEGORY_DEBUG_MOBTAG, text, data)

/proc/log_silicon(text, list/data)
	logger.Log(LOG_CATEGORY_SILICON, text, data)


/// Logs a message in a mob's individual log, and in the global logs as well if log_globally is true
/mob/log_message(message, message_type, color = null, log_globally = TRUE, list/data)
	if(!LAZYLEN(message))
		stack_trace("Empty message")
		return

	// Cannot use the list as a map if the key is a number, so we stringify it (thank you BYOND)
	var/smessage_type = num2text(message_type, MAX_BITFLAG_DIGITS)

	if(HAS_CONNECTED_PLAYER(src))
		if(!islist(persistent_client.logging[smessage_type]))
			persistent_client.logging[smessage_type] = list()

	if(!islist(logging[smessage_type]))
		logging[smessage_type] = list()

	var/colored_message = message
	if(color)
		if(color[1] == "#")
			colored_message = "<font color=[color]>[message]</font>"
		else
			colored_message = "<font color='[color]'>[message]</font>"

	//This makes readability a bit better for admins.
	switch(message_type)
		if(LOG_WHISPER)
			colored_message = "(WHISPER) [colored_message]"
		if(LOG_OOC)
			colored_message = "(OOC) [colored_message]"
		if(LOG_ASAY)
			colored_message = "(ASAY) [colored_message]"
		if(LOG_EMOTE)
			colored_message = "(EMOTE) [colored_message]"
		if(LOG_RADIO_EMOTE)
			colored_message = "(RADIOEMOTE) [colored_message]"

	var/list/timestamped_message = list("\[[time_stamp(format = "YYYY-MM-DD hh:mm:ss")]\] [key_name_and_tag(src)] [loc_name(src)] (Event #[LAZYLEN(logging[smessage_type])])" = colored_message)

	logging[smessage_type] += timestamped_message

	if(HAS_CONNECTED_PLAYER(src))
		persistent_client.logging[smessage_type] += timestamped_message

	..()
