GLOBAL_LIST_EMPTY(station_turfs)

/// Any floor or wall. What makes up the station and the rest of the map.
/turf
	icon = 'icons/turf/floors.dmi'
	datum_flags = DF_STATIC_OBJECT
	vis_flags = VIS_INHERIT_ID // Important for interaction with and visualization of openspace.
	luminosity = 1
	light_height = LIGHTING_HEIGHT_FLOOR

	///what /mob/oranges_ear instance is already assigned to us as there should only ever be one.
	///used for guaranteeing there is only one oranges_ear per turf when assigned, speeds up view() iteration
	var/mob/oranges_ear/assigned_oranges_ear

	/// Turf bitflags, see code/__DEFINES/flags.dm
	var/turf_flags = NONE

	/// If there's a tile over a basic floor that can be ripped out
	var/overfloor_placed = FALSE
	/// How accessible underfloor pieces such as wires, pipes, etc are on this turf. Can be HIDDEN, VISIBLE, or INTERACTABLE.
	var/underfloor_accessibility = UNDERFLOOR_HIDDEN
	/// If there is a lattice underneat this turf. Used for the attempt_lattice_replacement proc to determine if it should place lattice.
	var/lattice_underneath = TRUE

	// baseturfs can be either a list or a single turf type.
	// In class definition like here it should always be a single type.
	// A list will be created in initialization that figures out the baseturf's baseturf etc.
	// In the case of a list it is sorted from bottom layer to top.
	// This shouldn't be modified directly, use the helper procs.
	var/list/baseturfs = /turf/baseturf_bottom

	var/temperature = T20C
	///Used for fire, if a melting temperature was reached, it will be destroyed
	var/to_be_destroyed = 0
	///The max temperature of the fire which it was subjected to, determines the melting point of turf
	var/max_fire_temperature_sustained = 0

	var/blocks_air = FALSE
	// If this turf should initialize atmos adjacent turfs or not
	// Optimization, not for setting outside of initialize
	var/init_air = TRUE

	var/list/image/blueprint_data //for the station blueprints, images of objects eg: pipes

	var/list/explosion_throw_details

	var/requires_activation //add to air processing after initialize?
	var/changing_turf = FALSE

	var/bullet_bounce_sound = 'sound/items/weapons/gun/general/mag_bullet_remove.ogg' //sound played when a shell casing is ejected ontop of the turf.
	var/bullet_sizzle = FALSE //used by ammo_casing/bounce_away() to determine if the shell casing should make a sizzle sound when it's ejected over the turf
							//IE if the turf is supposed to be water, set TRUE.

	var/tiled_dirt = FALSE // use smooth tiled dirt decal

	///Icon-smoothing variable to map a diagonal wall corner with a fixed underlay.
	var/list/fixed_underlay = null

	///Lumcount added by sources other than lighting datum objects, such as the overlay lighting component.
	var/dynamic_lumcount = 0

	///Bool, whether this turf will always be illuminated no matter what area it is in
	///Makes it look blue, be warned
	var/space_lit = FALSE

	var/tmp/lighting_corners_initialised = FALSE

	///Our lighting object.
	var/tmp/datum/lighting_object/lighting_object
	///Lighting Corner datums.
	var/tmp/datum/lighting_corner/lighting_corner_NE
	var/tmp/datum/lighting_corner/lighting_corner_SE
	var/tmp/datum/lighting_corner/lighting_corner_SW
	var/tmp/datum/lighting_corner/lighting_corner_NW


	///Which directions does this turf block the vision of, taking into account both the turf's opacity and the movable opacity_sources.
	var/directional_opacity = NONE
	///Lazylist of movable atoms providing opacity sources.
	var/list/atom/movable/opacity_sources

	///the holodeck can load onto this turf if TRUE
	var/holodeck_compatible = FALSE

	/// If this turf contained an RCD'able object (or IS one, for walls)
	/// but is now destroyed, this will preserve the value.
	/// See __DEFINES/construction.dm for RCD_MEMORY_*.
	var/rcd_memory
	///whether or not this turf forces movables on it to have no gravity (unless they themselves have forced gravity)
	var/force_no_gravity = FALSE

	///This turf's resistance to getting rusted
	var/rust_resistance = RUST_RESISTANCE_ORGANIC

	/// How pathing algorithm will check if this turf is passable by itself (not including content checks). By default it's just density check.
	/// WARNING: Currently to use a density shortcircuiting this does not support dense turfs with special allow through function
	var/pathing_pass_method = TURF_PATHING_PASS_DENSITY

