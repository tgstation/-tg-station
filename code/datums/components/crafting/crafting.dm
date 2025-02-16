/datum/component/personal_crafting
	/// Custom screen_loc for our element
	var/screen_loc_override

/datum/component/personal_crafting/Initialize(screen_loc_override)
	src.screen_loc_override = screen_loc_override
	if(ismob(parent))
		RegisterSignal(parent, COMSIG_MOB_CLIENT_LOGIN, PROC_REF(create_mob_button))

/datum/component/personal_crafting/proc/create_mob_button(mob/user, client/user_client)
	SIGNAL_HANDLER

	var/datum/hud/hud = user.hud_used
	var/atom/movable/screen/craft/craft_ui = new()
	craft_ui.icon = hud.ui_style
	if (screen_loc_override)
		craft_ui.screen_loc = screen_loc_override
	hud.static_inventory += craft_ui
	user_client.screen += craft_ui
	RegisterSignal(craft_ui, COMSIG_SCREEN_ELEMENT_CLICK, PROC_REF(component_ui_interact))

#define COOKING TRUE
#define CRAFTING FALSE

/datum/component/personal_crafting
	var/busy
	var/mode = CRAFTING
	var/display_craftable_only = FALSE
	var/display_compact = FALSE
	var/forced_mode = FALSE
	/// crafting flags we ignore when considering a recipe
	var/ignored_flags = NONE

/* This is what procs do:
	get_environment - gets a list of things accessable for crafting by user
	get_surroundings - takes a list of things and makes a list of key-types to values-amounts of said type in the list
	check_contents - takes a recipe and a key-type list and checks if said recipe can be done with available stuff
	check_tools - takes recipe, a key-type list, and a user and checks if there are enough tools to do the stuff, checks bugs one level deep
	construct_item - takes a recipe and a user, call all the checking procs, calls do_after, checks all the things again, calls del_reqs, creates result, calls CheckParts of said result with argument being list returned by deel_reqs
	del_reqs - takes recipe and a user, loops over the recipes reqs var and tries to find everything in the list make by get_environment and delete it/add to parts list, then returns the said list
*/

/**
 * Check that the contents of the recipe meet the requirements.
 *
 * user: The /mob that initated the crafting.
 * R: The /datum/crafting_recipe being attempted.
 * contents: List of items to search for R's reqs.
 */
/datum/component/personal_crafting/proc/check_contents(atom/a, datum/crafting_recipe/R, list/contents)
	var/list/item_instances = contents["instances"]
	var/list/machines = contents["machinery"]
	var/list/structures = contents["structures"]
	contents = contents["other"]


	var/list/requirements_list = list()

	// Process all requirements
	for(var/requirement_path in R.reqs)
		// Check we have the appropriate amount available in the contents list
		var/needed_amount = R.reqs[requirement_path]
		for(var/content_item_path in contents)
			// Right path and not blacklisted
			if(!ispath(content_item_path, requirement_path) || R.blacklist.Find(content_item_path))
				continue

			needed_amount -= contents[content_item_path]
			if(needed_amount <= 0)
				break

		if(needed_amount > 0)
			return FALSE

		// Store the instances of what we will use for R.check_requirements() for requirement_path
		var/list/instances_list = list()
		for(var/instance_path in item_instances)
			if(ispath(instance_path, requirement_path))
				instances_list += item_instances[instance_path]

		requirements_list[requirement_path] = instances_list

	for(var/requirement_path in R.chem_catalysts)
		if(contents[requirement_path] < R.chem_catalysts[requirement_path])
			return FALSE

	var/mech_found = FALSE
	for(var/machinery_path in R.machinery)
		mech_found = FALSE
		for(var/obj/machinery/machine as anything in machines)
			if(ispath(machine, machinery_path))//We don't care for volume with machines, just if one is there or not
				mech_found = TRUE
				break
		if(!mech_found)
			return FALSE

	for(var/required_structure_path in R.structures)
		// Check for the presence of the required structure. Allow for subtypes to be used if not blacklisted
		var/needed_amount = R.structures[required_structure_path]
		for(var/structure_path in structures)
			if(!ispath(structure_path, required_structure_path) || R.blacklist.Find(structure_path))
				continue

				needed_amount -= structures[required_structure_path]
				requirements_list[required_structure_path] = structures[structure_path] // Store an instance of what we are using for check_requirements
				if(needed_amount <= 0)
					break

		// We didn't find the required item
		if(needed_amount > 0)
			return FALSE

	return R.check_requirements(a, requirements_list)

