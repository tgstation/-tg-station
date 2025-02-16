ADMIN_VERB_ONLY_CONTEXT_MENU(select_equipment, R_FUN, "Select Equipment", mob/target in world)
	var/datum/select_equipment/ui = new(user, target)
	ui.ui_interact(user.mob)

/*
 * This is the datum housing the select equipment UI.
 *
 * You may notice some oddities about the way outfits are passed to the UI and vice versa here.
 * That's because it handles both outfit typepaths (for normal outfits) *and* outfit objects (for custom outfits).
 *
 * Custom outfits need to be objects as they're created in runtime.
 * "Then just handle the normal outfits as objects too and simplify the handling" - you may say.
 * There are about 300 outfit types at the time of writing this. Initializing all of these to objects would be a huge waste.
 *
 */

/datum/select_equipment
	var/client/user
	var/mob/target_mob

	var/dummy_key

	//static list to share all the outfit typepaths between all instances of this datum.
	var/static/list/cached_outfits

	//a typepath if the selected outfit is a normal outfit;
	//an object if the selected outfit is a custom outfit
	var/datum/outfit/selected_outfit = /datum/outfit
	//serializable string for the UI to keep track of which outfit is selected
	var/selected_identifier = "/datum/outfit"

/datum/select_equipment/New(_user, mob/target)
	user = CLIENT_FROM_VAR(_user)

	if(!ishuman(target) && !isobserver(target))
		tgui_alert(usr,"Invalid mob")
		return
	target_mob = target

/datum/select_equipment/ui_interact(mob/user, datum/tgui/ui)
	ui = SStgui.try_update_ui(user, src, ui)
	if(!ui)
		ui = new(user, src, "SelectEquipment", "Select Equipment")
		ui.open()
		ui.set_autoupdate(FALSE)

/datum/select_equipment/ui_state(mob/user)
	return ADMIN_STATE(R_FUN)

/datum/select_equipment/ui_status(mob/user, datum/ui_state/state)
	if(QDELETED(target_mob))
		return UI_CLOSE
	return ..()

/datum/select_equipment/ui_close(mob/user)
	clear_human_dummy(dummy_key)
	qdel(src)

/datum/select_equipment/proc/init_dummy()
	dummy_key = "selectequipmentUI_[target_mob]"
	generate_dummy_lookalike(dummy_key, target_mob)
	unset_busy_human_dummy(dummy_key)
	return

/**
 * Packs up data about an outfit as an assoc list to send to the UI as an outfit entry.
 *
 * Args:
 * * category (string) - The tab it will be under
 *
 * * identifier (typepath or ref) - This will sent this back to ui_act to preview or spawn in an outfit.
 * * Must be unique between all entries.
 *
 * * name (string) - Will be the text on the button
 *
 * * priority (bool)(optional) - If True, the UI will sort the entry to the top, right below favorites.
 *
 * * custom_entry (bool)(optional) - Send the identifier with a "ref" keyword instead of "path",
 * * for the UI to tell apart custom outfits from normal ones.
 *
 * Returns (list) An outfit entry
 */

/datum/select_equipment/proc/outfit_entry(category, identifier, name, priority=FALSE, custom_entry=FALSE)
	if(custom_entry)
		return list("category" = category, "ref" = identifier, "name" = name, "priority" = priority)
	return list("category" = category, "path" = identifier, "name" = name, "priority" = priority)

/datum/select_equipment/proc/make_outfit_entries(category="General", list/outfit_list)
	var/list/entries = list()
	for(var/path as anything in outfit_list)
		var/datum/outfit/outfit = path
		entries += list(outfit_entry(category, path, initial(outfit.name)))
	return entries

//GLOB.custom_outfits lists outfit *objects* so we'll need to do some custom handling for it
/datum/select_equipment/proc/make_custom_outfit_entries(list/outfit_list)
	var/list/entries = list()
	for(var/datum/outfit/outfit as anything in outfit_list)
		entries += list(outfit_entry("Custom", REF(outfit), outfit.name, custom_entry=TRUE)) //it's either this or special handling on the UI side
	return entries

/datum/select_equipment/ui_data(mob/user)
	var/list/data = list()
	if(!dummy_key)
		init_dummy()

	var/icon/dummysprite = get_flat_human_icon(null,
		dummy_key = dummy_key,
		outfit_override = selected_outfit)
	data["icon64"] = icon2base64(dummysprite)
	data["name"] = target_mob

	var/datum/preferences/prefs = user?.client?.prefs
	data["favorites"] = list()
	if(prefs)
		data["favorites"] = prefs.favorite_outfits

	var/list/custom
	custom += make_custom_outfit_entries(GLOB.custom_outfits)
	data["custom_outfits"] = custom
	data["current_outfit"] = selected_identifier
	return data


