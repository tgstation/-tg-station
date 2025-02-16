// robot_upgrades.dm
// Contains various borg upgrades.

/obj/item/borg/upgrade
	name = "borg upgrade module"
	desc = "Protected by FRM."
	icon = 'icons/mob/silicon/robot_items.dmi'
	icon_state = "module_general"
	w_class = WEIGHT_CLASS_SMALL
	var/locked = FALSE
	var/installed = FALSE
	var/require_model = FALSE
	var/list/model_type = null
	/// Bitflags listing model compatibility. Used in the exosuit fabricator for creating sub-categories.
	var/model_flags = NONE

	/// List of items to add with the module, if any
	var/list/items_to_add
	/// List of items to remove with the module, if any
	var/list/items_to_remove
	// if true, is not stored in the robot to be ejected if model is reset
	var/one_use = FALSE
	// If the module allows duplicates of itself to exist within the borg.
	// one_use technically makes this value not mean anything, maybe could be just one variable with flags?
	var/allow_duplicates = FALSE

/obj/item/borg/upgrade/proc/action(mob/living/silicon/robot/borg, mob/living/user = usr)
	if(borg.stat == DEAD)
		to_chat(user, span_warning("[src] will not function on a deceased cyborg!"))
		return FALSE
	if(model_type && !is_type_in_list(borg.model, model_type))
		to_chat(borg, span_alert("Upgrade mounting error! No suitable hardpoint detected."))
		to_chat(user, span_warning("There's no mounting point for the module!"))
		return FALSE
	if(!allow_duplicates && (locate(type) in borg.upgrades))
		to_chat(borg, span_alert("Upgrade mounting error! Hardpoint already occupied!"))
		to_chat(user, span_warning("The mounting point for the module is already occupied!"))
		return FALSE
	// Handles adding/removing items.
	if(length(items_to_add))
		install_items(borg, user, items_to_add)
	if(length(items_to_remove))
		remove_items(borg, user, items_to_remove)
	return TRUE

/obj/item/borg/upgrade/proc/deactivate(mob/living/silicon/robot/borg, mob/living/user = usr)
	if (!(src in borg.upgrades))
		return FALSE

	// Handles reverting the items back
	if(length(items_to_add))
		remove_items(borg, user, items_to_add)
	if(length(items_to_remove))
		install_items(borg, user, items_to_remove)
	return TRUE

// Handles adding items with the module
/obj/item/borg/upgrade/proc/install_items(mob/living/silicon/robot/borg, mob/living/user = usr, list/items)
	for(var/item_to_add in items)
		var/obj/item/module_item = new item_to_add(borg.model)
		borg.model.basic_modules += module_item
		borg.model.add_module(module_item, FALSE, TRUE)
	return TRUE

// Handles removing some items as the module is installed
/obj/item/borg/upgrade/proc/remove_items(mob/living/silicon/robot/borg, mob/living/user = usr, list/items)
	for(var/item_to_remove in items)
		var/obj/item/module_item = locate(item_to_remove) in borg.model.modules
		if (module_item)
			borg.model.remove_module(module_item, TRUE)
	return TRUE

/obj/item/borg/upgrade/rename
	name = "cyborg reclassification board"
	desc = "Used to rename a cyborg."
	icon = 'icons/obj/devices/circuitry_n_data.dmi'
	icon_state = "cyborg_upgrade1"
	var/heldname = ""
	one_use = TRUE

/obj/item/borg/upgrade/rename/attack_self(mob/user)
	var/new_heldname = sanitize_name(tgui_input_text(user, "Enter new robot name", "Cyborg Reclassification", heldname, MAX_NAME_LEN), allow_numbers = TRUE)
	if(!new_heldname || !user.is_holding(src))
		return
	heldname = new_heldname
	user.log_message("set \"[heldname]\" as a name in a cyborg reclassification board at [loc_name(user)]", LOG_GAME)

/obj/item/borg/upgrade/rename/action(mob/living/silicon/robot/borg, mob/living/user = usr)
	. = ..()
	if(!.)
		return .
	var/oldname = borg.real_name
	var/oldkeyname = key_name(borg)
	borg.custom_name = heldname
	borg.updatename()
	if(oldname == borg.real_name)
		borg.notify_ai(AI_NOTIFICATION_CYBORG_RENAMED, oldname, borg.real_name)
	user.log_message("used a cyborg reclassification board to rename [oldkeyname] to [key_name(borg)]", LOG_GAME)

