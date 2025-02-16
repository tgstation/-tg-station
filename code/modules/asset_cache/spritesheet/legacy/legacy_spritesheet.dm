
// spritesheet implementation - coalesces various icons into a single .png file
// and uses CSS to select icons out of that file - saves on transferring some
// 1400-odd individual PNG files
#define SPR_SIZE 1
#define SPR_IDX 2
#define SPRSZ_COUNT 1
#define SPRSZ_ICON 2
#define SPRSZ_STRIPPED 3

/// Deprecated: Use /datum/asset/spritesheet_batched where possible
/datum/asset/spritesheet
	_abstract = /datum/asset/spritesheet
	cross_round_cachable = TRUE
	var/name
	/// List of arguments to pass into queuedInsert
	/// Exists so we can queue icon insertion, mostly for stuff like preferences
	var/list/to_generate = list()
	var/list/sizes = list()    // "32x32" -> list(10, icon/normal, icon/stripped)
	var/list/sprites = list()  // "foo_bar" -> list("32x32", 5)
	var/list/cached_spritesheets_needed
	var/generating_cache = FALSE
	var/fully_generated = FALSE
	/// If this asset should be fully loaded on new
	/// Defaults to false so we can process this stuff nicely
	var/load_immediately = FALSE
	VAR_PRIVATE
		// Kept in state so that the result is the same, even when the files are created, for this run
		should_refresh = null

/datum/asset/spritesheet/proc/should_load_immediately()
#ifdef DO_NOT_DEFER_ASSETS
	return TRUE
#else
	return load_immediately
#endif


/datum/asset/spritesheet/should_refresh()
	if (..())
		return TRUE

	if (isnull(should_refresh))
		// `fexists` seems to always fail on static-time
		should_refresh = !fexists(css_cache_filename()) || !fexists(data_cache_filename())

	return should_refresh

/datum/asset/spritesheet/unregister()
	SSassets.transport.unregister_asset("spritesheet_[name].css")
	if(length(sizes))
		for(var/size_id in sizes)
			SSassets.transport.unregister_asset("[name]_[size_id].png")
	else
		for(var/sheet in cached_spritesheets_needed)
			SSassets.transport.unregister_asset(sheet)

/datum/asset/spritesheet/regenerate()
	unregister()
	sprites = list()
	fdel("[ASSET_CROSS_ROUND_CACHE_DIRECTORY]/spritesheet.[name].css")
	for(var/sheet in cached_spritesheets_needed)
		fdel("[ASSET_CROSS_ROUND_CACHE_DIRECTORY]/spritesheet.[sheet].png")
	fdel("data/spritesheets/spritesheet_[name].css")
	for(var/size_id in sizes)
		fdel("data/spritesheets/[name]_[size_id].png")
	sizes = list()
	to_generate = list()
	cached_serialized_url_mappings = null
	cached_serialized_url_mappings_transport_type = null
	fully_generated = FALSE
	var/old_load = load_immediately
	load_immediately = TRUE
	create_spritesheets()
	realize_spritesheets(yield = FALSE)
	load_immediately = old_load

/datum/asset/spritesheet/register()
	SHOULD_NOT_OVERRIDE(TRUE)

	if (!name)
		CRASH("spritesheet [type] cannot register without a name")

	if (!should_refresh() && read_from_cache())
		fully_generated = TRUE
		return

	// If it's cached, may as well load it now, while the loading is cheap
	if(CONFIG_GET(flag/cache_assets) && cross_round_cachable)
		load_immediately = TRUE

	create_spritesheets()
	if(should_load_immediately())
		realize_spritesheets(yield = FALSE)
	else
		SSasset_loading.queue_asset(src)

