// ********************************************************
// Here's all the seeds (plants) that can be used in hydro
// ********************************************************

/obj/item/seeds
	icon = 'icons/obj/service/hydroponics/seeds.dmi'
	icon_state = "seed" // Unknown plant seed - these shouldn't exist in-game.
	worn_icon_state = "seed"
	w_class = WEIGHT_CLASS_TINY
	resistance_flags = FLAMMABLE
	/// Name of plant when planted.
	var/plantname = "Plants"
	/// A type path. The thing that is created when the plant is harvested.
	var/obj/item/product
	///Describes the product on the product path.
	var/productdesc
	/// Used to update icons. Should match the name in the sprites unless all icon_* are overridden.
	var/species = ""
	///the file that stores the sprites of the growing plant from this seed.
	var/growing_icon = 'icons/obj/service/hydroponics/growing.dmi'
	/// Used to override grow icon (default is `"[species]-grow"`). You can use one grow icon for multiple closely related plants with it.
	var/icon_grow
	/// Used to override dead icon (default is `"[species]-dead"`). You can use one dead icon for multiple closely related plants with it.
	var/icon_dead
	/// Used to override harvest icon (default is `"[species]-harvest"`). If null, plant will use `[icon_grow][growthstages]`.
	var/icon_harvest
	/// Used to offset the plant sprite so that it appears at proper height in the tray
	var/plant_icon_offset = 8
	/// How long before the plant begins to take damage from age.
	var/lifespan = 25
	/// Amount of health the plant has.
	var/endurance = 15
	/// Used to determine which sprite to switch to when growing.
	var/maturation = 6
	/// Changes the amount of time needed for a plant to become harvestable.
	var/production = 6
	/// Amount of growns created per harvest. If is -1, the plant/shroom/weed is never meant to be harvested.
	var/yield = 3
	/// The 'power' of a plant. Generally effects the amount of reagent in a plant, also used in other ways.
	var/potency = 10
	/// Amount of growth sprites the plant has.
	var/growthstages = 6
	// Chance that a plant will mutate in each stage of its life.
	var/instability = 5
	/// How rare the plant is. Used for giving points to cargo when shipping off to CentCom.
	var/rarity = 0
	/// The type of plants that this plant can mutate into.
	var/list/mutatelist
	/// Starts as a list of paths, is converted to a list of types on init. Plant gene datums are stored here, see plant_genes.dm for more info.
	var/list/genes = list()
	/// A list of reagents to add to product.
	var/list/reagents_add
	// Format: /datum/reagent/type = potency multiplier
	// Stronger reagents must always come first to avoid being displaced by weaker ones.
	// Total amount of any reagent in plant is calculated by formula: max(round(potency * multiplier), 1)
	///If the chance below passes, then this many weeds sprout during growth
	var/weed_rate = 1
	///Percentage chance per tray update to grow weeds
	var/weed_chance = 5
	///Determines if the plant has had a graft removed or not.
	var/grafted = FALSE
	///Type-path of trait to be applied when grafting a plant.
	var/graft_gene
	///Determines if the plant should be allowed to mutate early at 30+ instability.
	var/seed_flags = MUTATE_EARLY

/obj/item/seeds/Initialize(mapload, nogenes = FALSE)
	. = ..()
	pixel_x = base_pixel_x + rand(-8, 8)
	pixel_y = base_pixel_y + rand(-8, 8)

	if(!icon_grow)
		icon_grow = "[species]-grow"

	if(!icon_dead)
		icon_dead = "[species]-dead"

	if(!icon_harvest && !get_gene(/datum/plant_gene/trait/plant_type/fungal_metabolism) && yield != -1)
		icon_harvest = "[species]-harvest"

	if(!nogenes)
		for(var/plant_gene in genes)
			if(ispath(plant_gene))
				genes -= plant_gene
				genes += new plant_gene

		// Go through all traits in their genes and call on_new_seed from them.
		for(var/datum/plant_gene/trait/traits in genes)
			traits.on_new_seed(src)

		for(var/reag_id in reagents_add)
			genes += new /datum/plant_gene/reagent(reag_id, reagents_add[reag_id])
		reagents_from_genes() //quality coding

	var/static/list/hovering_item_typechecks = list(
		/obj/item/plant_analyzer = list(
			SCREENTIP_CONTEXT_LMB = "Scan seed stats",
			SCREENTIP_CONTEXT_RMB = "Scan seed chemicals"
		),
	)

	AddElement(/datum/element/contextual_screentip_item_typechecks, hovering_item_typechecks)