/obj/item/borg/upgrade/disablercooler
	name = "cyborg rapid disabler cooling module"
	desc = "Used to cool a mounted disabler, increasing the potential current in it and thus its recharge rate."
	icon_state = "module_security"
	require_model = TRUE
	model_type = list(/obj/item/robot_model/security)
	model_flags = BORG_MODEL_SECURITY
	// We handle this in a custom way
	allow_duplicates = TRUE

/obj/item/borg/upgrade/disablercooler/action(mob/living/silicon/robot/borg, mob/living/user = usr)
	. = ..()
	if(!.)
		return .

	var/obj/item/gun/energy/disabler/cyborg/disabler = locate() in borg.model.modules
	if(isnull(disabler))
		to_chat(user, span_warning("There's no disabler in this unit!"))
		return FALSE
	if(disabler.charge_delay <= 2)
		to_chat(borg, span_warning("A cooling unit is already installed!"))
		to_chat(user, span_warning("There's no room for another cooling unit!"))
		return FALSE

	disabler.charge_delay = max(2 , disabler.charge_delay - 4)

/obj/item/borg/upgrade/disablercooler/deactivate(mob/living/silicon/robot/borg, mob/living/user = usr)
	. = ..()
	if(!.)
		return .
	var/obj/item/gun/energy/disabler/cyborg/disabler = locate() in borg.model.modules
	if(isnull(disabler))
		return FALSE
	disabler.charge_delay = initial(disabler.charge_delay)

/obj/item/borg/upgrade/thrusters
	name = "ion thruster upgrade"
	desc = "An energy-operated thruster system for cyborgs."
	icon_state = "module_general"

/obj/item/borg/upgrade/thrusters/action(mob/living/silicon/robot/borg, mob/living/user = usr)
	. = ..()
	if(!.)
		return .
	if(borg.ionpulse)
		to_chat(user, span_warning("This unit already has ion thrusters installed!"))
		return FALSE

	borg.ionpulse = TRUE
	borg.toggle_ionpulse() //Enabled by default

/obj/item/borg/upgrade/thrusters/deactivate(mob/living/silicon/robot/borg, mob/living/user = usr)
	. = ..()
	if(!.)
		return .
	borg.ionpulse = FALSE

/obj/item/borg/upgrade/diamond_drill
	name = "mining cyborg diamond drill"
	desc = "A diamond drill replacement for the mining model's standard drill."
	icon_state = "module_miner"
	require_model = TRUE
	model_type = list(/obj/item/robot_model/miner)
	model_flags = BORG_MODEL_MINER

	items_to_add = list(/obj/item/pickaxe/drill/cyborg/diamond)
	items_to_remove = list(/obj/item/pickaxe/drill/cyborg, /obj/item/shovel)

/obj/item/borg/upgrade/soh
	name = "mining cyborg satchel of holding"
	desc = "A satchel of holding replacement for mining cyborg's ore satchel module."
	icon_state = "module_miner"
	require_model = TRUE
	model_type = list(/obj/item/robot_model/miner)
	model_flags = BORG_MODEL_MINER

	items_to_add = list(/obj/item/storage/bag/ore/holding)
	items_to_remove = list(/obj/item/storage/bag/ore/cyborg)

/obj/item/borg/upgrade/tboh
	name = "janitor cyborg trash bag of holding"
	desc = "A trash bag of holding replacement for the janiborg's standard trash bag."
	icon_state = "module_janitor"
	require_model = TRUE
	model_type = list(/obj/item/robot_model/janitor)
	model_flags = BORG_MODEL_JANITOR

	items_to_add = list(/obj/item/storage/bag/trash/bluespace/cyborg)
	items_to_remove = list(/obj/item/storage/bag/trash/cyborg)

/obj/item/borg/upgrade/amop
	name = "janitor cyborg advanced mop"
	desc = "An advanced mop replacement for the janiborg's standard mop."
	icon_state = "module_janitor"
	require_model = TRUE
	model_type = list(/obj/item/robot_model/janitor)
	model_flags = BORG_MODEL_JANITOR

	items_to_add = list(/obj/item/mop/advanced/cyborg)
	items_to_remove = list(/obj/item/mop/cyborg)

/obj/item/borg/upgrade/prt
	name = "janitor cyborg plating repair tool"
	desc = "A tiny heating device to repair burnt and damaged hull platings with."
	icon_state = "module_janitor"
	require_model = TRUE
	model_type = list(/obj/item/robot_model/janitor)
	model_flags = BORG_MODEL_JANITOR

	items_to_add = list(/obj/item/cautery/prt)

/obj/item/borg/upgrade/plunger
	name = "janitor cyborg plunging tool"
	desc = "An integrated cyborg retractable plunger. It's meant for plunging things, duh."
	icon_state = "module_janitor"
	require_model = TRUE
	model_type = list(/obj/item/robot_model/janitor)
	model_flags = BORG_MODEL_JANITOR

	items_to_add = list(/obj/item/plunger/cyborg)

