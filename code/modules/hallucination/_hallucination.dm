/**
 * # Hallucination datum.
 *
 * Handles effects of a hallucination on a living mob.
 * Created and triggered via the [cause hallucination proc][/mob/living/proc/cause_hallucination].
 *
 * See also: [the hallucination status effect][/datum/status_effect/hallucination].
 */
/datum/hallucination
	/// What is this hallucination's weight in the random hallucination pool?
	var/random_hallucination_weight = 0
	/// Who's our next highest abstract parent type?
	var/abstract_hallucination_parent = /datum/hallucination
	/// Extra info about the hallucination displayed in the log.
	var/feedback_details = ""
	/// The mob we're targeting with the hallucination.
	var/mob/living/hallucinator

/datum/hallucination/New(mob/living/hallucinator)
	if(!isliving(hallucinator))
		stack_trace("[type] was created without a hallucinating mob.")
		qdel(src)
		return

	src.hallucinator = hallucinator
	RegisterSignal(hallucinator, COMSIG_QDELETING, PROC_REF(target_deleting))
	GLOB.all_ongoing_hallucinations += src

/// Signal proc for [COMSIG_QDELETING], if the mob hallucinating us is deletes, we should delete too.
/datum/hallucination/proc/target_deleting()
	SIGNAL_HANDLER

	qdel(src)

/// Starts the hallucination.
/datum/hallucination/proc/start()
	SHOULD_CALL_PARENT(FALSE)
	stack_trace("[type] didn't implement any hallucination effects in start.")

/datum/hallucination/Destroy()
	if(hallucinator)
		UnregisterSignal(hallucinator, COMSIG_QDELETING)
		hallucinator = null

	GLOB.all_ongoing_hallucinations -= src
	return ..()

/// Returns a random turf in a ring around the hallucinator mob.
/// Useful for sound hallucinations.
/datum/hallucination/proc/random_far_turf()
	var/first_offset = pick(-8, -7, -6, -5, 5, 6, 7, 8)
	var/second_offset = rand(-8, 8)
	var/x_offset
	var/y_offset
	if(prob(50))
		x_offset = first_offset
		y_offset = second_offset
	else
		x_offset = second_offset
		y_offset = first_offset

	return locate(hallucinator.x + x_offset, hallucinator.y + y_offset, hallucinator.z)

/// Gets a random non-security member of the crew that is at least 8 tiles away.
/datum/hallucination/proc/random_non_sec_crewmember()
	var/list/possible_fakes = list()
	for(var/datum/mind/possible_fake as anything in get_crewmember_minds())
		// Sec won't make sense. (Neither will cap but we'll just let it slide)
		if(possible_fake.assigned_role.departments_bitflags & DEPARTMENT_BITFLAG_SECURITY)
			continue
		// Look for minds on the manifest in control of humans
		var/mob/living/carbon/human/fake_body = possible_fake.current
		if(!istype(fake_body) || fake_body == hallucinator)
			continue
		// This also won't make sense in most cases
		if(get_dist(fake_body, hallucinator) < 8)
			continue
		possible_fakes += fake_body

	return length(possible_fakes) ? pick(possible_fakes) : null

/**
 * Simple effect that holds an image
 * to be shown to one or multiple clients only.
 *
 * Pass a list of mobs in initialize() that corresponds to all mobs that can see it.
 */
/obj/effect/client_image_holder
	invisibility = INVISIBILITY_OBSERVER
	anchored = TRUE

	/// A list of mobs which can see us.
	var/list/mob/who_sees_us
	/// The created image, what we look like.
	var/image/shown_image
	/// The icon file the image uses. If null, we have no image
	var/image_icon
	/// The icon state the image uses
	var/image_state
	/// The x pixel offset of the image
	var/image_pixel_x = 0
	/// The y pixel offset of the image
	var/image_pixel_y = 0
	/// Optional, the color of the image
	var/image_color
	/// The layer of the image
	var/image_layer = MOB_LAYER
	/// The plane of the image
	var/image_plane = GAME_PLANE
	/// Should this image holder persist if there are no seers for it?
	var/persist_without_seers = FALSE

/obj/effect/client_image_holder/Initialize(mapload, list/mobs_which_see_us)
	. = ..()
	if(isnull(mobs_which_see_us))
		stack_trace("Client image holder was created with no mobs to see it.")
		return INITIALIZE_HINT_QDEL

	shown_image = generate_image()

	if(!islist(mobs_which_see_us))
		mobs_which_see_us = list(mobs_which_see_us)

	who_sees_us = list()
	for(var/mob/seer as anything in mobs_which_see_us)
		add_seer(seer)