/datum/component/personal_crafting/proc/get_environment(atom/a, list/blacklist = null, radius_range = 1)
	. = list()

	if(!isturf(a.loc))
		return

	for(var/atom/movable/AM in range(radius_range, a))
		if((AM.flags_1 & HOLOGRAM_1) || (blacklist && (AM.type in blacklist)))
			continue
		if(isitem(AM))
			var/obj/item/item = AM
			if(item.item_flags & ABSTRACT) //let's not tempt fate, shall we?
				continue
		. += AM

/datum/component/personal_crafting/proc/get_surroundings(atom/a, list/blacklist=null)
	. = list()
	.["tool_behaviour"] = list()
	.["other"] = list()
	.["instances"] = list()
	.["machinery"] = list()
	.["structures"] = list()
	for(var/obj/object in get_environment(a, blacklist))
		if(isitem(object))
			var/obj/item/item = object
			LAZYADDASSOCLIST(.["instances"], item.type, item)
			if(isstack(item))
				var/obj/item/stack/stack = item
				.["other"][item.type] += stack.amount
			else
				.["other"][item.type] += 1
				if(is_reagent_container(item) && item.is_drainable() && length(item.reagents.reagent_list)) //some container that has some reagents inside it that can be drained
					var/obj/item/reagent_containers/container = item
					for(var/datum/reagent/reagent as anything in container.reagents.reagent_list)
						.["other"][reagent.type] += reagent.volume
				else //a reagent container that is empty can also be used as a tool. e.g. glass bottle can be used as a rolling pin
					if(item.tool_behaviour)
						.["tool_behaviour"] += item.tool_behaviour
		else if (ismachinery(object))
			LAZYADDASSOCLIST(.["machinery"], object.type, object)
		else if (isstructure(object))
			LAZYADDASSOCLIST(.["structures"], object.type, object)

/// Returns a boolean on whether the tool requirements of the input recipe are satisfied by the input source and surroundings.
/datum/component/personal_crafting/proc/check_tools(atom/source, datum/crafting_recipe/recipe, list/surroundings)
	if(!length(recipe.tool_behaviors) && !length(recipe.tool_paths))
		return TRUE
	var/list/available_tools = list()
	var/list/present_qualities = list()

	for(var/obj/item/contained_item in source.contents)
		if(contained_item.atom_storage)
			for(var/obj/item/subcontained_item in contained_item.contents)
				available_tools[subcontained_item.type] = TRUE
				if(subcontained_item.tool_behaviour)
					present_qualities[subcontained_item.tool_behaviour] = TRUE
		available_tools[contained_item.type] = TRUE
		if(contained_item.tool_behaviour)
			present_qualities[contained_item.tool_behaviour] = TRUE

	for(var/quality in surroundings["tool_behaviour"])
		present_qualities[quality] = TRUE

	for(var/path in surroundings["other"])
		available_tools[path] = TRUE

	for(var/required_quality in recipe.tool_behaviors)
		if(present_qualities[required_quality])
			continue
		return FALSE

	for(var/required_path in recipe.tool_paths)
		var/found_this_tool = FALSE
		for(var/tool_path in available_tools)
			if(!ispath(tool_path, required_path))
				continue
			found_this_tool = TRUE
			break
		if(found_this_tool)
			continue
		return FALSE

	return TRUE


