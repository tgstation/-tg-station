/obj/item/clothing/under
	name = "under"
	icon = 'icons/obj/clothing/under/default.dmi'
	worn_icon = 'icons/mob/clothing/under/default.dmi'
	lefthand_file = 'icons/mob/inhands/clothing/suits_lefthand.dmi'
	righthand_file = 'icons/mob/inhands/clothing/suits_righthand.dmi'
	body_parts_covered = CHEST|GROIN|LEGS|ARMS
	slot_flags = ITEM_SLOT_ICLOTHING
	interaction_flags_click = NEED_DEXTERITY
	armor_type = /datum/armor/clothing_under
	supports_variations_flags = CLOTHING_DIGITIGRADE_MASK
	equip_sound = 'sound/items/equip/jumpsuit_equip.ogg'
	drop_sound = 'sound/items/handling/cloth/cloth_drop1.ogg'
	pickup_sound = 'sound/items/handling/cloth/cloth_pickup1.ogg'
	limb_integrity = 30
	interaction_flags_click = ALLOW_RESTING

	/// Has this undersuit been freshly laundered and, as such, imparts a mood bonus for wearing
	var/freshly_laundered = FALSE

	// Alt style handling
	/// Can this suit be adjustd up or down to an alt style
	var/can_adjust = TRUE
	/// If adjusted what style are we currently using?
	var/adjusted = NORMAL_STYLE
	/// For adjusted/rolled-down jumpsuits. FALSE = exposes chest and arms, TRUE = exposes arms only
	var/alt_covers_chest = FALSE
	/// The variable containing the flags for how the woman uniform cropping is supposed to interact with the sprite.
	var/female_sprite_flags = FEMALE_UNIFORM_FULL

	// Sensor handling
	/// Does this undersuit have suit sensors in general
	var/has_sensor = HAS_SENSORS
	/// Does this undersuit spawn with a random sensor value
	var/random_sensor = TRUE
	/// What is the active sensor mode of this udnersuit
	var/sensor_mode = NO_SENSORS

	// Accessory handling (Can be componentized eventually)
	/// The max number of accessories we can have on this suit.
	var/max_number_of_accessories = 5
	/// A list of all accessories attached to us.
	var/list/obj/item/clothing/accessory/attached_accessories
	/// The overlay of the accessory we're demonstrating. Only index 1 will show up.
	/// This is the overlay on the MOB, not the item itself.
	var/mutable_appearance/accessory_overlay

/datum/armor/clothing_under
	bio = 10
	wound = 5

/obj/item/clothing/under/Initialize(mapload)
	. = ..()
	if(random_sensor)
		//make the sensor mode favor higher levels, except coords.
		sensor_mode = pick(SENSOR_VITALS, SENSOR_VITALS, SENSOR_VITALS, SENSOR_LIVING, SENSOR_LIVING, SENSOR_COORDS, SENSOR_COORDS, SENSOR_OFF)
	register_context()
	AddElement(/datum/element/update_icon_updates_onmob, flags = ITEM_SLOT_ICLOTHING|ITEM_SLOT_OCLOTHING|ITEM_SLOT_NECK, body = TRUE)

/obj/item/clothing/under/setup_reskinning()
	if(!check_setup_reskinning())
		return

	// We already register context in Initialize.
	RegisterSignal(src, COMSIG_CLICK_ALT, PROC_REF(on_click_alt_reskin))

/obj/item/clothing/under/add_context(atom/source, list/context, obj/item/held_item, mob/living/user)
	. = ..()

	var/changed = FALSE

	if((isnull(held_item) || held_item == src) && has_sensor == HAS_SENSORS)
		context[SCREENTIP_CONTEXT_RMB] = "Toggle suit sensors"
		context[SCREENTIP_CONTEXT_CTRL_LMB] = "Set suit sensors to tracking"
		changed = TRUE

	if(istype(held_item, /obj/item/clothing/accessory) && length(attached_accessories) < max_number_of_accessories)
		context[SCREENTIP_CONTEXT_LMB] = "Attach accessory"
		changed = TRUE

	if(LAZYLEN(attached_accessories))
		context[SCREENTIP_CONTEXT_ALT_RMB] = "Remove accessory"
		changed = TRUE

	if(istype(held_item, /obj/item/stack/cable_coil) && has_sensor == BROKEN_SENSORS)
		context[SCREENTIP_CONTEXT_LMB] = "Repair suit sensors"
		changed = TRUE

	if(can_adjust && adjusted != DIGITIGRADE_STYLE)
		context[SCREENTIP_CONTEXT_ALT_LMB] =  "Wear [adjusted == ALT_STYLE ? "normally" : "casually"]"
		changed = TRUE

	return changed ? CONTEXTUAL_SCREENTIP_SET : .


