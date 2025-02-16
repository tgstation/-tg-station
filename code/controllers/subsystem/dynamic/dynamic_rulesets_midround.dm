/// Probability the AI going malf will be accompanied by an ion storm announcement and some ion laws.
#define MALF_ION_PROB 33
/// The probability to replace an existing law with an ion law instead of adding a new ion law.
#define REPLACE_LAW_WITH_ION_PROB 10

/// Midround Rulesets
/datum/dynamic_ruleset/midround // Can be drafted once in a while during a round
	ruletype = MIDROUND_RULESET
	var/midround_ruleset_style
	/// If the ruleset should be restricted from ghost roles.
	var/restrict_ghost_roles = TRUE
	/// What mob type the ruleset is restricted to.
	var/required_type = /mob/living/carbon/human
	var/list/living_players = list()
	var/list/living_antags = list()
	var/list/dead_players = list()
	var/list/list_observers = list()

	/// The minimum round time before this ruleset will show up
	var/minimum_round_time = 0
	/// Abstract root value
	var/abstract_type = /datum/dynamic_ruleset/midround

/datum/dynamic_ruleset/midround/forget_startup()
	living_players = list()
	living_antags = list()
	dead_players = list()
	list_observers = list()
	return ..()

/datum/dynamic_ruleset/midround/from_ghosts
	weight = 0
	required_type = /mob/dead/observer
	abstract_type = /datum/dynamic_ruleset/midround/from_ghosts
	/// Whether the ruleset should call generate_ruleset_body or not.
	var/makeBody = TRUE
	/// The rule needs this many applicants to be properly executed.
	var/required_applicants = 1
	///Path of an item to show up in ghost polls for applicants to sign up.
	var/signup_item_path = /obj/structure/sign/poster/contraband/syndicate_recruitment

/datum/dynamic_ruleset/midround/from_ghosts/check_candidates()
	var/dead_count = dead_players.len + list_observers.len
	if (required_candidates <= dead_count)
		return TRUE

	log_dynamic("FAIL: [src], a from_ghosts ruleset, did not have enough dead candidates: [required_candidates] needed, [dead_count] found")

	return FALSE

/datum/dynamic_ruleset/midround/trim_candidates()
	living_players = trim_list(GLOB.alive_player_list)
	living_antags = trim_list(GLOB.current_living_antags)
	dead_players = trim_list(GLOB.dead_player_list)
	list_observers = trim_list(GLOB.current_observers_list)

/datum/dynamic_ruleset/midround/proc/trim_list(list/to_trim = list())
	var/list/trimmed_list = to_trim.Copy()
	for(var/mob/creature in trimmed_list)
		if (!istype(creature, required_type))
			trimmed_list.Remove(creature)
			continue
		if (isnull(creature.client)) // Are they connected?
			trimmed_list.Remove(creature)
			continue
		if(creature.client.get_remaining_days(minimum_required_age) > 0)
			trimmed_list.Remove(creature)
			continue
		if (!((antag_preference || antag_flag) in creature.client.prefs.be_special))
			trimmed_list.Remove(creature)
			continue
		if (is_banned_from(creature.ckey, list(antag_flag_override || antag_flag, ROLE_SYNDICATE)))
			trimmed_list.Remove(creature)
			continue
		if (isnull(creature.mind))
			continue
		if (restrict_ghost_roles && !(creature.mind.assigned_role.job_flags & JOB_CREW_MEMBER)) // Are they not playing a station role?
			trimmed_list.Remove(creature)
			continue
		if (creature.mind.assigned_role.title in restricted_roles) // Does their job allow it?
			trimmed_list.Remove(creature)
			continue
		if (length(exclusive_roles) && !(creature.mind.assigned_role.title in exclusive_roles)) // Is the rule exclusive to their job?
			trimmed_list.Remove(creature)
			continue
		if(HAS_TRAIT(creature, TRAIT_MIND_TEMPORARILY_GONE)) // are they out of body?
			trimmed_list.Remove(creature)
			continue
		if(HAS_TRAIT(creature, TRAIT_TEMPORARY_BODY)) // are they an avatar?
			trimmed_list.Remove(creature)
			continue
	return trimmed_list

// You can then for example prompt dead players in execute() to join as strike teams or whatever
// Or autotator someone

// IMPORTANT, since /datum/dynamic_ruleset/midround may accept candidates from both living, dead, and even antag players
// subtype your midround with /from_ghosts or /from_living to get candidate checking. Or check yourself by subtyping from neither
/datum/dynamic_ruleset/midround/ready(forced = FALSE)
	if (forced)
		return TRUE

	var/job_check = 0
	if (enemy_roles.len > 0)
		for (var/mob/M in GLOB.alive_player_list)
			if (M.stat == DEAD || !M.client)
				continue // Dead/disconnected players cannot count as opponents
			if (M.mind && (M.mind.assigned_role.title in enemy_roles) && (!(M in candidates) || (M.mind.assigned_role.title in restricted_roles)))
				job_check++ // Checking for "enemies" (such as sec officers). To be counters, they must either not be candidates to that rule, or have a job that restricts them from it

	var/threat = round(SSdynamic.threat_level/10)
	var/ruleset_forced = (GLOB.dynamic_forced_rulesets[type] || RULESET_NOT_FORCED) == RULESET_FORCE_ENABLED
	if (!ruleset_forced && job_check < required_enemies[threat])
		log_dynamic("FAIL: [src] is not ready, because there are not enough enemies: [required_enemies[threat]] needed, [job_check] found")
		return FALSE

	return TRUE

/datum/dynamic_ruleset/midround/from_ghosts/execute()
	var/list/possible_candidates = list()
	possible_candidates.Add(dead_players)
	possible_candidates.Add(list_observers)
	send_applications(possible_candidates)
	if(assigned.len > 0)
		return TRUE
	else
		return FALSE

