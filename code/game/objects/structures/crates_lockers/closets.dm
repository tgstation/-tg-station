#define LOCKER_FULL -1

///A comprehensive list of all closets (NOT CRATES) in the game world
GLOBAL_LIST_EMPTY(roundstart_station_closets)


/obj/structure/closet
	name = "closet"
	desc = "It's a basic storage unit."
	icon = 'icons/obj/storage/closet.dmi'
	icon_state = "generic"
	density = TRUE
	drag_slowdown = 1.5 // Same as a prone mob
	max_integrity = 200
	integrity_failure = 0.25
	armor_type = /datum/armor/structure_closet
	blocks_emissive = EMISSIVE_BLOCK_GENERIC
	/// How close being inside of the thing provides complete pressure safety. Must be between 0 and 1!
	contents_pressure_protection = 0
	/// How insulated the thing is, for the purposes of calculating body temperature. Must be between 0 and 1!
	contents_thermal_insulation = 0
	pass_flags_self = PASSSTRUCTURE | LETPASSCLICKS

	/// The overlay for the closet's door
	var/obj/effect/overlay/closet_door/door_obj
	/// Whether or not this door is being animated
	var/is_animating_door = FALSE
	/// Vertical squish of the door
	var/door_anim_squish = 0.2
	/// The maximum angle the door will be drawn at
	var/door_anim_angle = 140
	/// X position of the closet door hinge, relative to the center of the sprite
	var/door_hinge_x = -6.5
	/// Amount of time it takes for the door animation to play
	var/door_anim_time = 2 // set to 0 to make the door not animate at all
	/// Paint jobs for this closet, crates are a subtype of closet so they override these values
	var/list/paint_jobs = TRUE
	/// Controls whether a door overlay should be applied using the icon_door value as the icon state
	var/enable_door_overlay = TRUE
	var/has_opened_overlay = TRUE
	var/has_closed_overlay = TRUE
	var/icon_door = null
	var/opened = FALSE
	var/welded = FALSE
	var/locked = FALSE
	var/large = TRUE
	var/wall_mounted = 0 //never solid (You can always pass over it)
	var/breakout_time = 1200
	var/message_cooldown
	var/can_weld_shut = TRUE
	var/horizontal = FALSE
	var/allow_objects = FALSE
	var/allow_dense = FALSE
	var/dense_when_open = FALSE //if it's dense when open or not
	var/max_mob_size = MOB_SIZE_HUMAN //Biggest mob_size accepted by the container
	var/mob_storage_capacity = 3 // how many human sized mob/living can fit together inside a closet.
	var/storage_capacity = 30 //This is so that someone can't pack hundreds of items in a locker/crate then open it in a populated area to crash clients.
	var/cutting_tool = /obj/item/weldingtool
	var/open_sound = 'sound/machines/closet/closet_open.ogg'
	var/close_sound = 'sound/machines/closet/closet_close.ogg'
	var/lock_sound = 'sound/machines/closet/closet_lock.ogg'
	var/unlock_sound = 'sound/machines/closet/closet_unlock.ogg'
	var/open_sound_volume = 35
	var/close_sound_volume = 50
	var/material_drop = /obj/item/stack/sheet/iron
	var/material_drop_amount = 2
	var/delivery_icon = "deliverycloset" //which icon to use when packagewrapped. null to be unwrappable.
	var/anchorable = TRUE
	var/icon_welded = "welded"
	var/icon_broken = "sparking"
	/// Whether a skittish person can dive inside this closet. Disable if opening the closet causes "bad things" to happen or that it leads to a logical inconsistency.
	var/divable = TRUE
	/// true whenever someone with the strong pull component (or magnet modsuit module) is dragging this, preventing opening
	var/strong_grab = FALSE
	/// secure locker or not, also used if overriding a non-secure locker with a secure door overlay to add fancy lights
	var/secure = FALSE
	var/can_install_electronics = TRUE

	var/is_maploaded = FALSE

	var/contents_initialized = FALSE
	/// is this closet locked by an exclusive id, i.e. your own personal locker
	var/datum/weakref/id_card = null
	/// should we prevent further access change
	var/access_locked = FALSE
	/// is the card reader installed in this machine
	var/card_reader_installed = FALSE
	/// access types for card reader
	var/list/access_choices = TRUE

	/// Whether this closet is sealed or not. If sealed, it'll have its own internal air
	var/sealed = FALSE

	/// Internal gas for this closet.
	var/datum/gas_mixture/internal_air
	/// Volume of the internal air
	var/air_volume = TANK_STANDARD_VOLUME * 3

	/// How many pixels the closet can shift on the x axis when shaking
	var/x_shake_pixel_shift = 2
	/// how many pixels the closet can shift on the y axes when shaking
	var/y_shake_pixel_shift = 1

/datum/armor/structure_closet
	melee = 20
	bullet = 10
	laser = 10
	bomb = 10
	fire = 70
	acid = 60

/obj/structure/closet/Initialize(mapload)
	. = ..()

	var/static/list/closet_paint_jobs
	if(isnull(closet_paint_jobs))
		closet_paint_jobs = list(
		"Cargo" = list("icon_state" = "qm"),
		"Engineering" = list("icon_state" = "ce"),
		"Engineering Secure" = list("icon_state" = "eng_secure"),
		"Radiation" = list("icon_state" = "eng", "icon_door" = "eng_rad"),
		"Tool Storage" = list("icon_state" = "eng", "icon_door" = "eng_tool"),
		"Fire Equipment" = list("icon_state" = "fire"),
		"Emergency" = list("icon_state" = "emergency"),
		"Hydroponics" = list("icon_state" = "hydro"),
		"Medical" = list("icon_state" = "med"),
		"Science" = list("icon_state" = "rd"),
		"Security" = list("icon_state" = "cap"),
		"Mining" = list("icon_state" = "mining"),
		"Virology" = list("icon_state" = "bio_viro"),
		)
	if(paint_jobs)
		paint_jobs = closet_paint_jobs

	var/static/list/card_reader_choices
	if(isnull(card_reader_choices))
		card_reader_choices = list(
			"Personal",
			"Job",
			"None"
			)
	if(access_choices)
		access_choices = card_reader_choices

	if(is_station_level(z) && mapload)
		add_to_roundstart_list()

	// if closed, any item at the crate's loc is put in the contents
	if (mapload)
		is_maploaded = TRUE
	. = INITIALIZE_HINT_LATELOAD

	populate_contents_immediate()
	var/static/list/loc_connections = list(
		COMSIG_LIVING_DISARM_COLLIDE = PROC_REF(locker_living),
		COMSIG_ATOM_MAGICALLY_UNLOCKED = PROC_REF(on_magic_unlock),
	)
	AddElement(/datum/element/connect_loc, loc_connections)
	register_context()

	if(opened)
		opened = FALSE //necessary because open() proc will early return if its true
		if(open(special_effects = FALSE)) //closets which are meant to be open by default don't need to be animated open
			return
	update_appearance()

