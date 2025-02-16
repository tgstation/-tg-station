/*
Miauw's big Say() rewrite.
This file has the basic atom/movable level speech procs.
And the base of the send_speech() proc, which is the core of saycode.
*/
GLOBAL_LIST_INIT(freqtospan, list(
	"[FREQ_SCIENCE]" = "sciradio",
	"[FREQ_MEDICAL]" = "medradio",
	"[FREQ_ENGINEERING]" = "engradio",
	"[FREQ_SUPPLY]" = "suppradio",
	"[FREQ_SERVICE]" = "servradio",
	"[FREQ_SECURITY]" = "secradio",
	"[FREQ_COMMAND]" = "comradio",
	"[FREQ_AI_PRIVATE]" = "aiprivradio",
	"[FREQ_ENTERTAINMENT]" = "enteradio",
	"[FREQ_SYNDICATE]" = "syndradio",
	"[FREQ_UPLINK]" = "syndradio",  // this probably shouldnt appear ingame
	"[FREQ_CENTCOM]" = "centcomradio",
	"[FREQ_CTF_RED]" = "redteamradio",
	"[FREQ_CTF_BLUE]" = "blueteamradio",
	"[FREQ_CTF_GREEN]" = "greenteamradio",
	"[FREQ_CTF_YELLOW]" = "yellowteamradio",
	"[FREQ_STATUS_DISPLAYS]" = "captaincast",
))

/**
 * What makes things... talk.
 *
 * * message - The message to say.
 * * bubble_type - The type of speech bubble to use when talking
 * * spans - A list of spans to attach to the message. Includes the atom's speech span by default
 * * sanitize - Should we sanitize the message? Only set to FALSE if you have ALREADY sanitized it
 * * language - The language to speak in. Defaults to the atom's selected language
 * * ignore_spam - Should we ignore spam checks?
 * * forced - What was it forced by? null if voluntary. (NOT a boolean!)
 * * filterproof - Do we bypass the filter when checking the message?
 * * message_range - The range of the message. Defaults to 7
 * * saymode - Saymode passed to the speech
 * This is usually set automatically and is only relevant for living mobs.
 * * message_mods - A list of message modifiers, i.e. whispering/singing.
 * Most of these are set automatically but you can pass in your own pre-say.
 */
/atom/movable/proc/say(
	message,
	bubble_type,
	list/spans = list(),
	sanitize = TRUE,
	datum/language/language,
	ignore_spam = FALSE,
	forced,
	filterproof = FALSE,
	message_range = 7,
	datum/saymode/saymode,
	list/message_mods = list(),
)
	if(!try_speak(message, ignore_spam, forced, filterproof))
		return
	if(sanitize)
		message = trim(copytext_char(sanitize(message), 1, MAX_MESSAGE_LEN))
	if(!message || message == "")
		return
	spans |= speech_span
	if(!language)
		language = get_selected_language()
	message_mods[SAY_MOD_VERB] = say_mod(message, message_mods)
	send_speech(message, message_range, src, bubble_type, spans, language, message_mods, forced = forced)

/// Called when this movable hears a message from a source.
/// Returns TRUE if the message was received and understood.
/atom/movable/proc/Hear(message, atom/movable/speaker, message_language, raw_message, radio_freq, list/spans, list/message_mods = list(), message_range=0)
	SEND_SIGNAL(src, COMSIG_MOVABLE_HEAR, args)
	return TRUE


/**
 * Checks if our movable can speak the provided message, passing it through filters
 * and spam detection. Does not call can_speak. CAN include feedback messages about
 * why someone can or can't speak
 *
 * Used in [proc/say] and other methods of speech (radios) after a movable has inputted some message.
 * If you just want to check if the movable is able to speak in character, use [proc/can_speak] instead.
 *
 * Parameters:
 * - message (string): the original message
 * - ignore_spam (bool): should we ignore spam?
 * - forced (null|string): what was it forced by? null if voluntary
 * - filterproof (bool): are we filterproof?
 *
 * Returns:
 * 	TRUE of FASE depending on if our movable can speak
 */
