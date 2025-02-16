/obj/item/reagent_containers
	name = "Container"
	desc = "..."
	icon = 'icons/obj/medical/chemical.dmi'
	icon_state = null
	w_class = WEIGHT_CLASS_TINY
	/// The maximum amount of reagents per transfer that will be moved out of this reagent container.
	var/amount_per_transfer_from_this = 5
	/// Does this container allow changing transfer amounts at all, the container can still have only one possible transfer value in possible_transfer_amounts at some point even if this is true
	var/has_variable_transfer_amount = TRUE
	/// The different possible amounts of reagent to transfer out of the container
	var/list/possible_transfer_amounts = list(5,10,15,20,25,30)
	/// The maximum amount of reagents this container can hold
	var/volume = 30
	/// Reagent flags, a few examples being if the container is open or not, if its transparent, if you can inject stuff in and out of the container, and so on
	var/reagent_flags
	/// A list of what initial reagents this container should spawn with
	var/list/list_reagents = null
	/// If this container should spawn with a disease type inside of it
	var/spawned_disease = null
	/// How much of a disease specified in spawned_disease should this container spawn with
	var/disease_amount = 20
	/// If the reagents inside of this container will splash out when the container tries to splash onto someone or something
	var/spillable = FALSE
	/**
	 * The different thresholds at which the reagent fill overlay will change. See medical/reagent_fillings.dmi.
	 *
	 * Should be a list of integers which correspond to a reagent unit threshold.
	 * If null, no automatic fill overlays are generated.
	 *
	 * For example, list(0) will mean it will gain a the overlay with any reagents present. This overlay is "overlayname0".
	 * list(0, 10) whill have two overlay options, for 0-10 units ("overlayname0") and 10+ units ("overlayname10").
	 */
	var/list/fill_icon_thresholds = null
	/// The optional custom name for the reagent fill icon_state prefix
	/// If not set, uses the current icon state.
	var/fill_icon_state = null
	/// The icon file to take fill icon appearances from
	var/fill_icon = 'icons/obj/medical/reagent_fillings.dmi'
	///The sound this container makes when picked up, dropped if there is liquid inside.
	var/reagent_container_liquid_sound = null

/obj/item/reagent_containers/apply_fantasy_bonuses(bonus)
	. = ..()
	if(reagents)
		reagents.maximum_volume = modify_fantasy_variable("maximum_volume", reagents.maximum_volume, bonus * 10, minimum = 5)
	volume = modify_fantasy_variable("maximum_volume_beaker", volume, bonus * 10, minimum = 5)

/obj/item/reagent_containers/remove_fantasy_bonuses(bonus)
	if(reagents)
		reagents.maximum_volume = reset_fantasy_variable("maximum_volume", reagents.maximum_volume)
	volume = reset_fantasy_variable("maximum_volume_beaker", volume)
	return ..()

/obj/item/reagent_containers/Initialize(mapload, vol)
	. = ..()
	if(isnum(vol) && vol > 0)
		volume = vol
	create_reagents(volume, reagent_flags)
	if(spawned_disease)
		var/datum/disease/F = new spawned_disease()
		var/list/data = list("viruses"= list(F))
		reagents.add_reagent(/datum/reagent/blood, disease_amount, data)
	add_initial_reagents()

/obj/item/reagent_containers/examine(mob/user)
	. = ..()
	if(has_variable_transfer_amount)
		if(possible_transfer_amounts.len > 1)
			. += span_notice("Left-click or right-click in-hand to increase or decrease its transfer amount.")
		else if(possible_transfer_amounts.len)
			. += span_notice("Left-click or right-click in-hand to view its transfer amount.")
	if(isliving(user) && HAS_TRAIT(user, TRAIT_REMOTE_TASTING))
		var/mob/living/living_user = user
		living_user.taste_container(reagents)

/obj/item/reagent_containers/create_reagents(max_vol, flags)
	. = ..()
	RegisterSignal(reagents, COMSIG_REAGENTS_HOLDER_UPDATED, PROC_REF(on_reagent_change))

/obj/item/reagent_containers/attack(mob/living/target_mob, mob/living/user, params)
	if (!user.combat_mode)
		return
	return ..()

/obj/item/reagent_containers/proc/add_initial_reagents()
	if(list_reagents)
		reagents.add_reagent_list(list_reagents)

/obj/item/reagent_containers/attack_self(mob/user)
	if(has_variable_transfer_amount)
		change_transfer_amount(user, FORWARD)

/obj/item/reagent_containers/attack_self_secondary(mob/user)
	if(has_variable_transfer_amount)
		change_transfer_amount(user, BACKWARD)

/obj/item/reagent_containers/proc/mode_change_message(mob/user)
	return

