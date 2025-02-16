#define SPAWN_AT_BASE "Nuke base"
#define SPAWN_AT_INFILTRATOR "Infiltrator"

/datum/team/nuclear
	var/syndicate_name
	var/obj/machinery/nuclearbomb/tracked_nuke
	var/core_objective = /datum/objective/nuclear
	var/memorized_code
	var/list/team_discounts
	var/datum/weakref/war_button_ref

/datum/team/nuclear/New()
	..()
	syndicate_name = syndicate_name()

/datum/team/nuclear/roundend_report()
	var/list/parts = list()
	parts += span_header("[syndicate_name] Operatives:")

	switch(get_result())
		if(NUKE_RESULT_FLUKE)
			parts += "<span class='redtext big'>Humiliating Syndicate Defeat</span>"
			parts += "<B>The crew of [station_name()] gave [syndicate_name] operatives back their bomb! The syndicate base was destroyed!</B> Next time, don't lose the nuke!"
		if(NUKE_RESULT_NUKE_WIN)
			parts += "<span class='greentext big'>Syndicate Major Victory!</span>"
			parts += "<B>[syndicate_name] operatives have destroyed [station_name()]!</B>"
		if(NUKE_RESULT_NOSURVIVORS)
			parts += "<span class='neutraltext big'>Total Annihilation!</span>"
			parts += "<B>[syndicate_name] operatives destroyed [station_name()] but did not leave the area in time and got caught in the explosion.</B> Next time, don't lose the disk!"
		if(NUKE_RESULT_WRONG_STATION)
			parts += "<span class='redtext big'>Crew Minor Victory!</span>"
			parts += "<B>[syndicate_name] operatives secured the authentication disk but blew up something that wasn't [station_name()].</B> Next time, don't do that!"
		if(NUKE_RESULT_WRONG_STATION_DEAD)
			parts += "<span class='redtext big'>[syndicate_name] operatives have earned Darwin Award!</span>"
			parts += "<B>[syndicate_name] operatives blew up something that wasn't [station_name()] and got caught in the explosion.</B> Next time, don't do that!"
		if(NUKE_RESULT_HIJACK_DISK)
			parts += "<span class='greentext big'>Syndicate Miniscule Victory!</span>"
			parts += "<B>[syndicate_name] operatives failed to destroy [station_name()], but they managed to secure the disk and hijack the emergency shuttle, causing it to land on the syndicate base. Good job?</B>"
		if(NUKE_RESULT_HIJACK_NO_DISK)
			parts += "<span class='greentext big'>Syndicate Insignificant Victory!</span>"
			parts += "<B>[syndicate_name] operatives failed to destroy [station_name()] or secure the disk, but they managed to hijack the emergency shuttle, causing it to land on the syndicate base. Good job?</B>"
		if(NUKE_RESULT_CREW_WIN_SYNDIES_DEAD)
			parts += "<span class='redtext big'>Crew Major Victory!</span>"
			parts += "<B>The Research Staff has saved the disk and killed the [syndicate_name] Operatives</B>"
		if(NUKE_RESULT_CREW_WIN)
			parts += "<span class='redtext big'>Crew Major Victory!</span>"
			parts += "<B>The Research Staff has saved the disk and stopped the [syndicate_name] Operatives!</B>"
		if(NUKE_RESULT_DISK_LOST)
			parts += "<span class='neutraltext big'>Neutral Victory!</span>"
			parts += "<B>The Research Staff failed to secure the authentication disk but did manage to kill most of the [syndicate_name] Operatives!</B>"
		if(NUKE_RESULT_DISK_STOLEN)
			parts += "<span class='greentext big'>Syndicate Minor Victory!</span>"
			parts += "<B>[syndicate_name] operatives survived the assault but did not achieve the destruction of [station_name()].</B> Next time, don't lose the disk!"
		else
			parts += "<span class='neutraltext big'>Neutral Victory</span>"
			parts += "<B>Mission aborted!</B>"

	var/text = span_header("<br>The syndicate operatives were:")
	var/purchases = ""
	var/TC_uses = 0
	LAZYINITLIST(GLOB.uplink_purchase_logs_by_key)
	for(var/I in members)
		var/datum/mind/syndicate = I
		var/datum/uplink_purchase_log/H = GLOB.uplink_purchase_logs_by_key[syndicate.key]
		if(H)
			TC_uses += H.total_spent
			purchases += H.generate_render(show_key = FALSE)
	text += printplayerlist(members)
	text += "<br>"
	text += "(Syndicates used [TC_uses] TC) [purchases]"
	if(TC_uses == 0 && GLOB.station_was_nuked && !are_all_operatives_dead())
		text += "<BIG>[icon2html('icons/ui/antags/badass.dmi', world, "badass")]</BIG>"

	parts += text

	return "<div class='panel redborder'>[parts.Join("<br>")]</div>"

