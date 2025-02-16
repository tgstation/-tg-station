// HUDs

/datum/design/health_hud
	name = "Health Scanner HUD"
	desc = "A heads-up display that scans the humans in view and provides accurate data about their health status."
	id = "health_hud"
	build_type = PROTOLATHE | AWAY_LATHE
	materials = list(/datum/material/iron =SMALL_MATERIAL_AMOUNT*5, /datum/material/glass =SMALL_MATERIAL_AMOUNT*5)
	build_path = /obj/item/clothing/glasses/hud/health
	category = list(
		RND_CATEGORY_EQUIPMENT + RND_SUBCATEGORY_EQUIPMENT_MEDICAL
	)
	departmental_flags = DEPARTMENT_BITFLAG_MEDICAL

/datum/design/health_hud_night
	name = "Night Vision Health Scanner HUD"
	desc = "An advanced medical head-up display that allows doctors to find patients in complete darkness."
	id = "health_hud_night"
	build_type = PROTOLATHE | AWAY_LATHE
	materials = list(
		/datum/material/iron = SMALL_MATERIAL_AMOUNT*6,
		/datum/material/glass = SMALL_MATERIAL_AMOUNT*6,
		/datum/material/uranium =HALF_SHEET_MATERIAL_AMOUNT,
		/datum/material/silver = SMALL_MATERIAL_AMOUNT*3.5,
	)
	build_path = /obj/item/clothing/glasses/hud/health/night
	category = list(
		RND_CATEGORY_EQUIPMENT + RND_SUBCATEGORY_EQUIPMENT_MEDICAL
	)
	departmental_flags = DEPARTMENT_BITFLAG_MEDICAL

/datum/design/security_hud
	name = "Security HUD"
	desc = "A heads-up display that scans the humans in view and provides accurate data about their ID status."
	id = "security_hud"
	build_type = PROTOLATHE | AWAY_LATHE
	materials = list(/datum/material/iron =SMALL_MATERIAL_AMOUNT*5, /datum/material/glass =SMALL_MATERIAL_AMOUNT*5)
	build_path = /obj/item/clothing/glasses/hud/security
	category = list(
		RND_CATEGORY_EQUIPMENT + RND_SUBCATEGORY_EQUIPMENT_SECURITY
	)
	departmental_flags = DEPARTMENT_BITFLAG_SECURITY

/datum/design/security_hud_night
	name = "Night Vision Security HUD"
	desc = "A heads-up display which provides id data and vision in complete darkness."
	id = "security_hud_night"
	build_type = PROTOLATHE | AWAY_LATHE
	materials = list(
		/datum/material/iron = SMALL_MATERIAL_AMOUNT*6,
		/datum/material/glass = SMALL_MATERIAL_AMOUNT*6,
		/datum/material/uranium =HALF_SHEET_MATERIAL_AMOUNT,
		/datum/material/gold = SMALL_MATERIAL_AMOUNT*3.5,
	)
	build_path = /obj/item/clothing/glasses/hud/security/night
	category = list(
		RND_CATEGORY_EQUIPMENT + RND_SUBCATEGORY_EQUIPMENT_SECURITY
	)
	departmental_flags = DEPARTMENT_BITFLAG_SECURITY

/datum/design/diagnostic_hud
	name = "Diagnostic HUD"
	desc = "A HUD used to analyze and determine faults within robotic machinery."
	id = "diagnostic_hud"
	build_type = PROTOLATHE | AWAY_LATHE
	materials = list(/datum/material/iron =SMALL_MATERIAL_AMOUNT*5, /datum/material/glass =SMALL_MATERIAL_AMOUNT*5)
	build_path = /obj/item/clothing/glasses/hud/diagnostic
	category = list(
		RND_CATEGORY_EQUIPMENT + RND_SUBCATEGORY_EQUIPMENT_SCIENCE
	)
	departmental_flags = DEPARTMENT_BITFLAG_SCIENCE

/datum/design/diagnostic_hud_night
	name = "Night Vision Diagnostic HUD"
	desc = "Upgraded version of the diagnostic HUD designed to function during a power failure."
	id = "diagnostic_hud_night"
	build_type = PROTOLATHE | AWAY_LATHE
	materials = list(
		/datum/material/iron = SMALL_MATERIAL_AMOUNT*6,
		/datum/material/glass = SMALL_MATERIAL_AMOUNT*6,
		/datum/material/uranium =HALF_SHEET_MATERIAL_AMOUNT,
		/datum/material/plasma =SMALL_MATERIAL_AMOUNT * 3,
	)
	build_path = /obj/item/clothing/glasses/hud/diagnostic/night
	category = list(
		RND_CATEGORY_EQUIPMENT + RND_SUBCATEGORY_EQUIPMENT_SCIENCE
	)
	departmental_flags = DEPARTMENT_BITFLAG_SCIENCE

// Misc

/datum/design/welding_goggles
	name = "Welding Goggles"
	desc = "Protects the eyes from bright flashes; approved by the mad scientist association."
	id = "welding_goggles"
	build_type = PROTOLATHE | AWAY_LATHE
	materials = list(/datum/material/iron =SMALL_MATERIAL_AMOUNT*5, /datum/material/glass =SMALL_MATERIAL_AMOUNT*5)
	build_path = /obj/item/clothing/glasses/welding
	category = list(
		RND_CATEGORY_EQUIPMENT + RND_SUBCATEGORY_EQUIPMENT_ENGINEERING
	)
	departmental_flags = DEPARTMENT_BITFLAG_SCIENCE | DEPARTMENT_BITFLAG_ENGINEERING

/datum/design/welding_mask
	name = "Welding Gas Mask"
	desc = "A gas mask with built in welding goggles and face shield. Looks like a skull, clearly designed by a nerd."
	id = "weldingmask"
	build_type = PROTOLATHE | AWAY_LATHE
	materials = list(/datum/material/iron =SHEET_MATERIAL_AMOUNT * 1.5, /datum/material/glass =HALF_SHEET_MATERIAL_AMOUNT)
	build_path = /obj/item/clothing/mask/gas/welding
	category = list(
		RND_CATEGORY_EQUIPMENT + RND_SUBCATEGORY_EQUIPMENT_ENGINEERING
	)
	departmental_flags = DEPARTMENT_BITFLAG_SCIENCE | DEPARTMENT_BITFLAG_ENGINEERING

/datum/design/bright_helmet
	name = "Workplace-Ready Firefighter Helmet"
	desc = "By applying state of the art lighting technology to a fire helmet with industry standard photo-chemical hardening methods, this hardhat will protect you from robust workplace hazards."
	id = "bright_helmet"
	build_type = PROTOLATHE | AWAY_LATHE
	materials = list(
		/datum/material/iron = SHEET_MATERIAL_AMOUNT*2,
		/datum/material/glass =HALF_SHEET_MATERIAL_AMOUNT,
		/datum/material/plastic =SHEET_MATERIAL_AMOUNT * 1.5,
		/datum/material/silver =SMALL_MATERIAL_AMOUNT*5,
	)
	build_path = /obj/item/clothing/head/utility/hardhat/red/upgraded
	category = list(
		RND_CATEGORY_EQUIPMENT + RND_SUBCATEGORY_EQUIPMENT_ENGINEERING
	)
	departmental_flags = DEPARTMENT_BITFLAG_SCIENCE | DEPARTMENT_BITFLAG_ENGINEERING

/datum/design/mauna_mug
	name = "Mauna Mug"
	desc = "This awesome mug will ensure your coffee never stays cold!"
	id = "mauna_mug"
	build_type = PROTOLATHE | AWAY_LATHE
	materials = list(/datum/material/iron =HALF_SHEET_MATERIAL_AMOUNT, /datum/material/glass =SMALL_MATERIAL_AMOUNT)
	category = list(
		RND_CATEGORY_EQUIPMENT + RND_SUBCATEGORY_EQUIPMENT_SCIENCE
	)
	build_path = /obj/item/reagent_containers/cup/maunamug
	departmental_flags = DEPARTMENT_BITFLAG_SCIENCE

