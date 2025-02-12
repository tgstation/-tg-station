/**
 * Run when a client is put in this mob or reconnets to byond and their client was on this mob.
 * Anything that sleeps can result in the client reference being dropped, due to byond using that sleep to handle a client disconnect.
 * You can save a lot of headache if you make Login use SHOULD_NOT_SLEEP, but that would require quite a bit of refactoring how Login code works.
 *
 * Things it does:
 * * Adds player to player_list
 * * sets lastKnownIP
 * * sets computer_id
 * * logs the login
 * * tells the world to update its status (for player count)
 * * create mob huds for the mob if needed
 * * reset next_move to 1
 * * Set statobj to our mob
 * * NOT the parent call. The only unique thing it does is a very obtuse move op, see the comment lower down
 * * if the client exists set the perspective to the mob loc
 * * call on_log on the loc (sigh)
 * * reload the huds for the mob
 * * reload all full screen huds attached to this mob
 * * load any global alternate apperances
 * * sync the mind datum via sync_mind()
 * * call any client login callbacks that exist
 * * grant any actions the mob has to the client
 * * calls [auto_deadmin_on_login](mob.html#proc/auto_deadmin_on_login)
 * * send signal COMSIG_MOB_CLIENT_LOGIN
 * * attaches the ash listener element so clients can hear weather
 * client can be deleted mid-execution of this proc, chiefly on parent calls, with lag
 */
/mob/Login()
	if(!client)
		return FALSE

	canon_client = client
	add_to_player_list()
	lastKnownIP = client.address
	computer_id = client.computer_id
	log_access("Mob Login: [key_name(src)] was assigned to a [type] ([tag])")
	world.update_status()
	client.clear_screen() //remove hud items just in case
	client.images = list()
	client.set_right_click_menu_mode(shift_to_open_context_menu)

	if(!hud_used)
		create_mob_hud() // creating a hud will add it to the client's screen, which can process a disconnect
		if(!client)
			return FALSE

	if(hud_used)
		hud_used.show_hud(hud_used.hud_version) // see above, this can process a disconnect
		if(!client)
			return FALSE
		hud_used.update_ui_style(ui_style2icon(client.prefs?.read_preference(/datum/preference/choiced/ui_style)))

	next_move = 1

	client.statobj = src

	// DO NOT CALL PARENT HERE
	// BYOND's internal implementation of login does two things
	// 1: Set statobj to the mob being logged into (We got this covered)
	// 2: And I quote "If the mob has no location, place it near (1,1,1) if possible"
	// See, near is doing an agressive amount of legwork there
	// What it actually does is takes the area that (1,1,1) is in, and loops through all those turfs
	// If you successfully move into one, it stops
	// Because we want Move() to mean standard movements rather then just what byond treats it as (ALL moves)
	// We don't allow moves from nullspace -> somewhere. This means the loop has to iterate all the turfs in (1,1,1)'s area
	// For us, (1,1,1) is a space tile. This means roughly 200,000! calls to Move()
	// You do not want this

	if(!client)
		return FALSE

	enable_client_mobs_in_contents(client)

	SEND_SIGNAL(src, COMSIG_MOB_LOGIN)

	if (key != client.key)
		key = client.key
	reset_perspective(loc)

	if(loc)
		loc.on_log(TRUE)

	//readd this mob's HUDs (antag, med, etc)
	reload_huds()

	reload_fullscreen() // Reload any fullscreen overlays this mob has.

	add_click_catcher()

	sync_mind()

	//Reload alternate appearances
	for(var/datum/atom_hud/alternate_appearance/alt_hud as anything in GLOB.active_alternate_appearances)
		if(!alt_hud.apply_to_new_mob(src))
			alt_hud.hide_from(src, absolute = TRUE)

	update_client_colour()
	update_mouse_pointer()
	update_ambience_area(get_area(src))

	if(!can_hear())
		stop_sound_channel(CHANNEL_AMBIENCE)

	if(client)
		if(client.view_size)
			client.view_size.resetToDefault() // Resets the client.view in case it was changed.
		else
			client.change_view(getScreenSize(client.prefs.read_preference(/datum/preference/toggle/widescreen)))

		if(client.player_details.player_actions.len)
			for(var/datum/action/A in client.player_details.player_actions)
				A.Grant(src)

		for(var/foo in client.player_details.post_login_callbacks)
			var/datum/callback/CB = foo
			CB.Invoke()
		log_played_names(
			client.ckey,
			list(
				"[name]" = tag,
				"[real_name]" = tag,
			),
		)
		auto_deadmin_on_login()

	log_message("Client [key_name(src)] has taken ownership of mob [src]([src.type])", LOG_OWNERSHIP)
	log_mob_tag("TAG: [tag] NEW OWNER: [key_name(src)]")
	SEND_SIGNAL(src, COMSIG_MOB_CLIENT_LOGIN, client)
	SEND_SIGNAL(client, COMSIG_CLIENT_MOB_LOGIN, src)
	client.init_verbs()

	AddElement(/datum/element/weather_listener, /datum/weather/ash_storm, ZTRAIT_ASHSTORM, GLOB.ash_storm_sounds)
	AddElement(/datum/element/weather_listener, /datum/weather/snow_storm, ZTRAIT_SNOWSTORM, GLOB.snowstorm_sounds)

	SEND_GLOBAL_SIGNAL(COMSIG_GLOB_MOB_LOGGED_IN, src)

	return TRUE


/**
 * Checks if the attached client is an admin and may deadmin them
 *
 * Configs:
 * * flag/auto_deadmin_players
 * * client.prefs?.toggles & DEADMIN_ALWAYS
 * * User is antag and flag/auto_deadmin_antagonists or client.prefs?.toggles & DEADMIN_ANTAGONIST
 * * or if their job demands a deadminning SSjob.handle_auto_deadmin_roles()
 *
 * Called from [login](mob.html#proc/Login)
 */
/mob/proc/auto_deadmin_on_login() //return true if they're not an admin at the end.
	if(!client?.holder)
		return TRUE
	if(CONFIG_GET(flag/auto_deadmin_players) || (client.prefs?.toggles & DEADMIN_ALWAYS))
		return client.holder.auto_deadmin()
	if(mind.has_antag_datum(/datum/antagonist) && (CONFIG_GET(flag/auto_deadmin_antagonists) || client.prefs?.toggles & DEADMIN_ANTAGONIST))
		return client.holder.auto_deadmin()
	if(job)
		return SSjob.handle_auto_deadmin_roles(client, job)
