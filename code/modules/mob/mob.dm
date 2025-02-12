/**
 * Delete a mob
 *
 * Removes mob from the following global lists
 * * GLOB.mob_list
 * * GLOB.dead_mob_list
 * * GLOB.alive_mob_list
 * * GLOB.all_clockwork_mobs
 *
 * Unsets the focus var
 *
 * Clears alerts for this mob
 *
 * Resets all the observers perspectives to the tile this mob is on
 *
 * qdels any client colours in place on this mob
 *
 * Clears any refs to the mob inside its current location
 *
 * Ghostizes the client attached to this mob
 *
 * If our mind still exists, clear its current var to prevent harddels
 *
 * Parent call
 */
/mob/Destroy()
	if(client)
		stack_trace("Mob with client has been deleted.")
	else if(ckey)
		stack_trace("Mob without client but with associated ckey, [ckey], has been deleted.")

	remove_from_mob_list()
	remove_from_dead_mob_list()
	remove_from_alive_mob_list()
	remove_from_mob_suicide_list()
	focus = null
	if(length(progressbars))
		stack_trace("[src] destroyed with elements in its progressbars list")
		progressbars = null
	for (var/alert in alerts)
		clear_alert(alert, TRUE)
	if(observers?.len)
		for(var/mob/dead/observe as anything in observers)
			observe.reset_perspective(null)

	qdel(hud_used)
	QDEL_LIST(client_colours)
	ghostize(can_reenter_corpse = FALSE) //False, since we're deleting it currently
	if(mind?.current == src) //Let's just be safe yeah? This will occasionally be cleared, but not always. Can't do it with ghostize without changing behavior
		mind.set_current(null)

	if(mock_client)
		mock_client.mob = null

	return ..()

/mob/New()
	// This needs to happen IMMEDIATELY. I'm sorry :(
	GenerateTag()
	return ..()

/**
 * Intialize a mob
 *
 * Sends global signal COMSIG_GLOB_MOB_CREATED
 *
 * Adds to global lists
 * * GLOB.mob_list
 * * GLOB.dead_mob_list - if mob is dead
 * * GLOB.alive_mob_list - if the mob is alive
 *
 * Other stuff:
 * * Sets the mob focus to itself
 * * Generates huds
 * * If there are any global alternate apperances apply them to this mob
 * * set a random nutrition level
 * * Intialize the movespeed of the mob
 */
/mob/Initialize(mapload)
	SEND_GLOBAL_SIGNAL(COMSIG_GLOB_MOB_CREATED, src)
	add_to_mob_list()
	if(stat == DEAD)
		add_to_dead_mob_list()
	else
		add_to_alive_mob_list()
	update_incapacitated()
	set_focus(src)
	prepare_huds()
	for(var/datum/atom_hud/alternate_appearance/alt_hud as anything in GLOB.active_alternate_appearances)
		alt_hud.apply_to_new_mob(src)

	set_nutrition(rand(NUTRITION_LEVEL_START_MIN, NUTRITION_LEVEL_START_MAX))
	. = ..()
	setup_hud_traits()
	update_config_movespeed()
	initialize_actionspeed()
	update_movespeed(TRUE)
	become_hearing_sensitive()
	log_mob_tag("TAG: [tag] CREATED: [key_name(src)] \[[type]\]")

/**
 * Generate the tag for this mob
 *
 * This is simply "mob_"+ a global incrementing counter that goes up for every mob
 */
/mob/GenerateTag()
	. = ..()
	tag = "mob_[next_mob_id++]"

/mob/serialize_list(list/options, list/semvers)
	. = ..()

	.["tag"] = tag
	.["name"] = name
	.["ckey"] = ckey
	.["key"] = key

	SET_SERIALIZATION_SEMVER(semvers, "1.0.0")
	return .

/**
 * set every hud image in the given category active so other people with the given hud can see it.
 * Arguments:
 * * hud_category - the index in our active_hud_list corresponding to an image now being shown.
 * * update_huds - if FALSE we will just put the hud_category into active_hud_list without actually updating the atom_hud datums subscribed to it
 * * exclusive_hud - if given a reference to an atom_hud, will just update that hud instead of all global ones attached to that category.
 * This is because some atom_hud subtypes arent supposed to work via global categories, updating normally would affect all of these which we dont want.
 */
/atom/proc/set_hud_image_active(hud_category, update_huds = TRUE, datum/atom_hud/exclusive_hud)
	if(!istext(hud_category) || !hud_list?[hud_category] || active_hud_list?[hud_category])
		return FALSE

	LAZYSET(active_hud_list, hud_category, hud_list[hud_category])

	if(!update_huds)
		return TRUE

	if(exclusive_hud)
		exclusive_hud.add_single_hud_category_on_atom(src, hud_category)
	else
		for(var/datum/atom_hud/hud_to_update as anything in GLOB.huds_by_category[hud_category])
			hud_to_update.add_single_hud_category_on_atom(src, hud_category)

	return TRUE

///sets every hud image in the given category inactive so no one can see it
/atom/proc/set_hud_image_inactive(hud_category, update_huds = TRUE, datum/atom_hud/exclusive_hud)
	if(!istext(hud_category))
		return FALSE

	if(!update_huds)
		LAZYREMOVE(active_hud_list, hud_category)
		return TRUE

	if(exclusive_hud)
		exclusive_hud.remove_single_hud_category_on_atom(src, hud_category)
	else
		for(var/datum/atom_hud/hud_to_update as anything in GLOB.huds_by_category[hud_category])
			hud_to_update.remove_single_hud_category_on_atom(src, hud_category)

	LAZYREMOVE(active_hud_list, hud_category)

	return TRUE

/**
 * Prepare the huds for this atom
 *
 * Goes through hud_possible list and adds the images to the hud_list variable (if not already cached)
 */
/atom/proc/prepare_huds()
	if(hud_list) // I choose to be lienient about people calling this proc more then once
		return
	hud_list = list()
	for(var/hud in hud_possible)
		var/hint = hud_possible[hud]

		if(hint == HUD_LIST_LIST)
			hud_list[hud] = list()

		else
			var/image/I = image('icons/mob/huds/hud.dmi', src, "")
			I.appearance_flags = RESET_COLOR|PIXEL_SCALE|KEEP_APART
			hud_list[hud] = I
		set_hud_image_active(hud, update_huds = FALSE) //by default everything is active. but dont add it to huds to keep control.

/**
 * Some kind of debug verb that gives atmosphere environment details
 */
/mob/proc/Cell()
	set category = "Admin"
	set hidden = TRUE

	if(!loc)
		return

	var/datum/gas_mixture/environment = loc.return_air()

	var/t = "[span_notice("Coordinates: [x],[y] ")]\n"
	t += "[span_danger("Temperature: [environment.temperature] ")]\n"
	for(var/id in environment.gases)
		var/gas = environment.gases[id]
		if(gas[MOLES])
			t+="[span_notice("[gas[GAS_META][META_GAS_NAME]]: [gas[MOLES]] ")]\n"

	to_chat(usr, t)

/**
 * Return the desc of this mob for a photo
 */
/mob/proc/get_photo_description(obj/item/camera/camera)
	return "a ... thing?"

/**
 * Show a message to this mob (visual or audible)
 */
/mob/proc/show_message(msg, type, alt_msg, alt_type, avoid_highlighting = FALSE)//Message, type of message (1 or 2), alternative message, alt message type (1 or 2)
	if(!client)
		return FALSE

	msg = copytext_char(msg, 1, MAX_MESSAGE_LEN)

	// Return TRUE if we sent the original msg, otherwise return FALSE
	. = TRUE
	if(type)
		if(type & MSG_VISUAL && is_blind())//Vision related
			if(!alt_msg)
				return FALSE
			else
				msg = alt_msg
				type = alt_type
				. = FALSE

		if(type & MSG_AUDIBLE && !can_hear())//Hearing related
			if(!alt_msg)
				return FALSE
			else
				msg = alt_msg
				type = alt_type
				. = FALSE
				if(type & MSG_VISUAL && is_blind())
					return FALSE
	// voice muffling
	if(stat == UNCONSCIOUS || stat == HARD_CRIT)
		if(type & MSG_AUDIBLE) //audio
			to_chat(src, "<I>... You can almost hear something ...</I>")
		return FALSE
	to_chat(src, msg, avoid_highlighting = avoid_highlighting)
	return .

