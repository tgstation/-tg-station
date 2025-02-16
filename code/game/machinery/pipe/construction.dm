/*CONTENTS
Buildable pipes
Buildable meters
*/

//construction defines are in __defines/pipe_construction.dm
//update those defines ANY TIME an atmos path is changed...
//...otherwise construction will stop working

/obj/item/pipe
	name = "pipe"
	desc = "A pipe."
	var/pipe_type
	var/pipename
	force = 7
	throwforce = 7
	icon = 'icons/obj/pipes_n_cables/pipe_item.dmi'
	icon_state = "simple"
	icon_state_preview = "manifold4w"
	inhand_icon_state = "buildpipe"
	w_class = WEIGHT_CLASS_NORMAL
	///Piping layer that we are going to be on
	var/piping_layer = PIPING_LAYER_DEFAULT
	///Type of pipe-object made, selected from the RPD
	var/RPD_type
	///Whether it can be painted
	var/paintable = FALSE
	///Color of the pipe is going to be made from this pipe-object
	var/pipe_color
	///Initial direction of the created pipe (either made from the RPD or after unwrenching the pipe)
	var/p_init_dir = SOUTH

/obj/item/pipe/on_craft_completion(list/components, datum/crafting_recipe/current_recipe, atom/crafter)
	. = ..()
	if(!istype(current_recipe, /datum/crafting_recipe/spec_pipe))
		return
	var/datum/crafting_recipe/spec_pipe/pipe_recipe = current_recipe
	pipe_type = pipe_recipe.pipe_type
	pipe_color = COLOR_VERY_LIGHT_GRAY
	setDir(crafter.dir)
	update()

/obj/item/pipe/directional
	RPD_type = PIPE_UNARY
/obj/item/pipe/directional/he_junction
	icon_state_preview = "junction"
	pipe_type = /obj/machinery/atmospherics/pipe/heat_exchanging/junction
/obj/item/pipe/directional/vent
	name = "air vent fitting"
	icon_state_preview = "uvent"
	pipe_type = /obj/machinery/atmospherics/components/unary/vent_pump
/obj/item/pipe/directional/scrubber
	name = "air scrubber fitting"
	icon_state_preview = "scrubber"
	pipe_type = /obj/machinery/atmospherics/components/unary/vent_scrubber
/obj/item/pipe/directional/connector
	icon_state_preview = "connector"
	pipe_type = /obj/machinery/atmospherics/components/unary/portables_connector
/obj/item/pipe/directional/passive_vent
	icon_state_preview = "pvent"
	pipe_type = /obj/machinery/atmospherics/components/unary/passive_vent
/obj/item/pipe/directional/injector
	icon_state_preview = "injector"
	pipe_type = /obj/machinery/atmospherics/components/unary/outlet_injector
/obj/item/pipe/directional/he_exchanger
	icon_state_preview = "heunary"
	pipe_type = /obj/machinery/atmospherics/components/unary/heat_exchanger
/obj/item/pipe/directional/airlock_pump
	icon_state_preview = "airlock_pump"
	pipe_type = /obj/machinery/atmospherics/components/unary/airlock_pump
/obj/item/pipe/binary
	RPD_type = PIPE_STRAIGHT
/obj/item/pipe/binary/layer_adapter
	icon_state_preview = "manifoldlayer"
	pipe_type = /obj/machinery/atmospherics/pipe/layer_manifold
/obj/item/pipe/binary/color_adapter
	icon_state_preview = "adapter_center"
	pipe_type = /obj/machinery/atmospherics/pipe/color_adapter
/obj/item/pipe/binary/pressure_pump
	icon_state_preview = "pump"
	pipe_type = /obj/machinery/atmospherics/components/binary/pump
/obj/item/pipe/binary/manual_valve
	icon_state_preview = "mvalve"
	pipe_type = /obj/machinery/atmospherics/components/binary/valve
/obj/item/pipe/binary/bendable
	RPD_type = PIPE_BENDABLE
/obj/item/pipe/trinary
	RPD_type = PIPE_TRINARY
/obj/item/pipe/trinary/flippable
	RPD_type = PIPE_TRIN_M
	var/flipped = FALSE