/// This sends a poll to ghosts if they want to be a ghost spawn from a ruleset.
/datum/dynamic_ruleset/midround/from_ghosts/proc/send_applications(list/possible_volunteers = list())
	if (possible_volunteers.len <= 0) // This shouldn't happen, as ready() should return FALSE if there is not a single valid candidate
		message_admins("Possible volunteers was 0. This shouldn't appear, because of ready(), unless you forced it!")
		return

	SSdynamic.log_dynamic_and_announce("Polling [possible_volunteers.len] players to apply for the [name] ruleset.")
	candidates = SSpolling.poll_ghost_candidates(
		question = "Looking for volunteers to become [span_notice(antag_flag)] for [span_danger(name)]",
		check_jobban = antag_flag_override,
		role = antag_flag || antag_flag_override,
		poll_time = 30 SECONDS,
		alert_pic = signup_item_path,
		role_name_text = antag_flag,
	)

	if(!candidates || candidates.len <= 0)
		SSdynamic.log_dynamic_and_announce("The ruleset [name] received no applications.")
		SSdynamic.executed_rules -= src
		attempt_replacement()
		return

	SSdynamic.log_dynamic_and_announce("[candidates.len] players volunteered for [name].")
	review_applications()

/// Here is where you can check if your ghost applicants are valid for the ruleset.
/// Called by send_applications().
/datum/dynamic_ruleset/midround/from_ghosts/proc/review_applications()
	if(candidates.len < required_applicants)
		SSdynamic.executed_rules -= src
		return
	for (var/i = 1, i <= required_candidates, i++)
		if(candidates.len <= 0)
			break
		var/mob/applicant = pick(candidates)
		candidates -= applicant
		if(!isobserver(applicant))
			if(applicant.stat == DEAD) // Not an observer? If they're dead, make them one.
				applicant = applicant.ghostize(FALSE)
			else // Not dead? Disregard them, pick a new applicant
				i--
				continue
		if(!applicant)
			i--
			continue
		assigned += applicant
	finish_applications()

/// Here the accepted applications get generated bodies and their setup is finished.
/// Called by review_applications()
/datum/dynamic_ruleset/midround/from_ghosts/proc/finish_applications()
	var/i = 0
	for(var/mob/applicant as anything in assigned)
		i++
		var/mob/new_character = applicant
		if(makeBody)
			new_character = generate_ruleset_body(applicant)
			SEND_GLOBAL_SIGNAL(COMSIG_RULESET_BODY_GENERATED_FROM_GHOSTS, applicant)
		finish_setup(new_character, i)
		notify_ghosts(
			"[applicant.name] has been picked for the ruleset [name]!",
			source = new_character,
		)

/datum/dynamic_ruleset/midround/from_ghosts/proc/generate_ruleset_body(mob/applicant)
	var/mob/living/carbon/human/new_character = make_body(applicant)
	new_character.dna.remove_all_mutations()
	return new_character

/datum/dynamic_ruleset/midround/from_ghosts/proc/finish_setup(mob/new_character, index)
	var/datum/antagonist/new_role = new antag_datum()
	setup_role(new_role)
	new_character.mind.add_antag_datum(new_role)
	new_character.mind.special_role = antag_flag

/datum/dynamic_ruleset/midround/from_ghosts/proc/setup_role(datum/antagonist/new_role)
	return

/// Fired when there are no valid candidates. Will spawn a sleeper agent or latejoin traitor.
/datum/dynamic_ruleset/midround/from_ghosts/proc/attempt_replacement()
	var/datum/dynamic_ruleset/midround/from_living/autotraitor/sleeper_agent = new

	SSdynamic.configure_ruleset(sleeper_agent)

	if (!SSdynamic.picking_specific_rule(sleeper_agent))
		return

	SSdynamic.picking_specific_rule(/datum/dynamic_ruleset/latejoin/infiltrator)

///subtype to handle checking players
/datum/dynamic_ruleset/midround/from_living
	weight = 0
	abstract_type = /datum/dynamic_ruleset/midround/from_living

/datum/dynamic_ruleset/midround/from_living/ready(forced)
	if(!check_candidates())
		return FALSE
	return ..()


/// Midround Traitor Ruleset (From Living)
/datum/dynamic_ruleset/midround/from_living/autotraitor
	name = "Syndicate Sleeper Agent"
	midround_ruleset_style = MIDROUND_RULESET_STYLE_LIGHT
	antag_datum = /datum/antagonist/traitor
	antag_flag = ROLE_SLEEPER_AGENT
	antag_flag_override = ROLE_TRAITOR
	protected_roles = list(
		JOB_CAPTAIN,
		JOB_DETECTIVE,
		JOB_HEAD_OF_PERSONNEL,
		JOB_HEAD_OF_SECURITY,
		JOB_PRISONER,
		JOB_SECURITY_OFFICER,
		JOB_WARDEN,
	)
	restricted_roles = list(
		JOB_AI,
		JOB_CYBORG,
		ROLE_POSITRONIC_BRAIN,
	)
	required_candidates = 1
	weight = 35
	cost = 3
	requirements = list(3,3,3,3,3,3,3,3,3,3)
	repeatable = TRUE

/datum/dynamic_ruleset/midround/from_living/autotraitor/trim_candidates()
	..()
	candidates = living_players
	for(var/mob/living/player in candidates)
		if(issilicon(player)) // Your assigned role doesn't change when you are turned into a silicon.
			candidates -= player
		else if(is_centcom_level(player.z))
			candidates -= player // We don't autotator people in CentCom
		else if(player.mind && (player.mind.special_role || !player.mind.can_roll_midround(antag_datum)))
			candidates -= player // We don't autotator people with roles already

/datum/dynamic_ruleset/midround/from_living/autotraitor/execute()
	var/mob/M = pick(candidates)
	assigned += M
	candidates -= M
	var/datum/antagonist/traitor/newTraitor = new
	M.mind.add_antag_datum(newTraitor)
	message_admins("[ADMIN_LOOKUPFLW(M)] was selected by the [name] ruleset and has been made into a midround traitor.")
	log_dynamic("[key_name(M)] was selected by the [name] ruleset and has been made into a midround traitor.")
	return TRUE

