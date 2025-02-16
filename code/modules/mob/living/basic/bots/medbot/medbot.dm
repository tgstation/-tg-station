#define TEND_DAMAGE_INTERACTION "tend_damage_interaction"

/mob/living/basic/bot/medbot
	name = "\improper Medibot"
	desc = "A little medical robot. He looks somewhat underwhelmed."
	icon = 'icons/mob/silicon/aibots.dmi'
	icon_state = "medbot_generic_idle"
	base_icon_state = "medbot"
	health = 20
	maxHealth = 20
	speed = 2
	light_power = 0.8
	light_color = "#99ccff"
	pass_flags = PASSMOB | PASSFLAPS
	status_flags = (CANPUSH | CANSTUN)
	ai_controller = /datum/ai_controller/basic_controller/bot/medbot

	req_one_access = list(ACCESS_ROBOTICS, ACCESS_MEDICAL)
	radio_key = /obj/item/encryptionkey/headset_med
	radio_channel = RADIO_CHANNEL_MEDICAL
	bot_type = MED_BOT
	data_hud_type = DATA_HUD_MEDICAL_ADVANCED
	hackables = "health processor circuits"
	possessed_message = "You are a medbot! Ensure good health among the crew to the best of your ability!"

	additional_access = /datum/id_trim/job/paramedic
	announcement_type = /datum/action/cooldown/bot_announcement/medbot
	path_image_color = "#d9d9f4"

	///anouncements when we find a target to heal
	var/static/list/wait_announcements = list(
		MEDIBOT_VOICED_HOLD_ON = 'sound/mobs/non-humanoids/medbot/coming.ogg',
		MEDIBOT_VOICED_WANT_TO_HELP = 'sound/mobs/non-humanoids/medbot/help.ogg',
		MEDIBOT_VOICED_YOU_ARE_INJURED = 'sound/mobs/non-humanoids/medbot/injured.ogg',
	)

	///announcements after we heal someone
	var/static/list/afterheal_announcements = list(
		MEDIBOT_VOICED_ALL_PATCHED_UP = 'sound/mobs/non-humanoids/medbot/patchedup.ogg',
		MEDIBOT_VOICED_APPLE_A_DAY = 'sound/mobs/non-humanoids/medbot/apple.ogg',
		MEDIBOT_VOICED_FEEL_BETTER = 'sound/mobs/non-humanoids/medbot/feelbetter.ogg',
	)

	///announcements when we are healing someone near death
	var/static/list/near_death_announcements = list(
		MEDIBOT_VOICED_STAY_WITH_ME = 'sound/mobs/non-humanoids/medbot/no.ogg',
		MEDIBOT_VOICED_LIVE = 'sound/mobs/non-humanoids/medbot/live.ogg',
		MEDIBOT_VOICED_NEVER_LOST = 'sound/mobs/non-humanoids/medbot/lost.ogg',
	)
	///announcements when we are idle
	var/static/list/idle_lines = list(
		MEDIBOT_VOICED_DELICIOUS = 'sound/mobs/non-humanoids/medbot/delicious.ogg',
		MEDIBOT_VOICED_PLASTIC_SURGEON = 'sound/mobs/non-humanoids/medbot/surgeon.ogg',
		MEDIBOT_VOICED_MASK_ON = 'sound/mobs/non-humanoids/medbot/radar.ogg',
		MEDIBOT_VOICED_ALWAYS_A_CATCH = 'sound/mobs/non-humanoids/medbot/catch.ogg',
		MEDIBOT_VOICED_LIKE_FLIES = 'sound/mobs/non-humanoids/medbot/flies.ogg',
		MEDIBOT_VOICED_SUFFER = 'sound/mobs/non-humanoids/medbot/why.ogg',
	)
	///announcements when we are emagged
	var/static/list/emagged_announcements = list(
		MEDIBOT_VOICED_FUCK_YOU = 'sound/mobs/non-humanoids/medbot/fuck_you.ogg',
		MEDIBOT_VOICED_NOT_A_GAME = 'sound/mobs/non-humanoids/medbot/turn_off.ogg',
		MEDIBOT_VOICED_IM_DIFFERENT = 'sound/mobs/non-humanoids/medbot/im_different.ogg',
		MEDIBOT_VOICED_FOURTH_WALL = 'sound/mobs/non-humanoids/medbot/close.ogg',
		MEDIBOT_VOICED_SHINDEMASHOU = 'sound/mobs/non-humanoids/medbot/shindemashou.ogg',
	)
	///announcements when we are being tipped
	var/static/list/tipped_announcements = list(
		MEDIBOT_VOICED_WAIT = 'sound/mobs/non-humanoids/medbot/hey_wait.ogg',
		MEDIBOT_VOICED_DONT = 'sound/mobs/non-humanoids/medbot/please_dont.ogg',
		MEDIBOT_VOICED_TRUSTED_YOU = 'sound/mobs/non-humanoids/medbot/i_trusted_you.ogg',
		MEDIBOT_VOICED_NO_SAD = 'sound/mobs/non-humanoids/medbot/nooo.ogg',
		MEDIBOT_VOICED_OH_FUCK = 'sound/mobs/non-humanoids/medbot/oh_fuck.ogg',
	)
	///announcements when we are being untipped
	var/static/list/untipped_announcements = list(
		MEDIBOT_VOICED_FORGIVE = 'sound/mobs/non-humanoids/medbot/forgive.ogg',
		MEDIBOT_VOICED_THANKS = 'sound/mobs/non-humanoids/medbot/thank_you.ogg',
		MEDIBOT_VOICED_GOOD_PERSON = 'sound/mobs/non-humanoids/medbot/youre_good.ogg',
	)
	///announcements when we are worried
	var/static/list/worried_announcements = list(
		MEDIBOT_VOICED_PUT_BACK = 'sound/mobs/non-humanoids/medbot/please_put_me_back.ogg',
		MEDIBOT_VOICED_IM_SCARED = 'sound/mobs/non-humanoids/medbot/please_im_scared.ogg',
		MEDIBOT_VOICED_NEED_HELP = 'sound/mobs/non-humanoids/medbot/dont_like.ogg',
		MEDIBOT_VOICED_THIS_HURTS = 'sound/mobs/non-humanoids/medbot/pain_is_real.ogg',
		MEDIBOT_VOICED_THE_END = 'sound/mobs/non-humanoids/medbot/is_this_the_end.ogg',
		MEDIBOT_VOICED_NOOO = 'sound/mobs/non-humanoids/medbot/nooo.ogg',
	)
	var/static/list/misc_announcements= list(
		MEDIBOT_VOICED_CHICKEN = 'sound/mobs/non-humanoids/medbot/i_am_chicken.ogg',
	)
	/// drop determining variable
	var/health_analyzer = /obj/item/healthanalyzer
	/// drop determining variable
	var/medkit_type = /obj/item/storage/medkit
	///based off medkit_X skins in aibots.dmi for your selection; X goes here IE medskin_tox means skin var should be "tox"
	var/skin = "generic"
	/// How much healing do we do at a time?
	var/heal_amount = 2.5
	/// Start healing when they have this much damage in a category
	var/heal_threshold = 10
	/// What damage type does this bot support. Because the default is brute, if the medkit is brute-oriented there is a slight bonus to healing. set to "all" for it to heal any of the 4 base damage types
	var/damage_type_healer = BRUTE

	///Flags Medbots use to decide how they should be acting.
	var/medical_mode_flags = MEDBOT_DECLARE_CRIT | MEDBOT_SPEAK_MODE
	//Selections:  MEDBOT_DECLARE_CRIT | MEDBOT_STATIONARY_MODE | MEDBOT_SPEAK_MODE | MEDBOT_TIPPED_MODE

	/// techweb linked to the medbot
	var/datum/techweb/linked_techweb
	///our tipper
	var/datum/weakref/tipper

