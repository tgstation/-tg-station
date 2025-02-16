/// Inert structures, such as girders, machine frames, and crates/lockers.
/obj/structure
	icon = 'icons/obj/structures.dmi'
	pressure_resistance = 8
	max_integrity = 300
	interaction_flags_atom = INTERACT_ATOM_ATTACK_HAND | INTERACT_ATOM_UI_INTERACT
	layer = BELOW_OBJ_LAYER
	flags_ricochet = RICOCHET_HARD
	receive_ricochet_chance_mod = 0.6
	pass_flags_self = PASSSTRUCTURE
	blocks_emissive = EMISSIVE_BLOCK_GENERIC
	armor_type = /datum/armor/obj_structure
	burning_particles = /particles/smoke/burning
	var/broken = FALSE

/datum/armor/obj_structure
	fire = 50
	acid = 50

/obj/structure/Initialize(mapload)
	. = ..()
	if(smoothing_flags & USES_SMOOTHING)
		QUEUE_SMOOTH(src)
		QUEUE_SMOOTH_NEIGHBORS(src)
		if(smoothing_flags & SMOOTH_CORNERS)
			icon_state = ""
	GLOB.cameranet.updateVisibility(src)

/obj/structure/Destroy(force)
	GLOB.cameranet.updateVisibility(src)
	if(smoothing_flags & USES_SMOOTHING)
		QUEUE_SMOOTH_NEIGHBORS(src)
	return ..()

/obj/structure/ui_act(action, list/params, datum/tgui/ui, datum/ui_state/state)
	add_fingerprint(usr)
	return ..()

/obj/structure/examine(mob/user)
	. = ..()
	if(!(resistance_flags & INDESTRUCTIBLE))
		if(resistance_flags & ON_FIRE)
			. += span_warning("It's on fire!")
		if(broken)
			. += span_notice("It appears to be broken.")
		var/examine_status = examine_status(user)
		if(examine_status)
			. += examine_status

/obj/structure/proc/examine_status(mob/user) //An overridable proc, mostly for falsewalls.
	var/healthpercent = (atom_integrity/max_integrity) * 100
	switch(healthpercent)
		if(50 to 99)
			return  "It looks slightly damaged."
		if(25 to 50)
			return  "It appears heavily damaged."
		if(0 to 25)
			if(!broken)
				return  span_warning("It's falling apart!")

/obj/structure/examine_descriptor(mob/user)
	return "structure"

/obj/structure/rust_heretic_act()
	take_damage(500, BRUTE, "melee", 1)

/obj/structure/zap_act(power, zap_flags)
	if(zap_flags & ZAP_OBJ_DAMAGE)
		take_damage(power * 2.5e-4, BURN, "energy")
	power -= power * 5e-4 //walls take a lot out of ya
	. = ..()

/obj/structure/animate_atom_living(mob/living/owner)
	new /mob/living/basic/mimic/copy(drop_location(), src, owner)

/// For when a mob comes flying through the window, smash it and damage the mob
/obj/structure/proc/smash_and_injure(mob/living/flying_mob, atom/oldloc, direction)
	flying_mob.balloon_alert_to_viewers("smashed through!")
	flying_mob.apply_damage(damage = rand(5, 15), damagetype = BRUTE, wound_bonus = 15, bare_wound_bonus = 25, sharpness = SHARP_EDGED, attack_direction = get_dir(src, oldloc))
	new /obj/effect/decal/cleanable/glass(get_step(flying_mob, flying_mob.dir))
	deconstruct(disassembled = FALSE)

/obj/structure/used_in_craft(atom/result, datum/crafting_recipe/current_recipe)
	. = ..()
	// If we consumed in crafting, we should dump contents out before qdeling them.
	if(!is_type_in_list(src, current_recipe.parts))
		dump_contents()
