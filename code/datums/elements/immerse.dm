/// A list of movables that shouldn't be affected by the element, either because it'd look bad or barely perceptible
GLOBAL_LIST_INIT(immerse_ignored_movable, typecacheof(list(
	/obj/effect,
	/mob/dead,
	/obj/projectile,
)))

/**
 * A visual element that makes movables entering the attached turfs look immersed into that turf.
 *
 * Abandon all hope, ye who read forth, for this immerse works on mind-numbing workarounds,
 */
/datum/element/immerse
	element_flags = ELEMENT_DETACH_ON_HOST_DESTROY | ELEMENT_BESPOKE
	argument_hash_start_idx = 2
	///An association list of turfs that have this element attached and their affected contents.
	var/list/attached_turfs_and_movables = list()

	///A list of icons generated from a target and a mask, later used as appearances for the overlays.
	var/static/list/generated_immerse_icons = list()
	///A list of instances of /atom/movable/immerse_overlay then used as visual overlays for the immersed movables.
	var/list/generated_visual_overlays = list()
	///An association list of movables as key and overlays as assoc.
	var/list/immersed_movables

	var/icon
	var/icon_state
	var/mask_icon
	var/color
	var/alpha

/datum/element/immerse/Attach(turf/target, icon, icon_state, mask_icon, color = "#777777", alpha = 180)
	. = ..()
	if(!isturf(target) || !icon || !icon_state || !mask_icon)
		return ELEMENT_INCOMPATIBLE

	src.icon = icon
	src.icon_state = icon_state
	src.color = color
	src.alpha = alpha
	src.mask_icon = mask_icon

	/**
	 * Hello, you may be wondering why we're blending icons and not simply
	 * overlaying one mutable appearance with the blend multiply on another.
	 * Well, the latter option doesn't work as neatly when added
	 * to an atom with the KEEP_TOGETHER appearance flag, with the mask icon also
	 * showing on said atom, while we don't want it to.
	 *
	 * Also using KEEP_APART isn't an option, because unless it's drawn as one with
	 * its visual loation, the whole plane the atom belongs to will count as part of the
	 * mask of the final visual overlay since that's how the BLEND_INSET_OVERLAY blend mode works here.
	 * In layman terms, with KEEP_APART on, if a flying monkey gets nears an immersed
	 * human, the visual overlay will appear on the flying monkey even if it shouldn't.
	 */
	var/icon/immerse_icon = generated_immerse_icons["[icon]-[icon_state]-[mask_icon]"]
	if(!immerse_icon)
		immerse_icon = icon(icon, icon_state)
		var/icon/sub_mask = icon('icons/effects/effects.dmi', mask_icon)
		immerse_icon.Blend(sub_mask, ICON_MULTIPLY)
		immerse_icon = fcopy_rsc(immerse_icon)
		generated_immerse_icons["[icon]-[icon_state]-[mask_icon]"] = immerse_icon

	RegisterSignal(target, SIGNAL_ADDTRAIT(TRAIT_IMMERSE_STOPPED), PROC_REF(stop_immersion))
	RegisterSignal(target, SIGNAL_REMOVETRAIT(TRAIT_IMMERSE_STOPPED), PROC_REF(start_immersion))

	if(!HAS_TRAIT(target, TRAIT_IMMERSE_STOPPED))
		start_immersion(target)

/datum/element/immerse/Detach(turf/source)
	UnregisterSignal(source, list(SIGNAL_ADDTRAIT(TRAIT_IMMERSE_STOPPED), SIGNAL_REMOVETRAIT(TRAIT_IMMERSE_STOPPED)))
	if(!HAS_TRAIT(source, TRAIT_IMMERSE_STOPPED))
		stop_immersion(source)
	return ..()

///Makes the element start affecting the turf and its contents. Called on Attach() or when TRAIT_IMMERSE_STOPPED is removed.
/datum/element/immerse/proc/start_immersion(turf/source)
	SIGNAL_HANDLER
	RegisterSignals(source, list(COMSIG_ATOM_ABSTRACT_ENTERED, COMSIG_ATOM_AFTER_SUCCESSFUL_INITIALIZED_ON), PROC_REF(on_init_or_entered))
	RegisterSignal(source, COMSIG_ATOM_ABSTRACT_EXITED, PROC_REF(on_atom_exited))
	attached_turfs_and_movables += source
	for(var/atom/movable/movable as anything in source)
		if(!(movable.flags_1 & INITIALIZED_1))
			continue
		on_init_or_entered(source, movable)

