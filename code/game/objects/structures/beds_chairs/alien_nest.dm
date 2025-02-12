//Alium nests. Essentially beds with an unbuckle delay that only aliums can buckle mobs to.

/obj/structure/bed/nest
	name = "alien nest"
	desc = "It's a gruesome pile of thick, sticky resin shaped like a nest."
	icon = 'icons/obj/smooth_structures/alien/nest.dmi'
	icon_state = "nest-0"
	base_icon_state = "nest"
	max_integrity = 120
	can_be_unanchored = FALSE
	smoothing_flags = SMOOTH_BITMASK
	smoothing_groups = SMOOTH_GROUP_ALIEN_NEST
	canSmoothWith = SMOOTH_GROUP_ALIEN_NEST
	build_stack_type = null
	elevation = 0
	can_deconstruct = FALSE
	var/static/mutable_appearance/nest_overlay = mutable_appearance('icons/mob/nonhuman-player/alien.dmi', "nestoverlay", LYING_MOB_LAYER)

/obj/structure/bed/nest/add_context(atom/source, list/context, obj/item/held_item, mob/living/user)
	if(held_item?.tool_behaviour == TOOL_WRENCH)
		return NONE

	return ..()

/obj/structure/bed/nest/user_unbuckle_mob(mob/living/captive, mob/living/hero)
	if(!length(buckled_mobs))
		return

	if(hero.get_organ_by_type(/obj/item/organ/alien/plasmavessel))
		unbuckle_mob(captive)
		add_fingerprint(hero)
		return

	if(captive != hero)
		captive.visible_message(span_notice("[hero.name] pulls [captive.name] free from the sticky nest!"),
			span_notice("[hero.name] pulls you free from the gelatinous resin."),
			span_hear("You hear squelching..."))
		unbuckle_mob(captive)
		add_fingerprint(hero)
		return

	captive.visible_message(span_warning("[captive.name] struggles to break free from the gelatinous resin!"),
		span_notice("You struggle to break free from the gelatinous resin... (Stay still for about a minute and a half.)"),
		span_hear("You hear squelching..."))

	if(!do_after(captive, 100 SECONDS, target = src, hidden = TRUE))
		if(captive.buckled)
			to_chat(captive, span_warning("You fail to unbuckle yourself!"))
		return

	captive.visible_message(span_warning("[captive.name] breaks free from the gelatinous resin!"),
		span_notice("You break free from the gelatinous resin!"),
		span_hear("You hear squelching..."))

	unbuckle_mob(captive)
	add_fingerprint(hero)

/obj/structure/bed/nest/user_buckle_mob(mob/living/M, mob/user, check_loc = TRUE)
	if ( !ismob(M) || (get_dist(src, user) > 1) || (M.loc != src.loc) || user.incapacitated || M.buckled )
		return

	if(M.get_organ_by_type(/obj/item/organ/alien/plasmavessel))
		return
	if(!user.get_organ_by_type(/obj/item/organ/alien/plasmavessel))
		return

	if(has_buckled_mobs())
		unbuckle_all_mobs()

	if(buckle_mob(M))
		M.visible_message(span_notice("[user.name] secretes a thick vile goo, securing [M.name] into [src]!"),\
			span_danger("[user.name] drenches you in a foul-smelling resin, trapping you in [src]!"),\
			span_hear("You hear squelching..."))

/obj/structure/bed/nest/post_buckle_mob(mob/living/M)
	ADD_TRAIT(M, TRAIT_HANDS_BLOCKED, type)
	M.add_offsets(type, x_add = 2)
	M.layer = BELOW_MOB_LAYER
	add_overlay(nest_overlay)

	if(ishuman(M))
		var/mob/living/carbon/human/victim = M
		if(((victim.wear_mask && istype(victim.wear_mask, /obj/item/clothing/mask/facehugger)) || HAS_TRAIT(victim, TRAIT_XENO_HOST)) && victim.stat != DEAD) //If they're a host or have a facehugger currently infecting them. Must be alive.
			victim.apply_status_effect(/datum/status_effect/nest_sustenance)

/obj/structure/bed/nest/post_unbuckle_mob(mob/living/M)
	REMOVE_TRAIT(M, TRAIT_HANDS_BLOCKED, type)
	M.remove_offsets(type)
	M.layer = initial(M.layer)
	cut_overlay(nest_overlay)
	M.remove_status_effect(/datum/status_effect/nest_sustenance)

/obj/structure/bed/nest/play_attack_sound(damage_amount, damage_type = BRUTE, damage_flag = 0)
	switch(damage_type)
		if(BRUTE)
			playsound(loc, 'sound/effects/blob/attackblob.ogg', 100, TRUE)
		if(BURN)
			playsound(loc, 'sound/items/tools/welder.ogg', 100, TRUE)

/obj/structure/bed/nest/attack_alien(mob/living/carbon/alien/user, list/modifiers)
	if(!user.combat_mode)
		return attack_hand(user, modifiers)
	else
		return ..()
