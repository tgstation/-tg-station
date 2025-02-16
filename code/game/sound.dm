
///Default override for echo
/sound
	echo = list(
		0, // Direct
		0, // DirectHF
		-10000, // Room, -10000 means no low frequency sound reverb
		-10000, // RoomHF, -10000 means no high frequency sound reverb
		0, // Obstruction
		0, // ObstructionLFRatio
		0, // Occlusion
		0.25, // OcclusionLFRatio
		1.5, // OcclusionRoomRatio
		1.0, // OcclusionDirectRatio
		0, // Exclusion
		1.0, // ExclusionLFRatio
		0, // OutsideVolumeHF
		0, // DopplerFactor
		0, // RolloffFactor
		0, // RoomRolloffFactor
		1.0, // AirAbsorptionFactor
		0, // Flags (1 = Auto Direct, 2 = Auto Room, 4 = Auto RoomHF)
	)
	environment = SOUND_ENVIRONMENT_NONE //Default to none so sounds without overrides dont get reverb

/**
 * playsound is a proc used to play a 3D sound in a specific range. This uses SOUND_RANGE + extra_range to determine that.
 *
 * Arguments:
 * * source - Origin of sound.
 * * soundin - Either a file, or a string that can be used to get an SFX.
 * * vol - The volume of the sound, excluding falloff and pressure affection.
 * * vary - bool that determines if the sound changes pitch every time it plays.
 * * extrarange - modifier for sound range. This gets added on top of SOUND_RANGE.
 * * falloff_exponent - Rate of falloff for the audio. Higher means quicker drop to low volume. Should generally be over 1 to indicate a quick dive to 0 rather than a slow dive.
 * * frequency - playback speed of audio.
 * * channel - The channel the sound is played at.
 * * pressure_affected - Whether or not difference in pressure affects the sound (E.g. if you can hear in space).
 * * ignore_walls - Whether or not the sound can pass through walls.
 * * falloff_distance - Distance at which falloff begins. Sound is at peak volume (in regards to falloff) aslong as it is in this range.
 */
/proc/playsound(atom/source, soundin, vol as num, vary, extrarange as num, falloff_exponent = SOUND_FALLOFF_EXPONENT, frequency = null, channel = 0, pressure_affected = TRUE, ignore_walls = TRUE, falloff_distance = SOUND_DEFAULT_FALLOFF_DISTANCE, use_reverb = TRUE)
	if(isarea(source))
		CRASH("playsound(): source is an area")

	if(islist(soundin))
		CRASH("playsound(): soundin attempted to pass a list! Consider using pick()")

	var/turf/turf_source = get_turf(source)

	if (!turf_source || !soundin || !vol)
		return

	if(vol < SOUND_AUDIBLE_VOLUME_MIN) // never let sound go below SOUND_AUDIBLE_VOLUME_MIN or bad things will happen
		return

	//allocate a channel if necessary now so its the same for everyone
	channel = channel || SSsounds.random_available_channel()

	var/sound/S = isdatum(soundin) ? soundin : sound(get_sfx(soundin))
	var/maxdistance = SOUND_RANGE + extrarange
	var/source_z = turf_source.z
	var/list/listeners = SSmobs.clients_by_zlevel[source_z].Copy()

	. = list()//output everything that successfully heard the sound

	var/turf/above_turf = GET_TURF_ABOVE(turf_source)
	var/turf/below_turf = GET_TURF_BELOW(turf_source)

	var/audible_distance = CALCULATE_MAX_SOUND_AUDIBLE_DISTANCE(vol, maxdistance, falloff_distance, falloff_exponent)

	if(ignore_walls)
		if(above_turf && istransparentturf(above_turf))
			listeners += SSmobs.clients_by_zlevel[above_turf.z]

		if(below_turf && istransparentturf(turf_source))
			listeners += SSmobs.clients_by_zlevel[below_turf.z]

	else //these sounds don't carry through walls
		listeners = get_hearers_in_view(audible_distance, turf_source)

		if(above_turf && istransparentturf(above_turf))
			listeners += get_hearers_in_view(audible_distance, above_turf)

		if(below_turf && istransparentturf(turf_source))
			listeners += get_hearers_in_view(audible_distance, below_turf)

	for(var/mob/listening_mob in listeners | SSmobs.dead_players_by_zlevel[source_z])//observers always hear through walls
		if(get_dist(listening_mob, turf_source) <= audible_distance)
			listening_mob.playsound_local(turf_source, soundin, vol, vary, frequency, falloff_exponent, channel, pressure_affected, S, maxdistance, falloff_distance, 1, use_reverb)
			. += listening_mob

/**
 * Plays a sound with a specific point of origin for src mob
 * Affected by pressure, distance, terrain and environment (see arguments)
 *
 * Arguments:
 * * turf_source - The turf our sound originates from, if this is not a turf, the sound is played with no spatial audio
 * * soundin - Either a file, or a string that can be used to get an SFX.
 * * vol - The volume of the sound, excluding falloff and pressure affection.
 * * vary - bool that determines if the sound changes pitch every time it plays.
 * * frequency - playback speed of audio.
 * * falloff_exponent - Rate of falloff for the audio. Higher means quicker drop to low volume. Should generally be over 1 to indicate a quick dive to 0 rather than a slow dive.
 * * channel - Optional: The channel the sound is played at.
 * * pressure_affected - bool Whether or not difference in pressure affects the sound (E.g. if you can hear in space).
 * * sound_to_use - Optional: Will default to soundin when absent
 * * max_distance - number, determines the maximum distance of our sound
 * * falloff_distance - Distance at which falloff begins. Sound is at peak volume (in regards to falloff) aslong as it is in this range.
 * * distance_multiplier - Default 1, multiplies the maximum distance of our sound
 * * use_reverb - bool default TRUE, determines if our sound has reverb
 */