/datum/asset/spritesheet/proc/realize_spritesheets(yield)
	if(fully_generated)
		return
	while(length(to_generate))
		var/list/stored_args = to_generate[to_generate.len]
		to_generate.len--
		queuedInsert(arglist(stored_args))
		if(yield && TICK_CHECK)
			return

	ensure_stripped()
	for(var/size_id in sizes)
		var/size = sizes[size_id]
		var/file_path = size[SPRSZ_STRIPPED]
		var/file_hash = rustg_hash_file("md5", file_path)
		SSassets.transport.register_asset("[name]_[size_id].png", file_path, file_hash=file_hash)
	var/css_name = "spritesheet_[name].css"
	var/file_directory = "data/spritesheets/[css_name]"
	fdel(file_directory)
	var/css = generate_css()
	rustg_file_write(css, file_directory)
	var/css_hash = rustg_hash_string("md5", css)
	SSassets.transport.register_asset(css_name, fcopy_rsc(file_directory), file_hash=css_hash)

	if(CONFIG_GET(flag/save_spritesheets))
		save_to_logs(file_name = css_name, file_location = file_directory)

	fdel(file_directory)

	if (CONFIG_GET(flag/cache_assets) && cross_round_cachable)
		write_to_cache()
	fully_generated = TRUE
	// If we were ever in there, remove ourselves
	SSasset_loading.dequeue_asset(src)

/datum/asset/spritesheet/queued_generation()
	realize_spritesheets(yield = TRUE)

/datum/asset/spritesheet/ensure_ready()
	if(!fully_generated)
		realize_spritesheets(yield = FALSE)
	return ..()

/datum/asset/spritesheet/send(client/client)
	if (!name)
		return

	if (!should_refresh())
		return send_from_cache(client)

	var/all = list("spritesheet_[name].css")
	for(var/size_id in sizes)
		all += "[name]_[size_id].png"
	. = SSassets.transport.send_assets(client, all)

/datum/asset/spritesheet/get_url_mappings()
	if (!name)
		return

	if (!should_refresh())
		return get_cached_url_mappings()

	. = list("spritesheet_[name].css" = SSassets.transport.get_asset_url("spritesheet_[name].css"))
	for(var/size_id in sizes)
		.["[name]_[size_id].png"] = SSassets.transport.get_asset_url("[name]_[size_id].png")

/datum/asset/spritesheet/proc/ensure_stripped(sizes_to_strip = sizes)
	for(var/size_id in sizes_to_strip)
		var/size = sizes[size_id]
		if (size[SPRSZ_STRIPPED])
			continue

		// save flattened version
		var/png_name = "[name]_[size_id].png"
		var/file_directory = "data/spritesheets/[png_name]"
		fcopy(size[SPRSZ_ICON], file_directory)
		var/error = rustg_dmi_strip_metadata(file_directory)
		if(length(error))
			stack_trace("Failed to strip [png_name]: [error]")
		size[SPRSZ_STRIPPED] = icon(file_directory)

		// this is useful here for determining if weird sprite issues (like having a white background) are a cause of what we're doing DM-side or not since we can see the full flattened thing at-a-glance.
		if(CONFIG_GET(flag/save_spritesheets))
			save_to_logs(file_name = png_name, file_location = file_directory)

		fdel(file_directory)

/datum/asset/spritesheet/proc/generate_css()
	var/list/out = list()

	for (var/size_id in sizes)
		var/size = sizes[size_id]
		var/icon/tiny = size[SPRSZ_ICON]
		out += ".[name][size_id]{display:inline-block;width:[tiny.Width()]px;height:[tiny.Height()]px;background-image:url('[get_background_url("[name]_[size_id].png")]');background-repeat:no-repeat;}"

	for (var/sprite_id in sprites)
		var/sprite = sprites[sprite_id]
		var/size_id = sprite[SPR_SIZE]
		var/idx = sprite[SPR_IDX]
		var/size = sizes[size_id]

		var/icon/tiny = size[SPRSZ_ICON]
		var/icon/big = size[SPRSZ_STRIPPED]
		var/per_line = big.Width() / tiny.Width()
		var/x = (idx % per_line) * tiny.Width()
		var/y = round(idx / per_line) * tiny.Height()

		out += ".[name][size_id].[sprite_id]{background-position:-[x]px -[y]px;}"

	return out.Join("\n")

/datum/asset/spritesheet/proc/css_cache_filename()
	return "[ASSET_CROSS_ROUND_CACHE_DIRECTORY]/spritesheet.[name].css"

/datum/asset/spritesheet/proc/data_cache_filename()
	return "[ASSET_CROSS_ROUND_CACHE_DIRECTORY]/spritesheet.[name].json"

/datum/asset/spritesheet/proc/read_from_cache()
	return read_css_from_cache() && read_data_from_cache()

