/// Proc ghosts to enter the body when it get's revived
/datum/component/ghostrole_on_revive
	/// If revived and no ghosts, just die again?
	var/refuse_revival_if_failed
	/// Callback for when the mob is revived and has their body occupied by a ghost
	var/datum/callback/on_successful_revive

/datum/component/ghostrole_on_revive/Initialize(refuse_revival_if_failed, on_successful_revive)
	. = ..()

	src.refuse_revival_if_failed = refuse_revival_if_failed
	src.on_successful_revive = on_successful_revive

	ADD_TRAIT(parent, TRAIT_GHOSTROLE_ON_REVIVE, REF(src)) //for adding an alternate examination

	if(ismob(parent))
		prepare_mob(parent)
		return

	if(!istype(parent, /obj/item/organ/brain))
		return COMPONENT_INCOMPATIBLE

	var/obj/item/organ/brain/brein = parent
	if(brein.owner)
		prepare_mob(brein.owner)
	else
		prepare_brain(brein)

/// Give the appropriate signals, and watch for organ removal
/datum/component/ghostrole_on_revive/proc/prepare_mob(mob/living/liver)
	RegisterSignal(liver, COMSIG_LIVING_REVIVE, PROC_REF(on_revive))
	ADD_TRAIT(liver, TRAIT_GHOSTROLE_ON_REVIVE, REF(src))
	liver.med_hud_set_status()

	if(iscarbon(liver))
		var/mob/living/carbon/carbon = liver
		var/obj/item/organ/brain = carbon.get_organ_by_type(/obj/item/organ/brain)
		if(brain)
			RegisterSignal(brain, COMSIG_ORGAN_REMOVED, PROC_REF(on_remove))

/datum/component/ghostrole_on_revive/proc/on_remove(obj/item/organ/brain, mob/living/old_owner)
	SIGNAL_HANDLER

	REMOVE_TRAIT(old_owner, TRAIT_GHOSTROLE_ON_REVIVE, REF(src))
	// we might have some lingering blinking eyes
	var/obj/item/bodypart/head/head = old_owner?.get_bodypart(BODY_ZONE_HEAD)
	if(head)
		var/soul_eyes = locate(/datum/bodypart_overlay/simple/soul_pending_eyes) in head.bodypart_overlays
		if(soul_eyes)
			head.remove_bodypart_overlay(soul_eyes)

	prepare_brain(brain)

/datum/component/ghostrole_on_revive/proc/prepare_brain(obj/item/organ/brein)
	SIGNAL_HANDLER

	RegisterSignal(brein, COMSIG_ORGAN_IMPLANTED, PROC_REF(prepare_mob_from_brain))
	UnregisterSignal(brein, COMSIG_ORGAN_REMOVED)

/datum/component/ghostrole_on_revive/proc/prepare_mob_from_brain(obj/item/organ/brain/brein, mob/living/owner)
	SIGNAL_HANDLER

	UnregisterSignal(brein, COMSIG_ORGAN_IMPLANTED)
	prepare_mob(owner)

/datum/component/ghostrole_on_revive/proc/on_revive(mob/living/aliver)
	SIGNAL_HANDLER

	INVOKE_ASYNC(src, PROC_REF(poll_ghosts), aliver)

/datum/component/ghostrole_on_revive/proc/poll_ghosts(mob/living/aliver)
	var/soul_eyes
	var/obj/item/bodypart/head
	// adds soulful SOUL PENDING eyes to indicate what's happening to observers

	var/mob/living/carbon/human/hewmon
	if(ishuman(aliver))
		hewmon = aliver
		head = hewmon.get_bodypart(BODY_ZONE_HEAD)
		if(head)
			soul_eyes = new /datum/bodypart_overlay/simple/soul_pending_eyes ()
			head.add_bodypart_overlay(soul_eyes)
			hewmon.update_body_parts()

	var/mob/dead/observer/chosen_one = SSpolling.poll_ghosts_for_target(
		question = "Would you like to play as a recovered crewmember?",
		role = null,
		check_jobban = ROLE_RECOVERED_CREW,
		poll_time = 15 SECONDS,
		checked_target = aliver,
		ignore_category = POLL_IGNORE_RECOVERED_CREW,
		alert_pic = aliver,
		role_name_text = "recovered crew",
	)
	if(head)
		head.remove_bodypart_overlay(soul_eyes)
		hewmon?.update_body_parts()

	if(!isobserver(chosen_one))
		if(refuse_revival_if_failed)
			aliver.death()
			aliver.visible_message(span_deadsay("[aliver.name]'s soul is struggling to return!"))
	else
		aliver.PossessByPlayer(chosen_one.ckey)
		on_successful_revive?.Invoke(aliver)
		qdel(src)

/datum/component/ghostrole_on_revive/Destroy(force)
	REMOVE_TRAIT(parent, TRAIT_GHOSTROLE_ON_REVIVE, REF(src))

	var/mob/living/living
	if(isliving(parent))
		living = parent
	else if(istype(parent, /obj/item/organ/brain))
		var/obj/item/organ/brain/brain = parent
		living = brain.owner
	living?.med_hud_set_status()

	. = ..()
