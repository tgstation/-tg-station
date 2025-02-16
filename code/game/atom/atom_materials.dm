/atom
	///The custom materials this atom is made of, used by a lot of things like furniture, walls, and floors (if I finish the functionality, that is.)
	///The list referenced by this var can be shared by multiple objects and should not be directly modified. Instead, use [set_custom_materials][/atom/proc/set_custom_materials].
	var/list/datum/material/custom_materials
	///Bitfield for how the atom handles materials.
	var/material_flags = NONE
	///Modifier that raises/lowers the effect of the amount of a material, prevents small and easy to get items from being death machines.
	var/material_modifier = 1

/// Sets the custom materials for an atom. This is what you want to call, since most of the ones below are mainly internal.
/atom/proc/set_custom_materials(list/materials, multiplier = 1)
	SHOULD_NOT_OVERRIDE(TRUE)
	var/replace_mats = length(materials)
	if(length(custom_materials))
		remove_material_effects(replace_mats)

	if(!replace_mats)
		return

	initialize_materials(materials, multiplier)

/**
 * The second part of set_custom_materials(), which handles applying the new materials
 * It is a separate proc because Initialize calls may make use of this since they should've no prior materials to remove.
 */
/atom/proc/initialize_materials(list/materials, multiplier = 1)
	SHOULD_NOT_OVERRIDE(TRUE)
	if(multiplier != 1)
		materials = materials.Copy() //avoid editing the list that was originally used as argument if it's ever going to be used again.
		for(var/current_material in materials)
			materials[current_material] *= multiplier

	apply_material_effects(materials)

///proc responsible for applying material effects when setting materials.
/atom/proc/apply_material_effects(list/materials)
	SHOULD_CALL_PARENT(TRUE)
	if(material_flags & MATERIAL_EFFECTS)
		var/list/material_effects = get_material_effects_list(materials)
		finalize_material_effects(material_effects)

	custom_materials = SSmaterials.FindOrCreateMaterialCombo(materials)

/// Proc responsible for removing material effects when setting materials.
/atom/proc/remove_material_effects(replace_mats = TRUE)
	SHOULD_CALL_PARENT(TRUE)
	//Only runs if custom materials existed at first and affected src.
	if(material_flags & MATERIAL_EFFECTS)
		var/list/material_effects = get_material_effects_list(custom_materials)
		finalize_remove_material_effects(material_effects)

	if(!replace_mats)
		custom_materials = null

/atom/proc/get_material_effects_list(list/materials)
	SHOULD_NOT_OVERRIDE(TRUE)
	PRIVATE_PROC(TRUE)
	var/list/material_effects = list()
	var/index = 1
	for(var/current_material in materials)
		var/datum/material/material = GET_MATERIAL_REF(current_material)
		material_effects[material] = list(
			MATERIAL_LIST_OPTIMAL_AMOUNT = OPTIMAL_COST(materials[current_material] * material_modifier),
			MATERIAL_LIST_MULTIPLIER = get_material_multiplier(material, materials, index),
		)
		index++
	sortTim(material_effects, GLOBAL_PROC_REF(cmp_mat_composition), associative = TRUE)
	return material_effects

/**
 * A proc that can be used to selectively control the stat changes and effects from a material without affecting the others.
 *
 * For example, we can have items made of two different materials, with the primary contributing a good 1.2 multiplier
 * and the second a meager 0.3.
 *
 * The GET_MATERIAL_MODIFIER macro will handles some modifications where the minimum should be 1 if above 1 and the maximum
 * be 1 if below 1. Just don't return negative values.
 */
/atom/proc/get_material_multiplier(datum/material/custom_material, list/materials, index)
	return 1/length(materials)

