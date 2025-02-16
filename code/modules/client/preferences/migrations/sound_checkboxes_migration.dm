/** Pull request: #86932 Sound mixer part 1
 *
 * Multiplies boolean sound prefs by 100
 *
 * Changed ambience tick pref to numeric slider
 * Changed ship ambience tick pref to numeric slider
 * Changed lobby music tick pref to numeric slider
 * Changed Radio noise tick pref to numeric slider
 */

/datum/preferences/proc/migrate_boolean_sound_prefs_to_default_volume()
	var/ambience_pref = savefile.get_entry("sound_ambience_volume")
	var/ship_ambience_pref = savefile.get_entry("sound_ship_ambience_volume")
	var/lobby_music_pref = savefile.get_entry("sound_lobby_volume")
	var/radio_noise_pref = savefile.get_entry("sound_radio_noise")
	write_preference(GLOB.preference_entries[/datum/preference/numeric/volume/sound_ambience_volume], ambience_pref*100)
	write_preference(GLOB.preference_entries[/datum/preference/numeric/volume/sound_ship_ambience_volume], ship_ambience_pref*100)
	write_preference(GLOB.preference_entries[/datum/preference/numeric/volume/sound_lobby_volume], lobby_music_pref*100)
	write_preference(GLOB.preference_entries[/datum/preference/numeric/volume/sound_radio_noise], radio_noise_pref*100)
	return


/datum/preferences/proc/migrate_boolean_sound_prefs_to_default_volume_v2()
	var/list/entries = list(
		/datum/preference/numeric/volume/sound_ai_vox = savefile.get_entry("sound_ai_vox"),
		/datum/preference/numeric/volume/sound_midi = savefile.get_entry("sound_midi"),
		/datum/preference/numeric/volume/sound_instruments = savefile.get_entry("sound_instruments"),
		/datum/preference/numeric/volume/sound_ambience_volume = savefile.get_entry("sound_ambience_volume"),
		/datum/preference/numeric/volume/sound_ship_ambience_volume = savefile.get_entry("sound_ship_ambience_volume"),
		/datum/preference/numeric/volume/sound_lobby_volume = savefile.get_entry("sound_lobby_volume"),
		/datum/preference/numeric/volume/sound_radio_noise = savefile.get_entry("sound_radio_noise"),

	)
	for(var/entry as anything in entries)
		var/pref_data = entries[entry]
		if(pref_data <= 1)
			pref_data *= 100
		write_preference(GLOB.preference_entries[entry], min(pref_data, 100))
	return
