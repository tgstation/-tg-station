//RAPID PIPE DISPENSER

#define ATMOS_CATEGORY 0
#define DISPOSALS_CATEGORY 1
#define TRANSIT_CATEGORY 2

#define BUILD_MODE (1<<0)
#define WRENCH_MODE (1<<1)
#define DESTROY_MODE (1<<2)
#define REPROGRAM_MODE (1<<3)

///Maximum number of pipe layers the RPD can support
#define MAX_PIPE_LAYERS 5

///Converts the pipe layer into a bitflag so we can append multiple layers into 1 bitfield
#define PIPE_LAYER(num) (1 << (num - 1))

///Sound to make when we use the item to build/destroy something
#define RPD_USE_SOUND 'sound/items/deconstruct.ogg'

/obj/item/pipe_dispenser
	name = "rapid pipe dispenser"
	desc = "A device used to rapidly pipe things."
	icon = 'icons/obj/tools.dmi'
	icon_state = "rpd"
	worn_icon_state = "RPD"
	lefthand_file = 'icons/mob/inhands/equipment/tools_lefthand.dmi'
	righthand_file = 'icons/mob/inhands/equipment/tools_righthand.dmi'
	obj_flags = CONDUCTS_ELECTRICITY
	force = 10
	throwforce = 10
	throw_speed = 1
	throw_range = 5
	w_class = WEIGHT_CLASS_NORMAL
	slot_flags = ITEM_SLOT_BELT
	custom_materials = list(/datum/material/iron=SHEET_MATERIAL_AMOUNT*37.5, /datum/material/glass=SHEET_MATERIAL_AMOUNT*18.75)
	armor_type = /datum/armor/item_pipe_dispenser
	resistance_flags = FIRE_PROOF
	drop_sound = 'sound/items/handling/tools/rpd_drop.ogg'
	pickup_sound = 'sound/items/handling/tools/rpd_pickup.ogg'
	sound_vary = TRUE
	///Sparks system used when changing device in the UI
	var/datum/effect_system/spark_spread/spark_system
	///Direction of the device we are going to spawn, set up in the UI
	var/p_dir = NORTH
	///Initial direction of the smart pipe we are going to spawn, set up in the UI
	var/p_init_dir = ALL_CARDINALS
	///Is the device of the flipped type?
	var/p_flipped = FALSE
	///Color of the device we are going to spawn
	var/paint_color = "green"
	///Speed of building atmos devices
	var/atmos_build_speed = 0.4 SECONDS
	///Speed of building disposal devices
	var/disposal_build_speed = 0.5 SECONDS
	///Speed of building transit devices
	var/transit_build_speed = 0.5 SECONDS
	///Category currently active (Atmos, disposal, transit)
	var/category = ATMOS_CATEGORY
	///All pipe layers we are going to spawn the atmos devices in
	var/pipe_layers = PIPE_LAYER(3)
	///Are we laying multiple layers per click
	var/multi_layer = FALSE
	///Stores the current device to spawn
	var/datum/pipe_info/recipe
	///Stores the first atmos device
	var/static/datum/pipe_info/first_atmos
	///Stores the first disposal device
	var/static/datum/pipe_info/first_disposal
	///Stores the first transit device
	var/static/datum/pipe_info/first_transit
	///The modes that are allowed for the RPD
	var/mode = BUILD_MODE | DESTROY_MODE | WRENCH_MODE | REPROGRAM_MODE
	/// Bitflags for upgrades
	var/upgrade_flags

/datum/armor/item_pipe_dispenser
	fire = 100
	acid = 50

/obj/item/pipe_dispenser/Initialize(mapload)
	. = ..()
	spark_system = new
	spark_system.set_up(5, 0, src)
	spark_system.attach(src)
	if(!first_atmos)
		first_atmos = GLOB.atmos_pipe_recipes[GLOB.atmos_pipe_recipes[1]][1]
	if(!first_disposal)
		first_disposal = GLOB.disposal_pipe_recipes[GLOB.disposal_pipe_recipes[1]][1]
	if(!first_transit)
		first_transit = GLOB.transit_tube_recipes[GLOB.transit_tube_recipes[1]][1]

	recipe = first_atmos
	register_item_context()