/datum/select_equipment/ui_static_data(mob/user)
	var/list/data = list()
	if(!cached_outfits)
		cached_outfits = list()
		cached_outfits += list(outfit_entry("General", /datum/outfit, "Naked", priority=TRUE))
		cached_outfits += make_outfit_entries("General", subtypesof(/datum/outfit) - typesof(/datum/outfit/job) - typesof(/datum/outfit/plasmaman))
		cached_outfits += make_outfit_entries("Jobs", typesof(/datum/outfit/job))
		cached_outfits += make_outfit_entries("Plasmamen Outfits", typesof(/datum/outfit/plasmaman))

	data["outfits"] = cached_outfits
	return data


/datum/select_equipment/proc/resolve_outfit(text)

	var/path = text2path(text)
	if(ispath(path, /datum/outfit))
		return path

	else //don't bail yet - could be a custom outfit
		var/datum/outfit/custom_outfit = locate(text)
		if(istype(custom_outfit))
			return custom_outfit


/datum/select_equipment/ui_act(action, params, datum/tgui/ui, datum/ui_state/state)
	if(..())
		return
	. = TRUE
	switch(action)
		if("preview")
			var/datum/outfit/new_outfit = resolve_outfit(params["path"])

			if(ispath(new_outfit)) //got a typepath - that means we're dealing with a normal outfit
				selected_identifier = new_outfit //these are keyed by type
				//by the way, no, they can't be keyed by name because many of them have duplicate names

			else if(istype(new_outfit)) //got an initialized object - means it's a custom outfit
				selected_identifier = REF(new_outfit) //and the outfit will be keyed by its ref (cause its type will always be /datum/outfit)

			else //we got nothing and should bail
				return

			selected_outfit = new_outfit

		if("applyoutfit")
			var/datum/outfit/new_outfit = resolve_outfit(params["path"])
			if(new_outfit && ispath(new_outfit)) //initialize it
				new_outfit = new new_outfit
			if(!istype(new_outfit))
				return
			user.admin_apply_outfit(target_mob, new_outfit)

		if("customoutfit")
			return SSadmin_verbs.dynamic_invoke_verb(ui.user, /datum/admin_verb/outfit_manager)

		if("togglefavorite")
			var/datum/outfit/outfit_path = resolve_outfit(params["path"])
			if(!ispath(outfit_path)) //we do *not* want custom outfits (i.e objects) here, they're not even persistent
				return

			if(user.prefs.favorite_outfits.Find(outfit_path)) //already there, remove it
				user.prefs.favorite_outfits -= outfit_path
			else //not there, add it
				user.prefs.favorite_outfits += outfit_path
			user.prefs.save_preferences()

/client/proc/admin_apply_outfit(mob/target, dresscode)
	if(!ishuman(target) && !isobserver(target))
		tgui_alert(usr,"Invalid mob")
		return

	if(!dresscode)
		return

	var/delete_pocket
	var/mob/living/carbon/human/human_target
	if(isobserver(target))
		human_target = target.change_mob_type(/mob/living/carbon/human, delete_old_mob = TRUE)
	else
		human_target = target
		if(human_target.l_store || human_target.r_store || human_target.s_store) //saves a lot of time for admins and coders alike
			if(tgui_alert(usr,"Do you need the items in your pockets?", "Pocket Items", list("Delete Them", "Drop Them")) == "Delete Them")
				delete_pocket = TRUE

	BLACKBOX_LOG_ADMIN_VERB("Select Equipment")
	var/includes_flags = delete_pocket ? INCLUDE_POCKETS : NONE
	for(var/obj/item/item in human_target.get_equipped_items(includes_flags))
		qdel(item)

	var/obj/item/organ/brain/human_brain = human_target.get_organ_slot(BRAIN)
	human_brain.destroy_all_skillchips() // get rid of skillchips to prevent runtimes

	if(dresscode != "Naked")
		human_target.equipOutfit(dresscode)

	human_target.regenerate_icons()

	log_admin("[key_name(usr)] changed the equipment of [key_name(human_target)] to [dresscode].")
	message_admins(span_adminnotice("[key_name_admin(usr)] changed the equipment of [ADMIN_LOOKUPFLW(human_target)] to [dresscode]."))

	return dresscode
