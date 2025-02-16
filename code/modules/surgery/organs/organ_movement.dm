// There are two kinds of organ movement: mob movement and limb movement
// If you pull someones brain out, you remove it from the mob and the limb
// If you take someones head off, you remove it from the mob but not the limb
// If you remove the brain from an already decapitated head, you remove it from the limb but not the mob

// Keep the seperation of limb removal and mob removal absolute

/*
 * Insert the organ into the select mob.
 *
 * receiver - the mob who will get our organ
 * special - "quick swapping" an organ out - when TRUE, the mob will be unaffected by not having that organ for the moment
 * movement_flags - Flags for how we behave in movement. See DEFINES/organ_movement for flags
 */
/obj/item/organ/proc/Insert(mob/living/carbon/receiver, special = FALSE, movement_flags)
	SHOULD_CALL_PARENT(TRUE)

	if(!mob_insert(receiver, special, movement_flags))
		return FALSE
	bodypart_insert(limb_owner = receiver, movement_flags = movement_flags)

	if(!special && !(receiver.living_flags & STOP_OVERLAY_UPDATE_BODY_PARTS))
		receiver.update_body_parts()

	return TRUE

/*
 * Remove the organ from the select mob.
 *
 * * organ_owner - the mob who owns our organ, that we're removing the organ from. Can be null
 * * special - "quick swapping" an organ out - when TRUE, the mob will be unaffected by not having that organ for the moment
 */
/obj/item/organ/proc/Remove(mob/living/carbon/organ_owner, special = FALSE, movement_flags)
	SHOULD_CALL_PARENT(TRUE)

	mob_remove(organ_owner, special, movement_flags)
	bodypart_remove(limb_owner = organ_owner, movement_flags = movement_flags)

	if(!special && !(organ_owner.living_flags & STOP_OVERLAY_UPDATE_BODY_PARTS))
		organ_owner.update_body_parts()

/*
 * Insert the organ into the select mob.
 *
 * receiver - the mob who will get our organ
 * special - "quick swapping" an organ out - when TRUE, the mob will be unaffected by not having that organ for the moment
 * movement_flags - Flags for how we behave in movement. See DEFINES/organ_movement for flags
 */
/obj/item/organ/proc/mob_insert(mob/living/carbon/receiver, special, movement_flags)
	SHOULD_NOT_OVERRIDE(TRUE)

	if(!iscarbon(receiver))
		//We try to insert the organ in a corgi when running the test, expecting it to return FALSE.
		if(!PERFORM_ALL_TESTS(organ_sanity))
			stack_trace("Tried to insert organ into non-carbon: [receiver.type]")
		return FALSE

	if(owner == receiver)
		stack_trace("Organ receiver is already organ owner")
		return FALSE

	var/obj/item/organ/replaced = receiver.get_organ_slot(slot)
	if(replaced)
		replaced.Remove(receiver, special = TRUE)
		if(movement_flags & DELETE_IF_REPLACED)
			qdel(replaced)
		else
			replaced.forceMove(get_turf(receiver))

	if(!IS_ROBOTIC_ORGAN(src) && (organ_flags & ORGAN_VIRGIN))
		blood_dna_info = receiver.get_blood_dna_list()
		// need to remove the synethic blood DNA that is initialized
		// wash also adds the blood dna again
		wash(CLEAN_TYPE_BLOOD)
		organ_flags &= ~ORGAN_VIRGIN

	if(external_bodytypes)
		receiver.synchronize_bodytypes()
	if(external_bodyshapes)
		receiver.synchronize_bodyshapes()

	receiver.organs |= src
	receiver.organs_slot[slot] = src
	owner = receiver

	on_mob_insert(receiver, special, movement_flags)

	return TRUE

/// Called after the organ is inserted into a mob.
/// Adds Traits, Actions, and Status Effects on the mob in which the organ is impanted.
/// Override this proc to create unique side-effects for inserting your organ. Must be called by overrides.
/obj/item/organ/proc/on_mob_insert(mob/living/carbon/organ_owner, special = FALSE, movement_flags)
	SHOULD_CALL_PARENT(TRUE)

	for(var/trait in organ_traits)
		ADD_TRAIT(organ_owner, trait, REF(src))

	for(var/datum/action/action as anything in actions)
		action.Grant(organ_owner)

	for(var/datum/status_effect/effect as anything in organ_effects)
		organ_owner.apply_status_effect(effect, type)

	if(!special)
		organ_owner.hud_used?.update_locked_slots()
	SEND_SIGNAL(src, COMSIG_ORGAN_IMPLANTED, organ_owner)
	SEND_SIGNAL(organ_owner, COMSIG_CARBON_GAIN_ORGAN, src, special)

	// organs_slot must ALWAYS be ordered in the same way as organ_process_order
	// Otherwise life processing breaks down
	sortTim(owner.organs_slot, GLOBAL_PROC_REF(cmp_organ_slot_asc))

	STOP_PROCESSING(SSobj, src)

