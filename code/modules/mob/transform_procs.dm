#define TRANSFORMATION_DURATION 22
/// Will be removed once the transformation is complete.
#define TEMPORARY_TRANSFORMATION_TRAIT "temporary_transformation"
/// Considered "permanent" since we'll be deleting the old mob and the client will be inserted into a new one (without this trait)
#define PERMANENT_TRANSFORMATION_TRAIT "permanent_transformation"

/mob/living/carbon/proc/monkeyize(instant = FALSE)
	if (transformation_timer || HAS_TRAIT(src, TRAIT_NO_TRANSFORM))
		return

	if(ismonkey(src))
		return

	if(instant)
		finish_monkeyize()
		return

	//Make mob invisible and spawn animation
	ADD_TRAIT(src, TRAIT_NO_TRANSFORM, TEMPORARY_TRANSFORMATION_TRAIT)
	Stun(TRANSFORMATION_DURATION, ignore_canstun = TRUE)
	icon = null
	cut_overlays()

	var/obj/effect = new /obj/effect/temp_visual/monkeyify(loc)
	effect.SetInvisibility(invisibility)
	SetInvisibility(INVISIBILITY_MAXIMUM, id=type)

	transformation_timer = addtimer(CALLBACK(src, PROC_REF(finish_monkeyize)), TRANSFORMATION_DURATION, TIMER_UNIQUE)

/mob/living/carbon/proc/finish_monkeyize()
	transformation_timer = null
	REMOVE_TRAIT(src, TRAIT_NO_TRANSFORM, TEMPORARY_TRANSFORMATION_TRAIT)
	icon = initial(icon)
	RemoveInvisibility(type)
	set_species(/datum/species/monkey)
	to_chat(src, span_boldnotice("You are now \a [dna.species.name]."))
	name = LOWER_TEXT(dna.species.name)
	regenerate_icons()
	set_name()
	SEND_SIGNAL(src, COMSIG_HUMAN_MONKEYIZE)
	uncuff()
	return src

//////////////////////////           Humanize               //////////////////////////////
//Could probably be merged with monkeyize but other transformations got their own procs, too

/mob/living/carbon/proc/humanize(species = /datum/species/human, instant = FALSE)
	if (transformation_timer || HAS_TRAIT(src, TRAIT_NO_TRANSFORM))
		return

	if(!ismonkey(src))
		return

	if(instant)
		finish_humanize(species)
		return

	//Make mob invisible and spawn animation
	ADD_TRAIT(src, TRAIT_NO_TRANSFORM, TEMPORARY_TRANSFORMATION_TRAIT)
	Stun(TRANSFORMATION_DURATION, ignore_canstun = TRUE)
	icon = null
	cut_overlays()

	var/obj/effect = new /obj/effect/temp_visual/monkeyify/humanify(loc)
	effect.SetInvisibility(invisibility)
	SetInvisibility(INVISIBILITY_MAXIMUM, id=type)

	transformation_timer = addtimer(CALLBACK(src, PROC_REF(finish_humanize), species), TRANSFORMATION_DURATION, TIMER_UNIQUE)


/mob/living/carbon/proc/finish_humanize(species = /datum/species/human)
	transformation_timer = null
	REMOVE_TRAIT(src, TRAIT_NO_TRANSFORM, TEMPORARY_TRANSFORMATION_TRAIT)
	icon = initial(icon)
	RemoveInvisibility(type)
	set_species(species)
	to_chat(src, span_boldnotice("You are now \a [dna.species.name]."))
	SEND_SIGNAL(src, COMSIG_MONKEY_HUMANIZE)
	return src

/mob/living/carbon/human/finish_humanize(species = /datum/species/human)
	underwear = "Nude"
	undershirt = "Nude"
	socks = "Nude"
	return ..()

/mob/proc/AIize(client/preference_source, move = TRUE)
	var/list/turf/landmark_loc = list()

	if(!move)
		landmark_loc += loc
	else
		for(var/obj/effect/landmark/start/ai/sloc in GLOB.landmarks_list)
			if(locate(/mob/living/silicon/ai) in sloc.loc)
				continue
			if(sloc.primary_ai)
				LAZYCLEARLIST(landmark_loc)
				landmark_loc += sloc.loc
				break
			landmark_loc += sloc.loc
		if(!length(landmark_loc))
			to_chat(src, "Oh god sorry we can't find an unoccupied AI spawn location, so we're spawning you on top of someone.")
			for(var/obj/effect/landmark/start/ai/sloc in GLOB.landmarks_list)
				landmark_loc += sloc.loc

	if(!length(landmark_loc))
		message_admins("Could not find ai landmark for [src]. Yell at a mapper! We are spawning them at their current location.")
		landmark_loc += loc

	if(client)
		stop_sound_channel(CHANNEL_LOBBYMUSIC)

	var/mob/living/silicon/ai/our_AI = new /mob/living/silicon/ai(pick(landmark_loc), null, src)
	. = our_AI

	if(preference_source)
		apply_pref_name(/datum/preference/name/ai, preference_source)
		our_AI.apply_pref_hologram_display(preference_source)
		our_AI.set_core_display_icon(null, preference_source)

	qdel(src)