/atom/movable/proc/try_speak(message, ignore_spam = FALSE, forced = null, filterproof = FALSE)
	return can_speak()

/**
 * Checks if our movable can currently speak, vocally, in general.
 * Should NOT include feedback messages about why someone can or can't speak

 * Used in various places to check if a movable is simply able to speak in general,
 * regardless of OOC status (being muted) and regardless of what they're actually saying.
 *
 * Checked AFTER handling of xeno channels.
 * (I'm not sure what this comment means, but it was here in the past, so I'll maintain it here.)
 *
 * allow_mimes - Determines if this check should skip over mimes. (Only matters for living mobs and up.)
 * If FALSE, this check will always fail if the movable has a mind and is miming.
 * if TRUE, we will check if the movable can speak REGARDLESS of if they have an active mime vow.
 */
/atom/movable/proc/can_speak(allow_mimes = FALSE)
	SHOULD_BE_PURE(TRUE)
	return !HAS_TRAIT(src, TRAIT_MUTE)

/atom/movable/proc/send_speech(message, range = 7, obj/source = src, bubble_type, list/spans, datum/language/message_language, list/message_mods = list(), forced = FALSE, tts_message, list/tts_filter)
	var/found_client = FALSE
	var/list/listeners = get_hearers_in_view(range, source)
	var/list/listened = list()
	for(var/atom/movable/hearing_movable as anything in listeners)
		if(!hearing_movable)//theoretically this should use as anything because it shouldnt be able to get nulls but there are reports that it does.
			stack_trace("somehow theres a null returned from get_hearers_in_view() in send_speech!")
			continue
		if(hearing_movable.Hear(null, src, message_language, message, null, spans, message_mods, range))
			listened += hearing_movable
		if(!found_client && length(hearing_movable.client_mobs_in_contents))
			found_client = TRUE

	var/tts_message_to_use = tts_message
	if(!tts_message_to_use)
		tts_message_to_use = message

	var/list/filter = list()
	if(length(voice_filter) > 0)
		filter += voice_filter

	if(length(tts_filter) > 0)
		filter += tts_filter.Join(",")

	if(voice && found_client)
		if (!CONFIG_GET(flag/tts_no_whisper) || (CONFIG_GET(flag/tts_no_whisper) && !message_mods[WHISPER_MODE]))
			INVOKE_ASYNC(SStts, TYPE_PROC_REF(/datum/controller/subsystem/tts, queue_tts_message), src, html_decode(tts_message_to_use), message_language, voice, filter.Join(","), listened, message_range = range, pitch = pitch)

/atom/movable/proc/compose_message(atom/movable/speaker, datum/language/message_language, raw_message, radio_freq, list/spans, list/message_mods = list(), visible_name = FALSE)
	//This proc uses [] because it is faster than continually appending strings. Thanks BYOND.
	//Basic span
	var/spanpart1 = "<span class='[radio_freq ? get_radio_span(radio_freq) : "game say"]'>"
	//Start name span.
	var/spanpart2 = "<span class='name'>"
	//Radio freq/name display
	var/freqpart = radio_freq ? "\[[get_radio_name(radio_freq)]\] " : ""
	//Speaker name
	var/namepart
	var/list/stored_name = list(null)

	if(iscarbon(speaker)) //First, try to pull the modified title from a carbon's ID. This will override both visual and audible names.
		var/mob/living/carbon/carbon_human = speaker
		var/obj/item/id_slot = carbon_human.get_item_by_slot(ITEM_SLOT_ID)
		if(id_slot)
			var/obj/item/card/id/id_card = id_slot?.GetID()
			if(id_card)
				SEND_SIGNAL(id_card, COMSIG_ID_GET_HONORIFIC, stored_name, carbon_human)

	if(!stored_name[NAME_PART_INDEX]) //Otherwise, we just use whatever the name signal gives us.
		SEND_SIGNAL(speaker, COMSIG_MOVABLE_MESSAGE_GET_NAME_PART, stored_name, visible_name)

	namepart = stored_name[NAME_PART_INDEX] || "[speaker.GetVoice()]"

	//End name span.
	var/endspanpart = "</span>"

	//Message
	var/messagepart
	var/languageicon = ""
	if(message_mods[MODE_CUSTOM_SAY_ERASE_INPUT])
		messagepart = message_mods[MODE_CUSTOM_SAY_EMOTE]
	else
		messagepart = speaker.say_quote(raw_message, spans, message_mods)

		var/datum/language/dialect = GLOB.language_datum_instances[message_language]
		if(istype(dialect) && dialect.display_icon(src))
			languageicon = "[dialect.get_icon()] "

	messagepart = " <span class='message'>[messagepart]</span></span>"

	return "[spanpart1][spanpart2][freqpart][languageicon][compose_track_href(speaker, namepart)][namepart][compose_job(speaker, message_language, raw_message, radio_freq)][endspanpart][messagepart]"

