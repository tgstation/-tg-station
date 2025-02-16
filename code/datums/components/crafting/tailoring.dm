/datum/crafting_recipe/durathread_vest
	name = "Durathread Vest"
	result = /obj/item/clothing/suit/armor/vest/durathread
	reqs = list(/obj/item/stack/sheet/durathread = 5,
				/obj/item/stack/sheet/leather = 4)
	time = 5 SECONDS
	category = CAT_CLOTHING

/datum/crafting_recipe/durathread_robe
	name = "Durathread Robe"
	result = /obj/item/clothing/suit/wizrobe/durathread
	reqs = list(
		/obj/item/stack/sheet/durathread = 3,
		/obj/item/stack/sheet/leather = 6,
	)
	time = 5 SECONDS
	category = CAT_CLOTHING

/datum/crafting_recipe/durathread_robe_fire
	name = "Durathread Pyromancer Robe"
	result = /obj/item/clothing/suit/wizrobe/durathread/fire
	reqs = list(/obj/item/clothing/suit/wizrobe/durathread = 1,
				/obj/item/grown/novaflower = 1,
				/obj/item/seeds/chili = 3)
	time = 2 SECONDS
	category = CAT_CLOTHING

/datum/crafting_recipe/durathread_robe_ice
	name = "Durathread Ice-o-mancer Robe"
	result = /obj/item/clothing/suit/wizrobe/durathread/ice
	reqs = list(/obj/item/clothing/suit/wizrobe/durathread = 1,
				/obj/item/seeds/chili/ice = 1,
				/obj/item/food/grown/herbs = 3)
	time = 2 SECONDS
	category = CAT_CLOTHING

/datum/crafting_recipe/durathread_robe_electric
	name = "Durathread Electromancer Robe"
	result = /obj/item/clothing/suit/wizrobe/durathread/electric
	reqs = list(/obj/item/clothing/suit/wizrobe/durathread = 1,
				/obj/item/food/grown/mushroom/jupitercup = 1,
				/obj/item/food/grown/sunflower = 3)
	time = 2 SECONDS
	category = CAT_CLOTHING

/datum/crafting_recipe/durathread_robe_earth
	name = "Durathread Geomancer Robe"
	result = /obj/item/clothing/suit/wizrobe/durathread/earth
	reqs = list(/obj/item/clothing/suit/wizrobe/durathread = 1,
				/obj/item/food/grown/cahnroot = 1,
				/obj/item/food/grown/potato = 3)
	time = 2 SECONDS
	category = CAT_CLOTHING

/datum/crafting_recipe/durathread_robe_necro
	name = "Durathread Necromancer Robe"
	result = /obj/item/clothing/suit/wizrobe/durathread/necro
	reqs = list(/obj/item/clothing/suit/wizrobe/durathread = 1,
				/obj/item/food/grown/cannabis/death = 2,
				/obj/item/food/grown/mushroom/angel = 2)
	time = 2 SECONDS
	category = CAT_CLOTHING

/datum/crafting_recipe/durathread_helmet
	name = "Durathread Helmet"
	result = /obj/item/clothing/head/helmet/durathread
	reqs = list(/obj/item/stack/sheet/durathread = 4,
				/obj/item/stack/sheet/leather = 5)
	time = 4 SECONDS
	category = CAT_CLOTHING

/datum/crafting_recipe/watermelon_armour
	name = "Watermelon Armour"
	result = /obj/item/clothing/suit/armor/durability/watermelon
	reqs = list(/obj/item/clothing/head/helmet/durability/watermelon = 3,
				/obj/item/stack/sheet/durathread = 1)
	time = 4 SECONDS
	category = CAT_CLOTHING

/datum/crafting_recipe/watermelon_armour_fr
	name = "Watermelon Armour"
	result = /obj/item/clothing/suit/armor/durability/watermelon/fire_resist
	reqs = list(/obj/item/clothing/head/helmet/durability/watermelon/fire_resist = 3,
				/obj/item/stack/sheet/durathread = 1)
	time = 4 SECONDS
	category = CAT_CLOTHING

/datum/crafting_recipe/holymelon_armour
	name = "Holymelon Armour"
	result = /obj/item/clothing/suit/armor/durability/holymelon
	reqs = list(/obj/item/clothing/head/helmet/durability/holymelon = 3,
				/obj/item/stack/sheet/durathread = 1)
	time = 4 SECONDS
	category = CAT_CLOTHING

