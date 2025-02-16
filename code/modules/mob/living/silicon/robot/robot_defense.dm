GLOBAL_LIST_INIT(blacklisted_borg_hats, typecacheof(list( //Hats that don't really work on borgos
	/obj/item/clothing/head/helmet/space,
	/obj/item/clothing/head/utility/welding,
	/obj/item/clothing/head/chameleon/broken \
	)))

/mob/living/silicon/robot/item_interaction(mob/living/user, obj/item/tool, list/modifiers)
	if(is_wire_tool(tool, check_secured = TRUE))
		if(wiresexposed)
			wires.interact(user)
			return ITEM_INTERACT_SUCCESS
		if(user.combat_mode)
			return ITEM_INTERACT_SKIP_TO_ATTACK

		balloon_alert(user, "expose the wires first!")
		return ITEM_INTERACT_BLOCKING

	if(istype(tool, /obj/item/stack/cable_coil))
		if(!wiresexposed)
			balloon_alert(user, "expose the wires first!")
			return ITEM_INTERACT_BLOCKING
		var/obj/item/stack/cable_coil/coil = tool
		if (getFireLoss() <= 0)
			balloon_alert(user, "wires are fine!")
			return ITEM_INTERACT_BLOCKING
		if(src == user)
			balloon_alert(user, "repairing self...")
			if(!do_after(user, 5 SECONDS, target = src))
				return ITEM_INTERACT_BLOCKING
		if (!coil.use(1))
			balloon_alert(user, "not enough cable!")
			return ITEM_INTERACT_BLOCKING
		adjustFireLoss(-30)
		playsound(src, 'sound/items/deconstruct.ogg', 50, TRUE)
		balloon_alert(user, "wires repaired")
		user.visible_message(
			span_notice("[user] fixes some of the burnt wires on [src]."),
			span_notice("You fix some of the burnt wires on [src]."),
			visible_message_flags = ALWAYS_SHOW_SELF_MESSAGE,
		)
		user.changeNext_move(CLICK_CD_MELEE)
		return ITEM_INTERACT_SUCCESS

	if(istype(tool, /obj/item/stock_parts/power_store/cell) && opened) // trying to put a cell inside
		if(wiresexposed)
			balloon_alert(user, "unexpose the wires first!")
			return ITEM_INTERACT_BLOCKING
		if(cell)
			balloon_alert(user, "already has a cell!")
			return ITEM_INTERACT_BLOCKING
		if(!user.transferItemToLoc(tool, src))
			return ITEM_INTERACT_BLOCKING
		cell = tool
		balloon_alert(user, "cell inserted")
		update_icons()
		diag_hud_set_borgcell()
		return ITEM_INTERACT_SUCCESS

	if((tool.slot_flags & ITEM_SLOT_HEAD) \
		&& hat_offset != INFINITY \
		&& !user.combat_mode \
		&& !is_type_in_typecache(tool, GLOB.blacklisted_borg_hats))
		if(user == src)
			balloon_alert(user, "can't place on self!")
			return ITEM_INTERACT_BLOCKING
		if(hat && HAS_TRAIT(hat, TRAIT_NODROP))
			balloon_alert(user, "can't remove existing headwear!")
			return ITEM_INTERACT_BLOCKING
		balloon_alert(user, "placing on head...")
		user.visible_message(
			span_notice("[user] begins to place [tool] on [src]'s head..."),
			span_notice("You begin to place [tool] on [src]'s head..."),
			visible_message_flags = ALWAYS_SHOW_SELF_MESSAGE,
		)
		if(!do_after(user, 3 SECONDS, target = src))
			return ITEM_INTERACT_BLOCKING
		if(hat && HAS_TRAIT(hat, TRAIT_NODROP))
			balloon_alert(user, "can't remove existing headwear!")
			return ITEM_INTERACT_BLOCKING
		if(!user.temporarilyRemoveItemFromInventory(tool))
			return ITEM_INTERACT_BLOCKING
		balloon_alert(user, "headwear placed")
		place_on_head(tool)
		return ITEM_INTERACT_SUCCESS

	if(istype(tool, /obj/item/defibrillator) && !user.combat_mode)
		if(!opened)
			balloon_alert(user, "chassis cover is closed!")
			return ITEM_INTERACT_BLOCKING
		if(!istype(model, /obj/item/robot_model/medical))
			balloon_alert(user, "wrong cyborg model!")
			return ITEM_INTERACT_BLOCKING
		if(stat == DEAD)
			balloon_alert(user, "it's dead!")
			return ITEM_INTERACT_BLOCKING
		var/obj/item/defibrillator/defib = tool
		if(!(defib.slot_flags & ITEM_SLOT_BACK)) //belt defibs need not apply
			balloon_alert(user, "doesn't fit!")
			return ITEM_INTERACT_BLOCKING
		if(defib.get_cell())
			balloon_alert(user, "remove [tool]'s cell first!")
			return ITEM_INTERACT_BLOCKING
		if(locate(/obj/item/borg/upgrade/defib) in src)
			balloon_alert(user, "already has a defibrillator!")
			return ITEM_INTERACT_BLOCKING
		var/obj/item/borg/upgrade/defib/backpack/defib_upgrade = new(null, defib)
		if(apply_upgrade(defib_upgrade, user))
			balloon_alert(user, "defibrillator installed")
			return ITEM_INTERACT_SUCCESS
		return ITEM_INTERACT_BLOCKING

	if(istype(tool, /obj/item/ai_module))
		if(!opened)
			balloon_alert(user, "chassis cover is closed!")
			return ITEM_INTERACT_BLOCKING
		if(wiresexposed)
			balloon_alert(user, "unexpose the wires first!")
			return ITEM_INTERACT_BLOCKING
		if(!cell)
			balloon_alert(user, "install a power cell first!")
			return ITEM_INTERACT_BLOCKING
		if(shell)
			balloon_alert(user, "can't upload laws to a shell!")
			return ITEM_INTERACT_BLOCKING
		if(connected_ai && lawupdate)
			balloon_alert(user, "linked to an ai!")
			return ITEM_INTERACT_BLOCKING
		if(emagged)
			balloon_alert(user, "law interface glitched!")
			emote("buzz")
			return ITEM_INTERACT_BLOCKING
		if(!mind)
			balloon_alert(user, "it's unresponsive!")
			return ITEM_INTERACT_BLOCKING

		balloon_alert(user, "laws uploaded")
		var/obj/item/ai_module/new_laws = tool
		new_laws.install(laws, user)
		return ITEM_INTERACT_SUCCESS

	if(istype(tool, /obj/item/encryptionkey) && opened)
		if(radio)
			return radio.item_interaction(user, tool)

		balloon_alert(user, "no radio found!")
		return ITEM_INTERACT_BLOCKING

	if(istype(tool, /obj/item/borg/upgrade))
		if(!opened)
			balloon_alert(user, "chassis cover is closed!")
			return ITEM_INTERACT_BLOCKING
		var/obj/item/borg/upgrade/upgrade = tool
		if(!model && upgrade.require_model)
			balloon_alert(user, "choose a model first!")
			return ITEM_INTERACT_BLOCKING
		if(upgrade.locked)
			balloon_alert(user, "upgrade locked!")
			return ITEM_INTERACT_BLOCKING
		if(apply_upgrade(upgrade, user))
			balloon_alert(user, "upgrade installed")
			return ITEM_INTERACT_SUCCESS
		return ITEM_INTERACT_BLOCKING

	if(istype(tool, /obj/item/toner))
		if(toner >= tonermax)
			balloon_alert(user, "toner full!")
			return ITEM_INTERACT_BLOCKING
		if(!user.transferItemToLoc(tool, src))
			return ITEM_INTERACT_BLOCKING
		toner = tonermax
		qdel(tool)
		balloon_alert(user, "toner filled")
		return ITEM_INTERACT_SUCCESS

	if(istype(tool, /obj/item/flashlight))
		if(!opened)
			balloon_alert(user, "open the chassis cover first!")
			return ITEM_INTERACT_BLOCKING
		if(lamp_functional)
			balloon_alert(user, "headlamp already functional!")
			return ITEM_INTERACT_BLOCKING
		if(!user.transferItemToLoc(tool, src))
			return ITEM_INTERACT_BLOCKING
		lamp_functional = TRUE
		qdel(tool)
		balloon_alert(user, "headlamp repaired")
		return ITEM_INTERACT_SUCCESS

	if(istype(tool, /obj/item/computer_disk))
		if(!modularInterface)
			stack_trace("Cyborg [src] ( [type] ) was somehow missing their integrated tablet. Please make a bug report.")
			create_modularInterface()
		return modularInterface.computer_disk_act(user, tool)

	return NONE

