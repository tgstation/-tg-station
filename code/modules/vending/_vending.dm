/*
 * Vending machine types - Can be found under /code/modules/vending/
 */

/*

/obj/machinery/vending/[vendors name here]   // --vending machine template   :)
	name = ""
	desc = ""
	icon = ''
	icon_state = ""
	products = list()
	contraband = list()
	premium = list()
*/

/// List of vending machines that players can restock, so only vending machines that are on station or don't have a unique condition.
GLOBAL_LIST_EMPTY(vending_machines_to_restock)

/// Maximum amount of items in a storage bag that we're transferring items to the vendor from.
#define MAX_VENDING_INPUT_AMOUNT 30
#define CREDITS_DUMP_THRESHOLD 50
/**
 * # vending record datum
 *
 * A datum that represents a product that is vendable
 */
/datum/data/vending_product
	name = "generic"
	///Typepath of the product that is created when this record "sells"
	var/product_path = null
	///How many of this product we currently have
	var/amount = 0
	///How many we can store at maximum
	var/max_amount = 0
	///The price of the item
	var/price
	///Whether spessmen with an ID with an age below AGE_MINOR (20 by default) can buy this item
	var/age_restricted = FALSE
	///Whether the product can be recolored by the GAGS system
	var/colorable
	/// The category the product was in, if any.
	/// Sourced directly from product_categories.
	var/category
	///List of items that have been returned to the vending machine.
	var/list/returned_products

/**
 * # vending machines
 *
 * Captalism in the year 2525, everything in a vending machine, even love
 */
/obj/machinery/vending
	name = "\improper Vendomat"
	desc = "A generic vending machine."
	icon = 'icons/obj/machines/vending.dmi'
	icon_state = "generic"
	layer = BELOW_OBJ_LAYER
	density = TRUE
	verb_say = "beeps"
	verb_ask = "beeps"
	verb_exclaim = "beeps"
	max_integrity = 300
	integrity_failure = 0.33
	armor_type = /datum/armor/machinery_vending
	circuit = /obj/item/circuitboard/machine/vendor
	payment_department = ACCOUNT_SRV
	light_power = 0.7
	light_range = MINIMUM_USEFUL_LIGHT_RANGE
	voice_filter = "alimiter=0.9,acompressor=threshold=0.2:ratio=20:attack=10:release=50:makeup=2,highpass=f=1000"

	/// Is the machine active (No sales pitches if off)!
	var/active = 1
	///Are we ready to vend?? Is it time??
	var/vend_ready = TRUE
	///Next world time to send a purchase message
	var/purchase_message_cooldown
	///The ref of the last mob to shop with us
	var/last_shopper
	///Whether the vendor is tilted or not
	var/tilted = FALSE
	/// If tilted, this variable should always be the rotation that was applied when we were tilted. Stored for the purposes of unapplying it.
	var/tilted_rotation = 0
	///Whether this vendor can be tilted over or not
	var/tiltable = TRUE
	///Damage this vendor does when tilting onto an atom
	var/squish_damage = 75
	/// The chance, in percent, of this vendor performing a critical hit on anything it crushes via [tilt].
	var/crit_chance = 15
	/// If set to a critical define in crushing.dm, anything this vendor crushes will always be hit with that effect.
	var/forcecrit = null
	///Number of glass shards the vendor creates and tries to embed into an atom it tilted onto
	var/num_shards = 7
	///List of mobs stuck under the vendor
	var/list/pinned_mobs = list()
	///Icon for the maintenance panel overlay
	var/panel_type = "panel1"

	/**
	  * List of products this machine sells
	  *
	  * form should be list(/type/path = amount, /type/path2 = amount2)
	  */
	var/list/products = list()

	/**
	 * List of products this machine sells, categorized.
	 * Can only be used as an alternative to `products`, not alongside it.
	 *
	 * Form should be list(
	 * 	"name" = "Category Name",
	 * 	"icon" = "UI Icon (Font Awesome or tgfont)",
	 * 	"products" = list(/type/path = amount, ...),
	 * )
	 */
	var/list/product_categories = null

	/**
	  * List of products this machine sells when you hack it
	  *
	  * form should be list(/type/path = amount, /type/path2 = amount2)
	  */
	var/list/contraband = list()

	/**
	  * List of premium products this machine sells
	  *
	  * form should be list(/type/path = amount, /type/path2 = amount2)
	  */
	var/list/premium = list()

	///String of slogans separated by semicolons, optional
	var/product_slogans = ""
	///String of small ad messages in the vending screen - random chance
	var/product_ads = ""

	///List of standard product records
	var/list/product_records = list()
	///List of contraband product records
	var/list/hidden_records = list()
	///List of premium product records
	var/list/coin_records = list()
	///List of slogans to scream at potential customers; built upon Iniitialize() of the vendor from product_slogans
	var/list/slogan_list = list()
	///Message sent post vend (Thank you for shopping!)
	var/vend_reply
	///Last world tick we sent a vent reply
	var/last_reply = 0
	///Last world tick we sent a slogan message out
	var/last_slogan = 0
	///How many ticks until we can send another
	var/slogan_delay = 10 MINUTES
	///Icon when vending an item to the user
	var/icon_vend
	///Icon to flash when user is denied a vend
	var/icon_deny
	///World ticks the machine is electified for
	var/seconds_electrified = MACHINE_NOT_ELECTRIFIED
	///When this is TRUE, we fire items at customers! We're broken!
	var/shoot_inventory = FALSE
	///How likely this is to happen (prob 100) per second
	var/shoot_inventory_chance = 1
	//Stop spouting those godawful pitches!
	var/shut_up = FALSE
	///can we access the hidden inventory?
	var/extended_inventory = FALSE
	///Are we checking the users ID
	var/scan_id = TRUE
	///Coins that we accept?
	var/obj/item/coin/coin
	///Bills we accept?
	var/obj/item/stack/spacecash/bill
	///Default price of items if not overridden
	var/default_price = 25
	///Default price of premium items if not overridden
	var/extra_price = 50
	///fontawesome icon name to use in to display the user's balance in the vendor UI
	var/displayed_currency_icon = "coins"
	///String of the used currency to display in the vendor UI
	var/displayed_currency_name = " cr"
	///Whether our age check is currently functional
	var/age_restrictions = TRUE
	/// How many credits does this vending machine have? 20% of all sales go to this pool, and are given freely when the machine is restocked, or successfully tilted. Lost on deconstruction.
	var/credits_contained = 0
	/**
	  * Is this item on station or not
	  *
	  * if it doesn't originate from off-station during mapload, all_products_free gets automatically set to TRUE if it was unset previously.
	  * if it's off-station during mapload, it's also safe from the brand intelligence event
	  */
	var/onstation = TRUE
	/**
	 * DO NOT APPLY THIS GLOBALLY. For mapping var edits only.
	 * A variable to change on a per instance basis that allows the instance to avoid having onstation set for them during mapload.
	 * Setting this to TRUE means that the vending machine is treated as if it were still onstation if it spawns off-station during mapload.
	 * Useful to specify an off-station machine that will be affected by machine-brand intelligence for whatever reason.
	 */
	var/onstation_override = FALSE
	/**
	 * If this is set to TRUE, all products sold by the vending machine are free (cost nothing).
	 * If unset, this will get automatically set to TRUE during init if the machine originates from off-station during mapload.
	 * Defaults to null, set it to TRUE or FALSE explicitly on a per-machine basis if you want to force it to be a certain value.
	 */
	var/all_products_free

	///Items that the players have loaded into the vendor
	var/list/vending_machine_input = list()

	//The type of refill canisters used by this machine.
	var/obj/item/vending_refill/refill_canister = null

	/// how many items have been inserted in a vendor
	var/loaded_items = 0

	///Name of lighting mask for the vending machine
	var/light_mask

	//the path of the fish_source datum to use for the fishing_spot component
	var/fish_source_path = /datum/fish_source/vending

/datum/armor/machinery_vending
	melee = 20
	fire = 50
	acid = 70

/**
 * Initialize the vending machine
 *
 * Builds the vending machine inventory, sets up slogans and other such misc work
 *
 * This also sets the onstation var to:
 * * FALSE - if the machine was maploaded on a zlevel that doesn't pass the is_station_level check
 * * TRUE - all other cases
 */
/obj/machinery/vending/Initialize(mapload)
	var/build_inv = FALSE
	if(!refill_canister)
		circuit = null
		build_inv = TRUE
	. = ..()
	set_wires(new /datum/wires/vending(src))

	if(SStts.tts_enabled)
		var/static/vendor_voice_by_type = list()
		if(!vendor_voice_by_type[type])
			vendor_voice_by_type[type] = pick(SStts.available_speakers)
		voice = vendor_voice_by_type[type]

	if(build_inv) //non-constructable vending machine
		///Non-constructible vending machines do not have a refill canister to populate its products list from,
		///Which apparently is still needed in the case we use product categories instead.
		if(product_categories)
			for(var/list/category as anything in product_categories)
				products |= category["products"]
		build_inventories()

	slogan_list = splittext(product_slogans, ";")
	// So not all machines speak at the exact same time.
	// The first time this machine says something will be at slogantime + this random value,
	// so if slogantime is 10 minutes, it will say it at somewhere between 10 and 20 minutes after the machine is crated.
	last_slogan = world.time + rand(0, slogan_delay)
	power_change()

	if(mapload) //check if it was initially created off station during mapload.
		if(!is_station_level(z))
			if(!onstation_override)
				onstation = FALSE
				if(isnull(all_products_free)) // Only auto-set the free products var if we haven't explicitly assigned a value to it yet.
					all_products_free = TRUE
			if(circuit)
				circuit.all_products_free = all_products_free //sync up the circuit so the pricing schema is carried over if it's reconstructed.

	else if(circuit)
		all_products_free = circuit.all_products_free //if it was constructed outside mapload, sync the vendor up with the circuit's var so you can't bypass price requirements by moving / reconstructing it off station.
	if(!all_products_free)
		AddComponent(/datum/component/payment, 0, SSeconomy.get_dep_account(payment_department), PAYMENT_VENDING)
		GLOB.vending_machines_to_restock += src //We need to keep track of the final onstation vending machines so we can keep them restocked.
	register_context()

	if(fish_source_path)
		AddComponent(/datum/component/fishing_spot, fish_source_path)

