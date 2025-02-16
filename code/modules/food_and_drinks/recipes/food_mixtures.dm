/datum/crafting_recipe/food
	mass_craftable = TRUE
	crafting_flags = parent_type::crafting_flags | CRAFT_TRANSFERS_REAGENTS | CRAFT_CLEARS_REAGENTS | CRAFT_ENFORCE_MATERIALS_PARITY

/datum/crafting_recipe/food/crafting_ui_data()
	var/list/data = list()

	if(ispath(result, /obj/item/food))
		var/obj/item/food/item = result
		data["foodtypes"] = bitfield_to_list(initial(item.foodtypes), FOOD_FLAGS)
		data["complexity"] = initial(item.crafting_complexity)

	return data

//////////////////////////////////////////FOOD MIXTURES////////////////////////////////////

/datum/chemical_reaction/food
	optimal_temp = 400
	temp_exponent_factor = 1
	optimal_ph_min = 2
	optimal_ph_max = 10
	thermic_constant = 0
	H_ion_release = 0
	reaction_tags = REACTION_TAG_FOOD | REACTION_TAG_EASY
	required_other = TRUE

	/// Typepath of food that is created on reaction
	var/atom/resulting_food_path
	/// Reagent purity of the result, calculated on reaction
	var/resulting_reagent_purity

/datum/chemical_reaction/food/pre_reaction_other_checks(datum/reagents/holder)
	resulting_reagent_purity = holder.get_average_purity()
	return TRUE

/datum/chemical_reaction/food/on_reaction(datum/reagents/holder, datum/equilibrium/reaction, created_volume)
	if(resulting_food_path)
		var/atom/location = holder.my_atom.drop_location()
		for(var/i in 1 to created_volume)
			var/obj/item/food/result = new resulting_food_path(location)
			if(ispath(resulting_food_path, /obj/item/food) && !isnull(resulting_reagent_purity))
				result.reagents?.set_all_reagents_purity(resulting_reagent_purity)

/datum/chemical_reaction/food/tofu
	required_reagents = list(/datum/reagent/consumable/soymilk = 10)
	required_catalysts = list(/datum/reagent/consumable/enzyme = 5)
	mob_react = FALSE
	reaction_flags = REACTION_INSTANT
	resulting_food_path = /obj/item/food/tofu

/datum/chemical_reaction/food/candycorn
	required_reagents = list(/datum/reagent/consumable/nutriment/fat/oil = 5)
	required_catalysts = list(/datum/reagent/consumable/sugar = 5)
	mob_react = FALSE
	reaction_flags = REACTION_INSTANT
	resulting_food_path = /obj/item/food/candy_corn

/datum/chemical_reaction/food/chocolatepudding
	results = list(/datum/reagent/consumable/chocolatepudding = 20)
	required_reagents = list(/datum/reagent/consumable/cream = 5, /datum/reagent/consumable/coco = 5, /datum/reagent/consumable/eggyolk = 2)

/datum/chemical_reaction/food/vanillapudding
	results = list(/datum/reagent/consumable/vanillapudding = 20)
	required_reagents = list(/datum/reagent/consumable/vanilla = 5, /datum/reagent/consumable/cream = 5, /datum/reagent/consumable/eggyolk = 2)

/datum/chemical_reaction/food/chocolate_bar
	required_reagents = list(/datum/reagent/consumable/soymilk = 2, /datum/reagent/consumable/coco = 2, /datum/reagent/consumable/sugar = 2)
	reaction_flags = REACTION_INSTANT
	resulting_food_path = /obj/item/food/chocolatebar

/datum/chemical_reaction/food/chocolate_bar2
	required_reagents = list(/datum/reagent/consumable/milk/chocolate_milk = 4, /datum/reagent/consumable/sugar = 2)
	mob_react = FALSE
	reaction_flags = REACTION_INSTANT
	resulting_food_path = /obj/item/food/chocolatebar