/obj/item/seeds/Destroy()
	// No AS ANYTHING here, because the list/genes could have typepaths in it.
	for(var/datum/plant_gene/gene in genes)
		gene.on_removed(src)
		qdel(gene)

	genes.Cut()
	return ..()

/obj/item/seeds/examine(mob/user)
	. = ..()
	. += span_notice("Use a pen on it to rename it or change its description.")
	if(reagents_add && user.can_see_reagents())
		. += span_notice("- Plant Reagents -")
		for(var/datum/plant_gene/reagent/reagent_gene in genes)
			. += span_notice("- [reagent_gene.get_name()] -")

/// Copy all the variables from one seed to a new instance of the same seed and return it.
/obj/item/seeds/proc/Copy()
	var/obj/item/seeds/copy_seed = new type(null, TRUE)
	// Copy all the stats
	copy_seed.lifespan = lifespan
	copy_seed.endurance = endurance
	copy_seed.maturation = maturation
	copy_seed.production = production
	copy_seed.yield = yield
	copy_seed.potency = potency
	copy_seed.instability = instability
	copy_seed.weed_rate = weed_rate
	copy_seed.weed_chance = weed_chance
	copy_seed.name = name
	copy_seed.plantname = plantname
	copy_seed.desc = desc
	copy_seed.productdesc = productdesc
	copy_seed.genes = list()
	for(var/datum/plant_gene/gene in genes)
		var/datum/plant_gene/copied_gene = gene.Copy()
		copy_seed.genes += copied_gene
		copied_gene.on_new_seed(copy_seed)

	copy_seed.reagents_add = reagents_add.Copy() // Faster than grabbing the list from genes.
	return copy_seed

/obj/item/seeds/proc/get_gene(typepath)
	return (locate(typepath) in genes)

/obj/item/seeds/proc/reagents_from_genes()
	reagents_add = list()
	for(var/datum/plant_gene/reagent/R in genes)
		reagents_add[R.reagent_id] = R.rate

/obj/item/seeds/proc/mutate(lifemut = 2, endmut = 5, productmut = 1, yieldmut = 2, potmut = 25, wrmut = 2, wcmut = 5, traitmut = 0, stabmut = 3)
	adjust_lifespan(rand(-lifemut,lifemut))
	adjust_endurance(rand(-endmut,endmut))
	adjust_production(rand(-productmut,productmut))
	adjust_yield(rand(-yieldmut,yieldmut))
	adjust_potency(rand(-potmut,potmut))
	adjust_instability(rand(-stabmut,stabmut))
	adjust_weed_rate(rand(-wrmut, wrmut))
	adjust_weed_chance(rand(-wcmut, wcmut))
	if(prob(traitmut))
		if(prob(50))
			add_random_traits(1, 1)
		else
			add_random_reagents(1, 1)



/obj/item/seeds/bullet_act(obj/projectile/proj) //Works with the Somatoray to modify plant variables.
	if(!istype(proj, /obj/projectile/energy/flora/yield))
		return ..()
	var/rating = 1
	if(istype(loc, /obj/machinery/hydroponics))
		var/obj/machinery/hydroponics/H = loc
		rating = H.rating
	if(yield == 0)//Oh god don't divide by zero you'll doom us all.
		adjust_yield(1 * rating)
	else if(prob(1/(yield * yield) * 100))//This formula gives you diminishing returns based on yield. 100% with 1 yield, decreasing to 25%, 11%, 6, 4, 2...
		adjust_yield(1 * rating)
	return BULLET_ACT_HIT

