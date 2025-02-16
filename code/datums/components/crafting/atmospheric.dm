/datum/crafting_recipe/bluespace_vendor_mount
	name = "Bluespace Vendor Wall Mount"
	result = /obj/item/wallframe/bluespace_vendor_mount
	time = 6 SECONDS
	reqs = list(
		/obj/item/stack/sheet/iron = 15,
		/obj/item/stack/sheet/glass = 10,
		/obj/item/stack/cable_coil = 10,
	)
	category = CAT_ATMOSPHERIC

/datum/crafting_recipe/pipe
	name = "Smart pipe fitting"
	tool_behaviors = list(TOOL_WRENCH)
	result = /obj/item/pipe/quaternary/pipe/crafted
	reqs = list(/obj/item/stack/sheet/iron = 1)
	time = 0.5 SECONDS
	category = CAT_ATMOSPHERIC

/datum/crafting_recipe/igniter
	name = "Igniter"
	result = /obj/machinery/igniter
	reqs = list(
		/obj/item/stack/sheet/iron = 5,
		/obj/item/assembly/igniter = 1,
	)
	blacklist = list(/obj/item/assembly/igniter/condenser)
	crafting_flags = CRAFT_CHECK_DENSITY | CRAFT_ONE_PER_TURF
	time = 2 SECONDS
	category = CAT_ATMOSPHERIC

/datum/crafting_recipe/air_sensor
	name = "Monitored Air Sensor"
	result = /obj/item/air_sensor
	reqs = list(
		/obj/item/analyzer = 1,
		/obj/item/stack/sheet/iron = 1,
		)
	blacklist = list(/obj/item/analyzer/ranged)

///abstract path for pipe crafting recipes that set the pipe_type of their results and have other checks as well
/datum/crafting_recipe/spec_pipe
	var/pipe_type

/datum/crafting_recipe/spec_pipe/check_requirements(mob/user, list/collected_requirements)
	return atmos_pipe_check(user, collected_requirements)

/datum/crafting_recipe/spec_pipe/layer_adapter
	name = "Layer manifold fitting"
	tool_behaviors = list(TOOL_WRENCH, TOOL_WELDER)
	result = /obj/item/pipe/binary/layer_adapter
	reqs = list(
		/obj/item/pipe = 1,
		/obj/item/stack/sheet/iron = 1,
	)
	time = 1 SECONDS
	category = CAT_ATMOSPHERIC
	pipe_type = /obj/machinery/atmospherics/pipe/layer_manifold

/datum/crafting_recipe/spec_pipe/color_adapter
	name = "Color adapter fitting"
	tool_behaviors = list(TOOL_WRENCH, TOOL_WELDER)
	result = /obj/item/pipe/binary/color_adapter
	reqs = list(
		/obj/item/pipe = 1,
		/obj/item/stack/sheet/iron = 1,
	)
	time = 1 SECONDS
	category = CAT_ATMOSPHERIC
	pipe_type = /obj/machinery/atmospherics/pipe/color_adapter

/datum/crafting_recipe/spec_pipe/he_pipe
	name = "H/E pipe fitting"
	tool_behaviors = list(TOOL_WRENCH, TOOL_WELDER)
	result = /obj/item/pipe/quaternary/he_pipe
	reqs = list(
		/obj/item/pipe = 1,
		/obj/item/stack/sheet/iron = 1,
	)
	time = 1 SECONDS
	category = CAT_ATMOSPHERIC
	pipe_type = /obj/machinery/atmospherics/pipe/heat_exchanging/manifold4w

/datum/crafting_recipe/spec_pipe/he_junction
	name = "H/E junction fitting"
	tool_behaviors = list(TOOL_WRENCH, TOOL_WELDER)
	result = /obj/item/pipe/directional/he_junction
	reqs = list(
		/obj/item/pipe = 1,
		/obj/item/stack/sheet/iron = 1,
	)
	time = 1 SECONDS
	category = CAT_ATMOSPHERIC
	pipe_type = /obj/machinery/atmospherics/pipe/heat_exchanging/junction

/datum/crafting_recipe/spec_pipe/pressure_pump
	name = "Pressure pump fitting"
	tool_behaviors = list(TOOL_WRENCH, TOOL_WELDER)
	result = /obj/item/pipe/binary/pressure_pump
	reqs = list(
		/obj/item/pipe = 1,
		/obj/item/stack/sheet/iron = 5,
		/obj/item/stack/cable_coil = 5,
	)
	time = 2 SECONDS
	category = CAT_ATMOSPHERIC
	pipe_type = /obj/machinery/atmospherics/components/binary/pump

/datum/crafting_recipe/spec_pipe/manual_valve
	name = "Manual valve fitting"
	tool_behaviors = list(TOOL_WRENCH, TOOL_WELDER)
	result = /obj/item/pipe/binary/manual_valve
	reqs = list(
		/obj/item/pipe = 1,
		/obj/item/stack/sheet/iron = 1,
	)
	time = 2 SECONDS
	category = CAT_ATMOSPHERIC
	pipe_type = /obj/machinery/atmospherics/components/binary/valve

/datum/crafting_recipe/spec_pipe/vent
	name = "Vent pump fitting"
	tool_behaviors = list(TOOL_WRENCH, TOOL_WELDER)
	result = /obj/item/pipe/directional/vent
	reqs = list(
		/obj/item/pipe = 1,
		/obj/item/stack/sheet/iron = 5,
		/obj/item/stack/cable_coil = 5,
	)
	time = 2 SECONDS
	category = CAT_ATMOSPHERIC
	pipe_type = /obj/machinery/atmospherics/components/unary/vent_pump

