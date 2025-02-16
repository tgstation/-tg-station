GLOBAL_DATUM_INIT(interviews, /datum/interview_manager, new)

/**
 * # Interview Manager
 *
 * Handles all interviews in the duration of a round, includes the primary functionality for
 * handling the interview queue.
 */
/datum/interview_manager
	/// The interviews that are currently "open", those that are not submitted as well as those that are waiting review
	var/list/open_interviews = list()
	/// The queue of interviews to be processed (submitted interviews)
	var/list/interview_queue = list()
	/// All closed interviews
	var/list/closed_interviews = list()
	/// Ckeys which are allowed to bypass the time-based allowlist
	var/list/approved_ckeys = list()
	/// Ckeys which are currently in the cooldown system, they will be unable to create new interviews
	var/list/cooldown_ckeys = list()

/datum/interview_manager/Destroy(force)
	QDEL_LIST(open_interviews)
	QDEL_LIST(interview_queue)
	QDEL_LIST(closed_interviews)
	QDEL_LIST(approved_ckeys)
	QDEL_LIST(cooldown_ckeys)
	return ..()

/**
 * Used in the new client pipeline to catch when clients are reconnecting and need to have their
 * reference re-assigned to the 'owner' variable of an interview
 *
 * Arguments:
 * * C - The client who is logging in
 */
/datum/interview_manager/proc/client_login(client/C)
	for(var/ckey in open_interviews)
		var/datum/interview/I = open_interviews[ckey]
		if (I && !I.owner && C.ckey == I.owner_ckey)
			I.owner = C

/**
 * Used in the destroy client pipeline to catch when clients are disconnecting and need to have their
 * reference nulled on the 'owner' variable of an interview
 *
 * Arguments:
 * * C - The client who is logging out
 */
/datum/interview_manager/proc/client_logout(client/C)
	for(var/ckey in open_interviews)
		var/datum/interview/I = open_interviews[ckey]
		if (I?.owner && C.ckey == I.owner_ckey)
			I.owner = null

/**
 * Attempts to return an interview for a given client, using an existing interview if found, otherwise
 * a new interview is created; if the user is on cooldown then it will return null.
 *
 * Arguments:
 * * C - The client to get the interview for
 */
/datum/interview_manager/proc/interview_for_client(client/C)
	if (!C)
		return
	if (open_interviews[C.ckey])
		return open_interviews[C.ckey]
	else if (!(C.ckey in cooldown_ckeys))
		log_admin_private("New interview created for [key_name(C)].")
		open_interviews[C.ckey] = new /datum/interview(C)
		return open_interviews[C.ckey]

/**
 * Attempts to return an interview for a provided ID, will return null if no matching interview is found
 *
 * Arguments:
 * * id - The ID of the interview to find
 */
/datum/interview_manager/proc/interview_by_id(id)
	if (!id)
		return
	for (var/ckey in open_interviews)
		var/datum/interview/I = open_interviews[ckey]
		if (I?.id == id)
			return I
	for (var/datum/interview/I in closed_interviews)
		if (I.id == id)
			return I

/**
 * Enqueues an interview in the interview queue, and notifies admins of the new interview to be
 * reviewed.
 *
 * Arguments:
 * * to_queue - The interview to enqueue
 */
/datum/interview_manager/proc/enqueue(datum/interview/to_queue)
	if (!to_queue || (to_queue in interview_queue))
		return
	to_queue.pos_in_queue = interview_queue.len + 1
	interview_queue |= to_queue

	// Notify admins
	var/ckey = to_queue.owner_ckey
	log_admin_private("Interview for [ckey] has been enqueued for review. Current position in queue: [to_queue.pos_in_queue]")
	var/admins_present = send2tgs_adminless_only("panic-bunker-interview", "Interview for [ckey] enqueued for review. Current position in queue: [to_queue.pos_in_queue]")
	if (admins_present <= 0 && to_queue.owner)
		to_chat(to_queue.owner, span_notice("No active admins are online, your interview's submission was sent through TGS to admins who are available. This may use IRC or Discord."))
	for(var/client/X in GLOB.admins)
		if(X.prefs.toggles & SOUND_ADMINHELP)
			SEND_SOUND(X, sound('sound/effects/adminhelp.ogg'))
		window_flash(X, ignorepref = TRUE)
		to_chat(X, span_adminhelp("[to_queue.link_self()] for [ckey] enqueued for review. Current position in queue: [to_queue.pos_in_queue]"), confidential = TRUE)

/**
 * Removes a ckey from the cooldown list, used for enforcing cooldown after an interview is denied.
 *
 * Arguments:
 * * ckey - The ckey to remove from the cooldown list
 */
/datum/interview_manager/proc/release_from_cooldown(ckey)
	cooldown_ckeys -= ckey

/**
 * Dequeues the first interview from the interview queue, and updates the queue positions of any relevant
 * interviews that follow it.
 */
/datum/interview_manager/proc/dequeue()
	if (interview_queue.len == 0)
		return

	// Get the first interview off the front of the queue
	var/datum/interview/to_return = interview_queue[1]
	interview_queue -= to_return

	// Decrement any remaining interview queue positions
	for(var/datum/interview/i in interview_queue)
		i.pos_in_queue--

	return to_return

/**
 * Dequeues an interview from the interview queue if present, and updates the queue positions of
 * any relevant interviews that follow it.
 *
 * Arguments:
 * * to_dequeue - The interview to dequeue
 */
/datum/interview_manager/proc/dequeue_specific(datum/interview/to_dequeue)
	if (!to_dequeue)
		return

	// Decrement all interviews in queue past the interview being removed
	var/found = FALSE
	for (var/datum/interview/i in interview_queue)
		if (found)
			i.pos_in_queue--
		if (i == to_dequeue)
			found = TRUE

	interview_queue -= to_dequeue

/**
 * Closes an interview, removing it from the queued interviews as well as adding it to the closed
 * interviews list.
 *
 * Arguments:
 * * to_close - The interview to dequeue
 */
/datum/interview_manager/proc/close_interview(datum/interview/to_close)
	if (!to_close)
		return
	dequeue_specific(to_close)
	if (open_interviews[to_close.owner_ckey])
		open_interviews -= to_close.owner_ckey
		closed_interviews += to_close

/datum/interview_manager/ui_interact(mob/user, datum/tgui/ui = null)
	ui = SStgui.try_update_ui(user, src, ui)
	if (!ui)
		ui = new(user, src, "InterviewManager")
		ui.open()

/datum/interview_manager/ui_state(mob/user)
	return ADMIN_STATE(R_ADMIN)

/datum/interview_manager/ui_act(action, list/params, datum/tgui/ui, datum/ui_state/state)
	if (..())
		return
	switch(action)
		if ("open")
			var/datum/interview/I = interview_by_id(text2num(params["id"]))
			if (I)
				I.ui_interact(usr)


/datum/interview_manager/ui_data(mob/user)
	. = list(
		"open_interviews" = list(),
		"closed_interviews" = list())
	for (var/ckey in open_interviews)
		var/datum/interview/I = open_interviews[ckey]
		if (I)
			var/list/data = list(
				"id" = I.id,
				"ckey" = I.owner_ckey,
				"status" = I.status,
				"queued" = I.pos_in_queue && I.status == INTERVIEW_PENDING,
				"disconnected" = !I.owner
			)
			.["open_interviews"] += list(data)
	for (var/datum/interview/I in closed_interviews)
		var/list/data = list(
			"id" = I.id,
			"ckey" = I.owner_ckey,
			"status" = I.status,
			"disconnected" = !I.owner
		)
		.["closed_interviews"] += list(data)
