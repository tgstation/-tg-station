/// Anything you can pick up and hold.
/obj/item
	name = "item"
	icon = 'icons/obj/anomaly.dmi'
	blocks_emissive = EMISSIVE_BLOCK_GENERIC
	burning_particles = /particles/smoke/burning/small
	pass_flags_self = PASSITEM

	/* !!!!!!!!!!!!!!! IMPORTANT !!!!!!!!!!!!!!

		IF YOU ADD MORE ICON CRAP TO THIS
		ENSURE YOU ALSO ADD THE NEW VARS TO CHAMELEON ITEM_ACTION'S update_item() PROC (/datum/action/item_action/chameleon/change/proc/update_item())
		WASHING MASHINE'S dye_item() PROC (/obj/item/proc/dye_item())
		AND ALSO TO THE CHANGELING PROFILE DISGUISE SYSTEMS (/datum/changeling_profile / /datum/antagonist/changeling/proc/create_profile() / /proc/changeling_transform())

		!!!!!!!!!!!!!!! IMPORTANT !!!!!!!!!!!!!! */

	///icon state for inhand overlays.
	var/inhand_icon_state = null
	///Icon file for left hand inhand overlays
	var/lefthand_file = 'icons/mob/inhands/items_lefthand.dmi'
	///Icon file for right inhand overlays
	var/righthand_file = 'icons/mob/inhands/items_righthand.dmi'

	/// Angle of the icon, used for piercing and slashing attack animations, clockwise from *east-facing* sprites
	var/icon_angle = 0
	///icon file for an alternate attack icon
	var/attack_icon
	///icon state for an alternate attack icon
	var/attack_icon_state

	///Icon file for mob worn overlays.
	var/icon/worn_icon
	///Icon state for mob worn overlays, if null the normal icon_state will be used.
	var/worn_icon_state
	///Icon state for the belt overlay, if null the normal icon_state will be used.
	var/inside_belt_icon_state
	///Forced mob worn layer instead of the standard preferred size.
	var/alternate_worn_layer
	///The config type to use for greyscaled worn sprites. Both this and greyscale_colors must be assigned to work.
	var/greyscale_config_worn
	///The config type to use for greyscaled left inhand sprites. Both this and greyscale_colors must be assigned to work.
	var/greyscale_config_inhand_left
	///The config type to use for greyscaled right inhand sprites. Both this and greyscale_colors must be assigned to work.
	var/greyscale_config_inhand_right
	///The config type to use for greyscaled belt overlays. Both this and greyscale_colors must be assigned to work.
	var/greyscale_config_belt

	/* !!!!!!!!!!!!!!! IMPORTANT !!!!!!!!!!!!!!

		IF YOU ADD MORE ICON CRAP TO THIS
		ENSURE YOU ALSO ADD THE NEW VARS TO CHAMELEON ITEM_ACTION'S update_item() PROC (/datum/action/item_action/chameleon/change/proc/update_item())
		WASHING MASHINE'S dye_item() PROC (/obj/item/proc/dye_item())
		AND ALSO TO THE CHANGELING PROFILE DISGUISE SYSTEMS (/datum/changeling_profile / /datum/antagonist/changeling/proc/create_profile() / /proc/changeling_transform())

		!!!!!!!!!!!!!!! IMPORTANT !!!!!!!!!!!!!! */

	///Dimensions of the icon file used when this item is worn, eg: hats.dmi (32x32 sprite, 64x64 sprite, etc.). Allows inhands/worn sprites to be of any size, but still centered on a mob properly
	var/worn_x_dimension = 32
	///Dimensions of the icon file used when this item is worn, eg: hats.dmi (32x32 sprite, 64x64 sprite, etc.). Allows inhands/worn sprites to be of any size, but still centered on a mob properly
	var/worn_y_dimension = 32
	///Same as for [worn_x_dimension][/obj/item/var/worn_x_dimension] but for inhands, uses the lefthand_ and righthand_ file vars
	var/inhand_x_dimension = 32
	///Same as for [worn_y_dimension][/obj/item/var/worn_y_dimension] but for inhands, uses the lefthand_ and righthand_ file vars
	var/inhand_y_dimension = 32
	/// Worn overlay will be shifted by this along y axis
	var/worn_y_offset = 0

	max_integrity = 200

	obj_flags = NONE
	///Item flags for the item
	var/item_flags = NONE

	///Sound played when you hit something with the item
	var/hitsound
	///Played when the item is used, for example tools
	var/usesound
	///Played when item is used for long progress
	var/operating_sound
	///Used when yate into a mob
	var/mob_throw_hit_sound
	///Sound used when equipping the item into a valid slot
	var/equip_sound
	///Sound uses when picking the item up (into your hands)
	var/pickup_sound
	///Sound uses when dropping the item, or when its thrown if a thrown sound isn't specified.
	var/drop_sound
	///Sound used on impact when the item is thrown.
	var/throw_drop_sound
	///Do the drop and pickup sounds vary?
	var/sound_vary = FALSE
	///Whether or not we use stealthy audio levels for this item's attack sounds
	var/stealthy_audio = FALSE
	///Sound which is produced when blocking an attack
	var/block_sound

	///How large is the object, used for stuff like whether it can fit in backpacks or not
	var/w_class = WEIGHT_CLASS_NORMAL
	///This is used to determine on which slots an item can fit.
	var/slot_flags = 0
	pass_flags = PASSTABLE
	pressure_resistance = 4
	/// This var exists as a weird proxy "owner" ref
	/// It's used in a few places. Stop using it, and optimially replace all uses please
	var/obj/item/master = null

	///Price of an item in a vending machine, overriding the base vending machine price. Define in terms of paycheck defines as opposed to raw numbers.
	var/custom_price
	///Price of an item in a vending machine, overriding the premium vending machine price. Define in terms of paycheck defines as opposed to raw numbers.
	var/custom_premium_price
	///Whether spessmen with an ID with an age below AGE_MINOR (20 by default) can buy this item
	var/age_restricted = FALSE

	///flags which determine which body parts are protected from heat. [See here][HEAD]
	var/heat_protection = 0
	///flags which determine which body parts are protected from cold. [See here][HEAD]
	var/cold_protection = 0
	///Set this variable to determine up to which temperature (IN KELVIN) the item protects against heat damage. Keep at null to disable protection. Only protects areas set by heat_protection flags
	var/max_heat_protection_temperature
	///Set this variable to determine down to which temperature (IN KELVIN) the item protects against cold damage. 0 is NOT an acceptable number due to if(varname) tests!! Keep at null to disable protection. Only protects areas set by cold_protection flags
	var/min_cold_protection_temperature

	///list of /datum/action's that this item has.
	var/list/datum/action/actions
	///list of paths of action datums to give to the item on New().
	var/list/actions_types

	//Since any item can now be a piece of clothing, this has to be put here so all items share it.
	///This flag is used to determine when items in someone's inventory cover others. IE helmets making it so you can't see glasses, etc.
	var/flags_inv
	///you can see someone's mask through their transparent visor, but you can't reach it
	var/transparent_protection = NONE
	///Name of a mask in icons\mob\human\hair_masks.dmi to apply to hair when this item is worn
	///Used by certain hats to give the appearance of squishing down tall hairstyles without hiding the hair completely
	var/hair_mask = ""

	///flags for what should be done when you click on the item, default is picking it up
	var/interaction_flags_item = INTERACT_ITEM_ATTACK_HAND_PICKUP

	///What body parts are covered by the clothing when you wear it
	var/body_parts_covered = 0
	/// for electrical admittance/conductance (electrocution checks and shit)
	var/siemens_coefficient = 1
	/// How much clothing is slowing you down. Negative values speeds you up
	var/slowdown = 0
	///percentage of armour effectiveness to remove
	var/armour_penetration = 0
	///Whether or not our object doubles the value of affecting armour
	var/weak_against_armour = FALSE
	/// The click cooldown given after attacking. Lower numbers means faster attacks
	var/attack_speed = CLICK_CD_MELEE
	/// The click cooldown on secondary attacks. Lower numbers mean faster attacks. Will use attack_speed if undefined.
	var/secondary_attack_speed
	///In deciseconds, how long an item takes to equip; counts only for normal clothing slots, not pockets etc.
	var/equip_delay_self = 0
	///In deciseconds, how long an item takes to put on another person
	var/equip_delay_other = 20
	///In deciseconds, how long an item takes to remove from another person
	var/strip_delay = 40
	///How long it takes to resist out of the item (cuffs and such)
	var/breakouttime = 0

	///Used in [atom/proc/attackby] to say how something was attacked `"[x] has been [z.attack_verb] by [y] with [z]"`
	var/list/attack_verb_continuous
	var/list/attack_verb_simple
	///list() of species types, if a species cannot put items in a certain slot, but species type is in list, it will be able to wear that item
	var/list/species_exception = null
	///This is a bitfield that defines what variations exist for bodyparts like Digi legs. See: code\_DEFINES\inventory.dm
	var/supports_variations_flags = NONE

	///A weakref to the mob who threw the item
	var/datum/weakref/thrownby = null //I cannot verbally describe how much I hate this var
	///Items can by default thrown up to 10 tiles by TK users
	tk_throw_range = 10

	///the icon to indicate this object is being dragged
	mouse_drag_pointer = MOUSE_ACTIVE_POINTER

	/// Does it embed and if yes, what kind of embed
	var/embed_type
	/// Stores embedding data
	VAR_PROTECTED/datum/embedding/embed_data

	///for flags such as [GLASSESCOVERSEYES]
	var/flags_cover = 0
	var/heat = 0
	/// All items with sharpness of SHARP_EDGED or higher will automatically get the butchering component.
	var/sharpness = NONE

	///How a tool acts when you use it on something, such as wirecutters cutting wires while multitools measure power
	var/tool_behaviour = null

	///How fast does the tool work
	var/toolspeed = 1

	///Chance of blocking incoming attack
	var/block_chance = 0
	///Effect of blocking
	var/block_effect = /obj/effect/temp_visual/block
	var/hit_reaction_chance = 0 //If you want to have something unrelated to blocking/armour piercing etc. Maybe not needed, but trying to think ahead/allow more freedom
	///In tiles, how far this weapon can reach; 1 for adjacent, which is default
	var/reach = 1

	///The list of slots by priority. equip_to_appropriate_slot() uses this list. Doesn't matter if a mob type doesn't have a slot. For default list, see [/mob/proc/equip_to_appropriate_slot]
	var/list/slot_equipment_priority = null

	///Reference to the datum that determines whether dogs can wear the item: Needs to be in /obj/item because corgis can wear a lot of non-clothing items
	var/datum/dog_fashion/dog_fashion = null

	//Tooltip vars
	///string form of an item's force. Edit this var only to set a custom force string
	var/force_string
	var/last_force_string_check = 0
	var/tip_timer

	///Determines who can shoot this
	var/trigger_guard = TRIGGER_GUARD_NONE

	///Used as the dye color source in the washing machine only (at the moment). Can be a hex color or a key corresponding to a registry entry, see washing_machine.dm
	var/dye_color
	///Whether the item is unaffected by standard dying.
	var/undyeable = FALSE
	///What dye registry should be looked at when dying this item; see washing_machine.dm
	var/dying_key

	///Grinder var:A reagent list containing the reagents this item produces when ground up in a grinder - this can be an empty list to allow for reagent transferring only
	var/list/grind_results
	///A reagent the nutriments are converted into when the item is juiced.
	var/datum/reagent/consumable/juice_typepath

	/// Used in obj/item/examine to give additional notes on what the weapon does, separate from the predetermined output variables
	var/offensive_notes
	/// Used in obj/item/examine to determines whether or not to detail an item's statistics even if it does not meet the force requirements
	var/override_notes = FALSE
	/// Used if we want to have a custom verb text for throwing. "John Spaceman flicks the ciggerate" for example.
	var/throw_verb

	/// A lazylist used for applying fantasy values, contains the actual modification applied to a variable.
	var/list/fantasy_modifications = null

	/// Has the item been reskinned?
	var/current_skin
	/// List of options to reskin.
	var/list/unique_reskin
	/// If reskins change base icon state as well
	var/unique_reskin_changes_base_icon_state = FALSE
	/// If reskins change inhands as well
	var/unique_reskin_changes_inhand = FALSE
	/// Do we apply a click cooldown when resisting this object if it is restraining them?
	var/resist_cooldown = CLICK_CD_BREAKOUT

