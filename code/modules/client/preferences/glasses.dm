/datum/preference/choiced/glasses
	category = PREFERENCE_CATEGORY_MANUALLY_RENDERED
	savefile_key = "glasses"
	savefile_identifier = PREFERENCE_CHARACTER
	should_generate_icons = TRUE

/datum/preference/choiced/glasses/create_default_value()
	return "Random"

/datum/preference/choiced/glasses/init_possible_values()
	return assoc_to_keys(GLOB.nearsighted_glasses) + "Random"

/datum/preference/choiced/glasses/icon_for(value)
	if (value == "Random")
		return uni_icon('icons/effects/random_spawners.dmi', "questionmark")
	else
		return uni_icon('icons/obj/clothing/glasses.dmi', "glasses_[LOWER_TEXT(value)]")

/datum/preference/choiced/glasses/is_accessible(datum/preferences/preferences)
	if (!..(preferences))
		return FALSE

	return "Nearsighted" in preferences.all_quirks

/datum/preference/choiced/glasses/apply_to_human(mob/living/carbon/human/target, value)
	return
