/obj/item/organ/lungs
	name = "lungs"
	icon_state = "lungs"

	zone = BODY_ZONE_CHEST
	slot = ORGAN_SLOT_LUNGS
	gender = PLURAL
	w_class = WEIGHT_CLASS_SMALL

	var/respiration_type = NONE // The type(s) of gas this lung needs for respiration

	healing_factor = STANDARD_ORGAN_HEALING
	decay_factor = STANDARD_ORGAN_DECAY * 0.9 // fails around 16.5 minutes, lungs are one of the last organs to die (of the ones we have)

	low_threshold_passed = span_warning("You feel short of breath.")
	high_threshold_passed = span_warning("You feel some sort of constriction around your chest as your breathing becomes shallow and rapid.")
	now_fixed = span_warning("Your lungs seem to once again be able to hold air.")
	low_threshold_cleared = span_info("You can breathe normally again.")
	high_threshold_cleared = span_info("The constriction around your chest loosens as your breathing calms down.")

	var/failed = FALSE
	var/operated = FALSE //whether we can still have our damages fixed through surgery

	food_reagents = list(/datum/reagent/consumable/nutriment/organ_tissue = 5, /datum/reagent/medicine/salbutamol = 5)

	/// Our previous breath's partial pressures, in the form gas id -> partial pressure
	var/list/last_partial_pressures = list()
	/// List of gas to treat as other gas, in the form list(inital_gas, treat_as, multiplier)
	var/list/treat_as = list()
	/// Assoc list of procs to run while a gas is present, in the form gas id -> proc_path
	var/list/breath_present = list()
	/// Assoc list of procs to run when a gas is immediately removed from the breath, in the form gas id -> proc_path
	var/list/breath_lost = list()
	/// Assoc list of procs to always run, in the form gas_id -> proc_path
	var/list/breathe_always = list()

	/// Gas mixture to breath out when we're done processing a breath
	/// Will get emptied out when it's all done
	var/datum/gas_mixture/immutable/breath_out

	//Breath damage
	//These thresholds are checked against what amounts to total_mix_pressure * (gas_type_mols/total_mols)
	var/safe_oxygen_min = 16 // Minimum safe partial pressure of O2, in kPa
	var/safe_oxygen_max = 0
	var/safe_nitro_min = 0
	var/safe_co2_max = 10 // Yes it's an arbitrary value who cares?
	var/safe_plasma_min = 0
	///How much breath partial pressure is a safe amount of plasma. 0 means that we are immune to plasma.
	var/safe_plasma_max = 0.05
	var/n2o_detect_min = 0.08 //Minimum n2o for effects
	var/n2o_para_min = 1 //Sleeping agent
	var/n2o_sleep_min = 5 //Sleeping agent
	var/BZ_trip_balls_min = 1 //BZ gas
	var/BZ_brain_damage_min = 10 //Give people some room to play around without killing the station
	var/gas_stimulation_min = 0.002 // For, Pluoxium, Nitrium and Freon
	///Minimum amount of healium to make you unconscious for 4 seconds
	var/healium_para_min = 3
	///Minimum amount of healium to knock you down for good
	var/healium_sleep_min = 6
	///Minimum amount of helium to affect speech
	var/helium_speech_min = 5
	///Whether these lungs react negatively to miasma
	var/suffers_miasma = TRUE
	// Vars for N2O/healium induced euphoria, stun, and sleep.
	var/n2o_euphoria = EUPHORIA_LAST_FLAG
	var/healium_euphoria = EUPHORIA_LAST_FLAG


	var/oxy_breath_dam_min = MIN_TOXIC_GAS_DAMAGE
	var/oxy_breath_dam_max = MAX_TOXIC_GAS_DAMAGE
	var/oxy_damage_type = OXY
	var/nitro_breath_dam_min = MIN_TOXIC_GAS_DAMAGE
	var/nitro_breath_dam_max = MAX_TOXIC_GAS_DAMAGE
	var/nitro_damage_type = OXY
	var/co2_breath_dam_min = MIN_TOXIC_GAS_DAMAGE
	var/co2_breath_dam_max = MAX_TOXIC_GAS_DAMAGE
	var/co2_damage_type = OXY
	var/plas_breath_dam_min = MIN_TOXIC_GAS_DAMAGE
	var/plas_breath_dam_max = MAX_TOXIC_GAS_DAMAGE
	var/plas_damage_type = TOX

	var/tritium_irradiation_moles_min = 1
	var/tritium_irradiation_moles_max = 15
	var/tritium_irradiation_probability_min = 10
	var/tritium_irradiation_probability_max = 60

	var/cold_message = "your face freezing and an icicle forming"
	var/cold_level_1_threshold = 260
	var/cold_level_2_threshold = 200
	var/cold_level_3_threshold = 120
	var/cold_level_1_damage = COLD_GAS_DAMAGE_LEVEL_1 //Keep in mind with gas damage levels, you can set these to be negative, if you want someone to heal, instead.
	var/cold_level_2_damage = COLD_GAS_DAMAGE_LEVEL_2
	var/cold_level_3_damage = COLD_GAS_DAMAGE_LEVEL_3
	var/cold_damage_type = BURN

	var/hot_message = "your face burning and a searing heat"
	var/heat_level_1_threshold = 360
	var/heat_level_2_threshold = 400
	var/heat_level_3_threshold = 1000
	var/heat_level_1_damage = HEAT_GAS_DAMAGE_LEVEL_1
	var/heat_level_2_damage = HEAT_GAS_DAMAGE_LEVEL_2
	var/heat_level_3_damage = HEAT_GAS_DAMAGE_LEVEL_3
	var/heat_damage_type = BURN

	var/crit_stabilizing_reagent = /datum/reagent/medicine/epinephrine

