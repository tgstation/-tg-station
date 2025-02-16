/obj/item/gun/ballistic/rifle
	name = "Bolt Rifle"
	desc = "Some kind of bolt action rifle. You get the feeling you shouldn't have this."
	icon = 'icons/obj/weapons/guns/wide_guns.dmi'
	icon_state = "sakhno"
	w_class = WEIGHT_CLASS_BULKY
	accepted_magazine_type = /obj/item/ammo_box/magazine/internal/boltaction
	bolt_wording = "bolt"
	bolt_type = BOLT_TYPE_LOCKING
	semi_auto = FALSE
	internal_magazine = TRUE
	fire_sound = 'sound/items/weapons/gun/rifle/shot_heavy.ogg'
	fire_sound_volume = 90
	rack_sound = 'sound/items/weapons/gun/rifle/bolt_out.ogg'
	bolt_drop_sound = 'sound/items/weapons/gun/rifle/bolt_in.ogg'
	drop_sound = 'sound/items/handling/gun/ballistics/rifle/rifle_drop1.ogg'
	pickup_sound = 'sound/items/handling/gun/ballistics/rifle/rifle_pickup1.ogg'
	tac_reloads = FALSE

/obj/item/gun/ballistic/rifle/rack(mob/user = null)
	if (bolt_locked == FALSE)
		balloon_alert(user, "bolt opened")
		playsound(src, rack_sound, rack_sound_volume, rack_sound_vary)
		process_chamber(FALSE, FALSE, FALSE)
		bolt_locked = TRUE
		update_appearance()
		return
	drop_bolt(user)


/obj/item/gun/ballistic/rifle/can_shoot()
	if (bolt_locked)
		return FALSE
	return ..()

/obj/item/gun/ballistic/rifle/examine(mob/user)
	. = ..()
	. += "The bolt is [bolt_locked ? "open" : "closed"]."

///////////////////////
// BOLT ACTION RIFLE //
///////////////////////

/obj/item/gun/ballistic/rifle/boltaction
	name = "\improper Sakhno Precision Rifle"
	desc = "A Sakhno Precision Rifle, a bolt action weapon that was (and certainly still is) popular with \
		frontiersmen, cargo runners, private security forces, explorers, and other unsavoury types. This particular \
		pattern of the rifle dates back all the way to 2440."
	sawn_desc = "A sawn-off Sakhno Precision Rifle, popularly known as an \"Obrez\". \
		There was probably a reason it wasn't manufactured this short to begin with. \
		Despite the terrible nature of the modification, the weapon seems otherwise in good condition."

	icon_state = "sakhno"
	inhand_icon_state = "sakhno"
	worn_icon_state = "sakhno"

	slot_flags = ITEM_SLOT_BACK
	accepted_magazine_type = /obj/item/ammo_box/magazine/internal/boltaction
	can_be_sawn_off = TRUE
	weapon_weight = WEAPON_HEAVY
	var/jamming_chance = 20
	var/unjam_chance = 10
	var/jamming_increment = 5
	var/jammed = FALSE
	var/can_jam = FALSE

	SET_BASE_PIXEL(-8, 0)

/obj/item/gun/ballistic/rifle/boltaction/add_bayonet_point()
	AddComponent(/datum/component/bayonet_attachable, offset_x = 32, offset_y = 12)

/obj/item/gun/ballistic/rifle/boltaction/sawoff(mob/user)
	. = ..()
	if(.)
		spread = 36
		SET_BASE_PIXEL(0, 0)
		update_appearance()

/obj/item/gun/ballistic/rifle/boltaction/attack_self(mob/user)
	if(jammed)
		if(prob(unjam_chance))
			jammed = FALSE
			unjam_chance = initial(unjam_chance)
		else
			unjam_chance += 10
			balloon_alert(user, "jammed!")
			playsound(user,'sound/items/weapons/jammed.ogg', 75, TRUE)
			return FALSE
	return ..()

/obj/item/gun/ballistic/rifle/boltaction/process_fire(mob/user)
	if(can_jam)
		if(chambered.loaded_projectile)
			if(prob(jamming_chance))
				jammed = TRUE
			jamming_chance += jamming_increment
			jamming_chance = clamp (jamming_chance, 0, 100)
	return ..()