///Stops the element from affecting on the turf and its contents. Called on Detach() or when TRAIT_IMMERSE_STOPPED is added.
/datum/element/immerse/proc/stop_immersion(turf/source)
	SIGNAL_HANDLER
	UnregisterSignal(source, list(COMSIG_ATOM_ABSTRACT_ENTERED, COMSIG_ATOM_AFTER_SUCCESSFUL_INITIALIZED_ON, COMSIG_ATOM_ABSTRACT_EXITED))
	for(var/atom/movable/movable as anything in attached_turfs_and_movables[source])
		remove_from_element(source, movable)
	attached_turfs_and_movables -= source

/**
 * If the movable is within the right layers and planes, not in the list of movable types to ignore,
 * or already affected by the element for that matter, Signals will be registered and,
 * unless the movable (or whatever it's buckled to) is flying, it'll appear as if immersed in that water.
 */
/datum/element/immerse/proc/on_init_or_entered(turf/source, atom/movable/movable)
	SIGNAL_HANDLER
	if(QDELETED(movable))
		return
	if(HAS_TRAIT(movable, TRAIT_IMMERSED) || HAS_TRAIT(movable, TRAIT_WALLMOUNTED))
		return
	if(!ISINRANGE(movable.plane, MUTATE_PLANE(FLOOR_PLANE, source), MUTATE_PLANE(GAME_PLANE, source)))
		return
	var/layer_to_check = IS_TOPDOWN_PLANE(source.plane) ? TOPDOWN_ABOVE_WATER_LAYER : ABOVE_ALL_MOB_LAYER
	//First, floor plane objects use TOPDOWN_LAYER, second this check shouldn't apply to them anyway.
	if(movable.layer >= layer_to_check)
		return
	if(is_type_in_typecache(movable, GLOB.immerse_ignored_movable))
		return

	var/atom/movable/buckled
	if(isliving(movable))
		var/mob/living/living_mob = movable
		RegisterSignal(living_mob, COMSIG_LIVING_SET_BUCKLED, PROC_REF(on_set_buckled))
		buckled = living_mob.buckled

	try_immerse(movable, buckled)
	RegisterSignal(movable, COMSIG_QDELETING, PROC_REF(on_movable_qdel))
	LAZYADD(attached_turfs_and_movables[source], movable)
	ADD_TRAIT(movable, TRAIT_IMMERSED, ELEMENT_TRAIT(src))

/datum/element/immerse/proc/on_movable_qdel(atom/movable/source)
	SIGNAL_HANDLER
	remove_from_element(source.loc, source)

/**
 * The main proc, which adds a visual overlay to the movable that has entered the turf to make it look immersed.
 * It's kind of iffy but basically, we want the overlay to cover as much area as needed to
 * avoid the movable's icon from spilling horizontally or below.
 * Also, while these visual overlays are mainly cached movables, for certain movables, such as living mobs,
 * we want them to have their own unique vis overlay with additional signals registered.
 * This allows the vis overlay to look more or less unchanged while its owner is spinning or resting
 * without otherwise affecting other movables with identical overlays.
 */
/datum/element/immerse/proc/add_immerse_overlay(atom/movable/movable)
	var/list/icon_dimensions = get_icon_dimensions(movable.icon)
	var/width = icon_dimensions["width"] || ICON_SIZE_X
	var/height = icon_dimensions["height"] || ICON_SIZE_Y

	///This determines if the overlay should cover the entire surface of the object or not
	var/layer_to_check = IS_TOPDOWN_PLANE(movable.plane) ? TOPDOWN_WATER_LEVEL_LAYER : WATER_LEVEL_LAYER
	var/is_below_water = (movable.layer < layer_to_check) ? "underwater-" : ""

	var/atom/movable/immerse_overlay/vis_overlay = generated_visual_overlays["[is_below_water][width]x[height]"]

	if(!vis_overlay) //create the overlay if not already done.
		vis_overlay = generate_vis_overlay(width, height, is_below_water)


	ADD_KEEP_TOGETHER(movable, ELEMENT_TRAIT(src))

	/**
	 * Let's give an unique immerse visual only to those movables that would
	 * benefit from this the most, for the sake of a smidge of lightweightness.
	 */
	if(HAS_TRAIT(movable, TRAIT_UNIQUE_IMMERSE))
		var/atom/movable/immerse_overlay/original_vis_overlay = vis_overlay
		vis_overlay = new(null)
		vis_overlay.appearance = original_vis_overlay
		vis_overlay.extra_width = original_vis_overlay.extra_width
		vis_overlay.extra_height = original_vis_overlay.extra_height
		vis_overlay.overlay_appearance = original_vis_overlay.overlay_appearance
		SEND_SIGNAL(movable, COMSIG_MOVABLE_EDIT_UNIQUE_IMMERSE_OVERLAY, vis_overlay)
		RegisterSignal(movable, COMSIG_ATOM_SPIN_ANIMATION, PROC_REF(on_spin_animation))
		RegisterSignal(movable, COMSIG_LIVING_POST_UPDATE_TRANSFORM, PROC_REF(on_update_transform))

	movable.vis_contents |= vis_overlay

	LAZYSET(immersed_movables, movable, vis_overlay)

