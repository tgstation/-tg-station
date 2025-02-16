//Space Ruin Parents

/area/ruin/space
	default_gravity = ZERO_GRAVITY
	area_flags = UNIQUE_AREA

/area/ruin/space/unpowered
	always_unpowered = TRUE
	power_light = FALSE
	power_equip = FALSE
	power_environ = FALSE

/area/ruin/space/has_grav
	default_gravity = STANDARD_GRAVITY

/area/ruin/space/has_grav/powered
	requires_power = FALSE


// Ruin solars define, /area/solars was moved to /area/station/solars, causing the solars specific areas to lose their properties
/area/ruin/space/solars
	requires_power = FALSE
	area_flags = UNIQUE_AREA
	flags_1 = NONE
	ambience_index = AMBIENCE_ENGI
	airlock_wires = /datum/wires/airlock/engineering
	sound_environment = SOUND_AREA_SPACE

/area/ruin/space/way_home
	name = "\improper Salvation"
	always_unpowered = FALSE

// Ruins of "onehalf" ship

/area/ruin/space/has_grav/onehalf/hallway
	name = "\improper Half-Station Hallway"

/area/ruin/space/has_grav/onehalf/drone_bay
	name = "\improper Mining Drone Bay"

/area/ruin/space/has_grav/onehalf/dorms_med
	name = "\improper Crew Quarters"

/area/ruin/space/has_grav/onehalf/bridge
	name = "\improper Half-Station Bridge"

/area/ruin/space/has_grav/powered/dinner_for_two
	name = "Dinner for Two"

/area/ruin/space/has_grav/powered/cat_man
	name = "\improper Kitty Den"

/area/ruin/space/has_grav/powered/authorship
	name = "\improper Authorship"

/area/ruin/space/has_grav/powered/aesthetic
	name = "Aesthetic"
	ambientsounds = list('sound/ambience/misc/ambivapor1.ogg')


//Ruin of Hotel

/area/ruin/space/has_grav/hotel
	name = "\improper Hotel"

/area/ruin/space/has_grav/hotel/guestroom
	name = "\improper Hotel Guest Room"

/area/ruin/space/has_grav/hotel/guestroom/room_1
	name = "\improper Hotel Guest Room 1"

/area/ruin/space/has_grav/hotel/guestroom/room_2
	name = "\improper Hotel Guest Room 2"

/area/ruin/space/has_grav/hotel/guestroom/room_3
	name = "\improper Hotel Guest Room 3"

/area/ruin/space/has_grav/hotel/guestroom/room_4
	name = "\improper Hotel Guest Room 4"

/area/ruin/space/has_grav/hotel/guestroom/room_5
	name = "\improper Hotel Guest Room 5"

/area/ruin/space/has_grav/hotel/guestroom/room_6
	name = "\improper Hotel Guest Room 6"

/area/ruin/space/has_grav/hotel/security
	name = "\improper Hotel Security Post"

/area/ruin/space/has_grav/hotel/pool
	name = "\improper Hotel Pool Room"

/area/ruin/space/has_grav/hotel/bar
	name = "\improper Hotel Bar"

/area/ruin/space/has_grav/hotel/power
	name = "\improper Hotel Power Room"

/area/ruin/space/has_grav/hotel/custodial
	name = "\improper Hotel Custodial Closet"

/area/ruin/space/has_grav/hotel/shuttle
	name = "\improper Hotel Shuttle"
	requires_power = FALSE

/area/ruin/space/has_grav/hotel/dock
	name = "\improper Hotel Shuttle Dock"

/area/ruin/space/has_grav/hotel/workroom
	name = "\improper Hotel Staff Room"

/area/ruin/space/has_grav/hotel/storeroom
	name = "\improper Hotel Staff Storage"

//Ruin of Derelict Oupost

/area/ruin/space/has_grav/derelictoutpost
	name = "\improper Derelict Outpost"

/area/ruin/space/has_grav/derelictoutpost/cargostorage
	name = "\improper Derelict Outpost Cargo Storage"

