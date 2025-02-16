/datum/crafting_recipe
	/// in-game display name
	/// Optional, if not set uses result name
	var/name
	/// description displayed in game
	/// Optional, if not set uses result desc
	var/desc
	///type paths of items consumed associated with how many are needed
	var/list/reqs = list()
	///type paths of items explicitly not allowed as an ingredient
	var/list/blacklist = list()
	///type path of item resulting from this craft
	var/result
	/// String defines of items needed but not consumed. Lazy list.
	var/list/tool_behaviors
	/// Type paths of items needed but not consumed. Lazy list.
	var/list/tool_paths
	///time in seconds. Remember to use the SECONDS define!
	var/time = 3 SECONDS
	///type paths of items that will be forceMoved() into the result instead of being deleted
	var/list/parts = list()
	///items, structures and machineries of types that are in this list won't transfer their materials to the result
	var/list/requirements_mats_blacklist
	///like tool_behaviors but for reagents
	var/list/chem_catalysts = list()
	///where it shows up in the crafting UI
	var/category
	///Required machines for the craft, set the assigned value of the typepath to CRAFTING_MACHINERY_CONSUME or CRAFTING_MACHINERY_USE. Lazy associative list: type_path key -> flag value.
	var/list/machinery
	///Required structures for the craft, set the assigned value of the typepath to CRAFTING_STRUCTURE_CONSUME or CRAFTING_STRUCTURE_USE. Lazy associative list: type_path key -> flag value.
	var/list/structures
	/// Bitflag of additional placement checks required to place. (STACK_CHECK_CARDINALS|STACK_CHECK_ADJACENT|STACK_CHECK_TRAM_FORBIDDEN|STACK_CHECK_TRAM_EXCLUSIVE)
	var/placement_checks = NONE
	/// Steps needed to achieve the result
	var/list/steps
	/// Whether the result can be crafted with a crafting menu button
	var/non_craftable
	/// Chemical reaction described in the recipe
	var/datum/chemical_reaction/reaction
	/// Resulting amount (for stacks only)
	var/result_amount
	/// Whether we should delete the contents of the crafted storage item (Only works with storage items, used for ammo boxes, donut boxes, internals boxes, etc)
	var/delete_contents = TRUE
	/// Allows you to craft so that you don't have to click the craft button many times.
	var/mass_craftable = FALSE

	///crafting_flags var to hold bool values
	var/crafting_flags = CRAFT_CHECK_DENSITY

/datum/crafting_recipe/New()
	if(!name && result)
		var/atom/atom_result = result
		name = initial(atom_result.name)

	if(!(result in reqs))
		blacklist += result
	// These should be excluded from all crafting recipies
	blacklist += list(
		/obj/item/cautery/augment,
		/obj/item/circular_saw/augment,
		/obj/item/crowbar/cyborg,
		/obj/item/hemostat/augment,
		/obj/item/multitool/cyborg,
		/obj/item/retractor/augment,
		/obj/item/scalpel/augment,
		/obj/item/screwdriver/cyborg,
		/obj/item/surgicaldrill/augment,
		/obj/item/weldingtool/largetank/cyborg,
		/obj/item/wirecutters/cyborg,
		/obj/item/wrench/cyborg,
	)
	if(tool_behaviors)
		tool_behaviors = string_list(tool_behaviors)
	if(tool_paths)
		tool_paths = string_list(tool_paths)
	for(var/key in parts)
		if(!parts[key])
			//ensure every unit of the part used for the recipe will be transferred if the value is otherwise not specified
			parts[key] = INFINITY

/datum/crafting_recipe/stack/New(obj/item/stack/material, datum/stack_recipe/stack_recipe)
	if(!material || !stack_recipe || !stack_recipe.result_type)
		stack_trace("Invalid stack recipe [stack_recipe]")
		return
	..()

	src.name = stack_recipe.title
	src.time = stack_recipe.time
	src.result = stack_recipe.result_type
	src.result_amount = stack_recipe.res_amount
	src.reqs[material] = stack_recipe.req_amount
	src.category = stack_recipe.category || CAT_MISC
	src.placement_checks = stack_recipe.placement_checks

	if(!(stack_recipe.crafting_flags & CRAFT_APPLIES_MATS))
		requirements_mats_blacklist = list(material) //the item is not intended to have mats :shrug:

/**
 * Run custom pre-craft checks for this recipe, don't add feedback messages in this because it will spam the client
 *
 * user: The /mob that initiated the crafting
 * collected_requirements: A list of lists of /obj/item instances that satisfy reqs. Top level list is keyed by requirement path.
 */
/datum/crafting_recipe/proc/check_requirements(mob/user, list/collected_requirements)
	return TRUE

///Check if the pipe used for atmospheric device crafting is the proper one
/datum/crafting_recipe/proc/atmos_pipe_check(mob/user, list/collected_requirements)
	var/obj/item/pipe/required_pipe = collected_requirements[/obj/item/pipe][1]
	if(ispath(required_pipe.pipe_type, /obj/machinery/atmospherics/pipe/smart))
		return TRUE
	return FALSE

/// Additional UI data to be passed to the crafting UI for this recipe
/datum/crafting_recipe/proc/crafting_ui_data()
	return list()
