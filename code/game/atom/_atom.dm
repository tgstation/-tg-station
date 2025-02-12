/**
 * The base type for nearly all physical objects in SS13

 * Lots and lots of functionality lives here, although in general we are striving to move
 * as much as possible to the components/elements system
 */
/atom
	layer = ABOVE_NORMAL_TURF_LAYER
	plane = GAME_PLANE
	appearance_flags = TILE_BOUND|LONG_GLIDE

	/// pass_flags that we are. If any of this matches a pass_flag on a moving thing, by default, we let them through.
	var/pass_flags_self = NONE

	///First atom flags var
	var/flags_1 = NONE
	///Intearaction flags
	var/interaction_flags_atom = NONE

	var/flags_ricochet = NONE

	///When a projectile tries to ricochet off this atom, the projectile ricochet chance is multiplied by this
	var/receive_ricochet_chance_mod = 1
	///When a projectile ricochets off this atom, it deals the normal damage * this modifier to this atom
	var/receive_ricochet_damage_coeff = 0.33

	///Reagents holder
	var/datum/reagents/reagents = null

	///all of this atom's HUD (med/sec, etc) images. Associative list of the form: list(hud category = hud image or images for that category).
	///most of the time hud category is associated with a single image, sometimes its associated with a list of images.
	///not every hud in this list is actually used. for ones available for others to see, look at active_hud_list.
	var/list/image/hud_list = null
	///all of this atom's HUD images which can actually be seen by players with that hud
	var/list/image/active_hud_list = null
	///HUD images that this atom can provide.
	var/list/hud_possible

	///How much this atom resists explosions by, in the end
	var/explosive_resistance = 0

	///vis overlays managed by SSvis_overlays to automaticaly turn them like other overlays.
	var/list/managed_vis_overlays

	/// Lazylist of all images (or atoms, I'm sorry) (hopefully attached to us) to update when we change z levels
	/// You will need to manage adding/removing from this yourself, but I'll do the updating for you
	var/list/image/update_on_z

	/// Lazylist of all overlays attached to us to update when we change z levels
	/// You will need to manage adding/removing from this yourself, but I'll do the updating for you
	/// Oh and note, if order of addition is important this WILL break that. so mind yourself
	var/list/image/update_overlays_on_z

	///Cooldown tick timer for buckle messages
	var/buckle_message_cooldown = 0
	///Last fingerprints to touch this atom
	var/fingerprintslast

	/// Radiation insulation types
	var/rad_insulation = RAD_NO_INSULATION

	/// The icon state intended to be used for the acid component. Used to override the default acid overlay icon state.
	var/custom_acid_overlay = null

	var/datum/wires/wires = null

	///Light systems, both shouldn't be active at the same time.
	var/light_system = COMPLEX_LIGHT
	///Range of the light in tiles. Zero means no light.
	var/light_range = 0
	///Intensity of the light. The stronger, the less shadows you will see on the lit area.
	var/light_power = 1
	///Hexadecimal RGB string representing the colour of the light. White by default.
	var/light_color = COLOR_WHITE
	/// Angle of light to show in light_dir
	/// 360 is a circle, 90 is a cone, etc.
	var/light_angle = 360
	/// What angle to project light in
	var/light_dir = NORTH
	///Boolean variable for toggleable lights. Has no effect without the proper light_system, light_range and light_power values.
	var/light_on = TRUE
	/// How many tiles "up" this light is. 1 is typical, should only really change this if it's a floor light
	var/light_height = LIGHTING_HEIGHT
	///Bitflags to determine lighting-related atom properties.
	var/light_flags = NONE
	///Our light source. Don't fuck with this directly unless you have a good reason!
	var/tmp/datum/light_source/light
	///Any light sources that are "inside" of us, for example, if src here was a mob that's carrying a flashlight, that flashlight's light source would be part of this list.
	var/tmp/list/light_sources

	/// Last name used to calculate a color for the chatmessage overlays
	var/chat_color_name
	/// Last color calculated for the the chatmessage overlays
	var/chat_color
	/// A luminescence-shifted value of the last color calculated for chatmessage overlays
	var/chat_color_darkened

	// Use SET_BASE_PIXEL(x, y) to set these in typepath definitions, it'll handle pixel_x and y for you
	///Default pixel x shifting for the atom's icon.
	var/base_pixel_x = 0
	///Default pixel y shifting for the atom's icon.
	var/base_pixel_y = 0
	// Use SET_BASE_VISUAL_PIXEL(x, y) to set these in typepath definitions, it'll handle pixel_w and z for you
	///Default pixel w shifting for the atom's icon.
	var/base_pixel_w = 0
	///Default pixel z shifting for the atom's icon.
	var/base_pixel_z = 0
	///Used for changing icon states for different base sprites.
	var/base_icon_state

	///Icon-smoothing behavior.
	var/smoothing_flags = NONE
	///What directions this is currently smoothing with. IMPORTANT: This uses the smoothing direction flags as defined in icon_smoothing.dm, instead of the BYOND flags.
	var/smoothing_junction = null //This starts as null for us to know when it's first set, but after that it will hold a 8-bit mask ranging from 0 to 255.
	///Smoothing variable
	var/top_left_corner
	///Smoothing variable
	var/top_right_corner
	///Smoothing variable
	var/bottom_left_corner
	///Smoothing variable
	var/bottom_right_corner
	///What smoothing groups does this atom belongs to, to match canSmoothWith. If null, nobody can smooth with it. Must be sorted.
	var/list/smoothing_groups = null
	///List of smoothing groups this atom can smooth with. If this is null and atom is smooth, it smooths only with itself. Must be sorted.
	var/list/canSmoothWith = null

	///AI controller that controls this atom. type on init, then turned into an instance during runtime
	var/datum/ai_controller/ai_controller

	/// forensics datum, contains fingerprints, fibres, blood_dna and hiddenprints on this atom
	var/datum/forensics/forensics

	/// How this atom should react to having its astar blocking checked
	var/can_astar_pass = CANASTARPASS_DENSITY
	///whether ghosts can see screentips on it
	var/ghost_screentips = FALSE

	/// Flags to check for in can_perform_action. Used in alt-click & ctrl-click checks
	var/interaction_flags_click = NONE
	/// Flags to check for in can_perform_action for mouse drag & drop checks. To bypass checks see interaction_flags_atom mouse drop flags
	var/interaction_flags_mouse_drop = NONE

