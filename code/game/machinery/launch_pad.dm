#define BEAM_FADE_TIME (1 SECONDS)

/obj/machinery/launchpad
	name = "bluespace launchpad"
	desc = "A bluespace pad able to thrust matter through bluespace, teleporting it to or from nearby locations."
	icon = 'icons/obj/machines/telepad.dmi'
	icon_state = "lpad-idle"
	active_power_usage = BASE_MACHINE_ACTIVE_CONSUMPTION * 2.5
	hud_possible = list(DIAG_LAUNCHPAD_HUD)
	interaction_flags_mouse_drop = NEED_DEXTERITY | NEED_HANDS
	circuit = /obj/item/circuitboard/machine/launchpad

	/// The beam icon
	var/icon_teleport = "lpad-beam"
	/// To prevent briefcase pad deconstruction and such
	var/stationary = TRUE
	/// What to name the launchpad in the console
	var/display_name = "Launchpad"
	/// The speed of the teleportation
	var/teleport_speed = 35
	/// Max range of the launchpad
	var/range = 10
	/// If it's in the process of teleporting
	var/teleporting = FALSE
	/// The power efficiency of the launchpad
	var/power_efficiency = 1
	/// Current x target
	var/x_offset = 0
	/// Current y target
	var/y_offset = 0
	/// The icon to use for the indicator
	var/indicator_icon = "launchpad_target"
	/// Determines if the bluespace launchpad is blatantly obvious on teleportation.
	var/hidden = FALSE
	/// The beam on teleportation
	var/teleport_beam = "sm_arc_supercharged"

/obj/machinery/launchpad/Initialize(mapload)
	. = ..()
	prepare_huds()
	for(var/datum/atom_hud/data/diagnostic/diag_hud in GLOB.huds)
		diag_hud.add_atom_to_hud(src)

	update_hud()

/obj/machinery/launchpad/RefreshParts()
	. = ..()
	var/max_range_multiplier = 0
	for(var/datum/stock_part/servo/servo in component_parts)
		max_range_multiplier += servo.tier
	range = initial(range)
	range *= max_range_multiplier

/obj/machinery/launchpad/on_changed_z_level(turf/old_turf, turf/new_turf, same_z_layer, notify_contents)
	if(same_z_layer && !QDELETED(src))
		update_hud()
	return ..()

/obj/machinery/launchpad/Destroy()
	for(var/datum/atom_hud/data/diagnostic/diag_hud in GLOB.huds)
		diag_hud.remove_atom_from_hud(src)
	return ..()

/obj/machinery/launchpad/examine(mob/user)
	. = ..()
	if(in_range(user, src) || isobserver(user))
		. += span_notice("The status display reads: Maximum range: <b>[range]</b> units.")

/obj/machinery/launchpad/multitool_act(mob/living/user, obj/item/multitool/multi)
	. = NONE
	if(!panel_open)
		return

	multi.set_buffer(src)
	balloon_alert(user, "saved to buffer")
	return ITEM_INTERACT_SUCCESS

/obj/machinery/launchpad/attackby(obj/item/weapon, mob/user, params)
	if(!stationary)
		return ..()

	if(default_deconstruction_screwdriver(user, "lpad-idle-open", "lpad-idle", weapon))
		update_indicator()
		return

	if(default_deconstruction_crowbar(weapon))
		return

/obj/machinery/launchpad/attack_ghost(mob/dead/observer/ghost)
	. = ..()
	if(.)
		return
	var/target_x = x + x_offset
	var/target_y = y + y_offset
	var/turf/target = locate(target_x, target_y, z)
	ghost.forceMove(target)

/// Updates diagnostic huds
/obj/machinery/launchpad/proc/update_hud()
	var/image/holder = hud_list[DIAG_LAUNCHPAD_HUD]
	var/mutable_appearance/target = mutable_appearance('icons/effects/effects.dmi', "launchpad_target", ABOVE_NORMAL_TURF_LAYER, src, GAME_PLANE)
	holder.appearance = target

	update_indicator()

	if(stationary)
		AddComponent(/datum/component/usb_port, list(
			/obj/item/circuit_component/bluespace_launchpad,
		))