/mob/living/basic/bot/medbot/proc/set_speech_keys()
	if(isnull(ai_controller))
		return
	ai_controller.set_blackboard_key(BB_NEAR_DEATH_SPEECH, near_death_announcements)
	ai_controller.set_blackboard_key(BB_WAIT_SPEECH, wait_announcements)
	ai_controller.set_blackboard_key(BB_AFTERHEAL_SPEECH, afterheal_announcements)
	ai_controller.set_blackboard_key(BB_IDLE_SPEECH, idle_lines)
	ai_controller.set_blackboard_key(BB_EMAGGED_SPEECH, emagged_announcements)
	ai_controller.set_blackboard_key(BB_WORRIED_ANNOUNCEMENTS, worried_announcements)

/mob/living/basic/bot/medbot/Initialize(mapload, new_skin)
	. = ..()
	set_speech_keys()

	if(!isnull(new_skin))
		skin = new_skin
		update_appearance()
	AddComponent(/datum/component/tippable, \
		tip_time = 3 SECONDS, \
		untip_time = 3 SECONDS, \
		self_right_time = 3.5 MINUTES, \
		pre_tipped_callback = CALLBACK(src, PROC_REF(pre_tip_over)), \
		post_tipped_callback = CALLBACK(src, PROC_REF(after_tip_over)), \
		post_untipped_callback = CALLBACK(src, PROC_REF(after_righted)))

	var/static/list/hat_offsets = list(4,-9)
	var/static/list/remove_hat = list(SIGNAL_ADDTRAIT(TRAIT_MOB_TIPPED))
	var/static/list/prevent_checks = list(TRAIT_MOB_TIPPED)
	AddElement(/datum/element/hat_wearer,\
		offsets = hat_offsets,\
		remove_hat_signals = remove_hat,\
		traits_prevent_checks = prevent_checks,\
	)
	RegisterSignal(src, COMSIG_HOSTILE_PRE_ATTACKINGTARGET, PROC_REF(pre_attack))

	if(!HAS_TRAIT(SSstation, STATION_TRAIT_MEDBOT_MANIA) || !mapload || !is_station_level(z))
		return INITIALIZE_HINT_LATELOAD

	skin = "adv"
	update_appearance()
	damage_type_healer = HEAL_ALL_DAMAGE
	if(prob(50))
		name += ", PhD."

	return INITIALIZE_HINT_LATELOAD

