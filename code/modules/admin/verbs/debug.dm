ADMIN_VERB(toggle_game_debug, R_DEBUG, "Debug-Game", "Toggles game debugging.", ADMIN_CATEGORY_DEBUG)
	GLOB.Debug2 = !GLOB.Debug2
	var/message = "toggled debugging [(GLOB.Debug2 ? "ON" : "OFF")]"
	message_admins("[key_name_admin(user)] [message].")
	log_admin("[key_name(user)] [message].")
	BLACKBOX_LOG_ADMIN_VERB("Toggle Debug Two")

ADMIN_VERB_VISIBILITY(air_status, ADMIN_VERB_VISIBLITY_FLAG_MAPPING_DEBUG)
ADMIN_VERB(air_status, R_DEBUG, "Air Status In Location", "Gets the air status for your current turf.", ADMIN_CATEGORY_DEBUG)
	var/turf/user_turf = get_turf(user.mob)
	if(!isturf(user_turf))
		return
	atmos_scan(user.mob, user_turf, silent = TRUE)
	BLACKBOX_LOG_ADMIN_VERB("Air Status In Location")

ADMIN_VERB(cmd_admin_robotize, R_FUN, "Make Cyborg", ADMIN_VERB_NO_DESCRIPTION, ADMIN_CATEGORY_HIDDEN, mob/target)
	if(!SSticker.HasRoundStarted())
		tgui_alert(user, "Wait until the game starts")
		return
	if(issilicon(target))
		tgui_alert(user, "They are already a cyborg.")
		return
	log_admin("[key_name(user)] has robotized [target.key].")
	INVOKE_ASYNC(target, TYPE_PROC_REF(/mob, Robotize))

/client/proc/poll_type_to_del(search_string)
	var/list/types = get_fancy_list_of_atom_types()
	if (!isnull(search_string) && search_string != "")
		types = filter_fancy_list(types, search_string)

	if(!length(types))
		return

	var/key = input(usr, "Choose an object to delete.", "Delete:") as null|anything in sort_list(types)

	if(!key)
		return
	return types[key]

ADMIN_VERB(cmd_del_all, R_DEBUG|R_SPAWN, "Del-All", "Delete all datums with the specified type.", ADMIN_CATEGORY_DEBUG, object as text)
	var/type_to_del = user.poll_type_to_del(object)
	if(!type_to_del)
		return

	var/counter = 0
	for(var/atom/O in world)
		if(istype(O, type_to_del))
			counter++
			qdel(O)
		CHECK_TICK
	log_admin("[key_name(user)] has deleted all ([counter]) instances of [type_to_del].")
	message_admins("[key_name_admin(user)] has deleted all ([counter]) instances of [type_to_del].")
	BLACKBOX_LOG_ADMIN_VERB("Delete All")

ADMIN_VERB(cmd_del_all_force, R_DEBUG|R_SPAWN, "Force-Del-All", "Forcibly delete all datums with the specified type.", ADMIN_CATEGORY_DEBUG, object as text)
	var/type_to_del = user.poll_type_to_del(object)
	if(!type_to_del)
		return

	var/counter = 0
	for(var/atom/O in world)
		if(istype(O, type_to_del))
			counter++
			qdel(O, force = TRUE)
		CHECK_TICK
	log_admin("[key_name(user)] has force-deleted all ([counter]) instances of [type_to_del].")
	message_admins("[key_name_admin(user)] has force-deleted all ([counter]) instances of [type_to_del].")
	BLACKBOX_LOG_ADMIN_VERB("Force-Delete All")

ADMIN_VERB(cmd_del_all_hard, R_DEBUG|R_SPAWN, "Hard-Del-All", "Hard delete all datums with the specified type.", ADMIN_CATEGORY_DEBUG, object as text)
	var/type_to_del = user.poll_type_to_del(object)
	if(!type_to_del)
		return

	var/choice = alert(user, "ARE YOU SURE that you want to hard delete this type? It will cause MASSIVE lag.", "Hoooo lad what happen?", "Yes", "No")
	if(choice != "Yes")
		return

	choice = alert(user, "Do you want to pre qdelete the atom? This will speed things up significantly, but may break depending on your level of fuckup.", "How do you even get it that bad", "Yes", "No")
	var/should_pre_qdel = TRUE
	if(choice == "No")
		should_pre_qdel = FALSE

	choice = alert(user, "Ok one last thing, do you want to yield to the game? or do it all at once. These are hard deletes remember.", "Jesus christ man", "Yield", "Ignore the server")
	var/should_check_tick = TRUE
	if(choice == "Ignore the server")
		should_check_tick = FALSE

	var/counter = 0
	if(should_check_tick)
		for(var/atom/O in world)
			if(istype(O, type_to_del))
				counter++
				if(should_pre_qdel)
					qdel(O)
				del(O)
			CHECK_TICK
	else
		for(var/atom/O in world)
			if(istype(O, type_to_del))
				counter++
				if(should_pre_qdel)
					qdel(O)
				del(O)
			CHECK_TICK
	log_admin("[key_name(user)] has hard deleted all ([counter]) instances of [type_to_del].")
	message_admins("[key_name_admin(user)] has hard deleted all ([counter]) instances of [type_to_del].")
	BLACKBOX_LOG_ADMIN_VERB("Hard Delete All")

ADMIN_VERB(cmd_debug_make_powernets, R_DEBUG|R_SERVER, "Make Powernets", "Regenerates all powernets for all cables.", ADMIN_CATEGORY_DEBUG)
	SSmachines.makepowernets()
	log_admin("[key_name(user)] has remade the powernet. makepowernets() called.")
	message_admins("[key_name_admin(user)] has remade the powernets. makepowernets() called.")
	BLACKBOX_LOG_ADMIN_VERB("Make Powernets")

