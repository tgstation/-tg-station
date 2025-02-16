/// Multiplier applied on construction & deconstruction time when building multiple structures
#define FREQUENT_USE_DEBUFF_MULTIPLIER 3

//RAPID CONSTRUCTION DEVICE

/obj/item/construction/rcd
	name = "rapid-construction-device (RCD)"
	icon = 'icons/obj/tools.dmi'
	icon_state = "rcd"
	worn_icon_state = "RCD"
	lefthand_file = 'icons/mob/inhands/equipment/tools_lefthand.dmi'
	righthand_file = 'icons/mob/inhands/equipment/tools_righthand.dmi'
	custom_premium_price = PAYCHECK_COMMAND * 2
	max_matter = 160
	slot_flags = ITEM_SLOT_BELT
	item_flags = NO_MAT_REDEMPTION | NOBLUDGEON
	has_ammobar = TRUE
	actions_types = list(/datum/action/item_action/rcd_scan)
	drop_sound = 'sound/items/handling/tools/rcd_drop.ogg'
	pickup_sound = 'sound/items/handling/tools/rcd_pickup.ogg'
	sound_vary = TRUE

	/// main category of currently selected design[Structures, Airlocks, Airlock Access]
	var/root_category
	/// category of currently selected design
	var/design_category
	/// name of currently selected design
	var/design_title
	/// type of structure being built, used to decide what variables are used to build what structure
	var/mode
	/// temporary holder of mode, used to restore mode original value after rcd deconstruction act
	var/construction_mode
	/// The path of the structure the rcd is currently creating
	var/atom/movable/rcd_design_path

	/// Owner of this rcd. It can either be a construction console, player, or mech.
	var/atom/owner
	/// used by arcd, can this rcd work from a range
	var/ranged = FALSE
	/// delay multiplier for all construction types
	var/delay_mod = 1
	/// variable for R walls to deconstruct them
	var/canRturf = FALSE
	/// integrated airlock electronics for setting access to a newly built airlocks
	var/obj/item/electronics/airlock/airlock_electronics

	COOLDOWN_DECLARE(destructive_scan_cooldown)

	///number of active rcd effects in use e.g. when building multiple walls at once this value increases
	var/current_active_effects = 0

/obj/effect/rcd_hologram
	name = "hologram"
	mouse_opacity = MOUSE_OPACITY_TRANSPARENT

/obj/effect/rcd_hologram/Initialize(mapload)
	. = ..()
	QDEL_IN(src, RCD_HOLOGRAM_FADE_TIME)

/obj/item/construction/rcd/Initialize(mapload)
	. = ..()
	airlock_electronics = new(src)
	airlock_electronics.name = "Access Control"
	airlock_electronics.holder = src

	root_category =  GLOB.rcd_designs[1]
	design_category = GLOB.rcd_designs[root_category][1]
	var/list/design = GLOB.rcd_designs[root_category][design_category][1]

	rcd_design_path = design["[RCD_DESIGN_PATH]"]
	design_title = initial(rcd_design_path.name)
	mode = design["[RCD_DESIGN_MODE]"]
	construction_mode = mode

	GLOB.rcd_list += src
	AddElement(/datum/element/openspace_item_click_handler)

/obj/item/construction/rcd/Destroy()
	QDEL_NULL(airlock_electronics)
	GLOB.rcd_list -= src
	. = ..()

/obj/item/construction/rcd/ui_action_click(mob/user, actiontype)
	if (!COOLDOWN_FINISHED(src, destructive_scan_cooldown))
		to_chat(user, span_warning("[src] lets out a low buzz."))
		return

	COOLDOWN_START(src, destructive_scan_cooldown, RCD_DESTRUCTIVE_SCAN_COOLDOWN)
	rcd_scan(src)

