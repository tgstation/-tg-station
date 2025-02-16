/datum/crafting_recipe/food/tiziran_sausage
	name = "Raw Tiziran blood sausage"
	reqs = list(
		/obj/item/food/meat/rawcutlet = 1,
		/obj/item/food/meat/rawbacon = 1,
		/datum/reagent/blood = 5,
		/datum/reagent/consumable/salt = 2
	)
	result = /obj/item/food/raw_tiziran_sausage
	category = CAT_LIZARD

/datum/crafting_recipe/food/headcheese
	name = "Raw headcheese"
	reqs = list(
		/obj/item/food/meat/slab = 1,
		/datum/reagent/consumable/salt = 10,
		/datum/reagent/consumable/blackpepper = 5
	)
	result = /obj/item/food/raw_headcheese
	category = CAT_LIZARD

/datum/crafting_recipe/food/shredded_lungs
	name = "Crispy shredded lung stirfry"
	reqs = list(
		/obj/item/food/grown/carrot = 1,
		/obj/item/food/grown/chili = 1,
		/obj/item/food/grown/onion = 1,
		/obj/item/organ/lungs = 1,
		/obj/item/reagent_containers/cup/bowl = 1,
	)
	blacklist = list(
		/obj/item/organ/lungs/cybernetic,
	)

	result = /obj/item/food/shredded_lungs
	category = CAT_LIZARD

/datum/crafting_recipe/food/tsatsikh
	name = "Tsatsikh"
	reqs = list(
		/obj/item/organ/heart = 1,
		/obj/item/organ/liver = 1,
		/obj/item/organ/lungs = 1,
		/obj/item/organ/stomach = 1,
		/datum/reagent/consumable/salt = 2,
		/datum/reagent/consumable/blackpepper = 2
	)
	result = /obj/item/food/tsatsikh
	category = CAT_LIZARD

/datum/crafting_recipe/food/liver_pate
	name = "Liver pate"
	reqs = list(
		/obj/item/organ/liver = 1,
		/obj/item/food/meat/rawcutlet = 1,
		/obj/item/food/grown/onion = 1
	)
	result = /obj/item/food/liver_pate
	category = CAT_LIZARD

/datum/crafting_recipe/food/moonfish_caviar
	name = "Moonfish caviar paste"
	reqs = list(
		/obj/item/food/moonfish_eggs = 1,
		/datum/reagent/consumable/salt = 2
	)
	result = /obj/item/food/moonfish_caviar
	category = CAT_LIZARD

/datum/crafting_recipe/food/lizard_escargot
	name = "Desert snail cocleas"
	reqs = list(
		/obj/item/food/canned/desert_snails = 1,
		/obj/item/food/grown/garlic = 1,
		/datum/reagent/consumable/lemonjuice = 3,
		/datum/reagent/consumable/blackpepper = 2,
		/datum/reagent/consumable/nutriment/fat/oil/olive = 3,
		/obj/item/reagent_containers/cup/bowl = 1,
	)
	result = /obj/item/food/lizard_escargot
	category = CAT_LIZARD

/datum/crafting_recipe/food/fried_blood_sausage
	name = "Fried blood sausage"
	reqs = list(
		/obj/item/food/raw_tiziran_sausage = 1,
		/datum/reagent/consumable/korta_flour = 5,
		/datum/reagent/water = 5
	)
	result = /obj/item/food/fried_blood_sausage
	category = CAT_LIZARD

/datum/crafting_recipe/food/lizard_fries
	name = "Loaded poms-franzisks"
	reqs = list(
		/obj/item/food/fries = 1,
		/obj/item/food/meat/cutlet = 2,
		/datum/reagent/consumable/bbqsauce = 5,
		/obj/item/plate = 1,
	)
	result = /obj/item/food/lizard_fries
	category = CAT_LIZARD

/datum/crafting_recipe/food/brain_pate
	name = "Eyeball-and-brain pate"
	reqs = list(
		/obj/item/organ/brain = 1,
		/obj/item/organ/eyes = 1,
		/obj/item/food/grown/onion = 1,
		/datum/reagent/consumable/salt = 3
	)
	result = /obj/item/food/brain_pate
	category = CAT_LIZARD

/datum/crafting_recipe/food/crispy_headcheese
	name = "Crispy breaded headcheese"
	reqs = list(
		/obj/item/food/headcheese_slice = 1,
		/obj/item/food/breadslice/root = 1
	)
	result = /obj/item/food/crispy_headcheese
	category = CAT_LIZARD

