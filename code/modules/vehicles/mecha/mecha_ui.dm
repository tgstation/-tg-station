/obj/vehicle/sealed/mecha/ui_close(mob/user)
	. = ..()
	ui_view.hide_from(user)

/obj/vehicle/sealed/mecha/ui_interact(mob/user, datum/tgui/ui)
	ui = SStgui.try_update_ui(user, src, ui)
	if(!ui)
		ui = new(user, src, "Mecha", name)
		ui.open()
		ui_view.display_to(user)

/obj/vehicle/sealed/mecha/ui_status(mob/user, datum/ui_state/state)
	var/common_status = min(
		ui_status_user_is_abled(user, src),
		ui_status_only_living(user),
	)
	var/mob_specific_status = UI_INTERACTIVE
	if(ishuman(user))
		mob_specific_status = min(
			ui_status_user_inside(user, src),
			ui_status_user_has_free_hands(user, src, allowed_source = VEHICLE_TRAIT),
			ui_status_user_is_advanced_tool_user(user),
		)
	if(isAI(user))
		mob_specific_status = ui_status_silicon_has_access(user, src)
	if(isbrain(user))
		mob_specific_status = ui_status_user_inside(user, src)
	return min(common_status, mob_specific_status)

/obj/vehicle/sealed/mecha/ui_assets(mob/user)
	return list(
		get_asset_datum(/datum/asset/spritesheet_batched/mecha_equipment),
	)

/obj/vehicle/sealed/mecha/ui_static_data(mob/user)
	var/list/data = list()
	data["ui_theme"] = ui_theme
	//same thresholds as in air alarm
	data["cabin_pressure_warning_min"]  = WARNING_LOW_PRESSURE
	data["cabin_pressure_hazard_min"]  = HAZARD_LOW_PRESSURE
	data["cabin_pressure_warning_max"]  = WARNING_HIGH_PRESSURE
	data["cabin_pressure_hazard_max"]  = HAZARD_HIGH_PRESSURE
	data["cabin_temp_warning_min"]  = BODYTEMP_COLD_WARNING_1 + 10 - T0C
	data["cabin_temp_hazard_min"]  = BODYTEMP_COLD_WARNING_1 - T0C
	data["cabin_temp_warning_max"]  = BODYTEMP_HEAT_WARNING_1 - 27 - T0C
	data["cabin_temp_hazard_max"]  = BODYTEMP_HEAT_WARNING_1 - T0C
	data["one_atmosphere"]  = ONE_ATMOSPHERE

	data["sheet_material_amount"] = SHEET_MATERIAL_AMOUNT
	//map of relevant flags to check tgui side, not every flag needs to be here
	data["mechflag_keys"] = list(
		"ID_LOCK_ON" = ID_LOCK_ON,
		"LIGHTS_ON" = LIGHTS_ON,
		"HAS_LIGHTS" = HAS_LIGHTS,
	)
	data["internal_damage_keys"] = list(
		"MECHA_INT_FIRE" = MECHA_INT_FIRE,
		"MECHA_INT_TEMP_CONTROL" = MECHA_INT_TEMP_CONTROL,
		"MECHA_CABIN_AIR_BREACH" = MECHA_CABIN_AIR_BREACH,
		"MECHA_INT_CONTROL_LOST" = MECHA_INT_CONTROL_LOST,
		"MECHA_INT_SHORT_CIRCUIT" = MECHA_INT_SHORT_CIRCUIT,
	)

	var/list/regions = list()
	var/list/tgui_region_data = SSid_access.all_region_access_tgui
	for(var/region in SSid_access.station_regions)
		regions += tgui_region_data[region]
	data["regions"] = regions
	return data

/obj/vehicle/sealed/mecha/ui_data(mob/user)
	var/list/data = list()
	var/isoperator = (user in occupants) //maintenance mode outside of mech
	data["isoperator"] = isoperator
	data["cell"] = cell?.name
	data["scanning"] = scanmod?.name
	data["capacitor"] = capacitor?.name
	data["servo"] = servo?.name
	ui_view.appearance = appearance
	data["name"] = name
	data["integrity"] = atom_integrity
	data["integrity_max"] = max_integrity
	data["power_level"] = cell?.charge
	data["power_max"] = cell?.maxcharge
	data["mecha_flags"] = mecha_flags
	data["internal_damage"] = internal_damage

	data["can_use_overclock"] = can_use_overclock
	data["overclock_safety_available"] = overclock_safety_available
	data["overclock_safety"] = overclock_safety
	data["overclock_mode"] = overclock_mode
	data["overclock_temp_percentage"] = overclock_temp / overclock_temp_danger

	data["dna_lock"] = dna_lock

	data["one_access"] = one_access
	data["accesses"] = accesses

	data["servo_rating"] = servo?.rating
	data["scanmod_rating"] = scanmod?.rating
	data["capacitor_rating"] = capacitor?.rating

	data["weapons_safety"] = weapons_safety
	data["enclosed"] = mecha_flags & IS_ENCLOSED
	data["cabin_sealed"] = cabin_sealed
	data["cabin_temp"] =  round(cabin_air.temperature - T0C)
	data["cabin_pressure"] = round(cabin_air.return_pressure())
	data["mech_view"] = ui_view.assigned_map
	data["modules"] = get_module_ui_data()
	data["selected_module_index"] = ui_selected_module_index
	return data