/obj/item/pipe_dispenser/Destroy()
	QDEL_NULL(spark_system)
	return ..()

/obj/item/pipe_dispenser/examine(mob/user)
	. = ..()
	. += span_notice("You can scroll your <b>mouse wheel</b> to change the piping layer.")
	. += span_notice("You can <b>right click</b> a pipe to set the RPD to its color and layer.")

/obj/item/pipe_dispenser/add_item_context(obj/item/source, list/context, atom/target, mob/living/user)
	. = NONE

	if(istype(target, /obj/machinery/atmospherics))
		var/obj/machinery/atmospherics/atmos_target = target
		if(atmos_target.pipe_color && atmos_target.piping_layer)
			context[SCREENTIP_CONTEXT_RMB] = "Copy piping color and layer"
			return CONTEXTUAL_SCREENTIP_SET

/obj/item/pipe_dispenser/equipped(mob/user, slot, initial)
	. = ..()
	if(slot & ITEM_SLOT_HANDS)
		RegisterSignal(user, COMSIG_MOUSE_SCROLL_ON, PROC_REF(mouse_wheeled))
	else
		UnregisterSignal(user,COMSIG_MOUSE_SCROLL_ON)

/obj/item/pipe_dispenser/dropped(mob/user, silent)
	UnregisterSignal(user, COMSIG_MOUSE_SCROLL_ON)
	return ..()

/obj/item/pipe_dispenser/cyborg_unequip(mob/user)
	UnregisterSignal(user, COMSIG_MOUSE_SCROLL_ON)
	return ..()

/obj/item/pipe_dispenser/attack_self(mob/user)
	ui_interact(user)

/obj/item/pipe_dispenser/suicide_act(mob/living/user)
	user.visible_message(span_suicide("[user] points the end of the RPD down [user.p_their()] throat and presses a button! It looks like [user.p_theyre()] trying to commit suicide..."))
	playsound(get_turf(user), SFX_TOOL_SWITCH, 20, TRUE)
	playsound(get_turf(user), RPD_USE_SOUND, 50, TRUE)
	return BRUTELOSS

///Converts pipe_layers bitflag into its corresponding list of actual pipe layers
/obj/item/pipe_dispenser/proc/get_active_pipe_layers()
	PRIVATE_PROC(TRUE)
	RETURN_TYPE(/list)

	var/list/layer_nums = list()
	for(var/pipe_layer_number in 1 to MAX_PIPE_LAYERS)
		if(PIPE_LAYER(pipe_layer_number) & pipe_layers)
			layer_nums += pipe_layer_number
	return layer_nums

/obj/item/pipe_dispenser/ui_assets(mob/user)
	return list(
		get_asset_datum(/datum/asset/spritesheet_batched/pipes),
	)

/obj/item/pipe_dispenser/ui_interact(mob/user, datum/tgui/ui)
	ui = SStgui.try_update_ui(user, src, ui)
	if(!ui)
		ui = new(user, src, "RapidPipeDispenser", name)
		ui.open()

/obj/item/pipe_dispenser/ui_static_data(mob/user)
	return list(
		"paint_colors" = GLOB.pipe_paint_colors,
		"max_pipe_layers" = MAX_PIPE_LAYERS,
	)