/area/ruin/space/has_grav/derelictoutpost/cargobay
	name = "\improper Derelict Outpost Cargo Bay"

/area/ruin/space/has_grav/derelictoutpost/powerstorage
	name = "\improper Derelict Outpost Power Storage"

/area/ruin/space/has_grav/derelictoutpost/dockedship
	name = "\improper Derelict Outpost Docked Ship"

//Ruin of turretedoutpost

/area/ruin/space/has_grav/turretedoutpost
	name = "\improper Turreted Outpost"


//Ruin of old teleporter

/area/ruin/space/oldteleporter
	name = "\improper Old Teleporter"


//Ruin of mech transport

/area/ruin/space/has_grav/powered/mechtransport
	name = "\improper Mech Transport"


//Ruin of The Lizard's Gas (Station)

/area/ruin/space/has_grav/thelizardsgas
	name = "\improper The Lizard's Gas"


//Ruin of Deep Storage

/area/ruin/space/has_grav/deepstorage
	name = "Deep Storage"

/area/ruin/space/has_grav/deepstorage/airlock
	name = "\improper Deep Storage Airlock"

/area/ruin/space/has_grav/deepstorage/power
	name = "\improper Deep Storage Power and Atmospherics Room"

/area/ruin/space/has_grav/deepstorage/hydroponics
	name = "Deep Storage Hydroponics"

/area/ruin/space/has_grav/deepstorage/armory
	name = "\improper Deep Storage Secure Storage"

/area/ruin/space/has_grav/deepstorage/storage
	name = "\improper Deep Storage Storage"

/area/ruin/space/has_grav/deepstorage/dorm
	name = "\improper Deep Storage Dormitory"

/area/ruin/space/has_grav/deepstorage/kitchen
	name = "\improper Deep Storage Kitchen"

/area/ruin/space/has_grav/deepstorage/crusher
	name = "\improper Deep Storage Recycler"

/area/ruin/space/has_grav/deepstorage/pharmacy
	name = "\improper Deep Storage Pharmacy"

//Ruin of Abandoned Zoo

/area/ruin/space/has_grav/abandonedzoo
	name = "\improper Abandoned Zoo"

//Ruin of Dangerous Research

/area/ruin/space/has_grav/dangerous_research
	name = "\improper ASRC Lobby"

/area/ruin/space/has_grav/dangerous_research/medical
	name = "\improper ASRC Medical Facilities"

/area/ruin/space/has_grav/dangerous_research/dorms
	name = "\improper ASRC Dorms"

/area/ruin/space/has_grav/dangerous_research/lab
	name = "\improper ASRC Laboratory"

/area/ruin/space/has_grav/dangerous_research/maint
	name = "\improper ASRC Maintenance"

//Interdyne Ruin

/area/ruin/space/has_grav/interdyne
	name = "\improper Interdyne Research Base"

//Ruin of Crashed Ship

/area/ruin/space/has_grav/crashedship/aft
	name = "\improper Crashed Ship's Aft"

/area/ruin/space/has_grav/crashedship/midship
	name = "\improper Crashed Ship's Midship"

/area/ruin/space/has_grav/crashedship/fore
	name = "\improper Crashed Ship's Fore"

/area/ruin/space/has_grav/crashedship/big_asteroid
	name = "\improper Asteroid"

/area/ruin/space/has_grav/crashedship/small_asteroid
	name = "\improper Asteroid"

//Ruin of ancient Space Station (OldStation)

/area/ruin/space/ancientstation
	icon_state = "oldstation"

/area/ruin/space/ancientstation/powered
	name = "Powered Tile"
	icon_state = "teleporter"
	requires_power = FALSE

/area/ruin/space/ancientstation/beta
	icon_state = "betastation"

/area/ruin/space/ancientstation/beta/atmos
	name = "Beta Station Atmospherics"
	icon_state = "os_beta_atmos"
	ambience_index = AMBIENCE_ENGI

/area/ruin/space/ancientstation/beta/supermatter
	name = "Beta Station Supermatter chamber"
	icon_state = "os_beta_engine"

