
#define DUALWIELD_PENALTY_EXTRA_MULTIPLIER 1.4
#define FIRING_PIN_REMOVAL_DELAY 50

/obj/item/gun
	name = "gun"
	desc = "It's a gun. It's pretty terrible, though."
	icon = 'icons/obj/weapons/guns/ballistic.dmi'
	icon_state = "revolver"
	inhand_icon_state = "gun"
	worn_icon_state = "gun"
	obj_flags = CONDUCTS_ELECTRICITY
	appearance_flags = TILE_BOUND|PIXEL_SCALE|LONG_GLIDE|KEEP_TOGETHER
	slot_flags = ITEM_SLOT_BELT
	custom_materials = list(/datum/material/iron=SHEET_MATERIAL_AMOUNT)
	w_class = WEIGHT_CLASS_NORMAL
	throwforce = 5
	throw_speed = 3
	throw_range = 5
	force = 5
	item_flags = NEEDS_PERMIT
	attack_verb_continuous = list("strikes", "hits", "bashes")
	attack_verb_simple = list("strike", "hit", "bash")

	var/gun_flags = NONE
	var/fire_sound = 'sound/items/weapons/gun/pistol/shot.ogg'
	var/vary_fire_sound = TRUE
	var/fire_sound_volume = 50
	var/dry_fire_sound = 'sound/items/weapons/gun/general/dry_fire.ogg'
	var/dry_fire_sound_volume = 30
	var/suppressed = null //whether or not a message is displayed when fired
	var/can_suppress = FALSE
	var/suppressed_sound = 'sound/items/weapons/gun/general/heavy_shot_suppressed.ogg'
	var/suppressed_volume = 60
	var/can_unsuppress = TRUE /// whether a gun can be unsuppressed. for ballistics, also determines if it generates a suppressor overlay
	var/recoil = 0 //boom boom shake the room
	var/clumsy_check = TRUE
	var/obj/item/ammo_casing/chambered = null
	trigger_guard = TRIGGER_GUARD_NORMAL //trigger guard on the weapon, hulks can't fire them with their big meaty fingers
	var/sawn_desc = null //description change if weapon is sawn-off
	var/sawn_off = FALSE
	var/burst_size = 1 //how large a burst is
	var/fire_delay = 0 //rate of fire for burst firing and semi auto
	var/firing_burst = 0 //Prevent the weapon from firing again while already firing
	var/semicd = 0 //cooldown handler
	var/weapon_weight = WEAPON_LIGHT
	var/dual_wield_spread = 24 //additional spread when dual wielding
	///Can we hold up our target with this? Default to yes
	var/can_hold_up = TRUE

	/// Just 'slightly' snowflakey way to modify projectile damage for projectiles fired from this gun.
	var/projectile_damage_multiplier = 1

	/// Even snowflakier way to modify projectile wounding bonus/potential for projectiles fired from this gun.
	var/projectile_wound_bonus = 0

	/// The most reasonable way to modify projectile speed values for projectile fired from this gun. Honest.
	/// Lower values are better, higher values are worse.
	var/projectile_speed_multiplier = 1

	var/spread = 0 //Spread induced by the gun itself.
	var/randomspread = 1 //Set to 0 for shotguns. This is used for weapons that don't fire all their bullets at once.

	lefthand_file = 'icons/mob/inhands/weapons/guns_lefthand.dmi'
	righthand_file = 'icons/mob/inhands/weapons/guns_righthand.dmi'

	var/obj/item/firing_pin/pin = /obj/item/firing_pin //standard firing pin for most guns
	/// True if a gun dosen't need a pin, mostly used for abstract guns like tentacles and meathooks
	var/pinless = FALSE

	var/ammo_x_offset = 0 //used for positioning ammo count overlay on sprite
	var/ammo_y_offset = 0

	var/pb_knockback = 0

	/// Cooldown for the visible message sent from gun flipping.
	COOLDOWN_DECLARE(flip_cooldown)

/obj/item/gun/Initialize(mapload)
	. = ..()
	if(ispath(pin))
		pin = new pin
		pin.gun_insert(new_gun = src)

	add_seclight_point()
	add_bayonet_point()

