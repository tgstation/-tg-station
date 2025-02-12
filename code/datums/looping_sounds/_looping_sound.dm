/**
 * A datum for sounds that need to loop, with a high amount of configurability.
 */
/datum/looping_sound
	/// (list or soundfile) Since this can be either a list or a single soundfile you can have random sounds. May contain further lists but must contain a soundfile at the end. In a list, path must have also be assigned a value or it will be assigned 0 and not play.
	var/mid_sounds
	/// The length of time to wait between playing mid_sounds. WARNING: Continuously looping sounds like the microwave, grav gen and fan sounds don't work very well with this, just don't set this if you are doing a continuous loop of machinery.
	var/mid_length
	/// Amount of time to add/take away from the mid length, randomly
	var/mid_length_vary = 0
	/// If we should always play each sound once per loop of all sounds. Weights here only really effect order, and could be disgarded
	var/each_once = FALSE
	/// Whether if the sounds should be played in order or not. Defaults to FALSE.
	var/in_order = FALSE
	/// Override for volume of start sound.
	var/start_volume
	/// (soundfile) Played before starting the mid_sounds loop.
	var/start_sound
	/// How long to wait before starting the main loop after playing start_sound.
	var/start_length
	/// Override for volume of end sound.
	var/end_volume
	/// (soundfile) The sound played after the main loop has concluded.
	var/end_sound
	/// Chance per loop to play a mid_sound.
	var/chance
	/// Sound output volume.
	var/volume = 100
	/// Whether or not the sounds will vary in pitch when played.
	var/vary = FALSE
	/// The max amount of loops to run for.
	var/max_loops
	/// The extra range of the sound in tiles, defaults to 0.
	var/extra_range = 0
	/// How much the sound will be affected by falloff per tile.
	var/falloff_exponent
	/// The falloff distance of the sound,
	var/falloff_distance
	/// Are the sounds affected by pressure? Defaults to TRUE.
	var/pressure_affected = TRUE
	/// Are the sounds subject to reverb? Defaults to TRUE.
	var/use_reverb = TRUE
	/// Are we ignoring walls? Defaults to TRUE.
	var/ignore_walls = TRUE

	// State stuff
	/// The source of the sound, or the recipient of the sound.
	var/atom/parent
	/// The ID of the timer that's used to loop the sounds.
	var/timer_id
	/// Has the looping started yet?
	var/loop_started = FALSE
	/// If we're using cut_mid, this is the list we cut from
	var/list/cut_list
	///The index of the current song we're playing in the mid_sounds list, only used if in_order is used
	///This is immediately set to 1, so we start the index at 0
	var/audio_index = 0

	// Args
	/// Do we skip the starting sounds?
	var/skip_starting_sounds = FALSE
	/// If true, plays directly to provided atoms instead of from them.
	var/direct
	/// Sound channel to play on, random if not provided
	var/sound_channel

/datum/looping_sound/New(_parent, start_immediately = FALSE, _direct = FALSE, _skip_starting_sounds = FALSE)
	if(!mid_sounds)
		WARNING("A looping sound datum was created without sounds to play.")
		return

	set_parent(_parent)
	direct = _direct
	skip_starting_sounds = _skip_starting_sounds

	if(start_immediately)
		start()

/datum/looping_sound/Destroy()
	stop(TRUE)
	return ..()

/**
 * The proc to actually kickstart the whole sound sequence. This is what you should call to start the `looping_sound`.
 *
 * Arguments:
 * * on_behalf_of - The new object to set as a parent.
 */
/datum/looping_sound/proc/start(on_behalf_of)
	if(on_behalf_of)
		set_parent(on_behalf_of)
	if(timer_id)
		return
	on_start()

/**
 * The proc to call to stop the sound loop.
 *
 * Arguments:
 * * null_parent - Whether or not we should set the parent to null (useful when destroying the `looping_sound` itself). Defaults to FALSE.
 */
/datum/looping_sound/proc/stop(null_parent = FALSE)
	stop_current()
	if(null_parent)
		set_parent(null)
	if(!timer_id)
		return
	on_stop()
	deltimer(timer_id, SSsound_loops)
	timer_id = null
	loop_started = FALSE

/// The proc that handles starting the actual core sound loop.
/datum/looping_sound/proc/start_sound_loop()
	loop_started = TRUE
	sound_loop()
	timer_id = addtimer(CALLBACK(src, PROC_REF(sound_loop), world.time), mid_length, TIMER_CLIENT_TIME | TIMER_STOPPABLE | TIMER_LOOP | TIMER_DELETE_ME, SSsound_loops)

/**
 * A simple proc handling the looping of the sound itself.
 *
 * Arguments:
 * * start_time - The time at which the `mid_sounds` started being played (so we know when to stop looping).
 */
