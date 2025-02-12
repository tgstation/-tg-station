#define BP_MAX_ROOM_SIZE 300
#define EXTRA_ROOM_CHECK_SKIP 1
#define EXTRA_ROOM_CHECK_FAIL 2

GLOBAL_LIST_INIT(typecache_powerfailure_safe_areas, typecacheof(list(
	/area/station/engineering/main,
	/area/station/engineering/supermatter,
	/area/station/engineering/atmospherics_engine,
	/area/station/ai_monitored/turret_protected/ai,
	/area/ruin/comms_agent //fixes icemoon comms station being affected

)))

// Gets an atmos isolated contained space
// Returns an associative list of turf|dirs pairs
// The dirs are connected turfs in the same space
// break_if_found is a typecache of turf/area types to return false if found
// extra_check is an optional callback to invoke on each turf checked, and can specify whether to skip processing the turf or return false
// Please keep this proc type agnostic. If you need to restrict it do it elsewhere or add an arg.
/proc/detect_room(turf/origin, list/break_if_found = list(), max_size=INFINITY, datum/callback/extra_check)
	if(origin.blocks_air)
		return list(origin)

	. = list()
	var/list/checked_turfs = list()
	var/list/found_turfs = list(origin)
	while(length(found_turfs))
		var/turf/sourceT = found_turfs[1]
		found_turfs.Cut(1, 2)
		var/dir_flags = checked_turfs[sourceT]
		for(var/dir in GLOB.alldirs)
			if(length(.) > max_size)
				return
			if(dir_flags & dir) // This means we've checked this dir before, probably from the other turf
				continue
			var/turf/checkT = get_step(sourceT, dir)
			if(!checkT)
				continue
			checked_turfs[sourceT] |= dir
			checked_turfs[checkT] |= REVERSE_DIR(dir)
			switch(extra_check?.Invoke(checkT))
				if(EXTRA_ROOM_CHECK_SKIP)
					continue
				if(EXTRA_ROOM_CHECK_FAIL)
					return FALSE
			.[sourceT] |= dir
			.[checkT] |= REVERSE_DIR(dir)
			if(break_if_found[checkT.type] || break_if_found[checkT.loc.type])
				return FALSE
			var/static/list/cardinal_cache = list("[NORTH]"=TRUE, "[EAST]"=TRUE, "[SOUTH]"=TRUE, "[WEST]"=TRUE)
			if(!cardinal_cache["[dir]"] || !TURFS_CAN_SHARE(sourceT, checkT))
				continue
			found_turfs += checkT // Since checkT is connected, add it to the list to be processed

/**
 * Create an atmos zone (Think ZAS), similiar to [proc/detect_room] but it ignores walls and turfs which are non-[atmos_can_pass]
 *
 * Arguments
 * source - the turf which to find all connected atmos turfs
 * range - the max range to check
 *
 * Returns a list of turfs, which is an area of isolated atmos
 */
/proc/create_atmos_zone(turf/source, range = INFINITY)
	var/counter = 1 // a counter which increment each loop
	var/loops = 0
	if(source.blocks_air)
		return
	var/list/connected_turfs = list(source)
	. = connected_turfs
	while(length(connected_turfs))
		var/list/turf/adjacent_turfs = list(
			get_step(connected_turfs[counter], NORTH),
			get_step(connected_turfs[counter], SOUTH),
			get_step(connected_turfs[counter], EAST),
			get_step(connected_turfs[counter], WEST)
		)// get a tile in each cardinal direction at once and add that to the list
		for(var/turf/valid_turf in adjacent_turfs)//loop through the list and check for atmos adjacency
			var/turf/reference_turf = connected_turfs[counter]
			if(valid_turf in connected_turfs)//if the turf is already added, skip
				loops += 1
				continue
			if(length(connected_turfs) >= range)
				return
			if(TURFS_CAN_SHARE(reference_turf, valid_turf))
				loops = 0
				connected_turfs |= valid_turf//add that to the original list
		if(loops >= 7)//if the loop has gone 7 consecutive times with no new turfs added, return the result. Number is arbitrary, subject to change
			return
		counter += 1 //increment by one so the next loop will start at the next position in the list

/proc/set_turfs_to_area(list/turf/turfs, area/new_area, list/area/affected_areas = list())
	for(var/turf/the_turf as anything in turfs)
		var/area/old_area = the_turf.loc

		//keep rack of all areas affected by turf changes
		affected_areas[old_area.name] = old_area

		//move the turf to its new area and unregister it from the old one
		the_turf.change_area(old_area, new_area)

		//inform atoms on the turf that their area has changed
		for(var/atom/stuff as anything in the_turf)
			//unregister the stuff from its old area
			SEND_SIGNAL(stuff, COMSIG_EXIT_AREA, old_area)

			//register the stuff to its new area. special exception for apc as its not registered to this signal
			if(istype(stuff, /obj/machinery/power/apc))
				var/obj/machinery/power/apc/area_apc = stuff
				area_apc.assign_to_area()
			else
				SEND_SIGNAL(stuff, COMSIG_ENTER_AREA, new_area)

