
/mob/living/proc/run_armor_check(def_zone = null, attack_flag = MELEE, absorb_text = null, soften_text = null, armour_penetration, penetrated_text, silent=FALSE, weak_against_armour = FALSE)
	var/our_armor = getarmor(def_zone, attack_flag)

	if(our_armor <= 0)
		return our_armor
	if(weak_against_armour && our_armor >= 0)
		our_armor *= ARMOR_WEAKENED_MULTIPLIER
	if(silent)
		return max(0, PENETRATE_ARMOUR(our_armor, armour_penetration))

	//the if "armor" check is because this is used for everything on /living, including humans
	if(armour_penetration)
		our_armor = max(PENETRATE_ARMOUR(our_armor, armour_penetration), 0)
		if(penetrated_text)
			to_chat(src, span_userdanger("[penetrated_text]"))
		else
			to_chat(src, span_userdanger("Your armor was penetrated!"))
	else if(our_armor >= 100)
		if(absorb_text)
			to_chat(src, span_notice("[absorb_text]"))
		else
			to_chat(src, span_notice("Your armor absorbs the blow!"))
	else
		if(soften_text)
			to_chat(src, span_warning("[soften_text]"))
		else
			to_chat(src, span_warning("Your armor softens the blow!"))
	return our_armor

/mob/living/proc/getarmor(def_zone, type)
	return 0

//this returns the mob's protection against eye damage (number between -1 and 2) from bright lights
/mob/living/proc/get_eye_protection()
	return 0

//this returns the mob's protection against ear damage (0:no protection; 1: some ear protection; 2: has no ears)
/mob/living/proc/get_ear_protection()
	var/turf/current_turf = get_turf(src)
	var/datum/gas_mixture/environment = current_turf.return_air()
	var/pressure = environment ? environment.return_pressure() : 0
	if(pressure < SOUND_MINIMUM_PRESSURE) //space is empty
		return 1
	return 0

/**
 * Checks if our mob has their mouth covered.
 *
 * Note that we only care about [ITEM_SLOT_HEAD] and [ITEM_SLOT_MASK].
 *  (so if you check all slots, it'll return head, then mask)
 *That is also the priority order
 * Arguments
 * * check_flags: What item slots should we check?
 *
 * Retuns a truthy value (a ref to what is covering mouth), or a falsy value (null)
 */
/mob/living/proc/is_mouth_covered(check_flags = ALL)
	return null

/**
 * Checks if our mob has their eyes covered.
 *
 * Note that we only care about [ITEM_SLOT_HEAD], [ITEM_SLOT_MASK], and [ITEM_SLOT_GLASSES].
 * That is also the priority order (so if you check all slots, it'll return head, then mask, then glasses)
 *
 * Arguments
 * * check_flags: What item slots should we check?
 *
 * Retuns a truthy value (a ref to what is covering eyes), or a falsy value (null)
 */
/mob/living/proc/is_eyes_covered(check_flags = ALL)
	return null

/**
 * Checks if our mob is protected from pepper spray.
 *
 * Note that we only care about [ITEM_SLOT_HEAD] and [ITEM_SLOT_MASK].
 * That is also the priority order (so if you check all slots, it'll return head, then mask)
 *
 * Arguments
 * * check_flags: What item slots should we check?
 *
 * Retuns a truthy value (a ref to what is protecting us), or a falsy value (null)
 */
/mob/living/proc/is_pepper_proof(check_flags = ALL)
	return null

/// Checks if the mob's ears (BOTH EARS, BOWMANS NEED NOT APPLY) are covered by something.
/// Returns the atom covering the mob's ears, or null if their ears are uncovered.
/mob/living/proc/is_ears_covered()
	return null

/mob/living/bullet_act(obj/projectile/proj, def_zone, piercing_hit = FALSE, blocked = 0)
	. = ..()
	if (. != BULLET_ACT_HIT)
		return .

	if(blocked >= 100)
		if(proj.is_hostile_projectile())
			apply_projectile_effects(proj, def_zone, blocked)
		return .

	var/hit_limb_zone = check_hit_limb_zone_name(def_zone)
	var/organ_hit_text = ""
	if (hit_limb_zone)
		organ_hit_text = " in \the [parse_zone_with_bodypart(hit_limb_zone)]"

	switch (proj.suppressed)
		if (SUPPRESSED_QUIET)
			to_chat(src, span_userdanger("You're shot by \a [proj][organ_hit_text]!"))
		if (SUPPRESSED_NONE)
			visible_message(span_danger("[src] is hit by \a [proj][organ_hit_text]!"), \
					span_userdanger("You're hit by \a [proj][organ_hit_text]!"), null, COMBAT_MESSAGE_RANGE)
			if(is_blind())
				to_chat(src, span_userdanger("You feel something hit you[organ_hit_text]!"))

	if(proj.is_hostile_projectile())
		apply_projectile_effects(proj, def_zone, blocked)

