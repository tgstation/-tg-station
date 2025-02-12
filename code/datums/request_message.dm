
/datum/request_message
	/// The r5tname of the department request console that sent the message
	var/sender_department = ""
	/// The time when the message arrived
	var/received_time = null
	/// The message itself
	var/content = ""
	/// The name on the ID that verified the message
	var/message_verified_by = ""
	/// The name of the stamp that verified the message
	var/message_stamped_by = ""
	/// The priority of the message
	var/priority = ""
	/// The radio channel the message should be broadcasted on
	var/radio_channel = null
	/// The type of the request
	var/request_type = ""
	/// A list to be appended after the message, for example, list of ores
	var/appended_list = list()

/datum/request_message/New(data)
	sender_department =  data["sender_department"]
	received_time = station_time_timestamp()
	content = data["message"]
	message_verified_by = data["verified"]
	message_stamped_by = data["stamped"]
	priority = data["priority"]
	radio_channel = data["notify_channel"]
	request_type = data["ore_update"] ? ORE_UPDATE_REQUEST : data["request_type"]
	var/list/data_appended_list = data["appended_list"]
	if(data_appended_list && data_appended_list.len)
		appended_list = data_appended_list

/// Retrieves the alert spoken/blared by the requests console that receives this message
/datum/request_message/proc/get_alert()
	var/authenticated = ""
	if(message_verified_by)
		authenticated = ", Verified by [message_verified_by] (Authenticated)"
	else if (message_stamped_by)
		authenticated = ", Stamped by [message_stamped_by] (Authenticated)"

	return "Message from [sender_department][authenticated]"

/// Converts the message into a format for the tgui ui_data json
/datum/request_message/proc/message_ui_data()
	var/list/ui_data = list()
	ui_data["sender_department"] = sender_department
	ui_data["received_time"] = received_time
	ui_data["content"] = content
	ui_data["message_verified_by"] = message_verified_by
	ui_data["message_stamped_by"] = message_stamped_by
	ui_data["priority"] = priority
	ui_data["request_type"] = request_type
	ui_data["appended_list"] = appended_list

	return ui_data
