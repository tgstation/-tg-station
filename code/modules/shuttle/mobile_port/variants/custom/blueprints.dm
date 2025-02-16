GLOBAL_LIST_INIT(shuttle_construction_area_whitelist, list(/area/space, /area/lavaland, /area/icemoon, /area/station/asteroid))

/obj/effect/client_image_holder/shuttle_construction_visualization
	image_icon = 'icons/effects/alphacolors.dmi'
	image_state = "transparent"
	image_layer = ABOVE_NORMAL_TURF_LAYER
	image_plane = ABOVE_GAME_PLANE
	mouse_opacity = MOUSE_OPACITY_TRANSPARENT
	persist_without_seers = TRUE

/datum/proximity_monitor/advanced/shuttle_construction_visualizer
	edge_is_a_field = TRUE
	var/mob/user
	var/list/image_holders = list()
	var/obj/item/shuttle_blueprints/parent

/datum/proximity_monitor/advanced/shuttle_construction_visualizer/New(atom/_host, range, _ignore_if_not_on_turf)
	. = ..()
	parent = _host

/datum/proximity_monitor/advanced/shuttle_construction_visualizer/Destroy()
	. = ..()
	parent = null
	QDEL_LIST_ASSOC_VAL(image_holders)

/datum/proximity_monitor/advanced/shuttle_construction_visualizer/proc/set_user(mob/new_user)
	if(user)
		for(var/turf in image_holders)
			var/obj/effect/client_image_holder/holder = image_holders[turf]
			holder.remove_seer(user)
		UnregisterSignal(user, list(COMSIG_MOB_LOGIN, COMSIG_MOB_LOGOUT))
		var/client/client = user.client
		if(client)
			UnregisterSignal(client, list(COMSIG_VIEW_SET, COMSIG_CLIENT_SET_EYE))
	if(new_user)
		user = new_user
		for(var/turf in image_holders)
			var/obj/effect/client_image_holder/holder = image_holders[turf]
			holder.add_seer(user)
		RegisterSignal(user, COMSIG_MOB_LOGIN, PROC_REF(on_user_login))
		RegisterSignal(user, COMSIG_MOB_LOGOUT, PROC_REF(unregister_client))
		var/client/client = user.client
		if(client)
			register_client(client)
	else
		unregister_client()

/datum/proximity_monitor/advanced/shuttle_construction_visualizer/proc/register_client(client/client)
	var/atom/eye = client.eye
	if(eye)
		set_host(client.eye)
	var/list/view_size = getviewsize(client.view)
	set_range(CEILING(max(view_size[1], view_size[2])/2, 1)+1)
	RegisterSignal(client, COMSIG_VIEW_SET, PROC_REF(on_view_set))
	RegisterSignal(client, COMSIG_CLIENT_SET_EYE, PROC_REF(on_set_eye))

/datum/proximity_monitor/advanced/shuttle_construction_visualizer/proc/unregister_client()
	SIGNAL_HANDLER
	set_host(parent)
	set_range(0)

/datum/proximity_monitor/advanced/shuttle_construction_visualizer/proc/on_user_login(mob/source)
	SIGNAL_HANDLER
	register_client(source.client)

/datum/proximity_monitor/advanced/shuttle_construction_visualizer/proc/on_view_set(datum/source, new_view)
	SIGNAL_HANDLER
	var/list/view_size = getviewsize(new_view)
	set_range(CEILING(max(view_size[1], view_size[2])/2, 1)+1)

/datum/proximity_monitor/advanced/shuttle_construction_visualizer/proc/on_set_eye(datum/source, atom/old_eye, atom/new_eye)
	SIGNAL_HANDLER
	set_host(new_eye)

/datum/proximity_monitor/advanced/shuttle_construction_visualizer/setup_field_turf(turf/target)
	var/obj/effect/client_image_holder/shuttle_construction_visualization/holder = new(target, list())
	image_holders[target] = holder
	evaluate_turf_overlay(holder, target)
	RegisterSignals(target, list(
		COMSIG_TURF_CHANGE,
		COMSIG_TURF_AREA_CHANGED,
		SIGNAL_ADDTRAIT(TRAIT_SHUTTLE_CONSTRUCTION_TURF),
		SIGNAL_REMOVETRAIT(TRAIT_SHUTTLE_CONSTRUCTION_TURF)
	), PROC_REF(on_turf_updated))
	if(user)
		holder.add_seer(user)

/datum/proximity_monitor/advanced/shuttle_construction_visualizer/cleanup_field_turf(turf/target)
	qdel(image_holders[target])
	image_holders -= target
	UnregisterSignal(target, list(
		COMSIG_TURF_CHANGE,
		COMSIG_TURF_AREA_CHANGED,
		SIGNAL_ADDTRAIT(TRAIT_SHUTTLE_CONSTRUCTION_TURF),
		SIGNAL_REMOVETRAIT(TRAIT_SHUTTLE_CONSTRUCTION_TURF)
	))

/datum/proximity_monitor/advanced/shuttle_construction_visualizer/proc/on_turf_updated(turf/source)
	SIGNAL_HANDLER
	evaluate_turf_overlay(image_holders[source], source)

/datum/proximity_monitor/advanced/shuttle_construction_visualizer/proc/evaluate_turf_overlay(obj/effect/client_image_holder/holder, turf/target)
	var/area/turf_area = target.loc
	if(HAS_TRAIT(target, TRAIT_SHUTTLE_CONSTRUCTION_TURF))
		if(is_type_in_list(turf_area, GLOB.shuttle_construction_area_whitelist) || GLOB.custom_areas[turf_area])
			holder.image_state = "green"
		else
			holder.image_state = "red"
	else
		if(GLOB.custom_areas[turf_area] && HAS_TRAIT(turf_area, TRAIT_HAS_SHUTTLE_CONSTRUCTION_TURF))
			holder.image_state = "red"
		else
			holder.image_state = "transparent"
	holder.regenerate_image()

/obj/item/shuttle_blueprints
	name = "shuttle blueprints"
	desc = "A blank sheet of synthetic engineering-grade paper."
	icon = 'icons/obj/scrolls.dmi'
	icon_state = "shuttle_blueprints0"
	base_icon_state = "shuttle_blueprints"
	inhand_icon_state = "blueprints"
	attack_verb_continuous = list("attacks", "baps", "hits")
	attack_verb_simple = list("attack", "bap", "hit")
	interaction_flags_atom = parent_type::interaction_flags_atom | INTERACT_ATOM_ALLOW_USER_LOCATION | INTERACT_ATOM_IGNORE_MOBILITY

	var/base_desc = "A blank sheet of synthetic engineering-grade paper."
	var/linked_desc = "A sheet of synthetic engineering-grade paper with shuttle schematics printed on it."

	//A weakref to the mobile docking port of the shuttle these blueprints are linked to, if any.
	var/datum/weakref/shuttle_ref

	//Whether the holder can visualize shuttle frames (and any turfs preventing them from becoming complete shuttles)
	var/visualize_frame_turfs = FALSE

	var/offset_x = 0
	var/offset_y = 0

	var/datum/proximity_monitor/advanced/shuttle_construction_visualizer/prox_monitor

