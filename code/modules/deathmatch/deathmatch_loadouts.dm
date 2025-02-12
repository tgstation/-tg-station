/datum/outfit/deathmatch_loadout //remember that fun > balance
	name = ""
	shoes = /obj/item/clothing/shoes/sneakers/black // im not doing this on all of them
	/// Name shown in the UI
	var/display_name = ""
	/// Description shown in the UI
	var/desc = ":KILL:"
	/// If defined, using this outfit sets the targets species to it
	var/datum/species/species_override
	/// This outfit will grant these spells if applied
	var/list/spells_to_add = list()
	/// This outfit will grant these mutations if applied
	var/list/mutations_to_add = list()

/datum/outfit/deathmatch_loadout/pre_equip(mob/living/carbon/human/user, visuals_only = FALSE)
	. = ..()
	if(isdummy(user))
		return

	if(!isnull(species_override))
		user.set_species(species_override)

	else if (!isnull(user.dna.species.outfit_important_for_life)) //plasmamen get lit on fire and die
		user.set_species(/datum/species/human)

	for(var/datum/action/act as anything in spells_to_add)
		var/datum/action/new_ability = new act(user)
		if(istype(new_ability, /datum/action/cooldown/spell))
			var/datum/action/cooldown/spell/new_spell = new_ability
			new_spell.spell_requirements = NONE
		new_ability.Grant(user)

	for(var/mutation in mutations_to_add)
		user.dna.add_mutation(mutation)

/datum/outfit/deathmatch_loadout/naked
	name = "Deathmatch: Naked"
	display_name = "Unarmed, Butt-naked"
	desc = "Naked man craves for bloodshed."
	shoes = null

/datum/outfit/deathmatch_loadout/assistant
	name = "Deathmatch: Assistant loadout"
	display_name = "Assistant"
	desc = "A simple assistant loadout: greyshirt and a toolbox"

	l_hand = /obj/item/storage/toolbox/mechanical
	uniform = /obj/item/clothing/under/color/grey
	back = /obj/item/storage/backpack
	box = /obj/item/storage/box/survival
	belt = /obj/item/flashlight

/datum/outfit/deathmatch_loadout/assistant/weaponless
	name = "Deathmatch: Assistant loadout (Weaponless)"
	display_name = "Assistant (Unarmed)"
	desc = "What is an assistant without a toolbox? Nothing!"
	l_hand = null

/datum/outfit/deathmatch_loadout/operative
	name = "Deathmatch: Operative"
	display_name = "Operative"
	desc = "A syndicate operative."

	uniform = /obj/item/clothing/under/syndicate
	shoes = /obj/item/clothing/shoes/combat
	gloves = /obj/item/clothing/gloves/combat
	back = /obj/item/storage/backpack
	id = /obj/item/card/id/advanced/chameleon

/datum/outfit/deathmatch_loadout/operative/ranged
	name = "Deathmatch: Ranged Operative"
	display_name = "Ranged Operative"
	desc = "A syndicate operative with a gun and a knife."

	l_hand = /obj/item/gun/ballistic/automatic/pistol
	l_pocket = /obj/item/knife/combat
	backpack_contents = list(/obj/item/ammo_box/magazine/m9mm = 5)

/datum/outfit/deathmatch_loadout/operative/melee
	name = "Deathmatch: Melee Operative"
	display_name = "Melee Operative"
	desc = "A syndicate operative with multiple knives."

	gloves = /obj/item/clothing/gloves/tackler/combat/insulated
	suit = /obj/item/clothing/suit/armor/vest
	head = /obj/item/clothing/head/helmet
	backpack_contents = list(/obj/item/knife/combat = 6)
	l_hand = /obj/item/knife/combat
	l_pocket = /obj/item/knife/combat

/datum/outfit/deathmatch_loadout/securing_sec
	name = "Deathmatch: Security Officer"
	display_name = "Security Officer"
	desc = "A security officer."

	uniform = /datum/outfit/job/security::uniform
	suit = /datum/outfit/job/security::suit
	suit_store = /datum/outfit/job/security::suit_store
	belt = /datum/outfit/job/security::belt
	ears = /datum/outfit/job/security::ears //cant communicate with station i think?
	gloves = /datum/outfit/job/security::gloves
	head = /datum/outfit/job/security::head
	shoes = /datum/outfit/job/security::shoes
	l_pocket = /obj/item/flashlight/seclite
	l_hand = /obj/item/gun/energy/disabler
	r_pocket = /obj/item/knife/combat/survival
	back = /datum/outfit/job/security::backpack
	box = /datum/outfit/job/security::box
	implants = list(/obj/item/implant/mindshield)

/datum/outfit/deathmatch_loadout/assistant/instagib
	name = "DM: Instagib"
	display_name = "Instagib"
	desc = "Assistant with an instakill rifle."

	l_hand = /obj/item/gun/energy/laser/instakill

/datum/outfit/deathmatch_loadout/operative/sniper
	name = "Deathmatch: Sniper"
	display_name = "Sniper"
	desc = "You know what do you need to do"
	backpack_contents = list(
		/obj/item/ammo_box/magazine/sniper_rounds = 3,
	)
	glasses = /obj/item/clothing/glasses/thermal
	uniform = /obj/item/clothing/under/syndicate/sniper
	gloves = /obj/item/clothing/gloves/tackler/combat/insulated
	l_pocket = /obj/item/knife/combat
	l_hand = /obj/item/gun/ballistic/rifle/sniper_rifle

/datum/outfit/deathmatch_loadout/chef
	name = "Deathmatch: Chef"
	display_name = "Chef"
	desc = "He love pizza."
	uniform = /obj/item/clothing/under/costume/buttondown/slacks/service
	suit = /obj/item/clothing/suit/toggle/chef
	head = /obj/item/clothing/head/utility/chefhat
	mask = /obj/item/clothing/mask/fakemoustache/italian
	gloves = /obj/item/clothing/gloves/the_sleeping_carp
	back = /obj/item/storage/backpack
	backpack_contents = list(
		/obj/item/sharpener,
	)

/datum/outfit/deathmatch_loadout/samurai
	name = "Deathmatch: Samurai"
	display_name = "Samurai"
	desc = "Bare-footed man craves to bloodshed."
	l_hand = /obj/item/katana
	uniform = /obj/item/clothing/under/costume/gi