/obj/item/construction/rcd/suicide_act(mob/living/user)
	var/turf/T = get_turf(user)

	if(!isopenturf(T)) // Oh fuck
		user.visible_message(span_suicide("[user] is beating [user.p_them()]self to death with [src]! It looks like [user.p_theyre()] trying to commit suicide!"))
		return BRUTELOSS

	mode = RCD_TURF
	user.visible_message(span_suicide("[user] sets the RCD to 'Wall' and points it down [user.p_their()] throat! It looks like [user.p_theyre()] trying to commit suicide!"))
	if(checkResource(16, user)) // It takes 16 resources to construct a wall
		var/success = T.rcd_act(user, src, list("[RCD_DESIGN_MODE]" = RCD_TURF, "[RCD_DESIGN_PATH]" = /turf/open/floor/plating/rcd))
		T = get_turf(user)
		// If the RCD placed a floor instead of a wall, having a wall without plating under it is cursed
		// There isn't an easy programmatical way to check if rcd_act will place a floor or a wall, so just repeat using it for free
		if(success && isopenturf(T))
			T.rcd_act(user, src, list("[RCD_DESIGN_MODE]" = RCD_TURF, "[RCD_DESIGN_PATH]" = /turf/open/floor/plating/rcd))
		useResource(16, user)
		activate()
		playsound(get_turf(user), SFX_TOOL_SWITCH, 20, TRUE)
		user.gib(DROP_ALL_REMAINS)
		return MANUAL_SUICIDE

	user.visible_message(span_suicide("[user] pulls the trigger... But there is not enough ammo!"))
	return SHAME

/**
 * checks if we can build the structure
 * Arguments
 *
 * * [atom][target]- the target we are trying to build on/deconstruct e.g. turf, wall etc
 * * rcd_results- list of params specifically the build type of our structure
 * * [mob][user]- the user
 */