ADMIN_VERB_VISIBILITY(cmd_admin_grantfullaccess, ADMIN_VERB_VISIBLITY_FLAG_MAPPING_DEBUG)
ADMIN_VERB(cmd_admin_grantfullaccess, R_DEBUG, "Grant Full Access", "Grant full access to a mob.", ADMIN_CATEGORY_DEBUG, mob/M in world)
	if(!SSticker.HasRoundStarted())
		tgui_alert(user, "Wait until the game starts")
		return
	if(ishuman(M))
		var/mob/living/carbon/human/H = M
		var/obj/item/worn = H.wear_id
		var/obj/item/card/id/id = null

		if(worn)
			id = worn.GetID()
		if(id)
			if(id == worn)
				worn = null
			qdel(id)

		id = new /obj/item/card/id/advanced/debug()

		id.registered_name = H.real_name
		id.update_label()
		id.update_icon()

		if(worn)
			if(istype(worn, /obj/item/modular_computer))
				var/obj/item/modular_computer/worn_computer = worn
				worn_computer.InsertID(id, H)

			else if(istype(worn, /obj/item/storage/wallet))
				var/obj/item/storage/wallet/W = worn
				W.front_id = id
				id.forceMove(W)
				W.update_icon()
		else
			H.equip_to_slot(id, ITEM_SLOT_ID)

	else
		tgui_alert(user,"Invalid mob")
	BLACKBOX_LOG_ADMIN_VERB("Grant Full Access")
	log_admin("[key_name(user)] has granted [M.key] full access.")
	message_admins(span_adminnotice("[key_name_admin(user)] has granted [M.key] full access."))

ADMIN_VERB(cmd_assume_direct_control, R_ADMIN, "Assume Direct Control", "Assume direct control of a mob.", ADMIN_CATEGORY_DEBUG, mob/M)
	if(M.ckey)
		if(tgui_alert(user,"This mob is being controlled by [M.key]. Are you sure you wish to assume control of it? [M.key] will be made a ghost.",,list("Yes","No")) != "Yes")
			return
	if(!M || QDELETED(M))
		to_chat(user, span_warning("The target mob no longer exists."))
		return
	message_admins(span_adminnotice("[key_name_admin(user)] assumed direct control of [M]."))
	log_admin("[key_name(user)] assumed direct control of [M].")
	var/mob/adminmob = user.mob
	if(M.ckey)
		M.ghostize(FALSE)

	M.PossessByPlayer(user.key)

	user.init_verbs()
	if(isobserver(adminmob))
		qdel(adminmob)
	BLACKBOX_LOG_ADMIN_VERB("Assume Direct Control")

ADMIN_VERB(cmd_give_direct_control, R_ADMIN, "Give Direct Control", "Give direct control of a mob to another player.", ADMIN_CATEGORY_GAME, mob/M)
	if(!M)
		return
	if(M.ckey)
		if(tgui_alert(user,"This mob is being controlled by [M.key]. Are you sure you wish to give someone else control of it? [M.key] will be made a ghost.",,list("Yes","No")) != "Yes")
			return
	var/client/newkey = input(user, "Pick the player to put in control.", "New player") as null|anything in sort_list(GLOB.clients)
	if(isnull(newkey))
		return
	var/mob/oldmob = newkey.mob
	var/delmob = FALSE
	if((isobserver(oldmob) || tgui_alert(user,"Do you want to delete [newkey]'s old mob?","Delete?",list("Yes","No")) != "No"))
		delmob = TRUE
	if(!M || QDELETED(M))
		to_chat(user, span_warning("The target mob no longer exists, aborting."))
		return
	if(M.ckey)
		M.ghostize(FALSE)
	M.ckey = newkey.key
	M.client?.init_verbs()
	if(delmob)
		qdel(oldmob)
	message_admins(span_adminnotice("[key_name_admin(user)] gave away direct control of [M] to [newkey]."))
	log_admin("[key_name(user)] gave away direct control of [M] to [newkey].")
	BLACKBOX_LOG_ADMIN_VERB("Give Direct Control")

