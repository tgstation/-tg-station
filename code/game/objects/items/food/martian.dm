//Ingredients and Simple Dishes
/obj/item/food/kimchi
	name = "kimchi"
	desc = "A classic Korean dish in the Martian style: shredded cabbage with chilli peppers, konbu, bonito, and a mix of spices."
	icon = 'icons/obj/food/martian.dmi'
	icon_state = "kimchi"
	food_reagents = list(
		/datum/reagent/consumable/nutriment/vitamin = 3,
		/datum/reagent/consumable/capsaicin = 1,
	)
	tastes = list("spicy cabbage" = 1)
	foodtypes = VEGETABLES
	w_class = WEIGHT_CLASS_SMALL
	crafting_complexity = FOOD_COMPLEXITY_2

/obj/item/food/inferno_kimchi
	name = "inferno kimchi"
	desc = "For when ordinary kimchi just can't scratch your itch for insane heat, inferno kimchi picks up the slack."
	icon = 'icons/obj/food/martian.dmi'
	icon_state = "inferno_kimchi"
	food_reagents = list(
		/datum/reagent/consumable/nutriment/vitamin = 3,
		/datum/reagent/consumable/capsaicin = 3,
	)
	tastes = list("very spicy cabbage" = 1)
	foodtypes = VEGETABLES
	w_class = WEIGHT_CLASS_SMALL
	crafting_complexity = FOOD_COMPLEXITY_2

/obj/item/food/garlic_kimchi
	name = "garlic kimchi"
	desc = "A new twist on a classic formula- kimchi and garlic, finally together in perfect harmony."
	icon = 'icons/obj/food/martian.dmi'
	icon_state = "garlic_kimchi"
	food_reagents = list(
		/datum/reagent/consumable/nutriment/vitamin = 3,
		/datum/reagent/consumable/capsaicin = 1,
		/datum/reagent/consumable/garlic = 2,
	)
	tastes = list("spicy cabbage" = 1, "garlic" = 1)
	foodtypes = VEGETABLES
	w_class = WEIGHT_CLASS_SMALL
	crafting_complexity = FOOD_COMPLEXITY_2

/obj/item/food/surimi
	name = "surimi"
	desc = "A portion of uncured fish surimi."
	icon = 'icons/obj/food/martian.dmi'
	icon_state = "surimi"
	food_reagents = list(
		/datum/reagent/consumable/nutriment/protein = 4,
		/datum/reagent/consumable/nutriment/vitamin = 2,
	)
	tastes = list("fish" = 1)
	foodtypes = SEAFOOD
	w_class = WEIGHT_CLASS_SMALL
	crafting_complexity = FOOD_COMPLEXITY_2

/obj/item/food/surimi/Initialize(mapload)
	. = ..()
	AddElement(/datum/element/dryable, /obj/item/food/kamaboko)

/obj/item/food/kamaboko
	name = "kamaboko"
	desc = "A Japanese-style cured fishcake frequently used in snacks and ramen."
	icon = 'icons/obj/food/martian.dmi'
	icon_state = "kamaboko_sunrise"
	food_reagents = list(
		/datum/reagent/consumable/nutriment/protein = 4,
		/datum/reagent/consumable/nutriment/vitamin = 4,
	)
	tastes = list("fish" = 1)
	foodtypes = SEAFOOD
	w_class = WEIGHT_CLASS_SMALL
	crafting_complexity = FOOD_COMPLEXITY_3

/obj/item/food/kamaboko/Initialize(mapload)
	. = ..()
	var/design = pick("smiling", "spiral", "star", "sunrise")
	name = "[design] kamaboko"
	icon_state = "kamaboko_[design]"

/obj/item/food/kamaboko/make_processable()
	AddElement(/datum/element/processable, TOOL_KNIFE, /obj/item/food/kamaboko_slice, 4, 3 SECONDS, table_required = TRUE, screentip_verb = "Cut")

/obj/item/food/kamaboko_slice
	name = "kamaboko slice"
	desc = "A slice of fishcake. Goes good in ramen."
	icon = 'icons/obj/food/martian.dmi'
	icon_state = "kamaboko_slice"
	food_reagents = list(
		/datum/reagent/consumable/nutriment/protein = 1,
		/datum/reagent/consumable/nutriment/vitamin = 1,
	)
	tastes = list("fish" = 1)
	foodtypes = SEAFOOD
	w_class = WEIGHT_CLASS_TINY
	crafting_complexity = FOOD_COMPLEXITY_3

/obj/item/food/sambal
	name = "sambal"
	desc = "A spice paste from Indonesia, used widely in cooking throughout South East Asia."
	icon = 'icons/obj/food/martian.dmi'
	icon_state = "sambal"
	trash_type = /obj/item/reagent_containers/cup/bowl
	food_reagents = list(
		/datum/reagent/consumable/nutriment/vitamin = 5,
		/datum/reagent/consumable/capsaicin = 2
	)
	tastes = list("chilli heat" = 1, "umami" = 1)
	foodtypes = SEAFOOD | VEGETABLES
	w_class = WEIGHT_CLASS_SMALL
	crafting_complexity = FOOD_COMPLEXITY_2

/obj/item/food/katsu_fillet
	name = "katsu fillet"
	desc = "Breaded and deep fried meat, used for a variety of dishes."
	icon = 'icons/obj/food/martian.dmi'
	icon_state = "katsu_fillet"
	food_reagents = list(
		/datum/reagent/consumable/nutriment/protein = 6,
		/datum/reagent/consumable/nutriment/vitamin = 2,
		/datum/reagent/consumable/nutriment = 2
	)
	tastes = list("meat" = 1, "breadcrumbs" = 1)
	foodtypes = MEAT | GRAIN
	w_class = WEIGHT_CLASS_SMALL
	crafting_complexity = FOOD_COMPLEXITY_2

/obj/item/food/rice_dough
	name = "rice dough"
	desc = "A piece of dough made with equal parts rice flour and wheat flour, for a unique flavour."
	icon = 'icons/obj/food/martian.dmi'
	icon_state = "rice_dough"
	food_reagents = list(
		/datum/reagent/consumable/nutriment = 6
	)
	tastes = list("rice" = 1)
	foodtypes = GRAIN
	crafting_complexity = FOOD_COMPLEXITY_2

/obj/item/food/rice_dough/make_bakeable()
	AddComponent(/datum/component/bakeable, /obj/item/food/bread/reispan, rand(30 SECONDS, 45 SECONDS), TRUE, TRUE)

/obj/item/food/rice_dough/make_processable()
	AddElement(/datum/element/processable, TOOL_KNIFE, /obj/item/food/spaghetti/rawnoodles, 6, 3 SECONDS, table_required = TRUE)

/obj/item/food/spaghetti/rawnoodles
	name = "fresh noodles"
	desc = "Rice noodles, made fresh. Remember, there is no secret ingredient."
	icon = 'icons/obj/food/martian.dmi'
	icon_state = "raw_noodles"

	food_reagents = list(
		/datum/reagent/consumable/nutriment = 3
	)
	tastes = list("rice" = 1)
	foodtypes = GRAIN
	crafting_complexity = FOOD_COMPLEXITY_2

/obj/item/food/spaghetti/boilednoodles
	name = "cooked noodles"
	desc = "Cooked fresh to order."
	icon = 'icons/obj/food/martian.dmi'
	icon_state = "cooked_noodles"
	food_reagents = list(
		/datum/reagent/consumable/nutriment = 3
	)
	tastes = list("rice" = 1)
	foodtypes = GRAIN
	crafting_complexity = FOOD_COMPLEXITY_3

/obj/item/food/bread/reispan
	name = "reispan"
	desc = "Though the concept of rice bread has been common in Asia for centuries, the reispan as we know it today is most commonly associated with Mars- where limited arable land has forced ingenuity."
	icon = 'icons/obj/food/martian.dmi'
	icon_state = "reispan"
	food_reagents = list(
		/datum/reagent/consumable/nutriment = 15
	)
	tastes = list("bread" = 10)
	foodtypes = GRAIN
	venue_value = FOOD_PRICE_TRASH
	crafting_complexity = FOOD_COMPLEXITY_3

/obj/item/food/bread/reispan/make_processable()
	AddElement(/datum/element/processable, TOOL_KNIFE, /obj/item/food/breadslice/reispan, 5, 3 SECONDS, table_required = TRUE)

/obj/item/food/breadslice/reispan
	name = "reispan slice"
	desc = "A slice of reispan, for use in Martian-style sandwiches."
	icon = 'icons/obj/food/martian.dmi'
	icon_state = "reispan_slice"
	food_reagents = list(
		/datum/reagent/consumable/nutriment = 3
	)
	foodtypes = GRAIN | VEGETABLES
	crafting_complexity = FOOD_COMPLEXITY_3

// Fried Rice

