//this category is very little but I think that it has great potential to grow
////////////////////////////////////////////SALAD////////////////////////////////////////////
/obj/item/food/salad
	icon = 'icons/obj/food/soupsalad.dmi'
	trash_type = /obj/item/reagent_containers/cup/bowl
	bite_consumption = 3
	w_class = WEIGHT_CLASS_NORMAL
	food_reagents = list(/datum/reagent/consumable/nutriment = 7, /datum/reagent/consumable/nutriment/vitamin = 2)
	tastes = list("leaves" = 1)
	foodtypes = VEGETABLES
	eatverbs = list("devour", "nibble", "gnaw", "gobble", "chomp") //who the fuck gnaws and devours on a salad
	venue_value = FOOD_PRICE_NORMAL
	crafting_complexity = FOOD_COMPLEXITY_2

/obj/item/food/salad/aesirsalad
	name = "\improper Aesir salad"
	desc = "Probably too incredible for mortal men to fully enjoy."
	icon_state = "aesirsalad"
	food_reagents = list(/datum/reagent/consumable/nutriment = 8, /datum/reagent/consumable/nutriment/vitamin = 12)
	tastes = list("leaves" = 1)
	foodtypes = VEGETABLES | FRUIT
	crafting_complexity = FOOD_COMPLEXITY_3

/obj/item/food/salad/herbsalad
	name = "herb salad"
	desc = "A tasty salad with apples on top."
	icon_state = "herbsalad"
	food_reagents = list(/datum/reagent/consumable/nutriment = 8, /datum/reagent/consumable/nutriment/vitamin = 6)
	tastes = list("leaves" = 1, "apple" = 1)
	foodtypes = VEGETABLES | FRUIT
	crafting_complexity = FOOD_COMPLEXITY_2

/obj/item/food/salad/validsalad
	name = "valid salad"
	desc = "It's just an herb salad with meatballs and fried potato slices. Nothing suspicious about it."
	icon_state = "validsalad"
	food_reagents = list(/datum/reagent/consumable/nutriment = 5, /datum/reagent/consumable/nutriment/protein = 5, /datum/reagent/consumable/doctor_delight = 8, /datum/reagent/consumable/nutriment/vitamin = 6)
	tastes = list("leaves" = 1, "potato" = 1, "meat" = 1, "valids" = 1)
	foodtypes = VEGETABLES | MEAT | FRIED | FRUIT

/obj/item/food/salad/fruit
	name = "fruit salad"
	desc = "Your standard fruit salad."
	icon_state = "fruitsalad"
	food_reagents = list(/datum/reagent/consumable/nutriment = 9, /datum/reagent/consumable/nutriment/vitamin = 5)
	tastes = list("fruit" = 1)
	foodtypes = FRUIT
	crafting_complexity = FOOD_COMPLEXITY_3

/obj/item/food/salad/jungle
	name = "jungle salad"
	desc = "Exotic fruits in a bowl."
	icon_state = "junglesalad"
	food_reagents = list(/datum/reagent/consumable/nutriment = 11, /datum/reagent/consumable/banana = 5, /datum/reagent/consumable/nutriment/vitamin = 7)
	tastes = list("fruit" = 1, "the jungle" = 1)
	foodtypes = FRUIT
	crafting_complexity = FOOD_COMPLEXITY_3

/obj/item/food/salad/citrusdelight
	name = "citrus delight"
	desc = "Citrus overload!"
	icon_state = "citrusdelight"
	food_reagents = list(
		/datum/reagent/consumable/nutriment = 11,
		/datum/reagent/consumable/nutriment/vitamin = 7,
	)
	tastes = list("sourness" = 1, "leaves" = 1)
	foodtypes = FRUIT | ORANGES
	crafting_complexity = FOOD_COMPLEXITY_3

/obj/item/food/uncooked_rice
	name = "uncooked rice"
	desc = "A clump of raw rice."
	icon_state = "uncooked_rice"
	food_reagents = list(/datum/reagent/consumable/nutriment = 4)
	tastes = list("rice" = 1)
	foodtypes = GRAIN | RAW

