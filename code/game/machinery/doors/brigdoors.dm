#define MAX_TIMER (15 MINUTES)
#define PRESET_SHORT (2 MINUTES)
#define PRESET_MEDIUM (3 MINUTES)
#define PRESET_LONG (5 MINUTES)

/**
 * Brig Door control displays.
 *
 * This is a controls the timer for the brig doors, displays the timer on itself and
 * has a popup window when used, allowing to set the timer.
 */
/obj/machinery/status_display/door_timer
	name = "door timer"
	desc = "A remote control for a door."
	current_mode = SD_MESSAGE
	req_access = list(ACCESS_SECURITY)
	text_color = "#F44"
	header_text_color = "#F88"

	/// ID of linked machinery/lockers.
	var/id = null
	/// The time at which the timer started.
	var/activation_time = 0
	/// The time offset from the activation time before releasing.
	var/timer_duration = 0
	/// Is the timer on?
	var/timing = FALSE
	///List of weakrefs to nearby doors
	var/list/doors = list()
	///List of weakrefs to nearby flashers
	var/list/flashers = list()
	///List of weakrefs to nearby closets
	var/list/closets = list()
	///Channel to report prisoneer's release
	var/broadcast_channel = RADIO_CHANNEL_SECURITY

/obj/machinery/status_display/door_timer/Initialize(mapload)
	. = ..()

	if(id != null)
		for(var/obj/machinery/door/window/brigdoor/M in urange(20, src))
			if (M.id == id)
				doors += WEAKREF(M)

		for(var/obj/machinery/door/airlock/security/M in urange(20, src))
			if (M.id == id)
				doors += WEAKREF(M)

		for(var/obj/machinery/flasher/F in urange(20, src))
			if(F.id == id)
				flashers += WEAKREF(F)

		for(var/obj/structure/closet/secure_closet/brig/C in urange(20, src))
			if(C.id == id)
				closets += WEAKREF(C)

	if(!length(doors) && !length(flashers) && length(closets))
		atom_break()

	RegisterSignal(SSdcs, COMSIG_GLOB_GREY_TIDE, PROC_REF(grey_tide))

//Main door timer loop, if it's timing and time is >0 reduce time by 1.
// if it's less than 0, open door, reset timer
// update the door_timer window and the icon
/obj/machinery/status_display/door_timer/process()
	if(machine_stat & (NOPOWER|BROKEN))
		// No power, no processing.
		update_appearance()
		return PROCESS_KILL

	if(!timing)
		return PROCESS_KILL

	if(world.time - activation_time >= timer_duration)
		timer_end() // open doors, reset timer, clear status screen
	update_content()

/**
 * Update the display content.
 */
/obj/machinery/status_display/door_timer/proc/update_content()
	var/time_left = time_left(seconds = TRUE)

	if(time_left == 0)
		set_messages("", "")
		return

	var/disp1 = name
	var/disp2 = "[add_leading(num2text((time_left / 60) % 60), 2, "0")]:[add_leading(num2text(time_left % 60), 2, "0")]"
	set_messages(disp1, disp2)

/**
 * Starts counting down the timer and closes linked the door.
 * The timer is expected to have already been set by set_timer()
 */
/obj/machinery/status_display/door_timer/proc/timer_start()
	if(machine_stat & (NOPOWER|BROKEN))
		return 0

	activation_time = world.time
	timing = TRUE
	begin_processing()

	for(var/datum/weakref/door_ref as anything in doors)
		var/obj/machinery/door/window/brigdoor/door = door_ref.resolve()
		if(!door)
			doors -= door_ref
			continue
		if(door.density)
			continue
		INVOKE_ASYNC(door, TYPE_PROC_REF(/obj/machinery/door/window/brigdoor, close))

	for(var/datum/weakref/closet_ref as anything in closets)
		var/obj/structure/closet/secure_closet/brig/closet = closet_ref.resolve()
		if(!closet)
			closets -= closet_ref
			continue
		if(closet.broken)
			continue
		if(closet.opened && !closet.close())
			continue
		closet.locked = TRUE
		closet.update_appearance()
	return 1

/**
 * Stops the timer and resets the timer to 0, and opens the linked door.
 * Arguments:
 * * forced - TRUE if it was forced to stop rather than timing out. Will skip radioing, etc.
 */
/obj/machinery/status_display/door_timer/proc/timer_end(forced = FALSE)
	if(machine_stat & (NOPOWER|BROKEN))
		return 0

	if(!forced)
		aas_config_announce(/datum/aas_config_entry/brig_cell_release_announcement, list("CELL" = name), src, list(broadcast_channel))

	timing = FALSE
	activation_time = 0
	set_timer(0)
	end_processing()

	for(var/datum/weakref/door_ref as anything in doors)
		var/obj/machinery/door/window/brigdoor/door = door_ref.resolve()
		if(!door)
			doors -= door_ref
			continue
		if(!door.density)
			continue
		INVOKE_ASYNC(door, TYPE_PROC_REF(/obj/machinery/door/window/brigdoor, open))

	for(var/datum/weakref/closet_ref as anything in closets)
		var/obj/structure/closet/secure_closet/brig/closet = closet_ref.resolve()
		if(!closet)
			closets -= closet_ref
			continue
		if(closet.broken)
			continue
		if(closet.opened)
			continue
		closet.locked = FALSE
		closet.update_appearance()

	return 1