/obj/item/gun/ballistic/rifle/boltaction/attackby(obj/item/item, mob/user, params)
	if(!bolt_locked && !istype(item, /obj/item/knife))
		balloon_alert(user, "bolt closed!")
		return

	. = ..()

/obj/item/gun/ballistic/rifle/boltaction/blow_up(mob/user)
	. = FALSE
	if(chambered?.loaded_projectile)
		process_fire(user, user, FALSE)
		. = TRUE

/obj/item/gun/ballistic/rifle/boltaction/harpoon
	name = "ballistic harpoon gun"
	desc = "A weapon favored by carp hunters, but just as infamously employed by agents of the Animal Rights Consortium against human aggressors. Because it's ironic."
	icon = 'icons/obj/weapons/guns/ballistic.dmi'
	icon_state = "speargun"
	inhand_icon_state = "speargun"
	worn_icon_state = "speargun"
	accepted_magazine_type = /obj/item/ammo_box/magazine/internal/boltaction/harpoon
	fire_sound = 'sound/items/weapons/gun/sniper/shot.ogg'
	can_be_sawn_off = FALSE

	SET_BASE_PIXEL(0, 0)

/obj/item/gun/ballistic/rifle/boltaction/surplus
	name = "\improper Sakhno M2442 Army"
	desc = "A modification of the Sakhno Precision Rifle, \"Sakhno M2442 Army\" is stamped into the side. \
		It is unknown what army this pattern of rifle was made for or if it was ever even used by an army \
		of any sort. What you can discern, however, is that its previous owner did not treat the weapon well. \
		For some reason, there's moisture all through the internals."
	sawn_desc = "A sawn-off Sakhno Precision Rifle, popularly known as an \"Obrez\". \
		\"Sakhno M2442 Army\" is stamped into the side of it. \
		There was probably a reason it wasn't manufactured this short to begin with. \
		Cutting the weapon down seems to have not helped with the moisture problem."
	icon_state = "sakhno_tactifucked"
	spawn_magazine_type = /obj/item/ammo_box/magazine/internal/boltaction/surplus
	can_jam = TRUE

/obj/item/gun/ballistic/rifle/boltaction/prime
	name = "\improper Sakhno-Zhihao Sporting Rifle"
	desc = "An upgrade and modernisation of the original Sakhno rifle, made with such wonders as \
		modern materials, a scope, and other impressive technological advancements that, to be honest, \
		were already around when the original weapon was designed. Surprisingly for a rifle of this type, \
		the scope actually has magnification, rather than being decorative."
	icon_state = "zhihao"
	inhand_icon_state = "zhihao"
	worn_icon_state = "zhihao"
	can_be_sawn_off = TRUE
	sawn_desc = "A sawn-off Sakhno-Zhihao Sporting Rifle... Doing this was a sin, I hope you're happy. \
		You are now probably one of the few people in the universe to ever hold an \"Obrez Moderna\". \
		All you had to do was take an allen wrench to the stock to take it off. But no, you just had to \
		go for the saw."
	spawn_magazine_type = /obj/item/ammo_box/magazine/internal/boltaction/phasic

/obj/item/gun/ballistic/rifle/boltaction/prime/Initialize(mapload)
	. = ..()
	AddComponent(/datum/component/scope, range_modifier = 1.5)

/obj/item/gun/ballistic/rifle/boltaction/prime/sawoff(mob/user)
	. = ..()
	if(.)
		name = "\improper Obrez Moderna" // wear it loud and proud

/obj/item/gun/ballistic/rifle/boltaction/mosin_nagant
	name = "\improper Mosin Nagant"
	desc = "A classic Mosin Nagant. They don't make them like they used to. Well, okay, in all honesty, this one is actually \
		a refurbished version, chambered in .310 Strilka. There really aren't that many left lying around since the Third Soviet \
		Union collapsed, and a sizable portion of the weapons were scrapped for parts. If you do find one, cherish it. You have a \
		rare artifact in your hands at this point. Many of them still have parts back from the original Soviet Union. Perfectly moist."
	icon_state = "mosin_nagant"
	inhand_icon_state = "mosin_nagant"
	worn_icon_state = "mosin_nagant"
	can_be_sawn_off = TRUE
	sawn_desc = "A sawn-off Mosin Nagant. They say that destroying such a weapon is tantamount to a mortal sin in the modern era. So \
		few examples of such a weapon remain. And yet they followed mankind to space all the same. It clings to life. And cruelly, it \
		was desecrated. Almost certainly, if you were responsible for this, a curse has been laid upon you and your lineage for all \
		eternity. The moisture is all gone. It is dry as a bone. Ruin has befallen this once great revolution."