#if defined(UNIT_TESTS) || defined(SPACEMAN_DMM)
	/// For the area_contents list unit test
	/// Allows us to know our area without needing to preassign it
	/// Sorry for the mess
	var/area/in_contents_of
#endif
	/// How much explosive resistance this turf is providing to itself
	/// Defaults to -1, interpreted as initial(explosive_resistance)
	/// This is an optimization to prevent turfs from needing to set these on init
	/// This would either be expensive, or impossible to manage. Let's just avoid it yes?
	/// Never directly access this, use get_explosive_block() instead
	var/inherent_explosive_resistance = -1

	///The typepath we use for lazy fishing on turfs, to save on world init time.
	var/fish_source


/turf/vv_edit_var(var_name, new_value)
	var/static/list/banned_edits = list(NAMEOF_STATIC(src, x), NAMEOF_STATIC(src, y), NAMEOF_STATIC(src, z))
	if(var_name in banned_edits)
		return FALSE
	. = ..()

/**
 * Turf Initialize
 *
 * Doesn't call parent, see [/atom/proc/Initialize]
 * Please note, space tiles do not run this code.
 * This is done because it's called so often that any extra code just slows things down too much
 * If you add something relevant here add it there too
 * [/turf/open/space/Initialize]
 */
/turf/Initialize(mapload)
	SHOULD_CALL_PARENT(FALSE)
	if(flags_1 & INITIALIZED_1)
		stack_trace("Warning: [src]([type]) initialized multiple times!")
	flags_1 |= INITIALIZED_1

	/// We do NOT use the shortcut here, because this is faster
	if(SSmapping.max_plane_offset)
		if(!SSmapping.plane_offset_blacklist["[plane]"])
			plane = plane - (PLANE_RANGE * SSmapping.z_level_to_plane_offset[z])

		var/turf/T = GET_TURF_ABOVE(src)
		if(T)
			T.multiz_turf_new(src, DOWN)
		T = GET_TURF_BELOW(src)
		if(T)
			T.multiz_turf_new(src, UP)

	// by default, vis_contents is inherited from the turf that was here before.
	// Checking length(vis_contents) in a proc this hot has huge wins for performance.
	if (length(vis_contents))
		vis_contents.Cut()

	assemble_baseturfs()

	levelupdate()

	SETUP_SMOOTHING()

	if (smoothing_flags & USES_SMOOTHING)
		QUEUE_SMOOTH(src)

	for(var/atom/movable/content as anything in src)
		Entered(content, null)

	var/area/our_area = loc
	if(!our_area.area_has_base_lighting && space_lit) //Only provide your own lighting if the area doesn't for you
		add_overlay(GLOB.starlight_overlays[GET_TURF_PLANE_OFFSET(src) + 1])

	if(requires_activation)
		CALCULATE_ADJACENT_TURFS(src, KILL_EXCITED)

	if (light_power && light_range)
		update_light()

	if (opacity)
		directional_opacity = ALL_CARDINALS

	// apply materials properly from the default custom_materials value
	if (!length(custom_materials))
		set_custom_materials(custom_materials)

	if(uses_integrity)
		atom_integrity = max_integrity

	return INITIALIZE_HINT_NORMAL

/// Initializes our adjacent turfs. If you want to avoid this, do not override it, instead set init_air to FALSE
/turf/proc/Initalize_Atmos(time)
	CALCULATE_ADJACENT_TURFS(src, NORMAL_TURF)

/turf/Destroy(force)
	. = QDEL_HINT_IWILLGC
	if(!changing_turf)
		stack_trace("Incorrect turf deletion")

	changing_turf = FALSE
	if(GET_LOWEST_STACK_OFFSET(z))
		var/turf/T = GET_TURF_ABOVE(src)
		if(T)
			T.multiz_turf_del(src, DOWN)
		T = GET_TURF_BELOW(src)
		if(T)
			T.multiz_turf_del(src, UP)

	if(force)
		..()
		//this will completely wipe turf state
		var/turf/B = new world.turf(src)
		for(var/A in B.contents)
			qdel(A)
		return

	LAZYCLEARLIST(blueprint_data)
	flags_1 &= ~INITIALIZED_1
	requires_activation = FALSE
	..()

	if(length(vis_contents))
		vis_contents.Cut()

