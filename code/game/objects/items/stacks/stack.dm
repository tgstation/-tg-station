/* Stack type objects!
 * Contains:
 * Stacks
 * Recipe datum
 * Recipe list datum
 */

/*
 * Stacks
 */

/obj/item/stack
	icon = 'icons/obj/stack_objects.dmi'
	gender = PLURAL
	material_modifier = 0.05 //5%, so that a 50 sheet stack has the effect of 5k materials instead of 100k.
	max_integrity = 100
	item_flags = SKIP_FANTASY_ON_SPAWN
	/// A list to all recipies this stack item can create.
	var/list/datum/stack_recipe/recipes
	/// What's the name of just 1 of this stack. You have a stack of leather, but one piece of leather
	var/singular_name
	/// How much is in this stack?
	var/amount = 1
	/// How much is allowed in this stack?
	// Also see stack recipes initialisation. "max_res_amount" must be equal to this max_amount
	var/max_amount = 50
	/// If TRUE, this stack is a module used by a cyborg (doesn't run out like normal / etc)
	var/is_cyborg = FALSE
	/// Related to above. If present, the energy we draw from when using stack items, for cyborgs
	var/datum/robot_energy_storage/source
	/// Related to above. How much energy it costs from storage to use stack items
	var/cost = 1
	/// This path and its children should merge with this stack, defaults to src.type
	var/merge_type = null
	/// The weight class the stack has at amount > 2/3rds max_amount
	var/full_w_class = WEIGHT_CLASS_NORMAL
	/// Determines whether the item should update its sprites based on amount.
	var/novariants = TRUE
	/// List that tells you how much is in a single unit.
	var/list/mats_per_unit
	/// Datum material type that this stack is made of
	var/material_type
	// NOTE: When adding grind_results, the amounts should be for an INDIVIDUAL ITEM -
	// these amounts will be multiplied by the stack size in on_grind()
	/// Amount of matter given back to RCDs
	var/matter_amount = 0
	/// Does this stack require a unique girder in order to make a wall?
	var/has_unique_girder = FALSE
	/// What typepath table we create from this stack
	var/obj/structure/table/tableVariant
	/// What typepath stairs do we create from this stack
	var/obj/structure/stairs/stairs_type
	/// If TRUE, we'll use a radial instead when displaying recipes
	var/use_radial = FALSE
	/// If use_radial is TRUE, this is the radius of the radial
	var/radial_radius = 52

	// The following are all for medical treatment
	// They're here instead of /stack/medical
	// because sticky tape can be used as a makeshift bandage or splint

	/// If set and this used as a splint for a broken bone wound,
	/// This is used as a multiplier for applicable slowdowns (lower = better) (also for speeding up burn recoveries)
	var/splint_factor
	/// Like splint_factor but for burns instead of bone wounds. This is a multiplier used to speed up burn recoveries
	var/burn_cleanliness_bonus
	/// How much blood flow this stack can absorb if used as a bandage on a cut wound.
	/// note that absorption is how much we lower the flow rate, not the raw amount of blood we suck up
	var/absorption_capacity
	/// How quickly we lower the blood flow on a cut wound we're bandaging.
	/// Expected lifetime of this bandage in seconds is thus absorption_capacity/absorption_rate,
	/// or until the cut heals, whichever comes first
	var/absorption_rate

/obj/item/stack/Initialize(mapload, new_amount, merge = TRUE, list/mat_override=null, mat_amt=1)
	if(new_amount != null)
		amount = new_amount
	while(amount > max_amount)
		amount -= max_amount
		new type(loc, max_amount, FALSE, mat_override, mat_amt)
	if(!merge_type)
		merge_type = type

	. = ..()

	var/materials_mult = amount
	if(LAZYLEN(mat_override))
		materials_mult *= mat_amt
		mats_per_unit = mat_override
	if(LAZYLEN(mats_per_unit))
		initialize_materials(mats_per_unit, materials_mult)

	if(merge && merge_with_stacks_on_same_loc())
		return INITIALIZE_HINT_QDEL

	recipes = get_main_recipes().Copy()
	if(material_type)
		var/datum/material/what_are_we_made_of = GET_MATERIAL_REF(material_type) //First/main material
		for(var/category in what_are_we_made_of.categories)
			switch(category)
				if(MAT_CATEGORY_BASE_RECIPES)
					recipes |= SSmaterials.base_stack_recipes.Copy()
				if(MAT_CATEGORY_RIGID)
					recipes |= SSmaterials.rigid_stack_recipes.Copy()

	update_weight()
	update_appearance()
	var/static/list/loc_connections = list(
		COMSIG_ATOM_ENTERED = PROC_REF(on_movable_entered_occupied_turf),
	)
	AddElement(/datum/element/connect_loc, loc_connections)

	if(is_path_in_list(merge_type, GLOB.golem_stack_food_directory))
		AddComponent(/datum/component/golem_food, golem_food_key = merge_type)