/obj/item/gun/Destroy()
	if(isobj(pin)) //Can still be the initial path, then we skip
		QDEL_NULL(pin)
	if(chambered) //Not all guns are chambered (EMP'ed energy guns etc)
		QDEL_NULL(chambered)
	if(isatom(suppressed)) //SUPPRESSED IS USED AS BOTH A TRUE/FALSE AND AS A REF, WHAT THE FUCKKKKKKKKKKKKKKKKK
		QDEL_NULL(suppressed)
	return ..()

/obj/item/gun/apply_fantasy_bonuses(bonus)
	. = ..()
	fire_delay = modify_fantasy_variable("fire_delay", fire_delay, -bonus, 0)
	projectile_damage_multiplier = modify_fantasy_variable("projectile_damage_multiplier", projectile_damage_multiplier, bonus/10, 0.1)

/obj/item/gun/remove_fantasy_bonuses(bonus)
	fire_delay = reset_fantasy_variable("fire_delay", fire_delay)
	projectile_damage_multiplier = reset_fantasy_variable("projectile_damage_multiplier", projectile_damage_multiplier)
	return ..()

/// Handles adding [the seclite mount component][/datum/component/seclite_attachable] to the gun.
/// If the gun shouldn't have a seclight mount, override this with a return.
/// Or, if a child of a gun with a seclite mount has slightly different behavior or icons, extend this.
/obj/item/gun/proc/add_seclight_point()
	return

/// Similarly to add_seclight_point(), handles [the bayonet attachment component][/datum/component/bayonet_attachable]
/obj/item/gun/proc/add_bayonet_point()
	return

/obj/item/gun/Exited(atom/movable/gone, direction)
	. = ..()
	if(gone == pin)
		pin = null
	if(gone == chambered)
		chambered = null
		update_appearance()
	if(gone == suppressed)
		clear_suppressor()

///Clears var and updates icon. In the case of ballistic weapons, also updates the gun's weight.
/obj/item/gun/proc/clear_suppressor()
	if(!can_unsuppress)
		return
	suppressed = null
	update_appearance()

/obj/item/gun/throw_impact(atom/hit_atom, datum/thrownthing/throwingdatum)
	. = ..()
	if(isliving(hit_atom))
		var/mob/living/thrower = throwingdatum?.get_thrower()
		toss_gun_hard(thrower, hit_atom)

/obj/item/gun/proc/toss_gun_hard(mob/living/thrower, mob/living/target) //throw a gun at them. They don't expect it.
	if(isnull(thrower))
		return FALSE
	if(!HAS_TRAIT(thrower, TRAIT_TOSS_GUN_HARD))
		return FALSE
	target.Knockdown(0.5 SECONDS)
	target.apply_damage(damage = max(w_class * 5 - throwforce, 10), damagetype = BRUTE, def_zone = thrower.zone_selected, wound_bonus = CANT_WOUND, attacking_item = src)
	return TRUE

/obj/item/gun/examine(mob/user)
	. = ..()
	if(!pinless)
		if(pin)
			. += "It has \a [pin] installed."
			if(pin.pin_removable)
				. += span_info("[pin] looks like [pin.p_they()] could be removed with some <b>tools</b>.")
			else
				. += span_info("[pin] looks like [pin.p_theyre()] firmly locked in, [pin.p_they()] looks impossible to remove.")
		else
			. += "It doesn't have a <b>firing pin</b> installed, and won't fire."

	var/healthpercent = (atom_integrity/max_integrity) * 100
	switch(healthpercent)
		if(60 to 95)
			. += span_info("It looks slightly damaged.")
		if(25 to 60)
			. += span_warning("It appears heavily damaged.")
		if(0 to 25)
			. += span_boldwarning("It's falling apart!")

//called after the gun has successfully fired its chambered ammo.
/obj/item/gun/proc/process_chamber(empty_chamber = TRUE, from_firing = TRUE, chamber_next_round = TRUE)
	handle_chamber(empty_chamber, from_firing, chamber_next_round)
	SEND_SIGNAL(src, COMSIG_GUN_CHAMBER_PROCESSED)

/obj/item/gun/proc/handle_chamber(empty_chamber = TRUE, from_firing = TRUE, chamber_next_round = TRUE)
	return

//check if there's enough ammo/energy/whatever to shoot one time
//i.e if clicking would make it shoot
/obj/item/gun/proc/can_shoot()
	return TRUE