// assign the respiration_type
/obj/item/organ/lungs/Initialize(mapload)
	. = ..()
	breath_out = new(BREATH_VOLUME)

	if(safe_nitro_min)
		respiration_type |= RESPIRATION_N2
	if(safe_oxygen_min)
		respiration_type |= RESPIRATION_OXYGEN
	if(safe_plasma_min)
		respiration_type |= RESPIRATION_PLASMA

	// Sets up what gases we want to react to, and in what way
	// always is always processed, while_present is called when the gas is in the breath, and on_loss is called right after a gas is lost
	// The naming convention goes like this
	// always : breath_{gas_type}
	// safe/neutral while_present : consume_{gas_type}
	// safe/neutral on_loss : lose_{gas_type}
	// dangerous while_present : too_much_{gas_type}
	// dangerous on_loss : safe_{gas_type}
	// These are reccomendations, if something seems better feel free to ignore them. S a bit vibes based
	if(safe_oxygen_min)
		add_gas_reaction(/datum/gas/oxygen, always = PROC_REF(breathe_oxygen))
	if(safe_oxygen_max)
		add_gas_reaction(/datum/gas/oxygen, while_present = PROC_REF(too_much_oxygen), on_loss = PROC_REF(safe_oxygen))
	add_gas_reaction(/datum/gas/pluoxium, while_present = PROC_REF(consume_pluoxium))
	// We treat a mole of ploux as 8 moles of oxygen
	add_gas_relationship(/datum/gas/pluoxium, /datum/gas/oxygen, 8)
	if(safe_nitro_min)
		add_gas_reaction(/datum/gas/nitrogen, always = PROC_REF(breathe_nitro))
	if(safe_co2_max)
		add_gas_reaction(/datum/gas/carbon_dioxide, while_present = PROC_REF(too_much_co2), on_loss = PROC_REF(safe_co2))
	if(safe_plasma_min)
		add_gas_reaction(/datum/gas/plasma, always = PROC_REF(breathe_plasma))
	if(safe_plasma_max)
		add_gas_reaction(/datum/gas/plasma, while_present = PROC_REF(too_much_plasma), on_loss = PROC_REF(safe_plasma))
	add_gas_reaction(/datum/gas/bz, while_present = PROC_REF(too_much_bz))
	add_gas_reaction(/datum/gas/freon, while_present = PROC_REF(too_much_freon))
	add_gas_reaction(/datum/gas/halon, while_present = PROC_REF(too_much_halon))
	add_gas_reaction(/datum/gas/healium, while_present = PROC_REF(consume_healium), on_loss = PROC_REF(lose_healium))
	add_gas_reaction(/datum/gas/helium, while_present = PROC_REF(consume_helium), on_loss = PROC_REF(lose_helium))
	add_gas_reaction(/datum/gas/hypernoblium, while_present = PROC_REF(consume_hypernoblium))
	if(suffers_miasma)
		add_gas_reaction(/datum/gas/miasma, while_present = PROC_REF(too_much_miasma), on_loss = PROC_REF(safe_miasma))
	add_gas_reaction(/datum/gas/nitrous_oxide, while_present = PROC_REF(too_much_n2o), on_loss = PROC_REF(safe_n2o))
	add_gas_reaction(/datum/gas/nitrium, while_present = PROC_REF(too_much_nitrium))
	add_gas_reaction(/datum/gas/tritium, while_present = PROC_REF(too_much_tritium))
	add_gas_reaction(/datum/gas/zauker, while_present = PROC_REF(too_much_zauker))

///Simply exists so that you don't keep any alerts from your previous lack of lungs.
/obj/item/organ/lungs/on_mob_insert(mob/living/carbon/receiver, special = FALSE, movement_flags)
	. = ..()

	receiver.clear_alert(ALERT_NOT_ENOUGH_OXYGEN)
	receiver.clear_alert(ALERT_NOT_ENOUGH_CO2)
	receiver.clear_alert(ALERT_NOT_ENOUGH_NITRO)
	receiver.clear_alert(ALERT_NOT_ENOUGH_PLASMA)
	receiver.clear_alert(ALERT_NOT_ENOUGH_N2O)

/obj/item/organ/lungs/on_mob_remove(mob/living/carbon/organ_owner, special, movement_flags)
	. = ..()
	// This is very "manual" I realize, but it's useful to ensure cleanup for gases we're removing happens
	// Avoids stuck alerts and such
	var/static/datum/gas_mixture/immutable/dummy = new(BREATH_VOLUME)
	for(var/gas_id in last_partial_pressures)
		var/on_loss = breath_lost[gas_id]
		if(!on_loss)
			continue

		call(src, on_loss)(organ_owner, dummy, last_partial_pressures[gas_id])
	dummy.garbage_collect()

/**
 * Tells the lungs to pay attention to the passed in gas type
 * We'll check for it when breathing, in a few possible ways
 * Accepts 3 optional arguments:
 *
 * proc/while_present * Called while the gas is present in our breath. Return BREATH_LOST to call on_loss afterwards
 * proc/on_loss * Called after we have lost a gas from our breath.
 * proc/always * Always called. Best suited for breathing procs, like oxygen
 *
 * while_present and always get the same arguments (mob/living/carbon/breather, datum/gas_mixture/breath, pp, old_pp)
 * on_loss is almost exactly the same, except it doesn't pass in a current partial pressure, since one isn't avalible
 */
/obj/item/organ/lungs/proc/add_gas_reaction(gas_type, while_present = null, on_loss = null, always = null)
	if(always)
		breathe_always[gas_type] = always

	if(isnull(while_present) && isnull(on_loss))
		return

	if(while_present)
		breath_present[gas_type] = while_present
	if(on_loss)
		breath_lost[gas_type] = on_loss

#define BREATH_RELATIONSHIP_INITIAL_GAS 1
#define BREATH_RELATIONSHIP_CONVERT 2
#define BREATH_RELATIONSHIP_MULTIPLIER 3
/**
 * Tells the lungs to treat the passed in gas type as another passed in gas type
 * Takes the gas to check for as an argument, alongside the gas to convert and the multiplier to use
 * These act in the order of insertion, use that how you will
 */
/obj/item/organ/lungs/proc/add_gas_relationship(gas_type, convert_to, multiplier)
	if(isnull(gas_type) || isnull(convert_to) || multiplier == 0)
		return

	var/list/add = new /list(BREATH_RELATIONSHIP_MULTIPLIER)
	add[BREATH_RELATIONSHIP_INITIAL_GAS] = gas_type
	add[BREATH_RELATIONSHIP_CONVERT] = convert_to
	add[BREATH_RELATIONSHIP_MULTIPLIER] = multiplier
	treat_as += list(add)

/// Clears away a gas relationship. Takes the same args as the initial addition
/obj/item/organ/lungs/proc/remove_gas_relationship(gas_type, convert_to, multiplier)
	if(isnull(gas_type) || isnull(convert_to) || multiplier == 0)
		return

	for(var/packet in treat_as)
		if(packet[BREATH_RELATIONSHIP_INITIAL_GAS] != gas_type)
			continue
		if(packet[BREATH_RELATIONSHIP_CONVERT] != convert_to)
			continue
		if(packet[BREATH_RELATIONSHIP_MULTIPLIER] != multiplier)
			continue
		treat_as -= packet
		return

/// Handles oxygen breathing. Always called by things that need o2, no matter what
/obj/item/organ/lungs/proc/breathe_oxygen(mob/living/carbon/breather, datum/gas_mixture/breath, o2_pp, old_o2_pp)
	if(o2_pp < safe_oxygen_min && !HAS_TRAIT(src, TRAIT_SPACEBREATHING))
		// Not safe to check the old pp because of can_breath_vacuum
		breather.throw_alert(ALERT_NOT_ENOUGH_OXYGEN, /atom/movable/screen/alert/not_enough_oxy)

		var/gas_breathed = handle_suffocation(breather, o2_pp, safe_oxygen_min, breath.gases[/datum/gas/oxygen][MOLES])
		if(o2_pp)
			breathe_gas_volume(breath, /datum/gas/oxygen, /datum/gas/carbon_dioxide, volume = gas_breathed)
		return

	// If we used to not have enough, clear the alert
	// Note this can be redundant, because of the vacuum check. It is fail safe tho, so it's ok
	if(old_o2_pp < safe_oxygen_min)
		breather.failed_last_breath = FALSE
		breather.clear_alert(ALERT_NOT_ENOUGH_OXYGEN)

	breathe_gas_volume(breath, /datum/gas/oxygen, /datum/gas/carbon_dioxide)
	// Heal mob if not in crit.
	if(breather.health >= breather.crit_threshold && breather.oxyloss)
		breather.adjustOxyLoss(-5)

