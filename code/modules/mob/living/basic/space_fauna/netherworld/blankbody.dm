/mob/living/basic/blankbody
	name = "blank body"
	desc = "This looks human enough, but its flesh has an ashy texture, and it's face is featureless save an eerie smile."
	icon_state = "blank-body"
	icon_living = "blank-body"
	icon_dead = "blank-dead"
	health = 100
	maxHealth = 100
	obj_damage = 50
	melee_damage_lower = 2
	melee_damage_upper = 6
	speed = 1
	attack_verb_continuous = "punches"
	attack_verb_simple = "punch"
	attack_sound = 'sound/items/weapons/bladeslice.ogg'
	attack_vis_effect = ATTACK_EFFECT_SLASH
	melee_attack_cooldown = 1 SECONDS
	faction = list(FACTION_NETHER)
	speak_emote = list("screams")
	death_message = "falls apart into a fine dust."
	unsuitable_atmos_damage = 0
	unsuitable_cold_damage = 0
	unsuitable_heat_damage = 0
	// Pink, like their skin
	lighting_cutoff_red = 30
	lighting_cutoff_green = 15
	lighting_cutoff_blue = 40

	ai_controller = /datum/ai_controller/basic_controller/simple/simple_hostile_obstacles

/mob/living/basic/blankbody/Initialize(mapload)
	. = ..()
	AddElement(/datum/element/swabable, CELL_LINE_TABLE_NETHER, CELL_VIRUS_TABLE_GENERIC_MOB, 1, 0)
	AddComponent(/datum/component/health_scaling_effects, min_health_attack_modifier_lower = 8, min_health_attack_modifier_upper = 14)
