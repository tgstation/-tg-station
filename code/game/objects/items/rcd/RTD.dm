//RAPID TILING DEVICE

/// time taken to create tile
#define CONSTRUCTION_TIME(cost)((cost * 0.15) SECONDS)
/// time taken to destroy a tile
#define DECONSTRUCTION_TIME(cost)((cost * 0.25) SECONDS)

/**
 * An tool used to create, destroy, and copy & clear decals of floor tiles
 * Great for janitor but can be made only in engineering
 * Supports silo link upgrade and refill with glass, plasteel & iron
 */
/obj/item/construction/rtd
	name = "rapid-tiling-device (RTD)"
	desc = "Used for fast placement & destruction of floor tiles."
	icon = 'icons/obj/tools.dmi'
	icon_state = "rtd"
	worn_icon_state = "RCD"
	lefthand_file = 'icons/mob/inhands/equipment/tools_lefthand.dmi'
	righthand_file = 'icons/mob/inhands/equipment/tools_righthand.dmi'
	custom_premium_price = PAYCHECK_COMMAND * 3
	max_matter = 350
	slot_flags = ITEM_SLOT_BELT
	item_flags = NO_MAT_REDEMPTION | NOBLUDGEON
	has_ammobar = TRUE
	banned_upgrades = RCD_ALL_UPGRADES & ~RCD_UPGRADE_SILO_LINK
	drop_sound = 'sound/items/handling/tools/rcd_drop.ogg'
	pickup_sound = 'sound/items/handling/tools/rcd_pickup.ogg'
	sound_vary = TRUE

	/// main category for tile design
	var/root_category = "Conventional"
	/// sub category for tile design
	var/design_category = "Standard"
	/// design selected by player
	var/datum/tile_info/selected_design
	/// temp var to store an single design from GLOB.floor_design while iterating through this list
	var/datum/tile_info/tile_design
	/// overlays on a tile
	var/list/design_overlays = list()
	var/ranged = TRUE
/// stores the name, type, icon & cost for each tile type
/datum/tile_info
	/// name of this tile design for ui
	var/name
	/// path to create this tile type
	var/obj/item/stack/tile/tile_type
	/// icon for this tile to display for ui
	var/icon_state
	/// rcd units to consume for this tile creation
	var/cost

	///directions this tile can be placed on the turf
	var/list/tile_directions
	/// user friendly names of the tile_directions to be sent to ui
	var/list/ui_directional_data
	/// current direction this tile should be rotated in before being placed on the plating
	var/selected_direction

/// decompress a single tile design list element from GLOB.floor_designs into its individual variables
/datum/tile_info/proc/set_info(list/design)
	name = design["name"]
	tile_type = design["type"]
	icon_state = initial(tile_type.icon_state)
	cost = design["tile_cost"]

	tile_directions = design["tile_rotate_dirs"]
	if(!tile_directions)
		selected_direction = null
		ui_directional_data = null
		return

	ui_directional_data = list()
	for(var/tile_direction in tile_directions)
		ui_directional_data += dir2text(tile_direction)
	selected_direction = tile_directions[1]

/// fill all information to be sent to the UI
/datum/tile_info/proc/fill_ui_data(list/data)
	data["selected_recipe"] = name
	data["selected_icon"] = get_icon_state()

	if(!tile_directions)
		data["selected_direction"] = null
		return

	data["tile_dirs"] = ui_directional_data
	data["selected_direction"] = dir2text(selected_direction)

/// change the direction the tile is laid on the turf
/datum/tile_info/proc/set_direction(direction)
	if(tile_directions == null || !(direction in tile_directions))
		return
	selected_direction = direction

/**
 * retrieve the icon for this tile design based on its direction
 * for complex directions like NORTHSOUTH etc we create an seperated blended icon in the asset file for example floor-northsouth
 * so we check which icons we want to retrieve based on its direction
 * for basic directions its rotated with CSS so there is no need for icon
 */
/datum/tile_info/proc/get_icon_state()
	var/prefix = ""
	if(selected_direction)
		prefix = (selected_direction in GLOB.tile_dont_rotate) ? "" : "-[dir2text(selected_direction)]"
	return icon_state + prefix

///convinience proc to quickly convert the tile design into an physical tile to lay on the plating
/datum/tile_info/proc/new_tile(loc)
	var/obj/item/stack/tile/final_tile = new tile_type(loc, 1)
	final_tile.turf_dir = selected_direction
	return final_tile

