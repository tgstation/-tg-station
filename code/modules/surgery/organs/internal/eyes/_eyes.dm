/obj/item/organ/eyes
	name = BODY_ZONE_PRECISE_EYES
	icon_state = "eyes"
	desc = "I see you!"
	visual = TRUE
	zone = BODY_ZONE_PRECISE_EYES
	slot = ORGAN_SLOT_EYES
	gender = PLURAL

	healing_factor = STANDARD_ORGAN_HEALING
	decay_factor = STANDARD_ORGAN_DECAY
	maxHealth = 0.5 * STANDARD_ORGAN_THRESHOLD //half the normal health max since we go blind at 30, a permanent blindness at 50 therefore makes sense unless medicine is administered
	high_threshold = 0.3 * STANDARD_ORGAN_THRESHOLD //threshold at 30
	low_threshold = 0.2 * STANDARD_ORGAN_THRESHOLD //threshold at 20

	low_threshold_passed = span_info("Distant objects become somewhat less tangible.")
	high_threshold_passed = span_info("Everything starts to look a lot less clear.")
	now_failing = span_warning("Darkness envelopes you, as your eyes go blind!")
	now_fixed = span_info("Color and shapes are once again perceivable.")
	high_threshold_cleared = span_info("Your vision functions passably once more.")
	low_threshold_cleared = span_info("Your vision is cleared of any ailment.")

	/// Sight flags this eye pair imparts on its user.
	var/sight_flags = NONE
	/// changes how the eyes overlay is applied, makes it apply over the lighting layer
	var/overlay_ignore_lighting = FALSE
	/// How much innate tint these eyes have
	var/tint = 0
	/// How much innare flash protection these eyes have, usually paired with tint
	var/flash_protect = FLASH_PROTECTION_NONE
	/// What level of invisibility these eyes can see
	var/see_invisible = SEE_INVISIBLE_LIVING
	/// How much darkness to cut out of your view (basically, night vision)
	var/lighting_cutoff = null
	/// List of color cutoffs from eyes, or null if not applicable
	var/list/color_cutoffs = null
	/// Are these eyes immune to pepperspray?
	var/pepperspray_protect = FALSE

	var/eye_color_left = "" //set to a hex code to override a mob's left eye color
	var/eye_color_right = "" //set to a hex code to override a mob's right eye color
	var/eye_icon_state = "eyes"
	/// Do these eyes have blinking animations
	var/blink_animation = TRUE
	/// Do these eyes have iris overlays
	var/iris_overlays = TRUE
	/// Should our blinking be synchronized or can separate eyes have (slightly) separate blinking times
	var/synchronized_blinking = TRUE
	// A pair of abstract eyelid objects (yes, really) used to animate blinking
	var/obj/effect/abstract/eyelid_effect/eyelid_left
	var/obj/effect/abstract/eyelid_effect/eyelid_right

	/// Glasses cannot be worn over these eyes. Currently unused
	var/no_glasses = FALSE
	/// indication that the eyes are undergoing some negative effect
	var/damaged = FALSE
	/// Native FOV that will be applied if a config is enabled
	var/native_fov = FOV_90_DEGREES
	/// Scarring on this organ
	var/scarring = NONE

/obj/item/organ/eyes/Initialize(mapload)
	. = ..()
	if (blink_animation)
		eyelid_left = new(src, "[eye_icon_state]_l")
		eyelid_right = new(src, "[eye_icon_state]_r")

/obj/item/organ/eyes/Destroy()
	QDEL_NULL(eyelid_left)
	QDEL_NULL(eyelid_right)
	return ..()

/obj/item/organ/eyes/on_mob_insert(mob/living/carbon/receiver, special, movement_flags)
	. = ..()
	receiver.cure_blind(NO_EYES)
	apply_damaged_eye_effects()
	refresh(receiver, call_update = !special)
	RegisterSignal(receiver, COMSIG_ATOM_BULLET_ACT, PROC_REF(on_bullet_act))
	RegisterSignal(receiver, COMSIG_COMPONENT_CLEAN_FACE_ACT, PROC_REF(on_face_wash))
	if (scarring)
		apply_scarring_effects()

/// Refreshes the visuals of the eyes
/// If call_update is TRUE, we also will call update_body
/obj/item/organ/eyes/proc/refresh(mob/living/carbon/eye_owner = owner, call_update = TRUE)
	owner.update_sight()
	owner.update_tint()

	if(!ishuman(eye_owner))
		return

	var/mob/living/carbon/human/affected_human = eye_owner
	if(length(eye_color_left))
		affected_human.add_eye_color_left(eye_color_left, EYE_COLOR_ORGAN_PRIORITY, update_body = FALSE)
	if(length(eye_color_right))
		affected_human.add_eye_color_right(eye_color_right, EYE_COLOR_ORGAN_PRIORITY, update_body = FALSE)
	refresh_atom_color_overrides()

	if(HAS_TRAIT(affected_human, TRAIT_NIGHT_VISION) && !lighting_cutoff)
		lighting_cutoff = LIGHTING_CUTOFF_REAL_LOW
	if(CONFIG_GET(flag/native_fov) && native_fov)
		affected_human.add_fov_trait(type, native_fov)

	if(call_update)
		affected_human.update_body()

/obj/item/organ/eyes/on_mob_remove(mob/living/carbon/organ_owner, special, movement_flags)
	. = ..()

	if(ishuman(organ_owner))
		var/mob/living/carbon/human/human_owner = organ_owner
		human_owner.remove_eye_color(EYE_COLOR_ORGAN_PRIORITY, update_body = FALSE)
		for(var/i in 1 to COLOUR_PRIORITY_AMOUNT)
			human_owner.remove_eye_color(EYE_COLOR_ATOM_COLOR_PRIORITY + i, update_body = FALSE)
		if(native_fov)
			organ_owner.remove_fov_trait(type)
		if(!special)
			human_owner.update_body()

	// Cure blindness from eye damage
	organ_owner.cure_blind(EYE_DAMAGE)
	organ_owner.cure_nearsighted(EYE_DAMAGE)
	// Eye blind and temp blind go to, even if this is a bit of cheesy way to clear blindness
	organ_owner.remove_status_effect(/datum/status_effect/eye_blur)
	organ_owner.remove_status_effect(/datum/status_effect/temporary_blindness)
	// Then become blind anyways (if not special)
	if(!special)
		organ_owner.become_blind(NO_EYES)

	organ_owner.update_tint()
	organ_owner.update_sight()
	UnregisterSignal(organ_owner, list(COMSIG_ATOM_BULLET_ACT, COMSIG_COMPONENT_CLEAN_FACE_ACT))