/obj/item/construction/rcd/proc/can_place(atom/target, list/rcd_results, mob/user)
	var/rcd_mode = rcd_results["[RCD_DESIGN_MODE]"]
	var/atom/movable/rcd_structure = rcd_results["[RCD_DESIGN_PATH]"]
	/**
	 *For anything that does not go an a wall we have to make sure that turf is clear for us to put the structure on it
	 *If we are just trying to destroy something then this check is not necessary
	 *RCD_WALLFRAME is also returned as the rcd_mode when upgrading apc, airalarm, firealarm using simple circuits upgrade
	 */
	if(rcd_mode != RCD_WALLFRAME && rcd_mode != RCD_DECONSTRUCT)
		var/turf/target_turf = get_turf(target)
		//if we are trying to build a window we check for specific edge cases
		if(rcd_mode == RCD_WINDOWGRILLE)
			var/obj/structure/window/window_type = rcd_structure
			var/is_full_tile = initial(window_type.fulltile)

			var/list/structures_to_ignore
			if(istype(target, /obj/structure/grille))
				if(is_full_tile) //if we are trying to build full-tile windows we ignore the grille
					structures_to_ignore = list(/obj/structure/grille)
				else //when building directional windows we ignore the grill and other directional windows
					structures_to_ignore = list(/obj/structure/grille, /obj/structure/window)
			else //for directional windows we ignore other directional windows as they can be in different directions on the turf.
				structures_to_ignore = list(/obj/structure/window)

			//check if we can build our window on the grill
			if(target_turf.is_blocked_turf(exclude_mobs = !is_full_tile, source_atom = null, ignore_atoms = structures_to_ignore, type_list = TRUE))
				playsound(get_turf(user), SFX_TOOL_SWITCH, 20, TRUE)
				balloon_alert(user, "something is blocking the turf")
				return FALSE

		/**
		 * if we are trying to create plating on turf which is not a proper floor then don't check for objects on top of the turf just allow that turf to be converted into plating. e.g. create plating beneath a player or underneath a machine frame/any dense object
		 * if we are trying to finish a wall girder then let it finish then make sure no one/nothing is stuck in the girder
		 */
		else if(rcd_mode == RCD_TURF && rcd_structure == /turf/open/floor/plating/rcd  && (!istype(target_turf, /turf/open/floor) || istype(target, /obj/structure/girder)))
			//if a player builds a wallgirder on top of himself manually with iron sheets he can't finish the wall if he is still on the girder. Exclude the girder itself when checking for other dense objects on the turf
			if(istype(target, /obj/structure/girder) && target_turf.is_blocked_turf(exclude_mobs = FALSE, source_atom = null, ignore_atoms = list(target)))
				playsound(get_turf(user), SFX_TOOL_SWITCH, 20, TRUE)
				balloon_alert(user, "something is on the girder!")
				return FALSE

		//check if turf is blocked in for dense structures
		else
			//structures which are small enough to fit on turfs containing directional windows.
			var/static/list/small_structures = list(
				/obj/machinery/door,
				/obj/structure/frame/computer/rcd,
				/obj/structure/floodlight_frame/completed,
				/obj/structure/chair,
				/obj/structure/table,
				/obj/structure/rack,
				/obj/structure/bed,
				/obj/structure/frame/machine/secured,
				/obj/structure/reflector,
			)

			//edge cases for what we can/can't ignore
			var/ignore_mobs = FALSE
			var/list/ignored_types
			if(rcd_mode == RCD_WINDOWGRILLE || is_path_in_list(rcd_structure, small_structures))
				ignored_types = list(/obj/structure/window)
				//if we are trying to create grills/windoors we can go ahead and further ignore other windoors on the turf
				if(rcd_mode == RCD_WINDOWGRILLE || (rcd_mode == RCD_AIRLOCK && ispath(rcd_structure, /obj/machinery/door/window)))
					//only ignore mobs if we are trying to create windoors and not grills. We don't want to drop a grill on top of somebody
					ignore_mobs = rcd_mode == RCD_AIRLOCK
					ignored_types += /obj/machinery/door/window
				//if we are trying to create full airlock doors then we do the regular checks and make sure we have the full space for them. i.e. don't ignore anything dense on the turf
				else if(rcd_mode == RCD_AIRLOCK)
					ignored_types = list()

			//check if the structure can fit on this turf
			if(target_turf.is_blocked_turf(exclude_mobs = ignore_mobs, source_atom = null, ignore_atoms = ignored_types, type_list = TRUE))
				playsound(get_turf(user), SFX_TOOL_SWITCH, 20, TRUE)
				balloon_alert(user, "something is on the tile!")
				return FALSE

	return TRUE

/obj/item/construction/rcd/build_delay(mob/user, delay, atom/target)
	//unaffected by ui changes
	if(mode == RCD_DECONSTRUCT)
		if(delay <= 0)
			return TRUE

		return do_after(user, delay, target)

	//checks for ui changes
	return ..()

/**
 * actual proc to create the structure
 *
 * Arguments
 * * [atom][target]- the target we are trying to build on/deconstruct e.g. turf, wall etc
 * * [mob][user]- the user building this structure
 */
/obj/item/construction/rcd/proc/rcd_create(atom/target, mob/user)
	var/list/rcd_results = target.rcd_vals(user, src) // does this atom allow for rcd actions?
	if(!rcd_results) // nope
		return NONE

	//straight up can't touch this
	if(mode == RCD_DECONSTRUCT && (target.resistance_flags & INDESTRUCTIBLE))
		balloon_alert(user, "too durable!")
		return ITEM_INTERACT_BLOCKING

	rcd_results["[RCD_DESIGN_MODE]"] = mode
	rcd_results["[RCD_DESIGN_PATH]"] = rcd_design_path

	var/delay = rcd_results["delay"] * delay_mod
	if (
		!(upgrade & RCD_UPGRADE_NO_FREQUENT_USE_COOLDOWN) \
			&& !rcd_results[RCD_RESULT_BYPASS_FREQUENT_USE_COOLDOWN] \
			&& current_active_effects > 0
	)
		delay *= FREQUENT_USE_DEBUFF_MULTIPLIER

	current_active_effects += 1

	var/target_name = target.name //Store this information before it gets mutated by the rcd.
	var/target_path = target.type
	var/atom/design_path = rcd_results["[RCD_DESIGN_PATH]"]
	var/location = AREACOORD(target)
	if(_rcd_create_effect(target, user, delay, rcd_results))
		log_tool("[key_name(user)] used [src] to [rcd_results["[RCD_DESIGN_MODE]"] != RCD_DECONSTRUCT ? "construct [initial(design_path.name)]([design_path])" : "deconstruct [target_name]([target_path])"] at [location]")

	current_active_effects -= 1
	return ITEM_INTERACT_SUCCESS