///the stack will loop through every stack in the loc and try to merge with them, and delete itself when the amount reaches zero.
/obj/item/stack/proc/merge_with_stacks_on_same_loc()
	for(var/obj/item/stack/item_stack in loc)
		if(item_stack == src)
			continue
		if(!can_merge(item_stack))
			continue
		INVOKE_ASYNC(src, PROC_REF(merge_without_del), item_stack)
		if(is_zero_amount(delete_if_zero = FALSE))
			return TRUE
	return FALSE

///Called to lazily update the materials of the item whenever the used or if more is added
/obj/item/stack/proc/update_custom_materials()
	if(length(mats_per_unit))
		set_custom_materials(mats_per_unit, amount)

/obj/item/stack/apply_material_effects(list/materials)
	. = ..()
	if(amount)
		mats_per_unit = SSmaterials.FindOrCreateMaterialCombo(materials, 1/amount)

/obj/item/stack/blend_requirements()
	if(is_cyborg)
		to_chat(usr, span_warning("[src] is too integrated into your chassis and can't be ground up!"))
		return
	return TRUE

/obj/item/stack/grind_atom(datum/reagents/target_holder, mob/user)
	var/current_amount = get_amount()
	if(current_amount <= 0 || QDELETED(src)) //just to get rid of this 0 amount/deleted stack we return success
		return TRUE

	if(reagents)
		reagents.trans_to(target_holder, reagents.total_volume, transferred_by = user)
	var/available_volume = target_holder.maximum_volume - target_holder.total_volume

	//compute total volume of reagents that will be occupied by grind_results
	var/total_volume = 0
	for(var/reagent in grind_results)
		total_volume += grind_results[reagent]

	//compute number of pieces(or sheets) from available_volume
	var/available_amount = min(current_amount, round(available_volume / total_volume))
	if(available_amount <= 0)
		return FALSE

	//Now transfer the grind results scaled by available_amount
	var/list/grind_reagents = grind_results.Copy()
	for(var/reagent in grind_reagents)
		grind_reagents[reagent] *= available_amount
	target_holder.add_reagent_list(grind_reagents)

	/**
	 * use available_amount of sheets/pieces, return TRUE only if all sheets/pieces of this stack were used
	 * we don't delete this stack when it reaches 0 because we expect the all in one grinder, etc to delete
	 * this stack if grinding was successful
	 */
	use(available_amount, check = FALSE)
	return available_amount == current_amount

/obj/item/stack/proc/get_main_recipes()
	RETURN_TYPE(/list)
	SHOULD_CALL_PARENT(TRUE)

	return list() //empty list

/obj/item/stack/proc/update_weight()
	if(amount <= (max_amount * (1/3)))
		update_weight_class(clamp(full_w_class-2, WEIGHT_CLASS_TINY, full_w_class))
	else if (amount <= (max_amount * (2/3)))
		update_weight_class(clamp(full_w_class-1, WEIGHT_CLASS_TINY, full_w_class))
	else
		update_weight_class(full_w_class)

/obj/item/stack/update_icon_state()
	if(novariants)
		return ..()
	if(amount <= (max_amount * (1/3)))
		icon_state = initial(icon_state)
		return ..()
	if (amount <= (max_amount * (2/3)))
		icon_state = "[initial(icon_state)]_2"
		return ..()
	icon_state = "[initial(icon_state)]_3"
	return ..()

/obj/item/stack/examine(mob/user)
	. = ..()
	if(is_cyborg)
		return
	if(singular_name)
		if(get_amount()>1)
			. += "There are [get_amount()] [singular_name]\s in the stack."
		else
			. += "There is [get_amount()] [singular_name] in the stack."
	else if(get_amount()>1)
		. += "There are [get_amount()] in the stack."
	else
		. += "There is [get_amount()] in the stack."
	. += span_notice("<b>Right-click</b> with an empty hand to take a custom amount.")

