/obj/item/grenade/chem_grenade
	name = "chemical grenade"
	desc = "A custom made grenade."
	icon_state = "chemg"
	base_icon_state = "chemg"
	inhand_icon_state = "flashbang"
	w_class = WEIGHT_CLASS_SMALL
	force = 2
	/// Which stage of construction this grenade is currently at.
	var/stage = GRENADE_EMPTY
	/// The set of reagent containers that have been added to this grenade casing.
	var/list/obj/item/reagent_containers/cup/beakers = list()
	/// The types of reagent containers that can be added to this grenade casing.
	var/list/allowed_containers = list(/obj/item/reagent_containers/cup/beaker, /obj/item/reagent_containers/cup/bottle)
	/// The types of reagent containers that can't be added to this grenade casing.
	var/list/banned_containers = list(/obj/item/reagent_containers/cup/beaker/bluespace) //Containers to exclude from specific grenade subtypes
	/// The maximum volume of the reagents in the grenade casing.
	var/casing_holder_volume = 1000
	/// The range that this grenade can splash reagents at if they aren't consumed on detonation.
	var/affected_area = 3
	/// The amount of temperature that is added to the reagents on detonation.
	var/ignition_temp = 10
	/// How much to scale the reagents by when the grenade detonates. Used by advanced grenades to make them slightly more worthy.
	var/threatscale = 1
	/// The description when examining empty casings.
	var/casedesc = "This basic model accepts both beakers and bottles. It heats contents by 10 K upon ignition."
	/// Whether or not the grenade is currently acting as a landmine. Currently broken and not my current project.
	var/obj/item/assembly/prox_sensor/landminemode = null

/obj/item/grenade/chem_grenade/Initialize(mapload)
	. = ..()
	AddElement(/datum/element/empprotection, EMP_PROTECT_WIRES)
	create_reagents(casing_holder_volume)
	stage_change() // If no argument is set, it will change the stage to the current stage, useful for stock grenades that start READY.
	set_wires(new /datum/wires/explosive/chem_grenade(src))

/obj/item/grenade/chem_grenade/Destroy(force)
	QDEL_NULL(landminemode)
	QDEL_LIST(beakers)
	return ..()

/obj/item/grenade/chem_grenade/apply_grenade_fantasy_bonuses(quality)
	threatscale = modify_fantasy_variable("threatscale", threatscale, quality/10)

/obj/item/grenade/chem_grenade/remove_grenade_fantasy_bonuses(quality)
	threatscale = reset_fantasy_variable("threatscale", threatscale)

/obj/item/grenade/chem_grenade/examine(mob/user)
	display_timer = (stage == GRENADE_READY) //show/hide the timer based on assembly state
	. = ..()
	if(user.can_see_reagents())
		if(beakers.len)
			. += span_notice("You scan the grenade and detect the following reagents:")
			for(var/obj/item/reagent_containers/cup/glass_beaker in beakers)
				for(var/datum/reagent/reagent in glass_beaker.reagents.reagent_list)
					. += span_notice("[reagent.volume] units of [reagent.name] in \the [glass_beaker].")
			if(beakers.len == 1)
				. += span_notice("You detect no second beaker in the grenade.")
		else
			. += span_notice("You scan the grenade, but detect nothing.")
	else if(stage != GRENADE_READY && beakers.len)
		if(beakers.len == 2 && beakers[1].name == beakers[2].name)
			. += span_notice("You see two [beakers[1].name]s inside the grenade.")
		else
			for(var/obj/item/reagent_containers/cup/glass_beaker in beakers)
				. += span_notice("You see a [glass_beaker.name] inside the grenade.")

/obj/item/grenade/chem_grenade/update_name(updates)
	switch(stage)
		if(GRENADE_EMPTY)
			name = "[initial(name)] casing"
		if(GRENADE_WIRED)
			name = "unsecured [initial(name)]"
		if(GRENADE_READY)
			name = initial(name)
	return ..()

