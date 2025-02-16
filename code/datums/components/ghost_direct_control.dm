/**
 * Component which lets ghosts click on a mob to take control of it
 */
/datum/component/ghost_direct_control
	/// Message to display upon successful possession
	var/assumed_control_message
	/// Type of ban you can get to prevent you from accepting this role
	var/ban_type
	/// Any extra checks which need to run before we take over
	var/datum/callback/extra_control_checks
	/// Callback run after someone successfully takes over the body
	var/datum/callback/after_assumed_control
	/// If we're currently awaiting the results of a ghost poll
	var/awaiting_ghosts = FALSE

/datum/component/ghost_direct_control/Initialize(
	ban_type = ROLE_SENTIENCE,
	role_name = null,
	poll_question = null,
	poll_candidates = TRUE,
	poll_announce_chosen = TRUE,
	poll_length = 10 SECONDS,
	poll_chat_border_icon = null,
	poll_ignore_key = POLL_IGNORE_SENTIENCE_POTION,
	assumed_control_message = null,
	datum/callback/extra_control_checks,
	datum/callback/after_assumed_control,
)
	. = ..()
	if (!isliving(parent))
		return COMPONENT_INCOMPATIBLE

	src.ban_type = ban_type
	src.assumed_control_message = assumed_control_message || "You are [parent]!"
	src.extra_control_checks = extra_control_checks
	src.after_assumed_control = after_assumed_control

	var/mob/mob_parent = parent
	LAZYADD(GLOB.joinable_mobs[format_text("[initial(mob_parent.name)]")], mob_parent)

	if (poll_candidates)
		INVOKE_ASYNC(src, PROC_REF(request_ghost_control), poll_question, role_name || "[parent]", poll_length, poll_ignore_key, poll_announce_chosen, poll_chat_border_icon)

/datum/component/ghost_direct_control/RegisterWithParent()
	. = ..()
	RegisterSignal(parent, COMSIG_ATOM_ATTACK_GHOST, PROC_REF(on_ghost_clicked))
	RegisterSignal(parent, COMSIG_ATOM_EXAMINE, PROC_REF(on_examined))
	RegisterSignal(parent, COMSIG_MOB_LOGIN, PROC_REF(on_login))

/datum/component/ghost_direct_control/UnregisterFromParent()
	UnregisterSignal(parent, list(COMSIG_ATOM_ATTACK_GHOST, COMSIG_ATOM_EXAMINE, COMSIG_MOB_LOGIN))
	return ..()

/datum/component/ghost_direct_control/Destroy(force)
	extra_control_checks = null
	after_assumed_control = null

	var/mob/mob_parent = parent
	var/list/spawners = GLOB.joinable_mobs[format_text("[initial(mob_parent.name)]")]
	LAZYREMOVE(spawners, mob_parent)
	if(!LAZYLEN(spawners))
		GLOB.joinable_mobs -= format_text("[initial(mob_parent.name)]")
	return ..()

/// Inform ghosts that they can possess this
/datum/component/ghost_direct_control/proc/on_examined(datum/source, mob/user, list/examine_text)
	SIGNAL_HANDLER
	if (!isobserver(user))
		return
	var/mob/living/our_mob = parent
	if (our_mob.stat == DEAD || our_mob.key || awaiting_ghosts)
		return
	examine_text += span_boldnotice("You could take control of this mob by clicking on it.")

/// Send out a request for a brain
/datum/component/ghost_direct_control/proc/request_ghost_control(poll_question, role_name, poll_length, poll_ignore_key, poll_announce_chosen, poll_chat_border_icon)
	if(!(GLOB.ghost_role_flags & GHOSTROLE_SPAWNER))
		return
	awaiting_ghosts = TRUE
	var/mob/chosen_one = SSpolling.poll_ghosts_for_target(
		question = poll_question,
		check_jobban = ban_type,
		role = ban_type,
		poll_time = poll_length,
		checked_target = parent,
		ignore_category = poll_ignore_key,
		alert_pic = parent,
		role_name_text = role_name,
		chat_text_border_icon = poll_chat_border_icon,
		announce_chosen = poll_announce_chosen,
	)
	awaiting_ghosts = FALSE
	if(isnull(chosen_one))
		return
	assume_direct_control(chosen_one)

/// A ghost clicked on us, they want to get in this body
/datum/component/ghost_direct_control/proc/on_ghost_clicked(mob/our_mob, mob/dead/observer/hopeful_ghost)
	SIGNAL_HANDLER
	if (our_mob.key)
		qdel(src)
		return
	if (!hopeful_ghost.client)
		return
	if (!(GLOB.ghost_role_flags & GHOSTROLE_SPAWNER))
		to_chat(hopeful_ghost, span_warning("Ghost roles have been temporarily disabled!"))
		return
	if (awaiting_ghosts)
		to_chat(hopeful_ghost, span_warning("Ghost candidate selection currently in progress!"))
		return COMPONENT_CANCEL_ATTACK_CHAIN
	if (!SSticker.HasRoundStarted())
		to_chat(hopeful_ghost, span_warning("You cannot assume control of this until after the round has started!"))
		return COMPONENT_CANCEL_ATTACK_CHAIN
	INVOKE_ASYNC(src, PROC_REF(attempt_possession), our_mob, hopeful_ghost)
	return COMPONENT_CANCEL_ATTACK_CHAIN

/// We got far enough to establish that this mob is a valid target, let's try to posssess it
/datum/component/ghost_direct_control/proc/attempt_possession(mob/our_mob, mob/dead/observer/hopeful_ghost)
	var/ghost_asked = tgui_alert(usr, "Become [our_mob]?", "Are you sure?", list("Yes", "No"))
	if (ghost_asked != "Yes" || QDELETED(our_mob))
		return
	assume_direct_control(hopeful_ghost)

/// Grant possession of our mob, component is now no longer required
/datum/component/ghost_direct_control/proc/assume_direct_control(mob/harbinger)
	if (QDELETED(src))
		to_chat(harbinger, span_warning("Offer to possess creature has expired!"))
		return
	if (is_banned_from(harbinger.ckey, list(ban_type)))
		to_chat(harbinger, span_warning("You are banned from playing as this role!"))
		return
	if (!(GLOB.ghost_role_flags & GHOSTROLE_SPAWNER))
		to_chat(harbinger, span_warning("Ghost roles have been temporarily disabled!"))
		return
	var/mob/living/new_body = parent
	if (new_body.stat == DEAD)
		to_chat(harbinger, span_warning("This body has passed away, it is of no use!"))
		return
	if (new_body.key)
		to_chat(harbinger, span_warning("[parent] has already become sapient!"))
		qdel(src)
		return
	if (extra_control_checks && !extra_control_checks.Invoke(harbinger))
		return

	harbinger.log_message("took control of [new_body].", LOG_GAME)
	// doesn't transfer mind because that transfers antag datum as well
	new_body.PossessByPlayer(harbinger.ckey)

	// Already qdels due to below proc but just in case
	qdel(src)

/// When someone assumes control, get rid of our component
/datum/component/ghost_direct_control/proc/on_login(mob/harbinger)
	SIGNAL_HANDLER
	// This proc is called the very moment .key is set, so we need to force mind to initialize here if we want the invoke to affect the mind of the mob
	if(isnull(harbinger.mind))
		harbinger.mind_initialize()
	to_chat(harbinger, span_boldnotice(assumed_control_message))
	after_assumed_control?.Invoke(harbinger)
	qdel(src)
