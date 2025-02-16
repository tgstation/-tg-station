/**
 * ### envenomable caseless element!
 *
 * Non bespoke element (1 in existence) that lets caseless bullets be dippable.
 * When you fire the bullet, it will gain venomous. The casing itself isn't venomous to prevent bullshit
 */
/datum/element/envenomable_casing
	element_flags = ELEMENT_BESPOKE
	argument_hash_start_idx = 2
	/// how much reagent can you dip the caseless in?
	var/amount_allowed

/datum/element/envenomable_casing/Attach(datum/target, amount_allowed = 5)
	. = ..()
	if(!isammocasing(target))
		return ELEMENT_INCOMPATIBLE
	src.amount_allowed = amount_allowed
	RegisterSignal(target, COMSIG_ITEM_INTERACTING_WITH_ATOM, PROC_REF(handle_interaction))
	RegisterSignal(target, COMSIG_ATOM_EXAMINE, PROC_REF(on_examine_before_dip))

/datum/element/envenomable_casing/Detach(datum/target)
	. = ..()
	UnregisterSignal(target, list(COMSIG_ITEM_AFTERATTACK, COMSIG_ATOM_EXAMINE))

///signal called on the parent attacking an item
/datum/element/envenomable_casing/proc/handle_interaction(obj/item/ammo_casing/casing, mob/user, atom/target, click_parameters)
	SIGNAL_HANDLER
	if(!is_reagent_container(target))
		return NONE
	var/obj/item/reagent_containers/venom_container = target
	if(!casing.loaded_projectile)
		user.balloon_alert(user, "casing is already spent!")
		return ITEM_INTERACT_BLOCKING
	if(!(venom_container.reagent_flags & OPENCONTAINER))
		user.balloon_alert(user, "open the container!")
		return ITEM_INTERACT_BLOCKING
	var/datum/reagent/venom_applied = venom_container.reagents.get_master_reagent()
	if(!venom_applied)
		return ITEM_INTERACT_BLOCKING
	var/amount_applied = min(venom_applied.volume, amount_allowed)

	casing.loaded_projectile.AddElement(/datum/element/venomous, venom_applied.type, amount_applied)
	to_chat(user, span_notice("You coat [casing] in [venom_applied]."))
	venom_container.reagents.remove_reagent(venom_applied.type, amount_applied)
	///stops further poison application
	UnregisterSignal(casing, COMSIG_ITEM_INTERACTING_WITH_ATOM)
	RegisterSignal(casing, COMSIG_ATOM_EXAMINE, PROC_REF(on_examine_after_dip), override = TRUE)
	return ITEM_INTERACT_SUCCESS

///signal called on parent being examined while not coated
/datum/element/envenomable_casing/proc/on_examine_before_dip(obj/item/ammo_casing/casing, mob/user, list/examine_list)
	SIGNAL_HANDLER
	examine_list += span_notice("You can dip it in a chemical to deliver a poisonous kick.")

///ditto, but after it's been coated
/datum/element/envenomable_casing/proc/on_examine_after_dip(obj/item/ammo_casing/casing, mob/user, list/examine_list)
	SIGNAL_HANDLER
	examine_list += span_warning("It's coated in some kind of chemical...")
