
// see code/module/crafting/table.dm

////////////////////////////////////////////////BREAD////////////////////////////////////////////////

/datum/crafting_recipe/food/meatbread
	name = "Meat bread"
	reqs = list(
		/obj/item/food/bread/plain = 1,
		/obj/item/food/meat/cutlet/plain = 3,
		/obj/item/food/cheese/wedge = 3
	)
	result = /obj/item/food/bread/meat
	category = CAT_BREAD

/datum/crafting_recipe/food/xenomeatbread
	name = "Xenomeat bread"
	reqs = list(
		/obj/item/food/bread/plain = 1,
		/obj/item/food/meat/cutlet/xeno = 3,
		/obj/item/food/cheese/wedge = 3
	)
	result = /obj/item/food/bread/xenomeat
	category = CAT_BREAD

/datum/crafting_recipe/food/spidermeatbread
	name = "Spidermeat bread"
	reqs = list(
		/obj/item/food/bread/plain = 1,
		/obj/item/food/meat/cutlet/spider = 3,
		/obj/item/food/cheese/wedge = 3
	)
	result = /obj/item/food/bread/spidermeat
	category = CAT_BREAD

/datum/crafting_recipe/food/sausagebread
	name = "Sausage bread"
	reqs = list(
		/obj/item/food/bread/plain = 1,
		/obj/item/food/sausage = 2,
	)
	result = /obj/item/food/bread/sausage
	category = CAT_BREAD

/datum/crafting_recipe/food/banananutbread
	name = "Banana nut bread"
	reqs = list(
		/datum/reagent/consumable/milk = 5,
		/obj/item/food/bread/plain = 1,
		/obj/item/food/boiledegg = 3,
		/obj/item/food/grown/banana = 1
	)
	result = /obj/item/food/bread/banana
	category = CAT_BREAD

/datum/crafting_recipe/food/tofubread
	name = "Tofu bread"
	reqs = list(
		/obj/item/food/bread/plain = 1,
		/obj/item/food/tofu = 3,
		/obj/item/food/cheese/wedge = 3
	)
	result = /obj/item/food/bread/tofu
	category = CAT_BREAD

/datum/crafting_recipe/food/creamcheesebread
	name = "Cream cheese bread"
	reqs = list(
		/datum/reagent/consumable/milk = 5,
		/obj/item/food/bread/plain = 1,
		/obj/item/food/cheese/wedge = 2
	)
	result = /obj/item/food/bread/creamcheese
	category = CAT_BREAD

/datum/crafting_recipe/food/mimanabread
	name = "Mimana bread"
	reqs = list(
		/datum/reagent/consumable/soymilk = 5,
		/obj/item/food/bread/plain = 1,
		/obj/item/food/tofu = 3,
		/obj/item/food/grown/banana/mime = 1
	)
	result = /obj/item/food/bread/mimana
	category = CAT_BREAD

/datum/crafting_recipe/food/garlicbread
	name = "Garlic Bread"
	time = 40
	reqs = list(/obj/item/food/grown/garlic = 1,
				/obj/item/food/breadslice/plain = 1,
				/obj/item/food/butterslice = 1
	)
	result = /obj/item/food/garlicbread
	category = CAT_BREAD

/datum/crafting_recipe/food/butterbiscuit
	name = "Butter Biscuit"
	reqs = list(
		/obj/item/food/bun = 1,
		/obj/item/food/butterslice = 1
	)
	result = /obj/item/food/butterbiscuit
	category = CAT_BREAD

/datum/crafting_recipe/food/butterdog
	name = "Butterdog"
	reqs = list(
		/obj/item/food/bun = 1,
		/obj/item/food/butter = 1,
		)
	result = /obj/item/food/butterdog
	category = CAT_BREAD

/datum/crafting_recipe/food/baguette
	name = "Baguette"
	time = 40
	reqs = list(/datum/reagent/consumable/salt = 1,
		/datum/reagent/consumable/blackpepper = 1,
		/obj/item/food/pastrybase = 2
	)
	result = /obj/item/food/baguette
	category = CAT_BREAD

