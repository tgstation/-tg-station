/obj/item/organ/tongue
	name = "tongue"
	desc = "A fleshy muscle mostly used for lying."
	icon_state = "tongue"

	zone = BODY_ZONE_PRECISE_MOUTH
	slot = ORGAN_SLOT_TONGUE
	attack_verb_continuous = list("licks", "slobbers", "slaps", "frenches", "tongues")
	attack_verb_simple = list("lick", "slobber", "slap", "french", "tongue")
	voice_filter = ""
	/**
	 * A cached list of paths of all the languages this tongue is capable of speaking
	 *
	 * Relates to a mob's ability to speak a language - a mob must be able to speak the language
	 * and have a tongue able to speak the language (or omnitongue) in order to actually speak said language
	 *
	 * To modify this list for subtypes, see [/obj/item/organ/tongue/proc/get_possible_languages]. Do not modify directly.
	 */
	VAR_PRIVATE/list/languages_possible
	/**
	 * A list of languages which are native to this tongue
	 *
	 * When these languages are spoken with this tongue, and modifies speech is true, no modifications will be made
	 * (such as no accent, hissing, or whatever)
	 */
	var/list/languages_native
	///changes the verbage of how you speak. (Permille -> says <-, "I just used a verb!")
	///i hate to say it, but because of sign language, this may have to be a component. and we may have to do some insane shit like putting a component on a component
	var/say_mod = "says"
	///for temporary overrides of the above variable.
	var/temp_say_mod = ""

	/// Whether the owner of this tongue can taste anything. Being set to FALSE will mean no taste feedback will be provided.
	var/sense_of_taste = TRUE
	/// Determines how "sensitive" this tongue is to tasting things, lower is more sensitive.
	/// See [/mob/living/proc/get_taste_sensitivity].
	var/taste_sensitivity = 15
	/// Foodtypes this tongue likes
	var/liked_foodtypes = JUNKFOOD | FRIED //human tastes are default
	/// Foodtypes this tongue dislikes
	var/disliked_foodtypes = GROSS | RAW | CLOTH | BUGS | GORE //human tastes are default
	/// Foodtypes this tongue HATES
	var/toxic_foodtypes = TOXIC //human tastes are default
	/// Whether this tongue modifies speech via signal
	var/modifies_speech = FALSE

/obj/item/organ/tongue/Initialize(mapload)
	. = ..()
	// Setup the possible languages list
	// - get_possible_languages gives us a list of language paths
	// - then we cache it via string list
	// this results in tongues with identical possible languages sharing a cached list instance
	languages_possible = string_list(get_possible_languages())

/obj/item/organ/tongue/examine(mob/user)
	. = ..()
	if(HAS_MIND_TRAIT(user, TRAIT_ENTRAILS_READER)|| isobserver(user))
		if(liked_foodtypes)
			. += span_info("This tongue has an affinity for the taste of [english_list(bitfield_to_list(liked_foodtypes, FOOD_FLAGS_IC))].")
		if(disliked_foodtypes)
			. += span_info("This tongue has an aversion for the taste of [english_list(bitfield_to_list(disliked_foodtypes, FOOD_FLAGS_IC))].")
		if(toxic_foodtypes)
			. += span_info("This tongue's physiology makes [english_list(bitfield_to_list(toxic_foodtypes, FOOD_FLAGS_IC))] toxic.")

/**
 * Used in setting up the "languages possible" list.
 *
 * Override to have your tongue be only capable of speaking certain languages
 * Extend to hvae a tongue capable of speaking additional languages to the base tongue
 *
 * While a user may be theoretically capable of speaking a language, they cannot physically speak it
 * UNLESS they have a tongue with that language possible, UNLESS UNLESS they have omnitongue enabled.
 */
/obj/item/organ/tongue/proc/get_possible_languages()
	RETURN_TYPE(/list)
	// This is the default list of languages most humans should be capable of speaking
	return list(
		/datum/language/common,
		/datum/language/uncommon,
		/datum/language/draconic,
		/datum/language/codespeak,
		/datum/language/monkey,
		/datum/language/narsie,
		/datum/language/beachbum,
		/datum/language/aphasia,
		/datum/language/piratespeak,
		/datum/language/moffic,
		/datum/language/sylvan,
		/datum/language/shadowtongue,
		/datum/language/terrum,
		/datum/language/nekomimetic,
	)