/mob/living/proc/apply_projectile_effects(obj/projectile/proj, def_zone, armor_check)
	apply_damage(
		damage = proj.damage,
		damagetype = proj.damage_type,
		def_zone = def_zone,
		blocked = min(ARMOR_MAX_BLOCK, armor_check),  //cap damage reduction at 90%
		wound_bonus = proj.wound_bonus,
		bare_wound_bonus = proj.bare_wound_bonus,
		sharpness = proj.sharpness,
		attack_direction = get_dir(proj.starting, src),
		attacking_item = proj,
	)

	apply_effects(
		stun = proj.stun,
		knockdown = proj.knockdown,
		unconscious = proj.unconscious,
		slur = (mob_biotypes & MOB_ROBOTIC) ? 0 SECONDS : proj.slur, // Don't want your cyborgs to slur from being ebow'd
		stutter = (mob_biotypes & MOB_ROBOTIC) ? 0 SECONDS : proj.stutter, // Don't want your cyborgs to stutter from being tazed
		eyeblur = proj.eyeblur,
		drowsy = proj.drowsy,
		blocked = armor_check,
		stamina = proj.stamina,
		jitter = (mob_biotypes & MOB_ROBOTIC) ? 0 SECONDS : proj.jitter, // Cyborgs can jitter but not from being shot
		paralyze = proj.paralyze,
		immobilize = proj.immobilize,
	)

	if(proj.dismemberment)
		check_projectile_dismemberment(proj, def_zone)

	if (proj.damage && armor_check < 100)
		create_projectile_hit_effects(proj, def_zone, armor_check)

/mob/living/proc/create_projectile_hit_effects(obj/projectile/proj, def_zone, blocked)
	if (proj.damage_type != BRUTE)
		return

	var/obj/item/bodypart/hit_bodypart = get_bodypart(check_hit_limb_zone_name(def_zone))
	if (blood_volume && (isnull(hit_bodypart) || hit_bodypart.can_bleed()))
		create_splatter(angle2dir(proj.angle))
		if(prob(33))
			add_splatter_floor(get_turf(src))
		return

	if (hit_bodypart?.biological_state & (BIO_METAL|BIO_WIRED))
		var/random_damage_mult = RANDOM_DECIMAL(0.85, 1.15) // SOMETIMES you can get more or less sparks
		var/damage_dealt = ((proj.damage / (1 - (blocked / 100))) * random_damage_mult)

		var/spark_amount = round((damage_dealt / PROJECTILE_DAMAGE_PER_ROBOTIC_SPARK))
		if (spark_amount > 0)
			do_sparks(spark_amount, FALSE, src)

/mob/living/check_projectile_armor(def_zone, obj/projectile/impacting_projectile, is_silent)
	return run_armor_check(def_zone, impacting_projectile.armor_flag, "","",impacting_projectile.armour_penetration, "", is_silent, impacting_projectile.weak_against_armour)

/mob/living/proc/check_projectile_dismemberment(obj/projectile/proj, def_zone)
	return

/obj/item/proc/get_volume_by_throwforce_and_or_w_class()
	if(throwforce && w_class)
		return clamp((throwforce + w_class) * 5, 30, 100)// Add the item's throwforce to its weight class and multiply by 5, then clamp the value between 30 and 100
	if(w_class)
		return clamp(w_class * 8, 20, 100) // Multiply the item's weight class by 8, then clamp the value between 20 and 100
	return 0

/mob/living/proc/set_combat_mode(new_mode, silent = TRUE)

	if(HAS_TRAIT(src, TRAIT_COMBAT_MODE_LOCK))
		return

	if(combat_mode == new_mode)
		return
	. = combat_mode
	combat_mode = new_mode
	if(hud_used?.action_intent)
		hud_used.action_intent.update_appearance()
	if(silent || !(client?.prefs.read_preference(/datum/preference/toggle/sound_combatmode)))
		return
	if(combat_mode)
		SEND_SOUND(src, sound('sound/misc/ui_togglecombat.ogg', volume = 25)) //Sound from interbay!
	else
		SEND_SOUND(src, sound('sound/misc/ui_toggleoffcombat.ogg', volume = 25)) //Slightly modified version of the above

