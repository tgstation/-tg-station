
/mob/living/proc/get_bodypart(zone)
	return

/mob/living/carbon/get_bodypart(zone)
	RETURN_TYPE(/obj/item/bodypart)

	if(!zone)
		zone = BODY_ZONE_CHEST
	for(var/obj/item/bodypart/bodypart as anything in bodyparts)
		if(bodypart.body_zone == zone)
			return bodypart

/// Replaces a single limb and deletes the old one if there was one
/mob/living/carbon/proc/del_and_replace_bodypart(obj/item/bodypart/new_limb, special)
	var/obj/item/bodypart/old_limb = get_bodypart(new_limb.body_zone)
	if(old_limb)
		old_limb.drop_limb(special = TRUE)
		qdel(old_limb)
	new_limb.try_attach_limb(src, special = special)

/// Replaces a single limb and returns the old one if there was one
/mob/living/carbon/proc/return_and_replace_bodypart(obj/item/bodypart/new_limb, special)
	var/obj/item/bodypart/old_limb = get_bodypart(new_limb.body_zone)
	if(!isnull(old_limb))
		old_limb.drop_limb(special = special)
		old_limb.moveToNullspace()

	new_limb.try_attach_limb(src, special = special)
	return old_limb // can be null

/mob/living/carbon/has_hand_for_held_index(i)
	if(!i)
		return FALSE
	var/obj/item/bodypart/hand_instance = hand_bodyparts[i]
	if(hand_instance && !hand_instance.bodypart_disabled)
		return hand_instance
	return FALSE


///Get the bodypart for whatever hand we have active, Only relevant for carbons
/mob/proc/get_active_hand()
	RETURN_TYPE(/obj/item/bodypart)
	return FALSE

/mob/living/carbon/get_active_hand()
	var/which_hand = BODY_ZONE_PRECISE_L_HAND
	if(IS_RIGHT_INDEX(active_hand_index))
		which_hand = BODY_ZONE_PRECISE_R_HAND
	return get_bodypart(check_zone(which_hand))

/// Gets the inactive hand of the mob. Returns FALSE on non-carbons, otherwise returns the /obj/item/bodypart.
/mob/proc/get_inactive_hand()
	return null

/mob/living/carbon/get_inactive_hand()
	var/which_hand = BODY_ZONE_PRECISE_R_HAND
	if(IS_RIGHT_INDEX(active_hand_index))
		which_hand = BODY_ZONE_PRECISE_L_HAND
	return get_bodypart(check_zone(which_hand))

/mob/proc/has_left_hand(check_disabled = TRUE)
	return TRUE


/mob/living/carbon/has_left_hand(check_disabled = TRUE)
	for(var/obj/item/bodypart/hand_instance in hand_bodyparts)
		if(IS_RIGHT_INDEX(hand_instance.held_index) || (check_disabled && hand_instance.bodypart_disabled))
			continue
		return TRUE
	return FALSE


/mob/living/carbon/alien/larva/has_left_hand(check_disabled = TRUE)
	return TRUE


/mob/proc/has_right_hand(check_disabled = TRUE)
	return TRUE


/mob/living/carbon/has_right_hand(check_disabled = TRUE)
	for(var/obj/item/bodypart/hand_instance in hand_bodyparts)
		if(IS_LEFT_INDEX(hand_instance.held_index) || (check_disabled && hand_instance.bodypart_disabled))
			continue
		return TRUE
	return FALSE


/mob/living/carbon/alien/larva/has_right_hand(check_disabled = TRUE)
	return TRUE


/mob/living/carbon/proc/get_missing_limbs()
	RETURN_TYPE(/list)
	var/list/full = GLOB.all_body_zones.Copy()
	for(var/zone in full)
		if(get_bodypart(zone))
			full -= zone
	return full

/mob/living/carbon/alien/larva/get_missing_limbs()
	var/list/full = list(BODY_ZONE_HEAD, BODY_ZONE_CHEST)
	for(var/zone in full)
		if(get_bodypart(zone))
			full -= zone
	return full

/mob/living/proc/get_disabled_limbs()
	return list()

/mob/living/carbon/get_disabled_limbs()
	var/list/full = GLOB.all_body_zones.Copy()
	var/list/disabled = list()
	for(var/zone in full)
		var/obj/item/bodypart/affecting = get_bodypart(zone)
		if(affecting?.bodypart_disabled)
			disabled += zone
	return disabled

/mob/living/carbon/alien/larva/get_disabled_limbs()
	var/list/full = list(BODY_ZONE_HEAD, BODY_ZONE_CHEST)
	var/list/disabled = list()
	for(var/zone in full)
		var/obj/item/bodypart/affecting = get_bodypart(zone)
		if(affecting?.bodypart_disabled)
			disabled += zone
	return disabled

