/obj/effect/mob_spawn
	name = "Mob Spawner"
	density = TRUE
	anchored = TRUE
	//So it shows up in the map editor
	icon = 'icons/effects/mapping_helpers.dmi'
	icon_state = "mobspawner"
	/// Can this spawner be used up?
	var/infinite_use = FALSE
	///A forced name of the mob, though can be overridden if a special name is passed as an argument
	var/mob_name
	///the type of the mob, you best inherit this
	var/mob_type = /mob/living/basic/cockroach

	////Human specific stuff. Don't set these if you aren't using a human, the unit tests will put a stop to your sinful hand.

	///sets the human as a species, use a typepath (example: /datum/species/skeleton)
	var/datum/species/mob_species
	///equips the human with an outfit.
	var/datum/outfit/outfit
	///for mappers to override parts of the outfit. really only in here for secret away missions, please try to refrain from using this out of laziness
	var/list/outfit_override
	///sets a human's hairstyle
	var/hairstyle
	///sets a human's facial hair
	var/facial_hairstyle
	///sets a human's hair color (use special for gradients, sorry)
	var/haircolor
	///sets a human's facial hair color
	var/facial_haircolor
	///sets a human's skin tone
	var/skin_tone
	/// Weakref to the mob this spawner created - just if you needed to do something with it.
	var/datum/weakref/spawned_mob_ref

/obj/effect/mob_spawn/Initialize(mapload)
	. = ..()
	if(faction)
		faction = string_list(faction)

/obj/effect/mob_spawn/Destroy()
	spawned_mob_ref = null
	if(istype(outfit))
		QDEL_NULL(outfit)
	return ..()

/// Creates whatever mob the spawner makes. Return FALSE if we want to exit from here without doing that, returning NULL will be logged to admins.
/obj/effect/mob_spawn/proc/create(mob/mob_possessor, newname)
	var/mob/living/spawned_mob = new mob_type(get_turf(src)) //living mobs only
	name_mob(spawned_mob, newname)
	special(spawned_mob, mob_possessor)
	equip(spawned_mob)
	spawned_mob_ref = WEAKREF(spawned_mob)
	return spawned_mob

/obj/effect/mob_spawn/proc/special(mob/living/spawned_mob)
	SHOULD_CALL_PARENT(TRUE)
	if(faction)
		spawned_mob.faction = faction
	if(ishuman(spawned_mob))
		var/mob/living/carbon/human/spawned_human = spawned_mob
		if(mob_species)
			spawned_human.set_species(mob_species)
		spawned_human.dna.species.give_important_for_life(spawned_human) // for preventing plasmamen from combusting immediately upon spawning
		spawned_human.underwear = "Nude"
		spawned_human.undershirt = "Nude"
		spawned_human.socks = "Nude"
		randomize_human_normie(spawned_human)
		if(hairstyle)
			spawned_human.set_hairstyle(hairstyle, update = FALSE)
		if(facial_hairstyle)
			spawned_human.set_facial_hairstyle(facial_hairstyle, update = FALSE)
		if(haircolor)
			spawned_human.set_haircolor(haircolor, update = FALSE)
		if(facial_haircolor)
			spawned_human.set_facial_haircolor(facial_haircolor, update = FALSE)
		spawned_human.update_body(is_creating = TRUE)

/obj/effect/mob_spawn/proc/name_mob(mob/living/spawned_mob, forced_name)
	var/chosen_name
	//passed arguments on mob spawns are number one priority
	if(forced_name)
		chosen_name = forced_name
	//then the mob name var
	else if(mob_name)
		chosen_name = mob_name
	//then if no name was chosen the one the mob has by default works great
	if(!chosen_name)
		return
	//not using an old name doesn't update records- but ghost roles don't have records so who cares
	spawned_mob.fully_replace_character_name(null, chosen_name)