/// WARNING WARNING
/// Turfs DO NOT lose their signals when they get replaced, REMEMBER THIS
/// It's possible because turfs are fucked, and if you have one in a list and it's replaced with another one, the list ref points to the new turf
/// We do it because moving signals over was needlessly expensive, and bloated a very commonly used bit of code
/turf/_clear_signal_refs()
	return

/turf/attack_hand(mob/user, list/modifiers)
	. = ..()
	if(.)
		return
	user.Move_Pulled(src)

/// Call to move a turf from its current area to a new one
/turf/proc/change_area(area/old_area, area/new_area)
	//don't waste our time
	if(old_area == new_area)
		return

	//move the turf
	LISTASSERTLEN(old_area.turfs_to_uncontain_by_zlevel, z, list())
	LISTASSERTLEN(new_area.turfs_by_zlevel, z, list())
	old_area.turfs_to_uncontain_by_zlevel[z] += src
	new_area.turfs_by_zlevel[z] += src
	new_area.contents += src
	SEND_SIGNAL(src, COMSIG_TURF_AREA_CHANGED, old_area)
	SEND_SIGNAL(new_area, COMSIG_AREA_TURF_ADDED, src, old_area)
	SEND_SIGNAL(old_area, COMSIG_AREA_TURF_REMOVED, src, new_area)

	//changes to make after turf has moved
	on_change_area(old_area, new_area)

/// Allows for reactions to an area change without inherently requiring change_area() be called (I hate maploading)
/turf/proc/on_change_area(area/old_area, area/new_area)
	transfer_area_lighting(old_area, new_area)

/turf/proc/multiz_turf_del(turf/T, dir)
	SEND_SIGNAL(src, COMSIG_TURF_MULTIZ_DEL, T, dir)

/turf/proc/multiz_turf_new(turf/T, dir)
	SEND_SIGNAL(src, COMSIG_TURF_MULTIZ_NEW, T, dir)

/**
 * Check whether the specified turf is blocked by something dense inside it with respect to a specific atom.
 *
 * Returns truthy value TURF_BLOCKED_TURF_DENSE if the turf is blocked because the turf itself is dense.
 * Returns truthy value TURF_BLOCKED_CONTENT_DENSE if one of the turf's contents is dense and would block
 * a source atom's movement.
 * Returns falsey value TURF_NOT_BLOCKED if the turf is not blocked.
 *
 * Arguments:
 * * exclude_mobs - If TRUE, ignores dense mobs on the turf.
 * * source_atom - If this is not null, will check whether any contents on the turf can block this atom specifically. Also ignores itself on the turf.
 * * ignore_atoms - Check will ignore any atoms in this list. Useful to prevent an atom from blocking itself on the turf.
 * * type_list - are we checking for types of atoms to ignore and not physical atoms
 */
/turf/proc/is_blocked_turf(exclude_mobs = FALSE, source_atom = null, list/ignore_atoms, type_list = FALSE)
	if(density)
		return TRUE

	for(var/atom/movable/movable_content as anything in contents)
		// We don't want to block ourselves
		if((movable_content == source_atom))
			continue
		// don't consider ignored atoms or their types
		if(length(ignore_atoms))
			if(!type_list && (movable_content in ignore_atoms))
				continue
			else if(type_list && is_type_in_list(movable_content, ignore_atoms))
				continue

		// If the thing is dense AND we're including mobs or the thing isn't a mob AND if there's a source atom and
		// it cannot pass through the thing on the turf,  we consider the turf blocked.
		if(movable_content.density && (!exclude_mobs || !ismob(movable_content)))
			if(source_atom && movable_content.CanPass(source_atom, get_dir(src, source_atom)))
				continue
			return TRUE
	return FALSE

/**
 * Checks whether the specified turf is blocked by something dense inside it, but ignores anything with the climbable trait
 *
 * Works similar to is_blocked_turf(), but ignores climbables and has less options. Primarily added for jaunting checks
 */
/turf/proc/is_blocked_turf_ignore_climbable()
	if(density)
		return TRUE

	for(var/atom/movable/atom_content as anything in contents)
		if(atom_content.density && !(atom_content.flags_1 & ON_BORDER_1) && !HAS_TRAIT(atom_content, TRAIT_CLIMBABLE))
			return TRUE
	return FALSE

//The zpass procs exist to be overridden, not directly called
//use can_z_pass for that
///If we'd allow anything to travel into us
/turf/proc/zPassIn(direction)
	return FALSE

///If we'd allow anything to travel out of us
/turf/proc/zPassOut(direction)
	return FALSE

//direction is direction of travel of air
/turf/proc/zAirIn(direction, turf/source)
	return FALSE