/obj/item/grenade/chem_grenade/update_desc(updates)
	switch(stage)
		if(GRENADE_EMPTY)
			desc = "A do it yourself [initial(name)]! [initial(casedesc)]"
		if(GRENADE_WIRED)
			desc = "An unsecured [initial(name)] assembly."
		if(GRENADE_READY)
			desc = initial(desc)
	return ..()


/obj/item/grenade/chem_grenade/update_icon_state()
	if(active)
		icon_state = "[base_icon_state]_active"
		return ..()

	switch(stage)
		if(GRENADE_EMPTY)
			icon_state = base_icon_state
		if(GRENADE_WIRED)
			icon_state = "[base_icon_state]_ass"
		if(GRENADE_READY)
			icon_state = "[base_icon_state]_locked"
	return ..()


/obj/item/grenade/chem_grenade/attack_self(mob/user)
	if(stage == GRENADE_READY && !active)
		..()
	if(stage == GRENADE_WIRED)
		wires.interact(user)

/obj/item/grenade/chem_grenade/screwdriver_act(mob/living/user, obj/item/tool)
	. = TRUE
	if(dud_flags & GRENADE_USED)
		balloon_alert(user, "resetting trigger...")
		if (do_after(user, 2 SECONDS, src))
			balloon_alert(user, "trigger reset")
			dud_flags &= ~GRENADE_USED
		return

	if(stage == GRENADE_WIRED)
		if(beakers.len)
			stage_change(GRENADE_READY)
			to_chat(user, span_notice("You lock the [initial(name)] assembly."))
			tool.play_tool_sound(src, 25)
		else if(landminemode)
			landminemode.timing = FALSE
			if(!landminemode.secured)
				landminemode.toggle_secure()
			landminemode.toggle_scan(FALSE)
			to_chat(user, span_notice("You disarm \the [landminemode]."))
			tool.play_tool_sound(src, 25)
		else
			to_chat(user, span_warning("You need to add at least one beaker before locking the [initial(name)] assembly!"))
	else if(stage == GRENADE_READY)
		det_time = det_time == 50 ? 30 : 50 //toggle between 30 and 50
		if(landminemode)
			landminemode.time = det_time * 0.1 //overwrites the proxy sensor activation timer
		tool.play_tool_sound(src, 25)
		to_chat(user, span_notice("You modify the time delay. It's set for [DisplayTimeText(det_time)]."))
	else
		to_chat(user, span_warning("You need to add a wire!"))

	return TRUE

/obj/item/grenade/chem_grenade/wirecutter_act(mob/living/user, obj/item/tool)
	if(stage == GRENADE_READY && !active)
		tool.play_tool_sound(src)
		stage_change(GRENADE_WIRED)
		to_chat(user, span_notice("You unlock the [initial(name)] assembly."))
		return TRUE

/obj/item/grenade/chem_grenade/wrench_act(mob/living/user, obj/item/tool)
	if(stage != GRENADE_WIRED)
		return FALSE
	if(beakers.len)
		for(var/obj/beaker in beakers)
			beaker.forceMove(drop_location())
			if(!beaker.reagents)
				continue
			var/reagent_list = pretty_string_from_reagent_list(beaker.reagents.reagent_list)
			user.log_message("removed [beaker] ([reagent_list]) from [src]", LOG_GAME)
		beakers = list()
		to_chat(user, span_notice("You open the [initial(name)] assembly and remove the payload."))
		return
	tool.play_tool_sound(src)
	wires.detach_assembly(wires.get_wire(1))
	new /obj/item/stack/cable_coil(get_turf(src), 1)
	stage_change(GRENADE_EMPTY)
	to_chat(user, span_notice("You remove the activation mechanism from the [initial(name)] assembly."))

