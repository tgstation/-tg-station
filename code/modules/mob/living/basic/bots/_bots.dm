GLOBAL_LIST_INIT(command_strings, list(
	"patroloff" = "STOP PATROL",
	"patrolon" = "START PATROL",
	"stop" = "STOP",
	"go" = "GO",
	"home" = "RETURN HOME",
))

#define SENTIENT_BOT_RESET_TIMER 45 SECONDS

/mob/living/basic/bot
	icon = 'icons/mob/silicon/aibots.dmi'
	layer = MOB_LAYER
	gender = NEUTER
	mob_biotypes = MOB_ROBOTIC
	basic_mob_flags = DEL_ON_DEATH
	density = FALSE

	damage_coeff = list(BRUTE = 1, BURN = 1, TOX = 0, STAMINA = 0, OXY = 0)
	habitable_atmos = null
	hud_possible = list(DIAG_STAT_HUD, DIAG_BOT_HUD, DIAG_HUD, DIAG_BATT_HUD, DIAG_PATH_HUD = HUD_LIST_LIST)

	maximum_survivable_temperature = INFINITY
	minimum_survivable_temperature = 0

	sentience_type = SENTIENCE_ARTIFICIAL
	status_flags = NONE //no default canpush
	ai_controller = /datum/ai_controller/basic_controller/bot
	pass_flags = PASSFLAPS | PASSMOB

	verb_say = "states"
	verb_ask = "queries"
	verb_exclaim = "declares"
	verb_yell = "alarms"

	initial_language_holder = /datum/language_holder/synthetic
	bubble_icon = "machine"

	speech_span = SPAN_ROBOT
	faction = list(FACTION_SILICON, FACTION_TURRET)
	light_system = OVERLAY_LIGHT
	light_range = 3
	light_power = 0.6
	speed = 3

	req_one_access = list(ACCESS_ROBOTICS)
	interaction_flags_click = ALLOW_SILICON_REACH
	///The Robot arm attached to this robot - has a 50% chance to drop on death.
	var/robot_arm = /obj/item/bodypart/arm/right/robot
	///The inserted (if any) pAI in this bot.
	var/obj/item/pai_card/paicard
	///The type of bot it is, for radio control.
	var/bot_type = NONE
	///All initial access this bot started with.
	var/list/initial_access = list()
	///Bot-related mode flags on the Bot indicating how they will act. BOT_MODE_ON | BOT_MODE_AUTOPATROL | BOT_MODE_REMOTE_ENABLED | BOT_MODE_CAN_BE_SAPIENT | BOT_MODE_ROUNDSTART_POSSESSION
	/// DO NOT MODIFY MANUALLY, USE set_bot_mode_flags. If you don't shit breaks BAD
	var/bot_mode_flags = BOT_MODE_ON | BOT_MODE_REMOTE_ENABLED | BOT_MODE_CAN_BE_SAPIENT | BOT_MODE_ROUNDSTART_POSSESSION
	///Bot-related cover flags on the Bot to deal with what has been done to their cover, including emagging. BOT_COVER_MAINTS_OPEN | BOT_COVER_LOCKED | BOT_COVER_EMAGGED | BOT_COVER_HACKED
	var/bot_access_flags = BOT_COVER_LOCKED
	///Small name of what the bot gets messed with when getting hacked/emagged.
	var/hackables = "system circuits"
	///Standardizes the vars that indicate the bot is busy with its function.
	var/mode = BOT_IDLE
	///Links a bot to the AI calling it.
	var/datum/weakref/calling_ai_ref
	///The bot's radio, for speaking to people.
	var/obj/item/radio/internal_radio
	///which channels can the bot listen to
	var/radio_key = null
	///The bot's default radio channel
	var/radio_channel = RADIO_CHANNEL_COMMON
	///our access card
	var/obj/item/card/id/access_card
	///The trim type that will grant additional acces
	var/datum/id_trim/additional_access
	///file the path icon is stored in
	var/path_image_icon = 'icons/mob/silicon/aibots.dmi'
	///state of the path icon
	var/path_image_icon_state = "path_indicator"
	///what color this path icon will use
	var/path_image_color = COLOR_WHITE
	///list of all layed path icons
	var/list/current_pathed_turfs = list()

	///The type of data HUD the bot uses. Diagnostic by default.
	var/data_hud_type = DATA_HUD_DIAGNOSTIC
	/// If true we will allow ghosts to control this mob
	var/can_be_possessed = FALSE
	/// Message to display upon possession
	var/possessed_message = "You're a generic bot. How did one of these even get made?"
	/// Action we use to say voice lines out loud, also we just pass anything we try to say through here just in case it plays a voice line
	var/datum/action/cooldown/bot_announcement/pa_system
	/// Type of bot_announcement ability we want
	var/announcement_type
	///list of traits we apply and remove when turning on/off
	var/static/list/on_toggle_traits = list(
		TRAIT_INCAPACITATED,
		TRAIT_IMMOBILIZED,
		TRAIT_HANDS_BLOCKED,
	)
	///name of the UI we will attempt to open
	var/bot_ui = "SimpleBot"
	/// If true we will offer this
	COOLDOWN_DECLARE(offer_ghosts_cooldown)

