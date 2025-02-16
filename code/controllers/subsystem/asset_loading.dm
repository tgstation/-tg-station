/// Allows us to lazyload asset datums
/// Anything inserted here will fully load if directly gotten
/// So this just serves to remove the requirement to load assets fully during init
SUBSYSTEM_DEF(asset_loading)
	name = "Asset Loading"
	priority = FIRE_PRIORITY_ASSETS
	flags = SS_NO_INIT
	runlevels = RUNLEVEL_LOBBY|RUNLEVELS_DEFAULT
	var/list/datum/asset/generate_queue = list()
	var/last_queue_len = 0

/datum/controller/subsystem/asset_loading/fire(resumed)
	while(length(generate_queue))
		var/datum/asset/to_load = generate_queue[generate_queue.len]

		to_load.queued_generation()

		if(MC_TICK_CHECK)
			return
		last_queue_len = length(generate_queue)
		generate_queue.len--
	// We just emptied the queue
	if(last_queue_len && !length(generate_queue))
		// Clean up cached icons, freeing memory.
		rustg_iconforge_cleanup()

/datum/controller/subsystem/asset_loading/proc/queue_asset(datum/asset/queue)
#ifdef DO_NOT_DEFER_ASSETS
	stack_trace("We queued an instance of [queue.type] for lateloading despite not allowing it")
#endif
	generate_queue += queue

/datum/controller/subsystem/asset_loading/proc/dequeue_asset(datum/asset/queue)
	generate_queue -= queue