/// Insert an organ into a limb, assume the limb as always detached and include no owner operations here (except the get_bodypart helper here I guess)
/// Give EITHER a limb OR a limb owner
/obj/item/organ/proc/bodypart_insert(obj/item/bodypart/bodypart, mob/living/carbon/limb_owner, movement_flags)
	SHOULD_CALL_PARENT(TRUE)

	if(limb_owner)
		bodypart = limb_owner.get_bodypart(deprecise_zone(zone))

	// The true movement
	forceMove(bodypart)
	bodypart.contents |= src
	bodypart_owner = bodypart

	RegisterSignal(src, COMSIG_MOVABLE_MOVED, PROC_REF(forced_removal))

	// Apply unique side-effects. Return value does not matter.
	on_bodypart_insert(bodypart)

	return TRUE

/// Add any limb specific effects you might want here
/obj/item/organ/proc/on_bodypart_insert(obj/item/bodypart/limb, movement_flags)
	SHOULD_CALL_PARENT(TRUE)

	item_flags |= ABSTRACT
	ADD_TRAIT(src, TRAIT_NODROP, ORGAN_INSIDE_BODY_TRAIT)
	interaction_flags_item &= ~INTERACT_ITEM_ATTACK_HAND_PICKUP

	if(bodypart_overlay)
		limb.add_bodypart_overlay(bodypart_overlay)

/*
 * Remove the organ from the select mob.
 *
 * * organ_owner - the mob who owns our organ, that we're removing the organ from. Can be null
 * * special - "quick swapping" an organ out - when TRUE, the mob will be unaffected by not having that organ for the moment
 */
/obj/item/organ/proc/mob_remove(mob/living/carbon/organ_owner, special = FALSE, movement_flags)
	SHOULD_NOT_OVERRIDE(TRUE)

	if(organ_owner)
		if(organ_owner.organs_slot[slot] == src)
			organ_owner.organs_slot.Remove(slot)
		organ_owner.organs -= src

	owner = null
	on_mob_remove(organ_owner, special, movement_flags)
	return TRUE

/// Called after the organ is removed from a mob.
/// Removes Traits, Actions, and Status Effects on the mob in which the organ was impanted.
/// Override this proc to create unique side-effects for removing your organ. Must be called by overrides.
/obj/item/organ/proc/on_mob_remove(mob/living/carbon/organ_owner, special = FALSE, movement_flags)
	SHOULD_CALL_PARENT(TRUE)

	if(!iscarbon(organ_owner))
		stack_trace("Organ removal should not be happening on non carbon mobs: [organ_owner]")

	for(var/trait in organ_traits)
		REMOVE_TRAIT(organ_owner, trait, REF(src))

	for(var/datum/action/action as anything in actions)
		action.Remove(organ_owner)

	for(var/datum/status_effect/effect as anything in organ_effects)
		organ_owner.remove_status_effect(effect, type)

	SEND_SIGNAL(src, COMSIG_ORGAN_REMOVED, organ_owner)
	SEND_SIGNAL(organ_owner, COMSIG_CARBON_LOSE_ORGAN, src, special)
	ADD_TRAIT(src, TRAIT_USED_ORGAN, ORGAN_TRAIT)

	organ_owner.synchronize_bodytypes()
	organ_owner.synchronize_bodyshapes()
	if(!special)
		organ_owner.hud_used?.update_locked_slots()

	if((organ_flags & ORGAN_VITAL) && !special && !HAS_TRAIT(organ_owner, TRAIT_GODMODE))
		if(organ_owner.stat != DEAD)
			organ_owner.investigate_log("has been killed by losing a vital organ ([src]).", INVESTIGATE_DEATHS)
		organ_owner.death()

	START_PROCESSING(SSobj, src)

	var/list/diseases = organ_owner.get_static_viruses()
	if(!LAZYLEN(diseases))
		return

	var/list/datum/disease/diseases_to_add = list()
	for(var/datum/disease/disease as anything in diseases)
		// robotic organs are immune to disease unless 'inorganic biology' symptom is present
		if(IS_ROBOTIC_ORGAN(src) && !(disease.infectable_biotypes & MOB_ROBOTIC))
			continue

		// admin or special viruses that should not be reproduced
		if(disease.spread_flags & (DISEASE_SPREAD_SPECIAL | DISEASE_SPREAD_NON_CONTAGIOUS))
			continue

		diseases_to_add += disease

	if(LAZYLEN(diseases_to_add))
		AddComponent(/datum/component/infective, diseases_to_add)

