
/datum/supply_pack/goody
	access = NONE
	group = "Goodies"
	goody = TRUE
	discountable = SUPPLY_PACK_STD_DISCOUNTABLE

/datum/supply_pack/goody/clear_pda
	name = "Mint Condition Nanotrasen Clear PDA"
	desc = "Mint condition, freshly repackaged! A valuable collector's item normally valued at over 2.5 million credits, now available for a steal!"
	cost = 100000
	contains = list(/obj/item/modular_computer/pda/clear)

/datum/supply_pack/goody/dumdum38
	name = ".38 DumDum Speedloader Single-Pack"
	desc = "Contains one speedloader of .38 DumDum ammunition, good for embedding in soft targets."
	cost = PAYCHECK_CREW * 2
	access_view = ACCESS_WEAPONS
	contains = list(/obj/item/ammo_box/c38/dumdum)

/datum/supply_pack/goody/match38
	name = ".38 Match Grade Speedloader Single-Pack"
	desc = "Contains one speedloader of match grade .38 ammunition, perfect for showing off trickshots."
	cost = PAYCHECK_CREW * 2
	access_view = ACCESS_WEAPONS
	contains = list(/obj/item/ammo_box/c38/match)

/datum/supply_pack/goody/rubber
	name = ".38 Rubber Speedloader Single-Pack"
	desc = "Contains one speedloader of bouncy rubber .38 ammunition, for when you want to bounce your shots off anything and everything."
	cost = PAYCHECK_CREW * 1.5
	access_view = ACCESS_WEAPONS
	contains = list(/obj/item/ammo_box/c38/match/bouncy)

/datum/supply_pack/goody/dumdum38br
	name = ".38 DumDum Magazine Single-Pack"
	desc = "Contains one magazine of .38 DumDum ammunition, good for embedding in soft targets."
	cost = PAYCHECK_CREW * 2
	access_view = ACCESS_WEAPONS
	contains = list(/obj/item/ammo_box/magazine/m38/dumdum)

/datum/supply_pack/goody/match38br
	name = ".38 Match Grade Magazine Single-Pack"
	desc = "Contains one magazine of match grade .38 ammunition, perfect for showing off trickshots."
	cost = PAYCHECK_CREW * 2
	access_view = ACCESS_WEAPONS
	contains = list(/obj/item/ammo_box/magazine/m38/match)

/datum/supply_pack/goody/rubber
	name = ".38 Rubber Magazine Single-Pack"
	desc = "Contains one magazine of bouncy rubber .38 ammunition, for when you want to bounce your shots off anything and everything."
	cost = PAYCHECK_CREW * 1.5
	access_view = ACCESS_WEAPONS
	contains = list(/obj/item/ammo_box/magazine/m38/match/bouncy)

/datum/supply_pack/goody/mars_single
	name = "Colt Detective Special Single-Pack"
	desc = "The HoS took your gun and your badge? No problem! Just pay the absurd taxation fee and you too can be reunited with the lethal power of a .38!"
	cost = PAYCHECK_CREW * 40 //they really mean a premium here
	access_view = ACCESS_WEAPONS
	contains = list(/obj/item/gun/ballistic/revolver/c38/detective)

/datum/supply_pack/goody/stingbang
	name = "Stingbang Single-Pack"
	desc = "Contains one \"Stingbang\" grenade, perfect for playing meanhearted pranks."
	cost = PAYCHECK_COMMAND * 2.5
	access_view = ACCESS_WEAPONS
	contains = list(/obj/item/grenade/stingbang)

/datum/supply_pack/goody/Survivalknives_single
	name = "Survival Knife Single-Pack"
	desc = "Contains one sharpened survival knife. Guaranteed to fit snugly inside any Nanotrasen-standard boot."
	cost = PAYCHECK_COMMAND * 1.75
	contains = list(/obj/item/knife/combat/survival)