/// Midround Malf AI Ruleset (From Living)
/datum/dynamic_ruleset/midround/malf
	name = "Malfunctioning AI"
	midround_ruleset_style = MIDROUND_RULESET_STYLE_HEAVY
	antag_datum = /datum/antagonist/malf_ai
	antag_flag = ROLE_MALF_MIDROUND
	antag_flag_override = ROLE_MALF
	enemy_roles = list(
		JOB_CHEMIST,
		JOB_CHIEF_ENGINEER,
		JOB_HEAD_OF_SECURITY,
		JOB_RESEARCH_DIRECTOR,
		JOB_SCIENTIST,
		JOB_SECURITY_OFFICER,
		JOB_WARDEN,
	)
	exclusive_roles = list(JOB_AI)
	required_enemies = list(4,4,4,4,4,4,2,2,2,0)
	required_candidates = 1
	minimum_players = 25
	weight = 2
	cost = 10
	required_type = /mob/living/silicon/ai
	blocking_rules = list(/datum/dynamic_ruleset/roundstart/malf_ai)
	// AIs are technically considered "Ghost roles" as far as candidate selection are concerned
	// So we need to allow it here. We filter of actual ghost role AIs (charlie) via trim_candidates ourselves
	restrict_ghost_roles = FALSE

/datum/dynamic_ruleset/midround/malf/trim_candidates()
	..()
	candidates = list()
	for(var/mob/living/silicon/ai/player in living_players)
		if(!is_station_level(player.z))
			continue
		if(isnull(player.mind))
			continue
		if(player.mind.special_role || !player.mind.can_roll_midround(antag_datum))
			continue
		candidates += player

/datum/dynamic_ruleset/midround/malf/ready(forced)
	if(!check_candidates())
		log_dynamic("FAIL: No valid AI found for the Malfunctioning AI ruleset.")
		return FALSE
	return ..()

/datum/dynamic_ruleset/midround/malf/execute()
	var/mob/living/silicon/ai/new_malf_ai = pick_n_take(candidates)
	assigned += new_malf_ai.mind
	var/datum/antagonist/malf_ai/malf_antag_datum = new
	new_malf_ai.mind.special_role = antag_flag
	new_malf_ai.mind.add_antag_datum(malf_antag_datum)
	if(prob(MALF_ION_PROB))
		priority_announce("Ion storm detected near the station. Please check all AI-controlled equipment for errors.", "Anomaly Alert", ANNOUNCER_IONSTORM)
		if(prob(REPLACE_LAW_WITH_ION_PROB))
			new_malf_ai.replace_random_law(generate_ion_law(), list(LAW_INHERENT, LAW_SUPPLIED, LAW_ION), LAW_ION)
		else
			new_malf_ai.add_ion_law(generate_ion_law())
	return TRUE

/// Midround Wizard Ruleset (From Ghosts)
/datum/dynamic_ruleset/midround/from_ghosts/wizard
	name = "Wizard"
	midround_ruleset_style = MIDROUND_RULESET_STYLE_HEAVY
	antag_datum = /datum/antagonist/wizard
	antag_flag = ROLE_WIZARD_MIDROUND
	antag_flag_override = ROLE_WIZARD
	ruleset_category = parent_type::ruleset_category |  RULESET_CATEGORY_NO_WITTING_CREW_ANTAGONISTS
	required_enemies = list(2,2,1,1,1,1,1,0,0,0)
	required_candidates = 1
	weight = 1
	cost = 10
	requirements = REQUIREMENTS_VERY_HIGH_THREAT_NEEDED
	flags = HIGH_IMPACT_RULESET
	ruleset_lazy_templates = list(LAZY_TEMPLATE_KEY_WIZARDDEN)
	signup_item_path = /obj/item/clothing/head/wizard

/datum/dynamic_ruleset/midround/from_ghosts/wizard/ready(forced = FALSE)
	if(!check_candidates())
		return FALSE
	if(!length(GLOB.wizardstart))
		log_admin("Cannot accept Wizard ruleset. Couldn't find any wizard spawn points.")
		message_admins("Cannot accept Wizard ruleset. Couldn't find any wizard spawn points.")
		return FALSE
	return ..()

/datum/dynamic_ruleset/midround/from_ghosts/wizard/finish_setup(mob/new_character, index)
	..()
	new_character.forceMove(pick(GLOB.wizardstart))

/// Midround Nuclear Operatives Ruleset (From Ghosts)
/datum/dynamic_ruleset/midround/from_ghosts/nuclear
	name = "Nuclear Assault"
	midround_ruleset_style = MIDROUND_RULESET_STYLE_HEAVY
	antag_flag = ROLE_OPERATIVE_MIDROUND
	antag_flag_override = ROLE_OPERATIVE
	antag_datum = /datum/antagonist/nukeop
	ruleset_category = parent_type::ruleset_category |  RULESET_CATEGORY_NO_WITTING_CREW_ANTAGONISTS
	enemy_roles = list(
		JOB_AI,
		JOB_CYBORG,
		JOB_CAPTAIN,
		JOB_DETECTIVE,
		JOB_HEAD_OF_SECURITY,
		JOB_SECURITY_OFFICER,
		JOB_WARDEN,
	)
	required_enemies = list(3,3,3,3,3,2,1,1,0,0)
	required_candidates = 5
	weight = 5
	cost = 7
	minimum_round_time = 70 MINUTES
	requirements = REQUIREMENTS_VERY_HIGH_THREAT_NEEDED
	ruleset_lazy_templates = list(LAZY_TEMPLATE_KEY_NUKIEBASE)
	flags = HIGH_IMPACT_RULESET
	signup_item_path = /obj/machinery/nuclearbomb

	var/list/operative_cap = list(2,2,3,3,4,5,5,5,5,5)