/datum/asset/spritesheet/proc/read_css_from_cache()
	var/replaced_css = rustg_file_read(css_cache_filename())

	var/regex/find_background_urls = regex(@"background-image:url\('%(.+?)%'\)", "g")
	while (find_background_urls.Find(replaced_css))
		var/asset_id = find_background_urls.group[1]
		var/file_path = "[ASSET_CROSS_ROUND_CACHE_DIRECTORY]/spritesheet.[asset_id]"
		// Hashing it here is a *lot* faster.
		var/hash = rustg_hash_file("md5", file_path)
		var/asset_cache_item = SSassets.transport.register_asset(asset_id, file_path, file_hash=hash)
		var/asset_url = SSassets.transport.get_asset_url(asset_cache_item = asset_cache_item)
		replaced_css = replacetext(replaced_css, find_background_urls.match, "background-image:url('[asset_url]')")
		LAZYADD(cached_spritesheets_needed, asset_id)

	var/finalized_name = "spritesheet_[name].css"
	var/replaced_css_filename = "data/spritesheets/[finalized_name]"
	var/css_hash = rustg_hash_string("md5", replaced_css)
	rustg_file_write(replaced_css, replaced_css_filename)
	SSassets.transport.register_asset(finalized_name, replaced_css_filename, file_hash=css_hash)

	if(CONFIG_GET(flag/save_spritesheets))
		save_to_logs(file_name = finalized_name, file_location = replaced_css_filename)

	fdel(replaced_css_filename)

	return TRUE

/datum/asset/spritesheet/proc/read_data_from_cache()
	var/json = json_decode(rustg_file_read(data_cache_filename()))

	if (islist(json["sprites"]))
		sprites = json["sprites"]

	return TRUE

/datum/asset/spritesheet/proc/send_from_cache(client/client)
	if (isnull(cached_spritesheets_needed))
		stack_trace("cached_spritesheets_needed was null when sending assets from [type] from cache")
		cached_spritesheets_needed = list()

	return SSassets.transport.send_assets(client, cached_spritesheets_needed + "spritesheet_[name].css")

/// Returns the URL to put in the background:url of the CSS asset
/datum/asset/spritesheet/proc/get_background_url(asset)
	if (generating_cache)
		return "%[asset]%"
	else
		return SSassets.transport.get_asset_url(asset)

/datum/asset/spritesheet/proc/write_to_cache()
	write_css_to_cache()
	write_data_to_cache()

/datum/asset/spritesheet/proc/write_css_to_cache()
	for (var/size_id in sizes)
		fcopy(SSassets.cache["[name]_[size_id].png"].resource, "[ASSET_CROSS_ROUND_CACHE_DIRECTORY]/spritesheet.[name]_[size_id].png")

	generating_cache = TRUE
	var/mock_css = generate_css()
	generating_cache = FALSE

	rustg_file_write(mock_css, css_cache_filename())

/datum/asset/spritesheet/proc/write_data_to_cache()
	rustg_file_write(json_encode(list(
		"sprites" = sprites,
	)), data_cache_filename())

/datum/asset/spritesheet/proc/get_cached_url_mappings()
	var/list/mappings = list()
	mappings["spritesheet_[name].css"] = SSassets.transport.get_asset_url("spritesheet_[name].css")

	for (var/asset_name in cached_spritesheets_needed)
		mappings[asset_name] = SSassets.transport.get_asset_url(asset_name)

	return mappings

/// Override this in order to start the creation of the spritehseet.
/// This is where all your Insert, InsertAll, etc calls should be inside.
/datum/asset/spritesheet/proc/create_spritesheets()
	SHOULD_CALL_PARENT(FALSE)
	CRASH("create_spritesheets() not implemented for [type]!")

/datum/asset/spritesheet/proc/Insert(sprite_name, icon/I, icon_state="", dir=SOUTH, frame=1, moving=FALSE)
	if(should_load_immediately())
		queuedInsert(sprite_name, I, icon_state, dir, frame, moving)
	else
		to_generate += list(args.Copy())

/datum/asset/spritesheet/proc/queuedInsert(sprite_name, icon/I, icon_state="", dir=SOUTH, frame=1, moving=FALSE)
#ifdef UNIT_TESTS
	if (I && icon_state && !icon_exists(I, icon_state)) // check the base icon prior to extracting the state we want
		stack_trace("Tried to insert nonexistent icon_state '[icon_state]' from [I] into spritesheet [name] ([type])")
		return
