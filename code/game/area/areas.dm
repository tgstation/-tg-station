/**
 * # area
 *
 * A grouping of tiles into a logical space, mostly used by map editors
 */
/area
	name = "Space"
	icon = 'icons/area/areas_misc.dmi'
	icon_state = "unknown"
	layer = AREA_LAYER
	//Keeping this on the default plane, GAME_PLANE, will make area overlays fail to render on FLOOR_PLANE.
	plane = AREA_PLANE
	mouse_opacity = MOUSE_OPACITY_TRANSPARENT
	invisibility = INVISIBILITY_LIGHTING

	/// List of all turfs currently inside this area as nested lists indexed by zlevel.
	/// Acts as a filtered version of area.contents For faster lookup
	/// (area.contents is actually a filtered loop over world)
	/// Semi fragile, but it prevents stupid so I think it's worth it
	var/list/list/turf/turfs_by_zlevel = list()
	/// turfs_by_z_level can hold MASSIVE lists, so rather then adding/removing from it each time we have a problem turf
	/// We should instead store a list of turfs to REMOVE from it, then hook into a getter for it
	/// There is a risk of this and contained_turfs leaking, so a subsystem will run it down to 0 incrementally if it gets too large
	/// This uses the same nested list format as turfs_by_zlevel
	var/list/list/turf/turfs_to_uncontain_by_zlevel = list()

	var/area_flags = VALID_TERRITORY | BLOBS_ALLOWED | UNIQUE_AREA | CULT_PERMITTED

	///Do we have an active fire alarm?
	var/fire = FALSE
	///A var for whether the area allows for detecting fires/etc. Disabled or enabled at a fire alarm, checked by fire locks.
	var/fire_detect = TRUE
	///A list of all fire locks in this area. Used by fire alarm panels when resetting fire locks or activating all in an area
	var/list/firedoors
	///A list of firelocks currently active. Used by fire alarms when setting their icons.
	var/list/active_firelocks
	///A list of all fire alarms in this area. Used by firelocks and burglar alarms to change icon state.
	var/list/firealarms = list()
	///Alarm type to count of sources. Not usable for ^ because we handle fires differently
	var/list/active_alarms = list()
	/// The current alarm fault status
	var/fault_status = AREA_FAULT_NONE
	/// The source machinery for the area's fault status
	var/fault_location
	///List of all lights in our area
	var/list/lights = list()
	///We use this just for fire alarms, because they're area based right now so one alarm going poof shouldn't prevent you from clearing your alarms listing. Fire alarms and fire locks will set and clear alarms.
	var/datum/alarm_handler/alarm_manager

	var/lightswitch = TRUE

	/// All beauty in this area combined, only includes indoor area.
	var/totalbeauty = 0
	/// Beauty average per open turf in the area
	var/beauty = 0
	/// If a room is too big it doesn't have beauty.
	var/beauty_threshold = 150

	/// For space, the asteroid, lavaland, etc. Used with blueprints or with weather to determine if we are adding a new area (vs editing a station room)
	var/outdoors = FALSE

	/// Size of the area in open turfs, only calculated for indoors areas.
	var/areasize = 0

	/// Bonus mood for being in this area
	var/mood_bonus = 0
	/// Mood message for being here, only shows up if mood_bonus != 0
	var/mood_message = "This area is pretty nice!"
	/// Does the mood bonus require a trait?
	var/mood_trait

	///Will objects this area be needing power?
	var/requires_power = TRUE
	/// This gets overridden to 1 for space in area/.
	var/always_unpowered = FALSE

	var/obj/machinery/power/apc/apc = null

	var/power_equip = TRUE
	var/power_light = TRUE
	var/power_environ = TRUE
	var/power_apc_charge = TRUE
	/// The default gravity for the area
	var/default_gravity = ZERO_GRAVITY

	var/parallax_movedir = 0

	var/ambience_index = AMBIENCE_GENERIC
	///A list of sounds to pick from every so often to play to clients.
	var/list/ambientsounds
	///Does this area immediately play an ambience track upon enter?
	var/forced_ambience = FALSE
	///The background droning loop that plays 24/7
	var/ambient_buzz = 'sound/ambience/general/shipambience.ogg'
	///The volume of the ambient buzz
	var/ambient_buzz_vol = 35
	///Used to decide what the minimum time between ambience is
	var/min_ambience_cooldown = 4 SECONDS
	///Used to decide what the maximum time between ambience is
	var/max_ambience_cooldown = 10 SECONDS

	flags_1 = CAN_BE_DIRTY_1

	var/list/cameras

	///Typepath to limit the areas (subtypes included) that atoms in this area can smooth with. Used for shuttles.
	var/area/area_limited_icon_smoothing

	/// The energy usage of the area in the last machines SS tick.
	var/list/energy_usage

	/// Wire assignment for airlocks in this area
	var/airlock_wires = /datum/wires/airlock

	///This datum, if set, allows terrain generation behavior to be ran on Initialize()
	var/datum/map_generator/map_generator

	///Used to decide what kind of reverb the area makes sound have
	var/sound_environment = SOUND_ENVIRONMENT_NONE

	/// List of all air vents in the area
	var/list/obj/machinery/atmospherics/components/unary/vent_pump/air_vents = list()

	/// List of all air scrubbers in the area
	var/list/obj/machinery/atmospherics/components/unary/vent_scrubber/air_scrubbers = list()