/obj/item/borg/upgrade/high_capacity_light_replacer
	name = "janitor cyborg high capacity replacer"
	desc = "Increases the amount of lights that can be stored in the replacer."
	icon_state = "module_janitor"
	require_model = TRUE
	model_type = list(/obj/item/robot_model/janitor)
	model_flags = BORG_MODEL_JANITOR

	items_to_add = list (/obj/item/lightreplacer/cyborg/advanced)
	items_to_remove = list(/obj/item/lightreplacer/cyborg)

/obj/item/borg/upgrade/syndicate
	name = "illegal equipment module"
	desc = "Unlocks the hidden, deadlier functions of a cyborg."
	icon_state = "module_illegal"
	require_model = TRUE

/obj/item/borg/upgrade/syndicate/Initialize(mapload)
	. = ..()
	ADD_TRAIT(src, TRAIT_CONTRABAND, INNATE_TRAIT)

/obj/item/borg/upgrade/syndicate/action(mob/living/silicon/robot/borg, mob/living/user = usr)
	. = ..()
	if(!.)
		return .
	if(borg.emagged)
		return FALSE

	borg.SetEmagged(TRUE)
	borg.logevent("WARN: hardware installed with missing security certificate!") //A bit of fluff to hint it was an illegal tech item
	borg.logevent("WARN: root privleges granted to PID [num2hex(rand(1,65535), -1)][num2hex(rand(1,65535), -1)].") //random eight digit hex value. Two are used because rand(1,4294967295) throws an error

	return TRUE

/obj/item/borg/upgrade/syndicate/deactivate(mob/living/silicon/robot/borg, mob/living/user = usr)
	. = ..()
	if(!.)
		return .
	borg.SetEmagged(FALSE)

/obj/item/borg/upgrade/lavaproof
	name = "mining cyborg lavaproof chassis"
	desc = "An upgrade kit to apply specialized coolant systems and insulation layers to a mining cyborg's chassis, enabling them to withstand exposure to molten rock and liquid plasma."
	icon_state = "module_miner"
	resistance_flags = LAVA_PROOF | FIRE_PROOF | FREEZE_PROOF
	require_model = TRUE
	model_type = list(/obj/item/robot_model/miner)
	model_flags = BORG_MODEL_MINER

/obj/item/borg/upgrade/lavaproof/action(mob/living/silicon/robot/borg, mob/living/user = usr)
	. = ..()
	if(!.)
		return .
	borg.add_traits(list(TRAIT_LAVA_IMMUNE, TRAIT_SNOWSTORM_IMMUNE), type)

/obj/item/borg/upgrade/lavaproof/deactivate(mob/living/silicon/robot/borg, mob/living/user = usr)
	. = ..()
	if(!.)
		return .
	borg.remove_traits(list(TRAIT_LAVA_IMMUNE, TRAIT_SNOWSTORM_IMMUNE), type)

/obj/item/borg/upgrade/selfrepair
	name = "self-repair module"
	desc = "This module will repair the cyborg over time."
	icon_state = "module_general"
	require_model = TRUE
	var/repair_amount = -1
	/// world.time of next repair
	var/next_repair = 0
	/// Minimum time between repairs in seconds
	var/repair_cooldown = 4
	var/on = FALSE
	var/energy_cost = 0.01 * STANDARD_CELL_CHARGE
	var/datum/action/toggle_action

/obj/item/borg/upgrade/selfrepair/action(mob/living/silicon/robot/borg, mob/living/user = usr)
	. = ..()
	if(!.)
		return .
	icon_state = "selfrepair_off"
	toggle_action = new /datum/action/item_action/toggle(src)
	toggle_action.Grant(borg)

/obj/item/borg/upgrade/selfrepair/deactivate(mob/living/silicon/robot/borg, mob/living/user = usr)
	. = ..()
	if(!.)
		return .
	toggle_action.Remove(borg)
	QDEL_NULL(toggle_action)
	deactivate_sr()

/obj/item/borg/upgrade/selfrepair/ui_action_click()
	if(on)
		to_chat(toggle_action.owner, span_notice("You deactivate the self-repair module."))
		deactivate_sr()
	else
		to_chat(toggle_action.owner, span_notice("You activate the self-repair module."))
		activate_sr()


/obj/item/borg/upgrade/selfrepair/update_icon_state()
	if(toggle_action)
		icon_state = "selfrepair_[on ? "on" : "off"]"
	else
		icon_state = "cyborg_upgrade5"
	return ..()

