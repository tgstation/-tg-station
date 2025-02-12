/* Toys!
 * Contains
 * Balloons
 * Captain's Aid
 * Fake singularity
 * Toy gun
 * Toy swords
 * Crayons
 * Snap pops
 * AI core prizes
 * Toy codex gigas
 * Skeleton toys
 * Toy nuke
 * Fake meteor
 * Foam armblade
 * Toy big red button
 * Beach ball
 * Toy xeno
 *      Kitty toys!
 * Snowballs
 * Clockwork Watches
 * Toy Daggers
 * Squeaky Brain
 * Broken Radio
 * Fake heretic codex
 * Fake Pierced Reality
 * Intento
 */
/obj/item/toy
	throwforce = 0
	throw_speed = 3
	throw_range = 7
	force = 0
	worn_icon_state = "nothing"

/*
 * Balloons
 */
/obj/item/toy/waterballoon
	name = "water balloon"
	desc = "A translucent balloon. There's nothing in it."
	icon = 'icons/obj/toys/balloons.dmi'
	icon_state = "balloon_red-e"
	inhand_icon_state = "balloon-empty"

/obj/item/toy/waterballoon/Initialize(mapload)
	. = ..()
	AddElement(/datum/element/update_icon_updates_onmob)
	create_reagents(10)

/obj/item/toy/waterballoon/attack(mob/living/carbon/human/M, mob/user)
	return

/obj/item/toy/waterballoon/interact_with_atom(atom/interacting_with, mob/living/user, list/modifiers)
	if (!istype(interacting_with, /obj/structure/reagent_dispensers))
		return NONE
	var/obj/structure/reagent_dispensers/RD = interacting_with
	if(RD.reagents.total_volume <= 0)
		to_chat(user, span_warning("[RD] is empty."))
	else if(reagents.total_volume >= 10)
		to_chat(user, span_warning("[src] is full."))
	else
		interacting_with.reagents.trans_to(src, 10, transferred_by = user)
		to_chat(user, span_notice("You fill the balloon with the contents of [interacting_with]."))
		desc = "A translucent balloon with some form of liquid sloshing around in it."
		update_appearance()
		return ITEM_INTERACT_SUCCESS
	return ITEM_INTERACT_BLOCKING

/obj/item/toy/waterballoon/attackby(obj/item/I, mob/user, params)
	if(istype(I, /obj/item/reagent_containers/cup))
		if(I.reagents)
			if(I.reagents.total_volume <= 0)
				to_chat(user, span_warning("[I] is empty."))
			else if(reagents.total_volume >= 10)
				to_chat(user, span_warning("[src] is full."))
			else
				desc = "A translucent balloon with some form of liquid sloshing around in it."
				to_chat(user, span_notice("You fill the balloon with the contents of [I]."))
				I.reagents.trans_to(src, 10, transferred_by = user)
				update_appearance()
	else if(I.get_sharpness())
		balloon_burst()
	else
		return ..()

/obj/item/toy/waterballoon/throw_impact(atom/hit_atom, datum/thrownthing/throwingdatum)
	if(!..()) //was it caught by a mob?
		balloon_burst(hit_atom)

/obj/item/toy/waterballoon/proc/balloon_burst(atom/AT)
	if(reagents.total_volume >= 1)
		var/turf/T
		if(AT)
			T = get_turf(AT)
		else
			T = get_turf(src)
		T.visible_message(span_danger("[src] bursts!"),span_hear("You hear a pop and a splash."))
		reagents.expose(T)
		for(var/atom/A in T)
			reagents.expose(A)
		icon_state = "burst"
		qdel(src)

/obj/item/toy/waterballoon/update_icon_state()
	if(reagents.total_volume >= 1)
		icon_state = "waterballoon"
		inhand_icon_state = "balloon"
	else
		icon_state = "balloon_red-e"
		inhand_icon_state = "balloon-empty"
	return ..()

#define BALLOON_COLORS list("red", "blue", "green", "yellow", "orange", "purple")

/obj/item/toy/balloon
	name = "balloon"
	desc = "No birthday is complete without it. Sealed with a mechanical bluespace wrap so it remains floating no matter what."
	icon = 'icons/obj/toys/balloons.dmi'
	icon_state = "balloon"
	inhand_icon_state = "balloon"
	lefthand_file = 'icons/mob/inhands/items/balloons_lefthand.dmi'
	righthand_file = 'icons/mob/inhands/items/balloons_righthand.dmi'
	w_class = WEIGHT_CLASS_BULKY
	throwforce = 0
	throw_speed = 3
	throw_range = 7
	force = 0
	var/random_color = TRUE
	/// the string describing the name of balloon's current colour.
	var/current_color

/obj/item/toy/balloon/long
	name = "long balloon"
	desc = "A perfect balloon to contort into goofy forms. Sealed with a mechanical bluespace wrap so it remains floating no matter what."
	icon_state = "balloon_long"
	inhand_icon_state = "balloon"
	w_class = WEIGHT_CLASS_NORMAL
	/// Combinations of balloon colours to make specific animals.
	var/list/balloon_combos = list(
		list("red", "blue") = /obj/item/toy/balloon_animal/guy,
		list("red", "green") = /obj/item/toy/balloon_animal/nukie,
		list("red", "yellow") = /obj/item/toy/balloon_animal/clown,
		list("red", "orange") = /obj/item/toy/balloon_animal/cat,
		list("red", "purple") = /obj/item/toy/balloon_animal/fly,
		list("blue", "green") = /obj/item/toy/balloon_animal/podguy,
		list("blue", "yellow") = /obj/item/toy/balloon_animal/ai,
		list("blue", "orange") = /obj/item/toy/balloon_animal/dog,
		list("blue", "purple") = /obj/item/toy/balloon_animal/xeno,
		list("green", "yellow") = /obj/item/toy/balloon_animal/banana,
		list("green", "orange") = /obj/item/toy/balloon_animal/lizard,
		list("green", "purple") = /obj/item/toy/balloon_animal/slime,
		list("yellow", "orange") = /obj/item/toy/balloon_animal/moth,
		list("yellow", "purple") = /obj/item/toy/balloon_animal/ethereal,
		list("orange", "purple") = /obj/item/toy/balloon_animal/plasmaman,
	)


/obj/item/toy/balloon/long/attackby(obj/item/attacking_item, mob/living/user, params)
	if(!istype(attacking_item, /obj/item/toy/balloon/long) || !HAS_TRAIT(user, TRAIT_BALLOON_SUTRA))
		return ..()

	var/obj/item/toy/balloon/long/hit_by = attacking_item
	if(hit_by.current_color == current_color)
		to_chat(user, span_warning("You must use balloons of different colours to do that!"))
		return ..()
	visible_message(
		span_notice("[user.name] starts contorting up a balloon animal!"),
		blind_message = span_hear("You hear balloons being contorted."),
		vision_distance = 3,
		ignored_mobs = user,
	)
	for(var/list/pair_of_colors in balloon_combos)
		if((hit_by.current_color == pair_of_colors[1] && current_color == pair_of_colors[2]) || (current_color == pair_of_colors[1] && hit_by.current_color == pair_of_colors[2]))
			var/path_to_spawn = balloon_combos[pair_of_colors]
			user.put_in_hands(new path_to_spawn)
			break
	qdel(hit_by)
	qdel(src)
	return TRUE

/obj/item/toy/balloon/attackby(obj/item/I, mob/user, params)
	if(istype(I, /obj/item/ammo_casing/foam_dart) && ismonkey(user))
		pop_balloon(monkey_pop = TRUE)
	else
		return ..()

/obj/item/toy/balloon/hitby(atom/movable/AM, skipcatch, hitpush, blocked, datum/thrownthing/throwingdatum)
	var/mob/thrower = throwingdatum?.get_thrower()
	if(ismonkey(thrower) && istype(AM, /obj/item/ammo_casing/foam_dart))
		pop_balloon(monkey_pop = TRUE)
	else
		return ..()

/obj/item/toy/balloon/bullet_act(obj/projectile/proj)
	if((istype(proj, /obj/projectile/bullet/p50) || istype(proj,/obj/projectile/bullet/foam_dart)) && ismonkey(proj.firer))
		pop_balloon(monkey_pop = TRUE)
		return BULLET_ACT_HIT
	return ..()

/obj/item/toy/balloon/proc/pop_balloon(monkey_pop = FALSE)
	playsound(src, 'sound/effects/cartoon_sfx/cartoon_pop.ogg', 50, vary = TRUE)
	if(monkey_pop) // Monkeys make money from popping bloons
		new /obj/item/coin/iron(get_turf(src))
	qdel(src)

/obj/item/toy/balloon/Initialize(mapload)
	. = ..()
	AddElement(/datum/element/update_icon_updates_onmob)
	if(!random_color)
		return
	current_color = pick(BALLOON_COLORS)
	update_appearance()

/obj/item/toy/balloon/update_name(updates)
	. = ..()
	name = "[current_color ? "[current_color] ":null][initial(name)]"

/obj/item/toy/balloon/vv_edit_var(vname, vval)
	. = ..()
	if(vname == NAMEOF(src, current_color))
		update_appearance()

/obj/item/toy/balloon/update_icon_state()
	. = ..()
	var/new_icon = "[initial(icon_state)][current_color ? "_[current_color]":null]"
	inhand_icon_state = new_icon
	icon_state = "[new_icon][isturf(loc) ? null : "_storage"]"