/obj/item/Initialize(mapload)
	if(attack_verb_continuous)
		attack_verb_continuous = string_list(attack_verb_continuous)
	if(attack_verb_simple)
		attack_verb_simple = string_list(attack_verb_simple)
	if(species_exception)
		species_exception = string_list(species_exception)

	if(sharpness && force > 5) //give sharp objects butchering functionality, for consistency
		AddComponent(/datum/component/butchering, speed = 8 SECONDS * toolspeed)

	if(!greyscale_config && greyscale_colors && (greyscale_config_worn || greyscale_config_belt || greyscale_config_inhand_right || greyscale_config_inhand_left))
		update_greyscale()

	. = ..()

	// Handle adding item associated actions
	for(var/path in actions_types)
		add_item_action(path)
	actions_types = null

	if(force_string)
		item_flags |= FORCE_STRING_OVERRIDE

	if(!hitsound)
		if(damtype == BURN)
			hitsound = 'sound/items/tools/welder.ogg'
		if(damtype == BRUTE)
			hitsound = SFX_SWING_HIT

	add_weapon_description()

	SEND_GLOBAL_SIGNAL(COMSIG_GLOB_NEW_ITEM, src)

	setup_reskinning()


/obj/item/Destroy(force)
	// This var exists as a weird proxy "owner" ref
	// It's used in a few places. Stop using it, and optimially replace all uses please
	master = null
	if(ismob(loc))
		var/mob/m = loc
		m.temporarilyRemoveItemFromInventory(src, TRUE)

	// Handle cleaning up our actions list
	for(var/datum/action/action as anything in actions)
		remove_item_action(action)

	return ..()


/obj/item/add_context(atom/source, list/context, obj/item/held_item, mob/user)
	. = ..()

	if(!unique_reskin)
		return

	if(current_skin && !(obj_flags & INFINITE_RESKIN))
		return

	context[SCREENTIP_CONTEXT_ALT_LMB] = "Reskin"
	return CONTEXTUAL_SCREENTIP_SET

/obj/item/click_ctrl(mob/user)
	SHOULD_NOT_OVERRIDE(TRUE)

	//If the item is on the ground & not anchored we allow the player to drag it
	. = item_ctrl_click(user)
	if(. & CLICK_ACTION_ANY)
		return (isturf(loc) && !anchored) ? NONE : . //allow the object to get dragged on the floor

/// Subtypes only override this proc for ctrl click purposes. obeys same principles as ctrl_click()
/obj/item/proc/item_ctrl_click(mob/user)
	SHOULD_CALL_PARENT(FALSE)
	return NONE

/// Called when an action associated with our item is deleted
/obj/item/proc/on_action_deleted(datum/source)
	SIGNAL_HANDLER

	if(!(source in actions))
		CRASH("An action ([source.type]) was deleted that was associated with an item ([src]), but was not found in the item's actions list.")

	LAZYREMOVE(actions, source)

/// Adds an item action to our list of item actions.
/// Item actions are actions linked to our item, that are granted to mobs who equip us.
/// This also ensures that the actions are properly tracked in the actions list and removed if they're deleted.
/// Can be be passed a typepath of an action or an instance of an action.
/obj/item/proc/add_item_action(action_or_action_type)

	var/datum/action/action
	if(ispath(action_or_action_type, /datum/action))
		action = new action_or_action_type(src)
	else if(istype(action_or_action_type, /datum/action))
		action = action_or_action_type
	else
		CRASH("item add_item_action got a type or instance of something that wasn't an action.")

	LAZYADD(actions, action)
	RegisterSignal(action, COMSIG_QDELETING, PROC_REF(on_action_deleted))
	grant_action_to_bearer(action)
	return action

/// Grant the action to anyone who has this item equipped to an appropriate slot
/obj/item/proc/grant_action_to_bearer(datum/action/action)
	if(!ismob(loc))
		return
	var/mob/holder = loc
	give_item_action(action, holder, holder.get_slot_by_item(src))

/// Removes an instance of an action from our list of item actions.
/obj/item/proc/remove_item_action(datum/action/action)
	if(!action)
		return

	UnregisterSignal(action, COMSIG_QDELETING)
	LAZYREMOVE(actions, action)
	qdel(action)

/// Called if this item is supposed to be a steal objective item objective.
/obj/item/proc/add_stealing_item_objective()
	return

/// Adds the weapon_description element, which shows the 'warning label' for especially dangerous objects. Override this for item types with special notes.
/obj/item/proc/add_weapon_description()
	AddElement(/datum/element/weapon_description)

/**
 * Checks if an item is allowed to be used on an atom/target
 * Returns TRUE if allowed.
 *
 * Args:
 * target_self - Whether we will check if we (src) are in target, preventing people from using items on themselves.
 * not_inside - Whether target (or target's loc) has to be a turf.
 */
/obj/item/proc/check_allowed_items(atom/target, not_inside = FALSE, target_self = FALSE)
	if(!target_self && (src in target))
		return FALSE
	if(not_inside && !isturf(target.loc) && !isturf(target))
		return FALSE
	return TRUE

/obj/item/blob_act(obj/structure/blob/B)
	if(B && B.loc == loc)
		atom_destruction(MELEE)

/**Makes cool stuff happen when you suicide with an item
 *
 *Outputs a creative message and then return the damagetype done
 * Arguments:
 * * user: The mob that is suiciding
 */
/obj/item/proc/suicide_act(mob/living/user)
	return

/obj/item/set_greyscale(list/colors, new_config, new_worn_config, new_inhand_left, new_inhand_right)
	if(new_worn_config)
		greyscale_config_worn = new_worn_config
	if(new_inhand_left)
		greyscale_config_inhand_left = new_inhand_left
	if(new_inhand_right)
		greyscale_config_inhand_right = new_inhand_right
	return ..()

/// Checks if this atom uses the GAGS system and if so updates the worn and inhand icons
/obj/item/update_greyscale()
	. = ..()
	if(!greyscale_colors)
		return
	if(greyscale_config_worn)
		worn_icon = SSgreyscale.GetColoredIconByType(greyscale_config_worn, greyscale_colors)
	if(greyscale_config_inhand_left)
		lefthand_file = SSgreyscale.GetColoredIconByType(greyscale_config_inhand_left, greyscale_colors)
	if(greyscale_config_inhand_right)
		righthand_file = SSgreyscale.GetColoredIconByType(greyscale_config_inhand_right, greyscale_colors)

/obj/item/verb/move_to_top()
	set name = "Move To Top"
	set category = "Object"
	set src in oview(1)

	if(!isturf(loc) || usr.stat != CONSCIOUS || HAS_TRAIT(usr, TRAIT_HANDS_BLOCKED))
		return

	if(isliving(usr))
		var/mob/living/L = usr
		if(!(L.mobility_flags & MOBILITY_PICKUP))
			return

	var/turf/T = loc
	abstract_move(null)
	forceMove(T)

/obj/item/examine_tags(mob/user)
	var/list/parent_tags = ..()
	parent_tags.Insert(1, weight_class_to_text(w_class)) // To make size display first, otherwise it looks goofy
	. = parent_tags
	.[weight_class_to_text(w_class)] = weight_class_to_tooltip(w_class)

	if(item_flags & CRUEL_IMPLEMENT)
		.[span_red("morbid")] = "It seems quite practical for particularly morbid procedures and experiments."

	if (siemens_coefficient == 0)
		.["insulated"] = "It is made from a robust electrical insulator and will block any electricity passing through it!"
	else if (siemens_coefficient <= 0.5)
		.["partially insulated"] = "It is made from a poor insulator that will dampen (but not fully block) electric shocks passing through it."

	if(resistance_flags & INDESTRUCTIBLE)
		.["indestructible"] = "It is extremely robust! It'll probably withstand anything that could happen to it!"
		return

	if(resistance_flags & LAVA_PROOF)
		.["lavaproof"] = "It is made of an extremely heat-resistant material, it'd probably be able to withstand lava!"
	if(resistance_flags & (ACID_PROOF | UNACIDABLE))
		.["acidproof"] = "It looks pretty robust! It'd probably be able to withstand acid!"
	if(resistance_flags & FREEZE_PROOF)
		.["freezeproof"] = "It is made of cold-resistant materials."
	if(resistance_flags & FIRE_PROOF)
		.["fireproof"] = "It is made of fire-retardant materials."

/obj/item/examine_descriptor(mob/user)
	return "item"

/obj/item/examine_more(mob/user)
	. = ..()
	if(HAS_TRAIT(user, TRAIT_RESEARCH_SCANNER))
		. += research_scan(user)

/obj/item/proc/research_scan(mob/user)
	/// Research prospects, including boostable nodes and point values. Deliver to a console to know whether the boosts have already been used.
	var/list/research_msg = list("<font color='purple'>Research prospects:</font> ")
	///Separator between the items on the list
	var/sep = ""
	///Nodes that can be boosted
	var/list/boostable_nodes = techweb_item_unlock_check(src)
	if (boostable_nodes)
		for(var/id in boostable_nodes)
			var/datum/techweb_node/node = SSresearch.techweb_node_by_id(id)
			if(!node)
				continue
			research_msg += sep
			research_msg += node.display_name
			sep = ", "
	var/list/points = techweb_item_point_check(src)
	if (length(points))
		sep = ", "
		research_msg += techweb_point_display_generic(points)

	if (!sep) // nothing was shown
		research_msg += "None"

	// Extractable materials. Only shows the names, not the amounts.
	research_msg += ".<br><font color='purple'>Extractable materials:</font> "
	if (length(custom_materials))
		sep = ""
		for(var/mat in custom_materials)
			research_msg += sep
			research_msg += CallMaterialName(mat)
			sep = ", "
	else
		research_msg += "None"
	research_msg += "."
	return research_msg.Join()

/obj/item/interact(mob/user)
	add_fingerprint(user)
	ui_interact(user)

/obj/item/ui_act(action, list/params, datum/tgui/ui, datum/ui_state/state)
	add_fingerprint(usr)
	return ..()

