/*

Miscellaneous traitor devices

BATTERER

RADIOACTIVE MICROLASER

*/

/*

The Batterer, like a flashbang but 50% chance to knock people over. Can be either very
effective or pretty fucking useless.

*/

/obj/item/batterer
	name = "mind batterer"
	desc = "A strange device with twin antennas."
	icon = 'icons/obj/devices/syndie_gadget.dmi'
	icon_state = "batterer"
	throwforce = 5
	w_class = WEIGHT_CLASS_TINY
	throw_speed = 3
	throw_range = 7
	obj_flags = CONDUCTS_ELECTRICITY
	inhand_icon_state = "electronic"
	lefthand_file = 'icons/mob/inhands/items/devices_lefthand.dmi'
	righthand_file = 'icons/mob/inhands/items/devices_righthand.dmi'

	var/times_used = 0 //Number of times it's been used.
	var/max_uses = 2


/obj/item/batterer/attack_self(mob/living/carbon/user, flag = 0, emp = 0)
	if(!user) return

	if(times_used >= max_uses)
		to_chat(user, span_danger("The mind batterer has been burnt out!"))
		return

	log_combat(user, null, "knocked down people in the area", src)

	for(var/mob/living/carbon/human/M in urange(10, user, 1))
		if(prob(50))

			M.Paralyze(rand(200,400))
			to_chat(M, span_userdanger("You feel a tremendous, paralyzing wave flood your mind."))

		else
			to_chat(M, span_userdanger("You feel a sudden, electric jolt travel through your head."))

	playsound(src.loc, 'sound/misc/interference.ogg', 50, TRUE)
	to_chat(user, span_notice("You trigger [src]."))
	times_used += 1
	if(times_used >= max_uses)
		icon_state = "battererburnt"

/*
		The radioactive microlaser, a device disguised as a health analyzer used to irradiate people.

		The strength of the radiation is determined by the 'intensity' setting, while the delay between
	the scan and the irradiation kicking in is determined by the wavelength.

		Each scan will cause the microlaser to have a brief cooldown period. Higher intensity will increase
	the cooldown, while higher wavelength will decrease it.

		Wavelength is also slightly increased by the intensity as well.
*/

/obj/item/healthanalyzer/rad_laser
	var/irradiate = TRUE
	var/stealth = FALSE
	var/used = FALSE // is it cooling down?
	var/intensity = 10 // how much damage the radiation does
	var/wavelength = 10 // time it takes for the radiation to kick in, in seconds

/obj/item/healthanalyzer/rad_laser/interact_with_atom(atom/interacting_with, mob/living/user, list/modifiers)
	if(!stealth || !irradiate)
		. = ..()

	if(!ishuman(interacting_with) || !irradiate)
		return .

	var/mob/living/carbon/human/human_target = interacting_with
	if(istype(human_target) && !used && SSradiation.wearing_rad_protected_clothing(human_target)) //intentionally not checking for TRAIT_RADIMMUNE here so that tatortot can still fuck up and waste their cooldown.
		to_chat(user, span_warning("[interacting_with]'s clothing is fully protecting [interacting_with.p_them()] from irradiation!"))
		return . | ITEM_INTERACT_BLOCKING

	if(!used)
		log_combat(user, interacting_with, "irradiated", src)
		var/cooldown = get_cooldown()
		used = TRUE
		icon_state = "health1"
		addtimer(VARSET_CALLBACK(src, used, FALSE), cooldown)
		addtimer(VARSET_CALLBACK(src, icon_state, "health"), cooldown)
		to_chat(user, span_warning("Successfully irradiated [interacting_with]."))
		addtimer(CALLBACK(src, PROC_REF(radiation_aftereffect), interacting_with, intensity), (wavelength+(intensity*4))*5)
		return . | ITEM_INTERACT_SUCCESS

	to_chat(user, span_warning("The radioactive microlaser is still recharging."))
	return . | ITEM_INTERACT_BLOCKING

