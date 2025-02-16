// 9mm (Makarov and Stechkin APS)

/obj/projectile/bullet/c9mm
	name = "9mm bullet"
	damage = 30
	embed_type = /datum/embedding/bullet_c9mm

/datum/embedding/bullet_c9mm
	embed_chance = 15
	fall_chance = 3
	jostle_chance = 4
	ignore_throwspeed_threshold = TRUE
	pain_stam_pct = 0.4
	pain_mult = 5
	jostle_pain_mult = 6
	rip_time = 1 SECONDS

/obj/projectile/bullet/c9mm/ap
	name = "9mm armor-piercing bullet"
	damage = 27
	armour_penetration = 40
	embed_type = null
	shrapnel_type = null

/obj/projectile/bullet/c9mm/hp
	name = "9mm hollow-point bullet"
	damage = 40
	weak_against_armour = TRUE

/obj/projectile/bullet/incendiary/c9mm
	name = "9mm incendiary bullet"
	damage = 15
	fire_stacks = 2

// 10mm

/obj/projectile/bullet/c10mm
	name = "10mm bullet"
	damage = 40

/obj/projectile/bullet/c10mm/ap
	name = "10mm armor-piercing bullet"
	damage = 35
	armour_penetration = 40

/obj/projectile/bullet/c10mm/hp
	name = "10mm hollow-point bullet"
	damage = 50
	weak_against_armour = TRUE

/obj/projectile/bullet/incendiary/c10mm
	name = "10mm incendiary bullet"
	damage = 20
	fire_stacks = 3

/obj/projectile/bullet/c10mm/reaper
	name = "10mm reaper pellet"
	damage = 50
	armour_penetration = 40
	tracer_type = /obj/effect/projectile/tracer/sniper
	impact_type = /obj/effect/projectile/impact/sniper
	muzzle_type = /obj/effect/projectile/muzzle/sniper
	hitscan = TRUE
	impact_effect_type = null
	hitscan_light_intensity = 3
	hitscan_light_range = 0.75
	hitscan_light_color_override = LIGHT_COLOR_DIM_YELLOW
	muzzle_flash_intensity = 5
	muzzle_flash_range = 1
	muzzle_flash_color_override = LIGHT_COLOR_DIM_YELLOW
	impact_light_intensity = 5
	impact_light_range = 1
	impact_light_color_override = LIGHT_COLOR_DIM_YELLOW

// .160 Smart

/obj/projectile/bullet/c160smart
	name = ".160 smart bullet"
	icon_state = "smartgun"
	damage = 10
	embed_type = /datum/embedding/bullet_c160smart
	speed = 0.5
	homing_turn_speed = 5
	homing_inaccuracy_min = 4
	homing_inaccuracy_max = 10

/datum/embedding/bullet_c160smart
	embed_chance = 10
	fall_chance = 5
	jostle_chance = 3
	ignore_throwspeed_threshold = TRUE
	pain_stam_pct = 0.25
	pain_mult = 3
	jostle_pain_mult = 6
	rip_time = 0.5 SECONDS