/mob/living/hitby(atom/movable/AM, skipcatch, hitpush = TRUE, blocked = FALSE, datum/thrownthing/throwingdatum)
	if(!isitem(AM))
		// Filled with made up numbers for non-items.
		if(check_block(AM, 30, "\the [AM.name]", THROWN_PROJECTILE_ATTACK, 0, BRUTE) & SUCCESSFUL_BLOCK)
			hitpush = FALSE
			skipcatch = TRUE
			blocked = TRUE
			return SUCCESSFUL_BLOCK
		else
			playsound(loc, 'sound/items/weapons/genhit.ogg', 50, TRUE, -1) //Item sounds are handled in the item itself
			if(!isvendor(AM) && !iscarbon(AM)) //Vendors have special interactions, while carbon mobs already generate visible messages!
				visible_message(span_danger("[src] is hit by [AM]!"), \
							span_userdanger("You're hit by [AM]!"))
		log_combat(AM, src, "hit ")
		return ..()

	var/obj/item/thrown_item = AM
	if(thrown_item.thrownby == WEAKREF(src)) //No throwing stuff at yourself to trigger hit reactions
		return ..()

	if(check_block(AM, thrown_item.throwforce, "\the [thrown_item.name]", THROWN_PROJECTILE_ATTACK, 0, thrown_item.damtype))
		hitpush = FALSE
		skipcatch = TRUE
		blocked = TRUE

	var/zone = get_random_valid_zone(BODY_ZONE_CHEST, 65)//Hits a random part of the body, geared towards the chest
	var/nosell_hit = (SEND_SIGNAL(thrown_item, COMSIG_MOVABLE_IMPACT_ZONE, src, zone, blocked, throwingdatum) & MOVABLE_IMPACT_ZONE_OVERRIDE) // TODO: find a better way to handle hitpush and skipcatch for humans
	if(nosell_hit)
		skipcatch = TRUE
		hitpush = FALSE

	if(blocked)
		return SUCCESSFUL_BLOCK

	var/mob/thrown_by = thrown_item.thrownby?.resolve()
	if(thrown_by)
		log_combat(thrown_by, src, "threw and hit", thrown_item)
	else
		log_combat(thrown_item, src, "hit ")
	if(nosell_hit)
		return ..()
	visible_message(span_danger("[src] is hit by [thrown_item]!"), \
					span_userdanger("You're hit by [thrown_item]!"))
	if(!thrown_item.throwforce)
		return
	var/armor = run_armor_check(zone, MELEE, "Your armor has protected your [parse_zone_with_bodypart(zone)].", "Your armor has softened hit to your [parse_zone_with_bodypart(zone)].", thrown_item.armour_penetration, "", FALSE, thrown_item.weak_against_armour)
	apply_damage(thrown_item.throwforce, thrown_item.damtype, zone, armor, sharpness = thrown_item.get_sharpness(), wound_bonus = (nosell_hit * CANT_WOUND))
	if(QDELETED(src)) //Damage can delete the mob.
		return
	if(body_position == LYING_DOWN) // physics says it's significantly harder to push someone by constantly chucking random furniture at them if they are down on the floor.
		hitpush = FALSE
	return ..()

/mob/living/proc/create_splatter(splatter_dir)
	new /obj/effect/temp_visual/dir_setting/bloodsplatter(get_turf(src), splatter_dir)

///The core of catching thrown items, which non-carbons cannot without the help of items or abilities yet, as they've no throw mode.
/mob/living/proc/try_catch_item(obj/item/item, skip_throw_mode_check = FALSE, try_offhand = FALSE)
	if(!can_catch_item(skip_throw_mode_check, try_offhand) || !isitem(item) || HAS_TRAIT(item, TRAIT_UNCATCHABLE) || !isturf(item.loc))
		return FALSE
	if(!can_hold_items(item))
		return FALSE
	INVOKE_ASYNC(item, TYPE_PROC_REF(/obj/item, attempt_pickup), src, TRUE)
	if(get_active_held_item() == item) //if our attack_hand() picks up the item...
		visible_message(span_warning("[src] catches [item]!"), \
						span_userdanger("You catch [item] in mid-air!"))
		return TRUE

///Checks the requites for catching a throw item.
/mob/living/proc/can_catch_item(skip_throw_mode_check = FALSE, try_offhand = FALSE)
	if(HAS_TRAIT(src, TRAIT_HANDS_BLOCKED))
		return FALSE
	if(get_active_held_item() && (!try_offhand || get_inactive_held_item() || !swap_hand()))
		return FALSE
	return TRUE

/mob/living/fire_act()
	. = ..()
	adjust_fire_stacks(3)
	ignite_mob()

/**
 * Called when a mob is grabbing another mob.
 */
/mob/living/proc/grab(mob/living/target)
	if(!istype(target))
		return FALSE
	if(SEND_SIGNAL(src, COMSIG_LIVING_GRAB, target) & (COMPONENT_CANCEL_ATTACK_CHAIN|COMPONENT_SKIP_ATTACK))
		return FALSE
	if(target.check_block(src, 0, "[src]'s grab", UNARMED_ATTACK))
		return FALSE
	target.grabbedby(src)
	return TRUE

/**
 * Called when this mob is grabbed by another mob.
 */
/mob/living/proc/grabbedby(mob/living/user, supress_message = FALSE)
	if(user == src || anchored || !isturf(user.loc))
		return FALSE

	if(!user.pulling || user.pulling != src)
		user.start_pulling(src, supress_message = supress_message)
		return

	if(!(status_flags & CANPUSH) || HAS_TRAIT(src, TRAIT_PUSHIMMUNE))
		to_chat(user, span_warning("[src] can't be grabbed more aggressively!"))
		return FALSE

	if(user.grab_state >= GRAB_AGGRESSIVE && HAS_TRAIT(user, TRAIT_PACIFISM))
		to_chat(user, span_warning("You don't want to risk hurting [src]!"))
		return FALSE

	grippedby(user)
	update_incapacitated()

