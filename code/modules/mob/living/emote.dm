
/* EMOTE DATUMS */
/datum/emote/living
	mob_type_allowed_typecache = /mob/living
	mob_type_blacklist_typecache = list(/mob/living/brain)

/datum/emote/living/taunt
	key = "taunt"
	key_third_person = "taunts"
	message = "taunts!"
	cooldown = 1.6 SECONDS //note when changing this- this is used by the matrix taunt to block projectiles.

/datum/emote/living/taunt/run_emote(mob/living/user, params, type_override, intentional)
	. = ..()
	user.spin(TAUNT_EMOTE_DURATION, 0.1 SECONDS)

/datum/emote/living/blush
	key = "blush"
	key_third_person = "blushes"
	message = "blushes."

/datum/emote/living/blush/run_emote(mob/user, params, type_override, intentional)
	. = ..()
	if(!ishuman(user))
		return
	var/mob/living/carbon/human/human_user = user
	QDEL_IN(human_user.give_emote_overlay(/datum/bodypart_overlay/simple/emote/blush), 5.2 SECONDS)

/datum/emote/living/sing_tune
	key = "tunesing"
	key_third_person = "sings a tune"
	message = "sings a tune."

/datum/emote/living/bow
	key = "bow"
	key_third_person = "bows"
	message = "bows."
	message_param = "bows to %t."
	hands_use_check = TRUE

/datum/emote/living/burp
	key = "burp"
	key_third_person = "burps"
	message = "burps."
	message_mime = "acts out a burp."
	emote_type = EMOTE_VISIBLE | EMOTE_AUDIBLE

/datum/emote/living/choke
	key = "choke"
	key_third_person = "chokes"
	message = "chokes!"
	message_mime = "chokes silently!"
	emote_type = EMOTE_VISIBLE | EMOTE_AUDIBLE

/datum/emote/living/cross
	key = "cross"
	key_third_person = "crosses"
	message = "crosses their arms."
	hands_use_check = TRUE

/datum/emote/living/chuckle
	key = "chuckle"
	key_third_person = "chuckles"
	message = "chuckles."
	message_mime = "acts out chuckling."
	emote_type = EMOTE_VISIBLE | EMOTE_AUDIBLE

/datum/emote/living/collapse
	key = "collapse"
	key_third_person = "collapses"
	message = "collapses!"
	emote_type = EMOTE_VISIBLE | EMOTE_AUDIBLE

/datum/emote/living/collapse/run_emote(mob/user, params, type_override, intentional)
	. = ..()
	if(isliving(user))
		var/mob/living/living = user
		living.Unconscious(4 SECONDS)

/datum/emote/living/dance
	key = "dance"
	key_third_person = "dances"
	message = "dances around happily."
	hands_use_check = TRUE

/datum/emote/living/deathgasp
	key = "deathgasp"
	key_third_person = "deathgasps"
	message = "seizes up and falls limp, their eyes dead and lifeless..."
	message_robot = "shudders violently for a moment before falling still, its eyes slowly darkening."
	message_AI = "screeches, its screen flickering as its systems slowly halt."
	message_alien = "lets out a waning guttural screech, and collapses onto the floor..."
	message_larva = "lets out a sickly hiss of air and falls limply to the floor..."
	message_monkey = "lets out a faint chimper as it collapses and stops moving..."
	message_animal_or_basic = "stops moving..."
	emote_type = EMOTE_VISIBLE | EMOTE_AUDIBLE | EMOTE_IMPORTANT
	cooldown = (15 SECONDS)
	stat_allowed = HARD_CRIT

