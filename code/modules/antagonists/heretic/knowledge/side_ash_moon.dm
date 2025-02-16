/datum/heretic_knowledge_tree_column/ash_to_moon
	neighbour_type_left = /datum/heretic_knowledge_tree_column/main/ash
	neighbour_type_right = /datum/heretic_knowledge_tree_column/main/moon

	route = PATH_SIDE

	tier1 = /datum/heretic_knowledge/medallion
	tier2 = /datum/heretic_knowledge/ether
	tier3 = /datum/heretic_knowledge/summon/ashy

// Sidepaths for knowledge between Ash and Flesh.
/datum/heretic_knowledge/medallion
	name = "Ashen Eyes"
	desc = "Allows you to transmute a pair of eyes, a candle, and a glass shard into an Eldritch Medallion. \
		The Eldritch Medallion grants you thermal vision while worn, and also functions as a focus."
	gain_text = "Piercing eyes guided them through the mundane. Neither darkness nor terror could stop them."

	required_atoms = list(
		/obj/item/organ/eyes = 1,
		/obj/item/shard = 1,
		/obj/item/flashlight/flare/candle = 1,
	)
	result_atoms = list(/obj/item/clothing/neck/eldritch_amulet)
	cost = 1
	research_tree_icon_path = 'icons/obj/antags/eldritch.dmi'
	research_tree_icon_state = "eye_medalion"

/datum/heretic_knowledge/ether
	name = "Ether Of The Newborn"
	desc = "Conjures a single use potion, drinking it will remove any sort of abnormality from your body including diseases, traumas and implants \
		on top of restoring it to full health, at the cost of losing consciousness for an entire minute."
	gain_text = "Vision and thought grow hazy as the fumes of this ichor swirl up to meet me. \
		Through the haze, I find myself staring back in relief, or something grossly resembling my visage. \
		It is this wretched thing that I consign to my fate, and whose own that I snatch through the haze of dreams. Fools that we are."
	required_atoms = list(
		/obj/item/shard = 1,
		/obj/effect/decal/cleanable/vomit = 1,
	)
	result_atoms = list(/obj/item/ether)
	cost = 1
	research_tree_icon_path = 'icons/obj/antags/eldritch.dmi'
	research_tree_icon_state = "poison_flask"

/datum/heretic_knowledge/summon/ashy
	name = "Ashen Ritual"
	desc = "Allows you to transmute a head, a pile of ash, and a book to create an Ash Spirit. \
		Ash Spirits have a short range jaunt and the ability to cause bleeding in foes at range. \
		They also have the ability to create a ring of fire around themselves for a length of time."
	gain_text = "I combined my principle of hunger with my desire for destruction. The Marshal knew my name, and the Nightwatcher gazed on."

	required_atoms = list(
		/obj/effect/decal/cleanable/ash = 1,
		/obj/item/bodypart/head = 1,
		/obj/item/book = 1,
		)
	mob_to_summon = /mob/living/basic/heretic_summon/ash_spirit
	cost = 1

	poll_ignore_define = POLL_IGNORE_ASH_SPIRIT

