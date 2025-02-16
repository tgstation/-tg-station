/obj/item/wallframe/fish
	name = "fish mount"
	desc = "The frame of a mount for trophy fish, to show off your proudest catch."
	icon = 'icons/obj/wallmounts.dmi'
	icon_state = "fish_mount_item"
	result_path = /obj/structure/fish_mount
	custom_materials = list(/datum/material/wood = SHEET_MATERIAL_AMOUNT)
	pixel_shift = 31
	///Reference to the persistent_id of the mount this was spawned from.
	var/persistence_id

/obj/item/wallframe/fish/after_attach(obj/structure/fish_mount/mount)
	. = ..()
	mount.persistence_id = persistence_id

///A wallmounted structure on which a fish can be attached to be used as room decoration.
/obj/structure/fish_mount
	name = "fish mount"
	desc = "A mount for trophy fish, to show off your proudest catch."
	icon = 'icons/obj/wallmounts.dmi'
	icon_state = "fish_mount"
	anchored = TRUE
	opacity = FALSE
	density = FALSE
	layer = SIGN_LAYER
	max_integrity = 100
	custom_materials = list(/datum/material/wood = SHEET_MATERIAL_AMOUNT)
	armor_type = /datum/armor/structure_sign
	resistance_flags = FLAMMABLE
	/// The instance of the fish mounted on this.
	var/obj/item/fish/mounted_fish
	/// The identifier for mounts that carry the trophy between rounds.
	var/persistence_id
	/// Trophies from persistence have a good chance to be dusted if removal is attempted, though rarely it pays off.
	var/persistence_loaded_fish = FALSE

/obj/structure/fish_mount/Initialize(mapload, floor_to_wall_dir)
	. = ..()
	//Mounted fish shouldn't flop. It should also show size and weight to everyone.
	add_traits(list(TRAIT_STOP_FISH_FLOPPING, TRAIT_EXAMINE_FISH), INNATE_TRAIT)
	if(floor_to_wall_dir)
		setDir(floor_to_wall_dir)
	find_and_hang_on_wall()
	if(!persistence_id)
		return
	if(SSfishing.initialized)
		load_trophy_fish()
	else
		RegisterSignal(SSfishing, COMSIG_SUBSYSTEM_POST_INITIALIZE, PROC_REF(load_trophy_fish))

/obj/structure/fish_mount/Destroy(force)
	QDEL_NULL(mounted_fish)
	return ..()

/obj/structure/fish_mount/proc/load_trophy_fish(datum/source)
	SIGNAL_HANDLER
	SSpersistence.load_trophy_fish(src)
	UnregisterSignal(SSfishing, COMSIG_SUBSYSTEM_POST_INITIALIZE)
	if(!mounted_fish)
		add_first_fish()

/obj/structure/fish_mount/screwdriver_act(mob/living/user, obj/item/item)
	. = ..()
	balloon_alert(user, "removing mount...")
	if(!item.use_tool(src, user, 3 SECONDS, volume = 50))
		return ITEM_INTERACT_BLOCKING
	playsound(src, 'sound/items/deconstruct.ogg', 50, TRUE)
	balloon_alert_to_viewers("fish mount removed")
	deconstruct()
	return ITEM_INTERACT_SUCCESS

/obj/structure/fish_mount/proc/add_first_fish()
	var/obj/item/fish/fish_path = pick(subtypesof(/obj/item/fish) - list(typesof(/obj/item/fish/holo) + list(/obj/item/fish/starfish/chrystarfish))) // chrystarfish immediately shatters when placed
	if(fish_path.fish_id_redirect_path)
		fish_path = fish_path.fish_id_redirect_path
	var/fluff_name = pick("John Trasen III", "a nameless intern", "Pun Pun", AQUARIUM_COMPANY, "Unknown", "Central Command")
	add_fish(new fish_path(loc), from_persistence = TRUE, catcher = fluff_name)
	mounted_fish.randomize_size_and_weight()
	mounted_fish.set_status(FISH_DEAD)
	SSpersistence.save_trophy_fish(src)

/obj/structure/fish_mount/atom_deconstruct(disassembled = TRUE)
	. = ..()
	if(disassembled)
		var/obj/item/wallframe/fish/frame = new (loc)
		frame.persistence_id = persistence_id
	mounted_fish?.forceMove(loc)

/obj/structure/fish_mount/item_interaction(mob/living/user, obj/item/item, list/modifiers)
	if(!isfish(item) || user.combat_mode)
		return ..()
	if(mounted_fish)
		balloon_alert(user, "remove other fish first!")
		return ITEM_INTERACT_BLOCKING
	if(item.flags_1 & HOLOGRAM_1)
		balloon_alert(user, "fish not mountable!")
		return ITEM_INTERACT_BLOCKING
	balloon_alert(user, "mounting fish...")
	if(!do_after(user, 3 SECONDS, src) || mounted_fish)
		return ITEM_INTERACT_BLOCKING
	add_fish(item, catcher = user.name)
	balloon_alert_to_viewers("fish mounted")
	playsound(loc, 'sound/machines/click.ogg', 30, TRUE)
	return ITEM_INTERACT_SUCCESS