/obj/machinery/vending/Destroy()
	QDEL_NULL(coin)
	QDEL_NULL(bill)
	GLOB.vending_machines_to_restock -= src
	return ..()

/obj/machinery/vending/vv_edit_var(vname, vval)
	. = ..()
	if (vname == NAMEOF(src, all_products_free))
		if (all_products_free)
			qdel(GetComponent(/datum/component/payment))
			GLOB.vending_machines_to_restock -= src
		else
			AddComponent(/datum/component/payment, 0, SSeconomy.get_dep_account(payment_department), PAYMENT_VENDING)
			GLOB.vending_machines_to_restock += src

/obj/machinery/vending/can_speak(allow_mimes)
	return is_operational && !shut_up && ..()

/obj/machinery/vending/emp_act(severity)
	. = ..()
	var/datum/language_holder/vending_languages = get_language_holder()
	var/datum/wires/vending/vending_wires = wires
	// if the language wire got pulsed during an EMP, this will make sure the language_iterator is synched correctly
	vending_languages.selected_language = vending_languages.spoken_languages[vending_wires.language_iterator]

//Better would be to make constructable child
/obj/machinery/vending/RefreshParts()
	SHOULD_CALL_PARENT(FALSE)
	if(!component_parts)
		return

	build_products_from_categories()

	product_records = list()
	hidden_records = list()
	coin_records = list()

	build_inventories(start_empty = TRUE)

	for(var/obj/item/vending_refill/installed_refill in component_parts)
		restock(installed_refill)

/obj/machinery/vending/on_deconstruction(disassembled)
	if(refill_canister)
		return ..()
	new /obj/item/stack/sheet/iron(loc, 3)

/obj/machinery/vending/update_appearance(updates=ALL)
	. = ..()
	if(machine_stat & BROKEN)
		set_light(0)
		return
	set_light(powered() ? MINIMUM_USEFUL_LIGHT_RANGE : 0)

/obj/machinery/vending/update_icon_state()
	if(machine_stat & BROKEN)
		icon_state = "[initial(icon_state)]-broken"
		return ..()
	icon_state = "[initial(icon_state)][powered() ? null : "-off"]"
	return ..()

/obj/machinery/vending/update_overlays()
	. = ..()
	if(panel_open)
		. += panel_type
	if(light_mask && !(machine_stat & BROKEN) && powered())
		. += emissive_appearance(icon, light_mask, src)

/obj/machinery/vending/examine(mob/user)
	. = ..()
	if(isnull(refill_canister))
		return // you can add the comment here instead
	if(total_max_stock())
		if(total_loaded_stock() < total_max_stock())
			. += span_notice("\The [src] can be restocked with [span_boldnotice("\a [initial(refill_canister.machine_name)] [initial(refill_canister.name)]")] with the panel open.")
		else
			. += span_notice("\The [src] is fully stocked.")
	if(credits_contained < CREDITS_DUMP_THRESHOLD && credits_contained > 0)
		. += span_notice("It should have a handfull of credits stored based on the missing items.")
	else if (credits_contained > PAYCHECK_CREW)
		. += span_notice("It should have at least a full paycheck worth of credits inside!")
		/**
		 * Intentionally leaving out a case for zero credits as it should be covered by the vending machine's stock being full,
		 * or covered by first case if items were returned.
		 */


/obj/machinery/vending/atom_break(damage_flag)
	. = ..()
	if(!.)
		return

	var/dump_amount = 0
	var/found_anything = TRUE
	while (found_anything)
		found_anything = FALSE
		for(var/datum/data/vending_product/record as anything in shuffle(product_records))
			//first dump any of the items that have been returned, in case they contain the nuke disk or something
			for(var/obj/returned_obj_to_dump in record.returned_products)
				LAZYREMOVE(record.returned_products, returned_obj_to_dump)
				returned_obj_to_dump.forceMove(get_turf(src))
				step(returned_obj_to_dump, pick(GLOB.alldirs))
				record.amount--

			if(record.amount <= 0) //Try to use a record that actually has something to dump.
				continue
			var/dump_path = record.product_path
			if(!dump_path)
				continue
			// busting open a vendor will destroy some of the contents
			if(found_anything && prob(80))
				record.amount--
				continue

			var/obj/obj_to_dump = dispense(record, loc)
			step(obj_to_dump, pick(GLOB.alldirs))
			found_anything = TRUE
			dump_amount++
			if (dump_amount >= 16)
				return

/**
 * Build the inventory of the vending machine from its product and record lists
 *
 * This builds up a full set of /datum/data/vending_products from the product list of the vending machine type
 * Arguments:
 * * productlist - the list of products that need to be converted
 * * recordlist - the list containing /datum/data/vending_product datums
 * * categories - A list in the format of product_categories to source category from
 * * startempty - should we set vending_product record amount from the product list (so it's prefilled at roundstart)
 * * premium - Whether the ending products shall have premium or default prices
 */
/obj/machinery/vending/proc/build_inventory(list/productlist, list/recordlist, list/categories, start_empty = FALSE, premium = FALSE)
	var/inflation_value = HAS_TRAIT(SSeconomy, TRAIT_MARKET_CRASHING) ? SSeconomy.inflation_value() : 1
	default_price = round(initial(default_price) * inflation_value)
	extra_price = round(initial(extra_price) * inflation_value)

	var/list/product_to_category = list()
	for (var/list/category as anything in categories)
		var/list/products = category["products"]
		for (var/product_key in products)
			product_to_category[product_key] = category

	for(var/typepath in productlist)
		var/amount = productlist[typepath]
		if(isnull(amount))
			amount = 0

		var/obj/item/temp = typepath
		var/datum/data/vending_product/new_record = new /datum/data/vending_product()
		new_record.name = initial(temp.name)
		new_record.product_path = typepath
		if(!start_empty)
			new_record.amount = amount
		new_record.max_amount = amount

		///Prices of vending machines are all increased uniformly.
		var/custom_price = round(initial(temp.custom_price) * inflation_value)
		if(!premium)
			new_record.price = custom_price || default_price
		else
			var/premium_custom_price = round(initial(temp.custom_premium_price) * inflation_value)
			if(!premium_custom_price && custom_price) //For some ungodly reason, some premium only items only have a custom_price
				new_record.price = extra_price + custom_price
			else
				new_record.price = premium_custom_price || extra_price

		new_record.age_restricted = initial(temp.age_restricted)
		new_record.colorable = !!(initial(temp.greyscale_config) && initial(temp.greyscale_colors) && (initial(temp.flags_1) & IS_PLAYER_COLORABLE_1))
		new_record.category = product_to_category[typepath]
		recordlist += new_record

/**Builds all available inventories for the vendor - standard, contraband and premium
 * Arguments:
 * start_empty - bool to pass into build_inventory that determines whether a product entry starts with available stock or not
*/
/obj/machinery/vending/proc/build_inventories(start_empty)
	build_inventory(products, product_records, product_categories, start_empty)
	build_inventory(contraband, hidden_records, create_categories_from("Contraband", "mask", contraband), start_empty, premium = TRUE)
	build_inventory(premium, coin_records, create_categories_from("Premium", "coins", premium), start_empty, premium = TRUE)

/**
 * Returns a list of data about the category
 * Arguments:
 * name - string for the name of the category
 * icon - string for the fontawesome icon to use in the UI for the category
 * products - list of products available in the category
*/
/obj/machinery/vending/proc/create_categories_from(name, icon, products)
	return list(list(
		"name" = name,
		"icon" = icon,
		"products" = products,
	))

///Populates list of products with categorized products
/obj/machinery/vending/proc/build_products_from_categories()
	if (isnull(product_categories))
		return

	products = list()

	for (var/list/category in product_categories)
		var/list/category_products = category["products"]
		for (var/product_key in category_products)
			products[product_key] += category_products[product_key]

/**
 * Reassign the prices of the vending machine as a result of the inflation value, as provided by SSeconomy
 *
 * This rebuilds both /datum/data/vending_products lists for premium and standard products based on their most relevant pricing values.
 * Arguments:
 * * recordlist - the list of standard product datums in the vendor to refresh their prices.
 * * premiumlist - the list of premium product datums in the vendor to refresh their prices.
 */
/obj/machinery/vending/proc/reset_prices(list/recordlist, list/premiumlist)
	var/inflation_value = HAS_TRAIT(SSeconomy, TRAIT_MARKET_CRASHING) ? SSeconomy.inflation_value() : 1
	default_price = round(initial(default_price) * inflation_value)
	extra_price = round(initial(extra_price) * inflation_value)

	for(var/datum/data/vending_product/record as anything in recordlist)
		var/obj/item/potential_product = record.product_path
		var/custom_price = round(initial(potential_product.custom_price) * inflation_value)
		record.price = custom_price | default_price
	for(var/datum/data/vending_product/premium_record as anything in premiumlist)
		var/obj/item/potential_product = premium_record.product_path
		var/premium_custom_price = round(initial(potential_product.custom_premium_price) * inflation_value)
		var/custom_price = initial(potential_product.custom_price)
		if(!premium_custom_price && custom_price) //For some ungodly reason, some premium only items only have a custom_price
			premium_record.price = extra_price + round(custom_price * inflation_value)
		else
			premium_record.price = premium_custom_price || extra_price