/obj/item/pipe/trinary/flippable/filter
	name = "gas filter fitting"
	icon_state_preview = "filter"
	pipe_type = /obj/machinery/atmospherics/components/trinary/filter
/obj/item/pipe/trinary/flippable/mixer
	icon_state_preview = "mixer"
	pipe_type = /obj/machinery/atmospherics/components/trinary/mixer
/obj/item/pipe/quaternary
	RPD_type = PIPE_ONEDIR
/obj/item/pipe/quaternary/pipe
	icon_state_preview = "manifold4w"
	pipe_type = /obj/machinery/atmospherics/pipe/smart
/obj/item/pipe/quaternary/pipe/crafted

/obj/item/pipe/quaternary/pipe/crafted/Initialize(mapload, _pipe_type, _dir, obj/machinery/atmospherics/make_from, device_color, device_init_dir = SOUTH)
	. = ..()
	pipe_type = /obj/machinery/atmospherics/pipe/smart
	pipe_color = COLOR_VERY_LIGHT_GRAY
	p_init_dir = ALL_CARDINALS
	setDir(SOUTH)
	update()

/obj/item/pipe/quaternary/he_pipe
	icon_state_preview = "he_manifold4w"
	pipe_type = /obj/machinery/atmospherics/pipe/heat_exchanging/manifold4w

/obj/item/pipe/Initialize(mapload, _pipe_type, _dir, obj/machinery/atmospherics/make_from, device_color, device_init_dir = SOUTH)
	if(make_from)
		make_from_existing(make_from)
	else
		p_init_dir = device_init_dir
		pipe_type = _pipe_type
		pipe_color = device_color
		setDir(_dir)

	update()
	pixel_x += rand(-5, 5)
	pixel_y += rand(-5, 5)

	//Flipping handled manually due to custom handling for trinary pipes
	AddComponent(/datum/component/simple_rotation, ROTATION_NO_FLIPPING)

	// Only 'normal' pipes
	if(type != /obj/item/pipe/quaternary)
		return ..()
	var/static/list/slapcraft_recipe_list = list(/datum/crafting_recipe/ghettojetpack, /datum/crafting_recipe/pipegun, /datum/crafting_recipe/smoothbore_disabler, /datum/crafting_recipe/improvised_pneumatic_cannon)

	AddElement(
		/datum/element/slapcrafting,\
		slapcraft_recipes = slapcraft_recipe_list,\
	)

	return ..()

/obj/item/pipe/proc/make_from_existing(obj/machinery/atmospherics/make_from)
	p_init_dir = make_from.get_init_directions()
	setDir(make_from.dir)
	pipename = make_from.name
	add_atom_colour(make_from.color, FIXED_COLOUR_PRIORITY)
	pipe_type = make_from.type
	paintable = make_from.paintable
	pipe_color = make_from.pipe_color

/obj/item/pipe/trinary/flippable/make_from_existing(obj/machinery/atmospherics/components/trinary/make_from)
	..()
	if(make_from.flipped)
		do_a_flip()

/obj/item/pipe/dropped()
	if(loc)
		set_piping_layer(piping_layer)
	return ..()

/obj/item/pipe/proc/set_piping_layer(new_layer = PIPING_LAYER_DEFAULT)
	var/obj/machinery/atmospherics/fakeA = pipe_type

	if(initial(fakeA.pipe_flags) & PIPING_ALL_LAYER)
		new_layer = PIPING_LAYER_DEFAULT
	piping_layer = new_layer

	PIPING_LAYER_SHIFT(src, piping_layer)
	layer = initial(layer) + ((piping_layer - PIPING_LAYER_DEFAULT) * PIPING_LAYER_LCHANGE)

/obj/item/pipe/proc/update()
	var/obj/machinery/atmospherics/fakeA = pipe_type
	name = "[initial(fakeA.name)] fitting"
	desc = initial(fakeA.desc)
	icon_state = initial(fakeA.pipe_state)
	if(ispath(pipe_type,/obj/machinery/atmospherics/pipe/heat_exchanging))
		resistance_flags |= FIRE_PROOF | LAVA_PROOF

