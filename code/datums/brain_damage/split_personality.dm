#define OWNER 0
#define STRANGER 1

/datum/brain_trauma/severe/split_personality
	name = "Split Personality"
	desc = "Patient's brain is split into two personalities, which randomly switch control of the body."
	scan_desc = "complete lobe separation"
	gain_text = span_warning("You feel like your mind was split in two.")
	lose_text = span_notice("You feel alone again.")
	var/current_controller = OWNER
	var/initialized = FALSE //to prevent personalities deleting themselves while we wait for ghosts
	var/mob/living/split_personality/stranger_backseat //there's two so they can swap without overwriting
	var/mob/living/split_personality/owner_backseat
	///The role to display when polling ghost
	var/poll_role = "split personality"

/datum/brain_trauma/severe/split_personality/on_gain()
	var/mob/living/brain_owner = owner
	if(brain_owner.stat == DEAD || !GET_CLIENT(brain_owner)) //No use assigning people to a corpse or braindead
		qdel(src)
		return
	..()
	make_backseats()

#ifdef UNIT_TESTS
	return // There's no ghosts in the unit test
#endif

	get_ghost()

/datum/brain_trauma/severe/split_personality/proc/make_backseats()
	stranger_backseat = new(owner, src)
	var/datum/action/personality_commune/stranger_spell = new(src)
	stranger_spell.Grant(stranger_backseat)

	owner_backseat = new(owner, src)
	var/datum/action/personality_commune/owner_spell = new(src)
	owner_spell.Grant(owner_backseat)

/// Attempts to get a ghost to play the personality
/datum/brain_trauma/severe/split_personality/proc/get_ghost()
	var/mob/chosen_one = SSpolling.poll_ghosts_for_target(
		question = "Do you want to play as [span_danger("[owner.real_name]'s")] [span_notice(poll_role)]?",
		check_jobban = ROLE_PAI,
		poll_time = 20 SECONDS,
		checked_target = owner,
		ignore_category = POLL_IGNORE_SPLITPERSONALITY,
		alert_pic = owner,
		role_name_text = poll_role,
	)
	schism(chosen_one)

/// Ghost poll has concluded
/datum/brain_trauma/severe/split_personality/proc/schism(mob/dead/observer/ghost)
	if(isnull(ghost))
		qdel(src)
		return

	stranger_backseat.PossessByPlayer(ghost.ckey)
	stranger_backseat.log_message("became [key_name(owner)]'s split personality.", LOG_GAME)
	message_admins("[ADMIN_LOOKUPFLW(stranger_backseat)] became [ADMIN_LOOKUPFLW(owner)]'s split personality.")


/datum/brain_trauma/severe/split_personality/on_life(seconds_per_tick, times_fired)
	if(owner.stat == DEAD)
		if(current_controller != OWNER)
			switch_personalities(TRUE)
		qdel(src)
	else if(SPT_PROB(1.5, seconds_per_tick))
		switch_personalities()
	..()

/datum/brain_trauma/severe/split_personality/on_lose()
	if(current_controller != OWNER) //it would be funny to cure a guy only to be left with the other personality, but it seems too cruel
		switch_personalities(TRUE)
	QDEL_NULL(stranger_backseat)
	QDEL_NULL(owner_backseat)
	..()


/datum/brain_trauma/severe/split_personality/proc/switch_personalities(reset_to_owner = FALSE)
	if(QDELETED(owner) || QDELETED(stranger_backseat) || QDELETED(owner_backseat))
		return

	var/mob/living/split_personality/current_backseat
	var/mob/living/split_personality/new_backseat
	if(current_controller == STRANGER || reset_to_owner)
		current_backseat = owner_backseat
		new_backseat = stranger_backseat
	else
		current_backseat = stranger_backseat
		new_backseat = owner_backseat

	if(!current_backseat.client) //Make sure we never switch to a logged off mob.
		return

	current_backseat.log_message("assumed control of [key_name(owner)] due to [src]. (Original owner: [current_controller == OWNER ? owner.key : current_backseat.key])", LOG_GAME)
	to_chat(owner, span_userdanger("You feel your control being taken away... your other personality is in charge now!"))
	to_chat(current_backseat, span_userdanger("You manage to take control of your body!"))

	//Body to backseat

	var/h2b_id = owner.computer_id
	var/h2b_ip= owner.lastKnownIP
	owner.computer_id = null
	owner.lastKnownIP = null

	new_backseat.ckey = owner.ckey

	new_backseat.name = owner.name

	if(owner.mind)
		new_backseat.mind = owner.mind

	if(!new_backseat.computer_id)
		new_backseat.computer_id = h2b_id

	if(!new_backseat.lastKnownIP)
		new_backseat.lastKnownIP = h2b_ip

	if(reset_to_owner && new_backseat.mind)
		new_backseat.ghostize(FALSE)

	//Backseat to body

	var/s2h_id = current_backseat.computer_id
	var/s2h_ip= current_backseat.lastKnownIP
	current_backseat.computer_id = null
	current_backseat.lastKnownIP = null

	owner.ckey = current_backseat.ckey
	owner.mind = current_backseat.mind

	if(!owner.computer_id)
		owner.computer_id = s2h_id

	if(!owner.lastKnownIP)
		owner.lastKnownIP = s2h_ip

	current_controller = !current_controller


