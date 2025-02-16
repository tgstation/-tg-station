

//TODO: Make these basic mobs

#define MIN_IMPREGNATION_TIME 100 //time it takes to impregnate someone
#define MAX_IMPREGNATION_TIME 150

#define MIN_ACTIVE_TIME 200 //time between being dropped and going idle
#define MAX_ACTIVE_TIME 400

/obj/item/clothing/mask/facehugger
	name = "alien"
	desc = "It has some sort of a tube at the end of its tail."
	icon = 'icons/mob/nonhuman-player/alien.dmi'
	icon_state = "facehugger"
	base_icon_state = "facehugger"
	inhand_icon_state = "facehugger"
	worn_icon_state = "facehugger"
	w_class = WEIGHT_CLASS_TINY //note: can be picked up by aliens unlike most other items of w_class below 4
	clothing_flags = MASKINTERNALS
	throw_range = 5
	tint = 3
	flags_cover = MASKCOVERSEYES | MASKCOVERSMOUTH
	layer = MOB_LAYER
	max_integrity = 100
	slowdown = 2
	var/stat = CONSCIOUS //UNCONSCIOUS is the idle state in this case

	var/sterile = FALSE
	var/real = TRUE //0 for the toy, 1 for real. Sure I could istype, but fuck that.
	var/strength = 5

	var/attached = 0

/obj/item/clothing/mask/facehugger/Initialize(mapload)
	. = ..()
	var/static/list/loc_connections = list(
		COMSIG_ATOM_ENTERED = PROC_REF(on_entered),
	)
	AddElement(/datum/element/connect_loc, loc_connections)
	AddElement(/datum/element/atmos_sensitive, mapload)
	AddElement(/datum/element/muffles_speech)

	RegisterSignal(src, COMSIG_LIVING_TRYING_TO_PULL, PROC_REF(react_to_mob))

/obj/item/clothing/mask/facehugger/take_damage(damage_amount, damage_type = BRUTE, damage_flag = 0, sound_effect = 1, attack_dir)
	..()
	if(atom_integrity < 90)
		Die()

/obj/item/clothing/mask/facehugger/attackby(obj/item/O, mob/user, params)
	return O.attack_atom(src, user, params)

/obj/item/clothing/mask/facehugger/proc/react_to_mob(datum/source, mob/user)
	SIGNAL_HANDLER
	if((stat == CONSCIOUS && !sterile) && !isalien(user))
		if(Leap(user))
			return COMSIG_LIVING_CANCEL_PULL

//ATTACK HAND IGNORING PARENT RETURN VALUE
/obj/item/clothing/mask/facehugger/attack_hand(mob/user, list/modifiers)
	if((stat == CONSCIOUS && !sterile) && !isalien(user))
		if(Leap(user))
			return
	. = ..()

/obj/item/clothing/mask/facehugger/attack(mob/living/M, mob/user)
	..()
	if(user.transferItemToLoc(src, get_turf(M)))
		Leap(M)

/obj/item/clothing/mask/facehugger/examine(mob/user)
	. = ..()
	if(!real)//So that giant red text about probisci doesn't show up.
		return
	switch(stat)
		if(DEAD,UNCONSCIOUS)
			. += span_bolddanger("[src] is not moving.")
		if(CONSCIOUS)
			. += span_bolddanger("[src] seems to be active!")
	if (sterile)
		. += span_bolddanger("It looks like the proboscis has been removed.")

/obj/item/clothing/mask/facehugger/should_atmos_process(datum/gas_mixture/air, exposed_temperature)
	return (exposed_temperature > 300)

/obj/item/clothing/mask/facehugger/atmos_expose(datum/gas_mixture/air, exposed_temperature)
	Die()

/obj/item/clothing/mask/facehugger/equipped(mob/M)
	. = ..()
	Attach(M)

/obj/item/clothing/mask/facehugger/proc/on_entered(datum/source, atom/target)
	SIGNAL_HANDLER
	HasProximity(target)

/obj/item/clothing/mask/facehugger/on_found(mob/finder)
	if(stat == CONSCIOUS)
		return HasProximity(finder)

/obj/item/clothing/mask/facehugger/HasProximity(atom/movable/AM as mob|obj)
	if(CanHug(AM) && Adjacent(AM))
		return Leap(AM)

/obj/item/clothing/mask/facehugger/throw_at(atom/target, range, speed, mob/thrower, spin=1, diagonals_first = 0, datum/callback/callback, gentle, quickstart = TRUE, throw_type_path = /datum/thrownthing)
	. = ..()
	if(!.)
		return
	if(stat == CONSCIOUS)
		icon_state = "[base_icon_state]_thrown"
		addtimer(CALLBACK(src, PROC_REF(clear_throw_icon_state)), 1.5 SECONDS)