///Called by apply_material_effects(). It ACTUALLY handles applying effects common to all atoms (depending on material flags)
/atom/proc/finalize_material_effects(list/materials)
	SHOULD_CALL_PARENT(TRUE)
	var/total_alpha = 0
	var/list/colors = list()
	var/mat_length = length(materials)
	var/datum/material/main_material = materials[1]//the material with the highest amount (after calculations)
	var/main_mat_amount = materials[main_material][MATERIAL_LIST_OPTIMAL_AMOUNT]
	var/main_mat_mult = materials[main_material][MATERIAL_LIST_MULTIPLIER]
	for(var/datum/material/custom_material as anything in materials)
		var/list/deets = materials[custom_material]
		var/mat_amount = deets[MATERIAL_LIST_OPTIMAL_AMOUNT]
		var/multiplier = deets[MATERIAL_LIST_MULTIPLIER]

		apply_single_mat_effect(custom_material, mat_amount, multiplier)
		custom_material.on_applied(src, mat_amount, multiplier)

		//Prevent changing things with pre-set colors, to keep colored toolboxes their looks for example
		if(material_flags & (MATERIAL_COLOR|MATERIAL_GREYSCALE))
			gather_material_color(custom_material, colors, mat_amount, multicolor = mat_length > 1)
			var/added_alpha = custom_material.alpha * (custom_material.alpha / 255)
			total_alpha += GET_MATERIAL_MODIFIER(added_alpha, multiplier)
		if(custom_material.beauty_modifier)
			AddElement(/datum/element/beauty, custom_material.beauty_modifier * mat_amount)

	apply_main_material_effects(main_material, main_mat_amount, main_mat_mult)

	if(material_flags & (MATERIAL_COLOR|MATERIAL_GREYSCALE))
		var/previous_alpha = alpha
		alpha *= (total_alpha / length(materials))/255

		if(alpha < previous_alpha * 0.9)
			opacity = FALSE

		if(material_flags & MATERIAL_GREYSCALE)
			var/config_path = get_material_greyscale_config(main_material.type, greyscale_config)
			//Make sure that we've no less than the expected amount
			//expected_colors is zero for paths, the value is assigned when reading the json files.
			var/datum/greyscale_config/config = SSgreyscale.configurations["[config_path || greyscale_config]"]
			var/colors_len = length(colors)
			if(config.expected_colors > colors_len)
				var/list/filled_colors = colors.Copy()
				for(var/index in colors_len to config.expected_colors - 1)
					filled_colors += pick(colors)
				colors = filled_colors
			set_greyscale(colors, config_path)
		else if(length(colors))
			mix_material_colors(colors)

	if(material_flags & MATERIAL_ADD_PREFIX)
		var/prefixes = get_material_prefixes(materials)
		name = "[prefixes] [name]"

/**
 * A proc used by both finalize_material_effects() and finalize_remove_material_effects() to get the colors
 * that will later be applied to or removed from the atom
 */
/atom/proc/gather_material_color(datum/material/material, list/colors, amount, multicolor = FALSE)
	SHOULD_CALL_PARENT(TRUE)
	if(!material.color) //the material has no color. Nevermind
		return
	var/color_to_add = material.color
	var/istext = istext(color_to_add)
	if(istext)
		if(material.alpha != 255)
			color_to_add += num2hex(material.alpha, 2)
	else
		if(multicolor || material_flags & MATERIAL_GREYSCALE)
			color_to_add = material.greyscale_color || color_matrix2color_hex(material.color)
			if(material.greyscale_color)
				color_to_add += num2hex(material.alpha, 2)
		else
			color_to_add = color_to_full_rgba_matrix(color_to_add)
			color_to_add[20] *= (material.alpha / 255) // multiply the constant alpha of the color matrix

	colors[color_to_add] += amount

/// Manages mixing, adding or removing the material colors from the atom in absence of the MATERIAL_GREYSCALE flag.
/atom/proc/mix_material_colors(list/colors, remove = FALSE)
	SHOULD_NOT_OVERRIDE(TRUE)
	var/color_len = length(colors)
	if(!color_len)
		return
	var/mixcolor = colors[1]
	var/amount_divisor = colors[mixcolor]
	for(var/i in 2 to length(colors))
		var/color_to_add = colors[i]
		if(islist(color_to_add))
			color_to_add = color_matrix2color_hex(color_to_add)
		var/mix_amount = colors[color_to_add]
		amount_divisor += mix_amount
		mixcolor = BlendRGB(mixcolor, color_to_add, mix_amount/amount_divisor)
	if(remove)
		remove_atom_colour(FIXED_COLOUR_PRIORITY, mixcolor)
	else
		add_atom_colour(mixcolor, FIXED_COLOUR_PRIORITY)