/area/ruin/space/ancientstation/beta/hall
	name = "Beta Station Main Corridor"
	icon_state = "os_beta_hall"

/area/ruin/space/ancientstation/beta/gravity
	name = "Beta Station Gravity Generator"
	icon_state = "os_beta_gravity"

/area/ruin/space/ancientstation/beta/mining
	name = "Beta Station Mining Equipment"
	icon_state = "os_beta_mining"
	ambience_index = AMBIENCE_MINING

/area/ruin/space/ancientstation/beta/medbay
	name = "Beta Station Medbay"
	icon_state = "os_beta_medbay"
	ambience_index = AMBIENCE_MEDICAL

/area/ruin/space/ancientstation/beta/storage
	name = "\improper Beta Station Storage"
	icon_state = "os_beta_storage"

/area/ruin/space/ancientstation/charlie
	icon_state = "charliestation"

/area/ruin/space/ancientstation/charlie/hall
	name = "Charlie Station Main Corridor"
	icon_state = "os_charlie_hall"

/area/ruin/space/ancientstation/charlie/engie
	name = "Charlie Station Engineering"
	icon_state = "os_charlie_engine"
	ambience_index = AMBIENCE_ENGI

/area/ruin/space/ancientstation/charlie/bridge
	name = "Charlie Station Command"
	icon_state = "os_charlie_bridge"

/area/ruin/space/ancientstation/charlie/hydro
	name = "Charlie Station Hydroponics"
	icon_state = "os_charlie_hydro"

/area/ruin/space/ancientstation/charlie/kitchen
	name = "\improper Charlie Station Kitchen"
	icon_state = "os_charlie_kitchen"

/area/ruin/space/ancientstation/charlie/sec
	name = "Charlie Station Security"
	icon_state = "os_charlie_sec"

/area/ruin/space/ancientstation/charlie/dorms
	name = "Charlie Station Dorms"
	icon_state = "os_charlie_dorms"

/area/ruin/space/solars/ancientstation/charlie/solars
	name = "\improper Charlie Station Solar Array"
	icon = 'icons/area/areas_ruins.dmi' // Solars inheriet areas_misc.dmi, not areas_ruin.dmi
	icon_state = "os_charlie_solars"
	requires_power = FALSE
	area_flags = UNIQUE_AREA
	sound_environment = SOUND_AREA_SPACE

/area/ruin/space/ancientstation/charlie/storage
	name = "Charlie Station Storage"
	icon_state = "os_charlie_storage"

/area/ruin/space/ancientstation/delta
	icon_state = "deltastation"

/area/ruin/space/ancientstation/delta/hall
	name = "Delta Station Main Corridor"
	icon_state = "os_delta_hall"

/area/ruin/space/ancientstation/delta/proto
	name = "\improper Delta Station Prototype Lab"
	icon_state = "os_delta_protolab"

/area/ruin/space/ancientstation/delta/rnd
	name = "Delta Station Research and Development"
	icon_state = "os_delta_rnd"

/area/ruin/space/ancientstation/delta/ai
	name = "\improper Delta Station AI Core"
	icon_state = "os_delta_ai"
	ambientsounds = list('sound/ambience/misc/ambimalf.ogg', 'sound/ambience/engineering/ambitech.ogg', 'sound/ambience/engineering/ambitech2.ogg', 'sound/ambience/engineering/ambiatmos.ogg', 'sound/ambience/engineering/ambiatmos2.ogg')

/area/ruin/space/ancientstation/delta/storage
	name = "\improper Delta Station Storage"
	icon_state = "os_delta_storage"

/area/ruin/space/ancientstation/delta/biolab
	name = "Delta Station Biolab"
	icon_state = "os_delta_biolab"

//KC13, aka TheDerelict.dmm

/area/ruin/space/ks13
	name = "\improper Derelict Station 13"
	icon_state = "ks13"

// Area define for organization
/area/ruin/space/ks13/hallway

/area/ruin/space/ks13/hallway/central
	name = "\improper Derelict Central Hallway"
	icon_state = "ks13_cent_hall"