/obj/item/toy/balloon/Moved(atom/old_loc, movement_dir, forced, list/old_locs, momentum_change)
	. = ..()
	update_appearance()

/obj/item/toy/balloon/corgi
	name = "corgi balloon"
	desc = "A balloon in the shape of a corgi's head. For the all year good boys."
	icon_state = "corgi"
	inhand_icon_state = "corgi"
	random_color = FALSE

/obj/item/toy/balloon/heart
	name = "heart balloon"
	desc = "A balloon in the shape of a heart. How lovely"
	icon_state = "heart"
	inhand_icon_state = "heart"
	random_color = FALSE

/obj/item/toy/balloon/syndicate
	name = "syndicate balloon"
	desc = "There is a tag on the back that reads \"FUK NT!11!\"."
	icon_state = "syndballoon"
	inhand_icon_state = "syndballoon"
	random_color = FALSE

/obj/item/toy/balloon/syndicate/pickup(mob/living/user)
	. = ..()
	if(user && user.mind && user.mind.has_antag_datum(/datum/antagonist, TRUE))
		user.add_mood_event("badass_antag", /datum/mood_event/badass_antag)

/obj/item/toy/balloon/syndicate/dropped(mob/living/user)
	if(user)
		user.clear_mood_event("badass_antag")
	. = ..()

/obj/item/toy/balloon/syndicate/Destroy()
	if(ismob(loc))
		var/mob/living/M = loc
		M.clear_mood_event("badass_antag")
	. = ..()

/obj/item/toy/balloon/arrest
	name = "arreyst balloon"
	desc = "A half inflated balloon about a boyband named Arreyst that was popular about ten years ago, famous for making fun of red jumpsuits as unfashionable."
	icon_state = "arrestballoon"
	inhand_icon_state = "arrestballoon"
	random_color = FALSE

#undef BALLOON_COLORS

/*
* Balloon animals
*/

/obj/item/toy/balloon_animal
	name = "balloon animal"
	desc = "You shouldn't have this."
	icon = 'icons/obj/toys/balloons.dmi'
	inhand_icon_state = "balloon"
	lefthand_file = 'icons/mob/inhands/items/balloons_lefthand.dmi'
	righthand_file = 'icons/mob/inhands/items/balloons_righthand.dmi'
	throwforce = 0
	throw_speed = 2
	throw_range = 5
	force = 0

/obj/item/toy/balloon_animal/guy
	name = "balloon guy"
	desc = "A balloon effigy of the everyday standard issue human guy. Wonder if he pays balloon taxes. He probably evades them."
	icon_state = "balloon_guy"

/obj/item/toy/balloon_animal/nukie
	name = "balloon nukie"
	desc = "A balloon effigy of syndicate's nuclear operative. Either made to appease them and pray for survival, or to poke fun at them."
	icon_state = "balloon_nukie"

/obj/item/toy/balloon_animal/clown
	name = "balloon clown"
	desc = "A balloon clown, smiling from ear to ear and beyond!"
	icon_state = "balloon_clown"

/obj/item/toy/balloon_animal/cat
	name = "balloon cat"
	desc = "Without the sharp claws, balloon cats are possibly cuter than their live counterparts, though not as relatable, warm and fuzzy."
	icon_state = "balloon_cat"

/obj/item/toy/balloon_animal/fly
	name = "balloon fly"
	desc = "A balloon effigy of a flyperson. Thankfully, it doesn't come with balloon vomit."
	icon_state = "balloon_fly"

/obj/item/toy/balloon_animal/podguy
	name = "balloon podguy"
	desc = "A balloon effigy of a podperson. Though, actual podpeople have heads and not stalks and leaves."
	icon_state = "balloon_podguy"

/obj/item/toy/balloon_animal/ai
	name = "balloon ai core"
	desc = "A somewhat unrealistic balloon effigy of the station's AI core. Actual AI probably wouldn't smile like this."
	icon_state = "balloon_ai"

/obj/item/toy/balloon_animal/dog
	name = "balloon dog"
	desc = "A balloon effigy of the best boy. It cannot truly compare, but it makes an effort."
	icon_state = "balloon_dog"

/obj/item/toy/balloon_animal/xeno
	name = "balloon xeno"
	desc = "A balloon effigy of a spooky xeno! Too squishy to scare anyone itself, though."
	icon_state = "balloon_xeno"

/obj/item/toy/balloon_animal/banana
	name = "balloon banana"
	desc = "A balloon banana. This one can't be slipped on. Good for psychological warfare, though."
	icon_state = "balloon_banana"

/obj/item/toy/balloon_animal/lizard
	name = "balloon lizard"
	desc = "A balloon effigy of a lizard. One of the first species to adapt to clown planet's culture. Perhaps because they are naturally laughable?"
	icon_state = "balloon_lizard"

/obj/item/toy/balloon_animal/slime
	name = "balloon slime"
	desc = "A balloon effigy of single specimen of the galaxy-wide slime scourge, of purple variety. Slimes tried to invade clown planet once. They got quickly washed out by water-spitting flowers, though."
	icon_state = "balloon_slime"

/obj/item/toy/balloon_animal/moth
	name = "balloon moth"
	desc = "A balloon effigy of a common member of moth flotillas. Very few of them ever decide to settle on the clown planet, but those who do have the best 'piece-of-cloth-disappearing' acts."
	icon_state = "balloon_moth"

/obj/item/toy/balloon_animal/ethereal
	name = "balloon ethereal"
	desc = "A balloon effigy of an ethereal artisan. Clownery is one form of art, and as such, ethereals were both drawn to and readily accepted at clown planet. Don't mind the lighbulb head, it's art too."
	icon_state = "balloon_ethereal"

/obj/item/toy/balloon_animal/plasmaman
	name = "balloon plasmaman"
	desc = "A balloon effigy of a plasmaman. Among the rarest on the clown planet, only having appeared recently thanks to ready trade between clown planet and NT."
	icon_state = "balloon_plasmaman"


/*
* Captain's Aid
*/
#define CAPTAINSAID_MODE_OFF 1

/obj/item/toy/captainsaid
	name = "\improper Captain's Aid"
	desc = "Every captain's greatest ally when exploring the vast emptiness of space, now with a color display!"
	icon = 'icons/obj/toys/toy.dmi'
	icon_state = "captainsaid_off"
	custom_price = PAYCHECK_COMMAND * 1.25

	/// List of modes it can cycle through
	var/list/modes = list(
		"off",
		"port",
		"starboard",
		"fore",
		"aft",
	)
	/// Current mode of the item, changed when cycling through modes
	var/current_mode = CAPTAINSAID_MODE_OFF

/obj/item/toy/captainsaid/examine_more(mob/user)
	. = ..()
	. += span_notice("You could swear you've been hearing advertisments for the 'soon upcoming' release of a tablet version for the better part of 3 years...")

/obj/item/toy/captainsaid/attack_self(mob/living/user)
	current_mode++
	playsound(src, 'sound/items/tools/screwdriver2.ogg', 50, vary = TRUE)
	if (current_mode <= modes.len)
		balloon_alert(user, "set to [current_mode]")
	else
		balloon_alert(user, "turned off")
		current_mode = CAPTAINSAID_MODE_OFF
	icon_state = "captainsaid_[modes[current_mode]]"
	update_appearance(UPDATE_ICON)

#undef CAPTAINSAID_MODE_OFF

/obj/item/toy/captainsaid/collector
	name = "\improper Collector's Edition Captain's Aid"
	desc = "A copy of the first run of Captain's Aid ever released. Functionally the same as the later batches, just more expensive. For the truly aristocratic."

/*
 * Fake singularity
 */
/obj/item/toy/spinningtoy
	name = "gravitational singularity"
	desc = "\"Singulo\" brand spinning toy."
	icon = 'icons/obj/machines/engine/singularity.dmi'
	icon_state = "singularity_s1"
	item_flags = NO_PIXEL_RANDOM_DROP

/obj/item/toy/spinningtoy/suicide_act(mob/living/carbon/human/user)
	var/obj/item/bodypart/head/myhead = user.get_bodypart(BODY_ZONE_HEAD)
	if(!myhead)
		user.visible_message(span_suicide("[user] tries consuming [src]... but [user.p_they()] [user.p_have()] no mouth!")) // and i must scream
		return SHAME
	user.visible_message(span_suicide("[user] consumes [src]! It looks like [user.p_theyre()] trying to commit suicide!"))
	playsound(user, 'sound/items/eatfood.ogg', 50, TRUE)
	user.adjust_nutrition(50) // mmmm delicious
	addtimer(CALLBACK(src, PROC_REF(manual_suicide), user), (3 SECONDS))
	return MANUAL_SUICIDE

/**
 * Internal function used in the toy singularity suicide
 *
 * Cavity implants the toy singularity into the body of the user (arg1), and kills the user.
 * Makes the user vomit and receive 120 suffocation damage if there already is a cavity implant in the user.
 * Throwing the singularity away will cause the user to start choking themself to death.
 * Arguments:
 * * user - Whoever is doing the suiciding
 */
