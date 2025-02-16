/////////////////////////////////////////
/////////////////Weapons/////////////////
/////////////////////////////////////////

/datum/design/c38/sec
	id = "c38_sec"
	build_type = PROTOLATHE | AWAY_LATHE
	category = list(
		RND_CATEGORY_WEAPONS + RND_SUBCATEGORY_WEAPONS_AMMO
	)
	departmental_flags = DEPARTMENT_BITFLAG_SECURITY
	autolathe_exportable = FALSE //Redundant, there's already an autolathe version.

/datum/design/c38_trac
	name = "Speed Loader (.38 TRAC) (Less Lethal)"
	desc = "Designed to quickly reload revolvers. TRAC bullets embed a tracking implant within the target's body. The implant's signal is incompatible with teleporters."
	id = "c38_trac"
	build_type = PROTOLATHE | AWAY_LATHE
	materials = list(
		/datum/material/iron = HALF_SHEET_MATERIAL_AMOUNT * 10,
		/datum/material/silver = HALF_SHEET_MATERIAL_AMOUNT * 2.5,
		/datum/material/gold = HALF_SHEET_MATERIAL_AMOUNT,
	)
	build_path = /obj/item/ammo_box/c38/trac
	category = list(
		RND_CATEGORY_WEAPONS + RND_SUBCATEGORY_WEAPONS_AMMO
	)
	departmental_flags = DEPARTMENT_BITFLAG_SECURITY

/datum/design/c38_hotshot
	name = "Speed Loader (.38 Hot Shot) (Very Lethal)"
	desc = "Designed to quickly reload revolvers. Hot Shot bullets contain an incendiary payload."
	id = "c38_hotshot"
	build_type = PROTOLATHE | AWAY_LATHE
	materials = list(
		/datum/material/iron = HALF_SHEET_MATERIAL_AMOUNT * 10,
		/datum/material/plasma = HALF_SHEET_MATERIAL_AMOUNT * 2.5,
	)
	build_path = /obj/item/ammo_box/c38/hotshot
	category = list(
		RND_CATEGORY_WEAPONS + RND_SUBCATEGORY_WEAPONS_AMMO
	)
	departmental_flags = DEPARTMENT_BITFLAG_SECURITY

/datum/design/c38_iceblox
	name = "Speed Loader (.38 Iceblox) (Lethal/Very Lethal (Lizardpeople))"
	desc = "Designed to quickly reload revolvers. Iceblox bullets contain a cryogenic payload."
	id = "c38_iceblox"
	build_type = PROTOLATHE | AWAY_LATHE
	materials = list(
		/datum/material/iron = HALF_SHEET_MATERIAL_AMOUNT * 10,
		/datum/material/plasma = HALF_SHEET_MATERIAL_AMOUNT * 2.5,
	)
	build_path = /obj/item/ammo_box/c38/iceblox
	category = list(
		RND_CATEGORY_WEAPONS + RND_SUBCATEGORY_WEAPONS_AMMO
	)
	departmental_flags = DEPARTMENT_BITFLAG_SECURITY

/datum/design/c38_rubber
	name = "Speed Loader (.38 Rubber) (Less Lethal)"
	desc = "Designed to quickly reload revolvers. Rubber bullets are bouncy and less-than-lethal."
	id = "c38_rubber"
	build_type = PROTOLATHE | AWAY_LATHE
	materials = list(/datum/material/iron = HALF_SHEET_MATERIAL_AMOUNT * 10)
	build_path = /obj/item/ammo_box/c38/match/bouncy
	category = list(
		RND_CATEGORY_WEAPONS + RND_SUBCATEGORY_WEAPONS_AMMO
	)
	departmental_flags = DEPARTMENT_BITFLAG_SECURITY

/datum/design/c38_true
	name = "Speedloader (.38 True Strike) (Lethal)"
	desc = "Designed to quickly reload revolvers. Bullets bounce towards new targets with surprising accuracy."
	id = "c38_true_strike"
	build_type = PROTOLATHE | AWAY_LATHE
	materials = list(
		/datum/material/iron = HALF_SHEET_MATERIAL_AMOUNT * 10,
		/datum/material/bluespace = HALF_SHEET_MATERIAL_AMOUNT,
	)
	build_path = /obj/item/ammo_box/magazine/m38/true
	category = list(
		RND_CATEGORY_WEAPONS + RND_SUBCATEGORY_WEAPONS_AMMO
	)
	departmental_flags = DEPARTMENT_BITFLAG_SECURITY