/obj/item/food/salad/hurricane_rice
	name = "hurricane fried rice"
	desc = "Inspired by nasi goreng, this piquant rice dish comes straight from Prospect, on Mars, and its night markets. It's named for its distinctive cooking style, where the frying rice is given lots of airtime while being flipped, mostly because it looks really cool for the customers."
	icon = 'icons/obj/food/martian.dmi'
	icon_state = "hurricane_rice"
	food_reagents = list(
		/datum/reagent/consumable/nutriment = 10,
		/datum/reagent/consumable/nutriment/protein = 6,
		/datum/reagent/consumable/nutriment/vitamin = 10,
	)
	tastes = list("rice" = 1, "meat" = 1, "pineapple" = 1, "veggies" = 1)
	foodtypes = MEAT | GRAIN | PINEAPPLE | FRUIT | VEGETABLES
	w_class = WEIGHT_CLASS_SMALL
	crafting_complexity = FOOD_COMPLEXITY_3

/obj/item/food/salad/ikareis
	name = "ikareis"
	desc = "A spicy rice dish made with squid-ink, peppers, onions, sausage, and flavourful chillis."
	icon = 'icons/obj/food/martian.dmi'
	icon_state = "ikareis"
	food_reagents = list(
		/datum/reagent/consumable/nutriment = 10,
		/datum/reagent/consumable/nutriment/protein = 10,
		/datum/reagent/consumable/nutriment/vitamin = 6,
		/datum/reagent/consumable/capsaicin = 4
	)
	tastes = list("rice" = 1, "squid ink" = 1, "veggies" = 1, "sausage" = 1, "chilli heat" = 1)
	foodtypes = MEAT | GRAIN | SEAFOOD | VEGETABLES
	w_class = WEIGHT_CLASS_SMALL
	crafting_complexity = FOOD_COMPLEXITY_4

/obj/item/food/salad/hawaiian_fried_rice
	name = "\improper Hawaiian fried rice"
	desc = "Not a traditional Hawaiian dish, Hawaiian fried rice instead utilises a pastiche of Hawaiian ingredients- including diced Chap and, controversially, pineapple. Purists are split on whether pineapple belongs in rice."
	icon = 'icons/obj/food/martian.dmi'
	icon_state = "hawaiian_fried_rice"
	food_reagents = list(
		/datum/reagent/consumable/nutriment = 10,
		/datum/reagent/consumable/nutriment/protein = 10,
		/datum/reagent/consumable/nutriment/vitamin = 8,
	)
	tastes = list("rice" = 1, "pork" = 1, "pineapple" = 1, "soy sauce" = 1, "veggies" = 1)
	foodtypes = MEAT | GRAIN | VEGETABLES | FRUIT | PINEAPPLE
	w_class = WEIGHT_CLASS_SMALL
	crafting_complexity = FOOD_COMPLEXITY_3

/obj/item/food/salad/ketchup_fried_rice
	name = "ketchup fried rice"
	desc = "A classic Japanese comfort food, made with sausage, veggies, worchestershire sauce, rice- oh, and of course, ketchup."
	icon = 'icons/obj/food/martian.dmi'
	icon_state = "ketchup_fried_rice"
	food_reagents = list(
		/datum/reagent/consumable/nutriment = 10,
		/datum/reagent/consumable/nutriment/protein = 8,
		/datum/reagent/consumable/nutriment/vitamin = 8,
		/datum/reagent/consumable/ketchup = 2,
	)
	tastes = list("rice" = 1, "sausage" = 1, "ketchup" = 1, "veggies" = 1)
	foodtypes = MEAT | GRAIN | VEGETABLES
	w_class = WEIGHT_CLASS_SMALL
	crafting_complexity = FOOD_COMPLEXITY_3

/obj/item/food/salad/mediterranean_fried_rice
	name = "mediterranean fried rice"
	desc = "A strange take on the fried rice formula: herbs, cheese, olives, and of course, meatballs. Sorta like a hybrid of risotto and fried rice."
	icon = 'icons/obj/food/martian.dmi'
	icon_state = "mediterranean_fried_rice"
	food_reagents = list(
		/datum/reagent/consumable/nutriment = 8,
		/datum/reagent/consumable/nutriment/protein = 10,
		/datum/reagent/consumable/nutriment/vitamin = 10,
	)
	tastes = list("rice" = 1, "cheese" = 1, "meatball" = 1, "olives" = 1, "herbs" = 1)
	foodtypes = MEAT | GRAIN | VEGETABLES | DAIRY
	w_class = WEIGHT_CLASS_SMALL
	crafting_complexity = FOOD_COMPLEXITY_3

/obj/item/food/salad/egg_fried_rice
	name = "egg fried rice"
	desc = "As simple as fried rice gets: rice, egg, soy sauce. Simple, elegant, and infinitely customisable."
	icon = 'icons/obj/food/martian.dmi'
	icon_state = "egg_fried_rice"
	food_reagents = list(
		/datum/reagent/consumable/nutriment = 8,
		/datum/reagent/consumable/nutriment/protein = 2,
	)
	tastes = list("rice" = 1, "egg" = 1, "soy sauce" = 1)
	foodtypes = MEAT | GRAIN
	w_class = WEIGHT_CLASS_SMALL
	crafting_complexity = FOOD_COMPLEXITY_2

/obj/item/food/salad/egg_fried_rice/Initialize(mapload)
	. = ..()
	AddComponent(/datum/component/ingredients_holder, null, CUSTOM_INGREDIENT_ICON_STACK)

/obj/item/food/salad/bibimbap
	name = "bibimbap"
	desc = "A Korean dish consisting of rice and various toppings, served in a hot stone bowl."
	icon = 'icons/obj/food/martian.dmi'
	icon_state = "bibimbap"
	food_reagents = list(
		/datum/reagent/consumable/nutriment/protein = 4,
		/datum/reagent/consumable/nutriment/vitamin = 8,
		/datum/reagent/consumable/nutriment = 6,
		/datum/reagent/consumable/capsaicin = 2,
	)
	tastes = list("rice" = 1, "spicy cabbage" = 1, "chilli heat" = 1, "egg" = 1, "meat" = 1)
	foodtypes = MEAT | VEGETABLES | GRAIN
	w_class = WEIGHT_CLASS_SMALL
	crafting_complexity = FOOD_COMPLEXITY_3

/obj/item/food/salad/bibimbap/Initialize(mapload)
	. = ..()
	AddComponent(/datum/component/ingredients_holder, null, CUSTOM_INGREDIENT_ICON_STACK)

// Noodles
/obj/item/food/salad/bulgogi_noodles
	name = "bulgogi noodles"
	desc = "Korean barbecue meat served with noodles! Made with gochujang, for extra spicy flavour."
	icon = 'icons/obj/food/martian.dmi'
	icon_state = "bulgogi_noodles"
	food_reagents = list(
		/datum/reagent/consumable/nutriment/protein = 8,
		/datum/reagent/consumable/nutriment = 8,
		/datum/reagent/consumable/capsaicin = 2,
	)
	tastes = list("barbecue meat" = 1, "noodles" = 1, "chilli heat" = 1)
	foodtypes = MEAT | GRAIN | VEGETABLES | FRUIT
	w_class = WEIGHT_CLASS_SMALL
	crafting_complexity = FOOD_COMPLEXITY_3

/obj/item/food/salad/yakisoba_katsu
	name = "yakisoba katsu"
	desc = "Breaded and deep fried meat on a bed of fried noodles. Delicious, if unconventional."
	icon = 'icons/obj/food/martian.dmi'
	icon_state = "yakisoba_katsu"
	food_reagents = list(
		/datum/reagent/consumable/nutriment/protein = 8,
		/datum/reagent/consumable/nutriment/vitamin = 4,
		/datum/reagent/consumable/nutriment = 8,
	)
	tastes = list("fried noodles" = 1, "meat" = 1, "breadcrumbs" = 1, "veggies" = 1)
	foodtypes = MEAT | VEGETABLES | GRAIN
	w_class = WEIGHT_CLASS_SMALL
	crafting_complexity = FOOD_COMPLEXITY_3

/obj/item/food/salad/martian_fried_noodles
	name = "\improper Martian fried noodles"
	desc = "Fried noodles from the red planet. Martian cooking draws from many cultures, and these noodles are no exception- there's elements of Malay, Thai, Chinese, Korean and Japanese cuisine in here."
	icon = 'icons/obj/food/martian.dmi'
	icon_state = "martian_fried_noodles"
	food_reagents = list(
		/datum/reagent/consumable/nutriment/protein = 8,
		/datum/reagent/consumable/nutriment/vitamin = 4,
		/datum/reagent/consumable/nutriment = 8,
	)
	tastes = list("noodles" = 1, "meat" = 1, "nuts" = 1, "onion" = 1, "egg" = 1)
	foodtypes = GRAIN | NUTS | MEAT | VEGETABLES
	w_class = WEIGHT_CLASS_SMALL
	crafting_complexity = FOOD_COMPLEXITY_3

