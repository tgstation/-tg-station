/obj/item/organ/heart
	name = "heart"
	desc = "I feel bad for the heartless bastard who lost this."
	icon_state = "heart-on"
	base_icon_state = "heart"

	zone = BODY_ZONE_CHEST
	slot = ORGAN_SLOT_HEART
	item_flags = NO_BLOOD_ON_ITEM
	healing_factor = STANDARD_ORGAN_HEALING
	decay_factor = 2.5 * STANDARD_ORGAN_DECAY //designed to fail around 6 minutes after death

	low_threshold_passed = span_info("Prickles of pain appear then die out from within your chest...")
	high_threshold_passed = span_warning("Something inside your chest hurts, and the pain isn't subsiding. You notice yourself breathing far faster than before.")
	now_fixed = span_info("Your heart begins to beat again.")
	high_threshold_cleared = span_info("The pain in your chest has died down, and your breathing becomes more relaxed.")

	attack_verb_continuous = list("beats", "thumps")
	attack_verb_simple = list("beat", "thump")

	// Love is stored in the heart.
	food_reagents = list(/datum/reagent/consumable/nutriment/organ_tissue = 5, /datum/reagent/love = 2.5)

	// Heart attack code is in code/modules/mob/living/carbon/human/life.dm

	/// Whether the heart is currently beating.
	/// Do not set this directly. Use Restart() and Stop() instead.
	VAR_PRIVATE/beating = TRUE

	/// is this mob having a heatbeat sound played? if so, which?
	var/beat = BEAT_NONE
	/// whether the heart's been operated on to fix some of its damages
	var/operated = FALSE

/obj/item/organ/heart/update_icon_state()
	. = ..()
	icon_state = "[base_icon_state]-[beating ? "on" : "off"]"

/obj/item/organ/heart/Remove(mob/living/carbon/heartless, special, movement_flags)
	. = ..()
	if(!special)
		addtimer(CALLBACK(src, PROC_REF(stop_if_unowned)), 12 SECONDS)
	beat = BEAT_NONE
	owner?.stop_sound_channel(CHANNEL_HEARTBEAT)

/obj/item/organ/heart/proc/stop_if_unowned()
	if(QDELETED(src))
		return
	if(IS_ROBOTIC_ORGAN(src))
		return
	if(isnull(owner))
		Stop()

/obj/item/organ/heart/attack_self(mob/user)
	. = ..()
	if(.)
		return

	if(!beating)
		user.visible_message(
			span_notice("[user] squeezes [src] to make it beat again!"),
			span_notice("You squeeze [src] to make it beat again!"),
		)
		Restart()
		addtimer(CALLBACK(src, PROC_REF(stop_if_unowned)), 8 SECONDS)
		return TRUE

/obj/item/organ/heart/proc/Stop()
	if(!beating)
		return FALSE

	beating = FALSE
	update_appearance()
	beat = BEAT_NONE
	owner?.stop_sound_channel(CHANNEL_HEARTBEAT)
	return TRUE

/obj/item/organ/heart/proc/Restart()
	if(beating)
		return FALSE

	beating = TRUE
	update_appearance()
	return TRUE

/obj/item/organ/heart/OnEatFrom(eater, feeder)
	. = ..()
	Stop()

/// Checks if the heart is beating.
/// Can be overridden to add more conditions for more complex hearts.
/obj/item/organ/heart/proc/is_beating()
	return beating

/obj/item/organ/heart/get_status_text(advanced, add_tooltips)
	if(!beating && !(organ_flags & ORGAN_FAILING) && owner.needs_heart() && owner.stat != DEAD)
		return conditional_tooltip("<font color='#cc3333'>Cardiac Arrest</font>", "Apply defibrillation immediately. Similar electric shocks may work in emergencies.", add_tooltips)
	return ..()

/obj/item/organ/heart/show_on_condensed_scans()
	// Always show if the guy needs a heart (so its status can be monitored)
	return ..() || owner.needs_heart()

/obj/item/organ/heart/on_life(seconds_per_tick, times_fired)
	..()

	// If the owner doesn't need a heart, we don't need to do anything with it.
	if(!owner.needs_heart())
		return

	// Handle "sudden" heart attack
	if(!beating || (organ_flags & ORGAN_FAILING))
		if(owner.can_heartattack() && Stop())
			if(owner.stat == CONSCIOUS)
				owner.visible_message(span_danger("[owner] clutches at [owner.p_their()] chest as if [owner.p_their()] heart is stopping!"))
			to_chat(owner, span_userdanger("You feel a terrible pain in your chest, as if your heart has stopped!"))
		return

	// Beyond deals with sound effects, so nothing needs to be done if no client
	if(isnull(owner.client))
		return

	if(owner.stat == SOFT_CRIT)
		if(beat != BEAT_SLOW)
			beat = BEAT_SLOW
			to_chat(owner, span_notice("You feel your heart slow down..."))
			SEND_SOUND(owner, sound('sound/effects/health/slowbeat.ogg', repeat = TRUE, channel = CHANNEL_HEARTBEAT, volume = 40))

	else if(owner.stat == HARD_CRIT)
		if(beat != BEAT_FAST && owner.has_status_effect(/datum/status_effect/jitter))
			SEND_SOUND(owner, sound('sound/effects/health/fastbeat.ogg', repeat = TRUE, channel = CHANNEL_HEARTBEAT, volume = 40))
			beat = BEAT_FAST

	else if(beat != BEAT_NONE)
		owner.stop_sound_channel(CHANNEL_HEARTBEAT)
		beat = BEAT_NONE

