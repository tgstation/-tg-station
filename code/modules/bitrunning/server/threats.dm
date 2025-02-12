/// Adds threats to the list and notifies players
/obj/machinery/quantum_server/proc/add_threats(mob/living/threat)
	spawned_threat_refs.Add(WEAKREF(threat))
	SEND_SIGNAL(src, COMSIG_BITRUNNER_THREAT_CREATED)
	threat.AddComponent(/datum/component/virtual_entity, src)


/// Choses which antagonist role is spawned based on threat
/obj/machinery/quantum_server/proc/get_antagonist_role()
	var/list/available = list()

	for(var/datum/antagonist/bitrunning_glitch/subtype as anything in subtypesof(/datum/antagonist/bitrunning_glitch))
		if(threat >= initial(subtype.threat))
			available += subtype

	shuffle_inplace(available)
	var/datum/antagonist/bitrunning_glitch/chosen = pick(available)

	threat -= initial(chosen.threat) * 0.5

	return chosen


/// Selects a target to mutate. Gives two attempts, then crashes if it fails.
/obj/machinery/quantum_server/proc/get_mutation_target()
	var/datum/weakref/target_ref = pick(mutation_candidate_refs)
	var/mob/living/resolved = target_ref.resolve()

	if(resolved)
		return resolved

	mutation_candidate_refs.Remove(target_ref)
	if(!length(mutation_candidate_refs))
		return

	target_ref = pick(mutation_candidate_refs)
	resolved = target_ref.resolve()
	return resolved


/// Finds any mobs with minds in the zones and gives them the bad news
/obj/machinery/quantum_server/proc/notify_spawned_threats()
	for(var/datum/weakref/baddie_ref as anything in spawned_threat_refs)
		var/mob/living/baddie = baddie_ref.resolve()
		if(isnull(baddie?.mind) || baddie.stat >= UNCONSCIOUS)
			continue

		var/atom/movable/screen/alert/bitrunning/alert = baddie.throw_alert(
			ALERT_BITRUNNER_RESET,
			/atom/movable/screen/alert/bitrunning,
			new_master = src,
		)
		alert.name = "Queue Deletion"
		alert.desc = "The server is resetting. Oblivion awaits."

		to_chat(baddie, span_userdanger("You have been flagged for deletion! Thank you for your service."))


/// Removes a specific threat - used when station spawning
/obj/machinery/quantum_server/proc/remove_threat(mob/living/threat)
	spawned_threat_refs.Remove(WEAKREF(threat))


/// Selects the role and waits for a ghost orbiter
/obj/machinery/quantum_server/proc/setup_glitch(datum/antagonist/bitrunning_glitch/forced_role)
	if(!validate_mutation_candidates())
		return

	var/mob/living/mutation_target = get_mutation_target()
	if(isnull(mutation_target))
		CRASH("vdom: After two attempts, no valid mutation target was found.")

	var/atom/thing = mutation_target
	thing.create_digital_aura()

	var/datum/antagonist/bitrunning_glitch/chosen_role = forced_role || get_antagonist_role()
	var/role_name = initial(chosen_role.name)
	var/mob/chosen_one = SSpolling.poll_ghosts_for_target(
		question = "<span class='ooc'>A temporary antagonist role is spawning in the virtual domain.</span>\
		\n<span class='boldnotice'>You will return to your previous body on conclusion.</span>",
		check_jobban = ROLE_GLITCH,
		poll_time = 20 SECONDS,
		checked_target = mutation_target,
		ignore_category = POLL_IGNORE_GLITCH,
		alert_pic = mutation_target,
		role_name_text = "Malfunction: [role_name]",
	)
	spawn_glitch(chosen_role, mutation_target, chosen_one)
	return mutation_target


