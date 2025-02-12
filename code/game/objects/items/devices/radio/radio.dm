#define FREQ_LISTENING (1<<0)

/obj/item/radio
	icon = 'icons/obj/devices/voice.dmi'
	name = "station bounced radio"
	icon_state = "walkietalkie"
	inhand_icon_state = "walkietalkie"
	lefthand_file = 'icons/mob/inhands/items/devices_lefthand.dmi'
	righthand_file = 'icons/mob/inhands/items/devices_righthand.dmi'
	worn_icon_state = "radio"
	desc = "A basic handheld radio that communicates with local telecommunication networks."
	dog_fashion = /datum/dog_fashion/back
	interaction_flags_atom = parent_type::interaction_flags_atom | INTERACT_ATOM_ALLOW_USER_LOCATION | INTERACT_ATOM_IGNORE_MOBILITY

	obj_flags = CONDUCTS_ELECTRICITY
	slot_flags = ITEM_SLOT_BELT
	throw_speed = 3
	throw_range = 7
	w_class = WEIGHT_CLASS_SMALL
	custom_materials = list(/datum/material/iron=SMALL_MATERIAL_AMOUNT * 0.75, /datum/material/glass=SMALL_MATERIAL_AMOUNT * 0.25)

	///if FALSE, broadcasting and listening don't matter and this radio shouldn't do anything
	VAR_PRIVATE/on = TRUE
	///the "default" radio frequency this radio is set to, listens and transmits to this frequency by default. wont work if the channel is encrypted
	VAR_PRIVATE/frequency = FREQ_COMMON

	/// Whether the radio will transmit dialogue it hears nearby into its radio channel.
	VAR_PRIVATE/broadcasting = FALSE
	/// Whether the radio is currently receiving radio messages from its radio frequencies.
	VAR_PRIVATE/listening = TRUE

	//the below three vars are used to track listening and broadcasting should they be forced off for whatever reason but "supposed" to be active
	//eg player sets the radio to listening, but an emp or whatever turns it off, its still supposed to be activated but was forced off,
	//when it wears off it sets listening to should_be_listening

	///used for tracking what broadcasting should be in the absence of things forcing it off, eg its set to broadcast but gets emp'd temporarily
	var/should_be_broadcasting = FALSE
	///used for tracking what listening should be in the absence of things forcing it off, eg its set to listen but gets emp'd temporarily
	var/should_be_listening = TRUE

	/// Both the range around the radio in which mobs can hear what it receives and the range the radio can hear
	var/canhear_range = 3
	/// Tracks the number of EMPs currently stacked.
	var/emped = 0

	/// Whether wires are accessible. Toggleable by screwdrivering.
	var/unscrewed = FALSE
	/// If true, the radio has access to the full spectrum.
	var/freerange = FALSE
	/// If true, the radio transmits and receives on subspace exclusively.
	var/subspace_transmission = FALSE
	/// If true, subspace_transmission can be toggled at will.
	var/subspace_switchable = FALSE
	/// Frequency lock to stop the user from untuning specialist radios.
	var/freqlock = RADIO_FREQENCY_UNLOCKED
	/// If true, broadcasts will be large and BOLD.
	var/use_command = FALSE
	/// If true, use_command can be toggled at will.
	var/command = FALSE
	/// Does it play radio noise?
	var/radio_noise = TRUE

	///makes anyone who is talking through this anonymous.
	var/anonymize = FALSE

	/// Encryption key handling
	var/obj/item/encryptionkey/keyslot
	/// Flags for which "special" radio networks should be accessible
	var/special_channels = NONE
	/// associative list of the encrypted radio channels this radio is currently set to listen/broadcast to, of the form: list(channel name = TRUE or FALSE)
	var/list/channels
	/// associative list of the encrypted radio channels this radio can listen/broadcast to, of the form: list(channel name = channel frequency)
	var/list/secure_radio_connections

	/// overlay when speaker is on
	var/overlay_speaker_idle = "s_idle"
	/// overlay when receiving a message
	var/overlay_speaker_active = "s_active"

	/// overlay when mic is on
	var/overlay_mic_idle = "m_idle"
	/// overlay when speaking a message (is displayed simultaneously with speaker_active)
	var/overlay_mic_active = "m_active"

	/// When set to FALSE, will avoid calling update_icon() in set_broadcasting and co.
	/// Used to save time on updating icon several times over initialization.
	VAR_PRIVATE/perform_update_icon = TRUE

	/// If TRUE, will set the icon in initializations.
	VAR_PRIVATE/should_update_icon = FALSE

	/// A very brief cooldown to prevent regular radio sounds from overlapping.
	COOLDOWN_DECLARE(audio_cooldown)
	/// A very brief cooldown to prevent "important" radio sounds from overlapping.
	COOLDOWN_DECLARE(important_audio_cooldown)

