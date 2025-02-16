/// The max amount of health a ghoul has.
#define GHOUL_MAX_HEALTH 25
/// The max amount of health a voiceless dead has.
#define MUTE_MAX_HEALTH 50

/datum/heretic_knowledge_tree_column/main/flesh
	neighbour_type_left = /datum/heretic_knowledge_tree_column/lock_to_flesh
	neighbour_type_right = /datum/heretic_knowledge_tree_column/flesh_to_void

	route = PATH_FLESH
	ui_bgr = "node_flesh"

	start = /datum/heretic_knowledge/limited_amount/starting/base_flesh
	grasp = /datum/heretic_knowledge/limited_amount/flesh_grasp
	tier1 = /datum/heretic_knowledge/limited_amount/flesh_ghoul
	mark = 	/datum/heretic_knowledge/mark/flesh_mark
	ritual_of_knowledge = /datum/heretic_knowledge/knowledge_ritual/flesh
	unique_ability = /datum/heretic_knowledge/spell/flesh_surgery
	tier2 = /datum/heretic_knowledge/summon/raw_prophet
	blade = /datum/heretic_knowledge/blade_upgrade/flesh
	tier3 = /datum/heretic_knowledge/summon/stalker
	ascension = /datum/heretic_knowledge/ultimate/flesh_final

/datum/heretic_knowledge/limited_amount/starting/base_flesh
	name = "Principle of Hunger"
	desc = "Opens up the Path of Flesh to you. \
		Allows you to transmute a knife and a pool of blood into a Bloody Blade. \
		You can only create three at a time."
	gain_text = "Hundreds of us starved, but not me... I found strength in my greed."
	required_atoms = list(
		/obj/item/knife = 1,
		/obj/effect/decal/cleanable/blood = 1,
	)
	result_atoms = list(/obj/item/melee/sickly_blade/flesh)
	limit = 3 // Bumped up so they can arm up their ghouls too.
	research_tree_icon_path = 'icons/obj/weapons/khopesh.dmi'
	research_tree_icon_state = "flesh_blade"

/datum/heretic_knowledge/limited_amount/starting/base_flesh/on_research(mob/user, datum/antagonist/heretic/our_heretic)
	. = ..()
	var/datum/objective/heretic_summon/summon_objective = new()
	summon_objective.owner = our_heretic.owner
	our_heretic.objectives += summon_objective

	to_chat(user, span_hierophant("Undertaking the Path of Flesh, you are given another objective."))
	our_heretic.owner.announce_objectives()

/datum/heretic_knowledge/limited_amount/flesh_grasp
	name = "Grasp of Flesh"
	desc = "Your Mansus Grasp gains the ability to create a ghoul out of corpse with a soul. \
		Ghouls have only 25 health and look like husks to the heathens' eyes, but can use Bloody Blades effectively. \
		You can only create one at a time by this method."
	gain_text = "My new found desires drove me to greater and greater heights."

	limit = 1
	cost = 1


	research_tree_icon_path = 'icons/ui_icons/antags/heretic/knowledge.dmi'
	research_tree_icon_state = "grasp_flesh"

/datum/heretic_knowledge/limited_amount/flesh_grasp/on_gain(mob/user, datum/antagonist/heretic/our_heretic)
	RegisterSignal(user, COMSIG_HERETIC_MANSUS_GRASP_ATTACK, PROC_REF(on_mansus_grasp))

/datum/heretic_knowledge/limited_amount/flesh_grasp/on_lose(mob/user, datum/antagonist/heretic/our_heretic)
	UnregisterSignal(user, COMSIG_HERETIC_MANSUS_GRASP_ATTACK)

/datum/heretic_knowledge/limited_amount/flesh_grasp/proc/on_mansus_grasp(mob/living/source, mob/living/target)
	SIGNAL_HANDLER

	if(target.stat != DEAD)
		return

	if(LAZYLEN(created_items) >= limit)
		target.balloon_alert(source, "at ghoul limit!")
		return COMPONENT_BLOCK_HAND_USE

	if(HAS_TRAIT(target, TRAIT_HUSK))
		target.balloon_alert(source, "husked!")
		return COMPONENT_BLOCK_HAND_USE

	if(!IS_VALID_GHOUL_MOB(target))
		target.balloon_alert(source, "invalid body!")
		return COMPONENT_BLOCK_HAND_USE

	target.grab_ghost()

	// The grab failed, so they're mindless or playerless. We can't continue
	if(!target.mind || !target.client)
		target.balloon_alert(source, "no soul!")
		return COMPONENT_BLOCK_HAND_USE

	make_ghoul(source, target)