/datum/supply_pack/goody/ballistic_single
	name = "Combat Shotgun Single-Pack"
	desc = "For when the enemy absolutely needs to be replaced with lead. Contains one Aussec-designed Combat Shotgun, and one Shotgun Bandolier."
	cost = PAYCHECK_COMMAND * 15
	access_view = ACCESS_ARMORY
	contains = list(
		/obj/item/gun/ballistic/shotgun/automatic/combat,
		/obj/item/storage/belt/bandolier
	)

/datum/supply_pack/goody/disabler_single
	name = "Disabler Single-Pack"
	desc = "Contains one disabler, the non-lethal workhorse of Nanotrasen security everywhere. Comes in an energy holster, just in case you happen to have an extra disabler."
	cost = PAYCHECK_COMMAND * 3
	access_view = ACCESS_WEAPONS
	contains = list(/obj/item/storage/belt/holster/energy/disabler)

/datum/supply_pack/goody/energy_single
	name = "Energy Gun Single-Pack"
	desc = "Contains one energy gun, capable of firing both non-lethal and lethal blasts of light."
	cost = PAYCHECK_COMMAND * 12
	access_view = ACCESS_WEAPONS
	contains = list(/obj/item/gun/energy/e_gun)

/datum/supply_pack/goody/laser_single
	name = "Laser Gun Single-Pack"
	desc = "Contains one laser gun, the lethal workhorse of Nanotrasen security everywhere."
	cost = PAYCHECK_COMMAND * 6
	access_view = ACCESS_WEAPONS
	contains = list(/obj/item/gun/energy/laser)

/datum/supply_pack/goody/hell_single
	name = "Hellgun Kit Single-Pack"
	desc = "Contains one hellgun degradation kit, an old pattern of laser gun infamous for its ability to horribly disfigure targets with burns. Technically violates the Space Geneva Convention when used on humanoids."
	cost = PAYCHECK_CREW * 2
	access_view = ACCESS_WEAPONS
	contains = list(/obj/item/weaponcrafting/gunkit/hellgun)

/datum/supply_pack/goody/thermal_single
	name = "Thermal Pistol Holster Single-Pack"
	desc = "Contains twinned thermal pistols in a holster, ready for use in the field."
	cost = PAYCHECK_COMMAND * 15
	access_view = ACCESS_WEAPONS
	contains = list(/obj/item/storage/belt/holster/energy/thermal)

/datum/supply_pack/goody/sologamermitts
	name = "Insulated Gloves Single-Pack"
	desc = "The backbone of modern society. Barely ever ordered for actual engineering."
	cost = PAYCHECK_CREW * 8
	contains = list(/obj/item/clothing/gloves/color/yellow)

/datum/supply_pack/goody/gorilla_single
	name = "Gorilla Gloves Single-Pack"
	desc = "A spare pair of gorilla gloves. Better for tackles than grippers from the security vendor."
	cost = PAYCHECK_COMMAND * 6
	contains = list(/obj/item/clothing/gloves/tackler/combat)

/datum/supply_pack/goody/firstaidbruises_single
	name = "Bruise Treatment Kit Single-Pack"
	desc = "A single brute medkit, perfect for recovering from being crushed in an airlock. Did you know people get crushed in airlocks all the time? Interesting..."
	cost = PAYCHECK_CREW * 4
	contains = list(/obj/item/storage/medkit/brute)

/datum/supply_pack/goody/firstaidburns_single
	name = "Burn Treatment Kit Single-Pack"
	desc = "A single burn medkit. The advertisement displays a winking atmospheric technician giving a thumbs up, saying \"Mistakes happen!\""
	cost = PAYCHECK_CREW * 4
	contains = list(/obj/item/storage/medkit/fire)

/datum/supply_pack/goody/firstaid_single
	name = "First Aid Kit Single-Pack"
	desc = "A single medkit, fit for healing most types of bodily harm."
	cost = PAYCHECK_CREW * 3
	contains = list(/obj/item/storage/medkit/regular)