/mob/living/basic/bot/Initialize(mapload)
	. = ..()

	add_traits(list(TRAIT_SILICON_ACCESS, TRAIT_REAGENT_SCANNER, TRAIT_UNOBSERVANT), INNATE_TRAIT)
	AddElement(/datum/element/ai_retaliate)
	RegisterSignal(src, COMSIG_MOVABLE_MOVED, PROC_REF(handle_loop_movement))
	RegisterSignal(src, COMSIG_ATOM_WAS_ATTACKED, PROC_REF(after_attacked))
	RegisterSignal(src, COMSIG_MOB_TRIED_ACCESS, PROC_REF(attempt_access))
	add_traits(list(TRAIT_NO_GLIDE, TRAIT_SILICON_EMOTES_ALLOWED), INNATE_TRAIT)
	GLOB.bots_list += src

	// Give bots a fancy new ID card that can hold any access.
	access_card = new /obj/item/card/id/advanced/simple_bot(src)
	// This access is so bots can be immediately set to patrol and leave Robotics, instead of having to be let out first.
	access_card.set_access(list(ACCESS_ROBOTICS))
	provide_additional_access()

	internal_radio = new /obj/item/radio(src)
	if(radio_key)
		internal_radio.keyslot = new radio_key
	internal_radio.subspace_transmission = TRUE
	internal_radio.canhear_range = 0 // anything greater will have the bot broadcast the channel as if it were saying it out loud.
	internal_radio.recalculateChannels()

	//Adds bot to the diagnostic HUD system
	prepare_huds()
	for(var/datum/atom_hud/data/diagnostic/diag_hud in GLOB.huds)
		diag_hud.add_atom_to_hud(src)
	diag_hud_set_bothealth()
	diag_hud_set_botstat()
	diag_hud_set_botmode()

	//If a bot has its own HUD (for player bots), provide it.
	if(!isnull(data_hud_type))
		var/datum/atom_hud/datahud = GLOB.huds[data_hud_type]
		datahud.show_to(src)

	if(mapload && is_station_level(z) && (bot_mode_flags & BOT_MODE_CAN_BE_SAPIENT) && (bot_mode_flags & BOT_MODE_ROUNDSTART_POSSESSION))
		enable_possession(mapload = mapload)

	pa_system = (isnull(announcement_type)) ? new(src, automated_announcements = generate_speak_list()) : new announcement_type(src, automated_announcements = generate_speak_list())
	pa_system.Grant(src)
	ai_controller.set_blackboard_key(BB_ANNOUNCE_ABILITY, pa_system)
	ai_controller.set_blackboard_key(BB_RADIO_CHANNEL, radio_channel)
	update_appearance()

/mob/living/basic/bot/proc/set_mode_flags(mode_flags)
	SHOULD_CALL_PARENT(TRUE)
	bot_mode_flags = mode_flags
	SEND_SIGNAL(src, COMSIG_BOT_MODE_FLAGS_SET, mode_flags)

/mob/living/basic/bot/proc/get_mode()
	if(client) //Player bots do not have modes, thus the override. Also an easy way for PDA users/AI to know when a bot is a player.
		return span_bold("[paicard ? "pAI Controlled" : "Autonomous"]")

	if(!(bot_mode_flags & BOT_MODE_ON))
		return span_bad("Inactive")

	return span_average("[mode]")

/**
 * Returns a status string about the bot's current status, if it's moving, manually controlled, or idle.
 */
/mob/living/basic/bot/proc/get_mode_ui()
	if(client)
		return paicard ? "pAI Controlled" : "Autonomous"

	if(!(bot_mode_flags & BOT_MODE_ON))
		return "Inactive"

	return "[mode]"

/**
 * Returns a string of flavor text for emagged bots as defined by policy.
 */
/mob/living/basic/bot/proc/get_emagged_message()
	return get_policy(ROLE_EMAGGED_BOT) || "You are a malfunctioning bot! Disrupt everyone and cause chaos!"