/obj/item/vv_do_topic(list/href_list)
	. = ..()

	if(!.)
		return

	if(href_list[VV_HK_ADD_FANTASY_AFFIX])
		if(!check_rights(R_FUN))
			return
		//gathering all affixes that make sense for this item
		var/list/prefixes = list()
		var/list/suffixes = list()
		for(var/datum/fantasy_affix/affix_choice as anything in subtypesof(/datum/fantasy_affix))
			affix_choice = new affix_choice()
			if(!affix_choice.validate(src))
				qdel(affix_choice)
			else
				if(affix_choice.placement & AFFIX_PREFIX)
					prefixes[affix_choice.name] = affix_choice
				else
					suffixes[affix_choice.name] = affix_choice
		//making it more presentable here
		var/list/affixes = list("---PREFIXES---")
		affixes.Add(prefixes)
		affixes.Add("---SUFFIXES---")
		affixes.Add(suffixes)
		//admin picks, cleanup the ones we didn't do and handle chosen
		var/picked_affix_name = tgui_input_list(usr, "Affix to add to [src]", "Enchant [src]", affixes)
		if(isnull(picked_affix_name))
			return
		if(!affixes[picked_affix_name] || QDELETED(src))
			return
		var/datum/fantasy_affix/affix = affixes[picked_affix_name]
		affixes.Remove(affix)
		var/fantasy_quality = 0
		if(affix.alignment & AFFIX_GOOD)
			fantasy_quality++
		else
			fantasy_quality--
		//name gets changed by the component so i want to store it for feedback later
		var/before_name = name
		//naming these vars that i'm putting into the fantasy component to make it more readable
		var/canFail = FALSE
		var/announce = FALSE
		//Apply fantasy with affix. failing this should never happen, but if it does it should not be silent.
		if(AddComponent(/datum/component/fantasy, fantasy_quality, list(affix), canFail, announce) == COMPONENT_INCOMPATIBLE)
			to_chat(usr, span_warning("Fantasy component not compatible with [src]."))
			CRASH("fantasy component incompatible with object of type: [type]")
		to_chat(usr, span_notice("[before_name] now has [picked_affix_name]!"))
		log_admin("[key_name(usr)] has added [picked_affix_name] fantasy affix to [before_name]")
		message_admins(span_notice("[key_name(usr)] has added [picked_affix_name] fantasy affix to [before_name]"))

/obj/item/attack_hand(mob/user, list/modifiers)
	. = ..()
	if(. || !user || anchored)
		return
	return attempt_pickup(user)

/obj/item/proc/attempt_pickup(mob/user, skip_grav = FALSE)
	. = TRUE

	if(!(interaction_flags_item & INTERACT_ITEM_ATTACK_HAND_PICKUP)) //See if we're supposed to auto pickup.
		return

	if(!skip_grav)
		//Heavy gravity makes picking up things very slow.
		var/grav = user.has_gravity()
		if(grav > STANDARD_GRAVITY)
			var/grav_power = min(3,grav - STANDARD_GRAVITY)
			to_chat(user,span_notice("You start picking up [src]..."))
			if(!do_after(user, 30 * grav_power, src))
				return

	//If the item is in a storage item, take it out
	var/outside_storage = !loc.atom_storage
	var/turf/storage_turf
	if(loc.atom_storage)
		//We want the pickup animation to play even if we're moving the item between movables. Unless the mob is not located on a turf.
		if(isturf(user.loc))
			storage_turf = get_turf(loc)
		if(!loc.atom_storage.remove_single(user, src, user, silent = TRUE))
			return
	if(QDELETED(src)) //moving it out of the storage destroyed it.
		return

	if(storage_turf)
		do_pickup_animation(user, storage_turf)

	if(throwing)
		throwing.finalize(FALSE)
	if(loc == user && outside_storage)
		if(!allow_attack_hand_drop(user) || !user.temporarilyRemoveItemFromInventory(src))
			return

	. = FALSE
	pickup(user)
	add_fingerprint(user)
	if(!user.put_in_active_hand(src, ignore_animation = !outside_storage))
		user.dropItemToGround(src)
		return TRUE

/obj/item/proc/allow_attack_hand_drop(mob/user)
	return TRUE

/obj/item/attack_paw(mob/user, list/modifiers)
	. = ..()
	if(. || !user || anchored)
		return
	return attempt_pickup(user)

/obj/item/attack_alien(mob/user, list/modifiers)
	var/mob/living/carbon/alien/ayy = user

	if(!ayy.can_hold_items(src))
		if(src in ayy.contents) // To stop Aliens having items stuck in their pockets
			ayy.dropItemToGround(src)
		to_chat(user, span_warning("Your claws aren't capable of such fine manipulation!"))
		return
	attack_paw(ayy, modifiers)

/obj/item/attack_ai(mob/user)
	if(istype(src.loc, /obj/item/robot_model))
		//If the item is part of a cyborg module, equip it
		if(!iscyborg(user))
			return
		var/mob/living/silicon/robot/R = user
		if(!R.low_power_mode) //can't equip modules with an empty cell.
			R.activate_module(src)
			R.hud_used.update_robot_modules_display()

// afterattack() and attack() prototypes moved to _onclick/item_attack.dm for consistency

/obj/item/proc/hit_reaction(mob/living/carbon/human/owner, atom/movable/hitby, attack_text = "the attack", final_block_chance = 0, damage = 0, attack_type = MELEE_ATTACK, damage_type = BRUTE)
	if(SEND_SIGNAL(src, COMSIG_ITEM_HIT_REACT, owner, hitby, attack_text, final_block_chance, damage, attack_type, damage_type) & COMPONENT_HIT_REACTION_BLOCK)
		return TRUE

	if(prob(final_block_chance))
		owner.visible_message(span_danger("[owner] blocks [attack_text] with [src]!"))
		var/owner_turf = get_turf(owner)
		new block_effect(owner_turf, COLOR_YELLOW)
		playsound(src, block_sound, BLOCK_SOUND_VOLUME, vary = TRUE)
		return TRUE

/**
 * Handles someone talking INTO an item
 *
 * Commonly used by someone holding it and using .r or .l
 * Also used by radios
 *
 * * speaker - the atom that is doing the talking
 * * message - the message being spoken
 * * channel - the channel the message is being spoken on, only really used for radios
 * * spans - the spans of the message
 * * language - the language the message is in
 * * message_mods - any message mods that should be applied to the message
 *
 * Return a flag that modifies the original message
 */
/obj/item/proc/talk_into(atom/movable/speaker, message, channel, list/spans, datum/language/language, list/message_mods)
	return SEND_SIGNAL(src, COMSIG_ITEM_TALK_INTO, speaker, message, channel, spans, language, message_mods) || (ITALICS|REDUCE_RANGE)

/// Called when a mob drops an item.
/obj/item/proc/dropped(mob/user, silent = FALSE)
	SHOULD_CALL_PARENT(TRUE)

	// Remove any item actions we temporary gave out.
	for(var/datum/action/action_item_has as anything in actions)
		action_item_has.Remove(user)

	if(item_flags & DROPDEL && !QDELETED(src))
		qdel(src)
	item_flags &= ~IN_INVENTORY
	UnregisterSignal(src, list(SIGNAL_ADDTRAIT(TRAIT_NO_WORN_ICON), SIGNAL_REMOVETRAIT(TRAIT_NO_WORN_ICON)))
	SEND_SIGNAL(src, COMSIG_ITEM_DROPPED, user)
	if(!silent)
		playsound(src, drop_sound, DROP_SOUND_VOLUME, vary = sound_vary, ignore_walls = FALSE)
	user?.update_equipment_speed_mods()

/// called just as an item is picked up (loc is not yet changed)
/obj/item/proc/pickup(mob/user)
	SHOULD_CALL_PARENT(TRUE)
	SEND_SIGNAL(src, COMSIG_ITEM_PICKUP, user)
	SEND_SIGNAL(user, COMSIG_LIVING_PICKED_UP_ITEM, src)
	item_flags |= IN_INVENTORY

/// called when "found" in pockets and storage items. Returns 1 if the search should end.
/obj/item/proc/on_found(mob/finder)
	return

/**
 * Called after an item is placed in an equipment slot. Runs equipped(), then sends a signal.
 * This should be called last or near-to-last, after all other inventory code stuff is handled.
 *
 * Arguments:
 * * user is mob that equipped it
 * * slot uses the slot_X defines found in setup.dm for items that can be placed in multiple slots
 * * initial is used to indicate whether or not this is the initial equipment (job datums etc) or just a player doing it
 */
/obj/item/proc/on_equipped(mob/user, slot, initial = FALSE)
	SHOULD_NOT_OVERRIDE(TRUE)
	equipped(user, slot, initial)
	if(SEND_SIGNAL(src, COMSIG_ITEM_POST_EQUIPPED, user, slot) & COMPONENT_EQUIPPED_FAILED)
		return FALSE
	return TRUE

/**
 * To be overwritten to only perform visual tasks;
 * this is directly called instead of `equipped` on visual-only features like human dummies equipping outfits.
 *
 * This separation exists to prevent things like the monkey sentience helmet from
 * polling ghosts while it's just being equipped as a visual preview for a dummy.
 */
/obj/item/proc/visual_equipped(mob/user, slot, initial = FALSE)
	return

/**
 * Called by on_equipped. Don't call this directly, we want the ITEM_POST_EQUIPPED signal to be sent after everything else.
 *
 * Note that hands count as slots.
 *
 * Arguments:
 * * user is mob that equipped it
 * * slot uses the slot_X defines found in setup.dm for items that can be placed in multiple slots
 * * initial is used to indicate whether or not this is the initial equipment (job datums etc) or just a player doing it
 */
/obj/item/proc/equipped(mob/user, slot, initial = FALSE)
	SHOULD_CALL_PARENT(TRUE)
	PROTECTED_PROC(TRUE)
	visual_equipped(user, slot, initial)
	SEND_SIGNAL(src, COMSIG_ITEM_EQUIPPED, user, slot)
	SEND_SIGNAL(user, COMSIG_MOB_EQUIPPED_ITEM, src, slot)

	// Give out actions our item has to people who equip it.
	for(var/datum/action/action as anything in actions)
		give_item_action(action, user, slot)

	item_flags |= IN_INVENTORY
	RegisterSignals(src, list(SIGNAL_ADDTRAIT(TRAIT_NO_WORN_ICON), SIGNAL_REMOVETRAIT(TRAIT_NO_WORN_ICON)), PROC_REF(update_slot_icon), override = TRUE)
	if(!initial)
		if(equip_sound && (slot_flags & slot))
			playsound(src, equip_sound, EQUIP_SOUND_VOLUME, TRUE, ignore_walls = FALSE)
		else if(slot & ITEM_SLOT_HANDS)
			playsound(src, pickup_sound, PICKUP_SOUND_VOLUME, sound_vary, ignore_walls = FALSE)
	user.update_equipment_speed_mods()

/// Gives one of our item actions to a mob, when equipped to a certain slot
/obj/item/proc/give_item_action(datum/action/action, mob/to_who, slot)
	// Some items only give their actions buttons when in a specific slot.
	if(!item_action_slot_check(slot, to_who, action) || SEND_SIGNAL(src, COMSIG_ITEM_UI_ACTION_SLOT_CHECKED, to_who, action, slot) & COMPONENT_ITEM_ACTION_SLOT_INVALID)
		// There is a chance we still have our item action currently,
		// and are moving it from a "valid slot" to an "invalid slot".
		// So call Remove() here regardless, even if excessive.
		action.Remove(to_who)
		return

	action.Grant(to_who)

/// Sometimes we only want to grant the item's action if it's equipped in a specific slot.
/obj/item/proc/item_action_slot_check(slot, mob/user, datum/action/action)
	if(slot & (ITEM_SLOT_BACKPACK|ITEM_SLOT_LEGCUFFED)) //these aren't true slots, so avoid granting actions there
		return FALSE
	return TRUE

