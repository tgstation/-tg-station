/**
 * # Custom Atom Component
 *
 * When added to an atom, item ingredients can be put into that.
 * The sprite is updated and reagents and custom materials are transferred.
 *
 * If the component is added to something that is processed, creating new objects (being cut, for example),
 * the replacement type needs to also have the component. The ingredients will be copied over. Reagents are not
 * copied over since other components already take care of that.
 */
/datum/component/ingredients_holder
	can_transfer = TRUE
	///List of item ingredients.
	var/list/obj/item/ingredients
	///Type path of replacement atom.
	var/replacement
	///Stores a copy of the list of materials that composed the base when ingredients were first added
	var/list/base_materials
	///Type of fill, can be [CUSTOM_INGREDIENT_ICON_NOCHANGE] for example.
	var/fill_type
	///Number of max ingredients.
	var/max_ingredients
	///Overlay used for certain fill types, always shows up on top.
	var/mutable_appearance/top_overlay
	///Type of ingredients to accept, [CUSTOM_INGREDIENT_TYPE_EDIBLE] for example.
	var/ingredient_type
	/// Adds screentips for all items that call on this proc, defaults to "Add"
	var/screentip_verb

	/// Stores the names of the ingredients of the holder, useful for processed results which cannot withhold refs for GC reasons.
	var/list/ingredient_names

/datum/component/ingredients_holder/Initialize(
		atom/replacement,
		fill_type,
		ingredient_type = CUSTOM_INGREDIENT_TYPE_EDIBLE,
		max_ingredients = MAX_ATOM_OVERLAYS - 3, // The cap is >= MAX_ATOM_OVERLAYS so we reserve 2 for top /bottom of item + 1 to stay under cap
		datum/component/ingredients_holder/processed_holder, //when processing a holder, the results receive their own comps, but need the ingredient names and filling passed down
		screentip_verb = "Add",
)
	if(!isatom(parent))
		return COMPONENT_INCOMPATIBLE
	var/atom/atom_parent = parent
	// assume replacement is OK
	if (!atom_parent.reagents && !replacement)
		return COMPONENT_INCOMPATIBLE

	atom_parent.flags_1 |= HAS_CONTEXTUAL_SCREENTIPS_1

	src.replacement = replacement
	src.fill_type = fill_type
	src.max_ingredients = max_ingredients
	src.ingredient_type = ingredient_type
	src.screentip_verb = screentip_verb

	if(processed_holder)
		src.ingredient_names = processed_holder.ingredient_names
		for(var/obj/item/ingredient as anything in processed_holder.ingredients)
			handle_fill(ingredient)

/datum/component/ingredients_holder/Destroy(force)
	QDEL_NULL(top_overlay)
	LAZYCLEARLIST(ingredients)
	base_materials = null
	return ..()

/datum/component/ingredients_holder/RegisterWithParent()
	. = ..()
	RegisterSignal(parent, COMSIG_ATOM_ATTACKBY, PROC_REF(customizable_attack))
	RegisterSignal(parent, COMSIG_ATOM_EXAMINE, PROC_REF(on_examine))
	RegisterSignal(parent, COMSIG_ATOM_EXITED, PROC_REF(food_exited))
	RegisterSignal(parent, COMSIG_ATOM_PROCESSED, PROC_REF(on_processed))
	RegisterSignal(parent, COMSIG_ATOM_REQUESTING_CONTEXT_FROM_ITEM, PROC_REF(on_requesting_context_from_item))
	ADD_TRAIT(parent, TRAIT_INGREDIENTS_HOLDER, INNATE_TRAIT)

/datum/component/ingredients_holder/UnregisterFromParent()
	. = ..()
	UnregisterSignal(parent, list(
		COMSIG_ATOM_ATTACKBY,
		COMSIG_ATOM_EXAMINE,
		COMSIG_ATOM_EXITED,
		COMSIG_ATOM_PROCESSED,
		COMSIG_ATOM_REQUESTING_CONTEXT_FROM_ITEM,
	))
	ADD_TRAIT(parent, TRAIT_INGREDIENTS_HOLDER, INNATE_TRAIT)

/datum/component/ingredients_holder/PostTransfer(datum/new_parent)
	if(!isatom(new_parent))
		return COMPONENT_INCOMPATIBLE
	var/atom/atom_parent = new_parent
	if (!atom_parent.reagents)
		return COMPONENT_INCOMPATIBLE

///Handles when the customizable food is examined.
/datum/component/ingredients_holder/proc/on_examine(atom/A, mob/user, list/examine_list)
	SIGNAL_HANDLER

	var/atom/atom_parent = parent

	examine_list += "It [LAZYLEN(ingredient_names) \
		? "contains [english_list(ingredient_names)] making a [custom_adjective()]-sized [initial(atom_parent.name)]" \
		: "does not contain any ingredients"]."