/area/ruin/space/ks13/hallway/aft
	name = "\improper Derelict Aft Hallway"
	icon_state = "ks13_aft_hall"

/area/ruin/space/ks13/hallway/starboard_bow
	name = "\improper Derelict Starboard Bow Hallway"
	icon_state = "ks13_sb_bow_hall"

// Area define for organization
/area/ruin/space/ks13/engineering

/area/ruin/space/ks13/engineering/supermatter
	name = "\improper Derelict Supermatter Engine"
	icon_state = "ks13_supermatter"

/area/ruin/space/ks13/engineering/atmos
	name = "\improper Derelict Atmospherics"
	icon_state = "ks13_atmos"

/area/ruin/space/ks13/engineering/secure_storage
	name = "\improper Derelict Secure Storage"
	icon_state = "ks13_secure_storage"

/area/ruin/space/ks13/engineering/tech_storage
	name = "\improper Derelict Tech Storage"
	icon_state = "ks13_tech_storage"

/area/ruin/space/ks13/engineering/aux_storage
	name = "\improper Derelict Aux Storage"
	icon_state = "ks13_aux_storage"

/area/ruin/space/ks13/engineering/grav_gen
	name = "\improper Derelict Gravity Generator"
	icon_state = "ks13_grav_gen"

/area/ruin/space/ks13/engineering/sb_bow_solars_control
	name = "\improper Derelict Starboard Bow Solars Control Room"
	icon_state = "ks13_sb_bow_solars_control"

/area/ruin/space/ks13/engineering/aft_solars_control
	name = "\improper Derelict Aft Solars Control Room"
	icon_state = "ks13_aft_solars_control"

// Area define for organization
/area/ruin/space/ks13/medical

/area/ruin/space/ks13/medical/morgue
	name = "\improper Derelict Morgue"
	icon_state = "ks13_morgue"

/area/ruin/space/ks13/medical/medbay
	name = "\improper Derelict Medbay"
	icon_state = "ks13_med"

// Area define for organization
/area/ruin/space/ks13/service

/area/ruin/space/ks13/service/kitchen
	name = "\improper Derelict Kitchen"
	icon_state = "ks13_kitchen"

/area/ruin/space/ks13/service/bar
	name = "\improper Derelict Bar"
	icon_state = "ks13_bar"

/area/ruin/space/ks13/service/chapel
	name = "\improper Derelict Chapel"
	icon_state = "ks13_chapel"

/area/ruin/space/ks13/service/chapel_office
	name = "\improper Derelict Chapel Office"
	icon_state = "ks13_chapel_office"

/area/ruin/space/ks13/service/cafe
	name = "\improper Derelict Cafe"
	icon_state = "ks13_cafe"

/area/ruin/space/ks13/service/hydro
	name = "\improper Derelict Hydroponics"
	icon_state = "ks13_hydro"

/area/ruin/space/ks13/service/jani
	name = "\improper Derelict Janitor Closet"
	icon_state = "ks13_jani"

// Area define for organization
/area/ruin/space/ks13/science

/area/ruin/space/ks13/science/rnd
	name = "\improper Derelict Research and Development"
	icon_state = "ks13_sci"

/area/ruin/space/ks13/science/genetics
	name = "\improper Derelict Genetics"
	icon_state = "ks13_gen"

/area/ruin/space/ks13/science/ordnance
	name = "\improper Derelict Ordnance Department"
	icon_state = "ks13_ord"

/area/ruin/space/ks13/science/ordnance_hall
	name = "\improper Derelict Ordnance Hallway"
	icon_state = "ks13_ord_hall"

// Area define for organization
/area/ruin/space/ks13/security

/area/ruin/space/ks13/security/sec
	name = "\improper Derelict Security"
	icon_state = "ks13_sec"

/area/ruin/space/ks13/security/cell
	name = "\improper Derelict Security Cell"
	icon_state = "ks13_sec_cell"

/area/ruin/space/ks13/security/court
	name = "\improper Derelict Courtroom"
	icon_state = "ks13_court"