/**
 * Stores the decal & overlays on the floor to preserve texture of the design
 * in short it's just an wrapper for mutable appearance where we retrieve the nessassary information
 * to recreate an mutable appearance
 */
/datum/overlay_info
	/// icon var of the mutable appearance
	var/icon/icon
	/// icon_state var of the mutable appearance
	var/icon_state
	/// direction var of the mutable appearance
	var/direction
	/// alpha var of the mutable appearance
	var/alpha
	/// color var of the mutable appearance
	var/color

//decompressing nessasary information required to re-create an mutable appearance
/datum/overlay_info/New(mutable_appearance/appearance)
	icon = appearance.icon
	icon_state = appearance.icon_state
	alpha = appearance.alpha
	direction = appearance.dir
	color = appearance.color

/// re create the appearance
/datum/overlay_info/proc/add_decal(turf/the_turf)
	the_turf.AddElement(/datum/element/decal, icon, icon_state, direction, null, null, alpha, color, null, FALSE, null)

/obj/item/construction/rtd/Initialize(mapload)
	. = ..()
	selected_design = new
	tile_design = new
	selected_design.set_info(GLOB.floor_designs[root_category][design_category][1])

/obj/item/construction/rtd/Destroy()
	QDEL_NULL(selected_design)
	QDEL_NULL(tile_design)
	QDEL_LIST(design_overlays)
	return ..()

/obj/item/construction/rtd/ui_interact(mob/user, datum/tgui/ui)
	ui = SStgui.try_update_ui(user, src, ui)
	if(!ui)
		ui = new(user, src, "RapidTilingDevice", name)
		ui.open()


/obj/item/construction/rtd/ui_assets(mob/user)
	return list(
		get_asset_datum(/datum/asset/spritesheet_batched/rtd),
	)

/obj/item/construction/rtd/attack_self(mob/user)
	. = ..()
	ui_interact(user)

/obj/item/construction/rtd/ui_static_data(mob/user)
	var/list/data = ..()

	data["root_categories"] = list()
	for(var/category in GLOB.floor_designs)
		data["root_categories"] += category
	data["selected_root"] = root_category

	data["categories"] = list()
	for(var/sub_category as anything in GLOB.floor_designs[root_category])
		var/list/target_category =  GLOB.floor_designs[root_category][sub_category]

		var/list/designs = list() //initialize all designs under this category
		for(var/list/design as anything in target_category)
			tile_design.set_info(design)
			designs += list(list("name" = tile_design.name, "icon" = tile_design.get_icon_state()))

		data["categories"] += list(list("category_name" = sub_category, "recipes" = designs))

	return data

/obj/item/construction/rtd/ui_data(mob/user)
	var/list/data = ..()

	data["selected_category"] = design_category
	selected_design.fill_ui_data(data)

	return data

/obj/item/construction/rtd/handle_ui_act(action, params, datum/tgui/ui, datum/ui_state/state)
	playsound(src, SFX_TOOL_SWITCH, 20, TRUE)

	var/floor_designs = GLOB.floor_designs
	switch(action)
		if("root_category")
			var/new_root = params["root_category"]
			if(floor_designs[new_root] != null) //is a valid category
				root_category = new_root
				update_static_data_for_all_viewers()

		if("set_dir")
			var/direction = text2dir(params["dir"])
			if(!direction)
				return FALSE
			selected_design.set_direction(direction)

		if("recipe")
			var/list/main_root = floor_designs[root_category]
			if(main_root == null)
				return FALSE
			var/list/sub_category = main_root[params["category_name"]]
			if(sub_category == null)
				return FALSE
			var/list/target_design = sub_category[text2num(params["id"])]
			if(target_design == null)
				return FALSE

			QDEL_LIST(design_overlays)
			design_category = params["category_name"]
			selected_design.set_info(target_design)
			blueprint_changed = TRUE

	return TRUE

/obj/item/construction/rtd/ranged_interact_with_atom(atom/interacting_with, mob/living/user, list/modifiers)
	if(!ranged || !range_check(interacting_with, user))
		return NONE
	return try_tiling(interacting_with, user)

/obj/item/construction/rtd/interact_with_atom(atom/interacting_with, mob/living/user, list/modifiers)
	. = ..()
	if(. & ITEM_INTERACT_ANY_BLOCKER)
		return .

	return try_tiling(interacting_with, user)

