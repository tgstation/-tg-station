/obj/item/gun/ballistic/shotgun
	name = "shotgun"
	desc = "A traditional shotgun with wood furniture and a four-shell capacity underneath."
	icon_state = "shotgun"
	worn_icon_state = null
	lefthand_file = 'icons/mob/inhands/weapons/64x_guns_left.dmi'
	righthand_file = 'icons/mob/inhands/weapons/64x_guns_right.dmi'
	inhand_icon_state = "shotgun"
	inhand_x_dimension = 64
	inhand_y_dimension = 64
	fire_sound = 'sound/items/weapons/gun/shotgun/shot.ogg'
	fire_sound_volume = 90
	rack_sound = 'sound/items/weapons/gun/shotgun/rack.ogg'
	load_sound = 'sound/items/weapons/gun/shotgun/insert_shell.ogg'
	drop_sound = 'sound/items/handling/gun/ballistics/shotgun/shotgun_drop1.ogg'
	pickup_sound = 'sound/items/handling/gun/ballistics/shotgun/shotgun_pickup1.ogg'
	w_class = WEIGHT_CLASS_BULKY
	force = 10
	obj_flags = CONDUCTS_ELECTRICITY
	slot_flags = ITEM_SLOT_BACK
	accepted_magazine_type = /obj/item/ammo_box/magazine/internal/shot
	semi_auto = FALSE
	internal_magazine = TRUE
	casing_ejector = FALSE
	bolt_wording = "pump"
	cartridge_wording = "shell"
	tac_reloads = FALSE
	weapon_weight = WEAPON_HEAVY
	misfire_probability_cap = 35 // Even if the misfire probability and increment are both zero, we've some shots that may do that.

	pb_knockback = 2

/obj/item/gun/ballistic/shotgun/blow_up(mob/user)
	. = 0
	if(chambered?.loaded_projectile)
		process_fire(user, user, FALSE)
		. = 1

/obj/item/gun/ballistic/shotgun/lethal
	accepted_magazine_type = /obj/item/ammo_box/magazine/internal/shot/lethal

// RIOT SHOTGUN //

/obj/item/gun/ballistic/shotgun/riot //for spawn in the armory
	name = "riot shotgun"
	desc = "A sturdy shotgun with a longer magazine and a fixed tactical stock designed for non-lethal riot control."
	icon_state = "riotshotgun"
	inhand_icon_state = "shotgun"
	fire_delay = 8
	accepted_magazine_type = /obj/item/ammo_box/magazine/internal/shot/riot
	sawn_desc = "Come with me if you want to live."
	can_be_sawn_off = TRUE

// Automatic Shotguns//

/obj/item/gun/ballistic/shotgun/automatic/shoot_live_shot(mob/living/user)
	..()
	rack()

/obj/item/gun/ballistic/shotgun/automatic/combat
	name = "combat shotgun"
	desc = "A semi automatic shotgun with tactical furniture and a six-shell capacity underneath."
	icon_state = "cshotgun"
	inhand_icon_state = "shotgun_combat"
	fire_delay = 5
	accepted_magazine_type = /obj/item/ammo_box/magazine/internal/shot/com
	w_class = WEIGHT_CLASS_HUGE

/obj/item/gun/ballistic/shotgun/automatic/combat/compact
	name = "compact shotgun"
	desc = "A compact version of the semi automatic combat shotgun. For close encounters."
	icon_state = "cshotgunc"
	accepted_magazine_type = /obj/item/ammo_box/magazine/internal/shot/com/compact
	w_class = WEIGHT_CLASS_BULKY

//Dual Feed Shotgun

/obj/item/gun/ballistic/shotgun/automatic/dual_tube
	name = "cycler shotgun"
	desc = "An advanced shotgun with two separate magazine tubes, allowing you to quickly toggle between ammo types."
	icon_state = "cycler"
	inhand_icon_state = "bulldog"
	lefthand_file = 'icons/mob/inhands/weapons/guns_lefthand.dmi'
	righthand_file = 'icons/mob/inhands/weapons/guns_righthand.dmi'
	inhand_x_dimension = 32
	inhand_y_dimension = 32
	worn_icon_state = "cshotgun"
	w_class = WEIGHT_CLASS_HUGE
	semi_auto = TRUE
	accepted_magazine_type = /obj/item/ammo_box/magazine/internal/shot/tube
	interaction_flags_click = NEED_DEXTERITY|NEED_HANDS|ALLOW_RESTING
	/// If defined, the secondary tube is this type, if you want different shell loads
	var/alt_mag_type
	/// If TRUE, we're drawing from the alternate_magazine
	var/toggled = FALSE
	/// The B tube
	var/obj/item/ammo_box/magazine/internal/shot/alternate_magazine

