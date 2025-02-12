/obj/item/storage/belt
	name = "not actually a toolbelt"
	desc = "Can hold various things. This is the base type of /belt, are you sure you should have this?"
	icon = 'icons/obj/clothing/belts.dmi'
	icon_state = "utility"
	inhand_icon_state = "utility"
	worn_icon_state = "utility"
	lefthand_file = 'icons/mob/inhands/equipment/belt_lefthand.dmi'
	righthand_file = 'icons/mob/inhands/equipment/belt_righthand.dmi'
	slot_flags = ITEM_SLOT_BELT
	attack_verb_continuous = list("whips", "lashes", "disciplines")
	attack_verb_simple = list("whip", "lash", "discipline")
	max_integrity = 300
	equip_sound = 'sound/items/equip/toolbelt_equip.ogg'
	w_class = WEIGHT_CLASS_BULKY
	var/content_overlays = FALSE //If this is true, the belt will gain overlays based on what it's holding

/obj/item/storage/belt/suicide_act(mob/living/carbon/user)
	user.visible_message(span_suicide("[user] begins belting [user.p_them()]self with \the [src]! It looks like [user.p_theyre()] trying to commit suicide!"))
	return BRUTELOSS

/obj/item/storage/belt/update_overlays()
	. = ..()
	if(!content_overlays)
		return
	for(var/obj/item/I in contents)
		. += I.get_belt_overlay()

/obj/item/storage/belt/Initialize(mapload)
	. = ..()
	AddElement(/datum/element/attack_equip)
	update_appearance()

/obj/item/storage/belt/utility
	name = "toolbelt" //Carn: utility belt is nicer, but it bamboozles the text parsing.
	desc = "Holds tools."
	icon_state = "utility"
	inhand_icon_state = "utility"
	worn_icon_state = "utility"
	content_overlays = TRUE
	custom_premium_price = PAYCHECK_CREW * 2
	drop_sound = 'sound/items/handling/toolbelt_drop.ogg'
	pickup_sound = 'sound/items/handling/toolbelt_pickup.ogg'

/obj/item/storage/belt/utility/Initialize(mapload)
	. = ..()
	atom_storage.max_specific_storage = WEIGHT_CLASS_NORMAL
	atom_storage.max_total_storage = 21
	atom_storage.set_holdable(GLOB.tool_items + list(
		/obj/item/clothing/gloves,
		/obj/item/radio,
		/obj/item/melee/sickly_blade/lock,
		/obj/item/reagent_containers/cup/soda_cans,
	))

/obj/item/storage/belt/utility/chief
	name = "chief engineer's toolbelt"
	desc = "Holds tools, looks snazzy."
	icon_state = "utility_ce"
	inhand_icon_state = "utility_ce"
	worn_icon_state = "utility_ce"

/obj/item/storage/belt/utility/chief/full
	preload = TRUE

/obj/item/storage/belt/utility/chief/full/PopulateContents()
	SSwardrobe.provide_type(/obj/item/screwdriver/power, src)
	SSwardrobe.provide_type(/obj/item/crowbar/power, src)
	SSwardrobe.provide_type(/obj/item/weldingtool/experimental, src)
	SSwardrobe.provide_type(/obj/item/multitool, src)
	SSwardrobe.provide_type(/obj/item/stack/cable_coil, src)
	SSwardrobe.provide_type(/obj/item/extinguisher/mini, src)
	SSwardrobe.provide_type(/obj/item/analyzer, src)
	//much roomier now that we've managed to remove two tools

/obj/item/storage/belt/utility/chief/full/get_types_to_preload()
	var/list/to_preload = list() //Yes this is a pain. Yes this is the point
	to_preload += /obj/item/screwdriver/power
	to_preload += /obj/item/crowbar/power
	to_preload += /obj/item/weldingtool/experimental
	to_preload += /obj/item/multitool
	to_preload += /obj/item/stack/cable_coil
	to_preload += /obj/item/extinguisher/mini
	to_preload += /obj/item/analyzer
	return to_preload

/obj/item/storage/belt/utility/full/PopulateContents()
	SSwardrobe.provide_type(/obj/item/screwdriver, src)
	SSwardrobe.provide_type(/obj/item/wrench, src)
	SSwardrobe.provide_type(/obj/item/weldingtool, src)
	SSwardrobe.provide_type(/obj/item/crowbar, src)
	SSwardrobe.provide_type(/obj/item/wirecutters, src)
	SSwardrobe.provide_type(/obj/item/multitool, src)
	SSwardrobe.provide_type(/obj/item/stack/cable_coil, src)

/obj/item/storage/belt/utility/full/get_types_to_preload()
	var/list/to_preload = list() //Yes this is a pain. Yes this is the point
	to_preload += /obj/item/screwdriver
	to_preload += /obj/item/wrench
	to_preload += /obj/item/weldingtool
	to_preload += /obj/item/crowbar
	to_preload += /obj/item/wirecutters
	to_preload += /obj/item/multitool
	to_preload += /obj/item/stack/cable_coil
	return to_preload