/obj/item/pipe/verb/flip()
	set category = "Object"
	set name = "Invert Pipe"
	set src in view(1)

	if ( usr.incapacitated )
		return

	do_a_flip()

/obj/item/pipe/proc/do_a_flip()
	setDir(REVERSE_DIR(dir))

/obj/item/pipe/trinary/flippable/do_a_flip()
	setDir(turn(dir, flipped ? 45 : -45))
	flipped = !flipped

/obj/item/pipe/Move()
	var/old_dir = dir
	..()
	setDir(old_dir) //pipes changing direction when moved is just annoying and buggy

// Convert dir of fitting into dir of built component
/obj/item/pipe/proc/fixed_dir()
	return dir

/obj/item/pipe/binary/fixed_dir()
	. = dir
	if(dir == SOUTH)
		. = NORTH
	else if(dir == WEST)
		. = EAST

/obj/item/pipe/trinary/flippable/fixed_dir()
	. = dir
	if(ISDIAGONALDIR(dir))
		. = turn(dir, 45)

/obj/item/pipe/attack_self(mob/user)
	setDir(turn(dir,-90))

///Check if the pipe on the turf and our to be placed binary pipe are perpendicular to each other
/obj/item/pipe/proc/check_ninety_degree_dir(obj/machinery/atmospherics/machine)
	if(ISDIAGONALDIR(machine.dir))
		return FALSE
	if(EWCOMPONENT(machine.dir) && EWCOMPONENT(dir))
		return FALSE
	if(NSCOMPONENT(machine.dir) && NSCOMPONENT(dir))
		return FALSE
	return TRUE

/obj/item/pipe/wrench_act(mob/living/user, obj/item/wrench/wrench)
	. = ..()
	if(!isturf(loc))
		return TRUE

	add_fingerprint(user)

	var/obj/machinery/atmospherics/fakeA = pipe_type
	var/flags = initial(fakeA.pipe_flags)
	var/list/potentially_conflicting_machines = list()
	// Work out which machines we would potentially conflict with
	for(var/obj/machinery/atmospherics/machine in loc)
		// Only one dense/requires density object per tile, eg connectors/cryo/heater/coolers.
		if(machine.pipe_flags & flags & PIPING_ONE_PER_TURF)
			to_chat(user, span_warning("Something is hogging the tile!"))
			return TRUE
		// skip checks if we don't overlap layers, either by being on the same layer or by something being on all layers
		if(machine.piping_layer != piping_layer && !((machine.pipe_flags | flags) & PIPING_ALL_LAYER))
			continue
		potentially_conflicting_machines += machine

	// See if we would conflict with any of the potentially interacting machines
	for(var/obj/machinery/atmospherics/machine as anything in potentially_conflicting_machines)
		// if the pipes have any directions in common, we can't place it that way.
		var/our_init_dirs = SSair.get_init_dirs(pipe_type, fixed_dir(), p_init_dir)
		if(machine.get_init_directions() & our_init_dirs)
			// We have a conflict!
			if (length(potentially_conflicting_machines) != 1 || !try_smart_reconfiguration(machine, our_init_dirs, user))
				// No solutions found
				to_chat(user, span_warning("There is already a pipe at that location!"))
				return TRUE
	// no conflicts found

	var/obj/machinery/atmospherics/built_machine = new pipe_type(loc, null, fixed_dir(), p_init_dir)
	build_pipe(built_machine)
	built_machine.on_construction(user, pipe_color, piping_layer)
	transfer_fingerprints_to(built_machine)

	wrench.play_tool_sound(src)
	user.visible_message( \
		"[user] fastens \the [src].", \
		span_notice("You fasten \the [src]."), \
		span_hear("You hear ratcheting."))

	qdel(src)

/obj/item/pipe/welder_act(mob/living/user, obj/item/welder)
	. = ..()
	if(istype(pipe_type, /obj/machinery/atmospherics/components))
		return TRUE
	if(!welder.tool_start_check(user, amount=2))
		return TRUE
	add_fingerprint(user)

	if(welder.use_tool(src, user, 2 SECONDS, volume=2))
		new /obj/item/sliced_pipe(drop_location())
		user.visible_message( \
			"[user] welds \the [src] in two.", \
			span_notice("You weld \the [src] in two."), \
			span_hear("You hear welding."))

		qdel(src)