/obj/vehicle/sealed/mecha/proc/get_module_ui_data()
	var/list/data = list()
	var/module_index = 0
	for(var/category in max_equip_by_category)
		var/max_per_category = max_equip_by_category[category]
		if(max_per_category)
			for(var/i = 1 to max_per_category)
				var/equipment = equip_by_category[category]
				var/is_slot_free = islist(equipment) ? i > length(equipment) : isnull(equipment)
				if(is_slot_free)
					data += list(list(
						"slot" = category
					))
					if(ui_selected_module_index == module_index)
						ui_selected_module_index = null
				else
					var/obj/item/mecha_parts/mecha_equipment/module = islist(equipment) ? equipment[i] : equipment
					data += list(list(
						"slot" = category,
						"icon" = module.icon_state,
						"name" = module.name,
						"desc" = module.desc,
						"detachable" = module.detachable,
						"integrity" = (module.get_integrity()/module.max_integrity),
						"can_be_toggled" = module.can_be_toggled,
						"can_be_triggered" = module.can_be_triggered,
						"active" = module.active,
						"active_label" = module.active_label,
						"equip_cooldown" = module.equip_cooldown && DisplayTimeText(module.equip_cooldown),
						"energy_per_use" = module.energy_drain,
						"snowflake" = module.get_snowflake_data(),
						"ref" = REF(module),
					))
					if(isnull(ui_selected_module_index))
						ui_selected_module_index = module_index
				module_index++
	return data

/obj/vehicle/sealed/mecha/ui_act(action, list/params, datum/tgui/ui, datum/ui_state/state)
	. = ..()
	if(.)
		return
	switch(action)
		if("clear_all")
			accesses = list()
			one_access = 0
			update_access()
		if("grant_all")
			accesses = SSid_access.get_region_access_list(list(REGION_ALL_STATION))
			update_access()
		if("one_access")
			one_access = !one_access
			update_access()
		if("set")
			var/access = params["access"]
			if (!(access in accesses))
				accesses += access
			else
				accesses -= access
			update_access()
		if("grant_region")
			var/region = params["region"]
			if(isnull(region))
				return
			accesses |= SSid_access.get_region_access_list(list(region))
			update_access()
		if("deny_region")
			var/region = params["region"]
			if(isnull(region))
				return
			accesses -= SSid_access.get_region_access_list(list(region))
			update_access()
		if("select_module")
			ui_selected_module_index = text2num(params["index"])
			return TRUE
		if("changename")
			var/userinput = tgui_input_text(usr, "Choose a new exosuit name", "Rename exosuit", max_length = MAX_NAME_LEN, default = name)
			if(!userinput)
				return
			if(is_ic_filtered(userinput) || is_soft_ic_filtered(userinput))
				tgui_alert(usr, "You cannot set a name that contains a word prohibited in IC chat!")
				return
			if(userinput == format_text(name)) //default mecha names may have improper span artefacts in their name, so we format the name
				to_chat(usr, span_notice("You rename [name] to... well, [userinput]."))
				return
			name = "\proper [userinput]"
			chassis_camera?.update_c_tag(src)
		if("toggle_safety")
			set_safety(usr)
			return
		if("dna_lock")
			var/mob/living/carbon/user = usr
			if(!istype(user) || !user.dna)
				to_chat(user, "[icon2html(src, occupants)][span_notice("You can't create a DNA lock with no DNA!.")]")
				return
			dna_lock = user.dna.unique_enzymes
			to_chat(user, "[icon2html(src, occupants)][span_notice("You feel a prick as the needle takes your DNA sample.")]")
		if("reset_dna")
			dna_lock = null
		if("toggle_cabin_seal")
			set_cabin_seal(usr, !cabin_sealed)
		if("toggle_id_lock")
			mecha_flags ^= ID_LOCK_ON
		if("toggle_lights")
			toggle_lights(user = usr)
		if("toggle_overclock")
			toggle_overclock()
		if("toggle_overclock_safety")
			overclock_safety = !overclock_safety
		if("repair_int_damage")
			try_repair_int_damage(usr, params["flag"])
			return FALSE
		if("equip_act")
			var/obj/item/mecha_parts/mecha_equipment/gear = locate(params["ref"]) in flat_equipment
			return gear?.ui_act(params["gear_action"], params, ui, state)
	return TRUE