/obj/item/grenade/chem_grenade/attackby(obj/item/item, mob/user, params)
	if(isassembly(item) && stage == GRENADE_WIRED)
		wires.interact(user)
	else if(stage == GRENADE_WIRED && is_type_in_list(item, allowed_containers))
		. = TRUE //no afterattack
		if(is_type_in_list(item, banned_containers))
			to_chat(user, span_warning("[src] is too small to fit [item]!")) // this one hits home huh anon?
			return
		if(beakers.len == 2)
			to_chat(user, span_warning("[src] can not hold more containers!"))
			return
		else
			if(item.reagents.total_volume)
				if(!user.transferItemToLoc(item, src))
					return
				to_chat(user, span_notice("You add [item] to the [initial(name)] assembly."))
				beakers += item
				var/reagent_list = pretty_string_from_reagent_list(item.reagents.reagent_list)
				user.log_message("inserted [item] ([reagent_list]) into [src]", LOG_GAME)
			else
				to_chat(user, span_warning("[item] is empty!"))

	else if(stage == GRENADE_EMPTY && istype(item, /obj/item/stack/cable_coil))
		var/obj/item/stack/cable_coil/coil = item
		if (coil.use(1))
			det_time = 50 // In case the cable_coil was removed and readded.
			stage_change(GRENADE_WIRED)
			to_chat(user, span_notice("You rig the [initial(name)] assembly."))
		else
			to_chat(user, span_warning("You need one length of coil to wire the assembly!"))
			return
	else
		return ..()

/obj/item/grenade/chem_grenade/proc/stage_change(N)
	if(N)
		stage = N
	update_appearance()

/obj/item/grenade/chem_grenade/on_found(mob/finder)
	var/obj/item/assembly/assembly = wires.get_attached(wires.get_wire(1))
	assembly?.on_found(finder)

/obj/item/grenade/chem_grenade/log_grenade(mob/user)
	var/reagent_string = ""
	var/beaker_number = 1
	for(var/obj/exploded_beaker in beakers)
		if(!exploded_beaker.reagents)
			continue
		reagent_string += " ([exploded_beaker.name] [beaker_number++] : " + pretty_string_from_reagent_list(exploded_beaker.reagents.reagent_list) + ");"
	if(landminemode)
		log_bomber(user, "activated a proxy", src, "containing:[reagent_string]", message_admins = !dud_flags)
	else
		log_bomber(user, "primed a", src, "containing:[reagent_string]", message_admins = !dud_flags)

/obj/item/grenade/chem_grenade/arm_grenade(mob/user, delayoverride, msg = TRUE, volume = 60)
	log_grenade(user) //Inbuilt admin procs already handle null users
	if(user)
		add_fingerprint(user)
		if(msg)
			if(landminemode)
				to_chat(user, span_warning("You prime [src], activating its proximity sensor."))
			else
				to_chat(user, span_warning("You prime [src]! [DisplayTimeText(det_time)]!"))

	active = TRUE
	update_icon_state()
	playsound(src, grenade_arm_sound, volume, grenade_sound_vary)
	if(landminemode)
		landminemode.activate()
		return
	addtimer(CALLBACK(src, PROC_REF(detonate)), isnull(delayoverride)? det_time : delayoverride)

/obj/item/grenade/chem_grenade/detonate(mob/living/lanced_by)
	if(stage != GRENADE_READY)
		return

	. = ..()
	if(!.)
		return

	var/list/datum/reagents/reactants = list()
	for(var/obj/item/reagent_containers/cup/glass_beaker in beakers)
		reactants += glass_beaker.reagents

	var/turf/detonation_turf = get_turf(src)
	if (chem_splash(detonation_turf, reagents, affected_area, reactants, ignition_temp, threatscale))
		// logs from custom assemblies priming are handled by the wire component
		log_game("A grenade detonated at [AREACOORD(detonation_turf)]")

	active = FALSE
	update_appearance()


