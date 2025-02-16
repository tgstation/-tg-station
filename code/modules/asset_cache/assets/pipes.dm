/datum/asset/spritesheet_batched/pipes
	name = "pipes"
	ignore_dir_errors = TRUE

/datum/asset/spritesheet_batched/pipes/create_spritesheets()
	for (var/each in list('icons/obj/pipes_n_cables/pipe_item.dmi', 'icons/obj/pipes_n_cables/disposal.dmi', 'icons/obj/pipes_n_cables/transit_tube.dmi', 'icons/obj/pipes_n_cables/hydrochem/fluid_ducts.dmi'))
		insert_all_icons("", each, GLOB.alldirs)
