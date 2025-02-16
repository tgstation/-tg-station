ADMIN_VERB(borg_panel, R_ADMIN, "Show Borg Panel", ADMIN_VERB_NO_DESCRIPTION, ADMIN_CATEGORY_HIDDEN, mob/living/silicon/robot/borgo)
	var/datum/borgpanel/borgpanel = new(user.mob, borgo)
	borgpanel.ui_interact(user.mob)

/datum/borgpanel
	var/mob/living/silicon/robot/borg
	var/user

/datum/borgpanel/New(to_user, mob/living/silicon/robot/to_borg)
	if(!istype(to_borg))
		qdel(src)
		CRASH("Borg panel is only available for borgs")
	user = CLIENT_FROM_VAR(to_user)
	if (!user)
		CRASH("Borg panel attempted to open to a mob without a client")
	borg = to_borg

/datum/borgpanel/ui_state(mob/user)
	return ADMIN_STATE(R_ADMIN)

/datum/borgpanel/ui_interact(mob/user, datum/tgui/ui)
	ui = SStgui.try_update_ui(user, src, ui)
	if(!ui)
		ui = new(user, src, "BorgPanel")
		ui.open()

/datum/borgpanel/ui_data(mob/user)
	. = list()
	.["borg"] = list(
		"ref" = REF(borg),
		"name" = "[borg]",
		"emagged" = borg.emagged,
		"active_module" = "[borg.model.type]",
		"lawupdate" = borg.lawupdate,
		"lockdown" = borg.lockcharge,
		"scrambledcodes" = borg.scrambledcodes
	)
	.["upgrades"] = list()
	var/static/list/not_shown_upgrades = list(/obj/item/borg/upgrade/hypospray)
	for (var/upgradetype in subtypesof(/obj/item/borg/upgrade)-not_shown_upgrades) //hypospray is a dummy parent for hypospray upgrades
		var/obj/item/borg/upgrade/upgrade = upgradetype
		if (initial(upgrade.model_type) && !is_type_in_list(borg.model, initial(upgrade.model_type))) // Upgrade requires a different model //HEY ASSHOLE, INITIAL DOESNT WORK WITH LISTS
			continue
		var/installed = FALSE
		if (locate(upgradetype) in borg)
			installed = TRUE
		.["upgrades"] += list(list("name" = initial(upgrade.name), "installed" = installed, "type" = upgradetype))
	.["laws"] = borg.laws ? borg.laws.get_law_list(include_zeroth = TRUE, render_html = FALSE) : list()
	.["channels"] = list()
	for (var/k in GLOB.radiochannels)
		if (k == RADIO_CHANNEL_COMMON)
			continue
		.["channels"] += list(list("name" = k, "installed" = (k in borg.radio.channels)))
	.["cell"] = borg.cell ? list("missing" = FALSE, "maxcharge" = borg.cell.maxcharge, "charge" = borg.cell.charge) : list("missing" = TRUE, "maxcharge" = 1, "charge" = 0)
	.["modules"] = list()
	for(var/model_type in typesof(/obj/item/robot_model))
		var/obj/item/robot_model/model = model_type
		.["modules"] += list(list(
			"name" = initial(model.name),
			"type" = "[model]"
		))
	.["ais"] = list(list("name" = "None", "ref" = "null", "connected" = isnull(borg.connected_ai)))
	for(var/mob/living/silicon/ai/ai in GLOB.ai_list)
		.["ais"] += list(list("name" = ai.name, "ref" = REF(ai), "connected" = (borg.connected_ai == ai)))


