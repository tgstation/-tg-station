/obj/item/borg/apparatus
	name = "unknown storage apparatus"
	desc = "This device seems nonfunctional."
	icon = 'icons/mob/silicon/robot_items.dmi'
	icon_state = "hugmodule"
	/// The item stored inside of this apparatus
	var/obj/item/stored
	/// Whitelist of types allowed in this apparatus
	var/list/storable = list()

/obj/item/borg/apparatus/Initialize(mapload)
	RegisterSignal(loc.loc, COMSIG_BORG_SAFE_DECONSTRUCT, PROC_REF(safedecon))
	return ..()

/obj/item/borg/apparatus/Destroy()
	QDEL_NULL(stored)
	return ..()

///If we're safely deconstructed, we put the item neatly onto the ground, rather than deleting it.
/obj/item/borg/apparatus/proc/safedecon()
	SIGNAL_HANDLER

	if(stored)
		stored.forceMove(get_turf(src))
		stored = null

/obj/item/borg/apparatus/Exited(atom/movable/gone, direction)
	if(gone == stored) //sanity check
		UnregisterSignal(stored, COMSIG_ATOM_UPDATED_ICON)
		stored = null
	update_appearance()
	return ..()

///A right-click verb, for those not using hotkey mode.
/obj/item/borg/apparatus/verb/verb_dropHeld()
	set category = "Object"
	set name = "Drop"

	if(usr != loc || !stored)
		return
	stored.forceMove(get_turf(usr))
	return

/obj/item/borg/apparatus/get_proxy_attacker_for(atom/target, mob/user)
	if(stored) // Use the stored item if available
		return stored
	return ..()

/**
* Attack_self will pass for the stored item.
*/
/obj/item/borg/apparatus/attack_self(mob/living/silicon/robot/user)
	if(!stored || !issilicon(user))
		return ..()
	stored.attack_self(user)

//Alt click drops the stored item.
/obj/item/borg/apparatus/click_alt(mob/living/silicon/robot/user)
	if(!stored || !issilicon(user))
		return CLICK_ACTION_BLOCKING
	stored.forceMove(user.drop_location())
	return CLICK_ACTION_SUCCESS

/obj/item/borg/apparatus/pre_attack(atom/atom, mob/living/user, params)
	if(istype(atom.loc, /mob/living/silicon/robot) || istype(atom.loc, /obj/item/robot_model) || HAS_TRAIT(atom, TRAIT_NODROP))
		return ..() // Borgs should not be grabbing their own modules

	var/itemcheck = FALSE
	for(var/storable_type in storable)
		if(istype(atom, storable_type))
			itemcheck = TRUE
			break
	if(itemcheck)
		var/obj/item/item = atom
		item.forceMove(src)
		stored = item
		RegisterSignal(stored, COMSIG_ATOM_UPDATED_ICON, PROC_REF(on_stored_updated_icon))
		update_appearance()
		return TRUE
	return ..()

/**
 * Updates the appearance of the apparatus when the stored object's icon gets updated.
 *
 * Returns NONE as we have not done anything to the stored object itself,
 * which is where this signal that this handler intercepts is sent from.
 */
/obj/item/borg/apparatus/proc/on_stored_updated_icon(datum/source, updates)
	SIGNAL_HANDLER
	update_appearance()
	return NONE

/obj/item/borg/apparatus/attackby(obj/item/item, mob/user, params)
	if(stored)
		item.melee_attack_chain(user, stored, params)
		return
	return ..()

/obj/item/borg/apparatus/beaker
	name = "beaker storage apparatus"
	desc = "A special apparatus for carrying beakers, bottles, and test tubes without spilling their contents."
	icon_state = "borg_beaker_apparatus"
	storable = list(
		/obj/item/reagent_containers/cup/beaker,
		/obj/item/reagent_containers/cup/bottle,
		/obj/item/reagent_containers/cup/tube,
	)

/obj/item/borg/apparatus/beaker/Initialize(mapload)
	add_glass()
	RegisterSignal(stored, COMSIG_ATOM_UPDATED_ICON, PROC_REF(on_stored_updated_icon))
	update_appearance()
	return ..()

/obj/item/borg/apparatus/beaker/proc/add_glass()
	stored = new /obj/item/reagent_containers/cup/beaker/large(src)

/obj/item/borg/apparatus/beaker/Destroy()
	if(stored)
		var/obj/item/reagent_containers/reagent_container = stored
		reagent_container.SplashReagents(get_turf(src))
	QDEL_NULL(stored)
	return ..()

/obj/item/borg/apparatus/beaker/examine()
	. = ..()
	if(stored)
		var/obj/item/reagent_containers/reagent_container = stored
		. += "The apparatus currently has [reagent_container] secured, which contains:"
		if(length(reagent_container.reagents.reagent_list))
			for(var/datum/reagent/reagent in reagent_container.reagents.reagent_list)
				. += "[reagent.volume] units of [reagent.name]"
		else
			. += "Nothing."

	. += span_notice(" <i>Alt-click</i> will drop the currently stored beaker. ")