/obj/item/storage/belt/utility/full/powertools
	preload = FALSE

/obj/item/storage/belt/utility/full/powertools/PopulateContents()
	new /obj/item/screwdriver/power(src)
	new /obj/item/crowbar/power(src)
	new /obj/item/weldingtool/experimental(src)
	new /obj/item/multitool(src)
	new /obj/item/holosign_creator/atmos(src)
	new /obj/item/extinguisher/mini(src)
	new /obj/item/stack/cable_coil(src)

/obj/item/storage/belt/utility/full/powertools/rcd/PopulateContents()
	new /obj/item/screwdriver/power(src)
	new /obj/item/crowbar/power(src)
	new /obj/item/weldingtool/experimental(src)
	new /obj/item/multitool(src)
	new /obj/item/construction/rcd/loaded/upgraded(src)
	new /obj/item/extinguisher/mini(src)
	new /obj/item/stack/cable_coil(src)

/obj/item/storage/belt/utility/full/engi/PopulateContents()
	SSwardrobe.provide_type(/obj/item/screwdriver, src)
	SSwardrobe.provide_type(/obj/item/wrench, src)
	SSwardrobe.provide_type(/obj/item/weldingtool/largetank, src)
	SSwardrobe.provide_type(/obj/item/crowbar, src)
	SSwardrobe.provide_type(/obj/item/wirecutters, src)
	SSwardrobe.provide_type(/obj/item/multitool, src)
	SSwardrobe.provide_type(/obj/item/stack/cable_coil, src)

/obj/item/storage/belt/utility/full/engi/get_types_to_preload()
	var/list/to_preload = list() //Yes this is a pain. Yes this is the point
	to_preload += /obj/item/screwdriver
	to_preload += /obj/item/wrench
	to_preload += /obj/item/weldingtool/largetank
	to_preload += /obj/item/crowbar
	to_preload += /obj/item/wirecutters
	to_preload += /obj/item/multitool
	to_preload += /obj/item/stack/cable_coil
	return to_preload

/obj/item/storage/belt/utility/atmostech/PopulateContents()
	SSwardrobe.provide_type(/obj/item/screwdriver, src)
	SSwardrobe.provide_type(/obj/item/wrench, src)
	SSwardrobe.provide_type(/obj/item/weldingtool, src)
	SSwardrobe.provide_type(/obj/item/crowbar, src)
	SSwardrobe.provide_type(/obj/item/wirecutters, src)
	SSwardrobe.provide_type(/obj/item/t_scanner, src)
	SSwardrobe.provide_type(/obj/item/extinguisher/mini, src)

/obj/item/storage/belt/utility/atmostech/get_types_to_preload()
	var/list/to_preload = list() //Yes this is a pain. Yes this is the point
	to_preload += /obj/item/screwdriver
	to_preload += /obj/item/wrench
	to_preload += /obj/item/weldingtool
	to_preload += /obj/item/crowbar
	to_preload += /obj/item/wirecutters
	to_preload += /obj/item/t_scanner
	to_preload += /obj/item/extinguisher/mini
	return to_preload

/obj/item/storage/belt/utility/full/inducer/PopulateContents()
	SSwardrobe.provide_type(/obj/item/screwdriver, src)
	SSwardrobe.provide_type(/obj/item/wrench, src)
	SSwardrobe.provide_type(/obj/item/weldingtool, src)
	SSwardrobe.provide_type(/obj/item/crowbar/red, src)
	SSwardrobe.provide_type(/obj/item/wirecutters, src)
	SSwardrobe.provide_type(/obj/item/multitool, src)
	SSwardrobe.provide_type(/obj/item/inducer, src)

/obj/item/storage/belt/utility/full/inducer/get_types_to_preload()
	var/list/to_preload = list() //Yes this is a pain. Yes this is the point
	to_preload += /obj/item/screwdriver
	to_preload += /obj/item/wrench
	to_preload += /obj/item/weldingtool
	to_preload += /obj/item/crowbar
	to_preload += /obj/item/wirecutters
	to_preload += /obj/item/multitool
	to_preload += /obj/item/inducer
	return to_preload

/obj/item/storage/belt/utility/syndicate
	preload = FALSE

/obj/item/storage/belt/utility/syndicate/PopulateContents()
	new /obj/item/screwdriver/nuke(src)
	new /obj/item/wrench/combat(src)
	new /obj/item/weldingtool/largetank(src)
	new /obj/item/crowbar(src)
	new /obj/item/wirecutters(src)
	new /obj/item/multitool(src)
	new /obj/item/inducer/syndicate(src)

/obj/item/storage/belt/medical
	name = "medical belt"
	desc = "Can hold various medical equipment."
	icon_state = "medical"
	inhand_icon_state = "medical"
	worn_icon_state = "medical"
	drop_sound = 'sound/items/handling/toolbelt_drop.ogg'
	pickup_sound = 'sound/items/handling/toolbelt_pickup.ogg'