/datum/design/c38_mag
	name = "Magazine (.38) (Lethal)"
	desc = "Designed to tactically reload a NT BR-38 Battle Rifle. Less powerful by design, guns chambered in .38 caliber rounds are still quite popular for use by police forces, \
		private security firms and organizations unable to access energy-based nonlethal weaponry. The lower (relative) penetrative power is useful for preventing potential hull damage \
		aboard space stations and shuttles."
	id = "c38_mag"
	build_type = PROTOLATHE | AWAY_LATHE
	materials = list(
		/datum/material/iron = HALF_SHEET_MATERIAL_AMOUNT * 30,
		/datum/material/plastic = HALF_SHEET_MATERIAL_AMOUNT * 3,
	)
	build_path = /obj/item/ammo_box/magazine/m38
	category = list(
		RND_CATEGORY_WEAPONS + RND_SUBCATEGORY_WEAPONS_AMMO
	)
	departmental_flags = DEPARTMENT_BITFLAG_SECURITY

/datum/design/c38_trac_mag
	name = "Magazine (.38 TRAC) (Less Lethal)"
	desc = "Designed to tactically reload a NT BR-38 Battle Rifle. TRAC bullets embed a tracking implant within the target's body. The implant's signal is incompatible with teleporters."
	id = "c38_trac_mag"
	build_type = PROTOLATHE | AWAY_LATHE
	materials = list(
		/datum/material/iron = HALF_SHEET_MATERIAL_AMOUNT * 30,
		/datum/material/silver = HALF_SHEET_MATERIAL_AMOUNT * 2.5,
		/datum/material/gold = HALF_SHEET_MATERIAL_AMOUNT,
		/datum/material/plastic = HALF_SHEET_MATERIAL_AMOUNT * 3,
	)
	build_path = /obj/item/ammo_box/magazine/m38/trac
	category = list(
		RND_CATEGORY_WEAPONS + RND_SUBCATEGORY_WEAPONS_AMMO
	)
	departmental_flags = DEPARTMENT_BITFLAG_SECURITY

/datum/design/c38_hotshot_mag
	name = "Magazine (.38 Hot Shot) (Very Lethal)"
	desc = "Designed to tactically reload a NT BR-38 Battle Rifle. Hot Shot bullets contain an incendiary payload."
	id = "c38_hotshot_mag"
	build_type = PROTOLATHE | AWAY_LATHE
	materials = list(
		/datum/material/iron = HALF_SHEET_MATERIAL_AMOUNT * 30,
		/datum/material/plasma = HALF_SHEET_MATERIAL_AMOUNT * 2.5,
		/datum/material/plastic = HALF_SHEET_MATERIAL_AMOUNT * 3,
	)
	build_path = /obj/item/ammo_box/magazine/m38/hotshot
	category = list(
		RND_CATEGORY_WEAPONS + RND_SUBCATEGORY_WEAPONS_AMMO
	)
	departmental_flags = DEPARTMENT_BITFLAG_SECURITY

/datum/design/c38_iceblox_mag
	name = "Magazine (.38 Iceblox) (Lethal/Very Lethal (Lizardpeople))"
	desc = "Designed to tactically reload a NT BR-38 Battle Rifle. Iceblox bullets contain a cryogenic payload."
	id = "c38_iceblox_mag"
	build_type = PROTOLATHE | AWAY_LATHE
	materials = list(
		/datum/material/iron = HALF_SHEET_MATERIAL_AMOUNT * 30,
		/datum/material/plasma = HALF_SHEET_MATERIAL_AMOUNT * 2.5,
		/datum/material/plastic = HALF_SHEET_MATERIAL_AMOUNT * 3,
	)
	build_path = /obj/item/ammo_box/magazine/m38/iceblox
	category = list(
		RND_CATEGORY_WEAPONS + RND_SUBCATEGORY_WEAPONS_AMMO
	)
	departmental_flags = DEPARTMENT_BITFLAG_SECURITY

/datum/design/c38_rubber_mag
	name = "Magazine (.38 Rubber) (Less Lethal)"
	desc = "Designed to tactically reload a NT BR-38 Battle Rifle. Rubber bullets are bouncy and less-than-lethal."
	id = "c38_rubber_mag"
	build_type = PROTOLATHE | AWAY_LATHE
	materials = list(
		/datum/material/iron = HALF_SHEET_MATERIAL_AMOUNT * 30,
		/datum/material/plastic = HALF_SHEET_MATERIAL_AMOUNT * 3,
	)
	build_path = /obj/item/ammo_box/magazine/m38/match/bouncy
	category = list(
		RND_CATEGORY_WEAPONS + RND_SUBCATEGORY_WEAPONS_AMMO
	)
	departmental_flags = DEPARTMENT_BITFLAG_SECURITY