/obj/item/food/uncooked_rice/make_bakeable()
	AddComponent(/datum/component/bakeable, /obj/item/food/boiledrice, rand(15 SECONDS, 20 SECONDS), TRUE, TRUE)

/obj/item/food/uncooked_rice/make_microwaveable()
	AddElement(/datum/element/microwavable, /obj/item/food/boiledrice)

/obj/item/food/boiledrice
	name = "boiled rice"
	desc = "A steaming cup of boiled rice. A bit bland by itself, but the basis for something delicious..."
	icon_state = "cooked_rice"
	food_reagents = list(
		/datum/reagent/consumable/nutriment = 6,
		/datum/reagent/consumable/nutriment/vitamin = 2,
	)
	tastes = list("rice" = 1)
	foodtypes = GRAIN | BREAKFAST
	crafting_complexity = FOOD_COMPLEXITY_1

/obj/item/food/salad/ricepudding
	name = "rice pudding"
	desc = "Everybody loves rice pudding!"
	icon_state = "ricepudding"
	food_reagents = list(
		/datum/reagent/consumable/nutriment = 8,
		/datum/reagent/consumable/sugar = 3,
		/datum/reagent/consumable/nutriment/vitamin = 3,
	)
	tastes = list("rice" = 1, "sweetness" = 1)
	foodtypes = GRAIN | DAIRY | SUGAR
	venue_value = FOOD_PRICE_NORMAL

/obj/item/food/salad/ricepork
	name = "rice and pork"
	desc = "Well, it looks like pork..."
	icon_state = "riceporkbowl"
	food_reagents = list(
		/datum/reagent/consumable/nutriment = 6,
		/datum/reagent/consumable/nutriment/protein = 6,
		/datum/reagent/consumable/nutriment/vitamin = 3,
	)
	tastes = list("rice" = 1, "meat" = 1)
	foodtypes = GRAIN | MEAT
	crafting_complexity = FOOD_COMPLEXITY_2

/obj/item/food/salad/risotto
	name = "risotto"
	desc = "Proof the Italians mastered every carb."
	icon_state = "risotto"
	food_reagents = list(
		/datum/reagent/consumable/nutriment = 10,
		/datum/reagent/consumable/nutriment/vitamin = 6,
	)
	tastes = list("rice" = 1, "cheese" = 1)
	foodtypes = GRAIN | DAIRY
	venue_value = FOOD_PRICE_EXOTIC
	crafting_complexity = FOOD_COMPLEXITY_3

/obj/item/food/salad/eggbowl
	name = "egg bowl"
	desc = "A bowl of rice with a fried egg."
	icon_state = "eggbowl"
	food_reagents = list(
		/datum/reagent/consumable/nutriment = 8,
		/datum/reagent/consumable/nutriment/protein = 2,
		/datum/reagent/consumable/nutriment/vitamin = 4,
	)
	tastes = list("rice" = 1, "egg" = 1)
	foodtypes = GRAIN | MEAT //EGG = MEAT -NinjaNomNom 2017
	crafting_complexity = FOOD_COMPLEXITY_4

/obj/item/food/salad/edensalad
	name = "\improper Salad of Eden"
	desc = "A salad brimming with untapped potential."
	icon_state = "edensalad"
	food_reagents = list(
		/datum/reagent/consumable/nutriment = 7,
		/datum/reagent/consumable/nutriment/vitamin = 5,
	)
	tastes = list("extreme bitterness" = 3, "hope" = 1)
	foodtypes = VEGETABLES
	crafting_complexity = FOOD_COMPLEXITY_3

