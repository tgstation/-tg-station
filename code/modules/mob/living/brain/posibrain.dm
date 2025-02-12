GLOBAL_VAR(posibrain_notify_cooldown)

/obj/item/mmi/posibrain
	name = "positronic brain"
	desc = "A cube of shining metal, four inches to a side and covered in shallow grooves."
	icon = 'icons/obj/devices/assemblies.dmi'
	icon_state = "posibrain"
	base_icon_state = "posibrain"
	w_class = WEIGHT_CLASS_NORMAL
	req_access = list(ACCESS_ROBOTICS)
	braintype = "Android"

	///Message sent to the user when polling ghosts
	var/begin_activation_message = span_notice("You carefully locate the manual activation switch and start the positronic brain's boot process.")
	///Message sent as a visible message on success
	var/success_message = span_notice("The positronic brain pings, and its lights start flashing. Success!")
	///Message sent as a visible message on failure
	var/fail_message = span_notice("The positronic brain buzzes quietly, and the golden lights fade away. Perhaps you could try again?")
	///Visible message sent when a player possesses the brain
	var/new_mob_message = span_notice("The positronic brain chimes quietly.")
	///Examine message when the posibrain has no mob
	var/dead_message = span_deadsay("It appears to be completely inactive. The reset light is blinking.")
	///Examine message when the posibrain cannot poll ghosts due to cooldown
	var/recharge_message = span_warning("The positronic brain isn't ready to activate again yet! Give it some time to recharge.")

	///Can be set to tell ghosts what the brain will be used for
	var/ask_role = ""
	///Role assigned to the newly created mind
	var/posibrain_job_path = /datum/job/positronic_brain
	///World time tick when ghost polling will be available again
	var/next_ask
	///Delay after polling ghosts
	var/ask_delay = 60 SECONDS
	///One of these names is randomly picked as the posibrain's name on possession. If left blank, it will use the global posibrain names
	var/list/possible_names
	///Picked posibrain name
	var/picked_name
	///Whether this positronic brain is currently looking for a ghost to enter it.
	var/searching = FALSE
	///List of all ckeys who has already entered this posibrain once before.
	var/list/ckeys_entered = list()

///Notify ghosts that the posibrain is up for grabs
/obj/item/mmi/posibrain/proc/ping_ghosts(msg, newlymade)
	if(newlymade || GLOB.posibrain_notify_cooldown <= world.time)
		notify_ghosts(
			"[name] [msg] in [get_area(src)]! [ask_role ? "Personality requested: \[[ask_role]\]" : ""]",
			source = src,
			header = "Ghost in the Machine",
			click_interact = TRUE,
			ghost_sound = !newlymade ? 'sound/effects/ghost2.ogg':null,
			ignore_key = POLL_IGNORE_POSIBRAIN,
			notify_flags = (GHOST_NOTIFY_IGNORE_MAPLOAD),
			notify_volume = 75,
		)
		if(!newlymade)
			GLOB.posibrain_notify_cooldown = world.time + ask_delay

/obj/item/mmi/posibrain/attack_self(mob/user)
	if(!brainmob)
		set_brainmob(new /mob/living/brain(src))
	if(!(GLOB.ghost_role_flags & GHOSTROLE_SILICONS))
		to_chat(user, span_warning("Central Command has temporarily outlawed posibrain sentience in this sector..."))
	if(is_occupied())
		to_chat(user, span_warning("This [name] is already active!"))
		return
	if(next_ask > world.time)
		to_chat(user, recharge_message)
		return
	//Start the process of requesting a new ghost.
	to_chat(user, begin_activation_message)
	ping_ghosts("requested", FALSE)
	next_ask = world.time + ask_delay
	searching = TRUE
	update_appearance()
	addtimer(CALLBACK(src, PROC_REF(check_success)), ask_delay)

/obj/item/mmi/posibrain/click_alt(mob/living/user)
	var/input_seed = tgui_input_text(user, "Enter a personality seed", "Enter seed", ask_role, max_length = MAX_NAME_LEN)
	if(isnull(input_seed))
		return CLICK_ACTION_BLOCKING
	if(!user.can_perform_action(src))
		return
	to_chat(user, span_notice("You set the personality seed to \"[input_seed]\"."))
	ask_role = input_seed
	update_appearance()
	return CLICK_ACTION_SUCCESS