/obj/item/organ/tongue/proc/handle_speech(datum/source, list/speech_args)
	SIGNAL_HANDLER

	if(should_modify_speech(source, speech_args))
		modify_speech(source, speech_args)

/obj/item/organ/tongue/proc/should_modify_speech(datum/source, list/speech_args)
	if(speech_args[SPEECH_LANGUAGE] in languages_native) // Speaking a native language?
		return FALSE // Don't modify speech
	if(HAS_TRAIT(source, TRAIT_SIGN_LANG)) // No modifiers for signers - I hate this but I simply cannot get these to combine into one statement
		return FALSE // Don't modify speech
	return TRUE

/obj/item/organ/tongue/proc/modify_speech(datum/source, list/speech_args)
	return speech_args[SPEECH_MESSAGE]

/**
 * Gets the food reaction a tongue would have from the food item,
 * assuming that no check_liked callback was used in the edible component.
 *
 * Can be overriden by subtypes for more complex behavior.
 * Does not get called if the owner has ageusia.
 **/
/obj/item/organ/tongue/proc/get_food_taste_reaction(obj/item/food, foodtypes = NONE)
	var/food_taste_reaction
	if(foodtypes & toxic_foodtypes)
		food_taste_reaction = FOOD_TOXIC
	else if(foodtypes & disliked_foodtypes)
		food_taste_reaction = FOOD_DISLIKED
	else if(foodtypes & liked_foodtypes)
		food_taste_reaction = FOOD_LIKED
	return food_taste_reaction

/obj/item/organ/tongue/on_mob_insert(mob/living/carbon/receiver, special, movement_flags)
	. = ..()

	if(modifies_speech)
		RegisterSignal(receiver, COMSIG_MOB_SAY, PROC_REF(handle_speech))
	receiver.voice_filter = voice_filter
	/* This could be slightly simpler, by making the removal of the
	* NO_TONGUE_TRAIT conditional on the tongue's `sense_of_taste`, but
	* then you can distinguish between ageusia from no tongue, and
	* ageusia from having a non-tasting tongue.
	*/
	REMOVE_TRAIT(receiver, TRAIT_AGEUSIA, NO_TONGUE_TRAIT)
	apply_tongue_effects()

/obj/item/organ/tongue/on_mob_remove(mob/living/carbon/organ_owner, special, movement_flags)
	. = ..()

	temp_say_mod = ""
	UnregisterSignal(organ_owner, COMSIG_MOB_SAY)
	REMOVE_TRAIT(organ_owner, TRAIT_SPEAKS_CLEARLY, SPEAKING_FROM_TONGUE)
	REMOVE_TRAIT(organ_owner, TRAIT_AGEUSIA, ORGAN_TRAIT)
	// Carbons by default start with NO_TONGUE_TRAIT caused TRAIT_AGEUSIA
	ADD_TRAIT(organ_owner, TRAIT_AGEUSIA, NO_TONGUE_TRAIT)
	organ_owner.voice_filter = initial(organ_owner.voice_filter)

/obj/item/organ/tongue/apply_organ_damage(damage_amount, maximum = maxHealth, required_organ_flag)
	. = ..()
	if(!owner)
		return FALSE
	apply_tongue_effects()

/// Applies effects to our owner based on how damaged our tongue is
/obj/item/organ/tongue/proc/apply_tongue_effects()
	if(sense_of_taste)
		//tongues can't taste food when they are failing
		if(organ_flags & ORGAN_FAILING)
			ADD_TRAIT(owner, TRAIT_AGEUSIA, ORGAN_TRAIT)
		else
			REMOVE_TRAIT(owner, TRAIT_AGEUSIA, ORGAN_TRAIT)
	else
		//tongues can't taste food when they lack a sense of taste
		ADD_TRAIT(owner, TRAIT_AGEUSIA, ORGAN_TRAIT)
	if(organ_flags & ORGAN_FAILING)
		REMOVE_TRAIT(owner, TRAIT_SPEAKS_CLEARLY, SPEAKING_FROM_TONGUE)
	else
		ADD_TRAIT(owner, TRAIT_SPEAKS_CLEARLY, SPEAKING_FROM_TONGUE)

