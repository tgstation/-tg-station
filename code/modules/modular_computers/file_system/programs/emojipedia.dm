/// A tablet app that lets anyone see all the valid emoji they can send via a PDA message (and even OOC!)
/datum/computer_file/program/emojipedia
	filename = "emojipedia"
	filedesc = "EmojiPedia"
	downloader_category = PROGRAM_CATEGORY_DEVICE // we want everyone to be able to access this application, since everyone can send emoji via PDA messages
	program_open_overlay = "generic"
	extended_desc = "This program allows you to view all the emojis you can send via PDA messages."
	size = 3
	tgui_id = "NtosEmojipedia"
	program_icon = "icons"
	/// Store the list of potential emojis here.
	var/static/list/emoji_list = icon_states(icon(EMOJI_SET))

/datum/computer_file/program/emojipedia/New()
	. = ..()
	// Sort the emoji list so it's easier to find things and we don't have to keep sorting on ui_data since the number of emojis can not change in-game.
	sortTim(emoji_list, /proc/cmp_text_asc)

/datum/computer_file/program/emojipedia/ui_static_data(mob_user)
	var/list/data = list()
	for(var/emoji in emoji_list)
		data["emoji_list"] += list(list(
			"name" = emoji,
		))

	return data

/datum/computer_file/program/emojipedia/ui_assets(mob/user)
	return list(
		get_asset_datum(/datum/asset/spritesheet_batched/emojipedia),
	)
