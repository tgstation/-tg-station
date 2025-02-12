/datum/job
	/// The name of the job , used for preferences, bans and more. Make sure you know what you're doing before changing this.
	var/title = "NOPE"

	/// The description of the job, used for preferences menu.
	/// Keep it short and useful. Avoid in-jokes, these are for new players.
	var/description

	/// Innate skill levels unlocked at roundstart. Based on config.jobs_have_minimal_access config setting, for example with a skeleton crew. Format is list(/datum/skill/foo = SKILL_EXP_NOVICE) with exp as an integer or as per code/_DEFINES/skills.dm
	var/list/skills
	/// Innate skill levels unlocked at roundstart. Based on config.jobs_have_minimal_access config setting, for example with a full crew. Format is list(/datum/skill/foo = SKILL_EXP_NOVICE) with exp as an integer or as per code/_DEFINES/skills.dm
	var/list/minimal_skills

	/// Determines who can demote this position
	var/department_head = list()

	/// Tells the given channels that the given mob is the new department head. See communications.dm for valid channels.
	var/list/head_announce = null

	/// Bitflags for the job
	var/auto_deadmin_role_flags = NONE

	/// Players will be allowed to spawn in as jobs that are set to "Station"
	var/faction = FACTION_NONE

	/// How many players can be this job
	var/total_positions = 0

	/// How many players can spawn in as this job
	var/spawn_positions = 0

	/// How many players have this job
	var/current_positions = 0

	/// Supervisors, who this person answers to directly
	var/supervisors = ""

	/// What kind of mob type joining players with this job as their assigned role are spawned as.
	var/spawn_type = /mob/living/carbon/human

	/// If this is set to 1, a text is printed to the player when jobs are assigned, telling him that he should let admins know that he has to disconnect.
	var/req_admin_notify

	/// If you have the use_age_restriction_for_jobs config option enabled and the database set up, this option will add a requirement for players to be at least minimal_player_age days old. (meaning they first signed in at least that many days before.)
	var/minimal_player_age = 0

	var/outfit = null

	/// The job's outfit that will be assigned for plasmamen.
	var/plasmaman_outfit = null

	/// Minutes of experience-time required to play in this job. The type is determined by [exp_required_type] and [exp_required_type_department] depending on configs.
	var/exp_requirements = 0
	/// Experience required to play this job, if the config is enabled, and `exp_required_type_department` is not enabled with the proper config.
	var/exp_required_type = ""
	/// Department experience required to play this job, if the config is enabled.
	var/exp_required_type_department = ""
	/// Experience type granted by playing in this job.
	var/exp_granted_type = ""

	///How much money does this crew member make in a single paycheck? Note that passive paychecks are capped to PAYCHECK_CREW in regular gameplay after roundstart.
	var/paycheck = PAYCHECK_CREW
	///Which department does this paycheck pay from?
	var/paycheck_department = ACCOUNT_CIV

	/// Traits added to the mind of the mob assigned this job
	var/list/mind_traits

	///Lazylist of traits added to the liver of the mob assigned this job (used for the classic "cops heal from donuts" reaction, among others)
	var/list/liver_traits = null

	var/display_order = JOB_DISPLAY_ORDER_DEFAULT

	///What types of bounty tasks can this job receive past the default?
	var/bounty_types = CIV_JOB_BASIC

	/// Goodies that can be received via the mail system.
	// this is a weighted list.
	/// Keep the _job definition for this empty and use /obj/item/mail to define general gifts.
	var/list/mail_goodies = list()

	/// If this job's mail goodies compete with generic goodies.
	var/exclusive_mail_goodies = FALSE

	/// Bitfield of departments this job belongs to. These get setup when adding the job into the department, on job datum creation.
	var/departments_bitflags = NONE

	/// If specified, this department will be used for the preferences menu.
	var/datum/job_department/department_for_prefs = null

	/// Lazy list with the departments this job belongs to.
	/// Required to be set for playable jobs.
	/// The first department will be used in the preferences menu,
	/// unless department_for_prefs is set.
	var/list/departments_list = null

	/// Should this job be allowed to be picked for the bureaucratic error event?
	var/allow_bureaucratic_error = TRUE

	///Is this job affected by weird spawns like the ones from station traits
	var/random_spawns_possible = TRUE

	/// List of family heirlooms this job can get with the family heirloom quirk. List of types.
	var/list/family_heirlooms

	/// All values = (JOB_ANNOUNCE_ARRIVAL | JOB_CREW_MANIFEST | JOB_EQUIP_RANK | JOB_CREW_MEMBER | JOB_NEW_PLAYER_JOINABLE | JOB_BOLD_SELECT_TEXT | JOB_ASSIGN_QUIRKS | JOB_CAN_BE_INTERN | JOB_CANNOT_OPEN_SLOTS | JOB_HEAD_OF_STAFF)
	var/job_flags = NONE

	/// Multiplier for general usage of the voice of god.
	var/voice_of_god_power = 1
	/// Multiplier for the silence command of the voice of god.
	var/voice_of_god_silence_power = 1

	/// String. If set to a non-empty one, it will be the key for the policy text value to show this role on spawn.
	var/policy_index = ""

	/// RPG job names, for the memes
	var/rpg_title

	/// Alternate titles to register as pointing to this job.
	var/list/alternate_titles

	var/human_authority = JOB_AUTHORITY_NON_HUMANS_ALLOWED

	/// String key to track any variables we want to tie to this job in config, so we can avoid using the job title. We CAPITALIZE it in order to ensure it's unique and resistant to trivial formatting changes.
	/// You'll probably break someone's config if you change this, so it's best to not to.
	var/config_tag = ""

	/// custom ringtone for this job
	var/job_tone

	/// Minimal character age for this job
	var/required_character_age

	/// If set, look for a policy with this instead of the job title
	var/policy_override

