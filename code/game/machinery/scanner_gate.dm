#define SCANGATE_NONE "Off"
#define SCANGATE_MINDSHIELD "Mindshield"
#define SCANGATE_DISEASE "Disease"
#define SCANGATE_GUNS "Guns"
#define SCANGATE_WANTED "Wanted"
#define SCANGATE_SPECIES "Species"
#define SCANGATE_NUTRITION "Nutrition"

/obj/machinery/scanner_gate
	name = "scanner gate"
	desc = "A gate able to perform mid-depth scans on any organisms who pass under it."
	icon = 'icons/obj/machines/scangate.dmi'
	icon_state = "scangate"
	layer = ABOVE_MOB_LAYER
	circuit = /obj/item/circuitboard/machine/scanner_gate
	COOLDOWN_DECLARE(next_beep)

	var/scanline_timer
	///Bool to check if the scanner's controls are locked by an ID.
	var/locked = FALSE
	///Which setting is the scanner checking for? See defines in scanner_gate.dm for the list.
	var/scangate_mode = SCANGATE_NONE
	///Is searching for a disease, what severity is enough to trigger the gate?
	var/disease_threshold = DISEASE_SEVERITY_MINOR
	///If scanning for a specific species, what species is it looking for?
	var/detect_species_id = SPECIES_HUMAN
	///Flips all scan results for inverse scanning. Signals if scan returns false.
	var/reverse = FALSE
	///If scanning for nutrition, what level of nutrition will trigger the scanner?
	var/detect_nutrition = NUTRITION_LEVEL_FAT
	///Will the assembly on the pass wire activate if the scanner resolves green (Pass) on crossing?
	var/light_pass = FALSE
	///Will the assembly on the pass wire activate if the scanner resolves red (fail) on crossing?
	var/light_fail = FALSE
	///Does the scanner ignore light_pass and light_fail for sending signals?
	var/ignore_signals = FALSE
	///Modifier to the chance of scanner being false positive/negative
	var/minus_false_beep = 0
	///Base false positive/negative chance
	var/base_false_beep = 5
	///List of species that can be scanned by the gate. Supports adding more species' IDs during in-game.
	var/static/list/available_species = list(
		SPECIES_HUMAN,
		SPECIES_LIZARD,
		SPECIES_FLYPERSON,
		SPECIES_FELINE,
		SPECIES_PLASMAMAN,
		SPECIES_MOTH,
		SPECIES_JELLYPERSON,
		SPECIES_PODPERSON,
		SPECIES_GOLEM,
		SPECIES_ZOMBIE,
	)
	/// All scan modes available to the scanner
	var/static/list/all_modes = list(
		SCANGATE_NONE,
		SCANGATE_MINDSHIELD,
		SCANGATE_DISEASE,
		SCANGATE_GUNS,
		SCANGATE_WANTED,
		SCANGATE_SPECIES,
		SCANGATE_NUTRITION,
	)
	/// All disease severity thresholds available to the scanner
	var/static/list/all_disease_thresholds = list(
		DISEASE_SEVERITY_POSITIVE,
		DISEASE_SEVERITY_NONTHREAT,
		DISEASE_SEVERITY_MINOR,
		DISEASE_SEVERITY_MEDIUM,
		DISEASE_SEVERITY_HARMFUL,
		DISEASE_SEVERITY_DANGEROUS,
		DISEASE_SEVERITY_BIOHAZARD,
	)
	/// All nutrition levels available to the scanner
	var/static/list/nutrition_modes = list(
		"Starving",
		"Obese",
	)
	/// Overlay object we're using for scanlines
	var/obj/effect/overlay/scanline = null

/obj/machinery/scanner_gate/Initialize(mapload)
	. = ..()
	set_wires(new /datum/wires/scanner_gate(src))
	set_scanline("passive")
	var/static/list/loc_connections = list(
		COMSIG_ATOM_ENTERED = PROC_REF(on_entered),
	)
	AddElement(/datum/element/connect_loc, loc_connections)
	register_context()

/obj/machinery/scanner_gate/Destroy(force)
	QDEL_NULL(scanline)
	return ..()

/obj/machinery/scanner_gate/RefreshParts()
	. = ..()
	for(var/datum/stock_part/scanning_module/scanning_module in component_parts)
		minus_false_beep = scanning_module.tier //The better are scanninning modules - the lower is chance of False Positives

/obj/machinery/scanner_gate/examine(mob/user)
	. = ..()

	. += span_notice("It's set to scan for [span_boldnotice(scangate_mode)].")
	if(locked)
		. += span_notice("The control panel is ID-locked. Swipe a valid ID to unlock it.")
	else
		. += span_notice("The control panel is unlocked. Swipe an ID to lock it.")

/obj/machinery/scanner_gate/proc/on_entered(datum/source, atom/movable/thing)
	SIGNAL_HANDLER
	INVOKE_ASYNC(src, PROC_REF(auto_scan), thing)

/obj/machinery/scanner_gate/proc/auto_scan(atom/movable/thing)
	if(!(machine_stat & (BROKEN|NOPOWER)) && anchored && !panel_open)
		perform_scan(thing)