/obj/item/gun/ballistic/shotgun/automatic/dual_tube/bounty
	name = "bounty cycler shotgun"
	desc = "An advanced shotgun with two separate magazine tubes. This one shows signs of bounty hunting customization, meaning it likely has a dual rubber shot/fire slug load."
	alt_mag_type = /obj/item/ammo_box/magazine/internal/shot/tube/fire

/obj/item/gun/ballistic/shotgun/automatic/dual_tube/deadly
	spawn_magazine_type = /obj/item/ammo_box/magazine/internal/shot/tube/buckshot
	alt_mag_type = /obj/item/ammo_box/magazine/internal/shot/tube/slug

/obj/item/gun/ballistic/shotgun/automatic/dual_tube/examine(mob/user)
	. = ..()
	. += span_notice("Alt-click to pump it.")

/obj/item/gun/ballistic/shotgun/automatic/dual_tube/Initialize(mapload)
	. = ..()
	alt_mag_type = alt_mag_type || spawn_magazine_type
	alternate_magazine = new alt_mag_type(src)

/obj/item/gun/ballistic/shotgun/automatic/dual_tube/Destroy()
	QDEL_NULL(alternate_magazine)
	return ..()

/obj/item/gun/ballistic/shotgun/automatic/dual_tube/attack_self(mob/living/user)
	if(!chambered && magazine.contents.len)
		rack()
	else
		toggle_tube(user)

/obj/item/gun/ballistic/shotgun/automatic/dual_tube/proc/toggle_tube(mob/living/user)
	var/current_mag = magazine
	var/alt_mag = alternate_magazine
	magazine = alt_mag
	alternate_magazine = current_mag
	toggled = !toggled
	if(toggled)
		balloon_alert(user, "switched to tube B")
	else
		balloon_alert(user, "switched to tube A")

/obj/item/gun/ballistic/shotgun/automatic/dual_tube/click_alt(mob/living/user)
	rack()
	return CLICK_ACTION_SUCCESS

// Bulldog shotgun //

/obj/item/gun/ballistic/shotgun/bulldog
	name = "\improper Bulldog Shotgun"
	desc = "A 2-round burst fire, mag-fed shotgun for combat in narrow corridors, \
		nicknamed 'Bulldog' by boarding parties. Compatible only with specialized 8-round drum magazines. \
		Can have a secondary magazine attached to quickly swap between ammo types, or just to keep shooting."
	icon_state = "bulldog"
	lefthand_file = 'icons/mob/inhands/weapons/guns_lefthand.dmi'
	righthand_file = 'icons/mob/inhands/weapons/guns_righthand.dmi'
	inhand_icon_state = "bulldog"
	worn_icon = 'icons/mob/clothing/back.dmi'
	worn_icon_state = "bulldog"
	inhand_x_dimension = 32
	inhand_y_dimension = 32
	projectile_damage_multiplier = 1.2
	weapon_weight = WEAPON_MEDIUM
	accepted_magazine_type = /obj/item/ammo_box/magazine/m12g
	can_suppress = FALSE
	burst_size = 2
	fire_delay = 1
	pin = /obj/item/firing_pin/implant/pindicate
	fire_sound = 'sound/items/weapons/gun/shotgun/shot_alt.ogg'
	actions_types = list(/datum/action/item_action/toggle_firemode)
	mag_display = TRUE
	empty_indicator = TRUE
	empty_alarm = TRUE
	special_mags = TRUE
	mag_display_ammo = TRUE
	semi_auto = TRUE
	internal_magazine = FALSE
	tac_reloads = TRUE
	burst_fire_selection = TRUE
	/// The type of secondary magazine for the bulldog
	var/secondary_magazine_type
	/// The secondary magazine
	var/obj/item/ammo_box/magazine/secondary_magazine

/obj/item/gun/ballistic/shotgun/bulldog/Initialize(mapload)
	. = ..()
	secondary_magazine_type = secondary_magazine_type || spawn_magazine_type
	secondary_magazine = new secondary_magazine_type(src)
	update_appearance()

/obj/item/gun/ballistic/shotgun/bulldog/Destroy()
	QDEL_NULL(secondary_magazine)
	return ..()

/obj/item/gun/ballistic/shotgun/bulldog/examine(mob/user)
	. = ..()
	if(secondary_magazine)
		var/secondary_ammo_count = secondary_magazine.ammo_count()
		. += "There is a secondary magazine."
		. += "It has [secondary_ammo_count] round\s remaining."
		. += "Shoot with right-click to swap to the secondary magazine after firing."
		. += "If the magazine is empty, [src] will automatically swap to the secondary magazine."
	. += "You can load a secondary magazine by right-clicking [src] with the magazine you want to load."
	. += "You can remove a secondary magazine by alt-right-clicking [src]."
	. += "Right-click to swap the magazine to the secondary position, and vice versa."