/**
 *the mob M is attempting to equip this item into the slot passed through as 'slot'. Return 1 if it can do this and 0 if it can't.
 *if this is being done by a mob other than M, it will include the mob equipper, who is trying to equip the item to mob M. equipper will be null otherwise.
 *If you are making custom procs but would like to retain partial or complete functionality of this one, include a 'return ..()' to where you want this to happen.
 * Arguments:
 * * disable_warning to TRUE if you wish it to not give you text outputs.
 * * slot is the slot we are trying to equip to
 * * bypass_equip_delay_self for whether we want to bypass the equip delay
 * * ignore_equipped ignores any already equipped items in that slot
 * * indirect_action allows inserting into "soft locked" bags, things that can be easily opened by the owner
 */
/obj/item/proc/mob_can_equip(mob/living/M, slot, disable_warning = FALSE, bypass_equip_delay_self = FALSE, ignore_equipped = FALSE, indirect_action = FALSE)
	if(!M)
		return FALSE

	return M.can_equip(src, slot, disable_warning, bypass_equip_delay_self, ignore_equipped, indirect_action = indirect_action)

/obj/item/verb/verb_pickup()
	set src in oview(1)
	set category = "Object"
	set name = "Pick up"

	if(usr.incapacitated || !Adjacent(usr))
		return

	if(isliving(usr))
		var/mob/living/L = usr
		if(!(L.mobility_flags & MOBILITY_PICKUP))
			return

	if(usr.get_active_held_item() == null) // Let me know if this has any problems -Yota
		usr.UnarmedAttack(src)

/**
 *This proc is executed when someone clicks the on-screen UI button.
 *The default action is attack_self().
 *Checks before we get to here are: mob is alive, mob is not restrained, stunned, asleep, resting, laying, item is on the mob.
 */
/obj/item/proc/ui_action_click(mob/user, actiontype)
	if(SEND_SIGNAL(src, COMSIG_ITEM_UI_ACTION_CLICK, user, actiontype) & COMPONENT_ACTION_HANDLED)
		return

	attack_self(user)

///This proc determines if and at what an object will reflect energy projectiles if it's in l_hand,r_hand or wear_suit
/obj/item/proc/IsReflect(def_zone)
	return FALSE

/obj/item/singularity_pull(atom/singularity, current_size)
	..()
	if(current_size >= STAGE_FOUR)
		throw_at(singularity, 14, 3, spin=0)
	else
		return

/obj/item/on_exit_storage(datum/storage/master_storage)
	. = ..()
	do_drop_animation(master_storage.parent)

/obj/item/pre_impact(atom/hit_atom, datum/thrownthing/throwingdatum)
	get_embed() // Ensure that embedding is lazyloaded before we impact the target, if we can have it
	var/impact_flags = ..()
	if(w_class < WEIGHT_CLASS_BULKY)
		impact_flags |= COMPONENT_MOVABLE_IMPACT_FLIP_HITPUSH
	if(!(impact_flags & COMPONENT_MOVABLE_IMPACT_NEVERMIND) && get_temperature() && isliving(hit_atom))
		var/mob/living/victim = hit_atom
		victim.ignite_mob()
	return impact_flags

/obj/item/throw_impact(atom/hit_atom, datum/thrownthing/throwingdatum)
	. = ..()

	if(!isliving(hit_atom)) //Living mobs handle hit sounds differently.
		if(throw_drop_sound)
			playsound(src, throw_drop_sound, YEET_SOUND_VOLUME, ignore_walls = FALSE, vary = sound_vary)
			return
		playsound(src, drop_sound, YEET_SOUND_VOLUME, ignore_walls = FALSE, vary = sound_vary)
		return

	if(.) //it's been caught.
		return

	var/volume = get_volume_by_throwforce_and_or_w_class()
	if (throwforce > 0 || HAS_TRAIT(src, TRAIT_CUSTOM_TAP_SOUND))
		if (mob_throw_hit_sound)
			playsound(hit_atom, mob_throw_hit_sound, volume, TRUE, -1)
		else if(hitsound)
			playsound(hit_atom, hitsound, volume, TRUE, -1)
		else
			playsound(hit_atom, 'sound/items/weapons/genhit.ogg',volume, TRUE, -1)
	else
		playsound(hit_atom, 'sound/items/weapons/throwtap.ogg', 1, volume, -1)

/obj/item/throw_at(atom/target, range, speed, mob/thrower, spin=1, diagonals_first = 0, datum/callback/callback, force, gentle = FALSE, quickstart = TRUE, throw_type_path = /datum/thrownthing)
	if(HAS_TRAIT(src, TRAIT_NODROP))
		return
	thrownby = WEAKREF(thrower)
	callback = CALLBACK(src, PROC_REF(after_throw), callback) //replace their callback with our own
	. = ..(target, range, speed, thrower, spin, diagonals_first, callback, force, gentle, quickstart = quickstart)

/obj/item/proc/after_throw(datum/callback/callback)
	if (callback) //call the original callback
		. = callback.Invoke()
	item_flags &= ~IN_INVENTORY
	if(!pixel_y && !pixel_x && !(item_flags & NO_PIXEL_RANDOM_DROP))
		pixel_x = rand(-8,8)
		pixel_y = rand(-8,8)

/// Takes the location to move the item to, and optionally the mob doing the removing
/// If no mob is provided, we'll pass in the location, assuming it is a mob
/// Please use this if you're going to snowflake an item out of a obj/item/storage
/obj/item/proc/remove_item_from_storage(atom/newLoc, mob/removing)
	if(!newLoc)
		return FALSE
	if(!removing)
		if(ismob(newLoc))
			removing = newLoc
		else
			stack_trace("Tried to remove an item and place it into [newLoc] without implicitly or explicitly passing in a mob doing the removing")
			return
	if(loc.atom_storage)
		return loc.atom_storage.remove_single(removing, src, newLoc, silent = TRUE)
	return FALSE

/// Returns the icon used for overlaying the object on a belt
/obj/item/proc/get_belt_overlay()
	var/icon_state_to_use = inside_belt_icon_state || icon_state
	if(greyscale_config_belt && greyscale_colors)
		return mutable_appearance(SSgreyscale.GetColoredIconByType(greyscale_config_belt, greyscale_colors), icon_state_to_use)
	return mutable_appearance('icons/obj/clothing/belt_overlays.dmi', icon_state_to_use)

/**
 * Extend this to give the item an appearance when placed in a surgical tray. Uses an icon state in `medicart.dmi`.
 * * tray_extended - If true, the surgical tray the item is placed on is in "table mode"
 */
/obj/item/proc/get_surgery_tool_overlay(tray_extended)
	return null

/obj/item/proc/update_slot_icon()
	SIGNAL_HANDLER
	if(!ismob(loc))
		return
	var/mob/owner = loc
	var/flags = slot_flags
	if(flags & ITEM_SLOT_OCLOTHING)
		owner.update_worn_oversuit()
	if(flags & ITEM_SLOT_ICLOTHING)
		owner.update_worn_undersuit()
	if(flags & ITEM_SLOT_GLOVES)
		owner.update_worn_gloves()
	if(flags & ITEM_SLOT_EYES)
		owner.update_worn_glasses()
	if(flags & ITEM_SLOT_EARS)
		owner.update_worn_ears()
	if(flags & ITEM_SLOT_MASK)
		owner.update_worn_mask()
	if(flags & ITEM_SLOT_HEAD)
		owner.update_worn_head()
	if(flags & ITEM_SLOT_FEET)
		owner.update_worn_shoes()
	if(flags & ITEM_SLOT_ID)
		owner.update_worn_id()
	if(flags & ITEM_SLOT_BELT)
		owner.update_worn_belt()
	if(flags & ITEM_SLOT_BACK)
		owner.update_worn_back()
	if(flags & ITEM_SLOT_NECK)
		owner.update_worn_neck()

///Returns the temperature of src. If you want to know if an item is hot use this proc.
/obj/item/proc/get_temperature()
	if(resistance_flags & ON_FIRE)
		return max(heat, BURNING_ITEM_MINIMUM_TEMPERATURE)
	return heat

///Returns the sharpness of src. If you want to get the sharpness of an item use this.
/obj/item/proc/get_sharpness()
	return sharpness

/obj/item/proc/get_dismember_sound()
	if(damtype == BURN)
		. = SFX_SEAR
	else
		. = SFX_DESECRATION

/// Creates an ignition hotspot if item is lit and located on turf, in mask, or in hand
/obj/item/proc/open_flame(flame_heat=700)
	var/turf/location = loc
	if(ismob(location))
		var/mob/pyromanic = location
		var/success = FALSE
		if(src == pyromanic.get_item_by_slot(ITEM_SLOT_MASK) || (src in pyromanic.held_items))
			success = TRUE
		if(success)
			location = get_turf(pyromanic)
	if(isturf(location))
		location.hotspot_expose(flame_heat, 5)

/// If an object can successfully be used as a fire starter it will return a message
/obj/item/proc/ignition_effect(atom/A, mob/user)
	if(get_temperature())
		. = span_notice("[user] lights [A] with [src].")
	else
		. = ""

/obj/item/hitby(atom/movable/AM, skipcatch, hitpush, blocked, datum/thrownthing/throwingdatum)
	return SEND_SIGNAL(src, COMSIG_ATOM_HITBY, AM, skipcatch, hitpush, blocked, throwingdatum)

/obj/item/attack_hulk(mob/living/carbon/human/user)
	return FALSE

/obj/item/attack_animal(mob/living/simple_animal/user, list/modifiers)
	if (obj_flags & CAN_BE_HIT)
		return ..()
	return 0

/obj/item/burn()
	if(!QDELETED(src))
		var/turf/T = get_turf(src)
		var/ash_type = /obj/effect/decal/cleanable/ash
		if(w_class == WEIGHT_CLASS_HUGE || w_class == WEIGHT_CLASS_GIGANTIC)
			ash_type = /obj/effect/decal/cleanable/ash/large
		var/obj/effect/decal/cleanable/ash/A = new ash_type(T)
		A.desc += "\nLooks like this used to be \an [name] some time ago."
		..()

/obj/item/acid_melt()
	if(!QDELETED(src))
		var/turf/T = get_turf(src)
		var/obj/effect/decal/cleanable/molten_object/MO = new(T)
		MO.pixel_x = rand(-16,16)
		MO.pixel_y = rand(-16,16)
		MO.desc = "Looks like this was \an [src] some time ago."
		..()

/obj/item/proc/microwave_act(obj/machinery/microwave/microwave_source, mob/microwaver, randomize_pixel_offset)
	SHOULD_CALL_PARENT(TRUE)

	return SEND_SIGNAL(src, COMSIG_ITEM_MICROWAVE_ACT, microwave_source, microwaver, randomize_pixel_offset)

///Used to check for extra requirements for blending(grinding or juicing) an object
/obj/item/proc/blend_requirements(obj/machinery/reagentgrinder/R)
	return TRUE

///Called BEFORE the object is ground up - use this to change grind results based on conditions. Return "-1" to prevent the grinding from occurring
/obj/item/proc/on_grind()
	PROTECTED_PROC(TRUE)

	return SEND_SIGNAL(src, COMSIG_ITEM_ON_GRIND)