/area/ruin/space/ks13/security/court_hall
	name = "\improper Derelict Courtroom Hallway"
	icon_state = "ks13_court_hall"

// Area define for organization
/area/ruin/space/ks13/command

/area/ruin/space/ks13/command/bridge
	name = "\improper Derelict Bridge"
	icon_state = "ks13_bridge"

/area/ruin/space/ks13/command/bridge_hall
	name = "\improper Derelict Bridge Hallway"
	icon_state = "ks13_bridge_hall"

/area/ruin/space/ks13/command/eva
	name = "\improper Derelict E.V.A"
	icon_state = "ks13_eva"

// Area define for organization
/area/ruin/space/ks13/ai

/area/ruin/space/ks13/ai/vault
	name = "\improper Derelict AI Vault"
	icon_state = "ks13_ai_vault"

/area/ruin/space/ks13/ai/corridor
	name = "\improper Derelict AI Corridor"
	icon_state = "ks13_ai_corridor"

// Misc areas that don't belong to a department, general purpose or what may have you
/area/ruin/space/ks13/tool_storage
	name = "\improper Derelict Tool Storage"
	icon_state = "ks13_tool_storage"

/area/ruin/space/ks13/dorms
	name = "\improper Derelict Dorms"
	icon_state = "ks13_dorms"

/area/ruin/space/solars/ks13/sb_bow_solars
	name = "\improper Derelict Starboard Bow Solars"
	icon_state = "ks13_sb_bow_solars"

/area/ruin/space/solars/ks13/aft_solars
	name = "\improper Derelict Aft Solars"
	icon_state = "ks13_aft_solars"

//DJSTATION

/area/ruin/space/djstation
	name = "\improper Ruskie DJ Station"
	icon_state = "DJ"
	default_gravity = STANDARD_GRAVITY

/area/ruin/space/djstation/solars
	name = "\improper DJ Station Solars"
	icon_state = "DJ"
	area_flags = UNIQUE_AREA
	default_gravity = ZERO_GRAVITY

/area/ruin/space/djstation/service
	name = "\improper DJ Station Service"
	icon_state = "DJ"
	default_gravity = STANDARD_GRAVITY

//ABANDONED TELEPORTER

/area/ruin/space/abandoned_tele
	name = "\improper Abandoned Teleporter"
	ambientsounds = list('sound/ambience/misc/ambimalf.ogg', 'sound/ambience/misc/signal.ogg')

//OLD AI SAT

/area/ruin/space/tcommsat_oldaisat // Since tcommsat was moved to /area/station/, this turf doesn't inhereit its properties anymore
	name = "\improper Abandoned Satellite"
	ambientsounds = list('sound/ambience/engineering/ambisin2.ogg', 'sound/ambience/misc/signal.ogg', 'sound/ambience/misc/signal.ogg', 'sound/ambience/general/ambigen9.ogg', 'sound/ambience/engineering/ambitech.ogg',\
											'sound/ambience/engineering/ambitech2.ogg', 'sound/ambience/engineering/ambitech3.ogg', 'sound/ambience/misc/ambimystery.ogg')
	airlock_wires = /datum/wires/airlock/engineering

// CRASHED PRISON SHUTTLE
/area/ruin/space/prison_shuttle
	name = "\improper Crashed Prisoner Shuttle"


//ABANDONED BOX WHITESHIP

/area/ruin/space/has_grav/whiteship/box

	name = "\improper Abandoned Ship"


//SYNDICATE LISTENING POST STATION

/area/ruin/space/has_grav/listeningstation
	name = "\improper Listening Post"

/area/ruin/space/has_grav/powered/ancient_shuttle
	name = "\improper Ancient Shuttle"

//HELL'S FACTORY OPERATING FACILITY
/area/ruin/space/has_grav/hellfactory
	name = "\improper Hell Factory"

/area/ruin/space/has_grav/hellfactoryoffice
	name = "\improper Hell Factory Office"
	area_flags = VALID_TERRITORY | BLOBS_ALLOWED | UNIQUE_AREA | NOTELEPORT