/obj/item/radio/Initialize(mapload)
	set_wires(new /datum/wires/radio(src))
	secure_radio_connections = list()
	. = ..()

	if(ispath(keyslot))
		keyslot = new keyslot()
	for(var/ch_name in channels)
		secure_radio_connections[ch_name] = add_radio(src, GLOB.radiochannels[ch_name])

	perform_update_icon = FALSE
	set_listening(listening)
	set_broadcasting(broadcasting)
	set_frequency(sanitize_frequency(frequency, freerange, (special_channels & RADIO_SPECIAL_SYNDIE)))
	set_on(on)
	perform_update_icon = TRUE

	if (should_update_icon)
		update_appearance(UPDATE_ICON)

	AddElement(/datum/element/empprotection, EMP_PROTECT_WIRES)

	// No subtypes
	if(type != /obj/item/radio)
		return
	AddElement(/datum/element/slapcrafting, string_list(list(/datum/crafting_recipe/improv_explosive)))
	if(prob(check_holidays(APRIL_FOOLS) ? 50 : 0.5)) // Extremely rare chance to replace a normal radio with a toy one, because it's funny
		make_silly()

/obj/item/radio/Destroy()
	remove_radio_all(src) //Just to be sure
	if(istype(keyslot))
		QDEL_NULL(keyslot)
	return ..()

/obj/item/radio/on_saboteur(datum/source, disrupt_duration)
	. = ..()
	if(broadcasting) //no broadcasting but it can still be used to send radio messages.
		set_broadcasting(FALSE)
		return TRUE

/obj/item/radio/proc/set_frequency(new_frequency)
	SEND_SIGNAL(src, COMSIG_RADIO_NEW_FREQUENCY, args)
	remove_radio(src, frequency)
	if(new_frequency)
		frequency = new_frequency

	if(listening && on)
		add_radio(src, new_frequency)

/obj/item/radio/proc/recalculateChannels()
	resetChannels()

	if(keyslot)
		for(var/channel_name in keyslot.channels)
			if(!(channel_name in channels))
				channels[channel_name] = keyslot.channels[channel_name]

		special_channels = keyslot.special_channels

	for(var/channel_name in channels)
		secure_radio_connections[channel_name] = add_radio(src, GLOB.radiochannels[channel_name])

	if(!listening)
		remove_radio_all(src)

// Used for cyborg override
/obj/item/radio/proc/resetChannels()
	channels = list()
	secure_radio_connections = list()
	special_channels = NONE

///goes through all radio channels we should be listening for and readds them to the global list
/obj/item/radio/proc/readd_listening_radio_channels()
	for(var/channel_name in channels)
		add_radio(src, GLOB.radiochannels[channel_name])

	add_radio(src, frequency)

/obj/item/radio/proc/make_syndie() // Turns normal radios into Syndicate radios!
	qdel(keyslot)
	keyslot = new /obj/item/encryptionkey/syndicate()
	special_channels |= RADIO_SPECIAL_SYNDIE
	recalculateChannels()

/obj/item/radio/interact(mob/user)
	if(unscrewed && !isAI(user))
		wires.interact(user)
		add_fingerprint(user)
	else
		..()

//simple getters only because i NEED to enforce complex setter use for these vars for caching purposes but VAR_PROTECTED requires getter usage as well.
//if another decorator is made that doesn't require getters feel free to nuke these and change these vars over to that

///simple getter for the on variable. necessary due to VAR_PROTECTED
/obj/item/radio/proc/is_on()
	return on

///simple getter for the frequency variable. necessary due to VAR_PROTECTED
/obj/item/radio/proc/get_frequency()
	return frequency

///simple getter for the broadcasting variable. necessary due to VAR_PROTECTED
/obj/item/radio/proc/get_broadcasting()
	return broadcasting

