//All bundles and telecrystals
/datum/uplink_category/dangerous
	name = "Conspicuous Weapons"
	weight = 9

/datum/uplink_item/dangerous
	category = /datum/uplink_category/dangerous

/datum/uplink_item/dangerous/foampistol
	name = "Donksoft Riot Pistol Case"
	desc = "A case containing an innocent-looking toy pistol designed to fire foam darts at higher than normal velocity. \
		Comes loaded with riot-grade darts effective at incapacitating a target, two spare magazines and a box of loose \
		riot darts. Perfect for nonlethal takedowns at range, as well as deniability. While not included in the kit, the \
		pistol is compatible with suppressors, which can be purchased separately."
	item = /obj/item/storage/toolbox/guncase/traitor/donksoft
	cost = 6
	surplus = 10
	purchasable_from = ~UPLINK_SERIOUS_OPS

/datum/uplink_item/dangerous/pistol
	name = "Makarov Pistol Case"
	desc = "A weapon case containing an unknown variant of the Makarov pistol, along with two spare magazines and a box of loose 9mm ammunition. \
		Chambered in 9mm. Perfect for frequent skirmishes with security, as well as ensuring you have enough firepower to outlast the competition. \
		While not included in the kit, the pistol is compatible with suppressors, which can be purchased separately."
	item = /obj/item/storage/toolbox/guncase/traitor
	cost = 7
	purchasable_from = ~UPLINK_ALL_SYNDIE_OPS

/datum/uplink_item/dangerous/throwingweapons
	name = "Box of Throwing Weapons"
	desc = "A box of shurikens and reinforced bolas from ancient Earth martial arts. They are highly effective \
			throwing weapons. The bolas can knock a target down and the shurikens will embed into limbs."
	item = /obj/item/storage/box/syndie_kit/throwing_weapons
	cost = 3
	uplink_item_flags = SYNDIE_TRIPS_CONTRABAND

/datum/uplink_item/dangerous/sword
	name = "Energy Sword"
	desc = "The energy sword is an edged weapon with a blade of pure energy. The sword is small enough to be \
			pocketed when inactive. Activating it produces a loud, distinctive noise."
	item = /obj/item/melee/energy/sword/saber
	cost = 6
	purchasable_from = ~UPLINK_CLOWN_OPS

/datum/uplink_item/dangerous/powerfist
	name = "Power Fist"
	desc = "The power-fist is a metal gauntlet with a built-in piston-ram powered by an external gas supply.\
			Upon hitting a target, the piston-ram will extend forward to make contact for some serious damage. \
			Using a wrench on the piston valve will allow you to tweak the amount of gas used per punch to \
			deal extra damage and hit targets further. Use a screwdriver to take out any attached tanks."
	item = /obj/item/melee/powerfist
	cost = 6
	purchasable_from = ~UPLINK_ALL_SYNDIE_OPS

/datum/uplink_item/dangerous/rapid
	name = "Gloves of the North Star"
	desc = "These gloves let the user punch people very fast. Does not improve weapon attack speed or the meaty fists of a hulk."
	item = /obj/item/clothing/gloves/rapid
	cost = 8

/datum/uplink_item/dangerous/doublesword
	name = "Double-Bladed Energy Sword"
	desc = "The double-bladed energy sword does slightly more damage than a standard energy sword and will deflect \
			energy projectiles it blocks, but requires two hands to wield. It also struggles to protect you from tackles."
	progression_minimum = 30 MINUTES
	item = /obj/item/dualsaber

	cost = 13
	purchasable_from = ~UPLINK_ALL_SYNDIE_OPS //nukies get their own version

/datum/uplink_item/dangerous/doublesword/get_discount_value(discount_type)
	switch(discount_type)
		if(TRAITOR_DISCOUNT_BIG)
			return 0.5
		if(TRAITOR_DISCOUNT_AVERAGE)
			return 0.35
		else
			return 0.2

/datum/uplink_item/dangerous/guardian
	name = "Holoparasites"
	desc = "Though capable of near sorcerous feats via use of hardlight holograms and nanomachines, they require an \
			organic host as a home base and source of fuel. Holoparasites come in various types and share damage with their host."
	progression_minimum = 20 MINUTES
	item = /obj/item/guardian_creator/tech
	cost = 18
	surplus = 0
	purchasable_from = ~UPLINK_ALL_SYNDIE_OPS
	restricted = TRUE
	refundable = TRUE

/datum/uplink_item/dangerous/revolver
	name = "Syndicate Revolver"
	desc = "A brutally simple Syndicate revolver that fires .357 Magnum rounds and has 7 chambers."
	item = /obj/item/gun/ballistic/revolver
	cost = 13
	surplus = 50
	purchasable_from = ~UPLINK_ALL_SYNDIE_OPS //only traitors get the original revolver

/datum/uplink_item/dangerous/cat
	name = "Feral cat grenade"
	desc = "This grenade is filled with 5 feral cats in stasis. Upon activation, the feral cats are awoken and unleashed unto unlucky bystanders. WARNING: The cats are not trained to discern friend from foe!"
	cost = 5
	item = /obj/item/grenade/spawnergrenade/cat
	surplus = 30