///Grind item, adding grind_results to item's reagents and transfering to target_holder if specified
/obj/item/proc/grind(datum/reagents/target_holder, mob/user, atom/movable/grinder = loc)
	SHOULD_NOT_OVERRIDE(TRUE)

	. = FALSE
	if(on_grind() == -1 || target_holder.holder_full())
		return

	. = grind_atom(target_holder, user)

	//reccursive grinding to get all them juices
	var/result
	for(var/obj/item/ingredient as anything in get_all_contents_type(/obj/item))
		if(ingredient == src)
			continue

		result = ingredient.grind(target_holder, user)
		if(!.)
			. = result

	if(. && istype(grinder))
		return grinder.blended(src, grinded = TRUE)

///Subtypes override his proc for custom grinding
/obj/item/proc/grind_atom(datum/reagents/target_holder, mob/user)
	PROTECTED_PROC(TRUE)

	. = FALSE
	if(length(grind_results))
		target_holder.add_reagent_list(grind_results)
		. = TRUE
	if(reagents?.trans_to(target_holder, reagents.total_volume, transferred_by = user))
		. = TRUE

///Called BEFORE the object is ground up - use this to change grind results based on conditions. Return "-1" to prevent the grinding from occurring
/obj/item/proc/on_juice()
	PROTECTED_PROC(TRUE)

	if(!juice_typepath)
		return -1

	return SEND_SIGNAL(src, COMSIG_ITEM_ON_JUICE)

///Juice item, converting nutriments into juice_typepath and transfering to target_holder if specified
/obj/item/proc/juice(datum/reagents/target_holder, mob/user, atom/movable/juicer = loc)
	SHOULD_NOT_OVERRIDE(TRUE)

	. = FALSE
	if(on_juice() == -1 || !reagents?.total_volume)
		return

	. = juice_atom(target_holder, user)

	//reccursive juicing to get all them juices
	var/result
	for(var/obj/item/ingredient as anything in get_all_contents_type(/obj/item))
		if(ingredient == src)
			continue

		result = ingredient.juice(target_holder, user)
		if(!.)
			. = result

	if(. && istype(juicer))
		return juicer.blended(src, grinded = FALSE)

///Subtypes override his proc for custom juicing
/obj/item/proc/juice_atom(datum/reagents/target_holder, mob/user)
	PROTECTED_PROC(TRUE)

	. = FALSE

	if(ispath(juice_typepath))
		reagents.convert_reagent(/datum/reagent/consumable/nutriment, juice_typepath, include_source_subtypes = FALSE)
		reagents.convert_reagent(/datum/reagent/consumable/nutriment/vitamin, juice_typepath, include_source_subtypes = FALSE)
		. = TRUE

	if(!QDELETED(target_holder))
		reagents.trans_to(target_holder, reagents.total_volume, transferred_by = user)

///What should The atom that blended an object do with it afterwards? Default behaviour is to delete it
/atom/movable/proc/blended(obj/item/blended_item, grinded)
	qdel(blended_item)

	return TRUE

/obj/item/proc/set_force_string()
	switch(force)
		if(0 to 4)
			force_string = "very low"
		if(4 to 7)
			force_string = "low"
		if(7 to 10)
			force_string = "medium"
		if(10 to 11)
			force_string = "high"
		if(11 to 20) //12 is the force of a toolbox
			force_string = "robust"
		if(20 to 25)
			force_string = "very robust"
		else
			force_string = "exceptionally robust"
	last_force_string_check = force

/obj/item/proc/openTip(location, control, params, user)
	if(last_force_string_check != force && !(item_flags & FORCE_STRING_OVERRIDE))
		set_force_string()
	if(!(item_flags & FORCE_STRING_OVERRIDE))
		openToolTip(user,src,params,title = name,content = "[desc]<br>[force ? "<b>Force:</b> [force_string]" : ""]",theme = "")
	else
		openToolTip(user,src,params,title = name,content = "[desc]<br><b>Force:</b> [force_string]",theme = "")

/obj/item/MouseEntered(location, control, params)
	. = ..()
	if(((get(src, /mob) == usr) || loc?.atom_storage || (item_flags & IN_STORAGE)) && !QDELETED(src)) //nullspace exists.
		var/mob/living/L = usr
		if(usr.client.prefs.read_preference(/datum/preference/toggle/enable_tooltips))
			var/timedelay = usr.client.prefs.read_preference(/datum/preference/numeric/tooltip_delay) / 100
			tip_timer = addtimer(CALLBACK(src, PROC_REF(openTip), location, control, params, usr), timedelay, TIMER_STOPPABLE)//timer takes delay in deciseconds, but the pref is in milliseconds. dividing by 100 converts it.
		if(usr.client.prefs.read_preference(/datum/preference/toggle/item_outlines))
			if(istype(L) && L.incapacitated)
				apply_outline(COLOR_RED_GRAY) //if they're dead or handcuffed, let's show the outline as red to indicate that they can't interact with that right now
			else
				apply_outline() //if the player's alive and well we send the command with no color set, so it uses the theme's color

/obj/item/base_mouse_drop_handler(atom/over, src_location, over_location, params)
	SHOULD_NOT_OVERRIDE(TRUE)

	. = ..()

	remove_filter(HOVER_OUTLINE_FILTER) //get rid of the hover effect in case the mouse exit isn't called if someone drags and drops an item and somthing goes wrong

/obj/item/MouseExited()
	deltimer(tip_timer) //delete any in-progress timer if the mouse is moved off the item before it finishes
	closeToolTip(usr)
	remove_filter(HOVER_OUTLINE_FILTER)

/obj/item/proc/apply_outline(outline_color = null)
	if(((get(src, /mob) != usr) && !loc?.atom_storage && !(item_flags & IN_STORAGE)) || QDELETED(src) || isobserver(usr)) //cancel if the item isn't in an inventory, is being deleted, or if the person hovering is a ghost (so that people spectating you don't randomly make your items glow)
		return FALSE
	var/theme = LOWER_TEXT(usr.client?.prefs?.read_preference(/datum/preference/choiced/ui_style))
	if(!outline_color) //if we weren't provided with a color, take the theme's color
		switch(theme) //yeah it kinda has to be this way
			if("midnight")
				outline_color = COLOR_THEME_MIDNIGHT
			if("plasmafire")
				outline_color = COLOR_THEME_PLASMAFIRE
			if("retro")
				outline_color = COLOR_THEME_RETRO //just as garish as the rest of this theme
			if("slimecore")
				outline_color = COLOR_THEME_SLIMECORE
			if("operative")
				outline_color = COLOR_THEME_OPERATIVE
			if("clockwork")
				outline_color = COLOR_THEME_CLOCKWORK //if you want free gbp go fix the fact that clockwork's tooltip css is glass'
			if("glass")
				outline_color = COLOR_THEME_GLASS
			else //this should never happen, hopefully
				outline_color = COLOR_WHITE
	if(color)
		outline_color = COLOR_WHITE //if the item is recolored then the outline will be too, let's make the outline white so it becomes the same color instead of some ugly mix of the theme and the tint

	add_filter(HOVER_OUTLINE_FILTER, 1, list("type" = "outline", "size" = 1, "color" = outline_color))

/// Called when a mob tries to use the item as a tool. Handles most checks.
/obj/item/proc/use_tool(atom/target, mob/living/user, delay, amount=0, volume=0, datum/callback/extra_checks)
	// No delay means there is no start message, and no reason to call tool_start_check before use_tool.
	// Run the start check here so we wouldn't have to call it manually.
	if(!delay && !tool_start_check(user, amount))
		return

	var/skill_modifier = 1

	if(tool_behaviour == TOOL_MINING && ishuman(user))
		if(user.mind)
			skill_modifier = user.mind.get_skill_modifier(/datum/skill/mining, SKILL_SPEED_MODIFIER)

			if(user.mind.get_skill_level(/datum/skill/mining) >= SKILL_LEVEL_JOURNEYMAN && prob(user.mind.get_skill_modifier(/datum/skill/mining, SKILL_PROBS_MODIFIER))) // we check if the skill level is greater than Journeyman and then we check for the probality for that specific level.
				mineral_scan_pulse(get_turf(user), SKILL_LEVEL_JOURNEYMAN - 2, scanner = src) //SKILL_LEVEL_JOURNEYMAN = 3 So to get range of 1+ we have to subtract 2 from it,.

	delay *= toolspeed * skill_modifier


	// Play tool sound at the beginning of tool usage.
	play_tool_sound(target, volume)

	if(delay)
		// Create a callback with checks that would be called every tick by do_after.
		var/datum/callback/tool_check = CALLBACK(src, PROC_REF(tool_check_callback), user, amount, extra_checks)

		if(delay >= MIN_TOOL_OPERATING_DELAY)
			play_tool_operating_sound(target, volume)

		if(!do_after(user, delay, target=target, extra_checks=tool_check))
			return
	else
		// Invoke the extra checks once, just in case.
		if(extra_checks && !extra_checks.Invoke())
			return

	// Use tool's fuel, stack sheets or charges if amount is set.
	if(amount && !use(amount))
		return

	// Play tool sound at the end of tool usage,
	// but only if the delay between the beginning and the end is not too small
	if(delay >= MIN_TOOL_SOUND_DELAY)
		play_tool_sound(target, volume)

	return TRUE

/// Called before [obj/item/proc/use_tool] if there is a delay, or by [obj/item/proc/use_tool] if there isn't. Only ever used by welding tools and stacks, so it's not added on any other [obj/item/proc/use_tool] checks.
/obj/item/proc/tool_start_check(mob/living/user, amount=0, heat_required=0)
	. = tool_use_check(user, amount, heat_required)
	if(.)
		SEND_SIGNAL(src, COMSIG_TOOL_START_USE, user)

/// A check called by [/obj/item/proc/tool_start_check] once, and by use_tool on every tick of delay.
/obj/item/proc/tool_use_check(mob/living/user, amount, heat_required)
	return !amount

/// Generic use proc. Depending on the item, it uses up fuel, charges, sheets, etc. Returns TRUE on success, FALSE on failure.
/obj/item/proc/use(used)
	return !used

/// Plays item's usesound, if any.
/obj/item/proc/play_tool_sound(atom/target, volume=50)
	if(target && usesound && volume)
		var/played_sound = usesound

		if(islist(usesound))
			played_sound = pick(usesound)

		playsound(target, played_sound, volume, TRUE)

///Play item's operating sound
/obj/item/proc/play_tool_operating_sound(atom/target, volume=50)
	if(target && operating_sound && volume)
		var/played_sound = operating_sound

		if(islist(operating_sound))
			played_sound = pick(operating_sound)

		if(!TIMER_COOLDOWN_FINISHED(src, COOLDOWN_TOOL_SOUND))
			return
		playsound(target, played_sound, volume, TRUE)
		TIMER_COOLDOWN_START(src, COOLDOWN_TOOL_SOUND, 4 SECONDS) //based on our longest sound clip

/// Used in a callback that is passed by use_tool into do_after call. Do not override, do not call manually.
/obj/item/proc/tool_check_callback(mob/living/user, amount, datum/callback/extra_checks)
	SHOULD_NOT_OVERRIDE(TRUE)
	. = tool_use_check(user, amount) && (!extra_checks || extra_checks.Invoke())
	if(.)
		SEND_SIGNAL(src, COMSIG_TOOL_IN_USE, user)

/// Returns a numeric value for sorting items used as parts in machines, so they can be replaced by the rped
/obj/item/proc/get_part_rating()
	return 0