/obj/item/toy/spinningtoy/proc/manual_suicide(mob/living/carbon/human/user)
	if(!user)
		return
	if(!user.is_holding(src)) // Half digestion? Start choking to death
		user.visible_message(span_suicide("[user] panics and starts choking [user.p_them()]self to death!"))
		user.adjustOxyLoss(200)
		user.death(FALSE) // unfortunately you have to handle the suiciding yourself with a manual suicide
		user.ghostize(FALSE) // get the fuck out of our body
		return
	var/obj/item/bodypart/chest/CH = user.get_bodypart(BODY_ZONE_CHEST)
	if(CH.cavity_item) // if he's (un)bright enough to have a round and full belly...
		user.visible_message(span_danger("[user] regurgitates [src]!")) // I swear i dont have a fetish
		user.vomit(VOMIT_CATEGORY_BLOOD, lost_nutrition = 100, distance = 0)
		user.adjustOxyLoss(120)
		user.dropItemToGround(src) // incase the crit state doesn't drop the singulo to the floor
		user.set_suicide(FALSE)
		return
	user.transferItemToLoc(src, user, TRUE)
	CH.cavity_item = src // The mother came inside and found Andy, dead with a HUGE belly full of toys
	user.adjustOxyLoss(200) // You know how most small toys in the EU have that 3+ onion head icon and a warning that says "Unsuitable for children under 3 years of age due to small parts - choking hazard"? This is why.
	user.death(FALSE)
	user.ghostize(FALSE)

/*
 * Fake dark matter singularity!
 */
/obj/item/toy/spinningtoy/dark_matter
	name = "dark matter singularity"
	desc = "<i>\"Surviving the encounter with the \
		horrible thing, I realized immediately what I \
		had to do: sell marketable toys of it. \
		\"</i><br>- Chief Engineer Tenshin Nakamura"
	icon = 'icons/obj/machines/engine/singularity.dmi'
	icon_state = "dark_matter_s1"

/*
 * Toy gun: Why isn't this an /obj/item/gun?
 */
/obj/item/toy/gun
	name = "cap gun"
	desc = "Looks almost like the real thing! Ages 8 and up. Please recycle in an autolathe when you're out of caps."
	icon = 'icons/obj/weapons/guns/ballistic.dmi'
	icon_state = "revolver"
	inhand_icon_state = "gun"
	worn_icon_state = "gun"
	lefthand_file = 'icons/mob/inhands/weapons/guns_lefthand.dmi'
	righthand_file = 'icons/mob/inhands/weapons/guns_righthand.dmi'
	obj_flags = CONDUCTS_ELECTRICITY
	slot_flags = ITEM_SLOT_BELT
	w_class = WEIGHT_CLASS_NORMAL
	custom_materials = list(/datum/material/iron = SMALL_MATERIAL_AMOUNT * 0.1, /datum/material/glass= SMALL_MATERIAL_AMOUNT * 0.1)
	attack_verb_continuous = list("strikes", "pistol whips", "hits", "bashes")
	attack_verb_simple = list("strike", "pistol whip", "hit", "bash")
	var/bullets = 7

/obj/item/toy/gun/examine(mob/user)
	. = ..()
	. += "There [bullets == 1 ? "is" : "are"] [bullets] cap\s left."

/obj/item/toy/gun/attackby(obj/item/toy/ammo/gun/A, mob/user, params)

	if(istype(A, /obj/item/toy/ammo/gun))
		if (src.bullets >= 7)
			to_chat(user, span_warning("It's already fully loaded!"))
			return 1
		if (A.amount_left <= 0)
			to_chat(user, span_warning("There are no more caps!"))
			return 1
		if (A.amount_left < (7 - src.bullets))
			src.bullets += A.amount_left
			to_chat(user, span_notice("You reload [A.amount_left] cap\s."))
			A.amount_left = 0
		else
			to_chat(user, span_notice("You reload [7 - src.bullets] cap\s."))
			A.amount_left -= 7 - src.bullets
			src.bullets = 7
		A.update_appearance()
		return 1
	else
		return ..()

/obj/item/toy/gun/ranged_interact_with_atom(atom/interacting_with, mob/living/user, list/modifiers)
	if(!ISADVANCEDTOOLUSER(user))
		to_chat(user, span_warning("You don't have the dexterity to do this!"))
		return ITEM_INTERACT_BLOCKING
	src.add_fingerprint(user)
	if (src.bullets < 1)
		user.show_message(span_warning("*click*"), MSG_AUDIBLE)
		playsound(src, 'sound/items/weapons/gun/revolver/dry_fire.ogg', 30, TRUE)
		return ITEM_INTERACT_SUCCESS
	playsound(user, 'sound/items/weapons/gun/revolver/shot.ogg', 100, TRUE)
	src.bullets--
	user.visible_message(span_danger("[user] fires [src] at [interacting_with]!"), \
		span_danger("You fire [src] at [interacting_with]!"), \
		span_hear("You hear a gunshot!"))
	return ITEM_INTERACT_SUCCESS

/obj/item/toy/ammo/gun
	name = "capgun ammo"
	desc = "Make sure to recycle the box in an autolathe when it gets empty."
	icon = 'icons/obj/weapons/guns/ammo.dmi'
	icon_state = "357OLD-7"
	w_class = WEIGHT_CLASS_TINY
	custom_materials = list(/datum/material/iron= SMALL_MATERIAL_AMOUNT * 0.1, /datum/material/glass= SMALL_MATERIAL_AMOUNT * 0.1)
	var/amount_left = 7

/obj/item/toy/ammo/gun/update_icon_state()
	icon_state = "357OLD-[amount_left]"
	return ..()

/obj/item/toy/ammo/gun/examine(mob/user)
	. = ..()
	. += "There [amount_left == 1 ? "is" : "are"] [amount_left] cap\s left."

/*
 * Toy swords
 */
/obj/item/toy/sword
	name = "toy sword"
	desc = "A cheap, plastic replica of an energy sword. Realistic sounds! Ages 8 and up."
	icon_state = "e_sword"
	inhand_icon_state = "e_sword"
	icon_angle = -45
	icon = 'icons/obj/weapons/transforming_energy.dmi'
	lefthand_file = 'icons/mob/inhands/weapons/swords_lefthand.dmi'
	righthand_file = 'icons/mob/inhands/weapons/swords_righthand.dmi'
	w_class = WEIGHT_CLASS_SMALL
	attack_verb_continuous = list("attacks", "strikes", "hits")
	attack_verb_simple = list("attack", "strike", "hit")
	/// Whether our sword has been multitooled to rainbow
	var/hacked = FALSE
	/// The color of our fake energy sword
	var/saber_color = "blue"

/obj/item/toy/sword/Initialize(mapload)
	. = ..()
	AddComponent( \
		/datum/component/transforming, \
		throw_speed_on = throw_speed, \
		hitsound_on = hitsound, \
		clumsy_check = FALSE, \
		inhand_icon_change = FALSE, \
	)
	RegisterSignal(src, COMSIG_TRANSFORMING_ON_TRANSFORM, PROC_REF(on_transform))
	AddElement(/datum/element/update_icon_updates_onmob)

	var/static/list/tool_behaviors = list(
		TOOL_SCREWDRIVER = list(
			SCREENTIP_CONTEXT_LMB = "Change blade color"
		),
	)
	AddElement(/datum/element/contextual_screentip_tools, tool_behaviors)

/*
 * Signal proc for [COMSIG_TRANSFORMING_ON_TRANSFORM].
 *
 * Updates our icon to have the correct color, and give some feedback.
 */
/obj/item/toy/sword/proc/on_transform(obj/item/source, mob/user, active)
	SIGNAL_HANDLER

	if(user)
		balloon_alert(user, "[active ? "flicked out":"pushed in"] [src]")

	playsound(src, active ? 'sound/items/weapons/saberon.ogg' : 'sound/items/weapons/saberoff.ogg', 20, TRUE)
	update_appearance(UPDATE_ICON)
	return COMPONENT_NO_DEFAULT_MESSAGE

/obj/item/toy/sword/examine(mob/user)
	. = ..()
	. += span_notice("It has a lighting dial currently set to [saber_color] which looks like it can be turned with a <b>screwdriver</b>.")

/obj/item/toy/sword/screwdriver_act(mob/living/user, obj/item/tool)
	switch(saber_color)
		if("red")
			saber_color = "blue"
		if("blue")
			saber_color = "green"
		if("green")
			saber_color = "purple"
		if("purple")
			saber_color = "red"
		else
			return ITEM_INTERACT_SUCCESS
	balloon_alert(user, "changed to [saber_color]")
	update_appearance(UPDATE_ICON)
	return ITEM_INTERACT_SUCCESS

/obj/item/toy/sword/vv_edit_var(vname, vval)
	. = ..()
	if(vname == NAMEOF(src, saber_color))
		update_appearance(UPDATE_ICON)

/obj/item/toy/sword/update_icon_state()
	. = ..()
	var/last_part = HAS_TRAIT(src, TRAIT_TRANSFORM_ACTIVE) ? "_on[saber_color ? "_[saber_color]" : null]" : null
	icon_state = "[initial(icon_state)][last_part]"
	inhand_icon_state = "[initial(inhand_icon_state)][last_part]"

/obj/item/toy/sword/multitool_act(mob/living/user, obj/item/tool)
	if(hacked)
		to_chat(user, span_warning("It's already fabulous!"))
		return
	hacked = TRUE
	saber_color = "rainbow"
	to_chat(user, span_warning("RNBW_ENGAGE"))
	update_appearance(UPDATE_ICON)


