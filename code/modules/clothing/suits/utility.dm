/*
 * Contains:
 * Fire protection
 * Bomb protection
 * Radiation protection
 */

/*
 * Fire protection
 */

/obj/item/clothing/suit/utility
	icon = 'icons/obj/clothing/suits/utility.dmi'
	worn_icon = 'icons/mob/clothing/suits/utility.dmi'

/obj/item/clothing/suit/utility/fire
	name = "emergency firesuit"
	desc = "A suit that helps protect against fire and heat."
	icon_state = "fire"
	inhand_icon_state = "ro_suit"
	w_class = WEIGHT_CLASS_BULKY
	body_parts_covered = CHEST|GROIN|LEGS|FEET|ARMS|HANDS
	allowed = list(
		/obj/item/crowbar,
		/obj/item/extinguisher,
		/obj/item/flashlight,
		/obj/item/fireaxe/metal_h2_axe,
		/obj/item/tank/internals,
	)
	slowdown = 1
	armor_type = /datum/armor/utility_fire
	flags_inv = HIDEGLOVES|HIDESHOES|HIDEJUMPSUIT
	clothing_flags = STOPSPRESSUREDAMAGE | THICKMATERIAL
	heat_protection = CHEST|GROIN|LEGS|FEET|ARMS|HANDS
	max_heat_protection_temperature = FIRE_SUIT_MAX_TEMP_PROTECT
	cold_protection = CHEST|GROIN|LEGS|FEET|ARMS|HANDS
	min_cold_protection_temperature = FIRE_SUIT_MIN_TEMP_PROTECT
	strip_delay = 60
	equip_delay_other = 60
	resistance_flags = FIRE_PROOF

/obj/item/clothing/suit/utility/fire/Initialize(mapload)
	. = ..()
	AddComponent(/datum/component/adjust_fishing_difficulty, 7)

/datum/armor/utility_fire
	melee = 15
	bullet = 5
	laser = 20
	energy = 20
	bomb = 20
	bio = 50
	fire = 100
	acid = 50

/obj/item/clothing/suit/utility/fire/worn_overlays(mutable_appearance/standing, isinhands, icon_file)
	. = ..()
	if(!isinhands)
		. += emissive_appearance(icon_file, "[icon_state]-emissive", src, alpha = src.alpha)

/obj/item/clothing/suit/utility/fire/firefighter
	icon_state = "firesuit"
	inhand_icon_state = "firefighter"
	flags_inv = HIDESHOES|HIDEJUMPSUIT
	heat_protection = CHEST|GROIN|LEGS|FEET|ARMS
	cold_protection = CHEST|GROIN|LEGS|FEET|ARMS
	body_parts_covered = CHEST|GROIN|LEGS|FEET|ARMS

/obj/item/clothing/suit/utility/fire/heavy
	name = "heavy firesuit"
	desc = "An old, bulky thermal protection suit."
	icon_state = "thermal"
	inhand_icon_state = "ro_suit"
	slowdown = 1.5

/obj/item/clothing/suit/utility/fire/atmos
	name = "atmospheric firesuit"
	desc = "An expensive firesuit that protects against even the most deadly of station fires. Designed to protect even if the wearer is set aflame."
	icon_state = "atmos_firesuit"
	inhand_icon_state = "firefighter_atmos"
	max_heat_protection_temperature = FIRE_IMMUNITY_MAX_TEMP_PROTECT
	heat_protection = CHEST|GROIN|LEGS|FEET|ARMS
	cold_protection = CHEST|GROIN|LEGS|FEET|ARMS
	body_parts_covered = CHEST|GROIN|LEGS|FEET|ARMS
	flags_inv = HIDESHOES|HIDEJUMPSUIT

/*
 * Bomb protection
 */
/obj/item/clothing/head/utility/bomb_hood
	name = "bomb hood"
	desc = "Use in case of bomb."
	icon_state = "bombsuit"
	clothing_flags = THICKMATERIAL | SNUG_FIT
	armor_type = /datum/armor/utility_bomb_hood
	flags_inv = HIDEFACE|HIDEMASK|HIDEEARS|HIDEEYES|HIDEHAIR|HIDEFACIALHAIR|HIDESNOUT

	cold_protection = HEAD
	min_cold_protection_temperature = HELMET_MIN_TEMP_PROTECT
	heat_protection = HEAD
	max_heat_protection_temperature = HELMET_MAX_TEMP_PROTECT
	strip_delay = 70
	equip_delay_other = 70
	flags_cover = HEADCOVERSEYES | HEADCOVERSMOUTH | PEPPERPROOF
	resistance_flags = NONE