/mob/living/basic/bot/proc/turn_on()
	if(stat == DEAD)
		return FALSE
	set_mode_flags(bot_mode_flags | BOT_MODE_ON)
	remove_traits(list(TRAIT_INCAPACITATED, TRAIT_IMMOBILIZED, TRAIT_HANDS_BLOCKED), POWER_LACK_TRAIT)
	set_light_on(bot_mode_flags & BOT_MODE_ON ? TRUE : FALSE)
	update_appearance()
	balloon_alert(src, "turned on")
	diag_hud_set_botstat()
	return TRUE

/mob/living/basic/bot/proc/turn_off()
	set_mode_flags(bot_mode_flags & ~BOT_MODE_ON)
	add_traits(on_toggle_traits, POWER_LACK_TRAIT)
	set_light_on(bot_mode_flags & BOT_MODE_ON ? TRUE : FALSE)
	bot_reset() //Resets an AI's call, should it exist.
	balloon_alert(src, "turned off")
	update_appearance()

/mob/living/basic/bot/Destroy()
	GLOB.bots_list -= src
	calling_ai_ref = null
	clear_path_hud()
	QDEL_NULL(paicard)
	QDEL_NULL(pa_system)
	QDEL_NULL(internal_radio)
	QDEL_NULL(access_card)
	return ..()

/// Allows this bot to be controlled by a ghost, who will become its mind
/mob/living/basic/bot/proc/enable_possession(user, mapload = FALSE)
	if (paicard)
		balloon_alert(user, "already sapient!")
		return
	can_be_possessed = TRUE
	var/can_announce = !mapload && COOLDOWN_FINISHED(src, offer_ghosts_cooldown)
	AddComponent(
		/datum/component/ghost_direct_control, \
		ban_type = ROLE_BOT, \
		poll_candidates = can_announce, \
		poll_ignore_key = POLL_IGNORE_BOTS, \
		assumed_control_message = (bot_access_flags & BOT_COVER_EMAGGED) ? get_emagged_message() : possessed_message, \
		extra_control_checks = CALLBACK(src, PROC_REF(check_possession)), \
		after_assumed_control = CALLBACK(src, PROC_REF(post_possession)), \
	)
	if (can_announce)
		COOLDOWN_START(src, offer_ghosts_cooldown, 30 SECONDS)

/// Disables this bot from being possessed by ghosts
/mob/living/basic/bot/proc/disable_possession(mob/user)
	can_be_possessed = FALSE
	if(isnull(key))
		return
	if (user)
		log_combat(user, src, "ejected from [initial(src.name)] control.")
	to_chat(src, span_warning("You feel yourself fade as your personality matrix is reset!"))
	ghostize(can_reenter_corpse = FALSE)
	playsound(src, 'sound/machines/ping.ogg', 30, TRUE)
	speak("Personality matrix reset!")
	key = null

/// Returns true if this mob can be controlled
/mob/living/basic/bot/proc/check_possession(mob/potential_possessor)
	if (!can_be_possessed)
		to_chat(potential_possessor, span_warning("The bot's personality download has been disabled!"))
	return can_be_possessed

/// Fired after something takes control of this mob
/mob/living/basic/bot/proc/post_possession()
	playsound(src, 'sound/machines/ping.ogg', 30, TRUE)
	speak("New personality installed successfully!")
	rename(src)

/// Allows renaming the bot to something else
/mob/living/basic/bot/proc/rename(mob/user)
	var/new_name = sanitize_name(
		reject_bad_text(tgui_input_text(
			user = user,
			message = "This machine is designated [real_name]. Would you like to update its registration?",
			title = "Name change",
			default = real_name,
			max_length = MAX_NAME_LEN,
		)),
		allow_numbers = TRUE,
	)
	if (isnull(new_name) || QDELETED(src))
		return
	if (key && user != src)
		var/accepted = tgui_alert(
			src,
			message = "Do you wish to be renamed to [new_name]?",
			title = "Name change",
			buttons = list("Yes", "No"),
		)
		if (accepted != "Yes" || QDELETED(src))
			return
	fully_replace_character_name(real_name, new_name)

/mob/living/basic/bot/allowed(mob/living/user)
	if(!(bot_access_flags & BOT_COVER_LOCKED)) // Unlocked.
		return TRUE
	return ..()

/mob/living/basic/bot/bee_friendly()
	return TRUE

/mob/living/basic/bot/death(gibbed)
	if(paicard)
		ejectpai()
	explode()
	return ..()

/mob/living/basic/bot/proc/explode()
	visible_message(span_boldnotice("[src] blows apart!"))
	do_sparks(3, TRUE, src)
	var/atom/location_destroyed = drop_location()
	if(prob(50))
		drop_part(robot_arm, location_destroyed)