/obj/item/organ/tongue/could_speak_language(datum/language/language_path)
	return (language_path in languages_possible)

/obj/item/organ/tongue/get_availability(datum/species/owner_species, mob/living/owner_mob)
	return owner_species.mutanttongue

/obj/item/organ/tongue/lizard
	name = "forked tongue"
	desc = "A thin and long muscle typically found in reptilian races, apparently moonlights as a nose."
	icon_state = "tonguelizard"
	say_mod = "hisses"
	taste_sensitivity = 10 // combined nose + tongue, extra sensitive
	modifies_speech = TRUE
	languages_native = list(/datum/language/draconic)
	liked_foodtypes = GORE | MEAT | SEAFOOD | NUTS | BUGS
	disliked_foodtypes = GRAIN | DAIRY | CLOTH | GROSS
	voice_filter = @{"[0:a] asplit [out0][out2]; [out0] asetrate=%SAMPLE_RATE%*0.9,aresample=%SAMPLE_RATE%,atempo=1/0.9,aformat=channel_layouts=mono,volume=0.2 [p0]; [out2] asetrate=%SAMPLE_RATE%*1.1,aresample=%SAMPLE_RATE%,atempo=1/1.1,aformat=channel_layouts=mono,volume=0.2[p2]; [p0][0][p2] amix=inputs=3"}
	var/static/list/speech_replacements = list(
		new /regex("s+", "g") = "sss",
		new /regex("S+", "g") = "SSS",
		new /regex(@"(\w)x", "g") = "$1kss",
		new /regex(@"(\w)X", "g") = "$1KSSS",
		new /regex(@"\bx([\-|r|R]|\b)", "g") = "ecks$1",
		new /regex(@"\bX([\-|r|R]|\b)", "g") = "ECKS$1",
	)

/obj/item/organ/tongue/lizard/Initialize(mapload)
	. = ..()
	AddComponent(/datum/component/speechmod, replacements = speech_replacements, should_modify_speech = CALLBACK(src, PROC_REF(should_modify_speech)))

/obj/item/organ/tongue/lizard/silver
	name = "silver tongue"
	desc = "A genetic branch of the high society Silver Scales that gives them their silverizing properties. To them, it is everything, and society traitors have their tongue forcibly revoked. Oddly enough, it itself is just blue."
	icon_state = "silvertongue"
	actions_types = list(/datum/action/cooldown/turn_to_statue)

/datum/action/cooldown/turn_to_statue
	name = "Become Statue"
	desc = "Become an elegant silver statue. Its durability and yours are directly tied together, so make sure you're careful."
	button_icon = 'icons/obj/medical/organs/organs.dmi'
	button_icon_state = "silvertongue"
	cooldown_time = 10 SECONDS
	check_flags = AB_CHECK_CONSCIOUS|AB_CHECK_LYING

	/// The statue we turn into.
	/// We only ever make one (in New) and simply move it into nullspace or back.
	var/obj/structure/statue/custom/statue

/datum/action/cooldown/turn_to_statue/New(Target)
	. = ..()
	if(!istype(Target, /obj/item/organ/tongue/lizard/silver))
		stack_trace("Non-silverscale tongue initialized a turn to statue action.")
		qdel(src)
		return

	init_statue()

/datum/action/cooldown/turn_to_statue/Destroy()
	clean_up_statue()
	return ..()

/datum/action/cooldown/turn_to_statue/IsAvailable(feedback)
	. = ..()
	if(!.)
		return FALSE

	if(!isliving(owner))
		return FALSE
	var/obj/item/organ/tongue/lizard/silver/tongue_target = target
	if(tongue_target.owner != owner)
		return FALSE

	if(isnull(statue))
		if(feedback)
			owner.balloon_alert(owner, "you can't seem to statue-ize!")
		return FALSE // permanently bricked
	if(owner.stat != CONSCIOUS)
		if(feedback)
			owner.balloon_alert(owner, "you're too weak!")
		return FALSE

	return TRUE

