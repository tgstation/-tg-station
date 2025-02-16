/// Pocket items (Moved to backpack)
/datum/loadout_category/pocket
	category_name = "Other"
	category_ui_icon = FA_ICON_QUESTION
	type_to_generate = /datum/loadout_item/pocket_items
	tab_order = /datum/loadout_category/head::tab_order + 5
	/// How many pocket items are allowed
	VAR_PRIVATE/max_allowed = 2

/datum/loadout_category/pocket/New()
	. = ..()
	category_info = "([max_allowed] allowed)"

/datum/loadout_category/pocket/handle_duplicate_entires(
	datum/preference_middleware/loadout/manager,
	datum/loadout_item/conflicting_item,
	datum/loadout_item/added_item,
	list/datum/loadout_item/all_loadout_items,
)
	var/list/datum/loadout_item/pocket_items/other_pocket_items = list()
	for(var/datum/loadout_item/pocket_items/other_pocket_item in all_loadout_items)
		other_pocket_items += other_pocket_item

	if(length(other_pocket_items) >= max_allowed)
		// We only need to deselect something if we're above the limit
		// (And if we are we prioritize the first item found, FIFO)
		manager.deselect_item(other_pocket_items[1])
	return TRUE

/datum/loadout_item/pocket_items
	abstract_type = /datum/loadout_item/pocket_items

/datum/loadout_item/pocket_items/on_equip_item(
	obj/item/equipped_item,
	datum/preferences/preference_source,
	list/preference_list,
	mob/living/carbon/human/equipper,
	visuals_only = FALSE,
)
	// Backpack items aren't created if it's a visual equipping, so don't do any on equip stuff. It doesn't exist.
	if(visuals_only)
		return NONE

	return ..()

/datum/loadout_item/pocket_items/lipstick_black
	name = "Lipstick (Black)"
	item_path = /obj/item/lipstick/black
	additional_displayed_text = list("Black")

/datum/loadout_item/pocket_items/lipstick_blue
	name = "Lipstick (Blue)"
	item_path = /obj/item/lipstick/blue
	additional_displayed_text = list("Blue")

/datum/loadout_item/pocket_items/lipstick_green
	name = "Lipstick (Green)"
	item_path = /obj/item/lipstick/green
	additional_displayed_text = list("Green")

/datum/loadout_item/pocket_items/lipstick_jade
	name = "Lipstick (Jade)"
	item_path = /obj/item/lipstick/jade
	additional_displayed_text = list("Jade")

/datum/loadout_item/pocket_items/lipstick_purple
	name = "Lipstick (Purple)"
	item_path = /obj/item/lipstick/purple
	additional_displayed_text = list("Purple")

/datum/loadout_item/pocket_items/lipstick_red
	name = "Lipstick (Red)"
	item_path = /obj/item/lipstick
	additional_displayed_text = list("Red")

/datum/loadout_item/pocket_items/lipstick_white
	name = "Lipstick (White)"
	item_path = /obj/item/lipstick/white
	additional_displayed_text = list("White")

/datum/loadout_item/pocket_items/plush
	abstract_type = /datum/loadout_item/pocket_items/plush
	can_be_named = TRUE

/datum/loadout_item/pocket_items/plush/bee
	name = "Plush (Bee)"
	item_path = /obj/item/toy/plush/beeplushie

/datum/loadout_item/pocket_items/plush/carp
	name = "Plush (Carp)"
	item_path = /obj/item/toy/plush/carpplushie

/datum/loadout_item/pocket_items/plush/lizard_greyscale
	name = "Plush (Lizard, Colorable)"
	item_path = /obj/item/toy/plush/lizard_plushie/greyscale

/datum/loadout_item/pocket_items/plush/lizard_random
	name = "Plush (Lizard, Random)"
	can_be_greyscale = DONT_GREYSCALE
	item_path = /obj/item/toy/plush/lizard_plushie
	additional_displayed_text = list("Random color")