///simple getter for the listening variable. necessary due to VAR_PROTECTED
/obj/item/radio/proc/get_listening()
	return listening

//now for setters for the above protected vars

/**
 * setter for the listener var, adds or removes this radio from the global radio list if we are also on
 *
 * * new_listening - the new value we want to set listening to
 * * actual_setting - whether or not the radio is supposed to be listening, sets should_be_listening to the new listening value if true, otherwise just changes listening
 */
/obj/item/radio/proc/set_listening(new_listening, actual_setting = TRUE)

	listening = new_listening
	if(actual_setting)
		should_be_listening = listening

	if(listening && on)
		readd_listening_radio_channels()
	else if(!listening)
		remove_radio_all(src)

	if (perform_update_icon && !isnull(overlay_speaker_idle))
		update_icon()
	else if (!perform_update_icon)
		should_update_icon = TRUE

/**
 * setter for broadcasting that makes us not hearing sensitive if not broadcasting and hearing sensitive if broadcasting
 * hearing sensitive in this case only matters for the purposes of listening for words said in nearby tiles, talking into us directly bypasses hearing
 *
 * * new_broadcasting- the new value we want to set broadcasting to
 * * actual_setting - whether or not the radio is supposed to be broadcasting, sets should_be_broadcasting to the new value if true, otherwise just changes broadcasting
 */
/obj/item/radio/proc/set_broadcasting(new_broadcasting, actual_setting = TRUE)

	broadcasting = new_broadcasting
	if(actual_setting)
		should_be_broadcasting = broadcasting

	if(broadcasting && on) //we don't need hearing sensitivity if we aren't broadcasting, because talk_into doesn't care about hearing
		become_hearing_sensitive(INNATE_TRAIT)
	else if(!broadcasting)
		lose_hearing_sensitivity(INNATE_TRAIT)

	if (perform_update_icon && !isnull(overlay_mic_idle))
		update_icon()
	else if (!perform_update_icon)
		should_update_icon = TRUE

///setter for the on var that sets both broadcasting and listening to off or whatever they were supposed to be
/obj/item/radio/proc/set_on(new_on)

	on = new_on

	if(on)
		set_broadcasting(should_be_broadcasting)//set them to whatever they're supposed to be
		set_listening(should_be_listening)
	else
		set_broadcasting(FALSE, actual_setting = FALSE)//fake set them to off
		set_listening(FALSE, actual_setting = FALSE)

/obj/item/radio/talk_into(atom/movable/talking_movable, message, channel, list/spans, datum/language/language, list/message_mods)
	if(SEND_SIGNAL(talking_movable, COMSIG_MOVABLE_USING_RADIO, src) & COMPONENT_CANNOT_USE_RADIO)
		return NONE
	if(SEND_SIGNAL(src, COMSIG_RADIO_NEW_MESSAGE, talking_movable, message, channel) & COMPONENT_CANNOT_USE_RADIO)
		return NONE

	if(!spans)
		spans = list(talking_movable.speech_span)
	if(!language)
		language = talking_movable.get_selected_language()
	INVOKE_ASYNC(src, PROC_REF(talk_into_impl), talking_movable, message, channel, LAZYLISTDUPLICATE(spans), language, LAZYLISTDUPLICATE(message_mods))
	return ITALICS | REDUCE_RANGE

/**
 * Handles talking into the radio
 *
 * Unlike most speech related procs, spans and message_mods are not guaranteed to be lists
 *
 * * talking_movable - the atom that is talking
 * * message - the message to be spoken
 * * channel - the channel to be spoken on
 * * spans - the spans to be used, lazylist
 * * language - the language to be spoken in. (Should) never be null
 * * message_mods - the message mods to be used, lazylist
 */
