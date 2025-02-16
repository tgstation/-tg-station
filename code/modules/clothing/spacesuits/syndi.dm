//Regular syndicate space suit
/obj/item/clothing/head/helmet/space/syndicate
	name = "red space helmet"
	icon_state = "syndicate"
	inhand_icon_state = "space_syndicate"
	desc = "Has a tag on it: Totally not property of an enemy corporation, honest!"
	armor_type = /datum/armor/space_syndicate

/datum/armor/space_syndicate
	melee = 40
	bullet = 50
	laser = 30
	energy = 40
	bomb = 30
	bio = 30
	fire = 80
	acid = 85

// Don't blame me, blame whoever added this many variations
GLOBAL_LIST_INIT(syndicate_space_suits_to_helmets,list(
	/obj/item/clothing/suit/space/syndicate = /obj/item/clothing/head/helmet/space/syndicate,
	/obj/item/clothing/suit/space/syndicate/green = /obj/item/clothing/head/helmet/space/syndicate/green,
	/obj/item/clothing/suit/space/syndicate/green/dark = /obj/item/clothing/head/helmet/space/syndicate/green/dark,
	/obj/item/clothing/suit/space/syndicate/orange = /obj/item/clothing/head/helmet/space/syndicate/orange,
	/obj/item/clothing/suit/space/syndicate/blue = /obj/item/clothing/head/helmet/space/syndicate/blue,
	/obj/item/clothing/suit/space/syndicate/black = /obj/item/clothing/head/helmet/space/syndicate/black,
	/obj/item/clothing/suit/space/syndicate/black/green = /obj/item/clothing/head/helmet/space/syndicate/black/green,
	/obj/item/clothing/suit/space/syndicate/black/blue = /obj/item/clothing/head/helmet/space/syndicate/black/blue,
	/obj/item/clothing/suit/space/syndicate/black/orange = /obj/item/clothing/head/helmet/space/syndicate/black/orange,
	/obj/item/clothing/suit/space/syndicate/black/red = /obj/item/clothing/head/helmet/space/syndicate/black/red,
	/obj/item/clothing/suit/space/syndicate/black/white = /obj/item/clothing/head/helmet/space/syndicate/black,
	/obj/item/clothing/suit/space/syndicate/black/med = /obj/item/clothing/head/helmet/space/syndicate/black/med,
	/obj/item/clothing/suit/space/syndicate/black/engie = /obj/item/clothing/head/helmet/space/syndicate/black/engie,
))

/obj/item/clothing/suit/space/syndicate
	name = "red space suit"
	icon_state = "syndicate"
	inhand_icon_state = "space_suit_syndicate"
	desc = "Has a tag on it: Totally not property of an enemy corporation, honest!"
	w_class = WEIGHT_CLASS_NORMAL
	allowed = list(/obj/item/gun, /obj/item/melee/baton, /obj/item/melee/energy/sword/saber, /obj/item/restraints/handcuffs, /obj/item/tank/internals)
	armor_type = /datum/armor/space_syndicate
	cell = /obj/item/stock_parts/power_store/cell/hyper
	var/helmet_type = /obj/item/clothing/head/helmet/space/syndicate

//Green syndicate space suit
/obj/item/clothing/head/helmet/space/syndicate/green
	name = "green space helmet"
	icon_state = "syndicate-helm-green"
	inhand_icon_state = "space_helmet_syndicate"

/obj/item/clothing/suit/space/syndicate/green
	name = "green space suit"
	icon_state = "syndicate-green"
	inhand_icon_state = "syndicate-green"
	helmet_type = /obj/item/clothing/head/helmet/space/syndicate/green


//Dark green syndicate space suit
/obj/item/clothing/head/helmet/space/syndicate/green/dark
	name = "dark green space helmet"
	icon_state = "syndicate-helm-green-dark"
	inhand_icon_state = "syndicate-helm-green-dark"

/obj/item/clothing/suit/space/syndicate/green/dark
	name = "dark green space suit"
	icon_state = "syndicate-green-dark"
	inhand_icon_state = "syndicate-green-dark"
	helmet_type = /obj/item/clothing/head/helmet/space/syndicate/green/dark


//Orange syndicate space suit
/obj/item/clothing/head/helmet/space/syndicate/orange
	name = "orange space helmet"
	icon_state = "syndicate-helm-orange"
	inhand_icon_state = "syndicate-helm-orange"

/obj/item/clothing/suit/space/syndicate/orange
	name = "orange space suit"
	icon_state = "syndicate-orange"
	inhand_icon_state = "syndicate-orange"
	helmet_type = /obj/item/clothing/head/helmet/space/syndicate/orange

//Blue syndicate space suit
/obj/item/clothing/head/helmet/space/syndicate/blue
	name = "blue space helmet"
	icon_state = "syndicate-helm-blue"
	inhand_icon_state = "syndicate-helm-blue"