/// Maximum Oxygen effects. "Too much O2!"
/obj/item/organ/lungs/proc/too_much_oxygen(mob/living/carbon/breather, datum/gas_mixture/breath, o2_pp, old_o2_pp)
	// If too much Oxygen is poisonous.
	if(o2_pp <= safe_oxygen_max)
		if(old_o2_pp > safe_oxygen_max)
			return BREATH_LOST
		return

	var/ratio = (breath.gases[/datum/gas/oxygen][MOLES] / safe_oxygen_max) * 10
	breather.apply_damage(clamp(ratio, oxy_breath_dam_min, oxy_breath_dam_max), oxy_damage_type, spread_damage = TRUE)
	if(!HAS_TRAIT(breather, TRAIT_ANOSMIA))
		breather.throw_alert(ALERT_TOO_MUCH_OXYGEN, /atom/movable/screen/alert/too_much_oxy)

/// Handles NOT having too much o2. only relevant if safe_oxygen_max has a value
/obj/item/organ/lungs/proc/safe_oxygen(mob/living/carbon/breather, datum/gas_mixture/breath, old_o2_pp)
	breather.clear_alert(ALERT_TOO_MUCH_OXYGEN)

/// Behaves like Oxygen with 8X efficacy, but metabolizes into a reagent.
/obj/item/organ/lungs/proc/consume_pluoxium(mob/living/carbon/breather, datum/gas_mixture/breath, pluoxium_pp, old_pluoxium_pp)
	breathe_gas_volume(breath, /datum/gas/pluoxium)
	// Metabolize to reagent.
	if(pluoxium_pp > gas_stimulation_min)
		var/existing = breather.reagents.get_reagent_amount(/datum/reagent/pluoxium)
		breather.reagents.add_reagent(/datum/reagent/pluoxium, max(0, 1 - existing))

/// If the lungs need Nitrogen to breathe properly, N2 is exchanged with CO2.
/obj/item/organ/lungs/proc/breathe_nitro(mob/living/carbon/breather, datum/gas_mixture/breath, nitro_pp, old_nitro_pp)
	if(nitro_pp < safe_nitro_min && !HAS_TRAIT(src, TRAIT_SPACEBREATHING))
		// Suffocation side-effects.
		// Not safe to check the old pp because of can_breath_vacuum
		if(!HAS_TRAIT(breather, TRAIT_ANOSMIA))
			breather.throw_alert(ALERT_NOT_ENOUGH_NITRO, /atom/movable/screen/alert/not_enough_nitro)
		var/gas_breathed = handle_suffocation(breather, nitro_pp, safe_nitro_min, breath.gases[/datum/gas/nitrogen][MOLES])
		if(nitro_pp)
			breathe_gas_volume(breath, /datum/gas/nitrogen, /datum/gas/carbon_dioxide, volume = gas_breathed)
		return

	if(old_nitro_pp < safe_nitro_min)
		breather.failed_last_breath = FALSE
		breather.clear_alert(ALERT_NOT_ENOUGH_NITRO)

	// Inhale N2, exhale equivalent amount of CO2. Look ma, sideways breathing!
	breathe_gas_volume(breath, /datum/gas/nitrogen, /datum/gas/carbon_dioxide)
	// Heal mob if not in crit.
	if(breather.health >= breather.crit_threshold && breather.oxyloss)
		breather.adjustOxyLoss(-5)

/// Maximum CO2 effects. "Too much CO2!"
/obj/item/organ/lungs/proc/too_much_co2(mob/living/carbon/breather, datum/gas_mixture/breath, co2_pp, old_co2_pp)
	if(co2_pp <= safe_co2_max)
		if(old_co2_pp > safe_co2_max)
			return BREATH_LOST
		return

	// If it's the first breath with too much CO2 in it, lets start a counter, then have them pass out after 12s or so.
	if(old_co2_pp < safe_co2_max)
		breather.co2overloadtime = world.time

	// CO2 side-effects.
	// Give the mob a chance to notice.
	if(prob(20))
		breather.emote("cough")

	if((world.time - breather.co2overloadtime) > 12 SECONDS)
		if(!HAS_TRAIT(breather, TRAIT_ANOSMIA))
			breather.throw_alert(ALERT_TOO_MUCH_CO2, /atom/movable/screen/alert/too_much_co2)
		breather.Unconscious(6 SECONDS)
		// Lets hurt em a little, let them know we mean business.
		breather.apply_damage(3, co2_damage_type, spread_damage = TRUE)
		// They've been in here 30s now, start to kill them for their own good!
		if((world.time - breather.co2overloadtime) > 30 SECONDS)
			breather.apply_damage(8, co2_damage_type, spread_damage = TRUE)

/// Handles NOT having too much co2. only relevant if safe_co2_max has a value
/obj/item/organ/lungs/proc/safe_co2(mob/living/carbon/breather, datum/gas_mixture/breath, old_co2_pp)
	// Reset side-effects.
	breather.co2overloadtime = 0
	breather.clear_alert(ALERT_TOO_MUCH_CO2)

/// If the lungs need Plasma to breathe properly, Plasma is exchanged with CO2.
/obj/item/organ/lungs/proc/breathe_plasma(mob/living/carbon/breather, datum/gas_mixture/breath, plasma_pp, old_plasma_pp)
	// Suffocation side-effects.
	if(plasma_pp < safe_plasma_min && !HAS_TRAIT(src, TRAIT_SPACEBREATHING))
		// Could check old_plasma_pp but vacuum breathing hates me
		if(!HAS_TRAIT(breather, TRAIT_ANOSMIA))
			breather.throw_alert(ALERT_NOT_ENOUGH_PLASMA, /atom/movable/screen/alert/not_enough_plas)
		// Breathe insufficient amount of Plasma, exhale CO2.
		var/gas_breathed = handle_suffocation(breather, plasma_pp, safe_plasma_min, breath.gases[/datum/gas/plasma][MOLES])
		if(plasma_pp)
			breathe_gas_volume(breath, /datum/gas/plasma, /datum/gas/carbon_dioxide, volume = gas_breathed)
		return

	if(old_plasma_pp < safe_plasma_min)
		breather.failed_last_breath = FALSE
		breather.clear_alert(ALERT_NOT_ENOUGH_PLASMA)
	// Inhale Plasma, exhale equivalent amount of CO2.
	breathe_gas_volume(breath, /datum/gas/plasma, /datum/gas/carbon_dioxide)
	// Heal mob if not in crit.
	if(breather.health >= breather.crit_threshold && breather.oxyloss)
		breather.adjustOxyLoss(-5)

/// Maximum Plasma effects. "Too much Plasma!"
/obj/item/organ/lungs/proc/too_much_plasma(mob/living/carbon/breather, datum/gas_mixture/breath, plasma_pp, old_plasma_pp)
	if(plasma_pp <= safe_plasma_max)
		if(old_plasma_pp > safe_plasma_max)
			return BREATH_LOST
		return

	// If it's the first breath with too much CO2 in it, lets start a counter, then have them pass out after 12s or so.
	if(old_plasma_pp < safe_plasma_max)
		if(!HAS_TRAIT(breather, TRAIT_ANOSMIA))
			breather.throw_alert(ALERT_TOO_MUCH_PLASMA, /atom/movable/screen/alert/too_much_plas)

	var/ratio = (breath.gases[/datum/gas/plasma][MOLES] / safe_plasma_max) * 10
	breather.apply_damage(clamp(ratio, plas_breath_dam_min, plas_breath_dam_max), plas_damage_type, spread_damage = TRUE)

