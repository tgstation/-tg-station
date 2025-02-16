/// if autoadmin is enabled
/datum/config_entry/flag/autoadmin
	protection = CONFIG_ENTRY_LOCKED

/// the rank given to autoadmins
/datum/config_entry/string/autoadmin_rank
	default = "Game Master"
	protection = CONFIG_ENTRY_LOCKED

/datum/config_entry/flag/auto_deadmin_players
	protection = CONFIG_ENTRY_LOCKED

/datum/config_entry/number/auto_deadmin_timegate
	default = null
	protection = CONFIG_ENTRY_LOCKED

/datum/config_entry/flag/auto_deadmin_antagonists
	protection = CONFIG_ENTRY_LOCKED

/datum/config_entry/flag/auto_deadmin_heads
	protection = CONFIG_ENTRY_LOCKED

/datum/config_entry/flag/auto_deadmin_silicons
	protection = CONFIG_ENTRY_LOCKED

/datum/config_entry/flag/auto_deadmin_security
	protection = CONFIG_ENTRY_LOCKED


/// server name (the name of the game window)
/datum/config_entry/string/servername

/// short form server name used for the DB
/datum/config_entry/string/serversqlname

/// station name (the name of the station in-game)
/datum/config_entry/string/stationname

/// Countdown between lobby and the round starting.
/datum/config_entry/number/lobby_countdown
	default = 120
	integer = FALSE
	min_val = 0

/// Post round murder death kill countdown.
/datum/config_entry/number/round_end_countdown
	default = 25
	integer = FALSE
	min_val = 0

/// if the game appears on the hub or not
/datum/config_entry/flag/hub

/// Pop requirement for the server to be removed from the hub
/datum/config_entry/number/max_hub_pop
	default = 0 //0 means disabled
	integer = TRUE
	min_val = 0

/// log messages sent in OOC
/datum/config_entry/flag/log_ooc

/// log login/logout
/datum/config_entry/flag/log_access

/// Config entry which special logging of failed logins under suspicious circumstances.
/datum/config_entry/flag/log_suspicious_login

/// log client say
/datum/config_entry/flag/log_say

/// log admin actions
/datum/config_entry/flag/log_admin
	protection = CONFIG_ENTRY_LOCKED

/// log prayers
/datum/config_entry/flag/log_prayer

///Log Music Requests
/datum/config_entry/flag/log_internet_request

/// log silicons
/datum/config_entry/flag/log_silicon

/datum/config_entry/flag/log_law
	deprecated_by = /datum/config_entry/flag/log_silicon

/datum/config_entry/flag/log_law/DeprecationUpdate(value)
	return value

/// log usage of tools
/datum/config_entry/flag/log_tools

/// log game events
/datum/config_entry/flag/log_game

/// log mech data
/datum/config_entry/flag/log_mecha

/// log virology data
/datum/config_entry/flag/log_virus

/// log assets
/datum/config_entry/flag/log_asset

/// log voting
/datum/config_entry/flag/log_vote

/// log manual zone switching
/datum/config_entry/flag/log_zone_switch

/// log client whisper
/datum/config_entry/flag/log_whisper

/// log attack messages
/datum/config_entry/flag/log_attack

/// log emotes
/datum/config_entry/flag/log_emote

/// log economy actions
/datum/config_entry/flag/log_econ

/// log traitor objectives
/datum/config_entry/flag/log_traitor

/// log admin chat messages
/datum/config_entry/flag/log_adminchat
	protection = CONFIG_ENTRY_LOCKED

/// log pda messages
/datum/config_entry/flag/log_pda

/// log uplink/spellbook/codex ciatrix purchases and refunds
/datum/config_entry/flag/log_uplink

/// log telecomms messages
/datum/config_entry/flag/log_telecomms

/// log speech indicators(started/stopped speaking)
/datum/config_entry/flag/log_speech_indicators

/// log certain expliotable parrots and other such fun things in a JSON file of twitter valid phrases.
/datum/config_entry/flag/log_twitter

/// log all world.Topic() calls
/datum/config_entry/flag/log_world_topic

