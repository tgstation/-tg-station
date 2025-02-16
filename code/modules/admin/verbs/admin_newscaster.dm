ADMIN_VERB(access_news_network, R_ADMIN, "Access Newscaster Network", "Allows you to view, add, and edit news feeds.", ADMIN_CATEGORY_EVENTS)
	var/datum/newspanel/new_newspanel = new
	new_newspanel.ui_interact(user.mob)

/datum/newspanel
	///What newscaster channel is currently being viewed by the player?
	var/datum/feed_channel/current_channel
	///What newscaster feed_message is currently having a comment written for it?
	var/datum/feed_message/current_message
	///The message that's currently being written for a feed story.
	var/feed_channel_message
	///The current image that will be submitted with the newscaster story.
	var/datum/picture/current_image
	///Is the current user creating a new channel at the moment?
	var/creating_channel = FALSE
	///Is the current user creating a new comment at the moment?
	var/creating_comment = FALSE
	///Is the current user editing or viewing a new wanted issue at the moment?
	var/viewing_wanted  = FALSE
	///What is the user submitted, criminal name for the new wanted issue?
	var/criminal_name
	///What is the user submitted, crime description for the new wanted issue?
	var/crime_description
	///What is the current, in-creation channel's name going to be?
	var/channel_name
	///What is the current, in-creation channel's description going to be?
	var/channel_desc
	///What is the current, in-creation comment's body going to be?
	var/comment_text

/datum/newspanel/ui_state(mob/user)
	return ADMIN_STATE(R_ADMIN)

/datum/newspanel/ui_interact(mob/user, datum/tgui/ui)
	ui = SStgui.try_update_ui(user, src, ui)
	if(!ui)
		ui = new(user, src, "PhysicalNewscaster")
		ui.open()

/datum/newspanel/ui_static_data(mob/user)
	. = ..()
	if (!is_admin(user))
		to_chat(usr, "Error: you are not an admin!", confidential = TRUE)
		return

/datum/newspanel/ui_data(mob/user)
	. = list()
	var/list/data = list()
	var/list/channel_list = list()
	var/list/message_list = list()

	data["user"] = list()
	data["user"]["name"] = "Centcom Official"
	data["user"]["job"] = "Official"
	data["user"]["department"] = "Department of News"

	data["admin_mode"] = TRUE
	data["security_mode"] = TRUE
	data["photo_data"] = !isnull(current_image)
	data["creating_channel"] = creating_channel
	data["creating_comment"] = creating_comment

	//Here is all the UI_data sent about the current wanted issue, as well as making a new one in the UI.
	data["viewing_wanted"] = viewing_wanted
	data["making_wanted_issue"] = !(GLOB.news_network.wanted_issue?.active)
	data["criminal_name"] = criminal_name
	data["crime_description"] = crime_description
	var/list/wanted_info = list()
	if(GLOB.news_network.wanted_issue)
		var/has_wanted_issue = !isnull(GLOB.news_network.wanted_issue.img)
		if(has_wanted_issue)
			user << browse_rsc(GLOB.news_network.wanted_issue.img, "wanted_photo.png")
		wanted_info = list(list(
			"active" = GLOB.news_network.wanted_issue.active,
			"criminal" = GLOB.news_network.wanted_issue.criminal,
			"crime" = GLOB.news_network.wanted_issue.body,
			"author" = GLOB.news_network.wanted_issue.scanned_user,
			"image" = (has_wanted_issue ? "wanted_photo.png" : null)
		))

	//Code breaking down the channels that have been made on-station thus far. ha
	//Then, breaks down the messages that have been made on those channels.
	for(var/datum/feed_channel/channel as anything in GLOB.news_network.network_channels)
		channel_list += list(list(
			"name" = channel.channel_name,
			"author" = channel.author,
			"censored" = channel.censored,
			"locked" = channel.locked,
			"ID" = channel.channel_ID,
		))
	if(current_channel)
		for(var/datum/feed_message/feed_message as anything in current_channel.messages)
			var/photo_ID = null
			var/list/comment_list
			if(feed_message.img)
				user << browse_rsc(feed_message.img, "tmp_photo[feed_message.message_ID].png")
				photo_ID = "tmp_photo[feed_message.message_ID].png"
			for(var/datum/feed_comment/comment_message as anything in feed_message.comments)
				comment_list += list(list(
					"auth" = comment_message.author,
					"body" = comment_message.body,
					"time" = comment_message.time_stamp,
				))
			message_list += list(list(
				"auth" = feed_message.author,
				"body" = feed_message.body,
				"time" = feed_message.time_stamp,
				"channel_num" = feed_message.parent_ID,
				"censored_message" = feed_message.body_censor,
				"censored_author" = feed_message.author_censor,
				"ID" = feed_message.message_ID,
				"photo" = photo_ID,
				"comments" = comment_list
			))


	data["viewing_channel"] = current_channel?.channel_ID
	//Here we display all the information about the current channel.
	data["channelName"] = current_channel?.channel_name
	data["channelAuthor"] = current_channel?.author

	if(!current_channel)
		data["channelAuthor"] = "Nanotrasen Inc"
		data["channelDesc"] = "Welcome to Newscaster Net. Interface & News networks Operational."
		data["channelLocked"] = TRUE
	else
		data["channelDesc"] = current_channel.channel_desc
		data["channelLocked"] = current_channel.locked
		data["channelCensored"] = current_channel.censored

	//We send all the information about all channels and all messages in existence.
	data["channels"] = channel_list
	data["messages"] = message_list
	data["wanted"] = wanted_info
	return data