/**
 * Attempt to automatically resolve a pipe conflict by reconfiguring any smart pipes involved.
 *
 * Constraints:
 *  - A smart pipe cannot have current connections reconfigured.
 *  - A smart pipe cannot have fewer than two directions in which it will connect.
 *  - A smart pipe, existing or new, will not automatically reconfigure itself to permit directions it was not previously permitting.
 */
/obj/item/pipe/proc/try_smart_reconfiguration(obj/machinery/atmospherics/machine, our_init_dirs, mob/living/user)
	// If we're a smart pipe, we might be able to solve this by placing down a more constrained version of ourselves.
	var/obj/machinery/atmospherics/pipe/smart/other_smart_pipe = machine
	if(ispath(pipe_type, /obj/machinery/atmospherics/pipe/smart/))
		// If we're conflicting with another smart pipe, see if we can negotiate.
		if(istype(other_smart_pipe))
			// Two smart pipes. This is going to get complicated.
			// Check to see whether the already placed pipe is bent or not.
			if (ISDIAGONALDIR(other_smart_pipe.dir))
				// The other pipe is bent, with at least two current connections. See if we can bounce off it as a bent pipe in the other direction.
				var/opposing_dir = our_init_dirs & ~other_smart_pipe.connections
				if (ISNOTSTUB(opposing_dir))
					// We only get here if both smart pipes have two directions.
					p_init_dir = opposing_dir
					other_smart_pipe.set_init_directions(other_smart_pipe.connections)
					other_smart_pipe.update_pipe_icon()
					return TRUE
				// We're left with one or no available directions if we look at the complement of the other smart pipe's live connections.
				// There's nothing further we can do.
				return FALSE
			else
				// The other pipe is straight. See if we can go over it in a perpindicular direction.
				// Note that the other pipe cannot be unconnected, since we have a conflict.
				if(EWCOMPONENT(other_smart_pipe.dir))
					if ((NORTH|SOUTH) & ~p_init_dir)
						// Not allowed to connect this way
						return FALSE
					if (~other_smart_pipe.get_init_directions() & (EAST|WEST))
						// Not allowed to reconfigure the other pipe this way
						return FALSE
					p_init_dir = NORTH|SOUTH
					other_smart_pipe.set_init_directions(EAST|WEST)
					other_smart_pipe.update_pipe_icon()
					return TRUE
				if (NSCOMPONENT(other_smart_pipe.dir))
					if ((EAST|WEST) & ~p_init_dir)
						// Not allowed to connect this way
						return FALSE
					if (~other_smart_pipe.get_init_directions() & (NORTH|SOUTH))
						// Not allowed to reconfigure the other pipe this way
						return FALSE
					p_init_dir = EAST|WEST
					other_smart_pipe.set_init_directions(NORTH|SOUTH)
					other_smart_pipe.update_pipe_icon()
					return TRUE
			return FALSE
		// We're not dealing with another smart pipe. See if we can become the complement of the conflicting machine.
		var/opposing_dir = our_init_dirs & ~machine.get_init_directions()
		if (ISNOTSTUB(opposing_dir))
			// We have at least two permitted directions in the complement. Use them.
			p_init_dir = opposing_dir
			return TRUE
		return FALSE

	else if(istype(other_smart_pipe))
		// We're not a smart pipe ourselves, but we are conflicting with a smart pipe. We might be able to solve this by constraining the smart pipe.
		if (our_init_dirs & other_smart_pipe.connections)
			// We needed to go where a smart pipe already had connections, nothing further we can do
			return FALSE
		var/opposing_dir = other_smart_pipe.get_init_directions() & ~our_init_dirs
		if (ISNOTSTUB(opposing_dir))
			// At least two directions remain for that smart pipe, reconfigure it
			other_smart_pipe.set_init_directions(opposing_dir)
			other_smart_pipe.update_pipe_icon()
			return TRUE
		return FALSE
	// No smart pipes involved, the conflict can't be solved this way.
	return FALSE