/obj/item/pipe_dispenser/ui_data(mob/user)
	var/list/data = list(
		"category" = category,
		"multi_layer" = multi_layer,
		"pipe_layers" = pipe_layers,
		"categories" = list(),
		"selected_recipe" = recipe.name,
		"selected_color" = paint_color,
		"mode" = mode,
	)

	//currently selected category (atmos, disposal or transit)
	var/list/selected_major_category
	switch(category)
		if(ATMOS_CATEGORY)
			selected_major_category = GLOB.atmos_pipe_recipes
		if(DISPOSALS_CATEGORY)
			selected_major_category = GLOB.disposal_pipe_recipes
		if(TRANSIT_CATEGORY)
			selected_major_category = GLOB.transit_tube_recipes
	//selected subcategory (e.g. pipes/binary/devices/heat exchange for atmos)
	for(var/subcategory in selected_major_category)
		var/list/subcategory_recipes = selected_major_category[subcategory]
		var/list/available_recipe = list()
		for(var/i in 1 to subcategory_recipes.len)
			var/datum/pipe_info/info = subcategory_recipes[i]

			available_recipe += list(list(
				"pipe_name" = info.name,
				"pipe_index" = i,
				"previews" = info.get_preview(p_dir, info == recipe)
			))
			if(info == recipe)
				data["selected_category"] = subcategory

		data["categories"] += list(list("cat_name" = subcategory, "recipes" = available_recipe))

	var/list/init_directions = list("north" = FALSE, "south" = FALSE, "east" = FALSE, "west" = FALSE)
	for(var/direction in GLOB.cardinals)
		if(p_init_dir & direction)
			init_directions[dir2text(direction)] = TRUE
	data["init_directions"] = init_directions
	return data

/obj/item/pipe_dispenser/ui_act(action, list/params, datum/tgui/ui, datum/ui_state/state)
	. = ..()
	if(.)
		return

	playsound(src, SFX_TOOL_SWITCH, 20, TRUE)

	switch(action)
		if("color")
			paint_color = params["paint_color"]
			return TRUE

		if("category")
			category = text2num(params["category"])
			switch(category)
				if(DISPOSALS_CATEGORY)
					recipe = first_disposal
				if(ATMOS_CATEGORY)
					recipe = first_atmos
				if(TRANSIT_CATEGORY)
					recipe = first_transit
			p_dir = NORTH
			return TRUE

		if("pipe_layers")
			var/selected_layers = text2num(params["pipe_layers"])

			//is valid
			var/valid_layer = FALSE
			for(var/pipe_layer_number in 1 to MAX_PIPE_LAYERS)
				if(!(PIPE_LAYER(pipe_layer_number) & selected_layers))
					continue
				valid_layer = TRUE
				break
			if(!valid_layer)
				return FALSE

			//append or set the layer
			if(multi_layer)
				if(pipe_layers != selected_layers)
					pipe_layers ^= selected_layers
			else
				pipe_layers = selected_layers

			return TRUE

		if("toggle_multi_layer")
			if(multi_layer)
				pipe_layers = PIPE_LAYER(max(get_active_pipe_layers()))
			multi_layer = !multi_layer

		if("pipe_type")
			var/static/list/recipes
			if(!recipes)
				recipes = GLOB.disposal_pipe_recipes + GLOB.atmos_pipe_recipes + GLOB.transit_tube_recipes
			recipe = recipes[params["category"]][text2num(params["pipe_type"])]
			p_dir = NORTH

		if("setdir")
			p_dir = text2dir(params["dir"])
			p_flipped = text2num(params["flipped"])
			return TRUE

		if("mode")
			var/selected_mode = text2num(params["mode"])
			mode ^= selected_mode

		if("init_dir_setting")
			var/target_dir = p_init_dir ^ text2dir(params["dir_flag"])
			// Refuse to create a smart pipe that can only connect in one direction (it would act weirdly and lack an icon)
			if (ISNOTSTUB(target_dir))
				p_init_dir = target_dir
			else
				to_chat(ui.user, span_warning("\The [src]'s screen flashes a warning: Can't configure a pipe to only connect in one direction."))
				return FALSE

		if("init_reset")
			p_init_dir = ALL_CARDINALS

	spark_system.start()
	playsound(get_turf(src), 'sound/effects/pop.ogg', 50, FALSE)
	return TRUE