/obj/item/clothing/under/worn_overlays(mutable_appearance/standing, isinhands = FALSE)
	. = ..()
	if(isinhands)
		return

	if(damaged_clothes)
		. += mutable_appearance('icons/effects/item_damage.dmi', "damageduniform")
	if(GET_ATOM_BLOOD_DNA_LENGTH(src))
		. += mutable_appearance('icons/effects/blood.dmi', "uniformblood")
	if(accessory_overlay)
		. += accessory_overlay

/obj/item/clothing/under/attackby(obj/item/attacking_item, mob/user, params)
	if(repair_sensors(attacking_item, user))
		return TRUE

	if(istype(attacking_item, /obj/item/clothing/accessory))
		return attach_accessory(attacking_item, user)

	return ..()

/obj/item/clothing/under/attack_hand_secondary(mob/user, params)
	. = ..()
	if(. == SECONDARY_ATTACK_CANCEL_ATTACK_CHAIN)
		return

	toggle()
	return SECONDARY_ATTACK_CANCEL_ATTACK_CHAIN

/obj/item/clothing/under/attack_self_secondary(mob/user, modifiers)
	. = ..()
	if(. == SECONDARY_ATTACK_CANCEL_ATTACK_CHAIN)
		return

	toggle()
	return SECONDARY_ATTACK_CANCEL_ATTACK_CHAIN

/obj/item/clothing/under/update_clothes_damaged_state(damaged_state = CLOTHING_DAMAGED)
	. = ..()
	if(damaged_state == CLOTHING_SHREDDED && has_sensor > NO_SENSORS)
		break_sensors()
	else if(damaged_state == CLOTHING_PRISTINE && has_sensor == BROKEN_SENSORS)
		repair_sensors(cable_required = FALSE)
	update_appearance()

/obj/item/clothing/under/visual_equipped(mob/user, slot)
	. = ..()
	if(adjusted == ALT_STYLE)
		adjust_to_normal()

	if((supports_variations_flags & CLOTHING_DIGITIGRADE_VARIATION) && ishuman(user))
		var/mob/living/carbon/human/wearer = user
		if(wearer.bodyshape & BODYSHAPE_DIGITIGRADE)
			adjusted = DIGITIGRADE_STYLE
			update_appearance()

/obj/item/clothing/under/generate_digitigrade_icons(icon/base_icon, greyscale_colors)
	var/icon/legs = icon(SSgreyscale.GetColoredIconByType(/datum/greyscale_config/digitigrade, greyscale_colors), "jumpsuit_worn")
	return replace_icon_legs(base_icon, legs)

/obj/item/clothing/under/equipped(mob/living/user, slot)
	..()
	if((slot & ITEM_SLOT_ICLOTHING) && freshly_laundered)
		freshly_laundered = FALSE
		user.add_mood_event("fresh_laundry", /datum/mood_event/fresh_laundry)

// Start suit sensor handling

/// Change the suit sensor state to broken and update the mob's status on the global sensor list
/obj/item/clothing/under/proc/break_sensors()
	if(has_sensor == BROKEN_SENSORS || has_sensor == NO_SENSORS)
		return

	visible_message(span_warning("[src]'s medical sensors short out!"), blind_message = span_warning("The [src] makes an electronic sizzling sound!"), vision_distance = COMBAT_MESSAGE_RANGE)
	has_sensor = BROKEN_SENSORS
	sensor_malfunction()
	update_wearer_status()

/**
 * Repair the suit sensors and update the mob's status on the global sensor list.
 * Can be called either through player action such as repairing with coil, or as part of a general fixing proc
 *
 * Arguments:
 * * attacking_item - the item being used for the repair, if any
 * * user - mob that's doing the repair
 * * cable_required - set to FALSE to bypass consuming cable coil
 */
/obj/item/clothing/under/proc/repair_sensors(obj/item/attacking_item, mob/user, cable_required = TRUE)
	if(has_sensor != BROKEN_SENSORS)
		return

	if(cable_required)
		if(!istype(attacking_item, /obj/item/stack/cable_coil))
			return
		var/obj/item/stack/cable_coil/cabling = attacking_item
		if(!cabling.use(1))
			return
		cabling.visible_message(span_notice("[user] repairs the suit sensors on [src] with [cabling]."))

	playsound(source = src, soundin = 'sound/effects/sparks/sparks4.ogg', vol = 100, vary = TRUE, extrarange = SHORT_RANGE_SOUND_EXTRARANGE, ignore_walls = FALSE)
	has_sensor = HAS_SENSORS
	update_wearer_status()

	return TRUE

