#define FORCED_SPEECH_COOLDOWN_DURATION 5 SECONDS

GLOBAL_LIST_INIT(strippable_parrot_items, create_strippable_list(list(
	/datum/strippable_item/parrot_headset,
)))


/// Parrots! Klepto bastards that imitate your speech and hoard your shit.
/mob/living/basic/parrot
	name = "parrot"
	desc = "The parrot squawks, \"They're a Parrot! BAWWK!\""
	icon = 'icons/mob/simple/animal.dmi'
	icon_state = "parrot_fly"
	icon_living = "parrot_fly"
	icon_dead = "parrot_dead"
	density = FALSE
	health = 80
	maxHealth = 80
	pass_flags = PASSTABLE | PASSMOB

	guaranteed_butcher_results = list(/obj/item/food/cracker = 1)
	melee_damage_upper = 10
	melee_damage_lower = 5

	response_help_continuous = "pets"
	response_help_simple = "pet"
	response_disarm_continuous = "gently moves aside"
	response_disarm_simple = "gently move aside"
	response_harm_continuous = "swats"
	response_harm_simple = "swat"
	combat_mode = TRUE //parrots now start "aggressive" since only player parrots will nuzzle.
	attack_verb_continuous = "chomps"
	attack_verb_simple = "chomp"
	attack_vis_effect = ATTACK_EFFECT_BITE
	friendly_verb_continuous = "grooms"
	friendly_verb_simple = "groom"
	mob_size = MOB_SIZE_SMALL
	gold_core_spawnable = FRIENDLY_SPAWN

	ai_controller = /datum/ai_controller/basic_controller/parrot

	/// Icon we use while sitting
	var/icon_sit = "parrot_sit"

	///Headset for Poly to yell at engineers :)
	var/obj/item/radio/headset/ears = null

	///Parrots are kleptomaniacs. This variable ... stores the item a parrot is holding.
	var/obj/item/held_item = null

	/// The blackboard key we use to store the string we're repeating
	var/speech_blackboard_key = BB_PARROT_REPEAT_STRING
	/// The generic probability odds we have to do a speech-related action
	var/speech_probability_rate = 5
	/// The generic probability odds we have to switch out our speech string
	var/speech_shuffle_rate = 30

	/// Contains all of the perches that parrots will generally sit on until something catches their eye.
	var/static/list/desired_perches = typecacheof(list(
		/obj/machinery/computer,
		/obj/machinery/dna_scannernew,
		/obj/machinery/nuclearbomb,
		/obj/machinery/recharge_station,
		/obj/machinery/smartfridge,
		/obj/machinery/suit_storage_unit,
		/obj/machinery/telecomms,
		/obj/machinery/teleport,
		/obj/structure/displaycase,
		/obj/structure/filingcabinet,
		/obj/structure/frame/computer,
	))
	///items we wont pick up
	var/static/list/ignore_items = typecacheof(list(/obj/item/radio))

	/// Food that Poly loves to eat (spoiler alert it's just crackers)
	var/static/list/edibles = list(
		/obj/item/food/cracker,
	)
	///list of commands we follow
	var/static/list/pet_commands = list(
		/datum/pet_command/idle,
		/datum/pet_command/free,
		/datum/pet_command/follow,
		/datum/pet_command/perform_trick_sequence,
	)

	/// Tracks the times when we send a phrase through either being pet or attack to ensure it's not abused to flood
	COOLDOWN_DECLARE(forced_speech_cooldown)

/mob/living/basic/parrot/Initialize(mapload)
	. = ..()
	setup_headset()
	update_speech_blackboards()
	ai_controller.set_blackboard_key(BB_PARROT_PERCH_TYPES, desired_perches)
	ai_controller.set_blackboard_key(BB_IGNORE_ITEMS, ignore_items)
	AddElement(/datum/element/pet_bonus) // parrots will listen for the signal this element sends in order to say something in response to the pat
	AddElement(/datum/element/ai_retaliate)
	AddElement(/datum/element/strippable, GLOB.strippable_parrot_items)
	AddElement(/datum/element/simple_flying)
	AddComponent(/datum/component/listen_and_repeat, desired_phrases = get_static_list_of_phrases(), blackboard_key = BB_PARROT_REPEAT_STRING)
	AddComponent(/datum/component/tameable, food_types = edibles, tame_chance = 100, bonus_tame_chance = 0)
	AddComponent(/datum/component/obeys_commands, pet_commands)
	RegisterSignal(src, COMSIG_ATOM_ATTACKBY_SECONDARY, PROC_REF(on_attacked)) // this means we could have a peaceful interaction, like getting a cracker
	RegisterSignal(src, COMSIG_ATOM_WAS_ATTACKED, PROC_REF(on_injured)) // this means we got hurt and it's go time
	RegisterSignal(src, COMSIG_ANIMAL_PET, PROC_REF(on_pet))
	RegisterSignal(src, COMSIG_KB_MOB_DROPITEM_DOWN, PROC_REF(drop_item_on_signal))
	ADD_TRAIT(src, TRAIT_CAN_MOUNT_HUMANS, INNATE_TRAIT)

