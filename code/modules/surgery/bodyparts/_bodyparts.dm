/obj/item/bodypart
	name = "limb"
	desc = "Why is it detached..."
	force = 3
	throwforce = 3
	w_class = WEIGHT_CLASS_SMALL
	icon = 'icons/mob/human/bodyparts.dmi'
	icon_state = "" //Leave this blank! Bodyparts are built using overlays
	flags_1 = PREVENT_CONTENTS_EXPLOSION_1 //actually mindblowing
	/// The icon for Organic limbs using greyscale
	VAR_PROTECTED/icon_greyscale = DEFAULT_BODYPART_ICON_ORGANIC
	///The icon for non-greyscale limbs
	VAR_PROTECTED/icon_static = 'icons/mob/human/bodyparts.dmi'
	///The icon for husked limbs
	VAR_PROTECTED/icon_husk = 'icons/mob/human/bodyparts.dmi'
	///The icon for invisible limbs
	VAR_PROTECTED/icon_invisible = 'icons/mob/human/bodyparts.dmi'
	///The type of husk for building an iconstate
	var/husk_type = "humanoid"
	///The color to multiply the greyscaled husk sprites by. Can be null. Old husk sprite chest color is #A6A6A6
	var/husk_color = "#A6A6A6"
	layer = BELOW_MOB_LAYER //so it isn't hidden behind objects when on the floor
	grind_results = list(/datum/reagent/bone_dust = 10, /datum/reagent/consumable/liquidgibs = 5) // robotic bodyparts and chests/heads cannot be ground
	/// The mob that "owns" this limb
	/// DO NOT MODIFY DIRECTLY. Use update_owner()
	var/mob/living/carbon/owner

	/// If this limb can be scarred.
	var/scarrable = TRUE

	/**
	 * A bitfield of biological states, exclusively used to determine which wounds this limb will get,
	 * as well as how easily it will happen.
	 * Set to BIO_STANDARD_UNJOINTED because most species have both flesh bone and blood in their limbs.
	 */
	var/biological_state = BIO_STANDARD_UNJOINTED
	///A bitfield of bodytypes for surgery, and misc information
	var/bodytype = BODYTYPE_ORGANIC
	///A bitfield of bodyshapes for clothing and other sprite information
	var/bodyshape = BODYSHAPE_HUMANOID
	///Defines when a bodypart should not be changed. Example: BP_BLOCK_CHANGE_SPECIES prevents the limb from being overwritten on species gain
	var/change_exempt_flags = NONE
	///Random flags that describe this bodypart
	var/bodypart_flags = NONE

	///Whether the bodypart (and the owner) is husked.
	var/is_husked = FALSE
	///Whether the bodypart (and the owner) is invisible through invisibleman trait.
	var/is_invisible = FALSE
	///The ID of a species used to generate the icon. Needs to match the icon_state portion in the limbs file!
	var/limb_id = SPECIES_HUMAN
	//Defines what sprite the limb should use if it is also sexually dimorphic.
	var/limb_gender = "m"
	///Is there a sprite difference between male and female?
	var/is_dimorphic = FALSE
	///The actual color a limb is drawn as, set by /proc/update_limb()
	var/draw_color //NEVER. EVER. EDIT THIS VALUE OUTSIDE OF UPDATE_LIMB. I WILL FIND YOU. It ruins the limb icon pipeline.

	/// BODY_ZONE_CHEST, BODY_ZONE_L_ARM, etc , used for def_zone
	var/body_zone
	/// The body zone of this part in english ("chest", "left arm", etc) without the species attached to it
	var/plaintext_zone
	var/aux_zone // used for hands
	var/aux_layer
	/// bitflag used to check which clothes cover this bodypart
	var/body_part
	/// List of obj/item's embedded inside us. Managed by embedded components, do not modify directly
	var/list/embedded_objects = list()
	/// are we a hand? if so, which one!
	var/held_index = 0
	/// A speed modifier we apply to the owner when attached, if any. Positive numbers make it move slower, negative numbers make it move faster.
	var/speed_modifier = 0

	// Limb disabling variables
	///Whether it is possible for the limb to be disabled whatsoever. TRUE means that it is possible.
	var/can_be_disabled = FALSE //Defaults to FALSE, as only human limbs can be disabled, and only the appendages.
	///Controls if the limb is disabled. TRUE means it is disabled (similar to being removed, but still present for the sake of targeted interactions).
	var/bodypart_disabled = FALSE
	///Handles limb disabling by damage. If 0 (0%), a limb can't be disabled via damage. If 1 (100%), it is disabled at max limb damage. Anything between is the percentage of damage against maximum limb damage needed to disable the limb.
	var/disabling_threshold_percentage = 0

	// Damage variables
	///A mutiplication of the burn and brute damage that the limb's stored damage contributes to its attached mob's overall wellbeing.
	var/body_damage_coeff = LIMB_BODY_DAMAGE_COEFFICIENT_TOTAL
	///The current amount of brute damage the limb has
	var/brute_dam = 0
	///The current amount of burn damage the limb has
	var/burn_dam = 0
	///The maximum brute OR burn damage a bodypart can take. Once we hit this cap, no more damage of either type!
	var/max_damage = 0

	//Used in determining overlays for limb damage states. As the mob receives more burn/brute damage, their limbs update to reflect.
	var/brutestate = 0
	var/burnstate = 0

	///Gradually increases while burning when at full damage, destroys the limb when at 100
	var/cremation_progress = 0

	//Multiplicative damage modifiers
	/// Brute damage gets multiplied by this on receive_damage()
	var/brute_modifier = 1
	/// Burn damage gets multiplied by this on receive_damage()
	var/burn_modifier = 1

	//Coloring and proper item icon update
	var/skin_tone = ""
	var/species_color = ""
	///Limbs need this information as a back-up incase they are generated outside of a carbon (limbgrower)
	var/should_draw_greyscale = TRUE
	/// An assoc list of priority (as a string because byond) -> color, used to override draw_color.
	var/list/color_overrides

	var/px_x = 0
	var/px_y = 0

	///the type of damage overlay (if any) to use when this bodypart is bruised/burned.
	var/dmg_overlay_type = "human"
	///a color (optionally matrix) for the damage overlays to give the limb
	var/damage_overlay_color
	/// If we're bleeding, which icon are we displaying on this part
	var/bleed_overlay_icon

	//Damage messages used by help_shake_act()
	var/light_brute_msg = "bruised"
	var/medium_brute_msg = "battered"
	var/heavy_brute_msg = "mangled"

	var/light_burn_msg = "numb"
	var/medium_burn_msg = "blistered"
	var/heavy_burn_msg = "peeling away"

	//Damage messages used by examine(). the desc that is most common accross all bodyparts gets shown
	var/list/damage_examines = list(
		BRUTE = DEFAULT_BRUTE_EXAMINE_TEXT,
		BURN = DEFAULT_BURN_EXAMINE_TEXT,
	)

	// Wounds related variables
	/// The wounds currently afflicting this body part
	var/list/wounds

	/// The scars currently afflicting this body part
	var/list/scars
	/// Our current stored wound damage multiplier
	var/wound_damage_multiplier = 1

	/// This number is subtracted from all wound rolls on this bodypart, higher numbers mean more defense, negative means easier to wound
	var/wound_resistance = 0
	/// When this bodypart hits max damage, this number is added to all wound rolls. Obviously only relevant for bodyparts that have damage caps.
	var/disabled_wound_penalty = 15

	/// A hat won't cover your face, but a shirt covering your chest will cover your... you know, chest
	var/scars_covered_by_clothes = TRUE
	/// So we know if we need to scream if this limb hits max damage
	var/last_maxed
	/// Our current bleed rate. Cached, update with refresh_bleed_rate()
	var/cached_bleed_rate = 0
	/// How much generic bleedstacks we have on this bodypart
	var/generic_bleedstacks
	/// If we have a gauze wrapping currently applied (not including splints)
	var/obj/item/stack/medical/gauze/current_gauze
	/// If something is currently grasping this bodypart and trying to staunch bleeding (see [/obj/item/hand_item/self_grasp])
	var/obj/item/hand_item/self_grasp/grasped_by

	///A list of all bodypart overlays to draw
	var/list/bodypart_overlays = list()

	/// Type of an attack from this limb does. Arms will do punches, Legs for kicks, and head for bites. (TO ADD: tactical chestbumps)
	var/attack_type = BRUTE
	/// the verbs used for an unarmed attack when using this limb, such as arm.unarmed_attack_verbs = list("punch")
	var/list/unarmed_attack_verbs = list("bump")
	/// if we have a special attack verb for hitting someone who is grappled by us, it goes here.
	var/grappled_attack_verb
	/// what visual effect is used when this limb is used to strike someone.
	var/unarmed_attack_effect = ATTACK_EFFECT_PUNCH
	/// Sounds when this bodypart is used in an umarmed attack
	var/sound/unarmed_attack_sound = 'sound/items/weapons/punch1.ogg'
	var/sound/unarmed_miss_sound = 'sound/items/weapons/punchmiss.ogg'
	///Lowest possible punch damage this bodypart can give. If this is set to 0, unarmed attacks will always miss.
	var/unarmed_damage_low = 1
	///Highest possible punch damage this bodypart can ive.
	var/unarmed_damage_high = 1
	///Determines the accuracy bonus, armor penetration and knockdown probability.
	var/unarmed_effectiveness = 10

	/// Traits that are given to the holder of the part. This does not update automatically on life(), only when the organs are initially generated or inserted!
	var/list/bodypart_traits = list()
	/// The name of the trait source that the organ gives. Should not be altered during the events of gameplay, and will cause problems if it is.
	var/bodypart_trait_source = BODYPART_TRAIT
	/// List of the above datums which have actually been instantiated, managed automatically
	var/list/feature_offsets = list()

	/// In the case we dont have dismemberable features, or literally cant get wounds, we will use this percent to determine when we can be dismembered.
	/// Compared to our ABSOLUTE maximum. Stored in decimal; 0.8 = 80%.
	var/hp_percent_to_dismemberable = 0.8
	/// If true, we will use [hp_percent_to_dismemberable] even if we are dismemberable via wounds. Useful for things with extreme wound resistance.
	var/use_alternate_dismemberment_calc_even_if_mangleable = FALSE
	/// If false, no wound that can be applied to us can mangle our exterior. Used for determining if we should use [hp_percent_to_dismemberable] instead of normal dismemberment.
	var/any_existing_wound_can_mangle_our_exterior
	/// If false, no wound that can be applied to us can mangle our interior. Used for determining if we should use [hp_percent_to_dismemberable] instead of normal dismemberment.
	var/any_existing_wound_can_mangle_our_interior
	/// get_damage() / total_damage must surpass this to allow our limb to be disabled, even temporarily, by an EMP.
	var/robotic_emp_paralyze_damage_percent_threshold = 0.3
	/// A potential texturing overlay to put on the limb
	var/datum/bodypart_overlay/texture/texture_bodypart_overlay
	/// Lazylist of /datum/status_effect/bodypart_effect types. Instances of this are applied to the carbon when added the limb is attached, and merged with similair limbs
	var/list/bodypart_effects