/obj/item/food/salad/simple_fried_noodles
	name = "simple fried noodles"
	desc = "A simple yet delicious fried noodle dish, perfect for the creative chef to make whatever fried noodles they want."
	icon = 'icons/obj/food/martian.dmi'
	icon_state = "simple_fried_noodles"
	food_reagents = list(
		/datum/reagent/consumable/nutriment/protein = 4,
		/datum/reagent/consumable/nutriment/vitamin = 4,
		/datum/reagent/consumable/nutriment = 6,
	)
	tastes = list("noodles" = 1, "soy sauce" = 1)
	foodtypes = GRAIN
	w_class = WEIGHT_CLASS_SMALL
	crafting_complexity = FOOD_COMPLEXITY_2

/obj/item/food/salad/simple_fried_noodles/Initialize(mapload)
	. = ..()
	AddComponent(/datum/component/ingredients_holder, null, CUSTOM_INGREDIENT_ICON_STACK)

// Curry
/obj/item/food/salad/setagaya_curry //let me explain...
	name = "\improper Setagaya curry"
	desc = "Made famous by a cafe in Setagaya, this curry's extensive recipe has gone on to be a closely-guarded secret amongst cafe owners across human space. The taste is said to replenish the diner's soul, whatever that means."
	icon = 'icons/obj/food/martian.dmi'
	icon_state = "setagaya_curry"
	food_reagents = list(
		/datum/reagent/consumable/nutriment/protein = 8,
		/datum/reagent/consumable/nutriment/vitamin = 8,
		/datum/reagent/consumable/nutriment = 8,
		/datum/reagent/medicine/omnizine = 5,
	)
	tastes = list("masterful curry" = 1, "rice" = 1)
	foodtypes = GRAIN | MEAT | VEGETABLES
	w_class = WEIGHT_CLASS_SMALL
	crafting_complexity = FOOD_COMPLEXITY_5 //Extensive and secretly guarded. Was previously 2 and I thought it was pathetic.

// Burgers and Sandwiches
/obj/item/food/burger/big_blue
	name = "\improper Big Blue burger"
	desc = "The original and best Big Blue, straight outta Mars' favourite burger joint. Catch the wave, brother!"
	icon = 'icons/obj/food/martian.dmi'
	icon_state = "big_blue_burger"
	food_reagents = list(
		/datum/reagent/consumable/nutriment = 4,
		/datum/reagent/consumable/nutriment/protein = 8,
		/datum/reagent/consumable/nutriment/vitamin = 8,
	)
	tastes = list("bun" = 1, "burger" = 2, "teriyaki onions" = 1, "cheese" = 1, "bacon" = 1, "pineapple" = 1)
	foodtypes = MEAT | GRAIN | DAIRY | VEGETABLES | FRUIT | PINEAPPLE
	w_class = WEIGHT_CLASS_SMALL
	crafting_complexity = FOOD_COMPLEXITY_4 //It's THE big blue, Baby!

/obj/item/food/burger/chappy
	name = "\improper Chappy patty"
	desc = "Originally born of a night of drinking in a Big Blue Burger's kitchen, the Chappy patty has since become a staple of both Big Blue's menu and Hawaiian (or at least, faux-Hawaiian) cuisine galaxy-wide. Given Big Kahuna operates most of its stores on Mars, it's perhaps no wonder this dish is popular there."
	icon = 'icons/obj/food/martian.dmi'
	icon_state = "chappy_patty"
	food_reagents = list(
		/datum/reagent/consumable/nutriment = 6,
		/datum/reagent/consumable/nutriment/protein = 6,
	)
	tastes = list("bun" = 1, "fried pork" = 2, "egg" = 1, "cheese" = 1, "ketchup" = 1)
	foodtypes = MEAT | GRAIN | DAIRY | VEGETABLES
	w_class = WEIGHT_CLASS_SMALL
	crafting_complexity = FOOD_COMPLEXITY_3

/obj/item/food/king_katsu_sandwich
	name = "\improper King Katsu sandwich"
	desc = "A big sandwich with crispy fried katsu, bacon, kimchi slaw and salad, all on reispan bread. Truly the king of meat between bread."
	icon = 'icons/obj/food/martian.dmi'
	icon_state = "king_katsu_sandwich"
	food_reagents = list(
		/datum/reagent/consumable/nutriment = 4,
		/datum/reagent/consumable/nutriment/protein = 6,
		/datum/reagent/consumable/nutriment/vitamin = 6,
		/datum/reagent/consumable/capsaicin = 1,
	)
	tastes = list("meat" = 1, "bacon" = 1, "kimchi" = 1, "salad" = 1, "rice bread" = 1)
	foodtypes = MEAT | GRAIN | VEGETABLES
	w_class = WEIGHT_CLASS_SMALL
	crafting_complexity = FOOD_COMPLEXITY_3

/obj/item/food/marte_cubano_sandwich
	name = "\improper Marte Cubano sandwich"
	desc = "A fusion food from Mars, the Marte-Cubano is based on the classic Cubano, but updated for ingredient availability and changes in tastes."
	icon = 'icons/obj/food/martian.dmi'
	icon_state = "marte_cubano_sandwich"
	food_reagents = list(
		/datum/reagent/consumable/nutriment = 6,
		/datum/reagent/consumable/nutriment/protein = 6,
		/datum/reagent/consumable/nutriment/vitamin = 4,
	)
	tastes = list("bacon" = 1, "pickles" = 1, "cheese" = 1, "rice bread" = 1)
	foodtypes = MEAT | DAIRY | VEGETABLES | GRAIN
	w_class = WEIGHT_CLASS_SMALL
	crafting_complexity = FOOD_COMPLEXITY_3

/obj/item/food/little_shiro_sandwich
	name = "\improper Little Shiro sandwich"
	desc = "A classic Martian sandwich, named for the first president of TerraGov to come from Mars. It features fried eggs, bulgogi beef, a kimchi salad, and a healthy topping of mozzarella cheese."
	icon = 'icons/obj/food/martian.dmi'
	icon_state = "marte_cubano_sandwich"
	food_reagents = list(
		/datum/reagent/consumable/nutriment = 4,
		/datum/reagent/consumable/nutriment/protein = 6,
		/datum/reagent/consumable/nutriment/vitamin = 6,
		/datum/reagent/consumable/capsaicin = 1,
	)
	tastes = list("egg" = 1, "meat" = 1, "kimchi" = 1, "mozzarella" = 1)
	foodtypes = MEAT | DAIRY | VEGETABLES | GRAIN
	w_class = WEIGHT_CLASS_SMALL
	crafting_complexity = FOOD_COMPLEXITY_3

/obj/item/food/croque_martienne
	name = "croque-martienne"
	desc = "The quintessential Martian breakfast sandwich. Egg, belly pork, pineapple, cheese. Simple. Classic. Available in every cafe across New Osaka."
	icon = 'icons/obj/food/martian.dmi'
	icon_state = "croque_martienne"
	food_reagents = list(
		/datum/reagent/consumable/nutriment = 4,
		/datum/reagent/consumable/nutriment/protein = 8,
		/datum/reagent/consumable/nutriment/vitamin = 4,
	)
	tastes = list("egg" = 1, "toast" = 1, "pork" = 1, "pineapple" = 1, "cheese" = 1)
	foodtypes = MEAT | DAIRY | VEGETABLES | GRAIN | PINEAPPLE | BREAKFAST
	w_class = WEIGHT_CLASS_SMALL
	crafting_complexity = FOOD_COMPLEXITY_3

/obj/item/food/prospect_sunrise
	name = "\improper Prospect Sunrise"
	desc = "The second-most quintessential Martian breakfast sandwich. The most beautiful combination of omelette, bacon, pickles and cheese. Available in every cafe across Prospect."
	icon = 'icons/obj/food/martian.dmi'
	icon_state = "prospect_sunrise"
	food_reagents = list(
		/datum/reagent/consumable/nutriment = 5,
		/datum/reagent/consumable/nutriment/protein = 8,
		/datum/reagent/consumable/nutriment/vitamin = 3,
	)
	tastes = list("egg" = 1, "toast" = 1, "bacon" = 1, "pickles" = 1, "cheese" = 1)
	foodtypes = MEAT | DAIRY | VEGETABLES | GRAIN | BREAKFAST
	w_class = WEIGHT_CLASS_SMALL
	crafting_complexity = FOOD_COMPLEXITY_3

// Snacks
/obj/item/food/takoyaki
	name = "takoyaki"
	desc = "A classic Japanese street food, takoyaki (or octopus balls) are made from octopus and onion inside a fried batter, topped with a savoury sauce."
	icon = 'icons/obj/food/martian.dmi'
	icon_state = "takoyaki"
	food_reagents = list(
		/datum/reagent/consumable/nutriment = 4,
		/datum/reagent/consumable/nutriment/protein = 4,
		/datum/reagent/consumable/nutriment/fat/oil = 2,
	)
	tastes = list("octopus" = 1, "batter" = 1, "onion" = 1, "worcestershire sauce" = 1)
	foodtypes = SEAFOOD | GRAIN | FRIED | VEGETABLES
	w_class = WEIGHT_CLASS_SMALL
	crafting_complexity = FOOD_COMPLEXITY_3