/// log crew manifest to separate file
/datum/config_entry/flag/log_manifest

/// log roundstart divide occupations debug information to a file
/datum/config_entry/flag/log_job_debug

/// log shuttle related actions, ie shuttle computers, shuttle manipulator, emergency console
/datum/config_entry/flag/log_shuttle

/// logs all timers in buckets on automatic bucket reset (Useful for timer debugging)
/datum/config_entry/flag/log_timers_on_bucket_reset

/// Log human readable versions of json log entries
/datum/config_entry/flag/log_as_human_readable
	default = TRUE

/// allows admins with relevant permissions to have their own ooc colour
/datum/config_entry/flag/allow_admin_ooccolor

/// allows admins with relevant permissions to have a personalized asay color
/datum/config_entry/flag/allow_admin_asaycolor

/// allow votes to restart
/datum/config_entry/flag/allow_vote_restart

/// allow votes to change map
/datum/config_entry/flag/allow_vote_map

/// allow players to vote to re-do the map vote
/datum/config_entry/flag/allow_rock_the_vote

/// the number of times we allow players to rock the vote
/datum/config_entry/number/max_rocking_votes
	default = 1
	min_val = 1

/// minimum time between voting sessions (deciseconds, 10 minute default)
/datum/config_entry/number/vote_delay
	default = 10 MINUTES
	integer = FALSE
	min_val = 0

/// length of voting period (deciseconds, default 1 minute)
/datum/config_entry/number/vote_period
	default = 1 MINUTES
	integer = FALSE
	min_val = 0

/// If disabled, non-voters will automatically have their votes added to certain vote options
/// (For example: restart votes will default to "no restart", map votes will default to their preferred map / default map, rocking the vote will default to "no")
/datum/config_entry/flag/default_no_vote

/// Prevents dead people from voting.
/datum/config_entry/flag/no_dead_vote

/// Gives the ability to send players a maptext popup.
/datum/config_entry/flag/popup_admin_pm

/datum/config_entry/number/fps
	default = 20
	integer = FALSE
	min_val = 1
	max_val = 100 //byond will start crapping out at 50, so this is just ridic
	var/sync_validate = FALSE

/datum/config_entry/number/fps/ValidateAndSet(str_val)
	. = ..()
	if(.)
		sync_validate = TRUE
		var/datum/config_entry/number/ticklag/TL = config.entries_by_type[/datum/config_entry/number/ticklag]
		if(!TL.sync_validate)
			TL.ValidateAndSet(10 / config_entry_value)
		sync_validate = FALSE

/datum/config_entry/number/ticklag
	integer = FALSE
	var/sync_validate = FALSE

/datum/config_entry/number/ticklag/New() //ticklag weirdly just mirrors fps
	var/datum/config_entry/CE = /datum/config_entry/number/fps
	default = 10 / initial(CE.default)
	..()

/datum/config_entry/number/ticklag/ValidateAndSet(str_val)
	. = text2num(str_val) > 0 && ..()
	if(.)
		sync_validate = TRUE
		var/datum/config_entry/number/fps/FPS = config.entries_by_type[/datum/config_entry/number/fps]
		if(!FPS.sync_validate)
			FPS.ValidateAndSet(10 / config_entry_value)
		sync_validate = FALSE

/datum/config_entry/flag/allow_holidays


/datum/config_entry/flag/admin_legacy_system //Defines whether the server uses the legacy admin system with admins.txt or the SQL system
	protection = CONFIG_ENTRY_LOCKED

/datum/config_entry/flag/protect_legacy_admins //Stops any admins loaded by the legacy system from having their rank edited by the permissions panel
	protection = CONFIG_ENTRY_LOCKED

/datum/config_entry/flag/protect_legacy_ranks //Stops any ranks loaded by the legacy system from having their flags edited by the permissions panel
	protection = CONFIG_ENTRY_LOCKED

/datum/config_entry/flag/enable_localhost_rank //Gives the !localhost! rank to any client connecting from 127.0.0.1 or ::1
	protection = CONFIG_ENTRY_LOCKED

