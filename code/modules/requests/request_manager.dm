/// Requests from prayers
#define REQUEST_PRAYER "request_prayer"
/// Requests for Centcom
#define REQUEST_CENTCOM "request_centcom"
/// Requests for the Syndicate
#define REQUEST_SYNDICATE "request_syndicate"
/// Requests for the nuke code
#define REQUEST_NUKE "request_nuke"
/// Requests somebody from fax
#define REQUEST_FAX "request_fax"
/// Requests from Request Music
#define REQUEST_INTERNET_SOUND "request_internet_sound"

GLOBAL_DATUM_INIT(requests, /datum/request_manager, new)

/**
 * # Request Manager
 *
 * Handles all player requests (prayers, centcom requests, syndicate requests)
 * that occur in the duration of a round.
 */
/datum/request_manager
	/// Associative list of ckey -> list of requests
	var/list/requests = list()
	/// List where requests can be accessed by ID
	var/list/requests_by_id = list()

/datum/request_manager/Destroy(force)
	QDEL_LIST(requests)
	return ..()

/**
 * Used in the new client pipeline to catch when clients are reconnecting and need to have their
 * reference re-assigned to the 'owner' variable of any requests
 *
 * Arguments:
 * * C - The client who is logging in
 */
/datum/request_manager/proc/client_login(client/C)
	if (!requests[C.ckey])
		return
	for (var/datum/request/request as anything in requests[C.ckey])
		request.owner = C

/**
 * Used in the destroy client pipeline to catch when clients are disconnecting and need to have their
 * reference nulled on the 'owner' variable of any requests
 *
 * Arguments:
 * * C - The client who is logging out
 */
/datum/request_manager/proc/client_logout(client/C)
	if (!requests[C.ckey])
		return
	for (var/datum/request/request as anything in requests[C.ckey])
		request.owner = null

/**
 * Creates a request for a prayer, and notifies admins who have the sound notifications enabled when appropriate
 *
 * Arguments:
 * * C - The client who is praying
 * * message - The prayer
 * * is_chaplain - Boolean operator describing if the prayer is from a chaplain
 */
/datum/request_manager/proc/pray(client/C, message, is_chaplain)
	request_for_client(C, REQUEST_PRAYER, message)
	for(var/client/admin in GLOB.admins)
		if(is_chaplain && get_chat_toggles(admin) & CHAT_PRAYER && admin.prefs.toggles & SOUND_PRAYERS)
			SEND_SOUND(admin, sound('sound/effects/pray.ogg'))

/**
 * Creates a request for a Centcom message
 *
 * Arguments:
 * * C - The client who is sending the request
 * * message - The message
 */
/datum/request_manager/proc/message_centcom(client/C, message)
	request_for_client(C, REQUEST_CENTCOM, message)

/**
 * Creates a request for a Syndicate message
 *
 * Arguments:
 * * C - The client who is sending the request
 * * message - The message
 */
/datum/request_manager/proc/message_syndicate(client/C, message)
	request_for_client(C, REQUEST_SYNDICATE, message)

/**
 * Creates a request for the nuclear self destruct codes
 *
 * Arguments:
 * * C - The client who is sending the request
 * * message - The message
 */
/datum/request_manager/proc/nuke_request(client/C, message)
	request_for_client(C, REQUEST_NUKE, message)

/**
 * Creates a request for fax answer
 *
 * Arguments:
 * * requester - The client who is sending the request
 * * message - Paper with text.. some stamps.. and another things.
 */
/datum/request_manager/proc/fax_request(client/requester, message, additional_info)
	request_for_client(requester, REQUEST_FAX, message, additional_info)

/**
 * Creates a request for a song
 *
 * Arguments:
 * * requester - The client who is sending the request
 * * message - The URL of the song
 */

/datum/request_manager/proc/music_request(client/requester, message)
	request_for_client(requester, REQUEST_INTERNET_SOUND, message)

/**
 * Creates a request and registers the request with all necessary internal tracking lists
 *
 * Arguments:
 * * C - The client who is sending the request
 * * type - The type of request, see defines
 * * message - The message
 */
/datum/request_manager/proc/request_for_client(client/C, type, message, additional_info)
	var/datum/request/request = new(C, type, message, additional_info)
	if (!requests[C.ckey])
		requests[C.ckey] = list()
	requests[C.ckey] += request
	requests_by_id.len++
	requests_by_id[request.id] = request

/datum/request_manager/ui_interact(mob/user, datum/tgui/ui = null)
	ui = SStgui.try_update_ui(user, src, ui)
	if (!ui)
		ui = new(user, src, "RequestManager")
		ui.open()

/datum/request_manager/ui_state(mob/user)
	return ADMIN_STATE(R_ADMIN)

