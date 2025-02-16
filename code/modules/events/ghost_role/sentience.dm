GLOBAL_LIST_INIT(high_priority_sentience, typecacheof(list(
	/mob/living/basic/bat,
	/mob/living/basic/butterfly,
	/mob/living/basic/carp/pet/cayenne,
	/mob/living/basic/chicken,
	/mob/living/basic/crab,
	/mob/living/basic/cow,
	/mob/living/basic/goat,
	/mob/living/basic/goose/vomit,
	/mob/living/basic/lizard,
	/mob/living/basic/mouse/brown/tom,
	/mob/living/basic/parrot,
	/mob/living/basic/pet,
	/mob/living/basic/pig,
	/mob/living/basic/rabbit,
	/mob/living/basic/sheep,
	/mob/living/basic/sloth,
	/mob/living/basic/snake,
	/mob/living/basic/spider/giant/sgt_araneus,
	/mob/living/simple_animal/bot/secbot/beepsky,
	/mob/living/basic/bear/snow/misha,
	/mob/living/basic/mining/lobstrosity/juvenile,
)))

/datum/round_event_control/sentience
	name = "Random Human-level Intelligence"
	typepath = /datum/round_event/ghost_role/sentience
	weight = 10
	category = EVENT_CATEGORY_FRIENDLY
	description = "An animal or robot becomes sentient!"
	min_wizard_trigger_potency = 0
	max_wizard_trigger_potency = 7


/datum/round_event/ghost_role/sentience
	minimum_required = 1
	role_name = "random animal"
	var/animals = 1
	var/one = "one"
	fakeable = TRUE

/datum/round_event/ghost_role/sentience/announce(fake)
	var/sentience_report = ""

	var/data = pick("scans from our long-range sensors", "our sophisticated probabilistic models", "our omnipotence", "the communications traffic on your station", "energy emissions we detected", "\[REDACTED\]")
	var/pets = pick("animals/bots", "bots/animals", "pets", "simple animals", "lesser lifeforms", "\[REDACTED\]")
	var/strength = pick("human", "moderate", "lizard", "security", "command", "clown", "low", "very low", "\[REDACTED\]")

	sentience_report += "Based on [data], we believe that [one] of the station's [pets] has developed [strength] level intelligence, and the ability to communicate."

	priority_announce(sentience_report,"[command_name()] Medium-Priority Update")

/datum/round_event/ghost_role/sentience/spawn_role()
	var/list/mob/dead/observer/candidates = SSpolling.poll_ghost_candidates(check_jobban = ROLE_SENTIENCE, role = ROLE_SENTIENCE, alert_pic = /obj/item/slimepotion/slime/sentience, role_name_text = role_name)
	if(!length(candidates))
		return NOT_ENOUGH_PLAYERS

	// find our chosen mob to breathe life into
	// Mobs have to be simple animals, mindless, on station, and NOT holograms.
	// prioritize starter animals that people will recognise


	var/list/potential = list()

	var/list/hi_pri = list()
	var/list/low_pri = list()

	for(var/mob/living/simple_animal/check_mob in GLOB.alive_mob_list)
		set_mob_priority(check_mob, hi_pri, low_pri)
	for(var/mob/living/basic/check_mob in GLOB.alive_mob_list)
		set_mob_priority(check_mob, hi_pri, low_pri)

	shuffle_inplace(hi_pri)
	shuffle_inplace(low_pri)

	potential = hi_pri + low_pri

	if(!potential.len)
		return WAITING_FOR_SOMETHING
	if(!candidates.len)
		return NOT_ENOUGH_PLAYERS

	var/spawned_animals = 0
	while(spawned_animals < animals && candidates.len && potential.len)
		var/mob/living/selected = popleft(potential)
		var/mob/dead/observer/picked_candidate = pick_n_take(candidates)

		spawned_animals++

		selected.PossessByPlayer(picked_candidate.key)

		selected.grant_all_languages(UNDERSTOOD_LANGUAGE, grant_omnitongue = FALSE, source = LANGUAGE_ATOM)

		if (isanimal(selected))
			var/mob/living/simple_animal/animal_selected = selected
			animal_selected.sentience_act()
			animal_selected.del_on_death = FALSE
		else if	(isbasicmob(selected))
			var/mob/living/basic/animal_selected = selected
			animal_selected.basic_mob_flags &= ~DEL_ON_DEATH

		selected.maxHealth = max(selected.maxHealth, 200)
		selected.health = selected.maxHealth
		spawned_mobs += selected

		to_chat(selected, span_userdanger("Hello world!"))
		to_chat(selected, span_warning("Due to freak radiation and/or chemicals \
			and/or lucky chance, you have gained human level intelligence \
			and the ability to speak and understand human language!"))

	return SUCCESSFUL_SPAWN

/// Adds a mob to either the high or low priority event list
/datum/round_event/ghost_role/sentience/proc/set_mob_priority(mob/living/checked_mob, list/high, list/low)
	var/turf/mob_turf = get_turf(checked_mob)
	if(!mob_turf || !is_station_level(mob_turf.z))
		return
	if((checked_mob in GLOB.player_list) || checked_mob.mind || (checked_mob.flags_1 & HOLOGRAM_1))
		return
	if(is_type_in_typecache(checked_mob, GLOB.high_priority_sentience))
		high += checked_mob
	else
		low += checked_mob

/datum/round_event_control/sentience/all
	name = "Station-wide Human-level Intelligence"
	typepath = /datum/round_event/ghost_role/sentience/all
	weight = 0
	category = EVENT_CATEGORY_FRIENDLY
	description = "ALL animals and robots become sentient, provided there is enough ghosts."

/datum/round_event/ghost_role/sentience/all
	one = "all"
	animals = INFINITY // as many as there are ghosts and animals
	// cockroach pride, station wide
