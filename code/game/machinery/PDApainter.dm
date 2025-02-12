/// Basic machine used to paint PDAs and re-trim ID cards.
/obj/machinery/pdapainter
	name = "\improper Tablet & ID Painter"
	desc = "A painting machine that can be used to paint PDAs and trim IDs. To use, simply insert the item and choose the desired preset."
	icon = 'icons/obj/machines/pda.dmi'
	icon_state = "pdapainter"
	base_icon_state = "pdapainter"
	density = TRUE
	max_integrity = 200
	integrity_failure = 0.5
	/// Current ID card inserted into the machine.
	var/obj/item/card/id/stored_id_card = null
	/// Current PDA inserted into the machine.
	var/obj/item/modular_computer/pda/stored_pda = null
	/// A blacklist of PDA types that we should not be able to paint.
	var/static/list/pda_type_blacklist = list(
		/obj/item/modular_computer/pda/heads,
		/obj/item/modular_computer/pda/clear,
		/obj/item/modular_computer/pda/syndicate,
		/obj/item/modular_computer/pda/chameleon,
		/obj/item/modular_computer/pda/chameleon/broken)
	/// A list of the PDA types that this machine can currently paint.
	var/list/pda_types = list()
	/// A list of the card trims that this machine can currently imprint onto a card.
	var/list/card_trims = list()
	/// Set to a region define (REGION_SECURITY for example) to create a departmental variant, limited to departmental options. If null, this is unrestricted.
	var/target_dept

/obj/machinery/pdapainter/update_icon_state()
	if(machine_stat & BROKEN)
		icon_state = "[base_icon_state]-broken"
		return ..()
	icon_state = "[base_icon_state][powered() ? null : "-off"]"
	return ..()

/obj/machinery/pdapainter/update_overlays()
	. = ..()

	if(machine_stat & BROKEN)
		return

	if(stored_pda || stored_id_card)
		. += "[initial(icon_state)]-closed"

/obj/machinery/pdapainter/Initialize(mapload)
	. = ..()

	if(!target_dept)
		pda_types = SSid_access.station_pda_templates.Copy()
		card_trims = SSid_access.station_job_templates.Copy()
		return

	// Cache the manager list, then check through each manager.
	// If we get a region match, add their trim templates and PDA paths to our lists.
	var/list/manager_cache = SSid_access.sub_department_managers_tgui
	for(var/access_txt in manager_cache)
		var/list/manager_info = manager_cache[access_txt]
		var/list/manager_regions = manager_info["regions"]
		if(target_dept in manager_regions)
			var/list/pda_list = manager_info["pdas"]
			var/list/trim_list = manager_info["templates"]
			pda_types |= pda_list
			card_trims |= trim_list

/obj/machinery/pdapainter/Destroy()
	QDEL_NULL(stored_pda)
	QDEL_NULL(stored_id_card)
	return ..()

/obj/machinery/pdapainter/on_deconstruction(disassembled)
	// Don't use ejection procs as we're gonna be destroyed anyway, so no need to update icons or anything.
	if(stored_pda)
		stored_pda.forceMove(loc)
		stored_pda = null
	if(stored_id_card)
		stored_id_card.forceMove(loc)
		stored_id_card = null

/obj/machinery/pdapainter/contents_explosion(severity, target)
	switch(severity)
		if(EXPLODE_DEVASTATE)
			if(stored_pda)
				SSexplosions.high_mov_atom += stored_pda
			if(stored_id_card)
				SSexplosions.high_mov_atom += stored_id_card
		if(EXPLODE_HEAVY)
			if(stored_pda)
				SSexplosions.med_mov_atom += stored_pda
			if(stored_id_card)
				SSexplosions.med_mov_atom += stored_id_card
		if(EXPLODE_LIGHT)
			if(stored_pda)
				SSexplosions.low_mov_atom += stored_pda
			if(stored_id_card)
				SSexplosions.low_mov_atom += stored_id_card

/obj/machinery/pdapainter/Exited(atom/movable/gone, direction)
	. = ..()
	if(gone == stored_pda)
		stored_pda = null
		update_appearance(UPDATE_ICON)
	if(gone == stored_id_card)
		stored_id_card = null
		update_appearance(UPDATE_ICON)

/obj/machinery/pdapainter/wrench_act(mob/living/user, obj/item/tool)
	. = ..()
	if(default_unfasten_wrench(user, tool))
		power_change()
	return ITEM_INTERACT_SUCCESS

