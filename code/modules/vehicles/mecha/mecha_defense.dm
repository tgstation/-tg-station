/*!
 * # Mecha defence explanation
 * Mechs focus is on a more heavy-but-slower damage approach
 * For this they have the following mechanics
 *
 * ## Backstab
 * Basically the tldr is that mechs are less flexible so we encourage good positioning, pretty simple
 * ## Armor modules
 * Pretty simple, adds armor, you can choose against what
 * ## Internal damage
 * When taking damage will force you to take some time to repair, encourages improvising in a fight
 * Targeting different def zones will damage them to encurage a more strategic approach to fights
 * where they target the "dangerous" modules
 */

/// tries to damage mech equipment depending on damage and where is being targeted
/obj/vehicle/sealed/mecha/proc/try_damage_component(damage, def_zone)
	if(damage < component_damage_threshold)
		return
	var/obj/item/mecha_parts/mecha_equipment/gear
	switch(def_zone)
		if(BODY_ZONE_L_ARM)
			gear = equip_by_category[MECHA_L_ARM]
		if(BODY_ZONE_R_ARM)
			gear = equip_by_category[MECHA_R_ARM]
	if(!gear)
		return
	var/component_health = gear.get_integrity()
	// always leave at least 1 health
	var/damage_to_deal = min(component_health - 1, damage)
	if(damage_to_deal <= 0)
		return

	gear.take_damage(damage_to_deal)
	if(gear.get_integrity() <= 1)
		to_chat(occupants, "[icon2html(src, occupants)][span_danger("[gear] is critically damaged!")]")
		playsound(src, gear.destroy_sound, 50)

/obj/vehicle/sealed/mecha/take_damage(damage_amount, damage_type = BRUTE, damage_flag = "", sound_effect = TRUE, attack_dir, armour_penetration = 0)
	var/damage_taken = ..()
	if(damage_taken <= 0 || atom_integrity < 0)
		return damage_taken

	diag_hud_set_mechhealth()
	spark_system?.start()
	try_deal_internal_damage(damage_taken)
	if(damage_taken >= 5 || prob(33))
		to_chat(occupants, "[icon2html(src, occupants)][span_userdanger("Taking damage!")]")
	log_message("Took [damage_taken] points of damage. Damage type: [damage_type]", LOG_MECHA)

	return damage_taken

/obj/vehicle/sealed/mecha/run_atom_armor(damage_amount, damage_type, damage_flag = 0, attack_dir, armour_penetration)
	. = ..()
	if(attack_dir)
		var/facing_modifier = get_armour_facing(abs(dir2angle(dir) - dir2angle(attack_dir)))
		if(.)
			. *= facing_modifier

/obj/vehicle/sealed/mecha/attack_hand(mob/living/user, list/modifiers)
	. = ..()
	if(.)
		return
	user.changeNext_move(CLICK_CD_MELEE) // Ugh. Ideally we shouldn't be setting cooldowns outside of click code.
	user.do_attack_animation(src, ATTACK_EFFECT_PUNCH)
	playsound(loc, 'sound/items/weapons/tap.ogg', 40, TRUE, -1)
	user.visible_message(span_danger("[user] hits [src]. Nothing happens."), null, null, COMBAT_MESSAGE_RANGE)
	log_message("Attack by hand/paw (no damage). Attacker - [user].", LOG_MECHA, color="red")

/obj/vehicle/sealed/mecha/attack_paw(mob/user, list/modifiers)
	return attack_hand(user, modifiers)

/obj/vehicle/sealed/mecha/attack_alien(mob/living/user, list/modifiers)
	log_message("Attack by alien. Attacker - [user].", LOG_MECHA, color="red")
	playsound(loc, 'sound/items/weapons/slash.ogg', 100, TRUE)
	attack_generic(user, rand(user.melee_damage_lower, user.melee_damage_upper), BRUTE, MELEE, 0)

