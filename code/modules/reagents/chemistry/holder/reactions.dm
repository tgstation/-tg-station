/**
 * Handle any reactions possible in this holder
 * Also UPDATES the reaction list
 * High potential for infinite loopsa if you're editing this.
*/
/datum/reagents/proc/handle_reactions()
	if(QDELING(src))
		CRASH("[my_atom] is trying to handle reactions while being flagged for deletion. It presently has [length(reagent_list)] number of reactants in it. If that is over 0 then something terrible happened.")

	if(!length(reagent_list))//The liver is calling this method a lot, and is often empty of reagents so it's pointless busywork. It should be an easy fix, but I'm nervous about touching things beyond scope. Also since everything is so handle_reactions() trigger happy it might be a good idea having this check anyways.
		return FALSE

	if(flags & NO_REACT)
		if(is_reacting)
			force_stop_reacting() //Force anything that is trying to to stop
		return FALSE //Yup, no reactions here. No siree.

	if(is_reacting)//Prevent wasteful calculations
		if(!(datum_flags & DF_ISPROCESSING))//If we're reacting - but not processing (i.e. we've transferred)
			START_PROCESSING(SSreagents, src)
		if(!(has_changed_state()))
			return FALSE

#ifndef UNIT_TESTS
	// We assert that reagents will not need to react before the map is fully loaded
	// This is the best I can do, sorry :(
	if(!MC_RUNNING())
		return FALSE
#endif

	var/list/cached_reagents = reagent_list
	var/list/cached_reactions = GLOB.chemical_reactions_list_reactant_index
	var/datum/cached_my_atom = my_atom
	LAZYNULL(failed_but_capable_reactions)
	LAZYNULL(previous_reagent_list)

	. = 0
	var/list/possible_reactions = list()
	for(var/datum/reagent/reagent as anything in cached_reagents)
		LAZYADD(previous_reagent_list, reagent.type)
		// I am SO sorry
		reaction_loop:
			for(var/datum/chemical_reaction/reaction as anything in cached_reactions[reagent.type]) // Was a big list but now it should be smaller since we filtered it with our reagent id
				if(!reaction)
					continue

				if(!reaction.required_reagents)//Don't bring in empty ones
					continue

				var/granularity = 1
				if(!(reaction.reaction_flags & REACTION_INSTANT))
					granularity = CHEMICAL_QUANTISATION_LEVEL

				var/list/cached_required_reagents = reaction.required_reagents
				for(var/req_reagent in cached_required_reagents)
					if(!has_reagent(req_reagent, (cached_required_reagents[req_reagent] * granularity)))
						continue reaction_loop

				var/list/cached_required_catalysts = reaction.required_catalysts
				for(var/_catalyst in cached_required_catalysts)
					if(!has_reagent(_catalyst, (cached_required_catalysts[_catalyst] * granularity)))
						continue reaction_loop

				if(cached_my_atom)
					if(reaction.required_container)
						if(reaction.required_container_accepts_subtypes)
							if(!istype(cached_my_atom, reaction.required_container))
								continue
						else if(cached_my_atom.type != reaction.required_container)
							continue

					if(isliving(cached_my_atom) && !reaction.mob_react) //Makes it so certain chemical reactions don't occur in mobs
						continue

				else if(reaction.required_container)
					continue

				if(reaction.required_other && !reaction.pre_reaction_other_checks(src))
					continue

				// At this point, we've passed all the hard restrictions and entered into just the soft ones
				// So we're gonna start tracking reactions that COULD be completed on continue, instead of just exiting
				var/required_temp = reaction.required_temp
				var/is_cold_recipe = reaction.is_cold_recipe
				if(required_temp != 0 && (is_cold_recipe && chem_temp > required_temp) || (!is_cold_recipe && chem_temp < required_temp))
					LAZYADD(failed_but_capable_reactions, reaction)
					continue

				if(ph < reaction.optimal_ph_min - reaction.determin_ph_range && ph > reaction.optimal_ph_max + reaction.determin_ph_range)
					LAZYADD(failed_but_capable_reactions, reaction)
					continue

				possible_reactions += reaction

	//This is the point where we have all the possible reactions from a reagent/catalyst point of view, so we set up the reaction list
	for(var/datum/chemical_reaction/selected_reaction as anything in possible_reactions)
		if((selected_reaction.reaction_flags & REACTION_INSTANT) || (flags & REAGENT_HOLDER_INSTANT_REACT)) //If we have instant reactions, we process them here
			instant_react(selected_reaction)
			.++
		else
			var/exists = FALSE
			for(var/datum/equilibrium/E_exist as anything in reaction_list)
				if(ispath(E_exist.reaction.type, selected_reaction.type)) //Don't add duplicates
					exists = TRUE

			//Add it if it doesn't exist in the list
			if(!exists)
				is_reacting = TRUE//Prevent any on_reaction() procs from infinite looping
				var/datum/equilibrium/equilibrium = new (selected_reaction, src) //Otherwise we add them to the processing list.
				if(equilibrium.to_delete)//failed startup checks
					qdel(equilibrium)
				else
					//Adding is done in new(), deletion is in qdel
					equilibrium.reaction.on_reaction(src, equilibrium, equilibrium.multiplier)
					equilibrium.react_timestep(1)//Get an initial step going so there's not a delay between setup and start - DO NOT ADD THIS TO equilibrium.NEW()

	if(LAZYLEN(reaction_list))
		is_reacting = TRUE //We've entered the reaction phase - this is set here so any reagent handling called in on_reaction() doesn't cause infinite loops
		START_PROCESSING(SSreagents, src) //see process() to see how reactions are handled
	else
		is_reacting = FALSE

	TEST_ONLY_ASSERT(!. || MC_RUNNING(), "We reacted during subsystem init, that shouldn't be happening!")

