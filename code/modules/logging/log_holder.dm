GLOBAL_REAL(logger, /datum/log_holder)
/**
 * Main datum to manage logging actions
 */
/datum/log_holder
	/// Round ID, if set, that logging is initialized for
	var/round_id
	/// When the log_holder first initialized
	var/logging_start_timestamp

	/// Associative: category -> datum
	var/list/datum/log_category/log_categories
	/// typecache list for categories that exist but are disabled
	var/list/disabled_categories
	/// category nesting tree for ui purposes
	var/list/category_group_tree

	/// list of Log args waiting for processing pending log initialization
	var/list/waiting_log_calls

	/// Whether or not logging as human readable text is enabled
	var/human_readable_enabled = FALSE

	/// Cached ui_data
	var/list/data_cache = list()

	/// Last time the ui_data was updated
	var/last_data_update = 0

	var/initialized = FALSE
	var/shutdown = FALSE

GENERAL_PROTECT_DATUM(/datum/log_holder)

ADMIN_VERB(log_viewer_new, R_ADMIN|R_DEBUG, "View Round Logs", "View the rounds logs.", ADMIN_CATEGORY_MAIN)
	logger.ui_interact(user.mob)

/datum/log_holder/ui_interact(mob/user, datum/tgui/ui)
	if(!check_rights_for(user.client, R_ADMIN))
		return

	ui = SStgui.try_update_ui(user, src, ui)
	if(isnull(ui))
		ui = new(user, src, "LogViewer")
		ui.set_autoupdate(FALSE)
		ui.open()

/datum/log_holder/ui_state(mob/user)
	return ADMIN_STATE(R_ADMIN | R_DEBUG)

/datum/log_holder/ui_static_data(mob/user)
	var/list/data = list(
		"round_id" = GLOB.round_id,
		"logging_start_timestamp" = logging_start_timestamp,
	)

	var/list/tree = list()
	data["tree"] = tree
	var/list/enabled_categories = list()
	for(var/enabled in log_categories)
		enabled_categories += enabled
	tree["enabled"] = enabled_categories

	var/list/disabled_categories = list()
	for(var/disabled in src.disabled_categories)
		disabled_categories += disabled
	tree["disabled"] = disabled_categories

	return data

/datum/log_holder/ui_data(mob/user)
	if(!last_data_update || (world.time - last_data_update) > LOG_UPDATE_TIMEOUT)
		cache_ui_data()
	return data_cache

/datum/log_holder/proc/cache_ui_data()
	var/list/category_map = list()
	for(var/datum/log_category/category as anything in log_categories)
		category = log_categories[category]
		var/list/category_data = list()

		var/list/entries = list()
		for(var/datum/log_entry/entry as anything in category.entries)
			entries += list(list(
				"id" = entry.id,
				"message" = entry.message,
				"timestamp" = entry.timestamp,
				"data" = entry.data,
				"semver" = entry.semver_store,
			))
		category_data["entries"] = entries
		category_data["entry_count"] = category.entry_count

		category_map[category.category] = category_data

	data_cache.Cut()
	last_data_update = world.time

	data_cache["categories"] = category_map
	data_cache["last_data_update"] = last_data_update

/datum/log_holder/ui_act(action, list/params, datum/tgui/ui, datum/ui_state/state)
	. = ..()
	if(.)
		return

	switch(action)
		if("refresh")
			cache_ui_data()
			SStgui.update_uis(src)
			return TRUE
		else
			stack_trace("unknown ui_act action [action] for [type]")

/// Assembles basic information for logging, creating the log category datums and checking for config flags as required
/datum/log_holder/proc/init_logging()
	if(initialized)
		CRASH("Attempted to call init_logging twice!")

	round_id = GLOB.round_id
	logging_start_timestamp = rustg_unix_timestamp()
	log_categories = list()
	disabled_categories = list()

	human_readable_enabled = CONFIG_GET(flag/log_as_human_readable)

	category_group_tree = assemble_log_category_tree()
	var/config_flag
	for(var/datum/log_category/master_category as anything in category_group_tree)
		var/list/sub_categories = category_group_tree[master_category]
		sub_categories = sub_categories.Copy()
		for(var/datum/log_category/sub_category as anything in sub_categories)
			config_flag = initial(sub_category.config_flag)
			if(config_flag && !config.Get(config_flag))
				disabled_categories[initial(sub_category.category)] = TRUE
				sub_categories -= sub_category
				continue

		config_flag = initial(master_category.config_flag)
		if(config_flag && !config.Get(config_flag))
			disabled_categories[initial(master_category.category)] = TRUE
			if(!length(sub_categories))
				continue
		// enabled, or any of the sub categories are enabled
		init_log_category(master_category, sub_categories)

	initialized = TRUE

	// process any waiting log calls and then cut the list
	for(var/list/arg_list as anything in waiting_log_calls)
		Log(arglist(arg_list))
	waiting_log_calls?.Cut()

	if(fexists(GLOB.config_error_log))
		fcopy(GLOB.config_error_log, "[GLOB.log_directory]/config_error.log")
		fdel(GLOB.config_error_log)

	world._initialize_log_files()

