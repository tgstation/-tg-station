/// Used to generate an asset key for a temporary image unique to this user.
#define TEMP_IMAGE_PATH(ref) ("ntos_messenger[ref]_temp_image.png")
/// Purpose is evident by the name, hopefully.
#define MAX_PDA_MESSAGE_LEN 1024
/// Format of message timestamps.
#define PDA_MESSAGE_TIMESTAMP_FORMAT "hh:mm"

/datum/computer_file/program/messenger
	filename = "nt_messenger"
	filedesc = "Direct Messenger"
	downloader_category = PROGRAM_CATEGORY_DEVICE
	program_open_overlay = "text"
	extended_desc = "This program allows old-school communication with other modular devices."
	size = 0
	undeletable = TRUE // It comes by default in tablets, can't be downloaded, takes no space and should obviously not be able to be deleted.
	power_cell_use = NONE
	program_flags = PROGRAM_HEADER | PROGRAM_RUNS_WITHOUT_POWER | PROGRAM_CIRCUITS_RUN_WHEN_CLOSED
	can_run_on_flags = PROGRAM_PDA
	ui_header = "ntnrc_idle.gif"
	tgui_id = "NtosMessenger"
	program_icon = "comment-alt"
	alert_able = TRUE
	circuit_comp_type = /obj/item/circuit_component/mod_program/messenger

	/// Whether the user is invisible to the message list.
	var/invisible = FALSE
	/// great wisdom from PDA.dm - "no spamming" (prevents people from spamming the same message over and over)
	COOLDOWN_DECLARE(last_text)
	/// even more wisdom from PDA.dm - "no everyone spamming" (prevents people from spamming the same message over and over)
	COOLDOWN_DECLARE(last_text_everyone)
	/// Whether or not we're in a mime PDA.
	var/mime_mode = FALSE
	/// Whether this app can send messages to all.
	var/spam_mode = FALSE

	/// An asssociative list of chats we have started, format: chatref -> pda_chat.
	var/list/saved_chats = list()
	/// Whose chatlogs we currently have open. If we are in the contacts list, this is null.
	var/viewing_messages_of = null

	/// The current ringtone (displayed in the chat when a message is received).
	var/ringtone = MESSENGER_RINGTONE_DEFAULT
	/// Whether or not we're sorting by job.
	var/sort_by_job = TRUE
	/// Whether or not we're sending and receiving messages.
	var/sending_and_receiving = TRUE
	/// Selected photo for sending purposes.
	var/selected_image = null
	/// Whether or not we're sending (or trying to send) a virus.
	var/sending_virus = FALSE

/datum/computer_file/program/messenger/on_install()
	. = ..()
	RegisterSignal(computer, COMSIG_MODULAR_COMPUTER_FILE_STORE, PROC_REF(check_new_photo))
	RegisterSignal(computer, COMSIG_MODULAR_COMPUTER_FILE_DELETE, PROC_REF(check_photo_removed))
	RegisterSignal(computer, COMSIG_MODULAR_PDA_IMPRINT_UPDATED, PROC_REF(on_imprint_added))
	RegisterSignal(computer, COMSIG_MODULAR_PDA_IMPRINT_RESET, PROC_REF(on_imprint_reset))

/datum/computer_file/program/messenger/proc/check_new_photo(sender, datum/computer_file/picture/storing_picture)
	SIGNAL_HANDLER
	if(!istype(storing_picture))
		return
	update_pictures_for_all()

/datum/computer_file/program/messenger/proc/check_photo_removed(sender, datum/computer_file/picture/photo_removed)
	SIGNAL_HANDLER
	if(istype(photo_removed) && selected_image == photo_removed.picture_name)
		selected_image = null

/datum/computer_file/program/messenger/proc/on_imprint_added(sender)
	SIGNAL_HANDLER
	add_messenger(src)

/datum/computer_file/program/messenger/proc/on_imprint_reset(sender)
	SIGNAL_HANDLER
	remove_messenger(src)
	saved_chats = list()
	selected_image = null
	viewing_messages_of = null

/datum/computer_file/program/messenger/Destroy(force)
	if(!QDELETED(computer))
		stack_trace("Attempted to qdel messenger of [computer] without qdeling computer, this will cause problems later")
	remove_messenger(src)
	return ..()