/datum/looping_sound/proc/sound_loop(start_time)
	if(max_loops && world.time >= start_time + mid_length * max_loops)
		stop()
		return
	// If we have a timer, we're varying mid length, and this is happening while we're runnin mid_sounds
	if(timer_id && mid_length_vary && start_time)
		updatetimedelay(timer_id, mid_length + rand(-mid_length_vary, mid_length_vary), timer_subsystem = SSsound_loops)
	if(!chance || prob(chance))
		play(get_sound())

/**
 * Applies a new mid length to the sound
 */
/datum/looping_sound/proc/set_mid_length(new_mid)
	mid_length = new_mid
	if(!timer_id)
		return
	updatetimedelay(timer_id, mid_length + rand(-mid_length_vary, mid_length_vary), timer_subsystem = SSsound_loops)

/**
 * The proc that handles actually playing the sound.
 *
 * Arguments:
 * * soundfile - The soundfile we want to play.
 * * volume_override - The volume we want to play the sound at, overriding the `volume` variable.
 */
/datum/looping_sound/proc/play(soundfile, volume_override)
	var/sound/sound_to_play = sound(soundfile)
	if(direct)
		sound_to_play.channel = sound_channel || SSsounds.random_available_channel()
		sound_to_play.volume = volume_override || volume //Use volume as fallback if theres no override
		SEND_SOUND(parent, sound_to_play)
	else
		playsound(
			parent,
			sound_to_play,
			volume,
			vary,
			extra_range,
			falloff_exponent = falloff_exponent,
			pressure_affected = pressure_affected,
			ignore_walls = ignore_walls,
			falloff_distance = falloff_distance,
			use_reverb = use_reverb
		)

/// Returns the sound we should now be playing.
/datum/looping_sound/proc/get_sound(_mid_sounds)
	var/list/play_from = _mid_sounds || mid_sounds
	if(!each_once)
		. = play_from
		while(!isfile(.) && !isnull(.))
			. = pick_weight_recursive(.)
		return .

	if(in_order)
		. = play_from
		audio_index++
		if(audio_index > length(play_from))
			audio_index = 1
		return .[audio_index]

	if(!length(cut_list))
		cut_list = shuffle(play_from.Copy())
	var/list/tree = list()
	. = cut_list
	while(!isfile(.) && !isnull(.))
		// Tree is a list of lists containign files
		// If an entry in the tree goes to 0 length, we cut it from the list
		tree += list(.)
		. = pick_weight_recursive(.)

	if(!isfile(.))
		return

	// Remove the sound file
	tree[length(tree)] -= .

	// Walk the tree bottom up, remove any lists that are empty
	// Don't do anything for the topmost list, cause we do not care
	for(var/i in length(tree) to 2 step -1)
		var/list/branch = tree[i]
		if(length(branch))
			break
		tree[i - 1] -= list(branch) // Remove the empty list
	return .



/// A proc that's there to handle delaying the main sounds if there's a start_sound, and simply starting the sound loop in general.
/datum/looping_sound/proc/on_start()
	var/start_wait = 0
	if(start_sound && !skip_starting_sounds)
		play(start_sound, start_volume)
		start_wait = start_length
	if(start_wait)
		timer_id = addtimer(CALLBACK(src, PROC_REF(start_sound_loop)), start_wait, TIMER_CLIENT_TIME | TIMER_DELETE_ME | TIMER_STOPPABLE, SSsound_loops)
	else
		start_sound_loop()

/// Stops sound playing on current channel, if specified
/datum/looping_sound/proc/stop_current()
	if(!sound_channel || !ismob(parent))
		return
	var/mob/mob_parent = parent
	mob_parent.stop_sound_channel(sound_channel)

/// Simple proc that's executed when the looping sound is stopped, so that the `end_sound` can be played, if there's one.
/datum/looping_sound/proc/on_stop()
	if(end_sound && loop_started)
		play(end_sound, end_volume)

/// A simple proc to change who our parent is set to, also handling registering and unregistering the QDELETING signals on the parent.
/datum/looping_sound/proc/set_parent(new_parent)
	if(parent)
		UnregisterSignal(parent, COMSIG_QDELETING)
	parent = new_parent
	if(parent)
		RegisterSignal(parent, COMSIG_QDELETING, PROC_REF(handle_parent_del))

/// A simple proc that lets us know whether the sounds are currently active or not.
/datum/looping_sound/proc/is_active()
	return !!timer_id

/// A simple proc to handle the deletion of the parent, so that it does not force it to hard-delete.
/datum/looping_sound/proc/handle_parent_del(datum/source)
	SIGNAL_HANDLER
	set_parent(null)