/**
 * A list of teleport locations
 *
 * Adding a wizard area teleport list because motherfucking lag -- Urist
 * I am far too lazy to make it a proper list of areas so I'll just make it run the usual teleport routine at the start of the game
 */
GLOBAL_LIST_EMPTY(teleportlocs)

/**
 * Generate a list of turfs you can teleport to from the areas list
 *
 * Includes areas if they're not a shuttle or not not teleport or have no contents
 *
 * The chosen turf is the first item in the areas contents that is a station level
 *
 * The returned list of turfs is sorted by name
 */
/proc/process_teleport_locs()
	for(var/area/AR as anything in get_sorted_areas())
		if(istype(AR, /area/shuttle) || AR.area_flags & NOTELEPORT)
			continue
		if(GLOB.teleportlocs[AR.name])
			continue
		if (!AR.has_contained_turfs())
			continue
		if (is_station_level(AR.z))
			GLOB.teleportlocs[AR.name] = AR

/**
 * Called when an area loads
 *
 *  Adds the item to the GLOB.areas_by_type list based on area type
 */
/area/New()
	// This interacts with the map loader, so it needs to be set immediately
	// rather than waiting for atoms to initialize.
	if (area_flags & UNIQUE_AREA)
		GLOB.areas_by_type[type] = src
	GLOB.areas += src
	energy_usage = new /list(AREA_USAGE_LEN) // Some atoms would like to use power in Initialize()
	alarm_manager = new(src) // just in case
	return ..()

/*
 * Initialize this area
 *
 * initializes the dynamic area lighting and also registers the area with the z level via
 * reg_in_areas_in_z
 *
 * returns INITIALIZE_HINT_LATELOAD
 */
/area/Initialize(mapload)
	icon_state = ""
	if(!ambientsounds)
		ambientsounds = GLOB.ambience_assoc[ambience_index]

	if(requires_power)
		luminosity = 0
	else
		power_light = TRUE
		power_equip = TRUE
		power_environ = TRUE

		if(static_lighting)
			luminosity = 0

	. = ..()

	if(!static_lighting)
		blend_mode = BLEND_MULTIPLY

	reg_in_areas_in_z()

	update_base_lighting()

	return INITIALIZE_HINT_LATELOAD

/**
 * Sets machine power levels in the area
 */
/area/LateInitialize()
	power_change() // all machines set to current power level, also updates icon
	update_beauty()

/// Generate turfs, including cool cave wall gen
/area/proc/RunTerrainGeneration()
	if(map_generator)
		map_generator = new map_generator()
		var/list/turfs = list()
		for(var/turf/T in contents)
			turfs += T
		map_generator.generate_terrain(turfs, src)

/// Populate the previously generated terrain with mobs and objects
/area/proc/RunTerrainPopulation()
	if(map_generator)
		var/list/turfs = list()
		for(var/turf/T in contents)
			turfs += T
		map_generator.populate_terrain(turfs, src)

/area/proc/test_gen()
	if(map_generator)
		var/list/turfs = list()
		for(var/turf/T in contents)
			turfs += T
		map_generator.generate_terrain(turfs, src)

/// Returns the highest zlevel that this area contains turfs for
/area/proc/get_highest_zlevel()
	for (var/area_zlevel in length(turfs_by_zlevel) to 1 step -1)
		if (length(turfs_to_uncontain_by_zlevel) >= area_zlevel)
			if (length(turfs_by_zlevel[area_zlevel]) - length(turfs_to_uncontain_by_zlevel[area_zlevel]) > 0)
				return area_zlevel
		else
			if (length(turfs_by_zlevel[area_zlevel]))
				return area_zlevel
	return 0