/obj/item/mmi/posibrain/proc/check_success()
	searching = FALSE
	update_appearance()
	if(QDELETED(brainmob))
		return
	if(brainmob.client)
		visible_message(success_message)
		playsound(src, 'sound/machines/ping.ogg', 15, TRUE)
	else
		visible_message(fail_message)

///ATTACK GHOST IGNORING PARENT RETURN VALUE
/obj/item/mmi/posibrain/attack_ghost(mob/user)
	activate(user)

/obj/item/mmi/posibrain/proc/is_occupied()
	if(brainmob.key)
		return TRUE
	if(iscyborg(loc))
		var/mob/living/silicon/robot/R = loc
		if(R.mmi == src)
			return TRUE
	return FALSE

///Two ways to activate a positronic brain. A clickable link in the ghost notif, or simply clicking the object itself.
/obj/item/mmi/posibrain/proc/activate(mob/user)
	if(QDELETED(brainmob))
		return
	if(user.ckey in ckeys_entered)
		to_chat(user, span_warning("You cannot re-enter [src] a second time!"))
		return
	if(is_occupied() || is_banned_from(user.ckey, ROLE_POSIBRAIN) || QDELETED(src) || QDELETED(user))
		return
	var/posi_ask = tgui_alert(user, "Become a [name]? (Warning, You can no longer be revived, and all past lives will be forgotten!)", "Confirm", list("Yes","No"))
	if(posi_ask != "Yes" || QDELETED(src))
		return
	if(HAS_TRAIT(brainmob, TRAIT_SUICIDED)) //clear suicide status if the old occupant suicided.
		brainmob.set_suicide(FALSE)
	transfer_personality(user)

/obj/item/mmi/posibrain/transfer_identity(mob/living/carbon/transferred_user)
	name = "[initial(name)] ([transferred_user])"
	brainmob.name = transferred_user.real_name
	brainmob.real_name = transferred_user.real_name
	if(transferred_user.has_dna())
		if(!brainmob.stored_dna)
			brainmob.stored_dna = new /datum/dna/stored(brainmob)
		transferred_user.dna.copy_dna(brainmob.stored_dna)
	brainmob.timeofdeath = transferred_user.timeofdeath
	brainmob.set_stat(CONSCIOUS)
	if(brainmob.mind)
		brainmob.mind.set_assigned_role(SSjob.get_job_type(posibrain_job_path))
	if(transferred_user.mind)
		transferred_user.mind.transfer_to(brainmob)

	brainmob.mind.remove_all_antag_datums()
	brainmob.mind.wipe_memory()
	update_appearance()

///Moves the candidate from the ghost to the posibrain
/obj/item/mmi/posibrain/proc/transfer_personality(mob/candidate)
	if(QDELETED(brainmob))
		return
	if(is_occupied()) //Prevents hostile takeover if two ghosts get the prompt or link for the same brain.
		to_chat(candidate, span_warning("This [name] was taken over before you could get to it! Perhaps it might be available later?"))
		return FALSE
	if(candidate.mind && !isobserver(candidate))
		candidate.mind.transfer_to(brainmob)
	else
		brainmob.PossessByPlayer(candidate.ckey)
	name = "[initial(name)] ([brainmob.name])"
	var/policy = get_policy(ROLE_POSIBRAIN)
	if(policy)
		to_chat(brainmob, policy)
	brainmob.mind.set_assigned_role(SSjob.get_job_type(posibrain_job_path))
	brainmob.set_stat(CONSCIOUS)

	visible_message(new_mob_message)
	check_success()
	ckeys_entered |= brainmob.ckey
	return TRUE


/obj/item/mmi/posibrain/examine(mob/user)
	. = ..()
	if(brainmob?.key)
		switch(brainmob.stat)
			if(CONSCIOUS)
				if(!brainmob.client)
					. += "It appears to be in stand-by mode." //afk
			if(DEAD)
				. += span_deadsay("It appears to be completely inactive.")
	else
		. += "[dead_message]"
		if(ask_role)
			. += span_notice("Current consciousness seed: \"[ask_role]\"")
		. += span_boldnotice("Alt-click to set a consciousness seed, specifying what [src] will be used for. This can help generate a personality interested in that role.")

