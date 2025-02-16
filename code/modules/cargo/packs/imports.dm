/**
 * Imports category.
 * This is for crates not intended for goodies, but also not intended for departmental orders.
 * This allows us to have a few crates meant for deliberate purchase through cargo, and for cargo to have a few items
 * they explicitly control. It also holds all of the black market material and contraband material, including items
 * meant for purchase only through emagging the console.
 */

/datum/supply_pack/imports
	group = "Imports"
	crate_name = "emergency crate"
	crate_type = /obj/structure/closet/crate/internals

/datum/supply_pack/imports/foamforce
	name = "Foam Force Crate"
	desc = "Break out the big guns with eight Foam Force shotguns!"
	cost = CARGO_CRATE_VALUE * 2
	contains = list(/obj/item/gun/ballistic/shotgun/toy = 8)
	crate_name = "foam force crate"
	crate_type = /obj/structure/closet/crate/freezer/donk
	discountable = SUPPLY_PACK_STD_DISCOUNTABLE

/datum/supply_pack/imports/foamforce/bonus
	name = "Foam Force Pistols Crate"
	desc = "Psst.. hey bud... remember those old foam force pistols that got discontinued for being too cool? \
		Well I got two of those right here with your name on em. I'll even throw in a spare mag for each, waddya say?"
	contraband = TRUE
	cost = CARGO_CRATE_VALUE * 3
	contains = list(
		/obj/item/gun/ballistic/automatic/pistol/toy = 2,
		/obj/item/ammo_box/magazine/toy/pistol = 2,
	)
	crate_name = "foam force crate"
	crate_type = /obj/structure/closet/crate/freezer/donk

/datum/supply_pack/imports/meatmeatmeatmeat // MEAT MEAT MEAT MEAT
	name = "MEAT MEAT MEAT MEAT MEAT"
	desc = "MEAT MEAT MEAT MEAT MEAT MEAT"
	cost = CARGO_CRATE_VALUE * 6
	contains = list(/obj/item/storage/backpack/meat)
	crate_name = "MEAT MEAT MEAT MEAT MEAT"
	crate_type = /obj/structure/closet/crate/necropolis
	discountable = SUPPLY_PACK_RARE_DISCOUNTABLE

/datum/supply_pack/imports/duct_spider
	name = "Duct Spider Crate"
	desc = "Awww! Straight from the Australicus sector to your station's ventilation system!"
	cost = CARGO_CRATE_VALUE * 4
	contains = list(/mob/living/basic/spider/maintenance)
	crate_name = "duct spider crate"
	crate_type = /obj/structure/closet/crate/critter
	discountable = SUPPLY_PACK_UNCOMMON_DISCOUNTABLE

/datum/supply_pack/imports/duct_spider/dangerous
	name = "Duct Spider Crate?"
	desc = "Wait, is this the right crate? It has a frowny face, what does that mean?"
	cost = CARGO_CRATE_VALUE * 4
	contains = list(/mob/living/basic/spider/giant/hunter)
	contraband = TRUE

/datum/supply_pack/imports/bamboo50
	name = "50 Bamboo Cuttings"
	desc = "You have no idea how many pandas we had to kill to get this bamboo."
	cost = CARGO_CRATE_VALUE * 15
	contains = list(/obj/item/stack/sheet/mineral/bamboo/fifty)
	crate_name = "bamboo cuttings crate"

/datum/supply_pack/imports/bananium
	name = "A Single Sheet of Bananium"
	desc = "Don't let the clown know that he can order this. It costs a fortune even for this much."
	cost = CARGO_CRATE_VALUE * 100
	contains = list(/obj/item/stack/sheet/mineral/bananium)
	crate_name = "bananium sheet crate"
	discountable = SUPPLY_PACK_RARE_DISCOUNTABLE

/datum/supply_pack/imports/dumpstercorpse
	name = "A....Dumpster?"
	desc = "Why does it smell so bad...."
	cost = CARGO_CRATE_VALUE * 5
	contains = list(/mob/living/carbon/human)
	crate_name = "putrid dumpster"
	crate_type = /obj/structure/closet/crate/trashcart

/datum/supply_pack/imports/dumpstercorpse/generate()
	. = ..()
	var/mob/living/carbon/human/corpse = locate() in .
	corpse.death()

/datum/supply_pack/imports/dumpsterloot
	name = "A....Dumpster"
	desc = "I'm not sure why you bothered to buy this...and why does it cost so much?"
	cost = CARGO_CRATE_VALUE * 5
	contains = list(
		/obj/effect/spawner/random/maintenance/three,
		/obj/effect/spawner/random/trash/garbage = 5,
	)
	crate_name = "putrid dumpster"
	crate_type = /obj/structure/closet/crate/trashcart

