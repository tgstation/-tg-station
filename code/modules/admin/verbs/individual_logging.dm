/proc/show_individual_logging_panel(mob/M, source = LOGSRC_CKEY, type = INDIVIDUAL_ATTACK_LOG)
	if(!M || !ismob(M))
		return

	var/ntype = text2num(type)

	//Add client links
	var/list/dat = list()
	if(M.ckey)
		dat += "<center><p>Ckey</p></center>"
		dat += "<center>"
		dat += individual_logging_panel_link(M, INDIVIDUAL_GAME_LOG, LOGSRC_CKEY, "Game Log", source, ntype)
		dat += " | "
		dat += individual_logging_panel_link(M, INDIVIDUAL_ATTACK_LOG, LOGSRC_CKEY, "Attack Log", source, ntype)
		dat += " | "
		dat += individual_logging_panel_link(M, INDIVIDUAL_SAY_LOG, LOGSRC_CKEY, "Say Log", source, ntype)
		dat += " | "
		dat += individual_logging_panel_link(M, INDIVIDUAL_EMOTE_LOG, LOGSRC_CKEY, "Emote Log", source, ntype)
		dat += " | "
		dat += individual_logging_panel_link(M, INDIVIDUAL_COMMS_LOG, LOGSRC_CKEY, "Comms Log", source, ntype)
		dat += " | "
		dat += individual_logging_panel_link(M, INDIVIDUAL_OOC_LOG, LOGSRC_CKEY, "OOC Log", source, ntype)
		dat += " | "
		dat += individual_logging_panel_link(M, INDIVIDUAL_SHOW_ALL_LOG, LOGSRC_CKEY, "Show All", source, ntype)
		dat += "</center>"
	else
		dat += "<p> No ckey attached to mob </p>"

	dat += "<hr style='background:#000000; border:0; height:1px'>"
	dat += "<center><p>Mob</p></center>"
	//Add the links for the mob specific log
	dat += "<center>"
	dat += individual_logging_panel_link(M, INDIVIDUAL_GAME_LOG, LOGSRC_MOB, "Game Log", source, ntype)
	dat += " | "
	dat += individual_logging_panel_link(M, INDIVIDUAL_ATTACK_LOG, LOGSRC_MOB, "Attack Log", source, ntype)
	dat += " | "
	dat += individual_logging_panel_link(M, INDIVIDUAL_SAY_LOG, LOGSRC_MOB, "Say Log", source, ntype)
	dat += " | "
	dat += individual_logging_panel_link(M, INDIVIDUAL_EMOTE_LOG, LOGSRC_MOB, "Emote Log", source, ntype)
	dat += " | "
	dat += individual_logging_panel_link(M, INDIVIDUAL_COMMS_LOG, LOGSRC_MOB, "Comms Log", source, ntype)
	dat += " | "
	dat += individual_logging_panel_link(M, INDIVIDUAL_OOC_LOG, LOGSRC_MOB, "OOC Log", source, ntype)
	dat += " | "
	dat += individual_logging_panel_link(M, INDIVIDUAL_SHOW_ALL_LOG, LOGSRC_MOB, "Show All", source, ntype)
	dat += "</center>"

	dat += "<hr style='background:#000000; border:0; height:1px'>"

	var/log_source = M.logging
	if(source == LOGSRC_CKEY && M.persistent_client)
		log_source = M.persistent_client.logging

	var/list/concatenated_logs = list()
	for(var/log_type in log_source)
		var/nlog_type = text2num(log_type)
		if(nlog_type & ntype)
			var/list/all_the_entrys = log_source[log_type]
			for(var/entry in all_the_entrys)
				concatenated_logs += "<b>[entry]</b><br>[all_the_entrys[entry]]"

	if(length(concatenated_logs))
		sortTim(concatenated_logs, cmp = GLOBAL_PROC_REF(cmp_text_dsc)) //Sort by timestamp.
		dat += "<font size=2px>"
		dat += concatenated_logs.Join("<br>")
		dat += "</font>"

	var/datum/browser/popup = new(usr, "invidual_logging_[key_name(M)]", "Individual Logs", 600, 600)
	popup.set_content(dat.Join())
	popup.open()

/proc/individual_logging_panel_link(mob/M, log_type, log_src, label, selected_src, selected_type)
	var/slabel = label
	if(selected_type == log_type && selected_src == log_src)
		slabel = "<b>\[[label]\]</b>"
	//This is necessary because num2text drops digits and rounds on big numbers. If more defines get added in the future it could break again.
	log_type = num2text(log_type, MAX_BITFLAG_DIGITS)
	return "<a href='byond://?_src_=holder;[HrefToken()];individuallog=[REF(M)];log_type=[log_type];log_src=[log_src]'>[slabel]</a>"