/datum/component/personal_crafting/proc/construct_item(atom/crafter, datum/crafting_recipe/recipe)
	if(!crafter)
		return ", unknown error!" // This should never happen, but in the event that it does...

	if(!recipe)
		return ", invalid recipe!" // This can happen, I can't really explain why, but it can. Better safe than sorry.

	var/list/contents = get_surroundings(crafter, recipe.blacklist)
	var/send_feedback = 1
	var/turf/dest_turf = get_turf(crafter)

	if(!check_contents(crafter, recipe, contents))
		return ", missing component."

	if(!check_tools(crafter, recipe, contents))
		return ", missing tool."

	var/considered_flags = recipe.crafting_flags & ~(ignored_flags)

	if((considered_flags & CRAFT_ONE_PER_TURF) && (locate(recipe.result) in dest_turf))
		return ", already one here!"

	if(considered_flags & CRAFT_CHECK_DIRECTION)
		if(!valid_build_direction(dest_turf, crafter.dir, is_fulltile = (considered_flags & CRAFT_IS_FULLTILE)))
			return ", won't fit here!"

	if(considered_flags & CRAFT_ON_SOLID_GROUND)
		if(isclosedturf(dest_turf))
			return ", cannot be made on a wall!"

		if(is_type_in_typecache(dest_turf, GLOB.turfs_without_ground))
			if(!locate(/obj/structure/thermoplastic) in dest_turf) // for tram construction
				return ", must be made on solid ground!"

	if(considered_flags & CRAFT_CHECK_DENSITY)
		for(var/obj/object in dest_turf)
			if(object.density && !(object.obj_flags & IGNORE_DENSITY) || object.obj_flags & BLOCKS_CONSTRUCTION)
				return ", something is in the way!"

	if(recipe.placement_checks & STACK_CHECK_CARDINALS)
		var/turf/nearby_turf
		for(var/direction in GLOB.cardinals)
			nearby_turf = get_step(dest_turf, direction)
			if(locate(recipe.result) in nearby_turf)
				to_chat(crafter, span_warning("\The [recipe.name] must not be built directly adjacent to another!"))
				return ", can't be adjacent to another!"

	if(recipe.placement_checks & STACK_CHECK_ADJACENT)
		if(locate(recipe.result) in range(1, dest_turf))
			return ", can't be near another!"

	if(recipe.placement_checks & STACK_CHECK_TRAM_FORBIDDEN)
		if(locate(/obj/structure/transport/linear/tram) in dest_turf || locate(/obj/structure/thermoplastic) in dest_turf)
			return ", can't be on tram!"

	if(recipe.placement_checks & STACK_CHECK_TRAM_EXCLUSIVE)
		if(!locate(/obj/structure/transport/linear/tram) in dest_turf)
			return ", must be made on a tram!"

	//If we're a mob we'll try a do_after; non mobs will instead instantly construct the item
	if(ismob(crafter) && !do_after(crafter, recipe.time, target = crafter))
		return "."
	contents = get_surroundings(crafter, recipe.blacklist)
	if(!check_contents(crafter, recipe, contents))
		return ", missing component."
	if(!check_tools(crafter, recipe, contents))
		return ", missing tool."
	var/list/parts = del_reqs(recipe, crafter)
	var/atom/movable/result
	if(ispath(recipe.result, /obj/item/stack))
		result = new recipe.result(get_turf(crafter.loc), recipe.result_amount || 1)
		result.dir = crafter.dir
	else
		result = new recipe.result(get_turf(crafter.loc))
		result.dir = crafter.dir
		if(result.atom_storage && recipe.delete_contents)
			for(var/obj/item/thing in result)
				qdel(thing)
	var/datum/reagents/holder = locate() in parts
	if(holder) //transfer reagents from ingredients to result
		if(!ispath(recipe.result, /obj/item/reagent_containers) && result.reagents)
			if(recipe.crafting_flags & CRAFT_CLEARS_REAGENTS)
				result.reagents.clear_reagents()
			if(recipe.crafting_flags & CRAFT_TRANSFERS_REAGENTS)
				holder.trans_to(result.reagents, holder.total_volume, no_react = TRUE)
		parts -= holder
		qdel(holder)
	result.CheckParts(parts, recipe)
	if(send_feedback)
		SSblackbox.record_feedback("tally", "object_crafted", 1, result.type)
	return result //Send the item back to whatever called this proc so it can handle whatever it wants to do with the new item

