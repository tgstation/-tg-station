#define SPR_SIZE "size_id"
#define SPR_IDX "position"
#define CACHE_WAIT "wait"
#define CACHE_INVALID TRUE
#define CACHE_VALID FALSE
/// This is used to invalidate the cache if something changes on the DM side. For example, if the CSS generator was changed.
#define SPRITESHEET_SYSTEM_VERSION 1

/datum/asset/spritesheet_batched
	_abstract = /datum/asset/spritesheet_batched
	var/name
	/// list("32x32")
	var/list/sizes = list()
	/// "foo_bar" -> list("32x32", 5, entry_obj)
	var/list/sprites = list()

	// "foo_bar" -> entry_obj
	var/list/entries = list()

	/// JSON encoded version of entries.
	var/entries_json = null

	/// If this spritesheet exists in a completed state.
	var/fully_generated = FALSE

	/// If this asset should be fully loaded on new
	/// Defaults to false so we can process this stuff nicely
	var/load_immediately = FALSE
	/// If we should avoid propogating 'invalid dir' errors from rust-g. Because sometimes, you just don't know what dirs are valid.
	var/ignore_dir_errors = FALSE

	/// Forces use of the smart cache. This is for unit tests, please respect the config <3
	var/force_cache = FALSE

	/// If there is currently an async job, its ID
	var/job_id = null
	/// If there is currently an async cache job, its ID.
	var/cache_job_id = null

	// Fields to store async cache task inputs.
	var/cache_data = null
	var/cache_sizes_data = null
	var/cache_sprites_data = null
	var/cache_input_hash = null
	var/cache_dmi_hashes = null
	var/cache_dmi_hashes_json = null
	/// Used to prevent async cache refresh jobs from looping on failure.
	var/cache_result = null

/datum/asset/spritesheet_batched/proc/should_load_immediately()
#ifdef DO_NOT_DEFER_ASSETS
	return TRUE
#else
	return load_immediately
#endif

/// Returns true if the cache should be invalidated/doesn't exist.
/datum/asset/spritesheet_batched/should_refresh(yield)
	. = CACHE_INVALID // in the case of any errors, we need to regenerate.
	if(!fexists("[ASSET_CROSS_ROUND_SMART_CACHE_DIRECTORY]/spritesheet_cache.[name].json"))
		return CACHE_INVALID
	if(!fexists("data/spritesheets/spritesheet_[name].css"))
		return CACHE_INVALID
	if(isnull(cache_data) || isnull(cache_dmi_hashes_json))
		cache_data = rustg_file_read("[ASSET_CROSS_ROUND_SMART_CACHE_DIRECTORY]/spritesheet_cache.[name].json")
		if(!findtext(cache_data, "{", 1, 2)) // cache isn't valid JSON
			log_asset("Cache for spritesheet_[name] was not valid JSON. This is abnormal. Likely tampered with or IO failure.")
			return CACHE_INVALID
		var/cache_json = json_decode(cache_data)
		// Best to invalidate if rustg updates, since the way icons are handled can change.
		var/cached_rustg_version = cache_json["rustg_version"]
		if(isnull(cached_rustg_version))
			log_asset("Cache for spritesheet_[name] did not contain a rustg_version!")
			return CACHE_INVALID
		var/rustg_version = rustg_get_version()
		if(cached_rustg_version != rustg_version)
			log_asset("Invalidated cache for spritesheet_[name] due to rustg updating from [cached_rustg_version] to [rustg_version].")
			return CACHE_INVALID
				// Invalidate cache if the DM version changes
		var/cached_dm_version = cache_json["dm_version"]
		if(isnull(cached_dm_version))
			log_asset("Cache for spritesheet_[name] did not contain a dm_version!")
			return CACHE_INVALID
		if(cached_dm_version != SPRITESHEET_SYSTEM_VERSION)
			log_asset("Invalidated cache for spritesheet_[name] due to DM spritesheet system updating from [cached_dm_version] to [SPRITESHEET_SYSTEM_VERSION].")
			return CACHE_INVALID
		cache_sizes_data = cache_json["sizes"]
		cache_sprites_data = cache_json["sprites"]
		cache_input_hash = cache_json["input_hash"]
		cache_dmi_hashes = cache_json["dmi_hashes"]
		if(!length(cache_dmi_hashes) || !length(cache_input_hash) || !length(cache_sizes_data) || !length(cache_sprites_data))
			log_asset("Cache for spritesheet_[name] did not contain the correct data. This is abnormal. Likely tampered with.")
			return CACHE_INVALID
		cache_dmi_hashes_json = json_encode(cache_dmi_hashes)
	var/data_out

	if(yield || !isnull(cache_job_id))
		if(isnull(cache_job_id))
			cache_job_id = rustg_iconforge_cache_valid_async(cache_input_hash, cache_dmi_hashes_json, entries_json)
		. = CACHE_WAIT // if we return during this, WAIT!!
		UNTIL((data_out = rustg_iconforge_check(cache_job_id)) != RUSTG_JOB_NO_RESULTS_YET)
		cache_job_id = null
		. = CACHE_INVALID // reset back to normal, invalid on CRASH
	else
		data_out = rustg_iconforge_cache_valid(cache_input_hash, cache_dmi_hashes_json, entries_json)
	if (data_out == RUSTG_JOB_ERROR)
		CRASH("Spritesheet [name] cache JOB PANIC")
	else if(!findtext(data_out, "{", 1, 2))
		rustg_file_write(cache_data, "[GLOB.log_directory]/spritesheet_cache_debug.[name].json")
		rustg_file_write(entries_json, "[GLOB.log_directory]/spritesheet_debug_[name].json")
		CRASH("Spritesheet [name] cache check UNKNOWN ERROR: [data_out]")
	var/result = json_decode(data_out)
	var/fail = result["fail_reason"]
	if(length(fail) || result["result"] != "1")
		if(findtextEx(fail, "ERROR:"))
			CRASH("Spritesheet [name] cache check UNKNOWN [fail]")
		log_asset("Invalidated cache for spritesheet_[name]: [fail]")
		return CACHE_INVALID
	// Populate the sizes and sprites list.
	sizes = cache_sizes_data
	sprites = cache_sprites_data
	log_asset("Validated cache for spritesheet_[name]!")
	return CACHE_VALID

