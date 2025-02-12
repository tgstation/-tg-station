/*

	Advance Disease is a system for medical to Engineer their own disease with symptoms that have effects and properties
	which add onto the overall disease.

	If you need help with creating new symptoms or expanding the advance disease, ask for Giacom on #coderbus.

*/




/*

	PROPERTIES

 */

/datum/disease/advance
	name = "Unknown" // We will always let our creator name our disease.
	desc = "An engineered disease which can contain a multitude of symptoms."
	form = "Advanced Disease" // Will let med-scanners know that this disease was engineered.
	agent = "advance microbes"
	max_stages = 5
	spread_text = "Unknown"
	viable_mobtypes = list(/mob/living/carbon/human)

	// NEW VARS
	var/list/properties = list()
	var/list/symptoms = list() // The symptoms of the disease.
	var/id = ""
	var/processing = FALSE
	var/mutable = TRUE //set to FALSE to prevent most in-game methods of altering the disease via virology
	var/oldres //To prevent setting new cures unless resistance changes.

	///Lists of cures and how hard we expect them to be to cure. Sentient diseases will pick two from 6+
	var/static/list/advance_cures = list(
		list( // level 1
			/datum/reagent/carbon,
			/datum/reagent/copper,
			/datum/reagent/iodine,
			/datum/reagent/iron,
			/datum/reagent/silver,
		),
		list( // level 2
			/datum/reagent/consumable/ethanol,
			/datum/reagent/acetone,
			/datum/reagent/bromine,
			/datum/reagent/lithium,
			/datum/reagent/potassium,
			/datum/reagent/silicon,
		),
		list( // level 3
			/datum/reagent/consumable/milk,
			/datum/reagent/consumable/orangejuice,
			/datum/reagent/consumable/salt,
			/datum/reagent/consumable/sugar,
			/datum/reagent/consumable/tomatojuice,
		),
		list( //level 4
			/datum/reagent/fuel/oil,
			/datum/reagent/medicine/c2/multiver,
			/datum/reagent/medicine/epinephrine,
			/datum/reagent/medicine/haloperidol,
			/datum/reagent/medicine/mine_salve,
			/datum/reagent/medicine/salglu_solution,
		),
		list( //level 5
			/datum/reagent/drug/space_drugs,
			/datum/reagent/medicine/mannitol,
			/datum/reagent/medicine/synaptizine,
			/datum/reagent/cryptobiolin,
		),
		list( // level 6
			/datum/reagent/medicine/antihol,
			/datum/reagent/medicine/inacusiate,
			/datum/reagent/medicine/oculine,
			/datum/reagent/phenol,
		),
		list( // level 7
			/datum/reagent/medicine/higadrite,
			/datum/reagent/medicine/leporazine,
			/datum/reagent/toxin/mindbreaker,
			/datum/reagent/acetaldehyde,
		),
		list( // level 8
			/datum/reagent/drug/happiness,
			/datum/reagent/medicine/ephedrine,
			/datum/reagent/pax,
		),
		list( // level 9
			/datum/reagent/medicine/sal_acid,
			/datum/reagent/toxin/chloralhydrate,
			/datum/reagent/toxin/lipolicide,
		),
		list( // level 10
			/datum/reagent/drug/aranesp,
			/datum/reagent/medicine/diphenhydramine,
			/datum/reagent/pentaerythritol,
		),
		list( //level 11
			/datum/reagent/medicine/c2/tirimol,
			/datum/reagent/medicine/modafinil,
		),
	)

/*

	OLD PROCS

 */

/datum/disease/advance/New()
	Refresh()

/datum/disease/advance/Destroy()
	if(processing)
		for(var/datum/symptom/S in symptoms)
			S.End(src)
	return ..()