/// battlers

/datum/outfit/deathmatch_loadout/battler
	name = "Deathmatch: Battler Base"
	display_name = "Battler"
	desc = "What is a battler without weapons?"

	shoes = /obj/item/clothing/shoes/combat
	uniform = /obj/item/clothing/under/syndicate
	gloves = /obj/item/clothing/gloves/combat
	back = /obj/item/storage/backpack
	id = /obj/item/card/id/advanced/chameleon

/datum/outfit/deathmatch_loadout/battler/soldier
	name = "Deathmatch: Soldier"
	display_name = "Soldier"
	desc = "Ready for combat."

	l_hand = /obj/item/gun/ballistic/rifle/boltaction
	l_pocket = /obj/item/knife/combat
	uniform = /obj/item/clothing/under/syndicate/rus_army
	suit = /obj/item/clothing/suit/armor/vest
	head = /obj/item/clothing/head/helmet/rus_helmet
	gloves = /obj/item/clothing/gloves/tackler/combat/insulated

	backpack_contents = list(
		/obj/item/grenade/smokebomb = 2,
		/obj/item/ammo_box/strilka310 = 2,
	)

/datum/outfit/deathmatch_loadout/battler/druid
	name = "Deathmatch: Druid"
	display_name = "Druid"
	desc = "How can plants help you?"

	species_override = /datum/species/pod
	l_hand = /obj/item/gun/ballistic/bow
	r_hand = /obj/item/ammo_casing/arrow
	l_pocket = /obj/item/knife/shiv/carrot
	r_pocket = /obj/item/flashlight/lantern
	head = /obj/item/food/grown/ambrosia/gaia
	uniform = /obj/item/clothing/under/shorts/green
	mask = /obj/item/clothing/mask/gas/tiki_mask
	glasses = /obj/item/clothing/glasses/thermal
	gloves = /obj/item/clothing/gloves/botanic_leather
	belt = /obj/item/gun/syringe/blowgun
	back = /obj/item/storage/backpack/saddlepack
	shoes = /obj/item/clothing/shoes/sandal
	backpack_contents = list(
		/obj/item/reagent_containers/syringe/crude/mushroom = 1,
		/obj/item/reagent_containers/syringe/crude/blastoff = 1,
		/obj/item/ammo_casing/arrow = 2,
		/obj/item/food/grown/nettle/death = 2,
		/obj/item/food/grown/banana = 2,
		/obj/item/food/grown/cherry_bomb = 2,
		/obj/item/food/grown/mushroom/walkingmushroom = 2,
		/obj/item/seeds/kudzu = 1,
	)

/datum/outfit/deathmatch_loadout/battler/northstar
	name = "Deathmatch: North Star"
	display_name = "North Star"
	desc = "flip flip flip"

	uniform = /obj/item/clothing/under/suit/carpskin
	head = /obj/item/clothing/head/fedora/carpskin
	gloves = /obj/item/clothing/gloves/rapid
	backpack_contents = list(
		/obj/item/throwing_star = 6,
		/obj/item/restraints/legcuffs/bola/tactical = 2,
	)

/datum/outfit/deathmatch_loadout/battler/janitor
	name = "Deathmatch: Janitor"
	display_name = "Janitor"
	desc = "Regular work"

	uniform = /obj/item/clothing/under/rank/civilian/janitor
	suit = /obj/item/clothing/suit/caution
	head = /obj/item/reagent_containers/cup/bucket
	shoes = /obj/item/clothing/shoes/chameleon/noslip
	l_hand = /obj/item/pushbroom
	l_pocket = /obj/item/reagent_containers/spray/waterflower/lube
	backpack_contents = list(
		/obj/item/grenade/chem_grenade/cleaner = 2,
		/obj/item/restraints/legcuffs/beartrap = 3,
		/obj/item/soap,
	)

/datum/outfit/deathmatch_loadout/battler/surgeon
	name = "Deathmatch: Surgeon"
	display_name = "Surgeon"
	desc = "Treatment has come"

	uniform = /obj/item/clothing/under/rank/medical/scrubs/blue
	suit = /obj/item/clothing/suit/apron/surgical
	head = /obj/item/clothing/head/utility/surgerycap
	mask = /obj/item/clothing/mask/surgical
	glasses = /obj/item/clothing/glasses/hud/health/night
	l_pocket = /obj/item/reagent_containers/hypospray/combat
	r_pocket = /obj/item/reagent_containers/hypospray/medipen/penthrite
	l_hand = /obj/item/chainsaw
	backpack_contents = list(
		/obj/item/storage/medkit/tactical,
		/obj/item/reagent_containers/hypospray/medipen/stimulants,
	)

/datum/outfit/deathmatch_loadout/battler/raider
	name = "Deathmatch: Raider"
	display_name = "Raider"
	desc = "Not from Shadow Legends"

	l_hand = /obj/item/nullrod/claymore/chainsaw_sword
	r_pocket = /obj/item/switchblade
	uniform = /obj/item/clothing/under/costume/jabroni
	back = /obj/item/spear
	belt = /obj/item/gun/magic/hook
	head = /obj/item/clothing/head/utility/welding

/datum/outfit/deathmatch_loadout/battler/clown
	name = "DM: Clown"
	display_name = "Clown (Man Of Honk)"
	desc = "Who called this honking clown"

	uniform = /datum/outfit/job/clown::uniform
	belt = /datum/outfit/job/clown::belt
	shoes = /datum/outfit/job/clown::shoes
	mask = /datum/outfit/job/clown::mask
	l_pocket = /datum/outfit/job/clown::l_pocket
	back = /datum/outfit/job/clown::backpack
	box = /datum/outfit/job/clown::box
	implants = list(/obj/item/implant/sad_trombone)
	l_pocket = /obj/item/melee/energy/sword/bananium
	r_pocket = /obj/item/shield/energy/bananium
	gloves = /obj/item/clothing/gloves/tackler/rocket
	backpack_contents = list(
		/obj/item/reagent_containers/spray/waterflower = 1,
		/obj/item/instrument/bikehorn = 1,
		/obj/item/bikehorn/airhorn = 1,
		/obj/item/food/grown/banana = 3,
		/obj/item/food/pie/cream = 2,
		)