/**
 * Top level of the destroy chain for most atoms
 *
 * Cleans up the following:
 * * Removes alternate apperances from huds that see them
 * * qdels the reagent holder from atoms if it exists
 * * clears the orbiters list
 * * clears overlays and priority overlays
 * * clears the light object
 */
/atom/Destroy(force)
	if(alternate_appearances)
		for(var/current_alternate_appearance in alternate_appearances)
			var/datum/atom_hud/alternate_appearance/selected_alternate_appearance = alternate_appearances[current_alternate_appearance]
			selected_alternate_appearance.remove_atom_from_hud(src)

	if(reagents)
		QDEL_NULL(reagents)

	if(forensics)
		QDEL_NULL(forensics)

	if(atom_storage)
		QDEL_NULL(atom_storage)

	if(wires)
		QDEL_NULL(wires)

	orbiters = null // The component is attached to us normaly and will be deleted elsewhere

	// Checking length(overlays) before cutting has significant speed benefits
	if (length(overlays))
		overlays.Cut()

	LAZYNULL(managed_overlays)
	if(ai_controller)
		QDEL_NULL(ai_controller)
	if(light)
		QDEL_NULL(light)
	if (length(light_sources))
		light_sources.Cut()

	if(smoothing_flags & SMOOTH_QUEUED)
		SSicon_smooth.remove_from_queues(src)

#ifndef DISABLE_DREAMLUAU
	// These lists cease existing when src does, so we need to clear any lua refs to them that exist.
	if(!(datum_flags & DF_STATIC_OBJECT))
		DREAMLUAU_CLEAR_REF_USERDATA(contents)
		DREAMLUAU_CLEAR_REF_USERDATA(filters)
		DREAMLUAU_CLEAR_REF_USERDATA(overlays)
		DREAMLUAU_CLEAR_REF_USERDATA(underlays)
#endif

	return ..()

/atom/proc/handle_ricochet(obj/projectile/ricocheting_projectile)
	var/turf/p_turf = get_turf(ricocheting_projectile)
	var/face_direction = get_dir(src, p_turf) || get_dir(src, ricocheting_projectile)
	var/face_angle = dir2angle(face_direction)
	var/incidence_s = GET_ANGLE_OF_INCIDENCE(face_angle, (ricocheting_projectile.angle + 180))
	var/a_incidence_s = abs(incidence_s)
	if(a_incidence_s > 90 && a_incidence_s < 270)
		return FALSE
	if((ricocheting_projectile.armor_flag in list(BULLET, BOMB)) && ricocheting_projectile.ricochet_incidence_leeway)
		if((a_incidence_s < 90 && a_incidence_s < 90 - ricocheting_projectile.ricochet_incidence_leeway) || (a_incidence_s > 270 && a_incidence_s -270 > ricocheting_projectile.ricochet_incidence_leeway))
			return FALSE
	var/new_angle_s = SIMPLIFY_DEGREES(face_angle + incidence_s)
	ricocheting_projectile.set_angle(new_angle_s)
	return TRUE

/// Whether the mover object can avoid being blocked by this atom, while arriving from (or leaving through) the border_dir.
/atom/proc/CanPass(atom/movable/mover, border_dir)
	SHOULD_CALL_PARENT(TRUE)
	SHOULD_BE_PURE(TRUE)
	if(SEND_SIGNAL(src, COMSIG_ATOM_TRIED_PASS, mover, border_dir) & COMSIG_COMPONENT_PERMIT_PASSAGE)
		return TRUE
	if(mover.movement_type & PHASING)
		return TRUE
	. = CanAllowThrough(mover, border_dir)
	// This is cheaper than calling the proc every time since most things dont override CanPassThrough
	if(!mover.generic_canpass)
		return mover.CanPassThrough(src, REVERSE_DIR(border_dir), .)

/// Returns true or false to allow the mover to move through src
/atom/proc/CanAllowThrough(atom/movable/mover, border_dir)
	SHOULD_CALL_PARENT(TRUE)
	//SHOULD_BE_PURE(TRUE)
	if(mover.pass_flags & pass_flags_self)
		return TRUE
	if(mover.throwing && (pass_flags_self & LETPASSTHROW))
		return TRUE
	return !density

/**
 * Is this atom currently located on centcom (or riding off into the sunset on a shuttle)
 *
 * Specifically, is it on the z level and within the centcom areas.
 * You can also be in a shuttle during endgame transit.
 *
 * Used in gamemode to identify mobs who have escaped and for some other areas of the code
 * who don't want atoms where they shouldn't be
 *
 * Returns TRUE if this atom is on centcom or an escape shuttle, or FALSE if not
 */
