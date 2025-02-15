#define SHEET_POINT_VALUE 33

/**********************Prisoners' Console**************************/

/obj/machinery/mineral/labor_claim_console
	name = "point claim console"
	desc = "A stacking console with an electromagnetic writer, used to track ore mined by prisoners."
	icon = 'icons/obj/machines/mining_machines.dmi'
	icon_state = "console"
	density = FALSE
	/// Connected stacking machine
	var/obj/machinery/mineral/stacking_machine/laborstacker/stacking_machine
	/// Whether the claim console initiated the launch.
	var/initiated_launch = FALSE
	/// Cooldown for console says.
	COOLDOWN_DECLARE(say_cooldown)

/obj/machinery/mineral/labor_claim_console/Initialize(mapload)
	. = ..()
	locate_stacking_machine()
	if(!SSshuttle.initialized)
		RegisterSignal(SSshuttle, COMSIG_SUBSYSTEM_POST_INITIALIZE, PROC_REF(register_shuttle_signal))
	else
		register_shuttle_signal()
	//If we can't find a stacking machine end it all ok?
	if(!stacking_machine)
		return INITIALIZE_HINT_QDEL

/obj/machinery/mineral/labor_claim_console/proc/register_shuttle_signal()
	SIGNAL_HANDLER
	var/obj/docking_port/mobile/laborshuttle = SSshuttle.getShuttle("laborcamp")
	RegisterSignal(laborshuttle, COMSIG_SHUTTLE_SHOULD_MOVE, PROC_REF(on_laborshuttle_can_move))
	UnregisterSignal(SSshuttle, COMSIG_SUBSYSTEM_POST_INITIALIZE)

/obj/machinery/mineral/labor_claim_console/Destroy()
	if(stacking_machine)
		stacking_machine.labor_console = null
		stacking_machine = null
	return ..()

/proc/cmp_sheet_list(list/a, list/b)
	return a["value"] - b["value"]

/obj/machinery/mineral/labor_claim_console/ui_interact(mob/user, datum/tgui/ui)
	ui = SStgui.try_update_ui(user, src, ui)
	if(!ui)
		ui = new(user, src, "LaborClaimConsole", name)
		ui.open()

/obj/machinery/mineral/labor_claim_console/ui_data(mob/user)
	var/list/data = list()
	var/can_go_home = FALSE

	if(obj_flags & EMAGGED)
		can_go_home = TRUE
	var/obj/item/card/id/worn_id
	if(isliving(user))
		var/mob/living/living_user = user
		worn_id = living_user.get_idcard(TRUE)
	if(istype(worn_id, /obj/item/card/id/advanced/prisoner))
		var/obj/item/card/id/advanced/prisoner/worn_prisoner_id = worn_id
		data["id_points"] = worn_prisoner_id.points
		if(!worn_prisoner_id.goal)
			data["status_info"] = "No goal set!"
		else if(worn_prisoner_id.points >= worn_prisoner_id.goal)
			can_go_home = TRUE
			data["status_info"] = "Goal met!"
		else
			data["status_info"] = "You are [(worn_prisoner_id.goal - worn_prisoner_id.points)] points away."
	else
		data["status_info"] = "No Prisoner ID detected."
		data["id_points"] = 0

	if(stacking_machine)
		data["unclaimed_points"] = stacking_machine.points

	data["can_go_home"] = can_go_home
	return data

/obj/machinery/mineral/labor_claim_console/ui_act(action, list/params, datum/tgui/ui, datum/ui_state/state)
	. = ..()
	if(.)
		return

	var/mob/user_mob = usr

	switch(action)

		if("claim_points")
			var/obj/item/card/id/worn_id
			if(isliving(user_mob))
				var/mob/living/living_mob = user_mob
				worn_id = living_mob.get_idcard(TRUE)
			if(istype(worn_id, /obj/item/card/id/advanced/prisoner))
				var/obj/item/card/id/advanced/prisoner/worn_prisoner_id = worn_id
				worn_prisoner_id.points += stacking_machine.points
				stacking_machine.points = 0
				say("Points transferred.")
				return TRUE
			else
				if(COOLDOWN_FINISHED(src, say_cooldown))
					say("No valid id for point transfer detected.")
					COOLDOWN_START(src, say_cooldown, 2 SECONDS)

		if("move_shuttle")
			var/list/labor_shuttle_mobs = find_labor_shuttle_mobs()
			if(length(labor_shuttle_mobs) > 1 || labor_shuttle_mobs[1] != user_mob)
				if(COOLDOWN_FINISHED(src, say_cooldown))
					say("Prisoners may only be released one at a time.")
					COOLDOWN_START(src, say_cooldown, 2 SECONDS)
				return

			switch(SSshuttle.moveShuttle("laborcamp", "laborcamp_home", TRUE))
				if(1)
					if(COOLDOWN_FINISHED(src, say_cooldown))
						say("Shuttle not found.")
						COOLDOWN_START(src, say_cooldown, 2 SECONDS)
				if(2)
					if(COOLDOWN_FINISHED(src, say_cooldown))
						say("Shuttle already at station.")
						COOLDOWN_START(src, say_cooldown, 2 SECONDS)
				if(3)
					if(COOLDOWN_FINISHED(src, say_cooldown))
						say("No permission to dock could be granted.")
						COOLDOWN_START(src, say_cooldown, 2 SECONDS)
				else
					if(!(obj_flags & EMAGGED))
						var/datum/record/crew/target = find_record(user_mob.real_name)
						target?.wanted_status = WANTED_PAROLE

						aas_config_announce(/datum/aas_config_entry/security_labor_stacker, list("PERSON" = user_mob.real_name), src, list(RADIO_CHANNEL_SECURITY))
					user_mob.log_message("has completed their labor points goal and is now sending the gulag shuttle back to the station.", LOG_GAME)
					say("Labor sentence finished, shuttle returning.")
					initiated_launch = TRUE
					return TRUE