/obj/item/borg/upgrade/selfrepair/proc/activate_sr()
	START_PROCESSING(SSobj, src)
	on = TRUE
	update_appearance()

/obj/item/borg/upgrade/selfrepair/proc/deactivate_sr()
	STOP_PROCESSING(SSobj, src)
	on = FALSE
	update_appearance()

/obj/item/borg/upgrade/selfrepair/process()
	if(world.time < next_repair)
		return

	var/mob/living/silicon/robot/cyborg = toggle_action.owner

	if(istype(cyborg) && (cyborg.stat != DEAD) && on)
		if(!cyborg.cell)
			to_chat(cyborg, span_alert("Self-repair module deactivated. Please insert power cell."))
			deactivate_sr()
			return

		if(cyborg.cell.charge < energy_cost * 2)
			to_chat(cyborg, span_alert("Self-repair module deactivated. Please recharge."))
			deactivate_sr()
			return

		if(cyborg.health < cyborg.maxHealth)
			if(cyborg.health < 0)
				repair_amount = -2.5
				energy_cost = 0.03 * STANDARD_CELL_CHARGE
			else
				repair_amount = -1
				energy_cost = 0.01 * STANDARD_CELL_CHARGE
			cyborg.adjustBruteLoss(repair_amount)
			cyborg.adjustFireLoss(repair_amount)
			cyborg.updatehealth()
			cyborg.cell.use(energy_cost)
		else
			cyborg.cell.use(0.005 * STANDARD_CELL_CHARGE)
		next_repair = world.time + repair_cooldown * 10 // Multiply by 10 since world.time is in deciseconds

		if(TIMER_COOLDOWN_FINISHED(src, COOLDOWN_BORG_SELF_REPAIR))
			TIMER_COOLDOWN_START(src, COOLDOWN_BORG_SELF_REPAIR, 200 SECONDS)
			var/msgmode = "standby"
			if(cyborg.health < 0)
				msgmode = "critical"
			else if(cyborg.health < cyborg.maxHealth)
				msgmode = "normal"
			to_chat(cyborg, span_notice("Self-repair is active in [span_boldnotice("[msgmode]")] mode."))
	else
		deactivate_sr()

/obj/item/borg/upgrade/hypospray
	name = "medical cyborg hypospray advanced synthesiser"
	desc = "An upgrade to the Medical model cyborg's hypospray, allowing it \
		to produce more advanced and complex medical reagents."
	icon_state = "module_medical"
	require_model = TRUE
	model_type = list(/obj/item/robot_model/medical)
	model_flags = BORG_MODEL_MEDICAL
	var/list/additional_reagents = list()

/obj/item/borg/upgrade/hypospray/action(mob/living/silicon/robot/borg, mob/living/user = usr)
	. = ..()
	if(!.)
		return .
	for(var/obj/item/reagent_containers/borghypo/medical/hypo in borg.model.modules)
		hypo.upgrade_hypo()

/obj/item/borg/upgrade/hypospray/deactivate(mob/living/silicon/robot/borg, mob/living/user = usr)
	. = ..()
	if(!.)
		return .
	for(var/obj/item/reagent_containers/borghypo/medical/hypo in borg.model.modules)
		hypo.remove_hypo_upgrade()

/obj/item/borg/upgrade/hypospray/expanded
	name = "medical cyborg expanded hypospray"
	desc = "An upgrade to the Medical model's hypospray, allowing it \
		to treat a wider range of conditions and problems."

/obj/item/borg/upgrade/piercing_hypospray
	name = "cyborg piercing hypospray"
	desc = "An upgrade to a cyborg's hypospray, allowing it to \
		pierce armor and thick material."
	icon_state = "module_medical"

/obj/item/borg/upgrade/piercing_hypospray/action(mob/living/silicon/robot/borg, mob/living/user = usr)
	. = ..()
	if(!.)
		return .
	var/found_hypo = FALSE
	for(var/obj/item/reagent_containers/borghypo/hypo in borg.model.modules)
		hypo.bypass_protection = TRUE
		found_hypo = TRUE
	for(var/obj/item/reagent_containers/borghypo/hypo in borg.model.emag_modules)
		hypo.bypass_protection = TRUE
		found_hypo = TRUE

	if(!found_hypo)
		to_chat(user, span_warning("There are no installed hypospray modules to upgrade with piercing!")) //check to see if any hyposprays were upgraded
		return FALSE

