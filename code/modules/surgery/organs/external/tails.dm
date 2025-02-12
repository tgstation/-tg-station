///Tail parent, it doesn't do very much.
/obj/item/organ/tail
	name = "tail"
	desc = "A severed tail. What did you cut this off of?"
	icon_state = "severedtail"

	zone = BODY_ZONE_PRECISE_GROIN
	slot = ORGAN_SLOT_EXTERNAL_TAIL

	dna_block = DNA_TAIL_BLOCK
	restyle_flags = EXTERNAL_RESTYLE_FLESH

	// defaults to cat, but the parent type shouldn't be created regardless
	bodypart_overlay = /datum/bodypart_overlay/mutant/tail/cat

	organ_flags = parent_type::organ_flags | ORGAN_EXTERNAL

	///Does this tail have a wagging sprite, and is it currently wagging?
	var/wag_flags = NONE
	///The original owner of this tail
	var/original_owner //Yay, snowflake code!
	///The overlay for tail spines, if any
	var/datum/bodypart_overlay/mutant/tail_spines/tail_spines_overlay

/obj/item/organ/tail/on_mob_insert(mob/living/carbon/receiver, special, movement_flags)
	. = ..()
	receiver.clear_mood_event("tail_lost")
	receiver.clear_mood_event("tail_balance_lost")

	if(!special) // if some admin wants to give someone tail moodles for tail shenanigans, they can spawn it and do it by hand
		original_owner ||= WEAKREF(receiver)

		// If it's your tail, an infinite debuff is replaced with a timed one
		// If it's not your tail but of same species, I guess it works, but we are more sad
		// If it's not your tail AND of different species, we are horrified
		if(IS_WEAKREF_OF(receiver, original_owner))
			receiver.add_mood_event("tail_regained", /datum/mood_event/tail_regained_right)
		else if(type in receiver.dna.species.mutant_organs)
			receiver.add_mood_event("tail_regained", /datum/mood_event/tail_regained_species)
		else
			receiver.add_mood_event("tail_regained", /datum/mood_event/tail_regained_wrong)

/obj/item/organ/tail/on_bodypart_insert(obj/item/bodypart/bodypart)
	var/obj/item/organ/spines/our_spines = bodypart.owner.get_organ_slot(ORGAN_SLOT_EXTERNAL_SPINES)
	if(our_spines)
		try_insert_tail_spines(bodypart)
	return ..()

/obj/item/organ/tail/on_bodypart_remove(obj/item/bodypart/bodypart)
	remove_tail_spines(bodypart)
	return ..()

/// If the owner has spines and an appropriate overlay exists, add a tail spines overlay.
/obj/item/organ/tail/proc/try_insert_tail_spines(obj/item/bodypart/bodypart)
	// Don't insert another overlay if there already is one.
	if(tail_spines_overlay)
		return
	// If this tail doesn't have a valid set of tail spines, don't insert them
	var/datum/sprite_accessory/tails/tail_sprite_datum = bodypart_overlay.sprite_datum
	if(!istype(tail_sprite_datum))
		return
	var/tail_spine_key = tail_sprite_datum.spine_key
	if(!tail_spine_key)
		return

	tail_spines_overlay = new
	tail_spines_overlay.tail_spine_key = tail_spine_key
	var/feature_name = bodypart.owner.dna.features["spines"] //tail spines don't live in DNA, but share feature names with regular spines
	tail_spines_overlay.set_appearance_from_name(feature_name)
	bodypart.add_bodypart_overlay(tail_spines_overlay)

/// If we have a tail spines overlay, delete it
/obj/item/organ/tail/proc/remove_tail_spines(obj/item/bodypart/bodypart)
	if(!tail_spines_overlay)
		return
	bodypart.remove_bodypart_overlay(tail_spines_overlay)
	QDEL_NULL(tail_spines_overlay)

/obj/item/organ/tail/on_mob_remove(mob/living/carbon/organ_owner, special, movement_flags)
	. = ..()

	if(wag_flags & WAG_WAGGING)
		stop_wag(organ_owner)

	organ_owner.clear_mood_event("tail_regained")

	if(type in organ_owner.dna.species.mutant_organs)
		organ_owner.add_mood_event("tail_lost", /datum/mood_event/tail_lost)
		organ_owner.add_mood_event("tail_balance_lost", /datum/mood_event/tail_balance_lost)

///We need some special behaviour for accessories, wrapped here so we can easily add more interactions later
///Accepts an optional timeout after which we remove the tail wagging
///Returns false if the wag worked, true otherwise
/obj/item/organ/tail/proc/start_wag(mob/living/carbon/organ_owner, stop_after = INFINITY)
	if(wag_flags & WAG_WAGGING || !(wag_flags & WAG_ABLE)) // we are already wagging
		return FALSE
	if(organ_owner.stat == DEAD || organ_owner != owner) // no wagging when owner is dead or tail has been disembodied
		return FALSE

	if(stop_after != INFINITY)
		addtimer(CALLBACK(src, PROC_REF(stop_wag), organ_owner), stop_after, TIMER_STOPPABLE|TIMER_DELETE_ME)

	var/datum/bodypart_overlay/mutant/tail/accessory = bodypart_overlay
	wag_flags |= WAG_WAGGING
	accessory.wagging = TRUE
	if(tail_spines_overlay) //if there are spines, they should wag with the tail
		tail_spines_overlay.wagging = TRUE
	organ_owner.update_body_parts()
	RegisterSignal(organ_owner, COMSIG_LIVING_DEATH, PROC_REF(owner_died))
	return TRUE