/**
 * Refill a vending machine from a refill canister
 *
 * This takes the products from the refill canister and then fills the products, contraband and premium product categories
 *
 * Arguments:
 * * canister - the vending canister we are refilling from
 */
/obj/machinery/vending/proc/restock(obj/item/vending_refill/canister)
	if (!canister.products)
		canister.products = products.Copy()
	if (!canister.contraband)
		canister.contraband = contraband.Copy()
	if (!canister.premium)
		canister.premium = premium.Copy()

	. = 0

	if (isnull(canister.product_categories) && !isnull(product_categories))
		canister.product_categories = product_categories.Copy()

	if (!isnull(canister.product_categories))
		var/list/products_unwrapped = list()
		for (var/list/category as anything in canister.product_categories)
			var/list/products = category["products"]
			for (var/product_key in products)
				products_unwrapped[product_key] += products[product_key]

		. += refill_inventory(products_unwrapped, product_records)
	else
		. += refill_inventory(canister.products, product_records)

	. += refill_inventory(canister.contraband, hidden_records)
	. += refill_inventory(canister.premium, coin_records)

	return .

/**
 * After-effects of refilling a vending machine from a refill canister
 *
 * This takes the amount of products restocked and gives the user our contained credits if needed,
 * sending the user a fitting message.
 *
 * Arguments:
 * * user - the user restocking us
 * * restocked - the amount of items we've been refilled with
 */
/obj/machinery/vending/proc/post_restock(mob/living/user, restocked)
	if(!restocked)
		to_chat(user, span_warning("There's nothing to restock!"))
		return

	to_chat(user, span_notice("You loaded [restocked] items in [src][credits_contained > 0 ? ", and are rewarded [credits_contained] credits." : "."]"))
	var/datum/bank_account/cargo_account = SSeconomy.get_dep_account(ACCOUNT_CAR)
	cargo_account.adjust_money(round(credits_contained * 0.5), "Vending: Restock")
	var/obj/item/holochip/payday = new(src, credits_contained)
	try_put_in_hand(payday, user)
	credits_contained = 0

/**
 * Refill our inventory from the passed in product list into the record list
 *
 * Arguments:
 * * productlist - list of types -> amount
 * * recordlist - existing record datums
 */
/obj/machinery/vending/proc/refill_inventory(list/productlist, list/recordlist)
	. = 0
	for(var/datum/data/vending_product/record as anything in recordlist)
		var/diff = min(record.max_amount - record.amount, productlist[record.product_path])
		if (diff)
			productlist[record.product_path] -= diff
			record.amount += diff
			. += diff

/**
 * Set up a refill canister that matches this machine's products
 *
 * This is used when the machine is deconstructed, so the items aren't "lost"
 */
/obj/machinery/vending/proc/update_canister()
	if (!component_parts)
		return

	var/obj/item/vending_refill/installed_refill = locate() in component_parts
	if (!installed_refill)
		CRASH("Constructible vending machine did not have a refill canister")

	unbuild_inventory_into(product_records, installed_refill.products, installed_refill.product_categories)

	installed_refill.contraband = unbuild_inventory(hidden_records)
	installed_refill.premium = unbuild_inventory(coin_records)

/**
 * Given a record list, go through and return a list of products in format of type -> amount
 * Arguments:
 * recordlist - list of records to unbuild products from
 */
/obj/machinery/vending/proc/unbuild_inventory(list/recordlist)
	. = list()
	for(var/datum/data/vending_product/record as anything in recordlist)
		.[record.product_path] += record.amount

/**
 * Unbuild product_records into categorized product lists to the machine's refill canister.
 * Does not handle contraband/premium products, only standard stock and any other categories used by the vendor(see: ClothesMate).
 * If a product has no category, puts it into standard stock category.
 * Arguments:
 * product_records - list of products of the vendor
 * products - list of products of the refill canister
 * product_categories - list of product categories of the refill canister
*/
/obj/machinery/vending/proc/unbuild_inventory_into(list/product_records, list/products, list/product_categories)
	products?.Cut()
	product_categories?.Cut()

	var/others_have_category = null

	var/list/categories_to_index = list()

	for (var/datum/data/vending_product/record as anything in product_records)
		var/list/category = record.category
		var/has_category = !isnull(category)
		//check if there're any uncategorized products
		if (isnull(others_have_category))
			others_have_category = has_category
		else if (others_have_category != has_category)
			if (has_category)
				WARNING("[record.product_path] in [type] has a category, but other products don't")
			else
				WARNING("[record.product_path] in [type] does not have a category, but other products do")

			continue

		if (has_category)
			var/index = categories_to_index.Find(category)

			if (index) //if we've already established a category, add the product there
				var/list/category_in_list = product_categories[index]
				var/list/products_in_category = category_in_list["products"]
				products_in_category[record.product_path] += record.amount
			else //create a category that the product is supposed to have and put it there
				categories_to_index += list(category)
				index = categories_to_index.len

				var/list/category_clone = category.Copy()

				var/list/initial_product_list = list()
				initial_product_list[record.product_path] = record.amount
				category_clone["products"] = initial_product_list

				product_categories += list(category_clone)
		else //no category found - dump it into standard stock
			products[record.product_path] = record.amount

/**
 * Returns the total amount of items in the vending machine based on the product records and premium records, but not contraband
 */
/obj/machinery/vending/proc/total_loaded_stock()
	var/total = 0
	for(var/datum/data/vending_product/record as anything in product_records + coin_records)
		total += record.amount
	return total

/**
 * Returns the total amount of items in the vending machine based on the product records and premium records, but not contraband
 */
/obj/machinery/vending/proc/total_max_stock()
	var/total_max = 0
	for(var/datum/data/vending_product/record as anything in product_records + coin_records)
		total_max += record.max_amount
	return total_max

/obj/machinery/vending/crowbar_act(mob/living/user, obj/item/attack_item)
	if(!component_parts)
		return FALSE
	default_deconstruction_crowbar(attack_item)
	return TRUE

/obj/machinery/vending/wrench_act(mob/living/user, obj/item/tool)
	. = ..()
	if(!panel_open)
		return FALSE
	if(default_unfasten_wrench(user, tool, time = 6 SECONDS))
		unbuckle_all_mobs(TRUE)
		return ITEM_INTERACT_SUCCESS
	return FALSE

/obj/machinery/vending/screwdriver_act(mob/living/user, obj/item/attack_item)
	if(..())
		return TRUE
	if(anchored)
		default_deconstruction_screwdriver(user, icon_state, icon_state, attack_item)
		update_appearance()
	else
		to_chat(user, span_warning("You must first secure [src]."))
	return TRUE

/obj/machinery/vending/attackby(obj/item/attack_item, mob/living/user, params)
	if(panel_open && is_wire_tool(attack_item))
		wires.interact(user)
		return

	if(refill_canister && istype(attack_item, refill_canister))
		if (!panel_open)
			to_chat(user, span_warning("You should probably unscrew the service panel first!"))
		else if (machine_stat & (BROKEN|NOPOWER))
			to_chat(user, span_notice("[src] does not respond."))
		else
			//if the panel is open we attempt to refill the machine
			var/obj/item/vending_refill/canister = attack_item
			if(canister.get_part_rating() == 0)
				to_chat(user, span_warning("[canister] is empty!"))
			else
				// instantiate canister if needed
				var/restocked = restock(canister)
				post_restock(user, restocked)
			return

	if(compartmentLoadAccessCheck(user) && !user.combat_mode)
		if(canLoadItem(attack_item))
			loadingAttempt(attack_item, user)

		if(istype(attack_item, /obj/item/storage/bag)) //trays USUALLY
			var/obj/item/storage/storage_item = attack_item
			var/loaded = 0
			var/denied_items = 0
			for(var/obj/item/the_item in storage_item.contents)
				if(contents.len >= MAX_VENDING_INPUT_AMOUNT) // no more than 30 item can fit inside, legacy from snack vending although not sure why it exists
					to_chat(user, span_warning("[src]'s compartment is full."))
					break
				if(canLoadItem(the_item) && loadingAttempt(the_item, user))
					storage_item.atom_storage?.attempt_remove(the_item, src)
					loaded++
				else
					denied_items++
			if(denied_items)
				to_chat(user, span_warning("[src] refuses some items!"))
			if(loaded)
				to_chat(user, span_notice("You insert [loaded] dishes into [src]'s compartment."))
	else
		. = ..()
		if(tiltable && !tilted && attack_item.force)
			if(isclosedturf(get_turf(user))) //If the attacker is inside of a wall, immediately fall in the other direction, with no chance for goodies.
				var/opposite_direction = REVERSE_DIR(get_dir(src, user))
				var/target = get_step(src, opposite_direction)
				tilt(get_turf(target))
				return
			switch(rand(1, 100))
				if(1 to 5)
					freebie(3)
				if(6 to 15)
					freebie(2)
				if(16 to 25)
					freebie(1)
				if(26 to 75)
					return
				if(76 to 100)
					tilt(user)

