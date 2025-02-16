/datum/color_matrix_editor
	var/client/owner
	var/datum/weakref/target
	var/atom/movable/screen/map_view/proxy_view
	var/list/current_color
	var/closed

/datum/color_matrix_editor/New(user, atom/_target = null)
	owner = CLIENT_FROM_VAR(user)
	if(islist(_target?.color))
		current_color = _target.color
	else if(istext(_target?.color))
		current_color = color_hex2color_matrix(_target.color)
	else
		current_color = COLOR_MATRIX_IDENTITY

	var/mutable_appearance/view = image('icons/testing/colortest.dmi', "colors")
	if(_target)
		target = WEAKREF(_target)
		if(!(_target.appearance_flags & PLANE_MASTER))
			view = image(_target)

	proxy_view = new
	proxy_view.generate_view("color_matrix_proxy_[REF(src)]")

	proxy_view.appearance = view
	proxy_view.color = current_color
	proxy_view.display_to(owner.mob)

/datum/color_matrix_editor/Destroy(force)
	QDEL_NULL(proxy_view)
	return ..()

/datum/color_matrix_editor/ui_state(mob/user)
	return ADMIN_STATE(R_VAREDIT)

/datum/color_matrix_editor/ui_static_data(mob/user)
	var/list/data = list()
	data["mapRef"] = proxy_view.assigned_map

	return data

/datum/color_matrix_editor/ui_data(mob/user)
	var/list/data = list()
	data["currentColor"] = current_color

	return data

/datum/color_matrix_editor/ui_interact(mob/user, datum/tgui/ui)
	ui = SStgui.try_update_ui(user, src, ui)
	if(!ui)
		ui = new(user, src, "ColorMatrixEditor")
		ui.open()

/datum/color_matrix_editor/ui_act(action, list/params, datum/tgui/ui, datum/ui_state/state)
	. = ..()
	if(.)
		return
	switch(action)
		if("transition_color")
			current_color = params["color"]
			animate(proxy_view, time = 4, color = current_color)
		if("confirm")
			on_confirm()
			SStgui.close_uis(src)

/datum/color_matrix_editor/ui_close(mob/user)
	. = ..()
	closed = TRUE

/datum/color_matrix_editor/proc/on_confirm()
	var/atom/target_atom = target?.resolve()
	if(istype(target_atom))
		target_atom.vv_edit_var("color", current_color)

/datum/color_matrix_editor/proc/wait()
	while(!closed)
		stoplag(1)

/client/proc/open_color_matrix_editor(atom/in_atom)
	var/datum/color_matrix_editor/editor = new /datum/color_matrix_editor(src, in_atom)
	editor.ui_interact(mob)
	editor.wait()
	. = editor.current_color
	qdel(editor)