/proc/create_area(mob/creator, new_area_type = /area)
	// Passed into the above proc as list/break_if_found
	var/static/list/area_or_turf_fail_types = typecacheof(list(
		/turf/open/space,
		/area/shuttle,
		))
	// Ignore these areas and dont let people expand them. They can expand into them though
	var/static/list/blacklisted_areas = typecacheof(list(
		/area/space,
		/area/station/asteroid,
		))

	var/error = ""
	var/list/turfs = detect_room(get_turf(creator), area_or_turf_fail_types, BP_MAX_ROOM_SIZE*2)
	var/turf_count = length(turfs)
	if(!turf_count)
		error = "The new area must be completely airtight and not a part of a shuttle."
	else if(turf_count > BP_MAX_ROOM_SIZE)
		error = "The room you're in is too big. It is [turf_count >= BP_MAX_ROOM_SIZE *2 ? "more than 100" : ((turf_count / BP_MAX_ROOM_SIZE)-1)*100]% larger than allowed."
	if(error)
		to_chat(creator, span_warning(error))
		return

	var/list/apc_map = list()
	var/list/areas = list("New Area" = new_area_type)
	for(var/i in 1 to turf_count)
		var/turf/the_turf = turfs[i]
		var/area/place = get_area(the_turf)
		if(blacklisted_areas[place.type])
			continue
		if(!place.requires_power || (place.area_flags & NOTELEPORT) || (place.area_flags & HIDDEN_AREA))
			continue // No expanding powerless rooms etc
		if(!TURF_SHARES(the_turf)) // No expanding areas of walls/something blocking this turf because that defeats the whole point of them used to separate areas
			continue
		if(!isnull(place.apc))
			apc_map[place.name] = place.apc
		if(length(apc_map) > 1) // When merging 2 or more areas make sure we arent merging their apc into 1 area
			to_chat(creator, span_warning("Multiple APC's detected in the vicinity. only 1 is allowed."))
			return
		areas[place.name] = place

	var/area_choice = tgui_input_list(creator, "Choose an area to expand or make a new area", "Area Expansion", areas)
	if(isnull(area_choice))
		to_chat(creator, span_warning("No choice selected. The area remains undefined."))
		return
	area_choice = areas[area_choice]

	var/area/newA
	var/area/oldA = get_area(get_turf(creator))
	if(!isarea(area_choice))
		var/str = tgui_input_text(creator, "New area name", "Blueprint Editing", max_length = MAX_NAME_LEN)
		if(!str)
			return
		newA = new area_choice
		newA.AddComponent(/datum/component/custom_area)
		newA.setup(str)
		newA.default_gravity = oldA.default_gravity
		GLOB.custom_areas[newA] = TRUE
		require_area_resort() //new area registered. resort the names
	else
		newA = area_choice

	//we haven't done anything. let's get outta here
	if(newA == oldA)
		to_chat(creator, span_warning("Selected choice is same as the area your standing in. No area changes were requested."))
		return

	/**
	 * A list of all machinery tied to an area along with the area itself. key=area name,value=list(area,list of machinery)
	 * we use this to keep track of what areas are affected by the blueprints & what machinery of these areas needs to be reconfigured accordingly
	 */
	var/list/area/affected_areas = list()
	set_turfs_to_area(turfs, newA, affected_areas)

	newA.reg_in_areas_in_z()

	if(!isarea(area_choice) && newA.static_lighting)
		newA.create_area_lighting_objects()

	//convert map to list
	var/list/area/area_list = list()
	for(var/area_name in affected_areas)
		area_list += affected_areas[area_name]
	SEND_GLOBAL_SIGNAL(COMSIG_AREA_CREATED, newA, area_list, creator)
	to_chat(creator, span_notice("You have created a new area, named [newA.name]. It is now weather proof, and constructing an APC will allow it to be powered."))
	creator.log_message("created a new area: [AREACOORD(creator)] (previously \"[oldA.name]\")", LOG_GAME)

	//purge old areas that had all their turfs merged into the new one i.e. old empty areas. also recompute fire doors
	for(var/i in 1 to length(area_list))
		var/area/merged_area = area_list[i]

		//recompute fire doors affecting areas
		for(var/obj/machinery/door/firedoor/FD as anything in merged_area.firedoors)
			FD.CalculateAffectingAreas()

		//no more turfs in this area. Time to clean up
		if(!merged_area.has_contained_turfs())
			qdel(merged_area)

	return TRUE

#undef BP_MAX_ROOM_SIZE

/proc/require_area_resort()
	GLOB.sortedAreas = null

/// Returns a sorted version of GLOB.areas, by name
/proc/get_sorted_areas()
	if(!GLOB.sortedAreas)
		GLOB.sortedAreas = sortTim(GLOB.areas.Copy(), /proc/cmp_name_asc)
	return GLOB.sortedAreas

