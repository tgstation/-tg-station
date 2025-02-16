/obj/item/food/tortilla
	name = "tortilla"
	desc = "The base for all your burritos."
	icon = 'icons/obj/food/food_ingredients.dmi'
	icon_state = "tortilla"
	food_reagents = list(
		/datum/reagent/consumable/nutriment = 3,
		/datum/reagent/consumable/nutriment/vitamin = 1,
	)
	tastes = list("tortilla" = 1)
	foodtypes = GRAIN
	w_class = WEIGHT_CLASS_TINY
	crafting_complexity = FOOD_COMPLEXITY_1

/obj/item/food/tortilla/make_grillable()
	AddComponent(/datum/component/grillable, /obj/item/food/hard_taco_shell, rand(15 SECONDS, 30 SECONDS), TRUE, TRUE)

/obj/item/food/burrito
	name = "burrito"
	desc = "Tortilla wrapped goodness."
	icon = 'icons/obj/food/mexican.dmi'
	icon_state = "burrito"
	food_reagents = list(
		/datum/reagent/consumable/nutriment = 2,
		/datum/reagent/consumable/nutriment/protein = 4,
		/datum/reagent/consumable/nutriment/vitamin = 1,
	)
	tastes = list("torilla" = 2, "beans" = 3)
	foodtypes = GRAIN
	w_class = WEIGHT_CLASS_SMALL
	venue_value = FOOD_PRICE_NORMAL
	crafting_complexity = FOOD_COMPLEXITY_2

/obj/item/food/cheesyburrito
	name = "cheesy burrito"
	desc = "It's a burrito filled with cheese."
	icon = 'icons/obj/food/mexican.dmi'
	icon_state = "cheesyburrito"
	food_reagents = list(
		/datum/reagent/consumable/nutriment = 3,
		/datum/reagent/consumable/nutriment/protein = 5,
		/datum/reagent/consumable/nutriment/vitamin = 2,
	)
	tastes = list("torilla" = 2, "beans" = 3, "cheese" = 1)
	foodtypes = GRAIN | DAIRY
	w_class = WEIGHT_CLASS_SMALL
	venue_value = FOOD_PRICE_EXOTIC
	crafting_complexity = FOOD_COMPLEXITY_3

/obj/item/food/carneburrito
	name = "carne asada burrito"
	desc = "The best burrito for meat lovers."
	icon = 'icons/obj/food/mexican.dmi'
	icon_state = "carneburrito"
	food_reagents = list(
		/datum/reagent/consumable/nutriment = 2,
		/datum/reagent/consumable/nutriment/protein = 6,
		/datum/reagent/consumable/nutriment/vitamin = 1,
	)
	tastes = list("torilla" = 2, "meat" = 4)
	foodtypes = GRAIN | MEAT
	w_class = WEIGHT_CLASS_SMALL
	venue_value = FOOD_PRICE_EXOTIC
	crafting_complexity = FOOD_COMPLEXITY_3

/obj/item/food/fuegoburrito
	name = "fuego plasma burrito"
	desc = "A super spicy burrito."
	icon = 'icons/obj/food/mexican.dmi'
	icon_state = "fuegoburrito"
	food_reagents = list(
		/datum/reagent/consumable/nutriment = 3,
		/datum/reagent/consumable/nutriment/protein = 2,
		/datum/reagent/consumable/capsaicin = 5,
		/datum/reagent/consumable/nutriment/vitamin = 3,
	)
	tastes = list("torilla" = 2, "beans" = 3, "hot peppers" = 1)
	foodtypes = GRAIN
	w_class = WEIGHT_CLASS_SMALL
	venue_value = FOOD_PRICE_LEGENDARY
	crafting_complexity = FOOD_COMPLEXITY_3

/obj/item/food/nachos
	name = "nachos"
	desc = "Chips from Space Mexico."
	icon = 'icons/obj/food/mexican.dmi'
	icon_state = "nachos"
	food_reagents = list(
		/datum/reagent/consumable/nutriment = 6,
		/datum/reagent/consumable/nutriment/vitamin = 2,
	)
	tastes = list("nachos" = 1)
	foodtypes = GRAIN | FRIED
	w_class = WEIGHT_CLASS_SMALL
	venue_value = FOOD_PRICE_CHEAP
	crafting_complexity = FOOD_COMPLEXITY_1

