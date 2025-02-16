// Priorities must be in order!
/// The default priority level
#define PREFERENCE_PRIORITY_DEFAULT 1

/// The priority at which species runs, needed for external organs to apply properly.
#define PREFERENCE_PRIORITY_SPECIES 2

/**
 * Some preferences get applied directly to bodyparts (anything head_flags related right now).
 * These must apply after species, as species gaining might replace the bodyparts of the human.
 */
#define PREFERENCE_PRIORITY_BODYPARTS 3

/// The priority at which gender is determined, needed for proper randomization.
#define PREFERENCE_PRIORITY_GENDER 4

/// The priority at which body type is decided, applied after gender so we can
/// support the "use gender" option.
#define PREFERENCE_PRIORITY_BODY_TYPE 5

/// Used for preferences that rely on body setup being finalized.
#define PREFERENCE_PRORITY_LATE_BODY_TYPE 6

/// Equpping items based on preferences.
/// Should happen after species and body type to make sure it looks right.
/// Mostly redundant, but a safety net for saving/loading.
#define PREFERENCE_PRIORITY_LOADOUT 7

/// The priority at which names are decided, needed for proper randomization.
#define PREFERENCE_PRIORITY_NAMES 8

/// Preferences that aren't names, but change the name changes set by PREFERENCE_PRIORITY_NAMES.
#define PREFERENCE_PRIORITY_NAME_MODIFICATIONS 9

/// The maximum preference priority, keep this updated, but don't use it for `priority`.
#define MAX_PREFERENCE_PRIORITY PREFERENCE_PRIORITY_NAME_MODIFICATIONS

/// For choiced preferences, this key will be used to set display names in constant data.
#define CHOICED_PREFERENCE_DISPLAY_NAMES "display_names"

/// For main feature preferences, this key refers to a feature considered supplemental.
/// For instance, hair color being supplemental to hair.
#define SUPPLEMENTAL_FEATURE_KEY "supplemental_feature"

/// An assoc list list of types to instantiated `/datum/preference` instances
GLOBAL_LIST_INIT(preference_entries, init_preference_entries())

/// An assoc list of preference entries by their `savefile_key`
GLOBAL_LIST_INIT(preference_entries_by_key, init_preference_entries_by_key())

/proc/init_preference_entries()
	var/list/output = list()
	for (var/datum/preference/preference_type as anything in subtypesof(/datum/preference))
		if (initial(preference_type.abstract_type) == preference_type)
			continue
		output[preference_type] = new preference_type
	return output

/proc/init_preference_entries_by_key()
	var/list/output = list()
	for (var/datum/preference/preference_type as anything in subtypesof(/datum/preference))
		if (initial(preference_type.abstract_type) == preference_type)
			continue
		output[initial(preference_type.savefile_key)] = GLOB.preference_entries[preference_type]
	return output

/// Returns a flat list of preferences in order of their priority
/proc/get_preferences_in_priority_order()
	var/list/preferences[MAX_PREFERENCE_PRIORITY]

	for (var/preference_type in GLOB.preference_entries)
		var/datum/preference/preference = GLOB.preference_entries[preference_type]
		LAZYADD(preferences[preference.priority], preference)

	var/list/flattened = list()
	for (var/index in 1 to MAX_PREFERENCE_PRIORITY)
		flattened += preferences[index]
	return flattened

