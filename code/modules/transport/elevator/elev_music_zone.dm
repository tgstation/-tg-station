GLOBAL_LIST_EMPTY(elevator_music)

/obj/effect/abstract/elevator_music_zone
	name = "elevator music speaker"
	desc = "You can't see this because it's mounted on the roof of the elevator."
	anchored = TRUE
	invisibility = INVISIBILITY_MAXIMUM // Setting this to ABSTRACT means it isn't moved by the lift
	icon = 'icons/obj/art/musician.dmi'
	icon_state = "piano"
	/// What specific_transport_id do we link with?
	var/linked_elevator_id = ""
	/// Radius around this map helper in which to play the sound
	var/range = 1
	/// Sound loop type to use
	var/soundloop_type = /datum/looping_sound/local_forecast
	/// Proximity monitor which handles playing sounds to clients
	var/datum/proximity_monitor/advanced/elevator_music_area/sound_player

/obj/effect/abstract/elevator_music_zone/Initialize(mapload)
	. = ..()
	if (!linked_elevator_id)
		log_mapping("No elevator ID for elevator music provided at [AREACOORD(src)].")
		return INITIALIZE_HINT_QDEL

	GLOB.elevator_music[linked_elevator_id] = src
	sound_player = new(src, range = src.range, soundloop_type = src.soundloop_type)

/obj/effect/abstract/elevator_music_zone/Destroy(force)
	GLOB.elevator_music -= src
	return ..()

/obj/effect/abstract/elevator_music_zone/proc/link_to_panel(atom/elevator_panel)
	RegisterSignal(elevator_panel, COMSIG_MACHINERY_POWER_RESTORED, PROC_REF(on_panel_powered))
	RegisterSignal(elevator_panel, COMSIG_MACHINERY_POWER_LOST, PROC_REF(on_panel_depowered))
	RegisterSignal(elevator_panel, COMSIG_QDELETING, PROC_REF(on_panel_destroyed))

/// Start sound loops when power is restored
/obj/effect/abstract/elevator_music_zone/proc/on_panel_powered()
	SIGNAL_HANDLER
	sound_player.turn_on()

/// Stop sound loops if power is lost
/obj/effect/abstract/elevator_music_zone/proc/on_panel_depowered()
	SIGNAL_HANDLER
	sound_player.turn_off()

/// Die if panel is destroyed, although currently they are invincible
/obj/effect/abstract/elevator_music_zone/proc/on_panel_destroyed()
	SIGNAL_HANDLER
	qdel(src)

/// Load or unload a looping sound when mobs enter or exit the area
/datum/proximity_monitor/advanced/elevator_music_area
	edge_is_a_field = TRUE
	/// Are we currently playing sounds?
	var/enabled = TRUE
	/// Looping sound datum type to play
	var/soundloop_type
	/// Assoc list of mobs to sound loops currently playing
	var/list/tracked_mobs = list()

/datum/proximity_monitor/advanced/elevator_music_area/New(atom/_host, range, _ignore_if_not_on_turf, soundloop_type)
	. = ..()
	src.soundloop_type = soundloop_type

/datum/proximity_monitor/advanced/elevator_music_area/Destroy()
	QDEL_LIST_ASSOC_VAL(tracked_mobs)
	return ..()

/datum/proximity_monitor/advanced/elevator_music_area/field_turf_crossed(mob/entered, turf/old_location, turf/new_location)
	if (!istype(entered) || !entered.mind)
		return

	if (entered in tracked_mobs)
		return
	var/pref_volume = entered.client?.prefs.read_preference(/datum/preference/numeric/volume/sound_ambience_volume)
	if (pref_volume > 0)
		var/datum/looping_sound/soundloop = new soundloop_type(_parent = entered, _direct = TRUE, start_immediately = enabled)
		soundloop.volume *= pref_volume/100
		tracked_mobs[entered] = soundloop
	else
		tracked_mobs[entered] = null // Still add it to the list so we don't keep making this check
	RegisterSignal(entered, COMSIG_QDELETING, PROC_REF(mob_destroyed))

/datum/proximity_monitor/advanced/elevator_music_area/field_turf_uncrossed(mob/exited, turf/old_location, turf/new_location)
	if (!(exited in tracked_mobs))
		return
	if ((new_location in field_turfs) || (new_location in edge_turfs))
		return
	qdel(tracked_mobs[exited])
	tracked_mobs -= exited
	UnregisterSignal(exited, COMSIG_QDELETING)

/// Remove references on mob deletion
/datum/proximity_monitor/advanced/elevator_music_area/proc/mob_destroyed(mob/former_mob)
	SIGNAL_HANDLER
	if (former_mob in tracked_mobs)
		qdel(tracked_mobs[former_mob])
		tracked_mobs -= former_mob

/// Start sound loops playing
/datum/proximity_monitor/advanced/elevator_music_area/proc/turn_on()
	enabled = TRUE
	for (var/mob as anything in tracked_mobs)
		var/datum/looping_sound/loop = tracked_mobs[mob]
		loop.start()

/// Stop active sound loops
/datum/proximity_monitor/advanced/elevator_music_area/proc/turn_off()
	enabled = FALSE
	for (var/mob as anything in tracked_mobs)
		var/datum/looping_sound/loop = tracked_mobs[mob]
		loop.stop()
