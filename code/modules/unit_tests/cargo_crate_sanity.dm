/**
 * This unit test loops through all cargo crates that are available to purchase, and confirms that they're below the expected sanity minimum when sold.
 * This prevents us from merging a crate that sells for more that it costs to buy.
 */

/datum/unit_test/cargo_crate_sanity

/datum/unit_test/cargo_crate_sanity/Run()
	for(var/crate in subtypesof(/datum/supply_pack))
		var/datum/supply_pack/new_crate = new crate
		if(new_crate.abstract)
			continue // We can safely ignore custom supply packs like the stock market or mining supply crates.
		if(!new_crate?.crate_type)
			continue
		var/obj/crate_type = allocate(new_crate.crate_type)
		var/datum/export_report/minimum_cost = export_item_and_contents(crate_type, dry_run = TRUE)
		var/crate_value = counterlist_sum(minimum_cost.total_value)
		var/turf/open/floor/testing_floor = EASY_ALLOCATE()

		var/obj/results = new_crate.generate(testing_floor)
		var/datum/export_report/export_log = export_item_and_contents(results, apply_elastic = TRUE)

		// The value of the crate and all of it's contents.
		var/value = counterlist_sum(export_log.total_value)

		// We're selling the crate and it's contents for more value than it's supply_pack costs.
		if(value > new_crate.get_cost())
			TEST_FAIL("Cargo crate [new_crate.type] had a sale value of [value], Selling for more than [new_crate.get_cost()], the cost to buy")

		// We're selling the crate & it's contents for less than the value of it's own crate, meaning you can buy and infinite number
		if(crate_value > new_crate.get_cost())
			TEST_FAIL("Cargo crate [new_crate.type] container sells for [crate_value], Selling for more than [new_crate.get_cost()], the cost to buy")
		for(var/atom/stuff as anything in results.contents)
			qdel(stuff)
		qdel(results)
