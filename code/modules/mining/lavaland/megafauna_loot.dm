//This file contains all Lavaland megafauna loot. Does not include crusher trophies.


//Hierophant: Hierophant Club

#define HIEROPHANT_BLINK_RANGE 5
#define HIEROPHANT_BLINK_COOLDOWN (15 SECONDS)

/datum/action/innate/dash/hierophant
	current_charges = 1
	max_charges = 1
	charge_rate = HIEROPHANT_BLINK_COOLDOWN
	recharge_sound = null
	phasein = /obj/effect/temp_visual/hierophant/blast/visual
	phaseout = /obj/effect/temp_visual/hierophant/blast/visual
	// It's a simple purple beam, works well enough for the purple hiero effects.
	beam_effect = "plasmabeam"

/datum/action/innate/dash/hierophant/teleport(mob/user, atom/target)
	var/dist = get_dist(user, target)
	if(dist > HIEROPHANT_BLINK_RANGE)
		user.balloon_alert(user, "destination out of range!")
		return FALSE
	var/turf/target_turf = get_turf(target)
	if(target_turf.is_blocked_turf_ignore_climbable())
		user.balloon_alert(user, "destination blocked!")
		return FALSE

	. = ..()
	var/obj/item/hierophant_club/club = target
	if(!istype(club))
		return

	club.update_appearance(UPDATE_ICON_STATE)

/datum/action/innate/dash/hierophant/charge()
	. = ..()
	var/obj/item/hierophant_club/club = target
	if(!istype(club))
		return

	club.update_appearance(UPDATE_ICON_STATE)

/obj/item/hierophant_club
	name = "hierophant club"
	desc = "The strange technology of this large club allows various nigh-magical teleportation feats. It used to beat you, but now you can set the beat."
	icon_state = "hierophant_club_ready_beacon"
	inhand_icon_state = "hierophant_club_ready_beacon"
	icon_angle = -135
	icon = 'icons/obj/mining_zones/artefacts.dmi'
	lefthand_file = 'icons/mob/inhands/64x64_lefthand.dmi'
	righthand_file = 'icons/mob/inhands/64x64_righthand.dmi'
	inhand_x_dimension = 64
	inhand_y_dimension = 64
	slot_flags = ITEM_SLOT_BACK
	w_class = WEIGHT_CLASS_NORMAL
	force = 15
	attack_verb_continuous = list("clubs", "beats", "pummels")
	attack_verb_simple = list("club", "beat", "pummel")
	hitsound = 'sound/items/weapons/sonic_jackhammer.ogg'
	resistance_flags = LAVA_PROOF | FIRE_PROOF | ACID_PROOF
	actions_types = list(/datum/action/item_action/vortex_recall)
	/// Linked teleport beacon for the group teleport functionality.
	var/obj/effect/hierophant/beacon
	/// TRUE if currently doing a teleport to the beacon, FALSE otherwise.
	var/teleporting = FALSE //if we ARE teleporting
	/// Action enabling the blink-dash functionality.
	var/datum/action/innate/dash/hierophant/blink
	/// Whether the blink ability is activated. IF TRUE, left clicking a location will blink to it. If FALSE, this is disabled.
	var/blink_activated = TRUE

/obj/item/hierophant_club/Initialize(mapload)
	. = ..()
	AddElement(/datum/element/update_icon_updates_onmob)
	blink = new(src)

/obj/item/hierophant_club/Destroy()
	QDEL_NULL(blink)
	return ..()

/obj/item/hierophant_club/examine(mob/user)
	. = ..()
	. += span_hierophant_warning("The[beacon ? " beacon is not currently":"re is a beacon"] attached.")

/obj/item/hierophant_club/suicide_act(mob/living/user)
	say("Xverwpsgexmrk...", forced = "hierophant club suicide")
	user.visible_message(span_suicide("[user] holds [src] into the air! It looks like [user.p_theyre()] trying to commit suicide!"))
	new/obj/effect/temp_visual/hierophant/telegraph(get_turf(user))
	playsound(user,'sound/machines/airlock/airlockopen.ogg', 75, TRUE)
	user.visible_message(span_hierophant_warning("[user] fades out, leaving [user.p_their()] belongings behind!"))
	for(var/obj/item/user_item in user)
		if(user_item != src)
			user.dropItemToGround(user_item)
	for(var/turf/blast_turf in RANGE_TURFS(1, user))
		new /obj/effect/temp_visual/hierophant/blast/visual(blast_turf, user, TRUE)
	user.dropItemToGround(src) //Drop us last, so it goes on top of their stuff
	qdel(user)

/obj/item/hierophant_club/attack_self(mob/user)
	blink_activated = !blink_activated
	to_chat(user, span_notice("You [blink_activated ? "enable" : "disable"] the blink function on [src]."))

/obj/item/hierophant_club/interact_with_atom(atom/interacting_with, mob/living/user, list/modifiers)
	// If our target is the beacon and the hierostaff is next to the beacon, we're trying to pick it up.
	if(interacting_with == beacon)
		return NONE
	if(blink_activated)
		blink.teleport(user, interacting_with)
		return ITEM_INTERACT_SUCCESS
	return NONE

/obj/item/hierophant_club/ranged_interact_with_atom(atom/interacting_with, mob/living/user, list/modifiers)
	if(blink_activated)
		blink.teleport(user, interacting_with)
		return ITEM_INTERACT_SUCCESS
	return NONE

/obj/item/hierophant_club/update_icon_state()
	icon_state = inhand_icon_state = "hierophant_club[blink?.current_charges > 0 ? "_ready":""][(!QDELETED(beacon)) ? "":"_beacon"]"
	return ..()