/datum/config_entry/flag/load_legacy_ranks_only //Loads admin ranks only from legacy admin_ranks.txt, while enabled ranks are mirrored to the database
	protection = CONFIG_ENTRY_LOCKED

/datum/config_entry/string/hostedby

/// Determines if a player can respawn after dying.
/// 0 / RESPAWN_FLAG_DISABLED = Cannot respawn (default)
/// 1 / RESPAWN_FLAG_FREE = Can respawn
/// 2 / RESPAWN_FLAG_NEW_CHARACTER = Can respawn if choosing a different character
/datum/config_entry/flag/allow_respawn
	default = RESPAWN_FLAG_DISABLED

/datum/config_entry/flag/allow_respawn/ValidateAndSet(str_val)
	if(!VASProcCallGuard(str_val))
		return FALSE
	var/val_as_num = text2num(str_val)
	if(val_as_num in list(RESPAWN_FLAG_DISABLED, RESPAWN_FLAG_FREE, RESPAWN_FLAG_NEW_CHARACTER))
		config_entry_value = val_as_num
		return TRUE
	return FALSE

/// Determines how long (in deciseconds) before a player is allowed to respawn.
/datum/config_entry/number/respawn_delay
	default = 0 SECONDS

/datum/config_entry/flag/usewhitelist

/datum/config_entry/flag/use_age_restriction_for_jobs //Do jobs use account age restrictions? --requires database

/datum/config_entry/flag/use_account_age_for_jobs //Uses the time they made the account for the job restriction stuff. New player joining alerts should be unaffected.

/datum/config_entry/flag/use_exp_tracking

/// Enables head jobs time restrictions.
/datum/config_entry/flag/use_exp_restrictions_heads

/datum/config_entry/number/use_exp_restrictions_heads_hours
	default = 0
	integer = FALSE
	min_val = 0

/datum/config_entry/flag/use_exp_restrictions_heads_department

/// Enables non-head jobs time restrictions.
/datum/config_entry/flag/use_exp_restrictions_other

/datum/config_entry/flag/use_exp_restrictions_admin_bypass

/datum/config_entry/flag/use_low_living_hour_intern

/datum/config_entry/number/use_low_living_hour_intern_hours
	default = 0
	integer = FALSE
	min_val = 0

/datum/config_entry/string/server

/datum/config_entry/string/public_address

/datum/config_entry/string/banappeals

/datum/config_entry/string/wikiurl
	default = "http://tgstation13.org/wiki"

/datum/config_entry/string/forumurl
	default = "http://tgstation13.org/phpBB/index.php"

/datum/config_entry/string/rulesurl
	default = "http://tgstation13.org/wiki/Rules"

/datum/config_entry/string/githuburl
	default = "https://www.github.com/tgstation/tgstation"

/datum/config_entry/string/discordbotcommandprefix
	default = "?"

/datum/config_entry/string/roundstatsurl

/datum/config_entry/string/gamelogurl

/datum/config_entry/flag/guest_ban

/datum/config_entry/number/id_console_jobslot_delay
	default = 30
	integer = FALSE
	min_val = 0

/datum/config_entry/number/inactivity_period //time in ds until a player is considered inactive
	default = 3000
	integer = FALSE
	min_val = 0

/datum/config_entry/number/inactivity_period/ValidateAndSet(str_val)
	. = ..()
	if(.)
		config_entry_value *= 10 //documented as seconds in config.txt

/datum/config_entry/number/afk_period //time in ds until a player is considered inactive
	default = 3000
	integer = FALSE
	min_val = 0

/datum/config_entry/number/afk_period/ValidateAndSet(str_val)
	. = ..()
	if(.)
		config_entry_value *= 10 //documented as seconds in config.txt

/datum/config_entry/flag/kick_inactive //force disconnect for inactive players

/datum/config_entry/flag/load_jobs_from_txt

/datum/config_entry/flag/forbid_singulo_possession

/datum/config_entry/flag/automute_on //enables automuting/spam prevention

/datum/config_entry/string/panic_server_name

/datum/config_entry/string/panic_server_name/ValidateAndSet(str_val)
	return str_val != "\[Put the name here\]" && ..()

