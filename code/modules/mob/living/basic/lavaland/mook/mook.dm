//Fragile but highly aggressive wanderers that pose a large threat in numbers.
//They'll attempt to leap at their target from afar using their hatchets.
/mob/living/basic/mining/mook
	name = "wanderer"
	desc = "This unhealthy looking primitive seems to be talented at administering health care."
	icon = 'icons/mob/simple/jungle/mook.dmi'
	icon_state = "mook"
	icon_living = "mook"
	icon_dead = "mook_dead"
	mob_biotypes = MOB_ORGANIC|MOB_HUMANOID
	gender = FEMALE
	maxHealth = 150
	faction = list(FACTION_MINING, FACTION_NEUTRAL)
	health = 150
	move_resist = MOVE_FORCE_VERY_STRONG
	melee_damage_lower = 8
	melee_damage_upper = 8
	attack_sound = 'sound/items/weapons/rapierhit.ogg'
	attack_vis_effect = ATTACK_EFFECT_SLASH
	death_sound = 'sound/mobs/non-humanoids/mook/mook_death.ogg'
	ai_controller = /datum/ai_controller/basic_controller/mook/support
	speed = 5
	pixel_x = -16
	base_pixel_x = -16
	pixel_y = -16
	base_pixel_y = -16

	///the state of combat we are in
	var/attack_state = MOOK_ATTACK_NEUTRAL
	///are we a healer?
	var/is_healer = TRUE
	///the ore we are holding if any
	var/obj/held_ore
	///overlay for neutral stance
	var/mutable_appearance/neutral_stance
	///overlay for attacking stance
	var/mutable_appearance/attack_stance
	///overlay when we hold an ore
	var/mutable_appearance/ore_overlay
	///commands we obey
	var/list/pet_commands = list(
		/datum/pet_command/idle,
		/datum/pet_command/free,
		/datum/pet_command/attack,
		/datum/pet_command/fetch,
	)

/mob/living/basic/mining/mook/Initialize(mapload)
	. = ..()
	AddElement(\
		/datum/element/change_force_on_death,\
		move_resist = MOVE_RESIST_DEFAULT,\
	)
	AddComponent(/datum/component/ai_retaliate_advanced, CALLBACK(src, PROC_REF(attack_intruder)))
	grant_actions_by_list(get_innate_abilities())

	ore_overlay = mutable_appearance(icon, "mook_ore_overlay")

	AddComponent(/datum/component/ai_listen_to_weather)
	AddElement(/datum/element/wall_tearer, allow_reinforced = FALSE)
	RegisterSignal(src, COMSIG_KB_MOB_DROPITEM_DOWN, PROC_REF(drop_ore))

	if(is_healer)
		grant_healer_abilities()

	AddComponent(/datum/component/obeys_commands, pet_commands)

/// Returns a list of actions and blackboard keys to pass into `grant_actions_by_list`.
/mob/living/basic/mining/mook/proc/get_innate_abilities()
	var/static/list/innate_abilities = list(
		/datum/action/cooldown/mob_cooldown/mook_ability/mook_jump = BB_MOOK_JUMP_ABILITY,
	)
	return innate_abilities

/mob/living/basic/mining/mook/proc/grant_healer_abilities()
	AddComponent(\
		/datum/component/healing_touch,\
		heal_brute = melee_damage_upper,\
		heal_burn = melee_damage_upper,\
		heal_time = 0,\
		valid_targets_typecache = typecacheof(list(/mob/living/basic/mining/mook)),\
	)

/mob/living/basic/mining/mook/Entered(atom/movable/mover)
	if(istype(mover, /obj/item/stack/ore))
		held_ore = mover
		update_appearance(UPDATE_OVERLAYS)

	return ..()

/mob/living/basic/mining/mook/Exited(atom/movable/mover)
	. = ..()
	if(held_ore != mover)
		return
	held_ore = null
	update_appearance(UPDATE_OVERLAYS)