//proc to upgrade a simple pull into a more aggressive grab.
/mob/living/proc/grippedby(mob/living/user, instant = FALSE)
	if(user.grab_state >= user.max_grab)
		return
	user.changeNext_move(CLICK_CD_GRABBING)
	var/sound_to_play = 'sound/items/weapons/thudswoosh.ogg'
	if(ishuman(user))
		var/mob/living/carbon/human/H = user
		if(H.dna.species.grab_sound)
			sound_to_play = H.dna.species.grab_sound
	playsound(src.loc, sound_to_play, 50, TRUE, -1)

	if(user.grab_state) //only the first upgrade is instantaneous
		var/old_grab_state = user.grab_state
		var/grab_upgrade_time = instant ? 0 : 30
		visible_message(span_danger("[user] starts to tighten [user.p_their()] grip on [src]!"), \
						span_userdanger("[user] starts to tighten [user.p_their()] grip on you!"), span_hear("You hear aggressive shuffling!"), null, user)
		to_chat(user, span_danger("You start to tighten your grip on [src]!"))
		switch(user.grab_state)
			if(GRAB_AGGRESSIVE)
				log_combat(user, src, "attempted to neck grab", addition="neck grab")
			if(GRAB_NECK)
				log_combat(user, src, "attempted to strangle", addition="kill grab")
		if(!do_after(user, grab_upgrade_time, src))
			return FALSE
		if(!user.pulling || user.pulling != src || user.grab_state != old_grab_state)
			return FALSE
	user.setGrabState(user.grab_state + 1)
	switch(user.grab_state)
		if(GRAB_AGGRESSIVE)
			var/add_log = ""
			if(HAS_TRAIT(user, TRAIT_PACIFISM))
				visible_message(span_danger("[user] firmly grips [src]!"),
								span_danger("[user] firmly grips you!"), span_hear("You hear aggressive shuffling!"), null, user)
				to_chat(user, span_danger("You firmly grip [src]!"))
				add_log = " (pacifist)"
			else
				visible_message(span_danger("[user] grabs [src] aggressively!"), \
								span_userdanger("[user] grabs you aggressively!"), span_hear("You hear aggressive shuffling!"), null, user)
				to_chat(user, span_danger("You grab [src] aggressively!"))
			stop_pulling()
			log_combat(user, src, "grabbed", addition="aggressive grab[add_log]")
		if(GRAB_NECK)
			log_combat(user, src, "grabbed", addition="neck grab")
			visible_message(span_danger("[user] grabs [src] by the neck!"),\
							span_userdanger("[user] grabs you by the neck!"), span_hear("You hear aggressive shuffling!"), null, user)
			to_chat(user, span_danger("You grab [src] by the neck!"))
			if(!buckled && !density)
				Move(user.loc)
		if(GRAB_KILL)
			log_combat(user, src, "strangled", addition="kill grab")
			visible_message(span_danger("[user] is strangling [src]!"), \
							span_userdanger("[user] is strangling you!"), span_hear("You hear aggressive shuffling!"), null, user)
			to_chat(user, span_danger("You're strangling [src]!"))
			if(!buckled && !density)
				Move(user.loc)
	user.set_pull_offsets(src, user.grab_state)
	return TRUE

/mob/living/attack_animal(mob/living/simple_animal/user, list/modifiers)
	. = ..()
	if(.)
		return FALSE // looks wrong, but if the attack chain was cancelled we don't propogate it up to children calls. Yeah it's cringe.

	if(user.melee_damage_upper == 0)
		if(user != src)
			visible_message(
				span_notice("[user] [user.friendly_verb_continuous] [src]!"),
				span_notice("[user] [user.friendly_verb_continuous] you!"),
				vision_distance = COMBAT_MESSAGE_RANGE,
				ignored_mobs = user,
			)
			to_chat(user, span_notice("You [user.friendly_verb_simple] [src]!"))
		return FALSE

	if(HAS_TRAIT(user, TRAIT_PACIFISM))
		to_chat(user, span_warning("You don't want to hurt anyone!"))
		return FALSE

	var/damage = rand(user.melee_damage_lower, user.melee_damage_upper)
	if(check_block(user, damage, "[user]'s [user.attack_verb_simple]", UNARMED_ATTACK, user.armour_penetration, user.melee_damage_type))
		return FALSE

	if(user.attack_sound)
		playsound(src, user.attack_sound, 50, TRUE, TRUE)

	user.do_attack_animation(src)
	visible_message(
		span_danger("[user] [user.attack_verb_continuous] [src]!"),
		span_userdanger("[user] [user.attack_verb_continuous] you!"),
		null,
		COMBAT_MESSAGE_RANGE,
		user,
	)

	var/dam_zone = dismembering_strike(user, pick(BODY_ZONE_CHEST, BODY_ZONE_PRECISE_L_HAND, BODY_ZONE_PRECISE_R_HAND, BODY_ZONE_L_LEG, BODY_ZONE_R_LEG))
	if(!dam_zone) //Dismemberment successful
		return FALSE

	var/armor_block = run_armor_check(user.zone_selected, MELEE, armour_penetration = user.armour_penetration)

	to_chat(user, span_danger("You [user.attack_verb_simple] [src]!"))
	log_combat(user, src, "attacked")
	var/damage_done = apply_damage(
		damage = damage,
		damagetype = user.melee_damage_type,
		def_zone = user.zone_selected,
		blocked = armor_block,
		wound_bonus = user.wound_bonus,
		bare_wound_bonus = user.bare_wound_bonus,
		sharpness = user.sharpness,
		attack_direction = get_dir(user, src),
	)
	return damage_done