/obj/item/bodypart/apply_fantasy_bonuses(bonus)
	. = ..()
	unarmed_damage_low = modify_fantasy_variable("unarmed_damage_low", unarmed_damage_low, bonus, minimum = 1)
	unarmed_damage_high = modify_fantasy_variable("unarmed_damage_high", unarmed_damage_high, bonus, minimum = 1)
	brute_modifier = modify_fantasy_variable("brute_modifier", brute_modifier, bonus * 0.02, minimum = 0.7)
	burn_modifier = modify_fantasy_variable("burn_modifier", burn_modifier, bonus * 0.02, minimum = 0.7)
	wound_resistance = modify_fantasy_variable("wound_resistance", wound_resistance, bonus)

/obj/item/bodypart/remove_fantasy_bonuses(bonus)
	unarmed_damage_low = reset_fantasy_variable("unarmed_damage_low", unarmed_damage_low)
	unarmed_damage_high = reset_fantasy_variable("unarmed_damage_high", unarmed_damage_high)
	brute_modifier = reset_fantasy_variable("brute_modifier", brute_modifier)
	burn_modifier = reset_fantasy_variable("burn_modifier", burn_modifier)
	wound_resistance = reset_fantasy_variable("wound_resistance", wound_resistance)
	return ..()

/obj/item/bodypart/Initialize(mapload)
	. = ..()
	if(can_be_disabled)
		RegisterSignal(src, SIGNAL_ADDTRAIT(TRAIT_PARALYSIS), PROC_REF(on_paralysis_trait_gain))
		RegisterSignal(src, SIGNAL_REMOVETRAIT(TRAIT_PARALYSIS), PROC_REF(on_paralysis_trait_loss))

	RegisterSignal(src, COMSIG_ATOM_RESTYLE, PROC_REF(on_attempt_feature_restyle))

	if(texture_bodypart_overlay)
		texture_bodypart_overlay = new texture_bodypart_overlay()
		add_bodypart_overlay(texture_bodypart_overlay, update = FALSE)

	if(!IS_ORGANIC_LIMB(src))
		grind_results = null

	name = "[limb_id] [parse_zone(body_zone)]"
	update_icon_dropped()
	refresh_bleed_rate()

/obj/item/bodypart/Destroy()
	if(owner && !QDELETED(owner))
		forced_removal(special = FALSE, dismembered = TRUE, move_to_floor = FALSE)
		update_owner(null)
	for(var/wound in wounds)
		qdel(wound) // wounds is a lazylist, and each wound removes itself from it on deletion.
	if(length(wounds))
		stack_trace("[type] qdeleted with [length(wounds)] uncleared wounds")
		wounds.Cut()

	owner = null

	QDEL_LAZYLIST(scars)

	for(var/atom/movable/movable in contents)
		qdel(movable)

	QDEL_LIST_ASSOC_VAL(feature_offsets)

	return ..()

/obj/item/bodypart/ex_act(severity, target)
	if(owner) //trust me bro you dont want this
		return FALSE
	return  ..()

/obj/item/bodypart/proc/on_forced_removal(atom/old_loc, dir, forced, list/old_locs)
	SIGNAL_HANDLER

	forced_removal(special = FALSE, dismembered = TRUE, move_to_floor = FALSE)

/// In-case someone, somehow only teleports someones limb
/obj/item/bodypart/proc/forced_removal(special, dismembered, move_to_floor)
	drop_limb(special, dismembered, move_to_floor)

	update_icon_dropped()

/obj/item/bodypart/examine(mob/user)
	SHOULD_CALL_PARENT(TRUE)

	. = ..()
	if(brute_dam > DAMAGE_PRECISION)
		. += span_warning("This limb has [brute_dam > 30 ? "severe" : "minor"] bruising.")
	if(burn_dam > DAMAGE_PRECISION)
		. += span_warning("This limb has [burn_dam > 30 ? "severe" : "minor"] burns.")

	for(var/datum/wound/wound as anything in wounds)
		var/wound_desc = wound.get_limb_examine_description()
		if(wound_desc)
			. += wound_desc

/**
 * Called when a bodypart is checked for injuries.
 *
 * Modifies the check_list list with the resulting report of the limb's status.
 */