/mob/living/basic/mining/mook/early_melee_attack(atom/target, list/modifiers, ignore_cooldown)
	. = ..()
	if(!.)
		return FALSE
	return attack_sequence(target)

/mob/living/basic/mining/mook/proc/attack_sequence(atom/target)
	if(istype(target, /obj/item/stack/ore) && isnull(held_ore))
		var/obj/item/ore_target = target
		ore_target.forceMove(src)
		return FALSE

	if(istype(target, /obj/structure/ore_container/material_stand))
		if(held_ore)
			held_ore.forceMove(target)
		return FALSE

	if(istype(target, /obj/structure/bonfire))
		var/obj/structure/bonfire/fire_target = target
		if(!fire_target.burning)
			fire_target.start_burning()
		return FALSE

/mob/living/basic/mining/mook/proc/change_combatant_state(state)
	attack_state = state
	update_appearance()

/mob/living/basic/mining/mook/Destroy()
	QDEL_NULL(held_ore)
	return ..()

/mob/living/basic/mining/mook/update_icon_state()
	. = ..()
	if(stat == DEAD)
		return
	switch(attack_state)
		if(MOOK_ATTACK_NEUTRAL)
			icon_state = "mook"
		if(MOOK_ATTACK_WARMUP)
			icon_state = "mook_warmup"
		if(MOOK_ATTACK_ACTIVE)
			icon_state = "mook_leap"
		if(MOOK_ATTACK_STRIKE)
			icon_state = "mook_strike"

/mob/living/basic/mining/mook/update_overlays()
	. = ..()
	if(stat == DEAD)
		return

	if(attack_state != MOOK_ATTACK_NEUTRAL || isnull(held_ore))
		return

	. += ore_overlay

/mob/living/basic/mining/mook/throw_at(atom/target, range, speed, mob/thrower, spin=1, diagonals_first = 0, datum/callback/callback, force, gentle = FALSE, quickstart = TRUE, throw_type_path = /datum/thrownthing)
	change_combatant_state(state = MOOK_ATTACK_ACTIVE)
	return ..()

/mob/living/basic/mining/mook/throw_impact(atom/hit_atom, datum/thrownthing/throwingdatum)
	. = ..()
	change_combatant_state(state = MOOK_ATTACK_NEUTRAL)

/mob/living/basic/mining/mook/CanAllowThrough(atom/movable/mover, border_dir)
	. = ..()

	if(.)
		return TRUE

	if(!istype(mover, /mob/living/basic/mining/mook))
		return FALSE

	var/mob/living/basic/mining/mook/mook_moover = mover
	if(mook_moover.attack_state == MOOK_ATTACK_ACTIVE)
		return TRUE

/mob/living/basic/mining/mook/proc/drop_ore(mob/living/user)
	SIGNAL_HANDLER

	if(isnull(held_ore))
		return
	dropItemToGround(held_ore)
	return COMSIG_KB_ACTIVATED

/mob/living/basic/mining/mook/death()
	desc = "A deceased primitive. Upon closer inspection, it was suffering from severe cellular degeneration and its garments are machine made..." //Can you guess the twist
	return ..()

/mob/living/basic/mining/mook/proc/attack_intruder(mob/living/intruder)
	if(istype(intruder, /mob/living/basic/mining/mook))
		return
	for(var/mob/living/basic/mining/mook/villager in oview(src, 9))
		villager.ai_controller?.insert_blackboard_key_lazylist(BB_BASIC_MOB_RETALIATE_LIST, intruder)


/mob/living/basic/mining/mook/worker
	desc = "This unhealthy looking primitive is wielding a rudimentary hatchet, swinging it with wild abandon. One isn't much of a threat, but in numbers they can quickly overwhelm a superior opponent."
	gender = MALE
	melee_damage_lower = 15
	melee_damage_upper = 15
	ai_controller = /datum/ai_controller/basic_controller/mook
	is_healer = FALSE