/obj/item/hierophant_club/ui_action_click(mob/user, action)
	if(!user.is_holding(src)) //you need to hold the staff to teleport
		to_chat(user, span_warning("You need to hold the club in your hands to [beacon ? "teleport with it":"detach the beacon"]!"))
		return
	if(!beacon || QDELETED(beacon))
		if(isturf(user.loc))
			user.visible_message(span_hierophant_warning("[user] starts fiddling with [src]'s pommel..."), \
			span_notice("You start detaching the hierophant beacon..."))
			if(do_after(user, 5 SECONDS, target = user) && !beacon)
				var/turf/user_turf = get_turf(user)
				playsound(user_turf,'sound/effects/magic/blind.ogg', 200, TRUE, -4)
				new /obj/effect/temp_visual/hierophant/telegraph/teleport(user_turf, user)
				beacon = new/obj/effect/hierophant(user_turf)
				user.update_mob_action_buttons()
				user.visible_message(span_hierophant_warning("[user] places a strange machine beneath [user.p_their()] feet!"), \
				"[span_hierophant("You detach the hierophant beacon, allowing you to teleport yourself and any allies to it at any time!")]\n\
				[span_notice("You can remove the beacon to place it again by striking it with the club.")]")
				update_appearance(UPDATE_ICON_STATE)
		else
			to_chat(user, span_warning("You need to be on solid ground to detach the beacon!"))
		return
	if(get_dist(user, beacon) <= 2) //beacon too close abort
		to_chat(user, span_warning("You are too close to the beacon to teleport to it!"))
		return
	var/turf/beacon_turf = get_turf(beacon)
	if(beacon_turf?.is_blocked_turf(TRUE))
		to_chat(user, span_warning("The beacon is blocked by something, preventing teleportation!"))
		return
	if(!isturf(user.loc))
		to_chat(user, span_warning("You don't have enough space to teleport from here!"))
		return
	teleporting = TRUE //start channel
	user.update_mob_action_buttons()
	user.visible_message(span_hierophant_warning("[user] starts to glow faintly..."))
	beacon.icon_state = "hierophant_tele_on"
	var/obj/effect/temp_visual/hierophant/telegraph/edge/user_telegraph = new /obj/effect/temp_visual/hierophant/telegraph/edge(user.loc)
	var/obj/effect/temp_visual/hierophant/telegraph/edge/beacon_telegraph = new /obj/effect/temp_visual/hierophant/telegraph/edge(beacon.loc)
	if(do_after(user, 4 SECONDS, target = user) && user && beacon)
		var/turf/destination = get_turf(beacon)
		var/turf/source = get_turf(user)
		if(destination.is_blocked_turf(TRUE))
			teleporting = FALSE
			to_chat(user, span_warning("The beacon is blocked by something, preventing teleportation!"))
			user.update_mob_action_buttons()
			beacon.icon_state = "hierophant_tele_off"
			return
		new /obj/effect/temp_visual/hierophant/telegraph(destination, user)
		new /obj/effect/temp_visual/hierophant/telegraph(source, user)
		playsound(destination,'sound/effects/magic/wand_teleport.ogg', 200, TRUE)
		playsound(source,'sound/machines/airlock/airlockopen.ogg', 200, TRUE)
		if(!do_after(user, 0.3 SECONDS, target = user) || !user || !beacon || QDELETED(beacon)) //no walking away shitlord
			teleporting = FALSE
			if(user)
				user.update_mob_action_buttons()
			if(beacon)
				beacon.icon_state = "hierophant_tele_off"
			return
		if(destination.is_blocked_turf(TRUE))
			teleporting = FALSE
			to_chat(user, span_warning("The beacon is blocked by something, preventing teleportation!"))
			user.update_mob_action_buttons()
			beacon.icon_state = "hierophant_tele_off"
			return
		user.log_message("teleported self from [AREACOORD(source)] to [beacon].", LOG_GAME)
		new /obj/effect/temp_visual/hierophant/telegraph/teleport(destination, user)
		new /obj/effect/temp_visual/hierophant/telegraph/teleport(source, user)
		for(var/turf_near_beacon in RANGE_TURFS(1, destination))
			new /obj/effect/temp_visual/hierophant/blast/visual(turf_near_beacon, user, TRUE)
		for(var/turf_near_source in RANGE_TURFS(1, source))
			new /obj/effect/temp_visual/hierophant/blast/visual(turf_near_source, user, TRUE)
		for(var/mob/living/mob_to_teleport in range(1, source))
			INVOKE_ASYNC(src, PROC_REF(teleport_mob), source, mob_to_teleport, destination, user)
		sleep(0.6 SECONDS) //at this point the blasts detonate
		if(beacon)
			beacon.icon_state = "hierophant_tele_off"
	else
		qdel(user_telegraph)
		qdel(beacon_telegraph)
	if(beacon)
		beacon.icon_state = "hierophant_tele_off"
	teleporting = FALSE
	if(user)
		user.update_mob_action_buttons()

/obj/item/hierophant_club/proc/teleport_mob(turf/source, mob/teleporting, turf/target, mob/user)
	var/turf/turf_to_teleport_to = get_step(target, get_dir(source, teleporting)) //get position relative to caster
	if(!turf_to_teleport_to || turf_to_teleport_to.is_blocked_turf(TRUE))
		return
	animate(teleporting, alpha = 0, time = 2, easing = EASE_OUT) //fade out
	sleep(0.1 SECONDS)
	if(!teleporting)
		return
	teleporting.visible_message(span_hierophant_warning("[teleporting] fades out!"))
	sleep(0.2 SECONDS)
	if(!teleporting)
		return
	var/success = do_teleport(teleporting, turf_to_teleport_to, no_effects = TRUE, channel = TELEPORT_CHANNEL_MAGIC)
	sleep(0.1 SECONDS)
	if(!teleporting)
		return
	animate(teleporting, alpha = 255, time = 2, easing = EASE_IN) //fade IN
	sleep(0.1 SECONDS)
	if(!teleporting)
		return
	teleporting.visible_message(span_hierophant_warning("[teleporting] fades in!"))
	if(user != teleporting && success)
		log_combat(user, teleporting, "teleported", null, "from [AREACOORD(source)]")

/obj/item/hierophant_club/equipped(mob/user)
	. = ..()
	blink.Grant(user, src)
	user.update_icons()

/obj/item/hierophant_club/dropped(mob/user)
	. = ..()
	blink.Remove(user)
	user.update_icons()

#undef HIEROPHANT_BLINK_RANGE
#undef HIEROPHANT_BLINK_COOLDOWN

//Bubblegum: Mayhem in a Bottle, H.E.C.K. Suit, Soulscythe

/obj/item/mayhem
	name = "mayhem in a bottle"
	desc = "A magically infused bottle of blood, the scent of which will drive anyone nearby into a murderous frenzy."
	icon = 'icons/obj/mining_zones/artefacts.dmi'
	icon_state = "vial"

/obj/item/mayhem/attack_self(mob/user)
	if(tgui_alert(user, "Breaking the bottle will cause nearby crewmembers to go into a murderous frenzy. Be sure you know what you are doing...","Break the bottle?",list("Break it!","DON'T")) != "Break it!")
		return
	if(QDELETED(src) || !user.is_holding(src) || user.incapacitated)
		return
	for(var/mob/living/carbon/human/target in range(7,user))
		target.apply_status_effect(/datum/status_effect/mayhem)
	to_chat(user, span_notice("You shatter the bottle!"))
	playsound(user.loc, 'sound/effects/glass/glassbr1.ogg', 100, TRUE)
	message_admins(span_adminnotice("[ADMIN_LOOKUPFLW(user)] has activated a bottle of mayhem!"))
	user.log_message("activated a bottle of mayhem", LOG_ATTACK)
	qdel(src)

/obj/item/clothing/suit/hooded/hostile_environment
	name = "H.E.C.K. suit"
	desc = "Hostile Environment Cross-Kinetic Suit: A suit designed to withstand the wide variety of hazards from Lavaland. It wasn't enough for its last owner."
	icon_state = "hostile_env"
	hoodtype = /obj/item/clothing/head/hooded/hostile_environment
	armor_type = /datum/armor/hooded_hostile_environment
	cold_protection = CHEST|GROIN|LEGS|FEET|ARMS|HANDS
	min_cold_protection_temperature = FIRE_SUIT_MIN_TEMP_PROTECT
	heat_protection = CHEST|GROIN|LEGS|FEET|ARMS|HANDS
	max_heat_protection_temperature = FIRE_IMMUNITY_MAX_TEMP_PROTECT
	body_parts_covered = CHEST|GROIN|LEGS|FEET|ARMS|HANDS
	clothing_flags = THICKMATERIAL|HEADINTERNALS
	resistance_flags = FIRE_PROOF|LAVA_PROOF|ACID_PROOF
	transparent_protection = HIDESUITSTORAGE|HIDEJUMPSUIT
	allowed = null
	greyscale_colors = "#4d4d4d#808080"
	greyscale_config = /datum/greyscale_config/heck_suit
	greyscale_config_worn = /datum/greyscale_config/heck_suit/worn
	flags_1 = IS_PLAYER_COLORABLE_1

/datum/armor/hooded_hostile_environment
	melee = 70
	bullet = 40
	laser = 10
	energy = 20
	bomb = 50
	fire = 100
	acid = 100

/obj/item/clothing/suit/hooded/hostile_environment/Initialize(mapload)
	. = ..()
	AddElement(/datum/element/radiation_protected_clothing)
	AddElement(/datum/element/gags_recolorable)
	allowed = GLOB.mining_suit_allowed

/obj/item/clothing/suit/hooded/hostile_environment/process(seconds_per_tick)
	var/mob/living/carbon/wearer = loc
	if(istype(wearer) && SPT_PROB(1, seconds_per_tick)) //cursed by bubblegum
		if(prob(7.5))
			wearer.cause_hallucination(/datum/hallucination/oh_yeah, "H.E.C.K suit", haunt_them = TRUE)
		else
			if(HAS_TRAIT(wearer, TRAIT_ANOSMIA)) //Anosmia quirk holder cannot fell any smell
				to_chat(wearer, span_warning("[pick("You hear faint whispers.","You feel hot.","You hear a roar in the distance.")]"))
			else
				to_chat(wearer, span_warning("[pick("You hear faint whispers.","You smell ash.","You feel hot.","You hear a roar in the distance.")]"))