/obj/item/bodypart/proc/check_for_injuries(mob/living/carbon/human/examiner, list/check_list)

	var/list/limb_damage = list(BRUTE = brute_dam, BURN = burn_dam)

	SEND_SIGNAL(src, COMSIG_BODYPART_CHECKED_FOR_INJURY, examiner, check_list, limb_damage)
	SEND_SIGNAL(examiner, COMSIG_CARBON_CHECKING_BODYPART, src, check_list, limb_damage)

	var/shown_brute = limb_damage[BRUTE]
	var/shown_burn = limb_damage[BURN]
	var/status = ""
	var/self_aware = HAS_TRAIT(examiner, TRAIT_SELF_AWARE)

	if(self_aware)
		if(!shown_brute && !shown_burn)
			status = "no damage"
		else
			status = "[shown_brute] brute damage and [shown_burn] burn damage"

	else
		if(shown_brute > (max_damage * 0.8))
			status += heavy_brute_msg
		else if(shown_brute > (max_damage * 0.4))
			status += medium_brute_msg
		else if(shown_brute > DAMAGE_PRECISION)
			status += light_brute_msg

		if(shown_brute > DAMAGE_PRECISION && shown_burn > DAMAGE_PRECISION)
			status += " and "

		if(shown_burn > (max_damage * 0.8))
			status += heavy_burn_msg
		else if(shown_burn > (max_damage * 0.2))
			status += medium_burn_msg
		else if(shown_burn > DAMAGE_PRECISION)
			status += light_burn_msg

		if(status == "")
			status = "OK"

	var/no_damage
	if(status == "OK" || status == "no damage")
		no_damage = TRUE

	var/is_disabled = ""
	if(bodypart_disabled)
		is_disabled = " is disabled"
		if(no_damage)
			is_disabled += " but otherwise"
		else
			is_disabled += " and"

	check_list += "\t <span class='[no_damage ? "notice" : "warning"]'>Your [name][is_disabled][self_aware ? " has " : " is "][status].</span>"

	for(var/datum/wound/wound as anything in wounds)
		switch(wound.severity)
			if(WOUND_SEVERITY_TRIVIAL)
				check_list += "\t [span_danger("Your [name] is suffering [wound.a_or_from] [LOWER_TEXT(wound.name)].")]"
			if(WOUND_SEVERITY_MODERATE)
				check_list += "\t [span_warning("Your [name] is suffering [wound.a_or_from] [LOWER_TEXT(wound.name)]!")]"
			if(WOUND_SEVERITY_SEVERE)
				check_list += "\t [span_boldwarning("Your [name] is suffering [wound.a_or_from] [LOWER_TEXT(wound.name)]!!")]"
			if(WOUND_SEVERITY_CRITICAL)
				check_list += "\t [span_boldwarning("Your [name] is suffering [wound.a_or_from] [LOWER_TEXT(wound.name)]!!!")]"

	for(var/obj/item/embedded_thing as anything in embedded_objects)
		var/harmless = embedded_thing.get_embed().is_harmless()
		var/stuck_wordage = harmless ? "stuck to" : "embedded in"
		var/embed_text = "\t <a href='byond://?src=[REF(examiner)];embedded_object=[REF(embedded_thing)];embedded_limb=[REF(src)]'> There is [icon2html(embedded_thing, examiner)] \a [embedded_thing] [stuck_wordage] your [plaintext_zone]!</a>"
		if (harmless)
			check_list += span_italics(span_notice(embed_text))
		else
			check_list += span_boldwarning(embed_text)

/obj/item/bodypart/blob_act()
	receive_damage(max_damage, wound_bonus = CANT_WOUND)

/obj/item/bodypart/attack(mob/living/carbon/victim, mob/user)
	SHOULD_CALL_PARENT(TRUE)

	if(ishuman(victim))
		var/mob/living/carbon/human/human_victim = victim
		if(HAS_TRAIT(victim, TRAIT_LIMBATTACHMENT) || HAS_TRAIT(src, TRAIT_EASY_ATTACH))
			if(!human_victim.get_bodypart(body_zone))
				user.temporarilyRemoveItemFromInventory(src, TRUE)
				if(!try_attach_limb(victim))
					to_chat(user, span_warning("[human_victim]'s body rejects [src]!"))
					forceMove(human_victim.loc)
					return
				if(check_for_frankenstein(victim))
					bodypart_flags |= BODYPART_IMPLANTED
				if(human_victim == user)
					human_victim.visible_message(span_warning("[human_victim] jams [src] into [human_victim.p_their()] empty socket!"),\
					span_notice("You force [src] into your empty socket, and it locks into place!"))
				else
					human_victim.visible_message(span_warning("[user] jams [src] into [human_victim]'s empty socket!"),\
					span_notice("[user] forces [src] into your empty socket, and it locks into place!"))
				return
	return ..()

/obj/item/bodypart/attackby(obj/item/weapon, mob/user, params)
	SHOULD_CALL_PARENT(TRUE)

	if(weapon.get_sharpness())
		add_fingerprint(user)
		if(!contents.len)
			to_chat(user, span_warning("There is nothing left inside [src]!"))
			return
		playsound(loc, 'sound/items/weapons/slice.ogg', 50, TRUE, -1)
		user.visible_message(span_warning("[user] begins to cut open [src]."),\
			span_notice("You begin to cut open [src]..."))
		if(do_after(user, 5.4 SECONDS, target = src))
			drop_organs(user, TRUE)
	else
		return ..()

/obj/item/bodypart/throw_impact(atom/hit_atom, datum/thrownthing/throwingdatum)
	SHOULD_CALL_PARENT(TRUE)

	..()
	if(IS_ORGANIC_LIMB(src))
		playsound(get_turf(src), 'sound/misc/splort.ogg', 50, TRUE, -1)
	pixel_x = rand(-3, 3)
	pixel_y = rand(-3, 3)

//empties the bodypart from its organs and other things inside it
/obj/item/bodypart/proc/drop_organs(mob/user, violent_removal)
	SHOULD_CALL_PARENT(TRUE)

	var/atom/drop_loc = drop_location()
	if(IS_ORGANIC_LIMB(src))
		playsound(drop_loc, 'sound/misc/splort.ogg', 50, TRUE, -1)

	QDEL_NULL(current_gauze)

	for(var/obj/item/organ/bodypart_organ in contents)
		if(bodypart_organ.organ_flags & ORGAN_UNREMOVABLE)
			continue
		if(owner)
			bodypart_organ.Remove(bodypart_organ.owner)
		else
			if(bodypart_organ.bodypart_remove(src))
				if(drop_loc) //can be null if being deleted
					bodypart_organ.forceMove(get_turf(drop_loc))

	if(drop_loc) //can be null during deletion
		for(var/atom/movable/movable as anything in src)
			movable.forceMove(drop_loc)

	update_icon_dropped()

//Return TRUE to get whatever mob this is in to update health.
/obj/item/bodypart/proc/on_life(seconds_per_tick, times_fired)
	SHOULD_CALL_PARENT(TRUE)

/**
 * #receive_damage
 *
 * called when a bodypart is taking damage
 * Damage will not exceed max_damage using this proc, and negative damage cannot be used to heal
 * Returns TRUE if damage icon states changes
 * Args:
 * brute - The amount of brute damage dealt.
 * burn - The amount of burn damage dealt.
 * blocked - The amount of damage blocked by armor.
 * update_health - Whether to update the owner's health from receiving the hit.
 * required_bodytype - A bodytype flag requirement to get this damage (ex: BODYTYPE_ORGANIC)
 * wound_bonus - Additional bonus chance to get a wound.
 * bare_wound_bonus - Additional bonus chance to get a wound if the bodypart is naked.
 * wound_clothing - If this should damage clothing.
 * sharpness - Flag on whether the attack is edged or pointy
 * attack_direction - The direction the bodypart is attacked from, used to send blood flying in the opposite direction.
 * damage_source - The source of damage, typically a weapon.
 */