/**
 * Dispenses free items from the standard stock.
 * Arguments:
 * freebies - number of free items to vend
 */
/obj/machinery/vending/proc/freebie(freebies)
	visible_message(span_notice("[src] yields [freebies > 1 ? "several free goodies" : "a free goody"][credits_contained > 0 ? " and some credits" : ""]!"))

	for(var/i in 1 to freebies)
		playsound(src, 'sound/machines/machine_vend.ogg', 50, TRUE, extrarange = -3)
		for(var/datum/data/vending_product/record in shuffle(product_records))

			if(record.amount <= 0) //Try to use a record that actually has something to dump.
				continue
			if(record.amount > LAZYLEN(record.returned_products)) //always give out new stuff that costs before free returned stuff, because of the risk getting gibbed involved
				dispense(record, get_turf(src), silent = TRUE)
			else
				var/obj/returned_obj_to_dump = LAZYACCESS(record.returned_products, LAZYLEN(record.returned_products)) //first in, last out
				LAZYREMOVE(record.returned_products, returned_obj_to_dump)
				returned_obj_to_dump.forceMove(get_turf(src))
				record.amount--
			break
	deploy_credits()

/**
 * Tilts ontop of the atom supplied, if crit is true some extra shit can happen. See [fall_and_crush] for return values.
 * Arguments:
 * fatty - atom to tilt the vendor onto
 * local_crit_chance - percent chance of a critical hit
 * forced_crit - specific critical hit case to use, if any
 * range - the range of the machine when thrown if not adjacent
*/
/obj/machinery/vending/proc/tilt(atom/fatty, local_crit_chance = crit_chance, forced_crit = forcecrit, range = 1)
	if(QDELETED(src) || !has_gravity(src))
		return

	. = NONE

	var/picked_rotation = pick(90, 270)
	if(Adjacent(fatty))
		. = fall_and_crush(get_turf(fatty), squish_damage, local_crit_chance, forced_crit, 6 SECONDS, rotation = picked_rotation)

		if (. & SUCCESSFULLY_FELL_OVER)
			visible_message(span_danger("[src] tips over!"))
			tilted = TRUE
			tilted_rotation = picked_rotation
			layer = ABOVE_MOB_LAYER

	if(get_turf(fatty) != get_turf(src))
		throw_at(get_turf(fatty), range, 1, spin = FALSE, quickstart = FALSE)

/**
 * Causes src to fall onto [target], crushing everything on it (including itself) with [damage]
 * and a small chance to do a spectacular effect per entity (if a chance above 0 is provided).
 *
 * Args:
 * * turf/target: The turf to fall onto. Cannot be null.
 * * damage: The raw numerical damage to do by default.
 * * chance_to_crit: The percent chance of a critical hit occurring. Default: 0
 * * forced_crit_case: If given a value from crushing.dm, [target] and its contents will always be hit with that specific critical hit. Default: null
 * * paralyze_time: The time, in deciseconds, a given mob/living will be paralyzed for if crushed.
 * * crush_dir: The direction the crush is coming from. Default: dir of src to [target].
 * * damage_type: The type of damage to do. Default: BRUTE
 * * damage_flag: The attack flag for armor purposes. Default: MELEE
 * * rotation: The angle of which to rotate src's transform by on a successful tilt. Default: 90.
 *
 * Returns: A collection of bitflags defined in crushing.dm. Read that file's documentation for info.
 */
/atom/movable/proc/fall_and_crush(turf/target, damage, chance_to_crit = 0, forced_crit_case = null, paralyze_time, crush_dir = get_dir(get_turf(src), target), damage_type = BRUTE, damage_flag = MELEE, rotation = 90)

	ASSERT(!isnull(target))

	var/flags_to_return = NONE

	if (!target.is_blocked_turf(TRUE, src, list(src)))
		for(var/atom/atom_target in (target.contents) + target)
			if (isarea(atom_target))
				continue

			if (SEND_SIGNAL(atom_target, COMSIG_PRE_TILT_AND_CRUSH, src) & COMPONENT_IMMUNE_TO_TILT_AND_CRUSH)
				continue

			var/crit_case = forced_crit_case
			if (isnull(crit_case) && chance_to_crit > 0)
				if (prob(chance_to_crit))
					crit_case = pick_weight(get_crit_crush_chances())
			var/crit_rebate_mult = 1 // lessen the normal damage we deal for some of the crits

			if (!isnull(crit_case))
				crit_rebate_mult = fall_and_crush_crit_rebate_table(crit_case)
				apply_crit_crush(crit_case, atom_target)

			var/adjusted_damage = damage * crit_rebate_mult
			var/crushed
			if (isliving(atom_target))
				crushed = TRUE
				var/mob/living/carbon/living_target = atom_target
				var/was_alive = (living_target.stat != DEAD)
				var/blocked = living_target.run_armor_check(attack_flag = damage_flag)
				if (iscarbon(living_target))
					var/mob/living/carbon/carbon_target = living_target
					if(prob(30))
						carbon_target.apply_damage(max(0, adjusted_damage), damage_type, blocked = blocked, forced = TRUE, spread_damage = TRUE, attack_direction = crush_dir) // the 30% chance to spread the damage means you escape breaking any bones
					else
						var/brute = (damage_type == BRUTE ? damage : 0) * 0.5
						var/burn = (damage_type == BURN ? damage : 0) * 0.5
						carbon_target.take_bodypart_damage(brute, burn, check_armor = TRUE, wound_bonus = 5) // otherwise, deal it to 2 random limbs (or the same one) which will likely shatter something
						carbon_target.take_bodypart_damage(brute, burn, check_armor = TRUE, wound_bonus = 5)
					carbon_target.AddElement(/datum/element/squish, 80 SECONDS)
				else
					living_target.apply_damage(adjusted_damage, damage_type, blocked = blocked, forced = TRUE, attack_direction = crush_dir)

				living_target.Paralyze(paralyze_time)
				living_target.emote("scream")
				playsound(living_target, 'sound/effects/blob/blobattack.ogg', 40, TRUE)
				playsound(living_target, 'sound/effects/splat.ogg', 50, TRUE)
				post_crush_living(living_target, was_alive)
				flags_to_return |= (SUCCESSFULLY_CRUSHED_MOB|SUCCESSFULLY_CRUSHED_ATOM)

			else if(check_atom_crushable(atom_target))
				atom_target.take_damage(adjusted_damage, damage_type, damage_flag, FALSE, crush_dir)
				crushed = TRUE
				flags_to_return |= SUCCESSFULLY_CRUSHED_ATOM

			if (crushed)
				atom_target.visible_message(span_danger("[atom_target] is crushed by [src]!"), span_userdanger("You are crushed by [src]!"))
				SEND_SIGNAL(atom_target, COMSIG_POST_TILT_AND_CRUSH, src)

		var/matrix/to_turn = turn(transform, rotation)
		animate(src, transform = to_turn, 0.2 SECONDS)
		playsound(src, 'sound/effects/bang.ogg', 40)

		visible_message(span_danger("[src] tips over, slamming hard onto [target]!"))
		flags_to_return |= SUCCESSFULLY_FELL_OVER
		post_tilt()
	else
		visible_message(span_danger("[src] rebounds comically as it fails to slam onto [target]!"))

	Move(target, crush_dir) // we still TRY to move onto it for shit like teleporters
	return flags_to_return

/**
 * Exists for the purposes of custom behavior.
 * Called directly after [crushed] is crushed.
 *
 * Args:
 * * mob/living/crushed: The mob that was crushed.
 * * was_alive: Boolean. True if the mob was alive before the crushing.
 */
/atom/movable/proc/post_crush_living(mob/living/crushed, was_alive)
	return

/**
 * Exists for the purposes of custom behavior.
 * Called directly after src actually rotates and falls over.
 */
/atom/movable/proc/post_tilt()
	return

/proc/check_atom_crushable(atom/atom_target)
	/// Contains structures and items that vendors shouldn't crush when we land on them.
	var/static/list/vendor_uncrushable_objects = list(
		/obj/structure/chair,
		/obj/machinery/conveyor,
	) + GLOB.WALLITEMS_INTERIOR + GLOB.WALLITEMS_EXTERIOR

	if(is_type_in_list(atom_target, vendor_uncrushable_objects)) //make sure its not in the list of "uncrushable" stuff
		return FALSE

	if (atom_target.uses_integrity && !(atom_target.invisibility > SEE_INVISIBLE_LIVING)) //check if it has integrity + allow ninjas, etc to be crushed in cloak
		return TRUE //SMUSH IT

	return FALSE

/obj/machinery/vending/post_crush_living(mob/living/crushed, was_alive)

	if(was_alive && crushed.stat == DEAD && crushed.client)
		crushed.client.give_award(/datum/award/achievement/misc/vendor_squish, crushed) // good job losing a fight with an inanimate object idiot

	add_memory_in_range(crushed, 7, /datum/memory/witness_vendor_crush, protagonist = crushed, antagonist = src)

	return ..()

/**
 * Allows damage to be reduced on certain crit cases.
 * Args:
 * * crit_case: The critical case chosen.
 */
/atom/movable/proc/fall_and_crush_crit_rebate_table(crit_case)

	ASSERT(!isnull(crit_case))

	switch(crit_case)
		if (CRUSH_CRIT_SHATTER_LEGS)
			return 0.2
		else
			return 1

/obj/machinery/vending/fall_and_crush_crit_rebate_table(crit_case)

	if (crit_case == VENDOR_CRUSH_CRIT_GLASSCANDY)
		return 0.33

	return ..()

