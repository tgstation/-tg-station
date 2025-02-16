// File ordered by progression

/datum/uplink_category/suits
	name = "Space Suits"
	weight = 3

/datum/uplink_item/suits
	category = /datum/uplink_category/suits
	surplus = 40

/datum/uplink_item/suits/infiltrator_bundle
	name = "Infiltrator MODsuit"
	desc = "Developed by the Roseus Galactic Actors Guild in conjunction with the Gorlex Marauders to produce a functional suit for urban operations, \
			this suit proves to be cheaper than your standard issue MODsuit, with none of the movement restrictions of the space suits employed by the company. \
			However, this greater mobility comes at a cost, and the suit is ineffective at protecting the wearer from the vacuum of space. \
			The suit does come pre-equipped with a special psi-emitter stealth module that makes it impossible to recognize the wearer \
			as well as causing significant demoralization amongst Nanotrasen crew."
	item = /obj/item/mod/control/pre_equipped/infiltrator
	cost = 6
	purchasable_from = ~UPLINK_ALL_SYNDIE_OPS

/datum/uplink_item/suits/space_suit
	name = "Syndicate Space Suit"
	desc = "This red and black Syndicate space suit is less encumbering than Nanotrasen variants, \
			fits inside bags, and has a weapon slot. Nanotrasen crew members are trained to report red space suit \
			sightings, however."
	item = /obj/item/storage/box/syndie_kit/space
	cost = 4

/datum/uplink_item/suits/modsuit
	name = "Syndicate MODsuit"
	desc = "The feared MODsuit of a Syndicate agent. Features armoring and a set of inbuilt modules."
	item = /obj/item/mod/control/pre_equipped/traitor
	cost = 8
	purchasable_from = ~UPLINK_ALL_SYNDIE_OPS //you can't buy it in nuke, because the elite modsuit costs the same while being better

/datum/uplink_item/suits/thermal
	name = "MODsuit Thermal Visor Module"
	desc = "A visor for a MODsuit. Lets you see living beings through walls."
	item = /obj/item/mod/module/visor/thermal
	cost = 3

/datum/uplink_item/suits/night
	name = "MODsuit Night Visor Module"
	desc = "A visor for a MODsuit. Lets you see clearer in the dark."
	item = /obj/item/mod/module/visor/night
	cost = 2

/datum/uplink_item/suits/chameleon
	name = "MODsuit Chameleon Module"
	desc = "A MODsuit module that lets the suit disguise itself as other objects."
	item = /obj/item/mod/module/chameleon
	cost = 2

/datum/uplink_item/suits/plate_compression
	name = "MODsuit Plate Compression Module"
	desc = "A MODsuit module that lets the suit compress into a smaller size. Not compatible with storage modules or the Infiltrator MODsuit."
	item = /obj/item/mod/module/plate_compression
	cost = 2

/datum/uplink_item/suits/noslip
	name = "MODsuit Anti-Slip Module"
	desc = "A MODsuit module preventing the user from slipping on water."
	item = /obj/item/mod/module/noslip
	cost = 2

/datum/uplink_item/suits/shock_absorber
	name = "MODsuit Shock-Absorber Module"
	desc = "A MODsuit module preventing the user from getting knocked down by batons."
	item = /obj/item/mod/module/shock_absorber
	cost = 2

/datum/uplink_item/suits/modsuit/wraith
	name = "MODsuit wraith cloaking module"
	desc = "A MODsuit module that grants to the user Optical camouflage and the ability to overload light sources to recharge suit power. \
		Incompatible with armored MODsuits."
	item = /obj/item/mod/module/stealth/wraith
	cost = 3