/// Makes [victim] into a ghoul.
/datum/heretic_knowledge/limited_amount/flesh_grasp/proc/make_ghoul(mob/living/user, mob/living/carbon/human/victim)
	user.log_message("created a ghoul, controlled by [key_name(victim)].", LOG_GAME)
	message_admins("[ADMIN_LOOKUPFLW(user)] created a ghoul, [ADMIN_LOOKUPFLW(victim)].")

	victim.apply_status_effect(
		/datum/status_effect/ghoul,
		GHOUL_MAX_HEALTH,
		user.mind,
		CALLBACK(src, PROC_REF(apply_to_ghoul)),
		CALLBACK(src, PROC_REF(remove_from_ghoul)),
	)

/// Callback for the ghoul status effect - Tracking all of our ghouls
/datum/heretic_knowledge/limited_amount/flesh_grasp/proc/apply_to_ghoul(mob/living/ghoul)
	LAZYADD(created_items, WEAKREF(ghoul))

/// Callback for the ghoul status effect - Tracking all of our ghouls
/datum/heretic_knowledge/limited_amount/flesh_grasp/proc/remove_from_ghoul(mob/living/ghoul)
	LAZYREMOVE(created_items, WEAKREF(ghoul))

/datum/heretic_knowledge/limited_amount/flesh_ghoul
	name = "Imperfect Ritual"
	desc = "Allows you to transmute a corpse and a poppy to create a Voiceless Dead. \
		The corpse does not need to have a soul. \
		Voiceless Dead are mute ghouls and only have 50 health, but can use Bloody Blades effectively. \
		You can only create two at a time."
	gain_text = "I found notes of a dark ritual, unfinished... yet still, I pushed forward."
	required_atoms = list(
		/mob/living/carbon/human = 1,
		/obj/item/food/grown/poppy = 1,
	)
	limit = 2
	cost = 1
	research_tree_icon_path = 'icons/ui_icons/antags/heretic/knowledge.dmi'
	research_tree_icon_state = "ghoul_voiceless"



/datum/heretic_knowledge/limited_amount/flesh_ghoul/recipe_snowflake_check(mob/living/user, list/atoms, list/selected_atoms, turf/loc)
	. = ..()
	if(!.)
		return FALSE

	for(var/mob/living/carbon/human/body in atoms)
		if(body.stat != DEAD)
			continue
		if(!IS_VALID_GHOUL_MOB(body) || HAS_TRAIT(body, TRAIT_HUSK))
			to_chat(user, span_hierophant_warning("[body] is not in a valid state to be made into a ghoul."))
			continue

		// We'll select any valid bodies here. If they're clientless, we'll give them a new one.
		selected_atoms += body
		return TRUE

	loc.balloon_alert(user, "ritual failed, no valid body!")
	return FALSE

/datum/heretic_knowledge/limited_amount/flesh_ghoul/on_finished_recipe(mob/living/user, list/selected_atoms, turf/loc)
	var/mob/living/carbon/human/soon_to_be_ghoul = locate() in selected_atoms
	if(QDELETED(soon_to_be_ghoul)) // No body? No ritual
		stack_trace("[type] reached on_finished_recipe without a human in selected_atoms to make a ghoul out of.")
		loc.balloon_alert(user, "ritual failed, no valid body!")
		return FALSE

	soon_to_be_ghoul.grab_ghost()

	if(!soon_to_be_ghoul.mind || !soon_to_be_ghoul.client)
		message_admins("[ADMIN_LOOKUPFLW(user)] is creating a voiceless dead of a body with no player.")
		var/mob/chosen_one = SSpolling.poll_ghosts_for_target("Do you want to play as [span_danger(soon_to_be_ghoul.real_name)], a [span_notice("voiceless dead")]?", check_jobban = ROLE_HERETIC, role = ROLE_HERETIC, poll_time = 5 SECONDS, checked_target = soon_to_be_ghoul, alert_pic = mutable_appearance('icons/mob/human/human.dmi', "husk"), jump_target = soon_to_be_ghoul, role_name_text = "voiceless dead")
		if(isnull(chosen_one))
			loc.balloon_alert(user, "ritual failed, no ghosts!")
			return FALSE
		message_admins("[key_name_admin(chosen_one)] has taken control of ([key_name_admin(soon_to_be_ghoul)]) to replace an AFK player.")
		soon_to_be_ghoul.ghostize(FALSE)
		soon_to_be_ghoul.PossessByPlayer(chosen_one.key)

	selected_atoms -= soon_to_be_ghoul
	make_ghoul(user, soon_to_be_ghoul)
	return TRUE