/**
 * put plating on the turf
 * Arguments
 *
 * * turf/open/floor/floor - the turf we are trying to put plating on
 * * mob/living/user - the mob trying to do the plating
 */
/obj/item/construction/rtd/proc/try_tiling(atom/interacting_with, mob/living/user)
	PRIVATE_PROC(TRUE)

	if(HAS_TRAIT(interacting_with, TRAIT_COMBAT_MODE_SKIP_INTERACTION))
		return NONE

	var/turf/open/floor/floor = interacting_with
	if(!istype(floor))
		return NONE

	var/floor_designs = GLOB.floor_designs
	if(!istype(floor, /turf/open/floor/plating)) //we infer what floor type it is if its not the usual plating
		if(ranged)
			user.Beam(floor, icon_state = "light_beam", time = 5)
		for(var/main_root in floor_designs)
			for(var/sub_category in floor_designs[main_root])
				for(var/list/design_info in floor_designs[main_root][sub_category])
					var/obj/item/stack/tile/tile_type = design_info["type"]
					if(initial(tile_type.turf_type) != floor.type)
						continue

					//infer available overlays on the floor to recreate them to the best extent
					QDEL_LIST(design_overlays)
					var/floor_overlays = floor.managed_overlays
					if(isnull(floor_overlays))
						floor_overlays = list()
					else if(!islist(floor_overlays))
						floor_overlays = list(floor.managed_overlays)
					for(var/mutable_appearance/appearance as anything in floor_overlays)
						design_overlays += new /datum/overlay_info(appearance)

					//store all information about this tile
					root_category = main_root
					design_category = sub_category
					selected_design.set_info(design_info)
					selected_design.set_direction(floor.dir)
					balloon_alert(user, "tile changed to [selected_design.name]")

					return ITEM_INTERACT_SUCCESS

		//can't infer floor type!
		balloon_alert(user, "design not supported!")
		return ITEM_INTERACT_BLOCKING

	//resource sanity check before & after delay along with special effects
	if(!checkResource(selected_design.cost, user))
		return ITEM_INTERACT_BLOCKING
	var/delay = CONSTRUCTION_TIME(selected_design.cost)
	var/obj/effect/constructing_effect/rcd_effect = new(floor, delay, RCD_TURF)
	var/beam
	if(ranged)
		beam = user.Beam(floor, icon_state = "light_beam", time = delay)
		playsound(loc, 'sound/effects/light_flicker.ogg', 50, FALSE)
	else
		playsound(loc, 'sound/machines/click.ogg', 50, TRUE)
	if(!build_delay(user, delay, target = floor))
		qdel(beam)
		qdel(rcd_effect)
		return ITEM_INTERACT_BLOCKING
	if(!checkResource(selected_design.cost, user))
		qdel(rcd_effect)
		return ITEM_INTERACT_BLOCKING

	//do the tilling
	if(!useResource(selected_design.cost, user))
		qdel(rcd_effect)
		return ITEM_INTERACT_BLOCKING
	activate()
	//step 1 create tile
	var/obj/item/stack/tile/final_tile = selected_design.new_tile(user.drop_location())
	if(QDELETED(final_tile)) //if you were standing on a stack of tiles this newly spawned tile could get merged with it cause its spawned on your location
		qdel(rcd_effect)
		balloon_alert(user, "tile got merged with the stack beneath you!")
		return ITEM_INTERACT_BLOCKING
	//step 2 lay tile
	var/turf/open/new_turf = final_tile.place_tile(floor, user)
	if(new_turf) //apply infered overlays
		for(var/datum/overlay_info/info in design_overlays)
			info.add_decal(new_turf)
	rcd_effect.end_animation()

	return ITEM_INTERACT_SUCCESS

/obj/item/construction/rtd/ranged_interact_with_atom_secondary(atom/interacting_with, mob/living/user, list/modifiers)
	if(!ranged || !range_check(interacting_with, user))
		return NONE
	return interact_with_atom_secondary(interacting_with, user, modifiers)