/// Returns a nested list of lists with all turfs split by zlevel.
/// only zlevels with turfs are returned. The order of the list is not guaranteed.
/area/proc/get_zlevel_turf_lists()
	if(length(turfs_to_uncontain_by_zlevel))
		cannonize_contained_turfs()

	var/list/zlevel_turf_lists = list()

	for (var/list/zlevel_turfs as anything in turfs_by_zlevel)
		if (length(zlevel_turfs))
			zlevel_turf_lists += list(zlevel_turfs)

	return zlevel_turf_lists

/// Returns a list with all turfs in this zlevel.
/area/proc/get_turfs_by_zlevel(zlevel)
	if (length(turfs_to_uncontain_by_zlevel) >= zlevel && length(turfs_to_uncontain_by_zlevel[zlevel]))
		cannonize_contained_turfs_by_zlevel(zlevel)

	if (length(turfs_by_zlevel) < zlevel)
		return list()

	return turfs_by_zlevel[zlevel]


/// Merges a list containing all of the turfs zlevel lists from get_zlevel_turf_lists inside one list. Use get_zlevel_turf_lists() or get_turfs_by_zlevel() unless you need all the turfs in one list to avoid generating large lists
/area/proc/get_turfs_from_all_zlevels()
	. = list()
	for (var/list/zlevel_turfs as anything in get_zlevel_turf_lists())
		. += zlevel_turfs

/// Ensures that the contained_turfs list properly represents the turfs actually inside us
/area/proc/cannonize_contained_turfs_by_zlevel(zlevel_to_clean, _autoclean = TRUE)
	// This is massively suboptimal for LARGE removal lists
	// Try and keep the mass removal as low as you can. We'll do this by ensuring
	// We only actually add to contained turfs after large changes (Also the management subsystem)
	// Do your damndest to keep turfs out of /area/space as a stepping stone
	// That sucker gets HUGE and will make this take actual seconds
	if (zlevel_to_clean <= length(turfs_by_zlevel) && zlevel_to_clean <= length(turfs_to_uncontain_by_zlevel))
		turfs_by_zlevel[zlevel_to_clean] -= turfs_to_uncontain_by_zlevel[zlevel_to_clean]

	if (!_autoclean) // Removes empty lists from the end of this list
		turfs_to_uncontain_by_zlevel[zlevel_to_clean] = list()
		return

	var/new_length = length(turfs_to_uncontain_by_zlevel)
	// Walk backwards thru the list
	for (var/i in length(turfs_to_uncontain_by_zlevel) to 0 step -1)
		if (i && length(turfs_to_uncontain_by_zlevel[i]))
			break // Stop the moment we find a useful list
		new_length = i

	if (new_length < length(turfs_to_uncontain_by_zlevel))
		turfs_to_uncontain_by_zlevel.len = new_length

	if (new_length >= zlevel_to_clean)
		turfs_to_uncontain_by_zlevel[zlevel_to_clean] = list()


/// Ensures that the contained_turfs list properly represents the turfs actually inside us
/area/proc/cannonize_contained_turfs()
	for (var/area_zlevel in 1 to length(turfs_to_uncontain_by_zlevel))
		cannonize_contained_turfs_by_zlevel(area_zlevel, _autoclean = FALSE)

	turfs_to_uncontain_by_zlevel = list()


/// Returns TRUE if we have contained turfs, FALSE otherwise
/area/proc/has_contained_turfs()
	for (var/area_zlevel in 1 to length(turfs_by_zlevel))
		if (length(turfs_to_uncontain_by_zlevel) >= area_zlevel)
			if (length(turfs_by_zlevel[area_zlevel]) - length(turfs_to_uncontain_by_zlevel[area_zlevel]) > 0)
				return TRUE
		else
			if (length(turfs_by_zlevel[area_zlevel]))
				return TRUE
	return FALSE

/**
 * Register this area as belonging to a z level
 *
 * Ensures the item is added to the SSmapping.areas_in_z list for this z
 */
/area/proc/reg_in_areas_in_z()
	if(!has_contained_turfs())
		return
	var/list/areas_in_z = SSmapping.areas_in_z
	update_areasize()
	if(!z)
		WARNING("No z found for [src]")
		return
	if(!areas_in_z["[z]"])
		areas_in_z["[z]"] = list()
	areas_in_z["[z]"] += src

/**
 * Destroy an area and clean it up
 *
 * Removes the area from GLOB.areas_by_type and also stops it processing on SSobj
 *
 * This is despite the fact that no code appears to put it on SSobj, but
 * who am I to argue with old coders
 */