/obj/item/storage/belt/medical/Initialize(mapload)
	. = ..()
	atom_storage.max_specific_storage = WEIGHT_CLASS_NORMAL
	atom_storage.max_total_storage = 21
	atom_storage.set_holdable(list(
		/obj/item/bikehorn/rubberducky,
		/obj/item/blood_filter,
		/obj/item/bonesetter,
		/obj/item/cautery,
		/obj/item/circular_saw,
		/obj/item/clothing/glasses,
		/obj/item/clothing/gloves,
		/obj/item/clothing/neck/stethoscope,
		/obj/item/clothing/mask/breath,
		/obj/item/clothing/mask/muzzle,
		/obj/item/clothing/mask/surgical,
		/obj/item/clothing/head/utility/surgerycap,
		/obj/item/construction/plumbing,
		/obj/item/dnainjector,
		/obj/item/extinguisher/mini,
		/obj/item/flashlight/pen,
		/obj/item/geiger_counter,
		/obj/item/gun/syringe/syndicate,
		/obj/item/healthanalyzer,
		/obj/item/hemostat,
		/obj/item/holosign_creator/medical,
		/obj/item/implant,
		/obj/item/implantcase,
		/obj/item/implanter,
		/obj/item/lazarus_injector,
		/obj/item/lighter,
		/obj/item/pinpointer/crew,
		/obj/item/plunger,
		/obj/item/radio,
		/obj/item/reagent_containers/blood,
		/obj/item/reagent_containers/dropper,
		/obj/item/reagent_containers/cup/beaker,
		/obj/item/reagent_containers/cup/bottle,
		/obj/item/reagent_containers/cup/tube,
		/obj/item/reagent_containers/hypospray,
		/obj/item/reagent_containers/medigel,
		/obj/item/reagent_containers/pill,
		/obj/item/reagent_containers/spray,
		/obj/item/reagent_containers/syringe,
		/obj/item/retractor,
		/obj/item/scalpel,
		/obj/item/shears,
		/obj/item/stack/medical,
		/obj/item/stack/sticky_tape, //surgical tape
		/obj/item/stamp,
		/obj/item/sensor_device,
		/obj/item/storage/fancy/cigarettes,
		/obj/item/storage/pill_bottle,
		/obj/item/surgical_drapes, //for true paramedics
		/obj/item/surgicaldrill,
		/obj/item/tank/internals/emergency_oxygen,
		/obj/item/wrench/medical,
		/obj/item/knife/ritual,
		/obj/item/flesh_shears,
	))

/obj/item/storage/belt/medical/paramedic
	name = "EMT belt"
	icon_state = "emt"
	inhand_icon_state = "security"
	worn_icon_state = "emt"
	preload = TRUE

/obj/item/storage/belt/medical/paramedic/PopulateContents()
	SSwardrobe.provide_type(/obj/item/sensor_device, src)
	SSwardrobe.provide_type(/obj/item/stack/medical/gauze/twelve, src)
	SSwardrobe.provide_type(/obj/item/stack/medical/bone_gel, src)
	SSwardrobe.provide_type(/obj/item/stack/sticky_tape/surgical, src)
	SSwardrobe.provide_type(/obj/item/reagent_containers/syringe, src)
	SSwardrobe.provide_type(/obj/item/reagent_containers/cup/bottle/ammoniated_mercury, src)
	SSwardrobe.provide_type(/obj/item/reagent_containers/cup/bottle/formaldehyde, src)
	update_appearance()

/obj/item/storage/belt/medical/paramedic/get_types_to_preload()
	var/list/to_preload = list() //Yes this is a pain. Yes this is the point
	to_preload += /obj/item/sensor_device
	to_preload += /obj/item/stack/medical/gauze/twelve
	to_preload += /obj/item/stack/medical/bone_gel
	to_preload += /obj/item/stack/sticky_tape/surgical
	to_preload += /obj/item/reagent_containers/syringe
	to_preload += /obj/item/reagent_containers/cup/bottle/ammoniated_mercury
	to_preload += /obj/item/reagent_containers/cup/bottle/formaldehyde
	return to_preload

/obj/item/storage/belt/medical/ert
	icon_state = "emt"
	inhand_icon_state = "security"
	worn_icon_state = "emt"
	preload = TRUE

/obj/item/storage/belt/medical/ert/PopulateContents()
	SSwardrobe.provide_type(/obj/item/sensor_device, src)
	SSwardrobe.provide_type(/obj/item/pinpointer/crew, src)
	SSwardrobe.provide_type(/obj/item/scalpel/advanced, src)
	SSwardrobe.provide_type(/obj/item/retractor/advanced, src)
	SSwardrobe.provide_type(/obj/item/stack/medical/bone_gel, src)
	SSwardrobe.provide_type(/obj/item/cautery/advanced, src)
	SSwardrobe.provide_type(/obj/item/surgical_drapes, src)
	update_appearance()