//direction is direction of travel
/turf/proc/zAirOut(direction, turf/source)
	return FALSE

/// Precipitates a movable (plus whatever buckled to it) to lower z levels if possible and then calls zImpact()
/turf/proc/zFall(atom/movable/falling, levels = 1, force = FALSE, falling_from_move = FALSE)
	var/direction = DOWN
	if(falling.has_gravity() <= NEGATIVE_GRAVITY)
		direction = UP
	var/turf/target = get_step_multiz(src, direction)
	if(!target)
		return FALSE
	var/isliving = isliving(falling)
	if(!isliving && !isobj(falling))
		return
	if(isliving)
		var/mob/living/falling_living = falling
		//relay this mess to whatever the mob is buckled to.
		if(falling_living.buckled)
			falling = falling_living.buckled
	if(!falling_from_move && falling.currently_z_moving)
		return
	if(!force && !falling.can_z_move(direction, src, target, ZMOVE_FALL_FLAGS))
		falling.set_currently_z_moving(FALSE, TRUE)
		return FALSE

	// So it doesn't trigger other zFall calls. Cleared on zMove.
	falling.set_currently_z_moving(CURRENTLY_Z_FALLING)

	falling.zMove(null, target, ZMOVE_CHECK_PULLEDBY)
	target.zImpact(falling, levels, src)
	return TRUE

///Called each time the target falls down a z level possibly making their trajectory come to a halt. see __DEFINES/movement.dm.
/turf/proc/zImpact(atom/movable/falling, levels = 1, turf/prev_turf, flags = NONE)
	var/list/falling_movables = falling.get_z_move_affected()
	var/list/falling_mov_names
	for(var/atom/movable/falling_mov as anything in falling_movables)
		falling_mov_names += falling_mov.name
	for(var/i in contents)
		var/atom/thing = i
		flags |= thing.intercept_zImpact(falling_movables, levels)
		if(flags & FALL_STOP_INTERCEPTING)
			break
	if(prev_turf && !(flags & FALL_NO_MESSAGE))
		for(var/mov_name in falling_mov_names)
			prev_turf.visible_message(span_danger("[mov_name] falls through [prev_turf]!"))
	if(!(flags & FALL_INTERCEPTED) && zFall(falling, levels + 1))
		return FALSE
	for(var/atom/movable/falling_mov as anything in falling_movables)
		if(!(flags & FALL_RETAIN_PULL))
			falling_mov.stop_pulling()
		if(!(flags & FALL_INTERCEPTED))
			falling_mov.onZImpact(src, levels)
		if(falling_mov.pulledby && (falling_mov.z != falling_mov.pulledby.z || get_dist(falling_mov, falling_mov.pulledby) > 1))
			falling_mov.pulledby.stop_pulling()
	return TRUE

/turf/proc/handleRCL(obj/item/rcl/C, mob/user)
	if(C.loaded)
		for(var/obj/structure/pipe_cleaner/LC in src)
			if(!LC.d1 || !LC.d2)
				LC.handlecable(C, user)
				return
		C.loaded.place_turf(src, user)
		if(C.wiring_gui_menu)
			C.wiringGuiUpdate(user)
		C.is_empty(user)

/turf/attackby(obj/item/C, mob/user, params)
	if(..())
		return TRUE
	if(can_lay_cable() && istype(C, /obj/item/stack/cable_coil))
		var/obj/item/stack/cable_coil/coil = C
		coil.place_turf(src, user)
		return TRUE
	else if(can_have_cabling() && istype(C, /obj/item/stack/pipe_cleaner_coil))
		var/obj/item/stack/pipe_cleaner_coil/coil = C
		for(var/obj/structure/pipe_cleaner/LC in src)
			if(!LC.d1 || !LC.d2)
				LC.attackby(C, user)
				return
		coil.place_turf(src, user)
		return TRUE

	else if(istype(C, /obj/item/rcl))
		handleRCL(C, user)

	return FALSE

