/datum/round_event_control/wizard/imposter //Mirror Mania
	name = "Imposter Wizard"
	weight = 1
	typepath = /datum/round_event/wizard/imposter
	max_occurrences = 1
	earliest_start = 0 MINUTES
	description = "Spawns a doppelganger of the wizard."
	min_wizard_trigger_potency = 2
	max_wizard_trigger_potency = 7

/datum/round_event/wizard/imposter/start()
	for(var/datum/mind/M as anything in get_antag_minds(/datum/antagonist/wizard))
		if(!ishuman(M.current))
			continue
		var/mob/living/carbon/human/W = M.current
		var/mob/chosen_one = SSpolling.poll_ghost_candidates("Would you like to be an [span_notice("imposter wizard")]?", check_jobban = ROLE_WIZARD, alert_pic = /obj/item/clothing/head/wizard, jump_target = W, role_name_text = "imposter wizard", amount_to_pick = 1)
		if(isnull(chosen_one))
			return //Sad Trombone
		new /obj/effect/particle_effect/fluid/smoke(W.loc)
		var/mob/living/carbon/human/I = new /mob/living/carbon/human(W.loc)
		W.dna.transfer_identity(I, transfer_SE=1)
		I.real_name = I.dna.real_name
		I.name = I.dna.real_name
		I.updateappearance(mutcolor_update=1)
		I.domutcheck()
		I.PossessByPlayer(chosen_one.key)
		var/datum/antagonist/wizard/master = M.has_antag_datum(/datum/antagonist/wizard)
		if(!master.wiz_team)
			master.create_wiz_team()
		var/datum/antagonist/wizard/apprentice/imposter/imposter = new()
		imposter.master = M
		imposter.wiz_team = master.wiz_team
		master.wiz_team.add_member(imposter)
		I.mind.add_antag_datum(imposter)
		I.mind.special_role = "imposter"
		I.log_message("is an imposter!", LOG_ATTACK, color="red") //?
		SEND_SOUND(I, sound('sound/effects/magic.ogg'))
		announce_to_ghosts(I)