/obj/item/storage/belt/medical/ert/get_types_to_preload()
	var/list/to_preload = list()
	to_preload += /obj/item/sensor_device
	to_preload += /obj/item/pinpointer/crew
	to_preload += /obj/item/scalpel/advanced
	to_preload += /obj/item/retractor/advanced
	to_preload += /obj/item/stack/medical/bone_gel
	to_preload += /obj/item/cautery/advanced
	to_preload += /obj/item/surgical_drapes
	return to_preload

/obj/item/storage/belt/security
	name = "security belt"
	desc = "Can hold security gear like handcuffs and flashes."
	icon_state = "security"
	inhand_icon_state = "security"//Could likely use a better one.
	worn_icon_state = "security"
	content_overlays = TRUE

/obj/item/storage/belt/security/Initialize(mapload)
	. = ..()
	atom_storage.max_slots = 5
	atom_storage.max_specific_storage = WEIGHT_CLASS_NORMAL
	atom_storage.set_holdable(list(
		/obj/item/ammo_box,
		/obj/item/ammo_casing/shotgun,
		/obj/item/assembly/flash/handheld,
		/obj/item/clothing/glasses,
		/obj/item/clothing/gloves,
		/obj/item/flashlight/seclite,
		/obj/item/food/donut,
		/obj/item/grenade,
		/obj/item/holosign_creator/security,
		/obj/item/knife/combat,
		/obj/item/melee/baton,
		/obj/item/radio,
		/obj/item/reagent_containers/spray/pepper,
		/obj/item/restraints/handcuffs,
		/obj/item/restraints/legcuffs/bola,
	))
	atom_storage.open_sound = 'sound/items/handling/holster_open.ogg'
	atom_storage.open_sound_vary = TRUE
	atom_storage.rustle_sound = FALSE

/obj/item/storage/belt/security/full/PopulateContents()
	new /obj/item/reagent_containers/spray/pepper(src)
	new /obj/item/restraints/handcuffs(src)
	new /obj/item/grenade/flashbang(src)
	new /obj/item/assembly/flash/handheld(src)
	new /obj/item/melee/baton/security/loaded(src)
	update_appearance()

/obj/item/storage/belt/security/webbing
	name = "security webbing"
	desc = "Unique and versatile chest rig, can hold security gear."
	icon_state = "securitywebbing"
	inhand_icon_state = "securitywebbing"
	worn_icon_state = "securitywebbing"
	content_overlays = FALSE
	custom_premium_price = PAYCHECK_COMMAND * 3

/obj/item/storage/belt/security/webbing/Initialize(mapload)
	. = ..()
	atom_storage.max_slots = 6

/obj/item/storage/belt/mining
	name = "explorer's webbing"
	desc = "A versatile chest rig, cherished by miners and hunters alike."
	icon_state = "explorer1"
	inhand_icon_state = "explorer1"
	worn_icon_state = "explorer1"
	w_class = WEIGHT_CLASS_BULKY

/obj/item/storage/belt/mining/Initialize(mapload)
	. = ..()
	atom_storage.max_slots = 6
	atom_storage.max_specific_storage = WEIGHT_CLASS_NORMAL
	atom_storage.max_total_storage = 20
	atom_storage.set_holdable(list(
		/obj/item/analyzer,
		/obj/item/clothing/gloves,
		/obj/item/crowbar,
		/obj/item/extinguisher/mini,
		/obj/item/flashlight,
		/obj/item/gps,
		/obj/item/mining_stabilizer,
		/obj/item/key/lasso,
		/obj/item/knife,
		/obj/item/lighter,
		/obj/item/mining_scanner,
		/obj/item/multitool,
		/obj/item/organ/monster_core,
		/obj/item/pickaxe,
		/obj/item/radio,
		/obj/item/reagent_containers/cup/glass,
		/obj/item/reagent_containers/cup/glass/bottle,
		/obj/item/reagent_containers/hypospray,
		/obj/item/reagent_containers/pill,
		/obj/item/resonator,
		/obj/item/screwdriver,
		/obj/item/shovel,
		/obj/item/stack/cable_coil,
		/obj/item/stack/marker_beacon,
		/obj/item/stack/medical,
		/obj/item/stack/ore,
		/obj/item/stack/sheet/animalhide,
		/obj/item/stack/sheet/bone,
		/obj/item/stack/sheet/sinew,
		/obj/item/storage/bag/ore,
		/obj/item/storage/fancy/cigarettes,
		/obj/item/storage/pill_bottle,
		/obj/item/survivalcapsule,
		/obj/item/t_scanner/adv_mining_scanner,
		/obj/item/weldingtool,
		/obj/item/wirecutters,
		/obj/item/wrench,
		/obj/item/wormhole_jaunter,
		/obj/item/skeleton_key,
	))


