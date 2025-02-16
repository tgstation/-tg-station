
//This proc is the most basic of the procs. All it does is make a new mob on the same tile and transfer over a few variables.
//Returns the new mob
//Note that this proc does NOT do MMI related stuff!
/mob/proc/change_mob_type(new_type = null, turf/location = null, new_name = null as text|null, delete_old_mob = FALSE)

	if(isnewplayer(src))
		to_chat(usr, span_danger("Cannot convert players who have not entered yet."))
		return

	if(!new_type)
		new_type = input("Mob type path:", "Mob type") as text|null

	if(istext(new_type))
		new_type = text2path(new_type)

	if( !ispath(new_type) )
		to_chat(usr, "Invalid type path (new_type = [new_type]) in change_mob_type(). Contact a coder.")
		return

	if(ispath(new_type, /mob/dead/new_player))
		to_chat(usr, span_danger("Cannot convert into a new_player mob type."))
		return

	if (SEND_SIGNAL(src, COMSIG_PRE_MOB_CHANGED_TYPE) & COMPONENT_BLOCK_MOB_CHANGE)
		return

	return change_mob_type_unchecked(new_type, location, new_name, delete_old_mob)

/// Version of [change_mob_type] that does no usr prompting (may send an error message though). Satisfies procs with the SHOULD_NOT_SLEEP restriction
/mob/proc/change_mob_type_unchecked(new_type = null, turf/location = null, new_name = null as text, delete_old_mob = FALSE)
	var/mob/desired_mob
	if(isturf(location))
		desired_mob = new new_type(location)
	else
		desired_mob = new new_type(src.loc)

	if(!ismob(desired_mob))
		to_chat(usr, "Type path is not a mob (new_type = [new_type]) in change_mob_type(). Contact a coder.")
		qdel(desired_mob)
		return

	if(istext(new_name))
		desired_mob.name = new_name
		desired_mob.real_name = new_name
	else
		desired_mob.name = src.name
		desired_mob.real_name = src.real_name

	if(has_dna() && desired_mob.has_dna())
		var/mob/living/carbon/old_mob = src
		var/mob/living/carbon/new_mob = desired_mob
		old_mob.dna.transfer_identity(new_mob, transfer_species = FALSE)
		new_mob.updateappearance(icon_update = TRUE, mutcolor_update = TRUE, mutations_overlay_update = TRUE)
	else if(ishuman(desired_mob) && (!ismonkey(desired_mob)))
		var/mob/living/carbon/human/new_human = desired_mob
		client?.prefs.safe_transfer_prefs_to(new_human)
		new_human.dna.update_dna_identity()
		new_human.updateappearance(icon_update = TRUE, mutcolor_update = TRUE, mutations_overlay_update = TRUE)

	//Ghosts have copys of their minds, but if an admin put somebody else in their og body, the mind will have a new mind.key
	//	and transfer_to will transfer the wrong person since it uses mind.key
	if(mind && isliving(desired_mob) && (!isobserver(src) || mind.current == src || QDELETED(mind.current)))
		if (ckey(mind.key) != ckey)
			//we could actually prevent the bug from happening here, but then nobody would know to look for the stack trace we are about to print.
			stack_trace("DEBUG: The bug where mob transfers or transforms sometimes kick unrelated people out of mobs has happened again. mob [src]([type])\ref[src] owned by [ckey] is being changed into a [new_type] but has a mind owned by [ckey(mind.key)].")

		mind.transfer_to(desired_mob, 1) // second argument to force key move to new mob
	else
		desired_mob.PossessByPlayer(key)

	SEND_SIGNAL(src, COMSIG_MOB_CHANGED_TYPE, desired_mob)
	if(delete_old_mob)
		QDEL_IN(src, 1)
	return desired_mob