/obj/item/radio/proc/talk_into_impl(atom/movable/talking_movable, message, channel, list/spans, datum/language/language, list/message_mods)
	if(!on)
		return // the device has to be on
	if(!talking_movable || !message)
		return
	if(wires.is_cut(WIRE_TX))  // Permacell and otherwise tampered-with radios
		return
	if(!talking_movable.try_speak(message))
		return

	if(use_command)
		spans |= SPAN_COMMAND

	var/radio_message = message
	if(LAZYACCESS(message_mods, WHISPER_MODE))
		// Radios don't pick up whispers very well
		radio_message = stars(radio_message)
		spans |= SPAN_ITALICS

	flick_overlay_view(overlay_mic_active, 5 SECONDS)

	/*
	Roughly speaking, radios attempt to make a subspace transmission (which
	is received, processed, and rebroadcast by the telecomms satellite) and
	if that fails, they send a mundane radio transmission.

	Headsets cannot send/receive mundane transmissions, only subspace.
	Syndicate radios can hear transmissions on all well-known frequencies.
	CentCom radios can hear the CentCom frequency no matter what.
	*/

	// From the channel, determine the frequency and get a reference to it.
	var/freq
	if(channel && channels && channels.len > 0)
		if(channel == MODE_DEPARTMENT)
			channel = channels[1]
		freq = secure_radio_connections[channel]
		if (!channels[channel]) // if the channel is turned off, don't broadcast
			return
	else
		freq = frequency
		channel = null

	// Nearby active jammers prevent the message from transmitting
	if(is_within_radio_jammer_range(src) && !(special_channels & RADIO_SPECIAL_SYNDIE))
		return

	// Determine the identity information which will be attached to the signal.
	var/atom/movable/virtualspeaker/speaker = new(null, talking_movable, src)

	// Construct the signal
	var/datum/signal/subspace/vocal/signal = new(src, freq, speaker, language, radio_message, spans, message_mods)

	// Independent radios, on the CentCom frequency, reach all independent radios
	if (special_channels & RADIO_SPECIAL_CENTCOM && (freq == FREQ_CENTCOM || freq == FREQ_CTF_RED || freq == FREQ_CTF_BLUE || freq == FREQ_CTF_GREEN || freq == FREQ_CTF_YELLOW))
		signal.data["compression"] = 0
		signal.transmission_method = TRANSMISSION_SUPERSPACE
		signal.levels = list(0)
		signal.broadcast()
		return

	if(isliving(talking_movable))
		var/mob/living/talking_living = talking_movable
		var/volume_modifier = (talking_living.client?.prefs.read_preference(/datum/preference/numeric/volume/sound_radio_noise))
		if(radio_noise && talking_living.can_hear() && volume_modifier && signal.frequency != FREQ_COMMON && !LAZYACCESS(message_mods, MODE_SEQUENTIAL) && COOLDOWN_FINISHED(src, audio_cooldown))
			COOLDOWN_START(src, audio_cooldown, 0.5 SECONDS)
			var/sound/radio_noise = sound('sound/items/radio/radio_talk.ogg', volume = volume_modifier)
			radio_noise.frequency = get_rand_frequency_low_range()
			SEND_SOUND(talking_living, radio_noise)

	// All radios make an attempt to use the subspace system first
	signal.send_to_receivers()

	// If the radio is subspace-only, that's all it can do
	if (subspace_transmission)
		return

	// Non-subspace radios will check in a couple of seconds, and if the signal
	// was never received, send a mundane broadcast (no headsets).
	addtimer(CALLBACK(src, PROC_REF(backup_transmission), signal), 2 SECONDS)

/obj/item/radio/proc/backup_transmission(datum/signal/subspace/vocal/signal)
	var/turf/T = get_turf(src)
	if (signal.data["done"] && (T.z in signal.levels))
		return

	// Okay, the signal was never processed, send a mundane broadcast.
	signal.data["compression"] = 0
	signal.transmission_method = TRANSMISSION_RADIO
	signal.levels = SSmapping.get_connected_levels(T)
	signal.broadcast()