/obj/item/healthanalyzer/rad_laser/proc/radiation_aftereffect(mob/living/M, passed_intensity)
	if(QDELETED(M) || !ishuman(M) || HAS_TRAIT(M, TRAIT_RADIMMUNE))
		return

	if(passed_intensity >= 5)
		M.apply_effect(round(passed_intensity/0.075), EFFECT_UNCONSCIOUS) //to save you some math, this is a round(intensity * (4/3)) second long knockout

/obj/item/healthanalyzer/rad_laser/proc/get_cooldown()
	return round(max(10, (stealth*30 + intensity*5 - wavelength/4)))

/obj/item/healthanalyzer/rad_laser/attack_self(mob/user)
	interact(user)

/obj/item/healthanalyzer/rad_laser/interact(mob/user)
	ui_interact(user)

/obj/item/healthanalyzer/rad_laser/ui_state(mob/user)
	return GLOB.hands_state

/obj/item/healthanalyzer/rad_laser/ui_interact(mob/user, datum/tgui/ui)
	ui = SStgui.try_update_ui(user, src, ui)
	if(!ui)
		ui = new(user, src, "RadioactiveMicrolaser")
		ui.open()

/obj/item/healthanalyzer/rad_laser/ui_data(mob/user)
	var/list/data = list()
	data["irradiate"] = irradiate
	data["stealth"] = stealth
	data["scanmode"] = scanmode
	data["intensity"] = intensity
	data["wavelength"] = wavelength
	data["on_cooldown"] = used
	data["cooldown"] = DisplayTimeText(get_cooldown())
	return data

/obj/item/healthanalyzer/rad_laser/ui_act(action, list/params, datum/tgui/ui, datum/ui_state/state)
	. = ..()
	if(.)
		return

	switch(action)
		if("irradiate")
			irradiate = !irradiate
			. = TRUE

		if("stealth")
			stealth = !stealth
			. = TRUE

		if("scanmode")
			scanmode = !scanmode
			. = TRUE

		if("radintensity")
			var/target = params["target"]
			var/adjust = text2num(params["adjust"])
			if(target == "min")
				target = 1
				. = TRUE

			else if(target == "max")
				target = 20
				. = TRUE

			else if(adjust)
				target = intensity + adjust
				. = TRUE

			else if(text2num(target) != null)
				target = text2num(target)
				. = TRUE

			if(.)
				target = round(target)
				intensity = clamp(target, 1, 20)

		if("radwavelength")
			var/target = params["target"]
			var/adjust = text2num(params["adjust"])
			if(target == "min")
				target = 0
				. = TRUE

			else if(target == "max")
				target = 120
				. = TRUE

			else if(adjust)
				target = wavelength + adjust
				. = TRUE

			else if(text2num(target) != null)
				target = text2num(target)
				. = TRUE

			if(.)
				target = round(target)
				wavelength = clamp(target, 0, 120)

/datum/action/item_action/stealth_mode
	name = "Toggle Stealth"
	desc = "Makes you invisible to the naked eye."
	button_icon = 'icons/mob/actions/actions_minor_antag.dmi'
	button_icon_state = "ninja_cloak"
	/// Whether stealth is active or not
	var/stealth_engaged = FALSE
	/// The amount of time the stealth mode can be active for, drains to 0 when active
	var/charge = 30 SECONDS
	/// The maximum amount of time the stealth mode can be active for
	var/max_charge = 30 SECONDS
	/// The minimum alpha value for the stealth mode
	var/min_alpha = 0
	/// Whether the stealth mode recharges while active
	/// if TRUE standing in darkness will recharge even while active
	/// if FALSE it will not uncharge, but not recharge while in darkness
	var/recharge_while_active = TRUE

/datum/action/item_action/stealth_mode/is_action_active(atom/movable/screen/movable/action_button/current_button)
	return stealth_engaged

/datum/action/item_action/stealth_mode/Grant(mob/grant_to)
	. = ..()
	START_PROCESSING(SSobj, src)
	build_all_button_icons(UPDATE_BUTTON_STATUS)

/datum/action/item_action/stealth_mode/Remove(mob/remove_from)
	if(!isnull(owner) && stealth_engaged)
		stealth_off()
	STOP_PROCESSING(SSobj, src)
	return ..()

