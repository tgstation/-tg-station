/obj/item/clothing/head/helmet/space/beret
	name = "CentCom officer's beret"
	desc = "An armored beret commonly used by special operations officers. Uses advanced force field technology to protect the head from space."
	greyscale_config = /datum/greyscale_config/beret_badge
	greyscale_config_worn = /datum/greyscale_config/beret_badge/worn
	icon_state = "beret_badge"
	inhand_icon_state = null
	greyscale_colors = "#397F3F#FFCE5B"
	clothing_flags = STOPSPRESSUREDAMAGE | THICKMATERIAL | SNUG_FIT
	slowdown = 0
	flags_inv = 0
	armor_type = /datum/armor/space_beret
	strip_delay = 130
	max_heat_protection_temperature = FIRE_IMMUNITY_MAX_TEMP_PROTECT
	resistance_flags = FIRE_PROOF | ACID_PROOF
	fishing_modifier = 0
	hair_mask = HAIR_MASK_HIDE_ABOVE_45_DEG_MEDIUM
	visor_dirt = null

/datum/armor/space_beret
	melee = 80
	bullet = 80
	laser = 50
	energy = 60
	bomb = 100
	bio = 100
	fire = 100
	acid = 100
	wound = 15

/obj/item/clothing/suit/space/officer
	name = "CentCom officer's coat"
	desc = "An armored, space-proof coat used in special operations."
	icon_state = "centcom_coat"
	icon = 'icons/obj/clothing/suits/jacket.dmi'
	worn_icon = 'icons/mob/clothing/suits/jacket.dmi'
	inhand_icon_state = "centcom"
	blood_overlay_type = "coat"
	slowdown = 0
	flags_inv = 0
	w_class = WEIGHT_CLASS_NORMAL
	allowed = list(/obj/item/gun, /obj/item/melee/baton, /obj/item/restraints/handcuffs, /obj/item/tank/internals)
	armor_type = /datum/armor/space_officer
	strip_delay = 130
	max_heat_protection_temperature = FIRE_IMMUNITY_MAX_TEMP_PROTECT
	resistance_flags = FIRE_PROOF | ACID_PROOF
	fishing_modifier = 0

/datum/armor/space_officer
	melee = 80
	bullet = 80
	laser = 50
	energy = 60
	bomb = 100
	bio = 100
	fire = 100
	acid = 100
	wound = 15