/datum/chemical_reaction/food/chocolate_bar3
	required_reagents = list(/datum/reagent/consumable/milk = 2, /datum/reagent/consumable/coco = 2, /datum/reagent/consumable/sugar = 2)
	reaction_flags = REACTION_INSTANT
	resulting_food_path = /obj/item/food/chocolatebar

/datum/chemical_reaction/food/soysauce
	results = list(/datum/reagent/consumable/soysauce = 5)
	required_reagents = list(/datum/reagent/consumable/soymilk = 4, /datum/reagent/toxin/acid = 1)

/datum/chemical_reaction/food/corn_syrup
	results = list(/datum/reagent/consumable/corn_syrup = 5)
	required_reagents = list(/datum/reagent/consumable/corn_starch = 1, /datum/reagent/toxin/acid = 1)
	required_temp = 374

/datum/chemical_reaction/food/rice_flour
	results = list(/datum/reagent/consumable/rice_flour = 10)
	required_reagents = list(/datum/reagent/consumable/flour = 5,/datum/reagent/consumable/rice = 5)

/datum/chemical_reaction/food/caramel
	results = list(/datum/reagent/consumable/caramel = 1)
	required_reagents = list(/datum/reagent/consumable/sugar = 1)
	required_temp = 413.15
	optimal_temp = 600
	mob_react = FALSE

/datum/chemical_reaction/food/caramel_burned
	results = list(/datum/reagent/carbon = 1)
	required_reagents = list(/datum/reagent/consumable/caramel = 1)
	required_temp = 483.15
	optimal_temp = 1000
	rate_up_lim = 10
	mob_react = FALSE

/datum/chemical_reaction/food/cheesewheel
	required_reagents = list(/datum/reagent/consumable/milk = 40)
	required_catalysts = list(/datum/reagent/consumable/enzyme = 5)
	reaction_flags = REACTION_INSTANT
	resulting_food_path = /obj/item/food/cheese/wheel

/datum/chemical_reaction/food/synthmeat
	required_reagents = list(/datum/reagent/blood = 5, /datum/reagent/medicine/cryoxadone = 1)
	mob_react = FALSE
	reaction_flags = REACTION_INSTANT
	resulting_food_path = /obj/item/food/meat/slab/synthmeat

/datum/chemical_reaction/food/hot_ramen
	results = list(/datum/reagent/consumable/hot_ramen = 3)
	required_reagents = list(/datum/reagent/water = 1, /datum/reagent/consumable/dry_ramen = 3)

/datum/chemical_reaction/food/hell_ramen
	results = list(/datum/reagent/consumable/hell_ramen = 6)
	required_reagents = list(/datum/reagent/consumable/capsaicin = 1, /datum/reagent/consumable/hot_ramen = 6)

/datum/chemical_reaction/food/imitationcarpmeat
	required_reagents = list(/datum/reagent/toxin/carpotoxin = 5)
	required_container = /obj/item/food/tofu
	mix_message = "The mixture becomes similar to carp meat."
	reaction_flags = REACTION_INSTANT

/datum/chemical_reaction/food/imitationcarpmeat/on_reaction(datum/reagents/holder, datum/equilibrium/reaction, created_volume)
	var/location = get_turf(holder.my_atom)
	new /obj/item/food/fishmeat/carp/imitation(location)
	if(holder?.my_atom)
		qdel(holder.my_atom)

/datum/chemical_reaction/food/dough
	required_reagents = list(/datum/reagent/water = 10, /datum/reagent/consumable/flour = 15)
	mix_message = "The ingredients form a dough."
	reaction_flags = REACTION_INSTANT
	resulting_food_path = /obj/item/food/dough

/datum/chemical_reaction/food/rice_dough
	required_reagents = list(/datum/reagent/consumable/rice_flour = 20,/datum/reagent/water = 10)
	mix_message = "The ingredients form a rice dough."
	reaction_flags = REACTION_INSTANT
	resulting_food_path = /obj/item/food/rice_dough