/datum/crafting_recipe/holymelonmelon_armour_fr
	name = "Holymelon Armour"
	result = /obj/item/clothing/suit/armor/durability/holymelon/fire_resist
	reqs = list(/obj/item/clothing/head/helmet/durability/holymelon/fire_resist = 3,
				/obj/item/stack/sheet/durathread = 1)
	time = 4 SECONDS
	category = CAT_CLOTHING

/datum/crafting_recipe/barrelmelon_armour
	name = "Barrelmelon Armour"
	result = /obj/item/clothing/suit/armor/durability/barrelmelon
	reqs = list(/obj/item/clothing/head/helmet/durability/barrelmelon = 3,
				/obj/item/stack/sheet/durathread = 1)
	time = 4 SECONDS
	category = CAT_CLOTHING

/datum/crafting_recipe/barrelmelon_armour_fr
	name = "Barrelmelon Armour"
	result = /obj/item/clothing/suit/armor/durability/barrelmelon/fire_resist
	reqs = list(/obj/item/clothing/head/helmet/durability/barrelmelon/fire_resist = 3,
				/obj/item/stack/sheet/durathread = 1)
	time = 4 SECONDS
	category = CAT_CLOTHING

/datum/crafting_recipe/grass_sheath
	name = "Grass Sabre Sheath"
	result = /obj/item/storage/belt/grass_sabre
	reqs = list(/obj/item/food/grown/grass = 4,
				/obj/item/food/grown/grass/fairy = 2)
	time = 4 SECONDS
	category = CAT_CONTAINERS

/datum/crafting_recipe/fannypack
	name = "Fannypack"
	result = /obj/item/storage/belt/fannypack
	reqs = list(/obj/item/stack/sheet/cloth = 2,
				/obj/item/stack/sheet/leather = 1)
	time = 2 SECONDS
	category = CAT_CONTAINERS

/datum/crafting_recipe/hudsunsec
	name = "Security HUDsunglasses"
	result = /obj/item/clothing/glasses/hud/security/sunglasses
	time = 2 SECONDS
	tool_behaviors = list(TOOL_SCREWDRIVER, TOOL_WIRECUTTER)
	reqs = list(/obj/item/clothing/glasses/hud/security = 1,
				  /obj/item/clothing/glasses/sunglasses = 1,
				  /obj/item/stack/cable_coil = 5)
	category = CAT_EQUIPMENT

/datum/crafting_recipe/hudsunsecremoval
	name = "Security HUD removal"
	result = /obj/item/clothing/glasses/sunglasses
	time = 2 SECONDS
	tool_behaviors = list(TOOL_SCREWDRIVER, TOOL_WIRECUTTER)
	reqs = list(/obj/item/clothing/glasses/hud/security/sunglasses = 1)
	category = CAT_EQUIPMENT

/datum/crafting_recipe/hudsunmed
	name = "Medical HUDsunglasses"
	result = /obj/item/clothing/glasses/hud/health/sunglasses
	time = 2 SECONDS
	tool_behaviors = list(TOOL_SCREWDRIVER, TOOL_WIRECUTTER)
	reqs = list(/obj/item/clothing/glasses/hud/health = 1,
				  /obj/item/clothing/glasses/sunglasses = 1,
				  /obj/item/stack/cable_coil = 5)
	category = CAT_EQUIPMENT

/datum/crafting_recipe/hudsunmedremoval
	name = "Medical HUD removal"
	result = /obj/item/clothing/glasses/sunglasses
	time = 2 SECONDS
	tool_behaviors = list(TOOL_SCREWDRIVER, TOOL_WIRECUTTER)
	reqs = list(/obj/item/clothing/glasses/hud/health/sunglasses = 1)
	category = CAT_EQUIPMENT

/datum/crafting_recipe/hudsundiag
	name = "Diagnostic HUDsunglasses"
	result = /obj/item/clothing/glasses/hud/diagnostic/sunglasses
	time = 2 SECONDS
	tool_behaviors = list(TOOL_SCREWDRIVER, TOOL_WIRECUTTER)
	reqs = list(/obj/item/clothing/glasses/hud/diagnostic = 1,
				  /obj/item/clothing/glasses/sunglasses = 1,
				  /obj/item/stack/cable_coil = 5)
	category = CAT_EQUIPMENT

/datum/crafting_recipe/hudsundiagremoval
	name = "Diagnostic HUD removal"
	result = /obj/item/clothing/glasses/sunglasses
	time = 2 SECONDS
	tool_behaviors = list(TOOL_SCREWDRIVER, TOOL_WIRECUTTER)
	reqs = list(/obj/item/clothing/glasses/hud/diagnostic/sunglasses = 1)
	category = CAT_EQUIPMENT

