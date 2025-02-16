/obj/item/gun/ballistic/automatic
	w_class = WEIGHT_CLASS_NORMAL
	can_suppress = TRUE
	burst_size = 3
	fire_delay = 2
	actions_types = list(/datum/action/item_action/toggle_firemode)
	semi_auto = TRUE
	fire_sound = 'sound/items/weapons/gun/smg/shot.ogg'
	fire_sound_volume = 90
	rack_sound = 'sound/items/weapons/gun/smg/smgrack.ogg'
	suppressed_sound = 'sound/items/weapons/gun/smg/shot_suppressed.ogg'
	burst_fire_selection = TRUE
	drop_sound = 'sound/items/handling/gun/ballistics/smg/smg_drop1.ogg'
	pickup_sound = 'sound/items/handling/gun/ballistics/smg/smg_pickup1.ogg'

/obj/item/gun/ballistic/automatic/proto
	name = "\improper Nanotrasen Saber SMG"
	desc = "A prototype full-auto 9mm submachine gun, designated 'SABR'. Has a threaded barrel for suppressors."
	icon_state = "saber"
	burst_size = 1
	actions_types = list()
	mag_display = TRUE
	empty_indicator = TRUE
	accepted_magazine_type = /obj/item/ammo_box/magazine/smgm9mm
	pin = null
	bolt_type = BOLT_TYPE_LOCKING
	show_bolt_icon = FALSE

/obj/item/gun/ballistic/automatic/proto/Initialize(mapload)
	. = ..()
	AddComponent(/datum/component/automatic_fire, 0.2 SECONDS)

/obj/item/gun/ballistic/automatic/proto/unrestricted
	pin = /obj/item/firing_pin

/obj/item/gun/ballistic/automatic/c20r
	name = "\improper C-20r SMG"
	desc = "A bullpup three-round burst .45 SMG, designated 'C-20r'. Has a 'Scarborough Arms - Per falcis, per pravitas' buttstamp."
	icon_state = "c20r"
	inhand_icon_state = "c20r"
	selector_switch_icon = TRUE
	accepted_magazine_type = /obj/item/ammo_box/magazine/smgm45
	fire_delay = 2
	burst_size = 3
	pin = /obj/item/firing_pin/implant/pindicate
	mag_display = TRUE
	mag_display_ammo = TRUE
	empty_indicator = TRUE

/obj/item/gun/ballistic/automatic/c20r/add_bayonet_point()
	AddComponent(/datum/component/bayonet_attachable, offset_x = 26, offset_y = 12)

/obj/item/gun/ballistic/automatic/c20r/update_overlays()
	. = ..()
	if(!chambered && empty_indicator) //this is duplicated due to a layering issue with the select fire icon.
		. += "[icon_state]_empty"

/obj/item/gun/ballistic/automatic/c20r/unrestricted
	pin = /obj/item/firing_pin

/obj/item/gun/ballistic/automatic/c20r/Initialize(mapload)
	. = ..()
	update_appearance()

/obj/item/gun/ballistic/automatic/wt550
	name = "\improper WT-550 Autorifle"
	desc = "Recalled by Nanotrasen due to public backlash around heat distribution resulting in unintended discombobulation. \
		This outcry was fabricated through various Syndicate-backed misinformation operations to force Nanotrasen to abandon \
		its ballistics weapon program, cornering them into the energy weapons market. Most often found today in the hands of pirates, \
		underfunded security personnel, cargo technicians, theoretical physicists, and gang bangers out on the rim. \
		Light-weight and fully automatic. Uses 4.6x30mm rounds."
	icon_state = "wt550"
	w_class = WEIGHT_CLASS_BULKY
	inhand_icon_state = "arg"
	accepted_magazine_type = /obj/item/ammo_box/magazine/wt550m9
	fire_delay = 2
	can_suppress = FALSE
	burst_size = 1
	actions_types = list()
	mag_display = TRUE
	mag_display_ammo = TRUE
	empty_indicator = TRUE

