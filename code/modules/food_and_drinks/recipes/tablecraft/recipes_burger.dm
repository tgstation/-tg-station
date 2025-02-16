
// see code/module/crafting/table.dm

////////////////////////////////////////////////BURGERS////////////////////////////////////////////////


/datum/crafting_recipe/food/humanburger
	name = "Human burger"
	reqs = list(
		/obj/item/food/bun = 1,
		/obj/item/food/patty/human = 1
	)
	result = /obj/item/food/burger/human
	category = CAT_BURGER

/datum/crafting_recipe/food/burger
	name = "Plain Burger"
	reqs = list(
			/obj/item/food/patty/plain = 1,
			/obj/item/food/bun = 1
	)

	result = /obj/item/food/burger/plain
	category = CAT_BURGER

/datum/crafting_recipe/food/corgiburger
	name = "Corgi burger"
	reqs = list(
			/obj/item/food/patty/corgi = 1,
			/obj/item/food/bun = 1
	)

	result = /obj/item/food/burger/corgi
	category = CAT_BURGER

/datum/crafting_recipe/food/appendixburger
	name = "Appendix burger"
	reqs = list(
		/obj/item/organ/appendix = 1,
		/obj/item/food/bun = 1
	)
	result = /obj/item/food/burger/appendix
	category = CAT_BURGER

/datum/crafting_recipe/food/brainburger
	name = "Brain burger"
	reqs = list(
		/obj/item/organ/brain = 1,
		/obj/item/food/bun = 1
	)
	result = /obj/item/food/burger/brain
	category = CAT_BURGER

/datum/crafting_recipe/food/xenoburger
	name = "Xeno burger"
	reqs = list(
		/obj/item/food/patty/xeno = 1,
		/obj/item/food/bun = 1
	)
	result = /obj/item/food/burger/xeno
	category = CAT_BURGER

/datum/crafting_recipe/food/bearger
	name = "Bearger"
	reqs = list(
		/obj/item/food/patty/bear = 1,
		/obj/item/food/bun = 1
	)
	result = /obj/item/food/burger/bearger
	category = CAT_BURGER

/datum/crafting_recipe/food/fishburger
	name = "Fish burger"
	reqs = list(
		/obj/item/food/fishmeat = 1,
		/obj/item/food/bun = 1,
		/obj/item/food/cheese/wedge = 1
	)
	result = /obj/item/food/burger/fish
	category = CAT_BURGER

/datum/crafting_recipe/food/tofuburger
	name = "Tofu burger"
	reqs = list(
		/obj/item/food/tofu = 1,
		/obj/item/food/bun = 1
	)
	result = /obj/item/food/burger/tofu
	category = CAT_BURGER

/datum/crafting_recipe/food/ghostburger
	name = "Ghost burger"
	reqs = list(
		/obj/item/ectoplasm = 1,
		/datum/reagent/consumable/salt = 2,
		/obj/item/food/bun = 1
	)
	result = /obj/item/food/burger/ghost
	category = CAT_BURGER

/datum/crafting_recipe/food/clownburger
	name = "Clown burger"
	reqs = list(
		/obj/item/clothing/mask/gas/clown_hat = 1,
		/obj/item/food/bun = 1
	)
	result = /obj/item/food/burger/clown
	category = CAT_BURGER

/datum/crafting_recipe/food/mimeburger
	name = "Mime burger"
	reqs = list(
		/obj/item/clothing/mask/gas/mime = 1,
		/obj/item/food/bun = 1
	)
	result = /obj/item/food/burger/mime
	category = CAT_BURGER

/datum/crafting_recipe/food/redburger
	name = "Red burger"
	reqs = list(
		/obj/item/food/patty/plain = 1,
		/obj/item/toy/crayon/red = 1,
		/obj/item/food/bun = 1
	)
	result = /obj/item/food/burger/red
	category = CAT_BURGER

/datum/crafting_recipe/food/orangeburger
	name = "Orange burger"
	reqs = list(
		/obj/item/food/patty/plain = 1,
		/obj/item/toy/crayon/orange = 1,
		/obj/item/food/bun = 1
	)
	result = /obj/item/food/burger/orange
	category = CAT_BURGER

/datum/crafting_recipe/food/yellowburger
	name = "Yellow burger"
	reqs = list(
		/obj/item/food/patty/plain = 1,
		/obj/item/toy/crayon/yellow = 1,
		/obj/item/food/bun = 1
	)
	result = /obj/item/food/burger/yellow
	category = CAT_BURGER

/datum/crafting_recipe/food/greenburger
	name = "Green burger"
	reqs = list(
		/obj/item/food/patty/plain = 1,
		/obj/item/toy/crayon/green = 1,
		/obj/item/food/bun = 1
	)
	result = /obj/item/food/burger/green
	category = CAT_BURGER

/datum/crafting_recipe/food/blueburger
	name = "Blue burger"
	reqs = list(
		/obj/item/food/patty/plain = 1,
		/obj/item/toy/crayon/blue = 1,
		/obj/item/food/bun = 1
	)
	result = /obj/item/food/burger/blue
	category = CAT_BURGER

