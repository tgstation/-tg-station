// see _DEFINES/is_helpers.dm for mob type checks

///Find the mob at the bottom of a buckle chain
/mob/proc/lowest_buckled_mob()
	. = src
	if(buckled && ismob(buckled))
		var/mob/Buckled = buckled
		. = Buckled.lowest_buckled_mob()

///Convert a PRECISE ZONE into the BODY_ZONE
/proc/check_zone(zone)
	if(!zone)
		return BODY_ZONE_CHEST
	switch(zone)
		if(BODY_ZONE_PRECISE_EYES)
			zone = BODY_ZONE_HEAD
		if(BODY_ZONE_PRECISE_MOUTH)
			zone = BODY_ZONE_HEAD
		if(BODY_ZONE_PRECISE_L_HAND)
			zone = BODY_ZONE_L_ARM
		if(BODY_ZONE_PRECISE_R_HAND)
			zone = BODY_ZONE_R_ARM
		if(BODY_ZONE_PRECISE_L_FOOT)
			zone = BODY_ZONE_L_LEG
		if(BODY_ZONE_PRECISE_R_FOOT)
			zone = BODY_ZONE_R_LEG
		if(BODY_ZONE_PRECISE_GROIN)
			zone = BODY_ZONE_CHEST
	return zone

/**
 * Return the zone or randomly, another valid zone
 *
 * probability controls the chance it chooses the passed in zone, or another random zone
 * defaults to 80
 */
/proc/ran_zone(zone, probability = 80, list/weighted_list)
	if(prob(probability))
		zone = check_zone(zone)
	else
		zone = pick_weight(weighted_list ? weighted_list : list(BODY_ZONE_HEAD = 1, BODY_ZONE_CHEST = 1, BODY_ZONE_L_ARM = 4, BODY_ZONE_R_ARM = 4, BODY_ZONE_L_LEG = 4, BODY_ZONE_R_LEG = 4))
	return zone


/**
 * More or less ran_zone, but only returns bodyzones that the mob /actually/ has.
 *
 * * blacklisted_parts - allows you to specify zones that will not be chosen. eg: list(BODY_ZONE_CHEST, BODY_ZONE_R_LEG)
 * * * !!!! blacklisting BODY_ZONE_CHEST is really risky since it's the only bodypart guarunteed to ALWAYS exists  !!!!
 * * * !!!! Only do that if you're REALLY CERTAIN they have limbs, otherwise we'll CRASH() !!!!
 *
 * * ran_zone has a base prob(80) to return the base_zone (or if null, BODY_ZONE_CHEST) vs something in our generated list of limbs.
 * * this probability is overriden when either blacklisted_parts contains BODY_ZONE_CHEST and we aren't passed a base_zone (since the default fallback for ran_zone would be the chest in that scenario), or if even_weights is enabled.
 * * you can also manually adjust this probability by altering base_probability
 *
 * * even_weights - ran_zone has a 40% chance (after the prob(80) mentioned above) of picking a limb, vs the torso & head which have an additional 10% chance.
 * * Setting even_weight to TRUE will make it just a straight up pick() between all possible bodyparts.
 *
 */
/mob/proc/get_random_valid_zone(base_zone, base_probability = 80, list/blacklisted_parts, even_weights, bypass_warning)
	return BODY_ZONE_CHEST //even though they don't really have a chest, let's just pass the default of check_zone to be safe.

/mob/living/carbon/get_random_valid_zone(base_zone, base_probability = 80, list/blacklisted_parts, even_weights, bypass_warning)
	var/list/limbs = list()
	for(var/obj/item/bodypart/part as anything in bodyparts)
		var/limb_zone = part.body_zone //cache the zone since we're gonna check it a ton.
		if(limb_zone in blacklisted_parts)
			continue
		if(even_weights)
			limbs[limb_zone] = 1
			continue
		if(limb_zone == BODY_ZONE_CHEST || limb_zone == BODY_ZONE_HEAD)
			limbs[limb_zone] = 1
		else
			limbs[limb_zone] = 4

	if(base_zone && !(check_zone(base_zone) in limbs))
		base_zone = null //check if the passed zone is infact valid

	var/chest_blacklisted
	if((BODY_ZONE_CHEST in blacklisted_parts))
		chest_blacklisted = TRUE
		if(bypass_warning && !limbs.len)
			CRASH("limbs is empty and the chest is blacklisted. this may not be intended!")
	return (((chest_blacklisted && !base_zone) || even_weights) ? pick_weight(limbs) : ran_zone(base_zone, base_probability, limbs))