/atom/movable/proc/compose_track_href(atom/movable/speaker, message_langs, raw_message, radio_freq)
	return ""

/atom/movable/proc/compose_job(atom/movable/speaker, message_langs, raw_message, radio_freq)
	return ""

/**
 * Works out and returns which prefix verb the passed message should use.
 *
 * input - The message for which we want the verb.
 * message_mods - A list of message modifiers, i.e. whispering/singing.
 */
/atom/movable/proc/say_mod(input, list/message_mods = list())
	var/ending = copytext_char(input, -1)
	if(copytext_char(input, -2) == "!!")
		return verb_yell
	else if(message_mods[MODE_SING])
		. = verb_sing
	else if(message_mods[WHISPER_MODE])
		. = verb_whisper
	else if(ending == "?")
		return verb_ask
	else if(ending == "!")
		return verb_exclaim
	else
		return get_default_say_verb()

/**
 * Gets the say verb we default to if no special verb is chosen.
 * This is primarily a hook for inheritors,
 * like human_say.dm's tongue-based verb_say changes.
 */
/atom/movable/proc/get_default_say_verb()
	return verb_say

/**
 * This prock is used to generate a message for chat
 * Generates the `says, "<span class='red'>meme</span>"` part of the `Grey Tider says, "meme"`.
 *
 * input - The message to be said
 * spans - A list of spans to attach to the message. Includes the atom's speech span by default
 * message_mods - A list of message modifiers, i.e. whispering/singing
 */
/atom/movable/proc/say_quote(input, list/spans = list(speech_span), list/message_mods = list())
	if(!input)
		input = "..."

	var/say_mod = message_mods[MODE_CUSTOM_SAY_EMOTE] || message_mods[SAY_MOD_VERB] || say_mod(input, message_mods)

	SEND_SIGNAL(src, COMSIG_MOVABLE_SAY_QUOTE, args)

	if(copytext_char(input, -2) == "!!")
		spans |= SPAN_YELL

	/* all inputs should be fully figured out past this point */

	var/processed_input = say_emphasis(input) //This MUST be done first so that we don't get clipped by spans
	processed_input = attach_spans(processed_input, spans)

	var/processed_say_mod = say_emphasis(say_mod)

	return "[processed_say_mod], \"[processed_input]\""

/// Transforms the speech emphasis mods from [/atom/movable/proc/say_emphasis] into the appropriate HTML tags. Includes escaping.
#define ENCODE_HTML_EMPHASIS(input, char, html, varname) \
	var/static/regex/##varname = regex("(?<!\\\\)[char](.+?)(?<!\\\\)[char]", "g");\
	input = varname.Replace_char(input, "<[html]>$1</[html]>&#8203;") //zero-width space to force maptext to respect closing tags.