//There's a lot of QDELETED() calls here if someone can figure out how to optimize this but not runtime when something gets deleted by a Bump/CanPass/Cross call, lemme know or go ahead and fix this mess - kevinz000
/turf/Enter(atom/movable/mover)
	// Do not call ..()
	// Byond's default turf/Enter() doesn't have the behaviour we want with Bump()
	// By default byond will call Bump() on the first dense object in contents
	// Here's hoping it doesn't stay like this for years before we finish conversion to step_
	var/atom/first_bump
	var/can_pass_self = CanPass(mover, get_dir(src, mover))

	if(can_pass_self)
		var/atom/mover_loc = mover.loc
		var/mover_is_phasing = mover.movement_type & PHASING
		for(var/atom/movable/thing as anything in contents)
			if(thing == mover || thing == mover_loc) // Multi tile objects and moving out of other objects
				continue
			if(!thing.Cross(mover))
				if(QDELETED(mover)) //deleted from Cross() (CanPass is pure so it can't delete, Cross shouldn't be doing this either though, but it can happen)
					return FALSE
				if(mover_is_phasing)
					mover.Bump(thing)
					if(QDELETED(mover)) //deleted from Bump()
						return FALSE
					continue
				else
					if(!first_bump || ((thing.layer > first_bump.layer || thing.flags_1 & ON_BORDER_1) && !(first_bump.flags_1 & ON_BORDER_1)))
						first_bump = thing
	if(QDELETED(mover)) //Mover deleted from Cross/CanPass/Bump, do not proceed.
		return FALSE
	if(!can_pass_self) //Even if mover is unstoppable they need to bump us.
		first_bump = src
	if(first_bump)
		mover.Bump(first_bump)
		return (mover.movement_type & PHASING)
	return TRUE

// A proc in case it needs to be recreated or badmins want to change the baseturfs
/turf/proc/assemble_baseturfs(turf/fake_baseturf_type)
	var/static/list/created_baseturf_lists = list()
	var/turf/current_target
	if(fake_baseturf_type)
		if(length(fake_baseturf_type)) // We were given a list, just apply it and move on
			baseturfs = baseturfs_string_list(fake_baseturf_type, src)
			return
		current_target = fake_baseturf_type
	else
		if(length(baseturfs))
			return // No replacement baseturf has been given and the current baseturfs value is already a list/assembled
		if(!baseturfs)
			current_target = initial(baseturfs) || type // This should never happen but just in case...
			stack_trace("baseturfs var was null for [type]. Failsafe activated and it has been given a new baseturfs value of [current_target].")
		else
			current_target = baseturfs

	// If we've made the output before we don't need to regenerate it
	if(created_baseturf_lists[current_target])
		var/list/premade_baseturfs = created_baseturf_lists[current_target]
		if(length(premade_baseturfs))
			baseturfs = baseturfs_string_list(premade_baseturfs.Copy(), src)
		else
			baseturfs = baseturfs_string_list(premade_baseturfs, src)
		return baseturfs

	var/turf/next_target = initial(current_target.baseturfs)
	//Most things only have 1 baseturf so this loop won't run in most cases
	if(current_target == next_target)
		baseturfs = current_target
		created_baseturf_lists[current_target] = current_target
		return current_target
	var/list/new_baseturfs = list(current_target)
	for(var/i=0;current_target != next_target;i++)
		if(i > 100)
			// A baseturfs list over 100 members long is silly
			// Because of how this is all structured it will only runtime/message once per type
			stack_trace("A turf <[type]> created a baseturfs list over 100 members long. This is most likely an infinite loop.")
			message_admins("A turf <[type]> created a baseturfs list over 100 members long. This is most likely an infinite loop.")
			break
		new_baseturfs.Insert(1, next_target)
		current_target = next_target
		next_target = initial(current_target.baseturfs)

	baseturfs = baseturfs_string_list(new_baseturfs, src)
	created_baseturf_lists[new_baseturfs[new_baseturfs.len]] = new_baseturfs.Copy()
	return new_baseturfs

/turf/proc/levelupdate()
	for(var/obj/O in src)
		if(O.flags_1 & INITIALIZED_1)
			SEND_SIGNAL(O, COMSIG_OBJ_HIDE, underfloor_accessibility)

// override for space turfs, since they should never hide anything
/turf/open/space/levelupdate()
	return

// Removes all signs of lattice on the pos of the turf -Donkieyo
/turf/proc/RemoveLattice()
	var/obj/structure/lattice/L = locate(/obj/structure/lattice, src)
	if(L && (L.flags_1 & INITIALIZED_1))
		qdel(L)

/turf/proc/Bless()
	new /obj/effect/blessing(src)

//////////////////////////////
//Distance procs
//////////////////////////////

//Distance associates with all directions movement
/turf/proc/Distance(turf/T)
	return get_dist(src,T)

//  This Distance proc assumes that only cardinal movement is
//  possible. It results in more efficient (CPU-wise) pathing
//  for bots and anything else that only moves in cardinal dirs.
/turf/proc/Distance_cardinal(turf/T)
	if(!src || !T)
		return FALSE
	return abs(x - T.x) + abs(y - T.y)