/datum/loadout_item/pocket_items/plush/moth
	name = "Plush (Moth)"
	item_path = /obj/item/toy/plush/moth

/datum/loadout_item/pocket_items/plush/nukie
	name = "Plush (Nukie)"
	item_path = /obj/item/toy/plush/nukeplushie

/datum/loadout_item/pocket_items/plush/peacekeeper
	name = "Plush (Peacekeeper)"
	item_path = /obj/item/toy/plush/pkplush

/datum/loadout_item/pocket_items/plush/plasmaman
	name = "Plush (Plasmaman)"
	item_path = /obj/item/toy/plush/plasmamanplushie

/datum/loadout_item/pocket_items/plush/rouny
	name = "Plush (Rouny)"
	item_path = /obj/item/toy/plush/rouny

/datum/loadout_item/pocket_items/plush/snake
	name = "Plush (Snake)"
	item_path = /obj/item/toy/plush/snakeplushie

/datum/loadout_item/pocket_items/card_binder
	name = "Card Binder"
	item_path = /obj/item/storage/card_binder

/datum/loadout_item/pocket_items/card_deck
	name = "Playing Card Deck"
	item_path = /obj/item/toy/cards/deck

/datum/loadout_item/pocket_items/kotahi_deck
	name = "Kotahi Deck"
	item_path = /obj/item/toy/cards/deck/kotahi

/datum/loadout_item/pocket_items/wizoff_deck
	name = "Wizoff Deck"
	item_path = /obj/item/toy/cards/deck/wizoff

/datum/loadout_item/pocket_items/dice_bag
	name = "Dice Bag"
	item_path = /obj/item/storage/dice

/datum/loadout_item/pocket_items/d1
	name = "D1"
	item_path = /obj/item/dice/d1

/datum/loadout_item/pocket_items/d2
	name = "D2"
	item_path = /obj/item/dice/d2

/datum/loadout_item/pocket_items/d4
	name = "D4"
	item_path = /obj/item/dice/d4

/datum/loadout_item/pocket_items/d6
	name = "D6"
	item_path = /obj/item/dice/d6

/datum/loadout_item/pocket_items/d6_ebony
	name = "D6 (Ebony)"
	item_path = /obj/item/dice/d6/ebony

/datum/loadout_item/pocket_items/d6_space
	name = "D6 (Space)"
	item_path = /obj/item/dice/d6/space

/datum/loadout_item/pocket_items/d8
	name = "D8"
	item_path = /obj/item/dice/d8

/datum/loadout_item/pocket_items/d10
	name = "D10"
	item_path = /obj/item/dice/d10

/datum/loadout_item/pocket_items/d12
	name = "D12"
	item_path = /obj/item/dice/d12

/datum/loadout_item/pocket_items/d20
	name = "D20"
	item_path = /obj/item/dice/d20

/datum/loadout_item/pocket_items/d100
	name = "D100"
	item_path = /obj/item/dice/d100

/datum/loadout_item/pocket_items/d00
	name = "D00"
	item_path = /obj/item/dice/d00

/datum/loadout_item/pocket_items/lighter
	name = "Zippo Lighter"
	item_path = /obj/item/lighter

/datum/loadout_item/pocket_items/flask
	name = "Pocket Flask"
	item_path = /obj/item/reagent_containers/cup/glass/flask

/datum/loadout_item/pocket_items/clipboard
	name = "Clipboard"
	item_path = /obj/item/clipboard

/datum/loadout_item/pocket_items/dye
	name = "Hair Dye"
	item_path = /obj/item/dyespray

/datum/loadout_item/pocket_items/poster
	name = "Poster (Contraband)"
	item_path = /obj/item/poster/random_contraband

/datum/loadout_item/pocket_items/poster_pinup
	name = "Poster (Pinup)"
	item_path = /obj/item/poster/random_contraband/pinup

/datum/loadout_item/pocket_items/wallet
	name = "Wallet"
	item_path = /obj/item/storage/wallet