ADMIN_VERB_VISIBILITY(cmd_admin_areatest, ADMIN_VERB_VISIBLITY_FLAG_MAPPING_DEBUG)
ADMIN_VERB(cmd_admin_areatest, R_DEBUG, "Test Areas", "Tests the areas for various machinery.", ADMIN_CATEGORY_MAPPING, on_station as num, filter_maint as num)
	var/list/dat = list()
	var/list/areas_all = list()
	var/list/areas_with_APC = list()
	var/list/areas_with_multiple_APCs = list()
	var/list/areas_with_air_alarm = list()
	var/list/areas_with_RC = list()
	var/list/areas_with_light = list()
	var/list/areas_with_LS = list()
	var/list/areas_with_intercom = list()
	var/list/areas_with_camera = list()
	/**We whitelist in case we're doing something on a planetary station that shares multiple different types of areas, this should only be full of "station" area types.
	This only goes into effect when we explicitly do the "on station" Areas Test.
	*/
	var/static/list/station_areas_whitelist = typecacheof(list(
		/area/station,
	))
	///Additionally, blacklist in order to filter out the types of areas that can show up on station Z-levels that we never need to test for.
	var/static/list/station_areas_blacklist = typecacheof(list(
		/area/centcom/asteroid,
		/area/mine,
		/area/ruin,
		/area/shuttle,
		/area/space,
		/area/station/engineering/supermatter,
		/area/station/holodeck/rec_center,
		/area/station/science/ordnance/bomb,
		/area/station/solars,
	))

	if(SSticker.current_state == GAME_STATE_STARTUP)
		to_chat(user, "Game still loading, please hold!", confidential = TRUE)
		return

	var/log_message
	if(on_station)
		dat += "<b>Only checking areas on station z-levels.</b><br><br>"
		log_message = "station z-levels"
	else
		log_message = "all z-levels"
	if(filter_maint)
		dat += "<b>Maintenance Areas Filtered Out</b>"
		log_message += ", with no maintenance areas"

	message_admins(span_adminnotice("[key_name_admin(user)] used the Test Areas debug command checking [log_message]."))
	log_admin("[key_name(user)] used the Test Areas debug command checking [log_message].")

	for(var/area/A as anything in GLOB.areas)
		if(on_station)
			var/list/area_turfs = get_area_turfs(A.type)
			if (!length(area_turfs))
				continue
			var/turf/picked = pick(area_turfs)
			if(is_station_level(picked.z))
				if(!(A.type in areas_all) && !is_type_in_typecache(A, station_areas_blacklist) && is_type_in_typecache(A, station_areas_whitelist))
					if(filter_maint && istype(A, /area/station/maintenance))
						continue
					areas_all.Add(A.type)
		else if(!(A.type in areas_all))
			areas_all.Add(A.type)
		CHECK_TICK

	for(var/obj/machinery/power/apc/APC as anything in SSmachines.get_machines_by_type_and_subtypes(/obj/machinery/power/apc))
		var/area/A = APC.area
		if(!A)
			dat += "Skipped over [APC] in invalid location, [APC.loc]."
			continue
		if(!(A.type in areas_with_APC))
			areas_with_APC.Add(A.type)
		else if(A.type in areas_all)
			areas_with_multiple_APCs.Add(A.type)
		CHECK_TICK

	for(var/obj/machinery/airalarm/AA in GLOB.air_alarms)
		var/area/A = get_area(AA)
		if(!A) //Make sure the target isn't inside an object, which results in runtimes.
			dat += "Skipped over [AA] in invalid location, [AA.loc].<br>"
			continue
		if(!(A.type in areas_with_air_alarm))
			areas_with_air_alarm.Add(A.type)
		CHECK_TICK

	for(var/obj/machinery/requests_console/RC in GLOB.req_console_all)
		var/area/A = get_area(RC)
		if(!A)
			dat += "Skipped over [RC] in invalid location, [RC.loc].<br>"
			continue
		if(!(A.type in areas_with_RC))
			areas_with_RC.Add(A.type)
		CHECK_TICK

	for(var/obj/machinery/light/L as anything in SSmachines.get_machines_by_type_and_subtypes(/obj/machinery/light))
		var/area/A = get_area(L)
		if(!A)
			dat += "Skipped over [L] in invalid location, [L.loc].<br>"
			continue
		if(!(A.type in areas_with_light))
			areas_with_light.Add(A.type)
		CHECK_TICK

	for(var/obj/machinery/light_switch/LS as anything in SSmachines.get_machines_by_type_and_subtypes(/obj/machinery/light_switch))
		var/area/A = get_area(LS)
		if(!A)
			dat += "Skipped over [LS] in invalid location, [LS.loc].<br>"
			continue
		if(!(A.type in areas_with_LS))
			areas_with_LS.Add(A.type)
		CHECK_TICK

	for(var/obj/item/radio/intercom/I as anything in GLOB.intercoms_list)
		var/area/A = get_area(I)
		if(!A)
			dat += "Skipped over [I] in invalid location, [I.loc].<br>"
			continue
		if(!(A.type in areas_with_intercom))
			areas_with_intercom.Add(A.type)
		CHECK_TICK

	for(var/obj/machinery/camera/C as anything in GLOB.cameranet.cameras)
		var/area/A = get_area(C)
		if(!A)
			dat += "Skipped over [C] in invalid location, [C.loc].<br>"
			continue
		if(!(A.type in areas_with_camera))
			areas_with_camera.Add(A.type)
		CHECK_TICK

	var/list/areas_without_APC = areas_all - areas_with_APC
	var/list/areas_without_air_alarm = areas_all - areas_with_air_alarm
	var/list/areas_without_RC = areas_all - areas_with_RC
	var/list/areas_without_light = areas_all - areas_with_light
	var/list/areas_without_LS = areas_all - areas_with_LS
	var/list/areas_without_intercom = areas_all - areas_with_intercom
	var/list/areas_without_camera = areas_all - areas_with_camera

	if(areas_without_APC.len)
		dat += "<h1>AREAS WITHOUT AN APC:</h1>"
		for(var/areatype in areas_without_APC)
			dat += "[areatype]<br>"
			CHECK_TICK

	if(areas_with_multiple_APCs.len)
		dat += "<h1>AREAS WITH MULTIPLE APCS:</h1>"
		for(var/areatype in areas_with_multiple_APCs)
			dat += "[areatype]<br>"
			CHECK_TICK

	if(areas_without_air_alarm.len)
		dat += "<h1>AREAS WITHOUT AN AIR ALARM:</h1>"
		for(var/areatype in areas_without_air_alarm)
			dat += "[areatype]<br>"
			CHECK_TICK

	if(areas_without_RC.len)
		dat += "<h1>AREAS WITHOUT A REQUEST CONSOLE:</h1>"
		for(var/areatype in areas_without_RC)
			dat += "[areatype]<br>"
			CHECK_TICK

	if(areas_without_light.len)
		dat += "<h1>AREAS WITHOUT ANY LIGHTS:</h1>"
		for(var/areatype in areas_without_light)
			dat += "[areatype]<br>"
			CHECK_TICK

	if(areas_without_LS.len)
		dat += "<h1>AREAS WITHOUT A LIGHT SWITCH:</h1>"
		for(var/areatype in areas_without_LS)
			dat += "[areatype]<br>"
			CHECK_TICK

	if(areas_without_intercom.len)
		dat += "<h1>AREAS WITHOUT ANY INTERCOMS:</h1>"
		for(var/areatype in areas_without_intercom)
			dat += "[areatype]<br>"
			CHECK_TICK

	if(areas_without_camera.len)
		dat += "<h1>AREAS WITHOUT ANY CAMERAS:</h1>"
		for(var/areatype in areas_without_camera)
			dat += "[areatype]<br>"
			CHECK_TICK

	if(!(areas_with_APC.len || areas_with_multiple_APCs.len || areas_with_air_alarm.len || areas_with_RC.len || areas_with_light.len || areas_with_LS.len || areas_with_intercom.len || areas_with_camera.len))
		dat += "<b>No problem areas!</b>"

	var/datum/browser/popup = new(user.mob, "testareas", "Test Areas", 500, 750)
	popup.set_content(dat.Join())
	popup.open()

ADMIN_VERB_VISIBILITY(cmd_admin_areatest_station, ADMIN_VERB_VISIBLITY_FLAG_MAPPING_DEBUG)
ADMIN_VERB(cmd_admin_areatest_station, R_DEBUG, "Test Areas (STATION ONLY)", "Tests the areas for various machinery on station z-levels.", ADMIN_CATEGORY_MAPPING)
	SSadmin_verbs.dynamic_invoke_verb(user, /datum/admin_verb/cmd_admin_areatest, /* on_station = */ TRUE)