/datum/team/nuclear/antag_listing_name()
	if(syndicate_name)
		return "[syndicate_name] Syndicates"
	else
		return "Syndicates"

/datum/team/nuclear/antag_listing_entry()
	var/disk_report = "<b>Nuclear Disk(s)</b><br>"
	disk_report += "<table cellspacing=5>"
	for(var/obj/item/disk/nuclear/N in SSpoints_of_interest.real_nuclear_disks)
		disk_report += "<tr><td>[N.name], "
		var/atom/disk_loc = N.loc
		while(!isturf(disk_loc))
			if(ismob(disk_loc))
				var/mob/M = disk_loc
				disk_report += "carried by <a href='byond://?_src_=holder;[HrefToken()];adminplayeropts=[REF(M)]'>[M.real_name]</a> "
			if(isobj(disk_loc))
				var/obj/O = disk_loc
				disk_report += "in \a [O.name] "
			disk_loc = disk_loc.loc
		disk_report += "in [disk_loc.loc] at ([disk_loc.x], [disk_loc.y], [disk_loc.z])</td><td><a href='byond://?_src_=holder;[HrefToken()];adminplayerobservefollow=[REF(N)]'>FLW</a></td></tr>"
	disk_report += "</table>"

	var/post_report

	var/war_declared = FALSE
	for(var/obj/item/circuitboard/computer/syndicate_shuttle/board as anything in GLOB.syndicate_shuttle_boards)
		if(board.challenge)
			war_declared = TRUE

	var/force_war_button = ""

	if(war_declared)
		post_report += "<b>War declared.</b>"
		force_war_button = "\[Force war\]"
	else
		post_report += "<b>War not declared.</b>"
		var/obj/item/nuclear_challenge/war_button = war_button_ref?.resolve()
		if(war_button)
			force_war_button = "<a href='byond://?_src_=holder;[HrefToken()];force_war=[REF(war_button)]'>\[Force war\]</a>"
		else
			force_war_button = "\[Cannot declare war, challenge button missing!\]"

	post_report += "\n[force_war_button]"
	post_report += "\n<a href='byond://?_src_=holder;[HrefToken()];give_reinforcement=[REF(src)]'>\[Send Reinforcement\]</a>"

	var/final_report = ..()
	final_report += disk_report
	final_report += post_report
	return final_report

/datum/team/nuclear/proc/rename_team(new_name)
	syndicate_name = new_name
	name = "[syndicate_name] Team"
	for(var/I in members)
		var/datum/mind/synd_mind = I
		var/mob/living/carbon/human/human_to_rename = synd_mind.current
		if(!istype(human_to_rename))
			continue
		var/first_name = human_to_rename.client?.prefs?.read_preference(/datum/preference/name/operative_alias) || pick(GLOB.operative_aliases)
		var/chosen_name = "[first_name] [syndicate_name]"
		human_to_rename.fully_replace_character_name(human_to_rename.real_name, chosen_name)