/datum/design/c38_true_mag
	name = "Magazine (.38 Truee Strike) (Lethal)"
	desc = "Designed to tactically reload a NT BR-38 Battle Rifle. Bullets bounce towards new targets with surprising accuracy."
	id = "c38_true_strike_mag"
	build_type = PROTOLATHE | AWAY_LATHE
	materials = list(
		/datum/material/iron = HALF_SHEET_MATERIAL_AMOUNT * 30,
		/datum/material/plastic = HALF_SHEET_MATERIAL_AMOUNT * 3,
		/datum/material/bluespace = HALF_SHEET_MATERIAL_AMOUNT,
	)
	build_path = /obj/item/ammo_box/magazine/m38/true
	category = list(
		RND_CATEGORY_WEAPONS + RND_SUBCATEGORY_WEAPONS_AMMO
	)
	departmental_flags = DEPARTMENT_BITFLAG_SECURITY

/datum/design/rubbershot/sec
	id = "sec_rshot"
	desc = "Rubbershot shotgun shells. Fires a cloud of pellets. Rubber bullets are bouncy and less-than-lethal."
	build_type = PROTOLATHE | AWAY_LATHE
	category = list(
		RND_CATEGORY_WEAPONS + RND_SUBCATEGORY_WEAPONS_AMMO
	)
	departmental_flags = DEPARTMENT_BITFLAG_SECURITY
	autolathe_exportable = FALSE //Redundant

/datum/design/beanbag_slug/sec
	id = "sec_beanbag_slug"
	desc = "Beanbag slug shotgun shells. Fires a single slug (a beanbag). Less-than-lethal."
	build_type = PROTOLATHE | AWAY_LATHE
	category = list(
		RND_CATEGORY_WEAPONS + RND_SUBCATEGORY_WEAPONS_AMMO
	)
	departmental_flags = DEPARTMENT_BITFLAG_SECURITY
	autolathe_exportable = FALSE

/datum/design/shotgun_dart/sec
	id = "sec_dart"
	desc = "Dart shotgun shells. Fires a single projectile (a dart). Can be filled with chemicals, \
		which it injects upon striking a target. Otherwise, very weak."
	build_type = PROTOLATHE | AWAY_LATHE
	category = list(
		RND_CATEGORY_WEAPONS + RND_SUBCATEGORY_WEAPONS_AMMO
	)
	departmental_flags = DEPARTMENT_BITFLAG_SECURITY
	autolathe_exportable = FALSE

/datum/design/incendiary_slug/sec
	id = "sec_Islug"
	desc = "Dart shotgun shells. Fires a single slug. Ignites a target upon hit, \
		and leaves a trail of fire as it flies through the air. Very user unfriendly, but effective."
	build_type = PROTOLATHE | AWAY_LATHE
	category = list(
		RND_CATEGORY_WEAPONS + RND_SUBCATEGORY_WEAPONS_AMMO
	)
	departmental_flags = DEPARTMENT_BITFLAG_SECURITY
	autolathe_exportable = FALSE

/datum/design/mag_autorifle
	name = "WT-550 Autorifle Magazine (4.6x30mm) (Lethal)"
	desc = "A 20 round magazine for the out of date WT-550 Autorifle."
	id = "mag_autorifle"
	build_type = PROTOLATHE | AWAY_LATHE
	materials = list(/datum/material/iron = SHEET_MATERIAL_AMOUNT * 2)
	build_path = /obj/item/ammo_box/magazine/wt550m9
	category = list(
		RND_CATEGORY_WEAPONS + RND_SUBCATEGORY_WEAPONS_AMMO
	)
	departmental_flags = DEPARTMENT_BITFLAG_SECURITY

/datum/design/mag_autorifle/ap_mag
	name = "WT-550 Autorifle Armour Piercing Magazine (4.6x30mm AP) (Lethal)"
	desc = "A 20 round armour piercing magazine for the out of date WT-550 Autorifle."
	id = "mag_autorifle_ap"
	materials = list(/datum/material/iron = SHEET_MATERIAL_AMOUNT * 3, /datum/material/silver = SMALL_MATERIAL_AMOUNT * 6)
	build_path = /obj/item/ammo_box/magazine/wt550m9/wtap
	departmental_flags = DEPARTMENT_BITFLAG_SECURITY

