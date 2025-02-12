/datum/heretic_knowledge_tree_column/lock_to_flesh
	neighbour_type_left = /datum/heretic_knowledge_tree_column/main/lock
	neighbour_type_right = /datum/heretic_knowledge_tree_column/main/flesh

	route = PATH_SIDE

	tier1 = /datum/heretic_knowledge/phylactery
	tier2 = /datum/heretic_knowledge/spell/opening_blast
	tier3 = /datum/heretic_knowledge/spell/apetra_vulnera

/**
 * Phylactery of Damnation
 */
/datum/heretic_knowledge/phylactery
	name = "Phylactery of Damnation"
	desc = "Allows you to transmute a sheet of glass and a poppy into a Phylactery that can instantly draw blood, even from long distances. \
		Be warned, your target may still feel a prick."
	gain_text = "A tincture twisted into the shape of a bloodsucker vermin. \
		Whether it chose the shape for itself, or this is the humor of the sickened mind that conjured this vile implement into being is something best not pondered."
	required_atoms = list(
		/obj/item/stack/sheet/glass = 1,
		/obj/item/food/grown/poppy = 1,
	)
	result_atoms = list(/obj/item/reagent_containers/cup/phylactery)
	cost = 1
	research_tree_icon_path = 'icons/obj/antags/eldritch.dmi'
	research_tree_icon_state = "phylactery_2"

// Sidepaths for knowledge between Knock and Flesh.
/datum/heretic_knowledge/spell/opening_blast
	name = "Wave Of Desperation"
	desc = "Grants you Wave Of Desparation, a spell which can only be cast while restrained. \
		It removes your restraints, repels and knocks down adjacent people, and applies the Mansus Grasp to everything nearby. \
		However, you will fall unconscious a short time after casting this spell."
	gain_text = "My shackles undone in dark fury, their feeble bindings crumble before my power."

	action_to_add = /datum/action/cooldown/spell/aoe/wave_of_desperation
	cost = 1

/datum/heretic_knowledge/spell/apetra_vulnera
	name = "Apetra Vulnera"
	desc = "Grants you Apetra Vulnera, a spell \
		which causes heavy bleeding on all bodyparts of the victim that have more than 15 brute damage. \
		Wounds a random limb if no limb is sufficiently damaged."
	gain_text = "Flesh opens, and blood spills. My master seeks sacrifice, and I shall appease."

	action_to_add = /datum/action/cooldown/spell/pointed/apetra_vulnera
	cost = 1


