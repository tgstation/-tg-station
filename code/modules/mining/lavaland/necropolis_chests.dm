//The chests dropped by tendrils and megafauna.

/obj/structure/closet/crate/necropolis
	name = "necropolis chest"
	desc = "It's watching you closely."
	icon_state = "necrocrate"
	base_icon_state = "necrocrate"
	resistance_flags = LAVA_PROOF | FIRE_PROOF | ACID_PROOF
	can_install_electronics = FALSE
	paint_jobs = null
	can_weld_shut = FALSE

/obj/structure/closet/crate/necropolis/tendril
	desc = "It's watching you suspiciously. You need a skeleton key to open it."
	integrity_failure = 0 //prevents bust_open from firing
	/// var to check if it got opened by a key
	var/spawned_loot = FALSE

/obj/structure/closet/crate/necropolis/tendril/attackby(obj/item/item, mob/user, params)
	if(!istype(item, /obj/item/skeleton_key) || spawned_loot)
		return ..()
	var/loot = rand(1,21)
	var/mod
	switch(loot)
		if(1)
			new /obj/item/shared_storage/red(src)
		if(2)
			new /obj/item/soulstone/anybody/mining(src)
		if(3)
			new /obj/item/organ/cyberimp/arm/shard/katana(src)
		if(4)
			new /obj/item/clothing/glasses/godeye(src)
		if(5)
			new /obj/item/reagent_containers/cup/bottle/potion/flight(src)
		if(6)
			new /obj/item/clothing/gloves/gauntlets(src)
		if(7)
			mod = rand(1,4)
			switch(mod)
				if(1)
					new /obj/item/disk/design_disk/modkit_disc/resonator_blast(src)
				if(2)
					new /obj/item/disk/design_disk/modkit_disc/rapid_repeater(src)
				if(3)
					new /obj/item/disk/design_disk/modkit_disc/mob_and_turf_aoe(src)
				if(4)
					new /obj/item/disk/design_disk/modkit_disc/bounty(src)
		if(8)
			new /obj/item/rod_of_asclepius(src)
		if(9)
			new /obj/item/organ/heart/cursed/wizard(src)
		if(10)
			new /obj/item/ship_in_a_bottle(src)
		if(11)
			new /obj/item/clothing/suit/hooded/berserker(src)
		if(12)
			new /obj/item/jacobs_ladder(src)
		if(13)
			new /obj/item/guardian_creator/miner(src)
		if(14)
			new /obj/item/warp_cube/red(src)
		if(15)
			new /obj/item/wisp_lantern(src)
		if(16)
			new /obj/item/immortality_talisman(src)
		if(17)
			new /obj/item/book/granter/action/spell/summonitem(src)
		if(18)
			new /obj/item/book_of_babel(src)
		if(19)
			new /obj/item/borg/upgrade/modkit/lifesteal(src)
			new /obj/item/bedsheet/cult(src)
		if(20)
			new /obj/item/clothing/neck/necklace/memento_mori(src)
		if(21)
			new /obj/item/clothing/gloves/fingerless/punch_mitts(src)
			new /obj/item/clothing/head/cowboy(src)
	if(!contents.len)
		to_chat(user, span_warning("[src] makes a clunking sound as you try to open it. You feel compelled to let the gods know! (Please open an adminhelp and try again!)"))
		CRASH("Failed to generate loot. loot number: [loot][mod ? "subloot: [mod]" : null]")
	spawned_loot = TRUE
	qdel(item)
	to_chat(user, span_notice("You disable the magic lock, revealing the loot."))

/obj/structure/closet/crate/necropolis/tendril/before_open(mob/living/user, force)
	. = ..()
	if(!.)
		return FALSE

	if(!broken && !force && !spawned_loot)
		balloon_alert(user, "its locked!")
		return FALSE

	return TRUE

//Megafauna chests

/obj/structure/closet/crate/necropolis/dragon
	name = "dragon chest"

/obj/structure/closet/crate/necropolis/dragon/PopulateContents()
	var/loot = rand(1,4)
	switch(loot)
		if(1)
			new /obj/item/melee/ghost_sword(src)
		if(2)
			new /obj/item/lava_staff(src)
		if(3)
			new /obj/item/book/granter/action/spell/sacredflame(src)
		if(4)
			new /obj/item/dragons_blood(src)

/obj/structure/closet/crate/necropolis/dragon/crusher
	name = "firey dragon chest"

/obj/structure/closet/crate/necropolis/dragon/crusher/PopulateContents()
	..()
	new /obj/item/crusher_trophy/tail_spike(src)

/obj/structure/closet/crate/necropolis/bubblegum
	name = "\improper Ancient Sarcophagus"
	desc = "Once guarded by the King of Demons, this sarcophagus contains the relics of an ancient soldier."
	icon_state = "necro_bubblegum"
	base_icon_state = "necro_bubblegum"
	lid_icon_state = "necro_bubblegum_lid"
	lid_x = -26
	lid_y = 2

/obj/structure/closet/crate/necropolis/bubblegum/PopulateContents()
	new /obj/item/clothing/suit/hooded/hostile_environment(src)
	var/loot = rand(1,2)
	switch(loot)
		if(1)
			new /obj/item/mayhem(src)
		if(2)
			new /obj/item/soulscythe(src)

/obj/structure/closet/crate/necropolis/bubblegum/crusher
	name = "bloody bubblegum chest"

/obj/structure/closet/crate/necropolis/bubblegum/crusher/PopulateContents()
	..()
	new /obj/item/crusher_trophy/demon_claws(src)

/obj/structure/closet/crate/necropolis/colossus
	name = "colossus chest"

/obj/structure/closet/crate/necropolis/colossus/bullet_act(obj/projectile/proj)
	if(istype(proj, /obj/projectile/colossus))
		return BULLET_ACT_FORCE_PIERCE
	return ..()

/obj/structure/closet/crate/necropolis/colossus/PopulateContents()
	var/list/choices = subtypesof(/obj/machinery/anomalous_crystal)
	var/random_crystal = pick(choices)
	new random_crystal(src)
	new /obj/item/organ/vocal_cords/colossus(src)
	new /obj/item/cain_and_abel(src)

/obj/structure/closet/crate/necropolis/colossus/crusher
	name = "angelic colossus chest"

/obj/structure/closet/crate/necropolis/colossus/crusher/PopulateContents()
	..()
	new /obj/item/crusher_trophy/blaster_tubes(src)

//Other chests and minor stuff

/obj/structure/closet/crate/necropolis/puzzle
	name = "puzzling chest"

/obj/structure/closet/crate/necropolis/puzzle/PopulateContents()
	var/loot = rand(1,3)
	switch(loot)
		if(1)
			new /obj/item/soulstone/anybody/mining(src)
		if(2)
			new /obj/item/wisp_lantern(src)
		if(3)
			new /obj/item/prisoncube(src)

/obj/item/skeleton_key
	name = "skeleton key"
	desc = "An artifact usually found in the hands of the natives of lavaland, which NT now holds a monopoly on."
	icon = 'icons/obj/mining_zones/artefacts.dmi'
	icon_state = "skeleton_key"
	w_class = WEIGHT_CLASS_SMALL
