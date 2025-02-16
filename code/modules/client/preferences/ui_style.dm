/// UI style preference
/datum/preference/choiced/ui_style
	category = PREFERENCE_CATEGORY_GAME_PREFERENCES
	savefile_identifier = PREFERENCE_PLAYER
	savefile_key = "UI_style"
	should_generate_icons = TRUE

/datum/preference/choiced/ui_style/init_possible_values()
	return assoc_to_keys(GLOB.available_ui_styles)

/datum/preference/choiced/ui_style/icon_for(value)
	var/ui_icons = GLOB.available_ui_styles[value]

	var/datum/universal_icon/icon = uni_icon(ui_icons, "hand_l")
	icon.crop(1 - ICON_SIZE_X, 1, ICON_SIZE_Y, ICON_SIZE_X)
	icon.blend_icon(uni_icon(ui_icons, "hand_r"), ICON_OVERLAY)

	return icon

/datum/preference/choiced/ui_style/create_default_value()
	return GLOB.available_ui_styles[1]

/datum/preference/choiced/ui_style/apply_to_client(client/client, value)
	client.mob?.hud_used?.update_ui_style(ui_style2icon(value))