/obj/item/gun/ballistic/automatic/wt550/Initialize(mapload)
	. = ..()
	AddComponent(/datum/component/automatic_fire, 0.3 SECONDS)

/obj/item/gun/ballistic/automatic/wt550/add_bayonet_point()
	AddComponent(/datum/component/bayonet_attachable, offset_x = 25, offset_y = 12)

/obj/item/gun/ballistic/automatic/smartgun
	name = "\improper Abielle Smart-SMG"
	desc = "An old experiment in smart-weapon technology that guides bullets towards the target the gun was aimed at when fired. \
		While the tracking functions worked fine, the gun is prone to insanely wide spread thanks to it's practically non-existant barrel."
	icon_state = "smartgun"
	inhand_icon_state = "smartgun"
	accepted_magazine_type = /obj/item/ammo_box/magazine/smartgun
	burst_size = 4
	fire_delay = 1
	spread = 40
	dual_wield_spread = 20
	actions_types = list()
	bolt_type = BOLT_TYPE_LOCKING
	can_suppress = FALSE
	mag_display = TRUE
	empty_indicator = TRUE
	click_on_low_ammo = FALSE
	/// List of the possible firing sounds
	var/list/firing_sound_list = list(
		'sound/items/weapons/gun/smartgun/smartgun_shoot_1.ogg',
		'sound/items/weapons/gun/smartgun/smartgun_shoot_2.ogg',
		'sound/items/weapons/gun/smartgun/smartgun_shoot_3.ogg',
	)

/obj/item/gun/ballistic/automatic/smartgun/fire_sounds()
	var/picked_fire_sound = pick(firing_sound_list)
	playsound(src, picked_fire_sound, fire_sound_volume, vary_fire_sound)

/obj/item/gun/ballistic/automatic/mini_uzi
	name = "\improper Type U3 Uzi"
	desc = "A lightweight, burst-fire submachine gun, for when you really want someone dead. Uses 9mm rounds."
	icon_state = "miniuzi"
	accepted_magazine_type = /obj/item/ammo_box/magazine/uzim9mm
	burst_size = 2
	bolt_type = BOLT_TYPE_OPEN
	show_bolt_icon = FALSE
	mag_display = TRUE
	rack_sound = 'sound/items/weapons/gun/pistol/slide_lock.ogg'

/**
 * Weak uzi for syndicate chimps. It comes in a 4 TC kit.
 * Roughly 9 damage per bullet every 0.2 seconds, equaling out to downing an opponent in a bit over a second, if they have no armor.
 */
/obj/item/gun/ballistic/automatic/mini_uzi/chimpgun
	name = "\improper MONK-10"
	desc = "Developed by Syndicate monkeys, for syndicate Monkeys. Despite the name, this weapon resembles an Uzi significantly more than a MAC-10. Uses 9mm rounds. There's a label on the other side of the gun that says \"Do what comes natural.\""
	projectile_damage_multiplier = 0.4
	projectile_wound_bonus = -25
	pin = /obj/item/firing_pin/monkey

/obj/item/gun/ballistic/automatic/m90
	name = "\improper M-90gl Carbine"
	desc = "A three-round burst .223 toploading carbine, designated 'M-90gl'. Has an attached underbarrel grenade launcher."
	desc_controls = "Right-click to use grenade launcher."
	icon_state = "m90"
	w_class = WEIGHT_CLASS_BULKY
	inhand_icon_state = "m90"
	selector_switch_icon = TRUE
	accepted_magazine_type = /obj/item/ammo_box/magazine/m223
	can_suppress = FALSE
	var/obj/item/gun/ballistic/revolver/grenadelauncher/underbarrel
	burst_size = 3
	fire_delay = 2
	spread = 5
	pin = /obj/item/firing_pin/implant/pindicate
	mag_display = TRUE
	empty_indicator = TRUE
	fire_sound = 'sound/items/weapons/gun/smg/shot_alt.ogg'

