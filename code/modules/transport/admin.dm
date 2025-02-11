ADMIN_VERB(reset_tram, R_DEBUG|R_ADMIN, "Reset Tram", "Reset a tram controller or its contents.", ADMIN_CATEGORY_DEBUG)
	var/static/list/debug_tram_list = list(
		TRAMSTATION_LINE_1,
		BIRDSHOT_LINE_1,
		BIRDSHOT_LINE_2,
		HILBERT_LINE_1,
	)

	var/datum/transport_controller/linear/tram/broken_controller
	var/selected_transport_id = tgui_input_list(user, "Which tram?", "Off the rails", debug_tram_list)
	if(isnull(selected_transport_id))
		return
	var/reset_type = tgui_input_list(user, "How hard of a reset?", "How bad is it screwed up", list("Clear Tram Contents", "Controller", "Controller and Contents", "Delete Datum", "Cancel"))

	if(isnull(reset_type) || reset_type == "Cancel")
		return

	for(var/datum/transport_controller/linear/tram/transport as anything in SStransport.transports_by_type[TRANSPORT_TYPE_TRAM])
		if(transport.specific_transport_id == selected_transport_id)
			broken_controller = transport
			break

	if(isnull(broken_controller))
		to_chat(user, span_warning("Couldn't find a transport controller datum with ID [selected_transport_id]!"))
		return

	switch(reset_type)
		if("Clear Tram Contents")
			var/selection = tgui_alert(user, "Include player mobs in the clearing?", "Contents reset [selected_transport_id]", list("Contents", "Contents and Players", "Cancel"))
			switch(selection)
				if("Contents")
					broken_controller.reset_lift_contents(foreign_objects = TRUE, foreign_non_player_mobs = TRUE, consider_player_mobs = FALSE)
					message_admins("[key_name_admin(user)] performed a contents reset of tram ID [selected_transport_id].")
					log_transport("TC: [selected_transport_id]: [key_name_admin(user)] performed a contents reset.")
				if("Contents and Players")
					broken_controller.reset_lift_contents(foreign_objects = TRUE, foreign_non_player_mobs = TRUE, consider_player_mobs = TRUE)
					message_admins("[key_name_admin(user)] performed a contents and player mob reset of tram ID [selected_transport_id].")
					log_transport("TC: [selected_transport_id]: [key_name_admin(user)] performed a contents and player mob reset.")
				else
					return

		if("Controller")
			log_transport("TC: [selected_transport_id]: [key_name_admin(user)] performed a controller reset, force operational.")
			message_admins("[key_name_admin(user)] performed a controller reset of tram ID [selected_transport_id].")
			broken_controller.set_operational(TRUE)
			broken_controller.reset_position()

		if("Controller and Contents")
			var/selection = tgui_alert(user, "Include player mobs in the clearing?", "Contents reset [selected_transport_id]", list("Contents", "Contents and Players", "Cancel"))
			switch(selection)
				if("Contents")
					message_admins("[key_name_admin(user)] performed a contents and controller reset of tram ID [selected_transport_id].")
					log_transport("TC: [selected_transport_id]: [key_name_admin(user)] performed a contents reset. Controller reset, force operational.")
					broken_controller.reset_lift_contents(foreign_objects = TRUE, foreign_non_player_mobs = TRUE, consider_player_mobs = FALSE)
				if("Contents and Players")
					message_admins("[key_name_admin(user)] performed a contents/player/controller reset of tram ID [selected_transport_id].")
					log_transport("TC: [selected_transport_id]: [key_name_admin(user)] performed a contents and player mob reset. Controller reset, force operational.")
					broken_controller.reset_lift_contents(foreign_objects = TRUE, foreign_non_player_mobs = TRUE, consider_player_mobs = TRUE)
				else
					return

			broken_controller.set_operational(TRUE)
			broken_controller.reset_position()

		if("Delete Datum")
			var/confirm = tgui_alert(user, "Deleting [selected_transport_id] will make it unrecoverable this round. Are you sure?", "Delete tram ID [selected_transport_id]", list("Yes", "Cancel"))
			if(confirm != "Yes")
				return

			var/obj/machinery/transport/tram_controller/tram_cabinet = broken_controller.paired_cabinet
			if(!isnull(tram_cabinet))
				tram_cabinet.controller_datum = null
				tram_cabinet.update_appearance()

			broken_controller.cycle_doors(CYCLE_OPEN, BYPASS_DOOR_CHECKS)
			broken_controller.estop()
			qdel(broken_controller)
			message_admins("[key_name_admin(user)] performed a datum delete of tram ID [selected_transport_id].")