/obj/item/food/takoyaki/russian
	name = "Russian takoyaki"
	desc = "A dangerous twist on a classic dish, that makes for the perfect cover for evading the police."
	icon = 'icons/obj/food/martian.dmi'
	icon_state = "russian_takoyaki"
	food_reagents = list(
		/datum/reagent/consumable/nutriment = 4,
		/datum/reagent/consumable/nutriment/protein = 4,
		/datum/reagent/consumable/capsaicin = 10,
	)
	tastes = list("octopus" = 1, "batter" = 1, "onion" = 1, "chilli heat" = 1)
	foodtypes = SEAFOOD | GRAIN | FRIED | VEGETABLES
	w_class = WEIGHT_CLASS_SMALL
	crafting_complexity = FOOD_COMPLEXITY_3

/obj/item/food/takoyaki/taco
	name = "tacoyaki"
	desc = "Straight outta Mars' most innovative street food stands, it's tacoyaki- trading octopus for taco meat and corn, and Worcestershire sauce for queso. ¡Tan sabroso!"
	icon = 'icons/obj/food/martian.dmi'
	icon_state = "tacoyaki"
	food_reagents = list(
		/datum/reagent/consumable/nutriment = 4,
		/datum/reagent/consumable/nutriment/protein = 4,
		/datum/reagent/consumable/nutriment/fat/oil = 2,
	)
	tastes = list("taco meat" = 1, "batter" = 1, "corn" = 1, "cheese" = 1)
	foodtypes = MEAT | GRAIN | FRIED | VEGETABLES | DAIRY
	w_class = WEIGHT_CLASS_SMALL
	crafting_complexity = FOOD_COMPLEXITY_4 //Batter AND Cargo ingredients.

/obj/item/food/okonomiyaki
	name = "okonomiyaki"
	desc = "A Kansai classic, okonomiyaki consists of a savoury pancake filled with... well, whatever you want- although cabbage, nagaimo and dashi are pretty much required, as is the eponymous okonomiyaki sauce."
	icon = 'icons/obj/food/martian.dmi'
	icon_state = "okonomiyaki"
	food_reagents = list(
		/datum/reagent/consumable/nutriment = 4,
		/datum/reagent/consumable/nutriment/vitamin = 6,
	)
	tastes = list("batter" = 1, "cabbage" = 1, "onion" = 1, "worcestershire sauce" = 1)
	foodtypes = SEAFOOD | GRAIN | FRIED | VEGETABLES
	w_class = WEIGHT_CLASS_SMALL
	crafting_complexity = FOOD_COMPLEXITY_4 //Cargo stuff and batter.

//hey, the name literally means "grilled how you like it", it'd be crazy to not make it customisable
/obj/item/food/okonomiyaki/Initialize(mapload)
	. = ..()
	AddComponent(/datum/component/ingredients_holder, null, CUSTOM_INGREDIENT_ICON_STACK)

/obj/item/food/brat_kimchi
	name = "brat-kimchi"
	desc = "Fried kimchi, mixed with sugar and topped with bratwurst. A popular dish at izakayas on Mars."
	icon = 'icons/obj/food/martian.dmi'
	icon_state = "brat_kimchi"
	food_reagents = list(
		/datum/reagent/consumable/nutriment/vitamin = 4,
		/datum/reagent/consumable/nutriment/protein = 4,
		/datum/reagent/consumable/capsaicin = 2,
		/datum/reagent/consumable/sugar = 2,
	)
	tastes = list("spicy cabbage" = 1, "sausage" = 1)
	foodtypes = MEAT | VEGETABLES
	w_class = WEIGHT_CLASS_SMALL
	crafting_complexity = FOOD_COMPLEXITY_3

/obj/item/food/tonkatsuwurst
	name = "tonkatsuwurst"
	desc = "A cultural fusion between German and Japanese cooking, tonkatsuwurst blends the currywurst and tonkatsu sauce into something familiar, yet new."
	icon = 'icons/obj/food/martian.dmi'
	icon_state = "tonkatsuwurst"
	food_reagents = list(
		/datum/reagent/consumable/nutriment/vitamin = 3,
		/datum/reagent/consumable/nutriment/protein = 6,
		/datum/reagent/consumable/worcestershire = 2,
	)
	tastes = list("sausage" = 1, "spicy sauce" = 1, "fries" = 1)
	foodtypes = MEAT | VEGETABLES
	w_class = WEIGHT_CLASS_SMALL
	crafting_complexity = FOOD_COMPLEXITY_4 //Cargo ingredients and a few steps.

/obj/item/food/kebab/ti_hoeh_koe
	name = "ti hoeh koe skewer"
	desc = "Pig blood, mixed with rice, fried, and topped with peanut and coriander. It's an... acquired taste for sure, but it's popular at Prospect's night markets, brought by Taiwanese settlers."
	icon = 'icons/obj/food/martian.dmi'
	icon_state = "ti_hoeh_koe"
	food_reagents = list(
		/datum/reagent/consumable/nutriment/vitamin = 1,
		/datum/reagent/consumable/nutriment/protein = 5,
		/datum/reagent/consumable/peanut_butter = 1,
	)
	tastes = list("blood" = 1, "nuts" = 1, "herbs" = 1)
	foodtypes = MEAT | NUTS | GRAIN
	w_class = WEIGHT_CLASS_SMALL
	crafting_complexity = FOOD_COMPLEXITY_3

/obj/item/food/kitzushi
	name = "kitzushi"
	desc = "A variant on inarizushi popular on Mars amongst vulpinids (and the wider animalid community), kitzushi integrates a spicy cheese and chilli mix inside the pocket for extra flavour."
	icon = 'icons/obj/food/martian.dmi'
	icon_state = "kitzushi"
	food_reagents = list(
		/datum/reagent/consumable/nutriment/protein = 3,
		/datum/reagent/consumable/nutriment = 3,
		/datum/reagent/consumable/capsaicin = 2,
	)
	tastes = list("rice" = 1, "tofu" = 1, "chilli cheese" = 1)
	foodtypes = GRAIN | FRIED | VEGETABLES | DAIRY
	w_class = WEIGHT_CLASS_SMALL
	crafting_complexity = FOOD_COMPLEXITY_2

/obj/item/food/epok_epok
	name = "epok-epok"
	desc = "A fried pastry snack from Malaysia, which migrated via Singapore into the Martian diet. Stuffed with curried chicken and potatoes, alongside a slice of hard boiled egg, it's a popular street food on the Red Planet."
	icon = 'icons/obj/food/martian.dmi'
	icon_state = "epok_epok"
	food_reagents = list(
		/datum/reagent/consumable/nutriment = 4,
		/datum/reagent/consumable/nutriment/protein = 4,
	)
	tastes = list("curry" = 1, "egg" = 1, "pastry" = 1)
	foodtypes = GRAIN | MEAT | VEGETABLES | FRIED
	w_class = WEIGHT_CLASS_SMALL
	crafting_complexity = FOOD_COMPLEXITY_3

/obj/item/food/roti_john
	name = "roti john"
	desc = "A classic Malaysian snack, the roti john consists of bread fried in a mixture of meat, egg and onion, yielding a result that's somewhere between French toast and an omelette."
	icon = 'icons/obj/food/martian.dmi'
	icon_state = "roti_john"
	food_reagents = list(
		/datum/reagent/consumable/nutriment/vitamin = 6,
		/datum/reagent/consumable/nutriment/protein = 8,
		/datum/reagent/consumable/nutriment = 10,
	)
	tastes = list("bread" = 1, "egg" = 1, "meat" = 1, "onion" = 1)
	foodtypes = GRAIN | MEAT | VEGETABLES | FRIED | BREAKFAST
	w_class = WEIGHT_CLASS_SMALL
	crafting_complexity = FOOD_COMPLEXITY_4

/obj/item/food/izakaya_fries
	name = "izakaya fries"
	desc = "New Osaka's favourite fries, 2 centuries running- and it's all thanks to the marriage of Red Bay, furikake and mayonnaise."
	icon = 'icons/obj/food/martian.dmi'
	icon_state = "izakaya_fries"
	food_reagents = list(
		/datum/reagent/consumable/nutriment = 6,
		/datum/reagent/consumable/nutriment/protein = 2,
		/datum/reagent/consumable/capsaicin = 2,
		/datum/reagent/consumable/salt = 2,
	)
	tastes = list("fries" = 1, "mars" = 1)
	foodtypes = VEGETABLES | FRIED
	w_class = WEIGHT_CLASS_SMALL
	crafting_complexity = FOOD_COMPLEXITY_3 //Extra complexity due to cargo ingredient.

