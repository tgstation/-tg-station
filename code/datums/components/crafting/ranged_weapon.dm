/datum/crafting_recipe/bola
	name = "Bola"
	result = /obj/item/restraints/legcuffs/bola
	reqs = list(
		/obj/item/restraints/handcuffs/cable = 1,
		/obj/item/stack/sheet/iron = 6,
	)
	time = 2 SECONDS //faster than crafting them by hand!
	category = CAT_WEAPON_RANGED

/datum/crafting_recipe/gonbola
	name = "Gonbola"
	result = /obj/item/restraints/legcuffs/bola/gonbola
	reqs = list(
		/obj/item/restraints/handcuffs/cable = 1,
		/obj/item/stack/sheet/iron = 6,
		/obj/item/stack/sheet/animalhide/gondola = 1,
	)
	time = 4 SECONDS
	category = CAT_WEAPON_RANGED

/datum/crafting_recipe/receiver
	name = "Modular Rifle Receiver"
	tool_behaviors = list(TOOL_WRENCH, TOOL_WELDER, TOOL_SAW)
	result = /obj/item/weaponcrafting/receiver
	reqs = list(
		/obj/item/stack/sheet/iron = 5,
		/obj/item/stack/sticky_tape = 1,
		/obj/item/screwdriver = 1,
		/obj/item/assembly/mousetrap = 1,
	)
	time = 10 SECONDS
	category = CAT_WEAPON_RANGED

/datum/crafting_recipe/riflestock
	name = "Wooden Rifle Stock"
	tool_paths = list(/obj/item/hatchet)
	result = /obj/item/weaponcrafting/stock
	reqs = list(
		/obj/item/stack/sheet/mineral/wood = 8,
		/obj/item/stack/sticky_tape = 1,
	)
	time = 5 SECONDS
	category = CAT_WEAPON_RANGED

/datum/crafting_recipe/gun_maint_kit
	name = "Makeshift Gun Maintenance Kit"
	tool_behaviors = list(TOOL_WRENCH, TOOL_WELDER, TOOL_SCREWDRIVER)
	result = /obj/item/gun_maintenance_supplies/makeshift
	reqs = list(
		/obj/item/stack/sheet/iron = 5,
		/obj/item/stack/sticky_tape = 1,
		/obj/item/pipe = 1,
		/obj/item/stack/sheet/cloth = 2,
	)
	time = 5 SECONDS
	category = CAT_WEAPON_RANGED

/datum/crafting_recipe/advancedegun
	name = "Advanced Energy Gun"
	result = /obj/item/gun/energy/e_gun/nuclear
	reqs = list(
		/obj/item/gun/energy/e_gun = 1,
		/obj/item/weaponcrafting/gunkit/nuclear = 1,
	)
	time = 10 SECONDS
	category = CAT_WEAPON_RANGED

/datum/crafting_recipe/advancedegun/New()
	..()
	blacklist += subtypesof(/obj/item/gun/energy/e_gun)

/datum/crafting_recipe/tempgun
	name = "Temperature Gun"
	result = /obj/item/gun/energy/temperature
	reqs = list(
		/obj/item/gun/energy/disabler = 1,
		/obj/item/weaponcrafting/gunkit/temperature = 1,
	)
	time = 10 SECONDS
	category = CAT_WEAPON_RANGED

/datum/crafting_recipe/tempgun/New()
	..()
	blacklist += subtypesof(/obj/item/gun/energy/e_gun)

/datum/crafting_recipe/beam_rifle
	name = "Event Horizon Anti-Existential Beam Rifle"
	result = /obj/item/gun/energy/event_horizon
	reqs = list(
		/obj/item/assembly/signaler/anomaly/flux = 2,
		/obj/item/assembly/signaler/anomaly/grav = 1,
		/obj/item/assembly/signaler/anomaly/vortex = (MAX_CORES_VORTEX - 1),
		/obj/item/assembly/signaler/anomaly/bluespace = 1,
		/obj/item/weaponcrafting/gunkit/beam_rifle = 1,
	)
	time = 30 SECONDS //Maybe the delay will make you reconsider your choices
	category = CAT_WEAPON_RANGED

/datum/crafting_recipe/ebow
	name = "Energy Crossbow"
	result = /obj/item/gun/energy/recharge/ebow/large
	reqs = list(
		/obj/item/gun/energy/recharge/kinetic_accelerator = 1,
		/obj/item/weaponcrafting/gunkit/ebow = 1,
		/datum/reagent/uranium/radium = 15,
	)
	time = 10 SECONDS
	category = CAT_WEAPON_RANGED

/datum/crafting_recipe/xraylaser
	name = "X-ray Laser Gun"
	result = /obj/item/gun/energy/xray
	reqs = list(
		/obj/item/gun/energy/laser = 1,
		/obj/item/weaponcrafting/gunkit/xray = 1,
	)
	time = 10 SECONDS
	category = CAT_WEAPON_RANGED

