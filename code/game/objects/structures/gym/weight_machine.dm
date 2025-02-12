#define WORKOUT_XP 5
#define EXERCISE_STATUS_DURATION 15 SECONDS
#define SAFE_DRUNK_LEVEL 39

/obj/structure/weightmachine
	name = "chest press machine"
	desc = "Just looking at this thing makes you feel tired."
	icon = 'icons/obj/fluff/gym_equipment.dmi'
	icon_state = "stacklifter"
	base_icon_state = "stacklifter"
	can_buckle = TRUE
	density = TRUE
	anchored = TRUE
	blocks_emissive = EMISSIVE_BLOCK_UNIQUE

	///How much we shift the user's pixel y when using the weight machine.
	var/pixel_shift_z = -3

	///The weight action we give to people that buckle themselves to us.
	var/datum/action/push_weights/weight_action

	///message when drunk user fails to use the machine
	var/drunk_message = "You try for a new record and pull through! Through a muscle that is."

	// the total reps you can do before you hit stamcrit based on fitness level
	var/static/list/total_workout_reps = list(3, 4, 4, 5, 6, 6, 7)

	///List of messages picked when using the machine.
	var/static/list/more_weight = list(
		"pushing it to the limit!",
		"going into overdrive!",
		"burning with determination!",
		"rising up to the challenge!",
		"getting strong now!",
		"getting ripped!",
	)
	///List of messages picked when finished using the machine.
	var/static/list/finished_message = list(
		"You feel stronger!",
		"You feel like you can take on the world!",
		"You feel robust!",
		"You feel indestructible!",
	)
	var/static/list/finished_silicon_message = list(
		"You feel nothing!",
		"No pain, no gain!",
		"Chassis hardness rating... Unchanged.",
		"You feel the exact same. Nothing.",
	)

/obj/structure/weightmachine/Initialize(mapload)
	. = ..()

	weight_action = new(src)
	weight_action.weightpress = src

	var/static/list/tool_behaviors
	if(!tool_behaviors)
		tool_behaviors = string_assoc_nested_list(list(
			TOOL_CROWBAR = list(
				SCREENTIP_CONTEXT_RMB = "Deconstruct",
			),

			TOOL_WRENCH = list(
				SCREENTIP_CONTEXT_RMB = "Anchor",
			),
		))
	AddElement(/datum/element/contextual_screentip_tools, tool_behaviors)

/obj/structure/weightmachine/Destroy()
	QDEL_NULL(weight_action)
	return ..()

/obj/structure/weightmachine/buckle_mob(mob/living/buckled, force, check_loc)
	. = ..()
	weight_action.Grant(buckled)

/obj/structure/weightmachine/unbuckle_mob(mob/living/buckled_mob, force, can_fall)
	. = ..()
	weight_action.Remove(buckled_mob)

/obj/structure/weightmachine/wrench_act_secondary(mob/living/user, obj/item/tool)
	tool.play_tool_sound(src)
	balloon_alert(user, anchored ? "unsecured" : "secured")
	anchored = !anchored
	return TRUE

/obj/structure/weightmachine/crowbar_act_secondary(mob/living/user, obj/item/tool)
	if(anchored)
		balloon_alert(user, "still secured!")
		return FALSE
	tool.play_tool_sound(src)
	balloon_alert(user, "deconstructing...")
	if (!do_after(user, 10 SECONDS, target = src))
		return FALSE
	new /obj/item/stack/sheet/iron(get_turf(src), 5)
	new /obj/item/stack/rods(get_turf(src), 2)
	new /obj/item/chair(get_turf(src))
	qdel(src)
	return TRUE