/mob/living/attack_hand(mob/living/carbon/human/user, list/modifiers)
	. = ..()
	if(.)
		return TRUE

	for(var/datum/surgery/operations as anything in surgeries)
		if(user.combat_mode)
			break
		if(IS_IN_INVALID_SURGICAL_POSITION(src, operations))
			continue
		if(operations.next_step(user, modifiers))
			return TRUE

	return FALSE

/mob/living/attack_paw(mob/living/carbon/human/user, list/modifiers)
	if(LAZYACCESS(modifiers, RIGHT_CLICK))
		user.disarm(src)
		return TRUE
	if (!user.combat_mode)
		return FALSE
	if(HAS_TRAIT(user, TRAIT_PACIFISM))
		to_chat(user, span_warning("You don't want to hurt anyone!"))
		return FALSE

	if(!user.get_bodypart(BODY_ZONE_HEAD))
		return FALSE
	if(user.is_mouth_covered(ITEM_SLOT_MASK))
		to_chat(user, span_warning("You can't bite with your mouth covered!"))
		return FALSE

	if(check_block(user, 1, "[user]'s bite", UNARMED_ATTACK, 0, BRUTE))
		return FALSE

	user.do_attack_animation(src, ATTACK_EFFECT_BITE)
	if (HAS_TRAIT(user, TRAIT_PERFECT_ATTACKER) || prob(75))
		log_combat(user, src, "attacked")
		playsound(loc, 'sound/items/weapons/bite.ogg', 50, TRUE, -1)
		visible_message(span_danger("[user.name] bites [src]!"), \
						span_userdanger("[user.name] bites you!"), span_hear("You hear a chomp!"), COMBAT_MESSAGE_RANGE, user)
		to_chat(user, span_danger("You bite [src]!"))
		return TRUE
	else
		visible_message(span_danger("[user.name]'s bite misses [src]!"), \
						span_danger("You avoid [user.name]'s bite!"), span_hear("You hear the sound of jaws snapping shut!"), COMBAT_MESSAGE_RANGE, user)
		to_chat(user, span_warning("Your bite misses [src]!"))

	return FALSE

/mob/living/attack_larva(mob/living/carbon/alien/larva/L, list/modifiers)
	if(L.combat_mode)
		if(HAS_TRAIT(L, TRAIT_PACIFISM))
			to_chat(L, span_warning("You don't want to hurt anyone!"))
			return FALSE

		if(check_block(L, 1, "[L]'s bite", UNARMED_ATTACK, 0, BRUTE))
			return FALSE

		L.do_attack_animation(src)
		if(prob(90))
			log_combat(L, src, "attacked")
			visible_message(span_danger("[L.name] bites [src]!"), \
							span_userdanger("[L.name] bites you!"), span_hear("You hear a chomp!"), COMBAT_MESSAGE_RANGE, L)
			to_chat(L, span_danger("You bite [src]!"))
			playsound(loc, 'sound/items/weapons/bite.ogg', 50, TRUE, -1)
			return TRUE
		else
			visible_message(span_danger("[L.name]'s bite misses [src]!"), \
							span_danger("You avoid [L.name]'s bite!"), span_hear("You hear the sound of jaws snapping shut!"), COMBAT_MESSAGE_RANGE, L)
			to_chat(L, span_warning("Your bite misses [src]!"))
			return FALSE

	visible_message(span_notice("[L.name] rubs its head against [src]."), \
					span_notice("[L.name] rubs its head against you."), null, null, L)
	to_chat(L, span_notice("You rub your head against [src]."))
	return FALSE

/mob/living/attack_alien(mob/living/carbon/alien/adult/user, list/modifiers)
	SEND_SIGNAL(src, COMSIG_MOB_ATTACK_ALIEN, user, modifiers)
	if(LAZYACCESS(modifiers, RIGHT_CLICK))
		if(check_block(user, 0, "[user]'s tackle", UNARMED_ATTACK, 0, BRUTE))
			return FALSE
		user.do_attack_animation(src, ATTACK_EFFECT_DISARM)
		return TRUE

	if(user.combat_mode)
		if(HAS_TRAIT(user, TRAIT_PACIFISM))
			to_chat(user, span_warning("You don't want to hurt anyone!"))
			return FALSE
		if(check_block(user, user.melee_damage_upper, "[user]'s slash", UNARMED_ATTACK, 0, BRUTE))
			return FALSE
		user.do_attack_animation(src)
		return TRUE

	visible_message(span_notice("[user] caresses [src] with its scythe-like arm."), \
					span_notice("[user] caresses you with its scythe-like arm."), null, null, user)
	to_chat(user, span_notice("You caress [src] with your scythe-like arm."))
	return FALSE

/mob/living/attack_hulk(mob/living/carbon/human/user)
	..()
	if(HAS_TRAIT(user, TRAIT_PACIFISM))
		to_chat(user, span_warning("You don't want to hurt [src]!"))
		return FALSE
	return TRUE

/mob/living/ex_act(severity, target, origin)
	if(origin && istype(origin, /datum/spacevine_mutation) && isvineimmune(src))
		return FALSE
	return ..()