/obj/item/gun/ballistic/automatic/m90/Initialize(mapload)
	. = ..()
	underbarrel = new /obj/item/gun/ballistic/revolver/grenadelauncher(src)
	update_appearance()

/obj/item/gun/ballistic/automatic/m90/Destroy()
	QDEL_NULL(underbarrel)
	return ..()

/obj/item/gun/ballistic/automatic/m90/unrestricted
	pin = /obj/item/firing_pin

/obj/item/gun/ballistic/automatic/m90/unrestricted/Initialize(mapload)
	. = ..()
	underbarrel = new /obj/item/gun/ballistic/revolver/grenadelauncher/unrestricted(src)
	update_appearance()

/obj/item/gun/ballistic/automatic/m90/try_fire_gun(atom/target, mob/living/user, params)
	if(LAZYACCESS(params2list(params), RIGHT_CLICK))
		return underbarrel.try_fire_gun(target, user, params)
	return ..()

/obj/item/gun/ballistic/automatic/m90/item_interaction(mob/living/user, obj/item/tool, list/modifiers)
	if(isammocasing(tool))
		if(istype(tool, underbarrel.magazine.ammo_type))
			underbarrel.attack_self(user)
			underbarrel.attackby(tool, user, list2params(modifiers))
		return ITEM_INTERACT_BLOCKING
	return ..()

/obj/item/gun/ballistic/automatic/tommygun
	name = "\improper Thompson SMG"
	desc = "Based on the classic 'Chicago Typewriter'."
	icon_state = "tommygun"
	inhand_icon_state = "shotgun"
	selector_switch_icon = TRUE
	w_class = WEIGHT_CLASS_BULKY
	slot_flags = 0
	accepted_magazine_type = /obj/item/ammo_box/magazine/tommygunm45
	can_suppress = FALSE
	burst_size = 1
	actions_types = list()
	fire_delay = 1
	bolt_type = BOLT_TYPE_OPEN
	empty_indicator = TRUE
	show_bolt_icon = FALSE
	/// Rate of fire, set on initialize only
	var/rof = 0.1 SECONDS

/obj/item/gun/ballistic/automatic/tommygun/Initialize(mapload)
	. = ..()
	AddComponent(/datum/component/automatic_fire, rof)

/**
 * Weak tommygun for syndicate chimps. It comes in a 4 TC kit.
 * Roughly 9 damage per bullet every 0.2 seconds, equaling out to downing an opponent in a bit over a second, if they have no armor.
 */
/obj/item/gun/ballistic/automatic/tommygun/chimpgun
	name = "\improper Typewriter"
	desc = "It was the best of times, it was the BLURST of times!? You stupid monkeys!"
	fire_delay = 2
	rof = 0.2 SECONDS
	projectile_damage_multiplier = 0.4
	projectile_wound_bonus = -25
	pin = /obj/item/firing_pin/monkey

/obj/item/gun/ballistic/automatic/ar
	name = "\improper NT-ARG 'Boarder'"
	desc = "A robust assault rifle used by Nanotrasen fighting forces."
	icon_state = "arg"
	inhand_icon_state = "arg"
	slot_flags = 0
	accepted_magazine_type = /obj/item/ammo_box/magazine/m223
	can_suppress = FALSE
	burst_size = 3
	fire_delay = 1

// L6 SAW //

/obj/item/gun/ballistic/automatic/l6_saw
	name = "\improper L6 SAW"
	desc = "A heavily modified 7mm light machine gun, designated 'L6 SAW'. Has 'Aussec Armoury - 2531' engraved on the receiver below the designation."
	icon_state = "l6"
	inhand_icon_state = "l6closedmag"
	base_icon_state = "l6"
	w_class = WEIGHT_CLASS_HUGE
	slot_flags = 0
	accepted_magazine_type = /obj/item/ammo_box/magazine/m7mm
	weapon_weight = WEAPON_HEAVY
	burst_size = 1
	actions_types = list()
	can_suppress = FALSE
	spread = 7
	pin = /obj/item/firing_pin/implant/pindicate
	bolt_type = BOLT_TYPE_OPEN
	show_bolt_icon = FALSE
	mag_display = TRUE
	mag_display_ammo = TRUE
	tac_reloads = FALSE
	fire_sound = 'sound/items/weapons/gun/l6/shot.ogg'
	rack_sound = 'sound/items/weapons/gun/l6/l6_rack.ogg'
	suppressed_sound = 'sound/items/weapons/gun/general/heavy_shot_suppressed.ogg'
	var/cover_open = FALSE