/datum/dynamic_ruleset/midround/from_ghosts/nuclear/acceptable(population=0, threat_level=0)
	if (locate(/datum/dynamic_ruleset/roundstart/nuclear) in SSdynamic.executed_rules)
		return FALSE // Unavailable if nuke ops were already sent at roundstart
	indice_pop = min(operative_cap.len, round(living_players.len/5)+1)
	required_candidates = operative_cap[indice_pop]
	return ..()

/datum/dynamic_ruleset/midround/from_ghosts/nuclear/ready(forced = FALSE)
	if (!check_candidates())
		return FALSE
	return ..()

/datum/dynamic_ruleset/midround/from_ghosts/nuclear/finish_applications()
	var/mob/leader = get_most_experienced(assigned, ROLE_NUCLEAR_OPERATIVE)
	if(leader)
		assigned.Remove(leader)
		assigned.Insert(1, leader)
	return ..()

/datum/dynamic_ruleset/midround/from_ghosts/nuclear/finish_setup(mob/new_character, index)
	new_character.mind.set_assigned_role(SSjob.get_job_type(/datum/job/nuclear_operative))
	new_character.mind.special_role = ROLE_NUCLEAR_OPERATIVE
	if(index == 1)
		var/datum/antagonist/nukeop/leader/leader_antag_datum = new()
		new_character.mind.add_antag_datum(leader_antag_datum)
		return
	return ..()

/// Midround Blob Ruleset (From Ghosts)
/datum/dynamic_ruleset/midround/from_ghosts/blob
	name = "Blob"
	midround_ruleset_style = MIDROUND_RULESET_STYLE_HEAVY
	antag_datum = /datum/antagonist/blob
	antag_flag = ROLE_BLOB
	ruleset_category = parent_type::ruleset_category |  RULESET_CATEGORY_NO_WITTING_CREW_ANTAGONISTS
	required_enemies = list(2,2,1,1,1,1,1,0,0,0)
	required_candidates = 1
	minimum_round_time = 35 MINUTES
	weight = 3
	cost = 8
	minimum_players = 25
	repeatable = TRUE
	signup_item_path = /obj/structure/blob/normal

/datum/dynamic_ruleset/midround/from_ghosts/blob/generate_ruleset_body(mob/applicant)
	var/body = applicant.become_overmind()
	return body

/// Midround Blob Infection Ruleset (From Living)
/datum/dynamic_ruleset/midround/from_living/blob_infection
	name = "Blob Infection"
	midround_ruleset_style = MIDROUND_RULESET_STYLE_HEAVY
	antag_datum = /datum/antagonist/blob/infection
	antag_flag = ROLE_BLOB_INFECTION
	antag_flag_override = ROLE_BLOB
	ruleset_category = parent_type::ruleset_category |  RULESET_CATEGORY_NO_WITTING_CREW_ANTAGONISTS
	protected_roles = list(
		JOB_CAPTAIN,
		JOB_DETECTIVE,
		JOB_HEAD_OF_SECURITY,
		JOB_PRISONER,
		JOB_SECURITY_OFFICER,
		JOB_WARDEN,
	)
	restricted_roles = list(
		JOB_AI,
		JOB_CYBORG,
		ROLE_POSITRONIC_BRAIN,
	)
	required_enemies = list(2,2,1,1,1,1,1,0,0,0)
	required_candidates = 1
	minimum_round_time = 35 MINUTES
	weight = 3
	cost = 10
	minimum_players = 25
	repeatable = TRUE

/datum/dynamic_ruleset/midround/from_living/blob_infection/trim_candidates()
	..()
	candidates = living_players
	for(var/mob/living/player as anything in candidates)
		var/turf/player_turf = get_turf(player)
		if(!player_turf || !is_station_level(player_turf.z))
			candidates -= player
			continue

		if(player.mind && (player.mind.special_role || !player.mind.can_roll_midround(antag_datum)))
			candidates -= player

/datum/dynamic_ruleset/midround/from_living/blob_infection/execute()
	if(!candidates || !candidates.len)
		return FALSE
	var/mob/living/carbon/human/blob_antag = pick_n_take(candidates)
	assigned += blob_antag.mind
	blob_antag.mind.special_role = antag_flag
	notify_ghosts(
		"[blob_antag] has become a blob host!",
		source = blob_antag,
		header = "So Bulbous...",
	)
	return ..()

/// Midround Xenomorph Ruleset (From Ghosts)
/datum/dynamic_ruleset/midround/from_ghosts/xenomorph
	name = "Alien Infestation"
	midround_ruleset_style = MIDROUND_RULESET_STYLE_HEAVY
	antag_datum = /datum/antagonist/xeno
	antag_flag = ROLE_ALIEN
	ruleset_category = parent_type::ruleset_category |  RULESET_CATEGORY_NO_WITTING_CREW_ANTAGONISTS
	required_enemies = list(2,2,1,1,1,1,1,0,0,0)
	required_candidates = 1
	minimum_round_time = 40 MINUTES
	weight = 5
	cost = 10
	minimum_players = 25
	repeatable = TRUE
	signup_item_path = /mob/living/basic/alien
	var/list/vents = list()

/datum/dynamic_ruleset/midround/from_ghosts/xenomorph/forget_startup()
	vents = list()
	return ..()

/datum/dynamic_ruleset/midround/from_ghosts/xenomorph/execute()
	// 50% chance of being incremented by one
	required_candidates += prob(50)
	var/list/vent_pumps = SSmachines.get_machines_by_type_and_subtypes(/obj/machinery/atmospherics/components/unary/vent_pump)
	for(var/obj/machinery/atmospherics/components/unary/vent_pump/temp_vent as anything in vent_pumps)
		if(QDELETED(temp_vent))
			continue
		if(is_station_level(temp_vent.loc.z) && !temp_vent.welded)
			var/datum/pipeline/temp_vent_parent = temp_vent.parents[1]
			if(!temp_vent_parent)
				continue // No parent vent
			// Stops Aliens getting stuck in small networks.
			// See: Security, Virology
			if(temp_vent_parent.other_atmos_machines.len > 20)
				vents += temp_vent
	if(!vents.len)
		return FALSE
	. = ..()