/mob/living/basic/mining/mook/worker/Initialize(mapload)
	. = ..()
	neutral_stance = mutable_appearance(icon, "mook_axe_overlay")
	attack_stance = mutable_appearance(icon, "axe_strike_overlay")
	update_appearance()

/mob/living/basic/mining/mook/worker/get_innate_abilities()
	var/static/list/worker_innate_abilites = null

	if(isnull(worker_innate_abilites))
		worker_innate_abilites = list()
		worker_innate_abilites += ..()
		worker_innate_abilites += list(
			/datum/action/cooldown/mob_cooldown/mook_ability/mook_leap = BB_MOOK_LEAP_ABILITY,
		)

	return worker_innate_abilites

/mob/living/basic/mining/mook/worker/attack_sequence(atom/target)
	. = ..()
	if(. & COMPONENT_HOSTILE_NO_ATTACK)
		return

	if(attack_state == MOOK_ATTACK_STRIKE)
		return COMPONENT_HOSTILE_NO_ATTACK

	change_combatant_state(state = MOOK_ATTACK_STRIKE)
	addtimer(CALLBACK(src, PROC_REF(change_combatant_state), MOOK_ATTACK_NEUTRAL), 0.3 SECONDS)

/mob/living/basic/mining/mook/worker/update_overlays()
	. = ..()
	if(stat == DEAD)
		return

	switch(attack_state)
		if(MOOK_ATTACK_STRIKE)
			. += attack_stance
		if(MOOK_ATTACK_NEUTRAL)
			. += neutral_stance

/mob/living/basic/mining/mook/worker/bard
	desc = "It's holding a guitar?"
	melee_damage_lower = 10
	melee_damage_upper = 10
	gender = MALE
	attack_sound = 'sound/items/weapons/stringsmash.ogg'
	death_sound = 'sound/mobs/non-humanoids/mook/mook_death.ogg'
	ai_controller = /datum/ai_controller/basic_controller/mook/bard
	///our guitar
	var/obj/item/instrument/guitar/held_guitar

/mob/living/basic/mining/mook/worker/bard/Initialize(mapload)
	. = ..()
	neutral_stance = mutable_appearance(icon, "bard_overlay")
	attack_stance = mutable_appearance(icon, "bard_strike")
	held_guitar = new(src)
	ai_controller.set_blackboard_key(BB_SONG_INSTRUMENT, held_guitar)
	update_appearance()

/mob/living/basic/mining/mook/worker/tribal_chief
	name = "tribal chief"
	desc = "Acknowledge him!"
	gender = MALE
	melee_damage_lower = 20
	melee_damage_upper = 20
	ai_controller = /datum/ai_controller/basic_controller/mook/tribal_chief
	///overlay in our neutral state
	var/static/mutable_appearance/chief_neutral = mutable_appearance('icons/mob/simple/jungle/mook.dmi', "mook_chief")
	///overlay in our striking state
	var/static/mutable_appearance/chief_strike = mutable_appearance('icons/mob/simple/jungle/mook.dmi', "mook_chief_strike")
	///overlay in our active state
	var/static/mutable_appearance/chief_active = mutable_appearance('icons/mob/simple/jungle/mook.dmi', "mook_chief_leap")
	///overlay in our warmup state
	var/static/mutable_appearance/chief_warmup = mutable_appearance('icons/mob/simple/jungle/mook.dmi', "mook_chief_warmup")

/mob/living/basic/mining/mook/worker/tribal_chief/Initialize(mapload)
	. = ..()
	update_appearance()

/mob/living/basic/mining/mook/worker/tribal_chief/update_overlays()
	. = ..()
	if(stat == DEAD)
		return
	switch(attack_state)
		if(MOOK_ATTACK_NEUTRAL)
			. += chief_neutral
		if(MOOK_ATTACK_WARMUP)
			. += chief_warmup
		if(MOOK_ATTACK_ACTIVE)
			. += chief_active
		if(MOOK_ATTACK_STRIKE)
			. += chief_strike