/datum/outfit/deathmatch_loadout/battler/tgcoder //tg doesnt stand for tgstation dont ask
	name = "Deathmatch: Coder"
	display_name = "Coder"
	desc = "What"

	l_hand = /obj/item/toy/katana
	uniform = /obj/item/clothing/under/costume/schoolgirl
	suit = /obj/item/clothing/suit/costume/joker
	shoes = /obj/item/clothing/shoes/clown_shoes/meown_shoes
	head = /obj/item/clothing/head/costume/kitty
	backpack_contents = list(
		/obj/item/reagent_containers/cup/soda_cans/pwr_game = 10,
	)

/datum/outfit/deathmatch_loadout/battler/enginer
	name = "Deathmatch: Engineer"
	display_name = "Engineer"
	desc = "Meet the engineer"

	l_hand = /obj/item/storage/toolbox/emergency/turret
	uniform = /obj/item/clothing/under/rank/engineering/engineer
	shoes = /obj/item/clothing/shoes/magboots
	head = /obj/item/clothing/head/utility/hardhat
	back = /obj/item/fireaxe
	gloves = /obj/item/clothing/gloves/color/yellow

/datum/outfit/deathmatch_loadout/battler/scientist
	name = "Deathmatch: Scientist"
	display_name = "Scientist"
	desc = "What a nerd"

	uniform = /obj/item/clothing/under/rank/rnd/scientist
	suit = /obj/item/clothing/suit/armor/reactive/stealth
	mask = /obj/item/clothing/mask/gas
	l_hand = /obj/item/reagent_containers/syringe/plasma
	l_pocket = /obj/item/slimecross/stabilized/sepia
	r_pocket = /obj/item/slimecross/stabilized/purple
	backpack_contents = list(
		/obj/item/reagent_containers/cup/bottle/plasma,
		/obj/item/slimecross/burning/grey,
		/obj/item/slimecross/burning/adamantine,
		/obj/item/slimecross/burning/gold,
		/obj/item/slimecross/burning/blue,
		/obj/item/slimecross/burning/sepia,
		/obj/item/slimecross/chilling/green,
		/obj/item/slimecross/chilling/grey,
		/obj/item/slimecross/industrial/oil,
		/obj/item/slimecross/charged/silver,
		/obj/item/slimecross/charged/black,
		/obj/item/slimecross/burning/rainbow,
		/obj/item/slimecross/chilling/adamantine,
	)

/datum/outfit/deathmatch_loadout/battler/bloodminer
	name = "Deathmatch: Blood Miner"
	display_name = "Blood Miner"
	desc = "Rip and tear!!!"

	l_hand = /obj/item/melee/cleaving_saw
	r_hand = /obj/item/gun/energy/recharge/kinetic_accelerator
	uniform = /obj/item/clothing/under/rank/cargo/miner/lavaland
	suit = /obj/item/clothing/suit/hooded/explorer
	shoes = /obj/item/clothing/shoes/workboots/mining
	mask = /obj/item/clothing/mask/gas/explorer
	spells_to_add = list(
		/datum/action/cooldown/mob_cooldown/dash,
	)

/datum/outfit/deathmatch_loadout/battler/ripper
	name = "Deathmatch: Ripper"
	display_name = "Ripper"
	desc = "Die die die!!!"

	l_hand = /obj/item/gun/ballistic/shotgun/hook
	r_hand = /obj/item/gun/ballistic/shotgun/hook
	uniform = /obj/item/clothing/under/costume/skeleton
	suit = /obj/item/clothing/suit/hooded/cultrobes/eldritch
	mask = /obj/item/clothing/mask/gas/cyborg
	shoes = /obj/item/clothing/shoes/sandal
	belt = /obj/item/melee/cleric_mace

/datum/outfit/deathmatch_loadout/battler/cowboy
	name = "Deathmatch: Cowboy"
	display_name = "Cowboy"
	desc = "Yeehaw partner"

	r_hand  = /obj/item/cigarette/cigar
	l_hand = /obj/item/melee/curator_whip
	l_pocket = /obj/item/lighter
	accessory = /obj/item/clothing/accessory/vest_sheriff
	uniform = /obj/item/clothing/under/rank/security/detective
	shoes = /obj/item/clothing/shoes/cowboy
	belt = /obj/item/storage/belt/holster/detective/full
	head = /obj/item/clothing/head/cowboy/brown

/// wizards

/datum/outfit/deathmatch_loadout/wizard
	name = "Deathmatch: Wizard"
	display_name = "Wizard"
	desc = "It's wizard time, motherfucker! FIREBALL!!"

	l_hand = /obj/item/staff
	uniform = /datum/outfit/wizard::uniform
	suit = /datum/outfit/wizard::suit
	head = /datum/outfit/wizard::head
	shoes = /datum/outfit/wizard::shoes
	spells_to_add = list(
		/datum/action/cooldown/spell/aoe/magic_missile,
		/datum/action/cooldown/spell/forcewall,
		/datum/action/cooldown/spell/pointed/projectile/fireball,
	)

/datum/outfit/deathmatch_loadout/wizard/pyro
	name = "Deathmatch: Pyromancer"
	display_name = "Pyromancer"
	desc = "Burninating the station-side! Burninating all the wizards!"

	suit = /obj/item/clothing/suit/wizrobe/red
	head = /obj/item/clothing/head/wizard/red
	mask = /obj/item/cigarette
	spells_to_add = list(
		/datum/action/cooldown/spell/pointed/projectile/fireball,
		/datum/action/cooldown/spell/smoke,
	)

/datum/outfit/deathmatch_loadout/wizard/electro
	name = "Deathmatch: Electromancer"
	display_name = "Electromancer"
	desc = "Batons are so last century."

	suit = /obj/item/clothing/suit/wizrobe/magusred
	head = /obj/item/clothing/head/wizard/magus
	spells_to_add = list(
		/datum/action/cooldown/spell/pointed/projectile/lightningbolt,
		/datum/action/cooldown/spell/charged/beam/tesla,
	)

/datum/outfit/deathmatch_loadout/wizard/necromancer
	name = "Deathmatch: Necromancer"
	display_name = "Necromancer"
	desc = "I've got a BONE to pick- Yeah, sorry."

	species_override = /datum/species/skeleton
	suit = /obj/item/clothing/suit/wizrobe/black
	head = /obj/item/clothing/head/wizard/black
	spells_to_add = list(
		/datum/action/cooldown/spell/touch/scream_for_me,
		/datum/action/cooldown/spell/conjure/link_worlds,
	)