/mob/living/basic/bot/emag_act(mob/user, obj/item/card/emag/emag_card)
	. = ..()
	if(bot_access_flags & BOT_COVER_LOCKED) //First emag application unlocks the bot's interface. Apply a screwdriver to use the emag again.
		bot_access_flags &= ~BOT_COVER_LOCKED
		balloon_alert(user, "cover unlocked")
		return TRUE
	if((bot_access_flags & BOT_COVER_LOCKED) || !(bot_access_flags & BOT_COVER_MAINTS_OPEN)) //Bot panel is unlocked by ID or emag, and the panel is screwed open. Ready for emagging.
		balloon_alert(user, "open maintenance panel first!")
		return FALSE
	bot_access_flags |= BOT_COVER_EMAGGED
	bot_access_flags |= BOT_COVER_LOCKED
	set_mode_flags(bot_mode_flags & ~BOT_MODE_REMOTE_ENABLED) //Manually emagging the bot also locks the AI from controlling it.
	bot_reset()
	turn_on() //The bot automatically turns on when emagged, unless recently hit with EMP.
	to_chat(src, span_userdanger("(#$*#$^^( OVERRIDE DETECTED"))
	to_chat(src, span_boldnotice(get_emagged_message()))
	if(user)
		log_combat(user, src, "emagged")
	emag_effects(user)
	return TRUE

/mob/living/basic/bot/examine(mob/user)
	. = ..()
	if(health < maxHealth)
		if(health > (maxHealth * 0.3))
			. += "[src]'s parts look loose."
		else
			. += "[src]'s parts look very loose!"
	else
		. += "[src] is in pristine condition."

	. += span_notice("Its maintenance panel is [bot_access_flags & BOT_COVER_MAINTS_OPEN ? "open" : "closed"].")
	. += span_info("You can use a <b>screwdriver</b> to [bot_access_flags & BOT_COVER_MAINTS_OPEN ? "close" : "open"] it.")

	if(bot_access_flags & BOT_COVER_MAINTS_OPEN)
		. += span_notice("Its control panel is [bot_access_flags & BOT_COVER_LOCKED ? "locked" : "unlocked"].")
		if(!(bot_access_flags & BOT_COVER_EMAGGED) && (issilicon(user) || user.Adjacent(src)))
			. += span_info("Alt-click [issilicon(user) ? "" : "or use your ID on "]it to [bot_access_flags & BOT_COVER_LOCKED ? "un" : ""]lock its control panel.")
	if(isnull(paicard))
		return
	. += span_notice("It has a pAI device installed.")
	if(!(bot_access_flags & BOT_COVER_MAINTS_OPEN))
		. += span_info("You can use a <b>hemostat</b> to remove it.")

/mob/living/basic/bot/updatehealth()
	. = ..()
	diag_hud_set_bothealth()

/mob/living/basic/bot/med_hud_set_health()
	return //we use a different hud

/mob/living/basic/bot/med_hud_set_status()
	return //we use a different hud

/mob/living/basic/bot/attack_hand(mob/living/carbon/human/user, list/modifiers)
	if(!user.combat_mode)
		ui_interact(user)
		return
	return ..()

/mob/living/basic/bot/attack_ai(mob/user)
	if(!topic_denied(user))
		ui_interact(user)
		return
	to_chat(user, span_warning("[src]'s interface is not responding!"))

/mob/living/basic/bot/ui_interact(mob/user, datum/tgui/ui)
	ui = SStgui.try_update_ui(user, src, ui)
	if(!ui)
		ui = new(user, src, bot_ui, name)
		ui.open()

/mob/living/basic/bot/click_alt(mob/user)
	unlock_with_id(user)
	return CLICK_ACTION_SUCCESS

/mob/living/basic/bot/proc/unlock_with_id(mob/living/user)
	if(bot_access_flags & BOT_COVER_EMAGGED)
		balloon_alert(user, "error!")
		return
	if(bot_access_flags & BOT_COVER_MAINTS_OPEN)
		balloon_alert(user, "access panel must be closed!")
		return
	if(!allowed(user))
		balloon_alert(user, "no access")
		return
	bot_access_flags ^= BOT_COVER_LOCKED
	to_chat(user, span_notice("Controls are now [bot_access_flags & BOT_COVER_LOCKED ? "locked" : "unlocked"]."))
	return TRUE

/mob/living/basic/bot/screwdriver_act(mob/living/user, obj/item/tool)
	. = ITEM_INTERACT_SUCCESS
	if(bot_access_flags & BOT_COVER_LOCKED)
		to_chat(user, span_warning("The maintenance panel is locked!"))
		return

	tool.play_tool_sound(src)
	bot_access_flags ^= BOT_COVER_MAINTS_OPEN
	to_chat(user, span_notice("The maintenance panel is now [bot_access_flags & BOT_COVER_MAINTS_OPEN ? "opened" : "closed"]."))