// Harvest procs
/obj/item/seeds/proc/getYield()
	var/return_yield = yield

	for(var/datum/plant_gene/trait/trait in genes)
		if(trait.trait_flags & TRAIT_NO_POLLINATION)
			return return_yield

	var/obj/machinery/hydroponics/parent = loc
	if(istype(loc, /obj/machinery/hydroponics))
		if(parent.yieldmod == 0)
			return_yield = min(return_yield, 1)//1 if above zero, 0 otherwise
		else
			return_yield *= (parent.yieldmod)

	return return_yield


/obj/item/seeds/proc/harvest(mob/user)
	///Reference to the tray/soil the seeds are planted in.
	var/obj/machinery/hydroponics/parent = loc //for ease of access
	///Count used for creating the correct amount of results to the harvest.
	var/t_amount = 0
	///List of plants all harvested from the same batch.
	var/list/result = list()
	///Tile of the harvester to deposit the growables.
	var/output_loc = parent.Adjacent(user) ? user.loc : parent.loc //needed for TK
	///Name of the grown products.
	var/product_name
	///The Number of products produced by the plant, typically the yield. Modified by certain traits.
	var/product_count = getYield()

	while(t_amount < product_count)
		var/obj/item/food/grown/t_prod
		if(instability >= 30 && (seed_flags & MUTATE_EARLY) && LAZYLEN(mutatelist) && prob(instability/3))
			var/obj/item/seeds/mutated_seed = pick(mutatelist)
			t_prod = initial(mutated_seed.product)
			if(!t_prod)
				continue
			mutated_seed = new mutated_seed
			for(var/datum/plant_gene/trait/trait in parent.myseed.genes)
				if((trait.mutability_flags & PLANT_GENE_MUTATABLE) && trait.can_add(mutated_seed))
					mutated_seed.genes += trait.Copy()
			t_prod = new t_prod(output_loc, new_seed = mutated_seed)
			t_prod.transform = initial(t_prod.transform)
			t_prod.transform *= TRANSFORM_USING_VARIABLE(t_prod.seed.potency, 100) + 0.5
			ADD_TRAIT(t_prod, TRAIT_PLANT_WILDMUTATE, INNATE_TRAIT)
			t_amount++
			if(t_prod.seed)
				t_prod.seed.set_instability(round(instability * 0.5))
			continue
		else
			t_prod = new product(output_loc, new_seed = src)
		if(parent.myseed.plantname != initial(parent.myseed.plantname))
			t_prod.name = LOWER_TEXT(parent.myseed.plantname)
		if(productdesc)
			t_prod.desc = productdesc
		t_prod.seed.name = parent.myseed.name
		t_prod.seed.desc = parent.myseed.desc
		t_prod.seed.plantname = parent.myseed.plantname
		result.Add(t_prod) // User gets a consumable
		if(!t_prod)
			return
		t_amount++
		product_name = parent.myseed.plantname
	if(product_count >= 1)
		SSblackbox.record_feedback("tally", "food_harvested", product_count, product_name)
	parent.update_tray(user, product_count)

	return result

/**
 * This is where plant chemical products are handled.
 *
 * Individually, the formula for individual amounts of chemicals is Potency * the chemical production %, rounded to the fullest 1.
 * Specific chem handling is also handled here, like bloodtype, food taste within nutriment, and the auto-distilling/autojuicing traits.
 * This is where chemical reactions can occur, and the heating / cooling traits effect the reagent container.
 */