/obj/item/shuttle_blueprints/Initialize(mapload)
	. = ..()
	prox_monitor = new(src, 0, FALSE)
	update_appearance()

/obj/item/shuttle_blueprints/equipped(mob/user, slot, initial)
	. = ..()
	var/static/list/connections = list(COMSIG_ITEM_PRE_ATTACK = PROC_REF(christen_check))
	if(slot == ITEM_SLOT_HANDS)
		AddComponent(/datum/component/connect_inventory, user, connections, allowed_slots = ITEM_SLOT_HANDS)

/obj/item/shuttle_blueprints/dropped(mob/user, silent)
	. = ..()
	stop_visualizing(user)
	qdel(GetComponent(/datum/component/connect_inventory))

/obj/item/shuttle_blueprints/proc/christen_check(obj/item/reagent_containers/cup/glass/bottle/source, atom/attacked, mob/living/user)
	SIGNAL_HANDLER
	var/obj/docking_port/mobile/custom/shuttle = shuttle_ref?.resolve()
	if(!istype(shuttle))
		return
	if(!iswallturf(attacked))
		return
	if(!istype(source))
		return
	if(SSshuttle.get_containing_shuttle(attacked) != shuttle)
		return
	if(HAS_TRAIT_FROM(user, TRAIT_ATTEMPTING_CHRISTENING, REF(shuttle)))
		return
	. = COMPONENT_CANCEL_ATTACK_CHAIN
	if(shuttle.master_blueprint?.resolve() != src)
		to_chat(user, span_warning("Only the master blueprint for \the [shuttle] grants you the right to rechristen [shuttle.p_them()]!"))
		return
	var/turf/user_turf = get_turf(user)
	if(user_turf && isshuttleturf(user_turf))
		to_chat(user, span_warning("You can't rechristen \the [shuttle] from inside of [shuttle.p_them()]!"))
		return
	if(!source.isGlass)
		to_chat(user, span_warning("You can't break [source] against [attacked]!"))
		return
	if(source.reagents.total_volume < CHEMICAL_QUANTISATION_LEVEL)
		to_chat(user, span_warning("You should put some christening fluid in [source]!"))
		return
	INVOKE_ASYNC(src, PROC_REF(christen), user, shuttle, attacked, user.active_hand_index)

/obj/item/shuttle_blueprints/proc/christen(mob/living/user, obj/docking_port/mobile/custom/shuttle, atom/attacked, hand)
	var/trait_source = REF(shuttle)
	ADD_TRAIT(user, TRAIT_ATTEMPTING_CHRISTENING, trait_source)
	var/new_name = reject_bad_name(tgui_input_text(user, "What would you like to rechristen \the [shuttle] as?", "Shuttle Rechristening", max_length = 128), allow_numbers = TRUE, strict = TRUE, cap_after_symbols = FALSE)
	if(QDELETED(user))
		return
	REMOVE_TRAIT(user, TRAIT_ATTEMPTING_CHRISTENING, trait_source)
	if(!new_name)
		user.balloon_alert(user, "cancelled")
		return
	new_name = apply_text_macros(new_name)
	var/obj/item/hitting_implement = (locate(/obj/item/reagent_containers/cup/glass/bottle) in user.held_items) || user.get_item_for_held_index(hand)
	if(!user.CanReach(attacked, hitting_implement))
		user.balloon_alert(user, "out of range!")
		return
	var/obj/item/reagent_containers/cup/glass/bottle/bottle = hitting_implement
	bottle = istype(bottle) && bottle.isGlass && bottle
	var/shuttle_exists = !QDELETED(shuttle)
	if(!shuttle_exists)
		to_chat(user, span_warning("Wasn't there supposed to be a shuttle here?"))
	var/has_blueprints = !QDELETED(src) && (src in user.gather_belongings())
	var/turf/attacked_turf = attacked
	var/is_closed_turf = isclosedturf(attacked_turf)
	var/is_shuttle_turf = isshuttleturf(attacked_turf)
	var/off_shuttle = SSshuttle.get_containing_shuttle(get_turf(user)) != shuttle
	var/has_bottle = istype(bottle)
	var/bottle_empty = bottle && bottle.reagents.total_volume < CHEMICAL_QUANTISATION_LEVEL
	var/is_clumsy = HAS_TRAIT(user, TRAIT_CLUMSY)
	var/clumsy_check = is_clumsy && prob(25)
	if(!(has_blueprints && is_closed_turf && is_shuttle_turf && off_shuttle && has_bottle && !clumsy_check && !bottle_empty))
		var/msg = "[user] tries to christen the shuttle with [hitting_implement ? "[hitting_implement.get_examine_name()]" : "[user.p_their()] empty fist"]"
		var/self_msg = "You try to christen the shuttle with [hitting_implement ? "[hitting_implement.get_examine_name()]" : "your empty fist"]"
		if(!is_closed_turf || clumsy_check)
			msg += ", but miss[user.p_es()], hitting [user.p_themselves()] instead"
			self_msg += ", but miss, hitting yourself instead"
			msg += "!"
			self_msg += "!"
			if(is_clumsy)
				msg += " What a klutz!"
			var/old_combat_mode = user.combat_mode
			user.set_combat_mode(TRUE)
			// Stupid code to bypass pacifism checks, since unintentional hits like this one shouldn't be blocked by pacifism
			var/list/pacifism_sources = GET_TRAIT_SOURCES(user, TRAIT_PACIFISM)
			REMOVE_TRAIT(user, TRAIT_PACIFISM, pacifism_sources)
			if(hitting_implement)
				hitting_implement.attack(user, user)
				bottle?.smash(user, user) // Because smashing a bottle isn't part of its main melee attack chain
			else
				user.resolve_unarmed_attack(user)
			if(length(pacifism_sources))
				ADD_TRAIT(user, TRAIT_PACIFISM, pacifism_sources)
			user.set_combat_mode(old_combat_mode)
		else
			if(!shuttle_exists)
				msg += ", but there was no shuttle to christen!"
				self_msg += ", but there was no shuttle to christen!"
			else if(!off_shuttle)
				msg += ", but you're suppossed to do that <i>outside</i> of [shuttle.p_them()]!"
				self_msg += ", but you're suppossed to do that <i>outside</i> of [shuttle.p_them()]!"
			else if(!is_shuttle_turf)
				msg += ", but miss[user.p_es()], hitting [attacked] instead!"
				self_msg += ", but miss, hitting [attacked] instead!"
			else if(!has_bottle)
				if(hitting_implement)
					msg += " - which isn't a glass bottle!"
					self_msg += " - which isn't a glass bottle!"
				else
					msg += "! That's not how you're supposed to do it!"
					self_msg += "! Aren't you supposed to use a glass bottle?"
			else if(bottle_empty)
				msg += ", but there's no christening fluid in [bottle]!"
				self_msg += ", but there's no christening fluid in [bottle]!"
			else if(!has_blueprints)
				msg += ", but [user.p_have()] no right to do so!"
				msg += ", but have no right to do so!"
			user.do_attack_animation(attacked, used_item = hitting_implement)
			if(hitting_implement && !bottle)
				if(hitting_implement.force)
					playsound(hitting_implement, 'sound/items/weapons/smash.ogg', hitting_implement.get_clamped_volume(), TRUE, hitting_implement.stealthy_audio ? SILENCED_SOUND_EXTRARANGE : -1, falloff_distance = 0)
				else
					playsound(hitting_implement, 'sound/items/weapons/tap.ogg', hitting_implement.get_clamped_volume(), TRUE, -1)
			else if(bottle)
				bottle.smash(attacked, user)
			else
				playsound(user, 'sound/effects/bang.ogg', 50, TRUE)
		user.visible_message(span_warning(msg), span_warning(self_msg))
	else
		user.visible_message(
			span_notice("[user] christens the shuttle as <b>\the [new_name]</b> with [hitting_implement.get_examine_name()]\
			[(bottle.reagents.total_volume < 30) ? "" : ", though the dearth of christening fluid makes for an unimpressive display"]."),
			span_notice("You christen the shuttle as <b>\the [new_name]</b> with [hitting_implement.get_examine_name()].")
		)
		user.do_attack_animation(attacked, used_item = bottle)
		bottle.smash(attacked, user)
		shuttle.name = new_name
		rename_area(shuttle.default_area, new_name)

