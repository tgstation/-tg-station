//as of:10/28/2019:
//boxstation: ~153 loot items spawned
//metastation: ~183 loot items spawned
//deltastation: ~165 loot items spawned

//how to balance maint loot spawns:
// 1) Ensure each category has items of approximately the same power level
// 2) Tune weight of each category until average power of a maint loot spawn is acceptable
// 3) Mapping considerations - Loot value should scale with difficulty of acquisition, or an assistaint will run through collecting free gear with no risk

//goal of maint loot:
// 1) Provide random equipment to people who take effort to crawl maint
// 2) Create memorable moments with very rare, crazy items

//Loot tables

GLOBAL_LIST_INIT(trash_loot, list(//junk: useless, very easy to get, or ghetto chemistry items
	list(//trash
		/obj/item/trash/can = 1,
		/obj/item/trash/candy = 1,
		/obj/item/trash/cheesie = 1,
		/obj/item/trash/chips = 1,
		/obj/item/trash/pistachios = 1,
		/obj/item/trash/popcorn = 1,
		/obj/item/trash/raisins = 1,
		/obj/item/trash/sosjerky = 1,
		/obj/item/trash/flare = 1,
		/obj/item/trash/candle = 1,

		/obj/item/c_tube = 1,
		/obj/item/disk/data = 1,
		/obj/item/folder/yellow = 1,
		/obj/item/hand_labeler = 1,
		/obj/item/paper = 1,
		/obj/item/paper/crumpled = 1,
		/obj/item/pen = 1,
		/obj/item/photo/old = 1,
		/obj/item/poster/random_contraband = 1,
		/obj/item/poster/random_official = 1,
		/obj/item/stack/sheet/cardboard = 1,
		/obj/item/storage/box = 1,

		/obj/effect/decal/cleanable/ash = 1,
		/obj/item/camera = 1,
		/obj/item/camera_film = 1,
		/obj/item/cigbutt = 1,
		/obj/item/coin/silver = 1,
		/obj/item/food/urinalcake = 1,
		/obj/item/light/bulb = 1,
		/obj/item/light/tube = 1,
		/obj/item/reagent_containers/cup/glass/drinkingglass = 1,

		/obj/item/airlock_painter = 1,
		/obj/item/airlock_painter/decal = 1,
		/obj/item/airlock_painter/decal/tile = 1,
		/obj/item/clothing/mask/breath = 1,
		/obj/item/rack_parts = 1,
		/obj/item/shard = 1,

		/obj/item/reagent_containers/pill/maintenance/achievement = 1,
		/obj/item/toy/eightball = 1,
		) = 8,

	list(//tier 1 stock parts
		/obj/item/stock_parts/capacitor = 1,
		/obj/item/stock_parts/servo = 1,
		/obj/item/stock_parts/matter_bin = 1,
		/obj/item/stock_parts/micro_laser = 1,
		/obj/item/stock_parts/scanning_module = 1,
		) = 1,
	))