/obj/item/food/kurry_ok_subsando
	name = "kurry-ok subsando"
	desc = "The bunny chow meets Martian ingenuity in the form of the kurry-ok subsando, with fries and katsu curry in perfect harmony."
	icon = 'icons/obj/food/martian.dmi'
	icon_state = "kurry_ok_subsando"
	food_reagents = list(
		/datum/reagent/consumable/nutriment = 10,
		/datum/reagent/consumable/nutriment/protein = 6,
		/datum/reagent/consumable/nutriment/vitamin = 8,
	)
	tastes = list("bread" = 1, "spicy fries" = 1, "mayonnaise" = 1, "curry" = 1, "meat" = 1)
	foodtypes = MEAT | GRAIN | VEGETABLES | FRIED
	w_class = WEIGHT_CLASS_SMALL
	crafting_complexity = FOOD_COMPLEXITY_4

/obj/item/food/loco_moco
	name = "loco moco"
	desc = "A simple classic from Hawaii. Makes for a filling, tasty, and cheap meal."
	icon = 'icons/obj/food/martian.dmi'
	icon_state = "loco_moco"
	food_reagents = list(
		/datum/reagent/consumable/nutriment = 6,
		/datum/reagent/consumable/nutriment/protein = 8,
	)
	tastes = list("rice" = 1, "burger" = 1, "gravy" = 1, "egg" = 1)
	foodtypes = MEAT | GRAIN | VEGETABLES
	w_class = WEIGHT_CLASS_SMALL
	crafting_complexity = FOOD_COMPLEXITY_2

/obj/item/food/wild_duck_fries
	name = "wild duck fries"
	desc = "Fries with shredded duck, ketchup, mayo, and Red Bay. A classic street food on Mars, although they're most often associated with Kwik-Kwak, Mars' favourite (and indeed, only) duck themed fast food chain."
	icon = 'icons/obj/food/martian.dmi'
	icon_state = "wild_duck_fries"
	food_reagents = list(
		/datum/reagent/consumable/nutriment = 8,
		/datum/reagent/consumable/nutriment/protein = 6,
		/datum/reagent/consumable/capsaicin = 2,
		/datum/reagent/consumable/salt = 2,
	)
	tastes = list("fries" = 1, "duck" = 1, "ketchup" = 1, "mayo" = 1, "spicy seasoning" = 1)
	foodtypes = MEAT | VEGETABLES | FRIED
	w_class = WEIGHT_CLASS_SMALL
	crafting_complexity = FOOD_COMPLEXITY_4 //Requires a complex 3 as an ingredient.

/obj/item/food/little_hawaii_hotdog
	name = "\improper Little Hawaii hotdog"
	desc = "From the friendly vendors of Honolulu Avenue comes the Little Hawaii dog- tropical and fattening, all at the same time!"
	icon = 'icons/obj/food/martian.dmi'
	icon_state = "little_hawaii_hotdog"
	food_reagents = list(
		/datum/reagent/consumable/nutriment = 4,
		/datum/reagent/consumable/nutriment/protein = 6,
		/datum/reagent/consumable/nutriment/vitamin = 6,
	)
	tastes = list("sausage" = 1, "pineapple" = 1, "onion" = 1, "teriyaki" = 1)
	foodtypes = MEAT | VEGETABLES | FRUIT | PINEAPPLE
	w_class = WEIGHT_CLASS_SMALL
	crafting_complexity = FOOD_COMPLEXITY_4
	custom_price = PAYCHECK_CREW * 1.2

/obj/item/food/salt_chilli_fries
	name = "salt n' chilli fries"
	desc = "The simple name of this dish doesn't tell the full story of its deliciousness- sure, salt and chilli are big components, but the onion, ginger and garlic are the real flavour heroes here."
	icon = 'icons/obj/food/martian.dmi'
	icon_state = "salt_chilli_fries"
	food_reagents = list(
		/datum/reagent/consumable/nutriment = 8,
		/datum/reagent/consumable/nutriment/vitamin = 4,
		/datum/reagent/consumable/capsaicin = 2,
		/datum/reagent/consumable/salt = 2,
	)
	tastes = list("fries" = 1, "garlic" = 1, "ginger" = 1, "numbing heat" = 1, "salt" = 1)
	foodtypes = VEGETABLES | FRIED
	w_class = WEIGHT_CLASS_SMALL
	crafting_complexity = FOOD_COMPLEXITY_3

/obj/item/food/grilled_octopus
	name = "grilled octopus tentacle"
	desc = "A simple seafood dish, typical to everywhere that octopus is eaten. Martians like it with Red Bay."
	icon = 'icons/obj/food/martian.dmi'
	icon_state = "grilled_octopus"
	food_reagents = list(
		/datum/reagent/consumable/nutriment/protein = 6,
		/datum/reagent/consumable/nutriment/vitamin = 2,
		/datum/reagent/consumable/char = 2)
	tastes = list("octopus" = 1)
	foodtypes = SEAFOOD | FRIED
	w_class = WEIGHT_CLASS_SMALL
	crafting_complexity = FOOD_COMPLEXITY_3

/obj/item/food/steak_croquette
	name = "steak croquette"
	desc = "Man, sticking chunks of steak in a croquette. Must be the countryside way."
	icon = 'icons/obj/food/martian.dmi'
	icon_state = "steak_croquette"
	food_reagents = list(
		/datum/reagent/consumable/nutriment = 3,
		/datum/reagent/consumable/nutriment/protein = 6,
	)
	tastes = list("steak" = 1, "potato" = 1)
	foodtypes = MEAT | VEGETABLES | FRIED
	w_class = WEIGHT_CLASS_SMALL
	crafting_complexity = FOOD_COMPLEXITY_3

/obj/item/food/chapsilog
	name = "chapsilog"
	desc = "A traditional Filipino-style silog consisting of sinangag, a fried egg, and slices of chap. Makes for a simple, yet filling, breakfast."
	icon = 'icons/obj/food/martian.dmi'
	icon_state = "chapsilog"
	food_reagents = list(
		/datum/reagent/consumable/nutriment = 6,
		/datum/reagent/consumable/nutriment/protein = 6,
		/datum/reagent/consumable/nutriment/vitamin = 3,
		/datum/reagent/consumable/garlic = 1,
	)
	tastes = list("ham" = 1, "garlic rice" = 1, "egg" = 1)
	foodtypes = MEAT | GRAIN | VEGETABLES | BREAKFAST
	w_class = WEIGHT_CLASS_SMALL
	crafting_complexity = FOOD_COMPLEXITY_3

/obj/item/food/chap_hash
	name = "chap hash"
	desc = "What do you get when you combine chap, onions, peppers and potatoes? The chap hash, of course! Add some red bay, and you've got yourself a tasty breakfast."
	icon = 'icons/obj/food/martian.dmi'
	icon_state = "chap_hash"
	food_reagents = list(
		/datum/reagent/consumable/nutriment/vitamin = 6,
		/datum/reagent/consumable/nutriment/protein = 6,
		/datum/reagent/consumable/nutriment = 3,
	)
	tastes = list("ham" = 1, "onion" = 1, "pepper" = 1, "potato" = 1)
	foodtypes = MEAT | VEGETABLES | BREAKFAST
	w_class = WEIGHT_CLASS_SMALL
	crafting_complexity = FOOD_COMPLEXITY_3

/obj/item/food/salad/agedashi_tofu
	name = "agedashi tofu"
	desc = "Crispy fried tofu, served in a tasty umami broth. Frequently served at izakayas."
	icon = 'icons/obj/food/martian.dmi'
	icon_state = "agedashi_tofu"
	food_reagents = list(
		/datum/reagent/consumable/nutriment = 6,
		/datum/reagent/consumable/nutriment/protein = 2,
		/datum/reagent/consumable/nutriment/vitamin = 4,
	)
	tastes = list("umami broth" = 1, "tofu" = 1)
	foodtypes = SEAFOOD | VEGETABLES
	w_class = WEIGHT_CLASS_SMALL
	crafting_complexity = FOOD_COMPLEXITY_2

// Curries and Stews
/obj/item/food/salad/po_kok_gai
	name = "po kok gai"
	desc = "Also known as galinha à portuguesa, or Portuguese chicken, this dish is a Macanese classic born of Portuguese colonialism, though the dish itself is not a Portuguese dish. It consists of chicken in \"Portuguese Sauce\", a mild coconut-based curry."
	icon = 'icons/obj/food/martian.dmi'
	icon_state = "po_kok_gai"
	food_reagents = list(
		/datum/reagent/consumable/nutriment = 4,
		/datum/reagent/consumable/nutriment/protein = 8,
		/datum/reagent/consumable/nutriment/vitamin = 2,
	)
	tastes = list("chicken" = 1, "coconut" = 1, "curry" = 1)
	foodtypes = MEAT | VEGETABLES | FRUIT
	w_class = WEIGHT_CLASS_SMALL
	crafting_complexity = FOOD_COMPLEXITY_3