/// If the item is being worn, a gentle reminder every 3-5 minutes that the sensors are broken
/obj/item/clothing/under/proc/sensor_malfunction()
	if(!QDELETED(src) && has_sensor == BROKEN_SENSORS && ishuman(loc))
		do_sparks(number = 2, cardinal_only = FALSE, source = src)
		addtimer(CALLBACK(src, PROC_REF(sensor_malfunction)), rand(BROKEN_SPARKS_MIN, BROKEN_SPARKS_MAX * 0.5), TIMER_UNIQUE | TIMER_NO_HASH_WAIT)

/// If the item is being worn, update the mob's status on the global sensor list
/obj/item/clothing/under/proc/update_wearer_status()
	if(!ishuman(loc))
		return

	var/mob/living/carbon/human/ooman = loc
	ooman.update_suit_sensors()
	ooman.med_hud_set_status()

/mob/living/carbon/human/update_suit_sensors()
	. = ..()
	update_sensor_list()

/// Adds or removes a mob from the global suit sensors list based on sensor status and mode
/mob/living/carbon/human/proc/update_sensor_list()
	var/obj/item/clothing/under/uniform = w_uniform
	if(istype(uniform) && uniform.has_sensor > NO_SENSORS && uniform.sensor_mode)
		GLOB.suit_sensors_list |= src
	else
		GLOB.suit_sensors_list -= src

/mob/living/carbon/human/dummy/update_sensor_list()
	return

/obj/item/clothing/under/emp_act(severity)
	. = ..()
	if(. & EMP_PROTECT_SELF)
		return
	if(has_sensor == NO_SENSORS || has_sensor == BROKEN_SENSORS)
		return

	if(severity <= EMP_HEAVY)
		break_sensors()

	else
		sensor_mode = pick(SENSOR_OFF, SENSOR_OFF, SENSOR_OFF, SENSOR_LIVING, SENSOR_LIVING, SENSOR_VITALS, SENSOR_VITALS, SENSOR_COORDS)
		playsound(source = src, soundin = 'sound/effects/sparks/sparks3.ogg', vol = 75, vary = TRUE, extrarange = SHORT_RANGE_SOUND_EXTRARANGE, ignore_walls = FALSE)
		visible_message(span_warning("The [src]'s medical sensors flash and change rapidly!"), blind_message = span_warning("The [src] makes an electronic sizzling sound!"), vision_distance = COMBAT_MESSAGE_RANGE)

	update_wearer_status()

/**
 * Called by medical scanners a simple summary of the status
 *
 * Arguments:
 * * silent: If TRUE, will return blank if everything is fine
 */
/obj/item/clothing/under/proc/get_sensor_text(silent = TRUE)
	if(has_sensor == BROKEN_SENSORS)
		return "<font color='#ffcc33'>Non-Functional: Repair with cable coil</font>"

	if(silent)
		return ""

	switch(has_sensor)
		if(NO_SENSORS)
			return "Not Present"

		if(LOCKED_SENSORS)
			return "Functional, Locked"

		if(HAS_SENSORS)
			return "Functional"

// End suit sensor handling

/// Attach the passed accessory to the clothing item
/obj/item/clothing/under/proc/attach_accessory(obj/item/clothing/accessory/accessory, mob/living/user, attach_message = TRUE)
	if(!istype(accessory))
		return
	if(!accessory.can_attach_accessory(src, user))
		return
	if(user && !user.temporarilyRemoveItemFromInventory(accessory))
		return
	if(!accessory.attach(src, user))
		return

	LAZYADD(attached_accessories, accessory)
	accessory.forceMove(src)
	// Allow for accessories to react to the acccessory list now
	accessory.successful_attach(src)

	if(user && attach_message)
		balloon_alert(user, "accessory attached")

	if(isnull(accessory_overlay))
		create_accessory_overlay()

	update_appearance()
	return TRUE

/// Removes (pops) the topmost accessory from the accessories list and puts it in the user's hands if supplied
/obj/item/clothing/under/proc/pop_accessory(mob/living/user, attach_message = TRUE)
	var/obj/item/clothing/accessory/popped_accessory = attached_accessories[1]
	remove_accessory(popped_accessory)

	if(!user)
		return

	user.put_in_hands(popped_accessory)
	if(attach_message)
		popped_accessory.balloon_alert(user, "accessory removed")

