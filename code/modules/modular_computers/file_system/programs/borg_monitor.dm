/datum/computer_file/program/borg_monitor
	filename = "siliconnect"
	filedesc = "SiliConnect"
	downloader_category = PROGRAM_CATEGORY_SCIENCE
	ui_header = "borg_mon.gif"
	program_open_overlay = "generic"
	extended_desc = "This program allows for remote monitoring of station cyborgs."
	program_flags = PROGRAM_ON_NTNET_STORE | PROGRAM_REQUIRES_NTNET
	download_access = list(ACCESS_ROBOTICS)
	size = 5
	tgui_id = "NtosCyborgRemoteMonitor"
	program_icon = "project-diagram"
	circuit_comp_type = /obj/item/circuit_component/mod_program/borg_monitor
	var/list/loglist = list() ///A list to copy a borg's IC log list into
	var/mob/living/silicon/robot/DL_source ///reference of a borg if we're downloading a log, or null if not.
	var/DL_progress = -1 ///Progress of current download, 0 to 100, -1 for no current download

/datum/computer_file/program/borg_monitor/Destroy()
	loglist = null
	DL_source = null
	return ..()

/datum/computer_file/program/borg_monitor/kill_program(mob/user)
	loglist = null //Not everything is saved if you close an app
	DL_source = null
	DL_progress = 0
	return ..()

/datum/computer_file/program/borg_monitor/tap(atom/tapped_atom, mob/living/user, list/modifiers)
	var/mob/living/silicon/robot/borgo = tapped_atom
	if(!istype(borgo) || !borgo.modularInterface)
		return FALSE
	DL_source = borgo
	DL_progress = 0

	var/username = "unknown user"
	var/obj/item/card/id/stored_card = computer.GetID()
	if(istype(stored_card) && stored_card.registered_name)
		username = "user [stored_card.registered_name]"
	to_chat(borgo, span_userdanger("Request received from [username] for the system log file. Upload in progress."))//Damning evidence may be contained, so warn the borg
	borgo.logevent("File request by [username]: /var/logs/syslog")
	borgo.balloon_alert(user, "downloading logs")
	return TRUE

/datum/computer_file/program/borg_monitor/process_tick(seconds_per_tick)
	if(!DL_source)
		DL_progress = -1
		return

	var/turf/here = get_turf(computer)
	var/turf/there = get_turf(DL_source)
	if(!here.Adjacent(there))//If someone walked away, cancel the download
		to_chat(DL_source, span_danger("Log upload failed: general connection error."))//Let the borg know the upload stopped
		DL_source = null
		DL_progress = -1
		return

	if(DL_progress == 100)
		if(!DL_source || !DL_source.modularInterface) //sanity check, in case the borg or their modular tablet poofs somehow
			loglist = list("System log of unit [DL_source.name]")
			loglist += "Error -- Download corrupted."
		else
			loglist = DL_source.modularInterface.borglog.Copy()
			loglist.Insert(1,"System log of unit [DL_source.name]")
		DL_progress = -1
		DL_source = null
		return

	DL_progress += 25

/datum/computer_file/program/borg_monitor/ui_data(mob/user)
	var/list/data = list()

	data["card"] = FALSE
	if(checkID())
		data["card"] = TRUE

	data["cyborgs"] = list()
	for(var/mob/living/silicon/robot/R in GLOB.silicon_mobs)
		if(!evaluate_borg(R))
			continue

		var/list/upgrade
		for(var/obj/item/borg/upgrade/I in R.upgrades)
			upgrade += "\[[I.name]\] "

		var/shell = FALSE
		if(R.shell && !R.ckey)
			shell = TRUE

		var/list/cyborg_data = list(
			name = R.name,
			integ = round((R.health + 100) / 2), //mob heath is -100 to 100, we want to scale that to 0 - 100
			locked_down = R.lockcharge,
			status = R.stat,
			shell_discon = shell,
			charge = R.cell ? round(R.cell.percent()) : null,
			module = R.model ? "[R.model.name] Model" : "No Model Detected",
			upgrades = upgrade,
			ref = REF(R)
		)
		data["cyborgs"] += list(cyborg_data)
		data["DL_progress"] = DL_progress

	data["borglog"] = loglist

	return data

/datum/computer_file/program/borg_monitor/ui_act(action, params, datum/tgui/ui, datum/ui_state/state)
	. = ..()
	switch(action)
		if("messagebot")
			var/mob/living/silicon/robot/robot = locate(params["ref"]) in GLOB.silicon_mobs
			message_robot(robot, usr)
			return TRUE

/datum/computer_file/program/borg_monitor/proc/message_robot(mob/living/silicon/robot/robot, mob/user)
	if(!istype(robot))
		return TRUE
	var/ID = checkID()
	if(!ID)
		return FALSE
	if(robot.stat == DEAD) //Dead borgs will listen to you no longer
		to_chat(user, span_warning("Error -- Could not open a connection to unit:[robot]"))
		return FALSE
	var/message = tgui_input_text(user, "Message to be sent to remote cyborg", "Send Message", max_length = MAX_MESSAGE_LEN)
	if(!message)
		return FALSE
	send_message(message, robot, user)