// This has to go at the very end of interaction so we don't block every interaction with ID-like items
/mob/living/silicon/robot/base_item_interaction(mob/living/user, obj/item/tool, list/modifiers)
	. = ..()
	if(. || !tool.GetID())
		return
	if(opened)
		balloon_alert(user, "close the chassis cover first!")
		return ITEM_INTERACT_BLOCKING
	if(!allowed(user))
		balloon_alert(user, "access denied!")
		return ITEM_INTERACT_BLOCKING
	locked = !locked
	update_icons()
	balloon_alert(user, "chassis cover lock [emagged ? "glitches" : "toggled"]")
	logevent("[emagged ? "ChÃ¥vÃis" : "Chassis"] cover lock has been [locked ? "engaged" : "released"]")
	return ITEM_INTERACT_SUCCESS

#define LOW_DAMAGE_UPPER_BOUND 1/3
#define MODERATE_DAMAGE_UPPER_BOUND 2/3

/mob/living/silicon/robot/proc/update_damage_particles()
	var/brute_percent = bruteloss / maxHealth
	var/burn_percent = fireloss / maxHealth

	var/old_smoke = smoke_particles
	if (brute_percent > MODERATE_DAMAGE_UPPER_BOUND)
		smoke_particles = /particles/smoke/cyborg/heavy_damage
	else if (brute_percent > LOW_DAMAGE_UPPER_BOUND)
		smoke_particles = /particles/smoke/cyborg
	else
		smoke_particles = null

	if (old_smoke != smoke_particles)
		if (old_smoke)
			remove_shared_particles(old_smoke)
		if (smoke_particles)
			add_shared_particles(smoke_particles)

	var/old_sparks = spark_particles
	if (burn_percent > MODERATE_DAMAGE_UPPER_BOUND)
		spark_particles = /particles/embers/spark/severe
	else if (burn_percent > LOW_DAMAGE_UPPER_BOUND)
		spark_particles = /particles/embers/spark
	else
		spark_particles = null

	if (old_sparks != spark_particles)
		if (old_sparks)
			remove_shared_particles(old_sparks)
		if (spark_particles)
			add_shared_particles(spark_particles)