/datum/action/item_action/stealth_mode/Trigger(trigger_flags)
	. = ..()
	if(!.)
		return

	if(stealth_engaged)
		stealth_off()
	else
		stealth_on()

/datum/action/item_action/stealth_mode/proc/stealth_on()
	animate(owner, alpha = get_alpha(), time = 0.5 SECONDS)
	apply_wibbly_filters(owner)
	stealth_engaged = TRUE
	build_all_button_icons(UPDATE_BUTTON_STATUS|UPDATE_BUTTON_BACKGROUND)
	owner.balloon_alert(owner, "stealth mode engaged")

/datum/action/item_action/stealth_mode/proc/stealth_off()
	owner.alpha = initial(owner.alpha)
	remove_wibbly_filters(owner)
	stealth_engaged = FALSE
	build_all_button_icons(UPDATE_BUTTON_STATUS|UPDATE_BUTTON_BACKGROUND)
	owner.balloon_alert(owner, "stealth mode disengaged")

/datum/action/item_action/stealth_mode/proc/get_alpha()
	return clamp(255 - (255 * charge / max_charge), min_alpha, 255)

/datum/action/item_action/stealth_mode/process(seconds_per_tick)
	if(!stealth_engaged)
		// Recharge over time
		charge = min(max_charge, charge + (max_charge * 0.04) * seconds_per_tick)
		build_all_button_icons(UPDATE_BUTTON_STATUS)
		return

	if(charge <= 0)
		stealth_off()
		return

	var/turf/our_turf = get_turf(owner)
	var/lumcount = our_turf?.get_lumcount() || 0
	if(lumcount > 0.3)
		// Decay charge while invisible+ in the light
		charge = max(0, charge - (max_charge * 0.05) * seconds_per_tick)
		build_all_button_icons(UPDATE_BUTTON_STATUS)

	else if(recharge_while_active)
		// Return charage while invisible + in the darkness + recharge_while_active
		charge = min(max_charge, charge + (max_charge * 0.1) * seconds_per_tick)
		build_all_button_icons(UPDATE_BUTTON_STATUS)

	animate(owner, alpha = get_alpha(), time = 1 SECONDS, flags = ANIMATION_PARALLEL)

/datum/action/item_action/stealth_mode/update_button_status(atom/movable/screen/movable/action_button/current_button, force)
	. = ..()
	current_button.maptext_x = 9
	current_button.maptext = MAPTEXT_TINY_UNICODE("[round(charge / max_charge * 100, 0.01)]%")

/datum/action/item_action/stealth_mode/weaker
	charge = 15 SECONDS
	max_charge = 15 SECONDS
	min_alpha = 20
	recharge_while_active = FALSE

/obj/item/shadowcloak
	name = "cloaker belt"
	desc = "Makes you invisible for short periods of time. Recharges in darkness, even while active."
	icon = 'icons/obj/clothing/belts.dmi'
	icon_state = "utility"
	inhand_icon_state = "utility"
	lefthand_file = 'icons/mob/inhands/equipment/belt_lefthand.dmi'
	righthand_file = 'icons/mob/inhands/equipment/belt_righthand.dmi'
	worn_icon_state = "utility"
	slot_flags = ITEM_SLOT_BELT
	attack_verb_continuous = list("whips", "lashes", "disciplines")
	attack_verb_simple = list("whip", "lash", "discipline")
	actions_types = list(/datum/action/item_action/stealth_mode)

/obj/item/shadowcloak/item_action_slot_check(slot, mob/user)
	return slot & slot_flags

/obj/item/shadowcloak/weaker
	name = "stealth belt"
	desc = "Makes you nigh-invisible to the naked eye for a short period of time. \
		Lasts indefinitely in darkness, but will not recharge unless inactive."
	actions_types = list(/datum/action/item_action/stealth_mode/weaker)

