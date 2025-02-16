/datum/market_item/weapon
	category = "Weapons"
	abstract_path = /datum/market_item/weapon

/datum/market_item/weapon/bear_trap
	name = "Bear Trap"
	desc = "Get the janitor back at his own game with this affordable prank kit."
	item = /obj/item/restraints/legcuffs/beartrap

	price_min = CARGO_CRATE_VALUE * 1.5
	price_max = CARGO_CRATE_VALUE * 2.75
	stock_max = 3
	availability_prob = 40

/datum/market_item/weapon/shotgun_dart
	name = "Box of XL Shotgun Darts"
	desc = "These handy darts can be filled up with any chemical and be shot with a shotgun! \
	Prank your friends by shooting them with laughter! \
	Not recommended for comercial use."
	item = /obj/item/storage/box/large_dart

	price_min = CARGO_CRATE_VALUE * 1.375
	price_max = CARGO_CRATE_VALUE * 2.875
	stock_max = 4
	availability_prob = 40

/datum/market_item/weapon/buckshot
	name = "Box of Buckshot Shells"
	desc = "It wasn't easy since buckshot is so heavily taxed nowadays, but we managed to find \
	a large cache of it... somewhere. A word of caution, the stuff may be a tad old."
	stock_max = 7
	availability_prob = 35
	item = /obj/effect/spawner/random/armory/buckshot/sketchy
	price_min = CARGO_CRATE_VALUE * 1
	price_max = CARGO_CRATE_VALUE * 3

/datum/market_item/weapon/bone_spear
	name = "Bone Spear"
	desc = "Authentic tribal spear, made from real bones! A steal at any price, especially if you're a caveman."
	item = /obj/item/spear/bonespear

	price_min = CARGO_CRATE_VALUE
	price_max = CARGO_CRATE_VALUE * 1.5
	stock_max = 3
	availability_prob = 60

/datum/market_item/weapon/chainsaw
	name = "Chainsaw"
	desc = "A lumberjack's best friend, perfect for cutting trees or limbs efficiently."
	item = /obj/item/chainsaw

	price_min = CARGO_CRATE_VALUE * 1.75
	price_max = CARGO_CRATE_VALUE * 3
	stock_max = 1
	availability_prob = 35

/datum/market_item/weapon/switchblade
	name = "Switchblade"
	desc = "Tunnel Snakes rule!"
	item = /obj/item/switchblade

	price_min = CARGO_CRATE_VALUE * 1.25
	price_max = CARGO_CRATE_VALUE * 1.75
	stock_max = 3
	availability_prob = 45

/datum/market_item/weapon/carpenter_hammer
	name = "Carpenter hammer"
	desc = "When you really want to look like a psycho..."
	item = /obj/item/carpenter_hammer

	price_min = CARGO_CRATE_VALUE * 1
	price_max = CARGO_CRATE_VALUE * 1.25
	stock_max = 2
	availability_prob = 65

/datum/market_item/weapon/emp_grenade
	name = "EMP Grenade"
	desc = "Use this grenade for SHOCKING results!"
	item = /obj/item/grenade/empgrenade

	price_min = CARGO_CRATE_VALUE * 0.5
	price_max = CARGO_CRATE_VALUE * 2
	stock_max = 2
	availability_prob = 50

/datum/market_item/weapon/fisher
	name = "SC/FISHER Saboteur Handgun"
	desc = "A self-recharging, compact pistol that disrupts lights, cameras, APCs, turrets and more, if only temporarily. Also usable in melee."
	item = /obj/item/gun/energy/recharge/fisher

	price_min = CARGO_CRATE_VALUE * 2
	price_max = CARGO_CRATE_VALUE * 4
	stock_max = 1
	availability_prob = 75

/datum/market_item/weapon/dimensional_bomb
	name = "Multi-Dimensional Bomb Core"
	desc = "A special bomb core, one of a kind, for all your 'terraforming gone wrong' purposes."
	item = /obj/item/bombcore/dimensional
	price_min = CARGO_CRATE_VALUE * 40
	price_max = CARGO_CRATE_VALUE * 50
	stock_max = 1
	availability_prob = 15

/datum/market_item/weapon/giant_wrench_parts
	name = "Big Slappy parts"
	desc = "Cheap illegal Big Slappy parts. The fastest and statistically most dangerous wrench."
	item = /obj/item/weaponcrafting/giant_wrench
	price_min = CARGO_CRATE_VALUE * 2
	price_max = CARGO_CRATE_VALUE * 5
	stock_max = 1
	availability_prob = 25

/datum/market_item/weapon/liberator
	name = "illegal 3D printer designs"
	desc = "Designs for a dirt cheap 3D printable gun, well known for exploding in unfortunate assistants' hands."
	item = /obj/item/disk/design_disk/liberator
	price_min = CARGO_CRATE_VALUE * 2
	price_max = CARGO_CRATE_VALUE * 5
	stock_max = 1
	availability_prob = 35