/obj/item/storage/belt/mining/vendor/PopulateContents()
	new /obj/item/survivalcapsule(src)

/obj/item/storage/belt/mining/alt
	icon_state = "explorer2"
	inhand_icon_state = "explorer2"
	worn_icon_state = "explorer2"

/obj/item/storage/belt/mining/healing/PopulateContents()
	for(var/i in 1 to 2)
		new /obj/item/reagent_containers/hypospray/medipen/survival/luxury(src)
	for(var/i in 1 to 2)
		new /obj/item/reagent_containers/hypospray/medipen/survival(src)
	for(var/i in 1 to 2)
		var/obj/item/organ/monster_core/core = new /obj/item/organ/monster_core/regenerative_core/legion(src)
		core.preserve()

/obj/item/storage/belt/mining/primitive
	name = "hunter's belt"
	desc = "A versatile belt, woven from sinew."
	icon_state = "ebelt"
	inhand_icon_state = "ebelt"
	worn_icon_state = "ebelt"

/obj/item/storage/belt/mining/primitive/Initialize(mapload)
	. = ..()
	atom_storage.max_slots = 5

/obj/item/storage/belt/soulstone
	name = "soul stone belt"
	desc = "Designed for ease of access to the shards during a fight, as to not let a single enemy spirit slip away."
	icon_state = "soulstonebelt"
	inhand_icon_state = "soulstonebelt"
	worn_icon_state = "soulstonebelt"
	drop_sound = 'sound/items/handling/toolbelt_drop.ogg'
	pickup_sound = 'sound/items/handling/toolbelt_pickup.ogg'

/obj/item/storage/belt/soulstone/Initialize(mapload)
	. = ..()
	atom_storage.max_slots = 6
	atom_storage.set_holdable(/obj/item/soulstone)

/obj/item/storage/belt/soulstone/full/PopulateContents()
	for(var/i in 1 to 6)
		new /obj/item/soulstone/mystic(src)

/obj/item/storage/belt/soulstone/full/chappy/PopulateContents()
	for(var/i in 1 to 6)
		new /obj/item/soulstone/anybody/chaplain(src)

/obj/item/storage/belt/champion
	name = "championship belt"
	desc = "Proves to the world that you are the strongest!"
	icon_state = "championbelt"
	inhand_icon_state = "championbelt"
	worn_icon_state = "championbelt"
	custom_materials = list(/datum/material/gold=SMALL_MATERIAL_AMOUNT *4)

/obj/item/storage/belt/champion/Initialize(mapload)
	. = ..()
	atom_storage.max_slots = 1
	atom_storage.set_holdable(/obj/item/clothing/mask/luchador)
	AddComponent(/datum/component/adjust_fishing_difficulty, -2)

/obj/item/storage/belt/military
	name = "chest rig"
	desc = "A set of tactical webbing worn by Syndicate boarding parties."
	icon_state = "militarywebbing"
	inhand_icon_state = "militarywebbing"
	worn_icon_state = "militarywebbing"
	resistance_flags = FIRE_PROOF

/obj/item/storage/belt/military/Initialize(mapload)
	. = ..()
	atom_storage.max_specific_storage = WEIGHT_CLASS_SMALL

/obj/item/storage/belt/military/snack
	name = "tactical snack rig"

/obj/item/storage/belt/military/snack/Initialize(mapload)
	. = ..()
	var/sponsor = pick("Donk Co.", "Waffle Corp.", "Roffle Co.", "Gorlex Marauders", "Tiger Cooperative")
	desc = "A set of snack-tical webbing worn by athletes of the [sponsor] VR sports division."
	atom_storage.max_slots = 6
	atom_storage.max_specific_storage = WEIGHT_CLASS_SMALL
	atom_storage.set_holdable(list(
		/obj/item/food,
		/obj/item/reagent_containers/cup/glass,
	))

/obj/item/storage/belt/military/snack/full

/obj/item/storage/belt/military/snack/full/Initialize(mapload)
	. = ..()
	var/amount = 5
	var/rig_snacks
	while(contents.len <= amount)
		rig_snacks = pick(list(
			/obj/item/food/candy,
			/obj/item/food/cheesiehonkers,
			/obj/item/food/cheesynachos,
			/obj/item/food/chips,
			/obj/item/food/cubannachos,
			/obj/item/food/donkpocket,
			/obj/item/food/nachos,
			/obj/item/food/nugget,
			/obj/item/food/rofflewaffles,
			/obj/item/food/sosjerky,
			/obj/item/food/spacetwinkie,
			/obj/item/food/spaghetti/pastatomato,
			/obj/item/food/syndicake,
			/obj/item/reagent_containers/cup/glass/drinkingglass/filled/nuka_cola,
			/obj/item/reagent_containers/cup/glass/dry_ramen,
			/obj/item/reagent_containers/cup/soda_cans/cola,
			/obj/item/reagent_containers/cup/soda_cans/dr_gibb,
			/obj/item/reagent_containers/cup/soda_cans/lemon_lime,
			/obj/item/reagent_containers/cup/soda_cans/pwr_game,
			/obj/item/reagent_containers/cup/soda_cans/space_mountain_wind,
			/obj/item/reagent_containers/cup/soda_cans/space_up,
			/obj/item/reagent_containers/cup/soda_cans/starkist,
		))
		new rig_snacks(src)