/// Checks if a given atom is in range of a radio jammer, returns TRUE if it is.
/proc/is_within_radio_jammer_range(atom/source)
	for(var/obj/item/jammer/jammer as anything in GLOB.active_jammers)
		if(IN_GIVEN_RANGE(source, jammer, jammer.range))
			return TRUE
	return FALSE

/obj/item/jammer
	name = "radio jammer"
	desc = "Device used to disrupt nearby radio communication. Alternate function creates a powerful disruptor wave which disables all nearby listening devices."
	icon = 'icons/obj/devices/syndie_gadget.dmi'
	icon_state = "jammer"
	var/active = FALSE
	var/range = 12
	var/jam_cooldown_duration = 15 SECONDS
	COOLDOWN_DECLARE(jam_cooldown)

/obj/item/jammer/Initialize(mapload)
	. = ..()
	register_context()

/obj/item/jammer/add_context(atom/source, list/context, obj/item/held_item, mob/user)
	context[SCREENTIP_CONTEXT_LMB] = "Release disruptor wave"
	context[SCREENTIP_CONTEXT_RMB] = "Toggle"
	return CONTEXTUAL_SCREENTIP_SET

/obj/item/jammer/attack_self(mob/user, modifiers)
	. = ..()
	if (!COOLDOWN_FINISHED(src, jam_cooldown))
		user.balloon_alert(user, "on cooldown!")
		return

	user.balloon_alert(user, "disruptor wave released!")
	to_chat(user, span_notice("You release a disruptor wave, disabling all nearby radio devices."))
	for (var/atom/potential_owner in view(7, user))
		disable_radios_on(potential_owner, ignore_syndie = TRUE)
	COOLDOWN_START(src, jam_cooldown, jam_cooldown_duration)

/obj/item/jammer/attack_self_secondary(mob/user, modifiers)
	. = ..()
	if(.)
		return
	to_chat(user, span_notice("You [active ? "deactivate" : "activate"] [src]."))
	user.balloon_alert(user, "[active ? "deactivated" : "activated"] the jammer")
	active = !active
	if(active)
		GLOB.active_jammers |= src
	else
		GLOB.active_jammers -= src
	update_appearance()
	return SECONDARY_ATTACK_CANCEL_ATTACK_CHAIN

/obj/item/jammer/interact_with_atom(atom/interacting_with, mob/living/user, list/modifiers)
	. = ..()

	if(. & ITEM_INTERACT_ANY_BLOCKER)
		return

	if (!(interacting_with in view(7, user)))
		user.balloon_alert(user, "out of reach!")
		return

	interacting_with.balloon_alert(user, "radio disrupted!")
	to_chat(user, span_notice("You release a directed disruptor wave, disabling all radio devices on [interacting_with]."))
	disable_radios_on(interacting_with)

	return ITEM_INTERACT_SUCCESS

/obj/item/jammer/proc/disable_radios_on(atom/target, ignore_syndie = FALSE)
	for (var/obj/item/radio/radio in target.get_all_contents() + target)
		if(ignore_syndie && (radio.special_channels & RADIO_SPECIAL_SYNDIE))
			continue
		radio.set_broadcasting(FALSE)

/obj/item/jammer/Destroy()
	GLOB.active_jammers -= src
	return ..()

/obj/item/storage/toolbox/emergency/turret
	desc = "You feel a strange urge to hit this with a wrench."

/obj/item/storage/toolbox/emergency/turret/PopulateContents()
	new /obj/item/screwdriver(src)
	new /obj/item/wrench/combat(src)
	new /obj/item/weldingtool(src)
	new /obj/item/crowbar(src)
	new /obj/item/analyzer(src)
	new /obj/item/wirecutters(src)

