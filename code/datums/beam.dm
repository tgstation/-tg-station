
/** # Beam Datum and Effect
 * **IF YOU ARE LAZY AND DO NOT WANT TO READ, GO TO THE BOTTOM OF THE FILE AND USE THAT PROC!**
 *
 * This is the beam datum! It's a really neat effect for the game in drawing a line from one atom to another.
 * It has two parts:
 * The datum itself which manages redrawing the beam to constantly keep it pointing from the origin to the target.
 * The effect which is what the beams are made out of. They're placed in a line from the origin to target, rotated towards the target and snipped off at the end.
 * These effects are kept in a list and constantly created and destroyed (hence the proc names draw and reset, reset destroying all effects and draw creating more.)
 *
 * You can add more special effects to the beam itself by changing what the drawn beam effects do. For example you can make a vine that pricks people by making the beam_type
 * include a crossed proc that damages the crosser. Examples in venus_human_trap.dm
*/
/datum/beam
	///where the beam goes from
	var/atom/origin = null
	///where the beam goes to
	var/atom/target = null
	///list of beam objects. These have their visuals set by the visuals var which is created on starting
	var/list/elements = list()
	///icon used by the beam.
	var/icon
	///icon state of the main segments of the beam
	var/icon_state = ""
	///The beam will qdel if it's longer than this many tiles.
	var/max_distance = 0
	///the objects placed in the elements list
	var/beam_type = /obj/effect/ebeam
	///This is used as the visual_contents of beams, so you can apply one effect to this and the whole beam will look like that. never gets deleted on redrawing.
	var/obj/effect/ebeam/visuals
	///The color of the beam we're drawing.
	var/beam_color
	///If we use an emissive appearance
	var/emissive = TRUE
	/// If set will be used instead of origin's pixel_x in offset calculations
	var/override_origin_pixel_x = null
	/// If set will be used instead of origin's pixel_y in offset calculations
	var/override_origin_pixel_y = null
	/// If set will be used instead of targets's pixel_x in offset calculations
	var/override_target_pixel_x = null
	/// If set will be used instead of targets's pixel_y in offset calculations
	var/override_target_pixel_y = null
	///the layer of our beam
	var/beam_layer

/datum/beam/New(
	origin,
	target,
	icon = 'icons/effects/beam.dmi',
	icon_state = "b_beam",
	time = INFINITY,
	max_distance = INFINITY,
	beam_type = /obj/effect/ebeam,
	beam_color = null,
	emissive = TRUE,
	override_origin_pixel_x = null,
	override_origin_pixel_y = null,
	override_target_pixel_x = null,
	override_target_pixel_y = null,
	beam_layer = ABOVE_ALL_MOB_LAYER
)
	src.origin = origin
	src.target = target
	src.icon = icon
	src.icon_state = icon_state
	src.max_distance = max_distance
	src.beam_type = beam_type
	src.beam_color = beam_color
	src.emissive = emissive
	src.override_origin_pixel_x = override_origin_pixel_x
	src.override_origin_pixel_y = override_origin_pixel_y
	src.override_target_pixel_x = override_target_pixel_x
	src.override_target_pixel_y = override_target_pixel_y
	src.beam_layer = beam_layer
	if(time < INFINITY)
		QDEL_IN(src, time)

/**
 * Proc called by the atom Beam() proc. Sets up signals, and draws the beam for the first time.
 */
/datum/beam/proc/Start()
	visuals = new beam_type()
	visuals.icon = icon
	visuals.icon_state = icon_state
	visuals.color = beam_color
	visuals.vis_flags = VIS_INHERIT_PLANE|VIS_INHERIT_LAYER
	visuals.emissive = emissive
	visuals.layer = beam_layer
	visuals.update_appearance()
	Draw()
	RegisterSignals(origin, list(COMSIG_MOVABLE_MOVED, COMSIG_QDELETING), PROC_REF(redrawing))
	RegisterSignals(target, list(COMSIG_MOVABLE_MOVED, COMSIG_QDELETING), PROC_REF(redrawing))

/**
 * Triggered by signals set up when the beam is set up. If it's still sane to create a beam, it removes the old beam, creates a new one. Otherwise it kills the beam.
 *
 * Arguments:
 * mover: either the origin of the beam or the target of the beam that moved.
 * oldloc: from where mover moved.
 * direction: in what direction mover moved from.
 */
/datum/beam/proc/redrawing(atom/movable/mover, atom/oldloc, direction)
	SIGNAL_HANDLER
	if(!QDELETED(origin) && !QDELETED(target) && get_dist(origin,target)<max_distance && origin.z == target.z)
		QDEL_LIST(elements)
		INVOKE_ASYNC(src, PROC_REF(Draw))
	else
		qdel(src)

