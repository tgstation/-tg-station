/*
	The monitoring computer for the messaging server.
	Lets you read PDA and request console messages.
*/

#define LINKED_SERVER_NONRESPONSIVE  (!linkedServer || (linkedServer.machine_stat & (NOPOWER|BROKEN)))

#define MSG_MON_SCREEN_MAIN 0
#define MSG_MON_SCREEN_LOGS 1
#define MSG_MON_SCREEN_REQUEST_LOGS 2
#define MSG_MON_SCREEN_HACKED 3

/obj/machinery/computer/message_monitor
	name = "message monitor console"
	desc = "Used to monitor the crew's PDA messages, as well as request console messages."
	icon_screen = "comm_logs"
	circuit = /obj/item/circuitboard/computer/message_monitor
	light_color = LIGHT_COLOR_GREEN
	/// Server linked to.
	var/obj/machinery/telecomms/message_server/linkedServer = null
	/// Sparks effect - For emag
	var/datum/effect_system/spark_spread/spark_system
	/// Computer properties.
	/// 0 = Main menu, 1 = Message Logs, 2 = Hacked screen, 3 = Custom Message
	var/screen = MSG_MON_SCREEN_MAIN
	/// The message that shows on the main menu.
	var/message = "System bootup complete. Please select an option."
	/// Error message to display in the interface.
	var/error_message = ""
	/// Notice message to display in the interface.
	var/notice_message = ""
	/// Success message to display in the interface.
	var/success_message = ""
	/// Decrypt password
	var/password = ""

/obj/machinery/computer/message_monitor/screwdriver_act(mob/living/user, obj/item/I)
	if(obj_flags & EMAGGED)
		//Stops people from just unscrewing the monitor and putting it back to get the console working again.
		to_chat(user, span_warning("It is too hot to mess with!"))
		return TRUE
	return ..()

/obj/machinery/computer/message_monitor/emag_act(mob/user, obj/item/card/emag/emag_card)
	if(obj_flags & EMAGGED)
		return FALSE
	if(!isnull(linkedServer))
		obj_flags |= EMAGGED
		screen = MSG_MON_SCREEN_HACKED
		spark_system.set_up(5, 0, src)
		spark_system.start()
		var/obj/item/paper/monitorkey/monitor_key_paper = new(loc, linkedServer)
		// Will help make emagging the console not so easy to get away with.
		monitor_key_paper.add_raw_text("<br><br><font color='red'>£%@%(*$%&(£&?*(%&£/{}</font>")
		var/time = 100 * length(linkedServer.decryptkey)
		addtimer(CALLBACK(src, PROC_REF(unemag_console)), time)
		error_message = "%$&(£: Critical %$$@ Error // !RestArting! <lOadiNg backUp iNput ouTput> - ?pLeaSe wAit!"
		linkedServer.toggled = FALSE
		return TRUE
	else
		to_chat(user, span_notice("A no server error appears on the screen."))
	return FALSE

/// Remove the emag effect from the console
/obj/machinery/computer/message_monitor/proc/unemag_console()
	screen = MSG_MON_SCREEN_MAIN
	linkedServer.toggled = TRUE
	error_message = ""
	obj_flags &= ~EMAGGED

/obj/machinery/computer/message_monitor/Initialize(mapload)
	..()
	spark_system = new
	GLOB.telecomms_list += src
	return INITIALIZE_HINT_LATELOAD

/obj/machinery/computer/message_monitor/post_machine_initialize()
	. = ..()
	//Is the server isn't linked to a server, and there's a server available, default it to the first one in the list.
	if(!linkedServer)
		for(var/obj/machinery/telecomms/message_server/message_server in GLOB.telecomms_list)
			linkedServer = message_server
			break

/obj/machinery/computer/message_monitor/Destroy()
	GLOB.telecomms_list -= src
	linkedServer = null
	return ..()

