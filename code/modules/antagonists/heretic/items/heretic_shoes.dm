/obj/item/clothing/shoes/greaves_of_the_prophet
	name = "\improper Joint-snap sabatons"
	desc = "Sabatons made out of rugged, worn iron. Feels more stable than the ground they tread on. They're caked in a thin layer of rust - and yet, the sight of it fills you with odd relief."
	icon_state = "hereticgreaves"
	resistance_flags = ACID_PROOF | FIRE_PROOF | LAVA_PROOF

/obj/item/clothing/shoes/greaves_of_the_prophet/Initialize(mapload)
	. = ..()
	attach_clothing_traits(list(TRAIT_NO_SLIP_WATER, TRAIT_NO_SLIP_ICE, TRAIT_NO_SLIP_SLIDE, TRAIT_NO_SLIP_ALL))
