#define ENGINE_UNWRENCHED 0
#define ENGINE_WRENCHED 1
#define ENGINE_WELDED 2
///How long it takes to weld/unweld an engine in place.
#define ENGINE_WELDTIME (20 SECONDS)

/obj/machinery/power/shuttle_engine
	name = "engine"
	desc = "A bluespace engine used to make shuttles move."
	icon = 'icons/turf/shuttle.dmi'
	resistance_flags = LAVA_PROOF | FIRE_PROOF | ACID_PROOF
	smoothing_groups = SMOOTH_GROUP_SHUTTLE_PARTS
	armor_type = /datum/armor/power_shuttle_engine
	can_atmos_pass = ATMOS_PASS_DENSITY
	max_integrity = 500
	density = TRUE
	anchored = TRUE
	use_power = NO_POWER_USE
	circuit = /obj/item/circuitboard/machine/engine

	///How well the engine affects the ship's speed.
	var/engine_power = 1
	///Construction state of the Engine.
	var/engine_state = ENGINE_WELDED //welding shmelding //i love welding

	///The mobile ship we are connected to.
	var/datum/weakref/connected_ship_ref

	var/static/list/connections = list(COMSIG_TURF_ADDED_TO_SHUTTLE = PROC_REF(on_turf_added_to_shuttle))

/datum/armor/power_shuttle_engine
	melee = 100
	bullet = 10
	laser = 10
	fire = 50
	acid = 70

/obj/machinery/power/shuttle_engine/Initialize(mapload)
	. = ..()
	AddComponent(/datum/component/simple_rotation)
	register_context()

/obj/machinery/power/shuttle_engine/connect_to_shuttle(mapload, obj/docking_port/mobile/port, obj/docking_port/stationary/dock)
	. = ..()
	if(!port)
		return FALSE
	connected_ship_ref = WEAKREF(port)
	port.engine_list += src
	port.current_engine_power += engine_power
	if(mapload)
		port.initial_engine_power += engine_power

/obj/machinery/power/shuttle_engine/Destroy()
	if(engine_state == ENGINE_WELDED)
		alter_engine_power(-engine_power)
	unsync_ship()
	return ..()

/obj/machinery/power/shuttle_engine/examine(mob/user)
	. = ..()
	switch(engine_state)
		if(ENGINE_UNWRENCHED)
			. += span_notice("\The [src] is unbolted from the floor. It needs to be wrenched to the floor to be installed.")
		if(ENGINE_WRENCHED)
			. += span_notice("\The [src] is bolted to the floor and can be unbolted with a wrench. It needs to be welded to the floor to finish installation.")
		if(ENGINE_WELDED)
			. += span_notice("\The [src] is welded to the floor and can be unwelded. It is currently fully installed.")

/obj/machinery/power/shuttle_engine/add_context(atom/source, list/context, obj/item/held_item, mob/living/user)
	if(held_item?.tool_behaviour == TOOL_WELDER && engine_state == ENGINE_WRENCHED)
		context[SCREENTIP_CONTEXT_LMB] = "Weld to Floor"
	if(held_item?.tool_behaviour == TOOL_WELDER && engine_state == ENGINE_WELDED)
		context[SCREENTIP_CONTEXT_LMB] = "Unweld from Floor"
	if(held_item?.tool_behaviour == TOOL_WRENCH && engine_state == ENGINE_UNWRENCHED)
		context[SCREENTIP_CONTEXT_LMB] = "Wrench to Floor"
	if(held_item?.tool_behaviour == TOOL_WRENCH && engine_state == ENGINE_WRENCHED)
		context[SCREENTIP_CONTEXT_LMB] = "Unwrench from Floor"
	return CONTEXTUAL_SCREENTIP_SET

/**
 * Called on destroy and when we need to unsync an engine from their ship.
 */
/obj/machinery/power/shuttle_engine/proc/unsync_ship()
	var/obj/docking_port/mobile/port = connected_ship_ref?.resolve()
	if(port)
		port.engine_list -= src
		port.current_engine_power -= initial(engine_power)
	connected_ship_ref = null
	RemoveElement(/datum/element/connect_loc, connections)

//Ugh this is a lot of copypasta from emitters, welding need some boilerplate reduction
/obj/machinery/power/shuttle_engine/can_be_unfasten_wrench(mob/user, silent)
	if(engine_state == ENGINE_WELDED)
		if(!silent)
			to_chat(user, span_warning("[src] is welded to the floor!"))
		return FAILED_UNFASTEN
	return ..()

/obj/machinery/power/shuttle_engine/default_unfasten_wrench(mob/user, obj/item/tool, time = 20)
	. = ..()
	if(. == SUCCESSFUL_UNFASTEN)
		if(anchored)
			connect_to_shuttle(port = SSshuttle.get_containing_shuttle(src)) //connect to a new ship, if needed
			if(!connected_ship_ref?.resolve())
				AddElement(/datum/element/connect_loc, connections)
			engine_state = ENGINE_WRENCHED
		else
			unsync_ship() //not part of the ship anymore
			engine_state = ENGINE_UNWRENCHED

