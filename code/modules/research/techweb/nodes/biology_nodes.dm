/datum/techweb_node/bio_scan
	id = TECHWEB_NODE_BIO_SCAN
	display_name = "Biological Scan"
	description = "Advanced technology for analyzing patient health and reagent compositions, ensuring precise diagnostics and treatment in the medical bay."
	prereq_ids = list(TECHWEB_NODE_MEDBAY_EQUIP)
	design_ids = list(
		"healthanalyzer",
		"autopsyscanner",
		"genescanner",
		"medical_kiosk",
		"chem_master",
		"ph_meter",
		"scigoggles",
		"mod_reagent_scanner",
	)
	research_costs = list(TECHWEB_POINT_TYPE_GENERIC = TECHWEB_TIER_1_POINTS)
	announce_channels = list(RADIO_CHANNEL_MEDICAL)

/datum/techweb_node/cytology
	id = TECHWEB_NODE_CYTOLOGY
	display_name = "Cytology"
	description = "Cellular biology research focused on cultivation of limbs and diverse organisms from cells."
	prereq_ids = list(TECHWEB_NODE_BIO_SCAN)
	design_ids = list(
		"limbgrower",
		"pandemic",
		"vatgrower",
		"petri_dish",
		"swab",
		"biopsy_tool",
	)
	research_costs = list(TECHWEB_POINT_TYPE_GENERIC = TECHWEB_TIER_2_POINTS)

/datum/techweb_node/xenobiology
	id = TECHWEB_NODE_XENOBIOLOGY
	display_name = "Xenobiology"
	description = "Exploration of non-human biology, unlocking the secrets of extraterrestrial lifeforms and their unique biological processes."
	prereq_ids = list(TECHWEB_NODE_CYTOLOGY)
	design_ids = list(
		"xenobioconsole",
		"slime_scanner",
		"limbdesign_ethereal",
		"limbdesign_felinid",
		"limbdesign_lizard",
		"limbdesign_plasmaman",
	)
	research_costs = list(TECHWEB_POINT_TYPE_GENERIC = TECHWEB_TIER_3_POINTS)
	discount_experiments = list(/datum/experiment/scanning/cytology/slime = TECHWEB_TIER_3_POINTS)

/datum/techweb_node/gene_engineering
	id = TECHWEB_NODE_GENE_ENGINEERING
	display_name = "Gene Engineering"
	description = "Research into sophisticated DNA manipulation techniques, enabling the modification of human genetic traits to unlock specific abilities and enhancements."
	prereq_ids = list(TECHWEB_NODE_SELECTION, TECHWEB_NODE_XENOBIOLOGY)
	design_ids = list(
		"dnascanner",
		"scan_console",
		"dna_disk",
		"dnainfuser",
		"mod_dna_lock",
		"fleshreshaper",
		"fleshreshapermed",
	)
	research_costs = list(TECHWEB_POINT_TYPE_GENERIC = TECHWEB_TIER_4_POINTS)
	discount_experiments = list(/datum/experiment/scanning/people/mutant = TECHWEB_TIER_4_POINTS)
	announce_channels = list(RADIO_CHANNEL_SCIENCE)

// Botany root node
/datum/techweb_node/botany_equip
	id = TECHWEB_NODE_BOTANY_EQUIP
	starting_node = TRUE
	display_name = "Botany Equipment"
	description = "Essential tools for maintaining onboard gardens, supporting plant growth in the unique environment of the space station."
	design_ids = list(
		"seed_extractor",
		"plant_analyzer",
		"watering_can",
		"spade",
		"cultivator",
		"secateurs",
		"hatchet",
	)

/datum/techweb_node/hydroponics
	id = TECHWEB_NODE_HYDROPONICS
	display_name = "Hydroponics"
	description = "Research into advanced hydroponic systems for efficient and sustainable plant cultivation."
	prereq_ids = list(TECHWEB_NODE_BOTANY_EQUIP, TECHWEB_NODE_CHEM_SYNTHESIS)
	design_ids = list(
		"biogenerator",
		"hydro_tray",
		"portaseeder",
	)
	research_costs = list(TECHWEB_POINT_TYPE_GENERIC = TECHWEB_TIER_2_POINTS)
	announce_channels = list(RADIO_CHANNEL_SERVICE)

/datum/techweb_node/selection
	id = TECHWEB_NODE_SELECTION
	display_name = "Artificial Selection"
	description = "Advancement in plant cultivation techniques through artificial selection, enabling precise manipulation of plant DNA."
	prereq_ids = list(TECHWEB_NODE_HYDROPONICS)
	design_ids = list(
		"flora_gun",
		"gene_shears",
	)
	research_costs = list(TECHWEB_POINT_TYPE_GENERIC = TECHWEB_TIER_3_POINTS)
	required_experiments = list(/datum/experiment/scanning/random/plants/wild)
	discount_experiments = list(/datum/experiment/scanning/random/plants/traits = TECHWEB_TIER_3_POINTS)
	announce_channels = list(RADIO_CHANNEL_SERVICE)