/mob/living/basic/bot/welder_act(mob/living/user, obj/item/tool)
	user.changeNext_move(CLICK_CD_MELEE)
	if(user.combat_mode)
		return FALSE

	. = ITEM_INTERACT_SUCCESS

	if(health >= maxHealth)
		user.balloon_alert(user, "no repairs needed!")
		return

	if(!(bot_access_flags & BOT_COVER_MAINTS_OPEN))
		user.balloon_alert(user, "maintenance panel closed!")
		return

	if(!tool.use_tool(src, user, 0 SECONDS, volume=40))
		return

	heal_overall_damage(10)
	user.visible_message(span_notice("[user] repairs [src]!"),span_notice("You repair [src]."))

/mob/living/basic/bot/attackby(obj/item/attacking_item, mob/living/user, params)
	if(attacking_item.GetID())
		unlock_with_id(user)
		return

	if(istype(attacking_item, /obj/item/pai_card))
		insertpai(user, attacking_item)
		return

	if(attacking_item.tool_behaviour != TOOL_HEMOSTAT || !paicard)
		return ..()

	if(bot_access_flags & BOT_COVER_MAINTS_OPEN)
		balloon_alert(user, "open the access panel!")
		return

	balloon_alert(user, "removing pAI...")
	if(!do_after(user, 3 SECONDS, target = src) || !paicard)
		return

	user.visible_message(span_notice("[user] uses [attacking_item] to pull [paicard] out of [initial(src.name)]!"), \
		span_notice("You pull [paicard] out of [initial(src.name)] with [attacking_item]."))

	ejectpai(user)

/mob/living/basic/bot/attack_effects(damage_done, hit_zone, armor_block, obj/item/attacking_item, mob/living/attacker)
	if(damage_done > 0 && attacking_item.damtype != STAMINA && stat != DEAD)
		do_sparks(5, TRUE, src)
		. = TRUE
	return ..() || .

/mob/living/basic/bot/bullet_act(obj/projectile/hitting_projectile, def_zone, piercing_hit = FALSE)
	. = ..()
	if(prob(25) || . != BULLET_ACT_HIT)
		return
	if(hitting_projectile.damage_type != BRUTE && hitting_projectile.damage_type != BURN)
		return
	if(!hitting_projectile.is_hostile_projectile() || hitting_projectile.damage <= 0)
		return
	do_sparks(5, TRUE, src)

/mob/living/basic/bot/emp_act(severity)
	. = ..()
	if(. & EMP_PROTECT_SELF)
		return
	new /obj/effect/temp_visual/emp(loc)
	if(paicard)
		paicard.emp_act(severity)
		src.visible_message(span_notice("[paicard] flies out of [initial(src.name)]!"), span_warning("You are forcefully ejected from [initial(src.name)]!"))
		ejectpai()

	if (QDELETED(src))
		return

	if(bot_mode_flags & BOT_MODE_ON)
		turn_off()
	else
		addtimer(CALLBACK(src, PROC_REF(turn_on)), severity * 30 SECONDS)

	if(!prob(70/severity) || !length(GLOB.uncommon_roundstart_languages))
		return

	remove_all_languages(source = LANGUAGE_EMP)
	grant_random_uncommon_language(source = LANGUAGE_EMP)

/**
 * Pass a message to have the bot say() it, passing through our announcement action to potentially also play a sound.
 * Optionally pass a frequency to say it on the radio.
 */
/mob/living/basic/bot/proc/speak(message, channel)
	if(!message)
		return
	pa_system.announce(message, channel)

/mob/living/basic/bot/radio(message, list/message_mods = list(), list/spans, language)
	. = ..()
	if(.)
		return

	if(message_mods[MODE_HEADSET])
		internal_radio.talk_into(src, message, , spans, language, message_mods)
		return REDUCE_RANGE
	if(message_mods[RADIO_EXTENSION] == MODE_DEPARTMENT)
		internal_radio.talk_into(src, message, message_mods[RADIO_EXTENSION], spans, language, message_mods)
		return REDUCE_RANGE
	if(message_mods[RADIO_EXTENSION] in GLOB.radiochannels)
		internal_radio.talk_into(src, message, message_mods[RADIO_EXTENSION], spans, language, message_mods)
		return REDUCE_RANGE

