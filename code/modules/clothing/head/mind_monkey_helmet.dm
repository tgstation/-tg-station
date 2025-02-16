
//monkey sentience caps

/obj/item/clothing/head/helmet/monkey_sentience
	name = "monkey mind magnification helmet"
	desc = "A fragile, circuitry embedded helmet for boosting the intelligence of a monkey to a higher level. You see several warning labels..."
	icon_state = "monkeymind"
	inhand_icon_state = null
	strip_delay = 100
	var/mob/living/carbon/human/magnification = null ///if the helmet is on a valid target (just works like a normal helmet if not (cargo please stop))
	var/polling = FALSE///if the helmet is currently polling for targets (special code for removal)
	var/light_colors = 1 ///which icon state color this is (red, blue, yellow)
	/// This chance is increased by 7 every time the helmet fails to get a host, to dissuade spam. starts negative to add 1 safe reuse
	var/rage_chance = -7
	/// Currently used particle type
	var/particle_path

/obj/item/clothing/head/helmet/monkey_sentience/Initialize(mapload)
	. = ..()
	light_colors = rand(1,3)
	update_appearance()

/obj/item/clothing/head/helmet/monkey_sentience/examine(mob/user)
	. = ..()
	. += span_boldwarning("---WARNING: REMOVAL OF HELMET ON SUBJECT, OR REPEATED SENTIENCE GENERATION FAILURES MAY LEAD TO:---")
	. += span_warning("BLOOD RAGE")
	. += span_warning("BRAIN DEATH")
	. += span_warning("PRIMAL GENE ACTIVATION")
	. += span_warning("GENETIC MAKEUP MASS SUSCEPTIBILITY")
	. += span_notice("Warranty voided if helmet is placed after more than ") + span_boldnotice("two") + span_notice(" mind magnification failures.")
	. += span_boldnotice("Ask your CMO if mind magnification is right for you!")

/obj/item/clothing/head/helmet/monkey_sentience/update_icon_state()
	. = ..()
	icon_state = "[initial(icon_state)][light_colors][magnification ? "up" : null]"

/obj/item/clothing/head/helmet/monkey_sentience/equipped(mob/user, slot)
	. = ..()
	if(!(slot & ITEM_SLOT_HEAD))
		return
	if(!ismonkey(user) || user.ckey)
		var/mob/living/something = user
		to_chat(something, span_boldnotice("You feel a stabbing pain in the back of your head for a moment."))
		something.apply_damage(5,BRUTE,BODY_ZONE_HEAD,FALSE,FALSE,FALSE) //notably: no damage resist (it's in your helmet), no damage spread (it's in your helmet)
		playsound(src, 'sound/machines/buzz/buzz-sigh.ogg', 30, TRUE)
		return
	if(!(GLOB.ghost_role_flags & GHOSTROLE_STATION_SENTIENCE))
		say("ERROR: Central Command has temporarily outlawed monkey sentience helmets in this sector. NEAREST LAWFUL SECTOR: 2.537 million light years away.")
		return
	magnification = user //this polls ghosts
	visible_message(span_warning("[src] powers up!"))
	playsound(src, 'sound/machines/ping.ogg', 30, TRUE)
	RegisterSignal(magnification, COMSIG_SPECIES_LOSS, PROC_REF(make_fall_off))
	polling = TRUE
	var/mob/chosen_one = SSpolling.poll_ghosts_for_target(check_jobban = ROLE_MONKEY_HELMET, poll_time = 5 SECONDS, checked_target = magnification, ignore_category = POLL_IGNORE_MONKEY_HELMET, alert_pic = magnification, role_name_text = "mind-magnified monkey")
	polling = FALSE
	if(!magnification)
		return
	if(isnull(chosen_one))
		UnregisterSignal(magnification, COMSIG_SPECIES_LOSS)
		magnification = null
		visible_message(span_notice("[src] falls silent and drops on the floor. Maybe you should try again later?"))
		if (particle_path)
			remove_shared_particles(particle_path)
		switch(rage_chance)
			if(-7 to 0)
				user.visible_message(span_notice("[src] falls silent and drops on the floor. Try again later?"))
				playsound(src, 'sound/machines/buzz/buzz-sigh.ogg', 30, TRUE)
				particle_path = null
			if(7 to 13)
				user.visible_message(span_notice("[src] sparkles momentarily, then falls silent and drops on the floor. Maybe you should try again later?"))
				playsound(src, SFX_SPARKS, 30, TRUE)
				do_sparks(2, FALSE, src)
				particle_path = /particles/smoke/steam/mild
			if(14 to 21)
				user.visible_message(span_notice("[src] sparkles and shatters ominously, then falls silent and drops on the floor. Maybe you shouldn't try again later."))
				do_sparks(4, FALSE, src)
				playsound(src, SFX_SPARKS, 15, TRUE)
				playsound(src, SFX_SHATTER, 30, TRUE)
				particle_path = /particles/smoke/steam/bad
			if(21 to INFINITY)
				user.visible_message(span_notice("[src] buzzes and smokes heavily, then falls silent and drops on the floor. This is clearly a bad idea."))
				do_sparks(6, FALSE, src)
				playsound(src, 'sound/machines/buzz/buzz-two.ogg', 30, TRUE)
				particle_path = /particles/smoke/steam
		rage_chance += 7
		if(particle_path)
			add_shared_particles(particle_path)
			addtimer(CALLBACK(src, TYPE_PROC_REF(/atom/movable, remove_shared_particles), particle_path), 2 MINUTES)
			addtimer(VARSET_CALLBACK(src, particle_path, null), 2 MINUTES)

		if((rage_chance > 0) && prob(rage_chance)) // too much spam means agnry gorilla running at you
			malfunction(user)
		user.dropItemToGround(src)
		return

	magnification.PossessByPlayer(chosen_one.key)
	playsound(src, 'sound/machines/microwave/microwave-end.ogg', 100, FALSE)
	to_chat(magnification, span_notice("You're a mind magnified monkey! Protect your helmet with your life- if you lose it, your sentience goes with it!"))
	var/policy = get_policy(ROLE_MONKEY_HELMET)
	if(policy)
		to_chat(magnification, policy)
	icon_state = "[icon_state]up"