/obj/item/gun/proc/tk_firing(mob/living/user)
	return !user.contains(src)

/obj/item/gun/proc/shoot_with_empty_chamber(mob/living/user as mob|obj)
	balloon_alert_to_viewers("*click*")
	playsound(src, dry_fire_sound, dry_fire_sound_volume, TRUE)

/obj/item/gun/proc/fire_sounds()
	if(suppressed)
		playsound(src, suppressed_sound, suppressed_volume, vary_fire_sound, ignore_walls = FALSE, extrarange = SILENCED_SOUND_EXTRARANGE, falloff_distance = 0)
	else
		playsound(src, fire_sound, fire_sound_volume, vary_fire_sound)

/obj/item/gun/proc/shoot_live_shot(mob/living/user, pointblank = FALSE, atom/pbtarget = null, message = TRUE)
	if(recoil && !tk_firing(user))
		shake_camera(user, recoil + 1, recoil)
	fire_sounds()
	if(suppressed || !message)
		return FALSE
	if(tk_firing(user))
		visible_message(
				span_danger("[src] fires itself[pointblank ? " point blank at [pbtarget]!" : "!"]"),
				blind_message = span_hear("You hear a gunshot!"),
				vision_distance = COMBAT_MESSAGE_RANGE
		)
	else if(pointblank)
		user.visible_message(
				span_danger("[user] fires [src] point blank at [pbtarget]!"),
				span_danger("You fire [src] point blank at [pbtarget]!"),
				span_hear("You hear a gunshot!"), COMBAT_MESSAGE_RANGE, pbtarget
		)
		to_chat(pbtarget, span_userdanger("[user] fires [src] point blank at you!"))
		if(pb_knockback > 0 && ismob(pbtarget))
			var/mob/PBT = pbtarget
			var/atom/throw_target = get_edge_target_turf(PBT, user.dir)
			PBT.throw_at(throw_target, pb_knockback, 2)
	else if(!tk_firing(user))
		user.visible_message(
				span_danger("[user] fires [src]!"),
				blind_message = span_hear("You hear a gunshot!"),
				vision_distance = COMBAT_MESSAGE_RANGE,
				ignored_mobs = user
		)

	if(chambered?.integrity_damage)
		take_damage(chambered.integrity_damage, sound_effect = FALSE)
	return TRUE

/obj/item/gun/atom_destruction(damage_flag)
	if(!isliving(loc))
		return ..()
	var/mob/living/holder = loc
	if(holder.is_holding(src) && holder.stat < UNCONSCIOUS)
		to_chat(holder, span_boldwarning("[src] breaks down!"))
		holder.playsound_local(get_turf(src), 'sound/items/weapons/smash.ogg', 50, TRUE)
	return ..()

/obj/item/gun/emp_act(severity)
	. = ..()
	if(!(. & EMP_PROTECT_CONTENTS))
		for(var/obj/inside in contents)
			inside.emp_act(severity)

/obj/item/gun/attack_self_secondary(mob/user, modifiers)
	. = ..()
	if(.)
		return

	if(pinless)
		return

	if(!HAS_TRAIT(user, TRAIT_GUNFLIP))
		return

	SpinAnimation(4, 2) // The spin happens regardless of the cooldown

	if(!COOLDOWN_FINISHED(src, flip_cooldown))
		return SECONDARY_ATTACK_CANCEL_ATTACK_CHAIN

	COOLDOWN_START(src, flip_cooldown, 3 SECONDS)
	if(HAS_TRAIT(user, TRAIT_CLUMSY) && prob(40))
		// yes this will sound silly for bows and wands, but that's a "gun" moment for you
		user.visible_message(
			span_danger("While trying to flip [src] [user] pulls the trigger accidentally!"),
			span_userdanger("While trying to flip [src] you pull the trigger accidentally!"),
		)
		process_fire(user, user, FALSE, user.get_random_valid_zone(even_weights = TRUE))
		user.dropItemToGround(src, TRUE)
	else
		user.visible_message(
			span_notice("[user] spins [src] around [user.p_their()] finger by the trigger. That's pretty badass."),
			span_notice("You spin [src] around your finger by the trigger. That's pretty badass."),
		)
		playsound(src, 'sound/items/handling/ammobox_pickup.ogg', 20, FALSE)

	return SECONDARY_ATTACK_CANCEL_ATTACK_CHAIN

