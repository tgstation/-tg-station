/obj/item/circuitboard/computer
	name = "Generic"
	name_extension = "(Computer Board)"

/obj/item/circuitboard/computer/examine()
	. = ..()
	if(GetComponent(/datum/component/gps))
		. += span_info("there's a small, blinking light!")

//Command

/obj/item/circuitboard/computer/aiupload
	name = "AI Upload"
	greyscale_colors = CIRCUIT_COLOR_COMMAND
	build_path = /obj/machinery/computer/upload/ai

/obj/item/circuitboard/computer/borgupload
	name = "Cyborg Upload"
	greyscale_colors = CIRCUIT_COLOR_COMMAND
	build_path = /obj/machinery/computer/upload/borg

/obj/item/circuitboard/computer/bsa_control
	name = "Bluespace Artillery Controls"
	build_path = /obj/machinery/computer/bsa_control

/obj/item/circuitboard/computer/accounting
	name = "Account Lookup Console"
	greyscale_colors = CIRCUIT_COLOR_COMMAND
	build_path = /obj/machinery/computer/accounting

/obj/item/circuitboard/computer/bankmachine
	name = "Bank Machine Console"
	greyscale_colors = CIRCUIT_COLOR_COMMAND
	build_path = /obj/machinery/computer/bank_machine

//Engineering

/obj/item/circuitboard/computer/apc_control
	name = "\improper Power Flow Control Console"
	greyscale_colors = CIRCUIT_COLOR_ENGINEERING
	build_path = /obj/machinery/computer/apc_control

/obj/item/circuitboard/computer/atmos_alert
	name = "Atmospheric Alert"
	greyscale_colors = CIRCUIT_COLOR_ENGINEERING
	build_path = /obj/machinery/computer/atmos_alert
	var/station_only = FALSE

/obj/item/circuitboard/computer/atmos_alert/station_only
	station_only = TRUE

/obj/item/circuitboard/computer/atmos_alert/examine(mob/user)
	. = ..()
	. += span_info("The board is configured to [station_only ? "track all station and mining alarms" : "track alarms on the same z-level"].")
	. += span_notice("The board mode can be changed with a [EXAMINE_HINT("multitool")].")

/obj/item/circuitboard/computer/atmos_alert/multitool_act(mob/living/user)
	station_only = !station_only
	balloon_alert(user, "tracking set to [station_only ? "station" : "z-level"]")
	return TRUE

/obj/item/circuitboard/computer/atmos_control
	name = "Atmospheric Control"
	greyscale_colors = CIRCUIT_COLOR_ENGINEERING
	build_path = /obj/machinery/computer/atmos_control

/obj/item/circuitboard/computer/atmos_control/nocontrol
	name = "Atmospheric Monitor"
	build_path = /obj/machinery/computer/atmos_control/nocontrol

/obj/item/circuitboard/computer/atmos_control/noreconnect
	name = "Atmospheric Control"
	build_path = /obj/machinery/computer/atmos_control/noreconnect

/obj/item/circuitboard/computer/atmos_control/fixed
	name = "Atmospheric Monitor"
	build_path = /obj/machinery/computer/atmos_control/fixed

/obj/item/circuitboard/computer/atmos_control/nocontrol/master
	name = "Station Atmospheric Monitor"
	build_path = /obj/machinery/computer/atmos_control/nocontrol/master

/obj/item/circuitboard/computer/atmos_control/nocontrol/incinerator
	name = "Incinerator Chamber Monitor"
	build_path = /obj/machinery/computer/atmos_control/nocontrol/incinerator

/obj/item/circuitboard/computer/atmos_control/ordnancemix
	name = "Ordnance Chamber Control"
	build_path = /obj/machinery/computer/atmos_control/ordnancemix

/obj/item/circuitboard/computer/atmos_control/oxygen_tank
	name = "Oxygen Supply Control"
	build_path = /obj/machinery/computer/atmos_control/oxygen_tank

/obj/item/circuitboard/computer/atmos_control/plasma_tank
	name = "Plasma Supply Control"
	build_path = /obj/machinery/computer/atmos_control/plasma_tank

