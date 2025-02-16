/datum/crafting_recipe/improv_explosive
	name = "Improvised Explosive"
	result = /obj/item/grenade/iedcasing/spawned
	tool_behaviors = list(TOOL_WELDER, TOOL_SCREWDRIVER)
	reqs = list(
		/datum/reagent/fuel = 20,
		/obj/item/stack/cable_coil = 15,
		/obj/item/assembly/timer = 1,
		/obj/item/pipe = 1,
	)
	time = 6 SECONDS
	category = CAT_CHEMISTRY

/datum/crafting_recipe/molotov
	name = "Molotov"
	result = /obj/item/reagent_containers/cup/glass/bottle/molotov
	reqs = list(
		/obj/item/reagent_containers/cup/rag = 1,
		/obj/item/reagent_containers/cup/glass/bottle = 1,
	)
	time = 4 SECONDS
	category = CAT_CHEMISTRY

/datum/crafting_recipe/chemical_payload
	name = "Chemical Payload (C4)"
	result = /obj/item/bombcore/chemical
	reqs = list(
		/obj/item/stock_parts/matter_bin = 1,
		/obj/item/grenade/c4 = 1,
		/obj/item/grenade/chem_grenade = 2
	)
	time = 3 SECONDS
	category = CAT_CHEMISTRY

/datum/crafting_recipe/chemical_payload2
	name = "Chemical Payload (Gibtonite)"
	result = /obj/item/bombcore/chemical
	reqs = list(
		/obj/item/stock_parts/matter_bin = 1,
		/obj/item/gibtonite = 1,
		/obj/item/grenade/chem_grenade = 2,
	)
	time = 5 SECONDS
	category = CAT_CHEMISTRY

/datum/crafting_recipe/alcohol_burner
	name = "Burner (Ethanol)"
	result = /obj/item/burner
	time = 5 SECONDS
	reqs = list(
		/obj/item/reagent_containers/cup = 1,
		/datum/reagent/consumable/ethanol = 15,
		/obj/item/paper = 1,
	)
	category = CAT_CHEMISTRY

/datum/crafting_recipe/oil_burner
	name = "Burner (Oil)"
	result = /obj/item/burner/oil
	time = 5 SECONDS
	reqs = list(
		/obj/item/reagent_containers/cup = 1,
		/datum/reagent/fuel/oil = 15,
		/obj/item/paper = 1,
	)
	category = CAT_CHEMISTRY

/datum/crafting_recipe/fuel_burner
	name = "Burner (Fuel)"
	result = /obj/item/burner/fuel
	time = 5 SECONDS
	reqs = list(
		/obj/item/reagent_containers/cup = 1,
		/datum/reagent/fuel = 15,
		/obj/item/paper = 1,
	)
	category = CAT_CHEMISTRY

/datum/crafting_recipe/thermometer
	name = "Thermometer"
	tool_behaviors = list(TOOL_WELDER)
	result = /obj/item/thermometer
	time = 5 SECONDS
	reqs = list(
		/datum/reagent/mercury = 5,
		/obj/item/stack/sheet/glass = 1,
	)
	category = CAT_CHEMISTRY

/datum/crafting_recipe/thermometer_alt
	name = "Thermometer"
	result = /obj/item/thermometer/pen
	time = 5 SECONDS
	reqs = list(
		/datum/reagent/mercury = 5,
		/obj/item/pen = 1,
	)
	category = CAT_CHEMISTRY

/datum/crafting_recipe/ph_booklet
	name = "pH booklet"
	result = /obj/item/ph_booklet
	time = 5 SECONDS
	reqs = list(
		/datum/reagent/universal_indicator = 5,
		/obj/item/paper = 1,
	)
	category = CAT_CHEMISTRY

/datum/crafting_recipe/dropper //Maybe make a glass pipette icon?
	name = "Dropper"
	result = /obj/item/reagent_containers/dropper
	tool_behaviors = list(TOOL_WELDER)
	time = 5 SECONDS
	reqs = list(
		/obj/item/stack/sheet/glass = 1,
	)
	category = CAT_CHEMISTRY


/datum/crafting_recipe/chem_separator
	name = "chemical separator"
	result = /obj/structure/chem_separator
	tool_behaviors = list(TOOL_WELDER)
	time = 5 SECONDS
	reqs = list(
		/obj/item/stack/sheet/mineral/wood = 1,
		/obj/item/stack/sheet/glass = 1,
		/obj/item/burner = 1,
		/obj/item/thermometer = 1,
	)
	category = CAT_CHEMISTRY

/datum/crafting_recipe/improvised_chem_heater
	name = "Improvised chem heater"
	result = /obj/machinery/space_heater/improvised_chem_heater
	tool_behaviors = list(TOOL_SCREWDRIVER, TOOL_MULTITOOL, TOOL_WIRECUTTER)
	time = 15 SECONDS
	reqs = list(
		/obj/item/stack/cable_coil = 2,
		/obj/item/stack/sheet/glass = 2,
		/obj/item/stack/sheet/iron = 2,
		/datum/reagent/water = 50,
		/obj/item/thermometer = 1,
	)
	machinery = list(/obj/machinery/space_heater = CRAFTING_MACHINERY_CONSUME)
	category = CAT_CHEMISTRY

/datum/crafting_recipe/improvised_coolant
	name = "Improvised cooling spray"
	tool_behaviors = list(TOOL_SCREWDRIVER, TOOL_WIRECUTTER)
	result = /obj/item/extinguisher/crafted
	time = 10 SECONDS
	reqs = list(
		/obj/item/toy/crayon/spraycan = 1,
		/datum/reagent/water = 20,
		/datum/reagent/consumable/ice = 10,
	)
	category = CAT_CHEMISTRY
