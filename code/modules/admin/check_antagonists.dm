//I wish we had interfaces sigh, and i'm not sure giving team and antag common root is a better solution here

//Name shown on antag list
/datum/antagonist/proc/antag_listing_name()
	if(!owner)
		return "Unassigned"
	if(owner.current)
		return "<a href='byond://?_src_=holder;[HrefToken()];adminplayeropts=[REF(owner.current)]'>[owner.current.real_name]</a> "
	else
		return "<a href='byond://?_src_=vars;[HrefToken()];Vars=[REF(owner)]'>[owner.name]</a> "

//Whatever interesting things happened to the antag admins should know about
//Include additional information about antag in this part
/datum/antagonist/proc/antag_listing_status()
	if(!owner)
		return "(Unassigned)"
	if(!owner.current)
		return "<font color=red>(Body destroyed)</font>"
	else
		if(owner.current.stat == DEAD)
			return "<font color=red>(DEAD)</font>"
		else if(!owner.current.client)
			return "(No client)"

//Builds the common FLW PM TP commands part
//Probably not going to be overwritten by anything but you never know
/datum/antagonist/proc/antag_listing_commands()
	if(!owner)
		return
	var/list/parts = list()
	parts += "<a href='byond://?priv_msg=[ckey(owner.key)]'>PM</a>"
	if(owner.current) //There's body to follow
		parts += "<a href='byond://?_src_=holder;[HrefToken()];adminplayerobservefollow=[REF(owner.current)]'>FLW</a>"
	else
		parts += ""
	parts += "<a href='byond://?_src_=holder;[HrefToken()];traitor=[REF(owner)]'>Show Objective</a>"
	return parts //Better as one cell or two/three

//Builds table row for the antag
// Jim (Status) FLW PM TP
/datum/antagonist/proc/antag_listing_entry()
	var/list/parts = list()
	if(show_name_in_check_antagonists)
		parts += "[antag_listing_name()]([name])"
	else
		parts += antag_listing_name()
	parts += antag_listing_status()
	parts += antag_listing_commands()
	return "<tr><td>[parts.Join("</td><td>")]</td></tr>"

/datum/admins/proc/build_antag_listing()
	var/list/sections = list()
	var/list/priority_sections = list()

	var/list/all_teams = list()
	var/list/all_antagonists = list()

	for(var/datum/antagonist/A in GLOB.antagonists)
		if(!A.owner)
			continue
		all_teams |= A.get_team()
		all_antagonists += A

	for(var/datum/team/T in all_teams)
		for(var/datum/antagonist/X in all_antagonists)
			if(X.get_team() == T)
				all_antagonists -= X
		sections += T.antag_listing_entry()

	sortTim(all_antagonists, GLOBAL_PROC_REF(cmp_antag_category))

	var/current_category
	var/list/current_section = list()
	for(var/i in 1 to all_antagonists.len)
		var/datum/antagonist/current_antag = all_antagonists[i]
		var/datum/antagonist/next_antag
		if(i < all_antagonists.len)
			next_antag = all_antagonists[i+1]
		if(!current_category)
			current_category = current_antag.roundend_category
			current_section += "<b>[capitalize(current_category)]</b><br>"
			current_section += "<table cellspacing=5>"
		current_section += current_antag.antag_listing_entry() // Name - (Traitor) - FLW | PM | TP

		if(!next_antag || next_antag.roundend_category != current_antag.roundend_category) //End of section
			current_section += "</table>"
			sections += current_section.Join()
			current_section.Cut()
			current_category = null
	var/list/all_sections = priority_sections + sections
	return all_sections.Join("<br>")