/obj/item/circuitboard/computer/atmos_control/air_tank
	name = "Mixed Air Supply Control"
	build_path = /obj/machinery/computer/atmos_control/air_tank

/obj/item/circuitboard/computer/atmos_control/mix_tank
	name = "Gas Mix Supply Control"
	build_path = /obj/machinery/computer/atmos_control/mix_tank

/obj/item/circuitboard/computer/atmos_control/nitrous_tank
	name = "Nitrous Oxide Supply Control"
	build_path = /obj/machinery/computer/atmos_control/nitrous_tank

/obj/item/circuitboard/computer/atmos_control/nitrogen_tank
	name = "Nitrogen Supply Control"
	build_path = /obj/machinery/computer/atmos_control/nitrogen_tank

/obj/item/circuitboard/computer/atmos_control/carbon_tank
	name = "Carbon Dioxide Supply Control"
	build_path = /obj/machinery/computer/atmos_control/carbon_tank

/obj/item/circuitboard/computer/atmos_control/bz_tank
	name = "BZ Supply Control"
	build_path = /obj/machinery/computer/atmos_control/bz_tank

/obj/item/circuitboard/computer/atmos_control/freon_tank
	name = "Freon Supply Control"
	build_path = /obj/machinery/computer/atmos_control/freon_tank

/obj/item/circuitboard/computer/atmos_control/halon_tank
	name = "Halon Supply Control"
	build_path = /obj/machinery/computer/atmos_control/halon_tank

/obj/item/circuitboard/computer/atmos_control/healium_tank
	name = "Healium Supply Control"
	build_path = /obj/machinery/computer/atmos_control/healium_tank

/obj/item/circuitboard/computer/atmos_control/hydrogen_tank
	name = "Hydrogen Supply Control"
	build_path = /obj/machinery/computer/atmos_control/hydrogen_tank

/obj/item/circuitboard/computer/atmos_control/hypernoblium_tank
	name = "Hypernoblium Supply Control"
	build_path = /obj/machinery/computer/atmos_control/hypernoblium_tank

/obj/item/circuitboard/computer/atmos_control/miasma_tank
	name = "Miasma Supply Control"
	build_path = /obj/machinery/computer/atmos_control/miasma_tank

/obj/item/circuitboard/computer/atmos_control/nitrium_tank
	name = "Nitrium Supply Control"
	build_path = /obj/machinery/computer/atmos_control/nitrium_tank

/obj/item/circuitboard/computer/atmos_control/pluoxium_tank
	name = "Pluoxium Supply Control"
	build_path = /obj/machinery/computer/atmos_control/pluoxium_tank

/obj/item/circuitboard/computer/atmos_control/proto_nitrate_tank
	name = "Proto-Nitrate Supply Control"
	build_path = /obj/machinery/computer/atmos_control/proto_nitrate_tank

/obj/item/circuitboard/computer/atmos_control/tritium_tank
	name = "Tritium Supply Control"
	build_path = /obj/machinery/computer/atmos_control/tritium_tank

/obj/item/circuitboard/computer/atmos_control/water_vapor
	name = "Water Vapor Supply Control"
	build_path = /obj/machinery/computer/atmos_control/water_vapor

/obj/item/circuitboard/computer/atmos_control/zauker_tank
	name = "Zauker Supply Control"
	build_path = /obj/machinery/computer/atmos_control/zauker_tank

/obj/item/circuitboard/computer/atmos_control/helium_tank
	name = "Helium Supply Control"
	build_path = /obj/machinery/computer/atmos_control/helium_tank

/obj/item/circuitboard/computer/atmos_control/antinoblium_tank
	name = "Antinoblium Supply Control"
	build_path = /obj/machinery/computer/atmos_control/antinoblium_tank

/obj/item/circuitboard/computer/auxiliary_base
	name = "Auxiliary Base Management Console"
	greyscale_colors = CIRCUIT_COLOR_ENGINEERING
	build_path = /obj/machinery/computer/auxiliary_base

/obj/item/circuitboard/computer/base_construction
	name = "Generic Base Construction Console"
	greyscale_colors = CIRCUIT_COLOR_ENGINEERING
	build_path = /obj/machinery/computer/camera_advanced/base_construction