/obj/item/pipe_dispenser/interact_with_atom(atom/attack_target, mob/living/user, list/modifiers)
	. = NONE

	if(!ISADVANCEDTOOLUSER(user) || HAS_TRAIT(attack_target, TRAIT_COMBAT_MODE_SKIP_INTERACTION) || istype(attack_target, /turf/open/space/transit))
		return

	if(istype(attack_target, /obj/item/rpd_upgrade))
		var/obj/item/rpd_upgrade/rpd_disk = attack_target

		// Check if the upgrade's already present
		if(rpd_disk.upgrade_flags & upgrade_flags)
			balloon_alert(user, "already installed!")
			return ITEM_INTERACT_BLOCKING

		// Adds the upgrade from the disk and then deletes the disk
		upgrade_flags |= rpd_disk.upgrade_flags
		playsound(loc, 'sound/machines/click.ogg', 50, vary = TRUE)
		balloon_alert(user, "upgrade installed")
		qdel(rpd_disk)
		return ITEM_INTERACT_SUCCESS

	//So that changing the menu settings doesn't affect the pipes already being built.
	var/queued_pipe_type = recipe.id
	var/queued_pipe_dir = p_dir
	var/queued_pipe_flipped = p_flipped

	//Unwrench pipe before we build one over/paint it, but only if we're not already running a do_after on it already to prevent a potential runtime.
	if((mode & DESTROY_MODE) && (upgrade_flags & RPD_UPGRADE_UNWRENCH) && istype(attack_target, /obj/machinery/atmospherics) && !(DOING_INTERACTION_WITH_TARGET(user, attack_target)))
		attack_target = attack_target.wrench_act(user, src)
		if(!isatom(attack_target)) //can return null, FALSE if do_after() fails see /obj/machinery/atmospherics/wrench_act()
			return ITEM_INTERACT_FAILURE

	if(istype(attack_target, /obj/machinery/atmospherics) && (mode & BUILD_MODE))
		attack_target = get_turf(attack_target)

	var/can_destroy = FALSE
	if((mode & DESTROY_MODE) && istype(attack_target, /obj/item/pipe))
		can_destroy = TRUE
	if(!can_destroy)
		var/static/list/destroyables = list(
			/obj/structure/disposalconstruct,
			/obj/structure/c_transit_tube,
			/obj/structure/c_transit_tube_pod,
			/obj/item/pipe_meter,
			/obj/structure/disposalpipe/broken
		)
		can_destroy = is_type_in_list(attack_target, destroyables)
	if(can_destroy)
		var/turf/ground = get_turf(src)
		playsound(ground, SFX_TOOL_SWITCH, 20, TRUE)
		playsound(ground, RPD_USE_SOUND, 50, TRUE)
		qdel(attack_target)
		return ITEM_INTERACT_SUCCESS

	if(mode & REPROGRAM_MODE)
		// If this is a placed smart pipe, try to reprogram it
		var/obj/machinery/atmospherics/pipe/smart/target_smart_pipe = attack_target
		if(istype(target_smart_pipe))
			if(target_smart_pipe.dir == ALL_CARDINALS)
				balloon_alert(user, "has no unconnected directions!")
				return ITEM_INTERACT_FAILURE
			var/old_init_dir = target_smart_pipe.get_init_directions()
			if(old_init_dir == p_init_dir)
				balloon_alert(user, "already configured!")
				return ITEM_INTERACT_FAILURE
			// Check for differences in unconnected directions
			var/target_differences = (p_init_dir ^ old_init_dir) & ~target_smart_pipe.connections
			if(!target_differences)
				balloon_alert(user, "already configured for its directions!")
				return ITEM_INTERACT_FAILURE

			playsound(get_turf(src), SFX_TOOL_SWITCH, 20, TRUE)

			// Something else could have changed the target's state while we were waiting in do_after
			// Most of the edge cases don't matter, but atmos components being able to have live connections not described by initializable directions sounds like a headache at best and an exploit at worst

			// Double check to make sure that nothing has changed. If anything we were about to change was connected during do_after, abort
			if(target_differences & target_smart_pipe.connections)
				balloon_alert(user, "can't configure for its direction!")
				return ITEM_INTERACT_FAILURE
			// Grab the current initializable directions, which may differ from old_init_dir if someone else was working on the same pipe at the same time
			var/current_init_dir = target_smart_pipe.get_init_directions()
			// Access p_init_dir directly. The RPD can change target layer and initializable directions (though not pipe type or dir) while working to dispense and connect a component,
			// and have it reflected in the final result. Reprogramming should be similarly consistent.
			var/new_init_dir = (current_init_dir & ~target_differences) | (p_init_dir & target_differences)
			// Don't make a smart pipe with only one connection
			if(ISSTUB(new_init_dir))
				balloon_alert(user, "no one directional pipes allowed!")
				return ITEM_INTERACT_FAILURE
			target_smart_pipe.set_init_directions(new_init_dir)
			// We're now reconfigured.
			// We can never disconnect from existing connections, but we can connect to previously unconnected directions, and should immediately do so
			var/newly_permitted_connections = new_init_dir & ~current_init_dir
			if(newly_permitted_connections)
				// We're allowed to connect in new directions. Recompute our nodes
				// Disconnect from everything that is currently connected
				for(var/i in 1 to target_smart_pipe.device_type)
					// This is basically pipe.nullifyNode, but using it here would create a pitfall for others attempting to
					// copy and paste disconnection code for other components. Welcome to the atmospherics subsystem
					var/obj/machinery/atmospherics/node = target_smart_pipe.nodes[i]
					if(!node)
						continue
					node.disconnect(target_smart_pipe)
					target_smart_pipe.nodes[i] = null
				// Get our new connections
				target_smart_pipe.atmos_init()
				// Connect to our new connections
				for(var/obj/machinery/atmospherics/connected_device in target_smart_pipe.nodes)
					connected_device.atmos_init()
					connected_device.add_member(target_smart_pipe)
				SSair.add_to_rebuild_queue(target_smart_pipe)
			// Finally, update our internal state - update_pipe_icon also updates dir and connections
			target_smart_pipe.update_pipe_icon()
			user.visible_message(span_notice("[user] reprograms \the [target_smart_pipe]."), span_notice("You reprogram \the [target_smart_pipe]."))
			return ITEM_INTERACT_SUCCESS

		// If this is an unplaced smart pipe, try to reprogram it
		var/obj/item/pipe/quaternary/target_unsecured_pipe = attack_target
		if(istype(target_unsecured_pipe) && ispath(target_unsecured_pipe.pipe_type, /obj/machinery/atmospherics/pipe/smart))
			// An unplaced pipe never has any existing connections, so just directly assign the new configuration
			target_unsecured_pipe.p_init_dir = p_init_dir
			target_unsecured_pipe.update()
			return ITEM_INTERACT_SUCCESS

	if(mode & BUILD_MODE)
		switch(category) //if we've gotten this var, the target is valid
			if(ATMOS_CATEGORY) //Making pipes
				return do_pipe_build(attack_target, user) ? ITEM_INTERACT_SUCCESS : ITEM_INTERACT_FAILURE

			if(DISPOSALS_CATEGORY) //Making disposals pipes
				if(!check_can_make_pipe(attack_target))
					return ITEM_INTERACT_FAILURE
				attack_target = get_turf(attack_target)
				if(isclosedturf(attack_target))
					balloon_alert(user, "target is blocked!")
					return ITEM_INTERACT_FAILURE
				playsound(get_turf(src), SFX_TOOL_SWITCH, 20, TRUE)

				if(!do_after(user, disposal_build_speed, target = attack_target))
					return ITEM_INTERACT_FAILURE

				var/obj/structure/disposalconstruct/new_disposals_segment = new (attack_target, queued_pipe_type, queued_pipe_dir, queued_pipe_flipped)

				if(!new_disposals_segment.can_place())
					balloon_alert(user, "not enough room!")
					qdel(new_disposals_segment)
					return ITEM_INTERACT_FAILURE

				playsound(get_turf(src), RPD_USE_SOUND, 50, TRUE)

				new_disposals_segment.add_fingerprint(user)
				new_disposals_segment.update_appearance()
				if(mode & WRENCH_MODE)
					new_disposals_segment.wrench_act(user, src)
				return ITEM_INTERACT_SUCCESS

			if(TRANSIT_CATEGORY) //Making transit tubes
				if(!check_can_make_pipe(attack_target))
					return ITEM_INTERACT_FAILURE
				attack_target = get_turf(attack_target)
				if(isclosedturf(attack_target))
					balloon_alert(user, "something in the way!")
					return ITEM_INTERACT_FAILURE

				var/turf/target_turf = get_turf(attack_target)
				if(target_turf.is_blocked_turf(exclude_mobs = TRUE))
					balloon_alert(user, "something in the way!")
					return ITEM_INTERACT_FAILURE

				playsound(get_turf(src), SFX_TOOL_SWITCH, 20, TRUE)
				if(!do_after(user, transit_build_speed, target = attack_target))
					return ITEM_INTERACT_FAILURE

				playsound(get_turf(src), RPD_USE_SOUND, 50, TRUE)
				if(queued_pipe_type == /obj/structure/c_transit_tube_pod)
					var/obj/structure/c_transit_tube_pod/pod = new /obj/structure/c_transit_tube_pod(attack_target)
					pod.add_fingerprint(user)
					if(mode & WRENCH_MODE)
						pod.wrench_act(user, src)

				else
					var/obj/structure/c_transit_tube/tube = new queued_pipe_type(attack_target)
					tube.setDir(queued_pipe_dir)

					if(queued_pipe_flipped)
						tube.setDir(turn(queued_pipe_dir, 45 + ROTATION_FLIP))
						tube.post_rotation(user, ROTATION_FLIP)

					tube.add_fingerprint(user)
					if(mode & WRENCH_MODE)
						tube.wrench_act(user, src)
				return ITEM_INTERACT_SUCCESS

