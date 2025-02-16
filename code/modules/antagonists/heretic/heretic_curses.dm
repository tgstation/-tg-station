/*!
 * Contains all the curses a heretic can cast using their upgraded codex
 */

/datum/heretic_knowledge/curse
	abstract_parent_type = /datum/heretic_knowledge/curse
	/// How far can we curse people?
	var/max_range = 64
	/// The duration of the curse
	var/duration = 1 MINUTES
	/// What color do we outline cursed folk with?
	var/curse_color = "#dadada"
	/// A list of all the fingerprints that were found on our atoms, in our last go at the ritual
	var/list/fingerprints
	/// A list of all the blood samples that were found on our atoms, in our last go at the ritual
	var/list/blood_samples

/datum/heretic_knowledge/curse/recipe_snowflake_check(mob/living/user, list/atoms, list/selected_atoms, turf/loc)
	fingerprints = list()
	blood_samples = list()
	for(var/atom/requirement as anything in atoms)
		for(var/print in GET_ATOM_FINGERPRINTS(requirement))
			fingerprints[print] = TRUE

		for(var/blood in GET_ATOM_BLOOD_DNA(requirement))
			blood_samples[blood] = TRUE

		for(var/datum/reagent/blood/usable_reagent as anything in requirement.reagents?.reagent_list)
			if(!istype(usable_reagent, /datum/reagent/blood))
				continue
			blood_samples[usable_reagent.data["blood_DNA"]] = TRUE

	return TRUE

/datum/heretic_knowledge/curse/on_finished_recipe(mob/living/user, list/selected_atoms,  turf/loc)
	// Potential targets is an assoc list of [names] to [human mob ref].
	var/list/potential_targets = list()

	for(var/datum/mind/crewmember as anything in get_crewmember_minds())
		var/mob/living/carbon/human/human_to_check = crewmember.current
		if(!istype(human_to_check) || human_to_check.stat == DEAD || !human_to_check.dna)
			continue
		var/their_prints = md5(human_to_check.dna.unique_identity)
		var/their_blood = human_to_check.dna.unique_enzymes
		if(!fingerprints[their_prints] && !blood_samples[their_blood])
			continue
		potential_targets["[human_to_check.real_name]"] = human_to_check

	var/chosen_mob = tgui_input_list(user, "Select the victim you wish to curse.", name, sort_list(potential_targets, GLOBAL_PROC_REF(cmp_text_asc)))
	if(isnull(chosen_mob))
		return FALSE

	var/mob/living/carbon/human/to_curse = potential_targets[chosen_mob]
	if(QDELETED(to_curse))
		loc.balloon_alert(user, "ritual failed, invalid choice!")
		return FALSE

	// Yes, you COULD curse yourself, not sure why but you could
	if(to_curse == user)
		var/are_you_sure = tgui_alert(user, "Are you sure you want to curse yourself?", name, list("Yes", "No"))
		if(are_you_sure != "Yes")
			return FALSE

	if(!ask_for_input(user))
		return FALSE

	var/turf/curse_turf = get_turf(to_curse)
	if(!is_valid_z_level(curse_turf, loc) || get_dist(curse_turf, loc) > max_range * 1.5) // Give a bit of leeway on max range for people moving around
		loc.balloon_alert(user, "ritual failed, too far!")
		return FALSE

	if(IS_HERETIC(to_curse) && to_curse != user)
		to_chat(user, span_warning("[to_curse.p_their()] ties to the Mansus are too strong. You are unable to curse [to_curse]."))
		return TRUE

	if(to_curse.can_block_magic(MAGIC_RESISTANCE|MAGIC_RESISTANCE_HOLY, charge_cost = 0))
		to_chat(to_curse, span_warning("A ghastly chill envelops you for a moment, but then it passes."))
		return TRUE

	log_combat(user, to_curse, "cursed via heretic ritual", addition = "([name])")
	var/obj/item/codex_cicatrix/morbus/cursed_book = locate() in selected_atoms
	curse(to_curse, cursed_book)
	to_chat(user, span_hierophant("You cast a [name] upon [to_curse.real_name]."))

	fingerprints = null
	blood_samples = null
	for(var/atom/to_wash in selected_atoms)
		to_wash.wash(CLEAN_SCRUB)
	for(var/atom/to_drain in selected_atoms)
		if(!to_drain.reagents?.reagent_list)
			continue
		for(var/datum/reagent/to_match in to_drain.reagents.reagent_list)
			if(to_match.data["blood_DNA"] != to_curse.dna.unique_enzymes)
				continue
			to_drain.reagents.remove_reagent(to_match.type, 5)
	return TRUE

