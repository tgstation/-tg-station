/datum/asset/spritesheet_batched/plumbing
	name = "plumbing-tgui"

/datum/asset/spritesheet_batched/plumbing/create_spritesheets()
	//load only what we need from the icon files,format is icon_file_name = list of icon_states we need from this file
	var/list/essentials = list(
		'icons/obj/medical/iv_drip.dmi' = list("plumb"),
		'icons/obj/pipes_n_cables/hydrochem/fluid_ducts.dmi' = list("nduct"),
		'icons/hud/radial.dmi' = list(
			"plumbing_layer1",
			"plumbing_layer2",
			"plumbing_layer4",
			"plumbing_layer8",
			"plumbing_layer16",
		),
		'icons/obj/pipes_n_cables/hydrochem/plumbers.dmi' = list(
			"synthesizer",
			"reaction_chamber",
			"grinder_chemical",
			"fermenter",
			"pump",
			"disposal",
			"buffer",
			"manifold",
			"pipe_input",
			"filter",
			"splitter",
			"beacon",
			"pipe_output",
			"tank",
			"acclimator",
			"bottler",
			"pill_press",
			"synthesizer_soda",
			"synthesizer_booze",
			"tap_output",
		),
	)

	for(var/icon_file as anything in essentials)
		for(var/icon_state as anything in essentials[icon_file])
			insert_icon(icon_state, uni_icon(icon_file, icon_state))