/obj/item/seeds/proc/prepare_result(obj/item/T)
	if(!T.reagents)
		CRASH("[T] has no reagents.")
	var/reagent_max = 0
	for(var/rid in reagents_add)
		reagent_max += reagents_add[rid]
	if(IS_EDIBLE(T) || istype(T, /obj/item/grown))
		var/obj/item/food/grown/grown_edible = T
		var/reagent_purity = get_reagent_purity()
		for(var/rid in reagents_add)
			var/reagent_overflow_mod = reagents_add[rid]
			if(reagent_max > 1)
				reagent_overflow_mod = (reagents_add[rid]/ reagent_max)
			var/edible_vol = grown_edible.reagents ? grown_edible.reagents.maximum_volume : 0
			var/amount = max(1, round((edible_vol)*(potency/100) * reagent_overflow_mod, 1)) //the plant will always have at least 1u of each of the reagents in its reagent production traits
			var/list/data
			if(rid == /datum/reagent/blood) // Hack to make blood in plants always O-
				data = list("blood_type" = "O-")
			if(istype(grown_edible) && (rid == /datum/reagent/consumable/nutriment || rid == /datum/reagent/consumable/nutriment/vitamin))
				data = grown_edible.tastes // apple tastes of apple.
			T.reagents.add_reagent(rid, amount, data, added_purity = reagent_purity)

		//Handles the juicing trait, swaps nutriment and vitamins for that species various juices if they exist. Mutually exclusive with distilling.
		if(get_gene(/datum/plant_gene/trait/juicing) && grown_edible.juice_typepath)
			grown_edible.juice(juicer = FALSE) //we pass FALSE & not null because Byond default args will subtitute it with the default value
		else if(get_gene(/datum/plant_gene/trait/brewing))
			grown_edible.ferment()

		/// The number of nutriments we have inside of our plant, for use in our heating / cooling genes
		var/num_nutriment = T.reagents.get_reagent_amount(/datum/reagent/consumable/nutriment)

		// Heats up the plant's contents by 25 kelvin per 1 unit of nutriment. Mutually exclusive with cooling.
		if(get_gene(/datum/plant_gene/trait/chem_heating))
			T.visible_message(span_notice("[T] releases freezing air, consuming its nutriments to heat its contents."))
			T.reagents.remove_reagent(/datum/reagent/consumable/nutriment, num_nutriment)
			T.reagents.chem_temp = min(1000, (T.reagents.chem_temp + num_nutriment * 25))
			T.reagents.handle_reactions()
			playsound(T.loc, 'sound/effects/wounds/sizzle2.ogg', 5)
		// Cools down the plant's contents by 5 kelvin per 1 unit of nutriment. Mutually exclusive with heating.
		else if(get_gene(/datum/plant_gene/trait/chem_cooling))
			T.visible_message(span_notice("[T] releases a blast of hot air, consuming its nutriments to cool its contents."))
			T.reagents.remove_reagent(/datum/reagent/consumable/nutriment, num_nutriment)
			T.reagents.chem_temp = max(3, (T.reagents.chem_temp + num_nutriment * -5))
			T.reagents.handle_reactions()
			playsound(T.loc, 'sound/effects/space_wind.ogg', 50)

/// Returns reagent purity based on seed stats
/obj/item/seeds/proc/get_reagent_purity()
	var/purity_from_lifespan = lifespan / 400 //up to +25% for lifespan
	var/purity_from_endurance = endurance / 400 //up to +25% for endurance
	var/purity_from_instability = rand(-instability, instability) / 400  //up to +-25% at random for instability
	var/result_purity = clamp(0.5 + purity_from_lifespan + purity_from_endurance + purity_from_instability, 0, 1) //50% base + stats
	return result_purity

/// Setters procs ///

/**
 * Adjusts seed yield up or down according to adjustamt. (Max 10)
 */
/obj/item/seeds/proc/adjust_yield(adjustamt)
	if(yield == -1) // Unharvestable shouldn't suddenly turn harvestable
		return

	var/max_yield = MAX_PLANT_YIELD
	var/min_yield = 0
	for(var/datum/plant_gene/trait/trait in genes)
		if(trait.trait_flags & TRAIT_HALVES_YIELD)
			max_yield = round(max_yield/2)
			break
	if(get_gene(/datum/plant_gene/trait/plant_type/fungal_metabolism))
		min_yield = FUNGAL_METAB_YIELD_MIN

	yield = clamp(yield + adjustamt, min_yield, max_yield)

/**
 * Adjusts seed lifespan up or down according to adjustamt. (Max 100)
 */
/obj/item/seeds/proc/adjust_lifespan(adjustamt)
	lifespan = clamp(lifespan + adjustamt, 10, MAX_PLANT_LIFESPAN)

