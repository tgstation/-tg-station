
/proc/debug_sources()
	GLOB.light_debug_enabled = TRUE
	var/list/sum = list()
	var/total = 0
	for(var/datum/light_source/source)
		if(!source.source_atom)
			continue
		source.source_atom.debug()
		sum[source.source_atom.type] += 1
		total += 1

	sortTim(sum, associative = TRUE)
	var/text = ""
	for(var/type in sum)
		text += "[type] = [sum[type]]\n"
	text += "total iterated: [total]"

	for(var/client/lad in GLOB.admins)
		var/datum/action/spawn_light/let_there_be = new (lad.mob.mind || lad.mob)
		let_there_be.Grant(lad.mob)

	// I am sorry
	SSdcs.RegisterSignal(SSdcs, COMSIG_GLOB_CLIENT_CONNECT, TYPE_PROC_REF(/datum/controller/subsystem/processing/dcs, on_client_connect))
	message_admins(text)

/datum/controller/subsystem/processing/dcs/proc/on_client_connect(datum/source, client/new_lad)
	SIGNAL_HANDLER
	var/datum/action/spawn_light/let_there_be = new (new_lad.mob.mind || new_lad.mob)
	let_there_be.Grant(new_lad.mob)

/proc/undebug_sources()
	GLOB.light_debug_enabled = FALSE
	for(var/datum/weakref/button_ref as anything in GLOB.light_debugged_atoms)
		var/atom/button = button_ref.resolve()
		if(!button)
			GLOB.light_debugged_atoms -= button_ref
			continue
		button.undebug()

	SEND_GLOBAL_SIGNAL(COMSIG_LIGHT_DEBUG_DISABLED)
	SSdcs.UnregisterSignal(SSdcs, COMSIG_GLOB_CLIENT_CONNECT)

GLOBAL_LIST_EMPTY(light_debugged_atoms)
/// Sets up this light source to be debugged, setting up in world buttons to control and move it
/// Also freezes it, so it can't change in future
/atom/proc/debug()
	if(isturf(src) || HAS_TRAIT(src, TRAIT_LIGHTING_DEBUGGED))
		return
	ADD_TRAIT(src, TRAIT_LIGHTING_DEBUGGED, LIGHT_DEBUG_TRAIT)
	GLOB.light_debugged_atoms += WEAKREF(src)
	add_filter("debug_light", 0, outline_filter(2, COLOR_CENTCOM_BLUE))
	var/static/uid = 0
	if(!render_target)
		render_target = "light_debug_[uid]"
		uid++
	var/atom/movable/render_step/color/above_light = new(null, src, "#ffffff23")
	SET_PLANE_EXPLICIT(above_light, ABOVE_LIGHTING_PLANE, src)
	add_overlay(above_light)
	QDEL_NULL(above_light)
	// Freeze our light would you please
	light_flags |= LIGHT_FROZEN
	new /atom/movable/screen/light_button/toggle(src)
	new /atom/movable/screen/light_button/edit(src)
	new /atom/movable/screen/light_button/move(src)

/// Disables light debugging, so you can let a scene fall to what it visually should be, or just fix admin fuckups
/atom/proc/undebug()
	// I don't really want to undebug a light if it's off rn
	// Loses control if we turn it back on again
	if(isturf(src) || !HAS_TRAIT(src, TRAIT_LIGHTING_DEBUGGED) || !light)
		return
	REMOVE_TRAIT(src, TRAIT_LIGHTING_DEBUGGED, LIGHT_DEBUG_TRAIT)
	GLOB.light_debugged_atoms -= WEAKREF(src)
	remove_filter("debug_light")
	// Removes the glow overlay via stupid, sorry
	var/atom/movable/render_step/color/above_light = new(null, src, "#ffffff23")
	SET_PLANE_EXPLICIT(above_light, ABOVE_LIGHTING_PLANE, src)
	cut_overlay(above_light)
	QDEL_NULL(above_light)
	var/atom/movable/lie_to_areas = src
	// Freeze our light would you please
	light_flags &= ~LIGHT_FROZEN
	for(var/atom/movable/screen/light_button/button in lie_to_areas.vis_contents)
		qdel(button)