/// Removes the passed accesory from our accessories list
/obj/item/clothing/under/proc/remove_accessory(obj/item/clothing/accessory/removed)
	if(removed == attached_accessories[1])
		accessory_overlay = null

	// Remove it from the list before detaching
	LAZYREMOVE(attached_accessories, removed)
	removed.detach(src)

	if(isnull(accessory_overlay) && LAZYLEN(attached_accessories))
		create_accessory_overlay()

	update_appearance()

/// Handles creating the worn overlay mutable appearance
/// Only the first accessory attached is displayed (currently)
/obj/item/clothing/under/proc/create_accessory_overlay()
	var/obj/item/clothing/accessory/prime_accessory = attached_accessories[1]
	accessory_overlay = mutable_appearance(prime_accessory.worn_icon, prime_accessory.icon_state)
	accessory_overlay.alpha = prime_accessory.alpha
	accessory_overlay.color = prime_accessory.color

/// Updates the accessory's worn overlay mutable appearance
/obj/item/clothing/under/proc/update_accessory_overlay()
	if(isnull(accessory_overlay))
		return

	cut_overlay(accessory_overlay)
	create_accessory_overlay()
	update_appearance() // so we update the suit inventory overlay too

/obj/item/clothing/under/Exited(atom/movable/gone, direction)
	. = ..()
	// If one of our accessories was moved out, handle it
	if(gone in attached_accessories)
		remove_accessory(gone)

/// Helper to remove all attachments to the passed location
/obj/item/clothing/under/proc/dump_attachments(atom/drop_to = drop_location())
	for(var/obj/item/clothing/accessory/worn_accessory as anything in attached_accessories)
		remove_accessory(worn_accessory)
		worn_accessory.forceMove(drop_to)

/obj/item/clothing/under/atom_destruction(damage_flag)
	dump_attachments()
	return ..()

/obj/item/clothing/under/Destroy()
	QDEL_LAZYLIST(attached_accessories)
	return ..()

/obj/item/clothing/under/examine(mob/user)
	. = ..()
	if(can_adjust)
		. += "Alt-click on [src] to wear it [adjusted == ALT_STYLE ? "normally" : "casually"]."
	if(has_sensor == BROKEN_SENSORS)
		. += span_warning("The medical sensors appear to be shorted out. You could repair it with some cabling.")
	else if(has_sensor > NO_SENSORS)
		switch(sensor_mode)
			if(SENSOR_OFF)
				. += "Its sensors appear to be disabled."
			if(SENSOR_LIVING)
				. += "Its binary life sensors appear to be enabled."
			if(SENSOR_VITALS)
				. += "Its vital tracker appears to be enabled."
			if(SENSOR_COORDS)
				. += "Its vital tracker and tracking beacon appear to be enabled."
	if(LAZYLEN(attached_accessories))
		var/list/accessories = list_accessories_with_icon(user)
		. += "It has [english_list(accessories)] attached."
		. += "Alt-Right-Click to remove [attached_accessories[1]]."

/// Helper to list out all accessories with an icon besides it, for use in examine
/obj/item/clothing/under/proc/list_accessories_with_icon(mob/user)
	var/list/all_accessories = list()
	for(var/obj/item/clothing/accessory/attached as anything in attached_accessories)
		all_accessories += attached.examine_title(user)

	return all_accessories

/obj/item/clothing/under/verb/toggle()
	set name = "Adjust Suit Sensors"
	set category = "Object"
	set src in usr
	var/mob/user_mob = usr
	if(!can_toggle_sensors(user_mob))
		return

	var/list/modes = list("Off", "Binary vitals", "Exact vitals", "Tracking beacon")
	var/switchMode = tgui_input_list(user_mob, "Select a sensor mode", "Suit Sensors", modes, modes[sensor_mode + 1])
	if(isnull(switchMode))
		return
	if(!can_toggle_sensors(user_mob))
		return

	sensor_mode = modes.Find(switchMode) - 1
	if (loc == user_mob)
		switch(sensor_mode)
			if(SENSOR_OFF)
				to_chat(user_mob, span_notice("You disable your suit's remote sensing equipment."))
			if(SENSOR_LIVING)
				to_chat(user_mob, span_notice("Your suit will now only report whether you are alive or dead."))
			if(SENSOR_VITALS)
				to_chat(user_mob, span_notice("Your suit will now only report your exact vital lifesigns."))
			if(SENSOR_COORDS)
				to_chat(user_mob, span_notice("Your suit will now report your exact vital lifesigns as well as your coordinate position."))

	update_wearer_status()