/obj/vehicle/sealed/mecha/attack_animal(mob/living/simple_animal/user, list/modifiers)
	log_message("Attack by simple animal. Attacker - [user].", LOG_MECHA, color="red")
	if(!user.melee_damage_upper && !user.obj_damage)
		user.emote("custom", message = "[user.friendly_verb_continuous] [src].")
		return 0
	else
		var/play_soundeffect = 1
		if(user.environment_smash)
			play_soundeffect = 0
			playsound(src, 'sound/effects/bang.ogg', 50, TRUE)
		var/animal_damage = rand(user.melee_damage_lower,user.melee_damage_upper)
		if(user.obj_damage)
			animal_damage = user.obj_damage
		animal_damage = min(animal_damage, 20*user.environment_smash)
		log_combat(user, src, "attacked")
		attack_generic(user, animal_damage, user.melee_damage_type, MELEE, play_soundeffect)
		return 1


/obj/vehicle/sealed/mecha/hulk_damage()
	return 15

/obj/vehicle/sealed/mecha/attack_hulk(mob/living/carbon/human/user)
	. = ..()
	if(.)
		log_message("Attack by hulk. Attacker - [user].", LOG_MECHA, color="red")
		log_combat(user, src, "punched", "hulk powers")

/obj/vehicle/sealed/mecha/blob_act(obj/structure/blob/B)
	log_message("Attack by blob. Attacker - [B].", LOG_MECHA, color="red")
	take_damage(30, BRUTE, MELEE, 0, get_dir(src, B))

/obj/vehicle/sealed/mecha/attack_tk()
	return

/obj/vehicle/sealed/mecha/hitby(atom/movable/AM, skipcatch, hitpush, blocked, datum/thrownthing/throwingdatum) //wrapper
	log_message("Hit by [AM].", LOG_MECHA, color="red")
	return ..()

/obj/vehicle/sealed/mecha/bullet_act(obj/projectile/hitting_projectile, def_zone, piercing_hit) //wrapper
	//allows bullets to hit the pilot of open-canopy mechs
	if(!(mecha_flags & IS_ENCLOSED) \
		&& LAZYLEN(occupants) \
		&& !(mecha_flags & SILICON_PILOT) \
		&& (def_zone == BODY_ZONE_HEAD || def_zone == BODY_ZONE_CHEST))
		var/mob/living/hitmob = pick(occupants)
		return hitmob.projectile_hit(hitting_projectile, def_zone, piercing_hit) //If the sides are open, the occupant can be hit

	. = ..()

	log_message("Hit by projectile. Type: [hitting_projectile]([hitting_projectile.damage_type]).", LOG_MECHA, color="red")
	// yes we *have* to run the armor calc proc here I love tg projectile code too
	try_damage_component(run_atom_armor(
		damage_amount = hitting_projectile.damage,
		damage_type = hitting_projectile.damage_type,
		damage_flag = hitting_projectile.armor_flag,
		attack_dir = REVERSE_DIR(hitting_projectile.dir),
		armour_penetration = hitting_projectile.armour_penetration,
	), def_zone)


/obj/vehicle/sealed/mecha/ex_act(severity, target)
	log_message("Affected by explosion of severity: [severity].", LOG_MECHA, color="red")
	return ..()

/obj/vehicle/sealed/mecha/contents_explosion(severity, target)
	severity--

	switch(severity)
		if(EXPLODE_DEVASTATE)
			if(flat_equipment)
				SSexplosions.high_mov_atom += flat_equipment
			if(trackers)
				SSexplosions.high_mov_atom += trackers
			if(occupants)
				SSexplosions.high_mov_atom += occupants
		if(EXPLODE_HEAVY)
			if(flat_equipment)
				SSexplosions.med_mov_atom += flat_equipment
			if(trackers)
				SSexplosions.med_mov_atom += trackers
			if(occupants)
				SSexplosions.med_mov_atom += occupants
		if(EXPLODE_LIGHT)
			if(flat_equipment)
				SSexplosions.low_mov_atom += flat_equipment
			if(trackers)
				SSexplosions.low_mov_atom += trackers
			if(occupants)
				SSexplosions.low_mov_atom += occupants

