/**
 * Check if a generic atom (because both mobs and the crafter machinery can do it) can potentially craft all recipes,
 * with the exact same types required in the recipe, and also compare the materials of crafted result with one of the same type
 * to ansure they match if the recipe has the CRAFT_ENFORCE_MATERIALS_PARITY flag.
 */
/datum/unit_test/crafting

/datum/unit_test/crafting/Run()
	var/static/list/blacklisted_recipes = list()

	var/atom/movable/crafter = allocate(__IMPLIED_TYPE__)
	var/turf/turf = crafter.loc
	var/old_turf_type = turf.type
	var/datum/component/personal_crafting/unit_test/craft_comp = crafter.AddComponent(__IMPLIED_TYPE__)
	var/obj/item/reagent_containers/cup/bottomless_cup = allocate_bottomless_cup()

	var/list/tools = list()

	for(var/datum/crafting_recipe/recipe as anything in GLOB.crafting_recipes)
		if(recipe.type in blacklisted_recipes)
			continue
		//split into a different proc, so if something fails it's both easier to track and doesn't halt the loop.
		process_recipe(crafter, craft_comp, recipe, bottomless_cup, tools)
		if(QDELETED(bottomless_cup) || bottomless_cup.loc != turf) //The cup itself was used in a recipe, rather than its contents.
			bottomless_cup = allocate_bottomless_cup()

	// We have one or two recipes that generate turf (from stacks, like snow walls), which shouldn't be carried between tests
	if(turf.type != old_turf_type)
		turf.ChangeTurf(old_turf_type)

///Allocate a reagent container with infinite capacity and no reaction to use in crafting
/datum/unit_test/crafting/proc/allocate_bottomless_cup()
	var/obj/item/reagent_containers/cup/bottomless_cup = allocate(__IMPLIED_TYPE__)
	bottomless_cup.reagents.flags |= NO_REACT|DRAINABLE
	bottomless_cup.reagents.maximum_volume = INFINITY
	return bottomless_cup

/datum/unit_test/crafting/proc/process_recipe(
	atom/crafter,
	datum/component/personal_crafting/unit_test/craft_comp,
	datum/crafting_recipe/recipe,
	obj/item/reagent_containers/bottomless_cup,
	list/tools
)
	var/turf/turf = crafter.loc
	for(var/req_path in recipe.reqs) //allocate items and reagents
		var/amount = recipe.reqs[req_path]

		if(ispath(req_path, /datum/reagent)) //it's a reagent
			if(!bottomless_cup.reagents.has_reagent(req_path, amount))
				bottomless_cup.reagents.add_reagent(req_path, amount + 1, no_react = TRUE)
			continue

		//it's a stack
		if(ispath(req_path, /obj/item/stack))
			var/obj/item/stack/stack = locate(req_path) in turf
			if(QDELETED(stack) || (stack.type in recipe.blacklist) || stack.amount < amount)
				allocate(req_path, turf, /*new_amount =*/ amount, /*merge =*/ FALSE)
			continue
		//it's any other item
		var/matches = 0
		for(var/atom/movable/movable as anything in turf)
			if(!QDELING(movable) && istype(movable, req_path) && !(movable.type in recipe.blacklist))
				matches++
		var/to_spawn = amount - matches
		for(var/iteration in 1 to to_spawn)
			allocate(req_path)

	for(var/req_path in recipe.chem_catalysts) // allocate catalysts
		var/amount = recipe.chem_catalysts[req_path]
		if(!bottomless_cup.reagents.has_reagent(req_path, amount))
			bottomless_cup.reagents.add_reagent(req_path, amount + 1, no_react = TRUE)

	var/list/bulky_objects = list()
	bulky_objects += recipe.structures + recipe.machinery //either structures and machinery could be null
	list_clear_nulls(bulky_objects) //so we clear the list
	for(var/req_path in bulky_objects) //allocate required machinery or structures
		var/atom/located = locate(req_path) in turf
		if(QDELETED(located))
			allocate(req_path)

	var/list/needed_tools = list()
	needed_tools += recipe.tool_behaviors + recipe.tool_paths //either tool_behaviors and tool_paths could be null
	list_clear_nulls(needed_tools) //so we clear the list
	for(var/tooltype in needed_tools)
		var/atom/tool = tools[tooltype]
		if(!QDELETED(tool) && tool.loc == turf)
			continue
		var/is_behaviour = istext(tooltype)
		var/obj/item/new_tool = allocate(is_behaviour ? /obj/item : tooltype)
		if(is_behaviour)
			new_tool.tool_behaviour = tooltype
		tools[tooltype] = new_tool

	var/atom/result = craft_comp.construct_item(crafter, recipe)
	if(istext(result) || isnull(result)) //construct_item() returned a text string telling us why it failed.
		TEST_FAIL("[recipe.type] couldn't be crafted during unit test[result || ", result is null for some reason!"]")
		return
	//enforcing materials parity between crafted and spawned for turfs would be more trouble than worth right now
	if(isturf(result))
		return

	allocated += result

	if(!(recipe.crafting_flags & CRAFT_ENFORCE_MATERIALS_PARITY))
		return

	var/atom/copycat = allocate(result.type)
	// SSmaterials caches the combinations so we don't have to run more complex checks
	if(result.custom_materials == copycat.custom_materials)
		return
	var/warning = "custom_materials of [result.type] when crafted and spawned don't match."
	var/what_it_should_be = "null"
	if(result.custom_materials) //compose a text string containing the syntax and paths to use for editing the custom_materials var
		what_it_should_be = "list("
		var/index = 1
		var/mats_len = length(result.custom_materials)
		for(var/datum/material/mat as anything in result.custom_materials)
			what_it_should_be += "[mat.type] = [result.custom_materials[mat]]"
			if(index < mats_len)
				what_it_should_be += ", "
			index++
		what_it_should_be += ")"
	TEST_FAIL("[warning] Set custom_materials to \[[what_it_should_be]\] or blacklist [recipe.type] in the unit test")

/datum/component/personal_crafting/unit_test
	ignored_flags = CRAFT_MUST_BE_LEARNED|CRAFT_ONE_PER_TURF|CRAFT_CHECK_DIRECTION|CRAFT_CHECK_DENSITY|CRAFT_ON_SOLID_GROUND