// Copied from /obj/item/melee/energy/sword/attackby
/obj/item/toy/sword/attackby(obj/item/weapon, mob/living/user, params)
	if(istype(weapon, /obj/item/toy/sword))
		var/obj/item/toy/sword/attatched_sword = weapon
		if(HAS_TRAIT(weapon, TRAIT_NODROP))
			to_chat(user, span_warning("[weapon] is stuck to your hand, you can't attach it to [src]!"))
			return
		else if(HAS_TRAIT(src, TRAIT_NODROP))
			to_chat(user, span_warning("[src] is stuck to your hand, you can't attach it to [weapon]!"))
			return
		else
			to_chat(user, span_notice("You attach the ends of the two plastic swords, making a single double-bladed toy! You're fake-cool."))
			var/obj/item/dualsaber/toy/new_saber = new /obj/item/dualsaber/toy(user.loc)
			if(attatched_sword.hacked || hacked)
				new_saber.hacked = TRUE
				new_saber.saber_color = "rainbow"
			qdel(weapon)
			qdel(src)
			user.put_in_hands(new_saber)
	else
		return ..()

/*
 * Foam armblade
 */
/obj/item/toy/foamblade
	name = "foam armblade"
	desc = "It says \"Sternside Changs #1 fan\" on it."
	icon = 'icons/obj/toys/toy.dmi'
	icon_state = "foamblade"
	inhand_icon_state = "arm_blade"
	icon_angle = -180
	lefthand_file = 'icons/mob/inhands/antag/changeling_lefthand.dmi'
	righthand_file = 'icons/mob/inhands/antag/changeling_righthand.dmi'
	attack_verb_continuous = list("pricks", "absorbs", "gores")
	attack_verb_simple = list("prick", "absorb", "gore")
	w_class = WEIGHT_CLASS_SMALL
	resistance_flags = FLAMMABLE

/obj/item/toy/windup_toolbox
	name = "windup toolbox"
	desc = "A replica toolbox that rumbles when you turn the key."
	icon = 'icons/obj/storage/toolbox.dmi'
	icon_state = "green"
	inhand_icon_state = "artistic_toolbox"
	lefthand_file = 'icons/mob/inhands/equipment/toolbox_lefthand.dmi'
	righthand_file = 'icons/mob/inhands/equipment/toolbox_righthand.dmi'
	hitsound = 'sound/items/weapons/smash.ogg'
	drop_sound = 'sound/items/handling/toolbox/toolbox_drop.ogg'
	pickup_sound = 'sound/items/handling/toolbox/toolbox_pickup.ogg'
	attack_verb_continuous = list("robusts")
	attack_verb_simple = list("robust")
	var/active = FALSE

/obj/item/toy/windup_toolbox/Initialize(mapload)
	. = ..()
	update_appearance()

/obj/item/toy/windup_toolbox/update_overlays()
	. = ..()
	if(active)
		. += "single_latch_open"
	else
		. += "single_latch"

/obj/item/toy/windup_toolbox/attack_self(mob/user)
	if(!active)
		to_chat(user, span_notice("You wind up [src], it begins to rumble."))
		active = TRUE
		update_appearance()
		playsound(src, 'sound/effects/pope_entry.ogg', 100)
		Rumble()
		addtimer(CALLBACK(src, PROC_REF(stopRumble)), 60 SECONDS)
	else
		to_chat(user, span_warning("[src] is already active!"))

/obj/item/toy/windup_toolbox/proc/Rumble()
	var/static/list/transforms
	if(!transforms)
		var/matrix/M1 = matrix()
		var/matrix/M2 = matrix()
		var/matrix/M3 = matrix()
		var/matrix/M4 = matrix()
		M1.Translate(-1, 0)
		M2.Translate(0, 1)
		M3.Translate(1, 0)
		M4.Translate(0, -1)
		transforms = list(M1, M2, M3, M4)
	animate(src, transform=transforms[1], time=0.2, loop=-1)
	animate(transform=transforms[2], time=0.1)
	animate(transform=transforms[3], time=0.2)
	animate(transform=transforms[4], time=0.3)

/obj/item/toy/windup_toolbox/proc/stopRumble()
	active = FALSE
	update_appearance()
	visible_message(span_warning("[src] slowly stops rattling and falls still, its latch snapping shut.")) //subtle difference
	playsound(loc, 'sound/items/weapons/batonextend.ogg', 100, TRUE)
	animate(src, transform = matrix())

/*
 * Subtype of Double-Bladed Energy Swords
 */
/obj/item/dualsaber/toy
	name = "double-bladed toy sword"
	desc = "A cheap, plastic replica of TWO energy swords.  Double the fun!"
	force = 0
	throwforce = 0
	throw_speed = 3
	throw_range = 5
	two_hand_force = 0
	attack_verb_continuous = list("attacks", "strikes", "hits")
	attack_verb_simple = list("attack", "strike", "hit")

/obj/item/dualsaber/toy/hit_reaction(mob/living/carbon/human/owner, atom/movable/hitby, attack_text = "the attack", final_block_chance = 0, damage = 0, attack_type = MELEE_ATTACK, damage_type = BRUTE)
	return 0

/obj/item/dualsaber/toy/IsReflect() //Stops Toy Dualsabers from reflecting energy projectiles
	return 0

/obj/item/dualsaber/toy/impale(mob/living/user)//Stops Toy Dualsabers from injuring clowns
	to_chat(user, span_warning("You twirl around a bit before losing your balance and impaling yourself on [src]."))
	user.adjustStaminaLoss(25)

/obj/item/toy/katana
	name = "replica katana"
	desc = "Woefully underpowered in D20."
	icon = 'icons/obj/weapons/sword.dmi'
	icon_state = "katana"
	inhand_icon_state = "katana"
	worn_icon_state = "katana"
	icon_angle = -45
	lefthand_file = 'icons/mob/inhands/weapons/swords_lefthand.dmi'
	righthand_file = 'icons/mob/inhands/weapons/swords_righthand.dmi'
	obj_flags = CONDUCTS_ELECTRICITY
	slot_flags = ITEM_SLOT_BELT | ITEM_SLOT_BACK
	force = 5
	throwforce = 5
	w_class = WEIGHT_CLASS_NORMAL
	attack_verb_continuous = list("attacks", "slashes", "slices")
	attack_verb_simple = list("attack", "slash", "slice")
	hitsound = 'sound/items/weapons/bladeslice.ogg'
	var/list/alt_continuous = list("stabs", "pierces", "impales")
	var/list/alt_simple = list("stab", "pierce", "impale")

/obj/item/toy/katana/Initialize(mapload)
	. = ..()
	alt_continuous = string_list(alt_continuous)
	alt_simple = string_list(alt_simple)
	AddComponent(/datum/component/alternative_sharpness, SHARP_POINTY, alt_continuous, alt_simple)

/*
 * Snap pops
 */
/obj/item/toy/snappop
	name = "snap pop"
	desc = "Wow!"
	icon = 'icons/obj/toys/toy.dmi'
	icon_state = "snappop"
	w_class = WEIGHT_CLASS_TINY
	var/ash_type = /obj/effect/decal/cleanable/ash

/obj/item/toy/snappop/proc/pop_burst(n=3, c=1)
	var/datum/effect_system/spark_spread/s = new()
	s.set_up(n, c, src)
	s.start()
	new ash_type(loc)
	visible_message(span_warning("[src] explodes!"),
		span_hear("You hear a snap!"))
	playsound(src, 'sound/effects/snap.ogg', 50, TRUE)
	qdel(src)

/obj/item/toy/snappop/fire_act(exposed_temperature, exposed_volume)
	pop_burst()

/obj/item/toy/snappop/throw_impact(atom/hit_atom, datum/thrownthing/throwingdatum)
	if(!..())
		pop_burst()

/obj/item/toy/snappop/Initialize(mapload)
	. = ..()
	var/static/list/loc_connections = list(
		COMSIG_ATOM_ENTERED = PROC_REF(on_entered),
	)
	AddElement(/datum/element/connect_loc, loc_connections)

/obj/item/toy/snappop/proc/on_entered(datum/source, H as mob|obj)
	SIGNAL_HANDLER
	if(ishuman(H) || issilicon(H)) //i guess carp and shit shouldn't set them off
		var/mob/living/carbon/M = H
		if(issilicon(H) || M.move_intent == MOVE_INTENT_RUN)
			to_chat(M, span_danger("You step on the snap pop!"))
			pop_burst(2, 0)

/obj/item/toy/snappop/phoenix
	name = "phoenix snap pop"
	desc = "Wow! And wow! And wow!"
	ash_type = /obj/effect/decal/cleanable/ash/snappop_phoenix

/obj/effect/decal/cleanable/ash/snappop_phoenix
	var/respawn_time = 300

/obj/effect/decal/cleanable/ash/snappop_phoenix/Initialize(mapload)
	. = ..()
	addtimer(CALLBACK(src, PROC_REF(respawn)), respawn_time)

/obj/effect/decal/cleanable/ash/snappop_phoenix/proc/respawn()
	new /obj/item/toy/snappop/phoenix(get_turf(src))
	qdel(src)

/obj/item/toy/talking
	name = "talking action figure"
	desc = "A generic action figure modeled after nothing in particular."
	icon = 'icons/obj/toys/toy.dmi'
	icon_state = "owlprize"
	w_class = WEIGHT_CLASS_SMALL
	var/cooldown = FALSE
	var/messages = list("I'm super generic!", "Mathematics class is of variable difficulty!")
	var/span = "danger"
	var/recharge_time = 30

	var/chattering = FALSE
	var/phomeme

// Talking toys are language universal, and thus all species can use them
/obj/item/toy/talking/attack_alien(mob/user, list/modifiers)
	return attack_hand(user, modifiers)