/obj/item/borg/upgrade/piercing_hypospray/deactivate(mob/living/silicon/robot/borg, mob/living/user = usr)
	. = ..()
	if(!.)
		return .
	for(var/obj/item/reagent_containers/borghypo/hypo in borg.model.modules)
		hypo.bypass_protection = initial(hypo.bypass_protection)
	for(var/obj/item/reagent_containers/borghypo/hypo in borg.model.emag_modules)
		hypo.bypass_protection = initial(hypo.bypass_protection)

/obj/item/borg/upgrade/surgery_omnitool
	name = "cyborg surgical omni-tool upgrade"
	desc = "An upgrade to the Medical model, upgrading the built-in \
		surgical omnitool, to be on par with advanced surgical tools, allowing for faster surgery. \
		It also upgrades their scanner."
	icon_state = "module_medical"
	require_model = TRUE
	model_type = list(/obj/item/robot_model/medical,  /obj/item/robot_model/syndicate_medical)
	model_flags = BORG_MODEL_MEDICAL

	items_to_add = list(/obj/item/healthanalyzer/advanced)
	items_to_remove = list(/obj/item/healthanalyzer)

/obj/item/borg/upgrade/surgery_omnitool/action(mob/living/silicon/robot/cyborg, mob/living/user = usr)
	. = ..()
	if(!.)
		return .
	ADD_TRAIT(cyborg, TRAIT_FASTMED, REF(src))
	for(var/obj/item/borg/cyborg_omnitool/medical/omnitool_upgrade in cyborg.model.modules)
		if(omnitool_upgrade.upgraded)
			to_chat(user, span_warning("This unit is already equipped with an omnitool upgrade!"))
			return FALSE
	for(var/obj/item/borg/cyborg_omnitool/medical/omnitool in cyborg.model.modules)
		omnitool.set_upgraded(TRUE)

/obj/item/borg/upgrade/surgery_omnitool/deactivate(mob/living/silicon/robot/cyborg, mob/living/user = usr)
	. = ..()
	if(!.)
		return .
	REMOVE_TRAIT(cyborg, TRAIT_FASTMED, REF(src))
	for(var/obj/item/borg/cyborg_omnitool/omnitool in cyborg.model.modules)
		omnitool.set_upgraded(FALSE)

/obj/item/borg/upgrade/engineering_omnitool
	name = "cyborg engineering omni-tool upgrade"
	desc = "An upgrade to the Engineering model, upgrading the built-in \
		engineering omnitool, to be on par with advanced engineering tools"
	icon_state = "module_engineer"
	require_model = TRUE
	model_type = list(/obj/item/robot_model/engineering,  /obj/item/robot_model/saboteur)
	model_flags = BORG_MODEL_ENGINEERING

/obj/item/borg/upgrade/engineering_omnitool/action(mob/living/silicon/robot/cyborg, mob/living/user = usr)
	. = ..()
	if(!.)
		return .
	for(var/obj/item/borg/cyborg_omnitool/engineering/omnitool_upgrade in cyborg.model.modules)
		if(omnitool_upgrade.upgraded)
			to_chat(user, span_warning("This unit is already equipped with an omnitool upgrade!"))
			return FALSE
	for(var/obj/item/borg/cyborg_omnitool/engineering/omnitool in cyborg.model.modules)
		omnitool.set_upgraded(TRUE)

/obj/item/borg/upgrade/engineering_omnitool/deactivate(mob/living/silicon/robot/cyborg, mob/living/user = usr)
	. = ..()
	if(!.)
		return .
	for(var/obj/item/borg/cyborg_omnitool/omnitool in cyborg.model.modules)
		omnitool.set_upgraded(FALSE)

/obj/item/borg/upgrade/defib
	name = "medical cyborg defibrillator"
	desc = "An upgrade to the Medical model, installing a built-in \
		defibrillator, for on the scene revival."
	icon_state = "module_medical"
	require_model = TRUE
	model_type = list(/obj/item/robot_model/medical)
	model_flags = BORG_MODEL_MEDICAL

	items_to_add = list(/obj/item/shockpaddles/cyborg)

/obj/item/borg/upgrade/defib/action(mob/living/silicon/robot/borg, mob/living/user = usr)
	. = ..()
	if(!.)
		return .
	var/obj/item/borg/upgrade/defib/backpack/defib_pack = locate() in borg //If a full defib unit was used to upgrade prior, we can just pop it out now and replace
	if(defib_pack)
		defib_pack.deactivate(borg, user)
		to_chat(user, span_notice("The defibrillator pops out of the chassis as the compact upgrade installs."))

///A version of the above that also acts as a holder of an actual defibrillator item used in place of the upgrade chip.
/obj/item/borg/upgrade/defib/backpack
	var/obj/item/defibrillator/defib_instance