/datum/job/New()
	. = ..()
	var/new_spawn_positions = CHECK_MAP_JOB_CHANGE(title, "spawn_positions")
	if(isnum(new_spawn_positions))
		spawn_positions = new_spawn_positions
	var/new_total_positions = CHECK_MAP_JOB_CHANGE(title, "total_positions")
	if(isnum(new_total_positions))
		total_positions = new_total_positions

/// Executes after the mob has been spawned in the map. Client might not be yet in the mob, and is thus a separate variable.
/datum/job/proc/after_spawn(mob/living/spawned, client/player_client)
	SHOULD_CALL_PARENT(TRUE)
	if(length(mind_traits))
		spawned.mind.add_traits(mind_traits, JOB_TRAIT)

	var/obj/item/organ/liver/liver = spawned.get_organ_slot(ORGAN_SLOT_LIVER)
	if(liver && length(liver_traits))
		liver.add_traits(liver_traits, JOB_TRAIT)

	if(!ishuman(spawned))
		SEND_GLOBAL_SIGNAL(COMSIG_GLOB_JOB_AFTER_SPAWN, src, spawned, player_client)
		return

	var/mob/living/carbon/human/spawned_human = spawned
	var/list/roundstart_experience

	if(player_client)
		for(var/obj/item/organ/our_organ in spawned_human.organs)
			ADD_TRAIT(our_organ, TRAIT_CLIENT_STARTING_ORGAN, ROUNDSTART_TRAIT)

	if(!config) //Needed for robots.
		roundstart_experience = minimal_skills

	if(CONFIG_GET(flag/jobs_have_minimal_access))
		roundstart_experience = minimal_skills
	else
		roundstart_experience = skills

	if(roundstart_experience)
		for(var/i in roundstart_experience)
			spawned_human.mind.adjust_experience(i, roundstart_experience[i], TRUE)

	SEND_GLOBAL_SIGNAL(COMSIG_GLOB_JOB_AFTER_SPAWN, src, spawned, player_client)

/// Return the outfit to use
/datum/job/proc/get_outfit(consistent)
	return outfit