/atom/proc/onCentCom()
	var/turf/current_turf = get_turf(src)
	if(!current_turf)
		return FALSE

	// This doesn't necessarily check that we're at central command,
	// but it checks for any shuttles which have finished are still in hyperspace
	// (IE, stuff like the whiteship which fly off into the sunset and "escape")
	if(is_reserved_level(current_turf.z))
		return on_escaped_shuttle(ENDGAME_TRANSIT)

	// From here on we only concern ourselves with people actually on the centcom Z
	if(!is_centcom_level(current_turf.z))
		return FALSE

	if(istype(current_turf.loc, /area/centcom))
		return TRUE

	// Finally, check if we're on an escaped shuttle
	return on_escaped_shuttle()

/**
 * Is the atom in any of the syndicate areas
 *
 * Either in the syndie base, or any of their shuttles
 *
 * Also used in gamemode code for win conditions
 *
 * Returns TRUE if this atom is on the syndicate recon base, any of its shuttles, or an escape shuttle, or FALSE if not
 */
/atom/proc/onSyndieBase()
	var/turf/current_turf = get_turf(src)
	if(!current_turf)
		return FALSE

	// Syndicate base is loaded in a reserved level. If not reserved, we don't care.
	if(!is_reserved_level(current_turf.z))
		return FALSE

	var/static/list/syndie_typecache = typecacheof(list(
		/area/centcom/syndicate_mothership, // syndicate base itself
		/area/shuttle/assault_pod, // steel rain
		/area/shuttle/syndicate, // infiltrator
	))

	if(is_type_in_typecache(current_turf.loc, syndie_typecache))
		return TRUE

	// Finally, check if we're on an escaped shuttle
	return on_escaped_shuttle()

/**
 * Checks that we're on a shuttle that's escaped
 *
 * * check_for_launch_status - What launch status do we check for? Generally the two you want to check for are ENDGAME_LAUNCHED or ENDGAME_TRANSIT
 *
 * Returns TRUE if this atom is on a shuttle which is escaping or has escaped, or FALSE otherwise
 */
/atom/proc/on_escaped_shuttle(check_for_launch_status = ENDGAME_LAUNCHED)
	var/turf/current_turf = get_turf(src)
	if(!current_turf)
		return FALSE

	for(var/obj/docking_port/mobile/mobile_docking_port as anything in SSshuttle.mobile_docking_ports)
		if(mobile_docking_port.launch_status != check_for_launch_status)
			continue
		for(var/area/shuttle/shuttle_area as anything in mobile_docking_port.shuttle_areas)
			if(shuttle_area == current_turf.loc)
				return TRUE

	return FALSE

/**
 * Is the atom in an away mission
 *
 * Must be in the away mission z-level to return TRUE
 *
 * Also used in gamemode code for win conditions
 */
/atom/proc/onAwayMission()
	var/turf/current_turf = get_turf(src)
	if(!current_turf)
		return FALSE

	if(is_away_level(current_turf.z))
		return TRUE

	return FALSE

/**
 * Ensure a list of atoms/reagents exists inside this atom
 *
 * Goes throught he list of passed in parts, if they're reagents, adds them to our reagent holder
 * creating the reagent holder if it exists.
 *
 * If the part is a moveable atom and the  previous location of the item was a mob/living,
 * it calls the inventory handler transferItemToLoc for that mob/living and transfers the part
 * to this atom
 *
 * Otherwise it simply forceMoves the atom into this atom
 */
/atom/proc/CheckParts(list/parts_list, datum/crafting_recipe/current_recipe)
	SEND_SIGNAL(src, COMSIG_ATOM_CHECKPARTS, parts_list, current_recipe)
	if(!parts_list)
		return
	for(var/part in parts_list)
		if(istype(part, /datum/reagent))
			if(!reagents)
				reagents = new()
			reagents.reagent_list.Add(part)
		else if(ismovable(part))
			var/atom/movable/object = part
			if(isliving(object.loc))
				var/mob/living/living = object.loc
				living.transferItemToLoc(object, src)
			else
				object.forceMove(src)
			SEND_SIGNAL(object, COMSIG_ATOM_USED_IN_CRAFT, src)
	parts_list.Cut()

///Take air from the passed in gas mixture datum
/atom/proc/assume_air(datum/gas_mixture/giver)
	return null

///Remove air from this atom
/atom/proc/remove_air(amount)
	return null

///Return the current air environment in this atom
/atom/proc/return_air()
	if(loc)
		return loc.return_air()
	else
		return null

///Return the air if we can analyze it
/atom/proc/return_analyzable_air()
	return null

/atom/proc/Bumped(atom/movable/bumped_atom)
	set waitfor = FALSE
	SEND_SIGNAL(src, COMSIG_ATOM_BUMPED, bumped_atom)

/// Convenience proc to see if a container is open for chemistry handling
/atom/proc/is_open_container()
	return is_refillable() && is_drainable()

/// Is this atom injectable into other atoms
/atom/proc/is_injectable(mob/user, allowmobs = TRUE)
	return reagents && (reagents.flags & (INJECTABLE | REFILLABLE))

/// Can we draw from this atom with an injectable atom
/atom/proc/is_drawable(mob/user, allowmobs = TRUE)
	return reagents && (reagents.flags & (DRAWABLE | DRAINABLE))