/datum/supply_pack/imports/shells
	name = "Lethal Shotgun Shell Box Crate"
	desc = "Contains three boxes of buckshot shotgun shells. \
		Due to Nanotrasen's failure to secure exclusive manufacturing rights \
		during the Spinward Hunting and Shooting policy hearings, this import \
		is heavily taxed, despite being 'legal'. I hope the price tag is worth it."
	cost = CARGO_CRATE_VALUE * 10
	access = ACCESS_ARMORY
	access_view = ACCESS_ARMORY
	contains = list(
		/obj/item/storage/box/lethalshot = 3,
	)
	crate_name = "shotgun shell crate"
	crate_type = /obj/structure/closet/crate/secure/weapon

/datum/supply_pack/imports/error
	name = "NULL_ENTRY"
	desc = "(*!&@#OKAY, OPERATIVE, WE SEE HOW MUCH MONEY YOU'RE FLAUNTING. FINE. HAVE THIS, AND GOOD LUCK PUTTING IT TOGETHER!#@*$"
	cost = CARGO_CRATE_VALUE * 100
	hidden = TRUE
	contains = list(/obj/item/book/granter/crafting_recipe/regal_condor)

/datum/supply_pack/imports/mafia
	name = "Cosa Nostra Starter Pack"
	desc = "This crate contains everything you need to set up your own ethnicity-based racketeering operation."
	cost = CARGO_CRATE_VALUE * 4
	contains = list()
	contraband = TRUE

/datum/supply_pack/imports/mafia/fill(obj/structure/closet/crate/our_crate)
	for(var/items in 1 to 4)
		new /obj/effect/spawner/random/clothing/mafia_outfit(our_crate)
		new /obj/item/virgin_mary(our_crate)
		if(prob(30)) //Not all mafioso have mustaches, some people also find this item annoying.
			new /obj/item/clothing/mask/fakemoustache/italian(our_crate)
	if(prob(10)) //A little extra sugar every now and then to shake things up.
		new /obj/item/switchblade(our_crate)

/datum/supply_pack/imports/contraband
	name = "'Contraband' Crate"
	desc = "Psst.. bud... want some contraband? I can get you a poster, some nice cigs, dank, even some \
		sponsored items...you know, the good stuff. Just keep it away from the cops, kay?"
	contraband = TRUE
	cost = CARGO_CRATE_VALUE * 20
	contains = list(
		/obj/effect/spawner/random/contraband = 5,
	)
	crate_name = "crate"

/datum/supply_pack/imports/wt550
	name = "Smuggled WT-550 Autorifle Crate"
	desc = "(*!&@#GOOD NEWS, OPERATIVE! WE CAN'T GET YOU THE BIG LEAGUE AUTOMATIC WEAPONS. BUT, BY \
		SMUGGLING THIS CRATE THROUGH A FEW OUTDATED CUSTOMS CHECKPOINTS, WE'VE THE NEXT BEST THING! \
		SERVICE AUTORIFLES. DON'T WORRY, THE RUMORS ABOUT THE GUN MELTING YOU ARE JUST THAT! RUMORS! \
		THESE THINGS WORK FINE! MIGHT BE SLIGHTLY DIRTY.!#@*$"
	hidden = TRUE
	cost = CARGO_CRATE_VALUE * 7
	contains = list(
		/obj/item/gun/ballistic/automatic/wt550 = 2,
		/obj/item/ammo_box/magazine/wt550m9 = 2,
	)
	crate_type = /obj/structure/closet/crate/secure/syndicate/gorlex/weapons/bustedlock

/datum/supply_pack/imports/wt550ammo
	name = "Smuggled WT-550 Ammo Crate"
	desc = "(*!&@#OPERATIVE, YOU LIKE THAT WT-550? THEN WHY NOT EQUIP YOURSELF WITH SOME MORE AMMO!!#@*$"
	hidden = TRUE
	cost = CARGO_CRATE_VALUE * 4
	contains = list(
		/obj/item/ammo_box/magazine/wt550m9 = 2,
		/obj/item/ammo_box/magazine/wt550m9/wtap = 2,
		/obj/item/ammo_box/magazine/wt550m9/wtic = 2,
	)
	crate_name = "emergency crate"
	crate_type = /obj/structure/closet/crate/secure/syndicate/gorlex/weapons/bustedlock