/*Del reqs works like this:

	Loop over reqs var of the recipe
	Set var amt to the value current cycle req is pointing to, its amount of type we need to delete
	Get var/surroundings list of things accessable to crafting by get_environment()
	Check the type of the current cycle req
		If its reagent then do a while loop, inside it try to locate() reagent containers, inside such containers try to locate needed reagent, if there isn't remove thing from surroundings
			If there is enough reagent in the search result then delete the needed amount, create the same type of reagent with the same data var and put it into deletion list
			If there isn't enough take all of that reagent from the container, put into deletion list, substract the amt var by the volume of reagent, remove the container from surroundings list and keep searching
			While doing above stuff check deletion list if it already has such reagnet, if yes merge instead of adding second one
		If its stack check if it has enough amount
			If yes create new stack with the needed amount and put in into deletion list, substract taken amount from the stack
			If no put all of the stack in the deletion list, substract its amount from amt and keep searching
			While doing above stuff check deletion list if it already has such stack type, if yes try to merge them instead of adding new one
		If its anything else just locate() in in the list in a while loop, each find --s the amt var and puts the found stuff in deletion loop

	Then do a loop over parts var of the recipe
		Do similar stuff to what we have done above, but now in deletion list, until the parts conditions are satisfied keep taking from the deletion list and putting it into parts list for return

	After its done loop over deletion list and delete all the shit that wasn't taken by parts loop

	del_reqs return the list of parts resulting object will receive as argument of CheckParts proc, on the atom level it will add them all to the contents, on all other levels it calls ..() and does whatever is needed afterwards but from contents list already
*/

/datum/component/personal_crafting/proc/del_reqs(datum/crafting_recipe/R, atom/a)
	. = list()

	var/datum/reagents/holder
	var/list/surroundings
	var/list/Deletion = list()
	var/amt
	var/list/requirements = list()
	if(R.reqs)
		requirements += R.reqs
	if(R.machinery)
		requirements += R.machinery
	if(R.structures)
		requirements += R.structures
	main_loop:
		for(var/path_key in requirements)
			amt = R.reqs?[path_key] || R.machinery?[path_key] || R.structures?[path_key]
			if(!amt)//since machinery & structures can have 0 aka CRAFTING_MACHINERY_USE - i.e. use it, don't consume it!
				continue main_loop
			surroundings = get_environment(a, R.blacklist)
			surroundings -= Deletion
			if(ispath(path_key, /datum/reagent))
				while(amt > 0)
					var/obj/item/reagent_containers/RC = locate() in surroundings
					if(isnull(RC)) //not found
						break
					if(QDELING(RC)) //deleting so is unusable
						surroundings -= RC
						continue

					var/reagent_volume = RC.reagents.get_reagent_amount(path_key)
					if(reagent_volume)
						if(!holder)
							holder = new(INFINITY, NO_REACT) //an infinite volume holder than can store reagents without reacting
							. += holder
						if(reagent_volume >= amt)
							RC.reagents.trans_to(holder, amt, target_id = path_key, no_react = TRUE)
							continue main_loop
						else
							RC.reagents.trans_to(holder, reagent_volume, target_id = path_key, no_react = TRUE)
							surroundings -= RC
							amt -= reagent_volume
					else
						surroundings -= RC
					RC.update_appearance(UPDATE_ICON)
			else if(ispath(path_key, /obj/item/stack))
				var/obj/item/stack/S
				var/obj/item/stack/SD
				while(amt > 0)
					S = locate(path_key) in surroundings
					if(S.amount >= amt)
						if(!locate(S.type) in Deletion)
							SD = new S.type()
							Deletion += SD
						S.use(amt)
						SD = SD || locate(S.type) in Deletion // SD might be already set here, no sense in searching for it again
						SD.amount += amt
						continue main_loop
					else
						amt -= S.amount
						if(!locate(S.type) in Deletion)
							Deletion += S
						else
							SD = SD || locate(S.type) in Deletion
							SD.add(S.amount) // add the amount to our tally stack, SD
							qdel(S) // We can just delete it straight away as it's going to be fully consumed anyway, saving some overhead from calling use()
						surroundings -= S
			else
				var/atom/movable/I
				while(amt > 0)
					I = locate(path_key) in surroundings
					Deletion += I
					surroundings -= I
					amt--
	var/list/partlist = list(R.parts.len)
	for(var/M in R.parts)
		partlist[M] = R.parts[M]
	for(var/part in R.parts)
		if(istype(part, /datum/reagent))
			var/datum/reagent/RG = locate(part) in Deletion
			if(RG.volume > partlist[part])
				RG.volume = partlist[part]
			. += RG
			Deletion -= RG
			continue
		else if(isstack(part))
			var/obj/item/stack/ST = locate(part) in Deletion
			if(ST.amount > partlist[part])
				ST.amount = partlist[part]
			. += ST
			Deletion -= ST
			continue
		else
			while(partlist[part] > 0)
				var/atom/movable/AM = locate(part) in Deletion
				. += AM
				Deletion -= AM
				partlist[part] -= 1
	while(Deletion.len)
		var/DL = Deletion[Deletion.len]
		Deletion.Cut(Deletion.len)
		// Snowflake handling of reagent containers, storage atoms, and structures with contents.
		// If we consumed them in our crafting, we should dump their contents out before qdeling them.
		if(is_reagent_container(DL))
			var/obj/item/reagent_containers/container = DL
			container.reagents.expose(container.loc, TOUCH)
		else if(istype(DL, /obj/item/storage))
			var/obj/item/storage/container = DL
			container.emptyStorage()
		else if(isstructure(DL))
			var/obj/structure/structure = DL
			structure.dump_contents(structure.drop_location())
		qdel(DL)