/// Gets the list of available messengers
/datum/computer_file/program/messenger/proc/get_messengers()
	var/list/dictionary = list()

	var/list/messengers_sorted = sort_by_job ? get_messengers_sorted_by_job() : get_messengers_sorted_by_name()

	for(var/messenger_ref in messengers_sorted)
		var/datum/computer_file/program/messenger/messenger = messengers_sorted[messenger_ref]
		if(!istype(messenger) || !istype(messenger.computer))
			continue
		if(messenger == src || messenger.invisible)
			continue

		var/list/data = list()
		data["name"] = messenger.computer.saved_identification
		data["job"] = messenger.computer.saved_job
		data["ref"] = REF(messenger)

		dictionary[data["ref"]] = data

	return dictionary

/// Checks if the person can send an everyone message
/datum/computer_file/program/messenger/proc/can_send_everyone_message()
	return COOLDOWN_FINISHED(src, last_text) && COOLDOWN_FINISHED(src, last_text_everyone)

/// Gets all currently relevant photo asset keys
/datum/computer_file/program/messenger/proc/get_picture_assets()
	var/list/data = list()

	for(var/datum/computer_file/picture/photo in computer.stored_files)
		data |= photo.picture_name

	if(viewing_messages_of in saved_chats)
		var/datum/pda_chat/chat = saved_chats[viewing_messages_of]
		for(var/datum/pda_message/message as anything in chat.messages)
			if(isnull(message.photo_name))
				continue
			data |= message.photo_name

	if(!isnull(selected_image))
		data |= selected_image

	return data

/// Sends new datum/picture assets to everyone
/datum/computer_file/program/messenger/proc/update_pictures_for_all()
	var/list/data = get_picture_assets()

	if(isnull(computer.open_uis))
		return

	for(var/datum/tgui/window as anything in computer.open_uis)
		SSassets.transport.send_assets(window.user, data)

/// Set the ringtone if possible. Also handles encoding.
/datum/computer_file/program/messenger/proc/set_ringtone(new_ringtone, mob/user)
	new_ringtone = trim(html_encode(new_ringtone), MESSENGER_RINGTONE_MAX_LENGTH)
	if(!new_ringtone)
		return FALSE

	if(SEND_SIGNAL(computer, COMSIG_TABLET_CHANGE_ID, user, new_ringtone) & COMPONENT_STOP_RINGTONE_CHANGE)
		return FALSE

	ringtone = new_ringtone
	return TRUE

/datum/computer_file/program/messenger/ui_interact(mob/user, datum/tgui/ui)
	var/list/data = get_picture_assets()
	SSassets.transport.send_assets(user, data)

/datum/computer_file/program/messenger/ui_state(mob/user)
	if(issilicon(user))
		return GLOB.deep_inventory_state
	return GLOB.default_state