/datum/newspanel/ui_act(action, list/params, datum/tgui/ui, datum/ui_state/state)
	. = ..()
	if(.)
		return

	switch(action)
		if("setChannel")
			var/prototype_channel = params["channel"]
			if(isnull(prototype_channel))
				return TRUE
			for(var/datum/feed_channel/potential_channel as anything in GLOB.news_network.network_channels)
				if(prototype_channel == potential_channel.channel_ID)
					current_channel = potential_channel

		if("createStory")
			if(!current_channel)
				to_chat(usr, "select a channel first!")
				return TRUE
			var/prototype_channel = params["current"]
			create_story(channel_name = prototype_channel)

		if("togglePhoto")
			toggle_photo()
			return TRUE

		if("startCreateChannel")
			start_creating_channel()
			return TRUE

		if("setChannelName")
			var/pre_channel_name = params["channeltext"]
			if(!pre_channel_name)
				return TRUE
			channel_name = pre_channel_name

		if("setChannelDesc")
			var/pre_channel_desc = params["channeldesc"]
			if(!pre_channel_desc)
				return TRUE
			channel_desc = pre_channel_desc

		if("createChannel")
			var/locked = params["lockedmode"]
			create_channel(locked)
			return TRUE

		if("cancelCreation")
			creating_channel = FALSE
			creating_comment = FALSE
			viewing_wanted = FALSE
			return TRUE

		if("storyCensor")
			var/questionable_message = params["messageID"]
			for(var/datum/feed_message/iterated_feed_message as anything in current_channel.messages)
				if(iterated_feed_message.message_ID == questionable_message)
					iterated_feed_message.toggle_censor_body()
					break

		if("author_censor")
			var/questionable_message = params["messageID"]
			for(var/datum/feed_message/iterated_feed_message in current_channel.messages)
				if(iterated_feed_message.message_ID == questionable_message)
					iterated_feed_message.toggle_censor_author()
					break

		if("channelDNotice")
			var/prototype_channel = (params["channel"])
			for(var/datum/feed_channel/potential_channel in GLOB.news_network.network_channels)
				if(prototype_channel == potential_channel.channel_ID)
					current_channel = potential_channel
					break
			current_channel.toggle_censor_D_class()

		if("startComment")
			creating_comment = TRUE
			var/commentable_message = params["messageID"]
			if(!commentable_message)
				return TRUE
			for(var/datum/feed_message/iterated_feed_message as anything in current_channel.messages)
				if(iterated_feed_message.message_ID == commentable_message)
					current_message = iterated_feed_message
			return TRUE

		if("setCommentBody")
			var/pre_comment_text = params["commenttext"]
			if(!pre_comment_text)
				return TRUE
			comment_text = pre_comment_text
			return TRUE

		if("createComment")
			create_comment()
			return TRUE

		if("toggleWanted")
			viewing_wanted = TRUE
			return TRUE

		if("setCriminalName")
			var/temp_name = tgui_input_text(usr, "Write the Criminal's Name", "Warrent Alert Handler", "John Doe", max_length = MAX_NAME_LEN, multiline = FALSE)
			if(!temp_name)
				return TRUE
			criminal_name = temp_name
			return TRUE

		if("setCrimeData")
			var/temp_desc = tgui_input_text(usr, "Write the Criminal's Crimes", "Warrent Alert Handler", "Unknown", max_length = MAX_BROADCAST_LEN, multiline = TRUE)
			if(!temp_desc)
				return TRUE
			crime_description = temp_desc
			return TRUE

		if("submitWantedIssue")
			if(!crime_description || !criminal_name)
				return TRUE
			GLOB.news_network.submit_wanted(criminal_name, crime_description, "Centcom Official", current_image, adminMsg = TRUE, newMessage = TRUE)
			current_image = null
			return TRUE

		if("clearWantedIssue")
			clear_wanted_issue(user = usr)
			return TRUE

	return TRUE