/obj/item/storage/belt/military/abductor
	name = "agent belt"
	desc = "A belt used by abductor agents."
	icon = 'icons/obj/antags/abductor.dmi'
	icon_state = "belt"
	inhand_icon_state = "security"
	worn_icon_state = "security"
	content_overlays = TRUE

/obj/item/storage/belt/military/abductor/full/PopulateContents()
	new /obj/item/screwdriver/abductor(src)
	new /obj/item/wrench/abductor(src)
	new /obj/item/weldingtool/abductor(src)
	new /obj/item/crowbar/abductor(src)
	new /obj/item/wirecutters/abductor(src)
	new /obj/item/multitool/abductor(src)
	new /obj/item/stack/cable_coil(src)

/obj/item/storage/belt/military/army
	name = "army belt"
	desc = "A belt used by military forces."
	icon_state = "military"
	inhand_icon_state = "security"
	worn_icon_state = "military"

/obj/item/storage/belt/military/assault
	name = "assault belt"
	desc = "A tactical assault belt."
	icon_state = "assault"
	inhand_icon_state = "security"
	worn_icon_state = "assault"

/obj/item/storage/belt/military/assault/Initialize(mapload)
	. = ..()
	atom_storage.max_slots = 6

/obj/item/storage/belt/military/assault/full/PopulateContents()
	generate_items_inside(list(
		/obj/item/ammo_box/magazine/wt550m9 = 4,
		/obj/item/ammo_box/magazine/wt550m9/wtap = 2,
	), src)

/obj/item/storage/belt/grenade
	name = "grenadier belt"
	desc = "A belt for holding grenades."
	icon_state = "grenadebeltnew"
	inhand_icon_state = "security"
	worn_icon_state = "grenadebeltnew"
	drop_sound = 'sound/items/handling/toolbelt_drop.ogg'
	pickup_sound = 'sound/items/handling/toolbelt_pickup.ogg'

/obj/item/storage/belt/grenade/Initialize(mapload)
	. = ..()
	atom_storage.max_slots = 30
	atom_storage.numerical_stacking = TRUE
	atom_storage.max_total_storage = 60
	atom_storage.max_specific_storage = WEIGHT_CLASS_BULKY
	atom_storage.set_holdable(list(
		/obj/item/food/grown/cherry_bomb,
		/obj/item/food/grown/firelemon,
		/obj/item/grenade,
		/obj/item/grenade/c4,
		/obj/item/lighter,
		/obj/item/multitool,
		/obj/item/reagent_containers/cup/glass/bottle/molotov,
		/obj/item/screwdriver,
	))

/obj/item/storage/belt/grenade/full/PopulateContents()
	generate_items_inside(list(
		/obj/item/grenade/chem_grenade/incendiary = 2,
		/obj/item/grenade/empgrenade = 2,
		/obj/item/grenade/frag = 10,
		/obj/item/grenade/flashbang = 2,
		/obj/item/grenade/gluon = 4,
		/obj/item/grenade/smokebomb = 4,
		/obj/item/grenade/syndieminibomb = 2,
		/obj/item/multitool = 1,
		/obj/item/screwdriver = 1,
	),src)


/obj/item/storage/belt/wands
	name = "wand belt"
	desc = "A belt designed to hold various rods of power. A veritable fanny pack of exotic magic."
	icon_state = "soulstonebelt"
	inhand_icon_state = "soulstonebelt"
	worn_icon_state = "soulstonebelt"

/obj/item/storage/belt/wands/Initialize(mapload)
	. = ..()
	atom_storage.max_slots = 7
	atom_storage.set_holdable(/obj/item/gun/magic/wand)

/obj/item/storage/belt/wands/full/PopulateContents()
	new /obj/item/gun/magic/wand/death(src)
	new /obj/item/gun/magic/wand/resurrection(src)
	new /obj/item/gun/magic/wand/polymorph(src)
	new /obj/item/gun/magic/wand/teleport(src)
	new /obj/item/gun/magic/wand/door(src)
	new /obj/item/gun/magic/wand/fireball(src)
	new /obj/item/gun/magic/wand/shrink(src)

	for(var/obj/item/gun/magic/wand/W in contents) //All wands in this pack come in the best possible condition
		W.max_charges = initial(W.max_charges)
		W.charges = W.max_charges

/obj/item/storage/belt/janitor
	name = "janibelt"
	desc = "A belt used to hold most janitorial supplies."
	icon_state = "janibelt"
	inhand_icon_state = "janibelt"
	worn_icon_state = "janibelt"
	drop_sound = 'sound/items/handling/toolbelt_drop.ogg'
	pickup_sound = 'sound/items/handling/toolbelt_pickup.ogg'

