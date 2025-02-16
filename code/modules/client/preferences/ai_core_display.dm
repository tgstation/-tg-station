/// What to show on the AI screen
/datum/preference/choiced/ai_core_display
	category = PREFERENCE_CATEGORY_NON_CONTEXTUAL
	savefile_identifier = PREFERENCE_CHARACTER
	savefile_key = "preferred_ai_core_display"
	should_generate_icons = TRUE

/datum/preference/choiced/ai_core_display/init_possible_values()
	return GLOB.ai_core_display_screens - "Portrait"

/datum/preference/choiced/ai_core_display/icon_for(value)
	if (value == "Random")
		return uni_icon('icons/mob/silicon/ai.dmi', "questionmark")
	else
		return uni_icon('icons/mob/silicon/ai.dmi', resolve_ai_icon_sync(value))

/datum/preference/choiced/ai_core_display/is_accessible(datum/preferences/preferences)
	if (!..(preferences))
		return FALSE

	return istype(preferences.get_highest_priority_job(), /datum/job/ai)

/datum/preference/choiced/ai_core_display/apply_to_human(mob/living/carbon/human/target, value)
	return
