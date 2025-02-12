/// You can't make a dragon darker than this, it'd be hard to see
#define REJECT_DARK_COLOUR_THRESHOLD 20
/// Any interactions executed by the space dragon
#define DOAFTER_SOURCE_SPACE_DRAGON_INTERACTION "space dragon interaction"

/**
 * Advanced stage of the space carp life cycle, spawned as a midround antagonist
 * Can eat corpses to heal, blow people back with its wings, and obviously as a dragon it breathes fire. It can even tear through walls.
 * The midround even version also creates rifts which summon carp, and heals when near them.
 */
/mob/living/basic/space_dragon
	name = "Space Dragon"
	desc = "A serpentine leviathan whose flight defies all modern understanding of physics. Said to be the ultimate stage in the life cycle of the Space Carp."
	icon = 'icons/mob/nonhuman-player/spacedragon.dmi'
	icon_state = "spacedragon"
	icon_living = "spacedragon"
	icon_dead = "spacedragon_dead"
	health_doll_icon = "spacedragon"
	faction = list(FACTION_CARP)
	mob_biotypes = MOB_SPECIAL
	flags_1 = PREVENT_CONTENTS_EXPLOSION_1
	gender = NEUTER
	maxHealth = 400
	health = 400
	unsuitable_cold_damage = 0
	unsuitable_heat_damage = 0
	unsuitable_atmos_damage = 0
	damage_coeff = list(BRUTE = 1, BURN = 1, TOX = 1, STAMINA = 0.5, OXY = 1)
	combat_mode = TRUE
	speed = 0
	attack_verb_continuous = "chomps"
	attack_verb_simple = "chomp"
	attack_sound = 'sound/effects/magic/demon_attack1.ogg'
	attack_vis_effect = ATTACK_EFFECT_BITE
	obj_damage = 50
	melee_damage_upper = 35
	melee_damage_lower = 35
	melee_attack_cooldown = CLICK_CD_MELEE
	mob_size = MOB_SIZE_LARGE
	armour_penetration = 30
	pixel_x = -16
	base_pixel_x = -16
	maptext_height = 64
	maptext_width = 64
	mouse_opacity = MOUSE_OPACITY_ICON
	death_sound = 'sound/mobs/non-humanoids/space_dragon/space_dragon_roar.ogg'
	death_message = "screeches in agony as it collapses to the floor, its life extinguished."
	butcher_results = list(/obj/item/stack/ore/diamond = 5, /obj/item/stack/sheet/sinew = 5, /obj/item/stack/sheet/bone = 30)
	initial_language_holder = /datum/language_holder/carp/dragon
	can_buckle_to = FALSE
	lighting_cutoff_red = 12
	lighting_cutoff_green = 15
	lighting_cutoff_blue = 34

	/// The colour of the space dragon
	var/chosen_colour
	/// Minimum devastation damage dealt coefficient based on max health
	var/devastation_damage_min_percentage = 0.4
	/// Maximum devastation damage dealt coefficient based on max health
	var/devastation_damage_max_percentage = 0.75
	/// Our fire breath action
	var/datum/action/cooldown/mob_cooldown/fire_breath/carp/fire_breath
	/// Our wing flap action
	var/datum/action/cooldown/mob_cooldown/wing_buffet/buffet

	///Are currently sharkified or a plain space dragon?
	var/shark_form = FALSE
	///The amount of fish (weight) the space dragon has to eat to be sharkified and receive a cheevo for it.
	var/fish_left = 15000 // 30 fish with a weight of 500.