//// Proc that checks if an ingredient is valid or not, returning false if it isnt and true if it is.
/datum/component/ingredients_holder/proc/valid_ingredient(obj/ingredient)
	if (HAS_TRAIT(ingredient, TRAIT_INGREDIENTS_HOLDER))
		return FALSE
	if(HAS_TRAIT(ingredient, TRAIT_ODD_CUSTOMIZABLE_FOOD_INGREDIENT))
		return TRUE
	switch (ingredient_type)
		if (CUSTOM_INGREDIENT_TYPE_EDIBLE)
			return IS_EDIBLE(ingredient)
		if (CUSTOM_INGREDIENT_TYPE_DRYABLE)
			return HAS_TRAIT(ingredient, TRAIT_DRYABLE)
	return TRUE

///Handles when the customizable food is attacked by something.
/datum/component/ingredients_holder/proc/customizable_attack(datum/source, obj/ingredient, mob/attacker, silent = FALSE, force = FALSE)
	SIGNAL_HANDLER

	if (!valid_ingredient(ingredient))
		if (ingredient.is_drainable()) // For stuff like adding flour from a flour sack into a bowl, we handle the transfer of the reagent elsewhere, but we shouldn't regard it beyond some user feedback.
			attacker.balloon_alert(attacker, "transferring...")
			return
		attacker.balloon_alert(attacker, "doesn't go on that!")
		return

	if (LAZYLEN(ingredient_names) >= max_ingredients)
		attacker.balloon_alert(attacker, "too full!")
		return COMPONENT_NO_AFTERATTACK

	if(!attacker.transferItemToLoc(ingredient, parent))
		return
	add_ingredient(ingredient)


///Handles the icon update for a new ingredient.
/datum/component/ingredients_holder/proc/handle_fill(obj/item/ingredient)
	if (fill_type == CUSTOM_INGREDIENT_ICON_NOCHANGE)
		//don't bother doing the icon procs
		return
	var/atom/atom_parent = parent
	var/mutable_appearance/filling = mutable_appearance(atom_parent.icon, "[initial(atom_parent.icon_state)]_filling")
	// get average color
	var/icon/icon = new(ingredient.icon, ingredient.icon_state)
	if(ingredient.color)
		icon.Blend(ingredient.color, ICON_MULTIPLY)
	icon.Scale(1, 1)
	var/fillcol = copytext(icon.GetPixel(1, 1), 1, 8) // remove opacity
	filling.color = fillcol

	switch(fill_type)
		if(CUSTOM_INGREDIENT_ICON_SCATTER)
			filling.pixel_x = rand(-1,1)
			filling.pixel_z = rand(-1,1)
		if(CUSTOM_INGREDIENT_ICON_STACK)
			filling.pixel_x = rand(-1,1)
			// we're gonna abuse position layering to ensure overlays render right
			filling.pixel_y = -LAZYLEN(ingredient_names)
			filling.pixel_z = 3 * LAZYLEN(ingredient_names) - 1
		if(CUSTOM_INGREDIENT_ICON_STACKPLUSTOP)
			filling.pixel_x = rand(-1,1)
			// similar here
			filling.pixel_y = -LAZYLEN(ingredient_names)
			filling.pixel_z = 3 * LAZYLEN(ingredient_names) - 1
			if (top_overlay) // delete old top if exists
				atom_parent.cut_overlay(top_overlay)
			top_overlay = mutable_appearance(atom_parent.icon, "[atom_parent.icon_state]_top")
			top_overlay.pixel_y = -LAZYLEN(ingredient_names) - 1
			top_overlay.pixel_z = 3 * LAZYLEN(ingredient_names) + 4
			atom_parent.add_overlay(filling)
			atom_parent.add_overlay(top_overlay)
			return
		if(CUSTOM_INGREDIENT_ICON_FILL)
			if (top_overlay)
				filling.color = mix_color(filling.color)
				atom_parent.cut_overlay(top_overlay)
			top_overlay = filling
		if(CUSTOM_INGREDIENT_ICON_LINE)
			filling.pixel_x = filling.pixel_z = rand(-8,3)
	atom_parent.add_overlay(filling)


///Takes the reagents from an ingredient.
/datum/component/ingredients_holder/proc/handle_reagents(obj/item/ingredient)
	var/atom/atom_parent = parent
	if (atom_parent.reagents && ingredient.reagents)
		atom_parent.reagents.maximum_volume += ingredient.reagents.maximum_volume // If we don't do this custom food starts voiding reagents past a certain point.
		ingredient.reagents.trans_to(atom_parent, ingredient.reagents.total_volume)
	return


///Adds a new ingredient and updates the parent's name.
/datum/component/ingredients_holder/proc/add_ingredient(obj/item/ingredient)
	var/atom/atom_parent = parent
	if(!LAZYLEN(ingredients))
		base_materials = atom_parent.custom_materials.Copy()

	if (replacement)
		var/atom/replacement_parent = new replacement(atom_parent.drop_location())
		ingredient.forceMove(replacement_parent)
		replacement = null
		replacement_parent.TakeComponent(src)
		atom_parent = parent
		handle_reagents(atom_parent)
		qdel(atom_parent)

	if(ingredient.loc != atom_parent)
		ingredient.forceMove(atom_parent)

	handle_reagents(ingredient)

	LAZYADD(ingredients, ingredient)
	LAZYADD(ingredient_names, "\a [ingredient.name]")
	if(isitem(atom_parent))
		var/obj/item/item_parent = atom_parent
		if(ingredient.w_class > item_parent.w_class)
			item_parent.update_weight_class(ingredient.w_class)
	atom_parent.name = "[custom_adjective()] [custom_type()] [initial(atom_parent.name)]"
	SEND_SIGNAL(atom_parent, COMSIG_ATOM_CUSTOMIZED, ingredient)
	SEND_SIGNAL(ingredient, COMSIG_ITEM_USED_AS_INGREDIENT, atom_parent)

	handle_fill(ingredient)

	handle_materials()