/datum/crafting_recipe/xraylaser/New()
	..()
	blacklist += subtypesof(/obj/item/gun/energy/laser)

/datum/crafting_recipe/hellgun
	name = "Hellfire Laser Gun"
	result = /obj/item/gun/energy/laser/hellgun
	reqs = list(
		/obj/item/gun/energy/laser = 1,
		/obj/item/weaponcrafting/gunkit/hellgun = 1,
	)
	time = 10 SECONDS
	category = CAT_WEAPON_RANGED

/datum/crafting_recipe/hellgun/New()
	..()
	blacklist += subtypesof(/obj/item/gun/energy/laser)

/datum/crafting_recipe/ioncarbine
	name = "Ion Carbine"
	result = /obj/item/gun/energy/ionrifle/carbine
	reqs = list(
		/obj/item/gun/energy/laser = 1,
		/obj/item/weaponcrafting/gunkit/ion = 1,
	)
	time = 10 SECONDS
	category = CAT_WEAPON_RANGED

/datum/crafting_recipe/ioncarbine/New()
	..()
	blacklist += subtypesof(/obj/item/gun/energy/laser)

/datum/crafting_recipe/teslacannon
	name = "Tesla Cannon"
	result = /obj/item/gun/energy/tesla_cannon
	reqs = list(
		/obj/item/assembly/signaler/anomaly/flux = 1,
		/obj/item/weaponcrafting/gunkit/tesla = 1,
	)
	time = 10 SECONDS
	category = CAT_WEAPON_RANGED

/datum/crafting_recipe/improvised_pneumatic_cannon //Pretty easy to obtain but
	name = "Pneumatic Cannon"
	result = /obj/item/pneumatic_cannon/ghetto
	tool_behaviors = list(TOOL_WELDER, TOOL_WRENCH)
	reqs = list(
		/obj/item/stack/sheet/iron = 4,
		/obj/item/stack/package_wrap = 8,
		/obj/item/pipe = 2,
	)
	time = 5 SECONDS
	category = CAT_WEAPON_RANGED

/datum/crafting_recipe/flamethrower
	name = "Flamethrower"
	result = /obj/item/flamethrower
	reqs = list(
		/obj/item/weldingtool = 1,
		/obj/item/assembly/igniter = 1,
		/obj/item/stack/rods = 1,
	)
	parts = list(
		/obj/item/assembly/igniter = 1,
		/obj/item/weldingtool = 1,
	)
	tool_behaviors = list(TOOL_SCREWDRIVER)
	time = 1 SECONDS
	category = CAT_WEAPON_RANGED

/datum/crafting_recipe/pipegun
	name = "Pipegun"
	result = /obj/item/gun/ballistic/rifle/boltaction/pipegun
	reqs = list(
		/obj/item/weaponcrafting/receiver = 1,
		/obj/item/pipe = 2,
		/obj/item/weaponcrafting/stock = 1,
		/obj/item/storage/toolbox = 1, // for the screws
		/obj/item/stack/sticky_tape = 1,
	)
	tool_behaviors = list(TOOL_SCREWDRIVER)
	time = 5 SECONDS
	category = CAT_WEAPON_RANGED

/datum/crafting_recipe/pipepistol
	name = "Pipe Pistol"
	result = /obj/item/gun/ballistic/rifle/boltaction/pipegun/pistol
	reqs = list(
		/obj/item/weaponcrafting/receiver = 1,
		/obj/item/pipe = 1,
		/obj/item/stock_parts/servo = 2,
		/obj/item/stack/sheet/mineral/wood = 4,
		/obj/item/storage/toolbox = 1, // for the screws
		/obj/item/stack/sticky_tape = 1,
	)
	tool_paths = list(/obj/item/hatchet)
	tool_behaviors = list(TOOL_SCREWDRIVER)
	time = 5 SECONDS
	category = CAT_WEAPON_RANGED

/datum/crafting_recipe/rebarxbow
	name = "Heated Rebar Crossbow"
	result = /obj/item/gun/ballistic/rifle/rebarxbow
	reqs = list(
		/obj/item/stack/rods = 6,
		/obj/item/stack/cable_coil = 12,
		/obj/item/inducer =  1,
	)
	blacklist = list(
		/obj/item/inducer/sci,
	)
	tool_behaviors = list(TOOL_WELDER)
	time = 5 SECONDS
	category = CAT_WEAPON_RANGED