/**
 * Returns a assoc list of (critcase -> num), where critcase is a critical define in crushing.dm and num is a weight.
 * Use with pickweight to acquire a random critcase.
 */
/atom/movable/proc/get_crit_crush_chances()
	RETURN_TYPE(/list)

	var/list/weighted_crits = list()

	weighted_crits[CRUSH_CRIT_SHATTER_LEGS] = 100
	weighted_crits[CRUSH_CRIT_PARAPLEGIC] = 80
	weighted_crits[CRUSH_CRIT_HEADGIB] = 20
	weighted_crits[CRUSH_CRIT_SQUISH_LIMB] = 100

	return weighted_crits

/obj/machinery/vending/get_crit_crush_chances()
	var/list/weighted_crits = ..()

	weighted_crits[VENDOR_CRUSH_CRIT_GLASSCANDY] = 100
	weighted_crits[VENDOR_CRUSH_CRIT_PIN] = 100

	return weighted_crits

/**
 * Should be where critcase effects are actually implemented. Use this to apply critcases.
 * Args:
 * * crit_case: The chosen critcase, defined in crushing.dm.
 * * atom/atom_target: The target to apply the critical hit to. Cannot be null. Can be anything except /area.
 *
 * Returns:
 * TRUE if a crit case is successfully applied, FALSE otherwise.
 */
/atom/movable/proc/apply_crit_crush(crit_case, atom/atom_target)
	switch (crit_case)
		if(CRUSH_CRIT_SHATTER_LEGS) // shatter their legs and bleed 'em
			if (!iscarbon(atom_target))
				return FALSE
			var/mob/living/carbon/carbon_target = atom_target
			carbon_target.bleed(150)
			var/obj/item/bodypart/leg/left/left_leg = carbon_target.get_bodypart(BODY_ZONE_L_LEG)
			if(left_leg)
				left_leg.receive_damage(brute = 200)
			var/obj/item/bodypart/leg/right/right_leg = carbon_target.get_bodypart(BODY_ZONE_R_LEG)
			if(right_leg)
				right_leg.receive_damage(brute = 200)
			if(left_leg || right_leg)
				carbon_target.visible_message(span_danger("[carbon_target]'s legs shatter with a sickening crunch!"), span_userdanger("Your legs shatter with a sickening crunch!"))
			return TRUE
		if(CRUSH_CRIT_PARAPLEGIC) // paralyze this binch
			// the new paraplegic gets like 4 lines of losing their legs so skip them
			if (!iscarbon(atom_target))
				return FALSE
			var/mob/living/carbon/carbon_target = atom_target
			visible_message(span_danger("[carbon_target]'s spinal cord is obliterated with a sickening crunch!"), ignored_mobs = list(carbon_target))
			carbon_target.gain_trauma(/datum/brain_trauma/severe/paralysis/paraplegic)
			return TRUE
		if(CRUSH_CRIT_SQUISH_LIMB) // limb squish!
			if (!iscarbon(atom_target))
				return FALSE
			var/mob/living/carbon/carbon_target = atom_target
			for(var/obj/item/bodypart/squish_part in carbon_target.bodyparts)
				var/severity = pick(WOUND_SEVERITY_MODERATE, WOUND_SEVERITY_SEVERE, WOUND_SEVERITY_CRITICAL)
				if (!carbon_target.cause_wound_of_type_and_severity(WOUND_BLUNT, squish_part, severity, wound_source = "crushed by [src]"))
					squish_part.receive_damage(brute = 30)
			carbon_target.visible_message(span_danger("[carbon_target]'s body is maimed underneath the mass of [src]!"), span_userdanger("Your body is maimed underneath the mass of [src]!"))
			return TRUE
		if(CRUSH_CRIT_HEADGIB) // skull squish!
			if (!iscarbon(atom_target))
				return FALSE
			var/mob/living/carbon/carbon_target = atom_target
			var/obj/item/bodypart/head/carbon_head = carbon_target.get_bodypart(BODY_ZONE_HEAD)
			if(carbon_head)
				if(carbon_head.dismember())
					carbon_target.visible_message(span_danger("[carbon_head] explodes in a shower of gore beneath [src]!"),	span_userdanger("Oh f-"))
					carbon_head.drop_organs()
					qdel(carbon_head)
					new /obj/effect/gibspawner/human/bodypartless(get_turf(carbon_target))
			return TRUE

	return FALSE

/obj/machinery/vending/apply_crit_crush(crit_case, atom_target)
	. = ..()

	if (.)
		return TRUE

	switch (crit_case)
		if (VENDOR_CRUSH_CRIT_GLASSCANDY)
			if (!iscarbon(atom_target))
				return FALSE
			var/mob/living/carbon/carbon_target = atom_target
			for(var/i in 1 to num_shards)
				var/obj/item/shard/shard = new /obj/item/shard(get_turf(carbon_target))
				shard.set_embed(/datum/embedding/glass_candy)
				carbon_target.hitby(shard, skipcatch = TRUE, hitpush = FALSE)
				shard.set_embed(initial(shard.embed_type))
			return TRUE
		if (VENDOR_CRUSH_CRIT_PIN) // pin them beneath the machine until someone untilts it
			if (!isliving(atom_target))
				return FALSE
			var/mob/living/living_target = atom_target
			forceMove(get_turf(living_target))
			buckle_mob(living_target, force=TRUE)
			living_target.visible_message(span_danger("[living_target] is pinned underneath [src]!"), span_userdanger("You are pinned down by [src]!"))
			return TRUE

	return FALSE

/**
 * Rights the vendor up, unpinning mobs under it, if any.
 * Arguments:
 * user - mob that has untilted the vendor
 */
/obj/machinery/vending/proc/untilt(mob/user)
	if(user)
		user.visible_message(span_notice("[user] rights [src]."), \
			span_notice("You right [src]."))

	unbuckle_all_mobs(TRUE)

	tilted = FALSE
	layer = initial(layer)

	var/matrix/to_turn = turn(transform, -tilted_rotation)
	animate(src, transform = to_turn, 0.2 SECONDS)
	tilted_rotation = 0

/**
 * Tries to insert the item into the vendor, and depending on whether the product is a part of the vendor's
 * stock or not, increments an already present product entry's available amount or creates a new entry.
 * arguments:
 * inserted_item - the item we're trying to insert
 * user - mob who's trying to insert the item
 */
/obj/machinery/vending/proc/loadingAttempt(obj/item/inserted_item, mob/user)
	. = TRUE
	if(!user.transferItemToLoc(inserted_item, src))
		return FALSE
	to_chat(user, span_notice("You insert [inserted_item] into [src]'s input compartment."))

	for(var/datum/data/vending_product/product_datum in product_records + coin_records + hidden_records)
		if(inserted_item.type == product_datum.product_path)
			product_datum.amount++
			LAZYADD(product_datum.returned_products, inserted_item)
			return

	if(vending_machine_input[inserted_item.type])
		vending_machine_input[inserted_item.type]++
	else
		vending_machine_input[inserted_item.type] = 1
	loaded_items++


/obj/machinery/vending/unbuckle_mob(mob/living/buckled_mob, force = FALSE, can_fall = TRUE)
	if(!force)
		return
	. = ..()

/**
 * Is the passed in user allowed to load this vending machines compartments? This only is ran if we are using a /obj/item/storage/bag to load the vending machine, and not a dedicated restocker.
 *
 * Arguments:
 * * user - mob that is doing the loading of the vending machine
 */
/obj/machinery/vending/proc/compartmentLoadAccessCheck(mob/user)
	if(!req_access || allowed(user) || (obj_flags & EMAGGED) || !scan_id)
		return TRUE

	to_chat(user, span_warning("[src]'s input compartment blinks red: Access denied."))
	return FALSE

/obj/machinery/vending/exchange_parts(mob/user, obj/item/storage/part_replacer/replacer)
	if(!istype(replacer) || !component_parts || !refill_canister)
		return FALSE

	var/works_from_distance = istype(replacer, /obj/item/storage/part_replacer/bluespace)

	if(!panel_open || works_from_distance)
		to_chat(user, display_parts(user))

	if(!panel_open && !works_from_distance)
		return FALSE

	var/restocked = 0
	for(var/replacer_item in replacer)
		if(istype(replacer_item, refill_canister))
			restocked += restock(replacer_item)
	post_restock(user, restocked)
	if(restocked > 0)
		replacer.play_rped_sound()
	return TRUE

/obj/machinery/vending/on_deconstruction(disassembled)
	update_canister()
	. = ..()

/obj/machinery/vending/emag_act(mob/user, obj/item/card/emag/emag_card)
	if(obj_flags & EMAGGED)
		return FALSE
	obj_flags |= EMAGGED
	balloon_alert(user, "product lock disabled")
	return TRUE

/obj/machinery/vending/interact(mob/user)
	if (HAS_AI_ACCESS(user))
		return ..()

	if(seconds_electrified && !(machine_stat & NOPOWER))
		if(shock(user, 100))
			return

	if(tilted && !user.buckled)
		to_chat(user, span_notice("You begin righting [src]."))
		if(do_after(user, 5 SECONDS, target=src))
			untilt(user)
		return

	return ..()

/obj/machinery/vending/attack_robot_secondary(mob/user, list/modifiers)
	. = ..()
	if (!Adjacent(user, src))
		return SECONDARY_ATTACK_CANCEL_ATTACK_CHAIN

/obj/machinery/vending/ui_assets(mob/user)
	return list(
		get_asset_datum(/datum/asset/spritesheet/vending),
	)