/obj/item/organ/heart/get_availability(datum/species/owner_species, mob/living/owner_mob)
	return owner_species.mutantheart

/obj/item/organ/heart/cursed
	name = "cursed heart"
	desc = "A heart that, when inserted, will force you to pump it manually."
	icon_state = "cursedheart-off"
	base_icon_state = "cursedheart"
	decay_factor = 0
	var/pump_delay = 3 SECONDS
	var/blood_loss = BLOOD_VOLUME_NORMAL * 0.2
	var/heal_brute = 0
	var/heal_burn = 0
	var/heal_oxy = 0

/obj/item/organ/heart/cursed/attack(mob/living/carbon/human/accursed, mob/living/carbon/human/user, obj/target)
	if(accursed == user && istype(accursed))
		playsound(user,'sound/effects/singlebeat.ogg',40,TRUE)
		user.temporarilyRemoveItemFromInventory(src, TRUE)
		Insert(user)
	else
		return ..()

/obj/item/organ/heart/cursed/on_mob_insert(mob/living/carbon/accursed)
	. = ..()

	accursed.AddComponent(/datum/component/manual_heart, pump_delay = pump_delay, blood_loss = blood_loss, heal_brute = heal_brute, heal_burn = heal_burn, heal_oxy = heal_oxy)

/obj/item/organ/heart/cursed/on_mob_remove(mob/living/carbon/accursed, special = FALSE, movement_flags)
	. = ..()

	qdel(accursed.GetComponent(/datum/component/manual_heart))

/obj/item/organ/heart/cybernetic
	name = "basic cybernetic heart"
	desc = "A basic electronic device designed to mimic the functions of an organic human heart."
	icon_state = "heart-c-on"
	base_icon_state = "heart-c"
	organ_flags = ORGAN_ROBOTIC
	maxHealth = STANDARD_ORGAN_THRESHOLD * 0.75 //This also hits defib timer, so a bit higher than its less important counterparts
	failing_desc = "seems to be broken."

	/// Whether or not we have a stabilization available. This prevents our owner from entering softcrit for an amount of time.
	var/stabilization_available = FALSE

	/// How long our stabilization lasts for.
	var/stabilization_duration = 10 SECONDS

	/// Whether our heart suppresses bleeders and restores blood automatically.
	var/bleed_prevention = FALSE

	/// The probability that our blood replication causes toxin damage.
	var/toxification_probability = 20

	/// Chance of permanent effects if emp-ed.
	var/emp_vulnerability = 80

/obj/item/organ/heart/cybernetic/emp_act(severity)
	. = ..()
	if(. & EMP_PROTECT_SELF)
		return
	// Some effects are byassed if our owner (should it exist) doesn't need a heart
	var/owner_needs_us = owner?.needs_heart()

	if(owner_needs_us && !COOLDOWN_FINISHED(src, severe_cooldown)) //So we cant just spam emp to kill people.
		owner.set_dizzy_if_lower(20 SECONDS)
		owner.losebreath += 10
		COOLDOWN_START(src, severe_cooldown, 20 SECONDS)

	if(prob(emp_vulnerability/severity)) //Chance of permanent effects
		organ_flags |= ORGAN_EMP //Starts organ faliure - gonna need replacing soon.
		Stop()
		addtimer(CALLBACK(src, PROC_REF(Restart)), 10 SECONDS)
		if(owner_needs_us)
			owner.visible_message(
				span_danger("[owner] clutches at [owner.p_their()] chest as if [owner.p_their()] heart is stopping!"),
				span_userdanger("You feel a terrible pain in your chest, as if your heart has stopped!"),
			)

