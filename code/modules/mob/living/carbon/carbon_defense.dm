#define SHAKE_ANIMATION_OFFSET 4

/mob/living/carbon/get_eye_protection()
	. = ..()
	if(is_blind() && !is_blind_from(list(UNCONSCIOUS_TRAIT, HYPNOCHAIR_TRAIT)))
		return INFINITY //For all my homies that can not see in the world
	var/obj/item/organ/eyes/eyes = get_organ_slot(ORGAN_SLOT_EYES)
	if(eyes)
		. += eyes.flash_protect
	else
		return INFINITY //Can't get flashed without eyes
	if(isclothing(head)) //Adds head protection
		. += head.flash_protect
	if(isclothing(glasses)) //Glasses
		. += glasses.flash_protect
	if(isclothing(wear_mask)) //Mask
		. += wear_mask.flash_protect

/mob/living/carbon/get_ear_protection()
	. = ..()
	if(HAS_TRAIT(src, TRAIT_DEAF))
		return INFINITY //For all my homies that can not hear in the world
	var/obj/item/organ/ears/E = get_organ_slot(ORGAN_SLOT_EARS)
	if(!E)
		return INFINITY
	else
		. += E.bang_protect

/mob/living/carbon/is_mouth_covered(check_flags = ALL)
	if((check_flags & ITEM_SLOT_HEAD) && head && (head.flags_cover & HEADCOVERSMOUTH))
		return head
	if((check_flags & ITEM_SLOT_MASK) && wear_mask && (wear_mask.flags_cover & MASKCOVERSMOUTH))
		return wear_mask

	return null

/mob/living/carbon/is_eyes_covered(check_flags = ALL)
	if((check_flags & ITEM_SLOT_HEAD) && head && (head.flags_cover & HEADCOVERSEYES))
		return head
	if((check_flags & ITEM_SLOT_MASK) && wear_mask && (wear_mask.flags_cover & MASKCOVERSEYES))
		return wear_mask
	if((check_flags & ITEM_SLOT_EYES) && glasses && (glasses.flags_cover & GLASSESCOVERSEYES))
		return glasses

	return null

/mob/living/carbon/is_pepper_proof(check_flags = ALL)
	var/obj/item/organ/eyes/eyes = get_organ_by_type(/obj/item/organ/eyes)
	if(eyes && eyes.pepperspray_protect)
		return eyes
	if((check_flags & ITEM_SLOT_HEAD) && head && (head.flags_cover & PEPPERPROOF))
		return head
	if((check_flags & ITEM_SLOT_MASK) && wear_mask && (wear_mask.flags_cover & PEPPERPROOF))
		return wear_mask

	return null

/mob/living/carbon/is_ears_covered()
	for(var/obj/item/worn_thing as anything in get_equipped_items())
		if(worn_thing.flags_cover & EARS_COVERED)
			return worn_thing

	return null

/mob/living/carbon/check_projectile_dismemberment(obj/projectile/proj, def_zone)
	var/obj/item/bodypart/affecting = get_bodypart(def_zone)
	if(affecting && affecting.can_dismember() && !(affecting.bodypart_flags & BODYPART_UNREMOVABLE) && affecting.get_damage() >= (affecting.max_damage - proj.dismemberment))
		affecting.dismember(proj.damtype)
		if(proj.catastropic_dismemberment)
			apply_damage(proj.damage, proj.damtype, BODY_ZONE_CHEST, wound_bonus = proj.wound_bonus) //stops a projectile blowing off a limb effectively doing no damage. Mostly relevant for sniper rifles.

/mob/living/carbon/try_catch_item(obj/item/item, skip_throw_mode_check = FALSE, try_offhand = FALSE)
	. = ..()
	if(.)
		throw_mode_off(THROW_MODE_TOGGLE)

/mob/living/carbon/can_catch_item(skip_throw_mode_check = FALSE, try_offhand = FALSE)
	if(!skip_throw_mode_check && !throw_mode)
		return FALSE
	return ..()

/mob/living/carbon/hitby(atom/movable/movable, skipcatch, hitpush = TRUE, blocked = FALSE, datum/thrownthing/throwingdatum)
	if(!skipcatch && try_catch_item(movable))
		return TRUE
	return ..()