/obj/item/food/cheesynachos
	name = "cheesy nachos"
	desc = "The delicious combination of nachos and melting cheese."
	icon = 'icons/obj/food/mexican.dmi'
	icon_state = "cheesynachos"
	food_reagents = list(
		/datum/reagent/consumable/nutriment = 6,
		/datum/reagent/consumable/nutriment/protein = 1,
		/datum/reagent/consumable/nutriment/vitamin = 3,
	)
	tastes = list("nachos" = 2, "cheese" = 1)
	foodtypes = GRAIN | FRIED | DAIRY
	w_class = WEIGHT_CLASS_SMALL
	venue_value = FOOD_PRICE_EXOTIC
	crafting_complexity = FOOD_COMPLEXITY_2

/obj/item/food/cubannachos
	name = "Cuban nachos"
	desc = "That's some dangerously spicy nachos."
	icon = 'icons/obj/food/mexican.dmi'
	icon_state = "cubannachos"
	food_reagents = list(
		/datum/reagent/consumable/nutriment = 7,
		/datum/reagent/consumable/capsaicin = 8,
		/datum/reagent/consumable/nutriment/vitamin = 4,
	)
	tastes = list("nachos" = 2, "hot pepper" = 1)
	foodtypes = VEGETABLES | FRIED | DAIRY
	w_class = WEIGHT_CLASS_SMALL
	venue_value = FOOD_PRICE_CHEAP
	crafting_complexity = FOOD_COMPLEXITY_2

/obj/item/food/taco
	name = "classic taco"
	desc = "A traditional taco with meat, cheese, and lettuce."
	icon = 'icons/obj/food/mexican.dmi'
	icon_state = "taco"
	food_reagents = list(
		/datum/reagent/consumable/nutriment = 2,
		/datum/reagent/consumable/nutriment/protein = 3,
		/datum/reagent/consumable/nutriment/vitamin = 2,
	)
	tastes = list("taco" = 4, "meat" = 2, "cheese" = 2, "lettuce" = 1)
	foodtypes = MEAT | DAIRY | GRAIN | VEGETABLES
	w_class = WEIGHT_CLASS_SMALL
	venue_value = FOOD_PRICE_NORMAL
	crafting_complexity = FOOD_COMPLEXITY_3

/obj/item/food/taco/plain
	name = "plain taco"
	desc = "A traditional taco with meat and cheese, minus the rabbit food."
	icon_state = "taco_plain"
	food_reagents = list(
		/datum/reagent/consumable/nutriment = 2,
		/datum/reagent/consumable/nutriment/protein = 2,
		/datum/reagent/consumable/nutriment/vitamin = 1,
	)
	tastes = list("taco" = 4, "meat" = 2, "cheese" = 2)
	foodtypes = MEAT | DAIRY | GRAIN
	venue_value = FOOD_PRICE_CHEAP
	crafting_complexity = FOOD_COMPLEXITY_2

/obj/item/food/taco/fish
	name = "fish taco"
	desc = "A taco with fish, cheese, and cabbage."
	icon_state = "fishtaco"
	tastes = list("taco" = 4, "fish" = 2, "cheese" = 2, "cabbage" = 1)
	foodtypes = SEAFOOD | DAIRY | GRAIN | VEGETABLES
	crafting_complexity = FOOD_COMPLEXITY_3

/obj/item/food/enchiladas
	name = "enchiladas"
	desc = "Viva La Mexico!"
	icon = 'icons/obj/food/mexican.dmi'
	icon_state = "enchiladas"
	bite_consumption = 4
	food_reagents = list(
		/datum/reagent/consumable/nutriment = 4,
		/datum/reagent/consumable/nutriment/protein = 7,
		/datum/reagent/consumable/capsaicin = 6,
		/datum/reagent/consumable/nutriment/vitamin = 2,
	)
	tastes = list("hot peppers" = 1, "meat" = 3, "cheese" = 1, "sour cream" = 1)
	foodtypes = MEAT | GRAIN
	w_class = WEIGHT_CLASS_SMALL
	crafting_complexity = FOOD_COMPLEXITY_3