///Initializes and caches a new visual overlay given parameters such as width, height and whether it should appear fully underwater.
/datum/element/immerse/proc/generate_vis_overlay(width, height, is_below_water)

	var/atom/movable/immerse_overlay/vis_overlay = new(null, src)

	/**
	 * vis contents spin around the center of the icon of their vis locs
	 * but since we want the appearance to stay where it should be,
	 * we have to counteract this one.
	 */
	var/extra_width = (width - ICON_SIZE_X) * 0.5
	var/extra_height = (height - ICON_SIZE_Y) * 0.5
	var/mutable_appearance/overlay_appearance = new()
	var/icon/immerse_icon = generated_immerse_icons["[icon]-[icon_state]-[mask_icon]"]
	var/last_i = width/ICON_SIZE_X
	for(var/i in -1 to last_i)
		var/mutable_appearance/underwater = mutable_appearance(icon, icon_state)
		underwater.pixel_x = ICON_SIZE_X * i - extra_width
		underwater.pixel_y = -ICON_SIZE_Y - extra_height
		overlay_appearance.overlays += underwater

		var/mutable_appearance/water_level = is_below_water ? underwater : mutable_appearance(immerse_icon)
		water_level.pixel_x = ICON_SIZE_X * i - extra_width
		water_level.pixel_y = -extra_height
		overlay_appearance.overlays += water_level


	vis_overlay.color = color
	vis_overlay.alpha = alpha
	vis_overlay.overlays = list(overlay_appearance)

	vis_overlay.extra_width = extra_width
	vis_overlay.extra_height = extra_height
	vis_overlay.overlay_appearance = overlay_appearance

	generated_visual_overlays["[is_below_water][width]x[height]"] = vis_overlay
	return vis_overlay

///This proc removes the vis_overlay, the keep together trait and some signals from the movable.
/datum/element/immerse/proc/remove_immerse_overlay(atom/movable/movable)
	var/atom/movable/immerse_overlay/vis_overlay = LAZYACCESS(immersed_movables, movable)
	LAZYREMOVE(immersed_movables, movable)
	REMOVE_KEEP_TOGETHER(movable, ELEMENT_TRAIT(src))
	movable.vis_contents -= vis_overlay
	if(HAS_TRAIT(movable, TRAIT_UNIQUE_IMMERSE))
		UnregisterSignal(movable, list(COMSIG_ATOM_SPIN_ANIMATION, COMSIG_LIVING_POST_UPDATE_TRANSFORM, COMSIG_QDELETING))
		if(!QDELETED(vis_overlay))
			qdel(vis_overlay)
/**
 * Called by init_or_entered() and on_set_buckled().
 * This applies the overlay if neither the movable or whatever is buckled to (exclusive to living mobs) are flying
 * as well as movetype signals when the movable isn't buckled.
 */
/datum/element/immerse/proc/try_immerse(atom/movable/movable, atom/movable/buckled)
	var/atom/movable/to_check = buckled || movable
	if(!(to_check.movement_type & MOVETYPES_NOT_TOUCHING_GROUND) && !movable.throwing)
		add_immerse_overlay(movable)
	if(!buckled)
		RegisterSignal(movable, COMSIG_MOVETYPE_FLAG_ENABLED, PROC_REF(on_move_flag_enabled))
		RegisterSignal(movable, COMSIG_MOVETYPE_FLAG_DISABLED, PROC_REF(on_move_flag_disabled))
		RegisterSignal(movable, COMSIG_MOVABLE_POST_THROW, PROC_REF(on_throw))
		RegisterSignal(movable, COMSIG_MOVABLE_THROW_LANDED, PROC_REF(on_throw_landed))

/**
 * Called by on_set_buckled() and remove_from_element().
 * This removes the filter and signals from the movable unless it doesn't have them.
 */