/obj/item/borg/apparatus/beaker/update_overlays()
	. = ..()
	var/mutable_appearance/arm = mutable_appearance(icon = icon, icon_state = "borg_beaker_apparatus_arm")
	if(stored)
		stored.pixel_x = 0
		stored.pixel_y = 0
		var/mutable_appearance/stored_copy = new /mutable_appearance(stored)
		if(istype(stored, /obj/item/reagent_containers/cup/beaker))
			arm.pixel_y = arm.pixel_y - 3
		stored_copy.layer = FLOAT_LAYER
		stored_copy.plane = FLOAT_PLANE
		. += stored_copy
	else
		arm.pixel_y = arm.pixel_y - 5
	. += arm

/obj/item/borg/apparatus/beaker/extra
	name = "secondary beaker storage apparatus"
	desc = "A supplementary beaker storage apparatus."

/obj/item/borg/apparatus/beaker/service
	name = "beverage storage apparatus"
	desc = "A special apparatus for carrying drinks and condiment packets without spilling their contents. Will resynthesize any drinks (or other nutritional liquids) you pour out of glasses!"
	icon_state = "borg_beaker_apparatus"
	storable = list(
		/obj/item/reagent_containers/cup/glass,
		/obj/item/reagent_containers/condiment,
		/obj/item/reagent_containers/cup/coffeepot,
		/obj/item/reagent_containers/cup/bottle/syrup_bottle,
	)

/obj/item/borg/apparatus/beaker/service/add_glass()
	stored = new /obj/item/reagent_containers/cup/glass/drinkingglass(src)
	handle_reflling(stored, loc.loc, force = TRUE)

/obj/item/borg/apparatus/beaker/service/proc/handle_reflling(obj/item/reagent_containers/cup/glass, mob/living/silicon/robot/bro, force = FALSE)
	if (isnull(bro))
		bro = loc
	if (!iscyborg(bro))
		return

	if (!stored || force)
		glass.AddComponent(/datum/component/reagent_refiller, power_draw_callback = CALLBACK(bro, TYPE_PROC_REF(/mob/living/silicon/robot, draw_power)))

/obj/item/borg/apparatus/beaker/service/Entered(atom/movable/arrived, atom/old_loc, list/atom/old_locs)
	if (!istype(arrived, /obj/item/reagent_containers/cup/glass))
		return
	handle_reflling(arrived)
	return ..()

///Used by the service borg drink apparatus upgrade, holds drink-related items
/obj/item/borg/apparatus/beaker/drink
	name = "secondary beverage storage apparatus"
	desc = "A special apparatus for carrying drinks and condiment packets without spilling their contents. Will NOT resynthesize drinks unlike your standard apparatus."
	icon_state = "borg_beaker_apparatus"
	storable = list(
		/obj/item/reagent_containers/cup/glass,
		/obj/item/reagent_containers/condiment,
		/obj/item/reagent_containers/cup/coffeepot,
		/obj/item/reagent_containers/cup/bottle/syrup_bottle,
		/obj/item/reagent_containers/cup/beaker,
	)

/obj/item/borg/apparatus/beaker/service2/add_glass()
	stored = new /obj/item/reagent_containers/cup/glass/drinkingglass(src)

/// allows medical cyborgs to manipulate organs without hands
/obj/item/borg/apparatus/organ_storage
	name = "organ storage bag"
	desc = "A container for holding body parts."
	icon = 'icons/obj/storage/storage.dmi'
	icon_state = "evidenceobj"
	item_flags = SURGICAL_TOOL
	storable = list(/obj/item/organ,
					/obj/item/bodypart)

/obj/item/borg/apparatus/organ_storage/examine()
	. = ..()
	. += "The organ bag currently contains:"
	if(stored)
		var/obj/item/organ = stored
		. += organ.name
	else
		. += "Nothing."
	. += span_notice(" <i>Alt-click</i> will drop the currently stored organ. ")

/obj/item/borg/apparatus/organ_storage/update_overlays()
	. = ..()
	icon_state = null // hides the original icon (otherwise it's drawn underneath)
	var/mutable_appearance/bag
	if(stored)
		var/mutable_appearance/stored_organ = new /mutable_appearance(stored)
		stored_organ.layer = FLOAT_LAYER
		stored_organ.plane = FLOAT_PLANE
		stored_organ.pixel_x = 0
		stored_organ.pixel_y = 0
		. += stored_organ
		bag = mutable_appearance(icon, icon_state = "evidence") // full bag
	else
		bag = mutable_appearance(icon, icon_state = "evidenceobj") // empty bag
	. += bag

/obj/item/borg/apparatus/organ_storage/click_alt(mob/living/silicon/robot/user)
	if(!stored)
		to_chat(user, span_notice("[src] is empty."))
		return CLICK_ACTION_BLOCKING

	var/obj/item/organ = stored
	user.visible_message(span_notice("[user] dumps [organ] from [src]."), span_notice("You dump [organ] from [src]."))
	cut_overlays()
	organ.forceMove(get_turf(src))
	return CLICK_ACTION_SUCCESS