/obj/machinery/power/shuttle_engine/proc/on_turf_added_to_shuttle(turf/source, obj/docking_port/mobile/port)
	SIGNAL_HANDLER
	connect_to_shuttle(port = port)

/obj/machinery/power/shuttle_engine/wrench_act(mob/living/user, obj/item/tool)
	. = ..()
	default_unfasten_wrench(user, tool)
	return ITEM_INTERACT_SUCCESS

/obj/machinery/power/shuttle_engine/welder_act(mob/living/user, obj/item/tool)
	. = ..()
	switch(engine_state)
		if(ENGINE_UNWRENCHED)
			to_chat(user, span_warning("\The [src] needs to be wrenched to the floor!"))
		if(ENGINE_WRENCHED)
			if(!tool.tool_start_check(user, amount=round(ENGINE_WELDTIME / 5), heat_required = HIGH_TEMPERATURE_REQUIRED))
				return TRUE

			user.visible_message(span_notice("[user.name] starts to weld \the [src] to the floor."), \
				span_notice("You start to weld \the [src] to the floor..."), \
				span_hear("You hear welding."))

			if(tool.use_tool(src, user, ENGINE_WELDTIME, volume=50))
				engine_state = ENGINE_WELDED
				to_chat(user, span_notice("You weld \the [src] to the floor."))
				alter_engine_power(engine_power)

		if(ENGINE_WELDED)
			if(!tool.tool_start_check(user, amount=round(ENGINE_WELDTIME / 5), heat_required = HIGH_TEMPERATURE_REQUIRED))
				return TRUE

			user.visible_message(span_notice("[user.name] starts to cut \the [src] free from the floor."), \
				span_notice("You start to cut \the [src] free from the floor..."), \
				span_hear("You hear welding."))

			if(tool.use_tool(src, user, ENGINE_WELDTIME, volume=50))
				engine_state = ENGINE_WRENCHED
				to_chat(user, span_notice("You cut \the [src] free from the floor."))
				alter_engine_power(-engine_power)
	return TRUE

//Propagates the change to the shuttle.
/obj/machinery/power/shuttle_engine/proc/alter_engine_power(mod)
	if(!mod)
		return
	var/obj/docking_port/mobile/port = connected_ship_ref?.resolve()
	if(port)
		port.alter_engines(mod)

/obj/machinery/power/shuttle_engine/heater
	name = "engine heater"
	desc = "Directs energy into compressed particles in order to power engines."
	icon_state = "heater"
	circuit = /obj/item/circuitboard/machine/engine/heater
	engine_power = 0 // todo make these into 2x1 parts

/obj/machinery/power/shuttle_engine/propulsion
	name = "propulsion engine"
	icon_state = "propulsion"
	desc = "A standard reliable bluespace engine used by many forms of shuttles."
	circuit = /obj/item/circuitboard/machine/engine/propulsion
	opacity = TRUE

/obj/machinery/power/shuttle_engine/propulsion/left
	name = "left propulsion engine"
	icon_state = "propulsion_l"

/obj/machinery/power/shuttle_engine/propulsion/right
	name = "right propulsion engine"
	icon_state = "propulsion_r"

/obj/machinery/power/shuttle_engine/propulsion/burst
	name = "burst engine"
	desc = "An engine that releases a large bluespace burst to propel it."

/obj/machinery/power/shuttle_engine/propulsion/burst/cargo
	engine_state = ENGINE_UNWRENCHED
	anchored = FALSE

/obj/machinery/power/shuttle_engine/propulsion/burst/left
	name = "left burst engine"
	icon_state = "burst_l"

/obj/machinery/power/shuttle_engine/propulsion/burst/right
	name = "right burst engine"
	icon_state = "burst_r"

/obj/machinery/power/shuttle_engine/large
	name = "engine"
	icon = 'icons/obj/fluff/2x2.dmi'
	icon_state = "large_engine"
	desc = "A very large bluespace engine used to propel very large ships."
	circuit = null
	opacity = TRUE
	bound_width = 64
	bound_height = 64
	appearance_flags = LONG_GLIDE

/obj/machinery/power/shuttle_engine/huge
	name = "engine"
	icon = 'icons/obj/fluff/3x3.dmi'
	icon_state = "huge_engine"
	desc = "An extremely large bluespace engine used to propel extremely large ships."
	circuit = null
	opacity = TRUE
	bound_width = 96
	bound_height = 96
	appearance_flags = LONG_GLIDE

#undef ENGINE_UNWRENCHED
#undef ENGINE_WRENCHED
#undef ENGINE_WELDED
#undef ENGINE_WELDTIME
