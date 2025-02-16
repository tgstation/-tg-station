/// Shoe Slot Items (Deletes overrided items)
/datum/loadout_category/shoes
	category_name = "Shoes"
	category_ui_icon = FA_ICON_SHOE_PRINTS
	type_to_generate = /datum/loadout_item/shoes
	tab_order = 1

/datum/loadout_item/shoes
	abstract_type = /datum/loadout_item/shoes

/datum/loadout_item/shoes/insert_path_into_outfit(datum/outfit/outfit, mob/living/carbon/human/equipper, visuals_only = FALSE)
	outfit.shoes = item_path

/datum/loadout_item/shoes/sneakers
	name = "Sneakers (Colourable)"
	item_path = /obj/item/clothing/shoes/sneakers

/datum/loadout_item/shoes/sandals_laced
	name = "Sandals (Laced)"
	item_path = /obj/item/clothing/shoes/sandal/laced

/datum/loadout_item/shoes/sandals_laced_black
	name = "Sandals (Black, Laced)"
	item_path = /obj/item/clothing/shoes/sandal/alt/laced

/datum/loadout_item/shoes/laceup
	name = "Shoes (Laceup)"
	item_path = /obj/item/clothing/shoes/laceup

/datum/loadout_item/shoes/cowboy_brown
	name = "Boots (Cowboy, Brown)"
	item_path = /obj/item/clothing/shoes/cowboy/laced

/datum/loadout_item/shoes/cowboy_white
	name = "Boots (Cowboy, White)"
	item_path = /obj/item/clothing/shoes/cowboy/white/laced

/datum/loadout_item/shoes/cowboy_black
	name = "Boots (Cowboy, Black)"
	item_path = /obj/item/clothing/shoes/cowboy/black/laced

/datum/loadout_item/shoes/glow_shoes
	name = "Shoes (Glowing, Colourable)"
	item_path = /obj/item/clothing/shoes/glow