/atom/movable/screen/light_button
	icon = 'icons/testing/lighting_debug.dmi'
	plane = BALLOON_CHAT_PLANE // We hijack runechat because we can get multiz niceness without making a new PM
	layer = ABOVE_ALL_MOB_LAYER
	alpha = 100
	var/datum/weakref/last_hovored_ref

/atom/movable/screen/light_button/Initialize(mapload)
	. = ..()
	attach_to(loc)

/atom/movable/screen/light_button/proc/attach_to(atom/new_owner)
	if(loc)
		UnregisterSignal(loc, COMSIG_QDELETING)
		var/atom/movable/mislead_areas = loc
		mislead_areas.vis_contents -= src
	forceMove(new_owner)
	layer = loc.layer
	RegisterSignal(loc, COMSIG_QDELETING, PROC_REF(delete_self))
	var/atom/movable/lie_to_areas = loc
	lie_to_areas.vis_contents += src

/atom/movable/screen/light_button/proc/delete_self(datum/source)
	SIGNAL_HANDLER
	qdel(src)

// Entered and Exited won't fire while you're dragging something, because you're still "holding" it
// Very much byond logic, but I want nice for my highlighting, so we fake it with drag
// Copypasta from action buttons
/atom/movable/screen/light_button/MouseDrag(atom/over_object, src_location, over_location, src_control, over_control, params)
	. = ..()
	if(IS_WEAKREF_OF(over_object, last_hovored_ref))
		return
	var/atom/old_object
	if(last_hovored_ref)
		old_object = last_hovored_ref?.resolve()
	else // If there's no current ref, we assume it was us. We also treat this as our "first go" location
		old_object = src

	if(old_object)
		old_object.MouseExited(over_location, over_control, params)

	last_hovored_ref = WEAKREF(over_object)
	over_object.MouseEntered(over_location, over_control, params)

/atom/movable/screen/light_button/mouse_drop_dragged(atom/over, mob/user, src_location, over_location, params)
	last_hovored_ref = null

/atom/movable/screen/light_button/MouseEntered(location, control, params)
	. = ..()
	animate(src, alpha = 255, time = 2)

/atom/movable/screen/light_button/MouseExited(location, control, params)
	. = ..()
	animate(src, alpha = initial(alpha), time = 2)

/atom/movable/screen/light_button/toggle
	name = "Toggle Light"
	desc = "Click to turn the light on/off"
	icon_state = "light_enable"

/atom/movable/screen/light_button/toggle/attach_to(atom/new_owner)
	if(loc)
		UnregisterSignal(loc, COMSIG_ATOM_UPDATE_LIGHT_ON)
	. = ..()
	RegisterSignal(loc, COMSIG_ATOM_UPDATE_LIGHT_ON, PROC_REF(on_changed))
	update_appearance()

/atom/movable/screen/light_button/toggle/Click(location, control, params)
	. = ..()
	if(!check_rights_for(usr.client, R_DEBUG))
		return
	var/atom/movable/parent = loc
	parent.light_flags &= ~LIGHT_FROZEN
	loc.set_light(l_on = !loc.light_on)
	parent.light_flags |= LIGHT_FROZEN

/atom/movable/screen/light_button/toggle/proc/on_changed()
	SIGNAL_HANDLER
	update_appearance()

/atom/movable/screen/light_button/toggle/update_icon_state()
	. = ..()
	if(loc.light_on)
		icon_state = "light_enable"
	else
		icon_state = "light_disable"

/atom/movable/screen/light_button/edit
	name = "Edit Light"
	desc = "Click to open an editing menu for the light"
	icon_state = "light_focus"

/atom/movable/screen/light_button/edit/attach_to(atom/new_owner)
	. = ..()
	SStgui.try_update_ui(usr, src, null)

/atom/movable/screen/light_button/edit/Click(location, control, params)
	. = ..()
	ui_interact(usr)

/atom/movable/screen/light_button/edit/ui_state(mob/user)
	return ADMIN_STATE(R_DEBUG)

/atom/movable/screen/light_button/edit/can_interact()
	return TRUE