/**
 * Checks to see if the reagents has a difference in reagents_list and previous_reagent_list (I.e. if there's a difference between the previous call and the last)
 * Also checks to see if the saved reactions in failed_but_capable_reactions can start as a result of temp/pH change
*/
/datum/reagents/proc/has_changed_state()
	//Check if reagents are different
	var/total_matching_reagents = 0
	for(var/reagent in previous_reagent_list)
		if(has_reagent(reagent))
			total_matching_reagents++
	if(total_matching_reagents != reagent_list.len)
		return TRUE

	//Check our last reactions
	for(var/datum/chemical_reaction/reaction as anything in failed_but_capable_reactions)
		if(reaction.is_cold_recipe)
			if(reaction.required_temp < chem_temp)
				return TRUE
		else
			if(reaction.required_temp < chem_temp)
				return TRUE
		if(((ph >= (reaction.optimal_ph_min - reaction.determin_ph_range)) && (ph <= (reaction.optimal_ph_max + reaction.determin_ph_range))))
			return TRUE
	return FALSE


/*
* Main Reaction loop handler, Do not call this directly
*
* Checks to see if there's a reaction, then processes over the reaction list, removing them if flagged
* If any are ended, it displays the reaction message and removes it from the reaction list
* If the list is empty at the end it finishes reacting.
* Arguments:
* * seconds_per_tick - the time between each time step
*/
/datum/reagents/process(seconds_per_tick)
	if(!is_reacting)
		force_stop_reacting()
		stack_trace("[src] | [my_atom] was forced to stop reacting. This might be unintentional.")
	//sum of output messages.
	var/list/mix_message = list()
	//Process over our reaction list
	//See equilibrium.dm for mechanics
	var/num_reactions = 0
	for(var/datum/equilibrium/equilibrium as anything in reaction_list)
		//Continue reacting
		equilibrium.react_timestep(seconds_per_tick)
		num_reactions++
		//if it's been flagged to delete
		if(equilibrium.to_delete)
			var/temp_mix_message = end_reaction(equilibrium)
			if(!text_in_list(temp_mix_message, mix_message))
				mix_message += temp_mix_message
			continue
		SSblackbox.record_feedback("tally", "chemical_reaction", 1, "[equilibrium.reaction.type] total reaction steps")
	if(num_reactions)
		SEND_SIGNAL(src, COMSIG_REAGENTS_REACTION_STEP, num_reactions, seconds_per_tick)

	if(length(mix_message) && !HAS_TRAIT(my_atom, TRAIT_SILENT_REACTIONS)) //This is only at the end
		my_atom.audible_message(span_notice("[icon2html(my_atom, viewers(DEFAULT_MESSAGE_RANGE, src))] [mix_message.Join()]"))

	if(!LAZYLEN(reaction_list))
		finish_reacting()
	else
		handle_reactions()