GLOBAL_LIST_INIT(common_loot, list( //common: basic items
	list(//tools
		/obj/item/analyzer = 1,
		/obj/item/crowbar = 1,
		/obj/item/geiger_counter = 1,
		/obj/item/mop = 1,
		/obj/item/pushbroom = 1,
		/obj/item/reagent_containers/cup/bucket = 1,
		/obj/item/screwdriver = 1,
		/obj/item/t_scanner = 1,
		/obj/item/toy/crayon/spraycan = 1,
		/obj/item/weldingtool = 1,
		/obj/item/wirecutters = 1,
		/obj/item/wrench = 1,
		) = 1,

	list(//equipment
		/obj/effect/spawner/random/clothing/gloves = 1,
		/obj/item/clothing/glasses/meson = 1,
		/obj/item/clothing/glasses/science = 1,
		/obj/item/clothing/gloves/color/black = 1,
		/obj/item/clothing/gloves/color/fyellow = 1,
		/obj/item/clothing/mask/gas = 1,
		/obj/item/clothing/shoes/sneakers/black = 1,
		/obj/item/clothing/suit/hazardvest = 1,
		/obj/item/clothing/suit/toggle/labcoat = 1,
		/obj/item/clothing/under/color/grey = 1,
		/obj/item/radio/headset = 1,
		/obj/item/storage/backpack = 1,
		/obj/item/storage/belt/fannypack = 1,
		/obj/item/storage/wallet/random = 1,
		) = 1,

	list(//construction and crafting
		/obj/item/sign = 1,
		/obj/item/stack/cable_coil = 1,
		/obj/item/stack/rods/twentyfive = 1,
		/obj/item/stack/sheet/iron/twenty = 1,
		/obj/item/stack/sheet/mineral/plasma = 1,
		/obj/item/stock_parts/power_store/cell = 1,

		//assemblies
		/obj/item/assembly/health = 1,
		/obj/item/assembly/igniter = 1,
		/obj/item/assembly/infra = 1,
		/obj/item/assembly/mousetrap = 1,
		/obj/item/assembly/prox_sensor = 1,
		/obj/item/assembly/signaler = 1,
		/obj/item/assembly/timer = 1,
		/obj/item/stack/package_wrap = 1,
		/obj/item/stack/wrapping_paper = 1,
		) = 1,

	list(//medical and chemicals
		/obj/item/grenade/chem_grenade/cleaner = 1,
		/obj/item/lead_pipe = 1,
		/obj/item/reagent_containers/cup/beaker = 1,
		/obj/item/reagent_containers/cup/bottle/random_buffer = 2,
		/obj/item/reagent_containers/cup/rag = 1,
		/obj/item/reagent_containers/hypospray/medipen/pumpup = 2,
		/obj/item/reagent_containers/syringe = 1,
		/obj/item/stock_parts/power_store/cell/lead = 1,
		/obj/item/storage/box/matches = 1,
		/obj/item/storage/fancy/cigarettes/dromedaryco = 1,
		) = 1,

	list(//food
		/obj/item/reagent_containers/cup/glass/bottle/beer = 1,
		/obj/item/reagent_containers/cup/glass/coffee = 1,
		) = 1,

	list(//misc
		/obj/item/bodybag = 1,
		/obj/item/extinguisher = 1,
		/obj/item/grenade/smokebomb = 1,
		/obj/item/radio/off = 1,
		/obj/item/stack/spacecash/c10 = 1,
		/obj/item/stack/sticky_tape = 1,
		/obj/item/tank/internals/emergency_oxygen = 1,
		/obj/item/paper/paperslip/fishing_tip = 1,

		//light sources
		/obj/effect/spawner/random/decoration/glowstick = 1,
		/obj/item/clothing/head/utility/hardhat/red = 1,
		/obj/item/flashlight = 1,
		/obj/item/flashlight/flare = 1,
		) = 1,
	))