/datum/crafting_recipe/food/picoss_skewers
	name = "Picoss skewers"
	reqs = list(
		/obj/item/food/fishmeat/armorfish = 2,
		/obj/item/food/grown/onion = 1,
		/obj/item/food/grown/chili = 1,
		/obj/item/stack/rods = 1,
		/datum/reagent/consumable/vinegar = 5
	)
	requirements_mats_blacklist = list(/obj/item/stack/rods)
	result = /obj/item/food/kebab/picoss_skewers
	category = CAT_LIZARD

/datum/crafting_recipe/food/nectar_larvae
	name = "Nectar larvae"
	reqs = list(
		/obj/item/food/canned/larvae = 1,
		/obj/item/food/grown/tomato = 1,
		/obj/item/food/grown/chili = 1,
		/datum/reagent/consumable/korta_nectar = 5
	)
	result = /obj/item/food/nectar_larvae
	category = CAT_LIZARD

/datum/crafting_recipe/food/mushroomy_stirfry
	name = "Mushroomy Stirfry"
	reqs = list(
		/obj/item/food/steeped_mushrooms = 1,
		/obj/item/food/grown/mushroom/plumphelmet = 1,
		/obj/item/food/grown/mushroom/chanterelle = 1,
		/datum/reagent/consumable/nutriment/fat/oil/olive = 5
	)
	result = /obj/item/food/mushroomy_stirfry
	category = CAT_LIZARD

/datum/crafting_recipe/food/moonfish_demiglace
	name = "Moonfish demiglace"
	reqs = list(
		/obj/item/food/grilled_moonfish = 1,
		/obj/item/food/grown/potato = 1,
		/obj/item/food/grown/carrot = 1,
		/datum/reagent/consumable/korta_milk = 5,
		/datum/reagent/consumable/ethanol/wine = 5
	)
	result = /obj/item/food/moonfish_demiglace
	category = CAT_LIZARD

/datum/crafting_recipe/food/lizard_surf_n_turf
	name = "Zagosk surf n turf smorgasbord"
	reqs = list(
		/obj/item/food/grilled_moonfish = 1,
		/obj/item/food/kebab/picoss_skewers = 2,
		/obj/item/food/meat/steak = 1,
		/obj/item/food/bbqribs = 1
	)
	result = /obj/item/food/lizard_surf_n_turf
	category = CAT_LIZARD

/datum/crafting_recipe/food/rootdough
	name = "Rootdough"
	reqs = list(
		/obj/item/food/grown/potato = 2,
		/obj/item/food/egg = 1,
		/datum/reagent/consumable/korta_flour = 5,
		/datum/reagent/water = 10
	)
	result = /obj/item/food/rootdough
	category = CAT_LIZARD

/datum/crafting_recipe/food/rootdough2
	name = "Rootdough"
	reqs = list(
		/obj/item/food/grown/potato = 2,
		/datum/reagent/consumable/soymilk = 15,
		/datum/reagent/consumable/korta_flour = 5,
		/datum/reagent/water = 10
	)
	result = /obj/item/food/rootdough
	category = CAT_LIZARD

/datum/crafting_recipe/food/snail_nizaya
	name = "Desert snail nizaya"
	reqs = list(
		/obj/item/food/canned/desert_snails = 1,
		/obj/item/food/spaghetti/nizaya = 1,
		/obj/item/food/grown/garlic = 1,
		/datum/reagent/consumable/ethanol/wine = 5
	)
	result = /obj/item/food/spaghetti/snail_nizaya
	category = CAT_LIZARD

/datum/crafting_recipe/food/garlic_nizaya
	name = "Garlic nizaya"
	reqs = list(
		/obj/item/food/spaghetti/nizaya = 1,
		/obj/item/food/grown/garlic = 1,
		/obj/item/food/grown/chili = 1,
		/datum/reagent/consumable/nutriment/fat/oil/olive = 5
	)
	result = /obj/item/food/spaghetti/garlic_nizaya
	category = CAT_LIZARD

/datum/crafting_recipe/food/demit_nizaya
	name = "Demit nizaya"
	reqs = list(
		/obj/item/food/spaghetti/nizaya = 1,
		/obj/item/food/grown/carrot = 1,
		/obj/item/food/grown/onion = 1,
		/obj/item/food/grown/eggplant = 1,
		/datum/reagent/consumable/korta_milk = 5,
		/datum/reagent/consumable/korta_nectar = 5
	)
	result = /obj/item/food/spaghetti/demit_nizaya
	category = CAT_LIZARD

/datum/crafting_recipe/food/mushroom_nizaya
	name = "Mushroom nizaya"
	reqs = list(
		/obj/item/food/spaghetti/nizaya = 1,
		/obj/item/food/steeped_mushrooms = 1,
		/obj/item/food/grown/garlic = 1,
		/datum/reagent/consumable/nutriment/fat/oil/olive = 5
	)
	result = /obj/item/food/spaghetti/mushroom_nizaya
	category = CAT_LIZARD