/mob/living/basic/bot/medbot/LateInitialize()
	if(!CONFIG_GET(flag/no_default_techweb_link) && !linked_techweb)
		CONNECT_TO_RND_SERVER_ROUNDSTART(linked_techweb, src)

/mob/living/basic/bot/medbot/on_craft_completion(list/components, datum/crafting_recipe/current_recipe, atom/crafter)
	. = ..()
	var/obj/item/storage/medkit/medkit = locate() in contents
	medkit_type = medkit
	health_analyzer = locate(/obj/item/healthanalyzer) in contents
	skin = medkit.get_medbot_skin()
	damage_type_healer = initial(medkit.damagetype_healed) ? initial(medkit.damagetype_healed) : BRUTE
	update_appearance()

/mob/living/basic/bot/medbot/update_icon_state()
	. = ..()

	var/mode_suffix = mode == BOT_HEALING ? "active" : "idle"
	icon_state = "[base_icon_state]_[skin]_[mode_suffix]"

/mob/living/basic/bot/medbot/update_overlays()
	. = ..()

	if(!(medical_mode_flags & MEDBOT_STATIONARY_MODE))
		. += mutable_appearance(icon, "[base_icon_state]_overlay_wheels")

	if(HAS_TRAIT(src, TRAIT_INCAPACITATED))
		. += mutable_appearance(icon, "[base_icon_state]_overlay_incapacitated")
		. += emissive_appearance(icon, "[base_icon_state]_overlay_incapacitated", src, alpha = src.alpha)
	else if(bot_mode_flags & BOT_MODE_ON)
		var/mode_suffix = mode == BOT_HEALING ? "active" : "idle"
		. += mutable_appearance(icon, "[base_icon_state]_overlay_on_[mode_suffix]")
		. += emissive_appearance(icon, "[base_icon_state]_overlay_on_[mode_suffix]", src, alpha = src.alpha)