/*
* This ends a single instance of an ongoing reaction
*
* Arguments:
* * [equilibrium][datum/equilibrium] - the equilibrium that will be ended
* Returns:
* * mix_message - the associated mix message of a reaction
*/
/datum/reagents/proc/end_reaction(datum/equilibrium/equilibrium)
	equilibrium.reaction.reaction_finish(src, equilibrium, equilibrium.reacted_vol)
	if(!equilibrium.holder || !equilibrium.reaction) //Somehow I'm getting empty equilibrium. This is here to handle them
		LAZYREMOVE(reaction_list, equilibrium)
		qdel(equilibrium)
		stack_trace("The equilibrium datum currently processing in this reagents datum had a nulled holder or nulled reaction. src holder:[my_atom] || src type:[my_atom.type] ") //Shouldn't happen. Does happen
		return
	if(equilibrium.holder != src) //When called from Destroy() eqs are nulled in smoke. This is very strange. This is probably causing it to spam smoke because of the runtime interupting the removal.
		stack_trace("The equilibrium datum currently processing in this reagents datum had a desynced holder to the ending reaction. src holder:[my_atom] | equilibrium holder:[equilibrium.holder.my_atom] || src type:[my_atom.type] | equilibrium holder:[equilibrium.holder.my_atom.type]")
		LAZYREMOVE(reaction_list, equilibrium)

	var/reaction_message = null

	if (!isnull(my_atom) && !HAS_TRAIT(my_atom, TRAIT_SILENT_REACTIONS))
		reaction_message = equilibrium.reaction.mix_message
		if(equilibrium.reaction.mix_sound)
			playsound(get_turf(my_atom), equilibrium.reaction.mix_sound, 80, TRUE)
	qdel(equilibrium)
	update_total()

	return reaction_message

/*
* This stops the holder from processing at the end of a series of reactions (i.e. when all the equilibriums are completed)
* Also resets reaction variables to be null/empty/FALSE so that it can restart correctly in the future
*/
/datum/reagents/proc/finish_reacting()
	STOP_PROCESSING(SSreagents, src)
	is_reacting = FALSE
	LAZYNULL(previous_reagent_list) //reset it to 0 - because any change will be different now.
	update_total()

/*
* Force stops the current holder/reagents datum from reacting
* Calls end_reaction() for each equlilbrium datum in reaction_list and finish_reacting()
* Usually only called when a datum is transferred into a NO_REACT container
*/
/datum/reagents/proc/force_stop_reacting()
	var/list/mix_message = list()
	for(var/datum/equilibrium/equilibrium as anything in reaction_list)
		mix_message += end_reaction(equilibrium)
	if(my_atom && length(mix_message))
		my_atom.audible_message(span_notice("[icon2html(my_atom, viewers(DEFAULT_MESSAGE_RANGE, src))] [mix_message.Join()]"))
	finish_reacting()

/*
* Force stops a specific reagent's associated reaction if it exists
*
* Returns TRUE if it stopped something, FALSE if it didn't
* Arguments:
* * reagent - the reagent PRODUCT that we're seeking reactions for, any and all found will be shut down
*/
/datum/reagents/proc/force_stop_reagent_reacting(datum/reagent/reagent)
	var/any_stopped = FALSE
	var/list/mix_message = list()
	for(var/datum/equilibrium/equilibrium as anything in reaction_list)
		for(var/result in equilibrium.reaction.results)
			if(result == reagent.type)
				mix_message += end_reaction(equilibrium)
				any_stopped = TRUE
	if(length(mix_message) && !HAS_TRAIT(my_atom, TRAIT_SILENT_REACTIONS))
		my_atom.audible_message(span_notice("[icon2html(my_atom, viewers(DEFAULT_MESSAGE_RANGE, src))][mix_message.Join()]"))
	return any_stopped