/datum/computer_file/program/messenger/ui_act(action, list/params, datum/tgui/ui, datum/ui_state/state)
	. = ..()
	switch(action)
		if("PDA_ringSet")
			var/mob/living/user = usr
			var/new_ringtone = tgui_input_text(user, "Enter a new ringtone", "Ringtone", ringtone, max_length = MAX_MESSAGE_LEN, encode = FALSE)
			if(!computer.can_interact(user))
				computer.balloon_alert(user, "can't reach!")
				return FALSE
			return set_ringtone(new_ringtone, user)

		if("PDA_toggleAlerts")
			alert_silenced = !alert_silenced
			return TRUE

		if("PDA_toggleSendingAndReceiving")
			sending_and_receiving = !sending_and_receiving
			return TRUE

		if("PDA_viewMessages")
			if(viewing_messages_of in saved_chats)
				var/datum/pda_chat/chat = saved_chats[viewing_messages_of]
				chat.unread_messages = 0

			viewing_messages_of = params["ref"]

			if (viewing_messages_of in saved_chats)
				var/datum/pda_chat/chat = saved_chats[viewing_messages_of]
				chat.visible_in_recents = TRUE

			selected_image = null
			return TRUE

		if("PDA_closeMessages")
			var/target = params["ref"]

			if(!(target in saved_chats))
				return FALSE

			var/datum/pda_chat/chat = saved_chats[target]
			chat.visible_in_recents = FALSE
			if(viewing_messages_of == target)
				viewing_messages_of = null
			return TRUE

		if("PDA_clearMessages")
			var/chat_ref = params["ref"]

			if(chat_ref in saved_chats)
				saved_chats.Remove(chat_ref)
			else if(isnull(chat_ref))
				saved_chats = list()

			viewing_messages_of = null
			return TRUE

		if("PDA_changeSortStyle")
			sort_by_job = !sort_by_job
			return TRUE

		if("PDA_sendEveryone")
			if(!sending_and_receiving)
				to_chat(usr, span_notice("ERROR: This device has sending disabled."))
				return FALSE

			if(!spam_mode)
				to_chat(usr, span_notice("ERROR: This device does not have mass-messaging perms."))
				return FALSE

			if(!can_send_everyone_message())
				return FALSE

			return send_message_to_all(usr, params["message"])

		if("PDA_saveMessageDraft")
			var/target_chat_ref = params["ref"]
			var/message_draft = params["message"]

			if(!(target_chat_ref in saved_chats))
				return FALSE

			var/datum/pda_chat/chat = saved_chats[target_chat_ref]

			chat.message_draft = message_draft

			return TRUE

		if("PDA_clearUnreads")
			var/target_chat_ref = params["ref"]

			if(!(target_chat_ref in saved_chats))
				return FALSE

			var/datum/pda_chat/chat = saved_chats[target_chat_ref]
			chat.unread_messages = 0

			return TRUE

		if("PDA_sendMessage")
			if(!sending_and_receiving)
				to_chat(usr, span_notice("ERROR: This device has sending disabled."))
				return FALSE

			// target ref, can either be a chat in saved_chats
			// or a messenger ref in GLOB.pda_messengers
			var/target_ref = params["ref"]

			var/target = null

			if(target_ref in saved_chats)
				target = saved_chats[target_ref]
			else if(target_ref in GLOB.pda_messengers)
				target = GLOB.pda_messengers[target_ref]
			else
				return FALSE

			if(sending_virus)
				var/obj/item/computer_disk/virus/disk = computer.inserted_disk
				if(!istype(disk))
					return FALSE

				var/datum/computer_file/program/messenger/target_messenger = null

				if(istype(target, /datum/pda_chat))
					var/datum/pda_chat/target_chat = target
					target_messenger = target_chat.recipient?.resolve()
					if(!istype(target_messenger))
						to_chat(usr, span_notice("ERROR: Recipient no longer exists."))
						return FALSE
				else if(istype(target, /datum/computer_file/program/messenger))
					target_messenger = target

				return disk.send_virus(computer, target_messenger.computer, usr, params["message"])

			return send_message(usr, params["message"], list(target))

		if("PDA_clearPhoto")
			selected_image = null
			return TRUE

		if("PDA_toggleVirus")
			sending_virus = !sending_virus
			return TRUE

		if("PDA_selectPhoto")
			if(issilicon(usr))
				return FALSE

			var/photo_uid = text2num(params["uid"])

			var/datum/computer_file/picture/selected_photo = computer.find_file_by_uid(photo_uid)

			if(!istype(selected_photo))
				return FALSE

			selected_image = selected_photo.picture_name
			return TRUE

		if("PDA_siliconSelectPhoto")
			if(!issilicon(usr))
				return FALSE
			var/mob/living/silicon/user = usr
			if(!user.aicamera)
				return FALSE
			var/datum/picture/selected_photo = user.aicamera.selectpicture(user)
			if(!selected_photo)
				return FALSE
			SSassets.transport.register_asset(TEMP_IMAGE_PATH(REF(src)), selected_photo.picture_image)
			selected_image = TEMP_IMAGE_PATH(REF(src))
			update_pictures_for_all()
			return TRUE

/datum/computer_file/program/messenger/ui_static_data(mob/user)
	var/list/static_data = list()

	static_data["can_spam"] = spam_mode
	static_data["is_silicon"] = issilicon(user)
	static_data["remote_silicon"] = (isAI(user) || iscyborg(user)) && !istype(computer, /obj/item/modular_computer/pda/silicon) //Silicon is accessing a PDA on the ground, not their internal one. Avoiding pAIs in this check.
	static_data["alert_able"] = alert_able

	return static_data