/obj/machinery/computer/message_monitor/ui_data(mob/user)
	var/list/data = list(
		"screen" = screen,
		"error_message" = error_message,
		"notice_message" = notice_message,
		"success_message" = success_message,
		"auth" = authenticated,
		"server_status" = !LINKED_SERVER_NONRESPONSIVE,
	)

	switch(screen)
		if(MSG_MON_SCREEN_MAIN)
			data["password"] = password
			data["status"] = linkedServer.on
			// Check is AI or cyborg malf
			var/mob/living/silicon/silicon_user = user
			data["is_malf"] = istype(silicon_user) && silicon_user.hack_software

		if(MSG_MON_SCREEN_LOGS)
			var/list/message_list = list()
			for(var/datum/data_tablet_msg/pda in linkedServer.pda_msgs)
				message_list += list(list("ref" = REF(pda), "sender" = pda.sender, "recipient" = pda.recipient, "message" = pda.message))
			data["messages"] = message_list
		if(MSG_MON_SCREEN_REQUEST_LOGS)
			var/list/request_list = list()
			for(var/datum/data_rc_msg/rc in linkedServer.rc_msgs)
				request_list += list(list("ref" = REF(rc), "message" = rc.message, "stamp" = rc.stamp, "id_auth" = rc.id_auth, "departament" = rc.sender_department))
			data["requests"] = request_list
	return data

/obj/machinery/computer/message_monitor/ui_act(action, list/params, datum/tgui/ui, datum/ui_state/state)
	. = ..()
	if(.)
		return .

	error_message = ""
	success_message = ""
	notice_message = ""

	switch(action)
		if("auth")
			var/authPass = params["auth_password"]

			if(authenticated)
				authenticated = FALSE
				return TRUE

			if(linkedServer.decryptkey != authPass)
				error_message = "ALERT: Incorrect decryption key!"
				return TRUE

			authenticated = TRUE
			success_message = "YOU SUCCESSFULLY LOGGED IN!"

			return TRUE
		if("link_server")
			var/list/message_servers = list()
			for (var/obj/machinery/telecomms/message_server/message_server in GLOB.telecomms_list)
				message_servers += message_server

			if(length(message_servers) > 1)
				linkedServer = tgui_input_list(usr, "Please select a server", "Server Selection", message_servers)
				if(linkedServer)
					notice_message = "NOTICE: Server selected."
				else if(length(message_servers) > 0)
					linkedServer = message_servers[1]
					notice_message = "NOTICE: Only Single Server Detected - Server selected."
				else
					error_message = "ALERT: No server detected."
			screen = MSG_MON_SCREEN_MAIN
			return TRUE
		if("turn_server")
			if(LINKED_SERVER_NONRESPONSIVE)
				error_message = "ALERT: No server detected."
				return TRUE

			linkedServer.toggled = !linkedServer.toggled
			return TRUE
		if("view_message_logs")
			screen = MSG_MON_SCREEN_LOGS
			return
		if("view_request_logs")
			screen = MSG_MON_SCREEN_REQUEST_LOGS
			return TRUE
		if("clear_message_logs")
			linkedServer.pda_msgs = list()
			notice_message = "NOTICE: Logs cleared."
			return TRUE
		if("clear_request_logs")
			linkedServer.rc_msgs = list()
			notice_message = "NOTICE: Logs cleared."
			return TRUE
		if("set_key")
			var/dkey = tgui_input_text(usr, "Please enter the decryption key", "Telecomms Decryption", max_length = 16)
			if(dkey && dkey != "")
				if(linkedServer.decryptkey == dkey)
					var/newkey = tgui_input_text(usr, "Please enter the new key (3 - 16 characters max)", "New Key", max_length = 16)
					if(length(newkey) <= 3)
						notice_message = "NOTICE: Decryption key too short!"
					else if(newkey && newkey != "")
						linkedServer.decryptkey = newkey
					notice_message = "NOTICE: Decryption key set."
				else
					error_message = "ALERT: Incorrect decryption key!"
			return TRUE
		if("return_home")
			screen = MSG_MON_SCREEN_MAIN
			return TRUE
		if("delete_message")
			linkedServer.pda_msgs -= locate(params["ref"]) in linkedServer.pda_msgs
			success_message = "Log Deleted!"
			return TRUE
		if("delete_request")
			linkedServer.rc_msgs -= locate(params["ref"]) in linkedServer.rc_msgs
			success_message = "Log Deleted!"
			return TRUE
		if("connect_server")
			if(!linkedServer)
				for(var/obj/machinery/telecomms/message_server/S in GLOB.telecomms_list)
					linkedServer = S
					break
			return TRUE
		if("send_fake_message")
			var/sender = tgui_input_text(usr, "What is the sender's name?", "Sender", max_length = MAX_NAME_LEN)
			var/job = tgui_input_text(usr, "What is the sender's job?", "Job", max_length = 60)

			var/recipient
			var/list/tablet_to_messenger = list()
			var/list/viewable_tablets = list()
			for (var/messenger_ref in GLOB.pda_messengers)
				var/datum/computer_file/program/messenger/message_app = GLOB.pda_messengers[messenger_ref]
				if(!message_app || message_app.invisible)
					continue
				if(!message_app.computer.saved_identification)
					continue
				viewable_tablets += message_app.computer
				tablet_to_messenger[message_app.computer] = message_app
			if(length(viewable_tablets) > 0)
				recipient = tgui_input_list(usr, "Select a tablet from the list", "Tablet Selection", viewable_tablets)
			else
				recipient = null

			var/message = tgui_input_text(usr, "Please enter your message", "Message", max_length = MAX_MESSAGE_LEN)
			if(isnull(sender) || sender == "")
				sender = "UNKNOWN"

			if(isnull(recipient))
				notice_message = "NOTICE: No recipient selected!"
				return attack_hand(usr)
			if(isnull(message) || message == "")
				notice_message = "NOTICE: No message entered!"
				return attack_hand(usr)

			var/datum/signal/subspace/messaging/tablet_message/signal = new(src, list(
				"fakename" = "[sender]",
				"fakejob" = "[job]",
				"message" = message,
				"targets" = list(tablet_to_messenger[recipient]),
			))
			// This will log the signal and transmit it to the target
			linkedServer.receive_information(signal, null)
			usr.log_message("(Tablet: [name] | [usr.real_name]) sent \"[message]\" to [signal.format_target()]", LOG_PDA)
			return TRUE
		// Malfunction AI and cyborgs can hack console. This will authenticate the console, but you need to wait password selection
		if("hack")
			var/time = 10 SECONDS * length(linkedServer.decryptkey)
			addtimer(CALLBACK(src, PROC_REF(unemag_console)), time)
			screen = MSG_MON_SCREEN_HACKED
			error_message = "%$&(£: Critical %$$@ Error // !RestArting! <lOadiNg backUp iNput ouTput> - ?pLeaSe wAit!"
			linkedServer.toggled = FALSE
			authenticated = TRUE
			return TRUE
	return TRUE