/obj/item/gun/ballistic/automatic/l6_saw/unrestricted
	pin = /obj/item/firing_pin

/obj/item/gun/ballistic/automatic/l6_saw/Initialize(mapload)
	. = ..()
	AddElement(/datum/element/update_icon_updates_onmob)
	AddComponent(/datum/component/automatic_fire, 0.2 SECONDS)

/obj/item/gun/ballistic/automatic/l6_saw/examine(mob/user)
	. = ..()
	. += "<b>alt + click</b> to [cover_open ? "close" : "open"] the dust cover."
	if(cover_open && magazine)
		. += span_notice("It seems like you could use an <b>empty hand</b> to remove the magazine.")


/obj/item/gun/ballistic/automatic/l6_saw/click_alt(mob/user)
	cover_open = !cover_open
	balloon_alert(user, "cover [cover_open ? "opened" : "closed"]")
	playsound(src, 'sound/items/weapons/gun/l6/l6_door.ogg', 60, TRUE)
	update_appearance()
	return CLICK_ACTION_SUCCESS

/obj/item/gun/ballistic/automatic/l6_saw/update_icon_state()
	. = ..()
	inhand_icon_state = "[base_icon_state][cover_open ? "open" : "closed"][magazine ? "mag":"nomag"]"

/obj/item/gun/ballistic/automatic/l6_saw/update_overlays()
	. = ..()
	. += "l6_door_[cover_open ? "open" : "closed"]"


/obj/item/gun/ballistic/automatic/l6_saw/try_fire_gun(atom/target, mob/living/user, params)
	if(cover_open)
		balloon_alert(user, "close the cover!")
		return FALSE

	. = ..()
	if(.)
		update_appearance()
	return .

//ATTACK HAND IGNORING PARENT RETURN VALUE
/obj/item/gun/ballistic/automatic/l6_saw/attack_hand(mob/user, list/modifiers)
	if (loc != user)
		..()
		return
	if (!cover_open)
		balloon_alert(user, "open the cover!")
		return
	..()

/obj/item/gun/ballistic/automatic/l6_saw/attackby(obj/item/A, mob/user, params)
	if(!cover_open && istype(A, accepted_magazine_type))
		balloon_alert(user, "open the cover!")
		return
	..()

// SKS semi-automatic rifle //

/obj/item/gun/ballistic/automatic/sks
	name = "\improper Sakhno SKS semi-automatic rifle"
	desc = "A revival of the ancient SKS semi-automatic rifle, redesigned to utilize .310 Strilka rounds. Produced to celebrate the \
		establishment of the Third Soviet Union in the Spinward Sector. In the wake of the union's collapse, these weapons now hold a \
		unique place in history amongst the populace of the sector. However, they are strangely rarer than the Sakhno M2442 Army. \
		Frontier settlers are known for owning one of these for hunting purposes. Or fighting off annoying tax collectors."
	icon = 'icons/obj/weapons/guns/wide_guns.dmi'
	icon_state = "sks"
	worn_icon_state = "sks"
	inhand_icon_state = "sks"
	burst_size = 1
	fire_delay = 0
	accepted_magazine_type = /obj/item/ammo_box/magazine/internal/sks
	internal_magazine = TRUE
	bolt_type = BOLT_TYPE_NO_BOLT
	can_suppress = FALSE
	tac_reloads = FALSE
	w_class = WEIGHT_CLASS_BULKY
	slot_flags = ITEM_SLOT_BACK
	weapon_weight = WEAPON_HEAVY
	projectile_damage_multiplier = 0.5
	fire_sound = 'sound/items/weapons/gun/rifle/shot_heavy.ogg'
	fire_sound_volume = 90
	drop_sound = 'sound/items/handling/gun/ballistics/rifle/rifle_drop1.ogg'
	pickup_sound = 'sound/items/handling/gun/ballistics/rifle/rifle_pickup1.ogg'
	actions_types = list()

	SET_BASE_PIXEL(-8, 0)