/// Announce that this job as joined the round to all crew members.
/// Note the joining mob has no client at this point.
/datum/job/proc/announce_job(mob/living/joining_mob)
	if(head_announce)
		announce_head(joining_mob, head_announce)


//Used for a special check of whether to allow a client to latejoin as this job.
/datum/job/proc/special_check_latejoin(client/latejoin)
	return TRUE


/mob/living/proc/on_job_equipping(datum/job/equipping, client/player_client)
	return

#define VERY_LATE_ARRIVAL_TOAST_PROB 20

/mob/living/carbon/human/on_job_equipping(datum/job/equipping, client/player_client)
	if(equipping.paycheck_department)
		var/datum/bank_account/bank_account = new(real_name, equipping, dna.species.payday_modifier)
		bank_account.payday(STARTING_PAYCHECKS, TRUE)
		account_id = bank_account.account_id
		bank_account.replaceable = FALSE
		add_mob_memory(/datum/memory/key/account, remembered_id = account_id)

	dress_up_as_job(
		equipping = equipping,
		visual_only = FALSE,
		player_client = player_client,
		consistent = FALSE,
	)

	if(EMERGENCY_PAST_POINT_OF_NO_RETURN && prob(VERY_LATE_ARRIVAL_TOAST_PROB))
		equip_to_slot_or_del(new /obj/item/food/griddle_toast(src), ITEM_SLOT_MASK)

#undef VERY_LATE_ARRIVAL_TOAST_PROB

/mob/living/proc/dress_up_as_job(datum/job/equipping, visual_only = FALSE, client/player_client, consistent = FALSE)
	return

/mob/living/carbon/human/dress_up_as_job(datum/job/equipping, visual_only = FALSE, client/player_client, consistent = FALSE)
	dna.species.pre_equip_species_outfit(equipping, src, visual_only)
	equip_outfit_and_loadout(equipping.get_outfit(consistent), player_client?.prefs, visual_only)

/datum/job/proc/announce_head(mob/living/carbon/human/human, channels) //tells the given channel that the given mob is the new department head. See communications.dm for valid channels.
	if(human)
		//timer because these should come after the captain announcement
		SSticker.OnRoundstart(CALLBACK(GLOBAL_PROC, GLOBAL_PROC_REF(_addtimer), CALLBACK(GLOBAL_PROC, GLOBAL_PROC_REF(aas_config_announce), /datum/aas_config_entry/newhead, list("PERSON" = human.real_name, "RANK" = human.job), null, channels, null, TRUE), 1))

//If the configuration option is set to require players to be logged as old enough to play certain jobs, then this proc checks that they are, otherwise it just returns 1
/datum/job/proc/player_old_enough(client/player)
	if(!player || !available_in_days(player))
		return TRUE //Available in 0 days = available right now = player is old enough to play.
	return FALSE


/datum/job/proc/available_in_days(client/player)
	if(!player)
		return 0

	if(!CONFIG_GET(flag/use_age_restriction_for_jobs))
		return 0

	//Without a database connection we can't get a player's age so we'll assume they're old enough for all jobs
	if(!SSdbcore.Connect())
		return 0

	// If they have been exempted from date availability checks, we assume they are old enough for all jobs.
	// This is only added whenever an admin manually ticks the box for this player.
	if(player.prefs?.db_flags & DB_FLAG_EXEMPT)
		return 0

	// As of the time of writing this comment, verifying database connection isn't "solved". Sometimes rust-g will report a
	// connection mid-shift despite the database dying.
	// If the client age is -1, it means that no code path has overwritten it. Even first time connections get it set to 0,
	// so it's a pretty good indication of a database issue. We'll again just assume they're old enough for all jobs.
	if(player.player_age == -1)
		return 0

	if(!isnum(minimal_player_age))
		return 0

	return max(0, minimal_player_age - player.player_age)

/datum/job/proc/config_check()
	return TRUE