/mob/living/acid_act(acidpwr, acid_volume)
	take_bodypart_damage(acidpwr * min(1, acid_volume * 0.1))
	return TRUE

///As the name suggests, this should be called to apply electric shocks.
/mob/living/proc/electrocute_act(shock_damage, source, siemens_coeff = 1, flags = NONE)
	if(SEND_SIGNAL(src, COMSIG_LIVING_ELECTROCUTE_ACT, shock_damage, source, siemens_coeff, flags) & COMPONENT_LIVING_BLOCK_SHOCK)
		return FALSE
	shock_damage *= siemens_coeff
	if((flags & SHOCK_TESLA) && HAS_TRAIT(src, TRAIT_TESLA_SHOCKIMMUNE))
		return FALSE
	if(HAS_TRAIT(src, TRAIT_SHOCKIMMUNE))
		return FALSE
	if(shock_damage < 1)
		return FALSE
	if(!(flags & SHOCK_ILLUSION))
		adjustFireLoss(shock_damage)
	else
		adjustStaminaLoss(shock_damage)
	if(!(flags & SHOCK_SUPPRESS_MESSAGE))
		visible_message(
			span_danger("[src] was shocked by \the [source]!"), \
			span_userdanger("You feel a powerful shock coursing through your body!"), \
			span_hear("You hear a heavy electrical crack.") \
		)
	return shock_damage

/mob/living/emp_act(severity)
	. = ..()
	if(. & EMP_PROTECT_CONTENTS)
		return
	for(var/obj/inside in contents)
		inside.emp_act(severity)

///Logs, gibs and returns point values of whatever mob is unfortunate enough to get eaten.
/mob/living/singularity_act()
	investigate_log("has been consumed by the singularity.", INVESTIGATE_ENGINE) //Oh that's where the clown ended up!
	investigate_log("has been gibbed by the singularity.", INVESTIGATE_DEATHS)
	gib()
	return 20

/mob/living/narsie_act()
	if(HAS_TRAIT(src, TRAIT_GODMODE) || QDELETED(src))
		return

	if(GLOB.cult_narsie && GLOB.cult_narsie.souls_needed[src])
		GLOB.cult_narsie.souls_needed -= src
		GLOB.cult_narsie.souls += 1
		if((GLOB.cult_narsie.souls == GLOB.cult_narsie.soul_goal) && (GLOB.cult_narsie.resolved == FALSE))
			GLOB.cult_narsie.resolved = TRUE
			sound_to_playing_players('sound/announcer/alarm/nuke_alarm.ogg', 70)
			addtimer(CALLBACK(GLOBAL_PROC, GLOBAL_PROC_REF(cult_ending_helper), CULT_VICTORY_MASS_CONVERSION), 12 SECONDS)
			addtimer(CALLBACK(GLOBAL_PROC, GLOBAL_PROC_REF(ending_helper)), 27 SECONDS)
	if(client)
		make_new_construct(/mob/living/basic/construct/harvester, src, cultoverride = TRUE)
	else
		switch(rand(1, 4))
			if(1)
				new /mob/living/basic/construct/juggernaut/hostile(get_turf(src))
			if(2)
				new /mob/living/basic/construct/wraith/hostile(get_turf(src))
			if(3)
				new /mob/living/basic/construct/artificer/hostile(get_turf(src))
			if(4)
				new /mob/living/basic/construct/proteon/hostile(get_turf(src))
	spawn_dust()
	investigate_log("has been gibbed by Nar'Sie.", INVESTIGATE_DEATHS)
	gib()
	return TRUE

//called when the mob receives a bright flash
/mob/living/proc/flash_act(intensity = 1, override_blindness_check = 0, affect_silicon = 0, visual = 0, type = /atom/movable/screen/fullscreen/flash, length = 2.5 SECONDS)
	if(HAS_TRAIT(src, TRAIT_NOFLASH))
		return FALSE
	if(get_eye_protection() >= intensity)
		return FALSE
	if(is_blind() && !(override_blindness_check || affect_silicon))
		return FALSE

	// this forces any kind of flash (namely normal and static) to use a black screen for photosensitive players
	// it absolutely isn't an ideal solution since sudden flashes to black can apparently still trigger epilepsy, but byond apparently doesn't let you freeze screens
	// and this is apparently at least less likely to trigger issues than a full white/static flash
	if(client?.prefs?.read_preference(/datum/preference/toggle/darkened_flash))
		type = /atom/movable/screen/fullscreen/flash/black

	overlay_fullscreen("flash", type)
	addtimer(CALLBACK(src, PROC_REF(clear_fullscreen), "flash", length), length)
	SEND_SIGNAL(src, COMSIG_MOB_FLASHED, intensity, override_blindness_check, affect_silicon, visual, type, length)
	return TRUE

//called when the mob receives a loud bang
/mob/living/proc/soundbang_act()
	return FALSE

//to damage the clothes worn by a mob
/mob/living/proc/damage_clothes(damage_amount, damage_type = BRUTE, damage_flag = 0, def_zone)
	return


/mob/living/do_attack_animation(atom/A, visual_effect_icon, obj/item/used_item, no_effect)
	if(!used_item)
		used_item = get_active_held_item()
	..()