/datum/component/personal_crafting/proc/is_recipe_available(datum/crafting_recipe/recipe, mob/user)
	if((recipe.crafting_flags & CRAFT_MUST_BE_LEARNED) && !(recipe.type in user?.mind?.learned_recipes)) //User doesn't actually know how to make this.
		return FALSE
	if (recipe.category == CAT_CULT && !IS_CULTIST(user)) // Skip blood cult recipes if not cultist
		return FALSE
	return TRUE

/datum/component/personal_crafting/proc/component_ui_interact(atom/movable/screen/craft/image, location, control, params, user)
	SIGNAL_HANDLER

	if(user == parent)
		INVOKE_ASYNC(src, PROC_REF(ui_interact), user)

/datum/component/personal_crafting/ui_state(mob/user)
	return GLOB.not_incapacitated_turf_state

//For the UI related things we're going to assume the user is a mob rather than typesetting it to an atom as the UI isn't generated if the parent is an atom
/datum/component/personal_crafting/ui_interact(mob/user, datum/tgui/ui)
	ui = SStgui.try_update_ui(user, src, ui)
	if(!ui)
		ui = new(user, src, "PersonalCrafting", "Crafting")
		ui.open()

/datum/component/personal_crafting/ui_data(mob/user)
	var/list/data = list()
	data["busy"] = busy
	data["mode"] = mode
	data["display_craftable_only"] = display_craftable_only
	data["display_compact"] = display_compact

	var/list/surroundings = get_surroundings(user)
	var/list/craftability = list()
	for(var/datum/crafting_recipe/recipe as anything in (mode ? GLOB.cooking_recipes : GLOB.crafting_recipes))
		if(!is_recipe_available(recipe, user))
			continue
		if(check_contents(user, recipe, surroundings) && check_tools(user, recipe, surroundings))
			craftability["[REF(recipe)]"] = TRUE

	data["craftability"] = craftability
	return data

/datum/component/personal_crafting/ui_static_data(mob/user)
	var/list/data = list()
	var/list/material_occurences = list()

	data["forced_mode"] = forced_mode
	data["recipes"] = list()
	data["categories"] = list()
	data["foodtypes"] = FOOD_FLAGS

	if(user.has_dna())
		var/mob/living/carbon/carbon = user
		data["diet"] = carbon.dna.species.get_species_diet()

	for(var/datum/crafting_recipe/recipe as anything in (mode ? GLOB.cooking_recipes : GLOB.crafting_recipes))
		if(!is_recipe_available(recipe, user))
			continue

		if(recipe.category)
			data["categories"] |= recipe.category

		// Materials
		for(var/req in recipe.reqs)
			material_occurences[req] += 1
		for(var/req in recipe.chem_catalysts)
			material_occurences[req] += 1

		data["recipes"] += list(build_crafting_data(recipe))

	var/list/atoms = mode ? GLOB.cooking_recipes_atoms : GLOB.crafting_recipes_atoms

	// Prepare atom data

	//load sprite sheets and select the correct one based on the mode
	var/static/list/sprite_sheets
	if(isnull(sprite_sheets))
		sprite_sheets = ui_assets()
	var/datum/asset/spritesheet_batched/sheet = sprite_sheets[mode ? 2 : 1]

	data["icon_data"] = list()
	for(var/atom/atom as anything in atoms)
		var/atom_id = atoms.Find(atom)

		data["atom_data"] += list(list(
			"name" = initial(atom.name),
			"is_reagent" = ispath(atom, /datum/reagent/),
		))

		var/icon_size = sheet.icon_size_id("a[atom_id]")
		if(!endswith(icon_size, "32x32"))
			data["icon_data"]["[atom_id]"] = "[icon_size] a[atom_id]"

	// Prepare materials data
	for(var/atom/atom as anything in material_occurences)
		if(material_occurences[atom] == 1)
			continue // Don't include materials that appear only once
		var/id = atoms.Find(atom)
		data["material_occurences"] += list(list(
				"atom_id" = "[id]",
				"occurences" = material_occurences[atom]
			))

	return data