/obj/item/organ/eyes/update_atom_colour()
	. = ..()
	if (ishuman(owner))
		refresh_atom_color_overrides()
		owner.update_body()

/// Adds eye color overrides to our owner from our atom color
/obj/item/organ/eyes/proc/refresh_atom_color_overrides()
	if (!atom_colours)
		return

	var/mob/living/carbon/human/human_owner = owner
	for(var/i in 1 to COLOUR_PRIORITY_AMOUNT)
		var/list/checked_color = atom_colours[i]
		if (!checked_color)
			human_owner.remove_eye_color(EYE_COLOR_ATOM_COLOR_PRIORITY + i, update_body = FALSE)
			continue

		var/left_color = COLOR_WHITE
		var/right_color = COLOR_WHITE

		if (length(eye_color_left))
			left_color = eye_color_left
		if (length(eye_color_right))
			right_color = eye_color_right

		if (checked_color[ATOM_COLOR_TYPE_INDEX] == ATOM_COLOR_TYPE_FILTER)
			var/color_filter = checked_color[ATOM_COLOR_VALUE_INDEX]
			left_color = apply_matrix_to_color(left_color, color_filter["color"], color_filter["space"] || COLORSPACE_RGB)
			right_color = apply_matrix_to_color(right_color, color_filter["color"], color_filter["space"] || COLORSPACE_RGB)
		else
			var/list/target_color = color_transition_filter(checked_color[ATOM_COLOR_VALUE_INDEX], SATURATION_OVERRIDE)
			left_color = apply_matrix_to_color(left_color, target_color["color"], COLORSPACE_HSL)
			right_color = apply_matrix_to_color(right_color, target_color["color"], COLORSPACE_HSL)

		human_owner.add_eye_color_left(left_color, EYE_COLOR_ATOM_COLOR_PRIORITY + i, update_body = FALSE)
		human_owner.add_eye_color_right(right_color, EYE_COLOR_ATOM_COLOR_PRIORITY + i, update_body = FALSE)

/obj/item/organ/eyes/proc/on_bullet_act(mob/living/carbon/source, obj/projectile/proj, def_zone, piercing_hit, blocked)
	SIGNAL_HANDLER

	// Once-a-dozen-rounds level of rare
	if (def_zone != BODY_ZONE_HEAD || !prob(proj.damage * 0.1) || !(proj.damage_type == BRUTE || proj.damage_type == BURN))
		return

	if (blocked && source.is_eyes_covered())
		if (!proj.armour_penetration || prob(blocked - proj.armour_penetration))
			return

	var/valid_sides = list()
	if (!(scarring & RIGHT_EYE_SCAR))
		valid_sides += RIGHT_EYE_SCAR
	if (!(scarring & LEFT_EYE_SCAR))
		valid_sides += LEFT_EYE_SCAR
	if (!length(valid_sides))
		return

	var/picked_side = pick(valid_sides)
	to_chat(owner, span_userdanger("You feel searing pain shoot though your [picked_side == RIGHT_EYE_SCAR ? "right" : "left"] eye!"))
	// oof ouch my eyes
	apply_organ_damage(rand((maxHealth - high_threshold) * 0.5, maxHealth - low_threshold))
	var/datum/wound/pierce/bleed/severe/eye/eye_puncture = new
	eye_puncture.apply_wound(bodypart_owner, wound_source = "bullet impact", right_side = picked_side)
	apply_scar(picked_side)

/// When our owner washes their face. The idea that spessmen wash their eyeballs is highly disturbing but this is the easiest way to get rid of cursed crayon eye coloring
/obj/item/organ/eyes/proc/on_face_wash()
	SIGNAL_HANDLER
	wash(CLEAN_WASH)

#define OFFSET_X 1
#define OFFSET_Y 2

/// Similar to get_status_text, but appends the text after the damage report, for additional status info
/obj/item/organ/eyes/get_status_appendix(advanced, add_tooltips)
	if(owner.stat == DEAD || HAS_TRAIT(owner, TRAIT_KNOCKEDOUT))
		return
	if(owner.is_blind())
		if(advanced)
			if(owner.is_blind_from(QUIRK_TRAIT))
				return conditional_tooltip("Subject is permanently blind.", "Irreparable under normal circumstances.", add_tooltips)
			if(owner.is_blind_from(EYE_SCARRING_TRAIT))
				return conditional_tooltip("Subject is blind from widespread ocular scarring.", "Surgically replace eyes, irreparable otherwise.", add_tooltips)
			if(owner.is_blind_from(TRAUMA_TRAIT))
				return conditional_tooltip("Subject is blind from mental trauma.", "Repair via treatment of associated trauma.", add_tooltips)
			if(owner.is_blind_from(GENETIC_MUTATION))
				return conditional_tooltip("Subject is genetically blind.", "Use medication such as [/datum/reagent/medicine/mutadone::name].", add_tooltips)
			if(owner.is_blind_from(EYE_DAMAGE))
				return conditional_tooltip("Subject is blind from eye damage.", "Repair surgically, use medication such as [/datum/reagent/medicine/oculine::name], or protect eyes with a blindfold.", add_tooltips)
		return "Subject is blind."
	if(owner.is_nearsighted())
		if(advanced)
			if(owner.is_nearsighted_from(QUIRK_TRAIT))
				return conditional_tooltip("Subject is permanently nearsighted.", "Irreparable under normal circumstances. Prescription glasses will assuage the effects.", add_tooltips)
			if(owner.is_nearsighted_from(TRAIT_RIGHT_EYE_SCAR) || owner.is_nearsighted_from(TRAIT_LEFT_EYE_SCAR))
				return conditional_tooltip("Subject is nearsighted from severe ocular scarring.", "Surgically replace eyes, irreparable otherwise.", add_tooltips)
			if(owner.is_nearsighted_from(GENETIC_MUTATION))
				return conditional_tooltip("Subject is genetically nearsighted.", "Use medication such as [/datum/reagent/medicine/mutadone::name]. Prescription glasses will assuage the effects.", add_tooltips)
			if(owner.is_nearsighted_from(EYE_DAMAGE))
				return conditional_tooltip("Subject is nearsighted from eye damage.", "Repair surgically or use medication such as [/datum/reagent/medicine/oculine::name]. Prescription glasses will assuage the effects.", add_tooltips)
		return "Subject is nearsighted."
	return ""