/datum/supply_pack/goody/firstaidoxygen_single
	name = "Oxygen Deprivation Kit Single-Pack"
	desc = "A single oxygen deprivation medkit, marketed heavily to those with crippling fears of asphyxiation."
	cost = PAYCHECK_CREW * 4
	contains = list(/obj/item/storage/medkit/o2)

/datum/supply_pack/goody/firstaidtoxins_single
	name = "Toxin Treatment Kit Single-Pack"
	desc = "A single first aid kit focused on healing damage dealt by heavy toxins."
	cost = PAYCHECK_CREW * 4
	contains = list(/obj/item/storage/medkit/toxin)

/datum/supply_pack/goody/bandagebox_singlepack
	name = "Box of Bandages Single-Pack"
	desc = "A single box of DeForest brand bandages. For when you don't want to see your doctor."
	cost = PAYCHECK_CREW * 3
	contains = list(/obj/item/storage/box/bandages)

/datum/supply_pack/goody/toolbox // mostly just to water down coupon probability
	name = "Mechanical Toolbox"
	desc = "A fully stocked mechanical toolbox, for when you're too lazy to just print them out."
	cost = PAYCHECK_CREW * 3
	contains = list(/obj/item/storage/toolbox/mechanical)

/datum/supply_pack/goody/valentine
	name = "Valentine Card"
	desc = "Make an impression on that special someone! Comes with one valentine card and a free candy heart!"
	cost = PAYCHECK_CREW * 2
	contains = list(/obj/item/paper/valentine, /obj/item/food/candyheart)

/datum/supply_pack/goody/beeplush
	name = "Bee Plushie"
	desc = "The most important thing you could possibly spend your hard-earned money on."
	cost = PAYCHECK_CREW * 4
	contains = list(/obj/item/toy/plush/beeplushie)

/datum/supply_pack/goody/blahaj
	name = "Shark Plushie"
	desc = "A soft, warm companion for midday naps."
	cost = PAYCHECK_CREW * 5
	contains = list(/obj/item/toy/plush/shark)

/datum/supply_pack/goody/dog_bone
	name = "Jumbo Dog Bone"
	desc = "The best dog bone money can have exported to a space station. A perfect gift for a dog."
	cost = PAYCHECK_COMMAND * 4
	contains = list(/obj/item/dog_bone)

/datum/supply_pack/goody/dyespray
	name = "Hair Dye Spray"
	desc = "A cool spray to dye your hair with awesome colors!"
	cost = PAYCHECK_CREW * 2
	contains = list(/obj/item/dyespray)

/datum/supply_pack/goody/beach_ball
	name = "Beach Ball Single-Pack"
	// uses desc from item
	cost = PAYCHECK_CREW
	contains = list(/obj/item/toy/beach_ball/branded)

/datum/supply_pack/goody/beach_ball/New()
	..()
	var/obj/item/toy/beach_ball/branded/beachball_type = /obj/item/toy/beach_ball/branded
	desc = initial(beachball_type.desc)

/datum/supply_pack/goody/medipen_twopak
	name = "Medipen Two-Pak"
	desc = "Contains one standard epinephrine medipen and one standard emergency medkit medipen. For when you want to prepare for the worst."
	cost = PAYCHECK_CREW * 2
	contains = list(
		/obj/item/reagent_containers/hypospray/medipen,
		/obj/item/reagent_containers/hypospray/medipen/ekit
	)

/datum/supply_pack/goody/mothic_rations
	name = "Surplus Mothic Ration Pack"
	desc = "A single surplus ration pack from the Mothic Fleet. Comes with 3 random sustenance bars, and a package of Activin chewing gum."
	cost = PAYCHECK_COMMAND * 2
	contains = list(/obj/item/storage/box/mothic_rations)

