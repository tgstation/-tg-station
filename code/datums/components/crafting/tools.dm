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
	parts = list(/obj/item/grown/log = 5) //Will be returned if the bonfire is dismantled
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