/// Represents an individual preference.
/datum/preference
	/// The key inside the savefile to use.
	/// This is also sent to the UI.
	/// Once you pick this, don't change it.
	var/savefile_key

	/// The category of preference, for use by the PreferencesMenu.
	/// This isn't used for anything other than as a key for UI data.
	/// It is up to the PreferencesMenu UI itself to interpret it.
	var/category = "misc"

	/// Do not instantiate if type matches this.
	var/abstract_type = /datum/preference

	/// What savefile should this preference be read from?
	/// Valid values are PREFERENCE_CHARACTER and PREFERENCE_PLAYER.
	/// See the documentation in [code/__DEFINES/preferences.dm].
	var/savefile_identifier

	/// The priority of when to apply this preference.
	/// Used for when you need to rely on another preference.
	var/priority = PREFERENCE_PRIORITY_DEFAULT

	/// If set, will be available to randomize, but only if the preference
	/// is for PREFERENCE_CHARACTER.
	var/can_randomize = TRUE

	/// If randomizable (PREFERENCE_CHARACTER and can_randomize), whether
	/// or not to enable randomization by default.
	/// This doesn't mean it'll always be random, but rather if a player
	/// DOES have random body on, will this already be randomized?
	var/randomize_by_default = TRUE

	/// If the selected species has this in its /datum/species/body_markings,
	/// will show the feature as selectable.
	var/relevant_body_markings = null

	/// If the selected species has this in its /datum/species/inherent_traits,
	/// will show the feature as selectable.
	var/relevant_inherent_trait = null

	/// If the selected species has this in its /datum/species/var/external_organs,
	/// will show the feature as selectable.
	var/relevant_external_organ = null

	/// If the selected species has this head_flag by default,
	/// will show the feature as selectable.
	var/relevant_head_flag = null

/// Called on the saved input when retrieving.
/// Also called by the value sent from the user through UI. Do not trust it.
/// Input is the value inside the savefile, output is to tell other code
/// what the value is.
/// This is useful either for more optimal data saving or for migrating
/// older data.
/// Must be overridden by subtypes.
/// Can return null if no value was found.
/datum/preference/proc/deserialize(input, datum/preferences/preferences)
	SHOULD_NOT_SLEEP(TRUE)
	SHOULD_CALL_PARENT(FALSE)
	CRASH("`deserialize()` was not implemented on [type]!")

/// Called on the input while saving.
/// Input is the current value, output is what to save in the savefile.
/datum/preference/proc/serialize(input)
	SHOULD_NOT_SLEEP(TRUE)
	return input

/// Produce a default, potentially random value for when no value for this
/// preference is found in the savefile.
/// Either this or create_informed_default_value must be overriden by subtypes.
/datum/preference/proc/create_default_value()
	SHOULD_NOT_SLEEP(TRUE)
	SHOULD_CALL_PARENT(FALSE)
	CRASH("`create_default_value()` was not implemented on [type]!")

/// Produce a default, potentially random value for when no value for this
/// preference is found in the savefile.
/// Unlike create_default_value(), will provide the preferences object if you
/// need to use it.
/// If not overriden, will call create_default_value() instead.
/datum/preference/proc/create_informed_default_value(datum/preferences/preferences)
	return create_default_value()

/// Produce a random value for the purposes of character randomization.
/// Will just create a default value by default.
/datum/preference/proc/create_random_value(datum/preferences/preferences)
	return create_informed_default_value(preferences)

/// Returns whether or not a preference can be randomized.
/datum/preference/proc/is_randomizable()
	SHOULD_NOT_OVERRIDE(TRUE)
	return savefile_identifier == PREFERENCE_CHARACTER && can_randomize

/// Given a savefile, return either the saved data or an acceptable default.
/// This will write to the savefile if a value was not found with the new value.
/datum/preference/proc/read(list/save_data, datum/preferences/preferences)
	SHOULD_NOT_OVERRIDE(TRUE)

	var/value

	if (!isnull(save_data))
		value = save_data[savefile_key]

	if (isnull(value))
		return null
	else
		return deserialize(value, preferences)

/// Given a savefile, writes the inputted value.
/// Returns TRUE for a successful application.
/// Return FALSE if it is invalid.
/datum/preference/proc/write(list/save_data, value)
	SHOULD_NOT_OVERRIDE(TRUE)

	if (!is_valid(value))
		return FALSE

	if (!isnull(save_data))
		save_data[savefile_key] = serialize(value)

	return TRUE