/obj/item/food/stuffedlegion
	name = "stuffed legion"
	desc = "The former skull of a damned human, filled with goliath meat. It has a decorative lava pool made of ketchup and hotsauce."
	icon_state = "stuffed_legion"
	food_reagents = list(
		/datum/reagent/consumable/nutriment = 2,
		/datum/reagent/consumable/nutriment/protein = 5,
		/datum/reagent/consumable/nutriment/vitamin = 5,
		/datum/reagent/consumable/capsaicin = 2,
	)
	tastes = list("death" = 2, "rock" = 1, "meat" = 1, "hot peppers" = 1)
	foodtypes = MEAT
	w_class = WEIGHT_CLASS_SMALL
	venue_value = FOOD_PRICE_LEGENDARY
	crafting_complexity = FOOD_COMPLEXITY_5
	crafted_food_buff = /datum/status_effect/food/trait/ashstorm_immune

/obj/item/food/chipsandsalsa
	name = "chips and salsa"
	desc = "Some tortilla chips with a cup of zesty salsa. Highly addictive!"
	icon = 'icons/obj/food/mexican.dmi'
	icon_state = "chipsandsalsa"
	trash_type = /obj/item/reagent_containers/cup/bowl
	food_reagents = list(
		/datum/reagent/consumable/nutriment = 4,
		/datum/reagent/consumable/capsaicin = 2,
		/datum/reagent/consumable/nutriment/vitamin = 4,
	)
	tastes = list("peppers" = 1, "salsa" = 3, "tortilla chips" = 1, "onion" = 1)
	foodtypes = VEGETABLES
	w_class = WEIGHT_CLASS_SMALL
	crafting_complexity = FOOD_COMPLEXITY_3

/obj/item/food/classic_chimichanga
	name = "classic chimichanga"
	desc = "A deep-fried burrito packed with a generous amount of meat and cheese."
	icon = 'icons/obj/food/mexican.dmi'
	icon_state = "classic_chimichanga"
	food_reagents = list(
		/datum/reagent/consumable/nutriment = 8,
		/datum/reagent/consumable/nutriment/vitamin = 4,
		/datum/reagent/consumable/nutriment/protein = 6,
	)
	tastes = list("deep-fried tortilla" = 1, "meat" = 3, "cheese" = 1, "onions" = 1)
	foodtypes = MEAT | GRAIN | VEGETABLES | DAIRY | FRIED
	w_class = WEIGHT_CLASS_SMALL
	crafting_complexity = FOOD_COMPLEXITY_3

/obj/item/food/vegetarian_chimichanga
	name = "vegetarian chimichanga"
	desc = "A deep-fried burrito packed with a generous amount of baked vegetables, for the non-meat eaters."
	icon = 'icons/obj/food/mexican.dmi'
	icon_state = "vegetarian_chimichanga"
	food_reagents = list(
		/datum/reagent/consumable/nutriment = 8,
		/datum/reagent/consumable/nutriment/vitamin = 10,
	)
	tastes = list("deep-fried tortilla" = 1, "cabbage" = 3, "onions" = 1, "peppers" = 1)
	foodtypes = GRAIN | VEGETABLES | FRIED
	w_class = WEIGHT_CLASS_SMALL
	crafting_complexity = FOOD_COMPLEXITY_3

/obj/item/food/hard_taco_shell
	name = "hard taco shell"
	desc = "A hard taco shell, just waiting to be stuffed with ingredients. Use an ingredient on it to start making custom tacos!"
	icon = 'icons/obj/food/mexican.dmi'
	icon_state = "hard_taco_shell"
	food_reagents = list(/datum/reagent/consumable/nutriment = 2)
	tastes = list("hard corn tortilla" = 1)
	foodtypes = GRAIN | FRIED
	w_class = WEIGHT_CLASS_SMALL
	crafting_complexity = FOOD_COMPLEXITY_1

/obj/item/food/hard_taco_shell/Initialize(mapload)
	. = ..()
	AddComponent(/datum/component/ingredients_holder, /obj/item/food/hard_taco_shell/empty, CUSTOM_INGREDIENT_ICON_FILL, max_ingredients = 6)

