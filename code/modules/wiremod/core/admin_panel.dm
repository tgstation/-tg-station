
ADMIN_VERB(view_all_circuits, R_ADMIN, "View All Circuits", "List all circuits in the game.", ADMIN_CATEGORY_GAME)
	var/static/datum/circuit_admin_panel/circuit_admin_panel = new
	circuit_admin_panel.ui_interact(user.mob)

/datum/circuit_admin_panel

/datum/circuit_admin_panel/ui_static_data(mob/user)
	var/list/data = list()
	data["circuits"] = list()

	for (var/obj/item/integrated_circuit/circuit as anything in GLOB.integrated_circuits)
		var/datum/mind/inserter = circuit.inserter_mind?.resolve()

		data["circuits"] += list(list(
			"ref" = REF(circuit),
			"name" = "[circuit.name] in [loc_name(circuit)]",
			"creator" = circuit.get_creator(),
			"has_inserter" = !isnull(inserter),
		))

	return data

/datum/circuit_admin_panel/ui_act(action, list/params, datum/tgui/ui, datum/ui_state/state)
	. = ..()
	if (.)
		return .

	switch(action)
		if ("disable_circuit_sound")
			CONFIG_SET(flag/disallow_circuit_sounds, !CONFIG_GET(flag/disallow_circuit_sounds))
			message_admins("[key_name_admin(usr)] has toggled all circuit sounds [CONFIG_GET(flag/disallow_circuit_sounds)? "off" : "on"].")
			log_admin("[key_name(usr)] has toggled all circuit sounds [CONFIG_GET(flag/disallow_circuit_sounds)? "off" : "on"].")
			return TRUE

	if (!istext(params["circuit"]))
		return FALSE

	var/obj/item/integrated_circuit/circuit = locate(params["circuit"])
	if (!istype(circuit))
		to_chat(usr, span_warning("That circuit no longer exists."))
		return FALSE

	switch (action)
		if ("duplicate_circuit")
			if (alert(usr, "This will spawn the new circuit at where you are, are you sure?", "Confirm", "Yes", "No") != "Yes")
				return FALSE

			var/list/errors = list()

			var/obj/item/integrated_circuit/loaded/new_circuit = new(usr.drop_location())
			new_circuit.load_circuit_data(circuit.convert_to_json(), errors)

			if (length(errors))
				to_chat(usr, span_warning("Somehow, duplicating the circuit failed:"))
				for (var/error in errors)
					to_chat(usr, span_warning(error))
		if ("follow_circuit")
			usr.client?.admin_follow(circuit)
		if ("save_circuit")
			circuit.attempt_save_to(usr.client)
		if ("vv_circuit")
			usr.client?.debug_variables(circuit)
		if ("open_circuit")
			circuit.ui_interact(usr)

		if ("open_player_panel")
			var/datum/mind/inserter = circuit.inserter_mind?.resolve()
			SSadmin_verbs.dynamic_invoke_verb(usr, /datum/admin_verb/show_player_panel, inserter?.current)

	return TRUE

/datum/circuit_admin_panel/ui_state(mob/user)
	return ADMIN_STATE(R_ADMIN)

/datum/circuit_admin_panel/ui_interact(mob/user, datum/tgui/ui)
	ui = SStgui.try_update_ui(user, src, ui)
	if(!ui)
		ui = new(user, src, "CircuitAdminPanel")
		ui.open()
