/obj/effect/spawner/random/armory
	name = "generic armory spawner"
	spawn_loot_split = TRUE
	spawn_loot_count = 3
	spawn_loot_split_pixel_offsets = 4

// Misc armory stuff
/obj/effect/spawner/random/armory/barrier_grenades
	name = "barrier grenade spawner"
	icon_state = "barrier_grenade"
	loot = list(/obj/item/grenade/barrier)

/obj/effect/spawner/random/armory/barrier_grenades/six
	name = "six barrier grenade spawner"
	spawn_loot_count = 6

/obj/effect/spawner/random/armory/riot_shield
	name = "riot shield spawner"
	icon_state = "riot_shield"
	loot = list(/obj/item/shield/riot)

/obj/effect/spawner/random/armory/rubbershot
	name = "rubbershot spawner"
	icon_state = "rubbershot"
	loot = list(/obj/item/storage/box/rubbershot)

/obj/effect/spawner/random/armory/buckshot
	name = "buckshot spawner"
	icon_state = "buckshot"
	loot = list(/obj/item/storage/box/lethalshot)

/obj/effect/spawner/random/armory/buckshot/sketchy
	name = "sketchy buckshot spawner"
	icon_state = "buckshot"
	loot = list(
		/obj/item/storage/box/lethalshot = 4,
		/obj/item/storage/box/lethalshot/old = 2,
	)

/obj/effect/spawner/random/armory/slug
	name = "slug shell spawner"
	icon_state = "buckshot"
	loot = list(/obj/item/storage/box/slugs)

/obj/effect/spawner/random/armory/strilka
	name = ".310 Strilka ammo box spawner"
	icon_state = "buckshot"
	spawn_loot_count = 1
	loot = list(
		/obj/item/storage/toolbox/ammobox/strilka310,
		/obj/item/storage/toolbox/ammobox/strilka310/surplus,
	)

// Weapons
/obj/effect/spawner/random/armory/disablers
	name = "disabler spawner"
	icon_state = "disabler"
	loot = list(/obj/item/gun/energy/disabler)

/obj/effect/spawner/random/armory/laser_gun
	name = "laser gun spawner"
	icon_state = "laser_gun"
	loot = list(/obj/item/gun/energy/laser)

/obj/effect/spawner/random/armory/e_gun
	name = "energy gun spawner"
	icon_state = "e_gun"
	loot = list(/obj/item/gun/energy/e_gun)

/obj/effect/spawner/random/armory/shotgun
	name = "shotgun spawner"
	icon_state = "shotgun"
	loot = list(/obj/item/gun/ballistic/shotgun/riot)

/obj/effect/spawner/random/armory/dragnet
	name = "DRAGnet spawner"
	icon_state = "dragnet"
	loot = list(/obj/item/gun/energy/e_gun/dragnet)
	spawn_loot_count = 2

/obj/effect/spawner/random/armory/dragnet/spawn_loot(lootcount_override)
	. = ..()
	new /obj/item/dragnet_beacon(get_turf(src)) //And give them a beacon too!

// Armor
/obj/effect/spawner/random/armory/bulletproof_helmet
	name = "bulletproof helmet spawner"
	icon_state = "armor_helmet"
	loot = list(/obj/item/clothing/head/helmet/alt)

/obj/effect/spawner/random/armory/riot_helmet
	name = "riot helmet spawner"
	icon_state = "riot_helmet"
	loot = list(/obj/item/clothing/head/helmet/toggleable/riot)

/obj/effect/spawner/random/armory/bulletproof_armor
	name = "bulletproof armor spawner"
	icon_state = "bulletproof_armor"
	loot = list(/obj/item/clothing/suit/armor/bulletproof)

/obj/effect/spawner/random/armory/riot_armor
	name = "riot armor spawner"
	icon_state = "riot_armor"
	loot = list(/obj/item/clothing/suit/armor/riot)