/datum/beam/Destroy()
	QDEL_LIST(elements)
	QDEL_NULL(visuals)
	UnregisterSignal(origin, COMSIG_MOVABLE_MOVED)
	UnregisterSignal(target, COMSIG_MOVABLE_MOVED)
	target = null
	origin = null
	return ..()

/**
 * Creates the beam effects and places them in a line from the origin to the target. Sets their rotation to make the beams face the target, too.
 */
/datum/beam/proc/Draw()
	if(SEND_SIGNAL(src, COMSIG_BEAM_BEFORE_DRAW) & BEAM_CANCEL_DRAW)
		return
	var/origin_px = (isnull(override_origin_pixel_x) ? origin.pixel_x : override_origin_pixel_x) + origin.pixel_w
	var/origin_py = (isnull(override_origin_pixel_y) ? origin.pixel_y : override_origin_pixel_y) + origin.pixel_z
	var/target_px = (isnull(override_target_pixel_x) ? target.pixel_x : override_target_pixel_x) + target.pixel_w
	var/target_py = (isnull(override_target_pixel_y) ? target.pixel_y : override_target_pixel_y) + target.pixel_z
	var/Angle = get_angle_raw(origin.x, origin.y, origin_px, origin_py, target.x , target.y, target_px, target_py)
	///var/Angle = round(get_angle(origin,target))
	var/matrix/rot_matrix = matrix()
	var/turf/origin_turf = get_turf(origin)
	rot_matrix.Turn(Angle)

	//Translation vector for origin and target
	var/DX = (32*target.x+target_px)-(32*origin.x+origin_px)
	var/DY = (32*target.y+target_py)-(32*origin.y+origin_py)
	var/N = 0
	var/length = round(sqrt((DX)**2+(DY)**2)) //hypotenuse of the triangle formed by target and origin's displacement

	for(N in 0 to length-1 step 32)//-1 as we want < not <=, but we want the speed of X in Y to Z and step X
		if(QDELETED(src))
			break
		var/obj/effect/ebeam/segment = new beam_type(origin_turf, src)
		elements += segment

		//Assign our single visual ebeam to each ebeam's vis_contents
		//ends are cropped by a transparent box icon of length-N pixel size laid over the visuals obj
		if(N+32>length) //went past the target, we draw a box of space to cut away from the beam sprite so the icon actually ends at the center of the target sprite
			var/icon/II = new(icon, icon_state)//this means we exclude the overshooting object from the visual contents which does mean those visuals don't show up for the final bit of the beam...
			II.DrawBox(null,1,(length-N),32,32)//in the future if you want to improve this, remove the drawbox and instead use a 513 filter to cut away at the final object's icon
			segment.icon = II
			segment.color = beam_color
		else
			segment.vis_contents += visuals
		segment.transform = rot_matrix

		//Calculate pixel offsets (If necessary)
		var/Pixel_x
		var/Pixel_y
		if(DX == 0)
			Pixel_x = 0
		else
			Pixel_x = round(sin(Angle)+32*sin(Angle)*(N+16)/32)
		if(DY == 0)
			Pixel_y = 0
		else
			Pixel_y = round(cos(Angle)+32*cos(Angle)*(N+16)/32)

		//Position the effect so the beam is one continous line
		var/final_x = segment.x
		var/final_y = segment.y
		if(abs(Pixel_x)>32)
			final_x += Pixel_x > 0 ? round(Pixel_x/32) : CEILING(Pixel_x/32, 1)
			Pixel_x %= 32
		if(abs(Pixel_y)>32)
			final_y += Pixel_y > 0 ? round(Pixel_y/32) : CEILING(Pixel_y/32, 1)
			Pixel_y %= 32

		segment.forceMove(locate(final_x, final_y, segment.z))
		segment.pixel_x = origin_px + Pixel_x
		segment.pixel_y = origin_py + Pixel_y
		CHECK_TICK

/obj/effect/ebeam
	mouse_opacity = MOUSE_OPACITY_TRANSPARENT
	layer = ABOVE_ALL_MOB_LAYER
	anchored = TRUE
	var/emissive = TRUE
	var/datum/beam/owner

/obj/effect/ebeam/Initialize(mapload, beam_owner)
	owner = beam_owner
	return ..()

/obj/effect/ebeam/update_overlays()
	. = ..()
	if(!emissive)
		return
	var/mutable_appearance/emissive_overlay = emissive_appearance(icon, icon_state, src)
	emissive_overlay.transform = transform
	emissive_overlay.alpha = alpha
	. += emissive_overlay