/datum/crafting_recipe/scienceglasses
	name = "Science Glasses"
	result = /obj/item/clothing/glasses/sunglasses/chemical
	time = 2 SECONDS
	tool_behaviors = list(TOOL_SCREWDRIVER, TOOL_WIRECUTTER)
	reqs = list(/obj/item/clothing/glasses/science = 1,
				  /obj/item/clothing/glasses/sunglasses = 1,
				  /obj/item/stack/cable_coil = 5)
	category = CAT_EQUIPMENT

/datum/crafting_recipe/scienceglassesremoval
	name = "Chemical Scanner removal"
	result = /obj/item/clothing/glasses/sunglasses
	time = 2 SECONDS
	tool_behaviors = list(TOOL_SCREWDRIVER, TOOL_WIRECUTTER)
	reqs = list(/obj/item/clothing/glasses/sunglasses/chemical = 1)
	category = CAT_EQUIPMENT

/datum/crafting_recipe/ghostsheet
	name = "Ghost Sheet"
	result = /obj/item/clothing/suit/costume/ghost_sheet
	time = 0.5 SECONDS
	tool_behaviors = list(TOOL_WIRECUTTER)
	reqs = list(/obj/item/bedsheet = 1)
	category = CAT_CLOTHING

/datum/crafting_recipe/lizardboots
	name = "Lizard Skin Boots"
	result = /obj/effect/spawner/random/clothing/lizardboots
	reqs = list(/obj/item/stack/sheet/animalhide/lizard = 1, /obj/item/stack/sheet/leather = 1)
	time = 6 SECONDS
	category = CAT_CLOTHING

/datum/crafting_recipe/prisonsuit
	name = "Prisoner Uniform (Suit)"
	result = /obj/item/clothing/under/rank/prisoner
	reqs = list(/obj/item/stack/sheet/cloth = 3, /obj/item/stack/license_plates = 1)
	time = 2 SECONDS
	category = CAT_CLOTHING

/datum/crafting_recipe/prisonskirt
	name = "Prisoner Uniform (Skirt)"
	result = /obj/item/clothing/under/rank/prisoner/skirt
	reqs = list(/obj/item/stack/sheet/cloth = 3, /obj/item/stack/license_plates = 1)
	time = 2 SECONDS
	category = CAT_CLOTHING

/datum/crafting_recipe/prisonshoes
	name = "Orange Prison Shoes"
	result = /obj/item/clothing/shoes/sneakers/orange
	reqs = list(/obj/item/stack/sheet/cloth = 2, /obj/item/stack/license_plates = 1)
	time = 1 SECONDS
	category = CAT_CLOTHING

/datum/crafting_recipe/tv_helmet
	name = "Television Helmet"
	result = /obj/item/clothing/head/costume/tv_head
	tool_behaviors = list(TOOL_SCREWDRIVER, TOOL_CROWBAR)
	reqs = list(/obj/item/wallframe/status_display = 1)
	time = 2 SECONDS
	category = CAT_CLOTHING

/datum/crafting_recipe/lizardhat
	name = "Lizard Cloche Hat"
	result = /obj/item/clothing/head/costume/lizard
	time = 1 SECONDS
	reqs = list(/obj/item/organ/tail/lizard = 1)
	category = CAT_CLOTHING

/datum/crafting_recipe/lizardhat_alternate
	name = "Lizard Cloche Hat"
	result = /obj/item/clothing/head/costume/lizard
	time = 1 SECONDS
	reqs = list(/obj/item/stack/sheet/animalhide/lizard = 1)
	category = CAT_CLOTHING

/datum/crafting_recipe/kittyears
	name = "Kitty Ears"
	result = /obj/item/clothing/head/costume/kitty/genuine
	time = 1 SECONDS
	reqs = list(
		/obj/item/organ/tail/cat = 1,
		/obj/item/organ/ears/cat = 1,
	)
	category = CAT_CLOTHING

/datum/crafting_recipe/bonearmor
	name = "Bone Armor"
	result = /obj/item/clothing/suit/armor/bone
	time = 3 SECONDS
	reqs = list(
		/obj/item/stack/sheet/bone = 6,
		/obj/item/stack/sheet/animalhide/goliath_hide = 3,
	)
	category = CAT_CLOTHING