/datum/action/cooldown/turn_to_statue/Activate(atom/target)
	StartCooldown(3 SECONDS)

	var/is_statue = owner.loc == statue
	if(!is_statue)
		owner.visible_message(
			span_notice("[owner] strikes a glorious pose."),
			span_notice("You strike a glorious pose as you become a statue!"),
		)

	owner.balloon_alert(owner, is_statue ? "breaking free..." : "striking a pose...")
	if(!do_after(owner, (is_statue ? 0.5 SECONDS : 3 SECONDS), target = get_turf(owner)))
		owner.balloon_alert(owner, "interrupted!")
		return

	StartCooldown()

	statue.name = "statue of [owner.real_name]"
	statue.desc = "statue depicting [owner.real_name]"

	if(is_statue)
		statue.visible_message(span_danger("[statue] becomes animated!"))
		owner.forceMove(get_turf(statue))
		statue.moveToNullspace()
		UnregisterSignal(owner, COMSIG_MOVABLE_MOVED)

	else
		owner.visible_message(
			span_notice("[owner] hardens into a silver statue."),
			span_notice("You have become a silver statue!"),
		)
		statue.set_visuals(owner.appearance)
		statue.forceMove(get_turf(owner))
		owner.forceMove(statue)
		RegisterSignal(owner, COMSIG_MOVABLE_MOVED, PROC_REF(human_left_statue))

		var/mob/living/living_owner = owner
		statue.update_integrity(living_owner.health) // Statue has 100 health, humans have 100 health

/// Somehow they used an exploit/teleportation to leave statue, lets clean up
/datum/action/cooldown/turn_to_statue/proc/human_left_statue(atom/movable/mover, atom/oldloc, direction)
	SIGNAL_HANDLER

	statue.moveToNullspace()
	UnregisterSignal(mover, COMSIG_MOVABLE_MOVED)

/// Statue was destroyed via IC means (destruction / deconstruction), dust the owner and drop their stuff
/datum/action/cooldown/turn_to_statue/proc/statue_destroyed(datum/source)
	SIGNAL_HANDLER

	if(isnull(statue.loc))
		return // the statue ended up getting destroyed while in nullspace?

	var/mob/living/carbon/carbon_owner = owner
	UnregisterSignal(carbon_owner, COMSIG_MOVABLE_MOVED)

	to_chat(carbon_owner, span_userdanger("Your existence as a living creature snaps as your statue form crumbles!"))
	carbon_owner.forceMove(get_turf(statue))
	carbon_owner.dust(just_ash = TRUE, drop_items = TRUE)
	carbon_owner.investigate_log("has been dusted from having their Silverscale Statue deconstructed / destroyed.", INVESTIGATE_DEATHS)

	clean_up_statue() // unregister signal before we can do further side effects.

/// Statue was qdeleted outright, do nothing but clear refs.
/datum/action/cooldown/turn_to_statue/proc/statue_deleted(datum/source)
	SIGNAL_HANDLER

	clean_up_statue() // Note that if the lizard is in the statue when they're raw deleted, they too will be raw deleted. This is fine

/// Initializes the statue we're going to hang around inside
/datum/action/cooldown/turn_to_statue/proc/init_statue()
	statue = new()
	statue.set_custom_materials(list(/datum/material/silver = SHEET_MATERIAL_AMOUNT * 5))
	statue.max_integrity = 100 // statues already have 100 max integrity, so this is a safety net
	statue.set_armor(/datum/armor/obj_structure/silverscale_statue_armor)
	statue.flags_ricochet |= RICOCHET_SHINY
	RegisterSignals(statue, list(COMSIG_OBJ_DECONSTRUCT, COMSIG_ATOM_DESTRUCTION), PROC_REF(statue_destroyed))
	RegisterSignal(statue, COMSIG_QDELETING, PROC_REF(statue_deleted))