//this is sin
/mob/living/basic/bot/medbot/generate_speak_list()
	var/static/list/finalized_speak_list = (idle_lines + wait_announcements + afterheal_announcements + near_death_announcements + emagged_announcements + tipped_announcements + untipped_announcements + worried_announcements + misc_announcements)
	return finalized_speak_list


/mob/living/basic/bot/medbot/attack_paw(mob/user, list/modifiers)
	return attack_hand(user, modifiers)

/mob/living/basic/bot/medbot/multitool_act(mob/living/user, obj/item/multitool/tool)
	if(!QDELETED(tool.buffer) && istype(tool.buffer, /datum/techweb))
		linked_techweb = tool.buffer
	return ITEM_INTERACT_SUCCESS

// Variables sent to TGUI
/mob/living/basic/bot/medbot/ui_data(mob/user)
	var/list/data = ..()
	if(!(bot_access_flags & BOT_COVER_LOCKED) || HAS_SILICON_ACCESS(user))
		data["custom_controls"]["heal_threshold"] = heal_threshold
		data["custom_controls"]["speaker"] = medical_mode_flags & MEDBOT_SPEAK_MODE
		data["custom_controls"]["crit_alerts"] = medical_mode_flags & MEDBOT_DECLARE_CRIT
		data["custom_controls"]["stationary_mode"] = medical_mode_flags & MEDBOT_STATIONARY_MODE
		data["custom_controls"]["sync_tech"] = TRUE
	return data

// Actions received from TGUI
/mob/living/basic/bot/medbot/ui_act(action, list/params, datum/tgui/ui, datum/ui_state/state)
	. = ..()
	var/mob/user = ui.user
	if(. || !isliving(ui.user) || (bot_access_flags & BOT_COVER_LOCKED) && !HAS_SILICON_ACCESS(user))
		return
	switch(action)
		if("heal_threshold")
			var/adjust_num = round(text2num(params["threshold"]))
			heal_threshold = adjust_num
			if(heal_threshold < 5)
				heal_threshold = 5
			if(heal_threshold > 75)
				heal_threshold = 75
		if("speaker")
			medical_mode_flags ^= MEDBOT_SPEAK_MODE
		if("crit_alerts")
			medical_mode_flags ^= MEDBOT_DECLARE_CRIT
		if("stationary_mode")
			medical_mode_flags ^= MEDBOT_STATIONARY_MODE
		if("sync_tech")
			if(!linked_techweb)
				to_chat(user, span_notice("No research techweb connected."))
				return
			var/oldheal_amount = heal_amount
			var/tech_boosters
			for(var/index in linked_techweb.researched_designs)
				var/datum/design/surgery/healing/design = SSresearch.techweb_design_by_id(index)
				if(!istype(design))
					continue
				tech_boosters++
			if(tech_boosters)
				heal_amount = (round(tech_boosters * 0.5, 0.1) * initial(heal_amount)) + initial(heal_amount) //every 2 tend wounds tech gives you an extra 100% healing, adjusting for unique branches (combo is bonus)
				if(oldheal_amount < heal_amount)
					speak("New knowledge found! Surgical efficacy improved to [round(heal_amount/initial(heal_amount)*100)]%!")

	update_appearance()

/mob/living/basic/bot/medbot/emag_effects(mob/user)
	medical_mode_flags &= ~MEDBOT_DECLARE_CRIT
	balloon_alert(user, "reagent synthesis circuits shorted")
	audible_message(span_danger("[src] buzzes oddly!"))
	flick_overlay_view(mutable_appearance(icon, "[base_icon_state]_spark"), 1 SECONDS)
	playsound(src, SFX_SPARKS, 75, TRUE, SHORT_RANGE_SOUND_EXTRARANGE)
	return TRUE

/mob/living/basic/bot/medbot/examine()
	. = ..()
	if(!(medical_mode_flags & MEDBOT_TIPPED_MODE))
		return
	var/static/list/panic_state = list(
		"It appears to be tipped over, and is quietly waiting for someone to set it right.",
		"It is tipped over and requesting help.",
		"They are tipped over and appear visibly distressed.",
		span_warning("They are tipped over and visibly panicking!"),
		span_warning(span_bold("They are freaking out from being tipped over!"))
	)
	. += pick(panic_state)