/obj/item/doMove(atom/destination)
	if (!ismob(loc))
		return ..()

	var/mob/M = loc
	var/hand_index = M.get_held_index_of_item(src)
	if(!hand_index)
		return ..()

	M.held_items[hand_index] = null
	M.update_held_items()
	if(M.client)
		M.client.screen -= src
	layer = initial(layer)
	SET_PLANE_IMPLICIT(src, initial(plane))
	appearance_flags &= ~NO_CLIENT_COLOR
	dropped(M, FALSE)
	return ..()

/obj/item/proc/canStrip(mob/stripper, mob/owner)
	SHOULD_BE_PURE(TRUE)
	return !HAS_TRAIT(src, TRAIT_NODROP) && !(item_flags & ABSTRACT)

/obj/item/proc/doStrip(mob/stripper, mob/owner)
	return owner.dropItemToGround(src)

///Called by the carbon throw_item() proc. Returns null if the item negates the throw, or a reference to the thing to suffer the throw else.
/obj/item/proc/on_thrown(mob/living/carbon/user, atom/target)
	if((item_flags & ABSTRACT) || HAS_TRAIT(src, TRAIT_NODROP))
		return
	user.dropItemToGround(src, silent = TRUE)
	if(throwforce && (HAS_TRAIT(user, TRAIT_PACIFISM)) || HAS_TRAIT(user, TRAIT_NO_THROWING))
		to_chat(user, span_notice("You set [src] down gently on the ground."))
		return
	return src

/// How many different types of mats will be counted in a bite?
#define MAX_MATS_PER_BITE 2

/*
 * On accidental consumption: when you somehow end up eating an item accidentally (currently, this is used for when items are hidden in food like bread or cake)
 *
 * The base proc will check if the item is sharp and has a decent force.
 * Then, it checks the item's mat datums for the effects it applies afterwards.
 * Then, it checks tiny items.
 * After all that, it returns TRUE if the item is set to be discovered. Otherwise, it returns FALSE.
 *
 * This works similarly to /suicide_act: if you want an item to have a unique interaction, go to that item
 * and give it an /on_accidental_consumption proc override. For a simple example of this, check out the nuke disk.
 *
 * Arguments
 * * M - the mob accidentally consuming the item
 * * user - the mob feeding M the item - usually, it's the same as M
 * * source_item - the item that held the item being consumed - bread, cake, etc
 * * discover_after - if the item will be discovered after being chomped (FALSE will usually mean it was swallowed, TRUE will usually mean it was bitten into and discovered)
 */
/obj/item/proc/on_accidental_consumption(mob/living/carbon/victim, mob/living/carbon/user, obj/item/source_item, discover_after = TRUE)
	if(get_sharpness() && force >= 5) //if we've got something sharp with a decent force (ie, not plastic)
		INVOKE_ASYNC(victim, TYPE_PROC_REF(/mob, emote), "scream")
		victim.visible_message(span_warning("[victim] looks like [victim.p_theyve()] just bit something they shouldn't have!"), \
							span_boldwarning("OH GOD! Was that a crunch? That didn't feel good at all!!"))

		victim.apply_damage(max(15, force), BRUTE, BODY_ZONE_HEAD, wound_bonus = 10, sharpness = TRUE)
		victim.losebreath += 2
		if(force_embed(victim, BODY_ZONE_CHEST)) //and if it embeds successfully in their chest, cause a lot of pain
			victim.apply_damage(max(25, force*1.5), BRUTE, BODY_ZONE_CHEST, wound_bonus = 7, sharpness = TRUE)
			victim.losebreath += 6
			discover_after = FALSE
		if(QDELETED(src)) // in case trying to embed it caused its deletion (say, if it's DROPDEL)
			return
		source_item?.reagents?.add_reagent(/datum/reagent/blood, 2)
		return discover_after

	if(custom_materials?.len) //if we've got materials, let's see what's in it
		// How many mats have we found? You can only be affected by two material datums by default
		var/found_mats = 0
		// How much of each material is in it? Used to determine if the glass should break
		var/total_material_amount = 0

		for(var/mats in custom_materials)
			total_material_amount += custom_materials[mats]
			if(found_mats >= MAX_MATS_PER_BITE)
				continue //continue instead of break so we can finish adding up all the mats to the total

			var/datum/material/discovered_mat = mats
			if(discovered_mat.on_accidental_mat_consumption(victim, source_item))
				found_mats++

		//if there's glass in it and the glass is more than 60% of the item, then we can shatter it
		if(custom_materials[GET_MATERIAL_REF(/datum/material/glass)] >= total_material_amount * 0.60)
			if(prob(66)) //66% chance to break it
				// The glass shard that is spawned into the source item
				var/obj/item/shard/broken_glass = new /obj/item/shard(loc)
				broken_glass.name = "broken [name]"
				broken_glass.desc = "This used to be \a [name], but it sure isn't anymore."
				playsound(victim, SFX_SHATTER, 25, TRUE)
				qdel(src)
				if(QDELETED(source_item))
					broken_glass.on_accidental_consumption(victim, user)
			else //33% chance to just "crack" it (play a sound) and leave it in the bread
				playsound(victim, SFX_SHATTER, 15, TRUE)
			discover_after = FALSE

		victim.adjust_disgust(33)
		victim.visible_message(span_warning("[victim] looks like [victim.p_theyve()] just bitten into something hard."), \
						span_warning("Eugh! Did I just bite into something?"))
		return discover_after

	if(w_class > WEIGHT_CLASS_TINY) //small items like soap or toys that don't have mat datums
		to_chat(victim, span_warning("[source_item? "Something strange was in \the [source_item]..." : "I just bit something strange..."] "))
		return discover_after

	// victim's chest (for cavity implanting the item)
	var/obj/item/bodypart/chest/victim_cavity = victim.get_bodypart(BODY_ZONE_CHEST)
	if(victim_cavity.cavity_item)
		victim.vomit(vomit_flags = (MOB_VOMIT_MESSAGE | MOB_VOMIT_HARM), lost_nutrition = 5, distance = 0)
		forceMove(drop_location())
		to_chat(victim, span_warning("You vomit up a [name]! [source_item? "Was that in \the [source_item]?" : ""]"))
		return FALSE

	victim.transferItemToLoc(src, victim, TRUE)
	victim.losebreath += 2
	victim_cavity.cavity_item = src
	to_chat(victim, span_warning("You swallow hard. [source_item? "Something small was in \the [source_item]..." : ""]"))
	return FALSE

#undef MAX_MATS_PER_BITE

/**
 * Updates all action buttons associated with this item
 *
 * Arguments:
 * * update_flags - Which flags of the action should we update
 * * force - Force buttons update even if the given button icon state has not changed
 */
/obj/item/proc/update_item_action_buttons(update_flags = ALL, force = FALSE)
	for(var/datum/action/current_action as anything in actions)
		current_action.build_all_button_icons(update_flags, force)

// Update icons if this is being carried by a mob
/obj/item/wash(clean_types)
	. = ..()
	if(ismob(loc))
		var/mob/mob_loc = loc
		mob_loc.update_clothing(slot_flags)

/// Called on [/datum/element/openspace_item_click_handler/proc/on_afterattack]. Check the relative file for information.
/obj/item/proc/handle_openspace_click(turf/target, mob/user, list/modifiers)
	stack_trace("Undefined handle_openspace_click() behaviour. Ascertain the openspace_item_click_handler element has been attached to the right item and that its proc override doesn't call parent.")

/**
 * * An interrupt for offering an item to other people, called mainly from [/mob/living/carbon/proc/give], in case you want to run your own offer behavior instead.
 *
 * * Return TRUE if you want to interrupt the offer.
 *
 * * Arguments:
 * * offerer - The person offering the item.
 * * offered - The person being offered the item.
 */
/obj/item/proc/on_offered(mob/living/carbon/offerer, mob/living/carbon/offered)
	if(SEND_SIGNAL(src, COMSIG_ITEM_OFFERING, offerer) & COMPONENT_OFFER_INTERRUPT)
		return TRUE

/**
 * * An interrupt for someone trying to accept an offered item, called mainly from [/mob/living/carbon/proc/take], in case you want to run your own take behavior instead.
 *
 * * Return TRUE if you want to interrupt the taking.
 *
 * * Arguments:
 * * offerer - the person offering the item
 * * taker - the person trying to accept the offer
 */
/obj/item/proc/on_offer_taken(mob/living/carbon/offerer, mob/living/carbon/taker)
	if(SEND_SIGNAL(src, COMSIG_ITEM_OFFER_TAKEN, offerer, taker) & COMPONENT_OFFER_INTERRUPT)
		return TRUE

/// Special stuff you want to do when an outfit equips this item.
/obj/item/proc/on_outfit_equip(mob/living/carbon/human/outfit_wearer, visuals_only, item_slot)
	SHOULD_CALL_PARENT(TRUE)
	SEND_SIGNAL(src, COMSIG_ITEM_EQUIPPED_AS_OUTFIT, outfit_wearer, visuals_only, item_slot)

/obj/item/proc/do_pickup_animation(atom/target, turf/source)
	if(!source)
		if(!istype(loc, /turf))
			return
		source = loc
	var/image/pickup_animation = image(icon = src)
	SET_PLANE(pickup_animation, GAME_PLANE, source)
	pickup_animation.transform.Scale(0.75)
	pickup_animation.appearance_flags = APPEARANCE_UI_IGNORE_ALPHA

	var/direction = get_dir(source, target)
	var/to_x = target.base_pixel_x + target.base_pixel_w
	var/to_y = target.base_pixel_y + target.base_pixel_z

	if(direction & NORTH)
		to_y += 32
	else if(direction & SOUTH)
		to_y -= 32
	if(direction & EAST)
		to_x += 32
	else if(direction & WEST)
		to_x -= 32
	if(!direction)
		to_y += 10
		pickup_animation.pixel_x += 6 * (prob(50) ? 1 : -1) //6 to the right or left, helps break up the straight upward move

	var/atom/movable/flick_visual/pickup = source.flick_overlay_view(pickup_animation, 0.4 SECONDS)
	var/matrix/animation_matrix = new(pickup.transform)
	animation_matrix.Turn(pick(-30, 30))
	animation_matrix.Scale(0.65)

	animate(pickup, alpha = 175, pixel_x = to_x, pixel_y = to_y, time = 0.3 SECONDS, transform = animation_matrix, easing = CUBIC_EASING)
	animate(alpha = 0, transform = matrix().Scale(0.7), time = 0.1 SECONDS)

/obj/item/proc/do_drop_animation(atom/moving_from)
	if(!istype(loc, /turf))
		return

	if(!istype(moving_from))
		return

	var/turf/current_turf = get_turf(src)
	var/direction = get_dir(moving_from, current_turf)
	var/from_x = moving_from.base_pixel_x
	var/from_y = moving_from.base_pixel_y

	if(direction & NORTH)
		from_y -= 32
	else if(direction & SOUTH)
		from_y += 32
	if(direction & EAST)
		from_x -= 32
	else if(direction & WEST)
		from_x += 32
	if(!direction)
		from_y += 10
		from_x += 6 * (prob(50) ? 1 : -1) //6 to the right or left, helps break up the straight upward move

	//We're moving from these chords to our current ones
	var/old_x = pixel_x
	var/old_y = pixel_y
	var/old_alpha = alpha
	var/matrix/old_transform = transform
	var/matrix/animation_matrix = new(old_transform)
	animation_matrix.Turn(pick(-30, 30))
	animation_matrix.Scale(0.7) // Shrink to start, end up normal sized

	pixel_x = from_x
	pixel_y = from_y
	alpha = 0
	transform = animation_matrix

	SEND_SIGNAL(src, COMSIG_ATOM_TEMPORARY_ANIMATION_START, 3)
	// This is instant on byond's end, but to our clients this looks like a quick drop
	animate(src, alpha = old_alpha, pixel_x = old_x, pixel_y = old_y, transform = old_transform, time = 3, easing = CUBIC_EASING)