/obj/item/reagent_containers/proc/change_transfer_amount(mob/user, direction = FORWARD)
	var/list_len = length(possible_transfer_amounts)
	if(!list_len)
		return
	var/index = possible_transfer_amounts.Find(amount_per_transfer_from_this) || 1
	switch(direction)
		if(FORWARD)
			index = (index % list_len) + 1
		if(BACKWARD)
			index = (index - 1) || list_len
		else
			CRASH("change_transfer_amount() called with invalid direction value")
	amount_per_transfer_from_this = possible_transfer_amounts[index]
	balloon_alert(user, "transferring [amount_per_transfer_from_this]u")
	mode_change_message(user)

/obj/item/reagent_containers/pre_attack_secondary(atom/target, mob/living/user, params)
	if(HAS_TRAIT(target, TRAIT_DO_NOT_SPLASH))
		return ..()
	if(!user.combat_mode)
		return ..()
	if (try_splash(user, target))
		return SECONDARY_ATTACK_CANCEL_ATTACK_CHAIN

	return ..()

/// Tries to splash the target. Used on both right-click and normal click when in combat mode.
/obj/item/reagent_containers/proc/try_splash(mob/user, atom/target)
	if (!spillable)
		return FALSE

	if (!reagents?.total_volume)
		return FALSE

	var/punctuation = ismob(target) ? "!" : "."

	var/reagent_text
	user.visible_message(
		span_danger("[user] splashes the contents of [src] onto [target][punctuation]"),
		span_danger("You splash the contents of [src] onto [target][punctuation]"),
		ignored_mobs = target,
	)
	SEND_SIGNAL(target, COMSIG_ATOM_SPLASHED)
	if (ismob(target))
		var/mob/target_mob = target
		target_mob.show_message(
			span_userdanger("[user] splashes the contents of [src] onto you!"),
			MSG_VISUAL,
			span_userdanger("You feel drenched!"),
		)

	playsound(target, 'sound/effects/slosh.ogg', 25, TRUE)

	var/mutable_appearance/splash_animation = mutable_appearance('icons/effects/effects.dmi', "splash")
	if(isturf(target))
		splash_animation.icon_state = "splash_floor"
	splash_animation.color = mix_color_from_reagents(reagents.reagent_list)
	target.flick_overlay_view(splash_animation, 1 SECONDS)

	for(var/datum/reagent/reagent as anything in reagents.reagent_list)
		reagent_text += "[reagent] ([num2text(reagent.volume)]),"

	var/mob/thrown_by = thrownby?.resolve()
	if(isturf(target) && reagents.reagent_list.len && thrown_by)
		log_combat(thrown_by, target, "splashed (thrown) [english_list(reagents.reagent_list)]")
		message_admins("[ADMIN_LOOKUPFLW(thrown_by)] splashed (thrown) [english_list(reagents.reagent_list)] on [target] at [ADMIN_VERBOSEJMP(target)].")

	reagents.expose(target, TOUCH)
	log_combat(user, target, "splashed", reagent_text)
	reagents.clear_reagents()

	return TRUE

/obj/item/reagent_containers/proc/canconsume(mob/eater, mob/user)
	if(!iscarbon(eater))
		return FALSE
	var/mob/living/carbon/C = eater
	var/covered = ""
	if(C.is_mouth_covered(ITEM_SLOT_HEAD))
		covered = "headgear"
	else if(C.is_mouth_covered(ITEM_SLOT_MASK))
		covered = "mask"
	if(covered)
		var/who = (isnull(user) || eater == user) ? "your" : "[eater.p_their()]"
		to_chat(user, span_warning("You have to remove [who] [covered] first!"))
		return FALSE
	return TRUE

/*
 * On accidental consumption, transfer a portion of the reagents to the eater and the item it's in, then continue to the base proc (to deal with shattering glass containers)
 */
/obj/item/reagent_containers/on_accidental_consumption(mob/living/carbon/M, mob/living/carbon/user, obj/item/source_item,  discover_after = TRUE)
	M.losebreath += 2
	reagents?.trans_to(M, min(15, reagents.total_volume / rand(5,10)), transferred_by = user, methods = INGEST)
	if(source_item?.reagents)
		reagents.trans_to(source_item, min(source_item.reagents.total_volume / 2, reagents.total_volume / 5), transferred_by = user, methods = TOUCH)

	return ..()

/obj/item/reagent_containers/fire_act(exposed_temperature, exposed_volume)
	reagents.expose_temperature(exposed_temperature)
	..()

/obj/item/reagent_containers/throw_impact(atom/hit_atom, datum/thrownthing/throwingdatum, do_splash = TRUE)
	. = ..()
	if(do_splash)
		SplashReagents(hit_atom, TRUE)

/obj/item/reagent_containers/proc/bartender_check(atom/target)
	. = FALSE
	var/mob/thrown_by = thrownby?.resolve()
	if(target.CanPass(src, get_dir(target, src)) && thrown_by && HAS_TRAIT(thrown_by, TRAIT_BOOZE_SLIDER))
		. = TRUE