/mob/living/basic/space_dragon/Initialize(mapload)
	. = ..()
	add_traits(list(TRAIT_SPACEWALK, TRAIT_FREE_HYPERSPACE_MOVEMENT, TRAIT_NO_FLOATING_ANIM, TRAIT_HEALS_FROM_CARP_RIFTS), INNATE_TRAIT)
	AddElement(/datum/element/simple_flying)
	AddElement(/datum/element/content_barfer)
	AddElement(/datum/element/wall_tearer, tear_time = 4 SECONDS, reinforced_multiplier = 3, do_after_key = DOAFTER_SOURCE_SPACE_DRAGON_INTERACTION)
	AddElement(/datum/element/door_pryer, pry_time = 4 SECONDS, interaction_key = DOAFTER_SOURCE_SPACE_DRAGON_INTERACTION)
	AddComponent(/datum/component/seethrough_mob, keep_color = TRUE)
	AddComponent(/datum/component/profound_fisher, new /obj/item/fishing_rod/mob_fisher/dragon(src))
	RegisterSignal(src, COMSIG_HOSTILE_PRE_ATTACKINGTARGET, PROC_REF(pre_attack))
	RegisterSignal(src, COMSIG_MOB_STATCHANGE, PROC_REF(on_stat_changed))
	RegisterSignal(src, COMSIG_ATOM_PRE_EX_ACT, PROC_REF(on_exploded))

	fire_breath = new(src)
	fire_breath.Grant(src)

	buffet = new(src)
	buffet.Grant(src)

/mob/living/basic/space_dragon/Destroy()
	fire_breath = null
	buffet = null
	return ..()

/mob/living/basic/space_dragon/Login()
	. = ..()
	if(!isnull(chosen_colour))
		return
	if(client.get_award_status(/datum/award/achievement/misc/sharkdragon))
		if(tgui_alert(src, "Shall you take the dragon form or the shark form?","Shark Form Unlocked", list("Dragon","Shark")) == "Shark")
			sharkify()
	rename_dragon()
	select_colour()

/mob/living/basic/space_dragon/mind_initialize()
	. = ..()
	if(shark_form && mind.get_skill_level(/datum/skill/fishing) < SKILL_LEVEL_APPRENTICE)
		mind.set_level(/datum/skill/fishing, SKILL_LEVEL_APPRENTICE, TRUE)

/mob/living/basic/space_dragon/proc/sharkify()
	if(shark_form)
		return
	pixel_z -= 3
	base_pixel_z -= 3
	do_jitter_animation(150)
	shark_form = TRUE
	desc = "A piscine mutation of the fearsome leviathan whose flight defies modern physics. Said to be the other ultimate stage in the life cycle of the Space Carp."
	icon_state = icon_state == icon_living ? "sharkdragon" : "sharkdragon_dead"
	icon_living = "sharkdragon"
	icon_dead = "sharkdragon_dead"
	if(mind && mind.get_skill_level(/datum/skill/fishing) < SKILL_LEVEL_APPRENTICE)
		mind.set_level(/datum/skill/fishing, SKILL_LEVEL_APPRENTICE, TRUE)
	client?.give_award(/datum/award/achievement/misc/sharkdragon, src)
	update_appearance()

/// Allows the space dragon to pick a funny name
/mob/living/basic/space_dragon/proc/rename_dragon()
	var/chosen_name = sanitize_name(reject_bad_text(tgui_input_text(src, "What would you like your name to be?", "Choose Your Name", real_name, MAX_NAME_LEN)))
	if(!chosen_name) // Null or empty or rejected
		to_chat(src, span_warning("Not a valid name, please try again."))
		rename_dragon()
		return
	to_chat(src, span_notice("Your name is now [span_name("[chosen_name]")], the feared Space Dragon."))
	fully_replace_character_name(null, chosen_name)

/// Select scale colour with the colour picker
/mob/living/basic/space_dragon/proc/select_colour()
	chosen_colour = input(src, "What colour would you like to be?" ,"Colour Selection", COLOR_WHITE) as color|null
	if(!chosen_colour) // Redo proc until we get a color
		to_chat(src, span_warning("Not a valid colour, please try again."))
		select_colour()
		return
	var/list/skin_hsv = rgb2hsv(chosen_colour)
	if(skin_hsv[3] < REJECT_DARK_COLOUR_THRESHOLD)
		to_chat(src, span_danger("Invalid colour. Your colour is not bright enough."))
		select_colour()
		return
	add_atom_colour(chosen_colour, FIXED_COLOUR_PRIORITY)
	update_appearance(UPDATE_OVERLAYS)