/**
 * Return time left.
 * Arguments:
 * * seconds - Return the time in seconds if TRUE, else deciseconds.
 */
/obj/machinery/status_display/door_timer/proc/time_left(seconds = FALSE)
	. = max(0, timer_duration + (activation_time ? activation_time - world.time : 0))
	if(seconds)
		. /= (1 SECONDS)

/**
 * Set the timer. Does NOT automatically start counting down, but does update the display.
 *
 * returns FALSE if no change occurred
 *
 * Arguments:
 * value - time in deciseconds to set the timer for.
 */
/obj/machinery/status_display/door_timer/proc/set_timer(value)
	var/new_time = clamp(value, 0, MAX_TIMER)
	. = new_time != timer_duration //return 1 on change
	timer_duration = new_time
	update_content()

/obj/machinery/status_display/door_timer/ui_interact(mob/user, datum/tgui/ui)
	ui = SStgui.try_update_ui(user, src, ui)
	if(!ui)
		ui = new(user, src, "BrigTimer", name)
		ui.open()

/obj/machinery/status_display/door_timer/ui_data()
	var/list/data = list()
	var/time_left = time_left(seconds = TRUE)
	data["seconds"] = round(time_left % 60)
	data["minutes"] = round((time_left - data["seconds"]) / 60)
	data["timing"] = timing
	data["flash_charging"] = FALSE
	for(var/datum/weakref/flash_ref as anything in flashers)
		var/obj/machinery/flasher/flasher = flash_ref.resolve()
		if(!flasher)
			flashers -= flash_ref
			continue
		if(!COOLDOWN_FINISHED(flasher, flash_cooldown))
			data["flash_charging"] = TRUE
			break
	return data

/obj/machinery/status_display/door_timer/ui_act(action, list/params, datum/tgui/ui, datum/ui_state/state)
	. = ..()
	if(.)
		return

	. = TRUE

	var/mob/user = usr

	if(!allowed(usr))
		to_chat(usr, span_warning("Access denied."))
		return FALSE

	switch(action)
		if("time")
			var/value = text2num(params["adjust"])
			if(value)
				. = set_timer(timer_duration + value)
				user.investigate_log("modified the timer by [value/10] seconds for cell [id], currently [time_left(seconds = TRUE)]", INVESTIGATE_RECORDS)
				user.log_message("modified the timer by [value/10] seconds for cell [id], currently [time_left(seconds = TRUE)]", LOG_ATTACK)
		if("start")
			timer_start()
			user.investigate_log("has started [id]'s timer of [time_left(seconds = TRUE)] seconds", INVESTIGATE_RECORDS)
			user.log_message("has started [id]'s timer of [time_left(seconds = TRUE)] seconds", LOG_ATTACK)
		if("stop")
			user.investigate_log("has stopped [id]'s timer of [time_left(seconds = TRUE)] seconds", INVESTIGATE_RECORDS)
			user.log_message("has stopped [id]'s timer of [time_left(seconds = TRUE)] seconds", LOG_ATTACK)
			timer_end(forced = TRUE)
		if("flash")
			user.investigate_log("has flashed cell [id]", INVESTIGATE_RECORDS)
			user.log_message("has flashed cell [id]", LOG_ATTACK)
			for(var/datum/weakref/flash_ref as anything in flashers)
				var/obj/machinery/flasher/flasher = flash_ref.resolve()
				if(!flasher)
					flashers -= flash_ref
					continue
				flasher.flash()
		if("preset")
			var/preset = params["preset"]
			var/preset_time = time_left()
			switch(preset)
				if("short")
					preset_time = PRESET_SHORT
				if("medium")
					preset_time = PRESET_MEDIUM
				if("long")
					preset_time = PRESET_LONG
			. = set_timer(preset_time)
			user.investigate_log("set cell [id]'s timer to [preset_time/10] seconds", INVESTIGATE_RECORDS)
			user.log_message("set cell [id]'s timer to [preset_time/10] seconds", LOG_ATTACK)
			if(timing)
				activation_time = world.time
		else
			. = FALSE

/obj/machinery/status_display/door_timer/proc/grey_tide(datum/source, list/grey_tide_areas)
	SIGNAL_HANDLER

	if(!is_station_level(z))
		return

	for(var/area_type in grey_tide_areas)
		if(!istype(get_area(src), area_type))
			continue
		timer_end(forced = TRUE)

/datum/aas_config_entry/brig_cell_release_announcement
	name = "Security Alert: Cell Timer Expired"
	announcement_lines_map = list(
		"Message" = "Timer for %CELL has expired. Releasing prisoner.",
	)
	vars_and_tooltips_map = list(
		"CELL" = "will be replaced with the cell name.",
	)

#undef PRESET_SHORT
#undef PRESET_MEDIUM
#undef PRESET_LONG
#undef MAX_TIMER