/obj/item/radio/Hear(message, atom/movable/speaker, message_language, raw_message, radio_freq, list/spans, list/message_mods = list(), message_range)
	. = ..()
	if(radio_freq || !broadcasting || get_dist(src, speaker) > canhear_range || message_mods[MODE_RELAY])
		return
	var/list/filtered_mods = list()

	if (message_mods[MODE_SING])
		filtered_mods[MODE_SING] = message_mods[MODE_SING]
	if (message_mods[WHISPER_MODE])
		filtered_mods[WHISPER_MODE] = message_mods[WHISPER_MODE]
	if (message_mods[SAY_MOD_VERB])
		filtered_mods[SAY_MOD_VERB] = message_mods[SAY_MOD_VERB]
	if (message_mods[MODE_CUSTOM_SAY_EMOTE])
		filtered_mods[MODE_CUSTOM_SAY_EMOTE] = message_mods[MODE_CUSTOM_SAY_EMOTE]
		filtered_mods[MODE_CUSTOM_SAY_ERASE_INPUT] = message_mods[MODE_CUSTOM_SAY_ERASE_INPUT]
	if(message_mods[RADIO_EXTENSION] == MODE_L_HAND || message_mods[RADIO_EXTENSION] == MODE_R_HAND)
		// try to avoid being heard double
		if (loc == speaker && ismob(speaker))
			var/mob/mob_speaker = speaker
			var/idx = mob_speaker.get_held_index_of_item(src)
			// left hands are odd slots
			if (idx && (idx % 2) == (message_mods[RADIO_EXTENSION] == MODE_L_HAND))
				return
	talk_into(speaker, raw_message, spans=spans, language=message_language, message_mods=filtered_mods)

/// Checks if this radio can receive on the given frequency.
/obj/item/radio/proc/can_receive(input_frequency, list/levels)
	// deny checks
	if (levels != RADIO_NO_Z_LEVEL_RESTRICTION)
		var/turf/position = get_turf(src)
		if(!position || !(position.z in levels))
			return FALSE

	if (input_frequency == FREQ_SYNDICATE && !(special_channels & RADIO_SPECIAL_SYNDIE))
		return FALSE

	// allow checks: are we listening on that frequency?
	if (input_frequency == frequency)
		return TRUE
	for(var/ch_name in channels)
		if(channels[ch_name] & FREQ_LISTENING)
			if(GLOB.radiochannels[ch_name] == text2num(input_frequency) || special_channels & RADIO_SPECIAL_SYNDIE)
				return TRUE
	return FALSE

/obj/item/radio/proc/on_receive_message(list/data)
	SEND_SIGNAL(src, COMSIG_RADIO_RECEIVE_MESSAGE, data)
	flick_overlay_view(overlay_speaker_active, 5 SECONDS)

	if(!isliving(loc))
		return

	var/mob/living/holder = loc
	var/volume_modifier = (holder.client?.prefs.read_preference(/datum/preference/numeric/volume/sound_radio_noise))
	if(!radio_noise || HAS_TRAIT(holder, TRAIT_DEAF) || !holder.client?.prefs.read_preference(/datum/preference/numeric/volume/sound_radio_noise))
		return
	var/list/spans = data["spans"]
	if(COOLDOWN_FINISHED(src, audio_cooldown))
		COOLDOWN_START(src, audio_cooldown, 0.5 SECONDS)
		var/sound/radio_receive = sound('sound/items/radio/radio_receive.ogg', volume = volume_modifier)
		radio_receive.frequency = get_rand_frequency_low_range()
		SEND_SOUND(holder, radio_receive)
	if((SPAN_COMMAND in spans) && COOLDOWN_FINISHED(src, important_audio_cooldown))
		COOLDOWN_START(src, important_audio_cooldown, 0.5 SECONDS)
		var/sound/radio_important = sound('sound/items/radio/radio_important.ogg', volume = volume_modifier)
		radio_important.frequency = get_rand_frequency_low_range()
		SEND_SOUND(holder, radio_important)

/obj/item/radio/ui_state(mob/user)
	return GLOB.inventory_state

/obj/item/radio/ui_interact(mob/user, datum/tgui/ui, datum/ui_state/state)
	ui = SStgui.try_update_ui(user, src, ui)
	if(!ui)
		ui = new(user, src, "Radio", name)
		if(state)
			ui.set_state(state)
		ui.open()

/obj/item/radio/ui_data(mob/user)
	var/list/data = list()

	data["broadcasting"] = broadcasting
	data["listening"] = listening
	data["frequency"] = frequency
	data["minFrequency"] = freerange ? MIN_FREE_FREQ : MIN_FREQ
	data["maxFrequency"] = freerange ? MAX_FREE_FREQ : MAX_FREQ
	data["freqlock"] = freqlock != RADIO_FREQENCY_UNLOCKED
	data["channels"] = list()
	for(var/channel in channels)
		data["channels"][channel] = channels[channel] & FREQ_LISTENING
	data["command"] = command
	data["useCommand"] = use_command
	data["subspace"] = subspace_transmission
	data["subspaceSwitchable"] = subspace_switchable
	data["headset"] = FALSE

	return data