/// Called to remove an organ from a limb. Do not put any mob operations here (except the bodypart_getter at the start)
/// Give EITHER a limb OR a limb_owner
/obj/item/organ/proc/bodypart_remove(obj/item/bodypart/limb, mob/living/carbon/limb_owner, movement_flags)
	SHOULD_CALL_PARENT(TRUE)

	if(!isnull(limb_owner))
		limb = limb_owner.get_bodypart(deprecise_zone(zone))

	UnregisterSignal(src, COMSIG_MOVABLE_MOVED) //DONT MOVE THIS!!!! we moves the organ right after, so we unregister before we move them physically

	// The true movement is here
	moveToNullspace()
	bodypart_owner = null

	on_bodypart_remove(limb)

	return TRUE

/// Called on limb removal to remove limb specific limb effects or statusses
/obj/item/organ/proc/on_bodypart_remove(obj/item/bodypart/limb, movement_flags)
	SHOULD_CALL_PARENT(TRUE)

	if(!IS_ROBOTIC_ORGAN(src) && !(item_flags & NO_BLOOD_ON_ITEM) && !QDELING(src))
		AddElement(/datum/element/decal/blood)

	item_flags &= ~ABSTRACT
	REMOVE_TRAIT(src, TRAIT_NODROP, ORGAN_INSIDE_BODY_TRAIT)
	interaction_flags_item |= INTERACT_ITEM_ATTACK_HAND_PICKUP

	if(!bodypart_overlay)
		return

	limb.remove_bodypart_overlay(bodypart_overlay)

	if(use_mob_sprite_as_obj_sprite)
		update_appearance(UPDATE_OVERLAYS)

	color = bodypart_overlay.draw_color // so a pink felinid doesn't drop a gray tail

	if(greyscale_config)
		get_greyscale_color_from_draw_color()
	else
		color = bodypart_overlay.draw_color // so a pink felinid doesn't drop a gray tail

///Here we define how draw_color from the bodypart overlay sets the greyscale colors of organs that use GAGS
/obj/item/organ/proc/get_greyscale_color_from_draw_color()
	color = bodypart_overlay.draw_color //Defaults to the legacy behaviour of applying the color to the item.

/// In space station videogame, nothing is sacred. If somehow an organ is removed unexpectedly, handle it properly
/obj/item/organ/proc/forced_removal()
	SIGNAL_HANDLER

	if(owner)
		Remove(owner)
	else if(bodypart_owner)
		bodypart_remove(bodypart_owner)
	else
		stack_trace("Force removed an already removed organ!")

/**
 * Proc that gets called when the organ is surgically removed by someone, can be used for special effects
 */
/obj/item/organ/proc/on_surgical_removal(mob/living/user, mob/living/carbon/old_owner, target_zone, obj/item/tool)
	SHOULD_CALL_PARENT(TRUE)
	SEND_SIGNAL(src, COMSIG_ORGAN_SURGICALLY_REMOVED, user, old_owner, target_zone, tool)
	RemoveElement(/datum/element/decal/blood)
/**
 * Proc that gets called when the organ is surgically inserted by someone. Seem familiar?
 */
/obj/item/organ/proc/on_surgical_insertion(mob/living/user, mob/living/carbon/new_owner, target_zone, obj/item/tool)
	SHOULD_CALL_PARENT(TRUE)
	SEND_SIGNAL(src, COMSIG_ORGAN_SURGICALLY_INSERTED, user, new_owner, target_zone, tool)

/// Proc that gets called when someone starts surgically inserting the organ
/obj/item/organ/proc/pre_surgical_insertion(mob/living/user, mob/living/carbon/new_owner, target_zone)
	return TRUE