/obj/item/storage/belt/janitor/Initialize(mapload)
	. = ..()
	atom_storage.max_slots = 6
	atom_storage.max_specific_storage = WEIGHT_CLASS_NORMAL // Set to this so the  light replacer can fit.
	atom_storage.set_holdable(list(
		/obj/item/access_key,
		/obj/item/assembly/mousetrap,
		/obj/item/clothing/gloves,
		/obj/item/flashlight,
		/obj/item/forcefield_projector,
		/obj/item/grenade/chem_grenade,
		/obj/item/holosign_creator,
		/obj/item/key/janitor,
		/obj/item/lightreplacer,
		/obj/item/melee/flyswatter,
		/obj/item/paint/paint_remover,
		/obj/item/plunger,
		/obj/item/pushbroom,
		/obj/item/reagent_containers/spray,
		/obj/item/soap,
		/obj/item/wirebrush,
	))

/obj/item/storage/belt/janitor/full/PopulateContents()
	new /obj/item/lightreplacer(src)
	new /obj/item/reagent_containers/spray/cleaner(src)
	new /obj/item/soap/nanotrasen(src)
	new /obj/item/holosign_creator(src)
	new /obj/item/melee/flyswatter(src)

/obj/item/storage/belt/bandolier
	name = "bandolier"
	desc = "A bandolier for holding rifle shotgun, and bigger revolver caliber ammunition."
	icon_state = "bandolier"
	inhand_icon_state = "bandolier"
	worn_icon_state = "bandolier"

/obj/item/storage/belt/bandolier/Initialize(mapload)
	. = ..()
	atom_storage.max_slots = 24
	atom_storage.max_total_storage = 24
	atom_storage.numerical_stacking = TRUE
	atom_storage.allow_quick_gather = TRUE
	atom_storage.allow_quick_empty = TRUE
	atom_storage.numerical_stacking = TRUE
	atom_storage.set_holdable(list(
		/obj/item/ammo_casing/strilka310,
		/obj/item/ammo_casing/shotgun,
		/obj/item/ammo_casing/c357,
		/obj/item/ammo_casing/junk,
	))

/obj/item/storage/belt/fannypack
	name = "fannypack"
	desc = "A dorky fannypack for keeping small items in. Concealed enough, or ugly enough to avert their eyes, that others won't see what you put in or take out easily."
	icon_state = "fannypack_leather"
	inhand_icon_state = null
	worn_icon_state = "fannypack_leather"
	dying_key = DYE_REGISTRY_FANNYPACK
	custom_price = PAYCHECK_CREW * 2

/obj/item/storage/belt/fannypack/Initialize(mapload)
	. = ..()
	atom_storage.max_slots = 3
	atom_storage.max_specific_storage = WEIGHT_CLASS_SMALL
	atom_storage.silent = TRUE

/obj/item/storage/belt/fannypack/black
	name = "black fannypack"
	icon_state = "fannypack_black"
	worn_icon_state = "fannypack_black"

/obj/item/storage/belt/fannypack/red
	name = "red fannypack"
	icon_state = "fannypack_red"
	worn_icon_state = "fannypack_red"

/obj/item/storage/belt/fannypack/purple
	name = "purple fannypack"
	icon_state = "fannypack_purple"
	worn_icon_state = "fannypack_purple"

/obj/item/storage/belt/fannypack/blue
	name = "blue fannypack"
	icon_state = "fannypack_blue"
	worn_icon_state = "fannypack_blue"

/obj/item/storage/belt/fannypack/orange
	name = "orange fannypack"
	icon_state = "fannypack_orange"
	worn_icon_state = "fannypack_orange"

/obj/item/storage/belt/fannypack/white
	name = "white fannypack"
	icon_state = "fannypack_white"
	worn_icon_state = "fannypack_white"

/obj/item/storage/belt/fannypack/green
	name = "green fannypack"
	icon_state = "fannypack_green"
	worn_icon_state = "fannypack_green"

/obj/item/storage/belt/fannypack/pink
	name = "pink fannypack"
	icon_state = "fannypack_pink"
	worn_icon_state = "fannypack_pink"

/obj/item/storage/belt/fannypack/cyan
	name = "cyan fannypack"
	icon_state = "fannypack_cyan"
	worn_icon_state = "fannypack_cyan"

/obj/item/storage/belt/fannypack/yellow
	name = "yellow fannypack"
	icon_state = "fannypack_yellow"
	worn_icon_state = "fannypack_yellow"

/obj/item/storage/belt/fannypack/cummerbund
	name = "cummerbund"
	desc = "A pleated sash that pairs well with a suit jacket."
	icon_state = "cummerbund"
	inhand_icon_state = null
	worn_icon_state = "cummerbund"