//Ruin of Spinward Smoothies

/area/ruin/space/has_grav/spinwardsmoothies
	name = "Spinward Smoothies"

// The planet of the clowns
/area/ruin/space/has_grav/powered/clownplanet
	name = "\improper Clown Planet"
	ambientsounds = list('sound/music/lobby_music/clown.ogg')

//DERELICT SULACO
/area/ruin/space/has_grav/derelictsulaco
	name = "\improper Derelict Sulaco"

/area/ruin/space/has_grav/powered/biooutpost
	name = "\improper Bioresearch Outpost"
	area_flags = UNIQUE_AREA | NOTELEPORT

/area/ruin/space/has_grav/powered/biooutpost/vault
	name = "\improper Bioresearch Outpost Secure Testing"

// Space Ghost Kitchen
/area/ruin/space/space_ghost_restaurant
	name = "\improper Space Ghost Restaurant"

//Mass-driver hub ruin
/area/ruin/space/massdriverhub
	name = "\improper Mass Driver Router"
	always_unpowered = FALSE

// The abandoned capsule 'The Traveler's Rest'
/area/ruin/space/has_grav/travelers_rest
	name = "\improper Traveler's Rest"

// The Phonebooth
/area/ruin/space/has_grav/powered/space_phone_booth
	name = "\improper Phonebooth"

// Botnanical Haven
/area/ruin/space/has_grav/powered/botanical_haven
	name = "\improper Botanical Haven"

// Ruin of Derelict Construction
/area/ruin/space/has_grav/derelictconstruction
	name = "\improper Derelict Construction Site"

/// The Atmos Asteroid Ruin, has a subtype for rapid identification since this has some unique atmospherics properties and we can easily detect it if something goes wonky.
/area/ruin/space/has_grav/atmosasteroid

// Ruin of Waystation
/area/ruin/space/has_grav/waystation
	name = "Waystation Maintenance"

/area/ruin/space/has_grav/waystation/qm
	name = "Waystation Quartermaster Office"

/area/ruin/space/has_grav/waystation/dorms
	name = "Waystation Living Space"

/area/ruin/space/has_grav/waystation/kitchen
	name = "Waystation Kitchen"

/area/ruin/space/has_grav/waystation/cargobay
	name = "Waystation Cargo Bay"

/area/ruin/space/has_grav/waystation/securestorage
	name = "Waystation Secure Storage"

/area/ruin/space/has_grav/waystation/cargooffice
	name = "Waystation Cargo Office"

/area/ruin/space/has_grav/powered/waystation/assaultpod
	name = "Waystation Assault Pod"

/area/ruin/space/has_grav/waystation/power
	name = "Waystation Electrical"

// Ruin of The All-American Diner
/area/ruin/space/has_grav/allamericandiner
	name = "\improper The All-American Diner"

// Transit Booth
/area/ruin/space/has_grav/transit_booth
	name = "transit_booth"
	icon = 'icons/area/areas_ruins.dmi'
	icon_state = "ruins"
	requires_power = FALSE
	ambientsounds = list('sound/ambience/general/ambigen12.ogg','sound/ambience/general/ambigen13.ogg','sound/ambience/medical/ambinice.ogg')

// the outlet
/area/ruin/space/has_grav/the_outlet/storefront
	name = "\improper outlet storefront"

/area/ruin/space/has_grav/the_outlet/employeesection
	name = "\improper outlet employees only"

/area/ruin/space/has_grav/the_outlet/researchrooms
	name = "\improper outlet research rooms"

/area/ruin/space/has_grav/the_outlet/cultinfluence
	name = "\improper outlet cult corruption"

//SYN-C Brutus, derelict frigate
/area/ruin/space/has_grav/infested_frigate
	name = "SYN-C Brutus"

//garbage trucks
/area/ruin/space/has_grav/garbagetruck
	name = "Decommissioned Garbage Truck"
	sound_environment = SOUND_AREA_SMALL_ENCLOSED
	ambience_index = AMBIENCE_MAINT

