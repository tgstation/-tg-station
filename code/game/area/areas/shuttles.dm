
//These are shuttle areas; all subtypes are only used as teleportation markers, they have no actual function beyond that.
//Multi area shuttles are a thing now, use subtypes! ~ninjanomnom

/area/shuttle
	name = "Shuttle"
	requires_power = FALSE
	static_lighting = TRUE
	default_gravity = STANDARD_GRAVITY
	always_unpowered = FALSE
	// Loading the same shuttle map at a different time will produce distinct area instances.
	area_flags = NONE
	icon = 'icons/area/areas_station.dmi'
	icon_state = "shuttle"
	flags_1 = CAN_BE_DIRTY_1
	area_limited_icon_smoothing = /area/shuttle
	sound_environment = SOUND_ENVIRONMENT_ROOM


/area/shuttle/place_on_top_react(list/new_baseturfs, turf/added_layer, flags)
	. = ..()
	if(ispath(added_layer, /turf/open/floor/plating))
		new_baseturfs.Add(/turf/baseturf_skipover/shuttle)
		. |= CHANGETURF_GENERATE_SHUTTLE_CEILING
	else if(ispath(new_baseturfs[1], /turf/open/floor/plating))
		new_baseturfs.Insert(1, /turf/baseturf_skipover/shuttle)
		. |= CHANGETURF_GENERATE_SHUTTLE_CEILING

////////////////////////////Custom Shuttles////////////////////////////

/area/shuttle/custom
	requires_power = TRUE

////////////////////////////Multi-area shuttles//////////////////////////////

////////////////////////////Syndicate infiltrator////////////////////////////

/area/shuttle/syndicate
	name = "Syndicate Infiltrator"
	ambience_index = AMBIENCE_DANGER
	area_limited_icon_smoothing = /area/shuttle/syndicate

/area/shuttle/syndicate/bridge
	name = "Syndicate Infiltrator Control"

/area/shuttle/syndicate/medical
	name = "Syndicate Infiltrator Medbay"

/area/shuttle/syndicate/armory
	name = "Syndicate Infiltrator Armory"

/area/shuttle/syndicate/eva
	name = "Syndicate Infiltrator EVA"

/area/shuttle/syndicate/hallway
	name = "Syndicate Infiltrator Hall"

/area/shuttle/syndicate/engineering
	name = "Syndicate Infiltrator Engineering"

/area/shuttle/syndicate/airlock
	name = "Syndicate Infiltrator Airlock"

////////////////////////////Pirate Shuttle////////////////////////////

/area/shuttle/pirate
	name = "Pirate Shuttle"
	requires_power = TRUE

/area/shuttle/pirate/flying_dutchman
	name = "Flying Dutchman"
	requires_power = FALSE

////////////////////////////Bounty Hunter Shuttles////////////////////////////

/area/shuttle/hunter
	name = "Hunter Shuttle"

/area/shuttle/hunter/russian
	name = "Russian Cargo Hauler"
	requires_power = TRUE

/area/shuttle/hunter/mi13_foodtruck
	name = "Perfectly Ordinary Food Truck"
	requires_power = TRUE
	ambience_index = AMBIENCE_DANGER

////////////////////////////White Ship////////////////////////////

/area/shuttle/abandoned
	name = "Abandoned Ship"
	requires_power = TRUE
	area_limited_icon_smoothing = /area/shuttle/abandoned

/area/shuttle/abandoned/bridge
	name = "Abandoned Ship Bridge"

/area/shuttle/abandoned/engine
	name = "Abandoned Ship Engine"

/area/shuttle/abandoned/bar
	name = "Abandoned Ship Bar"

/area/shuttle/abandoned/crew
	name = "Abandoned Ship Crew Quarters"

/area/shuttle/abandoned/cargo
	name = "Abandoned Ship Cargo Bay"

/area/shuttle/abandoned/medbay
	name = "Abandoned Ship Medbay"

/area/shuttle/abandoned/pod
	name = "Abandoned Ship Pod"

////////////////////////////Single-area shuttles////////////////////////////
/area/shuttle/transit
	name = "Hyperspace"
	desc = "Weeeeee"
	static_lighting = FALSE
	base_lighting_alpha = 255


/area/shuttle/arrival
	name = "Arrival Shuttle"
	area_flags = UNIQUE_AREA// SSjob refers to this area for latejoiners


/area/shuttle/arrival/on_joining_game(mob/living/boarder)
	if(SSshuttle.arrivals?.mode == SHUTTLE_CALL)
		var/atom/movable/screen/splash/Spl = new(null, boarder.client, TRUE)
		Spl.Fade(TRUE)
		boarder.playsound_local(get_turf(boarder), 'sound/announcer/ApproachingTG.ogg', 25)
	boarder.update_parallax_teleport()


/area/shuttle/pod_1
	name = "Escape Pod One"
	area_flags = NONE

/area/shuttle/pod_2
	name = "Escape Pod Two"
	area_flags = NONE

/area/shuttle/pod_3
	name = "Escape Pod Three"
	area_flags = NONE

/area/shuttle/pod_4
	name = "Escape Pod Four"
	area_flags = NONE

/area/shuttle/mining
	name = "Mining Shuttle"

/area/shuttle/mining/large
	name = "Mining Shuttle"
	requires_power = TRUE

/area/shuttle/labor
	name = "Labor Camp Shuttle"

/area/shuttle/supply
	name = "Supply Shuttle"
	area_flags = NOTELEPORT