//Large chem grenades accept slime cores and use the appropriately.
/obj/item/grenade/chem_grenade/large
	name = "large grenade"
	desc = "A custom made large grenade. Larger splash range and increased ignition temperature compared to basic grenades. Fits exotic and bluespace based containers."
	casedesc = "This casing affects a larger area than the basic model and can fit exotic containers, including slime cores and bluespace beakers. Heats contents by 25 K upon ignition."
	icon_state = "large_grenade"
	base_icon_state = "large_grenade"
	allowed_containers = list(/obj/item/reagent_containers/cup, /obj/item/reagent_containers/condiment, /obj/item/reagent_containers/cup/glass)
	banned_containers = list()
	affected_area = 5
	ignition_temp = 25 // Large grenades are slightly more effective at setting off heat-sensitive mixtures than smaller grenades.
	threatscale = 1.1 // 10% more effective.

/obj/item/grenade/chem_grenade/large/detonate(mob/living/lanced_by)
	if(stage != GRENADE_READY || dud_flags)
		active = FALSE
		update_appearance()
		return FALSE


	var/extract_total_volume = 0
	var/extract_maximum_volume = 0
	var/list/extracts = list()

	var/beaker_total_volume = 0
	var/list/other_containers = list()

	for(var/obj/item/thing as anything in beakers)
		if(!thing.reagents)
			continue

		if(istype(thing, /obj/item/slime_extract))
			var/obj/item/slime_extract/extract = thing
			if(!extract.extract_uses)
				continue

			extract_total_volume += extract.reagents.total_volume
			extract_maximum_volume += extract.reagents.maximum_volume
			extracts += extract
		else
			beaker_total_volume += thing.reagents.total_volume
			other_containers += thing


	var/available_extract_volume = extract_maximum_volume - extract_total_volume
	if(beaker_total_volume <= 0 || available_extract_volume <= 0)
		return ..()

	var/container_ratio = available_extract_volume / beaker_total_volume
	var/datum/reagents/tmp_holder = new/datum/reagents(beaker_total_volume)
	for(var/obj/item/container as anything in other_containers)
		container.reagents.trans_to(tmp_holder, container.reagents.total_volume * container_ratio, no_react = TRUE)

	for(var/obj/item/slime_extract/extract as anything in extracts)
		var/available_volume = extract.reagents.maximum_volume - extract.reagents.total_volume
		tmp_holder.trans_to(extract, beaker_total_volume * (available_volume / available_extract_volume), no_react = TRUE)

		extract.reagents.handle_reactions() // Reaction handling in the transfer proc is reciprocal and we don't want to blow up the tmp holder early.
		if(QDELETED(extract))
			beakers -= extract
			extracts -= extract

	return ..()

	//I tried to just put it in the allowed_containers list but
	//if you do that it must have reagents.  If you're going to
	//make a special case you might as well do it explicitly. -Sayu
/obj/item/grenade/chem_grenade/large/attackby(obj/item/item, mob/user, params)
	if(!istype(item, /obj/item/slime_extract) || stage != GRENADE_WIRED)
		return ..()

	if(!user.transferItemToLoc(item, src))
		return
	to_chat(user, span_notice("You add [item] to the [initial(name)] assembly."))
	beakers += item

/obj/item/grenade/chem_grenade/cryo // Intended for rare cryogenic mixes. Cools the area moderately upon detonation.
	name = "cryo grenade"
	desc = "A custom made cryogenic grenade. Rapidly cools contents upon ignition."
	casedesc = "Upon ignition, it rapidly cools contents by 100 K. Smaller splash range than regular casings."
	icon_state = "cryog"
	base_icon_state = "cryog"
	affected_area = 2
	ignition_temp = -100

/obj/item/grenade/chem_grenade/pyro // Intended for pyrotechnical mixes. Produces a small fire upon detonation, igniting potentially flammable mixtures.
	name = "pyro grenade"
	desc = "A custom made pyrotechnical grenade. Heats up contents upon ignition."
	casedesc = "Upon ignition, it rapidly heats contents by 500 K."
	icon_state = "pyrog"
	base_icon_state = "pyrog"
	ignition_temp = 500 // This is enough to expose a hotspot.