/obj/item/organ/eyes/show_on_condensed_scans()
	// Always show if we have an appendix
	return ..() || (owner.stat != DEAD && !HAS_TRAIT(owner, TRAIT_KNOCKEDOUT) && (owner.is_blind() || owner.is_nearsighted()))

/// This proc generates a list of overlays that the eye should be displayed using for the given parent
/obj/item/organ/eyes/proc/generate_body_overlay(mob/living/carbon/human/parent)
	if(!istype(parent) || parent.get_organ_by_type(/obj/item/organ/eyes) != src)
		CRASH("Generating a body overlay for [src] targeting an invalid parent '[parent]'.")

	if(isnull(eye_icon_state))
		return list()

	var/mutable_appearance/eye_left = mutable_appearance('icons/mob/human/human_face.dmi', "[eye_icon_state]_l", -BODY_LAYER, parent)
	var/mutable_appearance/eye_right = mutable_appearance('icons/mob/human/human_face.dmi', "[eye_icon_state]_r", -BODY_LAYER, parent)
	var/list/overlays = list(eye_left, eye_right)

	var/obscured = parent.check_obscured_slots(TRUE)
	if(overlay_ignore_lighting && !(obscured & ITEM_SLOT_EYES))
		overlays += emissive_appearance(eye_left.icon, eye_left.icon_state, parent, -BODY_LAYER, alpha = eye_left.alpha)
		overlays += emissive_appearance(eye_right.icon, eye_right.icon_state, parent, -BODY_LAYER, alpha = eye_right.alpha)

	var/obj/item/bodypart/head/my_head = parent.get_bodypart(BODY_ZONE_HEAD)

	if(!my_head)
		return overlays

	if(my_head.head_flags & HEAD_EYECOLOR)
		eye_right.color = parent.get_right_eye_color()
		eye_left.color = parent.get_left_eye_color()
		var/list/eyelids = setup_eyelids(eye_left, eye_right, parent)
		if (LAZYLEN(eyelids))
			overlays += eyelids

	if (scarring & RIGHT_EYE_SCAR)
		var/mutable_appearance/right_scar = mutable_appearance('icons/mob/human/human_face.dmi', "eye_scar_right", -BODY_LAYER)
		right_scar.color = my_head.draw_color
		overlays += right_scar

	if (scarring & LEFT_EYE_SCAR)
		var/mutable_appearance/left_scar = mutable_appearance('icons/mob/human/human_face.dmi', "eye_scar_left", -BODY_LAYER)
		left_scar.color = my_head.draw_color
		overlays += left_scar

	if(my_head.worn_face_offset)
		my_head.worn_face_offset.apply_offset(eye_left)
		my_head.worn_face_offset.apply_offset(eye_right)

	return overlays

/obj/item/organ/eyes/update_overlays()
	. = ..()
	if (scarring & RIGHT_EYE_SCAR)
		. += mutable_appearance('icons/obj/medical/organs/organs.dmi', "eye_scar_right")
	if (scarring & LEFT_EYE_SCAR)
		. += mutable_appearance('icons/obj/medical/organs/organs.dmi', "eye_scar_left")
	if (iris_overlays && eye_color_left && eye_color_right)
		var/mutable_appearance/left_iris = mutable_appearance(icon, "[icon_state]_iris_l")
		var/mutable_appearance/right_iris = mutable_appearance(icon, "[icon_state]_iris_r")
		var/list/color_left = rgb2num(eye_color_left, COLORSPACE_HSL)
		var/list/color_right = rgb2num(eye_color_right, COLORSPACE_HSL)
		// Ugly as sin? Indeed it is! But otherwise eyeballs turn out to be super dark, and this way even lighter colors are mostly preserved
		if (color_left[3])
			color_left[3] /= sqrt(color_left[3] * 0.01)
		if (color_right[3])
			color_right[3] /= sqrt(color_right[3] * 0.01)
		left_iris.color = rgb(color_left[1], color_left[2], color_left[3], space = COLORSPACE_HSL)
		right_iris.color = rgb(color_right[1], color_right[2], color_right[3], space = COLORSPACE_HSL)
		. += left_iris
		. += right_iris

/obj/item/organ/eyes/proc/apply_scar(side)
	if (scarring & side)
		return
	scarring |= side
	maxHealth -= 15
	update_appearance()
	apply_scarring_effects()

/obj/item/organ/eyes/proc/apply_scarring_effects()
	if(!owner)
		return
	// Even if eyes have enough health, our owner still becomes nearsighted
	if(scarring & RIGHT_EYE_SCAR)
		owner.assign_nearsightedness(TRAIT_RIGHT_EYE_SCAR, 1, FALSE)
	if(scarring & LEFT_EYE_SCAR)
		owner.assign_nearsightedness(TRAIT_LEFT_EYE_SCAR, 1, FALSE)
	if((scarring & RIGHT_EYE_SCAR) && (scarring & LEFT_EYE_SCAR))
		owner.become_blind(EYE_SCARRING_TRAIT)
	owner.update_body()

/obj/item/organ/eyes/proc/fix_scar(side)
	if (!(scarring & side))
		return
	scarring &= ~side
	maxHealth += 15
	update_appearance()
	if (!owner)
		return
	owner.cure_nearsighted(side == RIGHT_EYE_SCAR ? TRAIT_RIGHT_EYE_SCAR : TRAIT_LEFT_EYE_SCAR)
	owner.cure_blind(EYE_SCARRING_TRAIT)
	owner.update_body()