/obj/effect/ebeam/Destroy()
	owner = null
	return ..()

/obj/effect/ebeam/singularity_pull(atom/singularity, current_size)
	return

/obj/effect/ebeam/singularity_act()
	return

/obj/effect/ebeam/Process_Spacemove(movement_dir, continuous_move)
	return TRUE

/// A beam subtype used for advanced beams, to react to atoms entering the beam
/obj/effect/ebeam/reacting
	/// If TRUE, atoms that exist in the beam's loc when inited count as "entering" the beam
	var/react_on_init = FALSE

/obj/effect/ebeam/reacting/Initialize(mapload, beam_owner)
	. = ..()
	var/static/list/loc_connections = list(
		COMSIG_ATOM_ENTERED = PROC_REF(on_entered),
		COMSIG_ATOM_EXITED = PROC_REF(on_exited),
		COMSIG_TURF_CHANGE = PROC_REF(on_turf_change),
	)
	AddElement(/datum/element/connect_loc, loc_connections)

	if(!isturf(loc) || isnull(owner) || mapload || !react_on_init)
		return

	for(var/atom/movable/existing as anything in loc)
		beam_entered(existing)

/obj/effect/ebeam/reacting/proc/on_entered(datum/source, atom/movable/entered)
	SIGNAL_HANDLER

	if(isnull(owner))
		return

	beam_entered(entered)

/obj/effect/ebeam/reacting/proc/on_exited(datum/source, atom/movable/exited)
	SIGNAL_HANDLER

	if(isnull(owner))
		return

	beam_exited(exited)

/obj/effect/ebeam/reacting/proc/on_turf_change(datum/source, path, new_baseturfs, flags, list/datum/callback/post_change_callbacks)
	SIGNAL_HANDLER

	if(isnull(owner))
		return

	beam_turfs_changed(post_change_callbacks)

/// Some atom entered the beam's line
/obj/effect/ebeam/reacting/proc/beam_entered(atom/movable/entered)
	SHOULD_CALL_PARENT(TRUE)
	SEND_SIGNAL(owner, COMSIG_BEAM_ENTERED, src, entered)

/// Some atom exited the beam's line
/obj/effect/ebeam/reacting/proc/beam_exited(atom/movable/exited)
	SHOULD_CALL_PARENT(TRUE)
	SEND_SIGNAL(owner, COMSIG_BEAM_EXITED, src, exited)

/// Some turf the beam covers has changed to a new turf type
/obj/effect/ebeam/reacting/proc/beam_turfs_changed(list/datum/callback/post_change_callbacks)
	SHOULD_CALL_PARENT(TRUE)
	SEND_SIGNAL(owner, COMSIG_BEAM_TURFS_CHANGED, post_change_callbacks)

/**
 * This is what you use to start a beam. Example: origin.Beam(target, args). **Store the return of this proc if you don't set maxdist or time, you need it to delete the beam.**
 *
 * Unless you're making a custom beam effect (see the beam_type argument), you won't actually have to mess with any other procs. Make sure you store the return of this Proc, you'll need it
 * to kill the beam.
 * **Arguments:**
 * BeamTarget: Where you're beaming from. Where do you get origin? You didn't read the docs, fuck you.
 * icon_state: What the beam's icon_state is. The datum effect isn't the ebeam object, it doesn't hold any icon and isn't type dependent.
 * icon: What the beam's icon file is. Don't change this, man. All beam icons should be in beam.dmi anyways.
 * maxdistance: how far the beam will go before stopping itself. Used mainly for two things: preventing lag if the beam may go in that direction and setting a range to abilities that use beams.
 * beam_type: The type of your custom beam. This is for adding other wacky stuff for your beam only. Most likely, you won't (and shouldn't) change it.
 */
/atom/proc/Beam(atom/BeamTarget,
	icon_state="b_beam",
	icon='icons/effects/beam.dmi',
	time=INFINITY,maxdistance=INFINITY,
	beam_type=/obj/effect/ebeam,
	beam_color = null, emissive = TRUE,
	override_origin_pixel_x = null,
	override_origin_pixel_y = null,
	override_target_pixel_x = null,
	override_target_pixel_y = null,
	layer = ABOVE_ALL_MOB_LAYER
)
	var/datum/beam/newbeam = new(src,BeamTarget,icon,icon_state,time,maxdistance,beam_type, beam_color, emissive, override_origin_pixel_x, override_origin_pixel_y, override_target_pixel_x, override_target_pixel_y, layer)
	INVOKE_ASYNC(newbeam, TYPE_PROC_REF(/datum/beam/, Start))
	return newbeam
