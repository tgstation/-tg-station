/**
 * Component for allowing items to be inserted into foam darts.
 * The parent can register signal handlers for `COMSIG_DART_INSERT_ADDED`,
 * `COMSIG_DART_INSERT_REMOVED` to define custom behavior for when the item
 * is added to/removed from a dart, and `COMSIG_DART_INSERT_GET_VAR_MODIFIERS`
 * to define the modifications the item makes to the vars of the fired projectile.
 */
/datum/component/dart_insert
	/// List for tracking the modifications this component has made to the vars of the containing projectile
	var/list/var_modifiers
	/// A reference to the ammo casing this component's parent was inserted into
	var/obj/item/ammo_casing/holder_casing
	/// A reference to the projectile this component's parent was inserted into
	var/obj/projectile/holder_projectile
	/// The icon file used for the overlay applied over the containing ammo casing
	var/casing_overlay_icon
	/// The icon state used for the overlay applied over the containing ammo casing
	var/casing_overlay_icon_state
	/// The icon file used for the overlay applied over the containing projectile
	var/projectile_overlay_icon
	/// The icon state used for the overlay applied over the containing projectile
	var/projectile_overlay_icon_state
	/// Optional callback to invoke when acquiring projectile var modifiers
	var/datum/callback/modifier_getter

/datum/component/dart_insert/Initialize(_casing_overlay_icon, _casing_overlay_icon_state, _projectile_overlay_icon, _projectile_overlay_icon_state, datum/callback/_modifier_getter)
	if(!isitem(parent))
		return COMPONENT_INCOMPATIBLE
	casing_overlay_icon = _casing_overlay_icon
	casing_overlay_icon_state = _casing_overlay_icon_state
	projectile_overlay_icon = _projectile_overlay_icon
	projectile_overlay_icon_state = _projectile_overlay_icon_state
	modifier_getter = _modifier_getter

/datum/component/dart_insert/RegisterWithParent()
	. = ..()
	RegisterSignal(parent, COMSIG_ITEM_PRE_ATTACK, PROC_REF(on_preattack))
	RegisterSignal(parent, COMSIG_OBJ_RESKIN, PROC_REF(on_reskin))

/datum/component/dart_insert/UnregisterFromParent()
	. = ..()
	var/obj/item/parent_item = parent
	var/parent_loc = parent_item.loc
	if(parent_loc && (parent_loc == holder_casing || parent_loc == holder_projectile))
		parent_item.forceMove(get_turf(parent_item))
	remove_from_dart(holder_casing, holder_projectile)
	UnregisterSignal(parent, COMSIG_ITEM_PRE_ATTACK)

/datum/component/dart_insert/proc/on_preattack(datum/source, atom/target, mob/user, params)
	SIGNAL_HANDLER
	var/obj/item/ammo_casing/foam_dart/dart = target
	if(!istype(dart))
		return
	if(!dart.modified)
		to_chat(user, span_warning("The safety cap prevents you from inserting [parent] into [dart]."))
		return COMPONENT_CANCEL_ATTACK_CHAIN
	if(HAS_TRAIT(dart, TRAIT_DART_HAS_INSERT))
		to_chat(user, span_warning("There's already something in [dart]."))
		return COMPONENT_CANCEL_ATTACK_CHAIN
	add_to_dart(dart, user)
	return COMPONENT_CANCEL_ATTACK_CHAIN

/datum/component/dart_insert/proc/on_reskin(datum/source, mob/user, skin)
	SIGNAL_HANDLER
	SEND_SIGNAL(parent, COMSIG_DART_INSERT_PARENT_RESKINNED)

/datum/component/dart_insert/proc/add_to_dart(obj/item/ammo_casing/dart, mob/user)
	var/obj/projectile/dart_projectile = dart.loaded_projectile
	var/obj/item/parent_item = parent
	if(user)
		if(!user.transferItemToLoc(parent_item, dart_projectile))
			return
		to_chat(user, span_notice("You insert [parent_item] into [dart]."))
	else
		parent_item.forceMove(dart_projectile)
	ADD_TRAIT(dart, TRAIT_DART_HAS_INSERT, REF(src))
	RegisterSignal(dart, COMSIG_ITEM_ATTACK_SELF, PROC_REF(on_dart_attack_self))
	RegisterSignal(dart, COMSIG_ATOM_EXAMINE_MORE, PROC_REF(on_dart_examine_more))
	RegisterSignals(parent, list(COMSIG_QDELETING, COMSIG_MOVABLE_MOVED), PROC_REF(on_leave_dart))
	RegisterSignal(dart, COMSIG_ATOM_UPDATE_OVERLAYS, PROC_REF(on_casing_update_overlays))
	RegisterSignal(dart_projectile, COMSIG_ATOM_UPDATE_OVERLAYS, PROC_REF(on_projectile_update_overlays))
	RegisterSignals(dart_projectile, list(COMSIG_PROJECTILE_ON_SPAWN_DROP, COMSIG_PROJECTILE_ON_SPAWN_EMBEDDED), PROC_REF(on_spawn_drop))
	apply_var_modifiers(dart_projectile)
	dart.harmful = dart_projectile.damage > 0 || dart_projectile.wound_bonus > 0 || dart_projectile.bare_wound_bonus > 0
	SEND_SIGNAL(parent, COMSIG_DART_INSERT_ADDED, dart)
	dart.update_appearance()
	dart_projectile.update_appearance()
	holder_casing = dart
	holder_projectile = dart_projectile