/**
 * Generate a visible message from this atom
 *
 * Show a message to all player mobs who sees this atom
 *
 * Show a message to the src mob (if the src is a mob)
 *
 * Use for atoms performing visible actions
 *
 * message is output to anyone who can see, e.g. `"The [src] does something!"`
 *
 * Vars:
 * * message is the message output to anyone who can see.
 * * self_message (optional) is what the src mob sees e.g. "You do something!"
 * * blind_message (optional) is what blind people will hear e.g. "You hear something!"
 * * vision_distance (optional) define how many tiles away the message can be seen.
 * * ignored_mobs (optional) doesn't show any message to any mob in this list.
 * * visible_message_flags (optional) is the type of message being sent.
 */
/atom/proc/visible_message(message, self_message, blind_message, vision_distance = DEFAULT_MESSAGE_RANGE, list/ignored_mobs, visible_message_flags = NONE)
	var/turf/T = get_turf(src)
	if(!T)
		return

	if(!islist(ignored_mobs))
		ignored_mobs = list(ignored_mobs)
	var/list/hearers = get_hearers_in_view(vision_distance, src) //caches the hearers and then removes ignored mobs.
	hearers -= ignored_mobs

	if(self_message)
		hearers -= src

	var/raw_msg = message
	if(visible_message_flags & EMOTE_MESSAGE)
		message = span_emote("<b>[src]</b> [message]")

	for(var/mob/M in hearers)
		if(!M.client)
			continue

		//This entire if/else chain could be in two lines but isn't for readibilties sake.
		var/msg = message
		var/msg_type = MSG_VISUAL

		if(M.see_invisible < invisibility)//if src is invisible to M
			msg = blind_message
			msg_type = MSG_AUDIBLE
		else if(T != loc && T != src) //if src is inside something and not a turf.
			if(M != loc) // Only give the blind message to hearers that aren't the location
				msg = blind_message
				msg_type = MSG_AUDIBLE
		else if(!HAS_TRAIT(M, TRAIT_HEAR_THROUGH_DARKNESS) && M.lighting_cutoff < LIGHTING_CUTOFF_HIGH && T.is_softly_lit() && !in_range(T,M)) //if it is too dark, unless we're right next to them.
			msg = blind_message
			msg_type = MSG_AUDIBLE
		if(!msg)
			continue

		if(visible_message_flags & EMOTE_MESSAGE && runechat_prefs_check(M, visible_message_flags) && !M.is_blind())
			M.create_chat_message(src, raw_message = raw_msg, runechat_flags = visible_message_flags)

		M.show_message(msg, msg_type, blind_message, MSG_AUDIBLE)


///Adds the functionality to self_message.
/mob/visible_message(message, self_message, blind_message, vision_distance = DEFAULT_MESSAGE_RANGE, list/ignored_mobs, visible_message_flags = NONE)
	. = ..()
	if(!self_message)
		return
	var/raw_self_message = self_message
	var/self_runechat = FALSE
	if(visible_message_flags & EMOTE_MESSAGE)
		self_message = span_emote("<b>[src]</b> [self_message]") // May make more sense as "You do x"

	if(visible_message_flags & ALWAYS_SHOW_SELF_MESSAGE)
		to_chat(src, self_message)
		self_runechat = TRUE

	else
		self_runechat = show_message(self_message, MSG_VISUAL, blind_message, MSG_AUDIBLE)

	if(self_runechat && (visible_message_flags & EMOTE_MESSAGE) && runechat_prefs_check(src, visible_message_flags))
		create_chat_message(src, raw_message = raw_self_message, runechat_flags = visible_message_flags)

/**
 * Show a message to all mobs in earshot of this atom
 *
 * Use for objects performing audible actions
 *
 * vars:
 * * message is the message output to anyone who can hear.
 * * deaf_message (optional) is what deaf people will see.
 * * hearing_distance (optional) is the range, how many tiles away the message can be heard.
 * * self_message (optional) is what the src mob hears.
 * * audible_message_flags (optional) is the type of message being sent.
 */
/atom/proc/audible_message(message, deaf_message, hearing_distance = DEFAULT_MESSAGE_RANGE, self_message, audible_message_flags = NONE)
	var/list/hearers = get_hearers_in_view(hearing_distance, src)
	if(self_message)
		hearers -= src
	var/raw_msg = message
	if(audible_message_flags & EMOTE_MESSAGE)
		message = span_emote("<b>[src]</b> [message]")
	for(var/mob/M in hearers)
		if(audible_message_flags & EMOTE_MESSAGE && runechat_prefs_check(M, audible_message_flags) && M.can_hear())
			M.create_chat_message(src, raw_message = raw_msg, runechat_flags = audible_message_flags)
		M.show_message(message, MSG_AUDIBLE, deaf_message, MSG_VISUAL)

/**
 * Show a message to all mobs in earshot of this one
 *
 * This would be for audible actions by the src mob
 *
 * vars:
 * * message is the message output to anyone who can hear.
 * * self_message (optional) is what the src mob hears.
 * * deaf_message (optional) is what deaf people will see.
 * * hearing_distance (optional) is the range, how many tiles away the message can be heard.
 */
/mob/audible_message(message, deaf_message, hearing_distance = DEFAULT_MESSAGE_RANGE, self_message, audible_message_flags = NONE)
	. = ..()
	if(!self_message)
		return
	var/raw_self_message = self_message
	var/self_runechat = FALSE
	if(audible_message_flags & EMOTE_MESSAGE)
		self_message = span_emote("<b>[src]</b> [self_message]")
	if(audible_message_flags & ALWAYS_SHOW_SELF_MESSAGE)
		to_chat(src, self_message)
		self_runechat = TRUE
	else
		self_runechat = show_message(self_message, MSG_AUDIBLE, deaf_message, MSG_VISUAL)

	if(self_runechat && (audible_message_flags & EMOTE_MESSAGE) && runechat_prefs_check(src, audible_message_flags))
		create_chat_message(src, raw_message = raw_self_message, runechat_flags = audible_message_flags)

///Returns the client runechat visible messages preference according to the message type.
/atom/proc/runechat_prefs_check(mob/target, visible_message_flags = NONE)
	if(!target.client?.prefs.read_preference(/datum/preference/toggle/enable_runechat))
		return FALSE
	if (!target.client?.prefs.read_preference(/datum/preference/toggle/enable_runechat_non_mobs))
		return FALSE
	if(visible_message_flags & EMOTE_MESSAGE && !target.client.prefs.read_preference(/datum/preference/toggle/see_rc_emotes))
		return FALSE
	return TRUE

/mob/runechat_prefs_check(mob/target, visible_message_flags = NONE)
	if(!target.client?.prefs.read_preference(/datum/preference/toggle/enable_runechat))
		return FALSE
	if(visible_message_flags & EMOTE_MESSAGE && !target.client.prefs.read_preference(/datum/preference/toggle/see_rc_emotes))
		return FALSE
	return TRUE


///Get the item on the mob in the storage slot identified by the id passed in
/mob/proc/get_item_by_slot(slot_id)
	return null

/// Gets what slot the item on the mob is held in.
/// Returns null if the item isn't in any slots on our mob.
/// Does not check if the passed item is null, which may result in unexpected outcoms.
/mob/proc/get_slot_by_item(obj/item/looking_for)
	if(looking_for in held_items)
		return ITEM_SLOT_HANDS

	return null

/// Called whenever anything that modifes incapacitated is ran, updates it and sends a signal if it changes
/// Returns TRUE if anything changed, FALSE otherwise
/mob/proc/update_incapacitated()
	SIGNAL_HANDLER
	var/old_incap = incapacitated
	incapacitated = build_incapacitated()
	if(old_incap == incapacitated)
		return FALSE

	SEND_SIGNAL(src, COMSIG_MOB_INCAPACITATE_CHANGED, old_incap, incapacitated)
	return TRUE

/// Returns an updated incapacitated bitflag. If a flag is set it means we're incapacitated in that case
/mob/proc/build_incapacitated()
	return NONE

/**
 * This proc is called whenever someone clicks an inventory ui slot.
 *
 * Mostly tries to put the item into the slot if possible, or call attack hand
 * on the item in the slot if the users active hand is empty
 */
/mob/proc/attack_ui(slot, params)
	var/obj/item/W = get_active_held_item()

	if(istype(W))
		if(equip_to_slot_if_possible(W, slot,0,0,0))
			return TRUE

	if(!W)
		// Activate the item
		var/obj/item/I = get_item_by_slot(slot)
		if(istype(I))
			var/list/modifiers = params2list(params)
			I.attack_hand(src, modifiers)

	return FALSE