/mob/living/carbon/AIize(client/preference_source, transfer_after = TRUE)
	if(HAS_TRAIT(src, TRAIT_NO_TRANSFORM))
		return
	ADD_TRAIT(src, TRAIT_NO_TRANSFORM, PERMANENT_TRANSFORMATION_TRAIT)
	Paralyze(1, ignore_canstun = TRUE)
	for(var/obj/item/W in src)
		dropItemToGround(W)
	regenerate_icons()
	icon = null
	SetInvisibility(INVISIBILITY_MAXIMUM)
	return ..()

/mob/living/carbon/human/AIize(client/preference_source, transfer_after = TRUE)
	if(HAS_TRAIT(src, TRAIT_NO_TRANSFORM))
		return

	return ..()

/mob/proc/Robotize(delete_items = 0, transfer_after = TRUE)
	if(HAS_TRAIT(src, TRAIT_NO_TRANSFORM))
		return
	ADD_TRAIT(src, TRAIT_NO_TRANSFORM, PERMANENT_TRANSFORMATION_TRAIT)
	var/mob/living/silicon/robot/new_borg = new /mob/living/silicon/robot(loc)

	new_borg.gender = gender
	new_borg.SetInvisibility(INVISIBILITY_NONE)

	if(client?.prefs.read_preference(/datum/preference/name/cyborg) != DEFAULT_CYBORG_NAME)
		new_borg.apply_pref_name(/datum/preference/name/cyborg, client)

	if(mind) //TODO //TODO WHAT
		if(!transfer_after)
			mind.active = FALSE
		mind.transfer_to(new_borg, TRUE)
	else if(transfer_after)
		new_borg.PossessByPlayer(key)

	if(new_borg.mmi)
		new_borg.mmi.name = "[initial(new_borg.mmi.name)]: [real_name]"
		if(new_borg.mmi.brain)
			new_borg.mmi.brain.name = "[real_name]'s brain"
		if(new_borg.mmi.brainmob)
			new_borg.mmi.brainmob.real_name = real_name //the name of the brain inside the cyborg is the robotized human's name.
			new_borg.mmi.brainmob.name = real_name

	new_borg.job = JOB_CYBORG
	new_borg.notify_ai(AI_NOTIFICATION_NEW_BORG)

	. = new_borg
	if(new_borg.ckey && is_banned_from(new_borg.ckey, JOB_CYBORG))
		INVOKE_ASYNC(new_borg, TYPE_PROC_REF(/mob/living/silicon/robot, replace_banned_cyborg))
	qdel(src)

/mob/living/Robotize(delete_items = 0, transfer_after = TRUE)
	if(HAS_TRAIT(src, TRAIT_NO_TRANSFORM))
		return
	ADD_TRAIT(src, TRAIT_NO_TRANSFORM, TEMPORARY_TRANSFORMATION_TRAIT)
	Paralyze(1, ignore_canstun = TRUE)

	drop_everything(delete_items)

	regenerate_icons()
	icon = null
	SetInvisibility(INVISIBILITY_MAXIMUM)

	REMOVE_TRAIT(src, TRAIT_NO_TRANSFORM, TEMPORARY_TRANSFORMATION_TRAIT)
	return ..()

/mob/living/silicon/robot/proc/replace_banned_cyborg()
	to_chat(src, "<b>You are job banned from cyborg! Appeal your job ban if you want to avoid this in the future!</b>")
	ghostize(FALSE)

	var/mob/chosen_one = SSpolling.poll_ghosts_for_target("Do you want to play as [span_notice(name)]?", check_jobban = JOB_CYBORG, poll_time = 5 SECONDS, checked_target = src, alert_pic = src, role_name_text = "cyborg")
	if(chosen_one)
		message_admins("[key_name_admin(chosen_one)] has taken control of ([key_name_admin(src)]) to replace a jobbanned player.")
		key = chosen_one.key

