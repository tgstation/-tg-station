ADMIN_VERB_VISIBILITY(debug_air_status, ADMIN_VERB_VISIBLITY_FLAG_MAPPING_DEBUG)
ADMIN_VERB(debug_air_status, R_DEBUG, "Debug Air Status" , ADMIN_VERB_NO_DESCRIPTION, ADMIN_CATEGORY_HIDDEN, turf/target in world)
	atmos_scan(user.mob, target, silent = TRUE)
	BLACKBOX_LOG_ADMIN_VERB("Show Air Status")

ADMIN_VERB_VISIBILITY(fix_next_move, ADMIN_VERB_VISIBLITY_FLAG_MAPPING_DEBUG)
ADMIN_VERB(fix_next_move, R_DEBUG, "Fix Next Move", "Unfreezes all frozen mobs.", ADMIN_CATEGORY_DEBUG)
	var/largest_move_time = 0
	var/largest_click_time = 0
	var/mob/largest_move_mob = null
	var/mob/largest_click_mob = null
	for(var/mob/frozen_mob as anything in GLOB.player_list)
		if(frozen_mob.next_move >= largest_move_time)
			largest_move_mob = frozen_mob
			if(frozen_mob.next_move > world.time)
				largest_move_time = frozen_mob.next_move - world.time
			else
				largest_move_time = 1
		if(frozen_mob.next_click >= largest_click_time)
			largest_click_mob = frozen_mob
			if(frozen_mob.next_click > world.time)
				largest_click_time = frozen_mob.next_click - world.time
			else
				largest_click_time = 0
		log_admin("DEBUG: [key_name(frozen_mob)]  next_move = [frozen_mob.next_move]  lastDblClick = [frozen_mob.next_click]  world.time = [world.time]")
		frozen_mob.next_move = 1
		frozen_mob.next_click = 0
	message_admins("[ADMIN_LOOKUPFLW(largest_move_mob)] had the largest move delay with [largest_move_time] frames / [DisplayTimeText(largest_move_time)]!")
	message_admins("[ADMIN_LOOKUPFLW(largest_click_mob)] had the largest click delay with [largest_click_time] frames / [DisplayTimeText(largest_click_time)]!")
	message_admins("world.time = [world.time]")
	BLACKBOX_LOG_ADMIN_VERB("Unfreeze Everyone")

ADMIN_VERB_VISIBILITY(radio_report, ADMIN_VERB_VISIBLITY_FLAG_MAPPING_DEBUG)
ADMIN_VERB(radio_report, R_DEBUG, "Radio Report", "Shows a report of all radio devices and their filters.", ADMIN_CATEGORY_DEBUG)
	var/output = "<b>Radio Report</b><hr>"
	for (var/fq in SSradio.frequencies)
		output += "<b>Freq: [fq]</b><br>"
		var/datum/radio_frequency/fqs = SSradio.frequencies[fq]
		if (!fqs)
			output += "&nbsp;&nbsp;<b>ERROR</b><br>"
			continue
		for (var/filter in fqs.devices)
			var/list/filtered = fqs.devices[filter]
			if (!filtered)
				output += "&nbsp;&nbsp;[filter]: ERROR<br>"
				continue
			output += "&nbsp;&nbsp;[filter]: [filtered.len]<br>"
			for(var/datum/weakref/device_ref as anything in filtered)
				var/atom/device = device_ref.resolve()
				if(!device)
					filtered -= device_ref
					continue
				if (istype(device, /atom))
					var/atom/A = device
					output += "&nbsp;&nbsp;&nbsp;&nbsp;[device] ([AREACOORD(A)])<br>"
				else
					output += "&nbsp;&nbsp;&nbsp;&nbsp;[device]<br>"

	var/datum/browser/browser = new(user, "radioreport", "Radio Logs", 400, 440)
	browser.set_content(output)
	browser.open()
	BLACKBOX_LOG_ADMIN_VERB("Show Radio Report")

ADMIN_VERB(reload_admins, R_NONE, "Reload Admins", "Reloads all admins from the database.", ADMIN_CATEGORY_MAIN)
	var/confirm = tgui_alert(user, "Are you sure you want to reload all admins?", "Confirm", list("Yes", "No"))
	if(confirm != "Yes")
		return

	load_admins()
	BLACKBOX_LOG_ADMIN_VERB("Reload All Admins")
	message_admins("[key_name_admin(user)] manually reloaded admins")

ADMIN_VERB(toggle_cdn, R_SERVER|R_DEBUG, "Toggle CDN", "Toggles the CDN for the server.", ADMIN_CATEGORY_SERVER)
	var/static/admin_disabled_cdn_transport = null
	if (alert(user, "Are you sure you want to toggle the CDN asset transport?", "Confirm", "Yes", "No") != "Yes")
		return
	var/current_transport = CONFIG_GET(string/asset_transport)
	if (!current_transport || current_transport == "simple")
		if (admin_disabled_cdn_transport)
			CONFIG_SET(string/asset_transport, admin_disabled_cdn_transport)
			admin_disabled_cdn_transport = null
			SSassets.OnConfigLoad()
			message_admins("[key_name_admin(user)] re-enabled the CDN asset transport")
			log_admin("[key_name(user)] re-enabled the CDN asset transport")
		else
			to_chat(user, span_adminnotice("The CDN is not enabled!"))
			if (tgui_alert(user, "The CDN asset transport is not enabled! If you having issues with assets you can also try disabling filename mutations.", "The CDN asset transport is not enabled!", list("Try disabling filename mutations", "Nevermind")) == "Try disabling filename mutations")
				SSassets.transport.dont_mutate_filenames = !SSassets.transport.dont_mutate_filenames
				message_admins("[key_name_admin(user)] [(SSassets.transport.dont_mutate_filenames ? "disabled" : "re-enabled")] asset filename transforms")
				log_admin("[key_name(user)] [(SSassets.transport.dont_mutate_filenames ? "disabled" : "re-enabled")] asset filename transforms")
	else
		admin_disabled_cdn_transport = current_transport
		CONFIG_SET(string/asset_transport, "simple")
		SSassets.OnConfigLoad()
		message_admins("[key_name_admin(user)] disabled the CDN asset transport")
		log_admin("[key_name(user)] disabled the CDN asset transport")