/datum/crafting_recipe/rebarxbowforced
	name = "Forced Rebar Crossbow"
	desc = "A much quicker reload... for a chance of shooting yourself when you fire it."
	result = /obj/item/gun/ballistic/rifle/rebarxbow/forced
	reqs = list(
		/obj/item/gun/ballistic/rifle/rebarxbow = 1,
	)
	blacklist = list(
	/obj/item/gun/ballistic/rifle/rebarxbow/forced,
	/obj/item/gun/ballistic/rifle/rebarxbow/syndie,
	)
	tool_behaviors = list(TOOL_CROWBAR)
	time = 1 SECONDS
	category = CAT_WEAPON_RANGED

/datum/crafting_recipe/pipegun_prime
	name = "Regal Pipegun"
	result = /obj/item/gun/ballistic/rifle/boltaction/pipegun/prime
	reqs = list(
		/obj/item/gun/ballistic/rifle/boltaction/pipegun = 1,
		/obj/item/food/deadmouse = 1,
		/datum/reagent/consumable/grey_bull = 20,
		/obj/item/spear = 1,
		/obj/item/storage/toolbox = 1,
		/obj/item/clothing/head/costume/crown = 1, // Any ol' crown will do
	)
	tool_behaviors = list(TOOL_SCREWDRIVER)
	tool_paths = list(/obj/item/clothing/gloves/color/yellow, /obj/item/clothing/mask/gas, /obj/item/melee/baton/security/cattleprod)
	time = 15 SECONDS //contemplate for a bit
	category = CAT_WEAPON_RANGED
	crafting_flags = CRAFT_CHECK_DENSITY | CRAFT_MUST_BE_LEARNED

/datum/crafting_recipe/deagle_prime //When you factor in the makarov (7 tc), the toolbox (1 tc), and the emag (3 tc), this comes to a total of 18 TC or thereabouts. Igorning the 20k pricetag, obviously.
	name = "Regal Condor"
	result = /obj/item/gun/ballistic/automatic/pistol/deagle/regal
	reqs = list(
		/obj/item/gun/ballistic/automatic/pistol = 1,
		/obj/item/stack/sheet/mineral/gold = 25,
		/obj/item/stack/sheet/mineral/silver = 25,
		/obj/item/food/donkpocket = 1,
		/obj/item/stack/telecrystal = 4,
		/obj/item/clothing/head/costume/crown/fancy = 1, //the captain's crown
		/obj/item/storage/toolbox/syndicate = 1,
		/obj/item/stack/sheet/iron = 10,
	)
	tool_behaviors = list(TOOL_SCREWDRIVER)
	tool_paths = list(
		/obj/item/clothing/under/syndicate,
		/obj/item/clothing/mask/gas/syndicate,
		/obj/item/card/emag
	)
	time = 30 SECONDS
	category = CAT_WEAPON_RANGED
	crafting_flags = CRAFT_CHECK_DENSITY | CRAFT_MUST_BE_LEARNED

/datum/crafting_recipe/deagle_prime/New()
	..()
	blacklist += subtypesof(/obj/item/gun/ballistic/automatic/pistol)

/datum/crafting_recipe/deagle_prime_mag
	name = "Regal Condor Magazine (10mm Reaper)"
	result = /obj/item/ammo_box/magazine/r10mm
	reqs = list(
		/obj/item/stack/sheet/iron = 10,
		/obj/item/stack/sheet/mineral/gold = 10,
		/obj/item/stack/sheet/mineral/silver = 10,
		/obj/item/stack/sheet/mineral/plasma = 10,
		/obj/item/food/donkpocket = 1, //Station mass murder, as sponsored by Donk Co.
	)
	tool_behaviors = list(TOOL_SCREWDRIVER, TOOL_WELDER)
	tool_paths = list(
		/obj/item/clothing/under/syndicate,
		/obj/item/clothing/mask/gas/syndicate,
		/obj/item/card/emag,
		/obj/item/gun/ballistic/automatic/pistol/deagle/regal
	)
	time = 5 SECONDS
	category = CAT_WEAPON_RANGED
	crafting_flags = CRAFT_CHECK_DENSITY | CRAFT_MUST_BE_LEARNED

/datum/crafting_recipe/pipe_organ_gun
	name = "Pipe Organ Gun"
	tool_behaviors = list(TOOL_WELDER, TOOL_SCREWDRIVER)
	result = /obj/structure/mounted_gun/pipe
	reqs = list(
		/obj/item/pipe = 8,
		/obj/item/stack/sheet/mineral/wood = 15,
		/obj/item/stack/sheet/iron = 10,
		/obj/item/storage/toolbox = 1,
		/obj/item/stack/rods = 10,
		/obj/item/assembly/igniter = 2,
	)
	time = 15 SECONDS
	category = CAT_WEAPON_RANGED
	crafting_flags = CRAFT_CHECK_DENSITY

