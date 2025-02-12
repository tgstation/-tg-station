#define TRAIT_FISH_TESTING "made_you_read_this"
#define FISH_REAGENT_AMOUNT (10 * FISH_WEIGHT_GRIND_TO_BITE_MULT)

///Ensures that all fish have an aquarium icon state and that sprite_width and sprite_height have been set.
/datum/unit_test/fish_aquarium_icons

/datum/unit_test/fish_aquarium_icons/Run()
	for(var/obj/item/fish/fish as anything in subtypesof(/obj/item/fish))
		if(ispath(fish, /obj/item/fish/testdummy)) //We don't care about unit test fish.
			continue
		var/init_icon = fish::dedicated_in_aquarium_icon
		var/init_icon_state = fish::dedicated_in_aquarium_icon_state || "[fish::icon_state]_small"
		if(!icon_exists(init_icon, init_icon_state))
			TEST_FAIL("[fish] with doesn't have a \"[init_icon_state]\" aquarium icon state in [init_icon]. Please make one.")
		if(!fish::sprite_width)
			TEST_FAIL("[fish] doesn't have a set sprite_width.")
		if(!fish::sprite_height)
			TEST_FAIL("[fish] doesn't have a set sprite_height.")

///Checks that things associated with fish size and weight work correctly.
/datum/unit_test/fish_size_weight