/datum/emote/living/deathgasp/run_emote(mob/living/user, params, type_override, intentional)
	if(!is_type_in_typecache(user, mob_type_allowed_typecache))
		return
	var/custom_message = user.death_message
	if(custom_message)
		message_animal_or_basic = custom_message
	. = ..()
	message_animal_or_basic = initial(message_animal_or_basic)
	if(!user.can_speak() || user.getOxyLoss() >= 50)
		return //stop the sound if oxyloss too high/cant speak
	var/mob/living/carbon/carbon_user = user
	// For masks that give unique death sounds
	if(istype(carbon_user) && isclothing(carbon_user.wear_mask) && carbon_user.wear_mask.unique_death)
		playsound(carbon_user, carbon_user.wear_mask.unique_death, 200, TRUE, TRUE)
		return
	if(user.death_sound)
		playsound(user, user.death_sound, 200, TRUE, TRUE)

/datum/emote/living/drool
	key = "drool"
	key_third_person = "drools"
	message = "drools."

/datum/emote/living/faint
	key = "faint"
	key_third_person = "faints"
	message = "faints."

/datum/emote/living/faint/run_emote(mob/user, params, type_override, intentional)
	. = ..()
	if(isliving(user))
		var/mob/living/living = user
		living.SetSleeping(20 SECONDS)

/datum/emote/living/flap
	key = "flap"
	key_third_person = "flaps"
	message = "flaps their wings."
	hands_use_check = TRUE
	var/wing_time = 0.35 SECONDS

/datum/emote/living/flap/run_emote(mob/user, params, type_override, intentional)
	. = ..()
	if(!ishuman(user))
		return
	var/mob/living/carbon/human/human_user = user
	var/obj/item/organ/wings/wings = human_user.get_organ_slot(ORGAN_SLOT_EXTERNAL_WINGS)

	// play a flapping noise if the wing has this implemented
	if(!istype(wings))
		return
	wings.make_flap_sound(human_user)

	// open/close functional wings
	var/obj/item/organ/wings/functional/wings_functional = wings
	if(!istype(wings_functional))
		return
	var/open = FALSE
	if(wings_functional.wings_open)
		open = TRUE
		wings_functional.close_wings()
	else
		wings_functional.open_wings()
	addtimer(CALLBACK(wings_functional, open ? TYPE_PROC_REF(/obj/item/organ/wings/functional, open_wings) : TYPE_PROC_REF(/obj/item/organ/wings/functional, close_wings)), wing_time)

/datum/emote/living/flap/aflap
	key = "aflap"
	key_third_person = "aflaps"
	name = "flap (Angry)"
	message = "flaps their wings ANGRILY!"
	hands_use_check = TRUE
	wing_time = 10

/datum/emote/living/frown
	key = "frown"
	key_third_person = "frowns"
	message = "frowns."

/datum/emote/living/gag
	key = "gag"
	key_third_person = "gags"
	message = "gags."
	message_mime = "gags silently."
	emote_type = EMOTE_VISIBLE | EMOTE_AUDIBLE

/datum/emote/living/gasp
	key = "gasp"
	key_third_person = "gasps"
	message = "gasps!"
	message_mime = "gasps silently!"
	emote_type = EMOTE_VISIBLE | EMOTE_AUDIBLE
	stat_allowed = HARD_CRIT

/datum/emote/living/gasp/get_sound(mob/living/user)
	if(HAS_MIND_TRAIT(user, TRAIT_MIMING))
		return
	if(!ishuman(user))
		return

	var/mob/living/carbon/human/human_user = user
	if(human_user.physique == FEMALE)
		return pick(
			'sound/mobs/humanoids/human/gasp/gasp_female1.ogg',
			'sound/mobs/humanoids/human/gasp/gasp_female2.ogg',
			'sound/mobs/humanoids/human/gasp/gasp_female3.ogg',
			)
	return pick(
		'sound/mobs/humanoids/human/gasp/gasp_male1.ogg',
		'sound/mobs/humanoids/human/gasp/gasp_male2.ogg',
		)

/datum/emote/living/gasp/shock
	key = "gaspshock"
	key_third_person = "gaspsshock"
	name = "gasp (Shock)"
	message = "gasps in shock!"
	message_mime = "gasps in silent shock!"
	emote_type = EMOTE_VISIBLE | EMOTE_AUDIBLE
	stat_allowed = SOFT_CRIT