/// Whether this launchpad can send or receive.
/obj/machinery/launchpad/proc/is_available()
	if(QDELETED(src) || !is_operational || panel_open)
		return FALSE
	return TRUE

/// Updates the indicator icon.
/obj/machinery/launchpad/proc/update_indicator()
	var/image/holder = hud_list[DIAG_LAUNCHPAD_HUD]
	var/turf/target_turf
	if(is_available())
		target_turf = locate(x + x_offset, y + y_offset, z)
	if(target_turf)
		holder.icon_state = indicator_icon
		holder.loc = target_turf
	else
		holder.icon_state = null

/// Sets the offset of the launchpad.
/obj/machinery/launchpad/proc/set_offset(x, y)
	if(teleporting)
		return
	if(!isnull(x) && !isnull(y))
		x_offset = clamp(x, -range, range)
		y_offset = clamp(y, -range, range)
		log_message("changed the launchpad's x and y-offset parameters to X: [x] Y: [y].", LOG_GAME, log_globally = FALSE)
	else if(!isnull(x))
		x_offset = clamp(x, -range, range)
		log_message("changed the launchpad's x-offset parameter to X: [x].", LOG_GAME, log_globally = FALSE)
	else if(!isnull(y))
		y_offset = clamp(y, -range, range)
		log_message("changed the launchpad's y-offset parameter to Y: [y].", LOG_GAME, log_globally = FALSE)
	update_indicator()

/obj/effect/ebeam/launchpad/Initialize(mapload)
	. = ..()
	animate(src, alpha = 0, flags = ANIMATION_PARALLEL, time = BEAM_FADE_TIME)

/// Checks if the launchpad can teleport.
/obj/machinery/launchpad/proc/teleport_checks()
	if(!is_available())
		return "ERROR: Launchpad not operative. Make sure the launchpad is ready and powered."

	if(teleporting)
		return "ERROR: Launchpad busy."

	var/area/surrounding = get_area(src)
	if(is_centcom_level(z) || istype(surrounding, /area/shuttle/supply) ||istype(surrounding, /area/shuttle/transport))
		return "ERROR: Launchpad not operative. Heavy area shielding makes teleporting impossible."

	return null

/// Performs the teleport.
/// sending - TRUE/FALSE depending on if the launch pad is teleporting *to* or *from* the target.
/// alternate_log_name - An alternative name to use in logs, if `user` is not present..
/obj/machinery/launchpad/proc/doteleport(mob/user, sending, alternate_log_name = null)

	var/turf/dest = get_turf(src)

	var/target_x = x + x_offset
	var/target_y = y + y_offset
	var/turf/target = locate(target_x, target_y, z)
	var/area/A = get_area(target)

	flick(icon_teleport, src)

	//Change the indicator's icon to show that we're teleporting
	if(sending)
		indicator_icon = "launchpad_launch"
	else
		indicator_icon = "launchpad_pull"
	update_indicator()

	playsound(get_turf(src), 'sound/items/weapons/flash.ogg', 25, TRUE)
	teleporting = TRUE

	if(!hidden)
		playsound(target, 'sound/items/weapons/flash.ogg', 25, TRUE)
		var/datum/effect_system/spark_spread/quantum/spark_system = new /datum/effect_system/spark_spread/quantum()
		spark_system.set_up(5, TRUE, target)
		spark_system.start()

	sleep(teleport_speed)

	//Set the indicator icon back to normal
	indicator_icon = "launchpad_target"
	update_indicator()

	if(!is_available())
		return

	teleporting = FALSE
	if(!hidden)
		// Takes twice as long to make sure it properly fades out.
		Beam(target, icon_state = teleport_beam, time = BEAM_FADE_TIME*2, beam_type = /obj/effect/ebeam/launchpad)
		playsound(target, 'sound/items/weapons/emitter2.ogg', 25, TRUE)

	// use a lot of power
	use_energy(active_power_usage)

	var/turf/source = target
	var/list/log_msg = list()
	log_msg += "[alternate_log_name || key_name(user)] triggered a teleport "

	if(sending)
		source = dest
		dest = target

	playsound(get_turf(src), 'sound/items/weapons/emitter2.ogg', 25, TRUE)
	var/first = TRUE
	for(var/atom/movable/ROI in source)
		if(ROI == src)
			continue
		if(!istype(ROI) || isdead(ROI) || iseyemob(ROI) || istype(ROI, /obj/effect/dummy/phased_mob))
			continue//don't teleport these
		var/on_chair = ""
		if(ROI.anchored)// if it's anchored, don't teleport
			if(isliving(ROI))
				var/mob/living/L = ROI
				if(L.buckled)
					// TP people on office chairs
					if(L.buckled.anchored)
						continue
					on_chair = " (on a chair)"
				else
					continue
			else
				continue
		if(!first)
			log_msg += ", "
		if(ismob(ROI))
			var/mob/T = ROI
			log_msg += "[key_name(T)][on_chair]"
		else
			log_msg += "[ROI.name]"
			if (istype(ROI, /obj/structure/closet))
				log_msg += " ("
				var/first_inner = TRUE
				for(var/atom/movable/Q as mob|obj in ROI)
					if(!first_inner)
						log_msg += ", "
					first_inner = FALSE
					if(ismob(Q))
						log_msg += "[key_name(Q)]"
					else
						log_msg += "[Q.name]"
				if(first_inner)
					log_msg += "empty"
				log_msg += ")"
		do_teleport(ROI, dest, no_effects = !first, channel = TELEPORT_CHANNEL_BLUESPACE)
		first = FALSE

	if (first)
		log_msg += "nothing"
	log_msg += " [sending ? "to" : "from"] [target_x], [target_y], [z] ([A ? A.name : "null area"])"
	log_game(log_msg.Join())