/datum/design/mag_autorifle/ic_mag
	name = "WT-550 Autorifle Incendiary Magazine (4.6x30mm IC) (Lethal/Highly Destructive)"
	desc = "A 20 round armour piercing magazine for the out of date WT-550 Autorifle."
	id = "mag_autorifle_ic"
	materials = list(/datum/material/iron = SHEET_MATERIAL_AMOUNT * 3, /datum/material/silver = SMALL_MATERIAL_AMOUNT * 6, /datum/material/glass =HALF_SHEET_MATERIAL_AMOUNT)
	build_path = /obj/item/ammo_box/magazine/wt550m9/wtic
	departmental_flags = DEPARTMENT_BITFLAG_SECURITY

/datum/design/pin_testing
	name = "Test-Range Firing Pin"
	desc = "This safety firing pin allows firearms to be operated within proximity to a firing range."
	id = "pin_testing"
	build_type = PROTOLATHE | AWAY_LATHE
	materials = list(/datum/material/iron =SMALL_MATERIAL_AMOUNT*5, /datum/material/glass =SMALL_MATERIAL_AMOUNT * 3)
	build_path = /obj/item/firing_pin/test_range
	category = list(
		RND_CATEGORY_WEAPONS + RND_SUBCATEGORY_WEAPONS_FIRING_PINS
	)
	departmental_flags = DEPARTMENT_BITFLAG_SECURITY

/datum/design/pin_mindshield
	name = "Mindshield Firing Pin"
	desc = "This is a security firing pin which only authorizes users who are mindshield-implanted."
	id = "pin_loyalty"
	build_type = PROTOLATHE | AWAY_LATHE
	materials = list(/datum/material/silver = SMALL_MATERIAL_AMOUNT * 6, /datum/material/diamond = SMALL_MATERIAL_AMOUNT * 6, /datum/material/uranium =SMALL_MATERIAL_AMOUNT * 2)
	build_path = /obj/item/firing_pin/implant/mindshield
	category = list(
		RND_CATEGORY_WEAPONS + RND_SUBCATEGORY_WEAPONS_FIRING_PINS
	)
	departmental_flags = DEPARTMENT_BITFLAG_SECURITY

/datum/design/pin_explorer
	name = "Outback Firing Pin"
	desc = "This firing pin only shoots while ya ain't on station, fair dinkum!"
	id = "pin_explorer"
	build_type = PROTOLATHE | AWAY_LATHE
	materials = list(/datum/material/silver =HALF_SHEET_MATERIAL_AMOUNT, /datum/material/gold =HALF_SHEET_MATERIAL_AMOUNT, /datum/material/iron =SMALL_MATERIAL_AMOUNT*5)
	build_path = /obj/item/firing_pin/explorer
	category = list(
		RND_CATEGORY_WEAPONS + RND_SUBCATEGORY_WEAPONS_FIRING_PINS
	)
	departmental_flags = DEPARTMENT_BITFLAG_SECURITY

/datum/design/stunrevolver
	name = "Tesla Cannon Part Kit (Lethal)"
	desc = "The kit for a high-tech cannon that fires internal, reusable bolt cartridges in a revolving cylinder. The cartridges can be recharged using conventional rechargers."
	id = "stunrevolver"
	build_type = PROTOLATHE | AWAY_LATHE
	materials = list(/datum/material/iron = SHEET_MATERIAL_AMOUNT * 5, /datum/material/glass = SHEET_MATERIAL_AMOUNT * 5, /datum/material/silver = SHEET_MATERIAL_AMOUNT * 5)
	build_path = /obj/item/weaponcrafting/gunkit/tesla
	category = list(
		RND_CATEGORY_WEAPONS + RND_SUBCATEGORY_WEAPONS_KITS
	)
	departmental_flags = DEPARTMENT_BITFLAG_SECURITY
	autolathe_exportable = FALSE

/datum/design/nuclear_gun
	name = "Advanced Energy Gun Part Kit (Lethal/Nonlethal)"
	desc = "The kit for an energy gun with an experimental miniaturized reactor."
	id = "nuclear_gun"
	build_type = PROTOLATHE | AWAY_LATHE
	materials = list(/datum/material/iron = SHEET_MATERIAL_AMOUNT * 5, /datum/material/glass =SHEET_MATERIAL_AMOUNT, /datum/material/uranium =SHEET_MATERIAL_AMOUNT * 1.5, /datum/material/titanium =HALF_SHEET_MATERIAL_AMOUNT)
	build_path = /obj/item/weaponcrafting/gunkit/nuclear
	category = list(
		RND_CATEGORY_WEAPONS + RND_SUBCATEGORY_WEAPONS_KITS
	)
	departmental_flags = DEPARTMENT_BITFLAG_SECURITY
	autolathe_exportable = FALSE

