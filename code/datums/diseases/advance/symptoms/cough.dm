/**Coughing
 * Slightly decreases stealth
 * Reduces resistance
 * Slightly increases stage speed
 * Increases transmissibility
 * Low level
 * Bonus: Spreads the virus in a small square around the host. Can force the affected mob to drop small items!
*/
/datum/symptom/cough
	name = "Cough"
	desc = "The virus irritates the throat of the host, causing occasional coughing. Each cough will try to infect bystanders who are within 1 tile of the host with the virus."
	illness = "Jest Infection"
	stealth = -1
	resistance = 3
	stage_speed = 1
	transmittable = 2
	level = 1
	severity = 1
	base_message_chance = 15
	symptom_delay_min = 2
	symptom_delay_max = 15
	required_organ = ORGAN_SLOT_LUNGS
	threshold_descs = list(
		"Resistance 11" = "The host will drop small items when coughing.",
		"Resistance 15" = "Occasionally causes coughing fits that stun the host. The extra coughs do not spread the virus.",
		"Stage Speed 6" = "Increases cough frequency.",
		"Transmission 7" = "Coughing will now infect bystanders up to 2 tiles away.",
		"Stealth 4" = "The symptom remains hidden until active.",
	)
	///emote cooldowns
	COOLDOWN_DECLARE(cough_cooldown)
	///if FALSE, there is a percentage chance that the mob will emote coughing while cough_cooldown is on cooldown. If TRUE, won't emote again until after the off cooldown cough occurs.
	var/off_cooldown_coughed = FALSE
	var/spread_range = 1

/datum/symptom/cough/Start(datum/disease/advance/active_disease)
	. = ..()
	if(!.)
		return
	if(active_disease.totalStealth() >= 4)
		suppress_warning = TRUE
	if(active_disease.totalTransmittable() >= 7)
		spread_range = 2
	if(active_disease.totalResistance() >= 11) //strong enough to drop items
		power = 1.5
	if(active_disease.totalResistance() >= 15) //strong enough to stun (occasionally)
		power = 2
	if(active_disease.totalStageSpeed() >= 6) //cough more often
		symptom_delay_max = 10

/datum/symptom/cough/Activate(datum/disease/advance/active_disease)
	. = ..()
	if(!.)
		return
	var/mob/living/affected_mob = active_disease.affected_mob
	if(HAS_TRAIT(affected_mob, TRAIT_SOOTHED_THROAT))
		return
	switch(active_disease.stage)
		if(1, 2, 3)
			if(prob(base_message_chance) && !suppress_warning)
				to_chat(affected_mob, span_warning("[pick("You swallow excess mucus.", "You lightly cough.")]"))
		else
			if(COOLDOWN_FINISHED(src, cough_cooldown) || !COOLDOWN_FINISHED(src, cough_cooldown) && prob(60) && !off_cooldown_coughed)
				affected_mob.emote("cough")
				COOLDOWN_START(src, cough_cooldown, 5 SECONDS)
				if(!off_cooldown_coughed && !COOLDOWN_FINISHED(src, cough_cooldown))
					off_cooldown_coughed = TRUE
				else
					off_cooldown_coughed = FALSE
			active_disease.airborne_spread(spread_range)
			if(power >= 1.5)
				var/obj/item/held_object = affected_mob.get_active_held_item()
				if(held_object && held_object.w_class == WEIGHT_CLASS_TINY)
					affected_mob.dropItemToGround(held_object)
			if(power >= 2 && prob(30))
				to_chat(affected_mob, span_userdanger("[pick("You have a coughing fit!", "You can't stop coughing!")]"))
				affected_mob.Immobilize(20)
				addtimer(CALLBACK(affected_mob, TYPE_PROC_REF(/mob/, emote), "cough"), 0.6 SECONDS)
				addtimer(CALLBACK(affected_mob, TYPE_PROC_REF(/mob/, emote), "cough"), 1.2 SECONDS)
				addtimer(CALLBACK(affected_mob, TYPE_PROC_REF(/mob/, emote), "cough"), 1.8 SECONDS)
