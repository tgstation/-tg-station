/// A single reagent
/datum/reagent
	/// datums don't have names by default
	var/name = ""
	/// nor do they have descriptions
	var/description = ""
	///J/(K*mol)
	var/specific_heat = SPECIFIC_HEAT_DEFAULT
	/// used by taste messages
	var/taste_description = "metaphorical salt"
	///how this taste compares to others. Higher values means it is more noticable
	var/taste_mult = 1
	/// reagent holder this belongs to
	var/datum/reagents/holder = null
	/// Special data associated with the reagent that will be passed on upon transfer to a new holder.
	var/list/data
	/// increments everytime on_mob_life is called
	var/current_cycle = 0
	///pretend this is moles
	var/volume = 0
	/// pH of the reagent
	var/ph = 7
	///Purity of the reagent - for use with internal reaction mechanics only. Use below (creation_purity) if you're writing purity effects into a reagent's use mechanics.
	var/purity = 1
	///the purity of the reagent on creation (i.e. when it's added to a mob and its purity split it into 2 chems; the purity of the resultant chems are kept as 1, this tracks what the purity was before that)
	var/creation_purity = 1
	///The molar mass of the reagent - if you're adding a reagent that doesn't have a recipe, just add a random number between 10 - 800. Higher numbers are "harder" but it's mostly arbitary.
	var/mass
	/// color it looks in containers etc
	var/color = COLOR_BLACK // rgb: 0, 0, 0
	///how fast the reagent is metabolized by the mob
	var/metabolization_rate = REAGENTS_METABOLISM
	/// above this overdoses happen
	var/overdose_threshold = 0
	/// You fucked up and this is now triggering its overdose effects, purge that shit quick.
	var/overdosed = FALSE
	///if false stops metab in liverless mobs
	var/self_consuming = FALSE
	///affects how far it travels when sprayed
	var/reagent_weight = 1
	///is it currently metabolizing
	var/metabolizing = FALSE
	/// Are we from a material? We might wanna know that for special stuff. Like metalgen. Is replaced with a ref of the material on New()
	var/datum/material/material
	///A list of causes why this chem should skip being removed, if the length is 0 it will be removed from holder naturally, if this is >0 it will not be removed from the holder.
	var/list/reagent_removal_skip_list = list()
	///The set of exposure methods this penetrates skin with.
	var/penetrates_skin = VAPOR
	/// See fermi_readme.dm REAGENT_DEAD_PROCESS, REAGENT_DONOTSPLIT, REAGENT_INVISIBLE, REAGENT_SNEAKYNAME, REAGENT_SPLITRETAINVOL, REAGENT_CANSYNTH, REAGENT_IMPURE
	var/chemical_flags = NONE
	/// If the impurity is below 0.5, replace ALL of the chem with inverse_chem upon metabolising
	var/inverse_chem_val = 0.25
	/// What chem is metabolised when purity is below inverse_chem_val
	var/inverse_chem = /datum/reagent/inverse
	///what chem is made at the end of a reaction IF the purity is below the recipies purity_min at the END of a reaction only
	///Thermodynamic vars
	///How hot this reagent burns when it's on fire - null means it can't burn
	var/burning_temperature = null
	///How much is consumed when it is burnt per second
	var/burning_volume = 0.5
	///Assoc list with key type of addiction this reagent feeds, and value amount of addiction points added per unit of reagent metabolzied (which means * REAGENTS_METABOLISM every life())
	var/list/addiction_types = null
	/// The affected organ_flags, if the reagent damages/heals organ damage of an affected mob.
	/// See "Organ defines for carbon mobs" in /code/_DEFINES/surgery.dm
	var/affected_organ_flags = ORGAN_ORGANIC
	/// The affected bodytype, if the reagent damages/heals bodyparts (Brute/Fire) of an affected mob.
	/// See "Bodytype defines" in /code/_DEFINES/mobs.dm
	var/affected_bodytype = BODYTYPE_ORGANIC
	/// The affected biotype, if the reagent damages/heals toxin damage of an affected mob.
	/// See "Mob bio-types flags" in /code/_DEFINES/mobs.dm
	var/affected_biotype = MOB_ORGANIC
	/// The affected respiration type, if the reagent damages/heals oxygen damage of an affected mob.
	/// See "Mob bio-types flags" in /code/_DEFINES/mobs.dm
	var/affected_respiration_type = ALL
	/// A list of traits to apply while the reagent is being metabolized.
	var/list/metabolized_traits
	/// A list of traits to apply while the reagent is in a mob.
	var/list/added_traits
	/// Multiplier of the amount purged by reagents such as calomel, multiver, syniver etc.
	var/purge_multiplier = 1

	///The default reagent container for the reagent, used for icon generation
	var/obj/default_container = /obj/item/reagent_containers/cup/bottle

	// Used for restaurants.
	///The amount a robot will pay for a glass of this (20 units but can be higher if you pour more, be frugal!)
	var/glass_price
	/// Icon for fallback item displayed in a tourist's thought bubble for if this reagent had no associated glass_style datum.
	var/fallback_icon
	/// Icon state for fallback item displayed in a tourist's thought bubble for if this reagent had no associated glass_style datum.
	var/fallback_icon_state
	/// When ordered in a restaurant, what custom order do we create?
	var/restaurant_order = /datum/custom_order/reagent/drink