///Remove a specific embedded item from the carbon mob
/mob/living/carbon/proc/remove_embedded_object(obj/item/embedded)
	if (embedded.get_embed()?.owner != src)
		return
	embedded.get_embed().remove_embedding()

///Remove all embedded objects from all limbs on the carbon mob
/mob/living/carbon/proc/remove_all_embedded_objects()
	for(var/obj/item/bodypart/bodypart as anything in bodyparts)
		for(var/obj/item/embedded as anything in bodypart.embedded_objects)
			remove_embedded_object(embedded)

/mob/living/carbon/proc/has_embedded_objects(include_harmless = FALSE)
	for(var/obj/item/bodypart/bodypart as anything in bodyparts)
		for(var/obj/item/embedded as anything in bodypart.embedded_objects)
			if(!include_harmless && embedded.get_embed().is_harmless(consider_stamina = TRUE))
				continue
			return TRUE

//Helper for quickly creating a new limb - used by augment code in species.dm spec_attacked_by
//
// FUCK YOU AUGMENT CODE - With love, Kapu
/mob/living/carbon/proc/newBodyPart(zone)
	var/path = dna.species.bodypart_overrides[zone]
	var/obj/item/bodypart/new_bodypart = new path()
	return new_bodypart

/mob/living/carbon/alien/larva/newBodyPart(zone)
	var/obj/item/bodypart/new_bodypart
	switch(zone)
		if(BODY_ZONE_HEAD)
			new_bodypart = new /obj/item/bodypart/head/larva()
		if(BODY_ZONE_CHEST)
			new_bodypart = new /obj/item/bodypart/chest/larva()
	. = new_bodypart

/mob/living/carbon/alien/adult/newBodyPart(zone)
	var/obj/item/bodypart/new_bodypart
	switch(zone)
		if(BODY_ZONE_L_ARM)
			new_bodypart = new /obj/item/bodypart/arm/left/alien()
		if(BODY_ZONE_R_ARM)
			new_bodypart = new /obj/item/bodypart/arm/right/alien()
		if(BODY_ZONE_HEAD)
			new_bodypart = new /obj/item/bodypart/head/alien()
		if(BODY_ZONE_L_LEG)
			new_bodypart = new /obj/item/bodypart/leg/left/alien()
		if(BODY_ZONE_R_LEG)
			new_bodypart = new /obj/item/bodypart/leg/right/alien()
		if(BODY_ZONE_CHEST)
			new_bodypart = new /obj/item/bodypart/chest/alien()
	if(new_bodypart)
		new_bodypart.update_limb(is_creating = TRUE)

/// Makes sure that the owner's bodytype flags match the flags of all of its parts and organs
/mob/living/carbon/proc/synchronize_bodytypes()
	var/all_limb_flags = NONE
	for(var/obj/item/bodypart/limb as anything in bodyparts)
		for(var/obj/item/organ/organ in limb)
			all_limb_flags |= organ.external_bodytypes
		all_limb_flags |= limb.bodytype

	bodytype = all_limb_flags

/// Makes sure that the owner's bodyshape flags match the flags of all of its parts and organs
/mob/living/carbon/proc/synchronize_bodyshapes()
	var/all_limb_flags = NONE
	for(var/obj/item/bodypart/limb as anything in bodyparts)
		for(var/obj/item/organ/organ in limb)
			all_limb_flags |= organ.external_bodyshapes
		all_limb_flags |= limb.bodyshape

	bodyshape = all_limb_flags

/proc/skintone2hex(skin_tone)
	. = 0
	switch(skin_tone)
		if("caucasian1")
			. = "#ffe0d1"
		if("caucasian2")
			. = "#fcccb3"
		if("caucasian3")
			. = "#e8b59b"
		if("latino")
			. = "#d9ae96"
		if("mediterranean")
			. = "#c79b8b"
		if("asian1")
			. = "#ffdeb3"
		if("asian2")
			. = "#e3ba84"
		if("arab")
			. = "#c4915e"
		if("indian")
			. = "#b87840"
		if("mixed1")
			. = "#a57a66"
		if("mixed2")
			. = "#87563d"
		if("mixed3")
			. = "#725547"
		if("mixed4")
			. = "#866e63"
		if("african1")
			. = "#754523"
		if("african2")
			. = "#471c18"
		if("albino")
			. = "#fff4e6"
		if("orange")
			. = "#ffc905"
		if("green")
			. = "#a8e61d"
