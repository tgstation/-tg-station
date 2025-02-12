/datum/supply_pack/engineering
	group = "Engineering"
	crate_type = /obj/structure/closet/crate/engineering

/datum/supply_pack/engineering/shieldgen
	name = "Anti-breach Shield Projector Crate"
	desc = "Hull breaches again? Say no more with the Nanotrasen Anti-Breach Shield Projector! \
		Uses forcefield technology to keep the air in, and the space out. Contains two shield projectors."
	cost = CARGO_CRATE_VALUE * 3
	access_view = ACCESS_ENGINE_EQUIP
	contains = list(/obj/machinery/shieldgen = 2)
	crate_name = "anti-breach shield projector crate"

/datum/supply_pack/engineering/ripley
	name = "APLU MK-I Crate"
	desc = "A do-it-yourself kit for building an ALPU MK-I \"Ripley\", designed for lifting, \
		carrying heavy equipment, and other station tasks. Batteries not included."
	cost = CARGO_CRATE_VALUE * 10
	access_view = ACCESS_ROBOTICS
	contains = list(/obj/item/mecha_parts/chassis/ripley,
					/obj/item/mecha_parts/part/ripley_torso,
					/obj/item/mecha_parts/part/ripley_right_arm,
					/obj/item/mecha_parts/part/ripley_left_arm,
					/obj/item/mecha_parts/part/ripley_right_leg,
					/obj/item/mecha_parts/part/ripley_left_leg,
					/obj/item/stock_parts/capacitor,
					/obj/item/stock_parts/scanning_module,
					/obj/item/stock_parts/servo,
					/obj/item/circuitboard/mecha/ripley/main,
					/obj/item/circuitboard/mecha/ripley/peripherals,
					/obj/item/mecha_parts/mecha_equipment/drill,
					/obj/item/mecha_parts/mecha_equipment/hydraulic_clamp,
				)
	crate_name= "\improper APLU MK-I kit"
	crate_type = /obj/structure/closet/crate/science/robo

/datum/supply_pack/engineering/conveyor
	name = "Conveyor Assembly Crate"
	desc = "Keep production moving along with thirty conveyor belts. Conveyor switch included. \
		If you have any questions, check out the enclosed instruction book."
	cost = CARGO_CRATE_VALUE * 3.5
	contains = list(/obj/item/stack/conveyor/thirty,
					/obj/item/conveyor_switch_construct,
					/obj/item/paper/guides/conveyor,
				)
	crate_name = "conveyor assembly crate"

/datum/supply_pack/engineering/engiequipment
	name = "Engineering Gear Crate"
	desc = "Gear up with three toolbelts, high-visibility vests, welding helmets, hardhats, \
		and two pairs of meson goggles!"
	cost = CARGO_CRATE_VALUE * 4
	access_view = ACCESS_ENGINEERING
	contains = list(/obj/item/storage/belt/utility = 3,
					/obj/item/clothing/suit/hazardvest = 3,
					/obj/item/clothing/head/utility/welding = 3,
					/obj/item/clothing/head/utility/hardhat = 3,
					/obj/item/clothing/glasses/meson/engine = 2,
				)
	crate_name = "engineering gear crate"

/datum/supply_pack/engineering/powergamermitts
	name = "Insulated Gloves Crate"
	desc = "The backbone of modern society. Barely ever ordered for actual engineering. \
		Contains three insulated gloves."
	cost = CARGO_CRATE_VALUE * 8 //Made of pure-grade bullshittinium
	access_view = ACCESS_ENGINE_EQUIP
	contains = list(/obj/item/clothing/gloves/color/yellow = 3)
	crate_name = "insulated gloves crate"
	crate_type = /obj/structure/closet/crate/engineering/electrical

/datum/supply_pack/engineering/inducers
	name = "NT-75 Electromagnetic Power Inducers Crate"
	desc = "No rechargers? No problem, with the NT-75 EPI, you can recharge any standard \
		cell-based equipment anytime, anywhere. Contains two Inducers."
	cost = CARGO_CRATE_VALUE * 4
	contains = list(/obj/item/inducer/orderable = 2)
	crate_name = "inducer crate"
	crate_type = /obj/structure/closet/crate/nakamura