/obj/item/gun/ballistic/rifle/boltaction/mosin_nagant/sawoff(mob/user)
	. = ..()
	if(.)
		name = "\improper Obrez"

	if(ishuman(user))
		var/mob/living/carbon/human/the_bitch_that_did_it = user
		the_bitch_that_did_it.AddComponent(/datum/component/omen/quirk) // Damns you to a horrible, horrible fate.

/obj/item/gun/ballistic/rifle/boltaction/donkrifle
	name = "\improper Donk Co. Jezail"
	desc = "A mass-manufactured bolt-action sporting rifle with a distinctively long barrel. Powerful enough to take down a space bear from a thousand paces. The lengthened barrel gives it good accuracy and power, even at range."
	w_class = WEIGHT_CLASS_HUGE
	lefthand_file = 'icons/mob/inhands/weapons/64x_guns_left.dmi'
	righthand_file = 'icons/mob/inhands/weapons/64x_guns_right.dmi'
	inhand_x_dimension = 64
	inhand_y_dimension = 64
	icon_state = "jezail"
	inhand_icon_state = "jezail"
	worn_icon_state = "jezail"
	accepted_magazine_type = /obj/item/ammo_box/magazine/internal/boltaction/jezail
	can_be_sawn_off = TRUE
	sawn_desc = "A mass-manufactured bolt-action sporting rifle with a distinctively long barrel. Powerful enough to take down a space bear from a thousand paces. Its barrel has been cut off, so its power and accuracy have been impaired."

/obj/item/gun/ballistic/rifle/boltaction/donkrifle/sawoff(mob/user) //the heavy price one pays for fitting this in a backpack
	. = ..()
	if(.)
		projectile_damage_multiplier = 0.75
		spread = 50

/obj/item/gun/ballistic/rifle/rebarxbow
	name = "heated rebar crossbow"
	desc = "A handcrafted crossbow. \
		   Aside from conventional sharpened iron rods, it can also fire specialty ammo made from the atmos crystalizer - zaukerite, metallic hydrogen, and healium rods all work. \
		   Very slow to reload - you can craft the crossbow with a crowbar to loosen the crossbar, but risk a misfire, or worse..."
	icon = 'icons/obj/weapons/guns/ballistic.dmi'
	icon_state = "rebarxbow"
	inhand_icon_state = "rebarxbow"
	worn_icon_state = "rebarxbow"
	rack_sound = 'sound/items/weapons/gun/sniper/rack.ogg'
	mag_display = FALSE
	empty_indicator = TRUE
	bolt_type = BOLT_TYPE_OPEN
	semi_auto = FALSE
	internal_magazine = TRUE
	can_modify_ammo = FALSE
	slot_flags = ITEM_SLOT_BACK|ITEM_SLOT_SUITSTORE
	bolt_wording = "bowstring"
	magazine_wording = "rod"
	cartridge_wording = "rod"
	weapon_weight = WEAPON_HEAVY
	initial_caliber = CALIBER_REBAR
	accepted_magazine_type = /obj/item/ammo_box/magazine/internal/boltaction/rebarxbow/normal
	fire_sound = 'sound/items/xbow_lock.ogg'
	can_be_sawn_off = FALSE
	tac_reloads = FALSE
	var/draw_time = 3 SECONDS
	SET_BASE_PIXEL(0, 0)

/obj/item/gun/ballistic/rifle/rebarxbow/rack(mob/user = null)
	if (bolt_locked)
		drop_bolt(user)
		return
	balloon_alert(user, "bowstring loosened")
	playsound(src, rack_sound, rack_sound_volume, rack_sound_vary)
	handle_chamber(empty_chamber =  FALSE, from_firing = FALSE, chamber_next_round = FALSE)
	bolt_locked = TRUE
	update_appearance()