/obj/item/gun/interact_with_atom(atom/interacting_with, mob/living/user, list/modifiers)
	if(user.combat_mode && isliving(interacting_with))
		return ITEM_INTERACT_SKIP_TO_ATTACK // Gun bash / bayonet attack
	if(try_fire_gun(interacting_with, user, list2params(modifiers)))
		return ITEM_INTERACT_SUCCESS
	return NONE

/obj/item/gun/interact_with_atom_secondary(atom/interacting_with, mob/living/user, list/modifiers)
	if(!can_hold_up || !isliving(interacting_with))
		return interact_with_atom(interacting_with, user, modifiers)

	var/datum/component/gunpoint/gunpoint_component = user.GetComponent(/datum/component/gunpoint)
	if (gunpoint_component)
		balloon_alert(user, "already holding [gunpoint_component.target == interacting_with ? "them" : "someone"] up!")
		return ITEM_INTERACT_BLOCKING
	if (user == interacting_with)
		balloon_alert(user, "can't hold yourself up!")
		return ITEM_INTERACT_BLOCKING

	if(do_after(user, 0.5 SECONDS, interacting_with))
		user.AddComponent(/datum/component/gunpoint, interacting_with, src)
	return ITEM_INTERACT_SUCCESS

/obj/item/gun/ranged_interact_with_atom(atom/interacting_with, mob/living/user, list/modifiers)
	if(try_fire_gun(interacting_with, user, list2params(modifiers)))
		return ITEM_INTERACT_SUCCESS
	return ITEM_INTERACT_BLOCKING

/obj/item/gun/ranged_interact_with_atom_secondary(atom/interacting_with, mob/living/user, list/modifiers)
	if(IN_GIVEN_RANGE(user, interacting_with, GUNPOINT_SHOOTER_STRAY_RANGE))
		return interact_with_atom_secondary(interacting_with, user, modifiers)
	return ..()

/obj/item/gun/proc/try_fire_gun(atom/target, mob/living/user, params)
	return fire_gun(target, user, user.Adjacent(target), params)

/obj/item/gun/proc/fire_gun(atom/target, mob/living/user, flag, params)
	if(QDELETED(target))
		return
	if(firing_burst)
		return

	if(SEND_SIGNAL(user, COMSIG_MOB_TRYING_TO_FIRE_GUN, src, target, flag, params) & COMPONENT_CANCEL_GUN_FIRE)
		return

	if(SEND_SIGNAL(src, COMSIG_GUN_TRY_FIRE, user, target, flag, params) & COMPONENT_CANCEL_GUN_FIRE)
		return
	if(flag) //It's adjacent, is the user, or is on the user's person
		if(target in user.contents) //can't shoot stuff inside us.
			return
		if(!ismob(target) || user.combat_mode) //melee attack
			return
		if(target == user && user.zone_selected != BODY_ZONE_PRECISE_MOUTH) //so we can't shoot ourselves (unless mouth selected)
			return
		if(iscarbon(target))
			var/mob/living/carbon/C = target
			for(var/i in C.all_wounds)
				var/datum/wound/W = i
				if(W.try_treating(src, user))
					return // another coward cured!

	if(istype(user))//Check if the user can use the gun, if the user isn't alive(turrets) assume it can.
		var/mob/living/L = user
		if(!can_trigger_gun(L))
			return

	if(flag)
		if(user.zone_selected == BODY_ZONE_PRECISE_MOUTH)
			handle_suicide(user, target, params)
			return

	if(!can_shoot()) //Just because you can pull the trigger doesn't mean it can shoot.
		shoot_with_empty_chamber(user)
		return

	if(check_botched(user, target))
		return

	var/obj/item/bodypart/other_hand = user.has_hand_for_held_index(user.get_inactive_hand_index()) //returns non-disabled inactive hands
	if(weapon_weight == WEAPON_HEAVY && (user.get_inactive_held_item() || !other_hand))
		balloon_alert(user, "use both hands!")
		return
	//DUAL (or more!) WIELDING
	var/bonus_spread = 0
	var/loop_counter = 0
	if(user.combat_mode && !HAS_TRAIT(user, TRAIT_NO_GUN_AKIMBO))
		for(var/obj/item/gun/gun in user.held_items)
			if(gun == src || gun.weapon_weight >= WEAPON_MEDIUM)
				continue
			else if(gun.can_trigger_gun(user, akimbo_usage = TRUE))
				bonus_spread += dual_wield_spread
				loop_counter++
				addtimer(CALLBACK(gun, TYPE_PROC_REF(/obj/item/gun, process_fire), target, user, TRUE, params, null, bonus_spread), loop_counter)

	return process_fire(target, user, TRUE, params, null, bonus_spread)