/// Can this atoms reagents be refilled
/atom/proc/is_refillable()
	return reagents && (reagents.flags & REFILLABLE)

/// Is this atom drainable of reagents
/atom/proc/is_drainable()
	return reagents && (reagents.flags & DRAINABLE)

/** Handles exposing this atom to a list of reagents.
 *
 * Sends COMSIG_ATOM_EXPOSE_REAGENTS
 * Calls expose_atom() for every reagent in the reagent list.
 *
 * Arguments:
 * - [reagents][/list]: The list of reagents the atom is being exposed to.
 * - [source][/datum/reagents]: The reagent holder the reagents are being sourced from.
 * - methods: How the atom is being exposed to the reagents. Bitflags.
 * - volume_modifier: Volume multiplier.
 * - show_message: Whether to display anything to mobs when they are exposed.
 */
/atom/proc/expose_reagents(list/reagents, datum/reagents/source, methods=TOUCH, volume_modifier=1, show_message=TRUE)
	. = SEND_SIGNAL(src, COMSIG_ATOM_EXPOSE_REAGENTS, reagents, source, methods, volume_modifier, show_message)
	if(. & COMPONENT_NO_EXPOSE_REAGENTS)
		return

	SEND_SIGNAL(source, COMSIG_REAGENTS_EXPOSE_ATOM, src, reagents, methods, volume_modifier, show_message)
	for(var/datum/reagent/current_reagent as anything in reagents)
		. |= current_reagent.expose_atom(src, reagents[current_reagent])
	SEND_SIGNAL(src, COMSIG_ATOM_AFTER_EXPOSE_REAGENTS, reagents, source, methods, volume_modifier, show_message)

/// Are you allowed to drop this atom
/atom/proc/AllowDrop()
	return FALSE

///Is this atom within 1 tile of another atom
/atom/proc/HasProximity(atom/movable/proximity_check_mob as mob|obj)
	return

/// Sets the wire datum of an atom
/atom/proc/set_wires(datum/wires/new_wires)
	wires = new_wires

///Return true if we're inside the passed in atom
/atom/proc/in_contents_of(container)//can take class or object instance as argument
	if(ispath(container))
		if(istype(src.loc, container))
			return TRUE
	else if(src in container)
		return TRUE
	return FALSE

/**
 * Checks the atom's loc and calls update_held_items on it if it is a mob.
 *
 * This should only be used in situations when you are unable to use /datum/element/update_icon_updates_onmob for whatever reason.
 * Check code/datums/elements/update_icon_updates_onmob.dm before using this. Adding that to the atom and calling update_appearance will work for most cases.
 *
 * Arguments:
 * * mob/target - The mob to update the icons of. Optional argument, use if the atom's loc is not the mob you want to update.
 */
/atom/proc/update_inhand_icon(mob/target = loc)
	SHOULD_CALL_PARENT(TRUE)
	if(!istype(target))
		return

	target.update_held_items()

	SEND_SIGNAL(src, COMSIG_ATOM_UPDATE_INHAND_ICON, target)

/**
 * An atom we are buckled or is contained within us has tried to move
 *
 * Default behaviour is to send a warning that the user can't move while buckled as long
 * as the [buckle_message_cooldown][/atom/var/buckle_message_cooldown] has expired (50 ticks)
 */
/atom/proc/relaymove(mob/living/user, direction)
	if(SEND_SIGNAL(src, COMSIG_ATOM_RELAYMOVE, user, direction) & COMSIG_BLOCK_RELAYMOVE)
		return
	if(buckle_message_cooldown <= world.time)
		buckle_message_cooldown = world.time + 25
		balloon_alert(user, "can't move while buckled!")
	return

/**
 * A special case of relaymove() in which the person relaying the move may be "driving" this atom
 *
 * This is a special case for vehicles and ridden animals where the relayed movement may be handled
 * by the riding component attached to this atom. Returns TRUE as long as there's nothing blocking
 * the movement, or FALSE if the signal gets a reply that specifically blocks the movement
 */
/atom/proc/relaydrive(mob/living/user, direction)
	return !(SEND_SIGNAL(src, COMSIG_RIDDEN_DRIVER_MOVE, user, direction) & COMPONENT_DRIVER_BLOCK_MOVE)

///returns the mob's dna info as a list, to be inserted in an object's blood_DNA list
/mob/living/proc/get_blood_dna_list()
	if(get_blood_id() != /datum/reagent/blood)
		return
	return list("ANIMAL DNA" = "Y-")

///Get the mobs dna list
/mob/living/carbon/get_blood_dna_list()
	if(get_blood_id() != /datum/reagent/blood)
		return
	var/list/blood_dna = list()
	if(dna)
		blood_dna[dna.unique_enzymes] = dna.blood_type
	else
		blood_dna["UNKNOWN DNA"] = "X*"
	return blood_dna

/mob/living/carbon/alien/get_blood_dna_list()
	return list("UNKNOWN DNA" = "X*")

/mob/living/silicon/get_blood_dna_list()
	return

///to add a mob's dna info into an object's blood_dna list.
/atom/proc/transfer_mob_blood_dna(mob/living/injected_mob)
	// Returns 0 if we have that blood already
	var/new_blood_dna = injected_mob.get_blood_dna_list()
	if(!new_blood_dna)
		return FALSE
	var/old_length = GET_ATOM_BLOOD_DNA_LENGTH(src)
	add_blood_DNA(new_blood_dna)
	if(GET_ATOM_BLOOD_DNA_LENGTH(src) == old_length)
		return FALSE
	return TRUE

