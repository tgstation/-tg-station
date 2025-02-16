/*
* A debug chem tester that will process through all recipies automatically and try to react them.
* Highlights low purity reactions and and reactions that don't happen
*/

///don't alter the temperatrue of the reaction
#define USE_REACTION_TEMPERATURE 0
///force a user specified value for temperature on the reaction
#define USE_USER_TEMPERATURE 1
///force the minimum required temperature for the reaction to start on the reaction
#define USE_MINIMUM_TEMPERATURE 2
///force the optimal temperature for the reaction
#define USE_OPTIMAL_TEMPERATURE 3
///force the overheat temperature for the reaction. At this point reagents start to decrease
#define USE_OVERHEAT_TEMPERATURE 4

///Play the next reaction i.e. increment current_reaction_index
#define PLAY_NEXT_REACTION 0
///Play the previous reaction i.e. decrement current_reaction_index
#define PLAY_PREVIOUS_REACTION 1
///Pick a reaction at random i.e. user decides via input list what the value of current_reaction_index should be
#define PLAY_USER_REACTION 2

///Maximum volume of reagents this machine & its required container can hold
#define MAXIMUM_HOLDER_VOLUME 9000

/obj/machinery/chem_recipe_debug
	name = "chemical reaction tester"
	icon = 'icons/obj/medical/chemical.dmi'
	icon_state = "HPLC_debug"
	density = TRUE
	use_power = NO_POWER_USE
	resistance_flags = FIRE_PROOF | ACID_PROOF | INDESTRUCTIBLE

	///Temperature to be imposed on the reaction
	var/forced_temp = DEFAULT_REAGENT_TEMPERATURE
	///The mode for setting reaction temps. see temp defines
	var/temp_mode = USE_REACTION_TEMPERATURE
	///The ph to be imposed on the reaction
	var/forced_ph = CHEMICAL_NORMAL_PH
	///if TRUE will use forced_ph else don't alter the ph of the reaction
	var/use_forced_ph = FALSE
	///The purity of all reagents to be imposed on the reaction
	var/forced_purity = 1.0
	///If TRUE will use forced_purity else don't alter the purity of the reaction
	var/use_forced_purity = FALSE
	///The multiplier to be applied on the selected reaction required reagents to start the reaction
	var/volume_multiplier = 1

	///Cached copy all reactions mapped with their name
	var/static/list/all_reaction_list
	///The list of reactions to test
	var/list/datum/chemical_reaction/reactions_to_test = list()
	///The index in reactions_to_test list which points to the current reaction under test
	var/current_reaction_index = 0
	///Decides which reaction to play in the reactions_to_test list see Play defines
	var/current_reaction_mode = PLAY_NEXT_REACTION
	///The current reaction we are editing
	var/datum/chemical_reaction/edit_reaction
	///The current var of the reaction we are editing
	var/edit_var = "Required Temp"

	///The target reagents to we are working with. can vary if an reaction requires a specific container
	var/datum/reagents/target_reagents
	///The beaker inside this machine, if null will create a new one
	var/obj/item/reagent_containers/container
	///The default reagent container required for the selected test reaction if any
	var/obj/item/reagent_containers/required_container

/obj/machinery/chem_recipe_debug/Initialize(mapload)
	. = ..()

	create_reagents(MAXIMUM_HOLDER_VOLUME)
	target_reagents = reagents
	RegisterSignal(reagents, COMSIG_REAGENTS_REACTION_STEP, PROC_REF(on_reaction_step))
	register_context()

	if(isnull(all_reaction_list))
		all_reaction_list = list()
		for(var/datum/reagent/reagent as anything in GLOB.chemical_reactions_list_reactant_index)
			for(var/datum/chemical_reaction/reaction as anything in GLOB.chemical_reactions_list_reactant_index[reagent])
				all_reaction_list[extract_reaction_name(reaction)] = reaction