/obj/item/gun/ballistic/automatic/sks/add_bayonet_point()
	AddComponent(/datum/component/bayonet_attachable, offset_x = 38, offset_y = 12)

/obj/item/gun/ballistic/automatic/sks/chekhov
	name = "\improper Chekhov's SKS semi-automatic rifle"
	desc = "A revival of the ancient SKS semi-automatic rifle, redesigned to utilize .310 Strilka rounds. The name \
		'Chekhov' is engraved in the side of the stock. You feel like this had some kind of significance at one point, \
		but you cannot be sure as to what that might have been. Or whether that true meaning has yet to reveal itself."

/obj/item/gun/ballistic/automatic/sks/empty
	spawn_magazine_type = /obj/item/ammo_box/magazine/internal/sks/empty

// Laser rifle (rechargeable magazine) //

/obj/item/gun/ballistic/automatic/laser
	name = "laser rifle"
	desc = "Though sometimes mocked for the relatively weak firepower of their energy weapons, the logistic miracle of rechargeable ammunition has given Nanotrasen a decisive edge over many a foe."
	icon_state = "oldrifle"
	w_class = WEIGHT_CLASS_BULKY
	inhand_icon_state = "arg"
	accepted_magazine_type = /obj/item/ammo_box/magazine/recharge
	empty_indicator = TRUE
	fire_delay = 2
	can_suppress = FALSE
	burst_size = 0
	actions_types = list()
	fire_sound = 'sound/items/weapons/laser.ogg'
	casing_ejector = FALSE

// NT Battle Rifle //

/obj/item/gun/ballistic/automatic/battle_rifle
	name = "\improper NT BR-38 battle rifle"
	desc = "Nanotrasen's prototype security weapon, found exclusively in the hands of their private security teams. Chambered in .38 pistol rounds. \
		Ignore that this makes it technically a carbine. And that it functions as a designated marksman rifle. Marketing weren't being very co-operative \
		when it came time to name the gun. That, and the endless arguments in board rooms about exactly what designation the gun is meant to be."
	icon = 'icons/obj/weapons/guns/wide_guns.dmi'
	icon_state = "battle_rifle"
	inhand_icon_state = "battle_rifle"
	base_icon_state = "battle_rifle"
	worn_icon = 'icons/mob/clothing/back.dmi'
	worn_icon_state = "battle_rifle"
	slot_flags = ITEM_SLOT_BACK

	weapon_weight = WEAPON_HEAVY
	accepted_magazine_type = /obj/item/ammo_box/magazine/m38
	w_class = WEIGHT_CLASS_BULKY
	force = 15 //this thing is kind of oversized, okay?
	mag_display = TRUE
	projectile_damage_multiplier = 1.2
	projectile_speed_multiplier = 1.2
	fire_delay = 2
	burst_size = 1
	actions_types = list()
	spread = 10 //slightly inaccurate in burst fire mode, mostly important for long range shooting
	fire_sound = 'sound/items/weapons/thermalpistol.ogg'
	suppressor_x_offset = 8

	/// Determines how many shots we can make before the weapon needs to be maintained.
	var/shots_before_degradation = 10
	/// The max number of allowed shots this gun can have before degradation.
	var/max_shots_before_degradation = 10
	/// Determines the degradation stage. The higher the value, the more poorly the weapon performs.
	var/degradation_stage = 0
	/// Maximum degradation stage.
	var/degradation_stage_max = 5
	/// The probability of degradation increasing per shot.
	var/degradation_probability = 10
	/// The maximum speed malus for projectile flight speed. Projectiles probably shouldn't move too slowly or else they will start to cause problems.
	var/maximum_speed_malus = 0.7
	/// What is our damage multiplier if the gun is emagged?
	var/emagged_projectile_damage_multiplier = 1.6

	/// Whether or not our gun is suffering an EMP related malfunction.
	var/emp_malfunction = FALSE

	/// Our timer for when our gun is suffering an extreme malfunction. AKA it is going to explode
	var/explosion_timer

	SET_BASE_PIXEL(-8, 0)

