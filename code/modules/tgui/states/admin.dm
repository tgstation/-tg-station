/*!
 * Copyright (c) 2020 Aleksej Komarov
 * SPDX-License-Identifier: MIT
 */

/**
 * tgui state: admin_state
 *
 * Checks if the user has specific admin permissions.
 */

GLOBAL_LIST_EMPTY_TYPED(admin_states, /datum/ui_state/admin_state)
GLOBAL_PROTECT(admin_states)

/datum/ui_state/admin_state
	/// The specific admin permissions required for the UI using this state.
	VAR_FINAL/required_perms = R_ADMIN

/datum/ui_state/admin_state/New(required_perms = R_ADMIN)
	. = ..()
	src.required_perms = required_perms

/datum/ui_state/admin_state/can_use_topic(src_object, mob/user)
	if(check_rights_for(user.client, required_perms))
		return UI_INTERACTIVE
	return UI_CLOSE

/datum/ui_state/admin_state/vv_edit_var(var_name, var_value)
	if(var_name == NAMEOF(src, required_perms))
		return FALSE
	return ..()

/**
 * Returns a ui_state that checks to see if the user has specific admin permissions.
 *
 * Arguments:
 * * required_perms: Which admin permission flags to check the user for, such as [R_ADMIN]
 */
/proc/admin_state(required_perms) as /datum/ui_state/admin_state
	RETURN_TYPE(/datum/ui_state/admin_state)
	if(isnull(required_perms))
		CRASH("Null permissions passed to admin_state, permission flags must be explicitly defined!")
	// just to make the rest of this slightly easier on the eyes
	var/list/admin_states = GLOB.admin_states
	var/perms_key = "[required_perms]"

	if(!isnull(admin_states[perms_key]))
		return admin_states[perms_key]
	return admin_states[perms_key] = new /datum/ui_state/admin_state(required_perms)