/**
 * Calls a curse onto [chosen_mob].
 */
/datum/heretic_knowledge/curse/proc/curse(mob/living/carbon/human/chosen_mob, obj/item/codex_cicatrix/morbus/cursing_book)
	SHOULD_CALL_PARENT(TRUE)

	if(duration > 0)
		addtimer(CALLBACK(src, PROC_REF(uncurse), chosen_mob), duration)

	if(!curse_color)
		return

	chosen_mob.add_filter(name, 2, list("type" = "outline", "color" = curse_color, "size" = 1))

/**
 * Removes a curse from [chosen_mob]. Used in timers / callbacks.
 */
/datum/heretic_knowledge/curse/proc/uncurse(mob/living/carbon/human/chosen_mob)
	SHOULD_CALL_PARENT(TRUE)

	if(QDELETED(chosen_mob))
		return

	if(!curse_color)
		return

	chosen_mob.remove_filter(name)

/**
 * Asks the user for input (Optional)
 * Return TRUE to finish the curse
 * Return FALSE to cancel the curse
 */
/datum/heretic_knowledge/curse/proc/ask_for_input(mob/living/user)
	return TRUE

//---- Curse of Paralysis

/datum/heretic_knowledge/curse/paralysis
	abstract_parent_type = /datum/heretic_knowledge/curse/paralysis
	name = "Curse of Paralysis"
	desc = "Allows you to transmute a hatchet and both a left and right leg to cast a curse of immobility on a crew member. \
		While cursed, the victim will be unable to walk. You can additionally supply an item that a victim has touched \
		or is covered in the victim's blood to make the curse last longer."
	gain_text = "The flesh of humanity is weak. Make them bleed. Show them their fragility."

	duration = 5 MINUTES
	curse_color = "#f19a9a"

	research_tree_icon_path = 'icons/ui_icons/antags/heretic/knowledge.dmi'
	research_tree_icon_state = "curse_paralysis"


/datum/heretic_knowledge/curse/paralysis/curse(mob/living/carbon/human/chosen_mob)
	if(chosen_mob.usable_legs <= 0) // What're you gonna do, curse someone who already can't walk?
		to_chat(chosen_mob, span_notice("You feel a slight pain for a moment, but it passes shortly. Odd."))
		return

	to_chat(chosen_mob, span_danger("You suddenly lose feeling in your leg[chosen_mob.usable_legs == 1 ? "":"s"]!"))
	chosen_mob.add_traits(list(TRAIT_PARALYSIS_L_LEG, TRAIT_PARALYSIS_R_LEG), type)
	return ..()

/datum/heretic_knowledge/curse/paralysis/uncurse(mob/living/carbon/human/chosen_mob)
	if(QDELETED(chosen_mob))
		return

	chosen_mob.remove_traits(list(TRAIT_PARALYSIS_L_LEG, TRAIT_PARALYSIS_R_LEG), type)
	if(chosen_mob.usable_legs > 1)
		to_chat(chosen_mob, span_green("You regain feeling in your leg[chosen_mob.usable_legs == 1 ? "":"s"]!"))
	return ..()

//---- Curse of Corrosion

/datum/heretic_knowledge/curse/corrosion
	abstract_parent_type = /datum/heretic_knowledge/curse/corrosion
	name = "Curse of Corrosion"
	desc = "Allows you to transmute wirecutters, a pool of vomit, and a heart to cast a curse of sickness on a crew member. \
		While cursed, the victim will repeatedly vomit while their organs will take constant damage. You can additionally supply an item \
		that a victim has touched or is covered in the victim's blood to make the curse last longer."
	gain_text = "The body of humanity is temporary. Their weaknesses cannot be stopped, like iron falling to rust. Show them all."

	duration = 3 MINUTES
	curse_color = "#c1ffc9"

	research_tree_icon_path = 'icons/ui_icons/antags/heretic/knowledge.dmi'
	research_tree_icon_state = "curse_corrosion"