/obj/item/clothing/suit/space/syndicate/blue
	name = "blue space suit"
	icon_state = "syndicate-blue"
	inhand_icon_state = "syndicate-blue"
	helmet_type = /obj/item/clothing/head/helmet/space/syndicate/blue


//Black syndicate space suit
/obj/item/clothing/head/helmet/space/syndicate/black
	name = "black space helmet"
	icon_state = "syndicate-helm-black"
	inhand_icon_state = "syndicate-helm-black"

/obj/item/clothing/suit/space/syndicate/black
	name = "black space suit"
	icon_state = "syndicate-black"
	inhand_icon_state = "syndicate-black"
	helmet_type = /obj/item/clothing/head/helmet/space/syndicate/black


//Black-green syndicate space suit
/obj/item/clothing/head/helmet/space/syndicate/black/green
	name = "black space helmet"
	icon_state = "syndicate-helm-black-green"
	inhand_icon_state = "syndicate-helm-black-green"

/obj/item/clothing/suit/space/syndicate/black/green
	name = "black and green space suit"
	icon_state = "syndicate-black-green"
	inhand_icon_state = "syndicate-black-green"
	helmet_type = /obj/item/clothing/head/helmet/space/syndicate/black/green


//Black-blue syndicate space suit
/obj/item/clothing/head/helmet/space/syndicate/black/blue
	name = "black space helmet"
	icon_state = "syndicate-helm-black-blue"
	inhand_icon_state = "syndicate-helm-black-blue"

/obj/item/clothing/suit/space/syndicate/black/blue
	name = "black and blue space suit"
	icon_state = "syndicate-black-blue"
	inhand_icon_state = "syndicate-black-blue"
	helmet_type = /obj/item/clothing/head/helmet/space/syndicate/black/blue

//Black and white syndicate space suit without the medical iconography
/obj/item/clothing/suit/space/syndicate/black/white
	name = "black and white space suit"
	icon_state = "syndicate-black-white"
	inhand_icon_state = "syndicate-black"
	helmet_type = /obj/item/clothing/head/helmet/space/syndicate/black


//Black medical syndicate space suit
/obj/item/clothing/head/helmet/space/syndicate/black/med
	name = "black medical space helmet"
	icon_state = "syndicate-helm-black-med"
	inhand_icon_state = "syndicate-helm-black"

/obj/item/clothing/suit/space/syndicate/black/med
	name = "black medical space suit"
	icon_state = "syndicate-black-med"
	inhand_icon_state = "syndicate-black"
	helmet_type = /obj/item/clothing/head/helmet/space/syndicate/black/med


//Black-orange syndicate space suit
/obj/item/clothing/head/helmet/space/syndicate/black/orange
	name = "black space helmet"
	icon_state = "syndicate-helm-black-orange"
	inhand_icon_state = "syndicate-helm-black"

/obj/item/clothing/suit/space/syndicate/black/orange
	name = "black and orange space suit"
	icon_state = "syndicate-black-orange"
	inhand_icon_state = "syndicate-black"
	helmet_type = /obj/item/clothing/head/helmet/space/syndicate/black/orange


//Black-red syndicate space suit
/obj/item/clothing/head/helmet/space/syndicate/black/red
	name = "black space helmet"
	icon_state = "syndicate-helm-black-red"
	inhand_icon_state = "syndicate-helm-black-red"

/obj/item/clothing/suit/space/syndicate/black/red
	name = "black and red space suit"
	icon_state = "syndicate-black-red"
	inhand_icon_state = "syndicate-black-red"
	helmet_type = /obj/item/clothing/head/helmet/space/syndicate/black/red

//Black-red syndicate contract varient
/obj/item/clothing/head/helmet/space/syndicate/contract
	name = "contractor helmet"
	desc = "A specialised black and gold helmet that's more compact than its standard Syndicate counterpart. Can be ultra-compressed into even the tightest of spaces."
	w_class = WEIGHT_CLASS_SMALL
	icon_state = "syndicate-contract-helm"
	inhand_icon_state = "contractor_helmet"
	visor_dirt = null

/obj/item/clothing/suit/space/syndicate/contract
	name = "contractor space suit"
	desc = "A specialised black and gold space suit that's quicker, and more compact than its standard Syndicate counterpart. Can be ultra-compressed into even the tightest of spaces."
	slowdown = 1
	w_class = WEIGHT_CLASS_SMALL
	icon_state = "syndicate-contract"
	inhand_icon_state = null
	helmet_type = /obj/item/clothing/head/helmet/space/syndicate/contract

//Black with yellow/red engineering syndicate space suit
/obj/item/clothing/head/helmet/space/syndicate/black/engie
	name = "black engineering space helmet"
	icon_state = "syndicate-helm-black-engie"
	inhand_icon_state = "syndicate-helm-black"

/obj/item/clothing/suit/space/syndicate/black/engie
	name = "black engineering space suit"
	icon_state = "syndicate-black-engie"
	inhand_icon_state = "syndicate-black"
	helmet_type = /obj/item/clothing/head/helmet/space/syndicate/black/engie