/datum/emote/living/giggle
	key = "giggle"
	key_third_person = "giggles"
	message = "giggles."
	message_mime = "giggles silently!"
	emote_type = EMOTE_VISIBLE | EMOTE_AUDIBLE

/datum/emote/living/glare
	key = "glare"
	key_third_person = "glares"
	message = "glares."
	message_param = "glares at %t."

/datum/emote/living/grin
	key = "grin"
	key_third_person = "grins"
	message = "grins."

/datum/emote/living/groan
	key = "groan"
	key_third_person = "groans"
	message = "groans!"
	message_mime = "appears to groan!"
	emote_type = EMOTE_VISIBLE | EMOTE_AUDIBLE

/datum/emote/living/grimace
	key = "grimace"
	key_third_person = "grimaces"
	message = "grimaces."

/datum/emote/living/kiss
	key = "kiss"
	key_third_person = "kisses"
	cooldown = 3 SECONDS

/datum/emote/living/kiss/run_emote(mob/living/user, params, type_override, intentional)
	. = ..()
	var/kiss_type = /obj/item/hand_item/kisser

	if(HAS_TRAIT(user, TRAIT_SYNDIE_KISS))
		kiss_type = /obj/item/hand_item/kisser/syndie

	if(HAS_TRAIT(user, TRAIT_KISS_OF_DEATH))
		kiss_type = /obj/item/hand_item/kisser/death

	var/datum/action/cooldown/ink_spit/ink_action = locate() in user.actions
	if(ink_action?.IsAvailable())
		kiss_type = /obj/item/hand_item/kisser/ink
		ink_action.StartCooldown()
	else
		ink_action = null

	var/obj/item/kiss_blower = new kiss_type(user)
	if(user.put_in_hands(kiss_blower))
		to_chat(user, span_notice("You ready your kiss-blowing hand."))
	else
		qdel(kiss_blower)
		to_chat(user, span_warning("You're incapable of blowing a kiss in your current state."))
		ink_action?.ResetCooldown()

/datum/emote/living/laugh
	key = "laugh"
	key_third_person = "laughs"
	message = "laughs."
	message_mime = "laughs silently!"
	emote_type = EMOTE_VISIBLE | EMOTE_AUDIBLE
	specific_emote_audio_cooldown = 8 SECONDS
	vary = TRUE

/datum/emote/living/laugh/can_run_emote(mob/living/user, status_check = TRUE , intentional, params)
	return ..() && user.can_speak(allow_mimes = TRUE)

/datum/emote/living/laugh/get_sound(mob/living/carbon/human/user)
	if(!istype(user))
		return
	return user.dna.species.get_laugh_sound(user)

/datum/emote/living/look
	key = "look"
	key_third_person = "looks"
	message = "looks."
	message_param = "looks at %t."

/datum/emote/living/nod
	key = "nod"
	key_third_person = "nods"
	message = "nods."
	message_param = "nods at %t."

/datum/emote/living/point
	key = "point"
	key_third_person = "points"
	message = "points."
	message_param = "points at %t."
	cooldown = 1 SECONDS
	// don't put hands use check here, everything is handled in run_emote