/datum/outfit/deathmatch_loadout/wizard/larp
	name = "Deathmatch: LARPer"
	display_name = "LARPer"
	desc = "Lightning bolt! Lightning bolt! Lightning bolt!"

	l_hand = /obj/item/staff/stick
	suit = /obj/item/clothing/suit/wizrobe/fake
	head = /obj/item/clothing/head/wizard/fake
	shoes = /obj/item/clothing/shoes/sandal
	spells_to_add = list(
		/datum/action/cooldown/spell/conjure_item/spellpacket,
		/datum/action/cooldown/spell/aoe/repulse/wizard,
	)

/datum/outfit/deathmatch_loadout/wizard/chuuni
	name = "Deathmatch: Chuuni"
	display_name = "Chuunibyou"
	desc = "Darkness blacker than black and darker than dark, I beseech thee..."

	l_hand = /obj/item/staff/broom
	suit = /obj/item/clothing/suit/wizrobe/marisa
	head = /obj/item/clothing/head/wizard/marisa
	shoes = /obj/item/clothing/shoes/sneakers/marisa
	spells_to_add = list(
		/datum/action/cooldown/spell/chuuni_invocations,
		/datum/action/cooldown/spell/pointed/projectile/spell_cards,
	)

/datum/outfit/deathmatch_loadout/wizard/battle
	name = "Deathmatch: Battlemage"
	display_name = "Battlemage"
	desc = "Have you heard of the High Elves?"

	l_hand = /obj/item/mjollnir
	suit = /obj/item/clothing/suit/wizrobe/magusblue
	head = /obj/item/clothing/head/wizard/magus
	spells_to_add = list(
		/datum/action/cooldown/spell/summonitem,
	)

/datum/outfit/deathmatch_loadout/wizard/apprentice
	name = "Deathmatch: Apprentice"
	display_name = "Apprentice"
	desc = "You feel severely under-leveled for this encounter..."

	l_hand = null
	spells_to_add = list(
		/datum/action/cooldown/spell/charge,
	)

/datum/outfit/deathmatch_loadout/wizard/gunmancer
	name = "Deathmatch: Gunmancer"
	display_name = "Gunmancer"
	desc = "Magic is lame."

	l_hand = /obj/item/gun/ballistic/automatic/pistol/m1911
	suit = /obj/item/clothing/suit/wizrobe/tape
	head = /obj/item/clothing/head/wizard/tape
	shoes = /obj/item/clothing/shoes/jackboots
	spells_to_add = list(
		/datum/action/cooldown/spell/conjure_item/infinite_guns/gun,
		/datum/action/cooldown/spell/aoe/knock,
	)

/datum/outfit/deathmatch_loadout/wizard/chaos
	name = "Deathmatch: Chaos"
	display_name = "Chaosmancer"
	desc = "Hardcore Random Body ONLY!"

	l_hand = /obj/item/gun/magic/staff/chaos
	uniform = /obj/item/clothing/under/color/rainbow
	suit = /obj/item/clothing/suit/costume/hawaiian
	head = /obj/item/clothing/head/wizard/red
	shoes = /obj/item/clothing/shoes/sneakers/marisa
	spells_to_add = list(
		/datum/action/cooldown/spell/rod_form,
		/datum/action/cooldown/spell/conjure/the_traps,
	)

/datum/outfit/deathmatch_loadout/wizard/clown
	name = "Deathmatch: Clown"
	display_name = "Funnymancer"
	desc = "Honk NATH!"

	l_hand = /obj/item/gun/magic/staff/honk
	uniform = /obj/item/clothing/under/rank/civilian/clown
	suit = /obj/item/clothing/suit/chaplainsuit/clownpriest
	head = /obj/item/clothing/head/chaplain/clownmitre
	mask = /obj/item/clothing/mask/gas/clown_hat
	back = /obj/item/storage/backpack/clown
	shoes = /obj/item/clothing/shoes/clown_shoes
	spells_to_add = null

/datum/outfit/deathmatch_loadout/wizard/monkey
	name = "Deathmatch: Monkey"
	display_name = "Monkeymancer"
	desc = "Ook eek aaa ooo eee!"

	species_override = /datum/species/monkey
	l_hand = /obj/item/food/grown/banana
	uniform = null
	suit = null
	head = /obj/item/clothing/head/wizard
	shoes = null
	spells_to_add = list(
		/datum/action/cooldown/spell/conjure/simian,
	)

/datum/outfit/deathmatch_loadout/head_of_security
	name = "Deathmatch: Head of Security"
	display_name = "Head of Security"
	desc = "Finally, nobody to stop the power from going to your head."

	head = /datum/outfit/job/hos::head
	ears = 	/datum/outfit/job/hos::ears
	uniform = /obj/item/clothing/under/rank/security/head_of_security/alt
	shoes = /datum/outfit/job/hos::shoes
	neck = /datum/outfit/job/hos::neck
	glasses = /datum/outfit/job/hos::glasses
	suit = /obj/item/clothing/suit/armor/hos/hos_formal
	suit_store = /obj/item/gun/ballistic/shotgun/automatic/combat/compact
	gloves = /obj/item/clothing/gloves/tackler/combat
	belt = /obj/item/gun/energy/e_gun/hos
	r_hand = /obj/item/melee/baton/security/loaded
	l_hand = /obj/item/shield/riot/tele
	l_pocket = /obj/item/grenade/flashbang
	r_pocket = /obj/item/restraints/legcuffs/bola/energy

/datum/outfit/deathmatch_loadout/captain
	name = "Deathmatch: Captain"
	display_name = "Captain"
	desc = "Draw your sword and show the syndicate scum no quarter."

	head = /obj/item/clothing/head/hats/caphat/parade
	ears = /obj/item/radio/headset/heads/captain/alt
	uniform = /obj/item/clothing/under/rank/captain
	suit = /obj/item/clothing/suit/armor/vest/capcarapace/captains_formal
	suit_store = /obj/item/gun/energy/e_gun
	shoes = /obj/item/clothing/shoes/laceup
	neck = /obj/item/bedsheet/captain
	glasses = /obj/item/clothing/glasses/sunglasses
	gloves = /obj/item/clothing/gloves/captain
	belt = /obj/item/storage/belt/sabre
	l_hand = /obj/item/gun/energy/laser/captain
	r_pocket = /obj/item/assembly/flash
	l_pocket = /obj/item/melee/baton/telescopic

