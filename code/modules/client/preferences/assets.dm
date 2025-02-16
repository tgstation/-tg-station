/// Assets generated from `/datum/preference` icons
/datum/asset/spritesheet_batched/preferences
	name = "preferences"
	early = TRUE

/datum/asset/spritesheet_batched/preferences/create_spritesheets()
	for (var/preference_key in GLOB.preference_entries_by_key)
		var/datum/preference/choiced/preference = GLOB.preference_entries_by_key[preference_key]
		if (!istype(preference))
			continue

		if (!preference.should_generate_icons)
			continue

		for (var/preference_value in preference.get_choices())
			var/create_icon_of = preference.icon_for(preference_value)

			var/datum/universal_icon/icon

			if (ispath(create_icon_of, /atom))
				var/atom/atom_icon_source = create_icon_of
				icon = uni_icon(initial(atom_icon_source.icon), initial(atom_icon_source.icon_state))
			else if (istype(create_icon_of, /datum/universal_icon))
				icon = create_icon_of
			else if (isicon(create_icon_of))
				CRASH("Icon given for preference [preference_key]:[preference_value]. This is not supported anymore, provide a /datum/universal_icon instead.")
			else
				CRASH("[create_icon_of] is an invalid preference value (from [preference_key]:[preference_value]).")
			// There's no cost associated with inserting uni_icons, so just insert them immediately.
			var/spritesheet_key = preference.get_spritesheet_key(preference.serialize(preference_value))
			insert_icon(spritesheet_key, icon)

/// Returns the key that will be used in the spritesheet for a given value.
/datum/preference/proc/get_spritesheet_key(value)
	return "[savefile_key]___[sanitize_css_class_name(value)]"

/// Sends information needed for shared details on individual preferences
/datum/asset/json/preferences
	name = "preferences"

/datum/asset/json/preferences/generate()
	var/list/preference_data = list()

	for (var/middleware_type in subtypesof(/datum/preference_middleware))
		var/datum/preference_middleware/middleware = new middleware_type
		var/data = middleware.get_constant_data()
		if (!isnull(data))
			preference_data[middleware.key] = data

		qdel(middleware)

	for (var/preference_type in GLOB.preference_entries)
		var/datum/preference/preference_entry = GLOB.preference_entries[preference_type]
		var/data = preference_entry.compile_constant_data()
		if (!isnull(data))
			preference_data[preference_entry.savefile_key] = data

	return preference_data