/obj/effect/client_image_holder/Destroy(force)
	if(shown_image)
		for(var/mob/seer as anything in who_sees_us)
			remove_seer(seer)
		shown_image = null

	who_sees_us.Cut() // probably not needed but who knows
	return ..()

/obj/effect/client_image_holder/on_changed_z_level(turf/old_turf, turf/new_turf, same_z_layer, notify_contents)
	. = ..()
	if(QDELETED(src) || same_z_layer)
		return
	SET_PLANE(shown_image, PLANE_TO_TRUE(shown_image.plane), new_turf)

/obj/effect/client_image_holder/proc/add_seer(mob/new_seer)
	RegisterSignal(new_seer, COMSIG_MOB_LOGIN, PROC_REF(show_image_to))
	RegisterSignal(new_seer, COMSIG_QDELETING, PROC_REF(remove_seer))
	who_sees_us += new_seer
	show_image_to(new_seer)

/// Signal proc to clean up references if people who see us are deleted.
/obj/effect/client_image_holder/proc/remove_seer(mob/source)
	SIGNAL_HANDLER

	UnregisterSignal(source, list(COMSIG_MOB_LOGIN, COMSIG_QDELETING))
	hide_image_from(source)
	who_sees_us -= source

	// No reason to exist, anymore
	if(!QDELETED(src) && !length(who_sees_us) && !persist_without_seers)
		qdel(src)

/// Generates the image which we take on.
/obj/effect/client_image_holder/proc/generate_image()
	var/image/created = image(image_icon, src, image_state, image_layer, dir = src.dir)
	SET_PLANE_EXPLICIT(created, image_plane, src)
	created.pixel_x = image_pixel_x
	created.pixel_y = image_pixel_y
	if(image_color)
		created.color = image_color
	return created

/// Shows the image we generated to the passed mob
/obj/effect/client_image_holder/proc/show_image_to(mob/show_to)
	SIGNAL_HANDLER

	show_to.client?.images |= shown_image

/// Hides the image we generated from the passed mob
/obj/effect/client_image_holder/proc/hide_image_from(mob/hide_from)
	SIGNAL_HANDLER

	hide_from.client?.images -= shown_image

/// Simple helper for refreshing / showing the image to everyone in our list.
/obj/effect/client_image_holder/proc/regenerate_image()
	for(var/mob/seer as anything in who_sees_us)
		hide_image_from(seer)

	shown_image = generate_image()

	for(var/mob/seer as anything in who_sees_us)
		show_image_to(seer)

// Whenever we perform icon updates, regenerate our image
/obj/effect/client_image_holder/update_icon(updates = ALL)
	. = ..()
	regenerate_image()

// If we move for some reason, regenerate our image
/obj/effect/client_image_holder/Moved(atom/old_loc, movement_dir, forced, list/old_locs, momentum_change = TRUE)
	. = ..()
	if(!loc)
		return
	regenerate_image()

/obj/effect/client_image_holder/singularity_pull(atom/singularity, current_size)
	return

/obj/effect/client_image_holder/singularity_act()
	return

/**
 * A client-side image effect tied to the existence of a hallucination.
 */
/obj/effect/client_image_holder/hallucination
	invisibility = INVISIBILITY_OBSERVER
	anchored = TRUE
	/// The hallucination that created us.
	var/datum/hallucination/parent

/obj/effect/client_image_holder/hallucination/Initialize(mapload, list/mobs_which_see_us, datum/hallucination/parent)
	. = ..()
	if(!parent)
		stack_trace("[type] was created without a parent hallucination.")
		return INITIALIZE_HINT_QDEL

	RegisterSignal(parent, COMSIG_QDELETING, PROC_REF(parent_deleting))
	src.parent = parent

/obj/effect/client_image_holder/hallucination/Destroy(force)
	UnregisterSignal(parent, COMSIG_QDELETING)
	parent = null
	return ..()

/// Signal proc for [COMSIG_QDELETING], if our associated hallucination deletes, we should too
/obj/effect/client_image_holder/hallucination/proc/parent_deleting(datum/source)
	SIGNAL_HANDLER

	qdel(src)
