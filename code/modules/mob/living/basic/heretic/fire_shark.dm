/mob/living/basic/heretic_summon/fire_shark
	name = "\improper Fire Shark"
	real_name = "Fire Shark"
	desc = "It is a eldritch dwarf space shark, also known as a fire shark."
	icon_state = "fire_shark"
	icon_living = "fire_shark"
	pass_flags = PASSTABLE | PASSMOB
	mob_biotypes = MOB_ORGANIC | MOB_BEAST | MOB_AQUATIC
	speed = -0.5
	health = 16
	maxHealth = 16
	melee_damage_lower = 8
	melee_damage_upper = 8
	attack_sound = 'sound/items/weapons/bite.ogg'
	attack_vis_effect = ATTACK_EFFECT_BITE
	obj_damage = 0
	attack_verb_continuous = "bites"
	attack_verb_simple = "bite"
	damage_coeff = list(BRUTE = 1, BURN = 0.25, TOX = 0, STAMINA = 0, OXY = 0)
	faction = list(FACTION_HERETIC)
	mob_size = MOB_SIZE_TINY
	speak_emote = list("screams")
	basic_mob_flags = DEL_ON_DEATH
	ai_controller = /datum/ai_controller/basic_controller/simple/simple_hostile_obstacles
	initial_language_holder = /datum/language_holder/carp/hear_common

/mob/living/basic/heretic_summon/fire_shark/Initialize(mapload)
	. = ..()
	AddElement(/datum/element/death_gases, /datum/gas/plasma, 40)
	AddElement(/datum/element/simple_flying)
	AddElement(/datum/element/venomous, /datum/reagent/phlogiston, 2, injection_flags = INJECT_CHECK_PENETRATE_THICK)
	AddComponent(/datum/component/swarming)
	AddComponent(/datum/component/regenerator, outline_colour = COLOR_DARK_RED)
	ADD_TRAIT(src, TRAIT_SPACEWALK, INNATE_TRAIT)
	ADD_TRAIT(src, TRAIT_FREE_HYPERSPACE_MOVEMENT, INNATE_TRAIT)
	ADD_TRAIT(src, TRAIT_VENTCRAWLER_ALWAYS, INNATE_TRAIT)

/mob/living/basic/heretic_summon/fire_shark/wild
	faction = list(FACTION_HOSTILE)