/obj/item/gun/ballistic/shotgun/bulldog/update_overlays()
	. = ..()
	if(secondary_magazine)
		. += "[icon_state]_secondary_mag_[initial(secondary_magazine.icon_state)]"
		if(!secondary_magazine.ammo_count())
			. += "[icon_state]_secondary_mag_empty"

/obj/item/gun/ballistic/shotgun/bulldog/handle_chamber(empty_chamber = TRUE, from_firing = TRUE, chamber_next_round = TRUE)
	if(!secondary_magazine)
		return ..()
	var/secondary_shells_left = LAZYLEN(secondary_magazine.stored_ammo)
	if(magazine)
		var/shells_left = LAZYLEN(magazine.stored_ammo)
		if(shells_left <= 0 && secondary_shells_left >= 1)
			toggle_magazine()
	else
		toggle_magazine()
	return ..()

/obj/item/gun/ballistic/shotgun/bulldog/attack_self_secondary(mob/user, modifiers)
	toggle_magazine()
	return SECONDARY_ATTACK_CANCEL_ATTACK_CHAIN

/obj/item/gun/ballistic/shotgun/bulldog/ranged_interact_with_atom_secondary(atom/interacting_with, mob/living/user, list/modifiers)
	if(secondary_magazine)
		toggle_magazine()
	return ..()

/obj/item/gun/ballistic/shotgun/bulldog/item_interaction_secondary(mob/living/user, obj/item/tool, list/modifiers)
	if(!istype(tool, secondary_magazine_type))
		return ..()
	if(!user.transferItemToLoc(tool, src))
		return ITEM_INTERACT_BLOCKING
	var/obj/item/ammo_box/magazine/old_mag = secondary_magazine
	secondary_magazine = tool
	if(old_mag)
		user.put_in_hands(old_mag)
	balloon_alert(user, "secondary [magazine_wording] loaded")
	playsound(src, load_empty_sound, load_sound_volume, load_sound_vary)
	update_appearance()
	return ITEM_INTERACT_SUCCESS

/obj/item/gun/ballistic/shotgun/bulldog/click_alt_secondary(mob/user)
	if(secondary_magazine)
		var/obj/item/ammo_box/magazine/old_mag = secondary_magazine
		secondary_magazine = null
		user.put_in_hands(old_mag)
		update_appearance()
		playsound(src, load_empty_sound, load_sound_volume, load_sound_vary)

/obj/item/gun/ballistic/shotgun/bulldog/proc/toggle_magazine()
	var/primary_magazine = magazine
	var/alternative_magazine = secondary_magazine
	magazine = alternative_magazine
	secondary_magazine = primary_magazine
	playsound(src, load_empty_sound, load_sound_volume, load_sound_vary)
	update_appearance()

/obj/item/gun/ballistic/shotgun/bulldog/unrestricted
	pin = /obj/item/firing_pin
/////////////////////////////
// DOUBLE BARRELED SHOTGUN //
/////////////////////////////

/obj/item/gun/ballistic/shotgun/doublebarrel
	name = "double-barreled shotgun"
	desc = "A true classic."
	icon_state = "dshotgun"
	base_icon_state = "dshotgun"
	inhand_icon_state = "shotgun_db"
	w_class = WEIGHT_CLASS_BULKY
	weapon_weight = WEAPON_MEDIUM
	force = 10
	obj_flags = CONDUCTS_ELECTRICITY
	slot_flags = ITEM_SLOT_BACK
	accepted_magazine_type = /obj/item/ammo_box/magazine/internal/shot/dual
	sawn_desc = "Omar's coming!"
	obj_flags = UNIQUE_RENAME
	rack_sound_volume = 0
	unique_reskin = list("Default" = "dshotgun",
						"Dark Red Finish" = "dshotgun_d",
						"Ash" = "dshotgun_f",
						"Faded Grey" = "dshotgun_g",
						"Maple" = "dshotgun_l",
						"Rosewood" = "dshotgun_p"
						)
	semi_auto = TRUE
	bolt_type = BOLT_TYPE_NO_BOLT
	can_be_sawn_off = TRUE
	pb_knockback = 3 // it's a super shotgun!

/obj/item/gun/ballistic/shotgun/doublebarrel/sawoff(mob/user)
	. = ..()
	if(.)
		weapon_weight = WEAPON_MEDIUM