/**
 * Adjusts seed endurance up or down according to adjustamt. (Max 100)
 */
/obj/item/seeds/proc/adjust_endurance(adjustamt)
	endurance = clamp(endurance + adjustamt, MIN_PLANT_ENDURANCE, MAX_PLANT_ENDURANCE)

/**
 * Adjusts seed production seed up or down according to adjustamt. (Max 10)
 */
/obj/item/seeds/proc/adjust_production(adjustamt)
	if(yield == -1)
		return
	production = clamp(production + adjustamt, 1, MAX_PLANT_PRODUCTION)

/**
 * Adjusts seed potency up or down according to adjustamt. (Max 100)
 */
/obj/item/seeds/proc/adjust_potency(adjustamt)
	if(potency == -1)
		return
	potency = clamp(potency + adjustamt, 0, MAX_PLANT_POTENCY)

/**
 * Adjusts seed instability up or down according to adjustamt. (Max 100)
 */
/obj/item/seeds/proc/adjust_instability(adjustamt)
	if(instability == -1)
		return
	instability = clamp(instability + adjustamt, 0, MAX_PLANT_INSTABILITY)

/**
 * Adjusts seed weed grwoth speed up or down according to adjustamt. (Max 10)
 */
/obj/item/seeds/proc/adjust_weed_rate(adjustamt)
	weed_rate = clamp(weed_rate + adjustamt, 0, MAX_PLANT_WEEDRATE)

/**
 * Adjusts seed weed chance up or down according to adjustamt. (Max 67%)
 */
/obj/item/seeds/proc/adjust_weed_chance(adjustamt)
	weed_chance = clamp(weed_chance + adjustamt, 0, MAX_PLANT_WEEDCHANCE)

//Directly setting stats

/**
 * Sets the plant's yield stat to the value of adjustamt. (Max 10, or 5 with some traits)
 */
/obj/item/seeds/proc/set_yield(adjustamt)
	if(yield == -1) // Unharvestable shouldn't suddenly turn harvestable
		return

	var/max_yield = MAX_PLANT_YIELD
	var/min_yield = 0
	for(var/datum/plant_gene/trait/trait in genes)
		if(trait.trait_flags & TRAIT_HALVES_YIELD)
			max_yield = round(max_yield/2)
			break
	if(get_gene(/datum/plant_gene/trait/plant_type/fungal_metabolism))
		min_yield = FUNGAL_METAB_YIELD_MIN

	yield = clamp(adjustamt, min_yield, max_yield)

/**
 * Sets the plant's lifespan stat to the value of adjustamt. (Max 100)
 */
/obj/item/seeds/proc/set_lifespan(adjustamt)
	lifespan = clamp(adjustamt, 10, MAX_PLANT_LIFESPAN)

/**
 * Sets the plant's endurance stat to the value of adjustamt. (Max 100)
 */
/obj/item/seeds/proc/set_endurance(adjustamt)
	endurance = clamp(adjustamt, MIN_PLANT_ENDURANCE, MAX_PLANT_ENDURANCE)

/**
 * Sets the plant's production stat to the value of adjustamt. (Max 10)
 */
/obj/item/seeds/proc/set_production(adjustamt)
	if(yield == -1)
		return
	production = clamp(adjustamt, 1, MAX_PLANT_PRODUCTION)

/**
 * Sets the plant's potency stat to the value of adjustamt. (Max 100)
 */
/obj/item/seeds/proc/set_potency(adjustamt)
	if(potency == -1)
		return
	potency = clamp(adjustamt, 0, MAX_PLANT_POTENCY)

/**
 * Sets the plant's instability stat to the value of adjustamt. (Max 100)
 */
/obj/item/seeds/proc/set_instability(adjustamt)
	if(instability == -1)
		return
	instability = clamp(adjustamt, 0, MAX_PLANT_INSTABILITY)

/**
 * Sets the plant's weed production rate to the value of adjustamt. (Max 10)
 */
/obj/item/seeds/proc/set_weed_rate(adjustamt)
	weed_rate = clamp(adjustamt, 0, MAX_PLANT_WEEDRATE)

