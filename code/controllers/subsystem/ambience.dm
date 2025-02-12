/// The subsystem used to play ambience to users every now and then, makes them real excited.
SUBSYSTEM_DEF(ambience)
	name = "Ambience"
	flags = SS_BACKGROUND|SS_NO_INIT
	priority = FIRE_PRIORITY_AMBIENCE
	runlevels = RUNLEVEL_GAME | RUNLEVEL_POSTGAME
	wait = 1 SECONDS
	///Assoc list of listening client - next ambience time
	var/list/ambience_listening_clients = list()
	var/list/client_old_areas = list()
	///Cache for sanic speed :D
	var/list/currentrun = list()

/datum/controller/subsystem/ambience/fire(resumed)
	if(!resumed)
		currentrun = ambience_listening_clients.Copy()
	var/list/cached_clients = currentrun

	while(cached_clients.len)
		var/client/client_iterator = cached_clients[cached_clients.len]
		cached_clients.len--

		//Check to see if the client exists and isn't held by a new player
		var/mob/client_mob = client_iterator?.mob
		if(isnull(client_iterator) || !client_mob || isnewplayer(client_mob))
			ambience_listening_clients -= client_iterator
			client_old_areas -= client_iterator
			continue

		if(!client_mob.can_hear()) //WHAT? I CAN'T HEAR YOU
			continue

		//Check to see if the client-mob is in a valid area
		var/area/current_area = get_area(client_mob)
		if(!current_area) //Something's gone horribly wrong
			stack_trace("[key_name(client_mob)] has somehow ended up in nullspace. WTF did you do")
			remove_ambience_client(client_iterator)
			continue

		if(ambience_listening_clients[client_iterator] > world.time)
			if(!(current_area.forced_ambience && (client_old_areas?[client_iterator] != current_area) && prob(5)))
				continue

		//Run play_ambience() on the client-mob and set a cooldown
		ambience_listening_clients[client_iterator] = world.time + current_area.play_ambience(client_mob)

		//We REALLY don't want runtimes in SSambience
		if(client_iterator)
			client_old_areas[client_iterator] = current_area

		if(MC_TICK_CHECK)
			return

///Attempts to play an ambient sound to a mob, returning the cooldown in deciseconds
/area/proc/play_ambience(mob/M, sound/override_sound, volume = 27)
	var/sound/new_sound = override_sound || pick(ambientsounds)
	/// volume modifier for ambience as set by the player in preferences.
	var/volume_modifier = (M.client?.prefs.read_preference(/datum/preference/numeric/volume/sound_ambience_volume))/100
	new_sound = sound(new_sound, repeat = 0, wait = 0, volume = volume*volume_modifier, channel = CHANNEL_AMBIENCE)
	SEND_SOUND(M, new_sound)

	var/sound_length = SSsounds.get_sound_length(new_sound.file)
	return sound_length + rand(min_ambience_cooldown, max_ambience_cooldown)

/datum/controller/subsystem/ambience/proc/remove_ambience_client(client/to_remove)
	ambience_listening_clients -= to_remove
	client_old_areas -= to_remove
	currentrun -= to_remove

/area/station/maintenance

	///A list of rare sound effects to fuck with players. No, it does not contain actual minecraft sounds anymore.
	var/static/list/minecraft_cave_noises = list(
		'sound/machines/airlock/airlock.ogg',
		'sound/effects/snap.ogg',
		'sound/effects/footstep/clownstep1.ogg',
		'sound/effects/footstep/clownstep2.ogg',
		'sound/items/tools/welder.ogg',
		'sound/items/tools/welder2.ogg',
		'sound/items/tools/crowbar.ogg',
		'sound/items/deconstruct.ogg',
		'sound/ambience/misc/source_holehit3.ogg',
		'sound/ambience/misc/cavesound3.ogg',
	)

/area/station/maintenance/play_ambience(mob/M, sound/override_sound, volume)
	if(!M.has_light_nearby() && prob(0.5))
		return ..(M, pick(minecraft_cave_noises))
	return ..()

/**
 * Ambience buzz handling called by either area/Enter() or refresh_looping_ambience()
 */

/mob/proc/update_ambience_area(area/new_area)

	var/old_tracked_area = ambience_tracked_area
	if(old_tracked_area)
		UnregisterSignal(old_tracked_area, COMSIG_AREA_POWER_CHANGE)
		ambience_tracked_area = null
	if(!client)
		return
	if(new_area)
		ambience_tracked_area = new_area
		RegisterSignal(ambience_tracked_area, COMSIG_AREA_POWER_CHANGE, PROC_REF(refresh_looping_ambience), TRUE)

	refresh_looping_ambience()

/mob/proc/refresh_looping_ambience()
	SIGNAL_HANDLER

	if(!client || isobserver(client.mob)) // If a tree falls in the woods. sadboysuss: Don't refresh for ghosts, it sounds bad
		return

	var/area/my_area = get_area(src)
	var/sound_to_use = my_area.ambient_buzz
	var/volume_modifier = client.prefs.read_preference(/datum/preference/numeric/volume/sound_ship_ambience_volume)

	if(!sound_to_use || !(client.prefs.read_preference(/datum/preference/numeric/volume/sound_ship_ambience_volume)))
		SEND_SOUND(src, sound(null, repeat = 0, volume = volume_modifier, wait = 0, channel = CHANNEL_BUZZ))
		client.current_ambient_sound = null
		return

	if(!can_hear()) // Can the mob hear?
		SEND_SOUND(src, sound(null, repeat = 0, wait = 0, channel = CHANNEL_BUZZ))
		client.current_ambient_sound = null
		return

	//Station ambience is dependent on a functioning and charged APC with environment power enabled.
	if(!is_mining_level(my_area.z) && ((!my_area.apc || !my_area.apc.operating || !my_area.apc.cell?.charge && my_area.requires_power || !my_area.power_environ)))
		SEND_SOUND(src, sound(null, repeat = 0, wait = 0, channel = CHANNEL_BUZZ))
		client.current_ambient_sound = null
		return
	else
		if(sound_to_use == client.current_ambient_sound) // Don't reset current loops
			return

		client.current_ambient_sound = sound_to_use
		SEND_SOUND(src, sound(my_area.ambient_buzz, repeat = 1, wait = 0, volume = my_area.ambient_buzz_vol, channel = CHANNEL_BUZZ))