/datum/emote/living/point/run_emote(mob/user, params, type_override, intentional)
	message_param = initial(message_param) // reset
	if(iscarbon(user))
		var/mob/living/carbon/our_carbon = user
		if(our_carbon.usable_hands <= 0 || user.incapacitated & INCAPABLE_RESTRAINTS || HAS_TRAIT(user, TRAIT_HANDS_BLOCKED))
			if(our_carbon.usable_legs > 0)
				var/one_leg = FALSE
				var/has_shoes = our_carbon.get_item_by_slot(ITEM_SLOT_FEET)
				if(our_carbon.usable_legs == 1)
					one_leg = TRUE
				var/success_prob = 65
				if(HAS_TRAIT(our_carbon, TRAIT_FREERUNNING))
					success_prob += 35
				if(one_leg)
					success_prob -= 40
				if(prob(success_prob))
					message_param = "[one_leg ? "jumps into the air and " : ""]points at %t with their [has_shoes ? "leg" : "toes"]!"
				else
					message_param = "[one_leg ? "jumps into the air and " : ""]tries to point at %t with their [has_shoes ? "leg" : "toes"], falling down in the process!"
					our_carbon.Paralyze(2 SECONDS)
				TIMER_COOLDOWN_START(user, "point_verb_emote_cooldown", 1 SECONDS)
			else
				if(our_carbon.get_organ_slot(ORGAN_SLOT_EYES))
					message_param = "gives a meaningful glance at %t!"
					TIMER_COOLDOWN_START(src, "point_verb_emote_cooldown", 1.5 SECONDS)
				else
					if(our_carbon.get_organ_slot(ORGAN_SLOT_TONGUE))
						message_param = "motions their tongue towards %t!"
						TIMER_COOLDOWN_START(src, "point_verb_emote_cooldown", 2 SECONDS)
					else
						message_param = "[span_userdanger("bumps [user.p_their()] head on the ground")] trying to motion towards %t."
						our_carbon.adjustOrganLoss(ORGAN_SLOT_BRAIN, 5)
						playsound(user, 'sound/effects/glass/glassbash.ogg', 50, TRUE, SHORT_RANGE_SOUND_EXTRARANGE)
						TIMER_COOLDOWN_START(src, "point_verb_emote_cooldown", 2.5 SECONDS)
	return ..()

/datum/emote/living/sneeze
	key = "sneeze"
	key_third_person = "sneezes"
	message = "sneezes."
	message_mime = "acts out an exaggerated silent sneeze."
	emote_type = EMOTE_VISIBLE | EMOTE_AUDIBLE
	vary = TRUE

/datum/emote/living/sneeze/get_sound(mob/living/carbon/human/user)
	if(!istype(user))
		return
	return user.dna.species.get_sneeze_sound(user)

/datum/emote/living/cough
	key = "cough"
	key_third_person = "coughs"
	message = "coughs!"
	message_mime = "acts out an exaggerated cough!"
	vary = TRUE
	emote_type = EMOTE_VISIBLE | EMOTE_AUDIBLE | EMOTE_RUNECHAT

/datum/emote/living/cough/can_run_emote(mob/user, status_check = TRUE , intentional, params)
	return !HAS_TRAIT(user, TRAIT_SOOTHED_THROAT) && ..()

/datum/emote/living/cough/get_sound(mob/living/carbon/human/user)
	if(!istype(user))
		return
	return user.dna.species.get_cough_sound(user)


/datum/emote/living/pout
	key = "pout"
	key_third_person = "pouts"
	message = "pouts."
	message_mime = "pouts silently."

/datum/emote/living/scream
	key = "scream"
	key_third_person = "screams"
	message = "screams!"
	message_mime = "acts out a scream!"
	emote_type = EMOTE_VISIBLE | EMOTE_AUDIBLE
	mob_type_blacklist_typecache = list(/mob/living/brain, /mob/living/carbon/human)
	sound_wall_ignore = TRUE

/datum/emote/living/scream/run_emote(mob/user, params, type_override, intentional = FALSE)
	if(!intentional && HAS_TRAIT(user, TRAIT_ANALGESIA))
		return
	return ..()

/datum/emote/living/scream/select_message_type(mob/user, message, intentional)
	. = ..()
	if(!intentional && isanimal_or_basicmob(user))
		return "makes a loud and pained whimper."

/datum/emote/living/scowl
	key = "scowl"
	key_third_person = "scowls"
	message = "scowls."

/datum/emote/living/shake
	key = "shake"
	key_third_person = "shakes"
	message = "shakes their head."

/datum/emote/living/shiver
	key = "shiver"
	key_third_person = "shiver"
	message = "shivers."

