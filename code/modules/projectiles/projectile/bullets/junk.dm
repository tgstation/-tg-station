// Junk (Pipe Pistols and Pipeguns)

/obj/projectile/bullet/junk
	name = "junk bullet"
	icon_state = "trashball"
	damage = 30
	embed_type = /datum/embedding/bullet_junk
	/// What biotype does our junk projectile especially harm?
	var/extra_damage_mob_biotypes = MOB_ROBOTIC
	/// How much do we multiply our total base damage?
	var/extra_damage_multiplier = 1.5
	/// How much extra damage do we do on top of this total damage? Separate from the multiplier and unaffected by it.
	var/extra_damage_added_damage = 0
	/// What damage type is our extra damage?
	var/extra_damage_type = BRUTE

/obj/projectile/bullet/junk/on_hit(atom/target, blocked = 0, pierce_hit)
	. = ..()

	if(!isliving(target))
		return
	var/mob/living/living_target = target

	var/is_correct_biotype = living_target.mob_biotypes & extra_damage_mob_biotypes
	if(extra_damage_mob_biotypes && is_correct_biotype)
		var/multiplied_damage = extra_damage_multiplier ? ((damage * extra_damage_multiplier) - damage) : 0
		var/finalized_damage = multiplied_damage + extra_damage_added_damage
		if(finalized_damage)
			living_target.apply_damage(finalized_damage, damagetype = extra_damage_type, def_zone = BODY_ZONE_CHEST, wound_bonus = wound_bonus)

/datum/embedding/bullet_junk
	embed_chance = 15
	fall_chance = 3
	jostle_chance = 4
	ignore_throwspeed_threshold = TRUE
	pain_stam_pct = 0.4
	pain_mult = 5
	jostle_pain_mult = 6
	rip_time = 1 SECONDS

/obj/projectile/bullet/incendiary/fire/junk
	name = "burning oil"
	damage = 30
	fire_stacks = 5
	suppressed = SUPPRESSED_NONE

/obj/projectile/bullet/junk/phasic
	name = "junk phasic bullet"
	icon_state = "gaussphase"
	projectile_phasing =  PASSTABLE | PASSGLASS | PASSGRILLE | PASSCLOSEDTURF | PASSMACHINE | PASSSTRUCTURE | PASSDOORS

/obj/projectile/bullet/junk/shock
	name = "bundle of live electrical parts"
	icon_state = "tesla_projectile"
	damage = 15
	embed_type = null
	shrapnel_type = null
	extra_damage_added_damage = 30
	extra_damage_type = BURN

/obj/projectile/bullet/junk/shock/on_hit(atom/target, blocked = 0, pierce_hit)
	. = ..()
	if(isliving(target))
		var/mob/living/victim = target
		victim.electrocute_act(damage, src, siemens_coeff = 1, flags = SHOCK_NOSTUN)

/obj/projectile/bullet/junk/hunter
	name = "junk hunter bullet"
	icon_state = "gauss"
	extra_damage_mob_biotypes = MOB_ROBOTIC | MOB_BEAST | MOB_SPECIAL
	extra_damage_multiplier = 0
	extra_damage_added_damage = 50

/obj/projectile/bullet/junk/ripper
	name = "junk ripper bullet"
	icon_state = "redtrac"
	damage = 10
	embed_type = /datum/embedding/bullet_junk_ripper
	wound_bonus = 10
	bare_wound_bonus = 30

/datum/embedding/bullet_junk_ripper
	embed_chance = 100
	fall_chance = 3
	jostle_chance = 4
	ignore_throwspeed_threshold = TRUE
	pain_stam_pct = 0.4
	pain_mult = 5
	jostle_pain_mult = 6
	rip_time = 1 SECONDS

/obj/projectile/bullet/junk/reaper
	name = "junk reaper bullet"
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