/datum/disease/advance/try_infect(mob/living/infectee, make_copy = TRUE)
	//see if we are more transmittable than enough diseases to replace them
	//diseases replaced in this way do not confer immunity
	var/list/advance_diseases = list()
	for(var/datum/disease/advance/P in infectee.diseases)
		advance_diseases += P
	var/replace_num = advance_diseases.len + 1 - DISEASE_LIMIT //amount of diseases that need to be removed to fit this one
	if(replace_num > 0)
		sortTim(advance_diseases, GLOBAL_PROC_REF(cmp_advdisease_resistance_asc))
		for(var/i in 1 to replace_num)
			var/datum/disease/advance/competition = advance_diseases[i]
			if(!competition.bypasses_immunity)
				if(bypasses_immunity) //viruses with bypasses_immunity get a free pass on beating normal advanced diseases
					competition.cure(FALSE)
				if(totalTransmittable() > competition.totalResistance())
					competition.cure(FALSE)
				else
					return FALSE //we are not strong enough to bully our way in
	infect(infectee, make_copy)
	return TRUE


// Randomly pick a symptom to activate.
/datum/disease/advance/stage_act(seconds_per_tick, times_fired)
	. = ..()
	if(!.)
		return

	if(!length(symptoms))
		return

	if(!processing)
		processing = TRUE
		for(var/s in symptoms)
			var/datum/symptom/symptom_datum = s
			if(symptom_datum.Start(src)) //this will return FALSE if the symptom is neutered
				symptom_datum.next_activation = world.time + (rand(symptom_datum.symptom_delay_min SECONDS, symptom_datum.symptom_delay_max SECONDS) * DISEASE_SYMPTOM_FREQUENCY_MODIFIER)
			symptom_datum.on_stage_change(src)

	for(var/s in symptoms)
		var/datum/symptom/symptom_datum = s
		if(!symptom_datum.neutered)
			symptom_datum.Activate(src)


// Tell symptoms stage changed
/datum/disease/advance/update_stage(new_stage)
	..()
	for(var/datum/symptom/S in symptoms)
		S.on_stage_change(src)

// Compares type then ID.
/datum/disease/advance/IsSame(datum/disease/advance/D)

	if(!(istype(D, /datum/disease/advance)))
		return FALSE

	if(GetDiseaseID() != D.GetDiseaseID())
		return FALSE
	return TRUE

// Returns the advance disease with a different reference memory.
/datum/disease/advance/Copy()
	var/datum/disease/advance/A = ..()
	QDEL_LIST(A.symptoms)
	for(var/datum/symptom/S in symptoms)
		A.symptoms += S.Copy()
	A.properties = properties.Copy()
	A.id = id
	A.mutable = mutable
	A.oldres = oldres
	//this is a new disease starting over at stage 1, so processing is not copied
	return A

// Mix the symptoms of two diseases (the src and the argument)
/datum/disease/advance/proc/Mix(datum/disease/advance/D)
	if(!(IsSame(D)))
		var/list/possible_symptoms = shuffle(D.symptoms)
		for(var/datum/symptom/S in possible_symptoms)
			AddSymptom(S.Copy())

/datum/disease/advance/proc/HasSymptom(datum/symptom/S)
	for(var/datum/symptom/symp in symptoms)
		if(symp.type == S.type)
			return TRUE
	return FALSE

// Will generate new unique symptoms, use this if there are none. Returns a list of symptoms that were generated.
/datum/disease/advance/proc/GenerateSymptoms(level_min, level_max, amount_get = 0)

	. = list() // Symptoms we generated.

	// Generate symptoms. By default, we only choose non-deadly symptoms.
	var/list/possible_symptoms = list()
	for(var/symp in SSdisease.list_symptoms)
		var/datum/symptom/S = new symp
		if(S.can_generate_randomly() && S.level >= level_min && S.level <= level_max)
			if(!HasSymptom(S))
				possible_symptoms += S

	if(!possible_symptoms.len)
		return

	// Random chance to get more than one symptom
	var/number_of = amount_get
	if(!amount_get)
		number_of = 1
		while(prob(20))
			number_of += 1

	for(var/i = 1; number_of >= i && possible_symptoms.len; i++)
		. += pick_n_take(possible_symptoms)