/datum/computer_file/program/borg_monitor/proc/send_message(message, mob/living/silicon/robot/robot, mob/user)
	var/ID = checkID()
	if(!ID)
		return FALSE
	if(robot.stat == DEAD) //Dead borgs will listen to you no longer
		if(user)
			to_chat(user, span_warning("Error -- Could not open a connection to unit:[robot]"))
			return FALSE
	to_chat(robot, "<br><br>[span_notice("Message from [ID] -- \"[message]\"")]<br>")
	if(user)
		to_chat(user, "Message sent to [robot]: [message]")
	robot.logevent("Message from [ID] -- \"[message]\"")
	SEND_SOUND(robot, 'sound/machines/beep/twobeep_high.ogg')
	if(robot.connected_ai)
		to_chat(robot.connected_ai, "<br><br>[span_notice("Message from [ID] to [robot] -- \"[message]\"")]<br>")
		SEND_SOUND(robot.connected_ai, 'sound/machines/beep/twobeep_high.ogg')
	user?.log_talk(message, LOG_PDA, tag = "Cyborg Monitor Program: ID name \"[ID]\" to [robot]")
	return TRUE

///This proc is used to determin if a borg should be shown in the list (based on the borg's scrambledcodes var). Syndicate version overrides this to show only syndicate borgs.
/datum/computer_file/program/borg_monitor/proc/evaluate_borg(mob/living/silicon/robot/R)
	if(!is_valid_z_level(get_turf(computer), get_turf(R)))
		return FALSE
	if(R.scrambledcodes)
		return FALSE
	return TRUE

///Gets the ID's name, if one is inserted into the device. This is a separate proc solely to be overridden by the syndicate version of the app.
/datum/computer_file/program/borg_monitor/proc/checkID()
	var/obj/item/card/id/ID = computer.GetID()
	if(!ID)
		if(computer.obj_flags & EMAGGED)
			return "STDERR:UNDF"
		return FALSE
	. = "[ID.registered_name]"
	if(ID.assignment)
		. = "[.], [ID.assignment]"

/datum/computer_file/program/borg_monitor/syndicate
	filename = "roboverlord"
	filedesc = "Roboverlord"
	downloader_category = PROGRAM_CATEGORY_SCIENCE
	ui_header = "borg_mon.gif"
	program_open_overlay = "generic"
	extended_desc = "This program allows for remote monitoring of mission-assigned cyborgs."
	program_flags = PROGRAM_ON_SYNDINET_STORE
	download_access = list()
	circuit_comp_type = /obj/item/circuit_component/mod_program/borg_monitor/syndie

/datum/computer_file/program/borg_monitor/syndicate/evaluate_borg(mob/living/silicon/robot/R)
	if(!is_valid_z_level(get_turf(computer), get_turf(R)))
		return FALSE
	if(!R.scrambledcodes)
		return FALSE
	return TRUE

/datum/computer_file/program/borg_monitor/syndicate/checkID()
	return "\[CLASSIFIED\]" //no ID is needed for the syndicate version's message function, and the borg will see "[CLASSIFIED]" as the message sender.

/obj/item/circuit_component/mod_program/borg_monitor
	associated_program = /datum/computer_file/program/borg_monitor
	circuit_flags = CIRCUIT_FLAG_INPUT_SIGNAL

	///Circuit input for the robot we want to message
	var/datum/port/input/target_robot
	///The message we want to send
	var/datum/port/input/set_message

/obj/item/circuit_component/mod_program/borg_monitor/populate_ports()
	. = ..()
	target_robot = add_input_port("Receiver", PORT_TYPE_ATOM)
	set_message = add_input_port("Set Message", PORT_TYPE_STRING, trigger = PROC_REF(sanitize_borg_message))

/obj/item/circuit_component/mod_program/borg_monitor/proc/sanitize_borg_message(datum/port/port)
	set_message.set_value(trim(html_encode(set_message.value), MAX_MESSAGE_LEN))

/obj/item/circuit_component/mod_program/borg_monitor/input_received(datum/port/port)
	if(!length(set_message.value) || !iscyborg(target_robot.value))
		return
	var/mob/living/silicon/robot/robot = target_robot.value
	var/datum/computer_file/program/borg_monitor/monitor = associated_program
	if(monitor.send_message(set_message.value, robot))
		monitor.computer.log_talk("Cyborg Monitor message (ID name \"[monitor.checkID()]\") sent to [key_name(robot)] by [parent.get_creator()]: [set_message.value]")

/obj/item/circuit_component/mod_program/borg_monitor/syndie
	associated_program = /datum/computer_file/program/borg_monitor/syndicate