/datum/dynamic_ruleset/midround/from_ghosts/xenomorph/generate_ruleset_body(mob/applicant)
	var/obj/vent = pick_n_take(vents)
	var/mob/living/carbon/alien/larva/new_xeno = new(vent.loc)
	new_xeno.PossessByPlayer(applicant.ckey)
	new_xeno.move_into_vent(vent)
	message_admins("[ADMIN_LOOKUPFLW(new_xeno)] has been made into an alien by the midround ruleset.")
	log_dynamic("[key_name(new_xeno)] was spawned as an alien by the midround ruleset.")
	return new_xeno

/// Midround Nightmare Ruleset (From Ghosts)
/datum/dynamic_ruleset/midround/from_ghosts/nightmare
	name = "Nightmare"
	midround_ruleset_style = MIDROUND_RULESET_STYLE_LIGHT
	antag_datum = /datum/antagonist/nightmare
	antag_flag = ROLE_NIGHTMARE
	antag_flag_override = ROLE_ALIEN
	ruleset_category = parent_type::ruleset_category |  RULESET_CATEGORY_NO_WITTING_CREW_ANTAGONISTS
	required_enemies = list(2,2,1,1,1,1,1,0,0,0)
	required_candidates = 1
	weight = 3
	cost = 5
	minimum_players = 15
	repeatable = TRUE
	signup_item_path = /obj/item/light_eater

/datum/dynamic_ruleset/midround/from_ghosts/nightmare/acceptable(population = 0, threat_level = 0)
	var/turf/spawn_loc = find_maintenance_spawn(atmos_sensitive = TRUE, require_darkness = TRUE) //Checks if there's a single safe, dark tile on station.
	if(!spawn_loc)
		return FALSE
	return ..()

/datum/dynamic_ruleset/midround/from_ghosts/nightmare/generate_ruleset_body(mob/applicant)
	var/datum/mind/player_mind = new /datum/mind(applicant.key)
	player_mind.active = TRUE

	var/mob/living/carbon/human/new_nightmare = new (find_maintenance_spawn(atmos_sensitive = TRUE, require_darkness = TRUE))
	player_mind.transfer_to(new_nightmare)
	player_mind.set_assigned_role(SSjob.get_job_type(/datum/job/nightmare))
	player_mind.special_role = ROLE_NIGHTMARE
	player_mind.add_antag_datum(/datum/antagonist/nightmare)
	new_nightmare.set_species(/datum/species/shadow/nightmare)

	playsound(new_nightmare, 'sound/effects/magic/ethereal_exit.ogg', 50, TRUE, -1)
	message_admins("[ADMIN_LOOKUPFLW(new_nightmare)] has been made into a Nightmare by the midround ruleset.")
	log_dynamic("[key_name(new_nightmare)] was spawned as a Nightmare by the midround ruleset.")
	return new_nightmare

/// Midround Space Dragon Ruleset (From Ghosts)
/datum/dynamic_ruleset/midround/from_ghosts/space_dragon
	name = "Space Dragon"
	midround_ruleset_style = MIDROUND_RULESET_STYLE_HEAVY
	antag_datum = /datum/antagonist/space_dragon
	antag_flag = ROLE_SPACE_DRAGON
	ruleset_category = parent_type::ruleset_category |  RULESET_CATEGORY_NO_WITTING_CREW_ANTAGONISTS
	required_enemies = list(2,2,1,1,1,1,1,0,0,0)
	required_candidates = 1
	weight = 4
	cost = 7
	minimum_players = 25
	repeatable = TRUE
	signup_item_path = /mob/living/basic/space_dragon
	var/list/spawn_locs = list()

/datum/dynamic_ruleset/midround/from_ghosts/space_dragon/forget_startup()
	spawn_locs = list()
	return ..()

/datum/dynamic_ruleset/midround/from_ghosts/space_dragon/execute()
	for(var/obj/effect/landmark/carpspawn/C in GLOB.landmarks_list)
		spawn_locs += (C.loc)
	if(!spawn_locs.len)
		message_admins("No valid spawn locations found, aborting...")
		return MAP_ERROR
	. = ..()

/datum/dynamic_ruleset/midround/from_ghosts/space_dragon/generate_ruleset_body(mob/applicant)
	var/datum/mind/player_mind = new /datum/mind(applicant.key)
	player_mind.active = TRUE

	var/mob/living/basic/space_dragon/S = new (pick(spawn_locs))
	player_mind.transfer_to(S)
	player_mind.add_antag_datum(/datum/antagonist/space_dragon)

	playsound(S, 'sound/effects/magic/ethereal_exit.ogg', 50, TRUE, -1)
	message_admins("[ADMIN_LOOKUPFLW(S)] has been made into a Space Dragon by the midround ruleset.")
	log_dynamic("[key_name(S)] was spawned as a Space Dragon by the midround ruleset.")
	priority_announce("A large organic energy flux has been recorded near of [station_name()], please stand-by.", "Lifesign Alert")
	return S

/datum/dynamic_ruleset/midround/from_ghosts/abductors
	name = "Abductors"
	midround_ruleset_style = MIDROUND_RULESET_STYLE_LIGHT
	antag_datum = /datum/antagonist/abductor
	antag_flag = ROLE_ABDUCTOR
	ruleset_category = parent_type::ruleset_category |  RULESET_CATEGORY_NO_WITTING_CREW_ANTAGONISTS
	required_enemies = list(2,2,1,1,1,1,1,0,0,0)
	required_candidates = 2
	required_applicants = 2
	weight = 4
	cost = 7
	minimum_players = 25
	repeatable = TRUE
	ruleset_lazy_templates = list(LAZY_TEMPLATE_KEY_ABDUCTOR_SHIPS)

	var/datum/team/abductor_team/new_team