/obj/item/clothing/under/item_ctrl_click(mob/user)
	if(!can_toggle_sensors(user))
		return CLICK_ACTION_BLOCKING

	sensor_mode = SENSOR_COORDS
	balloon_alert(user, "set to tracking")
	update_wearer_status()
	return CLICK_ACTION_SUCCESS

/// Checks if the toggler is allowed to toggle suit sensors currently
/obj/item/clothing/under/proc/can_toggle_sensors(mob/toggler)
	if(!can_use(toggler) || toggler.stat == DEAD) //make sure they didn't hold the window open.
		return FALSE
	if(get_dist(toggler, src) > 1)
		balloon_alert(toggler, "too far!")
		return FALSE

	switch(has_sensor)
		if(LOCKED_SENSORS)
			balloon_alert(toggler, "sensor controls locked!")
			return FALSE
		if(BROKEN_SENSORS)
			balloon_alert(toggler, "sensors shorted!")
			return FALSE
		if(NO_SENSORS)
			balloon_alert(toggler, "no sensors to ajdust!")
			return FALSE

	return TRUE

/obj/item/clothing/under/click_alt(mob/user)
	if(!can_adjust)
		balloon_alert(user, "can't be adjusted!")
		return CLICK_ACTION_BLOCKING
	if(!can_use(user))
		return NONE
	rolldown()
	return CLICK_ACTION_SUCCESS

/obj/item/clothing/under/click_alt_secondary(mob/user)
	if(!LAZYLEN(attached_accessories))
		balloon_alert(user, "no accessories to remove!")
		return
	pop_accessory(user)

/obj/item/clothing/under/verb/jumpsuit_adjust()
	set name = "Adjust Jumpsuit Style"
	set category = null
	set src in usr

	if(!can_adjust)
		balloon_alert(usr, "can't be adjusted!")
		return
	if(!can_use(usr))
		return
	rolldown()

/obj/item/clothing/under/proc/rolldown()
	if(toggle_jumpsuit_adjust())
		to_chat(usr, span_notice("You adjust the suit to wear it more casually."))
	else
		to_chat(usr, span_notice("You adjust the suit back to normal."))

	update_appearance()

/// Helper to toggle the jumpsuit style, if possible
/// Returns the new state
/obj/item/clothing/under/proc/toggle_jumpsuit_adjust()
	switch(adjusted)
		if(DIGITIGRADE_STYLE)
			return

		if(NORMAL_STYLE)
			adjust_to_alt()

		if(ALT_STYLE)
			adjust_to_normal()

	SEND_SIGNAL(src, COMSIG_CLOTHING_UNDER_ADJUSTED)
	return adjusted

/// Helper to reset to normal jumpsuit state
/obj/item/clothing/under/proc/adjust_to_normal()
	adjusted = NORMAL_STYLE
	female_sprite_flags = initial(female_sprite_flags)
	if(!alt_covers_chest)
		body_parts_covered |= CHEST
		body_parts_covered |= ARMS
	if(LAZYLEN(damage_by_parts))
		// ugly check to make sure we don't reenable protection on a disabled part
		for(var/zone in list(BODY_ZONE_CHEST, BODY_ZONE_L_ARM, BODY_ZONE_R_ARM))
			if(damage_by_parts[zone] > limb_integrity)
				body_parts_covered &= body_zone2cover_flags(zone)

/// Helper to adjust to alt jumpsuit state
/obj/item/clothing/under/proc/adjust_to_alt()
	adjusted = ALT_STYLE
	if(!(female_sprite_flags & FEMALE_UNIFORM_TOP_ONLY))
		female_sprite_flags = NO_FEMALE_UNIFORM
	if(!alt_covers_chest) // for the special snowflake suits that expose the chest when adjusted (and also the arms, realistically)
		body_parts_covered &= ~CHEST
		body_parts_covered &= ~ARMS

/obj/item/clothing/under/can_use(mob/user)
	if(ismob(user) && !user.can_perform_action(src, NEED_DEXTERITY|NEED_HANDS|ALLOW_RESTING))
		return FALSE
	return ..()

/obj/item/clothing/under/rank
	dying_key = DYE_REGISTRY_UNDER