/obj/machinery/scanner_gate/proc/set_scanline(scanline_type, duration)
	if (!isnull(scanline))
		vis_contents -= scanline
	else
		scanline = new(src)
		scanline.icon = icon
		scanline.mouse_opacity = MOUSE_OPACITY_TRANSPARENT
		scanline.layer = layer
	deltimer(scanline_timer)
	if (isnull(scanline_type))
		if(duration)
			scanline_timer = addtimer(CALLBACK(src, PROC_REF(set_scanline), "passive"), duration, TIMER_STOPPABLE)
		return
	scanline.icon_state = scanline_type
	vis_contents += scanline
	if(duration)
		scanline_timer = addtimer(CALLBACK(src, PROC_REF(set_scanline), "passive"), duration, TIMER_STOPPABLE)

/obj/machinery/scanner_gate/power_change()
	. = ..()
	if (machine_stat & (NOPOWER | BROKEN))
		set_scanline(null)
		return
	set_scanline("passive")

/obj/machinery/scanner_gate/attackby(obj/item/attacking_item, mob/user, params)
	var/obj/item/card/id/card = attacking_item.GetID()
	if(card)
		if(locked)
			if(allowed(user))
				locked = FALSE
				req_access = list()
				to_chat(user, span_notice("You unlock [src]."))
		else if(!(obj_flags & EMAGGED))
			to_chat(user, span_notice("You lock [src] with [attacking_item]."))
			var/list/access = attacking_item.GetAccess()
			req_access = access
			locked = TRUE
		else
			to_chat(user, span_warning("You try to lock [src] with [attacking_item], but nothing happens."))
	else
		if(!locked && default_deconstruction_screwdriver(user, "[initial(icon_state)]_open", initial(icon_state), attacking_item))
			return
		if(panel_open && is_wire_tool(attacking_item))
			wires.interact(user)
	return ..()

/obj/machinery/scanner_gate/emag_act(mob/user, obj/item/card/emag/emag_card)
	if(obj_flags & EMAGGED)
		return FALSE
	locked = FALSE
	req_access = list()
	obj_flags |= EMAGGED
	balloon_alert(user, "id checker disabled")
	return TRUE

/obj/machinery/scanner_gate/proc/perform_scan(atom/movable/thing)
	var/beep = FALSE
	var/color = null
	var/detected_thing = null
	var/bypassed = FALSE
	playsound(src, SFX_INDUSTRIAL_SCAN, 20, TRUE, -2, TRUE, FALSE)
	switch(scangate_mode)
		if(SCANGATE_NONE)
			return
		if(SCANGATE_WANTED)
			if(ishuman(thing))
				detected_thing = "Warrant"
				var/mob/living/carbon/human/scanned_human = thing
				var/perpname = scanned_human.get_face_name(scanned_human.get_id_name())
				var/datum/record/crew/target = find_record(perpname)
				if(!target || (target.wanted_status == WANTED_ARREST))
					beep = TRUE
		if(SCANGATE_MINDSHIELD)
			detected_thing = "Mindshield"
			if(ishuman(thing))
				var/mob/living/carbon/human/scanned_human = thing
				if(HAS_TRAIT(scanned_human, TRAIT_MINDSHIELD))
					beep = TRUE
		if(SCANGATE_DISEASE)
			detected_thing = "[disease_threshold] infection"
			if(iscarbon(thing))
				var/mob/living/carbon/scanned_carbon = thing
				if(get_disease_severity_value(scanned_carbon.check_virus()) >= get_disease_severity_value(disease_threshold))
					beep = TRUE
		if(SCANGATE_SPECIES)
			if(ishuman(thing))
				var/mob/living/carbon/human/scanned_human = thing
				var/datum/species/scan_species = /datum/species/human
				if(detect_species_id && (detect_species_id in available_species))
					scan_species = GLOB.species_list[detect_species_id]
					detected_thing = scan_species.name
				if(is_species(scanned_human, scan_species))
					beep = TRUE
				if(detect_species_id == SPECIES_ZOMBIE) //Can detect dormant zombies
					detected_thing = "Romerol infection"
					if(scanned_human.get_organ_slot(ORGAN_SLOT_ZOMBIE))
						beep = TRUE
		if(SCANGATE_GUNS)
			detected_thing = "Weapons"
			if(isgun(thing))
				beep = TRUE
			else if(ishuman(thing))
				var/mob/living/carbon/human/scanned_human = thing
				var/obj/item/card/id/idcard = scanned_human.get_idcard(hand_first = FALSE)
				for(var/obj/item/scanned_item in scanned_human.get_all_contents_skipping_traits(TRAIT_CONTRABAND_BLOCKER))
					if(isgun(scanned_item))
						if((!HAS_TRAIT(scanned_human, TRAIT_MINDSHIELD)) && (isnull(idcard) || !(ACCESS_WEAPONS in idcard.access))) // mindshield or ID card with weapons access, like bartender
							beep = TRUE
							break
						bypassed = TRUE
						break
			else
				for(var/obj/item/content in thing.get_all_contents_skipping_traits(TRAIT_CONTRABAND_BLOCKER))
					if(isgun(content))
						beep = TRUE
						break
		if(SCANGATE_NUTRITION)
			if(ishuman(thing))
				var/mob/living/carbon/human/scanned_human = thing
				if(scanned_human.nutrition <= detect_nutrition && detect_nutrition == NUTRITION_LEVEL_STARVING)
					beep = TRUE
					detected_thing = "Starvation"
				if(scanned_human.nutrition >= detect_nutrition && detect_nutrition == NUTRITION_LEVEL_FAT)
					beep = TRUE
					detected_thing = "Obesity"

	if(reverse)
		beep = !beep

	if(prob(base_false_beep - minus_false_beep)) //False positive/negative
		beep = prob(50)

	if(beep)
		alarm_beep(detected_thing)
		SEND_SIGNAL(src, COMSIG_SCANGATE_PASS_TRIGGER, thing)
		if(!ignore_signals)
			color = wires.get_color_of_wire(WIRE_ACCEPT)
			var/obj/item/assembly/assembly = wires.get_attached(color)
			assembly?.activate()
	else
		SEND_SIGNAL(src, COMSIG_SCANGATE_PASS_NO_TRIGGER, thing)
		if(bypassed)
			say("[detected_thing] detection bypassed.")
		if(!ignore_signals)
			color = wires.get_color_of_wire(WIRE_DENY)
			var/obj/item/assembly/assembly = wires.get_attached(color)
			assembly?.activate()
		set_scanline("scanning", 1 SECONDS)

	use_energy(active_power_usage)