/mob/living/split_personality
	name = "split personality"
	real_name = "unknown conscience"
	var/mob/living/carbon/body
	var/datum/brain_trauma/severe/split_personality/trauma

/mob/living/split_personality/Initialize(mapload, _trauma)
	if(iscarbon(loc))
		body = loc
		name = body.real_name
		real_name = body.real_name
		trauma = _trauma
	return ..()

/mob/living/split_personality/Life(seconds_per_tick = SSMOBS_DT, times_fired)
	if(QDELETED(body))
		qdel(src) //in case trauma deletion doesn't already do it

	if((body.stat == DEAD && trauma.owner_backseat == src))
		trauma.switch_personalities()
		qdel(trauma)

	//if one of the two ghosts, the other one stays permanently
	if(!body.client && trauma.initialized)
		trauma.switch_personalities()
		qdel(trauma)

	..()

/mob/living/split_personality/Login()
	. = ..()
	if(!. || !client)
		return FALSE
	to_chat(src, span_notice("As a split personality, you cannot do anything but observe. However, you will eventually gain control of your body, switching places with the current personality."))
	to_chat(src, span_warning("<b>Do not commit suicide or put the body in a deadly position. Behave like you care about it as much as the owner.</b>"))

/mob/living/split_personality/try_speak(message, ignore_spam, forced, filterproof)
	SHOULD_CALL_PARENT(FALSE)
	to_chat(src, span_warning("You cannot speak, your other self is controlling your body!"))
	return FALSE

/mob/living/split_personality/emote(act, m_type = null, message = null, intentional = FALSE, force_silence = FALSE)
	return FALSE

///////////////BRAINWASHING////////////////////

/datum/brain_trauma/severe/split_personality/brainwashing
	name = "Split Personality"
	desc = "Patient's brain is split into two personalities, which randomly switch control of the body."
	scan_desc = "complete lobe separation"
	gain_text = ""
	lose_text = span_notice("You are free of your brainwashing.")
	can_gain = FALSE
	var/codeword
	var/objective

/datum/brain_trauma/severe/split_personality/brainwashing/New(obj/item/organ/brain/B, _permanent, _codeword, _objective)
	..()
	if(_codeword)
		codeword = _codeword
	else
		codeword = pick(strings("ion_laws.json", "ionabstract")\
			| strings("ion_laws.json", "ionobjects")\
			| strings("ion_laws.json", "ionadjectives")\
			| strings("ion_laws.json", "ionthreats")\
			| strings("ion_laws.json", "ionfood")\
			| strings("ion_laws.json", "iondrinks"))

/datum/brain_trauma/severe/split_personality/brainwashing/on_gain()
	..()
	var/mob/living/split_personality/traitor/traitor_backseat = stranger_backseat
	traitor_backseat.codeword = codeword
	traitor_backseat.objective = objective

/datum/brain_trauma/severe/split_personality/brainwashing/make_backseats()
	stranger_backseat = new /mob/living/split_personality/traitor(owner, src, codeword, objective)
	owner_backseat = new(owner, src)

