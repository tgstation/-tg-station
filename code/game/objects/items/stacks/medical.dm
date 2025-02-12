/obj/item/stack/medical
	name = "medical pack"
	singular_name = "medical pack"
	icon = 'icons/obj/medical/stack_medical.dmi'
	worn_icon_state = "nothing"
	amount = 6
	max_amount = 6
	w_class = WEIGHT_CLASS_TINY
	full_w_class = WEIGHT_CLASS_TINY
	throw_speed = 3
	throw_range = 7
	resistance_flags = FLAMMABLE
	max_integrity = 40
	novariants = FALSE
	item_flags = NOBLUDGEON|SKIP_FANTASY_ON_SPAWN
	cost = 250
	source = /datum/robot_energy_storage/medical
	merge_type = /obj/item/stack/medical
	/// How long it takes to apply it to yourself
	var/self_delay = 5 SECONDS
	/// How long it takes to apply it to someone else
	var/other_delay = 0
	/// If we've still got more and the patient is still hurt, should we keep going automatically?
	var/repeating = FALSE
	/// How much brute we heal per application. This is the only number that matters for simplemobs
	var/heal_brute
	/// How much burn we heal per application
	var/heal_burn
	/// How much we reduce bleeding per application on cut wounds
	var/stop_bleeding
	/// How much sanitization to apply to burn wounds on application
	var/sanitization
	/// How much we add to flesh_healing for burn wounds on application
	var/flesh_regeneration
	/// Verb used when applying this object to someone
	var/apply_verb = "treating"
	/// Whether this item can be used on dead bodies
	var/works_on_dead = FALSE
	/// The sound this makes when starting healing with this item
	var/heal_begin_sound = null
	/// The sound this makes when healed successfully with this item
	var/heal_end_sound = null
	/// The sound this makes when doing a continuous loop of healing with this item
	var/heal_continuous_sound = null

/obj/item/stack/medical/interact_with_atom(atom/interacting_with, mob/living/user, list/modifiers)
	if(!isliving(interacting_with))
		return NONE
	if(!begin_heal_loop(interacting_with, user, auto_change_zone = TRUE))
		return NONE // [ITEM_INTERACT_BLOCKING] would be redundant as we are nobludgeon
	return ITEM_INTERACT_SUCCESS

/obj/item/stack/medical/interact_with_atom_secondary(atom/interacting_with, mob/living/user, list/modifiers)
	if(!isliving(interacting_with))
		return NONE
	if(!begin_heal_loop(interacting_with, user, auto_change_zone = FALSE))
		return NONE // see above
	return ITEM_INTERACT_SUCCESS

/obj/item/stack/medical/Initialize(mapload, new_amount, merge, list/mat_override, mat_amt)
	. = ..()
	register_item_context()

/obj/item/stack/medical/add_item_context(obj/item/source, list/context, atom/target, mob/living/user)
	if(!isliving(target))
		return NONE
	if(iscarbon(target))
		context[SCREENTIP_CONTEXT_LMB] = "Auto Heal"
		context[SCREENTIP_CONTEXT_RMB] = "Manual Heal"
	else
		context[SCREENTIP_CONTEXT_LMB] = "Heal"
	return CONTEXTUAL_SCREENTIP_SET

/obj/item/stack/medical/apply_fantasy_bonuses(bonus)
	. = ..()
	if(heal_brute)
		heal_brute = modify_fantasy_variable("heal_brute", heal_brute, bonus)
	if(heal_burn)
		heal_burn = modify_fantasy_variable("heal_burn", heal_burn, bonus)
	if(stop_bleeding)
		stop_bleeding = modify_fantasy_variable("stop_bleeding", stop_bleeding, bonus/10)
	if(sanitization)
		sanitization = modify_fantasy_variable("sanitization", sanitization, bonus/10)
	if(flesh_regeneration)
		flesh_regeneration = modify_fantasy_variable("flesh_regeneration", flesh_regeneration, bonus/10)

/obj/item/stack/medical/remove_fantasy_bonuses(bonus)
	heal_brute = reset_fantasy_variable("heal_brute", heal_brute)
	heal_burn = reset_fantasy_variable("heal_burn", heal_burn)
	stop_bleeding = reset_fantasy_variable("stop_bleeding", stop_bleeding)
	sanitization = reset_fantasy_variable("sanitization", sanitization)
	flesh_regeneration = reset_fantasy_variable("flesh_regeneration", flesh_regeneration)
	return ..()

