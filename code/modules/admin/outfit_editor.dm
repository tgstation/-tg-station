
/client/proc/open_outfit_editor(datum/outfit/target)
	var/datum/outfit_editor/ui = new(usr, target)
	ui.ui_interact(usr)

#define OUTFIT_EDITOR_NAME "Outfit-O-Tron 9000"
/datum/outfit_editor
	var/client/owner

	var/dummy_key

	var/datum/outfit/drip

/datum/outfit_editor/New(user, datum/outfit/target)
	owner = CLIENT_FROM_VAR(user)

	if(ispath(target))
		drip = new /datum/outfit
		drip.copy_from(new target)
	else if(istype(target))
		drip = target
	else
		drip = new /datum/outfit
		drip.name = "New Outfit"

/datum/outfit_editor/ui_state(mob/user)
	return ADMIN_STATE(R_NONE)

/datum/outfit_editor/ui_status(mob/user, datum/ui_state/state)
	if(QDELETED(drip))
		return UI_CLOSE
	return ..()

/datum/outfit_editor/ui_close(mob/user)
	clear_human_dummy(dummy_key)
	qdel(src)

/datum/outfit_editor/proc/init_dummy()
	dummy_key = "outfit_editor_[owner]"
	generate_dummy_lookalike(dummy_key, owner.mob)
	unset_busy_human_dummy(dummy_key)

/datum/outfit_editor/ui_interact(mob/user, datum/tgui/ui)
	ui = SStgui.try_update_ui(user, src, ui)
	if(!ui)
		ui = new(user, src, "OutfitEditor", OUTFIT_EDITOR_NAME)
		ui.open()
		ui.set_autoupdate(FALSE)

/datum/outfit_editor/proc/entry(data)
	if(ispath(data, /obj/item))
		var/obj/item/item = data
		return list(
			"path" = item,
			"name" = initial(item.name),
			"desc" = initial(item.desc),
			// at this point initializing the item is probably faster tbh
			"sprite" = icon2base64(icon(initial(item.icon), initial(item.icon_state))),
		)

	return data

/datum/outfit_editor/proc/serialize_outfit()
	var/list/outfit_slots = drip.get_json_data()
	. = list()
	for(var/key in outfit_slots)
		var/val = outfit_slots[key]
		. += list("[key]" = entry(val))

/datum/outfit_editor/ui_data(mob/user)
	var/list/data = list()

	data["outfit"] = serialize_outfit()
	data["saveable"] = !GLOB.custom_outfits.Find(drip)

	if(!dummy_key)
		init_dummy()
	var/icon/dummysprite = get_flat_human_icon(null,
		dummy_key = dummy_key,
		showDirs = list(SOUTH),
		outfit_override = drip)
	data["dummy64"] = icon2base64(dummysprite)

	return data


/datum/outfit_editor/ui_act(action, list/params, datum/tgui/ui, datum/ui_state/state)
	if(..())
		return
	. = TRUE

	var/slot = params["slot"]
	switch(action)
		if("click")
			choose_item(slot)
		if("ctrlClick")
			choose_any_item(slot)
		if("clear")
			if(drip.vars.Find(slot))
				drip.vars[slot] = null

		if("rename")
			var/newname = tgui_input_text(owner, "What do you want to name this outfit?", OUTFIT_EDITOR_NAME, max_length = MAX_NAME_LEN)
			if(newname)
				drip.name = newname
		if("save")
			GLOB.custom_outfits |= drip
			SStgui.update_user_uis(owner.mob)
		if("delete")
			GLOB.custom_outfits -= drip
			SStgui.update_user_uis(owner.mob)
		if("vv")
			owner.debug_variables(drip)


/datum/outfit_editor/proc/set_item(slot, obj/item/choice)
	if(!choice)
		return
	if(!ispath(choice))
		tgui_alert(owner, "Invalid item", OUTFIT_EDITOR_NAME, list("oh no"))
		return
	if(initial(choice.icon_state) == null) //hacky check copied from experimentor code
		var/msg = "Warning: This item's icon_state is null, indicating it is very probably not actually a usable item."
		if(tgui_alert(owner, msg, OUTFIT_EDITOR_NAME, list("Use it anyway", "Cancel")) != "Use it anyway")
			return

	if(drip.vars.Find(slot))
		drip.vars[slot] = choice

/datum/outfit_editor/proc/choose_any_item(slot)
	var/obj/item/choice = pick_closest_path(FALSE)

	if(!choice)
		return

	set_item(slot, choice)

//this proc will try to give a good selection of items that the user can choose from
//it does *not* give a selection of all items that can fit in a slot because lag;
//most notably the hand and pocket slots because they accept pretty much anything
//also stuff that fits in the belt and back slots are scattered pretty much all over the place
/datum/outfit_editor/proc/choose_item(slot)
	var/list/options = list()

	switch(slot)
		if("head")
			options = typesof(/obj/item/clothing/head)
		if("glasses")
			options = typesof(/obj/item/clothing/glasses)
		if("ears")
			options = typesof(/obj/item/radio/headset)

		if("neck")
			options = typesof(/obj/item/clothing/neck)
		if("mask")
			options = typesof(/obj/item/clothing/mask)

		if("uniform")
			options = typesof(/obj/item/clothing/under)
		if("suit")
			options = typesof(/obj/item/clothing/suit)
		if("gloves")
			options = typesof(/obj/item/clothing/gloves)

		if("suit_store")
			var/obj/item/clothing/suit/suit = drip.suit
			if(suit)
				suit = new suit //initial() doesn't like lists
				options = suit.allowed
			if(!length(options)) //nothing will happen, but don't let the user think it's broken
				to_chat(owner, span_warning("No options available for the current suit."))

		if("belt")
			options = typesof(/obj/item/storage/belt)
		if("id")
			options = typesof(/obj/item/card/id)

		if("l_hand")
			choose_any_item(slot)
		if("back")
			options = typesof(/obj/item/storage/backpack)
			for(var/obj/item/mod/control/pre_equipped/potential_mod as anything in subtypesof(/obj/item/mod/control/pre_equipped))
				if(!(initial(potential_mod.slot_flags) == ITEM_SLOT_BACK))
					continue
				options |= potential_mod
		if("r_hand")
			choose_any_item(slot)

		if("l_pocket")
			choose_any_item(slot)
		if("shoes")
			options = typesof(/obj/item/clothing/shoes)
		if("r_pocket")
			choose_any_item(slot)

	if(!length(options))
		return
	var/option = tgui_input_list(owner, "Choose an item", OUTFIT_EDITOR_NAME, options)
	if(isnull(option))
		return
	set_item(slot, option)


#undef OUTFIT_EDITOR_NAME