/datum/disease/advance/proc/Refresh(new_name = FALSE)
	GenerateProperties()
	assign_properties()
	if(processing && symptoms?.len)
		for(var/datum/symptom/S in symptoms)
			S.Start(src)
			S.on_stage_change(src)
	id = null

	var/the_id = GetDiseaseID()
	if(!SSdisease.archive_diseases[the_id])
		SSdisease.archive_diseases[the_id] = src // So we don't infinite loop
		SSdisease.archive_diseases[the_id] = Copy()
		if(new_name)
			AssignName()

//Generate disease properties based on the effects. Returns an associated list.
/datum/disease/advance/proc/GenerateProperties()
	properties = list("resistance" = 0, "stealth" = 0, "stage_rate" = 0, "transmittable" = 0, "severity" = 0)

	for(var/datum/symptom/S in symptoms)
		properties["resistance"] += S.resistance
		properties["stealth"] += S.stealth
		properties["stage_rate"] += S.stage_speed
		properties["transmittable"] += S.transmittable
		if(!S.neutered)
			properties["severity"] += S.severity // severity is based on the sum of all non-neutered symptoms' severity
	if(properties["severity"] > 0)
		properties["severity"] += round((properties["resistance"] / 12), 1)
		properties["severity"] += round((properties["stage_rate"] / 11), 1)
		properties["severity"] += round((properties["transmittable"] / 8), 1)
		properties["severity"] = round((properties["severity"] / 2), 1)
		properties["severity"] *= (symptoms.len / VIRUS_SYMPTOM_LIMIT) //fewer symptoms, less severity
		properties["severity"] = round(clamp(properties["severity"], 1, 7), 1)

// Assign the properties that are in the list.
/datum/disease/advance/proc/assign_properties()

	if(properties?.len)
		if(properties["stealth"] >= properties["severity"] && properties["severity"] > 0)
			visibility_flags |= HIDDEN_SCANNER
		else
			visibility_flags &= ~HIDDEN_SCANNER

		if(properties["transmittable"] >= 11)
			set_spread(DISEASE_SPREAD_AIRBORNE)
		else if(properties["transmittable"] >= 7)
			set_spread(DISEASE_SPREAD_CONTACT_SKIN)
		else if(properties["transmittable"] >= 3)
			set_spread(DISEASE_SPREAD_CONTACT_FLUIDS)
		else
			set_spread(DISEASE_SPREAD_BLOOD)

		spreading_modifier = max(CEILING(0.4 * properties["transmittable"], 1), 1)
		cure_chance = clamp(7.5 - (0.5 * properties["resistance"]), 1, 10) // can be between 1 and 10
		stage_prob = max(0.3 * properties["stage_rate"], 1)
		set_severity(round(properties["severity"]), 1)
		generate_cure(properties)
	else
		CRASH("Our properties were empty or null!")


// Assign the spread type and give it the correct description.
/datum/disease/advance/proc/set_spread(spread_id)
	switch(spread_id)
		if(DISEASE_SPREAD_NON_CONTAGIOUS)
			update_spread_flags(DISEASE_SPREAD_NON_CONTAGIOUS)
			spread_text = "None"
		if(DISEASE_SPREAD_SPECIAL)
			update_spread_flags(DISEASE_SPREAD_SPECIAL)
			spread_text = "None"
		if(DISEASE_SPREAD_BLOOD)
			update_spread_flags(DISEASE_SPREAD_BLOOD)
			spread_text = "Blood"
		if(DISEASE_SPREAD_CONTACT_FLUIDS)
			update_spread_flags(DISEASE_SPREAD_BLOOD | DISEASE_SPREAD_CONTACT_FLUIDS)
			spread_text = "Fluids"
		if(DISEASE_SPREAD_CONTACT_SKIN)
			update_spread_flags(DISEASE_SPREAD_BLOOD | DISEASE_SPREAD_CONTACT_FLUIDS | DISEASE_SPREAD_CONTACT_SKIN)
			spread_text = "Skin contact"
		if(DISEASE_SPREAD_AIRBORNE)
			update_spread_flags(DISEASE_SPREAD_BLOOD | DISEASE_SPREAD_CONTACT_FLUIDS | DISEASE_SPREAD_CONTACT_SKIN | DISEASE_SPREAD_AIRBORNE)
			spread_text = "Respiration"