/obj/item/food/salad/huoxing_tofu
	name = "\improper Huoxing tofu"
	desc = "An adaptation of mapo tofu made famous in Prospect, the foodie Mecca of Mars. It even kinda looks like Mars, if you really squint."
	icon = 'icons/obj/food/martian.dmi'
	icon_state = "huoxing_tofu"
	food_reagents = list(
		/datum/reagent/consumable/nutriment/protein = 8,
		/datum/reagent/consumable/nutriment/vitamin = 4,
		/datum/reagent/consumable/nutriment = 4,
		/datum/reagent/consumable/capsaicin = 2
	)
	tastes = list("meat" = 1, "chilli heat" = 1, "tofu" = 1)
	foodtypes = MEAT | VEGETABLES
	w_class = WEIGHT_CLASS_SMALL
	crafting_complexity = FOOD_COMPLEXITY_2

/obj/item/food/feizhou_ji
	name = "fēizhōu jī"
	desc = "Considered a Macanese variant on piri-piri, fēizhōu jī, or galinha à africana, or African chicken (if you're feeling like speaking Common), is a popular dish in the TID, and subsequently also on Mars due to its influx of Macanese settlers."
	icon = 'icons/obj/food/martian.dmi'
	icon_state = "feizhou_ji"
	food_reagents = list(
		/datum/reagent/consumable/nutriment = 6,
		/datum/reagent/consumable/nutriment/protein = 8,
		/datum/reagent/consumable/capsaicin = 2,
	)
	tastes = list("chicken" = 1, "chilli heat" = 1, "vinegar" = 1)
	foodtypes = MEAT | VEGETABLES
	w_class = WEIGHT_CLASS_SMALL
	crafting_complexity = FOOD_COMPLEXITY_3


/obj/item/food/salad/galinha_de_cabidela
	name = "galinha de cabidela"
	desc = "Originally a Portuguese dish, cabidela rice is traditionally made with chicken in Portugal, and duck in Macau- ultimately, the chicken version won out on Mars due to European influence."
	icon = 'icons/obj/food/martian.dmi'
	icon_state = "galinha_de_cabidela"
	food_reagents = list(
		/datum/reagent/consumable/nutriment = 6,
		/datum/reagent/consumable/nutriment/protein = 12,
	)
	tastes = list("chicken" = 1, "iron" = 1, "vinegar" = 1, "rice" = 1)
	foodtypes = MEAT | VEGETABLES | GRAIN
	w_class = WEIGHT_CLASS_SMALL
	crafting_complexity = FOOD_COMPLEXITY_3

/obj/item/food/salad/katsu_curry
	name = "katsu curry"
	desc = "Breaded and deep fried meat, topped with curry sauce and served on a bed of rice."
	icon = 'icons/obj/food/martian.dmi'
	icon_state = "katsu_curry"
	food_reagents = list(
		/datum/reagent/consumable/nutriment = 6,
		/datum/reagent/consumable/nutriment/protein = 8,
	)
	tastes = list("curry" = 1, "meat" = 1, "breadcrumbs" = 1, "rice" = 1)
	foodtypes = MEAT | VEGETABLES | GRAIN
	w_class = WEIGHT_CLASS_SMALL
	crafting_complexity = FOOD_COMPLEXITY_3

/obj/item/food/salad/beef_bowl
	name = "beef bowl"
	desc = "A tasty mix of stewed beef and onion, served over rice. Typical toppings include pickled ginger, chilli powder, and fried eggs."
	icon = 'icons/obj/food/martian.dmi'
	icon_state = "beef_bowl"
	food_reagents = list(
		/datum/reagent/consumable/nutriment = 6,
		/datum/reagent/consumable/nutriment/protein = 8,
		/datum/reagent/consumable/nutriment/vitamin = 2,
	)
	tastes = list("beef" = 25, "onion" = 25, "chili heat" = 15, "rice" = 34, "soul" = 1) //I pour my soul into this bowl
	foodtypes = MEAT | VEGETABLES | GRAIN
	w_class = WEIGHT_CLASS_SMALL
	crafting_complexity = FOOD_COMPLEXITY_3

/obj/item/food/salad/salt_chilli_bowl
	name = "salt n' chilli octopus bowl"
	desc = "Inspired by the Japanese donburi tradition, this spicy take on ten-don is a flavour sensation that's swept the Martian nation."
	icon = 'icons/obj/food/martian.dmi'
	icon_state = "salt_chilli_bowl"
	food_reagents = list(
		/datum/reagent/consumable/nutriment = 4,
		/datum/reagent/consumable/nutriment/protein = 6,
		/datum/reagent/consumable/nutriment/vitamin = 6,
		/datum/reagent/consumable/capsaicin = 2,
		/datum/reagent/consumable/salt = 2,
	)
	tastes = list("seafood" = 1, "rice" = 1, "garlic" = 1, "ginger" = 1, "numbing heat" = 1, "salt" = 1)
	foodtypes = SEAFOOD | VEGETABLES | GRAIN
	w_class = WEIGHT_CLASS_SMALL
	crafting_complexity = FOOD_COMPLEXITY_4 //A few Cargo ingredients

/obj/item/food/salad/kansai_bowl
	name = "\improper Kansai bowl"
	desc = "Also known as konohadon, this donburi is typical to the Kansai region, and consists of kamaboko fishcake, egg and onion served over rice."
	icon = 'icons/obj/food/martian.dmi'
	icon_state = "kansai_bowl"
	food_reagents = list(
		/datum/reagent/consumable/nutriment = 8,
		/datum/reagent/consumable/nutriment/protein = 6,
		/datum/reagent/consumable/nutriment/vitamin = 2,
	)
	tastes = list("seafood" = 1, "rice" = 1, "egg" = 1, "onion" = 1)
	foodtypes = SEAFOOD | MEAT | VEGETABLES | GRAIN
	w_class = WEIGHT_CLASS_SMALL
	crafting_complexity = FOOD_COMPLEXITY_3

/obj/item/food/salad/eigamudo_curry //curry is meant to be really spicy or kinda mild, this just stinks!
	name = "\improper Eigamudo curry"
	desc = "An inexplicable curry dish made from a cacophony of ingredients. Presumably tastes good to someone, somewhere- though good luck finding them."
	icon = 'icons/obj/food/martian.dmi'
	icon_state = "eigamudo_curry"
	food_reagents = list(
		/datum/reagent/consumable/nutraslop = 8,
		/datum/reagent/consumable/capsaicin = 2,
		/datum/reagent/toxin/slimejelly = 4,
	)
	tastes = list("grit" = 1, "slime" = 1, "gristle" = 1, "rice" = 1, "Mystery Food X" = 1)
	foodtypes = GROSS | GRAIN | TOXIC
	w_class = WEIGHT_CLASS_SMALL
	crafting_complexity = FOOD_COMPLEXITY_3

// Entrees
/obj/item/food/cilbir
	name = "çilbir"
	desc = "Eggs, served on a savoury yoghurt base with a spicy oil topping. Originally a Turkish dish, it came to Mars with German-Turkish settlers and has become a breakfast mainstay since."
	icon = 'icons/obj/food/martian.dmi'
	icon_state = "cilbir"
	food_reagents = list(
		/datum/reagent/consumable/nutriment/protein = 4,
		/datum/reagent/consumable/nutriment/vitamin = 6,
		/datum/reagent/consumable/nutriment = 4,
		/datum/reagent/consumable/capsaicin = 2,
		/datum/reagent/consumable/garlic = 1,
	)
	tastes = list("yoghurt" = 1, "garlic" = 1, "lemon" = 1, "egg" = 1, "chilli heat" = 1)
	foodtypes = DAIRY | VEGETABLES | MEAT | BREAKFAST
	w_class = WEIGHT_CLASS_SMALL
	crafting_complexity = FOOD_COMPLEXITY_3

/obj/item/food/peking_duck_crepes
	name = "\improper Peking duck crepes a l'orange"
	desc = "This dish takes the best of Beijing's and Paris' cuisines to make a deliciously tangy and savoury meal."
	icon = 'icons/obj/food/martian.dmi'
	icon_state = "peking_duck_crepes"
	food_reagents = list(
		/datum/reagent/consumable/nutriment/protein = 10,
		/datum/reagent/consumable/nutriment = 6,
		/datum/reagent/consumable/nutriment/vitamin = 4,
		/datum/reagent/consumable/orangejuice = 4,
	)
	tastes = list("meat" = 1, "crepes" = 1, "orange" = 1)
	foodtypes = MEAT | DAIRY | VEGETABLES | FRUIT
	w_class = WEIGHT_CLASS_SMALL
	crafting_complexity = FOOD_COMPLEXITY_3

// Desserts
/obj/item/food/cake/spekkoek
	name = "vulgaris spekkoek"
	desc = "Brought to Mars by both Dutch and Indonesian settlers, spekkoek is a common holiday cake on the Red Planet, often being served as part of a traditional rijsttafel. Use of ambrosia vulgaris as a flavouring is one of necessity in deep space, as pandan leaf is rare this far from Earth."
	icon = 'icons/obj/food/martian.dmi'
	icon_state = "spekkoek"
	food_reagents = list(
		/datum/reagent/consumable/nutriment = 30,
		/datum/reagent/consumable/nutriment/vitamin = 15
	)
	tastes = list("winter spices" = 2, "ambrosia vulgaris" = 2, "cake" = 5)
	foodtypes = GRAIN | SUGAR | DAIRY
	crafting_complexity = FOOD_COMPLEXITY_3