/obj/item/borg/upgrade/defib/backpack/Initialize(mapload, obj/item/defibrillator/defib)
	. = ..()
	if(isnull(defib))
		defib = new /obj/item/defibrillator
	defib_instance = defib
	name = defib_instance.name
	defib_instance.moveToNullspace()
	RegisterSignals(defib_instance, list(COMSIG_QDELETING, COMSIG_MOVABLE_MOVED), PROC_REF(on_defib_instance_qdel_or_moved))

/obj/item/borg/upgrade/defib/backpack/proc/on_defib_instance_qdel_or_moved(obj/item/defibrillator/defib)
	SIGNAL_HANDLER
	defib_instance = null
	if(!QDELETED(src))
		qdel(src)

/obj/item/borg/upgrade/defib/backpack/Destroy()
	if(!QDELETED(defib_instance))
		QDEL_NULL(defib_instance)
	return ..()

/obj/item/borg/upgrade/defib/backpack/deactivate(mob/living/silicon/robot/borg, mob/living/user = usr)
	. = ..()
	if(!.)
		return .
	defib_instance?.forceMove(borg.drop_location()) // [on_defib_instance_qdel_or_moved()] handles the rest.

/obj/item/borg/upgrade/processor
	name = "medical cyborg surgical processor"
	desc = "An upgrade to the Medical model, installing a processor \
		capable of scanning surgery disks and carrying \
		out procedures"
	icon_state = "module_medical"
	require_model = TRUE
	model_type = list(/obj/item/robot_model/medical, /obj/item/robot_model/syndicate_medical)
	model_flags = BORG_MODEL_MEDICAL

	items_to_add = list(/obj/item/surgical_processor)

/obj/item/borg/upgrade/ai
	name = "B.O.R.I.S. module"
	desc = "Bluespace Optimized Remote Intelligence Synchronization. An uplink device which takes the place of an MMI in cyborg endoskeletons, creating a robotic shell controlled by an AI."
	icon = 'icons/obj/devices/circuitry_n_data.dmi'
	icon_state = "boris"

/obj/item/borg/upgrade/ai/action(mob/living/silicon/robot/borg, mob/living/user = usr)
	. = ..()
	if(!.)
		return .
	if(borg.key) //You cannot replace a player unless the key is completely removed.
		to_chat(user, span_warning("Intelligence patterns detected in this [borg.braintype]. Aborting."))
		return FALSE

	borg.make_shell(src)

/obj/item/borg/upgrade/ai/deactivate(mob/living/silicon/robot/borg, mob/living/user = usr)
	. = ..()
	if(!. || !borg.shell)
		return .

	borg.undeploy()
	borg.notify_ai(AI_NOTIFICATION_AI_SHELL)

/obj/item/borg/upgrade/expand
	name = "borg expander"
	desc = "A cyborg resizer, it makes a cyborg huge."
	icon_state = "module_general"

/obj/item/borg/upgrade/expand/action(mob/living/silicon/robot/borg, mob/living/user = usr)
	. = ..()
	if(!. || HAS_TRAIT(borg, TRAIT_NO_TRANSFORM))
		return FALSE

	if(borg.hasExpanded)
		to_chat(usr, span_warning("This unit already has an expand module installed!"))
		return FALSE

	ADD_TRAIT(borg, TRAIT_NO_TRANSFORM, REF(src))
	var/prev_lockcharge = borg.lockcharge
	borg.SetLockdown(TRUE)
	borg.set_anchored(TRUE)
	var/datum/effect_system/fluid_spread/smoke/smoke = new
	smoke.set_up(1, holder = borg, location = borg.loc)
	smoke.start()
	sleep(0.2 SECONDS)
	for(var/i in 1 to 4)
		playsound(borg, pick(
			'sound/items/tools/drill_use.ogg',
			'sound/items/tools/jaws_cut.ogg',
			'sound/items/tools/jaws_pry.ogg',
			'sound/items/tools/welder.ogg',
			'sound/items/tools/ratchet.ogg',
			), 80, TRUE, -1)
		sleep(1.2 SECONDS)
	if(!prev_lockcharge)
		borg.SetLockdown(FALSE)
	borg.set_anchored(FALSE)
	REMOVE_TRAIT(borg, TRAIT_NO_TRANSFORM, REF(src))
	borg.hasExpanded = TRUE
	borg.update_transform(2)

/obj/item/borg/upgrade/expand/deactivate(mob/living/silicon/robot/borg, mob/living/user = usr)
	. = ..()
	if(!.)
		return .
	if (borg.hasExpanded)
		borg.hasExpanded = FALSE
		borg.update_transform(0.5)