/obj/machinery/pdapainter/attackby(obj/item/O, mob/living/user, params)
	if(machine_stat & BROKEN)
		if(O.tool_behaviour == TOOL_WELDER && !user.combat_mode)
			if(!O.tool_start_check(user, amount=1))
				return
			user.visible_message(span_notice("[user] is repairing [src]."), \
							span_notice("You begin repairing [src]..."), \
							span_hear("You hear welding."))
			if(O.use_tool(src, user, 40, volume=50))
				if(!(machine_stat & BROKEN))
					return
				to_chat(user, span_notice("You repair [src]."))
				set_machine_stat(machine_stat & ~BROKEN)
				atom_integrity = max_integrity
				update_appearance(UPDATE_ICON)
			return
		return ..()

	// Chameleon checks first so they can exit the logic early if they're detected.
	if(istype(O, /obj/item/card/id/advanced/chameleon))
		to_chat(user, span_warning("The machine rejects your [O]. This ID card does not appear to be compatible with the PDA Painter."))
		return

	if(istype(O, /obj/item/modular_computer/pda))
		insert_pda(O, user)
		return

	if(isidcard(O))
		if(stored_id_card)
			to_chat(user, span_warning("There is already an ID card inside!"))
			return

		if(!user.transferItemToLoc(O, src))
			return

		stored_id_card = O
		O.add_fingerprint(user)
		update_appearance(UPDATE_ICON)
		return

	return ..()

/obj/machinery/pdapainter/attack_hand_secondary(mob/user, list/modifiers)
	. = ..()
	if(. == SECONDARY_ATTACK_CANCEL_ATTACK_CHAIN)
		return
	if(stored_pda)
		eject_pda(user)
	else
		eject_id_card(user)
	return SECONDARY_ATTACK_CANCEL_ATTACK_CHAIN

/**
 * Insert a PDA into the machine.
 *
 * Will swap PDAs if one is already inside. Attempts to put the PDA into the user's hands if possible.
 * Returns TRUE on success, FALSE otherwise.
 * Arguments:
 * * new_pda - The PDA to insert.
 * * user - The user to try and eject the PDA into the hands of.
 */
/obj/machinery/pdapainter/proc/insert_pda(obj/item/modular_computer/pda/new_pda, mob/living/user)
	if(!istype(new_pda))
		return FALSE

	if(user && !user.transferItemToLoc(new_pda, src))
		return FALSE
	else
		new_pda.forceMove(src)

	if(stored_pda)
		eject_pda(user)

	stored_pda = new_pda
	new_pda.add_fingerprint(user)
	update_icon()
	return TRUE

/**
 * Eject the stored PDA into the user's hands if possible, otherwise on the floor.
 *
 * Arguments:
 * * user - The user to try and eject the PDA into the hands of.
 */
/obj/machinery/pdapainter/proc/eject_pda(mob/living/user)
	if(stored_pda)
		if(user && !issilicon(user) && in_range(src, user))
			user.put_in_hands(stored_pda)
		else
			stored_pda.forceMove(drop_location())

		stored_pda = null
		update_icon()

/**
 * Insert an ID card into the machine.
 *
 * Will swap ID cards if one is already inside. Attempts to put the card into the user's hands if possible.
 * Returns TRUE on success, FALSE otherwise.
 * Arguments:
 * * new_id_card - The ID card to insert.
 * * user - The user to try and eject the PDA into the hands of.
 */
/obj/machinery/pdapainter/proc/insert_id_card(obj/item/card/id/new_id_card, mob/living/user)
	if(!istype(new_id_card))
		return FALSE

	if(user && !user.transferItemToLoc(new_id_card, src))
		return FALSE
	else
		new_id_card.forceMove(src)

	if(stored_id_card)
		eject_id_card(user)

	stored_id_card = new_id_card
	new_id_card.add_fingerprint(user)
	update_icon()
	return TRUE

/**
 * Eject the stored ID card into the user's hands if possible, otherwise on the floor.
 *
 * Arguments:
 * * user - The user to try and eject the ID card into the hands of.
 */
/obj/machinery/pdapainter/proc/eject_id_card(mob/living/user)
	if(stored_id_card)
		GLOB.manifest.modify(stored_id_card.registered_name, stored_id_card.assignment, stored_id_card.get_trim_assignment())
		if(user && !issilicon(user) && in_range(src, user))
			user.put_in_hands(stored_id_card)
		else
			stored_id_card.forceMove(drop_location())

		stored_id_card = null
		update_appearance(UPDATE_ICON)

/obj/machinery/pdapainter/ui_interact(mob/user, datum/tgui/ui)
	ui = SStgui.try_update_ui(user, src, ui)
	if(!ui)
		ui = new(user, src, "PaintingMachine", name)
		ui.open()