/obj/item/toy/talking/attack_self(mob/user)
	if(!cooldown)
		activation_message(user)
		playsound(loc, 'sound/machines/click.ogg', 20, TRUE)

		INVOKE_ASYNC(src, PROC_REF(do_toy_talk), user)

		cooldown = TRUE
		addtimer(VARSET_CALLBACK(src, cooldown, FALSE), recharge_time)
		return
	..()

/obj/item/toy/talking/proc/activation_message(mob/user)
	user.visible_message(
		span_notice("[user] pulls the string on \the [src]."),
		span_notice("You pull the string on \the [src]."),
		span_notice("You hear a string being pulled."))

/obj/item/toy/talking/proc/generate_messages()
	return list(pick(messages))

/obj/item/toy/talking/proc/do_toy_talk(mob/user)
	for(var/message in generate_messages())
		toy_talk(user, message)
		sleep(1 SECONDS)

/obj/item/toy/talking/proc/toy_talk(mob/user, message)
	say(message, spans = list(span))
	if(chattering)
		chatter(message, phomeme, user)

/*
 * AI core prizes
 */
/obj/item/toy/talking/ai
	name = "toy AI"
	desc = "A little toy model AI core with real law announcing action!"
	icon_state = "AI"
	w_class = WEIGHT_CLASS_SMALL

/obj/item/toy/talking/ai/generate_messages()
	return list(generate_ion_law())

/obj/item/toy/talking/codex_gigas
	name = "Toy Codex Gigas"
	desc = "A tool to help you write fictional devils!"
	icon = 'icons/obj/service/library.dmi'
	icon_state = "demonomicon"
	lefthand_file = 'icons/mob/inhands/items/books_lefthand.dmi'
	righthand_file = 'icons/mob/inhands/items/books_righthand.dmi'
	messages = list("You must challenge the devil to a dance-off!", "The devils true name is Ian", "The devil hates salt!", "Would you like infinite power?", "Would you like infinite wisdom?", "Would you like infinite healing?")
	w_class = WEIGHT_CLASS_SMALL
	recharge_time = 60

/obj/item/toy/talking/codex_gigas/activation_message(mob/user)
	user.visible_message(
		span_notice("[user] presses the button on \the [src]."),
		span_notice("You press the button on \the [src]."),
		span_notice("You hear a soft click."))

/obj/item/toy/talking/owl
	name = "owl action figure"
	desc = "An action figure modeled after 'The Owl', defender of justice."
	icon_state = "owlprize"
	messages = list("You won't get away this time, Griffin!", "Stop right there, criminal!", "Hoot! Hoot!", "I am the night!")
	chattering = TRUE
	phomeme = "owl"
	w_class = WEIGHT_CLASS_SMALL

/obj/item/toy/talking/griffin
	name = "griffin action figure"
	desc = "An action figure modeled after 'The Griffin', criminal mastermind."
	icon_state = "griffinprize"
	messages = list("You can't stop me, Owl!", "My plan is flawless! The vault is mine!", "Caaaawwww!", "You will never catch me!")
	chattering = TRUE
	phomeme = "griffin"
	w_class = WEIGHT_CLASS_SMALL

/*
 * Fake nuke
 */
/obj/item/toy/nuke
	name = "\improper Nuclear Fission Explosive toy"
	desc = "A plastic model of a Nuclear Fission Explosive."
	icon = 'icons/obj/toys/toy.dmi'
	icon_state = "nuketoyidle"
	w_class = WEIGHT_CLASS_SMALL
	var/cooldown = 0

/obj/item/toy/nuke/attack_self(mob/user)
	if (obj_flags & EMAGGED && cooldown < world.time)
		cooldown = world.time + 600
		user.audible_message(span_hear("You hear the click of a button."), self_message = span_notice("You activate [src], it plays a loud noise!"))
		sleep(0.5 SECONDS)
		playsound(src, 'sound/announcer/alarm/nuke_alarm.ogg', 20, FALSE)
		sleep(14 SECONDS)
		user.visible_message(span_alert("[src] violently explodes!"))
		explosion(src, light_impact_range = 1)
		qdel(src)
	else if (cooldown < world.time)
		cooldown = world.time + 600 //1 minute
		user.visible_message(span_warning("[user] presses a button on [src]."), span_notice("You activate [src], it plays a loud noise!"), span_hear("You hear the click of a button."))
		sleep(0.5 SECONDS)
		icon_state = "nuketoy"
		playsound(src, 'sound/announcer/alarm/nuke_alarm.ogg', 20, FALSE)
		sleep(13.5 SECONDS)
		icon_state = "nuketoycool"
		sleep(cooldown - world.time)
		icon_state = "nuketoyidle"
	else
		var/timeleft = (cooldown - world.time)
		to_chat(user, span_alert("Nothing happens, and '</span>[round(timeleft/10)]<span class='alert'>' appears on the small display."))
		sleep(0.5 SECONDS)

/obj/item/toy/nuke/emag_act(mob/user, obj/item/card/emag/emag_card)
	if (obj_flags & EMAGGED)
		return FALSE
	balloon_alert(user, "explosive simulation enabled")
	obj_flags |= EMAGGED
	return TRUE

/*
 * Fake meteor
 */
/obj/item/toy/minimeteor
	name = "\improper Mini-Meteor"
	desc = "Relive the excitement of a meteor shower! SweetMeat-eor Co. is not responsible for any injuries, headaches or hearing loss caused by Mini-Meteor."
	icon = 'icons/obj/toys/toy.dmi'
	icon_state = "minimeteor"
	inhand_icon_state = "minimeteor"
	w_class = WEIGHT_CLASS_SMALL

/obj/item/toy/minimeteor/emag_act(mob/user, obj/item/card/emag/emag_card)
	if (obj_flags & EMAGGED)
		return FALSE
	to_chat(user, span_warning("You short circuit whatever electronics exist inside. The \"meteor\" suddenly feels a lot heavier...?"))
	// not adding a balloon alert here since its hard to actually describe what this emag does in the balloon
	obj_flags |= EMAGGED
	return TRUE

/obj/item/toy/minimeteor/throw_impact(atom/hit_atom, datum/thrownthing/throwingdatum)
	playsound(src, 'sound/effects/meteorimpact.ogg', 40, TRUE)
	for(var/mob/M in urange(10, src))
		if(!M.stat && !isAI(M))
			shake_camera(M, 3, 1)
	if (obj_flags & EMAGGED)
		explosion(src, devastation_range = -1, heavy_impact_range = -1, light_impact_range = 1)

/*
 * Toy big red button
 */
/obj/item/toy/redbutton
	name = "big red button"
	desc = "A big, plastic red button. Reads 'From HonkCo Pranks!' on the back."
	icon = 'icons/obj/devices/assemblies.dmi'
	icon_state = "bigred"
	w_class = WEIGHT_CLASS_SMALL
	var/cooldown = 0

/obj/item/toy/redbutton/attack_self(mob/user)
	if (cooldown < world.time)
		cooldown = (world.time + 300) // Sets cooldown at 30 seconds
		user.visible_message(span_warning("[user] presses the big red button."), span_notice("You press the button, it plays a loud noise!"), span_hear("The button clicks loudly."))
		playsound(src, 'sound/effects/explosion/explosionfar.ogg', 50, FALSE)
		for(var/mob/M in urange(10, src)) // Checks range
			if(!M.stat && !isAI(M)) // Checks to make sure whoever's getting shaken is alive/not the AI
				// Short delay to match up with the explosion sound
				// Shakes player camera 2 squares for 1 second.
				addtimer(CALLBACK(GLOBAL_PROC, GLOBAL_PROC_REF(shake_camera), M, 2, 1), 0.8 SECONDS)

	else
		to_chat(user, span_alert("Nothing happens."))

/*
 * Snowballs
 */
/obj/item/toy/snowball
	name = "snowball"
	desc = "A compact ball of snow. Good for throwing at people."
	icon = 'icons/obj/toys/toy.dmi'
	icon_state = "snowball"
	throwforce = 20 //the same damage as a disabler shot
	damtype = STAMINA //maybe someday we can add stuffing rocks (or perhaps ore?) into snowballs to make them deal brute damage

/obj/item/toy/snowball/ranged_interact_with_atom(atom/interacting_with, mob/living/user, list/modifiers)
	user.throw_item(interacting_with)
	return ITEM_INTERACT_SUCCESS

/obj/item/toy/snowball/throw_impact(atom/hit_atom, datum/thrownthing/throwingdatum)
	if(!..())
		playsound(src, 'sound/effects/pop.ogg', 20, TRUE)
		qdel(src)

/*
 * Beach ball
 */
/obj/item/toy/beach_ball
	name = "beach ball"
	icon = 'icons/obj/fluff/beach.dmi'
	icon_state = "ball"
	inhand_icon_state = "beachball"
	w_class = WEIGHT_CLASS_BULKY //Stops people from hiding it in their bags/pockets
	item_flags = NO_PIXEL_RANDOM_DROP

/obj/item/toy/beach_ball/branded
	name = "\improper Nanotrasen-brand beach ball"
	desc = "The simple beach ball is one of Nanotrasen's most popular products. 'Why do we make beach balls? Because we can! (TM)' - Nanotrasen"

/obj/item/toy/beach_ball/baseball
	name = "baseball"
	desc = "Enter the world of concussions and become who you were destined to be."
	icon = 'icons/obj/toys/balls.dmi'
	icon_state = "baseball"
	inhand_icon_state = "baseball"
	w_class = WEIGHT_CLASS_SMALL
	throw_range = 9
	throw_speed = 0.5