///Would this zone be above the neck
/proc/above_neck(zone)
	var/list/zones = list(BODY_ZONE_HEAD, BODY_ZONE_PRECISE_MOUTH, BODY_ZONE_PRECISE_EYES)
	if(zones.Find(zone))
		return TRUE
	else
		return FALSE

/**
 * Convert random parts of a passed in message to stars
 *
 * * phrase - the string to convert
 * * probability - probability any character gets changed
 *
 * This proc is dangerously laggy, avoid it or die
 */
/proc/stars(phrase, probability = 25)
	if(probability <= 0)
		return phrase
	phrase = html_decode(phrase)
	var/leng = length(phrase)
	. = ""
	var/char = ""
	for(var/i = 1, i <= leng, i += length(char))
		char = phrase[i]
		if(char == " " || !prob(probability))
			. += char
		else
			. += "*"
	return sanitize(.)

/**
 * For when you're only able to speak a limited amount of words
 * phrase - the string to convert
 * definitive_limit - the amount of words to limit the phrase to, optional
*/
/proc/stifled(phrase, definitive_limit = null)
	phrase = html_decode(phrase)
	var/num_words = 0
	var/words = splittext(phrase, " ")
	if(definitive_limit > 0) // in case someone passes a negative
		num_words = min(definitive_limit, length(words))
	else
		num_words = min(rand(3, 5), length(words))
	. = ""
	for(var/i = 1, i <= num_words, i++)
		if(num_words == i)
			. += words[i] + "..."
		else
			. += words[i] + " ... "
	return sanitize(.)

/**
 * Turn text into complete gibberish!
 *
 * text is the inputted message, replace_characters will cause original letters to be replaced and chance are the odds that a character gets modified.
 */
/proc/Gibberish(text, replace_characters = FALSE, chance = 50)
	text = html_decode(text)
	. = ""
	var/rawchar = ""
	var/letter = ""
	var/lentext = length(text)
	for(var/i = 1, i <= lentext, i += length(rawchar))
		rawchar = letter = text[i]
		if(prob(chance))
			if(replace_characters)
				letter = ""
			for(var/j in 1 to rand(0, 2))
				letter += pick("#", "@", "*", "&", "%", "$", "/", "<", ">", ";", "*", "*", "*", "*", "*", "*", "*")
		. += letter
	return sanitize(.)

#define TILES_PER_SECOND 0.7
///Shake the camera of the person viewing the mob SO REAL!
///Takes the mob to shake, the time span to shake for, and the amount of tiles we're allowed to shake by in tiles
///Duration isn't taken as a strict limit, since we don't trust our coders to not make things feel shitty. So it's more like a soft cap.
/proc/shake_camera(mob/M, duration, strength=1)
	if(!M || !M.client || duration < 1)
		return
	var/client/C = M.client
	var/oldx = C.pixel_x
	var/oldy = C.pixel_y
	var/max_x = strength*ICON_SIZE_X
	var/max_y = strength*ICON_SIZE_Y
	var/min_x = -(strength*ICON_SIZE_X)
	var/min_y = -(strength*ICON_SIZE_Y)

	if(C.prefs?.read_preference(/datum/preference/toggle/screen_shake_darken))
		var/type = /atom/movable/screen/fullscreen/flash/black

		M.overlay_fullscreen("flash", type)
		addtimer(CALLBACK(M, TYPE_PROC_REF(/mob, clear_fullscreen), "flash", 3 SECONDS), 3 SECONDS)

	//How much time to allot for each pixel moved
	var/time_scalar = (1 / ICON_SIZE_ALL) * TILES_PER_SECOND
	var/last_x = oldx
	var/last_y = oldy

	var/time_spent = 0
	while(time_spent < duration)
		//Get a random pos in our box
		var/x_pos = rand(min_x, max_x) + oldx
		var/y_pos = rand(min_y, max_y) + oldy

		//We take the smaller of our two distances so things still have the propencity to feel somewhat jerky
		var/time = round(max(min(abs(last_x - x_pos), abs(last_y - y_pos)) * time_scalar, 1))

		if (time_spent == 0)
			animate(C, pixel_x=x_pos, pixel_y=y_pos, time=time)
		else
			animate(pixel_x=x_pos, pixel_y=y_pos, time=time)

		last_x = x_pos
		last_y = y_pos
		//We go based on time spent, so there is a chance we'll overshoot our duration. Don't care
		time_spent += time

	animate(pixel_x=oldx, pixel_y=oldy, time=3)