/obj/item/clothing/head/hooded/hostile_environment
	name = "H.E.C.K. helmet"
	icon = 'icons/obj/clothing/head/helmet.dmi'
	worn_icon = 'icons/mob/clothing/head/helmet.dmi'
	desc = "Hostile Environment Cross-Kinetic Helmet: A helmet designed to withstand the wide variety of hazards from Lavaland. It wasn't enough for its last owner."
	icon_state = "hostile_env"
	w_class = WEIGHT_CLASS_NORMAL
	armor_type = /datum/armor/hooded_hostile_environment
	cold_protection = HEAD
	min_cold_protection_temperature = FIRE_SUIT_MIN_TEMP_PROTECT
	heat_protection = HEAD
	max_heat_protection_temperature = FIRE_IMMUNITY_MAX_TEMP_PROTECT
	clothing_flags = SNUG_FIT|THICKMATERIAL
	resistance_flags = FIRE_PROOF|LAVA_PROOF|ACID_PROOF
	flags_inv = HIDEMASK|HIDEEARS|HIDEFACE|HIDEEYES|HIDEHAIR|HIDEFACIALHAIR|HIDESNOUT
	flags_cover = HEADCOVERSMOUTH
	actions_types = list()
	greyscale_colors = "#4d4d4d#808080#ff3300"
	greyscale_config = /datum/greyscale_config/heck_helmet
	greyscale_config_worn = /datum/greyscale_config/heck_helmet/worn
	flags_1 = IS_PLAYER_COLORABLE_1

/obj/item/clothing/head/hooded/hostile_environment/Initialize(mapload)
	. = ..()
	update_appearance()
	AddComponent(/datum/component/butchering/wearable, \
	speed = 0.5 SECONDS, \
	effectiveness = 150, \
	bonus_modifier = 0, \
	butcher_sound = null, \
	disabled = null, \
	can_be_blunt = TRUE, \
	butcher_callback = CALLBACK(src, PROC_REF(consume)), \
	)
	AddElement(/datum/element/radiation_protected_clothing)
	AddElement(/datum/element/gags_recolorable)

/obj/item/clothing/head/hooded/hostile_environment/equipped(mob/user, slot, initial = FALSE)
	. = ..()
	to_chat(user, span_notice("You feel a bloodlust. You can now butcher corpses with your bare arms."))

/obj/item/clothing/head/hooded/hostile_environment/dropped(mob/user, silent = FALSE)
	. = ..()
	to_chat(user, span_notice("You lose your bloodlust."))

/obj/item/clothing/head/hooded/hostile_environment/proc/consume(mob/living/user, mob/living/butchered)
	if(butchered.mob_biotypes & (MOB_ROBOTIC | MOB_SPIRIT))
		return
	var/health_consumed = butchered.maxHealth * 0.1
	user.heal_ordered_damage(health_consumed, list(BRUTE, BURN, TOX))
	to_chat(user, span_notice("You heal from the corpse of [butchered]."))
	var/datum/client_colour/color = user.add_client_colour(/datum/client_colour/bloodlust)
	QDEL_IN(color, 1 SECONDS)

#define MAX_BLOOD_LEVEL 100

/obj/item/soulscythe
	name = "soulscythe"
	desc = "An old relic of hell created by devils to establish themselves as the leadership of hell over the demons. It grows stronger while it possesses a powerful soul."
	icon = 'icons/obj/mining_zones/artefacts.dmi'
	icon_state = "soulscythe"
	inhand_icon_state = "soulscythe"
	lefthand_file = 'icons/mob/inhands/64x64_lefthand.dmi'
	righthand_file = 'icons/mob/inhands/64x64_righthand.dmi'
	attack_verb_continuous = list("chops", "slices", "cuts", "reaps")
	attack_verb_simple = list("chop", "slice", "cut", "reap")
	hitsound = 'sound/items/weapons/bladeslice.ogg'
	inhand_x_dimension = 64
	inhand_y_dimension = 64
	force = 20
	throwforce = 17
	armour_penetration = 50
	sharpness = SHARP_EDGED
	bare_wound_bonus = 10
	layer = MOB_LAYER
	resistance_flags = LAVA_PROOF | FIRE_PROOF | ACID_PROOF
	/// Soulscythe mob in the scythe
	var/mob/living/simple_animal/soulscythe/soul
	/// Are we grabbing a spirit?
	var/using = FALSE
	/// Currently charging?
	var/charging = FALSE
	/// Cooldown between moves
	COOLDOWN_DECLARE(move_cooldown)
	/// Cooldown between attacks
	COOLDOWN_DECLARE(attack_cooldown)

/obj/item/soulscythe/Initialize(mapload)
	. = ..()
	soul = new(src)
	RegisterSignal(soul, COMSIG_LIVING_RESIST, PROC_REF(on_resist))
	RegisterSignal(soul, COMSIG_MOB_ATTACK_RANGED, PROC_REF(on_attack))
	RegisterSignal(soul, COMSIG_MOB_ATTACK_RANGED_SECONDARY, PROC_REF(on_secondary_attack))
	RegisterSignal(src, COMSIG_ATOM_INTEGRITY_CHANGED, PROC_REF(on_integrity_change))
	AddElement(/datum/element/bane, mob_biotypes = MOB_PLANT, damage_multiplier = 0.5, requires_combat_mode = FALSE)

/obj/item/soulscythe/examine(mob/user)
	. = ..()
	. += soul.ckey ? span_nicegreen("There is a soul inhabiting it.") : span_danger("It's dormant.")

/obj/item/soulscythe/attack(mob/living/attacked, mob/living/user, params)
	. = ..()
	if(attacked.stat != DEAD)
		give_blood(10)

/obj/item/soulscythe/attack_hand(mob/user, list/modifiers)
	if(soul.ckey && !soul.faction_check_atom(user))
		to_chat(user, span_warning("You can't pick up [src]!"))
		return
	return ..()

/obj/item/soulscythe/pickup(mob/user)
	. = ..()
	if(soul.ckey)
		animate(src) //stop spinnage

/obj/item/soulscythe/dropped(mob/user, silent)
	. = ..()
	if(soul.ckey)
		reset_spin() //resume spinnage

/obj/item/soulscythe/attack_self(mob/user, modifiers)
	if(using || soul.ckey || soul.stat)
		return
	if(!(GLOB.ghost_role_flags & GHOSTROLE_STATION_SENTIENCE))
		balloon_alert(user, "you can't awaken the scythe!")
		return
	using = TRUE
	balloon_alert(user, "you hold the scythe up...")
	ADD_TRAIT(src, TRAIT_NODROP, type)
	var/mob/chosen_one = SSpolling.poll_ghosts_for_target(
		check_jobban = ROLE_PAI,
		poll_time = 20 SECONDS,
		checked_target = src,
		ignore_category = POLL_IGNORE_POSSESSED_BLADE,
		alert_pic = src,
		role_name_text = "soulscythe soul",
		chat_text_border_icon = src,
	)
	on_poll_concluded(user, chosen_one)

/// Ghost poll has concluded and a candidate has been chosen.
/obj/item/soulscythe/proc/on_poll_concluded(mob/living/master, mob/dead/observer/ghost)
	if(isnull(ghost))
		balloon_alert(master, "the scythe is dormant!")
		REMOVE_TRAIT(src, TRAIT_NODROP, type)
		using = FALSE
		return

	soul.ckey = ghost.ckey
	soul.copy_languages(master, LANGUAGE_MASTER) //Make sure the sword can understand and communicate with the master.
	soul.faction = list("[REF(master)]")
	balloon_alert(master, "the scythe glows")
	add_overlay("soulscythe_gem")
	density = TRUE
	if(!ismob(loc))
		reset_spin()

	REMOVE_TRAIT(src, TRAIT_NODROP, type)
	using = FALSE

