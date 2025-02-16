/obj/structure/toiletbong
	name = "toilet bong"
	desc = "A repurposed toilet with re-arranged piping and an attached flamethrower. Why would anyone build this?"
	icon = 'icons/obj/watercloset.dmi'
	icon_state = "toiletbong"
	base_icon_state = "toiletbong"
	density = FALSE
	anchored = TRUE
	var/smokeradius = 1
	var/mutable_appearance/weed_overlay

/obj/structure/toiletbong/Initialize(mapload)
	. = ..()
	create_storage()
	AddComponent(/datum/component/simple_rotation, post_rotation = CALLBACK(src, PROC_REF(post_rotation)))
	create_storage(max_total_storage = 100, max_slots = 12, canhold = /obj/item/food)
	atom_storage.attack_hand_interact = FALSE
	atom_storage.do_rustle = FALSE
	atom_storage.animated = FALSE

	weed_overlay = mutable_appearance('icons/obj/watercloset.dmi', "[base_icon_state]_overlay")
	START_PROCESSING(SSobj, src)

/obj/structure/toiletbong/on_craft_completion(list/components, datum/crafting_recipe/current_recipe, atom/crafter)
	var/obj/structure/toilet/toilet = locate(/obj/structure/toilet) in components
	if(toilet)
		for(var/obj/item/cistern_item in toilet.contents)
			cistern_item.forceMove(crafter.drop_location())
			to_chat(crafter, span_warning("[cistern_item] falls out of the toilet!"))
		setDir(toilet.dir)
		forceMove(toilet.loc)

	crafter.visible_message(
		span_notice("[crafter] attaches the flamethrower to the repurposed toilet."),
		span_notice("You attach the flamethrower to the repurposed toilet."),
	)
	return ..()

/obj/structure/toiletbong/update_overlays()
	. = ..()
	if (LAZYLEN(contents))
		. += weed_overlay

/obj/structure/toiletbong/attack_hand(mob/living/carbon/user)
	. = ..()
	if (!anchored)
		user.balloon_alert(user, "secure it first!")
		return
	if (!LAZYLEN(contents))
		user.balloon_alert(user, "it's empty!")
		return
	user.visible_message(span_boldnotice("[user] takes a huge drag on the [src]."))
	if (!do_after(user, 2 SECONDS, target = src))
		return
	var/turf/toiletbong_location = loc
	toiletbong_location.hotspot_expose(1000, 5)
	for (var/obj/item/item in contents)
		if (item.resistance_flags & INDESTRUCTIBLE)
			user.balloon_alert(user, "[item.name] is blocking the pipes!")
			continue
		playsound(src, 'sound/items/modsuit/flamethrower.ogg', 50)
		var/datum/effect_system/fluid_spread/smoke/chem/smoke_machine/puff = new
		puff.set_up(smokeradius, holder = src, location = user, carry = item.reagents, efficiency = 20)
		puff.start()
		if (prob(5) && !(obj_flags & EMAGGED))
			if(user.get_liked_foodtypes() & GORE)
				user.balloon_alert(user, "a hidden treat!")
				user.visible_message(span_danger("[user] fishes a mouse out of the pipes."))
			else
				to_chat(user, span_userdanger("There was something disgusting in the pipes!"))
				user.visible_message(span_danger("[user] spits out a mouse."))
				user.adjust_disgust(50)
				user.vomit(VOMIT_CATEGORY_DEFAULT)
			var/mob/living/spawned_mob = new /mob/living/basic/mouse(get_turf(user))
			spawned_mob.faction |= "[REF(user)]"
			if(prob(50))
				for(var/j in 1 to rand(1, 3))
					step(spawned_mob, pick(NORTH,SOUTH,EAST,WEST))
		qdel(item)
		if(!(obj_flags & EMAGGED))
			break
	update_appearance(UPDATE_ICON)

/obj/structure/toiletbong/wrench_act(mob/living/user, obj/item/tool)
	..()
	default_unfasten_wrench(user, tool)
	return ITEM_INTERACT_SUCCESS

///Called in the simple rotation's post_rotation callback, playing a sound cue to players.
/obj/structure/toiletbong/proc/post_rotation(mob/user, degrees)
	playsound(src, 'sound/items/deconstruct.ogg', 50)

/obj/structure/toiletbong/crowbar_act(mob/living/user, obj/item/tool)
	if(anchored)
		return FALSE
	tool.play_tool_sound(src)
	to_chat(user, span_notice("You begin taking apart the [src]."))
	if (!do_after(user, 10 SECONDS, target = src))
		return FALSE
	new /obj/item/flamethrower(get_turf(src))
	new /obj/item/stack/sheet/iron(get_turf(src))
	var/obj/item/tank/internals/plasma/ptank = new /obj/item/tank/internals/plasma(get_turf(src))
	ptank.air_contents.gases[/datum/gas/plasma][MOLES] = (0)
	qdel(src)
	return TRUE

/obj/structure/toiletbong/emag_act(mob/user, obj/item/card/emag/emag_card)
	if(obj_flags & EMAGGED)
		return FALSE
	obj_flags |= EMAGGED
	smokeradius = 2
	playsound(src, 'sound/effects/fish_splash.ogg', 50)
	balloon_alert(user, "toilet broke")
	if (emag_card)
		to_chat(user, span_boldwarning("The [emag_card] falls into the toilet. You fish it back out. Looks like you broke the toilet."))
	return TRUE

/obj/structure/toiletbong/attackby(obj/item/attacking_item, mob/user, params)
	if(istype(attacking_item, /obj/item/card/emag))
		return
	return ..()