/obj/item/bodypart/proc/receive_damage(brute = 0, burn = 0, blocked = 0, updating_health = TRUE, forced = FALSE, required_bodytype = null, wound_bonus = 0, bare_wound_bonus = 0, sharpness = NONE, attack_direction = null, damage_source, wound_clothing = TRUE)
	SHOULD_CALL_PARENT(TRUE)

	var/hit_percent = forced ? 1 : (100-blocked)/100
	if((!brute && !burn) || hit_percent <= 0)
		return FALSE
	if (!forced)
		if(!isnull(owner))
			if (HAS_TRAIT(owner, TRAIT_GODMODE))
				return FALSE
			if (SEND_SIGNAL(owner, COMSIG_CARBON_LIMB_DAMAGED, src, brute, burn) & COMPONENT_PREVENT_LIMB_DAMAGE)
				return FALSE
		if(required_bodytype && !(bodytype & required_bodytype))
			return FALSE

	var/dmg_multi = CONFIG_GET(number/damage_multiplier) * hit_percent
	brute = round(max(brute * dmg_multi * brute_modifier, 0), DAMAGE_PRECISION)
	burn = round(max(burn * dmg_multi * burn_modifier, 0), DAMAGE_PRECISION)

	if(!brute && !burn)
		return FALSE

	brute *= wound_damage_multiplier
	burn *= wound_damage_multiplier

	if(bodytype & (BODYTYPE_ALIEN|BODYTYPE_LARVA_PLACEHOLDER)) //aliens take double burn //nothing can burn with so much snowflake code around
		burn *= 2

	/*
	// START WOUND HANDLING
	*/

	// what kind of wounds we're gonna roll for, take the greater between brute and burn, then if it's brute, we subdivide based on sharpness
	var/wounding_type = (brute > burn ? WOUND_BLUNT : WOUND_BURN)
	var/wounding_dmg = max(brute, burn)

	if(wounding_type == WOUND_BLUNT && sharpness)
		if(sharpness & SHARP_EDGED)
			wounding_type = WOUND_SLASH
		else if (sharpness & SHARP_POINTY)
			wounding_type = WOUND_PIERCE

	if(owner) // i tried to modularize the below, but the modifications to wounding_dmg and wounding_type cant be extracted to a proc
		var/mangled_state = get_mangled_state()
		var/easy_dismember = HAS_TRAIT(owner, TRAIT_EASYDISMEMBER) // if we have easydismember, we don't reduce damage when redirecting damage to different types (slashing weapons on mangled/skinless limbs attack at 100% instead of 50%)

		var/bio_status = get_bio_state_status()

		var/has_exterior = ((bio_status & ANATOMY_EXTERIOR))
		var/has_interior = ((bio_status & ANATOMY_INTERIOR))

		var/exterior_ready_to_dismember = (!has_exterior || ((mangled_state & BODYPART_MANGLED_EXTERIOR)))

		// if we're bone only, all cutting attacks go straight to the bone
		if(!has_exterior && has_interior)
			if(wounding_type == WOUND_SLASH)
				wounding_type = WOUND_BLUNT
				wounding_dmg *= (easy_dismember ? 1 : 0.6)
			else if(wounding_type == WOUND_PIERCE)
				wounding_type = WOUND_BLUNT
				wounding_dmg *= (easy_dismember ? 1 : 0.75)
		else
			// if we've already mangled the skin (critical slash or piercing wound), then the bone is exposed, and we can damage it with sharp weapons at a reduced rate
			// So a big sharp weapon is still all you need to destroy a limb
			if(has_interior && exterior_ready_to_dismember && !(mangled_state & BODYPART_MANGLED_INTERIOR) && sharpness)
				if(wounding_type == WOUND_SLASH && !easy_dismember)
					wounding_dmg *= 0.6 // edged weapons pass along 60% of their wounding damage to the bone since the power is spread out over a larger area
				if(wounding_type == WOUND_PIERCE && !easy_dismember)
					wounding_dmg *= 0.75 // piercing weapons pass along 75% of their wounding damage to the bone since it's more concentrated
				wounding_type = WOUND_BLUNT
		if ((dismemberable_by_wound() || dismemberable_by_total_damage()) && try_dismember(wounding_type, wounding_dmg, wound_bonus, bare_wound_bonus))
			return
		// now we have our wounding_type and are ready to carry on with wounds and dealing the actual damage
		if(wounding_dmg >= WOUND_MINIMUM_DAMAGE && wound_bonus != CANT_WOUND)
			check_wounding(wounding_type, wounding_dmg, wound_bonus, bare_wound_bonus, attack_direction, damage_source = damage_source, wound_clothing = wound_clothing)

	for(var/datum/wound/iter_wound as anything in wounds)
		iter_wound.receive_damage(wounding_type, wounding_dmg, wound_bonus, damage_source)

	/*
	// END WOUND HANDLING
	*/

	//back to our regularly scheduled program, we now actually apply damage if there's room below limb damage cap
	var/can_inflict = max_damage - get_damage()
	var/total_damage = brute + burn
	if(total_damage > can_inflict && total_damage > 0) // TODO: the second part of this check should be removed once disabling is all done
		brute = round(brute * (can_inflict / total_damage),DAMAGE_PRECISION)
		burn = round(burn * (can_inflict / total_damage),DAMAGE_PRECISION)

	if(can_inflict <= 0)
		return FALSE
	if(brute)
		set_brute_dam(brute_dam + brute)
	if(burn)
		set_burn_dam(burn_dam + burn)

	if(owner)
		if(can_be_disabled)
			update_disabled()
		if(updating_health)
			owner.updatehealth()
	return update_bodypart_damage_state() || .

/// Returns a bitflag using ANATOMY_EXTERIOR or ANATOMY_INTERIOR. Used to determine if we as a whole have a interior or exterior biostate, or both.
/obj/item/bodypart/proc/get_bio_state_status()
	SHOULD_BE_PURE(TRUE)

	var/bio_status = NONE

	for (var/state as anything in GLOB.bio_state_anatomy)
		var/flag = text2num(state)
		if (!(biological_state & flag))
			continue

		var/value = GLOB.bio_state_anatomy[state]
		if (value & ANATOMY_EXTERIOR)
			bio_status |= ANATOMY_EXTERIOR
		if (value & ANATOMY_INTERIOR)
			bio_status |= ANATOMY_INTERIOR

		if ((bio_status & ANATOMY_EXTERIOR_AND_INTERIOR) == ANATOMY_EXTERIOR_AND_INTERIOR)
			break

	return bio_status

/// Returns if our current mangling status allows us to be dismembered. Requires both no exterior/mangled exterior and no interior/mangled interior.
/obj/item/bodypart/proc/dismemberable_by_wound()
	SHOULD_BE_PURE(TRUE)

	var/mangled_state = get_mangled_state()

	var/bio_status = get_bio_state_status()

	var/has_exterior = ((bio_status & ANATOMY_EXTERIOR))
	var/has_interior = ((bio_status & ANATOMY_INTERIOR))

	var/exterior_ready_to_dismember = (!has_exterior || ((mangled_state & BODYPART_MANGLED_EXTERIOR)))
	var/interior_ready_to_dismember = (!has_interior || ((mangled_state & BODYPART_MANGLED_INTERIOR)))

	return (exterior_ready_to_dismember && interior_ready_to_dismember)

/// Returns TRUE if our total percent damage is more or equal to our dismemberable percentage, but FALSE if a wound can cause us to be dismembered.
/obj/item/bodypart/proc/dismemberable_by_total_damage()

	update_wound_theory()

	var/bio_status = get_bio_state_status()

	var/has_interior = ((bio_status & ANATOMY_INTERIOR))
	var/can_theoretically_be_dismembered_by_wound = (any_existing_wound_can_mangle_our_interior || (any_existing_wound_can_mangle_our_exterior && has_interior))

	var/wound_dismemberable = dismemberable_by_wound()
	var/ready_to_use_alternate_formula = (use_alternate_dismemberment_calc_even_if_mangleable || (!wound_dismemberable && !can_theoretically_be_dismembered_by_wound))

	if (ready_to_use_alternate_formula)
		var/percent_to_total_max = (get_damage() / max_damage)
		if (percent_to_total_max >= hp_percent_to_dismemberable)
			return TRUE

	return FALSE

/// Updates our "can be theoretically dismembered by wounds" variables by iterating through all wound static data.
/obj/item/bodypart/proc/update_wound_theory()
	// We put this here so we dont increase init time by doing this all at once on initialization
	// Effectively, we "lazy load"
	if (isnull(any_existing_wound_can_mangle_our_interior) || isnull(any_existing_wound_can_mangle_our_exterior))
		any_existing_wound_can_mangle_our_interior = FALSE
		any_existing_wound_can_mangle_our_exterior = FALSE
		for (var/datum/wound/wound_type as anything in GLOB.all_wound_pregen_data)
			var/datum/wound_pregen_data/pregen_data = GLOB.all_wound_pregen_data[wound_type]
			if (!pregen_data.can_be_applied_to(src, random_roll = TRUE)) // we only consider randoms because non-randoms are usually really specific
				continue
			if (initial(pregen_data.wound_path_to_generate.wound_flags) & MANGLES_EXTERIOR)
				any_existing_wound_can_mangle_our_exterior = TRUE
			if (initial(pregen_data.wound_path_to_generate.wound_flags) & MANGLES_INTERIOR)
				any_existing_wound_can_mangle_our_interior = TRUE

			if (any_existing_wound_can_mangle_our_interior && any_existing_wound_can_mangle_our_exterior)
				break