/obj/item/circuitboard/computer/base_construction/aux
	name = "Aux Mining Base Construction Console"
	greyscale_colors = CIRCUIT_COLOR_ENGINEERING
	build_path = /obj/machinery/computer/camera_advanced/base_construction/aux

/obj/item/circuitboard/computer/base_construction/centcom
	name = "Centcom Base Construction Console"
	greyscale_colors = CIRCUIT_COLOR_ENGINEERING
	build_path = /obj/machinery/computer/camera_advanced/base_construction/centcom

/obj/item/circuitboard/computer/comm_monitor
	name = "Telecommunications Monitor"
	greyscale_colors = CIRCUIT_COLOR_ENGINEERING
	build_path = /obj/machinery/computer/telecomms/monitor

/obj/item/circuitboard/computer/comm_server
	name = "Telecommunications Server Monitor"
	greyscale_colors = CIRCUIT_COLOR_ENGINEERING
	build_path = /obj/machinery/computer/telecomms/server

/obj/item/circuitboard/computer/communications
	name = "Communications"
	greyscale_colors = CIRCUIT_COLOR_ENGINEERING
	build_path = /obj/machinery/computer/communications

/obj/item/circuitboard/computer/communications/syndicate
	name = "Syndicate Communications"
	greyscale_colors = CIRCUIT_COLOR_ENGINEERING
	build_path = /obj/machinery/computer/communications/syndicate


/obj/item/circuitboard/computer/message_monitor
	name = "Message Monitor"
	greyscale_colors = CIRCUIT_COLOR_ENGINEERING
	build_path = /obj/machinery/computer/message_monitor

/obj/item/circuitboard/computer/powermonitor
	name = "Power Monitor"  //name fixed 250810
	greyscale_colors = CIRCUIT_COLOR_ENGINEERING
	build_path = /obj/machinery/computer/monitor

/obj/item/circuitboard/computer/sat_control
	name = "Satellite Network Control"
	greyscale_colors = CIRCUIT_COLOR_ENGINEERING
	build_path = /obj/machinery/computer/sat_control

/obj/item/circuitboard/computer/solar_control
	name = "Solar Control"  //name fixed 250810
	greyscale_colors = CIRCUIT_COLOR_ENGINEERING
	build_path = /obj/machinery/power/solar_control

/obj/item/circuitboard/computer/station_alert
	name = "Station Alerts"
	greyscale_colors = CIRCUIT_COLOR_ENGINEERING
	build_path = /obj/machinery/computer/station_alert
	var/station_only = FALSE

/obj/item/circuitboard/computer/station_alert/station_only
	station_only = TRUE

/obj/item/circuitboard/computer/station_alert/examine(mob/user)
	. = ..()
	. += span_info("The board is configured to [station_only ? "track all station and mining alarms" : "track alarms on the same z-level"].")
	. += span_notice("The board mode can be changed with a [EXAMINE_HINT("multitool")].")

/obj/item/circuitboard/computer/station_alert/multitool_act(mob/living/user)
	station_only = !station_only
	balloon_alert(user, "tracking set to [station_only ? "station" : "z-level"]")
	return TRUE

/obj/item/circuitboard/computer/turbine_computer
	name = "Turbine Computer"
	greyscale_colors = CIRCUIT_COLOR_ENGINEERING
	build_path = /obj/machinery/computer/turbine_computer

//Generic

/obj/item/circuitboard/computer/arcade/amputation
	name = "Mediborg's Amputation Adventure"
	greyscale_colors = CIRCUIT_COLOR_GENERIC
	build_path = /obj/machinery/computer/arcade/amputation

/obj/item/circuitboard/computer/arcade/battle
	name = "Arcade Battle"
	greyscale_colors = CIRCUIT_COLOR_GENERIC
	build_path = /obj/machinery/computer/arcade/battle

/obj/item/circuitboard/computer/arcade/orion_trail
	name = "Orion Trail"
	greyscale_colors = CIRCUIT_COLOR_GENERIC
	build_path = /obj/machinery/computer/arcade/orion_trail

/obj/item/circuitboard/computer/holodeck// Not going to let people get this, but it's just here for future
	name = "Holodeck Control"
	greyscale_colors = CIRCUIT_COLOR_GENERIC
	build_path = /obj/machinery/computer/holodeck