/obj/item/organ/tail/proc/owner_died(mob/living/carbon/organ_owner) // Resisting the urge to replace owner with daddy
	SIGNAL_HANDLER
	stop_wag(organ_owner)

///We need some special behaviour for accessories, wrapped here so we can easily add more interactions later
///Returns false if the wag stopping worked, true otherwise
/obj/item/organ/tail/proc/stop_wag(mob/living/carbon/organ_owner)
	if(!(wag_flags & WAG_ABLE))
		return FALSE

	var/succeeded = FALSE
	if(wag_flags & WAG_WAGGING)
		wag_flags &= ~WAG_WAGGING
		succeeded = TRUE

	var/datum/bodypart_overlay/mutant/tail/tail_overlay = bodypart_overlay
	tail_overlay.wagging = FALSE
	if(tail_spines_overlay) //if there are spines, they should stop wagging with the tail
		tail_spines_overlay.wagging = FALSE
	if(isnull(organ_owner))
		return succeeded

	organ_owner.update_body_parts()
	UnregisterSignal(organ_owner, COMSIG_LIVING_DEATH)
	return succeeded

/obj/item/organ/tail/proc/get_butt_sprite()
	return null

///Tail parent type, with wagging functionality
/datum/bodypart_overlay/mutant/tail
	layers = EXTERNAL_FRONT|EXTERNAL_BEHIND
	dyable = TRUE
	var/wagging = FALSE

/datum/bodypart_overlay/mutant/tail/get_base_icon_state()
	return "[wagging ? "wagging_" : ""][sprite_datum.icon_state]" //add the wagging tag if we be wagging

/datum/bodypart_overlay/mutant/tail/can_draw_on_bodypart(mob/living/carbon/human/human)
	if(human.wear_suit && (human.wear_suit.flags_inv & HIDEJUMPSUIT))
		return FALSE
	return TRUE

/obj/item/organ/tail/cat
	name = "tail"
	preference = "feature_human_tail"

	bodypart_overlay = /datum/bodypart_overlay/mutant/tail/cat
	restyle_flags = EXTERNAL_RESTYLE_FLESH

	wag_flags = WAG_ABLE

/obj/item/organ/tail/cat/get_butt_sprite()
	return icon('icons/mob/butts.dmi', BUTT_SPRITE_CAT)

///Cat tail bodypart overlay
/datum/bodypart_overlay/mutant/tail/cat
	feature_key = "tail_cat"
	color_source = ORGAN_COLOR_HAIR

/datum/bodypart_overlay/mutant/tail/cat/get_global_feature_list()
	return SSaccessories.tails_list_felinid

/obj/item/organ/tail/monkey
	name = "monkey tail"
	preference = "feature_monkey_tail"

	bodypart_overlay = /datum/bodypart_overlay/mutant/tail/monkey

	dna_block = null

///Monkey tail bodypart overlay
/datum/bodypart_overlay/mutant/tail/monkey
	color_source = NONE
	feature_key = "tail_monkey"

/datum/bodypart_overlay/mutant/tail/monkey/get_global_feature_list()
	return SSaccessories.tails_list_monkey

/obj/item/organ/tail/lizard
	name = "lizard tail"
	desc = "A severed lizard tail. Somewhere, no doubt, a lizard hater is very pleased with themselves."
	preference = "feature_lizard_tail"

	bodypart_overlay = /datum/bodypart_overlay/mutant/tail/lizard

	wag_flags = WAG_ABLE
	dna_block = DNA_LIZARD_TAIL_BLOCK

///Lizard tail bodypart overlay datum
/datum/bodypart_overlay/mutant/tail/lizard
	feature_key = "tail_lizard"

/datum/bodypart_overlay/mutant/tail/lizard/get_global_feature_list()
	return SSaccessories.tails_list_lizard

/obj/item/organ/tail/lizard/fake
	name = "fabricated lizard tail"
	desc = "A fabricated severed lizard tail. This one's made of synthflesh. Probably not usable for lizard wine."

///Bodypart overlay for tail spines. Handled by the tail - has no actual organ associated.
/datum/bodypart_overlay/mutant/tail_spines
	layers = EXTERNAL_ADJACENT|EXTERNAL_BEHIND
	feature_key = "tailspines"
	///Spines wag when the tail does
	var/wagging = FALSE
	/// Key for tail spine states, depends on the shape of the tail. Defined in the tail sprite datum.
	var/tail_spine_key = NONE

/datum/bodypart_overlay/mutant/tail_spines/get_global_feature_list()
	return SSaccessories.tail_spines_list

/datum/bodypart_overlay/mutant/tail_spines/get_base_icon_state()
	return (!isnull(tail_spine_key) ? "[tail_spine_key]_" : "") + (wagging ? "wagging_" : "") + sprite_datum.icon_state // Select the wagging state if appropriate

/datum/bodypart_overlay/mutant/tail_spines/can_draw_on_bodypart(mob/living/carbon/human/human)
	. = ..()
	if(human.wear_suit && (human.wear_suit.flags_inv & HIDEJUMPSUIT))
		return FALSE

/datum/bodypart_overlay/mutant/tail_spines/set_dye_color(new_color, obj/item/organ/organ)
	dye_color = new_color //no update_body_parts() call, tail/set_dye_color will do it.