/datum/chemical_reaction/food/cakebatter
	required_reagents = list(/datum/reagent/consumable/eggyolk = 6, /datum/reagent/consumable/eggwhite = 12, /datum/reagent/consumable/flour = 15, /datum/reagent/consumable/sugar = 5)
	mix_message = "The ingredients form a cake batter."
	reaction_flags = REACTION_INSTANT
	resulting_food_path = /obj/item/food/cakebatter

/datum/chemical_reaction/food/cakebatter/vegan
	required_reagents = list(/datum/reagent/consumable/soymilk = 15, /datum/reagent/consumable/flour = 15, /datum/reagent/consumable/sugar = 5)

/datum/chemical_reaction/food/pancakebatter
	results = list(/datum/reagent/consumable/pancakebatter = 15)
	required_reagents = list(/datum/reagent/consumable/eggyolk = 6, /datum/reagent/consumable/eggwhite = 12, /datum/reagent/consumable/milk = 10, /datum/reagent/consumable/flour = 5)

/datum/chemical_reaction/food/uncooked_rice
	required_reagents = list(/datum/reagent/consumable/rice = 10, /datum/reagent/water = 10)
	mix_message = "The rice absorbs the water."
	reaction_flags = REACTION_INSTANT

/datum/chemical_reaction/food/uncooked_rice/on_reaction(datum/reagents/holder, datum/equilibrium/reaction, created_volume)
	var/location = get_turf(holder.my_atom)
	for(var/i in 1 to created_volume)
		new /obj/item/food/uncooked_rice(location)

/datum/chemical_reaction/food/nutriconversion
	results = list(/datum/reagent/consumable/nutriment/peptides = 0.5)
	required_reagents = list(/datum/reagent/consumable/nutriment/ = 0.5)
	required_catalysts = list(/datum/reagent/medicine/metafactor = 0.5)

/datum/chemical_reaction/food/protein_peptide
	results = list(/datum/reagent/consumable/nutriment/peptides = 0.5)
	required_reagents = list(/datum/reagent/consumable/nutriment/protein = 0.5)
	required_catalysts = list(/datum/reagent/medicine/metafactor = 0.5)

/datum/chemical_reaction/food/failed_nutriconversion
	results = list(/datum/reagent/peptides_failed = 0.5)
	required_reagents = list(/datum/reagent/consumable/nutriment/ = 0.5)
	required_catalysts = list(/datum/reagent/impurity/probital_failed = 0.5)
	thermic_constant = 100 // a tell

/datum/chemical_reaction/food/failed_protein_peptide
	results = list(/datum/reagent/peptides_failed = 0.5)
	required_reagents = list(/datum/reagent/consumable/nutriment/protein = 0.5)
	required_catalysts = list(/datum/reagent/impurity/probital_failed = 0.5)
	thermic_constant = 100 // a tell

/datum/chemical_reaction/food/bbqsauce
	results = list(/datum/reagent/consumable/bbqsauce = 5)
	required_reagents = list(/datum/reagent/ash = 1, /datum/reagent/consumable/tomatojuice = 1, /datum/reagent/medicine/salglu_solution = 3, /datum/reagent/consumable/blackpepper = 1)

/datum/chemical_reaction/food/gravy
	results = list(/datum/reagent/consumable/gravy = 3)
	required_reagents = list(/datum/reagent/consumable/milk = 1, /datum/reagent/consumable/nutriment = 1, /datum/reagent/consumable/flour = 1)

/datum/chemical_reaction/food/mothic_pizza_dough
	required_reagents = list(/datum/reagent/consumable/milk = 5, /datum/reagent/consumable/nutriment/fat/oil/olive = 2, /datum/reagent/medicine/salglu_solution = 5, /datum/reagent/consumable/cornmeal = 10, /datum/reagent/consumable/flour = 5)
	mix_message = "The ingredients form a pizza dough."
	reaction_flags = REACTION_INSTANT
	resulting_food_path = /obj/item/food/mothic_pizza_dough