/obj/structure/closet/LateInitialize()
	if(!opened && is_maploaded)
		take_contents()

	if(sealed)
		var/datum/gas_mixture/external_air = loc.return_air()
		if(external_air && is_maploaded)
			internal_air = external_air.copy()
		else
			internal_air = new()
		START_PROCESSING(SSobj, src)

/obj/structure/closet/return_air()
	if(sealed)
		return internal_air
	else
		return ..()

//USE THIS TO FILL IT, NOT INITIALIZE OR NEW
/obj/structure/closet/proc/PopulateContents()
	return

/// Populate the closet with stuff that needs to be added before it is opened.
/// This is useful for things like traitor objectives.
/obj/structure/closet/proc/populate_contents_immediate()
	return

/obj/structure/closet/Destroy()
	id_card = null
	QDEL_NULL(internal_air)
	QDEL_NULL(door_obj)
	GLOB.roundstart_station_closets -= src
	return ..()

/obj/structure/closet/process(seconds_per_tick)
	if(!sealed)
		return PROCESS_KILL
	process_internal_air(seconds_per_tick)

/obj/structure/closet/proc/process_internal_air(seconds_per_tick)
	if(opened)
		var/datum/gas_mixture/current_exposed_air = loc.return_air()
		if(!current_exposed_air)
			return
		if(current_exposed_air.equalize(internal_air))
			var/turf/location = get_turf(src)
			location.air_update_turf()

/obj/structure/closet/update_appearance(updates=ALL)
	. = ..()
	if(opened || broken || !secure)
		luminosity = 0
		return
	luminosity = 1

/obj/structure/closet/update_icon()
	. = ..()
	if(issupplypod(src))
		return
	layer = opened ? BELOW_OBJ_LAYER : OBJ_LAYER

/obj/structure/closet/update_overlays()
	. = ..()
	closet_update_overlays(.)

/obj/structure/closet/proc/closet_update_overlays(list/new_overlays)
	. = new_overlays
	if(enable_door_overlay && !is_animating_door)
		var/overlay_state = isnull(base_icon_state) ? initial(icon_state) : base_icon_state
		if(opened && has_opened_overlay)
			var/mutable_appearance/door_overlay = mutable_appearance(icon, "[overlay_state]_open", alpha = src.alpha)
			. += door_overlay
			door_overlay.overlays += emissive_blocker(door_overlay.icon, door_overlay.icon_state, src, alpha = door_overlay.alpha) // If we don't do this the door doesn't block emissives and it looks weird.
		else if(has_closed_overlay)
			var/mutable_appearance/door_overlay = mutable_appearance(icon, "[icon_door || overlay_state]_door", alpha = src.alpha)
			. += door_overlay

	if(opened)
		return

	if(welded)
		. += icon_welded

	if(broken && secure)
		. += mutable_appearance(icon, icon_broken, alpha = alpha)
		. += emissive_appearance(icon, icon_broken, src, alpha = alpha)
		return

	if(broken || !secure)
		return
	//Overlay is similar enough for both that we can use the same mask for both
	. += emissive_appearance(icon, "locked", src, alpha = src.alpha)
	. += locked ? "locked" : "unlocked"

/obj/structure/closet/vv_edit_var(vname, vval)
	if(vname == NAMEOF(src, opened))
		if(vval == opened)
			return FALSE
		if(vval && !opened && open(force = TRUE))
			datum_flags |= DF_VAR_EDITED
			return TRUE
		else if(!vval && opened && close())
			datum_flags |= DF_VAR_EDITED
			return TRUE
		return FALSE
	. = ..()
	if(vname == NAMEOF(src, welded) && welded && !can_weld_shut)
		can_weld_shut = TRUE
	else if(vname == NAMEOF(src, can_weld_shut) && !can_weld_shut && welded)
		welded = FALSE
		update_appearance()
	if(vname in list(NAMEOF(src, locked), NAMEOF(src, welded), NAMEOF(src, secure), NAMEOF(src, icon_welded), NAMEOF(src, delivery_icon)))
		update_appearance()

/// Animates the closet door opening and closing
/obj/structure/closet/proc/animate_door(closing = FALSE)
	if(!door_anim_time)
		return
	if(!door_obj)
		door_obj = new
	var/default_door_icon = "[icon_door || icon_state]_door"
	vis_contents += door_obj
	door_obj.icon = icon
	door_obj.icon_state = default_door_icon
	is_animating_door = TRUE
	var/num_steps = door_anim_time / world.tick_lag

	for(var/step in 0 to num_steps)
		var/angle = door_anim_angle * (closing ? 1 - (step/num_steps) : (step/num_steps))

		var/matrix/door_transform = get_door_transform(angle)
		var/door_state
		var/door_layer

		if (angle >= 90)
			door_state = "[icon_state]_back"
			door_layer = FLOAT_LAYER
		else
			door_state = default_door_icon
			door_layer = ABOVE_MOB_LAYER

		if(step == 0)
			door_obj.transform = door_transform
			door_obj.icon_state = door_state
			door_obj.layer = door_layer
		else if(step == 1)
			animate(door_obj, transform = door_transform, icon_state = door_state, layer = door_layer, time = world.tick_lag, flags = ANIMATION_END_NOW)
		else
			animate(transform = door_transform, icon_state = door_state, layer = door_layer, time = world.tick_lag)
	addtimer(CALLBACK(src, PROC_REF(end_door_animation)), door_anim_time, TIMER_UNIQUE|TIMER_OVERRIDE|TIMER_CLIENT_TIME)