/obj/effect/mob_spawn/proc/equip(mob/living/spawned_mob)
	if(outfit)
		var/mob/living/carbon/human/spawned_human = spawned_mob
		if(outfit_override)
			outfit = new outfit //create it now to apply vars
			for(var/outfit_var in outfit_override)
				if(!ispath(outfit_override[outfit_var]) && !isnull(outfit_override[outfit_var]))
					CRASH("outfit_override var on [mob_name] spawner has incorrect values! it must be an assoc list with outfit \"var\" = path | null")
				outfit.vars[outfit_var] = outfit_override[outfit_var]
		spawned_human.equipOutfit(outfit)

///these mob spawn subtypes do not trigger until attacked by a ghost.
/obj/effect/mob_spawn/ghost_role
	///a short, lowercase name for the mob used in possession prompt that pops up on ghost attacks. must be set.
	var/prompt_name = ""
	///if false, you won't prompt for this role. best used for replacing the prompt system with something else like a radial, or something.
	var/prompt_ghost = TRUE
	///how many times this spawner can be used (it won't delete unless it's out of uses and the var to delete itself is set)
	var/uses = 1
	/// Does the spawner delete itself when it runs out of uses?
	var/deletes_on_zero_uses_left = TRUE
	/// A list of the ckeys that currently are trying to access this spawner, so that they can't try to spawn more than once (in case there's sleeps).
	/// Static because you only really want to be able to spawn in one spawner at a time, obviously.
	var/static/list/ckeys_trying_to_spawn

	////descriptions

	///This should be the declaration of what the ghost role is, and maybe a short blurb after if you want. Shown in the spawner menu and after spawning first.
	var/you_are_text = ""
	///This should be the actual instructions/description/context to the ghost role. This should be the really long explainy bit, basically.
	var/flavour_text = ""
	///This is critical non-policy information about the ghost role. Shown in the spawner menu and after spawning last.
	var/important_text = ""

	///Show these on spawn? Usually used for hardcoded special flavor
	var/show_flavor = TRUE

	////bans and policy

	///which role to check for a job ban (ROLE_LAVALAND is the default ghost role ban)
	var/role_ban = ROLE_LAVALAND
	/// Typepath indicating the kind of job datum this ghost role will have. PLEASE inherit this with a new job datum, it's not hard. jobs come with policy configs.
	var/spawner_job_path = /datum/job/ghost_role

	/// Whether this offers a temporary body or not. Essentially, you'll be able to reenter your body after using this spawner.
	var/temp_body = FALSE


/obj/effect/mob_spawn/ghost_role/Initialize(mapload)
	. = ..()
	SSpoints_of_interest.make_point_of_interest(src)
	LAZYADD(GLOB.mob_spawners[name], src)

/obj/effect/mob_spawn/ghost_role/Destroy()
	var/list/spawners = GLOB.mob_spawners[name]
	LAZYREMOVE(spawners, src)
	if(!LAZYLEN(spawners))
		GLOB.mob_spawners -= name
	return ..()

//ATTACK GHOST IGNORING PARENT RETURN VALUE
/obj/effect/mob_spawn/ghost_role/attack_ghost(mob/dead/observer/user)
	if(!SSticker.HasRoundStarted() || !loc)
		return

	// We don't open the prompt more than once at a time.
	if(LAZYFIND(ckeys_trying_to_spawn, user.ckey))
		return

	var/user_ckey = user.ckey // Just in case shenanigans happen, we always want to remove it from the list.
	LAZYADD(ckeys_trying_to_spawn, user_ckey)

	if(prompt_ghost)
		var/prompt = "Become [prompt_name]?"
		if(!temp_body && user.can_reenter_corpse && user.mind)
			prompt += " (Warning, You can no longer be revived!)"
		var/ghost_role = tgui_alert(usr, prompt, buttons = list("Yes", "No"), timeout = 10 SECONDS)
		if(ghost_role != "Yes" || !loc || QDELETED(user))
			LAZYREMOVE(ckeys_trying_to_spawn, user_ckey)
			return

	if(!(GLOB.ghost_role_flags & GHOSTROLE_SPAWNER) && !(flags_1 & ADMIN_SPAWNED_1))
		to_chat(user, span_warning("An admin has temporarily disabled non-admin ghost roles!"))
		LAZYREMOVE(ckeys_trying_to_spawn, user_ckey)
		return
	if(uses <= 0 && !infinite_use) //just in case
		to_chat(user, span_warning("This spawner is out of charges!"))
		LAZYREMOVE(ckeys_trying_to_spawn, user_ckey)
		return

	if(is_banned_from(user.ckey, role_ban))
		to_chat(user, span_warning("You are banned from this role!"))
		LAZYREMOVE(ckeys_trying_to_spawn, user_ckey)
		return
	if(!allow_spawn(user, silent = FALSE))
		LAZYREMOVE(ckeys_trying_to_spawn, user_ckey)
		return
	if(QDELETED(src) || QDELETED(user))
		LAZYREMOVE(ckeys_trying_to_spawn, user_ckey)
		return

	if(uses <= 0 && !infinite_use) // Just in case something took longer than it should've and we got here after the uses went below zero.
		to_chat(user, span_warning("This spawner is out of charges!"))
		LAZYREMOVE(ckeys_trying_to_spawn, user_ckey)
		return

	create_from_ghost(user)