/// Cleans up the reference to the statue and unregisters signals
/datum/action/cooldown/turn_to_statue/proc/clean_up_statue()
	if(QDELETED(statue))
		statue = null
		return

	UnregisterSignal(statue, list(COMSIG_OBJ_DECONSTRUCT, COMSIG_ATOM_DESTRUCTION, COMSIG_QDELETING))
	QDEL_NULL(statue)

/datum/armor/obj_structure/silverscale_statue_armor
	melee = 50
	bullet = 50
	laser = 70
	energy = 70
	bomb = 50
	fire = 100

/obj/item/organ/tongue/abductor
	name = "superlingual matrix"
	desc = "A mysterious structure that allows for instant communication between users. Pretty impressive until you need to eat something."
	icon_state = "tongueayylmao"
	say_mod = "gibbers"
	sense_of_taste = FALSE
	modifies_speech = TRUE
	var/mothership

/obj/item/organ/tongue/abductor/attack_self(mob/living/carbon/human/tongue_holder)
	if(!istype(tongue_holder))
		return

	var/obj/item/organ/tongue/abductor/tongue = tongue_holder.get_organ_slot(ORGAN_SLOT_TONGUE)
	if(!istype(tongue))
		return

	if(tongue.mothership == mothership)
		to_chat(tongue_holder, span_notice("[src] is already attuned to the same channel as your own."))

	tongue_holder.visible_message(span_notice("[tongue_holder] holds [src] in their hands, and concentrates for a moment."), span_notice("You attempt to modify the attenuation of [src]."))
	if(do_after(tongue_holder, delay=15, target=src))
		to_chat(tongue_holder, span_notice("You attune [src] to your own channel."))
		mothership = tongue.mothership

/obj/item/organ/tongue/abductor/examine(mob/examining_mob)
	. = ..()
	if(HAS_MIND_TRAIT(examining_mob, TRAIT_ABDUCTOR_TRAINING) || isobserver(examining_mob))
		. += span_notice("It can be attuned to a different channel by using it inhand.")
		if(!mothership)
			. += span_notice("It is not attuned to a specific mothership.")
		else
			. += span_notice("It is attuned to [mothership].")

/obj/item/organ/tongue/abductor/modify_speech(datum/source, list/speech_args)
	//Hacks
	var/message = speech_args[SPEECH_MESSAGE]
	var/mob/living/carbon/human/user = source
	var/rendered = span_abductor("<b>[user.real_name]:</b> [message]")
	user.log_talk(message, LOG_SAY, tag=SPECIES_ABDUCTOR)
	for(var/mob/living/carbon/human/living_mob in GLOB.alive_mob_list)
		var/obj/item/organ/tongue/abductor/tongue = living_mob.get_organ_slot(ORGAN_SLOT_TONGUE)
		if(!istype(tongue))
			continue
		if(mothership == tongue.mothership)
			to_chat(living_mob, rendered)

	for(var/mob/dead_mob in GLOB.dead_mob_list)
		var/link = FOLLOW_LINK(dead_mob, user)
		to_chat(dead_mob, "[link] [rendered]")

	speech_args[SPEECH_MESSAGE] = ""

/obj/item/organ/tongue/zombie
	name = "rotting tongue"
	desc = "Between the decay and the fact that it's just lying there you doubt a tongue has ever seemed less sexy."
	icon_state = "tonguezombie"
	say_mod = "moans"
	modifies_speech = TRUE
	taste_sensitivity = 32
	liked_foodtypes = GROSS | MEAT | RAW | GORE
	disliked_foodtypes = NONE

// List of english words that translate to zombie phrases
GLOBAL_LIST_INIT(english_to_zombie, list())

/obj/item/organ/tongue/zombie/proc/add_word_to_translations(english_word, zombie_word)
	GLOB.english_to_zombie[english_word] = zombie_word
	// zombies don't care about grammar (any tense or form is all translated to the same word)
	GLOB.english_to_zombie[english_word + plural_s(english_word)] = zombie_word
	GLOB.english_to_zombie[english_word + "ing"] = zombie_word
	GLOB.english_to_zombie[english_word + "ed"] = zombie_word

