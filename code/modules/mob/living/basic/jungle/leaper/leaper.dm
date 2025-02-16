/mob/living/basic/leaper
	name = "leaper"
	desc = "Commonly referred to as 'leapers', the Geron Toad is a massive beast that spits out highly pressurized bubbles containing a unique toxin, knocking down its prey and then crushing it with its girth."
	icon = 'icons/mob/simple/jungle/leaper.dmi'
	icon_state = "leaper"
	icon_living = "leaper"
	icon_dead = "leaper_dead"
	mob_biotypes = MOB_ORGANIC|MOB_BEAST

	melee_damage_lower = 15
	melee_damage_upper = 20
	maxHealth = 350
	health = 350
	speed = 10

	pixel_x = -16
	base_pixel_x = -16

	faction = list(FACTION_JUNGLE)
	obj_damage = 30

	unsuitable_atmos_damage = 0
	minimum_survivable_temperature = 0
	maximum_survivable_temperature = INFINITY

	attack_sound = 'sound/items/weapons/bladeslice.ogg'
	attack_vis_effect = ATTACK_EFFECT_SLASH
	status_flags = NONE
	lighting_cutoff_red = 5
	lighting_cutoff_green = 20
	lighting_cutoff_blue = 25
	mob_size = MOB_SIZE_LARGE
	ai_controller = /datum/ai_controller/basic_controller/leaper
	move_resist = MOVE_FORCE_VERY_STRONG
	pull_force = MOVE_FORCE_VERY_STRONG
	///appearance when we dead
	var/mutable_appearance/dead_overlay
	///appearance when we are alive
	var/mutable_appearance/living_overlay
	///list of pet commands we can issue
	var/list/pet_commands = list(
		/datum/pet_command/idle,
		/datum/pet_command/move,
		/datum/pet_command/free,
		/datum/pet_command/follow,
		/datum/pet_command/untargeted_ability/blood_rain,
		/datum/pet_command/untargeted_ability/summon_toad,
		/datum/pet_command/attack,
		/datum/pet_command/use_ability/flop,
		/datum/pet_command/use_ability/bubble,
	)

/mob/living/basic/leaper/Initialize(mapload)
	. = ..()
	AddElement(\
		/datum/element/change_force_on_death,\
		move_resist = MOVE_RESIST_DEFAULT,\
		pull_force = PULL_FORCE_DEFAULT,\
	)
	AddComponent(/datum/component/obeys_commands, pet_commands)
	AddComponent(/datum/component/seethrough_mob)
	AddElement(/datum/element/wall_smasher)
	AddElement(/datum/element/ridable, component_type = /datum/component/riding/creature/leaper)
	AddElement(/datum/element/footstep, footstep_type = FOOTSTEP_MOB_HEAVY)
	var/datum/action/cooldown/mob_cooldown/blood_rain/volley = new(src)
	volley.Grant(src)
	ai_controller.set_blackboard_key(BB_LEAPER_VOLLEY, volley)
	var/datum/action/cooldown/mob_cooldown/belly_flop/flop = new(src)
	flop.Grant(src)
	ai_controller.set_blackboard_key(BB_LEAPER_FLOP, flop)
	var/datum/action/cooldown/mob_cooldown/projectile_attack/leaper_bubble/bubble = new(src)
	bubble.Grant(src)
	ai_controller.set_blackboard_key(BB_LEAPER_BUBBLE, bubble)
	var/datum/action/cooldown/spell/conjure/limit_summons/create_suicide_toads/toads = new(src)
	toads.Grant(src)
	ai_controller.set_blackboard_key(BB_LEAPER_SUMMON, toads)

/mob/living/basic/leaper/proc/set_color_overlay(toad_color)
	dead_overlay = mutable_appearance(icon, "[icon_state]_dead_overlay")
	dead_overlay.color = toad_color

	living_overlay = mutable_appearance(icon, "[icon_state]_overlay")
	living_overlay.color = toad_color
	update_appearance(UPDATE_OVERLAYS)

/mob/living/basic/leaper/update_overlays()
	. = ..()
	if(stat == DEAD && dead_overlay)
		. += dead_overlay
		return

	if(living_overlay)
		. += living_overlay

/mob/living/basic/leaper/throw_at(atom/target, range, speed, mob/thrower, spin=1, diagonals_first = 0, datum/callback/callback, force, gentle = FALSE, quickstart = TRUE, throw_type_path = /datum/thrownthing)
	ADD_TRAIT(src, TRAIT_IMMOBILIZED, LEAPING_TRAIT)
	return ..()

/mob/living/basic/leaper/throw_impact(atom/hit_atom, datum/thrownthing/throwingdatum)
	. = ..()
	REMOVE_TRAIT(src, TRAIT_IMMOBILIZED, LEAPING_TRAIT)