/obj/item/clothing/head/helmet/monkey_sentience/Destroy()
	disconnect()
	return ..()

/obj/item/clothing/head/helmet/monkey_sentience/proc/disconnect()
	if(!magnification) //not put on a viable head
		return
	if(!polling)//put on a viable head, but taken off after polling finished.
		if(magnification.client)
			to_chat(magnification, span_userdanger("You feel your flicker of sentience ripped away from you, as everything becomes dim..."))
			magnification.ghostize(FALSE)
		if(prob(10))
			malfunction(magnification)
	//either used up correctly or taken off before polling finished (punish this by destroying the helmet)
	UnregisterSignal(magnification, COMSIG_SPECIES_LOSS)
	playsound(src, 'sound/machines/buzz/buzz-sigh.ogg', 30, TRUE)
	playsound(src, SFX_SPARKS, 100, TRUE, SHORT_RANGE_SOUND_EXTRARANGE)
	visible_message(span_warning("[src] fizzles and breaks apart!"))
	magnification = null
	new /obj/effect/decal/cleanable/ash(drop_location()) //just in case they're in a locker or other containers it needs to use crematorium ash, see the path itself for an explanation

/obj/item/clothing/head/helmet/monkey_sentience/proc/malfunction(mob/living/carbon/target)
	switch(rand(1,4))
		if(1) //blood rage
			var/datum/ai_controller/monkey/monky_controller = target.ai_controller
			monky_controller.set_trip_mode(mode = FALSE)
			monky_controller.set_blackboard_key(BB_MONKEY_AGGRESSIVE, TRUE)
		if(2) //brain death
			target.apply_damage(500,BRAIN,BODY_ZONE_HEAD,FALSE,FALSE,FALSE)
		if(3) //primal gene (gorilla)
			target.gorillize()
		if(4) //genetic mass susceptibility (gib)
			target.gib(DROP_ALL_REMAINS)

/obj/item/clothing/head/helmet/monkey_sentience/dropped(mob/user)
	. = ..()
	if(magnification || polling)
		qdel(src)//runs disconnect code

/obj/item/clothing/head/helmet/monkey_sentience/proc/make_fall_off()
	SIGNAL_HANDLER
	if(magnification)
		visible_message(span_warning("[src] falls off of [magnification]'s head as it changes shape!"))
		magnification.dropItemToGround(src)