ADMIN_VERB_VISIBILITY(cmd_admin_areatest_station_no_maintenance, ADMIN_VERB_VISIBLITY_FLAG_MAPPING_DEBUG)
ADMIN_VERB(cmd_admin_areatest_station_no_maintenance, R_DEBUG, "Test Areas (STATION - NO MAINT)", "Tests the areas for various machinery on station z-levels, excluding maintenance areas.", ADMIN_CATEGORY_MAPPING)
	SSadmin_verbs.dynamic_invoke_verb(user, /datum/admin_verb/cmd_admin_areatest, /* on_station = */ TRUE, /* filter_maint = */ TRUE)

ADMIN_VERB_VISIBILITY(cmd_admin_areatest_all, ADMIN_VERB_VISIBLITY_FLAG_MAPPING_DEBUG)
ADMIN_VERB(cmd_admin_areatest_all, R_DEBUG, "Test Areas (ALL)", "Tests the areas for various machinery on all z-levels.", ADMIN_CATEGORY_MAPPING)
	SSadmin_verbs.dynamic_invoke_verb(user, /datum/admin_verb/cmd_admin_areatest)

/client/proc/robust_dress_shop()
	var/list/baseoutfits = list("Naked","Custom","As Job...", "As Plasmaman...")
	var/list/outfits = list()
	var/list/paths = subtypesof(/datum/outfit) - typesof(/datum/outfit/job) - typesof(/datum/outfit/plasmaman)

	for(var/path in paths)
		var/datum/outfit/O = path //not much to initalize here but whatever
		outfits[initial(O.name)] = path

	var/dresscode = input("Select outfit", "Robust quick dress shop") as null|anything in baseoutfits + sort_list(outfits)
	if (isnull(dresscode))
		return

	if (outfits[dresscode])
		dresscode = outfits[dresscode]

	if (dresscode == "As Job...")
		var/list/job_paths = subtypesof(/datum/outfit/job)
		var/list/job_outfits = list()
		for(var/path in job_paths)
			var/datum/outfit/O = path
			job_outfits[initial(O.name)] = path

		dresscode = input("Select job equipment", "Robust quick dress shop") as null|anything in sort_list(job_outfits)
		dresscode = job_outfits[dresscode]
		if(isnull(dresscode))
			return

	if (dresscode == "As Plasmaman...")
		var/list/plasmaman_paths = typesof(/datum/outfit/plasmaman)
		var/list/plasmaman_outfits = list()
		for(var/path in plasmaman_paths)
			var/datum/outfit/O = path
			plasmaman_outfits[initial(O.name)] = path

		dresscode = input("Select plasmeme equipment", "Robust quick dress shop") as null|anything in sort_list(plasmaman_outfits)
		dresscode = plasmaman_outfits[dresscode]
		if(isnull(dresscode))
			return

	if (dresscode == "Custom")
		var/list/custom_names = list()
		for(var/datum/outfit/D in GLOB.custom_outfits)
			custom_names[D.name] = D
		var/selected_name = input("Select outfit", "Robust quick dress shop") as null|anything in sort_list(custom_names)
		dresscode = custom_names[selected_name]
		if(isnull(dresscode))
			return

	return dresscode

ADMIN_VERB_ONLY_CONTEXT_MENU(cmd_admin_rejuvenate, R_ADMIN, "Rejuvenate", mob/living/M in world)
	if(!istype(M))
		tgui_alert(user,"Cannot revive a ghost")
		return
	M.revive(ADMIN_HEAL_ALL)

	log_admin("[key_name(user)] healed / revived [key_name(M)]")
	var/msg = span_danger("Admin [key_name_admin(user)] healed / revived [ADMIN_LOOKUPFLW(M)]!")
	message_admins(msg)
	admin_ticket_log(M, msg)
	BLACKBOX_LOG_ADMIN_VERB("Rejuvenate")

ADMIN_VERB_AND_CONTEXT_MENU(cmd_admin_delete, R_DEBUG|R_SPAWN, "Delete", ADMIN_VERB_NO_DESCRIPTION, ADMIN_CATEGORY_HIDDEN, atom/target as obj|mob|turf in world)
	user.admin_delete(target)

ADMIN_VERB_AND_CONTEXT_MENU(cmd_check_contents, R_ADMIN, "Check Contents", ADMIN_VERB_NO_DESCRIPTION, ADMIN_CATEGORY_HIDDEN, mob/living/mob)
	var/list/mob_contents = mob.get_contents()
	for(var/content in mob_contents)
		to_chat(user, "[content] [ADMIN_VV(content)] [ADMIN_TAG(content)]", confidential = TRUE)
	BLACKBOX_LOG_ADMIN_VERB("Check Contents")

ADMIN_VERB(modify_goals, R_ADMIN, "Modify Goals", "Modify the station goals for the shift.", ADMIN_CATEGORY_DEBUG)
	user.holder.modify_goals()

/datum/admins/proc/modify_goals()
	var/dat = ""
	for(var/datum/station_goal/goal as anything in SSstation.get_station_goals())
		dat += "[goal.name] - <a href='byond://?src=[REF(goal)];[HrefToken()];announce=1'>Announce</a> | <a href='byond://?src=[REF(goal)];[HrefToken()];remove=1'>Remove</a><br>"
	dat += "<br><a href='byond://?src=[REF(src)];[HrefToken()];add_station_goal=1'>Add New Goal</a>"
	var/datum/browser/browser = new(usr, "goals", "Modify Goals", 400, 400)
	browser.set_content(dat)
	browser.open()

ADMIN_VERB(debug_mob_lists, R_DEBUG, "Debug Mob Lists", "For when you just gotta know.", ADMIN_CATEGORY_DEBUG)
	var/chosen_list = tgui_input_list(user, "Which list?", "Select List", list("Players","Admins","Mobs","Living Mobs","Dead Mobs","Clients","Joined Clients"))
	if(isnull(chosen_list))
		return
	switch(chosen_list)
		if("Players")
			to_chat(user, jointext(GLOB.player_list,","), confidential = TRUE)
		if("Admins")
			to_chat(user, jointext(GLOB.admins,","), confidential = TRUE)
		if("Mobs")
			to_chat(user, jointext(GLOB.mob_list,","), confidential = TRUE)
		if("Living Mobs")
			to_chat(user, jointext(GLOB.alive_mob_list,","), confidential = TRUE)
		if("Dead Mobs")
			to_chat(user, jointext(GLOB.dead_mob_list,","), confidential = TRUE)
		if("Clients")
			to_chat(user, jointext(GLOB.clients,","), confidential = TRUE)
		if("Joined Clients")
			to_chat(user, jointext(GLOB.joined_player_list,","), confidential = TRUE)