/datum/reagent/New()
	SHOULD_CALL_PARENT(TRUE)
	. = ..()

	if(material)
		material = GET_MATERIAL_REF(material)
	if(glass_price)
		AddElement(/datum/element/venue_price, glass_price)
	if(!mass)
		mass = rand(10, 800)

/// This should only be called by the holder, so it's already handled clearing its references
/datum/reagent/Destroy()
	. = ..()
	holder = null

/// Applies this reagent to an [/atom]
/datum/reagent/proc/expose_atom(atom/exposed_atom, reac_volume)
	SHOULD_CALL_PARENT(TRUE)

	. = 0
	. |= SEND_SIGNAL(src, COMSIG_REAGENT_EXPOSE_ATOM, exposed_atom, reac_volume)
	. |= SEND_SIGNAL(exposed_atom, COMSIG_ATOM_EXPOSE_REAGENT, src, reac_volume)

/// Applies this reagent to a [/mob/living]
/datum/reagent/proc/expose_mob(mob/living/exposed_mob, methods=TOUCH, reac_volume, show_message = TRUE, touch_protection = 0)
	SHOULD_CALL_PARENT(TRUE)

	. = SEND_SIGNAL(src, COMSIG_REAGENT_EXPOSE_MOB, exposed_mob, methods, reac_volume, show_message, touch_protection)

	if(isnull(exposed_mob.reagents)) // lots of simple mobs do not have a reagents holder
		return

	if(penetrates_skin & methods) // models things like vapors which penetrate the skin
		var/amount = round(reac_volume * clamp((1 - touch_protection), 0, 1), 0.1)
		if(amount >= 0.5)
			exposed_mob.reagents.add_reagent(type, amount, added_purity = purity)

/// Applies this reagent to an [/obj]
/datum/reagent/proc/expose_obj(obj/exposed_obj, reac_volume, methods=TOUCH, show_message=TRUE)
	SHOULD_CALL_PARENT(TRUE)

	return SEND_SIGNAL(src, COMSIG_REAGENT_EXPOSE_OBJ, exposed_obj, reac_volume, methods, show_message)

/// Applies this reagent to a [/turf]
/datum/reagent/proc/expose_turf(turf/exposed_turf, reac_volume)
	SHOULD_CALL_PARENT(TRUE)

	return SEND_SIGNAL(src, COMSIG_REAGENT_EXPOSE_TURF, exposed_turf, reac_volume)

///Called whenever a reagent is on fire, or is in a holder that is on fire. (WIP)
/datum/reagent/proc/burn(datum/reagents/holder)
	return