///Apparatus to allow Engineering/Sabo borgs to manipulate any material sheets.
/obj/item/borg/apparatus/sheet_manipulator
	name = "material manipulation apparatus"
	desc = "An apparatus for carrying, deploying, and manipulating sheets of material. The device can also carry custom floor tiles and shuttle frame rods."
	icon_state = "borg_stack_apparatus"
	storable = list(/obj/item/stack/sheet,
					/obj/item/stack/tile,
					/obj/item/stack/rods/shuttle)

/obj/item/borg/apparatus/sheet_manipulator/Initialize(mapload)
	update_appearance()
	return ..()

/obj/item/borg/apparatus/sheet_manipulator/update_overlays()
	. = ..()
	var/mutable_appearance/arm = mutable_appearance(icon, "borg_stack_apparatus_arm1")
	if(stored)
		stored.pixel_x = 0
		stored.pixel_y = 0
		arm.icon_state = "borg_stack_apparatus_arm2"
		var/mutable_appearance/stored_copy = new /mutable_appearance(stored)
		var/underscore = findtext(stored_copy.icon_state, "_")
		if(underscore)
			stored_copy.icon_state = initial(stored.icon_state) //how we use the icon_state of single sheets, even with full stacks
		stored_copy.layer = FLOAT_LAYER
		stored_copy.plane = FLOAT_PLANE
		. += stored_copy
	. += arm

/obj/item/borg/apparatus/sheet_manipulator/examine()
	. = ..()
	if(stored)
		. += "The apparatus currently has [stored] secured."
	. += span_notice(" <i>Alt-click</i> will drop the currently stored sheets. ")

///Apparatus allowing Engineer/Sabo borgs to manipulate Machine and Computer circuit boards
/obj/item/borg/apparatus/circuit
	name = "circuit manipulation apparatus"
	desc = "A special apparatus for carrying and manipulating circuit boards."
	icon_state = "borg_hardware_apparatus"
	storable = list(/obj/item/circuitboard,
				/obj/item/electronics)

/obj/item/borg/apparatus/circuit/Initialize(mapload)
	update_appearance()
	return ..()

/obj/item/borg/apparatus/circuit/update_overlays()
	. = ..()
	var/mutable_appearance/arm = mutable_appearance(icon, "borg_hardware_apparatus_arm1")
	if(stored)
		stored.pixel_x = -3
		stored.pixel_y = 0
		if(!istype(stored, /obj/item/circuitboard))
			arm.icon_state = "borg_hardware_apparatus_arm2"
		var/mutable_appearance/stored_copy = new /mutable_appearance(stored)
		stored_copy.layer = FLOAT_LAYER
		stored_copy.plane = FLOAT_PLANE
		. += stored_copy
	. += arm

/obj/item/borg/apparatus/circuit/examine()
	. = ..()
	if(stored)
		. += "The apparatus currently has [stored] secured."
	. += span_notice(" <i>Alt-click</i> will drop the currently stored circuit. ")

/obj/item/borg/apparatus/circuit/pre_attack(atom/atom, mob/living/user, params)
	if(istype(atom, /obj/item/ai_module) && !stored) //If an admin wants a borg to upload laws, who am I to stop them? Otherwise, we can hint that it fails
		to_chat(user, span_warning("This circuit board doesn't seem to have standard robot apparatus pin holes. You're unable to pick it up."))
	return ..()

/obj/item/borg/apparatus/service
	name = "service apparatus"
	desc = "A special apparatus for carrying food, seeds, grafts, bowls, plates, oven trays, soup pots and paper."
	icon_state = "borg_service_apparatus"
	storable = list(
		/obj/item/food,
		/obj/item/paper,
		/obj/item/plate,
		/obj/item/plate/oven_tray,
		/obj/item/reagent_containers/cup/bowl,
		/obj/item/reagent_containers/cup/soup_pot,
		/obj/item/seeds,
		/obj/item/graft,
		/obj/item/fish,
	)

/obj/item/borg/apparatus/service/Initialize(mapload)
	update_appearance()
	return ..()

/obj/item/borg/apparatus/service/update_overlays()
	. = ..()
	var/mutable_appearance/arm = mutable_appearance(icon, "borg_hardware_apparatus_arm1")
	if(stored)
		stored.pixel_x = -3
		stored.pixel_y = 0
		if((!istype(stored, /obj/item/plate/oven_tray)) || (!istype(stored, /obj/item/food)))
			arm.icon_state = "borg_hardware_apparatus_arm2"
		var/mutable_appearance/stored_copy = new /mutable_appearance(stored)
		stored_copy.layer = FLOAT_LAYER
		stored_copy.plane = FLOAT_PLANE
		. += stored_copy
	. += arm

/obj/item/borg/apparatus/service/examine()
	. = ..()
	if(stored)
		. += "The apparatus currently has [stored] secured."
	. += span_notice("<i>Alt-click</i> will drop the currently secured item.")
