/**
 * Kinetic Crusher
 *
 * Lavaland's "Hard Mode" option for players, requiring melee attacks (backstabs even better),
 * but allowing you to upgrade it with trophies gained from fighting lavaland monsters, making it
 * a good tradeoff and a decent playstyle.
 */
/obj/item/kinetic_crusher
	name = "proto-kinetic crusher"
	desc = "An early design of the proto-kinetic accelerator, it is little more than a combination of various mining tools cobbled together, \
		forming a high-tech club. While it is an effective mining tool, it did little to aid any but the most skilled and/or \
		suicidal miners against local fauna."
	icon = 'icons/obj/mining.dmi'
	icon_state = "crusher"
	inhand_icon_state = "crusher0"
	icon_angle = -45
	lefthand_file = 'icons/mob/inhands/weapons/hammers_lefthand.dmi'
	righthand_file = 'icons/mob/inhands/weapons/hammers_righthand.dmi'
	resistance_flags = FIRE_PROOF
	force = 0 //You can't hit stuff unless wielded
	w_class = WEIGHT_CLASS_BULKY
	slot_flags = ITEM_SLOT_BACK
	throwforce = 5
	throw_speed = 4
	armour_penetration = 10
	custom_materials = list(/datum/material/iron=HALF_SHEET_MATERIAL_AMOUNT*1.15, /datum/material/glass=HALF_SHEET_MATERIAL_AMOUNT*2.075)
	hitsound = 'sound/items/weapons/bladeslice.ogg'
	attack_verb_continuous = list("smashes", "crushes", "cleaves", "chops", "pulps")
	attack_verb_simple = list("smash", "crush", "cleave", "chop", "pulp")
	sharpness = SHARP_EDGED
	actions_types = list(/datum/action/item_action/toggle_light)
	obj_flags = UNIQUE_RENAME
	light_system = OVERLAY_LIGHT
	light_range = 5
	light_power = 1.2
	light_color = "#ffff66"
	light_on = FALSE
	/// List of all crusher trophies attached to this.
	var/list/obj/item/crusher_trophy/trophies = list()
	/// If our crusher is ready to fire a projectile (FALSE means it's on cooldown)
	var/charged = TRUE
	/// How long before our crusher will recharge by default
	var/charge_time = 1.5 SECONDS
	/// Timer before our crusher recharges
	var/charge_timer
	/// Damage that the mark does when hit by the crusher
	var/detonation_damage = 50
	/// Damage that the mark additionally does when hit by the crusher via backstab
	var/backstab_bonus = 30
	/// Used by retool kits when changing the crusher's appearance
	var/current_inhand_icon_state = "crusher"
	/// Used by retool kits when changing the crusher's projectile sprite
	var/projectile_icon = "pulse1"

/obj/item/kinetic_crusher/Initialize(mapload)
	. = ..()
	AddComponent(/datum/component/butchering, \
		speed = 6 SECONDS, \
		effectiveness = 110, \
	)
	//technically it's huge and bulky, but this provides an incentive to use it
	AddComponent(/datum/component/two_handed, force_unwielded=0, force_wielded=20)
	register_context()

/obj/item/kinetic_crusher/add_context(atom/source, list/context, obj/item/held_item, mob/user)
	. = ..()
	if(!held_item)
		context[SCREENTIP_CONTEXT_RMB] = "Detach trophy"
		return CONTEXTUAL_SCREENTIP_SET

	if(istype(held_item) && held_item.tool_behaviour == TOOL_CROWBAR)
		context[SCREENTIP_CONTEXT_LMB] = "Detach all trophies"
		return CONTEXTUAL_SCREENTIP_SET

/obj/item/kinetic_crusher/Destroy()
	QDEL_LIST(trophies)
	return ..()

/obj/item/kinetic_crusher/Exited(atom/movable/gone, direction)
	. = ..()
	trophies -= gone