/area/shuttle/escape
	name = "Emergency Shuttle"
	area_flags = BLOBS_ALLOWED
	area_limited_icon_smoothing = /area/shuttle/escape
	flags_1 = CAN_BE_DIRTY_1
	area_flags = CULT_PERMITTED

/area/shuttle/escape/backup
	name = "Backup Emergency Shuttle"

/area/shuttle/escape/brig
	name = "Escape Shuttle Brig"
	icon_state = "shuttlered"

/area/shuttle/escape/luxury
	name = "Luxurious Emergency Shuttle"
	area_flags = NOTELEPORT

/area/shuttle/escape/simulation
	name = "Medieval Reality Simulation Dome"
	icon_state = "shuttlectf"
	area_flags = NOTELEPORT
	static_lighting = FALSE
	base_lighting_alpha = 255

/area/shuttle/escape/arena
	name = "The Arena"
	area_flags = NOTELEPORT

/area/shuttle/escape/meteor
	name = "\proper a meteor with engines strapped to it"
	luminosity = NONE

/area/shuttle/escape/engine
	name = "Escape Shuttle Engine"

/area/shuttle/transport
	name = "Transport Shuttle"

/area/shuttle/assault_pod
	name = "Steel Rain"

/area/shuttle/sbc_starfury
	name = "SBC Starfury"

/area/shuttle/sbc_fighter1
	name = "SBC Fighter 1"

/area/shuttle/sbc_fighter2
	name = "SBC Fighter 2"

/area/shuttle/sbc_fighter3
	name = "SBC Fighter 3"

/area/shuttle/sbc_corvette
	name = "SBC corvette"

/area/shuttle/syndicate_scout
	name = "Syndicate Scout"

/area/shuttle/ruin
	name = "Ruined Shuttle"

/// Special shuttles made for the Caravan Ambush ruin.
/area/shuttle/ruin/caravan
	requires_power = TRUE
	name = "Ruined Caravan Shuttle"

/area/shuttle/ruin/caravan/syndicate1
	name = "Syndicate Fighter"

/area/shuttle/ruin/caravan/syndicate2
	name = "Syndicate Fighter"

/area/shuttle/ruin/caravan/syndicate3
	name = "Syndicate Drop Ship"

/area/shuttle/ruin/caravan/pirate
	name = "Pirate Cutter"

/area/shuttle/ruin/caravan/freighter1
	name = "Small Freighter"

/area/shuttle/ruin/caravan/freighter2
	name = "Tiny Freighter"

/area/shuttle/ruin/caravan/freighter3
	name = "Tiny Freighter"

// ----------- Cyborg Mothership

/area/shuttle/ruin/cyborg_mothership
	name = "Cyborg Mothership"
	requires_power = TRUE
	area_limited_icon_smoothing = /area/shuttle/ruin/cyborg_mothership

// ----------- Arena Shuttle
/area/shuttle/shuttle_arena
	name = "arena"
	default_gravity = STANDARD_GRAVITY
	requires_power = FALSE

/obj/effect/forcefield/arena_shuttle
	name = "portal"
	initial_duration = 0
	var/list/warp_points = list()

/obj/effect/forcefield/arena_shuttle/Initialize(mapload)
	. = ..()
	for(var/obj/effect/landmark/shuttle_arena_safe/exit in GLOB.landmarks_list)
		warp_points += exit

/obj/effect/forcefield/arena_shuttle/Bumped(atom/movable/AM)
	if(!isliving(AM))
		return

	var/mob/living/L = AM
	if(L.pulling && istype(L.pulling, /obj/item/bodypart/head))
		to_chat(L, span_notice("Your offering is accepted. You may pass."), confidential = TRUE)
		qdel(L.pulling)
		var/turf/LA = get_turf(pick(warp_points))
		L.forceMove(LA)
		L.remove_status_effect(/datum/status_effect/hallucination)
		to_chat(L, "<span class='reallybig redtext'>The battle is won. Your bloodlust subsides.</span>", confidential = TRUE)
		for(var/obj/item/chainsaw/doomslayer/chainsaw in L)
			qdel(chainsaw)
		var/obj/item/skeleton_key/key = new(L)
		L.put_in_hands(key)
	else
		to_chat(L, span_warning("You are not yet worthy of passing. Drag a severed head to the barrier to be allowed entry to the hall of champions."), confidential = TRUE)

/obj/effect/landmark/shuttle_arena_safe
	name = "hall of champions"
	desc = "For the winners."

/obj/effect/landmark/shuttle_arena_entrance
	name = "\proper the arena"
	desc = "A lava filled battlefield."

/obj/effect/forcefield/arena_shuttle_entrance
	name = "portal"
	initial_duration = 0
	var/list/warp_points = list()

/obj/effect/forcefield/arena_shuttle_entrance/Bumped(atom/movable/AM)
	if(!isliving(AM))
		return

	if(!warp_points.len)
		for(var/obj/effect/landmark/shuttle_arena_entrance/S in GLOB.landmarks_list)
			warp_points |= S

	var/obj/effect/landmark/LA = pick(warp_points)
	var/mob/living/M = AM
	M.forceMove(get_turf(LA))
	to_chat(M, "<span class='reallybig redtext'>You're trapped in a deadly arena! To escape, you'll need to drag a severed head to the escape portals.</span>", confidential = TRUE)
	M.apply_status_effect(/datum/status_effect/mayhem)