/// Resets plasma side effects
/obj/item/organ/lungs/proc/safe_plasma(mob/living/carbon/breather, datum/gas_mixture/breath, old_plasma_pp)
	breather.clear_alert(ALERT_TOO_MUCH_PLASMA)

/// Too much funny gas, time to get brain damage
/obj/item/organ/lungs/proc/too_much_bz(mob/living/carbon/breather, datum/gas_mixture/breath, bz_pp, old_bz_pp)
	if(bz_pp > BZ_trip_balls_min)
		breather.adjust_hallucinations(20 SECONDS)
		breather.reagents.add_reagent(/datum/reagent/bz_metabolites, 5)
	if(bz_pp > BZ_brain_damage_min && prob(33))
		breather.adjustOrganLoss(ORGAN_SLOT_BRAIN, 3, 150, ORGAN_ORGANIC)

/// Breathing in refridgerator coolent, shit's caustic
/obj/item/organ/lungs/proc/too_much_freon(mob/living/carbon/breather, datum/gas_mixture/breath, freon_pp, old_freon_pp)
	// Inhale Freon. Exhale nothing.
	breathe_gas_volume(breath, /datum/gas/freon)
	if (freon_pp > gas_stimulation_min)
		breather.reagents.add_reagent(/datum/reagent/freon, 1)
	if (prob(freon_pp))
		to_chat(breather, span_alert("Your mouth feels like it's burning!"))
	if (freon_pp > 40)
		breather.emote("gasp")
		breather.adjustFireLoss(15)
		if (prob(freon_pp / 2))
			to_chat(breather, span_alert("Your throat closes up!"))
			breather.set_silence_if_lower(6 SECONDS)
	else
		breather.adjustFireLoss(freon_pp / 4)

/// Breathing in halon, convert it to a reagent
/obj/item/organ/lungs/proc/too_much_halon(mob/living/carbon/breather, datum/gas_mixture/breath, halon_pp, old_halon_pp)
	// Inhale Halon. Exhale nothing.
	breathe_gas_volume(breath, /datum/gas/halon)
	// Metabolize to reagent.
	if(halon_pp > gas_stimulation_min)
		breather.adjustOxyLoss(5)
		breather.reagents.add_reagent(/datum/reagent/halon, max(0, 1 - breather.reagents.get_reagent_amount(/datum/reagent/halon)))

/// Sleeping gas with healing properties.
/obj/item/organ/lungs/proc/consume_healium(mob/living/carbon/breather, datum/gas_mixture/breath, healium_pp, old_healium_pp)
	breathe_gas_volume(breath, /datum/gas/healium)
	// Euphoria side-effect.
	if(healium_pp > gas_stimulation_min)
		if(prob(15))
			to_chat(breather, span_alert("Your head starts spinning and your lungs burn!"))
			healium_euphoria = EUPHORIA_ACTIVE
			breather.emote("gasp")
	else
		healium_euphoria = EUPHORIA_INACTIVE
	// Stun/Sleep side-effects.
	if(healium_pp > healium_para_min && !breather.IsSleeping() && prob(30))
		breather.Sleeping(rand(3 SECONDS, 5 SECONDS))
	// Metabolize to reagent when concentration is high enough.
	if(healium_pp > healium_sleep_min)
		breather.reagents.add_reagent(/datum/reagent/healium, max(0, 1 - breather.reagents.get_reagent_amount(/datum/reagent/healium)))

/// Lose healium side effects
/obj/item/organ/lungs/proc/lose_healium(mob/living/carbon/breather, datum/gas_mixture/breath, old_healium_pp)
	healium_euphoria = EUPHORIA_INACTIVE

/// Activates helium speech when partial pressure gets high enough
/obj/item/organ/lungs/proc/consume_helium(mob/living/carbon/breather, datum/gas_mixture/breath, helium_pp, old_helium_pp)
	breathe_gas_volume(breath, /datum/gas/helium)
	if(helium_pp > helium_speech_min)
		if(old_helium_pp <= helium_speech_min)
			RegisterSignal(breather, COMSIG_MOB_SAY, PROC_REF(handle_helium_speech))
	else
		if(old_helium_pp > helium_speech_min)
			UnregisterSignal(breather, COMSIG_MOB_SAY)

/// Lose helium high pitched voice
/obj/item/organ/lungs/proc/lose_helium(mob/living/carbon/breather, datum/gas_mixture/breath, old_helium_pp)
	UnregisterSignal(breather, COMSIG_MOB_SAY)

/// React to speach while hopped up on the high pitched voice juice
/obj/item/organ/lungs/proc/handle_helium_speech(mob/living/carbon/breather, list/speech_args)
	SIGNAL_HANDLER
	speech_args[SPEECH_SPANS] |= SPAN_SMALL_VOICE

/// Gain hypernob effects if we have enough of the stuff
/obj/item/organ/lungs/proc/consume_hypernoblium(mob/living/carbon/breather, datum/gas_mixture/breath, hypernob_pp, old_hypernob_pp)
	breathe_gas_volume(breath, /datum/gas/hypernoblium)
	if (hypernob_pp > gas_stimulation_min)
		var/existing = breather.reagents.get_reagent_amount(/datum/reagent/hypernoblium)
		breather.reagents.add_reagent(/datum/reagent/hypernoblium,max(0, 1 - existing))

/// Breathing in the stink gas
/obj/item/organ/lungs/proc/too_much_miasma(mob/living/carbon/breather, datum/gas_mixture/breath, miasma_pp, old_miasma_pp)
	// Inhale Miasma. Exhale nothing.
	breathe_gas_volume(breath, /datum/gas/miasma)
	// Miasma side effects
	if (HAS_TRAIT(breather, TRAIT_ANOSMIA)) //Anosmia quirk holder cannot smell miasma, but can get diseases from it.
		return
	switch(miasma_pp)
		if(0.25 to 5)
			// At lower pp, give out a little warning
			breather.clear_mood_event("smell")
			if(prob(5))
				to_chat(breather, span_notice("There is an unpleasant smell in the air."))
		if(5 to 15)
			//At somewhat higher pp, warning becomes more obvious
			if(prob(15))
				to_chat(breather, span_warning("You smell something horribly decayed inside this room."))
				breather.add_mood_event("smell", /datum/mood_event/disgust/bad_smell)
		if(15 to 30)
			//Small chance to vomit. By now, people have internals on anyway
			if(prob(5))
				to_chat(breather, span_warning("The stench of rotting carcasses is unbearable!"))
				breather.add_mood_event("smell", /datum/mood_event/disgust/nauseating_stench)
				breather.vomit(VOMIT_CATEGORY_DEFAULT)
		if(30 to INFINITY)
			//Higher chance to vomit. Let the horror start
			if(prob(15))
				to_chat(breather, span_warning("The stench of rotting carcasses is unbearable!"))
				breather.add_mood_event("smell", /datum/mood_event/disgust/nauseating_stench)
				breather.vomit(VOMIT_CATEGORY_DEFAULT)
		else
			breather.clear_mood_event("smell")
	// In a full miasma atmosphere with 101.34 pKa, about 10 disgust per breath, is pretty low compared to threshholds
	// Then again, this is a purely hypothetical scenario and hardly reachable
	breather.adjust_disgust(0.1 * miasma_pp)