/datum/disease/advance/proc/set_severity(level_sev)

	switch(level_sev)

		if(-INFINITY to 0)
			severity = DISEASE_SEVERITY_POSITIVE
		if(1)
			severity = DISEASE_SEVERITY_NONTHREAT
		if(2)
			severity = DISEASE_SEVERITY_MINOR
		if(3)
			severity = DISEASE_SEVERITY_MEDIUM
		if(4)
			severity = DISEASE_SEVERITY_HARMFUL
		if(5)
			severity = DISEASE_SEVERITY_DANGEROUS
		if(6 to INFINITY)
			severity = DISEASE_SEVERITY_BIOHAZARD
		else
			severity = "Unknown"


// Will generate a random cure, the more resistance the symptoms have, the harder the cure.
/datum/disease/advance/proc/generate_cure()
	if(properties?.len)
		var/res = clamp(properties["resistance"] - (symptoms.len / 2), 1, advance_cures.len)
		if(res == oldres)
			return
		cures = list(pick(advance_cures[res]))
		oldres = res
		// Get the cure name from the cure_id
		var/datum/reagent/D = GLOB.chemical_reagents_list[cures[1]]
		cure_text = D.name

// Randomly generate a symptom, has a chance to lose or gain a symptom.
/datum/disease/advance/proc/Evolve(min_level, max_level, ignore_mutable = FALSE)
	if(!mutable && !ignore_mutable)
		return
	var/list/generated_symptoms = GenerateSymptoms(min_level, max_level, 1)
	if(length(generated_symptoms))
		var/datum/symptom/S = pick(generated_symptoms)
		AddSymptom(S)
		Refresh(TRUE)

// Randomly remove a symptom.
/datum/disease/advance/proc/Devolve(ignore_mutable = FALSE)
	if(!mutable && !ignore_mutable)
		return
	if(length(symptoms) > 1)
		var/datum/symptom/S = pick(symptoms)
		if(S)
			RemoveSymptom(S)
			Refresh(TRUE)

// Randomly neuter a symptom.
/datum/disease/advance/proc/Neuter(ignore_mutable = FALSE)
	if(!mutable && !ignore_mutable)
		return
	if(length(symptoms))
		var/datum/symptom/S = pick(symptoms)
		if(S)
			NeuterSymptom(S)
			Refresh(TRUE)

// Name the disease.
/datum/disease/advance/proc/AssignName(name = "Unknown")
	var/datum/disease/advance/A = SSdisease.archive_diseases[GetDiseaseID()]
	A.name = name

// Return a unique ID of the disease.
/datum/disease/advance/GetDiseaseID()
	if(!id)
		var/list/L = list()
		for(var/datum/symptom/S in symptoms)
			if(S.neutered)
				L += "[S.id]N"
			else
				L += S.id
		L = sort_list(L) // Sort the list so it doesn't matter which order the symptoms are in.
		var/result = jointext(L, ":")
		id = result
	return id


// Add a symptom, if it is over the limit we take a random symptom away and add the new one.
/datum/disease/advance/proc/AddSymptom(datum/symptom/S)
	if(HasSymptom(S))
		return
	if(symptoms.len >= VIRUS_SYMPTOM_LIMIT)
		RemoveSymptom(pick(symptoms))
	symptoms += S
	S.OnAdd(src)

// Simply removes the symptom.
/datum/disease/advance/proc/RemoveSymptom(datum/symptom/S)
	symptoms -= S
	S.OnRemove(src)

// Neuter a symptom, so it will only affect stats
/datum/disease/advance/proc/NeuterSymptom(datum/symptom/S)
	if(!S.neutered)
		S.neutered = TRUE
		S.name += " (neutered)"
		S.OnRemove(src)

/*

	Static Procs

*/