/mob/living/carbon/send_item_attack_message(obj/item/weapon, mob/living/user, hit_area, def_zone)
	if(!weapon.force && !length(weapon.attack_verb_simple) && !length(weapon.attack_verb_continuous))
		return
	var/obj/item/bodypart/hit_bodypart = get_bodypart(def_zone)
	if(isnull(hit_bodypart)) // ??
		return ..()

	// Sanity in case one is null for some reason
	var/picked_index = rand(max(length(weapon.attack_verb_simple), length(weapon.attack_verb_continuous)))

	var/message_verb_continuous = "attacks"
	var/message_verb_simple = "attack"
	var/message_hit_area = get_hit_area_message(hit_area)
	// Sanity in case one is... longer than the other?
	if (picked_index && length(weapon.attack_verb_continuous) >= picked_index)
		message_verb_continuous = weapon.attack_verb_continuous[picked_index]
	if (picked_index && length(weapon.attack_verb_simple) >= picked_index)
		message_verb_simple = weapon.attack_verb_simple[picked_index]

	var/extra_wound_details = ""

	if(weapon.damtype == BRUTE && hit_bodypart.can_dismember())

		var/mangled_state = hit_bodypart.get_mangled_state()

		var/bio_status = hit_bodypart.get_bio_state_status()

		var/has_exterior = ((bio_status & ANATOMY_EXTERIOR))
		var/has_interior = ((bio_status & ANATOMY_INTERIOR))

		var/exterior_ready_to_dismember = (!has_exterior || ((mangled_state & BODYPART_MANGLED_EXTERIOR)))
		var/interior_ready_to_dismember = (!has_interior || ((mangled_state & BODYPART_MANGLED_INTERIOR)))

		var/dismemberable = ((hit_bodypart.dismemberable_by_wound()) || hit_bodypart.dismemberable_by_total_damage())
		if (dismemberable)
			extra_wound_details = ", threatening to sever it entirely"
		else if((has_interior && (has_exterior && exterior_ready_to_dismember) && weapon.get_sharpness()))
			var/bone_text = hit_bodypart.get_internal_description()
			extra_wound_details = ", [weapon.get_sharpness() == SHARP_EDGED ? "slicing" : "piercing"] through to the [bone_text]"
		else if(has_exterior && ((has_interior && interior_ready_to_dismember) && weapon.get_sharpness()))
			var/tissue_text = hit_bodypart.get_external_description()
			extra_wound_details = ", [weapon.get_sharpness() == SHARP_EDGED ? "slicing" : "piercing"] at the remaining [tissue_text]"

	var/attack_message_spectator = "[src] [message_verb_continuous][message_hit_area] with [weapon][extra_wound_details]!"
	var/attack_message_victim = "You're [message_verb_continuous][message_hit_area] with [weapon][extra_wound_details]!"
	var/attack_message_attacker = "You [message_verb_simple] [src][message_hit_area] with [weapon][extra_wound_details]!"
	if(user in viewers(src, null))
		attack_message_spectator = "[user] [message_verb_continuous] [src][message_hit_area] with [weapon][extra_wound_details]!"
		attack_message_victim = "[user] [message_verb_continuous] you[message_hit_area] with [weapon][extra_wound_details]!"
	if(user == src)
		attack_message_victim = "You [message_verb_simple] yourself[message_hit_area] with [weapon][extra_wound_details]!"
	visible_message(span_danger("[attack_message_spectator]"),\
		span_userdanger("[attack_message_victim]"), null, COMBAT_MESSAGE_RANGE, user)
	if(user != src)
		to_chat(user, span_danger("[attack_message_attacker]"))
	return TRUE


/mob/living/carbon/attack_drone(mob/living/basic/drone/user)
	return //so we don't call the carbon's attack_hand().

/mob/living/carbon/attack_drone_secondary(mob/living/basic/drone/user)
	return SECONDARY_ATTACK_CANCEL_ATTACK_CHAIN

/mob/living/carbon/attack_hand(mob/living/carbon/human/user, list/modifiers)
	. = ..()

	for(var/thing in diseases)
		var/datum/disease/D = thing
		if(D.spread_flags & DISEASE_SPREAD_CONTACT_SKIN)
			user.ContactContractDisease(D)

	for(var/thing in user.diseases)
		var/datum/disease/D = thing
		if(D.spread_flags & DISEASE_SPREAD_CONTACT_SKIN)
			ContactContractDisease(D)

	if(.)
		return TRUE

	for(var/datum/wound/wounds as anything in all_wounds)
		if(wounds.try_handling(user))
			return TRUE

	return FALSE

/mob/living/carbon/attack_animal(mob/living/simple_animal/user, list/modifiers)
	if (!user.combat_mode)
		for (var/datum/wound/wounds as anything in all_wounds)
			if (wounds.try_handling(user))
				return TRUE

	return ..()