///Returns the prefixes to attach to the atom when setting materials, from a list argument.
/atom/proc/get_material_prefixes(list/materials)
	var/list/mat_names = list()
	for(var/datum/material/material as anything in materials)
		mat_names |= material.name
	return mat_names.Join("-")

///Returns a string like "plasma, paper and glass" from a list of materials
/atom/proc/get_material_english_list(list/materials)
	var/list/mat_names = list()
	for(var/datum/material/material as anything in materials)
		mat_names += material.name
	return english_list(mat_names)

///Searches for a subtype of config_type that is to be used in its place for specific materials (like shimmering gold for cleric maces)
/atom/proc/get_material_greyscale_config(mat_type, config_type)
	SHOULD_NOT_OVERRIDE(TRUE)
	if(!config_type)
		return
	for(var/datum/greyscale_config/path as anything in subtypesof(config_type))
		if(mat_type != initial(path.material_skin))
			continue
		return path

///Apply material effects of a single material.
/atom/proc/apply_single_mat_effect(datum/material/custom_material, amount, multipier)
	SHOULD_CALL_PARENT(TRUE)
	return

///A proc for material effects that only the main material (which the atom's primarly composed of) should apply.
/atom/proc/apply_main_material_effects(datum/material/main_material, amount, multipier)
	SHOULD_CALL_PARENT(TRUE)
	if(main_material.texture_layer_icon_state && material_flags & MATERIAL_COLOR)
		ADD_KEEP_TOGETHER(src, MATERIAL_SOURCE(main_material))
		add_filter("material_texture_[main_material.name]", 1, layering_filter(icon = main_material.cached_texture_filter_icon, blend_mode = BLEND_INSET_OVERLAY))

	main_material.on_main_applied(src, amount, multipier)

///Called by remove_material_effects(). It ACTUALLY handles removing effects common to all atoms (depending on material flags)
/atom/proc/finalize_remove_material_effects(list/materials)
	var/list/colors = list()
	var/datum/material/main_material = get_master_material()
	var/mat_length = length(materials)
	var/main_mat_amount
	var/main_mat_mult
	for(var/datum/material/custom_material as anything in materials)
		var/list/deets = materials[custom_material]
		var/mat_amount = deets[MATERIAL_LIST_OPTIMAL_AMOUNT]
		var/multiplier = deets[MATERIAL_LIST_MULTIPLIER]
		if(custom_material == main_material)
			main_mat_amount = mat_amount
			main_mat_mult = multiplier

		remove_single_mat_effect(custom_material, mat_amount, multiplier)
		custom_material.on_removed(src, mat_amount, multiplier)
		if(material_flags & MATERIAL_COLOR)
			gather_material_color(custom_material, colors, mat_amount, multicolor = mat_length > 1)
		if(custom_material.beauty_modifier)
			RemoveElement(/datum/element/beauty, custom_material.beauty_modifier * mat_amount)

	remove_main_material_effects(main_material, main_mat_amount, main_mat_mult)

	if(material_flags & (MATERIAL_GREYSCALE|MATERIAL_COLOR))
		if(material_flags & MATERIAL_COLOR)
			mix_material_colors(colors, remove = TRUE)
		else
			set_greyscale(initial(greyscale_colors), initial(greyscale_config))
		alpha = initial(alpha)
		opacity = initial(opacity)

	if(material_flags & MATERIAL_ADD_PREFIX)
		name = initial(name)

///Remove material effects of a single material.
/atom/proc/remove_single_mat_effect(datum/material/custom_material, amount, multipier)
	SHOULD_CALL_PARENT(TRUE)
	return

///A proc to remove the material effects previously applied by the (ex-)main material
/atom/proc/remove_main_material_effects(datum/material/main_material, amount, multipier)
	SHOULD_CALL_PARENT(TRUE)
	if(main_material.texture_layer_icon_state)
		remove_filter("material_texture_[main_material.name]")
		REMOVE_KEEP_TOGETHER(src, MATERIAL_SOURCE(main_material))
	main_material.on_main_removed(src, amount, multipier)