/datum/supply_pack/goody/ready_donk
	name = "Ready-Donk Single Meal"
	desc = "A complete meal package for the terminally lazy. Contains one Ready-Donk meal."
	cost = PAYCHECK_CREW * 2
	contains = list(/obj/item/food/ready_donk)

/datum/supply_pack/goody/pill_mutadone
	name = "Emergency Mutadone Pill Single-Pack"
	desc = "A single pill for curing genetic defects. Useful for when you can't procure one from medbay."
	cost = PAYCHECK_CREW * 2.5
	contains = list(/obj/item/reagent_containers/pill/mutadone)

/datum/supply_pack/goody/rapid_lighting_device
	name = "Rapid Lighting Device (RLD) Single-Pack"
	desc = "A device used to rapidly provide lighting sources to an area. Reload with iron, plasteel, glass or compressed matter cartridges."
	cost = PAYCHECK_CREW * 10
	contains = list(/obj/item/construction/rld)

/datum/supply_pack/goody/fishing_toolbox
	name = "Fishing Toolbox"
	desc = "Complete toolbox set for your fishing adventure. Contains a valuable tip. Advanced hooks and lines sold separately."
	cost = PAYCHECK_CREW * 2
	contains = list(/obj/item/storage/toolbox/fishing)

/datum/supply_pack/goody/fishing_hook_set
	name = "Fishing Hooks Set"
	desc = "Set of various fishing hooks."
	cost = PAYCHECK_CREW
	contains = list(/obj/item/storage/box/fishing_hooks)

/datum/supply_pack/goody/fishing_line_set
	name = "Fishing Lines Set"
	desc = "Set of various fishing lines."
	cost = PAYCHECK_CREW
	contains = list(/obj/item/storage/box/fishing_lines)

/datum/supply_pack/goody/fishing_lure_set
	name = "Fishing Lures Set"
	desc = "A set of bite-resistant fishing lures to fish all (most) sort of fish. Beat randomness to a curb today!"
	cost = PAYCHECK_CREW * 8
	contains = list(/obj/item/storage/box/fishing_lures)

/datum/supply_pack/goody/fishing_hook_rescue
	name = "Rescue Fishing Hook Single-Pack"
	desc = "For when your fellow miner has inevitably fallen into a chasm, and it's up to you to save them."
	cost = PAYCHECK_CREW * 12
	contains = list(/obj/item/fishing_hook/rescue)

/datum/supply_pack/goody/premium_bait
	name = "Deluxe Fishing Bait Single-Pack"
	desc = "When the standard variety is not good enough for you."
	cost = PAYCHECK_CREW
	contains = list(/obj/item/bait_can/worm/premium)

/datum/supply_pack/goody/fish_feed
	name = "Can of Fish Food Single-Pack"
	desc = "For keeping your little friends fed and alive."
	cost = PAYCHECK_CREW
	contains = list(/obj/item/reagent_containers/cup/fish_feed)

/datum/supply_pack/goody/naturalbait
	name = "Freshness Jars full of Natural Bait Single-Pack"
	desc = "Homemade in the Spinward Sector."
	cost = PAYCHECK_CREW * 4 //rock on
	contains = list(/obj/item/storage/pill_bottle/naturalbait)

/datum/supply_pack/goody/telescopic_fishing_rod
	name = "Telescopic Fishing Rod Single-Pack"
	desc = "A collapsible fishing rod that can fit within a backpack."
	cost = PAYCHECK_CREW * 8
	contains = list(/obj/item/fishing_rod/telescopic)

/datum/supply_pack/goody/fish_analyzer
	name = "Fish Analyzer Single-Pack"
	desc = "A single analyzer to monitor fish's status and traits with, in case you don't have the technology to print one."
	cost = PAYCHECK_CREW * 2.5
	contains = list(/obj/item/fish_analyzer)

/datum/supply_pack/goody/fish_catalog
	name = "Fishing Catalog Single-Pack"
	desc = "A catalog containing all the fishy info you'll ever need."
	cost = PAYCHECK_LOWER
	contains = list(/obj/item/book/manual/fish_catalog)