/// Apply this preference onto the given client.
/// Called when the savefile_identifier == PREFERENCE_PLAYER.
/datum/preference/proc/apply_to_client(client/client, value)
	SHOULD_NOT_SLEEP(TRUE)
	SHOULD_CALL_PARENT(FALSE)
	return

/// Fired when the preference is updated.
/// Calls apply_to_client by default, but can be overridden.
/datum/preference/proc/apply_to_client_updated(client/client, value)
	SHOULD_NOT_SLEEP(TRUE)
	apply_to_client(client, value)

/// Apply this preference onto the given human.
/// Must be overriden by subtypes.
/// Called when the savefile_identifier == PREFERENCE_CHARACTER.
/datum/preference/proc/apply_to_human(mob/living/carbon/human/target, value)
	SHOULD_NOT_SLEEP(TRUE)
	SHOULD_CALL_PARENT(FALSE)
	CRASH("`apply_to_human()` was not implemented for [type]!")

/// Returns which savefile to use for a given savefile identifier
/datum/preferences/proc/get_save_data_for_savefile_identifier(savefile_identifier)
	RETURN_TYPE(/list)

	if (!parent)
		return null
	if(!savefile)
		CRASH("Attempted to get the savedata for [savefile_identifier] of [parent] without a savefile. This should have been handled by load_preferences()")

	// Both of these will cache savefiles, but only for a tick.
	// This is because storing a savefile will lock it, causing later issues down the line.
	// Do not change them to addtimer, since the timer SS might not be running at this time.
	switch (savefile_identifier)
		if (PREFERENCE_CHARACTER)
			return savefile.get_entry("character[default_slot]")
		if (PREFERENCE_PLAYER)
			return savefile.get_entry()
		else
			CRASH("Unknown savefile identifier [savefile_identifier]")

/// Read a /datum/preference type and return its value.
/// This will write to the savefile if a value was not found with the new value.
/datum/preferences/proc/read_preference(preference_type)
	var/datum/preference/preference_entry = GLOB.preference_entries[preference_type]
	if (isnull(preference_entry))
		var/extra_info = ""

		// Current initializing subsystem is important to know because it might be a problem with
		// things running pre-assets-initialization.
		if (!isnull(Master.current_initializing_subsystem))
			extra_info = "Info was attempted to be retrieved while [Master.current_initializing_subsystem] was initializing."
		else if (!MC_RUNNING())
			extra_info = "Info was attempted to be retrieved before the MC started, but not while it was actively initializing a subsystem"

		CRASH("Preference type `[preference_type]` is invalid! [extra_info]")

	if (preference_type in value_cache)
		return value_cache[preference_type]

	var/value = preference_entry.read(get_save_data_for_savefile_identifier(preference_entry.savefile_identifier), src)
	if (isnull(value))
		value = preference_entry.create_informed_default_value(src)
		if (write_preference(preference_entry, value))
			return value
		else
			CRASH("Couldn't write the default value for [preference_type] (received [value])")
	value_cache[preference_type] = value
	return value

/// Set a /datum/preference entry.
/// Returns TRUE for a successful preference application.
/// Returns FALSE if it is invalid.
/datum/preferences/proc/write_preference(datum/preference/preference, preference_value)
	var/save_data = get_save_data_for_savefile_identifier(preference.savefile_identifier)
	var/new_value = preference.deserialize(preference_value, src)
	var/success = preference.write(save_data, new_value)
	if (success)
		value_cache[preference.type] = new_value
	return success

/// Will perform an update on the preference, but not write to the savefile.
/// This will, for instance, update the character preference view.
/// Performs sanity checks.
/datum/preferences/proc/update_preference(datum/preference/preference, preference_value)
	if (!preference.is_accessible(src))
		return FALSE

	var/new_value = preference.deserialize(preference_value, src)
	var/success = preference.write(null, new_value)

	if (!success)
		return FALSE

	recently_updated_keys |= preference.type
	value_cache[preference.type] = new_value

	if (preference.savefile_identifier == PREFERENCE_PLAYER)
		preference.apply_to_client_updated(parent, read_preference(preference.type))
	else
		character_preview_view?.update_body()

	return TRUE

