
/**
 * ## nobody wants to learn matrix math!
 *
 * More than just a completely true statement, this datum is created as a tgui interface
 * allowing you to modify each vector until you know what you're doing.
 * Much like filteriffic, 'nobody wants to learn matrix math' is meant for developers like you and I
 * to implement interesting matrix transformations without the hassle if needing to know... algebra? Damn, i'm stupid.
 */
/datum/nobody_wants_to_learn_matrix_math
	var/atom/target
	var/matrix/testing_matrix

/datum/nobody_wants_to_learn_matrix_math/New(atom/target)
	src.target = target
	testing_matrix = matrix(target.transform)

/datum/nobody_wants_to_learn_matrix_math/Destroy(force)
	QDEL_NULL(testing_matrix)
	return ..()

/datum/nobody_wants_to_learn_matrix_math/ui_state(mob/user)
	return ADMIN_STATE(R_VAREDIT)

/datum/nobody_wants_to_learn_matrix_math/ui_close(mob/user)
	qdel(src)

/datum/nobody_wants_to_learn_matrix_math/ui_interact(mob/user, datum/tgui/ui)
	ui = SStgui.try_update_ui(user, src, ui)
	if(!ui)
		ui = new(user, src, "MatrixMathTester")
		ui.open()

/datum/nobody_wants_to_learn_matrix_math/ui_data()
	var/list/data = list()
	data["matrix_a"] = testing_matrix.a
	data["matrix_b"] = testing_matrix.b
	data["matrix_c"] = testing_matrix.c
	data["matrix_d"] = testing_matrix.d
	data["matrix_e"] = testing_matrix.e
	data["matrix_f"] = testing_matrix.f
	data["pixelated"] = target.appearance_flags & PIXEL_SCALE
	return data

/datum/nobody_wants_to_learn_matrix_math/ui_act(action, list/params, datum/tgui/ui, datum/ui_state/state)
	. = ..()
	if(.)
		return

	switch(action)
		if("change_var")
			var/matrix_var_name = params["var_name"]
			var/matrix_var_value = params["var_value"]
			if(testing_matrix.vv_edit_var(matrix_var_name, matrix_var_value) == FALSE)
				to_chat(src, "Your edit was rejected by the object. This is a bug with the matrix tester, not your fault, so report it on GitHub.", confidential = TRUE)
				return
			set_transform()
		if("scale")
			testing_matrix.Scale(params["x"], params["y"])
			set_transform()
		if("translate")
			testing_matrix.Translate(params["x"], params["y"])
			set_transform()
		if("shear")
			testing_matrix.Shear(params["x"], params["y"])
			set_transform()
		if("turn")
			testing_matrix.Turn(params["angle"])
			set_transform()
		if("toggle_pixel")
			target.appearance_flags ^= PIXEL_SCALE

/datum/nobody_wants_to_learn_matrix_math/proc/set_transform()
	animate(target, transform = testing_matrix, time = 0.5 SECONDS)
	testing_matrix = matrix(target.transform)

/client/proc/open_matrix_tester(atom/in_atom)
	if(holder)
		var/datum/nobody_wants_to_learn_matrix_math/matrix_tester = new(in_atom)
		matrix_tester.ui_interact(mob)