#undef TILES_PER_SECOND

///Find if the message has the real name of any user mob in the mob_list
/proc/findname(msg)
	if(!istext(msg))
		msg = "[msg]"
	for(var/i in GLOB.mob_list)
		var/mob/M = i
		if(M.real_name == msg)
			return M
	return 0

///Returns a mob's real name between brackets. Useful when you want to display a mob's name alongside their real name
/mob/proc/get_realname_string()
	if(real_name && real_name != name)
		return " \[[real_name]\]"
	return ""

// moved out of admins.dm because things other than admin procs were calling this.
/**
 * Returns TRUE if the game has started and we're either an AI with a 0th law, or we're someone with a special role/antag datum
 * If allow_fake_antags is set to FALSE, Valentines, ERTs, and any such roles with FLAG_FAKE_ANTAG won't pass.
*/
/proc/is_special_character(mob/M, allow_fake_antags = FALSE)
	if(!SSticker.HasRoundStarted())
		return FALSE
	if(!istype(M))
		return FALSE
	if(iscyborg(M)) //as a borg you're now beholden to your laws rather than greentext
		return FALSE


	// Returns TRUE if AI has a zeroth law *and* either has a special role *or* an antag datum.
	if(isAI(M))
		var/mob/living/silicon/ai/A = M
		return (A.laws?.zeroth && (A.mind?.special_role || !isnull(M.mind?.antag_datums)))

	if(M.mind?.special_role)
		return TRUE

	// Turns 'faker' to TRUE if the antag datum is fake. If it's not fake, returns TRUE directly.
	var/faker = FALSE
	for(var/datum/antagonist/antag_datum as anything in M.mind?.antag_datums)
		if((antag_datum.antag_flags & FLAG_FAKE_ANTAG))
			faker = TRUE
		else
			return TRUE

	// If 'faker' was assigned TRUE in the above loop and the argument 'allow_fake_antags' is set to TRUE, this passes.
	// Else, return FALSE.
	return (faker && allow_fake_antags)

/**
 * Fancy notifications for ghosts
 *
 * The kitchen sink of notification procs
 *
 * Arguments:
 * * message: The message displayed in chat.
 * * source: The source of the notification. This is required for an icon
 * * header: The title text to display on the icon tooltip.
 * * alert_overlay: Optional. Create a custom overlay if you want, otherwise it will use the source
 * * click_interact: If true, adds a link + clicking the icon will attack_ghost the source
 * * custom_link: Optional. If you want to add a custom link to the chat notification
 * * ghost_sound: sound to play
 * * ignore_key: Ignore keys if they're in the GLOB.poll_ignore list
 * * notify_volume: How loud the sound should be to spook the user
 */