/mob/proc/playsound_local(turf/turf_source, soundin, vol as num, vary, frequency, falloff_exponent = SOUND_FALLOFF_EXPONENT, channel = 0, pressure_affected = TRUE, sound/sound_to_use, max_distance, falloff_distance = SOUND_DEFAULT_FALLOFF_DISTANCE, distance_multiplier = 1, use_reverb = TRUE)
	if(!client || !can_hear())
		return

	if(!sound_to_use)
		sound_to_use = sound(get_sfx(soundin))

	sound_to_use.wait = 0 //No queue
	sound_to_use.channel = channel || SSsounds.random_available_channel()
	sound_to_use.volume = vol

	if(vary)
		if(frequency)
			sound_to_use.frequency = frequency
		else
			sound_to_use.frequency = get_rand_frequency()

	var/distance = 0

	if(isturf(turf_source))
		var/turf/turf_loc = get_turf(src)

		//sound volume falloff with distance
		distance = get_dist(turf_loc, turf_source) * distance_multiplier

		if(max_distance) //If theres no max_distance we're not a 3D sound, so no falloff.
			sound_to_use.volume -= CALCULATE_SOUND_VOLUME(vol, distance, max_distance, falloff_distance, falloff_exponent)

		if(pressure_affected)
			//Atmosphere affects sound
			var/pressure_factor = 1
			var/datum/gas_mixture/hearer_env = turf_loc.return_air()
			var/datum/gas_mixture/source_env = turf_source.return_air()

			if(hearer_env && source_env)
				var/pressure = min(hearer_env.return_pressure(), source_env.return_pressure())
				if(pressure < ONE_ATMOSPHERE)
					pressure_factor = max((pressure - SOUND_MINIMUM_PRESSURE)/(ONE_ATMOSPHERE - SOUND_MINIMUM_PRESSURE), 0)
			else //space
				pressure_factor = 0

			if(distance <= 1)
				pressure_factor = max(pressure_factor, 0.15) //touching the source of the sound

			sound_to_use.volume *= pressure_factor
			//End Atmosphere affecting sound

		if(sound_to_use.volume < SOUND_AUDIBLE_VOLUME_MIN)
			return //No sound

		var/dx = turf_source.x - turf_loc.x // Hearing from the right/left
		sound_to_use.x = dx * distance_multiplier
		var/dz = turf_source.y - turf_loc.y // Hearing from infront/behind
		sound_to_use.z = dz * distance_multiplier
		var/dy = (turf_source.z - turf_loc.z) * 5 * distance_multiplier // Hearing from  above / below, multiplied by 5 because we assume height is further along coords.
		sound_to_use.y = dy

		sound_to_use.falloff = max_distance || 1 //use max_distance, else just use 1 as we are a direct sound so falloff isnt relevant.

		// Sounds can't have their own environment. A sound's environment will be:
		// 1. the mob's
		// 2. the area's (defaults to SOUND_ENVRIONMENT_NONE)
		if(sound_environment_override != SOUND_ENVIRONMENT_NONE)
			sound_to_use.environment = sound_environment_override
		else
			var/area/A = get_area(src)
			sound_to_use.environment = A.sound_environment

		if(use_reverb && sound_to_use.environment != SOUND_ENVIRONMENT_NONE) //We have reverb, reset our echo setting
			sound_to_use.echo[3] = 0 //Room setting, 0 means normal reverb
			sound_to_use.echo[4] = 0 //RoomHF setting, 0 means normal reverb.

	if(HAS_TRAIT(src, TRAIT_SOUND_DEBUGGED))
		to_chat(src, span_admin("Max Range-[max_distance] Distance-[distance] Vol-[round(sound_to_use.volume, 0.01)] Sound-[sound_to_use.file]"))

	SEND_SOUND(src, sound_to_use)

/proc/sound_to_playing_players(soundin, volume = 100, vary = FALSE, frequency = 0, channel = 0, pressure_affected = FALSE, sound/S)
	if(!S)
		S = sound(get_sfx(soundin))
	for(var/m in GLOB.player_list)
		if(ismob(m) && !isnewplayer(m))
			var/mob/M = m
			M.playsound_local(M, null, volume, vary, frequency, null, channel, pressure_affected, S)

/mob/proc/stop_sound_channel(chan)
	SEND_SOUND(src, sound(null, repeat = 0, wait = 0, channel = chan))

/mob/proc/set_sound_channel_volume(channel, volume)
	var/sound/S = sound(null, FALSE, FALSE, channel, volume)
	S.status = SOUND_UPDATE
	SEND_SOUND(src, S)

/client/proc/playtitlemusic(vol = 85)
	set waitfor = FALSE
	UNTIL(SSticker.login_music) //wait for SSticker init to set the login music

	var/volume_modifier = prefs.read_preference(/datum/preference/numeric/volume/sound_lobby_volume)
	if((prefs && volume_modifier) && !CONFIG_GET(flag/disallow_title_music))
		SEND_SOUND(src, sound(SSticker.login_music, repeat = 0, wait = 0, volume = volume_modifier, channel = CHANNEL_LOBBYMUSIC)) // MAD JAMS