//human -> alien
/mob/living/carbon/human/proc/Alienize()
	if(HAS_TRAIT(src, TRAIT_NO_TRANSFORM))
		return
	ADD_TRAIT(src, TRAIT_NO_TRANSFORM, PERMANENT_TRANSFORMATION_TRAIT)
	add_traits(list(TRAIT_IMMOBILIZED, TRAIT_HANDS_BLOCKED), TRAIT_GENERIC)
	for(var/obj/item/W in src)
		dropItemToGround(W)
	regenerate_icons()
	icon = null
	SetInvisibility(INVISIBILITY_MAXIMUM)
	for(var/t in bodyparts)
		qdel(t)

	var/alien_caste = pick("Hunter","Sentinel","Drone")
	var/mob/living/carbon/alien/adult/new_xeno
	switch(alien_caste)
		if("Hunter")
			new_xeno = new /mob/living/carbon/alien/adult/hunter(loc)
		if("Sentinel")
			new_xeno = new /mob/living/carbon/alien/adult/sentinel(loc)
		if("Drone")
			new_xeno = new /mob/living/carbon/alien/adult/drone(loc)

	new_xeno.set_combat_mode(TRUE)
	new_xeno.PossessByPlayer(key)

	to_chat(new_xeno, span_boldnotice("You are now an alien."))
	qdel(src)
	return new_xeno

/mob/living/carbon/human/proc/slimeize(reproduce as num)
	if(HAS_TRAIT(src, TRAIT_NO_TRANSFORM))
		return
	ADD_TRAIT(src, TRAIT_NO_TRANSFORM, PERMANENT_TRANSFORMATION_TRAIT)
	add_traits(list(TRAIT_IMMOBILIZED, TRAIT_HANDS_BLOCKED), TRAIT_GENERIC)
	for(var/obj/item/W in src)
		dropItemToGround(W)
	regenerate_icons()
	icon = null
	SetInvisibility(INVISIBILITY_MAXIMUM)
	for(var/t in bodyparts)
		qdel(t)

	var/mob/living/basic/slime/new_slime
	if(reproduce)
		var/number = pick(14;2,3,4) //reproduce (has a small chance of producing 3 or 4 offspring)
		var/list/babies = list()
		for(var/i in 1 to number)
			var/mob/living/basic/slime/M = new/mob/living/basic/slime(loc)
			M.set_nutrition(round(nutrition/number))
			step_away(M,src)
			babies += M
		new_slime = pick(babies)
	else
		new_slime = new /mob/living/basic/slime(loc)
	new_slime.set_combat_mode(TRUE)
	new_slime.PossessByPlayer(key)

	to_chat(new_slime, span_boldnotice("You are now a slime. Skreee!"))
	qdel(src)
	return new_slime

/mob/proc/become_overmind(starting_points = OVERMIND_STARTING_POINTS)
	var/mob/eye/blob/B = new /mob/eye/blob(get_turf(src), starting_points)
	B.PossessByPlayer(key)
	. = B
	qdel(src)


/mob/living/carbon/human/proc/corgize()
	if(HAS_TRAIT(src, TRAIT_NO_TRANSFORM))
		return
	ADD_TRAIT(src, TRAIT_NO_TRANSFORM, PERMANENT_TRANSFORMATION_TRAIT)
	Paralyze(1, ignore_canstun = TRUE)
	for(var/obj/item/W in src)
		dropItemToGround(W)
	regenerate_icons()
	icon = null
	SetInvisibility(INVISIBILITY_MAXIMUM)
	for(var/t in bodyparts) //this really should not be necessary
		qdel(t)

	var/mob/living/basic/pet/dog/corgi/new_corgi = new /mob/living/basic/pet/dog/corgi (loc)
	new_corgi.set_combat_mode(TRUE)
	new_corgi.PossessByPlayer(key)

	to_chat(new_corgi, span_boldnotice("You are now a Corgi. Yap Yap!"))
	qdel(src)
	return new_corgi

/**
 * Turns the source atom into a crab crab, the peak of evolutionary design.
 */
/mob/living/carbon/human/proc/crabize()
	if(HAS_TRAIT(src, TRAIT_NO_TRANSFORM))
		return
	ADD_TRAIT(src, TRAIT_NO_TRANSFORM, PERMANENT_TRANSFORMATION_TRAIT)
	Paralyze(1, ignore_canstun = TRUE)
	for(var/obj/item/objeto in src)
		dropItemToGround(objeto)
	regenerate_icons()
	icon = null
	SetInvisibility(INVISIBILITY_MAXIMUM)

	var/mob/living/basic/crab/new_crab = new (loc)
	new_crab.set_combat_mode(TRUE) // snip snip
	if(mind)
		mind.transfer_to(new_crab)

	to_chat(new_crab, span_boldnotice("You have evolved into a crab!"))
	qdel(src)
	return new_crab