/datum/supply_pack/engineering/pacman
	name = "P.A.C.M.A.N Generator Crate"
	desc = "Engineers can't set up the engine? Not an issue for you, once you get your hands \
		on this P.A.C.M.A.N. Generator! Takes in plasma and spits out sweet sweet energy."
	cost = CARGO_CRATE_VALUE * 5
	access_view = ACCESS_ENGINEERING
	contains = list(/obj/machinery/power/port_gen/pacman)
	crate_name = "\improper PACMAN generator crate"
	crate_type = /obj/structure/closet/crate/nakamura

/datum/supply_pack/engineering/power
	name = "Power Cell Crate"
	desc = "Looking for power overwhelming? Look no further. Contains three high-voltage power cells."
	cost = CARGO_CRATE_VALUE * 3
	contains = list(/obj/item/stock_parts/power_store/cell/high = 3)
	crate_name = "power cell crate"
	crate_type = /obj/structure/closet/crate/engineering/electrical

/datum/supply_pack/engineering/shuttle_engine
	name = "Shuttle Engine Crate"
	desc = "Through advanced bluespace-shenanigans, our engineers have managed to fit an entire \
		shuttle engine into one tiny little crate."
	cost = CARGO_CRATE_VALUE * 6
	access = ACCESS_CE
	access_view = ACCESS_CE
	contains = list(/obj/machinery/power/shuttle_engine/propulsion/burst/cargo)
	crate_name = "shuttle engine crate"
	crate_type = /obj/structure/closet/crate/secure/engineering

/datum/supply_pack/engineering/tools
	name = "Toolbox Crate"
	desc = "Any robust spaceman is never far from their trusty toolbox. Contains three electrical \
		toolboxes and three mechanical toolboxes."
	access_view = ACCESS_ENGINE_EQUIP
	contains = list(/obj/item/storage/toolbox/electrical = 3,
					/obj/item/storage/toolbox/mechanical = 3,
				)
	cost = CARGO_CRATE_VALUE * 5
	crate_name = "toolbox crate"

/datum/supply_pack/engineering/portapump
	name = "Portable Air Pump Crate"
	desc = "Did someone let the air out of the shuttle again? We've got you covered. \
		Contains two portable air pumps."
	cost = CARGO_CRATE_VALUE * 4.5
	access_view = ACCESS_ATMOSPHERICS
	contains = list(/obj/machinery/portable_atmospherics/pump = 2)
	crate_name = "portable air pump crate"
	crate_type = /obj/structure/closet/crate/secure/engineering/atmos

/datum/supply_pack/engineering/portascrubber
	name = "Portable Scrubber Crate"
	desc = "Clean up that pesky plasma leak with your very own set of two portable scrubbers."
	cost = CARGO_CRATE_VALUE * 4.5
	access_view = ACCESS_ATMOSPHERICS
	contains = list(/obj/machinery/portable_atmospherics/scrubber = 2)
	crate_name = "portable scrubber crate"
	crate_type = /obj/structure/closet/crate/secure/engineering/atmos

/datum/supply_pack/engineering/hugescrubber
	name = "Huge Portable Scrubber Crate"
	desc = "A huge portable scrubber for huge atmospherics mistakes."
	cost = CARGO_CRATE_VALUE * 7.5
	access_view = ACCESS_ATMOSPHERICS
	contains = list(/obj/machinery/portable_atmospherics/scrubber/huge/movable/cargo)
	crate_name = "huge portable scrubber crate"
	crate_type = /obj/structure/closet/crate/large

/datum/supply_pack/engineering/space_heater
	name = "Space Heater Crate"
	desc = "A dual purpose heater/cooler for when things are too chilly/toasty."
	cost = CARGO_CRATE_VALUE * 2
	contains = list(/obj/machinery/space_heater)
	crate_name = "space heater crate"
	crate_type = /obj/structure/closet/crate/secure/engineering/atmos

