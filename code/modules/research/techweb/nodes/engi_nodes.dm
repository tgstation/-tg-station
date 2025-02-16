// Parts root node
/datum/techweb_node/parts
	id = TECHWEB_NODE_PARTS
	starting_node = TRUE
	display_name = "Essential Stock Parts"
	description = "Foundational components that form the backbone of station operations, encompassing a range of essential equipment necessary for day-to-day functionality."
	design_ids = list(
		"micro_servo",
		"basic_battery",
		"basic_capacitor",
		"basic_cell",
		"basic_matter_bin",
		"basic_micro_laser",
		"basic_scanning",
		"high_battery",
		"high_cell",
		"miniature_power_cell",
		"condenser",
		"igniter",
		"infrared_emitter",
		"prox_sensor",
		"signaler",
		"timer",
		"voice_analyzer",
		"health_sensor",
		"sflash",
	)

/datum/techweb_node/parts_upg
	id = TECHWEB_NODE_PARTS_UPG
	display_name = "Upgraded Parts"
	description = "Offering enhanced capabilities beyond their basic counterparts."
	prereq_ids = list(TECHWEB_NODE_PARTS, TECHWEB_NODE_ENERGY_MANIPULATION)
	design_ids = list(
		"rped",
		"high_micro_laser",
		"adv_capacitor",
		"nano_servo",
		"adv_matter_bin",
		"adv_scanning",
		"super_battery",
		"super_cell",
	)
	research_costs = list(TECHWEB_POINT_TYPE_GENERIC = TECHWEB_TIER_2_POINTS)
	announce_channels = list(RADIO_CHANNEL_ENGINEERING)

/datum/techweb_node/parts_adv
	id = TECHWEB_NODE_PARTS_ADV
	display_name = "Advanced Parts"
	description = "The most finely tuned and accurate stock parts."
	prereq_ids = list(TECHWEB_NODE_PARTS_UPG)
	design_ids = list(
		"ultra_micro_laser",
		"super_capacitor",
		"pico_servo",
		"super_matter_bin",
		"phasic_scanning",
		"hyper_battery",
		"hyper_cell",
	)
	research_costs = list(TECHWEB_POINT_TYPE_GENERIC = TECHWEB_TIER_3_POINTS)
	required_experiments = list(/datum/experiment/scanning/points/machinery_tiered_scan/tier2_any)
	announce_channels = list(RADIO_CHANNEL_ENGINEERING)


/datum/techweb_node/parts_bluespace
	id = TECHWEB_NODE_PARTS_BLUESPACE
	display_name = "Bluespace Parts"
	description = "Integrating the latest in bluespace technology, these advanced components not only enhance functionality but also open up new possibilities for the station's technological capabilities."
	prereq_ids = list(TECHWEB_NODE_PARTS_ADV, TECHWEB_NODE_BLUESPACE_TRAVEL)
	design_ids = list(
		"bs_rped",
		"quadultra_micro_laser",
		"quadratic_capacitor",
		"femto_servo",
		"bluespace_matter_bin",
		"triphasic_scanning",
		"bluespace_battery",
		"bluespace_cell",
	)
	research_costs = list(TECHWEB_POINT_TYPE_GENERIC = TECHWEB_TIER_4_POINTS)
	discount_experiments = list(/datum/experiment/scanning/points/machinery_tiered_scan/tier3_any = TECHWEB_TIER_4_POINTS)
	announce_channels = list(RADIO_CHANNEL_ENGINEERING)

/datum/techweb_node/telecomms
	id = TECHWEB_NODE_TELECOMS
	display_name = "Telecommunications Technology"
	description = "A comprehensive suite of machinery for station-wide communication setups, ensuring seamless connectivity and operational coordination."
	prereq_ids = list(TECHWEB_NODE_PARTS_BLUESPACE)
	design_ids = list(
		"comm_monitor",
		"comm_server",
		"message_monitor",
		"ntnet_relay",
		"s_hub",
		"s_messaging",
		"s_server",
		"s_processor",
		"s_relay",
		"s_bus",
		"s_broadcaster",
		"s_receiver",
		"s_amplifier",
		"s_analyzer",
		"s_ansible",
		"s_crystal",
		"s_filter",
		"s_transmitter",
		"s_treatment",
	)
	research_costs = list(TECHWEB_POINT_TYPE_GENERIC = TECHWEB_TIER_5_POINTS)

// Engineering root node
/datum/techweb_node/construction
	id = TECHWEB_NODE_CONSTRUCTION
	starting_node = TRUE
	display_name = "Construction"
	description = "Tools and essential machinery used for station maintenance and expansion."
	design_ids = list(
		"circuit_imprinter_offstation",
		"circuit_imprinter",
		"solarcontrol",
		"solar_panel",
		"solar_tracker",
		"power_control",
		"airalarm_electronics",
		"airlock_board",
		"firealarm_electronics",
		"firelock_board",
		"trapdoor_electronics",
		"blast",
		"big_manipulator",
		"tile_sprayer",
		"airlock_painter",
		"decal_painter",
		"rwd",
		"cable_coil",
		"welding_helmet",
		"welding_tool",
		"tscanner",
		"analyzer",
		"multitool",
		"wrench",
		"crowbar",
		"screwdriver",
		"wirecutters",
		"light_bulb",
		"light_tube",
		"crossing_signal",
		"guideway_sensor",
		"manuunloader",
		"manusmelter",
		"manucrusher",
		"manucrafter",
		"manulathe",
		"manusorter",
		"manurouter",
		"mailsorter",
	)