/// We're free from the stick, clear out its impacts
/obj/item/organ/lungs/proc/safe_miasma(mob/living/carbon/breather, datum/gas_mixture/breath, old_miasma_pp)
	// Clear out moods when immune to miasma, or if there's no miasma at all.
	breather.clear_mood_event("smell")

/// Causes random euphoria and giggling. Large amounts knock you down
/obj/item/organ/lungs/proc/too_much_n2o(mob/living/carbon/breather, datum/gas_mixture/breath, n2o_pp, old_n2o_pp)
	if(n2o_pp < n2o_para_min)
		// Small amount of N2O, small side-effects.
		if(n2o_pp <= n2o_detect_min)
			if(old_n2o_pp > n2o_detect_min)
				return BREATH_LOST
			return
		// No alert for small amounts, but the mob randomly feels euphoric.
		if(old_n2o_pp >= n2o_para_min || old_n2o_pp <= n2o_detect_min)
			breather.clear_alert(ALERT_TOO_MUCH_N2O)

		if(prob(20))
			n2o_euphoria = EUPHORIA_ACTIVE
			breather.emote(pick("giggle", "laugh"))
			breather.set_drugginess(30 SECONDS)
		else
			n2o_euphoria = EUPHORIA_INACTIVE
		return

	// More N2O, more severe side-effects. Causes stun/sleep.
	if(old_n2o_pp < n2o_para_min)
		if(!HAS_TRAIT(breather, TRAIT_ANOSMIA))
			breather.throw_alert(ALERT_TOO_MUCH_N2O, /atom/movable/screen/alert/too_much_n2o)
	n2o_euphoria = EUPHORIA_ACTIVE

	// give them one second of grace to wake up and run away a bit!
	if(!HAS_TRAIT(breather, TRAIT_SLEEPIMMUNE))
		breather.Unconscious(6 SECONDS)
	// Enough to make the mob sleep.
	if(n2o_pp > n2o_sleep_min)
		breather.Sleeping(min(breather.AmountSleeping() + 100, 200))

/// N2O side-effects. "Too much N2O!"
/obj/item/organ/lungs/proc/safe_n2o(mob/living/carbon/breather, datum/gas_mixture/breath, old_n2o_pp)
	n2o_euphoria = EUPHORIA_INACTIVE
	breather.clear_alert(ALERT_TOO_MUCH_N2O)

// Breathe in nitrium. It's helpful, but has nasty side effects
/obj/item/organ/lungs/proc/too_much_nitrium(mob/living/carbon/breather, datum/gas_mixture/breath, nitrium_pp, old_nitrium_pp)
	breathe_gas_volume(breath, /datum/gas/nitrium)

	if(prob(20))
		breather.emote("burp")

	// Random chance to inflict side effects increases with pressure.
	if((prob(nitrium_pp) && (nitrium_pp > 15)))
		// Nitrium side-effect.
		breather.adjustOrganLoss(ORGAN_SLOT_LUNGS, nitrium_pp * 0.1)
		to_chat(breather, span_notice("You feel a burning sensation in your chest"))
	// Metabolize to reagents.
	if (nitrium_pp > 5)
		var/existing = breather.reagents.get_reagent_amount(/datum/reagent/nitrium_low_metabolization)
		breather.reagents.add_reagent(/datum/reagent/nitrium_low_metabolization, max(0, 2 - existing))
	if (nitrium_pp > 10)
		var/existing = breather.reagents.get_reagent_amount(/datum/reagent/nitrium_high_metabolization)
		breather.reagents.add_reagent(/datum/reagent/nitrium_high_metabolization, max(0, 1 - existing))

/// Radioactive, green gas. Toxin damage, and a radiation chance
/obj/item/organ/lungs/proc/too_much_tritium(mob/living/carbon/breather, datum/gas_mixture/breath, trit_pp, old_trit_pp)
	var/gas_breathed = breathe_gas_volume(breath, /datum/gas/tritium)
	var/moles_visible = GLOB.meta_gas_info[/datum/gas/tritium][META_GAS_MOLES_VISIBLE] * BREATH_PERCENTAGE
	// Tritium side-effects.
	if(gas_breathed > moles_visible)
		var/ratio = gas_breathed * 15
		breather.adjustToxLoss(clamp(ratio, MIN_TOXIC_GAS_DAMAGE, MAX_TOXIC_GAS_DAMAGE))
	// If you're breathing in half an atmosphere of radioactive gas, you fucked up.
	if((trit_pp > tritium_irradiation_moles_min) && SSradiation.can_irradiate_basic(breather))
		var/lerp_scale = min(tritium_irradiation_moles_max, trit_pp - tritium_irradiation_moles_min) / (tritium_irradiation_moles_max - tritium_irradiation_moles_min)
		var/chance = LERP(tritium_irradiation_probability_min, tritium_irradiation_probability_max, lerp_scale)
		if (prob(chance))
			breather.AddComponent(/datum/component/irradiated)

/// Really toxic stuff, very much trying to kill you
/obj/item/organ/lungs/proc/too_much_zauker(mob/living/carbon/breather, datum/gas_mixture/breath, zauker_pp, old_zauker_pp)
	breathe_gas_volume(breath, /datum/gas/zauker)
	// Metabolize to reagent.
	if(zauker_pp > gas_stimulation_min)
		var/existing = breather.reagents.get_reagent_amount(/datum/reagent/zauker)
		breather.reagents.add_reagent(/datum/reagent/zauker, max(0, 1 - existing))

/**
 * This proc tests if the lungs can breathe, if they can breathe a given gas mixture, and throws/clears gas alerts.
 * It does this by calling subprocs "registered" to pay attention to different gas types
 * There's also support for gases that should always be checked for, and procs that should run when a gas is finished
 *
 *
 * Returns TRUE if the breath was successful, or FALSE if otherwise.
 *
 * Arguments:
 * * breath: A gas mixture to test, or null.
 * * breather: A carbon mob that is using the lungs to breathe.
 */