/mob/living/carbon/attack_paw(mob/living/carbon/human/user, list/modifiers)

	if(try_inject(user, injection_flags = INJECT_TRY_SHOW_ERROR_MESSAGE))
		for(var/thing in diseases)
			var/datum/disease/D = thing
			if((D.spread_flags & DISEASE_SPREAD_CONTACT_SKIN) && prob(85))
				user.ContactContractDisease(D)

	for(var/thing in user.diseases)
		var/datum/disease/D = thing
		if(D.spread_flags & DISEASE_SPREAD_CONTACT_SKIN)
			ContactContractDisease(D)

	if(!user.combat_mode)
		help_shake_act(user)
		return FALSE

	if(..()) //successful monkey bite.
		for(var/thing in user.diseases)
			var/datum/disease/D = thing
			if(D.spread_flags & (DISEASE_SPREAD_SPECIAL | DISEASE_SPREAD_NON_CONTAGIOUS))
				continue
			ForceContractDisease(D)
		return TRUE

/**
 * Really weird proc that attempts to dismebmer the passed zone if it is at max damage
 * Unless the attacker is an NPC, in which case it disregards the zone and picks a random one
 *
 * Cannot dismember heads
 *
 * Returns a falsy value (null) on success, and a truthy value (the hit zone) on failure
 */
/mob/living/proc/dismembering_strike(mob/living/attacker, dam_zone)
	return dam_zone

/mob/living/carbon/dismembering_strike(mob/living/attacker, dam_zone)
	if(!attacker.limb_destroyer)
		return dam_zone
	var/obj/item/bodypart/affecting
	if(dam_zone && attacker.client)
		affecting = get_bodypart(get_random_valid_zone(dam_zone))
	else
		var/list/things_to_ruin = shuffle(bodyparts.Copy())
		for(var/obj/item/bodypart/bodypart as anything in things_to_ruin)
			if(bodypart.body_zone == BODY_ZONE_HEAD || bodypart.body_zone == BODY_ZONE_CHEST)
				continue
			if(!affecting || ((affecting.get_damage() / affecting.max_damage) < (bodypart.get_damage() / bodypart.max_damage)))
				affecting = bodypart

	if(affecting)
		dam_zone = affecting.body_zone
		if(affecting.get_damage() >= affecting.max_damage && affecting.dismember())
			return null

	return dam_zone

/mob/living/carbon/blob_act(obj/structure/blob/B)
	if (stat == DEAD)
		return
	else
		show_message(span_userdanger("The blob attacks!"))
		adjustBruteLoss(10)

///Adds to the parent by also adding functionality to propagate shocks through pulling and doing some fluff effects.
/mob/living/carbon/electrocute_act(shock_damage, source, siemens_coeff = 1, flags = NONE, jitter_time = 20 SECONDS, stutter_time = 4 SECONDS, stun_duration = 4 SECONDS)
	. = ..()
	if(!.)
		return
	//Propagation through pulling, fireman carry
	if(!(flags & SHOCK_ILLUSION))
		if(undergoing_cardiac_arrest())
			set_heartattack(FALSE)
		var/list/shocking_queue = list()
		if(iscarbon(pulling) && source != pulling)
			shocking_queue += pulling
		if(iscarbon(pulledby) && source != pulledby)
			shocking_queue += pulledby
		if(iscarbon(buckled) && source != buckled)
			shocking_queue += buckled
		for(var/mob/living/carbon/carried in buckled_mobs)
			if(source != carried)
				shocking_queue += carried
		//Found our victims, now lets shock them all
		for(var/victim in shocking_queue)
			var/mob/living/carbon/C = victim
			C.electrocute_act(shock_damage*0.75, src, 1, flags, jitter_time, stutter_time, stun_duration)
	//Stun
	var/should_stun = (!(flags & SHOCK_TESLA) || siemens_coeff > 0.5) && !(flags & SHOCK_NOSTUN)
	var/paralyze = !(flags & SHOCK_KNOCKDOWN)
	var/immediately_stun = should_stun && !(flags & SHOCK_DELAY_STUN)
	if (immediately_stun)
		if (paralyze)
			Paralyze(stun_duration)
		else
			Knockdown(stun_duration)
	//Jitter and other fluff.
	do_jitter_animation(300)
	adjust_jitter(jitter_time)
	adjust_stutter(stutter_time)
	if (should_stun)
		addtimer(CALLBACK(src, PROC_REF(secondary_shock), paralyze, stun_duration * 1.5), 2 SECONDS)
	return shock_damage

///Called slightly after electrocute act to apply a secondary stun.
/mob/living/carbon/proc/secondary_shock(paralyze, stun_duration)
	if (paralyze)
		Paralyze(stun_duration)
	else
		Knockdown(stun_duration)