/*
 * Clockwork Watch
 */
/obj/item/toy/clockwork_watch
	name = "steampunk watch"
	desc = "A stylish steampunk watch made out of thousands of tiny cogwheels."
	icon = 'icons/obj/toys/toy.dmi'
	icon_state = "dread_ipad"
	worn_icon_state = "dread_ipad"
	slot_flags = ITEM_SLOT_BELT
	w_class = WEIGHT_CLASS_SMALL
	var/cooldown = 0

/obj/item/toy/clockwork_watch/attack_self(mob/user)
	if (cooldown < world.time)
		cooldown = world.time + 1800 //3 minutes
		user.visible_message(span_warning("[user] rotates a cogwheel on [src]."), span_notice("You rotate a cogwheel on [src], it plays a loud noise!"), span_hear("You hear cogwheels turning."))
		playsound(src, 'sound/effects/magic/clockwork/ark_activation.ogg', 50, FALSE)
	else
		to_chat(user, span_alert("The cogwheels are already turning!"))

/obj/item/toy/clockwork_watch/examine(mob/user)
	. = ..()
	. += span_info("Station Time: [station_time_timestamp()]")

/*
 * Toy Dagger
 */
/obj/item/toy/toy_dagger
	name = "toy dagger"
	desc = "A cheap plastic replica of a dagger. Produced by THE ARM Toys, Inc."
	icon = 'icons/obj/weapons/khopesh.dmi'
	icon_state = "render"
	inhand_icon_state = "cultdagger"
	icon_angle = -45
	lefthand_file = 'icons/mob/inhands/weapons/swords_lefthand.dmi'
	righthand_file = 'icons/mob/inhands/weapons/swords_righthand.dmi'
	w_class = WEIGHT_CLASS_SMALL

/*
 * Xenomorph action figure
 */
/obj/item/toy/toy_xeno
	icon = 'icons/obj/toys/toy.dmi'
	icon_state = "toy_xeno"
	name = "xenomorph action figure"
	desc = "MEGA presents the new Xenos Isolated action figure! Comes complete with realistic sounds! Pull back string to use."
	w_class = WEIGHT_CLASS_SMALL
	var/cooldown = 0

/obj/item/toy/toy_xeno/attack_self(mob/user)
	if(cooldown <= world.time)
		cooldown = (world.time + 50) //5 second cooldown
		user.visible_message(span_notice("[user] pulls back the string on [src]."))
		icon_state = "[initial(icon_state)]_used"
		sleep(0.5 SECONDS)
		audible_message(span_danger("[icon2html(src, viewers(src))] Hiss!"))
		var/list/possible_sounds = list('sound/mobs/non-humanoids/hiss/hiss1.ogg', 'sound/mobs/non-humanoids/hiss/hiss2.ogg', 'sound/mobs/non-humanoids/hiss/hiss3.ogg', 'sound/mobs/non-humanoids/hiss/hiss4.ogg')
		var/chosen_sound = pick(possible_sounds)
		playsound(get_turf(src), chosen_sound, 50, TRUE)
		addtimer(VARSET_CALLBACK(src, icon_state, "[initial(icon_state)]"), 4.5 SECONDS)
	else
		to_chat(user, span_warning("The string on [src] hasn't rewound all the way!"))
		return

// TOY MOUSEYS :3 :3 :3
/obj/item/toy/cattoy
	name = "toy mouse"
	desc = "A colorful toy mouse!"
	icon = 'icons/obj/toys/toy.dmi'
	icon_state = "toy_mouse"
	w_class = WEIGHT_CLASS_SMALL
	var/cooldown = 0
	resistance_flags = FLAMMABLE


/*
 * Action Figures
 */
/obj/item/toy/figure
	name = "\improper Non-Specific Action Figure action figure"
	icon = 'icons/obj/toys/toy.dmi'
	icon_state = "nuketoy"
	var/cooldown = 0
	var/toysay = "What the fuck did you do?"
	var/toysound = 'sound/machines/click.ogg'
	w_class = WEIGHT_CLASS_SMALL

/obj/item/toy/figure/Initialize(mapload)
	. = ..()
	desc = "A \"Space Life\" brand [src]."
	AddElement(/datum/element/toy_talk)

/obj/item/toy/figure/attack_self(mob/user as mob)
	if(cooldown <= world.time)
		cooldown = world.time + 50
		to_chat(user, span_notice("[src] says \"[toysay]\""))
		playsound(user, toysound, 20, TRUE)

/obj/item/toy/figure/cmo
	name = "\improper Chief Medical Officer action figure"
	icon_state = "cmo"
	toysay = "Suit sensors!"

/obj/item/toy/figure/assistant
	name = "\improper Assistant action figure"
	icon_state = "assistant"
	inhand_icon_state = "assistant"
	toysay = "Greytide world wide!"

/obj/item/toy/figure/atmos
	name = "\improper Atmospheric Technician action figure"
	icon_state = "atmos"
	toysay = "Glory to Atmosia!"

/obj/item/toy/figure/bartender
	name = "\improper Bartender action figure"
	icon_state = "bartender"
	toysay = "Where is Pun Pun?"

/obj/item/toy/figure/bitrunner
	name = "\improper Bitrunner action figure"
	icon_state = "bitrunner"
	toysay = "I'm in..."

/obj/item/toy/figure/borg
	name = "\improper Cyborg action figure"
	icon_state = "borg"
	toysay = "I. LIVE. AGAIN."
	toysound = 'sound/mobs/non-humanoids/cyborg/liveagain.ogg'

/obj/item/toy/figure/botanist
	name = "\improper Botanist action figure"
	icon_state = "botanist"
	toysay = "Blaze it!"

/obj/item/toy/figure/captain
	name = "\improper Captain action figure"
	icon_state = "captain"
	toysay = "Any heads of staff?"

/obj/item/toy/figure/cargotech
	name = "\improper Cargo Technician action figure"
	icon_state = "cargotech"
	toysay = "For Cargonia!"

/obj/item/toy/figure/ce
	name = "\improper Chief Engineer action figure"
	icon_state = "ce"
	toysay = "Wire the solars!"

/obj/item/toy/figure/chaplain
	name = "\improper Chaplain action figure"
	icon_state = "chaplain"
	toysay = "Praise Space Jesus!"

/obj/item/toy/figure/chef
	name = "\improper Cook action figure"
	icon_state = "chef"
	toysay = "I'll make you into a burger!"

/obj/item/toy/figure/chemist
	name = "\improper Chemist action figure"
	icon_state = "chemist"
	toysay = "Get your pills!"

/obj/item/toy/figure/clown
	name = "\improper Clown action figure"
	icon_state = "clown"
	toysay = "Honk!"
	toysound = 'sound/items/bikehorn.ogg'

/obj/item/toy/figure/ian
	name = "\improper Ian action figure"
	icon_state = "ian"
	toysay = "Arf!"

/obj/item/toy/figure/detective
	name = "\improper Detective action figure"
	icon_state = "detective"
	toysay = "This airlock has grey jumpsuit and insulated glove fibers on it."

/obj/item/toy/figure/dsquad
	name = "\improper Deathsquad Officer action figure"
	icon_state = "dsquad"
	toysay = "Kill 'em all!"

/obj/item/toy/figure/engineer
	name = "\improper Station Engineer action figure"
	icon_state = "engineer"
	toysay = "Oh god, the singularity is loose!"

/obj/item/toy/figure/geneticist
	name = "\improper Geneticist action figure"
	icon_state = "geneticist"
	toysay = "Smash!"

/obj/item/toy/figure/hop
	name = "\improper Head of Personnel action figure"
	icon_state = "hop"
	toysay = "Giving out all access!"

/obj/item/toy/figure/hos
	name = "\improper Head of Security action figure"
	icon_state = "hos"
	toysay = "Go ahead, make my day."

/obj/item/toy/figure/qm
	name = "\improper Quartermaster action figure"
	icon_state = "qm"
	toysay = "Please sign this form in triplicate and we will see about geting you a welding mask within 3 business days."

/obj/item/toy/figure/janitor
	name = "\improper Janitor action figure"
	icon_state = "janitor"
	toysay = "Look at the signs, you idiot."

/obj/item/toy/figure/lawyer
	name = "\improper Lawyer action figure"
	icon_state = "lawyer"
	toysay = "My client is a dirty traitor!"

/obj/item/toy/figure/curator
	name = "\improper Curator action figure"
	icon_state = "curator"
	toysay = "One day while..."

/obj/item/toy/figure/md
	name = "\improper Medical Doctor action figure"
	icon_state = "md"
	toysay = "The patient is already dead!"

/obj/item/toy/figure/coroner
	name = "\improper Coroner action figure"
	icon_state = "coroner"
	toysay = "Get the damn Revenant outta here!"

/obj/item/toy/figure/paramedic
	name = "\improper Paramedic action figure"
	icon_state = "paramedic"
	toysay = "And the best part? I'm not even a real doctor!"

/obj/item/toy/figure/psychologist
	name = "\improper Psychologist action figure"
	icon_state = "psychologist"
	toysay = "Alright, just take these happy pills!"

/obj/item/toy/figure/prisoner
	name = "\improper Prisoner action figure"
	icon_state = "prisoner"
	toysay = "I did not hit her! I did not!"

/obj/item/toy/figure/mime
	name = "\improper Mime action figure"
	icon_state = "mime"
	toysay = "..."
	toysound = null

