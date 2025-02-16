GLOBAL_LIST_INIT(guardian_radial_images, setup_guardian_radial())

/proc/setup_guardian_radial()
	. = list()
	for(var/mob/living/basic/guardian/guardian_path as anything in subtypesof(/mob/living/basic/guardian))
		var/datum/radial_menu_choice/option = new()
		option.name = initial(guardian_path.creator_name)
		option.image = image(icon = 'icons/hud/guardian.dmi', icon_state = initial(guardian_path.creator_icon))
		option.info = span_boldnotice(initial(guardian_path.creator_desc))
		.[guardian_path] = option

/// An item which grants you your very own soul buddy
/obj/item/guardian_creator
	name = "enchanted deck of tarot cards"
	desc = "An enchanted deck of tarot cards, rumored to be a source of unimaginable power."
	icon = 'icons/obj/toys/playing_cards.dmi'
	icon_state = "deck_tarot_full"
	/// Are we used or in the process of being used? If yes, then we can't be used.
	var/used = FALSE
	/// The visuals we give to the guardian we spawn.
	var/theme = GUARDIAN_THEME_MAGIC
	/// The name of the guardian, for UI/message stuff.
	var/mob_name = "Guardian Spirit"
	/// Message sent when you use it.
	var/use_message = span_holoparasite("You shuffle the deck...")
	/// Message sent when it's already used.
	var/used_message = span_holoparasite("All the cards seem to be blank now.")
	/// Failure message if no ghost picks the holopara.
	var/failure_message = span_boldholoparasite("..And draw a card! It's... blank? Maybe you should try again later.")
	/// Failure message if we don't allow lings.
	var/ling_failure = span_boldholoparasite("The deck refuses to respond to a souless creature such as you.")
	/// Message sent if we successfully get a guardian.
	var/success_message = span_holoparasite("<b>%GUARDIAN</b> has been summoned!")
	/// If true, you are given a random guardian rather than picking from a selection.
	var/random = FALSE
	/// If true, you can have multiple guardians at the same time.
	var/allow_multiple = FALSE
	/// If true, lings can get guardians from this.
	var/allow_changeling = TRUE
	/// If true, a dextrous guardian can get their own guardian, infinite chain!
	var/allow_guardian = FALSE
	/// List of all the guardians this type can spawn.
	var/list/possible_guardians = list( //default, has everything but dextrous
		/mob/living/basic/guardian/assassin,
		/mob/living/basic/guardian/charger,
		/mob/living/basic/guardian/explosive,
		/mob/living/basic/guardian/gaseous,
		/mob/living/basic/guardian/gravitokinetic,
		/mob/living/basic/guardian/lightning,
		/mob/living/basic/guardian/protector,
		/mob/living/basic/guardian/ranged,
		/mob/living/basic/guardian/standard,
		/mob/living/basic/guardian/support,
	)

/obj/item/guardian_creator/Initialize(mapload)
	. = ..()
	var/datum/guardian_fluff/using_theme = GLOB.guardian_themes[theme]
	mob_name = using_theme.name

/obj/item/guardian_creator/attack_self(mob/living/user)
	if(isguardian(user) && !allow_guardian)
		balloon_alert(user, "can't do that!")
		return
	var/list/guardians = user.get_all_linked_holoparasites()
	if(length(guardians) && !allow_multiple)
		balloon_alert(user, "already have one!")
		return
	if(IS_CHANGELING(user) && !allow_changeling)
		to_chat(user, ling_failure)
		return
	if(used)
		to_chat(user, used_message)
		return
	var/list/radial_options = GLOB.guardian_radial_images.Copy()
	for(var/possible_guardian in radial_options)
		if(possible_guardian in possible_guardians)
			continue
		radial_options -= possible_guardian
	var/mob/living/basic/guardian/guardian_path
	if(random)
		guardian_path = pick(possible_guardians)
	else
		guardian_path = show_radial_menu(user, src, radial_options, custom_check = CALLBACK(src, PROC_REF(check_menu), user), radius = 42, require_near = TRUE)
		if(isnull(guardian_path))
			return
	used = TRUE
	to_chat(user, use_message)
	var/guardian_type_name = random ? "Random" : capitalize(initial(guardian_path.creator_name))
	var/mob/chosen_one = SSpolling.poll_ghost_candidates(
		"Do you want to play as [span_danger("[user.real_name]'s")] [span_notice("[guardian_type_name] [mob_name]")]?",
		check_jobban = ROLE_PAI,
		poll_time = 10 SECONDS,
		ignore_category = POLL_IGNORE_HOLOPARASITE,
		alert_pic = guardian_path,
		jump_target = src,
		role_name_text = guardian_type_name,
		amount_to_pick = 1,
	)
	if(chosen_one)
		spawn_guardian(user, chosen_one, guardian_path)
		used = TRUE
		SEND_SIGNAL(src, COMSIG_TRAITOR_ITEM_USED(type))
	else
		to_chat(user, failure_message)
		used = FALSE