/obj/item/radio/ui_act(action, params, datum/tgui/ui)
	. = ..()
	if(.)
		return
	switch(action)
		if("frequency")
			if(freqlock != RADIO_FREQENCY_UNLOCKED)
				return
			var/tune = params["tune"]
			var/adjust = text2num(params["adjust"])
			if(adjust)
				tune = frequency + adjust * 10
				. = TRUE
			else if(text2num(tune) != null)
				tune = tune * 10
				. = TRUE
			if(.)
				set_frequency(sanitize_frequency(tune, freerange, (special_channels & RADIO_SPECIAL_SYNDIE)))
		if("listen")
			set_listening(!listening)
			. = TRUE
		if("broadcast")
			set_broadcasting(!broadcasting)
			. = TRUE
		if("channel")
			var/channel = params["channel"]
			if(!(channel in channels))
				return
			if(channels[channel] & FREQ_LISTENING)
				channels[channel] &= ~FREQ_LISTENING
			else
				channels[channel] |= FREQ_LISTENING
			. = TRUE
		if("command")
			use_command = !use_command
			. = TRUE
		if("subspace")
			if(subspace_switchable)
				subspace_transmission = !subspace_transmission
				if(!subspace_transmission)
					channels = list()
				else
					recalculateChannels()
				. = TRUE

/obj/item/radio/examine(mob/user)
	. = ..()
	if (frequency && in_range(src, user))
		. += span_notice("It is set to broadcast over the [span_radio("[frequency/10]")] frequency.")
	if (unscrewed)
		. += span_notice("It can be attached and modified.")
	else
		. += span_notice("It cannot be modified or attached.")

/obj/item/radio/update_overlays()
	. = ..()
	if(unscrewed)
		return
	if(broadcasting && overlay_mic_idle)
		. += overlay_mic_idle
	if(listening && overlay_speaker_idle)
		. += overlay_speaker_idle

/obj/item/radio/item_interaction(mob/living/user, obj/item/tool, list/modifiers)
	if(user.combat_mode && tool.tool_behaviour == TOOL_SCREWDRIVER)
		return screwdriver_act(user, tool)
	return ..()

/obj/item/radio/screwdriver_act(mob/living/user, obj/item/tool)
	add_fingerprint(user)
	unscrewed = !unscrewed
	if(unscrewed)
		to_chat(user, span_notice("The radio can now be attached and modified!"))
	else
		to_chat(user, span_notice("The radio can no longer be modified or attached!"))

/obj/item/radio/emp_act(severity)
	. = ..()
	if (. & EMP_PROTECT_SELF)
		return
	emped++ //There's been an EMP; better count it
	var/curremp = emped //Remember which EMP this was
	if (listening && ismob(loc)) // if the radio is turned on and on someone's person they notice
		to_chat(loc, span_warning("\The [src] overloads."))
	for (var/ch_name in channels)
		channels[ch_name] = 0
	set_on(FALSE)
	addtimer(CALLBACK(src, PROC_REF(end_emp_effect), curremp), 20 SECONDS)

/obj/item/radio/suicide_act(mob/living/user)
	user.visible_message(span_suicide("[user] starts bouncing [src] off [user.p_their()] head! It looks like [user.p_theyre()] trying to commit suicide!"))
	return BRUTELOSS

/obj/item/radio/proc/end_emp_effect(curremp)
	if(emped != curremp) //Don't fix it if it's been EMP'd again
		return FALSE
	emped = FALSE
	set_on(TRUE)
	return TRUE

/obj/item/radio/proc/make_silly()
	name = "\improper Little-Crew: Assistant's First Radio"
	icon_state = "walkieian"
	desc = "A Little-Crew branded toy radio in the shape of a lovable pet. After Little-Crew HQ was hit with a Donksoft Nuke, these have become collector's items!"
	overlay_speaker_idle = null
	overlay_speaker_active = null
	overlay_mic_idle = null
	overlay_mic_active = null

///////////////////////////////
//////////Borg Radios//////////
///////////////////////////////
//Giving borgs their own radio to have some more room to work with -Sieve

/obj/item/radio/borg
	name = "cyborg radio"
	subspace_transmission = TRUE
	subspace_switchable = TRUE
	dog_fashion = null
	canhear_range = 0