/mob/living/basic/space_dragon/update_icon_state()
	. = ..()
	if (stat == DEAD)
		return
	if (!HAS_TRAIT(src, TRAIT_WING_BUFFET))
		icon_state = icon_living
		return
	if (HAS_TRAIT(src, TRAIT_WING_BUFFET_TIRED))
		icon_state = "[icon_living]_gust_2"
		return
	icon_state = "[icon_living]_gust"

/mob/living/basic/space_dragon/update_overlays()
	. = ..()
	var/overlay_state = "overlay_base"
	if (stat == DEAD)
		overlay_state = "overlay_dead"
	else if (HAS_TRAIT(src, TRAIT_WING_BUFFET_TIRED))
		overlay_state = "overlay_gust_2"
	else if (HAS_TRAIT(src, TRAIT_WING_BUFFET))
		overlay_state = "overlay_gust"

	var/mutable_appearance/overlay = mutable_appearance(icon, "[icon_living]_[overlay_state]")
	overlay.appearance_flags = RESET_COLOR
	// the overlay should inherit the atom color only if the dragon is dyed by colorful reagent or something
	if(!cached_color_filter)
		overlay.appearance_flags |= KEEP_APART
	. += overlay

/mob/living/basic/space_dragon/melee_attack(obj/vehicle/sealed/mecha/target, list/modifiers, ignore_cooldown)
	. = ..()
	if (!. || !ismecha(target))
		return
	target.take_damage(obj_damage, BRUTE, MELEE)

/// Before we attack something, check if we want to do something else instead
/mob/living/basic/space_dragon/proc/pre_attack(mob/living/source, atom/target)
	SIGNAL_HANDLER
	if (target == src)
		return COMPONENT_HOSTILE_NO_ATTACK // Easy to misclick yourself, let's not
	if (DOING_INTERACTION(source, DOAFTER_SOURCE_SPACE_DRAGON_INTERACTION))
		balloon_alert(source, "busy!")
		return COMPONENT_HOSTILE_NO_ATTACK
	if(isfish(target))
		INVOKE_ASYNC(src, PROC_REF(try_eat), target)
	if (!isliving(target))
		return
	var/mob/living/living_target = target
	if (living_target.stat != DEAD)
		return
	INVOKE_ASYNC(src, PROC_REF(try_eat), living_target)
	return COMPONENT_HOSTILE_NO_ATTACK

/// Try putting something inside us
/mob/living/basic/space_dragon/proc/try_eat(atom/movable/food)
	balloon_alert(src, "swallowing...")
	if (do_after(src, 3 SECONDS, target = food))
		if(isliving(food))
			eat(food)
		else if(isfish(food))
			eat_fish(food)

/// Succeed in putting something inside us
/mob/living/basic/space_dragon/proc/eat(mob/living/food)
	var/health_recovered = food.maxHealth * 0.25
	if(shark_form)
		if(istype(food, /mob/living/basic/carp))
			health_recovered *= 1.75 // plus 7.5 points when eating advanced space carps (from the rift)
		else
			health_recovered *= 0.75 // minus 7.5 points when eating a human for example.
	adjust_health(round(-health_recovered, 1))
	if (QDELETED(food) || food.loc == src)
		return FALSE
	playsound(src, 'sound/effects/magic/demon_attack1.ogg', 60, TRUE)
	visible_message(span_boldwarning("[src] swallows [food] whole!"))
	food.extinguish_mob() // It's wet in there, and our food is likely to be on fire. Let's be decent and not husk them.
	food.forceMove(src)
	return TRUE