#define SHIVER_LOOP_DURATION (1 SECONDS)
/datum/emote/living/shiver/run_emote(mob/living/user, params, type_override, intentional)
	. = ..()

	animate(user, pixel_w = 1, time = 0.1 SECONDS, flags = ANIMATION_RELATIVE)
	for(var/i in 1 to SHIVER_LOOP_DURATION / (0.2 SECONDS)) //desired total duration divided by the iteration duration to give the necessary iteration count
		animate(pixel_w = -2, time = 0.1 SECONDS, flags = ANIMATION_RELATIVE|ANIMATION_CONTINUE)
		animate(pixel_w = 2, time = 0.1 SECONDS, flags = ANIMATION_RELATIVE|ANIMATION_CONTINUE)
	animate(pixel_w = -1, time = 0.1 SECONDS, flags = ANIMATION_RELATIVE)
#undef SHIVER_LOOP_DURATION

/datum/emote/living/sigh
	key = "sigh"
	key_third_person = "sighs"
	message = "sighs."
	message_mime = "acts out an exaggerated silent sigh."
	emote_type = EMOTE_VISIBLE | EMOTE_AUDIBLE
	vary = TRUE

/datum/emote/living/sigh/run_emote(mob/living/user, params, type_override, intentional)
	. = ..()
	if(!ishuman(user))
		return
	var/image/emote_animation = image('icons/mob/human/emote_visuals.dmi', user, "sigh")
	flick_overlay_global(emote_animation, GLOB.clients, 2.0 SECONDS)

/datum/emote/living/sigh/get_sound(mob/living/carbon/human/user)
	if(!istype(user))
		return
	return user.dna.species.get_sigh_sound(user)

/datum/emote/living/sit
	key = "sit"
	key_third_person = "sits"
	message = "sits down."

/datum/emote/living/smile
	key = "smile"
	key_third_person = "smiles"
	message = "smiles."

/datum/emote/living/smug
	key = "smug"
	key_third_person = "smugs"
	message = "grins smugly."

/datum/emote/living/sniff
	key = "sniff"
	key_third_person = "sniffs"
	message = "sniffs."
	message_mime = "sniffs silently."
	emote_type = EMOTE_VISIBLE | EMOTE_AUDIBLE
	vary = TRUE

/datum/emote/living/sniff/get_sound(mob/living/carbon/human/user)
	if(!istype(user))
		return
	return user.dna.species.get_sniff_sound(user)

/datum/emote/living/snore
	key = "snore"
	key_third_person = "snores"
	message = "snores."
	message_mime = "sleeps soundly."
	emote_type = EMOTE_VISIBLE | EMOTE_AUDIBLE
	stat_allowed = UNCONSCIOUS

// eventually we want to give species their own "snoring" sounds
/datum/emote/living/snore/get_sound(mob/living/carbon/human/user)
	if(!istype(user))
		return
	return user.dna.species.get_snore_sound(user)

/datum/emote/living/stare
	key = "stare"
	key_third_person = "stares"
	message = "stares."
	message_param = "stares at %t."

/datum/emote/living/strech
	key = "stretch"
	key_third_person = "stretches"
	message = "stretches their arms."

/datum/emote/living/sulk
	key = "sulk"
	key_third_person = "sulks"
	message = "sulks down sadly."

/datum/emote/living/surrender
	key = "surrender"
	key_third_person = "surrenders"
	message = "puts their hands on their head and falls to the ground, they surrender%s!"
	emote_type = EMOTE_VISIBLE | EMOTE_AUDIBLE

/datum/emote/living/surrender/run_emote(mob/user, params, type_override, intentional)
	. = ..()
	if(isliving(user))
		var/mob/living/living = user
		living.Paralyze(20 SECONDS)
		living.remove_status_effect(/datum/status_effect/grouped/surrender)

/datum/emote/living/sway
	key = "sway"
	key_third_person = "sways"
	message = "sways around dizzily."