/datum/asset/spritesheet_batched/proc/insert_icon(sprite_name, datum/universal_icon/entry)
	if(!istext(sprite_name) || !length(sprite_name))
		CRASH("Invalid sprite_name \"[sprite_name]\" given to insert_icon()! Providing non-strings will break icon generation.")
	if(!istype(entry))
		CRASH("Invalid type provided to insert_icon()! Value: [entry] (type: [entry?.type])")
	entries[sprite_name] = entry.to_list()

/datum/asset/spritesheet_batched/register()
	SHOULD_NOT_OVERRIDE(TRUE)

	if (!name)
		CRASH("spritesheet [type] cannot register without a name")

	// Create our input data first, so we can compare to the cache.
	create_spritesheets()

	if(should_load_immediately())
		realize_spritesheets(yield = FALSE)
	else
		SSasset_loading.queue_asset(src)

/datum/asset/spritesheet_batched/unregister()
	CRASH("unregister() called on batched spritesheet! Bad!")

/// Call insert_icon or insert_all_icons here, building a spritesheet!
/datum/asset/spritesheet_batched/proc/create_spritesheets()
	SHOULD_CALL_PARENT(FALSE)
	CRASH("create_spritesheets() not implemented for [type]!")

/datum/asset/spritesheet_batched/proc/insert_all_icons(prefix, icon/I, list/directions, prefix_with_dirs = TRUE)
	if (length(prefix))
		prefix = "[prefix]-"

	if (!directions)
		directions = list(SOUTH)

	for (var/icon_state_name in icon_states(I))
		for (var/direction in directions)
			var/prefix2 = (directions.len > 1 && prefix_with_dirs) ? "[dir2text(direction)]-" : ""
			insert_icon("[prefix][prefix2][icon_state_name]", uni_icon(I, icon_state_name, direction))