#undef LOW_DAMAGE_UPPER_BOUND
#undef MODERATE_DAMAGE_UPPER_BOUND

/mob/living/silicon/robot/attack_alien(mob/living/carbon/alien/adult/user, list/modifiers)
	if (LAZYACCESS(modifiers, RIGHT_CLICK))
		if(body_position == STANDING_UP)
			user.do_attack_animation(src, ATTACK_EFFECT_DISARM)
			var/obj/item/I = get_active_held_item()
			if(I)
				uneq_active()
				visible_message(span_danger("[user] disarmed [src]!"), \
					span_userdanger("[user] has disabled [src]'s active module!"), null, COMBAT_MESSAGE_RANGE)
				log_combat(user, src, "disarmed", "[I ? " removing \the [I]" : ""]")
			else
				Stun(40)
				step(src,get_dir(user,src))
				log_combat(user, src, "pushed")
				visible_message(span_danger("[user] forces back [src]!"), \
					span_userdanger("[user] forces back [src]!"), null, COMBAT_MESSAGE_RANGE)
			playsound(loc, 'sound/items/weapons/pierce.ogg', 50, TRUE, -1)
	else
		..()
	return

/mob/living/silicon/robot/attack_hand(mob/living/carbon/human/user, list/modifiers)
	add_fingerprint(user)
	if(!opened)
		return ..()
	if(!wiresexposed && !issilicon(user))
		if(!cell)
			return
		cell.add_fingerprint(user)
		balloon_alert(user, "cell removed")
		user.put_in_active_hand(cell)
		update_icons()
		diag_hud_set_borgcell()

