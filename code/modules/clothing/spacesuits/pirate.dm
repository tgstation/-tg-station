/obj/item/clothing/head/helmet/space/pirate
	name = "modified EVA helmet"
	desc = "A modified helmet to allow space pirates to intimidate their customers whilst staying safe from the void. Comes with some additional protection."
	icon_state = "spacepirate"
	inhand_icon_state = "space_pirate_helmet"
	armor_type = /datum/armor/space_pirate
	strip_delay = 40
	equip_delay_other = 20
	fishing_modifier = -2
	visor_dirt = null

/datum/armor/space_pirate
	melee = 30
	bullet = 50
	laser = 30
	energy = 40
	bomb = 30
	bio = 30
	fire = 60
	acid = 75

/obj/item/clothing/head/helmet/space/pirate/bandana
	icon_state = "spacebandana"

/obj/item/clothing/suit/space/pirate
	name = "modified EVA suit"
	desc = "A modified suit to allow space pirates to board shuttles and stations while avoiding the maw of the void. Comes with additional protection and is lighter to move in."
	icon_state = "spacepirate"
	w_class = WEIGHT_CLASS_NORMAL
	allowed = list(/obj/item/gun, /obj/item/melee/baton, /obj/item/restraints/handcuffs, /obj/item/tank/internals, /obj/item/melee/energy/sword/pirate, /obj/item/clothing/glasses/eyepatch, /obj/item/reagent_containers/cup/glass/bottle/rum)
	slowdown = 0
	armor_type = /datum/armor/space_pirate
	strip_delay = 40
	equip_delay_other = 20
	fishing_modifier = -3

/obj/item/clothing/head/helmet/space/pirate/tophat
	name = "designer pirate helmet"
	desc = "A modified EVA helmet with a five-thousand credit Lizzy Vuitton hat affixed to the top, proving that working in deep space is no excuse for being poor."
	icon_state = "spacetophat"

/obj/item/clothing/head/helmet/space/pirate/tophat/add_stabilizer(loose_hat = FALSE)
	return

/obj/item/clothing/suit/space/pirate/silverscale
	name = "designer pirate suit"
	desc = "A specially-made Cybersun branded space suit; the fine plastisilk exterior is woven from the cocoons of black-market Lümlan mothroaches \
		and the trim is lined with the ivory of the critically endangered Zanzibarian dwarf elephant. Baby seal leather boots sold separately."
	inhand_icon_state = "syndicate-black"
	icon_state = "syndicate-black-white"