/datum/design/tele_shield
	name = "Telescopic Riot Shield"
	desc = "An advanced riot shield made of lightweight materials that collapses for easy storage."
	id = "tele_shield"
	build_type = PROTOLATHE | AWAY_LATHE
	materials = list(/datum/material/iron = SHEET_MATERIAL_AMOUNT * 2, /datum/material/glass = SHEET_MATERIAL_AMOUNT * 2, /datum/material/silver =SMALL_MATERIAL_AMOUNT * 3, /datum/material/titanium =SMALL_MATERIAL_AMOUNT * 2)
	build_path = /obj/item/shield/riot/tele
	category = list(
		RND_CATEGORY_WEAPONS + RND_SUBCATEGORY_WEAPONS_MELEE
	)
	departmental_flags = DEPARTMENT_BITFLAG_SECURITY
	autolathe_exportable = FALSE

/datum/design/ballistic_shield
	name = "Ballistic Shield"
	desc = "A heavy shield designed for blocking projectiles, weaker to melee."
	id = "ballistic_shield"
	build_type = PROTOLATHE | AWAY_LATHE
	materials = list(/datum/material/iron = SHEET_MATERIAL_AMOUNT * 2, /datum/material/glass = SHEET_MATERIAL_AMOUNT * 2, /datum/material/titanium =SHEET_MATERIAL_AMOUNT)
	build_path = /obj/item/shield/ballistic
	category = list(
		RND_CATEGORY_WEAPONS + RND_SUBCATEGORY_WEAPONS_MELEE
	)
	departmental_flags = DEPARTMENT_BITFLAG_SECURITY
	autolathe_exportable = FALSE

/datum/design/beamrifle
	name = "Event Horizon Anti-Existential Beam Rifle Part Kit (DOOMSDAY DEVICE)"
	desc = "The kit that produces a weapon made to end your foes on an existential level. Why the fuck can you make this?"
	id = "beamrifle"
	build_type = PROTOLATHE | AWAY_LATHE
	materials = list(/datum/material/iron = SHEET_MATERIAL_AMOUNT * 5, /datum/material/glass =SHEET_MATERIAL_AMOUNT * 2.5, /datum/material/diamond =SHEET_MATERIAL_AMOUNT * 2.5, /datum/material/uranium = SHEET_MATERIAL_AMOUNT * 4, /datum/material/silver = SHEET_MATERIAL_AMOUNT * 2.25, /datum/material/gold =SHEET_MATERIAL_AMOUNT * 2.5)
	build_path = /obj/item/weaponcrafting/gunkit/beam_rifle
	category = list(
		RND_CATEGORY_WEAPONS + RND_SUBCATEGORY_WEAPONS_KITS
	)
	departmental_flags = DEPARTMENT_BITFLAG_SECURITY
	autolathe_exportable = FALSE

/datum/design/rapidsyringe
	name = "Rapid Syringe Gun"
	desc = "A gun that fires many syringes."
	id = "rapidsyringe"
	build_type = PROTOLATHE | AWAY_LATHE
	materials = list(/datum/material/iron =SHEET_MATERIAL_AMOUNT * 2.5, /datum/material/glass =HALF_SHEET_MATERIAL_AMOUNT)
	build_path = /obj/item/gun/syringe/rapidsyringe
	category = list(
		RND_CATEGORY_EQUIPMENT + RND_SUBCATEGORY_EQUIPMENT_CHEMISTRY
	)
	departmental_flags = DEPARTMENT_BITFLAG_MEDICAL //uwu

/datum/design/temp_gun
	name = "Temperature Gun Part Kit (Less Lethal/Very Lethal (Lizardpeople))"
	desc = "A gun that shoots temperature bullet energythings to change temperature."//Change it if you want
	id = "temp_gun"
	build_type = PROTOLATHE | AWAY_LATHE
	materials = list(/datum/material/iron =SHEET_MATERIAL_AMOUNT * 2.5, /datum/material/glass =SMALL_MATERIAL_AMOUNT*5, /datum/material/silver = SHEET_MATERIAL_AMOUNT * 1.5)
	build_path = /obj/item/weaponcrafting/gunkit/temperature
	category = list(
		RND_CATEGORY_WEAPONS + RND_SUBCATEGORY_WEAPONS_KITS
	)
	departmental_flags = DEPARTMENT_BITFLAG_SECURITY
	autolathe_exportable = FALSE

