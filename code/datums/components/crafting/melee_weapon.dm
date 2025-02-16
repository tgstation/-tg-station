/datum/crafting_recipe/stunprod
	name = "Stunprod"
	result = /obj/item/melee/baton/security/cattleprod
	reqs = list(
		/obj/item/restraints/handcuffs/cable = 1,
		/obj/item/stack/rods = 1,
		/obj/item/assembly/igniter = 1,
	)
	time = 4 SECONDS
	category = CAT_WEAPON_MELEE

/datum/crafting_recipe/teleprod
	name = "Teleprod"
	result = /obj/item/melee/baton/security/cattleprod/teleprod
	reqs = list(
		/obj/item/restraints/handcuffs/cable = 1,
		/obj/item/stack/rods = 1,
		/obj/item/assembly/igniter = 1,
		/obj/item/stack/ore/bluespace_crystal = 1,
	)
	time = 4 SECONDS
	category = CAT_WEAPON_MELEE

/datum/crafting_recipe/telecrystalprod
	name = "Snatcherprod"
	result = /obj/item/melee/baton/security/cattleprod/telecrystalprod
	reqs = list(
		/obj/item/restraints/handcuffs/cable = 1,
		/obj/item/stack/rods = 1,
		/obj/item/assembly/igniter = 1,
		/obj/item/stack/telecrystal = 1,
	)
	time = 4 SECONDS
	category = CAT_WEAPON_MELEE

/datum/crafting_recipe/tailclub
	name = "Tail Club"
	result = /obj/item/tailclub
	reqs = list(
		/obj/item/organ/tail/lizard = 1,
		/obj/item/stack/sheet/iron = 1,
	)
	blacklist = list(/obj/item/organ/tail/lizard/fake)
	time = 4 SECONDS
	category = CAT_WEAPON_MELEE


/datum/crafting_recipe/balloon_mallet
	name = "Balloon Mallet"
	result = /obj/item/balloon_mallet
	reqs = list(
		/obj/item/toy/balloon/long = 18,
	)
	time = 10 SECONDS
	category = CAT_WEAPON_MELEE

/datum/crafting_recipe/balloon_mallet/check_requirements(mob/user, list/collected_requirements)
	. = ..()
	if(HAS_TRAIT(user, TRAIT_BALLOON_SUTRA))
		return TRUE

/datum/crafting_recipe/tailwhip
	name = "Liz O' Nine Tails"
	result = /obj/item/melee/chainofcommand/tailwhip
	reqs = list(
		/obj/item/organ/tail/lizard = 1,
		/obj/item/stack/cable_coil = 1,
	)
	blacklist = list(/obj/item/organ/tail/lizard/fake)
	time = 4 SECONDS
	category = CAT_WEAPON_MELEE

/datum/crafting_recipe/catwhip
	name = "Cat O' Nine Tails"
	result = /obj/item/melee/chainofcommand/tailwhip/kitty
	reqs = list(
		/obj/item/organ/tail/cat = 1,
		/obj/item/stack/cable_coil = 1,
	)
	time = 4 SECONDS
	category = CAT_WEAPON_MELEE

/datum/crafting_recipe/chainsaw
	name = "Chainsaw"
	result = /obj/item/chainsaw
	reqs = list(
		/obj/item/circular_saw = 1,
		/obj/item/stack/cable_coil = 3,
		/obj/item/stack/sheet/plasteel = 5,
	)
	tool_behaviors = list(TOOL_WELDER)
	time = 5 SECONDS
	category = CAT_WEAPON_MELEE

/datum/crafting_recipe/spear
	name = "Spear"
	result = /obj/item/spear
	reqs = list(
		/obj/item/restraints/handcuffs/cable = 1,
		/obj/item/shard = 1,
		/obj/item/stack/rods = 1,
	)
	time = 4 SECONDS
	category = CAT_WEAPON_MELEE

/datum/crafting_recipe/toysword
	name = "Toy Sword"
	reqs = list(
		/obj/item/light/bulb = 1,
		/obj/item/stack/cable_coil = 1,
		/obj/item/stack/sheet/plastic = 4,
	)
	result = /obj/item/toy/sword
	category = CAT_WEAPON_MELEE