/obj/vehicle/sealed/mecha/emp_act(severity)
	. = ..()
	if (. & EMP_PROTECT_SELF)
		return
	if(get_charge())
		use_energy((cell.charge/3)/(severity*2))
		take_damage(30 / severity, BURN, ENERGY, 1)
	log_message("EMP detected", LOG_MECHA, color="red")

	//Mess with the focus of the inbuilt camera if present
	if(chassis_camera && !chassis_camera.is_emp_scrambled)
		chassis_camera.setViewRange(chassis_camera.short_range)
		chassis_camera.is_emp_scrambled = TRUE
		diag_hud_set_camera()
		addtimer(CALLBACK(chassis_camera, TYPE_PROC_REF(/obj/machinery/camera/exosuit, emp_refocus), src), 10 SECONDS / severity)

	if(!equipment_disabled && LAZYLEN(occupants)) //prevent spamming this message with back-to-back EMPs
		to_chat(occupants, span_warning("Error -- Connection to equipment control unit has been lost."))
	addtimer(CALLBACK(src, TYPE_PROC_REF(/obj/vehicle/sealed/mecha, restore_equipment)), 3 SECONDS, TIMER_UNIQUE | TIMER_OVERRIDE)
	equipment_disabled = TRUE
	set_mouse_pointer()

/obj/vehicle/sealed/mecha/should_atmos_process(datum/gas_mixture/air, exposed_temperature)
	return exposed_temperature > max_temperature

/obj/vehicle/sealed/mecha/atmos_expose(datum/gas_mixture/air, exposed_temperature)
	log_message("Exposed to dangerous temperature.", LOG_MECHA, color="red")
	take_damage(5, BURN, 0, 1)

/obj/vehicle/sealed/mecha/fire_act() //Check if we should ignite the pilot of an open-canopy mech
	. = ..()
	if(mecha_flags & IS_ENCLOSED || mecha_flags & SILICON_PILOT)
		return
	for(var/mob/living/cookedalive as anything in occupants)
		if(cookedalive.fire_stacks < 5)
			cookedalive.adjust_fire_stacks(1)
			cookedalive.ignite_mob()

/obj/vehicle/sealed/mecha/attackby_secondary(obj/item/weapon, mob/user, params)
	if(istype(weapon, /obj/item/mecha_parts))
		var/obj/item/mecha_parts/parts = weapon
		parts.try_attach_part(user, src, TRUE)
		return SECONDARY_ATTACK_CANCEL_ATTACK_CHAIN
	return ..()

/obj/vehicle/sealed/mecha/attackby(obj/item/weapon, mob/living/user, params)
	if(user.combat_mode)
		return ..()
	if(istype(weapon, /obj/item/mmi))
		if(mmi_move_inside(weapon,user))
			balloon_alert(user, "weapon initialized.")
		else
			balloon_alert(user, "weapon initialization failed!")
		return

	if(istype(weapon, /obj/item/mecha_ammo))
		ammo_resupply(weapon, user)
		return

	if(istype(weapon, /obj/item/rcd_upgrade))
		upgrade_rcd(weapon, user)
		return

	if(weapon.GetID())
		if(!allowed(user))
			if(mecha_flags & ID_LOCK_ON)
				balloon_alert(user, "access denied!")
			else
				balloon_alert(user, "unable to set id lock!")
			return
		mecha_flags ^= ID_LOCK_ON
		balloon_alert(user, "[mecha_flags & ID_LOCK_ON ? "enabled" : "disabled"] id lock !")
		return

	if(istype(weapon, /obj/item/mecha_parts))
		var/obj/item/mecha_parts/part = weapon
		part.try_attach_part(user, src, FALSE)
		return

	if(is_wire_tool(weapon) && (mecha_flags & PANEL_OPEN))
		wires.interact(user)
		return

	if(istype(weapon, /obj/item/stock_parts))
		try_insert_part(weapon, user)
		return

	return ..()

