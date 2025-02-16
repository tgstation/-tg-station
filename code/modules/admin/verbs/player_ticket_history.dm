/// Holds information about a ticket
/datum/ticket_history
	var/player_ckey
	/// Number of the ticket *for that round*
	var/ticket_number
	var/round_id
	var/list/ticket_log

/datum/ticket_log_entry
	var/timestamp
	var/origin_ckey
	var/target_ckey
	var/action
	var/message

GENERAL_PROTECT_DATUM(/datum/ticket_history)
GENERAL_PROTECT_DATUM(/datum/ticket_log_entry)

GLOBAL_DATUM_INIT(player_ticket_history, /datum/ticket_history_holder, new)
GLOBAL_PROTECT(player_ticket_history)

ADMIN_VERB(player_ticket_history, R_ADMIN, "Player Ticket History", "Allows you to view the ticket history of a player.", ADMIN_CATEGORY_MAIN)
	GLOB.player_ticket_history.ui_interact(user.mob)

/datum/ticket_history_holder
	/// Assosciative list of ticket histories. ckey -> list/datum/ticket_history
	var/list/ticket_histories = list()
	/// Assosciative list of user_ckey -> target_ckey
	var/list/user_selections = list()

/datum/ticket_history_holder/proc/cache_history_for_ckey(ckey, entries = 5)
	ckey = LOWER_TEXT(ckey)

	if(!isnum(entries) || entries <= 0)
		return

	var/list/datum/ticket_history/history_cache = list()
	ticket_histories[ckey] = history_cache

	var/datum/db_query/ticket_lookup = SSdbcore.NewQuery("\
		WITH DISTINCT_TICKETS AS ( \
			SELECT id, round_id, ticket, sender, recipient FROM [format_table_name("ticket")] \
			WHERE id IN ( \
				SELECT MAX(id) FROM ticket GROUP BY round_id, ticket \
			) \
			AND round_id != :current_round \
		) \
		SELECT round_id, ticket FROM DISTINCT_TICKETS \
		WHERE sender = :ckey OR recipient = :ckey \
		ORDER BY id DESC \
		LIMIT :max_entries",
		list(
			"ckey" = ckey,
			"current_round" = GLOB.round_id,
			"max_entries" = entries,
		)
	)
	if(!ticket_lookup.Execute())
		qdel(ticket_lookup)
		to_chat(usr, "Failed to query ticket history for [ckey]!")
		return

	var/list/lookup_targets = list()
	// round-ticket
	while(ticket_lookup.NextRow())
		lookup_targets += "[ticket_lookup.item[1]]-[ticket_lookup.item[2]]"
	qdel(ticket_lookup)

	for(var/lookup_string in lookup_targets)
		ASYNC
			var/datum/ticket_history/ticket_history = new
			history_cache += ticket_history

			var/round = splittext(lookup_string, "-")[1]
			var/ticket = splittext(lookup_string, "-")[2]

			ticket_history.round_id = text2num(round)
			ticket_history.ticket_number = text2num(ticket)

			var/datum/db_query/ticket_lookup_instance = SSdbcore.NewQuery("\
				SELECT action, message, timestamp, recipient, sender \
				FROM [format_table_name("ticket")] \
				WHERE round_id = :round AND ticket = :ticket \
				ORDER BY id DESC \
			", list(
				"round" = round,
				"ticket" = ticket
			))
			if(!ticket_lookup_instance.warn_execute())
				qdel(ticket_lookup_instance)
				lookup_targets -= lookup_string
				continue

			var/list/ticket_log = list()
			while(ticket_lookup_instance.NextRow())
				var/datum/ticket_log_entry/log_entry = new
				ticket_log += log_entry
				log_entry.action = ticket_lookup_instance.item[1]
				log_entry.message = ticket_lookup_instance.item[2]
				log_entry.timestamp = ticket_lookup_instance.item[3]
				log_entry.target_ckey = ticket_lookup_instance.item[4]
				log_entry.origin_ckey = ticket_lookup_instance.item[5]
			qdel(ticket_lookup_instance)
			ticket_history.ticket_log = ticket_log
			lookup_targets -= lookup_string

	// wait for all the queries to finish
	UNTIL(lookup_targets.len == 0)

	if(!length(history_cache))
		to_chat(usr, span_adminnotice("No ticket history found for [ckey]!"))
		ticket_histories -= ckey
		return

	to_chat(usr, span_adminnotice("Finished caching ticket history for [ckey]!"))

/datum/ticket_history_holder/ui_state(mob/user)
	return ADMIN_STATE(R_ADMIN)

/datum/ticket_history_holder/ui_static_data(mob/user)
	if(!check_rights_for(CLIENT_FROM_VAR(user), R_ADMIN))
		return list()

	if(!SSdbcore.IsConnected())
		return list(
			"db_connected" = 0,
		)

	var/list/data = list(
		"db_connected" = TRUE,
	)
	var/list/cached_ckeys = list()
	for(var/ckey in ticket_histories)
		cached_ckeys += ckey
	data["cached_ckeys"] = cached_ckeys

	if(user.ckey in user_selections)
		var/list/ticket_cache = list()
		for(var/datum/ticket_history/ticket_history as anything in ticket_histories[user_selections[user.ckey]])
			var/list/ticket_data = list(
				"ticket_number" = ticket_history.ticket_number,
				"round_id" = ticket_history.round_id,
			)
			var/list/ticket_log = list()
			for(var/datum/ticket_log_entry/entry as anything in ticket_history.ticket_log)
				ticket_log += list(list(
					"timestamp" = entry.timestamp,
					"origin_ckey" = entry.origin_ckey,
					"target_ckey" = entry.target_ckey,
					"action" = entry.action,
					"message" = entry.message,
				))

			ticket_data["ticket_log"] = ticket_log
			ticket_cache += list(ticket_data)
		data["ticket_cache"] = ticket_cache
		data["target_ckey"] = user_selections[user.ckey]

	return data

/datum/ticket_history_holder/ui_act(action, list/params, datum/tgui/ui, datum/ui_state/state)
	. = ..()
	if(.)
		return

	switch(action)
		if("select-user")
			var/target = params["target"]
			if(!(target in ticket_histories))
				return TRUE
			user_selections[ui.user.ckey] = target
			SStgui.update_static_data(ui.user, ui)
			return TRUE

		if("cache-user")
			var/target = params["target"]
			var/amount = ("amount" in params) ? params["amount"] : 5
			cache_history_for_ckey(target, amount)
			SStgui.update_static_data(ui.user, ui)
			return TRUE

		else
			stack_trace("[type]/ui_act: unknown action type [action]")

/datum/ticket_history_holder/ui_interact(mob/user, datum/tgui/ui)
	ui = SStgui.try_update_ui(user, src, ui)
	if(!isnull(ui))
		ui.send_full_update()
		return

	ui = new(user, src, "PlayerTicketHistory")
	ui.set_autoupdate(FALSE)
	ui.open()