/obj/item/clothing/mask/facehugger/proc/clear_throw_icon_state()
	if(icon_state == "[base_icon_state]_thrown")
		icon_state = "[base_icon_state]"

/obj/item/clothing/mask/facehugger/throw_impact(atom/hit_atom, datum/thrownthing/throwingdatum)
	..()
	if(stat == CONSCIOUS)
		icon_state = "[base_icon_state]"
		Leap(hit_atom)

/obj/item/clothing/mask/facehugger/proc/valid_to_attach(mob/living/hit_mob)
	// valid targets: carbons except aliens and devils
	// facehugger state early exit checks (Note: Melbert does not want dead people to be huggable)
	if(stat != CONSCIOUS)
		return FALSE
	if(attached)
		return FALSE
	if(!iscarbon(hit_mob))
		return FALSE
	// disallowed carbons
	if(isalien(hit_mob))
		return FALSE
	var/mob/living/carbon/target = hit_mob
	// gotta have a head to be implanted (no changelings or sentient plants)
	if(!target.get_bodypart(BODY_ZONE_HEAD))
		return FALSE
	// gotta be able to have the xeno implanted
	if(HAS_TRAIT(hit_mob, TRAIT_XENO_IMMUNE))
		return FALSE
	// carbon, has head, not an alien nor has an hivenode or embryo: valid
	return TRUE

/obj/item/clothing/mask/facehugger/proc/Leap(mob/living/hit_mob)
	//check if not carbon/alien/has facehugger already/ect.
	if(!valid_to_attach(hit_mob))
		return FALSE
	var/mob/living/carbon/target = hit_mob
	if(target.wear_mask && istype(target.wear_mask, /obj/item/clothing/mask/facehugger))
		return FALSE
	// passed initial checks - time to leap!
	target.visible_message(span_danger("[src] leaps at [target]'s face!"), \
						span_userdanger("[src] leaps at your face!"))

	// probiscis-blocker handling
	if(target.is_mouth_covered(ITEM_SLOT_HEAD))
		target.visible_message(span_danger("[src] smashes against [target]'s [target.head]!"), \
							span_userdanger("[src] smashes against your [target.head]!"))
		Die()
		return FALSE

	if(target.wear_mask)
		var/obj/item/clothing/worn_mask = target.wear_mask
		if(target.dropItemToGround(worn_mask))
			target.visible_message(span_danger("[src] tears [worn_mask] off of [target]'s face!"), \
								span_userdanger("[src] tears [worn_mask] off of your face!"))

	if(!target.equip_to_slot_if_possible(src, ITEM_SLOT_MASK, 0, 1, 1))
		return FALSE
	log_combat(target, src, "was facehugged by")
	return TRUE // time for a smoke

/obj/item/clothing/mask/facehugger/proc/Attach(mob/living/victim)
	if(!valid_to_attach(victim))
		return

	if(victim.stat < UNCONSCIOUS) //sorry bro you gotta be awake
		victim.say("AAAA!!") //triggers muffled speech and also visual feedback i guess
	// early returns and validity checks done: attach.
	attached++
	//ensure we detach once we no longer need to be attached
	addtimer(CALLBACK(src, PROC_REF(detach)), MAX_IMPREGNATION_TIME)


	if(!sterile)
		victim.take_bodypart_damage(strength,0) //done here so that humans in helmets take damage
	if(real && !sterile)
		victim.Knockdown(5 SECONDS)
	GoIdle() //so it doesn't jump the people that tear it off

	addtimer(CALLBACK(src, PROC_REF(Impregnate), victim), rand(MIN_IMPREGNATION_TIME, MAX_IMPREGNATION_TIME))

/obj/item/clothing/mask/facehugger/proc/detach()
	attached = 0

/obj/item/clothing/mask/facehugger/proc/Impregnate(mob/living/target)
	if(!target || target.stat == DEAD) //was taken off or something
		return

	if(iscarbon(target))
		var/mob/living/carbon/C = target
		if(C.wear_mask != src)
			return

	if(!sterile)
		target.visible_message(span_danger("[src] falls limp after violating [target]'s face!"), \
								span_userdanger("[src] falls limp after violating your face!"))

		Die()
		icon_state = "[base_icon_state]_impregnated"
		worn_icon_state = "[base_icon_state]_impregnated"

		var/obj/item/bodypart/chest/LC = target.get_bodypart(BODY_ZONE_CHEST)
		if((!LC || IS_ORGANIC_LIMB(LC)) && !target.get_organ_by_type(/obj/item/organ/body_egg/alien_embryo))
			new /obj/item/organ/body_egg/alien_embryo(target)
			target.log_message("was impregnated by a facehugger", LOG_GAME)
			target.log_message("was impregnated by a facehugger", LOG_VICTIM, log_globally = FALSE)
			if(target.stat != DEAD && istype(target.buckled, /obj/structure/bed/nest)) //Handles toggling the nest sustenance status effect if the user was already buckled to a nest.
				target.apply_status_effect(/datum/status_effect/nest_sustenance)

	else
		target.visible_message(span_danger("[src] violates [target]'s face!"), \
								span_userdanger("[src] violates your face!"))

