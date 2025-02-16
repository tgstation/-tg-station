/obj/item/clothing/head/helmet/space/santahat
	name = "Santa's hat"
	desc = "Ho ho ho. Merrry X-mas!"
	icon = 'icons/obj/clothing/head/wizard.dmi'
	worn_icon = 'icons/mob/clothing/head/wizard.dmi'
	icon_state = "santahat"
	inhand_icon_state = "santahat"
	flags_cover = HEADCOVERSEYES
	dog_fashion = /datum/dog_fashion/head/santa
	fishing_modifier = 0
	visor_dirt = null

/obj/item/clothing/head/helmet/space/santahat/beardless
	icon = 'icons/obj/clothing/head/costume.dmi'
	worn_icon = 'icons/mob/clothing/head/costume.dmi'
	icon_state = "santahatnorm"
	inhand_icon_state = "that"
	flags_inv = NONE

/obj/item/clothing/suit/space/santa
	name = "Santa's suit"
	desc = "Festive!"
	icon_state = "santa"
	icon = 'icons/obj/clothing/suits/wizard.dmi'
	worn_icon = 'icons/mob/clothing/suits/wizard.dmi'
	inhand_icon_state = "santa"
	slowdown = 0
	allowed = list(/obj/item) //for stuffing exta special presents
	fishing_modifier = 0