//Heals brute and burn damage for the organ. Returns 1 if the damage-icon states changed at all.
//Damage cannot go below zero.
//Cannot remove negative damage (i.e. apply damage)
/obj/item/bodypart/proc/heal_damage(brute, burn, updating_health = TRUE, forced = FALSE, required_bodytype)
	SHOULD_CALL_PARENT(TRUE)

	if(!forced && required_bodytype && !(bodytype & required_bodytype)) //So we can only heal certain kinds of limbs, ie robotic vs organic.
		return

	if(brute)
		set_brute_dam(round(max(brute_dam - brute, 0), DAMAGE_PRECISION))
	if(burn)
		set_burn_dam(round(max(burn_dam - burn, 0), DAMAGE_PRECISION))

	if(owner)
		if(can_be_disabled)
			update_disabled()
		if(updating_health)
			owner.updatehealth()
	cremation_progress = min(0, cremation_progress - ((brute_dam + burn_dam)*(100/max_damage)))
	return update_bodypart_damage_state()

///Sets the damage of a bodypart when it is created.
/obj/item/bodypart/proc/set_initial_damage(brute_damage, burn_damage)
	set_brute_dam(brute_damage)
	set_burn_dam(burn_damage)

///Proc to hook behavior associated to the change of the brute_dam variable's value.
/obj/item/bodypart/proc/set_brute_dam(new_value)
	PROTECTED_PROC(TRUE)

	if(brute_dam == new_value)
		return
	. = brute_dam
	brute_dam = new_value

///Proc to hook behavior associated to the change of the burn_dam variable's value.
/obj/item/bodypart/proc/set_burn_dam(new_value)
	PROTECTED_PROC(TRUE)

	if(burn_dam == new_value)
		return
	. = burn_dam
	burn_dam = new_value

//Returns total damage.
/obj/item/bodypart/proc/get_damage()
	return brute_dam + burn_dam

//Checks disabled status thresholds
/obj/item/bodypart/proc/update_disabled()
	SHOULD_CALL_PARENT(TRUE)

	if(!owner)
		return

	if(!can_be_disabled)
		set_disabled(FALSE)
		CRASH("update_disabled called with can_be_disabled false")

	if(HAS_TRAIT(src, TRAIT_PARALYSIS))
		set_disabled(TRUE)
		return

	var/total_damage = brute_dam + burn_dam

	// this block of checks is for limbs that can be disabled, but not through pure damage (AKA limbs that suffer wounds, human/monkey parts and such)
	if(!disabling_threshold_percentage)
		if(total_damage < max_damage)
			last_maxed = FALSE
		else
			if(!last_maxed && owner.stat < UNCONSCIOUS)
				INVOKE_ASYNC(owner, TYPE_PROC_REF(/mob, emote), "scream")
			last_maxed = TRUE
		set_disabled(FALSE) // we only care about the paralysis trait
		return

	// we're now dealing solely with limbs that can be disabled through pure damage, AKA robot parts
	if(total_damage >= max_damage * disabling_threshold_percentage)
		if(!last_maxed)
			if(owner.stat < UNCONSCIOUS)
				INVOKE_ASYNC(owner, TYPE_PROC_REF(/mob, emote), "scream")
			last_maxed = TRUE
		set_disabled(TRUE)
		return

	if(bodypart_disabled && total_damage <= max_damage * 0.5) // reenable the limb at 50% health
		last_maxed = FALSE
		set_disabled(FALSE)

///Proc to change the value of the `disabled` variable and react to the event of its change.
/obj/item/bodypart/proc/set_disabled(new_disabled)
	SHOULD_CALL_PARENT(TRUE)
	PROTECTED_PROC(TRUE)

	if(bodypart_disabled == new_disabled)
		return
	. = bodypart_disabled
	bodypart_disabled = new_disabled

	if(!owner)
		return
	owner.update_health_hud() //update the healthdoll
	owner.update_body()

/// Proc to change the value of the `owner` variable and react to the event of its change.
/obj/item/bodypart/proc/update_owner(new_owner)
	SHOULD_NOT_OVERRIDE(TRUE)

	if(owner == new_owner)
		return FALSE //`null` is a valid option, so we need to use a num var to make it clear no change was made.

	if(owner)
		. = owner //return value is old owner
		clear_ownership(owner)
	if(new_owner)
		apply_ownership(new_owner)

	SEND_SIGNAL(src, COMSIG_BODYPART_CHANGED_OWNER, new_owner, owner)

	refresh_bleed_rate()
	return .

/// Run all necessary procs to remove a limbs ownership and remove the appropriate signals and traits
/obj/item/bodypart/proc/clear_ownership(mob/living/carbon/old_owner)
	SHOULD_CALL_PARENT(TRUE)

	owner = null

	if(speed_modifier)
		old_owner.update_bodypart_speed_modifier()
	if(length(bodypart_traits))
		old_owner.remove_traits(bodypart_traits, bodypart_trait_source)

	UnregisterSignal(old_owner, list(
		SIGNAL_REMOVETRAIT(TRAIT_NOLIMBDISABLE),
	SIGNAL_ADDTRAIT(TRAIT_NOLIMBDISABLE),
		SIGNAL_REMOVETRAIT(TRAIT_NOBLOOD),
		SIGNAL_ADDTRAIT(TRAIT_NOBLOOD),
		))

	UnregisterSignal(old_owner, list(COMSIG_ATOM_RESTYLE, COMSIG_COMPONENT_CLEAN_ACT))

/// Apply ownership of a limb to someone, giving the appropriate traits, updates and signals
/obj/item/bodypart/proc/apply_ownership(mob/living/carbon/new_owner)
	SHOULD_CALL_PARENT(TRUE)

	owner = new_owner

	if(speed_modifier)
		owner.update_bodypart_speed_modifier()
	if(length(bodypart_traits))
		owner.add_traits(bodypart_traits, bodypart_trait_source)

	if(initial(can_be_disabled))
		if(HAS_TRAIT(owner, TRAIT_NOLIMBDISABLE))
			set_can_be_disabled(FALSE)

		// Listen to disable traits being added
		RegisterSignal(owner, SIGNAL_REMOVETRAIT(TRAIT_NOLIMBDISABLE), PROC_REF(on_owner_nolimbdisable_trait_loss))
		RegisterSignal(owner, SIGNAL_ADDTRAIT(TRAIT_NOLIMBDISABLE), PROC_REF(on_owner_nolimbdisable_trait_gain))

		// Listen to no blood traits being added
		RegisterSignal(owner, SIGNAL_REMOVETRAIT(TRAIT_NOBLOOD), PROC_REF(on_owner_nobleed_loss))
		RegisterSignal(owner, SIGNAL_ADDTRAIT(TRAIT_NOBLOOD), PROC_REF(on_owner_nobleed_gain))

	if(can_be_disabled)
		update_disabled()

	RegisterSignal(owner, COMSIG_ATOM_RESTYLE, PROC_REF(on_attempt_feature_restyle_mob))
	RegisterSignal(owner, COMSIG_COMPONENT_CLEAN_ACT, PROC_REF(on_owner_clean))

	forceMove(owner)
	RegisterSignal(src, COMSIG_MOVABLE_MOVED, PROC_REF(on_forced_removal)) //this must be set after we moved, or we insta gib

/// Called on addition of a bodypart
/obj/item/bodypart/proc/on_adding(mob/living/carbon/new_owner)
	SHOULD_CALL_PARENT(TRUE)

	item_flags |= ABSTRACT
	ADD_TRAIT(src, TRAIT_NODROP, ORGAN_INSIDE_BODY_TRAIT)

/// Called on removal of a bodypart.
/obj/item/bodypart/proc/on_removal(mob/living/carbon/old_owner)
	SHOULD_CALL_PARENT(TRUE)

	UnregisterSignal(src, COMSIG_MOVABLE_MOVED)

	item_flags &= ~ABSTRACT
	REMOVE_TRAIT(src, TRAIT_NODROP, ORGAN_INSIDE_BODY_TRAIT)

	if(!length(bodypart_traits))
		return

	owner.remove_traits(bodypart_traits, bodypart_trait_source)

///Proc to change the value of the `can_be_disabled` variable and react to the event of its change.
/obj/item/bodypart/proc/set_can_be_disabled(new_can_be_disabled)
	PROTECTED_PROC(TRUE)
	SHOULD_CALL_PARENT(TRUE)

	if(can_be_disabled == new_can_be_disabled)
		return
	. = can_be_disabled
	can_be_disabled = new_can_be_disabled
	if(can_be_disabled)
		if(owner)
			if(HAS_TRAIT(owner, TRAIT_NOLIMBDISABLE))
				CRASH("set_can_be_disabled to TRUE with for limb whose owner has TRAIT_NOLIMBDISABLE")
			RegisterSignal(owner, SIGNAL_ADDTRAIT(TRAIT_PARALYSIS), PROC_REF(on_paralysis_trait_gain))
			RegisterSignal(owner, SIGNAL_REMOVETRAIT(TRAIT_PARALYSIS), PROC_REF(on_paralysis_trait_loss))
		update_disabled()
	else if(.)
		if(owner)
			UnregisterSignal(owner, list(
				SIGNAL_ADDTRAIT(TRAIT_PARALYSIS),
				SIGNAL_REMOVETRAIT(TRAIT_PARALYSIS),
				))
		set_disabled(FALSE)