/obj/item/organ/lungs/proc/check_breath(datum/gas_mixture/breath, mob/living/carbon/human/breather)
	if(HAS_TRAIT(breather, TRAIT_GODMODE))
		breather.failed_last_breath = FALSE
		breather.clear_alert(ALERT_NOT_ENOUGH_OXYGEN)
		return FALSE

	if(HAS_TRAIT(breather, TRAIT_NOBREATH))
		return FALSE

	// If the breath is falsy or "null", we can use the backup empty_breath.
	if(!breath)
		var/static/datum/gas_mixture/immutable/empty_breath = new(BREATH_VOLUME)
		breath = empty_breath

	// Indicates if there are moles of gas in the breath.
	var/has_moles = breath.total_moles() != 0

	// Check for moles of gas and handle partial pressures / special conditions.
	if(has_moles)
		// Breath has more than 0 moles of gas.
		// Route gases through mask filter if breather is wearing one.
		if(istype(breather.wear_mask) && (breather.wear_mask.clothing_flags & GAS_FILTERING) && breather.wear_mask.has_filter)
			breath = breather.wear_mask.consume_filter(breath)
	// Breath has 0 moles of gas, and we can breathe space
	else if(HAS_TRAIT(src, TRAIT_SPACEBREATHING))
		// The lungs can breathe anyways. What are you? Some bottom-feeding, scum-sucking algae eater?
		breather.failed_last_breath = FALSE
		// Vacuum-adapted lungs regenerate oxyloss even when breathing nothing.
		if(breather.health >= breather.crit_threshold && breather.oxyloss)
			breather.adjustOxyLoss(-5)
	else
		// Can't breathe!
		breather.failed_last_breath = TRUE

	// The list of gases in the breath.
	var/list/breath_gases = breath.gases
	// Copy the breath's temperature into breath_out to avoid cooling the output breath down unfairly
	breath_out.temperature = breath.temperature

	var/old_euphoria = (n2o_euphoria == EUPHORIA_ACTIVE || healium_euphoria == EUPHORIA_ACTIVE)

	// Cache for sonic speed
	var/list/last_partial_pressures = src.last_partial_pressures
	var/list/breathe_always = src.breathe_always
	var/list/breath_present = src.breath_present
	var/list/breath_lost = src.breath_lost

	// Build out our partial pressures, for use as we go
	var/list/partial_pressures = list()
	for(var/gas_id in breath_gases)
		partial_pressures[gas_id] = breath.get_breath_partial_pressure(breath_gases[gas_id][MOLES])

	// Treat gas as other types of gas
	for(var/list/conversion_packet in treat_as)
		var/read_from = conversion_packet[BREATH_RELATIONSHIP_INITIAL_GAS]
		if(!partial_pressures[read_from])
			continue
		var/convert_into = conversion_packet[BREATH_RELATIONSHIP_CONVERT]
		partial_pressures[convert_into] += partial_pressures[read_from] * conversion_packet[BREATH_RELATIONSHIP_MULTIPLIER]
		if(partial_pressures[convert_into] <= 0)
			partial_pressures -= convert_into // No negative values jeremy

	// First, we breathe the stuff that always wants to be processed
	// This is typically things like o2, stuff the mob needs to live
	for(var/breath_id in breathe_always)
		var/partial_pressure = partial_pressures[breath_id] || 0
		var/old_partial_pressure = last_partial_pressures[breath_id] || 0
		// Ensures the gas will always be instanciated, so people can interact with it safely
		ASSERT_GAS(breath_id, breath)
		var/inhale = breathe_always[breath_id]
		call(src, inhale)(breather, breath, partial_pressure, old_partial_pressure)

	// Now we'll handle the callbacks that want to be run conditionally off our current breath
	for(var/breath_id in breath_gases)
		var/when_present = breath_present[breath_id]
		if(!when_present)
			continue

		var/reaction = call(src, when_present)(breather, breath, partial_pressures[breath_id], last_partial_pressures[breath_id])
		if(reaction == BREATH_LOST)
			var/on_lose = breath_lost[breath_id]
			if(on_lose)
				call(src, on_lose)(breather, breath, partial_pressures[breath_id], last_partial_pressures[breath_id])

	// Finally, we'll run the callbacks that aren't in breath_gases, but WERE in our last breath
	for(var/gas_lost in last_partial_pressures)
		// If we still have it, go away
		if(breath_gases[gas_lost])
			continue
		var/on_loss = breath_lost[gas_lost]
		if(!on_loss)
			continue

		call(src, on_loss)(breather, breath, last_partial_pressures[gas_lost])

	src.last_partial_pressures = partial_pressures

	// Handle chemical euphoria mood event, caused by gases such as N2O or healium.
	var/new_euphoria = (n2o_euphoria == EUPHORIA_ACTIVE || healium_euphoria == EUPHORIA_ACTIVE)
	if (!old_euphoria && new_euphoria)
		breather.add_mood_event("chemical_euphoria", /datum/mood_event/chemical_euphoria)
	else if (old_euphoria && !new_euphoria)
		breather.clear_mood_event("chemical_euphoria")

	if(has_moles)
		handle_breath_temperature(breath, breather)
		// Merge breath_out into breath. They're kept seprerate before now to ensure stupid like, order of operations shit doesn't happen
		// But that time has passed
		breath.merge(breath_out)
		// Resets immutable gas_mixture to empty.
		breath_out.garbage_collect()

	breath.garbage_collect()
	// Returning FALSE indicates the breath failed.
	if(!breather.failed_last_breath)
		return TRUE

/// Remove gas from breath. If output_gas is given, transfers the removed gas to the lung's gas_mixture.
/// Removes 100% of the given gas type unless given a volume argument.
/// Returns the amount of gas theoretically removed.
/obj/item/organ/lungs/proc/breathe_gas_volume(datum/gas_mixture/breath, remove_id, exchange_id = null, volume = INFINITY)
	var/list/breath_gases = breath.gases
	volume = min(volume, breath_gases[remove_id][MOLES])
	breath_gases[remove_id][MOLES] -= volume
	if(exchange_id)
		ASSERT_GAS(exchange_id, breath_out)
		breath_out.gases[exchange_id][MOLES] += volume
	return volume

/// Applies suffocation side-effects to a given Human, scaling based on ratio of required pressure VS "true" pressure.
/// If pressure is greater than 0, the return value will represent the amount of gas successfully breathed.
/obj/item/organ/lungs/proc/handle_suffocation(mob/living/carbon/human/suffocator = null, breath_pp = 0, safe_breath_min = 0, mole_count = 0)
	. = 0
	// Can't suffocate without a Human, or without minimum breath pressure.
	if(!suffocator || !safe_breath_min)
		return
	// Mob is suffocating.
	suffocator.failed_last_breath = TRUE
	// Give them a chance to notice something is wrong.
	if(prob(20))
		suffocator.emote("gasp")
	// If mob is at critical health, check if they can be damaged further.
	if(suffocator.health < suffocator.crit_threshold)
		// Mob is immune to damage at critical health.
		if(HAS_TRAIT(suffocator, TRAIT_NOCRITDAMAGE))
			return
		// Reagents like Epinephrine stop suffocation at critical health.
		if(suffocator.reagents.has_reagent(crit_stabilizing_reagent, needs_metabolizing = TRUE))
			return
	// Low pressure.
	if(breath_pp)
		var/ratio = safe_breath_min / breath_pp
		suffocator.adjustOxyLoss(min(5 * ratio, HUMAN_MAX_OXYLOSS))
		return mole_count * ratio / 6
	// Zero pressure.
	if(suffocator.health >= suffocator.crit_threshold)
		suffocator.adjustOxyLoss(HUMAN_MAX_OXYLOSS)
	else
		suffocator.adjustOxyLoss(HUMAN_CRIT_MAX_OXYLOSS)