/datum/component/personal_crafting/proc/make_action(datum/crafting_recipe/recipe, mob/user)
	var/atom/movable/result = construct_item(user, recipe)
	if(istext(result)) //We failed to make an item and got a fail message
		to_chat(user, span_warning("Construction failed[result]"))
		return FALSE
	if(ismob(user) && isitem(result)) //In case the user is actually possessing a non mob like a machine
		user.put_in_hands(result)
	else if(!istype(result, /obj/effect/spawner))
		result.forceMove(user.drop_location())
	to_chat(user, span_notice("[recipe.name] crafted."))
	user.investigate_log("crafted [recipe]", INVESTIGATE_CRAFTING)
	recipe.on_craft_completion(user, result)
	return TRUE


/datum/component/personal_crafting/ui_act(action, list/params, datum/tgui/ui, datum/ui_state/state)
	. = ..()
	if(.)
		return
	switch(action)
		if("make", "make_mass")
			var/mob/user = usr
			var/datum/crafting_recipe/crafting_recipe = locate(params["recipe"]) in (mode ? GLOB.cooking_recipes : GLOB.crafting_recipes)
			busy = TRUE
			ui_interact(user)
			if(action == "make_mass")
				var/crafted_items = 0
				while(make_action(crafting_recipe, user))
					crafted_items++
				if(crafted_items)
					to_chat(user, span_notice("You made [crafted_items] item\s."))
			else
				make_action(crafting_recipe, user)
			busy = FALSE
		if("toggle_recipes")
			display_craftable_only = !display_craftable_only
			. = TRUE
		if("toggle_compact")
			display_compact = !display_compact
			. = TRUE
		if("toggle_mode")
			if(forced_mode)
				return
			mode = !mode
			var/mob/user = usr
			update_static_data(user)
			. = TRUE

/datum/component/personal_crafting/ui_assets(mob/user)
	return list(
		get_asset_datum(/datum/asset/spritesheet_batched/crafting),
		get_asset_datum(/datum/asset/spritesheet_batched/crafting/cooking),
	)