/// Ends the door animation and removes the animated overlay
/obj/structure/closet/proc/end_door_animation()
	is_animating_door = FALSE
	vis_contents -= door_obj
	update_icon()

/// Calculates the matrix to be applied to the animated door overlay
/obj/structure/closet/proc/get_door_transform(angle)
	var/matrix/door_matrix = matrix()
	door_matrix.Translate(-door_hinge_x, 0)
	door_matrix.Multiply(matrix(cos(angle), 0, 0, -sin(angle) * door_anim_squish, 1, 0))
	door_matrix.Translate(door_hinge_x, 0)
	return door_matrix

/obj/structure/closet/examine(mob/user)
	. = ..()
	if(id_card)
		. += span_notice("It can be [EXAMINE_HINT("marked")] with a pen.")
	if(can_weld_shut && !welded)
		. += span_notice("It can be [EXAMINE_HINT("welded")] shut.")
	if(welded)
		. += span_notice("It's [EXAMINE_HINT("welded")] shut.")
	if(anchorable && !anchored)
		. += span_notice("It can be [EXAMINE_HINT("bolted")] to the ground.")
	if(anchored)
		. += span_notice("It's [anchorable ? EXAMINE_HINT("bolted") : "attached firmly"] to the ground.")
	if(length(paint_jobs))
		. += span_notice("It can be [EXAMINE_HINT("painted")] with another texture.")
	if(HAS_TRAIT(user, TRAIT_SKITTISH) && divable)
		. += span_notice("If you bump into [p_them()] while running, you will jump inside.")

	if(can_install_electronics)
		if(!secure)
			. += span_notice("You can install airlock electronics for access control.")
		else
			. += span_notice("Its airlock electronics are [EXAMINE_HINT("screwed")] in place.")
		if(!card_reader_installed && length(access_choices))
			. += span_notice("You can install a card reader for further access control.")
		else if(card_reader_installed)
			. += span_notice("The card reader could be [EXAMINE_HINT("pried")] out.")
			. += span_notice("Swipe your PDA with an ID card/Just ID to change access levels.")
			. += span_notice("Use multitool to [access_locked ? "unlock" : "lock"] the access panel.")

/obj/structure/closet/add_context(atom/source, list/context, obj/item/held_item, mob/user)
	. = ..()
	var/screentip_change = FALSE

	if(isnull(held_item))
		if(secure && !broken)
			context[SCREENTIP_CONTEXT_RMB] = opened ? "Lock" : "Unlock"
		if(!welded)
			context[SCREENTIP_CONTEXT_LMB] = opened ? "Close" : "Open"
		screentip_change = TRUE

	if(istype(held_item, cutting_tool))
		if(opened)
			context[SCREENTIP_CONTEXT_LMB] = "Deconstruct"
			screentip_change = TRUE
		else
			if(!welded && can_weld_shut)
				context[SCREENTIP_CONTEXT_LMB] = "Weld"
				screentip_change = TRUE
			else if(welded)
				context[SCREENTIP_CONTEXT_LMB] = "Unweld"
				screentip_change = TRUE

	if(istype(held_item) && held_item.tool_behaviour == TOOL_WRENCH && anchorable)
		context[SCREENTIP_CONTEXT_RMB] = anchored ? "Unanchor" : "Anchor"
		screentip_change = TRUE

	if(!locked && !opened && (welded || !can_weld_shut))
		if(!secure)
			if(!broken && can_install_electronics && istype(held_item, /obj/item/electronics/airlock))
				context[SCREENTIP_CONTEXT_LMB] = "Install Electronics"
				screentip_change = TRUE
		else
			if(istype(held_item) && held_item.tool_behaviour == TOOL_SCREWDRIVER)
				context[SCREENTIP_CONTEXT_LMB] = "Remove Electronics"
				screentip_change = TRUE
			if(!card_reader_installed && length(access_choices) && !broken && can_install_electronics && istype(held_item, /obj/item/stock_parts/card_reader))
				context[SCREENTIP_CONTEXT_LMB] = "Install Reader"
				screentip_change = TRUE
		if(card_reader_installed && istype(held_item) && held_item.tool_behaviour == TOOL_CROWBAR)
			context[SCREENTIP_CONTEXT_LMB] = "Remove Reader"
			screentip_change = TRUE

	if(!locked && !opened)
		if(id_card && IS_WRITING_UTENSIL(held_item))
			context[SCREENTIP_CONTEXT_LMB] = "Rename"
			screentip_change = TRUE
		if(secure && card_reader_installed && !broken)
			if(!access_locked && istype(held_item) && !isnull(held_item.GetID()))
				context[SCREENTIP_CONTEXT_LMB] = "Change Access"
				screentip_change = TRUE
			if(istype(held_item) && istype(held_item) && held_item.tool_behaviour == TOOL_MULTITOOL)
				context[SCREENTIP_CONTEXT_LMB] = "[access_locked ? "Unlock" : "Lock"] Access Panel"
				screentip_change = TRUE

	return screentip_change ? CONTEXTUAL_SCREENTIP_SET : NONE

/obj/structure/closet/CanAllowThrough(atom/movable/mover, border_dir)
	. = ..()
	if(wall_mounted)
		return TRUE

/obj/structure/closet/proc/can_open(mob/living/user, force = FALSE)
	if(force)
		return TRUE
	if(welded || locked)
		return FALSE
	if(strong_grab)
		if(user)
			to_chat(user, span_danger("[pulledby] has an incredibly strong grip on [src], preventing it from opening."))
		return FALSE
	var/turf/T = get_turf(src)
	for(var/mob/living/L in T)
		if(L.anchored || horizontal && L.mob_size > MOB_SIZE_TINY && L.density)
			if(user)
				to_chat(user, span_danger("There's something large on top of [src], preventing it from opening."))
			return FALSE
	return TRUE