/datum/team/nuclear/proc/admin_spawn_reinforcement(mob/admin)
	if(!check_rights_for(admin.client, R_ADMIN))
		return

	var/infil_or_nukebase = tgui_alert(
		admin,
		"Spawn them at the nuke base, or in the Infiltrator?",
		"Where to reinforce?",
		list(SPAWN_AT_BASE, SPAWN_AT_INFILTRATOR, "Cancel"),
	)

	if(!infil_or_nukebase || infil_or_nukebase == "Cancel")
		return

	var/tc_to_spawn = tgui_input_number(admin, "How much TC to spawn with?", "TC", 0, 100)

	var/mob/chosen_one = SSpolling.poll_ghost_candidates(
		check_jobban = ROLE_OPERATIVE,
		role = ROLE_OPERATIVE,
		poll_time = 30 SECONDS,
		ignore_category = POLL_IGNORE_SYNDICATE,
		alert_pic = /obj/structure/sign/poster/contraband/gorlex_recruitment,
		role_name_text = "emergency syndicate reinforcement",
		amount_to_pick = 1,
	)

	if(isnull(chosen_one))
		tgui_alert(admin, "No candidates found.", "Recruitment Shortage", list("OK"))
		return


	var/turf/spawn_loc
	if(infil_or_nukebase == SPAWN_AT_INFILTRATOR)
		var/area/spawn_in
		// Prioritize EVA then hallway, if neither can be found default to the first area we can find
		for(var/area_type in list(/area/shuttle/syndicate/eva, /area/shuttle/syndicate/hallway, /area/shuttle/syndicate))
			spawn_in = locate(area_type) in GLOB.areas // I'd love to use areas_by_type but the Infiltrator is a unique area
			if(spawn_in)
				break

		var/list/turf/options = list()
		for(var/turf/open/open_turf in spawn_in?.get_turfs_from_all_zlevels())
			if(open_turf.is_blocked_turf())
				continue
			options += open_turf

		if(length(options))
			spawn_loc = pick(options)
		else
			infil_or_nukebase = SPAWN_AT_BASE

	if(infil_or_nukebase == SPAWN_AT_BASE)
		spawn_loc = pick(GLOB.nukeop_start)

	var/mob/living/carbon/human/nukie = new(spawn_loc)
	chosen_one.client.prefs.safe_transfer_prefs_to(nukie, is_antag = TRUE)
	nukie.PossessByPlayer(chosen_one.key)

	var/datum/antagonist/nukeop/antag_datum = new()
	antag_datum.send_to_spawnpoint = FALSE
	antag_datum.nukeop_outfit = /datum/outfit/syndicate/reinforcement

	nukie.mind.add_antag_datum(antag_datum, src)

	var/datum/component/uplink/uplink = nukie.mind.find_syndicate_uplink()
	uplink?.uplink_handler.set_telecrystals(tc_to_spawn)

	// add some pizzazz
	do_sparks(4, FALSE, spawn_loc)
	new /obj/effect/temp_visual/teleport_abductor/syndi_teleporter(spawn_loc)
	playsound(spawn_loc, SFX_SPARKS, 50, TRUE)
	playsound(spawn_loc, 'sound/effects/phasein.ogg', 50, TRUE)

	tgui_alert(admin, "Reinforcement spawned at [infil_or_nukebase] with [tc_to_spawn].", "Reinforcements have arrived", list("God speed"))

/datum/team/nuclear/proc/update_objectives()
	if(core_objective)
		var/datum/objective/O = new core_objective
		O.team = src
		objectives += O

/datum/team/nuclear/proc/is_disk_rescued()
	for(var/obj/item/disk/nuclear/nuke_disk in SSpoints_of_interest.real_nuclear_disks)
		//If emergency shuttle is in transit disk is only safe on it
		if(SSshuttle.emergency.mode == SHUTTLE_ESCAPE)
			if(!SSshuttle.emergency.is_in_shuttle_bounds(nuke_disk))
				return FALSE
		//If shuttle escaped check if it's on centcom side
		else if(SSshuttle.emergency.mode == SHUTTLE_ENDGAME)
			if(!nuke_disk.onCentCom())
				return FALSE
		else //Otherwise disk is safe when on station
			var/turf/disk_turf = get_turf(nuke_disk)
			if(!disk_turf || !is_station_level(disk_turf.z))
				return FALSE
	return TRUE