/**
 * Ticks on mob Life() for as long as the reagent remains in the mob's reagents.
 *
 * Usage: Parent should be called first using . = ..()
 *
 * Exceptions: If the holder var needs to be accessed, call the parent afterward that as it can become null if the reagent is fully removed.
 *
 * Returns: UPDATE_MOB_HEALTH only if you need to update the health of a mob (this is only needed when damage is dealt to the mob)
 *
 * Arguments
 * * mob/living/carbon/affected_mob - the mob which the reagent currently is inside of
 * * seconds_per_tick - the time in server seconds between proc calls (when performing normally it will be 2)
 * * times_fired - the number of times the owner's Life() tick has been called aka The number of times SSmobs has fired
 *
 */
/datum/reagent/proc/on_mob_life(mob/living/carbon/affected_mob, seconds_per_tick, times_fired)
	SHOULD_CALL_PARENT(TRUE)

///Metabolizes a portion of the reagent after on_mob_life() is called
/datum/reagent/proc/metabolize_reagent(mob/living/carbon/affected_mob, seconds_per_tick, times_fired)
	if(length(reagent_removal_skip_list))
		return
	if(isnull(holder))
		return

	var/metabolizing_out = metabolization_rate * seconds_per_tick
	if(!(chemical_flags & REAGENT_UNAFFECTED_BY_METABOLISM))
		if(chemical_flags & REAGENT_REVERSE_METABOLISM)
			metabolizing_out /= affected_mob.metabolism_efficiency
		else
			metabolizing_out *= affected_mob.metabolism_efficiency

	holder.remove_reagent(type, metabolizing_out)


/// Called in burns.dm *if* the reagent has the REAGENT_AFFECTS_WOUNDS process flag
/datum/reagent/proc/on_burn_wound_processing(datum/wound/burn/flesh/burn_wound)
	return

/*
Used to run functions before a reagent is transferred. Returning TRUE will block the transfer attempt.
Primarily used in reagents/reaction_agents
*/
/datum/reagent/proc/intercept_reagents_transfer(datum/reagents/target, amount)
	return FALSE

///Called after a reagent is transferred
/datum/reagent/proc/on_transfer(atom/A, methods=TOUCH, trans_volume)
	return

/// Called when this reagent is first added to a mob
/datum/reagent/proc/on_mob_add(mob/living/affected_mob, amount)
	// Scale the overdose threshold of the chem by the difference between the default and creation purity.
	overdose_threshold += (src.creation_purity - initial(purity)) * overdose_threshold
	if(added_traits)
		affected_mob.add_traits(added_traits, "base:[type]")

/// Called when this reagent is removed while inside a mob
/datum/reagent/proc/on_mob_delete(mob/living/affected_mob)
	affected_mob.clear_mood_event("[type]_overdose")
	REMOVE_TRAITS_IN(affected_mob, "base:[type]")

/// Called when this reagent first starts being metabolized by a liver
/datum/reagent/proc/on_mob_metabolize(mob/living/affected_mob)
	SHOULD_CALL_PARENT(TRUE)
	if(metabolized_traits)
		affected_mob.add_traits(metabolized_traits, "metabolize:[type]")

/// Called when this reagent stops being metabolized by a liver
/datum/reagent/proc/on_mob_end_metabolize(mob/living/affected_mob)
	SHOULD_CALL_PARENT(TRUE)
	REMOVE_TRAITS_IN(affected_mob, "metabolize:[type]")

/**
 * Called when a reagent is inside of a mob when they are dead if the reagent has the REAGENT_DEAD_PROCESS flag
 * Returning UPDATE_MOB_HEALTH will cause updatehealth() to be called on the holder mob by /datum/reagents/proc/metabolize.
 */
/datum/reagent/proc/on_mob_dead(mob/living/carbon/affected_mob, seconds_per_tick)
	SHOULD_CALL_PARENT(TRUE)

/// Called after add_reagents creates a new reagent.
/datum/reagent/proc/on_new(data)
	if(data)
		src.data = data

/// Called when two reagents of the same are mixing.
/datum/reagent/proc/on_merge(data, amount)
	return

/// Called if the reagent has passed the overdose threshold and is set to be triggering overdose effects. Returning UPDATE_MOB_HEALTH will cause updatehealth() to be called on the holder mob by /datum/reagents/proc/metabolize.
/datum/reagent/proc/overdose_process(mob/living/affected_mob, seconds_per_tick, times_fired)
	return