////////////////////////////////////////////////////

/turf/singularity_act()
	if(underfloor_accessibility < UNDERFLOOR_INTERACTABLE)
		for(var/obj/on_top in contents) //this is for deleting things like wires contained in the turf
			if(HAS_TRAIT(on_top, TRAIT_T_RAY_VISIBLE))
				on_top.singularity_act()
	ScrapeAway(flags = CHANGETURF_INHERIT_AIR)
	return(2)

/turf/proc/can_have_cabling()
	return TRUE

/turf/proc/can_lay_cable()
	return can_have_cabling() && underfloor_accessibility >= UNDERFLOOR_INTERACTABLE

/turf/proc/visibilityChanged()
	GLOB.cameranet.updateVisibility(src)

/turf/proc/burn_tile()
	return

/turf/proc/break_tile()
	return

/turf/proc/is_shielded()
	return

/turf/contents_explosion(severity, target)
	for(var/thing in contents)
		var/atom/movable/movable_thing = thing
		if(QDELETED(movable_thing))
			continue
		switch(severity)
			if(EXPLODE_DEVASTATE)
				SSexplosions.high_mov_atom += movable_thing
			if(EXPLODE_HEAVY)
				SSexplosions.med_mov_atom += movable_thing
			if(EXPLODE_LIGHT)
				SSexplosions.low_mov_atom += movable_thing

/turf/narsie_act(force, ignore_mobs, probability = 20)
	. = (prob(probability) || force)
	for(var/I in src)
		var/atom/A = I
		if(ignore_mobs && ismob(A))
			continue
		if(ismob(A) || .)
			A.narsie_act()

/turf/proc/get_smooth_underlay_icon(mutable_appearance/underlay_appearance, turf/asking_turf, adjacency_dir)
	underlay_appearance.icon = icon
	underlay_appearance.icon_state = icon_state
	underlay_appearance.dir = adjacency_dir
	return TRUE

/turf/proc/add_blueprints(atom/movable/AM)
	var/image/I = new
	SET_PLANE(I, GAME_PLANE, src)
	I.layer = OBJ_LAYER
	I.appearance = AM.appearance
	I.appearance_flags = RESET_COLOR|RESET_ALPHA|RESET_TRANSFORM
	I.loc = src
	I.setDir(AM.dir)
	I.alpha = 128
	LAZYADD(blueprint_data, I)

/turf/proc/add_blueprints_preround(atom/movable/AM)
	if(!SSicon_smooth.initialized)
		if(AM.layer == WIRE_LAYER) //wires connect to adjacent positions after its parent init, meaning we need to wait (in this case, until smoothing) to take its image
			SSicon_smooth.blueprint_queue += AM
		else
			add_blueprints(AM)

/turf/proc/is_transition_turf()
	return

/turf/acid_act(acidpwr, acid_volume)
	. = ..()
	if((acidpwr <= 0) || (acid_volume <= 0))
		return FALSE

	AddComponent(/datum/component/acid, acidpwr, acid_volume, GLOB.acid_overlay)

	return . || TRUE

/turf/proc/acid_melt()
	return

/// Check if the heretic is strong enough to rust this turf, and if so, rusts the turf with an added visual effect.
/turf/rust_heretic_act(rust_strength = 1)
	if((turf_flags & NO_RUST) || (rust_strength < rust_resistance))
		return
	rust_turf()

/// Override this to change behaviour when being rusted by a heretic
/turf/proc/rust_turf()
	if(HAS_TRAIT(src, TRAIT_RUSTY))
		return

	AddElement(/datum/element/rust/heretic)
	new /obj/effect/glowing_rune(src)

/turf/handle_fall(mob/faller)
	if(has_gravity(src))
		playsound(src, SFX_BODYFALL, 50, TRUE)
	faller.drop_all_held_items()

/turf/proc/photograph(limit=20)
	var/image/I = new()
	I.add_overlay(src)
	for(var/V in contents)
		var/atom/A = V
		if(A.invisibility)
			continue
		I.add_overlay(A)
		if(limit)
			limit--
		else
			return I
	return I

/turf/AllowDrop()
	return TRUE