/datum/asset/spritesheet_batched/proc/realize_spritesheets(yield)
	if(fully_generated)
		return
	if(!length(entries))
		CRASH("Spritesheet [name] ([type]) is empty! What are you doing?")

	if(isnull(entries_json))
		entries_json = json_encode(entries)

	if(isnull(cache_result))
		cache_result = should_refresh(yield)
		if(cache_result == CACHE_WAIT) // sleep interrupted by MC. We'll get queried again later.
			cache_result = null
			return

	// read_from_cache returns false if config is disabled, otherwise it fully loads the spritesheet.
	if (cache_result == CACHE_VALID && read_from_cache())
		SSasset_loading.dequeue_asset(src)
		fully_generated = TRUE
		return
	// Remove the cache, since it's invalid if we get to this point.
	fdel("[ASSET_CROSS_ROUND_SMART_CACHE_DIRECTORY]/spritesheet_cache.[name].json")

	var/do_cache = CONFIG_GET(flag/smart_cache_assets) || force_cache
	var/data_out
	if(yield || !isnull(job_id))
		if(isnull(job_id))
			job_id = rustg_iconforge_generate_async("data/spritesheets/", name, entries_json, do_cache)
		UNTIL((data_out = rustg_iconforge_check(job_id)) != RUSTG_JOB_NO_RESULTS_YET)
	else
		data_out = rustg_iconforge_generate("data/spritesheets/", name, entries_json, do_cache)
	if (data_out == RUSTG_JOB_ERROR)
		CRASH("Spritesheet [name] JOB PANIC")
	else if(!findtext(data_out, "{", 1, 2))
		rustg_file_write(entries_json, "[GLOB.log_directory]/spritesheet_debug_[name].json")
		CRASH("Spritesheet [name] UNKNOWN ERROR: [data_out]")
	var/data = json_decode(data_out)
	sizes = data["sizes"]
	sprites = data["sprites"]
	var/input_hash = data["sprites_hash"]
	var/dmi_hashes = data["dmi_hashes"] // this only contains values if do_cache is TRUE.

	for(var/size_id in sizes)
		var/png_name = "[name]_[size_id].png"
		var/file_directory = "data/spritesheets/[png_name]"
		var/file_hash = rustg_hash_file("md5", file_directory)
		SSassets.transport.register_asset(png_name, fcopy_rsc(file_directory), file_hash)
		if(CONFIG_GET(flag/save_spritesheets))
			save_to_logs(file_name = png_name, file_location = file_directory)
	var/css_name = "spritesheet_[name].css"
	var/file_directory = "data/spritesheets/[css_name]"

	fdel(file_directory)
	var/css = generate_css()
	rustg_file_write(css, file_directory)
	var/css_hash = rustg_hash_string("md5", css)
	SSassets.transport.register_asset(css_name, fcopy_rsc(file_directory), file_hash=css_hash)

	if(CONFIG_GET(flag/save_spritesheets))
		save_to_logs(file_name = css_name, file_location = file_directory)

	if (do_cache)
		write_cache_meta(input_hash, dmi_hashes)
	fully_generated = TRUE
	// If we were ever in there, remove ourselves
	SSasset_loading.dequeue_asset(src)
	if(data["error"] && !(ignore_dir_errors && findtext(data["error"], "is not in the set of valid dirs")))
		CRASH("Error during spritesheet generation for [name]: [data["error"]]")

/datum/asset/spritesheet_batched/queued_generation()
	realize_spritesheets(yield = TRUE)

/datum/asset/spritesheet_batched/ensure_ready()
	if(!fully_generated)
		realize_spritesheets(yield = FALSE)
	return ..()

/datum/asset/spritesheet_batched/send(client/client)
	if (!name)
		return

	var/all = list("spritesheet_[name].css")
	for(var/size_id in sizes)
		all += "[name]_[size_id].png"
	. = SSassets.transport.send_assets(client, all)

/datum/asset/spritesheet_batched/get_url_mappings()
	if (!name)
		return

	. = list("spritesheet_[name].css" = SSassets.transport.get_asset_url("spritesheet_[name].css"))
	for(var/size_id in sizes)
		.["[name]_[size_id].png"] = SSassets.transport.get_asset_url("[name]_[size_id].png")