/datum/supply_pack/goody/coffee_mug
	name = "Coffee Mug Single-Pack"
	desc = "A bog standard coffee mug, for drinking coffee."
	cost = PAYCHECK_LOWER
	contains = list(/obj/item/reagent_containers/cup/glass/mug)

/datum/supply_pack/goody/nt_mug
	name = "Nanotrasen Coffee Mug Single-Pack"
	desc = "A blue mug bearing the logo of your corporate masters. Usually given out at inductions or events, we'll send one out special for a nominal fee."
	cost = PAYCHECK_LOWER
	contains = list(/obj/item/reagent_containers/cup/glass/mug/nanotrasen)

/datum/supply_pack/goody/coffee_cartridge
	name = "Coffee Cartridge Single-Pack"
	desc = "A basic cartridge for a coffeemaker. Makes 4 pots."
	cost = PAYCHECK_LOWER
	contains = list(/obj/item/coffee_cartridge)

/datum/supply_pack/goody/coffee_cartridge_fancy
	name = "Fancy Coffee Cartridge Single-Pack"
	desc = "A fancy cartridge for a coffeemaker. Makes 4 pots."
	cost = PAYCHECK_CREW
	contains = list(/obj/item/coffee_cartridge/fancy)

/datum/supply_pack/goody/coffeepot
	name = "Coffeepot Single-Pack"
	desc = "A standard-sized coffeepot, for use with a coffeemaker."
	cost = PAYCHECK_CREW
	contains = list(/obj/item/reagent_containers/cup/coffeepot)

/datum/supply_pack/goody/climbing_hook
	name = "Climbing Hook Single-Pack"
	desc = "A less cheap imported climbing hook. Absolutely no use outside of multi-floor stations."
	cost = PAYCHECK_CREW * 5
	contains = list(/obj/item/climbing_hook)

/datum/supply_pack/goody/double_barrel
	name = "Double-barreled Shotgun Single-Pack"
	desc = "Lost your beloved bunny to a demonic invasion? Clown broke in and stole your beloved gun? No worries! Get a new gun as long as you can pay the absurd fees."
	cost = PAYCHECK_COMMAND * 18
	access_view = ACCESS_WEAPONS
	contains = list(/obj/item/gun/ballistic/shotgun/doublebarrel)

/datum/supply_pack/goody/experimental_medication
	name = "Experimental Medication Single-Pack"
	desc = "A single bottle of Interdyne brand experimental medication, used for treating people suffering from hereditary manifold disease."
	cost = PAYCHECK_CREW * 6.5
	contains = list(/obj/item/storage/pill_bottle/sansufentanyl)

/datum/supply_pack/goody/pet_mouse
	name = "Pet Mouse"
	desc = "Many people consider mice to be vermin, or dirty lab animals for experimentation, or a culinary delicacy. That's why we're not asking any questions, here."
	cost = PAYCHECK_CREW * 1.5
	contains = list(/obj/item/pet_carrier/small/mouse)

/datum/supply_pack/goody/shuttle_construction_kit
	name = "Shuttle Construction Starter Kit"
	desc = "Contains a set of shuttle blueprints, and the circuitboards necessary for constructing your own shuttle. \
			Well at least the ones you can't source yourself without Science's help."
	cost = PAYCHECK_COMMAND * 12 //You assistants with shipwrighting ambitions can do a couple bounties, can't you?
	access_view = ACCESS_AUX_BASE //Engineers have it, QM can give it to whoever, and scientists can just research the tech.
	contains = list(
		/obj/item/shuttle_blueprints,
		/obj/item/circuitboard/computer/shuttle/flight_control,
		/obj/item/circuitboard/computer/shuttle/docker,
		/obj/item/circuitboard/machine/engine/propulsion = 2,
	)