/// Try to insert a stock part into the mech
/obj/vehicle/sealed/mecha/proc/try_insert_part(obj/item/stock_parts/weapon, mob/living/user)
	if(!(mecha_flags & PANEL_OPEN))
		balloon_alert(user, "open the panel first!")
		return

	if(istype(weapon, /obj/item/stock_parts/power_store/cell))
		if(!cell)
			if(!user.transferItemToLoc(weapon, src, silent = FALSE))
				return
			cell = weapon
			balloon_alert(user, "installed power cell")
			diag_hud_set_mechcell()
			playsound(src, 'sound/items/tools/screwdriver2.ogg', 50, FALSE)
			log_message("Power cell installed", LOG_MECHA)
		else
			balloon_alert(user, "already installed!")
		return

	if(istype(weapon, /obj/item/stock_parts/scanning_module))
		if(!scanmod)
			if(!user.transferItemToLoc(weapon, src, silent = FALSE))
				return
			scanmod = weapon
			balloon_alert(user, "installed scanning module")
			playsound(src, 'sound/items/tools/screwdriver2.ogg', 50, FALSE)
			log_message("[weapon] installed", LOG_MECHA)
			update_part_values()
		else
			balloon_alert(user, "already installed!")
		return

	if(istype(weapon, /obj/item/stock_parts/capacitor))
		if(!capacitor)
			if(!user.transferItemToLoc(weapon, src, silent = FALSE))
				return
			capacitor = weapon
			balloon_alert(user, "installed capacitor")
			playsound(src, 'sound/items/tools/screwdriver2.ogg', 50, FALSE)
			log_message("[weapon] installed", LOG_MECHA)
			update_part_values()
		else
			balloon_alert(user, "already installed!")
		return

	if(istype(weapon, /obj/item/stock_parts/servo))
		if(!servo)
			if(!user.transferItemToLoc(weapon, src, silent = FALSE))
				return
			servo = weapon
			balloon_alert(user, "installed servo")
			playsound(src, 'sound/items/tools/screwdriver2.ogg', 50, FALSE)
			log_message("[weapon] installed", LOG_MECHA)
			update_part_values()
		else
			balloon_alert(user, "already installed!")
		return

/obj/vehicle/sealed/mecha/attacked_by(obj/item/attacking_item, mob/living/user)
	if(!attacking_item.force)
		return

	var/damage_taken = take_damage(attacking_item.force * attacking_item.demolition_mod, attacking_item.damtype, MELEE, 1, get_dir(src, user))
	try_damage_component(damage_taken, user.zone_selected)

	var/hit_verb = length(attacking_item.attack_verb_simple) ? "[pick(attacking_item.attack_verb_simple)]" : "hit"
	user.visible_message(
		span_danger("[user] [hit_verb][plural_s(hit_verb)] [src] with [attacking_item][damage_taken ? "." : ", without leaving a mark!"]"),
		span_danger("You [hit_verb] [src] with [attacking_item][damage_taken ? "." : ", without leaving a mark!"]"),
		span_hear("You hear a [hit_verb]."),
		COMBAT_MESSAGE_RANGE,
	)

	log_combat(user, src, "attacked", attacking_item)
	log_message("Attacked by [user]. Item - [attacking_item], Damage - [damage_taken]", LOG_MECHA)

/obj/vehicle/sealed/mecha/attack_generic(mob/user, damage_amount, damage_type, damage_flag, effects, armor_penetration)
	. = ..()
	if(.)
		try_damage_component(., user.zone_selected)
		diag_hud_set_mechhealth()

/obj/vehicle/sealed/mecha/examine(mob/user)
	. = ..()
	if(mecha_flags & PANEL_OPEN)
		. += span_notice("The panel is open. You could use a <b>crowbar</b> to eject parts or lock the panel back with a <b>screwdriver</b>.")
	else
		. += span_notice("You could unlock the maintenance cover with a <b>screwdriver</b>.")