/**
 * Sends photo data to build the newscaster article.
 */
/datum/newspanel/proc/send_photo_data()
	if(!current_image)
		return null
	return current_image

/**
 * This takes a held photograph, and updates the current_image variable with that of the held photograph's image.
 * *user: The mob who is being checked for a held photo object.
 */
/datum/newspanel/proc/attach_photo(mob/user)
	to_chat(user, "I didn't add this!")
	return

/**
 * Performs a series of sanity checks before giving the user confirmation to create a new feed_channel using channel_name, and channel_desc.
 * *channel_locked: This variable determines if other users than the author can make comments and new feed_stories on this channel.
 */
/datum/newspanel/proc/create_channel(channel_locked)
	if(!channel_name)
		return
	for(var/datum/feed_channel/iterated_feed_channel as anything in GLOB.news_network.network_channels)
		if(iterated_feed_channel.channel_name == channel_name)
			tgui_alert(usr, "ERROR: Feed channel with that name already exists on the Network.", list("Okay"))
			return TRUE
	if(!channel_desc)
		return TRUE
	if(isnull(channel_locked))
		return TRUE
	var/choice = tgui_alert(usr, "Please confirm feed channel creation","Network Channel Handler", list("Confirm","Cancel"))
	if(choice == "Confirm")
		GLOB.news_network.create_feed_channel(channel_name, "Centcom Official", channel_desc, locked = channel_locked)
		SSblackbox.record_feedback("text", "newscaster_channels", 1, "[channel_name]")
	creating_channel = FALSE

/**
 * Constructs a comment to attach to the currently selected feed_message of choice, assuming that a user can be found and that a message body has been written.
 */
/datum/newspanel/proc/create_comment()
	if(!comment_text)
		creating_comment = FALSE
		return TRUE
	var/datum/feed_comment/new_feed_comment = new /datum/feed_comment
	new_feed_comment.author = "Centcom Official"
	new_feed_comment.body = comment_text
	new_feed_comment.time_stamp = station_time_timestamp()
	current_message.comments += new_feed_comment
	GLOB.news_network.last_action ++
	usr.log_message("(as an admin) commented on message [current_message.return_body(-1)] -- [current_message.body]", LOG_COMMENT)
	creating_comment = FALSE

/**
 * This proc performs checks before enabling the creating_channel var on the newscaster, such as preventing a user from having multiple channels,
 * preventing an un-ID'd user from making a channel, and preventing censored authors from making a channel.
 * Otherwise, sets creating_channel to TRUE.
 */
/datum/newspanel/proc/start_creating_channel()
	//This first block checks for pre-existing reasons to prevent you from making a new channel, like being censored, or if you have a channel already.
	var/list/existing_authors = list()
	for(var/datum/feed_channel/iterated_feed_channel as anything in GLOB.news_network.network_channels)
		if(iterated_feed_channel.author_censor)
			existing_authors += GLOB.news_network.redacted_text
		else
			existing_authors += iterated_feed_channel.author
	creating_channel = TRUE

/**
 * Creates a new feed story to the global newscaster network.
 * Verifies that the message is being written to a real feed_channel, then provides a text input for the feed story to be written into.
 * Finally, it submits the message to the network, is logged globally, and clears all message-specific variables from the machine.
 */
/datum/newspanel/proc/create_story(channel_name)
	for(var/datum/feed_channel/potential_channel as anything in GLOB.news_network.network_channels)
		if(channel_name == potential_channel.channel_ID)
			current_channel = potential_channel
			break
	var/temp_message = tgui_input_text(usr, "Write your Feed story", "Network Channel Handler", feed_channel_message, max_length = MAX_BROADCAST_LEN, multiline = TRUE)
	if(length(temp_message) <= 1)
		return TRUE
	if(temp_message)
		feed_channel_message = temp_message
	GLOB.news_network.submit_article("<font face=\"[PEN_FONT]\">[parsemarkdown(feed_channel_message, usr)]</font>", "Centcom Official", current_channel.channel_name, send_photo_data(), adminMessage = TRUE, allow_comments = TRUE)
	SSblackbox.record_feedback("amount", "newscaster_stories", 1)
	feed_channel_message = ""
	current_image = null

/**
 * Selects a currently held photo from the user's hand and makes it the current_image held by the newscaster.
 * If a photo is still held in the newscaster, it will otherwise clear it from the machine.
 */
/datum/newspanel/proc/toggle_photo()
	if(current_image)
		current_image = null
		return TRUE
	else
		attach_photo(usr)
		return TRUE

/datum/newspanel/proc/clear_wanted_issue(user)
	GLOB.news_network.wanted_issue.active = FALSE
	return