/datum/request_manager/ui_act(action, list/params, datum/tgui/ui, datum/ui_state/state)
	if (..())
		return

	// Only admins should be sending actions
	if (!check_rights(R_ADMIN))
		to_chat(usr, "You do not have permission to do this, you require +ADMIN", confidential = TRUE)
		return

	if (action == "toggleprint")
		GLOB.fax_autoprinting = !GLOB.fax_autoprinting
		return TRUE

	// Get the request this relates to
	var/id = params["id"] != null ? text2num(params["id"]) : null
	if (!id)
		to_chat(usr, "Failed to find a request ID in your action, please report this", confidential = TRUE)
		CRASH("Received an action without a request ID, this shouldn't happen!")
	var/datum/request/request = !id ? null : requests_by_id[id]

	switch(action)
		if ("pp")
			SSadmin_verbs.dynamic_invoke_verb(ui.user, /datum/admin_verb/show_player_panel, request.owner?.mob)
			return TRUE

		if ("vv")
			var/mob/M = request.owner?.mob
			usr.client.debug_variables(M)
			return TRUE

		if ("sm")
			SSadmin_verbs.dynamic_invoke_verb(ui.user, /datum/admin_verb/cmd_admin_subtle_message, request.owner?.mob)
			return TRUE

		if ("flw")
			var/mob/M = request.owner?.mob
			usr.client.admin_follow(M)
			return TRUE
		if ("tp")
			if(!SSticker.HasRoundStarted())
				tgui_alert(usr,"The game hasn't started yet!")
				return TRUE
			var/mob/M = request.owner?.mob
			if(!ismob(M))
				var/datum/mind/D = M
				if(!istype(D))
					to_chat(usr, "This can only be used on instances of type /mob and /mind", confidential = TRUE)
					return TRUE
				else
					D.traitor_panel()
					return TRUE
			else
				SSadmin_verbs.dynamic_invoke_verb(usr, /datum/admin_verb/show_traitor_panel, M)
				return TRUE

		if ("logs")
			var/mob/M = request.owner?.mob
			if(!ismob(M))
				to_chat(usr, "This can only be used on instances of type /mob.", confidential = TRUE)
				return TRUE
			show_individual_logging_panel(M, null, null)
			return TRUE

		if ("smite")
			SSadmin_verbs.dynamic_invoke_verb(ui.user, /datum/admin_verb/admin_smite, request.owner?.mob)
			return TRUE

		if ("rply")
			if (request.req_type == REQUEST_PRAYER)
				to_chat(usr, "Cannot reply to a prayer", confidential = TRUE)
				return TRUE
			var/mob/M = request.owner?.mob
			usr.client.admin_headset_message(M, request.req_type == REQUEST_SYNDICATE ? RADIO_CHANNEL_SYNDICATE : RADIO_CHANNEL_CENTCOM)
			return TRUE
		if ("setcode")
			if (request.req_type != REQUEST_NUKE)
				to_chat(usr, "You cannot set the nuke code for a non-nuke-code-request request!", confidential = TRUE)
				return TRUE
			var/code = random_nukecode()
			for(var/obj/machinery/nuclearbomb/selfdestruct/SD in SSmachines.get_machines_by_type_and_subtypes(/obj/machinery/nuclearbomb/selfdestruct))
				SD.r_code = code
			message_admins("[key_name_admin(usr)] has set the self-destruct code to \"[code]\".")
			return TRUE
		if ("show")
			if(request.req_type != REQUEST_FAX)
				to_chat(usr, "Request doesn't have a paper to read.", confidential = TRUE)
				return TRUE
			var/obj/item/paper/request_message = request.additional_information["paper"]
			request_message.ui_interact(usr)
			return TRUE
		if ("print")
			if (request.req_type != REQUEST_FAX)
				to_chat(usr, "Request doesn't have a paper to print.", confidential = TRUE)
				return TRUE
			for(var/obj/machinery/fax/admin/FAX as anything in SSmachines.get_machines_by_type_and_subtypes(/obj/machinery/fax/admin))
				if(FAX.fax_id != request.additional_information["destination_id"])
					continue
				var/obj/item/paper/request_message = request.additional_information["paper"]
				var/sender_name = request.additional_information["sender_name"]
				FAX.receive(request_message, sender_name)
				return TRUE
		if ("play")
			if(request.req_type != REQUEST_INTERNET_SOUND)
				to_chat(usr, "Request doesn't have a sound to play.", confidential = TRUE)
				return TRUE
			if(findtext(request.message, ":") && !findtext(request.message, GLOB.is_http_protocol))
				to_chat(usr, "Request is not a valid URL.", confidential = TRUE)
				return TRUE

			web_sound(usr, request.message)
			return TRUE

/datum/request_manager/ui_data(mob/user)
	var/list/data = list()
	for (var/ckey in requests)
		for (var/datum/request/request as anything in requests[ckey])
			data["requests"] += list(list(
				"id" = request.id,
				"req_type" = request.req_type,
				"owner" = request.owner ? "[REF(request.owner)]" : null,
				"owner_ckey" = request.owner_ckey,
				"owner_name" = request.owner_name,
				"message" = request.message,
				"additional_info" = request.additional_information,
				"timestamp" = request.timestamp,
				"timestamp_str" = gameTimestamp(wtime = request.timestamp)
			))
	data["fax_autoprinting"] = GLOB.fax_autoprinting
	return data

#undef REQUEST_PRAYER
#undef REQUEST_CENTCOM
#undef REQUEST_SYNDICATE
#undef REQUEST_NUKE
#undef REQUEST_FAX
#undef REQUEST_INTERNET_SOUND