/obj/item/shuttle_blueprints/proc/start_visualizing(mob/user)
	visualize_frame_turfs = TRUE
	RegisterSignal(user, SIGNAL_ADDTRAIT(TRAIT_USER_SCOPED), PROC_REF(stop_visualizing))
	prox_monitor.set_user(user)
	prox_monitor.recalculate_field()

/obj/item/shuttle_blueprints/proc/stop_visualizing(mob/user)
	SIGNAL_HANDLER
	visualize_frame_turfs = FALSE
	UnregisterSignal(user, SIGNAL_ADDTRAIT(TRAIT_USER_SCOPED))
	prox_monitor.set_user(null)

/obj/item/shuttle_blueprints/ui_interact(mob/user, datum/tgui/ui)
	ui = SStgui.try_update_ui(user, src, ui)
	if(!ui)
		ui = new(user, src, "ShuttleBlueprints", name)
		ui.open()
		RegisterSignal(user, COMSIG_ENTER_AREA, PROC_REF(on_user_enter_area))

/obj/item/shuttle_blueprints/ui_close(mob/user)
	. = ..()
	UnregisterSignal(user, COMSIG_ENTER_AREA)

/obj/item/shuttle_blueprints/proc/on_user_enter_area(mob/source, area/new_area)
	var/obj/docking_port/mobile/custom/shuttle = shuttle_ref?.resolve()
	if(shuttle && shuttle.default_area == new_area)
		update_static_data(source)

/obj/item/shuttle_blueprints/ui_state(mob/user)
	return GLOB.hands_state

/obj/item/shuttle_blueprints/ui_static_data(mob/user)
	var/list/data = list()
	var/obj/docking_port/mobile/custom/shuttle = shuttle_ref?.resolve()
	if(get_area(user) == shuttle?.default_area && length(shuttle?.shuttle_areas) > 1)
		var/list/neighboring_areas = list()
		var/room_turfs = detect_room(get_turf(user), max_size = CONFIG_GET(number/max_shuttle_size), extra_check = CALLBACK(GLOBAL_PROC, GLOBAL_PROC_REF(custom_shuttle_room_check), shuttle, neighboring_areas))
		if(room_turfs)
			data["apcInMergeRegion"] = shuttle.default_area.apc && room_turfs[get_turf(shuttle.default_area.apc)]
			var/list/area_refs = list()
			for(var/area/neighboring_area in neighboring_areas)
				area_refs[REF(neighboring_area)] = neighboring_area.name
			data["neighboringAreas"] = area_refs
	return data

/obj/item/shuttle_blueprints/ui_data(mob/user)
	var/data = list()
	var/turf/current_turf = get_turf(user)
	var/obj/docking_port/mobile/custom/linked_shuttle = shuttle_ref?.resolve()
	var/linked_to_shuttle = istype(linked_shuttle)
	data["linkedShuttle"] = linked_to_shuttle && shuttle_ref.reference
	data["visualizing"] = visualize_frame_turfs
	data["onShuttleFrame"] = HAS_TRAIT(current_turf, TRAIT_SHUTTLE_CONSTRUCTION_TURF)
	if(!linked_to_shuttle)
		var/obj/docking_port/mobile/custom/loc_shuttle = SSshuttle.get_containing_shuttle(current_turf)
		data["tooManyShuttles"] = length(SSshuttle.custom_shuttles) >= CONFIG_GET(number/max_shuttle_count)
		data["onCustomShuttle"] = istype(loc_shuttle)
		data["masterExists"] = loc_shuttle?.master_blueprint?.resolve()
	else
		var/obj/item/shuttle_blueprints/master = linked_shuttle.master_blueprint?.resolve()
		data["masterExists"] = master
		data["isMaster"] = master == src
		var/area/current_area = get_area(current_turf)
		var/area/default_area = linked_shuttle.default_area
		data["onShuttle"] = linked_shuttle.shuttle_areas[current_area]
		data["inDefaultArea"] = default_area == current_area
		data["currentArea"] = list(name = current_area.name, ref = REF(current_area))
		data["defaultApc"] = !!default_area.apc
		var/list/apcs = list()
		for(var/area/area as anything in linked_shuttle.shuttle_areas - default_area)
			apcs[REF(area)] = !!area.apc
		data["apcs"] = apcs
		data["idle"] = linked_shuttle.mode == SHUTTLE_IDLE
	return data

/obj/item/shuttle_blueprints/proc/link_to_shuttle(obj/docking_port/mobile/custom/shuttle, is_master = FALSE)
	shuttle_ref = WEAKREF(shuttle)
	if(is_master)
		shuttle.master_blueprint = WEAKREF(src)
	RegisterSignal(shuttle, COMSIG_QDELETING, PROC_REF(on_shuttle_deleted))
	update_appearance()