/// Checks that a given value is valid.
/// Must be overriden by subtypes.
/// Any type can be passed through.
/datum/preference/proc/is_valid(value)
	SHOULD_NOT_SLEEP(TRUE)
	SHOULD_CALL_PARENT(FALSE)
	CRASH("`is_valid()` was not implemented for [type]!")

/// Returns data to be sent to users in the menu
/datum/preference/proc/compile_ui_data(mob/user, value)
	SHOULD_NOT_SLEEP(TRUE)

	return serialize(value)

/// Returns data compiled into the preferences JSON asset
/datum/preference/proc/compile_constant_data()
	SHOULD_NOT_SLEEP(TRUE)

	return null

/// Returns whether or not this preference is accessible.
/// If FALSE, will not show in the UI and will not be editable (by update_preference).
/datum/preference/proc/is_accessible(datum/preferences/preferences)
	SHOULD_CALL_PARENT(TRUE)
	SHOULD_NOT_SLEEP(TRUE)

	if ( \
		!isnull(relevant_inherent_trait) \
		|| !isnull(relevant_external_organ) \
		|| !isnull(relevant_head_flag) \
		|| !isnull(relevant_body_markings) \
	)
		var/species_type = preferences.read_preference(/datum/preference/choiced/species)

		var/datum/species/species = GLOB.species_prototypes[species_type]
		if (!(savefile_key in species.get_features()))
			return FALSE

	if (!should_show_on_page(preferences.current_window))
		return FALSE

	return TRUE

/// Returns whether or not, given the PREFERENCE_TAB_*, this preference should
/// appear.
/datum/preference/proc/should_show_on_page(preference_tab)
	var/is_on_character_page = preference_tab == PREFERENCE_TAB_CHARACTER_PREFERENCES
	var/is_character_preference = savefile_identifier == PREFERENCE_CHARACTER
	return is_on_character_page == is_character_preference

/// A preference that is a choice of one option among a fixed set.
/// Used for preferences such as clothing.
/datum/preference/choiced
	/// If this is TRUE, an icon will be generated for every value.
	/// If you implement this, you must implement `icon_for(value)` for every possible value.
	var/should_generate_icons = FALSE

	var/list/cached_values

	/// If the preference is a main feature (PREFERENCE_CATEGORY_FEATURES or PREFERENCE_CATEGORY_CLOTHING)
	/// this is the name of the feature that will be presented.
	var/main_feature_name

	abstract_type = /datum/preference/choiced

/// Returns a list of every possible value.
/// The first time this is called, will run `init_values()`.
/// Return value can be in the form of:
/// - A flat list of raw values, such as list(MALE, FEMALE, PLURAL).
/// - An assoc list of raw values to atoms/icons.
/datum/preference/choiced/proc/get_choices()
	// Override `init_values()` instead.
	SHOULD_NOT_OVERRIDE(TRUE)

	if (isnull(cached_values))
		cached_values = init_possible_values()
		ASSERT(cached_values.len)

	return cached_values

/// Returns a list of every possible value, serialized.
/datum/preference/choiced/proc/get_choices_serialized()
	// Override `init_values()` instead.
	SHOULD_NOT_OVERRIDE(TRUE)

	var/list/serialized_choices = list()

	for (var/choice in get_choices())
		serialized_choices += serialize(choice)

	return serialized_choices

/// Returns a list of every possible value.
/// This must be overriden by `/datum/preference/choiced` subtypes.
/// If `should_generate_icons` is TRUE, then you will also need to implement `icon_for(value)`
/// for every possible value.
/datum/preference/choiced/proc/init_possible_values()
	CRASH("`init_possible_values()` was not implemented for [type]!")