/datum/supply_pack/imports/shocktrooper
	name = "Shocktrooper Crate"
	desc = "(*!&@#WANT TO PUT THE FEAR OF DEATH INTO YOUR ENEMIES? THIS CRATE OF GOODIES CAN HELP MAKE THAT A REALITY. \
		CONTAINS AN ARMOR VEST AND HELMET, A BOX OF FIVE EMP GRENADES, THREE SMOKEBOMBS, TWO GLUON GRENADES AND TWO FRAG GRENADES!#@*$"
	hidden = TRUE
	cost = CARGO_CRATE_VALUE * 10
	contains = list(
		/obj/item/storage/box/emps,
		/obj/item/grenade/smokebomb = 3,
		/obj/item/grenade/gluon = 2,
		/obj/item/grenade/frag = 2,
		/obj/item/clothing/suit/armor/vest,
		/obj/item/clothing/head/helmet,
	)
	crate_type = /obj/structure/closet/crate/secure/syndicate/gorlex/weapons/bustedlock

/datum/supply_pack/imports/specialops
	name = "Special Ops Crate"
	desc = "(*!&@#THE PIGS ON YOUR TAIL? MAYBE YOU CAN BUY SOME TIME WITH THIS CRATE! \
		CONTAINS A CHAMELEON MASK, BELT AND JUMPSUIT, MIRAGE GRENADES AND AN AGENT CARD! AND A KNIFE!!#@*$"
	hidden = TRUE
	cost = CARGO_CRATE_VALUE * 10
	contains = list(
		/obj/item/clothing/mask/chameleon,
		/obj/item/clothing/under/chameleon,
		/obj/item/storage/belt/chameleon,
		/obj/item/card/id/advanced/chameleon,
		/obj/item/switchblade,
		/obj/item/grenade/mirage = 5,
	)
	crate_type = /obj/structure/closet/crate/secure/syndicate/gorlex/weapons/bustedlock

/datum/supply_pack/imports/russian
	name = "Russian Surplus Military Gear Crate"
	desc = "Hello <;~insert appropriate greeting here: 'Comrade'|'Imperalist Scum'|'Quartermaster of Reputable Station'~;>, \
		we have the most modern russian military equipment the black market can offer, for the right price of course. \
		No lock, best price."
	contraband = TRUE
	cost = CARGO_CRATE_VALUE * 12
	contains = list(
		/obj/item/food/rationpack,
		/obj/item/ammo_box/strilka310,
		/obj/item/ammo_box/strilka310/surplus,
		/obj/effect/spawner/random/armory/strilka,
		/obj/item/gun_maintenance_supplies,
		/obj/item/clothing/suit/armor/vest/russian,
		/obj/item/clothing/head/helmet/rus_helmet,
		/obj/item/clothing/shoes/russian,
		/obj/item/clothing/gloves/tackler/combat,
		/obj/item/clothing/under/syndicate/rus_army,
		/obj/item/clothing/under/costume/soviet,
		/obj/item/clothing/mask/russian_balaclava,
		/obj/item/clothing/head/helmet/rus_ushanka,
		/obj/item/clothing/suit/armor/vest/russian_coat,
		/obj/item/storage/toolbox/guncase/soviet = 2,
	)
	discountable = SUPPLY_PACK_RARE_DISCOUNTABLE

/datum/supply_pack/imports/russian/fill(obj/structure/closet/crate/our_crate)
	for(var/items in 1 to 10)
		var/item = pick(contains)
		new item(our_crate)

/datum/supply_pack/imports/moistnuggets
	name = "Refurbished Sakhno Precision Rifle Crate"
	desc = "Hello Comrade Operative. You need gun? You hate garbage we sell to station normally? \
		Then we have the perfect weapon for you! Special price for good friends! \
		We don't have enough spare ammo, so you'll have to pick up the weapon of \
		dead comrade when you run out."
	hidden = TRUE
	cost = CARGO_CRATE_VALUE * 6
	contains = list(/obj/item/gun/ballistic/rifle/boltaction = 6)

/datum/supply_pack/imports/vehicle
	name = "Biker Gang Kit" //TUNNEL SNAKES OWN THIS TOWN
	desc = "TUNNEL SNAKES OWN THIS TOWN. Contains an unbranded All Terrain Vehicle, and a \
		complete gang outfit -- consists of black gloves, a menacing skull bandanna, and a SWEET leather overcoat!"
	cost = CARGO_CRATE_VALUE * 4
	contraband = TRUE
	contains = list(
		/obj/vehicle/ridden/atv,
		/obj/item/key/atv,
		/obj/item/clothing/suit/jacket/leather/biker,
		/obj/item/clothing/gloves/color/black,
		/obj/item/clothing/head/soft,
		/obj/item/clothing/mask/bandana/skull/black,
	)//so you can properly #cargoniabikergang
	crate_name = "biker kit"
	crate_type = /obj/structure/closet/crate/large