/obj/item/stack/proc/get_amount()
	if(is_cyborg)
		. = round(source?.energy / cost)
	else
		. = (amount)

/**
 * Builds all recipes in a given recipe list and returns an association list containing them
 *
 * Arguments:
 * * recipe_to_iterate - The list of recipes we are using to build recipes
 */
/obj/item/stack/proc/recursively_build_recipes(list/recipe_to_iterate)
	var/list/L = list()
	for(var/recipe in recipe_to_iterate)
		if(istype(recipe, /datum/stack_recipe_list))
			var/datum/stack_recipe_list/R = recipe
			L["[R.title]"] = recursively_build_recipes(R.recipes)
		if(istype(recipe, /datum/stack_recipe))
			var/datum/stack_recipe/R = recipe
			L["[R.title]"] = build_recipe(R)
	return L

/**
 * Returns a list of properties of a given recipe
 *
 * Arguments:
 * * R - The stack recipe we are using to get a list of properties
 */
/obj/item/stack/proc/build_recipe(datum/stack_recipe/R)
	var/list/data = list()
	var/obj/result = R.result_type

	data["ref"] = text_ref(R)
	data["req_amount"] = R.req_amount
	data["res_amount"] = R.res_amount
	data["max_res_amount"] = R.max_res_amount
	data["icon"] = result.icon
	data["icon_state"] = result.icon_state

	// DmIcon cannot paint images. So, if we have grayscale sprite, we need ready base64 image.
	if(R.result_image)
		data["image"] = R.result_image

	return data

/**
 * Checks if the recipe is valid to be used
 *
 * Arguments:
 * * R - The stack recipe we are checking if it is valid
 * * recipe_list - The list of recipes we are using to check the given recipe
 */
/obj/item/stack/proc/is_valid_recipe(datum/stack_recipe/R, list/recipe_list)
	for(var/S in recipe_list)
		if(S == R)
			return TRUE
		if(istype(S, /datum/stack_recipe_list))
			var/datum/stack_recipe_list/L = S
			if(is_valid_recipe(R, L.recipes))
				return TRUE
	return FALSE

/obj/item/stack/interact(mob/user)
	if(use_radial)
		show_construction_radial(user)
	else
		ui_interact(user)

/obj/item/stack/ui_state(mob/user)
	return GLOB.hands_state

/obj/item/stack/ui_interact(mob/user, datum/tgui/ui)
	ui = SStgui.try_update_ui(user, src, ui)
	if(!ui)
		ui = new(user, src, "StackCrafting", name)
		ui.open()

/obj/item/stack/ui_data(mob/user)
	var/list/data = list()
	data["amount"] = get_amount()
	return data

/obj/item/stack/ui_static_data(mob/user)
	var/list/data = list()
	data["recipes"] = recursively_build_recipes(recipes)
	return data

/obj/item/stack/ui_act(action, list/params, datum/tgui/ui, datum/ui_state/state)
	. = ..()
	if(.)
		return

	switch(action)
		if("make")
			var/datum/stack_recipe/recipe = locate(params["ref"])
			var/multiplier = text2num(params["multiplier"])

			return make_item(usr, recipe, multiplier)

/// The key / title for a radial option that shows the entire list of buildables (uses the old menu)
#define FULL_LIST "view full list"

/// Shows a radial consisting of every radial recipe we have in our list.
/obj/item/stack/proc/show_construction_radial(mob/builder)
	var/list/options = list()
	var/list/titles_to_recipes = list()

	for(var/datum/stack_recipe/radial/recipe in recipes)
		var/datum/radial_menu_choice/option = new()
		option.image = image(
			icon = initial(recipe.result_type.icon),
			icon_state = initial(recipe.result_type.icon_state),
		)

		if(recipe.desc)
			option.info = recipe.desc

		options[recipe.title] = option
		titles_to_recipes[recipe.title] = recipe

	// After everything's been added to the radial, add an option
	// that lets the user see the whole list of buildables
	options[FULL_LIST] = image(
		icon = 'icons/hud/radial.dmi',
		icon_state = "radial_full_list",
	)

	var/selection = show_radial_menu(
		user = builder,
		anchor = builder,
		choices = options,
		custom_check = CALLBACK(src, PROC_REF(radial_check), builder),
		radius = radial_radius,
		tooltips = TRUE,
	)

	if(!selection)
		return
	// Run normal UI interact if we wanna see the full list
	if(selection == FULL_LIST)
		ui_interact(builder)
		return

	// Otherwise go straight to building
	var/datum/stack_recipe/picked_recipe = titles_to_recipes[selection]
	if(!istype(picked_recipe))
		return

	make_item(builder, picked_recipe, 1)