/obj/item/organ/heart/cybernetic/on_life(seconds_per_tick, times_fired)
	. = ..()

	if(organ_flags & ORGAN_EMP)
		return

	if(stabilization_available && owner.health <= owner.crit_threshold)
		stabilize_heart()

	if(bleed_prevention && ishuman(owner) && owner.blood_volume < BLOOD_VOLUME_NORMAL)
		var/mob/living/carbon/human/wounded_owner = owner
		wounded_owner.blood_volume += 2 * seconds_per_tick
		if(toxification_probability && prob(toxification_probability))
			wounded_owner.adjustToxLoss(1 * seconds_per_tick, updating_health = FALSE)

		var/datum/wound/bloodiest_wound

		for(var/datum/wound/iter_wound as anything in wounded_owner.all_wounds)
			if(iter_wound.blood_flow && iter_wound.blood_flow > bloodiest_wound?.blood_flow)
				bloodiest_wound = iter_wound

		if(bloodiest_wound)
			bloodiest_wound.adjust_blood_flow(-1 * seconds_per_tick)

/obj/item/organ/heart/cybernetic/proc/stabilize_heart()
	ADD_TRAIT(owner, TRAIT_NOSOFTCRIT, ORGAN_TRAIT)
	stabilization_available = FALSE

	addtimer(TRAIT_CALLBACK_REMOVE(owner, TRAIT_NOSOFTCRIT, ORGAN_TRAIT), stabilization_duration)

	addtimer(VARSET_CALLBACK(src, stabilization_available, TRUE), 5 MINUTES, TIMER_DELETE_ME)

// Largely a sanity check
/obj/item/organ/heart/cybernetic/on_mob_remove(mob/living/carbon/heart_owner, special = FALSE, movement_flags)
	. = ..()
	if(HAS_TRAIT_FROM(heart_owner, TRAIT_NOSOFTCRIT, ORGAN_TRAIT))
		REMOVE_TRAIT(heart_owner, TRAIT_NOSOFTCRIT, ORGAN_TRAIT)

/obj/item/organ/heart/cybernetic/tier2
	name = "cybernetic heart"
	desc = "An electronic device designed to mimic the functions of an organic human heart. In case of lacerations or haemorrhaging, the heart rapidly begins self-replicating \
		artificial blood. However, this can cause toxins to build up in the bloodstream to the imperfect replication process."
	icon_state = "heart-c-u-on"
	base_icon_state = "heart-c-u"
	maxHealth = 1.5 * STANDARD_ORGAN_THRESHOLD
	bleed_prevention = TRUE
	emp_vulnerability = 40

/obj/item/organ/heart/cybernetic/tier3
	name = "upgraded cybernetic heart"
	desc = "An electronic device designed to mimic the functions of an organic human heart. In case of physical trauma, the heart has temporary failsafes to maintain patient stability \
		and mobility for a brief moment. In addition, the heart is able to safely self-replicate blood without risk of toxin buildup."
	icon_state = "heart-c-u2-on"
	base_icon_state = "heart-c-u2"
	maxHealth = 2 * STANDARD_ORGAN_THRESHOLD
	stabilization_available = TRUE
	toxification_probability = 0
	emp_vulnerability = 20

/obj/item/organ/heart/cybernetic/surplus
	name = "surplus prosthetic heart"
	desc = "A fragile mockery of a human heart that resembles a water pump more than an actual heart. \
		Offers no protection against EMPs."
	icon_state = "heart-c-s-on"
	base_icon_state = "heart-c-s"
	maxHealth = STANDARD_ORGAN_THRESHOLD*0.5
	emp_vulnerability = 100

//surplus organs are so awful that they explode when removed, unless failing
/obj/item/organ/heart/cybernetic/surplus/Initialize(mapload)
	. = ..()
	AddElement(/datum/element/dangerous_organ_removal, /*surgical = */ TRUE)

/obj/item/organ/heart/freedom
	name = "heart of freedom"
	desc = "This heart pumps with the passion to give... something freedom."
	organ_flags = ORGAN_ROBOTIC  //the power of freedom prevents heart attacks
	/// The cooldown until the next time this heart can give the host an adrenaline boost.
	COOLDOWN_DECLARE(adrenaline_cooldown)

/obj/item/organ/heart/freedom/on_life(seconds_per_tick, times_fired)
	. = ..()
	if(owner.health < 5 && COOLDOWN_FINISHED(src, adrenaline_cooldown))
		COOLDOWN_START(src, adrenaline_cooldown, rand(25 SECONDS, 1 MINUTES))
		to_chat(owner, span_userdanger("You feel yourself dying, but you refuse to give up!"))
		owner.heal_overall_damage(brute = 15, burn = 15, required_bodytype = BODYTYPE_ORGANIC)
		if(owner.reagents.get_reagent_amount(/datum/reagent/medicine/ephedrine) < 20)
			owner.reagents.add_reagent(/datum/reagent/medicine/ephedrine, 10)

/obj/item/organ/heart/pod
	name = "pod mitochondria"
	desc = "This plant-like organ is the powerhouse of the podperson." // deliberate wording here
	foodtype_flags = PODPERSON_ORGAN_FOODTYPES
	color = COLOR_LIME