/obj/item/organ/eyes/on_mob_remove(mob/living/carbon/eye_owner)
	. = ..()
	if (scarring)
		eye_owner.cure_nearsighted(TRAIT_RIGHT_EYE_SCAR)
		eye_owner.cure_nearsighted(TRAIT_LEFT_EYE_SCAR)
		eye_owner.cure_blind(EYE_SCARRING_TRAIT)

#undef OFFSET_X
#undef OFFSET_Y

//Gotta reset the eye color, because that persists
/obj/item/organ/eyes/enter_wardrobe()
	. = ..()
	eye_color_left = initial(eye_color_left)
	eye_color_right = initial(eye_color_right)

/obj/item/organ/eyes/apply_organ_damage(damage_amount, maximum = maxHealth, required_organ_flag)
	. = ..()
	if(!owner)
		return FALSE
	apply_damaged_eye_effects()

/// Applies effects to our owner based on how damaged our eyes are
/obj/item/organ/eyes/proc/apply_damaged_eye_effects()
	// we're in healthy threshold, either try to heal (if damaged) or do nothing
	if(damage <= low_threshold)
		if(damaged)
			damaged = FALSE
			// clear nearsightedness from damage
			owner.cure_nearsighted(EYE_DAMAGE)
			// and cure blindness from damage
			owner.cure_blind(EYE_DAMAGE)
		return

	//various degrees of "oh fuck my eyes", from "point a laser at your eye" to "staring at the Sun" intensities
	// 50 - blind
	// 49-31 - nearsighted (2 severity)
	// 30-20 - nearsighted (1 severity)
	if(organ_flags & ORGAN_FAILING)
		// become blind from damage
		owner.become_blind(EYE_DAMAGE)

	else
		// become nearsighted from damage
		var/severity = damage > high_threshold ? 3 : 2
		owner.assign_nearsightedness(EYE_DAMAGE, severity, TRUE)

	damaged = TRUE

#define BASE_BLINKING_DELAY 5 SECONDS
#define RAND_BLINKING_DELAY 1 SECONDS
#define BLINK_DURATION 0.15 SECONDS
#define BLINK_LOOPS 5
#define ASYNC_BLINKING_BRAIN_DAMAGE 60

/// Modifies eye overlays to also act as eyelids, both for blinking and for when you're knocked out cold
/obj/item/organ/eyes/proc/setup_eyelids(mutable_appearance/eye_left, mutable_appearance/eye_right, mob/living/carbon/human/parent)
	var/obj/item/bodypart/head/my_head = parent.get_bodypart(BODY_ZONE_HEAD)
	// Robotic eyes or colorless heads don't get the privelege of having eyelids
	if (IS_ROBOTIC_ORGAN(src) || !my_head.draw_color || HAS_TRAIT(parent, TRAIT_NO_EYELIDS))
		return

	var/list/base_color = rgb2num(my_head.draw_color, COLORSPACE_HSL)
	base_color[2] *= 0.85
	base_color[3] *= 0.85
	var/eyelid_color = rgb(base_color[1], base_color[2], base_color[3], (length(base_color) >= 4 ? base_color[4] : null), COLORSPACE_HSL)
	// If we're knocked out, just color the eyes
	if (!parent.appears_alive() || HAS_TRAIT(parent, TRAIT_KNOCKEDOUT))
		eye_right.color = eyelid_color
		eye_left.color = eyelid_color
		return

	if (!blink_animation || HAS_TRAIT(parent, TRAIT_PREVENT_BLINKING))
		return

	eyelid_left.color = eyelid_color
	eyelid_right.color = eyelid_color
	eyelid_left.render_target = "*[REF(parent)]_eyelid_left"
	eyelid_right.render_target = "*[REF(parent)]_eyelid_right"
	parent.vis_contents += eyelid_left
	parent.vis_contents += eyelid_right
	var/sync_blinking = synchronized_blinking && (parent.get_organ_loss(ORGAN_SLOT_BRAIN) < ASYNC_BLINKING_BRAIN_DAMAGE)
	// Randomize order for unsynched animations
	if (sync_blinking || prob(50))
		var/list/anim_times = animate_eyelid(eyelid_left, parent, sync_blinking)
		animate_eyelid(eyelid_right, parent, sync_blinking, anim_times)
	else
		var/list/anim_times = animate_eyelid(eyelid_right, parent, sync_blinking)
		animate_eyelid(eyelid_left, parent, sync_blinking, anim_times)

	var/mutable_appearance/left_eyelid_overlay = mutable_appearance(layer = -BODY_LAYER, offset_spokesman = parent)
	var/mutable_appearance/right_eyelid_overlay = mutable_appearance(layer = -BODY_LAYER, offset_spokesman = parent)
	left_eyelid_overlay.render_source = "*[REF(parent)]_eyelid_left"
	right_eyelid_overlay.render_source = "*[REF(parent)]_eyelid_right"
	return list(left_eyelid_overlay, right_eyelid_overlay)

/// Animates one eyelid at a time, thanks BYOND and thanks animation chains
/obj/item/organ/eyes/proc/animate_eyelid(obj/effect/abstract/eyelid_effect/eyelid, mob/living/carbon/human/parent, sync_blinking = TRUE, list/anim_times = null)
	. = list()
	var/prevent_loops = HAS_TRAIT(parent, TRAIT_PREVENT_BLINK_LOOPS)
	animate(eyelid, alpha = 0, time = 0, loop = (prevent_loops ? 0 : -1))
	for (var/i in 1 to (prevent_loops ? 1 : BLINK_LOOPS))
		var/wait_time = rand(BASE_BLINKING_DELAY - RAND_BLINKING_DELAY, BASE_BLINKING_DELAY + RAND_BLINKING_DELAY)
		if (anim_times)
			if (sync_blinking)
				wait_time = anim_times[1]
				anim_times.Cut(1, 2)
			else
				wait_time = rand(max(BASE_BLINKING_DELAY - RAND_BLINKING_DELAY, anim_times[1] - RAND_BLINKING_DELAY), anim_times[1])
		. += wait_time
		if (anim_times && !sync_blinking)
			// Make sure that we're somewhat in sync with the other eye
			animate(time = anim_times[1] - wait_time)
			anim_times.Cut(1, 2)
		animate(alpha = 255, time = 0)
		animate(time = BLINK_DURATION)
		animate(alpha = 0, time = 0)
		animate(time = wait_time)

