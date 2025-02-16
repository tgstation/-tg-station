/datum/crafting_recipe/gold_horn
	name = "Golden Bike Horn"
	result = /obj/item/bikehorn/golden
	time = 2 SECONDS
	reqs = list(
		/obj/item/stack/sheet/mineral/bananium = 5,
		/obj/item/bikehorn = 1,
	)
	category = CAT_TOOLS

/datum/crafting_recipe/bonfire
	name = "Bonfire"
	time = 6 SECONDS
	reqs = list(/obj/item/grown/log = 5)
	parts = list(/obj/item/grown/log = 5)
	blacklist = list(/obj/item/grown/log/steel)
	result = /obj/structure/bonfire
	category = CAT_TOOLS

/datum/crafting_recipe/boneshovel
	name = "Serrated Bone Shovel"
	reqs = list(
		/obj/item/stack/sheet/bone = 4,
		/datum/reagent/fuel/oil = 5,
		/obj/item/shovel = 1,
	)
	result = /obj/item/shovel/serrated
	category = CAT_TOOLS
	crafting_flags = CRAFT_CHECK_DENSITY | CRAFT_MUST_BE_LEARNED

/datum/crafting_recipe/lasso
	name = "Bone Lasso"
	reqs = list(
		/obj/item/stack/sheet/bone = 1,
		/obj/item/stack/sheet/sinew = 5,
	)
	result = /obj/item/key/lasso
	category = CAT_TOOLS

/datum/crafting_recipe/ipickaxe
	name = "Improvised Pickaxe"
	reqs = list(
		/obj/item/crowbar = 1,
		/obj/item/knife = 1,
		/obj/item/stack/sticky_tape = 1,
	)
	result = /obj/item/pickaxe/improvised
	category = CAT_TOOLS

/datum/crafting_recipe/bandage
	name = "Makeshift Bandage"
	reqs = list(
		/obj/item/stack/sheet/cloth = 3,
		/datum/reagent/medicine/c2/libital = 10,
	)
	result = /obj/item/stack/medical/bandage/makeshift
	category = CAT_TOOLS

/datum/crafting_recipe/bone_rod
	name = "Bone Fishing Rod"
	result = /obj/item/fishing_rod/bone
	time = 5 SECONDS
	reqs = list(/obj/item/stack/sheet/leather = 1,
				/obj/item/stack/sheet/sinew = 2,
				/obj/item/stack/sheet/bone = 2)
	category = CAT_TOOLS

/datum/crafting_recipe/sinew_line
	name = "Sinew Fishing Line Reel"
	result = /obj/item/fishing_line/sinew
	reqs = list(/obj/item/stack/sheet/sinew = 2)
	time = 2 SECONDS
	category = CAT_TOOLS

/datum/crafting_recipe/bone_hook
	name = "Goliath Bone Hook"
	result = /obj/item/fishing_hook/bone
	reqs = list(/obj/item/stack/sheet/bone = 1)
	time = 2 SECONDS
	category = CAT_TOOLS

/datum/crafting_recipe/shuttle_blueprints
	name = "Crude Shuttle Blueprints"
	result = /obj/item/shuttle_blueprints/crude
	reqs = list(
		/obj/item/paper = 1,
		/obj/item/toy/crayon = CRAFTING_INGREDIENT_USE,
	)
	steps = list(
		"You must use either a a blue crayon, a rainbow crayon, or a spray can.",
		"The crayon or spray can you use must have at least 10 uses remaining."
	)
	time = 10 SECONDS
	category = CAT_TOOLS

/datum/crafting_recipe/shuttle_blueprints/check_requirements(mob/user, list/collected_requirements)
	var/list/crayons = collected_requirements[/obj/item/toy/crayon]
	for(var/obj/item/toy/crayon/crayon as anything in crayons)
		if(!is_type_in_list(crayon, list(/obj/item/toy/crayon/blue, /obj/item/toy/crayon/rainbow, /obj/item/toy/crayon/spraycan)))
			continue
		if(!crayon.check_empty(user, 10))
			return TRUE

/datum/crafting_recipe/shuttle_blueprints/on_craft_completion(mob/user, atom/result)
	var/static/list/valid_types = list(/obj/item/toy/crayon/blue, /obj/item/toy/crayon/rainbow, /obj/item/toy/crayon/spraycan)
	for(var/valid_type in valid_types)
		var/obj/item/toy/crayon/crayon = locate(valid_type) in range(1)
		if(!crayon)
			continue
		if(crayon.use_charges(user, 10))
			return