/obj/item/storage/toolbox/emergency/turret/item_interaction(mob/living/user, obj/item/tool, list/modifiers)
	if(!istype(tool, /obj/item/wrench/combat))
		return NONE
	if(!user.combat_mode)
		return NONE
	if(!tool.toolspeed)
		return ITEM_INTERACT_BLOCKING
	balloon_alert(user, "constructing...")
	if(!tool.use_tool(src, user, 2 SECONDS, volume = 20))
		return ITEM_INTERACT_BLOCKING

	balloon_alert(user, "constructed!")
	user.visible_message(
		span_danger("[user] bashes [src] with [tool]!"),
		span_danger("You bash [src] with [tool]!"),
		null,
		COMBAT_MESSAGE_RANGE,
	)

	playsound(src, 'sound/items/tools/drill_use.ogg', 80, TRUE, -1)
	var/obj/machinery/porta_turret/syndicate/toolbox/turret = new(get_turf(loc))
	set_faction(turret, user)
	turret.toolbox = src
	forceMove(turret)
	return ITEM_INTERACT_SUCCESS


/obj/item/storage/toolbox/emergency/turret/proc/set_faction(obj/machinery/porta_turret/turret, mob/user)
	turret.faction = list("[REF(user)]")

/obj/item/storage/toolbox/emergency/turret/nukie/set_faction(obj/machinery/porta_turret/turret, mob/user)
	turret.faction = list(ROLE_SYNDICATE)

/obj/machinery/porta_turret/syndicate/toolbox
	icon_state = "toolbox_off"
	base_icon_state = "toolbox"

/obj/machinery/porta_turret/syndicate/toolbox/Initialize(mapload)
	. = ..()
	underlays += image(icon = icon, icon_state = "[base_icon_state]_frame")

/obj/machinery/porta_turret/syndicate/toolbox
	integrity_failure = 0
	max_integrity = 100
	shot_delay = 0.5 SECONDS
	stun_projectile = /obj/projectile/bullet/toolbox_turret
	lethal_projectile = /obj/projectile/bullet/toolbox_turret
	subsystem_type = /datum/controller/subsystem/processing/projectiles
	ignore_faction = TRUE
	/// The toolbox we store.
	var/obj/item/toolbox

/obj/machinery/porta_turret/syndicate/toolbox/examine(mob/user)
	. = ..()
	if(faction_check(faction, user.faction))
		. += span_notice("You can repair it by <b>left-clicking</b> with a combat wrench.")
		. += span_notice("You can fold it by <b>right-clicking</b> with a combat wrench.")

/obj/machinery/porta_turret/syndicate/toolbox/target(atom/movable/target)
	if(!target)
		return

	if(shootAt(target))
		setDir(get_dir(base, target))

	return TRUE

/obj/machinery/porta_turret/syndicate/toolbox/attackby(obj/item/attacking_item, mob/living/user, params)
	if(!istype(attacking_item, /obj/item/wrench/combat))
		return ..()

	if(!attacking_item.toolspeed)
		return

	if(user.combat_mode)
		balloon_alert(user, "deconstructing...")
		if(!attacking_item.use_tool(src, user, 5 SECONDS, volume = 20))
			return

		deconstruct(TRUE)
		attacking_item.play_tool_sound(src, 50)
		balloon_alert(user, "deconstructed!")

	else
		if(atom_integrity == max_integrity)
			balloon_alert(user, "already repaired!")
			return

		balloon_alert(user, "repairing...")
		while(atom_integrity != max_integrity)
			if(!attacking_item.use_tool(src, user, 2 SECONDS, volume = 20))
				return

			repair_damage(10)

		balloon_alert(user, "repaired!")

/obj/machinery/porta_turret/syndicate/toolbox/on_deconstruction(disassembled)
	if(disassembled)
		var/atom/movable/old_toolbox = toolbox
		toolbox = null
		old_toolbox.forceMove(drop_location())

	else
		new /obj/effect/gibspawner/robot(drop_location())

	return ..()

/obj/machinery/porta_turret/syndicate/toolbox/Destroy()
	toolbox = null
	return ..()

/obj/machinery/porta_turret/syndicate/toolbox/Exited(atom/movable/gone, direction)
	. = ..()
	if(gone == toolbox)
		toolbox = null
		qdel(src)

/obj/machinery/porta_turret/syndicate/toolbox/ui_status(mob/user, datum/ui_state/state)
	if(faction_check(user.faction, faction))
		return ..()

	return UI_CLOSE

/obj/projectile/bullet/toolbox_turret
	damage = 10
	speed = 1.6
