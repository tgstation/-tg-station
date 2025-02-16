/obj/item/organ/ears
	name = "ears"
	icon_state = "ears"
	desc = "There are three parts to the ear. Inner, middle and outer. Only one of these parts should be normally visible."
	zone = BODY_ZONE_HEAD
	slot = ORGAN_SLOT_EARS
	gender = PLURAL

	healing_factor = STANDARD_ORGAN_HEALING
	decay_factor = STANDARD_ORGAN_DECAY

	low_threshold_passed = span_info("Your ears begin to resonate with an internal ring sometimes.")
	now_failing = span_warning("You are unable to hear at all!")
	now_fixed = span_info("Noise slowly begins filling your ears once more.")
	low_threshold_cleared = span_info("The ringing in your ears has died down.")

	/// `deaf` measures "ticks" of deafness. While > 0, the person is unable to hear anything.
	var/deaf = 0

	// `damage` in this case measures long term damage to the ears, if too high,
	// the person will not have either `deaf` or `ear_damage` decrease
	// without external aid (earmuffs, drugs)

	/// Resistance against loud noises
	var/bang_protect = 0
	/// Multiplier for both long term and short term ear damage
	var/damage_multiplier = 1

/obj/item/organ/ears/on_life(seconds_per_tick, times_fired)
	// only inform when things got worse, needs to happen before we heal
	if((damage > low_threshold && prev_damage < low_threshold) || (damage > high_threshold && prev_damage < high_threshold))
		to_chat(owner, span_warning("The ringing in your ears grows louder, blocking out any external noises for a moment."))

	. = ..()
	// if we have non-damage related deafness like mutations, quirks or clothing (earmuffs), don't bother processing here.
	// Ear healing from earmuffs or chems happen elsewhere
	if(HAS_TRAIT_NOT_FROM(owner, TRAIT_DEAF, EAR_DAMAGE))
		return
	// no healing if failing
	if(organ_flags & ORGAN_FAILING)
		return
	adjustEarDamage(0, -0.5 * seconds_per_tick)
	if((damage > low_threshold) && SPT_PROB(damage / 60, seconds_per_tick))
		adjustEarDamage(0, 4)
		SEND_SOUND(owner, sound('sound/items/weapons/flash_ring.ogg'))

/obj/item/organ/ears/apply_organ_damage(damage_amount, maximum, required_organ_flag)
	. = ..()
	update_temp_deafness()

/obj/item/organ/ears/on_mob_insert(mob/living/carbon/organ_owner, special, movement_flags)
	. = ..()
	update_temp_deafness()

/obj/item/organ/ears/on_mob_remove(mob/living/carbon/organ_owner, special, movement_flags)
	. = ..()
	UnregisterSignal(organ_owner, COMSIG_MOB_SAY)
	REMOVE_TRAIT(organ_owner, TRAIT_DEAF, EAR_DAMAGE)

/obj/item/organ/ears/get_status_appendix(advanced, add_tooltips)
	if(owner.stat == DEAD || !HAS_TRAIT(owner, TRAIT_DEAF))
		return
	if(advanced)
		if(HAS_TRAIT_FROM(owner, TRAIT_DEAF, QUIRK_TRAIT))
			return conditional_tooltip("Subject is permanently deaf.", "Irreparable under normal circumstances.", add_tooltips)
		if(HAS_TRAIT_FROM(owner, TRAIT_DEAF, GENETIC_MUTATION))
			return conditional_tooltip("Subject is genetically deaf.", "Use medication such as [/datum/reagent/medicine/mutadone::name].", add_tooltips)
		if(HAS_TRAIT_FROM(owner, TRAIT_DEAF, EAR_DAMAGE))
			return conditional_tooltip("Subject is [(organ_flags & ORGAN_FAILING) ? "permanently": "temporarily"] deaf from ear damage.", "Repair surgically, use medication such as [/datum/reagent/medicine/inacusiate::name], or protect ears with earmuffs.", add_tooltips)
	return "Subject is deaf."

/obj/item/organ/ears/show_on_condensed_scans()
	// Always show if we have an appendix
	return ..() || (owner.stat != DEAD && HAS_TRAIT(owner, TRAIT_DEAF))