/datum/crafting_recipe/food/rustic_flatbread
	name = "Rustic flatbread"
	reqs = list(
		/obj/item/food/root_flatbread = 1,
		/obj/item/food/grown/garlic = 1,
		/datum/reagent/consumable/lemonjuice = 2,
		/datum/reagent/consumable/nutriment/fat/oil/olive = 3
	)
	result = /obj/item/food/pizza/flatbread/rustic
	category = CAT_LIZARD

/datum/crafting_recipe/food/italic_flatbread
	name = "Italic flatbread"
	reqs = list(
		/obj/item/food/root_flatbread = 1,
		/obj/item/food/grown/garlic = 1,
		/obj/item/food/grown/tomato = 1,
		/obj/item/food/meatball = 2,
		/datum/reagent/consumable/nutriment/fat/oil/olive = 3
	)
	result = /obj/item/food/pizza/flatbread/italic
	category = CAT_LIZARD

/datum/crafting_recipe/food/imperial_flatbread
	name = "Imperial flatbread"
	reqs = list(
		/obj/item/food/root_flatbread = 1,
		/obj/item/food/liver_pate = 1,
		/obj/item/food/sauerkraut = 1,
		/obj/item/food/headcheese = 1
	)
	result = /obj/item/food/pizza/flatbread/imperial
	category = CAT_LIZARD

/datum/crafting_recipe/food/rawmeat_flatbread
	name = "Meatlovers flatbread"
	reqs = list(
		/obj/item/food/root_flatbread = 1,
		/obj/item/food/meat/slab = 1
	)
	result = /obj/item/food/pizza/flatbread/rawmeat
	category = CAT_LIZARD

/datum/crafting_recipe/food/stinging_flatbread
	name = "Stinging flatbread"
	reqs = list(
		/obj/item/food/root_flatbread = 1,
		/obj/item/food/canned/larvae = 1,
		/obj/item/food/canned/jellyfish = 1
	)
	result = /obj/item/food/pizza/flatbread/stinging
	category = CAT_LIZARD

/datum/crafting_recipe/food/zmorgast_flatbread
	name = "Zmorgast flatbread"
	reqs = list(
		/obj/item/food/root_flatbread = 1,
		/obj/item/food/grown/cucumber = 2,
		/obj/item/food/egg = 1,
		/obj/item/organ/liver = 1
	)
	result = /obj/item/food/pizza/flatbread/zmorgast
	category = CAT_LIZARD

/datum/crafting_recipe/food/fish_flatbread
	name = "BBQ fish flatbread"
	reqs = list(
		/obj/item/food/root_flatbread = 1,
		/obj/item/food/fishmeat = 2,
		/datum/reagent/consumable/bbqsauce = 5
	)
	result = /obj/item/food/pizza/flatbread/fish
	category = CAT_LIZARD

/datum/crafting_recipe/food/mushroom_flatbread
	name = "Mushroom and tomato flatbread"
	reqs = list(
		/obj/item/food/root_flatbread = 1,
		/obj/item/food/grown/tomato = 1,
		/obj/item/food/grown/mushroom = 3,
		/datum/reagent/consumable/nutriment/fat/oil/olive = 3
	)
	result = /obj/item/food/pizza/flatbread/mushroom
	category = CAT_LIZARD

/datum/crafting_recipe/food/nutty_flatbread
	name = "Nut paste flatbread"
	reqs = list(
		/obj/item/food/root_flatbread = 1,
		/datum/reagent/consumable/korta_flour = 5,
		/datum/reagent/consumable/korta_milk = 5
	)
	result = /obj/item/food/pizza/flatbread/nutty
	category = CAT_LIZARD

/datum/crafting_recipe/food/emperor_roll
	name = "Emperor roll"
	reqs = list(
		/obj/item/food/rootroll = 1,
		/obj/item/food/liver_pate = 1,
		/obj/item/food/headcheese_slice = 2,
		/obj/item/food/moonfish_caviar = 1
	)
	result = /obj/item/food/emperor_roll
	category = CAT_LIZARD

/datum/crafting_recipe/food/honey_sweetroll
	name = "Honey sweetroll"
	reqs = list(
		/obj/item/food/rootroll = 1,
		/obj/item/food/grown/berries = 1,
		/obj/item/food/grown/banana = 1,
		/datum/reagent/consumable/honey = 5
	)
	result = /obj/item/food/honey_roll
	category = CAT_LIZARD

/datum/crafting_recipe/food/black_eggs
	name = "Black scrambled eggs"
	reqs = list(
		/obj/item/food/egg = 2,
		/datum/reagent/blood = 5,
		/datum/reagent/consumable/vinegar = 2
	)
	result = /obj/item/food/black_eggs
	category = CAT_LIZARD