/area/Destroy()
	if(GLOB.areas_by_type[type] == src)
		GLOB.areas_by_type[type] = null
	//this is not initialized until get_sorted_areas() is called so we have to do a null check
	if(!isnull(GLOB.sortedAreas))
		GLOB.sortedAreas -= src
	//just for sanity sake cause why not
	if(!isnull(GLOB.areas))
		GLOB.areas -= src
	if(!isnull(GLOB.custom_areas))
		GLOB.custom_areas -= src
	//machinery cleanup
	STOP_PROCESSING(SSobj, src)
	QDEL_NULL(alarm_manager)
	firedoors = null
	//atmos cleanup
	firealarms = null
	air_vents = null
	air_scrubbers = null
	//turf cleanup
	turfs_by_zlevel = null
	turfs_to_uncontain_by_zlevel = null
	//parent cleanup
	return ..()

/**
 * Close and lock a door passed into this proc
 *
 * Does this need to exist on area? probably not
 */
/area/proc/close_and_lock_door(obj/machinery/door/DOOR)
	set waitfor = FALSE
	DOOR.close()
	if(DOOR.density)
		DOOR.lock()

/**
 * Raise a burglar alert for this area
 *
 * Close and locks all doors in the area and alerts silicon mobs of a break in
 *
 * Alarm auto resets after 600 ticks
 */
/area/proc/burglaralert(obj/trigger)
	//Trigger alarm effect
	set_fire_effect(TRUE)
	//Lockdown airlocks
	for(var/obj/machinery/door/door in src)
		close_and_lock_door(door)


/**
 * Set the fire alarm visual affects in an area
 *
 * Allows interested parties (lights and fire alarms) to react
 */
/area/proc/set_fire_effect(new_fire, fault_type, fault_source)
	if(new_fire == fire)
		return
	fire = new_fire
	fault_status = fault_type
	if(fire)
		fault_location = fault_source
	else
		fault_location = null
	SEND_SIGNAL(src, COMSIG_AREA_FIRE_CHANGED, fire)

/**
 * Update the icon state of the area
 *
 * I'm not sure what the heck this does, something to do with weather being able to set icon
 * states on areas?? where the heck would that even display?
 */
/area/update_icon_state()
	var/weather_icon
	for(var/V in SSweather.processing)
		var/datum/weather/W = V
		if(W.stage != END_STAGE && (src in W.impacted_areas))
			W.update_areas()
			weather_icon = TRUE
	if(!weather_icon)
		icon_state = null
	return ..()

/**
 * Update the icon of the area (overridden to always be null for space
 */
/area/space/update_icon_state()
	SHOULD_CALL_PARENT(FALSE)
	icon_state = null


/**
 * Returns int 1 or 0 if the area has power for the given channel
 *
 * evaluates a mixture of variables mappers can set, requires_power, always_unpowered and then
 * per channel power_equip, power_light, power_environ
 */
/area/proc/powered(chan) // return true if the area has power to given channel

	if(!requires_power)
		return TRUE
	if(always_unpowered)
		return FALSE
	switch(chan)
		if(AREA_USAGE_EQUIP)
			return power_equip
		if(AREA_USAGE_LIGHT)
			return power_light
		if(AREA_USAGE_ENVIRON)
			return power_environ

	return FALSE

/**
 * Space is not powered ever, so this returns false
 */
/area/space/powered(chan) //Nope.avi
	return FALSE

/**
 * Called when the area power status changes
 *
 * Updates the area icon, calls power change on all machinees in the area, and sends the `COMSIG_AREA_POWER_CHANGE` signal.
 */
/area/proc/power_change()
	SEND_SIGNAL(src, COMSIG_AREA_POWER_CHANGE)
	update_appearance()


/**
 * Add a static amount of power load to an area. The value is assumed as the watt.
 *
 * Possible channels
 * *AREA_USAGE_STATIC_EQUIP
 * *AREA_USAGE_STATIC_LIGHT
 * *AREA_USAGE_STATIC_ENVIRON
 */
/area/proc/addStaticPower(value, powerchannel)
	value = power_to_energy(value)
	switch(powerchannel)
		if(AREA_USAGE_STATIC_START to AREA_USAGE_STATIC_END)
			energy_usage[powerchannel] += value

/**
 * Remove a static amount of power load to an area. The value is assumed as the watt.
 *
 * Possible channels
 * *AREA_USAGE_STATIC_EQUIP
 * *AREA_USAGE_STATIC_LIGHT
 * *AREA_USAGE_STATIC_ENVIRON
 */
/area/proc/removeStaticPower(value, powerchannel)
	value = power_to_energy(value)
	switch(powerchannel)
		if(AREA_USAGE_STATIC_START to AREA_USAGE_STATIC_END)
			energy_usage[powerchannel] -= value

/**
 * Clear all non-static power usage in area
 *
 * Clears all power used for the dynamic equipment, light and environment channels
 */