///Rebuilds the custom materials the holder is composed of based on the materials of each ingredient
/datum/component/ingredients_holder/proc/handle_materials()
	var/atom/atom_parent = parent
	var/list/mats = base_materials?.Copy() || list()
	for(var/obj/item/ingredient as anything in atom_parent)
		if(!ingredient.custom_materials)
			continue
		for(var/mat in ingredient.custom_materials)
			base_materials[mat] += ingredient.custom_materials[mat]
	atom_parent.material_flags |= MATERIAL_EFFECTS|MATERIAL_AFFECT_STATISTICS|MATERIAL_NO_EDIBILITY //we want these
	atom_parent.material_flags &= ~MATERIAL_ADD_PREFIX|MATERIAL_COLOR // while we've fillings and examine strings for these.
	atom_parent.set_custom_materials(mats)

///Gives an adjective to describe the size of the custom food.
/datum/component/ingredients_holder/proc/custom_adjective()
	switch(LAZYLEN(ingredient_names))
		if (0 to 2)
			return "small"
		if (3 to 5)
			return "standard"
		if (6 to 8)
			return "big"
		if (8 to 11)
			return "ridiculous"
		if (12 to INFINITY)
			return "monstrous"


///Gives the type of custom food (based on what the first ingredient was).
/datum/component/ingredients_holder/proc/custom_type()
	var/custom_type = "empty"
	if (LAZYLEN(ingredients))
		var/obj/item/first_ingredient = ingredients[1]
		if (istype(first_ingredient, /obj/item/food/meat))
			var/obj/item/food/meat/meat = first_ingredient
			if (meat.subjectname)
				custom_type = meat.subjectname
			else if (meat.subjectjob)
				custom_type = meat.subjectjob
		if (custom_type == "empty" && first_ingredient.name)
			custom_type = first_ingredient.name
	return custom_type


///Returns the color of the input mixed with the top_overlay's color.
/datum/component/ingredients_holder/proc/mix_color(color)
	if(LAZYLEN(ingredients) == 1 || !top_overlay)
		return color
	else
		var/list/rgbcolor = list(0,0,0,0)
		var/customcolor = GetColors(color)
		var/ingcolor = GetColors(top_overlay.color)
		rgbcolor[1] = (customcolor[1]+ingcolor[1])/2
		rgbcolor[2] = (customcolor[2]+ingcolor[2])/2
		rgbcolor[3] = (customcolor[3]+ingcolor[3])/2
		rgbcolor[4] = (customcolor[4]+ingcolor[4])/2
		return rgb(rgbcolor[1], rgbcolor[2], rgbcolor[3], rgbcolor[4])


///Copies over the parent's fillings and name of ingredients to the processing results (such as slices when the parent is cut).
/datum/component/ingredients_holder/proc/on_processed(datum/source, mob/living/user, obj/item/ingredient, list/atom/results)
	SIGNAL_HANDLER

	// Reagents are not transferred since that should be handled elsewhere
	// while custom materials are already transferred evenly between results by atom/proc/StartProcessingAtom()
	for (var/atom/result as anything in results)
		result.AddComponent(/datum/component/ingredients_holder, null, fill_type, ingredient_type = ingredient_type, max_ingredients = max_ingredients, processed_holder = src)

/**
 * Adds context sensitivy directly to the customizable reagent holder file for screentips
 * Arguments:
 * * source - refers to item that will display its screentip
 * * context - refers to, in this case, an item that can be customized with other reagents or ingrideints
 * * held_item - refers to the item in your hand, which is hopefully an ingredient
 * * user - refers to user who will see the screentip when the proper context and tool are there
 */
/datum/component/ingredients_holder/proc/on_requesting_context_from_item(datum/source, list/context, obj/item/held_item, mob/user)
	SIGNAL_HANDLER

	// only accept valid ingredients
	if (isnull(held_item) || !valid_ingredient(held_item))
		return NONE

	context[SCREENTIP_CONTEXT_LMB] = "[screentip_verb] [held_item]"

	return CONTEXTUAL_SCREENTIP_SET

/// Clear refs if our food "goes away" somehow
/datum/component/ingredients_holder/proc/food_exited(datum/source, atom/movable/gone)
	SIGNAL_HANDLER
	LAZYREMOVE(ingredients, gone)
	LAZYREMOVE(ingredient_names, "\a [gone.name]")
	handle_materials()