/**
 * Reset the attached clients perspective (viewpoint)
 *
 * reset_perspective(null) set eye to common default : mob on turf, loc otherwise
 * reset_perspective(thing) set the eye to the thing (if it's equal to current default reset to mob perspective)
 */
/mob/proc/reset_perspective(atom/new_eye)
	SHOULD_CALL_PARENT(TRUE)
	if(!client)
		return

	if(new_eye)
		if(ismovable(new_eye))
			//Set the new eye unless it's us
			if(new_eye != src)
				client.perspective = EYE_PERSPECTIVE
				client.set_eye(new_eye)
			else
				client.set_eye(client.mob)
				client.perspective = MOB_PERSPECTIVE

		else if(isturf(new_eye))
			//Set to the turf unless it's our current turf
			if(new_eye != loc)
				client.perspective = EYE_PERSPECTIVE
				client.set_eye(new_eye)
			else
				client.set_eye(client.mob)
				client.perspective = MOB_PERSPECTIVE
		else
			return TRUE //no setting eye to stupid things like areas or whatever
	else
		//Reset to common defaults: mob if on turf, otherwise current loc
		if(isturf(loc))
			client.set_eye(client.mob)
			client.perspective = MOB_PERSPECTIVE
		else
			client.perspective = EYE_PERSPECTIVE
			client.set_eye(loc)
	/// Signal sent after the eye has been successfully updated, with the client existing.
	SEND_SIGNAL(src, COMSIG_MOB_RESET_PERSPECTIVE)
	return TRUE

/**
 * Examine a mob
 *
 * mob verbs are faster than object verbs. See
 * [this byond forum post](https://secure.byond.com/forum/?post=1326139&page=2#comment8198716)
 * for why this isn't atom/verb/examine()
 */
/mob/verb/examinate(atom/examinify as mob|obj|turf in view()) //It used to be oview(12), but I can't really say why
	set name = "Examine"
	set category = "IC"

	DEFAULT_QUEUE_OR_CALL_VERB(VERB_CALLBACK(src, PROC_REF(run_examinate), examinify))

/mob/proc/run_examinate(atom/examinify)

	if(isturf(examinify) && !(sight & SEE_TURFS) && !(examinify in view(client ? client.view : world.view, src)))
		// shift-click catcher may issue examinate() calls for out-of-sight turfs
		return

	var/turf/examine_turf = get_turf(examinify)
	if(is_blind()) //blind people see things differently (through touch)
		if(!blind_examine_check(examinify))
			return
	else if(examine_turf && !(examine_turf.luminosity || examine_turf.dynamic_lumcount) && \
		get_dist(src, examine_turf) > 1 && \
		!has_nightvision()) // If you aren't blind, it's in darkness (that you can't see) and farther then next to you
		return

	face_atom(examinify)
	var/result_combined
	if(client)
		LAZYINITLIST(client.recent_examines)
		var/ref_to_atom = REF(examinify)
		var/examine_time = client.recent_examines[ref_to_atom]
		if(examine_time && (world.time - examine_time < EXAMINE_MORE_WINDOW))
			var/list/result = examinify.examine_more(src)
			if(!length(result))
				result += span_notice("<i>You examine [examinify] closer, but find nothing of interest...</i>")
			result_combined = boxed_message(jointext(result, "<br>"))

		else
			client.recent_examines[ref_to_atom] = world.time // set to when we last normal examine'd them
			addtimer(CALLBACK(src, PROC_REF(clear_from_recent_examines), ref_to_atom), RECENT_EXAMINE_MAX_WINDOW)
			handle_eye_contact(examinify)

	if(!result_combined)
		var/list/result = examinify.examine(src)
		var/atom_title = examinify.examine_title(src, thats = TRUE)
		SEND_SIGNAL(src, COMSIG_MOB_EXAMINING, examinify, result)
		result_combined = (atom_title ? fieldset_block("[atom_title]", jointext(result, "<br>"), "boxed_message") : boxed_message(jointext(result, "<br>")))

	to_chat(src, span_infoplain(result_combined))
	SEND_SIGNAL(src, COMSIG_MOB_EXAMINATE, examinify)

/mob/proc/blind_examine_check(atom/examined_thing)
	return TRUE //The non-living will always succeed at this check.


/mob/living/blind_examine_check(atom/examined_thing)
	//need to be next to something and awake
	if(!Adjacent(examined_thing) || incapacitated)
		to_chat(src, span_warning("Something is there, but you can't see it!"))
		return FALSE

	//you can examine things you're holding directly, but you can't examine other things if your hands are full
	/// the item in our active hand
	var/obj/item/active_item = get_active_held_item()
	var/boosted = FALSE
	if(active_item)
		if(HAS_TRAIT(active_item, TRAIT_BLIND_TOOL))
			boosted = TRUE
		else if(active_item != examined_thing)
			to_chat(src, span_warning("Your hands are too full to examine this!"))
			return FALSE

	//you can only initiate exaimines if you have a hand, it's not disabled, and only as many examines as you have hands
	/// our active hand, to check if it's disabled/detached
	var/obj/item/bodypart/active_hand = has_active_hand()? get_active_hand() : null
	if(!active_hand || active_hand.bodypart_disabled || do_after_count() >= usable_hands)
		to_chat(src, span_warning("You don't have a free hand to examine this!"))
		return FALSE

	//you can only queue up one examine on something at a time
	if(DOING_INTERACTION_WITH_TARGET(src, examined_thing))
		return FALSE

	to_chat(src, span_notice("You start feeling around for something..."))
	visible_message(span_notice(" [name] begins feeling around for \the [examined_thing.name]..."))

	/// how long it takes for the blind person to find the thing they're examining
	var/examine_delay_length = rand(1 SECONDS, 2 SECONDS)
	if(boosted)
		examine_delay_length = 0.5 SECONDS
	if(client?.recent_examines && client?.recent_examines[ref(examined_thing)]) //easier to find things we just touched
		examine_delay_length = 0.33 SECONDS
	else if(isobj(examined_thing))
		examine_delay_length *= 1.5
	else if(ismob(examined_thing) && examined_thing != src)
		examine_delay_length *= 2

	if(examine_delay_length > 0 && !do_after(src, examine_delay_length, target = examined_thing))
		to_chat(src, span_notice("You can't get a good feel for what is there."))
		return FALSE

	//now we touch the thing we're examining
	/// our current intent, so we can go back to it after touching
	var/previous_combat_mode = combat_mode
	set_combat_mode(FALSE)
	INVOKE_ASYNC(examined_thing, TYPE_PROC_REF(/atom, attack_hand), src)
	set_combat_mode(previous_combat_mode)
	return TRUE


/mob/proc/clear_from_recent_examines(ref_to_clear)
	SIGNAL_HANDLER
	if(!client)
		return
	LAZYREMOVE(client.recent_examines, ref_to_clear)

/**
 * handle_eye_contact() is called when we examine() something. If we examine an alive mob with a mind who has examined us in the last 2 seconds within 5 tiles, we make eye contact!
 *
 * Note that if either party has their face obscured, the other won't get the notice about the eye contact
 * Also note that examine_more() doesn't proc this or extend the timer, just because it's simpler this way and doesn't lose much.
 * The nice part about relying on examining is that we don't bother checking visibility, because we already know they were both visible to each other within the last second, and the one who triggers it is currently seeing them
 */
/mob/proc/handle_eye_contact(mob/living/examined_mob)
	return