/// Makes [victim] into a ghoul.
/datum/heretic_knowledge/limited_amount/flesh_ghoul/proc/make_ghoul(mob/living/user, mob/living/carbon/human/victim)
	user.log_message("created a voiceless dead, controlled by [key_name(victim)].", LOG_GAME)
	message_admins("[ADMIN_LOOKUPFLW(user)] created a voiceless dead, [ADMIN_LOOKUPFLW(victim)].")

	victim.apply_status_effect(
		/datum/status_effect/ghoul,
		MUTE_MAX_HEALTH,
		user.mind,
		CALLBACK(src, PROC_REF(apply_to_ghoul)),
		CALLBACK(src, PROC_REF(remove_from_ghoul)),
	)

/// Callback for the ghoul status effect - Tracks all of our ghouls and applies effects
/datum/heretic_knowledge/limited_amount/flesh_ghoul/proc/apply_to_ghoul(mob/living/ghoul)
	LAZYADD(created_items, WEAKREF(ghoul))
	ADD_TRAIT(ghoul, TRAIT_MUTE, MAGIC_TRAIT)

/// Callback for the ghoul status effect - Tracks all of our ghouls and applies effects
/datum/heretic_knowledge/limited_amount/flesh_ghoul/proc/remove_from_ghoul(mob/living/ghoul)
	LAZYREMOVE(created_items, WEAKREF(ghoul))
	REMOVE_TRAIT(ghoul, TRAIT_MUTE, MAGIC_TRAIT)

/datum/heretic_knowledge/mark/flesh_mark
	name = "Mark of Flesh"
	desc = "Your Mansus Grasp now applies the Mark of Flesh. The mark is triggered from an attack with your Bloody Blade. \
		When triggered, the victim begins to bleed significantly."
	gain_text = "That's when I saw them, the marked ones. They were out of reach. They screamed, and screamed."


	mark_type = /datum/status_effect/eldritch/flesh

/datum/heretic_knowledge/knowledge_ritual/flesh

/datum/heretic_knowledge/spell/flesh_surgery
	name = "Knitting of Flesh"
	desc = "Grants you the spell Knit Flesh. This spell allows you to remove organs from victims \
		without requiring a lengthy surgery. This process is much longer if the target is not dead. \
		This spell also allows you to heal your minions and summons, or restore failing organs to acceptable status."
	gain_text = "But they were not out of my reach for long. With every step, the screams grew, until at last \
		I learned that they could be silenced."
	action_to_add = /datum/action/cooldown/spell/touch/flesh_surgery
	cost = 1

/datum/heretic_knowledge/summon/raw_prophet
	name = "Raw Ritual"
	desc = "Allows you to transmute a pair of eyes, a left arm, and a pool of blood to create a Raw Prophet. \
		Raw Prophets have a greatly increased sight range and x-ray vision, as well as a long range jaunt and \
		the ability to link minds to communicate with ease, but are very fragile and weak in combat."
	gain_text = "I could not continue alone. I was able to summon The Uncanny Man to help me see more. \
		The screams... once constant, now silenced by their wretched appearance. Nothing was out of reach."
	required_atoms = list(
		/obj/item/organ/eyes = 1,
		/obj/effect/decal/cleanable/blood = 1,
		/obj/item/bodypart/arm/left = 1,
	)
	mob_to_summon = /mob/living/basic/heretic_summon/raw_prophet
	cost = 1
	poll_ignore_define = POLL_IGNORE_RAW_PROPHET