/datum/component/personal_crafting/proc/build_crafting_data(datum/crafting_recipe/recipe)
	var/list/data = list()
	var/list/atoms = mode ? GLOB.cooking_recipes_atoms : GLOB.crafting_recipes_atoms

	data["ref"] = "[REF(recipe)]"
	var/atom/atom = recipe.result

	data["id"] = atoms.Find(atom)

	var/recipe_data = recipe.crafting_ui_data()
	for(var/new_data in recipe_data)
		data[new_data] = recipe_data[new_data]

	// Category
	data["category"] = recipe.category

	// Name, Description
	data["name"] = recipe.name

	if(ispath(recipe.result, /datum/reagent))
		var/datum/reagent/reagent = recipe.result
		if(recipe.result_amount > 1)
			data["name"] = "[data["name"]] [recipe.result_amount]u"
		data["desc"] = recipe.desc || initial(reagent.description)

	else if(ispath(recipe.result, /obj/item/pipe))
		var/obj/item/pipe/pipe_obj = recipe.result
		var/obj/pipe_real = initial(pipe_obj.pipe_type)
		data["desc"] = recipe.desc || initial(pipe_real.desc)

	else
		if(ispath(recipe.result, /obj/item/stack) && recipe.result_amount > 1)
			data["name"] = "[data["name"]] [recipe.result_amount]x"
		data["desc"] = recipe.desc || initial(atom.desc)

	if(ispath(recipe.result, /obj/item/food))
		var/obj/item/food/food = recipe.result
		data["has_food_effect"] = !!food.crafted_food_buff

	// Crafting
	if(recipe.non_craftable)
		data["non_craftable"] = recipe.non_craftable
	data["mass_craftable"] = recipe.mass_craftable
	if(recipe.steps)
		data["steps"] = recipe.steps

	// Tools
	if(recipe.tool_behaviors)
		data["tool_behaviors"] = recipe.tool_behaviors
	if(recipe.tool_paths)
		data["tool_paths"] = list()
		for(var/req_atom in recipe.tool_paths)
			data["tool_paths"] += atoms.Find(req_atom)

	// Machinery
	if(recipe.machinery)
		data["machinery"] = list()
		for(var/req_atom in recipe.machinery)
			data["machinery"] += atoms.Find(req_atom)

	// Structures
	if(recipe.structures)
		data["structures"] = list()
		for(var/req_atom in recipe.structures)
			data["structures"] += atoms.Find(req_atom)

	// Ingredients / Materials
	if(recipe.reqs.len)
		data["reqs"] = list()
		for(var/req_atom in recipe.reqs)
			var/id = atoms.Find(req_atom)
			data["reqs"]["[id]"] = recipe.reqs[req_atom]

	// Catalysts
	if(recipe.chem_catalysts.len)
		data["chem_catalysts"] = list()
		for(var/req_atom in recipe.chem_catalysts)
			var/id = atoms.Find(req_atom)
			data["chem_catalysts"]["[id]"] = recipe.chem_catalysts[req_atom]

	// Reaction data
	if(ispath(recipe.reaction))
		data["is_reaction"] = TRUE
		// May be called before chemical reactions list is setup
		var/datum/chemical_reaction/reaction = GLOB.chemical_reactions_list[recipe.reaction] || new recipe.reaction()
		if(istype(reaction))
			if(!data["steps"])
				data["steps"] = list()
			if(reaction.required_container)
				var/id = atoms.Find(reaction.required_container)
				data["reqs"]["[id]"] = 1
				data["steps"] += "Add all ingredients into \a [initial(reaction.required_container.name)]"
			else if(length(recipe.reqs) > 1 || length(reaction.required_catalysts))
				data["steps"] += "Mix all ingredients together"
			if(reaction.required_temp > T20C)
				data["steps"] += "Heat up to [reaction.required_temp]K"
		else
			stack_trace("Invalid reaction found in recipe code! ([recipe.reaction])")
	else if(!isnull(recipe.reaction))
		stack_trace("Invalid reaction found in recipe code! ([recipe.reaction])")

	return data

#undef COOKING
#undef CRAFTING

//Mind helpers

/// proc that teaches user a non-standard crafting recipe
/datum/mind/proc/teach_crafting_recipe(recipe)
	if(!learned_recipes)
		learned_recipes = list()
	learned_recipes |= recipe

/// proc that makes user forget a specific crafting recipe
/datum/mind/proc/forget_crafting_recipe(recipe)
	learned_recipes -= recipe

/datum/mind/proc/has_crafting_recipe(mob/user, potential_recipe)
	if(!learned_recipes)
		return FALSE
	if(!ispath(potential_recipe, /datum/crafting_recipe))
		CRASH("Non-crafting recipe passed to has_crafting_recipe")
	for(var/recipe in user.mind.learned_recipes)
		if(recipe == potential_recipe)
			return TRUE
	return FALSE

/datum/component/personal_crafting/machine
	ignored_flags = CRAFT_CHECK_DENSITY

/datum/component/personal_crafting/machine/get_environment(atom/crafter, list/blacklist = null, radius_range = 1)
	. = list()
	var/turf/crafter_loc = get_turf(crafter)
	for(var/atom/movable/content as anything in crafter_loc.contents)
		if((content.flags_1 & HOLOGRAM_1) || (blacklist && (content.type in blacklist)))
			continue
		if(isitem(content))
			var/obj/item/item = content
			if(item.item_flags & ABSTRACT) //let's not tempt fate, shall we?
				continue
		. += content

/datum/component/personal_crafting/machine/check_tools(atom/source, datum/crafting_recipe/recipe, list/surroundings)
	return TRUE