/obj/item/food/salad/gumbo
	name = "black eyed gumbo"
	desc = "A spicy and savory meat and rice dish."
	icon_state = "gumbo"
	food_reagents = list(
		/datum/reagent/consumable/capsaicin = 2,
		/datum/reagent/consumable/nutriment/vitamin = 3,
		/datum/reagent/consumable/nutriment = 5,
	)
	tastes = list("building heat" = 2, "savory meat and vegtables" = 1)
	foodtypes = GRAIN | MEAT | VEGETABLES
	crafting_complexity = FOOD_COMPLEXITY_3

/obj/item/reagent_containers/cup/bowl
	name = "bowl"
	desc = "A simple bowl, used for soups and salads."
	icon = 'icons/obj/food/soupsalad.dmi'
	icon_state = "bowl"
	base_icon_state = "bowl"
	reagent_flags = OPENCONTAINER | DUNKABLE
	custom_materials = list(/datum/material/glass = SMALL_MATERIAL_AMOUNT*5)
	w_class = WEIGHT_CLASS_NORMAL
	custom_price = PAYCHECK_CREW * 0.6
	fill_icon_thresholds = list(0)
	fill_icon_state = "fullbowl"
	fill_icon = 'icons/obj/food/soupsalad.dmi'

	volume = SOUP_SERVING_SIZE + 5
	gulp_size = 3

/obj/item/reagent_containers/cup/bowl/Initialize(mapload)
	. = ..()
	RegisterSignal(src, COMSIG_ATOM_REAGENT_EXAMINE, PROC_REF(reagent_special_examine))
	AddElement(/datum/element/foodlike_drink)
	AddComponent(/datum/component/ingredients_holder, /obj/item/food/salad/empty, CUSTOM_INGREDIENT_ICON_FILL, max_ingredients = 6)
	AddComponent( \
		/datum/component/takes_reagent_appearance, \
		on_icon_changed = CALLBACK(src, PROC_REF(on_cup_change)), \
		on_icon_reset = CALLBACK(src, PROC_REF(on_cup_reset)), \
		base_container_type = /obj/item/reagent_containers/cup/bowl, \
	)

/obj/item/reagent_containers/cup/bowl/on_cup_change(datum/glass_style/style)
	. = ..()
	fill_icon_thresholds = null

/obj/item/reagent_containers/cup/bowl/on_cup_reset()
	. = ..()
	fill_icon_thresholds ||= list(0)

/**
 * Override standard reagent examine
 * so that anyone examining a bowl of soup sees the soup but nothing else (unless they have sci goggles)
 */
/obj/item/reagent_containers/cup/bowl/proc/reagent_special_examine(datum/source, mob/user, list/examine_list, can_see_insides = FALSE)
	SIGNAL_HANDLER

	if(can_see_insides || reagents.total_volume <= 0)
		return

	var/unknown_volume = 0
	var/list/soups_found = list()
	for(var/datum/reagent/current_reagent as anything in reagents.reagent_list)
		if(istype(current_reagent, /datum/reagent/consumable/nutriment/soup))
			soups_found += "&bull; [round(current_reagent.volume, 0.01)] units of [current_reagent.name]"
		else
			unknown_volume += current_reagent.volume

	if(!length(soups_found))
		// There was no soup in the pot, do normal examine
		return

	examine_list += "Inside, you can see:"
	examine_list += soups_found
	if(unknown_volume > 0)
		examine_list += "&bull; [round(unknown_volume, 0.01)] units of unknown reagents"

	return STOP_GENERIC_REAGENT_EXAMINE

// empty salad for custom salads
/obj/item/food/salad/empty
	name = "salad"
	foodtypes = NONE
	tastes = list()
	icon_state = "bowl"
	desc = "A delicious customized salad."

/obj/item/food/salad/kale_salad
	name = "kale salad"
	desc = "A healthy kale salad drizzled in oil, perfect for warm summer months."
	icon_state = "kale_salad"
	food_reagents = list(
		/datum/reagent/consumable/nutriment/vitamin = 12,
		/datum/reagent/consumable/nutriment = 12,
	)
	tastes = list("healthy greens" = 2, "olive dressing" = 1)
	foodtypes = VEGETABLES
	crafting_complexity = FOOD_COMPLEXITY_3