// Mix a list of advance diseases and return the mixed result.
/proc/Advance_Mix(list/D_list)
	var/list/diseases = list()

	for(var/datum/disease/advance/A in D_list)
		diseases += A.Copy()

	if(!diseases.len)
		return null
	if(diseases.len <= 1)
		return pick(diseases) // Just return the only entry.

	var/i = 0
	// Mix our diseases until we are left with only one result.
	while(i < 20 && diseases.len > 1)

		i++

		var/datum/disease/advance/D1 = pick(diseases)
		diseases -= D1

		var/datum/disease/advance/D2 = pick(diseases)
		D2.Mix(D1)

	// Should be only 1 entry left, but if not let's only return a single entry
	var/datum/disease/advance/to_return = pick(diseases)
	to_return.Refresh(TRUE)
	return to_return

/proc/SetViruses(datum/reagent/R, list/data)
	if(data)
		var/list/preserve = list()
		if(istype(data) && data["viruses"])
			for(var/datum/disease/A in data["viruses"])
				preserve += A.Copy()
			R.data = data.Copy()
		if(preserve.len)
			R.data["viruses"] = preserve

/proc/AdminCreateVirus(client/user)

	if(!user)
		return

	var/i = VIRUS_SYMPTOM_LIMIT

	var/datum/disease/advance/D = new()
	D.symptoms = list()

	var/list/symptoms = list()
	symptoms += "Done"
	symptoms += SSdisease.list_symptoms.Copy()
	do
		if(user)
			var/symptom = tgui_input_list(user, "Choose a symptom to add ([i] remaining)", "Choose a Symptom", sort_list(symptoms, GLOBAL_PROC_REF(cmp_typepaths_asc)))
			if(isnull(symptom))
				return
			else if(istext(symptom))
				i = 0
			else if(ispath(symptom))
				var/datum/symptom/S = new symptom
				if(!D.HasSymptom(S))
					D.AddSymptom(S)
					i -= 1
	while(i > 0)

	if(D.symptoms.len > 0)

		var/new_name = tgui_input_text(user, "Name your new disease", "New Name", max_length = MAX_NAME_LEN)
		if(!new_name)
			return
		D.Refresh()
		D.AssignName(new_name) //Updates the master copy
		D.name = new_name //Updates our copy

		var/list/targets = list("Random")
		targets += sort_names(GLOB.human_list)
		var/target = tgui_input_list(user, "Viable human target", "Disease Target", targets)
		if(isnull(target))
			return
		var/mob/living/carbon/human/H
		if(target == "Random")
			for(var/human in shuffle(GLOB.human_list))
				H = human
				var/found = FALSE
				if(!is_station_level(H.z))
					continue
				if(!H.HasDisease(D))
					found = H.ForceContractDisease(D)
					break
				if(!found)
					to_chat(user, "Could not find a valid target for the disease.")
		else
			H = target
			if(istype(H) && D.infectable_biotypes & H.mob_biotypes)
				H.ForceContractDisease(D)
			else
				to_chat(user, "Target could not be infected. Check mob biotype compatibility or resistances.")
				return

		message_admins("[key_name_admin(user)] has triggered a custom virus outbreak of [D.admin_details()] in [ADMIN_LOOKUPFLW(H)]")
		log_virus("[key_name(user)] has triggered a custom virus outbreak of [D.admin_details()] in [H]!")


/datum/disease/advance/proc/totalStageSpeed()
	return properties["stage_rate"]

/datum/disease/advance/proc/totalStealth()
	return properties["stealth"]

/datum/disease/advance/proc/totalResistance()
	return properties["resistance"]

/datum/disease/advance/proc/totalTransmittable()
	return properties["transmittable"]

/**
 *  If the disease has an incubation time (such as event diseases) start the timer, let properties determine if there's no timer set.
 */
/datum/disease/advance/after_add()
	. = ..()

	if(isnull(incubation_time))
		return

	if(incubation_time < world.time)
		make_visible()
		return

	addtimer(CALLBACK(src, PROC_REF(make_visible)), incubation_time - world.time)


/**
 *  Make virus visible to heath scanners
 */
/datum/disease/advance/proc/make_visible()
	visibility_flags &= ~HIDDEN_SCANNER
	affected_mob.med_hud_set_status()