/obj/item/grenade/chem_grenade/adv_release // Intended for weaker, but longer lasting effects. Could have some interesting uses.
	name = "advanced release grenade"
	desc = "A custom made advanced release grenade. It is able to be detonated more than once. Can be configured using a multitool."
	casedesc = "This casing is able to detonate more than once. Can be configured using a multitool."
	icon_state = "timeg"
	base_icon_state = "timeg"
	var/unit_spread = 10 // Amount of units per repeat. Can be altered with a multitool.

/obj/item/grenade/chem_grenade/adv_release/multitool_act(mob/living/user, obj/item/tool)
	if (active)
		return
	var/newspread = tgui_input_number(user, "Please enter a new spread amount", "Grenade Spread", 5, 100, 5)
	if(!newspread || QDELETED(user) || QDELETED(src) || !usr.can_perform_action(src, FORBID_TELEKINESIS_REACH))
		return
	unit_spread = newspread
	to_chat(user, span_notice("You set the time release to [unit_spread] units per detonation."))
	..()

/obj/item/grenade/chem_grenade/adv_release/detonate(mob/living/lanced_by)
	if(stage != GRENADE_READY || dud_flags)
		active = FALSE
		update_appearance()
		return

	var/total_volume = 0
	for(var/obj/item/reagent_containers/reagent_container in beakers)
		total_volume += reagent_container.reagents.total_volume
	if(!total_volume)
		active = FALSE
		update_appearance()
		return
	var/fraction = unit_spread/total_volume
	var/datum/reagents/reactants = new(unit_spread)
	reactants.my_atom = src
	for(var/obj/item/reagent_containers/reagent_container in beakers)
		reagent_container.reagents.trans_to(
			reactants,
			reagent_container.reagents.total_volume * fraction,
			threatscale,
			no_react = TRUE
		)
	chem_splash(get_turf(src), reagents, affected_area, list(reactants), ignition_temp, threatscale)

	var/turf/detonated_turf = get_turf(src)
	addtimer(CALLBACK(src, PROC_REF(detonate)), det_time)
	log_game("A grenade detonated at [AREACOORD(detonated_turf)]")




//////////////////////////////
////// PREMADE GRENADES //////
//////////////////////////////

/obj/item/grenade/chem_grenade/metalfoam
	name = "metal foam grenade"
	desc = "Used for emergency sealing of hull breaches."
	stage = GRENADE_READY

/obj/item/grenade/chem_grenade/metalfoam/Initialize(mapload)
	. = ..()
	var/obj/item/reagent_containers/cup/beaker/beaker_one = new(src)
	var/obj/item/reagent_containers/cup/beaker/beaker_two = new(src)

	beaker_one.reagents.add_reagent(/datum/reagent/aluminium, 30)
	beaker_two.reagents.add_reagent(/datum/reagent/foaming_agent, 10)
	beaker_two.reagents.add_reagent(/datum/reagent/toxin/acid/fluacid, 10)

	beakers += beaker_one
	beakers += beaker_two


/obj/item/grenade/chem_grenade/smart_metal_foam
	name = "smart metal foam grenade"
	desc = "Used for emergency sealing of hull breaches, while keeping areas accessible."
	stage = GRENADE_READY

/obj/item/grenade/chem_grenade/smart_metal_foam/Initialize(mapload)
	. = ..()
	var/obj/item/reagent_containers/cup/beaker/large/beaker_one = new(src)
	var/obj/item/reagent_containers/cup/beaker/beaker_two = new(src)

	beaker_one.reagents.add_reagent(/datum/reagent/aluminium, 75)
	beaker_two.reagents.add_reagent(/datum/reagent/smart_foaming_agent, 25)
	beaker_two.reagents.add_reagent(/datum/reagent/toxin/acid/fluacid, 25)

	beakers += beaker_one
	beakers += beaker_two