/datum/crafting_recipe/trash_cannon
	name = "Trash Cannon"
	tool_behaviors = list(TOOL_WELDER, TOOL_SCREWDRIVER)
	result = /obj/structure/cannon/trash
	reqs = list(
		/obj/item/melee/skateboard/improvised = 1,
		/obj/item/tank/internals/oxygen = 1,
		/datum/reagent/drug/maint/tar = 15,
		/obj/item/restraints/handcuffs/cable = 1,
		/obj/item/storage/toolbox = 1,
	)
	category = CAT_WEAPON_RANGED
	crafting_flags = CRAFT_CHECK_DENSITY | CRAFT_MUST_BE_LEARNED

/datum/crafting_recipe/laser_musket
	name = "Laser Musket"
	result = /obj/item/gun/energy/laser/musket
	reqs = list(
		/obj/item/weaponcrafting/stock = 1,
		/obj/item/stack/cable_coil = 15,
		/obj/item/stack/rods = 4,
		/obj/item/stock_parts/micro_laser = 1,
		/obj/item/stock_parts/capacitor = 1,
		/obj/item/reagent_containers/cup/glass/drinkingglass = 2,
	)
	tool_behaviors = list(TOOL_SCREWDRIVER, TOOL_WIRECUTTER)
	time = 10 SECONDS
	category = CAT_WEAPON_RANGED

/datum/crafting_recipe/laser_musket_prime
	name = "Heroic Laser Musket"
	result = /obj/item/gun/energy/laser/musket/prime
	reqs = list(
		/obj/item/gun/energy/laser/musket = 1,
		/obj/item/stack/cable_coil = 15,
		/obj/item/stack/sheet/mineral/silver = 5,
		/obj/item/stock_parts/water_recycler = 1,
		/datum/reagent/consumable/nuka_cola = 15,
	)
	tool_behaviors = list(TOOL_SCREWDRIVER)
	tool_paths = list(/obj/item/clothing/head/cowboy, /obj/item/clothing/shoes/cowboy)
	time = 30 SECONDS //contemplate for a bit
	category = CAT_WEAPON_RANGED
	crafting_flags = CRAFT_CHECK_DENSITY | CRAFT_MUST_BE_LEARNED

/datum/crafting_recipe/smoothbore_disabler
	name = "Smoothbore Disabler"
	result = /obj/item/gun/energy/disabler/smoothbore
	reqs = list(
		/obj/item/weaponcrafting/stock = 1, //it becomes the grip
		/obj/item/stack/cable_coil = 5,
		/obj/item/pipe = 1,
		/obj/item/stock_parts/micro_laser = 1,
		/obj/item/stock_parts/power_store/cell = 1,
		/obj/item/assembly/mousetrap = 1,
	)
	tool_behaviors = list(TOOL_SCREWDRIVER, TOOL_WRENCH)
	time = 10 SECONDS
	category = CAT_WEAPON_RANGED

/datum/crafting_recipe/smoothbore_disabler_prime
	name = "Elite Smoothbore Disabler"
	result = /obj/item/gun/energy/disabler/smoothbore/prime
	reqs = list(
		/obj/item/gun/energy/disabler/smoothbore = 1,
		/obj/item/stack/sheet/mineral/gold = 5,
		/obj/item/stock_parts/power_store/cell/hyper = 1,
		/datum/reagent/reaction_agent/speed_agent = 10,
	)
	tool_behaviors = list(TOOL_SCREWDRIVER)
	time = 20 SECONDS
	category = CAT_WEAPON_RANGED
	crafting_flags = CRAFT_CHECK_DENSITY | CRAFT_MUST_BE_LEARNED

/datum/crafting_recipe/shortbow
	name = "Shortbow"
	result = /obj/item/gun/ballistic/bow/shortbow
	reqs = list(
		/obj/item/stack/sheet/mineral/wood = 4,
		/obj/item/stack/sheet/cloth = 2,
		/obj/item/stack/sheet/iron = 1,
	)
	tool_paths = list(
		/obj/item/hatchet,
	)
	time = 30 SECONDS
	category = CAT_WEAPON_RANGED
	crafting_flags = CRAFT_CHECK_DENSITY | CRAFT_MUST_BE_LEARNED

/datum/crafting_recipe/photoncannon
	name = "Photon Cannon"
	result = /obj/item/gun/energy/photon
	reqs = list(
		/obj/item/assembly/signaler/anomaly/flux = 1,
		/obj/item/weaponcrafting/gunkit/photon = 1,
	)
	time = 10 SECONDS
	category = CAT_WEAPON_RANGED

/datum/crafting_recipe/sks
	name = "Sakhno SKS semi-automatic rifle"
	result = /obj/item/gun/ballistic/automatic/sks/empty
	reqs = list(
		/obj/item/weaponcrafting/stock = 1,
		/obj/item/weaponcrafting/receiver = 1,
		/obj/item/weaponcrafting/gunkit/sks = 1,
	)
	tool_behaviors = list(TOOL_SCREWDRIVER)
	time = 10 SECONDS
	category = CAT_WEAPON_RANGED