/obj/item/pipe_dispenser/interact_with_atom_secondary(obj/machinery/atmospherics/target, mob/living/user, list/modifiers)
	. = NONE

	if(!istype(target))
		return

	if(target.pipe_color && target.piping_layer)
		paint_color = GLOB.pipe_color_name[target.pipe_color]
		pipe_layers = PIPE_LAYER(target.piping_layer)
		balloon_alert(user, "color/layer copied")
		return ITEM_INTERACT_SUCCESS

/**
 * Can we make a pipe on the target
 * Arguments
 *
 * * atom/target_of_attack - the target we are trying to build a pipe on
 */
/obj/item/pipe_dispenser/proc/check_can_make_pipe(atom/target_of_attack)
	PRIVATE_PROC(TRUE)
	SHOULD_BE_PURE(TRUE)

	if(isturf(target_of_attack))
		return TRUE

	//make sure what we're clicking is valid for the current category
	var/static/list/make_pipe_whitelist = typecacheof(
		list(
				/obj/structure/lattice,
				/obj/structure/girder,
				/obj/item/pipe,
				/obj/structure/window,
				/obj/structure/grille
			)
	)
	return is_type_in_typecache(target_of_attack, make_pipe_whitelist)

/**
 * Build pipe on the target
 * Arguments
 *
 * * atom/atom_to_target - the target we are trying to build the pipe on
 * * mob/user - mob performing the action
 */