/obj/item/food/cake/spekkoek/make_processable()
	AddElement(/datum/element/processable, TOOL_KNIFE, /obj/item/food/cakeslice/spekkoek, 5, 3 SECONDS, table_required = TRUE)

/obj/item/food/cakeslice/spekkoek
	name = "vulgaris spekkoek slice"
	desc = "A slice of vulgaris spekkoek. If you're Martian, this might remind you of home."
	icon = 'icons/obj/food/martian.dmi'
	icon_state = "spekkoek_slice"
	tastes = list("winter spices" = 2, "ambrosia vulgaris" = 2, "cake" = 5)
	foodtypes = GRAIN | SUGAR | DAIRY
	crafting_complexity = FOOD_COMPLEXITY_3

/obj/item/food/salad/pineapple_foster
	name = "pineapple foster"
	desc = "A classic Martian adaptation of another classic dessert, Pineapple Foster is a toasty sweet treat which presents only a mild-to-moderate fire risk."
	icon = 'icons/obj/food/martian.dmi'
	icon_state = "pineapple_foster"
	food_reagents = list(
		/datum/reagent/consumable/nutriment/vitamin = 6,
		/datum/reagent/consumable/nutriment = 2,
		/datum/reagent/consumable/caramel = 4,
		/datum/reagent/consumable/pineapplejuice = 2,
		/datum/reagent/consumable/milk = 4
	)
	tastes = list("pineapple" = 1, "vanilla" = 1, "caramel" = 1, "ice cream" = 1)
	foodtypes = FRUIT | DAIRY | PINEAPPLE
	w_class = WEIGHT_CLASS_SMALL
	crafting_complexity = FOOD_COMPLEXITY_3

/obj/item/food/pastel_de_nata
	name = "pastel de nata"
	desc = "Originally created by Portuguese monks, pastéis de nata went worldwide under the Portuguese colonial empire- including Macau, from which it came to Mars with settlers from the TID of Hong Kong and Macau."
	icon = 'icons/obj/food/martian.dmi'
	icon_state = "pastel_de_nata"
	food_reagents = list(
		/datum/reagent/consumable/nutriment/protein = 4,
		/datum/reagent/consumable/nutriment = 4,
		/datum/reagent/consumable/sugar = 4,
	)
	tastes = list("custard" = 1, "vanilla" = 1, "sweet pastry" = 1)
	foodtypes = DAIRY | GRAIN
	w_class = WEIGHT_CLASS_SMALL
	crafting_complexity = FOOD_COMPLEXITY_3

/obj/item/food/boh_loh_yah
	name = "boh loh yah"
	desc = "Confusingly referred to as a \"pineapple bun\", this Hong Konger treat contains no actual pineapple- instead, it's a sugar-cookie like bun with a butter filling."
	icon = 'icons/obj/food/martian.dmi'
	icon_state = "boh_loh_yah"
	food_reagents = list(
		/datum/reagent/consumable/nutriment = 6,
		/datum/reagent/consumable/sugar = 4,
	)
	tastes = list("cookie" = 1, "butter" = 1)
	foodtypes = DAIRY | GRAIN | PINEAPPLE //it's funny
	w_class = WEIGHT_CLASS_SMALL
	crafting_complexity = FOOD_COMPLEXITY_3

/obj/item/food/banana_fritter
	name = "banana fritter"
	desc = "A ubiquitous sweet snack from much of Maritime South-East Asia, the banana fritter has many names, but all share a similar style- banana, coated in batter, and fried."
	icon = 'icons/obj/food/martian.dmi'
	icon_state = "banana_fritter"
	food_reagents = list(
		/datum/reagent/consumable/nutriment = 3,
		/datum/reagent/consumable/nutriment/vitamin = 1,
		/datum/reagent/consumable/sugar = 1,
	)
	tastes = list("banana" = 1, "batter" = 1)
	foodtypes = GRAIN | FRUIT | FRIED
	w_class = WEIGHT_CLASS_SMALL
	crafting_complexity = FOOD_COMPLEXITY_3 //Fried goodness, oil scawy.

/obj/item/food/pineapple_fritter
	name = "pineapple fritter"
	desc = "Like its cousin, the banana fritter, the pineapple fritter is a popular snack, though somewhat let down by pineapple's infamous \"love it or hate it\" flavour."
	icon = 'icons/obj/food/martian.dmi'
	icon_state = "pineapple_fritter"
	food_reagents = list(
		/datum/reagent/consumable/nutriment = 3,
		/datum/reagent/consumable/nutriment/vitamin = 1,
		/datum/reagent/consumable/sugar = 1,
	)
	tastes = list("pineapple" = 1, "batter" = 1)
	foodtypes = GRAIN | FRUIT | FRIED | PINEAPPLE
	w_class = WEIGHT_CLASS_SMALL
	crafting_complexity = FOOD_COMPLEXITY_3

/obj/item/food/kebab/kasei_dango
	name = "kasei dango"
	desc = "Japanese-style dango balls, flavoured with grenadine and orange, giving a final result that looks like Mars and tastes like dessert, served three to a stick."
	icon = 'icons/obj/food/martian.dmi'
	icon_state = "kasei_dango"
	food_reagents = list(
		/datum/reagent/consumable/sugar = 6,
		/datum/reagent/consumable/nutriment = 2,
		/datum/reagent/consumable/orangejuice = 3,
		/datum/reagent/consumable/grenadine = 3
	)
	tastes = list("pomegranate" = 1, "orange" = 1)
	foodtypes = FRUIT | GRAIN
	w_class = WEIGHT_CLASS_SMALL
	crafting_complexity = FOOD_COMPLEXITY_3

// Frozen
/obj/item/food/pb_ice_cream_mochi
	name = "peanut butter ice cream mochi"
	desc = "A classic dessert at the Arabia Street Night Market in Prospect, peanut butter ice cream mochi is made with a peanut-butter flavoured ice cream as the main filling, and coated in crushed peanuts in the Taiwanese tradition."
	icon = 'icons/obj/food/martian.dmi'
	icon_state = "pb_ice_cream_mochi"
	food_reagents = list(
		/datum/reagent/consumable/nutriment = 4,
		/datum/reagent/consumable/sugar = 6,
		/datum/reagent/consumable/peanut_butter = 4,
		/datum/reagent/consumable/milk = 2,
	)
	tastes = list("peanut butter" = 1, "mochi" = 1)
	foodtypes = NUTS | GRAIN | DAIRY | SUGAR
	w_class = WEIGHT_CLASS_SMALL
	crafting_complexity = FOOD_COMPLEXITY_3

/obj/item/food/popsicle/pineapple_pop
	name = "frozen pineapple pop"
	desc = "Few cultures love pineapple as much as the Martians, and this dessert proves that- frozen pineapple, on a stick, with just a little dunk of dark chocolate."
	overlay_state = "pineapple_pop"
	food_reagents = list(
		/datum/reagent/consumable/pineapplejuice = 4,
		/datum/reagent/consumable/sugar = 4,
		/datum/reagent/consumable/nutriment = 2,
		/datum/reagent/consumable/nutriment/vitamin = 2,
	)
	tastes = list("cold pineapple" = 1, "chocolate" = 1)
	foodtypes = SUGAR | PINEAPPLE
	crafting_complexity = FOOD_COMPLEXITY_3

/obj/item/food/popsicle/sea_salt
	name = "sea salt ice-cream bar"
	desc = "This sky-blue ice-cream bar is flavoured with only the finest imported sea salt. Salty... no, sweet!"
	overlay_state = "sea_salt_pop"
	food_reagents = list(
		/datum/reagent/consumable/salt = 1,
		/datum/reagent/consumable/nutriment = 2,
		/datum/reagent/consumable/cream = 2,
		/datum/reagent/consumable/vanilla = 2,
		/datum/reagent/consumable/sugar = 4,
	)
	tastes = list("salt" = 1, "sweet" = 1)
	foodtypes = SUGAR | DAIRY
	crafting_complexity = FOOD_COMPLEXITY_3

// topsicles, also known as tofu popsicles
/obj/item/food/popsicle/topsicle
	name = "berry topsicle"
	desc = "A frozen treat made from tofu and berry juice blended smooth, then frozen. Supposedly a favourite of bears, but that makes no sense..."
	overlay_state = "topsicle_berry"
	food_reagents = list(
		/datum/reagent/consumable/nutriment/vitamin = 4,
		/datum/reagent/consumable/sugar = 6,
		/datum/reagent/consumable/berryjuice = 4
	)
	tastes = list("berry" = 1, "tofu" = 1)
	foodtypes = FRUIT | VEGETABLES
	crafting_complexity = FOOD_COMPLEXITY_3