/obj/item/reagent_containers/proc/SplashReagents(atom/target, thrown = FALSE, override_spillable = FALSE)
	if(!reagents || !reagents.total_volume || (!spillable && !override_spillable))
		return
	var/mob/thrown_by = thrownby?.resolve()

	if(ismob(target) && target.reagents)
		var/splash_multiplier = 1
		if(thrown)
			splash_multiplier *= (rand(5,10) * 0.1) //Not all of it makes contact with the target
		var/mob/M = target
		var/turf/target_turf = get_turf(target)
		var/R
		target.visible_message(span_danger("[M] is splashed with something!"), \
						span_userdanger("[M] is splashed with something!"))
		for(var/datum/reagent/A in reagents.reagent_list)
			R += "[A.type]  ([num2text(A.volume)]),"

		if(thrown_by)
			log_combat(thrown_by, M, "splashed", R)
		reagents.expose(target, TOUCH, splash_multiplier)
		reagents.expose(target_turf, TOUCH, (1 - splash_multiplier)) // 1 - splash_multiplier because it's what didn't hit the target

	else if(bartender_check(target) && thrown)
		visible_message(span_notice("[src] lands onto \the [target] without spilling a single drop."))
		return

	else
		if(isturf(target) && reagents.reagent_list.len && thrown_by)
			log_combat(thrown_by, target, "splashed (thrown) [english_list(reagents.reagent_list)]", "in [AREACOORD(target)]")
			thrown_by.log_message("splashed (thrown) [english_list(reagents.reagent_list)] on [target].", LOG_ATTACK)
			message_admins("[ADMIN_LOOKUPFLW(thrown_by)] splashed (thrown) [english_list(reagents.reagent_list)] on [target] in [ADMIN_VERBOSEJMP(target)].")
		visible_message(span_notice("[src] spills its contents all over [target]."))
		reagents.expose(target, TOUCH)
		if(QDELETED(src))
			return

	playsound(target, 'sound/effects/slosh.ogg', 25, TRUE)

	var/mutable_appearance/splash_animation = mutable_appearance('icons/effects/effects.dmi', "splash")
	if(isturf(target))
		splash_animation.icon_state = "splash_floor"
	splash_animation.color = mix_color_from_reagents(reagents.reagent_list)
	target.flick_overlay_view(splash_animation, 1.0 SECONDS)

	reagents.clear_reagents()

/obj/item/reagent_containers/microwave_act(obj/machinery/microwave/microwave_source, mob/microwaver, randomize_pixel_offset)
	reagents.expose_temperature(1000)
	return ..() | COMPONENT_MICROWAVE_SUCCESS

/// Updates the icon of the container when the reagents change. Eats signal args
/obj/item/reagent_containers/proc/on_reagent_change(datum/reagents/holder, ...)
	SIGNAL_HANDLER
	update_appearance()

/obj/item/reagent_containers/update_overlays()
	. = ..()
	if(!fill_icon_thresholds)
		return
	if(!reagents.total_volume)
		return

	var/fill_name = fill_icon_state ? fill_icon_state : icon_state
	var/mutable_appearance/filling = mutable_appearance(fill_icon, "[fill_name][fill_icon_thresholds[1]]")

	var/percent = round((reagents.total_volume / volume) * 100)
	for(var/i in 1 to fill_icon_thresholds.len)
		var/threshold = fill_icon_thresholds[i]
		var/threshold_end = (i == fill_icon_thresholds.len) ? INFINITY : fill_icon_thresholds[i+1]
		if(threshold <= percent && percent < threshold_end)
			filling.icon_state = "[fill_name][fill_icon_thresholds[i]]"

	filling.color = mix_color_from_reagents(reagents.reagent_list)
	. += filling

/obj/item/reagent_containers/dropped(mob/user, silent)
	. = ..()
	if(reagent_container_liquid_sound && reagents.total_volume > 0)
		playsound(src, reagent_container_liquid_sound, LIQUID_SLOSHING_SOUND_VOLUME, vary = TRUE, ignore_walls = FALSE)

/obj/item/reagent_containers/equipped(mob/user, slot, initial = FALSE)
	. = ..()
	if(!initial && (slot & ITEM_SLOT_HANDS) && reagent_container_liquid_sound && reagents.total_volume > 0)
		playsound(src, reagent_container_liquid_sound, LIQUID_SLOSHING_SOUND_VOLUME, vary = TRUE, ignore_walls = FALSE)

/obj/item/reagent_containers/used_in_craft(atom/result, datum/crafting_recipe/current_recipe)
	. = ..()
	// If consumed in crafting, we should dump contents out before qdeling them.
	if(!is_type_in_list(src, current_recipe.parts))
		reagents.expose(loc, TOUCH)
