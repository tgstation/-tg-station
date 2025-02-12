/**
 * Called whenever the mob is to be resized or when lying/standing up for carbons.
 * IMPORTANT: Multiple animate() calls do not stack well, so try to do them all at once if you can.
 */
/mob/living/proc/update_transform(resize = RESIZE_DEFAULT_SIZE)
	var/matrix/ntransform = matrix(transform)
	var/current_translate = get_transform_translation_size(current_size)
	var/final_dir = dir
	var/changed = FALSE

	if(lying_angle != lying_prev && rotate_on_lying)
		changed = TRUE
		if(lying_angle && lying_prev == 0)
			if(current_translate)
				ntransform.Translate(0, -current_translate)
			// Standing to lying and facing east or west
			if(dir & (EAST|WEST))
				// ...So you fall on your side, rather than your face or ass
				final_dir = pick(NORTH, SOUTH)
		else
			if(current_translate && !lying_angle && lying_prev != 0)
				ntransform.Translate(current_translate * (lying_prev == 270 ? -1 : 1), 0)
		// Done last, as it can mess with the translation.
		ntransform.TurnTo(lying_prev, lying_angle)

	if(resize != RESIZE_DEFAULT_SIZE)
		changed = TRUE
		var/is_vertical = !lying_angle || !rotate_on_lying
		var/new_translation = get_transform_translation_size(resize * current_size)
		// scaling also affects translation, so we've to undo the old translate beforehand.
		if(is_vertical && current_translate)
			ntransform.Translate(0, -current_translate)

		ntransform.Scale(resize)
		current_size *= resize
		// Update the height of the maptext according to the size of the mob so they don't overlap.
		var/old_maptext_offset = body_maptext_height_offset
		body_maptext_height_offset = initial(maptext_height) * (current_size - 1) * 0.5
		maptext_height += body_maptext_height_offset - old_maptext_offset
		// and update the new translation
		if(is_vertical && new_translation)
			ntransform.Translate(0, new_translation)

	if(!changed) //Nothing has been changed, nothing has to be done.
		return FALSE

	// ensures the floating animation doesn't mess with our animation
	if(HAS_TRAIT(src, TRAIT_MOVE_FLOATING))
		ADD_TRAIT(src, TRAIT_NO_FLOATING_ANIM, UPDATE_TRANSFORM_TRAIT)
		addtimer(TRAIT_CALLBACK_REMOVE(src, TRAIT_NO_FLOATING_ANIM, UPDATE_TRANSFORM_TRAIT), 0.3 SECONDS, TIMER_UNIQUE|TIMER_OVERRIDE)
	//if true, we want to avoid any animation time, it'll tween and not rotate at all otherwise.
	var/is_opposite_angle = REVERSE_ANGLE(lying_angle) == lying_prev
	var/animate_time = is_opposite_angle ? 0 : UPDATE_TRANSFORM_ANIMATION_TIME
	animate(src, transform = ntransform, time = animate_time, dir = final_dir, easing = (EASE_IN|EASE_OUT))
	for (var/hud_key in hud_list)
		var/image/hud_image = hud_list[hud_key]
		if (istype(hud_image))
			adjust_hud_position(hud_image, animate_time = animate_time)

	SEND_SIGNAL(src, COMSIG_LIVING_POST_UPDATE_TRANSFORM, resize, lying_angle, is_opposite_angle)
	return TRUE

/// Calculates how far vertically the mob's transform should translate according to its size (1 being "default")
/mob/living/proc/get_transform_translation_size(value)
	return (value - 1) * 16

/**
 * Adds an offset to the mob's pixel position.
 *
 * * source: The source of the offset, a string
 * * w_add: pixel_w offset
 * * x_add: pixel_x offset
 * * y_add: pixel_y offset
 * * z_add: pixel_z offset
 * * animate: If TRUE, the mob will animate to the new position. If FALSE, it will instantly move.
 */