///Called when TRAIT_PARALYSIS is added to the limb.
/obj/item/bodypart/proc/on_paralysis_trait_gain(obj/item/bodypart/source)
	PROTECTED_PROC(TRUE)
	SIGNAL_HANDLER

	if(can_be_disabled)
		set_disabled(TRUE)

///Called when TRAIT_PARALYSIS is removed from the limb.
/obj/item/bodypart/proc/on_paralysis_trait_loss(obj/item/bodypart/source)
	PROTECTED_PROC(TRUE)
	SIGNAL_HANDLER

	if(can_be_disabled)
		update_disabled()

///Called when TRAIT_NOLIMBDISABLE is added to the owner.
/obj/item/bodypart/proc/on_owner_nolimbdisable_trait_gain(mob/living/carbon/source)
	PROTECTED_PROC(TRUE)
	SIGNAL_HANDLER

	set_can_be_disabled(FALSE)

///Called when TRAIT_NOLIMBDISABLE is removed from the owner.
/obj/item/bodypart/proc/on_owner_nolimbdisable_trait_loss(mob/living/carbon/source)
	PROTECTED_PROC(TRUE)
	SIGNAL_HANDLER

	set_can_be_disabled(initial(can_be_disabled))

//Updates an organ's brute/burn states for use by update_damage_overlays()
//Returns 1 if we need to update overlays. 0 otherwise.
/obj/item/bodypart/proc/update_bodypart_damage_state()
	SHOULD_CALL_PARENT(TRUE)

	var/tbrute = round( (brute_dam/max_damage)*3, 1 )
	var/tburn = round( (burn_dam/max_damage)*3, 1 )
	if((tbrute != brutestate) || (tburn != burnstate))
		brutestate = tbrute
		burnstate = tburn
		return TRUE
	return FALSE

//we inform the bodypart of the changes that happened to the owner, or give it the informations from a source mob.
//set is_creating to true if you want to change the appearance of the limb outside of mutation changes or forced changes.
/obj/item/bodypart/proc/update_limb(dropping_limb = FALSE, is_creating = FALSE)
	SHOULD_CALL_PARENT(TRUE)

	if(IS_ORGANIC_LIMB(src))
		if(!(bodypart_flags & BODYPART_UNHUSKABLE) && owner && HAS_TRAIT(owner, TRAIT_HUSK))
			dmg_overlay_type = "" //no damage overlay shown when husked
			is_husked = TRUE
		else if(owner && HAS_TRAIT(owner, TRAIT_INVISIBLE_MAN))
			dmg_overlay_type = "" //no damage overlay shown when invisible since the wounds themselves are invisible.
			is_invisible = TRUE
		else
			dmg_overlay_type = initial(dmg_overlay_type)
			is_husked = FALSE
			is_invisible = FALSE

	update_draw_color()

	if(!is_creating || !owner)
		return

	// There should technically to be an ishuman(owner) check here, but it is absent because no basetype carbons use bodyparts
	// No, xenos don't actually use bodyparts. Don't ask.
	var/mob/living/carbon/human/human_owner = owner

	limb_gender = (human_owner.physique == MALE) ? "m" : "f"
	if(HAS_TRAIT(human_owner, TRAIT_USES_SKINTONES))
		skin_tone = human_owner.skin_tone
	else if(HAS_TRAIT(human_owner, TRAIT_MUTANT_COLORS))
		skin_tone = ""
		var/datum/species/owner_species = human_owner.dna.species
		if(owner_species.fixed_mut_color)
			species_color = owner_species.fixed_mut_color
		else
			species_color = human_owner.dna.features["mcolor"]
	else
		skin_tone = ""
		species_color = ""

	update_draw_color()

	// Recolors mutant overlays to match new mutant colors
	for(var/datum/bodypart_overlay/mutant/overlay in bodypart_overlays)
		overlay.inherit_color(src, force = TRUE)
	// Ensures marking overlays are updated accordingly as well
	for(var/datum/bodypart_overlay/simple/body_marking/marking in bodypart_overlays)
		marking.set_appearance(human_owner.dna.features[marking.dna_feature_key], species_color)

	return TRUE

/obj/item/bodypart/proc/update_draw_color()
	draw_color = null
	if(LAZYLEN(color_overrides))
		var/priority
		for (var/override_priority in color_overrides)
			if (text2num(override_priority) > priority)
				priority = text2num(override_priority)
				draw_color = color_overrides[override_priority]
		return
	if(should_draw_greyscale)
		draw_color = species_color || (skin_tone ? skintone2hex(skin_tone) : null)

/obj/item/bodypart/proc/add_color_override(new_color, color_priority)
	LAZYSET(color_overrides, "[color_priority]", new_color)

/obj/item/bodypart/proc/remove_color_override(color_priority)
	LAZYREMOVE(color_overrides, "[color_priority]")

/// Called when limb's current owner gets washed
/obj/item/bodypart/proc/on_owner_clean(mob/living/carbon/source, clean_types)
	SIGNAL_HANDLER
	wash(clean_types)

/// To update the bodypart's icon when not attached to a mob
/obj/item/bodypart/proc/update_icon_dropped()
	SHOULD_CALL_PARENT(TRUE)

	cut_overlays()
	var/list/standing = get_limb_icon(TRUE)
	if(!standing.len)
		icon_state = initial(icon_state)//no overlays found, we default back to initial icon.
		return
	for(var/image/img as anything in standing)
		img.pixel_x += px_x
		img.pixel_y += px_y
	add_overlay(standing)

/obj/item/bodypart/update_atom_colour()
	. = ..()
	for(var/i in 1 to COLOUR_PRIORITY_AMOUNT)
		var/list/checked_color = atom_colours[i]
		if (!checked_color)
			remove_color_override(LIMB_COLOR_ATOM_COLOR + i)
			continue
		var/actual_color = checked_color[ATOM_COLOR_VALUE_INDEX]
		if (checked_color[ATOM_COLOR_TYPE_INDEX] == ATOM_COLOR_TYPE_FILTER)
			var/color_filter = checked_color[ATOM_COLOR_VALUE_INDEX]
			actual_color = apply_matrix_to_color(COLOR_WHITE, color_filter["color"], color_filter["space"] || COLORSPACE_RGB)
		add_color_override(actual_color, LIMB_COLOR_ATOM_COLOR + i)
	update_limb()
	if (owner)
		owner.update_body_parts()
	else
		update_icon_dropped()