ADMIN_VERB(del_log, R_DEBUG, "Display del() Log", "Display del's log of everything that's passed through it.", ADMIN_CATEGORY_DEBUG)
	var/list/dellog = list("<B>List of things that have gone through qdel this round</B><BR><BR><ol>")
	sortTim(SSgarbage.items, cmp=/proc/cmp_qdel_item_time, associative = TRUE)
	for(var/path in SSgarbage.items)
		var/datum/qdel_item/I = SSgarbage.items[path]
		dellog += "<li><u>[path]</u><ul>"
		if (I.qdel_flags & QDEL_ITEM_SUSPENDED_FOR_LAG)
			dellog += "<li>SUSPENDED FOR LAG</li>"
		if (I.failures)
			dellog += "<li>Failures: [I.failures]</li>"
		dellog += "<li>qdel() Count: [I.qdels]</li>"
		dellog += "<li>Destroy() Cost: [I.destroy_time]ms</li>"
		if (I.hard_deletes)
			dellog += "<li>Total Hard Deletes [I.hard_deletes]</li>"
			dellog += "<li>Time Spent Hard Deleting: [I.hard_delete_time]ms</li>"
			dellog += "<li>Highest Time Spent Hard Deleting: [I.hard_delete_max]ms</li>"
			if (I.hard_deletes_over_threshold)
				dellog += "<li>Hard Deletes Over Threshold: [I.hard_deletes_over_threshold]</li>"
		if (I.slept_destroy)
			dellog += "<li>Sleeps: [I.slept_destroy]</li>"
		if (I.no_respect_force)
			dellog += "<li>Ignored force: [I.no_respect_force]</li>"
		if (I.no_hint)
			dellog += "<li>No hint: [I.no_hint]</li>"
		if(LAZYLEN(I.extra_details))
			var/details = I.extra_details.Join("</li><li>")
			dellog += "<li>Extra Info: <ul><li>[details]</li></ul>"
		dellog += "</ul></li>"

	dellog += "</ol>"

	var/datum/browser/browser = new(usr, "dellog", "Del Log", 00, 400)
	browser.set_content(dellog.Join())
	browser.open()

ADMIN_VERB(display_overlay_log, R_DEBUG, "Display Overlay Log", "Display SSoverlays log of everything that's passed through it.", ADMIN_CATEGORY_DEBUG)
	render_stats(SSoverlays.stats, user)

ADMIN_VERB(init_log, R_DEBUG, "Display Initialize() Log", "Displays a list of things that didn't handle Initialize() properly.", ADMIN_CATEGORY_DEBUG)
	var/datum/browser/browser = new(user, "initlog", "Initialize Log", 500, 500)
	browser.set_content(replacetext(SSatoms.InitLog(), "\n", "<br>"))
	browser.open()

ADMIN_VERB(debug_color_test, R_DEBUG, "Colorblind Testing", "Change your view to a budget version of colorblindness to test for usability.", ADMIN_CATEGORY_DEBUG)
	user.holder.color_test.ui_interact(user.mob)

ADMIN_VERB(debug_plane_masters, R_DEBUG, "Edit/Debug Planes", "Edit and visualize plane masters and their connections (relays).", ADMIN_CATEGORY_DEBUG)
	user.edit_plane_masters()

/client/proc/edit_plane_masters(mob/debug_on)
	if(!holder)
		return
	if(debug_on)
		holder.plane_debug.set_mirroring(TRUE)
		holder.plane_debug.set_target(debug_on)
	else
		holder.plane_debug.set_mirroring(FALSE)
	holder.plane_debug.ui_interact(mob)

ADMIN_VERB(debug_huds, R_DEBUG, "Debug HUDs", "Debug the data or antag HUDs.", ADMIN_CATEGORY_DEBUG, i as num)
	SSadmin_verbs.dynamic_invoke_verb(user, /datum/admin_verb/debug_variables, GLOB.huds[i])

ADMIN_VERB(jump_to_ruin, R_DEBUG, "Jump to Ruin", "Displays a list of all placed ruins to teleport to.", ADMIN_CATEGORY_DEBUG)
	var/list/names = list()
	for(var/obj/effect/landmark/ruin/ruin_landmark as anything in GLOB.ruin_landmarks)
		var/datum/map_template/ruin/template = ruin_landmark.ruin_template

		var/count = 1
		var/name = template.name
		var/original_name = name

		while(name in names)
			count++
			name = "[original_name] ([count])"

		names[name] = ruin_landmark

	var/ruinname = tgui_input_list(user, "Select ruin", "Jump to Ruin", sort_list(names))
	var/obj/effect/landmark/ruin/landmark = names[ruinname]
	if(!istype(landmark))
		return
	var/datum/map_template/ruin/template = landmark.ruin_template
	user.mob.forceMove(get_turf(landmark))
	to_chat(user, span_name(template.name), confidential = TRUE)
	to_chat(user, span_italics(template.description), confidential = TRUE)

ADMIN_VERB_VISIBILITY(place_ruin, ADMIN_VERB_VISIBLITY_FLAG_MAPPING_DEBUG)
ADMIN_VERB(place_ruin, R_DEBUG, "Spawn Ruin", "Attempt to randomly place a specific ruin.", ADMIN_CATEGORY_MAPPING)
	var/list/exists = list()
	for(var/landmark in GLOB.ruin_landmarks)
		var/obj/effect/landmark/ruin/L = landmark
		exists[L.ruin_template] = landmark

	var/list/names = list()
	var/list/themed_names
	for (var/theme in SSmapping.themed_ruins)
		names += "---- [theme] ----"
		themed_names = list()
		for (var/name in SSmapping.themed_ruins[theme])
			var/datum/map_template/ruin/ruin = SSmapping.themed_ruins[theme][name]
			if(names[name])
				name = "[theme] [name]"
			themed_names[name] = list(ruin, theme, list(ruin.default_area))
		names += sort_list(themed_names)

	var/ruinname = tgui_input_list(user, "Select ruin", "Spawn Ruin", sort_list(names))
	var/data = names[ruinname]
	if (!data)
		return
	var/datum/map_template/ruin/template = data[1]
	if (exists[template])
		var/response = tgui_alert(user,"There is already a [template] in existence.", "Spawn Ruin", list("Jump", "Place Another", "Cancel"))
		if (response == "Jump")
			user.mob.forceMove(get_turf(exists[template]))
			return
		else if (response == "Cancel")
			return

	var/len = GLOB.ruin_landmarks.len
	seedRuins(SSmapping.levels_by_trait(data[2]), max(1, template.cost), data[3], list(ruinname = template))
	if (GLOB.ruin_landmarks.len > len)
		var/obj/effect/landmark/ruin/landmark = GLOB.ruin_landmarks[GLOB.ruin_landmarks.len]
		log_admin("[key_name(user)] randomly spawned ruin [ruinname] at [COORD(landmark)].")
		user.mob.forceMove(get_turf(landmark))
		to_chat(user, span_name("[template.name]"), confidential = TRUE)
		to_chat(user, span_italics("[template.description]"), confidential = TRUE)
	else
		to_chat(user, span_warning("Failed to place [template.name]."), confidential = TRUE)