/datum/crafting_recipe/bonetalisman
	name = "Bone Talisman"
	result = /obj/item/clothing/accessory/talisman
	time = 2 SECONDS
	reqs = list(
		/obj/item/stack/sheet/bone = 2,
		/obj/item/stack/sheet/sinew = 1,
	)
	category = CAT_CLOTHING

/datum/crafting_recipe/bonecodpiece
	name = "Skull Codpiece"
	result = /obj/item/clothing/accessory/skullcodpiece
	time = 2 SECONDS
	reqs = list(
		/obj/item/stack/sheet/bone = 2,
		/obj/item/stack/sheet/animalhide/goliath_hide = 1,
	)
	category = CAT_CLOTHING

/datum/crafting_recipe/skilt
	name = "Sinew Kilt"
	result = /obj/item/clothing/accessory/skilt
	time = 2 SECONDS
	reqs = list(
		/obj/item/stack/sheet/bone = 1,
		/obj/item/stack/sheet/sinew = 2,
	)
	category = CAT_CLOTHING

/datum/crafting_recipe/wreath
	name = "Watcher Wreath"
	result = /obj/item/clothing/neck/wreath
	time = 2 SECONDS
	reqs = list(
		/obj/item/stack/sheet/bone = 2,
		/obj/item/stack/sheet/sinew = 2,
		/obj/item/stack/ore/diamond = 2,
	)
	category = CAT_CLOTHING

/datum/crafting_recipe/icewreath
	name = "Icewing Wreath"
	result = /obj/item/clothing/neck/wreath/icewing
	time = 2 SECONDS
	reqs = list(
		/obj/item/stack/sheet/bone = 1,
		/obj/item/stack/sheet/sinew = 1,
		/obj/item/stack/ore/diamond = 2,
		/obj/item/crusher_trophy/watcher_wing/ice_wing = 1,
	)
	category = CAT_CLOTHING

/datum/crafting_recipe/bracers
	name = "Bone Bracers"
	result = /obj/item/clothing/gloves/bracer
	time = 2 SECONDS
	reqs = list(
		/obj/item/stack/sheet/bone = 2,
		/obj/item/stack/sheet/sinew = 1,
	)
	category = CAT_CLOTHING

/datum/crafting_recipe/skullhelm
	name = "Skull Helmet"
	result = /obj/item/clothing/head/helmet/skull
	time = 3 SECONDS
	reqs = list(/obj/item/stack/sheet/bone = 4)
	category = CAT_CLOTHING

/datum/crafting_recipe/goliathcloak
	name = "Goliath Cloak"
	result = /obj/item/clothing/suit/hooded/cloak/goliath
	time = 5 SECONDS
	reqs = list(
		/obj/item/stack/sheet/sinew = 3,
		/obj/item/stack/sheet/animalhide/goliath_hide = 9,
	)
	category = CAT_CLOTHING

/datum/crafting_recipe/drakecloak
	name = "Ash Drake Armour"
	result = /obj/item/clothing/suit/hooded/cloak/drake
	time = 4 SECONDS
	reqs = list(
		/obj/item/stack/sheet/sinew = 2,
		/obj/item/drake_remains = 1,
	)
	category = CAT_CLOTHING

/datum/crafting_recipe/drakeremains
	name = "Drake Remains"
	result = /obj/item/drake_remains
	time = 1 SECONDS
	reqs = list(
		/obj/item/stack/sheet/bone = 10,
		/obj/item/stack/sheet/animalhide/ashdrake = 5,
	)
	category = CAT_CLOTHING

/datum/crafting_recipe/godslayer
	name = "Godslayer Armour"
	result = /obj/item/clothing/suit/hooded/cloak/godslayer
	time = 6 SECONDS
	reqs = list(
		/obj/item/ice_energy_crystal = 1,
		/obj/item/wendigo_skull = 1,
		/obj/item/clockwork_alloy = 1,
	)
	category = CAT_CLOTHING

/datum/crafting_recipe/mummy
	name = "Mummification Bandages (Mask)"
	result = /obj/item/clothing/mask/mummy
	time = 1 SECONDS
	tool_paths = list(/obj/item/nullrod/egyptian)
	reqs = list(/obj/item/stack/sheet/cloth = 2)
	category = CAT_CLOTHING

/datum/crafting_recipe/mummy/body
	name = "Mummification Bandages (Body)"
	result = /obj/item/clothing/under/costume/mummy
	reqs = list(/obj/item/stack/sheet/cloth = 5)