///to add blood from a mob onto something, and transfer their dna info
/atom/proc/add_mob_blood(mob/living/injected_mob)
	var/list/blood_dna = injected_mob.get_blood_dna_list()
	if(!blood_dna)
		return FALSE
	return add_blood_DNA(blood_dna)

///Is this atom in space
/atom/proc/isinspace()
	if(isspaceturf(get_turf(src)))
		return TRUE
	else
		return FALSE

/**
 * If someone's trying to dump items onto our atom, where should they be dumped to?
 *
 * Return a loc to place objects, or null to stop dumping.
 */
/atom/proc/get_dumping_location()
	return null

/**
 * the vision impairment to give to the mob whose perspective is set to that atom
 *
 * (e.g. an unfocused camera giving you an impaired vision when looking through it)
 */
/atom/proc/get_remote_view_fullscreens(mob/user)
	return

/**
 * the sight changes to give to the mob whose perspective is set to that atom
 *
 * (e.g. A mob with nightvision loses its nightvision while looking through a normal camera)
 */
/atom/proc/update_remote_sight(mob/living/user)
	return


/**
 * Hook for running code when a dir change occurs
 *
 * Not recommended to use, listen for the [COMSIG_ATOM_DIR_CHANGE] signal instead (sent by this proc)
 */
/atom/proc/setDir(newdir)
	SHOULD_CALL_PARENT(TRUE)
	if (SEND_SIGNAL(src, COMSIG_ATOM_PRE_DIR_CHANGE, dir, newdir) & COMPONENT_ATOM_BLOCK_DIR_CHANGE)
		newdir = dir
		return
	SEND_SIGNAL(src, COMSIG_ATOM_DIR_CHANGE, dir, newdir)
	var/oldDir = dir
	dir = newdir
	SEND_SIGNAL(src, COMSIG_ATOM_POST_DIR_CHANGE, oldDir, newdir)
	if(smoothing_flags & SMOOTH_BORDER_OBJECT)
		QUEUE_SMOOTH_NEIGHBORS(src)

/**
 * Wash this atom
 *
 * This will clean it off any temporary stuff like blood. Override this in your item to add custom cleaning behavior.
 * Returns true if any washing was necessary and thus performed
 * Arguments:
 * * clean_types: any of the CLEAN_ constants
 */
/atom/proc/wash(clean_types)
	SHOULD_CALL_PARENT(TRUE)
	if(SEND_SIGNAL(src, COMSIG_COMPONENT_CLEAN_ACT, clean_types) & COMPONENT_CLEANED)
		return TRUE

	// Basically "if has washable coloration"
	if(length(atom_colours) >= WASHABLE_COLOUR_PRIORITY && atom_colours[WASHABLE_COLOUR_PRIORITY])
		remove_atom_colour(WASHABLE_COLOUR_PRIORITY)
		return TRUE
	return FALSE

///Where atoms should drop if taken from this atom
/atom/proc/drop_location()
	var/atom/location = loc
	if(!location)
		return null
	return location.AllowDrop() ? location : location.drop_location()

/**
 * An atom has entered this atom's contents
 *
 * Default behaviour is to send the [COMSIG_ATOM_ENTERED]
 */
/atom/Entered(atom/movable/arrived, atom/old_loc, list/atom/old_locs)
	SEND_SIGNAL(src, COMSIG_ATOM_ENTERED, arrived, old_loc, old_locs)
	SEND_SIGNAL(arrived, COMSIG_ATOM_ENTERING, src, old_loc, old_locs)

/**
 * An atom is attempting to exit this atom's contents
 *
 * Default behaviour is to send the [COMSIG_ATOM_EXIT]
 */
/atom/Exit(atom/movable/leaving, direction)
	// Don't call `..()` here, otherwise `Uncross()` gets called.
	// See the doc comment on `Uncross()` to learn why this is bad.

	if(SEND_SIGNAL(src, COMSIG_ATOM_EXIT, leaving, direction) & COMPONENT_ATOM_BLOCK_EXIT)
		return FALSE

	return TRUE

/**
 * An atom has exited this atom's contents
 *
 * Default behaviour is to send the [COMSIG_ATOM_EXITED]
 */
/atom/Exited(atom/movable/gone, direction)
	SEND_SIGNAL(src, COMSIG_ATOM_EXITED, gone, direction)

///Return atom temperature
/atom/proc/return_temperature()
	return

/atom/proc/process_recipes(mob/living/user, obj/item/processed_object, list/processing_recipes)
	//Only one recipe? use the first
	if(processing_recipes.len == 1)
		StartProcessingAtom(user, processed_object, processing_recipes[1])
		return
	//Otherwise, select one with a radial
	ShowProcessingGui(user, processed_object, processing_recipes)

///Creates the radial and processes the selected option
/atom/proc/ShowProcessingGui(mob/living/user, obj/item/processed_object, list/possible_options)
	var/list/choices_to_options = list() //Dict of object name | dict of object processing settings
	var/list/choices = list()

	for(var/list/current_option as anything in possible_options)
		var/atom/current_option_type = current_option[TOOL_PROCESSING_RESULT]
		choices_to_options[initial(current_option_type.name)] = current_option
		var/image/option_image = image(icon = initial(current_option_type.icon), icon_state = initial(current_option_type.icon_state))
		choices += list("[initial(current_option_type.name)]" = option_image)

	var/pick = show_radial_menu(user, src, choices, radius = 36, require_near = TRUE)
	if(!pick)
		return

	StartProcessingAtom(user, processed_object, choices_to_options[pick])