/obj/effect/abstract/eyelid_effect
	name = "eyelid"
	icon = 'icons/mob/human/human_face.dmi'
	layer = -BODY_LAYER
	vis_flags = VIS_INHERIT_DIR | VIS_INHERIT_PLANE | VIS_INHERIT_ID

/obj/effect/abstract/eyelid_effect/Initialize(mapload, new_state)
	. = ..()
	icon_state = new_state

#undef BASE_BLINKING_DELAY
#undef RAND_BLINKING_DELAY
#undef BLINK_DURATION
#undef BLINK_LOOPS
#undef ASYNC_BLINKING_BRAIN_DAMAGE

#define NIGHTVISION_LIGHT_OFF 0
#define NIGHTVISION_LIGHT_LOW 1
#define NIGHTVISION_LIGHT_MID 2
#define NIGHTVISION_LIGHT_HIG 3

/obj/item/organ/eyes/night_vision
	actions_types = list(/datum/action/item_action/organ_action/use)

	// These lists are used as the color cutoff for the eye
	// They need to be filled out for subtypes
	var/list/low_light_cutoff
	var/list/medium_light_cutoff
	var/list/high_light_cutoff
	var/light_level = NIGHTVISION_LIGHT_OFF

/obj/item/organ/eyes/night_vision/Initialize(mapload)
	. = ..()
	if (PERFORM_ALL_TESTS(focus_only/nightvision_color_cutoffs) && type != /obj/item/organ/eyes/night_vision)
		if(length(low_light_cutoff) != 3 || length(medium_light_cutoff) != 3 || length(high_light_cutoff) != 3)
			stack_trace("[type] did not have fully filled out color cutoff lists")
	if(low_light_cutoff)
		color_cutoffs = low_light_cutoff.Copy()
	light_level = NIGHTVISION_LIGHT_LOW

/obj/item/organ/eyes/night_vision/ui_action_click()
	sight_flags = initial(sight_flags)
	switch(light_level)
		if (NIGHTVISION_LIGHT_OFF)
			color_cutoffs = low_light_cutoff.Copy()
			light_level = NIGHTVISION_LIGHT_LOW
		if (NIGHTVISION_LIGHT_LOW)
			color_cutoffs = medium_light_cutoff.Copy()
			light_level = NIGHTVISION_LIGHT_MID
		if (NIGHTVISION_LIGHT_MID)
			color_cutoffs = high_light_cutoff.Copy()
			light_level = NIGHTVISION_LIGHT_HIG
		else
			color_cutoffs = null
			light_level = NIGHTVISION_LIGHT_OFF
	owner.update_sight()

#undef NIGHTVISION_LIGHT_OFF
#undef NIGHTVISION_LIGHT_LOW
#undef NIGHTVISION_LIGHT_MID
#undef NIGHTVISION_LIGHT_HIG

/obj/item/organ/eyes/night_vision/mushroom
	name = "fung-eye"
	desc = "While on the outside they look inert and dead, the eyes of mushroom people are actually very advanced."
	low_light_cutoff = list(0, 15, 20)
	medium_light_cutoff = list(0, 20, 35)
	high_light_cutoff = list(0, 40, 50)

/obj/item/organ/eyes/zombie
	name = "undead eyes"
	desc = "Somewhat counterintuitively, these half-rotten eyes actually have superior vision to those of a living human."
	color_cutoffs = list(25, 35, 5)

/obj/item/organ/eyes/alien
	name = "alien eyes"
	desc = "It turned out they had them after all!"
	sight_flags = SEE_MOBS
	color_cutoffs = list(25, 5, 42)

/obj/item/organ/eyes/golem
	name = "resonating crystal"
	desc = "Golems somehow measure external light levels and detect nearby ore using this sensitive mineral lattice."
	icon_state = "adamantine_cords"
	eye_icon_state = null
	blink_animation = FALSE
	iris_overlays = FALSE
	color = COLOR_GOLEM_GRAY
	visual = FALSE
	organ_flags = ORGAN_MINERAL
	color_cutoffs = list(10, 15, 5)
	actions_types = list(/datum/action/cooldown/golem_ore_sight)

/// Send an ore detection pulse on a cooldown
/datum/action/cooldown/golem_ore_sight
	name = "Ore Resonance"
	desc = "Causes nearby ores to vibrate, revealing their location."
	button_icon = 'icons/obj/devices/scanner.dmi'
	button_icon_state = "manual_mining"
	check_flags = AB_CHECK_CONSCIOUS
	cooldown_time = 10 SECONDS

/datum/action/cooldown/golem_ore_sight/Activate(atom/target)
	. = ..()
	mineral_scan_pulse(get_turf(target), scanner = target)

///Robotic

/obj/item/organ/eyes/robotic
	name = "robotic eyes"
	desc = "Your vision is augmented."
	icon_state = "cybernetic_eyeballs"
	iris_overlays = FALSE
	organ_flags = ORGAN_ROBOTIC
	failing_desc = "seems to be broken."

/obj/item/organ/eyes/robotic/emp_act(severity)
	. = ..()
	if((. & EMP_PROTECT_SELF) || !owner)
		return
	if(prob(10 * severity))
		return
	to_chat(owner, span_warning("Static obfuscates your vision!"))
	owner.flash_act(visual = 1)

/obj/item/organ/eyes/robotic/basic
	name = "basic robotic eyes"
	desc = "A pair of basic cybernetic eyes that restore vision, but at some vulnerability to light."
	eye_color_left = "5500ff"
	eye_color_right = "5500ff"
	flash_protect = FLASH_PROTECTION_SENSITIVE