/obj/item/grenade/chem_grenade/incendiary
	name = "incendiary grenade"
	desc = "Used for clearing rooms of living things."
	stage = GRENADE_READY

/obj/item/grenade/chem_grenade/incendiary/Initialize(mapload)
	. = ..()
	var/obj/item/reagent_containers/cup/beaker/beaker_one = new(src)
	var/obj/item/reagent_containers/cup/beaker/beaker_two = new(src)

	beaker_one.reagents.add_reagent(/datum/reagent/phosphorus, 25)
	beaker_two.reagents.add_reagent(/datum/reagent/stable_plasma, 25)
	beaker_two.reagents.add_reagent(/datum/reagent/toxin/acid, 25)

	beakers += beaker_one
	beakers += beaker_two


/obj/item/grenade/chem_grenade/antiweed
	name = "weedkiller grenade"
	desc = "Used for purging large areas of invasive plant species. Contents under pressure. Do not directly inhale contents."
	stage = GRENADE_READY

/obj/item/grenade/chem_grenade/antiweed/Initialize(mapload)
	. = ..()
	var/obj/item/reagent_containers/cup/beaker/beaker_one = new(src)
	var/obj/item/reagent_containers/cup/beaker/beaker_two = new(src)

	beaker_one.reagents.add_reagent(/datum/reagent/toxin/plantbgone, 25)
	beaker_one.reagents.add_reagent(/datum/reagent/potassium, 25)
	beaker_two.reagents.add_reagent(/datum/reagent/phosphorus, 25)
	beaker_two.reagents.add_reagent(/datum/reagent/consumable/sugar, 25)

	beakers += beaker_one
	beakers += beaker_two


/obj/item/grenade/chem_grenade/cleaner
	name = "cleaner grenade"
	desc = "BLAM!-brand foaming space cleaner. In a special applicator for rapid cleaning of wide areas."
	stage = GRENADE_READY

/obj/item/grenade/chem_grenade/cleaner/Initialize(mapload)
	. = ..()
	var/obj/item/reagent_containers/cup/beaker/beaker_one = new(src)
	var/obj/item/reagent_containers/cup/beaker/beaker_two = new(src)

	beaker_one.reagents.add_reagent(/datum/reagent/fluorosurfactant, 40)
	beaker_two.reagents.add_reagent(/datum/reagent/water, 40)
	beaker_two.reagents.add_reagent(/datum/reagent/space_cleaner, 10)

	beakers += beaker_one
	beakers += beaker_two


/obj/item/grenade/chem_grenade/ez_clean
	name = "cleaner grenade"
	desc = "Waffle Corp. brand foaming space cleaner. In a special applicator for rapid cleaning of wide areas."
	stage = GRENADE_READY

/obj/item/grenade/chem_grenade/ez_clean/Initialize(mapload)
	. = ..()
	var/obj/item/reagent_containers/cup/beaker/large/beaker_one = new(src)
	var/obj/item/reagent_containers/cup/beaker/large/beaker_two = new(src)

	beaker_one.reagents.add_reagent(/datum/reagent/fluorosurfactant, 40)
	beaker_two.reagents.add_reagent(/datum/reagent/water, 40)
	beaker_two.reagents.add_reagent(/datum/reagent/space_cleaner/ez_clean, 60) //ensures a  t h i c c  distribution

	beakers += beaker_one
	beakers += beaker_two



/obj/item/grenade/chem_grenade/teargas
	name = "teargas grenade"
	desc = "Used for nonlethal riot control. Contents under pressure. Do not directly inhale contents."
	stage = GRENADE_READY