/obj/structure/closet/proc/can_close(mob/living/user)
	var/turf/T = get_turf(src)
	for(var/obj/structure/closet/closet in T)
		if(closet != src && !closet.wall_mounted)
			if(user)
				balloon_alert(user, "[closet.name] is in the way!")
			return FALSE
	for(var/mob/living/L in T)
		if(L.anchored || horizontal && L.mob_size > MOB_SIZE_TINY && L.density)
			if(user)
				to_chat(user, span_danger("There's something too large in [src], preventing it from closing."))
			return FALSE
	return TRUE

/obj/structure/closet/dump_contents()
	if (!contents_initialized)
		contents_initialized = TRUE
		PopulateContents()
		SEND_SIGNAL(src, COMSIG_CLOSET_CONTENTS_INITIALIZED)

	var/atom/L = drop_location()
	for(var/atom/movable/AM in src)
		AM.forceMove(L)
		if(throwing) // you keep some momentum when getting out of a thrown closet
			step(AM, dir)
	if(throwing)
		throwing.finalize(FALSE)

/obj/structure/closet/proc/take_contents(mapload = FALSE)
	var/atom/location = drop_location()
	if(!location)
		return
	for(var/atom/movable/AM in location)
		if(AM != src && insert(AM, mapload) == LOCKER_FULL) // limit reached
			if(mapload) // Yea, it's a mapping issue. Blame mappers.
				log_mapping("Closet storage capacity of [type] exceeded on mapload at [AREACOORD(src)]")
			break
	for(var/i in reverse_range(location.get_all_contents()))
		var/atom/movable/thing = i
		thing.atom_storage?.close_all()

///Proc to write checks before opening a door
/obj/structure/closet/proc/before_open(mob/living/user, force)
	return TRUE

/obj/structure/closet/proc/open(mob/living/user, force = FALSE, special_effects = TRUE)
	if(opened || !can_open(user, force))
		return FALSE
	if(!before_open(user, force) || (SEND_SIGNAL(src, COMSIG_CLOSET_PRE_OPEN, user, force) & BLOCK_OPEN))
		return FALSE
	welded = FALSE
	unlock()
	if(special_effects)
		playsound(loc, open_sound, open_sound_volume, TRUE, -3)
	opened = TRUE
	if(!dense_when_open)
		set_density(FALSE)
	dump_contents()
	if(special_effects)
		animate_door(FALSE)
	update_appearance()
	after_open(user, force)
	SEND_SIGNAL(src, COMSIG_CLOSET_POST_OPEN, user, force)
	return TRUE

///Proc to override for effects after opening a door
/obj/structure/closet/proc/after_open(mob/living/user, force = FALSE)
	return

/obj/structure/closet/proc/insert(atom/movable/inserted, mapload = FALSE)
	if(length(contents) >= storage_capacity)
		if(!mapload)
			return LOCKER_FULL
		//For maploading, we only return LOCKER_FULL if the movable was otherwise insertable. This way we can avoid logging false flags.
		return insertion_allowed(inserted) ? LOCKER_FULL : FALSE
	if(!insertion_allowed(inserted))
		return FALSE
	if(SEND_SIGNAL(src, COMSIG_CLOSET_INSERT, inserted) & COMPONENT_CLOSET_INSERT_INTERRUPT)
		return TRUE
	inserted.forceMove(src)
	return TRUE

/obj/structure/closet/proc/insertion_allowed(atom/movable/AM)
	if(ismob(AM))
		if(!isliving(AM)) //let's not put ghosts or eye mobs inside closets...
			return FALSE
		var/mob/living/L = AM
		if(L.anchored || L.buckled || L.incorporeal_move || L.has_buckled_mobs())
			return FALSE
		if(L.mob_size > MOB_SIZE_TINY) // Tiny mobs are treated as items.
			if(horizontal && L.density)
				return FALSE
			if(L.mob_size > max_mob_size)
				return FALSE
			var/mobs_stored = 0
			for(var/mob/living/M in contents)
				mobs_stored++
				if(mobs_stored >= mob_storage_capacity)
					return FALSE
		L.stop_pulling()

	else if(istype(AM, /obj/structure/closet))
		return FALSE
	else if(isobj(AM))
		if((!allow_dense && AM.density) || AM.anchored || AM.has_buckled_mobs() || ismecha(AM))
			return FALSE
		else if(isitem(AM) && !HAS_TRAIT(AM, TRAIT_NODROP))
			return TRUE
		else if(!allow_objects && !istype(AM, /obj/effect/dummy/chameleon))
			return FALSE
	else
		return FALSE

	return TRUE

///Proc to write checks before closing a door
/obj/structure/closet/proc/before_close(mob/living/user)
	return TRUE

/obj/structure/closet/proc/close(mob/living/user)
	if(!opened || !can_close(user))
		return FALSE
	if(!before_close(user) || (SEND_SIGNAL(src, COMSIG_CLOSET_PRE_CLOSE, user) & BLOCK_CLOSE))
		return FALSE
	take_contents()
	playsound(loc, close_sound, close_sound_volume, TRUE, -3)
	opened = FALSE
	set_density(TRUE)
	animate_door(TRUE)
	update_appearance()
	after_close(user)
	SEND_SIGNAL(src, COMSIG_CLOSET_POST_CLOSE, user)
	return TRUE

///Proc to do effects after closet has closed
/obj/structure/closet/proc/after_close(mob/living/user)
	return

/**
 * Toggles a closet open or closed, to the opposite state. Does not respect locked or welded states, however.
 */
/obj/structure/closet/proc/toggle(mob/living/user)
	if(opened)
		return close(user)
	else
		return open(user)