/**
 * Sets the plant's weed growth percentage to the value of adjustamt. (Max 67%)
 */
/obj/item/seeds/proc/set_weed_chance(adjustamt)
	weed_chance = clamp(adjustamt, 0, MAX_PLANT_WEEDCHANCE)

/**
 * Override for seeds with unique text for their analyzer. (No newlines at the start or end of unique text!)
 * Returns null if no unique text, or a string of text if there is.
 */
/obj/item/seeds/proc/get_unique_analyzer_text()
	return null

/**
 * Override for seeds with special chem reactions.
 */
/obj/item/seeds/proc/on_chem_reaction(datum/reagents/reagents)
	return

/obj/item/seeds/attackby(obj/item/O, mob/user, params)
	if(IS_WRITING_UTENSIL(O))
		var/choice = tgui_input_list(usr, "What would you like to change?", "Seed Alteration", list("Plant Name", "Seed Description", "Product Description"))
		if(isnull(choice))
			return
		if(!user.can_perform_action(src))
			return
		switch(choice)
			if("Plant Name")
				var/newplantname = reject_bad_text(tgui_input_text(user, "Write a new plant name", "Plant Name", plantname, max_length = MAX_NAME_LEN))
				if(isnull(newplantname))
					return
				if(!user.can_perform_action(src))
					return
				name = "[LOWER_TEXT(newplantname)]"
				plantname = newplantname
			if("Seed Description")
				var/newdesc = tgui_input_text(user, "Write a new seed description", "Seed Description", desc, max_length = MAX_DESC_LEN)
				if(isnull(newdesc))
					return
				if(!user.can_perform_action(src))
					return
				desc = newdesc
			if("Product Description")
				if(product && !productdesc)
					productdesc = initial(product.desc)
				var/newproductdesc = tgui_input_text(user, "Write a new product description", "Product Description", productdesc, max_length = MAX_DESC_LEN)
				if(isnull(newproductdesc))
					return
				if(!user.can_perform_action(src))
					return
				productdesc = newproductdesc

	..() // Fallthrough to item/attackby() so that bags can pick seeds up

/obj/item/seeds/proc/randomize_stats()
	set_lifespan(rand(25, 60))
	set_endurance(rand(15, 35))
	set_production(rand(2, 10))
	set_yield(rand(1, 10))
	set_potency(rand(10, 35))
	set_weed_rate(rand(1, 10))
	set_weed_chance(rand(5, 100))
	maturation = rand(6, 12)

/obj/item/seeds/proc/add_random_reagents(lower = 0, upper = 2)
	var/amount_random_reagents = rand(lower, upper)
	for(var/i in 1 to amount_random_reagents)
		var/random_amount = rand(4, 15) * 0.01 // this must be multiplied by 0.01, otherwise, it will not properly associate
		var/datum/plant_gene/reagent/R = new(get_random_reagent_id(), random_amount)
		if(R.can_add(src))
			if(!R.try_upgrade_gene(src))
				genes += R
		else
			qdel(R)
	reagents_from_genes()

/obj/item/seeds/proc/add_random_traits(lower = 0, upper = 2)
	var/amount_random_traits = rand(lower, upper)
	for(var/i in 1 to amount_random_traits)
		var/random_trait = pick(subtypesof(/datum/plant_gene/trait))
		var/datum/plant_gene/trait/picked_random_trait = new random_trait
		if((picked_random_trait.mutability_flags & PLANT_GENE_MUTATABLE) && picked_random_trait.can_add(src))
			genes += picked_random_trait
		else
			qdel(picked_random_trait)

/obj/item/seeds/proc/add_random_plant_type(normal_plant_chance = 75)
	if(prob(normal_plant_chance))
		var/random_plant_type = pick(subtypesof(/datum/plant_gene/trait/plant_type))
		var/datum/plant_gene/trait/plant_type/P = new random_plant_type
		if(P.can_add(src))
			genes += P
		else
			qdel(P)