// empty taco shell for custom tacos
/obj/item/food/hard_taco_shell/empty
	name = "hard-shell taco"
	foodtypes = NONE
	tastes = list()
	icon_state = "hard_taco_shell"
	desc = "A customized hard-shell taco."
	crafting_complexity = FOOD_COMPLEXITY_1

/obj/item/food/classic_hard_shell_taco
	name = "classic hard-shell taco"
	desc = "A classically-made hard-shell taco, the most satisfying crunch in the galaxy."
	icon = 'icons/obj/food/mexican.dmi'
	icon_state = "classic_hard_shell_taco"
	food_reagents = list(
		/datum/reagent/consumable/nutriment = 8,
		/datum/reagent/consumable/nutriment/vitamin = 6,
		/datum/reagent/consumable/nutriment/protein = 6,
	)
	tastes = list("crunchy taco shell" = 1, "cabbage" = 3, "tomatoes" = 1, "ground meat" = 1, "cheese" = 1)
	foodtypes = GRAIN | VEGETABLES | MEAT | DAIRY
	w_class = WEIGHT_CLASS_SMALL
	crafting_complexity = FOOD_COMPLEXITY_4

/obj/item/food/plain_hard_shell_taco
	name = "plain hard-shell taco"
	desc = "A hard-shell taco with just meat, for the picky eaters and children in us all."
	icon = 'icons/obj/food/mexican.dmi'
	icon_state = "plain_hard_shell_taco"
	food_reagents = list(
		/datum/reagent/consumable/nutriment = 6,
		/datum/reagent/consumable/nutriment/vitamin = 3,
		/datum/reagent/consumable/nutriment/protein = 6,
	)
	tastes = list("crunchy taco shell" = 1, "ground meat" = 1)
	foodtypes = GRAIN | MEAT
	w_class = WEIGHT_CLASS_SMALL
	crafting_complexity = FOOD_COMPLEXITY_2

/obj/item/food/refried_beans
	name = "refried beans"
	desc = "A steaming bowl of delicious refried beans, a common staple in Mexican cuisine."
	icon = 'icons/obj/food/mexican.dmi'
	icon_state = "refried_beans"
	food_reagents = list(
		/datum/reagent/consumable/nutriment = 6,
		/datum/reagent/consumable/nutriment/vitamin = 6,
		/datum/reagent/consumable/nutriment/protein = 4,
	)
	trash_type = /obj/item/reagent_containers/cup/bowl
	tastes = list("mashed beans" = 1, "onion" = 3,)
	foodtypes = VEGETABLES | FRIED
	w_class = WEIGHT_CLASS_SMALL
	crafting_complexity = FOOD_COMPLEXITY_2

/obj/item/food/spanish_rice
	name = "spanish rice"
	desc = "A bowl of delicious spanish rice, cooked in a tomato sauce which gives it the orange color."
	icon = 'icons/obj/food/mexican.dmi'
	icon_state = "spanish_rice"
	food_reagents = list(
		/datum/reagent/consumable/nutriment = 6,
		/datum/reagent/consumable/nutriment/vitamin = 6,
	)
	trash_type = /obj/item/reagent_containers/cup/bowl
	tastes = list("zesty rice" = 1, "tomato sauce" = 3,)
	foodtypes = VEGETABLES
	w_class = WEIGHT_CLASS_SMALL
	crafting_complexity = FOOD_COMPLEXITY_2

/obj/item/food/pineapple_salsa
	name = "pineapple salsa"
	desc = "A not-so liquid salsa made of pineapples, tomatoes, onions, and chilis. Makes for delightfully contrasting flavors."
	icon = 'icons/obj/food/mexican.dmi'
	icon_state = "pineapple_salsa"
	trash_type = /obj/item/reagent_containers/cup/bowl
	food_reagents = list(
		/datum/reagent/consumable/nutriment = 6,
		/datum/reagent/consumable/nutriment/vitamin = 6,
	)
	tastes = list("pineapple" = 4, "tomato" = 3, "onion" = 2, "chili" = 2)
	foodtypes = VEGETABLES | FRUIT | PINEAPPLE
	w_class = WEIGHT_CLASS_SMALL
	crafting_complexity = FOOD_COMPLEXITY_3