/datum/heretic_knowledge/curse/corrosion/curse(mob/living/carbon/human/chosen_mob)
	to_chat(chosen_mob, span_danger("You feel very ill..."))
	chosen_mob.apply_status_effect(/datum/status_effect/corrosion_curse)
	return ..()

/datum/heretic_knowledge/curse/corrosion/uncurse(mob/living/carbon/human/chosen_mob)
	if(QDELETED(chosen_mob))
		return

	chosen_mob.remove_status_effect(/datum/status_effect/corrosion_curse)
	to_chat(chosen_mob, span_green("You start to feel better."))
	return ..()

//---- Curse of Transmutation

/datum/heretic_knowledge/curse/transmutation
	abstract_parent_type = /datum/heretic_knowledge/curse/transmutation
	name = "Curse of Transmutation"
	duration = 0 // Infinite curse, it breaks when our codex is destroyed
	curse_color = NONE
	/// What species we are going to turn our victim in to
	var/chosen_species

/datum/heretic_knowledge/curse/transmutation/ask_for_input(mob/living/user)
	var/list/chooseable_races = list()
	for(var/datum/species/species_type as anything in subtypesof(/datum/species))
		if(initial(species_type.changesource_flags) & RACE_SWAP)
			chooseable_races[species_type.name] = species_type

	var/species_name = tgui_input_list(user, "Choose a race", "Choose a race to turn your victim into", chooseable_races)
	if(!species_name)
		return FALSE
	chosen_species = chooseable_races[species_name]
	return ..()

/datum/heretic_knowledge/curse/transmutation/curse(mob/living/carbon/human/chosen_mob, obj/item/codex_cicatrix/morbus/cursing_book)
	if(chosen_mob.dna.species == chosen_species)
		to_chat(chosen_mob, span_warning("You feel your body morph into... itself?"))
		return
	chosen_mob.apply_status_effect(/datum/status_effect/race_swap, chosen_species)
	cursing_book.transmuted_victims += WEAKREF(chosen_mob)
	to_chat(chosen_mob, span_danger("You feel your body morph into a new shape"))
	return ..()

/datum/heretic_knowledge/curse/transmutation/uncurse(mob/living/carbon/human/chosen_mob)
	if(QDELETED(chosen_mob))
		return

	chosen_mob.remove_status_effect(/datum/status_effect/race_swap)

	return ..()

/datum/status_effect/race_swap
	id = "race_swap"
	status_type = STATUS_EFFECT_REPLACE
	alert_type = null
	duration = STATUS_EFFECT_PERMANENT
	tick_interval = STATUS_EFFECT_NO_TICK
	/// What species were we before this effect was ever applied on us
	var/old_species

/datum/status_effect/race_swap/on_creation(mob/living/new_owner, datum/species/new_species)
	. = ..()
	owner.set_species(new_species)

/datum/status_effect/race_swap/on_apply()
	if(!iscarbon(owner))
		return FALSE
	var/mob/living/carbon/carbon_owner = owner
	if(!old_species)
		old_species = carbon_owner.dna.species
	return ..()

/datum/status_effect/race_swap/be_replaced()
	owner.set_species(old_species)
	return ..()

/datum/status_effect/race_swap/on_remove()
	. = ..()
	owner.set_species(old_species)

//---- Curse of Indulgence

/datum/heretic_knowledge/curse/indulgence
	abstract_parent_type = /datum/heretic_knowledge/curse/indulgence
	name = "Curse of Indulgence"
	duration = 8 MINUTES
	curse_color = COLOR_MAROON

/datum/heretic_knowledge/curse/indulgence/curse(mob/living/carbon/human/chosen_mob)
	chosen_mob.gain_trauma(/datum/brain_trauma/severe/flesh_desire, TRAUMA_RESILIENCE_MAGIC)
	chosen_mob.nutrition = NUTRITION_LEVEL_STARVING
	return ..()

/datum/heretic_knowledge/curse/indulgence/uncurse(mob/living/carbon/human/chosen_mob)
	if(QDELETED(chosen_mob))
		return
	chosen_mob.cure_trauma_type(/datum/brain_trauma/severe/flesh_desire, TRAUMA_RESILIENCE_MAGIC)
	return ..()