/*
* Transfers the reaction_list to a new reagents datum
*
* Arguments:
* * target - the datum/reagents that this src is being transferred into
*/
/datum/reagents/proc/transfer_reactions(datum/reagents/target)
	if(QDELETED(target))
		CRASH("transfer_reactions() had a [target] ([target.type]) passed to it when it was set to qdel, or it isn't a reagents datum.")
	if(!reaction_list)
		return
	for(var/datum/equilibrium/reaction_source as anything in reaction_list)
		var/exists = FALSE
		for(var/datum/equilibrium/reaction_target as anything in target.reaction_list) //Don't add duplicates
			if(reaction_source.reaction.type == reaction_target.reaction.type)
				exists = TRUE
		if(exists)
			continue
		if(!reaction_source.holder)
			CRASH("reaction_source is missing a holder in transfer_reactions()!")

		var/datum/equilibrium/new_E = new (reaction_source.reaction, target)//addition to reaction_list is done in new()
		if(new_E.to_delete)//failed startup checks
			qdel(new_E)

	target.previous_reagent_list = LAZYLISTDUPLICATE(previous_reagent_list)
	target.is_reacting = is_reacting

/**
 * Old reaction mechanics, edited to work on one only
 * This is changed from the old - purity of the reagents will affect yield
 *
 * Arguments
 * * [selected_reaction][datum/chemical_reaction] - the chemical reaction to finish instantly
 */
/datum/reagents/proc/instant_react(datum/chemical_reaction/selected_reaction)
	var/list/cached_required_reagents = selected_reaction.required_reagents
	var/list/cached_results = selected_reaction.results
	var/datum/cached_my_atom = my_atom

	//find how much ration of products to create
	var/multiplier = INFINITY
	for(var/datum/reagent/requirement as anything in cached_required_reagents)
		multiplier = min(multiplier, get_reagent_amount(requirement) / cached_required_reagents[requirement])
	multiplier = round(multiplier, CHEMICAL_QUANTISATION_LEVEL)
	if(!multiplier)//Incase we're missing reagents - usually from on_reaction being called in an equlibrium when the results.len == 0 handler catches a misflagged reaction
		return FALSE

	//average purity to be used in scaling the yield of products formed
	var/average_purity = get_average_purity()

	//remove the required reagents
	for(var/datum/reagent/requirement as anything in cached_required_reagents)//this is not an object
		remove_reagent(requirement, cached_required_reagents[requirement] * multiplier)

	//add the result reagents whose yield depend on the average purity
	var/yield
	for(var/datum/reagent/product as anything in cached_results)
		yield = cached_results[product] * multiplier * average_purity
		SSblackbox.record_feedback("tally", "chemical_reaction", yield, product)
		add_reagent(product, yield, null, chem_temp, average_purity)

	//play sounds on the target atom
	var/list/seen = viewers(4, get_turf(my_atom))
	var/iconhtml = icon2html(cached_my_atom, seen)
	if(cached_my_atom)
		if(!ismob(cached_my_atom) && !HAS_TRAIT(my_atom, TRAIT_SILENT_REACTIONS)) // No bubbling mobs
			if(selected_reaction.mix_sound)
				playsound(get_turf(cached_my_atom), selected_reaction.mix_sound, 80, TRUE)
			my_atom.audible_message(span_notice("[iconhtml] [selected_reaction.mix_message]"))

		//use slime extract
		if(istype(cached_my_atom, /obj/item/slime_extract))
			var/obj/item/slime_extract/extract = my_atom
			extract.extract_uses--
			if(extract.extract_uses <= 0) // give the notification that the slime core is dead
				my_atom.visible_message(span_notice("[iconhtml] \The [my_atom]'s power is consumed in the reaction."))
				extract.name = "used slime extract"
				extract.desc = "This extract has been used up."
				extract.grind_results.Cut()

	//finish the reaction
	selected_reaction.on_reaction(src, null, multiplier)