/obj/item/food/salad/greek_salad
	name = "Greek salad"
	desc = "A popular salad made of tomatoes, onions, feta cheese, and olives all drizzled in olive oil. Though it feels like it's missing something..."
	icon_state = "greek_salad"
	food_reagents = list(
		/datum/reagent/consumable/nutriment/vitamin = 13,
		/datum/reagent/consumable/nutriment = 14,
	)
	tastes = list("healthy greens" = 2, "olive dressing" = 1, "feta cheese" = 1)
	foodtypes = VEGETABLES | DAIRY
	crafting_complexity = FOOD_COMPLEXITY_4

/obj/item/food/salad/caesar_salad
	name = "Caesar salad"
	desc = "A simple yet flavorful salad of onions, lettuce, croutons, and shreds of cheese dressed in oil. Comes with a slice of pita bread!"
	icon_state = "caesar_salad"
	food_reagents = list(
		/datum/reagent/consumable/nutriment/vitamin = 12,
		/datum/reagent/consumable/nutriment = 12,
	)
	tastes = list("healthy greens" = 2, "olive dressing" = 2, "feta cheese" = 2, "pita bread" = 1)
	foodtypes = VEGETABLES | DAIRY | GRAIN
	crafting_complexity = FOOD_COMPLEXITY_4

/obj/item/food/salad/spring_salad
	name = "spring salad"
	desc = "A simple salad of carrots, lettuce and peas drizzled in oil with a pinch of salt."
	icon_state = "spring_salad"
	food_reagents = list(
		/datum/reagent/consumable/nutriment/vitamin = 12,
		/datum/reagent/consumable/nutriment = 12,
	)
	tastes = list("crisp greens" = 2, "olive dressing" = 2, "salt" = 1)
	foodtypes = VEGETABLES
	crafting_complexity = FOOD_COMPLEXITY_3

/obj/item/food/salad/potato_salad
	name = "potato salad"
	desc = "A dish of boiled potatoes mixed with boiled eggs, onions, and mayonnaise. A staple of every self-respecting barbecue."
	icon_state = "potato_salad"
	food_reagents = list(
		/datum/reagent/consumable/nutriment/vitamin = 12,
		/datum/reagent/consumable/nutriment = 12,
		/datum/reagent/consumable/nutriment/protein = 4,
	)
	tastes = list("creamy potatoes" = 2, "eggs" = 2, "mayonnaise" = 1, "onions" = 1)
	foodtypes = VEGETABLES | BREAKFAST
	crafting_complexity = FOOD_COMPLEXITY_3

/obj/item/food/salad/spinach_fruit_salad
	name = "spinach fruit salad"
	desc = "A vibrant fruit salad made of spinach, berries, and pineapple chunks all drizzled in oil. Yummy!"
	icon_state = "spinach_fruit_salad"
	food_reagents = list(
		/datum/reagent/consumable/nutriment/vitamin = 12,
		/datum/reagent/consumable/nutriment = 12,
	)
	tastes = list("spinach" = 2, "berries" = 2, "pineapple" = 2, "dressing" = 1)
	foodtypes = VEGETABLES | FRUIT
	crafting_complexity = FOOD_COMPLEXITY_3

/obj/item/food/salad/antipasto_salad
	name = "antipasto salad"
	desc = "A traditional Italian salad made of salami, mozzarella cheese, olives, and tomatoes. Often served as a first course meal."
	icon_state = "antipasto_salad"
	food_reagents = list(
		/datum/reagent/consumable/nutriment/vitamin = 12,
		/datum/reagent/consumable/nutriment = 12,
		/datum/reagent/consumable/nutriment/protein = 6,
	)
	tastes = list("lettuce" = 2, "salami" = 2, "mozzarella cheese" = 2, "tomatoes" = 2, "dressing" = 1)
	foodtypes = VEGETABLES | DAIRY | MEAT
	crafting_complexity = FOOD_COMPLEXITY_4
