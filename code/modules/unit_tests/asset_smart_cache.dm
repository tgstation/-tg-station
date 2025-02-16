/datum/asset/spritesheet_batched/test
	name = "test"
	load_immediately = TRUE
	force_cache = TRUE
	// Don't let the asset subsystem load this. This is how we trick it.
	_abstract = /datum/asset/spritesheet_batched/test
	var/static/list/items = list(/obj/item/binoculars, /obj/item/camera, /obj/item/clothing/under/color/blue, /obj/item/clothing/under/color/black)

/datum/asset/spritesheet_batched/test/create_spritesheets()
	for(var/atom/item as() in items)
		if (!ispath(item, /atom))
			return FALSE
		var/imgid = replacetext(replacetext("[item]", "/obj/item/", ""), "/", "-")
		insert_icon(imgid, get_display_icon_for(item))
	// Get some coverage on each operation.
	var/datum/universal_icon/I = uni_icon('icons/effects/effects.dmi', "nothing")
	I.blend_icon(uni_icon('icons/effects/effects.dmi', "sparks"), ICON_OVERLAY)
	I.blend_color("#ff0000", ICON_MULTIPLY)
	I.scale(64, 64)
	I.crop(1, 1, 128, 64) // we'll test for the scale later.
	insert_icon("test", I)

/datum/asset/spritesheet_batched/test/unregister()
	SSassets.transport.unregister_asset("spritesheet_[name].css")
	if(length(sizes))
		for(var/size_id in sizes)
			SSassets.transport.unregister_asset("[name]_[size_id].png")

/datum/unit_test/test_asset_smart_cache/Run()
	fdel("[ASSET_CROSS_ROUND_SMART_CACHE_DIRECTORY]/spritesheet_cache.test.json")
	fdel("data/spritesheets/spritesheet_test.css")
	var/datum/asset/spritesheet_batched/test/sheet = new()
	TEST_ASSERT(sheet.fully_generated, "Spritesheet not generated!")
	// Cache should be invalid initially.
	TEST_ASSERT(sheet.cache_result, "Spritesheet smart cache was VALID when it should be INVALID!")
	for(var/item in sheet.items)
		var/imgid = replacetext(replacetext("[item]", "/obj/item/", ""), "/", "-")
		// All items should be in sprites list.
		TEST_ASSERT(imgid in sheet.sprites, "Item [item] not present in spritesheet result!")
	TEST_ASSERT("test" in sheet.sprites, "Item test not present in spritesheet result!")
	TEST_ASSERT("128x64" in sheet.sizes, "Test icon was not output as 128x64!")
	// cache wrote properly
	TEST_ASSERT(fexists("[ASSET_CROSS_ROUND_SMART_CACHE_DIRECTORY]/spritesheet_cache.test.json"), "Smart cache entry did not write!")
	// Clear it out and get ready to do it again, this time loading from cache
	sheet.unregister()
	sheet.entries = list()
	sheet.sprites = list()
	sheet.sizes = list()
	sheet.job_id = null
	sheet.cache_result = null
	sheet.cache_data = null
	sheet.cache_job_id = null
	sheet.fully_generated = FALSE

	sheet.register()
	TEST_ASSERT(sheet.fully_generated, "Spritesheet did not load from smart cache properly!")
	// Check for CACHE_VALID
	TEST_ASSERT(!sheet.cache_result, "Spritesheet did not load from smart cache, it was invalid despite having the same input data!")
	// Cleanup files.
	fdel("[ASSET_CROSS_ROUND_SMART_CACHE_DIRECTORY]/spritesheet_cache.test.json")
	fdel("data/spritesheets/spritesheet_test.css")
	for(var/size in sheet.sizes)
		fdel("data/spritesheets/test_[size].png")


