/// Previously, sound preferences were legacy toggles.
/// PR #71040 changed these to modern toggles.
/// This migration transfers the player's existing preferences into the new toggles

/datum/preferences/proc/migrate_legacy_sound_toggles(savefile/savefile)
	write_preference(GLOB.preference_entries[/datum/preference/numeric/volume/sound_ambience_volume], toggles & 1<<2)
	write_preference(GLOB.preference_entries[/datum/preference/toggle/sound_announcements], toggles & 1<<11)
	write_preference(GLOB.preference_entries[/datum/preference/toggle/sound_combatmode], toggles & 1<<22)
	write_preference(GLOB.preference_entries[/datum/preference/numeric/volume/sound_instruments], toggles & 1<<7)
	write_preference(GLOB.preference_entries[/datum/preference/numeric/volume/sound_lobby_volume], toggles & 1<<3)
	write_preference(GLOB.preference_entries[/datum/preference/numeric/volume/sound_midi], toggles & 1<<1)
	write_preference(GLOB.preference_entries[/datum/preference/numeric/volume/sound_ship_ambience_volume], toggles & 1<<8)