///Generates an /image for the limb to be used as an overlay
/obj/item/bodypart/proc/get_limb_icon(dropped)
	SHOULD_CALL_PARENT(TRUE)
	RETURN_TYPE(/list)

	icon_state = "" //to erase the default sprite, we're building the visual aspects of the bodypart through overlays alone.

	. = list()

	var/image_dir = NONE
	if(dropped)
		image_dir = SOUTH
		if(dmg_overlay_type)
			if(brutestate)
				. += image('icons/mob/effects/dam_mob.dmi', "[dmg_overlay_type]_[body_zone]_[brutestate]0", -DAMAGE_LAYER, image_dir)
			if(burnstate)
				. += image('icons/mob/effects/dam_mob.dmi', "[dmg_overlay_type]_[body_zone]_0[burnstate]", -DAMAGE_LAYER, image_dir)

	var/image/limb = image(layer = -BODYPARTS_LAYER, dir = image_dir)
	var/image/aux

	// Handles invisibility (not alpha or actual invisibility but invisibility)
	if(is_invisible)
		limb.icon = icon_invisible
		limb.icon_state = "invisible_[body_zone]"
		. += limb
		return .

	// Normal non-husk handling
		// This is the MEAT of limb icon code
	limb.icon = icon_greyscale
	if(!should_draw_greyscale || !icon_greyscale)
		limb.icon = icon_static

	if(is_dimorphic) //Does this type of limb have sexual dimorphism?
		limb.icon_state = "[limb_id]_[body_zone]_[limb_gender]"
	else
		limb.icon_state = "[limb_id]_[body_zone]"

	icon_exists_or_scream(limb.icon, limb.icon_state) //Prints a stack trace on the first failure of a given iconstate.

	. += limb

	if(aux_zone) //Hand shit
		aux = image(limb.icon, "[limb_id]_[aux_zone]", -aux_layer, image_dir)
		. += aux

	update_draw_color()

	if(is_husked)
		huskify_image(thing_to_husk = limb)
		if(aux)
			huskify_image(thing_to_husk = aux)
		draw_color = husk_color
	if(draw_color)
		limb.color = "[draw_color]"
		if(aux_zone)
			aux.color = "[draw_color]"

		//EMISSIVE CODE START
		// For some reason this was applied as an overlay on the aux image and limb image before.
		// I am very sure that this is unnecessary, and i need to treat it as part of the return list
		// to be able to mask it proper in case this limb is a leg.
	if(!is_husked)
		if(blocks_emissive != EMISSIVE_BLOCK_NONE)
			var/atom/location = loc || owner || src
			var/mutable_appearance/limb_em_block = emissive_blocker(limb.icon, limb.icon_state, location, layer = limb.layer, alpha = limb.alpha)
			limb_em_block.dir = image_dir
			. += limb_em_block

			if(aux_zone)
				var/mutable_appearance/aux_em_block = emissive_blocker(aux.icon, aux.icon_state, location, layer = aux.layer, alpha = aux.alpha)
				aux_em_block.dir = image_dir
				. += aux_em_block
		//EMISSIVE CODE END

	//No need to handle leg layering if dropped, we only face south anyways
	if(!dropped && ((body_zone == BODY_ZONE_R_LEG) || (body_zone == BODY_ZONE_L_LEG)))
		//Legs are a bit goofy in regards to layering, and we will need two images instead of one to fix that
		var/obj/item/bodypart/leg/leg_source = src
		for(var/image/limb_image in .)
			//remove the old, unmasked image
			. -= limb_image
			//add two masked images based on the old one
			. += leg_source.generate_masked_leg(limb_image, image_dir)

	// And finally put bodypart_overlays on if not husked
	if(!is_husked)
		//Draw external organs like horns and frills
		for(var/datum/bodypart_overlay/overlay as anything in bodypart_overlays)
			if(!dropped && !overlay.can_draw_on_bodypart(owner)) //if you want different checks for dropped bodyparts, you can insert it here
				continue
			//Some externals have multiple layers for background, foreground and between
			for(var/external_layer in overlay.all_layers)
				if(overlay.layers & external_layer)
					. += overlay.get_overlay(external_layer, src)
			for(var/datum/layer in .)
				overlay.modify_bodypart_appearance(layer)
	return .

/obj/item/bodypart/proc/huskify_image(image/thing_to_husk, draw_blood = TRUE)
	var/icon/husk_icon = new(thing_to_husk.icon)
	husk_icon.ColorTone(HUSK_COLOR_TONE)
	thing_to_husk.icon = husk_icon
	if(draw_blood)
		var/mutable_appearance/husk_blood = mutable_appearance(icon_husk, "[husk_type]_husk_[body_zone]")
		husk_blood.blend_mode = BLEND_INSET_OVERLAY
		husk_blood.appearance_flags |= RESET_COLOR
		husk_blood.dir = thing_to_husk.dir
		thing_to_husk.add_overlay(husk_blood)

///Add a bodypart overlay and call the appropriate update procs
/obj/item/bodypart/proc/add_bodypart_overlay(datum/bodypart_overlay/overlay, update = TRUE)
	bodypart_overlays += overlay
	overlay.added_to_limb(src)
	if(!update)
		return
	if(!owner)
		update_icon_dropped()
	else if(!(owner.living_flags & STOP_OVERLAY_UPDATE_BODY_PARTS))
		owner.update_body_parts()

///Remove a bodypart overlay and call the appropriate update procs
/obj/item/bodypart/proc/remove_bodypart_overlay(datum/bodypart_overlay/overlay, update = TRUE)
	bodypart_overlays -= overlay
	overlay.removed_from_limb(src)
	if(!update)
		return
	if(!owner)
		update_icon_dropped()
	else if(!(owner.living_flags & STOP_OVERLAY_UPDATE_BODY_PARTS))
		owner.update_body_parts()

/obj/item/bodypart/atom_deconstruct(disassembled = TRUE)
	SHOULD_CALL_PARENT(TRUE)

	drop_organs()

	return ..()

/// INTERNAL PROC, DO NOT USE
/// Properly sets us up to manage an inserted embeded object
/obj/item/bodypart/proc/_embed_object(obj/item/embed)
	if(embed in embedded_objects) // go away
		return
	// We don't need to do anything with projectile embedding, because it will never reach this point
	embedded_objects += embed
	RegisterSignal(embed, COMSIG_ITEM_EMBEDDING_UPDATE, PROC_REF(embedded_object_changed))
	refresh_bleed_rate()

/// INTERNAL PROC, DO NOT USE
/// Cleans up any attachment we have to the embedded object, removes it from our list
/obj/item/bodypart/proc/_unembed_object(obj/item/unembed)
	embedded_objects -= unembed
	UnregisterSignal(unembed, COMSIG_ITEM_EMBEDDING_UPDATE)
	refresh_bleed_rate()

/obj/item/bodypart/proc/embedded_object_changed(obj/item/embedded_source)
	SIGNAL_HANDLER
	/// Embedded objects effect bleed rate, gotta refresh lads
	refresh_bleed_rate()

/// Sets our generic bleedstacks
/obj/item/bodypart/proc/setBleedStacks(set_to)
	SHOULD_CALL_PARENT(TRUE)
	adjustBleedStacks(set_to - generic_bleedstacks)

/// Modifies our generic bleedstacks. You must use this to change the variable
/// Takes the amount to adjust by, and the lowest amount we're allowed to have post adjust
/obj/item/bodypart/proc/adjustBleedStacks(adjust_by, minimum = -INFINITY)
	if(!adjust_by)
		return
	var/old_bleedstacks = generic_bleedstacks
	generic_bleedstacks = max(generic_bleedstacks + adjust_by, minimum)

	// If we've started or stopped bleeding, we need to refresh our bleed rate
	if((old_bleedstacks <= 0 && generic_bleedstacks > 0) \
		|| old_bleedstacks > 0 && generic_bleedstacks <= 0)
		refresh_bleed_rate()

/obj/item/bodypart/proc/on_owner_nobleed_loss(datum/source)
	SIGNAL_HANDLER
	refresh_bleed_rate()

/obj/item/bodypart/proc/on_owner_nobleed_gain(datum/source)
	SIGNAL_HANDLER
	refresh_bleed_rate()

/// Refresh the cache of our rate of bleeding sans any modifiers
/// ANYTHING ADDED TO THIS PROC NEEDS TO CALL IT WHEN ITS EFFECT CHANGES
/obj/item/bodypart/proc/refresh_bleed_rate()
	SHOULD_NOT_OVERRIDE(TRUE)

	var/old_bleed_rate = cached_bleed_rate
	cached_bleed_rate = 0
	if(!owner)
		return

	if(!can_bleed())
		if(cached_bleed_rate != old_bleed_rate)
			update_part_wound_overlay()
		return

	if(generic_bleedstacks > 0)
		cached_bleed_rate += 0.5

	for(var/obj/item/embeddies as anything in embedded_objects)
		if(!embeddies.get_embed().is_harmless())
			cached_bleed_rate += 0.25

	for(var/datum/wound/iter_wound as anything in wounds)
		cached_bleed_rate += iter_wound.blood_flow

	// Our bleed overlay is based directly off bleed_rate, so go aheead and update that would you?
	if(cached_bleed_rate != old_bleed_rate)
		update_part_wound_overlay()

	return cached_bleed_rate

/// Returns our bleed rate, taking into account laying down and grabbing the limb
/obj/item/bodypart/proc/get_modified_bleed_rate()
	var/bleed_rate = cached_bleed_rate
	if(owner.body_position == LYING_DOWN)
		bleed_rate *= 0.75
	if(grasped_by)
		bleed_rate *= 0.7
	return bleed_rate