/mob/living/handle_eye_contact(mob/living/examined_mob)
	if(!istype(examined_mob) || src == examined_mob || examined_mob.stat >= UNCONSCIOUS || !client || is_blind())
		return

	var/imagined_eye_contact = FALSE
	if(!LAZYACCESS(examined_mob.client?.recent_examines, src))
		// even if you haven't looked at them recently, if you have the shift eyes trait, they may still imagine the eye contact
		if(HAS_TRAIT(examined_mob, TRAIT_SHIFTY_EYES) && prob(10 - get_dist(src, examined_mob)))
			imagined_eye_contact = TRUE
		else
			return

	if(get_dist(src, examined_mob) > EYE_CONTACT_RANGE)
		return

	// check to see if their face is blocked or, if not, a signal blocks it
	if(examined_mob.is_face_visible() && SEND_SIGNAL(src, COMSIG_MOB_EYECONTACT, examined_mob, TRUE) != COMSIG_BLOCK_EYECONTACT)
		var/obj/item/clothing/eye_cover = examined_mob.is_eyes_covered()
		if (!eye_cover || (!eye_cover.tint && !eye_cover.flash_protect))
			var/msg = span_smallnotice("You make eye contact with [examined_mob].")
			addtimer(CALLBACK(GLOBAL_PROC, GLOBAL_PROC_REF(to_chat), src, msg), 0.3 SECONDS) // so the examine signal has time to fire and this will print after

	if(!imagined_eye_contact && is_face_visible() && !examined_mob.is_blind() && SEND_SIGNAL(examined_mob, COMSIG_MOB_EYECONTACT, src, FALSE) != COMSIG_BLOCK_EYECONTACT)
		var/obj/item/clothing/eye_cover = is_eyes_covered()
		if (!eye_cover || (!eye_cover.tint && !eye_cover.flash_protect))
			var/msg = span_smallnotice("[src] makes eye contact with you.")
			addtimer(CALLBACK(GLOBAL_PROC, GLOBAL_PROC_REF(to_chat), examined_mob, msg), 0.3 SECONDS)

/**
 * Called by using Activate Held Object with an empty hand/limb
 *
 * Does nothing by default. The intended use is to allow limbs to call their
 * own attack_self procs. It is up to the individual mob to override this
 * parent and actually use it.
 */
/mob/proc/limb_attack_self()
	return

///Can this mob resist (default FALSE)
/mob/proc/can_resist()
	return FALSE //overridden in living.dm

#define SPIN_PROC_TRAIT "trait_from_spin()"

///Spin this mob around it's central axis
/mob/proc/spin(spintime, speed)
	set waitfor = 0
	var/D = dir
	if((spintime < 1) || (speed < 1) || !spintime || !speed)
		return

	ADD_TRAIT(src, TRAIT_SPINNING, SPIN_PROC_TRAIT)
	while(spintime >= speed)
		sleep(speed)
		switch(D)
			if(NORTH)
				D = EAST
			if(SOUTH)
				D = WEST
			if(EAST)
				D = SOUTH
			if(WEST)
				D = NORTH
		setDir(D)
		spintime -= speed
	REMOVE_TRAIT(src, TRAIT_SPINNING, SPIN_PROC_TRAIT)

#undef SPIN_PROC_TRAIT

///Update the pulling hud icon
/mob/proc/update_pull_hud_icon()
	hud_used?.pull_icon?.update_appearance()

///Update the resting hud icon
/mob/proc/update_rest_hud_icon()
	hud_used?.rest_icon?.update_appearance()

/**
 * Verb to activate the object in your held hand
 *
 * Calls attack self on the item and updates the inventory hud for hands
 */
/mob/verb/mode()
	set name = "Activate Held Object"
	set category = "Object"
	set src = usr

	DEFAULT_QUEUE_OR_CALL_VERB(VERB_CALLBACK(src, PROC_REF(execute_mode)))

///proc version to finish /mob/verb/mode() execution. used in case the proc needs to be queued for the tick after its first called
/mob/proc/execute_mode()
	if(ismecha(loc))
		return

	if(incapacitated)
		return

	var/obj/item/I = get_active_held_item()
	if(I)
		I.attack_self(src)
		update_held_items()
		return

	limb_attack_self()

/**
 * Allows you to respawn, abandoning your current mob
 *
 * This sends you back to the lobby creating a new dead mob
 *
 * Only works if flag/allow_respawn is allowed in config
 */
/mob/verb/abandon_mob()
	set name = "Respawn"
	set category = "OOC"

	switch(CONFIG_GET(flag/allow_respawn))
		if(RESPAWN_FLAG_NEW_CHARACTER)
			if(tgui_alert(usr, "Note, respawning is only allowed as another character. If you don't have another free slot you may not be able to respawn.", "Respawn", list("Ok", "Nevermind")) != "Ok")
				return

		if(RESPAWN_FLAG_FREE)
			pass() // Normal respawn

		if(RESPAWN_FLAG_DISABLED)
			if (!check_rights_for(usr.client, R_ADMIN))
				to_chat(usr, span_boldnotice("Respawning is not enabled!"))
				return
			if (tgui_alert(usr, "Respawning is currently disabled, do you want to use your permissions to circumvent it?", "Respawn", list("Yes", "No")) != "Yes")
				return

	if (stat != DEAD)
		to_chat(usr, span_boldnotice("You must be dead to use this!"))
		return

	if(!check_respawn_delay())
		return

	usr.log_message("used the respawn button.", LOG_GAME)

	to_chat(usr, span_boldnotice("Please roleplay correctly!"))

	if(!client)
		usr.log_message("respawn failed due to disconnect.", LOG_GAME)
		return
	client.screen.Cut()
	client.screen += client.void
	if(!client)
		usr.log_message("respawn failed due to disconnect.", LOG_GAME)
		return

	var/mob/dead/new_player/M = new /mob/dead/new_player()
	if(!client)
		usr.log_message("respawn failed due to disconnect.", LOG_GAME)
		qdel(M)
		return

	M.key = key

/// Checks if the mob can respawn yet according to the respawn delay
/mob/proc/check_respawn_delay(override_delay = 0)
	if(!override_delay && !CONFIG_GET(number/respawn_delay))
		return TRUE

	var/death_time = world.time - client.player_details.time_of_death

	var/required_delay = override_delay || CONFIG_GET(number/respawn_delay)

	if(death_time < required_delay)
		if(!check_rights_for(usr.client, R_ADMIN))
			to_chat(usr, "You have been dead for [DisplayTimeText(death_time, 1)].")
			to_chat(usr, span_warning("You must wait [DisplayTimeText(required_delay, 1)] to respawn!"))
			return FALSE
		if(tgui_alert(usr, "You have been dead for [DisplayTimeText(death_time, 1)] out of required [DisplayTimeText(required_delay, 1)]. Do you want to use your permissions to circumvent it?", "Respawn", list("Yes", "No")) != "Yes")
			return FALSE
	return TRUE

/**
 * Sometimes helps if the user is stuck in another perspective or camera
 */
/mob/verb/cancel_camera()
	set name = "Cancel Camera View"
	set category = "OOC"
	reset_perspective(null)

//suppress the .click/dblclick macros so people can't use them to identify the location of items or aimbot
/mob/verb/DisClick(argu = null as anything, sec = "" as text, number1 = 0 as num  , number2 = 0 as num)
	set name = ".click"
	set hidden = TRUE
	set category = null
	return

/mob/verb/DisDblClick(argu = null as anything, sec = "" as text, number1 = 0 as num  , number2 = 0 as num)
	set name = ".dblclick"
	set hidden = TRUE
	set category = null
	return

/// Adds this list to the output to the stat browser
/mob/proc/get_status_tab_items()
	. = list("") //we want to offset unique stuff from standard stuff
	SEND_SIGNAL(src, COMSIG_MOB_GET_STATUS_TAB_ITEMS, .)

/**
 * Convert a list of spells into a displyable list for the statpanel
 *
 * Shows charge and other important info
 */
/mob/proc/get_actions_for_statpanel()
	var/list/data = list()
	for(var/datum/action/cooldown/action in actions)
		var/list/action_data = action.set_statpanel_format()
		if(!length(action_data))
			return

		data += list(list(
			// the panel the action gets displayed to
			// in the future, this could probably be replaced with subtabs (a la admin tabs)
			action_data[PANEL_DISPLAY_PANEL],
			// the status of the action, - cooldown, charges, whatever
			action_data[PANEL_DISPLAY_STATUS],
			// the name of the action
			action_data[PANEL_DISPLAY_NAME],
			// a ref to the action button of this action for this mob
			// it's a ref to the button specifically, instead of the action itself,
			// because statpanel href calls click(), which the action button (not the action itself) handles
			REF(action.viewers[hud_used]),
		))

	return data

/mob/proc/swap_hand(held_index, silent = FALSE)
	SHOULD_NOT_OVERRIDE(TRUE) // Override perform_hand_swap instead

	var/obj/item/held_item = get_active_held_item()
	if(SEND_SIGNAL(src, COMSIG_MOB_SWAPPING_HANDS, held_item) & COMPONENT_BLOCK_SWAP)
		if (!silent)
			to_chat(src, span_warning("Your other hand is too busy holding [held_item]."))
		return FALSE

	var/result = perform_hand_swap(held_index)
	if (result)
		SEND_SIGNAL(src, COMSIG_MOB_SWAP_HANDS)

	return result

