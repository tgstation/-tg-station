///The plumbing RCD. All the blueprints are located in _globalvars > lists > construction.dm
/obj/item/construction/plumbing
	name = "Plumbing Constructor"
	desc = "An expertly modified RCD outfitted to construct plumbing machinery."
	icon_state = "plumberer2"
	inhand_icon_state = "plumberer"
	lefthand_file = 'icons/mob/inhands/equipment/tools_lefthand.dmi'
	righthand_file = 'icons/mob/inhands/equipment/tools_righthand.dmi'
	worn_icon_state = "plumbing"
	icon = 'icons/obj/tools.dmi'
	slot_flags = ITEM_SLOT_BELT
	banned_upgrades = RCD_ALL_UPGRADES & ~RCD_UPGRADE_SILO_LINK
	matter = 200
	max_matter = 200
	drop_sound = 'sound/items/handling/tools/rcd_drop.ogg'
	pickup_sound = 'sound/items/handling/tools/rcd_pickup.ogg'
	sound_vary = TRUE

	///category of design selected
	var/selected_category
	///type of the plumbing machine
	var/obj/machinery/blueprint = null
	///This list that holds all the plumbing design types the plumberer can construct. Its purpose is to make it easy to make new plumberer subtypes with a different selection of machines.
	var/list/plumbing_design_types = null
	///Current selected layer
	var/current_layer = "Default Layer"
	///Current selected color, for ducts
	var/current_color = "omni"
	///maps layer name to layer number value. didnt make this global cause only this class needs it
	var/static/list/name_to_number = list(
		"First Layer" = 1,
		"Second Layer" = 2,
		"Default Layer" = 3,
		"Fourth Layer" = 4,
		"Fifth Layer" = 5,
	)
	///Design types for general plumbing constructor
	var/static/list/general_design_types = list(
		//category 1 Synthesizers i.e devices which creates , reacts & destroys chemicals
		"Synthesizers" = list(
			/obj/machinery/plumbing/synthesizer = 15,
			/obj/machinery/plumbing/reaction_chamber/chem = 15,
			/obj/machinery/plumbing/grinder_chemical = 30,
			/obj/machinery/plumbing/fermenter = 30,
			/obj/machinery/plumbing/liquid_pump = 35, //extracting chemicals from ground is one way of creation
			/obj/machinery/plumbing/disposer = 10,
			/obj/machinery/plumbing/buffer = 10, //creates chemicals as it waits for other buffers containing other chemicals and when mixed creates new chemicals
		),

		//category 2 distributors i.e devices which inject , move around , remove chemicals from the network
		"Distributors" = list(
			/obj/machinery/duct = 1,
			/obj/machinery/plumbing/layer_manifold = 5,
			/obj/machinery/plumbing/input = 5,
			/obj/machinery/plumbing/filter = 5,
			/obj/machinery/plumbing/splitter = 5,
			/obj/machinery/plumbing/sender = 20,
			/obj/machinery/plumbing/output = 5,
		),

		//category 3 Storage i.e devices which stores & makes the processed chemicals ready for consumption
		"Storage" = list(
			/obj/machinery/plumbing/tank = 20,
			/obj/machinery/plumbing/acclimator = 10,
			/obj/machinery/plumbing/bottler = 50,
			/obj/machinery/plumbing/pill_press = 20,
			/obj/machinery/iv_drip/plumbing = 20
		),
	)

/obj/item/construction/plumbing/Initialize(mapload)
	. = ..()

	if(isnull(plumbing_design_types))
		plumbing_design_types = general_design_types

	selected_category = plumbing_design_types[1]
	/**
	 * plumbing_design_types["Synthesizers"] = <list of designs under synthesizers>
	 * <list of designs under synthesizers>[1] = <first design in this list>
	 */
	blueprint = plumbing_design_types[selected_category][1]

/obj/item/construction/plumbing/equipped(mob/user, slot, initial)
	. = ..()
	if(slot & ITEM_SLOT_HANDS)
		RegisterSignal(user, COMSIG_MOUSE_SCROLL_ON, PROC_REF(mouse_wheeled))
	else
		UnregisterSignal(user, COMSIG_MOUSE_SCROLL_ON)

/obj/item/construction/plumbing/dropped(mob/user, silent)
	UnregisterSignal(user, COMSIG_MOUSE_SCROLL_ON)
	return ..()

/obj/item/construction/plumbing/cyborg_unequip(mob/user)
	UnregisterSignal(user, COMSIG_MOUSE_SCROLL_ON)
	return ..()

/obj/item/construction/plumbing/attack_self(mob/user)
	. = ..()
	ui_interact(user)

/obj/item/construction/plumbing/examine(mob/user)
	. = ..()
	. += "You can scroll your mouse wheel to change the piping layer."
	. += "You can right click a fluid duct to set the Plumbing RPD to its color and layer."