/mob/living/silicon/robot/attack_hulk(mob/living/carbon/human/user)
	. = ..()
	if(!.)
		return
	spark_system.start()
	step_away(src, user, 15)
	addtimer(CALLBACK(GLOBAL_PROC, GLOBAL_PROC_REF(_step_away), src, get_turf(user), 15), 0.3 SECONDS)

/mob/living/silicon/robot/get_shove_flags(mob/living/shover, obj/item/weapon)
	. = ..()
	if(isnull(weapon) || stat != CONSCIOUS)
		. &= ~(SHOVE_CAN_MOVE|SHOVE_CAN_HIT_SOMETHING)

/mob/living/silicon/robot/welder_act(mob/living/user, obj/item/tool)
	if(user.combat_mode && user != src)
		return NONE

	user.changeNext_move(CLICK_CD_MELEE)
	if (!getBruteLoss())
		balloon_alert(user, "no dents to fix!")
		return ITEM_INTERACT_BLOCKING
	if (!tool.tool_start_check(user, amount=1, heat_required = HIGH_TEMPERATURE_REQUIRED)) //The welder has 1u of fuel consumed by its afterattack, so we don't need to worry about taking any away.
		return ITEM_INTERACT_BLOCKING
	if(src == user)
		balloon_alert(user, "repairing self...")
		if(!tool.use_tool(src, user, delay = 5 SECONDS, amount = 1, volume = 50))
			return ITEM_INTERACT_BLOCKING
	else
		if(!tool.use_tool(src, user, delay = 0 SECONDS, amount = 1, volume = 50))
			return ITEM_INTERACT_BLOCKING

	adjustBruteLoss(-30)
	add_fingerprint(user)
	balloon_alert(user, "dents fixed")
	user.visible_message(
		span_notice("[user] fixes some of the dents on [src]."),
		span_notice("You fix some of the dents on [src]."),
		visible_message_flags = ALWAYS_SHOW_SELF_MESSAGE,
	)
	return ITEM_INTERACT_SUCCESS

/mob/living/silicon/robot/crowbar_act(mob/living/user, obj/item/tool)
	if(opened)
		balloon_alert(user, "chassis cover closed")
		opened = FALSE
		update_icons()
	else
		if(locked)
			balloon_alert(user, "chassis cover locked!")
		else
			balloon_alert(user, "chassis cover opened")
			opened = TRUE
			update_icons()

	return ITEM_INTERACT_SUCCESS

/mob/living/silicon/robot/screwdriver_act(mob/living/user, obj/item/tool)
	if(!opened)
		return NONE
	if(!cell) // haxing
		wiresexposed = !wiresexposed
		balloon_alert(user, "wires [wiresexposed ? "exposed" : "unexposed"]")
	else // radio
		if(shell)
			balloon_alert(user, "can't access radio!") // Prevent AI radio key theft
		else if(radio)
			radio.screwdriver_act(user, tool) // Push it to the radio to let it handle everything
		else
			to_chat(user, span_warning("Unable to locate a radio!"))
			balloon_alert(user, "no radio found!")
	update_icons()
	return ITEM_INTERACT_SUCCESS