/**
 * Internal proc which creates the rcd effects & creates the structure
 *
 * Arguments
 * * [atom][target]- the target we are trying to build on/deconstruct e.g. turf, wall etc
 * * [mob][user]- the user trying to build the structure
 * * delay- the delay with the disk upgrades applied
 * * rcd_results- list of params which contains the cost & build mode to create the structure
 */
/obj/item/construction/rcd/proc/_rcd_create_effect(atom/target, mob/user, delay, list/rcd_results)
	PRIVATE_PROC(TRUE)

	var/obj/effect/constructing_effect/rcd_effect = new(get_turf(target), delay, rcd_results["[RCD_DESIGN_MODE]"], upgrade)

	//resource & structure placement sanity checks before & after delay along with beam effects
	if(!checkResource(rcd_results["cost"], user) || !can_place(target, rcd_results, user))
		qdel(rcd_effect)
		return FALSE
	var/beam
	if(ranged)
		var/atom/beam_source = owner ? owner : user
		beam = beam_source.Beam(target, icon_state = "rped_upgrade", time = delay)
	if(!build_delay(user, delay, target = target)) // no need for do_after with no delay
		qdel(rcd_effect)
		if(!isnull(beam))
			qdel(beam)
		return FALSE
	if (QDELETED(rcd_effect))
		return FALSE
	if(!checkResource(rcd_results["cost"], user) || !can_place(target, rcd_results, user))
		qdel(rcd_effect)
		return FALSE

	if(!useResource(rcd_results["cost"], user))
		qdel(rcd_effect)
		return FALSE
	activate()
	if(!target.rcd_act(user, src, rcd_results))
		qdel(rcd_effect)
		return FALSE
	playsound(loc, 'sound/machines/click.ogg', 50, TRUE)
	rcd_effect.end_animation()
	return TRUE

/obj/item/construction/rcd/ui_assets(mob/user)
	return list(
		get_asset_datum(/datum/asset/spritesheet_batched/rcd),
	)

/obj/item/construction/rcd/ui_host(mob/user)
	return owner || ..()

/obj/item/construction/rcd/ui_interact(mob/user, datum/tgui/ui)
	ui = SStgui.try_update_ui(user, src, ui)
	if(!ui)
		ui = new(user, src, "RapidConstructionDevice", name)
		ui.open()

/obj/item/construction/rcd/ui_static_data(mob/user)
	var/list/data = ..()

	var/list/electronics_data = airlock_electronics.ui_static_data(user)
	for(var/key in electronics_data)
		data[key] = electronics_data[key]

	data["root_categories"] = list()
	for(var/category in GLOB.rcd_designs)
		data["root_categories"] += category
	data["selected_root"] = root_category

	data["categories"] = list()
	for(var/sub_category as anything in GLOB.rcd_designs[root_category])
		var/list/target_category =  GLOB.rcd_designs[root_category][sub_category]
		if(!length(target_category))
			continue

		//skip category if upgrades were not installed for these
		if(sub_category == "Machines" && !(upgrade & RCD_UPGRADE_FRAMES))
			continue
		if(sub_category == "Furniture" && !(upgrade & RCD_UPGRADE_FURNISHING))
			continue

		var/list/designs = list() //initialize all designs under this category
		for(var/list/design as anything in target_category)
			var/atom/movable/design_path = design[RCD_DESIGN_PATH]

			var/design_name = initial(design_path.name)

			designs += list(list("title" = design_name, "icon" = sanitize_css_class_name(design_name)))
		data["categories"] += list(list("cat_name" = sub_category, "designs" = designs))

	return data