/area/ruin/space/has_grav/garbagetruck/foodwaste

/area/ruin/space/has_grav/garbagetruck/medicalwaste

/area/ruin/space/has_grav/garbagetruck/squat

/area/ruin/space/has_grav/garbagetruck/toystore

//Donk Co trading outpost
/area/ruin/space/has_grav/hauntedtradingpost
	name = "\improper Donk Co. Trading Outpost"
	icon_state = "donk_public"
	sound_environment = SOUND_AREA_STANDARD_STATION

/area/ruin/space/has_grav/hauntedtradingpost/public
	name = "\improper Donk Co. Trading Outpost Public Meeting Area And Cafeteria"

/area/ruin/space/has_grav/hauntedtradingpost/public/corridor
	name = "\improper Donk Co. Trading Outpost Public Docks And Corridors"
	sound_environment = SOUND_AREA_LARGE_ENCLOSED

/area/ruin/space/has_grav/hauntedtradingpost/employees
	name = "\improper Donk Co. Trading Outpost Employees Lounge"
	icon_state = "donk_employees"
	airlock_wires = /datum/wires/airlock/engineering
	sound_environment = SOUND_AREA_MEDIUM_SOFTFLOOR

/area/ruin/space/has_grav/hauntedtradingpost/employees/workstation
	name = "\improper Donk Co. Trading Outpost Engineering Station"

/area/ruin/space/has_grav/hauntedtradingpost/employees/corridor
	name = "\improper Donk Co. Trading Outpost Secure Corridor"
	icon_state = "donk_command"

/area/ruin/space/has_grav/hauntedtradingpost/employees/breakroom
	name = "\improper Donk Co. Trading Outpost Break Room"

/area/ruin/space/has_grav/hauntedtradingpost/maint
	name = "\improper Donk Co. Trading Outpost Auxiliary Storage Room"
	icon_state = "donk_maints"
	airlock_wires = /datum/wires/airlock/maint
	sound_environment = SOUND_AREA_TUNNEL_ENCLOSED
	ambience_index = AMBIENCE_MAINT

/area/ruin/space/has_grav/hauntedtradingpost/maint/toolstorage

/area/ruin/space/has_grav/hauntedtradingpost/maint/toystorage

/area/ruin/space/has_grav/hauntedtradingpost/maint/disposals
	name = "\improper Donk Co. Trading Outpost Waste Management Station"
	sound_environment = SOUND_AREA_SMALL_ENCLOSED

/area/ruin/space/has_grav/hauntedtradingpost/office
	name = "\improper Donk Co. Trading Outpost Captains Office"
	icon_state = "donk_command"
	airlock_wires = /datum/wires/airlock/cargo
	sound_environment = SOUND_ENVIRONMENT_ROOM

/area/ruin/space/has_grav/hauntedtradingpost/office/meetingroom
	name = "\improper Donk Co. Trading Outpost Board Room"

/area/ruin/space/has_grav/hauntedtradingpost/aicore
	name = "\improper Cybersun AI Core"
	icon_state = "donk_command"
	airlock_wires = /datum/wires/airlock/security
	sound_environment = SOUND_AREA_SMALL_ENCLOSED
	ambience_index = AMBIENCE_DANGER

//Film studio
/area/ruin/space/has_grav/film_studio
	name = "\improper Film Studio Generator Room"

/area/ruin/space/has_grav/film_studio/dorms
	name = "\improper Film Studio Living Quarters"

/area/ruin/space/has_grav/film_studio/stage
	name = "\improper Film Studio Main Set Area"

/area/ruin/space/has_grav/film_studio/backstage
	name = "\improper Film Studio Backstage"

/area/ruin/space/has_grav/film_studio/director
	name = "\improper Film Studio Director Room"

/area/ruin/space/has_grav/film_studio/solars
	name = "\improper Film Studio Maintenance Solars"

/area/ruin/space/has_grav/film_studio/starboard
	name = "\improper Film Studio Starboard Wing"