/obj/item/storage/belt/sabre
	name = "sabre sheath"
	desc = "An ornate sheath designed to hold an officer's blade."
	icon_state = "sheath"
	inhand_icon_state = "sheath"
	worn_icon_state = "sheath"
	w_class = WEIGHT_CLASS_BULKY
	interaction_flags_click = parent_type::interaction_flags_click | NEED_DEXTERITY | NEED_HANDS

/obj/item/storage/belt/sabre/Initialize(mapload)
	. = ..()
	AddElement(/datum/element/update_icon_updates_onmob)

	atom_storage.max_slots = 1
	atom_storage.do_rustle = FALSE
	atom_storage.max_specific_storage = WEIGHT_CLASS_BULKY
	atom_storage.set_holdable(/obj/item/melee/sabre)
	atom_storage.click_alt_open = FALSE

/obj/item/storage/belt/sabre/examine(mob/user)
	. = ..()
	if(length(contents))
		. += span_notice("Alt-click it to quickly draw the blade.")

/obj/item/storage/belt/sabre/click_alt(mob/user)
	if(length(contents))
		var/obj/item/I = contents[1]
		user.visible_message(span_notice("[user] takes [I] out of [src]."), span_notice("You take [I] out of [src]."))
		user.put_in_hands(I)
		update_appearance()
	else
		balloon_alert(user, "it's empty!")
	return CLICK_ACTION_SUCCESS

/obj/item/storage/belt/sabre/update_icon_state()
	icon_state = initial(inhand_icon_state)
	inhand_icon_state = initial(inhand_icon_state)
	worn_icon_state = initial(worn_icon_state)
	if(contents.len)
		icon_state += "-sabre"
		inhand_icon_state += "-sabre"
		worn_icon_state += "-sabre"
	return ..()

/obj/item/storage/belt/sabre/PopulateContents()
	new /obj/item/melee/sabre(src)
	update_appearance()

/obj/item/storage/belt/grass_sabre
	name = "sabre sheath"
	desc = "A simple grass sheath designed to hold a sabre of... some sort. An actual metal one might be too sharp, though..."
	icon_state = "grass_sheath"
	inhand_icon_state = "grass_sheath"
	worn_icon_state = "grass_sheath"
	w_class = WEIGHT_CLASS_BULKY
	interaction_flags_click = parent_type::interaction_flags_click | NEED_DEXTERITY | NEED_HANDS

/obj/item/storage/belt/grass_sabre/Initialize(mapload)
	. = ..()
	AddElement(/datum/element/update_icon_updates_onmob)

	atom_storage.max_slots = 1
	atom_storage.do_rustle = FALSE
	atom_storage.max_specific_storage = WEIGHT_CLASS_BULKY
	atom_storage.set_holdable(/obj/item/melee/parsnip_sabre)
	atom_storage.click_alt_open = FALSE

/obj/item/storage/belt/grass_sabre/examine(mob/user)
	. = ..()
	if(length(contents))
		. += span_notice("Alt-click it to quickly draw the blade.")

/obj/item/storage/belt/grass_sabre/click_alt(mob/user)
	if(length(contents))
		var/obj/item/I = contents[1]
		user.visible_message(span_notice("[user] takes [I] out of [src]."), span_notice("You take [I] out of [src]."))
		user.put_in_hands(I)
		update_appearance()
	else
		balloon_alert(user, "it's empty!")
	return CLICK_ACTION_SUCCESS

/obj/item/storage/belt/grass_sabre/update_icon_state()
	icon_state = initial(inhand_icon_state)
	inhand_icon_state = initial(inhand_icon_state)
	worn_icon_state = initial(worn_icon_state)
	if(contents.len)
		icon_state += "-sabre"
		inhand_icon_state += "-sabre"
		worn_icon_state += "-sabre"
	return ..()

/obj/item/storage/belt/plant
	name = "botanical belt"
	desc = "A sturdy leather belt used to hold most hydroponics supplies."
	icon_state = "plantbelt"
	inhand_icon_state = "utility"
	worn_icon_state = "plantbelt"
	content_overlays = TRUE

/obj/item/storage/belt/plant/Initialize(mapload)
	. = ..()
	atom_storage.max_slots = 6
	atom_storage.max_specific_storage = WEIGHT_CLASS_NORMAL
	atom_storage.set_holdable(list(
		/obj/item/cultivator,
		/obj/item/geneshears,
		/obj/item/graft,
		/obj/item/gun/energy/floragun,
		/obj/item/hatchet,
		/obj/item/plant_analyzer,
		/obj/item/reagent_containers/cup/beaker,
		/obj/item/reagent_containers/cup/bottle,
		/obj/item/reagent_containers/cup/tube,
		/obj/item/reagent_containers/spray/pestspray,
		/obj/item/reagent_containers/spray/plantbgone,
		/obj/item/secateurs,
		/obj/item/seeds,
		/obj/item/shovel/spade,
	))