/obj/item/construction/plumbing/ui_interact(mob/user, datum/tgui/ui)
	ui = SStgui.try_update_ui(user, src, ui)
	if(!ui)
		ui = new(user, src, "RapidPlumbingDevice", name)
		ui.open()

/obj/item/construction/plumbing/ui_assets(mob/user)
	return list(
		get_asset_datum(/datum/asset/spritesheet_batched/plumbing),
	)

/obj/item/construction/plumbing/ui_static_data(mob/user)
	var/list/data = ..()

	data["paint_colors"] = GLOB.pipe_paint_colors

	var/category_list = list()
	for(var/category_name in plumbing_design_types)
		var/list/designs = plumbing_design_types[category_name]

		//Create category
		var/list/item_list = list()
		item_list["cat_name"] = category_name //used by RapidPipeDispenser.js
		item_list["recipes"] = list() //used by RapidPipeDispenser.js
		category_list[category_name] = item_list

		//Add designs to category
		for(var/obj/machinery/recipe as anything in designs)
			category_list[category_name]["recipes"] += list(list(
				"icon" = initial(recipe.icon_state),
				"name" = initial(recipe.name),
			))

	data["categories"] = list()
	for(var/category_name in category_list)
		data["categories"] += list(category_list[category_name])

	return data

/obj/item/construction/plumbing/ui_data(mob/user)
	var/list/data = ..()

	data["piping_layer"] = name_to_number[current_layer] //maps layer name to layer number's 1,2,3,4,5
	data["selected_color"] = current_color
	data["layer_icon"] = "plumbing_layer[GLOB.plumbing_layers[current_layer]]"
	data["selected_category"] = selected_category
	data["selected_recipe"] = initial(blueprint.name)

	return data

/obj/item/construction/plumbing/handle_ui_act(action, params, datum/tgui/ui, datum/ui_state/state)
	playsound(src, SFX_TOOL_SWITCH, 20, TRUE)

	switch(action)
		if("color")
			var/color = params["paint_color"]
			if(GLOB.pipe_paint_colors[color] != null) //validate if the color is in the allowed list of values
				current_color = color
		if("piping_layer")
			var/bitflag = text2num(params["piping_layer"])  //convert from layer number back to layer string
			bitflag = 1 << (bitflag - 1)
			var/layer = GLOB.plumbing_layer_names["[bitflag]"]
			if(layer != null) //validate if this value exists in the list
				current_layer = layer
		if("recipe")
			var/category = params["category"]

			var/list/designs = plumbing_design_types[category]
			if(!length(designs))
				return FALSE
			selected_category = category

			var/design = designs[text2num(params["id"]) + 1]
			if(!design)
				return FALSE
			blueprint = design
			blueprint_changed = TRUE

	return TRUE


///pretty much rcd_create, but named differently to make myself feel less bad for copypasting from a sibling-type
/obj/item/construction/plumbing/proc/create_machine(atom/destination, mob/user)
	if(!isopenturf(destination))
		return FALSE

	var/cost = 0
	for(var/category in plumbing_design_types)
		cost = plumbing_design_types[category][blueprint]
		if(cost)
			break
	if(!cost)
		return FALSE

	//resource & placement sanity check before & after delay
	var/is_allowed = TRUE
	if(!checkResource(cost, user) || !(is_allowed = canPlace(destination)))
		if(!is_allowed)
			balloon_alert(user, "turf is blocked!")
		return FALSE
	if(!build_delay(user, cost, target = destination))
		return FALSE
	if(!checkResource(cost, user) || !(is_allowed = canPlace(destination)))
		if(!is_allowed)
			balloon_alert(user, "turf is blocked!")
		return FALSE

	if(!useResource(cost, user))
		return FALSE
	activate()
	playsound(loc, 'sound/machines/click.ogg', 50, TRUE)
	if(ispath(blueprint, /obj/machinery/duct))
		var/is_omni = current_color == DUCT_COLOR_OMNI
		new blueprint(destination, FALSE, GLOB.pipe_paint_colors[current_color], GLOB.plumbing_layers[current_layer], null, is_omni)
	else
		new blueprint(destination, FALSE, GLOB.plumbing_layers[current_layer])
	return TRUE

/obj/item/construction/plumbing/proc/canPlace(turf/destination)
	if(!isopenturf(destination))
		return FALSE
	if(initial(blueprint.density) && destination.is_blocked_turf(exclude_mobs = FALSE, source_atom = null, ignore_atoms = null))
		return FALSE
	. = TRUE

	var/layer_id = GLOB.plumbing_layers[current_layer]
	for(var/obj/content_obj in destination.contents)
		// Make sure plumbling isn't overlapping.
		for(var/datum/component/plumbing/plumber as anything in content_obj.GetComponents(/datum/component/plumbing))
			if(plumber.ducting_layer & layer_id)
				return FALSE

		// Make sure ducts aren't overlapping.
		if(istype(content_obj, /obj/machinery/duct))
			var/obj/machinery/duct/duct_machine = content_obj
			if(duct_machine.duct_layer & layer_id)
				return FALSE