/atom/proc/StartProcessingAtom(mob/living/user, obj/item/process_item, list/chosen_option)
	var/processing_time = chosen_option[TOOL_PROCESSING_TIME]
	to_chat(user, span_notice("You start working on [src]."))
	if(process_item.use_tool(src, user, processing_time, volume=50))
		var/atom/atom_to_create = chosen_option[TOOL_PROCESSING_RESULT]
		var/list/atom/created_atoms = list()
		var/amount_to_create = chosen_option[TOOL_PROCESSING_AMOUNT]
		for(var/i = 1 to amount_to_create)
			var/atom/created_atom = new atom_to_create(drop_location())
			if(custom_materials)
				created_atom.set_custom_materials(custom_materials, 1 / amount_to_create)
			created_atom.pixel_x = pixel_x
			created_atom.pixel_y = pixel_y
			if(i > 1)
				created_atom.pixel_x += rand(-8,8)
				created_atom.pixel_y += rand(-8,8)
			created_atom.OnCreatedFromProcessing(user, process_item, chosen_option, src)
			created_atoms.Add(created_atom)
		to_chat(user, span_notice("You manage to create [amount_to_create] [initial(atom_to_create.gender) == PLURAL ? "[initial(atom_to_create.name)]" : "[initial(atom_to_create.name)][plural_s(initial(atom_to_create.name))]"] from [src]."))
		SEND_SIGNAL(src, COMSIG_ATOM_PROCESSED, user, process_item, created_atoms)
		UsedforProcessing(user, process_item, chosen_option, created_atoms)
		return

/atom/proc/UsedforProcessing(mob/living/user, obj/item/used_item, list/chosen_option, list/created_atoms)
	qdel(src)
	return

/atom/proc/OnCreatedFromProcessing(mob/living/user, obj/item/work_tool, list/chosen_option, atom/original_atom)
	SHOULD_CALL_PARENT(TRUE)

	if(HAS_TRAIT(original_atom, TRAIT_FOOD_SILVER))
		ADD_TRAIT(src, TRAIT_FOOD_SILVER, INNATE_TRAIT) // stinky food always stinky

	SEND_SIGNAL(src, COMSIG_ATOM_CREATEDBY_PROCESSING, original_atom, chosen_option)
	if(user.mind)
		ADD_TRAIT(src, TRAIT_FOOD_CHEF_MADE, REF(user.mind))

///Connect this atom to a shuttle
/atom/proc/connect_to_shuttle(mapload, obj/docking_port/mobile/port, obj/docking_port/stationary/dock)
	return

/atom/proc/intercept_zImpact(list/falling_movables, levels = 1)
	SHOULD_CALL_PARENT(TRUE)
	. |= SEND_SIGNAL(src, COMSIG_ATOM_INTERCEPT_Z_FALL, falling_movables, levels)

///Setter for the `density` variable to append behavior related to its changing.
/atom/proc/set_density(new_value)
	SHOULD_CALL_PARENT(TRUE)
	if(density == new_value)
		return
	. = density
	density = new_value
	SEND_SIGNAL(src, COMSIG_ATOM_DENSITY_CHANGED)

///Setter for the `base_pixel_x` variable to append behavior related to its changing.
/atom/proc/set_base_pixel_x(new_value)
	if(base_pixel_x == new_value)
		return
	. = base_pixel_x
	base_pixel_x = new_value

	pixel_x = pixel_x + base_pixel_x - .

///Setter for the `base_pixel_y` variable to append behavior related to its changing.
/atom/proc/set_base_pixel_y(new_value)
	if(base_pixel_y == new_value)
		return
	. = base_pixel_y
	base_pixel_y = new_value

	pixel_y = pixel_y + base_pixel_y - .

// Not a valid operation, turfs and movables handle block differently
/atom/proc/set_explosion_block(explosion_block)
	return

/**
 * Returns true if this atom has gravity for the passed in turf
 *
 * Sends signals [COMSIG_ATOM_HAS_GRAVITY] and [COMSIG_TURF_HAS_GRAVITY], both can force gravity with
 * the forced gravity var.
 *
 * micro-optimized to hell because this proc is very hot, being called several times per movement every movement.
 *
 * HEY JACKASS, LISTEN
 * IF YOU ADD SOMETHING TO THIS PROC, MAKE SURE /mob/living ACCOUNTS FOR IT
 * Living mobs treat gravity in an event based manner. We've decomposed this proc into different checks
 * for them to use. If you add more to it, make sure you do that, or things will behave strangely
 *
 * Gravity situations:
 * * No gravity if you're not in a turf
 * * No gravity if this atom is in is a space turf
 * * No gravity if the area has NO_GRAVITY flag (space, ordnance bomb site, nearstation, solars)
 * * Gravity if the area it's in always has gravity
 * * Gravity if there's a gravity generator on the z level
 * * Gravity if the Z level has an SSMappingTrait for ZTRAIT_GRAVITY
 * * otherwise no gravity
 */
