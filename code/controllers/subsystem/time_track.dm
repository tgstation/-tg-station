SUBSYSTEM_DEF(time_track)
	name = "Time Tracking"
	wait = 100
	init_order = INIT_ORDER_TIMETRACK
	runlevels = RUNLEVEL_LOBBY | RUNLEVELS_DEFAULT

	var/time_dilation_current = 0

	var/time_dilation_avg_fast = 0
	var/time_dilation_avg = 0
	var/time_dilation_avg_slow = 0

	var/first_run = TRUE

	var/last_tick_realtime = 0
	var/last_tick_byond_time = 0
	var/last_tick_tickcount = 0
	var/list/sendmaps_names_map = list(
		"SendMaps" = "send_maps",
		"SendMaps: Initial housekeeping" = "initial_house",
		"SendMaps: Cleanup" = "cleanup",
		"SendMaps: Client loop" = "client_loop",
		"SendMaps: Per client" = "per_client",
		"SendMaps: Per client: Deleted images" = "deleted_images",
		"SendMaps: Per client: HUD update" = "hud_update",
		"SendMaps: Per client: Statpanel update" = "statpanel_update",
		"SendMaps: Per client: Map data" = "map_data",
		"SendMaps: Per client: Map data: Check eye position" = "check_eye_pos",
		"SendMaps: Per client: Map data: Update chunks" = "update_chunks",
		"SendMaps: Per client: Map data: Send turfmap updates" = "turfmap_updates",
		"SendMaps: Per client: Map data: Send changed turfs" = "changed_turfs",
		"SendMaps: Per client: Map data: Send turf chunk info" = "turf_chunk_info",
		"SendMaps: Per client: Map data: Send obj changes" = "obj_changes",
		"SendMaps: Per client: Map data: Send mob changes" = "mob_changes",
		"SendMaps: Per client: Map data: Send notable turf visual contents" = "send_turf_vis_conts",
		"SendMaps: Per client: Map data: Send pending animations" = "pending_animations",
		"SendMaps: Per client: Map data: Look for movable changes" = "look_for_movable_changes",
		"SendMaps: Per client: Map data: Look for movable changes: Check notable turf visual contents" = "check_turf_vis_conts",
		"SendMaps: Per client: Map data: Look for movable changes: Check HUD/image visual contents" = "check_hud/image_vis_contents",
		"SendMaps: Per client: Map data: Look for movable changes: Loop through turfs in range" = "turfs_in_range",
		"SendMaps: Per client: Map data: Look for movable changes: Movables examined" = "movables_examined",
	)

/datum/controller/subsystem/time_track/Initialize()
	GLOB.perf_log = "[GLOB.log_directory]/perf-[GLOB.round_id ? GLOB.round_id : "NULL"]-[SSmapping.current_map.map_name].csv"
	world.Profile(PROFILE_RESTART, type = "sendmaps")
	//Need to do the sendmaps stuff in its own file, since it works different then everything else
	var/list/sendmaps_headers = list()
	for(var/proper_name in sendmaps_names_map)
		sendmaps_headers += sendmaps_names_map[proper_name]
		sendmaps_headers += "[sendmaps_names_map[proper_name]]_count"
	log_perf(
		list(
			"time",
			"players",
			"tidi",
			"tidi_fastavg",
			"tidi_avg",
			"tidi_slowavg",
			"maptick",
			"num_timers",
			"air_turf_cost",
			"air_eg_cost",
			"air_highpressure_cost",
			"air_hotspots_cost",
			"air_superconductivity_cost",
			"air_pipenets_cost",
			"air_rebuilds_cost",
			"air_turf_count",
			"air_eg_count",
			"air_hotspot_count",
			"air_network_count",
			"air_delta_count",
			"air_superconductive_count",
			"all_queries",
			"queries_active",
			"queries_standby"
		) + sendmaps_headers
	)
	return SS_INIT_SUCCESS

/datum/controller/subsystem/time_track/fire()

	var/current_realtime = REALTIMEOFDAY
	var/current_byondtime = world.time
	var/current_tickcount = world.time/world.tick_lag

	if (!first_run)
		var/tick_drift = max(0, (((current_realtime - last_tick_realtime) - (current_byondtime - last_tick_byond_time)) / world.tick_lag))

		time_dilation_current = tick_drift / (current_tickcount - last_tick_tickcount) * 100

		time_dilation_avg_fast = MC_AVERAGE_FAST(time_dilation_avg_fast, time_dilation_current)
		time_dilation_avg = MC_AVERAGE(time_dilation_avg, time_dilation_avg_fast)
		time_dilation_avg_slow = MC_AVERAGE_SLOW(time_dilation_avg_slow, time_dilation_avg)
		GLOB.old_glide_size_multiplier = (current_byondtime - last_tick_byond_time) / (current_realtime - last_tick_realtime)
	else
		first_run = FALSE
	last_tick_realtime = current_realtime
	last_tick_byond_time = current_byondtime
	last_tick_tickcount = current_tickcount

	var/sendmaps_json = world.Profile(PROFILE_REFRESH, type = "sendmaps", format="json")
	var/list/send_maps_data = null
	try
		send_maps_data = json_decode(sendmaps_json)
	catch
		text2file(sendmaps_json,"bad_sendmaps.json")
		can_fire = FALSE
		return
	var/send_maps_sort = send_maps_data.Copy() //Doing it like this guarantees us a properly sorted list

	for(var/list/packet in send_maps_data)
		send_maps_sort[packet["name"]] = packet

	var/list/send_maps_values = list()
	for(var/entry_name in sendmaps_names_map)
		var/list/packet = send_maps_sort[entry_name]
		if(!packet) //If the entry does not have a value for us, just put in 0 for both
			send_maps_values += 0
			send_maps_values += 0
			continue
		send_maps_values += packet["value"]
		send_maps_values += packet["calls"]

	SSblackbox.record_feedback("associative", "time_dilation_current", 1, list("[ISOtime()]" = list("current" = "[time_dilation_current]", "avg_fast" = "[time_dilation_avg_fast]", "avg" = "[time_dilation_avg]", "avg_slow" = "[time_dilation_avg_slow]")))
	log_perf(
		list(
			world.time,
			length(GLOB.clients),
			time_dilation_current,
			time_dilation_avg_fast,
			time_dilation_avg,
			time_dilation_avg_slow,
			MAPTICK_LAST_INTERNAL_TICK_USAGE,
			length(SStimer.timer_id_dict),
			SSair.cost_turfs,
			SSair.cost_groups,
			SSair.cost_highpressure,
			SSair.cost_hotspots,
			SSair.cost_superconductivity,
			SSair.cost_pipenets,
			SSair.cost_rebuilds,
			length(SSair.active_turfs),
			length(SSair.excited_groups),
			length(SSair.hotspots),
			length(SSair.networks),
			length(SSair.high_pressure_delta),
			length(SSair.active_super_conductivity),
			SSdbcore.all_queries_num,
			SSdbcore.queries_active_num,
			SSdbcore.queries_standby_num
		) + send_maps_values
	)

	SSdbcore.reset_tracking()