/// Used to begin the recursive healing loop.
/// Returns TRUE if we entered the loop, FALSE if we didn't
/obj/item/stack/medical/proc/begin_heal_loop(mob/living/patient, mob/living/user, auto_change_zone = TRUE)
	if(DOING_INTERACTION_WITH_TARGET(user, patient))
		return FALSE
	var/heal_zone = check_zone(user.zone_selected)
	if(!try_heal_checks(patient, user, heal_zone))
		return FALSE
	SSblackbox.record_feedback("nested tally", "medical_item_used", 1, list("[auto_change_zone ? "auto" : "manual"]", "[type]"))
	patient.balloon_alert(user, "[apply_verb] [parse_zone(heal_zone)]...")
	INVOKE_ASYNC(src, PROC_REF(try_heal), patient, user, heal_zone, FALSE, iscarbon(patient) && auto_change_zone) // auto change is useless for non-carbons
	return TRUE

/**
 * What actually handles printing the message that we're starting to heal someone, and trying to heal them
 *
 * This proc is recursively called until we run out of charges OR until the patient is fully healed
 * OR until the target zone is fully healed (if auto_change_zone is FALSE)
 *
 * * patient - The mob we're trying to heal
 * * user - The mob that's trying to heal the patient
 * * healed_zone - The zone we're trying to heal on the patient
 * Disregarded if auto_change_zone is TRUE
 * * silent - If we should not print the message that we're starting to heal the patient
 * Used so looping the proc doesn't spam messages
 * * auto_change_zone - Handles the behavior when we finish healing a zone
 * If auto_change_zone is set to TRUE, it picks the next most damaged zone to heal
 * If auto_change_zone is set to FALSE, it'll give the user a chance to pick a new zone to heal
 * If continuous is set to true, it will play the continuous sound for healing
 */
/obj/item/stack/medical/proc/try_heal(mob/living/patient, mob/living/user, healed_zone, silent = FALSE, auto_change_zone = TRUE, var/continuous = FALSE)
	if(heal_begin_sound && !continuous)
		playsound(patient, heal_begin_sound, 75, TRUE, MEDIUM_RANGE_SOUND_EXTRARANGE)
	if(patient == user)
		if(!silent)
			user.visible_message(
				span_notice("[user] starts to apply [src] on [user.p_them()]self..."),
				span_notice("You begin applying [src] on yourself..."),
				visible_message_flags = ALWAYS_SHOW_SELF_MESSAGE,
			)
		if(!do_after(
			user,
			self_delay * (auto_change_zone ? 1 : 0.9),
			patient,
			extra_checks = CALLBACK(src, PROC_REF(can_heal), patient, user, healed_zone),
		))
			return
		if(!auto_change_zone)
			healed_zone = check_zone(user.zone_selected)
		if(!try_heal_checks(patient, user, healed_zone))
			return

	else if(other_delay)
		if(!silent)
			user.visible_message(
				span_notice("[user] starts to apply [src] on [patient]."),
				span_notice("You begin applying [src] on [patient]..."),
				visible_message_flags = ALWAYS_SHOW_SELF_MESSAGE,
			)
		if(!do_after(
			user,
			other_delay * (auto_change_zone ? 1 : 0.9),
			patient,
			extra_checks = CALLBACK(src, PROC_REF(can_heal), patient, user, healed_zone),
		))
			return
		if(!auto_change_zone)
			healed_zone = check_zone(user.zone_selected)
		if(!try_heal_checks(patient, user, healed_zone))
			return

	else
		if(!silent)
			user.visible_message(
				span_notice("[user] applies [src] on [patient]."),
				span_notice("You apply [src] on [patient]."),
				visible_message_flags = ALWAYS_SHOW_SELF_MESSAGE,
			)

	if(iscarbon(patient))
		if(!heal_carbon(patient, user, healed_zone))
			return
	else if(isanimal_or_basicmob(patient))
		if(!heal_simplemob(patient, user))
			return
	else
		CRASH("Stack medical item healing a non-carbon, non-animal mob [patient] ([patient.type])")
	if(!use(1) || !repeating || amount <= 0)
		var/atom/alert_loc = QDELETED(src) ? user : src
		alert_loc.balloon_alert(user, repeating ? "all used up!" : "treated [parse_zone(healed_zone)]")
		playsound(patient, heal_end_sound, 75, TRUE, MEDIUM_RANGE_SOUND_EXTRARANGE)
		return
	if(heal_continuous_sound && (continuous || !silent))
		playsound(patient, heal_continuous_sound, 75, TRUE, MEDIUM_RANGE_SOUND_EXTRARANGE)
	log_combat(user, patient, "healed", src)

	// first, just try looping
	// 1. we can keep healing the current target
	// 2. the user's changed their target (and thus we should heal that limb instead)
	var/preferred_target = check_zone(user.zone_selected)
	if(try_heal_checks(patient, user, preferred_target, silent = TRUE))
		if(preferred_target != healed_zone)
			patient.balloon_alert(user, "[apply_verb] [parse_zone(preferred_target)]...")
		try_heal(patient, user, preferred_target, TRUE, auto_change_zone, TRUE)
		return

	// second, handle what happens otherwise
	if(!iscarbon(patient))
		// behavior 0: non-carbons have no limbs so we can assume they are fully healed
		patient.balloon_alert(user, "fully treated")
	else if(auto_change_zone)
		// behavior 1: automatically pick another zone to heal
		try_heal_auto_change_zone(patient, user, preferred_target, healed_zone)
	else
		// behavior 2: assess injury, giving the user time to manually pick another zone
		try_heal_manual_target(patient, user)
	if(heal_end_sound)
		playsound(patient, heal_end_sound, 75, TRUE, MEDIUM_RANGE_SOUND_EXTRARANGE)

