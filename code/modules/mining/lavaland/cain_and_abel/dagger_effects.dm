//effect when we're swinging wildly around
/obj/effect/temp_visual/dagger_slash
	mouse_opacity = MOUSE_OPACITY_TRANSPARENT
	anchored = TRUE
	vis_flags = VIS_INHERIT_DIR | VIS_INHERIT_PLANE
	layer = ABOVE_HUD_PLANE
	icon = 'icons/effects/160x160.dmi'
	icon_state = "dagger_slash"
	pixel_y = -64
	base_pixel_y = -64
	pixel_x = -64
	base_pixel_x = -64
	duration = 1.75 SECONDS

/obj/effect/temp_visual/dagger_slash/Initialize()
	. = ..()
	animate(src, alpha = 0, time = 1.75 SECONDS)

//flames we collect around our body
/obj/effect/overlay/blood_wisp
	mouse_opacity = MOUSE_OPACITY_TRANSPARENT
	anchored = TRUE
	vis_flags = VIS_INHERIT_DIR | VIS_INHERIT_PLANE
	layer = ABOVE_HUD_PLANE
	icon = 'icons/effects/effects.dmi'
	icon_state = "blood_wisp"
	light_power = 2
	light_range = 2
	light_color = "#d74e63"

//blade we hurl
/obj/projectile/dagger
	name = "Cain"
	icon = 'icons/effects/effects.dmi'
	icon_state = "cain_abel_attack"
	damage = 10
	range = 9
	light_power = 2
	light_range = 2
	light_color = "#589ac9"
	speed = 3
	can_hit_turfs = TRUE
	hitsound = 'sound/items/weapons/zipline_hit.ogg'
	///effect we leave by after hit
	var/effect_left = /obj/effect/temp_visual/dagger_engraved

/obj/projectile/dagger/proc/dagger_effects(atom/target)
	if(QDELETED(target))
		return null
	var/turf/target_turf = get_turf(target)
	if(isgroundlessturf(target_turf))
		return null
	var/obj/effect/temp_visual/dagger_engraved/engraved = new effect_left(target_turf)
	firer.Beam(engraved, icon_state = "chain", icon = 'icons/obj/mining_zones/artefacts.dmi', maxdistance = 9, layer = BELOW_MOB_LAYER)
	return engraved

/obj/projectile/dagger/crystal
	effect_left = /obj/effect/temp_visual/dagger_engraved/crystals

/obj/projectile/dagger/launch
	effect_left = /obj/effect/temp_visual/dagger_engraved/launch

/obj/projectile/dagger/launch/dagger_effects(atom/target)
	. = ..()
	if(isnull(.))
		return
	var/obj/effect/temp_visual/dagger_engraved/launch/launching_dagger = .
	launching_dagger.launch(firer)

//effect when monsters step on our crystals
/obj/effect/temp_visual/dagger_lightning
	icon = 'icons/effects/effects.dmi'
	icon_state = "lightning"
	light_color = "#3d50db"
	duration = 1.25 SECONDS

//dagger engraved to the floor
/obj/effect/temp_visual/dagger_engraved
	icon = 'icons/effects/effects.dmi'
	icon_state = "cain_abel_engraved"
	light_color = "#5767e1"
	light_power = 2
	light_range = 2
	duration = 3 SECONDS

//the dagger thatll launch us toward it
/obj/effect/temp_visual/dagger_engraved/launch

/obj/effect/temp_visual/dagger_engraved/launch/proc/launch(mob/living/firer)
	firer.throw_at(target = src, range = 9, speed = 1, spin = FALSE, gentle = TRUE, throw_type_path = /datum/thrownthing/dagger_launch)

//throw datum the cain and abel applies
/datum/thrownthing/dagger_launch
	///traits we apply to the user when being launched
	var/static/list/traits_on_launch = list(
		TRAIT_IMMOBILIZED,
		TRAIT_MOVE_FLOATING,
	)

/datum/thrownthing/dagger_launch/New(thrownthing, target, init_dir, maxrange, speed, thrower, diagonals_first, force, gentle, callback, target_zone)
	. = ..()
	if(isnull(thrownthing))
		return
	var/atom/thrown_atom = thrownthing
	thrown_atom.add_traits(traits_on_launch, REF(src))
	new /obj/effect/temp_visual/mook_dust(get_turf(thrownthing))