/datum/supply_pack/engineering/bsa
	name = "Bluespace Artillery Parts"
	desc = "The pride of Nanotrasen Naval Command. The legendary Bluespace Artillery Cannon is a \
		devastating feat of human engineering and testament to wartime determination. \
		Highly advanced research is required for proper construction."
	cost = CARGO_CRATE_VALUE * 30
	special = TRUE
	access_view = ACCESS_COMMAND
	contains = list(/obj/item/paper/guides/jobs/engineering/bsa,
					/obj/item/circuitboard/machine/bsa/front,
					/obj/item/circuitboard/machine/bsa/middle,
					/obj/item/circuitboard/machine/bsa/back,
					/obj/item/circuitboard/computer/bsa_control,
				)
	crate_name= "bluespace artillery parts crate"

/datum/supply_pack/engineering/dna_vault
	name = "DNA Vault Parts"
	desc = "Secure the longevity of the current state of humanity within this massive \
		library of scientific knowledge, capable of granting superhuman powers and abilities. \
		Highly advanced research is required for proper construction. Also contains five DNA probes."
	cost = CARGO_CRATE_VALUE * 24
	special = TRUE
	access_view = ACCESS_COMMAND
	contains = list(/obj/item/circuitboard/machine/dna_vault,
					/obj/item/dna_probe = 5,
				)
	crate_name= "dna vault parts crate"

/datum/supply_pack/engineering/dna_probes
	name = "DNA Vault Samplers"
	desc = "Contains five DNA probes for use in the DNA vault."
	cost = CARGO_CRATE_VALUE * 6
	special = TRUE
	access_view = ACCESS_COMMAND
	contains = list(/obj/item/dna_probe = 5)
	crate_name= "dna samplers crate"


/datum/supply_pack/engineering/shield_sat
	name = "Shield Generator Satellite"
	desc = "Protect the very existence of this station with these Anti-Meteor defenses. \
		Contains three Shield Generator Satellites."
	cost = CARGO_CRATE_VALUE * 6
	access_view = ACCESS_COMMAND
	contains = list(/obj/machinery/satellite/meteor_shield = 3)
	crate_name= "shield sat crate"


/datum/supply_pack/engineering/shield_sat_control
	name = "Shield System Control Board"
	desc = "A control system for the Shield Generator Satellite system."
	cost = CARGO_CRATE_VALUE * 10
	access_view = ACCESS_COMMAND
	contains = list(/obj/item/circuitboard/computer/sat_control)
	crate_name= "shield control board crate"

/datum/supply_pack/engineering/ceturtlenecks
	name = "Chief Engineer Turtlenecks"
	desc = "Contains the CE's turtleneck and turtleneck skirt."
	cost = CARGO_CRATE_VALUE * 2
	access = ACCESS_CE
	contains = list(/obj/item/clothing/under/rank/engineering/chief_engineer/turtleneck,
					/obj/item/clothing/under/rank/engineering/chief_engineer/turtleneck/skirt,
				)

/// Engine Construction

/datum/supply_pack/engine
	group = "Engine Construction"
	access_view = ACCESS_ENGINEERING
	crate_type = /obj/structure/closet/crate/engineering

/datum/supply_pack/engine/emitter
	name = "Emitter Crate"
	desc = "Useful for powering forcefield generators while destroying locked crates \
		and intruders alike. Contains two high-powered energy emitters."
	cost = CARGO_CRATE_VALUE * 7
	access = ACCESS_CE
	contains = list(/obj/machinery/power/emitter = 2)
	crate_name = "emitter crate"
	crate_type = /obj/structure/closet/crate/secure/engineering
	dangerous = TRUE

/datum/supply_pack/engine/field_gen
	name = "Field Generator Crate"
	desc = "Typically the only thing standing between the station and a messy death. \
		Powered by emitters. Contains two field generators."
	cost = CARGO_CRATE_VALUE * 7
	contains = list(/obj/machinery/field/generator = 2)
	crate_name = "field generator crate"