/obj/item/construction/rtd/interact_with_atom_secondary(atom/interacting_with, mob/living/user, list/modifiers)
	var/turf/open/floor/floor = interacting_with
	if(!istype(floor))
		return NONE

	if(istype(floor, /turf/open/floor/plating)) //cant deconstruct normal plating thats the RCD's job
		balloon_alert(user, "nothing to deconstruct!")
		return ITEM_INTERACT_BLOCKING

	var/floor_designs = GLOB.floor_designs

	//we only deconstruct floors which are supported by the RTD
	var/cost = 0
	for(var/main_root in floor_designs)
		if(cost)
			break
		for(var/sub_category in floor_designs[main_root])
			if(cost)
				break
			for(var/list/design_info in floor_designs[main_root][sub_category])
				var/obj/item/stack/tile/tile_type = design_info["type"]
				if(initial(tile_type.turf_type) == floor.type)
					cost = design_info["tile_cost"]
					break
	if(!cost)
		balloon_alert(user, "can't deconstruct this type!")
		return ITEM_INTERACT_BLOCKING

	//resource sanity check before & after delay along with beam effects
	if(!checkResource(cost * 0.7, user)) //no ballon alert for checkResource as it already spans an alert to chat
		return ITEM_INTERACT_BLOCKING
	var/delay = DECONSTRUCTION_TIME(cost)
	var/obj/effect/constructing_effect/rcd_effect = new(floor, delay, RCD_DECONSTRUCT)
	var/beam
	if(ranged)
		beam = user.Beam(floor, icon_state = "light_beam", time = delay)
		playsound(loc, 'sound/effects/light_flicker.ogg', 50, FALSE)
	else
		playsound(loc, 'sound/machines/click.ogg', 50, TRUE)
	if(!do_after(user, delay, target = floor))
		qdel(beam)
		qdel(rcd_effect)
		return ITEM_INTERACT_BLOCKING
	if(!checkResource(cost * 0.7, user))
		qdel(rcd_effect)
		return ITEM_INTERACT_BLOCKING

	//begin deconstruction
	if(!useResource(cost * 0.7, user))
		qdel(rcd_effect)
		return ITEM_INTERACT_BLOCKING
	activate()
	//find & collect all decals
	var/list/all_decals = list()
	for(var/obj/effect/decal in floor.contents)
		all_decals += decal
	//delete all decals
	for(var/obj/effect/decal in all_decals)
		floor.contents -= decal
		qdel(decal)
	if(floor.baseturf_at_depth(1) == /turf/baseturf_bottom) //for turfs whose base is open space we put regular plating in its place else everyone dies
		floor.ChangeTurf(/turf/open/floor/plating, flags = CHANGETURF_INHERIT_AIR)
	else //for every other turf we scrape away exposing base turf underneath
		floor.ScrapeAway(flags = CHANGETURF_INHERIT_AIR)
	rcd_effect.end_animation()

	return ITEM_INTERACT_SUCCESS

///Converting tile cost into joules
#define RTD_BORG_ENERGY_FACTOR (0.03 * STANDARD_CELL_CHARGE)

/obj/item/construction/rtd/borg
	ranged = FALSE

///Cannot deconstruct floors
/obj/item/construction/rtd/borg/interact_with_atom_secondary(atom/interacting_with, mob/living/user, list/modifiers)
	return NONE

/obj/item/construction/rtd/borg/get_matter(mob/user)
	if(!iscyborg(user))
		return 0
	var/mob/living/silicon/robot/borgy = user
	if(!borgy.cell)
		return 0
	max_matter = borgy.cell.maxcharge
	return borgy.cell.charge

/obj/item/construction/rtd/borg/useResource(amount, mob/user)
	if(!iscyborg(user))
		return 0
	var/mob/living/silicon/robot/borgy = user
	if(!borgy.cell)
		balloon_alert(user, "no cell found!")
		return 0
	. = borgy.cell.use(amount * RTD_BORG_ENERGY_FACTOR)
	if(!.)
		balloon_alert(user, "insufficient charge!")

/obj/item/construction/rtd/borg/checkResource(amount, mob/user)
	if(!iscyborg(user))
		return 0
	var/mob/living/silicon/robot/borgy = user
	if(!borgy.cell)
		balloon_alert(user, "no cell found!")
		return 0
	. = borgy.cell.charge >= (amount * RTD_BORG_ENERGY_FACTOR)
	if(!.)
		balloon_alert(user, "insufficient charge!")

#undef RTD_BORG_ENERGY_FACTOR

/obj/item/construction/rtd/loaded
	matter = 350

/obj/item/construction/rtd/admin
	name = "admin RTD"
	max_matter = INFINITY
	matter = INFINITY

#undef CONSTRUCTION_TIME
#undef DECONSTRUCTION_TIME