/datum/outfit/deathmatch_loadout/traitor
	name = "Deathmatch: Traitor"
	display_name = "Traitor"
	desc = "The classic; energy sword & energy bow, donning a reflector trenchcoat (stolen)."

	head = /obj/item/clothing/head/chameleon
	uniform = /obj/item/clothing/under/chameleon
	mask = /obj/item/clothing/mask/chameleon
	suit = /obj/item/clothing/suit/hooded/ablative
	shoes = /obj/item/clothing/shoes/chameleon/noslip
	glasses = /obj/item/clothing/glasses/thermal/syndi
	gloves = /obj/item/clothing/gloves/combat
	suit_store = /obj/item/gun/energy/recharge/ebow
	l_hand = /obj/item/melee/energy/sword
	r_pocket = /obj/item/reagent_containers/hypospray/medipen/stimulants
	l_pocket = /obj/item/soap/syndie
	belt = /obj/item/gun/ballistic/revolver

/datum/outfit/deathmatch_loadout/nukie
	name = "Deathmatch: Nuclear Operative"
	display_name = "Nuclear Operative"
	desc = "Gear afforded to Lone Operatives. Your mission is simple."

	uniform = /obj/item/clothing/under/syndicate/tacticool
	back = /obj/item/mod/control/pre_equipped/nuclear
	r_hand = /obj/item/gun/ballistic/shotgun/bulldog/unrestricted
	belt = /obj/item/gun/ballistic/automatic/pistol/clandestine
	r_pocket = /obj/item/reagent_containers/hypospray/medipen/stimulants
	l_pocket = /obj/item/grenade/syndieminibomb
	implants = list(/obj/item/implant/explosive)

	backpack_contents = list(
		/obj/item/ammo_box/c10mm,
		/obj/item/ammo_box/magazine/m12g = 2,
		/obj/item/pen/edagger,
		/obj/item/reagent_containers/hypospray/medipen/atropine,
	)

/datum/outfit/deathmatch_loadout/pete
	name = "Deathmatch: Cuban Pete"
	display_name = "Disciple of Pete"
	desc = "You took a lesson from Cuban Pete."

	back = /obj/item/storage/backpack/santabag
	head = /obj/item/clothing/head/collectable/petehat
	uniform = /obj/item/clothing/under/pants/camo
	suit = /obj/item/clothing/suit/costume/poncho
	belt = /obj/item/storage/belt/grenade/full
	shoes = /obj/item/clothing/shoes/workboots
	l_hand = /obj/item/reagent_containers/cup/glass/bottle/rum
	r_hand = /obj/item/sbeacondrop/bomb
	l_pocket = /obj/item/grenade/syndieminibomb
	r_pocket = /obj/item/grenade/syndieminibomb
	implants = list(/obj/item/implant/explosive/macro)
	backpack_contents = list(
		/obj/item/assembly/signaler = 10,
	)

/datum/outfit/deathmatch_loadout/tider
	name = "Deathmatch: Tider"
	display_name = "Tider"
	desc = "A very high power level Assistant."

	back = /obj/item/melee/baton/security/cattleprod
	r_hand = /obj/item/fireaxe
	uniform = /obj/item/clothing/under/color/grey/ancient
	mask = /obj/item/clothing/mask/gas
	shoes = /obj/item/clothing/shoes/sneakers/black
	gloves = /obj/item/clothing/gloves/cut
	l_pocket = /obj/item/reagent_containers/hypospray/medipen/methamphetamine
	r_pocket = /obj/item/stock_parts/power_store/cell/high
	belt = /obj/item/storage/belt/utility/full

/datum/outfit/deathmatch_loadout/abductor
	name = "Deathmatch: Abductor"
	display_name = "Abductor"
	desc = "We come in peace."

	species_override = /datum/species/abductor
	uniform = /obj/item/clothing/under/abductor
	head = /obj/item/clothing/head/helmet/abductor
	suit = /obj/item/clothing/suit/armor/abductor/vest
	l_pocket = /obj/item/reagent_containers/hypospray/medipen/atropine
	r_pocket = /obj/item/grenade/gluon
	l_hand = /obj/item/gun/energy/alien
	r_hand = /obj/item/gun/energy/alien
	belt = /obj/item/gun/energy/shrink_ray

/datum/outfit/deathmatch_loadout/battler/clown/upgraded
	name = "Deathmatch: Clown (Syndicate Gear)"
	display_name = "Clown Commando"
	desc = "They were bound to show up sooner or later."

	shoes = /obj/item/clothing/shoes/clown_shoes/combat
	r_hand = /obj/item/pneumatic_cannon/pie/selfcharge
	l_hand = /obj/item/bikehorn/golden
	box = /obj/item/storage/box/hug/reverse_revolver

	backpack_contents = list(
		/obj/item/paperplane/syndicate = 1,
		/obj/item/restraints/legcuffs/bola/tactical = 1,
		/obj/item/restraints/legcuffs/beartrap = 1,
		/obj/item/food/grown/banana = 1,
		/obj/item/food/pie/cream = 1,
		/obj/item/dnainjector/clumsymut,
		/obj/item/sbeacondrop/clownbomb,
		)

/datum/outfit/deathmatch_loadout/mime
	name = "Deathmatch: Mime"
	display_name = "Mime"
	desc = "..."

	uniform = /datum/outfit/job/mime::uniform
	belt = /obj/item/food/baguette/combat
	head = /datum/outfit/job/mime::head
	shoes = /datum/outfit/job/mime::shoes
	mask = /datum/outfit/job/mime::mask
	back = /datum/outfit/job/mime::backpack
	box = /datum/outfit/job/mime::box
	l_pocket = /obj/item/toy/crayon/spraycan/mimecan
	r_pocket = /obj/item/food/grown/banana/mime
	neck = /datum/outfit/job/mime::neck
	gloves = /datum/outfit/job/mime::gloves

	backpack_contents = list(
		/obj/item/reagent_containers/cup/glass/bottle/bottleofnothing,
		/obj/item/gun/ballistic/automatic/pistol,
		/obj/item/suppressor,
		/obj/item/ammo_box/c9mm,
		/obj/item/food/croissant/throwing = 2,
		)

	spells_to_add = list(
		/datum/action/cooldown/spell/vow_of_silence,
		/datum/action/cooldown/spell/conjure_item/invisible_box,
		/datum/action/cooldown/spell/conjure/invisible_chair,
		/datum/action/cooldown/spell/conjure/invisible_wall,
		/datum/action/cooldown/spell/forcewall/mime,
		/datum/action/cooldown/spell/pointed/projectile/finger_guns,
		)