/atom/movable/screen/light_button/edit/ui_interact(mob/user, datum/tgui/ui)
	ui = SStgui.try_update_ui(user, src, ui)
	if(!ui)
		ui = new(user, src, "LightController")
		ui.open()

/atom/movable/screen/light_button/edit/ui_assets(mob/user)
	return list(get_asset_datum(/datum/asset/spritesheet/lights))

/atom/movable/screen/light_button/edit/ui_data()
	var/list/data = list()

	var/atom/parent = loc
	var/list/light_info = list()
	light_info["name"] = full_capitalize(parent.name)
	light_info["on"] = parent.light_on
	light_info["power"] = parent.light_power
	light_info["range"] = parent.light_range
	light_info["color"] = parent.light_color
	light_info["angle"] = parent.light_angle
	data["light_info"] = light_info
	data["on"] = parent.light_on
	data["direction"] = parent.dir

	return data

/atom/movable/screen/light_button/edit/ui_static_data(mob/user)
	. = ..()
	var/list/data = list()
	data["templates"] = list()
	data["category_ids"] = list()
	for(var/id in GLOB.light_types)
		var/datum/light_template/template = GLOB.light_types[id]
		var/list/insert = list()
		var/list/light_info = list()
		light_info["name"] = template.name
		light_info["power"] = template.power
		light_info["range"] = template.range
		light_info["color"] = template.color
		light_info["angle"] = template.angle
		insert["light_info"] = light_info
		insert["description"] = template.desc
		insert["id"] = template.id
		insert["category"] = template.category
		if(!data["category_ids"][template.category])
			data["category_ids"][template.category] = list()
		data["category_ids"][template.category] += id
		data["templates"][template.id] = insert

	var/datum/light_template/first_template = GLOB.light_types[GLOB.light_types[1]]
	data["default_id"] = first_template.id
	data["default_category"] = first_template.category
	return data

/atom/movable/screen/light_button/edit/ui_act(action, list/params, datum/tgui/ui, datum/ui_state/state)
	. = ..()
	if(.)
		return

	var/atom/parent = loc
	parent.light_flags &= ~LIGHT_FROZEN
	switch(action)
		if("set_on")
			parent.set_light(l_on = params["value"])
		if("change_color")
			var/chosen_color = input(ui.user, "Pick new color", "[parent]", parent.light_color) as color|null
			if(chosen_color)
				parent.set_light(l_color = chosen_color)
		if("set_power")
			parent.set_light(l_power = params["value"])
		if("set_range")
			parent.set_light(l_range = params["value"])
		if("set_angle")
			// We use dir instead of light dir because anything directional should have its lightdir tied
			// And this way we can update the sprite too
			parent.set_light(l_angle = params["value"])
		if("set_dir")
			parent.setDir(params["value"])
		if("mirror_template")
			var/datum/light_template/template = GLOB.light_types[params["id"]]
			var/atom/new_light = template.create(parent.loc, parent.dir)
			var/atom/movable/lies_to_children = parent
			for(var/atom/movable/screen/light_button/button in lies_to_children.vis_contents)
				button.attach_to(new_light)

			qdel(parent)
		if("isolate")
			isolate_light(parent)

	parent.light_flags |= LIGHT_FROZEN
	return TRUE

/// Hides all the lights around a source temporarially, for the sake of figuring out how bad a light bleeds
/// (Except for turf lights, because they're a part of the "scene" and rarely modified)
/proc/isolate_light(atom/source, delay = 7 SECONDS)
	var/list/datum/lighting_corner/interesting_corners = source.light?.effect_str

	var/list/atom/sources = list()
	for(var/datum/lighting_corner/corner as anything in interesting_corners)
		for(var/datum/light_source/target_spotted as anything in corner.affecting)
			if(isturf(target_spotted.source_atom))
				continue
			sources[target_spotted.source_atom] = TRUE

	sources -= source // Please don't disable yourself
	if(!length(sources))
		return

	// Now that we have all the lights (and a bit more), let's get rid of em
	for(var/atom/light_source as anything in sources)
		light_source.light_flags &= ~LIGHT_FROZEN
		light_source.set_light(l_on = FALSE)
		light_source.light_flags |= LIGHT_FROZEN

	// Now we sleep until the lighting system has processed them
	var/current_tick = SSlighting.times_fired

	UNTIL(SSlighting.times_fired > current_tick || QDELETED(source) || !source.light)

	if(QDELETED(source) || !source.light)
		repopulate_lights(sources)
		return

	// And finally, wait the allotted time, and reawake em
	addtimer(CALLBACK(GLOBAL_PROC, GLOBAL_PROC_REF(repopulate_lights), sources), delay)