/obj/item/clothing/mask/facehugger/proc/GoActive()
	if(stat == DEAD || stat == CONSCIOUS)
		return

	stat = CONSCIOUS
	icon_state = "[base_icon_state]"
	worn_icon_state = "[base_icon_state]"

/obj/item/clothing/mask/facehugger/proc/GoIdle()
	if(stat == DEAD || stat == UNCONSCIOUS)
		return

	stat = UNCONSCIOUS
	icon_state = "[base_icon_state]_inactive"
	worn_icon_state = "[base_icon_state]_inactive"

	addtimer(CALLBACK(src, PROC_REF(GoActive)), rand(MIN_ACTIVE_TIME, MAX_ACTIVE_TIME))

/obj/item/clothing/mask/facehugger/proc/Die()
	if(stat == DEAD)
		return

	icon_state = "[base_icon_state]_dead"
	worn_icon_state = "[base_icon_state]_dead"
	inhand_icon_state = "facehugger_inactive"
	stat = DEAD

	visible_message(span_danger("[src] curls up into a ball!"))

	// chest maybe because getting slammed in the chest would knock it off your face while dead
	AddComponent(/datum/component/knockoff, knockoff_chance = 40, target_zones = list(BODY_ZONE_HEAD, BODY_ZONE_CHEST), slots_knockoffable = slot_flags)

/obj/item/clothing/mask/facehugger/allow_attack_hand_drop(mob/living/carbon/human/user)
	if(!real || sterile || user.get_organ_by_type(/obj/item/organ/body_egg/alien_embryo))
		return ..()
	if(istype(user) && ishuman(loc) && stat != DEAD)
		if(user == loc && user.get_item_by_slot(slot_flags) == src)
			to_chat(user, span_userdanger("[src] is latched on too tight! Get help or wait for it to let go!"))
			return FALSE
	return ..()

/obj/item/clothing/mask/facehugger/mouse_drop_dragged(atom/over, mob/user, src_location, over_location, params)
	var/mob/living/carbon/human/wearer = loc
	if(!istype(wearer) || user != wearer)
		return
	if(!real || sterile || user.get_organ_by_type(/obj/item/organ/body_egg/alien_embryo))
		return ..()
	if(wearer.get_item_by_slot(slot_flags) == src && stat != DEAD)
		to_chat(user, span_userdanger("[src] is latched on too tight! Get help or wait for it to let go!"))
		return
	return ..()

/proc/CanHug(mob/living/M)
	if(!istype(M))
		return FALSE
	if(M.stat == DEAD)
		return FALSE
	if(M.get_organ_by_type(/obj/item/organ/alien/hivenode))
		return FALSE
	var/mob/living/carbon/C = M
	if(ishuman(C) && !(C.dna.species.no_equip_flags & ITEM_SLOT_MASK))
		var/mob/living/carbon/human/H = C
		if(H.is_mouth_covered(ITEM_SLOT_HEAD))
			return FALSE
		return TRUE
	return FALSE

/obj/item/clothing/mask/facehugger/lamarr
	name = "Lamarr"
	desc = "The Research Director's pet, a domesticated and debeaked xenomorph facehugger. Friendly, but may still try to couple with your head."
	sterile = TRUE
	slowdown = 1.5 //lamarr is too fat after being fed in captivity to effectively slow people down or something

/obj/item/clothing/mask/facehugger/dead
	icon_state = "facehugger_dead"
	inhand_icon_state = "facehugger_inactive"
	worn_icon_state = "facehugger_dead"
	stat = DEAD

/obj/item/clothing/mask/facehugger/impregnated
	icon_state = "facehugger_impregnated"
	inhand_icon_state = null
	worn_icon_state = "facehugger_impregnated"
	stat = DEAD

/obj/item/clothing/mask/facehugger/toy
	inhand_icon_state = "facehugger_inactive"
	desc = "A toy often used to play pranks on other miners by putting it in their beds. It takes a bit to recharge after latching onto something."
	real = FALSE
	sterile = TRUE
	tint = 3 //Makes it feel more authentic when it latches on
	slowdown = 0
	integrity_failure = 0

/obj/item/clothing/mask/facehugger/toy/Die()
	return

#undef MIN_ACTIVE_TIME
#undef MAX_ACTIVE_TIME

#undef MIN_IMPREGNATION_TIME
#undef MAX_IMPREGNATION_TIME