/mob/living/carbon/proc/help_shake_act(mob/living/carbon/helper, force_friendly)
	if(on_fire)
		to_chat(helper, span_warning("You can't put [p_them()] out with just your bare hands!"))
		return

	if(SEND_SIGNAL(src, COMSIG_CARBON_PRE_MISC_HELP, helper) & COMPONENT_BLOCK_MISC_HELP)
		return

	if(helper == src)
		check_self_for_injuries()
		return

	if(body_position == LYING_DOWN)
		if(buckled)
			to_chat(helper, span_warning("You need to unbuckle [src] first to do that!"))
			return
		helper.visible_message(span_notice("[helper] shakes [src] trying to get [p_them()] up!"), \
						null, span_hear("You hear the rustling of clothes."), DEFAULT_MESSAGE_RANGE, list(helper, src))
		to_chat(helper, span_notice("You shake [src] trying to pick [p_them()] up!"))
		to_chat(src, span_notice("[helper] shakes you to get you up!"))
	else if(check_zone(helper.zone_selected) == BODY_ZONE_HEAD && get_bodypart(BODY_ZONE_HEAD)) //Headpats!
		helper.visible_message(span_notice("[helper] gives [src] a pat on the head to make [p_them()] feel better!"), \
					null, span_hear("You hear a soft patter."), DEFAULT_MESSAGE_RANGE, list(helper, src))
		to_chat(helper, span_notice("You give [src] a pat on the head to make [p_them()] feel better!"))
		to_chat(src, span_notice("[helper] gives you a pat on the head to make you feel better! "))

		if(HAS_TRAIT(src, TRAIT_BADTOUCH))
			to_chat(helper, span_warning("[src] looks visibly upset as you pat [p_them()] on the head."))

	else if ((helper.zone_selected == BODY_ZONE_PRECISE_GROIN) && !isnull(src.get_organ_by_type(/obj/item/organ/tail)))
		helper.visible_message(span_notice("[helper] pulls on [src]'s tail!"), \
					null, span_hear("You hear a soft patter."), DEFAULT_MESSAGE_RANGE, list(helper, src))
		to_chat(helper, span_notice("You pull on [src]'s tail!"))
		to_chat(src, span_notice("[helper] pulls on your tail!"))
		if(HAS_TRAIT(src, TRAIT_BADTOUCH)) //How dare they!
			to_chat(helper, span_warning("[src] makes a grumbling noise as you pull on [p_their()] tail."))
		else
			add_mood_event("tailpulled", /datum/mood_event/tailpulled)

	else if ((helper.zone_selected == BODY_ZONE_PRECISE_GROIN) && (istype(head, /obj/item/clothing/head/costume/kitty) || istype(head, /obj/item/clothing/head/collectable/kitty)))
		var/obj/item/clothing/head/faketail = head
		helper.visible_message(span_danger("[helper] pulls on [src]'s tail... and it rips off!"), \
					null, span_hear("You hear a ripping sound."), DEFAULT_MESSAGE_RANGE, list(helper, src))
		to_chat(helper, span_danger("You pull on [src]'s tail... and it rips off!"))
		to_chat(src, span_userdanger("[helper] pulls on your tail... and it rips off!"))
		playsound(loc, 'sound/effects/cloth_rip.ogg', 75, TRUE)
		dropItemToGround(faketail)
		helper.put_in_hands(faketail)
		helper.add_mood_event("rippedtail", /datum/mood_event/rippedtail)

	else
		if (helper.grab_state >= GRAB_AGGRESSIVE)
			helper.visible_message(span_notice("[helper] embraces [src] in a tight bear hug!"), \
						null, span_hear("You hear the rustling of clothes."), DEFAULT_MESSAGE_RANGE, list(helper, src))
			to_chat(helper, span_notice("You wrap [src] into a tight bear hug!"))
			to_chat(src, span_notice("[helper] squeezes you super tightly in a firm bear hug!"))
		else
			helper.visible_message(span_notice("[helper] hugs [src] to make [p_them()] feel better!"), \
						null, span_hear("You hear the rustling of clothes."), DEFAULT_MESSAGE_RANGE, list(helper, src))
			to_chat(helper, span_notice("You hug [src] to make [p_them()] feel better!"))
			to_chat(src, span_notice("[helper] hugs you to make you feel better!"))

		// Warm them up with hugs
		share_bodytemperature(helper)

		// No moodlets for people who hate touches
		if(!HAS_TRAIT(src, TRAIT_BADTOUCH))
			if (helper.grab_state >= GRAB_AGGRESSIVE)
				add_mood_event("hug", /datum/mood_event/bear_hug)
			else
				if(bodytemperature > helper.bodytemperature)
					if(!HAS_TRAIT(helper, TRAIT_BADTOUCH))
						helper.add_mood_event("hug", /datum/mood_event/warmhug, src) // Hugger got a warm hug (Unless they hate hugs)
					add_mood_event("hug", /datum/mood_event/hug) // Receiver always gets a mood for being hugged
				else
					add_mood_event("hug", /datum/mood_event/warmhug, helper) // You got a warm hug
		else
			if (helper.grab_state >= GRAB_AGGRESSIVE)
				add_mood_event("hug", /datum/mood_event/bad_touch_bear_hug)

		// Let people know if they hugged someone really warm or really cold
		if(helper.bodytemperature > BODYTEMP_HEAT_DAMAGE_LIMIT)
			to_chat(src, span_warning("It feels like [helper] is over heating as [helper.p_they()] hug[helper.p_s()] you."))
		else if(helper.bodytemperature < BODYTEMP_COLD_DAMAGE_LIMIT)
			to_chat(src, span_warning("It feels like [helper] is freezing as [helper.p_they()] hug[helper.p_s()] you."))

		if(bodytemperature > BODYTEMP_HEAT_DAMAGE_LIMIT)
			to_chat(helper, span_warning("It feels like [src] is over heating as you hug [p_them()]."))
		else if(bodytemperature < BODYTEMP_COLD_DAMAGE_LIMIT)
			to_chat(helper, span_warning("It feels like [src] is freezing as you hug [p_them()]."))

		if(HAS_TRAIT(helper, TRAIT_FRIENDLY) || force_friendly)
			if (helper.mob_mood.sanity >= SANITY_GREAT)
				new /obj/effect/temp_visual/heart(loc)
				add_mood_event("friendly_hug", /datum/mood_event/besthug, helper)
			else if (helper.mob_mood.sanity >= SANITY_DISTURBED)
				add_mood_event("friendly_hug", /datum/mood_event/betterhug, helper)

		if(HAS_TRAIT(src, TRAIT_BADTOUCH))
			to_chat(helper, span_warning("[src] looks visibly upset as you hug [p_them()]."))

	SEND_SIGNAL(src, COMSIG_CARBON_HELP_ACT, helper)
	SEND_SIGNAL(helper, COMSIG_CARBON_HELPED, src)

	adjust_status_effects_on_shake_up()
	set_resting(FALSE)
	if(body_position != STANDING_UP && !resting && !buckled && !HAS_TRAIT(src, TRAIT_FLOORED))
		get_up(TRUE)

	playsound(loc, 'sound/items/weapons/thudswoosh.ogg', 50, TRUE, -1)

	// Shake animation
	if (incapacitated)
		shake_up_animation()