/obj/item/gun/proc/check_botched(mob/living/user, atom/target)
	if(clumsy_check)
		if(istype(user))
			if(HAS_TRAIT(user, TRAIT_CLUMSY) && prob(40))
				var/target_zone = user.get_random_valid_zone(blacklisted_parts = list(BODY_ZONE_CHEST, BODY_ZONE_HEAD, BODY_ZONE_L_ARM, BODY_ZONE_R_ARM), even_weights = TRUE, bypass_warning = TRUE)
				if(!target_zone)
					return
				to_chat(user, span_userdanger("You shoot yourself in the foot with [src]!"))
				process_fire(user, user, FALSE, null, target_zone)
				SEND_SIGNAL(user, COMSIG_MOB_CLUMSY_SHOOT_FOOT)
				if(!tk_firing(user) && !HAS_TRAIT(src, TRAIT_NODROP))
					user.dropItemToGround(src, TRUE)
				return TRUE

/obj/item/gun/can_trigger_gun(mob/living/user, akimbo_usage)
	. = ..()
	if(!handle_pins(user))
		return FALSE

/obj/item/gun/proc/handle_pins(mob/living/user)
	if(pinless)
		return TRUE
	if(pin)
		if(pin.pin_auth(user) || (pin.obj_flags & EMAGGED))
			return TRUE
		else
			pin.auth_fail(user)
			return FALSE
	else
		to_chat(user, span_warning("[src]'s trigger is locked. This weapon doesn't have a firing pin installed!"))
		balloon_alert(user, "trigger locked, firing pin needed!")
	return FALSE

/obj/item/gun/proc/recharge_newshot()
	return

/obj/item/gun/proc/process_burst(mob/living/user, atom/target, message = TRUE, params=null, zone_override = "", random_spread = 0, burst_spread_mult = 0, iteration = 0)
	if(!user || !firing_burst)
		firing_burst = FALSE
		return FALSE
	if(!issilicon(user))
		if(iteration > 1 && !(user.is_holding(src))) //for burst firing
			firing_burst = FALSE
			return FALSE
	if(chambered?.loaded_projectile)
		if(HAS_TRAIT(user, TRAIT_PACIFISM)) // If the user has the pacifist trait, then they won't be able to fire [src] if the round chambered inside of [src] is lethal.
			if(chambered.harmful) // Is the bullet chambered harmful?
				to_chat(user, span_warning("[src] is lethally chambered! You don't want to risk harming anyone..."))
				firing_burst = FALSE
				return FALSE
		var/sprd
		if(randomspread)
			sprd = round((rand(0, 1) - 0.5) * DUALWIELD_PENALTY_EXTRA_MULTIPLIER * (random_spread))
		else //Smart spread
			sprd = round((((burst_spread_mult/burst_size) * iteration) - (0.5 + (burst_spread_mult * 0.25))) * (random_spread))
		before_firing(target,user)
		if(!chambered.fire_casing(target, user, params, ,suppressed, zone_override, sprd, src))
			shoot_with_empty_chamber(user)
			firing_burst = FALSE
			return FALSE
		else
			if(get_dist(user, target) <= 1) //Making sure whether the target is in vicinity for the pointblank shot
				shoot_live_shot(user, TRUE, target, message)
			else
				shoot_live_shot(user, FALSE, target, message)
			if (iteration >= burst_size)
				firing_burst = FALSE
	else
		shoot_with_empty_chamber(user)
		firing_burst = FALSE
		return FALSE
	process_chamber()
	update_appearance()
	return TRUE

