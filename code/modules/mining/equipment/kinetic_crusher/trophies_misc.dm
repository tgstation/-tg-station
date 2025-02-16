/*!
 * Contains crusher trophies that are not obtained from fauna
 */

//cosmetic items for changing the crusher's look

/obj/item/crusher_trophy/retool_kit
	name = "crusher sword retool kit"
	desc = "A toolkit for changing the crusher's appearance without affecting the device's function. This one will make it look like a sword."
	icon = 'icons/obj/mining.dmi'
	icon_state = "retool_kit"
	denied_type = /obj/item/crusher_trophy/retool_kit
	/// Specifies the icon file in which the crusher's new state is stored.
	var/retool_icon = 'icons/obj/mining.dmi'
	///Specifies the sprite/icon state which the crusher is changed to as an item. Should appear in the icons/obj/mining.dmi file with accompanying "lit" and "recharging" sprites
	var/retool_icon_state = "crusher_sword"
	///Specifies the icon state for the crusher's appearance in hand. Should appear in both retool_lefthand_file and retool_righthand_file, which are icons/mob/inhands/weapons/hammers_lefthand.dmi and icons/mob/inhands/weapons/hammers_righthand.dmi by default.
	var/retool_inhand_icon = "crusher_sword"
	///For if the retool kit changes the projectile's appearance. The sprite should be in icons/obj/weapons/guns/projectiles.dmi
	var/retool_projectile_icon = "pulse1"
	/// Specifies the left hand inhand icon file. If both this and retool_righthand_file are set, changes the inhand files and dimensions as appropriate.
	var/retool_lefthand_file = 'icons/mob/inhands/weapons/hammers_lefthand.dmi'
	/// Specifies the right hand inhand icon file. If both this and retool_lefthand_file are set, changes the inhand files and dimensions as appropriate.
	var/retool_righthand_file = 'icons/mob/inhands/weapons/hammers_righthand.dmi'
	/// Specifies the X dimensions of the new inhand, only relevant with different inhand files.
	var/retool_inhand_X = 32
	/// Specifies the Y dimensions of the new inhand, only relevant with different inhand files.
	var/retool_inhand_Y = 32

/obj/item/crusher_trophy/retool_kit/effect_desc()
	return "the crusher to have the appearance of a sword"

/obj/item/crusher_trophy/retool_kit/add_to(obj/item/kinetic_crusher/pkc, mob/user)
	. = ..()
	if(.)
		pkc.icon = retool_icon
		pkc.icon_state = retool_icon_state
		pkc.current_inhand_icon_state = retool_inhand_icon
		pkc.projectile_icon = retool_projectile_icon
		pkc.inhand_x_dimension = retool_inhand_X
		pkc.inhand_y_dimension = retool_inhand_Y
		pkc.update_appearance()
		if(iscarbon(pkc.loc))
			var/mob/living/carbon/holder = pkc.loc
			holder.update_worn_back()
			holder.update_suit_storage()
			holder.update_held_items()

/obj/item/crusher_trophy/retool_kit/remove_from(obj/item/kinetic_crusher/pkc)
	pkc.icon = initial(pkc.icon)
	pkc.icon_state = initial(pkc.icon_state)
	pkc.current_inhand_icon_state = initial(pkc.current_inhand_icon_state)
	pkc.projectile_icon = initial(pkc.projectile_icon)
	pkc.lefthand_file = initial(pkc.lefthand_file)
	pkc.righthand_file = initial(pkc.righthand_file)
	pkc.inhand_x_dimension = initial(pkc.inhand_x_dimension)
	pkc.inhand_y_dimension = initial(pkc.inhand_y_dimension)
	pkc.update_appearance()
	if(iscarbon(pkc.loc))
		var/mob/living/carbon/holder = pkc.loc
		holder.update_worn_back()
		holder.update_suit_storage()
		holder.update_held_items()
	..()

/obj/item/crusher_trophy/retool_kit/harpoon
	name = "crusher harpoon retool kit"
	desc = "A toolkit for changing the crusher's appearance without affecting the device's function. This one will make it look like a harpoon."
	retool_icon = "crusher_harpoon"
	retool_inhand_icon = "crusher_harpoon"
	retool_projectile_icon = "pulse_harpoon"

/obj/item/crusher_trophy/retool_kit/harpoon/effect_desc()
	return "the crusher to have the appearance of a harpoon"

/obj/item/crusher_trophy/retool_kit/dagger
	name = "crusher dagger retool kit"
	desc = "A toolkit for changing the crusher's appearance without affecting the device's function. This one will make it look like a dual dagger and mini-blaster on a chain."
	retool_icon = "crusher_dagger"
	retool_inhand_icon = "crusher_dagger"

/obj/item/crusher_trophy/retool_kit/dagger/effect_desc()
	return "the crusher to have the appearance of a dual dagger and blaster"

/obj/item/crusher_trophy/retool_kit/glaive
	name = "crusher glaive retool kit"
	desc = "A toolkit for changing the crusher's appearance without affecting the device's function. This one will make it look like a glaive, with a longer, thinner blade."
	retool_icon = "crusher_glaive"
	retool_inhand_icon = "crusher_glaive"
	retool_lefthand_file = 'icons/mob/inhands/64x64_lefthand.dmi'
	retool_righthand_file = 'icons/mob/inhands/64x64_righthand.dmi'
	retool_inhand_X = 64
	retool_inhand_Y = 64

/obj/item/crusher_trophy/retool_kit/glaive/effect_desc()
	return "the crusher to have the appearance of a glaive"

/obj/item/crusher_trophy/retool_kit/ashenskull
	name = "ashen skull"
	desc = "It burns with the flame of the necropolis, whispering in your ear. It demands to be bound to a suitable weapon."
	icon_state = "retool_kit_skull"
	retool_icon = "crusher_skull"
	retool_inhand_icon = "crusher_skull"
	retool_projectile_icon = "pulse_skull"

/obj/item/crusher_trophy/retool_kit/ashenskull/effect_desc()
	return "the crusher to appear corrupted by infernal powers"