/obj/item/grenade/chem_grenade/teargas/Initialize(mapload)
	. = ..()
	var/obj/item/reagent_containers/cup/beaker/large/beaker_one = new(src)
	var/obj/item/reagent_containers/cup/beaker/large/beaker_two = new(src)

	beaker_one.reagents.add_reagent(/datum/reagent/consumable/condensedcapsaicin, 60)
	beaker_one.reagents.add_reagent(/datum/reagent/potassium, 40)
	beaker_two.reagents.add_reagent(/datum/reagent/phosphorus, 40)
	beaker_two.reagents.add_reagent(/datum/reagent/consumable/sugar, 40)

	beakers += beaker_one
	beakers += beaker_two


/obj/item/grenade/chem_grenade/facid
	name = "acid grenade"
	desc = "Used for melting armoured opponents."
	stage = GRENADE_READY

/obj/item/grenade/chem_grenade/facid/Initialize(mapload)
	. = ..()
	var/obj/item/reagent_containers/cup/beaker/bluespace/beaker_one = new(src)
	var/obj/item/reagent_containers/cup/beaker/bluespace/beaker_two = new(src)

	beaker_one.reagents.add_reagent(/datum/reagent/toxin/acid/fluacid, 290)
	beaker_one.reagents.add_reagent(/datum/reagent/potassium, 10)
	beaker_two.reagents.add_reagent(/datum/reagent/phosphorus, 10)
	beaker_two.reagents.add_reagent(/datum/reagent/consumable/sugar, 10)
	beaker_two.reagents.add_reagent(/datum/reagent/toxin/acid/fluacid, 280)

	beakers += beaker_one
	beakers += beaker_two


/obj/item/grenade/chem_grenade/colorful
	name = "colorful grenade"
	desc = "Used for wide scale painting projects."
	stage = GRENADE_READY

/obj/item/grenade/chem_grenade/colorful/Initialize(mapload)
	. = ..()
	var/obj/item/reagent_containers/cup/beaker/beaker_one = new(src)
	var/obj/item/reagent_containers/cup/beaker/beaker_two = new(src)

	beaker_one.reagents.add_reagent(/datum/reagent/colorful_reagent, 25)
	beaker_one.reagents.add_reagent(/datum/reagent/potassium, 25)
	beaker_two.reagents.add_reagent(/datum/reagent/phosphorus, 25)
	beaker_two.reagents.add_reagent(/datum/reagent/consumable/sugar, 25)

	beakers += beaker_one
	beakers += beaker_two

/obj/item/grenade/chem_grenade/glitter
	name = "generic glitter grenade"
	desc = "You shouldn't see this description."
	stage = GRENADE_READY
	var/glitter_type = /datum/reagent/glitter

/obj/item/grenade/chem_grenade/glitter/Initialize(mapload)
	. = ..()
	var/obj/item/reagent_containers/cup/beaker/beaker_one = new(src)
	var/obj/item/reagent_containers/cup/beaker/beaker_two = new(src)

	beaker_one.reagents.add_reagent(glitter_type, 25)
	beaker_one.reagents.add_reagent(/datum/reagent/potassium, 25)
	beaker_two.reagents.add_reagent(/datum/reagent/phosphorus, 25)
	beaker_two.reagents.add_reagent(/datum/reagent/consumable/sugar, 25)

	beakers += beaker_one
	beakers += beaker_two

/obj/item/grenade/chem_grenade/glitter/pink
	name = "pink glitter bomb"
	desc = "For that HOT glittery look."
	glitter_type = /datum/reagent/glitter/pink

/obj/item/grenade/chem_grenade/glitter/blue
	name = "blue glitter bomb"
	desc = "For that COOL glittery look."
	glitter_type = /datum/reagent/glitter/blue

/obj/item/grenade/chem_grenade/glitter/white
	name = "white glitter bomb"
	desc = "For that somnolent glittery look."
	glitter_type = /datum/reagent/glitter/white

/obj/item/grenade/chem_grenade/clf3
	name = "clf3 grenade"
	desc = "BURN!-brand foaming clf3. In a special applicator for rapid purging of wide areas."
	stage = GRENADE_READY