/mob/proc/shake_up_animation()
		var/direction = prob(50) ? -1 : 1
		animate(src, pixel_w = SHAKE_ANIMATION_OFFSET * direction, time = 0.1 SECONDS, easing = QUAD_EASING | EASE_OUT, flags = ANIMATION_PARALLEL|ANIMATION_RELATIVE)
		animate(pixel_w = SHAKE_ANIMATION_OFFSET * -2 * direction, time = 0.1 SECONDS, flags = ANIMATION_RELATIVE)
		animate(pixel_w = SHAKE_ANIMATION_OFFSET * direction, time = 0.1 SECONDS, easing = QUAD_EASING | EASE_IN, flags = ANIMATION_RELATIVE)

/// Check ourselves to see if we've got any shrapnel, return true if we do. This is a much simpler version of what humans do, we only indicate we're checking ourselves if there's actually shrapnel
/mob/living/carbon/proc/check_self_for_injuries()
	if(stat >= UNCONSCIOUS)
		return

	var/embeds = FALSE
	for(var/obj/item/bodypart/limb as anything in bodyparts)
		for(var/obj/item/weapon as anything in limb.embedded_objects)
			if(!embeds)
				embeds = TRUE
				// this way, we only visibly try to examine ourselves if we have something embedded, otherwise we'll still hug ourselves :)
				visible_message(span_notice("[src] examines [p_them()]self."), \
					span_notice("You check yourself for shrapnel."), visible_message_flags = ALWAYS_SHOW_SELF_MESSAGE)
			var/harmless = weapon.get_embed().is_harmless()
			var/stuck_wordage = harmless ? "stuck to" : "embedded in"
			var/embed_text = "\t <a href='byond://?src=[REF(src)];embedded_object=[REF(weapon)];embedded_limb=[REF(limb)]'> There is [icon2html(weapon, src)] \a [weapon] [stuck_wordage] your [limb.plaintext_zone]!</a>"
			if (harmless)
				to_chat(src, span_italics(span_notice(embed_text)))
			else
				to_chat(src, span_boldwarning(embed_text))
	return embeds

