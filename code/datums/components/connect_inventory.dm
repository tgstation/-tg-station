/// Behaves similar to connect_loc_behalf, but hooks into signals on items in the user's inventory
/datum/component/connect_inventory
	dupe_mode = COMPONENT_DUPE_UNIQUE

	var/list/connections

	var/mob/living/tracked

	var/allowed_slots

/datum/component/connect_inventory/Initialize(mob/living/tracked, connections, allowed_slots = ALL)
	. = ..()
	if(!istype(tracked))
		return COMPONENT_INCOMPATIBLE
	src.connections = connections
	src.tracked = tracked
	src.allowed_slots = allowed_slots

/datum/component/connect_inventory/RegisterWithParent()
	RegisterSignal(tracked, COMSIG_MOB_EQUIPPED_ITEM, PROC_REF(on_equipped_item))
	RegisterSignal(tracked, COMSIG_QDELETING, PROC_REF(handle_tracked_qdel))
	update_signals()

/datum/component/connect_inventory/UnregisterFromParent()
	unregister_signals()
	UnregisterSignal(tracked, list(COMSIG_MOB_EQUIPPED_ITEM, COMSIG_MOB_UNEQUIPPED_ITEM))

/datum/component/connect_inventory/proc/handle_tracked_qdel()
	SIGNAL_HANDLER
	qdel(src)

/datum/component/connect_inventory/proc/update_signals()
	unregister_signals()

	for(var/obj/item/item as anything in tracked.get_equipped_items(INCLUDE_POCKETS | INCLUDE_HELD))
		if(!(allowed_slots & tracked.get_slot_by_item(item)))
			continue
		RegisterSignal(item, COMSIG_ITEM_DROPPED, PROC_REF(on_unequipped_item))
		for(var/signal in connections)
			parent.RegisterSignal(item, signal, connections[signal])

/datum/component/connect_inventory/proc/unregister_signals()
	for(var/obj/item/item as anything in tracked.get_equipped_items(INCLUDE_POCKETS | INCLUDE_HELD))
		UnregisterSignal(item, COMSIG_ITEM_DROPPED)
		parent.UnregisterSignal(item, connections)

/datum/component/connect_inventory/proc/on_equipped_item(datum/source, obj/item/equipped, slot)
	SIGNAL_HANDLER
	if(!(allowed_slots & slot))
		return
	// This handler has to be registered on the component itself because users may have their own COMSIG_ITEM_DROPPED handler for the equipped item
	RegisterSignal(equipped, COMSIG_ITEM_DROPPED, PROC_REF(on_unequipped_item))
	for(var/signal in connections)
		parent.RegisterSignal(equipped, signal, connections[signal])

/datum/component/connect_inventory/proc/on_unequipped_item(obj/item/unequipped)
	SIGNAL_HANDLER
	UnregisterSignal(unequipped, COMSIG_ITEM_DROPPED)
	parent.UnregisterSignal(unequipped, connections)
