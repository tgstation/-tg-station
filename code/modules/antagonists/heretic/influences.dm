
/// The number of influences spawned per heretic
#define NUM_INFLUENCES_PER_HERETIC 5

/**
 * #Reality smash tracker
 *
 * A global singleton data that tracks all the heretic
 * influences ("reality smashes") that we've created,
 * and all of the heretics (minds) that can see them.
 *
 * Handles ensuring all minds can see influences, generating
 * new influences for new heretic minds, and allowing heretics
 * to see new influences that are created.
 */
/datum/reality_smash_tracker
	/// The total number of influences that have been drained, for tracking.
	var/num_drained = 0
	/// List of tracked influences (reality smashes)
	var/list/obj/effect/heretic_influence/smashes = list()
	/// List of minds with the ability to see influences
	var/list/datum/mind/tracked_heretics = list()

/datum/reality_smash_tracker/Destroy(force)
	if(GLOB.reality_smash_track == src)
		stack_trace("[type] was deleted. Heretics may no longer access any influences. Fix it, or call coder support.")
		message_admins("The [type] was deleted. Heretics may no longer access any influences. Fix it, or call coder support.")
	QDEL_LIST(smashes)
	tracked_heretics.Cut()
	return ..()

/**
 * Generates a set amount of reality smashes
 * based on the number of already existing smashes
 * and the number of minds we're tracking.
 */
/datum/reality_smash_tracker/proc/generate_new_influences()
	var/how_many_can_we_make = 0
	for(var/heretic_number in 1 to length(tracked_heretics))
		how_many_can_we_make += max(NUM_INFLUENCES_PER_HERETIC - heretic_number + 1, 1)

	var/location_sanity = 0
	while((length(smashes) + num_drained) < how_many_can_we_make && location_sanity < 100)
		var/turf/chosen_location = get_safe_random_station_turf_equal_weight()

		// We don't want them close to each other - at least 1 tile of separation
		var/list/nearby_things = range(1, chosen_location)
		var/obj/effect/heretic_influence/what_if_i_have_one = locate() in nearby_things
		var/obj/effect/visible_heretic_influence/what_if_i_had_one_but_its_used = locate() in nearby_things
		if(what_if_i_have_one || what_if_i_had_one_but_its_used)
			location_sanity++
			continue

		new /obj/effect/heretic_influence(chosen_location)

/**
 * Adds a mind to the list of people that can see the reality smashes
 *
 * Use this whenever you want to add someone to the list
 */
/datum/reality_smash_tracker/proc/add_tracked_mind(datum/mind/heretic)
	tracked_heretics |= heretic

	// If our heretic's on station, generate some new influences
	if(ishuman(heretic.current) && !is_centcom_level(heretic.current.z))
		generate_new_influences()

/**
 * Removes a mind from the list of people that can see the reality smashes
 *
 * Use this whenever you want to remove someone from the list
 */
/datum/reality_smash_tracker/proc/remove_tracked_mind(datum/mind/heretic)
	tracked_heretics -= heretic

/obj/effect/visible_heretic_influence
	name = "pierced reality"
	icon = 'icons/effects/eldritch.dmi'
	icon_state = "pierced_illusion"
	anchored = TRUE
	interaction_flags_atom = INTERACT_ATOM_NO_FINGERPRINT_ATTACK_HAND|INTERACT_ATOM_NO_FINGERPRINT_INTERACT
	resistance_flags = FIRE_PROOF | UNACIDABLE | ACID_PROOF
	alpha = 0

/obj/effect/visible_heretic_influence/Initialize(mapload)
	. = ..()
	addtimer(CALLBACK(src, PROC_REF(show_presence)), 15 SECONDS)
	AddComponent(/datum/component/fishing_spot, GLOB.preset_fish_sources[/datum/fish_source/dimensional_rift])

	var/image/silicon_image = image('icons/effects/eldritch.dmi', src, null, OBJ_LAYER)
	silicon_image.override = TRUE
	add_alt_appearance(/datum/atom_hud/alternate_appearance/basic/silicons, "pierced_reality", silicon_image)