/datum/team/nuclear/proc/are_all_operatives_dead()
	for(var/datum/mind/operative_mind as anything in members)
		if(ishuman(operative_mind.current) && (operative_mind.current.stat != DEAD))
			return FALSE
	return TRUE

/datum/team/nuclear/proc/get_result()
	var/shuttle_evacuated = EMERGENCY_ESCAPED_OR_ENDGAMED
	var/shuttle_landed_base = SSshuttle.emergency.is_hijacked()
	var/disk_rescued = is_disk_rescued()
	var/syndies_didnt_escape = !is_infiltrator_docked_at_syndiebase()
	var/team_is_dead = are_all_operatives_dead()
	var/station_was_nuked = GLOB.station_was_nuked
	var/station_nuke_source = GLOB.station_nuke_source

	// The nuke detonated on the syndicate base
	if(station_nuke_source == DETONATION_HIT_SYNDIE_BASE)
		return NUKE_RESULT_FLUKE

	// The station was nuked
	if(station_was_nuked)
		// The station was nuked and the infiltrator failed to escape
		if(syndies_didnt_escape)
			return NUKE_RESULT_NOSURVIVORS
		// The station was nuked and the infiltrator escaped, and the nuke ops won
		else
			return NUKE_RESULT_NUKE_WIN

	// The station was not nuked, but something was
	else if(station_nuke_source && !disk_rescued)
		// The station was not nuked, but something was, and the syndicates didn't escape it
		if(syndies_didnt_escape)
			return NUKE_RESULT_WRONG_STATION_DEAD
		// The station was not nuked, but something was, and the syndicates returned to their base
		else
			return NUKE_RESULT_WRONG_STATION

	// Nuke didn't blow, but nukies somehow hijacked the emergency shuttle to land at the base anyways.
	else if(shuttle_landed_base)
		if(disk_rescued)
			return NUKE_RESULT_HIJACK_DISK
		else
			return NUKE_RESULT_HIJACK_NO_DISK

	// No nuke went off, the station rescued the disk
	else if(disk_rescued)
		// No nuke went off, the shuttle left, and the team is dead
		if(shuttle_evacuated && team_is_dead)
			return NUKE_RESULT_CREW_WIN_SYNDIES_DEAD
		// No nuke went off, but the nuke ops survived
		else
			return NUKE_RESULT_CREW_WIN

	// No nuke went off, but the disk was left behind
	else
		// No nuke went off, the disk was left, but all the ops are dead
		if(team_is_dead)
			return NUKE_RESULT_DISK_LOST
		// No nuke went off, the disk was left, there are living ops, but the shuttle left successfully
		else if(shuttle_evacuated)
			return NUKE_RESULT_DISK_STOLEN

	CRASH("[type] - got an undefined / unexpected result.")

/// Returns whether or not syndicate operatives escaped.
/proc/is_infiltrator_docked_at_syndiebase()
	var/obj/docking_port/mobile/infiltrator/infiltrator_port = SSshuttle.getShuttle("syndicate")

	var/datum/lazy_template/nukie_base/nukie_template = GLOB.lazy_templates[LAZY_TEMPLATE_KEY_NUKIEBASE]
	if(!nukie_template)
		return FALSE // if its not even loaded, cant be docked

	for(var/datum/turf_reservation/loaded_area as anything in nukie_template.reservations)
		var/infiltrator_turf = get_turf(infiltrator_port)
		if(infiltrator_turf in loaded_area.reserved_turfs)
			return TRUE
	return FALSE

/datum/team/nuclear/add_member(datum/mind/new_member)
	..()
	SEND_SIGNAL(src, COMSIG_NUKE_TEAM_ADDITION, new_member.current)

#undef SPAWN_AT_BASE
#undef SPAWN_AT_INFILTRATOR