/obj/item/circuitboard/computer/libraryconsole
	name = "Library Visitor Console"
	build_path = /obj/machinery/computer/libraryconsole

/obj/item/circuitboard/computer/libraryconsole/bookconsole
	name =  "Book Inventory Management Console"
	build_path = /obj/machinery/computer/libraryconsole/bookmanagement

/obj/item/circuitboard/computer/libraryconsole/screwdriver_act(mob/living/user, obj/item/tool)
	if(build_path == /obj/machinery/computer/libraryconsole/bookmanagement)
		name = "Library Visitor Console"
		build_path = /obj/machinery/computer/libraryconsole
		to_chat(user, span_notice("Defaulting access protocols."))
	else
		name = "Book Inventory Management Console"
		build_path = /obj/machinery/computer/libraryconsole/bookmanagement
		to_chat(user, span_notice("Access protocols successfully updated."))
	return TRUE

/obj/item/circuitboard/computer/monastery_shuttle
	name = "Monastery Shuttle"
	greyscale_colors = CIRCUIT_COLOR_GENERIC
	build_path = /obj/machinery/computer/shuttle/monastery_shuttle

/obj/item/circuitboard/computer/olddoor
	name = "DoorMex"
	greyscale_colors = CIRCUIT_COLOR_GENERIC
	build_path = /obj/machinery/computer/pod/old

/obj/item/circuitboard/computer/pod
	name = "Massdriver control"
	greyscale_colors = CIRCUIT_COLOR_GENERIC
	build_path = /obj/machinery/computer/pod

/obj/item/circuitboard/computer/slot_machine
	name = "Slot Machine"
	greyscale_colors = CIRCUIT_COLOR_GENERIC
	build_path = /obj/machinery/computer/slot_machine

/obj/item/circuitboard/computer/swfdoor
	name = "Magix"
	greyscale_colors = CIRCUIT_COLOR_GENERIC
	build_path = /obj/machinery/computer/pod/old/swf

/obj/item/circuitboard/computer/syndicate_shuttle
	name = "Syndicate Shuttle"
	greyscale_colors = CIRCUIT_COLOR_GENERIC
	build_path = /obj/machinery/computer/shuttle/syndicate
	var/challenge = FALSE
	var/moved = FALSE

/obj/item/circuitboard/computer/syndicate_shuttle/Initialize(mapload)
	. = ..()
	GLOB.syndicate_shuttle_boards += src

/obj/item/circuitboard/computer/syndicate_shuttle/Destroy()
	GLOB.syndicate_shuttle_boards -= src
	return ..()

/obj/item/circuitboard/computer/syndicatedoor
	name = "ProComp Executive"
	greyscale_colors = CIRCUIT_COLOR_GENERIC
	build_path = /obj/machinery/computer/pod/old/syndicate

/obj/item/circuitboard/computer/white_ship
	name = "White Ship"
	greyscale_colors = CIRCUIT_COLOR_GENERIC
	build_path = /obj/machinery/computer/shuttle/white_ship

/obj/item/circuitboard/computer/white_ship/bridge
	name = "White Ship Bridge"
	greyscale_colors = CIRCUIT_COLOR_GENERIC
	build_path = /obj/machinery/computer/shuttle/white_ship/bridge

/obj/item/circuitboard/computer/bountypad
	name = "Bounty Pad"
	build_path = /obj/machinery/computer/piratepad_control/civilian

/obj/item/circuitboard/computer/tram_controls
	name = "Tram Controls"
	build_path = /obj/machinery/computer/tram_controls
	var/split_mode = FALSE

/obj/item/circuitboard/computer/tram_controls/split
	split_mode = TRUE

/obj/item/circuitboard/computer/tram_controls/examine(mob/user)
	. = ..()
	. += span_info("The board is configured for [split_mode ? "split window" : "normal window"].")
	. += span_notice("The board mode can be changed with a [EXAMINE_HINT("multitool")].")

/obj/item/circuitboard/computer/tram_controls/multitool_act(mob/living/user)
	split_mode = !split_mode
	to_chat(user, span_notice("[src] positioning set to [split_mode ? "split window" : "normal window"]."))
	return TRUE