/datum/outfit/deathmatch_loadout/chef/upgraded
	name = "Deathmatch: Master Chef"
	display_name = "Master Chef"
	desc = "Let him cook."

	belt = /obj/item/gun/magic/hook
	uniform = /obj/item/clothing/under/costume/buttondown/slacks/service
	suit = /obj/item/clothing/suit/toggle/chef
	suit_store = /obj/item/knife/kitchen
	head = /obj/item/clothing/head/utility/chefhat
	mask = /obj/item/clothing/mask/fakemoustache/italian
	gloves = /obj/item/clothing/gloves/the_sleeping_carp
	back = /obj/item/storage/backpack

	backpack_contents = list(
		/obj/item/pizzabox/bomb/armed = 3,
		/obj/item/knife/butcher,
		/obj/item/sharpener,
	)

//species

/datum/outfit/deathmatch_loadout/humanity
	name = "Deathmatch: Human Species"
	display_name = "Humanity"
	desc = "The most ambitious and successful species. Or just the most rapacious, depending on who you ask."
	species_override = /datum/species/human

	head = /obj/item/clothing/head/soft/black
	glasses = /obj/item/clothing/glasses/sunglasses
	ears = /obj/item/radio/headset/headset_com
	neck = /obj/item/clothing/neck/large_scarf/blue
	//suit
	id_trim = /datum/id_trim/job/bridge_assistant // half tider half command
	id = /obj/item/card/id/advanced/chameleon
	uniform = /obj/item/clothing/under/trek/command/next
	l_pocket = /obj/item/gun/energy/e_gun/mini // they are thej best race in the end. not as impactful as you may think
	r_pocket = /obj/item/extinguisher/mini
	gloves = /obj/item/clothing/gloves/fingerless
	belt = /obj/item/storage/belt/utility/full/inducer
	shoes = /obj/item/clothing/shoes/sneakers/black

// Lizard: Desert, Soldier, Trash

/datum/outfit/deathmatch_loadout/lizardkind
	name = "Deathmatch: Lizard Species"
	display_name = "Lizardfolk"
	desc = "They may be heavily discriminated against, they may be most often seen doing menial activities, but at least they, uh, uhh..."
	species_override = /datum/species/lizard

	head = /obj/item/clothing/head/soft/purple
	id_trim = /datum/id_trim/job/janitor
	id = /obj/item/card/id/advanced/chameleon
	uniform = /obj/item/clothing/under/rank/civilian/janitor
	gloves = /obj/item/clothing/gloves/color/black
	belt = /obj/item/storage/belt/janitor/full
	shoes = /obj/item/clothing/shoes/chameleon/noslip
	r_hand  = /obj/item/mop/advanced
	back = /obj/item/storage/backpack
	backpack_contents = list(
		/obj/item/toy/plush/lizard_plushie/green,
		// reclaiming lizard racism
		/obj/item/reagent_containers/cup/glass/bottle/lizardwine,
		/obj/item/tailclub,
		/obj/item/melee/chainofcommand/tailwhip,
		/obj/item/reagent_containers/cup/glass/coffee
	)

/datum/outfit/deathmatch_loadout/mothman
	name = "Deathmatch: Moth Species"
	display_name = "Mothmen"
	desc = "An innocent and fluffy visage hides the combat ability of a particularly hairy kitten."
	species_override = /datum/species/moth

	head = /obj/item/clothing/head/utility/head_mirror
	glasses = /obj/item/clothing/glasses/hud/health
	suit = /obj/item/clothing/suit/hooded/wintercoat/medical
	suit_store = /obj/item/flashlight/pen/paramedic
	id_trim = /datum/id_trim/job/medical_doctor
	id = /obj/item/card/id/advanced/chameleon
	uniform = /obj/item/clothing/under/rank/medical/scrubs/blue
	belt = /obj/item/storage/belt/medical/paramedic
	shoes = /obj/item/clothing/shoes/sneakers/white
	l_hand = /obj/item/circular_saw

	back = /obj/item/storage/backpack/medic

	backpack_contents = list(
		/obj/item/toy/plush/moth,
		/obj/item/storage/medkit/brute,
		/obj/item/storage/medkit/fire,
		/obj/item/statuebust/hippocratic
	)

// Roboticist??
/datum/outfit/deathmatch_loadout/ethereal
	name = "Deathmatch: Ethereal Species"
	display_name = "Etherealkind"
	desc = "Prepare to be SHOCKED as you are reminded of this species's existence."
	species_override = /datum/species/ethereal

	head = /obj/item/clothing/head/soft/black
	id_trim = /datum/id_trim/job/roboticist
	id = /obj/item/card/id/advanced/chameleon
	suit = /obj/item/clothing/suit/toggle/labcoat/roboticist
	suit_store = /datum/id_trim/job/roboticist
	uniform = /obj/item/clothing/under/rank/rnd/roboticist
	l_pocket = /obj/item/assembly/flash
	belt = /obj/item/storage/belt/utility/full
	shoes = /obj/item/clothing/shoes/sneakers/black

	back = /obj/item/storage/backpack/science

	backpack_contents = list(
		/obj/item/etherealballdeployer,
	)

	mutations_to_add = list(/obj/item/dnainjector/shock) // pretend ethereals are interesting