/obj/item/stack/medical/proc/try_heal_auto_change_zone(mob/living/carbon/patient, mob/living/user, preferred_target, last_zone)
	PRIVATE_PROC(TRUE)

	var/list/other_affected_limbs = list()
	for(var/obj/item/bodypart/limb as anything in patient.bodyparts)
		if(!try_heal_checks(patient, user, limb.body_zone, silent = TRUE))
			continue
		other_affected_limbs += limb.body_zone

	if(!length(other_affected_limbs))
		patient.balloon_alert(user, "fully treated")
		return

	var/next_picked = (preferred_target in other_affected_limbs) ? preferred_target : other_affected_limbs[1]
	if(next_picked != last_zone)
		patient.balloon_alert(user, "[apply_verb] [parse_zone(next_picked)]...")
	try_heal(patient, user, next_picked, silent = TRUE, auto_change_zone = TRUE, continuous = TRUE)

/obj/item/stack/medical/proc/try_heal_manual_target(mob/living/carbon/patient, mob/living/user)
	PRIVATE_PROC(TRUE)

	patient.balloon_alert(user, "assessing injury...")
	if(!do_after(user, 1 SECONDS, patient))
		return
	var/new_zone = check_zone(user.zone_selected)
	if(!try_heal_checks(patient, user, new_zone))
		return
	patient.balloon_alert(user, "[apply_verb] [parse_zone(new_zone)]...")
	try_heal(patient, user, new_zone, silent = TRUE, auto_change_zone = FALSE, continuous = TRUE)

/// Checks if the passed patient can be healed by the passed user
/obj/item/stack/medical/proc/can_heal(mob/living/patient, mob/living/user, healed_zone, silent = FALSE)
	return patient.try_inject(user, healed_zone, injection_flags = silent ? NONE : INJECT_TRY_SHOW_ERROR_MESSAGE)

/// Checks a bunch of stuff to see if we can heal the patient, including can_heal
/// Gives a feedback if we can't ultimatly heal the patient (unless silent is TRUE)
/obj/item/stack/medical/proc/try_heal_checks(mob/living/patient, mob/living/user, healed_zone, silent = FALSE)
	if(!(healed_zone in GLOB.all_body_zones))
		stack_trace("Invalid zone ([healed_zone || "null"]) passed to try_heal_checks.")
		healed_zone = BODY_ZONE_CHEST

	if(!can_heal(patient, user, healed_zone, silent))
		// has its own feedback
		return FALSE
	if(!works_on_dead && patient.stat == DEAD)
		if(!silent)
			patient.balloon_alert(user, "[patient.p_theyre()] dead!")
		return FALSE

	if(iscarbon(patient))
		var/mob/living/carbon/carbon_patient = patient
		var/obj/item/bodypart/affecting = carbon_patient.get_bodypart(healed_zone)
		if(!affecting) //Missing limb?
			if(!silent)
				carbon_patient.balloon_alert(user, "no [parse_zone(healed_zone)]!")
			return FALSE
		if(!IS_ORGANIC_LIMB(affecting)) //Limb must be organic to be healed - RR
			if(!silent)
				carbon_patient.balloon_alert(user, "[affecting.plaintext_zone] is not organic!")
			return FALSE

		var/datum/wound/burn/flesh/any_burn_wound = locate() in affecting.wounds
		var/can_heal_burn_wounds = (flesh_regeneration || sanitization) && any_burn_wound?.can_be_ointmented_or_meshed()
		var/can_suture_bleeding = stop_bleeding && affecting.get_modified_bleed_rate() > 0
		var/brute_to_heal = heal_brute && affecting.brute_dam > 0
		var/burn_to_heal = heal_burn && affecting.burn_dam > 0

		if(!brute_to_heal && !burn_to_heal && !can_heal_burn_wounds && !can_suture_bleeding)
			if(!silent)
				if(!brute_to_heal && stop_bleeding) // no brute, no bleeding
					carbon_patient.balloon_alert(user, "[affecting.plaintext_zone] is not bleeding or bruised!")
				else if(!burn_to_heal && (flesh_regeneration || sanitization) && any_burn_wound) // no burns, existing burn wounds are treated
					carbon_patient.balloon_alert(user, "[affecting.plaintext_zone] is fully treated, give it time!")
				else if(!affecting.brute_dam && !affecting.burn_dam) // not hurt at all
					carbon_patient.balloon_alert(user, "[affecting.plaintext_zone] is not hurt!")
				else // probably hurt in some way but we are not the right item for this
					carbon_patient.balloon_alert(user, "can't heal [affecting.plaintext_zone] with [name]!")
			return FALSE
		return TRUE

	if(isanimal_or_basicmob(patient))
		if(!heal_brute) // only brute can heal
			if(!silent)
				patient.balloon_alert(user, "can't heal with [name]!")
			return FALSE
		if(!(patient.mob_biotypes & MOB_ORGANIC))
			if(!silent)
				patient.balloon_alert(user, "no organic tissue!")
			return FALSE
		if(patient.health == patient.maxHealth)
			if(!silent)
				patient.balloon_alert(user, "not hurt!")
			return FALSE
		return TRUE

	return FALSE