/obj/item/gun/ballistic/rifle/rebarxbow/drop_bolt(mob/user = null)
	if(!do_after(user, draw_time, target = src))
		return
	playsound(src, bolt_drop_sound, bolt_drop_sound_volume, FALSE)
	balloon_alert(user, "bowstring drawn")
	chamber_round()
	bolt_locked = FALSE
	update_appearance()

/obj/item/gun/ballistic/rifle/rebarxbow/shoot_live_shot(mob/living/user)
	..()
	rack()

/obj/item/gun/ballistic/rifle/rebarxbow/can_shoot()
	if (bolt_locked)
		return FALSE
	return ..()

/obj/item/gun/ballistic/rifle/rebarxbow/shoot_with_empty_chamber(mob/living/user)
	if(chambered || !magazine || !length(magazine.contents))
		return ..()
	drop_bolt(user)

/obj/item/gun/ballistic/rifle/rebarxbow/examine(mob/user)
	. = ..()
	. += "The crossbow is [bolt_locked ? "not ready" : "ready"] to fire."

/obj/item/gun/ballistic/rifle/rebarxbow/update_overlays()
	. = ..()
	if(!magazine)
		. += "[initial(icon_state)]" + "_empty"
	if(!bolt_locked)
		. += "[initial(icon_state)]" + "_bolt_locked"

/obj/item/gun/ballistic/rifle/rebarxbow/forced
	name = "stressed rebar crossbow"
	desc = "Some idiot decided that they would risk shooting themselves in the face if it meant they could have a draw this crossbow a bit faster. Hopefully, it was worth it."
	// Feel free to add a recipe to allow you to change it back if you would like, I just wasn't sure if you could have two recipes for the same thing.
	can_misfire = TRUE
	draw_time = 1.5
	misfire_probability = 25
	accepted_magazine_type = /obj/item/ammo_box/magazine/internal/boltaction/rebarxbow/force

/obj/item/gun/ballistic/rifle/rebarxbow/syndie
	name = "syndicate rebar crossbow"
	desc = "The syndicate liked the bootleg rebar crossbow NT engineers made, so they showed what it could be if properly developed. \
			Holds three shots without a chance of exploding, and features a built in scope. Compatible with all known crossbow ammunition."
	icon_state = "rebarxbowsyndie"
	inhand_icon_state = "rebarxbowsyndie"
	worn_icon_state = "rebarxbowsyndie"
	w_class = WEIGHT_CLASS_NORMAL
	initial_caliber = CALIBER_REBAR
	draw_time = 1
	accepted_magazine_type = /obj/item/ammo_box/magazine/internal/boltaction/rebarxbow/syndie

/obj/item/gun/ballistic/rifle/rebarxbow/syndie/Initialize(mapload)
	. = ..()
	AddComponent(/datum/component/scope, range_modifier = 2) //enough range to at least be useful for stealth

/// PIPE GUNS ///

/obj/item/gun/ballistic/rifle/boltaction/pipegun
	name = "pipegun"
	desc = "A symbol that the true masters of this place are not those who merely inhabit it, but the one willing to twist it towards a killing intent."
	icon_state = "pipegun"
	inhand_icon_state = "pipegun"
	worn_icon_state = "pipegun"
	fire_sound = 'sound/items/weapons/gun/sniper/shot.ogg'
	accepted_magazine_type = /obj/item/ammo_box/magazine/internal/boltaction/pipegun

	projectile_damage_multiplier = 1.35
	obj_flags = UNIQUE_RENAME
	can_be_sawn_off = FALSE
	trigger_guard = TRIGGER_GUARD_ALLOW_ALL
	pb_knockback = 3

	SET_BASE_PIXEL(-8, 0)

/obj/item/gun/ballistic/rifle/boltaction/pipegun/add_bayonet_point()
	AddComponent(/datum/component/bayonet_attachable, offset_x = 35, offset_y = 10)