/obj/item/kinetic_crusher/examine(mob/living/user)
	. = ..()
	. += span_notice("Mark a large creature with a destabilizing force with right-click, then hit them in melee to do <b>[force + detonation_damage]</b> damage.")
	. += span_notice("Does <b>[force + detonation_damage + backstab_bonus]</b> damage if the target is backstabbed, instead of <b>[force + detonation_damage]</b>.")
	for(var/obj/item/crusher_trophy/crusher_trophy as anything in trophies)
		. += span_notice("It has \a [crusher_trophy] attached, which causes [crusher_trophy.effect_desc()].")

/obj/item/kinetic_crusher/attackby(obj/item/attacking_item, mob/user, params)
	if(istype(attacking_item, /obj/item/crusher_trophy))
		var/obj/item/crusher_trophy/crusher_trophy = attacking_item
		crusher_trophy.add_to(src, user)
		return
	return ..()

/obj/item/kinetic_crusher/crowbar_act(mob/living/user, obj/item/tool)
	. = ..()
	if(!LAZYLEN(trophies))
		user.balloon_alert(user, "no trophies!")
		return ITEM_INTERACT_BLOCKING
	user.balloon_alert(user, "trophies removed")
	tool.play_tool_sound(src)
	for(var/obj/item/crusher_trophy/crusher_trophy as anything in trophies)
		crusher_trophy.remove_from(src, user)
	return ITEM_INTERACT_SUCCESS

// adapted from kinetic accelerator attack_hand_secodary
/obj/item/kinetic_crusher/attack_hand_secondary(mob/user, list/modifiers)
	. = ..()
	if(. == SECONDARY_ATTACK_CANCEL_ATTACK_CHAIN)
		return SECONDARY_ATTACK_CANCEL_ATTACK_CHAIN

	if(!LAZYLEN(trophies))
		return SECONDARY_ATTACK_CONTINUE_CHAIN

	var/list/display_names = list()
	var/list/items = list()
	for(var/trophies_length in 1 to length(trophies))
		var/obj/item/crusher_trophy/trophy = trophies[trophies_length]
		display_names[trophy.name] = REF(trophy)
		var/image/item_image = image(icon = trophy.icon, icon_state = trophy.icon_state)
		if(length(trophy.overlays))
			item_image.copy_overlays(trophy)
		items["[trophy.name]"] = item_image

	var/pick = show_radial_menu(user, src, items, custom_check = CALLBACK(src, PROC_REF(check_menu), user), radius = 36, require_near = TRUE, tooltips = TRUE)
	if(!pick)
		return SECONDARY_ATTACK_CANCEL_ATTACK_CHAIN

	var/trophy_reference = display_names[pick]
	var/obj/item/crusher_trophy/trophy_to_remove = locate(trophy_reference) in trophies
	if(!istype(trophy_to_remove))
		return SECONDARY_ATTACK_CANCEL_ATTACK_CHAIN
	trophy_to_remove.remove_from(src, user)
	if(!user.put_in_hands(trophy_to_remove))
		trophy_to_remove.forceMove(drop_location())

	return SECONDARY_ATTACK_CANCEL_ATTACK_CHAIN

/obj/item/kinetic_crusher/proc/check_menu(mob/living/carbon/human/user)
	if(!istype(user))
		return FALSE
	if(user.incapacitated)
		return FALSE
	return TRUE

/obj/item/kinetic_crusher/pre_attack(atom/A, mob/living/user, params)
	. = ..()
	if(.)
		return TRUE
	if(!HAS_TRAIT(src, TRAIT_WIELDED))
		user.balloon_alert(user, "must be wielded!")
		return TRUE
	return .

/obj/item/kinetic_crusher/attack(mob/living/target, mob/living/carbon/user)
	target.apply_status_effect(/datum/status_effect/crusher_damage)
	return ..()