/datum/crafting_recipe/food/patzikula
	name = "Patzikula"
	reqs = list(
		/obj/item/food/grown/tomato = 2,
		/obj/item/food/grown/onion = 1,
		/obj/item/food/grown/chili = 1,
		/obj/item/food/egg = 2
	)
	result = /obj/item/food/patzikula
	category = CAT_LIZARD

/datum/crafting_recipe/food/korta_brittle
	name = "Korta brittle slab"
	reqs = list(
		/obj/item/food/grown/korta_nut = 2,
		/obj/item/food/butterslice = 1,
		/datum/reagent/consumable/korta_nectar = 5,
		/datum/reagent/consumable/sugar = 5,
		/datum/reagent/consumable/salt = 2
	)
	result = /obj/item/food/cake/korta_brittle
	category = CAT_LIZARD

/datum/crafting_recipe/food/korta_ice
	name = "Korta ice"
	reqs = list(
		/obj/item/reagent_containers/cup/glass/sillycup = 1,
		/datum/reagent/consumable/ice = 15,
		/datum/reagent/consumable/korta_nectar = 5,
		/obj/item/food/grown/berries = 1
	)
	result = /obj/item/food/snowcones/korta_ice
	category = CAT_LIZARD

/datum/crafting_recipe/food/candied_mushrooms
	name = "Candied mushrooms"
	reqs = list(
		/obj/item/stack/rods = 1,
		/obj/item/food/steeped_mushrooms = 1,
		/datum/reagent/consumable/caramel = 5,
		/datum/reagent/consumable/salt = 1
	)
	requirements_mats_blacklist = list(/obj/item/stack/rods)
	result = /obj/item/food/kebab/candied_mushrooms
	category = CAT_LIZARD

/datum/crafting_recipe/food/sauerkraut
	name = "Sauerkraut"
	reqs = list(
		/obj/item/food/grown/cabbage = 2,
		/datum/reagent/consumable/salt = 10
	)
	result = /obj/item/food/sauerkraut
	category = CAT_LIZARD

/datum/crafting_recipe/food/lizard_dumplings
	name = "Tiziran dumplings"
	reqs = list(
		/obj/item/food/grown/potato = 1,
		/datum/reagent/consumable/korta_flour = 5
	)
	result = /obj/item/food/lizard_dumplings
	category = CAT_LIZARD

/datum/crafting_recipe/food/steeped_mushrooms
	name = "Steeped mushrooms"
	reqs = list(
		/obj/item/food/grown/ash_flora/seraka = 1,
		/datum/reagent/lye = 5
	)
	result = /obj/item/food/steeped_mushrooms
	category = CAT_LIZARD

/datum/crafting_recipe/food/rootbreadpbj
	name = "Peanut butter and jelly rootwich"
	reqs = list(
		/obj/item/food/breadslice/root = 2,
		/datum/reagent/consumable/peanut_butter = 5,
		/datum/reagent/consumable/cherryjelly = 5
	)
	result = /obj/item/food/rootbread_peanut_butter_jelly
	category = CAT_LIZARD

/datum/crafting_recipe/food/rootbreadpbb
	name = "Peanut butter and banana rootwich"
	reqs = list(
		/obj/item/food/breadslice/root = 2,
		/datum/reagent/consumable/peanut_butter = 5,
		/obj/item/food/grown/banana = 1
	)
	result = /obj/item/food/rootbread_peanut_butter_banana
	category = CAT_LIZARD
// Soups

/datum/crafting_recipe/food/reaction/soup/atrakor_dumplings
	reaction = /datum/chemical_reaction/food/soup/atrakor_dumplings
	category = CAT_LIZARD

/datum/crafting_recipe/food/reaction/soup/meatball_noodles
	reaction = /datum/chemical_reaction/food/soup/meatball_noodles
	category = CAT_LIZARD

/datum/crafting_recipe/food/reaction/soup/black_broth
	reaction = /datum/chemical_reaction/food/soup/black_broth
	category = CAT_LIZARD

/datum/crafting_recipe/food/reaction/soup/jellyfish_stew
	reaction = /datum/chemical_reaction/food/soup/jellyfish_stew
	category = CAT_LIZARD

/datum/crafting_recipe/food/reaction/soup/jellyfish_stew_two
	reaction = /datum/chemical_reaction/food/soup/jellyfish_stew_two
	category = CAT_LIZARD

/datum/crafting_recipe/food/reaction/soup/rootbread_soup
	reaction = /datum/chemical_reaction/food/soup/rootbread_soup
	category = CAT_LIZARD