/// Used as a callback for radial building.
/obj/item/stack/proc/radial_check(mob/builder)
	if(QDELETED(builder) || QDELETED(src))
		return FALSE
	if(builder.incapacitated)
		return FALSE
	if(!builder.is_holding(src))
		return FALSE
	return TRUE

#undef FULL_LIST

/// Makes the item with the given recipe.
/obj/item/stack/proc/make_item(mob/builder, datum/stack_recipe/recipe, multiplier)
	if(get_amount() < 1 && !is_cyborg) //sanity check as this shouldn't happen
		qdel(src)
		return
	if(!is_valid_recipe(recipe, recipes)) //href exploit protection
		return
	if(!multiplier || multiplier < 1 || !IS_FINITE(multiplier)) //href exploit protection
		stack_trace("Invalid multiplier value in stack creation [multiplier], [usr] is likely attempting an exploit")
		return
	if(!building_checks(builder, recipe, multiplier))
		return
	if(recipe.time)
		var/adjusted_time = 0
		builder.balloon_alert(builder, "building...")
		builder.visible_message(
			span_notice("[builder] starts building \a [recipe.title]."),
			span_notice("You start building \a [recipe.title]..."),
		)
		if(HAS_TRAIT(builder, recipe.trait_booster))
			adjusted_time = (recipe.time * recipe.trait_modifier)
		else
			adjusted_time = recipe.time
		if(!do_after(builder, adjusted_time, target = builder))
			builder.balloon_alert(builder, "interrupted!")
			return
		if(!building_checks(builder, recipe, multiplier))
			return

	var/atom/created
	if(recipe.max_res_amount > 1) // Is it a stack?
		created = new recipe.result_type(builder.drop_location(), recipe.res_amount * multiplier)
		builder.balloon_alert(builder, "built items")

	else if(ispath(recipe.result_type, /turf))
		var/turf/covered_turf = builder.drop_location()
		if(!isturf(covered_turf))
			return
		var/turf/created_turf = covered_turf.place_on_top(recipe.result_type, flags = CHANGETURF_INHERIT_AIR)
		builder.balloon_alert(builder, "placed [ispath(recipe.result_type, /turf/open) ? "floor" : "wall"]")
		if((recipe.crafting_flags & CRAFT_APPLIES_MATS) && LAZYLEN(mats_per_unit))
			created_turf.set_custom_materials(mats_per_unit, recipe.req_amount / recipe.res_amount)

	else
		created = new recipe.result_type(builder.drop_location())
		builder.balloon_alert(builder, "built item")

	if(created)
		created.setDir(builder.dir)
		SEND_SIGNAL(created, COMSIG_ATOM_CONSTRUCTED, builder)
		on_item_crafted(builder, created)

	// Use up the material
	use(recipe.req_amount * multiplier)
	builder.investigate_log("crafted [recipe.title]", INVESTIGATE_CRAFTING)

	// Apply mat datums
	if((recipe.crafting_flags & CRAFT_APPLIES_MATS) && LAZYLEN(mats_per_unit))
		if(isstack(created))
			var/obj/item/stack/crafted_stack = created
			crafted_stack.set_custom_materials(mats_per_unit, (recipe.req_amount / recipe.res_amount) * crafted_stack.amount)
		else
			created.set_custom_materials(mats_per_unit, recipe.req_amount / recipe.res_amount)

	// We could be qdeleted - like if it's a stack and has already been merged
	if(QDELETED(created))
		return TRUE

	// Add fingerprints first, otherwise created might already be deleted because of stack merging
	created.add_fingerprint(builder)
	if(isitem(created))
		builder.put_in_hands(created)

	//BubbleWrap - so newly formed boxes are empty
	if(istype(created, /obj/item/storage))
		for (var/obj/item/thing in created)
			qdel(thing)
	//BubbleWrap END

	return TRUE