/obj/vehicle/sealed/mecha/screwdriver_act(mob/living/user, obj/item/tool)
	..()
	. = TRUE

	if(LAZYLEN(occupants))
		balloon_alert(user, "panel blocked")
		return

	mecha_flags ^= PANEL_OPEN
	balloon_alert(user, (mecha_flags & PANEL_OPEN) ? "panel open" : "panel closed")
	tool.play_tool_sound(src)

/obj/vehicle/sealed/mecha/crowbar_act(mob/living/user, obj/item/tool)
	..()
	. = TRUE
	if(istype(tool, /obj/item/crowbar/mechremoval))
		var/obj/item/crowbar/mechremoval/remover = tool
		remover.empty_mech(src, user)
		return
	if(!(mecha_flags & PANEL_OPEN))
		balloon_alert(user, "open the panel first!")
		return
	if(dna_lock && user.has_dna())
		var/mob/living/carbon/user_carbon = user
		if(user_carbon.dna.unique_enzymes != dna_lock)
			balloon_alert(user, "access with this DNA denied!")
			return
	if((mecha_flags & ID_LOCK_ON) && !allowed(user))
		balloon_alert(user, "access denied!")
		return

	var/list/stock_parts = list()
	if(cell)
		stock_parts += cell
	if(scanmod)
		stock_parts += scanmod
	if(capacitor)
		stock_parts += capacitor
	if(servo)
		stock_parts += servo

	if(length(stock_parts))
		var/obj/item/stock_parts/part_to_remove = tgui_input_list(user, "Which part to remove?", "Part Removal", stock_parts)
		if(!(locate(part_to_remove) in contents))
			return
		user.put_in_hands(part_to_remove)
		locate_parts()
		diag_hud_set_mechcell()
		tool.play_tool_sound(src)
		return
	balloon_alert(user, "no parts!")

/obj/vehicle/sealed/mecha/welder_act(mob/living/user, obj/item/W)
	if(user.combat_mode)
		return
	. = TRUE
	if(DOING_INTERACTION(user, src))
		balloon_alert(user, "you're already repairing this!")
		return
	if(atom_integrity >= max_integrity)
		balloon_alert(user, "it's not damaged!")
		return
	if(!W.tool_start_check(user, amount=1, heat_required = HIGH_TEMPERATURE_REQUIRED))
		return
	user.balloon_alert_to_viewers("started welding [src]", "started repairing [src]")
	audible_message(span_hear("You hear welding."))
	var/did_the_thing
	while(atom_integrity < max_integrity)
		if(W.use_tool(src, user, 2.5 SECONDS, volume=50))
			did_the_thing = TRUE
			atom_integrity += min(10, (max_integrity - atom_integrity))
			audible_message(span_hear("You hear welding."))
		else
			break
	if(did_the_thing)
		user.balloon_alert_to_viewers("[(atom_integrity >= max_integrity) ? "fully" : "partially"] repaired [src]")
		diag_hud_set_mechhealth()
	else
		user.balloon_alert_to_viewers("stopped welding [src]", "interrupted the repair!")


/obj/vehicle/sealed/mecha/proc/full_repair(charge_cell)
	atom_integrity = max_integrity
	if(cell && charge_cell)
		cell.charge = cell.maxcharge
		diag_hud_set_mechcell()
	if(internal_damage & MECHA_INT_FIRE)
		clear_internal_damage(MECHA_INT_FIRE)
	if(internal_damage & MECHA_INT_TEMP_CONTROL)
		clear_internal_damage(MECHA_INT_TEMP_CONTROL)
	if(internal_damage & MECHA_INT_SHORT_CIRCUIT)
		clear_internal_damage(MECHA_INT_SHORT_CIRCUIT)
	if(internal_damage & MECHA_CABIN_AIR_BREACH)
		clear_internal_damage(MECHA_CABIN_AIR_BREACH)
	if(internal_damage & MECHA_INT_CONTROL_LOST)
		clear_internal_damage(MECHA_INT_CONTROL_LOST)
	diag_hud_set_mechhealth()