/mob/living/basic/bot/proc/drop_part(obj/item/drop_item, dropzone)
	var/obj/item/item_to_drop
	if(ispath(drop_item))
		item_to_drop = new drop_item(dropzone)
	else
		item_to_drop = drop_item
		item_to_drop.forceMove(dropzone)

	if(istype(item_to_drop, /obj/item/stock_parts/power_store/cell))
		var/obj/item/stock_parts/power_store/cell/dropped_cell = item_to_drop
		dropped_cell.charge = 0
		return

	if(istype(item_to_drop, /obj/item/storage))
		item_to_drop.contents = list()
		return

	if(!istype(item_to_drop, /obj/item/gun/energy))
		return
	var/obj/item/gun/energy/dropped_gun = item_to_drop
	dropped_gun.cell.charge = 0
	dropped_gun.update_appearance()

/mob/living/basic/bot/proc/bot_reset(bypass_ai_reset = FALSE)
	SEND_SIGNAL(src, COMSIG_BOT_RESET)
	access_card.set_access(initial_access)
	update_bot_mode(new_mode = src::mode)
	diag_hud_set_botstat()
	diag_hud_set_botmode()
	clear_path_hud()
	if(bypass_ai_reset || isnull(calling_ai_ref))
		return
	var/mob/living/ai_caller = calling_ai_ref.resolve()
	if(isnull(ai_caller))
		return
	to_chat(ai_caller, span_danger("Call command to a bot has been reset."))
	calling_ai_ref = null

//PDA control. Some bots, especially MULEs, may have more parameters.
/mob/living/basic/bot/proc/bot_control(command, mob/user, list/user_access = list())
	if(!(bot_mode_flags & BOT_MODE_ON) || bot_access_flags & BOT_COVER_EMAGGED || !(bot_mode_flags & BOT_MODE_REMOTE_ENABLED)) //Emagged bots do not respect anyone's authority! Bots with their remote controls off cannot get commands.
		return TRUE //ACCESS DENIED
	if(client && command != "ejectpai")
		bot_control_message(command, user)
	// process control input
	switch(command)
		if("patroloff")
			set_patrol_off()
		if("patrolon")
			set_mode_flags(bot_mode_flags | BOT_MODE_AUTOPATROL)
		if("summon")
			summon_bot(user, user_access = user_access)
		if("ejectpai")
			eject_pai_remote(user)

/mob/living/basic/bot/proc/set_patrol_off()
	bot_reset()
	set_mode_flags(bot_mode_flags & ~BOT_MODE_AUTOPATROL)

/mob/living/basic/bot/proc/bot_control_message(command, user)
	if(command == "summon")
		return "PRIORITY ALERT:[user] in [get_area_name(user)]!"
	return GLOB.command_strings[command] || "Unidentified control sequence received:[command]"

/mob/living/basic/bot/ui_data(mob/user)
	var/list/data = list()
	data["can_hack"] = HAS_SILICON_ACCESS(user)
	data["custom_controls"] = list()
	data["emagged"] = bot_access_flags & BOT_COVER_EMAGGED
	data["has_access"] = allowed(user)
	data["locked"] = (bot_access_flags & BOT_COVER_LOCKED)
	data["settings"] = list()
	if(!(bot_access_flags & BOT_COVER_LOCKED) || HAS_SILICON_ACCESS(user))
		data["settings"]["pai_inserted"] = !isnull(paicard)
		data["settings"]["allow_possession"] = bot_mode_flags & BOT_MODE_CAN_BE_SAPIENT
		data["settings"]["possession_enabled"] = can_be_possessed
		data["settings"]["airplane_mode"] = !(bot_mode_flags & BOT_MODE_REMOTE_ENABLED)
		data["settings"]["maintenance_lock"] = !(bot_access_flags & BOT_COVER_MAINTS_OPEN)
		data["settings"]["power"] = bot_mode_flags & BOT_MODE_ON
		data["settings"]["patrol_station"] = bot_mode_flags & BOT_MODE_AUTOPATROL
	return data