/datum/design/rolling_table
	name = "Rolly poly"
	desc = "We duct-taped some wheels to the bottom of a table. It's goddamn science alright?"
	id = "rolling_table"
	build_type = PROTOLATHE | AWAY_LATHE
	materials = list(/datum/material/iron = SHEET_MATERIAL_AMOUNT*2)
	build_path = /obj/structure/table/rolling
	category = list(
		RND_CATEGORY_EQUIPMENT + RND_SUBCATEGORY_EQUIPMENT_SCIENCE
	)
	departmental_flags = DEPARTMENT_BITFLAG_SCIENCE

/datum/design/portaseeder
	name = "Portable Seed Extractor"
	desc = "For the enterprising botanist on the go. Less efficient than the stationary model, it creates one seed per plant."
	id = "portaseeder"
	build_type = PROTOLATHE | AWAY_LATHE
	materials = list(/datum/material/iron =HALF_SHEET_MATERIAL_AMOUNT, /datum/material/glass = SMALL_MATERIAL_AMOUNT*4)
	build_path = /obj/item/storage/bag/plants/portaseeder
	category = list(
		RND_CATEGORY_EQUIPMENT + RND_SUBCATEGORY_TOOLS_BOTANY
	)
	departmental_flags = DEPARTMENT_BITFLAG_SERVICE

/datum/design/clown_firing_pin
	name = "Hilarious Firing Pin"
	id = "clown_firing_pin"
	build_type = PROTOLATHE | AWAY_LATHE
	materials = list(/datum/material/iron =SMALL_MATERIAL_AMOUNT*5, /datum/material/glass =SMALL_MATERIAL_AMOUNT * 3, /datum/material/bananium =SMALL_MATERIAL_AMOUNT*5)
	build_path = /obj/item/firing_pin/clown
	category = list(
		RND_CATEGORY_EQUIPMENT + RND_SUBCATEGORY_EQUIPMENT_SERVICE
	)
	departmental_flags = DEPARTMENT_BITFLAG_SERVICE

/datum/design/water_balloon
	name = "Water Balloon"
	id = "water_balloon"
	build_type = PROTOLATHE | AWAY_LATHE
	materials = list(/datum/material/plastic =SMALL_MATERIAL_AMOUNT*5)
	build_path = /obj/item/toy/waterballoon
	category = list(
		RND_CATEGORY_EQUIPMENT + RND_SUBCATEGORY_EQUIPMENT_SERVICE
	)
	departmental_flags = DEPARTMENT_BITFLAG_SERVICE

/datum/design/mesons
	name = "Optical Meson Scanners"
	desc = "Used by engineering and mining staff to see basic structural and terrain layouts through walls, regardless of lighting condition."
	id = "mesons"
	build_type = PROTOLATHE | AWAY_LATHE
	materials = list(/datum/material/iron =SMALL_MATERIAL_AMOUNT*5, /datum/material/glass =SMALL_MATERIAL_AMOUNT*5)
	build_path = /obj/item/clothing/glasses/meson
	category = list(
		RND_CATEGORY_EQUIPMENT + RND_SUBCATEGORY_EQUIPMENT_ENGINEERING
	)
	departmental_flags = DEPARTMENT_BITFLAG_CARGO | DEPARTMENT_BITFLAG_ENGINEERING

/datum/design/engine_goggles
	name = "Engineering Scanner Goggles"
	desc = "Goggles used by engineers. The Meson Scanner mode lets you see basic structural and terrain layouts through walls, regardless of lighting condition. The T-ray Scanner mode lets you see underfloor objects such as cables and pipes."
	id = "engine_goggles"
	build_type = PROTOLATHE | AWAY_LATHE
	materials = list(/datum/material/iron =SMALL_MATERIAL_AMOUNT*5, /datum/material/glass =SMALL_MATERIAL_AMOUNT*5, /datum/material/plasma =SMALL_MATERIAL_AMOUNT)
	build_path = /obj/item/clothing/glasses/meson/engine
	category = list(
		RND_CATEGORY_EQUIPMENT + RND_SUBCATEGORY_EQUIPMENT_ENGINEERING
	)
	departmental_flags = DEPARTMENT_BITFLAG_ENGINEERING

/datum/design/tray_goggles
	name = "Optical T-Ray Scanners"
	desc = "Used by engineering staff to see underfloor objects such as cables and pipes."
	id = "tray_goggles"
	build_type = PROTOLATHE | AWAY_LATHE
	materials = list(/datum/material/iron =SMALL_MATERIAL_AMOUNT*5, /datum/material/glass =SMALL_MATERIAL_AMOUNT*5)
	build_path = /obj/item/clothing/glasses/meson/engine/tray
	category = list(
		RND_CATEGORY_EQUIPMENT + RND_SUBCATEGORY_EQUIPMENT_ATMOSPHERICS
	)
	departmental_flags = DEPARTMENT_BITFLAG_ENGINEERING

/datum/design/atmos_thermal
	name = "Atmospheric thermal imaging goggles"
	desc = "Used by Atmospheric Technician to determine the temperature of the air"
	id = "atmos_thermal"
	build_type = PROTOLATHE | AWAY_LATHE
	materials = list(/datum/material/iron =SMALL_MATERIAL_AMOUNT*5, /datum/material/glass =SMALL_MATERIAL_AMOUNT*5, /datum/material/plasma =SMALL_MATERIAL_AMOUNT)
	build_path = /obj/item/clothing/glasses/meson/engine/atmos_imaging
	category = list(
		RND_CATEGORY_EQUIPMENT + RND_SUBCATEGORY_EQUIPMENT_ATMOSPHERICS
	)
	departmental_flags = DEPARTMENT_BITFLAG_ENGINEERING

/datum/design/nvgmesons
	name = "Night Vision Optical Meson Scanners"
	desc = "Prototype meson scanners fitted with an extra sensor which amplifies the visible light spectrum and overlays it to the UHD display."
	id = "nvgmesons"
	build_type = PROTOLATHE | AWAY_LATHE
	materials = list(
		/datum/material/iron = SMALL_MATERIAL_AMOUNT*6,
		/datum/material/glass = SMALL_MATERIAL_AMOUNT*6,
		/datum/material/plasma = SMALL_MATERIAL_AMOUNT*3.5,
		/datum/material/uranium =HALF_SHEET_MATERIAL_AMOUNT,
	)
	build_path = /obj/item/clothing/glasses/meson/night
	category = list(
		RND_CATEGORY_EQUIPMENT + RND_SUBCATEGORY_EQUIPMENT_ENGINEERING
	)
	departmental_flags = DEPARTMENT_BITFLAG_ENGINEERING | DEPARTMENT_BITFLAG_CARGO

/datum/design/night_vision_goggles
	name = "Night Vision Goggles"
	desc = "Goggles that let you see through darkness unhindered."
	id = "night_visision_goggles"
	build_type = PROTOLATHE | AWAY_LATHE
	materials = list(
		/datum/material/iron = SMALL_MATERIAL_AMOUNT*6,
		/datum/material/glass = SMALL_MATERIAL_AMOUNT*6,
		/datum/material/plasma = SMALL_MATERIAL_AMOUNT*3.5,
		/datum/material/uranium =HALF_SHEET_MATERIAL_AMOUNT,
	)
	build_path = /obj/item/clothing/glasses/night
	category = list(
		RND_CATEGORY_EQUIPMENT + RND_SUBCATEGORY_EQUIPMENT_MISC
	)
	departmental_flags = DEPARTMENT_BITFLAG_SCIENCE | DEPARTMENT_BITFLAG_SECURITY

/datum/design/magboots
	name = "Magnetic Boots"
	desc = "Magnetic boots, often used during extravehicular activity to ensure the user remains safely attached to the vehicle."
	id = "magboots"
	build_type = PROTOLATHE | AWAY_LATHE
	materials = list(
		/datum/material/iron = SHEET_MATERIAL_AMOUNT*2,
		/datum/material/silver =HALF_SHEET_MATERIAL_AMOUNT * 1.5,
		/datum/material/gold = SHEET_MATERIAL_AMOUNT*1.25,
	)
	build_path = /obj/item/clothing/shoes/magboots
	category = list(
		RND_CATEGORY_EQUIPMENT + RND_SUBCATEGORY_EQUIPMENT_ENGINEERING
	)
	departmental_flags = DEPARTMENT_BITFLAG_ENGINEERING