/// Performs the actual ritual of swapping hands, such as setting the held index variables
/mob/proc/perform_hand_swap(held_index)
	PROTECTED_PROC(TRUE)
	if (!HAS_TRAIT(src, TRAIT_CAN_HOLD_ITEMS))
		return FALSE

	if(!held_index)
		held_index = (active_hand_index % held_items.len) + 1

	if(!isnum(held_index))
		CRASH("You passed [held_index] into swap_hand instead of a number. WTF man")

	var/previous_index = active_hand_index
	active_hand_index = held_index
	if(hud_used)
		var/atom/movable/screen/inventory/hand/held_location
		held_location = hud_used.hand_slots["[previous_index]"]
		if(!isnull(held_location))
			held_location.update_appearance()
		held_location = hud_used.hand_slots["[held_index]"]
		if(!isnull(held_location))
			held_location.update_appearance()
	return TRUE

/mob/proc/activate_hand(selected_hand)
	if (!HAS_TRAIT(src, TRAIT_CAN_HOLD_ITEMS))
		return

	if(!selected_hand)
		selected_hand = active_hand_index
	else if(istext(selected_hand))
		selected_hand = LOWER_TEXT(selected_hand)
		if(selected_hand == "right" || selected_hand == "r")
			selected_hand = 2
		if(selected_hand == "left" || selected_hand == "l")
			selected_hand = 1

	if(selected_hand != active_hand_index)
		swap_hand(selected_hand)

	// _queue_verb requires a client, so when we don't have it (AI controlled mob) we don't use it
	client ? mode() : execute_mode()

/mob/proc/assess_threat(judgement_criteria, lasercolor = "", datum/callback/weaponcheck=null) //For sec bot threat assessment
	return 0

///Get the ghost of this mob (from the mind)
/mob/proc/get_ghost(even_if_they_cant_reenter, ghosts_with_clients)
	if(mind)
		return mind.get_ghost(even_if_they_cant_reenter, ghosts_with_clients)

///Force get the ghost from the mind
/mob/proc/grab_ghost(force)
	if(mind)
		return mind.grab_ghost(force = force)

///Notify a ghost that its body is being revived
/mob/proc/notify_revival(message = "Someone is trying to revive you. Re-enter your corpse if you want to be revived!", sound = 'sound/effects/genetics.ogg', atom/source = null, flashwindow = TRUE)
	var/mob/dead/observer/ghost = get_ghost()
	if(ghost)
		ghost.send_revival_notification(message, sound, source, flashwindow)
		return ghost

/**
 * Checks to see if the mob can cast normal magic spells.
 *
 * args:
 * * magic_flags (optional) A bitfield with the type of magic being cast (see flags at: /datum/component/anti_magic)
**/
/mob/proc/can_cast_magic(magic_flags = MAGIC_RESISTANCE)
	if(magic_flags == NONE) // magic with the NONE flag can always be cast
		return TRUE

	var/restrict_magic_flags = SEND_SIGNAL(src, COMSIG_MOB_RESTRICT_MAGIC, magic_flags)
	return restrict_magic_flags == NONE

/**
 * Checks to see if the mob can block magic
 *
 * args:
 * * casted_magic_flags (optional) A bitfield with the types of magic resistance being checked (see flags at: /datum/component/anti_magic)
 * * charge_cost (optional) The cost of charge to block a spell that will be subtracted from the protection used
**/
/mob/proc/can_block_magic(casted_magic_flags = MAGIC_RESISTANCE, charge_cost = 1)
	if(casted_magic_flags == NONE) // magic with the NONE flag is immune to blocking
		return FALSE

	// A list of all things which are providing anti-magic to us
	var/list/antimagic_sources = list()
	var/is_magic_blocked = FALSE

	if(SEND_SIGNAL(src, COMSIG_MOB_RECEIVE_MAGIC, casted_magic_flags, charge_cost, antimagic_sources) & COMPONENT_MAGIC_BLOCKED)
		is_magic_blocked = TRUE
	if(HAS_TRAIT(src, TRAIT_ANTIMAGIC))
		is_magic_blocked = TRUE
	if((casted_magic_flags & MAGIC_RESISTANCE_HOLY) && HAS_TRAIT(src, TRAIT_HOLY))
		is_magic_blocked = TRUE

	if(is_magic_blocked && charge_cost > 0 && !HAS_TRAIT(src, TRAIT_RECENTLY_BLOCKED_MAGIC))
		on_block_magic_effects(casted_magic_flags, antimagic_sources)

	return is_magic_blocked

/// Called whenever a magic effect with a charge cost is blocked and we haven't recently blocked magic.
/mob/proc/on_block_magic_effects(magic_flags, list/antimagic_sources)
	return

/mob/living/on_block_magic_effects(magic_flags, list/antimagic_sources)
	ADD_TRAIT(src, TRAIT_RECENTLY_BLOCKED_MAGIC, MAGIC_TRAIT)
	addtimer(TRAIT_CALLBACK_REMOVE(src, TRAIT_RECENTLY_BLOCKED_MAGIC, MAGIC_TRAIT), 6 SECONDS)

	var/mutable_appearance/antimagic_effect
	var/antimagic_color
	var/atom/antimagic_source = length(antimagic_sources) ? pick(antimagic_sources) : src

	if(magic_flags & MAGIC_RESISTANCE)
		visible_message(
			span_warning("[src] pulses red as [ismob(antimagic_source) ? p_they() : antimagic_source] absorbs magic energy!"),
			span_userdanger("An intense magical aura pulses around [ismob(antimagic_source) ? "you" : antimagic_source] as it dissipates into the air!"),
		)
		antimagic_effect = mutable_appearance('icons/effects/effects.dmi', "shield-red", MOB_SHIELD_LAYER)
		antimagic_color = LIGHT_COLOR_BLOOD_MAGIC
		playsound(src, 'sound/effects/magic/magic_block.ogg', 50, TRUE)

	else if(magic_flags & MAGIC_RESISTANCE_HOLY)
		visible_message(
			span_warning("[src] starts to glow as [ismob(antimagic_source) ? p_they() : antimagic_source] emits a halo of light!"),
			span_userdanger("A feeling of warmth washes over [ismob(antimagic_source) ? "you" : antimagic_source] as rays of light surround your body and protect you!"),
		)
		antimagic_effect = mutable_appearance('icons/mob/effects/genetics.dmi', "servitude", -MUTATIONS_LAYER)
		antimagic_color = LIGHT_COLOR_HOLY_MAGIC
		playsound(src, 'sound/effects/magic/magic_block_holy.ogg', 50, TRUE)

	else if(magic_flags & MAGIC_RESISTANCE_MIND)
		visible_message(
			span_warning("[src] forehead shines as [ismob(antimagic_source) ? p_they() : antimagic_source] repulses magic from their mind!"),
			span_userdanger("A feeling of cold splashes on [ismob(antimagic_source) ? "you" : antimagic_source] as your forehead reflects magic usering your mind!"),
		)
		antimagic_effect = mutable_appearance('icons/mob/effects/genetics.dmi', "telekinesishead", MOB_SHIELD_LAYER)
		antimagic_color = LIGHT_COLOR_DARK_BLUE
		playsound(src, 'sound/effects/magic/magic_block_mind.ogg', 50, TRUE)

	mob_light(range = 2, power = 2, color = antimagic_color, duration = 5 SECONDS)
	add_overlay(antimagic_effect)
	addtimer(CALLBACK(src, TYPE_PROC_REF(/atom, cut_overlay), antimagic_effect), 5 SECONDS)

/**
 * Buckle a living mob to this mob. Also turns you to face the other mob
 *
 * You can buckle on mobs if you're next to them since most are dense
 */
/mob/buckle_mob(mob/living/M, force = FALSE, check_loc = TRUE, buckle_mob_flags= NONE)
	if(M.buckled)
		return FALSE
	return ..(M, force, check_loc, buckle_mob_flags)

///Call back post buckle to a mob to offset your visual height
/mob/post_buckle_mob(mob/living/M)
	var/height = M.get_mob_buckling_height(src)
	M.pixel_y = initial(M.pixel_y) + height
	if(M.layer <= layer) //make sure they stay above our current layer
		M.layer = layer + 0.1