/area/proc/clear_usage()
	energy_usage[AREA_USAGE_EQUIP] = 0
	energy_usage[AREA_USAGE_LIGHT] = 0
	energy_usage[AREA_USAGE_ENVIRON] = 0
	energy_usage[AREA_USAGE_APC_CHARGE] = 0


/**
 * Add a power value amount to the stored used_x variables
 */
/area/proc/use_energy(amount, chan)
	switch(chan)
		if(AREA_USAGE_STATIC_START to AREA_USAGE_STATIC_END)
			return
		else
			energy_usage[chan] += amount

/**
 * Call back when an atom enters an area
 *
 * Sends signals COMSIG_AREA_ENTERED and COMSIG_ENTER_AREA (to a list of atoms)
 *
 * If the area has ambience, then it plays some ambience music to the ambience channel
 */
/area/Entered(atom/movable/arrived, area/old_area)
	set waitfor = FALSE
	SEND_SIGNAL(src, COMSIG_AREA_ENTERED, arrived, old_area)

	if(!arrived.important_recursive_contents?[RECURSIVE_CONTENTS_AREA_SENSITIVE])
		return
	for(var/atom/movable/recipient as anything in arrived.important_recursive_contents[RECURSIVE_CONTENTS_AREA_SENSITIVE])
		SEND_SIGNAL(recipient, COMSIG_ENTER_AREA, src)

	if(ismob(arrived))
		var/mob/mob = arrived
		mob.update_ambience_area(src)

/**
 * Called when an atom exits an area
 *
 * Sends signals COMSIG_AREA_EXITED and COMSIG_EXIT_AREA (to a list of atoms)
 */
/area/Exited(atom/movable/gone, direction)
	SEND_SIGNAL(src, COMSIG_AREA_EXITED, gone, direction)
	SEND_SIGNAL(gone, COMSIG_MOVABLE_EXITED_AREA, src, direction)

	if(!gone.important_recursive_contents?[RECURSIVE_CONTENTS_AREA_SENSITIVE])
		return
	for(var/atom/movable/recipient as anything in gone.important_recursive_contents[RECURSIVE_CONTENTS_AREA_SENSITIVE])
		SEND_SIGNAL(recipient, COMSIG_EXIT_AREA, src)

///Divides total beauty in the room by roomsize to allow us to get an average beauty per tile.
/area/proc/update_beauty()
	if(!areasize)
		beauty = 0
		return FALSE
	if(areasize >= beauty_threshold)
		beauty = 0
		return FALSE //Too big
	beauty = totalbeauty / areasize
	SEND_SIGNAL(src, COMSIG_AREA_BEAUTY_UPDATED)

/**
 * Setup an area (with the given name)
 *
 * Sets the area name, sets all status var's to false and adds the area to the sorted area list
 */
/area/proc/setup(a_name)
	name = a_name
	power_equip = FALSE
	power_light = FALSE
	power_environ = FALSE
	always_unpowered = FALSE
	area_flags &= ~(VALID_TERRITORY|BLOBS_ALLOWED|CULT_PERMITTED)
	require_area_resort()
/**
 * Set the area size of the area
 *
 * This is the number of open turfs in the area contents, or FALSE if the outdoors var is set
 *
 */
/area/proc/update_areasize()
	if(outdoors)
		return FALSE
	areasize = 0
	for(var/list/zlevel_turfs as anything in get_zlevel_turf_lists())
		for(var/turf/open/thisvarisunused in zlevel_turfs)
			areasize++

/**
 * Causes a runtime error
 */
/area/AllowDrop()
	CRASH("Bad op: area/AllowDrop() called")

/**
 * Causes a runtime error
 */
/area/drop_location()
	CRASH("Bad op: area/drop_location() called")

/// A hook so areas can modify the incoming args of ChangeTurf
/area/proc/place_on_top_react(list/new_baseturfs, turf/added_layer, flags)
	return flags


/// Called when a living mob that spawned here, joining the round, receives the player client.
/area/proc/on_joining_game(mob/living/boarder)
	return

/**
 * Returns the name of an area, with the original name if the area name has been changed.
 *
 * If an area has not been renamed, returns the area name. If it has been modified (by blueprints or other means)
 * returns the current name, as well as the initial value, in the format of [Current Location Name (Original Name)]
 */

/area/proc/get_original_area_name()
	if(name == initial(name))
		return name
	return "[name] ([initial(name)])"

/**
 * A blank area subtype solely used by the golem area editor for the purpose of
 * allowing golems to create new areas without suffering from the hazard_area debuffs.
 */
/area/golem
	name = "Golem Territory"