/proc/notify_ghosts(
	message,
	atom/source,
	header = "Something Interesting!",
	mutable_appearance/alert_overlay,
	click_interact = FALSE,
	custom_link = "",
	ghost_sound,
	ignore_key,
	notify_flags = NOTIFY_CATEGORY_DEFAULT,
	notify_volume = 100,
)

	if(notify_flags & GHOST_NOTIFY_IGNORE_MAPLOAD && SSatoms.initialized != INITIALIZATION_INNEW_REGULAR) //don't notify for objects created during a map load
		return

	if(source)
		if(isnull(alert_overlay))
			alert_overlay = get_small_overlay(source)

		alert_overlay.appearance_flags |= TILE_BOUND
		alert_overlay.layer = FLOAT_LAYER
		alert_overlay.plane = FLOAT_PLANE

	for(var/mob/dead/observer/ghost in GLOB.player_list)
		if(!(notify_flags & GHOST_NOTIFY_NOTIFY_SUICIDERS) && HAS_TRAIT(ghost, TRAIT_SUICIDED))
			continue
		if(ignore_key && (ghost.ckey in GLOB.poll_ignore[ignore_key]))
			continue

		if(notify_flags & GHOST_NOTIFY_FLASH_WINDOW)
			window_flash(ghost.client)

		if(ghost_sound)
			SEND_SOUND(ghost, sound(ghost_sound, volume = notify_volume))

		if(isnull(source))
			to_chat(ghost, span_ghostalert(message))
			continue

		var/interact_link = click_interact ? " <a href='byond://?src=[REF(ghost)];play=[REF(source)]'>(Play)</a>" : ""
		var/view_link = " <a href='byond://?src=[REF(ghost)];view=[REF(source)]'>(View)</a>"

		to_chat(ghost, span_ghostalert("[message][custom_link][interact_link][view_link]"))

		var/atom/movable/screen/alert/notify_action/toast = ghost.throw_alert(
			category = "[REF(source)]_notify_action",
			type = /atom/movable/screen/alert/notify_action,
		)
		toast.add_overlay(alert_overlay)
		toast.click_interact = click_interact
		toast.desc = "Click to [click_interact ? "play" : "view"]."
		toast.name = header
		toast.target_ref = WEAKREF(source)



///Is the passed in mob a ghost with admin powers, doesn't check for AI interact like isAdminGhost() used to
/proc/isAdminObserver(mob/user)
	if(!user) //Are they a mob? Auto interface updates call this with a null src
		return
	if(!user.client) // Do they have a client?
		return
	if(!isobserver(user)) // Are they a ghost?
		return
	if(!check_rights_for(user.client, R_ADMIN)) // Are they allowed?
		return
	return TRUE

///Returns TRUE/FALSE on whether the mob is an Admin Ghost AI.
///This requires this snowflake check because AI interact gives the access to the mob's client, rather
///than the mob like everyone else, and we keep it that way so they can't accidentally give someone Admin AI access.
/proc/isAdminGhostAI(mob/user)
	if(!isAdminObserver(user))
		return FALSE
	if(!HAS_TRAIT_FROM(user.client, TRAIT_AI_ACCESS, ADMIN_TRAIT)) // Do they have it enabled?
		return FALSE
	return TRUE

/**
 * Offer control of the passed in mob to dead player
 *
 * Automatic logging and uses poll_candidates_for_mob, how convenient
 */
/proc/offer_control(mob/M)
	to_chat(M, "Control of your mob has been offered to dead players.")
	if(usr)
		log_admin("[key_name(usr)] has offered control of ([key_name(M)]) to ghosts.")
		message_admins("[key_name_admin(usr)] has offered control of ([ADMIN_LOOKUPFLW(M)]) to ghosts")
	var/poll_message = "Do you want to play as [span_danger(M.real_name)]?"
	if(M.mind)
		poll_message = "[poll_message] Job: [span_notice(M.mind.assigned_role.title)]."
		if(M.mind.special_role)
			poll_message = "[poll_message] Status: [span_boldnotice(M.mind.special_role)]."
		else
			var/datum/antagonist/A = M.mind.has_antag_datum(/datum/antagonist/)
			if(A)
				poll_message = "[poll_message] Status: [span_boldnotice(A.name)]."
	var/mob/chosen_one = SSpolling.poll_ghosts_for_target(poll_message, check_jobban = ROLE_PAI, poll_time = 10 SECONDS, checked_target = M, alert_pic = M, role_name_text = "ghost control")

	if(chosen_one)
		to_chat(M, "Your mob has been taken over by a ghost!")
		message_admins("[key_name_admin(chosen_one)] has taken control of ([ADMIN_LOOKUPFLW(M)])")
		M.ghostize(FALSE)
		M.PossessByPlayer(chosen_one.key)
		M.client?.init_verbs()
		return TRUE
	else
		to_chat(M, "There were no ghosts willing to take control.")
		message_admins("No ghosts were willing to take control of [ADMIN_LOOKUPFLW(M)])")
		return FALSE

