/datum/asset/spritesheet_batched/telecomms
	name = "tcomms"

/datum/asset/spritesheet_batched/telecomms/create_spritesheets()
	var/list/inserted_states = list() // No need to send entire `telecomms.dmi`.
	for(var/obj/machinery/telecomms/machine as anything in subtypesof(/obj/machinery/telecomms))
		var/icon_state = machine::icon_state
		if(icon_state in inserted_states)
			continue

		insert_icon(icon_state, uni_icon(machine::icon, icon_state))
		inserted_states += icon_state