/// Run special logic on created items after they've been successfully crafted.
/obj/item/stack/proc/on_item_crafted(mob/builder, atom/created)
	return

/obj/item/stack/vv_edit_var(vname, vval)
	if(vname == NAMEOF(src, amount))
		add(clamp(vval, 1-amount, max_amount - amount)) //there must always be one.
		return TRUE
	else if(vname == NAMEOF(src, max_amount))
		max_amount = max(vval, 1)
		add((max_amount < amount) ? (max_amount - amount) : 0) //update icon, weight, ect
		return TRUE
	return ..()

/// Checks if we can build here, validly.
/obj/item/stack/proc/building_checks(mob/builder, datum/stack_recipe/recipe, multiplier)
	if (get_amount() < recipe.req_amount * multiplier)
		builder.balloon_alert(builder, "not enough material!")
		return FALSE
	var/turf/dest_turf = get_turf(builder)

	if((recipe.crafting_flags & CRAFT_ONE_PER_TURF) && (locate(recipe.result_type) in dest_turf))
		builder.balloon_alert(builder, "already one here!")
		return FALSE

	if(recipe.crafting_flags & CRAFT_CHECK_DIRECTION)
		if(!valid_build_direction(dest_turf, builder.dir, is_fulltile = (recipe.crafting_flags & CRAFT_IS_FULLTILE)))
			builder.balloon_alert(builder, "won't fit here!")
			return FALSE

	if(recipe.crafting_flags & CRAFT_ON_SOLID_GROUND)
		if(isclosedturf(dest_turf))
			builder.balloon_alert(builder, "cannot be made on a wall!")
			return FALSE

		if(is_type_in_typecache(dest_turf, GLOB.turfs_without_ground))
			if(!locate(/obj/structure/thermoplastic) in dest_turf) // for tram construction
				builder.balloon_alert(builder, "must be made on solid ground!")
				return FALSE

	if(recipe.crafting_flags & CRAFT_CHECK_DENSITY)
		for(var/obj/object in dest_turf)
			if(object.density && !(object.obj_flags & IGNORE_DENSITY) || object.obj_flags & BLOCKS_CONSTRUCTION)
				builder.balloon_alert(builder, "something is in the way!")
				return FALSE

	if(recipe.placement_checks & STACK_CHECK_CARDINALS)
		var/turf/nearby_turf
		for(var/direction in GLOB.cardinals)
			nearby_turf = get_step(dest_turf, direction)
			if(locate(recipe.result_type) in nearby_turf)
				to_chat(builder, span_warning("\The [recipe.title] must not be built directly adjacent to another!"))
				builder.balloon_alert(builder, "can't be adjacent to another!")
				return FALSE

	if(recipe.placement_checks & STACK_CHECK_ADJACENT)
		if(locate(recipe.result_type) in range(1, dest_turf))
			builder.balloon_alert(builder, "can't be near another!")
			return FALSE

	if(recipe.placement_checks & STACK_CHECK_TRAM_FORBIDDEN)
		if(locate(/obj/structure/transport/linear/tram) in dest_turf || locate(/obj/structure/thermoplastic) in dest_turf)
			builder.balloon_alert(builder, "can't be on tram!")
			return FALSE

	if(recipe.placement_checks & STACK_CHECK_TRAM_EXCLUSIVE)
		if(!locate(/obj/structure/transport/linear/tram) in dest_turf)
			builder.balloon_alert(builder, "must be made on a tram!")
			return FALSE

	return TRUE

/obj/item/stack/use(used, transfer = FALSE, check = TRUE) // return 0 = borked; return 1 = had enough
	if(check && is_zero_amount(delete_if_zero = TRUE))
		return FALSE
	if(is_cyborg)
		return source.use_charge(used * cost)
	if (amount < used)
		return FALSE
	amount -= used
	if(check && is_zero_amount(delete_if_zero = TRUE))
		return TRUE
	update_custom_materials()
	update_appearance()
	update_weight()
	return TRUE