/obj/item/construction/plumbing/interact_with_atom(atom/interacting_with, mob/living/user, list/modifiers)
	. = ..()
	if(. & ITEM_INTERACT_ANY_BLOCKER)
		return .
	if(HAS_TRAIT(interacting_with, TRAIT_COMBAT_MODE_SKIP_INTERACTION))
		return NONE

	for(var/category_name in plumbing_design_types)
		var/list/designs = plumbing_design_types[category_name]

		for(var/obj/machinery/recipe as anything in designs)
			if(interacting_with.type != recipe)
				continue

			var/obj/machinery/machine_target = interacting_with
			if(machine_target.anchored)
				balloon_alert(user, "unanchor first!")
				return ITEM_INTERACT_BLOCKING
			if(do_after(user, 2 SECONDS, target = interacting_with))
				machine_target.deconstruct() //Let's not substract matter
				playsound(src, 'sound/machines/click.ogg', 50, TRUE) //this is just such a great sound effect
			return ITEM_INTERACT_SUCCESS

	if(!isopenturf(interacting_with))
		return NONE
	if(create_machine(interacting_with, user))
		return ITEM_INTERACT_SUCCESS
	return ITEM_INTERACT_BLOCKING

/obj/item/construction/plumbing/interact_with_atom_secondary(atom/target, mob/living/user, list/modifiers)
	if(!istype(target, /obj/machinery/duct))
		return NONE

	var/obj/machinery/duct/duct = target
	if(duct.duct_layer && duct.duct_color)
		current_color = GLOB.pipe_color_name[duct.duct_color]
		current_layer = GLOB.plumbing_layer_names["[duct.duct_layer]"]
		balloon_alert(user, "using [current_color], layer [current_layer]")
		return ITEM_INTERACT_SUCCESS
	return ITEM_INTERACT_BLOCKING

/obj/item/construction/plumbing/click_alt(mob/user)
	ui_interact(user)
	return CLICK_ACTION_SUCCESS

/obj/item/construction/plumbing/proc/mouse_wheeled(mob/source, atom/A, delta_x, delta_y, params)
	SIGNAL_HANDLER
	if(INCAPACITATED_IGNORING(source, INCAPABLE_RESTRAINTS|INCAPABLE_STASIS))
		return
	if(delta_y == 0)
		return

	if(delta_y < 0)
		var/current_loc = GLOB.plumbing_layers.Find(current_layer) + 1
		if(current_loc > GLOB.plumbing_layers.len)
			current_loc = 1
		current_layer = GLOB.plumbing_layers[current_loc]
	else
		var/current_loc = GLOB.plumbing_layers.Find(current_layer) - 1
		if(current_loc < 1)
			current_loc = GLOB.plumbing_layers.len
		current_layer = GLOB.plumbing_layers[current_loc]
	to_chat(source, span_notice("You set the layer to [current_layer]."))

/obj/item/construction/plumbing/service
	name = "service plumbing constructor"
	desc = "A type of plumbing constructor designed to rapidly deploy the machines needed to make a brewery."
	icon_state = "plumberer_service"
	///Design types for plumbing service constructor
	var/static/list/service_design_types = list(
		//Category 1 synthesizers
		"Synthesizers" = list(
			/obj/machinery/plumbing/synthesizer/soda = 15,
			/obj/machinery/plumbing/synthesizer/beer = 15,
			/obj/machinery/plumbing/reaction_chamber = 15,
			/obj/machinery/plumbing/buffer = 10,
			/obj/machinery/plumbing/fermenter = 30,
			/obj/machinery/plumbing/grinder_chemical = 30,
			/obj/machinery/plumbing/disposer = 10,
		),

		//Category 2 distributors
		"Distributors" = list(
			/obj/machinery/duct = 1,
			/obj/machinery/plumbing/layer_manifold = 5,
			/obj/machinery/plumbing/input = 5,
			/obj/machinery/plumbing/filter = 5,
			/obj/machinery/plumbing/splitter = 5,
			/obj/machinery/plumbing/output/tap = 5,
			/obj/machinery/plumbing/sender = 20,
		),

		//category 3 storage
		"Storage" = list(
			/obj/machinery/plumbing/bottler = 50,
			/obj/machinery/plumbing/tank = 20,
			/obj/machinery/plumbing/acclimator = 10,
		),
	)

/obj/item/construction/plumbing/service/Initialize(mapload)
	plumbing_design_types = service_design_types

	. = ..()