/**
 * Snowflake proc to handle temporary deafness
 *
 * * ddmg: Handles normal organ damage
 * * ddeaf: Handles temporary deafness, 1 ddeaf = 2 seconds of deafness, by default (with no multiplier)
 */
/obj/item/organ/ears/proc/adjustEarDamage(ddmg = 0, ddeaf = 0)
	if(HAS_TRAIT(owner, TRAIT_GODMODE))
		update_temp_deafness()
		return

	var/mod_damage = ddmg > 0 ? (ddmg * damage_multiplier) : ddmg
	if(mod_damage)
		apply_organ_damage(mod_damage)
	var/mod_deaf = ddeaf > 0 ? (ddeaf * damage_multiplier) : ddeaf
	if(mod_deaf)
		deaf = max(deaf + mod_deaf, 0)
	update_temp_deafness()

/// Updates status of deafness
/obj/item/organ/ears/proc/update_temp_deafness()
	// if we're failing we always have at least some deaf stacks (and thus deafness)
	if(organ_flags & ORGAN_FAILING)
		deaf = max(deaf, 1 * damage_multiplier)

	if(isnull(owner))
		return

	if(HAS_TRAIT(owner, TRAIT_GODMODE))
		deaf = 0

	if(deaf > 0)
		if(!HAS_TRAIT_FROM(owner, TRAIT_DEAF, EAR_DAMAGE))
			RegisterSignal(owner, COMSIG_MOB_SAY, PROC_REF(adjust_speech))
			ADD_TRAIT(owner, TRAIT_DEAF, EAR_DAMAGE)
	else
		REMOVE_TRAIT(owner, TRAIT_DEAF, EAR_DAMAGE)
		UnregisterSignal(owner, COMSIG_MOB_SAY)

/// Being deafened by loud noises makes you shout
/obj/item/organ/ears/proc/adjust_speech(datum/source, list/speech_args)
	SIGNAL_HANDLER

	if(HAS_TRAIT_NOT_FROM(source, TRAIT_DEAF, EAR_DAMAGE))
		return
	if(HAS_TRAIT(source, TRAIT_SIGN_LANG))
		return

	var/message = speech_args[SPEECH_MESSAGE]
	// Replace only end-of-sentence punctuation with exclamation marks (hence the empty space)
	// We don't wanna mess with things like ellipses
	message = replacetext(message, ". ", "! ")
	message = replacetext(message, "? ", "?! ")
	// Special case for the last character
	switch(copytext_char(message, -1))
		if(".")
			if(copytext_char(message, -2) != "..") // Once again ignoring ellipses, let people trail off
				message = copytext_char(message, 1, -1) + "!"
		if("?")
			message = copytext_char(message, 1, -1) + "?!"
		if("!")
			pass()
		else
			message += "!"

	speech_args[SPEECH_MESSAGE] = message
	return COMPONENT_UPPERCASE_SPEECH

/obj/item/organ/ears/invincible
	damage_multiplier = 0


/obj/item/organ/ears/cat
	name = "cat ears"
	icon = 'icons/obj/clothing/head/costume.dmi'
	worn_icon = 'icons/mob/clothing/head/costume.dmi'
	icon_state = "kitty"
	visual = TRUE
	damage_multiplier = 2

	preference = "feature_human_ears"
	restyle_flags = EXTERNAL_RESTYLE_FLESH

	dna_block = DNA_EARS_BLOCK

	bodypart_overlay = /datum/bodypart_overlay/mutant/cat_ears

/// Bodypart overlay for the horrible cat ears
/datum/bodypart_overlay/mutant/cat_ears
	layers = EXTERNAL_FRONT | EXTERNAL_BEHIND
	color_source = ORGAN_COLOR_HAIR
	feature_key = "ears"
	dyable = TRUE

	/// Layer upon which we add the inner ears overlay
	var/inner_layer = EXTERNAL_FRONT

/datum/bodypart_overlay/mutant/cat_ears/get_global_feature_list()
	return SSaccessories.ears_list

/datum/bodypart_overlay/mutant/cat_ears/can_draw_on_bodypart(mob/living/carbon/human/human)
	if((human.head?.flags_inv & HIDEHAIR) || (human.wear_mask?.flags_inv & HIDEHAIR))
		return FALSE
	return TRUE

