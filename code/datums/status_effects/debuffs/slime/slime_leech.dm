/atom/movable/screen/alert/status_effect/slime_leech
	name = "Covered in Slime"
	desc = "A slime is draining your very lifeforce! Remove it by hand, by hitting it, or by water."
	icon_state = "slime_leech"

/datum/status_effect/slime_leech
	id = "slime_leech"
	alert_type = /atom/movable/screen/alert/status_effect/slime_leech
	var/mob/living/basic/slime/our_slime

/datum/status_effect/slime_leech/on_creation(mob/living/new_owner, mob/living/basic/slime/our_slime)
	src.our_slime = our_slime
	return ..()

/datum/status_effect/slime_leech/on_apply()
	if(isnull(our_slime))
		return FALSE

	if(!isslime(our_slime))
		return FALSE

	RegisterSignals(our_slime, list(COMSIG_LIVING_DEATH, COMSIG_MOB_UNBUCKLED, COMSIG_QDELETING,), PROC_REF(on_buckle_end))
	return ..()

///If the buckling ends
/datum/status_effect/slime_leech/proc/on_buckle_end()
	SIGNAL_HANDLER

	var/bio_protection = 100 - owner.getarmor(null, BIO)
	if(prob(bio_protection))
		owner.apply_status_effect(/datum/status_effect/slimed, our_slime.slime_type.rgb_code, our_slime.slime_type.colour == SLIME_TYPE_RAINBOW)

	UnregisterSignal(our_slime, list(COMSIG_LIVING_DEATH, COMSIG_MOB_UNBUCKLED, COMSIG_QDELETING,))
	if(!QDELETED(our_slime))
		our_slime.stop_feeding()

	qdel(src)

/datum/status_effect/slime_leech/on_remove()
	our_slime = null

/datum/status_effect/slime_leech/tick(seconds_between_ticks)
	if(our_slime.stat != CONSCIOUS)
		our_slime.stop_feeding(silent = TRUE)
		return

	if(owner.stat == DEAD) // our victim died
		if(our_slime.client)
			to_chat(our_slime, span_info("This subject does not have a strong enough life energy anymore..."))

		SEND_SIGNAL(owner, COMSIG_SLIME_DRAINED, our_slime)

		if(prob(60) && owner.client && ishuman(owner) && !our_slime.ai_controller.blackboard[BB_SLIME_RABID])
			our_slime.ai_controller?.set_blackboard_key(BB_SLIME_RABID, TRUE) //we might go rabid after finishing to feed on a human with a client.

		our_slime.stop_feeding()
		return

	var/totaldamage = 0 //total damage done to this unfortunate soul

	if(iscarbon(owner))
		totaldamage += owner.adjustBruteLoss(rand(2, 4) * 0.5 * seconds_between_ticks)
		totaldamage += owner.adjustToxLoss(rand(1, 2) * 0.5 * seconds_between_ticks)

	if(isanimal_or_basicmob(owner))

		var/need_mob_update
		need_mob_update = totaldamage += owner.adjustBruteLoss(rand(2, 4) * 0.5 * seconds_between_ticks, updating_health = FALSE)
		need_mob_update += totaldamage += owner.adjustToxLoss(rand(1, 2) * 0.5 * seconds_between_ticks, updating_health = FALSE)
		if(need_mob_update)
			owner.updatehealth()

	if(totaldamage >= 0) // AdjustBruteLoss returns a negative value on successful damage adjustment
		our_slime.balloon_alert(our_slime, "not food!")
		our_slime.stop_feeding()
		return

	if(totaldamage < 0 && SPT_PROB(5, seconds_between_ticks) && owner.client)

		var/static/list/pain_lines
		if(isnull(pain_lines))
			pain_lines = list(
				"You can feel your body becoming weak!",
				"You feel like you're about to die!",
				"You feel every part of your body screaming in agony!",
				"A low, rolling pain passes through your body!",
				"Your body feels as if it's falling apart!",
				"You feel extremely weak!",
				"A sharp, deep pain bathes every inch of your body!",
			)

		to_chat(owner, span_userdanger(pick(pain_lines)))

	our_slime.adjust_nutrition(-1 * 1.8 * totaldamage) //damage is already modified by seconds_between_ticks

	//Heal yourself.
	our_slime.adjustBruteLoss(-1.5 * seconds_between_ticks)