/obj/item/organ/eyes/robotic/basic/emp_act(severity)
	. = ..()
	if(. & EMP_PROTECT_SELF)
		return
	if(prob(10 * severity))
		apply_organ_damage(20 * severity)
		to_chat(owner, span_warning("Your eyes start to fizzle in their sockets!"))
		do_sparks(2, TRUE, owner)
		owner.emote("scream")

/obj/item/organ/eyes/robotic/xray
	name = "x-ray eyes"
	desc = "These cybernetic eyes will give you X-ray vision. Blinking is futile."
	eye_color_left = "000"
	eye_color_right = "000"
	sight_flags = SEE_MOBS | SEE_OBJS | SEE_TURFS

/obj/item/organ/eyes/robotic/xray/on_mob_insert(mob/living/carbon/eye_owner)
	. = ..()
	ADD_TRAIT(eye_owner, TRAIT_XRAY_VISION, ORGAN_TRAIT)

/obj/item/organ/eyes/robotic/xray/on_mob_remove(mob/living/carbon/eye_owner)
	. = ..()
	REMOVE_TRAIT(eye_owner, TRAIT_XRAY_VISION, ORGAN_TRAIT)

/obj/item/organ/eyes/robotic/thermals
	name = "thermal eyes"
	desc = "These cybernetic eye implants will give you thermal vision. Vertical slit pupil included."
	eye_color_left = "FC0"
	eye_color_right = "FC0"
	// We're gonna downshift green and blue a bit so darkness looks yellow
	color_cutoffs = list(25, 8, 5)
	sight_flags = SEE_MOBS
	flash_protect = FLASH_PROTECTION_SENSITIVE

/obj/item/organ/eyes/robotic/flashlight
	name = "flashlight eyes"
	desc = "It's two flashlights rigged together with some wire. Why would you put these in someone's head?"
	eye_color_left ="fee5a3"
	eye_color_right ="fee5a3"
	icon = 'icons/obj/lighting.dmi'
	icon_state = "flashlight_eyes"
	flash_protect = FLASH_PROTECTION_WELDER
	tint = INFINITY
	var/obj/item/flashlight/eyelight/eye

/obj/item/organ/eyes/robotic/flashlight/Initialize(mapload)
	. = ..()
	AddElement(/datum/element/empprotection, EMP_PROTECT_ALL)

/obj/item/organ/eyes/robotic/flashlight/on_mob_insert(mob/living/carbon/victim)
	. = ..()
	if(!eye)
		eye = new /obj/item/flashlight/eyelight()
	eye.set_light_on(TRUE)
	eye.forceMove(victim)
	eye.update_brightness(victim)
	victim.become_blind(FLASHLIGHT_EYES)

/obj/item/organ/eyes/robotic/flashlight/on_mob_remove(mob/living/carbon/victim)
	. = ..()
	eye.set_light_on(FALSE)
	eye.update_brightness(victim)
	eye.forceMove(src)
	victim.cure_blind(FLASHLIGHT_EYES)

// Welding shield implant
/obj/item/organ/eyes/robotic/shield
	name = "shielded robotic eyes"
	desc = "These reactive micro-shields will protect you from welders and flashes without obscuring your vision."
	flash_protect = FLASH_PROTECTION_WELDER

/obj/item/organ/eyes/robotic/shield/Initialize(mapload)
	. = ..()
	AddElement(/datum/element/empprotection, EMP_PROTECT_ALL)

#define MATCH_LIGHT_COLOR 1
#define USE_CUSTOM_COLOR 0
#define UPDATE_LIGHT 0
#define UPDATE_EYES_LEFT 1
#define UPDATE_EYES_RIGHT 2

/obj/item/organ/eyes/robotic/glow
	name = "high luminosity eyes"
	desc = "Special glowing eyes, used by snowflakes who want to be special."
	eye_color_left = "000"
	eye_color_right = "000"
	actions_types = list(/datum/action/item_action/organ_action/use, /datum/action/item_action/organ_action/toggle)
	var/max_light_beam_distance = 5
	var/obj/item/flashlight/eyelight/glow/eye
	/// base icon state for eye overlays
	var/base_eye_state = "eyes_glow_gs"
	/// Whether or not to match the eye color to the light or use a custom selection
	var/eye_color_mode = USE_CUSTOM_COLOR
	/// The selected color for the light beam itself
	var/light_color_string = "#ffffff"
	/// The custom selected eye color for the left eye. Defaults to the mob's natural eye color
	var/left_eye_color_string
	/// The custom selected eye color for the right eye. Defaults to the mob's natural eye color
	var/right_eye_color_string

/obj/item/organ/eyes/robotic/glow/Initialize(mapload)
	. = ..()
	eye = new /obj/item/flashlight/eyelight/glow

/obj/item/organ/eyes/robotic/glow/Destroy()
	. = ..()
	deactivate(close_ui = TRUE)
	QDEL_NULL(eye)

/obj/item/organ/eyes/robotic/glow/emp_act(severity)
	. = ..()
	if(!eye.light_on || . & EMP_PROTECT_SELF)
		return
	deactivate(close_ui = TRUE)

/// Set the initial color of the eyes on insert to be the mob's previous eye color.
/obj/item/organ/eyes/robotic/glow/on_mob_insert(mob/living/carbon/eye_recipient, special = FALSE, movement_flags)
	. = ..()
	left_eye_color_string = eye_color_left
	right_eye_color_string = eye_color_right
	update_mob_eye_color(eye_recipient)
	deactivate(close_ui = TRUE)
	eye.forceMove(eye_recipient)

/obj/item/organ/eyes/robotic/glow/on_mob_remove(mob/living/carbon/eye_owner)
	deactivate(eye_owner, close_ui = TRUE)
	if(!QDELETED(eye))
		eye.forceMove(src)
	return ..()

/obj/item/organ/eyes/robotic/glow/ui_state(mob/user)
	return GLOB.default_state

/obj/item/organ/eyes/robotic/glow/ui_status(mob/user, datum/ui_state/state)
	if(!QDELETED(owner))
		if(owner == user)
			return min(
				ui_status_user_is_abled(user, src),
				ui_status_only_living(user),
			)
		else return UI_CLOSE
	return ..()