/obj/item/shuttle_blueprints/proc/on_shuttle_deleted()
	SIGNAL_HANDLER
	unlink(removing = TRUE)

/obj/item/shuttle_blueprints/proc/unlink(removing = FALSE)
	var/obj/docking_port/mobile/custom/shuttle = shuttle_ref.resolve()
	if(!QDELETED(shuttle))
		UnregisterSignal(shuttle, COMSIG_QDELETING)
	shuttle_ref = null
	update_appearance()

/obj/item/shuttle_blueprints/update_name(updates)
	. = ..()
	var/obj/docking_port/mobile/shuttle = shuttle_ref?.resolve()
	if(shuttle)
		name = get_linked_name(shuttle)
	else
		name = initial(name)

/obj/item/shuttle_blueprints/proc/get_linked_name(obj/docking_port/mobile/shuttle)
	return "\improper [shuttle.name] blueprints"

/obj/item/shuttle_blueprints/update_desc(updates)
	. = ..()
	desc = shuttle_ref?.resolve() ? linked_desc : base_desc

/obj/item/shuttle_blueprints/update_icon_state()
	. = ..()
	icon_state = "[base_icon_state][!!shuttle_ref]"

/obj/item/shuttle_blueprints/vv_edit_var(vname, vval)
	. = ..()
	if(!.)
		return
	if(vname == NAMEOF(src, desc))
		if(shuttle_ref?.resolve())
			linked_desc = vval
		else
			base_desc = vval
		update_desc()

/obj/item/shuttle_blueprints/examine(mob/user)
	. = ..()
	. += get_shuttle_tip()

/obj/item/shuttle_blueprints/proc/get_shuttle_tip()
	. = list()
	if(!shuttle_ref)
		. += span_notice("It can be used to construct a custom shuttle.")
		return
	var/obj/docking_port/mobile/custom/shuttle = shuttle_ref.resolve()
	if(!shuttle)
		. += span_notice("It has the plans for a shuttle that no longer exists. It can be reused to construct a new shuttle.")
	else
		. += span_notice("It has the plans for \the [shuttle] on it, and can be used to expand [shuttle.p_them()] or modify [shuttle.p_their()] areas.")
		if(shuttle.master_blueprint.resolve() == src)
			. += span_notice("This is the master blueprint for \the [shuttle]. You can copy it to a blank set of blueprints, or to an engineering cyborg with a shuttle database module installed.")

/obj/item/shuttle_blueprints/interact_with_atom(atom/interacting_with, mob/living/user, list/modifiers)
	. = ..()
	var/obj/docking_port/mobile/custom/shuttle = shuttle_ref?.resolve()
	if(!istype(shuttle))
		return
	if(shuttle.master_blueprint?.resolve() != src)
		return
	if(istype(interacting_with, /obj/item/shuttle_blueprints))
		var/obj/item/shuttle_blueprints/other_blueprints = interacting_with
		var/obj/docking_port/mobile/other_shuttle = other_blueprints.shuttle_ref?.resolve()
		if(istype(other_shuttle))
			return
		balloon_alert(user, "copying blueprints...")
		if(!do_after(user, 5 SECONDS, other_blueprints))
			balloon_alert(user, "interrupted!")
			return ITEM_INTERACT_FAILURE
		other_blueprints.link_to_shuttle(shuttle)
		balloon_alert(user, "copied")
		return ITEM_INTERACT_SUCCESS
	if(istype(interacting_with, /mob/living/silicon/robot))
		var/mob/living/silicon/robot/borg = interacting_with
		var/obj/item/shuttle_blueprints/borg/other_blueprints = (locate() in borg.model.modules) || (locate() in borg.held_items)
		if(!other_blueprints)
			return
		if(other_blueprints.shuttles.Find(shuttle_ref))
			balloon_alert(user, "already has these blueprints!")
		balloon_alert(user, "copying blueprints...")
		if(!do_after(user, 5 SECONDS, borg))
			balloon_alert(user, "interrupted")
			return ITEM_INTERACT_FAILURE
		if(QDELETED(other_blueprints))
			return ITEM_INTERACT_FAILURE
		other_blueprints.shuttles |= shuttle_ref
		balloon_alert(user, "copied")
		return ITEM_INTERACT_SUCCESS