/datum/element/immerse/proc/try_unimmerse(atom/movable/movable, atom/movable/buckled)
	var/atom/movable/to_check = buckled || movable
	if(!(to_check.movement_type & MOVETYPES_NOT_TOUCHING_GROUND) && !movable.throwing)
		remove_immerse_overlay(movable)
	if(!buckled)
		UnregisterSignal(movable, list(COMSIG_MOVETYPE_FLAG_ENABLED, COMSIG_MOVETYPE_FLAG_DISABLED, COMSIG_MOVABLE_POST_THROW, COMSIG_MOVABLE_THROW_LANDED))

/datum/element/immerse/proc/on_set_buckled(mob/living/source, atom/movable/new_buckled)
	SIGNAL_HANDLER
	try_unimmerse(source, source.buckled)
	try_immerse(source, new_buckled)

///Removes the overlay from mob and bucklees is flying.
/datum/element/immerse/proc/on_move_flag_enabled(atom/movable/source, flag, old_movement_type)
	SIGNAL_HANDLER
	if(!(flag & MOVETYPES_NOT_TOUCHING_GROUND) || (old_movement_type & MOVETYPES_NOT_TOUCHING_GROUND) || source.throwing)
		return
	remove_immerse_overlay(source)
	for(var/mob/living/buckled_mob as anything in source.buckled_mobs)
		remove_immerse_overlay(buckled_mob)

///Works just like on_move_flag_enabled, except it only has to check that movable isn't flying
/datum/element/immerse/proc/on_throw(atom/movable/source)
	SIGNAL_HANDLER
	if(source.movement_type & MOVETYPES_NOT_TOUCHING_GROUND)
		return
	remove_immerse_overlay(source)
	for(var/mob/living/buckled_mob as anything in source.buckled_mobs)
		remove_immerse_overlay(buckled_mob)

///Readds the overlay to the mob and bucklees if no longer flying.
/datum/element/immerse/proc/on_move_flag_disabled(atom/movable/source, flag, old_movement_type)
	SIGNAL_HANDLER
	if(!(flag & MOVETYPES_NOT_TOUCHING_GROUND) || (source.movement_type & MOVETYPES_NOT_TOUCHING_GROUND) || source.throwing)
		return
	add_immerse_overlay(source)
	for(var/mob/living/buckled_mob as anything in source.buckled_mobs)
		add_immerse_overlay(buckled_mob)

///Works just like on_move_flag_disabled, except it only has to check that movable isn't flying
/datum/element/immerse/proc/on_throw_landed(atom/movable/source)
	SIGNAL_HANDLER
	if(source.movement_type & MOVETYPES_NOT_TOUCHING_GROUND)
		return
	add_immerse_overlay(source)
	for(var/mob/living/buckled_mob as anything in source.buckled_mobs)
		add_immerse_overlay(buckled_mob)

/**
 * Called when a movable exits the turf. If its new location is not in the list of turfs with this element,
 * Remove the movable from the element.
 */
/datum/element/immerse/proc/on_atom_exited(turf/source, atom/movable/exited, direction)
	SIGNAL_HANDLER
	if(!(exited.loc in attached_turfs_and_movables))
		remove_from_element(source, exited)
	else
		LAZYREMOVE(attached_turfs_and_movables[source], exited)
		LAZYADD(attached_turfs_and_movables[exited.loc], exited)

///Remove any signal, overlay, trait given to the movable and reference to it within the element.
/datum/element/immerse/proc/remove_from_element(turf/source, atom/movable/movable)
	var/atom/movable/buckled
	if(isliving(movable))
		var/mob/living/living_mob = movable
		buckled = living_mob.buckled
	try_unimmerse(movable, buckled)

	LAZYREMOVE(attached_turfs_and_movables[source], movable)
	UnregisterSignal(movable, list(COMSIG_LIVING_SET_BUCKLED, COMSIG_QDELETING))
	REMOVE_TRAIT(movable, TRAIT_IMMERSED, ELEMENT_TRAIT(src))