/*
 * Makes the influence fade in after 15 seconds.
 */
/obj/effect/visible_heretic_influence/proc/show_presence()
	animate(src, alpha = 255, time = 15 SECONDS)

/obj/effect/visible_heretic_influence/attack_hand(mob/living/user, list/modifiers)
	. = ..()
	if(.)
		return
	if(!ishuman(user))
		return

	if(IS_HERETIC(user))
		to_chat(user, span_boldwarning("You know better than to tempt forces out of your control!"))
		return TRUE

	var/mob/living/carbon/human/human_user = user
	var/obj/item/bodypart/their_poor_arm = human_user.get_active_hand()
	if(prob(25))
		to_chat(human_user, span_userdanger("An otherwordly presence tears and atomizes your [their_poor_arm.name] as you try to touch the hole in the very fabric of reality!"))
		their_poor_arm.dismember()
		forceMove(their_poor_arm, src) // stored for later fishage
	else
		to_chat(human_user,span_danger("You pull your hand away from the hole as the eldritch energy flails, trying to latch onto existence itself!"))
	return TRUE

/obj/effect/visible_heretic_influence/attack_tk(mob/user)
	if(!ishuman(user))
		return

	. = COMPONENT_CANCEL_ATTACK_CHAIN

	if(IS_HERETIC(user))
		to_chat(user, span_boldwarning("You know better than to tempt forces out of your control!"))
		return

	var/mob/living/carbon/human/human_user = user

	// You see, these tendrils are psychic. That's why you can't see them. Definitely not laziness. Just psychic. The character can feel but not see them.
	// Because they're psychic. Yeah.
	if(human_user.can_block_magic(MAGIC_RESISTANCE_MIND))
		visible_message(span_danger("Psychic endrils lash out from [src], batting ineffectively at [user]'s head."))
		return

	// A very elaborate way to suicide
	visible_message(span_userdanger("Psychic tendrils lash out from [src], psychically grabbing onto [user]'s psychically sensitive mind and tearing [user.p_their()] head off!"))
	var/obj/item/bodypart/head/head = locate() in human_user.bodyparts
	if(head)
		head.dismember()
		forceMove(head, src) // stored for later fishage
	else
		human_user.gib(DROP_ALL_REMAINS)
	human_user.investigate_log("has died from using telekinesis on a heretic influence.", INVESTIGATE_DEATHS)
	var/datum/effect_system/reagents_explosion/explosion = new()
	explosion.set_up(1, get_turf(human_user), TRUE, 0)
	explosion.start(src)

/obj/effect/visible_heretic_influence/examine(mob/user)
	. = ..()
	if(IS_HERETIC(user) || !ishuman(user))
		return

	var/mob/living/carbon/human/human_user = user
	to_chat(human_user, span_userdanger("Your mind burns as you stare at the tear!"))
	human_user.adjustOrganLoss(ORGAN_SLOT_BRAIN, 10, 190)
	human_user.add_mood_event("gates_of_mansus", /datum/mood_event/gates_of_mansus)

/obj/effect/heretic_influence
	name = "reality smash"
	icon = 'icons/effects/eldritch.dmi'
	anchored = TRUE
	interaction_flags_atom = INTERACT_ATOM_NO_FINGERPRINT_ATTACK_HAND|INTERACT_ATOM_NO_FINGERPRINT_INTERACT
	resistance_flags = FIRE_PROOF | UNACIDABLE | ACID_PROOF
	invisibility = INVISIBILITY_OBSERVER
	/// Whether we're currently being drained or not.
	var/being_drained = FALSE
	/// The icon state applied to the image created for this influence.
	var/real_icon_state = "reality_smash"