/obj/structure/closet/handle_deconstruct(disassembled)
	dump_contents()
	if(obj_flags & NO_DEBRIS_AFTER_DECONSTRUCTION)
		return

	if(ispath(material_drop) && material_drop_amount)
		new material_drop(loc, material_drop_amount)
	if (secure)
		var/obj/item/electronics/airlock/electronics = new(drop_location())
		if(length(req_one_access))
			electronics.one_access = TRUE
			electronics.accesses = req_one_access
		else
			electronics.accesses = req_access
	if(card_reader_installed)
		new /obj/item/stock_parts/card_reader(drop_location())

/obj/structure/closet/atom_break(damage_flag)
	. = ..()
	if(!broken)
		bust_open()

/obj/structure/closet/on_craft_completion(list/components, datum/crafting_recipe/current_recipe, atom/crafter)
	var/obj/item/electronics/airlock/access_control = locate() in components
	if(QDELETED(access_control))
		return ..()

	inherit_airlock_electronics_access(access_control)

	return ..()

/obj/structure/closet/proc/inherit_airlock_electronics_access(obj/item/electronics/airlock/access_control)
	if (access_control.one_access)
		req_one_access = access_control.accesses
		req_access = null
	else
		req_access = access_control.accesses
		req_one_access = null

/obj/structure/closet/multitool_act(mob/living/user, obj/item/tool)
	if(!secure || !card_reader_installed || broken || locked || opened)
		return
	access_locked = !access_locked
	balloon_alert(user, "access panel [access_locked ? "locked" : "unlocked"]")
	return TRUE

/// sets the access for the closets from the swiped ID card
/obj/structure/closet/proc/set_access(list/accesses)
	if(length(req_one_access))
		req_one_access = accesses
		req_access = null
	else
		req_access = accesses
		req_one_access = null

/obj/structure/closet/attackby(obj/item/W, mob/user, params)
	if(user in src)
		return
	if(src.tool_interact(W,user))
		return 1 // No afterattack
	else
		return ..()

/// check if we can install airlock electronics in this closet
/obj/structure/closet/proc/can_install_airlock_electronics(mob/user)
	if(secure || !can_install_electronics || opened)
		return FALSE

	if(broken)
		balloon_alert(user, "its broken!")
		return FALSE

	if(locked)
		balloon_alert(user, "unlock first!")
		return FALSE

	return TRUE

/// check if we can unscrew airlock electronics from this closet
/obj/structure/closet/proc/can_unscrew_airlock_electronics(mob/user)
	if(!secure || opened)
		return FALSE
	if(card_reader_installed)
		balloon_alert(user, "attached to reader!")
		return FALSE
	if(locked)
		balloon_alert(user, "unlock first!")
		return FALSE

	return TRUE

/// check if we can install card reader in this closet
/obj/structure/closet/proc/can_install_card_reader(mob/user)
	if(card_reader_installed || !can_install_electronics || !length(access_choices) || opened)
		return FALSE

	if(broken)
		balloon_alert(user, "its broken!")
		return FALSE

	if(!secure)
		balloon_alert(user, "no electronics inside!")
		return FALSE

	if(locked)
		balloon_alert(user, "unlock first!")
		return FALSE

	return TRUE

/// check if we can pry out the card reader from this closet
/obj/structure/closet/proc/can_pryout_card_reader(mob/user)
	if(!card_reader_installed || opened)
		return FALSE

	if(locked)
		balloon_alert(user, "unlock first!")
		return FALSE

	return TRUE

