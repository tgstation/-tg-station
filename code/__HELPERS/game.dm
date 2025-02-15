///Time before being allowed to select a new cult leader again
#define CULT_POLL_WAIT (240 SECONDS)

/// Returns either the error landmark or the location of the room. Needless to say, if this is used, it means things have gone awry.
#define GET_ERROR_ROOM ((locate(/obj/effect/landmark/error) in GLOB.landmarks_list) || locate(4,4,1))

///Returns the name of the area the atom is in
/proc/get_area_name(atom/checked_atom, format_text = FALSE)
	var/area/checked_area = isarea(checked_atom) ? checked_atom : get_area(checked_atom)
	if(!checked_area)
		return null
	return format_text ? format_text(checked_area.name) : checked_area.name

///Tries to move an atom to an adjacent turf, return TRUE if successful
/proc/try_move_adjacent(atom/movable/atom_to_move, trydir)
	var/turf/atom_turf = get_turf(atom_to_move)
	if(trydir)
		if(atom_to_move.Move(get_step(atom_turf, trydir)))
			return TRUE
	for(var/direction in (GLOB.cardinals-trydir))
		if(atom_to_move.Move(get_step(atom_turf, direction)))
			return TRUE
	return FALSE

///Return the mob type that is being controlled by a ckey
/proc/get_mob_by_key(key)
	var/ckey = ckey(key)
	for(var/player in GLOB.player_list)
		var/mob/player_mob = player
		if(player_mob.ckey == ckey)
			return player_mob
	return null

/**
 * Checks if the passed mind has a mob that is "alive"
 *
 * * player_mind - who to check for alive status
 * * enforce_human - if TRUE, the checks fails if the mind's mob is a silicon, brain, or infectious zombie.
 *
 * Returns TRUE if they're alive, FALSE otherwise
 */
/proc/considered_alive(datum/mind/player_mind, enforce_human = TRUE)
	if(player_mind?.current)
		if(enforce_human)
			var/mob/living/carbon/human/player_mob = player_mind.current

			if(player_mob.stat == DEAD)
				return FALSE
			if(issilicon(player_mob) || isbrain(player_mob))
				return FALSE
			if(istype(player_mob) && (player_mob.dna?.species?.id == SPECIES_ZOMBIE_INFECTIOUS))
				return FALSE
			return TRUE

		else if(isliving(player_mind.current))
			return (player_mind.current.stat != DEAD)

	return FALSE

/**
 * Exiled check
 *
 * Checks if the current body of the mind has an exile implant and is currently in
 * an away mission. Returns FALSE if any of those conditions aren't met.
 */
/proc/considered_exiled(datum/mind/player_mind)
	if(!ishuman(player_mind?.current))
		return FALSE
	for(var/obj/item/implant/implant_check in player_mind.current.implants)
		if(istype(implant_check, /obj/item/implant/exile && player_mind.current.onAwayMission()))
			return TRUE

///Checks if a player is considered AFK
/proc/considered_afk(datum/mind/player_mind)
	return !player_mind || !player_mind.current || !player_mind.current.client || player_mind.current.client.is_afk()

///Return an object with a new maptext (not currently in use)
/proc/screen_text(atom/movable/object_to_change, maptext = "", screen_loc = "CENTER-7,CENTER-7", maptext_height = 480, maptext_width = 480)
	if(!istype(object_to_change))
		object_to_change = new /atom/movable/screen/text()
	object_to_change.maptext = MAPTEXT(maptext)
	object_to_change.maptext_height = maptext_height
	object_to_change.maptext_width = maptext_width
	object_to_change.screen_loc = screen_loc
	return object_to_change

/// Adds an image to a client's `.images`. Useful as a callback.
/proc/add_image_to_client(image/image_to_remove, client/add_to)
	add_to?.images += image_to_remove

/// Like add_image_to_client, but will add the image from a list of clients
/proc/add_image_to_clients(image/image_to_remove, list/show_to)
	for(var/client/add_to in show_to)
		add_to.images += image_to_remove

/// Removes an image from a client's `.images`. Useful as a callback.
/proc/remove_image_from_client(image/image_to_remove, client/remove_from)
	remove_from?.images -= image_to_remove

/// Like remove_image_from_client, but will remove the image from a list of clients
/proc/remove_image_from_clients(image/image_to_remove, list/hide_from)
	for(var/client/remove_from in hide_from)
		remove_from.images -= image_to_remove