/obj/item/toy/figure/miner
	name = "\improper Shaft Miner action figure"
	icon_state = "miner"
	toysay = "COLOSSUS RIGHT OUTSIDE THE BASE!"

/obj/item/toy/figure/ninja
	name = "\improper Space Ninja action figure"
	icon_state = "ninja"
	toysay = "I am the shadow warrior!"

/obj/item/toy/figure/wizard
	name = "\improper Wizard action figure"
	icon_state = "wizard"
	toysay = "EI NATH!"
	toysound = 'sound/effects/magic/disintegrate.ogg'

/obj/item/toy/figure/wizard/special
	name = "\improper Wizard action figure special edition"
	toysay = "CLANG!";
	toysound = 'sound/effects/clang.ogg'

/obj/item/toy/figure/rd
	name = "\improper Research Director action figure"
	icon_state = "rd"
	toysay = "Blowing all of the borgs!"

/obj/item/toy/figure/roboticist
	name = "\improper Roboticist action figure"
	icon_state = "roboticist"
	toysay = "Big stompy mechs!"
	toysound = 'sound/vehicles/mecha/mechstep.ogg'

/obj/item/toy/figure/scientist
	name = "\improper Scientist action figure"
	icon_state = "scientist"
	toysay = "I call ordnance."
	toysound = 'sound/effects/explosion/explosionfar.ogg'

/obj/item/toy/figure/syndie
	name = "\improper Nuclear Operative action figure"
	icon_state = "syndie"
	toysay = "Get that fucking disk!"

/obj/item/toy/figure/secofficer
	name = "\improper Security Officer action figure"
	icon_state = "secofficer"
	toysay = "I am the law!"
	toysound = 'sound/runtime/complionator/dredd.ogg'


/obj/item/toy/figure/warden
	name = "\improper Warden action figure"
	icon_state = "warden"
	toysay = "Seventeen minutes for coughing at an officer!"

/obj/item/toy/dummy
	name = "ventriloquist dummy"
	desc = "It's a dummy, dummy."
	icon = 'icons/obj/toys/toy.dmi'
	icon_state = "puppet"
	inhand_icon_state = "puppet"
	var/doll_name = "Dummy"

//Add changing looks when i feel suicidal about making 20 inhands for these.
/obj/item/toy/dummy/attack_self(mob/user)
	var/new_name = tgui_input_text(usr, "What would you like to name the dummy?", "Doll Name", doll_name, max_length = MAX_NAME_LEN)
	if(!new_name || !user.is_holding(src))
		return
	doll_name = new_name
	to_chat(user, span_notice("You name the dummy as \"[doll_name]\"."))
	name = "[initial(name)] - [doll_name]"

/obj/item/toy/dummy/Initialize(mapload)
	. = ..()
	AddElement(/datum/element/toy_talk)

/obj/item/toy/dummy/GetVoice()
	return doll_name

/obj/item/toy/seashell
	name = "seashell"
	desc = "May you always have a shell in your pocket and sand in your shoes. Whatever that's supposed to mean."
	icon = 'icons/obj/fluff/beach.dmi'
	icon_state = "shell1"
	var/static/list/possible_colors = list("" = 2, COLOR_PURPLE_GRAY = 1, COLOR_OLIVE = 1, COLOR_PALE_BLUE_GRAY = 1, COLOR_RED_GRAY = 1)

/obj/item/toy/seashell/Initialize(mapload)
	. = ..()
	pixel_x = rand(-5, 5)
	pixel_y = rand(-5, 5)
	icon_state = "shell[rand(1,3)]"
	color = pick_weight(possible_colors)
	setDir(pick(GLOB.cardinals))

/obj/item/toy/brokenradio
	name = "broken radio"
	desc = "An old radio that produces nothing but static when turned on."
	icon = 'icons/obj/toys/toy.dmi'
	icon_state = "broken_radio"
	w_class = WEIGHT_CLASS_SMALL
	var/cooldown = 0

/obj/item/toy/brokenradio/attack_self(mob/user)
	if(cooldown <= world.time)
		cooldown = (world.time + 300)
		user.visible_message(span_notice("[user] adjusts the dial on [src]."))
		addtimer(CALLBACK(GLOBAL_PROC, GLOBAL_PROC_REF(playsound), src, 'sound/items/radiostatic.ogg', 50, FALSE), 0.5 SECONDS)
	else
		to_chat(user, span_warning("The dial on [src] jams up"))
		return

/obj/item/toy/braintoy
	name = "squeaky brain"
	desc = "A Mr. Monstrous brand toy made to imitate a human brain in smell and texture."
	icon = 'icons/obj/medical/organs/organs.dmi'
	icon_state = "brain-old"
	var/cooldown = 0

/obj/item/toy/braintoy/attack_self(mob/user)
	if(cooldown <= world.time)
		cooldown = (world.time + 10)
		addtimer(CALLBACK(GLOBAL_PROC, GLOBAL_PROC_REF(playsound), src, 'sound/effects/blob/blobattack.ogg', 50, FALSE), 0.5 SECONDS)

/*
 * Eldritch Toys
 */
/obj/item/toy/eldritch_book
	name = "Codex Cicatrix"
	desc = "A toy book that closely resembles the Codex Cicatrix. Covered in fake polyester human flesh and has a huge googly eye attached to the cover. The runes are gibberish and cannot be used to summon demons... Hopefully?"
	icon = 'icons/obj/antags/eldritch.dmi'
	base_icon_state = "book"
	icon_state = "book"
	worn_icon_state = "book"
	w_class = WEIGHT_CLASS_SMALL
	attack_verb_continuous = list("sacrifices", "transmutes", "graspes", "curses")
	attack_verb_simple = list("sacrifice", "transmute", "grasp", "curse")
	/// Helps determine the icon state of this item when it's used on self.
	var/book_open = FALSE
	/// id for timer
	var/timer_id

/obj/item/toy/eldritch_book/attack_self(mob/user, modifiers)
	. = ..()
	if(.)
		return

	if(book_open)
		close_animation()
	else
		open_animation()

/// Plays a little animation that shows the book opening and closing.
/obj/item/toy/eldritch_book/proc/open_animation()
	icon_state = "[base_icon_state]_open"
	flick("[base_icon_state]_opening", src)
	book_open = TRUE

	timer_id = addtimer(CALLBACK(src, PROC_REF(close_animation)), 5 SECONDS, TIMER_UNIQUE|TIMER_OVERRIDE|TIMER_STOPPABLE)

/// Plays a closing animation and resets the icon state.
/obj/item/toy/eldritch_book/proc/close_animation()
	icon_state = base_icon_state
	flick("[base_icon_state]_closing", src)
	book_open = FALSE

	deltimer(timer_id)

/*
 * Fake tear
 */
/obj/item/toy/reality_pierce
	name = "Pierced reality"
	desc = "Hah. You thought it was the real deal!"
	icon = 'icons/effects/eldritch.dmi'
	icon_state = "pierced_illusion"
	item_flags = NO_PIXEL_RANDOM_DROP

/obj/item/storage/box/heretic_box
	name = "box of pierced realities"
	desc = "A box containing toys resembling pierced realities."

/obj/item/storage/box/heretic_box/PopulateContents()
	for(var/i in 1 to rand(1,4))
		new /obj/item/toy/reality_pierce(src)

/obj/item/toy/foamfinger
	name = "foam finger"
	desc = "root for the home team! wait, does this station even have a sports team?"
	icon = 'icons/obj/weapons/guns/ballistic.dmi'
	icon_state = "foamfinger"
	inhand_icon_state = "foamfinger_inhand"
	lefthand_file = 'icons/mob/inhands/weapons/guns_lefthand.dmi'
	righthand_file = 'icons/mob/inhands/weapons/guns_righthand.dmi'
	w_class = WEIGHT_CLASS_NORMAL
	COOLDOWN_DECLARE(foamfinger_cooldown)

/obj/item/toy/foamfinger/attack_self(mob/living/carbon/human/user)
	if(!COOLDOWN_FINISHED(src, foamfinger_cooldown))
		return
	COOLDOWN_START(src, foamfinger_cooldown, 5 SECONDS)
	user.manual_emote("waves around the foam finger.")
	var/direction = prob(50) ? -1 : 1
	if(NSCOMPONENT(user.dir))
		animate(user, pixel_w = (1 * direction), time = 0.1 SECONDS, easing = SINE_EASING, flags = ANIMATION_RELATIVE|ANIMATION_PARALLEL)
		animate(pixel_w = (-2 * direction), time = 0.1 SECONDS, easing = SINE_EASING, flags = ANIMATION_RELATIVE)
		animate(pixel_w = (2 * direction), time = 0.1 SECONDS, easing = SINE_EASING, flags = ANIMATION_RELATIVE)
		animate(pixel_w = (-2 * direction), time = 0.1 SECONDS, easing = SINE_EASING, flags = ANIMATION_RELATIVE)
		animate(pixel_w = (1 * direction), time = 0.1 SECONDS, easing = SINE_EASING, flags = ANIMATION_RELATIVE)
	else
		animate(user, pixel_z = (1 * direction), time = 0.1 SECONDS, easing = SINE_EASING, flags = ANIMATION_RELATIVE|ANIMATION_PARALLEL)
		animate(pixel_z = (-2 * direction), time = 0.1 SECONDS, easing = SINE_EASING, flags = ANIMATION_RELATIVE)
		animate(pixel_z = (2 * direction), time = 0.1 SECONDS, easing = SINE_EASING, flags = ANIMATION_RELATIVE)
		animate(pixel_z = (-2 * direction), time = 0.1 SECONDS, easing = SINE_EASING, flags = ANIMATION_RELATIVE)
		animate(pixel_z = (1 * direction), time = 0.1 SECONDS, easing = SINE_EASING, flags = ANIMATION_RELATIVE)
	user.changeNext_move(CLICK_CD_MELEE)