/obj/machinery/chem_recipe_debug/Destroy()
	reactions_to_test.Cut()
	target_reagents = null
	edit_reaction = null
	QDEL_NULL(container)
	QDEL_NULL(required_container)
	return ..()

/obj/machinery/chem_recipe_debug/add_context(atom/source, list/context, obj/item/held_item, mob/user)
	. = ..()
	if(isnull(held_item) || (held_item.item_flags & ABSTRACT) || (held_item.flags_1 & HOLOGRAM_1))
		return NONE

	if(!QDELETED(container))
		if(is_reagent_container(held_item)  && held_item.is_open_container())
			context[SCREENTIP_CONTEXT_LMB] = "Replace container"
			return CONTEXTUAL_SCREENTIP_SET
	else if(is_reagent_container(held_item)  && held_item.is_open_container())
		context[SCREENTIP_CONTEXT_LMB] = "Insert container"
		return CONTEXTUAL_SCREENTIP_SET

/obj/machinery/chem_recipe_debug/examine(mob/user)
	. = ..()
	if(!QDELETED(container))
		. += span_notice("A container of [container.reagents.maximum_volume]u capacity is inside.")
	else
		. += span_notice("No container is present. A new will be created when ejecting.")

/obj/machinery/chem_recipe_debug/Exited(atom/movable/gone, direction)
	. = ..()
	if(gone == container)
		container = null

/obj/machinery/chem_recipe_debug/item_interaction(mob/living/user, obj/item/held_item, list/modifiers)
	. = NONE
	if((held_item.item_flags & ABSTRACT) || (held_item.flags_1 & HOLOGRAM_1))
		return

	if(is_reagent_container(held_item)  && held_item.is_open_container())
		if(!QDELETED(container))
			try_put_in_hand(container, user)
		if(!user.transferItemToLoc(held_item, src))
			return ITEM_INTERACT_FAILURE
		container = held_item
		return ITEM_INTERACT_SUCCESS

/**
 * Extracts a human readable name for this chemical reaction
 * Arguments
 *
 * * datum/chemical_reaction/reaction - the reaction who's name we have to decode
 */
/obj/machinery/chem_recipe_debug/proc/extract_reaction_name(datum/chemical_reaction/reaction)
	PRIVATE_PROC(TRUE)
	SHOULD_BE_PURE(TRUE)

	var/reaction_name = "[reaction]"
	reaction_name = copytext(reaction_name, findlasttext(reaction_name, "/") + 1)
	reaction_name = replacetext(reaction_name, "_", " ")
	return full_capitalize(reaction_name)

///Retrives the target temperature to be imposed on the test reaction based on temp_mode
/obj/machinery/chem_recipe_debug/proc/decode_target_temperature()
	PRIVATE_PROC(TRUE)
	SHOULD_BE_PURE(TRUE)

	if(temp_mode == USE_REACTION_TEMPERATURE)
		return null //simply means don't alter the reaction temperature
	else if(temp_mode == USE_USER_TEMPERATURE)
		return forced_temp
	else
		var/datum/chemical_reaction/test_reaction = reactions_to_test[current_reaction_index || 1]
		switch(temp_mode)
			if(USE_MINIMUM_TEMPERATURE)
				return test_reaction.required_temp
			if(USE_OPTIMAL_TEMPERATURE)
				return test_reaction.optimal_temp
			if(USE_OVERHEAT_TEMPERATURE)
				return test_reaction.overheat_temp

/**
 * Adjusts the temperature, ph & purity of the holder
 * Arguments
 *
 * * seconds_per_tick - passed from on_reaction_step or process
 */
/obj/machinery/chem_recipe_debug/proc/adjust_environment(seconds_per_tick)
	PRIVATE_PROC(TRUE)

	var/target_temperature = decode_target_temperature()
	if(!isnull(target_temperature))
		target_reagents.adjust_thermal_energy((target_temperature - target_reagents.chem_temp) * 0.4 * seconds_per_tick * target_reagents.heat_capacity())

	if(use_forced_purity)
		target_reagents.set_all_reagents_purity(forced_purity)

	if(use_forced_ph)
		for(var/datum/reagent/reagent as anything in target_reagents.reagent_list)
			reagent.ph = clamp(forced_ph, CHEMICAL_MIN_PH, CHEMICAL_MAX_PH)

	target_reagents.update_total()