/obj/structure/fish_mount/proc/add_fish(obj/item/fish/fish, from_persistence = FALSE, catcher)
	if(QDELETED(src)) // don't ever try to add a fish to one of these that's already been deleted - and get rid of the one that was created
		qdel(fish)
		return
	if(QDELETED(fish)) // no adding deleted fishies either
		return
	if(mounted_fish)
		mounted_fish.forceMove(loc)
	fish.forceMove(src)
	vis_contents += fish
	fish.flags_1 |= IS_ONTOP_1
	fish.vis_flags |= (VIS_INHERIT_PLANE|VIS_INHERIT_LAYER)
	fish.interaction_flags_item &= ~INTERACT_ITEM_ATTACK_HAND_PICKUP
	fish.obj_flags &= ~UNIQUE_RENAME
	fish.remove_fillet_type()
	fish.anchored = TRUE
	mounted_fish = fish

	if(!fish.catcher_name)
		fish.catcher_name = catcher
	if(!fish.catch_date)
		fish.catch_date = "[time2text(world.realtime, "Day, Month DD")], [CURRENT_STATION_YEAR]"

	AddElement(/datum/element/beauty, get_fish_beauty())
	RegisterSignals(fish, list(COMSIG_ATOM_ATTACK_HAND, COMSIG_ATOM_ATTACK_PAW), PROC_REF(on_fish_attack_hand))
	rotate_fish(dir)
	if(from_persistence)
		persistence_loaded_fish = TRUE
		fish.add_traits(list(TRAIT_NO_FISHING_ACHIEVEMENT, TRAIT_FISH_LOW_PRICE), INNATE_TRAIT)
	else if(persistence_id)
		SSpersistence.save_trophy_fish(src)

/obj/structure/fish_mount/proc/get_fish_beauty()
	var/beauty = 100 + mounted_fish.beauty * 1.2
	var/datum/material/main_material = mounted_fish.get_master_material()
	if(main_material)
		beauty += main_material.beauty_modifier * mounted_fish.weight
	return round(beauty)

/obj/structure/fish_mount/proc/rotate_fish(direction, old_direction)
	var/rotation = angle2dir(REVERSE_DIR(direction))
	if(old_direction)
		rotation -= angle2dir(REVERSE_DIR(old_direction))

	if(!rotation)
		return
	mounted_fish.transform = mounted_fish.transform.Turn(rotation)

/obj/structure/fish_mount/setDir(newdir)
	var/old_dir = dir
	. = ..()
	rotate_fish(dir, old_dir)

/obj/structure/fish_mount/proc/on_fish_attack_hand(datum/source, mob/living/user)
	SIGNAL_HANDLER
	INVOKE_ASYNC(src, PROC_REF(remove_fish), user)
	return SECONDARY_ATTACK_CANCEL_ATTACK_CHAIN

/obj/structure/fish_mount/attack_hand_secondary(mob/living/user, list/modifiers)
	. = ..()
	if(!mounted_fish)
		balloon_alert(user, "no fish mounted!")
	else
		remove_fish(user)
	return SECONDARY_ATTACK_CANCEL_ATTACK_CHAIN

/obj/structure/fish_mount/proc/remove_fish(mob/living/user)
	balloon_alert(user, "removing fish...")
	if(!do_after(user, (persistence_loaded_fish ? 6 : 3) SECONDS, src) || !mounted_fish)
		return

	var/obj/item/fish/fish_reference = mounted_fish
	if(persistence_loaded_fish)
		roll_for_safe_removal(user)

	if(QDELETED(fish_reference))
		var/ash_type = /obj/effect/decal/cleanable/ash
		if(fish_reference.w_class >= WEIGHT_CLASS_BULKY)
			ash_type = /obj/effect/decal/cleanable/ash/large
		new ash_type(loc)
		visible_message("[fish_reference] turns into dust as [fish_reference.p_theyre()] removed from [src].")
	else
		user.put_in_hands(mounted_fish)
	balloon_alert_to_viewers("fish removed")

/obj/structure/fish_mount/Exited(atom/movable/gone)
	if(gone != mounted_fish)
		return ..()
	RemoveElement(/datum/element/beauty, get_fish_beauty())
	if(!QDELETED(mounted_fish) && (!persistence_loaded_fish || roll_for_safe_removal()))
		rotate_fish(0, dir)
		UnregisterSignal(mounted_fish, list(COMSIG_ATOM_ATTACK_HAND, COMSIG_ATOM_ATTACK_PAW))
		mounted_fish.flags_1 &= ~IS_ONTOP_1
		mounted_fish.vis_flags &= ~(VIS_INHERIT_PLANE|VIS_INHERIT_LAYER)
		mounted_fish.interaction_flags_item |= INTERACT_ITEM_ATTACK_HAND_PICKUP
		mounted_fish.obj_flags |= UNIQUE_RENAME
		mounted_fish.add_fillet_type()
		mounted_fish.anchored = FALSE
	persistence_loaded_fish = FALSE
	mounted_fish = null
	return ..()

/obj/structure/fish_mount/proc/roll_for_safe_removal(mob/living/user)
	if(isnull(mounted_fish))
		return FALSE

	///the base success rate is calculated considering the item inventory size and the heaviness of the fish.
	var/success_prob = 100/(mounted_fish.w_class + GET_FISH_WEIGHT_RANK(mounted_fish.weight))
	var/fishing_prowess = user?.mind?.get_skill_level(/datum/skill/fishing)
	success_prob += fishing_prowess * 4 // up to 28% fixed bonus chance to safely retrieve the trophy depending on skill.
	if(!prob(success_prob))
		qdel(mounted_fish)
		return FALSE

	persistence_loaded_fish = FALSE //this way we don't roll again on Exited()
	return TRUE

/obj/structure/fish_mount/bar
	persistence_id = "Bar"

MAPPING_DIRECTIONAL_HELPERS(/obj/structure/fish_mount/bar, /obj/item/wallframe/fish::pixel_shift)