/datum/config_entry/string/panic_server_address //Reconnect a player this linked server if this server isn't accepting new players

/datum/config_entry/string/panic_server_address/ValidateAndSet(str_val)
	return str_val != "byond://address:port" && ..()

/datum/config_entry/string/invoke_youtubedl
	protection = CONFIG_ENTRY_LOCKED | CONFIG_ENTRY_HIDDEN

/datum/config_entry/flag/request_internet_sound

/datum/config_entry/string/request_internet_allowed
	protection = CONFIG_ENTRY_LOCKED

/datum/config_entry/flag/show_irc_name

/datum/config_entry/flag/no_default_techweb_link

/datum/config_entry/flag/see_own_notes //Can players see their own admin notes

/datum/config_entry/number/note_fresh_days
	default = null
	min_val = 0
	integer = FALSE

/datum/config_entry/number/note_stale_days
	default = null
	min_val = 0
	integer = FALSE

/datum/config_entry/flag/maprotation

/datum/config_entry/number/auto_lag_switch_pop //Number of clients at which drastic lag mitigation measures kick in
	config_entry_value = null
	min_val = 0

/datum/config_entry/number/soft_popcap
	default = null
	min_val = 0

/datum/config_entry/number/hard_popcap
	default = null
	min_val = 0

/datum/config_entry/number/extreme_popcap
	default = null
	min_val = 0

/datum/config_entry/string/soft_popcap_message
	default = "Be warned that the server is currently serving a high number of users, consider using alternative game servers."

/datum/config_entry/string/hard_popcap_message
	default = "The server is currently serving a high number of users, You cannot currently join. You may wait for the number of living crew to decline, observe, or find alternative servers."

/datum/config_entry/string/extreme_popcap_message
	default = "The server is currently serving a high number of users, find alternative servers."

/datum/config_entry/flag/byond_member_bypass_popcap

/datum/config_entry/flag/panic_bunker // prevents people the server hasn't seen before from connecting

/datum/config_entry/number/panic_bunker_living // living time in minutes that a player needs to pass the panic bunker

/// Flag for requiring players who would otherwise be denied access by the panic bunker to complete a written interview
/datum/config_entry/flag/panic_bunker_interview

/datum/config_entry/string/panic_bunker_message
	default = "Sorry but the server is currently not accepting connections from never before seen players."

/datum/config_entry/number/notify_new_player_age // how long do we notify admins of a new player
	min_val = -1

/datum/config_entry/number/notify_new_player_account_age // how long do we notify admins of a new byond account
	min_val = 0

/datum/config_entry/flag/irc_first_connection_alert // do we notify the irc channel when somebody is connecting for the first time?

/datum/config_entry/string/ipintel_base
	default = "check.getipintel.net"

/datum/config_entry/string/ipintel_email

/datum/config_entry/string/ipintel_email/ValidateAndSet(str_val)
	return str_val != "ch@nge.me" && (!length(str_val) || findtext(str_val, "@")) && ..()

/datum/config_entry/number/ipintel_rating_bad
	default = 1
	integer = FALSE
	min_val = 0
	max_val = 1

/datum/config_entry/flag/ipintel_reject_rate_limited
	default = FALSE

/datum/config_entry/flag/ipintel_reject_bad
	default = FALSE

/datum/config_entry/flag/ipintel_reject_unknown
	default = FALSE

/datum/config_entry/number/ipintel_rate_minute
	default = 15
	min_val = 0

/datum/config_entry/number/ipintel_cache_length
	default = 7
	min_val = 0

/datum/config_entry/number/ipintel_exempt_playtime_living
	default = 5
	min_val = 0

/datum/config_entry/flag/aggressive_changelog

/datum/config_entry/flag/autoconvert_notes //if all connecting player's notes should attempt to be converted to the database
	protection = CONFIG_ENTRY_LOCKED

/datum/config_entry/flag/allow_webclient

/datum/config_entry/flag/webclient_only_byond_members

/datum/config_entry/flag/announce_admin_logout

/datum/config_entry/flag/announce_admin_login