/datum/dynamic_ruleset/midround/from_ghosts/abductors/forget_startup()
	new_team = null
	return ..()

/datum/dynamic_ruleset/midround/from_ghosts/abductors/ready(forced = FALSE)
	if (required_candidates > (dead_players.len + list_observers.len))
		return FALSE
	return ..()

/datum/dynamic_ruleset/midround/from_ghosts/abductors/finish_setup(mob/new_character, index)
	if (index == 1) // Our first guy is the scientist.  We also initialize the team here as well since this should only happen once per pair of abductors.
		new_team = new
		if(new_team.team_number > ABDUCTOR_MAX_TEAMS)
			return MAP_ERROR
		var/datum/antagonist/abductor/scientist/new_role = new
		new_character.mind.add_antag_datum(new_role, new_team)
	else // Our second guy is the agent, team is already created, don't need to make another one.
		var/datum/antagonist/abductor/agent/new_role = new
		new_character.mind.add_antag_datum(new_role, new_team)

/// Midround Space Ninja Ruleset (From Ghosts)
/datum/dynamic_ruleset/midround/from_ghosts/space_ninja
	name = "Space Ninja"
	midround_ruleset_style = MIDROUND_RULESET_STYLE_HEAVY
	antag_datum = /datum/antagonist/ninja
	antag_flag = ROLE_NINJA
	ruleset_category = parent_type::ruleset_category |  RULESET_CATEGORY_NO_WITTING_CREW_ANTAGONISTS
	required_enemies = list(2,2,1,1,1,1,1,0,0,0)
	required_candidates = 1
	weight = 4
	cost = 8
	minimum_players = 30
	repeatable = TRUE
	ruleset_lazy_templates = list(LAZY_TEMPLATE_KEY_NINJA_HOLDING_FACILITY) // I mean, no one uses the nets anymore but whateva
	signup_item_path = /obj/item/energy_katana

	var/list/spawn_locs = list()

/datum/dynamic_ruleset/midround/from_ghosts/space_ninja/forget_startup()
	spawn_locs = list()
	return ..()

/datum/dynamic_ruleset/midround/from_ghosts/space_ninja/execute()
	for(var/obj/effect/landmark/carpspawn/carp_spawn in GLOB.landmarks_list)
		if(!isturf(carp_spawn.loc))
			stack_trace("Carp spawn found not on a turf: [carp_spawn.type] on [isnull(carp_spawn.loc) ? "null" : carp_spawn.loc.type]")
			continue
		spawn_locs += carp_spawn.loc
	if(!spawn_locs.len)
		message_admins("No valid spawn locations found, aborting...")
		return MAP_ERROR
	return ..()

/datum/dynamic_ruleset/midround/from_ghosts/space_ninja/generate_ruleset_body(mob/applicant)
	var/mob/living/carbon/human/ninja = create_space_ninja(pick(spawn_locs))
	ninja.PossessByPlayer(applicant.ckey)
	ninja.mind.add_antag_datum(/datum/antagonist/ninja)

	message_admins("[ADMIN_LOOKUPFLW(ninja)] has been made into a Space Ninja by the midround ruleset.")
	log_dynamic("[key_name(ninja)] was spawned as a Space Ninja by the midround ruleset.")
	return ninja

/// Midround Spiders Ruleset (From Ghosts)
/datum/dynamic_ruleset/midround/spiders
	name = "Spiders"
	midround_ruleset_style = MIDROUND_RULESET_STYLE_HEAVY
	antag_flag = ROLE_SPIDER
	ruleset_category = parent_type::ruleset_category |  RULESET_CATEGORY_NO_WITTING_CREW_ANTAGONISTS
	required_type = /mob/dead/observer
	required_enemies = list(2,2,1,1,1,1,1,0,0,0)
	required_candidates = 0
	weight = 3
	cost = 8
	minimum_players = 27
	repeatable = TRUE
	var/spawncount = 2

/datum/dynamic_ruleset/midround/spiders/execute()
	create_midwife_eggs(spawncount)
	return ..()

/// Midround Revenant Ruleset (From Ghosts)
/datum/dynamic_ruleset/midround/from_ghosts/revenant
	name = "Revenant"
	midround_ruleset_style = MIDROUND_RULESET_STYLE_LIGHT
	ruleset_category = parent_type::ruleset_category |  RULESET_CATEGORY_NO_WITTING_CREW_ANTAGONISTS
	antag_datum = /datum/antagonist/revenant
	antag_flag = ROLE_REVENANT
	required_enemies = list(2,2,1,1,1,1,1,0,0,0)
	required_candidates = 1
	weight = 4
	cost = 5
	minimum_players = 15
	repeatable = TRUE
	signup_item_path = /mob/living/basic/revenant
	var/dead_mobs_required = 20
	var/need_extra_spawns_value = 15
	var/list/spawn_locs = list()

/datum/dynamic_ruleset/midround/from_ghosts/revenant/forget_startup()
	spawn_locs = list()
	return ..()

/datum/dynamic_ruleset/midround/from_ghosts/revenant/acceptable(population=0, threat_level=0)
	if(GLOB.dead_mob_list.len < dead_mobs_required)
		return FALSE
	return ..()

/datum/dynamic_ruleset/midround/from_ghosts/revenant/execute()
	for(var/mob/living/corpse in GLOB.dead_mob_list) //look for any dead bodies
		var/turf/corpse_turf = get_turf(corpse)
		if(corpse_turf && is_station_level(corpse_turf.z))
			spawn_locs += corpse_turf
	if(!spawn_locs.len || spawn_locs.len < need_extra_spawns_value) //look for any morgue trays, crematoriums, ect if there weren't alot of dead bodies on the station to pick from
		for(var/obj/structure/bodycontainer/corpse_container in GLOB.bodycontainers)
			var/turf/container_turf = get_turf(corpse_container)
			if(container_turf && is_station_level(container_turf.z))
				spawn_locs += container_turf
	if(!spawn_locs.len) //If we can't find any valid spawnpoints, try the carp spawns
		for(var/obj/effect/landmark/carpspawn/carp_spawnpoint in GLOB.landmarks_list)
			if(isturf(carp_spawnpoint.loc))
				spawn_locs += carp_spawnpoint.loc
	if(!spawn_locs.len) //If we can't find THAT, then just give up and cry
		return FALSE
	. = ..()

