/// Used to test the game for issues with different types of color blindness
/// WARNING ASSHOLE: Because we can only apply matrixes, and can't preform gamma correction
/// https://web.archive.org/web/20220227030606/https://ixora.io/projects/colorblindness/color-blindness-simulation-research/
/// The results of this tool aren't perfect. It's way better then nothing, but IT IS NOT A PROPER SIMULATION
/// Please do not make us look like assholes by assuming it is. Thanks.
/datum/colorblind_tester
	/// List of simulated blindness -> matrix to use
	/// Most of these matrixes are based off https://web.archive.org/web/20220227030606/https://ixora.io/projects/colorblindness/color-blindness-simulation-research/
	/// AGAIN, THESE ARE NOT PERFECT BECAUSE WE CANNOT COMPUTE GAMMA CORRECTION, AND CONVERT SRGB TO LINEAR RGB
	/// Do not assume this is absolute
	var/list/color_matrixes = list(
		"Protanopia" = list(0.56,0.43,0,0, 0.55,0.44,0,0, 0,0.24,0.75,0, 0,0,0,1, 0,0,0,0),
		"Deuteranopia" = list(0.62,0.37,0,0, 0.70,0.30,0,0, 0,0.30,0.70,0, 0,0,0,1, 0,0,0,0),
		"Tritanopia" = list(0.95,0.5,0,0, 0,0.43,0.56,0, 0,0.47,0.52,0, 0,0,0,1, 0,0,0,0),
		"Achromatopsia" = list(0.33,0.33,0.33,0, 0.33,0.33,0.33,0, 0.33,0.33,0.33,0, 0,0,0,1, 0,0,0,0),
	)
	var/list/descriptions = list(
		"Protanopia" = "No long wavelength cones, ends up not being able to see red light. Troubles with blue/green and red/green",
		"Deuteranopia" = "No medium wavelength cones. Because the red and green parts of light nearly overlap in this space, trouble is mostly with red/green",
		"Tritanopia" = "No short wavelength cones, so trouble with blue/green and yellow/violet. Aggressively rare, and equally hard to simulate",
		"Achromatopsia" = "No cones at all, which leads to something close to monochromatic vision"
	)
	var/selected_type = ""

/datum/colorblind_tester/ui_state(mob/user)
	return ADMIN_STATE(R_DEBUG)

/datum/colorblind_tester/ui_interact(mob/user, datum/tgui/ui)
	ui = SStgui.try_update_ui(user, src, ui)
	if(!ui)
		ui = new(user, src, "ColorBlindTester")
		ui.open()

/datum/colorblind_tester/ui_data()
	var/list/data = list()
	data["details"] = descriptions
	data["selected"] = selected_type
	return data

/datum/colorblind_tester/ui_act(action, list/params, datum/tgui/ui, datum/ui_state/state)
	. = ..()
	if(.)
		return

	var/datum/hud/our_hud = ui.user?.hud_used
	if(!our_hud) // Nothing to act on
		return

	switch(action)
		if("set_matrix")
			set_selected_type(params["name"], our_hud)
			return TRUE
		if("clear_matrix")
			set_selected_type("", our_hud)
			return TRUE

/datum/colorblind_tester/proc/set_selected_type(selected, datum/hud/remove_from)
	var/atom/movable/plane_master_controller/colorblind_planes = remove_from.plane_master_controllers[PLANE_MASTERS_COLORBLIND]
	// This is dumb, but well
	// The parralax plane has a blend mode of 4, or BLEND_MULTIPLY
	// It's like that so it is properly masked by darkness and such
	// The problem is blend modes apply to filters like this too
	// So I need to manually set and reset its blendmode to allow for proper shading of the background
	// Sorry...
	if(selected_type)
		colorblind_planes.remove_filter(selected_type)
		for(var/atom/movable/screen/plane_master/parralax as anything in remove_from.get_true_plane_masters(PLANE_SPACE_PARALLAX))
			parralax.blend_mode = initial(parralax.blend_mode)
	selected_type = selected
	if(selected_type)
		var/list/matrix = color_matrixes[selected_type]
		colorblind_planes.add_filter(selected_type, 0, color_matrix_filter(matrix))
		for(var/atom/movable/screen/plane_master/parralax as anything in remove_from.get_true_plane_masters(PLANE_SPACE_PARALLAX))
			parralax.blend_mode = BLEND_DEFAULT