/obj/item/shuttle_blueprints/ui_act(action, list/params, datum/tgui/ui, datum/ui_state/state)
	. = ..()
	if(.)
		return
	switch(action)
		if("toggleVisualization")
			if(visualize_frame_turfs)
				stop_visualizing(usr)
			else
				start_visualizing(usr)
			return TRUE
		if("tryBuildShuttle")
			var/shuttle_dir = params["dir"]
			if(!(shuttle_dir in GLOB.cardinals))
				return TRUE
			var/list/shuttle_turfs = list()
			var/list/shuttle_areas = list()
			var/turf/shuttle_origin = get_turf(usr)
			var/check_status = shuttle_build_check(shuttle_origin, shuttle_turfs, shuttle_areas)
			if(check_status & ORIGIN_NOT_ON_SHUTTLE)
				balloon_alert(usr, "not on shuttle frame!")
				return TRUE
			if(check_status & TOO_MANY_SHUTTLES)
				balloon_alert(usr, "too many shuttles exist!")
				return TRUE
			if(check_status & ABOVE_MAX_SHUTTLE_SIZE)
				balloon_alert(usr, "frame too big!")
				return TRUE
			if(check_status & CUSTOM_AREA_NOT_COMPLETELY_CONTAINED)
				balloon_alert(usr, "frame must completely enclose custom areas!")
				return TRUE
			if(check_status & INTERSECTS_NON_WHITELISTED_AREA)
				balloon_alert(usr, "frame overlaps disallowed areas!")
				return TRUE
			var/obj/docking_port/mobile/custom/shuttle = create_shuttle(
				usr,
				shuttle_origin,
				shuttle_turfs,
				shuttle_areas,
				shuttle_dir,
				name = "\improper Unnamed Shuttle",
				id = "custom_[length(SSshuttle.custom_shuttles)+1]"
			)
			link_to_shuttle(shuttle, TRUE)
			return TRUE
		if("tryLinkShuttle")
			if(shuttle_ref?.resolve())
				balloon_alert(usr, "already linked!")
				return TRUE
			var/obj/docking_port/mobile/custom/shuttle = SSshuttle.get_containing_shuttle(usr)
			if(!shuttle)
				balloon_alert(usr, "not on shuttle!")
				return TRUE
			if(!istype(shuttle))
				balloon_alert(usr, "incompatible shuttle type!")
				return TRUE
			var/obj/item/shuttle_blueprints/master = shuttle.master_blueprint?.resolve()
			if(master && (master != src))
				balloon_alert(usr, "master blueprint already exists!")
				return TRUE
			link_to_shuttle(shuttle, TRUE)
			return TRUE
		if("promoteToMaster")
			var/obj/docking_port/mobile/custom/shuttle = shuttle_ref?.resolve()
			if(!shuttle)
				balloon_alert(usr, "not linked!")
				return TRUE
			var/obj/item/shuttle_blueprints/master = shuttle.master_blueprint?.resolve()
			if(master)
				balloon_alert(usr, "master blueprint already exists!")
				return TRUE
			shuttle.master_blueprint = WEAKREF(src)
			return TRUE
		if("createNewArea")
			var/obj/docking_port/mobile/custom/shuttle = shuttle_ref?.resolve()
			if(!shuttle)
				balloon_alert(usr, "not linked!")
				return TRUE
			var/area_name = params["name"]
			if(!area_name)
				balloon_alert(usr, "no name given!")
				return TRUE
			var/area/current_area = get_area(usr)
			var/area/default_area = shuttle.default_area
			if(current_area != default_area)
				balloon_alert(usr, "must be in default area!")
				return TRUE
			var/list/turfs = detect_room(get_turf(usr), max_size = CONFIG_GET(number/max_shuttle_size), extra_check = CALLBACK(GLOBAL_PROC, GLOBAL_PROC_REF(custom_shuttle_room_check), shuttle, null))
			if(!length(turfs))
				balloon_alert(usr, "invalid room!")
				return TRUE
			var/area/shuttle/custom/new_area = new()
			new_area.name = area_name
			shuttle.shuttle_areas[new_area] = TRUE
			set_turfs_to_area(turfs, new_area)
			new_area.reg_in_areas_in_z()
			new_area.create_area_lighting_objects()
			for(var/obj/machinery/door/firedoor/firelock as anything in default_area.firedoors)
				firelock.CalculateAffectingAreas()
			new_area.power_change()
			return TRUE
		if("releaseArea")
			var/obj/docking_port/mobile/custom/shuttle = shuttle_ref?.resolve()
			if(!shuttle)
				balloon_alert(usr, "not linked!")
				return TRUE
			var/area/current_area = get_area(usr)
			if(!shuttle.shuttle_areas[current_area])
				balloon_alert(usr, "not on shuttle!")
				return TRUE
			var/area/default_area = shuttle.default_area
			if(current_area == default_area)
				balloon_alert(usr, "can't release default area!")
				return TRUE
			var/obj/machinery/power/apc/current_area_apc = current_area.apc
			var/obj/machinery/power/apc/default_area_apc = default_area.apc
			if(current_area_apc && default_area_apc)
				balloon_alert(usr, "remove the apc first!")
				return TRUE
			var/list/turfs = current_area.get_turfs_by_zlevel(shuttle.z)
			set_turfs_to_area(turfs, default_area)
			for(var/obj/machinery/door/firedoor/firelock as anything in default_area.firedoors)
				firelock.CalculateAffectingAreas()
			shuttle.shuttle_areas -= current_area
			qdel(current_area)
			return TRUE
		if("mergeIntoArea")
			var/obj/docking_port/mobile/custom/shuttle = shuttle_ref?.resolve()
			if(!shuttle)
				balloon_alert(usr, "not linked!")
				return TRUE
			var/area/current_area = get_area(usr)
			var/area/default_area = shuttle.default_area
			if(current_area != default_area)
				balloon_alert(usr, "must be in default area!")
				return TRUE
			var/area/merge_area = locate(params["area"])
			if(!istype(merge_area))
				return TRUE
			if(!shuttle.shuttle_areas[merge_area])
				return TRUE
			if(merge_area == default_area)
				return TRUE
			var/list/actual_adjacent_areas = list()
			var/list/turfs = detect_room(get_turf(usr), max_size = CONFIG_GET(number/max_shuttle_size), extra_check = CALLBACK(GLOBAL_PROC, GLOBAL_PROC_REF(custom_shuttle_room_check), shuttle, actual_adjacent_areas))
			if(!length(turfs))
				balloon_alert(usr, "invalid room!")
				return TRUE
			if(!actual_adjacent_areas[merge_area])
				balloon_alert(usr, "selected area not connected to room!")
				return TRUE
			if(merge_area.apc && default_area.apc && turfs[get_turf(default_area.apc)])
				balloon_alert(usr, "remove the apc first!")
				return TRUE
			set_turfs_to_area(turfs, merge_area)
			for(var/obj/machinery/door/firedoor/firelock as anything in merge_area.firedoors + default_area.firedoors)
				firelock.CalculateAffectingAreas()
			return TRUE
		if("renameArea")
			var/obj/docking_port/mobile/custom/shuttle = shuttle_ref?.resolve()
			if(!shuttle)
				balloon_alert(usr, "not linked!")
				return TRUE
			var/area/current_area = get_area(usr)
			if(!shuttle.shuttle_areas[current_area])
				balloon_alert(usr, "not on shuttle!")
				return TRUE
			var/area/default_area = shuttle.default_area
			if(current_area == default_area)
				balloon_alert(usr, "can't rename default area!")
				return TRUE
			var/new_name = params["name"]
			if(!new_name)
				balloon_alert(usr, "no name given!")
				return TRUE
			rename_area(current_area, new_name)
			return TRUE
		if("expandWithFrame")
			var/obj/docking_port/mobile/custom/shuttle = shuttle_ref?.resolve()
			if(!shuttle)
				balloon_alert(usr, "not linked!")
				return TRUE
			var/list/turfs = list()
			var/list/areas = list()
			var/turf/origin = get_turf(usr)
			var/check_status = shuttle_expand_check(origin, shuttle, turfs, areas)
			if(check_status & ORIGIN_NOT_ON_SHUTTLE)
				balloon_alert(usr, "not on shuttle frame!")
				return TRUE
			if(check_status & FRAME_NOT_ADJACENT_TO_LINKED_SHUTTLE)
				balloon_alert(usr, "not connected to linked shuttle!")
				return TRUE
			if(check_status & ABOVE_MAX_SHUTTLE_SIZE)
				balloon_alert(usr, "frame too big!")
				return TRUE
			if(check_status & CUSTOM_AREA_NOT_COMPLETELY_CONTAINED)
				balloon_alert(usr, "frame must completely enclose custom areas!")
				return TRUE
			if(check_status & INTERSECTS_NON_WHITELISTED_AREA)
				balloon_alert(usr, "frame overlaps disallowed areas!")
				return TRUE
			expand_shuttle(usr, shuttle, turfs, areas)
			return TRUE
		if("cleanupEmptyTurfs")
			var/obj/docking_port/mobile/custom/shuttle = shuttle_ref?.resolve()
			if(!shuttle)
				balloon_alert(usr, "not linked!")
				return TRUE
			var/obj/item/shuttle_blueprints/master = shuttle.master_blueprint?.resolve()
			if(master && master != src)
				balloon_alert(usr, "not master blueprints!")
			var/shuttle_z = shuttle.z
			var/bounds_need_recalculation
			var/docking_port_needs_relocated
			var/list/bounds = shuttle.return_coords()
			var/x0 = bounds[1]
			var/y0 = bounds[2]
			var/x1 = bounds[3]
			var/y1 = bounds[4]
			for(var/area/area as anything in shuttle.shuttle_areas)
				var/list/turfs = area.get_turfs_by_zlevel(shuttle_z)
				turfs = turfs.Copy()
				for(var/turf/turf as anything in turfs)
					var/move_mode = turf.fromShuttleMove(move_mode = MOVE_AREA)
					if(move_mode & (MOVE_TURF | MOVE_CONTENTS))
						continue
					for(var/atom/movable/movable as anything in turf.contents)
						//CHECK_TICK
						if(movable.loc != turf)
							continue
						if(movable == shuttle)
							continue
						move_mode = movable.hypotheticalShuttleMove(0, move_mode, shuttle)
					if(move_mode & (MOVE_TURF | MOVE_CONTENTS))
						continue
					if(shuttle.loc == turf)
						docking_port_needs_relocated = TRUE
						bounds_need_recalculation = TRUE
					var/area/new_area = shuttle.underlying_areas_by_turf[turf]
					if(!istype(new_area))
						new_area = GLOB.areas_by_type[SHUTTLE_DEFAULT_UNDERLYING_AREA]
					if(!istype(new_area))
						new_area = new SHUTTLE_DEFAULT_UNDERLYING_AREA(null)
					shuttle.underlying_areas_by_turf -= turf
					shuttle.turf_count--
					turfs -= turf
					turf.change_area(area, new_area)
					if(bounds_need_recalculation)
						continue
					if(turf.x == x0 || turf.x == x1 || turf.y == y0 || turf.y == y1)
						bounds_need_recalculation = TRUE
				if((area != shuttle.default_area) && !length(turfs))
					shuttle.shuttle_areas -= area
					qdel(area)
			if(!shuttle.turf_count)
				qdel(shuttle.default_area)
				qdel(shuttle)
				return
			if(docking_port_needs_relocated)
				shuttle.forceMove(pick(shuttle.underlying_areas_by_turf))
			if(bounds_need_recalculation)
				QDEL_NULL(shuttle.assigned_transit)
				shuttle.calculate_docking_port_information()