/// The healing effects on a carbon patient.
/// Since we have extra details for dealing with bodyparts, we get our own fancy proc.
/// Still returns TRUE on success and FALSE on fail
/obj/item/stack/medical/proc/heal_carbon(mob/living/carbon/patient, mob/living/user, healed_zone)
	var/obj/item/bodypart/affecting = patient.get_bodypart(healed_zone)
	user.visible_message(
		span_green("[user] applies [src] on [patient]'s [affecting.plaintext_zone]."),
		span_green("You apply [src] on [patient]'s [affecting.plaintext_zone]."),
		visible_message_flags = ALWAYS_SHOW_SELF_MESSAGE,
	)
	var/previous_damage = affecting.get_damage()
	if(affecting.heal_damage(heal_brute, heal_burn))
		patient.update_damage_overlays()
	if(stop_bleeding)
		for(var/datum/wound/wound as anything in affecting.wounds)
			if(wound.blood_flow)
				wound.adjust_blood_flow(-1 * stop_bleeding * (user == patient ? 0.7 : 1))
				break // one at a time
		affecting.adjustBleedStacks(-1 * stop_bleeding, 0)
	if(flesh_regeneration || sanitization)
		for(var/datum/wound/burn/flesh/wound as anything in affecting.wounds)
			if(wound.can_be_ointmented_or_meshed())
				wound.flesh_healing += flesh_regeneration
				wound.sanitization += sanitization
				break // one at a time
	post_heal_effects(max(previous_damage - affecting.get_damage(), 0), patient, user)
	return TRUE

/// Healing a simple mob, just an adjustbruteloss call
/obj/item/stack/medical/proc/heal_simplemob(mob/living/patient, mob/living/user)
	patient.adjustBruteLoss(-1 * (heal_brute * patient.maxHealth / 100))
	user.visible_message(
		span_green("[user] applies [src] on [patient]."),
		span_green("You apply [src] on [patient]."),
		visible_message_flags = ALWAYS_SHOW_SELF_MESSAGE,
	)
	return TRUE

///Override this proc for special post heal effects. Only called for carbon patients.
/obj/item/stack/medical/proc/post_heal_effects(amount_healed, mob/living/carbon/healed_mob, mob/living/user)
	return

/obj/item/stack/medical/bruise_pack
	name = "bruise pack"
	singular_name = "bruise pack"
	desc = "A therapeutic gel pack and bandages designed to treat blunt-force trauma."
	icon_state = "brutepack"
	lefthand_file = 'icons/mob/inhands/equipment/medical_lefthand.dmi'
	righthand_file = 'icons/mob/inhands/equipment/medical_righthand.dmi'
	heal_brute = 40
	self_delay = 4 SECONDS
	other_delay = 2 SECONDS
	grind_results = list(/datum/reagent/medicine/c2/libital = 10)
	merge_type = /obj/item/stack/medical/bruise_pack
	apply_verb = "applying to"

/obj/item/stack/medical/bruise_pack/suicide_act(mob/living/user)
	user.visible_message(span_suicide("[user] is bludgeoning [user.p_them()]self with [src]! It looks like [user.p_theyre()] trying to commit suicide!"))
	return BRUTELOSS