/obj/item/stack/tool_use_check(mob/living/user, amount, heat_required)
	if(get_amount() < amount)
		// general balloon alert that says they don't have enough
		user.balloon_alert(user, "not enough material!")
		// then a more specific message about how much they need and what they need specifically
		if(singular_name)
			if(amount > 1)
				to_chat(user, span_warning("You need at least [amount] [singular_name]\s to do this!"))
			else
				to_chat(user, span_warning("You need at least [amount] [singular_name] to do this!"))
		else
			to_chat(user, span_warning("You need at least [amount] to do this!"))

		return FALSE

	return TRUE

/**
 * Returns TRUE if the item stack is the equivalent of a 0 amount item.
 *
 * Also deletes the item if delete_if_zero is TRUE and the stack does not have
 * is_cyborg set to true.
 */
/obj/item/stack/proc/is_zero_amount(delete_if_zero = TRUE)
	if(is_cyborg)
		return source.energy < cost
	if(amount < 1)
		if(delete_if_zero)
			qdel(src)
		return TRUE
	return FALSE

/** Adds some number of units to this stack.
 *
 * Arguments:
 * - _amount: The number of units to add to this stack.
 */
/obj/item/stack/proc/add(_amount)
	if(is_cyborg)
		source.add_charge(_amount * cost)
	else
		amount += _amount
	update_custom_materials()
	update_appearance()
	update_weight()

/** Checks whether this stack can merge itself into another stack.
 *
 * Arguments:
 * - [check][/obj/item/stack]: The stack to check for mergeability.
 * - [inhand][boolean]: Whether or not the stack to check should act like it's in a mob's hand.
 */
/obj/item/stack/proc/can_merge(obj/item/stack/check, inhand = FALSE)
	// We don't only use istype here, since that will match subtypes, and stack things that shouldn't stack
	if(!istype(check, merge_type) || check.merge_type != merge_type)
		return FALSE
	if(mats_per_unit ~! check.mats_per_unit) // ~! in case of lists this operator checks only keys, but not values
		return FALSE
	if(is_cyborg) // No merging cyborg stacks into other stacks
		return FALSE
	if(ismob(loc) && !inhand && !HAS_TRAIT(loc, TRAIT_MOB_MERGE_STACKS)) // no merging with items that are on the mob
		return FALSE
	if(istype(loc, /obj/machinery)) // no merging items in machines that aren't both in componentparts
		var/obj/machinery/machine = loc
		if(!(src in machine.component_parts) || !(check in machine.component_parts))
			return FALSE
	if(SEND_SIGNAL(src, COMSIG_STACK_CAN_MERGE, check, inhand) & CANCEL_STACK_MERGE)
		return FALSE
	return TRUE

/**
 * Merges as much of src into target_stack as possible. If present, the limit arg overrides target_stack.max_amount for transfer.
 *
 * This calls use() without check = FALSE, preventing the item from qdeling itself if it reaches 0 stack size.
 *
 * As a result, this proc can leave behind a 0 amount stack.
 */
/obj/item/stack/proc/merge_without_del(obj/item/stack/target_stack, limit)
	// Cover edge cases where multiple stacks are being merged together and haven't been deleted properly.
	// Also cover edge case where a stack is being merged into itself, which is supposedly possible.
	if(QDELETED(target_stack))
		CRASH("Stack merge attempted on qdeleted target stack.")
	if(QDELETED(src))
		CRASH("Stack merge attempted on qdeleted source stack.")
	if(target_stack == src)
		CRASH("Stack attempted to merge into itself.")

	var/transfer = get_amount()
	if(target_stack.is_cyborg)
		transfer = min(transfer, round((target_stack.source.max_energy - target_stack.source.energy) / target_stack.cost))
	else
		transfer = min(transfer, (limit ? limit : target_stack.max_amount) - target_stack.amount)
	if(pulledby)
		pulledby.start_pulling(target_stack)
	target_stack.copy_evidences(src)
	use(transfer, transfer = TRUE, check = FALSE)
	target_stack.add(transfer)
	if(target_stack.mats_per_unit != mats_per_unit) // We get the average value of mats_per_unit between two stacks getting merged
		var/list/temp_mats_list = list() // mats_per_unit is passed by ref into this coil, and that same ref is used in other places. If we didn't make a new list here we'd end up contaminating those other places, which leads to batshit behavior
		for(var/mat_type in target_stack.mats_per_unit)
			temp_mats_list[mat_type] = (target_stack.mats_per_unit[mat_type] * (target_stack.amount - transfer) + mats_per_unit[mat_type] * transfer) / target_stack.amount
		target_stack.mats_per_unit = temp_mats_list
	return transfer

