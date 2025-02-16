/**
 * update_tablet_open_uis
 *
 * Will search the user to see if they have the tablet open.
 * If they don't, we'll open a new UI depending on the tab the tablet is meant to be on.
 * If they do, we'll update the interface and title, then update all static data and re-send assets.
 *
 * This is best called when you're actually changing the app, as we don't check
 * if we're swapping to the current UI repeatedly.
 * Args:
 * user - The person whose UI we're updating. Only necessary if we're opening the UI for the first time.
 */
/obj/item/modular_computer/proc/update_tablet_open_uis(mob/user)
	if(user)
		var/datum/tgui/active_ui = SStgui.get_open_ui(user, src)
		if(!active_ui)
			if(active_program)
				active_ui = new(user, src, active_program.tgui_id, active_program.filedesc)
				active_program.ui_interact(user, active_ui)
			else
				active_ui = new(user, src, "NtosMain")
			return active_ui.open()

	for (var/datum/tgui/window as anything in open_uis)
		if(active_program)
			window.interface = active_program.tgui_id
			window.title = active_program.filedesc
			active_program.ui_interact(window.user, window)
		else
			window.interface = "NtosMain"
		window.send_assets()
	update_static_data_for_all_viewers()


/obj/item/modular_computer/ui_state(mob/user)
	if(inserted_pai && (user == inserted_pai.pai))
		return GLOB.contained_state
	return ..()

/obj/item/modular_computer/interact(mob/user)
	if(enabled)
		ui_interact(user)
	else
		turn_on(user)

// Operates TGUI
/obj/item/modular_computer/ui_interact(mob/user, datum/tgui/ui)
	if(!enabled || !user.can_read(src, READING_CHECK_LITERACY))
		ui?.close()
		return

	// Robots don't really need to see the screen, their wireless connection works as long as computer is on.
	if(!screen_on && !issilicon(user))
		ui?.close()
		return

	if(honkvirus_amount > 0) // EXTRA annoying, huh!
		honkvirus_amount--
		playsound(src, 'sound/items/bikehorn.ogg', 30, TRUE)

	ui = SStgui.try_update_ui(user, src, ui)
	if(!ui)
		update_tablet_open_uis(user)
	else if(active_program?.always_update_ui)
		active_program.ui_interact(user, ui)

/obj/item/modular_computer/ui_assets(mob/user)
	var/list/data = list()
	data += get_asset_datum(/datum/asset/simple/headers)
	if(active_program)
		data += active_program.ui_assets(user)
	return data

/obj/item/modular_computer/ui_static_data(mob/user)
	var/list/data = list()
	if(active_program)
		data += active_program.ui_static_data(user)
		return data

	data["show_imprint"] = istype(src, /obj/item/modular_computer/pda)
	return data

/obj/item/modular_computer/ui_data(mob/user)
	var/list/data = get_header_data()
	if(active_program)
		data += active_program.ui_data(user)
		return data

	data["pai"] = inserted_pai
	data["has_light"] = has_light
	data["light_on"] = light_on
	data["comp_light_color"] = comp_light_color

	data["login"] = list(
		IDName = saved_identification || "Unknown",
		IDJob = saved_job || "Unknown",
	)

	data["proposed_login"] = list(
		IDInserted = computer_id_slot ? TRUE : FALSE,
		IDName = computer_id_slot?.registered_name,
		IDJob = computer_id_slot?.assignment,
	)

	data["removable_media"] = list()
	if(inserted_disk)
		data["removable_media"] += "Eject Disk"
	var/datum/computer_file/program/ai_restorer/airestore_app = locate() in stored_files
	if(airestore_app?.stored_card)
		data["removable_media"] += "intelliCard"

	data["programs"] = list()
	for(var/datum/computer_file/program/program in stored_files)
		data["programs"] += list(list(
			"name" = program.filename,
			"desc" = program.filedesc,
			"header_program" = !!(program.program_flags & PROGRAM_HEADER),
			"running" = !!(program in idle_threads),
			"icon" = program.program_icon,
			"alert" = program.alert_pending,
		))

	return data

// Handles user's GUI input
/obj/item/modular_computer/ui_act(action, list/params, datum/tgui/ui, datum/ui_state/state)
	. = ..()
	if(.)
		return

	if(ishuman(usr) && !allow_chunky)
		var/mob/living/carbon/human/human_user = usr
		if(human_user.check_chunky_fingers())
			balloon_alert(human_user, "fingers are too big!")
			return TRUE

	switch(action)
		if("PC_exit")
			//you can't close apps in emergency mode.
			if(isnull(internal_cell) || internal_cell.charge)
				active_program.kill_program(usr)
			return TRUE
		if("PC_shutdown")
			shutdown_computer()
			return TRUE
		if("PC_minimize")
			if(!active_program || (!isnull(internal_cell) && !internal_cell.charge))
				return
			active_program.background_program(usr)
			return TRUE

		if("PC_killprogram")
			var/prog = params["name"]
			var/datum/computer_file/program/killed_program = find_file_by_name(prog)

			if(!istype(killed_program))
				return

			killed_program.kill_program(usr)
			to_chat(usr, span_notice("Program [killed_program.filename].[killed_program.filetype] with PID [rand(100,999)] has been killed."))
			return TRUE

		if("PC_runprogram")
			open_program(usr, find_file_by_name(params["name"]))
			return TRUE

		if("PC_toggle_light")
			toggle_flashlight()
			return TRUE

		if("PC_light_color")
			var/mob/user = usr
			var/new_color
			while(!new_color)
				new_color = input(user, "Choose a new color for [src]'s flashlight.", "Light Color",light_color) as color|null
				if(!new_color)
					return
				if(is_color_dark(new_color, 50) ) //Colors too dark are rejected
					to_chat(user, span_warning("That color is too dark! Choose a lighter one."))
					new_color = null
			set_flashlight_color(new_color)
			return TRUE

		if("PC_Eject_Disk")
			var/param = params["name"]
			var/mob/user = usr
			switch(param)
				if("Eject Disk")
					if(!inserted_disk)
						return

					user.put_in_hands(inserted_disk)
					inserted_disk = null
					playsound(src, 'sound/machines/card_slide.ogg', 50)
					return TRUE

				if("intelliCard")
					var/datum/computer_file/program/ai_restorer/airestore_app = locate() in stored_files
					if(!airestore_app)
						return

					if(airestore_app.try_eject(user))
						playsound(src, 'sound/machines/card_slide.ogg', 50)
						return TRUE

				if("ID")
					if(RemoveID(user))
						playsound(src, 'sound/machines/card_slide.ogg', 50)
						return TRUE

		if("PC_Imprint_ID")
			imprint_id()
			UpdateDisplay()
			playsound(src, 'sound/machines/terminal/terminal_processing.ogg', 15, TRUE)

		if("PC_Pai_Interact")
			switch(params["option"])
				if("eject")
					if(!ishuman(usr))
						return
					remove_pai(usr)
				if("interact")
					inserted_pai.attack_self(usr)
			return TRUE

	if(active_program)
		return active_program.ui_act(action, params, ui, state)

/obj/item/modular_computer/ui_host()
	if(physical)
		return physical
	return src

/obj/item/modular_computer/ui_close(mob/user)
	. = ..()
	if(active_program)
		active_program.ui_close(user)