/datum/supply_pack/imports/abandoned
	name = "Abandoned Crate"
	desc = "...wait, how did this get here?"
	cost = CARGO_CRATE_VALUE * 50
	contains = list()
	crate_type = /obj/structure/closet/crate/secure/loot
	crate_name = "abandoned crate"
	contraband = TRUE
	dangerous = TRUE //these are literally bombs so....
	discountable = SUPPLY_PACK_RARE_DISCOUNTABLE

/datum/supply_pack/imports/shambler_evil
	name = "Shamber's Juice Eldritch Energy! Crate"
	desc = "~J'I'CE!~"
	cost = CARGO_CRATE_VALUE * 50
	contains = list(/obj/item/reagent_containers/cup/soda_cans/shamblers/eldritch = 1)
	crate_name = "illegal shambler's juice crate"
	contraband = TRUE

/datum/supply_pack/imports/hide
	name = "Animal Hide Crate"
	desc = "Want to not bother slaughtering a bunch of innocent creatures? Here, have some animal pelts! \
		Just don't ask where they came from..."
	cost = CARGO_CRATE_VALUE * 30
	contains = list(/obj/effect/spawner/random/animalhide = 5)
	crate_name = "animal hide crate"

/datum/supply_pack/imports/dreadnog
	name = "Dreadnog Carton Crate"
	desc = "I have eggnog and I must soda."
	cost = CARGO_CRATE_VALUE * 5
	contains = list(/obj/item/reagent_containers/cup/glass/bottle/juice/dreadnog = 3)
	crate_name = "dreadnog crate"

/datum/supply_pack/imports/giant_wrench_parts
	name = "Big Slappy parts"
	desc = "Illegal Big Slappy parts. The fastest and statistically most dangerous wrench."
	cost = CARGO_CRATE_VALUE * 22
	contraband = TRUE
	contains = list(/obj/item/weaponcrafting/giant_wrench)
	crate_name = "unknown parts crate"

/datum/supply_pack/imports/materials_market
	name = "Galactic Materials Market Crate"
	desc = "A circuit board to build your own materials market for use by certified market traders. Warning: Losses are not covered by insurance."
	cost = CARGO_CRATE_VALUE * 3
	contains = list(
		/obj/item/circuitboard/machine/materials_market = 1,
		/obj/item/stack/sheet/iron = 5,
		/obj/item/stack/cable_coil/five = 2,
		/obj/item/stock_parts/scanning_module = 1,
		/obj/item/stock_parts/card_reader = 1
	)
	crate_name = "materials market crate"
	crate_type = /obj/structure/closet/crate/cargo

/datum/supply_pack/imports/floortilecamo
	name = "Floor-tile Camouflage Uniform"
	desc = "Hey there, looking to surprise somebody? Spy? Steal? Then you're lucky, meet our newest \
		floor-tile 'NT SCUM' styled camouflage fatigues. This is the ultimate \
		espionage uniform used by the very best. Providing the best \
		flexibility, with our latest Camo-tech threads. Perfect for \
		risky espionage hallway operations. Enjoy our product!"
	contraband = TRUE
	cost = CARGO_CRATE_VALUE * 6
	contains = list(
		/obj/item/clothing/under/syndicate/floortilecamo = 3,
		/obj/item/clothing/mask/floortilebalaclava = 3,
		/obj/item/clothing/gloves/combat/floortile = 3,
		/obj/item/clothing/shoes/jackboots/floortile = 3,
		/obj/item/storage/backpack/floortile = 3
	)
	crate_name = "floortile camouflauge crate"
	crate_type = /obj/structure/closet/crate/secure/weapon

/**
 * The Long To Short Range Bluespace Teleporter, used to deliver (black) market purchases more effiiently
 * It can also be used to restock it, if you hit it with enough credits.
 */
/datum/supply_pack/imports/blackmarket_telepad
	name = "Black Market LTSRBT"
	desc = "Need a faster and better way of transporting your illegal goods from and to the \
		station? Fear not, the Long-To-Short-Range-Bluespace-Transceiver (LTSRBT for short) \
		is here to help. Contains a LTSRBT circuit, two bluespace crystals, and one ansible."
	cost = CARGO_CRATE_VALUE * 10
	contraband = TRUE
	contains = list(
		/obj/item/circuitboard/machine/ltsrbt,
		/obj/item/stack/ore/bluespace_crystal/artificial = 2,
		/obj/item/stock_parts/subspace/ansible,
	)