/obj/item/borg/upgrade/rped
	name = "engineering cyborg RPED"
	desc = "A rapid part exchange device for the engineering cyborg."
	icon_state = "module_engineer"
	require_model = TRUE
	model_type = list(/obj/item/robot_model/engineering, /obj/item/robot_model/saboteur)
	model_flags = BORG_MODEL_ENGINEERING

	items_to_add = list(/obj/item/storage/part_replacer/cyborg)

/obj/item/borg/upgrade/inducer
	name = "engineering integrated power inducer"
	desc = "An integrated inducer that can charge a device's internal cell from power provided by the cyborg."
	icon_state = "module_engineer"
	require_model = TRUE
	model_type = list(/obj/item/robot_model/engineering, /obj/item/robot_model/saboteur)
	model_flags = BORG_MODEL_ENGINEERING
	items_to_add = list(/obj/item/inducer/cyborg)

/obj/item/borg/upgrade/pinpointer
	name = "medical cyborg crew pinpointer"
	desc = "A crew pinpointer module for the medical cyborg. Permits remote access to the crew monitor."
	icon_state = "module_medical"
	require_model = TRUE
	model_type = list(/obj/item/robot_model/medical, /obj/item/robot_model/syndicate_medical)
	model_flags = BORG_MODEL_MEDICAL

	items_to_add = list(/obj/item/pinpointer/crew)
	var/datum/action/crew_monitor

/obj/item/borg/upgrade/pinpointer/action(mob/living/silicon/robot/borg, mob/living/user = usr)
	. = ..()
	if(!.)
		return .
	crew_monitor = new /datum/action/item_action/crew_monitor(src)
	crew_monitor.Grant(borg)
	icon_state = "scanner"


/obj/item/borg/upgrade/pinpointer/deactivate(mob/living/silicon/robot/borg, mob/living/user = usr)
	. = ..()
	if(!.)
		return .
	icon_state = "pinpointer_crew"
	crew_monitor.Remove(borg)
	QDEL_NULL(crew_monitor)

/obj/item/borg/upgrade/pinpointer/ui_action_click()
	if(..())
		return
	var/mob/living/silicon/robot/borg = usr
	GLOB.crewmonitor.show(borg,borg)

/datum/action/item_action/crew_monitor
	name = "Interface With Crew Monitor"

/obj/item/borg/upgrade/transform
	name = "borg model picker (Standard)"
	desc = "Allows you to turn a cyborg into a standard cyborg."
	icon_state = "module_general"
	var/obj/item/robot_model/new_model = null

/obj/item/borg/upgrade/transform/action(mob/living/silicon/robot/borg, mob/living/user = usr)
	. = ..()
	if(. && new_model)
		borg.model.transform_to(new_model)

/obj/item/borg/upgrade/transform/clown
	name = "borg model picker (Clown)"
	desc = "Allows you to turn a cyborg into a clown, honk."
	icon_state = "module_honk"
	new_model = /obj/item/robot_model/clown

/obj/item/borg/upgrade/circuit_app
	name = "circuit manipulation apparatus"
	desc = "An engineering cyborg upgrade allowing for manipulation of circuit boards."
	icon_state = "module_engineer"
	require_model = TRUE
	model_type = list(/obj/item/robot_model/engineering, /obj/item/robot_model/saboteur)
	model_flags = BORG_MODEL_ENGINEERING

	items_to_add = list(/obj/item/borg/apparatus/circuit)

/obj/item/borg/upgrade/beaker_app
	name = "beaker storage apparatus"
	desc = "A supplementary beaker storage apparatus for medical cyborgs."
	icon_state = "module_medical"
	require_model = TRUE
	model_type = list(/obj/item/robot_model/medical)
	model_flags = BORG_MODEL_MEDICAL

	items_to_add = list(/obj/item/borg/apparatus/beaker/extra)

/obj/item/borg/upgrade/drink_app
	name = "glass storage apparatus"
	desc = "A supplementary drinking glass storage apparatus for service cyborgs."
	icon_state = "module_service"
	require_model = TRUE
	model_type = list(/obj/item/robot_model/service)
	model_flags = BORG_MODEL_SERVICE

	items_to_add = list(/obj/item/borg/apparatus/beaker/drink)

/obj/item/borg/upgrade/broomer
	name = "experimental push broom"
	desc = "An experimental push broom used for efficiently pushing refuse."
	icon_state = "module_janitor"
	require_model = TRUE
	model_type = list(/obj/item/robot_model/janitor)
	model_flags = BORG_MODEL_JANITOR

	items_to_add = list(/obj/item/pushbroom/cyborg)