/mob/living/basic/space_dragon/proc/eat_fish(obj/item/fish/fish)
	//a standard fish weights about 500 units on average, rarely exceeds 2000 units, the amount healed is less than a one fiftyth of our total on average.
	var/health_recovered = fish.weight * 0.014
	if(shark_form)
		health_recovered *= 2
	else
		fish_left -= fish.weight
		if(fish_left <= 0)
			addtimer(CALLBACK(src, PROC_REF(begin_sharkify)), 2 SECONDS)
			fish_left = initial(fish_left) //prevent begin_sharkify from being called again by eating another fish.
	adjust_health(round(-health_recovered, 1))
	playsound(src, 'sound/effects/magic/demon_attack1.ogg', 40, TRUE)
	visible_message(span_boldwarning("[src] swallows [fish] whole!"))
	if(HAS_TRAIT(fish, TRAIT_YUCKY_FISH))
		balloon_alert(src, "disgusting!")
		to_chat(src, span_warning("that [fish.name] tasted awful, you feel like you're about to throw up..."))
		addtimer(CALLBACK(src, PROC_REF(barf_contents)), 3 SECONDS)
	qdel(fish)

/mob/living/basic/space_dragon/proc/begin_sharkify()
	do_jitter_animation(300)
	addtimer(CALLBACK(src, PROC_REF(sharkify)), 1.2 SECONDS)
	visible_message(span_warning("[src] begins mutating!"))

/mob/living/basic/space_dragon/proc/barf_contents()
	if(stat == DEAD)
		return
	new /obj/effect/decal/cleanable/vomit(loc)
	playsound(src, 'sound/effects/splat.ogg', vol = 50, vary = TRUE)
	visible_message(span_danger("[src] vomits up everything it ate so far!"))
	for(var/atom/movable/eaten in src)
		if(HAS_TRAIT(eaten, TRAIT_NOT_BARFABLE))
			continue
		eaten.forceMove(eaten.loc)
		if(prob(90))
			step(eaten, pick(GLOB.alldirs))

/mob/living/basic/space_dragon/Entered(atom/movable/arrived, atom/old_loc, list/atom/old_locs)
	. = ..()
	if (isliving(arrived))
		RegisterSignal(arrived, COMSIG_MOB_STATCHANGE, PROC_REF(eaten_stat_changed))

/mob/living/basic/space_dragon/Exited(atom/movable/gone, direction)
	. = ..()
	if (isliving(gone))
		UnregisterSignal(gone, COMSIG_MOB_STATCHANGE)

/// Release consumed mobs if they transition from dead to alive
/mob/living/basic/space_dragon/proc/eaten_stat_changed(mob/living/eaten)
	SIGNAL_HANDLER
	if (eaten.stat == DEAD)
		return
	new /obj/effect/decal/cleanable/vomit(loc)
	playsound(src, 'sound/effects/splat.ogg', vol = 50, vary = TRUE)
	visible_message(span_danger("[src] vomits up [eaten]!"))
	eaten.forceMove(loc)
	eaten.Paralyze(5 SECONDS)

/mob/living/basic/space_dragon/RangedAttack(atom/target, modifiers)
	fire_breath.Trigger(target = target)

/mob/living/basic/space_dragon/ranged_secondary_attack(atom/target, modifiers)
	buffet.Trigger()

/// When our stat changes, make sure we are using the correct overlay
/mob/living/basic/space_dragon/proc/on_stat_changed()
	SIGNAL_HANDLER
	update_appearance(UPDATE_OVERLAYS)

/// We take devastating bomb damage as a random percentage of our maximum health instead of being gibbed
/mob/living/basic/space_dragon/proc/on_exploded(mob/living/source, severity, target, origin)
	SIGNAL_HANDLER
	if (severity != EXPLODE_DEVASTATE)
		return
	var/damage_coefficient = rand(devastation_damage_min_percentage, devastation_damage_max_percentage)
	adjustBruteLoss(initial(maxHealth)*damage_coefficient)
	return COMPONENT_CANCEL_EX_ACT // we handled it

/// Subtype used by the midround/event
/mob/living/basic/space_dragon/spawn_with_antag

/mob/living/basic/space_dragon/spawn_with_antag/mind_initialize()
	. = ..()
	mind.add_antag_datum(/datum/antagonist/space_dragon)

/// The internal fishing rod of our space dragon
/obj/item/fishing_rod/mob_fisher/dragon
	difficulty_modifier = -14
	hook = /obj/item/fishing_hook/jaws

#undef REJECT_DARK_COLOUR_THRESHOLD
#undef DOAFTER_SOURCE_SPACE_DRAGON_INTERACTION