/obj/structure/weightmachine/proc/perform_workout(mob/living/user)
	if(user.nutrition <= NUTRITION_LEVEL_STARVING)
		user.balloon_alert(user, "too hungry to workout!")
		return

	user.balloon_alert_to_viewers("[pick(more_weight)]")
	START_PROCESSING(SSobj, src)

	if(do_after(user, 8 SECONDS, src) && user.has_gravity())
		// with enough dedication, even clowns can overcome their handicaps
		var/clumsy_chance = 30 - (user.mind.get_skill_level(/datum/skill/athletics) * 5)
		if(HAS_TRAIT(user, TRAIT_CLUMSY) && prob(clumsy_chance))
			playsound(src, 'sound/effects/bang.ogg', 50, TRUE)
			to_chat(user, span_warning("Your hand slips, causing \the [src] to smash you!"))
			user.take_bodypart_damage(rand(2, 5))
			end_workout()
			return

		// awlways a chance for a person not to fail horribly when drunk
		if(user.get_drunk_amount() > SAFE_DRUNK_LEVEL && prob(min(user.get_drunk_amount(), 99)))
			playsound(src,'sound/effects/bang.ogg', 50, TRUE)
			to_chat(user, span_warning(drunk_message))
			user.take_bodypart_damage(rand(5, 10), wound_bonus = 10)
			end_workout()
			return

		if(issilicon(user))
			user.balloon_alert(user, pick(finished_silicon_message))
		else
			user.balloon_alert(user, pick(finished_message))

		user.adjust_nutrition(-5) // feel the burn

		if(iscarbon(user))
			var/gravity_modifier = user.has_gravity() > STANDARD_GRAVITY ? 2 : 1
			// remember the real xp gain is from sleeping after working out
			user.mind.adjust_experience(/datum/skill/athletics, WORKOUT_XP * gravity_modifier)
			user.apply_status_effect(/datum/status_effect/exercised, EXERCISE_STATUS_DURATION)

	end_workout()

/obj/structure/weightmachine/proc/end_workout()
	playsound(src, 'sound/machines/click.ogg', 60, TRUE)
	STOP_PROCESSING(SSobj, src)
	icon_state = initial(icon_state)

/// roughly 8 seconds for 1 workout rep
#define WORKOUT_LENGTH 8

/obj/structure/weightmachine/process(seconds_per_tick)
	if(!has_buckled_mobs())
		end_workout()
		return FALSE
	var/mutable_appearance/workout = mutable_appearance(icon, "[base_icon_state]-o", ABOVE_MOB_LAYER, src, appearance_flags = KEEP_APART)
	workout = color_atom_overlay(workout)
	flick_overlay_view(workout, 0.8 SECONDS)
	flick("[base_icon_state]-u", src)
	var/mob/living/user = buckled_mobs[1]
	animate(user, pixel_z = pixel_shift_z, time = WORKOUT_LENGTH * 0.5, flags = ANIMATION_PARALLEL|ANIMATION_RELATIVE)
	animate(pixel_z = -pixel_shift_z, time = WORKOUT_LENGTH * 0.5, flags = ANIMATION_PARALLEL)
	playsound(user, 'sound/machines/creak.ogg', 60, TRUE)

	if(!iscarbon(user) || isnull(user.mind))
		return TRUE

	var/affected_gravity = user.has_gravity()
	if (!affected_gravity)
		return TRUE // No weight? I could do this all day
	var/gravity_modifier = affected_gravity > STANDARD_GRAVITY ? 0.75 : 1
	// the amount of workouts you can do before you hit stamcrit
	var/workout_reps = total_workout_reps[user.mind.get_skill_level(/datum/skill/athletics)] * gravity_modifier
	// total stamina drain of 1 workout calculated based on the workout length
	var/stamina_exhaustion = FLOOR(user.maxHealth / workout_reps / WORKOUT_LENGTH, 0.1)

	var/obj/item/organ/cyberimp/chest/spine/potential_spine = user.get_organ_slot(ORGAN_SLOT_SPINE)
	if(istype(potential_spine))
		stamina_exhaustion *= potential_spine.athletics_boost_multiplier

	if(HAS_TRAIT(user, TRAIT_STRENGTH)) //The strong get reductions to stamina damage taken while exercising
		stamina_exhaustion *= 0.5

	user.adjustStaminaLoss(stamina_exhaustion * seconds_per_tick)

	return TRUE

#undef WORKOUT_LENGTH

/**
 * Weight lifter subtype
 */
/obj/structure/weightmachine/weightlifter
	name = "incline bench press"
	icon_state = "benchpress"
	base_icon_state = "benchpress"

	pixel_shift_z = 5

	drunk_message = "You raise the bar over you trying to balance it with one hand, keyword tried."

#undef WORKOUT_XP
#undef EXERCISE_STATUS_DURATION
#undef SAFE_DRUNK_LEVEL