/obj/item/stack/medical/gauze
	name = "medical gauze"
	desc = "A roll of elastic cloth, perfect for stabilizing all kinds of wounds, from cuts and burns, to broken bones. "
	gender = PLURAL
	singular_name = "medical gauze"
	icon_state = "gauze"
	self_delay = 5 SECONDS
	other_delay = 2 SECONDS
	max_amount = 12
	amount = 6
	grind_results = list(/datum/reagent/cellulose = 2)
	custom_price = PAYCHECK_CREW * 2
	absorption_rate = 0.125
	absorption_capacity = 5
	splint_factor = 0.7
	burn_cleanliness_bonus = 0.35
	merge_type = /obj/item/stack/medical/gauze
	apply_verb = "wrapping"
	works_on_dead = TRUE
	var/obj/item/bodypart/gauzed_bodypart
	heal_end_sound = SFX_BANDAGE_END
	heal_begin_sound = SFX_BANDAGE_BEGIN
	drop_sound = SFX_CLOTH_DROP
	pickup_sound = SFX_CLOTH_PICKUP

/obj/item/stack/medical/gauze/Destroy(force)
	. = ..()

	if (gauzed_bodypart)
		gauzed_bodypart.current_gauze = null
		SEND_SIGNAL(gauzed_bodypart, COMSIG_BODYPART_UNGAUZED, src)
	gauzed_bodypart = null

/obj/item/stack/medical/gauze/add_item_context(obj/item/source, list/context, atom/target, mob/living/user)
	if(iscarbon(target))
		context[SCREENTIP_CONTEXT_LMB] = "Apply Gauze"
		return CONTEXTUAL_SCREENTIP_SET
	return NONE

/obj/item/stack/medical/gauze/try_heal_checks(mob/living/patient, mob/living/user, healed_zone, silent = FALSE)
	var/obj/item/bodypart/limb = patient.get_bodypart(healed_zone)
	if(isnull(limb))
		if(!silent)
			patient.balloon_alert(user, "no [parse_zone(healed_zone)]!")
		return FALSE
	if(!LAZYLEN(limb.wounds))
		if(!silent)
			patient.balloon_alert(user, "no wounds!") // good problem to have imo
		return FALSE
	if(limb.current_gauze && (limb.current_gauze.absorption_capacity * 1.2 > absorption_capacity)) // ignore if our new wrap is < 20% better than the current one, so someone doesn't bandage it 5 times in a row
		if(!silent)
			patient.balloon_alert(user, pick("already bandaged!", "bandage is clean!")) // good enough
		return FALSE
	for(var/datum/wound/woundies as anything in limb.wounds)
		if(woundies.wound_flags & ACCEPTS_GAUZE)
			return TRUE
	if(!silent)
		patient.balloon_alert(user, "can't gauze!")
	return FALSE