///Call back post unbuckle from a mob, (reset your visual height here)
/mob/post_unbuckle_mob(mob/living/M)
	M.layer = initial(M.layer)
	M.pixel_y = initial(M.pixel_y)

///returns the height in pixel the mob should have when buckled to another mob.
/mob/proc/get_mob_buckling_height(mob/seat)
	if(isliving(seat))
		var/mob/living/L = seat
		if(L.mob_size <= MOB_SIZE_SMALL) //being on top of a small mob doesn't put you very high.
			return 0
	return 9

///Can the mob interact() with an atom?
/mob/proc/can_interact_with(atom/A, treat_mob_as_adjacent)
	if(isAdminGhostAI(src))
		return TRUE
	//Return early. we do not need to check that we are on adjacent turfs (i.e we are inside a closet)
	if (treat_mob_as_adjacent && src == A.loc)
		return TRUE
	if (Adjacent(A))
		return TRUE
	var/datum/dna/mob_dna = has_dna()
	if(mob_dna?.check_mutation(/datum/mutation/human/telekinesis) && tkMaxRangeCheck(src, A))
		return TRUE
	var/obj/item/item_in_hand = get_active_held_item()
	if(istype(item_in_hand, /obj/item/machine_remote))
		return TRUE

	//range check
	if(!interaction_range) // If you don't have extra length, GO AWAY
		return FALSE
	var/turf/our_turf = get_turf(src)
	var/turf/their_turf = get_turf(A)
	if (!our_turf || !their_turf)
		return FALSE
	return ISINRANGE(their_turf.x, our_turf.x - interaction_range, our_turf.x + interaction_range) && ISINRANGE(their_turf.y, our_turf.y - interaction_range, our_turf.y + interaction_range)

/**
 * Checks whether a mob can perform an action to interact with an object
 *
 * The default behavior checks if the mob is:
 * * Directly adjacent (1-tile radius)
 * * Standing up (not resting)
 * * Allows telekinesis to be used to skip adjacent checks (if they have DNA mutation)
 * *
 * action_bitflags: (see code/__DEFINES/mobs.dm)
 * * NEED_GRAVITY - If gravity must be present to perform action (can't use pens without gravity)
 * * NEED_LITERACY - If reading is required to perform action (can't read a book if you are illiterate)
 * * NEED_LIGHT - If lighting must be present to perform action (can't heal someone in the dark)
 * * NEED_DEXTERITY - If other mobs (monkeys, aliens, etc) can perform action (can't use computers if you are a monkey)
 * * NEED_HANDS - If hands are required to perform action (can't pickup items if you are a cyborg)
 * * FORBID_TELEKINESIS_REACH - If telekinesis is forbidden to perform action from a distance (ex. canisters are blacklisted from telekinesis manipulation)
 * * ALLOW_SILICON_REACH - If silicons are allowed to perform action from a distance (silicons can operate airlocks from far away)
 * * ALLOW_RESTING - If resting on the floor is allowed to perform action ()
 * * ALLOW_VENTCRAWL - Mobs with ventcrawl traits can alt-click this to vent
 * * BYPASS_ADJACENCY - The target does not have to be adjacent
 * * SILENT_ADJACENCY - Adjacency is required but errors are not printed
 * * NOT_INSIDE_TARGET - The target maybe adjacent but the mob should not be inside the target
 * * ALLOW_PAI - Allows pAIs to perform an action
 *
 * silence_adjacency: Sometimes we want to use this proc to check interaction without allowing it to throw errors for base case adjacency
 * Alt click uses this, as otherwise you can detect what is interactable from a distance via the error message
**/
/mob/proc/can_perform_action(atom/target, action_bitflags)
	return

///Can this mob use storage
/mob/proc/canUseStorage()
	return FALSE

/*
 * Compare two lists of factions, returning true if any match
 *
 * If exact match is passed through we only return true if both faction lists match equally
 */
/proc/faction_check(list/faction_A, list/faction_B, exact_match)
	var/list/match_list
	if(exact_match)
		match_list = faction_A&faction_B //only items in both lists
		var/length = LAZYLEN(match_list)
		if(length)
			return (length == LAZYLEN(faction_A)) //if they're not the same len(gth) or we don't have a len, then this isn't an exact match.
	else
		match_list = faction_A&faction_B
		return LAZYLEN(match_list)
	return FALSE


/**
 * Fully update the name of a mob
 *
 * This will update a mob's name, real_name, mind.name, GLOB.manifest records, pda, id and traitor text
 *
 * Calling this proc without an oldname will only update the mob and skip updating the pda, id and records ~Carn
 */
/mob/proc/fully_replace_character_name(oldname, newname)
	if(!newname)
		log_message("[src] failed name change from [oldname] as no new name was specified", LOG_OWNERSHIP)
		return FALSE
	if(oldname == newname)
		log_message("[src] failed name change as the new name was the same as the old one: [oldname]", LOG_OWNERSHIP)
		return FALSE
	if(!istext(newname) && !isnull(newname))
		stack_trace("[src] attempted to change its name from [oldname] to the non string value [newname]")
		return FALSE

	log_message("[src] name changed from [oldname] to [newname]", LOG_OWNERSHIP)

	log_played_names(
		ckey,
		list(
			"[newname]" = tag,
		),
	)

	real_name = newname
	name = newname
	if(mind)
		mind.name = newname
		if(mind.key)
			log_played_names(
				ckey(mind.key),
				list(
					"[newname]" = tag,
				),
			) //Just in case the mind is unsynced at the moment.

	if(oldname)
		//update the datacore records! This is goig to be a bit costly.
		replace_records_name(oldname,newname)

		//update our pda and id if we have them on our person
		replace_identification_name(oldname,newname)

		for(var/datum/mind/T in SSticker.minds)
			for(var/datum/objective/obj in T.get_all_objectives())
				// Only update if this player is a target
				if(obj.target && obj.target.current && obj.target.current.real_name == name)
					obj.update_explanation_text()

	log_mob_tag("TAG: [tag] RENAMED: [key_name(src)]")

	return TRUE

///Updates GLOB.manifest records with new name , see mob/living/carbon/human
/mob/proc/replace_records_name(oldname,newname)
	return

///update the ID name of this mob
/mob/proc/replace_identification_name(oldname,newname)
	var/list/searching = get_all_contents()
	var/search_id = 1
	var/search_pda = 1

	for(var/A in searching)
		if( search_id && isidcard(A) )
			var/obj/item/card/id/ID = A
			if(ID.registered_name == oldname)
				ID.registered_name = newname
				ID.update_label()
				ID.update_icon()
				if(ID.registered_account?.account_holder == oldname)
					ID.registered_account.account_holder = newname
				if(!search_pda)
					break
				search_id = 0

		else if( search_pda && istype(A, /obj/item/modular_computer/pda) )
			var/obj/item/modular_computer/pda/PDA = A
			if(PDA.saved_identification == oldname)
				PDA.imprint_id(name = newname)
				PDA.UpdateDisplay()
				if(!search_id)
					break
				search_pda = 0

/mob/proc/update_stat()
	return

/mob/proc/update_health_hud()
	return

/// Changes the stamina HUD based on new information
/mob/proc/update_stamina_hud()
	return

///Update the lighting plane and sight of this mob (sends COMSIG_MOB_UPDATE_SIGHT)
/mob/proc/update_sight()
	SHOULD_CALL_PARENT(TRUE)
	SEND_SIGNAL(src, COMSIG_MOB_UPDATE_SIGHT)
	sync_lighting_plane_cutoff()

///Set the lighting plane hud filters to the mobs lighting_cutoff var
/mob/proc/sync_lighting_plane_cutoff()
	if(!hud_used)
		return
	for(var/atom/movable/screen/plane_master/rendering_plate/lighting/light as anything in hud_used.get_true_plane_masters(RENDER_PLANE_LIGHTING))
		light.set_light_cutoff(lighting_cutoff, lighting_color_cutoffs)

///Update the mouse pointer of the attached client in this mob
/mob/proc/update_mouse_pointer()
	if(!client)
		return
	if(client.mouse_pointer_icon != initial(client.mouse_pointer_icon))//only send changes to the client if theyre needed
		client.mouse_pointer_icon = initial(client.mouse_pointer_icon)
	if(examine_cursor_icon && client.keys_held["Shift"]) //mouse shit is hardcoded, make this non hard-coded once we make mouse modifiers bindable
		client.mouse_pointer_icon = examine_cursor_icon
	if(istype(loc, /obj/vehicle/sealed))
		var/obj/vehicle/sealed/E = loc
		if(E.mouse_pointer)
			client.mouse_pointer_icon = E.mouse_pointer
	if(client.mouse_override_icon)
		client.mouse_pointer_icon = client.mouse_override_icon