///returns true if the gun successfully fires
/obj/item/gun/proc/process_fire(atom/target, mob/living/user, message = TRUE, params = null, zone_override = "", bonus_spread = 0)
	var/base_bonus_spread = 0
	if(user)
		var/list/bonus_spread_values = list(base_bonus_spread, bonus_spread)
		SEND_SIGNAL(user, COMSIG_MOB_FIRED_GUN, src, target, params, zone_override, bonus_spread_values)
		base_bonus_spread = bonus_spread_values[MIN_BONUS_SPREAD_INDEX]
		bonus_spread = bonus_spread_values[MAX_BONUS_SPREAD_INDEX]

	SEND_SIGNAL(src, COMSIG_GUN_FIRED, user, target, params, zone_override)

	add_fingerprint(user)

	if(semicd)
		return

	//Vary by at least this much
	var/randomized_bonus_spread = rand(base_bonus_spread, bonus_spread)
	var/randomized_gun_spread = spread ? rand(0, spread) : 0
	var/total_random_spread = max(0, randomized_bonus_spread + randomized_gun_spread)
	var/burst_spread_mult = rand()

	var/modified_delay = fire_delay
	if(user && HAS_TRAIT(user, TRAIT_DOUBLE_TAP))
		modified_delay = ROUND_UP(fire_delay * 0.5)

	if(burst_size > 1)
		firing_burst = TRUE
		for(var/i = 1 to burst_size)
			addtimer(CALLBACK(src, PROC_REF(process_burst), user, target, message, params, zone_override, total_random_spread, burst_spread_mult, i), modified_delay * (i - 1))
	else
		if(chambered)
			if(HAS_TRAIT(user, TRAIT_PACIFISM)) // If the user has the pacifist trait, then they won't be able to fire [src] if the round chambered inside of [src] is lethal.
				if(chambered.harmful) // Is the bullet chambered harmful?
					to_chat(user, span_warning("[src] is lethally chambered! You don't want to risk harming anyone..."))
					return
			var/sprd = round((rand(0, 1) - 0.5) * DUALWIELD_PENALTY_EXTRA_MULTIPLIER * total_random_spread)
			before_firing(target,user)
			if(!chambered.fire_casing(target, user, params, , suppressed, zone_override, sprd, src))
				shoot_with_empty_chamber(user)
				return
			else
				if(get_dist(user, target) <= 1) //Making sure whether the target is in vicinity for the pointblank shot
					shoot_live_shot(user, TRUE, target, message)
				else
					shoot_live_shot(user, FALSE, target, message)
		else
			shoot_with_empty_chamber(user)
			return
		// If gun gets destroyed as a result of firing
		if (!QDELETED(src))
			process_chamber()
			update_appearance()
			semicd = TRUE
			addtimer(CALLBACK(src, PROC_REF(reset_semicd)), modified_delay)

	if(user)
		user.update_held_items()
	SSblackbox.record_feedback("tally", "gun_fired", 1, type)

	return TRUE

/obj/item/gun/proc/reset_semicd()
	semicd = FALSE

/obj/item/gun/screwdriver_act(mob/living/user, obj/item/I)
	. = ..()
	if(.)
		return
	if(!user.can_perform_action(src, FORBID_TELEKINESIS_REACH))
		return
	if(pin?.pin_removable && user.is_holding(src))
		user.visible_message(span_warning("[user] attempts to remove [pin] from [src] with [I]."),
		span_notice("You attempt to remove [pin] from [src]. (It will take [DisplayTimeText(FIRING_PIN_REMOVAL_DELAY)].)"), null, 3)
		if(I.use_tool(src, user, FIRING_PIN_REMOVAL_DELAY, volume = 50))
			if(!pin) //check to see if the pin is still there, or we can spam messages by clicking multiple times during the tool delay
				return
			user.visible_message(span_notice("[pin] is pried out of [src] by [user], destroying the pin in the process."),
								span_warning("You pry [pin] out with [I], destroying the pin in the process."), null, 3)
			QDEL_NULL(pin)
			return ITEM_INTERACT_SUCCESS