/atom/proc/has_gravity(turf/gravity_turf)
	if(!isturf(gravity_turf))
		gravity_turf = get_turf(src)

		if(!gravity_turf)//no gravity in nullspace
			return FALSE

	var/list/forced_gravity = list()
	SEND_SIGNAL(src, COMSIG_ATOM_HAS_GRAVITY, gravity_turf, forced_gravity)
	SEND_SIGNAL(gravity_turf, COMSIG_TURF_HAS_GRAVITY, src, forced_gravity)
	if(length(forced_gravity))
		var/positive_grav = max(forced_gravity)
		var/negative_grav = min(min(forced_gravity), 0) //negative grav needs to be below or equal to 0

		//our gravity is sum of the most massive positive and negative numbers returned by the signal
		//so that adding two forced_gravity elements with an effect size of 1 each doesnt add to 2 gravity
		//but negative force gravity effects can cancel out positive ones

		return (positive_grav + negative_grav)

	var/area/turf_area = gravity_turf.loc

	return (!gravity_turf.force_no_gravity && !(turf_area.area_flags & NO_GRAVITY)) && (SSmapping.gravity_by_z_level[gravity_turf.z] || turf_area.default_gravity)

/**
 * Used to set something as 'open' if it's being used as a supplypod
 *
 * Override this if you want an atom to be usable as a supplypod.
 */
/atom/proc/setOpened()
	return

/**
 * Used to set something as 'closed' if it's being used as a supplypod
 *
 * Override this if you want an atom to be usable as a supplypod.
 */
/atom/proc/setClosed()
	return

///Called after the atom is 'tamed' for type-specific operations, Usually called by the tameable component but also other things.
/atom/proc/tamed(mob/living/tamer, obj/item/food)
	return

/**
 * Used to attempt to charge an object with a payment component.
 *
 * Use this if an atom needs to attempt to charge another atom.
 */
/atom/proc/attempt_charge(atom/sender, atom/target, extra_fees = 0)
	return SEND_SIGNAL(sender, COMSIG_OBJ_ATTEMPT_CHARGE, target, extra_fees)

///Passes Stat Browser Panel clicks to the game and calls client click on an atom
/atom/Topic(href, list/href_list)
	. = ..()
	if(!usr?.client)
		return
	var/client/usr_client = usr.client
	var/list/paramslist = list()

	if(href_list["statpanel_item_click"])
		switch(href_list["statpanel_item_click"])
			if("left")
				paramslist[LEFT_CLICK] = "1"
			if("right")
				paramslist[RIGHT_CLICK] = "1"
			if("middle")
				paramslist[MIDDLE_CLICK] = "1"
			else
				return

		if(href_list["statpanel_item_shiftclick"])
			paramslist[SHIFT_CLICK] = "1"
		if(href_list["statpanel_item_ctrlclick"])
			paramslist[CTRL_CLICK] = "1"
		if(href_list["statpanel_item_altclick"])
			paramslist[ALT_CLICK] = "1"

		var/mouseparams = list2params(paramslist)
		usr_client.Click(src, loc, null, mouseparams)
		return TRUE

/atom/MouseEntered(location, control, params)
	SSmouse_entered.hovers[usr.client] = src

