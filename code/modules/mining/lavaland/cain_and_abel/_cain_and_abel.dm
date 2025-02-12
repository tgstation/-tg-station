#define THROW_MODE_CRYSTALS "throw_mode_crystals"
#define THROW_MODE_LAUNCH "throw_mode_launch"

/obj/item/cain_and_abel
	name = "Cain & Abel"
	desc = "I cry I pray mon Dieu."
	icon = 'icons/obj/mining_zones/artefacts.dmi'
	lefthand_file = 'icons/mob/inhands/equipment/kitchen_lefthand.dmi'
	righthand_file = 'icons/mob/inhands/equipment/kitchen_lefthand.dmi' //same sprite as lefthand
	icon_state = "cain_and_abel"
	inhand_icon_state = "cain_and_abel"
	attack_verb_continuous = list("attacks", "saws", "slices", "tears", "lacerates", "rips", "dices", "cuts")
	attack_verb_simple = list("attack", "saw", "slice", "tear", "lacerate", "rip", "dice", "cut")
	force = 15
	attack_speed = 6
	actions_types = list(/datum/action/cooldown/dagger_swing)
	hitsound = 'sound/items/weapons/bladeslice.ogg'
	w_class = WEIGHT_CLASS_SMALL
	sharpness = SHARP_EDGED
	light_range = 3
	light_power = 2
	light_color = "#3db9db"
	reach = 2
	attack_icon = 'icons/effects/effects.dmi'
	attack_icon_state = "cain_abel_attack"
	///our current combo count
	var/combo_count = 0
	///the maximum combo we can reach
	var/max_combo = 6
	///percentage boost we get on every combo
	var/damage_boost = 1.15
	///pixel offsets of our wisps
	var/static/list/wisp_offsets = list(
		list(9, 12),
		list(14, 0),
		list(9, -12),
		list(-9, 12),
		list(-14, 0),
		list(-9, -12),
	)
	///what throw mode we're using
	var/throw_mode = THROW_MODE_CRYSTALS
	///flames we have up!
	var/list/current_wisps = list()
	///cooldown till we can throw blades again
	COOLDOWN_DECLARE(throw_cooldown)

/obj/item/cain_and_abel/Initialize(mapload)
	. = ..()
	AddComponent(/datum/component/two_handed, require_twohands = TRUE, force_unwielded = force, force_wielded = force)


/obj/item/cain_and_abel/Moved(atom/old_loc, movement_dir, forced, list/old_locs, momentum_change)
	. = ..()
	if(!isliving(old_loc))
		return

	unset_user(old_loc)

/obj/item/cain_and_abel/proc/unset_user(mob/living/source)
	if(HAS_TRAIT(source, TRAIT_RELAYING_ATTACKER))
		source.RemoveElement(/datum/element/relay_attackers)

	set_combo(new_value = 0, user = source)
	UnregisterSignal(source, list(COMSIG_ATOM_WAS_ATTACKED))


/obj/item/cain_and_abel/equipped(mob/user, slot)
	. = ..()

	if(!(slot & ITEM_SLOT_HANDS))
		unset_user(user)
		return

	if(!HAS_TRAIT(user, TRAIT_RELAYING_ATTACKER))
		user.AddElement(/datum/element/relay_attackers)

	RegisterSignal(user, COMSIG_ATOM_WAS_ATTACKED, PROC_REF(on_attacked))

/obj/item/cain_and_abel/proc/on_attacked(datum/source, atom/attacker, attack_flags)
	SIGNAL_HANDLER
	set_combo(new_value = 0, user = source)

/obj/item/cain_and_abel/ranged_interact_with_atom_secondary(atom/interacting_with, mob/living/user, list/modifiers)
	if(get_dist(interacting_with, user) > 9 || interacting_with.z != user.z)
		return ITEM_INTERACT_BLOCKING

	if(!length(current_wisps))
		user.balloon_alert(user, "no wisps!")
		return

	for(var/index in 0 to (length(current_wisps) - 1))
		addtimer(CALLBACK(src, PROC_REF(fire_wisp), user, interacting_with), index * 0.15 SECONDS)

	set_combo(new_value = 0, user = user)

/obj/item/cain_and_abel/attack(mob/living/target, mob/living/carbon/human/user)
	if(!istype(target) || target.mob_size < MOB_SIZE_LARGE || target.stat == DEAD)
		return ..()

	var/old_force = force
	var/bonus_value = combo_count || 1
	force = CEILING((bonus_value * damage_boost) * force, 1)
	. = ..()
	force = old_force
	set_combo(new_value = combo_count + 1, user = user)

/obj/item/cain_and_abel/attack_self(mob/user)
	. = ..()
	if(.)
		return TRUE
	throw_mode = (throw_mode == THROW_MODE_CRYSTALS) ? THROW_MODE_LAUNCH : THROW_MODE_CRYSTALS
	user.balloon_alert(user, "crystals [throw_mode == THROW_MODE_CRYSTALS ? "activated" : "deactivated"]")
	return TRUE

/obj/item/cain_and_abel/proc/set_combo(new_value, mob/living/user)
	combo_count = (new_value <= max_combo) ? new_value : 0
	handle_wisps(user)

/obj/item/cain_and_abel/proc/handle_wisps(mob/living/user)
	var/should_remove = length(current_wisps) > combo_count
	var/wisps_to_alter = abs(combo_count - length(current_wisps))

	for(var/i = 1, i <= wisps_to_alter, i++)
		if(!should_remove)
			add_wisp(user)
			continue
		var/obj/my_wisp = current_wisps[i]
		remove_wisp(my_wisp)

/obj/item/cain_and_abel/proc/add_wisp(mob/living/user)
	var/obj/effect/overlay/blood_wisp/new_wisp = new(src)
	current_wisps += new_wisp
	var/list/position = wisp_offsets[length(current_wisps)]
	user.vis_contents += new_wisp
	new_wisp.pixel_x = position[1]
	new_wisp.pixel_y = position[2]
	RegisterSignal(new_wisp, COMSIG_QDELETING, PROC_REF(on_wisp_delete))

/obj/item/cain_and_abel/proc/on_wisp_delete(datum/source)
	SIGNAL_HANDLER
	current_wisps -= source
	UnregisterSignal(source, COMSIG_QDELETING)

/obj/item/cain_and_abel/proc/fire_wisp(atom/user, atom/target)
	user.fire_projectile(/obj/projectile/dagger_wisp, target)

/obj/item/cain_and_abel/proc/remove_wisp(obj/wisp_to_remove)
	animate(wisp_to_remove, alpha = 0, time = 0.2 SECONDS)
	QDEL_IN(wisp_to_remove, 0.2 SECONDS)