/obj/item/gun/ballistic/rifle/boltaction/pipegun/handle_chamber(empty_chamber = TRUE, from_firing = TRUE, chamber_next_round = TRUE)
	. = ..()
	do_sparks(1, TRUE, src)

/obj/item/gun/ballistic/rifle/boltaction/pipegun/examine_more(mob/user)
	. = ..()
	. += span_notice("<b><i>Looking down at \the [src], you recall a tale told to you in some distant memory...</i></b>")

	. += span_info("It's said that the first slaying committed on a Nanotrasen space station was by an assistant.")
	. += span_info("That this act, done by toolbox, maybe spear, was what consigned their kind to a life of destitution, rejection and violence.")
	. += span_info("They carry the weight of this act visibly; the grey jumpsuit. Breathing deeply filtered air. And with bloodsoaked yellow hands clenched into fists. Eyes, sharp and waiting. Hunters in the dark.")
	. += span_info("Eventually, these killing spirits sought to stake a claim on the metal tombs they were trapped within. Rejecting their status. Determined to be something more.")
	. += span_info("This weapon is one such tool. And it is a grim one indeed. Wrought from scrap, pulled from the station's walls and floors and the very nails holding it together.")
	. += span_info("It is a symbol that the true masters of this place are not those who merely inhabit it. But the one willing to twist it towards a killing intent.")

/obj/item/gun/ballistic/rifle/boltaction/pipegun/pistol
	name = "pipe pistol"
	desc = "It is foolish to think that anyone wearing the grey is incapable of hurting you, simply because they are not baring their teeth."
	icon_state = "pipepistol"
	inhand_icon_state = "pipepistol"
	worn_icon_state = "gun"
	accepted_magazine_type = /obj/item/ammo_box/magazine/internal/boltaction/pipegun/pistol
	projectile_damage_multiplier = 0.50
	spread = 15 //kinda inaccurate
	burst_size = 3 //but it empties the entire magazine when it fires
	fire_delay = 0.3 // and by empties, I mean it does it all at once
	slot_flags = ITEM_SLOT_BELT
	w_class = WEIGHT_CLASS_NORMAL
	weapon_weight = WEAPON_MEDIUM
	semi_auto = TRUE

	SET_BASE_PIXEL(0, 0)

/obj/item/gun/ballistic/rifle/boltaction/pipegun/pistol/add_bayonet_point()
	return

/obj/item/gun/ballistic/rifle/boltaction/pipegun/prime
	name = "regal pipegun"
	desc = "To call this 'regal' is a cruel irony. For the only noteworthy quality of nobility is in how it is wielded to kill. \
		All monarchs deserve to be crowned. But none will remember the dead tyrant for the red stain they left on the carpet."
	icon_state = "regal_pipegun"
	inhand_icon_state = "regal_pipegun"
	worn_icon_state = "regal_pipegun"
	accepted_magazine_type = /obj/item/ammo_box/magazine/internal/boltaction/pipegun/prime
	projectile_damage_multiplier = 2

/obj/item/gun/ballistic/rifle/boltaction/pipegun/pistol/prime
	name = "regal pipe pistol"
	desc = "What value is there in honesty towards the dishonest? So that they might twist the arm and slit the wrist? \
		The open palm is no sign of weakness; it is to draw the eyes away from the other hand, lying in wait."
	icon_state = "regal_pipepistol"
	inhand_icon_state = "regal_pipepistol"
	accepted_magazine_type = /obj/item/ammo_box/magazine/internal/boltaction/pipegun/pistol/prime
	projectile_damage_multiplier = 1
	burst_size = 6 // WHOLE CLIP
	spread = 0

/// MAGICAL BOLT ACTIONS ///

/obj/item/gun/ballistic/rifle/enchanted
	name = "enchanted bolt action rifle"
	desc = "Careful not to lose your head."
	icon_state = "enchanted_rifle"
	inhand_icon_state = "enchanted_rifle"
	worn_icon_state = "enchanted_rifle"
	slot_flags = ITEM_SLOT_BACK
	var/guns_left = 30
	accepted_magazine_type = /obj/item/ammo_box/magazine/internal/enchanted
	can_be_sawn_off = FALSE

	SET_BASE_PIXEL(-8, 0)