/**
 * Uses a use and creates a mob from a passed ghost
 *
 * Does NOT validate that the spawn is possible or valid - assumes this has been done already!
 *
 * If you are manually forcing a player into this mob spawn,
 * you should be using this and not directly calling [proc/create].
 */
/obj/effect/mob_spawn/ghost_role/proc/create_from_ghost(mob/dead/user)
	ASSERT(istype(user))
	var/user_ckey = user.ckey // We need to do it before everything else, because after the create() the ckey will already have been transferred.

	user.log_message("became a [prompt_name].", LOG_GAME)
	uses -= 1 // Remove a use before trying to spawn to prevent strangeness like the spawner trying to spawn more mobs than it should be able to
	if(!temp_body)
		user.mind = null // dissassociate mind, don't let it follow us to the next life

	var/created = create(user)
	LAZYREMOVE(ckeys_trying_to_spawn, user_ckey) // We do this AFTER the create() so that we're basically sure that the user won't be in their ghost body anymore, so they can't click on the spawner again.

	if(!created)
		uses += 1 // Refund use because we didn't actually spawn anything

		if(isnull(created)) // If we explicitly return FALSE instead of just not returning a mob, we don't want to spam the admins
			CRASH("An instance of [type] didn't return anything when creating a mob, this might be broken!")

	SEND_SIGNAL(src, COMSIG_GHOSTROLE_SPAWNED, created)
	check_uses() // Now we check if the spawner should delete itself or not

	return created

/obj/effect/mob_spawn/ghost_role/create(mob/mob_possessor, newname)
	if(!mob_possessor.key) // This is in the scenario that the server is somehow lagging, or someone fucked up their code, and we try to spawn the same person in twice. We'll simply not spawn anything and CRASH(), so that we report what happened.
		CRASH("Attempted to create an instance of [type] with a mob that had no ckey attached to it, which isn't supported by ghost role spawners!")

	return ..()


/obj/effect/mob_spawn/ghost_role/special(mob/living/spawned_mob, mob/mob_possessor)
	. = ..()
	if(mob_possessor)
		if(mob_possessor.mind)
			mob_possessor.mind.transfer_to(spawned_mob, force_key_move = TRUE)
		else
			spawned_mob.PossessByPlayer(mob_possessor.key)
	var/datum/mind/spawned_mind = spawned_mob.mind
	if(spawned_mind)
		spawned_mob.mind.set_assigned_role_with_greeting(SSjob.get_job_type(spawner_job_path))
		spawned_mind.name = spawned_mob.real_name

	if(show_flavor)
		var/output_message = span_infoplain("<span class='big bold'>[you_are_text]</span>")
		if(flavour_text != "")
			output_message += "\n<span class='infoplain'><b>[flavour_text]</b></span>"
		if(important_text != "")
			output_message += "\n[span_userdanger("[important_text]")]"
		to_chat(spawned_mob, output_message)