/datum/heretic_knowledge/blade_upgrade/flesh
	name = "Bleeding Steel"
	desc = "Your Bloody Blade now causes enemies to bleed heavily on attack."
	gain_text = "The Uncanny Man was not alone. They led me to the Marshal. \
		I finally began to understand. And then, blood rained from the heavens."
	research_tree_icon_path = 'icons/ui_icons/antags/heretic/knowledge.dmi'
	research_tree_icon_state = "blade_upgrade_flesh"
	///What type of wound do we apply on hit
	var/wound_type = /datum/wound/slash/flesh/severe

/datum/heretic_knowledge/blade_upgrade/flesh/do_melee_effects(mob/living/source, mob/living/target, obj/item/melee/sickly_blade/blade)
	if(!iscarbon(target) || source == target)
		return

	var/mob/living/carbon/carbon_target = target
	var/obj/item/bodypart/bodypart = pick(carbon_target.bodyparts)
	var/datum/wound/crit_wound = new wound_type()
	crit_wound.apply_wound(bodypart, attack_direction = get_dir(source, target))

/datum/heretic_knowledge/summon/stalker
	name = "Lonely Ritual"
	desc = "Allows you to transmute a tail of any kind, a stomach, a tongue, a pen and a piece of paper to create a Stalker. \
		Stalkers can jaunt, release EMPs, shapeshift into animals or automatons, and are strong in combat."
	gain_text = "I was able to combine my greed and desires to summon an eldritch beast I had never seen before. \
		An ever shapeshifting mass of flesh, it knew well my goals. The Marshal approved."

	required_atoms = list(
		/obj/item/organ/tail = 1,
		/obj/item/organ/stomach = 1,
		/obj/item/organ/tongue = 1,
		/obj/item/pen = 1,
		/obj/item/paper = 1,
	)
	mob_to_summon = /mob/living/basic/heretic_summon/stalker
	cost = 1

	poll_ignore_define = POLL_IGNORE_STALKER


/datum/heretic_knowledge/ultimate/flesh_final
	name = "Priest's Final Hymn"
	desc = "The ascension ritual of the Path of Flesh. \
		Bring 4 corpses to a transmutation rune to complete the ritual. \
		When completed, you gain the ability to shed your human form \
		and become the Lord of the Night, a supremely powerful creature. \
		Just the act of transforming causes nearby heathens great fear and trauma. \
		While in the Lord of the Night form, you can consume arms to heal and regain segments. \
		Additionally, you can summon three times as many Ghouls and Voiceless Dead, \
		and can create unlimited blades to arm them all."
	gain_text = "With the Marshal's knowledge, my power had peaked. The throne was open to claim. \
		Men of this world, hear me, for the time has come! The Marshal guides my army! \
		Reality will bend to THE LORD OF THE NIGHT or be unraveled! WITNESS MY ASCENSION!"
	required_atoms = list(/mob/living/carbon/human = 4)
	ascension_achievement = /datum/award/achievement/misc/flesh_ascension
	announcement_text = "%SPOOKY% Ever coiling vortex. Reality unfolded. ARMS OUTREACHED, THE LORD OF THE NIGHT, %NAME% has ascended! Fear the ever twisting hand! %SPOOKY%"
	announcement_sound = 'sound/music/antag/heretic/ascend_flesh.ogg'

/datum/heretic_knowledge/ultimate/flesh_final/on_finished_recipe(mob/living/user, list/selected_atoms, turf/loc)
	. = ..()
	var/datum/action/cooldown/spell/shapeshift/shed_human_form/worm_spell = new(user.mind)
	worm_spell.Grant(user)

	var/datum/antagonist/heretic/heretic_datum = GET_HERETIC(user)
	var/datum/heretic_knowledge/limited_amount/flesh_grasp/grasp_ghoul = heretic_datum.get_knowledge(/datum/heretic_knowledge/limited_amount/flesh_grasp)
	grasp_ghoul.limit *= 3
	var/datum/heretic_knowledge/limited_amount/flesh_ghoul/ritual_ghoul = heretic_datum.get_knowledge(/datum/heretic_knowledge/limited_amount/flesh_ghoul)
	ritual_ghoul.limit *= 3
	var/datum/heretic_knowledge/limited_amount/starting/base_flesh/blade_ritual = heretic_datum.get_knowledge(/datum/heretic_knowledge/limited_amount/starting/base_flesh)
	blade_ritual.limit = 999

#undef GHOUL_MAX_HEALTH
#undef MUTE_MAX_HEALTH