/obj/item/gun/ballistic/shotgun/doublebarrel/slugs
	name = "hunting shotgun"
	desc = "A hunting shotgun used by the wealthy to hunt \"game\"."
	sawn_desc = "A sawn-off hunting shotgun. In its new state, it's remarkably less effective at hunting... anything."
	accepted_magazine_type = /obj/item/ammo_box/magazine/internal/shot/dual/slugs

/obj/item/gun/ballistic/shotgun/doublebarrel/breacherslug
	name = "breaching shotgun"
	desc = "A normal double-barrel shotgun that has been rechambered to fit breaching shells. Useful in breaching airlocks and windows, not much else."
	sawn_desc = "A sawn-off breaching shotgun, making for a more compact configuration while still having the same capability as before."
	accepted_magazine_type = /obj/item/ammo_box/magazine/internal/shot/dual/breacherslug

/obj/item/gun/ballistic/shotgun/hook
	name = "hook modified sawn-off shotgun"
	desc = "Range isn't an issue when you can bring your victim to you."
	icon_state = "hookshotgun"
	inhand_icon_state = "hookshotgun"
	lefthand_file = 'icons/mob/inhands/weapons/guns_lefthand.dmi'
	righthand_file = 'icons/mob/inhands/weapons/guns_righthand.dmi'
	inhand_x_dimension = 32
	inhand_y_dimension = 32
	accepted_magazine_type = /obj/item/ammo_box/magazine/internal/shot/bounty
	weapon_weight = WEAPON_MEDIUM
	semi_auto = TRUE
	obj_flags = CONDUCTS_ELECTRICITY
	force = 18 //it has a hook on it
	sharpness = SHARP_POINTY //it does in fact, have a hook on it
	attack_verb_continuous = list("slashes", "hooks", "stabs")
	attack_verb_simple = list("slash", "hook", "stab")
	hitsound = 'sound/items/weapons/bladeslice.ogg'
	//our hook gun!
	var/obj/item/gun/magic/hook/bounty/hook

/obj/item/gun/ballistic/shotgun/hook/Initialize(mapload)
	. = ..()
	hook = new /obj/item/gun/magic/hook/bounty(src)

/obj/item/gun/ballistic/shotgun/hook/Destroy()
	QDEL_NULL(hook)
	return ..()

/obj/item/gun/ballistic/shotgun/hook/examine(mob/user)
	. = ..()
	. += span_notice("Right-click to shoot the hook.")

/obj/item/gun/ballistic/shotgun/hook/try_fire_gun(atom/target, mob/living/user, params)
	if(LAZYACCESS(params2list(params), RIGHT_CLICK))
		return hook.try_fire_gun(target, user, params)
	return ..()

///An underpowered shotgun given to Pun Pun when the station job trait roll.
/obj/item/gun/ballistic/shotgun/monkey
	name = "\improper Barback's Shot"
	desc = "A chimp-sized, single-shot and break-action shotgun with an unpractical stock."
	icon_state = "chimp_shottie"
	inhand_icon_state = "shotgun"
	lefthand_file = 'icons/mob/inhands/weapons/guns_lefthand.dmi'
	righthand_file = 'icons/mob/inhands/weapons/guns_righthand.dmi'
	inhand_x_dimension = 32
	inhand_y_dimension = 32
	force = 8
	obj_flags = CONDUCTS_ELECTRICITY
	slot_flags = NONE
	accepted_magazine_type = /obj/item/ammo_box/magazine/internal/shot/single
	obj_flags = UNIQUE_RENAME
	w_class = WEIGHT_CLASS_NORMAL
	weapon_weight = WEAPON_MEDIUM
	semi_auto = TRUE
	bolt_type = BOLT_TYPE_NO_BOLT
	spread = 10
	projectile_damage_multiplier = 0.5
	projectile_wound_bonus = -25
	recoil = 1
	pin = /obj/item/firing_pin/monkey
	pb_knockback = 1

/obj/item/gun/ballistic/shotgun/musket
	name = "\improper Donk Co. Musket"
	icon = 'icons/obj/weapons/guns/ballistic.dmi'
	icon_state = "donk_musket"
	inhand_icon_state = "donk_musket"
	worn_icon_state = "donk_musket"
	desc = "A large-bore boltloading firearm with a classy wooden frame. Cheap, accurate, and easy to maintain. Reload and rack after every shot."
	semi_auto = TRUE
	alternative_caliber = CALIBER_50BMG
	casing_ejector = TRUE
	bolt_type = BOLT_TYPE_LOCKING
	bolt_wording = "bolt"
	internal_magazine = TRUE
	accepted_magazine_type = /obj/item/ammo_box/magazine/internal/shot/single/musket