/obj/item/circuitboard/computer/terminal
	name = "Terminal"
	build_path = /obj/machinery/computer/terminal

//Medical

/obj/item/circuitboard/computer/crew
	name = "Crew Monitoring Console"
	greyscale_colors = CIRCUIT_COLOR_MEDICAL
	build_path = /obj/machinery/computer/crew

/obj/item/circuitboard/computer/med_data
	name = "Medical Records Console"
	greyscale_colors = CIRCUIT_COLOR_MEDICAL
	build_path = /obj/machinery/computer/records/medical

/obj/item/circuitboard/computer/operating
	name = "Operating Computer"
	greyscale_colors = CIRCUIT_COLOR_MEDICAL
	build_path = /obj/machinery/computer/operating

/obj/item/circuitboard/computer/pandemic
	name = "PanD.E.M.I.C. 2200"
	greyscale_colors = CIRCUIT_COLOR_MEDICAL
	build_path = /obj/machinery/computer/pandemic

//Science

/obj/item/circuitboard/computer/aifixer
	name = "AI Integrity Restorer"
	greyscale_colors = CIRCUIT_COLOR_SCIENCE
	build_path = /obj/machinery/computer/aifixer

/obj/item/circuitboard/computer/launchpad_console
	name = "Launchpad Control Console"
	greyscale_colors = CIRCUIT_COLOR_SCIENCE
	build_path = /obj/machinery/computer/launchpad

/obj/item/circuitboard/computer/mech_bay_power_console
	name = "Mech Bay Power Control Console"
	greyscale_colors = CIRCUIT_COLOR_SCIENCE
	build_path = /obj/machinery/computer/mech_bay_power_console

/obj/item/circuitboard/computer/mecha_control
	name = "Exosuit Control Console"
	greyscale_colors = CIRCUIT_COLOR_SCIENCE
	build_path = /obj/machinery/computer/mecha

/obj/item/circuitboard/computer/rdconsole
	name = "R&D Console"
	greyscale_colors = CIRCUIT_COLOR_SCIENCE
	build_path = /obj/machinery/computer/rdconsole
	var/silence_announcements = FALSE

/obj/item/circuitboard/computer/rdconsole/examine(mob/user)
	. = ..()
	. += span_info("The board is configured to [silence_announcements ? "silence" : "announce"] researched nodes on radio.")
	. += span_notice("The board mode can be changed with a [EXAMINE_HINT("multitool")].")

/obj/item/circuitboard/computer/rdconsole/multitool_act(mob/living/user)
	. = ..()
	if(obj_flags & EMAGGED)
		balloon_alert(user, "board mode is broken!")
		return
	silence_announcements = !silence_announcements
	balloon_alert(user, "announcements [silence_announcements ? "enabled" : "disabled"]")

/obj/item/circuitboard/computer/rdconsole/emag_act(mob/user, obj/item/card/emag/emag_card)
	if (obj_flags & EMAGGED)
		return FALSE

	obj_flags |= EMAGGED
	silence_announcements = FALSE
	to_chat(user, span_notice("You overload the node announcement chip, forcing every node to be announced on the common channel."))
	return TRUE

/obj/item/circuitboard/computer/rdservercontrol
	name = "R&D Server Control"
	greyscale_colors = CIRCUIT_COLOR_SCIENCE
	build_path = /obj/machinery/computer/rdservercontrol

/obj/item/circuitboard/computer/research
	name = "Research Monitor"
	greyscale_colors = CIRCUIT_COLOR_SCIENCE
	build_path = /obj/machinery/computer/security/research

/obj/item/circuitboard/computer/robotics
	name = "Robotics Control"
	greyscale_colors = CIRCUIT_COLOR_SCIENCE
	build_path = /obj/machinery/computer/robotics

/obj/item/circuitboard/computer/teleporter
	name = "Teleporter"
	greyscale_colors = CIRCUIT_COLOR_SCIENCE
	build_path = /obj/machinery/computer/teleporter

/obj/item/circuitboard/computer/xenobiology
	name = "Xenobiology Console"
	greyscale_colors = CIRCUIT_COLOR_SCIENCE
	build_path = /obj/machinery/computer/camera_advanced/xenobio