/datum/chemical_reaction/food/curd_cheese
	required_reagents = list(/datum/reagent/consumable/milk = 15, /datum/reagent/consumable/vinegar = 5, /datum/reagent/consumable/cream = 5)
	mix_message = "The milk curdles into cheese."
	required_temp = 353
	reaction_flags = REACTION_INSTANT
	resulting_food_path = /obj/item/food/cheese/curd_cheese

/datum/chemical_reaction/food/mozzarella
	required_reagents = list(/datum/reagent/consumable/milk = 10, /datum/reagent/consumable/cream = 10)
	required_catalysts = list(/datum/reagent/consumable/enzyme = 1)
	mix_message = "Fine ribbons of curd form in the milk."
	required_temp = 353
	reaction_flags = REACTION_INSTANT
	resulting_food_path = /obj/item/food/cheese/mozzarella

/datum/chemical_reaction/food/cornmeal_batter
	results = list(/datum/reagent/consumable/cornmeal_batter = 35)
	required_reagents = list(/datum/reagent/consumable/cornmeal = 20, /datum/reagent/consumable/yoghurt = 10, /datum/reagent/consumable/eggyolk = 5)
	mix_message = "A silky batter forms."

/datum/chemical_reaction/food/cornbread
	required_reagents = list(/datum/reagent/consumable/cornmeal_batter = 25)
	mix_message = "The batter bakes into cornbread- somehow!"
	required_temp = 473
	reaction_flags = REACTION_INSTANT
	resulting_food_path = /obj/item/food/bread/corn

/datum/chemical_reaction/food/yoghurt
	required_reagents = list(/datum/reagent/consumable/cream = 10, /datum/reagent/consumable/virus_food = 2)
	results = list(/datum/reagent/consumable/yoghurt = 10)
	mix_message = "The mixture thickens into yoghurt."
	reaction_flags = REACTION_INSTANT

/datum/chemical_reaction/food/olive_oil_upconvert
	required_catalysts = list(/datum/reagent/consumable/nutriment/fat/oil/olive = 1)
	required_reagents = list( /datum/reagent/consumable/nutriment/fat/oil = 2)
	results = list(/datum/reagent/consumable/nutriment/fat/oil/olive = 2)
	mix_message = "The cooking oil dilutes the quality oil- how delightfully devilish..."
	reaction_flags = REACTION_INSTANT

/datum/chemical_reaction/food/olive_oil
	results = list(/datum/reagent/consumable/nutriment/fat/oil/olive = 2)
	required_reagents = list(/datum/reagent/consumable/olivepaste = 4, /datum/reagent/water = 1)
	reaction_flags = REACTION_INSTANT

/datum/chemical_reaction/food/wine_vinegar
	results = list(/datum/reagent/consumable/vinegar = 5)
	required_reagents = list(/datum/reagent/consumable/ethanol/wine = 1, /datum/reagent/water = 1, /datum/reagent/consumable/sugar = 1)
	reaction_flags = REACTION_INSTANT

/datum/chemical_reaction/food/grounding_neutralise
	results = list(/datum/reagent/consumable/salt = 2)
	required_reagents = list(/datum/reagent/consumable/liquidelectricity/enriched = 2, /datum/reagent/consumable/grounding_solution = 1)
	mix_message = "The mixture lets off a sharp snap as the electricity discharges."
	mix_sound = 'sound/items/weapons/taser.ogg'
	reaction_flags = REACTION_INSTANT

/datum/chemical_reaction/food/martian_batter
	results = list(/datum/reagent/consumable/martian_batter = 10)
	required_reagents = list(/datum/reagent/consumable/flour = 5, /datum/reagent/consumable/nutriment/soup/dashi = 5)
	mix_message = "A smooth batter forms."
	reaction_flags = REACTION_INSTANT

/datum/chemical_reaction/food/grape_vinegar
	results = list(/datum/reagent/consumable/vinegar = 5)
	required_reagents = list(/datum/reagent/consumable/grapejuice = 5)
	required_catalysts = list(/datum/reagent/consumable/enzyme = 5)
	mix_message = "The smell of the mixture reminds you of how you lost access to the country club..."