/obj/item/soulscythe/relaymove(mob/living/user, direction)
	if(!COOLDOWN_FINISHED(src, move_cooldown) || charging)
		return
	if(!isturf(loc))
		balloon_alert(user, "resist out!")
		COOLDOWN_START(src, move_cooldown, 1 SECONDS)
		return
	if(!use_blood(1, FALSE))
		return
	if(pixel_x != base_pixel_x || pixel_y != base_pixel_y)
		animate(src, 0.2 SECONDS, pixel_x = base_pixel_y, pixel_y = base_pixel_y, flags = ANIMATION_PARALLEL)
	try_step_multiz(direction)
	COOLDOWN_START(src, move_cooldown, (direction in GLOB.cardinals) ? 0.1 SECONDS : 0.2 SECONDS)

/obj/item/soulscythe/throw_impact(atom/hit_atom, datum/thrownthing/throwingdatum)
	. = ..()
	if(!charging)
		return
	charging = FALSE
	throwforce *= 0.5
	reset_spin()
	if(ismineralturf(hit_atom))
		var/turf/closed/mineral/hit_rock = hit_atom
		hit_rock.gets_drilled()
	if(isliving(hit_atom))
		var/mob/living/hit_mob = hit_atom
		if(hit_mob.stat != DEAD)
			give_blood(15)

/obj/item/soulscythe/AllowClick()
	return TRUE

/obj/item/soulscythe/proc/use_blood(amount = 0, message = TRUE)
	if(amount > soul.blood_level)
		if(message)
			to_chat(soul, span_warning("Not enough blood!"))
		return FALSE
	soul.blood_level -= amount
	return TRUE

/obj/item/soulscythe/proc/give_blood(amount)
	soul.blood_level = min(MAX_BLOOD_LEVEL, soul.blood_level + amount)

/obj/item/soulscythe/proc/on_resist(mob/living/user)
	SIGNAL_HANDLER

	if(isturf(loc))
		return
	INVOKE_ASYNC(src, PROC_REF(break_out))

/obj/item/soulscythe/proc/break_out()
	if(!use_blood(10))
		return
	balloon_alert(soul, "you resist...")
	if(!do_after(soul, 5 SECONDS, target = src, timed_action_flags = IGNORE_TARGET_LOC_CHANGE))
		balloon_alert(soul, "interrupted!")
		return
	balloon_alert(soul, "you break out")
	if(ismob(loc))
		var/mob/holder = loc
		holder.temporarilyRemoveItemFromInventory(src)
	forceMove(drop_location())

/obj/item/soulscythe/proc/on_integrity_change(datum/source, old_value, new_value)
	SIGNAL_HANDLER

	soul.set_health(new_value)

/obj/item/soulscythe/proc/on_attack(mob/living/source, atom/attacked_atom, modifiers)
	SIGNAL_HANDLER

	if(!COOLDOWN_FINISHED(src, attack_cooldown) || !isturf(loc))
		return
	if(get_dist(source, attacked_atom) > 1)
		INVOKE_ASYNC(src, PROC_REF(shoot_target), attacked_atom)
	else
		INVOKE_ASYNC(src, PROC_REF(slash_target), attacked_atom)

/obj/item/soulscythe/proc/on_secondary_attack(mob/living/source, atom/attacked_atom, modifiers)
	SIGNAL_HANDLER

	if(!COOLDOWN_FINISHED(src, attack_cooldown) || !isturf(loc))
		return
	INVOKE_ASYNC(src, PROC_REF(charge_target), attacked_atom)

/obj/item/soulscythe/proc/shoot_target(atom/attacked_atom)
	if(!use_blood(15))
		return
	COOLDOWN_START(src, attack_cooldown, 3 SECONDS)
	var/obj/projectile/projectile = new /obj/projectile/soulscythe(get_turf(src))
	projectile.aim_projectile(attacked_atom, src)
	projectile.firer = src
	projectile.fire(null, attacked_atom)
	visible_message(span_danger("[src] fires at [attacked_atom]!"), span_notice("You fire at [attacked_atom]!"))
	playsound(src, 'sound/effects/magic/fireball.ogg', 50, TRUE)

/obj/item/soulscythe/proc/slash_target(atom/attacked_atom)
	if(isliving(attacked_atom) && use_blood(10))
		var/mob/living/attacked_mob = attacked_atom
		if(attacked_mob.stat != DEAD)
			give_blood(15)
		attacked_mob.apply_damage(damage = force * (ishostile(attacked_mob) ? 2 : 1), sharpness = SHARP_EDGED, bare_wound_bonus = 5)
		to_chat(attacked_mob, span_userdanger("You're slashed by [src]!"))
	else if((ismachinery(attacked_atom) || isstructure(attacked_atom)) && use_blood(5))
		var/obj/attacked_obj = attacked_atom
		attacked_obj.take_damage(force, BRUTE, MELEE, FALSE)
	else
		return
	COOLDOWN_START(src, attack_cooldown, 1 SECONDS)
	animate(src)
	SpinAnimation(5)
	addtimer(CALLBACK(src, PROC_REF(reset_spin)), 1 SECONDS)
	visible_message(span_danger("[src] slashes [attacked_atom]!"), span_notice("You slash [attacked_atom]!"))
	playsound(src, 'sound/items/weapons/bladeslice.ogg', 50, TRUE)
	do_attack_animation(attacked_atom, ATTACK_EFFECT_SLASH)

/obj/item/soulscythe/proc/charge_target(atom/attacked_atom)
	if(charging || !use_blood(30))
		return
	COOLDOWN_START(src, attack_cooldown, 5 SECONDS)
	animate(src)
	charging = TRUE
	visible_message(span_danger("[src] starts charging..."))
	balloon_alert(soul, "you start charging...")
	if(!do_after(soul, 2 SECONDS, target = src, timed_action_flags = IGNORE_TARGET_LOC_CHANGE))
		balloon_alert(soul, "interrupted!")
		return
	visible_message(span_danger("[src] charges at [attacked_atom]!"), span_notice("You charge at [attacked_atom]!"))
	new /obj/effect/temp_visual/mook_dust(get_turf(src))
	playsound(src, 'sound/items/weapons/thudswoosh.ogg', 50, TRUE)
	SpinAnimation(1)
	throwforce *= 2
	throw_at(attacked_atom, 10, 3, soul, FALSE)

/obj/item/soulscythe/proc/reset_spin()
	animate(src)
	SpinAnimation(15)

/obj/item/soulscythe/Destroy(force)
	soul.ghostize()
	QDEL_NULL(soul)
	. = ..()
/mob/living/simple_animal/soulscythe
	name = "mysterious spirit"
	maxHealth = 200
	health = 200
	gender = NEUTER
	mob_biotypes = MOB_SPIRIT
	faction = list()
	weather_immunities = list(TRAIT_ASHSTORM_IMMUNE, TRAIT_SNOWSTORM_IMMUNE)
	/// Blood level, used for movement and abilities in a soulscythe
	var/blood_level = MAX_BLOOD_LEVEL

/mob/living/simple_animal/soulscythe/get_status_tab_items()
	. = ..()
	. += "Blood: [blood_level]/[MAX_BLOOD_LEVEL]"

/mob/living/simple_animal/soulscythe/Life(seconds_per_tick, times_fired)
	. = ..()
	if(!stat)
		blood_level = min(MAX_BLOOD_LEVEL, blood_level + round(1 * seconds_per_tick))

/obj/projectile/soulscythe
	name = "soulslash"
	icon_state = "soulslash"
	armor_flag = MELEE //jokair
	damage = 15
	light_range = 1
	light_power = 1
	light_color = LIGHT_COLOR_BLOOD_MAGIC

/obj/projectile/soulscythe/on_hit(atom/target, blocked = 0, pierce_hit)
	if(ishostile(target))
		damage *= 2
	return ..()

#undef MAX_BLOOD_LEVEL

//Ash Drake: Spectral Blade, Lava Staff, Dragon's Blood

