/obj/projectile/bullet/foam_dart
	name = "foam dart"
	desc = "I hope you're wearing eye protection."
	damage = 0 // It's a damn toy.
	damage_type = OXY
	icon = 'icons/obj/weapons/guns/toy.dmi'
	icon_state = "foamdart_proj"
	base_icon_state = "foamdart"
	range = 10
	embed_type = /datum/embedding/foam_dart
	shrapnel_type = /obj/item/ammo_casing/foam_dart
	embed_falloff_tile = 0
	var/modified = FALSE

/datum/embedding/foam_dart
	embed_chance = 85
	fall_chance = 2
	jostle_chance = 0
	ignore_throwspeed_threshold = TRUE
	pain_mult = 0
	jostle_pain_mult = 0
	rip_time = 0.5 SECONDS

/obj/projectile/bullet/foam_dart/Initialize(mapload)
	. = ..()
	RegisterSignals(src, list(COMSIG_PROJECTILE_ON_SPAWN_DROP, COMSIG_PROJECTILE_ON_SPAWN_EMBEDDED), PROC_REF(handle_drop))

/obj/projectile/bullet/foam_dart/proc/handle_drop(datum/source, obj/item/ammo_casing/foam_dart/newcasing)
	SIGNAL_HANDLER
	newcasing.modified = modified
	newcasing.update_appearance()
	var/obj/projectile/bullet/foam_dart/newdart = newcasing.loaded_projectile
	newdart.modified = modified
	newdart.damage_type = damage_type
	newdart.update_appearance()

/obj/projectile/bullet/foam_dart/riot
	name = "riot foam dart"
	icon_state = "foamdart_riot_proj"
	base_icon_state = "foamdart_riot"
	shrapnel_type = /obj/item/ammo_casing/foam_dart/riot
	stamina = 25

/datum/embedding/foam_dart/riot
	fall_chance = 1.5
	jostle_chance = 5
	pain_mult = 1
	jostle_pain_mult = 4 // These things are heavy and weigh you down a bit when stuck
	pain_stam_pct = 1
	rip_time = 1 SECONDS