/datum/crafting_recipe/food/purpleburger
	name = "Purple burger"
	reqs = list(
		/obj/item/food/patty/plain = 1,
		/obj/item/toy/crayon/purple = 1,
		/obj/item/food/bun = 1
	)
	result = /obj/item/food/burger/purple
	category = CAT_BURGER

/datum/crafting_recipe/food/blackburger
	name = "Black burger"
	reqs = list(
		/obj/item/food/patty/plain = 1,
		/obj/item/toy/crayon/black = 1,
		/obj/item/food/bun = 1
	)
	result = /obj/item/food/burger/black
	category = CAT_BURGER

/datum/crafting_recipe/food/whiteburger
	name = "White burger"
	reqs = list(
		/obj/item/food/patty/plain = 1,
		/obj/item/toy/crayon/white = 1,
		/obj/item/food/bun = 1
	)
	result = /obj/item/food/burger/white
	category = CAT_BURGER

/datum/crafting_recipe/food/spellburger
	name = "Spell burger"
	reqs = list(
		/obj/item/clothing/head/wizard = 1,
		/obj/item/food/bun = 1
	)
	result = /obj/item/food/burger/spell
	category = CAT_BURGER

/datum/crafting_recipe/food/bigbiteburger
	name = "Big bite burger"
	reqs = list(
		/obj/item/food/patty/plain = 3,
		/obj/item/food/bun = 1,
		/obj/item/food/cheese/wedge = 2
	)
	result = /obj/item/food/burger/bigbite
	category = CAT_BURGER

/datum/crafting_recipe/food/superbiteburger
	name = "Super bite burger"
	reqs = list(
		/datum/reagent/consumable/salt = 5,
		/datum/reagent/consumable/blackpepper = 5,
		/obj/item/food/patty/plain = 5,
		/obj/item/food/grown/tomato = 4,
		/obj/item/food/cheese/wedge = 3,
		/obj/item/food/boiledegg = 1,
		/obj/item/food/meat/bacon = 1,
		/obj/item/food/bun = 1,
		/obj/item/food/pickle = 1,

	)
	result = /obj/item/food/burger/superbite
	category = CAT_BURGER

/datum/crafting_recipe/food/slimeburger
	name = "Jelly burger"
	reqs = list(
		/datum/reagent/toxin/slimejelly = 5,
		/obj/item/food/bun = 1
	)
	result = /obj/item/food/burger/jelly/slime
	category = CAT_BURGER

/datum/crafting_recipe/food/jellyburger
	name = "Jelly burger"
	reqs = list(
			/datum/reagent/consumable/cherryjelly = 5,
			/obj/item/food/bun = 1
	)
	result = /obj/item/food/burger/jelly/cherry
	category = CAT_BURGER

/datum/crafting_recipe/food/fivealarmburger
	name = "Five alarm burger"
	reqs = list(
			/obj/item/food/patty/plain = 1,
			/obj/item/food/grown/ghost_chili = 2,
			/obj/item/food/bun = 1
	)
	result = /obj/item/food/burger/fivealarm
	category = CAT_BURGER

/datum/crafting_recipe/food/ratburger
	name = "Rat burger"
	reqs = list(
			/obj/item/food/deadmouse = 1,
			/obj/item/food/bun = 1
	)
	result = /obj/item/food/burger/rat
	category = CAT_BURGER

/datum/crafting_recipe/food/baseballburger
	name = "Home run baseball burger"
	reqs = list(
			/obj/item/melee/baseball_bat = 1,
			/obj/item/food/bun = 1
	)
	result = /obj/item/food/burger/baseball
	category = CAT_BURGER

/datum/crafting_recipe/food/baconburger
	name = "Bacon Burger"
	reqs = list(
			/obj/item/food/meat/bacon = 3,
			/obj/item/food/bun = 1
	)

	result = /obj/item/food/burger/baconburger
	category = CAT_BURGER

/datum/crafting_recipe/food/empoweredburger
	name = "Empowered Burger"
	reqs = list(
			/obj/item/stack/sheet/mineral/plasma = 2,
			/obj/item/food/bun = 1
	)
	requirements_mats_blacklist = list(/obj/item/stack/sheet/mineral/plasma)
	result = /obj/item/food/burger/empoweredburger
	category = CAT_BURGER

/datum/crafting_recipe/food/catburger
	name = "Cat burger"
	reqs = list(
		/obj/item/food/bun = 1,
		/obj/item/food/patty/plain = 1,
		/obj/item/organ/ears/cat = 1,
		/obj/item/organ/tail/cat = 1,
	)
	result = /obj/item/food/burger/catburger
	category = CAT_BURGER

/datum/crafting_recipe/food/crabburger
	name = "Crab Burger"
	reqs = list(
			/obj/item/food/meat/crab = 2,
			/obj/item/food/bun = 1
	)

	result = /obj/item/food/burger/crab
	category = CAT_BURGER