/// returns TRUE if attackBy call shouldn't be continued (because tool was used/closet was of wrong type), FALSE if otherwise
/obj/structure/closet/proc/tool_interact(obj/item/weapon, mob/living/user)
	. = TRUE
	var/obj/item/card/id/id = null
	if(!opened && istype(weapon, /obj/item/airlock_painter))
		if(!length(paint_jobs))
			return
		var/choice = tgui_input_list(user, "Set Closet Paintjob", "Paintjob", paint_jobs)
		if(isnull(choice))
			return

		var/obj/item/airlock_painter/painter = weapon
		if(!painter.use_paint(user))
			return
		var/list/paint_job = paint_jobs[choice]
		icon_state = paint_job["icon_state"]
		base_icon_state = icon_state
		icon_door = paint_job["icon_door"]

		update_appearance()

	else if(istype(weapon, /obj/item/electronics/airlock) && can_install_airlock_electronics(user))
		user.visible_message(span_notice("[user] installs the electronics into the [src]."),\
			span_notice("You start to install electronics into the [src]..."))

		if(!do_after(user, 4 SECONDS, target = src, extra_checks = CALLBACK(src, PROC_REF(can_install_airlock_electronics), user)))
			return
		if(!user.transferItemToLoc(weapon, src))
			return

		inherit_airlock_electronics_access(weapon)
		qdel(weapon)
		secure = TRUE
		balloon_alert(user, "electronics installed")

		update_appearance()

	else if(weapon.tool_behaviour == TOOL_SCREWDRIVER && can_unscrew_airlock_electronics(user))
		user.visible_message(span_notice("[user] begins to remove the electronics from the [src]."),\
			span_notice("You begin to remove the electronics from the [src]..."))

		if (!weapon.use_tool(src, user, 40, volume = 50, extra_checks = CALLBACK(src, PROC_REF(can_unscrew_airlock_electronics), user)))
			return

		var/obj/item/electronics/airlock/airlock_electronics = new(drop_location())
		if(length(req_one_access))
			airlock_electronics.one_access = TRUE
			airlock_electronics.accesses = req_one_access
		else
			airlock_electronics.accesses = req_access

		req_access = list()
		req_one_access = null
		id_card = null
		secure = FALSE
		balloon_alert(user, "electronics removed")

		update_appearance()

	else if(istype(weapon, /obj/item/stock_parts/card_reader) && can_install_card_reader(user))
		user.visible_message(span_notice("[user] is installing a card reader."),
					span_notice("You begin installing the card reader."))

		if(!do_after(user, 4 SECONDS, target = src, extra_checks = CALLBACK(src, PROC_REF(can_install_card_reader), user)))
			return

		qdel(weapon)
		card_reader_installed = TRUE

		balloon_alert(user, "card reader installed")

	else if(weapon.tool_behaviour == TOOL_CROWBAR && can_pryout_card_reader(user))
		user.visible_message(span_notice("[user] begins to pry the card reader out from [src]."),\
			span_notice("You begin to pry the card reader out from [src]..."))

		if(!weapon.use_tool(src, user, 4 SECONDS, extra_checks = CALLBACK(src, PROC_REF(can_pryout_card_reader), user)))
			return

		new /obj/item/stock_parts/card_reader(drop_location())
		card_reader_installed = FALSE

		balloon_alert(user, "card reader removed")

	else if(secure && !broken && card_reader_installed && !locked && !opened && !access_locked && !isnull((id = weapon.GetID())))
		var/num_choices = length(access_choices)
		if(!num_choices)
			return

		var/choice
		if(num_choices == 1)
			choice = access_choices[1]
		else
			choice = tgui_input_list(user, "Set Access Type", "Access Type", access_choices)
		if(isnull(choice))
			return

		id_card = null
		switch(choice)
			if("Personal") //only the player who swiped their id has access.
				id_card = WEAKREF(id)
				name = "[id.registered_name]'s locker"
				desc += " It has been ID locked to [id.registered_name]."
			if("Job") //anyone who has the same access permissions as this id has access. Does NOT apply to the whole department.
				name = "[id.assignment]'s locker"
				desc += " It has been access locked to [id.assignment]s."
				set_access(id.GetAccess())
			if("None") //free for all
				name = initial(name)
				desc = initial(desc)
				req_access = list()
				req_one_access = null
				set_access(list())

		if(!isnull(id_card))
			balloon_alert(user, "now owned by [id.registered_name]")
		else
			balloon_alert(user, "set to [choice]")

	else if(!opened && IS_WRITING_UTENSIL(weapon))
		if(locked)
			balloon_alert(user, "unlock first!")
			return

		if(isnull(id_card) && secure)
			balloon_alert(user, "not yours to rename!")
			return

		var/name_set = FALSE
		var/desc_set = FALSE


		var/input_name = tgui_input_text(user, "Locker Name", "Locker Name", max_length = MAX_NAME_LEN)

		if(!isnull(input_name))
			name = input_name
			name_set = TRUE

		var/input_desc = tgui_input_text(user, "Locker Description", "Locker Description", max_length = MAX_DESC_LEN)

		if(!isnull(input_desc))
			desc = input_desc
			desc_set = TRUE

		var/bit_flag = NONE
		if(name_set)
			bit_flag |= UPDATE_NAME
		if(desc_set)
			bit_flag |= UPDATE_DESC
		if(bit_flag)
			update_appearance(bit_flag)

	else if(opened)
		if(istype(weapon, cutting_tool))
			if(weapon.tool_behaviour == TOOL_WELDER)
				if(!weapon.tool_start_check(user, amount=1))
					return

				to_chat(user, span_notice("You begin cutting \the [src] apart..."))
				if(weapon.use_tool(src, user, 40, volume=50))
					if(!opened)
						return
					user.visible_message(span_notice("[user] slices apart \the [src]."),
									span_notice("You cut \the [src] apart with \the [weapon]."),
									span_hear("You hear welding."))
					deconstruct(TRUE)
				return
			else // for example cardboard box is cut with wirecutters
				user.visible_message(span_notice("[user] cut apart \the [src]."), \
									span_notice("You cut \the [src] apart with \the [weapon]."))
				deconstruct(TRUE)
				return
		if (user.combat_mode)
			return
		if(user.transferItemToLoc(weapon, drop_location())) // so we put in unlit welder too
			return

	else if(weapon.tool_behaviour == TOOL_WELDER && can_weld_shut)
		if(!weapon.tool_start_check(user, amount=1))
			return

		if(weapon.use_tool(src, user, 40, volume=50))
			if(opened)
				return
			welded = !welded
			after_weld(welded)
			user.visible_message(span_notice("[user] [welded ? "welds shut" : "unwelded"] \the [src]."),
							span_notice("You [welded ? "weld" : "unwelded"] \the [src] with \the [weapon]."),
							span_hear("You hear welding."))
			user.log_message("[welded ? "welded":"unwelded"] closet [src] with [weapon]", LOG_GAME)
			update_appearance()

	else if(!user.combat_mode || (weapon.item_flags & NOBLUDGEON))
		var/item_is_id = weapon.GetID()
		if(!item_is_id)
			return FALSE
		if((item_is_id || !toggle(user)) && !opened)
			togglelock(user)
	else
		return FALSE

/obj/structure/closet/wrench_act_secondary(mob/living/user, obj/item/tool)
	if(!anchorable)
		balloon_alert(user, "no anchor bolts!")
		return TRUE
	if(isinspace() && !anchored) // We want to prevent anchoring a locker in space, but we should still be able to unanchor it there
		balloon_alert(user, "nothing to anchor to!")
		return TRUE
	set_anchored(!anchored)
	tool.play_tool_sound(src, 75)
	user.balloon_alert_to_viewers("[anchored ? "anchored" : "unanchored"]")
	return TRUE

/obj/structure/closet/proc/after_weld(weld_state)
	return

/obj/structure/closet/mouse_drop_receive(atom/movable/O, mob/living/user, params)
	if(!istype(O) || O.anchored || istype(O, /atom/movable/screen))
		return
	if(user == O) //try to climb onto it
		return ..()
	if(!opened)
		return
	if(!isturf(O.loc))
		return

	var/actuallyismob = 0
	if(isliving(O))
		actuallyismob = 1
	else if(!isitem(O))
		return
	var/turf/T = get_turf(src)
	add_fingerprint(user)
	user.visible_message(span_warning("[user] [actuallyismob ? "tries to ":""]stuff [O] into [src]."), \
		span_warning("You [actuallyismob ? "try to ":""]stuff [O] into [src]."), \
		span_hear("You hear clanging."))
	if(actuallyismob)
		if(do_after(user, 4 SECONDS, O))
			user.visible_message(span_notice("[user] stuffs [O] into [src]."), \
				span_notice("You stuff [O] into [src]."), \
				span_hear("You hear a loud metal bang."))
			var/mob/living/L = O
			if(!issilicon(L))
				L.Paralyze(40)
			if(istype(src, /obj/structure/closet/supplypod/extractionpod))
				O.forceMove(src)
			else
				O.forceMove(T)
				close()
			log_combat(user, O, "stuffed", addition = "inside of [src]")
	else
		O.forceMove(T)