/datum/emote/living/sway/run_emote(mob/living/user, params, type_override, intentional)
	. = ..()

	animate(user, pixel_w = 2, time = 0.5 SECONDS, flags = ANIMATION_RELATIVE)
	for(var/i in 1 to 2)
		animate(pixel_w = -6, time = 1.0 SECONDS, flags = ANIMATION_RELATIVE|ANIMATION_CONTINUE)
		animate(pixel_w = 6, time = 1.0 SECONDS, flags = ANIMATION_RELATIVE|ANIMATION_CONTINUE)
	animate(pixel_w = -2, time = 0.5 SECONDS, flags = ANIMATION_RELATIVE)

/datum/emote/living/tilt
	key = "tilt"
	key_third_person = "tilts"
	message = "tilts their head to the side."

/datum/emote/living/tremble
	key = "tremble"
	key_third_person = "trembles"
	message = "trembles!"

#define TREMBLE_LOOP_DURATION (4.4 SECONDS)
/datum/emote/living/tremble/run_emote(mob/living/user, params, type_override, intentional)
	. = ..()

	animate(user, pixel_w = 2, time = 0.2 SECONDS, flags = ANIMATION_RELATIVE)
	for(var/i in 1 to TREMBLE_LOOP_DURATION / (0.4 SECONDS)) //desired total duration divided by the iteration duration to give the necessary iteration count
		animate(pixel_w = -4, time = 0.2 SECONDS, flags = ANIMATION_RELATIVE|ANIMATION_CONTINUE)
		animate(pixel_w = 4, time = 0.2 SECONDS, flags = ANIMATION_RELATIVE|ANIMATION_CONTINUE)
	animate(pixel_w = -2, time = 0.2 SECONDS, flags = ANIMATION_RELATIVE)
#undef TREMBLE_LOOP_DURATION

/datum/emote/living/twitch
	key = "twitch"
	key_third_person = "twitches"
	message = "twitches violently."

/datum/emote/living/twitch/run_emote(mob/living/user, params, type_override, intentional)
	. = ..()

	animate(user, pixel_w = 1, time = 0.1 SECONDS, flags = ANIMATION_RELATIVE)
	animate(pixel_w = -2, time = 0.1 SECONDS, flags = ANIMATION_RELATIVE)
	animate(time = 0.1 SECONDS)
	animate(pixel_w = 2, time = 0.1 SECONDS, flags = ANIMATION_RELATIVE)
	animate(pixel_w = -1, time = 0.1 SECONDS, flags = ANIMATION_RELATIVE)

/datum/emote/living/twitch_s
	key = "twitch_s"
	name = "twitch (Slight)"
	message = "twitches."

/datum/emote/living/twitch_s/run_emote(mob/living/user, params, type_override, intentional)
	. = ..()

	animate(user, pixel_w = -1, time = 0.1 SECONDS, flags = ANIMATION_RELATIVE)
	animate(pixel_w = 1, time = 0.1 SECONDS, flags = ANIMATION_RELATIVE)

/datum/emote/living/wave
	key = "wave"
	key_third_person = "waves"
	message = "waves."

/datum/emote/living/whimper
	key = "whimper"
	key_third_person = "whimpers"
	message = "whimpers."
	message_mime = "appears hurt."
	emote_type = EMOTE_VISIBLE | EMOTE_AUDIBLE

/datum/emote/living/wsmile
	key = "wsmile"
	key_third_person = "wsmiles"
	name = "smile (Weak)"
	message = "smiles weakly."

/// The base chance for your yawn to propagate to someone else if they're on the same tile as you
#define YAWN_PROPAGATE_CHANCE_BASE 20
/// The amount the base chance to propagate yawns falls for each tile of distance
#define YAWN_PROPAGATE_CHANCE_DECAY 4

/datum/emote/living/yawn
	key = "yawn"
	key_third_person = "yawns"
	message = "yawns."
	message_mime = "acts out an exaggerated silent yawn."
	message_robot = "symphathetically yawns."
	message_AI = "symphathetically yawns."
	emote_type = EMOTE_VISIBLE | EMOTE_AUDIBLE
	cooldown = 5 SECONDS