/datum/crafting_recipe/food/cheeseburger
	name = "Cheese Burger"
	reqs = list(
			/obj/item/food/patty/plain = 1,
			/obj/item/food/bun = 1,
			/obj/item/food/cheese/wedge = 1,
	)
	result = /obj/item/food/burger/cheese
	category = CAT_BURGER

/datum/crafting_recipe/food/soylentburger
	name = "Soylent Burger"
	reqs = list(
			/obj/item/food/soylentgreen = 1, //two full meats worth.
			/obj/item/food/bun = 1,
			/obj/item/food/cheese/wedge = 2,
	)
	result = /obj/item/food/burger/soylent
	category = CAT_BURGER

/datum/crafting_recipe/food/ribburger
	name = "McRib"
	reqs = list(
			/obj/item/food/bbqribs = 1,     //The sauce is already included in the ribs
			/obj/item/food/onion_slice = 1, //feel free to remove if too burdensome.
			/obj/item/food/bun = 1
	)
	result = /obj/item/food/burger/rib
	category = CAT_BURGER

/datum/crafting_recipe/food/mcguffin
	name = "McGuffin"
	reqs = list(
			/obj/item/food/friedegg = 1,
			/obj/item/food/meat/bacon = 2,
			/obj/item/food/bun = 1
	)
	result = /obj/item/food/burger/mcguffin
	category = CAT_BURGER

/datum/crafting_recipe/food/chickenburger
	name = "Chicken Sandwich"
	reqs = list(
			/obj/item/food/patty/chicken = 1,
			/datum/reagent/consumable/mayonnaise = 5,
			/obj/item/food/bun = 1
	)
	result = /obj/item/food/burger/chicken
	category = CAT_BURGER

/datum/crafting_recipe/food/crazyhamburger
	name = "Crazy hamburger"
	reqs = list(
			/obj/item/food/patty/plain = 2,
			/obj/item/food/bun = 1,
			/obj/item/food/cheese/wedge = 2,
			/obj/item/food/grown/chili = 1,
			/obj/item/food/grown/cabbage = 1,
			/obj/item/toy/crayon/green = 1,
			/obj/item/flashlight/flare = 1,
			/datum/reagent/consumable/nutriment/fat/oil = 15
	)
	result = /obj/item/food/burger/crazy
	category = CAT_BURGER

/datum/crafting_recipe/food/sloppy_moe
	name = "Sloppy moe"
	reqs = list(
			/obj/item/food/bun = 1,
			/obj/item/food/meat/cutlet = 2,
			/obj/item/food/onion_slice = 1,
			/datum/reagent/consumable/bbqsauce = 5,
	)
	result = /obj/item/food/burger/sloppy_moe
	category = CAT_BURGER

/datum/crafting_recipe/food/kortaburger
	name = "Plain Rootburger"
	reqs = list(
			/obj/item/food/patty/plain = 1,
			/obj/item/food/rootroll = 1
	)
	result = /obj/item/food/burger/plain/korta
	category = CAT_BURGER

/datum/crafting_recipe/food/ratkorta
	name = "Rat Rootburger"
	reqs = list(
			/obj/item/food/deadmouse = 1,
			/obj/item/food/rootroll = 1
	)
	result = /obj/item/food/burger/rat/korta
	category = CAT_BURGER

/datum/crafting_recipe/food/rootguffin
	name = "Root-Guffin"
	reqs = list(
			/obj/item/food/friedegg = 1,
			/obj/item/food/meat/bacon = 2,
			/obj/item/food/rootroll = 1
	)
	result = /obj/item/food/burger/rootguffin
	category = CAT_BURGER

/datum/crafting_recipe/food/rootrib
	name = "RootRib"
	reqs = list(
			/obj/item/food/bbqribs = 1,     //The sauce is already included in the ribs
			/obj/item/food/onion_slice = 1, //feel free to remove if too burdensome.
			/obj/item/food/rootroll = 1
	)
	result = /obj/item/food/burger/rootrib
	category = CAT_BURGER

/datum/crafting_recipe/food/rootchicken
	name = "Chicken Rootwich"
	reqs = list(
			/obj/item/food/patty/chicken = 1,
			/datum/reagent/consumable/mayonnaise = 5,
			/obj/item/food/rootroll = 1
	)
	result = /obj/item/food/burger/rootchicken
	category = CAT_BURGER

/datum/crafting_recipe/food/rootfish
	name = "Fish rootburger"
	reqs = list(
		/obj/item/food/fishmeat = 1,
		/obj/item/food/rootroll = 1
	)
	result = /obj/item/food/burger/rootfish
	category = CAT_BURGER

/datum/crafting_recipe/food/sloppyroot
	name = "Sssloppy moe"
	reqs = list(
			/obj/item/food/rootroll = 1,
			/obj/item/food/meat/cutlet = 2,
			/obj/item/food/onion_slice = 1,
			/datum/reagent/consumable/bbqsauce = 5,
	)
	result = /obj/item/food/burger/sloppyroot
	category = CAT_BURGER