/**
 * Merges as much of src into target_stack as possible. If present, the limit arg overrides target_stack.max_amount for transfer.
 *
 * This proc deletes src if the remaining amount after the transfer is 0.
 */
/obj/item/stack/proc/merge(obj/item/stack/target_stack, limit)
	. = merge_without_del(target_stack, limit)
	is_zero_amount(delete_if_zero = TRUE)

/// Signal handler for connect_loc element. Called when a movable enters the turf we're currently occupying. Merges if possible.
/obj/item/stack/proc/on_movable_entered_occupied_turf(datum/source, atom/movable/arrived)
	SIGNAL_HANDLER

	// Edge case. This signal will also be sent when src has entered the turf. Don't want to merge with ourselves.
	if(arrived == src)
		return

	if(!arrived.throwing && can_merge(arrived))
		INVOKE_ASYNC(src, PROC_REF(merge), arrived)

/obj/item/stack/hitby(atom/movable/hitting, skipcatch, hitpush, blocked, datum/thrownthing/throwingdatum)
	if(can_merge(hitting, inhand = TRUE))
		merge(hitting)
	. = ..()

//ATTACK HAND IGNORING PARENT RETURN VALUE
/obj/item/stack/attack_hand(mob/user, list/modifiers)
	if(user.get_inactive_held_item() == src)
		if(is_zero_amount(delete_if_zero = TRUE))
			return
		return split_stack(user, 1)
	else
		. = ..()

/obj/item/stack/attack_hand_secondary(mob/user, modifiers)
	. = ..()
	if(. == SECONDARY_ATTACK_CANCEL_ATTACK_CHAIN)
		return

	if(is_cyborg || !user.can_perform_action(src, NEED_DEXTERITY))
		return SECONDARY_ATTACK_CONTINUE_CHAIN
	if(is_zero_amount(delete_if_zero = TRUE))
		return SECONDARY_ATTACK_CANCEL_ATTACK_CHAIN
	var/max = get_amount()
	var/stackmaterial = tgui_input_number(user, "How many sheets do you wish to take out of this stack?", "Stack Split", max_value = max)
	if(!stackmaterial || QDELETED(user) || QDELETED(src) || !usr.can_perform_action(src, FORBID_TELEKINESIS_REACH))
		return SECONDARY_ATTACK_CANCEL_ATTACK_CHAIN
	split_stack(user, stackmaterial)
	to_chat(user, span_notice("You take [stackmaterial] sheets out of the stack."))
	return SECONDARY_ATTACK_CANCEL_ATTACK_CHAIN

/** Splits the stack into two stacks.
 *
 * Arguments:
 * - [user][/mob]: The mob splitting the stack.
 * - amount: The number of units to split from this stack.
 */
/obj/item/stack/proc/split_stack(mob/user, amount)
	if(!use(amount, TRUE, FALSE))
		return null
	var/obj/item/stack/F = new type(user? user : drop_location(), amount, FALSE, mats_per_unit)
	. = F
	F.copy_evidences(src)
	loc.atom_storage?.refresh_views()
	if(user)
		if(!user.put_in_hands(F, merge_stacks = FALSE))
			F.forceMove(user.drop_location())
		add_fingerprint(user)
		F.add_fingerprint(user)

	is_zero_amount(delete_if_zero = TRUE)

/obj/item/stack/attackby(obj/item/W, mob/user, params)
	if(can_merge(W, inhand = TRUE))
		var/obj/item/stack/S = W
		if(merge(S))
			to_chat(user, span_notice("Your [S.name] stack now contains [S.get_amount()] [S.singular_name]\s."))
	else
		. = ..()

/obj/item/stack/proc/copy_evidences(obj/item/stack/from)
	add_blood_DNA(GET_ATOM_BLOOD_DNA(from))
	add_fingerprint_list(GET_ATOM_FINGERPRINTS(from))
	add_hiddenprint_list(GET_ATOM_HIDDENPRINTS(from))
	fingerprintslast = from.fingerprintslast
	//TODO bloody overlay