/datum/computer_file/program/messenger/ui_data(mob/user)
	var/list/data = list()

	var/list/chats_data = list()
	for(var/chat_ref in saved_chats)
		var/datum/pda_chat/chat = saved_chats[chat_ref]
		var/list/chat_data = chat.get_ui_data(user)
		chats_data[chat_ref] = chat_data

	var/list/messengers = get_messengers()

	data["owner"] = ((REF(src) in GLOB.pda_messengers) ? list(
			"name" = computer.saved_identification,
			"job" = computer.saved_job,
			"ref" = REF(src)
		) : null)
	data["saved_chats"] = chats_data
	data["messengers"] = messengers
	data["sort_by_job"] = sort_by_job
	data["alert_silenced"] = alert_silenced
	data["sending_and_receiving"] = sending_and_receiving
	data["open_chat"] = viewing_messages_of

	// silicons handle selecting photos a bit differently for now
	if(!issilicon(user))
		var/list/stored_photos = list()
		for(var/datum/computer_file/picture/photo_file in computer.stored_files)
			stored_photos += list(list(
				"uid" = photo_file.uid,
				"path" = SSassets.transport.get_asset_url(photo_file.picture_name)
			))
		data["stored_photos"] = stored_photos
	data["selected_photo_path"] = !isnull(selected_image) ? SSassets.transport.get_asset_url(selected_image) : null
	data["on_spam_cooldown"] = !can_send_everyone_message()

	var/obj/item/computer_disk/virus/disk = computer.inserted_disk
	if(istype(disk))
		data["virus_attach"] = TRUE
		data["sending_virus"] = sending_virus
	return data

/datum/computer_file/program/messenger/ui_assets(mob/user)
	. = ..()
	. += get_asset_datum(/datum/asset/spritesheet_batched/chat)

//////////////////////
// MESSAGE HANDLING //
//////////////////////

/// Brings up the quick reply prompt to send a message.
/datum/computer_file/program/messenger/proc/quick_reply_prompt(mob/living/user, datum/pda_chat/chat)
	if(!istype(chat))
		return
	var/datum/computer_file/program/messenger/target = chat.recipient?.resolve()
	if(!istype(target) || !istype(target.computer))
		to_chat(user, span_notice("ERROR: Recipient no longer exists."))
		chat.recipient = null
		chat.can_reply = FALSE
		return
	var/target_name = target.computer.saved_identification
	var/input_message = tgui_input_text(user, "Enter [mime_mode ? "emojis":"a message"]", "NT Messaging[target_name ? " ([target_name])" : ""]", max_length = MAX_MESSAGE_LEN, encode = FALSE)
	send_message(user, input_message, list(chat))

/// Helper proc that sends a message to everyone
/datum/computer_file/program/messenger/proc/send_message_to_all(mob/living/user, message)
	var/list/datum/pda_chat/chats = list()
	var/list/messenger_targets = list()

	for(var/mc in get_messengers())
		messenger_targets += mc

	for(var/chatref in saved_chats)
		var/datum/pda_chat/chat = saved_chats[chatref]
		if(!(chat.recipient?.reference in messenger_targets)) // if its in messenger_targets, it's valid
			continue
		messenger_targets -= chat.recipient.reference
		chats += chat

	for(var/missing_messenger in messenger_targets)
		var/datum/pda_chat/new_chat = create_chat(missing_messenger)
		chats += new_chat

	if(send_message(user, message, chats, everyone = TRUE))
		COOLDOWN_START(src, last_text_everyone, 2 MINUTES)

/// Creates a chat and adds it to saved_chats. Supports fake users. Returns the newly created chat.
/datum/computer_file/program/messenger/proc/create_chat(recipient_ref, name, job)
	var/datum/computer_file/program/messenger/recipient = null

	if(isnull(name) && isnull(job))
		if(!(recipient_ref in GLOB.pda_messengers))
			CRASH("tried to create a chat with a messenger that isn't registered")
		recipient = GLOB.pda_messengers[recipient_ref]

	var/datum/pda_chat/new_chat = new(recipient)

	// this is a chat with a "fake user" (automated or forged message)
	if(!istype(recipient))
		new_chat.cached_name = name
		new_chat.cached_job = job
		new_chat.can_reply = FALSE

	saved_chats[REF(new_chat)] = new_chat

	return new_chat