/obj/structure/closet/relaymove(mob/living/user, direction)
	if(user.stat || !isturf(loc))
		return
	if(locked)
		if(message_cooldown <= world.time)
			message_cooldown = world.time + 50
			to_chat(user, span_warning("[src]'s door won't budge!"))
		return
	container_resist_act(user)


/obj/structure/closet/attack_hand(mob/living/user, list/modifiers)
	. = ..()
	if(.)
		return
	if(user.body_position == LYING_DOWN && get_dist(src, user) > 0)
		return

	if(toggle(user))
		return

	if(!opened)
		togglelock(user)

/obj/structure/closet/attack_paw(mob/user, list/modifiers)
	return attack_hand(user, modifiers)

/obj/structure/closet/attack_robot(mob/user)
	if(user.Adjacent(src))
		return attack_hand(user)

/obj/structure/closet/attack_robot_secondary(mob/user, list/modifiers)
	if(!user.Adjacent(src))
		return SECONDARY_ATTACK_CONTINUE_CHAIN
	togglelock(user)
	return SECONDARY_ATTACK_CANCEL_ATTACK_CHAIN

// tk grab then use on self
/obj/structure/closet/attack_self_tk(mob/user)
	if(attack_hand(user))
		return ITEM_INTERACT_BLOCKING

/obj/structure/closet/verb/verb_toggleopen()
	set src in view(1)
	set category = "Object"
	set name = "Toggle Open"

	if(!usr.can_perform_action(src) || !isturf(loc))
		return

	if(iscarbon(usr) || issilicon(usr) || isdrone(usr))
		return toggle(usr)
	else
		to_chat(usr, span_warning("This mob type can't use this verb."))

// Objects that try to exit a locker by stepping were doing so successfully,
// and due to an oversight in turf/Enter() were going through walls.  That
// should be independently resolved, but this is also an interesting twist.
/obj/structure/closet/Exit(atom/movable/leaving, direction)
	open()
	if(leaving.loc == src)
		return FALSE
	return TRUE

/obj/structure/closet/container_resist_act(mob/living/user, loc_required = TRUE)
	if(isstructure(loc))
		relay_container_resist_act(user, loc)
	if(opened)
		return
	if(ismovable(loc))
		user.changeNext_move(CLICK_CD_BREAKOUT)
		user.last_special = world.time + CLICK_CD_BREAKOUT
		var/atom/movable/AM = loc
		AM.relay_container_resist_act(user, src)
		return
	if(!welded && !locked)
		open()
		return

	if(DOING_INTERACTION_WITH_TARGET(user, src))
		return
	//okay, so the closet is either welded or locked... resist!!!
	user.changeNext_move(CLICK_CD_BREAKOUT)
	user.last_special = world.time + CLICK_CD_BREAKOUT
	user.visible_message(span_warning("[src] begins to shake violently!"), \
		span_notice("You lean on the back of [src] and start pushing the door open... (this will take about [DisplayTimeText(breakout_time)].)"), \
		span_hear("You hear banging from [src]."))

	addtimer(CALLBACK(src, PROC_REF(check_if_shake)), 1 SECONDS)

	if(do_after(user,(breakout_time), target = src))
		if(!user || user.stat != CONSCIOUS || (loc_required && (user.loc != src)) || opened || (!locked && !welded) )
			return
		//we check after a while whether there is a point of resisting anymore and whether the user is capable of resisting
		user.visible_message(span_danger("[user] successfully broke out of [src]!"),
							span_notice("You successfully break out of [src]!"))
		bust_open()
	else
		if(user.loc == src) //so we don't get the message if we resisted multiple times and succeeded.
			to_chat(user, span_warning("You fail to break out of [src]!"))

/obj/structure/closet/relay_container_resist_act(mob/living/user, obj/container)
	container.container_resist_act(user)

/// Check if someone is still resisting inside, and choose to either keep shaking or stop shaking the closet
/obj/structure/closet/proc/check_if_shake()
	// Assuming we decide to shake again, how long until we check to shake again
	var/next_check_time = 1 SECONDS

	// How long we shake between different calls of Shake(), so that it starts shaking and stops, instead of a steady shake
	var/shake_duration =  0.3 SECONDS

	for(var/mob/living/mob in contents)
		if(DOING_INTERACTION_WITH_TARGET(mob, src))
			// Shake and queue another check_if_shake
			Shake(x_shake_pixel_shift, y_shake_pixel_shift, shake_duration, shake_interval = 0.1 SECONDS)
			addtimer(CALLBACK(src, PROC_REF(check_if_shake)), next_check_time)
			return TRUE

	// If we reach here, nobody is resisting, so don't shake
	return FALSE

/obj/structure/closet/proc/bust_open()
	SIGNAL_HANDLER
	welded = FALSE //applies to all lockers
	unlock() //applies to critter crates and secure lockers only
	broken = TRUE //applies to secure lockers only
	open(force = TRUE, special_effects = FALSE)

/obj/structure/closet/attack_hand_secondary(mob/user, modifiers)
	. = ..()

	if(!user.can_perform_action(src) || !isturf(loc))
		return

	if(!opened && secure)
		togglelock(user)
		return SECONDARY_ATTACK_CANCEL_ATTACK_CHAIN

/**
 * returns TRUE if the closet is allowed to unlock
 * * user: the player trying to unlock this closet
 * * player_id: the id of the player trying to unlock this closet
 * * registered_id: the id registered to this closet, null if no one registered
 */
/obj/structure/closet/proc/can_unlock(mob/living/user, obj/item/card/id/player_id, obj/item/card/id/registered_id)
	if(isnull(registered_id))
		return allowed(user)
	return player_id == registered_id