/obj/machinery/vending/ui_interact(mob/user, datum/tgui/ui)
	ui = SStgui.try_update_ui(user, src, ui)
	if(!ui)
		ui = new(user, src, "Vending", name)
		ui.open()

/obj/machinery/vending/ui_static_data(mob/user)
	var/list/data = list()
	data["onstation"] = onstation
	data["all_products_free"] = all_products_free
	data["department"] = payment_department
	data["jobDiscount"] = DEPARTMENT_DISCOUNT
	data["product_records"] = list()
	data["displayed_currency_icon"] = displayed_currency_icon
	data["displayed_currency_name"] = displayed_currency_name

	var/list/categories = list()

	data["product_records"] = collect_records_for_static_data(product_records, categories)
	data["coin_records"] = collect_records_for_static_data(coin_records, categories, premium = TRUE)
	data["hidden_records"] = collect_records_for_static_data(hidden_records, categories, premium = TRUE)

	data["categories"] = categories

	return data

/**
 * Returns a list of given product records of the vendor to be used in UI.
 * arguments:
 * records - list of records available
 * categories - list of categories available
 * premium - bool of whether a record should be priced by a custom/premium price or not
 */
/obj/machinery/vending/proc/collect_records_for_static_data(list/records, list/categories, premium)
	var/static/list/default_category = list(
		"name" = "Products",
		"icon" = "cart-shopping",
	)

	var/list/out_records = list()

	for (var/datum/data/vending_product/record as anything in records)
		var/list/static_record = list(
			path = replacetext(replacetext("[record.product_path]", "/obj/item/", ""), "/", "-"),
			name = record.name,
			price = record.price,
			max_amount = record.max_amount,
			ref = REF(record),
		)

		var/atom/printed = record.product_path
		// If it's not GAGS and has no innate colors we have to care about, we use DMIcon
		if(ispath(printed, /atom) \
			&& (!initial(printed.greyscale_config) || !initial(printed.greyscale_colors)) \
			&& !initial(printed.color) \
		)
			static_record["icon"] = initial(printed.icon)
			static_record["icon_state"] = initial(printed.icon_state)

		var/list/category = record.category || default_category
		if (!isnull(category))
			if (!(category["name"] in categories))
				categories[category["name"]] = list(
					"icon" = category["icon"],
				)

			static_record["category"] = category["name"]

		if (premium)
			static_record["premium"] = TRUE

		out_records += list(static_record)

	return out_records

/obj/machinery/vending/ui_data(mob/user)
	. = list()
	var/obj/item/card/id/card_used
	var/held_cash = 0
	if(isliving(user))
		var/mob/living/living_user = user
		card_used = living_user.get_idcard(TRUE)
		held_cash = living_user.tally_physical_credits()

	var/list/user_data = null
	if(card_used?.registered_account)
		user_data = list()
		user_data["name"] = card_used.registered_account.account_holder
		user_data["cash"] = fetch_balance_to_use(card_used) + held_cash
		if(card_used.registered_account.account_job)
			user_data["job"] = card_used.registered_account.account_job.title
			user_data["department"] = card_used.registered_account.account_job.paycheck_department
		else
			user_data["job"] = "No Job"
			user_data["department"] = DEPARTMENT_UNASSIGNED
	.["user"] = user_data

	.["stock"] = list()

	for (var/datum/data/vending_product/product_record as anything in product_records + coin_records + hidden_records)
		var/list/product_data = list(
			name = product_record.name,
			path = replacetext(replacetext("[product_record.product_path]", "/obj/item/", ""), "/", "-"),
			amount = product_record.amount,
			colorable = product_record.colorable,
		)

		.["stock"][product_data["path"]] = product_data

	.["extended_inventory"] = extended_inventory

/obj/machinery/vending/ui_act(action, list/params, datum/tgui/ui, datum/ui_state/state)
	. = ..()
	if(.)
		return
	switch(action)
		if("vend")
			. = vend(params)
		if("select_colors")
			. = select_colors(params)

/**
 * Whether this vendor can vend items or not.
 * arguments:
 * user - current customer
 */
/obj/machinery/vending/proc/can_vend(user)
	. = FALSE
	if(!vend_ready)
		return
	if(panel_open)
		to_chat(user, span_warning("The vending machine cannot dispense products while its service panel is open!"))
		return
	return TRUE

/**
 * Brings up a color config menu for the picked greyscaled item
 */
/obj/machinery/vending/proc/select_colors(list/params)
	. = TRUE
	if(!can_vend(usr))
		return
	var/datum/data/vending_product/product = locate(params["ref"])
	var/atom/fake_atom = product.product_path

	var/list/allowed_configs = list()
	var/config = initial(fake_atom.greyscale_config)
	if(!config)
		return
	allowed_configs += "[config]"
	if(ispath(fake_atom, /obj/item))
		var/obj/item/item = fake_atom
		if(initial(item.greyscale_config_worn))
			allowed_configs += "[initial(item.greyscale_config_worn)]"
		if(initial(item.greyscale_config_inhand_left))
			allowed_configs += "[initial(item.greyscale_config_inhand_left)]"
		if(initial(item.greyscale_config_inhand_right))
			allowed_configs += "[initial(item.greyscale_config_inhand_right)]"

	var/datum/greyscale_modify_menu/menu = new(
		src, usr, allowed_configs, CALLBACK(src, PROC_REF(vend_greyscale), params),
		starting_icon_state=initial(fake_atom.icon_state),
		starting_config=initial(fake_atom.greyscale_config),
		starting_colors=initial(fake_atom.greyscale_colors)
	)
	menu.ui_interact(usr)

/**
 * Vends a greyscale modified item.
 * arguments:
 * menu - greyscale config menu that has been used to vend the item
 */
/obj/machinery/vending/proc/vend_greyscale(list/params, datum/greyscale_modify_menu/menu)
	if(usr != menu.user)
		return
	vend(params, menu.split_colors)

/**
 * The entire shebang of vending the picked item. Processes the vending and initiates the payment for the item.
 * arguments:
 * greyscale_colors - greyscale config for the item we're about to vend, if any
 */
/obj/machinery/vending/proc/vend(list/params, list/greyscale_colors)
	. = TRUE
	if(!can_vend(usr))
		return
	vend_ready = FALSE //One thing at a time!!
	var/datum/data/vending_product/item_record = locate(params["ref"])
	var/list/record_to_check = product_records + coin_records
	if(extended_inventory)
		record_to_check = product_records + coin_records + hidden_records
	if(!item_record || !istype(item_record) || !item_record.product_path)
		vend_ready = TRUE
		return
	var/price_to_use = item_record.price
	if(item_record in hidden_records)
		if(!extended_inventory)
			vend_ready = TRUE
			return
	else if (!(item_record in record_to_check))
		vend_ready = TRUE
		message_admins("Vending machine exploit attempted by [ADMIN_LOOKUPFLW(usr)]!")
		return
	if (item_record.amount <= 0)
		speak("Sold out of [item_record.name].")
		flick(icon_deny,src)
		vend_ready = TRUE
		return
	if(onstation)
		// Here we do additional handing ahead of the payment component's logic, such as age restrictions and additional logging
		var/obj/item/card/id/card_used
		var/mob/living/living_user
		if(isliving(usr))
			living_user = usr
			card_used = living_user.get_idcard(TRUE)
		if(age_restrictions && item_record.age_restricted && (!card_used.registered_age || card_used.registered_age < AGE_MINOR))
			speak("You are not of legal age to purchase [item_record.name].")
			if(!(usr in GLOB.narcd_underages))
				aas_config_announce(/datum/aas_config_entry/vendomat_age_control, list(
					"PERSON" = usr.name,
					"LOCATION" = get_area_name(src),
					"VENDOR" = name,
					"PRODUCT" = item_record.name
				), src, list(RADIO_CHANNEL_SECURITY))
				GLOB.narcd_underages += usr
			flick(icon_deny,src)
			vend_ready = TRUE
			return

		if(!proceed_payment(card_used, living_user, item_record, price_to_use, params["discountless"]))
			vend_ready = TRUE
			return

	if(last_shopper != REF(usr) || purchase_message_cooldown < world.time)
		var/vend_response = vend_reply || "Thank you for shopping with [src]!"
		speak(vend_response)
		purchase_message_cooldown = world.time + 5 SECONDS
		//This is not the best practice, but it's safe enough here since the chances of two people using a machine with the same ref in 5 seconds is fuck low
		last_shopper = REF(usr)
	use_energy(active_power_usage)
	if(icon_vend) //Show the vending animation if needed
		flick(icon_vend,src)
	var/obj/item/vended_item
	if(!LAZYLEN(item_record.returned_products)) //always give out free returned stuff first, e.g. to avoid walling a traitor objective in a bag behind paid items
		vended_item = dispense(item_record, get_turf(src))
	else
		playsound(src, 'sound/machines/machine_vend.ogg', 50, TRUE, extrarange = -3)
		vended_item = LAZYACCESS(item_record.returned_products, LAZYLEN(item_record.returned_products)) //first in, last out
		LAZYREMOVE(item_record.returned_products, vended_item)
		vended_item.forceMove(get_turf(src))
	if(greyscale_colors)
		vended_item.set_greyscale(colors=greyscale_colors)
	if(usr.CanReach(src) && usr.put_in_hands(vended_item))
		to_chat(usr, span_notice("You take [item_record.name] out of the slot."))
	else
		to_chat(usr, span_warning("[capitalize(format_text(item_record.name))] falls onto the floor!"))
	SSblackbox.record_feedback("nested tally", "vending_machine_usage", 1, list("[type]", "[item_record.product_path]"))
	vend_ready = TRUE