/datum/dynamic_ruleset/midround/from_ghosts/revenant/generate_ruleset_body(mob/applicant)
	var/mob/living/basic/revenant/revenant = new(pick(spawn_locs))
	revenant.PossessByPlayer(applicant.ckey)
	message_admins("[ADMIN_LOOKUPFLW(revenant)] has been made into a revenant by the midround ruleset.")
	log_game("[key_name(revenant)] was spawned as a revenant by the midround ruleset.")
	return revenant

/// Midround Space Pirates Ruleset (From Ghosts)
/datum/dynamic_ruleset/midround/pirates
	name = "Space Pirates"
	midround_ruleset_style = MIDROUND_RULESET_STYLE_LIGHT
	ruleset_category = parent_type::ruleset_category |  RULESET_CATEGORY_NO_WITTING_CREW_ANTAGONISTS
	antag_flag = "Space Pirates"
	required_type = /mob/dead/observer
	required_enemies = list(2,2,1,1,1,1,1,0,0,0)
	required_candidates = 0
	weight = 3
	cost = 8
	minimum_players = 20
	repeatable = TRUE

/datum/dynamic_ruleset/midround/pirates/acceptable(population=0, threat_level=0)
	if (SSmapping.is_planetary() || GLOB.light_pirate_gangs.len == 0)
		return FALSE
	return ..()

/datum/dynamic_ruleset/midround/pirates/execute()
	send_pirate_threat(GLOB.light_pirate_gangs)
	return ..()

/// Dangerous Space Pirates ruleset
/datum/dynamic_ruleset/midround/dangerous_pirates
	name = "Dangerous Space Pirates"
	midround_ruleset_style = MIDROUND_RULESET_STYLE_HEAVY
	ruleset_category = parent_type::ruleset_category |  RULESET_CATEGORY_NO_WITTING_CREW_ANTAGONISTS
	antag_flag = "Space Pirates"
	required_type = /mob/dead/observer
	required_enemies = list(2,2,1,1,1,1,1,0,0,0)
	required_candidates = 0
	weight = 3
	cost = 8
	minimum_players = 25
	repeatable = TRUE

/datum/dynamic_ruleset/midround/dangerous_pirates/acceptable(population=0, threat_level=0)
	if (SSmapping.is_planetary() || GLOB.heavy_pirate_gangs.len == 0)
		return FALSE
	return ..()

/datum/dynamic_ruleset/midround/dangerous_pirates/execute()
	send_pirate_threat(GLOB.heavy_pirate_gangs)
	return ..()

/// Midround Obsessed Ruleset (From Living)
/datum/dynamic_ruleset/midround/from_living/obsessed
	name = "Obsessed"
	midround_ruleset_style = MIDROUND_RULESET_STYLE_LIGHT
	antag_datum = /datum/antagonist/obsessed
	antag_flag = ROLE_OBSESSED
	ruleset_category = parent_type::ruleset_category |  RULESET_CATEGORY_NO_WITTING_CREW_ANTAGONISTS
	restricted_roles = list(
		JOB_AI,
		JOB_CYBORG,
		ROLE_POSITRONIC_BRAIN,
	)
	required_enemies = list(2,2,1,1,1,1,1,0,0,0)
	required_candidates = 1
	weight = 4
	cost = 3 // Doesn't have the same impact on rounds as revenants, dragons, sentient disease (10) or syndicate infiltrators (5).
	repeatable = TRUE

/datum/dynamic_ruleset/midround/from_living/obsessed/trim_candidates()
	..()
	candidates = living_players
	for(var/mob/living/carbon/human/candidate in candidates)
		if( \
			!candidate.get_organ_by_type(/obj/item/organ/brain) \
			|| candidate.mind.has_antag_datum(/datum/antagonist/obsessed) \
			|| candidate.stat == DEAD \
			|| !(ROLE_OBSESSED in candidate.client?.prefs?.be_special) \
			|| !candidate.mind.assigned_role \
		)
			candidates -= candidate

/datum/dynamic_ruleset/midround/from_living/obsessed/execute()
	var/mob/living/carbon/human/obsessed = pick_n_take(candidates)
	obsessed.gain_trauma(/datum/brain_trauma/special/obsessed)
	message_admins("[ADMIN_LOOKUPFLW(obsessed)] has been made Obsessed by the midround ruleset.")
	log_game("[key_name(obsessed)] was made Obsessed by the midround ruleset.")
	notify_ghosts(
		"[obsessed] has developed an obsession with someone!",
		source = obsessed,
		header = "Love Can Bloom",
	)
	return TRUE

/// Midround Space Changeling Ruleset (From Ghosts)
/datum/dynamic_ruleset/midround/from_ghosts/changeling_midround
	name = "Space Changeling"
	midround_ruleset_style = MIDROUND_RULESET_STYLE_LIGHT
	antag_datum = /datum/antagonist/changeling/space
	antag_flag = ROLE_CHANGELING_MIDROUND
	antag_flag_override = ROLE_CHANGELING
	ruleset_category = parent_type::ruleset_category |  RULESET_CATEGORY_NO_WITTING_CREW_ANTAGONISTS
	required_type = /mob/dead/observer
	required_enemies = list(2,2,1,1,1,1,1,0,0,0)
	required_candidates = 1
	weight = 3
	cost = 7
	minimum_players = 15
	repeatable = TRUE
	signup_item_path = /obj/effect/meteor/meaty/changeling