/obj/structure/closet/proc/togglelock(mob/living/user, silent)
	if(!secure || broken)
		return

	if(locked) //only apply checks while unlocking else allow anyone to lock it
		var/error_msg = ""
		if(!isnull(id_card))
			var/obj/item/card/id/registered_id = id_card.resolve()
			if(!registered_id) //id was deleted at some point. make this closet public access again
				name = initial(name)
				desc = initial(desc)
				id_card = null
				req_access = list()
				req_one_access = null
				togglelock(user, silent)
				return
			if(!can_unlock(user, user.get_idcard(), registered_id))
				error_msg = "not your locker!"
		else if(!can_unlock(user, user.get_idcard()))
			error_msg = "access denied!"
		if(error_msg)
			if(!silent)
				balloon_alert(user, error_msg)
			return

	if(iscarbon(user))
		add_fingerprint(user)
	locked = !locked
	play_closet_lock_sound()
	user.visible_message(
		span_notice("[user] [locked ? "locks" : "unlocks"] [src]."),
		span_notice("You [locked ? "locked" : "unlocked"] [src]."),
	)
	update_appearance()

/// toggles the lock state of a closet
/obj/structure/closet/proc/lock()
	if(locked)
		return
	locked = TRUE
	play_closet_lock_sound()
	update_appearance()

/// unlocks the closet
/obj/structure/closet/proc/unlock()
	if(!locked)
		return
	locked = FALSE
	play_closet_lock_sound()
	update_appearance()

/// plays the closet's lock/unlock sound, this should be placed AFTER you've changed the lock state
/obj/structure/closet/proc/play_closet_lock_sound()
	playsound(src, locked ? lock_sound : unlock_sound, 50, TRUE)

/obj/structure/closet/emag_act(mob/user, obj/item/card/emag/emag_card)
	if(secure && !broken)
		visible_message(span_warning("Sparks fly from [src]!"), blind_message = span_hear("You hear a faint electrical spark."))
		balloon_alert(user, "lock broken open")
		playsound(src, SFX_SPARKS, 50, TRUE, SHORT_RANGE_SOUND_EXTRARANGE)
		broken = TRUE
		locked = FALSE
		update_appearance()
		return TRUE
	return FALSE

/obj/structure/closet/get_remote_view_fullscreens(mob/user)
	if(user.stat == DEAD || !(user.sight & (SEEOBJS|SEEMOBS)))
		user.overlay_fullscreen("remote_view", /atom/movable/screen/fullscreen/impaired, 1)

/obj/structure/closet/emp_act(severity)
	. = ..()
	if(. & EMP_PROTECT_SELF)
		return
	if (!(. & EMP_PROTECT_CONTENTS))
		for(var/obj/O in src)
			O.emp_act(severity)
	if(secure && !broken && !(. & EMP_PROTECT_SELF))
		if(prob(50 / severity))
			locked = !locked
			update_appearance()
		if(prob(20 / severity) && !opened)
			if(!locked)
				open()
			else
				req_access = list()
				req_access += pick(SSid_access.get_region_access_list(list(REGION_ALL_STATION)))

/obj/structure/closet/contents_explosion(severity, target)
	switch(severity)
		if(EXPLODE_DEVASTATE)
			SSexplosions.high_mov_atom += contents
		if(EXPLODE_HEAVY)
			SSexplosions.med_mov_atom += contents
		if(EXPLODE_LIGHT)
			SSexplosions.low_mov_atom += contents

/obj/structure/closet/singularity_act()
	dump_contents()
	..()

/obj/structure/closet/AllowDrop()
	return TRUE

/obj/structure/closet/return_temperature()
	return

/obj/structure/closet/proc/locker_living(datum/source, mob/living/shover, mob/living/target, shove_flags, obj/item/weapon)
	SIGNAL_HANDLER
	if(!opened && (locked || welded)) //Yes this could be less code, no I don't care
		return
	if(!opened && ((shove_flags & SHOVE_KNOCKDOWN_BLOCKED) || !(shove_flags & SHOVE_BLOCKED)))
		return
	if (!toggle())
		return
	if(!opened) // Reversed because we should've toggled already
		if (target.loc != loc)
			return
		target.forceMove(src)
	else
		target.Knockdown(SHOVE_KNOCKDOWN_SOLID)
	update_icon()
	target.visible_message(span_danger("[shover.name] shoves [target.name] into [src]!"),
		span_userdanger("You're shoved into [src] by [shover.name]!"),
		span_hear("You hear aggressive shuffling followed by a loud thud!"), COMBAT_MESSAGE_RANGE, shover)
	to_chat(src, span_danger("You shove [target.name] into [src]!"))
	log_combat(shover, target, "shoved", "into [src] (locker/crate)[weapon ? " with [weapon]" : ""]")
	return COMSIG_LIVING_SHOVE_HANDLED

/// Signal proc for [COMSIG_ATOM_MAGICALLY_UNLOCKED]. Unlock and open up when we get knock casted.
/obj/structure/closet/proc/on_magic_unlock(datum/source, datum/action/cooldown/spell/aoe/knock/spell, atom/caster)
	SIGNAL_HANDLER

	INVOKE_ASYNC(src, PROC_REF(unlock))
	INVOKE_ASYNC(src, PROC_REF(open))

/obj/structure/closet/preopen
	opened = TRUE

///Adds the closet to a global list. Placed in its own proc so that crates may be excluded.
/obj/structure/closet/proc/add_to_roundstart_list()
	GLOB.roundstart_station_closets += src

///Spears deal bonus damages to lockers
/obj/structure/closet/attacked_by(obj/item/attacking_item, mob/living/user)
	if(istype(attacking_item, /obj/item/spear))
		take_damage(attacking_item.force * 2, attacking_item.damtype, MELEE, 1, get_dir(src, user))
		user.visible_message(span_danger("[user] stabs with precision [src]'s electronics with [attacking_item]!"),
		span_danger("You stab with precision [src]'s electronics with [attacking_item]!"), null, COMBAT_MESSAGE_RANGE)
		log_combat(user, src, "attacked", attacking_item)
		return
	return ..()

#undef LOCKER_FULL
