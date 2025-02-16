/*
 * This test checks that all heretic knowledges that unlocks rituals
 * properly consume all used atoms and creates all resulting atoms.
 *
 * This test ONLY checks knowledges that unlock rituals which consume atoms and produce atoms.
 * - Rituals that consume atoms, but do not create any atoms (such as rituals of knowledge) are not tested.
 * - Summon rituals sleep after completing as they expect a ghost candidate to fill the summon, so they're skipped.
 * - Final rituals results in a bunch of side-effects and vary a good deal so they're skipped explicitly.
 * - Sacrifice ritual (Hunt and Sacrifice) requires sacrifice targets, as well as spawning a new z-level, so it's better not to test.
 * - Codex Morbus doesn't consume the body that is required in it's ritual.
 */
/datum/unit_test/heretic_rituals

/datum/unit_test/heretic_rituals/Run()

	// Gotta create ourselves a rune and a user to start.
	var/obj/effect/heretic_rune/big/our_rune = allocate(/obj/effect/heretic_rune/big)
	var/mob/living/carbon/human/our_heretic = allocate(/mob/living/carbon/human/consistent)
	// -- Note for the human dummy we create:
	// The user does not actually NEED a heretic antag datum for the type of rituals we're testing,
	// so we don't give them one here. The heretic antag datum has side effects when applied,
	// like creating influences and learning the default knowledge types, so better safe than sorry.

	// Slap them down somewhere. The "heretic" should be in the middle of the rune, though this doesn't really matter.
	our_rune.forceMove(run_loc_floor_bottom_left)
	our_heretic.forceMove(locate((run_loc_floor_bottom_left.x + 1), (run_loc_floor_bottom_left.y + 1), run_loc_floor_bottom_left.z))

	// Set up the blacklist for types we don't want to test here. See above for reasons.
	var/list/blacklist_typecache = typecacheof(list(
		/datum/heretic_knowledge/summon,
		/datum/heretic_knowledge/ultimate,
		/datum/heretic_knowledge/hunt_and_sacrifice,
		/datum/heretic_knowledge/codex_morbus,
	))
	var/list/all_ritual_knowledge = list()

	// Now, let's instantiate our all_ritual_knowledge list with knowledge we're gonna test.
	for(var/knowledge_type in typesof(/datum/heretic_knowledge))

		// Skip blacklisted types
		if(is_type_in_typecache(knowledge_type, blacklist_typecache))
			continue

		var/datum/heretic_knowledge/instantiated_knowledge = new knowledge_type()
		// No required atoms = it's not a ritual, delete it and move on
		// No resulting atoms = it's not a ritual we test here, delete it and move on
		if(!LAZYLEN(instantiated_knowledge.required_atoms) || !LAZYLEN(instantiated_knowledge.result_atoms))
			qdel(instantiated_knowledge)
			continue

		all_ritual_knowledge += instantiated_knowledge

	// All the knowledge we want to test is instantiated, let's actually test their rituals now.
	for(var/datum/heretic_knowledge/knowledge as anything in all_ritual_knowledge)
		// Let's do a dry run of any special checks the knowledge may have
		// without any atoms passed at all. This is to ensure that,
		// if the ritual requires specific circumstances we can't setup in this test,
		// such as freezing temperatures or humans that are augmented on completion,
		// that we don't proceede to try to test them (as they'll fail anyways).
		if(!knowledge.recipe_snowflake_check(our_heretic, list(), list(), get_turf(our_rune)))
			continue

		// Okay, so we've got a knowledge by this point we definitely want to test.
		// Go though all the atoms it wants for it's ritual and create them on the rune.
		var/list/created_atoms = list()
		for(var/ritual_item_path in knowledge.required_atoms)
			var/amount_to_create = knowledge.required_atoms[ritual_item_path]
			if(islist(ritual_item_path))
				ritual_item_path = pick(ritual_item_path)
			for(var/i in 1 to amount_to_create)
				var/obj/item/item = new ritual_item_path(get_turf(our_heretic))
				if(isitem(item))
					item.item_flags &= ~ABSTRACT
				created_atoms += item

		// Now, we can ACTUALLY run the ritual. Let's do it.
		// Attempt to run the knowledge via the sacrifice rune.
		// If do_ritual() returns FALSE with our knowledge, it messed up.
		// If do_ritual() returns TRUE, then it was successful.
		if(!our_rune.do_ritual(our_heretic, knowledge))
			// We failed. The knowledge should have everything to succeed, yet it returned FALSE!
			// Clean up the atoms it was meant to consume, so we can keep testing.
			for(var/atom/leftover as anything in created_atoms)
				created_atoms -= leftover
				qdel(leftover)

			// Aaand throw a fail.
			TEST_FAIL("Heretic rituals: ([knowledge.type]) Despite having all required atoms present, the ritual failed to transmute.")
			continue

		// Making it here means the ritual was a success.
		// Let's check all the atoms nearby to see if we got what we wanted.
		var/list/atom/movable/nearby_atoms = range(1, our_heretic)
		nearby_atoms -= our_heretic // Our dude is supposed to be there
		nearby_atoms -= our_rune // Same with our rune

		// Did we get all the results we want?
		for(var/result_item_path in knowledge.result_atoms)
			var/atom/result = locate(result_item_path) in nearby_atoms
			// No, we couldn't find the a resulting atom on the rune. Throw a fail.
			if(!result)
				TEST_FAIL("Heretic rituals: ([knowledge.type]) Despite successfully completing the ritual, a resulting atom could not be found ([result_item_path])")
				continue

			// Yes, we got a resulting atom we expected! Remove it from the list and clean up.
			nearby_atoms -= result
			qdel(result)

		// Finally, we checked all of our resulting atoms and cleaned them up.
		// The nearby_atoms list should be devoid of any atom/movables now. Let's double-check that.
		for(var/atom/thing as anything in nearby_atoms)
			if(!ismovable(thing))
				continue
			if(isitem(thing))
				var/obj/item/item = thing
				if(item.item_flags & ABSTRACT) //bodyparts and stuff will get registered otherwise
					continue

			// There are atoms around the rune still, and there shouldn't be.
			// All component atoms were consumed, and all resulting atoms were cleaned up.
			// This means the ritual may have messed up somewhere. Throw a fail and clean them up so we can keep testing.
			TEST_FAIL("Heretic rituals: ([knowledge.type]) After completing the ritual, there were non-result atoms remaining on the rune. ([thing] - [thing.type])")
			nearby_atoms -= thing
			qdel(thing)

	// All done, clean up the knowledge list.
	QDEL_LIST(all_ritual_knowledge)