/obj/item/organ/eyes/robotic/glow/ui_interact(mob/user, datum/tgui/ui)
	ui = SStgui.try_update_ui(user, src, ui)
	if(!ui)
		ui = new(user, src, "HighLuminosityEyesMenu")
		ui.autoupdate = FALSE
		ui.open()

/obj/item/organ/eyes/robotic/glow/ui_data(mob/user)
	var/list/data = list()

	data["eyeColor"] = list(
		mode = eye_color_mode,
		hasOwner = owner ? TRUE : FALSE,
		left = left_eye_color_string,
		right = right_eye_color_string,
	)
	data["lightColor"] = light_color_string
	data["range"] = eye.light_range

	return data

/obj/item/organ/eyes/robotic/glow/ui_act(action, list/params, datum/tgui/ui)
	. = ..()
	if(.)
		return

	switch(action)
		if("set_range")
			var/new_range = params["new_range"]
			set_beam_range(new_range)
			return TRUE
		if("pick_color")
			var/new_color = input(
				usr,
				"Choose eye color color:",
				"High Luminosity Eyes Menu",
				light_color_string
			) as color|null
			if(new_color)
				var/to_update = params["to_update"]
				set_beam_color(new_color, to_update)
				return TRUE
		if("enter_color")
			var/new_color = LOWER_TEXT(params["new_color"])
			var/to_update = params["to_update"]
			set_beam_color(new_color, to_update, sanitize = TRUE)
			return TRUE
		if("random_color")
			var/to_update = params["to_update"]
			randomize_color(to_update)
			return TRUE
		if("toggle_eye_color")
			toggle_eye_color_mode()
			return TRUE

/obj/item/organ/eyes/robotic/glow/ui_action_click(mob/user, action)
	if(istype(action, /datum/action/item_action/organ_action/toggle))
		toggle_active()
	else if(istype(action, /datum/action/item_action/organ_action/use))
		ui_interact(user)

/**
 * Activates the light
 *
 * Turns on the attached flashlight object, updates the mob overlay to be added.
 */
/obj/item/organ/eyes/robotic/glow/proc/activate()
	if(eye.light_range)
		eye.set_light_on(TRUE)
	else
		eye.light_on = TRUE // at range 0 we are just going to make the eyes glow emissively, no light overlay
	update_mob_eye_color()

/**
 * Deactivates the light
 *
 * Turns off the attached flashlight object, closes UIs, updates the mob overlay to be removed.
 * Arguments:
 * * mob/living/carbon/eye_owner - the mob who the eyes belong to
 * * close_ui - whether or not to close the ui
 */
/obj/item/organ/eyes/robotic/glow/proc/deactivate(mob/living/carbon/eye_owner = owner, close_ui = FALSE)
	if(close_ui)
		SStgui.close_uis(src)
	eye.set_light_on(FALSE)
	update_mob_eye_color(eye_owner)

/**
 * Randomizes the light color
 *
 * Picks a random color and sets the beam color to that
 * Arguments:
 * * to_update - whether we are setting the color for the light beam itself, or the individual eyes
 */
/obj/item/organ/eyes/robotic/glow/proc/randomize_color(to_update = UPDATE_LIGHT)
	var/new_color = "#"
	for(var/i in 1 to 3)
		new_color += num2hex(rand(0, 255), 2)
	set_beam_color(new_color, to_update)

/**
 * Setter function for the light's range
 *
 * Sets the light range of the attached flashlight object
 * Includes some 'unique' logic to accomodate for some quirks of the lighting system
 * Arguments:
 * * new_range - the new range to set
 */
/obj/item/organ/eyes/robotic/glow/proc/set_beam_range(new_range)
	var/old_light_range = eye.light_range
	if(old_light_range == 0 && new_range > 0 && eye.light_on) // turn bring back the light overlay if we were previously at 0 (aka emissive eyes only)
		eye.light_on = FALSE // this is stupid, but this has to be FALSE for set_light_on() to work.
		eye.set_light_on(TRUE)
	eye.set_light_range(clamp(new_range, 0, max_light_beam_distance))

/**
 * Setter function for the light's color
 *
 * Sets the light color of the attached flashlight object. Sets the eye color vars of this eye organ as well and then updates the mob's eye color.
 * Arguments:
 * * newcolor - the new color hex string to set
 * * to_update - whether we are setting the color for the light beam itself, or the individual eyes
 * * sanitize - whether the hex string should be sanitized
 */
/obj/item/organ/eyes/robotic/glow/proc/set_beam_color(newcolor, to_update = UPDATE_LIGHT, sanitize = FALSE)
	var/newcolor_string
	if(sanitize)
		newcolor_string = sanitize_hexcolor(newcolor)
	else
		newcolor_string = newcolor
	switch(to_update)
		if(UPDATE_LIGHT)
			light_color_string = newcolor_string
			eye.set_light_color(newcolor_string)
		if(UPDATE_EYES_LEFT)
			left_eye_color_string = newcolor_string
		if(UPDATE_EYES_RIGHT)
			right_eye_color_string = newcolor_string

	update_mob_eye_color()

/**
 * Toggle the attached flashlight object on or off
 */
/obj/item/organ/eyes/robotic/glow/proc/toggle_active()
	if(eye.light_on)
		deactivate()
	else
		activate()

/**
 * Toggles for the eye color mode
 *
 * Toggles the eye color mode on or off and then calls an update on the mob's eye color
 */
/obj/item/organ/eyes/robotic/glow/proc/toggle_eye_color_mode()
	eye_color_mode = !eye_color_mode
	update_mob_eye_color()

/**
 * Updates the mob eye color
 *
 * Updates the eye color to reflect on the mob's body if it's possible to do so
 * Arguments:
 * * mob/living/carbon/eye_owner - the mob to update the eye color appearance of
 */
