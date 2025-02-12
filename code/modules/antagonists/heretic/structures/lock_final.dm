/obj/structure/lock_tear
	name = "???"
	desc = "It stares back. There's no reason to remain. Run."
	max_integrity = INFINITY
	resistance_flags = INDESTRUCTIBLE | LAVA_PROOF | FIRE_PROOF | UNACIDABLE | ACID_PROOF
	icon = 'icons/obj/anomaly.dmi'
	icon_state = "bhole3"
	color = COLOR_VOID_PURPLE
	light_color = COLOR_VOID_PURPLE
	light_range = 20
	anchored = TRUE
	density = FALSE
	layer = HIGH_PIPE_LAYER //0.01 above sigil layer used by heretic runes
	move_resist = INFINITY
	/// Who is our daddy?
	var/datum/mind/ascendee
	/// True if we're currently checking for ghost opinions
	var/gathering_candidates = TRUE
	///a static list of heretic summons we cam create, automatically populated from heretic monster subtypes
	var/static/list/monster_types
	/// A static list of heretic summons which we should not create
	var/static/list/monster_types_blacklist = list(
		/mob/living/basic/heretic_summon/armsy,
		/mob/living/basic/heretic_summon/star_gazer,
	)

/obj/structure/lock_tear/Initialize(mapload, datum/mind/ascendant_mind)
	. = ..()
	transform *= 3
	if(isnull(monster_types))
		monster_types = subtypesof(/mob/living/basic/heretic_summon) - monster_types_blacklist
	if(!isnull(ascendant_mind))
		ascendee = ascendant_mind
		RegisterSignals(ascendant_mind.current, list(COMSIG_LIVING_DEATH, COMSIG_QDELETING), PROC_REF(end_madness))
	SSpoints_of_interest.make_point_of_interest(src)
	INVOKE_ASYNC(src, PROC_REF(poll_ghosts))

/// Ask ghosts if they want to make some noise
/obj/structure/lock_tear/proc/poll_ghosts()
	var/list/candidates = SSpolling.poll_ghost_candidates("Would you like to be a random [span_notice("eldritch monster")] attacking the crew?", check_jobban = ROLE_SENTIENCE, role = ROLE_SENTIENCE, poll_time = 10 SECONDS, ignore_category = POLL_IGNORE_HERETIC_MONSTER, alert_pic = src, role_name_text = "eldritch monster")
	while(LAZYLEN(candidates))
		var/mob/dead/observer/candidate = pick_n_take(candidates)
		ghost_to_monster(candidate, should_ask = FALSE)
	gathering_candidates = FALSE

/// Destroy the rift if you kill the heretic
/obj/structure/lock_tear/proc/end_madness(datum/former_master)
	SIGNAL_HANDLER
	var/turf/our_turf = get_turf(src)
	playsound(our_turf, 'sound/effects/magic/castsummon.ogg', vol = 100, vary = TRUE)
	visible_message(span_boldwarning("The rip in space spasms and disappears!"))
	UnregisterSignal(former_master, list(COMSIG_LIVING_DEATH, COMSIG_QDELETING)) // Just in case they die THEN delete
	new /obj/effect/temp_visual/destabilising_tear(our_turf)
	qdel(src)

/obj/structure/lock_tear/attack_ghost(mob/user)
	. = ..()
	if(. || gathering_candidates)
		return
	ghost_to_monster(user)

/obj/structure/lock_tear/examine(mob/user)
	. = ..()
	if (!isobserver(user) || gathering_candidates)
		return
	. += span_notice("You can use this to enter the world as a foul monster.")

/// Turn a ghost into an 'orrible beast
/obj/structure/lock_tear/proc/ghost_to_monster(mob/dead/observer/user, should_ask = TRUE)
	if(should_ask)
		var/ask = tgui_alert(user, "Become a monster?", "Ascended Rift", list("Yes", "No"))
		if(ask != "Yes" || QDELETED(src) || QDELETED(user))
			return FALSE
	var/monster_type = pick(monster_types)
	var/mob/living/monster = new monster_type(loc)
	monster.PossessByPlayer(user.key)
	monster.set_name()
	var/datum/antagonist/heretic_monster/woohoo_free_antag = new(src)
	monster.mind.add_antag_datum(woohoo_free_antag)
	if(ascendee)
		monster.faction = ascendee.current.faction
		woohoo_free_antag.set_owner(ascendee)
	var/datum/objective/kill_all_your_friends = new()
	kill_all_your_friends.owner = monster.mind
	kill_all_your_friends.explanation_text = "The station's crew must be culled."
	kill_all_your_friends.completed = TRUE
	woohoo_free_antag.objectives += kill_all_your_friends

/obj/structure/lock_tear/move_crushed(atom/movable/pusher, force = MOVE_FORCE_DEFAULT, direction)
	return FALSE

/obj/structure/lock_tear/Destroy(force)
	if(ascendee)
		ascendee = null
	return ..()

/obj/effect/temp_visual/destabilising_tear
	name = "destabilised tear"
	icon = 'icons/obj/anomaly.dmi'
	icon_state = "bhole3"
	color = COLOR_VOID_PURPLE
	light_color = COLOR_VOID_PURPLE
	light_range = 20
	layer = HIGH_PIPE_LAYER
	duration = 1 SECONDS

/obj/effect/temp_visual/destabilising_tear/Initialize(mapload)
	. = ..()
	transform *= 3
	animate(src, transform = matrix().Scale(3.2), time = 0.15 SECONDS)
	animate(transform = matrix().Scale(0.2), time = 0.75 SECONDS)
	animate(transform = matrix().Scale(3, 0), time = 0.1 SECONDS)
	animate(src, color = COLOR_WHITE, time = 0.25 SECONDS, flags = ANIMATION_PARALLEL)
	animate(color = COLOR_VOID_PURPLE, time = 0.3 SECONDS)