/datum/dynamic_ruleset/midround/from_ghosts/changeling_midround/generate_ruleset_body(mob/applicant)
	var/body = generate_changeling_meteor(applicant)
	message_admins("[ADMIN_LOOKUPFLW(body)] has been made into a space changeling by the midround ruleset.")
	log_dynamic("[key_name(body)] was spawned as a space changeling by the midround ruleset.")
	return body

/// Midround Paradox Clone Ruleset (From Ghosts)
/datum/dynamic_ruleset/midround/from_ghosts/paradox_clone
	name = "Paradox Clone"
	midround_ruleset_style = MIDROUND_RULESET_STYLE_LIGHT
	antag_datum = /datum/antagonist/paradox_clone
	antag_flag = ROLE_PARADOX_CLONE
	ruleset_category = parent_type::ruleset_category |  RULESET_CATEGORY_NO_WITTING_CREW_ANTAGONISTS
	enemy_roles = list(
		JOB_CAPTAIN,
		JOB_DETECTIVE,
		JOB_HEAD_OF_SECURITY,
		JOB_SECURITY_OFFICER,
		JOB_WARDEN,
	)
	required_enemies = list(2, 2, 1, 1, 1, 1, 1, 0, 0, 0)
	required_candidates = 1
	weight = 4
	cost = 3
	repeatable = TRUE
	signup_item_path = /obj/effect/bluespace_stream
	var/list/possible_spawns = list() ///places the antag can spawn

/datum/dynamic_ruleset/midround/from_ghosts/paradox_clone/forget_startup()
	possible_spawns = list()
	return ..()

/datum/dynamic_ruleset/midround/from_ghosts/paradox_clone/execute()
	possible_spawns += find_maintenance_spawn(atmos_sensitive = TRUE, require_darkness = FALSE)
	if(!possible_spawns.len)
		return MAP_ERROR
	return ..()

/datum/dynamic_ruleset/midround/from_ghosts/paradox_clone/generate_ruleset_body(mob/applicant)
	var/datum/mind/player_mind = new /datum/mind(applicant.key)
	player_mind.active = TRUE

	var/mob/living/carbon/human/clone_victim = find_original()
	var/mob/living/carbon/human/clone = clone_victim.make_full_human_copy(pick(possible_spawns))
	player_mind.transfer_to(clone)

	var/datum/antagonist/paradox_clone/new_datum = player_mind.add_antag_datum(/datum/antagonist/paradox_clone)
	new_datum.original_ref = WEAKREF(clone_victim.mind)
	new_datum.setup_clone()

	playsound(clone, 'sound/items/weapons/zapbang.ogg', 30, TRUE)
	new /obj/item/storage/toolbox/mechanical(clone.loc) //so they dont get stuck in maints

	message_admins("[ADMIN_LOOKUPFLW(clone)] has been made into a Paradox Clone by the midround ruleset.")
	clone.log_message("was spawned as a Paradox Clone of [key_name(clone)] by the midround ruleset.", LOG_GAME)

	return clone

/**
 * Trims through GLOB.player_list and finds a target
 * Returns a single human victim, if none is possible then returns null.
 */
/datum/dynamic_ruleset/midround/from_ghosts/paradox_clone/proc/find_original()
	var/list/possible_targets = list()

	for(var/mob/living/carbon/human/player in GLOB.player_list)
		if(!player.client || !player.mind || player.stat)
			continue
		if(!(player.mind.assigned_role.job_flags & JOB_CREW_MEMBER))
			continue
		possible_targets += player

	if(possible_targets.len)
		return pick(possible_targets)
	return FALSE

#undef MALF_ION_PROB
#undef REPLACE_LAW_WITH_ION_PROB

/// Midround Voidwalker Ruleset (From Ghosts)
/datum/dynamic_ruleset/midround/from_ghosts/voidwalker
	name = "Voidwalker"
	midround_ruleset_style = MIDROUND_RULESET_STYLE_LIGHT
	antag_datum = /datum/antagonist/voidwalker
	antag_flag = ROLE_VOIDWALKER
	antag_flag_override = ROLE_VOIDWALKER
	ruleset_category = parent_type::ruleset_category |  RULESET_CATEGORY_NO_WITTING_CREW_ANTAGONISTS
	required_enemies = list(2,2,1,1,1,1,1,0,0,0)
	required_candidates = 1
	weight = 2
	cost = 5
	minimum_players = 40
	repeatable = TRUE
	signup_item_path = /obj/item/clothing/head/helmet/skull/cosmic
	ruleset_lazy_templates = list(LAZY_TEMPLATE_KEY_VOIDWALKER_VOID)
	/// The space turf we find in acceptable(), cached for ease
	var/space_turf

/datum/dynamic_ruleset/midround/from_ghosts/voidwalker/acceptable(population = 0, threat_level = 0)
	space_turf = find_space_spawn()
	// Space only antag and will die on planetary gravity.
	if(SSmapping.is_planetary() || !space_turf)
		return FALSE
	return ..()

/datum/dynamic_ruleset/midround/from_ghosts/voidwalker/generate_ruleset_body(mob/applicant)
	var/datum/mind/player_mind = new /datum/mind(applicant.key)
	player_mind.active = TRUE

	var/mob/living/carbon/human/voidwalker = new (space_turf)
	player_mind.transfer_to(voidwalker)
	player_mind.set_assigned_role(SSjob.get_job_type(/datum/job/voidwalker))
	player_mind.special_role = antag_flag
	player_mind.add_antag_datum(antag_datum)

	playsound(voidwalker, 'sound/effects/magic/ethereal_exit.ogg', 50, TRUE, -1)
	message_admins("[ADMIN_LOOKUPFLW(voidwalker)] has been made into a Voidwalker by the midround ruleset.")
	log_dynamic("[key_name(voidwalker)] was spawned as a Voidwalker by the midround ruleset.")
	return voidwalker