/obj/machinery/pdapainter/ui_data(mob/user)
	var/data = list()

	if(stored_pda)
		data["hasPDA"] = TRUE
		data["pdaName"] = stored_pda.name
	else
		data["hasPDA"] = FALSE
		data["pdaName"] = null

	if(stored_id_card)
		data["hasID"] = TRUE
		data["idName"] = stored_id_card.name
	else
		data["hasID"] = FALSE
		data["idName"] = null

	return data

/obj/machinery/pdapainter/ui_static_data(mob/user)
	var/data = list()

	data["pdaTypes"] = pda_types
	data["cardTrims"] = card_trims

	return data

/obj/machinery/pdapainter/ui_act(action, list/params, datum/tgui/ui, datum/ui_state/state)
	. = ..()
	if(.)
		return

	switch(action)
		if("eject_pda")
			if((machine_stat & BROKEN))
				return TRUE

			var/obj/item/held_item = usr.get_active_held_item()
			if(istype(held_item, /obj/item/modular_computer/pda))
				// If we successfully inserted, we've ejected the old item. Return early.
				if(insert_pda(held_item, usr))
					return TRUE
			// If we did not successfully insert, try to eject.
			if(stored_pda)
				eject_pda(usr)
				return TRUE

			return TRUE
		if("eject_card")
			if((machine_stat & BROKEN))
				return TRUE

			var/obj/item/held_item = usr.get_active_held_item()
			if(isidcard(held_item))
				// If we successfully inserted, we've ejected the old item. Return early.
				if(insert_id_card(held_item, usr))
					return TRUE
			// If we did not successfully insert, try to eject.
			if(stored_id_card)
				eject_id_card(usr)
				return TRUE

			return TRUE
		if("trim_pda")
			if((machine_stat & BROKEN) || !stored_pda)
				return TRUE

			var/selection = params["selection"]
			var/obj/item/modular_computer/pda/pda_path = /obj/item/modular_computer/pda

			for(var/path in pda_types)
				if(pda_types[path] == selection)
					pda_path = path
					break

			if(initial(pda_path.greyscale_config) && initial(pda_path.greyscale_colors))
				stored_pda.set_greyscale(initial(pda_path.greyscale_colors), initial(pda_path.greyscale_config))
			else
				stored_pda.icon = initial(pda_path.icon)
			stored_pda.icon_state = initial(pda_path.icon_state)
			stored_pda.desc = initial(pda_path.desc)

			return TRUE
		if("reset_pda")
			if((machine_stat & BROKEN) || !stored_pda)
				return TRUE

			stored_pda.reset_imprint()
			return TRUE
		if("trim_card")
			if((machine_stat & BROKEN) || !stored_id_card)
				return TRUE

			var/selection = params["selection"]
			for(var/path in card_trims)
				if(card_trims[path] != selection)
					continue

				if(SSid_access.apply_trim_to_card(stored_id_card, path, copy_access = FALSE))
					return TRUE

				to_chat(usr, span_warning("The trim you selected could not be added to \the [stored_id_card]. You will need a rarer ID card to imprint that trim data."))

			return TRUE
		if("reset_card")
			if((machine_stat & BROKEN) || !stored_id_card)
				return TRUE

			stored_id_card.clear_account()

			return TRUE

/// Security departmental variant. Limited to PDAs defined in the SSid_access.sub_department_managers_tgui data structure.
/obj/machinery/pdapainter/security
	name = "\improper Security PDA & ID Painter"
	target_dept = REGION_SECURITY

/// Medical departmental variant. Limited to PDAs defined in the SSid_access.sub_department_managers_tgui data structure.
/obj/machinery/pdapainter/medbay
	name = "\improper Medbay PDA & ID Painter"
	target_dept = REGION_MEDBAY

/// Science departmental variant. Limited to PDAs defined in the SSid_access.sub_department_managers_tgui data structure.
/obj/machinery/pdapainter/research
	name = "\improper Research PDA & ID Painter"
	target_dept = REGION_RESEARCH

/// Engineering departmental variant. Limited to PDAs defined in the SSid_access.sub_department_managers_tgui data structure.
/obj/machinery/pdapainter/engineering
	name = "\improper Engineering PDA & ID Painter"
	target_dept = REGION_ENGINEERING

/// Supply departmental variant. Limited to PDAs defined in the SSid_access.sub_department_managers_tgui data structure.
/obj/machinery/pdapainter/supply
	name = "\improper Supply PDA & ID Painter"
	target_dept = REGION_SUPPLY