/obj/item/gun/ballistic/automatic/battle_rifle/Initialize(mapload)
	. = ..()
	AddComponent(/datum/component/scope, range_modifier = 2)
	register_context()

/obj/item/gun/ballistic/automatic/battle_rifle/add_context(atom/source, list/context, obj/item/held_item, mob/user)
	. = ..()

	if(held_item?.tool_behaviour == TOOL_MULTITOOL && shots_before_degradation < max_shots_before_degradation)
		context[SCREENTIP_CONTEXT_LMB] = "Reset System"
		return CONTEXTUAL_SCREENTIP_SET

/obj/item/gun/ballistic/automatic/battle_rifle/examine_more(mob/user)
	. = ..()
	. += span_notice("<b><i>Looking down at \the [src], you recall something you read in a promotional pamphlet... </i></b>")

	. += span_info("The BR-38 possesses an acceleration rail that launches bullets at higher than typical velocity.\
		This allows even less powerful cartridges to put out significant amounts of stopping power.")

	. += span_notice("<b><i>However, you also remember some of the rumors...  </i></b>")

	. += span_notice("In a sour twist of irony for Nanotrasen's historical issues with ballistics-based security weapons, the BR-38 has one significant flaw. \
		It is possible for the weapon to suffer from unintended discombulations due to closed heat distribution systems should the weapon be tampered with. \
		R&D are working on this issue before the weapon sees commercial sales. That, and trying to work out why the weapon's onboard computation systems suffer \
		from so many calculation errors.")

/obj/item/gun/ballistic/automatic/battle_rifle/examine(mob/user)
	. = ..()
	if(shots_before_degradation)
		. += span_notice("[src] can fire [shots_before_degradation] more times before risking system degradation.")
	else
		. += span_notice("[src] is in the process of system degradation. It is currently at stage [degradation_stage] of [degradation_stage_max]. Use a multitool on [src] to recalibrate. Alternatively, insert it into a weapon recharger.")

/obj/item/gun/ballistic/automatic/battle_rifle/update_icon_state()
	. = ..()
	if(!shots_before_degradation)
		inhand_icon_state = "[base_icon_state]-empty"
	else
		inhand_icon_state = "[base_icon_state]"

/obj/item/gun/ballistic/automatic/battle_rifle/update_overlays()
	. = ..()
	if(degradation_stage)
		. += "[base_icon_state]_empty"
	else if(shots_before_degradation)
		var/ratio_for_overlay = CEILING(clamp(shots_before_degradation / max_shots_before_degradation, 0, 1) * 3, 1)
		. += "[icon_state]_stage_[ratio_for_overlay]"

/obj/item/gun/ballistic/automatic/battle_rifle/emp_act(severity)
	. = ..()
	if (!(. & EMP_PROTECT_SELF) && prob(50 / severity))
		shots_before_degradation = 0
		emp_malfunction = TRUE
		attempt_degradation(TRUE)

/obj/item/gun/ballistic/automatic/battle_rifle/emag_act(mob/user, obj/item/card/emag/emag_card)
	. = ..()
	if(obj_flags & EMAGGED)
		return FALSE
	obj_flags |= EMAGGED
	projectile_damage_multiplier = emagged_projectile_damage_multiplier
	balloon_alert(user, "heat distribution systems deactivated")
	return TRUE