/datum/design/forcefield_projector
	name = "Forcefield Projector"
	desc = "A device which can project temporary forcefields to seal off an area."
	id = "forcefield_projector"
	build_type = PROTOLATHE | AWAY_LATHE
	materials = list(
		/datum/material/iron = SHEET_MATERIAL_AMOUNT*1.25,
		/datum/material/glass =HALF_SHEET_MATERIAL_AMOUNT,
	)
	build_path = /obj/item/forcefield_projector
	category = list(
		RND_CATEGORY_TOOLS + RND_SUBCATEGORY_TOOLS_ENGINEERING
	)
	departmental_flags = DEPARTMENT_BITFLAG_ENGINEERING

/datum/design/sci_goggles
	name = "Science Goggles"
	desc = "Goggles fitted with a portable analyzer capable of determining the research worth of an item or components of a machine."
	id = "scigoggles"
	build_type = PROTOLATHE | AWAY_LATHE
	materials = list(/datum/material/iron =SMALL_MATERIAL_AMOUNT*5, /datum/material/glass =SMALL_MATERIAL_AMOUNT*5)
	build_path = /obj/item/clothing/glasses/science
	category = list(
		RND_CATEGORY_EQUIPMENT + RND_SUBCATEGORY_EQUIPMENT_CHEMISTRY
	)
	departmental_flags = DEPARTMENT_BITFLAG_SCIENCE | DEPARTMENT_BITFLAG_MEDICAL

/datum/design/nv_sci_goggles
	name = "Night Vision Science Goggles"
	desc = "Goggles that lets the user see in the dark and recognize chemical compounds at a glance."
	id = "nv_scigoggles"
	build_type = PROTOLATHE | AWAY_LATHE
	materials = list(
		/datum/material/iron = SMALL_MATERIAL_AMOUNT*6,
		/datum/material/glass = SMALL_MATERIAL_AMOUNT*6,
		/datum/material/plasma = SMALL_MATERIAL_AMOUNT*3.5,
		/datum/material/uranium =HALF_SHEET_MATERIAL_AMOUNT,
	)
	build_path = /obj/item/clothing/glasses/science/night
	category = list(
		RND_CATEGORY_EQUIPMENT + RND_SUBCATEGORY_EQUIPMENT_CHEMISTRY
	)
	departmental_flags = DEPARTMENT_BITFLAG_SCIENCE | DEPARTMENT_BITFLAG_MEDICAL

/datum/design/roastingstick
	name = "Advanced Roasting Stick"
	desc = "A roasting stick for cooking sausages in exotic ovens."
	id = "roastingstick"
	build_type = PROTOLATHE | AWAY_LATHE
	materials = list(
		/datum/material/iron=HALF_SHEET_MATERIAL_AMOUNT,
		/datum/material/glass =SMALL_MATERIAL_AMOUNT*5,
		/datum/material/bluespace = SMALL_MATERIAL_AMOUNT*2.5,
	)
	build_path = /obj/item/melee/roastingstick
	category = list(
		RND_CATEGORY_EQUIPMENT + RND_SUBCATEGORY_EQUIPMENT_KITCHEN
	)
	departmental_flags = DEPARTMENT_BITFLAG_SERVICE

/datum/design/locator
	name = "Bluespace Locator"
	desc = "Used to track portable teleportation beacons and targets with embedded tracking implants."
	id = "locator"
	build_type = PROTOLATHE | AWAY_LATHE
	materials = list(/datum/material/iron=HALF_SHEET_MATERIAL_AMOUNT, /datum/material/glass =SMALL_MATERIAL_AMOUNT*5, /datum/material/silver =SMALL_MATERIAL_AMOUNT*5)
	build_path = /obj/item/locator
	category = list(
		RND_CATEGORY_EQUIPMENT + RND_SUBCATEGORY_EQUIPMENT_SECURITY
	)
	departmental_flags = DEPARTMENT_BITFLAG_SECURITY

/datum/design/quantum_keycard
	name = "Quantum Keycard"
	desc = "Allows for the construction of a quantum keycard."
	id = "quantum_keycard"
	build_type = PROTOLATHE | AWAY_LATHE
	materials = list(/datum/material/glass =SMALL_MATERIAL_AMOUNT*5, /datum/material/iron =SMALL_MATERIAL_AMOUNT*5, /datum/material/silver =SMALL_MATERIAL_AMOUNT*5, /datum/material/bluespace =HALF_SHEET_MATERIAL_AMOUNT)
	build_path = /obj/item/quantum_keycard
	category = list(
		RND_CATEGORY_EQUIPMENT + RND_SUBCATEGORY_EQUIPMENT_SCIENCE
	)
	departmental_flags = DEPARTMENT_BITFLAG_SCIENCE

/datum/design/botpad_remote
	name = "Bot Launchpad Controller"
	desc = "Allows you to control the connected bot launchpad"
	id = "botpad_remote"
	build_type = PROTOLATHE | AWAY_LATHE
	materials = list(/datum/material/glass =SMALL_MATERIAL_AMOUNT*5, /datum/material/iron =SMALL_MATERIAL_AMOUNT*5)
	build_path = /obj/item/botpad_remote
	category = list(
		RND_CATEGORY_EQUIPMENT + RND_SUBCATEGORY_EQUIPMENT_SCIENCE
	)
	departmental_flags = DEPARTMENT_BITFLAG_SCIENCE

/datum/design/anomaly_neutralizer
	name = "Anomaly Neutralizer"
	desc = "An advanced tool capable of instantly neutralizing anomalies, designed to capture the fleeting aberrations created by the engine."
	id = "anomaly_neutralizer"
	build_type = PROTOLATHE | AWAY_LATHE
	materials = list(/datum/material/iron =SHEET_MATERIAL_AMOUNT, /datum/material/gold =SHEET_MATERIAL_AMOUNT, /datum/material/plasma =SHEET_MATERIAL_AMOUNT * 2.5, /datum/material/uranium =SHEET_MATERIAL_AMOUNT)
	build_path = /obj/item/anomaly_neutralizer
	category = list(
		RND_CATEGORY_EQUIPMENT + RND_SUBCATEGORY_EQUIPMENT_SCIENCE
	)
	departmental_flags = DEPARTMENT_BITFLAG_SCIENCE

/datum/design/donksoft_refill
	name = "Donksoft Toy Vendor Refill"
	desc = "A refill canister for Donksoft Toy Vendors."
	id = "donksoft_refill"
	build_type = PROTOLATHE | AWAY_LATHE
	materials = list(
		/datum/material/iron = SHEET_MATERIAL_AMOUNT*12.5,
		/datum/material/glass = SHEET_MATERIAL_AMOUNT*7.5,
		/datum/material/plasma = SHEET_MATERIAL_AMOUNT*10,
		/datum/material/gold = SHEET_MATERIAL_AMOUNT*5,
		/datum/material/silver = SHEET_MATERIAL_AMOUNT*5,
	)
	build_path = /obj/item/vending_refill/donksoft
	category = list(
		RND_CATEGORY_STOCK_PARTS + RND_SUBCATEGORY_STOCK_PARTS_MISC
	)
	departmental_flags = DEPARTMENT_BITFLAG_ENGINEERING | DEPARTMENT_BITFLAG_SERVICE

/datum/design/oxygen_tank
	name = "Oxygen Tank"
	desc = "An empty oxygen tank."
	id = "oxygen_tank"
	build_type = PROTOLATHE | AWAY_LATHE
	materials = list(/datum/material/iron =SHEET_MATERIAL_AMOUNT)
	build_path = /obj/item/tank/internals/oxygen/empty
	category = list(
		RND_CATEGORY_EQUIPMENT + RND_SUBCATEGORY_EQUIPMENT_GAS_TANKS
	)
	departmental_flags = DEPARTMENT_BITFLAG_ENGINEERING | DEPARTMENT_BITFLAG_SCIENCE | DEPARTMENT_BITFLAG_CARGO

/datum/design/plasma_tank
	name = "Plasma Tank"
	desc = "An empty oxygen tank."
	id = "plasma_tank"
	build_type = PROTOLATHE | AWAY_LATHE
	materials = list(/datum/material/iron =SHEET_MATERIAL_AMOUNT)
	build_path = /obj/item/tank/internals/plasma/empty
	category = list(
		RND_CATEGORY_EQUIPMENT + RND_SUBCATEGORY_EQUIPMENT_GAS_TANKS
	)
	departmental_flags = DEPARTMENT_BITFLAG_ENGINEERING | DEPARTMENT_BITFLAG_SCIENCE

