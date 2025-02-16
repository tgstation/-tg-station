// Atom x_act() procs signals. Format:
// When the signal is called: (signal arguments)
// All signals send the source datum of the signal as the first argument

///from the [EX_ACT] wrapper macro: (severity, target)
#define COMSIG_ATOM_PRE_EX_ACT "atom_pre_ex_act"
	/// if returned, don't let the explosion act on this atom
	#define COMPONENT_CANCEL_EX_ACT (1<<0)
///from the [EX_ACT] wrapper macro: (severity, target)
#define COMSIG_ATOM_EX_ACT "atom_ex_act"
///from base of atom/emp_act(severity): (severity). return EMP protection flags
#define COMSIG_ATOM_PRE_EMP_ACT "atom_emp_act"
///from base of atom/emp_act(severity): (severity, protection)
#define COMSIG_ATOM_EMP_ACT "atom_emp_act"
///from base of atom/fire_act(): (exposed_temperature, exposed_volume)
#define COMSIG_ATOM_FIRE_ACT "atom_fire_act"
///from base of atom/bullet_act(): (/obj/proj, def_zone, piercing_hit, blocked)
#define COMSIG_ATOM_PRE_BULLET_ACT "pre_atom_bullet_act"
	/// All this does is prevent default bullet on_hit from being called, [BULLET_ACT_HIT] being return is implied
	#define COMPONENT_BULLET_ACTED (1<<0)
	/// Forces bullet act to return [BULLET_ACT_BLOCK], takes priority over above
	#define COMPONENT_BULLET_BLOCKED (1<<1)
	/// Forces bullet act to return [BULLET_ACT_FORCE_PIERCE], takes priority over above
	#define COMPONENT_BULLET_PIERCED (1<<2)
///from base of atom/bullet_act(): (/obj/proj, def_zone, piercing_hit, blocked)
#define COMSIG_ATOM_BULLET_ACT "atom_bullet_act"
///from base of atom/on_craft_completion(): (components, datum/crafting_recipe/current_recipe)
#define COMSIG_ATOM_ON_CRAFT "atom_checkparts"
///from base of atom/used_in_craft(): (atom/result)
#define COMSIG_ATOM_USED_IN_CRAFT "atom_used_in_craft"
///from base of atom/blob_act(): (/obj/structure/blob)
#define COMSIG_ATOM_BLOB_ACT "atom_blob_act"
	/// if returned, forces nothing to happen when the atom is attacked by a blob
	#define COMPONENT_CANCEL_BLOB_ACT (1<<0)
///from base of atom/acid_act(): (acidpwr, acid_volume)
#define COMSIG_ATOM_ACID_ACT "atom_acid_act"
///from base of atom/emag_act(): (/mob/user)
#define COMSIG_ATOM_EMAG_ACT "atom_emag_act"
///from base of atom/narsie_act(): ()
#define COMSIG_ATOM_NARSIE_ACT "atom_narsie_act"
///from base of atom/rcd_act(): (/mob, /obj/item/construction/rcd, passed_mode)
#define COMSIG_ATOM_RCD_ACT "atom_rcd_act"
///from base of atom/singularity_pull(): (/atom, current_size)
#define COMSIG_ATOM_SING_PULL "atom_sing_pull"
///from obj/machinery/bsa/full/proc/fire(): ()
#define COMSIG_ATOM_BSA_BEAM "atom_bsa_beam_pass"
	#define COMSIG_ATOM_BLOCKS_BSA_BEAM (1<<0)