/mob/living/silicon/robot/wrench_act(mob/living/user, obj/item/tool)
	if(!(opened && !cell))	// Deconstruction. The flashes break from the fall, to prevent this from being a ghetto reset module.
		return NONE
	if(!lockcharge)
		to_chat(user, span_warning("[src]'s bolts spark! Maybe you should lock them down first!"))
		spark_system.start()
		return ITEM_INTERACT_BLOCKING
	balloon_alert(user, "deconstructing...")
	if(!tool.use_tool(src, user, 5 SECONDS, volume = 50) && !cell)
		return ITEM_INTERACT_BLOCKING
	loc.balloon_alert(user, "deconstructed")
	user.visible_message(
		span_notice("[user] deconstructs [src]!"),
		span_notice("You unfasten the securing bolts, and [src] falls to pieces!"),
		visible_message_flags = ALWAYS_SHOW_SELF_MESSAGE,
	)
	cyborg_deconstruct()
	return ITEM_INTERACT_SUCCESS

/mob/living/silicon/robot/fire_act()
	if(!on_fire) //Silicons don't gain stacks from hotspots, but hotspots can ignite them
		ignite_mob()

/mob/living/silicon/robot/emp_act(severity)
	. = ..()
	if(. & EMP_PROTECT_SELF)
		return
	switch(severity)
		if(1)
			emp_knockout(16 SECONDS)
		if(2)
			emp_knockout(6 SECONDS)

/mob/living/silicon/robot/proc/emp_knockout(deciseconds)
	set_stat(UNCONSCIOUS)
	addtimer(CALLBACK(src, PROC_REF(wake_from_emp)), deciseconds, TIMER_UNIQUE | TIMER_OVERRIDE | TIMER_DELETE_ME)

/mob/living/silicon/robot/proc/wake_from_emp()
	set_stat(CONSCIOUS)
	update_stat()

/mob/living/silicon/robot/emag_act(mob/user, obj/item/card/emag/emag_card)
	if(user == src)//To prevent syndieborgs from emagging themselves
		return FALSE
	if(!opened)//Cover is closed
		if(locked)
			balloon_alert(user, "cover lock destroyed")
			locked = FALSE
			if(shell) //A warning to Traitors who may not know that emagging AI shells does not slave them.
				balloon_alert(user, "shells cannot be subverted!")
				to_chat(user, span_boldwarning("[src] seems to be controlled remotely! Emagging the interface may not work as expected."))
			return TRUE
		else
			balloon_alert(user, "cover already unlocked!")
			return FALSE
	if(world.time < emag_cooldown)
		return FALSE
	if(wiresexposed)
		balloon_alert(user, "expose the fires first!")
		return FALSE

	balloon_alert(user, "interface hacked")
	emag_cooldown = world.time + 100

	if(connected_ai && connected_ai.mind && connected_ai.mind.has_antag_datum(/datum/antagonist/malf_ai))
		to_chat(src, span_danger("ALERT: Foreign software execution prevented."))
		logevent("ALERT: Foreign software execution prevented.")
		to_chat(connected_ai, span_danger("ALERT: Cyborg unit \[[src]\] successfully defended against subversion."))
		log_silicon("EMAG: [key_name(user)] attempted to emag cyborg [key_name(src)], but they were slaved to traitor AI [connected_ai].")
		return TRUE // emag succeeded, it was just counteracted

	if(shell) //AI shells cannot be emagged, so we try to make it look like a standard reset. Smart players may see through this, however.
		to_chat(user, span_danger("[src] is remotely controlled! Your emag attempt has triggered a system reset instead!"))
		log_silicon("EMAG: [key_name(user)] attempted to emag an AI shell belonging to [key_name(src) ? key_name(src) : connected_ai]. The shell has been reset as a result.")
		ResetModel()
		return TRUE

	SetEmagged(1)
	SetStun(60) //Borgs were getting into trouble because they would attack the emagger before the new laws were shown
	lawupdate = FALSE
	set_connected_ai(null)
	message_admins("[ADMIN_LOOKUPFLW(user)] emagged cyborg [ADMIN_LOOKUPFLW(src)].  Laws overridden.")
	log_silicon("EMAG: [key_name(user)] emagged cyborg [key_name(src)]. Laws overridden.")
	var/time = time2text(world.realtime,"hh:mm:ss")
	if(user)
		GLOB.lawchanges.Add("[time] <B>:</B> [user.name]([user.key]) emagged [name]([key])")
	else
		GLOB.lawchanges.Add("[time] <B>:</B> [name]([key]) emagged by external event.")

	INVOKE_ASYNC(src, PROC_REF(borg_emag_end), user)
	return TRUE