/obj/item/borg/upgrade/condiment_synthesizer
	name = "Service Cyborg Condiment Synthesiser"
	desc = "An upgrade to the service model cyborg, allowing it to produce solid condiments."
	icon_state = "module_service"
	require_model = TRUE
	model_type = list(/obj/item/robot_model/service)
	model_flags = BORG_MODEL_SERVICE

	items_to_add = list(/obj/item/reagent_containers/borghypo/condiment_synthesizer)

/obj/item/borg/upgrade/silicon_knife
	name = "Service Cyborg Kitchen Toolset"
	desc = "An upgrade to the service model cyborg, to help process foods."
	icon_state = "module_service"
	require_model = TRUE
	model_type = list(/obj/item/robot_model/service)
	model_flags = BORG_MODEL_SERVICE

	items_to_add = list(/obj/item/knife/kitchen/silicon)

/obj/item/borg/upgrade/service_apparatus
	name = "Service Cyborg Service Apparatus"
	desc = "An upgrade to the service model cyborg, to help handle foods and paper."
	icon_state = "module_service"
	require_model = TRUE
	model_type = list(/obj/item/robot_model/service)
	model_flags = BORG_MODEL_SERVICE

	items_to_add = list(/obj/item/borg/apparatus/service)

/obj/item/borg/upgrade/rolling_table
	name = "Service Cyborg Rolling Table Dock"
	desc = "An upgrade to the service model cyborg, to help provide mobile service."
	icon_state = "module_service"
	require_model = TRUE
	model_type = list(/obj/item/robot_model/service)
	model_flags = BORG_MODEL_SERVICE

	items_to_add = list(/obj/item/rolling_table_dock)

/obj/item/borg/upgrade/service_cookbook
	name = "Service Cyborg Cookbook"
	desc = "An upgrade to the service model cyborg, that lets them create more foods."
	icon_state = "module_service"
	require_model = TRUE
	model_type = list(/obj/item/robot_model/service)
	model_flags = BORG_MODEL_SERVICE

	items_to_add = list(/obj/item/borg/cookbook)

/obj/item/borg/upgrade/botany_upgrade
	name = "Service Cyborg Botany Tools"
	desc = "An upgrade to the service model cyborg, that let them do gardening and plant processing."
	icon_state = "module_service"
	require_model = TRUE
	model_type = list(/obj/item/robot_model/service)
	model_flags = BORG_MODEL_SERVICE

	items_to_add = list(/obj/item/storage/bag/plants/cyborg, /obj/item/borg/cyborg_omnitool/botany, /obj/item/plant_analyzer)

/obj/item/borg/upgrade/shuttle_blueprints
	name = "Engineering Cyborg Shuttle Blueprint Database"
	desc = "An upgrade to the engineering model cyborg allowing for the construction and expansion of shuttles."
	icon_state = "module_engineer"
	require_model = TRUE
	model_type = list(/obj/item/robot_model/engineering, /obj/item/robot_model/saboteur)
	model_flags = BORG_MODEL_ENGINEERING

	items_to_add = list(/obj/item/shuttle_blueprints/borg)


///This isn't an upgrade or part of the same path, but I'm gonna just stick it here because it's a tool used on cyborgs.
//A reusable tool that can bring borgs back to life. They gotta be repaired first, though.
/obj/item/borg_restart_board
	name = "cyborg emergency reboot module"
	desc = "A reusable firmware reset tool that can force a reboot of a disabled-but-repaired cyborg, bringing it back online."
	w_class = WEIGHT_CLASS_SMALL
	icon = 'icons/obj/devices/circuitry_n_data.dmi'
	icon_state = "cyborg_upgrade1"

/obj/item/borg_restart_board/pre_attack(mob/living/silicon/robot/borgo, mob/living/user, params)
	if(!istype(borgo))
		return ..()
	if(!borgo.opened)
		to_chat(user, span_warning("You must access the cyborg's internals!"))
		return ..()
	if(borgo.health < 0)
		to_chat(user, span_warning("You have to repair the cyborg before using this module!"))
		return ..()
	if(!(borgo.stat & DEAD))
		to_chat(user, span_warning("This cyborg is already operational!"))
		return ..()

	if(borgo.mind)
		borgo.mind.grab_ghost()
		playsound(loc, 'sound/mobs/non-humanoids/cyborg/liveagain.ogg', 75, TRUE)
	else
		playsound(loc, 'sound/machines/ping.ogg', 75, TRUE)

	borgo.revive()
	borgo.logevent("WARN -- System recovered from unexpected shutdown.")
	borgo.logevent("System brought online.")
	return ..()