/datum/admins/proc/check_antagonists()
	if(!SSticker.HasRoundStarted())
		tgui_alert(usr, "The game hasn't started yet!")
		return
	var/list/dat = list("<html><head><meta http-equiv='Content-Type' content='text/html; charset=UTF-8'><title>Round Status</title></head><body><h1><B>Round Status</B></h1>")
	dat += "<a href='byond://?_src_=holder;[HrefToken()];gamemode_panel=1'>Game Mode Panel</a><br>"
	dat += "Round Duration: <B>[DisplayTimeText(world.time - SSticker.round_start_time)]</B><BR>"
	dat += "<B>Emergency shuttle</B><BR>"
	if(EMERGENCY_IDLE_OR_RECALLED)
		dat += "<a href='byond://?_src_=holder;[HrefToken()];call_shuttle=1'>Call Shuttle</a><br>"
	else
		var/timeleft = SSshuttle.emergency.timeLeft()
		if(SSshuttle.emergency.mode == SHUTTLE_CALL)
			dat += "ETA: <a href='byond://?_src_=holder;[HrefToken()];edit_shuttle_time=1'>[(timeleft / 60) % 60]:[add_leading(num2text(timeleft % 60), 2, "0")]</a><BR>"
			dat += "<a href='byond://?_src_=holder;[HrefToken()];call_shuttle=2'>Send Back</a><br>"
		else
			dat += "ETA: <a href='byond://?_src_=holder;[HrefToken()];edit_shuttle_time=1'>[(timeleft / 60) % 60]:[add_leading(num2text(timeleft % 60), 2, "0")]</a><BR>"
	dat += "<a href='byond://?_src_=holder;[HrefToken()];end_round=[REF(usr)]'>End Round Now</a><br>"
	if(SSticker.delay_end)
		dat += "<a href='byond://?_src_=holder;[HrefToken()];undelay_round_end=1'>Undelay Round End</a><br>"
	else
		dat += "<a href='byond://?_src_=holder;[HrefToken()];delay_round_end=1'>Delay Round End</a><br>"
	dat += "<a href='byond://?_src_=holder;[HrefToken()];ctf_toggle=1'>Enable/Disable CTF</a><br>"
	dat += "<a href='byond://?_src_=holder;[HrefToken()];rebootworld=1'>Reboot World</a><br>"
	dat += "<a href='byond://?_src_=holder;[HrefToken()];check_teams=1'>Check Teams</a>"
	var/connected_players = GLOB.clients.len
	var/lobby_players = 0
	var/observers = 0
	var/observers_connected = 0
	var/living_players = 0
	var/living_players_connected = 0
	var/antagonists = 0
	var/antagonists_dead = 0
	var/brains = 0
	var/other_players = 0
	var/living_skipped = 0
	var/drones = 0
	var/security = 0
	var/security_dead = 0
	for(var/mob/checked_mob in GLOB.mob_list)
		if(checked_mob.ckey)
			if(isnewplayer(checked_mob))
				lobby_players++
				continue
			else if(checked_mob.mind && !isbrain(checked_mob) && !isobserver(checked_mob))
				if(checked_mob.stat != DEAD)
					if(isdrone(checked_mob))
						drones++
						continue
					if(is_centcom_level(checked_mob.z))
						living_skipped++
						continue
					living_players++
					if(checked_mob.client)
						living_players_connected++
				else if (checked_mob.ckey)
					// This finds all dead mobs that still have a ckey inside them
					// Ie, they have died, but have not ghosted
					observers++
					if (checked_mob.client)
						observers_connected++

				if(checked_mob.mind.special_role)
					antagonists++
					if(checked_mob.stat == DEAD)
						antagonists_dead++
				if(checked_mob.mind.assigned_role?.departments_list?.Find(/datum/job_department/security))
					security++
					if(checked_mob.stat == DEAD)
						security_dead++
			else if(checked_mob.stat == DEAD || isobserver(checked_mob))
				observers++
				if(checked_mob.client)
					observers_connected++
			else if(isbrain(checked_mob))
				brains++
			else
				other_players++
	dat += "<BR><b><font color='blue' size='3'>Players:|[connected_players - lobby_players] ingame|[connected_players] connected|[lobby_players] lobby|</font></b>"
	dat += "<BR><b><font color='green'>Living Players:|[living_players_connected] active|[living_players - living_players_connected] disconnected|</font></b>"
	dat += "<BR><b><font color='#e29300'>Antagonists Players:|[antagonists] ingame|[antagonists-antagonists_dead] alive|[antagonists_dead] dead|</font></b>"
	dat += "<BR><b><font color='#860e03'>Security Players:|[security] ingame|[security-security_dead] alive|[security_dead] dead|</font></b>"
	dat += "<BR><b><font color='#bf42f4'>SKIPPED \[On centcom Z-level\]: [living_skipped] living players|[drones] living drones|</font></b>"
	dat += "<BR><b><font color='red'>Dead/Observing players:|[observers_connected] active|[observers - observers_connected] disconnected|[brains] brains|</font></b>"
	if(other_players)
		dat += "<BR>[span_userdanger("[other_players] players in invalid state or the statistics code is bugged!")]"
	dat += "<br><br>"

	dat += build_antag_listing()

	dat += "</body></html>"
	var/datum/browser/browser = new(usr, "roundstatus", "Round Status", 500, 500)
	browser.set_content(dat.Join())
	browser.open()