/atom/movable/proc/do_item_attack_animation(atom/attacked_atom, visual_effect_icon, obj/item/used_item, animation_type = ATTACK_ANIMATION_BLUNT)
	if (visual_effect_icon)
		var/image/attack_image = image(icon = 'icons/effects/effects.dmi', icon_state = visual_effect_icon)
		attack_image.plane = attacked_atom.plane + 1
		// Scale the icon.
		attack_image.transform *= 0.4
		// The icon should not rotate.
		attack_image.appearance_flags = APPEARANCE_UI
		var/atom/movable/flick_visual/attack = attacked_atom.flick_overlay_view(attack_image, 1 SECONDS)
		var/matrix/copy_transform = new(transform)
		animate(attack, alpha = 175, transform = copy_transform.Scale(0.75), time = 0.3 SECONDS)
		animate(time = 0.1 SECONDS)
		animate(alpha = 0, time = 0.3 SECONDS, easing = CIRCULAR_EASING|EASE_OUT)
		return

	if (isnull(used_item))
		return

	var/image/attack_image = isnull(used_item.attack_icon) ? image(icon = used_item) : image(icon = used_item.attack_icon, icon_state = used_item.attack_icon_state)
	attack_image.plane = attacked_atom.plane + 1
	// Scale the icon.
	attack_image.transform *= 0.5
	// The icon should not rotate.
	attack_image.appearance_flags = APPEARANCE_UI

	var/atom/movable/flick_visual/attack = attacked_atom.flick_overlay_view(attack_image, 1 SECONDS)
	var/matrix/copy_transform = new(transform)
	var/x_sign = 0
	var/y_sign = 0
	var/direction = get_dir(src, attacked_atom)
	if (direction & NORTH)
		y_sign = -1
	else if (direction & SOUTH)
		y_sign = 1

	if (direction & EAST)
		x_sign = -1
	else if (direction & WEST)
		x_sign = 1

	// Attacking self, or something on the same turf as us
	if (!direction)
		y_sign = 1
		// Not a fan of this, but its the "cleanest" way to animate this
		x_sign = 0.25 * (prob(50) ? 1 : -1)
		// For piercing attacks
		direction = SOUTH

	// And animate the attack!
	switch (animation_type)
		if (ATTACK_ANIMATION_BLUNT)
			attack.pixel_x = 14 * x_sign
			attack.pixel_y = 12 * y_sign
			animate(attack, alpha = 175, transform = copy_transform.Scale(0.75), pixel_x = 4 * x_sign, pixel_y = 3 * y_sign, time = 0.2 SECONDS)
			animate(time = 0.1 SECONDS)
			animate(alpha = 0, time = 0.1 SECONDS, easing = CIRCULAR_EASING|EASE_OUT)

		if (ATTACK_ANIMATION_PIERCE)
			var/attack_angle = dir2angle(direction) + rand(-7, 7)
			// Deducting 90 because we're assuming that icon_angle of 0 means an east-facing sprite
			var/anim_angle = attack_angle - 90 - used_item.icon_angle
			var/angle_mult = 1
			if (x_sign && y_sign)
				angle_mult = 1.4
			attack.pixel_x = 22 * x_sign * angle_mult
			attack.pixel_y = 18 * y_sign * angle_mult
			attack.transform = attack.transform.Turn(anim_angle)
			copy_transform = copy_transform.Turn(anim_angle)
			animate(
				attack,
				pixel_x = (22 * x_sign - 12 * sin(attack_angle)) * angle_mult,
				pixel_y = (18 * y_sign - 8 * cos(attack_angle)) * angle_mult,
				time = 0.1 SECONDS,
				easing = CUBIC_EASING|EASE_IN,
			)
			animate(
				attack,
				alpha = 175,
				transform = copy_transform.Scale(0.75),
				pixel_x = (22 * x_sign + 26 * sin(attack_angle)) * angle_mult,
				pixel_y = (18 * y_sign + 22 * cos(attack_angle)) * angle_mult,
				time = 0.3 SECONDS,
				easing = CUBIC_EASING|EASE_OUT,
			)
			animate(
				alpha = 0,
				pixel_x = -3 * -(x_sign + sin(attack_angle)),
				pixel_y = -2 * -(y_sign + cos(attack_angle)),
				time = 0.1 SECONDS,
				easing = CIRCULAR_EASING|EASE_OUT
			)

		if (ATTACK_ANIMATION_SLASH)
			attack.pixel_x = 18 * x_sign
			attack.pixel_y = 14 * y_sign
			var/x_rot_sign = 0
			var/y_rot_sign = 0
			var/attack_dir = (prob(50) ? 1 : -1)
			var/anim_angle = dir2angle(direction) - 90 - used_item.icon_angle

			if (x_sign)
				y_rot_sign = attack_dir
			if (y_sign)
				x_rot_sign = attack_dir

			// Animations are flipped, so flip us too!
			if (x_sign > 0 || y_sign < 0)
				attack_dir *= -1

			// We're swinging diagonally, use separate logic
			var/anim_dir = attack_dir
			if (x_sign && y_sign)
				if (attack_dir < 0)
					x_rot_sign = -x_sign * 1.4
					y_rot_sign = 0
				else
					x_rot_sign = 0
					y_rot_sign = -y_sign * 1.4

				// Flip us if we've been flipped *unless* we're flipped due to both axis
				if ((x_sign < 0 && y_sign > 0) || (x_sign > 0 && y_sign < 0))
					anim_dir *= -1

			attack.pixel_x += 10 * x_rot_sign
			attack.pixel_y += 8 * y_rot_sign
			attack.transform = attack.transform.Turn(anim_angle - 45 * anim_dir)
			copy_transform = copy_transform.Scale(0.75)
			animate(attack, alpha = 175, time = 0.3 SECONDS, flags = ANIMATION_PARALLEL)
			animate(time = 0.1 SECONDS)
			animate(alpha = 0, time = 0.1 SECONDS, easing = CIRCULAR_EASING|EASE_OUT)

			animate(attack, transform = copy_transform.Turn(anim_angle + 45 * anim_dir), time = 0.3 SECONDS, flags = ANIMATION_PARALLEL)

			var/x_return = 10 * -x_rot_sign
			var/y_return = 8 * -y_rot_sign

			if (!x_rot_sign)
				x_return = 18 * x_sign
			if (!y_rot_sign)
				y_return = 14 * y_sign

			var/angle_mult = 1
			if (x_sign && y_sign)
				angle_mult = 1.4
				if (attack_dir > 0)
					x_return = 8 * x_sign
					y_return = 14 * y_sign
				else
					x_return = 18 * x_sign
					y_return = 6 * y_sign

			animate(attack, pixel_x = 4 * x_sign * angle_mult, time = 0.2 SECONDS, easing = CIRCULAR_EASING | EASE_IN, flags = ANIMATION_PARALLEL)
			animate(pixel_x = x_return, time = 0.2 SECONDS, easing = CIRCULAR_EASING | EASE_OUT)

			animate(attack, pixel_y = 3 * y_sign * angle_mult, time = 0.2 SECONDS, easing = CIRCULAR_EASING | EASE_IN, flags = ANIMATION_PARALLEL)
			animate(pixel_y = y_return, time = 0.2 SECONDS, easing = CIRCULAR_EASING | EASE_OUT)

/// Common proc used by painting tools like spraycans and palettes that can access the entire 24 bits color space.
/obj/item/proc/pick_painting_tool_color(mob/user, default_color)
	var/chosen_color = input(user,"Pick new color", "[src]", default_color) as color|null
	if(!chosen_color || QDELETED(src) || IS_DEAD_OR_INCAP(user) || !user.is_holding(src))
		return
	set_painting_tool_color(chosen_color)

/obj/item/proc/set_painting_tool_color(chosen_color)
	SEND_SIGNAL(src, COMSIG_PAINTING_TOOL_SET_COLOR, chosen_color)

/**
 * Returns null if this object cannot be used to interact with physical writing mediums such as paper.
 * Returns a list of key attributes for this object interacting with paper otherwise.
 */
/obj/item/proc/get_writing_implement_details()
	return null

/**
 * When called on an item, and given a body targeting zone, this will return TRUE if the item slot matches the target zone, and FALSE otherwise.
 * Currently supports the jumpsuit, outersuit, backpack, belt, gloves, hat, ears, neck, mask, eyes, and feet slots. All other slots will auto return FALSE.
 */
/obj/item/proc/compare_zone_to_item_slot(zone)
	switch(slot_flags)
		if(ITEM_SLOT_ICLOTHING, ITEM_SLOT_OCLOTHING, ITEM_SLOT_BACK)
			return (zone == BODY_ZONE_CHEST)
		if(ITEM_SLOT_BELT)
			return (zone == BODY_ZONE_PRECISE_GROIN)
		if(ITEM_SLOT_GLOVES)
			return (zone == BODY_ZONE_R_ARM || zone == BODY_ZONE_L_ARM)
		if(ITEM_SLOT_HEAD, ITEM_SLOT_EARS, ITEM_SLOT_NECK)
			return (zone == BODY_ZONE_HEAD)
		if(ITEM_SLOT_MASK)
			return (zone == BODY_ZONE_PRECISE_MOUTH)
		if(ITEM_SLOT_EYES)
			return (zone == BODY_ZONE_PRECISE_EYES)
		if(ITEM_SLOT_FEET)
			return (zone == BODY_ZONE_L_LEG || zone == BODY_ZONE_R_LEG)
	return FALSE

/**
 * This proc calls at the begining of anytime an item is being equiped to a target by another mob.
 * It handles initial messages, AFK stripping, and initial logging.
 */
/obj/item/proc/item_start_equip(atom/target, obj/item/equipping, mob/user, show_visible_message = TRUE)

	if(show_visible_message)
		if(HAS_TRAIT(equipping, TRAIT_DANGEROUS_OBJECT))
			target.visible_message(
				span_danger("[user] tries to put [equipping] on [target]."),
				span_userdanger("[user] tries to put [equipping] on you."),
				ignored_mobs = user,
			)

		else
			target.visible_message(
				span_notice("[user] tries to put [equipping] on [target]."),
				span_notice("[user] tries to put [equipping] on you."),
				ignored_mobs = user,
			)

		if(ishuman(target))
			var/mob/living/carbon/human/victim_human = target
			if(victim_human.key && !victim_human.client) // AKA braindead
				if(victim_human.stat <= SOFT_CRIT && LAZYLEN(victim_human.afk_thefts) <= AFK_THEFT_MAX_MESSAGES)
					var/list/new_entry = list(list(user.name, "tried equipping you with [equipping]", world.time))
					LAZYADD(victim_human.afk_thefts, new_entry)

			else if(victim_human.is_blind())
				to_chat(target, span_userdanger("You feel someone trying to put something on you."))
	user.do_item_attack_animation(target, used_item = equipping)

	to_chat(user, span_notice("You try to put [equipping] on [target]..."))

	user.log_message("is putting [equipping] on [key_name(target)]", LOG_ATTACK, color="red")
	target.log_message("is having [equipping] put on them by [key_name(user)]", LOG_VICTIM, color="orange", log_globally=FALSE)