/datum/emote/living/yawn/run_emote(mob/user, params, type_override, intentional)
	. = ..()
	if(!isliving(user))
		return

	if(TIMER_COOLDOWN_FINISHED(user, COOLDOWN_YAWN_PROPAGATION))
		TIMER_COOLDOWN_START(user, COOLDOWN_YAWN_PROPAGATION, cooldown * 3)

	var/mob/living/carbon/carbon_user = user
	if(istype(carbon_user) && ((carbon_user.wear_mask?.flags_inv & HIDEFACE) || carbon_user.head?.flags_inv & HIDEFACE))
		return // if your face is obscured, skip propagation

	var/propagation_distance = user.client ? 5 : 2 // mindless mobs are less able to spread yawns

	for(var/mob/living/iter_living in view(user, propagation_distance))
		if(IS_DEAD_OR_INCAP(iter_living) || TIMER_COOLDOWN_RUNNING(iter_living, COOLDOWN_YAWN_PROPAGATION))
			continue

		var/dist_between = get_dist(user, iter_living)
		var/recently_examined = FALSE // if you yawn just after someone looks at you, it forces them to yawn as well. Tradecraft!

		if(iter_living.client)
			var/examine_time = LAZYACCESS(iter_living.client?.recent_examines, user)
			if(examine_time && (world.time - examine_time < YAWN_PROPAGATION_EXAMINE_WINDOW))
				recently_examined = TRUE

		if(!recently_examined && !prob(YAWN_PROPAGATE_CHANCE_BASE - (YAWN_PROPAGATE_CHANCE_DECAY * dist_between)))
			continue

		var/yawn_delay = rand(0.2 SECONDS, 0.7 SECONDS) * dist_between
		addtimer(CALLBACK(src, PROC_REF(propagate_yawn), iter_living), yawn_delay)

/// This yawn has been triggered by someone else yawning specifically, likely after a delay. Check again if they don't have the yawned recently trait
/datum/emote/living/yawn/proc/propagate_yawn(mob/user)
	if(!istype(user) || TIMER_COOLDOWN_RUNNING(user, COOLDOWN_YAWN_PROPAGATION))
		return
	user.emote("yawn")

#undef YAWN_PROPAGATE_CHANCE_BASE
#undef YAWN_PROPAGATE_CHANCE_DECAY

/datum/emote/living/gurgle
	key = "gurgle"
	key_third_person = "gurgles"
	message = "makes an uncomfortable gurgle."
	message_mime = "gurgles silently and uncomfortably."
	emote_type = EMOTE_VISIBLE | EMOTE_AUDIBLE

/datum/emote/living/custom
	key = "me"
	key_third_person = "custom"
	message = null

/datum/emote/living/custom/can_run_emote(mob/user, status_check, intentional, params)
	. = ..()
	if(!. || !intentional)
		return FALSE

	if(!isnull(user.ckey) && is_banned_from(user.ckey, "Emote"))
		to_chat(user, span_boldwarning("You cannot send custom emotes (banned)."))
		return FALSE

	if(QDELETED(user))
		return FALSE

	if(user.client && user.client.prefs.muted & MUTE_IC)
		to_chat(user, span_boldwarning("You cannot send IC messages (muted)."))
		return FALSE