/// Add an image to a list of clients and calls a proc to remove it after a duration
/proc/flick_overlay_global(image/image_to_show, list/show_to, duration)
	if(!show_to || !length(show_to) || !image_to_show)
		return
	for(var/client/add_to in show_to)
		add_to.images += image_to_show
	addtimer(CALLBACK(GLOBAL_PROC, GLOBAL_PROC_REF(remove_image_from_clients), image_to_show, show_to), duration, TIMER_CLIENT_TIME)

///Flicks a certain overlay onto an atom, handling icon_state strings
/atom/proc/flick_overlay(image_to_show, list/show_to, duration, layer)
	var/image/passed_image = \
		istext(image_to_show) \
			? image(icon, src, image_to_show, layer) \
			: image_to_show

	flick_overlay_global(passed_image, show_to, duration)

/**
 * Helper atom that copies an appearance and exists for a period
*/
/atom/movable/flick_visual

/// Takes the passed in MA/icon_state, mirrors it onto ourselves, and displays that in world for duration seconds
/// Returns the displayed object, you can animate it and all, but you don't own it, we'll delete it after the duration
/atom/proc/flick_overlay_view(mutable_appearance/display, duration)
	if(!display)
		return null

	var/mutable_appearance/passed_appearance = \
		istext(display) \
			? mutable_appearance(icon, display, layer) \
			: display

	// If you don't give it a layer, we assume you want it to layer on top of this atom
	// Because this is vis_contents, we need to set the layer manually (you can just set it as you want on return if this is a problem)
	if(passed_appearance.layer == FLOAT_LAYER)
		passed_appearance.layer = layer + 0.1
	// This is faster then pooling. I promise
	var/atom/movable/flick_visual/visual = new()
	visual.appearance = passed_appearance
	visual.mouse_opacity = MOUSE_OPACITY_TRANSPARENT
	// I hate /area
	var/atom/movable/lies_to_children = src
	lies_to_children.vis_contents += visual
	QDEL_IN_CLIENT_TIME(visual, duration)
	return visual

/area/flick_overlay_view(mutable_appearance/display, duration)
	return

///Get active players who are playing in the round
/proc/get_active_player_count(alive_check = FALSE, afk_check = FALSE, human_check = FALSE)
	var/active_players = 0
	for(var/i = 1; i <= GLOB.player_list.len; i++)
		var/mob/player_mob = GLOB.player_list[i]
		if(!player_mob?.client)
			continue
		if(alive_check && player_mob.stat)
			continue
		else if(afk_check && player_mob.client.is_afk())
			continue
		else if(human_check && !ishuman(player_mob))
			continue
		else if(isnewplayer(player_mob)) // exclude people in the lobby
			continue
		else if(isobserver(player_mob)) // Ghosts are fine if they were playing once (didn't start as observers)
			var/mob/dead/observer/ghost_player = player_mob
			if(ghost_player.started_as_observer) // Exclude people who started as observers
				continue
		active_players++
	return active_players

///Uses stripped down and bastardized code from respawn character
/proc/make_body(mob/dead/observer/ghost_player)
	if(!ghost_player || !ghost_player.key)
		return

	//First we spawn a dude.
	var/mob/living/carbon/human/new_character = new//The mob being spawned.
	SSjob.send_to_late_join(new_character)

	ghost_player.client.prefs.safe_transfer_prefs_to(new_character)
	new_character.dna.update_dna_identity()
	new_character.key = ghost_player.key

	return new_character

///sends a whatever to all playing players; use instead of to_chat(world, where needed)
/proc/send_to_playing_players(thing)
	for(var/player_mob in GLOB.player_list)
		if(player_mob && !isnewplayer(player_mob))
			to_chat(player_mob, thing)

///Flash the window of a player
/proc/window_flash(client/flashed_client, ignorepref = FALSE)
	if(ismob(flashed_client))
		var/mob/player_mob = flashed_client
		if(player_mob.client)
			flashed_client = player_mob.client
	if(!flashed_client || (!flashed_client.prefs.read_preference(/datum/preference/toggle/window_flashing) && !ignorepref))
		return
	winset(flashed_client, "mainwindow", "flash=5")

///Recursively checks if an item is inside a given type/atom, even through layers of storage. Returns the atom if it finds it.
/proc/recursive_loc_check(atom/movable/target, type)
	var/atom/atom_to_find = null

	if(ispath(type))
		atom_to_find = target
		if(istype(atom_to_find, type))
			return atom_to_find

		while(!istype(atom_to_find, type))
			if(!atom_to_find.loc)
				return
			atom_to_find = atom_to_find.loc
	else if(isatom(type))
		atom_to_find = target
		if(atom_to_find == type)
			return atom_to_find

		while(atom_to_find != type)
			if(!atom_to_find.loc)
				return
			atom_to_find = atom_to_find.loc

	return atom_to_find

