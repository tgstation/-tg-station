/datum/crafting_recipe/ed209
	name = "ED209"
	result = /mob/living/simple_animal/bot/secbot/ed209
	reqs = list(
		/obj/item/robot_suit = 1,
		/obj/item/clothing/head/helmet/sec = 1,
		/obj/item/clothing/suit/armor/vest = 1,
		/obj/item/bodypart/leg/left/robot = 1,
		/obj/item/bodypart/leg/right/robot = 1,
		/obj/item/stack/sheet/iron = 1,
		/obj/item/stack/cable_coil = 1,
		/obj/item/gun/energy/disabler = 1,
		/obj/item/assembly/prox_sensor = 1,
	)
	tool_behaviors = list(TOOL_WELDER, TOOL_SCREWDRIVER)
	time = 6 SECONDS
	category = CAT_ROBOT

/datum/crafting_recipe/secbot
	name = "Secbot"
	result = /mob/living/simple_animal/bot/secbot
	reqs = list(
		/obj/item/assembly/signaler = 1,
		/obj/item/clothing/head/helmet/sec = 1,
		/obj/item/melee/baton/security/ = 1,
		/obj/item/assembly/prox_sensor = 1,
		/obj/item/bodypart/arm/right/robot = 1,
	)
	tool_behaviors = list(TOOL_WELDER)
	time = 6 SECONDS
	category = CAT_ROBOT

/datum/crafting_recipe/cleanbot
	name = "Cleanbot"
	result = /mob/living/basic/bot/cleanbot
	reqs = list(
		/obj/item/reagent_containers/cup/bucket = 1,
		/obj/item/assembly/prox_sensor = 1,
		/obj/item/bodypart/arm/right/robot = 1,
	)
	parts = list(/obj/item/reagent_containers/cup/bucket = 1) //cleanbot/Entered() handles bucket colors
	time = 4 SECONDS
	category = CAT_ROBOT

/datum/crafting_recipe/repairbot
	name = "Repairbot"
	result = /mob/living/basic/bot/repairbot
	reqs = list(
		/obj/item/storage/toolbox = 1,
		/obj/item/stack/conveyor = 1,
		/obj/item/assembly/prox_sensor = 1,
		/obj/item/bodypart/arm/right/robot = 1,
	)
	time = 4 SECONDS
	category = CAT_ROBOT

/datum/crafting_recipe/medbot
	name = "Medbot"
	result = /mob/living/basic/bot/medbot
	reqs = list(
		/obj/item/healthanalyzer = 1,
		/obj/item/storage/medkit = 1,
		/obj/item/assembly/prox_sensor = 1,
		/obj/item/bodypart/arm/right/robot = 1,
	)
	parts = list(
		/obj/item/storage/medkit = 1,
		/obj/item/healthanalyzer = 1,
	)
	time = 4 SECONDS
	category = CAT_ROBOT

/datum/crafting_recipe/honkbot
	name = "Honkbot"
	result = /mob/living/basic/bot/honkbot
	reqs = list(
		/obj/item/storage/box/clown = 1,
		/obj/item/bodypart/arm/right/robot = 1,
		/obj/item/assembly/prox_sensor = 1,
		/obj/item/bikehorn = 1,
	)
	time = 4 SECONDS
	category = CAT_ROBOT

/datum/crafting_recipe/firebot
	name = "Firebot"
	result = /mob/living/basic/bot/firebot
	reqs = list(
		/obj/item/extinguisher = 1,
		/obj/item/bodypart/arm/right/robot = 1,
		/obj/item/assembly/prox_sensor = 1,
		/obj/item/clothing/head/utility/hardhat/red = 1,
	)
	time = 4 SECONDS
	category = CAT_ROBOT

/datum/crafting_recipe/vibebot
	name = "Vibebot"
	result = /mob/living/basic/bot/vibebot
	reqs = list(
		/obj/item/light/bulb = 2,
		/obj/item/bodypart/head/robot = 1,
		/obj/item/assembly/prox_sensor = 1,
		/obj/item/toy/crayon = 1,
	)
	time = 4 SECONDS
	category = CAT_ROBOT

/datum/crafting_recipe/hygienebot
	name = "Hygienebot"
	result = /mob/living/basic/bot/hygienebot
	reqs = list(
		/obj/item/bot_assembly/hygienebot = 1,
		/obj/item/stack/ducts = 1,
		/obj/item/assembly/prox_sensor = 1,
	)
	tool_behaviors = list(TOOL_WELDER)
	time = 4 SECONDS
	category = CAT_ROBOT

/datum/crafting_recipe/vim
	name = "Vim"
	result = /obj/vehicle/sealed/car/vim
	reqs = list(
		/obj/item/clothing/head/helmet/space/eva = 1,
		/obj/item/bodypart/leg/left/robot = 1,
		/obj/item/bodypart/leg/right/robot = 1,
		/obj/item/flashlight = 1,
		/obj/item/assembly/voice = 1,
	)
	tool_behaviors = list(TOOL_SCREWDRIVER)
	time = 6 SECONDS //Has a four second do_after when building manually
	category = CAT_ROBOT

/datum/crafting_recipe/aitater
	name = "intelliTater"
	result = /obj/item/aicard/aitater
	time = 3 SECONDS
	tool_behaviors = list(TOOL_WIRECUTTER)
	reqs = list(
		/obj/item/aicard = 1,
		/obj/item/food/grown/potato = 1,
		/obj/item/stack/cable_coil = 5,
	)
	category = CAT_ROBOT

/datum/crafting_recipe/aitater/aispook
	name = "intelliLantern"
	result = /obj/item/aicard/aispook
	reqs = list(
		/obj/item/aicard = 1,
		/obj/item/food/grown/pumpkin = 1,
		/obj/item/stack/cable_coil = 5,
	)

/datum/crafting_recipe/mod_core_standard
	name = "MOD core (Standard)"
	result = /obj/item/mod/core/standard
	tool_behaviors = list(TOOL_SCREWDRIVER)
	time = 10 SECONDS
	reqs = list(
		/obj/item/stack/cable_coil = 5,
		/obj/item/stack/rods = 2,
		/obj/item/stack/sheet/glass = 1,
		/obj/item/organ/heart/ethereal = 1,
	)
	category = CAT_ROBOT

/datum/crafting_recipe/mod_core_ethereal
	name = "MOD core (Ethereal)"
	result = /obj/item/mod/core/ethereal
	tool_behaviors = list(TOOL_SCREWDRIVER)
	time = 10 SECONDS
	reqs = list(
		/datum/reagent/consumable/liquidelectricity = 5,
		/obj/item/stack/cable_coil = 5,
		/obj/item/stack/rods = 2,
		/obj/item/stack/sheet/glass = 1,
		/obj/item/reagent_containers/syringe = 1,
	)
	category = CAT_ROBOT