/// Gets the chat by the recipient, either by their name or messenger ref
/datum/computer_file/program/messenger/proc/find_chat_by_recipient(recipient, fake_user = FALSE)
	for(var/chat_ref in saved_chats)
		var/datum/pda_chat/chat = saved_chats[chat_ref]
		if(fake_user && chat.cached_name == recipient)
			return chat
		else if(chat.recipient?.reference == recipient)
			return chat
	return null

/// Returns a message input, sanitized and checked against the filter
/datum/computer_file/program/messenger/proc/sanitize_pda_message(message, mob/sender)
	message = sanitize(trim(message, MAX_PDA_MESSAGE_LEN))

	if(mime_mode)
		message = emoji_sanitize(message)

	// check message against filter
	if(sender && !check_pda_message_against_filter(message, sender))
		return null

	return emoji_parse(message)

/// Sends a message to targets via PDA. When sending to everyone, set `everyone` to true so the message is formatted accordingly
/datum/computer_file/program/messenger/proc/send_message(atom/source, message, list/targets, everyone = FALSE)
	var/mob/living/sender
	if(isliving(source))
		sender = source
	message = sanitize_pda_message(message, sender)
	if(!message)
		return FALSE


	// upgrade the image asset to a permanent key
	var/photo_asset_key = selected_image
	if(photo_asset_key == TEMP_IMAGE_PATH(REF(src)))
		var/datum/asset_cache_item/img_asset = SSassets.cache[photo_asset_key]
		photo_asset_key = SSmodular_computers.get_next_picture_name()
		SSassets.transport.register_asset(photo_asset_key, img_asset.resource, img_asset.hash)

	// our sender targets
	var/list/datum/computer_file/program/messenger/target_messengers = list()
	var/list/datum/pda_chat/target_chats = list()

	var/should_alert = length(targets) == 1 && sender

	// filter out invalid targets
	for(var/target in targets)
		var/datum/pda_chat/target_chat = null
		var/datum/computer_file/program/messenger/target_messenger = null

		if(istype(target, /datum/pda_chat))
			target_chat = target

			if(!target_chat.can_reply)
				if(should_alert)
					to_chat(sender, span_notice("ERROR: Recipient has receiving disabled."))
				continue

			target_messenger = target_chat.recipient?.resolve()

			if(!istype(target_messenger))
				if(should_alert)
					to_chat(sender, span_notice("ERROR: Recipient no longer exists."))
				target_chat.can_reply = FALSE
				target_chat.recipient = null
				continue

			if(!target_messenger.sending_and_receiving)
				if(should_alert)
					to_chat(sender, span_notice("ERROR: Recipient has receiving disabled."))
				continue

		else if(istype(target, /datum/computer_file/program/messenger))
			target_messenger = target

			if(!target_messenger.sending_and_receiving)
				if(should_alert)
					to_chat(sender, span_notice("ERROR: Recipient has receiving disabled."))
				continue

			target_chat = find_chat_by_recipient(REF(target))

			if(!istype(target_chat))
				target_chat = create_chat(REF(target))

		else
			stack_trace("invalid target [target]")
			continue

		target_chats += target_chat
		target_messengers += target_messenger

	if(!send_message_signal(source, message, target_messengers, photo_asset_key, everyone))
		return FALSE

	// Log it in our logs
	var/datum/pda_message/message_datum = new(message, TRUE, station_time_timestamp(PDA_MESSAGE_TIMESTAMP_FORMAT), photo_asset_key, everyone)
	for(var/datum/pda_chat/target_chat as anything in target_chats)
		target_chat.add_message(message_datum, show_in_recents = !everyone)
		target_chat.unread_messages = 0

	// send new pictures to everyone
	if(!isnull(photo_asset_key))
		update_pictures_for_all()

	// switch our chat screen after sending a message, but do it only if it's not to everyone
	if(!everyone)
		viewing_messages_of = REF(target_chats[1])

	return TRUE

/// Sends a rigged message that explodes when the recipient tries to reply or look at it.
/datum/computer_file/program/messenger/proc/send_rigged_message(mob/sender, message, list/datum/computer_file/program/messenger/targets, fake_name, fake_job, attach_fake_photo)
	message = sanitize_pda_message(message, sender)

	if(!message)
		return FALSE

	var/fake_photo = attach_fake_photo ? ">:3c" : null

	return send_message_signal(sender, message, targets, fake_photo, FALSE, TRUE, fake_name, fake_job)

