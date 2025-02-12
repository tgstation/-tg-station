/datum/job/cook
	title = JOB_COOK
	description = "Serve food, cook meat, keep the crew fed."
	department_head = list(JOB_HEAD_OF_PERSONNEL)
	faction = FACTION_STATION
	total_positions = 2
	spawn_positions = 1
	supervisors = SUPERVISOR_HOP
	exp_granted_type = EXP_TYPE_CREW
	config_tag = "COOK"
	var/cooks = 0 //Counts cooks amount

	outfit = /datum/outfit/job/cook
	plasmaman_outfit = /datum/outfit/plasmaman/chef

	paycheck = PAYCHECK_CREW
	paycheck_department = ACCOUNT_SRV

	liver_traits = list(TRAIT_CULINARY_METABOLISM)

	display_order = JOB_DISPLAY_ORDER_COOK
	bounty_types = CIV_JOB_CHEF
	departments_list = list(
		/datum/job_department/service,
		)

	family_heirlooms = list(
		/obj/item/reagent_containers/condiment/saltshaker,
		/obj/item/kitchen/rollingpin,
		/obj/item/clothing/head/utility/chefhat,
	)

	// Adds up to 100, don't mess it up
	mail_goodies = list(
		/obj/item/storage/box/ingredients/random = 40,
		/obj/item/reagent_containers/cup/bottle/caramel = 7,
		/obj/item/reagent_containers/condiment/flour = 7,
		/obj/item/reagent_containers/condiment/rice = 7,
		/obj/item/reagent_containers/condiment/ketchup = 7,
		/obj/item/reagent_containers/condiment/enzyme = 7,
		/obj/item/reagent_containers/condiment/soymilk = 7,
		/obj/item/kitchen/spoon/soup_ladle = 6,
		/obj/item/kitchen/tongs = 6,
		/obj/item/knife/kitchen = 4,
		/obj/item/knife/butcher = 2,
	)

	rpg_title = "Tavern Chef"
	alternate_titles = list(
		JOB_CHEF,
	)
	job_flags = STATION_JOB_FLAGS

/datum/job/cook/award_service(client/winner, award)
	winner.give_award(award, winner.mob)

	var/datum/venue/restaurant = SSrestaurant.all_venues[/datum/venue/restaurant]
	var/award_score = restaurant.total_income
	var/award_status = winner.get_award_status(/datum/award/score/chef_tourist_score)
	if(award_score > award_status)
		award_score -= award_status
	winner.give_award(/datum/award/score/chef_tourist_score, winner.mob, award_score)


/datum/outfit/job/cook
	name = "Cook"
	jobtype = /datum/job/cook

	id_trim = /datum/id_trim/job/cook/chef
	uniform = /obj/item/clothing/under/costume/buttondown/slacks/service
	suit = /obj/item/clothing/suit/toggle/chef
	backpack_contents = list(
		/obj/item/choice_beacon/ingredient = 1,
		/obj/item/sharpener = 1,
	)
	belt = /obj/item/modular_computer/pda/cook
	ears = /obj/item/radio/headset/headset_srv
	head = /obj/item/clothing/head/utility/chefhat
	mask = /obj/item/clothing/mask/fakemoustache/italian

	skillchips = list(/obj/item/skillchip/job/chef)

/datum/outfit/job/cook/pre_equip(mob/living/carbon/human/H, visuals_only = FALSE)
	..()
	var/datum/job/cook/other_chefs = SSjob.get_job_type(jobtype)
	if(other_chefs) // If there's other Chefs, you're a Cook
		if(other_chefs.cooks > 0)//Cooks
			id_trim = /datum/id_trim/job/cook
			suit = /obj/item/clothing/suit/apron/chef
			head = /obj/item/clothing/head/soft/mime
		if(!visuals_only)
			other_chefs.cooks++

/datum/outfit/job/cook/post_equip(mob/living/carbon/human/user, visuals_only = FALSE)
	. = ..()
	// Update PDA to match possible new trim.
	var/obj/item/card/id/worn_id = user.wear_id
	var/obj/item/modular_computer/pda/pda = user.get_item_by_slot(pda_slot)
	if(!istype(worn_id) || !istype(pda))
		return
	var/assignment = worn_id.get_trim_assignment()
	if(!isnull(assignment))
		pda.imprint_id(user.real_name, assignment, worn_id)

/datum/outfit/job/cook/get_types_to_preload()
	. = ..()
	. += /obj/item/clothing/suit/apron/chef
	. += /obj/item/clothing/head/soft/mime
