/// Manager for the lost crew bodies, for spawning and granting rewards
GLOBAL_DATUM_INIT(lost_crew_manager, /datum/lost_crew_manager, new)

/// Handles procs and timers for the lost crew bodies
/datum/lost_crew_manager
	/// How many credits we reward the medical budget on a successful revive
	var/credits_on_succes = /datum/supply_pack/medical/lost_crew::cost + CARGO_CRATE_VALUE * 2
	/// How long after successful revival we check to see if theyre still alive, and give rewards
	var/succes_check_time = 3 MINUTES
	/// How much the revived crew start with on their cards
	var/starting_funds = 100

/**
 * Creates a body with random background and injuries
 *
 * Arguments:
 * * revivable - Whether or not we can be revived to grand a ghost controle
 * * container - Humans really dont like not having a loc, so please either give the container where you want to spawn it or a turf
 * * forced_class - To force a specific damage class for some specific lore reason
 * * recovered_items - Items recovered, such as some organs, dropped directly with the body
 * * protected_items - Items that can only be recovered by the revived player
 * * body_data - Debug data we can use to get a readout of what has been done
 */
/datum/lost_crew_manager/proc/create_lost_crew(revivable = TRUE, datum/corpse_damage_class/forced_class, list/recovered_items, list/protected_items, list/body_data = list())
	var/mob/living/carbon/human/new_body = new()
	new_body.death()

	var/static/list/scenarios = list()
	if(!scenarios.len)
		var/list/types = subtypesof(/datum/corpse_damage_class)
		for(var/datum/corpse_damage_class/scenario as anything in types)
			scenarios[scenario] = initial(scenario.weight)

	var/list/datum/callback/on_revive_and_player_occupancy = list()

	var/datum/corpse_damage_class/scenario = forced_class || pick_weight(scenarios)
	scenario = new scenario ()

	scenario.apply_character(new_body, protected_items, recovered_items, on_revive_and_player_occupancy, body_data)
	scenario.apply_injuries(new_body, recovered_items, on_revive_and_player_occupancy, body_data)
	scenario.death_lore += "I should get a formalized assignment!"

	. = new_body
	// so bodies can also be used for runes, morgue, etc
	if(!revivable)
		return

	//it's not necessary since we dont spawn the body until we open the bodybag, but why not be nice for once
	new_body.reagents.add_reagent(/datum/reagent/toxin/formaldehyde, 5)

	if(!recovered_items)
		return

	var/obj/item/paper/paper = new()
	recovered_items += paper

	if(!HAS_TRAIT(new_body, TRAIT_HUSK))
		paper.name = "DO NOT REMOVE BRAIN"
		paper.add_raw_text("Body swapping is not covered by medical insurance for unhusked bodies. Chemical brain explosives have been administered to enforce stipend.")
		var/obj/item/organ/brain/boombrain = new_body.get_organ_by_type(/obj/item/organ/brain)
		//I swear to fuck I will explode you. you're not clever
		//everyone thought of this, but I am the fool for having any faith
		//in people actually wanting to play the job in an interesting manner
		//instead of just taking the easiest way out and learning nothing
		//(no one abused it yet but I am already getting pinged by people who think they've broken the system when really I just expected better of them)
		boombrain.AddElement(/datum/element/dangerous_organ_removal)
	else
		paper.name = "BODYSWAPPING PERMITTED"
		paper.add_raw_text("Body swapping is covered by medical insurance in case of husking and a lack of skill in the practictioner.")

	var/obj/item/organ/brain/hersens = new_body.get_organ_by_type(/obj/item/organ/brain)
	hersens.AddComponent(
		/datum/component/ghostrole_on_revive, \
		/* refuse_revival_if_failed = */ TRUE, \
		/*on_revival = */ CALLBACK(src, PROC_REF(on_successful_revive), hersens, scenario.death_lore, on_revive_and_player_occupancy) \
	)