/**
 * Can this mob see in the dark
 *
 * This checks all traits, glasses, and robotic eyeball implants to see if the mob can see in the dark
 * this does NOT check if the mob is missing it's eyeballs.
**/
/mob/proc/has_nightvision()
	// Somewhat conservative, basically is your lighting plane bright enough that you the user can see stuff
	var/light_offset = lighting_cutoff
	if(length(lighting_color_cutoffs) == 3)
		light_offset += (lighting_color_cutoffs[1] + lighting_color_cutoffs[2] + lighting_color_cutoffs[3]) / 3
	return light_offset >= LIGHTING_NIGHTVISION_THRESHOLD

/// This mob is abile to read books
/mob/proc/is_literate()
	return HAS_TRAIT(src, TRAIT_LITERATE) && !HAS_TRAIT(src, TRAIT_ILLITERATE)

/**
 * Proc that returns TRUE if the mob can write using the writing_instrument, FALSE otherwise.
 *
 * This proc a side effect, outputting a message to the mob's chat with a reason if it returns FALSE.
 * Unless silent_if_not_writing_tool is TRUE. In that case it'll be silent if it isn't a writing implement/tool/instrument w/e.
 */
/mob/proc/can_write(obj/item/writing_instrument, silent_if_not_writing_tool = FALSE)
	if(!writing_instrument)
		return FALSE

	var/pen_info = writing_instrument.get_writing_implement_details()
	if(!pen_info || (pen_info["interaction_mode"] != MODE_WRITING))
		if(!silent_if_not_writing_tool)
			to_chat(src, span_warning("You can't write with the [writing_instrument]!"))
		return FALSE

	if(!is_literate())
		to_chat(src, span_warning("You try to write, but don't know how to spell anything!"))
		return FALSE

	if(!has_light_nearby() && !has_nightvision())
		to_chat(src, span_warning("It's too dark in here to write anything!"))
		return FALSE

	if(has_gravity())
		return TRUE

	var/obj/item/pen/pen = writing_instrument

	if(istype(pen) && pen.requires_gravity)
		to_chat(src, span_warning("You try to write, but the [writing_instrument] doesn't work in zero gravity!"))
		return FALSE

	return TRUE

/**
 * Checks if there is enough light where the mob is located
 *
 * Args:
 *  light_amount (optional) - A decimal amount between 1.0 through 0.0 (default is 0.2)
**/
/mob/proc/has_light_nearby(light_amount = LIGHTING_TILE_IS_DARK)
	var/turf/mob_location = get_turf(src)
	var/area/mob_area = get_area(src)

	if(mob_location.get_lumcount() > light_amount)
		return TRUE
	else if(!mob_area.static_lighting)
		return TRUE

	return FALSE



/// Can this mob read
/mob/proc/can_read(atom/viewed_atom, reading_check_flags = (READING_CHECK_LITERACY|READING_CHECK_LIGHT), silent = FALSE)
	if((reading_check_flags & READING_CHECK_LITERACY) && !is_literate())
		if(!silent)
			to_chat(src, span_warning("You try to read [viewed_atom], but can't comprehend any of it."))
		return FALSE

	if((reading_check_flags & READING_CHECK_LIGHT) && !has_light_nearby() && !has_nightvision())
		if(!silent)
			to_chat(src, span_warning("It's too dark in here to read!"))
		return FALSE

	return TRUE

/**
 * Get the mob VV dropdown extras
 */
/mob/vv_get_dropdown()
	. = ..()
	VV_DROPDOWN_OPTION("", "---------")
	VV_DROPDOWN_OPTION(VV_HK_GIB, "Gib")
	VV_DROPDOWN_OPTION(VV_HK_GIVE_AI, "Give AI Controller")
	VV_DROPDOWN_OPTION(VV_HK_REMOVE_SPELL, "Remove Spell")
	VV_DROPDOWN_OPTION(VV_HK_GIVE_SPELL, "Give Spell")
	VV_DROPDOWN_OPTION(VV_HK_REMOVE_SPELL, "Remove Spell")
	VV_DROPDOWN_OPTION(VV_HK_GIVE_MOB_ACTION, "Give Mob Ability")
	VV_DROPDOWN_OPTION(VV_HK_REMOVE_MOB_ACTION, "Remove Mob Ability")
	VV_DROPDOWN_OPTION(VV_HK_GIVE_DISEASE, "Give Disease")
	VV_DROPDOWN_OPTION(VV_HK_GODMODE, "Toggle Godmode")
	VV_DROPDOWN_OPTION(VV_HK_DROP_ALL, "Drop Everything")
	VV_DROPDOWN_OPTION(VV_HK_REGEN_ICONS, "Regenerate Icons")
	VV_DROPDOWN_OPTION(VV_HK_REGEN_ICONS_FULL, "Regenerate Icons & Clear Stuck Overlays")
	VV_DROPDOWN_OPTION(VV_HK_PLAYER_PANEL, "Show player panel")
	VV_DROPDOWN_OPTION(VV_HK_BUILDMODE, "Toggle Buildmode")
	VV_DROPDOWN_OPTION(VV_HK_DIRECT_CONTROL, "Assume Direct Control")
	VV_DROPDOWN_OPTION(VV_HK_GIVE_DIRECT_CONTROL, "Give Direct Control")
	VV_DROPDOWN_OPTION(VV_HK_OFFER_GHOSTS, "Offer Control to Ghosts")
	VV_DROPDOWN_OPTION(VV_HK_VIEW_PLANES, "View/Edit Planes")

/mob/vv_do_topic(list/href_list)
	. = ..()

	if(!.)
		return

	if(href_list[VV_HK_REGEN_ICONS])
		if(!check_rights(NONE))
			return
		regenerate_icons()

	if(href_list[VV_HK_REGEN_ICONS_FULL])
		if(!check_rights(NONE))
			return
		cut_overlays()
		regenerate_icons()

	if(href_list[VV_HK_PLAYER_PANEL])
		return SSadmin_verbs.dynamic_invoke_verb(usr, /datum/admin_verb/show_player_panel, src)

	if(href_list[VV_HK_GODMODE])
		if(!check_rights(R_ADMIN))
			return
		usr.client.cmd_admin_godmode(src)

	if(href_list[VV_HK_GIVE_AI])
		return SSadmin_verbs.dynamic_invoke_verb(usr, /datum/admin_verb/give_ai_controller, src)

	if(href_list[VV_HK_GIVE_MOB_ACTION])
		return SSadmin_verbs.dynamic_invoke_verb(usr, /datum/admin_verb/give_mob_action, src)

	if(href_list[VV_HK_REMOVE_MOB_ACTION])
		return SSadmin_verbs.dynamic_invoke_verb(usr, /datum/admin_verb/remove_mob_action, src)

	if(href_list[VV_HK_GIVE_SPELL])
		return SSadmin_verbs.dynamic_invoke_verb(usr, /datum/admin_verb/give_spell, src)

	if(href_list[VV_HK_REMOVE_SPELL])
		return SSadmin_verbs.dynamic_invoke_verb(usr, /datum/admin_verb/remove_spell, src)

	if(href_list[VV_HK_GIVE_DISEASE])
		return SSadmin_verbs.dynamic_invoke_verb(usr, /datum/admin_verb/give_disease, src)

	if(href_list[VV_HK_GIB])
		return SSadmin_verbs.dynamic_invoke_verb(usr, /datum/admin_verb/gib_them, src)

	if(href_list[VV_HK_BUILDMODE])
		if(!check_rights(R_BUILD))
			return
		togglebuildmode(src)

	if(href_list[VV_HK_DROP_ALL])
		return SSadmin_verbs.dynamic_invoke_verb(usr, /datum/admin_verb/drop_everything, src)

	if(href_list[VV_HK_DIRECT_CONTROL])
		return SSadmin_verbs.dynamic_invoke_verb(usr, /datum/admin_verb/cmd_assume_direct_control, src)

	if(href_list[VV_HK_GIVE_DIRECT_CONTROL])
		return SSadmin_verbs.dynamic_invoke_verb(usr, /datum/admin_verb/cmd_give_direct_control, src)

	if(href_list[VV_HK_OFFER_GHOSTS])
		if(!check_rights(NONE))
			return
		offer_control(src)

	if(href_list[VV_HK_VIEW_PLANES])
		if(!check_rights(R_DEBUG))
			return
		usr.client.edit_plane_masters(src)