/// Sent from [atom/proc/item_interaction], when this atom is left-clicked on by a mob with an item
/// Sent from the very beginning of the click chain, intended for generic atom-item interactions
/// Args: (mob/living/user, obj/item/tool, list/modifiers)
/// Return any ITEM_INTERACT_ flags as relevant (see tools.dm)
#define COMSIG_ATOM_ITEM_INTERACTION "atom_item_interaction"
/// Sent from [atom/proc/item_interaction], when this atom is right-clicked on by a mob with an item
/// Sent from the very beginning of the click chain, intended for generic atom-item interactions
/// Args: (mob/living/user, obj/item/tool, list/modifiers)
/// Return any ITEM_INTERACT_ flags as relevant (see tools.dm)
#define COMSIG_ATOM_ITEM_INTERACTION_SECONDARY "atom_item_interaction_secondary"
/// Sent from [atom/proc/item_interaction], to a mob clicking on an atom with an item
#define COMSIG_USER_ITEM_INTERACTION "user_item_interaction"
/// Sent from [atom/proc/item_interaction], to an item clicking on an atom
/// Args: (mob/living/user, atom/interacting_with, list/modifiers)
/// Return any ITEM_INTERACT_ flags as relevant (see tools.dm)
#define COMSIG_ITEM_INTERACTING_WITH_ATOM "item_interacting_with_atom"
/// Sent from [atom/proc/item_interaction], to an item right-clicking on an atom
/// Args: (mob/living/user, atom/interacting_with, list/modifiers)
/// Return any ITEM_INTERACT_ flags as relevant (see tools.dm)
#define COMSIG_ITEM_INTERACTING_WITH_ATOM_SECONDARY "item_interacting_with_atom_secondary"
/// Sent from [atom/proc/item_interaction], when this atom is right-clicked on by a mob with a tool
#define COMSIG_USER_ITEM_INTERACTION_SECONDARY "user_item_interaction_secondary"
/// Sent from [atom/proc/item_interaction], when this atom is left-clicked on by a mob with a tool of a specific tool type
/// Args: (mob/living/user, obj/item/tool, list/recipes)
/// Return any ITEM_INTERACT_ flags as relevant (see tools.dm)
#define COMSIG_ATOM_TOOL_ACT(tooltype) "tool_act_[tooltype]"
/// Sent from [atom/proc/item_interaction], when this atom is right-clicked on by a mob with a tool of a specific tool type
/// Args: (mob/living/user, obj/item/tool)
/// Return any ITEM_INTERACT_ flags as relevant (see tools.dm)
#define COMSIG_ATOM_SECONDARY_TOOL_ACT(tooltype) "tool_secondary_act_[tooltype]"

/// Sent from [atom/proc/ranged_item_interaction], when this atom is left-clicked on by a mob with an item while not adjacent
#define COMSIG_ATOM_RANGED_ITEM_INTERACTION "atom_ranged_item_interaction"
/// Sent from [atom/proc/ranged_item_interaction], when this atom is right-clicked on by a mob with an item while not adjacent
#define COMSIG_ATOM_RANGED_ITEM_INTERACTION_SECONDARY "atom_ranged_item_interaction_secondary"
/// Sent from [atom/proc/ranged_item_interaction], when a mob is using this item while left-clicking on by an atom while not adjacent
#define COMSIG_RANGED_ITEM_INTERACTING_WITH_ATOM "ranged_item_interacting_with_atom"
/// Sent from [atom/proc/ranged_item_interaction], when a mob is using this item while right-clicking on by an atom while not adjacent
#define COMSIG_RANGED_ITEM_INTERACTING_WITH_ATOM_SECONDARY "ranged_item_interacting_with_atom_secondary"

/// Sent from [atom/proc/item_interaction], when this atom is used as a tool and an event occurs
#define COMSIG_ITEM_TOOL_ACTED "tool_item_acted"

/// from /obj/projectile/energy/fisher/on_hit() or /obj/item/gun/energy/recharge/fisher when striking a target
#define COMSIG_ATOM_SABOTEUR_ACT "hit_by_saboteur"
	#define COMSIG_SABOTEUR_SUCCESS 1

/// signal sent when a mouse is hovering over us, sent by atom/proc/on_mouse_entered
#define COMSIG_ATOM_MOUSE_ENTERED "mouse_entered"