/// Set a timer for awarding succes and drop some awesome deathlore
/datum/lost_crew_manager/proc/on_successful_revive(obj/item/organ/brain/brain, list/death_lore, list/datum/callback/on_revive_and_player_occupancy)
	var/mob/living/carbon/human/owner = brain.owner

	owner.mind.add_antag_datum(/datum/antagonist/recovered_crew) //for tracking mostly

	var/datum/bank_account/bank_account = new(owner.real_name, owner.mind.assigned_role, owner.dna.species.payday_modifier)
	bank_account.adjust_money(starting_funds, "[starting_funds]cr given to [owner.name] as starting fund.")
	owner.account_id = bank_account.account_id
	bank_account.replaceable = FALSE

	owner.add_mob_memory(/datum/memory/key/account, remembered_id = owner.account_id)

	death_lore += "My account number was [owner.account_id]."

	brain.RemoveElement(/datum/element/dangerous_organ_removal)

	// Drop the sick ass death lore and give them an indicator of who they were and what they can do
	for(var/i in 1 to death_lore.len)
		addtimer(CALLBACK(src, GLOBAL_PROC_REF(to_chat), owner, span_boldnotice(death_lore[i])), 10 SECONDS + 2 SECONDS * i)

	addtimer(CALLBACK(src, PROC_REF(award_succes), owner.mind, death_lore), succes_check_time)

	// Run any callbacks our characters or damages may have placed for some effects for when the player is revived
	for(var/datum/callback/callback as anything in on_revive_and_player_occupancy)
		callback.Invoke()

/// Give medbay a happy announcement and put some money into their budget
/datum/lost_crew_manager/proc/award_succes(datum/mind/revived_mind, list/death_lore)
	// I am incredibly disappointed in you
	if(revived_mind.current.stat == DEAD)
		aas_config_announce(/datum/aas_config_entry/medical_lost_crew_reward, list("PERSON" = revived_mind.name, "AWARD" = 0), null, list(RADIO_CHANNEL_MEDICAL), "Deceased")
		return

	// You are a credit to society
	aas_config_announce(/datum/aas_config_entry/medical_lost_crew_reward, list("PERSON" = revived_mind.name, "AWARD" = credits_on_succes), null, list(RADIO_CHANNEL_MEDICAL), "Revived")

	var/datum/bank_account/medical_budget = SSeconomy.get_dep_account(ACCOUNT_MED)
	medical_budget.adjust_money(credits_on_succes)

/// A box for recovered items that can only be opened by the new crewmember
/obj/item/storage/lockbox/mind
	name = "mind lockbox"
	desc = "A locked box, openable only by one mind."

	/// The mind needed to unlock the box
	var/datum/mind/mind

/obj/item/storage/lockbox/mind/attack_hand(mob/user, list/modifiers)
	if (!(src in user.held_items))
		return ..()
	if(atom_storage.locked && can_unlock(user, silent = TRUE))
		toggle_locked(user)
		return
	return ..()

/obj/item/storage/lockbox/mind/attack_self(mob/user, modifiers)
	if (atom_storage.locked && can_unlock(user))
		toggle_locked(user)
		return
	return ..()

/obj/item/storage/lockbox/mind/can_unlock(mob/living/user, obj/item/card/id/id_card, silent = FALSE)
	if (user.mind == mind)
		return TRUE
	if (!silent)
		balloon_alert(user, "access denied!")
	return FALSE

/obj/item/storage/lockbox/mind/toggle_locked(mob/living/user)
	if(!atom_storage.locked)
		return

	atom_storage.locked = STORAGE_NOT_LOCKED
	balloon_alert(user, "unlocked")
	update_appearance()

/obj/item/storage/lockbox/mind/add_context(atom/source, list/context, obj/item/held_item, mob/user)
	if(broken || user.mind != mind)
		return NONE
	context[SCREENTIP_CONTEXT_LMB] = "Use in-hand to unlock"
	return CONTEXTUAL_SCREENTIP_SET

/datum/aas_config_entry/medical_lost_crew_reward
	name = "Medical Alert: Lost Crew Revival Program"
	announcement_lines_map = list(
		"Deceased" = "Sensors indicate lifesigns of %PERSON have seized. Please inform their family of your failure.",
		"Revived" = "Sensors indicate continued survival of %PERSON. Well done, %AWARDcr has been transferred to the medical budget."
	)
	vars_and_tooltips_map = list(
		"PERSON" = "will be replaced with body's name",
		"AWARD" = "with money that medical department receive, if any"
	)
	modifiable = FALSE