/datum/crafting_recipe/chaplain_hood
	name = "Follower Hoodie"
	result = /obj/item/clothing/suit/hooded/chaplain_hoodie
	time = 1 SECONDS
	tool_paths = list(
		/obj/item/clothing/suit/hooded/chaplain_hoodie,
		/obj/item/book/bible,
	)
	reqs = list(/obj/item/stack/sheet/cloth = 4)
	category = CAT_CLOTHING

/datum/crafting_recipe/chaplain_hood/New()
	. = ..()
	//the resulting hoodie can be used to craft other hoodies.
	//recipe blacklists should be refactored to only affect components and not tools.
	blacklist -= result

/datum/crafting_recipe/flower_garland
	name = "Flower Garland"
	result = /obj/item/clothing/head/costume/garland
	time = 1 SECONDS
	reqs = list(
		/obj/item/food/grown/poppy = 4,
		/obj/item/food/grown/harebell = 4,
		/obj/item/food/grown/rose = 4,
	)
	category = CAT_CLOTHING

/datum/crafting_recipe/poppy_crown
	name = "Poppy Crown"
	result = /obj/item/clothing/head/costume/garland/poppy
	time = 1 SECONDS
	reqs = list(
		/obj/item/food/grown/poppy = 5,
		/obj/item/stack/cable_coil = 3,
	)
	category = CAT_CLOTHING

/datum/crafting_recipe/lily_crown
	name = "Lily Crown"
	result = /obj/item/clothing/head/costume/garland/lily
	time = 1 SECONDS
	reqs = list(
		/obj/item/food/grown/poppy/lily = 5,
		/obj/item/stack/cable_coil = 3,
	)
	category = CAT_CLOTHING

/datum/crafting_recipe/sunflower_crown
	name = "Sunflower Crown"
	result = /obj/item/clothing/head/costume/garland/sunflower
	time = 1 SECONDS
	reqs = list(
		/obj/item/food/grown/sunflower = 5,
		/obj/item/stack/cable_coil = 3,
	)
	category = CAT_CLOTHING

/datum/crafting_recipe/rainbow_bunch_crown
	name = "Rainbow Flower Crown"
	result = /obj/item/clothing/head/costume/garland/rainbowbunch
	time = 1 SECONDS
	reqs = list(
		/obj/item/food/grown/rainbow_flower = 5,
		/obj/item/stack/cable_coil = 3,
	)
	category = CAT_CLOTHING

/datum/crafting_recipe/pillow_suit
	name = "pillow suit"
	result = /obj/item/clothing/suit/pillow_suit
	time = 2 SECONDS
	reqs = list(
		/obj/item/stack/sticky_tape = 10,
		/obj/item/pillow = 5,
	)
	category = CAT_CLOTHING

/datum/crafting_recipe/pillow_hood
	name = "pillow hood"
	result = /obj/item/clothing/head/pillow_hood
	tool_behaviors = list(TOOL_WIRECUTTER, TOOL_KNIFE)
	time = 2 SECONDS
	reqs = list(
		/obj/item/stack/sticky_tape = 5,
		/obj/item/pillow = 1,
	)
	category = CAT_CLOTHING

/datum/crafting_recipe/shark_costume
	name = "shark costume"
	result = /obj/item/clothing/suit/hooded/shark_costume
	time = 2 SECONDS
	reqs = list(
		/obj/item/stack/sheet/leather = 5,
		/obj/item/stack/sheet/animalhide/carp = 5,
	)
	category = CAT_CLOTHING

/datum/crafting_recipe/shork_costume
	name = "shork costume"
	result = /obj/item/clothing/suit/hooded/shork_costume
	time = 2 SECONDS
	tool_behaviors = list(TOOL_WIRECUTTER)
	reqs = list(
		/obj/item/clothing/suit/hooded/shark_costume = 1,
	)
	category = CAT_CLOTHING


/datum/crafting_recipe/sturdy_shako
	name = "Sturdy Shako"
	result = /obj/item/clothing/head/hats/hos/shako
	tool_behaviors = list(TOOL_WELDER, TOOL_KNIFE)
	time = 5 SECONDS
	reqs = list(
		/obj/item/clothing/head/hats/hos/cap = 1,
		/obj/item/stack/sheet/plasteel = 2, //Stout shako for two refined
		/obj/item/stack/sheet/mineral/gold = 2,
	)

	category = CAT_CLOTHING