/datum/design/flora_gun
	name = "Floral Somatoray"
	desc = "A tool that discharges controlled radiation which induces mutation in plant cells. Harmless to other organic life."
	id = "flora_gun"
	build_type = PROTOLATHE | AWAY_LATHE
	materials = list(/datum/material/iron =SHEET_MATERIAL_AMOUNT, /datum/material/glass =SMALL_MATERIAL_AMOUNT*5, /datum/material/uranium =SHEET_MATERIAL_AMOUNT)
	build_path = /obj/item/gun/energy/floragun
	category = list(
		RND_CATEGORY_TOOLS + RND_SUBCATEGORY_TOOLS_BOTANY_ADVANCED
	)
	departmental_flags = DEPARTMENT_BITFLAG_SERVICE

/datum/design/large_grenade
	name = "Large Grenade Casing"
	desc = "A grenade that affects a larger area and use larger containers."
	id = "large_grenade"
	build_type = PROTOLATHE | AWAY_LATHE
	materials = list(/datum/material/iron = SHEET_MATERIAL_AMOUNT * 1.5)
	build_path = /obj/item/grenade/chem_grenade/large
	category = list(
		RND_CATEGORY_EQUIPMENT + RND_SUBCATEGORY_EQUIPMENT_CHEMISTRY
	)
	departmental_flags = DEPARTMENT_BITFLAG_MEDICAL

/datum/design/pyro_grenade
	name = "Pyro Grenade Casing"
	desc = "An advanced grenade that is able to self ignite its mixture."
	id = "pyro_grenade"
	build_type = PROTOLATHE | AWAY_LATHE
	materials = list(/datum/material/iron = SHEET_MATERIAL_AMOUNT, /datum/material/plasma =SMALL_MATERIAL_AMOUNT * 5)
	build_path = /obj/item/grenade/chem_grenade/pyro
	category = list(
		RND_CATEGORY_EQUIPMENT + RND_SUBCATEGORY_EQUIPMENT_CHEMISTRY
	)
	departmental_flags = DEPARTMENT_BITFLAG_MEDICAL

/datum/design/cryo_grenade
	name = "Cryo Grenade Casing"
	desc = "An advanced grenade that rapidly cools its contents upon detonation."
	id = "cryo_grenade"
	build_type = PROTOLATHE | AWAY_LATHE
	materials = list(/datum/material/iron = SHEET_MATERIAL_AMOUNT, /datum/material/silver = SMALL_MATERIAL_AMOUNT * 5)
	build_path = /obj/item/grenade/chem_grenade/cryo
	category = list(
		RND_CATEGORY_EQUIPMENT + RND_SUBCATEGORY_EQUIPMENT_CHEMISTRY
	)
	departmental_flags = DEPARTMENT_BITFLAG_MEDICAL

/datum/design/adv_grenade
	name = "Advanced Release Grenade Casing"
	desc = "An advanced grenade that can be detonated several times, best used with a repeating igniter."
	id = "adv_grenade"
	build_type = PROTOLATHE | AWAY_LATHE
	materials = list(/datum/material/iron = SHEET_MATERIAL_AMOUNT * 1.5, /datum/material/glass = SMALL_MATERIAL_AMOUNT * 5)
	build_path = /obj/item/grenade/chem_grenade/adv_release
	category = list(
		RND_CATEGORY_EQUIPMENT + RND_SUBCATEGORY_EQUIPMENT_CHEMISTRY
	)
	departmental_flags = DEPARTMENT_BITFLAG_MEDICAL

/datum/design/xray
	name = "X-ray Laser Gun Part Kit (Lethal)"
	desc = "Not quite as menacing as it sounds"
	id = "xray_laser"
	build_type = PROTOLATHE | AWAY_LATHE
	materials = list(/datum/material/gold =SHEET_MATERIAL_AMOUNT * 2.5, /datum/material/uranium = SHEET_MATERIAL_AMOUNT * 2, /datum/material/iron =SHEET_MATERIAL_AMOUNT * 2.5, /datum/material/titanium =SHEET_MATERIAL_AMOUNT, /datum/material/bluespace =SHEET_MATERIAL_AMOUNT)
	build_path = /obj/item/weaponcrafting/gunkit/xray
	category = list(
		RND_CATEGORY_WEAPONS + RND_SUBCATEGORY_WEAPONS_KITS
	)
	departmental_flags = DEPARTMENT_BITFLAG_SECURITY
	autolathe_exportable = FALSE

/datum/design/ioncarbine
	name = "Ion Carbine Part Kit (Nonlethal/Highly Destructive/Lethal (Silicons))"
	desc = "How to Dismantle a Cyborg: The Gun."
	id = "ioncarbine"
	build_type = PROTOLATHE | AWAY_LATHE
	materials = list(/datum/material/silver = SHEET_MATERIAL_AMOUNT * 3, /datum/material/iron = SHEET_MATERIAL_AMOUNT * 4, /datum/material/uranium =SHEET_MATERIAL_AMOUNT)
	build_path = /obj/item/weaponcrafting/gunkit/ion
	category = list(
		RND_CATEGORY_WEAPONS + RND_SUBCATEGORY_WEAPONS_KITS
	)
	departmental_flags = DEPARTMENT_BITFLAG_SECURITY
	autolathe_exportable = FALSE