/obj/item/melee/ghost_sword
	name = "\improper spectral blade"
	desc = "A rusted and dulled blade. It doesn't look like it'd do much damage. It glows weakly."
	icon = 'icons/obj/weapons/sword.dmi'
	icon_state = "spectral"
	inhand_icon_state = "spectral"
	icon_angle = -45
	lefthand_file = 'icons/mob/inhands/weapons/swords_lefthand.dmi'
	righthand_file = 'icons/mob/inhands/weapons/swords_righthand.dmi'
	obj_flags = CONDUCTS_ELECTRICITY
	sharpness = SHARP_EDGED
	w_class = WEIGHT_CLASS_BULKY
	force = 1
	throwforce = 1
	hitsound = 'sound/effects/ghost2.ogg'
	block_sound = 'sound/items/weapons/parry.ogg'
	attack_verb_continuous = list("attacks", "slashes", "slices", "tears", "lacerates", "rips", "dices", "rends")
	attack_verb_simple = list("attack", "slash", "slice", "tear", "lacerate", "rip", "dice", "rend")
	resistance_flags = LAVA_PROOF | FIRE_PROOF | ACID_PROOF
	var/summon_cooldown = 0
	var/list/mob/dead/observer/spirits
	var/list/alt_continuous = list("stabs", "pierces", "impales")
	var/list/alt_simple = list("stab", "pierce", "impale")

/obj/item/melee/ghost_sword/Initialize(mapload)
	. = ..()
	spirits = list()
	START_PROCESSING(SSobj, src)
	SSpoints_of_interest.make_point_of_interest(src)
	alt_continuous = string_list(alt_continuous)
	alt_simple = string_list(alt_simple)
	AddComponent(/datum/component/alternative_sharpness, SHARP_POINTY, alt_continuous, alt_simple)
	AddComponent(\
		/datum/component/butchering, \
		speed = 15 SECONDS, \
		effectiveness = 90, \
	)

/obj/item/melee/ghost_sword/Destroy()
	for(var/mob/dead/observer/G in spirits)
		G.RemoveInvisibility(type)
	spirits.Cut()
	STOP_PROCESSING(SSobj, src)
	. = ..()

/obj/item/melee/ghost_sword/attack_self(mob/user)
	if(summon_cooldown > world.time)
		to_chat(user, span_warning("You just recently called out for aid. You don't want to annoy the spirits!"))
		return
	to_chat(user, span_notice("You call out for aid, attempting to summon spirits to your side."))

	notify_ghosts(
		"[user] is raising [user.p_their()] [name], calling for your help!",
		source = user,
		ignore_key = POLL_IGNORE_SPECTRAL_BLADE,
		header = "Spectral blade",
	)

	summon_cooldown = world.time + 600

/obj/item/melee/ghost_sword/process()
	ghost_check()

/obj/item/melee/ghost_sword/proc/ghost_check()
	var/ghost_counter = 0
	var/turf/T = get_turf(src)
	var/list/contents = T.get_all_contents()
	var/mob/dead/observer/current_spirits = list()
	for(var/thing in contents)
		var/atom/A = thing
		A.transfer_observers_to(src)
	for(var/i in orbiters?.orbiter_list)
		if(!isobserver(i))
			continue
		var/mob/dead/observer/G = i
		ghost_counter++
		G.SetInvisibility(INVISIBILITY_NONE, id=type, priority=INVISIBILITY_PRIORITY_BASIC_ANTI_INVISIBILITY)
		current_spirits |= G
	for(var/mob/dead/observer/G in spirits - current_spirits)
		G.RemoveInvisibility(type)
	spirits = current_spirits
	return ghost_counter

/obj/item/melee/ghost_sword/attack(mob/living/target, mob/living/carbon/human/user)
	force = 0
	var/ghost_counter = ghost_check()
	force = clamp((ghost_counter * 4), 0, 75)
	user.visible_message(span_danger("[user] strikes with the force of [ghost_counter] vengeful spirits!"))
	..()

/obj/item/melee/ghost_sword/hit_reaction(mob/living/carbon/human/owner, atom/movable/hitby, attack_text = "the attack", final_block_chance = 0, damage = 0, attack_type = MELEE_ATTACK, damage_type = BRUTE)
	var/ghost_counter = ghost_check()
	final_block_chance += clamp((ghost_counter * 5), 0, 75)
	owner.visible_message(span_danger("[owner] is protected by a ring of [ghost_counter] ghosts!"))
	return ..()

/obj/item/dragons_blood
	name = "bottle of dragons blood"
	desc = "You're not actually going to drink this, are you?"
	icon = 'icons/obj/mining_zones/artefacts.dmi'
	icon_state = "vial"

/obj/item/dragons_blood/attack_self(mob/living/carbon/human/user)
	if(!istype(user))
		return

	var/mob/living/carbon/human/consumer = user
	var/random = rand(1,4)

	switch(random)
		if(1)
			to_chat(user, span_danger("Your appearance morphs to that of a very small humanoid ash dragon! You get to look like a freak without the cool abilities."))
			consumer.dna.features = list(
				"mcolor" = "#A02720",
				"tail_lizard" = "Dark Tiger",
				"tail_human" = "None",
				"snout" = "Sharp",
				"horns" = "Curled",
				"ears" = "None",
				"wings" = "None",
				"frills" = "None",
				"spines" = "Long",
				"lizard_markings" = "Dark Tiger Body",
				"legs" = DIGITIGRADE_LEGS,
			)
			consumer.eye_color_left = "#FEE5A3"
			consumer.eye_color_right = "#FEE5A3"
			consumer.set_species(/datum/species/lizard)
		if(2)
			to_chat(user, span_danger("Your flesh begins to melt! Miraculously, you seem fine otherwise."))
			consumer.set_species(/datum/species/skeleton)
		if(3)
			to_chat(user, span_danger("Power courses through you! You can now shift your form at will."))
			var/datum/action/cooldown/spell/shapeshift/dragon/dragon_shapeshift = new(user.mind || user)
			dragon_shapeshift.Grant(user)
		if(4)
			to_chat(user, span_danger("You feel like you could walk straight through lava now."))
			ADD_TRAIT(user, TRAIT_LAVA_IMMUNE, type)

	playsound(user,'sound/items/drink.ogg', 30, TRUE)
	qdel(src)

/obj/item/lava_staff
	name = "staff of lava"
	desc = "The ability to fill the emergency shuttle with lava. What more could you want out of life?"
	icon_state = "lavastaff"
	inhand_icon_state = "lavastaff"
	icon_angle = -45
	lefthand_file = 'icons/mob/inhands/weapons/staves_lefthand.dmi'
	righthand_file = 'icons/mob/inhands/weapons/staves_righthand.dmi'
	icon = 'icons/obj/weapons/guns/magic.dmi'
	slot_flags = ITEM_SLOT_BACK
	w_class = WEIGHT_CLASS_NORMAL
	force = 18
	damtype = BURN
	resistance_flags = LAVA_PROOF | FIRE_PROOF | ACID_PROOF
	attack_verb_continuous = list("sears", "clubs", "burn")
	attack_verb_simple = list("sear", "club", "burn")
	hitsound = 'sound/items/weapons/sear.ogg'
	var/turf_type = /turf/open/lava/smooth/weak
	var/transform_string = "lava"
	var/reset_turf_type = /turf/open/misc/asteroid/basalt
	var/reset_string = "basalt"
	var/create_cooldown = 10 SECONDS
	var/create_delay = 3 SECONDS
	var/reset_cooldown = 5 SECONDS
	var/timer = 0
	var/static/list/banned_turfs = typecacheof(list(/turf/open/space, /turf/closed))

/obj/item/lava_staff/interact_with_atom(atom/interacting_with, mob/living/user, list/modifiers)
	if(interacting_with.atom_storage || SHOULD_SKIP_INTERACTION(interacting_with, src, user))
		return NONE
	return ranged_interact_with_atom(interacting_with, user, modifiers)