/obj/item/pipe_dispenser/proc/do_pipe_build(atom/atom_to_target, mob/user)
	PRIVATE_PROC(TRUE)

	if(!check_can_make_pipe(atom_to_target))
		return FALSE

	//So that changing the menu settings doesn't affect the pipes already being built.
	var/queued_pipe_type = recipe.id
	var/queued_pipe_dir = p_dir
	var/queued_pipe_flipped = p_flipped

	var/list/pipe_layer_numbers = get_active_pipe_layers()
	for(var/layer_to_build in pipe_layer_numbers)
		playsound(get_turf(src), SFX_TOOL_SWITCH, 20, vary = TRUE)
		if(!do_after(user, atmos_build_speed, target = atom_to_target))
			return FALSE
		if(!recipe.all_layers && (layer_to_build == 1 || layer_to_build == MAX_PIPE_LAYERS))
			balloon_alert(user, "can't build on layer [layer_to_build]!")
			if(multi_layer)
				continue
			return FALSE
		playsound(get_turf(src), RPD_USE_SOUND, 50, TRUE)
		if(recipe.type == /datum/pipe_info/meter)
			var/obj/item/pipe_meter/new_meter = new /obj/item/pipe_meter(get_turf(atom_to_target))
			new_meter.setAttachLayer(layer_to_build)
			if(mode & WRENCH_MODE)
				new_meter.wrench_act(user, src)
		else
			var/obj/machinery/atmospherics/path = queued_pipe_type
			var/pipe_item_type = initial(path.construction_type) || /obj/item/pipe
			var/obj/item/pipe/pipe_type = new pipe_item_type(
				get_turf(atom_to_target),
				queued_pipe_type,
				queued_pipe_dir,
				null,
				GLOB.pipe_paint_colors[paint_color],
				ispath(queued_pipe_type, /obj/machinery/atmospherics/pipe/smart) ? p_init_dir : null,
			)
			if(queued_pipe_flipped && istype(pipe_type, /obj/item/pipe/trinary/flippable))
				var/obj/item/pipe/trinary/flippable/new_flippable_pipe = pipe_type
				new_flippable_pipe.flipped = queued_pipe_flipped

			pipe_type.update()
			pipe_type.add_fingerprint(user)
			pipe_type.set_piping_layer(layer_to_build)
			if(ispath(queued_pipe_type, /obj/machinery/atmospherics) && !ispath(queued_pipe_type, /obj/machinery/atmospherics/pipe/color_adapter))
				pipe_type.add_atom_colour(GLOB.pipe_paint_colors[paint_color], FIXED_COLOUR_PRIORITY)
			if(mode & WRENCH_MODE)
				pipe_type.wrench_act(user, src)
	return TRUE