/datum/emote/living/custom/proc/emote_is_valid(mob/user, input)
	// We're assuming clientless mobs custom emoting is something codebase-driven and not player-driven.
	// If players ever get the ability to force clientless mobs to emote, we'd need to reconsider this.
	if(!user.client)
		return TRUE

	if(CAN_BYPASS_FILTER(user))
		return TRUE

	var/static/regex/stop_bad_mime = regex(@"says|exclaims|yells|asks")
	if(stop_bad_mime.Find(input, 1, 1))
		to_chat(user, span_danger("Invalid emote."))
		return FALSE

	var/list/filter_result = is_ic_filtered(input)

	if(filter_result)
		to_chat(user, span_warning("That emote contained a word prohibited in IC emotes! Consider reviewing the server rules."))
		to_chat(user, span_warning("\"[input]\""))
		REPORT_CHAT_FILTER_TO_USER(user, filter_result)
		log_filter("IC Emote", input, filter_result)
		SSblackbox.record_feedback("tally", "ic_blocked_words", 1, LOWER_TEXT(config.ic_filter_regex.match))
		return FALSE

	filter_result = is_soft_ic_filtered(input)

	if(filter_result)
		if(tgui_alert(user,"Your emote contains \"[filter_result[CHAT_FILTER_INDEX_WORD]]\". \"[filter_result[CHAT_FILTER_INDEX_REASON]]\", Are you sure you want to emote it?", "Soft Blocked Word", list("Yes", "No")) != "Yes")
			SSblackbox.record_feedback("tally", "soft_ic_blocked_words", 1, LOWER_TEXT(config.soft_ic_filter_regex.match))
			log_filter("Soft IC Emote", input, filter_result)
			return FALSE

		message_admins("[ADMIN_LOOKUPFLW(user)] has passed the soft filter for emote \"[filter_result[CHAT_FILTER_INDEX_WORD]]\" they may be using a disallowed term. Emote: \"[input]\"")
		log_admin_private("[key_name(user)] has passed the soft filter for emote \"[filter_result[CHAT_FILTER_INDEX_WORD]]\" they may be using a disallowed term. Emote: \"[input]\"")
		SSblackbox.record_feedback("tally", "passed_soft_ic_blocked_words", 1, LOWER_TEXT(config.soft_ic_filter_regex.match))
		log_filter("Soft IC Emote (Passed)", input, filter_result)

	return TRUE

/datum/emote/living/custom/proc/get_custom_emote_from_user()
	return copytext(sanitize(input("Choose an emote to display.") as text|null), 1, MAX_MESSAGE_LEN)

/datum/emote/living/custom/proc/get_custom_emote_type_from_user()
	var/type = input("Is this a visible or hearable emote?") as null|anything in list("Visible", "Hearable", "Both")

	switch(type)
		if("Visible")
			return EMOTE_VISIBLE
		if("Hearable")
			return EMOTE_AUDIBLE
		if("Both")
			return EMOTE_VISIBLE | EMOTE_AUDIBLE
		else
			tgui_alert(usr,"Unable to use this emote, must be either hearable or visible.")
			return FALSE

/datum/emote/living/custom/run_emote(mob/user, params, type_override = null, intentional = FALSE)
	var/our_message = params ? params : get_custom_emote_from_user()

	if(!emote_is_valid(user, our_message))
		return FALSE

	if(type_override)
		emote_type = type_override

	if(!params)
		var/user_emote_type = get_custom_emote_type_from_user()

		if(!user_emote_type)
			return FALSE

		emote_type = user_emote_type

	message = our_message
	. = ..()

	///Reset the message and emote type after it's run.
	message = null
	emote_type = EMOTE_VISIBLE

/datum/emote/living/custom/replace_pronoun(mob/user, message)
	return message

/datum/emote/living/inhale
	key = "inhale"
	key_third_person = "inhales"
	message = "breathes in."
	emote_type = EMOTE_VISIBLE | EMOTE_AUDIBLE

/datum/emote/living/exhale
	key = "exhale"
	key_third_person = "exhales"
	message = "breathes out."
	emote_type = EMOTE_VISIBLE | EMOTE_AUDIBLE

/datum/emote/living/swear
	key = "swear"
	key_third_person = "swears"
	message = "says a swear word!"
	message_mime = "makes a rude gesture!"
	emote_type = EMOTE_AUDIBLE

/datum/emote/living/carbon/whistle
	key = "whistle"
	key_third_person = "whistles"
	message = "whistles."
	message_mime = "whistles silently!"
	vary = TRUE
	emote_type = EMOTE_AUDIBLE | EMOTE_VISIBLE

/datum/emote/living/carbon/whistle/get_sound(mob/living/user)
	return 'sound/mobs/humanoids/human/whistle/whistle1.ogg'
