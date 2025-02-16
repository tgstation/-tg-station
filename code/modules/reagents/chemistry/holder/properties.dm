//============================VOLUME======================================
/// Is this holder full or not
/datum/reagents/proc/holder_full()
	return total_volume >= maximum_volume

/**
 * Get the amount of this reagent or the sum of all its subtypes if specified
 * Arguments
 * * [reagent][datum/reagent] - the typepath of the reagent to look for
 * * type_check - see defines under reagents.dm file
 */
/datum/reagents/proc/get_reagent_amount(datum/reagent/reagent, type_check = REAGENT_STRICT_TYPE)
	if(!ispath(reagent))
		stack_trace("invalid path passed to get_reagent_amount [reagent]")
		return 0
	var/list/cached_reagents = reagent_list

	var/total_amount = 0
	for(var/datum/reagent/cached_reagent as anything in cached_reagents)
		switch(type_check)
			if(REAGENT_STRICT_TYPE)
				if(cached_reagent.type != reagent)
					continue
			if(REAGENT_PARENT_TYPE) //to simulate typesof() which returns the type and then child types
				if(cached_reagent.type != reagent && type2parent(cached_reagent.type) != reagent)
					continue
			else
				if(!istype(cached_reagent, reagent))
					continue

		total_amount += cached_reagent.volume

		//short cut to break when we have found our one exact type
		if(type_check == REAGENT_STRICT_TYPE)
			break

	return total_amount


//======================PH(clamped between 0->14)========================================
/*
* Adjusts the base pH of all of the reagents in a beaker
*
* - moves it towards acidic
* + moves it towards basic
* Arguments:
* * value - How much to adjust the base pH by
*/
/datum/reagents/proc/adjust_all_reagents_ph(value)
	for(var/datum/reagent/reagent as anything in reagent_list)
		reagent.ph = clamp(reagent.ph + value, CHEMICAL_MIN_PH, CHEMICAL_MAX_PH)

/*
* Adjusts the base pH of a specific type
*
* - moves it towards acidic
* + moves it towards basic
* Arguments:
* * input_reagent - type path of the reagent
* * value - How much to adjust the base pH by
*/
/datum/reagents/proc/adjust_specific_reagent_ph(input_reagent, value)
	var/datum/reagent/reagent = has_reagent(input_reagent)
	if(!reagent) //We can call this with missing reagents.
		return FALSE
	reagent.ph = clamp(reagent.ph + value, CHEMICAL_MIN_PH, CHEMICAL_MAX_PH)


//==========================TEMPERATURE======================================
/// Returns the total heat capacity for all of the reagents currently in this holder.
/datum/reagents/proc/heat_capacity()
	. = 0
	var/list/cached_reagents = reagent_list //cache reagents
	for(var/datum/reagent/reagent in cached_reagents)
		. += reagent.specific_heat * reagent.volume

/** Adjusts the thermal energy of the reagents in this holder by an amount.
 *
 * Arguments:
 * - delta_energy: The amount to change the thermal energy by.
 * - min_temp: The minimum temperature that can be reached.
 * - max_temp: The maximum temperature that can be reached.
 */
/datum/reagents/proc/adjust_thermal_energy(delta_energy, min_temp = 2.7, max_temp = 1000)
	var/heat_capacity = heat_capacity()
	if(!heat_capacity)
		return // no div/0 please
	set_temperature(clamp(chem_temp + (delta_energy / heat_capacity), min_temp, max_temp))

/** Sets the temperature of this reagent container to a new value.
 *
 * Handles setter signals.
 *
 * Arguments:
 * - _temperature: The new temperature value.
 */
/datum/reagents/proc/set_temperature(_temperature)
	if(_temperature == chem_temp)
		return

	. = chem_temp
	chem_temp = clamp(_temperature, 0, CHEMICAL_MAXIMUM_TEMPERATURE)
	SEND_SIGNAL(src, COMSIG_REAGENTS_TEMP_CHANGE, _temperature, .)

//==============================PURITY==========================================
/**
 * Get the purity of this reagent
 * Arguments
 * * [reagent][datum/reagent] - the typepath of the specific reagent to get purity of
 */
/datum/reagents/proc/get_reagent_purity(datum/reagent/reagent)
	if(!ispath(reagent))
		stack_trace("invalid reagent typepath passed to get_reagent_purity [reagent]")
		return 0

	var/list/cached_reagents = reagent_list
	for(var/datum/reagent/cached_reagent as anything in cached_reagents)
		if(cached_reagent.type == reagent)
			return round(cached_reagent.purity, 0.01)

	return 0

/**
 * Get the average purity of all reagents (or all subtypes of provided typepath)
 * Arguments
 * * [parent_type][datum/reagent] - the typepath of specific reagents to look for
 */
/datum/reagents/proc/get_average_purity(datum/reagent/parent_type = null)
	if(!isnull(parent_type) && !ispath(parent_type))
		stack_trace("illegal path passed to get_average_purity [parent_type]")
		return FALSE

	var/total_amount
	var/weighted_purity
	var/list/cached_reagents = reagent_list
	for(var/datum/reagent/reagent as anything in cached_reagents)
		if(!isnull(parent_type) && !istype(reagent, parent_type))
			continue
		total_amount += reagent.volume
		weighted_purity += reagent.volume * reagent.purity

	return weighted_purity / total_amount

/**
 * Directly set the purity of all contained reagents to a new value
 * Arguments
 * * new_purity - the new purity value
 */
/datum/reagents/proc/set_all_reagents_purity(new_purity = 0)
	var/list/cached_reagents = reagent_list
	for(var/datum/reagent/cached_reagent as anything in cached_reagents)
		cached_reagent.purity = max(0, new_purity)


//================================TASTE===================================================
/**
 * Returns what this holder's reagents taste like
 *
 * Arguments:
 * * mob/living/taster - who is doing the tasting. Some mobs can pick up specific flavours.
 * * minimum_percent - the lower the minimum percent, the more sensitive the message is.
 */
/datum/reagents/proc/generate_taste_message(mob/living/taster, minimum_percent)
	return generate_reagents_taste_message(reagent_list, taster, minimum_percent)
