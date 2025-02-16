/// What to show on the AI hologram
/datum/preference/choiced/ai_hologram_display
	category = PREFERENCE_CATEGORY_NON_CONTEXTUAL
	savefile_identifier = PREFERENCE_CHARACTER
	savefile_key = "preferred_ai_hologram_display"
	should_generate_icons = TRUE

/datum/preference/choiced/ai_hologram_display/init_possible_values()
	return assoc_to_keys(GLOB.ai_hologram_icons) + "Random"

/datum/preference/choiced/ai_hologram_display/icon_for(value)
	if (value == "Random")
		return uni_icon('icons/mob/silicon/ai.dmi', "questionmark")
	else
		return uni_icon(GLOB.ai_hologram_icons[value], GLOB.ai_hologram_icon_state[value])

/datum/preference/choiced/ai_hologram_display/is_accessible(datum/preferences/preferences)
	if (!..(preferences))
		return FALSE

	return istype(preferences.get_highest_priority_job(), /datum/job/ai)

/datum/preference/choiced/ai_hologram_display/apply_to_human(mob/living/carbon/human/target, value)
	return