/datum/brain_trauma/severe/split_personality/brainwashing/get_ghost()
	set waitfor = FALSE
	var/mob/chosen_one = SSpolling.poll_ghosts_for_target("Do you want to play as [span_danger("[owner.real_name]'s")] brainwashed mind?", poll_time = 7.5 SECONDS, checked_target = stranger_backseat, alert_pic = owner, role_name_text = "brainwashed mind")
	if(chosen_one)
		stranger_backseat.PossessByPlayer(chosen_one.ckey)
	else
		qdel(src)

/datum/brain_trauma/severe/split_personality/brainwashing/on_life(seconds_per_tick, times_fired)
	return //no random switching

/datum/brain_trauma/severe/split_personality/brainwashing/handle_hearing(datum/source, list/hearing_args)
	if(!owner.can_hear() || owner == hearing_args[HEARING_SPEAKER] || !owner.has_language(hearing_args[HEARING_LANGUAGE]))
		return

	var/message = hearing_args[HEARING_RAW_MESSAGE]
	if(findtext(message, codeword))
		hearing_args[HEARING_RAW_MESSAGE] = replacetext(message, codeword, span_warning("[codeword]"))
		addtimer(CALLBACK(src, TYPE_PROC_REF(/datum/brain_trauma/severe/split_personality, switch_personalities)), 1 SECONDS)

/datum/brain_trauma/severe/split_personality/brainwashing/handle_speech(datum/source, list/speech_args)
	if(findtext(speech_args[SPEECH_MESSAGE], codeword))
		speech_args[SPEECH_MESSAGE] = "" //oh hey did you want to tell people about the secret word to bring you back?

/mob/living/split_personality/traitor
	name = "split personality"
	real_name = "unknown conscience"
	var/objective
	var/codeword

/mob/living/split_personality/traitor/Login()
	. = ..()
	if(!. || !client)
		return FALSE
	to_chat(src, span_notice("As a brainwashed personality, you cannot do anything yet but observe. However, you may gain control of your body if you hear the special codeword, switching places with the current personality."))
	to_chat(src, span_notice("Your activation codeword is: <b>[codeword]</b>"))
	if(objective)
		to_chat(src, span_notice("Your master left you an objective: <b>[objective]</b>. Follow it at all costs when in control."))

/datum/brain_trauma/severe/split_personality/blackout
	name = "Alcohol-Induced CNS Impairment"
	desc = "Patient's CNS has been temporarily impaired by imbibed alcohol, blocking memory formation, and causing reduced cognition and stupefaction."
	scan_desc = "alcohol-induced CNS impairment"
	gain_text = span_warning("Crap, that was one drink too many. You black out...")
	lose_text = "You wake up very, very confused and hungover. All you can remember is drinking a lot of alcohol... what happened?"
	poll_role = "blacked out drunkard"
	random_gain = FALSE
	/// Duration of effect, tracked in seconds, not deciseconds. qdels when reaching 0.
	var/duration_in_seconds = 180

/datum/brain_trauma/severe/split_personality/blackout/on_gain()
	. = ..()

	if(QDELETED(src))
		return

	RegisterSignal(owner, COMSIG_ATOM_SPLASHED, PROC_REF(on_splashed))
	notify_ghosts(
		"[owner] is blacking out!",
		source = owner,
		header = "Bro I'm not even drunk right now",
		notify_flags = NOTIFY_CATEGORY_NOFLASH,
	)

/datum/brain_trauma/severe/split_personality/blackout/on_lose()
	. = ..()
	owner.add_mood_event("hang_over", /datum/mood_event/hang_over)
	UnregisterSignal(owner, COMSIG_ATOM_SPLASHED)

/datum/brain_trauma/severe/split_personality/blackout/proc/on_splashed()
	SIGNAL_HANDLER
	if(prob(20))//we don't want every single splash to wake them up now do we
		qdel(src)

/datum/brain_trauma/severe/split_personality/blackout/on_life(seconds_per_tick, times_fired)
	if(current_controller == OWNER && stranger_backseat)//we should only start transitioning after the other personality has entered
		owner.overlay_fullscreen("fade_to_black", /atom/movable/screen/fullscreen/blind)
		owner.clear_fullscreen("fade_to_black", animated = 4 SECONDS)
		switch_personalities()
	if(owner.stat == DEAD)
		if(current_controller != OWNER)
			switch_personalities(TRUE)
		qdel(src)
		return
	if(duration_in_seconds <= 0)
		qdel(src)
		return
	else if(duration_in_seconds <= 60 && !(duration_in_seconds % 20))
		to_chat(owner, span_warning("You have [duration_in_seconds] seconds left before sobering up!"))
	if(prob(10) && !HAS_TRAIT(owner, TRAIT_DISCOORDINATED_TOOL_USER))
		ADD_TRAIT(owner, TRAIT_DISCOORDINATED_TOOL_USER, TRAUMA_TRAIT)
		owner.balloon_alert(owner, "dexterity reduced temporarily!")
		//We then send a callback to automatically re-add the trait
		addtimer(TRAIT_CALLBACK_REMOVE(owner, TRAIT_DISCOORDINATED_TOOL_USER, TRAUMA_TRAIT), 10 SECONDS)
		addtimer(CALLBACK(owner, TYPE_PROC_REF(/atom, balloon_alert), owner, "dexterity regained!"), 10 SECONDS)
	if(prob(15))
		playsound(owner,'sound/mobs/humanoids/human/hiccup/sf_hiccup_male_01.ogg', 50)
		owner.emote("hiccup")
	//too drunk to feel anything
	//if they're to this point, they're likely dying of liver damage
	//and not accounting for that, the split personality is temporary
	owner.adjustStaminaLoss(-25)
	duration_in_seconds -= seconds_per_tick

/mob/living/split_personality/blackout
	name = "blacked-out drunkard"
	real_name = "drunken consciousness"

/mob/living/split_personality/blackout/Login()
	. = ..()
	if(!. || !client)
		return FALSE
	to_chat(src, span_notice("You're the incredibly inebriated leftovers of your host's consciousness! Make sure to act the part and leave a trail of confusion and chaos in your wake."))
	to_chat(src, span_boldwarning("While you're drunk, you're not suicidal. Do not commit suicide or put the body in danger. You have a minor license to grief just like a clown, but do not kill anyone or create a situation leading to the body being put in danger or at risk of being harmed."))

#undef OWNER
#undef STRANGER