/datum/config_entry/flag/allow_map_voting
	deprecated_by = /datum/config_entry/flag/preference_map_voting

/datum/config_entry/flag/allow_map_voting/DeprecationUpdate(value)
	return value

/datum/config_entry/flag/preference_map_voting

/// Allows players to export their own preferences as a JSON file. Left as a config toggle in case it needs to be turned off due to server-specific needs.
/datum/config_entry/flag/forbid_preferences_export
	default = FALSE

/// The number of seconds a player must wait between preference export attempts.
/datum/config_entry/number/seconds_cooldown_for_preferences_export
	default = 10
	min_val = 1

/datum/config_entry/number/client_warn_version
	default = null
	min_val = 500

/datum/config_entry/number/client_warn_build
	default = null
	min_val = 0

/datum/config_entry/string/client_warn_message
	default = "Your version of byond may have issues or be blocked from accessing this server in the future."

/datum/config_entry/flag/client_warn_popup

/datum/config_entry/number/client_error_version
	default = null
	min_val = 500

/datum/config_entry/string/client_error_message
	default = "Your version of byond is too old, may have issues, and is blocked from accessing this server."

/datum/config_entry/number/client_error_build
	default = null
	min_val = 0

/datum/config_entry/number/minute_topic_limit
	default = null
	min_val = 0

/datum/config_entry/number/second_topic_limit
	default = null
	min_val = 0

/datum/config_entry/number/minute_click_limit
	default = 400
	min_val = 0

/datum/config_entry/number/second_click_limit
	default = 15
	min_val = 0

/datum/config_entry/number/error_cooldown // The "cooldown" time for each occurrence of a unique error
	default = 600
	integer = FALSE
	min_val = 0

/datum/config_entry/number/error_limit // How many occurrences before the next will silence them
	default = 50

/datum/config_entry/number/error_silence_time // How long a unique error will be silenced for
	default = 6000
	integer = FALSE

/datum/config_entry/number/error_msg_delay // How long to wait between messaging admins about occurrences of a unique error
	default = 50
	integer = FALSE

/datum/config_entry/flag/irc_announce_new_game
	deprecated_by = /datum/config_entry/str_list/channel_announce_new_game

/datum/config_entry/flag/irc_announce_new_game/DeprecationUpdate(value)
	return "" //default broadcast

/datum/config_entry/string/chat_announce_new_game
	deprecated_by = /datum/config_entry/str_list/channel_announce_new_game

/datum/config_entry/string/chat_announce_new_game/DeprecationUpdate(value)
	return "" //default broadcast

/datum/config_entry/str_list/channel_announce_new_game
	default = null

/datum/config_entry/str_list/channel_announce_end_game
	default = null

/datum/config_entry/str_list/chat_new_game_notifications
	default = null

/// validate ownership of admin flags for chat commands
/datum/config_entry/flag/secure_chat_commands
	default = FALSE

/datum/config_entry/flag/debug_admin_hrefs

/datum/config_entry/number/mc_tick_rate/base_mc_tick_rate
	integer = FALSE
	default = 1

/datum/config_entry/number/mc_tick_rate/high_pop_mc_tick_rate
	integer = FALSE
	default = 1.1

/datum/config_entry/number/mc_tick_rate/high_pop_mc_mode_amount
	default = 65

/datum/config_entry/number/mc_tick_rate/disable_high_pop_mc_mode_amount
	default = 60

/datum/config_entry/number/mc_tick_rate
	abstract_type = /datum/config_entry/number/mc_tick_rate

/datum/config_entry/number/mc_tick_rate/ValidateAndSet(str_val)
	. = ..()
	if (.)
		Master.UpdateTickRate()

/datum/config_entry/flag/resume_after_initializations

/datum/config_entry/flag/resume_after_initializations/ValidateAndSet(str_val)
	. = ..()
	if(. && MC_RUNNING())
		world.sleep_offline = !config_entry_value

/datum/config_entry/number/rounds_until_hard_restart
	default = -1
	min_val = 0

/datum/config_entry/string/default_view
	default = "15x15"

/datum/config_entry/string/default_view_square
	default = "15x15"