///Clicks a random nearby mob with the source from this mob
/mob/proc/click_random_mob()
	var/list/nearby_mobs = list()
	for(var/mob/living/L in range(1, src))
		if(L != src)
			nearby_mobs |= L
	if(nearby_mobs.len)
		var/mob/living/T = pick(nearby_mobs)
		ClickOn(T)

///Can the mob hear
/mob/proc/can_hear()
	return !HAS_TRAIT(src, TRAIT_DEAF)

/**
 * Get the list of keywords for policy config
 *
 * This gets the type, mind assigned roles and antag datums as a list, these are later used
 * to send the user relevant headadmin policy config
 */
/mob/proc/get_policy_keywords()
	. = list()
	. += "[type]"
	if(mind)
		if(mind.assigned_role.policy_index)
			. += mind.assigned_role.policy_index
		. += mind.assigned_role.title //A bit redunant, but both title and policy index are used
		. += mind.special_role //In case there's something special leftover, try to avoid
		for(var/datum/antagonist/antag_datum as anything in mind.antag_datums)
			. += "[antag_datum.type]"

///Can the mob see reagents inside of containers?
/mob/proc/can_see_reagents()
	return stat == DEAD || HAS_TRAIT(src, TRAIT_REAGENT_SCANNER) //Dead guys and silicons can always see reagents

///Can this mob hold items
/mob/proc/can_hold_items(obj/item/I)
	return length(held_items)

/// Returns this mob's default lighting alpha
/mob/proc/default_lighting_cutoff()
	if(client?.combo_hud_enabled && client?.prefs?.toggles & COMBOHUD_LIGHTING)
		return LIGHTING_CUTOFF_FULLBRIGHT
	return initial(lighting_cutoff)

/// Returns a generic path of the object based on the slot
/proc/get_path_by_slot(slot_id)
	switch(slot_id)
		if(ITEM_SLOT_BACK)
			return /obj/item/storage/backpack
		if(ITEM_SLOT_MASK)
			return /obj/item/clothing/mask
		if(ITEM_SLOT_NECK)
			return /obj/item/clothing/neck
		if(ITEM_SLOT_HANDCUFFED)
			return /obj/item/restraints/handcuffs
		if(ITEM_SLOT_LEGCUFFED)
			return /obj/item/restraints/legcuffs
		if(ITEM_SLOT_BELT)
			return /obj/item/storage/belt
		if(ITEM_SLOT_ID)
			return /obj/item/card/id/advanced
		if(ITEM_SLOT_EARS)
			return /obj/item/clothing/ears
		if(ITEM_SLOT_EYES)
			return /obj/item/clothing/glasses
		if(ITEM_SLOT_GLOVES)
			return /obj/item/clothing/gloves
		if(ITEM_SLOT_HEAD)
			return /obj/item/clothing/head
		if(ITEM_SLOT_FEET)
			return /obj/item/clothing/shoes
		if(ITEM_SLOT_OCLOTHING)
			return /obj/item/clothing/suit
		if(ITEM_SLOT_ICLOTHING)
			return /obj/item/clothing/under
		if(ITEM_SLOT_LPOCKET)
			return /obj/item
		if(ITEM_SLOT_RPOCKET)
			return /obj/item
		if(ITEM_SLOT_SUITSTORE)
			return /obj/item
	return null