/datum/unit_test/fish_size_weight/Run()

	var/obj/structure/table/table = allocate(/obj/structure/table)
	var/obj/item/fish/testdummy/fish = allocate(__IMPLIED_TYPE__, table.loc)
	var/datum/reagent/reagent = fish.reagents?.has_reagent(/datum/reagent/fishdummy)
	TEST_ASSERT(reagent, "the test fish doesn't have the test reagent.[fish.reagents ? "" : " It doesn't even have a reagent holder."]")
	var/expected_units = FISH_REAGENT_AMOUNT * fish.weight / FISH_WEIGHT_BITE_DIVISOR
	TEST_ASSERT_EQUAL(reagent.volume, expected_units, "the test fish has [reagent.volume] units of the test reagent when it should have [expected_units]")
	TEST_ASSERT_EQUAL(fish.w_class, WEIGHT_CLASS_BULKY, "the test fish has w_class of [fish.w_class] when it should have been [WEIGHT_CLASS_BULKY]")
	var/mob/living/carbon/human/consistent/chef = allocate(/mob/living/carbon/human/consistent)
	var/obj/item/knife/kitchen/blade = allocate(/obj/item/knife/kitchen)
	var/fish_fillet_type = fish.fillet_type
	var/expected_num_fillets = fish.expected_num_fillets
	blade.melee_attack_chain(chef, fish)
	var/counted_fillets = 0
	for(var/atom/movable/content as anything in table.loc.contents)
		if(istype(content, fish_fillet_type))
			counted_fillets++
			allocated += content
	TEST_ASSERT_EQUAL(counted_fillets, expected_num_fillets, "the test fish yielded [counted_fillets] fillets when it should have been [expected_num_fillets]")

/// Make sure fish don't stay hungry after being fed
/datum/unit_test/fish_feeding

/datum/unit_test/fish_feeding/Run()
	var/obj/item/fish/testdummy/hungry = allocate(__IMPLIED_TYPE__)
	hungry.last_feeding = 0 //the fish should be hungry.
	TEST_ASSERT(hungry.get_hunger(), "the fish doesn't seem to be hungry in the slightest")
	var/obj/item/reagent_containers/cup/fish_feed/yummy = allocate(__IMPLIED_TYPE__)
	hungry.feed(yummy.reagents)
	TEST_ASSERT(!hungry.get_hunger(), "the fish is still hungry despite having been just fed")

	///Try feeding it again, but this time with the right hunger so they actually grow
	hungry.last_feeding = world.time - (hungry.feeding_frequency * FISH_GROWTH_PEAK)
	var/old_size = hungry.size
	var/old_weight = hungry.weight
	hungry.feed(yummy.reagents)
	TEST_ASSERT(hungry.size > old_size, "the fish size didn't increase after being properly fed")
	TEST_ASSERT(hungry.weight > old_weight, "the fish weight didn't increase after being properly fed")

///Checks that fish breeding works correctly.
/datum/unit_test/fish_breeding

/datum/unit_test/fish_breeding/Run()
	var/obj/item/fish_tank/reproduction/fish_tank = allocate(__IMPLIED_TYPE__)
	///Check if the fishes can generate offsprings at all.
	var/obj/item/fish/new_fish = fish_tank.fish.try_to_reproduce()
	TEST_ASSERT(new_fish, "the two test fishes couldn't generate an offspring")
	var/traits_len = length(new_fish.fish_traits)
	TEST_ASSERT_NOTEQUAL(traits_len, 2, "the offspring of the test fishes has both parents' traits, which are incompatible with each other")
	TEST_ASSERT_NOTEQUAL(traits_len, 0, "the offspring has neither of the parents' traits")
	TEST_ASSERT(HAS_TRAIT(new_fish, TRAIT_FISH_TESTING), "The offspring doesn't have the relative datum trait associated with its fish trait")

	///Check that crossbreeder, no-mating and self-reproductive fish traits work correctly.
	var/obj/structure/aquarium/traits/aquarium = allocate(/obj/structure/aquarium/traits)
	TEST_ASSERT(!aquarium.sterile.try_to_reproduce(), "The test aquarium's sterile fish managed to reproduce when it shouldn't have")
	var/obj/item/fish/crossbreeder_jr = aquarium.crossbreeder.try_to_reproduce()
	TEST_ASSERT(crossbreeder_jr, "The test aquarium's crossbreeder fish didn't manage to reproduce when it should have")
	TEST_ASSERT_EQUAL(crossbreeder_jr.type, aquarium.cloner.type, "The test aquarium's crossbreeder fish mated with the wrong type of fish")
	var/obj/item/fish/cloner_jr = aquarium.cloner.try_to_reproduce()
	TEST_ASSERT(cloner_jr, "The test aquarium's cloner fish didn't manage to reproduce when it should have")
	TEST_ASSERT_NOTEQUAL(cloner_jr.type, aquarium.sterile.type, "The test aquarium's cloner fish mated with the sterile fish")

/obj/item/fish_tank/reproduction
	var/obj/item/fish/testdummy/small/fish
	var/obj/item/fish/testdummy/small/partner

/obj/item/fish_tank/reproduction/Initialize(mapload)
	. = ..()
	fish = new(src)
	partner = new(src)

/obj/item/fish_tank/reproduction/Destroy()
	fish = null
	partner = null
	return ..()

///Checks that fish evolutions work correctly.
/datum/unit_test/fish_evolution

/datum/unit_test/fish_evolution/Run()
	var/obj/structure/aquarium/evolution/aquarium = allocate(/obj/structure/aquarium/evolution)
	var/obj/item/fish/evolve_jr = aquarium.evolve.try_to_reproduce()
	TEST_ASSERT(evolve_jr, "The test aquarium's evolution fish didn't manage to reproduce when it should have")
	TEST_ASSERT_NOTEQUAL(evolve_jr.type, /obj/item/fish/goldfish, "The test aquarium's evolution fish managed to pass the conditions of an impossible evolution")
	TEST_ASSERT_EQUAL(evolve_jr.type, /obj/item/fish/clownfish, "The test aquarium's evolution fish's offspring isn't of the expected type")
	TEST_ASSERT(!(/datum/fish_trait/dummy in evolve_jr.fish_traits), "The test aquarium's evolution fish's offspring still has the old trait that ought to be removed by the evolution datum")
	TEST_ASSERT(/datum/fish_trait/dummy/two in evolve_jr.fish_traits, "The test aquarium's evolution fish's offspring doesn't have the evolution trait")

/datum/unit_test/fish_scanning

/datum/unit_test/fish_scanning/Run()
	var/scannable_fishes = 0
	for(var/obj/item/fish/fish_prototype as anything in subtypesof(/obj/item/fish))
		if(initial(fish_prototype.fish_flags) & FISH_FLAG_EXPERIMENT_SCANNABLE)
			scannable_fishes++
	for(var/datum/experiment/scanning/fish/fish_scan as anything in typesof(/datum/experiment/scanning/fish))
		fish_scan = new fish_scan
		var/scan_key = fish_scan.required_atoms[1]
		if(fish_scan.required_atoms[scan_key] > scannable_fishes)
			TEST_FAIL("[fish_scan.type] has requirements higher than the number of scannable fish types in the game: [scannable_fishes]")

///dummy fish item used for the tests, as well with related subtypes and datums.
/obj/item/fish/testdummy
	grind_results = list()
	average_weight = FISH_GRIND_RESULTS_WEIGHT_DIVISOR * 2
	average_size = FISH_SIZE_BULKY_MAX
	num_fillets = 2
	fish_traits = list(/datum/fish_trait/dummy)
	stable_population = INFINITY
	breeding_timeout = 0
	fish_flags = parent_type::fish_flags & ~(FISH_FLAG_SHOW_IN_CATALOG|FISH_FLAG_EXPERIMENT_SCANNABLE)
	fish_id_redirect_path = /obj/item/fish/goldfish //Stops SSfishing from complaining
	var/expected_num_fillets = 0 //used to know how many fillets should be gotten out of this fish

/obj/item/fish/testdummy/small
	// The parent type is too big to reproduce inside the more compact fish tank
	average_size = /obj/item/fish_tank::max_total_size * 0.2

/obj/item/fish/testdummy/add_fillet_type()
	expected_num_fillets = ..()
	return expected_num_fillets

/obj/item/fish/testdummy/two
	fish_traits = list(/datum/fish_trait/dummy/two)

/datum/fish_trait/dummy
	incompatible_traits = list(/datum/fish_trait/dummy/two)
	inheritability = 100
	diff_traits_inheritability = 100
	reagents_to_add = list(/datum/reagent/fishdummy = FISH_REAGENT_AMOUNT)

/datum/fish_trait/dummy/apply_to_fish(obj/item/fish/fish)
	. = ..()
	ADD_TRAIT(fish, TRAIT_FISH_TESTING, FISH_TRAIT_DATUM)

/datum/fish_trait/dummy/two
	incompatible_traits = list(/datum/fish_trait/dummy)

/datum/reagent/fishdummy
	name = "fish test reagent"
	description = "It smells fishy."

/obj/structure/aquarium/traits
	var/obj/item/fish/testdummy/crossbreeder/crossbreeder
	var/obj/item/fish/testdummy/cloner/cloner
	var/obj/item/fish/testdummy/sterile/sterile

/obj/structure/aquarium/traits/Initialize(mapload)
	. = ..()
	crossbreeder = new(src)
	cloner = new(src)
	sterile = new(src)

/obj/structure/aquarium/traits/Destroy()
	crossbreeder = null
	cloner = null
	sterile = null
	return ..()

/obj/item/fish/testdummy/crossbreeder
	fish_traits = list(/datum/fish_trait/crossbreeder)

/obj/item/fish/testdummy/cloner
	fish_traits = list(/datum/fish_trait/parthenogenesis)

/obj/item/fish/testdummy/sterile
	fish_traits = list(/datum/fish_trait/no_mating)

/obj/structure/aquarium/evolution
	var/obj/item/fish/testdummy/evolve/evolve
	var/obj/item/fish/testdummy/evolve_two/evolve_two

/obj/structure/aquarium/evolution/Initialize(mapload)
	. = ..()
	evolve = new(src)
	evolve_two = new(src)

/obj/structure/aquarium/evolution/Destroy()
	evolve = null
	evolve_two = null
	return ..()

/obj/item/fish/testdummy/evolve
	compatible_types = list(/obj/item/fish/testdummy/evolve_two)
	evolution_types = list(/datum/fish_evolution/dummy)

/obj/item/fish/testdummy/evolve_two
	compatible_types = list(/obj/item/fish/testdummy/evolve)
	evolution_types = list(/datum/fish_evolution/dummy/two)

/datum/fish_evolution/dummy
	probability = 200 //Guaranteed chance even if halved.
	new_fish_type = /obj/item/fish/clownfish
	new_traits = list(/datum/fish_trait/dummy/two)
	removed_traits = list(/datum/fish_trait/dummy)
	show_on_wiki = FALSE

///This is used by both fish_evolution and fish_growth unit tests.
/datum/fish_evolution/dummy/two
	new_fish_type = /obj/item/fish/goldfish

/datum/fish_evolution/dummy/two/New()
	. = ..()
	probability = 0 //works around the global list initialization skipping abstract/impossible evolutions.

///During the fish_growth unit test, we spawn a fish outside of the aquarium and check that this actually stops it from growing
/datum/fish_evolution/dummy/two/growth_checks(obj/item/fish/source, seconds_per_tick, growth)
	. = ..()
	if(!source.loc || !HAS_TRAIT(source.loc, TRAIT_IS_AQUARIUM))
		return COMPONENT_DONT_GROW

///A test that checks that fishing portals can be linked and function as expected
/datum/unit_test/fish_portal_gen_linking

/datum/unit_test/fish_portal_gen_linking/Run()
	var/mob/living/carbon/human/consistent/user = allocate(/mob/living/carbon/human/consistent)
	var/obj/machinery/fishing_portal_generator/portal = allocate(/obj/machinery/fishing_portal_generator/no_power)
	var/obj/structure/toilet/unit_test/fishing_spot = new(get_turf(user)) //This is deleted during the test
	var/obj/structure/moisture_trap/extra_spot = allocate(/obj/structure/moisture_trap)
	var/obj/machinery/hydroponics/constructable/inaccessible = allocate(/obj/machinery/hydroponics/constructable)
	ADD_TRAIT(inaccessible, TRAIT_UNLINKABLE_FISHING_SPOT, INNATE_TRAIT)
	var/obj/item/multitool/tool = allocate(/obj/item/multitool)
	var/datum/fish_source/toilet/fish_source = GLOB.preset_fish_sources[/datum/fish_source/toilet]

	portal.max_fishing_spots = 1 //We've no scrying orb to know if it'll be buffed or nerfed this in the future. We only have space for one here.
	portal.activate(fish_source, user)
	TEST_ASSERT(!portal.active, "[portal] was activated with a fish source from an unlinked fishing spot")
	portal.multitool_act(user, tool)
	TEST_ASSERT_EQUAL(tool.buffer, portal, "[portal] wasn't set as buffer for [tool]")
	tool.melee_attack_chain(user, fishing_spot)
	TEST_ASSERT_EQUAL(LAZYACCESS(portal.linked_fishing_spots, fishing_spot), fish_source, "We tried linking [portal] to the fishing spot but didn't succeed.")
	portal.activate(fish_source, user)
	TEST_ASSERT(portal.active?.fish_source == fish_source, "[portal] can't acces a fish source from a linked fishing spot")
	//Let's move the fishing spot away. This is fine as long as the portal moves to another z level, away from the toilet
	var/turf/other_z_turf = pick(GLOB.newplayer_start)
	portal.forceMove(other_z_turf)
	TEST_ASSERT(!portal.active, "[portal] (not upgraded) is still active though the fishing spot is on another z-level.[portal.z == fishing_spot.z ? " Actually they're still on the same level!" : ""]")
	portal.long_range_link = TRUE
	portal.activate(fish_source, user)
	TEST_ASSERT(portal.active?.fish_source == fish_source, "[portal] can't acces a fish source from a linked fishing spot on a different z-level despite being upgraded")
	fishing_spot.forceMove(other_z_turf)
	portal.forceMove(get_turf(user))
	TEST_ASSERT(portal.active?.fish_source == fish_source, "[portal] (upgraded) deactivated while changing z-level")
	tool.melee_attack_chain(user, extra_spot)
	TEST_ASSERT_EQUAL(length(portal.linked_fishing_spots), 1, "We managed to link to another fishing spot when there's only space for one")
	TEST_ASSERT_EQUAL(LAZYACCESS(portal.linked_fishing_spots, fishing_spot), fish_source, "linking to another fishing spot fouled up the other linked spots")
	QDEL_NULL(fishing_spot)
	TEST_ASSERT(!portal.active, "[portal] is still linked to the fish source of the deleted fishing spot it's associated to")
	tool.melee_attack_chain(user, inaccessible)
	TEST_ASSERT(!length(portal.linked_fishing_spots), "We managed to link to an unlinkable fishing spot")

/obj/machinery/fishing_portal_generator/no_power
	use_power = NO_POWER_USE

/obj/structure/toilet/unit_test/Initialize(mapload)
	. = ..()
	if(!HAS_TRAIT(src, TRAIT_FISHING_SPOT)) //Ensure this toilet has a fishing spot because only maploaded ones have it.
		AddComponent(/datum/component/fishing_spot, GLOB.preset_fish_sources[/datum/fish_source/toilet])

// we want no default spawns in this unit test
/datum/chasm_detritus/restricted/bodies/no_defaults
	default_contents_chance = 0

/// Checks that we are able to fish people out of chasms with priority and that they end up in the right location
/datum/unit_test/fish_rescue_hook
	priority = TEST_LONGER
	var/original_turf_type
	var/original_turf_baseturfs
	var/list/mobs_spawned

/datum/unit_test/fish_rescue_hook/Run()
	// create our human dummies to be dropped into the chasm
	var/mob/living/carbon/human/consistent/get_in_the_hole = allocate(/mob/living/carbon/human/consistent)
	var/mob/living/basic/mining/lobstrosity/you_too = allocate(/mob/living/basic/mining/lobstrosity)
	var/mob/living/carbon/human/consistent/mindless = allocate(/mob/living/carbon/human/consistent)
	var/mob/living/carbon/human/consistent/no_brain = allocate(/mob/living/carbon/human/consistent)
	var/mob/living/carbon/human/consistent/empty = allocate(/mob/living/carbon/human/consistent)
	var/mob/living/carbon/human/consistent/dummy = allocate(/mob/living/carbon/human/consistent)

	mobs_spawned = list(
		get_in_the_hole,
		you_too,
		mindless,
		no_brain,
		empty,
		dummy,
	)

	// create our chasm and remember the previous turf so we can change it back once we're done
	original_turf_type = run_loc_floor_bottom_left.type
	original_turf_baseturfs = islist(run_loc_floor_bottom_left.baseturfs) ? run_loc_floor_bottom_left.baseturfs.Copy() : run_loc_floor_bottom_left.baseturfs
	run_loc_floor_bottom_left.ChangeTurf(/turf/open/chasm)
	var/turf/open/chasm/the_hole = run_loc_floor_bottom_left

	// into the hole they go
	for(var/mob/mob_spawned in mobs_spawned)
		the_hole.drop(mob_spawned)
		sleep(0.2 SECONDS) // we have to WAIT because the drop() proc sleeps.

	// our 'fisherman' where we expect the item to be moved to after fishing it up
	var/mob/living/carbon/human/consistent/a_fisherman = allocate(/mob/living/carbon/human/consistent, run_loc_floor_top_right)

	// pretend like this mob has a mind. they should be fished up first
	no_brain.mind_initialize()

	var/datum/component/fishing_spot/the_hole_fishing_spot = the_hole.GetComponent(/datum/component/fishing_spot)
	var/datum/fish_source/fishing_source = the_hole_fishing_spot.fish_source
	var/obj/item/fishing_hook/rescue/the_hook = allocate(/obj/item/fishing_hook/rescue, run_loc_floor_top_right)
	the_hook.chasm_detritus_type = /datum/chasm_detritus/restricted/bodies/no_defaults

	// try to fish up our minded victim
	var/atom/movable/reward = fishing_source.dispense_reward(the_hook.chasm_detritus_type, a_fisherman, the_hole)

	// mobs with minds (aka players) should have precedence over any other mobs that are in the chasm
	TEST_ASSERT_EQUAL(reward, no_brain, "Fished up [reward] ([REF(reward)]) with a rescue hook; expected to fish up [no_brain]([REF(no_brain)])")
	// it should end up on the same turf as the fisherman
	TEST_ASSERT_EQUAL(get_turf(reward), get_turf(a_fisherman), "[reward] was fished up with the rescue hook and ended up at [get_turf(reward)]; expected to be at [get_turf(a_fisherman)]")

	// let's further test that by giving a second mob a mind. they should be fished up immediately..
	empty.mind_initialize()

	reward = fishing_source.dispense_reward(the_hook.chasm_detritus_type, a_fisherman, the_hole)

	TEST_ASSERT_EQUAL(reward, empty, "Fished up [reward]([REF(reward)]) with a rescue hook; expected to fish up [empty]([REF(empty)])")
	TEST_ASSERT_EQUAL(get_turf(reward), get_turf(a_fisherman), "[reward] was fished up with the rescue hook and ended up at [get_turf(reward)]; expected to be at [get_turf(a_fisherman)]")

// clean up so we don't mess up subsequent tests
/datum/unit_test/fish_rescue_hook/Destroy()
	QDEL_LIST(mobs_spawned)
	run_loc_floor_bottom_left.ChangeTurf(original_turf_type, original_turf_baseturfs)
	return ..()

///Check that the fish growth component works.
/datum/unit_test/fish_growth

/datum/unit_test/fish_growth/Run()
	var/obj/structure/aquarium/crab/aquarium = allocate(/obj/structure/aquarium/crab)
	var/list/growth_comps = aquarium.crabbie.GetComponents(/datum/component/fish_growth) //Can't use GetComponent() without s because the comp is dupe-selective
	var/datum/component/fish_growth/crab_growth = growth_comps[1]

	crab_growth.on_fish_life(aquarium.crabbie, seconds_per_tick = 1) //give the fish growth component a small push.

	var/mob/living/basic/mining/lobstrosity/juvenile/lobster = locate() in aquarium.loc
	TEST_ASSERT(lobster, "The lobstrosity didn't spawn at all. chasm crab maturation: [crab_growth.maturation]%.")
	TEST_ASSERT_EQUAL(lobster.loc, get_turf(aquarium), "The lobstrosity didn't spawn on the aquarium's turf")
	TEST_ASSERT(QDELETED(aquarium.crabbie), "The test aquarium's chasm crab didn't delete itself.")
	TEST_ASSERT_EQUAL(lobster.name, "Crabbie", "The lobstrosity didn't inherit the aquarium chasm crab's custom name")
	allocated |= lobster //make sure it's allocated and thus properly deleted when the test is over

	//While ideally impossible to have all traits because of incompatible ones, I want to be sure they don't error out.
	for(var/trait_type in GLOB.fish_traits)
		var/datum/fish_trait/trait = GLOB.fish_traits[trait_type]
		trait.apply_to_mob(lobster)

	var/obj/item/fish/testdummy/dummy = allocate(/obj/item/fish/testdummy)
	var/datum/component/fish_growth/dummy_growth = dummy.AddComponent(/datum/component/fish_growth, /datum/fish_evolution/dummy/two, 1 SECONDS, use_drop_loc = FALSE)
	dummy.last_feeding = world.time
	dummy_growth.on_fish_life(dummy, seconds_per_tick = 1)
	TEST_ASSERT(!QDELETED(dummy), "The fish has grown when it shouldn't have")
	dummy.forceMove(aquarium)
	dummy_growth.on_fish_life(dummy, seconds_per_tick = 1)
	var/obj/item/fish/dummy_boogaloo = locate(/datum/fish_evolution/dummy/two::new_fish_type) in aquarium
	TEST_ASSERT(dummy_boogaloo, "The new fish type cannot be found inside the aquarium")

/obj/structure/aquarium/crab
	///Our test subject
	var/obj/item/fish/chasm_crab/instant_growth/crabbie

/obj/structure/aquarium/crab/Initialize(mapload)
	. = ..()
	crabbie = new(src)
	crabbie.AddComponent(/datum/component/rename, "Crabbie", crabbie.desc)
	crabbie.last_feeding = world.time
	crabbie.AddComponent(/datum/component/fish_growth, crabbie.lob_type, 1 SECONDS)

/obj/structure/aquarium/crab/Exited(atom/movable/gone)
	. = ..()
	if(gone == crabbie) //the fish item is deleted once it grows up
		crabbie = null

/obj/item/fish/chasm_crab/instant_growth
	fish_traits = list() //We don't want to end up applying traits twice on the resulting lobstrosity
	fish_id_redirect_path = /obj/item/fish/chasm_crab

/datum/unit_test/fish_sources

/datum/unit_test/fish_sources/Run()
	var/datum/fish_source/source = GLOB.preset_fish_sources[/datum/fish_source/unit_test_explosive]
	source.spawn_reward_from_explosion(run_loc_floor_bottom_left, 1)
	if(source.fish_counts[/obj/item/wrench])
		TEST_FAIL("The unit test item wasn't removed/spawned from fish_table during 'spawn_reward_from_explosion'.")

	///From here, we check that the profound_fisher as well as fish source procs for rolling rewards don't fail.
	source = GLOB.preset_fish_sources[/datum/fish_source/unit_test_profound_fisher]

	run_loc_floor_bottom_left.AddComponent(/datum/component/fishing_spot, source)
	var/mob/living/basic/fisher = allocate(/mob/living/basic)
	fisher.AddComponent(/datum/component/profound_fisher)
	fisher.set_combat_mode(FALSE)
	fisher.melee_attack(run_loc_floor_bottom_left, ignore_cooldown = TRUE)
	if(source.fish_counts[/obj/item/fish/testdummy] != 1)
		TEST_FAIL("The unit test profound fisher didn't catch the test fish on a lazy fishing spot (element)")

	///For good measure, let's try it again, but with the component this time, and a human mob and gloves
	qdel(run_loc_floor_bottom_left.GetComponent(/datum/component/fishing_spot))
	var/datum/component/comp = run_loc_floor_bottom_left.AddComponent(/datum/component/fishing_spot, source)
	var/mob/living/carbon/human/consistent/angler = allocate(/mob/living/carbon/human/consistent)
	var/obj/item/clothing/gloves/noodling = allocate(/obj/item/clothing/gloves)
	noodling.AddComponent(/datum/component/profound_fisher)
	angler.equip_to_slot(noodling, ITEM_SLOT_GLOVES)

	angler.UnarmedAttack(run_loc_floor_bottom_left, proximity_flag = TRUE)
	if(source.fish_counts[/obj/item/fish/testdummy])
		TEST_FAIL("The unit test profound fisher didn't catch the test fish on a fishing spot (component)")
	qdel(comp)

	///As a final test, let's see how it goes with a fish source containing every single fish subtype.
	comp = run_loc_floor_bottom_left.AddComponent(/datum/component/fishing_spot, GLOB.preset_fish_sources[/datum/fish_source/unit_test_all_fish])
	fisher.melee_attack(run_loc_floor_bottom_left, ignore_cooldown = TRUE)
	qdel(comp)

/datum/fish_source/unit_test_explosive
	fish_table = list(
		/obj/item/wrench = 1,
		/obj/item/screwdriver = INFINITY, //infinite weight, so if fish counts doesn't work as intended, this'll be always picked.
	)
	fish_counts = list(
		/obj/item/wrench = 1,
		/obj/item/screwdriver = 0, //this should never be picked.
	)

/datum/fish_source/unit_test_profound_fisher
	fish_table = list(/obj/item/fish/testdummy = 1)
	fish_counts = list(/obj/item/fish/testdummy = 2)
	fish_source_flags = parent_type::fish_source_flags

/datum/fish_source/unit_test_all_fish
	fish_source_flags = parent_type::fish_source_flags

/datum/fish_source/unit_test_all_fish/New()
	for(var/fish_type as anything in subtypesof(/obj/item/fish))
		fish_table[fish_type] = 10
	return ..()

/datum/unit_test/edible_fish

/datum/unit_test/edible_fish/Run()
	var/obj/item/fish/fish = allocate(/obj/item/fish/testdummy/food)
	var/datum/component/edible/edible = fish.GetComponent(/datum/component/edible)
	TEST_ASSERT(edible, "Fish is not edible")
	edible.eat_time = 0
	TEST_ASSERT(fish.GetComponent(/datum/component/infective), "Fish doesn't have the infective component")
	var/bite_size = edible.bite_consumption

	var/mob/living/carbon/human/consistent/gourmet = allocate(/mob/living/carbon/human/consistent)

	var/food_quality = edible.get_perceived_food_quality(gourmet)
	TEST_ASSERT(food_quality < 0, "Humans don't seem to dislike raw, unprocessed fish when they should")
	ADD_TRAIT(gourmet, TRAIT_FISH_EATER, TRAIT_FISH_TESTING)
	food_quality = edible.get_perceived_food_quality(gourmet)
	TEST_ASSERT(food_quality >= LIKED_FOOD_QUALITY_CHANGE, "mobs with the TRAIT_FISH_EATER traits don't seem to like fish when they should")
	REMOVE_TRAIT(gourmet, TRAIT_FISH_EATER, TRAIT_FISH_TESTING)

	fish.attack(gourmet, gourmet)
	TEST_ASSERT(gourmet.has_reagent(/datum/reagent/consumable/nutriment/protein), "Human doesn't have ingested protein after eating fish")
	TEST_ASSERT(gourmet.has_reagent(/datum/reagent/blood), "Human doesn't have ingested blood after eating fish")
	TEST_ASSERT(gourmet.has_reagent(/datum/reagent/fishdummy), "Human doesn't have the reagent from /datum/fish_trait/dummy after eating fish")

	TEST_ASSERT_EQUAL(fish.status, FISH_DEAD, "The fish is not dead, despite having sustained enough damage that it should. health: [fish.health]")

	var/obj/item/organ/stomach/belly = gourmet.get_organ_slot(ORGAN_SLOT_STOMACH)
	belly.reagents.clear_reagents()

	fish.set_status(FISH_ALIVE)
	TEST_ASSERT(!fish.bites_amount, "bites_amount wasn't reset after the fish revived")

	fish.update_size_and_weight(fish.size, FISH_WEIGHT_BITE_DIVISOR)
	fish.AddElement(/datum/element/fried_item, FISH_SAFE_COOKING_DURATION)
	TEST_ASSERT_EQUAL(fish.status, FISH_DEAD, "The fish didn't die after being cooked")
	TEST_ASSERT(bite_size < edible.bite_consumption, "The bite_consumption value hasn't increased after being cooked (it removes blood but doubles protein). Value: [bite_size]")
	TEST_ASSERT(!(edible.foodtypes & (RAW|GORE)), "Fish still has the GORE and/or RAW foodtypes flags after being cooked")
	TEST_ASSERT(!fish.GetComponent(/datum/component/infective), "Fish still has the infective component after being cooked for long enough")


	food_quality = edible.get_perceived_food_quality(gourmet)
	TEST_ASSERT(food_quality >= 0, "Humans still dislike fish, even when it's cooked")
	fish.attack(gourmet, gourmet)
	TEST_ASSERT(!gourmet.has_reagent(/datum/reagent/blood), "Human has ingested blood from eating a fish when it shouldn't since the fish has been cooked")

	TEST_ASSERT(QDELETED(fish), "The fish is not being deleted, despite having sustained enough bites. Reagents volume left: [fish.reagents.total_volume]")

/obj/item/fish/testdummy/food
	average_weight = FISH_WEIGHT_BITE_DIVISOR * 2 //One bite, it's death; the other, it's gone.

///Check that nothing wrong happens when randomizing size and weight of a fish
/datum/unit_test/fish_randomize_size_weight

/datum/unit_test/fish_randomize_size_weight/Run()
	var/obj/item/storage/box/fish_debug/box = allocate(/obj/item/storage/box/fish_debug)
	for(var/obj/item/fish/fish as anything in box)
		fish.randomize_size_and_weight()

/datum/unit_test/aquarium_upgrade

/datum/unit_test/aquarium_upgrade/Run()
	var/mob/living/carbon/human/dummy/user = allocate(__IMPLIED_TYPE__)
	var/obj/item/aquarium_upgrade/bioelec_gen/upgrade = allocate(__IMPLIED_TYPE__)
	var/obj/structure/aquarium/aquarium = allocate(upgrade::upgrade_from_type)

	var/datum/component/aquarium/comp = aquarium.GetComponent(__IMPLIED_TYPE__)
	TEST_ASSERT(comp, "[aquarium.type] doesn't have an aquarium component")
	comp.set_fluid_type(AQUARIUM_FLUID_AIR)
	comp.fluid_temp = MAX_AQUARIUM_TEMP
	aquarium.add_traits(list(TRAIT_AQUARIUM_PANEL_OPEN, TRAIT_STOP_FISH_REPRODUCTION_AND_GROWTH), AQUARIUM_TRAIT)

	var/type_to_check = upgrade::upgrade_to_type
	var/turf/aquarium_loc = aquarium.loc
	user.put_in_hands(upgrade)
	upgrade.melee_attack_chain(user, aquarium)
	TEST_ASSERT(QDELETED(aquarium), "Old [aquarium.type] was not deleted after upgrade")

	var/obj/structure/aquarium/upgraded_aquarium = locate(type_to_check) in aquarium_loc
	TEST_ASSERT(upgraded_aquarium, "New [upgraded_aquarium.type] was not spawned after upgrade")
	comp = upgraded_aquarium.GetComponent(/datum/component/aquarium)
	TEST_ASSERT(comp, "New [upgraded_aquarium.type] doesn't have an aquarium component")

	TEST_ASSERT_EQUAL(comp.fluid_type, AQUARIUM_FLUID_AIR, "Inherited aquarium fluid type should be [AQUARIUM_FLUID_AIR]")
	TEST_ASSERT_EQUAL(comp.fluid_temp, MAX_AQUARIUM_TEMP, "Inherited aquarium fluid temperature should be [MAX_AQUARIUM_TEMP]")
	TEST_ASSERT(HAS_TRAIT(upgraded_aquarium, TRAIT_AQUARIUM_PANEL_OPEN), "The new aquarium should have its panel open")
	TEST_ASSERT(HAS_TRAIT(upgraded_aquarium, TRAIT_STOP_FISH_REPRODUCTION_AND_GROWTH), "The 'growth and reproduction' setting for this aquarium should be disabled")

	TEST_ASSERT(QDELETED(upgrade), "Aquarium upgrade wasn't deleted afterward")

#undef FISH_REAGENT_AMOUNT
#undef TRAIT_FISH_TESTING