// Actions received from TGUI
/mob/living/basic/bot/ui_act(action, list/params, datum/tgui/ui, datum/ui_state/state)
	. = ..()
	if(.)
		return
	var/mob/the_user = ui.user
	if(!allowed(the_user))
		balloon_alert(the_user, "access denied!")
		return

	if(action == "lock")
		bot_access_flags ^= BOT_COVER_LOCKED

	switch(action)
		if("power")
			if(bot_mode_flags & BOT_MODE_ON)
				turn_off()
			else
				turn_on()
		if("maintenance")
			bot_access_flags ^= BOT_COVER_MAINTS_OPEN
		if("patrol")
			set_mode_flags(bot_mode_flags ^ BOT_MODE_AUTOPATROL)
			bot_reset()
		if("airplane")
			set_mode_flags(bot_mode_flags ^ BOT_MODE_REMOTE_ENABLED)
		if("hack")
			if(!HAS_SILICON_ACCESS(the_user))
				return
			if(!(bot_access_flags & BOT_COVER_EMAGGED))
				bot_access_flags |= (BOT_COVER_LOCKED|BOT_COVER_EMAGGED|BOT_COVER_HACKED)
				emag_effects(the_user)
				to_chat(the_user, span_warning("You overload [src]'s [hackables]."))
				message_admins("Safety lock of [ADMIN_LOOKUPFLW(src)] was disabled by [ADMIN_LOOKUPFLW(the_user)] in [ADMIN_VERBOSEJMP(the_user)]")
				the_user.log_message("disabled safety lock of [the_user]", LOG_GAME)
				bot_reset()
				to_chat(src, span_userdanger("(#$*#$^^( OVERRIDE DETECTED"))
				to_chat(src, span_boldnotice(get_emagged_message()))
				return
			if(!(bot_access_flags & BOT_COVER_HACKED))
				to_chat(the_user, span_bolddanger("You fail to repair [src]'s [hackables]."))
				return
			bot_access_flags &= ~(BOT_COVER_EMAGGED|BOT_COVER_HACKED)
			to_chat(the_user, span_notice("You reset the [src]'s [hackables]."))
			the_user.log_message("re-enabled safety lock of [src]", LOG_GAME)
			bot_reset()
			to_chat(src, span_userdanger("Software restored to standard."))
			to_chat(src, span_boldnotice(possessed_message))
		if("eject_pai")
			if(!paicard)
				return
			to_chat(the_user, span_notice("You eject [paicard] from [initial(src.name)]."))
			ejectpai(the_user)
		if("toggle_personality")
			if (can_be_possessed)
				disable_possession(the_user)
			else
				enable_possession(the_user)
		if("rename")
			rename(the_user)

/mob/living/basic/bot/update_icon_state()
	icon_state = "[isnull(base_icon_state) ? initial(icon_state) : base_icon_state][bot_mode_flags & BOT_MODE_ON]"
	return ..()

/// Access check proc for bot topics! Remember to place in a bot's individual Topic if desired.
/mob/living/basic/bot/proc/topic_denied(mob/user)
	if(!user.can_perform_action(src, ALLOW_SILICON_REACH))
		return TRUE
	// 0 for access, 1 for denied.
	if(!(bot_access_flags & BOT_COVER_EMAGGED)) //An emagged bot cannot be controlled by humans, silicons can if one hacked it.
		return FALSE
	if(!(bot_access_flags & BOT_COVER_HACKED)) //Manually emagged by a human - access denied to all.
		return TRUE
	if(!HAS_SILICON_ACCESS(user)) //Bot is hacked, so only silicons and admins are allowed access.
		return TRUE

	return FALSE

/// Places a pAI in control of this mob
/mob/living/basic/bot/proc/insertpai(mob/user, obj/item/pai_card/card)
	if(paicard)
		balloon_alert(user, "slot occupied!")
		return
	if(key)
		balloon_alert(user, "personality already present!")
		return
	if(!(bot_access_flags & BOT_COVER_MAINTS_OPEN))
		balloon_alert(user, "slot inaccessible!")
		return
	if(!(bot_mode_flags & BOT_MODE_CAN_BE_SAPIENT))
		balloon_alert(user, "incompatible firmware!")
		return
	if(isnull(card.pai?.mind))
		balloon_alert(user, "pAI is inactive!")
		return
	if(!user.transferItemToLoc(card, src))
		return
	paicard = card
	disable_possession()
	paicard.pai.fold_in()
	copy_languages(paicard.pai, source_override = LANGUAGE_PAI)
	set_active_language(paicard.pai.get_selected_language())
	user.visible_message(span_notice("[user] inserts [card] into [src]!"), span_notice("You insert [card] into [src]."))
	paicard.pai.mind.transfer_to(src)
	to_chat(src, span_notice("You sense your form change as you are uploaded into [src]."))
	name = paicard.pai.name
	faction = user.faction.Copy()
	log_combat(user, paicard.pai, "uploaded to [initial(src.name)],")
	return TRUE

/mob/living/basic/bot/ghost()
	if(stat != DEAD) // Only ghost if we're doing this while alive, the pAI probably isn't dead yet.
		return ..()
	if(paicard && (!client || stat == DEAD))
		ejectpai()