/obj/item/kinetic_crusher/afterattack(mob/living/target, mob/living/user, clickparams)
	if(!isliving(target))
		return
	// Melee effect
	for(var/obj/item/crusher_trophy/crusher_trophy as anything in trophies)
		crusher_trophy.on_melee_hit(target, user)
	if(QDELETED(target))
		return
	var/datum/status_effect/crusher_mark/mark = target.has_status_effect(/datum/status_effect/crusher_mark)
	if(!mark)
		return
	var/boosted_mark = mark.boosted
	if(!target.remove_status_effect(mark))
		return
	// Detonation effect
	var/datum/status_effect/crusher_damage/crusher_damage_effect = target.has_status_effect(/datum/status_effect/crusher_damage) || target.apply_status_effect(/datum/status_effect/crusher_damage)
	var/target_health = target.health
	for(var/obj/item/crusher_trophy/crusher_trophy as anything in trophies)
		crusher_trophy.on_mark_detonation(target, user)
	if(QDELETED(target))
		return
	if(!QDELETED(crusher_damage_effect))
		crusher_damage_effect.total_damage += target_health - target.health //we did some damage, but let's not assume how much we did
	new /obj/effect/temp_visual/kinetic_blast(get_turf(target))
	var/backstabbed = FALSE
	var/combined_damage = detonation_damage
	var/def_check = target.getarmor(type = BOMB)
	// Backstab bonus
	if(check_behind(user, target) || boosted_mark)
		backstabbed = TRUE
		combined_damage += backstab_bonus
		playsound(user, 'sound/items/weapons/kinetic_accel.ogg', 100, TRUE) //Seriously who spelled it wrong
	if(!QDELETED(crusher_damage_effect))
		crusher_damage_effect.total_damage += combined_damage
	SEND_SIGNAL(user, COMSIG_LIVING_CRUSHER_DETONATE, target, src, backstabbed)
	target.apply_damage(combined_damage, BRUTE, blocked = def_check)

/obj/item/kinetic_crusher/interact_with_atom_secondary(atom/interacting_with, mob/living/user, list/modifiers)
	if(!HAS_TRAIT(src, TRAIT_WIELDED))
		balloon_alert(user, "wield it first!")
		return ITEM_INTERACT_BLOCKING
	if(interacting_with == user)
		balloon_alert(user, "can't aim at yourself!")
		return ITEM_INTERACT_BLOCKING
	fire_kinetic_blast(interacting_with, user, modifiers)
	user.changeNext_move(CLICK_CD_MELEE)
	return ITEM_INTERACT_SUCCESS

/obj/item/kinetic_crusher/ranged_interact_with_atom_secondary(atom/interacting_with, mob/living/user, list/modifiers)
	return interact_with_atom_secondary(interacting_with, user, modifiers)

/obj/item/kinetic_crusher/proc/fire_kinetic_blast(atom/target, mob/living/user, list/modifiers)
	if(!charged)
		return
	var/turf/proj_turf = user.loc
	if(!isturf(proj_turf))
		return
	var/obj/projectile/destabilizer/destabilizer = new(proj_turf)
	destabilizer.icon_state = "[projectile_icon]"
	for(var/obj/item/crusher_trophy/attached_trophy as anything in trophies)
		attached_trophy.on_projectile_fire(destabilizer, user)
	destabilizer.aim_projectile(target, user, modifiers)
	destabilizer.firer = user
	destabilizer.fired_from = src
	playsound(user, 'sound/items/weapons/plasma_cutter.ogg', 100, TRUE)
	destabilizer.fire()
	charged = FALSE
	update_appearance()
	attempt_recharge_projectile()

/// Handles the timer for reloading the projectile
/obj/item/kinetic_crusher/proc/attempt_recharge_projectile(set_recharge_time)
	if(!set_recharge_time)
		set_recharge_time = charge_time
	deltimer(charge_timer)
	charge_timer = addtimer(CALLBACK(src, PROC_REF(recharge_projectile)), set_recharge_time, TIMER_STOPPABLE)