/mob/living/basic/parrot/Destroy()
	// should have cleaned these up on death, but let's be super safe in case that didn't happen
	if(!QDELETED(ears))
		QDEL_NULL(ears)
	if(!QDELETED(held_item))
		QDEL_NULL(held_item)
	return ..()

/mob/living/basic/parrot/death(gibbed)
	if(held_item)
		held_item.forceMove(drop_location())
		held_item = null

	if(ears)
		ears.forceMove(drop_location())
		ears = null

	if(!isnull(buckled))
		buckled.unbuckle_mob(src, force = TRUE)
	buckled = null
	pixel_x = base_pixel_x
	pixel_y = base_pixel_y

	return ..()

/mob/living/basic/parrot/examine(mob/user)
	. = ..()
	. += "It appears to [isnull(held_item) ? "not be holding anything." : "be holding \a [held_item]."]"

	if(stat != DEAD)
		return

	if(HAS_MIND_TRAIT(user, TRAIT_NAIVE))
		. += pick(
			"It seems tired and shagged out after a long squawk.",
			"It seems to be pining for the fjords.",
			"It's resting. It's a beautiful bird. Lovely plumage.",
		)
	else
		. += pick(
			"This is a late parrot.",
			"This is an ex-parrot.",
			"This parrot is no more.",
		)

/mob/living/basic/parrot/say_dead(message)
	return // this is so flarped

/mob/living/basic/parrot/get_status_tab_items()
	. = ..()
	. += "Held Item: [held_item]"

/mob/living/basic/parrot/radio(message, list/message_mods = list(), list/spans, language) //literally copied from human/radio(), but there's no other way to do this. at least it's better than it used to be.
	. = ..()
	if(. != NONE)
		return

	if(message_mods[MODE_HEADSET])
		if(ears)
			ears.talk_into(src, message, , spans, language, message_mods)
		return ITALICS | REDUCE_RANGE
	else if(message_mods[RADIO_EXTENSION] == MODE_DEPARTMENT)
		if(ears)
			ears.talk_into(src, message, message_mods[RADIO_EXTENSION], spans, language, message_mods)
		return ITALICS | REDUCE_RANGE
	else if(message_mods[RADIO_EXTENSION] in GLOB.radiochannels)
		if(ears)
			ears.talk_into(src, message, message_mods[RADIO_EXTENSION], spans, language, message_mods)
			return ITALICS | REDUCE_RANGE

	return NONE

/mob/living/basic/parrot/update_icon_state()
	. = ..()
	if(stat == DEAD)
		return
	icon_state = HAS_TRAIT(src, TRAIT_PARROT_PERCHED) ? icon_sit : icon_living

/// Proc that we just use to see if we're rightclicking something for perch behavior or dropping the item we currently ahve
/mob/living/basic/parrot/resolve_right_click_attack(atom/target, list/modifiers)
	if(!start_perching(target))
		return SECONDARY_ATTACK_CALL_NORMAL
	if(!isnull(held_item))
		drop_held_item(gently = TRUE)
	return SECONDARY_ATTACK_CANCEL_ATTACK_CHAIN

/// Proc that handles sending the signal and returning a valid phrase to say. Will not do anything if we don't have a stat or if we're cliented.
/// Will return either a string or null.
/mob/living/basic/parrot/proc/get_phrase()
	if(!isnull(client) || stat != CONSCIOUS)
		return null

	if(!COOLDOWN_FINISHED(src, forced_speech_cooldown))
		return null

	var/return_value = SEND_SIGNAL(src, COMSIG_NEEDS_NEW_PHRASE)
	if(return_value & NO_NEW_PHRASE_AVAILABLE)
		return null

	COOLDOWN_START(src, forced_speech_cooldown, FORCED_SPEECH_COOLDOWN_DURATION)
	return ai_controller.blackboard[BB_PARROT_REPEAT_STRING]

/// Proc that listens for when a parrot is pet so we can dispatch a voice line.
/mob/living/basic/parrot/proc/on_pet(mob/living/basic/source, mob/living/petter, modifiers)
	SIGNAL_HANDLER
	var/return_value = get_phrase()
	if(isnull(return_value))
		return

	INVOKE_ASYNC(src, TYPE_PROC_REF(/atom/movable, say), message = return_value, forced = "parrot oneliner on pet")