///Common proc that dispenses an item. Called when the item is vended, or gotten some other way.
/obj/machinery/vending/proc/dispense(datum/data/vending_product/item_record, atom/spawn_location, silent = FALSE)
	SHOULD_CALL_PARENT(TRUE)
	if(!silent)
		playsound(src, 'sound/machines/machine_vend.ogg', 50, TRUE, extrarange = -3)
	var/obj/item/vended_item = new item_record.product_path (spawn_location)
	if(vended_item.type in contraband)
		ADD_TRAIT(vended_item, TRAIT_CONTRABAND, INNATE_TRAIT)
	on_dispense(vended_item)
	item_record.amount--
	return vended_item

///A proc meant to perform custom behavior on newly dispensed items.
/obj/machinery/vending/proc/on_dispense(obj/item/vended_item)
	return

/**
 * Returns the balance that the vendor will use for proceeding payment. Most vendors would want to use the user's
 * card's account credits balance.
 * arguments:
 * passed_id - the id card that will be billed for the product
 */
/obj/machinery/vending/proc/fetch_balance_to_use(obj/item/card/id/passed_id)
	return passed_id.registered_account.account_balance

/**
 * Handles payment processing: discounts, logging, balance change etc.
 * arguments:
 * paying_id_card - the id card that will be billed for the product.
 * mob_paying - the mob that is trying to purchase the item.
 * product_to_vend - the product record of the item we're trying to vend.
 * price_to_use - price of the item we're trying to vend.
 * discountless - whether or not to apply discounts
 */
/obj/machinery/vending/proc/proceed_payment(obj/item/card/id/paying_id_card, mob/living/mob_paying, datum/data/vending_product/product_to_vend, price_to_use, discountless)
	if(QDELETED(paying_id_card)) //not available(null) or somehow is getting destroyed
		speak("You do not possess an ID to purchase [product_to_vend.name].")
		return FALSE
	var/datum/bank_account/account = paying_id_card.registered_account
	if(account.account_job && account.account_job.paycheck_department == payment_department && !discountless)
		price_to_use = max(round(price_to_use * DEPARTMENT_DISCOUNT), 1) //No longer free, but signifigantly cheaper.
	if(LAZYLEN(product_to_vend.returned_products))
		price_to_use = 0 //returned items are free
	if(price_to_use && (attempt_charge(src, mob_paying, price_to_use) & COMPONENT_OBJ_CANCEL_CHARGE))
		speak("You do not possess the funds to purchase [product_to_vend.name].")
		flick(icon_deny,src)
		vend_ready = TRUE
		return FALSE
	//actual payment here
	var/datum/bank_account/paying_id_account = SSeconomy.get_dep_account(payment_department)
	if(paying_id_account)
		SSblackbox.record_feedback("amount", "vending_spent", price_to_use)
		SSeconomy.track_purchase(account, price_to_use, name)
		log_econ("[price_to_use] credits were inserted into [src] by [account.account_holder] to buy [product_to_vend].")
	credits_contained += round(price_to_use * VENDING_CREDITS_COLLECTION_AMOUNT)
	return TRUE

/obj/machinery/vending/process(seconds_per_tick)
	if(machine_stat & (BROKEN|NOPOWER))
		return PROCESS_KILL
	if(!active)
		return

	if(seconds_electrified > MACHINE_NOT_ELECTRIFIED)
		seconds_electrified--

	//Pitch to the people!  Really sell it!
	if(last_slogan + slogan_delay <= world.time && slogan_list.len > 0 && !shut_up && SPT_PROB(2.5, seconds_per_tick))
		var/slogan = pick(slogan_list)
		speak(slogan)
		last_slogan = world.time

	if(shoot_inventory && SPT_PROB(shoot_inventory_chance, seconds_per_tick))
		throw_item()

/**
 * Speak the given message verbally
 *
 * Checks if the machine is powered and the message exists
 *
 * Arguments:
 * * message - the message to speak
 */
/obj/machinery/vending/proc/speak(message)
	if(machine_stat & (BROKEN|NOPOWER))
		return
	if(!message)
		return

	say(message)

/obj/machinery/vending/power_change()
	. = ..()
	if(powered())
		START_PROCESSING(SSmachines, src)

//Somebody cut an important wire and now we're following a new definition of "pitch."
/**
 * Throw an item from our internal inventory out in front of us
 *
 * This is called when we are hacked, it selects a random product from the records that has an amount > 0
 * This item is then created and tossed out in front of us with a visible message
 */
/obj/machinery/vending/proc/throw_item()
	var/obj/throw_item = null
	var/mob/living/target = locate() in view(7,src)
	if(!target)
		return FALSE

	for(var/datum/data/vending_product/record in shuffle(product_records))
		if(record.amount <= 0) //Try to use a record that actually has something to dump.
			continue
		var/dump_path = record.product_path
		if(!dump_path)
			continue
		if(record.amount > LAZYLEN(record.returned_products)) //always throw new stuff that costs before free returned stuff, because of the hacking effort and time between throws involved
			throw_item = new dump_path(loc)
		else
			throw_item = LAZYACCESS(record.returned_products, LAZYLEN(record.returned_products)) //first in, last out
			throw_item.forceMove(loc)
			LAZYREMOVE(record.returned_products, throw_item)
		record.amount--
		break
	if(!throw_item)
		return FALSE

	pre_throw(throw_item)

	throw_item.throw_at(target, 16, 3)
	visible_message(span_danger("[src] launches [throw_item] at [target]!"))
	return TRUE

/**
 * A callback called before an item is tossed out
 *
 * Override this if you need to do any special case handling
 *
 * Arguments:
 * * thrown_item - obj/item being thrown
 */
/obj/machinery/vending/proc/pre_throw(obj/item/thrown_item)
	return

/**
 * Shock the passed in user
 *
 * This checks we have power and that the passed in prob is passed, then generates some sparks
 * and calls electrocute_mob on the user
 *
 * Arguments:
 * * user - the user to shock
 * * shock_chance - probability the shock happens
 */
/obj/machinery/vending/proc/shock(mob/living/user, shock_chance)
	if(!istype(user) || machine_stat & (BROKEN|NOPOWER)) // unpowered, no shock
		return FALSE
	if(!prob(shock_chance))
		return FALSE
	do_sparks(5, TRUE, src)
	if(electrocute_mob(user, get_area(src), src, 0.7, dist_check = TRUE))
		return TRUE
	else
		return FALSE
/**
 * Are we able to load the item passed in
 *
 * Arguments:
 * * loaded_item - the item being loaded
 * * user - the user doing the loading
 * * send_message - should we send a message to the user if the item can't be loaded? Either a to_chat or a speak depending on vending type.
 */
/obj/machinery/vending/proc/canLoadItem(obj/item/loaded_item, mob/user, send_message = TRUE)
	if(!length(loaded_item.contents) && ((loaded_item.type in products) || (loaded_item.type in premium) || (loaded_item.type in contraband)))
		return TRUE
	if(send_message)
		to_chat(user, span_warning("[src] does not accept [loaded_item]!"))
	return FALSE

/obj/machinery/vending/hitby(atom/movable/hitting_atom, skipcatch, hitpush, blocked, datum/thrownthing/throwingdatum)
	. = ..()
	var/mob/living/living_mob = hitting_atom
	if(tilted || !istype(living_mob) || !prob(20 * (throwingdatum.speed - living_mob.throw_speed))) // hulk throw = +20%, neckgrab throw = +20%
		return

	tilt(living_mob)

/obj/machinery/vending/attack_tk_grab(mob/user)
	to_chat(user, span_warning("[src] seems to resist your mental grasp!"))

///Crush the mob that the vending machine got thrown at
/obj/machinery/vending/throw_impact(atom/hit_atom, datum/thrownthing/throwingdatum)
	if(isliving(hit_atom))
		tilt(fatty=hit_atom)
	return ..()

/** Drop credits when the vendor is attacked.*/
/obj/machinery/vending/proc/deploy_credits()
	if(credits_contained <= 0)
		return
	var/credits_to_remove = min(CREDITS_DUMP_THRESHOLD, round(credits_contained))
	var/obj/item/holochip/holochip = new(loc, credits_to_remove)
	playsound(src, 'sound/effects/cashregister.ogg', 40, TRUE)
	credits_contained = max(0, credits_contained - credits_to_remove)
	SSblackbox.record_feedback("amount", "vending machine looted", holochip.credits)

/obj/machinery/vending/add_context(atom/source, list/context, obj/item/held_item, mob/user)
	if(tilted && !held_item)
		context[SCREENTIP_CONTEXT_LMB] = "Right machine"
		return CONTEXTUAL_SCREENTIP_SET

	if(held_item?.tool_behaviour == TOOL_SCREWDRIVER)
		context[SCREENTIP_CONTEXT_LMB] = panel_open ? "Close panel" : "Open panel"
		return CONTEXTUAL_SCREENTIP_SET

	if(panel_open && held_item?.tool_behaviour == TOOL_WRENCH)
		context[SCREENTIP_CONTEXT_LMB] = anchored ? "Unsecure" : "Secure"
		return CONTEXTUAL_SCREENTIP_SET

	if(panel_open && held_item?.tool_behaviour == TOOL_CROWBAR)
		context[SCREENTIP_CONTEXT_LMB] = "Deconstruct"
		return CONTEXTUAL_SCREENTIP_SET

	if(!isnull(held_item) && (vending_machine_input[held_item.type] || canLoadItem(held_item, user, send_message = FALSE)))
		context[SCREENTIP_CONTEXT_LMB] = "Load item"
		return CONTEXTUAL_SCREENTIP_SET

	if(panel_open && istype(held_item, refill_canister))
		context[SCREENTIP_CONTEXT_LMB] = "Restock vending machine[credits_contained ? " and collect credits" : null]"
		return TRUE
	return NONE