/obj/item/organ/tongue/zombie/proc/load_zombie_translations()
	var/list/zombie_translation = strings("zombie_replacement.json", "zombie")
	for(var/zombie_word in zombie_translation)
		// since zombie words are a reverse list, we gotta do this backwards
		var/list/data = islist(zombie_translation[zombie_word]) ? zombie_translation[zombie_word] : list(zombie_translation[zombie_word])
		for(var/english_word in data)
			add_word_to_translations(english_word, zombie_word)
	GLOB.english_to_zombie = sort_list(GLOB.english_to_zombie) // Alphabetizes the list (for debugging)

/obj/item/organ/tongue/zombie/modify_speech(datum/source, list/speech_args)
	var/message = speech_args[SPEECH_MESSAGE]
	if(message[1] != "*")
		// setup the global list for translation if it hasn't already been done
		if(!length(GLOB.english_to_zombie))
			load_zombie_translations()

		// make a list of all words that can be translated
		var/list/message_word_list = splittext(message, " ")
		var/list/translated_word_list = list()
		for(var/word in message_word_list)
			word = GLOB.english_to_zombie[LOWER_TEXT(word)]
			translated_word_list += word ? word : FALSE

		// all occurrences of characters "eiou" (case-insensitive) are replaced with "r"
		message = replacetext(message, regex(@"[eiou]", "ig"), "r")
		// all characters other than "zhrgbmna .!?-" (case-insensitive) are stripped
		message = replacetext(message, regex(@"[^zhrgbmna.!?-\s]", "ig"), "")
		// multiple spaces are replaced with a single (whitespace is trimmed)
		message = replacetext(message, regex(@"(\s+)", "g"), " ")

		var/list/old_words = splittext(message, " ")
		var/list/new_words = list()
		for(var/word in old_words)
			// lower-case "r" at the end of words replaced with "rh"
			word = replacetext(word, regex(@"\lr\b"), "rh")
			// an "a" or "A" by itself will be replaced with "hra"
			word = replacetext(word, regex(@"\b[Aa]\b"), "hra")
			new_words += word

		// if words were not translated, then we apply our zombie speech patterns
		for(var/i in 1 to length(new_words))
			new_words[i] = translated_word_list[i] ? translated_word_list[i] : new_words[i]

		message = new_words.Join(" ")
		message = capitalize(message)
		speech_args[SPEECH_MESSAGE] = message

/obj/item/organ/tongue/alien
	name = "alien tongue"
	desc = "According to leading xenobiologists the evolutionary benefit of having a second mouth in your mouth is \"that it looks badass\"."
	icon_state = "tonguexeno"
	say_mod = "hisses"
	taste_sensitivity = 10 // LIZARDS ARE ALIENS CONFIRMED
	modifies_speech = TRUE // not really, they just hiss
	voice_filter = @{"[0:a] asplit [out0][out2]; [out0] asetrate=%SAMPLE_RATE%*0.8,aresample=%SAMPLE_RATE%,atempo=1/0.8,aformat=channel_layouts=mono [p0]; [out2] asetrate=%SAMPLE_RATE%*1.2,aresample=%SAMPLE_RATE%,atempo=1/1.2,aformat=channel_layouts=mono[p2]; [p0][0][p2] amix=inputs=3"}
// Aliens can only speak alien and a few other languages.
/obj/item/organ/tongue/alien/get_possible_languages()
	return list(
		/datum/language/xenocommon,
		/datum/language/common,
		/datum/language/uncommon,
		/datum/language/draconic, // Both hiss?
		/datum/language/monkey,
	)

/obj/item/organ/tongue/alien/modify_speech(datum/source, list/speech_args)
	var/datum/saymode/xeno/hivemind = speech_args[SPEECH_SAYMODE]
	if(hivemind)
		return

	playsound(owner, SFX_HISS, 25, TRUE, TRUE)