///Remove the old effects, change the material_modifier variable, and then reapply all the effects.
/atom/proc/change_material_modifier(new_value)
	SHOULD_NOT_OVERRIDE(TRUE)
	remove_material_effects()
	material_modifier = new_value
	apply_material_effects(custom_materials)

///For enabling and disabling material effects from an item (mainly VV)
/atom/proc/toggle_material_flags(new_flags)
	SHOULD_NOT_OVERRIDE(TRUE)
	if(material_flags & MATERIAL_EFFECTS && !(new_flags & MATERIAL_EFFECTS))
		remove_material_effects()
	else if(!(material_flags & MATERIAL_EFFECTS) && new_flags & MATERIAL_EFFECTS)
		apply_material_effects()
	material_flags = new_flags

/**
 * Returns the material composition of the atom.
 *
 * Used when recycling items, specifically to turn alloys back into their component mats.
 *
 * Exists because I'd need to add a way to un-alloy alloys or otherwise deal
 * with people converting the entire stations material supply into alloys.
 *
 * Arguments:
 * - flags: A set of flags determining how exactly the materials are broken down.
 */
/atom/proc/get_material_composition()
	. = list()

	var/list/cached_materials = custom_materials
	for(var/mat in cached_materials)
		var/datum/material/material = GET_MATERIAL_REF(mat)
		var/list/material_comp = material.return_composition(cached_materials[mat])
		for(var/comp_mat in material_comp)
			.[comp_mat] += material_comp[comp_mat]

/**
 * Fetches a list of all of the materials this object has of the desired type. Returns null if there is no valid materials of the type
 *
 * Arguments:
 * - [required_material][/datum/material]: The type of material we are checking for
 * - mat_amount: The minimum required amount of material
 */
/atom/proc/has_material_type(datum/material/required_material, mat_amount = 0)
	var/list/cached_materials = custom_materials
	if(!length(cached_materials))
		return null

	var/materials_of_type
	for(var/current_material in cached_materials)
		if(cached_materials[current_material] < mat_amount)
			continue
		var/datum/material/material = GET_MATERIAL_REF(current_material)
		if(!istype(material, required_material))
			continue
		LAZYSET(materials_of_type, material, cached_materials[current_material])

	return materials_of_type

/**
 * Fetches a list of all of the materials this object has with the desired material category.
 *
 * Arguments:
 * - category: The category to check for
 * - any_flags: Any bitflags that must be present for the category
 * - all_flags: All bitflags that must be present for the category
 * - no_flags: Any bitflags that must not be present for the category
 * - mat_amount: The minimum amount of materials that must be present
 */
/atom/proc/has_material_category(category, any_flags=0, all_flags=0, no_flags=0, mat_amount=0)
	var/list/cached_materials = custom_materials
	if(!length(cached_materials))
		return null

	var/materials_of_category
	for(var/current_material in cached_materials)
		if(cached_materials[current_material] < mat_amount)
			continue
		var/datum/material/material = GET_MATERIAL_REF(current_material)
		var/category_flags = material?.categories[category]
		if(isnull(category_flags))
			continue
		if(any_flags && !(category_flags & any_flags))
			continue
		if(all_flags && (all_flags != (category_flags & all_flags)))
			continue
		if(no_flags && (category_flags & no_flags))
			continue
		LAZYSET(materials_of_category, material, cached_materials[current_material])
	return materials_of_category

/**
 * Gets the most common material in the object.
 */
/atom/proc/get_master_material()
	var/list/cached_materials = custom_materials
	if(!length(cached_materials))
		return null

	var/most_common_material = null
	var/max_amount = 0
	for(var/material in cached_materials)
		if(cached_materials[material] > max_amount)
			most_common_material = material
			max_amount = cached_materials[material]

	if(most_common_material)
		return GET_MATERIAL_REF(most_common_material)

/**
 * Gets the total amount of materials in this atom.
 */
/atom/proc/get_custom_material_amount()
	return isnull(custom_materials) ? 0 : counterlist_sum(custom_materials)