/datum/config_entry/flag/log_pictures

/datum/config_entry/flag/picture_logging_camera


/datum/config_entry/flag/reopen_roundstart_suicide_roles

/datum/config_entry/flag/reopen_roundstart_suicide_roles_command_positions

/datum/config_entry/number/reopen_roundstart_suicide_roles_delay
	min_val = 30

/datum/config_entry/flag/reopen_roundstart_suicide_roles_command_report

/datum/config_entry/flag/auto_profile

/datum/config_entry/number/profiler_interval
	default = 300 SECONDS

/datum/config_entry/number/drift_dump_threshold
	default = 4 SECONDS

/datum/config_entry/number/drift_profile_delay
	default = 15 SECONDS

/datum/config_entry/string/centcom_ban_db // URL for the CentCom Galactic Ban DB API

/datum/config_entry/string/centcom_source_whitelist

/// URL for admins to be redirected to for 2FA
/datum/config_entry/string/admin_2fa_url

/datum/config_entry/number/hard_deletes_overrun_threshold
	integer = FALSE
	min_val = 0
	default = 0.5

/datum/config_entry/number/hard_deletes_overrun_limit
	default = 0
	min_val = 0

/datum/config_entry/str_list/motd

/datum/config_entry/number/urgent_ahelp_cooldown
	default = 300

/datum/config_entry/string/urgent_ahelp_message
	default = "This ahelp is urgent!"

/datum/config_entry/string/ahelp_message
	default = ""

/datum/config_entry/string/urgent_ahelp_user_prompt
	default = "There are no admins currently on. Do not press the button below if your ahelp is a joke, a request or a question. Use it only for cases of obvious grief."

/datum/config_entry/string/urgent_adminhelp_webhook_url

/datum/config_entry/string/regular_adminhelp_webhook_url

/datum/config_entry/string/adminhelp_webhook_pfp

/datum/config_entry/string/adminhelp_webhook_name

/datum/config_entry/string/adminhelp_ahelp_link

/datum/config_entry/flag/cache_assets
	default = TRUE

/datum/config_entry/flag/smart_cache_assets
	default = TRUE

/datum/config_entry/flag/save_spritesheets
	default = FALSE

/datum/config_entry/flag/station_name_in_hub_entry
	default = FALSE

/datum/config_entry/number/pr_announcements_per_round
	default = 5
	min_val = 0
	integer = TRUE

/datum/config_entry/flag/forbid_all_profiling

/datum/config_entry/flag/forbid_admin_profiling


/datum/config_entry/flag/morgue_cadaver_disable_nonhumans
	default = FALSE

/datum/config_entry/number/morgue_cadaver_other_species_probability
	default = 50

/datum/config_entry/string/morgue_cadaver_override_species

/datum/config_entry/flag/toast_notification_on_init

/datum/config_entry/flag/config_errors_runtime
	default = FALSE

/datum/config_entry/number/upload_limit
	default = 524288
	min_val = 0

/datum/config_entry/number/upload_limit_admin
	default = 5242880
	min_val = 0

/// The minimum number of tallies a map vote entry can have.
/datum/config_entry/number/map_vote_minimum_tallies
	default = 1
	min_val = 0
	max_val = 50

/// The flat amount all maps get by default
/datum/config_entry/number/map_vote_flat_bonus
	default = 5
	min_val = 0
	max_val = INFINITY

/// The maximum number of tallies a map vote entry can have.
/datum/config_entry/number/map_vote_maximum_tallies
	default = 200
	min_val = 0
	max_val = INFINITY

/// The number of tallies that are carried over between rounds.
/datum/config_entry/number/map_vote_tally_carryover_percentage
	default = 100
	min_val = 0
	max_val = 100

/// If admins with +DEBUG can initialize byond-tracy midround.
/datum/config_entry/flag/allow_tracy_start
	protection = CONFIG_ENTRY_LOCKED

/// If admins with +DEBUG can queue byond-tracy to run the next round.
/datum/config_entry/flag/allow_tracy_queue
	protection = CONFIG_ENTRY_LOCKED