/datum/outfit/deathmatch_loadout/plasmamen
	name = "Deathmatch: Plasmaman Species"
	display_name = "Plasmamen"
	desc = "Burn baby burn!"
	species_override = /datum/species/plasmaman

	head = /obj/item/clothing/head/helmet/space/plasmaman/atmospherics
	suit = /obj/item/clothing/suit/hazardvest
	suit_store = /obj/item/flashlight
	uniform = /obj/item/clothing/under/plasmaman/atmospherics
	id_trim = /datum/id_trim/job/atmospheric_technician
	id = /obj/item/card/id/advanced/chameleon
	belt = /obj/item/storage/belt/utility/atmostech
	gloves = /obj/item/clothing/gloves/color/plasmaman/atmos
	shoes = /obj/item/clothing/shoes/workboots
	r_pocket = /obj/item/tank/internals/plasmaman/belt/full

	back = /obj/item/storage/backpack/industrial

	backpack_contents = list(
		/obj/item/toy/plush/plasmamanplushie,
		/obj/item/tank/internals/plasma,
		/obj/item/tank/internals/plasmaman,
		/obj/item/stack/sheet/mineral/uranium/half,
		/obj/item/stack/sheet/mineral/plasma/thirty,
		/obj/item/reagent_containers/condiment/milk,
		/obj/item/storage/medkit/fire,
		/obj/item/reagent_containers/syringe/plasma
	)

/datum/outfit/deathmatch_loadout/felinid
	name = "Deathmatch: Felinid Species"
	display_name = "Felinids"
	desc = "Strictly inferior to humans in every way."
	species_override = /datum/species/human/felinid

	head = /obj/item/clothing/head/soft/rainbow
	glasses = null
	ears = /obj/item/radio/headset
	neck = /obj/item/clothing/neck/petcollar
	//suit
	uniform = /obj/item/clothing/under/color/rainbow
	l_pocket = /obj/item/toy/cattoy
	r_pocket = /obj/item/restraints/handcuffs/fake
	gloves = /obj/item/clothing/gloves/color/rainbow
	belt = /obj/item/melee/curator_whip
	shoes = /obj/item/clothing/shoes/sneakers/rainbow

//spleef

/datum/outfit/deathmatch_loadout/lattice_battles
	name = "Deathmatch: Lattice loadout"
	display_name = "Lattice Battler"
	desc = "Snip the catwalks under everyone else and win! You're pacifist, so no punching."

	uniform = /obj/item/clothing/under/pants/jeans
	suit = /obj/item/clothing/suit/costume/wellworn_shirt/graphic
	r_pocket = /obj/item/stack/rods/twentyfive
	l_pocket = /obj/item/stack/rods/twentyfive
	r_hand = /obj/item/wirecutters

// We don't want them to just punch each other to death

/datum/outfit/deathmatch_loadout/lattice_battles/pre_equip(mob/living/carbon/human/user, visuals_only)
	. = ..()
	ADD_TRAIT(user, TRAIT_PACIFISM, REF(src))

// Ragnarok: Fight between religions!

/datum/outfit/deathmatch_loadout/cultish/pre_equip(mob/living/carbon/human/user, visuals_only)
	. = ..()
	ADD_TRAIT(user, TRAIT_ACT_AS_CULTIST, REF(src))
	user.AddElement(/datum/element/cult_halo, initial_delay = 0 SECONDS)
	user.AddElement(/datum/element/cult_eyes, initial_delay = 0 SECONDS)

// Cultist Invoker, has all the balanced cult gear

/datum/outfit/deathmatch_loadout/cultish/invoker
	name = "Deathmatch: Cultist Invoker"
	display_name = "Cultist Invoker"
	desc = "Prove Nar'sie's superiority with your well-balanced set of equipment."
	//species_override = /datum/species/plasmaman

	head = /obj/item/clothing/head/hooded/cult_hoodie/cult_shield
	glasses = /obj/item/clothing/glasses/hud/health/night/cultblind
	suit = /obj/item/clothing/suit/hooded/cultrobes/cult_shield // the dreaded return!
	suit_store = /obj/item/melee/cultblade
	uniform = /obj/item/clothing/under/color/black
	id_trim = null
	belt = /obj/item/melee/cultblade/dagger
	l_pocket = /obj/item/flashlight/flare/culttorch
	r_pocket = /obj/item/flashlight/flare/culttorch
	gloves = /obj/item/clothing/gloves/color/black
	shoes = /obj/item/clothing/shoes/cult/alt
	l_hand = /obj/item/shield/mirror // the dreaded return!!

	back = /obj/item/storage/backpack/cultpack

	backpack_contents = list(
		/obj/item/reagent_containers/cup/beaker/unholywater,
		/obj/item/reagent_containers/cup/beaker/unholywater,
	)

// Cultist Artificer, gets all the balanced cult magicks

/datum/outfit/deathmatch_loadout/cultish/artificer
	name = "Deathmatch: Cultist Artificer"
	display_name = "Cultist Artificer"
	desc = "Prove Nar'sie's superiority with your well-balanced blood magicks."
	//species_override = /datum/species/plasmaman

	head = /obj/item/clothing/head/hooded/cult_hoodie/berserkerhood
	neck = /obj/item/clothing/neck/heretic_focus/crimson_medallion
	suit = /obj/item/clothing/suit/hooded/cultrobes/berserker
	suit_store = /obj/item/melee/sickly_blade/cursed
	uniform = /obj/item/clothing/under/color/red
	id_trim = null
	belt = /obj/item/melee/cultblade/dagger
	l_pocket = /obj/item/flashlight/flare/culttorch
	r_pocket = /obj/item/flashlight/flare/culttorch
	gloves = /obj/item/clothing/gloves/color/red
	shoes = /obj/item/clothing/shoes/cult
	l_hand = null

	back = /obj/item/storage/backpack/cultpack

	backpack_contents = list(
		/obj/item/restraints/legcuffs/bola/cult,
		/obj/item/reagent_containers/cup/beaker/unholywater,
		/obj/item/reagent_containers/cup/beaker/unholywater,
	)

	spells_to_add = list(
		/datum/action/innate/cult/blood_spell/horror,
		/datum/action/innate/cult/blood_spell/stun,
		/datum/action/innate/cult/blood_spell/stun,
		/datum/action/innate/cult/blood_spell/manipulation,
	)

/datum/outfit/deathmatch_loadout/cultish/artificer/post_equip(mob/living/carbon/human/user, visuals_only)
	. = ..()
	var/datum/action/innate/cult/blood_spell/manipulation/magick = locate() in user.get_all_contents()
	magick.charges = 300

/datum/outfit/deathmatch_loadout/heresy
	/// Grants the effects of these knowledges to the DMer
	var/list/knowledge_to_grant