/obj/item/shuttle_blueprints/crude
	name = "crude shuttle blueprints"
	desc = "This is just a sheet of paper thoroughly covered in what could either be crayon or spraypaint."
	icon_state = "shuttle_blueprints_crude0"
	base_icon_state = "shuttle_blueprints_crude"
	base_desc = "This is just a sheet of paper thoroughly covered in what could either be crayon or spraypaint."
	linked_desc = "This is just a crude doodle of a shuttle drawn on a background of what could either be crayon or spraypaint."

/obj/item/shuttle_blueprints/borg
	name = "shuttle blueprint database"
	desc = "A module designed to store the plans for one or more shuttles."
	icon = 'icons/obj/items_cyborg.dmi'
	icon_state = "shuttle_database0"
	base_icon_state = "shuttle_database"
	damtype = BURN // In case fantasy affixes or adminbus end up making this actually capable of hurting someone.
	attack_verb_continuous = list("attacks", "scans", "analyzes")
	attack_verb_simple = list("attack", "scan", "analyze")
	base_desc = "A module designed to store the plans for one or more shuttles."
	linked_desc = "A module designed to store the plans for one or more shuttles."
	var/list/shuttles = list()

/obj/item/shuttle_blueprints/borg/get_shuttle_tip()
	. = list()
	if(!shuttle_ref)
		if(!length(shuttles))
			. += span_notice("It does not have any shuttle plans stored.")
		else
			. += span_notice("It does not currently have a shuttle plan loaded.")
		. += span_notice("In this mode, it can be used to construct a custom shuttle.")
		return
	var/obj/docking_port/mobile/custom/shuttle = shuttle_ref.resolve()
	if(!shuttle)
		. += span_notice("The currently loaded plans are for a shuttle that no longer exists. It will default to shuttle construction mode.")
	else
		. += span_notice("It has the plans for \the [shuttle] currently loaded, and can be used to expand [shuttle.p_them()] or modify [shuttle.p_their()] areas.")
		if(shuttle.master_blueprint.resolve() == src)
			. += span_notice("This is the master blueprint for \the [shuttle]. You can copy it to a blank set of blueprints, or to another engineering cyborg with a shuttle database module installed.")

/obj/item/shuttle_blueprints/borg/unlink(removing)
	if(removing)
		shuttles -= shuttle_ref
	..()

/obj/item/shuttle_blueprints/borg/ui_data(mob/user)
	var/list/data = ..()
	var/list/shuttle_data = list()
	var/list/shuttle_name_count = list()
	for(var/datum/weakref/shuttle_weakref as anything in shuttles)
		var/obj/docking_port/mobile/shuttle = shuttle_weakref.resolve()
		if(!shuttle)
			continue
		var/shuttle_name = shuttle.name
		if(!shuttle_name_count[shuttle_name])
			shuttle_name_count[shuttle_name] = 0
		var/ref = shuttle_weakref.reference
		shuttle_data[ref] = shuttle_name
		if(shuttle_name_count[shuttle_name]++ > 1)
			shuttle_data[ref] += " ([shuttle_name_count[shuttle_name]])"
	if(length(shuttle_data))
		data["shuttles"] = shuttle_data
	return data

/obj/item/shuttle_blueprints/borg/ui_act(action, list/params, datum/tgui/ui, datum/ui_state/state)
	. = ..()
	if(.)
		return
	switch(action)
		if("switchShuttle")
			var/ref = params["ref"]
			var/obj/docking_port/mobile/shuttle = locate(ref)
			if(!shuttle)
				return TRUE
			if(shuttles.Find(WEAKREF(shuttle)))
				link_to_shuttle(shuttle)
			return TRUE
		if("unsetShuttle")
			unlink()
			return TRUE

/obj/item/shuttle_blueprints/borg/link_to_shuttle(obj/docking_port/mobile/custom/shuttle, is_master)
	. = ..()
	shuttles |= WEAKREF(shuttle)

/obj/item/shuttle_blueprints/borg/get_linked_name(obj/docking_port/mobile/shuttle)
	name = "shuttle blueprint database ([shuttle.name])"