GLOBAL_LIST_INIT(uncommon_loot, list(//uncommon: useful items
	list(//tools
		/obj/item/grenade/iedcasing/spawned = 1,
		/obj/item/hatchet = 1,
		/obj/item/melee/baton/security/cattleprod = 1,
		/obj/item/multitool = 1,
		/obj/item/pen/fountain = 1,
		/obj/item/restraints/handcuffs/cable = 1,
		/obj/item/restraints/legcuffs/bola = 1,
		/obj/item/emergency_bed = 1,
		/obj/item/spear = 1,
		/obj/item/weldingtool/largetank = 1,
		/obj/item/market_uplink/blackmarket = 1,
		) = 8,

	list(//equipment
		/obj/item/clothing/ears/earmuffs = 1,
		/obj/item/clothing/glasses/hud/diagnostic = 1,
		/obj/item/clothing/glasses/hud/health = 1,
		/obj/item/clothing/glasses/salesman = 1,
		/obj/item/clothing/glasses/nightmare_vision = 1,
		/obj/item/clothing/glasses/welding = 1,
		/obj/item/clothing/gloves/tackler/offbrand = 1,
		/obj/item/clothing/head/helmet/old = 1,
		/obj/item/clothing/head/utility/welding = 1,
		/obj/item/clothing/mask/muzzle = 1,
		/obj/item/clothing/suit/armor/vest/old = 1,
		/obj/item/storage/belt/medical = 1,
		/obj/item/storage/belt/utility = 1,
		/obj/item/pen/screwdriver = 1,
		) = 8,

	list(//strange objects
		/obj/item/relic = 5,
		) = 8,

	list(//construction and crafting
		/obj/item/beacon = 1,
		/obj/item/paper/fluff/stations/soap = 1, //recipes count as crafting.
		/obj/item/plaque = 1,
		/obj/item/seeds/kronkus = 1,
		/obj/item/seeds/odious_puffball = 1,
		/obj/item/stack/sheet/mineral/wood/fifty = 1,
		/obj/item/stock_parts/power_store/cell/high = 1,
		/obj/item/storage/box/clown = 1,
		/obj/item/weaponcrafting/receiver = 1,
		/obj/item/book/granter/crafting_recipe/death_sandwich = 1,
		/obj/item/survivalcapsule/fishing = 1,
		) = 8,

	list(//medical and chemicals
		list(//basic healing items
			/obj/item/stack/medical/gauze = 1,
			/obj/item/stack/medical/mesh = 1,
			/obj/item/stack/medical/suture = 1,
			/obj/item/stack/medical/bandage = 1,
			) = 1,
		list(//medical chems
			/obj/item/reagent_containers/cup/bottle/multiver = 1,
			/obj/item/reagent_containers/hypospray/medipen = 1,
			/obj/item/reagent_containers/syringe/convermol = 1,
			) = 1,
		list(//drinks
			/obj/item/reagent_containers/cup/glass/bottle/vodka = 1,
			/obj/item/reagent_containers/cup/glass/drinkingglass/filled/nuka_cola = 1,
			/obj/item/reagent_containers/cup/soda_cans/grey_bull = 1,
			) = 1,
		list(//sprayers
			/obj/item/reagent_containers/spray = 1,
			/obj/item/watertank = 1,
			/obj/item/watertank/janitor = 1,
			) = 1,
		) = 8,

	list(//food
		/obj/item/food/canned/peaches/maint = 1,
		/obj/item/storage/box/donkpockets = 1,
		/obj/item/storage/box/gum/happiness = 1,
		list(//Donk Varieties
			/obj/item/storage/box/donkpockets/donkpocketberry = 1,
			/obj/item/storage/box/donkpockets/donkpockethonk = 1,
			/obj/item/storage/box/donkpockets/donkpocketpizza = 1,
			/obj/item/storage/box/donkpockets/donkpocketspicy = 1,
			/obj/item/storage/box/donkpockets/donkpocketteriyaki = 1,
			) = 1,
		list(//Donk-dinner Varieties
			/obj/item/food/ready_donk = 1,
			/obj/item/food/ready_donk/donkhiladas = 1,
			/obj/item/food/ready_donk/mac_n_cheese = 1,
			) = 1,
		/obj/item/food/monkeycube = 1,
		) = 8,

	list(//computer disks
		/obj/item/computer_disk/maintenance/scanner = 1,
		/obj/item/computer_disk/maintenance/camera = 1,
		/obj/item/computer_disk/maintenance/modsuit_control = 1,
		/obj/item/computer_disk/maintenance/spectre_meter = 1,
		/obj/item/computer_disk/maintenance/arcade = 1,
		/obj/item/disk/design_disk/liberator = 1,
		/obj/item/computer_disk/maintenance/theme = 3,
	) = 4,

	list(//modsuits
		/obj/effect/spawner/random/mod/maint = 3,
		/obj/item/mod/construction/broken_core = 1,
		) = 4,

	list(//music
		/obj/item/instrument/accordion = 5,
		/obj/item/instrument/banjo = 5,
		/obj/item/instrument/bikehorn = 2,
		/obj/item/instrument/eguitar = 5,
		/obj/item/instrument/glockenspiel = 5,
		/obj/item/instrument/guitar = 5,
		/obj/item/instrument/harmonica = 5,
		/obj/item/instrument/musicalmoth = 1,
		/obj/item/instrument/recorder = 5,
		/obj/item/instrument/saxophone = 5,
		/obj/item/instrument/trombone = 5,
		/obj/item/instrument/trumpet = 5,
		/obj/item/instrument/violin = 5,
		/obj/item/instrument/violin/golden = 2,
		) = 2,

	list(//fakeout items, keep this list at low relative weight
		/obj/item/clothing/shoes/jackboots = 1,
		/obj/item/dice/d20 = 1, //To balance out the stealth die of fates in oddities
		) = 1,
))