/**
 * Does a slap animation on an atom
 *
 * Uses do_attack_animation to animate the attacker attacking
 * then draws a hand moving across the top half of the target(where a mobs head would usually be) to look like a slap
 * Arguments:
 * * atom/A - atom being slapped
 */
/mob/living/proc/do_slap_animation(atom/slapped)
	do_attack_animation(slapped, no_effect=TRUE)
	var/mutable_appearance/glove_appearance = mutable_appearance('icons/effects/effects.dmi', "slapglove")
	glove_appearance.pixel_y = 10 // should line up with head
	glove_appearance.pixel_x = 10
	var/atom/movable/flick_visual/glove = slapped.flick_overlay_view(glove_appearance, 1 SECONDS)

	// And animate the attack!
	animate(glove, alpha = 175, transform = matrix() * 0.75, pixel_x = 0, pixel_y = 10, pixel_z = 0, time = 3)
	animate(time = 1)
	animate(alpha = 0, time = 3, easing = CIRCULAR_EASING|EASE_OUT)

/** Handles exposing a mob to reagents.
 *
 * If the methods include INGEST or INHALE, the mob tastes the reagents.
 * If the methods include VAPOR it incorporates permiability protection.
 */
/mob/living/expose_reagents(list/reagents, datum/reagents/source, methods=TOUCH, volume_modifier=1, show_message=TRUE)
	. = ..()
	if(. & COMPONENT_NO_EXPOSE_REAGENTS)
		return

	if(methods & (INGEST | INHALE))
		taste_list(reagents)

	var/touch_protection = (methods & VAPOR) ? getarmor(null, BIO) * 0.01 : 0
	SEND_SIGNAL(source, COMSIG_REAGENTS_EXPOSE_MOB, src, reagents, methods, volume_modifier, show_message, touch_protection)
	for(var/datum/reagent/reagent as anything in reagents)
		var/reac_volume = reagents[reagent]
		. |= reagent.expose_mob(src, methods, reac_volume, show_message, touch_protection)

/// Simplified ricochet angle calculation for mobs (also the base version doesn't work on mobs)
/mob/living/handle_ricochet(obj/projectile/ricocheting_projectile)
	var/face_angle = get_angle_raw(ricocheting_projectile.x, ricocheting_projectile.pixel_x, ricocheting_projectile.pixel_y, ricocheting_projectile.p_y, x, y, pixel_x, pixel_y)
	var/new_angle_s = SIMPLIFY_DEGREES(face_angle + GET_ANGLE_OF_INCIDENCE(face_angle, (ricocheting_projectile.angle + 180)))
	ricocheting_projectile.set_angle(new_angle_s)
	return TRUE