/obj/item/lava_staff/ranged_interact_with_atom(atom/interacting_with, mob/living/user, list/modifiers)
	if(timer > world.time)
		return NONE
	if(is_type_in_typecache(interacting_with, banned_turfs))
		return NONE
	if(!(interacting_with in view(user.client.view, get_turf(user))))
		return NONE
	var/turf/open/T = get_turf(interacting_with)
	if(!istype(T))
		return NONE
	if(!islava(T))
		var/obj/effect/temp_visual/lavastaff/L = new /obj/effect/temp_visual/lavastaff(T)
		L.alpha = 0
		animate(L, alpha = 255, time = create_delay)
		user.visible_message(span_danger("[user] points [src] at [T]!"))
		timer = world.time + create_delay + 1
		if(do_after(user, create_delay, target = T))
			var/old_name = T.name
			if(T.TerraformTurf(turf_type, flags = CHANGETURF_INHERIT_AIR))
				user.visible_message(span_danger("[user] turns \the [old_name] into [transform_string]!"))
				message_admins("[ADMIN_LOOKUPFLW(user)] fired the lava staff at [ADMIN_VERBOSEJMP(T)]")
				user.log_message("fired the lava staff at [AREACOORD(T)].", LOG_ATTACK)
				timer = world.time + create_cooldown
				playsound(T,'sound/effects/magic/fireball.ogg', 200, TRUE)
		else
			timer = world.time
		qdel(L)
	else
		var/old_name = T.name
		if(T.TerraformTurf(reset_turf_type, flags = CHANGETURF_INHERIT_AIR))
			user.visible_message(span_danger("[user] turns \the [old_name] into [reset_string]!"))
			timer = world.time + reset_cooldown
			playsound(T,'sound/effects/magic/fireball.ogg', 200, TRUE)
	return ITEM_INTERACT_SUCCESS

/obj/effect/temp_visual/lavastaff
	icon_state = "lavastaff_warn"
	duration = 50

/turf/open/lava/smooth/weak
	lava_damage = 10
	lava_firestacks = 10
	temperature_damage = 2500

//Blood-Drunk Miner: Cleaving Saw


/obj/item/melee/cleaving_saw
	name = "cleaving saw"
	desc = "This saw, effective at drawing the blood of beasts, transforms into a long cleaver that makes use of centrifugal force."
	icon = 'icons/obj/mining_zones/artefacts.dmi'
	lefthand_file = 'icons/mob/inhands/64x64_lefthand.dmi'
	righthand_file = 'icons/mob/inhands/64x64_righthand.dmi'
	icon_state = "cleaving_saw"
	inhand_icon_state = "cleaving_saw"
	worn_icon_state = "cleaving_saw"
	attack_verb_continuous = list("attacks", "saws", "slices", "tears", "lacerates", "rips", "dices", "cuts")
	attack_verb_simple = list("attack", "saw", "slice", "tear", "lacerate", "rip", "dice", "cut")
	force = 12
	throwforce = 20
	inhand_x_dimension = 64
	inhand_y_dimension = 64
	slot_flags = ITEM_SLOT_BELT
	hitsound = 'sound/items/weapons/bladeslice.ogg'
	w_class = WEIGHT_CLASS_BULKY
	sharpness = SHARP_EDGED
	/// List of factions we deal bonus damage to
	var/list/nemesis_factions = list(FACTION_MINING, FACTION_BOSS)
	/// Amount of damage we deal to the above factions
	var/faction_bonus_force = 30
	/// Whether the cleaver is actively AoE swiping something.
	var/swiping = FALSE
	/// Amount of bleed stacks gained per hit
	var/bleed_stacks_per_hit = 3
	/// Force when the saw is opened.
	var/open_force = 20
	/// Throwforce when the saw is opened.
	var/open_throwforce = 20

/obj/item/melee/cleaving_saw/Initialize(mapload)
	. = ..()
	AddComponent( \
		/datum/component/transforming, \
		transform_cooldown_time = (CLICK_CD_MELEE * 0.25), \
		force_on = open_force, \
		throwforce_on = open_throwforce, \
		sharpness_on = sharpness, \
		hitsound_on = hitsound, \
		w_class_on = w_class, \
		attack_verb_continuous_on = list("cleaves", "swipes", "slashes", "chops"), \
		attack_verb_simple_on = list("cleave", "swipe", "slash", "chop"), \
	)
	RegisterSignal(src, COMSIG_TRANSFORMING_ON_TRANSFORM, PROC_REF(on_transform))

/obj/item/melee/cleaving_saw/examine(mob/user)
	. = ..()
	. += span_notice("It is [HAS_TRAIT(src, TRAIT_TRANSFORM_ACTIVE) ? "open, will cleave enemies in a wide arc and deal additional damage to fauna":"closed, and can be used for rapid consecutive attacks that cause fauna to bleed"].")
	. += span_notice("Both modes will build up existing bleed effects, doing a burst of high damage if the bleed is built up high enough.")
	. += span_notice("Transforming it immediately after an attack causes the next attack to come out faster.")

/obj/item/melee/cleaving_saw/suicide_act(mob/living/user)
	user.visible_message(span_suicide("[user] is [HAS_TRAIT(src, TRAIT_TRANSFORM_ACTIVE) ? "closing [src] on [user.p_their()] neck" : "opening [src] into [user.p_their()] chest"]! It looks like [user.p_theyre()] trying to commit suicide!"))
	attack_self(user)
	return BRUTELOSS

/obj/item/melee/cleaving_saw/melee_attack_chain(mob/user, atom/target, params)
	. = ..()
	if(!HAS_TRAIT(src, TRAIT_TRANSFORM_ACTIVE))
		user.changeNext_move(CLICK_CD_MELEE * 0.5) //when closed, it attacks very rapidly

/obj/item/melee/cleaving_saw/attack(mob/living/target, mob/living/carbon/human/user)
	var/is_open = HAS_TRAIT(src, TRAIT_TRANSFORM_ACTIVE)
	if(!is_open || swiping || !target.density || get_turf(target) == get_turf(user))
		if(!is_open)
			faction_bonus_force = 0
		var/is_nemesis_faction = FALSE
		for(var/found_faction in target.faction)
			if(found_faction in nemesis_factions)
				is_nemesis_faction = TRUE
				force += faction_bonus_force
				nemesis_effects(user, target)
				break
		. = ..()
		if(is_nemesis_faction)
			force -= faction_bonus_force
		if(!is_open)
			faction_bonus_force = initial(faction_bonus_force)
	else
		var/turf/user_turf = get_turf(user)
		var/dir_to_target = get_dir(user_turf, get_turf(target))
		swiping = TRUE
		var/static/list/cleaving_saw_cleave_angles = list(0, -45, 45) //so that the animation animates towards the target clicked and not towards a side target
		for(var/i in cleaving_saw_cleave_angles)
			var/turf/turf = get_step(user_turf, turn(dir_to_target, i))
			for(var/mob/living/living_target in turf)
				if(user.Adjacent(living_target) && living_target.body_position != LYING_DOWN)
					melee_attack_chain(user, living_target)
		swiping = FALSE

/*
 * If we're attacking [target]s in our nemesis list, apply unique effects.
 *
 * user - the mob attacking with the saw
 * target - the mob being attacked
 */
/obj/item/melee/cleaving_saw/proc/nemesis_effects(mob/living/user, mob/living/target)
	if(istype(target, /mob/living/simple_animal/hostile/asteroid/elite))
		return
	var/datum/status_effect/stacking/saw_bleed/existing_bleed = target.has_status_effect(/datum/status_effect/stacking/saw_bleed)
	if(existing_bleed)
		existing_bleed.add_stacks(bleed_stacks_per_hit)
	else
		target.apply_status_effect(/datum/status_effect/stacking/saw_bleed, bleed_stacks_per_hit)

/*
 * Signal proc for [COMSIG_TRANSFORMING_ON_TRANSFORM].
 *
 * Gives feedback and makes the nextmove after transforming much quicker.
 */
/obj/item/melee/cleaving_saw/proc/on_transform(obj/item/source, mob/user, active)
	SIGNAL_HANDLER

	user.changeNext_move(CLICK_CD_MELEE * 0.25)
	if(user)
		balloon_alert(user, "[active ? "opened" : "closed"] [src]")
	playsound(src, 'sound/effects/magic/clockwork/fellowship_armory.ogg', 35, TRUE, frequency = 90000 - (active * 30000))
	return COMPONENT_NO_DEFAULT_MESSAGE