GLOBAL_LIST_INIT(rarity_loot, list(//rare: really good items
	list(//tools
		/obj/item/assembly/flash/memorizer = 1,
		/obj/item/flashlight/flashdark = 1,
		/obj/item/knife/kitchen = 1,
		/obj/item/melee/baton/security/cattleprod/teleprod = 1,
		/obj/item/pen/survival = 1,
		/obj/item/restraints/handcuffs = 1,
		/obj/item/shield/buckler = 1,
		/obj/item/shield/improvised = 1,
		/obj/item/throwing_star = 1,
		/obj/item/weldingtool/hugetank = 1,
		/obj/item/fishing_rod/telescopic/master = 1,
		/obj/item/spess_knife = 1,
		/obj/item/gun/ballistic/automatic/pistol/doorhickey = 1,
		) = 1,

	list(//equipment
		/obj/item/clothing/glasses/hud/security = 1,
		/obj/item/clothing/glasses/sunglasses = 1,
		/obj/item/clothing/gloves/color/black/security = 1,
		/obj/item/clothing/gloves/color/yellow = 1,
		/obj/item/clothing/gloves/tackler/combat = 1,
		/obj/item/clothing/head/helmet/toggleable/justice = 1,
		/obj/item/storage/belt/military/assault = 1,
		/obj/item/storage/belt/security = 1,
		) = 1,

	list(//paint
		/obj/item/paint/anycolor = 1,
		/obj/item/paint/black = 1,
		/obj/item/paint/blue = 1,
		/obj/item/paint/green = 1,
		/obj/item/paint/paint_remover = 1,
		/obj/item/paint/red = 1,
		/obj/item/paint/violet = 1,
		/obj/item/paint/white = 1,
		/obj/item/paint/yellow = 1,
		) = 1,

	list(//medical and chemicals
		list(//medkits
			/obj/item/storage/box/hug/medical = 1,
			/obj/item/storage/medkit/emergency = 1,
			/obj/item/storage/medkit/regular = 1,
			/obj/item/storage/box/bandages = 1,
			) = 1,
		list(//medical chems
			/obj/item/reagent_containers/hypospray/medipen/oxandrolone = 1,
			/obj/item/reagent_containers/hypospray/medipen/salacid = 1,
			/obj/item/reagent_containers/syringe/contraband/methamphetamine = 1,
			) = 1,
		) = 1,

	list(//misc
		/obj/item/book/granter/crafting_recipe/dusting/pipegun_prime = 1,
		/obj/item/book/granter/crafting_recipe/trash_cannon = 1,
		/obj/item/book/granter/crafting_recipe/dusting/laser_musket_prime = 1,
		/obj/item/book/granter/sign_language = 1,
		/obj/item/disk/nuclear/fake = 1,
		/obj/item/disk/surgery/advanced_plastic_surgery = 1,
		/obj/item/skillchip/brainwashing = 1,
		/obj/item/skillchip/intj = 1,
		/obj/item/tattoo_kit = 1,
		/obj/item/folder/ancient_paperwork = 1,
		) = 1,

))



GLOBAL_LIST_INIT(oddity_loot, list(//oddity: strange or crazy items
		/obj/effect/rune/teleport = 1,
		/obj/item/clothing/head/helmet/abductor = 1,
		/obj/item/clothing/shoes/jackboots/fast = 1,
		/obj/item/clothing/suit/armor/reactive/table = 1,
		/obj/item/dice/d20/fate/stealth/cursed = 1, //Only rolls 1
		/obj/item/dice/d20/fate/stealth/one_use = 1, //Looks like a d20, keep the d20 in the uncommon pool.
		/obj/item/shadowcloak = 1,
		/obj/item/spear/grey_tide = 1,
		/obj/item/storage/box/donkpockets/donkpocketgondola = 1,
		list(//music
			/obj/item/instrument/saxophone/spectral = 1,
			/obj/item/instrument/trombone/spectral = 1,
			/obj/item/instrument/trumpet/spectral = 1,
			) = 1,
		/obj/item/toy/cards/deck/tarot/haunted = 1,
	))

//Maintenance loot spawner pools
#define maint_trash_weight 4500
#define maint_common_weight 4500
#define maint_uncommon_weight 900
#define maint_rarity_weight 99
#define maint_oddity_weight 1 //1 out of 10,000 would give metastation (180 spawns) a 2 in 111 chance of spawning an oddity per round, similar to xeno egg
#define maint_holiday_weight 3500 // When holiday loot is enabled, it'll give every loot item a 25% chance of being a holiday item

//Loot pool used by default maintenance loot spawners
GLOBAL_LIST_INIT(maintenance_loot, list(
	GLOB.trash_loot = maint_trash_weight,
	GLOB.common_loot = maint_common_weight,
	GLOB.uncommon_loot = maint_uncommon_weight,
	GLOB.rarity_loot = maint_rarity_weight,
	GLOB.oddity_loot = maint_oddity_weight,
	))

GLOBAL_LIST_INIT(ratking_trash, list(//Garbage: used by the regal rat mob when spawning garbage.
			/obj/item/cigbutt,
			/obj/item/trash/candy,
			/obj/item/trash/cheesie,
			/obj/item/trash/chips,
			/obj/item/trash/pistachios,
			/obj/item/trash/popcorn,
			/obj/item/trash/raisins,
			/obj/item/trash/sosjerky,
			/obj/item/trash/syndi_cakes,
		))

GLOBAL_LIST_INIT(ratking_coins, list(//Coins: Used by the regal rat mob when spawning coins.
			/obj/item/coin/iron,
			/obj/item/coin/plastic,
			/obj/item/coin/silver,
			/obj/item/coin/titanium,
		))
