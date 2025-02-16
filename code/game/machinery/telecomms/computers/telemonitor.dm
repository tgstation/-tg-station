#define MAIN_VIEW 0
#define MACHINE_VIEW 1
#define MAX_NETWORK_ID_LENGTH 15

/obj/machinery/computer/telecomms/monitor
	name = "telecommunications monitoring console"
	desc = "Monitors the details of the telecommunications network it's synced with."
	circuit = /obj/item/circuitboard/computer/comm_monitor

	icon_screen = "comm_monitor"

	/// Weakref of the currently selected tcomms machine
	var/datum/weakref/selected_machine_ref = null
	/// Weakrefs of the machines located by the computer
	var/list/datum/weakref/machine_refs

	/// Currently displayed "tab"
	var/screen = MAIN_VIEW
	/// The network to probe
	var/network = "NULL"
	/// Error message to show
	var/status_message = null

/obj/machinery/computer/telecomms/monitor/Initialize(mapload, obj/item/circuitboard/C)
	. = ..()
	LAZYINITLIST(machine_refs)

/obj/machinery/computer/telecomms/monitor/ui_assets(mob/user)
	return list(
		get_asset_datum(/datum/asset/spritesheet_batched/telecomms),
	)

/obj/machinery/computer/telecomms/monitor/ui_interact(mob/user, datum/tgui/ui)
	. = ..()

	ui = SStgui.try_update_ui(user, src, ui)
	if(!ui)
		ui = new(user, src, "TelecommsMonitor")
		ui.open()

/obj/machinery/computer/telecomms/monitor/ui_data(mob/user)
	var/list/data = list()

	data["screen"] = screen
	data["statusMessage"] = status_message

	switch(screen)
		if(MAIN_VIEW)
			data["network"] = network

			data["machines"] = list()
			for(var/datum/weakref/machine_ref in machine_refs)
				var/obj/machinery/telecomms/machine = machine_ref.resolve()
				if(isnull(machine))
					machine_refs -= machine_ref
					continue

				data["machines"] += list(list(
					"id" = machine.id,
					"name" = machine.name,
					"icon" = initial(machine.icon_state),
				))

		if(MACHINE_VIEW)
			var/obj/machinery/telecomms/selected = selected_machine_ref?.resolve()
			if(!isnull(selected))
				var/list/linked_machines = list()
				for(var/obj/machinery/telecomms/machine as anything in selected.links)
					linked_machines += list(list(
						"id" = machine.id,
						"name" = machine.name,
						"icon" = initial(machine.icon_state),
					))

				data["machine"] = list(
					"id" = selected.id,
					"name" = selected.name,
					"network" = selected.network,
					"linkedMachines" = linked_machines,
				)

	return data

/obj/machinery/computer/telecomms/monitor/ui_act(action, list/params, datum/tgui/ui, datum/ui_state/state)
	. = ..()
	if(.)
		return

	status_message = null

	switch(action)
		if("flush")
			machine_refs = list()
			network = ""
			return TRUE

		if("home")
			selected_machine_ref = null
			screen = MAIN_VIEW
			return TRUE

		if("view")
			var/machine_id = params["id"]
			if(isnull(machine_id))
				return

			for(var/datum/weakref/machine_ref as anything in machine_refs)
				var/obj/machinery/telecomms/machine = machine_ref.resolve()
				if(isnull(machine))
					machine_refs -= machine_ref
					continue

				if(machine.id != machine_id)
					continue

				selected_machine_ref = machine_ref
				screen = MACHINE_VIEW

			if(isnull(selected_machine_ref))
				status_message = "OPERATION FAILED: UNABLE TO LOCATE MACHINERY."

			return TRUE

		if("probe")
			var/network_id = params["id"]
			if(length(network_id) > MAX_NETWORK_ID_LENGTH)
				status_message = "OPERATION FAILED: NETWORK ID TOO LONG."
				return TRUE

			list_clear_empty_weakrefs(machine_refs)

			if(length(machine_refs) > 0)
				status_message = "OPERATION FAILED: CANNOT PROBE WHEN BUFFER FULL."
				return TRUE

			network = network_id

			var/list/telecomms_machines = SSmachines.get_machines_by_type_and_subtypes(/obj/machinery/telecomms)
			for(var/obj/machinery/telecomms/machine as anything in telecomms_machines)
				if(machine.network != network)
					continue

				machine_refs += WEAKREF(machine)

			if(length(machine_refs) == 0)
				status_message = "OPERATION FAILED: UNABLE TO LOCATE NETWORK ENTITIES IN [network]."
				return TRUE

			status_message = "[length(machine_refs)] ENTITIES LOCATED & BUFFERED"
			return TRUE

	return TRUE

#undef MAIN_VIEW
#undef MACHINE_VIEW
#undef MAX_NETWORK_ID_LENGTH
