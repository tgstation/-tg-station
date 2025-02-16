/datum/heretic_knowledge_tree_column/blade_to_rust
	neighbour_type_left = /datum/heretic_knowledge_tree_column/main/blade
	neighbour_type_right = /datum/heretic_knowledge_tree_column/main/rust

	route = PATH_SIDE

	tier1 = /datum/heretic_knowledge/armor
	tier2 = list(/datum/heretic_knowledge/crucible, /datum/heretic_knowledge/rifle)
	tier3 = list(/datum/heretic_knowledge/spell/rust_charge, /datum/heretic_knowledge/greaves_of_the_prophet)

// Sidepaths for knowledge between Rust and Blade.
/datum/heretic_knowledge/armor
	name = "Armorer's Ritual"
	desc = "Allows you to transmute a table and a gas mask to create Eldritch Armor. \
		Eldritch Armor provides great protection while also acting as a focus when hooded."
	gain_text = "The Rusted Hills welcomed the Blacksmith in their generosity. And the Blacksmith \
		returned their generosity in kind."

	required_atoms = list(
		/obj/structure/table = 1,
		/obj/item/clothing/mask/gas = 1,
	)
	result_atoms = list(/obj/item/clothing/suit/hooded/cultrobes/eldritch)
	cost = 1

	research_tree_icon_path = 'icons/obj/clothing/suits/armor.dmi'
	research_tree_icon_state = "eldritch_armor"
	research_tree_icon_frame = 12


/datum/heretic_knowledge/crucible
	name = "Mawed Crucible"
	desc = "Allows you to transmute a portable water tank and a table to create a Mawed Crucible. \
		The Mawed Crucible can brew powerful potions for combat and utility, but must be fed bodyparts and organs between uses."
	gain_text = "This is pure agony. I wasn't able to summon the figure of the Aristocrat, \
		but with the Priest's attention I stumbled upon a different recipe..."

	required_atoms = list(
		/obj/structure/reagent_dispensers/watertank = 1,
		/obj/structure/table = 1,
	)
	result_atoms = list(/obj/structure/destructible/eldritch_crucible)
	cost = 1

	research_tree_icon_path = 'icons/obj/antags/eldritch.dmi'
	research_tree_icon_state = "crucible"


/datum/heretic_knowledge/rifle
	name = "Lionhunter's Rifle"
	desc = "Allows you to transmute a piece of wood, with hide \
		from any animal,and a camera to create the Lionhunter's rifle. \
		The Lionhunter's Rifle is a long ranged ballistic weapon with three shots. \
		These shots function as normal, albeit weak high-caliber munitions when fired from \
		close range or at inanimate objects. You can aim the rifle at distant foes, \
		causing the shot to mark your victim with your grasp and teleport you directly to them."
	gain_text = "I met an old man in an antique shop who wielded a very unusual weapon. \
		I could not purchase it at the time, but they showed me how they made it ages ago."

	required_atoms = list(
		/obj/item/stack/sheet/mineral/wood = 1,
		/obj/item/stack/sheet/animalhide = 1,
		/obj/item/camera = 1,
	)
	result_atoms = list(/obj/item/gun/ballistic/rifle/lionhunter)
	cost = 1


	research_tree_icon_path = 'icons/obj/weapons/guns/ballistic.dmi'
	research_tree_icon_state = "goldrevolver"

/datum/heretic_knowledge/rifle_ammo
	name = "Lionhunter Rifle Ammunition"
	desc = "Allows you to transmute 3 ballistic ammo casings (used or unused) of any caliber, \
		including shotgun shells to create an extra clip of ammunition for the Lionhunter Rifle."
	gain_text = "The weapon came with three rough iron balls, intended to be used as ammunition. \
		They were very effective, for simple iron, but used up quickly. I soon ran out. \
		No replacement munitions worked in their stead. It was peculiar in what it wanted."
	required_atoms = list(
		/obj/item/ammo_casing = 3,
	)
	result_atoms = list(/obj/item/ammo_box/strilka310/lionhunter)
	cost = 0

	research_tree_icon_path = 'icons/obj/weapons/guns/ammo.dmi'
	research_tree_icon_state = "310_strip"

	/// A list of calibers that the ritual will deny. Only ballistic calibers are allowed.
	var/static/list/caliber_blacklist = list(
		CALIBER_LASER,
		CALIBER_ENERGY,
		CALIBER_FOAM,
		CALIBER_ARROW,
		CALIBER_HARPOON,
		CALIBER_HOOK,
	)

/datum/heretic_knowledge/rifle_ammo/recipe_snowflake_check(mob/living/user, list/atoms, list/selected_atoms, turf/loc)
	for(var/obj/item/ammo_casing/casing in atoms)
		if(!(casing.caliber in caliber_blacklist))
			continue

		// Remove any casings in the caliber_blacklist list from atoms
		atoms -= casing

	// We removed any invalid casings from the atoms list,
	// return to allow the ritual to fill out selected atoms with the new list
	return TRUE

/datum/heretic_knowledge/spell/rust_charge
	name = "Rust Charge"
	desc = "A charge that must be started on a rusted tile and will destroy any rusted objects you come into contact with, will deal high damage to others and rust around you during the charge."
	gain_text = "The hills sparkled now, as I neared them my mind began to wander. I quickly regained my resolve and pushed forward, this last leg would be the most treacherous."

	action_to_add = /datum/action/cooldown/mob_cooldown/charge/rust
	cost = 1

/datum/heretic_knowledge/greaves_of_the_prophet
	name = "Greaves Of The Prophet"
	desc = "Conjures a pair of Armored Greaves, they confer to the user fully immunity to slips and the ability resist gravity at will."
	gain_text = " \
		Gristle churns into joint, a pop, and the fool twists a blackened foot from the \
		jaws of another. At their game for centuries, this mangled tree of limbs twists, \
		thrashing snares buried into snarling gums, seeking to shred the weight of grafted \
		neighbors. Weighed down by lacerated feet, this canopy of rancid idiots ever seeks \
		the undoing of its own bonds. I dread the thought of walking in their wake, but \
		I must press on all the same. Their rhythms keep the feud fresh with indifference \
		to barrier or border. Pulling more into their turmoil as they waltz."
	cost = 1
	required_atoms = list(
		/obj/item/clothing/shoes/jackboots = 1,
		/obj/item/stack/sheet/mineral/titanium = 2,
	)
	result_atoms = list(/obj/item/clothing/shoes/greaves_of_the_prophet)
	research_tree_icon_path = 'icons/obj/clothing/shoes.dmi'
	research_tree_icon_state = "hereticgreaves"