/datum/design/id
	name = "Identification Card"
	desc = "A card used to provide ID and determine access across the station. Has an integrated digital display and advanced microchips."
	id = "idcard"
	build_type = PROTOLATHE | AWAY_LATHE
	materials = list(/datum/material/iron=SMALL_MATERIAL_AMOUNT * 2, /datum/material/glass =SMALL_MATERIAL_AMOUNT)
	build_path = /obj/item/card/id/advanced
	category = list(
		RND_CATEGORY_EQUIPMENT + RND_SUBCATEGORY_EQUIPMENT_SERVICE
	)
	departmental_flags = DEPARTMENT_BITFLAG_SERVICE

/datum/design/eng_gloves
	name = "Tinkers Gloves"
	desc = "Overdesigned engineering gloves that have automated construction subroutines dialed in, allowing for faster construction while worn."
	id = "eng_gloves"
	build_type = PROTOLATHE | AWAY_LATHE
	materials = list(/datum/material/iron=SHEET_MATERIAL_AMOUNT, /datum/material/silver=HALF_SHEET_MATERIAL_AMOUNT * 1.5, /datum/material/gold =HALF_SHEET_MATERIAL_AMOUNT)
	build_path = /obj/item/clothing/gloves/tinkerer
	category = list(
		RND_CATEGORY_EQUIPMENT + RND_SUBCATEGORY_EQUIPMENT_ENGINEERING
	)
	departmental_flags = DEPARTMENT_BITFLAG_ENGINEERING

/datum/design/lavarods
	name = "Lava-Resistant Iron Rods"
	id = "lava_rods"
	build_type = PROTOLATHE | AWAY_LATHE
	materials = list(/datum/material/iron=HALF_SHEET_MATERIAL_AMOUNT, /datum/material/plasma=SMALL_MATERIAL_AMOUNT*5, /datum/material/titanium=SHEET_MATERIAL_AMOUNT)
	build_path = /obj/item/stack/rods/lava
	category = list(
		RND_CATEGORY_CONSTRUCTION + RND_SUBCATEGORY_CONSTRUCTION_MATERIALS
	)
	departmental_flags = DEPARTMENT_BITFLAG_CARGO | DEPARTMENT_BITFLAG_SCIENCE | DEPARTMENT_BITFLAG_ENGINEERING

/datum/design/plasticducky
	name = "Rubber Ducky"
	desc = "The classic Nanotrasen design for competitively priced bath based duck toys. No need for fancy Waffle Corp. rubber, buy Plastic Ducks today!"
	id = "plasticducky"
	build_type = PROTOLATHE | AWAY_LATHE
	materials = list(/datum/material/plastic =HALF_SHEET_MATERIAL_AMOUNT)
	build_path = /obj/item/bikehorn/rubberducky/plasticducky
	category = list(
		RND_CATEGORY_EQUIPMENT + RND_SUBCATEGORY_EQUIPMENT_SERVICE
	)
	departmental_flags = DEPARTMENT_BITFLAG_SERVICE

/datum/design/pneumatic_seal
	name = "Pneumatic Airlock Seal"
	desc = "A heavy brace used to seal airlocks. Useful for keeping out people without the dexterity to remove it."
	id = "pneumatic_seal"
	build_type = PROTOLATHE | AWAY_LATHE
	materials = list(/datum/material/iron = SHEET_MATERIAL_AMOUNT*10, /datum/material/plasma = SHEET_MATERIAL_AMOUNT*5)
	build_path = /obj/item/door_seal
	category = list(
		RND_CATEGORY_EQUIPMENT + RND_SUBCATEGORY_EQUIPMENT_ENGINEERING
	)
	departmental_flags = DEPARTMENT_BITFLAG_ENGINEERING | DEPARTMENT_BITFLAG_SECURITY | DEPARTMENT_BITFLAG_SCIENCE

// Janitor Designs

/datum/design/advmop
	name = "Advanced Mop"
	desc = "An upgraded mop with a large internal capacity for holding water or other cleaning chemicals."
	id = "advmop"
	build_type = PROTOLATHE | AWAY_LATHE
	materials = list(/datum/material/iron = HALF_SHEET_MATERIAL_AMOUNT*2.5, /datum/material/glass =SMALL_MATERIAL_AMOUNT * 2)
	build_path = /obj/item/mop/advanced
	category = list(
		RND_CATEGORY_TOOLS + RND_SUBCATEGORY_TOOLS_JANITORIAL
	)
	departmental_flags = DEPARTMENT_BITFLAG_SERVICE

/datum/design/normtrash
	name = "Trashbag"
	desc = "It's a bag for trash, you put garbage in it."
	id = "normtrash"
	build_type = PROTOLATHE | AWAY_LATHE
	materials = list(/datum/material/plastic =SHEET_MATERIAL_AMOUNT)
	build_path = /obj/item/storage/bag/trash
	category = list(
		RND_CATEGORY_TOOLS + RND_SUBCATEGORY_TOOLS_JANITORIAL
	)
	departmental_flags = DEPARTMENT_BITFLAG_SERVICE

/datum/design/blutrash
	name = "Trashbag of Holding"
	desc = "An advanced trash bag with bluespace properties; capable of holding a plethora of garbage."
	id = "blutrash"
	build_type = PROTOLATHE | AWAY_LATHE
	materials = list(/datum/material/gold =HALF_SHEET_MATERIAL_AMOUNT * 1.5, /datum/material/uranium = SMALL_MATERIAL_AMOUNT*2.5, /datum/material/plasma =HALF_SHEET_MATERIAL_AMOUNT * 1.5)
	build_path = /obj/item/storage/bag/trash/bluespace
	category = list(
		RND_CATEGORY_TOOLS + RND_SUBCATEGORY_TOOLS_JANITORIAL
	)
	departmental_flags = DEPARTMENT_BITFLAG_SERVICE

/datum/design/light_replacer
	name = "Light Replacer"
	desc = "A device to automatically replace lights. Refill with working light bulbs."
	id = "light_replacer"
	build_type = PROTOLATHE | AWAY_LATHE
	materials = list(/datum/material/iron =HALF_SHEET_MATERIAL_AMOUNT * 1.5, /datum/material/silver = SMALL_MATERIAL_AMOUNT*1.5, /datum/material/glass =SHEET_MATERIAL_AMOUNT * 1.5)
	build_path = /obj/item/lightreplacer
	category = list(
		RND_CATEGORY_TOOLS + RND_SUBCATEGORY_TOOLS_JANITORIAL
	)
	departmental_flags = DEPARTMENT_BITFLAG_SERVICE

/datum/design/light_replacer_blue
	name = "Bluespace Light Replacer"
	desc = "A device to automatically replace lights at a distance. Refill with working light bulbs."
	id = "light_replacer_blue"
	build_type = PROTOLATHE
	materials = list(/datum/material/iron =HALF_SHEET_MATERIAL_AMOUNT * 1.5, /datum/material/silver = SMALL_MATERIAL_AMOUNT*1.5, /datum/material/glass =SHEET_MATERIAL_AMOUNT * 1.5, /datum/material/bluespace =SMALL_MATERIAL_AMOUNT * 3)
	build_path = /obj/item/lightreplacer/blue
	category = list(
		RND_CATEGORY_TOOLS + RND_SUBCATEGORY_TOOLS_JANITORIAL
	)
	departmental_flags = DEPARTMENT_BITFLAG_SERVICE | DEPARTMENT_BITFLAG_ENGINEERING

/datum/design/buffer_upgrade
	name = "Floor Buffer Upgrade"
	desc = "A floor buffer that can be attached to vehicular janicarts."
	id = "buffer"
	build_type = PROTOLATHE | AWAY_LATHE
	materials = list(/datum/material/iron =SHEET_MATERIAL_AMOUNT * 1.5, /datum/material/glass =SMALL_MATERIAL_AMOUNT * 2)
	build_path = /obj/item/janicart_upgrade/buffer
	category = list(
		RND_CATEGORY_EQUIPMENT + RND_SUBCATEGORY_EQUIPMENT_JANITOR
	)
	departmental_flags = DEPARTMENT_BITFLAG_SERVICE