/datum/design/wormhole_projector
	name = "Bluespace Wormhole Projector"
	desc = "A projector that emits high density quantum-coupled bluespace beams. Requires a bluespace anomaly core to function."
	id = "wormholeprojector"
	build_type = PROTOLATHE
	materials = list(/datum/material/silver =SHEET_MATERIAL_AMOUNT, /datum/material/iron =SHEET_MATERIAL_AMOUNT * 2.5, /datum/material/diamond =SHEET_MATERIAL_AMOUNT, /datum/material/bluespace =SHEET_MATERIAL_AMOUNT * 1.5)
	build_path = /obj/item/gun/energy/wormhole_projector
	category = list(
		RND_CATEGORY_EQUIPMENT + RND_SUBCATEGORY_EQUIPMENT_SCIENCE
	)
	departmental_flags = DEPARTMENT_BITFLAG_SCIENCE

/datum/design/stunshell
	name = "Stun Shell"
	desc = "A stunning shell for a shotgun."
	id = "stunshell"
	build_type = PROTOLATHE | AWAY_LATHE
	materials = list(/datum/material/iron =SMALL_MATERIAL_AMOUNT * 2)
	build_path = /obj/item/ammo_casing/shotgun/stunslug
	category = list(
		RND_CATEGORY_WEAPONS + RND_SUBCATEGORY_WEAPONS_AMMO
	)
	departmental_flags = DEPARTMENT_BITFLAG_SECURITY

/datum/design/lasershell
	name = "Scatter Laser Shotgun Shell (Lethal)"
	desc = "A high-tech shotgun shell which houses an internal capacitor and laser focusing crystal inside of a shell casing. \
		Able to be fired from conventional ballistic shotguns with minimal rifling degradation. Also leaves most targets covered \
		in grotesque burns."
	id = "lasershell"
	build_type = PROTOLATHE | AWAY_LATHE
	materials = list(/datum/material/iron = HALF_SHEET_MATERIAL_AMOUNT, /datum/material/glass = SMALL_MATERIAL_AMOUNT * 2, /datum/material/gold = HALF_SHEET_MATERIAL_AMOUNT)
	build_path = /obj/item/ammo_casing/shotgun/scatterlaser
	category = list(
		RND_CATEGORY_WEAPONS + RND_SUBCATEGORY_WEAPONS_AMMO
	)
	departmental_flags = DEPARTMENT_BITFLAG_SECURITY

/datum/design/techshell
	name = "Unloaded Technological Shotshell"
	desc = "A high-tech shotgun shell which can be crafted into more advanced shells to produce unique effects. \
		Does nothing on its own."
	id = "techshotshell"
	build_type = PROTOLATHE | AWAY_LATHE
	materials = list(/datum/material/iron =HALF_SHEET_MATERIAL_AMOUNT, /datum/material/glass =SMALL_MATERIAL_AMOUNT * 2)
	build_path = /obj/item/ammo_casing/shotgun/techshell
	category = list(
		RND_CATEGORY_WEAPONS + RND_SUBCATEGORY_WEAPONS_AMMO
	)
	departmental_flags = DEPARTMENT_BITFLAG_SECURITY

/datum/design/suppressor
	name = "Suppressor"
	desc = "A reverse-engineered suppressor that fits on most small arms with threaded barrels."
	id = "suppressor"
	build_type = PROTOLATHE | AWAY_LATHE
	materials = list(/datum/material/iron =SHEET_MATERIAL_AMOUNT, /datum/material/silver =SMALL_MATERIAL_AMOUNT*5)
	build_path = /obj/item/suppressor
	category = list(
		RND_CATEGORY_WEAPONS + RND_SUBCATEGORY_WEAPONS_PARTS
	)
	departmental_flags = DEPARTMENT_BITFLAG_SECURITY