/datum/crafting_recipe/food/raw_breadstick
	name = "Raw breadstick"
	reqs = list(
		/obj/item/food/doughslice = 1,
		/datum/reagent/consumable/salt = 1,
		/obj/item/food/butterslice = 1
	)
	result = /obj/item/food/raw_breadstick
	category = CAT_BREAD

/datum/crafting_recipe/food/raw_croissant
	name = "Raw croissant"
	reqs = list(
		/obj/item/food/doughslice = 1,
		/datum/reagent/consumable/sugar = 1,
		/obj/item/food/butterslice = 1
	)
	result = /obj/item/food/raw_croissant
	category = CAT_BREAD

/datum/crafting_recipe/food/throwing_croissant
	name = "Throwing croissant"
	reqs = list(
		/obj/item/food/croissant = 1,
		/obj/item/stack/rods = 1,
	)
	requirements_mats_blacklist = list(/obj/item/stack/rods)
	result = /obj/item/food/croissant/throwing
	category = CAT_BREAD
	crafting_flags = CRAFT_CHECK_DENSITY | CRAFT_MUST_BE_LEARNED

/datum/crafting_recipe/food/breaddog
	name = "Living dog/bread hybrid"
	reqs = list(
		/obj/item/organ/brain = 1,
		/obj/item/organ/heart = 1,
		/obj/item/food/bread/plain = 2,
		/obj/item/food/meat/slab = 3,
		/datum/reagent/blood = 30,
		/datum/reagent/teslium = 1 //To shock the whole thing into life
	)
	result = /mob/living/basic/pet/dog/breaddog
	category = CAT_BREAD

////////////////////////////////////////////////TOAST////////////////////////////////////////////////

/datum/crafting_recipe/food/slimetoast
	name = "Slime toast"
	reqs = list(
		/datum/reagent/toxin/slimejelly = 5,
		/obj/item/food/breadslice/plain = 1
	)
	result = /obj/item/food/jelliedtoast/slime
	category = CAT_BREAD

/datum/crafting_recipe/food/jelliedyoast
	name = "Jellied toast"
	reqs = list(
		/datum/reagent/consumable/cherryjelly = 5,
		/obj/item/food/breadslice/plain = 1
	)
	result = /obj/item/food/jelliedtoast/cherry
	category = CAT_BREAD

/datum/crafting_recipe/food/butteredtoast
	name = "Buttered Toast"
	reqs = list(
		/obj/item/food/breadslice/plain = 1,
		/obj/item/food/butterslice = 1
	)
	result = /obj/item/food/butteredtoast
	category = CAT_BREAD

/datum/crafting_recipe/food/twobread
	name = "Two bread"
	reqs = list(
		/datum/reagent/consumable/ethanol/wine = 5,
		/obj/item/food/breadslice/plain = 2
	)
	result = /obj/item/food/twobread
	category = CAT_BREAD

/datum/crafting_recipe/food/moldybread // why would you make this?
	name = "Moldy Bread"
	reqs = list(
		/obj/item/food/breadslice/plain = 1,
		/obj/item/food/grown/mushroom/amanita = 1
		)
	result = /obj/item/food/breadslice/moldy
	category = CAT_BREAD

/datum/crafting_recipe/food/breadcat
	name = "Bread cat/bread hybrid"
	reqs = list(
		/obj/item/food/bread/plain = 1,
		/obj/item/organ/ears/cat = 1,
		/obj/item/organ/tail/cat = 1,
		/obj/item/food/meat/slab = 3,
		/datum/reagent/blood = 50,
		/datum/reagent/medicine/strange_reagent = 5
	)
	result = /mob/living/basic/pet/cat/breadcat
	category = CAT_BREAD

/datum/crafting_recipe/food/frenchtoast
	name = "Raw french toast"
	reqs = list(
		/obj/item/food/breadslice/plain = 1,
		/obj/item/food/egg = 2,
		/datum/reagent/consumable/milk = 5
	)
	result = /obj/item/food/raw_frenchtoast
	category = CAT_BREAD