//Starts in the briefcase. Don't spawn this directly, or it will runtime when closing.
/obj/machinery/launchpad/briefcase
	name = "briefcase launchpad"
	desc = "A portable bluespace pad able to thrust matter through bluespace, teleporting it to or from nearby locations. Controlled via remote."
	icon_state = "blpad-idle"
	icon_teleport = "blpad-beam"
	anchored = FALSE
	use_power = NO_POWER_USE
	active_power_usage = 0
	teleport_speed = 20
	range = 8
	stationary = FALSE
	hidden = TRUE
	var/closed = TRUE
	var/obj/item/storage/briefcase/launchpad/briefcase

/obj/machinery/launchpad/briefcase/Initialize(mapload, _briefcase)
	. = ..()
	if(!_briefcase)
		stack_trace("[src] spawned without a briefcase.")
		return INITIALIZE_HINT_QDEL
	briefcase = _briefcase

/obj/machinery/launchpad/briefcase/Destroy()
	if(!QDELETED(briefcase))
		qdel(briefcase)
	briefcase = null
	return ..()

/obj/machinery/launchpad/briefcase/is_available()
	if(closed)
		return FALSE
	if(panel_open)
		return FALSE
	return TRUE

/obj/machinery/launchpad/briefcase/mouse_drop_dragged(atom/over_object, mob/user, src_location, over_location, params)
	if(over_object == user)
		if(!briefcase)
			return
		user.visible_message(span_notice("[usr] starts closing [src]..."), span_notice("You start closing [src]..."))
		if(do_after(user, 3 SECONDS, target = user))
			user.put_in_hands(briefcase)
			moveToNullspace() //hides it from suitcase contents
			closed = TRUE
			update_indicator()

/obj/machinery/launchpad/briefcase/attackby(obj/item/I, mob/user, params)
	if(istype(I, /obj/item/launchpad_remote))
		var/obj/item/launchpad_remote/L = I
		if(L.pad == WEAKREF(src)) //do not attempt to link when already linked
			return ..()
		L.pad = WEAKREF(src)
		to_chat(user, span_notice("You link [src] to [L]."))
	else
		return ..()

//Briefcase item that contains the launchpad.
/obj/item/storage/briefcase/launchpad
	var/obj/machinery/launchpad/briefcase/pad

/obj/item/storage/briefcase/launchpad/Initialize(mapload)
	pad = new(null, src) //spawns pad in nullspace to hide it from briefcase contents
	. = ..()

/obj/item/storage/briefcase/launchpad/Destroy()
	if(!QDELETED(pad))
		qdel(pad)
	pad = null
	return ..()