/// When `should_generate_icons` is TRUE, this proc is called for every value.
/// It can return either an /datum/universal_icon (see uni_icon() DEFINE) or a typepath to an atom to create.
/datum/preference/choiced/proc/icon_for(value)
	SHOULD_CALL_PARENT(FALSE)
	SHOULD_NOT_SLEEP(TRUE)
	CRASH("`icon_for()` was not implemented for [type], even though should_generate_icons = TRUE!")

/datum/preference/choiced/is_valid(value)
	return value in get_choices()

/datum/preference/choiced/deserialize(input, datum/preferences/preferences)
	return sanitize_inlist(input, get_choices(), create_default_value())

/datum/preference/choiced/create_default_value()
	return pick(get_choices())

/datum/preference/choiced/compile_constant_data()
	var/list/data = list()

	var/list/choices = list()

	for (var/choice in get_choices())
		choices += choice

	data["choices"] = choices

	if (should_generate_icons)
		var/list/icons = list()

		for (var/choice in choices)
			icons[choice] = get_spritesheet_key(choice)

		data["icons"] = icons

	if (!isnull(main_feature_name))
		data["name"] = main_feature_name

	return data

/// A preference that represents an RGB color of something.
/// Will give the value as 6 hex digits, without a hash.
/datum/preference/color
	abstract_type = /datum/preference/color

/datum/preference/color/deserialize(input, datum/preferences/preferences)
	return sanitize_hexcolor(input)

/datum/preference/color/create_default_value()
	return random_color()

/datum/preference/color/serialize(input)
	return sanitize_hexcolor(input)

/datum/preference/color/is_valid(value)
	return findtext(value, GLOB.is_color)

/// A numeric preference with a minimum and maximum value
/datum/preference/numeric
	/// The minimum value
	var/minimum

	/// The maximum value
	var/maximum

	/// The step of the number, such as 1 for integers or 0.5 for half-steps.
	var/step = 1

	abstract_type = /datum/preference/numeric

/datum/preference/numeric/deserialize(input, datum/preferences/preferences)
	if(istext(input)) // Sometimes TGUI will return a string instead of a number, so we take that into account.
		input = text2num(input) // Worst case, it's null, it'll just use create_default_value()
	return sanitize_float(input, minimum, maximum, step, create_default_value())

/datum/preference/numeric/serialize(input)
	return sanitize_float(input, minimum, maximum, step, create_default_value())

/datum/preference/numeric/create_default_value()
	return rand(minimum, maximum)

/datum/preference/numeric/is_valid(value)
	return isnum(value) && value >= round(minimum, step) && value <= round(maximum, step)

/datum/preference/numeric/compile_constant_data()
	return list(
		"minimum" = minimum,
		"maximum" = maximum,
		"step" = step,
	)

/// A preference whose value is always TRUE or FALSE
/datum/preference/toggle
	abstract_type = /datum/preference/toggle

	/// The default value of the toggle, if create_default_value is not specified
	var/default_value = TRUE

/datum/preference/toggle/create_default_value()
	return default_value

/datum/preference/toggle/deserialize(input, datum/preferences/preferences)
	return !!input

/datum/preference/toggle/is_valid(value)
	return value == TRUE || value == FALSE


/// A string-based preference accepting arbitrary string values entered by the user, with a maximum length.
/datum/preference/text
	abstract_type = /datum/preference/text

	/// What is the maximum length of the value allowed in this field?
	var/maximum_value_length = 256

	/// Should we strip HTML the input or simply restrict it to the maximum_value_length?
	var/should_strip_html = TRUE


/datum/preference/text/deserialize(input, datum/preferences/preferences)
	return should_strip_html ? STRIP_HTML_SIMPLE(input, maximum_value_length) : copytext(input, 1, maximum_value_length)

/datum/preference/text/create_default_value()
	return ""

/datum/preference/text/is_valid(value)
	return istext(value) && length(value) < maximum_value_length

/datum/preference/text/compile_constant_data()
	return list("maximum_length" = maximum_value_length)
