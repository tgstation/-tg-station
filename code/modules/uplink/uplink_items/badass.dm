/datum/uplink_category/badassery
	name = "(Pointless) Badassery"
	weight = 0

/datum/uplink_item/badass
	category = /datum/uplink_category/badassery
	surplus = 0

/datum/uplink_item/badass/balloon
	name = "Syndicate Balloon"
	desc = "For showing that you are THE BOSS: A useless red balloon with the Syndicate logo on it. \
			Can blow the deepest of covers."
	item = /obj/item/toy/balloon/syndicate
	cost = 20
	lock_other_purchases = TRUE
	cant_discount = TRUE
	uplink_item_flags = SYNDIE_TRIPS_CONTRABAND

/datum/uplink_item/badass/balloon/spawn_item(spawn_path, mob/user, datum/uplink_handler/uplink_handler, atom/movable/source)
	. = ..()

	if(!.)
		return

	notify_ghosts(
		"[user] has purchased a BADASS Syndicate Balloon!",
		source = .,
		header = "What are they THINKING?",
	)

/datum/uplink_item/badass/syndiecards
	name = "Syndicate Playing Cards"
	desc = "A special deck of space-grade playing cards with a mono-molecular edge and metal reinforcement, \
			making them slightly more robust than a normal deck of cards. \
			You can also play card games with them or leave them on your victims."
	item = /obj/item/toy/cards/deck/syndicate
	cost = 1
	surplus = 40
	uplink_item_flags = SYNDIE_TRIPS_CONTRABAND

/datum/uplink_item/badass/syndiecigs
	name = "Syndicate Smokes"
	desc = "Strong flavor, dense smoke, infused with omnizine."
	item = /obj/item/storage/fancy/cigarettes/cigpack_syndicate
	cost = 2
	uplink_item_flags = SYNDIE_TRIPS_CONTRABAND

/datum/uplink_item/badass/syndiecash
	name = "Syndicate Briefcase Full of Cash"
	desc = "A secure briefcase containing 5000 space credits. Useful for bribing personnel, or purchasing goods \
			and services at lucrative prices. The briefcase also feels a little heavier to hold; it has been \
			manufactured to pack a little bit more of a punch if your client needs some convincing."
	item = /obj/item/storage/briefcase/secure/syndie
	cost = 3
	restricted = TRUE
	uplink_item_flags = SYNDIE_TRIPS_CONTRABAND

/datum/uplink_item/badass/costumes/clown
	name = "Clown Costume"
	desc = "Nothing is more terrifying than clowns with fully automatic weaponry."
	item = /obj/item/storage/backpack/duffelbag/clown/syndie

/datum/uplink_item/badass/costumes/tactical_naptime
	name = "Sleepy Time Pajama Bundle"
	desc = "Even soldiers need to get a good nights rest. Comes with blood-red pajamas, a blankie, a hot mug of cocoa and a fuzzy friend."
	item = /obj/item/storage/box/syndie_kit/sleepytime
	limited_stock = 1
	cant_discount = TRUE

/datum/uplink_item/badass/costumes/obvious_chameleon
	name = "Broken Chameleon Kit"
	desc = "A set of items that contain chameleon technology allowing you to disguise as pretty much anything on the station, and more! \
			Please note that this kit did NOT pass quality control."
	item = /obj/item/storage/box/syndie_kit/chameleon/broken

/datum/uplink_item/badass/costumes/centcom_official
	name = "CentCom Official Costume"
	desc = "Ask the crew to \"inspect\" their nuclear disk and weapons system, and then when they decline, pull out a fully automatic rifle and gun down the Captain. \
			Radio headset does not include encryption key. No gun included."
	item = /obj/item/storage/box/syndie_kit/centcom_costume

/datum/uplink_item/badass/stickers
	name = "Syndicate Sticker Pack"
	desc = "Contains 8 random stickers precisely engineered to resemble suspicious objects, which may or may not be useful for fooling crew."
	item = /obj/item/storage/box/stickers/syndie_kit
	cost = 1

/datum/uplink_item/badass/demotivational_posters
	name = "Syndicate Demotivational Poster Pack"
	desc = "Contains a selection of demotivational posters to minimise productivity and maximise apathy in the workplace."
	item = /obj/item/storage/box/syndie_kit/poster_box
	cost = 1

/datum/uplink_item/badass/syndie_spraycan
	name = "Syndicate Spraycan"
	desc = "A stylish Syndicate spraycan. \
		Contains enough special solution to spray a single super-size seditious symbol, subjecting station staff to slippery suffering."
	item = /obj/item/traitor_spraycan
	cost = 1

/datum/uplink_item/badass/pinpointer
	name = "Surplus Pinpointer"
	desc = "Provides a surplus pinpointer, left over from the previous models that were abandoned in favor of a SAAS cloud-based PDA app."
	item = /obj/item/pinpointer/nuke/syndicate
	cost = 2