/datum/design/vacuum_upgrade
	name = "Vacuum Upgrade"
	desc = "A vacuum that can be attached to vehicular janicarts."
	id = "vacuum"
	build_type = PROTOLATHE | AWAY_LATHE
	materials = list(/datum/material/iron =SHEET_MATERIAL_AMOUNT * 1.5, /datum/material/glass =SMALL_MATERIAL_AMOUNT * 2)
	build_path = /obj/item/janicart_upgrade/vacuum
	category = list(
		RND_CATEGORY_EQUIPMENT + RND_SUBCATEGORY_EQUIPMENT_JANITOR
	)
	departmental_flags = DEPARTMENT_BITFLAG_SERVICE

/datum/design/paint_remover
	name = "Paint Remover"
	desc = "Removes stains from the floor, and not much else."
	id = "paint_remover"
	build_type = PROTOLATHE | AWAY_LATHE
	materials = list(/datum/material/iron =HALF_SHEET_MATERIAL_AMOUNT)
	build_path = /obj/item/paint/paint_remover
	category = list(
		RND_CATEGORY_TOOLS + RND_SUBCATEGORY_TOOLS_JANITORIAL
	)
	departmental_flags = DEPARTMENT_BITFLAG_SERVICE

/datum/design/spraybottle
	name = "Spray Bottle"
	desc = "A spray bottle, with an unscrewable top."
	id = "spraybottle"
	build_type = PROTOLATHE | AWAY_LATHE
	materials = list(/datum/material/iron =SHEET_MATERIAL_AMOUNT * 1.5, /datum/material/glass =SMALL_MATERIAL_AMOUNT * 2)
	build_path = /obj/item/reagent_containers/spray
	category = list(
		RND_CATEGORY_TOOLS + RND_SUBCATEGORY_TOOLS_JANITORIAL
	)
	departmental_flags = DEPARTMENT_BITFLAG_SERVICE

/datum/design/beartrap
	name = "Bear Trap"
	desc = "A trap used to catch space bears and other legged creatures."
	id = "beartrap"
	build_type = PROTOLATHE | AWAY_LATHE
	materials = list(/datum/material/iron =SHEET_MATERIAL_AMOUNT * 2.5, /datum/material/titanium =HALF_SHEET_MATERIAL_AMOUNT)
	build_path = /obj/item/restraints/legcuffs/beartrap
	category = list(
		RND_CATEGORY_TOOLS + RND_SUBCATEGORY_TOOLS_JANITORIAL
	)
	departmental_flags = DEPARTMENT_BITFLAG_SERVICE


// Hydroponics

/datum/design/adv_watering_can
	name = "Advanced Watering Can"
	id = "adv_watering_can"
	build_type = PROTOLATHE | AWAY_LATHE
	materials = list(/datum/material/iron = HALF_SHEET_MATERIAL_AMOUNT*2.5, /datum/material/glass =SMALL_MATERIAL_AMOUNT * 2)
	category = list(
		RND_CATEGORY_TOOLS + RND_SUBCATEGORY_TOOLS_BOTANY_ADVANCED
	)
	build_path = /obj/item/reagent_containers/cup/watering_can/advanced
	departmental_flags = DEPARTMENT_BITFLAG_SERVICE

// Holobarriers

/datum/design/holosign
	name = "Holographic Sign Projector"
	desc = "A holographic projector used to project various warning signs."
	id = "holosign"
	build_type = PROTOLATHE | AWAY_LATHE
	materials = list(/datum/material/iron =SHEET_MATERIAL_AMOUNT, /datum/material/glass =HALF_SHEET_MATERIAL_AMOUNT)
	build_path = /obj/item/holosign_creator
	category = list(
		RND_CATEGORY_EQUIPMENT + RND_SUBCATEGORY_EQUIPMENT_SERVICE
	)
	departmental_flags = DEPARTMENT_BITFLAG_SERVICE

/datum/design/holobarrier_jani
	name = "Custodial Holobarrier Projector"
	desc = "A holographic projector used to project hard light wet floor barriers."
	id = "holobarrier_jani"
	build_type = PROTOLATHE | AWAY_LATHE
	materials = list(/datum/material/iron =SHEET_MATERIAL_AMOUNT, /datum/material/glass =HALF_SHEET_MATERIAL_AMOUNT, /datum/material/silver =HALF_SHEET_MATERIAL_AMOUNT)
	build_path = /obj/item/holosign_creator/janibarrier
	category = list(
		RND_CATEGORY_TOOLS + RND_SUBCATEGORY_TOOLS_JANITORIAL
	)
	departmental_flags = DEPARTMENT_BITFLAG_SERVICE

/datum/design/holosignsec
	name = "Security Holobarrier Projector"
	desc = "A holographic projector that creates holographic security barriers."
	id = "holosignsec"
	build_type = PROTOLATHE | AWAY_LATHE
	materials = list(/datum/material/iron =SHEET_MATERIAL_AMOUNT * 2.5, /datum/material/glass =HALF_SHEET_MATERIAL_AMOUNT, /datum/material/gold =HALF_SHEET_MATERIAL_AMOUNT, /datum/material/silver =HALF_SHEET_MATERIAL_AMOUNT)
	build_path = /obj/item/holosign_creator/security
	category = list(
		RND_CATEGORY_TOOLS + RND_SUBCATEGORY_TOOLS_SECURITY
	)
	departmental_flags = DEPARTMENT_BITFLAG_SECURITY

/datum/design/holosignengi
	name = "Engineering Holobarrier Projector"
	desc = "A holographic projector that creates holographic engineering barriers."
	id = "holosignengi"
	build_type = PROTOLATHE | AWAY_LATHE
	materials = list(/datum/material/iron =SHEET_MATERIAL_AMOUNT * 2.5, /datum/material/glass =HALF_SHEET_MATERIAL_AMOUNT, /datum/material/gold =HALF_SHEET_MATERIAL_AMOUNT, /datum/material/silver =HALF_SHEET_MATERIAL_AMOUNT)
	build_path = /obj/item/holosign_creator/engineering
	category = list(
		RND_CATEGORY_TOOLS + RND_SUBCATEGORY_TOOLS_ENGINEERING
	)
	departmental_flags = DEPARTMENT_BITFLAG_ENGINEERING

/datum/design/holosignatmos
	name = "ATMOS Holofan Projector"
	desc = "A holographic projector that creates holographic barriers that prevent changes in atmospheric conditions."
	id = "holosignatmos"
	build_type = PROTOLATHE | AWAY_LATHE
	materials = list(/datum/material/iron =SHEET_MATERIAL_AMOUNT * 2.5, /datum/material/glass =HALF_SHEET_MATERIAL_AMOUNT, /datum/material/gold =HALF_SHEET_MATERIAL_AMOUNT, /datum/material/silver =HALF_SHEET_MATERIAL_AMOUNT)
	build_path = /obj/item/holosign_creator/atmos
	category = list(
		RND_CATEGORY_TOOLS + RND_SUBCATEGORY_TOOLS_ATMOSPHERICS
	)
	departmental_flags = DEPARTMENT_BITFLAG_ENGINEERING

/datum/design/holobarrier_med
	name = "PENLITE Holobarrier Projector"
	desc = "PENLITE holobarriers, a device that halts individuals with malicious diseases."
	build_type = PROTOLATHE | AWAY_LATHE
	build_path = /obj/item/holosign_creator/medical
	materials = list(/datum/material/iron =SMALL_MATERIAL_AMOUNT*5, /datum/material/glass =SMALL_MATERIAL_AMOUNT*5, /datum/material/silver =SMALL_MATERIAL_AMOUNT) //a hint of silver since it can troll 2 antags (bad viros and sentient disease)
	id = "holobarrier_med"
	category = list(
		RND_CATEGORY_TOOLS + RND_SUBCATEGORY_TOOLS_MEDICAL
	)
	departmental_flags = DEPARTMENT_BITFLAG_MEDICAL

// Armour

/datum/design/reactive_armour
	name = "Reactive Armor Shell"
	desc = "An experimental suit of armour capable of utilizing an implanted anomaly core to protect the user."
	id = "reactive_armour"
	build_type = PROTOLATHE | AWAY_LATHE
	materials = list(
		/datum/material/iron = SHEET_MATERIAL_AMOUNT*5,
		/datum/material/uranium = SHEET_MATERIAL_AMOUNT*4,
		/datum/material/diamond = SHEET_MATERIAL_AMOUNT * 2.5,
		/datum/material/silver = SHEET_MATERIAL_AMOUNT*2.5,
		/datum/material/gold = SHEET_MATERIAL_AMOUNT * 2.5,
	)
	build_path = /obj/item/reactive_armor_shell
	category = list(
		RND_CATEGORY_EQUIPMENT + RND_SUBCATEGORY_EQUIPMENT_SCIENCE
	)
	departmental_flags = DEPARTMENT_BITFLAG_SCIENCE