/datum/bodypart_overlay/mutant/cat_ears/get_image(image_layer, obj/item/bodypart/limb)
	var/mutable_appearance/base_ears = ..()

	// Only add inner ears on the inner layer
	if(image_layer != bitflag_to_layer(inner_layer))
		return base_ears

	// Construct image of inner ears, apply to base ears as an overlay
	feature_key += "inner"
	var/mutable_appearance/inner_ears = ..()
	inner_ears.appearance_flags = RESET_COLOR
	feature_key = initial(feature_key)

	base_ears.overlays += inner_ears
	return base_ears

/obj/item/organ/ears/penguin
	name = "penguin ears"
	desc = "The source of a penguin's happy feet."

/obj/item/organ/ears/penguin/on_mob_insert(mob/living/carbon/human/ear_owner)
	. = ..()
	to_chat(ear_owner, span_notice("You suddenly feel like you've lost your balance."))
	ear_owner.AddElementTrait(TRAIT_WADDLING, ORGAN_TRAIT, /datum/element/waddling)

/obj/item/organ/ears/penguin/on_mob_remove(mob/living/carbon/human/ear_owner)
	. = ..()
	to_chat(ear_owner, span_notice("Your sense of balance comes back to you."))
	REMOVE_TRAIT(ear_owner, TRAIT_WADDLING, ORGAN_TRAIT)

/obj/item/organ/ears/cybernetic
	name = "basic cybernetic ears"
	icon_state = "ears-c"
	desc = "A basic cybernetic organ designed to mimic the operation of ears."
	damage_multiplier = 0.9
	organ_flags = ORGAN_ROBOTIC
	failing_desc = "seems to be broken."

/obj/item/organ/ears/cybernetic/upgraded
	name = "cybernetic ears"
	icon_state = "ears-c-u"
	desc =  "An advanced cybernetic ear, surpassing the performance of organic ears."
	damage_multiplier = 0.5

/obj/item/organ/ears/cybernetic/whisper
	name = "whisper-sensitive cybernetic ears"
	icon_state = "ears-c-u"
	desc = "Allows the user to more easily hear whispers. The user becomes extra vulnerable to loud noises, however"
	// Same sensitivity as felinid ears
	damage_multiplier = 2

// The original idea was to use signals to do this not traits. Unfortunately, the star effect used for whispers applies before any relevant signals
// This seems like the least invasive solution
/obj/item/organ/ears/cybernetic/whisper/on_mob_insert(mob/living/carbon/ear_owner)
	. = ..()
	ADD_TRAIT(ear_owner, TRAIT_GOOD_HEARING, ORGAN_TRAIT)

/obj/item/organ/ears/cybernetic/whisper/on_mob_remove(mob/living/carbon/ear_owner)
	. = ..()
	REMOVE_TRAIT(ear_owner, TRAIT_GOOD_HEARING, ORGAN_TRAIT)

// "X-ray ears" that let you hear through walls
/obj/item/organ/ears/cybernetic/xray
	name = "wall-penetrating cybernetic ears"
	icon_state = "ears-c-u"
	desc = "Through the power of modern engineering, allows the user to hear speech through walls. The user becomes extra vulnerable to loud noises, however"
	// Same sensitivity as felinid ears
	damage_multiplier = 2

/obj/item/organ/ears/cybernetic/xray/on_mob_insert(mob/living/carbon/ear_owner)
	. = ..()
	ADD_TRAIT(ear_owner, TRAIT_XRAY_HEARING, ORGAN_TRAIT)

/obj/item/organ/ears/cybernetic/xray/on_mob_remove(mob/living/carbon/ear_owner)
	. = ..()
	REMOVE_TRAIT(ear_owner, TRAIT_XRAY_HEARING, ORGAN_TRAIT)

/obj/item/organ/ears/cybernetic/emp_act(severity)
	. = ..()
	if(. & EMP_PROTECT_SELF)
		return
	apply_organ_damage(20 / severity)

/obj/item/organ/ears/pod
	name = "pod ears"
	desc = "Strangest salad you've ever seen."
	foodtype_flags = PODPERSON_ORGAN_FOODTYPES
	color = COLOR_LIME