/datum/supply_pack/engine/grounding_rods
	name = "Grounding Rod Crate"
	desc = "Four grounding rods guaranteed to keep any uppity tesla coil's lightning under control."
	cost = CARGO_CRATE_VALUE * 8
	contains = list(/obj/machinery/power/energy_accumulator/grounding_rod = 4)
	crate_name = "grounding rod crate"
	crate_type = /obj/structure/closet/crate/engineering/electrical

/datum/supply_pack/engine/solar
	name = "Solar Panel Crate"
	desc = "Go green with this DIY advanced solar array. Contains twenty one solar assemblies, \
		a solar-control circuit board, and tracker. If you have any questions, \
		please check out the enclosed instruction book."
	cost = CARGO_CRATE_VALUE * 8
	contains = list(/obj/item/solar_assembly = 21,
					/obj/item/circuitboard/computer/solar_control,
					/obj/item/electronics/tracker,
					/obj/item/paper/guides/jobs/engi/solars,
				)
	crate_name = "solar panel crate"
	crate_type = /obj/structure/closet/crate/engineering/electrical

/datum/supply_pack/engine/supermatter_shard
	name = "Supermatter Shard Crate"
	desc = "The power of the heavens condensed into a single crystal."
	cost = CARGO_CRATE_VALUE * 20
	access = ACCESS_CE
	contains = list(/obj/machinery/power/supermatter_crystal/shard)
	crate_name = "supermatter shard crate"
	crate_type = /obj/structure/closet/crate/secure/radiation
	dangerous = TRUE
	discountable = SUPPLY_PACK_RARE_DISCOUNTABLE

/datum/supply_pack/engine/tesla_coils
	name = "Tesla Coil Crate"
	desc = "Whether it's high-voltage executions, creating research points, or just plain old \
		assistant electrofrying: this pack of four Tesla coils can do it all!"
	cost = CARGO_CRATE_VALUE * 10
	contains = list(/obj/machinery/power/energy_accumulator/tesla_coil = 4)
	crate_name = "tesla coil crate"
	crate_type = /obj/structure/closet/crate/engineering/electrical

/datum/supply_pack/engine/hypertorus_fusion_reactor
	name = "HFR Crate"
	desc = "The new and improved fusion reactor."
	cost = CARGO_CRATE_VALUE * 23
	access = ACCESS_CE
	contains = list(/obj/item/hfr_box/corner = 4,
					/obj/item/hfr_box/body/fuel_input,
					/obj/item/hfr_box/body/moderator_input,
					/obj/item/hfr_box/body/waste_output,
					/obj/item/hfr_box/body/interface,
					/obj/item/hfr_box/core,
				)
	crate_name = "HFR crate"
	crate_type = /obj/structure/closet/crate/secure/engineering/atmos
	dangerous = TRUE

/datum/supply_pack/engineering/rad_protection_modules
	name = "Radiation Protection Modules"
	desc = "Contains multiple radiation protections modules for MODsuits."
	hidden = TRUE
	contains = list(/obj/item/mod/module/rad_protection = 3)
	crate_name = "modsuit radiation modules"
	crate_type = /obj/structure/closet/crate/engineering

/datum/supply_pack/engineering/rad_nebula_shielding_kit
	name = "Radioactive Nebula Shielding"
	desc = "Contains circuitboards and radiation modules for constructing radioactive nebula shielding."
	cost = CARGO_CRATE_VALUE * 2

	special = TRUE
	contains = list(
		/obj/item/mod/module/rad_protection = 5,
		/obj/item/circuitboard/machine/radioactive_nebula_shielding = 5,
		/obj/item/paper/fluff/radiation_nebula = 1,
	)
	crate_name = "radioactive nebula shielding (IMPORTANT)"
	crate_type = /obj/structure/closet/crate/engineering

/datum/supply_pack/engineering/portagrav
	name = "Portable Gravity Unit Crate"
	desc = "Contains a portable gravity unit, to make the clown float into the ceiling."
	cost = CARGO_CRATE_VALUE * 4
	access_view = ACCESS_ENGINEERING
	contains = list(/obj/machinery/power/portagrav = 1)
	crate_name = "portable gravity unit crate"
	crate_type = /obj/structure/closet/crate/engineering