/obj/item/organ/lungs/proc/handle_breath_temperature(datum/gas_mixture/breath, mob/living/carbon/human/breather) // called by human/life, handles temperatures
	var/breath_temperature = breath.temperature

	if(!HAS_TRAIT(breather, TRAIT_RESISTCOLD)) // COLD DAMAGE
		var/cold_modifier = breather.dna.species.coldmod
		var/breath_effect_prob = 0
		if(breath_temperature < cold_level_3_threshold)
			breather.apply_damage(cold_level_3_damage * cold_modifier, cold_damage_type, spread_damage = TRUE)
			breath_effect_prob = 100
		if(breath_temperature > cold_level_3_threshold && breath_temperature < cold_level_2_threshold)
			breather.apply_damage(cold_level_2_damage * cold_modifier, cold_damage_type, spread_damage = TRUE)
			breath_effect_prob = 50
		if(breath_temperature > cold_level_2_threshold && breath_temperature < cold_level_1_threshold)
			breather.apply_damage(cold_level_1_damage * cold_modifier, cold_damage_type, spread_damage = TRUE)
			breath_effect_prob = 25
		if(breath_temperature < cold_level_1_threshold)
			if(prob(sqrt(breath_effect_prob) * 4))
				to_chat(breather, span_warning("You feel [cold_message] in your [name]!"))
				if(prob(50))
					breather.emote("shiver")
			if(prob(breath_effect_prob))
				// Breathing into your mask, no particle. We can add fogged up glasses later
				if(breather.is_mouth_covered())
					return
				// Even though breathing via internals TECHNICALLY exhales into the environment, we'll still block it
				if(breather.internal || breather.external)
					return
				emit_breath_particle(breather, /particles/fog/breath)

	if(!HAS_TRAIT(breather, TRAIT_RESISTHEAT)) // HEAT DAMAGE
		var/heat_modifier = breather.dna.species.heatmod
		var/heat_message_prob = 0
		if(breath_temperature > heat_level_1_threshold && breath_temperature < heat_level_2_threshold)
			breather.apply_damage(heat_level_1_damage * heat_modifier, heat_damage_type, spread_damage = TRUE)
			heat_message_prob = 100
		if(breath_temperature > heat_level_2_threshold && breath_temperature < heat_level_3_threshold)
			breather.apply_damage(heat_level_2_damage * heat_modifier, heat_damage_type, spread_damage = TRUE)
			heat_message_prob = 50
		if(breath_temperature > heat_level_3_threshold)
			breather.apply_damage(heat_level_3_damage * heat_modifier, heat_damage_type, spread_damage = TRUE)
			heat_message_prob = 25
		if(breath_temperature > heat_level_1_threshold)
			if(prob(sqrt(heat_message_prob) * 4))
				to_chat(breather, span_warning("You feel [hot_message] in your [name]!"))

	// The air you breathe out should match your body temperature
	breath.temperature = breather.bodytemperature

/// Creates a particle effect off the mouth of the passed mob.
/obj/item/organ/lungs/proc/emit_breath_particle(mob/living/carbon/human/breather, particle_type)
	ASSERT(ispath(particle_type, /particles))

	var/obj/effect/abstract/particle_holder/holder = new(breather, particle_type)
	var/particles/breath_particle = holder.particles
	var/breath_dir = breather.dir

	var/list/particle_grav = list(0, 0.1, 0)
	var/list/particle_pos = list(0, breather.mob_height + 2, 0)
	if(breath_dir & NORTH)
		particle_grav[2] = 0.2
		breath_particle.rotation = pick(-45, 45)
		// Layer it behind the mob since we're facing away from the camera
		holder.pixel_w -= 4
		holder.pixel_y += 4
	if(breath_dir & WEST)
		particle_grav[1] = -0.2
		particle_pos[1] = -5
		breath_particle.rotation = -45
	if(breath_dir & EAST)
		particle_grav[1] = 0.2
		particle_pos[1] = 5
		breath_particle.rotation = 45
	if(breath_dir & SOUTH)
		particle_grav[2] = 0.2
		breath_particle.rotation = pick(-45, 45)
		// Shouldn't be necessary but just for parity
		holder.pixel_w += 4
		holder.pixel_y -= 4

	breath_particle.gravity = particle_grav
	breath_particle.position = particle_pos

	QDEL_IN(holder, breath_particle.lifespan)

/obj/item/organ/lungs/on_life(seconds_per_tick, times_fired)
	. = ..()
	if(failed && !(organ_flags & ORGAN_FAILING))
		failed = FALSE
		return
	if(damage >= low_threshold)
		var/do_i_cough = SPT_PROB((damage < high_threshold) ? 2.5 : 5, seconds_per_tick) // between : past high
		if(do_i_cough)
			owner.emote("cough")
	if(organ_flags & ORGAN_FAILING && owner.stat == CONSCIOUS)
		owner.visible_message(span_danger("[owner] grabs [owner.p_their()] throat, struggling for breath!"), span_userdanger("You suddenly feel like you can't breathe!"))
		failed = TRUE

/obj/item/organ/lungs/get_availability(datum/species/owner_species, mob/living/owner_mob)
	return owner_species.mutantlungs

#define SMOKER_ORGAN_HEALTH (STANDARD_ORGAN_THRESHOLD * 0.75)
#define SMOKER_LUNG_HEALING (STANDARD_ORGAN_HEALING * 0.75)

/obj/item/organ/lungs/plasmaman
	name = "plasma filter"
	desc = "A spongy rib-shaped mass for filtering plasma from the air."
	icon_state = "lungs-plasma"
	organ_traits = list(TRAIT_NOHUNGER) // A fresh breakfast of plasma is a great start to any morning.

	safe_oxygen_min = 0 //We don't breathe this
	safe_plasma_min = 4 //We breathe THIS!
	safe_plasma_max = 0

/obj/item/organ/lungs/plasmaman/plasmaman_smoker
	name = "smoker plasma filter"
	desc = "A plasma filter that look discolored, a result from smoking a lot."
	icon_state = "lungs_plasma_smoker"

	maxHealth = SMOKER_ORGAN_HEALTH
	healing_factor = SMOKER_LUNG_HEALING

/obj/item/organ/lungs/slime
	name = "slime vacuole"
	desc = "A large organelle designed to store oxygen and other important gasses."

	safe_plasma_max = 0 //We breathe this to gain POWER.

/obj/item/organ/lungs/slime/check_breath(datum/gas_mixture/breath, mob/living/carbon/human/breather_slime)
	. = ..()
	if (breath?.gases[/datum/gas/plasma])
		var/plasma_pp = breath.get_breath_partial_pressure(breath.gases[/datum/gas/plasma][MOLES])
		breather_slime.blood_volume += (0.2 * plasma_pp) // 10/s when breathing literally nothing but plasma, which will suffocate you.

/obj/item/organ/lungs/smoker_lungs
	name = "smoker lungs"
	desc = "A pair of lungs that look sickly, a result from smoking a lot."
	icon_state = "lungs_smoker"

	maxHealth = SMOKER_ORGAN_HEALTH
	healing_factor = SMOKER_LUNG_HEALING

/obj/item/organ/lungs/cybernetic
	name = "basic cybernetic lungs"
	desc = "A basic cybernetic version of the lungs found in traditional humanoid entities."
	failing_desc = "seems to be broken."
	icon_state = "lungs-c"
	organ_flags = ORGAN_ROBOTIC
	maxHealth = STANDARD_ORGAN_THRESHOLD * 0.5
	var/emp_vulnerability = 80 //Chance of permanent effects if emp-ed.