/obj/item/gun/ballistic/rifle/enchanted/dropped()
	. = ..()
	guns_left = 0
	magazine = null
	chambered = null

/obj/item/gun/ballistic/rifle/enchanted/proc/discard_gun(mob/living/user)
	user.throw_item(pick(oview(7,get_turf(user))))

/obj/item/gun/ballistic/rifle/enchanted/attack_self()
	return

/obj/item/gun/ballistic/rifle/enchanted/process_fire(atom/target, mob/living/user, message = TRUE, params = null, zone_override = "", bonus_spread = 0)
	. = ..()
	if(!.)
		return
	if(guns_left)
		var/obj/item/gun/ballistic/rifle/enchanted/gun = new type
		gun.guns_left = guns_left - 1
		discard_gun(user)
		user.swap_hand()
		user.put_in_hands(gun)
	else
		user.dropItemToGround(src, TRUE)

// SNIPER //

/obj/item/gun/ballistic/rifle/sniper_rifle
	name = "anti-materiel sniper rifle"
	desc = "A boltaction anti-materiel rifle, utilizing .50 BMG cartridges. While technically outdated in modern arms markets, it still works exceptionally well as \
		an anti-personnel rifle. In particular, the employment of modern armored MODsuits utilizing advanced armor plating has given this weapon a new home on the battlefield. \
		It is also able to be suppressed....somehow."
	icon = 'icons/obj/weapons/guns/ballistic.dmi'
	icon_state = "sniper"
	lefthand_file = 'icons/mob/inhands/weapons/guns_lefthand.dmi'
	righthand_file = 'icons/mob/inhands/weapons/guns_righthand.dmi'
	inhand_x_dimension = 32
	inhand_y_dimension = 32
	weapon_weight = WEAPON_HEAVY
	inhand_icon_state = "sniper"
	worn_icon_state = null
	fire_sound = 'sound/items/weapons/gun/sniper/shot.ogg'
	fire_sound_volume = 90
	load_sound = 'sound/items/weapons/gun/sniper/mag_insert.ogg'
	rack_sound = 'sound/items/weapons/gun/sniper/rack.ogg'
	suppressed_sound = 'sound/items/weapons/gun/general/heavy_shot_suppressed.ogg'
	recoil = 2
	accepted_magazine_type = /obj/item/ammo_box/magazine/sniper_rounds
	internal_magazine = FALSE
	w_class = WEIGHT_CLASS_NORMAL
	slot_flags = ITEM_SLOT_BACK
	mag_display = TRUE
	tac_reloads = TRUE
	rack_delay = 1 SECONDS
	can_suppress = TRUE
	can_unsuppress = TRUE
	suppressor_x_offset = 3
	suppressor_y_offset = 3

/obj/item/gun/ballistic/rifle/sniper_rifle/examine(mob/user)
	. = ..()
	. += span_warning("<b>It seems to have a warning label:</b> Do NOT, under any circumstances, attempt to 'quickscope' with this rifle.")

/obj/item/gun/ballistic/rifle/sniper_rifle/Initialize(mapload)
	. = ..()
	AddComponent(/datum/component/scope, range_modifier = 4) //enough range to at least make extremely good use of the penetrator rounds

/obj/item/gun/ballistic/rifle/sniper_rifle/reset_semicd()
	. = ..()
	if(suppressed)
		playsound(src, 'sound/machines/eject.ogg', 25, TRUE, ignore_walls = FALSE, extrarange = SILENCED_SOUND_EXTRARANGE, falloff_distance = 0)
	else
		playsound(src, 'sound/machines/eject.ogg', 50, TRUE)

/obj/item/gun/ballistic/rifle/sniper_rifle/syndicate
	desc = "A boltaction anti-materiel rifle, utilizing .50 BMG cartridges. While technically outdated in modern arms markets, it still works exceptionally well as \
		an anti-personnel rifle. In particular, the employment of modern armored MODsuits utilizing advanced armor plating has given this weapon a new home on the battlefield. \
		It is also able to be suppressed....somehow. This one seems to have a little picture of someone in a blood-red MODsuit stenciled on it, pointing at a green floppy disk. \
		Who knows what that might mean."
	pin = /obj/item/firing_pin/implant/pindicate