/// Orbit poll has concluded - spawn the antag
/obj/machinery/quantum_server/proc/spawn_glitch(datum/antagonist/bitrunning_glitch/chosen_role, mob/living/mutation_target, mob/dead/observer/ghost)
	if(QDELETED(mutation_target))
		return

	if(QDELETED(src) || isnull(ghost) || isnull(generated_domain) || !is_ready || !is_operational)
		var/atom/thing = mutation_target
		thing.remove_digital_aura()
		return

	var/role_name = initial(chosen_role.name)

	var/mob/living/new_mob
	switch(role_name)
		if(ROLE_NETGUARDIAN)
			new_mob = new /mob/living/basic/netguardian(mutation_target.loc)
		else // any other humanoid mob
			new_mob = new /mob/living/carbon/human(mutation_target.loc)

	mutation_target.gib(DROP_ALL_REMAINS)

	var/datum/mind/ghost_mind = ghost.mind
	new_mob.key = ghost.key

	if(ghost_mind)
		new_mob.AddComponent(/datum/component/temporary_body, ghost_mind, ghost_mind.current, TRUE)

	var/datum/mind/antag_mind = new_mob.mind
	antag_mind.add_antag_datum(chosen_role)
	antag_mind.special_role = ROLE_GLITCH
	antag_mind.set_assigned_role(SSjob.get_job_type(/datum/job/bitrunning_glitch))

	playsound(new_mob, 'sound/effects/magic/ethereal_exit.ogg', 50, vary = TRUE)
	message_admins("[ADMIN_LOOKUPFLW(new_mob)] has been made into virtual antagonist by an event.")
	new_mob.log_message("was spawned as a virtual antagonist by an event.", LOG_GAME)

	add_threats(new_mob)


/// Oh boy - transports the antag station side
/obj/machinery/quantum_server/proc/station_spawn(mob/living/antag, obj/machinery/byteforge/chosen_forge)
	antag.balloon_alert(antag, "scanning...")
	chosen_forge.setup_particles(angry = TRUE)
	var/obj/machinery/announcement_system/aas = get_announcement_system(source = src)
	if (aas)
		aas.broadcast("QUANTUM SERVER ALERT: Security breach detected. Unauthorized entry sequence in progress...", list(RADIO_CHANNEL_SUPPLY))
	SEND_SIGNAL(src, COMSIG_BITRUNNER_STATION_SPAWN)

	var/timeout = 2 SECONDS
	if(!ishuman(antag))
		if (aas)
			aas.broadcast("QUANTUM SERVER ALERT: Fabrication protocols have crashed unexpectedly. Please evacuate the area.", list(RADIO_CHANNEL_SUPPLY))
		timeout = 10 SECONDS

	if(!do_after(antag, timeout) || QDELETED(chosen_forge) || QDELETED(antag) || QDELETED(src) || !is_ready || !is_operational)
		chosen_forge.setup_particles()
		return

	var/datum/component/glitch/effect = antag.AddComponent(/datum/component/glitch, \
		server = src, \
		forge = chosen_forge, \
	)

	chosen_forge.flicker(angry = TRUE)
	if(!do_after(antag, 1 SECONDS))
		chosen_forge.setup_particles()
		qdel(effect)
		return

	chosen_forge.flash()

	if(ishuman(antag))
		reset_equipment(antag)
	else if (aas)
		aas.broadcast("QUANTUM SERVER CRITICAL ALERT: Unregistered mechanical entity deployed.", list())

	var/datum/antagonist/antag_datum = antag.mind?.has_antag_datum(/datum/antagonist/bitrunning_glitch)
	if(istype(antag_datum))
		antag_datum.show_in_roundend = TRUE

	var/datum/component/temp_body = antag.GetComponent(/datum/component/temporary_body)
	if(temp_body)
		qdel(temp_body)

	do_teleport(antag, get_turf(chosen_forge), forced = TRUE, asoundin = 'sound/effects/magic/ethereal_enter.ogg', asoundout = 'sound/effects/magic/ethereal_exit.ogg', channel = TELEPORT_CHANNEL_QUANTUM)


/// Removes any invalid candidates from the list
/obj/machinery/quantum_server/proc/validate_mutation_candidates()
	for(var/datum/weakref/creature_ref as anything in mutation_candidate_refs)
		var/mob/living/creature = creature_ref?.resolve()
		if(isnull(creature) || creature.mind)
			mutation_candidate_refs.Remove(creature_ref)

	if(!length(mutation_candidate_refs))
		return FALSE

	shuffle_inplace(mutation_candidate_refs)

	return TRUE
