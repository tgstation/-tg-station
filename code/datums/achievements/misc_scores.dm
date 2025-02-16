///How many times did we survive being a cripple?
/datum/award/score/hardcore_random
	name = "Hardcore random points"
	desc = "Well, I might be a blind, deaf, crippled guy, but hey, at least I'm alive."
	database_id = HARDCORE_RANDOM_SCORE

///How many maintenance pills did you eat?
/datum/award/score/maintenance_pill
	name = "Maintenance Pills Consumed"
	desc = "Wait why?"
	database_id = MAINTENANCE_PILL_SCORE

///How high of a score on the Intento did we get?
/datum/award/score/intento_score
	name = "Intento Score"
	desc = "A blast from the future?"
	database_id = INTENTO_SCORE

/// What's the highest amount of style points we've gotten?
/datum/award/score/style_score
	name = "Style Score"
	desc = "You might not be a robot, but you were damn close."
	database_id = STYLE_SCORE

/datum/award/score/progress/fish
	name = "Fish Species Caught"
	desc = "How many different species of fish you've caught so far. Gotta fish 'em all."
	database_id = FISH_SCORE
	var/list/early_entries_to_validate = list()

/datum/award/score/progress/fish/New()
	. = ..()
	RegisterSignal(SSfishing, COMSIG_SUBSYSTEM_POST_INITIALIZE, PROC_REF(validate_early_joiners))

/datum/award/score/progress/fish/get_table()
	return "fish_progress"

/datum/award/score/progress/fish/proc/validate_early_joiners(datum/source)
	for(var/client/client as anything in GLOB.clients)
		var/datum/achievement_data/holder = client.persistent_client.achievements
		if(!holder?.initialized)
			continue

		var/list/entries = holder.data[/datum/award/score/progress/fish]
		var/list_copied = FALSE
		for(var/fish_id in entries)
			if(SSfishing.catchable_fish[fish_id])
				continue

			//make a new list, unbound from the cached awards data, so that the score can be updated at the end of the round.
			if(!list_copied)
				entries = entries.Copy()
				holder.data[/datum/award/score/progress/fish] = entries
				list_copied = TRUE
			entries -= fish_id

/datum/award/score/progress/fish/validate_entries(list/entries, list/validated_entries)
	. = ..()
	if(!SSfishing.initialized)
		return
	for(var/fish_id in validated_entries)
		if(!(SSfishing.catchable_fish[fish_id]))
			validated_entries -= fish_id
			. = FALSE

/datum/award/score/progress/fish/get_progress(datum/achievement_data/holder)
	var/list/data = list(
		"name" = "Fishdex",
		"percent" = 0,
		"value_text" = "Subsystems still initializing...",
		"entries" = list(),
	)
	if(!SSfishing.initialized)
		return data
	var/list/catched_fish = holder.data[type]
	var/catched_len = length(catched_fish)
	var/catchable_len = length(SSfishing.catchable_fish)
	data["percent"] = catched_len/catchable_len
	data["value_text"] = "[catched_len] / [catchable_len]"
	var/index = 1
	var/max_zeros = round(log(10, catchable_len))
	for(var/fish_id in SSfishing.catchable_fish)
		var/obj/item/fish/fish = SSfishing.catchable_fish[fish_id]
		var/catched = (fish_id in catched_fish)
		var/entry_name = "◦[prefix_zeros_to_number(index, max_zeros)]◦ [catched ? full_capitalize(initial(fish.name)) : "??????" ]"
		var/list/icon_dimensions = get_icon_dimensions(initial(fish.icon))
		data["entries"] += list(list(
			"name" = entry_name,
			"icon" = catched ? SSfishing.cached_fish_icons[fish] : SSfishing.cached_unknown_fish_icons[fish],
			"height" = icon_dimensions["height"] * 2,
			"width" = icon_dimensions["width"] * 2,
		))
		index++
	return data