/obj/item/organ/tongue/bone
	name = "bone \"tongue\""
	desc = "Apparently skeletons alter the sounds they produce through oscillation of their teeth, hence their characteristic rattling."
	icon_state = "tonguebone"
	say_mod = "rattles"
	attack_verb_continuous = list("bites", "chatters", "chomps", "enamelles", "bones")
	attack_verb_simple = list("bite", "chatter", "chomp", "enamel", "bone")
	sense_of_taste = FALSE
	liked_foodtypes = GROSS | MEAT | RAW | GORE | DAIRY //skeletons eat spooky shit... and dairy, of course
	disliked_foodtypes = NONE
	modifies_speech = TRUE
	var/chattering = FALSE
	var/phomeme_type = "sans"
	var/list/phomeme_types = list("sans", "papyrus")

/obj/item/organ/tongue/bone/Initialize(mapload)
	. = ..()
	phomeme_type = pick(phomeme_types)

// Bone tongues can speak all default + calcic
/obj/item/organ/tongue/bone/get_possible_languages()
	return ..() + /datum/language/calcic

/obj/item/organ/tongue/bone/modify_speech(datum/source, list/speech_args)
	if (chattering)
		chatter(speech_args[SPEECH_MESSAGE], phomeme_type, source)
	switch(phomeme_type)
		if("sans")
			speech_args[SPEECH_SPANS] |= SPAN_SANS
		if("papyrus")
			speech_args[SPEECH_SPANS] |= SPAN_PAPYRUS

/obj/item/organ/tongue/bone/plasmaman
	name = "plasma bone \"tongue\""
	desc = "Like animated skeletons, Plasmamen vibrate their teeth in order to produce speech."
	icon_state = "tongueplasma"
	modifies_speech = FALSE
	liked_foodtypes = VEGETABLES
	disliked_foodtypes = FRUIT | CLOTH

/obj/item/organ/tongue/robot
	name = "robotic voicebox"
	desc = "A voice synthesizer that can interface with organic lifeforms."
	failing_desc = "seems to be broken."
	organ_flags = ORGAN_ROBOTIC
	icon_state = "tonguerobot"
	say_mod = "states"
	attack_verb_continuous = list("beeps", "boops")
	attack_verb_simple = list("beep", "boop")
	modifies_speech = TRUE
	taste_sensitivity = 25 // not as good as an organic tongue
	organ_traits = list(TRAIT_SILICON_EMOTES_ALLOWED)
	voice_filter = "alimiter=0.9,acompressor=threshold=0.2:ratio=20:attack=10:release=50:makeup=2,highpass=f=1000"

/obj/item/organ/tongue/robot/could_speak_language(datum/language/language_path)
	return TRUE // THE MAGIC OF ELECTRONICS

/obj/item/organ/tongue/robot/modify_speech(datum/source, list/speech_args)
	speech_args[SPEECH_SPANS] |= SPAN_ROBOT

/obj/item/organ/tongue/snail
	name = "radula"
	desc = "A minutely toothed, chitinous ribbon, which as a side effect, makes all snails talk IINNCCRREEDDIIBBLLYY SSLLOOWWLLYY."
	color = "#96DB00" // TODO proper sprite, rather than recoloured pink tongue
	modifies_speech = TRUE
	voice_filter = "atempo=0.5" // makes them talk really slow

/obj/item/organ/tongue/snail/modify_speech(datum/source, list/speech_args)
	var/new_message
	var/message = speech_args[SPEECH_MESSAGE]
	for(var/i in 1 to length(message))
		if(findtext("ABCDEFGHIJKLMNOPWRSTUVWXYZabcdefghijklmnopqrstuvwxyz", message[i])) //Im open to suggestions
			new_message += message[i] + message[i] + message[i] //aaalllsssooo ooopppeeennn tttooo sssuuuggggggeeessstttiiiooonsss
		else
			new_message += message[i]
	speech_args[SPEECH_MESSAGE] = new_message