/obj/effect/heretic_influence/Initialize(mapload)
	. = ..()
	GLOB.reality_smash_track.smashes += src
	generate_name()

	var/image/heretic_image = image(icon, src, real_icon_state, OBJ_LAYER)
	add_alt_appearance(/datum/atom_hud/alternate_appearance/basic/has_antagonist/heretic, "reality_smash", heretic_image)

	AddElement(/datum/element/block_turf_fingerprints)
	AddComponent(/datum/component/redirect_attack_hand_from_turf, interact_check = CALLBACK(src, PROC_REF(verify_user_can_see)))
	AddComponent(/datum/component/fishing_spot, GLOB.preset_fish_sources[/datum/fish_source/dimensional_rift])

/obj/effect/heretic_influence/proc/verify_user_can_see(mob/user)
	return (user.mind in GLOB.reality_smash_track.tracked_heretics)

/obj/effect/heretic_influence/Destroy()
	GLOB.reality_smash_track.smashes -= src
	return ..()

/obj/effect/heretic_influence/attack_hand_secondary(mob/user, list/modifiers)
	if(!IS_HERETIC(user)) // Shouldn't be able to do this, but just in case
		return SECONDARY_ATTACK_CALL_NORMAL

	if(being_drained)
		loc.balloon_alert(user, "already being drained!")
	else
		INVOKE_ASYNC(src, PROC_REF(drain_influence), user, 1)

	return SECONDARY_ATTACK_CANCEL_ATTACK_CHAIN

/obj/effect/heretic_influence/attackby(obj/item/weapon, mob/user, params)
	. = ..()
	if(.)
		return

	// Using a codex will give you two knowledge points for draining.
	if(drain_influence_with_codex(user, weapon))
		return TRUE

/obj/effect/heretic_influence/proc/drain_influence_with_codex(mob/user, obj/item/codex_cicatrix/codex)
	if(!istype(codex) || being_drained)
		return FALSE
	if(!codex.book_open)
		codex.attack_self(user) // open booke
	INVOKE_ASYNC(src, PROC_REF(drain_influence), user, 2, codex.drain_speed)
	return TRUE

/**
 * Begin to drain the influence, setting being_drained,
 * registering an examine signal, and beginning a do_after.
 *
 * If successful, the influence is drained and deleted.
 */
/obj/effect/heretic_influence/proc/drain_influence(mob/living/user, knowledge_to_gain, drain_speed = 10 SECONDS)

	being_drained = TRUE
	loc.balloon_alert(user, "draining influence...")

	if(!do_after(user, drain_speed, src, hidden = TRUE))
		being_drained = FALSE
		loc.balloon_alert(user, "interrupted!")
		return

	// We don't need to set being_drained back since we delete after anyways
	loc.balloon_alert(user, "influence drained")

	var/datum/antagonist/heretic/heretic_datum = GET_HERETIC(user)
	heretic_datum.knowledge_points += knowledge_to_gain

	// Aaand now we delete it
	after_drain(user)

/**
 * Handle the effects of the drain.
 */
/obj/effect/heretic_influence/proc/after_drain(mob/living/user)
	if(user)
		to_chat(user, span_hypnophrase(pick_list(HERETIC_INFLUENCE_FILE, "drain_message")))
		to_chat(user, span_warning("[src] begins to fade into reality!"))

	var/obj/effect/visible_heretic_influence/illusion = new /obj/effect/visible_heretic_influence(drop_location())
	illusion.name = "\improper" + pick_list(HERETIC_INFLUENCE_FILE, "drained") + " " + format_text(name)

	GLOB.reality_smash_track.num_drained++
	qdel(src)

/**
 * Generates a random name for the influence.
 */
/obj/effect/heretic_influence/proc/generate_name()
	name = "\improper" + pick_list(HERETIC_INFLUENCE_FILE, "prefix") + " " + pick_list(HERETIC_INFLUENCE_FILE, "postfix")

#undef NUM_INFLUENCES_PER_HERETIC

/// Hud used for heretics to see influences
/datum/atom_hud/alternate_appearance/basic/has_antagonist/heretic
	antag_datum_type = /datum/antagonist/heretic
	add_ghost_version = TRUE