/turf/proc/add_vomit_floor(mob/living/vomiter, vomit_type = /obj/effect/decal/cleanable/vomit, vomit_flags, purge_ratio = 0.1)
	var/obj/effect/decal/cleanable/vomit/throw_up = new vomit_type (src, vomiter?.get_static_viruses())

	// if the vomit combined, apply toxicity and reagents to the old vomit
	if (QDELETED(throw_up))
		throw_up = locate() in src
	if(isnull(throw_up))
		return

	if(!iscarbon(vomiter) || (purge_ratio == 0))
		return

	clear_reagents_to_vomit_pool(vomiter, throw_up, purge_ratio)

/proc/clear_reagents_to_vomit_pool(mob/living/carbon/M, obj/effect/decal/cleanable/vomit/V, purge_ratio = 0.1)
	var/obj/item/organ/stomach/belly = M.get_organ_slot(ORGAN_SLOT_STOMACH)
	if(!belly?.reagents.total_volume)
		return
	var/chemicals_lost = belly.reagents.total_volume * purge_ratio
	belly.reagents.trans_to(V, chemicals_lost, transferred_by = M)
	//clear the stomach of anything even not food
	for(var/bile in belly.reagents.reagent_list)
		var/datum/reagent/reagent = bile
		if(!belly.food_reagents[reagent.type])
			belly.reagents.remove_reagent(reagent.type, min(reagent.volume, 10))
		else
			var/bit_vol = reagent.volume - belly.food_reagents[reagent.type]
			if(bit_vol > 0)
				belly.reagents.remove_reagent(reagent.type, min(bit_vol, 10))

//Whatever happens after high temperature fire dies out or thermite reaction works.
//Should return new turf
/turf/proc/Melt()
	return ScrapeAway(flags = CHANGETURF_INHERIT_AIR)

/// Handles exposing a turf to reagents.
/turf/expose_reagents(list/reagents, datum/reagents/source, methods=TOUCH, volume_modifier=1, show_message=TRUE)
	. = ..()
	if(. & COMPONENT_NO_EXPOSE_REAGENTS)
		return

	SEND_SIGNAL(source, COMSIG_REAGENTS_EXPOSE_TURF, src, reagents, methods, volume_modifier, show_message)
	for(var/datum/reagent/reagent as anything in reagents)
		var/reac_volume = reagents[reagent]
		. |= reagent.expose_turf(src, reac_volume)

// When our turf is washed, we may wash everything on top of the turf
// By default we will only wash mopable things (like blood or vomit)
// but you may optionally pass in all_contents = TRUE to wash everything
/turf/wash(clean_types, all_contents = FALSE)
	. = ..()
	for(var/atom/movable/to_clean as anything in src)
		if(all_contents || HAS_TRAIT(to_clean, TRAIT_MOPABLE))
			to_clean.wash(clean_types)

/turf/set_density(new_value)
	var/old_density = density
	. = ..()
	if(old_density == density)
		return

	if(old_density)
		explosive_resistance -= get_explosive_block()
	if(density)
		explosive_resistance += get_explosive_block()

/// Wrapper around inherent_explosive_resistance
/// We assume this proc is cold, so we can move the "what is our block" into it
/turf/proc/get_explosive_block()
	if(inherent_explosive_resistance != -1)
		return inherent_explosive_resistance
	if(explosive_resistance)
		return initial(explosive_resistance)
	return 0

/**
 * Returns adjacent turfs to this turf that are reachable, in all cardinal directions
 *
 * Arguments:
 * * requester: The movable, if one exists, being used for mobility checks to see what tiles it can reach
 * * access: A list that decides if we can gain access to doors that would otherwise block a turf
 * * simulated_only: Do we only worry about turfs with simulated atmos, most notably things that aren't space?
 * * no_id: When true, doors with public access will count as impassible
*/
/turf/proc/reachableAdjacentTurfs(atom/movable/requester, list/access, simulated_only, no_id = FALSE)
	var/static/space_type_cache = typecacheof(/turf/open/space)
	. = list()

	var/datum/can_pass_info/pass_info = new(requester, access, no_id)
	for(var/iter_dir in GLOB.cardinals)
		var/turf/turf_to_check = get_step(src,iter_dir)
		if(!turf_to_check || (simulated_only && space_type_cache[turf_to_check.type]))
			continue
		if(turf_to_check.density || LinkBlockedWithAccess(turf_to_check, pass_info))
			continue
		. += turf_to_check

/turf/proc/GetHeatCapacity()
	. = heat_capacity

/turf/proc/GetTemperature()
	. = temperature

/turf/proc/TakeTemperature(temp)
	temperature += temp