/obj/item/organ/tongue/ethereal
	name = "electric discharger"
	desc = "A sophisticated ethereal organ, capable of synthesising speech via electrical discharge."
	icon_state = "electrotongue"
	say_mod = "crackles"
	taste_sensitivity = 10 // ethereal tongues function (very loosely) like a gas spectrometer: vaporising a small amount of the food and allowing it to pass to the nose, resulting in more sensitive taste
	liked_foodtypes = NONE //no food is particularly liked by ethereals
	disliked_foodtypes = GROSS
	toxic_foodtypes = NONE //no food is particularly toxic to ethereals
	attack_verb_continuous = list("shocks", "jolts", "zaps")
	attack_verb_simple = list("shock", "jolt", "zap")
	voice_filter = @{"[0:a] asplit [out0][out2]; [out0] asetrate=%SAMPLE_RATE%*0.99,aresample=%SAMPLE_RATE%,volume=0.3 [p0]; [p0][out2] amix=inputs=2"}

// Ethereal tongues can speak all default + voltaic
/obj/item/organ/tongue/ethereal/get_possible_languages()
	return ..() + /datum/language/voltaic

/obj/item/organ/tongue/cat
	name = "felinid tongue"
	desc = "A fleshy muscle mostly used for meowing."
	say_mod = "meows"
	liked_foodtypes = SEAFOOD | ORANGES | BUGS | GORE
	disliked_foodtypes = GROSS | CLOTH | RAW
	organ_traits = list(TRAIT_WOUND_LICKER, TRAIT_FISH_EATER)

/obj/item/organ/tongue/jelly
	name = "jelly tongue"
	desc = "Ah... That's not the sound I expected it to make. Sounds like a Space Autumn Bird."
	say_mod = "chirps"
	liked_foodtypes = MEAT | BUGS
	disliked_foodtypes = GROSS
	toxic_foodtypes = NONE

/obj/item/organ/tongue/jelly/get_food_taste_reaction(obj/item/food, foodtypes = NONE)
	// a silver slime created this? what a delicacy!
	if(HAS_TRAIT(food, TRAIT_FOOD_SILVER))
		return FOOD_LIKED
	return ..()

/obj/item/organ/tongue/monkey
	name = "primitive tongue"
	desc = "For aggressively chimpering. And consuming bananas."
	say_mod = "chimpers"
	liked_foodtypes = MEAT | FRUIT | BUGS
	disliked_foodtypes = CLOTH

/obj/item/organ/tongue/moth
	name = "moth tongue"
	desc = "Moths don't have tongues. Someone get god on the phone, tell them I'm not happy."
	say_mod = "flutters"
	liked_foodtypes = VEGETABLES | DAIRY | CLOTH
	disliked_foodtypes = FRUIT | GROSS | BUGS | GORE
	toxic_foodtypes = MEAT | RAW | SEAFOOD

/obj/item/organ/tongue/zombie
	name = "rotting tongue"
	desc = "Makes you speak like you're at the dentist and you just absolutely refuse to spit because you forgot to mention you were allergic to space shellfish."
	say_mod = "moans"

/obj/item/organ/tongue/mush
	name = "mush-tongue-room"
	desc = "You poof with this. Got it?"
	icon = 'icons/obj/service/hydroponics/seeds.dmi'
	icon_state = "mycelium-angel"
	say_mod = "poofs"

/obj/item/organ/tongue/pod
	name = "pod tongue"
	desc = "A plant-like organ used for speaking and eating."
	say_mod = "whistles"
	liked_foodtypes = VEGETABLES | FRUIT | GRAIN
	disliked_foodtypes = GORE | MEAT | DAIRY | SEAFOOD | BUGS
	foodtype_flags = PODPERSON_ORGAN_FOODTYPES
	color = COLOR_LIME

/obj/item/organ/tongue/golem
	name = "golem tongue"
	desc = "This silicate plate doesn't seem particularly mobile, but golems use it to form sounds."
	color = COLOR_WEBSAFE_DARK_GRAY
	organ_flags = ORGAN_MINERAL
	say_mod = "rumbles"
	sense_of_taste = FALSE
	liked_foodtypes = STONE
	disliked_foodtypes = NONE //you don't care for much else besides stone
	toxic_foodtypes = NONE //you can eat fucking uranium
