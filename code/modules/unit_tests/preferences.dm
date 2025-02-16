/// Requires all preferences to implement required methods.
/datum/unit_test/preferences_implement_everything

/datum/unit_test/preferences_implement_everything/Run()
	var/datum/preferences/preferences = new(new /datum/client_interface)
	var/mob/living/carbon/human/human = allocate(/mob/living/carbon/human/consistent)

	for (var/preference_type in GLOB.preference_entries)
		var/datum/preference/preference = GLOB.preference_entries[preference_type]
		if (preference.savefile_identifier == PREFERENCE_CHARACTER)
			preference.apply_to_human(human, preference.create_informed_default_value(preferences))

		if (istype(preference, /datum/preference/choiced))
			var/datum/preference/choiced/choiced_preference = preference
			choiced_preference.init_possible_values()

		// Smoke-test is_valid
		preference.is_valid(TRUE)
		preference.is_valid("string")
		preference.is_valid(100)
		preference.is_valid(list(1, 2, 3))

/// Requires all preferences to have a valid, unique savefile_identifier.
/datum/unit_test/preferences_valid_savefile_key

/datum/unit_test/preferences_valid_savefile_key/Run()
	var/list/known_savefile_keys = list()

	for (var/preference_type in GLOB.preference_entries)
		var/datum/preference/preference = GLOB.preference_entries[preference_type]
		if (!istext(preference.savefile_key))
			TEST_FAIL("[preference_type] has an invalid savefile_key.")

		if (preference.savefile_key in known_savefile_keys)
			TEST_FAIL("[preference_type] has a non-unique savefile_key `[preference.savefile_key]`!")

		known_savefile_keys += preference.savefile_key

/// Requires all main features have a main_feature_name
/datum/unit_test/preferences_valid_main_feature_name

/datum/unit_test/preferences_valid_main_feature_name/Run()
	for (var/preference_type in GLOB.preference_entries)
		var/datum/preference/choiced/preference = GLOB.preference_entries[preference_type]
		if (!istype(preference))
			continue

		if (preference.category != PREFERENCE_CATEGORY_FEATURES && preference.category != PREFERENCE_CATEGORY_CLOTHING)
			continue

		TEST_ASSERT(!isnull(preference.main_feature_name), "Preference [preference_type] does not have a main_feature_name set!")

/// Validates that every choiced preference with should_generate_icons implements icon_for,
/// and that every one that doesn't, doesn't.
/datum/unit_test/preferences_should_generate_icons_sanity

/datum/unit_test/preferences_should_generate_icons_sanity/Run()
	for (var/preference_type in GLOB.preference_entries)
		var/datum/preference/choiced/choiced_preference = GLOB.preference_entries[preference_type]
		if (!istype(choiced_preference) || choiced_preference.abstract_type == preference_type)
			continue

		var/list/values = choiced_preference.get_choices()

		if (choiced_preference.should_generate_icons)
			for (var/value in values)
				var/icon = choiced_preference.icon_for(value)
				TEST_ASSERT(istype(icon, /datum/universal_icon) || ispath(icon), "[preference_type] gave [icon] as an icon for [value], which is not a valid value")
		else
			var/errored = FALSE

			try
				choiced_preference.icon_for(values[1])
			catch
				errored = TRUE

			TEST_ASSERT(errored, "[preference_type] implemented icon_for, but does not have should_generate_icons = TRUE")