///Send a message in common radio when a player arrives
/proc/announce_arrival(mob/living/carbon/human/character, rank)
	if(!SSticker.IsRoundInProgress() || QDELETED(character))
		return
	var/area/player_area = get_area(character)
	deadchat_broadcast(span_game(" has arrived at the station at [span_name(player_area.name)]."), span_game("[span_name(character.real_name)] ([rank])"), follow_target = character, message_type=DEADCHAT_ARRIVALRATTLE)
	if(character.mind && (character.mind.assigned_role.job_flags & JOB_ANNOUNCE_ARRIVAL))
		aas_config_announce(/datum/aas_config_entry/arrival, list("PERSON" = character.real_name,"RANK" = rank))

///Check if the turf pressure allows specialized equipment to work
/proc/lavaland_equipment_pressure_check(turf/turf_to_check)
	. = FALSE
	if(!istype(turf_to_check))
		return
	var/datum/gas_mixture/environment = turf_to_check.return_air()
	if(!istype(environment))
		return
	var/pressure = environment.return_pressure()
	if(pressure <= LAVALAND_EQUIPMENT_EFFECT_PRESSURE)
		. = TRUE

///Find an obstruction free turf that's within the range of the center. Can also condition on if it is of a certain area type.
/proc/find_obstruction_free_location(range, atom/center, area/specific_area)
	var/list/possible_loc = list()

	for(var/turf/found_turf as anything in RANGE_TURFS(range, center))
		// We check if both the turf is a floor, and that it's actually in the area.
		// We also want a location that's clear of any obstructions.
		if (specific_area && !istype(get_area(found_turf), specific_area))
			continue

		if (!isgroundlessturf(found_turf) && !found_turf.is_blocked_turf())
			possible_loc.Add(found_turf)

	// Need at least one free location.
	if (possible_loc.len < 1)
		return FALSE

	return pick(possible_loc)

///Checks to see if `atom/source` is behind `atom/target`
/proc/check_behind(atom/source, atom/target)
	// Let's see if source is behind target
	// "Behind" is defined as 3 tiles directly to the back of the target
	// x . .
	// x > .
	// x . .

	// No tactical spinning allowed
	if(HAS_TRAIT(target, TRAIT_SPINNING))
		return TRUE

	// We'll take "same tile" as "behind" for ease
	if(target.loc == source.loc)
		return TRUE

	// We'll also assume lying down is behind, as mob directions when lying are unclear
	if(isliving(target))
		var/mob/living/living_target = target
		if(living_target.body_position == LYING_DOWN)
			return TRUE

	// Exceptions aside, let's actually check if they're, yknow, behind
	var/dir_target_to_source = get_dir(target, source)
	if(target.dir & REVERSE_DIR(dir_target_to_source))
		return TRUE

	return FALSE

///Disable power in the station APCs
/proc/power_fail(duration_min, duration_max)
	for(var/obj/machinery/power/apc/current_apc as anything in SSmachines.get_machines_by_type_and_subtypes(/obj/machinery/power/apc))
		if(!current_apc.cell || !SSmapping.level_trait(current_apc.z, ZTRAIT_STATION))
			continue
		var/area/apc_area = current_apc.area
		if(is_type_in_typecache(apc_area, GLOB.typecache_powerfailure_safe_areas))
			continue

		var/duration = rand(duration_min,duration_max)
		current_apc.energy_fail(duration)

/**
 * Sends a round tip to a target. If selected_tip is null, a random tip will be sent instead (5% chance of it being silly).
 * Tips that starts with the @ character won't be html encoded. That's necessary for any tip containing markup tags,
 * just make sure they don't also have html characters like <, > and ' which will be garbled.
 */
/proc/send_tip_of_the_round(target, selected_tip, source = "Tip of the round")
	var/message
	if(selected_tip)
		message = selected_tip
	else
		var/list/randomtips = world.file2list("strings/tips.txt")
		var/list/memetips = world.file2list("strings/sillytips.txt")
		if(randomtips.len && prob(95))
			message = pick(randomtips)
		else if(memetips.len)
			message = pick(memetips)

	if(!message)
		return
	if(message[1] != "@")
		message = html_encode(message)
	else
		message = copytext(message, 2)
	to_chat(target, custom_boxed_message("purple_box", span_purple("<b>[source]: </b>[message]")), type = MESSAGE_TYPE_INFO)