/obj/machinery/chem_recipe_debug/process(seconds_per_tick)
	if(!target_reagents.is_reacting)
		adjust_environment(seconds_per_tick)
		target_reagents.handle_reactions()

	//send updates to ui. faster than SStgui.update_uis
	for(var/datum/tgui/ui in src.open_uis)
		ui.send_update()

/obj/machinery/chem_recipe_debug/proc/on_reaction_step(datum/reagents/holder, num_reactions, seconds_per_tick)
	SIGNAL_HANDLER

	adjust_environment(seconds_per_tick)

	//send updates to ui. faster than SStgui.update_uis
	for(var/datum/tgui/ui in src.open_uis)
		ui.send_update()

/**
 * Decodes the ui reaction var into its original name
 * Arguments
 *
 * * variable - the name of the variable as seen in the UI
 */
/obj/machinery/chem_recipe_debug/proc/decode_var(variable)
	PRIVATE_PROC(TRUE)

	. = null

	if(isnull(edit_reaction))
		return

	var/static/list/ui_to_var
	if(isnull(ui_to_var))
		ui_to_var = list(
			"Required Temp" = "required_temp",
			"Optimal Temp" = "optimal_temp",
			"Overheat Temp" = "overheat_temp",
			"Optimal Min Ph" = "optimal_ph_min",
			"Optimal Max Ph" = "optimal_ph_max",
			"Ph Range" = "determin_ph_range",
			"Temp Exp Factor" = "temp_exponent_factor",
			"Ph Exp Factor" = "ph_exponent_factor",
			"Thermic Constant" = "thermic_constant",
			"H Ion Release" = "H_ion_release",
			"Rate Up Limit" = "rate_up_lim",
			"Purity Min" = "purity_min",
		)

	var/value = ui_to_var[variable]
	if(!isnull(value))
		. = value

/obj/machinery/chem_recipe_debug/ui_interact(mob/user, datum/tgui/ui)
	ui = SStgui.try_update_ui(user, src, ui)
	if(!ui)
		ui = new(user, src, "ChemRecipeDebug", name)
		ui.open()