/obj/item/construction/rcd/ui_data(mob/user)
	var/list/data = ..()

	//main categories
	data["selected_category"] = design_category
	data["selected_design"] = design_title

	//merge airlock_electronics ui data with this
	var/list/airlock_data = airlock_electronics.ui_data(user)
	for(var/key in airlock_data)
		data[key] = airlock_data[key]

	return data

/obj/item/construction/rcd/handle_ui_act(action, params, datum/tgui/ui, datum/ui_state/state)
	playsound(src, SFX_TOOL_SWITCH, 20, TRUE)

	switch(action)
		if("root_category")
			var/new_root = params["root_category"]
			if(GLOB.rcd_designs[new_root] != null) //is a valid category
				root_category = new_root
				update_static_data_for_all_viewers()

		if("design")
			//read and validate params from UI
			var/category_name = params["category"]
			var/index = params["index"]
			var/list/root = GLOB.rcd_designs[root_category]
			if(root == null) //not a valid root
				return TRUE
			var/list/category = root[category_name]
			if(category == null) //not a valid category
				return TRUE

			/**
			 * The advantage of organizing designs into categories is that
			 * You can ignore an complete category if the design disk upgrade for that category isn't installed.
			 */
			//You can't select designs from the Machines category if you don't have the frames upgrade installed.
			if(category == "Machines" && !(upgrade & RCD_UPGRADE_FRAMES))
				return TRUE
			//You can't select designs from the Furniture category if you don't have the furnishing upgrade installed.
			if(category == "Furniture" && !(upgrade & RCD_UPGRADE_FURNISHING))
				return TRUE

			//use UI params to set variables
			var/list/design = category[index]
			if(design == null) //not a valid design
				return TRUE
			design_category = category_name
			mode = design["[RCD_DESIGN_MODE]"]
			construction_mode = mode
			rcd_design_path = design["[RCD_DESIGN_PATH]"]
			design_title = initial(rcd_design_path.name)
			blueprint_changed = TRUE

		else
			airlock_electronics.do_action(action, params)

	return TRUE

/obj/item/construction/rcd/attack_self(mob/user)
	. = ..()
	ui_interact(user)

/obj/item/construction/rcd/interact_with_atom(atom/interacting_with, mob/living/user, list/modifiers)
	. = ..()
	if(. & ITEM_INTERACT_ANY_BLOCKER)
		return .

	mode = construction_mode
	return rcd_create(interacting_with, user)

/obj/item/construction/rcd/ranged_interact_with_atom(atom/interacting_with, mob/living/user, list/modifiers)
	if(!ranged || !range_check(interacting_with, user))
		return ITEM_INTERACT_BLOCKING

	mode = construction_mode
	return rcd_create(interacting_with, user)

/obj/item/construction/rcd/interact_with_atom_secondary(atom/interacting_with, mob/living/user, list/modifiers)
	mode = RCD_DECONSTRUCT
	return rcd_create(interacting_with, user)

/obj/item/construction/rcd/ranged_interact_with_atom_secondary(atom/interacting_with, mob/living/user, list/modifiers)
	if(!ranged || !range_check(interacting_with, user))
		return ITEM_INTERACT_BLOCKING

	mode = RCD_DECONSTRUCT
	return rcd_create(interacting_with, user)

/obj/item/construction/rcd/handle_openspace_click(turf/target, mob/user, list/modifiers)
	interact_with_atom(target, user, modifiers)