/mob/living/proc/add_offsets(source, w_add, x_add, y_add, z_add, animate = TRUE)
	LAZYINITLIST(offsets)
	if(isnum(w_add))
		LAZYSET(offsets[PIXEL_W_OFFSET], source, w_add)
	if(isnum(x_add))
		LAZYSET(offsets[PIXEL_X_OFFSET], source, x_add)
	if(isnum(y_add))
		LAZYSET(offsets[PIXEL_Y_OFFSET], source, y_add)
	if(isnum(z_add))
		LAZYSET(offsets[PIXEL_Z_OFFSET], source, z_add)
	update_offsets(animate)

/**
 * Goes through all pixel adjustments and removes any tied to the passed source.
 *
 * * source: The source of the offset to remove
 * * animate: If TRUE, the mob will animate to the position with any offsets removed. If FALSE, it will instantly move.
 */
/mob/living/proc/remove_offsets(source, animate = TRUE)
	for(var/offset in offsets)
		LAZYREMOVE(offsets[offset], source)
		ASSOC_UNSETEMPTY(offsets, offset)
	UNSETEMPTY(offsets)
	update_offsets(animate)

/**
 * Updates the mob's pixel position according to the offsets.
 *
 * * animate: If TRUE, the mob will animate to the new position. If FALSE, it will instantly move.
 *
 * Returns TRUE if the mob's position has changed, FALSE otherwise.
 */
/mob/living/proc/update_offsets(animate = FALSE)
	var/new_w = base_pixel_w
	var/new_x = base_pixel_x
	var/new_y = base_pixel_y
	var/new_z = base_pixel_z

	for(var/offset_key in LAZYACCESS(offsets, PIXEL_W_OFFSET))
		new_w += offsets[PIXEL_W_OFFSET][offset_key]
	for(var/offset_key in LAZYACCESS(offsets, PIXEL_X_OFFSET))
		new_x += offsets[PIXEL_X_OFFSET][offset_key]
	for(var/offset_key in LAZYACCESS(offsets, PIXEL_Y_OFFSET))
		new_y += offsets[PIXEL_Y_OFFSET][offset_key]
	for(var/offset_key in LAZYACCESS(offsets, PIXEL_Z_OFFSET))
		new_z += offsets[PIXEL_Z_OFFSET][offset_key]

	if(new_w == pixel_w && new_x == pixel_x && new_y == pixel_y && new_z == pixel_z)
		return FALSE

	if(!animate)
		pixel_w = new_w
		pixel_x = new_x
		pixel_y = new_y
		pixel_z = new_z
		return TRUE

	// ensures the floating animation doesn't mess with our animation
	if(HAS_TRAIT(src, TRAIT_MOVE_FLOATING))
		ADD_TRAIT(src, TRAIT_NO_FLOATING_ANIM, UPDATE_OFFSET_TRAIT)
		addtimer(TRAIT_CALLBACK_REMOVE(src, TRAIT_NO_FLOATING_ANIM, UPDATE_OFFSET_TRAIT), 0.3 SECONDS, TIMER_UNIQUE|TIMER_OVERRIDE)

	animate(src,
		pixel_w = new_w,
		pixel_x = new_x,
		pixel_y = new_y,
		pixel_z = new_z,
		easing = (EASE_IN|EASE_OUT),
		flags = ANIMATION_PARALLEL,
		time = UPDATE_TRANSFORM_ANIMATION_TIME,
	)
	return TRUE

/**
 * Checks if we are offset by the passed source for the passed pixel.
 *
 * * source: The source of the offset
 * * pixel: Optional, The pixel to check.
 * If not supplied, just reports if it's offset by the source at all (returning the first offset found).
 *
 * Returns the offset if we are, 0 otherwise.
 */
/mob/living/proc/has_offset(source, pixel)
	if(isnull(pixel))
		for(var/found_pixel in offsets)
			var/pixel_source = has_offset(source, found_pixel)
			if(pixel_source)
				return pixel_source

		return 0

	return offsets?[pixel]?[source] || 0

// Updates offsets if base pixel changes
// Future TODO: move base pixel onto /obj and make mobs just set a base pixel using a source
/mob/living/set_base_pixel_x(new_value)
	. = ..()
	update_offsets()

/mob/living/set_base_pixel_y(new_value)
	. = ..()
	update_offsets()