/datum/design/knight_armour
	name = "Knight Armour"
	desc = "A royal knight's favorite garments. Can be trimmed by any friendly person."
	id = "knight_armour"
	build_type = AUTOLATHE
	materials = list(MAT_CATEGORY_ITEM_MATERIAL = SHEET_MATERIAL_AMOUNT*5)
	build_path = /obj/item/clothing/suit/armor/riot/knight/greyscale
	category = list(RND_CATEGORY_IMPORTED)

/datum/design/knight_helmet
	name = "Knight Helmet"
	desc = "A royal knight's favorite hat. If you hold it upside down it's actually a bucket."
	id = "knight_helmet"
	build_type = AUTOLATHE
	materials = list(MAT_CATEGORY_ITEM_MATERIAL = SHEET_MATERIAL_AMOUNT*2.5)
	build_path = /obj/item/clothing/head/helmet/knight/greyscale
	category = list(RND_CATEGORY_IMPORTED)

// Security

/datum/design/seclite
	name = "Seclite"
	desc = "A robust flashlight used by security."
	id = "seclite"
	build_type = PROTOLATHE | AWAY_LATHE
	materials = list(/datum/material/iron = HALF_SHEET_MATERIAL_AMOUNT*2.5)
	build_path = /obj/item/flashlight/seclite
	category = list(
		RND_CATEGORY_EQUIPMENT + RND_SUBCATEGORY_EQUIPMENT_SECURITY
	)
	departmental_flags = DEPARTMENT_BITFLAG_SECURITY

/datum/design/pepperspray
	name = "Pepper Spray"
	desc = "Manufactured by UhangInc, used to blind and down an opponent quickly. Printed pepper sprays do not contain reagents."
	id = "pepperspray"
	build_type = PROTOLATHE | AWAY_LATHE
	materials = list(/datum/material/iron =SHEET_MATERIAL_AMOUNT * 2.5, /datum/material/glass =HALF_SHEET_MATERIAL_AMOUNT)
	build_path = /obj/item/reagent_containers/spray/pepper/empty
	category = list(
		RND_CATEGORY_EQUIPMENT + RND_SUBCATEGORY_EQUIPMENT_SECURITY
	)
	departmental_flags = DEPARTMENT_BITFLAG_SECURITY

/datum/design/bola_energy
	name = "Energy Bola"
	desc = "A specialized hard-light bola designed to ensnare fleeing criminals and aid in arrests."
	id = "bola_energy"
	build_type = PROTOLATHE | AWAY_LATHE
	materials = list(/datum/material/silver =SMALL_MATERIAL_AMOUNT*5, /datum/material/plasma =SMALL_MATERIAL_AMOUNT*5, /datum/material/titanium =SMALL_MATERIAL_AMOUNT*5)
	build_path = /obj/item/restraints/legcuffs/bola/energy
	category = list(
		RND_CATEGORY_EQUIPMENT + RND_SUBCATEGORY_EQUIPMENT_SECURITY
	)
	departmental_flags = DEPARTMENT_BITFLAG_SECURITY
	autolathe_exportable = FALSE

/datum/design/zipties
	name = "Zipties"
	desc = "Plastic, disposable zipties that can be used to restrain temporarily but are destroyed after use."
	id = "zipties"
	build_type = PROTOLATHE | AWAY_LATHE
	materials = list(/datum/material/plastic = SMALL_MATERIAL_AMOUNT*2.5)
	build_path = /obj/item/restraints/handcuffs/cable/zipties
	category = list(
		RND_CATEGORY_EQUIPMENT + RND_SUBCATEGORY_EQUIPMENT_SECURITY
	)
	departmental_flags = DEPARTMENT_BITFLAG_SECURITY

/datum/design/evidencebag
	name = "Evidence Bag"
	desc = "An empty evidence bag."
	id = "evidencebag"
	build_type = PROTOLATHE | AWAY_LATHE
	materials = list(/datum/material/plastic =SMALL_MATERIAL_AMOUNT)
	build_path = /obj/item/evidencebag
	category = list(
		RND_CATEGORY_EQUIPMENT + RND_SUBCATEGORY_EQUIPMENT_SECURITY
	)
	departmental_flags = DEPARTMENT_BITFLAG_SECURITY


/datum/design/dragnet_beacon
	name = "DRAGnet Beacon"
	desc = "A beacon that can be used as a teleport destination for DRAGnet snare rounds. Remember to sync it with your DRAGnet first!"
	id = "dragnet_beacon"
	build_type = PROTOLATHE | AWAY_LATHE
	materials = list(/datum/material/iron = SHEET_MATERIAL_AMOUNT * 5, /datum/material/glass = SHEET_MATERIAL_AMOUNT * 2)
	build_path = /obj/item/dragnet_beacon
	category = list(
		RND_CATEGORY_EQUIPMENT + RND_SUBCATEGORY_EQUIPMENT_SECURITY
	)
	departmental_flags = DEPARTMENT_BITFLAG_SECURITY

/datum/design/inspector
	name = "N-Spect Scanner"
	desc = "Central Command-issued inspection device. Performs inspections according to Nanotrasen protocols when activated, then prints an encrypted report regarding the maintenance of the station. Definitely not giving you cancer."
	id = "inspector"
	build_type = PROTOLATHE | AWAY_LATHE
	materials = list(/datum/material/iron =SHEET_MATERIAL_AMOUNT * 2.5, /datum/material/glass =HALF_SHEET_MATERIAL_AMOUNT, /datum/material/gold =HALF_SHEET_MATERIAL_AMOUNT, /datum/material/uranium =SHEET_MATERIAL_AMOUNT)
	build_path = /obj/item/inspector
	category = list(
		RND_CATEGORY_EQUIPMENT + RND_SUBCATEGORY_EQUIPMENT_SECURITY
	)
	departmental_flags = DEPARTMENT_BITFLAG_SECURITY

/datum/design/sec_pen
	name = "Security Pen"
	id = "sec_pen"
	build_type = PROTOLATHE | AUTOLATHE
	materials = list(/datum/material/iron =SMALL_MATERIAL_AMOUNT)
	build_path = /obj/item/pen/red/security
	category = list(
		RND_CATEGORY_EQUIPMENT + RND_SUBCATEGORY_EQUIPMENT_SECURITY
	)
	departmental_flags = DEPARTMENT_BITFLAG_SECURITY

/datum/design/plumbing_rcd
	name = "Plumbing Constructor"
	id = "plumbing_rcd"
	build_type = PROTOLATHE | AWAY_LATHE
	materials = list(/datum/material/iron = SHEET_MATERIAL_AMOUNT*38, /datum/material/glass = SHEET_MATERIAL_AMOUNT*18, /datum/material/plastic =HALF_SHEET_MATERIAL_AMOUNT)
	build_path = /obj/item/construction/plumbing
	category = list(
		RND_CATEGORY_TOOLS + RND_SUBCATEGORY_TOOLS_PLUMBING
	)
	departmental_flags = DEPARTMENT_BITFLAG_MEDICAL

/datum/design/gas_filter
	name = "Gas Filter"
	id = "gas_filter"
	build_type = PROTOLATHE | AUTOLATHE
	materials = list(/datum/material/iron =SMALL_MATERIAL_AMOUNT)
	build_path = /obj/item/gas_filter
	category = list(
		RND_CATEGORY_EQUIPMENT + RND_SUBCATEGORY_EQUIPMENT_GAS_TANKS_EQUIPMENT
	)
	departmental_flags = ALL

/datum/design/plasmaman_gas_filter
	name = "Plasmaman Gas Filter"
	id = "plasmaman_gas_filter"
	build_type = PROTOLATHE | AUTOLATHE
	materials = list(/datum/material/iron =SMALL_MATERIAL_AMOUNT)
	build_path = /obj/item/gas_filter/plasmaman
	category = list(
		RND_CATEGORY_EQUIPMENT + RND_SUBCATEGORY_EQUIPMENT_GAS_TANKS_EQUIPMENT
	)
	departmental_flags = ALL

// Tape