/*
 * Proc used in a callback for before this medibot is tipped by the tippable component.
 *
 * user - the mob who is tipping us over
 */
/mob/living/basic/bot/medbot/proc/pre_tip_over(mob/user)
	speak(pick(worried_announcements))

/*
 * Proc used in a callback for after this medibot is tipped by the tippable component.
 *
 * user - the mob who tipped us over
 */
/mob/living/basic/bot/medbot/proc/after_tip_over(mob/user)
	medical_mode_flags |= MEDBOT_TIPPED_MODE
	tipper = WEAKREF(user)
	playsound(src, 'sound/machines/warning-buzzer.ogg', 50)
	if(prob(10))
		speak("PSYCH ALERT: Crewmember [user.name] recorded displaying antisocial tendencies torturing bots in [get_area(src)]. Please schedule psych evaluation.", radio_channel)

/mob/living/basic/bot/medbot/explode()
	var/atom/our_loc = drop_location()
	drop_part(medkit_type, our_loc)
	drop_part(health_analyzer, our_loc)
	return ..()

/*
 * Proc used in a callback for after this medibot is righted, either by themselves or by a mob, by the tippable component.
 *
 * user - the mob who righted us. Can be null.
 */
/mob/living/basic/bot/medbot/proc/after_righted(mob/user)
	var/mob/tipper_mob = isnull(user) ? null : tipper?.resolve()
	tipper = null
	medical_mode_flags &= ~MEDBOT_TIPPED_MODE
	if(isnull(tipper_mob))
		return
	if(tipper_mob == user)
		speak(MEDIBOT_VOICED_FORGIVE)
		return
	speak(pick(untipped_announcements))

/mob/living/basic/bot/medbot/proc/pre_attack(mob/living/puncher, atom/target)
	SIGNAL_HANDLER

	if(HAS_TRAIT(src, TRAIT_HANDS_BLOCKED))
		return
	if(!iscarbon(target))
		return
	INVOKE_ASYNC(src, PROC_REF(medicate_patient), target)
	return COMPONENT_HOSTILE_NO_ATTACK

/mob/living/basic/bot/medbot/proc/medicate_patient(mob/living/carbon/human/patient)
	if(DOING_INTERACTION(src, TEND_DAMAGE_INTERACTION))
		return

	if((damage_type_healer == HEAL_ALL_DAMAGE && patient.get_total_damage() <= heal_threshold) || (!(damage_type_healer == HEAL_ALL_DAMAGE) && patient.get_current_damage_of_type(damage_type_healer) <= heal_threshold))
		to_chat(src, "[patient] is healthy! Your programming prevents you from tending the wounds of anyone with less than [heal_threshold + 1] [damage_type_healer == HEAL_ALL_DAMAGE ? "total" : damage_type_healer] damage.")
		return

	update_bot_mode(new_mode = BOT_HEALING, update_hud = FALSE)
	patient.visible_message("[src] is trying to tend the wounds of [patient]", span_userdanger("[src] is trying to tend your wounds!"))
	if(!do_after(src, delay = 2 SECONDS, target = patient, interaction_key = TEND_DAMAGE_INTERACTION))
		update_bot_mode(new_mode = BOT_IDLE)
		return
	var/modified_heal_amount = heal_amount
	var/done_healing = FALSE
	if(damage_type_healer == BRUTE && medkit_type == /obj/item/storage/medkit/brute)
		modified_heal_amount *= 1.1
	if(bot_access_flags & BOT_COVER_EMAGGED)
		patient.reagents?.add_reagent(/datum/reagent/toxin/chloralhydrate, 5)
		log_combat(src, patient, "pretended to tend wounds on", "internal tools")
	else if(damage_type_healer == HEAL_ALL_DAMAGE)
		patient.heal_ordered_damage(amount = modified_heal_amount, damage_types = list(BRUTE, BURN, TOX, OXY))
		log_combat(src, patient, "tended the wounds of", "internal tools")
		if(patient.get_total_damage() <= heal_threshold)
			done_healing = TRUE
	else
		patient.heal_damage_type(heal_amount = modified_heal_amount, damagetype = damage_type_healer)
		log_combat(src, patient, "tended the wounds of", "internal tools")
		if(patient.get_current_damage_of_type(damage_type_healer) <= heal_threshold)
			done_healing = TRUE

	patient.visible_message(span_notice("[src] tends the wounds of [patient]!"), "[span_infoplain(span_green("[src] tends your wounds!"))]")

	if(done_healing)
		visible_message(span_infoplain("[src] places its tools back into itself."))
		to_chat(src, "[patient] is now healthy!")
		update_bot_mode(new_mode = BOT_IDLE)
		return

	if(CanReach(patient))
		melee_attack(patient)


