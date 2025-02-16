/// For scaling the effectiveness of certain effects to the total bodypart count
#define GET_BODYPART_COEFFICIENT(X) round(X.len / BODYPARTS_DEFAULT_MAXIMUM , 0.1)
/// Check if it's full body. These are mostly here so we can change just one place when we ever add more limbs (?)
#define IS_FULL_BODY(X) (X.len == BODYPARTS_DEFAULT_MAXIMUM )

/// Effects added to a carbon focused on the bodyparts itself, such as adding a photosynthesis component that
/datum/status_effect/bodypart_effect
	id = "bodypart_effect"
	duration = STATUS_EFFECT_PERMANENT
	tick_interval = STATUS_EFFECT_NO_TICK
	alert_type = null

	/// List of bodyparts contributing to this effect
	var/list/bodyparts = list()
	/// Minimum amount of bodyparts required for on_apply to be called. When tipping below, on_remove is called
	var/minimum_bodyparts = 1
	/// Are we currently active? We don't NEED to track it, but it's a lot easier and faster if we do
	var/is_active = FALSE

/datum/status_effect/bodypart_effect/on_creation(mob/living/new_owner, obj/item/bodypart/bodypart)
	. = ..()

	add_bodypart(bodypart)

/// Merge a bodypart into the effect
/datum/status_effect/bodypart_effect/proc/add_bodypart(bodypart)
	RegisterSignal(bodypart, COMSIG_BODYPART_REMOVED, PROC_REF(on_bodypart_removed))
	RegisterSignal(bodypart, COMSIG_QDELETING, PROC_REF(on_bodypart_destroyed))

	bodyparts.Add(bodypart)

	if(!is_active && bodyparts.len >= minimum_bodyparts)
		activate()

/// Remove a bodypart from the effect. Deleting = TRUE is used during clean-up phase
/datum/status_effect/bodypart_effect/proc/remove_bodypart(obj/item/bodypart/bodypart, deleting = FALSE)
	UnregisterSignal(bodypart, COMSIG_BODYPART_REMOVED)

	bodyparts.Remove(bodypart)

	if(deleting)
		return

	if(bodyparts.len == 0)
		qdel(src)

	else if(is_active && bodyparts.len < minimum_bodyparts)
		deactivate()

/// Signal called when a bodypart is removed
/datum/status_effect/bodypart_effect/proc/on_bodypart_removed(obj/item/bodypart/bodypart)
	SIGNAL_HANDLER

	remove_bodypart(owner, bodypart)

/// Signal called when a bodypart is destroyed. Destruction of a bodypart doesn't necessarily drop it
/datum/status_effect/bodypart_effect/proc/on_bodypart_destroyed(obj/item/bodypart/bodypart)
	SIGNAL_HANDLER

	remove_bodypart(bodypart)

/// Activate some sort of effect when a threshold is reached
/datum/status_effect/bodypart_effect/proc/activate()
	PROTECTED_PROC(TRUE)
	SHOULD_CALL_PARENT(TRUE)

	is_active = TRUE
	// Maybe add support for different stages? AKA add a stronger effect when there are more limbs

/// Remove an effect whenever a threshold is no longer reached
/datum/status_effect/bodypart_effect/proc/deactivate()
	PROTECTED_PROC(TRUE)
	SHOULD_CALL_PARENT(TRUE)

	is_active = FALSE

/// Clean up all references and self-destruct
/datum/status_effect/bodypart_effect/Destroy()
	deactivate()
	for(var/obj/item/bodypart/bodypart as anything in bodyparts)
		remove_bodypart(bodypart, deleting = TRUE)

	return ..()

/// This limb regens in light! Only BODYTYPE_PLANT limbs will heal, but limbs without the flag (and with the effect) still contribute to healing of the other limbs
/datum/status_effect/bodypart_effect/photosynthesis
	processing_speed = STATUS_EFFECT_NORMAL_PROCESS
	id = "photosynthesis"

/datum/status_effect/bodypart_effect/photosynthesis/tick(seconds_between_ticks)
	var/light_amount = 0 //how much light there is in the place, affects receiving nutrition and healing
	var/bodypart_coefficient = GET_BODYPART_COEFFICIENT(bodyparts)

	if(isturf(owner.loc)) //else, there's considered to be no light
		var/turf/turf_loc = owner.loc
		light_amount = min(1, turf_loc.get_lumcount()) - 0.5

		if(owner.nutrition < NUTRITION_LEVEL_ALMOST_FULL)
			owner.adjust_nutrition(2.5 * light_amount * bodypart_coefficient)

		if(light_amount > 0.2) //if there's enough light, heal
			var/need_mob_update = FALSE
			need_mob_update += owner.heal_overall_damage(brute = 0.25 * bodypart_coefficient, \
				burn = 0.25 * bodypart_coefficient, updating_health = FALSE, required_bodytype = BODYTYPE_PLANT)
			need_mob_update += owner.adjustToxLoss(-0.25 * bodypart_coefficient, updating_health = FALSE)
			need_mob_update += owner.adjustOxyLoss(-0.25 * bodypart_coefficient, updating_health = FALSE)
			if(need_mob_update)
				owner.updatehealth()

	if(owner.nutrition < NUTRITION_LEVEL_STARVING + 50)
		owner.take_overall_damage(brute = 0.5 * bodypart_coefficient, required_bodytype = BODYTYPE_PLANT)

/// This limb heals in darkness and dies in light!
/// Only BODYTYPE_SHADOW limbs will heal, but limbs without the flag (and with the effect) still contribute to healing of the other limbs
/datum/status_effect/bodypart_effect/nyxosynthesis
	processing_speed = STATUS_EFFECT_NORMAL_PROCESS
	id = "nyxosynthesis"

/datum/status_effect/bodypart_effect/nyxosynthesis/tick(seconds_between_ticks)
	var/turf/owner_turf = owner.loc
	if(!isturf(owner_turf))
		return
	var/light_amount = owner_turf.get_lumcount()

	var/bodypart_coefficient = GET_BODYPART_COEFFICIENT(bodyparts)

	if (light_amount < SHADOW_SPECIES_LIGHT_THRESHOLD) //heal in the dark
		owner.heal_overall_damage(brute = 0.5 * bodypart_coefficient, burn = 0.5 * bodypart_coefficient, required_bodytype = BODYTYPE_SHADOW)
		if(!owner.has_status_effect(/datum/status_effect/shadow/nightmare)) //somewhat awkward, but let's not duplicate the alerts
			//this only appears when in shadows, don't move to bodypart effect so people with nightvision can still tell if they're in light or not
			owner.apply_status_effect(/datum/status_effect/shadow)
	else
		owner.take_overall_damage(brute = 0.25 * bodypart_coefficient, burn = 0.25 * bodypart_coefficient, required_bodytype = BODYTYPE_SHADOW)

#undef GET_BODYPART_COEFFICIENT
#undef IS_FULL_BODY