/obj/item/food/popsicle/topsicle/banana
	name = "banana topsicle"
	desc = "A frozen treat made from tofu and banana juice blended smooth, then frozen. Popular in rural Japan in the summer."
	overlay_state = "topsicle_banana"
	food_reagents = list(
		/datum/reagent/consumable/nutriment/vitamin = 4,
		/datum/reagent/consumable/sugar = 6,
		/datum/reagent/consumable/banana = 4
	)
	tastes = list("banana" = 1, "tofu" = 1)

/obj/item/food/popsicle/topsicle/pineapple
	name = "pineapple topsicle"
	desc = "A frozen treat made from tofu and pineapple juice blended smooth, then frozen. As seen on TV."
	overlay_state = "topsicle_pineapple"
	food_reagents = list(
		/datum/reagent/consumable/nutriment/vitamin = 4,
		/datum/reagent/consumable/sugar = 6,
		/datum/reagent/consumable/pineapplejuice = 4
	)
	tastes = list("pineapple" = 1, "tofu" = 1)

// Ballpark Food
/obj/item/food/plasma_dog_supreme
	name = "\improper Plasma Dog Supreme"
	desc = "The signature snack of Cybersun Park, home of the New Osaka Woodpeckers: a ballpark hot-dog with sambal, dashi-grilled onions and pineapple-lime salsa. You know, the sort of bold flavours they enjoy on Mars."
	icon = 'icons/obj/food/martian.dmi'
	icon_state = "plasma_dog_supreme"
	food_reagents = list(
		/datum/reagent/consumable/nutriment/vitamin = 8,
		/datum/reagent/consumable/nutriment/protein = 8,
		/datum/reagent/consumable/nutriment = 6
	)
	tastes = list("sausage" = 1, "relish" = 1, "onion" = 1, "fruity salsa" = 1)
	foodtypes = FRUIT | MEAT | PINEAPPLE | VEGETABLES | GRAIN
	w_class = WEIGHT_CLASS_SMALL
	crafting_complexity = FOOD_COMPLEXITY_4 //Uses Sambal
	custom_price = PAYCHECK_CREW * 2

/obj/item/food/frickles
	name = "frickles"
	desc = "Spicy fried pickle spears? Such a bold combination can surely come only from one place- Martian ballparks? Well, not really, but they are a popular snack there."
	icon = 'icons/obj/food/martian.dmi'
	icon_state = "frickles"
	food_reagents = list(
		/datum/reagent/consumable/nutriment = 6,
		/datum/reagent/consumable/nutriment/fat/oil = 2,
		/datum/reagent/consumable/capsaicin = 1,
	)
	tastes = list("frickles" = 1)
	foodtypes = VEGETABLES | GRAIN
	w_class = WEIGHT_CLASS_SMALL
	crafting_complexity = FOOD_COMPLEXITY_3 //batter and cargo stuff.

/obj/item/food/raw_ballpark_pretzel
	name = "raw pretzel"
	desc = "A twisted knot of dough, ready to be baked, or possibly griddled?"
	icon = 'icons/obj/food/martian.dmi'
	icon_state = "raw_ballpark_pretzel"
	food_reagents = list(
		/datum/reagent/consumable/nutriment = 3,
		/datum/reagent/consumable/salt = 1,
	)
	tastes = list("bread" = 1, "salt" = 1)
	foodtypes = GRAIN | RAW
	w_class = WEIGHT_CLASS_SMALL
	crafting_complexity = FOOD_COMPLEXITY_2

/obj/item/food/raw_ballpark_pretzel/make_bakeable()
	AddComponent(/datum/component/bakeable, /obj/item/food/ballpark_pretzel, rand(15 SECONDS, 25 SECONDS), TRUE, TRUE)

/obj/item/food/raw_ballpark_pretzel/make_grillable()
	AddComponent(/datum/component/grillable, /obj/item/food/ballpark_pretzel, rand(15 SECONDS, 25 SECONDS), TRUE, TRUE)

/obj/item/food/ballpark_pretzel
	name = "ballpark pretzel"
	desc = "A classic German bread, transformed by the hand of American imperialism into a game-day snack, and then carried to the Red Planet on the backs of Japanese settlers. How multicultural."
	icon = 'icons/obj/food/martian.dmi'
	icon_state = "ballpark_pretzel"
	food_reagents = list(
		/datum/reagent/consumable/nutriment = 6,
		/datum/reagent/consumable/salt = 1,
	)
	tastes = list("bread" = 1, "salt" = 1)
	foodtypes = GRAIN
	w_class = WEIGHT_CLASS_SMALL
	crafting_complexity = FOOD_COMPLEXITY_3

/obj/item/food/kebab/raw_ballpark_tsukune
	name = "raw tsukune"
	desc = "Raw chicken meatballs on a skewer, ready to be griddled into something delicious."
	icon = 'icons/obj/food/martian.dmi'
	icon_state = "raw_ballpark_tsukune"
	food_reagents = list(
		/datum/reagent/consumable/nutriment/protein = 3,
		/datum/reagent/consumable/nutriment = 2,
	)
	tastes = list("raw chicken" = 7, "salmonella" = 1)
	foodtypes = MEAT | RAW
	w_class = WEIGHT_CLASS_SMALL
	crafting_complexity = FOOD_COMPLEXITY_2

/obj/item/food/kebab/raw_ballpark_tsukune/make_grillable()
	AddComponent(/datum/component/grillable, /obj/item/food/kebab/ballpark_tsukune, rand(15 SECONDS, 25 SECONDS), TRUE, TRUE)

/obj/item/food/kebab/ballpark_tsukune
	name = "ballpark tsukune"
	desc = "Skewered chicken meatballs in a sweet-and-savoury yakitori sauce. A common sight at Martian ballparks."
	icon = 'icons/obj/food/martian.dmi'
	icon_state = "ballpark_tsukune"
	food_reagents = list(
		/datum/reagent/consumable/nutriment/protein = 6,
		/datum/reagent/consumable/nutriment = 4,
	)
	tastes = list("chicken" = 1, "umami sauce" = 1)
	foodtypes = MEAT
	w_class = WEIGHT_CLASS_SMALL
	crafting_complexity = FOOD_COMPLEXITY_3

// Ethereal-suitable cross-culture food
/*	Ethereals are, as part of the uplifting process, considered as citizens of the Terran Federation.
	For this reason, a lot of ethereals have chosen to move throughout human space, settling on various planets to a mixed reception.
	Mars is no exception to this rule, where the ethereal population has been more welcomed than most, due to Mars' more cosmopolitan past.
	Here, the ethereals have developed a distinct culture, neither that of their homeland nor that of Mars, and with that a distinct cuisine.
*/

// Pickled Voltvine
/obj/item/food/pickled_voltvine
	name = "pickled voltvine"
	desc = "A traditional dish from Sprout (where it is known as hinu'sashuruhk), pickled voltvine has taken on a new identity amongst the pickle masters of Mars, earning a seat at the holy pickle pantheon alongside pickled ginger and kimchi (once appropriately discharged, at least)."
	icon = 'icons/obj/food/martian.dmi'
	icon_state = "pickled_voltvine"
	food_reagents = list(
		/datum/reagent/consumable/liquidelectricity/enriched = 4,
		/datum/reagent/consumable/nutriment/vitamin = 2,
	)
	tastes = list("sour radish" = 1)
	foodtypes = VEGETABLES
	w_class = WEIGHT_CLASS_SMALL
	crafting_complexity = FOOD_COMPLEXITY_2 //If it comes straight from cargo, should be worth paying for.

// 24-Volt Energy
/obj/item/food/volt_fish
	name = "24-volt fish"
	desc = "Some may question the 24-volt fish. After all, fish poached in electric-blue super-sour energy drink looks awful. And, indeed, tastes awful. So why do the Martian ethereals like it, then?" //beats the hell out of me
	icon = 'icons/obj/food/martian.dmi'
	icon_state = "volt_fish"
	food_reagents = list(
		/datum/reagent/consumable/liquidelectricity/enriched = 6,
		/datum/reagent/consumable/nutriment/protein = 4,
	)
	tastes = list("fish" = 1, "sour pear" = 1)
	foodtypes = SEAFOOD
	w_class = WEIGHT_CLASS_SMALL
	crafting_complexity = FOOD_COMPLEXITY_3

// Sprout Bowl
/obj/item/food/salad/sprout_bowl
	name = "\improper Sprout bowl"
	desc = "Named for the Ethereal homeworld, this rice-based bowl draws on the donburi tradition, but rejects typical donburi toppings, instead using sashimi grade fish and pickled voltvine."
	icon = 'icons/obj/food/martian.dmi'
	icon_state = "sprout_bowl"
	food_reagents = list(
		/datum/reagent/consumable/liquidelectricity/enriched = 8,
		/datum/reagent/consumable/nutriment/protein = 4,
		/datum/reagent/consumable/nutriment/vitamin = 2,
	)
	tastes = list("fish" = 1, "sour radish" = 1, "rice" = 1)
	foodtypes = SEAFOOD | VEGETABLES | GRAIN
	w_class = WEIGHT_CLASS_SMALL
	crafting_complexity = FOOD_COMPLEXITY_3