/mob/living/basic/bot/medbot/autopatrol
	bot_mode_flags = BOT_MODE_ON | BOT_MODE_AUTOPATROL | BOT_MODE_REMOTE_ENABLED | BOT_MODE_CAN_BE_SAPIENT | BOT_MODE_ROUNDSTART_POSSESSION

/mob/living/basic/bot/medbot/stationary
	medical_mode_flags = MEDBOT_DECLARE_CRIT | MEDBOT_STATIONARY_MODE | MEDBOT_SPEAK_MODE

/mob/living/basic/bot/medbot/mysterious
	name = "\improper Mysterious Medibot"
	desc = "International Medibot of mystery."
	skin = "bezerk"
	damage_type_healer = HEAL_ALL_DAMAGE
	heal_amount = 10

/mob/living/basic/bot/medbot/derelict
	name = "\improper Old Medibot"
	desc = "Looks like it hasn't been modified since the late 2080s."
	skin = "bezerk"
	damage_type_healer = HEAL_ALL_DAMAGE
	medical_mode_flags = MEDBOT_SPEAK_MODE
	heal_threshold = 0
	heal_amount = 5

/mob/living/basic/bot/medbot/nukie
	name = "Oppenheimer"
	desc = "A medibot stolen from a Nanotrasen station and upgraded by the Syndicate. Despite their best efforts at reprogramming, it still appears visibly upset near nuclear explosives."
	health = 40
	maxHealth = 40
	skin = "bezerk"
	req_one_access = list(ACCESS_SYNDICATE)
	bot_mode_flags = parent_type::bot_mode_flags & ~BOT_MODE_REMOTE_ENABLED
	radio_key = /obj/item/encryptionkey/syndicate
	radio_channel = RADIO_CHANNEL_SYNDICATE
	damage_type_healer = HEAL_ALL_DAMAGE
	faction = list(ROLE_SYNDICATE)
	heal_threshold = 0
	heal_amount = 5
	additional_access = /datum/id_trim/syndicom/crew

/mob/living/basic/bot/medbot/nukie/Initialize(mapload, new_skin)
	. = ..()
	RegisterSignal(SSdcs, COMSIG_GLOB_NUKE_DEVICE_DISARMED, PROC_REF(nuke_disarm))
	RegisterSignal(SSdcs, COMSIG_GLOB_NUKE_DEVICE_ARMED, PROC_REF(nuke_arm))
	RegisterSignal(SSdcs, COMSIG_GLOB_NUKE_DEVICE_DETONATING, PROC_REF(nuke_detonate))
	internal_radio.set_frequency(FREQ_SYNDICATE)
	internal_radio.freqlock = RADIO_FREQENCY_LOCKED

/mob/living/basic/bot/medbot/nukie/proc/nuke_disarm()
	SIGNAL_HANDLER

	INVOKE_ASYNC(src, PROC_REF(speak), pick(untipped_announcements))

/mob/living/basic/bot/medbot/nukie/proc/nuke_arm()
	SIGNAL_HANDLER

	INVOKE_ASYNC(src, PROC_REF(speak), pick(worried_announcements))

/mob/living/basic/bot/medbot/nukie/proc/nuke_detonate()
	SIGNAL_HANDLER

	INVOKE_ASYNC(src, PROC_REF(speak), pick(emagged_announcements))

#undef TEND_DAMAGE_INTERACTION