/// Proc that ascertains the type of perch we're dealing with and starts the perching process.
/// Returns TRUE if we started perching, FALSE otherwise.
/mob/living/basic/parrot/proc/start_perching(atom/target)
	if(HAS_TRAIT(src, TRAIT_PARROT_PERCHED))
		balloon_alert(src, "already perched!")
		return FALSE

	if(ishuman(target))
		return perch_on_human(target)

	if(!is_type_in_typecache(target, desired_perches))
		return FALSE

	forceMove(get_turf(target))
	drop_held_item(gently = TRUE) // comfy :)
	toggle_perched(perched = TRUE)
	RegisterSignal(src, COMSIG_MOVABLE_MOVED, PROC_REF(after_move))
	return TRUE

/mob/living/basic/parrot/proc/after_move(atom/source)
	SIGNAL_HANDLER

	UnregisterSignal(src, COMSIG_MOVABLE_MOVED)
	toggle_perched(perched = FALSE)

/// Proc that will perch us on a human. Returns TRUE if we perched, FALSE otherwise.
/mob/living/basic/parrot/proc/perch_on_human(mob/living/carbon/human/target)
	if(LAZYLEN(target.buckled_mobs) >= target.max_buckled_mobs)
		balloon_alert(src, "can't perch on them!")
		return FALSE

	forceMove(get_turf(target))
	if(!target.buckle_mob(src, TRUE))
		return FALSE

	to_chat(src, span_notice("You sit on [target]'s shoulder."))
	toggle_perched(perched = TRUE)
	RegisterSignal(src, COMSIG_LIVING_SET_BUCKLED, PROC_REF(on_unbuckle))
	return TRUE

/mob/living/basic/parrot/proc/on_unbuckle(mob/living/source, atom/movable/new_buckled)
	SIGNAL_HANDLER

	if(new_buckled)
		return
	UnregisterSignal(src, COMSIG_LIVING_SET_BUCKLED)
	toggle_perched(perched = FALSE)

#define PERCH_SOURCE "perched"

/mob/living/basic/parrot/proc/toggle_perched(perched)
	if(!perched)
		REMOVE_TRAIT(src, TRAIT_PARROT_PERCHED, PERCH_SOURCE)
		remove_offsets(PERCH_SOURCE)
	else
		ADD_TRAIT(src, TRAIT_PARROT_PERCHED, PERCH_SOURCE)
		add_offsets(PERCH_SOURCE, y_add = 9)
	update_appearance(UPDATE_ICON_STATE)

#undef PERCH_SOURCE

/// Master proc which will determine the intent of OUR attacks on an object and summon the relevant procs accordingly.
/// This is pretty much meant for players, AI will use the task-specific procs instead.
/mob/living/basic/parrot/early_melee_attack(atom/target, list/modifiers, ignore_cooldown)
	. = ..()
	if(!.)
		return FALSE

	if(isitem(target) && steal_from_ground(target))
		return FALSE

	if(iscarbon(target) && steal_from_mob(target))
		return FALSE

/// Picks up an item from the ground and puts it in our claws. Returns TRUE if we picked it up, FALSE otherwise.
/mob/living/basic/parrot/proc/steal_from_ground(obj/item/target)
	if(!isnull(held_item))
		balloon_alert(src, "already holding something!")
		return FALSE

	if(target.w_class > WEIGHT_CLASS_SMALL)
		balloon_alert(src, "too big to pick up!")
		return FALSE

	pick_up_item(target)
	visible_message(
		span_notice("[src] grabs [held_item]!"),
		span_notice("You grab [held_item]!"),
		span_hear("You hear the sounds of wings flapping furiously."),
	)
	return TRUE

/// Looks for an item that we can snatch and puts it in our claws. Returns TRUE if we picked it up, FALSE otherwise.
/mob/living/basic/parrot/proc/steal_from_mob(mob/living/carbon/victim)
	if(!isnull(held_item))
		balloon_alert(src, "already holding something!")
		return FALSE

	for(var/obj/item/stealable in victim.held_items)
		if(stealable.w_class > WEIGHT_CLASS_SMALL)
			continue

		if(!victim.temporarilyRemoveItemFromInventory(stealable))
			continue

		visible_message(
			span_notice("[src] grabs [held_item] out of [victim]'s hand!"),
			span_notice("You snag [held_item] out of [victim]'s hand!"),
			span_hear("You hear the sounds of wings flapping furiously."),
		)
		pick_up_item(stealable)
		return TRUE

	return FALSE

/// If we're right-clicked on with a cracker, we eat the cracker.
/mob/living/basic/parrot/proc/on_attacked(mob/living/basic/source, obj/item/thing, mob/living/attacker, params)
	SIGNAL_HANDLER
	if(!istype(thing, /obj/item/food/cracker)) // Poly wants a cracker
		return

	consume_cracker(thing) // potential clash with the tameable element so we'll leave it to that to handle qdeling the cracker.
	return COMPONENT_NO_AFTERATTACK