/// Returns a client from a mob, mind or client
/proc/get_player_client(player)
	if(ismob(player))
		var/mob/player_mob = player
		player = player_mob.client
	else if(istype(player, /datum/mind))
		var/datum/mind/player_mind = player
		player = player_mind.current.client
	if(!istype(player, /client))
		return
	return player

/proc/health_percentage(mob/living/mob)
	var/divided_health = mob.health / mob.maxHealth
	if(iscyborg(mob) || islarva(mob))
		divided_health = (mob.health + mob.maxHealth) / (mob.maxHealth * 2)
	else if(iscarbon(mob) || isAI(mob) || isbrain(mob))
		divided_health = abs(HEALTH_THRESHOLD_DEAD - mob.health) / abs(HEALTH_THRESHOLD_DEAD - mob.maxHealth)
	return divided_health * 100

/**
 * Generates a log message when a user manually changes their targeted zone.
 * Only need to one of new_target or old_target, and the other will be auto populated with the current selected zone.
 */
/mob/proc/log_manual_zone_selected_update(source, new_target, old_target)
	if(!new_target && !old_target)
		CRASH("Called log_manual_zone_selected_update without specifying a new or old target")

	old_target ||= zone_selected
	new_target ||= zone_selected
	if(old_target == new_target)
		return

	var/list/data = list(
		"new_target" = new_target,
		"old_target" = old_target,
	)

	if(mind?.assigned_role)
		data["assigned_role"] = mind.assigned_role.title
	if(job)
		data["assigned_job"] = job

	var/atom/handitem = get_active_held_item()
	if(handitem)
		data["active_item"] = list(
			"type" = handitem.type,
			"name" = handitem.name,
		)

	var/atom/offhand = get_inactive_held_item()
	if(offhand)
		data["offhand_item"] = list(
			"type" = offhand.type,
			"name" = offhand.name,
		)

	logger.Log(
		LOG_CATEGORY_TARGET_ZONE_SWITCH,
		"[key_name(src)] manually changed selected zone",
		data,
	)

/**
 * Returns an associative list of the logs of a certain amount of lines spoken recently by this mob
 * copy_amount - number of lines to return
 * line_chance - chance to return a line, if you don't want just the most recent x lines
 */
/mob/proc/copy_recent_speech(copy_amount = LING_ABSORB_RECENT_SPEECH, line_chance = 100)
	var/list/recent_speech = list()
	var/list/say_log = list()
	var/log_source = logging
	for(var/log_type in log_source)
		var/nlog_type = text2num(log_type)
		if(nlog_type & LOG_SAY)
			var/list/reversed = log_source[log_type]
			if(islist(reversed))
				say_log = reverse_range(reversed.Copy())
				break

	for(var/spoken_memory in say_log)
		if(recent_speech.len >= copy_amount)
			break
		if(!prob(line_chance))
			continue
		recent_speech[spoken_memory] = splittext(say_log[spoken_memory], "\"", 1, 0, TRUE)[3]

	var/list/raw_lines = list()
	for (var/key as anything in recent_speech)
		raw_lines += recent_speech[key]

	return raw_lines

/// Takes in an associated list (key `/datum/action` typepaths, value is the AI blackboard key) and handles granting the action and adding it to the mob's AI controller blackboard.
/// This is only useful in instances where you don't want to store the reference to the action on a variable on the mob.
/// You can set the value to null if you don't want to add it to the blackboard (like in player controlled instances). Is also safe with null AI controllers.
/// Assumes that the action will be initialized and held in the mob itself, which is typically standard.
/mob/proc/grant_actions_by_list(list/input)
	if(length(input) <= 0)
		return

	for(var/action in input)
		var/datum/action/ability = new action(src)
		ability.Grant(src)

		var/blackboard_key = input[action]
		if(isnull(blackboard_key))
			continue

		ai_controller?.set_blackboard_key(blackboard_key, ability)