/obj/item/construction/rcd/proc/detonate_pulse()
	audible_message(span_danger("<b>[src] begins to vibrate and buzz loudly!</b>"), \
	span_danger("<b>[src] begins vibrating violently!</b>"))
	// 5 seconds to get rid of it
	addtimer(CALLBACK(src, PROC_REF(detonate_pulse_explode)), 5 SECONDS)

/obj/item/construction/rcd/proc/detonate_pulse_explode()
	explosion(src, light_impact_range = 3, flame_range = 1, flash_range = 1)
	qdel(src)

/obj/item/construction/rcd/borg
	desc = "A device used to rapidly build walls and floors."
	banned_upgrades = RCD_UPGRADE_SILO_LINK
	/// enery usage
	var/energyfactor = 0.072 * STANDARD_CELL_CHARGE

/obj/item/construction/rcd/borg/get_matter(mob/user)
	if(!iscyborg(user))
		return 0
	var/mob/living/silicon/robot/borgy = user
	if(!borgy.cell)
		return 0
	max_matter = borgy.cell.maxcharge
	return borgy.cell.charge

/obj/item/construction/rcd/borg/useResource(amount, mob/user)
	if(!iscyborg(user))
		return 0
	var/mob/living/silicon/robot/borgy = user
	if(!borgy.cell)
		if(user)
			balloon_alert(user, "no cell found!")
		return 0
	. = borgy.cell.use(amount * energyfactor) //borgs get 1.3x the use of their RCDs
	if(!. && user)
		balloon_alert(user, "insufficient charge!")
	return .

/obj/item/construction/rcd/borg/checkResource(amount, mob/user)
	if(!iscyborg(user))
		return 0
	var/mob/living/silicon/robot/borgy = user
	if(!borgy.cell)
		if(user)
			balloon_alert(user, "no cell found!")
		return 0
	. = borgy.cell.charge >= (amount * energyfactor)
	if(!. && user)
		balloon_alert(user, "insufficient charge!")
	return .

/obj/item/construction/rcd/borg/syndicate
	name = "syndicate RCD"
	desc = "A reverse-engineered RCD with black market upgrades that allow this device to deconstruct reinforced walls. Property of Donk Co."
	icon_state = "ircd"
	inhand_icon_state = "ircd"
	energyfactor = 0.066 * STANDARD_CELL_CHARGE
	canRturf = TRUE

/obj/item/construction/rcd/loaded
	matter = 160

/obj/item/construction/rcd/loaded/upgraded
	upgrade = RCD_ALL_UPGRADES

/obj/item/construction/rcd/ce
	name = "professional RCD"
	desc = "A higher-end model of the rapid construction device, prefitted with improved cooling and disruption prevention. Provided to the chief engineer."
	upgrade = RCD_UPGRADE_ANTI_INTERRUPT | RCD_UPGRADE_NO_FREQUENT_USE_COOLDOWN
	matter = 160
	color = list(
		0.3, 0.3, 0.7, 0.0,
		1.0, 1.0, 0.2, 0.0,
		-0.2, 0.0, 1.0, 0.0,
		0.0, 0.0, 0.0, 1.0,
		0.0, 0.0, 0.0, 0.0,
	)

/obj/item/construction/rcd/combat
	name = "industrial RCD"
	icon_state = "ircd"
	inhand_icon_state = "ircd"
	max_matter = 500
	matter = 500
	canRturf = TRUE
	upgrade = RCD_ALL_UPGRADES

/obj/item/construction/rcd/combat/admin
	name = "admin RCD"
	max_matter = INFINITY
	matter = INFINITY
	upgrade = RCD_ALL_UPGRADES & ~RCD_UPGRADE_SILO_LINK
	delay_mod = 0.1