// I'm sorry, this is the only way that both makes sense and is cheap
/turf/set_explosion_block(explosion_block)
	explosive_resistance -= get_explosive_block()
	inherent_explosive_resistance = explosion_block
	explosive_resistance += get_explosive_block()

/turf/apply_main_material_effects(datum/material/main_material, amount, multipier)
	. = ..()
	if(alpha < 255)
		ADD_TURF_TRANSPARENCY(src, MATERIAL_SOURCE(main_material))
		main_material.setup_glow(src)
	rust_resistance = main_material.mat_rust_resistance

/turf/remove_main_material_effects(datum/material/custom_material, amount, multipier)
	. = ..()
	rust_resistance = initial(rust_resistance)
	if(alpha == 255)
		return
	REMOVE_TURF_TRANSPARENCY(src, MATERIAL_SOURCE(custom_material))
	// yeets glow
	UnregisterSignal(SSdcs, COMSIG_STARLIGHT_COLOR_CHANGED)
	set_light(0, 0, null)

/// Returns whether it is safe for an atom to move across this turf
/turf/proc/can_cross_safely(atom/movable/crossing)
	return TRUE

/**
 * the following are some hacky fishing-related optimizations to shave off
 * time we spend implementing the fishing as possible, even if that means
 * doing hackier code, because we've hundreds of turfs like lava, water etc every round,
 */
/turf/proc/add_lazy_fishing(fish_source_path)
	RegisterSignal(src, COMSIG_FISHING_ROD_CAST, PROC_REF(add_fishing_spot_comp))
	RegisterSignal(src, COMSIG_NPC_FISHING, PROC_REF(on_npc_fishing))
	RegisterSignal(src, COMSIG_FISH_RELEASED_INTO, PROC_REF(on_fish_release_into))
	RegisterSignal(src, COMSIG_TURF_CHANGE, PROC_REF(remove_lazy_fishing))
	ADD_TRAIT(src, TRAIT_FISHING_SPOT, INNATE_TRAIT)
	fish_source = fish_source_path

/turf/proc/remove_lazy_fishing()
	SIGNAL_HANDLER
	UnregisterSignal(src, list(
		COMSIG_FISHING_ROD_CAST,
		COMSIG_NPC_FISHING,
		COMSIG_FISH_RELEASED_INTO,
		COMSIG_ATOM_TOOL_ACT(TOOL_MULTITOOL),
		COMSIG_TURF_CHANGE,
	))
	REMOVE_TRAIT(src, TRAIT_FISHING_SPOT, INNATE_TRAIT)
	fish_source = null

/turf/proc/add_fishing_spot_comp(datum/source, obj/item/fishing_rod/rod, mob/user)
	SIGNAL_HANDLER
	var/datum/component/fishing_spot/spot = source.AddComponent(/datum/component/fishing_spot, fish_source)
	remove_lazy_fishing()
	return spot.handle_cast(arglist(args))

/turf/proc/on_npc_fishing(datum/source, list/fish_spot_container)
	SIGNAL_HANDLER
	fish_spot_container[NPC_FISHING_SPOT] = GLOB.preset_fish_sources[fish_source]

/turf/proc/on_fish_release_into(datum/source, obj/item/fish/fish, mob/living/releaser)
	SIGNAL_HANDLER
	GLOB.preset_fish_sources[fish_source].readd_fish(fish, releaser)

/turf/examine(mob/user)
	. = ..()
	if(!fish_source || !HAS_MIND_TRAIT(user, TRAIT_EXAMINE_FISHING_SPOT))
		return
	if(!GLOB.preset_fish_sources[fish_source].has_known_fishes(src))
		return
	. += span_tinynoticeital("This is a fishing spot. You can look again to list its fishes...")

/turf/examine_more(mob/user)
	. = ..()
	if(!HAS_MIND_TRAIT(user, TRAIT_EXAMINE_FISHING_SPOT) || !fish_source)
		return
	GLOB.preset_fish_sources[fish_source].get_catchable_fish_names(user, src, .)

/turf/ex_act(severity, target)
	. = ..()
	if(!fish_source)
		return
	GLOB.preset_fish_sources[fish_source].spawn_reward_from_explosion(src, severity)

/turf/multitool_act(mob/living/user, obj/item/multitool/tool)
	if(!fish_source || !istype(tool.buffer, /obj/machinery/fishing_portal_generator))
		return ..()
	var/obj/machinery/fishing_portal_generator/portal = tool.buffer
	return portal.link_fishing_spot(GLOB.preset_fish_sources[fish_source], src, user)