/datum/thrownthing/dagger_launch/finalize(hit, target)
	if(thrownthing)
		new /obj/effect/temp_visual/mook_dust(get_turf(thrownthing))
	return ..()

/datum/thrownthing/dagger_launch/Destroy()
	if(thrownthing)
		thrownthing.remove_traits(traits_on_launch, REF(src))
	var/obj/effect/temp_visual/dagger_engraved/launch/target_dagger = initial_target?.resolve()
	if(istype(target_dagger))
		qdel(target_dagger)
	return ..()

//dagger thatll spring up crystals
/obj/effect/temp_visual/dagger_engraved/crystals
	light_power = 1
	light_range = 1

/obj/effect/temp_visual/dagger_engraved/crystals/Initialize(mapload)
	. = ..()
	for(var/index in 0 to 2)
		addtimer(CALLBACK(src, PROC_REF(generate_crystals), index), index * 0.5 SECONDS)

/obj/effect/temp_visual/dagger_engraved/crystals/proc/generate_crystals(range)
	if(range == 0)
		new /obj/effect/temp_visual/dagger_crystal(get_turf(src))
		return

	playsound(src, 'sound/items/weapons/crystal_dagger_sound.ogg', 60, vary = TRUE, pressure_affected = FALSE)
	var/list/turfs_to_crystalize = border_diamond_range_turfs(src, range)
	for(var/turf/turf_to_crystalize as anything in turfs_to_crystalize)
		new /obj/effect/temp_visual/dagger_crystal(turf_to_crystalize)

//effect when our whisps hit something
/obj/effect/temp_visual/wisp_explosion
	icon = 'icons/effects/effects.dmi'
	icon_state = "wisp_hit"
	layer = ABOVE_ALL_MOB_LAYER
	light_power = 2
	light_range = 2
	light_color = "#d74e63"
	duration = 0.5 SECONDS

/obj/effect/temp_visual/wisp_explosion/Initialize(mapload)
	. = ..()
	playsound(get_turf(src), 'sound/items/weapons/effects/blood_wisp_explode.ogg', 60, vary = TRUE, pressure_affected = FALSE)

//painful crystals to step on
/obj/effect/temp_visual/dagger_crystal
	icon = 'icons/effects/effects.dmi'
	icon_state = "cain_abel_crystal"
	duration = 3 SECONDS
	light_range = 3
	light_power = 2
	light_color = "#3db9db"
	///damage we apply to mobs who step on us
	var/applied_damage = 50

/obj/effect/temp_visual/dagger_crystal/Initialize(mapload)
	. = ..()
	var/static/list/loc_connections = list(
		COMSIG_ATOM_ENTERED = PROC_REF(on_entered),
	)
	AddElement(/datum/element/connect_loc, loc_connections)

	for(var/mob/living/victim in get_turf(src))
		if(victim.mob_size < MOB_SIZE_LARGE)
			continue
		apply_crystal_effects(victim)
	addtimer(CALLBACK(src, PROC_REF(dissappear_gracefully)), duration - 1 SECONDS)

/obj/effect/temp_visual/dagger_crystal/proc/on_entered(datum/source, mob/living/entered_living)
	SIGNAL_HANDLER
	if(!istype(entered_living) || entered_living.mob_size < MOB_SIZE_LARGE)
		return
	apply_crystal_effects(entered_living)

/obj/effect/temp_visual/dagger_crystal/proc/apply_crystal_effects(mob/living/victim)
	victim.apply_status_effect(/datum/status_effect/dagger_stun)
	victim.apply_damage(applied_damage, BRUTE)

/obj/effect/temp_visual/dagger_crystal/proc/dissappear_gracefully()
	animate(src, alpha = 0, time = 0.9 SECONDS)

//wisp we hurl at monsters
/obj/projectile/dagger_wisp
	name = "dagger wisp"
	damage = 25
	armor_flag = BOMB
	light_power = 2
	light_range = 2
	light_color = "#d74e63"
	icon = 'icons/effects/effects.dmi'
	icon_state = "blood_wisp"

/obj/projectile/dagger_wisp/Initialize(mapload)
	. = ..()
	transform = transform.Scale(1, -1)

/obj/projectile/dagger_wisp/on_hit(atom/target, blocked, pierce_hit)
	. = ..()
	new /obj/effect/temp_visual/wisp_explosion(get_turf(target))