//Takes: Area type as a text string from a variable.
//Returns: Instance for the area in the world.
/proc/get_area_instance_from_text(areatext)
	if(istext(areatext))
		areatext = text2path(areatext)
	return GLOB.areas_by_type[areatext]

//Takes: Area type as text string or as typepath OR an instance of the area.
//Returns: A list of all areas of that type in the world.
/proc/get_areas(areatype, subtypes=TRUE)
	if(istext(areatype))
		areatype = text2path(areatype)
	else if(isarea(areatype))
		var/area/areatemp = areatype
		areatype = areatemp.type
	else if(!ispath(areatype))
		return null

	var/list/areas = list()
	if(subtypes)
		var/list/cache = typecacheof(areatype)
		for(var/area/area_to_check as anything in GLOB.areas)
			if(cache[area_to_check.type])
				areas += area_to_check
	else
		for(var/area/area_to_check as anything in GLOB.areas)
			if(area_to_check.type == areatype)
				areas += area_to_check
	return areas

/// Iterates over all turfs in the target area and returns the first non-dense one
/proc/get_first_open_turf_in_area(area/target)
	if(!target)
		return
	for(var/turf/turf in target)
		if(!turf.density)
			return turf

//Takes: Area type as text string or as typepath OR an instance of the area.
//Returns: A list of all turfs in areas of that type of that type in the world.
/proc/get_area_turfs(areatype, target_z = 0, subtypes=FALSE)
	if(istext(areatype))
		areatype = text2path(areatype)
	else if(isarea(areatype))
		var/area/areatemp = areatype
		areatype = areatemp.type
	else if(!ispath(areatype))
		return null
	// Pull out the areas
	var/list/areas_to_pull = list()
	if(subtypes)
		var/list/cache = typecacheof(areatype)
		for(var/area/area_to_check as anything in GLOB.areas)
			if(!cache[area_to_check.type])
				continue
			areas_to_pull += area_to_check
	else
		for(var/area/area_to_check as anything in GLOB.areas)
			if(area_to_check.type != areatype)
				continue
			areas_to_pull += area_to_check

	// Now their turfs
	var/list/turfs = list()
	for(var/area/pull_from as anything in areas_to_pull)
		if (target_z == 0)
			for (var/list/zlevel_turfs as anything in pull_from.get_zlevel_turf_lists())
				turfs += zlevel_turfs
		else
			turfs += pull_from.get_turfs_by_zlevel(target_z)
	return turfs


///Takes: list of area types
///Returns: all mobs that are in an area type
/proc/mobs_in_area_type(list/area/checked_areas)
	var/list/mobs_in_area = list()
	for(var/mob/living/mob as anything in GLOB.mob_living_list)
		if(QDELETED(mob))
			continue
		for(var/area in checked_areas)
			if(istype(get_area(mob), area))
				mobs_in_area += mob
				break
	return mobs_in_area

/**
 * rename_area
 * Renames an area to the given new name, updating all machines' names and firedoors
 * to properly ensure alarms and machines are named correctly at all times.
 * Args:
 * - area_to_rename: The area that's being renamed.
 * - new_name: The name we're changing said area to.
 */
/proc/rename_area(area/area_to_rename, new_name)
	var/prevname = "[area_to_rename.name]"
	set_area_machinery_title(area_to_rename, new_name, prevname)
	area_to_rename.name = new_name
	require_area_resort() //area renamed so resort the names

	if(LAZYLEN(area_to_rename.firedoors))
		for(var/obj/machinery/door/firedoor/area_firedoors as anything in area_to_rename.firedoors)
			area_firedoors.CalculateAffectingAreas()
	area_to_rename.update_areasize()
	return TRUE

/**
 * Renames all machines in a defined area from the old title to the new title.
 * Used when renaming an area to ensure that all machiens are labeled the new area's machine.
 * Args:
 * - area_renaming: The area being renamed, which we'll check turfs from to rename machines in.
 * - title: The new name of the area that we're swapping into.
 * - oldtitle: The old name of the area that we're replacing text from.
 */
/proc/set_area_machinery_title(area/area_renaming, title, oldtitle)
	if(!oldtitle) // or replacetext goes to infinite loop
		return

	//stuff tied to the area to rename
	var/static/list/to_rename = typecacheof(list(
		/obj/machinery/airalarm,
		/obj/machinery/atmospherics/components/unary/vent_scrubber,
		/obj/machinery/atmospherics/components/unary/vent_pump,
		/obj/machinery/door,
		/obj/machinery/firealarm,
		/obj/machinery/light_switch,
		/obj/machinery/power/apc,
		/obj/machinery/camera,
	))
	for(var/list/zlevel_turfs as anything in area_renaming.get_zlevel_turf_lists())
		for(var/turf/area_turf as anything in zlevel_turfs)
			for(var/obj/machine as anything in typecache_filter_list(area_turf.contents, to_rename))
				machine.name = replacetext(machine.name, oldtitle, title)