/proc/custom_shuttle_room_check(obj/docking_port/mobile/custom/shuttle, list/neighboring_areas = list(), turf/check_turf)
	if(SSshuttle.get_containing_shuttle(check_turf) != shuttle)
		return EXTRA_ROOM_CHECK_SKIP
	var/area/check_area = check_turf.loc
	if(check_area != shuttle.default_area)
		neighboring_areas[check_area] = TRUE
		return EXTRA_ROOM_CHECK_SKIP
	var/move_mode = MOVE_AREA
	move_mode = check_turf.fromShuttleMove(move_mode = move_mode)
	if(move_mode & (MOVE_CONTENTS | MOVE_TURF))
		return
	for(var/atom/movable/movable as anything in check_turf.contents)
		CHECK_TICK
		if(movable.loc != check_turf)
			continue
		move_mode = movable.hypotheticalShuttleMove(0, move_mode, shuttle)
	if(!(move_mode & (MOVE_CONTENTS | MOVE_TURF)))
		return EXTRA_ROOM_CHECK_SKIP

/proc/get_connected_shuttle_frame_turfs(turf/starting_turf, max_size = INFINITY, list/adjacent_shuttles)
	. = list()
	var/list/check_turfs = list(starting_turf)
	while(length(check_turfs))
		var/turf/check_turf = check_turfs[1]
		check_turfs.Cut(1,2)
		.[check_turf] = TRUE
		if(length(.) > max_size)
			return
		for(var/check_dir in GLOB.cardinals)
			var/turf/neighbor = get_step(check_turf, check_dir)
			if(neighbor)
				if(HAS_TRAIT(neighbor, TRAIT_SHUTTLE_CONSTRUCTION_TURF) && !.[neighbor])
					check_turfs[neighbor] = TRUE
				else if(islist(adjacent_shuttles))
					var/obj/docking_port/mobile/custom/shuttle = SSshuttle.get_containing_shuttle(neighbor)
					if(istype(shuttle))
						adjacent_shuttles |= shuttle

/proc/shuttle_build_check(turf/origin, list/turfs, list/areas)
	var/z = origin.z
	var/skip_flood_fill = !!length(turfs)
	if(skip_flood_fill && !(turfs[origin]))
		. |= ORIGIN_NOT_ON_SHUTTLE
	if(length(SSshuttle.custom_shuttles) >= CONFIG_GET(number/max_shuttle_count))
		. |= TOO_MANY_SHUTTLES
	var/max_turfs = CONFIG_GET(number/max_shuttle_size)
	if(!skip_flood_fill)
		turfs += get_connected_shuttle_frame_turfs(origin, max_turfs)
	var/turf_count = length(turfs)
	if(!skip_flood_fill && !(turfs[origin]))
		. |= ORIGIN_NOT_ON_SHUTTLE
	if(turf_count > max_turfs)
		. |= ABOVE_MAX_SHUTTLE_SIZE
	. |= shuttle_area_check(turfs.Copy(), areas, z)

/proc/shuttle_expand_check(turf/origin, obj/docking_port/mobile/shuttle, list/turfs, list/areas)
	var/z = origin.z
	var/skip_flood_fill = !!length(turfs)
	if(skip_flood_fill && !(turfs[origin]))
		. |= ORIGIN_NOT_ON_SHUTTLE
	var/max_turfs = CONFIG_GET(number/max_shuttle_size) - shuttle.turf_count
	var/list/adjacent_shuttles = list()
	if(!skip_flood_fill)
		turfs += get_connected_shuttle_frame_turfs(origin, max_turfs, adjacent_shuttles)
	var/turf_count = length(turfs)
	if(!skip_flood_fill && !(turfs[origin]))
		. |= ORIGIN_NOT_ON_SHUTTLE
	if(turf_count > max_turfs)
		. |= ABOVE_MAX_SHUTTLE_SIZE
	if(!adjacent_shuttles.Find(shuttle))
		. |= FRAME_NOT_ADJACENT_TO_LINKED_SHUTTLE
	. |= shuttle_area_check(turfs.Copy(), areas, z)

/*
 * Check to see if the following conditions are met:
 * 1. Any custom areas that overlap with the the region defined by `turf` are contained entirely within that region
 * 2. All other turfs in the region are within whitelisted areas
 */
/proc/shuttle_area_check(list/turfs, list/areas, z)
	for(var/area/custom_area as anything in GLOB.custom_areas)
		var/list/area_turfs = custom_area.get_turfs_by_zlevel(z)
		var/turf_count = length(area_turfs)
		if(!turf_count)
			continue
		var/list/turfs_not_in_frame = area_turfs - turfs
		var/turfs_not_in_frame_count = length(turfs_not_in_frame)
		if(turfs_not_in_frame_count == turf_count)
			continue
		areas[custom_area] = area_turfs - turfs_not_in_frame
		if(turfs_not_in_frame_count)
			. |= CUSTOM_AREA_NOT_COMPLETELY_CONTAINED
		turfs -= area_turfs
	while(length(turfs))
		var/turf/checked_turf = pick(turfs)
		var/area/checked_area = checked_turf.loc
		var/list/area_turfs = checked_area.get_turfs_by_zlevel(z)
		if(!is_type_in_list(checked_area, GLOB.shuttle_construction_area_whitelist))
			. |= INTERSECTS_NON_WHITELISTED_AREA
		turfs -= area_turfs

/proc/convert_areas_to_shuttle_areas(list/turfs, list/in_areas, list/out_areas, list/underlying_areas, area_type = /area/shuttle/custom)
	for(var/area/area as anything in in_areas)
		var/area/new_area = new area_type()
		new_area.setup(area.name)
		out_areas += new_area
		var/list/area_turfs = in_areas[area]
		var/datum/component/custom_area/custom_area = area.GetComponent(/datum/component/custom_area)
		if(custom_area)
			underlying_areas += (custom_area.previous_areas & area_turfs)
		set_turfs_to_area(area_turfs, new_area)
		turfs -= area_turfs
		new_area.reg_in_areas_in_z()
		new_area.create_area_lighting_objects()
		new_area.power_change()
		for(var/obj/machinery/door/firedoor/firelock as anything in area.firedoors)
			firelock.CalculateAffectingAreas()
		if(!area.has_contained_turfs())
			qdel(area)