/obj/item/organ/lungs/cybernetic/emp_act(severity)
	. = ..()
	if(. & EMP_PROTECT_SELF)
		return
	if(!COOLDOWN_FINISHED(src, severe_cooldown)) //So we cant just spam emp to kill people.
		owner.losebreath += 20
		COOLDOWN_START(src, severe_cooldown, 30 SECONDS)
	if(prob(emp_vulnerability/severity)) //Chance of permanent effects
		organ_flags |= ORGAN_EMP //Starts organ faliure - gonna need replacing soon.

/obj/item/organ/lungs/cybernetic/tier2
	name = "cybernetic lungs"
	desc = "A cybernetic version of the lungs found in traditional humanoid entities. Allows for greater intakes of oxygen than organic lungs, requiring slightly less pressure."
	icon_state = "lungs-c-u"
	maxHealth = 1.5 * STANDARD_ORGAN_THRESHOLD
	safe_oxygen_min = 13
	emp_vulnerability = 40

/obj/item/organ/lungs/cybernetic/tier3
	name = "upgraded cybernetic lungs"
	desc = "A more advanced version of the stock cybernetic lungs. Features the ability to filter out lower levels of plasma and carbon dioxide."
	icon_state = "lungs-c-u2"
	safe_plasma_max = 20
	safe_co2_max = 20
	maxHealth = 2 * STANDARD_ORGAN_THRESHOLD
	safe_oxygen_min = 13
	emp_vulnerability = 20

	cold_level_1_threshold = 200
	cold_level_2_threshold = 140
	cold_level_3_threshold = 100

/obj/item/organ/lungs/cybernetic/surplus
	name = "surplus prosthetic lungs"
	desc = "Two fragile, inflatable sacks of air that only barely mimic the function of human lungs. \
		Offer no protection against EMPs."
	icon_state = "lungs-c-s"
	maxHealth = 0.35 * STANDARD_ORGAN_THRESHOLD
	emp_vulnerability = 100

//surplus organs are so awful that they explode when removed, unless failing
/obj/item/organ/lungs/cybernetic/surplus/Initialize(mapload)
	. = ..()
	AddElement(/datum/element/dangerous_organ_removal, /*surgical = */ TRUE)

/obj/item/organ/lungs/lavaland
	name = "blackened frilled lungs" // blackened from necropolis exposure
	desc = "Exposure to the necropolis has mutated these lungs to breathe the air of Indecipheres, the lava-covered moon."
	icon_state = "lungs-ashwalker"

// Normal oxygen is 21 kPa partial pressure, but SS13 humans can tolerate down
// to 16 kPa. So it follows that ashwalkers, as humanoids, follow the same rules.
#define GAS_TOLERANCE 5

/obj/item/organ/lungs/lavaland/Initialize(mapload)
	var/datum/gas_mixture/immutable/planetary/mix = SSair.planetary[LAVALAND_DEFAULT_ATMOS]

	if(!mix?.total_moles()) // this typically means we didn't load lavaland, like if we're using the LOWMEMORYMODE define
		return ..()

	// Take a "breath" of the air
	var/datum/gas_mixture/breath = mix.remove(mix.total_moles() * BREATH_PERCENTAGE)

	var/list/breath_gases = breath.gases

	breath.assert_gases(
		/datum/gas/oxygen,
		/datum/gas/plasma,
		/datum/gas/carbon_dioxide,
		/datum/gas/nitrogen,
		/datum/gas/bz,
		/datum/gas/miasma,
	)

	var/oxygen_pp = breath.get_breath_partial_pressure(breath_gases[/datum/gas/oxygen][MOLES])
	var/nitrogen_pp = breath.get_breath_partial_pressure(breath_gases[/datum/gas/nitrogen][MOLES])
	var/plasma_pp = breath.get_breath_partial_pressure(breath_gases[/datum/gas/plasma][MOLES])
	var/carbon_dioxide_pp = breath.get_breath_partial_pressure(breath_gases[/datum/gas/carbon_dioxide][MOLES])
	var/bz_pp = breath.get_breath_partial_pressure(breath_gases[/datum/gas/bz][MOLES])
	var/miasma_pp = breath.get_breath_partial_pressure(breath_gases[/datum/gas/miasma][MOLES])

	safe_oxygen_min = max(0, oxygen_pp - GAS_TOLERANCE)
	safe_nitro_min = max(0, nitrogen_pp - GAS_TOLERANCE)
	safe_plasma_min = max(0, plasma_pp - GAS_TOLERANCE)

	// Increase plasma tolerance based on amount in base air
	safe_plasma_max += plasma_pp

	// CO2 is always a waste gas, so none is required, but ashwalkers
	// tolerate the base amount plus tolerance*2 (humans tolerate only 10 pp)

	safe_co2_max = carbon_dioxide_pp + GAS_TOLERANCE * 2

	// The lung tolerance against BZ is also increased the amount of BZ in the base air
	BZ_trip_balls_min += bz_pp
	BZ_brain_damage_min += bz_pp

	// Lungs adapted to a high miasma atmosphere do not process it, and breathe it back out
	if(miasma_pp)
		suffers_miasma = FALSE
	return ..()


#undef GAS_TOLERANCE

/obj/item/organ/lungs/ethereal
	name = "aeration reticulum"
	desc = "These exotic lungs seem crunchier than most."
	icon_state = "lungs_ethereal"
	heat_level_1_threshold = FIRE_MINIMUM_TEMPERATURE_TO_SPREAD // 150C or 433k, in line with ethereal max safe body temperature
	heat_level_2_threshold = 473
	heat_level_3_threshold = 1073

/obj/item/organ/lungs/ethereal/ethereal_smoker
	name = "smoker aeration reticulum"
	desc = "A pair of exotic lungs that look pale and sickly, a result from smoking a lot."
	icon_state = "lungs_ethereal_smoker"

	maxHealth = SMOKER_ORGAN_HEALTH
	healing_factor = SMOKER_LUNG_HEALING

/obj/item/organ/lungs/ethereal/Initialize(mapload)
	. = ..()
	add_gas_reaction(/datum/gas/water_vapor, while_present = PROC_REF(consume_water))

/// H2O electrolysis
/obj/item/organ/lungs/ethereal/proc/consume_water(mob/living/carbon/breather, datum/gas_mixture/breath, h2o_pp, old_h2o_pp)
	var/gas_breathed = breath.gases[/datum/gas/water_vapor][MOLES]
	breath.gases[/datum/gas/water_vapor][MOLES] -= gas_breathed
	breath_out.assert_gases(/datum/gas/oxygen, /datum/gas/hydrogen)
	breath_out.gases[/datum/gas/oxygen][MOLES] += gas_breathed
	breath_out.gases[/datum/gas/hydrogen][MOLES] += gas_breathed * 2


/obj/item/organ/lungs/pod
	name = "pod vacuole"
	desc = "A large organelle designed to store oxygen and other important gasses."
	foodtype_flags = PODPERSON_ORGAN_FOODTYPES
	color = COLOR_LIME

#undef BREATH_RELATIONSHIP_INITIAL_GAS
#undef BREATH_RELATIONSHIP_CONVERT
#undef BREATH_RELATIONSHIP_MULTIPLIER
#undef SMOKER_ORGAN_HEALTH
#undef SMOKER_LUNG_HEALING