/obj/item/storage/briefcase/launchpad/PopulateContents()
	new /obj/item/pen(src)
	new /obj/item/launchpad_remote(src, pad)

/obj/item/storage/briefcase/launchpad/attack_self(mob/user)
	if(!isturf(user.loc)) //no setting up in a locker
		return
	add_fingerprint(user)
	user.visible_message(span_notice("[user] starts setting down [src]..."), span_notice("You start setting up [pad]..."))
	if(do_after(user, 3 SECONDS, target = user))
		pad.forceMove(get_turf(src))
		pad.update_indicator()
		pad.closed = FALSE
		user.transferItemToLoc(src, pad, TRUE)
		atom_storage.close_all()

/obj/item/storage/briefcase/launchpad/tool_act(mob/living/user, obj/item/tool, list/modifiers)
	if(!istype(tool, /obj/item/launchpad_remote))
		return ..()
	var/obj/item/launchpad_remote/remote = tool
	if(remote.pad == WEAKREF(src.pad))
		return ..()
	remote.pad = WEAKREF(src.pad)
	to_chat(user, span_notice("You link [pad] to [remote]."))
	return ITEM_INTERACT_BLOCKING

/obj/item/launchpad_remote
	name = "folder"
	desc = "A folder."
	icon = 'icons/obj/service/bureaucracy.dmi'
	icon_state = "folder"
	w_class = WEIGHT_CLASS_SMALL
	var/sending = TRUE
	//A weakref to our linked pad
	var/datum/weakref/pad

/obj/item/launchpad_remote/Initialize(mapload, pad) //remote spawns linked to the briefcase pad
	. = ..()
	src.pad = WEAKREF(pad)

/obj/item/launchpad_remote/attack_self(mob/user)
	. = ..()
	ui_interact(user)
	to_chat(user, span_notice("[src] projects a display onto your retina."))


/obj/item/launchpad_remote/ui_state(mob/user)
	return GLOB.inventory_state

/obj/item/launchpad_remote/ui_interact(mob/user, datum/tgui/ui)
	ui = SStgui.try_update_ui(user, src, ui)
	if(!ui)
		ui = new(user, src, "LaunchpadRemote")
		ui.open()
	ui.set_autoupdate(TRUE)

/obj/item/launchpad_remote/ui_data(mob/user)
	var/list/data = list()
	var/obj/machinery/launchpad/briefcase/our_pad = pad.resolve()
	data["has_pad"] = our_pad ? TRUE : FALSE
	if(our_pad)
		data["pad_closed"] = our_pad.closed
	if(!our_pad || our_pad.closed)
		return data

	data["pad_name"] = our_pad.display_name
	data["range"] = our_pad.range
	data["x"] = our_pad.x_offset
	data["y"] = our_pad.y_offset
	return data

/obj/item/launchpad_remote/proc/teleport(mob/user, obj/machinery/launchpad/pad)
	if(QDELETED(pad))
		to_chat(user, span_warning("ERROR: Launchpad not responding. Check launchpad integrity."))
		return
	var/error_reason = pad.teleport_checks()
	if(error_reason)
		to_chat(user, span_warning(error_reason))
		return
	pad.doteleport(user, sending)

/obj/item/launchpad_remote/ui_act(action, list/params, datum/tgui/ui, datum/ui_state/state)
	. = ..()
	if(.)
		return
	var/obj/machinery/launchpad/briefcase/our_pad = pad.resolve()
	if(!our_pad)
		pad = null
		return TRUE
	switch(action)
		if("set_pos")
			var/new_x = text2num(params["x"])
			var/new_y = text2num(params["y"])
			// sanitizes our ranges for us
			our_pad.set_offset(new_x, new_y)
			. = TRUE
		if("move_pos")
			var/plus_x = text2num(params["x"])
			var/plus_y = text2num(params["y"])
			// sanitizes our ranges for us
			our_pad.set_offset(
				x = our_pad.x_offset + plus_x,
				y = our_pad.y_offset + plus_y
			)
			. = TRUE
		if("rename")
			. = TRUE
			var/new_name = reject_bad_name(params["name"], allow_numbers = TRUE, max_length = MAX_NAME_LEN, cap_after_symbols = FALSE)
			if(!new_name)
				return
			our_pad.display_name = new_name
		if("remove")
			. = TRUE
			if(usr && tgui_alert(usr, "Are you sure?", "Unlink Launchpad", list("Confirm", "Abort")) == "I'm Sure")
				our_pad = null
		if("launch")
			sending = TRUE
			teleport(usr, our_pad)
			. = TRUE
		if("pull")
			sending = FALSE
			teleport(usr, our_pad)
			. = TRUE