/obj/machinery/scanner_gate/proc/alarm_beep(detected_thing)
	if(!COOLDOWN_FINISHED(src, next_beep))
		return

	if(detected_thing)
		say("[detected_thing][reverse ? " not " : " "]detected!!")

	COOLDOWN_START(src, next_beep, 2 SECONDS)
	playsound(source = src, soundin = 'sound/machines/scanner/scanbuzz.ogg', vol = 30, vary = FALSE, extrarange = MEDIUM_RANGE_SOUND_EXTRARANGE, falloff_distance = 4)
	set_scanline("alarm", 2 SECONDS)

/obj/machinery/scanner_gate/can_interact(mob/user)
	if(locked)
		return FALSE
	return ..()

/obj/machinery/scanner_gate/ui_interact(mob/user, datum/tgui/ui)
	ui = SStgui.try_update_ui(user, src, ui)
	if(!ui)
		ui = new(user, src, "ScannerGate", name)
		ui.open()

/obj/machinery/scanner_gate/ui_static_data(mob/user)
	. = ..()
	for(var/species_id in available_species)
		var/datum/species/specie = GLOB.species_list[species_id]
		.["available_species"] += list(list(
			"specie_name" = capitalize(format_text(specie.name)),
			"specie_id" = species_id,
		))

/obj/machinery/scanner_gate/ui_data()
	var/list/data = list()
	data["locked"] = locked
	data["scan_mode"] = scangate_mode
	data["reverse"] = reverse
	data["disease_threshold"] = disease_threshold
	data["target_species_id"] = detect_species_id
	data["target_nutrition"] = detect_nutrition
	data["target_zombie"] = (detect_species_id == SPECIES_ZOMBIE)
	return data

/obj/machinery/scanner_gate/ui_act(action, list/params, datum/tgui/ui, datum/ui_state/state)
	. = ..()
	if(.)
		return

	switch(action)
		if("set_mode")
			var/new_mode = params["new_mode"]
			if(!new_mode || !(new_mode in all_modes))
				return
			scangate_mode = new_mode
			. = TRUE
		if("toggle_reverse")
			reverse = !reverse
			. = TRUE
		if("toggle_lock")
			if(allowed(usr))
				locked = !locked
			. = TRUE
		if("set_disease_threshold")
			var/new_threshold = params["new_threshold"]
			if(!new_threshold || !(new_threshold in all_disease_thresholds))
				return
			disease_threshold = new_threshold
			. = TRUE
		if("set_target_species")
			var/new_specie_id = params["new_species_id"]
			if(!new_specie_id || !(new_specie_id in available_species))
				return
			detect_species_id = new_specie_id
			. = TRUE
		if("set_target_nutrition")
			var/new_nutrition = params["new_nutrition"]
			if(!new_nutrition || !(new_nutrition in nutrition_modes))
				return
			switch(new_nutrition)
				if("Starving")
					detect_nutrition = NUTRITION_LEVEL_STARVING
				if("Obese")
					detect_nutrition = NUTRITION_LEVEL_FAT
			. = TRUE

/obj/machinery/scanner_gate/preset_guns
	locked = TRUE
	req_access = list(ACCESS_SECURITY)
	scangate_mode = SCANGATE_GUNS

#undef SCANGATE_NONE
#undef SCANGATE_MINDSHIELD
#undef SCANGATE_DISEASE
#undef SCANGATE_GUNS
#undef SCANGATE_WANTED
#undef SCANGATE_SPECIES
#undef SCANGATE_NUTRITION