/obj/item/circuitboard/computer/scan_consolenew
	name = "DNA Console"
	greyscale_colors = CIRCUIT_COLOR_SCIENCE
	build_path = /obj/machinery/computer/scan_consolenew

/obj/item/circuitboard/computer/mechpad
	name = "Mecha Orbital Pad Console"
	greyscale_colors = CIRCUIT_COLOR_SCIENCE
	build_path = /obj/machinery/computer/mechpad

//Security

/obj/item/circuitboard/computer/labor_shuttle
	name = "Labor Shuttle"
	greyscale_colors = CIRCUIT_COLOR_SECURITY
	build_path = /obj/machinery/computer/shuttle/labor

/obj/item/circuitboard/computer/labor_shuttle/one_way
	name = "Prisoner Shuttle Console"
	greyscale_colors = CIRCUIT_COLOR_SECURITY
	build_path = /obj/machinery/computer/shuttle/labor/one_way

/obj/item/circuitboard/computer/gulag_teleporter_console
	name = "Labor Camp teleporter console"
	greyscale_colors = CIRCUIT_COLOR_SECURITY
	build_path = /obj/machinery/computer/prisoner/gulag_teleporter_computer

/obj/item/circuitboard/computer/prisoner
	name = "Prisoner Management Console"
	greyscale_colors = CIRCUIT_COLOR_SECURITY
	build_path = /obj/machinery/computer/prisoner/management

/obj/item/circuitboard/computer/secure_data
	name = "Security Records Console"
	greyscale_colors = CIRCUIT_COLOR_SECURITY
	build_path = /obj/machinery/computer/records/security

/obj/item/circuitboard/computer/warrant
	name = "Security Warrant Viewer"
	greyscale_colors = CIRCUIT_COLOR_SECURITY
	build_path = /obj/machinery/computer/warrant

/obj/item/circuitboard/computer/security
	name = "Security Cameras"
	greyscale_colors = CIRCUIT_COLOR_SECURITY
	build_path = /obj/machinery/computer/security

/obj/item/circuitboard/computer/advanced_camera
	name = "Advanced Camera Console"
	greyscale_colors = CIRCUIT_COLOR_SECURITY
	build_path = /obj/machinery/computer/camera_advanced/syndie

//Service
/obj/item/circuitboard/computer/order_console
	name = "Produce Orders Console"
	greyscale_colors = CIRCUIT_COLOR_SERVICE
	build_path = /obj/machinery/computer/order_console/cook

//Supply

/obj/item/circuitboard/computer/cargo
	name = "Supply Console"
	greyscale_colors = CIRCUIT_COLOR_SUPPLY
	build_path = /obj/machinery/computer/cargo
	var/contraband = FALSE

/obj/item/circuitboard/computer/cargo/multitool_act(mob/living/user)
	. = ..()
	if(!(obj_flags & EMAGGED))
		contraband = !contraband
		to_chat(user, span_notice("Receiver spectrum set to [contraband ? "Broad" : "Standard"]."))
	else
		to_chat(user, span_alert("The spectrum chip is unresponsive."))

/obj/item/circuitboard/computer/cargo/emag_act(mob/user, obj/item/card/emag/emag_card)
	if (obj_flags & EMAGGED)
		return FALSE

	contraband = TRUE
	obj_flags |= EMAGGED
	to_chat(user, span_notice("You adjust [src]'s routing and receiver spectrum, unlocking special supplies and contraband."))
	return TRUE

/obj/item/circuitboard/computer/cargo/configure_machine(obj/machinery/computer/cargo/machine)
	if(!istype(machine))
		CRASH("Cargo board attempted to configure incorrect machine type: [machine] ([machine?.type])")

	machine.contraband = contraband
	if (obj_flags & EMAGGED)
		machine.obj_flags |= EMAGGED
	else
		machine.obj_flags &= ~EMAGGED

/obj/item/circuitboard/computer/cargo/express
	name = "Express Supply Console"
	build_path = /obj/machinery/computer/cargo/express

/obj/item/circuitboard/computer/cargo/express/emag_act(mob/user, obj/item/card/emag/emag_card)
	if (obj_flags & EMAGGED)
		return FALSE

	contraband = TRUE
	obj_flags |= EMAGGED
	to_chat(user, span_notice("You change the routing protocols, allowing the Drop Pod to land anywhere on the station."))
	return TRUE

