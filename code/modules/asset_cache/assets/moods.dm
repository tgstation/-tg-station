/datum/asset/spritesheet_batched/moods
	name = "moods"

/datum/asset/spritesheet_batched/moods/create_spritesheets()
	var/list/mood_colors = list(
		"mood1" = "#f15d36",
		"mood2" = "#f38943",
		"mood3" = "#f38943",
		"mood4" = "#dfa65b",
		"mood5" = "#4b96c4",
		"mood6" = "#86d656",
		"mood7" = "#2eeb9a",
		"mood8" = "#2eeb9a",
		"mood9" = "#2eeb9a",
	)
	for(var/target_to_insert in mood_colors)
		var/blended_color = mood_colors[target_to_insert]
		insert_icon(target_to_insert, uni_icon('icons/hud/screen_gen.dmi', target_to_insert, color=blended_color))
