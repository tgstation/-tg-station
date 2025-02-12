/obj/item/ammo_box/magazine/m223
	name = "toploader magazine (.223)"
	desc = "A top-loading .223 magazine, suitable for the M-90gl carbine."
	icon_state = ".223"
	ammo_band_icon = "+.223ab"
	ammo_type = /obj/item/ammo_casing/a223
	caliber = CALIBER_A223
	max_ammo = 30
	multiple_sprites = AMMO_BOX_FULL_EMPTY

/obj/item/ammo_box/magazine/m223/phasic
	name = "toploader magazine (.223 Phasic)"
	desc = parent_type::desc + "<br>Carries phasic rounds, which completely ignore armor and phase through cover, but not targets."
	ammo_type = /obj/item/ammo_casing/a223/phasic

// .38 (Battle Rifle) //

/obj/item/ammo_box/magazine/m38
	name = "battle rifle magazine (.38)"
	desc = "A .38 magazine for a BR-38 battle rifle."
	icon_state = "38mag"
	base_icon_state = "38mag"
	w_class = WEIGHT_CLASS_NORMAL
	ammo_type = /obj/item/ammo_casing/c38
	caliber = CALIBER_38
	max_ammo = 15
	ammo_band_icon = "+38mag_ammo_band"
	ammo_band_color = null

/obj/item/ammo_box/magazine/m38/update_icon_state()
	. = ..()
	icon_state = "[base_icon_state][ammo_count() ? "-ammo" : ""]"

/obj/item/ammo_box/magazine/m38/empty
	start_empty = TRUE

/obj/item/ammo_box/magazine/m38/trac
	name = "battle rifle magazine (.38 TRAC)"
	desc = parent_type::desc + " TRAC bullets embed a tracking implant within the target's body and are entirely nonlethal."
	ammo_type = /obj/item/ammo_casing/c38/trac
	ammo_band_color = COLOR_AMMO_TRACK

/obj/item/ammo_box/magazine/m38/match
	name = "battle rifle magazine (.38 Match)"
	desc = parent_type::desc + " These rounds are manufactured within extremely tight tolerances, making them easy to show off trickshots with."
	ammo_type = /obj/item/ammo_casing/c38/match
	ammo_band_color = COLOR_AMMO_MATCH

/obj/item/ammo_box/magazine/m38/match/bouncy
	name = "battle rifle magazine (.38 Rubber)"
	desc = parent_type::desc + " These rounds are incredibly bouncy and MOSTLY nonlethal, making them great to show off trickshots with."
	ammo_type = /obj/item/ammo_casing/c38/match/bouncy
	ammo_band_color = COLOR_AMMO_RUBBER

/obj/item/ammo_box/magazine/m38/true
	name = "battle rifle magazine (.38 True Strike)"
	desc = parent_type::desc + " Bullets bounce towards new targets with surprising accuracy."
	ammo_type = /obj/item/ammo_casing/c38/match/true
	ammo_band_color = COLOR_AMMO_TRUESTRIKE

/obj/item/ammo_box/magazine/m38/dumdum
	name = "battle rifle magazine (.38 DumDum)"
	desc = parent_type::desc + " These rounds expand on impact, allowing them to shred the target and cause massive bleeding. Very weak against armor and distant targets."
	ammo_type = /obj/item/ammo_casing/c38/dumdum
	ammo_band_color = COLOR_AMMO_DUMDUM

/obj/item/ammo_box/magazine/m38/hotshot
	name = "battle rifle magazine (.38 Hot Shot)"
	desc = parent_type::desc + " Hot Shot bullets contain an incendiary payload."
	ammo_type = /obj/item/ammo_casing/c38/hotshot
	ammo_band_color = COLOR_AMMO_HOTSHOT

/obj/item/ammo_box/magazine/m38/iceblox
	name = "battle rifle magazine (.38 Iceblox)"
	desc = parent_type::desc + " Iceblox bullets contain a cryogenic payload."
	ammo_type = /obj/item/ammo_casing/c38/iceblox
	ammo_band_color = COLOR_AMMO_ICEBLOX