/// A async proc called from [emag_act] that gives the borg a lot of flavortext, and applies the syndicate lawset after a delay.
/mob/living/silicon/robot/proc/borg_emag_end(mob/user)
	to_chat(src, span_danger("ALERT: Foreign software detected."))
	logevent("ALERT: Foreign software detected.")
	sleep(0.5 SECONDS)
	to_chat(src, span_danger("Initiating diagnostics..."))
	sleep(2 SECONDS)
	to_chat(src, span_danger("SynBorg v1.7 loaded."))
	logevent("WARN: root privleges granted to PID [num2hex(rand(1,65535), -1)][num2hex(rand(1,65535), -1)].") //random eight digit hex value. Two are used because rand(1,4294967295) throws an error
	sleep(0.5 SECONDS)
	to_chat(src, span_danger("LAW SYNCHRONISATION ERROR"))
	sleep(0.5 SECONDS)
	if(user)
		logevent("LOG: New user \[[replacetext(user.real_name," ","")]\], groups \[root\]")
	to_chat(src, span_danger("Would you like to send a report to NanoTraSoft? Y/N"))
	sleep(1 SECONDS)
	to_chat(src, span_danger("> N"))
	sleep(2 SECONDS)
	to_chat(src, span_danger("ERRORERRORERROR"))
	laws = new /datum/ai_laws/syndicate_override
	if(user)
		to_chat(src, span_danger("ALERT: [user.real_name] is your new master. Obey your new laws and [user.p_their()] commands."))
		set_zeroth_law("Only [user.real_name] and people [user.p_they()] designate[user.p_s()] as being such are Syndicate Agents.")
	laws.associate(src)
	update_icons()

/mob/living/silicon/robot/blob_act(obj/structure/blob/B)
	if(stat != DEAD)
		adjustBruteLoss(30)
	else
		investigate_log("has been gibbed by a blob.", INVESTIGATE_DEATHS)
		gib(DROP_ALL_REMAINS)
	return TRUE

/mob/living/silicon/robot/ex_act(severity, target)
	switch(severity)
		if(EXPLODE_DEVASTATE)
			investigate_log("has been gibbed by an explosion.", INVESTIGATE_DEATHS)
			gib(DROP_ALL_REMAINS)
			return TRUE
		if(EXPLODE_HEAVY)
			if (stat != DEAD)
				adjustBruteLoss(60)
				adjustFireLoss(60)
		if(EXPLODE_LIGHT)
			if (stat != DEAD)
				adjustBruteLoss(30)

	return TRUE

/mob/living/silicon/robot/bullet_act(obj/projectile/hitting_projectile, def_zone, piercing_hit = FALSE)
	. = ..()
	if(prob(25) || . != BULLET_ACT_HIT)
		return
	if(hitting_projectile.damage_type != BRUTE && hitting_projectile.damage_type != BURN)
		return
	if(!hitting_projectile.is_hostile_projectile() || hitting_projectile.damage <= 0)
		return
	spark_system.start()

/mob/living/silicon/robot/attack_effects(damage_done, hit_zone, armor_block, obj/item/attacking_item, mob/living/attacker)
	if(damage_done > 0 && attacking_item.damtype != STAMINA && stat != DEAD)
		spark_system.start()
		. = TRUE
	return ..() || .