/// Fired whenever this atom is the most recent to be hovered over in the tick.
/// Preferred over MouseEntered if you do not need information such as the position of the mouse.
/// Especially because this is deferred over a tick, do not trust that `client` is not null.
/atom/proc/on_mouse_enter(client/client)
	SHOULD_NOT_SLEEP(TRUE)

	var/mob/user = client?.mob
	if (isnull(user))
		return

	SEND_SIGNAL(user, COMSIG_ATOM_MOUSE_ENTERED, src)

	// Screentips
	var/datum/hud/active_hud = user.hud_used
	if(!active_hud)
		return

	var/screentips_enabled = active_hud.screentips_enabled
	if(screentips_enabled == SCREENTIP_PREFERENCE_DISABLED || flags_1 & NO_SCREENTIPS_1)
		active_hud.screentip_text.maptext = ""
		return

	var/lmb_rmb_line = ""
	var/ctrl_lmb_ctrl_rmb_line = ""
	var/alt_lmb_alt_rmb_line = ""
	var/shift_lmb_ctrl_shift_lmb_line = ""
	var/extra_lines = 0
	var/extra_context = ""
	var/used_name = name

	if(isliving(user) || isovermind(user) || iscameramob(user) || (ghost_screentips && isobserver(user)))
		var/obj/item/held_item = user.get_active_held_item()

		if (user.mob_flags & MOB_HAS_SCREENTIPS_NAME_OVERRIDE)
			var/list/returned_name = list(used_name)

			var/name_override_returns = SEND_SIGNAL(user, COMSIG_MOB_REQUESTING_SCREENTIP_NAME_FROM_USER, returned_name, held_item, src)
			if (name_override_returns & SCREENTIP_NAME_SET)
				used_name = returned_name[1]

		if (flags_1 & HAS_CONTEXTUAL_SCREENTIPS_1 || held_item?.item_flags & ITEM_HAS_CONTEXTUAL_SCREENTIPS)
			var/list/context = list()

			var/contextual_screentip_returns = \
				SEND_SIGNAL(src, COMSIG_ATOM_REQUESTING_CONTEXT_FROM_ITEM, context, held_item, user) \
				| (held_item && SEND_SIGNAL(held_item, COMSIG_ITEM_REQUESTING_CONTEXT_FOR_TARGET, context, src, user))

			if (contextual_screentip_returns & CONTEXTUAL_SCREENTIP_SET)
				var/screentip_images = active_hud.screentip_images
				// LMB and RMB on one line...
				var/lmb_text = build_context(context, SCREENTIP_CONTEXT_LMB, screentip_images)
				var/rmb_text = build_context(context, SCREENTIP_CONTEXT_RMB, screentip_images)

				if (lmb_text != "")
					lmb_rmb_line = lmb_text
					if (rmb_text != "")
						lmb_rmb_line += " | [rmb_text]"
				else if (rmb_text != "")
					lmb_rmb_line = rmb_text

				// Ctrl-LMB, Ctrl-RMB on one line...
				if (lmb_rmb_line != "")
					lmb_rmb_line += "<br>"
					extra_lines++
				if (SCREENTIP_CONTEXT_CTRL_LMB in context)
					ctrl_lmb_ctrl_rmb_line += build_context(context, SCREENTIP_CONTEXT_CTRL_LMB, screentip_images)

				if (SCREENTIP_CONTEXT_CTRL_RMB in context)
					if (ctrl_lmb_ctrl_rmb_line != "")
						ctrl_lmb_ctrl_rmb_line += " | "
					ctrl_lmb_ctrl_rmb_line += build_context(context, SCREENTIP_CONTEXT_CTRL_RMB, screentip_images)

				// Alt-LMB, Alt-RMB on one line...
				if (ctrl_lmb_ctrl_rmb_line != "")
					ctrl_lmb_ctrl_rmb_line += "<br>"
					extra_lines++
				if (SCREENTIP_CONTEXT_ALT_LMB in context)
					alt_lmb_alt_rmb_line += build_context(context, SCREENTIP_CONTEXT_ALT_LMB, screentip_images)
				if (SCREENTIP_CONTEXT_ALT_RMB in context)
					if (alt_lmb_alt_rmb_line != "")
						alt_lmb_alt_rmb_line += " | "
					alt_lmb_alt_rmb_line += build_context(context, SCREENTIP_CONTEXT_ALT_RMB, screentip_images)

				// Shift-LMB, Ctrl-Shift-LMB on one line...
				if (alt_lmb_alt_rmb_line != "")
					alt_lmb_alt_rmb_line += "<br>"
					extra_lines++
				if (SCREENTIP_CONTEXT_SHIFT_LMB in context)
					shift_lmb_ctrl_shift_lmb_line += build_context(context, SCREENTIP_CONTEXT_SHIFT_LMB, screentip_images)
				if (SCREENTIP_CONTEXT_CTRL_SHIFT_LMB in context)
					if (shift_lmb_ctrl_shift_lmb_line != "")
						shift_lmb_ctrl_shift_lmb_line += " | "
					shift_lmb_ctrl_shift_lmb_line += build_context(context, SCREENTIP_CONTEXT_CTRL_SHIFT_LMB, screentip_images)

				if (shift_lmb_ctrl_shift_lmb_line != "")
					extra_lines++

				if(extra_lines)
					extra_context = "<br><span class='subcontext'>[lmb_rmb_line][ctrl_lmb_ctrl_rmb_line][alt_lmb_alt_rmb_line][shift_lmb_ctrl_shift_lmb_line]</span>"

	var/new_maptext
	if (screentips_enabled == SCREENTIP_PREFERENCE_CONTEXT_ONLY && extra_context == "")
		new_maptext = ""
	else
		//We inline a MAPTEXT() here, because there's no good way to statically add to a string like this
		new_maptext = "<span class='context' style='text-align: center; color: [active_hud.screentip_color]'>[used_name][extra_context]</span>"

	if (length(used_name) * 10 > active_hud.screentip_text.maptext_width)
		INVOKE_ASYNC(src, PROC_REF(set_hover_maptext), client, active_hud, new_maptext)
		return

	active_hud.screentip_text.maptext = new_maptext
	active_hud.screentip_text.maptext_y = 10 - (extra_lines > 0 ? 11 + 9 * (extra_lines - 1): 0)

/atom/proc/set_hover_maptext(client/client, datum/hud/active_hud, new_maptext)
	var/map_height
	WXH_TO_HEIGHT(client.MeasureText(new_maptext, null, active_hud.screentip_text.maptext_width), map_height)
	active_hud.screentip_text.maptext = new_maptext
	active_hud.screentip_text.maptext_y = 26 - map_height

/**
 * This proc is used for telling whether something can pass by this atom in a given direction, for use by the pathfinding system.
 *
 * Trying to generate one long path across the station will call this proc on every single object on every single tile that we're seeing if we can move through, likely
 * multiple times per tile since we're likely checking if we can access said tile from multiple directions, so keep these as lightweight as possible.
 *
 * For turfs this will only be used if pathing_pass_method is TURF_PATHING_PASS_PROC
 *
 * Arguments:
 * * to_dir - What direction we're trying to move in, relevant for things like directional windows that only block movement in certain directions
 * * pass_info - Datum that stores info about the thing that's trying to pass us
 *
 * IMPORTANT NOTE: /turf/proc/LinkBlockedWithAccess assumes that overrides of CanAStarPass will always return true if density is FALSE
 * If this is NOT you, ensure you edit your can_astar_pass variable. Check __DEFINES/path.dm
 **/
/atom/proc/CanAStarPass(to_dir, datum/can_pass_info/pass_info)
	if(pass_info.pass_flags & pass_flags_self)
		return TRUE
	. = !density
