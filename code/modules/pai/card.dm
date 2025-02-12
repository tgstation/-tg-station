/obj/item/pai_card
	custom_premium_price = PAYCHECK_COMMAND * 1.25
	desc = "Downloads personal AI assistants to accompany its owner or others."
	icon = 'icons/obj/aicards.dmi'
	icon_state = "pai"
	inhand_icon_state = "electronic"
	lefthand_file = 'icons/mob/inhands/items/devices_lefthand.dmi'
	name = "personal AI device"
	resistance_flags = FIRE_PROOF | ACID_PROOF | INDESTRUCTIBLE
	righthand_file = 'icons/mob/inhands/items/devices_righthand.dmi'
	slot_flags = ITEM_SLOT_BELT
	w_class = WEIGHT_CLASS_SMALL
	worn_icon_state = "electronic"

	/// Spam alert prevention
	var/alert_cooldown
	/// The icon displayed on the card's screen.
	var/datum/pai_screen_image/screen_image = /datum/pai_screen_image/off
	/// Any pAI personalities inserted
	var/mob/living/silicon/pai/pai
	/// Prevents a crew member from hitting "request pAI" repeatedly
	var/request_spam = FALSE

/obj/item/pai_card/Initialize(mapload)
	. = ..()

	update_appearance()
	SSpai.pai_card_list += src
	ADD_TRAIT(src, TRAIT_CASTABLE_LOC, INNATE_TRAIT)

/obj/item/pai_card/attackby(obj/item/used, mob/user, params)
	if(pai && istype(used, /obj/item/encryptionkey))
		if(!pai.encrypt_mod)
			to_chat(user, span_alert("Encryption Key ports not configured."))
			return
		pai.radio.attackby(used, user, params)
		to_chat(user, span_notice("You insert [used] into the [src]."))
		return
	return ..()

/obj/item/pai_card/attack_self(mob/user)
	if(!in_range(src, user))
		return
	ui_interact(user)

/obj/item/pai_card/Destroy()
	//Will stop people throwing friend pAIs into the singularity so they can respawn
	SSpai.pai_card_list.Remove(src)
	if(!QDELETED(pai))
		QDEL_NULL(pai)
	return ..()

/obj/item/pai_card/emag_act(mob/user)
	if(pai)
		return pai.handle_emag(user)
	return FALSE

/obj/item/pai_card/emp_act(severity)
	. = ..()
	if (. & EMP_PROTECT_SELF)
		return
	if(pai && !pai.holoform)
		pai.emp_act(severity)

/obj/item/pai_card/proc/on_pai_del(atom/source)
	SIGNAL_HANDLER
	if(QDELETED(src))
		return
	pai = null
	screen_image = initial(screen_image)
	update_appearance()

/obj/item/pai_card/on_saboteur(datum/source, disrupt_duration)
	. = ..()
	if(pai)
		return pai.on_saboteur(source, disrupt_duration)

/obj/item/pai_card/suicide_act(mob/living/user)
	user.visible_message(span_suicide("[user] is staring sadly at [src]! [user.p_They()] can't keep living without real human intimacy!"))
	return OXYLOSS

/obj/item/pai_card/update_overlays()
	. = ..()
	. += image(icon = screen_image.icon, icon_state = screen_image.icon_state)
	if(pai?.hacking_cable)
		. += "[initial(icon_state)]-connector"

/obj/item/pai_card/vv_edit_var(vname, vval)
	. = ..()
	if(vname == NAMEOF(src, screen_image))
		update_appearance()

/obj/item/pai_card/ui_interact(mob/user, datum/tgui/ui)
	. = ..()
	ui = SStgui.try_update_ui(user, src, ui)
	if(!ui)
		ui = new(user, src, "PaiCard")
		ui.open()

/obj/item/pai_card/ui_status(mob/user, datum/ui_state/state)
	if(user in get_nested_locs(src))
		return UI_INTERACTIVE
	return ..()

/obj/item/pai_card/ui_static_data(mob/user)
	. = ..()
	.["range_max"] = HOLOFORM_MAX_RANGE
	.["range_min"] = HOLOFORM_MIN_RANGE

/obj/item/pai_card/ui_data(mob/user)
	. = ..()
	var/list/data = list()
	if(!pai)
		data["candidates"] = pool_candidates() || list()
		return data
	data["pai"] = list(
		can_holo = pai.can_holo,
		dna = pai.master_dna,
		emagged = pai.emagged,
		laws = pai.laws.supplied,
		master = pai.master_name,
		name = pai.name,
		transmit = pai.can_transmit,
		receive = pai.can_receive,
		range = pai.leash?.distance,
	)
	return data