/// A band-aid to keep the (unique) visual overlay from scaling and rotating along with its owner. I'm sorry.
/datum/element/immerse/proc/on_update_transform(mob/living/source, resize, new_lying_angle, is_opposite_angle)
	SIGNAL_HANDLER
	var/matrix/new_transform = matrix()
	new_transform.Scale(1/source.current_size)
	new_transform.Turn(-new_lying_angle)

	var/atom/movable/immerse_overlay/vis_overlay = immersed_movables[source]
	if(is_opposite_angle)
		vis_overlay.transform = new_transform
		vis_overlay.adjust_living_overlay_offset(source)
		return

	/**
	 * Here, we temporarily switch from the offset of the mutable appearance to one for movable used as visual overlay.
	 * Why? While visual overlays can be animated, their fixed point stays at the center of the icon of the atom
	 * they're attached to and not theirs, which can make manipulating the transform var a pain, but because
	 * we cannot do that with normal overlay or filters (reliably), we have to bend a knee and try to compensate it.
	 */
	vis_overlay.overlays = list(vis_overlay.overlay_appearance)

	/// Oh, yeah, didn't I mention turning a visual overlay affects its pixel x/y/w/z too? Yeah, it sucks.
	var/new_x = vis_overlay.extra_width
	var/new_y = vis_overlay.extra_height
	var/old_div = source.current_size / resize
	var/offset_lying = source.rotate_on_lying ? PIXEL_Y_OFFSET_LYING : source.get_transform_translation_size(old_div)
	switch(source.lying_prev)
		if(270)
			vis_overlay.pixel_x += -offset_lying / old_div
		if(90)
			vis_overlay.pixel_x += offset_lying / old_div
		if(0)
			vis_overlay.pixel_y += -source.get_transform_translation_size(old_div) / old_div

	switch(new_lying_angle)
		if(270)
			new_x += -offset_lying / source.current_size
		if(90)
			new_x += offset_lying / source.current_size
		if(0)
			new_y += -source.get_transform_translation_size(old_div) / old_div

	animate(vis_overlay, transform = new_transform, pixel_x = new_x, pixel_y = new_y, time = UPDATE_TRANSFORM_ANIMATION_TIME, easing = (EASE_IN|EASE_OUT))
	addtimer(CALLBACK(vis_overlay, TYPE_PROC_REF(/atom/movable/immerse_overlay, adjust_living_overlay_offset), source), UPDATE_TRANSFORM_ANIMATION_TIME)

///Spin the overlay in the opposite direction so it doesn't look like it's spinning at all.
/datum/element/immerse/proc/on_spin_animation(atom/source, speed, loops, segments, segment)
	SIGNAL_HANDLER
	var/atom/movable/immerse_overlay/vis_overlay = immersed_movables[source]
	vis_overlay.do_spin_animation(speed, loops, segments, -segment)

///We need to make sure to remove hard refs from the element when deleted.
/datum/element/immerse/proc/clear_overlay_refs(atom/movable/immerse_overlay/source)
	//Assume that every vis loc is also in the immersed_movables list
	for(var/atom/movable/vis_loc as anything in source.vis_locs)
		remove_from_element(vis_loc.loc, vis_loc)
	LAZYREMOVE(generated_visual_overlays, source)
	source.overlay_appearance = null

///The not-quite-perfect movable used by the immerse element for its nefarious deeds.
/atom/movable/immerse_overlay
	appearance_flags = RESET_TRANSFORM|RESET_COLOR|RESET_ALPHA|KEEP_TOGETHER
	vis_flags = VIS_INHERIT_PLANE|VIS_INHERIT_ID
	mouse_opacity = MOUSE_OPACITY_TRANSPARENT
	blend_mode = BLEND_INSET_OVERLAY
	layer = WATER_VISUAL_OVERLAY_LAYER
	plane = FLOAT_PLANE
	/**
	 * The actual overlay used to make the mob look like it's half-covered in water.
	 *
	 * For visual overlays, pixel y/x/w/z are amplified by the a, b, d, e variables
	 * of the transform matrix of the movable they're attached to.
	 * For example, if a mob is twice its normal size (a = 2, e = 2),
	 * offsetting the movable used as visual overlay by 4 pixels to the right will result
	 * in the visual overlay moving 8 pixels to the right.
	 *
	 * This however, doesn't extend to the overlays of our visual overlay. which is why there's
	 * a mutable appearance variable that we use for those pixel offsets that really shouldn't be affected
	 * by the transform of our vis loc(s) in the first place.
	 */
	var/mutable_appearance/overlay_appearance
	///The base pixel x offset of this movable
	var/extra_width = 0
	///The base pixel y offset of this movable
	var/extra_height = 0

/atom/movable/immerse_overlay/Initialize(mapload, datum/element/immerse/element)
	. = ..()
	verbs.Cut() //"Cargo cultttttt" or something. Either way, they're better off without verbs.
	element?.RegisterSignal(src, COMSIG_QDELETING, TYPE_PROC_REF(/datum/element/immerse, clear_overlay_refs))

///Called by COMSIG_MOVABLE_EDIT_UNIQUE_IMMERSE_OVERLAY for living mobs and a few procs from the immerse element.
/atom/movable/immerse_overlay/proc/adjust_living_overlay_offset(mob/living/source)
	pixel_x = extra_width
	pixel_y = extra_height
	overlays = list(overlay_appearance)
