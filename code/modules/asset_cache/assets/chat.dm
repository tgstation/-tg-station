/datum/asset/spritesheet_batched/chat
	name = "chat"

/datum/asset/spritesheet_batched/chat/create_spritesheets()
	insert_all_icons("emoji", EMOJI_SET)
	// pre-loading all lanugage icons also helps to avoid meta
	insert_all_icons("language", 'icons/ui/chat/language.dmi')
	// catch languages which are pulling icons from another file
	for(var/datum/language/L as anything in subtypesof(/datum/language))
		var/icon = initial(L.icon)
		if (icon != 'icons/ui/chat/language.dmi')
			var/icon_state = initial(L.icon_state)
			insert_icon("language-[icon_state]", uni_icon(icon, icon_state))
