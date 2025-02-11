#define ATMOS_PIPEDISPENSER 0
#define DISPOSAL_PIPEDISPENSER 1
#define TRANSIT_PIPEDISPENSER 2

/obj/machinery/pipedispenser
	name = "pipe dispenser"
	icon = 'icons/obj/machines/lathes.dmi'
	icon_state = "pipe_d"
	desc = "Dispenses countless types of pipes. Very useful if you need pipes."
	density = TRUE
	interaction_flags_machine = INTERACT_MACHINE_ALLOW_SILICON | INTERACT_MACHINE_OPEN_SILICON | INTERACT_MACHINE_OFFLINE
	interaction_flags_mouse_drop = NEED_DEXTERITY

	var/wait = 0
	var/piping_layer = PIPING_LAYER_DEFAULT
	///color of pipe
	var/paint_color = "green"
	///type of dispenser
	var/category = ATMOS_PIPEDISPENSER
	///smart pipe directions
	var/p_init_dir = ALL_CARDINALS

/obj/machinery/pipedispenser/attack_paw(mob/user, list/modifiers)
	return attack_hand(user, modifiers)

/obj/machinery/pipedispenser/ui_static_data(mob/user)
	var/list/data = list("paint_colors" = GLOB.pipe_paint_colors)
	return data

/obj/machinery/pipedispenser/ui_data()
	var/list/data = list(
		"category" = category,
		"piping_layer" = piping_layer,
		"categories" = list(),
		"selected_color" = paint_color,
	)

	// The get the recipies for this dispenser
	var/list/recipes
	switch(category)
		if(ATMOS_PIPEDISPENSER)
			recipes = GLOB.atmos_pipe_recipes
		if(DISPOSAL_PIPEDISPENSER)
			recipes = GLOB.disposal_pipe_recipes
		if(TRANSIT_PIPEDISPENSER)
			recipes = GLOB.transit_tube_recipes
	// Generate pipe categories
	for(var/c in recipes)
		var/list/cat = recipes[c]
		var/list/r = list()
		for(var/i in 1 to cat.len)
			var/datum/pipe_info/info = cat[i]
			r += list(list("pipe_name" = info.name, "pipe_index" = i, "all_layers" = info.all_layers, "dir" = NORTH))
			// if this is bendable, add the bent version of the pipe (disposals)
			if (info.dirtype == PIPE_BENDABLE)
				r += list(list("pipe_name" = "Bent " + info.name, "pipe_index" = i, "all_layers" = info.all_layers, "dir" = NORTHEAST))
		data["categories"] += list(list("cat_name" = c, "recipes" = r))
	var/list/init_directions = list("north" = FALSE, "south" = FALSE, "east" = FALSE, "west" = FALSE)
	for(var/direction in GLOB.cardinals)
		if(p_init_dir & direction)
			init_directions[dir2text(direction)] = TRUE
	data["init_directions"] = init_directions
	return data