ADMIN_VERB(unload_ctf, R_DEBUG, "Unload CTF", "Despawns the majority of CTF.", ADMIN_CATEGORY_DEBUG)
	toggle_id_ctf(user, CTF_GHOST_CTF_GAME_ID, unload=TRUE)

ADMIN_VERB(run_empty_query, R_DEBUG, "Run Empty Query", "Runs a specified number of empty queries.", ADMIN_CATEGORY_DEBUG, val as num)
	var/list/queries = list()
	for(var/i in 1 to val)
		var/datum/db_query/query = SSdbcore.NewQuery("NULL")
		INVOKE_ASYNC(query, TYPE_PROC_REF(/datum/db_query, Execute))
		queries += query

	for(var/datum/db_query/query as anything in queries)
		query.sync()
		qdel(query)
	queries.Cut()

	message_admins("[key_name_admin(user)] ran [val] empty queries.")

ADMIN_VERB(clear_turf_reservations, R_DEBUG, "Clear Dynamic Turf Reservations", "Deallocates all reserved space, restoring it to round start conditions.", ADMIN_CATEGORY_DEBUG)
	var/answer = tgui_alert(
		user,
		"WARNING: THIS WILL WIPE ALL RESERVED SPACE TO A CLEAN SLATE! ANY MOVING SHUTTLES, ELEVATORS, OR IN-PROGRESS PHOTOGRAPHY WILL BE DELETED!",
		"Really wipe dynamic turfs?",
		list("YES", "NO"),
	)
	if(answer != "YES")
		return
	message_admins(span_adminnotice("[key_name_admin(user)] cleared dynamic transit space."))
	BLACKBOX_LOG_ADMIN_VERB("Clear Dynamic Turf Reservations")
	log_admin("[key_name(user)] cleared dynamic turf reservations.")
	SSmapping.wipe_reservations() //this goes after it's logged, incase something horrible happens.

ADMIN_VERB(toggle_medal_disable, R_DEBUG, "Toggle Medal Disable", "Toggles the safety lock on trying to contact the medal hub.", ADMIN_CATEGORY_DEBUG)
	SSachievements.achievements_enabled = !SSachievements.achievements_enabled

	message_admins(span_adminnotice("[key_name_admin(user)] [SSachievements.achievements_enabled ? "disabled" : "enabled"] the medal hub lockout."))
	BLACKBOX_LOG_ADMIN_VERB("Toggle Medal Disable")
	log_admin("[key_name(user)] [SSachievements.achievements_enabled ? "disabled" : "enabled"] the medal hub lockout.")

ADMIN_VERB(view_runtimes, R_DEBUG, "View Runtimes", "Opens the runtime viewer.", ADMIN_CATEGORY_DEBUG)
	GLOB.error_cache.show_to(user)

	// The runtime viewer has the potential to crash the server if there's a LOT of runtimes
	// this has happened before, multiple times, so we'll just leave an alert on it
	if(GLOB.total_runtimes >= 50000) // arbitrary number, I don't know when exactly it happens
		var/warning = "There are a lot of runtimes, clicking any button (especially \"linear\") can have the potential to lag or crash the server"
		if(GLOB.total_runtimes >= 100000)
			warning = "There are a TON of runtimes, clicking any button (especially \"linear\") WILL LIKELY crash the server"
		// Not using TGUI alert, because it's view runtimes, stuff is probably broken
		alert(user, "[warning]. Proceed with caution. If you really need to see the runtimes, download the runtime log and view it in a text editor.", "HEED THIS WARNING CAREFULLY MORTAL")

ADMIN_VERB(pump_random_event, R_DEBUG, "Pump Random Event", "Schedules the event subsystem to fire a new random event immediately. Some events may fire without notification.", ADMIN_CATEGORY_DEBUG)
	SSevents.scheduled = world.time

	message_admins(span_adminnotice("[key_name_admin(user)] pumped a random event."))
	BLACKBOX_LOG_ADMIN_VERB("Pump Random Event")
	log_admin("[key_name(user)] pumped a random event.")

ADMIN_VERB_VISIBILITY(start_line_profiling, ADMIN_VERB_VISIBLITY_FLAG_MAPPING_DEBUG)
ADMIN_VERB(start_line_profiling, R_DEBUG, "Start Line Profiling", "Starts tracking line by line profiling for code lines that support it.", ADMIN_CATEGORY_PROFILE)
	LINE_PROFILE_START

	message_admins(span_adminnotice("[key_name_admin(user)] started line by line profiling."))
	BLACKBOX_LOG_ADMIN_VERB("Start Line Profiling")
	log_admin("[key_name(user)] started line by line profiling.")

ADMIN_VERB_VISIBILITY(stop_line_profiling, ADMIN_VERB_VISIBLITY_FLAG_MAPPING_DEBUG)
ADMIN_VERB(stop_line_profiling, R_DEBUG, "Stop Line Profiling", "Stops tracking line by line profiling for code lines that support it.", ADMIN_CATEGORY_PROFILE)
	LINE_PROFILE_STOP

	message_admins(span_adminnotice("[key_name_admin(user)] stopped line by line profiling."))
	BLACKBOX_LOG_ADMIN_VERB("Stop Line Profiling")
	log_admin("[key_name(user)] stopped line by line profiling.")