/// Scans the input sentence for speech emphasis modifiers, notably |italics|, +bold+, and _underline_ -mothblocks
/atom/movable/proc/say_emphasis(input)
	ENCODE_HTML_EMPHASIS(input, "\\|", "i", italics)
	ENCODE_HTML_EMPHASIS(input, "\\+", "b", bold)
	ENCODE_HTML_EMPHASIS(input, "\\_", "u", underline)
	var/static/regex/remove_escape_backlashes = regex("\\\\(\\_|\\+|\\|)", "g") // Removes backslashes used to escape text modification.
	input = remove_escape_backlashes.Replace_char(input, "$1")
	return input

#undef ENCODE_HTML_EMPHASIS

/// Modifies the message by comparing the languages of the speaker with the languages of the hearer. Called on the hearer.
/atom/movable/proc/translate_language(atom/movable/speaker, datum/language/language, raw_message, list/spans, list/message_mods)
	if(!language)
		return "makes a strange sound."

	if(!has_language(language))
		var/datum/language/dialect = GLOB.language_datum_instances[language]
		raw_message = dialect.scramble(raw_message)

	return raw_message

/proc/get_radio_span(freq)
	var/returntext = GLOB.freqtospan["[freq]"]
	if(returntext)
		return returntext
	return "radio"

/proc/get_radio_name(freq)
	var/returntext = GLOB.reverseradiochannels["[freq]"]
	if(returntext)
		return returntext
	return "[copytext_char("[freq]", 1, 4)].[copytext_char("[freq]", 4, 5)]"

/proc/attach_spans(input, list/spans)
	return "[message_spans_start(spans)][input]</span>"

/proc/message_spans_start(list/spans)
	var/output = "<span class='"
	for(var/S in spans)
		output = "[output][S] "
	output = "[output]'>"
	return output

/proc/say_test(text)
	var/ending = copytext_char(text, -1)
	if (ending == "?")
		return "1"
	else if (ending == "!")
		return "2"
	return "0"

/atom/proc/GetVoice()
	return "[src]" //Returns the atom's name, prepended with 'The' if it's not a proper noun

//HACKY VIRTUALSPEAKER STUFF BEYOND THIS POINT
//these exist mostly to deal with the AIs hrefs and job stuff.

/atom/movable/proc/GetJob() //Get a job, you lazy butte

/atom/movable/proc/GetSource()

/atom/movable/proc/GetRadio()

//VIRTUALSPEAKERS
/atom/movable/virtualspeaker
	var/job
	var/atom/movable/source
	var/obj/item/radio/radio

INITIALIZE_IMMEDIATE(/atom/movable/virtualspeaker)
/atom/movable/virtualspeaker/Initialize(mapload, atom/movable/M, _radio)
	. = ..()
	radio = _radio
	source = M
	if(istype(M))
		name = radio.anonymize ? "Unknown" : M.GetVoice()
		verb_say = M.get_default_say_verb()
		verb_ask = M.verb_ask
		verb_exclaim = M.verb_exclaim
		verb_yell = M.verb_yell

	// The mob's job identity
	if(ishuman(M))
		// Humans use their job as seen on the crew manifest. This is so the AI
		// can know their job even if they don't carry an ID.
		var/datum/record/crew/found_record = find_record(name)
		if(found_record)
			job = found_record.rank
		else
			job = "Unknown"
	else if(iscarbon(M))  // Carbon nonhuman
		job = "No ID"
	else if(isAI(M))  // AI
		job = "AI"
	else if(iscyborg(M))  // Cyborg
		var/mob/living/silicon/robot/B = M
		job = "[B.designation] Cyborg"
	else if(ispAI(M))  // Personal AI (pAI)
		job = JOB_PERSONAL_AI
	else if(isobj(M))  // Cold, emotionless machines
		job = "Machine"
	else  // Unidentifiable mob
		job = "Unknown"

/atom/movable/virtualspeaker/GetJob()
	return job

/atom/movable/virtualspeaker/GetSource()
	return source

/atom/movable/virtualspeaker/GetRadio()
	return radio