/datum/crafting_recipe/atmospherics_gas_mask
	name = "atmospherics gas mask"
	result = /obj/item/clothing/mask/gas/atmos
	tool_behaviors = list(TOOL_WELDER)
	time = 8 SECONDS
	reqs = list(
		/obj/item/stack/sheet/mineral/metal_hydrogen = 1,
		/obj/item/stack/sheet/mineral/zaukerite = 1,
	)

	category = CAT_CLOTHING

/datum/crafting_recipe/paper_hat
	name = "Paper Hat"
	result = /obj/item/clothing/head/costume/paper_hat
	time = 5 SECONDS
	reqs = list(
		/obj/item/paper = 1,
	)
	category = CAT_CLOTHING

/datum/crafting_recipe/biohood_sec
	name = "security biohood"
	result = /obj/item/clothing/head/bio_hood/security
	time = 2 SECONDS
	reqs = list(
		/obj/item/clothing/head/bio_hood/general = 1,
		/obj/item/clothing/head/helmet/sec = 1,
	)
	category = CAT_CLOTHING

/datum/crafting_recipe/biosuit_sec
	name = "security biosuit"
	result = /obj/item/clothing/suit/bio_suit/security
	time = 2 SECONDS
	reqs = list(
		/obj/item/clothing/suit/bio_suit/general = 1,
		/obj/item/clothing/suit/armor/vest = 1,
	)
	category = CAT_CLOTHING

/datum/crafting_recipe/balloon_helmet
	result = /obj/item/clothing/head/helmet/balloon
	reqs = list(
		/obj/item/toy/balloon/long = 6,
	)
	time = 4 SECONDS
	category = CAT_CLOTHING

/datum/crafting_recipe/balloon_helmet/check_requirements(mob/user, list/collected_requirements)
	. = ..()
	if(HAS_TRAIT(user, TRAIT_BALLOON_SUTRA))
		return TRUE

/datum/crafting_recipe/balloon_tophat
	result = /obj/item/clothing/head/hats/tophat/balloon
	reqs = list(
		/obj/item/toy/balloon/long = 6,
	)
	time = 4 SECONDS
	category = CAT_CLOTHING

/datum/crafting_recipe/balloon_tophat/check_requirements(mob/user, list/collected_requirements)
	. = ..()
	if(HAS_TRAIT(user, TRAIT_BALLOON_SUTRA))
		return TRUE

/datum/crafting_recipe/balloon_vest
	result = /obj/item/clothing/suit/armor/balloon_vest
	reqs = list(
		/obj/item/toy/balloon/long = 18,
	)
	time = 8 SECONDS
	category = CAT_CLOTHING

/datum/crafting_recipe/balloon_vest/check_requirements(mob/user, list/collected_requirements)
	. = ..()
	if(HAS_TRAIT(user, TRAIT_BALLOON_SUTRA))
		return TRUE

/datum/crafting_recipe/press_armor
	name = "press armor vest"
	result = /obj/item/clothing/suit/armor/vest/press
	time = 2 SECONDS
	tool_paths = list(/obj/item/clothing/accessory/press_badge)
	reqs = list(
		/obj/item/clothing/suit/armor/vest = 1,
	)
	category = CAT_CLOTHING

/datum/crafting_recipe/press_helmet
	name = "press helmet vest"
	result = /obj/item/clothing/head/helmet/press
	time = 2 SECONDS
	tool_paths = list(/obj/item/clothing/accessory/press_badge)
	reqs = list(
		/obj/item/clothing/head/helmet/sec = 1,
	)
	category = CAT_CLOTHING

/datum/crafting_recipe/press_vest
	name = "press vest"
	result = /obj/item/clothing/suit/hazardvest/press
	time = 2 SECONDS
	tool_paths = list(/obj/item/clothing/accessory/press_badge)
	reqs = list(
		/obj/item/clothing/suit/hazardvest = 1,
	)
	category = CAT_CLOTHING

/datum/crafting_recipe/press_fedora
	name = "press fedora"
	result = /obj/item/clothing/head/fedora/beige/press
	time = 2 SECONDS
	tool_paths = list(/obj/item/clothing/accessory/press_badge)
	reqs = list(
		/obj/item/clothing/head/fedora/beige = 1,
	)
	category = CAT_CLOTHING

/datum/crafting_recipe/jonkler
	name = "gamer's wig and mask"
	result = /obj/item/clothing/mask/gas/jonkler
	time = 10 SECONDS
	tool_paths = list(/obj/item/toy/crayon/green)
	reqs = list(
		/obj/item/clothing/mask/gas/clown_hat = 1,
	)
	category = CAT_CLOTHING
