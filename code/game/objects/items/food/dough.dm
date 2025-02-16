//Note for this file: All the raw pastries should not have microwave results, use baking instead. All cooked products can use baking, but should also support a microwave.

/obj/item/food/dough
	name = "dough"
	desc = "A piece of dough."
	icon = 'icons/obj/food/food_ingredients.dmi'
	icon_state = "dough"
	food_reagents = list(/datum/reagent/consumable/nutriment = 6)
	tastes = list("dough" = 1)
	foodtypes = GRAIN
	crafting_complexity = FOOD_COMPLEXITY_0

/obj/item/food/dough/make_bakeable()
	AddComponent(/datum/component/bakeable, /obj/item/food/bread/plain, rand(30 SECONDS, 45 SECONDS), TRUE, TRUE)

// Dough + rolling pin = flat dough
/obj/item/food/dough/make_processable()
	AddElement(/datum/element/processable, TOOL_ROLLINGPIN, /obj/item/food/flatdough, 1, 3 SECONDS, table_required = TRUE, screentip_verb = "Flatten")

/obj/item/food/flatdough
	name = "flat dough"
	desc = "A flattened dough."
	icon = 'icons/obj/food/food_ingredients.dmi'
	icon_state = "flat dough"
	food_reagents = list(/datum/reagent/consumable/nutriment = 6)
	tastes = list("dough" = 1)
	foodtypes = GRAIN
	crafting_complexity = FOOD_COMPLEXITY_0

/obj/item/food/flatdough/make_bakeable()
	AddComponent(/datum/component/bakeable, /obj/item/food/pizzabread, rand(30 SECONDS, 45 SECONDS), TRUE, TRUE)

// sliceable into 3xdoughslices
/obj/item/food/flatdough/make_processable()
	AddElement(/datum/element/processable, TOOL_KNIFE, /obj/item/food/doughslice, 3, 3 SECONDS, table_required = TRUE, screentip_verb = "Slice")

/obj/item/food/pizzabread
	name = "pizza bread"
	desc = "Add ingredients to make a pizza."
	icon = 'icons/obj/food/food_ingredients.dmi'
	icon_state = "pizzabread"
	food_reagents = list(/datum/reagent/consumable/nutriment = 7)
	tastes = list("bread" = 1)
	foodtypes = GRAIN
	crafting_complexity = FOOD_COMPLEXITY_1

/obj/item/food/pizzabread/Initialize(mapload)
	. = ..()
	AddComponent(/datum/component/ingredients_holder, /obj/item/food/pizza, CUSTOM_INGREDIENT_ICON_SCATTER, max_ingredients = 12)

/obj/item/food/doughslice
	name = "dough slice"
	desc = "A slice of dough. Can be cooked into a bun."
	icon = 'icons/obj/food/food_ingredients.dmi'
	icon_state = "doughslice"
	food_reagents = list(/datum/reagent/consumable/nutriment = 2)
	w_class = WEIGHT_CLASS_SMALL
	tastes = list("dough" = 1)
	foodtypes = GRAIN
	crafting_complexity = FOOD_COMPLEXITY_0

/obj/item/food/doughslice/make_bakeable()
	AddComponent(/datum/component/bakeable, /obj/item/food/bun, rand(20 SECONDS, 25 SECONDS), TRUE, TRUE)

/obj/item/food/doughslice/make_processable()
	AddElement(/datum/element/processable, TOOL_KNIFE, /obj/item/food/bait/doughball, 5, 3 SECONDS, screentip_verb = "Slice")

/obj/item/food/bun
	name = "bun"
	desc = "A base for any self-respecting burger."
	icon = 'icons/obj/food/burgerbread.dmi'
	icon_state = "bun"
	food_reagents = list(/datum/reagent/consumable/nutriment = 3)
	w_class = WEIGHT_CLASS_SMALL
	tastes = list("bun" = 1) // the bun tastes of bun.
	foodtypes = GRAIN
	crafting_complexity = FOOD_COMPLEXITY_1

/obj/item/food/bun/Initialize(mapload)
	. = ..()
	AddComponent(/datum/component/ingredients_holder, /obj/item/food/burger/empty, CUSTOM_INGREDIENT_ICON_STACKPLUSTOP)

/obj/item/food/cakebatter
	name = "cake batter"
	desc = "Bake it to get a cake."
	icon = 'icons/obj/food/food_ingredients.dmi'
	icon_state = "cakebatter"
	food_reagents = list(/datum/reagent/consumable/nutriment = 9)
	tastes = list("batter" = 1)
	foodtypes = GRAIN | DAIRY
	crafting_complexity = FOOD_COMPLEXITY_1

/obj/item/food/cakebatter/make_bakeable()
	AddComponent(/datum/component/bakeable, /obj/item/food/cake/plain, rand(70 SECONDS, 90 SECONDS), TRUE, TRUE)

/obj/item/food/cakebatter/make_processable()
	AddElement(/datum/element/processable, TOOL_ROLLINGPIN, /obj/item/food/piedough, 1, 3 SECONDS, table_required = TRUE, screentip_verb = "Flatten")

/obj/item/food/piedough
	name = "pie dough"
	desc = "Cook it to get a pie."
	icon = 'icons/obj/food/food_ingredients.dmi'
	icon_state = "piedough"
	food_reagents = list(/datum/reagent/consumable/nutriment = 9)
	tastes = list("dough" = 1)
	foodtypes = GRAIN | DAIRY
	crafting_complexity = FOOD_COMPLEXITY_1

/obj/item/food/piedough/make_bakeable()
	AddComponent(/datum/component/bakeable, /obj/item/food/pie/plain, rand(30 SECONDS, 45 SECONDS), TRUE, TRUE)

/obj/item/food/piedough/make_processable()
	AddElement(/datum/element/processable, TOOL_KNIFE, /obj/item/food/rawpastrybase, 6, 3 SECONDS, table_required = TRUE, screentip_verb = "Slice")

/obj/item/food/rawpastrybase
	name = "raw pastry base"
	desc = "Must be cooked before use."
	icon = 'icons/obj/food/food_ingredients.dmi'
	icon_state = "rawpastrybase"
	food_reagents = list(/datum/reagent/consumable/nutriment = 2)
	w_class = WEIGHT_CLASS_SMALL
	tastes = list("raw pastry" = 1)
	foodtypes = GRAIN | DAIRY
	crafting_complexity = FOOD_COMPLEXITY_1

/obj/item/food/rawpastrybase/make_bakeable()
	AddComponent(/datum/component/bakeable, /obj/item/food/pastrybase, rand(20 SECONDS, 25 SECONDS), TRUE, TRUE)

/obj/item/food/pastrybase
	name = "pastry base"
	desc = "A base for any self-respecting pastry."
	icon = 'icons/obj/food/food_ingredients.dmi'
	icon_state = "pastrybase"
	food_reagents = list(/datum/reagent/consumable/nutriment = 3)
	w_class = WEIGHT_CLASS_SMALL
	tastes = list("pastry" = 1)
	foodtypes = GRAIN | DAIRY
	crafting_complexity = FOOD_COMPLEXITY_2