/obj/item/seeds/proc/remove_random_reagents(lower = 0, upper = 2)
	var/amount_random_reagents = rand(lower, upper)
	for(var/i in 1 to amount_random_reagents)
		var/datum/reagent/chemical = pick(reagents_add)
		qdel(chemical)

/**
 * Creates a graft from this plant.
 *
 * Creates a new graft from this plant.
 * Sets the grafts trait to this plants graftable trait.
 * Gives the graft a reference to this plant.
 * Copies all the relevant stats from this plant to the graft.
 * Returns the created graft.
 */
/obj/item/seeds/proc/create_graft()
	var/obj/item/graft/snip = new(loc, graft_gene)
	snip.parent_name = plantname
	snip.name += " ([plantname])"

	// Copy over stats so the graft can outlive its parent.
	snip.lifespan = lifespan
	snip.endurance = endurance
	snip.production = production
	snip.weed_rate = weed_rate
	snip.weed_chance = weed_chance
	snip.yield = yield

	return snip

/**
 * Applies a graft to this plant.
 *
 * Adds the graft trait to this plant if possible.
 * Increases plant stats by 2/3 of the grafts stats to a maximum of 100 (10 for yield).
 * Returns TRUE if the graft could apply its trait successfully, FALSE if it fails to apply the trait.
 * NOTE even if the graft fails to apply the trait it still adjusts the plant's stats and reagents.
 *
 * Arguments:
 * - [snip][/obj/item/graft]: The graft being used applied to this plant.
 */
/obj/item/seeds/proc/apply_graft(obj/item/graft/snip)
	. = TRUE
	var/datum/plant_gene/new_trait = snip.stored_trait
	if(new_trait?.can_add(src))
		genes += new_trait.Copy()
	else
		. = FALSE

	// Adjust stats based on graft stats
	set_lifespan(round(max(lifespan, (lifespan + (2/3)*(snip.lifespan - lifespan)))))
	set_endurance(round(max(endurance, (endurance + (2/3)*(snip.endurance - endurance)))))
	set_production(round(max(production, (production + (2/3)*(snip.production - production)))))
	set_weed_rate(round(max(weed_rate, (weed_rate + (2/3)*(snip.weed_rate - weed_rate)))))
	set_weed_chance(round(max(weed_chance, (weed_chance+ (2/3)*(snip.weed_chance - weed_chance)))))
	set_yield(round(max(yield, (yield + (2/3)*(snip.yield - yield)))))

	// Add in any reagents, too.
	reagents_from_genes()

	return

/*
 * Both `/item/food/grown` and `/item/grown` implement a seed variable which tracks
 * plant statistics, genes, traits, etc. This proc gets the seed for either grown food or
 * grown inedibles and returns it, or returns null if it's not a plant.
 *
 * Returns an `/obj/item/seeds` ref for grown foods or grown inedibles.
 *  - returned seed CAN be null in weird cases but in all applications it SHOULD NOT be.
 * Returns null if it is not a plant.
 */
/obj/item/proc/get_plant_seed()
	return null

/obj/item/food/grown/get_plant_seed()
	return seed

/obj/item/grown/get_plant_seed()
	return seed

/obj/item/seeds/proc/perform_reagent_pollination(obj/item/seeds/donor)
	var/list/datum/plant_gene/reagent/valid_reagents = list()
	for(var/datum/plant_gene/reagent/donor_reagent in donor.genes)
		var/repeated = FALSE
		for(var/datum/plant_gene/reagent/receptor_reagent in genes)
			if(donor_reagent.reagent_id == receptor_reagent.reagent_id)
				if(receptor_reagent.rate < donor_reagent.rate)
					receptor_reagent.rate = donor_reagent.rate
					// sucessful pollination/upgrade, we stop here.
					reagents_from_genes()
					return
				else
					repeated = TRUE
					break

		if(!repeated)
			valid_reagents += donor_reagent

	if(length(valid_reagents))
		// pick a valid reagent that our receptor seed don't have and add the gene to it
		var/datum/plant_gene/reagent/selected_reagent = pick(valid_reagents)
		genes += selected_reagent.Copy()
		reagents_from_genes()