/datum/computer_file/program/messenger/proc/send_message_signal(atom/source, message, list/datum/computer_file/program/messenger/targets, photo_path = null, everyone = FALSE, rigged = FALSE, fake_name = null, fake_job = null)
	var/mob/sender
	if(ismob(source))
		sender = source
		if(!sender.can_perform_action(computer, ALLOW_RESTING | ALLOW_PAI))
			return FALSE

	if(!COOLDOWN_FINISHED(src, last_text))
		return FALSE

	if(!length(targets))
		return FALSE

	// check for jammers
	if(is_within_radio_jammer_range(computer) && !rigged)
		// different message so people know it's a radio jammer
		if(sender)
			to_chat(sender, span_notice("ERROR: Network unavailable, please try again later."))
		if(alert_able && !alert_silenced)
			playsound(computer, 'sound/machines/terminal/terminal_error.ogg', 15, TRUE)
		return FALSE

	// used for logging
	var/list/stringified_targets = list()

	for(var/datum/computer_file/program/messenger/messenger as anything in targets)
		stringified_targets += get_messenger_name(messenger)

	var/datum/signal/subspace/messaging/tablet_message/signal = new(computer, list(
		"ref" = REF(src),
		"message" = message,
		"targets" = targets,
		"rigged" = rigged,
		"everyone" = everyone,
		"photo" = photo_path,
		"automated" = FALSE,
	))
	if(rigged) //Will skip the message server and go straight to the hub so it can't be cheesed by disabling the message server machine
		signal.data["fakename"] = fake_name
		signal.data["fakejob"] = fake_job
		signal.server_type = /obj/machinery/telecomms/hub
		signal.data["reject"] = FALSE // Do not refuse the message

	signal.send_to_receivers()

	// If it didn't reach, note that fact
	if (!signal.data["done"])
		if(sender)
			to_chat(sender, span_notice("ERROR: Server is not responding."))
		if(alert_able && !alert_silenced)
			playsound(computer, 'sound/machines/terminal/terminal_error.ogg', 15, TRUE)
		return FALSE

	var/shell_addendum = ""
	if(istype(source, /obj/item/circuit_component))
		var/obj/item/circuit_component/circuit = source
		shell_addendum = "[circuit.parent.get_creator()] "

	// Log in the talk log
	source.log_talk(message, LOG_PDA, tag="[shell_addendum][rigged ? "Rigged" : ""] PDA: [computer.saved_identification] to [signal.format_target()]")
	if(rigged)
		log_bomber(sender, "sent a rigged PDA message (Name: [fake_name]. Job: [fake_job]) to [english_list(stringified_targets)] [!is_special_character(sender) ? "(SENT BY NON-ANTAG)" : ""]")

	// Show it to ghosts
	var/ghost_message = span_game_say("[span_name(signal.format_sender())] [rigged ? "(as [span_name(fake_name)]) Rigged " : ""]PDA Message --> [span_name("[signal.format_target()]")]: \"[signal.format_message()]\"")
	var/list/message_listeners = GLOB.dead_player_list + GLOB.current_observers_list
	for(var/mob/listener as anything in message_listeners)
		if(!(get_chat_toggles(listener) & CHAT_GHOSTPDA))
			continue
		to_chat(listener, "[FOLLOW_LINK(listener, source)] [ghost_message]")

	if(sender)
		to_chat(sender, span_info("PDA message sent to [signal.format_target()]: \"[message]\""))

	if (alert_able && !alert_silenced)
		computer.send_sound()

	COOLDOWN_START(src, last_text, 1 SECONDS)

	SEND_SIGNAL(computer, COMSIG_MODULAR_PDA_MESSAGE_SENT, source, signal)

	selected_image = null
	return TRUE