/datum/asset/spritesheet_batched/proc/generate_css()
	var/list/out = list()

	for (var/size_id in sizes)
		var/size_split = splittext(size_id, "x")
		var/width = text2num(size_split[1])
		var/height = text2num(size_split[2])
		out += ".[name][size_id]{display:inline-block;width:[width]px;height:[height]px;background-image:url('[get_background_url("[name]_[size_id].png")]');background-repeat:no-repeat;}"

	for (var/sprite_id in sprites)
		var/sprite = sprites[sprite_id]
		var/size_id = sprite[SPR_SIZE]
		var/idx = sprite[SPR_IDX]

		var/size_split = splittext(size_id, "x")
		var/width = text2num(size_split[1])
		var/x = idx * width
		var/y = 0

		out += ".[name][size_id].[sprite_id]{background-position:-[x]px -[y]px;}"

	return out.Join("\n")

/datum/asset/spritesheet_batched/proc/read_from_cache()
	if(!CONFIG_GET(flag/smart_cache_assets) && !force_cache)
		return FALSE
	// this is already guaranteed to exist.
	var/css_name = "spritesheet_[name].css"
	var/css_file_directory = "data/spritesheets/[css_name]"

	// sizes gets filled during should_refresh()
	for(var/size_id in sizes)
		var/fname = "data/spritesheets/[name]_[size_id].png"
		if(!fexists(fname))
			return FALSE

	var/css_hash = rustg_hash_file("md5", css_file_directory)
	SSassets.transport.register_asset(css_name, fcopy_rsc(css_file_directory), file_hash=css_hash)
	for(var/size_id in sizes)
		var/fname = "data/spritesheets/[name]_[size_id].png"
		var/hash = rustg_hash_file("md5", fname)
		SSassets.transport.register_asset("[name]_[size_id].png", fcopy_rsc(fname), file_hash=hash)

	if(CONFIG_GET(flag/save_spritesheets))
		save_to_logs(file_name = css_name, file_location = css_file_directory)

	return TRUE

/// Returns the URL to put in the background:url of the CSS asset
/datum/asset/spritesheet_batched/proc/get_background_url(asset)
	return SSassets.transport.get_asset_url(asset)

/datum/asset/spritesheet_batched/proc/write_cache_meta(input_hash, dmi_hashes)
	var/list/cache_data = list(
		"input_hash" = input_hash,
		"dmi_hashes" = dmi_hashes,
		"sizes" = sizes,
		"sprites" = sprites,
		"rustg_version" = rustg_get_version(),
		"dm_version" = SPRITESHEET_SYSTEM_VERSION,
	)
	rustg_file_write(json_encode(cache_data), "[ASSET_CROSS_ROUND_SMART_CACHE_DIRECTORY]/spritesheet_cache.[name].json")

/**
 * Third party helpers
 * ===================
 */

/datum/asset/spritesheet_batched/proc/css_tag()
	return {"<link rel="stylesheet" href="[css_filename()]" />"}

/datum/asset/spritesheet_batched/proc/css_filename()
	return SSassets.transport.get_asset_url("spritesheet_[name].css")

/datum/asset/spritesheet_batched/proc/icon_tag(sprite_name)
	var/sprite = sprites[sprite_name]
	if (!sprite)
		return null
	var/size_id = sprite[SPR_SIZE]
	return "<span class='[name][size_id] [sprite_name]'></span>"

/datum/asset/spritesheet_batched/proc/icon_class_name(sprite_name)
	var/sprite = sprites[sprite_name]
	if (!sprite)
		return null
	var/size_id = sprite[SPR_SIZE]
	return "[name][size_id] [sprite_name]"

/**
 * Returns the size class (ex design32x32) for a given sprite's icon
 *
 * Arguments:
 * * sprite_name - The sprite to get the size of
 */
/datum/asset/spritesheet_batched/proc/icon_size_id(sprite_name)
	var/sprite = sprites[sprite_name]
	if (!sprite)
		return null
	var/size_id = sprite[SPR_SIZE]
	return "[name][size_id]"

#undef SPR_SIZE
#undef SPR_IDX
#undef CACHE_WAIT
#undef CACHE_INVALID
#undef CACHE_VALID
#undef SPRITESHEET_SYSTEM_VERSION