/obj/item/radio/borg/resetChannels()
	. = ..()

	var/mob/living/silicon/robot/R = loc
	if(istype(R))
		for(var/ch_name in R.model.radio_channels)
			channels[ch_name] = TRUE

/obj/item/radio/borg/syndicate
	special_channels = RADIO_SPECIAL_SYNDIE
	keyslot = /obj/item/encryptionkey/syndicate

/obj/item/radio/borg/syndicate/Initialize(mapload)
	. = ..()
	set_frequency(FREQ_SYNDICATE)

/obj/item/radio/borg/screwdriver_act(mob/living/user, obj/item/tool)
	if(!keyslot)
		to_chat(user, span_warning("This radio doesn't have any encryption keys!"))
		return

	for(var/ch_name in channels)
		SSradio.remove_object(src, GLOB.radiochannels[ch_name])
		secure_radio_connections[ch_name] = null

	if(keyslot)
		var/turf/user_turf = get_turf(user)
		if(user_turf)
			keyslot.forceMove(user_turf)
			keyslot = null

	recalculateChannels()
	to_chat(user, span_notice("You pop out the encryption key in the radio."))
	return ..()

/obj/item/radio/borg/attackby(obj/item/attacking_item, mob/user, params)

	if(istype(attacking_item, /obj/item/encryptionkey))
		if(keyslot)
			to_chat(user, span_warning("The radio can't hold another key!"))
			return

		if(!keyslot)
			if(!user.transferItemToLoc(attacking_item, src))
				return
			keyslot = attacking_item

		recalculateChannels()


/obj/item/radio/off // Station bounced radios, their only difference is spawning with the speakers off, this was made to help the lag.
	dog_fashion = /datum/dog_fashion/back

/obj/item/radio/off/Initialize(mapload)
	. = ..()
	set_listening(FALSE)

// RADIOS USED BY BROADCASTING
/obj/item/radio/entertainment
	desc = "You should not hold this."
	canhear_range = 7
	freerange = TRUE
	freqlock = RADIO_FREQENCY_LOCKED
	radio_noise = FALSE

/obj/item/radio/entertainment/Initialize(mapload)
	. = ..()
	set_frequency(FREQ_ENTERTAINMENT)

/obj/item/radio/entertainment/speakers // Used inside of the entertainment monitors, not to be used as a actual item
	should_be_listening = TRUE
	should_be_broadcasting = FALSE

/obj/item/radio/entertainment/speakers/proc/toggle_mute()
	should_be_listening = !should_be_listening

/obj/item/radio/entertainment/speakers/Initialize(mapload)
	. = ..()
	set_broadcasting(FALSE)
	set_listening(TRUE)
	wires?.cut(WIRE_TX)

/obj/item/radio/entertainment/speakers/on_receive_message(list/data)
	playsound(source = src, soundin = SFX_MUFFLED_SPEECH, vol = 60, extrarange = -4, vary = TRUE, ignore_walls = FALSE)

	return ..()

/obj/item/radio/entertainment/speakers/physical // Can be used as a physical item
	name = "entertainment radio"
	desc = "A portable one-way radio permanently tuned into entertainment frequency."
	icon_state = "radio"
	inhand_icon_state = "radio"
	worn_icon_state = "radio"
	overlay_speaker_idle = "radio_s_idle"
	overlay_speaker_active = "radio_s_active"
	overlay_mic_idle = "radio_m_idle"
	overlay_mic_active = "radio_m_active"

/obj/item/radio/entertainment/microphone // Used inside of a broadcast camera, not to be used as a actual item
	should_be_listening = FALSE
	should_be_broadcasting = TRUE

/obj/item/radio/entertainment/microphone/Initialize(mapload)
	. = ..()
	set_broadcasting(TRUE)
	set_listening(FALSE)
	wires?.cut(WIRE_RX)

/obj/item/radio/entertainment/microphone/physical // Can be used as a physical item
	name = "microphone"
	desc = "No comments."
	icon = 'icons/obj/service/broadcast.dmi'
	icon_state = "microphone"
	inhand_icon_state = "microphone"
	canhear_range = 3

// In case you want to map it in/spawn it for some reason
/obj/item/radio/toy/Initialize(mapload)
	. = ..()
	make_silly()

#undef FREQ_LISTENING