/datum/crafting_recipe/bonedagger
	name = "Bone Dagger"
	result = /obj/item/knife/combat/bone
	time = 2 SECONDS
	reqs = list(/obj/item/stack/sheet/bone = 2)
	category = CAT_WEAPON_MELEE

/datum/crafting_recipe/bonespear
	name = "Bone Spear"
	result = /obj/item/spear/bonespear
	time = 3 SECONDS
	reqs = list(
		/obj/item/stack/sheet/bone = 4,
		/obj/item/stack/sheet/sinew = 1,
	)
	category = CAT_WEAPON_MELEE

/datum/crafting_recipe/boneaxe
	name = "Bone Axe"
	result = /obj/item/fireaxe/boneaxe
	time = 5 SECONDS
	reqs = list(
		/obj/item/stack/sheet/bone = 6,
		/obj/item/stack/sheet/sinew = 3,
	)
	category = CAT_WEAPON_MELEE

/datum/crafting_recipe/house_edge
	name = "House Edge"
	result = /obj/item/house_edge
	tool_behaviors = list(TOOL_WRENCH, TOOL_SCREWDRIVER, TOOL_WELDER)
	reqs = list(
		/obj/item/v8_engine = 1,
		/obj/item/weaponcrafting/receiver = 1,
		/obj/item/assembly/igniter = 1,
		/obj/item/stack/sheet/iron = 2,
		/obj/item/knife = 1,
		/obj/item/weldingtool = 1,
		/obj/item/roulette_wheel_beacon = 1,
	)
	time = 10 SECONDS
	category = CAT_WEAPON_MELEE
	crafting_flags = CRAFT_CHECK_DENSITY | CRAFT_MUST_BE_LEARNED

/datum/crafting_recipe/giant_wrench
	name = "Big Slappy"
	result = /obj/item/shovel/giant_wrench
	tool_behaviors = list(TOOL_CROWBAR, TOOL_SCREWDRIVER, TOOL_WELDER)
	reqs = list(
		/obj/item/wrench = 4,
		/obj/item/weaponcrafting/giant_wrench = 1,
		/obj/item/stack/sheet/plasteel = 5,
		/obj/item/stack/rods = 10,
		/obj/item/pickaxe/drill = 1,
	)
	time = 10 SECONDS
	category = CAT_WEAPON_MELEE

/datum/crafting_recipe/singulo_hammer
	name = "Singularity Hammer"
	result = /obj/item/singularityhammer
	reqs = list(
		/obj/item/assembly/signaler/anomaly/pyro = 1,
		/obj/item/assembly/signaler/anomaly/grav = 1,
		/obj/item/assembly/signaler/anomaly/flux = 1,
		/obj/item/assembly/signaler/anomaly/bluespace = 1,
		/obj/item/assembly/signaler/anomaly/vortex = 1,
		/obj/item/assembly/signaler/anomaly/bioscrambler = 1,
		/obj/item/assembly/signaler/anomaly/hallucination = 1,
		/obj/item/assembly/signaler/anomaly/dimensional = 1,
		/obj/item/assembly/signaler/anomaly/ectoplasm = 1,
	)
	machinery = list(
		/obj/machinery/power/supermatter_crystal = CRAFTING_MACHINERY_CONSUME,
	)
	time = 10 SECONDS
	category = CAT_WEAPON_MELEE

/datum/crafting_recipe/bambostaff
	name = "Bamboo Bo Staff"
	result = /obj/item/bambostaff
	reqs = list(
		/obj/item/stack/sheet/mineral/bamboo = 4,
		/obj/item/grown/log/steel = 2,
	)
	time = 8 SECONDS
	category = CAT_WEAPON_MELEE

/datum/crafting_recipe/sm_sword
	name = "Supermatter Sword"
	result = /obj/item/melee/supermatter_sword
	reqs = list(
		/obj/item/assembly/signaler/anomaly/vortex = (MAX_CORES_VORTEX - 1),
	)
	machinery = list(
		/obj/machinery/power/supermatter_crystal/small = CRAFTING_MACHINERY_CONSUME,
	)
	time = 120 SECONDS
	category = CAT_WEAPON_MELEE