ADMIN_VERB_VISIBILITY(show_line_profiling, ADMIN_VERB_VISIBLITY_FLAG_MAPPING_DEBUG)
ADMIN_VERB(show_line_profiling, R_DEBUG, "Show Line Profiling", "Shows tracked profiling info from code lines that support it.", ADMIN_CATEGORY_PROFILE)
	var/list/sortlist = list(
		"Avg time" = GLOBAL_PROC_REF(cmp_profile_avg_time_dsc),
		"Total Time" = GLOBAL_PROC_REF(cmp_profile_time_dsc),
		"Call Count" = GLOBAL_PROC_REF(cmp_profile_count_dsc),
	)
	var/sort = input(user, "Sort type?", "Sort Type", "Avg time") as null|anything in sortlist
	if (!sort)
		return
	sort = sortlist[sort]
	profile_show(user, sort)

ADMIN_VERB(reload_configuration, R_DEBUG, "Reload Configuration", "Reloads the configuration from the default path on the disk, wiping any in-round modifications.", ADMIN_CATEGORY_DEBUG)
	if(tgui_alert(user, "Are you absolutely sure you want to reload the configuration from the default path on the disk, wiping any in-round modifications?", "Really reset?", list("No", "Yes")) != "Yes")
		return
	config.admin_reload()