/datum/borgpanel/ui_act(action, list/params, datum/tgui/ui, datum/ui_state/state)
	. = ..()
	if(.)
		return
	switch (action)
		if ("set_charge")
			var/newcharge = tgui_input_number(usr, "Set new charge", borg.name, borg.cell.charge, borg.cell.maxcharge)
			if(isnull(newcharge))
				return
			borg.cell.charge = newcharge
			message_admins("[key_name_admin(user)] set the charge of [ADMIN_LOOKUPFLW(borg)] to [borg.cell.charge].")
			log_silicon("[key_name(user)] set the charge of [key_name(borg)] to [borg.cell.charge].")
		if ("remove_cell")
			QDEL_NULL(borg.cell)
			message_admins("[key_name_admin(user)] deleted the cell of [ADMIN_LOOKUPFLW(borg)].")
			log_silicon("[key_name(user)] deleted the cell of [key_name(borg)].")
		if ("change_cell")
			var/chosen = pick_closest_path(null, make_types_fancy(typesof(/obj/item/stock_parts/power_store/cell)))
			if (!ispath(chosen))
				chosen = text2path(chosen)
			if (chosen)
				if (borg.cell)
					QDEL_NULL(borg.cell)
				var/new_cell = new chosen(borg)
				borg.cell = new_cell
				borg.cell.charge = borg.cell.maxcharge
				borg.diag_hud_set_borgcell()
				message_admins("[key_name_admin(user)] changed the cell of [ADMIN_LOOKUPFLW(borg)] to [new_cell].")
				log_silicon("[key_name(user)] changed the cell of [key_name(borg)] to [new_cell].")
		if ("toggle_emagged")
			borg.SetEmagged(!borg.emagged)
			if (borg.emagged)
				message_admins("[key_name_admin(user)] emagged [ADMIN_LOOKUPFLW(borg)].")
				log_silicon("[key_name(user)] emagged [key_name(borg)].")
			else
				message_admins("[key_name_admin(user)] un-emagged [ADMIN_LOOKUPFLW(borg)].")
				log_silicon("[key_name(user)] un-emagged [key_name(borg)].")
		if ("toggle_lawupdate")
			borg.lawupdate = !borg.lawupdate
			if (borg.lawupdate)
				message_admins("[key_name_admin(user)] enabled lawsync on [ADMIN_LOOKUPFLW(borg)].")
				log_silicon("[key_name(user)] enabled lawsync on [key_name(borg)].")
			else
				message_admins("[key_name_admin(user)] disabled lawsync on [ADMIN_LOOKUPFLW(borg)].")
				log_silicon("[key_name(user)] disabled lawsync on [key_name(borg)].")
		if ("toggle_lockdown")
			borg.SetLockdown(!borg.lockcharge)
			if (borg.lockcharge)
				message_admins("[key_name_admin(user)] locked down [ADMIN_LOOKUPFLW(borg)].")
				log_silicon("[key_name(user)] locked down [key_name(borg)].")
			else
				message_admins("[key_name_admin(user)] released [ADMIN_LOOKUPFLW(borg)] from lockdown.")
				log_silicon("[key_name(user)] released [key_name(borg)] from lockdown.")
		if ("toggle_scrambledcodes")
			borg.scrambledcodes = !borg.scrambledcodes
			if (borg.scrambledcodes)
				message_admins("[key_name_admin(user)] enabled scrambled codes on [ADMIN_LOOKUPFLW(borg)].")
				log_silicon("[key_name(user)] enabled scrambled codes on [key_name(borg)].")
			else
				message_admins("[key_name_admin(user)] disabled scrambled codes on [ADMIN_LOOKUPFLW(borg)].")
				log_silicon("[key_name(user)] disabled scrambled codes on [key_name(borg)].")
		if ("rename")
			var/new_name = sanitize_name(tgui_input_text(user, "What would you like to name this cyborg?", "Cyborg Reclassification", borg.real_name, MAX_NAME_LEN), allow_numbers = TRUE)
			if(!new_name)
				return
			message_admins("[key_name_admin(user)] renamed [ADMIN_LOOKUPFLW(borg)] to [new_name].")
			log_silicon("[key_name(user)] renamed [key_name(borg)] to [new_name].")
			borg.fully_replace_character_name(borg.real_name,new_name)
		if ("toggle_upgrade")
			var/upgradepath = text2path(params["upgrade"])
			var/obj/item/borg/upgrade/installedupgrade = locate(upgradepath) in borg.upgrades
			if (installedupgrade)
				message_admins("[key_name_admin(user)] removed the [installedupgrade] upgrade from [ADMIN_LOOKUPFLW(borg)].")
				log_silicon("[key_name(user)] removed the [installedupgrade] upgrade from [key_name(borg)].")
				qdel(installedupgrade) // see [mob/living/silicon/robot/on_upgrade_deleted()].
			else
				var/obj/item/borg/upgrade/upgrade = new upgradepath(borg)
				message_admins("[key_name_admin(user)] added the [upgrade] borg upgrade to [ADMIN_LOOKUPFLW(borg)].")
				log_silicon("[key_name(user)] added the [upgrade] borg upgrade to [key_name(borg)].")
				if(upgrade.action(borg, user))
					borg.add_to_upgrades(upgrade)
				else
					qdel(upgrade)
		if ("toggle_radio")
			var/channel = params["channel"]
			if (channel in borg.radio.channels) // We're removing a channel
				if (!borg.radio.keyslot) // There's no encryption key. This shouldn't happen but we can cope
					borg.radio.channels -= channel
					if (channel == RADIO_CHANNEL_SYNDICATE)
						borg.radio.special_channels &= ~RADIO_SPECIAL_SYNDIE
					else if (channel == "CentCom")
						borg.radio.special_channels &= ~RADIO_SPECIAL_CENTCOM
				else
					borg.radio.keyslot.channels -= channel
					if (channel == RADIO_CHANNEL_SYNDICATE)
						borg.radio.keyslot.special_channels &= ~RADIO_SPECIAL_SYNDIE
					else if (channel == "CentCom")
						borg.radio.keyslot.special_channels &= ~RADIO_SPECIAL_CENTCOM
				message_admins("[key_name_admin(user)] removed the [channel] radio channel from [ADMIN_LOOKUPFLW(borg)].")
				log_silicon("[key_name(user)] removed the [channel] radio channel from [key_name(borg)].")
			else // We're adding a channel
				if (!borg.radio.keyslot) // Assert that an encryption key exists
					borg.radio.keyslot = new()
				borg.radio.keyslot.channels[channel] = 1
				if (channel == RADIO_CHANNEL_SYNDICATE)
					borg.radio.keyslot.special_channels |= RADIO_SPECIAL_SYNDIE
				else if (channel == "CentCom")
					borg.radio.keyslot.special_channels |= RADIO_SPECIAL_CENTCOM
				message_admins("[key_name_admin(user)] added the [channel] radio channel to [ADMIN_LOOKUPFLW(borg)].")
				log_silicon("[key_name(user)] added the [channel] radio channel to [key_name(borg)].")
			borg.radio.recalculateChannels()
		if ("setmodule")
			var/new_model_path = text2path(params["module"])
			if (ispath(new_model_path))
				borg.model.transform_to(new_model_path)
				message_admins("[key_name_admin(user)] changed the model of [ADMIN_LOOKUPFLW(borg)] to [new_model_path].")
				log_silicon("[key_name(user)] changed the model of [key_name(borg)] to [new_model_path].")
		if ("slavetoai")
			var/mob/living/silicon/ai/newai = locate(params["slavetoai"]) in GLOB.ai_list
			if (newai && newai != borg.connected_ai)
				borg.notify_ai(AI_NOTIFICATION_CYBORG_DISCONNECTED)
				if(borg.shell)
					borg.undeploy()
				borg.set_connected_ai(newai)
				borg.notify_ai(TRUE)
				message_admins("[key_name_admin(user)] slaved [ADMIN_LOOKUPFLW(borg)] to the AI [ADMIN_LOOKUPFLW(newai)].")
				log_silicon("[key_name(user)] slaved [key_name(borg)] to the AI [key_name(newai)].")
			else if (params["slavetoai"] == "null")
				borg.notify_ai(AI_NOTIFICATION_CYBORG_DISCONNECTED)
				if(borg.shell)
					borg.undeploy()
				borg.set_connected_ai(null)
				message_admins("[key_name_admin(user)] freed [ADMIN_LOOKUPFLW(borg)] from being slaved to an AI.")
				log_silicon("[key_name(user)] freed [key_name(borg)] from being slaved to an AI.")
			if (borg.lawupdate)
				borg.lawsync()

	. = TRUE