/obj/machinery/chem_recipe_debug/ui_data(mob/user)
	. = list()

	.["forced_temp"] = forced_temp
	.["temp_mode"] = temp_mode
	.["forced_ph"] = forced_ph
	.["use_forced_ph"] = use_forced_ph
	.["forced_purity"] = forced_purity
	.["use_forced_purity"] = use_forced_purity
	.["volume_multiplier"] = volume_multiplier

	var/datum/chemical_reaction/current_reaction = null
	if(reactions_to_test.len)
		current_reaction = reactions_to_test[current_reaction_index || 1]
	if(isnull(current_reaction))
		.["current_reaction_name"] = "N/A"
	else
		.["current_reaction_name"] = extract_reaction_name(current_reaction)
	.["current_reaction_mode"] = current_reaction_mode

	var/list/active_reactions = list()
	var/flashing = DISABLE_FLASHING //for use with alertAfter - since there is no alertBefore, I set the after to 0 if true, or to the max value if false
	for(var/datum/equilibrium/equilibrium as anything in target_reagents.reaction_list)
		if(!equilibrium.reaction.results)//Incase of no result reactions
			continue
		var/datum/reagent/reagent = target_reagents.has_reagent(equilibrium.reaction.results[1]) //Reactions are named after their primary products
		if(!reagent)
			continue

		//check for danger levels primirarly overheating
		var/overheat = FALSE
		var/danger = FALSE
		var/purity_alert = 2 //same as flashing
		if(reagent.purity < equilibrium.reaction.purity_min)
			purity_alert = ENABLE_FLASHING//Because 0 is seen as null
			danger = TRUE
		if(flashing != ENABLE_FLASHING)//So that the pH meter flashes for ANY reactions out of optimal
			if(equilibrium.reaction.optimal_ph_min > target_reagents.ph || equilibrium.reaction.optimal_ph_max < target_reagents.ph)
				flashing = ENABLE_FLASHING
		if(equilibrium.reaction.is_cold_recipe)
			if(equilibrium.reaction.overheat_temp > target_reagents.chem_temp && equilibrium.reaction.overheat_temp != NO_OVERHEAT)
				danger = TRUE
				overheat = TRUE
		else
			if(equilibrium.reaction.overheat_temp < target_reagents.chem_temp)
				danger = TRUE
				overheat = TRUE

		//create ui data
		active_reactions += list(list(
			"name" = reagent.name,
			"danger" = danger,
			"overheat" = overheat,
			"purityAlert" = purity_alert,
			"quality" = equilibrium.reaction_quality,
			"inverse" = reagent.inverse_chem_val,
			"minPure" = equilibrium.reaction.purity_min,
			"reactedVol" = equilibrium.reacted_vol,
			"targetVol" = round(equilibrium.target_vol, 1)
			)
		)

		//additional data for competitive reactions
		if(equilibrium.reaction.reaction_flags & REACTION_COMPETITIVE) //We have a compeitive reaction - concatenate the results for the different reactions
			for(var/entry in active_reactions)
				if(entry["name"] == reagent.name) //If we have multiple reaction methods for the same result - combine them
					entry["reactedVol"] = equilibrium.reacted_vol
					entry["targetVol"] = round(equilibrium.target_vol, 1)//Use the first result reagent to name the reaction detected
					entry["quality"] = (entry["quality"] + equilibrium.reaction_quality) /2
					continue
	.["activeReactions"] = active_reactions

	.["isFlashing"] = flashing
	.["isReacting"] = target_reagents.is_reacting

	var/list/reaction_data = null
	if(!isnull(edit_reaction))
		var/reaction_name
		if(length(edit_reaction.results)) //soups can have no results
			var/datum/reagent/reagent = edit_reaction.results[1]
			reaction_name = initial(reagent.name)
		else
			reaction_name = "[edit_reaction]"
		reaction_data = list(
			"name" = reaction_name,
			"editVar" = edit_var,
			"editValue" = edit_reaction.vars[decode_var(edit_var)]
		)
	.["editReaction"] = reaction_data

	var/list/beaker_data = null
	if(!QDELETED(container) || target_reagents.total_volume)
		beaker_data = list()
		beaker_data["maxVolume"] = target_reagents.maximum_volume
		beaker_data["pH"] = round(target_reagents.ph, 0.01)
		beaker_data["currentVolume"] = target_reagents.total_volume
		beaker_data["currentTemp"] = round(target_reagents.chem_temp, 1)
		beaker_data["purity"] = round(target_reagents.get_average_purity(), 0.001)
		var/list/beakerContents = list()
		if(length(target_reagents.reagent_list))
			for(var/datum/reagent/reagent in target_reagents.reagent_list)
				beakerContents += list(list("name" = reagent.name, "volume" = round(reagent.volume, CHEMICAL_VOLUME_ROUNDING)))

		if(!QDELETED(required_container))
			//as of now we only decode soup pots. If more exotic containers are made make sure to add them here
			if(istype(required_container, /obj/item/reagent_containers/cup/soup_pot))
				var/obj/item/reagent_containers/cup/soup_pot/pot = required_container
				for(var/obj/item as anything in pot.added_ingredients)
					//increment count if item already exists
					var/entry_found = FALSE
					for(var/list/entry as anything in beakerContents)
						if(entry["name"] == item.name)
							entry["volume"] += 1
							entry_found = TRUE
							break
					//new entry if non existent
					if(!entry_found)
						beakerContents += list(list("name" = item.name, "volume" = 1))

		beaker_data["contents"] = beakerContents
	.["beaker"] = beaker_data