/// Recharges the projectile
/obj/item/kinetic_crusher/proc/recharge_projectile()
	if(!charged)
		charged = TRUE
		update_appearance()
		playsound(src.loc, 'sound/items/weapons/kinetic_reload.ogg', 60, TRUE)

/obj/item/kinetic_crusher/ui_action_click(mob/user, actiontype)
	set_light_on(!light_on)
	playsound(user, 'sound/items/weapons/empty.ogg', 100, TRUE)
	update_appearance()

/obj/item/kinetic_crusher/on_saboteur(datum/source, disrupt_duration)
	. = ..()
	set_light_on(FALSE)
	playsound(src, 'sound/items/weapons/empty.ogg', 100, TRUE)
	return TRUE

/obj/item/kinetic_crusher/update_icon_state()
	inhand_icon_state = "[current_inhand_icon_state][HAS_TRAIT(src, TRAIT_WIELDED)]" // this is not icon_state and not supported by 2hcomponent
	return ..()

/obj/item/kinetic_crusher/update_overlays()
	. = ..()
	if(!charged)
		. += "[icon_state]_uncharged"
	if(light_on)
		. += "[icon_state]_lit"

/obj/item/kinetic_crusher/compact //for admins
	name = "compact kinetic crusher"
	w_class = WEIGHT_CLASS_NORMAL

//destablizing force
/obj/projectile/destabilizer
	name = "destabilizing force"
	damage = 0 //We're just here to mark people. This is still a melee weapon.
	damage_type = BRUTE
	armor_flag = BOMB
	range = 6
	log_override = TRUE
	/// Has this projectile been boosted
	var/boosted = FALSE

/obj/projectile/destabilizer/Initialize(mapload)
	. = ..()
	AddComponent(/datum/component/parriable_projectile, parry_callback = CALLBACK(src, PROC_REF(on_parry)))

/obj/projectile/destabilizer/Destroy()
	fired_from = null
	return ..()

/obj/projectile/destabilizer/proc/on_parry(mob/user)
	SIGNAL_HANDLER
	boosted = TRUE
	// Get a bit of a damage/range boost after being parried
	damage = 10
	range = 9

/obj/projectile/destabilizer/on_hit(atom/target, blocked = 0, pierce_hit)
	var/obj/item/kinetic_crusher/used_crusher
	if(istype(fired_from, /obj/item/kinetic_crusher))
		used_crusher = fired_from

	if(isliving(target))
		for(var/obj/item/crusher_trophy/crusher_trophy as anything in used_crusher?.trophies)
			crusher_trophy.on_projectile_hit_mob(target, firer)
		if(QDELETED(target))
			return ..()
		var/mob/living/living_target = target
		living_target.apply_status_effect(/datum/status_effect/crusher_mark, boosted)
		return ..()

	var/target_turf = get_turf(target)
	if(ismineralturf(target_turf))
		var/turf/closed/mineral/hit_mineral = target_turf
		for(var/obj/item/crusher_trophy/crusher_trophy as anything in used_crusher?.trophies)
			crusher_trophy.on_projectile_hit_mineral(hit_mineral, firer)
		if(QDELETED(hit_mineral))
			return ..()
		new /obj/effect/temp_visual/kinetic_blast(hit_mineral)
		hit_mineral.gets_drilled(firer, TRUE)
		if(!iscarbon(firer))
			return ..()
		var/mob/living/carbon/carbon_firer = firer
		var/skill_modifier = 1
		// If there is a mind, check for skill modifier to allow them to reload faster.
		if(carbon_firer.mind && used_crusher)
			skill_modifier = carbon_firer.mind.get_skill_modifier(/datum/skill/mining, SKILL_SPEED_MODIFIER)
			used_crusher.attempt_recharge_projectile(used_crusher.charge_time * skill_modifier) //If you hit a mineral, you might get a quicker reload. epic gamer style.

	return ..()