/**
 * extra var handling for the logging var
 */
/mob/vv_get_var(var_name)
	switch(var_name)
		if(NAMEOF(src, logging))
			return debug_variable(var_name, logging, 0, src, FALSE)
	. = ..()

/mob/vv_auto_rename(new_name)
	//Do not do parent's actions, as we *usually* do this differently.
	fully_replace_character_name(real_name, new_name)

///Show the language menu for this mob
/mob/verb/open_language_menu_verb()
	set name = "Open Language Menu"
	set category = "IC"

	get_language_holder().open_language_menu(usr)

///Adjust the nutrition of a mob
/mob/proc/adjust_nutrition(change, forced = FALSE) //Honestly FUCK the oldcoders for putting nutrition on /mob someone else can move it up because holy hell I'd have to fix SO many typechecks
	if(HAS_TRAIT(src, TRAIT_NOHUNGER) && !forced)
		return

	nutrition = max(0, nutrition + change)
	hud_used?.hunger?.update_appearance()

/mob/living/adjust_nutrition(change, forced)
	. = ..()
	mob_mood?.update_nutrition_moodlets()

///Force set the mob nutrition
/mob/proc/set_nutrition(set_to, forced = FALSE) //Seriously fuck you oldcoders.
	if(HAS_TRAIT(src, TRAIT_NOHUNGER) && !forced)
		return

	nutrition = max(0, set_to)
	hud_used?.hunger?.update_appearance()

/mob/living/set_nutrition(set_to, forced)
	. = ..()
	mob_mood?.update_nutrition_moodlets()

///Apply a proper movespeed modifier based on items we have equipped
/mob/proc/update_equipment_speed_mods()
	var/speedies = 0
	var/immutable_speedies = 0
	for(var/obj/item/thing in get_equipped_speed_mod_items())
		if(thing.item_flags & IMMUTABLE_SLOW)
			immutable_speedies += thing.slowdown
		else
			speedies += thing.slowdown

	//if  we have TRAIT_STURDY_FRAME, we reduce our overall speed penalty UNLESS that penalty would be a negative value, and therefore a speed boost.
	if(speedies > 0 && HAS_TRAIT(src, TRAIT_STURDY_FRAME))
		speedies *= 0.2

	if(immutable_speedies)
		add_or_update_variable_movespeed_modifier(
			/datum/movespeed_modifier/equipment_speedmod/immutable,
			multiplicative_slowdown = immutable_speedies,
		)
	else
		remove_movespeed_modifier(/datum/movespeed_modifier/equipment_speedmod/immutable)

	if(speedies)
		add_or_update_variable_movespeed_modifier(
			/datum/movespeed_modifier/equipment_speedmod,
			multiplicative_slowdown = speedies,
		)
	else
		remove_movespeed_modifier(/datum/movespeed_modifier/equipment_speedmod)

///Get all items in our possession that should affect our movespeed
/mob/proc/get_equipped_speed_mod_items()
	. = list()
	for(var/obj/item/thing in held_items)
		if(thing.item_flags & SLOWS_WHILE_IN_HAND)
			. += thing

/mob/proc/set_stat(new_stat)
	if(new_stat == stat)
		return
	. = stat
	stat = new_stat
	SEND_SIGNAL(src, COMSIG_MOB_STATCHANGE, new_stat, .)

/// Proc used for custom metabolization of reagents, if any
/mob/proc/reagent_check(datum/reagent/chem, seconds_per_tick, times_fired)
	SHOULD_CALL_PARENT(TRUE)
	return SEND_SIGNAL(src, COMSIG_MOB_REAGENT_CHECK, chem, seconds_per_tick, times_fired)

/mob/vv_edit_var(var_name, var_value)
	switch(var_name)
		if(NAMEOF(src, focus))
			set_focus(var_value)
			. = TRUE
		if(NAMEOF(src, nutrition))
			set_nutrition(var_value)
			. = TRUE
		if(NAMEOF(src, stat))
			set_stat(var_value)
			. = TRUE

	if(!isnull(.))
		datum_flags |= DF_VAR_EDITED
		return

	var/slowdown_edit = (var_name == NAMEOF(src, cached_multiplicative_slowdown))
	var/diff
	if(slowdown_edit && isnum(cached_multiplicative_slowdown) && isnum(var_value))
		remove_movespeed_modifier(/datum/movespeed_modifier/admin_varedit)
		diff = var_value - cached_multiplicative_slowdown

	. = ..()

	if(. && slowdown_edit && isnum(diff))
		add_or_update_variable_movespeed_modifier(/datum/movespeed_modifier/admin_varedit, multiplicative_slowdown = diff)

/// Cleanup proc that's called when a mob loses a client, either through client destroy or logout
/// Logout happens post client del, so we can't just copypaste this there. This keeps things clean and consistent
/mob/proc/become_uncliented()
	if(!canon_client)
		return

	for(var/foo in canon_client.player_details.post_logout_callbacks)
		var/datum/callback/CB = foo
		CB.Invoke()

	if(canon_client?.movingmob)
		LAZYREMOVE(canon_client.movingmob.client_mobs_in_contents, src)
		canon_client.movingmob = null

	clear_important_client_contents()
	canon_client = null

///Shows a tgui window with memories
/mob/verb/memory()
	set name = "Memories"
	set category = "IC"
	set desc = "View your character's memories."
	if(!mind)
		var/fail_message = "You have no mind!"
		if(isobserver(src))
			fail_message += " You have to be in the current round at some point to have one."
		to_chat(src, span_warning(fail_message))
		return
	if(!mind.memory_panel)
		mind.memory_panel = new(usr, mind)
	mind.memory_panel.ui_interact(usr)

/datum/memory_panel
	var/datum/mind/mind_reference
	var/client/holder //client of whoever is using this datum

/datum/memory_panel/New(user, mind_reference)//user can either be a client or a mob due to byondcode(tm)
	if (istype(user, /client))
		var/client/user_client = user
		holder = user_client //if its a client, assign it to holder
	else
		var/mob/user_mob = user
		holder = user_mob.client //if its a mob, assign the mob's client to holder
	src.mind_reference = mind_reference

/datum/memory_panel/Destroy(force)
	mind_reference.memory_panel = null
	. = ..()

/datum/memory_panel/ui_state(mob/user)
	return GLOB.always_state

/datum/memory_panel/ui_close()
	qdel(src)

/datum/memory_panel/ui_interact(mob/user, datum/tgui/ui)
	ui = SStgui.try_update_ui(user, src, ui)
	if(!ui)
		ui = new(user, src, "MemoryPanel")
		ui.open()

/datum/memory_panel/ui_data(mob/user)
	var/list/data = list()
	var/list/memories = list()

	for(var/memory_key in user?.mind.memories)
		var/datum/memory/memory = user.mind.memories[memory_key]
		memories += list(list("name" = memory.name, "quality" = memory.story_value))

	data["memories"] = memories
	return data

/mob/verb/view_skills()
	set category = "IC"
	set name = "View Skills"

	mind?.print_levels(src)

/mob/key_down(key, client/client, full_key)
	..()
	SEND_SIGNAL(src, COMSIG_MOB_KEYDOWN, key, client, full_key)

/mob/proc/setup_hud_traits()
	for(var/hud_trait in GLOB.trait_to_hud)
		RegisterSignal(src, SIGNAL_ADDTRAIT(hud_trait), PROC_REF(hud_trait_enabled))
		RegisterSignal(src, SIGNAL_REMOVETRAIT(hud_trait), PROC_REF(hud_trait_disabled))

/mob/proc/hud_trait_enabled(datum/source, new_trait)
	SIGNAL_HANDLER
	var/datum/atom_hud/datahud = GLOB.huds[GLOB.trait_to_hud[new_trait]]
	datahud.show_to(src)

/mob/proc/hud_trait_disabled(datum/source, new_trait)
	SIGNAL_HANDLER
	var/datum/atom_hud/datahud = GLOB.huds[GLOB.trait_to_hud[new_trait]]
	datahud.hide_from(src)