/datum/component/dart_insert/proc/remove_from_dart(obj/item/ammo_casing/dart, obj/projectile/projectile, mob/user)
	holder_casing = null
	holder_projectile = null
	if(istype(dart))
		UnregisterSignal(dart, list(COMSIG_ITEM_ATTACK_SELF, COMSIG_ATOM_EXAMINE_MORE, COMSIG_ATOM_UPDATE_OVERLAYS))
		REMOVE_TRAIT(dart, TRAIT_DART_HAS_INSERT, REF(src))
		dart.update_appearance()
	if(istype(projectile))
		remove_var_modifiers(projectile)
		UnregisterSignal(projectile, list(COMSIG_PROJECTILE_ON_SPAWN_DROP, COMSIG_PROJECTILE_ON_SPAWN_EMBEDDED, COMSIG_ATOM_UPDATE_OVERLAYS))
		if(dart?.loaded_projectile == projectile)
			dart.harmful = projectile.damage > 0 || projectile.wound_bonus > 0 || projectile.bare_wound_bonus > 0
		projectile.update_appearance()
	SEND_SIGNAL(parent, COMSIG_DART_INSERT_REMOVED, dart, projectile, user)
	UnregisterSignal(parent, list(COMSIG_QDELETING, COMSIG_MOVABLE_MOVED))
	if(user)
		INVOKE_ASYNC(user, TYPE_PROC_REF(/mob, put_in_hands), parent)
		to_chat(user, span_notice("You remove [parent] from [dart]."))

/datum/component/dart_insert/proc/on_dart_attack_self(datum/source, mob/user)
	SIGNAL_HANDLER
	remove_from_dart(holder_casing, holder_projectile, user)

/datum/component/dart_insert/proc/on_dart_examine_more(datum/source, mob/user, list/examine_list)
	var/obj/item/parent_item = parent
	examine_list += span_notice("You can see a [parent_item.name] inserted into it.")

/datum/component/dart_insert/proc/on_leave_dart()
	SIGNAL_HANDLER
	remove_from_dart(holder_casing, holder_projectile)

/datum/component/dart_insert/proc/on_spawn_drop(datum/source, obj/item/ammo_casing/new_casing)
	SIGNAL_HANDLER
	UnregisterSignal(parent, list(COMSIG_QDELETING, COMSIG_MOVABLE_MOVED))
	add_to_dart(new_casing)

/datum/component/dart_insert/proc/on_casing_update_overlays(datum/source, list/new_overlays)
	SIGNAL_HANDLER
	new_overlays += mutable_appearance(casing_overlay_icon, casing_overlay_icon_state)

/datum/component/dart_insert/proc/on_projectile_update_overlays(datum/source, list/new_overlays)
	SIGNAL_HANDLER
	new_overlays += mutable_appearance(projectile_overlay_icon, projectile_overlay_icon_state)

/datum/component/dart_insert/proc/apply_var_modifiers(obj/projectile/projectile)
	if (!modifier_getter)
		return
	var_modifiers = modifier_getter.Invoke(projectile)
	projectile.damage += var_modifiers["damage"]
	projectile.speed += var_modifiers["speed"]
	projectile.armour_penetration += var_modifiers["armour_penetration"]
	projectile.wound_bonus += var_modifiers["wound_bonus"]
	projectile.bare_wound_bonus += var_modifiers["bare_wound_bonus"]
	projectile.demolition_mod += var_modifiers["demolition_mod"]
	if(var_modifiers["embedding"])
		projectile.set_embed(var_modifiers["embedding"])

/datum/component/dart_insert/proc/remove_var_modifiers(obj/projectile/projectile)
	projectile.damage -= var_modifiers["damage"]
	projectile.speed -= var_modifiers["speed"]
	projectile.armour_penetration -= var_modifiers["armour_penetration"]
	projectile.wound_bonus -= var_modifiers["wound_bonus"]
	projectile.bare_wound_bonus -= var_modifiers["bare_wound_bonus"]
	projectile.demolition_mod -= var_modifiers["demolition_mod"]
	if(var_modifiers["embedding"])
		projectile.set_embed(initial(projectile.embed_type))
	var_modifiers.Cut()