/datum/outfit/deathmatch_loadout/heresy/pre_equip(mob/living/carbon/human/user, visuals_only)
	. = ..()
	ADD_TRAIT(user, TRAIT_ACT_AS_HERETIC, REF(src))
	user.AddElement(/datum/element/leeching_walk)

	// Creates the knowledge as an isolated datum inside the target, allowing passive knowledges to work still.
	for(var/datum/heretic_knowledge/knowhow as anything in knowledge_to_grant)
		knowhow = new knowhow(user)
		knowhow.on_gain(user, null)

// Heretic Warrior

/datum/outfit/deathmatch_loadout/heresy/warrior
	name = "Deathmatch: Heretic Warrior"
	display_name = "Heretic Warrior"
	desc = "Prove the furious strength of the Mansus!"

	head = /obj/item/clothing/head/hooded/cult_hoodie/eldritch
	neck = /obj/item/clothing/neck/heretic_focus
	suit = /obj/item/clothing/suit/hooded/cultrobes/eldritch
	suit_store = /obj/item/melee/sickly_blade/dark
	uniform = /obj/item/clothing/under/color/darkgreen
	id_trim = null
	belt = /obj/item/melee/sickly_blade/rust
	gloves = null
	shoes = /obj/item/clothing/shoes/sandal
	l_pocket = /obj/item/flashlight/lantern/jade/on
	r_pocket = /obj/item/melee/rune_carver
	l_hand = null

	back = /obj/item/storage/backpack

	backpack_contents = list(
		/obj/item/reagent_containers/cup/beaker/eldritch,
		/obj/item/reagent_containers/cup/beaker/eldritch,
		/obj/item/eldritch_potion/wounded,
		/obj/item/eldritch_potion/wounded,
	)

	// I mean is it really that bad if they don't even know half this stuff is added to them.
	// It's like, forbidden knowledge. It fits with the mansus theme - great excuse for poor design!
	knowledge_to_grant = list(
		/datum/heretic_knowledge/blade_grasp,
		/datum/heretic_knowledge/blade_dance,
		/datum/heretic_knowledge/blade_upgrade/blade,
	)

	spells_to_add = list(
		/datum/action/cooldown/spell/touch/mansus_grasp,
		/datum/action/cooldown/spell/realignment,
		/datum/action/cooldown/spell/pointed/projectile/furious_steel,
		/datum/action/cooldown/spell/cone/staggered/entropic_plume,
		/datum/action/cooldown/spell/pointed/rust_construction,
	)

// Heretic Scribe

/datum/outfit/deathmatch_loadout/heresy/scribe
	name = "Deathmatch: Heretic Scribe"
	display_name = "Heretic Scribe"
	desc = "Reveal the forgotten knowledge of the Mansus."

	head = /obj/item/clothing/head/helmet/chaplain/witchunter_hat
	mask = /obj/item/clothing/mask/madness_mask
	neck = /obj/item/clothing/neck/eldritch_amulet
	suit = /obj/item/clothing/suit/hooded/cultrobes/void
	suit_store = /obj/item/melee/sickly_blade
	uniform = /obj/item/clothing/under/costume/gamberson/military
	id_trim = null
	belt = /obj/item/storage/belt/unfathomable_curio
	gloves = null
	shoes = /obj/item/clothing/shoes/winterboots/ice_boots
	l_pocket = /obj/item/ammo_box/strilka310/lionhunter
	r_pocket = /obj/item/ammo_box/strilka310/lionhunter

	back = /obj/item/gun/ballistic/rifle/lionhunter // for his neutral b, he wields a gun

	belt_contents = list(
		/obj/item/heretic_labyrinth_handbook,
		/obj/item/heretic_labyrinth_handbook,
		/obj/item/eldritch_potion/duskndawn,
		/obj/item/eldritch_potion/duskndawn,
	)

	knowledge_to_grant = list(
		/datum/heretic_knowledge/cosmic_grasp,
	)

	spells_to_add = list(
		/datum/action/cooldown/spell/touch/mansus_grasp,
		/datum/action/cooldown/spell/pointed/projectile/star_blast,
		/datum/action/cooldown/spell/touch/star_touch,
		/datum/action/cooldown/spell/aoe/void_pull,
		/datum/action/cooldown/spell/pointed/void_phase,
	)

// Chaplain! No spells (other than smoke), but strong armor and weapons, and immune to others' spells

/datum/outfit/deathmatch_loadout/holy_crusader
	name = "Deathmatch: Holy Crusader"
	display_name = "Holy Crusader"
	desc = "Smite the heathens!!"
	//species_override = /datum/species/plasmaman

	head = /obj/item/clothing/head/helmet/chaplain
	neck = /obj/item/camera/spooky
	suit = /obj/item/clothing/suit/chaplainsuit/armor/templar
	suit_store = /obj/item/book/bible/booze
	uniform = /obj/item/clothing/under/rank/civilian/chaplain
	id_trim = null
	belt = /obj/item/nullrod/non_station // choose any!
	gloves = /obj/item/clothing/gloves/plate
	shoes = /obj/item/clothing/shoes/plate
	l_pocket = /obj/item/flashlight/lantern/on
	r_pocket = /obj/item/reagent_containers/cup/glass/bottle/holywater
	l_hand = /obj/item/shield/buckler

	back = /obj/item/claymore/weak // or don't

	spells_to_add = list(
		/datum/action/cooldown/spell/smoke/lesser
	)
	mutations_to_add = list(
		/datum/mutation/human/medieval,
		/datum/mutation/human/lay_on_hands, // useless, but fun
	)

// Rat'var Apostate

/datum/outfit/deathmatch_loadout/clock_cult
	name = "Deathmatch: Clock Cultist"
	display_name = "Rat'var Apostate"
	desc = "You're in a fight between the servants of gods, and yours is dead. Good luck?"

	head = /obj/item/clothing/head/costume/bronze
	suit = /obj/item/clothing/suit/costume/bronze
	suit_store = /obj/item/toy/clockwork_watch
	uniform = /obj/item/clothing/under/chameleon
	id_trim = null
	belt = /obj/item/brass_spear
	gloves = /obj/item/clothing/gloves/tinkerer
	shoes = /obj/item/clothing/shoes/bronze
	l_pocket = /obj/item/reagent_containers/cup/beaker/synthflesh/named // they used to turn their dmg into tox with a spell. close enough
	r_pocket = /obj/item/reagent_containers/cup/beaker/synthflesh/named