/obj/item/pai_card/ui_act(action, list/params, datum/tgui/ui)
	. = ..()
	if(.)
		return TRUE
	// Actions that don't require a pAI
	if(action == "download")
		download_candidate(usr, params["ckey"])
		return TRUE
	if(action == "request")
		find_pai(usr)
		return TRUE
	// pAI specific actions.
	if(!pai)
		return FALSE
	switch(action)
		if("fix_speech")
			pai.fix_speech()
			return TRUE
		if("reset_software")
			pai.reset_software()
			return TRUE
		if("set_dna")
			pai.set_dna(usr)
			return TRUE
		if("set_laws")
			pai.set_laws(usr)
			return TRUE
		if("toggle_holo")
			pai.toggle_holo()
			return TRUE
		if("toggle_radio")
			pai.toggle_radio(params["option"])
			return TRUE
		if("increase_range")
			pai.increment_range(1)
			return TRUE
		if("decrease_range")
			pai.increment_range(-1)
			return TRUE
		if("wipe_pai")
			pai.wipe_pai(usr)
			ui.close()
			return TRUE
	return FALSE

/** Flashes the pai card screen */
/obj/item/pai_card/proc/add_alert()
	if(pai)
		return
	add_overlay(
		list(mutable_appearance(icon, "[initial(icon_state)]-alert"),
			emissive_appearance(icon, "[initial(icon_state)]-alert", src, alpha = src.alpha)))

/** Removes any overlays */
/obj/item/pai_card/proc/remove_alert()
	if(pai)
		return
	cut_overlays()

/** Alerts pAI cards that someone has submitted candidacy */
/obj/item/pai_card/proc/alert_update()
	if(!COOLDOWN_FINISHED(src, alert_cooldown))
		return
	COOLDOWN_START(src, alert_cooldown, 5 SECONDS)
	add_alert()
	addtimer(CALLBACK(src, PROC_REF(remove_alert)), 5 SECONDS)
	playsound(src, 'sound/machines/ping.ogg', 30, TRUE)
	visible_message(span_notice("[src] flashes a message across its screen: New personalities available for download!"), blind_message = span_notice("[src] vibrates with an alert."))

/**
 * Downloads a candidate from the list and removes them from SSpai.candidates
 *
 * @param {string} ckey The ckey of the candidate to download
 *
 * @returns {boolean} - TRUE if the candidate was downloaded, FALSE if not
 */
/obj/item/pai_card/proc/download_candidate(mob/user, ckey)
	if(pai)
		return FALSE
	var/datum/pai_candidate/candidate = SSpai.candidates[ckey]
	if(!candidate?.check_ready())
		balloon_alert(user, "download interrupted")
		return FALSE
	var/mob/living/silicon/pai/new_pai = new(src)
	new_pai.name = candidate.name || pick(GLOB.ninja_names)
	new_pai.real_name = new_pai.name
	new_pai.PossessByPlayer(candidate.ckey)
	set_personality(new_pai)
	SSpai.candidates -= ckey
	return TRUE

/**
 * Pings ghosts to announce that someone is requesting a pAI
 *
 * @param {mob} user - The user who is requesting a pAI
 *
 * @returns {boolean} - TRUE if the pAI was requested, FALSE if not
 */
/obj/item/pai_card/proc/find_pai(mob/user)
	if(pai)
		return FALSE
	if(!(GLOB.ghost_role_flags & GHOSTROLE_SILICONS))
		balloon_alert(user, "unavailable: NT blacklisted")
		return FALSE
	if(request_spam)
		balloon_alert(user, "request sent too recently")
		return FALSE
	request_spam = TRUE
	playsound(src, 'sound/machines/ping.ogg', 20, TRUE)
	balloon_alert(user, "pAI assistance requested")
	var/mutable_appearance/alert_overlay = mutable_appearance('icons/obj/aicards.dmi', "pai")

	notify_ghosts(
		"[user] is requesting a pAI companion! Use the pAI button to submit yourself as one.",
		source = user,
		header = "pAI Request!",
		alert_overlay = alert_overlay,
		notify_flags = NOTIFY_CATEGORY_NOFLASH,
		ignore_key = POLL_IGNORE_PAI,
	)

	addtimer(VARSET_CALLBACK(src, request_spam, FALSE), PAI_SPAM_TIME, TIMER_UNIQUE|TIMER_DELETE_ME)
	return TRUE

/**
 * Gathers a list of candidates to display in the download candidate
 * window. If the candidate isn't marked ready, ie they have not
 * pressed submit, they will be skipped over.
 *
 * @returns - An array of candidate objects.
 */
/obj/item/pai_card/proc/pool_candidates()
	var/list/candidates = list()
	if(pai || !length(SSpai?.candidates))
		return candidates
	for(var/key in SSpai.candidates)
		var/datum/pai_candidate/candidate = SSpai.candidates[key]
		if(!candidate?.check_ready())
			continue
		candidates += list(list(
			ckey = candidate.ckey,
			comments = candidate.comments,
			description = candidate.description,
			name = candidate.name,
		))
	return candidates

/**
 * Sets the personality on the current pai_card
 *
 * @param {silicon/pai} downloaded - The new pAI to load into the card.
 */
/obj/item/pai_card/proc/set_personality(mob/living/silicon/pai/downloaded)
	if(pai)
		return FALSE
	pai = downloaded
	RegisterSignal(pai, COMSIG_QDELETING, PROC_REF(on_pai_del))
	screen_image = /datum/pai_screen_image/neutral
	update_appearance()
	playsound(src, 'sound/effects/pai_boot.ogg', 50, TRUE, -1)
	audible_message("[src] plays a cheerful startup noise!")
	return TRUE