/datum/design/super_sticky_tape
	name = "Super Sticky Tape"
	id = "super_sticky_tape"
	build_type = PROTOLATHE | AWAY_LATHE
	materials = list(/datum/material/plastic =SHEET_MATERIAL_AMOUNT * 1.5)
	build_path = /obj/item/stack/sticky_tape/super
	category = list(
		RND_CATEGORY_EQUIPMENT + RND_SUBCATEGORY_EQUIPMENT_SERVICE
	)
	departmental_flags = DEPARTMENT_BITFLAG_SERVICE

/datum/design/pointy_tape
	name = "Pointy Tape"
	id = "pointy_tape"
	build_type = PROTOLATHE | AWAY_LATHE
	materials = list(/datum/material/iron =HALF_SHEET_MATERIAL_AMOUNT * 1.5, /datum/material/plastic =HALF_SHEET_MATERIAL_AMOUNT)
	build_path = /obj/item/stack/sticky_tape/pointy
	category = list(
		RND_CATEGORY_EQUIPMENT + RND_SUBCATEGORY_EQUIPMENT_SERVICE
	)
	departmental_flags = DEPARTMENT_BITFLAG_SERVICE

/datum/design/super_pointy_tape
	name = "Super Pointy Tape"
	id = "super_pointy_tape"
	build_type = PROTOLATHE | AWAY_LATHE
	materials = list(/datum/material/iron =SHEET_MATERIAL_AMOUNT * 1.5, /datum/material/plastic =SHEET_MATERIAL_AMOUNT)
	build_path = /obj/item/stack/sticky_tape/pointy/super
	category = list(
		RND_CATEGORY_EQUIPMENT + RND_SUBCATEGORY_EQUIPMENT_SERVICE
	)
	departmental_flags = DEPARTMENT_BITFLAG_SERVICE

// Tackle Gloves

/datum/design/tackle_dolphin
	name = "Dolphin Gloves"
	id = "tackle_dolphin"
	build_type = PROTOLATHE | AWAY_LATHE
	materials = list(/datum/material/plastic = HALF_SHEET_MATERIAL_AMOUNT*2.5)
	build_path = /obj/item/clothing/gloves/tackler/dolphin
	category = list(
		RND_CATEGORY_EQUIPMENT + RND_SUBCATEGORY_EQUIPMENT_SECURITY
	)
	departmental_flags = DEPARTMENT_BITFLAG_SECURITY

/datum/design/tackle_rocket
	name = "Rocket Gloves"
	id = "tackle_rocket"
	build_type = PROTOLATHE | AWAY_LATHE
	materials = list(/datum/material/plasma =HALF_SHEET_MATERIAL_AMOUNT, /datum/material/plastic =SHEET_MATERIAL_AMOUNT)
	build_path = /obj/item/clothing/gloves/tackler/rocket
	category = list(
		RND_CATEGORY_EQUIPMENT + RND_SUBCATEGORY_EQUIPMENT_SECURITY
	)
	departmental_flags = DEPARTMENT_BITFLAG_SECURITY

// Restaurant Equipment

/datum/design/holosign/restaurant
	name = "Restaurant Seating Projector"
	desc = "A holographic projector that creates seating designation for restaurants."
	id = "holosignrestaurant"
	build_type = PROTOLATHE
	materials = list(/datum/material/iron =SHEET_MATERIAL_AMOUNT, /datum/material/glass =HALF_SHEET_MATERIAL_AMOUNT)
	build_path = /obj/item/holosign_creator/robot_seat/restaurant
	category = list(
		RND_CATEGORY_TOOLS + RND_SUBCATEGORY_TOOLS_SERVICE
	)
	departmental_flags = DEPARTMENT_BITFLAG_SERVICE

/datum/design/holosign/bar
	name = "Bar Seating Projector"
	desc = "A holographic projector that creates seating designation for bars."
	id = "holosignbar"
	build_type = PROTOLATHE
	materials = list(/datum/material/iron =SHEET_MATERIAL_AMOUNT, /datum/material/glass =HALF_SHEET_MATERIAL_AMOUNT)
	build_path = /obj/item/holosign_creator/robot_seat/bar
	category = list(
		RND_CATEGORY_TOOLS + RND_SUBCATEGORY_TOOLS_SERVICE
	)
	departmental_flags = DEPARTMENT_BITFLAG_SERVICE

/datum/design/oven_tray
	name = "Oven Tray"
	desc = "Gotta shove something in!"
	id = "oven_tray"
	build_type = AUTOLATHE | PROTOLATHE | AWAY_LATHE
	materials = list(/datum/material/iron =SMALL_MATERIAL_AMOUNT*5)
	build_path = /obj/item/plate/oven_tray
	category = list(
		RND_CATEGORY_EQUIPMENT + RND_SUBCATEGORY_EQUIPMENT_KITCHEN
	)
	departmental_flags = DEPARTMENT_BITFLAG_SERVICE

// Fishing Equipment

/datum/design/fishing_rod_tech
	name = "Advanced Fishing Rod"
	desc = "A fishing rod with an embedded generator dispensing an infinite supply of fishing baits."
	id = "fishing_rod_tech"
	build_type = PROTOLATHE | AWAY_LATHE
	materials = list(/datum/material/uranium =HALF_SHEET_MATERIAL_AMOUNT, /datum/material/plastic =SHEET_MATERIAL_AMOUNT)
	build_path = /obj/item/fishing_rod/tech
	category = list(
		RND_CATEGORY_EQUIPMENT + RND_SUBCATEGORY_EQUIPMENT_SERVICE
	)
	departmental_flags = DEPARTMENT_BITFLAG_SERVICE | DEPARTMENT_BITFLAG_CARGO | DEPARTMENT_BITFLAG_SCIENCE

/datum/design/fishing_gloves
	name = "Athletic Fishing Gloves"
	desc = "A pair of gloves to fish without a fishing rod and train your athletics with."
	id = "fishing_gloves"
	build_type = PROTOLATHE | AWAY_LATHE
	materials = list(/datum/material/iron = HALF_SHEET_MATERIAL_AMOUNT, /datum/material/plastic = SHEET_MATERIAL_AMOUNT)
	build_path = /obj/item/clothing/gloves/fishing
	category = list(
		RND_CATEGORY_EQUIPMENT + RND_SUBCATEGORY_EQUIPMENT_SERVICE
	)
	departmental_flags = DEPARTMENT_BITFLAG_SERVICE | DEPARTMENT_BITFLAG_CARGO | DEPARTMENT_BITFLAG_SCIENCE

/datum/design/stabilized_hook
	name = "Gyro-Stabilized Hook"
	desc = "An advanced fishing hook that gives the user a tighter control on the fish when reeling in."
	id = "stabilized_hook"
	build_type = PROTOLATHE | AWAY_LATHE
	materials = list(/datum/material/iron = SMALL_MATERIAL_AMOUNT * 5, /datum/material/gold = SMALL_MATERIAL_AMOUNT * 3, /datum/material/titanium = SMALL_MATERIAL_AMOUNT * 2)
	build_path = /obj/item/fishing_hook/stabilized
	category = list(
		RND_CATEGORY_EQUIPMENT + RND_SUBCATEGORY_EQUIPMENT_SERVICE
	)
	departmental_flags = DEPARTMENT_BITFLAG_SERVICE | DEPARTMENT_BITFLAG_CARGO | DEPARTMENT_BITFLAG_SCIENCE

/datum/design/auto_reel
	name = "Fishing Line Auto-Reel"
	desc = "An advanced line reel which can be used speed up fishing or casually snag other items in your direction."
	id = "auto_reel"
	build_type = PROTOLATHE | AWAY_LATHE
	materials = list(/datum/material/iron = SMALL_MATERIAL_AMOUNT * 4, /datum/material/gold = SMALL_MATERIAL_AMOUNT * 3, /datum/material/silver = SMALL_MATERIAL_AMOUNT * 3)
	build_path = /obj/item/fishing_line/auto_reel
	category = list(
		RND_CATEGORY_EQUIPMENT + RND_SUBCATEGORY_EQUIPMENT_SERVICE
	)
	departmental_flags = DEPARTMENT_BITFLAG_SERVICE | DEPARTMENT_BITFLAG_CARGO | DEPARTMENT_BITFLAG_SCIENCE

