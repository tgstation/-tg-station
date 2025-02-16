/// Admin adventure manager
/datum/adventure_browser
	var/datum/adventure/temp_adventure
	var/feedback_message

/datum/adventure_browser/ui_interact(mob/user, datum/tgui/ui)
	. = ..()
	ui = SStgui.try_update_ui(user, src, ui)
	if(!ui)
		ui = new(user, src, "AdventureBrowser")
		ui.open()

/datum/adventure_browser/ui_state(mob/user)
	return ADMIN_STATE(R_DEBUG)

/// Handles finishing adventure
/datum/adventure_browser/proc/resolve_adventure(datum/source,result)
	SIGNAL_HANDLER
	feedback_message = "Adventure ended with result : [result]"
	QDEL_NULL(temp_adventure)

/datum/adventure_browser/ui_act(action, list/params, datum/tgui/ui, datum/ui_state/state)
	. = ..()
	if(.)
		return
	feedback_message = ""
	switch(action)
		if("play")
			var/datum/adventure_db_entry/target = locate(params["ref"]) in GLOB.explorer_drone_adventure_db_entries
			if(!target)
				return
			if(temp_adventure)
				QDEL_NULL(temp_adventure)
			temp_adventure = target.create_adventure()
			if(!temp_adventure)
				feedback_message = "Instantiating adventure failed. Check runtime logs for details."
				return TRUE
			RegisterSignal(temp_adventure,COMSIG_ADVENTURE_FINISHED, PROC_REF(resolve_adventure))
			temp_adventure.start_adventure()
			feedback_message = "Adventure started"
			return TRUE
		if("adventure_choice")
			temp_adventure?.select_choice(params["choice"])
			return TRUE
		if("end_play")
			if(temp_adventure)
				QDEL_NULL(temp_adventure)
			feedback_message = "Adventure stopped"
			return TRUE

/datum/adventure_browser/ui_data(mob/user)
	. = ..()
	var/list/adventure_data = list()
	for(var/datum/adventure_db_entry/db_entry in GLOB.explorer_drone_adventure_db_entries)
		adventure_data += list(list(
			"ref" = ref(db_entry),
			"filename" = db_entry.filename,
			"name" = db_entry.name,
			"version" = db_entry.version,
			"uploader" = db_entry.uploader,
			"approved" = db_entry.approved,
			"json_status" = db_entry.raw_json ? "Valid JSON" : "Empty"
		))
	.["adventures"] = adventure_data
	.["feedback_message"] = feedback_message
	.["play_mode"] = !!temp_adventure
	.["adventure_data"] = temp_adventure?.ui_data(user)
	if(temp_adventure?.delayed_action)
		.["delay_time"] = temp_adventure.delayed_action[1]
		.["delay_message"] = temp_adventure.delayed_action[2]
	else
		.["delay_time"] = 0
		.["delay_message"] = ""

/datum/adventure_browser/ui_close(mob/user)
	. = ..()
	qdel(src)

/datum/adventure_browser/ui_assets(mob/user)
	return list(get_asset_datum(/datum/asset/simple/adventure))

/datum/adventure_browser/Destroy(force)
	. = ..()
	QDEL_NULL(temp_adventure)

ADMIN_VERB(adventure_manager, R_DEBUG, "Adventure Manager", "View and edit adventures.", ADMIN_CATEGORY_DEBUG)
	var/datum/adventure_browser/browser = new()
	browser.ui_interact(user.mob)