ADMIN_VERB(check_timer_sources, R_DEBUG, "Check Timer Sources", "Checks the sources of running timers.", ADMIN_CATEGORY_DEBUG)
	var/bucket_list_output = generate_timer_source_output(SStimer.bucket_list)
	var/second_queue = generate_timer_source_output(SStimer.second_queue)

	var/datum/browser/browser = new(user, "check_timer_sources", "Timer Sources", 700, 700)
	browser.set_content({"
		<h3>bucket_list</h3>
		[bucket_list_output]

		<h3>second_queue</h3>
		[second_queue]
	"})
	browser.open()

ADMIN_VERB(reestablish_tts_connection, R_DEBUG, "Re-establish Connection To TTS", "Re-establishes connection to the TTS server if possible", ADMIN_CATEGORY_DEBUG)
	message_admins("[key_name_admin(user)] attempted to re-establish connection to the TTS HTTP server.")
	log_admin("[key_name(user)] attempted to re-establish connection to the TTS HTTP server.")
	var/success = SStts.establish_connection_to_tts()
	if(!success)
		message_admins("[key_name_admin(user)] failed to re-established the connection to the TTS HTTP server.")
		log_admin("[key_name(user)] failed to re-established the connection to the TTS HTTP server.")
		return
	message_admins("[key_name_admin(user)] successfully re-established the connection to the TTS HTTP server.")
	log_admin("[key_name(user)] successfully re-established the connection to the TTS HTTP server.")

ADMIN_VERB(allow_browser_inspect, R_DEBUG, "Allow Browser Inspect", "Allow browser debugging via inspect", ADMIN_CATEGORY_DEBUG)
	if(user.byond_version < 516)
		to_chat(user, span_warning("You can only use this on 516!"))
		return

	to_chat(user, span_notice("You can now right click to use inspect on browsers."))
	winset(user, null, list("browser-options" = "+devtools"))

/proc/generate_timer_source_output(list/datum/timedevent/events)
	var/list/per_source = list()

	// Collate all events and figure out what sources are creating the most
	for (var/_event in events)
		if (!_event)
			continue
		var/datum/timedevent/event = _event

		do
			if (event.source)
				if (per_source[event.source] == null)
					per_source[event.source] = 1
				else
					per_source[event.source] += 1
			event = event.next
		while (event && event != _event)

	// Now, sort them in order
	var/list/sorted = list()
	for (var/source in per_source)
		sorted += list(list("source" = source, "count" = per_source[source]))
	sortTim(sorted, GLOBAL_PROC_REF(cmp_timer_data))

	// Now that everything is sorted, compile them into an HTML output
	var/output = "<table border='1'>"

	for (var/_timer_data in sorted)
		var/list/timer_data = _timer_data
		output += {"<tr>
			<td><b>[timer_data["source"]]</b></td>
			<td>[timer_data["count"]]</td>
		</tr>"}

	output += "</table>"

	return output

/proc/cmp_timer_data(list/a, list/b)
	return b["count"] - a["count"]

#ifdef TESTING
ADMIN_VERB_CUSTOM_EXIST_CHECK(check_missing_sprites)
	return TRUE
#else
ADMIN_VERB_CUSTOM_EXIST_CHECK(check_missing_sprites)
	return FALSE
#endif

ADMIN_VERB(check_missing_sprites, R_DEBUG, "Debug Worn Item Sprites", "We're cancelling the Spritemageddon. (This will create a LOT of runtimes! Don't use on a live server!)", ADMIN_CATEGORY_DEBUG)
	var/actual_file_name
	for(var/test_obj in subtypesof(/obj/item))
		var/obj/item/sprite = new test_obj
		if(!sprite.slot_flags || (sprite.item_flags & ABSTRACT))
			continue
		//Is there an explicit worn_icon to pick against the worn_icon_state? Easy street expected behavior.
		if(sprite.worn_icon)
			if(!icon_exists(sprite.worn_icon, sprite.icon_state))
				to_chat(user, span_warning("ERROR sprites for [sprite.type]. Slot Flags are [sprite.slot_flags]."), confidential = TRUE)
		else if(sprite.worn_icon_state)
			if(sprite.slot_flags & ITEM_SLOT_MASK)
				actual_file_name = 'icons/mob/clothing/mask.dmi'
				if(!icon_exists(actual_file_name, sprite.worn_icon_state))
					to_chat(user, span_warning("ERROR sprites for [sprite.type]. Mask slot."), confidential = TRUE)
			if(sprite.slot_flags & ITEM_SLOT_NECK)
				actual_file_name = 'icons/mob/clothing/neck.dmi'
				if(!icon_exists(actual_file_name, sprite.worn_icon_state))
					to_chat(user, span_warning("ERROR sprites for [sprite.type]. Neck slot."), confidential = TRUE)
			if(sprite.slot_flags & ITEM_SLOT_BACK)
				actual_file_name = 'icons/mob/clothing/back.dmi'
				if(!icon_exists(actual_file_name, sprite.worn_icon_state))
					to_chat(user, span_warning("ERROR sprites for [sprite.type]. Back slot."), confidential = TRUE)
			if(sprite.slot_flags & ITEM_SLOT_HEAD)
				actual_file_name = 'icons/mob/clothing/head/default.dmi'
				if(!icon_exists(actual_file_name, sprite.worn_icon_state))
					to_chat(user, span_warning("ERROR sprites for [sprite.type]. Head slot."), confidential = TRUE)
			if(sprite.slot_flags & ITEM_SLOT_BELT)
				actual_file_name = 'icons/mob/clothing/belt.dmi'
				if(!icon_exists(actual_file_name, sprite.worn_icon_state))
					to_chat(user, span_warning("ERROR sprites for [sprite.type]. Belt slot."), confidential = TRUE)
			if(sprite.slot_flags & ITEM_SLOT_SUITSTORE)
				actual_file_name = 'icons/mob/clothing/belt_mirror.dmi'
				if(!icon_exists(actual_file_name, sprite.worn_icon_state))
					to_chat(user, span_warning("ERROR sprites for [sprite.type]. Suit Storage slot."), confidential = TRUE)
		else if(sprite.icon_state)
			if(sprite.slot_flags & ITEM_SLOT_MASK)
				actual_file_name = 'icons/mob/clothing/mask.dmi'
				if(!icon_exists(actual_file_name, sprite.icon_state))
					to_chat(user, span_warning("ERROR sprites for [sprite.type]. Mask slot."), confidential = TRUE)
			if(sprite.slot_flags & ITEM_SLOT_NECK)
				actual_file_name = 'icons/mob/clothing/neck.dmi'
				if(!icon_exists(actual_file_name, sprite.icon_state))
					to_chat(user, span_warning("ERROR sprites for [sprite.type]. Neck slot."), confidential = TRUE)
			if(sprite.slot_flags & ITEM_SLOT_BACK)
				actual_file_name = 'icons/mob/clothing/back.dmi'
				if(!icon_exists(actual_file_name, sprite.icon_state))
					to_chat(user, span_warning("ERROR sprites for [sprite.type]. Back slot."), confidential = TRUE)
			if(sprite.slot_flags & ITEM_SLOT_HEAD)
				actual_file_name = 'icons/mob/clothing/head/default.dmi'
				if(!icon_exists(actual_file_name, sprite.icon_state))
					to_chat(user, span_warning("ERROR sprites for [sprite.type]. Head slot."), confidential = TRUE)
			if(sprite.slot_flags & ITEM_SLOT_BELT)
				actual_file_name = 'icons/mob/clothing/belt.dmi'
				if(!icon_exists(actual_file_name, sprite.icon_state))
					to_chat(user, span_warning("ERROR sprites for [sprite.type]. Belt slot."), confidential = TRUE)
			if(sprite.slot_flags & ITEM_SLOT_SUITSTORE)
				actual_file_name = 'icons/mob/clothing/belt_mirror.dmi'
				if(!icon_exists(actual_file_name, sprite.icon_state))
					to_chat(user, span_warning("ERROR sprites for [sprite.type]. Suit Storage slot."), confidential = TRUE)

#ifndef OPENDREAM
ADMIN_VERB(start_tracy, R_DEBUG, "Run Tracy Now", "Start running the byond-tracy profiler immediately", ADMIN_CATEGORY_DEBUG)
	if(GLOB.tracy_initialized)
		to_chat(user, span_warning("byond-tracy is already running!"), avoid_highlighting = TRUE, type = MESSAGE_TYPE_DEBUG, confidential = TRUE)
		return
	else if(GLOB.tracy_init_error)
		to_chat(user, span_danger("byond-tracy failed to initialize during an earlier attempt: [GLOB.tracy_init_error]"), avoid_highlighting = TRUE, type = MESSAGE_TYPE_DEBUG, confidential = TRUE)
		return
	message_admins(span_adminnotice("[key_name_admin(user)] is trying to start the byond-tracy profiler."))
	log_admin("[key_name(user)] is trying to start the byond-tracy profiler.")
	GLOB.tracy_initialized = FALSE
	GLOB.tracy_init_reason = "[user.ckey]"
	world.init_byond_tracy()
	if(GLOB.tracy_init_error)
		to_chat(user, span_danger("byond-tracy failed to initialize: [GLOB.tracy_init_error]"), avoid_highlighting = TRUE, type = MESSAGE_TYPE_DEBUG, confidential = TRUE)
		message_admins(span_adminnotice("[key_name_admin(user)] tried to start the byond-tracy profiler, but it failed to initialize ([GLOB.tracy_init_error])"))
		log_admin("[key_name(user)] tried to start the byond-tracy profiler, but it failed to initialize ([GLOB.tracy_init_error])")
		return
	to_chat(user, span_notice("byond-tracy successfully started!"), avoid_highlighting = TRUE, type = MESSAGE_TYPE_DEBUG, confidential = TRUE)
	message_admins(span_adminnotice("[key_name_admin(user)] started the byond-tracy profiler."))
	log_admin("[key_name(user)] started the byond-tracy profiler.")
	if(GLOB.tracy_log)
		rustg_file_write("[GLOB.tracy_log]", "[GLOB.log_directory]/tracy.loc")

ADMIN_VERB_CUSTOM_EXIST_CHECK(start_tracy)
	return CONFIG_GET(flag/allow_tracy_start) && fexists(TRACY_DLL_PATH)

ADMIN_VERB(queue_tracy, R_DEBUG, "Toggle Tracy Next Round", "Toggle running the byond-tracy profiler next round", ADMIN_CATEGORY_DEBUG)
	if(fexists(TRACY_ENABLE_PATH))
		fdel(TRACY_ENABLE_PATH)
	else
		rustg_file_write("[user.ckey]", TRACY_ENABLE_PATH)
	message_admins(span_adminnotice("[key_name_admin(user)] [fexists(TRACY_ENABLE_PATH) ? "enabled" : "disabled"] the byond-tracy profiler for next round."))
	log_admin("[key_name(user)] [fexists(TRACY_ENABLE_PATH) ? "enabled" : "disabled"] the byond-tracy profiler for next round.")

ADMIN_VERB_CUSTOM_EXIST_CHECK(queue_tracy)
	return CONFIG_GET(flag/allow_tracy_queue) && fexists(TRACY_DLL_PATH)
#endif