/obj/machinery/chem_recipe_debug/ui_act(action, list/params, datum/tgui/ui, datum/ui_state/state)
	. = ..()
	if(.)
		return

	switch(action)
		if("forced_temp")
			var/target = params["target"]
			if(isnull(target))
				return

			target = text2num(target)
			if(isnull(target))
				return

			forced_temp = target
			return TRUE

		if("temp_mode")
			var/target = params["target"]
			if(isnull(target))
				return

			switch(target)
				if("Reaction Temp")
					temp_mode = USE_REACTION_TEMPERATURE
					return TRUE
				if("Forced Temp")
					temp_mode = USE_USER_TEMPERATURE
					return TRUE
				if("Minimum Temp")
					temp_mode = USE_MINIMUM_TEMPERATURE
					return TRUE
				if("Optimal Temp")
					temp_mode = USE_OPTIMAL_TEMPERATURE
					return TRUE
				if("Overheat Temp")
					temp_mode = USE_OVERHEAT_TEMPERATURE
					return TRUE

		if("forced_ph")
			var/target = params["target"]
			if(isnull(target))
				return

			target = text2num(target)
			if(isnull(target))
				return

			forced_ph = target
			return TRUE

		if("toggle_forced_ph")
			use_forced_ph = !use_forced_ph
			return TRUE

		if("forced_purity")
			var/target = params["target"]
			if(isnull(target))
				return

			target = text2num(target)
			if(isnull(target))
				return

			forced_purity = target
			return TRUE

		if("toggle_forced_purity")
			use_forced_purity = !use_forced_purity
			return TRUE

		if("volume_multiplier")
			var/target = params["target"]
			if(isnull(target))
				return

			target = text2num(target)
			if(isnull(target))
				return

			volume_multiplier = target
			return TRUE

		if("pick_reaction")
			var/mode = tgui_alert(usr, "Play all or a specific reaction?","Select Reaction", list("All", "Specific"))
			if(mode == "All")
				reactions_to_test.Cut()
				for(var/reaction as anything in all_reaction_list)
					reactions_to_test += all_reaction_list[reaction]
				current_reaction_index = 0
				return TRUE

			var/selected_reaction = tgui_input_list(ui.user, "Select Reaction", "Reaction", all_reaction_list)
			if(!selected_reaction)
				return

			var/datum/chemical_reaction/reaction = all_reaction_list[selected_reaction]
			if(!reaction)
				return

			reactions_to_test.Cut()
			reactions_to_test += reaction
			current_reaction_index = 0
			return TRUE

		if("reaction_mode")
			var/target = params["target"]
			if(isnull(target))
				return

			switch(target)
				if("Next Reaction")
					current_reaction_mode = PLAY_NEXT_REACTION
					return TRUE
				if("Previous Reaction")
					current_reaction_mode = PLAY_PREVIOUS_REACTION
					return TRUE
				if("Pick Reaction")
					current_reaction_mode = PLAY_USER_REACTION
					return TRUE

		if("start_reaction")
			var/datum/chemical_reaction/test_reaction

			//pick the reaction based on the reaction mode
			var/len = reactions_to_test.len
			if(len > 1)
				switch(current_reaction_mode)
					if(PLAY_NEXT_REACTION)
						current_reaction_index = (current_reaction_index + 1) % len
					if(PLAY_PREVIOUS_REACTION)
						current_reaction_index = max(current_reaction_index - 1, 1)
					if(PLAY_USER_REACTION)
						var/list/reaction_names = list()
						for(var/datum/chemical_reaction/reaction as anything in reactions_to_test)
							reaction_names += extract_reaction_name(reaction)
						if(!reaction_names.len)
							return

						var/selected_reaction = tgui_input_list(ui.user, "Select Reaction", "Reaction", reaction_names)
						if(!selected_reaction)
							return
						for(var/i = 1; i <= reaction_names.len; i++)
							if(selected_reaction == reaction_names[i])
								current_reaction_index = i
								break
				test_reaction = reactions_to_test[current_reaction_index]
			else if(len == 1)
				current_reaction_index = 1
				test_reaction = reactions_to_test[1]

			//clear the previous reaction stuff
			target_reagents.force_stop_reacting()
			target_reagents.clear_reagents()

			//If the reaction requires a specific container initialize & do other stuff accordingly
			target_reagents = reagents
			if(!QDELETED(required_container))
				UnregisterSignal(required_container.reagents, COMSIG_REAGENTS_REACTION_STEP)
				QDEL_NULL(required_container)
			if(!isnull(test_reaction.required_container))
				required_container = new test_reaction.required_container(src)
				required_container.create_reagents(MAXIMUM_HOLDER_VOLUME)
				target_reagents = required_container.reagents
				RegisterSignal(target_reagents, COMSIG_REAGENTS_REACTION_STEP, PROC_REF(on_reaction_step))

			//append everything required
			var/list/reagent_list = list()
			if(length(test_reaction.required_catalysts))
				reagent_list += test_reaction.required_catalysts
			if(length(test_reaction.required_reagents))
				reagent_list += test_reaction.required_reagents
			//now add the required reagents
			var/target_temperature
			switch(temp_mode)
				if(USE_REACTION_TEMPERATURE)
					target_temperature = DEFAULT_REAGENT_TEMPERATURE
				else
					target_temperature = decode_target_temperature()
			for(var/datum/reagent/_reagent as anything in reagent_list)
				var/vol_mul = volume_multiplier
				if(length(test_reaction.required_catalysts) && test_reaction.required_catalysts[_reagent.type])
					vol_mul = 1 //catalysts don't need to be present in large amounts

				//add the required reagents with the precise conditions
				target_reagents.add_reagent(
					_reagent,
					reagent_list[_reagent] * vol_mul,
					reagtemp = target_temperature,
					added_purity = use_forced_purity ? forced_purity : null,
					added_ph = use_forced_ph  ? forced_ph : null,
					no_react = TRUE
				)

				//add solid ingredients for soups
				if(istype(test_reaction, /datum/chemical_reaction/food/soup))
					var/datum/chemical_reaction/food/soup/soup_reaction = test_reaction
					var/obj/item/reagent_containers/cup/soup_pot/pot = required_container
					for(var/obj/item as anything in soup_reaction.required_ingredients)
						for(var/_ in 1 to soup_reaction.required_ingredients[item])
							LAZYADD(pot.added_ingredients, new item(pot))

			target_reagents.handle_reactions()
			return TRUE

		if("edit_reaction")
			var/selected_reaction = tgui_input_list(ui.user, "Select Reaction", "Reaction", all_reaction_list)
			if(!selected_reaction)
				return

			var/datum/chemical_reaction/reaction = all_reaction_list[selected_reaction]
			if(!reaction)
				return

			edit_reaction = reaction
			edit_var = initial(edit_var)
			return TRUE

		if("edit_var")
			var/target = params["target"]
			if(isnull(target))
				return
			if(isnull(decode_var(target)))
				return
			edit_var = target
			return TRUE

		if("edit_value")
			var/target = params["target"]
			if(isnull(target))
				return

			target = text2num(target)
			if(isnull(target))
				return

			edit_reaction.vars[decode_var(edit_var)] = target
			return TRUE

		if("reset_value")
			switch(edit_var)
				if("Required Temp")
					edit_reaction.required_temp = initial(edit_reaction.required_temp)
					return TRUE
				if("Optimal Temp")
					edit_reaction.optimal_temp = initial(edit_reaction.optimal_temp)
					return TRUE
				if("Overheat Temp")
					edit_reaction.overheat_temp = initial(edit_reaction.overheat_temp)
					return TRUE
				if("Optimal Min Ph")
					edit_reaction.optimal_ph_min = initial(edit_reaction.optimal_ph_min)
					return TRUE
				if("Optimal Max Ph")
					edit_reaction.optimal_ph_max = initial(edit_reaction.optimal_ph_max)
					return TRUE
				if("Ph Range")
					edit_reaction.determin_ph_range = initial(edit_reaction.determin_ph_range)
					return TRUE
				if("Temp Exp Factor")
					edit_reaction.temp_exponent_factor = initial(edit_reaction.temp_exponent_factor)
					return TRUE
				if("Ph Exp Factor")
					edit_reaction.ph_exponent_factor = initial(edit_reaction.ph_exponent_factor)
					return TRUE
				if("Thermic Constant")
					edit_reaction.thermic_constant = initial(edit_reaction.thermic_constant)
					return TRUE
				if("H Ion Release")
					edit_reaction.H_ion_release = initial(edit_reaction.H_ion_release)
					return TRUE
				if("Rate Up Limit")
					edit_reaction.rate_up_lim = initial(edit_reaction.rate_up_lim)
					return TRUE
				if("Purity Min")
					edit_reaction.purity_min = initial(edit_reaction.purity_min)
					return TRUE

		if("export")
			var/export = "[edit_reaction]\n"
			export += "\tis_cold_recipe = [edit_reaction.is_cold_recipe]\n"
			export += "\trequired_temp = [edit_reaction.required_temp]\n"
			export += "\toptimal_temp = [edit_reaction.optimal_temp]\n"
			export += "\toverheat_temp = [edit_reaction.overheat_temp]\n"
			export += "\toptimal_ph_min = [edit_reaction.optimal_ph_min]\n"
			export += "\toptimal_ph_max = [edit_reaction.optimal_ph_max]\n"
			export += "\tdetermin_ph_range = [edit_reaction.determin_ph_range]\n"
			export += "\ttemp_exponent_factor = [edit_reaction.temp_exponent_factor]\n"
			export += "\tph_exponent_factor = [edit_reaction.ph_exponent_factor]\n"
			export += "\tthermic_constant = [edit_reaction.thermic_constant]\n"
			export += "\tH_ion_release = [edit_reaction.H_ion_release]\n"
			export += "\trate_up_lim = [edit_reaction.rate_up_lim]\n"
			export += "\tpurity_min = [edit_reaction.purity_min]\n"

			var/dest = "[GLOB.log_directory]/chem_parse.txt"
			text2file(export, dest)
			tgui_alert(ui.user, "Saved to [dest]")

		if("eject")
			//initialize a new container for us
			if(QDELETED(container))
				if(QDELETED(required_container))
					container = new /obj/item/reagent_containers/cup/beaker/bluespace(src)
				else
					container = new required_container.type(src)

			//transfer all reagents & ingredients if we are using a soup pot
			container.reagents.clear_reagents()
			target_reagents.trans_to(container, target_reagents.total_volume)
			if(istype(container, /obj/item/reagent_containers/cup/soup_pot) && istype(required_container, /obj/item/reagent_containers/cup/soup_pot))
				var/obj/item/reagent_containers/cup/soup_pot/pot = container
				for(var/obj/item as anything in pot.added_ingredients)
					qdel(item)
				var/obj/item/reagent_containers/cup/soup_pot/holder = required_container
				for(var/obj/item as anything in holder.added_ingredients)
					item.forceMove(pot)
					LAZYADD(pot.added_ingredients, item)
			try_put_in_hand(container, ui.user)

			return TRUE

#undef USE_REACTION_TEMPERATURE
#undef USE_MINIMUM_TEMPERATURE
#undef USE_USER_TEMPERATURE
#undef USE_OPTIMAL_TEMPERATURE
#undef USE_OVERHEAT_TEMPERATURE
#undef PLAY_NEXT_REACTION
#undef PLAY_PREVIOUS_REACTION
#undef PLAY_USER_REACTION
#undef MAXIMUM_HOLDER_VOLUME