/datum/design/fish_analyzer
	name = "Fish Analyzer"
	desc = "An analyzer used to monitor fish's status and traits with."
	id = "fish_analyzer"
	build_type = PROTOLATHE | AWAY_LATHE
	materials = list(/datum/material/iron = SMALL_MATERIAL_AMOUNT * 5, /datum/material/glass = SMALL_MATERIAL_AMOUNT * 0.5)
	build_path = /obj/item/fish_analyzer
	category = list(
		RND_CATEGORY_EQUIPMENT + RND_SUBCATEGORY_EQUIPMENT_SERVICE
	)
	departmental_flags = DEPARTMENT_BITFLAG_SERVICE | DEPARTMENT_BITFLAG_CARGO | DEPARTMENT_BITFLAG_SCIENCE

/datum/design/bluespace_fish_case
	name = "Bluespace Fish Case"
	desc = "An improved fish case to keep large fish in stasis in a compact little space."
	id = "bluespace_fish_case"
	build_type = PROTOLATHE | AWAY_LATHE
	materials = list(/datum/material/iron = SMALL_MATERIAL_AMOUNT, /datum/material/plastic = SMALL_MATERIAL_AMOUNT, /datum/material/bluespace = SMALL_MATERIAL_AMOUNT)
	build_path = /obj/item/storage/fish_case/bluespace
	category = list(
		RND_CATEGORY_EQUIPMENT + RND_SUBCATEGORY_EQUIPMENT_SERVICE
	)
	departmental_flags = DEPARTMENT_BITFLAG_SERVICE | DEPARTMENT_BITFLAG_CARGO | DEPARTMENT_BITFLAG_SCIENCE

/datum/design/bluespace_fish_tank
	name = "Bluespace Fish Tank Kit"
	desc = "The required components to upgrade the capacity of a fish tank."
	id = "bluespace_fish_tank_kit"
	build_type = PROTOLATHE | AWAY_LATHE
	materials = list(/datum/material/iron = SMALL_MATERIAL_AMOUNT * 3, /datum/material/titanium = SMALL_MATERIAL_AMOUNT, /datum/material/bluespace = SMALL_MATERIAL_AMOUNT * 3)
	build_path = /obj/item/aquarium_upgrade/bluespace_tank
	category = list(
		RND_CATEGORY_MACHINE + RND_SUBCATEGORY_MACHINE_SERVICE,
	)
	departmental_flags = DEPARTMENT_BITFLAG_SERVICE | DEPARTMENT_BITFLAG_CARGO | DEPARTMENT_BITFLAG_SCIENCE

// Coffeemaker Stuff

/datum/design/coffeepot
	name = "Coffeepot"
	id = "coffeepot"
	build_type = PROTOLATHE | AWAY_LATHE
	materials = list(/datum/material/glass =SMALL_MATERIAL_AMOUNT*5, /datum/material/plastic =SMALL_MATERIAL_AMOUNT*5)
	build_path = /obj/item/reagent_containers/cup/coffeepot
	category = list(
		RND_CATEGORY_EQUIPMENT + RND_SUBCATEGORY_EQUIPMENT_KITCHEN
	)
	departmental_flags = DEPARTMENT_BITFLAG_SERVICE

/datum/design/coffeepot_bluespace
	name = "Bluespace Coffeepot"
	id = "bluespace_coffeepot"
	build_type = PROTOLATHE | AWAY_LATHE
	materials = list(/datum/material/iron =HALF_SHEET_MATERIAL_AMOUNT, /datum/material/plastic =SMALL_MATERIAL_AMOUNT*5, /datum/material/bluespace =SMALL_MATERIAL_AMOUNT*5)
	build_path = /obj/item/reagent_containers/cup/coffeepot/bluespace
	category = list(
		RND_CATEGORY_EQUIPMENT + RND_SUBCATEGORY_EQUIPMENT_KITCHEN
	)
	departmental_flags = DEPARTMENT_BITFLAG_SERVICE

/datum/design/coffee_cartridge
	name = "Blank Coffee Cartridge"
	id = "coffee_cartridge"
	build_type = PROTOLATHE | AWAY_LATHE
	materials = list(/datum/material/plastic =HALF_SHEET_MATERIAL_AMOUNT)
	build_path = /obj/item/blank_coffee_cartridge
	category = list(
		RND_CATEGORY_EQUIPMENT + RND_SUBCATEGORY_EQUIPMENT_KITCHEN
	)
	departmental_flags = DEPARTMENT_BITFLAG_SERVICE

/datum/design/syrup_bottle
	name = "Syrup bottle"
	id = "syrup_bottle"
	build_type = PROTOLATHE | AWAY_LATHE
	materials = list(/datum/material/plastic =HALF_SHEET_MATERIAL_AMOUNT)
	build_path = /obj/item/reagent_containers/cup/bottle/syrup_bottle
	category = list(
		RND_CATEGORY_EQUIPMENT + RND_SUBCATEGORY_EQUIPMENT_KITCHEN
	)
	departmental_flags = DEPARTMENT_BITFLAG_SERVICE

/datum/design/radio_navigation_beacon
	name = "Compact Radio Navigation Gigabeacon"
	id = "gigabeacon"
	build_type = PROTOLATHE | AWAY_LATHE
	materials = list(/datum/material/iron = SHEET_MATERIAL_AMOUNT * 2,
		/datum/material/glass = HALF_SHEET_MATERIAL_AMOUNT)
	build_path = /obj/item/folded_navigation_gigabeacon
	category = list(
		RND_CATEGORY_EQUIPMENT + RND_SUBCATEGORY_EQUIPMENT_ENGINEERING
	)
	departmental_flags = DEPARTMENT_BITFLAG_ENGINEERING | DEPARTMENT_BITFLAG_SCIENCE | DEPARTMENT_BITFLAG_CARGO

/datum/design/shuttle_rods
	name = "Shuttle Frame Rods"
	id = "shuttlerods"
	build_type = PROTOLATHE
	materials = list(/datum/material/iron =HALF_SHEET_MATERIAL_AMOUNT, /datum/material/titanium = SMALL_MATERIAL_AMOUNT)
	build_path = /obj/item/stack/rods/shuttle
	category = list(
		RND_CATEGORY_CONSTRUCTION + RND_SUBCATEGORY_CONSTRUCTION_MATERIALS
	)
	departmental_flags = DEPARTMENT_BITFLAG_CARGO | DEPARTMENT_BITFLAG_SCIENCE | DEPARTMENT_BITFLAG_ENGINEERING

// Experimental designs

/datum/design/polymorph_belt
	name = "Polymorphic Field Inverter"
	id = "polymorph_belt"
	desc = "This device can scan and store DNA from other life forms, and use it to transform its wearer. It requires a Bioscrambler Anomaly Core in order to function."
	build_type = PROTOLATHE | AWAY_LATHE
	build_path = /obj/item/polymorph_belt
	materials = list(
		/datum/material/silver = SHEET_MATERIAL_AMOUNT * 2,
		/datum/material/uranium = SHEET_MATERIAL_AMOUNT,
		/datum/material/diamond = SHEET_MATERIAL_AMOUNT,
	)
	category = list(
		RND_CATEGORY_EQUIPMENT + RND_SUBCATEGORY_EQUIPMENT_SCIENCE
	)
	departmental_flags = DEPARTMENT_BITFLAG_SCIENCE

/datum/design/perceptomatrix
	name = "Perceptomatrix Helm"
	id = "perceptomatrix"
	desc = "This helm harnesses hallucinatory energies to shield its owner from perceptual anomalies. It requires a Hallucination Anomaly Core in order to function."
	build_type = PROTOLATHE | AWAY_LATHE
	build_path = /obj/item/clothing/head/helmet/perceptomatrix
	materials = list(
		/datum/material/titanium = SHEET_MATERIAL_AMOUNT * 2,
		/datum/material/silver = SHEET_MATERIAL_AMOUNT * 1,
		/datum/material/gold = SHEET_MATERIAL_AMOUNT * 0.5,
		/datum/material/plasma = SHEET_MATERIAL_AMOUNT * 3,
		/datum/material/uranium = SHEET_MATERIAL_AMOUNT,
	)
	category = list(
		RND_CATEGORY_EQUIPMENT + RND_SUBCATEGORY_EQUIPMENT_SCIENCE
	)
	departmental_flags = DEPARTMENT_BITFLAG_SCIENCE