/obj/machinery/pipedispenser/ui_act(action, list/params, datum/tgui/ui, datum/ui_state/state)
	if(..())
		return
	switch(action)
		if("color")
			paint_color = params["paint_color"]

		if("pipe_type")
			switch(category)
				if(ATMOS_PIPEDISPENSER)
					if(wait < world.time)
						var/datum/pipe_info/info = GLOB.atmos_pipe_recipes[params["category"]][params["pipe_type"]]
						var/recipe_type = info.type
						var/p_type = info.id

						// No spawning arbitrary paths (literally 1984)
						if(!verify_recipe(GLOB.atmos_pipe_recipes, p_type))
							return

						// If this is a meter, make that.
						if(recipe_type == /datum/pipe_info/meter)
							new /obj/item/pipe_meter(loc)
							wait = world.time + 1 SECONDS
							return

						// Otherwise, make a pipe/device
						var/p_dir = params["pipe_dir"]
						var/obj/item/pipe/pipe_out = new (loc, p_type, p_dir)
						pipe_out.p_init_dir = p_init_dir
						pipe_out.pipe_color = GLOB.pipe_paint_colors[paint_color]
						pipe_out.add_atom_colour(GLOB.pipe_paint_colors[paint_color], FIXED_COLOUR_PRIORITY)
						pipe_out.set_piping_layer(piping_layer)
						pipe_out.add_fingerprint(usr)
						wait = world.time + 1 SECONDS
				if(DISPOSAL_PIPEDISPENSER)
					if(wait < world.time)
						var/datum/pipe_info/info = GLOB.disposal_pipe_recipes[params["category"]][params["pipe_type"]]
						var/p_type = info.id

						// No spawning arbitrary paths (literally 1984)
						if(!verify_recipe(GLOB.disposal_pipe_recipes, p_type))
							return

						var/obj/structure/disposalconstruct/disposal_out = new (loc, p_type)
						if(!disposal_out.can_place())
							to_chat(usr, span_warning("There's not enough room to build that here!"))
							qdel(disposal_out)
							return

						disposal_out.add_fingerprint(usr)
						disposal_out.update_appearance()
						disposal_out.setDir(params["pipe_dir"])
						wait = world.time + 1 SECONDS
				if(TRANSIT_PIPEDISPENSER)
					if(wait < world.time)
						var/datum/pipe_info/info = GLOB.transit_tube_recipes[params["category"]][params["pipe_type"]]
						var/p_type = info.id

						// No spawning arbitrary paths (literally 1984)
						if(!verify_recipe(GLOB.transit_tube_recipes, p_type))
							return

						var/obj/structure/c_transit_tube/tube_out = new p_type(loc)
						tube_out.add_fingerprint(usr)
						tube_out.update_appearance()
						tube_out.setDir(params["pipe_dir"])
						wait = world.time + 1 SECONDS
		if("piping_layer")
			piping_layer = text2num(params["piping_layer"])

		if("init_dir_setting")
			var/target_dir = p_init_dir ^ text2dir(params["dir_flag"])
			// Refuse to create a smart pipe that can only connect in one direction (it would act weirdly and lack an icon)
			if (ISNOTSTUB(target_dir))
				p_init_dir = target_dir
			else
				to_chat(usr, span_warning("\The [src]'s screen flashes a warning: Can't configure a pipe to only connect in one direction."))

		if("init_reset")
			p_init_dir = ALL_CARDINALS

	return TRUE

/obj/machinery/pipedispenser/ui_interact(mob/user, datum/tgui/ui)
	ui = SStgui.try_update_ui(user, src, ui)
	if(!ui)
		ui = new(user, src, "PipeDispenser", name)
		ui.open()

/obj/machinery/pipedispenser/attackby(obj/item/W, mob/user, params)
	add_fingerprint(user)
	if (istype(W, /obj/item/pipe) || istype(W, /obj/item/pipe_meter))
		to_chat(usr, span_notice("You put [W] back into [src]."))
		qdel(W)
		return
	else
		return ..()

/obj/machinery/pipedispenser/proc/verify_recipe(recipes, path)
	for(var/category in recipes)
		var/list/cat_recipes = recipes[category]
		for(var/i in cat_recipes)
			var/datum/pipe_info/info = i
			if (path == info.id)
				return TRUE
	return FALSE

/obj/machinery/pipedispenser/wrench_act(mob/living/user, obj/item/tool)
	. = ..()
	default_unfasten_wrench(user, tool, time = 4 SECONDS)
	return ITEM_INTERACT_SUCCESS


/obj/machinery/pipedispenser/disposal
	name = "disposal pipe dispenser"
	icon = 'icons/obj/machines/lathes.dmi'
	icon_state = "pipe_d"
	desc = "Dispenses pipes that will ultimately be used to move trash around."
	density = TRUE
	category = DISPOSAL_PIPEDISPENSER

//Allow you to drag-drop disposal pipes and transit tubes into it
/obj/machinery/pipedispenser/disposal/mouse_drop_receive(obj/structure/pipe, mob/user, params)
	if (!istype(pipe, /obj/structure/disposalconstruct) && !istype(pipe, /obj/structure/c_transit_tube) && !istype(pipe, /obj/structure/c_transit_tube_pod))
		return

	if (get_dist(user, src) > 1 || get_dist(src, pipe) > 1 )
		return

	if (pipe.anchored)
		return

	qdel(pipe)

//transit tube dispenser
//inherit disposal for the dragging proc
/obj/machinery/pipedispenser/disposal/transit_tube
	name = "transit tube dispenser"
	icon = 'icons/obj/machines/lathes.dmi'
	icon_state = "pipe_d"
	density = TRUE
	desc = "Dispenses pipes that will move beings around."
	category = TRANSIT_PIPEDISPENSER

#undef ATMOS_PIPEDISPENSER
#undef DISPOSAL_PIPEDISPENSER
#undef TRANSIT_PIPEDISPENSER