/obj/machinery/vending/custom
	name = "Custom Vendor"
	icon_state = "custom"
	icon_deny = "custom-deny"
	max_integrity = 400
	payment_department = NO_FREEBIES
	light_mask = "custom-light-mask"
	refill_canister = /obj/item/vending_refill/custom
	fish_source_path = /datum/fish_source/vending/custom
	/// where the money is sent
	var/datum/bank_account/linked_account
	/// max number of items that the custom vendor can hold
	var/max_loaded_items = 20
	/// Base64 cache of custom icons.
	var/list/base64_cache = list()
	panel_type = "panel20"

/obj/machinery/vending/custom/compartmentLoadAccessCheck(mob/user)
	. = FALSE
	if(!isliving(user))
		return FALSE
	var/mob/living/living_user = user
	var/obj/item/card/id/id_card = living_user.get_idcard(FALSE)
	if(id_card?.registered_account && id_card.registered_account == linked_account)
		return TRUE

/obj/machinery/vending/custom/canLoadItem(obj/item/loaded_item, mob/user, send_message = TRUE)
	. = FALSE
	if(loaded_item.flags_1 & HOLOGRAM_1)
		if(send_message)
			speak("This vendor cannot accept nonexistent items.")
		return
	if(loaded_items >= max_loaded_items)
		if(send_message)
			speak("There are too many items in stock.")
		return
	if(isstack(loaded_item))
		if(send_message)
			speak("Loose items may cause problems, try to use it inside wrapping paper.")
		return
	if(loaded_item.custom_price)
		return TRUE

/obj/machinery/vending/custom/ui_interact(mob/user, datum/tgui/ui)
	if(!linked_account)
		balloon_alert(user, "no registered owner!")
		return FALSE
	return ..()

/obj/machinery/vending/custom/ui_data(mob/user)
	. = ..()
	.["access"] = compartmentLoadAccessCheck(user)
	.["vending_machine_input"] = list()
	for (var/obj/item/stocked_item as anything in vending_machine_input)
		if(vending_machine_input[stocked_item] > 0)
			var/base64
			var/price = 0
			var/itemname = initial(stocked_item.name)
			for(var/obj/item/stored_item in contents)
				if(stored_item.type == stocked_item)
					price = stored_item.custom_price
					itemname = stored_item.name
					if(!base64) //generate an icon of the item to use in UI
						if(base64_cache[stored_item.type])
							base64 = base64_cache[stored_item.type]
						else
							base64 = icon2base64(getFlatIcon(stored_item, no_anim=TRUE))
							base64_cache[stored_item.type] = base64
					break
			var/list/data = list(
				path = stocked_item,
				name = itemname,
				price = price,
				img = base64,
				amount = vending_machine_input[stocked_item],
				colorable = FALSE
			)
			.["vending_machine_input"] += list(data)

/obj/machinery/vending/custom/ui_act(action, list/params, datum/tgui/ui, datum/ui_state/state)
	. = ..()
	if(.)
		return
	switch(action)
		if("dispense")
			if(isliving(usr))
				vend_act(usr, params)
				vend_ready = TRUE
			return TRUE

/obj/machinery/vending/custom/attackby(obj/item/attack_item, mob/user, params)
	if(!linked_account && isliving(user))
		var/mob/living/living_user = user
		var/obj/item/card/id/card_used = living_user.get_idcard(TRUE)
		if(card_used?.registered_account)
			linked_account = card_used.registered_account
			speak("\The [src] has been linked to [card_used].")

	if(!compartmentLoadAccessCheck(user) || !IS_WRITING_UTENSIL(attack_item))
		return ..()

	var/new_name = reject_bad_name(tgui_input_text(user, "Set name", "Name", name, max_length = 20), allow_numbers = TRUE, strict = TRUE, cap_after_symbols = FALSE)
	if (new_name)
		name = new_name
	var/new_desc = reject_bad_text(tgui_input_text(user, "Set description", "Description", desc, max_length = 60))
	if (new_desc)
		desc = new_desc
	var/new_slogan = reject_bad_text(tgui_input_text(user, "Set slogan", "Slogan", "Epic", max_length = 60))
	if (new_slogan)
		slogan_list += new_slogan
		last_slogan = world.time + rand(0, slogan_delay)

/obj/machinery/vending/custom/crowbar_act(mob/living/user, obj/item/attack_item)
	return FALSE

/obj/machinery/vending/custom/on_deconstruction(disassembled)
	unbuckle_all_mobs(TRUE)
	var/turf/current_turf = get_turf(src)
	if(current_turf)
		for(var/obj/item/stored_item in contents)
			stored_item.forceMove(current_turf)
		explosion(src, devastation_range = -1, light_impact_range = 3)

/**
 * Vends an item to the user. Handles all the logic:
 * Updating stock, account transactions, alerting users.
 * @return -- TRUE if a valid condition was met, FALSE otherwise.
 */
/obj/machinery/vending/custom/proc/vend_act(mob/living/user, list/params)
	if(!vend_ready)
		return
	var/obj/item/choice = text2path(params["item"]) // typepath is a string coming from javascript, we need to convert it back
	var/obj/item/dispensed_item
	var/obj/item/card/id/id_card = user.get_idcard(TRUE)
	vend_ready = FALSE
	if(!id_card || !id_card.registered_account || !id_card.registered_account.account_job)
		balloon_alert(usr, "no card found!")
		flick(icon_deny, src)
		return TRUE
	var/datum/bank_account/payee = id_card.registered_account
	for(var/obj/item/stock in contents)
		if(istype(stock, choice))
			dispensed_item = stock
			break
	if(!dispensed_item)
		return FALSE
	/// Charges the user if its not the owner
	if(!compartmentLoadAccessCheck(user))
		if(!payee.has_money(dispensed_item.custom_price))
			balloon_alert(user, "insufficient funds!")
			return TRUE
		/// Make the transaction
		payee.adjust_money(-dispensed_item.custom_price, , "Vending: [dispensed_item]")
		linked_account.adjust_money(dispensed_item.custom_price, "Vending: [dispensed_item] Bought")
		linked_account.bank_card_talk("[payee.account_holder] made a [dispensed_item.custom_price] \
		cr purchase at your custom vendor.")
		/// Log the transaction
		SSblackbox.record_feedback("amount", "vending_spent", dispensed_item.custom_price)
		log_econ("[dispensed_item.custom_price] credits were spent on [src] buying a \
		[dispensed_item] by [payee.account_holder], owned by [linked_account.account_holder].")
		/// Make an alert
		if(last_shopper != REF(usr) || purchase_message_cooldown < world.time)
			speak("Thank you for your patronage [user]!")
			purchase_message_cooldown = world.time + 5 SECONDS
			last_shopper = REF(usr)
	/// Remove the item
	loaded_items--
	use_energy(active_power_usage)
	vending_machine_input[choice] = max(vending_machine_input[choice] - 1, 0)
	if(user.CanReach(src) && user.put_in_hands(dispensed_item))
		to_chat(user, span_notice("You take [dispensed_item.name] out of the slot."))
	else
		to_chat(user, span_warning("[capitalize(format_text(dispensed_item.name))] falls onto the floor!"))
	return TRUE

/obj/machinery/vending/custom/unbreakable
	name = "Indestructible Vendor"
	resistance_flags = INDESTRUCTIBLE

/obj/item/vending_refill/custom
	machine_name = "Custom Vendor"
	icon_state = "refill_custom"
	custom_premium_price = PAYCHECK_CREW

/obj/machinery/vending/custom/greed //name and like decided by the spawn
	icon_state = "greed"
	icon_deny = "greed-deny"
	panel_type = "panel4"
	max_integrity = 700
	max_loaded_items = 40
	light_mask = "greed-light-mask"
	custom_materials = list(/datum/material/gold = SHEET_MATERIAL_AMOUNT * 5)

/obj/machinery/vending/custom/greed/Initialize(mapload)
	. = ..()
	//starts in a state where you can move it
	set_panel_open(TRUE)
	set_anchored(FALSE)
	add_overlay(panel_type)
	//and references the deity
	name = "[GLOB.deity]'s Consecrated Vendor"
	desc = "A vending machine created by [GLOB.deity]."
	slogan_list = list("[GLOB.deity] says: It's your divine right to buy!")
	add_filter("vending_outline", 9, list("type" = "outline", "color" = COLOR_VERY_SOFT_YELLOW))
	add_filter("vending_rays", 10, list("type" = "rays", "size" = 35, "color" = COLOR_VIVID_YELLOW))

/datum/aas_config_entry/vendomat_age_control
	name = "Security Alert: Underaged Substance Abuse"
	announcement_lines_map = list(
		"Message" = "SECURITY ALERT: Underaged crewmember %PERSON recorded attempting to purchase %PRODUCT in %LOCATION by %VENDOR. Please watch for substance abuse."
	)
	vars_and_tooltips_map = list(
		"PERSON" = "will be replaced with the name of the crewmember",
		"PRODUCT" = "with the product, he attempted to purchase",
		"LOCATION" = "with place of purchase",
		"VENDOR" = "with the vending machine"
	)

#undef MAX_VENDING_INPUT_AMOUNT