/// Ejects a pAI from this bot
/mob/living/basic/bot/proc/ejectpai(mob/user = null, announce = TRUE)
	if(isnull(paicard))
		return

	if(paicard.pai)
		if(isnull(mind))
			mind.transfer_to(paicard.pai)
		else
			paicard.pai.PossessByPlayer(key)
	else
		ghostize(FALSE) // The pAI card that just got ejected was dead.

	key = null
	paicard.forceMove(drop_location())
	var/to_log = user ? user : src
	log_combat(to_log, paicard.pai, "ejected [user ? "from [initial(name)]" : ""].")
	if(announce)
		to_chat(paicard.pai, span_notice("You feel your control fade as [paicard] ejects from [initial(name)]."))
	paicard = null
	name = initial(name)
	faction = initial(faction)
	remove_all_languages(source = LANGUAGE_PAI)
	get_selected_language()

/// Ejects the pAI remotely.
/mob/living/basic/bot/proc/eject_pai_remote(mob/user)
	if(!allowed(user) || !paicard)
		return
	speak("Ejecting personality chip.", radio_channel)
	ejectpai(user)

/mob/living/basic/bot/Login()
	. = ..()
	if(!. || isnull(client))
		return FALSE
	REMOVE_TRAIT(src, TRAIT_NO_GLIDE, INNATE_TRAIT)
	speed = 2

	diag_hud_set_botmode()
	clear_path_hud()

/mob/living/basic/bot/Logout()
	. = ..()
	bot_reset()
	speed = initial(speed)
	ADD_TRAIT(src, TRAIT_NO_GLIDE, INNATE_TRAIT)

/mob/living/basic/bot/revive(full_heal_flags = NONE, excess_healing = 0, force_grab_ghost = FALSE)
	. = ..()
	if(!.)
		return
	update_appearance()

/mob/living/basic/bot/rust_heretic_act()
	adjustBruteLoss(400)

/mob/living/basic/bot/proc/attempt_access(mob/bot, obj/door_attempt)
	SIGNAL_HANDLER

	return (door_attempt.check_access(access_card) ? ACCESS_ALLOWED : ACCESS_DISALLOWED)

/mob/living/basic/bot/proc/generate_speak_list()
	return null

/mob/living/basic/bot/proc/provide_additional_access()
	var/datum/id_trim/additional_trim = SSid_access.trim_singletons_by_path[additional_access]
	if(isnull(additional_trim))
		return
	access_card.add_access(additional_trim.access + additional_trim.wildcard_access)
	initial_access = access_card.access.Copy()


/mob/living/basic/bot/proc/summon_bot(atom/summoner, turf/turf_destination, user_access = list(), grant_all_access = FALSE)
	if(isAI(summoner) && !set_ai_caller(summoner))
		return FALSE
	bot_reset(bypass_ai_reset = isAI(summoner))
	var/turf/destination = turf_destination ? turf_destination : get_turf(summoner)
	ai_controller?.set_blackboard_key(BB_BOT_SUMMON_TARGET, destination)
	var/list/access_to_grant = grant_all_access ? REGION_ACCESS_ALL_STATION : user_access + initial_access
	access_card.set_access(access_to_grant)
	speak("Responding.", radio_channel)
	update_bot_mode(new_mode = BOT_SUMMON)
	if(client) //if we're sentient, we reset ourselves after a short period
		addtimer(CALLBACK(src, PROC_REF(bot_reset)), SENTIENT_BOT_RESET_TIMER)
	return TRUE

/mob/living/basic/bot/proc/set_ai_caller(mob/living/ai_caller)
	var/atom/calling_ai = calling_ai_ref?.resolve()
	if(!isnull(calling_ai) && calling_ai != src)
		return FALSE
	calling_ai_ref = WEAKREF(ai_caller)
	return TRUE

/mob/living/basic/bot/proc/update_bot_mode(new_mode, update_hud = TRUE)
	mode = new_mode
	update_appearance()
	if(update_hud)
		diag_hud_set_botmode()

/mob/living/basic/bot/proc/after_attacked(datum/source, atom/attacker, attack_flags)
	SIGNAL_HANDLER

	if(attack_flags & ATTACKER_DAMAGING_ATTACK)
		do_sparks(number = 5, cardinal_only = TRUE, source = src)

/mob/living/basic/bot/proc/emag_effects(user)
	return

/mob/living/basic/bot/spawn_gibs(drop_bitflags = NONE)
	new /obj/effect/gibspawner/robot(drop_location(), src)

/mob/living/basic/bot/get_hit_area_message(input_area)
	// we just get hit, there's no complexity for hitting an arm (if it exists) or anything.
	// we also need to return an empty string as otherwise it would falsely say that we get hit in the chest or something strange like that (bots don't have "chests")
	return ""

/mob/living/basic/bot/proc/on_bot_movement(atom/movable/source, atom/oldloc, dir, forced)
	return

#undef SENTIENT_BOT_RESET_TIMER