// Ranged RCD
/obj/item/construction/rcd/arcd
	name = "advanced rapid-construction-device (ARCD)"
	desc = "A prototype RCD with ranged capability and infinite capacity."
	max_matter = INFINITY
	matter = INFINITY
	canRturf = TRUE
	delay_mod = 0.6
	ranged = TRUE
	icon_state = "arcd"
	inhand_icon_state = "oldrcd"
	has_ammobar = FALSE
	upgrade = RCD_ALL_UPGRADES & ~RCD_UPGRADE_SILO_LINK

///How much charge is used up for each matter unit.
#define MASS_TO_ENERGY (0.016 * STANDARD_CELL_CHARGE)

/obj/item/construction/rcd/exosuit
	name = "mounted RCD"
	desc = "An exosuit-mounted Rapid Construction Device."
	max_matter = INFINITY // mass-energy equivalence go brrrrrr
	canRturf = TRUE
	ranged = TRUE
	has_ammobar = FALSE
	resistance_flags = FIRE_PROOF | INDESTRUCTIBLE // should NOT be destroyed unless the equipment is destroyed
	item_flags = NO_MAT_REDEMPTION | NOBLUDGEON | DROPDEL // already qdeleted in the equipment's Destroy() but you can never be too sure
	delay_mod = 0.5

/obj/item/construction/rcd/exosuit/ui_status(mob/user, datum/ui_state/state)
	if(ismecha(owner))
		return owner.ui_status(user)
	return UI_CLOSE

/obj/item/construction/rcd/exosuit/build_delay(mob/user, delay, atom/target)
	if(delay <= 0)
		return TRUE

	var/obj/item/mecha_parts/mecha_equipment/rcd/module = loc

	//deconstruction can't be cancelled by ui changes
	if(mode != RCD_DECONSTRUCT)
		blueprint_changed = FALSE

	return module.do_after_mecha(target, user, delay)

/obj/item/construction/rcd/exosuit/get_matter(mob/user)
	if(silo_link)
		return ..()
	if(!ismecha(owner))
		return 0
	var/obj/vehicle/sealed/mecha/gundam = owner
	return round(gundam.get_charge() / MASS_TO_ENERGY)

/obj/item/construction/rcd/exosuit/useResource(amount, mob/user)
	if(silo_link)
		return ..()
	if(!ismecha(owner))
		return 0
	var/obj/vehicle/sealed/mecha/gundam = owner
	if(!gundam.use_energy(amount * MASS_TO_ENERGY))
		gundam.balloon_alert(user, "insufficient charge!")
		return FALSE
	return TRUE

/obj/item/construction/rcd/exosuit/checkResource(amount, mob/user)
	if(silo_link)
		return ..()
	if(!ismecha(owner))
		return 0
	var/obj/vehicle/sealed/mecha/gundam = owner
	if(!gundam.has_charge(amount * MASS_TO_ENERGY))
		gundam.balloon_alert(user, "insufficient charge!")
		return FALSE
	return TRUE

#undef MASS_TO_ENERGY

#undef FREQUENT_USE_DEBUFF_MULTIPLIER

/obj/item/rcd_ammo
	name = "RCD matter cartridge"
	desc = "Highly compressed matter for the RCD."
	icon = 'icons/obj/tools.dmi'
	icon_state = "rcdammo"
	w_class = WEIGHT_CLASS_TINY
	lefthand_file = 'icons/mob/inhands/equipment/tools_lefthand.dmi'
	righthand_file = 'icons/mob/inhands/equipment/tools_righthand.dmi'
	custom_materials = list(/datum/material/iron=SHEET_MATERIAL_AMOUNT *6, /datum/material/glass=SHEET_MATERIAL_AMOUNT*4)
	var/ammoamt = 40

/obj/item/rcd_ammo/large
	custom_materials = list(/datum/material/iron=SHEET_MATERIAL_AMOUNT*24, /datum/material/glass=SHEET_MATERIAL_AMOUNT*16)
	ammoamt = 160
