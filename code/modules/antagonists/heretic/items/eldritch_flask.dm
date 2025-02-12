// An unholy water flask, but for heretics.
// Heals heretics, harms non-heretics. Pretty much identical.
/obj/item/reagent_containers/cup/beaker/eldritch
	name = "flask of eldritch essence"
	desc = "Toxic to the closed minded, yet refreshing to those with knowledge of the beyond."
	icon = 'icons/obj/antags/eldritch.dmi'
	icon_state = "eldritch_flask"
	list_reagents = list(/datum/reagent/eldritch = 50)

// Unique bottle that lets you instantly draw blood from a victim
/obj/item/reagent_containers/cup/phylactery
	name = "phylactery of damnation"
	desc = "Used to steal blood from soon-to-be victims."
	icon = 'icons/obj/antags/eldritch.dmi'
	icon_state = "phylactery"
	base_icon_state = "phylactery"
	has_variable_transfer_amount = FALSE
	reagent_flags = OPENCONTAINER | DUNKABLE | TRANSPARENT
	volume = 10
	/// Cooldown before you can steal blood again
	COOLDOWN_DECLARE(drain_cooldown)

/obj/item/reagent_containers/cup/phylactery/interact_with_atom_secondary(atom/target, mob/living/user, list/modifiers)
	if(!COOLDOWN_FINISHED(src, drain_cooldown))
		user.balloon_alert(user, "can't steal so fast!")
		return NONE
	if(!isliving(target))
		return NONE
	var/mob/living/living_target = target
	if(reagents.total_volume >= reagents.maximum_volume)
		to_chat(user, span_notice("[src] is full."))
		return ITEM_INTERACT_BLOCKING
	if(living_target == user)
		return ITEM_INTERACT_BLOCKING
	if(living_target.can_block_magic(MAGIC_RESISTANCE_HOLY))
		to_chat(user, span_warning("You are unable to draw any blood from [living_target]!"))
		COOLDOWN_START(src, drain_cooldown, 5 SECONDS)
		to_chat(living_target, span_warning("You feel a force attempt to steal your blood, but it is repelled!"))
		return ITEM_INTERACT_BLOCKING
	var/drawn_amount = min(reagents.maximum_volume - reagents.total_volume, 5)
	if(living_target.transfer_blood_to(src, drawn_amount))
		to_chat(user, span_notice("You take a blood sample from [living_target]."))
		to_chat(living_target, span_warning("You feel a tiny prick!"))
		COOLDOWN_START(src, drain_cooldown, 5 SECONDS)
		playsound(src, 'sound/effects/chemistry/catalyst.ogg', 20, TRUE, extrarange = SILENCED_SOUND_EXTRARANGE, falloff_exponent = 10)
	else
		to_chat(user, span_warning("You are unable to draw any blood from [living_target]!"))
	return ITEM_INTERACT_SUCCESS

/obj/item/reagent_containers/cup/phylactery/ranged_interact_with_atom_secondary(atom/interacting_with, mob/living/user, list/modifiers)
	if(get_dist(user, interacting_with) <= 30)
		return interact_with_atom_secondary(interacting_with, user, modifiers)
	return ..()

/obj/item/reagent_containers/cup/phylactery/update_icon_state()
	. = ..()
	switch(reagents.total_volume)
		if(0)
			icon_state = base_icon_state
		if(0.1 to 5)
			icon_state = base_icon_state + "_1"
		if(5.1 to 10)
			icon_state = base_icon_state + "_2"

// Funny potion that is basically an aheal. The downside is that it puts you to sleep for a minute.
/obj/item/ether
	name = "ether of the newborn"
	desc = "A flask of nausea-inducing, thick green liquid. Restores your body completely, then places you into an enhanced sleep for a full minute."
	icon = 'icons/obj/antags/eldritch.dmi'
	icon_state = "poison_flask"

/obj/item/ether/attack_self(mob/living/user, modifiers)
	. = ..()
	user.revive(HEAL_ALL)
	for(var/obj/item/implant/to_remove in user.implants)
		to_remove.removed(user)

	user.apply_status_effect(/datum/status_effect/eldritch_sleep)
	user.SetSleeping(60 SECONDS)
	qdel(src)

/datum/status_effect/eldritch_sleep
	id = "eldritch_sleep"
	duration = 60 SECONDS
	status_type = STATUS_EFFECT_REFRESH
	alert_type = /atom/movable/screen/alert/status_effect/eldritch_sleep
	show_duration = TRUE
	remove_on_fullheal = TRUE
	/// List of traits our drinker gets while they are asleep
	var/list/sleeping_traits = list(TRAIT_NOBREATH, TRAIT_RESISTLOWPRESSURE, TRAIT_RESISTLOWPRESSURE, TRAIT_RESISTCOLD, TRAIT_RESISTHEAT)

/datum/status_effect/eldritch_sleep/on_apply()
	. = ..()
	owner.add_traits(sleeping_traits, TRAIT_STATUS_EFFECT(id))
	owner.apply_status_effect(/datum/status_effect/grouped/stasis, STASIS_ELDRITCH_ETHER)

/datum/status_effect/eldritch_sleep/on_remove()
	owner.SetSleeping(0) // Wake up bookworm, we have some heathens to burn
	owner.remove_traits(sleeping_traits, TRAIT_STATUS_EFFECT(id))
	owner.reagents?.remove_all(100) // If someone gives you over 100 units of poison while you sleep then you deserve this L
	owner.remove_status_effect(/datum/status_effect/grouped/stasis, STASIS_ELDRITCH_ETHER)

/atom/movable/screen/alert/status_effect/eldritch_sleep
	name = "Eldritch Slumber"
	desc = "You feel an indescribable warmth keeping you safe..."
	icon_state = "eldritch_slumber"