/obj/item/mmi/posibrain/Initialize(mapload, autoping = TRUE)
	. = ..()
	set_brainmob(new /mob/living/brain(src))
	var/new_name
	if(!LAZYLEN(possible_names))
		new_name = pick(GLOB.posibrain_names)
	else
		new_name = pick(possible_names)
	brainmob.name = "[new_name]-[rand(100, 999)]"
	brainmob.real_name = brainmob.name
	brainmob.forceMove(src)
	brainmob.container = src
	if(autoping)
		ping_ghosts("created", TRUE)

/obj/item/mmi/posibrain/update_icon_state()
	. = ..()
	if(searching)
		icon_state = "[base_icon_state]-searching"
		return
	if(brainmob?.key)
		icon_state = "[base_icon_state]-occupied"
		return
	icon_state = "[base_icon_state]"
	return

/obj/item/mmi/posibrain/attackby(obj/item/O, mob/user, params)
	return

/obj/item/mmi/posibrain/add_mmi_overlay()
	return

/obj/item/mmi/posibrain/display
	name = "display positronic brain"
	desc = "A small positronic brain that doesn't allow the downloading of personalities."

/obj/item/mmi/posibrain/display/is_occupied()
	return TRUE

/// Posibrains but spherical. They can roll around and you can kick them
/obj/item/mmi/posibrain/sphere
	name = "positronic sphere"
	desc = "Recent developments on cost-cutting measures have allowed us to cut positronic brain cubes into twice-as-cheap spheres. \
	Unfortunately, it also allows them to move around the lab via rolling maneuvers."
	icon_state = "spheribrain"
	base_icon_state = "spheribrain"
	immobilize = FALSE
	/// Delay between movements
	var/move_delay = 0.5 SECONDS
	/// when can we move again?
	var/can_move

/obj/item/mmi/posibrain/sphere/Initialize(mapload, autoping)
	. = ..()

	var/matrix/matrix = matrix()
	transform = matrix.Scale(0.8, 0.8)

	brainmob.remove_traits(list(TRAIT_IMMOBILIZED, TRAIT_HANDS_BLOCKED), BRAIN_UNAIDED)

/obj/item/mmi/posibrain/sphere/relaymove(mob/living/user, direction)
	if(isspaceturf(loc) || !direction || mecha)
		return

	if(can_move >= world.time)
		return
	can_move = world.time + move_delay

	// ESCAPE PRISON
	if(ismovable(loc) && prob(25))
		var/obj/item/item = pick(loc.contents)
		if(istype(loc, /obj/item/storage))
			item.forceMove(loc.drop_location()) //throw stuff out of the inventory till we free ourselves!
			playsound(src, SFX_RUSTLE, 30, TRUE)
		return

	// MOVE US
	if(isturf(loc))
		can_move = world.time + move_delay
		try_step_multiz(direction)
		SpinAnimation(move_delay, 1, direction == NORTH || direction == EAST)

/obj/item/mmi/posibrain/sphere/Moved(atom/old_loc, movement_dir, forced, list/old_locs, momentum_change)
	. = ..()
	if(brainmob && isturf(loc))
		anchored = TRUE //anchor so we dont broom ourselves.
		do_sweep(src, brainmob, loc, get_dir(old_loc, loc)) //movement dir doesnt work on objects
		anchored = FALSE

/// Punt the shit across the room
/obj/item/mmi/posibrain/sphere/attack_hand_secondary(mob/user, list/modifiers)
	. = ..()
	if(. == SECONDARY_ATTACK_CANCEL_ATTACK_CHAIN)
		return .
	throw_at(get_edge_target_turf(src, get_dir(user, src)), 7, 1, user)
	user.do_attack_animation(src)
	can_move = world.time + move_delay //pweeze stawp
	return SECONDARY_ATTACK_CANCEL_ATTACK_CHAIN