/obj/item/grenade/chem_grenade/clf3/Initialize(mapload)
	. = ..()
	var/obj/item/reagent_containers/cup/beaker/bluespace/beaker_one = new(src)
	var/obj/item/reagent_containers/cup/beaker/bluespace/beaker_two = new(src)

	beaker_one.reagents.add_reagent(/datum/reagent/fluorosurfactant, 250)
	beaker_one.reagents.add_reagent(/datum/reagent/clf3, 50)
	beaker_two.reagents.add_reagent(/datum/reagent/water, 250)
	beaker_two.reagents.add_reagent(/datum/reagent/clf3, 50)

	beakers += beaker_one
	beakers += beaker_two

/obj/item/grenade/chem_grenade/bioterrorfoam
	name = "Bio terror foam grenade"
	desc = "Tiger Cooperative chemical foam grenade. Causes temporary irritation, blindness, confusion, mutism, and mutations to carbon based life forms. Contains additional spore toxin."
	stage = GRENADE_READY

/obj/item/grenade/chem_grenade/bioterrorfoam/Initialize(mapload)
	. = ..()
	var/obj/item/reagent_containers/cup/beaker/bluespace/beaker_one = new(src)
	var/obj/item/reagent_containers/cup/beaker/bluespace/beaker_two = new(src)

	beaker_one.reagents.add_reagent(/datum/reagent/cryptobiolin, 75)
	beaker_one.reagents.add_reagent(/datum/reagent/water, 50)
	beaker_one.reagents.add_reagent(/datum/reagent/toxin/mutetoxin, 50)
	beaker_one.reagents.add_reagent(/datum/reagent/toxin/spore, 75)
	beaker_one.reagents.add_reagent(/datum/reagent/toxin/itching_powder, 50)
	beaker_two.reagents.add_reagent(/datum/reagent/fluorosurfactant, 150)
	beaker_two.reagents.add_reagent(/datum/reagent/toxin/mutagen, 150)
	beakers += beaker_one
	beakers += beaker_two

/obj/item/grenade/chem_grenade/tuberculosis
	name = "Fungal tuberculosis grenade"
	desc = "WARNING: GRENADE WILL RELEASE DEADLY SPORES CONTAINING ACTIVE AGENTS. SEAL SUIT AND AIRFLOW BEFORE USE."
	stage = GRENADE_READY

/obj/item/grenade/chem_grenade/tuberculosis/Initialize(mapload)
	. = ..()
	var/obj/item/reagent_containers/cup/beaker/bluespace/beaker_one = new(src)
	var/obj/item/reagent_containers/cup/beaker/bluespace/beaker_two = new(src)

	beaker_one.reagents.add_reagent(/datum/reagent/potassium, 50)
	beaker_one.reagents.add_reagent(/datum/reagent/phosphorus, 50)
	beaker_one.reagents.add_reagent(/datum/reagent/fungalspores, 200)
	beaker_two.reagents.add_reagent(/datum/reagent/blood, 250)
	beaker_two.reagents.add_reagent(/datum/reagent/consumable/sugar, 50)

	beakers += beaker_one
	beakers += beaker_two

/obj/item/grenade/chem_grenade/holy
	name = "holy hand grenade"
	desc = "A vessel of concentrated religious might."
	icon_state = "holy_grenade"
	base_icon_state = "holy_grenade"
	stage = GRENADE_READY

/obj/item/grenade/chem_grenade/holy/Initialize(mapload)
	. = ..()
	var/obj/item/reagent_containers/cup/beaker/meta/beaker_one = new(src)
	var/obj/item/reagent_containers/cup/beaker/meta/beaker_two = new(src)

	beaker_one.reagents.add_reagent(/datum/reagent/potassium, 150)
	beaker_two.reagents.add_reagent(/datum/reagent/water/holywater, 150)

	beakers += beaker_one
	beakers += beaker_two