#endif
	I = icon(I, icon_state=icon_state, dir=dir, frame=frame, moving=moving)
	if (!I || !length(icon_states(I)))  // that direction or state doesn't exist
		return

	var/start_usage = world.tick_usage

	//any sprite modifications we want to do (aka, coloring a greyscaled asset)
	I = ModifyInserted(I)
	var/size_id = "[I.Width()]x[I.Height()]"
	var/size = sizes[size_id]

	if (sprites[sprite_name])
		CRASH("duplicate sprite \"[sprite_name]\" in sheet [name] ([type])")

	if (size)
		var/position = size[SPRSZ_COUNT]++
		// Icons are essentially representations of files + modifications
		// Because of this, byond keeps them in a cache. It does this in a really dumb way tho
		// It's essentially a FIFO queue. So after we do icon() some amount of times, our old icons go out of cache
		// When this happens it becomes impossible to modify them, trying to do so will instead throw a
		// "bad icon" error.
		// What we're doing here is ensuring our icon is in the cache by refreshing it, so we can modify it w/o runtimes.
		var/icon/sheet = size[SPRSZ_ICON]
		var/icon/sheet_copy = icon(sheet)
		size[SPRSZ_STRIPPED] = null
		sheet_copy.Insert(I, icon_state=sprite_name)
		size[SPRSZ_ICON] = sheet_copy

		sprites[sprite_name] = list(size_id, position)
	else
		sizes[size_id] = size = list(1, I, null)
		sprites[sprite_name] = list(size_id, 0)

	SSblackbox.record_feedback("tally", "spritesheet_queued_insert_time", TICK_USAGE_TO_MS(start_usage), name)

/**
 * A simple proc handing the Icon for you to modify before it gets turned into an asset.
 *
 * Arguments:
 * * I: icon being turned into an asset
 */
/datum/asset/spritesheet/proc/ModifyInserted(icon/pre_asset)
	return pre_asset

/datum/asset/spritesheet/proc/InsertAll(prefix, icon/I, list/directions)
	if (length(prefix))
		prefix = "[prefix]-"

	if (!directions)
		directions = list(SOUTH)

	for (var/icon_state_name in icon_states(I))
		for (var/direction in directions)
			var/prefix2 = (directions.len > 1) ? "[dir2text(direction)]-" : ""
			Insert("[prefix][prefix2][icon_state_name]", I, icon_state=icon_state_name, dir=direction)

/datum/asset/spritesheet/proc/css_tag()
	return {"<link rel="stylesheet" href="[css_filename()]" />"}

/datum/asset/spritesheet/proc/css_filename()
	return SSassets.transport.get_asset_url("spritesheet_[name].css")

/datum/asset/spritesheet/proc/icon_tag(sprite_name)
	var/sprite = sprites[sprite_name]
	if (!sprite)
		return null
	var/size_id = sprite[SPR_SIZE]
	return {"<span class='[name][size_id] [sprite_name]'></span>"}

/datum/asset/spritesheet/proc/icon_class_name(sprite_name)
	var/sprite = sprites[sprite_name]
	if (!sprite)
		return null
	var/size_id = sprite[SPR_SIZE]
	return {"[name][size_id] [sprite_name]"}

/**
 * Returns the size class (ex design32x32) for a given sprite's icon
 *
 * Arguments:
 * * sprite_name - The sprite to get the size of
 */
/datum/asset/spritesheet/proc/icon_size_id(sprite_name)
	var/sprite = sprites[sprite_name]
	if (!sprite)
		return null
	var/size_id = sprite[SPR_SIZE]
	return "[name][size_id]"

#undef SPR_SIZE
#undef SPR_IDX
#undef SPRSZ_COUNT
#undef SPRSZ_ICON
#undef SPRSZ_STRIPPED

/// Spritesheet that only uses simple PNGs and CSS keys. See `assets` variable.
/// Deprecated: Use /datum/asset/spritesheet_batched where possible
/datum/asset/spritesheet/simple
	_abstract = /datum/asset/spritesheet/simple
	/// Associative list of icon keys (CSS class names) -> PNG filepaths (single quote!)
	/// File paths MUST be PNGs
	var/list/assets

/datum/asset/spritesheet/simple/create_spritesheets()
	for (var/key in assets)
		Insert(key, assets[key])