/obj/machinery/mineral/labor_claim_console/proc/find_labor_shuttle_mobs()
	var/list/prisoners = mobs_in_area_type(list(get_area(src)))

	// security personnel and nonhumans do not count towards this
	for(var/mob/living/mob as anything in prisoners)
		var/obj/item/card/id/card = mob.get_idcard(FALSE)
		if(!ishuman(mob) || (ACCESS_BRIG in card?.GetAccess()))
			prisoners -= mob

	return prisoners

/obj/machinery/mineral/labor_claim_console/proc/on_laborshuttle_can_move(obj/docking_port/mobile/source)
	SIGNAL_HANDLER

	if(initiated_launch && length(find_labor_shuttle_mobs()) > 1)
		initiated_launch = FALSE
		say("Takeoff aborted. Prisoners may only be released one at a time.")
		return BLOCK_SHUTTLE_MOVE

/obj/machinery/mineral/labor_claim_console/proc/locate_stacking_machine()
	stacking_machine = locate(/obj/machinery/mineral/stacking_machine) in dview(2, get_turf(src))
	if(stacking_machine)
		stacking_machine.labor_console = src

/obj/machinery/mineral/labor_claim_console/emag_act(mob/user, obj/item/card/emag/emag_card)
	if (obj_flags & EMAGGED)
		return FALSE

	obj_flags |= EMAGGED
	balloon_alert(user, "id authenticator short-circuited")
	visible_message(span_warning("[src] lets out a few sparks!"))
	do_sparks(2, TRUE, src)
	return TRUE

/**********************Prisoner Collection Unit**************************/

/obj/machinery/mineral/stacking_machine/laborstacker
	force_connect = TRUE
	damage_deflection = 21 //otherwise prisoners will destroy it
	///Idle points sitting in the machine left to be claimed.
	var/points = 0
	///Labor claim console synced to our stacking machine, set by the console.
	var/obj/machinery/mineral/labor_claim_console/labor_console

/obj/machinery/mineral/stacking_machine/laborstacker/Destroy()
	if(labor_console)
		labor_console.stacking_machine = null
		labor_console = null
	return ..()

/obj/machinery/mineral/stacking_machine/laborstacker/process_sheet(obj/item/stack/sheet/input)
	if (input.manufactured && input.gulag_valid)
		points += SHEET_POINT_VALUE * input.amount
	return ..()

/obj/machinery/mineral/stacking_machine/laborstacker/base_item_interaction(mob/living/user, obj/item/weapon, list/modifiers)
	if(istype(weapon, /obj/item/stack/sheet))
		process_sheet(weapon)
		return ITEM_INTERACT_SUCCESS
	return ..()

/**********************Point Lookup Console**************************/

/obj/machinery/mineral/labor_points_checker
	name = "points checking console"
	desc = "A console used by prisoners to check the progress on their quotas. Simply swipe a prisoner ID."
	icon = 'icons/obj/machines/mining_machines.dmi'
	icon_state = "console"
	density = FALSE

/obj/machinery/mineral/labor_points_checker/attack_hand(mob/user, list/modifiers)
	. = ..()
	if(. || user.is_blind())
		return
	user.examinate(src)

/obj/machinery/mineral/labor_points_checker/attackby(obj/item/weapon, mob/user, params)
	if(!istype(weapon, /obj/item/card/id/advanced/prisoner))
		return ..()
	var/obj/item/card/id/advanced/prisoner/prisoner_id = weapon
	if(!prisoner_id.goal) //no goal to reach
		say("No goal required for this ID.")
		return
	say("ID: [prisoner_id.registered_name].")
	say("Points Collected: [prisoner_id.points] / [prisoner_id.goal].")
	say("Collect points by bringing smelted minerals to the Labor Shuttle stacking machine. Reach your quota to earn your release.")

/datum/aas_config_entry/security_labor_stacker
	name = "Security Alert: Labor Camp Release"
	announcement_lines_map = list(
		"Message" = "%PERSON returned to the station. Minerals and Prisoner ID card ready for retrieval."
	)
	vars_and_tooltips_map = list(
		"PERSON" = "will be replaced with the name of the prisoner."
	)

#undef SHEET_POINT_VALUE