/mob/living/carbon/flash_act(intensity = 1, override_blindness_check = 0, affect_silicon = 0, visual = 0, type = /atom/movable/screen/fullscreen/flash, length = 25)
	var/obj/item/organ/eyes/eyes = get_organ_slot(ORGAN_SLOT_EYES)
	if(!eyes) //can't flash what can't see!
		return

	. = ..()

	var/damage = intensity - get_eye_protection()
	if(.) // we've been flashed
		if(visual)
			return

		switch(damage)
			if(1)
				to_chat(src, span_warning("Your eyes sting a little."))
				if(prob(40))
					eyes.apply_organ_damage(1)

			if(2)
				to_chat(src, span_warning("Your eyes burn."))
				eyes.apply_organ_damage(rand(2, 4))

			if(3 to INFINITY)
				to_chat(src, span_warning("Your eyes itch and burn severely!"))
				eyes.apply_organ_damage(rand(12, 16))

		if(eyes.damage > 10)
			adjust_temp_blindness(damage * 2 SECONDS)
			set_eye_blur_if_lower(damage * rand(6 SECONDS, 12 SECONDS))

			if(eyes.damage > eyes.low_threshold)
				if(!is_nearsighted_from(EYE_DAMAGE) && prob(eyes.damage - eyes.low_threshold))
					to_chat(src, span_warning("Your eyes start to burn badly!"))
					eyes.apply_organ_damage(eyes.low_threshold)

				else if(!is_blind() && prob(eyes.damage - eyes.high_threshold))
					to_chat(src, span_warning("You can't see anything!"))
					eyes.apply_organ_damage(eyes.maxHealth)

			else
				to_chat(src, span_warning("Your eyes are really starting to hurt. This can't be good for you!"))
		return TRUE

	else if(damage == 0 && prob(20)) // just enough protection
		to_chat(src, span_notice("Something bright flashes in the corner of your vision!"))


/mob/living/carbon/soundbang_act(intensity = 1, stun_pwr = 20, damage_pwr = 5, deafen_pwr = 15)
	var/list/reflist = list(intensity) // Need to wrap this in a list so we can pass a reference
	SEND_SIGNAL(src, COMSIG_CARBON_SOUNDBANG, reflist)
	intensity = reflist[1]
	var/ear_safety = get_ear_protection()
	var/obj/item/organ/ears/ears = get_organ_slot(ORGAN_SLOT_EARS)
	var/effect_amount = intensity - ear_safety
	if(effect_amount > 0)
		if(stun_pwr)
			Paralyze((stun_pwr*effect_amount)*0.1)
			Knockdown(stun_pwr*effect_amount)

		if(ears && (deafen_pwr || damage_pwr))
			var/ear_damage = damage_pwr * effect_amount
			var/deaf = deafen_pwr * effect_amount
			ears.adjustEarDamage(ear_damage,deaf)

			if(ears.damage >= 15)
				to_chat(src, span_warning("Your ears start to ring badly!"))
				if(prob(ears.damage - 5))
					to_chat(src, span_userdanger("You can't hear anything!"))
					// Makes you deaf, enough that you need a proper source of healing, it won't self heal
					// you need earmuffs, inacusiate, or replacement
					ears.set_organ_damage(ears.maxHealth)
			else if(ears.damage >= 5)
				to_chat(src, span_warning("Your ears start to ring!"))
			SEND_SOUND(src, sound('sound/items/weapons/flash_ring.ogg',0,1,0,250))
		return effect_amount //how soundbanged we are


/mob/living/carbon/damage_clothes(damage_amount, damage_type = BRUTE, damage_flag = 0, def_zone)
	if(damage_type != BRUTE && damage_type != BURN)
		return
	damage_amount *= 0.5 //0.5 multiplier for balance reason, we don't want clothes to be too easily destroyed
	if(!def_zone || def_zone == BODY_ZONE_HEAD)
		var/obj/item/clothing/hit_clothes
		if(wear_mask)
			hit_clothes = wear_mask
		if(wear_neck)
			hit_clothes = wear_neck
		if(head)
			hit_clothes = head
		if(hit_clothes)
			hit_clothes.take_damage(damage_amount, damage_type, damage_flag, 0)

/mob/living/carbon/can_hear()
	. = FALSE
	var/obj/item/organ/ears/ears = get_organ_slot(ORGAN_SLOT_EARS)
	if(ears && !HAS_TRAIT(src, TRAIT_DEAF))
		. = TRUE
	if(health <= hardcrit_threshold && !HAS_TRAIT(src, TRAIT_NOHARDCRIT))
		. = FALSE


/mob/living/carbon/adjustOxyLoss(amount, updating_health = TRUE, forced, required_biotype, required_respiration_type)
	if(!forced && HAS_TRAIT(src, TRAIT_NOBREATH))
		amount = min(amount, 0) //Prevents oxy damage but not healing

	. = ..()
	check_passout()