/datum/computer_file/program/messenger/proc/receive_message(datum/signal/subspace/messaging/tablet_message/signal)
	var/datum/pda_chat/chat = null

	var/is_rigged = signal.data["rigged"]
	var/is_automated = signal.data["automated"]
	var/is_fake_user = is_rigged || is_automated || isnull(signal.data["ref"])
	var/fake_name = is_fake_user ? signal.data["fakename"] : null
	var/fake_job = is_fake_user ? signal.data["fakejob"] : null

	var/sender_ref = signal.data["ref"]


	// don't create a new chat for rigged messages, make it a one off notif
	if(!is_rigged)
		var/datum/pda_message/message = new(signal.data["message"], FALSE, station_time_timestamp(PDA_MESSAGE_TIMESTAMP_FORMAT), signal.data["photo"], signal.data["everyone"])

		chat = find_chat_by_recipient(is_fake_user ? fake_name : sender_ref, is_fake_user)
		if(!istype(chat))
			chat = create_chat(!is_fake_user ? sender_ref : null, fake_name, fake_job)
		chat.add_message(message)
		chat.unread_messages++

		// the recipient (us) currently has a chat with the sender open, so update their ui
		if(!isnull(viewing_messages_of) && viewing_messages_of == sender_ref)
			viewing_messages_of = REF(chat)

	var/list/mob/living/receievers = list()
	if(computer.inserted_pai && computer.inserted_pai.pai)
		receievers += computer.inserted_pai.pai
	if(computer.loc && isliving(computer.loc))
		receievers += computer.loc

	// resolving w/o nullcheck here, assume the messenger exists if a real person sent a message
	var/datum/computer_file/program/messenger/sender_messenger = chat.recipient?.resolve()

	var/sender_title = is_fake_user ? STRINGIFY_PDA_TARGET(fake_name, fake_job) : get_messenger_name(sender_messenger)
	var/sender_name = is_fake_user ? fake_name : sender_messenger.computer.saved_identification

	SEND_SIGNAL(computer, COMSIG_MODULAR_PDA_MESSAGE_RECEIVED, signal, fake_job || sender_messenger?.computer.saved_job , sender_name)

	for(var/mob/living/messaged_mob as anything in receievers)
		if(messaged_mob.stat >= UNCONSCIOUS)
			continue
		if(!messaged_mob.is_literate())
			continue
		var/reply_href = signal.data["rigged"] ? "explode" : "message"
		var/photo_href = signal.data["rigged"] ? "explode" : "open"
		var/reply
		if(is_automated)
			reply = "\[Automated Message\]"
		else
			reply = "(<a href='byond://?src=[REF(src)];choice=[reply_href];skiprefresh=1;target=[REF(chat)]'>Reply</a>)"

		if (isAI(messaged_mob))
			sender_title = "<a href='byond://?src=[REF(messaged_mob)];track=[html_encode(sender_name)]'>[sender_title]</a>"

		var/inbound_message = "[signal.format_message()]"

		var/photo_message = signal.data["photo"] ? " (<a href='byond://?src=[REF(src)];choice=[photo_href];skiprefresh=1;target=[REF(chat)]'>Photo Attached</a>)" : ""
		to_chat(messaged_mob, span_infoplain("[icon2html(computer, messaged_mob)] <b>PDA message from [sender_title], </b>\"[inbound_message]\"[photo_message] [reply]"))

		SEND_SIGNAL(computer, COMSIG_COMPUTER_RECEIVED_MESSAGE, sender_title, inbound_message, photo_message)

	if (alert_able && (!alert_silenced || is_rigged))
		computer.ring(ringtone, receievers)

	SStgui.update_uis(computer)
	update_pictures_for_all()

/// topic call that answers to people pressing "(Reply)" in chat
/datum/computer_file/program/messenger/Topic(href, href_list)
	..()

	if(QDELETED(src))
		return
	if(!usr.can_perform_action(computer, FORBID_TELEKINESIS_REACH | ALLOW_RESTING | ALLOW_PAI))
		return

	// send an activation message and open the messenger
	if(!(computer.enabled || computer.turn_on(usr, open_ui = FALSE)))
		return
	if(!(computer.active_program == src || computer.open_program(usr, src, open_ui = FALSE)))
		return

	var/target_href = href_list["target"]

	switch(href_list["choice"])
		if("message")
			if(!(target_href in saved_chats))
				return
			quick_reply_prompt(usr, saved_chats[target_href])

		if("open")
			if(target_href in saved_chats)
				viewing_messages_of = target_href
			computer.update_tablet_open_uis(usr)

		if("explode")
			if(!HAS_TRAIT(computer, TRAIT_PDA_CAN_EXPLODE))
				return

			var/obj/item/modular_computer/pda/comp = computer
			comp.explode(usr, from_message_menu = TRUE)

#undef PDA_MESSAGE_TIMESTAMP_FORMAT
#undef MAX_PDA_MESSAGE_LEN
#undef TEMP_IMAGE_PATH