//Legion: Staff of Storms

/obj/item/storm_staff
	name = "staff of storms"
	desc = "An ancient staff retrieved from the remains of Legion. The wind stirs as you move it."
	icon_state = "staffofstorms"
	inhand_icon_state = "staffofstorms"
	icon_angle = -45
	icon = 'icons/obj/weapons/guns/magic.dmi'
	lefthand_file = 'icons/mob/inhands/weapons/staves_lefthand.dmi'
	righthand_file = 'icons/mob/inhands/weapons/staves_righthand.dmi'
	slot_flags = ITEM_SLOT_BACK
	w_class = WEIGHT_CLASS_BULKY
	force = 20
	damtype = BURN
	hitsound = 'sound/items/weapons/taserhit.ogg'
	wound_bonus = -30
	bare_wound_bonus = 20
	resistance_flags = LAVA_PROOF | FIRE_PROOF | ACID_PROOF
	var/max_thunder_charges = 3
	var/thunder_charges = 3
	var/thunder_charge_time = 15 SECONDS
	var/static/list/excluded_areas = list(/area/space)
	var/list/targeted_turfs = list()

/obj/item/storm_staff/examine(mob/user)
	. = ..()
	. += span_notice("It has [thunder_charges] charges remaining.")
	. += span_notice("Use it in hand to dispel storms.")
	. += span_notice("Use it on targets to summon thunderbolts from the sky.")
	. += span_notice("The thunderbolts are boosted if in an area with weather effects.")

/obj/item/storm_staff/attack_self(mob/user)
	var/area/user_area = get_area(user)
	var/turf/user_turf = get_turf(user)
	if(!user_area || !user_turf || (is_type_in_list(user_area, excluded_areas)))
		to_chat(user, span_warning("Something is preventing you from using the staff here."))
		return
	var/datum/weather/affected_weather
	for(var/datum/weather/weather as anything in SSweather.processing)
		if((user_turf.z in weather.impacted_z_levels) && ispath(user_area.type, weather.area_type))
			affected_weather = weather
			break
	if(!affected_weather)
		return
	if(affected_weather.stage == END_STAGE)
		balloon_alert(user, "already ended!")
		return
	if(affected_weather.stage == WIND_DOWN_STAGE)
		balloon_alert(user, "already ending!")
		return
	balloon_alert(user, "you hold the staff up...")
	if(!do_after(user, 3 SECONDS, target = src))
		balloon_alert(user, "interrupted!")
		return
	user.visible_message(span_warning("[user] holds [src] skywards as an orange beam travels into the sky!"), \
	span_notice("You hold [src] skyward, dispelling the storm!"))
	playsound(user, 'sound/effects/magic/staff_change.ogg', 200, FALSE)
	var/old_color = user.color
	user.color = list(340/255, 240/255, 0,0, 0,0,0,0, 0,0,0,0, 0,0,0,1, 0,0,0,0)
	var/old_transform = user.transform
	user.transform *= 1.2
	animate(user, color = old_color, transform = old_transform, time = 1 SECONDS)
	affected_weather.wind_down()
	user.log_message("has dispelled a storm at [AREACOORD(user_turf)].", LOG_GAME)

/obj/item/storm_staff/ranged_interact_with_atom(atom/interacting_with, mob/living/user, list/modifiers)
	return thunder_blast(interacting_with, user) ? ITEM_INTERACT_SUCCESS : ITEM_INTERACT_BLOCKING

/obj/item/storm_staff/afterattack(atom/target, mob/user, click_parameters)
	thunder_blast(target, user)

/obj/item/storm_staff/proc/thunder_blast(atom/target, mob/user)
	if(!thunder_charges)
		balloon_alert(user, "needs to charge!")
		return FALSE
	var/turf/target_turf = get_turf(target)
	var/area/target_area = get_area(target)
	if(!target_turf || !target_area || (is_type_in_list(target_area, excluded_areas)))
		balloon_alert(user, "can't bolt here!")
		return FALSE
	if(target_turf in targeted_turfs)
		balloon_alert(user, "already targeted!")
		return FALSE
	if(HAS_TRAIT(user, TRAIT_PACIFISM))
		balloon_alert(user, "you don't want to harm!")
		return FALSE
	var/power_boosted = FALSE
	for(var/datum/weather/weather as anything in SSweather.processing)
		if(weather.stage != MAIN_STAGE)
			continue
		if((target_turf.z in weather.impacted_z_levels) && ispath(target_area.type, weather.area_type))
			power_boosted = TRUE
			break
	playsound(src, 'sound/effects/magic/lightningshock.ogg', 10, TRUE, extrarange = SILENCED_SOUND_EXTRARANGE, falloff_distance = 0)
	targeted_turfs += target_turf
	balloon_alert(user, "you aim at [target_turf]...")
	new /obj/effect/temp_visual/telegraphing/thunderbolt(target_turf)
	addtimer(CALLBACK(src, PROC_REF(throw_thunderbolt), target_turf, power_boosted), 1.5 SECONDS)
	thunder_charges--
	addtimer(CALLBACK(src, PROC_REF(recharge)), thunder_charge_time)
	user.log_message("fired the staff of storms at [AREACOORD(target_turf)].", LOG_ATTACK)
	return TRUE

/obj/item/storm_staff/proc/recharge(mob/user)
	thunder_charges = min(thunder_charges + 1, max_thunder_charges)
	playsound(src, 'sound/effects/magic/charge.ogg', 10, TRUE, extrarange = SILENCED_SOUND_EXTRARANGE, falloff_distance = 0)

/obj/item/storm_staff/proc/throw_thunderbolt(turf/target, boosted)
	targeted_turfs -= target
	new /obj/effect/temp_visual/thunderbolt(target)
	var/list/affected_turfs = list(target)
	if(boosted)
		for(var/direction in GLOB.alldirs)
			var/turf_to_add = get_step(target, direction)
			if(!turf_to_add)
				continue
			affected_turfs += turf_to_add
	for(var/turf/turf as anything in affected_turfs)
		new /obj/effect/temp_visual/electricity(turf)
		for(var/mob/living/hit_mob in turf)
			to_chat(hit_mob, span_userdanger("You've been struck by lightning!"))
			hit_mob.electrocute_act(15 * (isanimal_or_basicmob(hit_mob) ? 3 : 1) * (turf == target ? 2 : 1) * (boosted ? 2 : 1), src, flags = SHOCK_TESLA|SHOCK_NOSTUN)

		for(var/obj/hit_thing in turf)
			hit_thing.take_damage(20, BURN, ENERGY, FALSE)
	playsound(target, 'sound/effects/magic/lightningbolt.ogg', 100, TRUE)
	target.visible_message(span_danger("A thunderbolt strikes [target]!"))
	explosion(target, light_impact_range = (boosted ? 1 : 0), flame_range = (boosted ? 2 : 1), silent = TRUE)


/datum/action/innate/brain_undeployment
	name = "Disconnect from shell"
	desc = "Stop controlling your shell and resume normal core operations."
	button_icon = 'icons/mob/actions/actions_AI.dmi'
	button_icon_state = "ai_core"

/datum/action/innate/brain_undeployment/Trigger(trigger_flags)
	if(!..())
		return FALSE
	var/obj/item/organ/brain/cybernetic/ai/shell_to_disconnect = owner.get_organ_by_type(/obj/item/organ/brain/cybernetic/ai)

	shell_to_disconnect.undeploy()
	return TRUE

/obj/item/organ/brain/cybernetic/ai
	name = "AI-uplink brain"
	desc = "Can be inserted into a body with NO ORGANIC INTERNAL ORGANS (robotic organs only) to allow AIs to control it. Comes with its own health sensors beacon. MUST be a humanoid or bad things happen to the consciousness."
	can_smoothen_out = FALSE
	/// if connected, our AI
	var/mob/living/silicon/ai/mainframe
	/// action for undeployment
	var/datum/action/innate/brain_undeployment/undeployment_action = new