/obj/vehicle/sealed/mecha/narsie_act()
	emp_act(EMP_HEAVY)

/obj/vehicle/sealed/mecha/do_attack_animation(atom/A, visual_effect_icon, obj/item/used_item, no_effect)
	if(!no_effect && !visual_effect_icon)
		visual_effect_icon = ATTACK_EFFECT_SMASH
		if(damtype == BURN)
			visual_effect_icon = ATTACK_EFFECT_MECHFIRE
		else if(damtype == TOX)
			visual_effect_icon = ATTACK_EFFECT_MECHTOXIN
	..()


/obj/vehicle/sealed/mecha/proc/ammo_resupply(obj/item/mecha_ammo/A, mob/user,fail_chat_override = FALSE)
	if(!A.rounds)
		if(!fail_chat_override)
			balloon_alert(user, "the box is empty!")
		return FALSE
	var/ammo_needed
	var/found_gun
	for(var/obj/item/mecha_parts/mecha_equipment/weapon/ballistic/gun in flat_equipment)
		ammo_needed = 0

		if(gun.ammo_type != A.ammo_type)
			continue
		found_gun = TRUE
		if(A.direct_load)
			ammo_needed = initial(gun.projectiles) - gun.projectiles
		else
			ammo_needed = gun.projectiles_cache_max - gun.projectiles_cache

		if(!ammo_needed)
			continue
		if(ammo_needed < A.rounds)
			if(A.direct_load)
				gun.projectiles = gun.projectiles + ammo_needed
			else
				gun.projectiles_cache = gun.projectiles_cache + ammo_needed
			playsound(get_turf(user),A.load_audio,50,TRUE)
			to_chat(user, span_notice("You add [ammo_needed] [A.ammo_type][ammo_needed > 1?"s":""] to \the [gun]"))
			A.rounds = A.rounds - ammo_needed
			if(A.custom_materials)	//Change material content of the ammo box according to the amount of ammo deposited into the weapon
				/// list of materials contained in the ammo box after we put it through the equation so we can stick this list into set_custom_materials()
				var/list/new_material_content = list()
				for(var/datum/material/current_material in A.custom_materials)
					if(istype(current_material, /datum/material/iron))	//we can flatten an empty ammo box into a sheet of iron (2000 units) so we have to make sure the box always has this amount at minimum
						new_material_content[current_material] = (A.custom_materials[current_material] - SHEET_MATERIAL_AMOUNT) * (A.rounds / initial(A.rounds)) + SHEET_MATERIAL_AMOUNT
					else
						new_material_content[current_material] = A.custom_materials[current_material] * (A.rounds / initial(A.rounds))
				A.set_custom_materials(new_material_content)
			A.update_name()
			return TRUE

		if(A.direct_load)
			gun.projectiles = gun.projectiles + A.rounds
		else
			gun.projectiles_cache = gun.projectiles_cache + A.rounds
		playsound(get_turf(user),A.load_audio,50,TRUE)
		to_chat(user, span_notice("You add [A.rounds] [A.ammo_type][A.rounds > 1?"s":""] to \the [gun]"))
		if(A.qdel_on_empty)
			qdel(A)
			return TRUE
		A.rounds = 0
		A.set_custom_materials(list(/datum/material/iron=SHEET_MATERIAL_AMOUNT))
		A.update_appearance()
		return TRUE
	if(!fail_chat_override)
		if(found_gun)
			balloon_alert(user, "ammo storage is full!")
		else
			balloon_alert(user, "can't use this ammo!")
	return FALSE

///Upgrades any attached RCD equipment.
/obj/vehicle/sealed/mecha/proc/upgrade_rcd(obj/item/rcd_upgrade/rcd_upgrade, mob/user)
	for(var/obj/item/mecha_parts/mecha_equipment/rcd/rcd_equip in flat_equipment)
		if(rcd_equip.internal_rcd.install_upgrade(rcd_upgrade, user))
			return