/obj/item/clothing/head/utility/bomb_hood/Initialize(mapload)
	. = ..()
	AddComponent(/datum/component/clothing_dirt, "bomb_dirt")
	AddComponent(/datum/component/adjust_fishing_difficulty, 8)
	AddComponent(/datum/component/hat_stabilizer, loose_hat = TRUE)

/datum/armor/utility_bomb_hood
	melee = 20
	laser = 20
	energy = 30
	bomb = 100
	bio = 50
	fire = 80
	acid = 50

/obj/item/clothing/suit/utility/bomb_suit
	name = "bomb suit"
	desc = "A suit designed for safety when handling explosives."
	icon_state = "bombsuit"
	inhand_icon_state = null
	w_class = WEIGHT_CLASS_BULKY
	clothing_flags = THICKMATERIAL
	body_parts_covered = CHEST|GROIN|LEGS|FEET|ARMS|HANDS
	slowdown = 2
	armor_type = /datum/armor/utility_bomb_suit
	flags_inv = HIDEJUMPSUIT
	heat_protection = CHEST|GROIN|LEGS|FEET|ARMS|HANDS
	max_heat_protection_temperature = ARMOR_MAX_TEMP_PROTECT
	cold_protection = CHEST|GROIN|LEGS|FEET|ARMS|HANDS
	min_cold_protection_temperature = ARMOR_MIN_TEMP_PROTECT
	strip_delay = 70
	equip_delay_other = 70
	resistance_flags = NONE

/obj/item/clothing/suit/utility/bomb_suit/Initialize(mapload)
	. = ..()
	AddComponent(/datum/component/adjust_fishing_difficulty, 8)

/datum/armor/utility_bomb_suit
	melee = 20
	laser = 20
	energy = 30
	bomb = 100
	bio = 50
	fire = 80
	acid = 50

/obj/item/clothing/head/utility/bomb_hood/security
	icon_state = "bombsuit_sec"
	inhand_icon_state = null

/obj/item/clothing/suit/utility/bomb_suit/security
	icon_state = "bombsuit_sec"
	inhand_icon_state = null
	allowed = list(/obj/item/gun/energy, /obj/item/melee/baton, /obj/item/restraints/handcuffs)

/obj/item/clothing/head/utility/bomb_hood/white
	icon_state = "bombsuit_white"
	inhand_icon_state = null

/obj/item/clothing/suit/utility/bomb_suit/white
	icon_state = "bombsuit_white"
	inhand_icon_state = null

/*
* Radiation protection
*/

/obj/item/clothing/head/utility/radiation
	name = "radiation hood"
	icon_state = "rad"
	desc = "A hood with radiation protective properties. The label reads, 'Made with lead. Please do not consume insulation.'"
	clothing_flags = THICKMATERIAL | SNUG_FIT
	flags_inv = HIDEMASK|HIDEEARS|HIDEFACE|HIDEEYES|HIDEHAIR|HIDEFACIALHAIR|HIDESNOUT
	armor_type = /datum/armor/utility_radiation
	strip_delay = 60
	equip_delay_other = 60
	flags_cover = HEADCOVERSEYES | HEADCOVERSMOUTH | PEPPERPROOF
	resistance_flags = NONE

/obj/item/clothing/head/utility/radiation/Initialize(mapload)
	. = ..()
	AddComponent(/datum/component/adjust_fishing_difficulty, 7)
	AddComponent(/datum/component/hat_stabilizer, loose_hat = TRUE)
	AddElement(/datum/element/radiation_protected_clothing)
	AddComponent(/datum/component/clothing_dirt, "rad_dirt")

/datum/armor/utility_radiation
	bio = 60
	fire = 30
	acid = 30

/obj/item/clothing/suit/utility/radiation
	name = "radiation suit"
	desc = "A suit that protects against radiation. The label reads, 'Made with lead. Please do not consume insulation.'"
	icon_state = "rad"
	inhand_icon_state = "rad_suit"
	w_class = WEIGHT_CLASS_BULKY
	clothing_flags = THICKMATERIAL
	body_parts_covered = CHEST|GROIN|LEGS|FEET|ARMS|HANDS
	allowed = list(
		/obj/item/flashlight,
		/obj/item/geiger_counter,
		/obj/item/tank/internals,
		)
	slowdown = 1.5
	armor_type = /datum/armor/utility_radiation
	strip_delay = 60
	equip_delay_other = 60
	flags_inv = HIDEJUMPSUIT
	resistance_flags = NONE

/obj/item/clothing/suit/utility/radiation/Initialize(mapload)
	. = ..()
	AddElement(/datum/element/radiation_protected_clothing)
	AddComponent(/datum/component/adjust_fishing_difficulty, 7)