///Changes the piping layer when the mousewheel is scrolled up or down.
/obj/item/pipe_dispenser/proc/mouse_wheeled(mob/source_mob, atom/A, delta_x, delta_y, params)
	SIGNAL_HANDLER
	if(multi_layer)
		balloon_alert(source_mob, "turn off multi layer!")
		return
	if(INCAPACITATED_IGNORING(source_mob, INCAPABLE_RESTRAINTS|INCAPABLE_STASIS))
		return
	if(source_mob.get_active_held_item() != src)
		return

	if(delta_y < 0)
		pipe_layers = min(PIPE_LAYER(MAX_PIPE_LAYERS), pipe_layers << 1)
	else if(delta_y > 0)
		pipe_layers = max(PIPE_LAYER(1), pipe_layers >> 1)
	else //mice with side-scrolling wheels are apparently a thing and fuck this up
		return
	SStgui.update_uis(src)
	balloon_alert(source_mob, "set pipe layer to [get_active_pipe_layers()[1]]")


/obj/item/rpd_upgrade
	name = "RPD advanced design disk"
	desc = "It seems to be empty."
	icon = 'icons/obj/devices/circuitry_n_data.dmi'
	icon_state = "datadisk3"
	/// Bitflags for upgrades
	var/upgrade_flags

/obj/item/rpd_upgrade/unwrench
	name = "RPD advanced upgrade: wrench mode"
	desc = "Adds reverse wrench mode to the RPD. Attention, due to budget cuts, the mode is hard linked to the destroy mode control button."
	icon_state = "datadisk1"
	upgrade_flags = RPD_UPGRADE_UNWRENCH

#undef ATMOS_CATEGORY
#undef DISPOSALS_CATEGORY
#undef TRANSIT_CATEGORY

#undef BUILD_MODE
#undef DESTROY_MODE
#undef WRENCH_MODE
#undef REPROGRAM_MODE

#undef PIPE_LAYER

#undef RPD_USE_SOUND
#undef MAX_PIPE_LAYERS
