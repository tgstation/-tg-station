ADMIN_VERB(fishing_calculator, R_DEBUG, "Fishing Calculator", "A calculator... for fishes?", ADMIN_CATEGORY_DEBUG)
	var/datum/fishing_calculator/ui = new
	ui.ui_interact(user.mob)

/datum/fishing_calculator
	var/list/current_table

/datum/fishing_calculator/ui_interact(mob/user, datum/tgui/ui)
	ui = SStgui.try_update_ui(user, src, ui)
	if(!ui)
		ui = new(user, src, "FishingCalculator")
		ui.open()

/datum/fishing_calculator/ui_state(mob/user)
	return ADMIN_STATE(R_DEBUG)

/datum/fishing_calculator/ui_close(mob/user)
	qdel(src)

/datum/fishing_calculator/ui_static_data(mob/user)
	. = ..()
	.["rod_types"] = typesof(/obj/item/fishing_rod)
	.["hook_types"] = typesof(/obj/item/fishing_hook)
	.["line_types"] = typesof(/obj/item/fishing_line)
	.["spot_types"] = subtypesof(/datum/fish_source)

/datum/fishing_calculator/ui_data(mob/user)
	return list("info" = current_table)

/datum/fishing_calculator/ui_act(action, list/params, datum/tgui/ui, datum/ui_state/state)
	. = ..()
	var/mob/user = usr
	switch(action)
		if("recalc")
			var/rod_type = text2path(params["rod"])
			if(!rod_type)
				to_chat(user, span_warning("A fishing rod is needed in order to fish."))
				return
			var/hook_type = text2path(params["hook"])
			if(!hook_type)
				to_chat(user, span_warning("A fishing hook is needed in order to fish."))
				return
			var/bait_type = text2path(params["bait"])
			var/line_type = text2path(params["line"])
			var/datum/fish_source/spot = GLOB.preset_fish_sources[text2path(params["spot"])]

			var/obj/item/fishing_rod/temporary_rod = new rod_type
			qdel(temporary_rod.bait)
			qdel(temporary_rod.line)
			qdel(temporary_rod.hook)

			if(bait_type)
				temporary_rod.set_slot(new bait_type(temporary_rod), ROD_SLOT_BAIT)
			temporary_rod.set_slot(new hook_type(temporary_rod), ROD_SLOT_HOOK)
			if(line_type)
				temporary_rod.set_slot(new line_type(temporary_rod), ROD_SLOT_LINE)

			var/result_table = list()
			var/modified_table = spot.get_modified_fish_table(temporary_rod, user, null)
			for(var/result_type in spot.fish_table) // through this not modified to display 0 chance ones too
				var/list/info = list()
				info["result"] = result_type
				info["weight"] = modified_table[result_type] || 0
				info["difficulty"] = spot.calculate_difficulty(result_type, temporary_rod, user) + /datum/fishing_challenge::difficulty
				info["count"] = spot.fish_counts[result_type] || "Infinite"
				result_table += list(info)
			current_table = result_table

			qdel(temporary_rod)
			return TRUE