/mob/living/carbon/proc/gorillize(genetics_gorilla = FALSE)
	if(HAS_TRAIT(src, TRAIT_NO_TRANSFORM))
		return
	ADD_TRAIT(src, TRAIT_NO_TRANSFORM, PERMANENT_TRANSFORMATION_TRAIT)
	Paralyze(1, ignore_canstun = TRUE)

	SSblackbox.record_feedback("amount", "gorillas_created", 1)

	var/Itemlist = get_equipped_items(INCLUDE_POCKETS)
	Itemlist += held_items
	for(var/obj/item/W in Itemlist)
		dropItemToGround(W, TRUE)

	regenerate_icons()
	icon = null
	SetInvisibility(INVISIBILITY_MAXIMUM)
	var/gorilla_type = genetics_gorilla ? /mob/living/basic/gorilla/genetics : /mob/living/basic/gorilla
	var/mob/living/basic/gorilla/new_gorilla = new gorilla_type(get_turf(src))
	new_gorilla.set_combat_mode(TRUE)
	if(mind)
		mind.transfer_to(new_gorilla)
	else
		new_gorilla.PossessByPlayer(key)
	to_chat(new_gorilla, span_boldnotice("You are now a gorilla. Ooga ooga!"))
	qdel(src)
	return new_gorilla

/mob/living/carbon/human/Animalize()

	var/list/mobtypes = typesof(/mob/living/simple_animal) + typesof(/mob/living/basic)
	var/mobpath = tgui_input_list(usr, "Which type of mob should [src] turn into?", "Choose a type", sort_list(mobtypes, GLOBAL_PROC_REF(cmp_typepaths_asc)))
	if(isnull(mobpath))
		return
	if(!safe_animal(mobpath))
		to_chat(usr, span_danger("Sorry but this mob type is currently unavailable."))
		return

	if(HAS_TRAIT(src, TRAIT_NO_TRANSFORM))
		return
	ADD_TRAIT(src, TRAIT_NO_TRANSFORM, PERMANENT_TRANSFORMATION_TRAIT)
	Paralyze(1, ignore_canstun = TRUE)

	for(var/obj/item/W in src)
		dropItemToGround(W)

	regenerate_icons()
	icon = null
	SetInvisibility(INVISIBILITY_MAXIMUM)

	for(var/t in bodyparts)
		qdel(t)

	var/mob/living/new_mob = new mobpath(src.loc)

	new_mob.PossessByPlayer(key)
	new_mob.set_combat_mode(TRUE)

	to_chat(new_mob, span_boldnotice("You suddenly feel more... animalistic."))
	qdel(src)
	return new_mob

/mob/proc/Animalize()

	var/list/mobtypes = typesof(/mob/living/simple_animal) + typesof(/mob/living/basic)
	var/mobpath = tgui_input_list(usr, "Which type of mob should [src] turn into?", "Choose a type", sort_list(mobtypes, GLOBAL_PROC_REF(cmp_typepaths_asc)))
	if(isnull(mobpath))
		return
	if(!safe_animal(mobpath))
		to_chat(usr, span_danger("Sorry but this mob type is currently unavailable."))
		return

	var/mob/living/new_mob = new mobpath(src.loc)

	new_mob.PossessByPlayer(key)
	new_mob.set_combat_mode(TRUE)
	to_chat(new_mob, span_boldnotice("You feel more... animalistic."))

	. = new_mob
	qdel(src)

/* Certain mob types have problems and should not be allowed to be controlled by players.
 *
 * This proc is here to force coders to manually place their mob in this list, hopefully tested.
 * This also gives a place to explain -why- players shouldn't be turn into certain mobs and hopefully someone can fix them.
 */
/mob/proc/safe_animal(MP)

//Bad mobs! - Remember to add a comment explaining what's wrong with the mob
	if(!MP)
		return FALSE //Sanity, this should never happen.

	if(ispath(MP, /mob/living/basic/construct))
		return FALSE //Verbs do not appear for players.

//Good mobs!
	if(ispath(MP, /mob/living/basic/pet/cat))
		return TRUE
	if(ispath(MP, /mob/living/basic/pet/dog/corgi))
		return TRUE
	if(ispath(MP, /mob/living/basic/crab))
		return TRUE
	if(ispath(MP, /mob/living/basic/carp))
		return TRUE
	if(ispath(MP, /mob/living/basic/mushroom))
		return TRUE
	if(ispath(MP, /mob/living/basic/shade))
		return TRUE
	if(ispath(MP, /mob/living/basic/killer_tomato))
		return TRUE
	if(ispath(MP, /mob/living/basic/mouse))
		return TRUE
	if(ispath(MP, /mob/living/basic/bear))
		return TRUE
	if(ispath(MP, /mob/living/basic/parrot))
		return TRUE //Parrots are no longer unfinished! -Nodrak

	//Not in here? Must be untested!
	return FALSE

#undef PERMANENT_TRANSFORMATION_TRAIT
#undef TEMPORARY_TRANSFORMATION_TRAIT
#undef TRANSFORMATION_DURATION