#undef BEAM_FADE_TIME

/obj/item/circuit_component/bluespace_launchpad
	display_name = "Bluespace Launchpad"
	desc = "Teleports anything to and from any location on the station. Doesn't use actual GPS coordinates, but rather offsets from the launchpad itself. Can only go as far as the launchpad can go, which depends on its parts."

	var/datum/port/input/x_pos
	var/datum/port/input/y_pos
	var/datum/port/input/send_trigger
	var/datum/port/input/retrieve_trigger

	var/datum/port/output/sent
	var/datum/port/output/retrieved
	var/datum/port/output/on_fail
	var/datum/port/output/why_fail

	var/obj/machinery/launchpad/attached_launchpad

/obj/item/circuit_component/bluespace_launchpad/get_ui_notices()
	. = ..()

	if(isnull(attached_launchpad))
		return

	. += create_ui_notice("Minimum Range: [-attached_launchpad.range]", "orange", "minus")
	. += create_ui_notice("Maximum Range: [attached_launchpad.range]", "orange", "plus")

/obj/item/circuit_component/bluespace_launchpad/populate_ports()
	x_pos = add_input_port("X offset", PORT_TYPE_NUMBER)
	y_pos = add_input_port("Y offset", PORT_TYPE_NUMBER)
	send_trigger = add_input_port("Send", PORT_TYPE_SIGNAL)
	retrieve_trigger = add_input_port("Retrieve", PORT_TYPE_SIGNAL)

	sent = add_output_port("Sent", PORT_TYPE_SIGNAL)
	retrieved = add_output_port("Retrieved", PORT_TYPE_SIGNAL)
	why_fail = add_output_port("Fail reason", PORT_TYPE_STRING)
	on_fail = add_output_port("Failed", PORT_TYPE_SIGNAL)

/obj/item/circuit_component/bluespace_launchpad/register_usb_parent(atom/movable/shell)
	. = ..()
	if(istype(shell, /obj/machinery/launchpad))
		attached_launchpad = shell

/obj/item/circuit_component/bluespace_launchpad/unregister_usb_parent(atom/movable/shell)
	attached_launchpad = null
	return ..()

/obj/item/circuit_component/bluespace_launchpad/input_received(datum/port/input/port)
	if(!attached_launchpad)
		why_fail.set_output("Not connected!")
		on_fail.set_output(COMPONENT_SIGNAL)
		return

	if(abs(x_pos.value) > attached_launchpad.range || abs(y_pos.value) > attached_launchpad.range)
		why_fail.set_output("Out of range!")
		on_fail.set_output(COMPONENT_SIGNAL)
		return

	attached_launchpad.set_offset(x_pos.value, y_pos.value)

	if(COMPONENT_TRIGGERED_BY(port, x_pos))
		x_pos.set_value(attached_launchpad.x_offset)
		return

	if(COMPONENT_TRIGGERED_BY(port, y_pos))
		y_pos.set_value(attached_launchpad.y_offset)
		return


	var/checks = attached_launchpad.teleport_checks()
	if(!isnull(checks))
		why_fail.set_output(checks)
		on_fail.set_output(COMPONENT_SIGNAL)
		return

	if(COMPONENT_TRIGGERED_BY(send_trigger, port))
		INVOKE_ASYNC(attached_launchpad, TYPE_PROC_REF(/obj/machinery/launchpad, doteleport), null, TRUE, parent.get_creator())
		sent.set_output(COMPONENT_SIGNAL)

	if(COMPONENT_TRIGGERED_BY(retrieve_trigger, port))
		INVOKE_ASYNC(attached_launchpad, TYPE_PROC_REF(/obj/machinery/launchpad, doteleport), null, FALSE, parent.get_creator())
		retrieved.set_output(COMPONENT_SIGNAL)