/mob/living/carbon/proc/get_interaction_efficiency(zone)
	var/obj/item/bodypart/limb = get_bodypart(zone)
	if(!limb)
		return

/mob/living/carbon/setOxyLoss(amount, updating_health = TRUE, forced, required_biotype, required_respiration_type)
	. = ..()
	check_passout()

/**
* Check to see if we should be passed out from oxyloss
*/
/mob/living/carbon/proc/check_passout()
	var/mob_oxyloss = getOxyLoss()
	if(mob_oxyloss >= OXYLOSS_PASSOUT_THRESHOLD)
		if(!HAS_TRAIT_FROM(src, TRAIT_KNOCKEDOUT, OXYLOSS_TRAIT))
			ADD_TRAIT(src, TRAIT_KNOCKEDOUT, OXYLOSS_TRAIT)
	else if(mob_oxyloss < OXYLOSS_PASSOUT_THRESHOLD)
		REMOVE_TRAIT(src, TRAIT_KNOCKEDOUT, OXYLOSS_TRAIT)

/mob/living/carbon/get_organic_health()
	. = health
	for (var/_limb in bodyparts)
		var/obj/item/bodypart/limb = _limb
		if (!IS_ORGANIC_LIMB(limb))
			. += (limb.brute_dam * limb.body_damage_coeff) + (limb.burn_dam * limb.body_damage_coeff)

/mob/living/carbon/grabbedby(mob/living/user, supress_message = FALSE)
	if(user != src)
		return ..()

	var/obj/item/bodypart/grasped_part = get_bodypart(zone_selected)
	if(!grasped_part?.can_be_grasped())
		return
	var/starting_hand_index = active_hand_index
	if(starting_hand_index == grasped_part.held_index)
		to_chat(src, span_danger("You can't grasp your [grasped_part.name] with itself!"))
		return

	var/bleed_rate = grasped_part.get_modified_bleed_rate()
	var/bleeding_text = (bleed_rate ? ", trying to stop the bleeding" : "")
	to_chat(src, span_warning("You try grasping at your [grasped_part.name][bleeding_text]..."))
	if(!do_after(src, 0.75 SECONDS))
		to_chat(src, span_danger("You fail to grasp your [grasped_part.name]."))
		return

	var/obj/item/hand_item/self_grasp/grasp = new
	if(starting_hand_index != active_hand_index || !put_in_active_hand(grasp))
		to_chat(src, span_danger("You fail to grasp your [grasped_part.name]."))
		QDEL_NULL(grasp)
		return
	grasp.grasp_limb(grasped_part)

/// If TRUE, the owner of this bodypart can try grabbing it to slow bleeding, as well as various other effects.
/obj/item/bodypart/proc/can_be_grasped()
	if (get_modified_bleed_rate())
		return TRUE

	for (var/datum/wound/iterated_wound as anything in wounds)
		if (iterated_wound.wound_flags & CAN_BE_GRASPED)
			return TRUE

	return FALSE

/// an abstract item representing you holding your own limb to staunch the bleeding, see [/mob/living/carbon/proc/grabbedby] will probably need to find somewhere else to put this.
/obj/item/hand_item/self_grasp
	name = "self-grasp"
	desc = "Sometimes all you can do is slow the bleeding."
	icon_state = "latexballoon"
	inhand_icon_state = "nothing"
	slowdown = 0.5
	item_flags = DROPDEL | ABSTRACT | NOBLUDGEON | SLOWS_WHILE_IN_HAND | HAND_ITEM
	/// The bodypart we're staunching bleeding on, which also has a reference to us in [/obj/item/bodypart/var/grasped_by]
	var/obj/item/bodypart/grasped_part
	/// The carbon who owns all of this mess
	var/mob/living/carbon/user

/obj/item/hand_item/self_grasp/Destroy()
	if(user)
		to_chat(user, span_warning("You stop holding onto your[grasped_part ? " [grasped_part.name]" : "self"]."))
		UnregisterSignal(user, COMSIG_QDELETING)
	if(grasped_part)
		UnregisterSignal(grasped_part, list(COMSIG_CARBON_REMOVE_LIMB, COMSIG_QDELETING))
		grasped_part.grasped_by = null
		grasped_part.refresh_bleed_rate()
	grasped_part = null
	user = null
	return ..()

/// The limb or the whole damn person we were grasping got deleted or dismembered, so we don't care anymore
/obj/item/hand_item/self_grasp/proc/qdel_void()
	SIGNAL_HANDLER
	qdel(src)