/obj/item/pipe/proc/build_pipe(obj/machinery/atmospherics/A)
	if(pipename)
		A.name = pipename
	if(A.on)
		// Certain pre-mapped subtypes are on by default, we want to preserve
		// every other aspect of these subtypes (name, pre-set filters, etc.)
		// but they shouldn't turn on automatically when wrenched.
		A.on = FALSE

/obj/item/pipe/trinary/flippable/build_pipe(obj/machinery/atmospherics/components/trinary/T)
	..()
	T.flipped = flipped

/obj/item/pipe/suicide_act(mob/living/user)
	user.visible_message(span_suicide("[user] shoves [src] in [user.p_their()] mouth and turns it on! It looks like [user.p_theyre()] trying to commit suicide!"))
	if(iscarbon(user))
		var/mob/living/carbon/C = user
		for(var/i in 1 to 20)
			C.vomit(vomit_flags = (MOB_VOMIT_BLOOD | MOB_VOMIT_HARM), lost_nutrition = 0, distance = 4)
			if(prob(20))
				C.spew_organ()
			sleep(0.5 SECONDS)
		C.blood_volume = 0
	return(OXYLOSS|BRUTELOSS)

/obj/item/pipe/examine(mob/user)
	. = ..()
	. += span_notice("The pipe layer is set to [piping_layer].")
	. += span_notice("You can change the pipe layer by Right-Clicking the device.")

/obj/item/pipe/attack_hand_secondary(mob/user, list/modifiers)
	. = ..()
	if(. == SECONDARY_ATTACK_CANCEL_ATTACK_CHAIN)
		return
	var/layer_to_set = (piping_layer >= PIPING_LAYER_MAX) ? PIPING_LAYER_MIN : (piping_layer + 1)
	set_piping_layer(layer_to_set)
	balloon_alert(user, "pipe layer set to [piping_layer]")
	return SECONDARY_ATTACK_CANCEL_ATTACK_CHAIN


/obj/item/pipe/trinary/flippable/examine(mob/user)
	. = ..()
	. += span_notice("You can flip the device by Right-Clicking it.")

/obj/item/pipe/trinary/flippable/attack_hand_secondary(mob/user, list/modifiers)
	. = ..()
	if(. == SECONDARY_ATTACK_CANCEL_ATTACK_CHAIN)
		return
	do_a_flip()
	balloon_alert(user, "pipe was flipped")
	return SECONDARY_ATTACK_CANCEL_ATTACK_CHAIN

/obj/item/pipe_meter
	name = "meter"
	desc = "A meter that can be wrenched on pipes, or attached to the floor with screws."
	icon = 'icons/obj/pipes_n_cables/pipe_item.dmi'
	icon_state = "meter"
	inhand_icon_state = "buildpipe"
	w_class = WEIGHT_CLASS_BULKY
	var/piping_layer = PIPING_LAYER_DEFAULT

/obj/item/pipe_meter/wrench_act(mob/living/user, obj/item/wrench/W)
	. = ..()
	var/obj/machinery/atmospherics/pipe/pipe
	for(var/obj/machinery/atmospherics/pipe/P in loc)
		if(P.piping_layer == piping_layer)
			pipe = P
			break
	if(!pipe)
		to_chat(user, span_warning("You need to fasten it to a pipe!"))
		return TRUE
	new /obj/machinery/meter(loc, piping_layer)
	W.play_tool_sound(src)
	to_chat(user, span_notice("You fasten the meter to the pipe."))
	qdel(src)

/obj/item/pipe_meter/screwdriver_act(mob/living/user, obj/item/S)
	. = ..()
	if(.)
		return TRUE

	if(!isturf(loc))
		to_chat(user, span_warning("You need to fasten it to the floor!"))
		return TRUE

	new /obj/machinery/meter/turf(loc, piping_layer)
	S.play_tool_sound(src)
	to_chat(user, span_notice("You fasten the meter to \the [loc]."))
	qdel(src)

/obj/item/pipe_meter/dropped()
	. = ..()
	if(loc)
		setAttachLayer(piping_layer)

/obj/item/pipe_meter/proc/setAttachLayer(new_layer = PIPING_LAYER_DEFAULT)
	piping_layer = new_layer
	PIPING_LAYER_DOUBLE_SHIFT(src, piping_layer)