/// Checks if the spawner has zero uses left, if so, delete yourself... NOW!
/obj/effect/mob_spawn/ghost_role/proc/check_uses()
	if(!uses && deletes_on_zero_uses_left)
		qdel(src)

///override this to add special spawn conditions to a ghost role
/obj/effect/mob_spawn/ghost_role/proc/allow_spawn(mob/user, silent = FALSE)
	return TRUE

///these mob spawn subtypes trigger immediately (New or Initialize) and are not player controlled... since they're dead, you know?
/obj/effect/mob_spawn/corpse
	density = FALSE //these are pretty much abstract objects that leave a corpse in their place.
	///when this mob spawn should auto trigger.
	var/spawn_when = CORPSE_INSTANT

	////damage values (very often, mappers want corpses to be mangled)

	///brute damage this corpse will spawn with
	var/brute_damage = 0
	///oxy damage this corpse will spawn with
	var/oxy_damage = 0
	///burn damage this corpse will spawn with
	var/burn_damage = 0

	///what environmental storytelling script should this corpse have
	var/corpse_description = ""
	///optionally different text to display if the target is a clown
	var/naive_corpse_description = ""

/obj/effect/mob_spawn/corpse/Initialize(mapload, no_spawn)
	. = ..()
	if(no_spawn)
		return
	switch(spawn_when)
		if(CORPSE_INSTANT)
			INVOKE_ASYNC(src, PROC_REF(create))
		if(CORPSE_ROUNDSTART)
			if(mapload || (SSticker && SSticker.current_state > GAME_STATE_SETTING_UP))
				INVOKE_ASYNC(src, PROC_REF(create))

/obj/effect/mob_spawn/corpse/special(mob/living/spawned_mob)
	. = ..()
	spawned_mob.death(TRUE)
	spawned_mob.adjustOxyLoss(oxy_damage)
	spawned_mob.adjustBruteLoss(brute_damage)
	spawned_mob.adjustFireLoss(burn_damage)
	if (corpse_description)
		spawned_mob.AddComponent(/datum/component/temporary_description, corpse_description, naive_corpse_description)

/obj/effect/mob_spawn/corpse/create(mob/mob_possessor, newname)
	. = ..()
	qdel(src)

//almost all mob spawns in this game, dead or living, are human. so voila

/obj/effect/mob_spawn/ghost_role/human
	//gives it a base sprite instead of a mapping helper. makes sense, right?
	icon = 'icons/obj/machines/sleeper.dmi'
	icon_state = "sleeper"
	mob_type = /mob/living/carbon/human

/obj/effect/mob_spawn/corpse/human
	icon_state = "corpsehuman"
	mob_type = /mob/living/carbon/human
	///disables PDA and sensors. only makes sense on corpses because ghost roles could simply turn those on again.
	var/conceal_presence = TRUE
	///husks the corpse if true.
	var/husk = FALSE

/obj/effect/mob_spawn/corpse/human/special(mob/living/carbon/human/spawned_human)
	. = ..()
	if(husk)
		spawned_human.Drain()
	else //Because for some reason I can't track down, things are getting turned into husks even if husk = false. It's in some damage proc somewhere.
		spawned_human.cure_husk()

/obj/effect/mob_spawn/corpse/human/equip(mob/living/carbon/human/spawned_human)
	. = ..()
	if(conceal_presence)
		// We don't want corpse PDAs to show up in the messenger list.
		var/obj/item/modular_computer/pda/messenger = locate() in spawned_human
		if(messenger)
			var/datum/computer_file/program/messenger/message_app = locate() in messenger.stored_files
			if(message_app)
				message_app.invisible = TRUE
		// Or on crew monitors
		var/obj/item/clothing/under/sensor_clothes = spawned_human.w_uniform
		if(istype(sensor_clothes))
			sensor_clothes.sensor_mode = SENSOR_OFF
			spawned_human.update_suit_sensors()

//don't use this in subtypes, just add 1000 brute yourself. that being said, this is a type that has 1000 brute. it doesn't really have a home anywhere else, it just needs to exist
/obj/effect/mob_spawn/corpse/human/damaged
	brute_damage = 1000