/// We've already cleared that the bodypart in question is bleeding in [the place we create this][/mob/living/carbon/proc/grabbedby], so set up the connections
/obj/item/hand_item/self_grasp/proc/grasp_limb(obj/item/bodypart/grasping_part)
	user = grasping_part.owner
	if(!istype(user))
		stack_trace("[src] attempted to try_grasp() with [isdatum(user) ? user.type : isnull(user) ? "null" : user] user")
		qdel(src)
		return

	grasped_part = grasping_part
	grasped_part.grasped_by = src
	grasped_part.refresh_bleed_rate()
	RegisterSignal(user, COMSIG_QDELETING, PROC_REF(qdel_void))
	RegisterSignals(grasped_part, list(COMSIG_CARBON_REMOVE_LIMB, COMSIG_QDELETING), PROC_REF(qdel_void))

	var/bleed_rate = grasped_part.get_modified_bleed_rate()
	var/bleeding_text = (bleed_rate ? ", trying to stop the bleeding" : "")
	user.visible_message(span_danger("[user] grasps at [user.p_their()] [grasped_part.name][bleeding_text]."), span_notice("You grab hold of your [grasped_part.name] tightly."), vision_distance=COMBAT_MESSAGE_RANGE)
	playsound(get_turf(src), 'sound/items/weapons/thudswoosh.ogg', 50, TRUE, -1)
	return TRUE

/// Randomise a body part and organ of this mob
/mob/living/carbon/proc/bioscramble(scramble_source)
	if(!(mob_biotypes & MOB_ORGANIC))
		return FALSE

	if (HAS_TRAIT(src, TRAIT_GENELESS))
		return FALSE

	if (run_armor_check(attack_flag = BIO, silent = TRUE) >= 100)
		to_chat(src, span_warning("Your armor shields you from [scramble_source]!"))
		return FALSE

	if (!length(GLOB.bioscrambler_valid_organs) || !length(GLOB.bioscrambler_valid_parts))
		init_bioscrambler_lists()

	var/changed_something = FALSE
	var/obj/item/organ/new_organ = pick(GLOB.bioscrambler_valid_organs)
	var/obj/item/organ/replaced = get_organ_slot(initial(new_organ.slot))
	if (!replaced || !IS_ROBOTIC_ORGAN(replaced))
		changed_something = TRUE
		new_organ = new new_organ()
		new_organ.replace_into(src)

	var/obj/item/bodypart/new_part = pick(GLOB.bioscrambler_valid_parts)
	var/obj/item/bodypart/picked_user_part = get_bodypart(initial(new_part.body_zone))
	if (picked_user_part && BODYTYPE_CAN_BE_BIOSCRAMBLED(picked_user_part.bodytype))
		changed_something = TRUE
		new_part = new new_part()
		new_part.replace_limb(src, special = TRUE)
		if (picked_user_part)
			qdel(picked_user_part)

	if (!changed_something)
		to_chat(src, span_notice("Your augmented body protects you from [scramble_source]!"))
		return FALSE
	update_body(TRUE)
	balloon_alert(src, "something has changed about you")
	return TRUE

/// Fill in the lists of things we can bioscramble into people
/mob/living/carbon/proc/init_bioscrambler_lists()
	var/list/body_parts = typesof(/obj/item/bodypart/chest) + typesof(/obj/item/bodypart/head) + subtypesof(/obj/item/bodypart/arm) + subtypesof(/obj/item/bodypart/leg)
	for(var/obj/item/bodypart/part as anything in body_parts)
		if(!is_type_in_typecache(part, GLOB.bioscrambler_parts_blacklist) && BODYTYPE_CAN_BE_BIOSCRAMBLED(initial(part.bodytype)))
			continue
		body_parts -= part
	GLOB.bioscrambler_valid_parts = body_parts

	var/list/organs = subtypesof(/obj/item/organ) + subtypesof(/obj/item/organ)
	for(var/obj/item/organ/organ_type as anything in organs)
		if(!is_type_in_typecache(organ_type, GLOB.bioscrambler_organs_blacklist) && !(initial(organ_type.organ_flags) & ORGAN_ROBOTIC))
			continue
		organs -= organ_type
	GLOB.bioscrambler_valid_organs = organs

/mob/living/carbon/get_shove_flags(mob/living/shover, obj/item/weapon)
	. = ..()
	. |= SHOVE_CAN_STAGGER
	if(IsKnockdown() && !IsParalyzed() && HAS_TRAIT(src, TRAIT_DAZED))
		. |= SHOVE_CAN_KICK_SIDE
	if(HAS_TRAIT(src, TRAIT_NO_SIDE_KICK)) // added as an extra check, just in case
		. &= ~SHOVE_CAN_KICK_SIDE

#undef SHAKE_ANIMATION_OFFSET