/obj/item/bodypart/proc/update_part_wound_overlay()
	if(!owner)
		return FALSE
	if(!can_bleed())
		if(bleed_overlay_icon)
			bleed_overlay_icon = null
			owner.update_wound_overlays()
		return FALSE

	if (SEND_SIGNAL(src, COMSIG_BODYPART_UPDATE_WOUND_OVERLAY, cached_bleed_rate) & COMPONENT_PREVENT_WOUND_OVERLAY_UPDATE)
		return

	var/bleed_rate = cached_bleed_rate
	var/new_bleed_icon = null

	switch(bleed_rate)
		if(-INFINITY to BLEED_OVERLAY_LOW)
			new_bleed_icon = null
		if(BLEED_OVERLAY_LOW to BLEED_OVERLAY_MED)
			new_bleed_icon = "[body_zone]_1"
		if(BLEED_OVERLAY_MED to BLEED_OVERLAY_GUSH)
			if(owner.body_position == LYING_DOWN || HAS_TRAIT(owner, TRAIT_STASIS) || owner.stat == DEAD)
				new_bleed_icon = "[body_zone]_2s"
			else
				new_bleed_icon = "[body_zone]_2"
		if(BLEED_OVERLAY_GUSH to INFINITY)
			if(HAS_TRAIT(owner, TRAIT_STASIS) || owner.stat == DEAD)
				new_bleed_icon = "[body_zone]_2s"
			else
				new_bleed_icon = "[body_zone]_3"

	if(new_bleed_icon != bleed_overlay_icon)
		bleed_overlay_icon = new_bleed_icon
		owner.update_wound_overlays()

/obj/item/bodypart/proc/can_bleed()
	SHOULD_BE_PURE(TRUE)

	return ((biological_state & BIO_BLOODED) && (!owner || !HAS_TRAIT(owner, TRAIT_NOBLOOD)))

/**
 * apply_gauze() is used to- well, apply gauze to a bodypart
 *
 * As of the Wounds 2 PR, all bleeding is now bodypart based rather than the old bleedstacks system, and 90% of standard bleeding comes from flesh wounds (the exception is embedded weapons).
 * The same way bleeding is totaled up by bodyparts, gauze now applies to all wounds on the same part. Thus, having a slash wound, a pierce wound, and a broken bone wound would have the gauze
 * applying blood staunching to the first two wounds, while also acting as a sling for the third one. Once enough blood has been absorbed or all wounds with the ACCEPTS_GAUZE flag have been cleared,
 * the gauze falls off.
 *
 * Arguments:
 * * gauze- Just the gauze stack we're taking a sheet from to apply here
 */
/obj/item/bodypart/proc/apply_gauze(obj/item/stack/medical/gauze/new_gauze)
	if(!istype(new_gauze) || !new_gauze.absorption_capacity || !new_gauze.use(1))
		return
	var/newly_gauzed = !current_gauze
	QDEL_NULL(current_gauze)
	current_gauze = new new_gauze.type(src, 1)
	current_gauze.gauzed_bodypart = src
	if(newly_gauzed)
		SEND_SIGNAL(src, COMSIG_BODYPART_GAUZED, current_gauze, new_gauze)

/**
 * seep_gauze() is for when a gauze wrapping absorbs blood or pus from wounds, lowering its absorption capacity.
 *
 * The passed amount of seepage is deducted from the bandage's absorption capacity, and if we reach a negative absorption capacity, the bandages falls off and we're left with nothing.
 *
 * Arguments:
 * * seep_amt - How much absorption capacity we're removing from our current bandages (think, how much blood or pus are we soaking up this tick?)
 */
/obj/item/bodypart/proc/seep_gauze(seep_amt = 0)
	if(!current_gauze)
		return
	current_gauze.absorption_capacity -= seep_amt
	if(current_gauze.absorption_capacity <= 0)
		owner.visible_message(span_danger("\The [current_gauze.name] on [owner]'s [name] falls away in rags."), span_warning("\The [current_gauze.name] on your [name] falls away in rags."), vision_distance=COMBAT_MESSAGE_RANGE)
		QDEL_NULL(current_gauze)

///A multi-purpose setter for all things immediately important to the icon and iconstate of the limb.
/obj/item/bodypart/proc/change_appearance(icon, id, greyscale, dimorphic)
	var/icon_holder
	if(greyscale)
		icon_greyscale = icon
		icon_holder = icon
		should_draw_greyscale = TRUE
	else
		icon_static = icon
		icon_holder = icon
		should_draw_greyscale = FALSE

	if(id) //limb_id should never be falsey
		limb_id = id

	if(!isnull(dimorphic))
		is_dimorphic = dimorphic

	if(!owner)
		update_icon_dropped()
	else if(!(owner.living_flags & STOP_OVERLAY_UPDATE_BODY_PARTS))
		owner.update_body_parts()

	//This foot gun needs a safety
	if(!icon_exists(icon_holder, "[limb_id]_[body_zone][is_dimorphic ? "_[limb_gender]" : ""]"))
		reset_appearance()
		stack_trace("change_appearance([icon], [id], [greyscale], [dimorphic]) generated null icon")

///Resets the base appearance of a limb to it's default values.
/obj/item/bodypart/proc/reset_appearance()
	icon_static = initial(icon_static)
	icon_greyscale = initial(icon_greyscale)
	limb_id = initial(limb_id)
	is_dimorphic = initial(is_dimorphic)
	should_draw_greyscale = initial(should_draw_greyscale)

	if(!owner)
		update_icon_dropped()
	else if(!(owner.living_flags & STOP_OVERLAY_UPDATE_BODY_PARTS))
		owner.update_body_parts()

// Note: For effects on subtypes, use the emp_effect() proc instead
/obj/item/bodypart/emp_act(severity)
	var/protection = ..()
	// If the limb doesn't protect contents, strike them first
	if(!(protection & EMP_PROTECT_CONTENTS))
		for(var/atom/content as anything in contents)
			content.emp_act(severity)

	if((protection & (EMP_PROTECT_WIRES | EMP_PROTECT_SELF)))
		return protection

	emp_effect(severity, protection)
	return protection

/// The actual effect of EMPs on the limb. Allows children to override it however they want
/obj/item/bodypart/proc/emp_effect(severity, protection)
	if(!IS_ROBOTIC_LIMB(src))
		return FALSE
	// with defines at the time of writing, this is 2 brute and 1.5 burn
	// 2 + 1.5 = 3,5, with 6 limbs thats 21, on a heavy 42
	// 42 * 0.8 = 33.6
	// 3 hits to crit with an ion rifle on someone fully augged at a total of 100.8 damage, although im p sure mood can boost max hp above 100
	// dont forget emps pierce armor, debilitate augs, and usually comes with splash damage e.g. ion rifles or grenades
	var/time_needed = AUGGED_LIMB_EMP_PARALYZE_TIME
	var/brute_damage = AUGGED_LIMB_EMP_BRUTE_DAMAGE
	var/burn_damage = AUGGED_LIMB_EMP_BURN_DAMAGE
	if(severity == EMP_HEAVY)
		time_needed *= 2
		brute_damage *= 2
		burn_damage *= 2

	receive_damage(brute_damage, burn_damage)
	do_sparks(number = 1, cardinal_only = FALSE, source = owner || src)

	if(can_be_disabled && (get_damage() / max_damage) >= robotic_emp_paralyze_damage_percent_threshold)
		ADD_TRAIT(src, TRAIT_PARALYSIS, EMP_TRAIT)
		addtimer(TRAIT_CALLBACK_REMOVE(src, TRAIT_PARALYSIS, EMP_TRAIT), time_needed)
		owner?.visible_message(span_danger("[owner]'s [plaintext_zone] seems to malfunction!"))

	return TRUE

/// Returns the generic description of our BIO_EXTERNAL feature(s), prioritizing certain ones over others. Returns error on failure.
/obj/item/bodypart/proc/get_external_description()
	if (biological_state & BIO_FLESH)
		return "flesh"
	if (biological_state & BIO_WIRED)
		return "wiring"

	return "error"

/// Returns the generic description of our BIO_INTERNAL feature(s), prioritizing certain ones over others. Returns error on failure.
/obj/item/bodypart/proc/get_internal_description()
	if (biological_state & BIO_BONE)
		return "bone"
	if (biological_state & BIO_METAL)
		return "metal"

	return "error"