/**
 * Attempt to disarm the target mob. Some items might let you do it, also carbon can do it with right click.
 * Will shove the target mob back, and drop them if they're in front of something dense
 * or another carbon.
*/
/mob/living/proc/disarm(mob/living/target, obj/item/weapon)
	if(!can_disarm(target))
		return
	var/shove_flags = target.get_shove_flags(src, weapon)
	if(weapon)
		do_attack_animation(target, used_item = weapon)
		playsound(target, 'sound/effects/glass/glassbash.ogg', 50, TRUE, -1)
	else
		do_attack_animation(target, ATTACK_EFFECT_DISARM)
		playsound(target, 'sound/items/weapons/shove.ogg', 50, TRUE, -1)
	if (ishuman(target) && isnull(weapon))
		var/mob/living/carbon/human/human_target = target
		human_target.w_uniform?.add_fingerprint(src)

	SEND_SIGNAL(target, COMSIG_LIVING_DISARM_HIT, src, zone_selected, weapon)
	var/shove_dir = get_dir(loc, target.loc)
	var/turf/target_shove_turf = get_step(target.loc, shove_dir)
	var/turf/target_old_turf = target.loc

	//Are we hitting anything? or
	if(shove_flags & SHOVE_CAN_MOVE)
		if(SEND_SIGNAL(target_shove_turf, COMSIG_LIVING_DISARM_PRESHOVE, src, target, weapon) & COMSIG_LIVING_ACT_SOLID)
			shove_flags |= SHOVE_BLOCKED
		else
			target.Move(target_shove_turf, shove_dir)
			if(get_turf(target) == target_old_turf)
				shove_flags |= SHOVE_BLOCKED

	if(!(shove_flags & SHOVE_BLOCKED))
		target.setGrabState(GRAB_PASSIVE)

	//Directional checks to make sure that we're not shoving through a windoor or something like that
	if((shove_flags & SHOVE_BLOCKED) && (shove_dir in GLOB.cardinals))
		var/target_turf = get_turf(target)
		for(var/obj/obj_content in target_turf)
			if(obj_content.flags_1 & ON_BORDER_1 && obj_content.dir == shove_dir && obj_content.density)
				shove_flags |= SHOVE_DIRECTIONAL_BLOCKED
				break
		if(target_turf != target_shove_turf && !(shove_flags && SHOVE_DIRECTIONAL_BLOCKED)) //Make sure that we don't run the exact same check twice on the same tile
			for(var/obj/obj_content in target_shove_turf)
				if(obj_content.flags_1 & ON_BORDER_1 && obj_content.dir == REVERSE_DIR(shove_dir) && obj_content.density)
					shove_flags |= SHOVE_DIRECTIONAL_BLOCKED
					break

	if(shove_flags & SHOVE_CAN_HIT_SOMETHING)
		//Don't hit people through windows, ok?
		if(!(shove_flags & SHOVE_DIRECTIONAL_BLOCKED) && (SEND_SIGNAL(target_shove_turf, COMSIG_LIVING_DISARM_COLLIDE, src, target, shove_flags, weapon) & COMSIG_LIVING_SHOVE_HANDLED))
			return
		if((shove_flags & SHOVE_BLOCKED) && !(shove_flags & (SHOVE_KNOCKDOWN_BLOCKED|SHOVE_CAN_KICK_SIDE)))
			target.Knockdown(SHOVE_KNOCKDOWN_SOLID, daze_amount = 3 SECONDS)
			target.visible_message(span_danger("[name] shoves [target.name], knocking [target.p_them()] down!"),
				span_userdanger("You're knocked down from a shove by [name]!"), span_hear("You hear aggressive shuffling followed by a loud thud!"), COMBAT_MESSAGE_RANGE, src)
			to_chat(src, span_danger("You shove [target.name], knocking [target.p_them()] down!"))
			log_combat(src, target, "shoved", "knocking them down[weapon ? " with [weapon]" : ""]")
			return

	if(shove_flags & SHOVE_CAN_KICK_SIDE) //KICK HIM IN THE NUTS
		target.Paralyze(SHOVE_CHAIN_PARALYZE)
		target.apply_status_effect(/datum/status_effect/no_side_kick)
		target.visible_message(span_danger("[name] kicks [target.name] onto [target.p_their()] side!"),
						span_userdanger("You're kicked onto your side by [name]!"), span_hear("You hear aggressive shuffling followed by a loud thud!"), COMBAT_MESSAGE_RANGE, src)
		to_chat(src, span_danger("You kick [target.name] onto [target.p_their()] side!"))
		addtimer(CALLBACK(target, TYPE_PROC_REF(/mob/living, SetKnockdown), 0), SHOVE_CHAIN_PARALYZE)
		log_combat(src, target, "kicks", "onto their side (paralyzing)")
		return

	target.get_shoving_message(src, weapon, shove_flags)

	//Take their lunch money
	var/target_held_item = target.get_active_held_item()
	var/append_message = weapon ? " with [weapon]" : ""
	// If it's in our typecache, they're staggered and it exists, disarm. If they're knocked down, disarm too.
	if(target_held_item && target.get_timed_status_effect_duration(/datum/status_effect/staggered) && is_type_in_typecache(target_held_item, GLOB.shove_disarming_types) || target_held_item && target.body_position == LYING_DOWN)
		target.dropItemToGround(target_held_item)
		append_message = "causing [target.p_them()] to drop [target_held_item]"
		target.visible_message(span_danger("[target.name] drops \the [target_held_item]!"),
			span_warning("You drop \the [target_held_item]!"), null, COMBAT_MESSAGE_RANGE)

	if(shove_flags & SHOVE_CAN_STAGGER)
		target.adjust_staggered_up_to(STAGGERED_SLOWDOWN_LENGTH, 10 SECONDS)

	log_combat(src, target, "shoved", append_message)

///Check if the universal conditions for disarming/shoving are met.
/mob/living/proc/can_disarm(mob/living/target)
	if(body_position != STANDING_UP || src == target || loc == target.loc)
		return FALSE
	return TRUE

///Check if there's anything that could stop the knockdown from being shoved into something or someone.
/mob/living/proc/get_shove_flags(mob/living/shover, obj/item/weapon)
	if(shover.move_force >= move_resist)
		. |= SHOVE_CAN_MOVE
		if(!buckled)
			. |= SHOVE_CAN_HIT_SOMETHING
	if(HAS_TRAIT(src, TRAIT_BRAWLING_KNOCKDOWN_BLOCKED))
		. |= SHOVE_KNOCKDOWN_BLOCKED

///Send the chat feedback message for shoving
/mob/living/proc/get_shoving_message(mob/living/shover, obj/item/weapon, shove_flags)
	visible_message(span_danger("[shover] shoves [name][weapon ? " with [weapon]" : ""]!"),
		span_userdanger("You're shoved by [shover][weapon ? " with [weapon]" : ""]!"), span_hear("You hear aggressive shuffling!"), COMBAT_MESSAGE_RANGE, shover)
	to_chat(shover, span_danger("You shove [name][weapon ? " with [weapon]" : ""]!"))

/mob/living/proc/check_block(atom/hit_by, damage, attack_text = "the attack", attack_type = MELEE_ATTACK, armour_penetration = 0, damage_type = BRUTE)
	if(SEND_SIGNAL(src, COMSIG_LIVING_CHECK_BLOCK, hit_by, damage, attack_text, attack_type, armour_penetration, damage_type) & SUCCESSFUL_BLOCK)
		return SUCCESSFUL_BLOCK

	return FAILED_BLOCK