/obj/item/organ/eyes/robotic/glow/proc/update_mob_eye_color(mob/living/carbon/eye_owner = owner)
	switch(eye_color_mode)
		if(MATCH_LIGHT_COLOR)
			eye_color_left = light_color_string
			eye_color_right = light_color_string
		if(USE_CUSTOM_COLOR)
			eye_color_left = left_eye_color_string
			eye_color_right = right_eye_color_string

	if(QDELETED(eye_owner) || !ishuman(eye_owner)) //Other carbon mobs don't have eye color.
		return

	if(!eye.light_on)
		eye_icon_state = initial(eye_icon_state)
		overlay_ignore_lighting = FALSE
	else
		overlay_ignore_lighting = TRUE
		eye_icon_state = base_eye_state

	var/obj/item/bodypart/head/head = eye_owner.get_bodypart(BODY_ZONE_HEAD) //if we have eyes we definently have a head anyway
	var/previous_flags = head.head_flags
	head.head_flags = previous_flags | HEAD_EYECOLOR
	eye_owner.dna.species.handle_body(eye_owner)
	head.head_flags = previous_flags

#undef MATCH_LIGHT_COLOR
#undef USE_CUSTOM_COLOR
#undef UPDATE_LIGHT
#undef UPDATE_EYES_LEFT
#undef UPDATE_EYES_RIGHT

/obj/item/organ/eyes/moth
	name = "moth eyes"
	desc = "These eyes seem to have increased sensitivity to bright light, with no improvement to low light vision."
	icon_state = "eyeballs-moth"
	eye_icon_state = "motheyes"
	blink_animation = FALSE
	iris_overlays = FALSE
	flash_protect = FLASH_PROTECTION_SENSITIVE

/obj/item/organ/eyes/robotic/moth
	name = "robotic moth eyes"
	desc = "Your vision is augmented. Much like actual moth eyes, very sensitive to bright lights."
	icon_state = "eyeballs-cybermoth"
	eye_icon_state = "motheyes"
	blink_animation = FALSE
	flash_protect = FLASH_PROTECTION_SENSITIVE

/obj/item/organ/eyes/robotic/basic/moth
	name = "basic robotic moth eyes"
	icon_state = "eyeballs-cybermoth"
	eye_icon_state = "motheyes"
	blink_animation = FALSE
	flash_protect = FLASH_PROTECTION_SENSITIVE

/obj/item/organ/eyes/robotic/xray/moth
	name = "moth x-ray eyes"
	desc = "These cybernetic imitation moth eyes will give you X-ray vision. Blinking is futile. Much like actual moth eyes, very sensitive to bright lights."
	icon_state = "eyeballs-cybermoth"
	eye_icon_state = "motheyes"
	blink_animation = FALSE
	flash_protect = FLASH_PROTECTION_SENSITIVE

/obj/item/organ/eyes/robotic/shield/moth
	name = "shielded robotic moth eyes"
	icon_state = "eyeballs-cybermoth"
	eye_icon_state = "motheyes"
	blink_animation = FALSE

/obj/item/organ/eyes/robotic/glow/moth
	name = "high luminosity moth eyes"
	desc = "Special glowing eyes, to be one with the lamp. Much like actual moth eyes, very sensitive to bright lights."
	icon_state = "eyeballs-cybermoth"
	eye_icon_state = "motheyes"
	blink_animation = FALSE
	base_eye_state = "eyes_mothglow"
	flash_protect = FLASH_PROTECTION_SENSITIVE

/obj/item/organ/eyes/robotic/thermals/moth //we inherit flash weakness from thermals
	name = "thermal moth eyes"
	icon_state = "eyeballs-cybermoth"
	eye_icon_state = "motheyes"
	blink_animation = FALSE

/obj/item/organ/eyes/snail
	name = "snail eyes"
	desc = "These eyes seem to have a large range, but might be cumbersome with glasses."
	icon_state = "snail_eyeballs"
	eye_icon_state = "snail_eyes"
	blink_animation = FALSE
	iris_overlays = FALSE

/obj/item/organ/eyes/jelly
	name = "jelly eyes"
	desc = "These eyes are made of a soft jelly. Unlike all other eyes, though, there are three of them."
	icon_state = "eyeballs-jelly"
	eye_icon_state = "jelleyes"
	blink_animation = FALSE
	iris_overlays = FALSE

/obj/item/organ/eyes/lizard
	name = "reptile eyes"
	desc = "A pair of reptile eyes with thin vertical slits for pupils."
	icon_state = "lizard_eyes"
	synchronized_blinking = FALSE

/obj/item/organ/eyes/night_vision/maintenance_adapted
	name = "adapted eyes"
	desc = "These red eyes look like two foggy marbles. They give off a particularly worrying glow in the dark."
	flash_protect = FLASH_PROTECTION_HYPER_SENSITIVE
	eye_color_left = "f00"
	eye_color_right = "f00"
	icon_state = "adapted_eyes"
	eye_icon_state = "eyes_glow"
	iris_overlays = FALSE
	overlay_ignore_lighting = TRUE
	low_light_cutoff = list(5, 12, 20)
	medium_light_cutoff = list(15, 20, 30)
	high_light_cutoff = list(30, 35, 50)

/obj/item/organ/eyes/night_vision/maintenance_adapted/on_mob_insert(mob/living/carbon/eye_owner)
	. = ..()
	ADD_TRAIT(eye_owner, TRAIT_UNNATURAL_RED_GLOWY_EYES, ORGAN_TRAIT)

/obj/item/organ/eyes/night_vision/maintenance_adapted/on_life(seconds_per_tick, times_fired)
	if(!owner.is_blind() && isturf(owner.loc) && owner.has_light_nearby(light_amount=0.5)) //we allow a little more than usual so we can produce light from the adapted eyes
		to_chat(owner, span_danger("Your eyes! They burn in the light!"))
		apply_organ_damage(10) //blind quickly
		playsound(owner, 'sound/machines/grill/grillsizzle.ogg', 50)
	else
		apply_organ_damage(-10) //heal quickly
	. = ..()

/obj/item/organ/eyes/night_vision/maintenance_adapted/on_mob_remove(mob/living/carbon/unadapted, special = FALSE, movement_flags)
	REMOVE_TRAIT(unadapted, TRAIT_UNNATURAL_RED_GLOWY_EYES, ORGAN_TRAIT)
	return ..()

/obj/item/organ/eyes/pod
	name = "pod eyes"
	desc = "Strangest salad you've ever seen."
	foodtype_flags = PODPERSON_ORGAN_FOODTYPES
