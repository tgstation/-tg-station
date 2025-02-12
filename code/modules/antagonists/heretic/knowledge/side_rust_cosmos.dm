/datum/heretic_knowledge_tree_column/rust_to_cosmic
	neighbour_type_left = /datum/heretic_knowledge_tree_column/main/rust
	neighbour_type_right = /datum/heretic_knowledge_tree_column/main/cosmic

	route = PATH_SIDE

	tier1 = /datum/heretic_knowledge/essence
	tier2 = list(/datum/heretic_knowledge/entropy_pulse, /datum/heretic_knowledge/rust_sower)
	tier3 = /datum/heretic_knowledge/summon/rusty


// Sidepaths for knowledge between Rust and Cosmos.

/datum/heretic_knowledge/essence
	name = "Priest's Ritual"
	desc = "Allows you to transmute a tank of water and a glass shard into a Flask of Eldritch Essence. \
		Eldritch Essence can be consumed for potent healing, or given to heathens for deadly poisoning."
	gain_text = "This is an old recipe. The Owl whispered it to me. \
		Created by the Priest - the Liquid that both was and is not."

	required_atoms = list(
		/obj/structure/reagent_dispensers/watertank = 1,
		/obj/item/shard = 1,
	)
	result_atoms = list(/obj/item/reagent_containers/cup/beaker/eldritch)
	cost = 1


	research_tree_icon_path = 'icons/obj/antags/eldritch.dmi'
	research_tree_icon_state = "eldritch_flask"

/datum/heretic_knowledge/rust_sower
	name = "Rust Sower Grenade"
	desc = "Conjures a cursed grenade filled with Eldritch Rust, upon detonating it releases a huge cloud that blinds organics, rusts affected turfs and obliterates Silicons and Mechs."
	gain_text = "The choked vines of the Rusted Hills are burdened with such overripe fruits. It undoes the markers of progress, leaving a clean slate to work into new shapes."
	required_atoms = list(
		/obj/item/grenade/chem_grenade = 1,
		/obj/item/organ/liver = 1,
	)
	result_atoms = list(/obj/item/grenade/chem_grenade/rust_sower)
	cost = 1
	research_tree_icon_path = 'icons/obj/weapons/grenade.dmi'
	research_tree_icon_state = "rustgrenade"

/datum/heretic_knowledge/entropy_pulse
	name = "Pulse of Entropy"
	desc = "Allows you to transmute 10 iron sheets and a garbage item to fill the surrounding vicinity of the rune with rust."
	gain_text = "Reality begins to whisper to me. To give it its entropic end."
	required_atoms = list(
		/obj/item/stack/sheet/iron = 10,
		/obj/item/trash = 1,
	)
	cost = 0

	research_tree_icon_path = 'icons/mob/actions/actions_ecult.dmi'
	research_tree_icon_state = "corrode"
	research_tree_icon_frame = 10

	var/rusting_range = 8

/datum/heretic_knowledge/entropy_pulse/on_finished_recipe(mob/living/user, list/selected_atoms, turf/loc)
	for(var/turf/nearby_turf in view(rusting_range, loc))
		if(get_dist(nearby_turf, loc) <= 1) //tiles on rune should always be rusted
			nearby_turf.rust_heretic_act()
		//we exclude closed turf to avoid exposing cultist bases
		if(prob(10) || isclosedturf(nearby_turf))
			continue
		nearby_turf.rust_heretic_act()
	return TRUE

/datum/heretic_knowledge/summon/rusty
	name = "Rusted Ritual"
	desc = "Allows you to transmute a pool of vomit, some cable coil, and 10 sheets of iron into a Rust Walker. \
		Rust Walkers excel at spreading rust and are moderately strong in combat."
	gain_text = "I combined my knowledge of creation with my desire for corruption. The Marshal knew my name, and the Rusted Hills echoed out."

	required_atoms = list(
		/obj/effect/decal/cleanable/vomit = 1,
		/obj/item/stack/sheet/iron = 10,
		/obj/item/stack/cable_coil = 15,
	)
	mob_to_summon = /mob/living/basic/heretic_summon/rust_walker
	cost = 1

	poll_ignore_define = POLL_IGNORE_RUST_SPIRIT