/proc/create_shuttle(mob/user, turf/origin, list/turfs, list/areas, shuttle_dir, port_dir = NORTH, area_type = /area/shuttle/custom, docking_port_type = /obj/docking_port/mobile/custom, obj/docking_port/stationary/dock_at, name, id, replace, custom = TRUE, force)
	if(!ispath(docking_port_type, /obj/docking_port/mobile))
		CRASH("docking_port_type must be /obj/docking_port/mobile or a subpath")
	if(!ispath(area_type, /area/shuttle))
		CRASH("area_type must be /area/shuttle or a subpath")
	var/list/default_area_turfs = turfs.Copy()
	// Convert each custom area into a shuttle area, then remove the affected turfs from the list of turfs to add to the default area
	var/list/shuttle_areas = list()
	var/list/underlying_areas = list()
	convert_areas_to_shuttle_areas(default_area_turfs, areas, shuttle_areas, underlying_areas, area_type)
	for(var/turf/turf as anything in default_area_turfs)
		underlying_areas[turf] = turf.loc

	// Merge the remaining frame turfs into a default shuttle area
	var/list/affected_areas = list()
	var/area/default_area = new area_type()
	default_area.setup(name)
	set_turfs_to_area(default_area_turfs, default_area, affected_areas)
	default_area.reg_in_areas_in_z()
	default_area.create_area_lighting_objects()
	default_area.power_change()
	for(var/area_name in affected_areas)
		var/area/merged_area = affected_areas[area_name]
		for(var/obj/machinery/door/firedoor/firelock as anything in merged_area.firedoors)
			firelock.CalculateAffectingAreas()
		if(!merged_area.has_contained_turfs())
			qdel(merged_area)
	shuttle_areas.Insert(1, default_area)

	var/obj/docking_port/mobile/mobile_port = new docking_port_type(origin, shuttle_areas)
	mobile_port.underlying_areas_by_turf += underlying_areas
	mobile_port.name = name
	mobile_port.shuttle_id = id
	mobile_port.port_direction = REVERSE_DIR(shuttle_dir)
	mobile_port.dir = port_dir
	mobile_port.calculate_docking_port_information()
	mobile_port.turf_count = length(turfs)

	for(var/turf/turf as anything in turfs)
		turf.stack_below_baseturf(/turf/open/floor/plating, /turf/baseturf_skipover/shuttle)
		SEND_SIGNAL(turf, COMSIG_TURF_ADDED_TO_SHUTTLE, mobile_port)
		if(!turf.depth_to_find_baseturf(/turf/baseturf_skipover/shuttle))
			continue
		var/turf/new_ceiling = get_step_multiz(turf, UP) // check if a ceiling is needed
		if(new_ceiling)
			// generate ceiling
			if(!(istype(new_ceiling, /turf/open/floor/engine/hull/ceiling) || new_ceiling.depth_to_find_baseturf(/turf/open/floor/engine/hull/ceiling)))
				if(istype(new_ceiling, /turf/open/openspace) || istype(new_ceiling, /turf/open/space/openspace))
					new_ceiling.place_on_top(/turf/open/floor/engine/hull/ceiling)
				else
					new_ceiling.stack_ontop_of_baseturf(/turf/open/openspace, /turf/open/floor/engine/hull/ceiling)
					new_ceiling.stack_ontop_of_baseturf(/turf/open/space/openspace, /turf/open/floor/engine/hull/ceiling)

	if(!istype(dock_at))
		dock_at = new(origin)
		var/area/origin_area = get_area(origin)
		dock_at.name = origin_area.name
		dock_at.dir = port_dir

	mobile_port.register(replace, custom)

	message_admins("[key_name(user)] has created a shuttle at [ADMIN_VERBOSEJMP(origin)].")
	log_shuttle("[key_name(user)] has created a shuttle at [get_area(origin)].")

	return mobile_port

/proc/expand_shuttle(mob/user, obj/docking_port/mobile/shuttle, list/turfs, list/areas)
	var/list/default_area_turfs = turfs.Copy()
	// Convert each custom area into a shuttle area, then remove the affected turfs from the list of turfs to add to the default area
	var/list/shuttle_areas = list()
	var/list/underlying_areas = list()
	convert_areas_to_shuttle_areas(default_area_turfs, areas, shuttle_areas, underlying_areas, shuttle.area_type)
	for(var/turf/turf as anything in default_area_turfs)
		underlying_areas[turf] = turf.loc

	var/list/affected_areas = list()
	var/area/default_area = shuttle.shuttle_areas[1]
	set_turfs_to_area(default_area_turfs, default_area, affected_areas)
	default_area.power_change()

	for(var/area_name in affected_areas)
		var/area/merged_area = affected_areas[area_name]
		for(var/obj/machinery/door/firedoor/firelock as anything in merged_area.firedoors)
			firelock.CalculateAffectingAreas()
		if(!merged_area.has_contained_turfs())
			qdel(merged_area)

	for(var/area/shuttle_area as anything in shuttle_areas)
		shuttle.shuttle_areas[shuttle_area] = TRUE

	var/list/bounds = shuttle.return_coords()
	var/x0 = bounds[1]
	var/y0 = bounds[2]
	var/x1 = bounds[3]
	var/y1 = bounds[4]
	var/bounds_need_recalculation
	for(var/turf/turf as anything in turfs)
		turf.stack_below_baseturf(/turf/open/floor/plating, /turf/baseturf_skipover/shuttle)
		SEND_SIGNAL(turf, COMSIG_TURF_ADDED_TO_SHUTTLE, shuttle)
		if(turf.depth_to_find_baseturf(/turf/baseturf_skipover/shuttle))
			var/turf/new_ceiling = get_step_multiz(turf, UP) // check if a ceiling is needed
			if(new_ceiling)
				// generate ceiling
				if(!(istype(new_ceiling, /turf/open/floor/engine/hull/ceiling) || new_ceiling.depth_to_find_baseturf(/turf/open/floor/engine/hull/ceiling)))
					if(istype(new_ceiling, /turf/open/openspace) || istype(new_ceiling, /turf/open/space/openspace))
						new_ceiling.place_on_top(/turf/open/floor/engine/hull/ceiling)
					else
						new_ceiling.stack_ontop_of_baseturf(/turf/open/openspace, /turf/open/floor/engine/hull/ceiling)
						new_ceiling.stack_ontop_of_baseturf(/turf/open/space/openspace, /turf/open/floor/engine/hull/ceiling)
		if(bounds_need_recalculation)
			continue
		if(!(ISINRANGE(turf.x, x0, x1) && ISINRANGE(turf.y, y0, y1)))
			bounds_need_recalculation = TRUE

	shuttle.turf_count += length(turfs)
	shuttle.underlying_areas_by_turf += underlying_areas
	SEND_SIGNAL(shuttle, COMSIG_SHUTTLE_EXPANDED, turfs)
	if(bounds_need_recalculation)
		QDEL_NULL(shuttle.assigned_transit)
		shuttle.calculate_docking_port_information()
	shuttle.initiate_docking(shuttle.get_docked(), force = TRUE)

	message_admins("[key_name(user)] has expanded [shuttle] at [ADMIN_VERBOSEJMP(user)].")
	log_shuttle("[key_name(user)] expanded [shuttle] at [get_area(user)].")