///get a random frequency.
/proc/get_rand_frequency()
	return rand(32000, 55000)

///get_rand_frequency but lower range.
/proc/get_rand_frequency_low_range()
	return rand(38000, 45000)

///Used to convert a SFX define into a .ogg so we can add some variance to sounds. If soundin is already a .ogg, we simply return it
/proc/get_sfx(soundin)
	if(!istext(soundin))
		return soundin
	switch(soundin)
		if(SFX_SHATTER)
			soundin = pick(
				'sound/effects/glass/glassbr1.ogg',
				'sound/effects/glass/glassbr2.ogg',
				'sound/effects/glass/glassbr3.ogg',
				)
		if(SFX_EXPLOSION)
			soundin = pick(
				'sound/effects/explosion/explosion1.ogg',
				'sound/effects/explosion/explosion2.ogg',
				)
		if(SFX_EXPLOSION_CREAKING)
			soundin = pick(
				'sound/effects/explosion/explosioncreak1.ogg',
				'sound/effects/explosion/explosioncreak2.ogg',
				)
		if(SFX_HULL_CREAKING)
			soundin = pick(
				'sound/effects/creak/creak1.ogg',
				'sound/effects/creak/creak2.ogg',
				'sound/effects/creak/creak3.ogg',
				)
		if(SFX_SPARKS)
			soundin = pick(
				'sound/effects/sparks/sparks1.ogg',
				'sound/effects/sparks/sparks2.ogg',
				'sound/effects/sparks/sparks3.ogg',
				'sound/effects/sparks/sparks4.ogg',
				)
		if(SFX_RUSTLE)
			soundin = pick(
				'sound/effects/rustle/rustle1.ogg',
				'sound/effects/rustle/rustle2.ogg',
				'sound/effects/rustle/rustle3.ogg',
				'sound/effects/rustle/rustle4.ogg',
				'sound/effects/rustle/rustle5.ogg',
				)
		if(SFX_BODYFALL)
			soundin = pick(
				'sound/effects/bodyfall/bodyfall1.ogg',
				'sound/effects/bodyfall/bodyfall2.ogg',
				'sound/effects/bodyfall/bodyfall3.ogg',
				'sound/effects/bodyfall/bodyfall4.ogg',
				)
		if(SFX_PUNCH)
			soundin = pick(
				'sound/items/weapons/punch1.ogg',
				'sound/items/weapons/punch2.ogg',
				'sound/items/weapons/punch3.ogg',
				'sound/items/weapons/punch4.ogg',
				)
		if(SFX_CLOWN_STEP)
			soundin = pick(
				'sound/effects/footstep/clownstep1.ogg',
				'sound/effects/footstep/clownstep2.ogg',
				)
		if(SFX_SUIT_STEP)
			soundin = pick(
			'sound/items/handling/armor_rustle/riot_armor/suitstep1.ogg',
			'sound/items/handling/armor_rustle/riot_armor/suitstep2.ogg',
			)
		if(SFX_SWING_HIT)
			soundin = pick(
				'sound/items/weapons/genhit1.ogg',
				'sound/items/weapons/genhit2.ogg',
				'sound/items/weapons/genhit3.ogg',
				)
		if(SFX_HISS)
			soundin = pick(
				'sound/mobs/non-humanoids/hiss/hiss1.ogg',
				'sound/mobs/non-humanoids/hiss/hiss2.ogg',
				'sound/mobs/non-humanoids/hiss/hiss3.ogg',
				'sound/mobs/non-humanoids/hiss/hiss4.ogg',
				)
		if(SFX_PAGE_TURN)
			soundin = pick(
				'sound/effects/page_turn/pageturn1.ogg',
				'sound/effects/page_turn/pageturn2.ogg',
				'sound/effects/page_turn/pageturn3.ogg',
				)
		if(SFX_RICOCHET)
			soundin = pick(
				'sound/items/weapons/effects/ric1.ogg',
				'sound/items/weapons/effects/ric2.ogg',
				'sound/items/weapons/effects/ric3.ogg',
				'sound/items/weapons/effects/ric4.ogg',
				'sound/items/weapons/effects/ric5.ogg',
				)
		if(SFX_TERMINAL_TYPE)
			soundin = pick(list(
				'sound/machines/terminal/terminal_button01.ogg',
				'sound/machines/terminal/terminal_button02.ogg',
				'sound/machines/terminal/terminal_button03.ogg',
				'sound/machines/terminal/terminal_button04.ogg',
				'sound/machines/terminal/terminal_button05.ogg',
				'sound/machines/terminal/terminal_button06.ogg',
				'sound/machines/terminal/terminal_button07.ogg',
				'sound/machines/terminal/terminal_button08.ogg',
			))
		if(SFX_DESECRATION)
			soundin = pick(
				'sound/effects/desecration/desecration-01.ogg',
				'sound/effects/desecration/desecration-02.ogg',
				'sound/effects/desecration/desecration-03.ogg',
				)
		if(SFX_IM_HERE)
			soundin = pick(
				'sound/effects/hallucinations/im_here1.ogg',
				'sound/effects/hallucinations/im_here2.ogg',
				)
		if(SFX_CAN_OPEN)
			soundin = pick(
				'sound/items/can/can_open1.ogg',
				'sound/items/can/can_open2.ogg',
				'sound/items/can/can_open3.ogg',
				)
		if(SFX_BULLET_MISS)
			soundin = pick(
				'sound/items/weapons/bulletflyby.ogg',
				'sound/items/weapons/bulletflyby2.ogg',
				'sound/items/weapons/bulletflyby3.ogg',
				)
		if(SFX_REVOLVER_SPIN)
			soundin = pick(
				'sound/items/weapons/gun/revolver/spin1.ogg',
				'sound/items/weapons/gun/revolver/spin2.ogg',
				'sound/items/weapons/gun/revolver/spin3.ogg',
				)
		if(SFX_LAW)
			soundin = pick(list(
				'sound/mobs/non-humanoids/beepsky/creep.ogg',
				'sound/mobs/non-humanoids/beepsky/god.ogg',
				'sound/mobs/non-humanoids/beepsky/iamthelaw.ogg',
				'sound/mobs/non-humanoids/beepsky/insult.ogg',
				'sound/mobs/non-humanoids/beepsky/radio.ogg',
				'sound/mobs/non-humanoids/beepsky/secureday.ogg',
			))
		if(SFX_HONKBOT_E)
			soundin = pick(list(
				'sound/effects/pray.ogg',
				'sound/mobs/non-humanoids/frog/reee.ogg',
				'sound/items/airhorn/AirHorn.ogg',
				'sound/items/airhorn/AirHorn2.ogg',
				'sound/items/bikehorn.ogg',
				'sound/items/WEEOO1.ogg',
				'sound/machines/buzz/buzz-sigh.ogg',
				'sound/machines/ping.ogg',
				'sound/effects/magic/Fireball.ogg',
				'sound/misc/sadtrombone.ogg',
				'sound/mobs/non-humanoids/beepsky/creep.ogg',
				'sound/mobs/non-humanoids/beepsky/iamthelaw.ogg',
				'sound/mobs/non-humanoids/hiss/hiss1.ogg',
				'sound/items/weapons/bladeslice.ogg',
				'sound/items/weapons/flashbang.ogg',
			))
		if(SFX_GOOSE)
			soundin = pick(
				'sound/mobs/non-humanoids/goose/goose1.ogg',
				'sound/mobs/non-humanoids/goose/goose2.ogg',
				'sound/mobs/non-humanoids/goose/goose3.ogg',
				'sound/mobs/non-humanoids/goose/goose4.ogg',
				)
		if(SFX_WARPSPEED)
			soundin = 'sound/runtime/hyperspace/hyperspace_begin.ogg'
		if(SFX_SM_CALM)
			soundin = pick(list(
				'sound/machines/sm/accent/normal/1.ogg',
				'sound/machines/sm/accent/normal/2.ogg',
				'sound/machines/sm/accent/normal/3.ogg',
				'sound/machines/sm/accent/normal/4.ogg',
				'sound/machines/sm/accent/normal/5.ogg',
				'sound/machines/sm/accent/normal/6.ogg',
				'sound/machines/sm/accent/normal/7.ogg',
				'sound/machines/sm/accent/normal/8.ogg',
				'sound/machines/sm/accent/normal/9.ogg',
				'sound/machines/sm/accent/normal/10.ogg',
				'sound/machines/sm/accent/normal/11.ogg',
				'sound/machines/sm/accent/normal/12.ogg',
				'sound/machines/sm/accent/normal/13.ogg',
				'sound/machines/sm/accent/normal/14.ogg',
				'sound/machines/sm/accent/normal/15.ogg',
				'sound/machines/sm/accent/normal/16.ogg',
				'sound/machines/sm/accent/normal/17.ogg',
				'sound/machines/sm/accent/normal/18.ogg',
				'sound/machines/sm/accent/normal/19.ogg',
				'sound/machines/sm/accent/normal/20.ogg',
				'sound/machines/sm/accent/normal/21.ogg',
				'sound/machines/sm/accent/normal/22.ogg',
				'sound/machines/sm/accent/normal/23.ogg',
				'sound/machines/sm/accent/normal/24.ogg',
				'sound/machines/sm/accent/normal/25.ogg',
				'sound/machines/sm/accent/normal/26.ogg',
				'sound/machines/sm/accent/normal/27.ogg',
				'sound/machines/sm/accent/normal/28.ogg',
				'sound/machines/sm/accent/normal/29.ogg',
				'sound/machines/sm/accent/normal/30.ogg',
				'sound/machines/sm/accent/normal/31.ogg',
				'sound/machines/sm/accent/normal/32.ogg',
				'sound/machines/sm/accent/normal/33.ogg',
			))
		if(SFX_SM_DELAM)
			soundin = pick(list(
				'sound/machines/sm/accent/delam/1.ogg',
				'sound/machines/sm/accent/delam/2.ogg',
				'sound/machines/sm/accent/delam/3.ogg',
				'sound/machines/sm/accent/delam/4.ogg',
				'sound/machines/sm/accent/delam/5.ogg',
				'sound/machines/sm/accent/delam/6.ogg',
				'sound/machines/sm/accent/delam/7.ogg',
				'sound/machines/sm/accent/delam/8.ogg',
				'sound/machines/sm/accent/delam/9.ogg',
				'sound/machines/sm/accent/delam/10.ogg',
				'sound/machines/sm/accent/delam/11.ogg',
				'sound/machines/sm/accent/delam/12.ogg',
				'sound/machines/sm/accent/delam/13.ogg',
				'sound/machines/sm/accent/delam/14.ogg',
				'sound/machines/sm/accent/delam/15.ogg',
				'sound/machines/sm/accent/delam/16.ogg',
				'sound/machines/sm/accent/delam/17.ogg',
				'sound/machines/sm/accent/delam/18.ogg',
				'sound/machines/sm/accent/delam/19.ogg',
				'sound/machines/sm/accent/delam/20.ogg',
				'sound/machines/sm/accent/delam/21.ogg',
				'sound/machines/sm/accent/delam/22.ogg',
				'sound/machines/sm/accent/delam/23.ogg',
				'sound/machines/sm/accent/delam/24.ogg',
				'sound/machines/sm/accent/delam/25.ogg',
				'sound/machines/sm/accent/delam/26.ogg',
				'sound/machines/sm/accent/delam/27.ogg',
				'sound/machines/sm/accent/delam/28.ogg',
				'sound/machines/sm/accent/delam/29.ogg',
				'sound/machines/sm/accent/delam/30.ogg',
				'sound/machines/sm/accent/delam/31.ogg',
				'sound/machines/sm/accent/delam/32.ogg',
				'sound/machines/sm/accent/delam/33.ogg',
			))
		if(SFX_HYPERTORUS_CALM)
			soundin = pick(list(
				'sound/machines/sm/accent/normal/1.ogg',
				'sound/machines/sm/accent/normal/2.ogg',
				'sound/machines/sm/accent/normal/3.ogg',
				'sound/machines/sm/accent/normal/4.ogg',
				'sound/machines/sm/accent/normal/5.ogg',
				'sound/machines/sm/accent/normal/6.ogg',
				'sound/machines/sm/accent/normal/7.ogg',
				'sound/machines/sm/accent/normal/8.ogg',
				'sound/machines/sm/accent/normal/9.ogg',
				'sound/machines/sm/accent/normal/10.ogg',
				'sound/machines/sm/accent/normal/11.ogg',
				'sound/machines/sm/accent/normal/12.ogg',
				'sound/machines/sm/accent/normal/13.ogg',
				'sound/machines/sm/accent/normal/14.ogg',
				'sound/machines/sm/accent/normal/15.ogg',
				'sound/machines/sm/accent/normal/16.ogg',
				'sound/machines/sm/accent/normal/17.ogg',
				'sound/machines/sm/accent/normal/18.ogg',
				'sound/machines/sm/accent/normal/19.ogg',
				'sound/machines/sm/accent/normal/20.ogg',
				'sound/machines/sm/accent/normal/21.ogg',
				'sound/machines/sm/accent/normal/22.ogg',
				'sound/machines/sm/accent/normal/23.ogg',
				'sound/machines/sm/accent/normal/24.ogg',
				'sound/machines/sm/accent/normal/25.ogg',
				'sound/machines/sm/accent/normal/26.ogg',
				'sound/machines/sm/accent/normal/27.ogg',
				'sound/machines/sm/accent/normal/28.ogg',
				'sound/machines/sm/accent/normal/29.ogg',
				'sound/machines/sm/accent/normal/30.ogg',
				'sound/machines/sm/accent/normal/31.ogg',
				'sound/machines/sm/accent/normal/32.ogg',
				'sound/machines/sm/accent/normal/33.ogg',
			))
		if(SFX_HYPERTORUS_MELTING)
			soundin = pick(list(
				'sound/machines/sm/accent/delam/1.ogg',
				'sound/machines/sm/accent/delam/2.ogg',
				'sound/machines/sm/accent/delam/3.ogg',
				'sound/machines/sm/accent/delam/4.ogg',
				'sound/machines/sm/accent/delam/5.ogg',
				'sound/machines/sm/accent/delam/6.ogg',
				'sound/machines/sm/accent/delam/7.ogg',
				'sound/machines/sm/accent/delam/8.ogg',
				'sound/machines/sm/accent/delam/9.ogg',
				'sound/machines/sm/accent/delam/10.ogg',
				'sound/machines/sm/accent/delam/11.ogg',
				'sound/machines/sm/accent/delam/12.ogg',
				'sound/machines/sm/accent/delam/13.ogg',
				'sound/machines/sm/accent/delam/14.ogg',
				'sound/machines/sm/accent/delam/15.ogg',
				'sound/machines/sm/accent/delam/16.ogg',
				'sound/machines/sm/accent/delam/17.ogg',
				'sound/machines/sm/accent/delam/18.ogg',
				'sound/machines/sm/accent/delam/19.ogg',
				'sound/machines/sm/accent/delam/20.ogg',
				'sound/machines/sm/accent/delam/21.ogg',
				'sound/machines/sm/accent/delam/22.ogg',
				'sound/machines/sm/accent/delam/23.ogg',
				'sound/machines/sm/accent/delam/24.ogg',
				'sound/machines/sm/accent/delam/25.ogg',
				'sound/machines/sm/accent/delam/26.ogg',
				'sound/machines/sm/accent/delam/27.ogg',
				'sound/machines/sm/accent/delam/28.ogg',
				'sound/machines/sm/accent/delam/29.ogg',
				'sound/machines/sm/accent/delam/30.ogg',
				'sound/machines/sm/accent/delam/31.ogg',
				'sound/machines/sm/accent/delam/32.ogg',
				'sound/machines/sm/accent/delam/33.ogg',
			))
		if(SFX_CRUNCHY_BUSH_WHACK)
			soundin = pick(
				'sound/effects/bush/crunchybushwhack1.ogg',
				'sound/effects/bush/crunchybushwhack2.ogg',
				'sound/effects/bush/crunchybushwhack3.ogg',
				)
		if(SFX_TREE_CHOP)
			soundin = pick(
				'sound/effects/treechop/treechop1.ogg',
				'sound/effects/treechop/treechop2.ogg',
				'sound/effects/treechop/treechop3.ogg',
				)
		if(SFX_ROCK_TAP)
			soundin = pick(
				'sound/effects/rock/rocktap1.ogg',
				'sound/effects/rock/rocktap2.ogg',
				'sound/effects/rock/rocktap3.ogg',
				)
		if(SFX_SEAR)
			soundin = 'sound/items/weapons/sear.ogg'
		if(SFX_REEL)
			soundin = pick(
				'sound/items/reel/reel1.ogg',
				'sound/items/reel/reel2.ogg',
				'sound/items/reel/reel3.ogg',
				'sound/items/reel/reel4.ogg',
				'sound/items/reel/reel5.ogg',
			)
		if(SFX_RATTLE)
			soundin = pick(
				'sound/items/rattle/rattle1.ogg',
				'sound/items/rattle/rattle2.ogg',
				'sound/items/rattle/rattle3.ogg',
			)
		if(SFX_PORTAL_CLOSE)
			soundin = 'sound/effects/portal/portal_close.ogg'
		if(SFX_PORTAL_ENTER)
			soundin = 'sound/effects/portal/portal_travel.ogg'
		if(SFX_PORTAL_CREATED)
			soundin = pick(
				'sound/effects/portal/portal_open_1.ogg',
				'sound/effects/portal/portal_open_2.ogg',
				'sound/effects/portal/portal_open_3.ogg',
			)
		if(SFX_SCREECH)
			soundin = pick(
				'sound/mobs/non-humanoids/monkey/monkey_screech_1.ogg',
				'sound/mobs/non-humanoids/monkey/monkey_screech_2.ogg',
				'sound/mobs/non-humanoids/monkey/monkey_screech_3.ogg',
				'sound/mobs/non-humanoids/monkey/monkey_screech_4.ogg',
				'sound/mobs/non-humanoids/monkey/monkey_screech_5.ogg',
				'sound/mobs/non-humanoids/monkey/monkey_screech_6.ogg',
				'sound/mobs/non-humanoids/monkey/monkey_screech_7.ogg',
			)
		if(SFX_TOOL_SWITCH)
			soundin = 'sound/items/tools/tool_switch.ogg'
		if(SFX_KEYBOARD_CLICKS)
			soundin = pick(
				'sound/machines/computer/keyboard_clicks_1.ogg',
				'sound/machines/computer/keyboard_clicks_2.ogg',
				'sound/machines/computer/keyboard_clicks_3.ogg',
				'sound/machines/computer/keyboard_clicks_4.ogg',
				'sound/machines/computer/keyboard_clicks_5.ogg',
				'sound/machines/computer/keyboard_clicks_6.ogg',
				'sound/machines/computer/keyboard_clicks_7.ogg',
			)
		if(SFX_STONE_DROP)
			soundin = pick(
				'sound/items/stones/stone_drop1.ogg',
				'sound/items/stones/stone_drop2.ogg',
				'sound/items/stones/stone_drop3.ogg',
			)
		if(SFX_STONE_PICKUP)
			soundin = pick(
				'sound/items/stones/stone_pick_up1.ogg',
				'sound/items/stones/stone_pick_up2.ogg',
			)
		if(SFX_MUFFLED_SPEECH)
			soundin = pick(
				'sound/effects/muffspeech/muffspeech1.ogg',
				'sound/effects/muffspeech/muffspeech2.ogg',
				'sound/effects/muffspeech/muffspeech3.ogg',
				'sound/effects/muffspeech/muffspeech4.ogg',
				'sound/effects/muffspeech/muffspeech5.ogg',
				'sound/effects/muffspeech/muffspeech6.ogg',
				'sound/effects/muffspeech/muffspeech7.ogg',
				'sound/effects/muffspeech/muffspeech8.ogg',
				'sound/effects/muffspeech/muffspeech9.ogg',
			)
		if(SFX_DEFAULT_FISH_SLAP)
			soundin = 'sound/mobs/non-humanoids/fish/fish_slap1.ogg'
		if(SFX_ALT_FISH_SLAP)
			soundin = 'sound/mobs/non-humanoids/fish/fish_slap2.ogg'
		if(SFX_FISH_PICKUP)
			soundin = pick(
				'sound/mobs/non-humanoids/fish/fish_pickup1.ogg',
				'sound/mobs/non-humanoids/fish/fish_pickup2.ogg',
			)
		if(SFX_LIQUID_POUR)
			soundin = pick(
				'sound/effects/liquid_pour/liquid_pour1.ogg',
				'sound/effects/liquid_pour/liquid_pour2.ogg',
				'sound/effects/liquid_pour/liquid_pour3.ogg',
			)
		if(SFX_SNORE_FEMALE)
			soundin = pick_weight(list(
				'sound/mobs/humanoids/human/snore/snore_female1.ogg' = 33,
				'sound/mobs/humanoids/human/snore/snore_female2.ogg' = 33,
				'sound/mobs/humanoids/human/snore/snore_female3.ogg' = 33,
				'sound/mobs/humanoids/human/snore/snore_mimimi1.ogg' = 1,
			))
		if(SFX_SNORE_MALE)
			soundin = pick_weight(list(
				'sound/mobs/humanoids/human/snore/snore_male1.ogg' = 20,
				'sound/mobs/humanoids/human/snore/snore_male2.ogg' = 20,
				'sound/mobs/humanoids/human/snore/snore_male3.ogg' = 20,
				'sound/mobs/humanoids/human/snore/snore_male4.ogg' = 20,
				'sound/mobs/humanoids/human/snore/snore_male5.ogg' = 20,
				'sound/mobs/humanoids/human/snore/snore_mimimi2.ogg' = 1,
			))
		if(SFX_CAT_MEOW)
			soundin = pick_weight(list(
				'sound/mobs/non-humanoids/cat/cat_meow1.ogg' = 33,
				'sound/mobs/non-humanoids/cat/cat_meow2.ogg' = 33,
				'sound/mobs/non-humanoids/cat/cat_meow3.ogg' = 33,
				'sound/mobs/non-humanoids/cat/oranges_meow1.ogg' = 1,
			))
		if(SFX_CAT_PURR)
			soundin = pick(
				'sound/mobs/non-humanoids/cat/cat_purr1.ogg',
				'sound/mobs/non-humanoids/cat/cat_purr2.ogg',
				'sound/mobs/non-humanoids/cat/cat_purr3.ogg',
				'sound/mobs/non-humanoids/cat/cat_purr4.ogg',
			)
		if(SFX_DEFAULT_LIQUID_SLOSH)
			soundin = pick(
				'sound/items/handling/reagent_containers/default/default_liquid_slosh1.ogg',
				'sound/items/handling/reagent_containers/default/default_liquid_slosh2.ogg',
				'sound/items/handling/reagent_containers/default/default_liquid_slosh3.ogg',
				'sound/items/handling/reagent_containers/default/default_liquid_slosh4.ogg',
				'sound/items/handling/reagent_containers/default/default_liquid_slosh5.ogg',
			)
		if(SFX_PLASTIC_BOTTLE_LIQUID_SLOSH)
			soundin = pick(
				'sound/items/handling/reagent_containers/plastic_bottle/plastic_bottle_liquid_slosh1.ogg',
				'sound/items/handling/reagent_containers/plastic_bottle/plastic_bottle_liquid_slosh2.ogg',
			)
		if(SFX_PLATE_ARMOR_RUSTLE)
			soundin = pick_weight(list(
				'sound/items/handling/armor_rustle/plate_armor/plate_armor_rustle1.ogg' = 8, //longest sound is rarer.
				'sound/items/handling/armor_rustle/plate_armor/plate_armor_rustle2.ogg' = 23,
				'sound/items/handling/armor_rustle/plate_armor/plate_armor_rustle3.ogg' = 23,
				'sound/items/handling/armor_rustle/plate_armor/plate_armor_rustle4.ogg' = 23,
				'sound/items/handling/armor_rustle/plate_armor/plate_armor_rustle5.ogg' = 23,
			))
		if(SFX_PIG_OINK)
			soundin = pick(
				'sound/mobs/non-humanoids/pig/pig1.ogg',
				'sound/mobs/non-humanoids/pig/pig2.ogg',
			)
		if(SFX_VISOR_DOWN)
			soundin = pick(
				'sound/items/handling/helmet/visor_down1.ogg',
				'sound/items/handling/helmet/visor_down2.ogg',
				'sound/items/handling/helmet/visor_down3.ogg',
			)
		if(SFX_VISOR_UP)
			soundin = pick(
				'sound/items/handling/helmet/visor_up1.ogg',
				'sound/items/handling/helmet/visor_up2.ogg',
			)
		if(SFX_GROWL)
			soundin = pick(
				'sound/mobs/non-humanoids/dog/growl1.ogg',
				'sound/mobs/non-humanoids/dog/growl2.ogg',
			)
		if(SFX_GROWL)
			soundin = pick(
				'sound/effects/wounds/sizzle1.ogg',
				'sound/effects/wounds/sizzle2.ogg',
			)
		if(SFX_POLAROID)
			soundin = pick(
				'sound/items/polaroid/polaroid1.ogg',
				'sound/items/polaroid/polaroid2.ogg',
			)
		if(SFX_HALLUCINATION_TURN_AROUND)
			soundin = pick(
				'sound/effects/hallucinations/turn_around1.ogg',
				'sound/effects/hallucinations/turn_around2.ogg',
			)
		if(SFX_HALLUCINATION_I_SEE_YOU)
			soundin = pick(
				'sound/effects/hallucinations/i_see_you1.ogg',
				'sound/effects/hallucinations/i_see_you2.ogg',
			)
		if(SFX_LOW_HISS)
			soundin = pick(
				'sound/mobs/non-humanoids/hiss/lowHiss2.ogg',
				'sound/mobs/non-humanoids/hiss/lowHiss3.ogg',
				'sound/mobs/non-humanoids/hiss/lowHiss4.ogg',
			)
		if(SFX_HALLUCINATION_I_M_HERE)
			soundin = pick(
				'sound/effects/hallucinations/im_here1.ogg',
				'sound/effects/hallucinations/im_here2.ogg',
			)
		if(SFX_HALLUCINATION_OVER_HERE)
			soundin = pick(
				'sound/effects/hallucinations/over_here2.ogg',
				'sound/effects/hallucinations/over_here3.ogg',
			)
		if(SFX_INDUSTRIAL_SCAN)
			soundin = pick(
				'sound/effects/industrial_scan/industrial_scan1.ogg',
				'sound/effects/industrial_scan/industrial_scan2.ogg',
				'sound/effects/industrial_scan/industrial_scan3.ogg',
			)
		if(SFX_MALE_SIGH)
			soundin = pick(
				'sound/mobs/humanoids/human/sigh/male_sigh1.ogg',
				'sound/mobs/humanoids/human/sigh/male_sigh2.ogg',
				'sound/mobs/humanoids/human/sigh/male_sigh3.ogg',
			)
		if(SFX_FEMALE_SIGH)
			soundin = pick(
				'sound/mobs/humanoids/human/sigh/female_sigh1.ogg',
				'sound/mobs/humanoids/human/sigh/female_sigh2.ogg',
				'sound/mobs/humanoids/human/sigh/female_sigh3.ogg',
			)
		if(SFX_WRITING_PEN)
			soundin = pick(
				'sound/effects/writing_pen/writing_pen1.ogg',
				'sound/effects/writing_pen/writing_pen2.ogg',
				'sound/effects/writing_pen/writing_pen3.ogg',
				'sound/effects/writing_pen/writing_pen4.ogg',
				'sound/effects/writing_pen/writing_pen5.ogg',
				'sound/effects/writing_pen/writing_pen6.ogg',
				'sound/effects/writing_pen/writing_pen7.ogg',
			)
		if(SFX_CLOWN_CAR_LOAD)
			soundin = pick(
				'sound/vehicles/clown_car/clowncar_load1.ogg',
				'sound/vehicles/clown_car/clowncar_load2.ogg',
			)
		if(SFX_SEATBELT_BUCKLE)
			soundin = pick(
				'sound/machines/buckle/buckle1.ogg',
				'sound/machines/buckle/buckle2.ogg',
				'sound/machines/buckle/buckle3.ogg',
			)
		if(SFX_SEATBELT_UNBUCKLE)
			soundin = pick(
				'sound/machines/buckle/unbuckle1.ogg',
				'sound/machines/buckle/unbuckle2.ogg',
				'sound/machines/buckle/unbuckle3.ogg',
			)
		if(SFX_HEADSET_EQUIP)
			soundin = pick(
				'sound/items/equip/headset_equip1.ogg',
				'sound/items/equip/headset_equip2.ogg',
			)
		if(SFX_HEADSET_PICKUP)
			soundin = pick(
				'sound/items/handling/headset/headset_pickup1.ogg',
				'sound/items/handling/headset/headset_pickup2.ogg',
				'sound/items/handling/headset/headset_pickup3.ogg',
			)
		if(SFX_BANDAGE_BEGIN)
			soundin = pick(
				'sound/items/gauze/bandage_begin1.ogg',
				'sound/items/gauze/bandage_begin2.ogg',
				'sound/items/gauze/bandage_begin3.ogg',
				'sound/items/gauze/bandage_begin4.ogg',
			)
		if(SFX_BANDAGE_END)
			soundin = pick(
				'sound/items/gauze/bandage_end1.ogg',
				'sound/items/gauze/bandage_end2.ogg',
				'sound/items/gauze/bandage_end3.ogg',
				'sound/items/gauze/bandage_end4.ogg',
			)
		// Old cloth sounds are named cloth_...1.ogg, I wanted to keep them so these new ones go further down the line.
		if(SFX_CLOTH_DROP)
			soundin = pick(
				'sound/items/handling/cloth/cloth_drop2.ogg',
				'sound/items/handling/cloth/cloth_drop3.ogg',
				'sound/items/handling/cloth/cloth_drop4.ogg',
				'sound/items/handling/cloth/cloth_drop5.ogg',
			)
		if(SFX_CLOTH_PICKUP)
			soundin = pick(
				'sound/items/handling/cloth/cloth_pickup2.ogg',
				'sound/items/handling/cloth/cloth_pickup3.ogg',
				'sound/items/handling/cloth/cloth_pickup4.ogg',
				'sound/items/handling/cloth/cloth_pickup5.ogg',
			)
		if(SFX_SUTURE_BEGIN)
			soundin = pick(
				'sound/items/suture/suture_begin1.ogg',
			)
		if(SFX_SUTURE_CONTINUOUS)
			soundin = pick(
				'sound/items/suture/suture_continuous1.ogg',
				'sound/items/suture/suture_continuous2.ogg',
				'sound/items/suture/suture_continuous3.ogg',
			)
		if(SFX_SUTURE_END)
			soundin = pick(
				'sound/items/suture/suture_end1.ogg',
				'sound/items/suture/suture_end2.ogg',
				'sound/items/suture/suture_end3.ogg',
			)
		if(SFX_SUTURE_PICKUP)
			soundin = pick(
				'sound/items/handling/suture/needle_pickup1.ogg',
				'sound/items/handling/suture/needle_pickup2.ogg',
			)
		if(SFX_SUTURE_DROP)
			soundin = pick(

				'sound/items/handling/suture/needle_drop1.ogg',
				'sound/items/handling/suture/needle_drop2.ogg',
				'sound/items/handling/suture/needle_drop3.ogg',
			)
	return soundin
