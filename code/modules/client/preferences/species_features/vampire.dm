/datum/preference/choiced/vampire_status
	savefile_key = "feature_vampire_status"
	savefile_identifier = PREFERENCE_CHARACTER
	category = PREFERENCE_CATEGORY_FEATURES
	priority = PREFERENCE_PRIORITY_NAME_MODIFICATIONS //this will be overwritten by names otherwise
	main_feature_name = "Vampire status"
	should_generate_icons = TRUE
	relevant_inherent_trait = TRAIT_BLOOD_CLANS

/datum/preference/choiced/vampire_status/create_default_value()
	return "Inoculated" //eh, have em try out the mechanic first

/datum/preference/choiced/vampire_status/init_possible_values()
	return list("Inoculated", "Outcast")

/datum/preference/choiced/vampire_status/icon_for(value)
	switch (value)
		if ("Inoculated")
			return uni_icon('icons/obj/drinks/drinks.dmi', "bloodglass")
		if ("Outcast")
			return uni_icon('icons/obj/medical/bloodpack.dmi', "generic_bloodpack")

///list that stores a vampire house name for each department
GLOBAL_LIST_EMPTY(vampire_houses)

/datum/preference/choiced/vampire_status/apply_to_human(mob/living/carbon/human/target, value)
	if(!HAS_TRAIT(target, TRAIT_BLOOD_CLANS))
		return

	if(value != "Inoculated")
		return

	//find and setup the house (department) this vampire is joining
	var/datum/job_department/vampire_house
	var/datum/job/vampire_job = SSjob.get_job(target.job)
	if(!vampire_job) //no job or no mind LOSERS
		return
	var/list/valid_departments = (SSjob.joinable_departments.Copy()) - list(/datum/job_department/silicon, /datum/job_department/undefined)
	for(var/datum/job_department/potential_house as anything in valid_departments)
		if(vampire_job in potential_house.department_jobs)
			vampire_house = potential_house
			break
	if(!vampire_house) //sillycones
		return
	if(!GLOB.vampire_houses[vampire_house.department_name])
		GLOB.vampire_houses[vampire_house.department_name] = pick(GLOB.vampire_house_names)
	var/house_name = GLOB.vampire_houses[vampire_house.department_name]

	//modify name (Platos Syrup > Platos de Lioncourt)
	var/first_space_index = findtextEx(target.real_name, " ")
	var/new_name = copytext(target.real_name, 1, first_space_index + 1)
	new_name += house_name
	target.fully_replace_character_name(target.real_name, new_name)