/// Tells the log_holder to not allow any more logging to be done, and dumps all categories to their json file
/datum/log_holder/proc/shutdown_logging()
	if(shutdown)
		CRASH("Attempted to call shutdown_logging twice!")
	shutdown = TRUE

/// Iterates over all log category types to assemble them into a tree of main category -> (sub category)[] while also checking for loops and sanity errors
/datum/log_holder/proc/assemble_log_category_tree()
	var/static/list/category_tree
	if(category_tree)
		return category_tree

	category_tree = list()
	var/list/all_types = subtypesof(/datum/log_category)
	var/list/known_categories = list()
	var/list/sub_categories = list()

	// Assemble the master categories
	for(var/datum/log_category/category_type as anything in all_types)
		var/category = initial(category_type.category)
		if(category in known_categories)
			stack_trace("log category type '[category_type]' has duplicate category '[category]', skipping")
			continue

		if(!initial(category_type.schema_version))
			stack_trace("log category type '[category_type]' does not have a valid schema version, skipping")
			continue

		var/master_category = initial(category_type.master_category)
		if(master_category)
			sub_categories[master_category] += list(category_type)
			continue
		category_tree[category_type] = list()

	// Sort the sub categories
	for(var/datum/log_category/master as anything in sub_categories)
		if(!(master in category_tree))
			stack_trace("log category [master] is an invalid master category as it's a sub category")
			continue
		for(var/datum/log_category/sub_category as anything in sub_categories[master])
			if(initial(sub_category.secret) != initial(master.secret))
				stack_trace("log category [sub_category] has a secret status that differs from its master category [master]")
			category_tree[master] += list(sub_category)

	return category_tree

/// Log entry header used to mark a file is being reset
#define LOG_CATEGORY_RESET_FILE_MARKER "{\"LOG FILE RESET -- THIS IS AN ERROR\"}"
#define LOG_CATEGORY_RESET_FILE_MARKER_READABLE "LOG FILE RESET -- THIS IS AN ERROR"
/// Gets a recovery file for the given path. Caches the last known recovery path for each path.
/datum/log_holder/proc/get_recovery_file_for(path)
	var/static/cache
	if(isnull(cache))
		cache = list()

	var/count = cache[path] || 0
	while(fexists("[path].rec[count]"))
		count++
	cache[path] = count

	return "[path].rec[count]"

/// Sets up the given category's file and header.
/datum/log_holder/proc/init_category_file(datum/log_category/category)
	var/file_path = category.get_output_file(null)
	if(fexists(file_path)) // already exists? implant a reset marker
		rustg_file_append(LOG_CATEGORY_RESET_FILE_MARKER, file_path)
		fcopy(file_path, get_recovery_file_for(file_path))
	rustg_file_write("[json_encode(category.category_header)]\n", file_path)

	if(!human_readable_enabled)
		return

	file_path = category.get_output_file(null, "log")
	if(fexists(file_path))
		rustg_file_append(LOG_CATEGORY_RESET_FILE_MARKER_READABLE, file_path)
		fcopy(file_path, get_recovery_file_for(file_path))
	rustg_file_write("\[[human_readable_timestamp()]\] Starting up round ID [round_id].\n - -------------------------\n", file_path)

#undef LOG_CATEGORY_RESET_FILE_MARKER
#undef LOG_CATEGORY_RESET_FILE_MARKER_READABLE