/datum/design/gravitygun
	name = "One-point Gravitational Manipulator"
	desc = "A multi-mode device that blasts one-point bluespace-gravitational bolts that locally distort gravity. Requires a gravitational anomaly core to function."
	id = "gravitygun"
	build_type = PROTOLATHE | AWAY_LATHE
	materials = list(/datum/material/silver = SHEET_MATERIAL_AMOUNT * 4, /datum/material/uranium = SHEET_MATERIAL_AMOUNT * 4, /datum/material/glass = SHEET_MATERIAL_AMOUNT * 6, /datum/material/iron = SHEET_MATERIAL_AMOUNT * 6, /datum/material/diamond =SHEET_MATERIAL_AMOUNT * 1.5, /datum/material/bluespace =SHEET_MATERIAL_AMOUNT * 1.5)
	build_path = /obj/item/gun/energy/gravity_gun
	category = list(
		RND_CATEGORY_EQUIPMENT + RND_SUBCATEGORY_EQUIPMENT_SCIENCE
	)
	departmental_flags = DEPARTMENT_BITFLAG_SCIENCE

/datum/design/largecrossbow
	name = "Energy Crossbow Part Kit (Less Lethal/Contraband)"
	desc = "A kit to reverse-engineer a proto-kinetic accelerator into an energy crossbow, favored by syndicate infiltration teams and carp hunters."
	id = "largecrossbow"
	build_type = PROTOLATHE | AWAY_LATHE
	materials = list(/datum/material/iron =SHEET_MATERIAL_AMOUNT * 2.5, /datum/material/glass =HALF_SHEET_MATERIAL_AMOUNT * 1.5, /datum/material/uranium =HALF_SHEET_MATERIAL_AMOUNT * 1.5, /datum/material/silver =HALF_SHEET_MATERIAL_AMOUNT * 1.5)
	build_path = /obj/item/weaponcrafting/gunkit/ebow
	category = list(
		RND_CATEGORY_WEAPONS + RND_SUBCATEGORY_WEAPONS_KITS
	)
	departmental_flags = DEPARTMENT_BITFLAG_SECURITY
	autolathe_exportable = FALSE

/datum/design/cleric_mace
	name = "Cleric Mace"
	desc = "A mace fit for a cleric. Useful for bypassing plate armor, but too bulky for much else."
	id = "cleric_mace"
	build_type = AUTOLATHE
	materials = list(MAT_CATEGORY_ITEM_MATERIAL = SHEET_MATERIAL_AMOUNT * 4.5, MAT_CATEGORY_ITEM_MATERIAL_COMPLEMENTARY = SHEET_MATERIAL_AMOUNT * 1.5)
	build_path = /obj/item/melee/cleric_mace
	category = list(RND_CATEGORY_IMPORTED)

/datum/design/liberator_gun
	name = "The Liberator"
	desc = "A dirt cheap 3D printed gun. Only holds one bullet, and is infamous for sometimes exploding on it's user."
	id = "liberator_gun"
	build_type = AUTOLATHE
	materials = list(/datum/material/plastic = SHEET_MATERIAL_AMOUNT * 2, /datum/material/iron = SMALL_MATERIAL_AMOUNT * 15)
	build_path = /obj/item/gun/ballistic/automatic/pistol/doorhickey
	category = list(RND_CATEGORY_IMPORTED)

/datum/design/stun_boomerang
	name = "OZtek Boomerang"
	desc = "Uses reverse flow gravitodynamics to flip its personal gravity back to the thrower mid-flight. Also functions similar to a stun baton."
	id = "stun_boomerang"
	build_type = PROTOLATHE | AWAY_LATHE
	materials = list(/datum/material/iron = SHEET_MATERIAL_AMOUNT * 5, /datum/material/glass = SHEET_MATERIAL_AMOUNT * 2, /datum/material/silver = SHEET_MATERIAL_AMOUNT * 5, /datum/material/gold =SHEET_MATERIAL_AMOUNT)
	build_path = /obj/item/melee/baton/security/boomerang
	category = list(
		RND_CATEGORY_WEAPONS + RND_SUBCATEGORY_WEAPONS_RANGED
	)
	departmental_flags = DEPARTMENT_BITFLAG_SECURITY

/datum/design/photon_cannon
	name = "Photon Cannon Part Kit (Nonlethal)"
	desc = "A kit to reverse-engineer a photon cannon, a weapon that generates a shortly-lived miniature sun. Technically brightens up the room, effectively blinds everyone in it. Requires a flux anomaly core to finish."
	id = "photon_cannon"
	build_type = PROTOLATHE | AWAY_LATHE
	materials = list(/datum/material/iron = SHEET_MATERIAL_AMOUNT * 3, /datum/material/glass = SHEET_MATERIAL_AMOUNT * 7, /datum/material/gold = SHEET_MATERIAL_AMOUNT * 5)
	build_path = /obj/item/weaponcrafting/gunkit/photon
	category = list(
		RND_CATEGORY_WEAPONS + RND_SUBCATEGORY_WEAPONS_KITS
	)
	departmental_flags = DEPARTMENT_BITFLAG_SECURITY