/// Eats a cracker (or anything i guess). This would be nice to eventually fold into the basic_eating element but we do too much snowflake inventory code stuff for this to be reliable presently.
/// We don't qdel the item here, we assume the invoking proc will have handled that somehow.
/// Returns TRUE if we ate the thing.
/mob/living/basic/parrot/proc/consume_cracker(obj/item/thing)
	to_chat(src, span_notice("[src] eagerly devours \the [thing]."))
	if(!istype(thing, /obj/item/food/cracker))
		return TRUE // we still ate it

	if(health < maxHealth)
		adjustBruteLoss(-10)
	speech_probability_rate *= 1.27
	speech_shuffle_rate += 10
	update_speech_blackboards()
	return TRUE

/// Handles special behavior whenever we are injured.
/mob/living/basic/parrot/proc/on_injured(mob/living/basic/source, mob/living/attacker, attack_flags)
	SIGNAL_HANDLER
	if(!isnull(client) || stat == CONSCIOUS)
		return

	drop_held_item(gently = FALSE)

	var/return_value = get_phrase()
	if(isnull(return_value))
		return

	INVOKE_ASYNC(src, TYPE_PROC_REF(/atom/movable, say), message = return_value, forced = "parrot oneliner on attack")

/// Handles picking up the item we're holding, done in its own proc because of a snowflake edge case we need to account for. No additional logic beyond that.
/// Returns TRUE if we picked it up, FALSE otherwise.
/mob/living/basic/parrot/proc/pick_up_item(obj/item/target)
	if(istype(target, /obj/item/food/cracker))
		consume_cracker(target)
		qdel(target)
		return

	target.forceMove(src)
	held_item = target

/// Handles dropping items we're holding. Gently is a special modifier we can use for special interactions.
/mob/living/basic/parrot/proc/drop_held_item(gently = TRUE)
	if(isnull(held_item))
		balloon_alert(src, "nothing to drop!")
		return

	if(stat != CONSCIOUS) // don't gotta do shit
		return

	if(!gently && isgrenade(held_item))
		var/obj/item/grenade/bomb = held_item
		balloon_alert(src, "bombs away!") // you'll likely die too so we can get away with the `!` here
		bomb.forceMove(drop_location())
		bomb.detonate()
		return

	balloon_alert(src, "dropped item")
	held_item.forceMove(drop_location())

/mob/living/basic/parrot/Exited(atom/movable/gone, direction)
	. = ..()
	if(gone != held_item)
		return
	held_item = null

/mob/living/basic/parrot/vv_edit_var(var_name, vval)
	. = ..() // give admins an easier time when it comes to fucking with poly
	switch(var_name)
		if(NAMEOF(src, speech_probability_rate))
			update_speech_blackboards()
		if(NAMEOF(src, speech_shuffle_rate))
			update_speech_blackboards()

/// Updates our speech blackboards mob-side to reflect the current speech on the controller to ensure everything is synchronized.
/mob/living/basic/parrot/proc/update_speech_blackboards()
	ai_controller.set_blackboard_key(BB_PARROT_REPEAT_PROBABILITY, speech_probability_rate)
	ai_controller.set_blackboard_key(BB_PARROT_PHRASE_CHANGE_PROBABILITY, speech_shuffle_rate)

/// Will simply set up the headset for the parrot to use. Stub, implemented on subtypes.
/mob/living/basic/parrot/proc/setup_headset()
	return

/// Gets a static list of phrases we wish to pass to the element.
/mob/living/basic/parrot/proc/get_static_list_of_phrases()
	var/static/list/default_phrases = list(
		"BAWWWWK george mellons griffing me!",
		"Cracker?",
		"Hello!",
		"Hi!",
	)

	return default_phrases

/// Gets the available channels that this parrot has access to. Returns a list of the channels we can use.
/mob/living/basic/parrot/proc/get_available_channels()
	var/list/returnable_list = list()
	if(isnull(ears))
		return returnable_list

	var/list/headset_channels = ears.channels
	for(var/channel in headset_channels)
		returnable_list += GLOB.channel_tokens[channel] // will return something like ":e" or ":c" y'know

	return returnable_list

/mob/living/basic/parrot/tamed(mob/living/tamer, atom/food)
	new /obj/effect/temp_visual/heart(drop_location())

/mob/living/basic/parrot/proc/drop_item_on_signal(mob/living/user)
	SIGNAL_HANDLER

	drop_held_item()
	return COMSIG_KB_ACTIVATED

#undef FORCED_SPEECH_COOLDOWN_DURATION