/// Initializes the given log category and populates the list of contained categories based on the sub category list
/datum/log_holder/proc/init_log_category(datum/log_category/category_type, list/datum/log_category/sub_categories)
	var/datum/log_category/category_instance = new category_type

	var/list/contained_categories = list()
	for(var/datum/log_category/sub_category as anything in sub_categories)
		sub_category = new sub_category
		var/sub_category_actual = sub_category.category
		sub_category.master_category = category_instance
		log_categories[sub_category_actual] = sub_category

		if(!semver_to_list(sub_category.schema_version))
			stack_trace("log category [sub_category_actual] has an invalid schema version '[sub_category.schema_version]'")
			sub_category.schema_version = LOG_CATEGORY_SCHEMA_VERSION_NOT_SET

		contained_categories += sub_category_actual

	log_categories[category_instance.category] = category_instance

	if(!semver_to_list(category_instance.schema_version))
		stack_trace("log category [category_instance.category] has an invalid schema version '[category_instance.schema_version]'")
		category_instance.schema_version = LOG_CATEGORY_SCHEMA_VERSION_NOT_SET

	contained_categories += category_instance.category

	var/list/category_header = list(
		LOG_HEADER_INIT_TIMESTAMP = logging_start_timestamp,
		LOG_HEADER_ROUND_ID = GLOB.round_id,
		LOG_HEADER_SECRET = category_instance.secret,
		LOG_HEADER_CATEGORY_LIST = contained_categories,
		LOG_HEADER_CATEGORY = category_instance.category,
	)

	category_instance.category_header = category_header
	init_category_file(category_instance, category_header)

/datum/log_holder/proc/human_readable_timestamp(precision = 3)
	var/start = time2text(world.timeofday, "YYYY-MM-DD hh:mm:ss")
	// now we grab the millis from the rustg timestamp
	var/rustg_stamp = rustg_unix_timestamp()
	var/list/timestamp = splittext(rustg_stamp, ".")
#ifdef UNIT_TESTS
	if(length(timestamp) != 2)
		stack_trace("rustg returned illegally formatted string '[rustg_stamp]'")
		return start
#endif
	var/millis = timestamp[2]
	if(length(millis) > precision)
		millis = copytext(millis, 1, precision + 1)
	return "[start].[millis]"

/// Adds an entry to the given category, if the category is disabled it will not be logged.
/// If the category does not exist, we will CRASH and log to the error category.
/// the data list is optional and will be recursively json serialized.
/datum/log_holder/proc/Log(category, message, list/data)
	// This is Log because log is a byond internal proc

	// do not include the message because these go into the runtime log and we might be secret!
	if(!istext(message))
		message = "[message]"
		stack_trace("Logging with a non-text message")

	if(!category)
		category = LOG_CATEGORY_INTERNAL_CATEGORY_NOT_FOUND
		stack_trace("Logging with a null or empty category")

	if(data && !islist(data))
		data = list("data" = data)
		stack_trace("Logging with data this is not a list, it will be converted to a list with a single key 'data'")

	if(!initialized) // we are initialized during /world/proc/SetupLogging which is called in /world/New
		waiting_log_calls += list(list(category, message, data))
		return

	if(disabled_categories[category])
		return

	var/datum/log_category/log_category = log_categories[category]
	if(!log_category)
		Log(LOG_CATEGORY_INTERNAL_CATEGORY_NOT_FOUND, message, data)
		CRASH("Attempted to log to a category that doesn't exist! [category]")

	var/list/semver_store = null
	if(length(data))
		semver_store = list()
		data = recursive_jsonify(data, semver_store)
	log_category.create_entry(message, data, semver_store)

/// Recursively converts an associative list of datums into their jsonified(list) form
/datum/log_holder/proc/recursive_jsonify(list/data_list, list/semvers)
	if(isnull(data_list))
		return null

	var/list/jsonified_list = list()
	for(var/key in data_list)
		var/datum/data = data_list[key]

		if(isnull(data))
			pass() // nulls are allowed

		else if(islist(data))
			data = recursive_jsonify(data, semvers)

		else if(isdatum(data))
			var/list/options_list = list(
				SCHEMA_VERSION = LOG_CATEGORY_SCHEMA_VERSION_NOT_SET,
			)

			var/list/serialization_data = data.serialize_list(options_list, semvers)
			var/current_semver = semvers[data.type]
			if(!semver_to_list(current_semver))
				stack_trace("serialization of data had an invalid semver")
				semvers[data.type] = LOG_CATEGORY_SCHEMA_VERSION_NOT_SET

			if(!length(serialization_data)) // serialize_list wasn't implemented, and errored
				stack_trace("serialization data was empty")
				continue

			data = recursive_jsonify(serialization_data, semvers)

		if(islist(data) && !length(data))
			stack_trace("recursive_jsonify got an empty list after serialization")
			continue

		jsonified_list[key] = data

	return jsonified_list