/proc/repopulate_lights(list/atom/sources)
	for(var/atom/light_source as anything in sources)
		light_source.light_flags &= ~LIGHT_FROZEN
		light_source.set_light(l_on = TRUE)
		light_source.light_flags |= LIGHT_FROZEN

/atom/movable/screen/light_button/move
	name = "Move Light"
	desc = "Drag to move the light around"
	icon_state = "light_move"
	mouse_drag_pointer = 'icons/effects/mouse_pointers/light_drag.dmi'

/atom/movable/screen/light_button/move/mouse_drop_dragged(atom/over_object)
	if(!ismovable(loc))
		return
	var/atom/movable/movable_owner = loc
	movable_owner.forceMove(get_turf(over_object))

/datum/action/spawn_light
	name = "Spawn Light"
	desc = "Create a light from a template"
	button_icon = 'icons/mob/actions/actions_construction.dmi'
	button_icon_state = "light_spawn"

/datum/action/spawn_light/New(Target)
	. = ..()
	RegisterSignal(SSdcs, COMSIG_LIGHT_DEBUG_DISABLED, PROC_REF(debug_disabled))

/datum/action/spawn_light/proc/debug_disabled()
	SIGNAL_HANDLER
	qdel(src)

/datum/action/spawn_light/Grant(mob/grant_to)
	. = ..()
	RegisterSignal(grant_to.client, COMSIG_CLIENT_MOB_LOGIN, PROC_REF(move_action), override = TRUE)

/datum/action/spawn_light/proc/move_action(client/source, mob/new_mob)
	SIGNAL_HANDLER
	Grant(new_mob)

/datum/action/spawn_light/Trigger(trigger_flags)
	. = ..()
	ui_interact(usr)

/datum/action/spawn_light/ui_state(mob/user)
	return ADMIN_STATE(R_DEBUG)

/datum/action/spawn_light/ui_interact(mob/user, datum/tgui/ui)
	ui = SStgui.try_update_ui(user, src, ui)
	if(!ui)
		ui = new(user, src, "LightSpawn")
		ui.open()

/datum/action/spawn_light/ui_assets(mob/user)
	return list(get_asset_datum(/datum/asset/spritesheet/lights))

/datum/action/spawn_light/ui_data()
	var/list/data = list()
	return data

/datum/action/spawn_light/ui_static_data(mob/user)
	. = ..()
	var/list/data = list()
	data["templates"] = list()
	data["category_ids"] = list()
	for(var/id in GLOB.light_types)
		var/datum/light_template/template = GLOB.light_types[id]
		var/list/insert = list()
		var/list/light_info = list()
		light_info["name"] = template.name
		light_info["power"] = template.power
		light_info["range"] = template.range
		light_info["color"] = template.color
		light_info["angle"] = template.angle
		insert["light_info"] = light_info
		insert["description"] = template.desc
		insert["id"] = template.id
		insert["category"] = template.category
		if(!data["category_ids"][template.category])
			data["category_ids"][template.category] = list()
		data["category_ids"][template.category] += id
		data["templates"][template.id] = insert

	var/datum/light_template/first_template = GLOB.light_types[GLOB.light_types[1]]
	data["default_id"] = first_template.id
	data["default_category"] = first_template.category
	return data

/datum/action/spawn_light/ui_act(action, list/params, datum/tgui/ui, datum/ui_state/state)
	. = ..()
	if(.)
		return

	switch(action)
		if("spawn_template")
			var/datum/light_template/template = GLOB.light_types[params["id"]]
			template.create(get_turf(owner), params["dir"])
	return TRUE