/// Called when an overdose starts. Returning UPDATE_MOB_HEALTH will cause updatehealth() to be called on the holder mob by /datum/reagents/proc/metabolize.
/datum/reagent/proc/overdose_start(mob/living/affected_mob)
	to_chat(affected_mob, span_userdanger("You feel like you took too much of [name]!"))
	affected_mob.add_mood_event("[type]_overdose", /datum/mood_event/overdose, name)
	return

/**
 * Called when this chemical is processed in a hydroponics tray.
 *
 * Can affect plant's health, stats, or cause the plant to react in certain ways.
 */
/datum/reagent/proc/on_hydroponics_apply(obj/machinery/hydroponics/mytray, mob/user)
	return

/// Should return a associative list where keys are taste descriptions and values are strength ratios
/datum/reagent/proc/get_taste_description(mob/living/taster)
	if(isnull(taster) || !HAS_TRAIT(taster, TRAIT_DETECTIVES_TASTE))
		return list("[taste_description]" = 1)
	return list("[LOWER_TEXT(name)]" = 1)

/**
 * Used when you want the default reagents purity to be equal to the normal effects
 * (i.e. if default purity is 0.75, and your reacted purity is 1, then it will return 1.33)
 *
 * Arguments
 * * normalise_num_to - what number/purity value you're normalising to. If blank it will default to the compile value of purity for this chem
 * * creation_purity - creation_purity override, if desired. This is the purity of the reagent that you're normalising from.
 */
/datum/reagent/proc/normalise_creation_purity(normalise_num_to, creation_purity)
	if(!normalise_num_to)
		normalise_num_to = initial(purity)
	if(!creation_purity)
		creation_purity = src.creation_purity
	return creation_purity / normalise_num_to

/**
 * Gets the inverse purity of this reagent. Mostly used when converting from a normal reagent to its inverse one.
 *
 * Arguments
 * * purity - Overrides the purity used for determining the inverse purity.
 */
/datum/reagent/proc/get_inverse_purity(purity)
	if(!inverse_chem || !inverse_chem_val)
		return 0
	if(!purity)
		purity = src.purity
	return min(1-inverse_chem_val + purity + 0.01, 1) //Gives inverse reactions a 1% purity threshold for being 100% pure to appease players with OCD.

///Called when feeding a fish. If TRUE is returned, a portion of reagent will be consumed.
/datum/reagent/proc/used_on_fish(obj/item/fish/fish)
	return FALSE

/**
 * Input a reagent_list, outputs pretty readable text!
 * Default output will be formatted as
 * * water, 5 | silicon, 6 | soup, 4 | space lube, 8
 *
 * * names_only will remove the amount displays, showing
 * * water | silicon | soup | space lube
 *
 * * join_text will alter the text between reagents
 * * setting to ", " will result in
 * * water, 5, silicon, 6, soup, 4, space lube, 8
 *
 * * final_and should be combined with the above. will format as
 * * water, 5, silicon, 6, soup, 4, and space lube, 8
 *
 * * capitalize_names will result in
 * * Water, 5 | Silicon, 6 | Soup, 4 | Space lube, 8
 *
 * * * use (reagents.reagent_list, names_only, join_text = ", ", final_and, capitalize_names) for the formatting
 * * * Water, Silicon, Soup, and Space Lube
 */
/proc/pretty_string_from_reagent_list(list/reagent_list, names_only, join_text = " | ", final_and, capitalize_names)
	//Convert reagent list to a printable string for logging etc
	var/list/reagent_strings = list()
	var/reagents_left = reagent_list.len
	var/intial_list_length = reagents_left
	for (var/datum/reagent/reagent as anything in reagent_list)
		reagents_left--
		if(final_and && intial_list_length > 1 && reagents_left == 0)
			reagent_strings += "and [capitalize_names ? capitalize(reagent.name) : reagent.name][names_only ? null : ", [reagent.volume]"]"
		else
			reagent_strings += "[capitalize_names ? capitalize(reagent.name) : reagent.name][names_only ? null : ", [reagent.volume]"]"

	return reagent_strings.Join(join_text)