/obj/item/organ/brain/cybernetic/ai/Initialize(mapload)
	. = ..()
	AddElement(/datum/element/noticable_organ, "%PRONOUN_Their eyes move with machine precision, their expression completely blank.")

/obj/item/organ/brain/cybernetic/ai/Destroy()
	. = ..()
	undeploy()
	mainframe = null
	QDEL_NULL(undeployment_action)

/obj/item/organ/brain/cybernetic/ai/on_mob_insert(mob/living/carbon/brain_owner, special, movement_flags)
	. = ..()
	brain_owner.add_traits(list(HUMAN_SENSORS_VISIBLE_WITHOUT_SUIT, TRAIT_NO_MINDSWAP), ORGAN_TRAIT)
	update_med_hud_status(brain_owner)
	RegisterSignal(brain_owner, COMSIG_LIVING_HEALTH_UPDATE, PROC_REF(update_med_hud_status))
	RegisterSignal(brain_owner, COMSIG_CLICK, PROC_REF(owner_clicked))
	RegisterSignal(brain_owner, COMSIG_MOB_GET_STATUS_TAB_ITEMS, PROC_REF(get_status_tab_item))
	RegisterSignal(brain_owner, COMSIG_MOB_MIND_BEFORE_MIDROUND_ROLL, PROC_REF(cancel_rolls))
	RegisterSignals(brain_owner, list(COMSIG_QDELETING, COMSIG_LIVING_PRE_WABBAJACKED), PROC_REF(undeploy))
	RegisterSignal(brain_owner, COMSIG_CARBON_GAIN_ORGAN, PROC_REF(on_organ_gain))

/obj/item/organ/brain/cybernetic/ai/on_mob_remove(mob/living/carbon/organ_owner, special, movement_flags)
	undeploy()
	. = ..()
	organ_owner.remove_traits(list(HUMAN_SENSORS_VISIBLE_WITHOUT_SUIT, TRAIT_NO_MINDSWAP), ORGAN_TRAIT)
	UnregisterSignal(organ_owner, list(COMSIG_LIVING_HEALTH_UPDATE, COMSIG_CLICK, COMSIG_MOB_GET_STATUS_TAB_ITEMS, COMSIG_MOB_MIND_BEFORE_MIDROUND_ROLL, COMSIG_QDELETING, COMSIG_LIVING_PRE_WABBAJACKED))

/obj/item/organ/brain/cybernetic/ai/proc/cancel_rolls(mob/living/source, datum/mind/mind, datum/antagonist/antagonist)
	SIGNAL_HANDLER
	if(ispath(antagonist, /datum/antagonist/malf_ai))
		return
	return CANCEL_ROLL

/obj/item/organ/brain/cybernetic/ai/proc/get_status_tab_item(mob/living/source, list/items)
	SIGNAL_HANDLER
	if(!mainframe)
		return
	items += mainframe.get_status_tab_items()

/obj/item/organ/brain/cybernetic/ai/proc/update_med_hud_status(mob/living/mob_parent)
	SIGNAL_HANDLER
	var/image/holder = mob_parent.hud_list?[STATUS_HUD]
	if(isnull(holder))
		return
	var/icon/size_check = icon(mob_parent.icon, mob_parent.icon_state, mob_parent.dir)
	holder.pixel_y = size_check.Height() - ICON_SIZE_Y
	if(mob_parent.stat == DEAD || HAS_TRAIT(mob_parent, TRAIT_FAKEDEATH) || isnull(mainframe))
		holder.icon_state = "huddead2"
		holder.pixel_x = -8 // new icon states? nuh uh
	else
		holder.icon_state = "hudtrackingai"
		holder.pixel_x = -16

// no thoughts only wifi
/obj/item/organ/brain/cybernetic/ai/can_gain_trauma(datum/brain_trauma/trauma, resilience, natural_gain = FALSE)
	return FALSE

/obj/item/organ/brain/cybernetic/ai/proc/owner_clicked(datum/source, atom/location, control, params, mob/user)
	SIGNAL_HANDLER
	if(!isAI(user))
		return
	var/list/lines = list()
	lines += span_bold("[owner]")
	lines += "Target is currently [!HAS_TRAIT(owner, TRAIT_INCAPACITATED) ? "functional" : "incapacitated"]"
	lines += "Estimated organic/inorganic integrity: [owner.health]"
	if(is_sufficiently_augmented())
		lines += "<a href='byond://?src=[REF(src)];ai_take_control=[REF(user)]'>[span_boldnotice("Take control?")]</a><br>"
	else
		lines += span_warning("Organic organs detected. Robotic organs only, cannot take over.")

	to_chat(user, boxed_message(jointext(lines, "\n")), type = MESSAGE_TYPE_INFO)

/obj/item/organ/brain/cybernetic/ai/Topic(href, href_list)
	..()
	if(!href_list["ai_take_control"] || !is_sufficiently_augmented())
		return
	var/mob/living/silicon/ai/AI = locate(href_list["ai_take_control"]) in GLOB.silicon_mobs
	if(isnull(AI))
		return
	if(AI.controlled_equipment)
		to_chat(AI, span_warning("You are already loaded into an onboard computer!"))
		return
	if(!GLOB.cameranet.checkCameraVis(owner))
		to_chat(AI, span_warning("Target is no longer near active cameras."))
		return
	if(!isturf(AI.loc))
		to_chat(AI, span_warning("You aren't in your core!"))
		return

	RegisterSignal(owner, COMSIG_LIVING_DEATH, PROC_REF(undeploy))
	AI.deployed_shell = owner
	deploy_init(AI)
	ADD_TRAIT(AI.mind, TRAIT_UNCONVERTABLE, ORGAN_TRAIT)
	AI.mind.transfer_to(owner)

/obj/item/organ/brain/cybernetic/ai/proc/deploy_init(mob/living/silicon/ai/AI)
	//todo camera maybe
	mainframe = AI
	RegisterSignal(AI, COMSIG_QDELETING, PROC_REF(ai_deleted))
	undeployment_action.Grant(owner)
	update_med_hud_status(owner)
	to_chat(owner, span_boldbig("You are still considered a silicon/cyborg/AI. Follow your laws."))

/obj/item/organ/brain/cybernetic/ai/proc/undeploy(datum/source)
	SIGNAL_HANDLER
	if(!owner?.mind || !mainframe)
		return
	UnregisterSignal(src, list(COMSIG_LIVING_DEATH, COMSIG_QDELETING))
	mainframe.redeploy_action.Remove(mainframe)
	mainframe.redeploy_action.last_used_shell = null
	owner.mind.transfer_to(mainframe)
	mainframe.deployed_shell = null
	undeployment_action.Remove(owner)
	if(mainframe.laws)
		mainframe.laws.show_laws(mainframe)
	if(mainframe.eyeobj)
		mainframe.eyeobj.setLoc(loc)
	REMOVE_TRAIT(mainframe.mind, TRAIT_UNCONVERTABLE, ORGAN_TRAIT)
	mainframe = null
	update_med_hud_status(owner)

/obj/item/organ/brain/cybernetic/ai/proc/is_sufficiently_augmented()
	var/mob/living/carbon/carb_owner = owner
	. = TRUE
	if(!istype(carb_owner))
		return
	for(var/obj/item/organ/organ as anything in carb_owner.organs)
		if(organ.organ_flags & ORGAN_EXTERNAL)
			continue
		if(!IS_ROBOTIC_ORGAN(organ) && !istype(organ, /obj/item/organ/tongue)) //tongues are not in the exosuit fab and nobody is going to bother to find them so
			return FALSE

/obj/item/organ/brain/cybernetic/ai/proc/on_organ_gain(datum/source, obj/item/organ/new_organ, special)
	SIGNAL_HANDLER
	if(!is_sufficiently_augmented())
		to_chat(owner, span_danger("Connection failure. Organics detected."))
		undeploy()

/obj/item/organ/brain/cybernetic/ai/proc/ai_deleted(datum/source)
	SIGNAL_HANDLER
	to_chat(owner, span_danger("Your core has been rendered inoperable..."))
	undeploy()