/datum/crafting_recipe/spec_pipe/scrubber
	name = "Scrubber fitting"
	tool_behaviors = list(TOOL_WRENCH, TOOL_WELDER)
	result = /obj/item/pipe/directional/scrubber
	reqs = list(
		/obj/item/pipe = 1,
		/obj/item/stack/sheet/iron = 5,
		/obj/item/stack/cable_coil = 5,
	)
	time = 2 SECONDS
	category = CAT_ATMOSPHERIC
	pipe_type = /obj/machinery/atmospherics/components/unary/vent_scrubber

/datum/crafting_recipe/spec_pipe/filter
	name = "Filter fitting"
	tool_behaviors = list(TOOL_WRENCH, TOOL_WELDER)
	result = /obj/item/pipe/trinary/flippable/filter
	reqs = list(
		/obj/item/pipe = 1,
		/obj/item/stack/sheet/iron = 5,
		/obj/item/stack/cable_coil = 5,
	)
	time = 2 SECONDS
	category = CAT_ATMOSPHERIC
	pipe_type = /obj/machinery/atmospherics/components/trinary/filter

/datum/crafting_recipe/spec_pipe/mixer
	name = "Mixer fitting"
	tool_behaviors = list(TOOL_WRENCH, TOOL_WELDER)
	result = /obj/item/pipe/trinary/flippable/mixer
	reqs = list(
		/obj/item/pipe = 1,
		/obj/item/stack/sheet/iron = 5,
		/obj/item/stack/cable_coil = 5,
	)
	time = 2 SECONDS
	category = CAT_ATMOSPHERIC
	pipe_type = /obj/machinery/atmospherics/components/trinary/mixer

/datum/crafting_recipe/spec_pipe/connector
	name = "Portable connector fitting"
	tool_behaviors = list(TOOL_WRENCH, TOOL_WELDER)
	result = /obj/item/pipe/directional/connector
	reqs = list(
		/obj/item/pipe = 1,
		/obj/item/stack/sheet/iron = 1,
	)
	time = 2 SECONDS
	category = CAT_ATMOSPHERIC
	pipe_type = /obj/machinery/atmospherics/components/unary/portables_connector

/datum/crafting_recipe/spec_pipe/passive_vent
	name = "Passive vent fitting"
	tool_behaviors = list(TOOL_WRENCH, TOOL_WELDER)
	result = /obj/item/pipe/directional/passive_vent
	reqs = list(
		/obj/item/pipe = 1,
		/obj/item/stack/sheet/iron = 1,
	)
	time = 2 SECONDS
	category = CAT_ATMOSPHERIC
	pipe_type = /obj/machinery/atmospherics/components/unary/passive_vent

/datum/crafting_recipe/spec_pipe/injector
	name = "Outlet injector fitting"
	tool_behaviors = list(TOOL_WRENCH, TOOL_WELDER)
	result = /obj/item/pipe/directional/injector
	reqs = list(
		/obj/item/pipe = 1,
		/obj/item/stack/sheet/iron = 1,
		/obj/item/stack/cable_coil = 5,
	)
	time = 2 SECONDS
	category = CAT_ATMOSPHERIC
	pipe_type = /obj/machinery/atmospherics/components/unary/outlet_injector

/datum/crafting_recipe/spec_pipe/he_exchanger
	name = "Heat exchanger fitting"
	tool_behaviors = list(TOOL_WRENCH, TOOL_WELDER)
	result = /obj/item/pipe/directional/he_exchanger
	reqs = list(
		/obj/item/pipe = 1,
		/obj/item/stack/sheet/plasteel = 1,
	)
	time = 2 SECONDS
	category = CAT_ATMOSPHERIC
	pipe_type = /obj/machinery/atmospherics/components/unary/heat_exchanger

/datum/crafting_recipe/steam_vent
	name = "Steam Vent"
	result = /obj/structure/steam_vent
	time = 0.8 SECONDS
	reqs = list(
		/obj/item/stack/sheet/iron = 2,
		/obj/item/stack/tile/iron = 1,
		/obj/item/stock_parts/water_recycler = 1,
	)
	category = CAT_ATMOSPHERIC

/datum/crafting_recipe/elder_atmosian_statue
	name = "Elder Atmosian Statue"
	result = /obj/structure/statue/elder_atmosian
	time = 6 SECONDS
	reqs = list(
		/obj/item/stack/sheet/mineral/metal_hydrogen = 20,
		/obj/item/stack/sheet/mineral/zaukerite = 15,
		/obj/item/stack/sheet/iron = 30,
	)
	category = CAT_STRUCTURE

/datum/crafting_recipe/spec_pipe/airlock_pump
	name = "External Airlock Pump"
	tool_behaviors = list(TOOL_WRENCH, TOOL_WELDER)
	result = /obj/item/pipe/directional/airlock_pump
	reqs = list(
		/obj/item/pipe = 1,
		/obj/item/stack/sheet/iron = 5,
		/obj/item/stack/cable_coil = 5,
		/obj/item/analyzer = 1,
	)
	time = 2 SECONDS
	category = CAT_ATMOSPHERIC
	pipe_type = /obj/machinery/atmospherics/components/unary/airlock_pump