/obj/machinery/computer/message_monitor/ui_interact(mob/user, datum/tgui/ui)
	. = ..()
	ui = SStgui.try_update_ui(user, src, ui)
	if (!ui)
		ui = new(user, src, "MessageMonitor", name)
		ui.open()

/obj/machinery/computer/message_monitor/ui_assets(mob/user)
	. = ..()
	. += get_asset_datum(/datum/asset/spritesheet_batched/chat)

#undef MSG_MON_SCREEN_MAIN
#undef MSG_MON_SCREEN_LOGS
#undef MSG_MON_SCREEN_REQUEST_LOGS
#undef MSG_MON_SCREEN_HACKED
#undef LINKED_SERVER_NONRESPONSIVE

/// Monitor decryption key paper

/obj/item/paper/monitorkey
	name = "monitor decryption key"

/obj/item/paper/monitorkey/Initialize(mapload, obj/machinery/telecomms/message_server/server)
	. = ..()
	if (server)
		print(server)
		return INITIALIZE_HINT_NORMAL
	return INITIALIZE_HINT_LATELOAD

/**
 * Handles printing the monitor key for a given server onto this piece of paper.
 */
/obj/item/paper/monitorkey/proc/print(obj/machinery/telecomms/message_server/server)
	add_raw_text("<center><h2>Daily Key Reset</h2></center><br>The new message monitor key is <b>[server.decryptkey]</b>.<br>Please keep this a secret and away from the clown.<br>If necessary, change the password to a more secure one.")
	add_overlay("paper_words")
	update_appearance()

/obj/item/paper/monitorkey/LateInitialize()
	for (var/obj/machinery/telecomms/message_server/preset/server in GLOB.telecomms_list)
		if (server.decryptkey)
			print(server)
			break
