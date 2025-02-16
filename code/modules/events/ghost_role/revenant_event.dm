#define REVENANT_SPAWN_THRESHOLD 20

/datum/round_event_control/revenant
	name = "Spawn Revenant" // Did you mean 'griefghost'?
	typepath = /datum/round_event/ghost_role/revenant
	weight = 7
	max_occurrences = 1
	min_players = 5
	dynamic_should_hijack = TRUE
	category = EVENT_CATEGORY_ENTITIES
	description = "Spawns an angry, soul sucking ghost."
	min_wizard_trigger_potency = 4
	max_wizard_trigger_potency = 7


/datum/round_event/ghost_role/revenant
	var/ignore_mobcheck = FALSE
	role_name = "revenant"

/datum/round_event/ghost_role/revenant/New(my_processing = TRUE, new_ignore_mobcheck = FALSE)
	..()
	ignore_mobcheck = new_ignore_mobcheck

/datum/round_event/ghost_role/revenant/spawn_role()
	if(!ignore_mobcheck)
		var/deadMobs = 0
		for(var/mob/M in GLOB.dead_mob_list)
			deadMobs++
		if(deadMobs < REVENANT_SPAWN_THRESHOLD)
			message_admins("Event attempted to spawn a revenant, but there were only [deadMobs]/[REVENANT_SPAWN_THRESHOLD] dead mobs.")
			return WAITING_FOR_SOMETHING

	var/mob/chosen_one = SSpolling.poll_ghost_candidates(check_jobban = ROLE_REVENANT, role = ROLE_REVENANT, alert_pic = /mob/living/basic/revenant, amount_to_pick = 1)
	if(isnull(chosen_one))
		return NOT_ENOUGH_PLAYERS
	var/list/spawn_locs = list()
	for(var/mob/living/carbon/human/L in GLOB.dead_mob_list) //look for any harvestable bodies
		var/turf/T = get_turf(L)
		if(T && is_station_level(T.z))
			spawn_locs += T
	if(!spawn_locs.len || spawn_locs.len < 15) //look for any morgue trays, crematoriums, ect if there weren't alot of dead bodies on the station to pick from
		for(var/obj/structure/bodycontainer/bc in GLOB.bodycontainers)
			var/turf/T = get_turf(bc)
			if(T && is_station_level(T.z))
				spawn_locs += T
	if(!spawn_locs.len) //If we can't find any valid spawnpoints, try the carp spawns
		spawn_locs += find_space_spawn()
	if(!spawn_locs.len) //If we can't find either, just spawn the revenant at the player's location
		spawn_locs += get_turf(chosen_one)
	if(!spawn_locs.len) //If we can't find THAT, then just give up and cry
		return MAP_ERROR

	var/mob/living/basic/revenant/revvie = new(pick(spawn_locs))
	revvie.PossessByPlayer(chosen_one.key)
	message_admins("[ADMIN_LOOKUPFLW(revvie)] has been made into a revenant by an event.")
	revvie.log_message("was spawned as a revenant by an event.", LOG_GAME)
	spawned_mobs += revvie
	qdel(chosen_one)
	return SUCCESSFUL_SPAWN

#undef REVENANT_SPAWN_THRESHOLD