/obj/item/gun/welder_act(mob/living/user, obj/item/I)
	. = ..()
	if(.)
		return
	if(!user.can_perform_action(src, FORBID_TELEKINESIS_REACH))
		return
	if(pin?.pin_removable && user.is_holding(src))
		user.visible_message(span_warning("[user] attempts to remove [pin] from [src] with [I]."),
		span_notice("You attempt to remove [pin] from [src]. (It will take [DisplayTimeText(FIRING_PIN_REMOVAL_DELAY)].)"), null, 3)
		if(I.use_tool(src, user, FIRING_PIN_REMOVAL_DELAY, 5, volume = 50))
			if(!pin) //check to see if the pin is still there, or we can spam messages by clicking multiple times during the tool delay
				return
			user.visible_message(span_notice("[pin] is spliced out of [src] by [user], melting part of the pin in the process."),
								span_warning("You splice [pin] out of [src] with [I], melting part of the pin in the process."), null, 3)
			QDEL_NULL(pin)
			return TRUE

/obj/item/gun/wirecutter_act(mob/living/user, obj/item/I)
	. = ..()
	if(.)
		return
	if(!user.can_perform_action(src, FORBID_TELEKINESIS_REACH))
		return
	if(pin?.pin_removable && user.is_holding(src))
		user.visible_message(span_warning("[user] attempts to remove [pin] from [src] with [I]."),
		span_notice("You attempt to remove [pin] from [src]. (It will take [DisplayTimeText(FIRING_PIN_REMOVAL_DELAY)].)"), null, 3)
		if(I.use_tool(src, user, FIRING_PIN_REMOVAL_DELAY, volume = 50))
			if(!pin) //check to see if the pin is still there, or we can spam messages by clicking multiple times during the tool delay
				return
			user.visible_message(span_notice("[pin] is ripped out of [src] by [user], mangling the pin in the process."),
								span_warning("You rip [pin] out of [src] with [I], mangling the pin in the process."), null, 3)
			QDEL_NULL(pin)
			return TRUE

/obj/item/gun/animate_atom_living(mob/living/owner)
	new /mob/living/basic/mimic/copy/ranged(drop_location(), src, owner)

/obj/item/gun/proc/handle_suicide(mob/living/carbon/human/user, mob/living/carbon/human/target, params, bypass_timer)
	if(!ishuman(user) || !ishuman(target))
		return

	if(semicd)
		return

	if(user == target)
		target.visible_message(span_warning("[user] sticks [src] in [user.p_their()] mouth, ready to pull the trigger..."), \
			span_userdanger("You stick [src] in your mouth, ready to pull the trigger..."))
	else
		target.visible_message(span_warning("[user] points [src] at [target]'s head, ready to pull the trigger..."), \
			span_userdanger("[user] points [src] at your head, ready to pull the trigger..."))

	semicd = TRUE

	if(!bypass_timer && (!do_after(user, 12 SECONDS, target) || user.zone_selected != BODY_ZONE_PRECISE_MOUTH))
		if(user)
			if(user == target)
				user.visible_message(span_notice("[user] decided not to shoot."))
			else if(target?.Adjacent(user))
				target.visible_message(span_notice("[user] has decided to spare [target]"), span_notice("[user] has decided to spare your life!"))
		semicd = FALSE
		return

	semicd = FALSE

	target.visible_message(span_warning("[user] pulls the trigger!"), span_userdanger("[(user == target) ? "You pull" : "[user] pulls"] the trigger!"))

	if(chambered?.loaded_projectile)
		chambered.loaded_projectile.damage *= 5
		if(chambered.loaded_projectile.wound_bonus != CANT_WOUND)
			chambered.loaded_projectile.wound_bonus += 5 // much more dramatic on multiple pellet'd projectiles really

	var/fired = process_fire(target, user, TRUE, params, BODY_ZONE_HEAD)
	if(!fired && chambered?.loaded_projectile)
		chambered.loaded_projectile.damage /= 5
		if(chambered.loaded_projectile.wound_bonus != CANT_WOUND)
			chambered.loaded_projectile.wound_bonus -= 5

/obj/item/gun/proc/unlock() //used in summon guns and as a convience for admins
	if(pin)
		qdel(pin)
	var/obj/item/firing_pin/new_pin = new
	new_pin.gun_insert(new_gun = src)

//Happens before the actual projectile creation
/obj/item/gun/proc/before_firing(atom/target,mob/user)
	return

#undef FIRING_PIN_REMOVAL_DELAY
#undef DUALWIELD_PENALTY_EXTRA_MULTIPLIER