/// Actually create our guy
/obj/item/guardian_creator/proc/spawn_guardian(mob/living/user, mob/dead/candidate, guardian_path)
	if(QDELETED(user) || user.stat == DEAD)
		return
	var/list/guardians = user.get_all_linked_holoparasites()
	if(length(guardians) && !allow_multiple)
		balloon_alert(user, "already got one!")
		used = FALSE
		return
	var/datum/guardian_fluff/guardian_theme = GLOB.guardian_themes[theme]
	var/mob/living/basic/guardian/summoned_guardian = new guardian_path(user, guardian_theme)
	summoned_guardian.set_summoner(user, different_person = TRUE)
	summoned_guardian.PossessByPlayer(candidate.key)
	user.log_message("has summoned [key_name(summoned_guardian)], a [summoned_guardian.creator_name] holoparasite.", LOG_GAME)
	summoned_guardian.log_message("was summoned as a [summoned_guardian.creator_name] holoparasite.", LOG_GAME)
	to_chat(user, guardian_theme.get_fluff_string(summoned_guardian.guardian_type))
	to_chat(user, replacetext(success_message, "%GUARDIAN", mob_name))
	summoned_guardian.client?.init_verbs()
	return summoned_guardian

/// Checks to ensure we're still capable of using the radial selector
/obj/item/guardian_creator/proc/check_menu(mob/living/user)
	if(!istype(user))
		return FALSE
	if(user.incapacitated || !user.is_holding(src) || used)
		return FALSE
	return TRUE

/// Guardian creator available in the wizard spellbook. All but support are available.
/obj/item/guardian_creator/wizard
	allow_multiple = TRUE
	possible_guardians = list(
		/mob/living/basic/guardian/assassin,
		/mob/living/basic/guardian/charger,
		/mob/living/basic/guardian/dextrous,
		/mob/living/basic/guardian/explosive,
		/mob/living/basic/guardian/gaseous,
		/mob/living/basic/guardian/gravitokinetic,
		/mob/living/basic/guardian/lightning,
		/mob/living/basic/guardian/protector,
		/mob/living/basic/guardian/ranged,
		/mob/living/basic/guardian/standard,
	)

/obj/item/guardian_creator/wizard/spawn_guardian(mob/living/user, mob/dead/candidate)
	var/mob/guardian = ..()
	if(isnull(guardian))
		return null
	// Add the wizard team datum
	var/datum/antagonist/wizard/antag_datum = user.mind.has_antag_datum(/datum/antagonist/wizard)
	if(isnull(antag_datum))
		return guardian
	if(!antag_datum.wiz_team)
		antag_datum.create_wiz_team()
	guardian.mind.add_antag_datum(/datum/antagonist/wizard_minion, antag_datum.wiz_team)
	return guardian

/// Guardian creator available in the traitor uplink. All but dextrous are available, you can pick which you want, and changelings cannot use it.
/obj/item/guardian_creator/tech
	name = "holoparasite injector"
	desc = "It contains an alien nanoswarm of unknown origin. Though capable of near sorcerous feats via use of hardlight holograms and nanomachines, it requires an organic host as a home base and source of fuel."
	icon = 'icons/obj/medical/syringe.dmi'
	icon_state = "combat_hypo"
	theme = GUARDIAN_THEME_TECH
	allow_changeling = FALSE
	use_message = span_holoparasite("You start to power on the injector...")
	used_message = span_holoparasite("The injector has already been used.")
	failure_message = span_boldholoparasite("...ERROR. BOOT SEQUENCE ABORTED. AI FAILED TO INTIALIZE. PLEASE CONTACT SUPPORT OR TRY AGAIN LATER.")
	ling_failure = span_boldholoparasite("The holoparasites recoil in horror. They want nothing to do with a creature like you.")
	success_message = span_holoparasite("<b>%GUARDIAN</b> is now online!")

/// Guardian creator only spawned by admins, which creates a holographic fish. You can have several of them.
/obj/item/guardian_creator/carp
	name = "holocarp fishsticks"
	desc = "Using the power of Carp'sie, you can catch a carp from byond the veil of Carpthulu, and bind it to your fleshy flesh form."
	icon = 'icons/obj/food/meat.dmi'
	icon_state = "fishfingers"
	theme = GUARDIAN_THEME_CARP
	use_message = span_holoparasite("You put the fishsticks in your mouth...")
	used_message = span_holoparasite("Someone's already taken a bite out of these fishsticks! Ew.")
	failure_message = span_boldholoparasite("You couldn't catch any carp spirits from the seas of Lake Carp. Maybe there are none, maybe you fucked up.")
	ling_failure = span_boldholoparasite("Carp'sie seems to not have taken you as the chosen one. Maybe it's because of your horrifying origin.")
	success_message = span_holoparasite("<b>%GUARDIAN</b> has been caught!")
	allow_multiple = TRUE

/// Guardian creator available to miners from chests, very limited selection and randomly assigned.
/obj/item/guardian_creator/miner
	name = "dusty shard"
	desc = "Seems to be a very old rock, may have originated from a strange meteor."
	icon = 'icons/obj/mining_zones/artefacts.dmi'
	icon_state = "dustyshard"
	theme = GUARDIAN_THEME_MINER
	use_message = span_holoparasite("You pierce your skin with the shard...")
	used_message = span_holoparasite("This shard seems to have lost all its power...")
	failure_message = span_boldholoparasite("The shard hasn't reacted at all. Maybe try again later...")
	ling_failure = span_boldholoparasite("The power of the shard seems to not react with your horrifying, mutated body.")
	success_message = span_holoparasite("<b>%GUARDIAN</b> has appeared!")
	random = TRUE
	//limited to ones which are plausibly useful on lavaland
	possible_guardians = list(
		/mob/living/basic/guardian/charger, // A flying mount which can cross chasms
		/mob/living/basic/guardian/protector, // Bodyblocks projectiles for you
		/mob/living/basic/guardian/ranged, // Shoots the bad guys
		/mob/living/basic/guardian/standard, // Can mine walls
		/mob/living/basic/guardian/support, // Heals and teleports you
	)