///All people who have used an Intento this round along with their high scores.
GLOBAL_LIST_EMPTY(intento_players)

#define HELP "help"
#define DISARM "disarm"
#define GRAB "grab"
#define HARM "harm"
#define ICON_SPLIT ICON_SIZE_ALL/2

// These states do not have any associated processing.
#define STATE_AWAITING_PLAYER_INPUT "awaiting_player_input"
#define STATE_OFF "off"

// When the Intento is in one of these four states, it has an accompanying
// set of code that runs in processing()
#define STATE_STARTING "starting"
#define STATE_DEMO "demo"
#define STATE_END_OF_GAME "end_of_game"
#define STATE_RETALIATION "retaliation"

#define TIME_TO_BEGIN (1.6 SECONDS)
#define TIME_PER_DEMO_STEP (0.6 SECONDS)
#define TIME_TO_RESET_ICON (0.5 SECONDS)

/obj/item/toy/intento
	name = "\improper Intento"
	desc = "Fundamentally useless for all intents and purposes."
	icon = 'icons/obj/toys/intents.dmi'
	icon_state = "blank"
	custom_price = PAYCHECK_COMMAND * 1.25

	/// Current sequence of intents
	var/list/current_sequence = list()
	/// Sequence player inputs
	var/list/player_sequence = list()
	/// Score of the player
	var/score = 0
	/// Associated list of intents to their sounds
	var/static/list/sound_by_intent = list(
		HELP = 'sound/items/intents/Help.ogg',
		DISARM = 'sound/items/intents/Disarm.ogg',
		GRAB = 'sound/items/intents/Grab.ogg',
		HARM = 'sound/items/intents/Harm.ogg',
		)

	/// What state the toy is in.
	var/state = STATE_OFF
	/// Index used for iteration of steps for both demo and retaliation states
	var/index
	/// Time to delay until we start processing whatever state we're in
	COOLDOWN_DECLARE(next_process)
	/// Time until we reset the icon of the Intento
	COOLDOWN_DECLARE(next_icon_reset)

/obj/item/toy/intento/attack_self(mob/user, modifiers) //added params to attack_self, the alternative is registering a signal on clickon but i was advised not to
	..()
	if(state == STATE_OFF)
		boot()
		return

	if(!modifiers)
		return

	if(state != STATE_AWAITING_PLAYER_INPUT)
		return

	var/input
	var/icon_x = text2num(modifiers[ICON_X])
	var/icon_y = text2num(modifiers[ICON_Y])
	if(icon_x > ICON_SPLIT && icon_y > ICON_SPLIT)
		input = DISARM
	if(icon_x < ICON_SPLIT && icon_y > ICON_SPLIT)
		input = HELP
	if(icon_x > ICON_SPLIT && icon_y < ICON_SPLIT)
		input = GRAB
	if(icon_x < ICON_SPLIT && icon_y < ICON_SPLIT)
		input = HARM

	player_input(user, input)

/obj/item/toy/intento/proc/boot()
	say("Game starting!")
	playsound(src, 'sound/machines/synth/synth_yes.ogg', 50, FALSE)

	state = STATE_STARTING
	COOLDOWN_START(src, next_process, TIME_TO_BEGIN)
	START_PROCESSING(SSfastprocess, src)

/obj/item/toy/intento/proc/player_input(mob/player, intent)
	// All branches of this proc lead to us wanting to process
	START_PROCESSING(SSfastprocess, src)

	render(intent)

	player_sequence += intent
	for(var/i in 1 to player_sequence.len)
		if(player_sequence[i] != current_sequence[i])
			state = STATE_END_OF_GAME
			COOLDOWN_START(src, next_process, TIME_TO_RESET_ICON)
			return

	if(player_sequence.len == current_sequence.len)
		score++

		state = STATE_STARTING
		COOLDOWN_START(src, next_process, TIME_TO_BEGIN)

/obj/item/toy/intento/process()
	if(next_icon_reset && next_icon_reset <= world.time)
		icon_state = initial(icon_state)
		COOLDOWN_RESET(src, next_icon_reset)

	if(next_process && next_process > world.time)
		return

	switch(state)
		if(STATE_STARTING)
			process_start()

		if(STATE_DEMO)
			process_demo()

		if(STATE_END_OF_GAME)
			process_end(isliving(loc) ? loc : null)

		if(STATE_RETALIATION)
			process_retaliation()

	if(!next_process && !next_icon_reset)
		return PROCESS_KILL

/obj/item/toy/intento/proc/process_start()
	player_sequence.Cut()

	current_sequence += pick(list(HELP, DISARM, GRAB, HARM))

	state = STATE_DEMO
	next_process = world.time
	index = 1

/obj/item/toy/intento/proc/process_demo()
	if(index > length(current_sequence))
		state = STATE_AWAITING_PLAYER_INPUT
		COOLDOWN_RESET(src, next_process)
		return

	var/intent = current_sequence[index]
	render(intent)

	index += 1
	COOLDOWN_START(src, next_process, TIME_PER_DEMO_STEP)

/obj/item/toy/intento/proc/process_end(mob/user)
	if(user && GLOB.intento_players[user.ckey] < score)
		GLOB.intento_players[user.ckey] = score
		var/award_status = user.client.get_award_status(/datum/award/score/intento_score)
		var/award_score = score - award_status
		if(award_score > 0)
			user.client.give_award(/datum/award/score/intento_score, user, award_score)

	say("GAME OVER. Your score was [score]!")
	playsound(src, 'sound/machines/synth/synth_no.ogg', 50, FALSE)

	if(user && loc == user && obj_flags & EMAGGED)
		ADD_TRAIT(src, TRAIT_NODROP, type)
		to_chat(user, span_userdanger("Bad mistake."))

		state = STATE_RETALIATION
		next_process = world.time
		index = 1
	else
		cleanup()

/obj/item/toy/intento/proc/process_retaliation()
	var/mob/living/victim = loc
	if(!isliving(victim) || index > length(current_sequence))
		cleanup()
		return

	var/intent = current_sequence[index]
	render(intent)
	switch(intent)
		if(HELP)
			to_chat(victim, span_danger("[src] hugs you to make you feel better!"))
			victim.add_mood_event("hug", /datum/mood_event/hug)
		if(DISARM)
			to_chat(victim, span_danger("You're knocked down from a shove by [src]!"))
			victim.Knockdown(2 SECONDS)
		if(GRAB)
			to_chat(victim, span_danger("[src] grabs you aggressively!"))
			victim.Stun(2 SECONDS)
		if(HARM)
			to_chat(victim, span_danger("You're punched by [src]!"))
			victim.apply_damage(rand(20, 30), BRUTE)

	index += 1
	COOLDOWN_START(src, next_process, TIME_PER_DEMO_STEP)

/obj/item/toy/intento/proc/cleanup()
	score = 0
	index = 1
	player_sequence.Cut()
	current_sequence.Cut()

	state = STATE_OFF
	COOLDOWN_RESET(src, next_process)
	REMOVE_TRAIT(src, TRAIT_NODROP, type)

/obj/item/toy/intento/proc/render(input)
	icon_state = input
	playsound(src, sound_by_intent[input], 50, FALSE)

	START_PROCESSING(SSfastprocess, src)
	COOLDOWN_START(src, next_icon_reset, TIME_TO_RESET_ICON)

/obj/item/toy/intento/emag_act(mob/user, obj/item/card/emag/emag_card)
	if(obj_flags & EMAGGED)
		return FALSE
	obj_flags |= EMAGGED
	balloon_alert(user, "negative feedback loop enabled")
	return TRUE

/obj/item/toy/intento/Destroy()
	STOP_PROCESSING(SSfastprocess, src)
	return ..()

#undef HELP
#undef DISARM
#undef GRAB
#undef HARM
#undef ICON_SPLIT
#undef STATE_AWAITING_PLAYER_INPUT
#undef STATE_OFF
#undef STATE_STARTING
#undef STATE_DEMO
#undef STATE_END_OF_GAME
#undef STATE_RETALIATION
#undef TIME_TO_BEGIN
#undef TIME_PER_DEMO_STEP
#undef TIME_TO_RESET_ICON

/*
 * Runic Scepter
 */
/obj/item/toy/foam_runic_scepter
	name = "foam scepter"
	desc = "A foam replica of the scepters Wizards us on Vendormancy Soccer."
	icon_state = "vendor_staff"
	worn_icon_state = "vendor_staff" //For the back
	inhand_icon_state = "vendor_staff"
	lefthand_file = 'icons/mob/inhands/weapons/staves_lefthand.dmi'
	righthand_file = 'icons/mob/inhands/weapons/staves_righthand.dmi'
	icon = 'icons/obj/weapons/guns/magic.dmi'
	slot_flags = ITEM_SLOT_BACK
	attack_verb_continuous = list("smacks", "clubs", "wacks", "vendors")
	attack_verb_simple = list("smack", "club", "wack", "vendor")
	w_class = WEIGHT_CLASS_SMALL
	resistance_flags = FLAMMABLE