/datum/techweb_node/energy_manipulation
	id = TECHWEB_NODE_ENERGY_MANIPULATION
	display_name = "Energy Manipulation"
	description = "Harnessing the raw power of lightning arcs through sophisticated energy control methods."
	prereq_ids = list(TECHWEB_NODE_CONSTRUCTION)
	design_ids = list(
		"apc_control",
		"powermonitor",
		"smes",
		"portable_smes",
		"power_connector",
		"emitter",
		"grounding_rod",
		"tesla_coil",
		"cell_charger",
		"recharger",
		"inducer",
		"inducerengi",
		"welding_goggles",
		"tray_goggles",
	)
	research_costs = list(TECHWEB_POINT_TYPE_GENERIC = TECHWEB_TIER_1_POINTS)
	announce_channels = list(RADIO_CHANNEL_ENGINEERING)

/datum/techweb_node/shuttle_engineering
	id = TECHWEB_NODE_SHUTTLE_ENG
	display_name = "Shuttle Engineering"
	description = "Materials and equipment for constructing shuttles"
	prereq_ids = list(TECHWEB_NODE_ENERGY_MANIPULATION, TECHWEB_NODE_APPLIED_BLUESPACE)
	design_ids = list(
		"borg_upgrade_engineering_shuttle_blueprints",
		"propulsion_engine",
		"shuttle_blueprints",
		"shuttle_control",
		"shuttle_docker",
		"shuttlerods",
	)
	research_costs = list(TECHWEB_POINT_TYPE_GENERIC = TECHWEB_TIER_1_POINTS)
	announce_channels = list(RADIO_CHANNEL_ENGINEERING, RADIO_CHANNEL_SCIENCE, RADIO_CHANNEL_SUPPLY)

/datum/techweb_node/holographics
	id = TECHWEB_NODE_HOLOGRAPHICS
	display_name = "Holographics"
	description = "Use of holographic technology for signage and barriers."
	prereq_ids = list(TECHWEB_NODE_ENERGY_MANIPULATION)
	design_ids = list(
		"forcefield_projector",
		"holosign",
		"holosignsec",
		"holosignengi",
		"holosignatmos",
		"holosignrestaurant",
		"holosignbar",
		"holobarrier_jani",
		"holobarrier_med",
		"holopad",
		"vendatray",
		"holodisk",
		"modular_shield_generator",
		"modular_shield_node",
		"modular_shield_relay",
		"modular_shield_charger",
		"modular_shield_well",
	)
	research_costs = list(TECHWEB_POINT_TYPE_GENERIC = TECHWEB_TIER_2_POINTS)

/datum/techweb_node/hud
	id = TECHWEB_NODE_HUD
	display_name = "Integrated HUDs"
	description = "Initially developed for assistants to learn the nuances of different professions through augmented reality."
	prereq_ids = list(TECHWEB_NODE_HOLOGRAPHICS, TECHWEB_NODE_CYBER_IMPLANTS)
	design_ids = list(
		"health_hud",
		"diagnostic_hud",
		"security_hud",
		"mod_visor_medhud",
		"mod_visor_diaghud",
		"mod_visor_sechud",
		"ci-medhud",
		"ci-diaghud",
		"ci-sechud",
	)
	research_costs = list(TECHWEB_POINT_TYPE_GENERIC = TECHWEB_TIER_3_POINTS)
	announce_channels = list(RADIO_CHANNEL_ENGINEERING, RADIO_CHANNEL_SECURITY, RADIO_CHANNEL_SCIENCE, RADIO_CHANNEL_MEDICAL)

/datum/techweb_node/night_vision
	id = TECHWEB_NODE_NIGHT_VISION
	display_name = "Night Vision Technology"
	description = "There are whispers that Nanotrasen pushed for this technology to extend shift durations, ensuring productivity around the clock."
	prereq_ids = list(TECHWEB_NODE_HUD)
	design_ids = list(
		"diagnostic_hud_night",
		"health_hud_night",
		"night_visision_goggles",
		"nvgmesons",
		"nv_scigoggles",
		"security_hud_night",
	)
	research_costs = list(TECHWEB_POINT_TYPE_GENERIC = TECHWEB_TIER_4_POINTS)
	announce_channels = list(RADIO_CHANNEL_ENGINEERING, RADIO_CHANNEL_SECURITY, RADIO_CHANNEL_SCIENCE, RADIO_CHANNEL_MEDICAL)