/obj/item/gun/ballistic/automatic/battle_rifle/multitool_act(mob/living/user, obj/item/tool)
	if(!tool.use_tool(src, user, 20 SECONDS, volume = 50))
		balloon_alert(user, "interrupted!")
		return ITEM_INTERACT_BLOCKING

	emp_malfunction = FALSE
	shots_before_degradation = initial(shots_before_degradation)
	degradation_stage = initial(degradation_stage)
	projectile_speed_multiplier = initial(projectile_speed_multiplier)
	fire_delay = initial(fire_delay)
	update_appearance()
	balloon_alert(user, "system reset")
	return ITEM_INTERACT_SUCCESS

/obj/item/gun/ballistic/automatic/battle_rifle/try_fire_gun(atom/target, mob/living/user, params)
	. = ..()
	if(!chambered || (chambered && !chambered.loaded_projectile))
		return

	if(shots_before_degradation)
		shots_before_degradation --
		return

	else if ((obj_flags & EMAGGED) && degradation_stage == degradation_stage_max && !explosion_timer)
		perform_extreme_malfunction(user)

	else
		attempt_degradation(FALSE)


/obj/item/gun/ballistic/automatic/battle_rifle/process_fire(atom/target, mob/living/user, message = TRUE, params = null, zone_override = "", bonus_spread = 0)
	if(chambered.loaded_projectile && prob(75) && (emp_malfunction || degradation_stage == degradation_stage_max))
		balloon_alert_to_viewers("*click*")
		playsound(src, dry_fire_sound, dry_fire_sound_volume, TRUE)
		return

	return ..()

/// Proc to handle weapon degradation. Called when attempting to fire or immediately after an EMP takes place.
/obj/item/gun/ballistic/automatic/battle_rifle/proc/attempt_degradation(force_increment = FALSE)
	if(!prob(degradation_probability) && !force_increment || degradation_stage == degradation_stage_max)
		return //Only update if we actually increment our degradation stage

	degradation_stage = clamp(degradation_stage + (obj_flags & EMAGGED ? 2 : 1), 0, degradation_stage_max)
	projectile_speed_multiplier = clamp(initial(projectile_speed_multiplier) + degradation_stage * 0.1, initial(projectile_speed_multiplier), maximum_speed_malus)
	fire_delay = initial(fire_delay) + (degradation_stage * 0.5)
	do_sparks(1, TRUE, src)
	update_appearance()

/// Called by /obj/machinery/recharger while inserted: attempts to recalibrate our gun but reducing degradation.
/obj/item/gun/ballistic/automatic/battle_rifle/proc/attempt_recalibration(restoring_shots_before_degradation = FALSE, recharge_rate = 1)
	emp_malfunction = FALSE

	if(restoring_shots_before_degradation)
		shots_before_degradation = clamp(round(shots_before_degradation + recharge_rate, 1), 0, max_shots_before_degradation)

	else
		degradation_stage = clamp(degradation_stage - 1, 0, degradation_stage_max)
		if(degradation_stage)
			projectile_speed_multiplier = clamp(initial(projectile_speed_multiplier) - degradation_stage * 0.1, maximum_speed_malus, initial(projectile_speed_multiplier))
			fire_delay = initial(fire_delay) + (degradation_stage * 0.5)
		else
			projectile_speed_multiplier = initial(projectile_speed_multiplier)
			fire_delay = initial(fire_delay)

	update_appearance()

/// Proc to handle the countdown for our detonation
/obj/item/gun/ballistic/automatic/battle_rifle/proc/perform_extreme_malfunction(mob/living/user)
	balloon_alert(user, "gun is exploding, throw it!")
	explosion_timer = addtimer(CALLBACK(src, PROC_REF(fucking_explodes_you)), 5 SECONDS, (TIMER_UNIQUE|TIMER_OVERRIDE))
	playsound(src, 'sound/items/weapons/gun/general/empty_alarm.ogg', 50, FALSE)

/// proc to handle our detonation
/obj/item/gun/ballistic/automatic/battle_rifle/proc/fucking_explodes_you()
	explosion(src, devastation_range = 1, heavy_impact_range = 3, light_impact_range = 6, explosion_cause = src)