// gauze is only relevant for wounds, which are handled in the wounds themselves
/obj/item/stack/medical/gauze/try_heal(mob/living/patient, mob/living/user, healed_zone, silent, auto_change_zone)
	var/obj/item/bodypart/limb = patient.get_bodypart(healed_zone)
	var/treatment_delay = (user == patient ? self_delay : other_delay)
	var/any_scanned = FALSE
	for(var/datum/wound/woundies as anything in limb.wounds)
		if(HAS_TRAIT(woundies, TRAIT_WOUND_SCANNED))
			any_scanned = TRUE
			break

	if(any_scanned)
		treatment_delay *= 0.5
		if(user == patient)
			if(!silent)
				user.visible_message(
					span_warning("[user] begins expertly wrapping the wounds on [p_their()]'s [limb.plaintext_zone] with [src]..."),
					span_warning("You begin quickly wrapping the wounds on your [limb.plaintext_zone] with [src], keeping the holo-image indications in mind..."),
					visible_message_flags = ALWAYS_SHOW_SELF_MESSAGE,
				)
		else
			if(!silent)
				user.visible_message(
					span_warning("[user] begins expertly wrapping the wounds on [patient]'s [limb.plaintext_zone] with [src]..."),
					span_warning("You begin quickly wrapping the wounds on [patient]'s [limb.plaintext_zone] with [src], keeping the holo-image indications in mind..."),
					visible_message_flags = ALWAYS_SHOW_SELF_MESSAGE,
				)
	else
		if(!silent)
			user.visible_message(
				span_warning("[user] begins wrapping the wounds on [patient]'s [limb.plaintext_zone] with [src]..."),
				span_warning("You begin wrapping the wounds on [user == patient ? "your" : "[patient]'s"] [limb.plaintext_zone] with [src]..."),
				visible_message_flags = ALWAYS_SHOW_SELF_MESSAGE,
			)
	playsound(src, heal_begin_sound, 75, TRUE, MEDIUM_RANGE_SOUND_EXTRARANGE)

	if(!do_after(user, treatment_delay, target = patient))
		return

	if(!silent)
		patient.balloon_alert(user, "wrapped [parse_zone(healed_zone)]")
		user.visible_message(
			span_green("[user] applies [src] to [patient]'s [limb.plaintext_zone]."),
			span_green("You bandage the wounds on [user == patient ? "your" : "[patient]'s"] [limb.plaintext_zone]."),
			visible_message_flags = ALWAYS_SHOW_SELF_MESSAGE,
		)
		if(heal_end_sound)
			playsound(patient, heal_end_sound, 75, TRUE, MEDIUM_RANGE_SOUND_EXTRARANGE)
	limb.apply_gauze(src)

/obj/item/stack/medical/gauze/twelve
	amount = 12

/obj/item/stack/medical/gauze/attackby(obj/item/I, mob/user, params)
	if(I.tool_behaviour == TOOL_WIRECUTTER || I.get_sharpness())
		if(get_amount() < 2)
			balloon_alert(user, "not enough gauze!")
			return
		new /obj/item/stack/sheet/cloth(I.drop_location())
		if(user.CanReach(src))
			user.visible_message(span_notice("[user] cuts [src] into pieces of cloth with [I]."), \
				span_notice("You cut [src] into pieces of cloth with [I]."), \
				span_hear("You hear cutting."))
		else //telekinesis
			visible_message(span_notice("[I] cuts [src] into pieces of cloth."), \
				blind_message = span_hear("You hear cutting."))
		use(2)
	else
		return ..()

/obj/item/stack/medical/gauze/suicide_act(mob/living/user)
	user.visible_message(span_suicide("[user] begins tightening [src] around [user.p_their()] neck! It looks like [user.p_they()] forgot how to use medical supplies!"))
	return OXYLOSS

/obj/item/stack/medical/gauze/improvised
	name = "improvised gauze"
	singular_name = "improvised gauze"
	desc = "A roll of cloth roughly cut from something that does a decent job of stabilizing wounds, but less efficiently so than real medical gauze."
	icon_state = "gauze_imp"
	self_delay = 6 SECONDS
	other_delay = 3 SECONDS
	splint_factor = 0.85
	burn_cleanliness_bonus = 0.7
	absorption_rate = 0.075
	absorption_capacity = 4
	merge_type = /obj/item/stack/medical/gauze/improvised

	/*
	The idea is for the following medical devices to work like a hybrid of the old brute packs and tend wounds,
	they heal a little at a time, have reduced healing density and does not allow for rapid healing while in combat.
	However they provice graunular control of where the healing is directed, this makes them better for curing work-related cuts and scrapes.

	The interesting limb targeting mechanic is retained and i still believe they will be a viable choice, especially when healing others in the field.
	 */

/obj/item/stack/medical/suture
	name = "suture"
	desc = "Basic sterile sutures used to seal up cuts and lacerations and stop bleeding."
	gender = PLURAL
	singular_name = "suture"
	icon_state = "suture"
	self_delay = 3 SECONDS
	other_delay = 1 SECONDS
	amount = 10
	max_amount = 10
	repeating = TRUE
	heal_brute = 10
	stop_bleeding = 0.6
	grind_results = list(/datum/reagent/medicine/spaceacillin = 2)
	merge_type = /obj/item/stack/medical/suture
	apply_verb = "suturing"
	drop_sound = SFX_SUTURE_DROP
	pickup_sound = SFX_SUTURE_PICKUP
	heal_begin_sound = SFX_SUTURE_BEGIN
	heal_continuous_sound = SFX_SUTURE_CONTINUOUS
	heal_end_sound = SFX_SUTURE_END

/obj/item/stack/medical/suture/emergency
	name = "emergency suture"
	desc = "A value pack of cheap sutures, not very good at repairing damage, but still decent at stopping bleeding."
	heal_brute = 5
	amount = 5
	max_amount = 5
	merge_type = /obj/item/stack/medical/suture/emergency

/obj/item/stack/medical/suture/medicated
	name = "medicated suture"
	icon_state = "suture_purp"
	desc = "A suture infused with drugs that speed up wound healing of the treated laceration."
	heal_brute = 15
	stop_bleeding = 0.75
	grind_results = list(/datum/reagent/medicine/polypyr = 1)
	merge_type = /obj/item/stack/medical/suture/medicated

/obj/item/stack/medical/ointment
	name = "ointment"
	desc = "Basic burn ointment, rated effective for second degree burns with proper bandaging, though it's still an effective stabilizer for worse burns. Not terribly good at outright healing burns though."
	gender = PLURAL
	singular_name = "ointment"
	icon_state = "ointment"
	lefthand_file = 'icons/mob/inhands/equipment/medical_lefthand.dmi'
	righthand_file = 'icons/mob/inhands/equipment/medical_righthand.dmi'
	amount = 8
	max_amount = 8
	self_delay = 4 SECONDS
	other_delay = 2 SECONDS

	heal_burn = 5
	flesh_regeneration = 2.5
	sanitization = 0.25
	grind_results = list(/datum/reagent/medicine/c2/lenturi = 10)
	merge_type = /obj/item/stack/medical/ointment
	apply_verb = "applying to"

/obj/item/stack/medical/ointment/suicide_act(mob/living/user)
	user.visible_message(span_suicide("[user] is squeezing [src] into [user.p_their()] mouth! [user.p_do(TRUE)]n't [user.p_they()] know that stuff is toxic?"))
	return TOXLOSS

/obj/item/stack/medical/mesh
	name = "regenerative mesh"
	desc = "A bacteriostatic mesh used to dress burns."
	gender = PLURAL
	singular_name = "mesh piece"
	icon_state = "regen_mesh"
	self_delay = 3 SECONDS
	other_delay = 1 SECONDS
	amount = 15
	heal_burn = 10
	max_amount = 15
	repeating = TRUE
	sanitization = 0.75
	flesh_regeneration = 3
	pickup_sound = SFX_CLOTH_PICKUP
	drop_sound = SFX_CLOTH_DROP

	var/is_open = TRUE ///This var determines if the sterile packaging of the mesh has been opened.
	grind_results = list(/datum/reagent/medicine/spaceacillin = 2)
	merge_type = /obj/item/stack/medical/mesh

/obj/item/stack/medical/mesh/Initialize(mapload, new_amount, merge = TRUE, list/mat_override=null, mat_amt=1)
	. = ..()
	if(amount == max_amount)  //only seal full mesh packs
		is_open = FALSE
		update_appearance()

/obj/item/stack/medical/mesh/update_icon_state()
	if(is_open)
		return ..()
	icon_state = "regen_mesh_closed"

/obj/item/stack/medical/mesh/try_heal_checks(mob/living/patient, mob/living/user, healed_zone, silent = FALSE)
	if(!is_open)
		if(!silent)
			balloon_alert(user, "open it first!")
		return FALSE
	return ..()

/obj/item/stack/medical/mesh/click_alt(mob/living/user)
	if(!is_open)
		balloon_alert(user, "open it first!")
		return CLICK_ACTION_BLOCKING
	return CLICK_ACTION_SUCCESS

/obj/item/stack/medical/mesh/attack_hand(mob/user, list/modifiers)
	if(!is_open && user.get_inactive_held_item() == src)
		balloon_alert(user, "open it first!")
		return
	return ..()

/obj/item/stack/medical/mesh/attack_self(mob/user)
	if(!is_open)
		is_open = TRUE
		balloon_alert(user, "opened")
		update_appearance()
		playsound(src, 'sound/items/poster/poster_ripped.ogg', 20, TRUE)
		return
	return ..()

/obj/item/stack/medical/mesh/advanced
	name = "advanced regenerative mesh"
	desc = "An advanced mesh made with aloe extracts and sterilizing chemicals, used to treat burns."

	gender = PLURAL
	icon_state = "aloe_mesh"
	heal_burn = 15
	sanitization = 1.25
	flesh_regeneration = 3.5
	grind_results = list(/datum/reagent/consumable/aloejuice = 1)
	merge_type = /obj/item/stack/medical/mesh/advanced

/obj/item/stack/medical/mesh/advanced/update_icon_state()
	if(is_open)
		return ..()
	icon_state = "aloe_mesh_closed"

/obj/item/stack/medical/aloe
	name = "aloe cream"
	desc = "A healing paste for minor cuts and burns."

	gender = PLURAL
	singular_name = "aloe cream"
	icon_state = "aloe_paste"
	self_delay = 2 SECONDS
	other_delay = 1 SECONDS
	novariants = TRUE
	amount = 20
	max_amount = 20
	repeating = TRUE
	heal_brute = 3
	heal_burn = 3
	grind_results = list(/datum/reagent/consumable/aloejuice = 1)
	merge_type = /obj/item/stack/medical/aloe
	apply_verb = "applying to"

/obj/item/stack/medical/aloe/Initialize(mapload, new_amount, merge, list/mat_override, mat_amt)
	. = ..()
	AddComponent(/datum/component/bakeable, /obj/item/food/badrecipe, rand(10 SECONDS, 15 SECONDS), FALSE)

/obj/item/stack/medical/aloe/fresh
	amount = 2

/obj/item/stack/medical/bone_gel
	name = "bone gel"
	singular_name = "bone gel"
	desc = "A potent medical gel that, when applied to a damaged bone in a proper surgical setting, triggers an intense melding reaction to repair the wound. Can be directly applied alongside surgical sticky tape to a broken bone in dire circumstances, though this is very harmful to the patient and not recommended."

	icon = 'icons/obj/medical/surgery_tools.dmi'
	icon_state = "bone-gel"
	inhand_icon_state = "bone-gel"
	lefthand_file = 'icons/mob/inhands/equipment/medical_lefthand.dmi'
	righthand_file = 'icons/mob/inhands/equipment/medical_righthand.dmi'

	amount = 5
	self_delay = 20
	grind_results = list(/datum/reagent/bone_dust = 10, /datum/reagent/carbon = 10)
	novariants = TRUE
	merge_type = /obj/item/stack/medical/bone_gel
	apply_verb = "applying to"

/obj/item/stack/medical/bone_gel/get_surgery_tool_overlay(tray_extended)
	return "gel" + (tray_extended ? "" : "_out")

/obj/item/stack/medical/bone_gel/attack(mob/living/patient, mob/user)
	patient.balloon_alert(user, "no fractures!")
	return

/obj/item/stack/medical/bone_gel/suicide_act(mob/living/user)
	if(!iscarbon(user))
		return
	var/mob/living/carbon/patient = user
	patient.visible_message(span_suicide("[patient] is squirting all of [src] into [patient.p_their()] mouth! That's not proper procedure! It looks like [patient.p_theyre()] trying to commit suicide!"))
	if(!do_after(patient, 2 SECONDS))
		patient.visible_message(span_suicide("[patient] screws up like an idiot and still dies anyway!"))
		return BRUTELOSS

	patient.emote("scream")
	for(var/obj/item/bodypart/bone as anything in patient.bodyparts)
		// fine to just, use these raw, its a meme anyway
		var/datum/wound/blunt/bone/severe/oof_ouch = new
		oof_ouch.apply_wound(bone, wound_source = "bone gel")
		var/datum/wound/blunt/bone/critical/oof_OUCH = new
		oof_OUCH.apply_wound(bone, wound_source = "bone gel")
	for(var/zone in GLOB.all_body_zones)
		patient.apply_damage(60, BRUTE, zone)
	use(1)
	return BRUTELOSS

/obj/item/stack/medical/bone_gel/one
	amount = 1

/obj/item/stack/medical/poultice
	name = "mourning poultices"
	singular_name = "mourning poultice"
	desc = "A type of primitive herbal poultice.\n\
		While traditionally used to prepare corpses for the mourning feast, \
		it can also treat scrapes and burns on the living, however, \
		it is liable to cause shortness of breath when employed in this manner.\n\
		It is imbued with ancient wisdom."
	icon_state = "poultice"
	amount = 15
	max_amount = 15
	heal_brute = 10
	heal_burn = 10
	self_delay = 40
	other_delay = 10
	repeating = TRUE
	drop_sound = 'sound/misc/moist_impact.ogg'
	mob_throw_hit_sound = 'sound/misc/moist_impact.ogg'
	hitsound = 'sound/misc/moist_impact.ogg'
	merge_type = /obj/item/stack/medical/poultice
	apply_verb = "applying to"
	works_on_dead = TRUE

/obj/item/stack/medical/poultice/post_heal_effects(amount_healed, mob/living/carbon/healed_mob, mob/living/user)
	. = ..()
	playsound(src, 'sound/misc/soggy.ogg', 30, TRUE)
	healed_mob.adjustOxyLoss(amount_healed)

/obj/item/stack/medical/bandage
	name = "first aid bandage"
	desc = "A DeForest brand bandage designed for basic first aid on blunt-force trauma."
	icon_state = "bandage"
	inhand_icon_state = "bandage"
	novariants = TRUE
	amount = 1
	max_amount = 1
	lefthand_file = 'icons/mob/inhands/equipment/medical_lefthand.dmi'
	righthand_file = 'icons/mob/inhands/equipment/medical_righthand.dmi'
	heal_brute = 25
	stop_bleeding = 0.2
	self_delay = 3 SECONDS
	other_delay = 1 SECONDS
	grind_results = list(/datum/reagent/medicine/c2/libital = 2)
	apply_verb = "applying to"
	pickup_sound = SFX_CLOTH_PICKUP
	// add a better drop sound more fitting for a lil' itty bitty band-aid

/obj/item/stack/medical/bandage/makeshift
	name = "makeshift bandage"
	desc = "A hastily constructed bandage designed for basic first aid on blunt-force trauma."
	icon_state = "bandage_makeshift"
	icon_state_preview = "bandage_makeshift"
	inhand_icon_state = "bandage"
	novariants = TRUE