/obj/item/update_atom_colour()
	. = ..()
	update_slot_icon()

/// Modifies the fantasy variable
/obj/item/proc/modify_fantasy_variable(variable_key, value, bonus, minimum = 0)
	var/result = LAZYACCESS(fantasy_modifications, variable_key)
	if(!isnull(result))
		if(HAS_TRAIT(src, TRAIT_INNATELY_FANTASTICAL_ITEM))
			return result // we are immune to your foul magicks you inferior wizard, we keep our bonuses

		stack_trace("modify_fantasy_variable was called twice for the same key '[variable_key]' on type '[type]' before reset_fantasy_variable could be called!")

	var/intended_target = value + bonus
	value = max(minimum, intended_target)

	var/difference = intended_target - value
	var/modified_amount = bonus - difference
	LAZYSET(fantasy_modifications, variable_key, modified_amount)
	return value

/// Returns the original fantasy variable value
/obj/item/proc/reset_fantasy_variable(variable_key, current_value)
	var/modification = LAZYACCESS(fantasy_modifications, variable_key)

	if(isnum(modification) && HAS_TRAIT(src, TRAIT_INNATELY_FANTASTICAL_ITEM))
		return modification // we are immune to your foul magicks you inferior wizard, we keep our bonuses the way they are

	LAZYREMOVE(fantasy_modifications, variable_key)
	if(isnull(modification))
		return current_value

	return current_value - modification

/obj/item/proc/apply_fantasy_bonuses(bonus)
	SHOULD_CALL_PARENT(TRUE)
	SEND_SIGNAL(src, COMSIG_ITEM_APPLY_FANTASY_BONUSES, bonus)
	force = modify_fantasy_variable("force", force, bonus)
	throwforce = modify_fantasy_variable("throwforce", throwforce, bonus)
	wound_bonus = modify_fantasy_variable("wound_bonus", wound_bonus, bonus)
	bare_wound_bonus = modify_fantasy_variable("bare_wound_bonus", bare_wound_bonus, bonus)
	toolspeed = modify_fantasy_variable("toolspeed", toolspeed, -bonus/10, minimum = 0.1)

/obj/item/proc/remove_fantasy_bonuses(bonus)
	SHOULD_CALL_PARENT(TRUE)
	force = reset_fantasy_variable("force", force)
	throwforce = reset_fantasy_variable("throwforce", throwforce)
	wound_bonus = reset_fantasy_variable("wound_bonus", wound_bonus)
	bare_wound_bonus = reset_fantasy_variable("bare_wound_bonus", bare_wound_bonus)
	toolspeed = reset_fantasy_variable("toolspeed", toolspeed)
	SEND_SIGNAL(src, COMSIG_ITEM_REMOVE_FANTASY_BONUSES, bonus)

//automatically finds tool behavior if there is only one. requires an extension of the proc if a tool has multiple behaviors
/obj/item/proc/get_all_tool_behaviours()
	if (!isnull(tool_behaviour))
		return list(tool_behaviour)
	return null

/obj/item/animate_atom_living(mob/living/owner)
	new /mob/living/basic/mimic/copy(drop_location(), src, owner)

/**
 * Used to update the weight class of the item in a way that other atoms can react to the change.
 *
 * Arguments:
 * * new_w_class - The new weight class of the item.
 *
 * Returns:
 * * TRUE if weight class was successfully updated
 * * FALSE otherwise
 */
/obj/item/proc/update_weight_class(new_w_class)
	if(w_class == new_w_class)
		return FALSE

	var/old_w_class = w_class
	w_class = new_w_class
	SEND_SIGNAL(src, COMSIG_ITEM_WEIGHT_CLASS_CHANGED, old_w_class, new_w_class)
	if(!isnull(loc))
		SEND_SIGNAL(loc, COMSIG_ATOM_CONTENTS_WEIGHT_CLASS_CHANGED, src, old_w_class, new_w_class)
	return TRUE

/**
 * Used to determine if an item should be considered contraband by N-spect scanners or scanner gates.
 * Returns true when an item has the contraband trait, or is included in the traitor uplink.
 */
/obj/item/proc/is_contraband()
	if(HAS_TRAIT(src, TRAIT_CONTRABAND))
		return TRUE
	for(var/datum/uplink_item/traitor_item as anything in SStraitor.uplink_items)
		if(istype(src, traitor_item.item))
			if(!(traitor_item.uplink_item_flags & SYNDIE_TRIPS_CONTRABAND))
				return FALSE
			return TRUE
	return FALSE

/obj/item/apply_main_material_effects(datum/material/main_material, amount, multipier)
	. = ..()
	if(material_flags & MATERIAL_GREYSCALE)
		var/main_mat_type = main_material.type
		var/worn_path = get_material_greyscale_config(main_mat_type, greyscale_config_worn)
		var/lefthand_path = get_material_greyscale_config(main_mat_type, greyscale_config_inhand_left)
		var/righthand_path = get_material_greyscale_config(main_mat_type, greyscale_config_inhand_right)
		set_greyscale(
			new_worn_config = worn_path,
			new_inhand_left = lefthand_path,
			new_inhand_right = righthand_path
		)
	if(!main_material.item_sound_override)
		return
	hitsound = main_material.item_sound_override
	usesound = main_material.item_sound_override
	mob_throw_hit_sound = main_material.item_sound_override
	equip_sound = main_material.item_sound_override
	pickup_sound = main_material.item_sound_override
	drop_sound = main_material.item_sound_override

/obj/item/remove_main_material_effects(datum/material/main_material, amount, multipier)
	. = ..()
	if(material_flags & MATERIAL_GREYSCALE)
		set_greyscale(
			new_worn_config = initial(greyscale_config_worn),
			new_inhand_left = initial(greyscale_config_inhand_left),
			new_inhand_right = initial(greyscale_config_inhand_right)
		)
	if(!main_material.item_sound_override)
		return
	hitsound = initial(hitsound)
	usesound = initial(usesound)
	mob_throw_hit_sound = initial(mob_throw_hit_sound)
	equip_sound = initial(equip_sound)
	pickup_sound = initial(pickup_sound)
	drop_sound = initial(drop_sound)

/obj/item/apply_single_mat_effect(datum/material/material, mat_amount, multiplier)
	. = ..()
	if(!(material_flags & MATERIAL_AFFECT_STATISTICS) || (material_flags & MATERIAL_NO_SLOWDOWN) || !material.added_slowdown)
		return
	slowdown += GET_MATERIAL_MODIFIER(material.added_slowdown * mat_amount, multiplier)

/obj/item/remove_single_mat_effect(datum/material/material, mat_amount, multiplier)
	. = ..()
	if(!(material_flags & MATERIAL_AFFECT_STATISTICS) || (material_flags & MATERIAL_NO_SLOWDOWN) || !material.added_slowdown)
		return
	slowdown -= GET_MATERIAL_MODIFIER(material.added_slowdown * mat_amount, multiplier)

/**
 * Returns the atom(either itself or an internal module) that will interact/attack the target on behalf of us
 * For example an object can have different `tool_behaviours` (e.g borg omni tool) but will return an internal reference of that tool to attack for us
 * You can use it for general purpose polymorphism if you need a proxy atom to interact in a specific way
 * with a target on behalf on this atom
 *
 * Currently used only in the object melee attack chain but can be used anywhere else or even moved up to the atom level if required
 */
/obj/item/proc/get_proxy_attacker_for(atom/target, mob/user)
	RETURN_TYPE(/obj/item)

	return src

/// Checks if the bait is liked by the fish type or not. Returns a multiplier that affects the chance of catching it.
/obj/item/proc/check_bait(obj/item/fish/fish)
	if(HAS_TRAIT(src, TRAIT_OMNI_BAIT))
		return 1
	var/catch_multiplier = 1

	var/list/properties = SSfishing.fish_properties[isfish(fish) ? fish.type : fish]
	//Bait matching likes doubles the chance
	var/list/fav_bait = properties[FISH_PROPERTIES_FAV_BAIT]
	for(var/bait_identifer in fav_bait)
		if(is_matching_bait(src, bait_identifer))
			catch_multiplier *= 2
	//Bait matching dislikes
	var/list/disliked_bait = properties[FISH_PROPERTIES_BAD_BAIT]
	for(var/bait_identifer in disliked_bait)
		if(is_matching_bait(src, bait_identifer))
			catch_multiplier *= 0.5
	return catch_multiplier

/// Helper proc that checks if a bait matches identifier from fav/disliked bait list
/proc/is_matching_bait(obj/item/bait, identifier)
	if(ispath(identifier)) //Just a path
		return istype(bait, identifier)
	if(!islist(identifier))
		return HAS_TRAIT(bait, identifier)
	var/list/special_identifier = identifier
	switch(special_identifier[FISH_BAIT_TYPE])
		if(FISH_BAIT_FOODTYPE)
			var/datum/component/edible/edible = bait.GetComponent(/datum/component/edible)
			return edible?.foodtypes & special_identifier[FISH_BAIT_VALUE]
		if(FISH_BAIT_REAGENT)
			return bait.reagents?.has_reagent(special_identifier[FISH_BAIT_VALUE], special_identifier[FISH_BAIT_AMOUNT], check_subtypes = TRUE)
		else
			CRASH("Unknown bait identifier in fish favourite/disliked list")

/obj/item/vv_get_header()
	. = ..()
	. += {"
		<br><font size='1'>
			DAMTYPE: <font size='1'><a href='byond://?_src_=vars;[HrefToken()];item_to_tweak=[REF(src)];var_tweak=damtype' id='damtype'>[uppertext(damtype)]</a>
			FORCE: <font size='1'><a href='byond://?_src_=vars;[HrefToken()];item_to_tweak=[REF(src)];var_tweak=force' id='force'>[force]</a>
			WOUND: <font size='1'><a href='byond://?_src_=vars;[HrefToken()];item_to_tweak=[REF(src)];var_tweak=wound' id='wound'>[wound_bonus]</a>
			BARE WOUND: <font size='1'><a href='byond://?_src_=vars;[HrefToken()];item_to_tweak=[REF(src)];var_tweak=bare wound' id='bare wound'>[bare_wound_bonus]</a>
		</font>
	"}

/// Fetches, or lazyloads, our embedding datum
/obj/item/proc/get_embed()
	RETURN_TYPE(/datum/embedding)
	// Something may call this during qdeleting, which would cause a harddel
	if (QDELETED(src))
		return null
	if (embed_data)
		return embed_data
	if (embed_type)
		embed_data = new embed_type(src)
	return embed_data

/// Sets our embedding datum to a different one. Can also take types
/obj/item/proc/set_embed(datum/embedding/new_embed)
	if (new_embed == embed_data)
		return

	// Needs to be QDELETED as embed data uses this to clean itself up from its parent (us)
	if (!QDELETED(embed_data))
		qdel(embed_data)

	if (ispath(new_embed))
		new_embed = new new_embed(src)

	embed_data = new_embed
	SEND_SIGNAL(src, COMSIG_ITEM_EMBEDDING_UPDATE)

/// Embed ourselves into an object if we possess embedding data
/obj/item/proc/force_embed(mob/living/carbon/victim, obj/item/bodypart/target_limb)
	if (!istype(victim))
		return FALSE

	if (!istype(target_limb))
		target_limb = victim.get_bodypart(target_limb) || victim.bodyparts[1]

	return get_embed()?.embed_into(victim, target_limb)