/**
 * # map_check
 *
 * Checks the map config for job changes
 * If they have 0 spawn and total positions in the config, the job is entirely removed from occupations prefs for the round.
 */
/datum/job/proc/map_check()
	var/available_roundstart = TRUE
	var/available_latejoin = TRUE

	var/edited_spawn_positions = CHECK_MAP_JOB_CHANGE(title, "spawn_positions")
	if(!isnull(edited_spawn_positions) && (edited_spawn_positions == 0))
		available_roundstart = FALSE
	var/edited_total_positions = CHECK_MAP_JOB_CHANGE(title, "total_positions")
	if(!isnull(edited_total_positions) && (edited_total_positions == 0))
		available_latejoin = FALSE

	if(!available_roundstart && !available_latejoin) //map config disabled the job
		return FALSE

	return TRUE

/// Gets the message that shows up when spawning as this job
/datum/job/proc/get_spawn_message()
	SHOULD_NOT_OVERRIDE(TRUE)
	return boxed_message(span_infoplain(jointext(get_spawn_message_information(), "\n&bull; ")))

/// Returns a list of strings that correspond to chat messages sent to this mob when they join the round.
/datum/job/proc/get_spawn_message_information()
	SHOULD_CALL_PARENT(TRUE)
	var/list/info = list()
	info += "<b>You are the [title].</b>\n"
	var/related_policy = get_policy(policy_override || title)
	var/radio_info = get_radio_information()
	if(related_policy)
		info += related_policy
	if(supervisors)
		info += "As the [title] you answer directly to [supervisors]. Special circumstances may change this."
	if(radio_info)
		info += radio_info
	if(req_admin_notify)
		info += "<b>You are playing a job that is important for Game Progression. \
			If you have to disconnect, please notify the admins via adminhelp.</b>"
	if(CONFIG_GET(number/minimal_access_threshold))
		info += span_boldnotice("As this station was initially staffed with a \
			[CONFIG_GET(flag/jobs_have_minimal_access) ? "full crew, only your job's necessities" : "skeleton crew, additional access may"] \
			have been added to your ID card.")

	return info

/// Returns information pertaining to this job's radio.
/datum/job/proc/get_radio_information()
	if(job_flags & JOB_CREW_MEMBER)
		return "<b>Prefix your message with :h to speak on your department's radio. To see other prefixes, look closely at your headset.</b>"

/datum/outfit/job
	name = "Standard Gear"

	var/jobtype = null

	uniform = /obj/item/clothing/under/color/grey
	id = /obj/item/card/id/advanced
	ears = /obj/item/radio/headset
	belt = /obj/item/modular_computer/pda
	back = /obj/item/storage/backpack
	shoes = /obj/item/clothing/shoes/sneakers/black
	box = /obj/item/storage/box/survival

	preload = TRUE // These are used by the prefs ui, and also just kinda could use the extra help at roundstart

	var/backpack = /obj/item/storage/backpack
	var/satchel = /obj/item/storage/backpack/satchel
	var/duffelbag = /obj/item/storage/backpack/duffelbag
	var/messenger = /obj/item/storage/backpack/messenger

	var/pda_slot = ITEM_SLOT_BELT

/datum/outfit/job/pre_equip(mob/living/carbon/human/H, visuals_only = FALSE)
	if(ispath(back, /obj/item/storage/backpack))
		switch(H.backpack)
			if(GBACKPACK)
				back = /obj/item/storage/backpack //Grey backpack
			if(GSATCHEL)
				back = /obj/item/storage/backpack/satchel //Grey satchel
			if(GDUFFELBAG)
				back = /obj/item/storage/backpack/duffelbag //Grey Duffel bag
			if(LSATCHEL)
				back = /obj/item/storage/backpack/satchel/leather //Leather Satchel
			if(GMESSENGER)
				back = /obj/item/storage/backpack/messenger //Grey messenger bag
			if(DSATCHEL)
				back = satchel //Department satchel
			if(DDUFFELBAG)
				back = duffelbag //Department duffel bag
			if(DMESSENGER)
				back = messenger //Department messenger bag
			else
				back = backpack //Department backpack

	//converts the uniform string into the path we'll wear, whether it's the skirt or regular variant
	var/holder
	if(H.jumpsuit_style == PREF_SKIRT)
		holder = "[uniform]/skirt"
		if(!text2path(holder))
			holder = "[uniform]"
	else
		holder = "[uniform]"
	uniform = text2path(holder)

	var/client/client = GLOB.directory[ckey(H.mind?.key)]

	if(client?.is_veteran() && client?.prefs.read_preference(/datum/preference/toggle/playtime_reward_cloak))
		neck = /obj/item/clothing/neck/cloak/skill_reward/playing

/datum/outfit/job/post_equip(mob/living/carbon/human/equipped, visuals_only = FALSE)
	if(visuals_only)
		return

	var/datum/job/equipped_job = SSjob.get_job_type(jobtype)

	if(!equipped_job)
		equipped_job = SSjob.get_job(equipped.job)

	var/obj/item/card/id/card = equipped.wear_id

	if(istype(card))
		ADD_TRAIT(card, TRAIT_JOB_FIRST_ID_CARD, ROUNDSTART_TRAIT)
		shuffle_inplace(card.access) // Shuffle access list to make NTNet passkeys less predictable
		card.registered_name = equipped.real_name

		if(equipped.age)
			card.registered_age = equipped.age

		card.update_label()
		card.update_icon()
		var/datum/bank_account/account = SSeconomy.bank_accounts_by_id["[equipped.account_id]"]

		if(account && account.account_id == equipped.account_id)
			card.registered_account = account
			account.bank_cards += card

		equipped.sec_hud_set_ID()

	var/obj/item/modular_computer/pda/pda = equipped.get_item_by_slot(pda_slot)

	if(istype(pda))
		pda.imprint_id(equipped.real_name, equipped_job.title)
		pda.update_ringtone(equipped_job.job_tone)
		pda.UpdateDisplay()

		var/client/equipped_client = GLOB.directory[ckey(equipped.mind?.key)]

		if(equipped_client)
			pda.update_pda_prefs(equipped_client)


/datum/outfit/job/get_chameleon_disguise_info()
	var/list/types = ..()
	types -= /obj/item/storage/backpack //otherwise this will override the actual backpacks
	types += backpack
	types += satchel
	types += duffelbag
	return types

/datum/outfit/job/get_types_to_preload()
	var/list/preload = ..()
	preload += backpack
	preload += satchel
	preload += duffelbag
	preload += /obj/item/storage/backpack/satchel/leather
	var/skirtpath = "[uniform]/skirt"
	preload += text2path(skirtpath)
	return preload

/// An overridable getter for more dynamic goodies.
/datum/job/proc/get_mail_goodies(mob/recipient)
	return mail_goodies


/datum/job/proc/award_service(client/winner, award)
	return


/datum/job/proc/get_captaincy_announcement(mob/living/captain)
	return "Due to extreme staffing shortages, newly promoted Acting Captain [captain.real_name] on deck!"


/// Returns an atom where the mob should spawn in.
/datum/job/proc/get_roundstart_spawn_point()
	if(random_spawns_possible)
		if(HAS_TRAIT(SSstation, STATION_TRAIT_LATE_ARRIVALS))
			return get_latejoin_spawn_point()
		if(HAS_TRAIT(SSstation, STATION_TRAIT_RANDOM_ARRIVALS))
			return get_safe_random_station_turf(typesof(/area/station/hallway)) || get_latejoin_spawn_point()
		if(HAS_TRAIT(SSstation, STATION_TRAIT_HANGOVER))
			var/obj/effect/landmark/start/hangover_spawn_point
			for(var/obj/effect/landmark/start/hangover/hangover_landmark in GLOB.start_landmarks_list)
				hangover_spawn_point = hangover_landmark
				if(hangover_landmark.used) //so we can revert to spawning them on top of eachother if something goes wrong
					continue
				hangover_landmark.used = TRUE
				break
			return hangover_spawn_point || get_latejoin_spawn_point()
	if(length(GLOB.jobspawn_overrides[title]))
		return pick(GLOB.jobspawn_overrides[title])
	var/obj/effect/landmark/start/spawn_point = get_default_roundstart_spawn_point()
	if(!spawn_point) //if there isn't a spawnpoint send them to latejoin, if there's no latejoin go yell at your mapper
		return get_latejoin_spawn_point()
	return spawn_point


/// Handles finding and picking a valid roundstart effect landmark spawn point, in case no uncommon different spawning events occur.
/datum/job/proc/get_default_roundstart_spawn_point()
	for(var/obj/effect/landmark/start/spawn_point as anything in GLOB.start_landmarks_list)
		if(spawn_point.name != title)
			continue
		. = spawn_point
		if(spawn_point.used) //so we can revert to spawning them on top of eachother if something goes wrong
			continue
		spawn_point.used = TRUE
		break
	if(!.)
		log_mapping("Job [title] ([type]) couldn't find a round start spawn point.")

/// Finds a valid latejoin spawn point, checking for events and special conditions.
/datum/job/proc/get_latejoin_spawn_point()
	if(length(GLOB.jobspawn_overrides[title])) //We're doing something special today.
		return pick(GLOB.jobspawn_overrides[title])
	if(length(SSjob.latejoin_trackers))
		return pick(SSjob.latejoin_trackers)
	return SSjob.get_last_resort_spawn_points()


/// Spawns the mob to be played as, taking into account preferences and the desired spawn point.
/datum/job/proc/get_spawn_mob(client/player_client, atom/spawn_point)
	var/mob/living/spawn_instance
	if(ispath(spawn_type, /mob/living/silicon/ai))
		// This is unfortunately necessary because of snowflake AI init code. To be refactored.
		spawn_instance = new spawn_type(get_turf(spawn_point), null, player_client.mob)
	else
		spawn_instance = new spawn_type(player_client.mob.loc)
		spawn_point.JoinPlayerHere(spawn_instance, TRUE)
	spawn_instance.apply_prefs_job(player_client, src)
	if(!player_client)
		qdel(spawn_instance)
		return // Disconnected while checking for the appearance ban.
	return spawn_instance


/// Applies the preference options to the spawning mob, taking the job into account. Assumes the client has the proper mind.
/mob/living/proc/apply_prefs_job(client/player_client, datum/job/job)


/mob/living/carbon/human/apply_prefs_job(client/player_client, datum/job/job)
	var/fully_randomize = GLOB.current_anonymous_theme || player_client.prefs.should_be_random_hardcore(job, player_client.mob.mind) || is_banned_from(player_client.ckey, "Appearance")
	if(!player_client)
		return // Disconnected while checking for the appearance ban.

	var/human_authority_setting = CONFIG_GET(string/human_authority)
	var/require_human = FALSE

	// If the job in question is a head of staff,
	// check the config to see if we should force the player onto a human character or not
	if(job.job_flags & JOB_HEAD_OF_STAFF)
		switch(human_authority_setting)

			// If non-humans are the norm and jobs must be forced to be only for humans
			// then we only force the player to be a human if the job exclusively allows humans
			if(HUMAN_AUTHORITY_HUMAN_WHITELIST)
				require_human = job.human_authority == JOB_AUTHORITY_HUMANS_ONLY

			// If humans are the norm and jobs must be allowed to be played by non-humans
			// then we only force the player to be a human if the job doesn't allow for non-humans to play it
			if(HUMAN_AUTHORITY_NON_HUMAN_WHITELIST)
				require_human = job.human_authority != JOB_AUTHORITY_NON_HUMANS_ALLOWED

			// If humans are the norm and there is no chance that a non-human can be a head of staff
			// always return true, since there is no chance that a non-human can be a head of staff.
			if(HUMAN_AUTHORITY_ENFORCED)
				require_human = TRUE

	src.job = job.title

	if(fully_randomize)
		player_client.prefs.apply_prefs_to(src)

		if(require_human)
			randomize_human_appearance(~RANDOMIZE_SPECIES)
		else
			randomize_human_appearance()

		if (require_human)
			set_species(/datum/species/human)
			dna.species.roundstart_changed = TRUE

		if(GLOB.current_anonymous_theme)
			fully_replace_character_name(null, GLOB.current_anonymous_theme.anonymous_name(src))
	else
		var/is_antag = (player_client.mob.mind in GLOB.pre_setup_antags)
		if(require_human)
			player_client.prefs.randomise["species"] = FALSE
		player_client.prefs.safe_transfer_prefs_to(src, TRUE, is_antag)
		if(require_human && !ishumanbasic(src))
			set_species(/datum/species/human)
			dna.species.roundstart_changed = TRUE
			apply_pref_name(/datum/preference/name/backup_human, player_client)
		if(CONFIG_GET(flag/force_random_names))
			real_name = generate_random_name_species_based(
				player_client.prefs.read_preference(/datum/preference/choiced/gender),
				TRUE,
				player_client.prefs.read_preference(/datum/preference/choiced/species),
			)
	dna.update_dna_identity()
	updateappearance()

/mob/living/silicon/ai/apply_prefs_job(client/player_client, datum/job/job)
	if(GLOB.current_anonymous_theme)
		fully_replace_character_name(real_name, GLOB.current_anonymous_theme.anonymous_ai_name(TRUE))
		return
	apply_pref_name(/datum/preference/name/ai, player_client) // This proc already checks if the player is appearance banned.
	set_core_display_icon(null, player_client)
	apply_pref_emote_display(player_client)
	apply_pref_hologram_display(player_client)

/mob/living/silicon/robot/apply_prefs_job(client/player_client, datum/job/job)
	if(mmi)
		var/organic_name
		if(GLOB.current_anonymous_theme)
			organic_name = GLOB.current_anonymous_theme.anonymous_name(src)
		else if(player_client.prefs.read_preference(/datum/preference/choiced/random_name) == RANDOM_ENABLED || CONFIG_GET(flag/force_random_names) || is_banned_from(player_client.ckey, "Appearance"))
			if(!player_client)
				return // Disconnected while checking the appearance ban.

			organic_name = generate_random_name_species_based(
				player_client.prefs.read_preference(/datum/preference/choiced/gender),
				TRUE,
				player_client.prefs.read_preference(/datum/preference/choiced/species),
			)
		else
			if(!player_client)
				return // Disconnected while checking the appearance ban.
			organic_name = player_client.prefs.read_preference(/datum/preference/name/real_name)

		mmi.name = "[initial(mmi.name)]: [organic_name]"
		if(mmi.brain)
			mmi.brain.name = "[organic_name]'s brain"
		if(mmi.brainmob)
			mmi.brainmob.real_name = organic_name //the name of the brain inside the cyborg is the robotized human's name.
			mmi.brainmob.name = organic_name
	// If this checks fails, then the name will have been handled during initialization.
	if(!GLOB.current_anonymous_theme && player_client.prefs.read_preference(/datum/preference/name/cyborg) != DEFAULT_CYBORG_NAME)
		apply_pref_name(/datum/preference/name/cyborg, player_client)

/**
 * Called after a successful roundstart spawn.
 * Client is not yet in the mob.
 * This happens after after_spawn()
 */
/datum/job/proc/after_roundstart_spawn(mob/living/spawning, client/player_client)
	SHOULD_CALL_PARENT(TRUE)


/**
 * Called after a successful latejoin spawn.
 * Client is in the mob.
 * This happens after after_spawn()
 */
/datum/job/proc/after_latejoin_spawn(mob/living/spawning)
	SHOULD_CALL_PARENT(TRUE)
	SEND_GLOBAL_SIGNAL(COMSIG_GLOB_JOB_AFTER_LATEJOIN_SPAWN, src, spawning)