/obj/item/circuitboard/computer/cargo/express/multitool_act(mob/living/user)
	if (!(obj_flags & EMAGGED))
		contraband = !contraband
		to_chat(user, span_notice("Receiver spectrum set to [contraband ? "Broad" : "Standard"]."))
		return TRUE
	else
		to_chat(user, span_notice("You reset the destination-routing protocols and receiver spectrum to factory defaults."))
		contraband = FALSE
		obj_flags &= ~EMAGGED
		return TRUE

/obj/item/circuitboard/computer/cargo/request
	name = "Supply Request Console"
	build_path = /obj/machinery/computer/cargo/request

/obj/item/circuitboard/computer/order_console/mining
	name = "Mining Vending Console"
	greyscale_colors = CIRCUIT_COLOR_SUPPLY
	build_path = /obj/machinery/computer/order_console/mining

/obj/item/circuitboard/computer/order_console/mining/golem
	name = "Golem Ship Equipment Vendor Console"
	build_path = /obj/machinery/computer/order_console/mining/golem

/obj/item/circuitboard/computer/order_console/bitrunning
	name = "Bitrunning Vendor Console"
	build_path = /obj/machinery/computer/order_console/bitrunning

/obj/item/circuitboard/computer/ferry
	name = "Transport Ferry"
	greyscale_colors = CIRCUIT_COLOR_SUPPLY
	build_path = /obj/machinery/computer/shuttle/ferry

/obj/item/circuitboard/computer/ferry/request
	name = "Transport Ferry Console"
	greyscale_colors = CIRCUIT_COLOR_SUPPLY
	build_path = /obj/machinery/computer/shuttle/ferry/request

/obj/item/circuitboard/computer/mining
	name = "Outpost Status Display"
	greyscale_colors = CIRCUIT_COLOR_SUPPLY
	build_path = /obj/machinery/computer/security/mining

/obj/item/circuitboard/computer/mining_shuttle
	name = "Mining Shuttle"
	greyscale_colors = CIRCUIT_COLOR_SUPPLY
	build_path = /obj/machinery/computer/shuttle/mining

/obj/item/circuitboard/computer/mining_shuttle/common
	name = "Lavaland Shuttle"
	build_path = /obj/machinery/computer/shuttle/mining/common

/obj/item/circuitboard/computer/emergency_pod
	name = "Emergency Pod Controls"
	greyscale_colors = CIRCUIT_COLOR_GENERIC
	build_path = /obj/machinery/computer/shuttle/pod

/obj/item/circuitboard/computer/exoscanner_console
	name = "Scanner Array Control Console"
	build_path = /obj/machinery/computer/exoscanner_control

/obj/item/circuitboard/computer/exodrone_console
	name = "Exploration Drone Control Console"
	build_path = /obj/machinery/computer/exodrone_control_console

/obj/item/circuitboard/computer/shuttle
	var/shuttle_id

/obj/item/circuitboard/computer/shuttle/configure_machine(obj/machinery/machine)
	var/obj/docking_port/mobile/custom/shuttle = shuttle_id ? SSshuttle.getShuttle(shuttle_id) : SSshuttle.get_containing_shuttle(machine)
	if(!shuttle)
		var/on_shuttle_frame = HAS_TRAIT((get_turf(machine)), TRAIT_SHUTTLE_CONSTRUCTION_TURF)
		machine.say(on_shuttle_frame ? "Console will automatically link on shuttle completion." : "No shuttle available for linking.")
	else if(!istype(shuttle))
		machine.say("Cannot link to this kind of shuttle!")
	else
		machine.connect_to_shuttle(TRUE, shuttle)

/obj/item/circuitboard/computer/shuttle/flight_control
	name = "Shuttle Flight Control (Computer Board)"
	build_path = /obj/machinery/computer/shuttle/custom_shuttle

/obj/item/circuitboard/computer/shuttle/docker
	name = "Shuttle Navigation Computer (Computer Board)"
	build_path = /obj/machinery/computer/camera_advanced/shuttle_docker/custom
