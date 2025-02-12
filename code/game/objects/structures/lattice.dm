/obj/structure/lattice
	name = "lattice"
	desc = "A lightweight support lattice. These hold our station together."
	icon = 'icons/obj/smooth_structures/lattice.dmi'
	icon_state = "lattice-255"
	base_icon_state = "lattice"
	density = FALSE
	anchored = TRUE
	armor_type = /datum/armor/structure_lattice
	max_integrity = 50
	layer = LATTICE_LAYER //under pipes
	plane = FLOOR_PLANE
	obj_flags = CAN_BE_HIT | BLOCK_Z_OUT_DOWN
	smoothing_flags = SMOOTH_BITMASK
	smoothing_groups = SMOOTH_GROUP_LATTICE
	canSmoothWith = SMOOTH_GROUP_LATTICE + SMOOTH_GROUP_WALLS + SMOOTH_GROUP_OPEN_FLOOR
	var/number_of_mats = 1
	var/build_material = /obj/item/stack/rods
	var/list/give_turf_traits = list(TRAIT_CHASM_STOPPED, TRAIT_HYPERSPACE_STOPPED)

/obj/structure/lattice/Initialize(mapload)
	. = ..()
	if(length(give_turf_traits))
		give_turf_traits = string_list(give_turf_traits)
		AddElement(/datum/element/give_turf_traits, give_turf_traits)
	AddElement(/datum/element/footstep_override, footstep = FOOTSTEP_CATWALK)

/datum/armor/structure_lattice
	melee = 50
	fire = 80
	acid = 50

/obj/structure/lattice/examine(mob/user)
	. = ..()
	. += deconstruction_hints(user)

/obj/structure/lattice/Destroy(force) // so items on the lattice fall when the lattice is destroyed
	var/turf/turfloc = loc
	. = ..()
	if(isturf(turfloc))
		for(var/thing_that_falls as anything in turfloc) // as anything because turfloc can only contain movables
			turfloc.zFall((thing_that_falls))

/obj/structure/lattice/proc/deconstruction_hints(mob/user)
	return span_notice("The rods look like they could be <b>cut</b>. There's space for more <i>rods</i> or a <i>tile</i>.")

/obj/structure/lattice/Initialize(mapload)
	. = ..()
	for(var/obj/structure/lattice/LAT in loc)
		if(LAT == src)
			continue
		stack_trace("multiple lattices found in ([loc.x], [loc.y], [loc.z])")
		return INITIALIZE_HINT_QDEL

/obj/structure/lattice/blob_act(obj/structure/blob/B)
	return

/obj/structure/lattice/attackby(obj/item/C, mob/user, params)
	if(resistance_flags & INDESTRUCTIBLE)
		return
	if(C.tool_behaviour == TOOL_WIRECUTTER)
		to_chat(user, span_notice("Slicing [name] joints ..."))
		deconstruct()
	else
		var/turf/T = get_turf(src)
		return T.attackby(C, user) //hand this off to the turf instead (for building plating, catwalks, etc)

/obj/structure/lattice/atom_deconstruct(disassembled = TRUE)
	new build_material(get_turf(src), number_of_mats)

/obj/structure/lattice/rcd_vals(mob/user, obj/item/construction/rcd/the_rcd)
	if(the_rcd.mode == RCD_TURF)
		return list("delay" = 0, "cost" = the_rcd.rcd_design_path == /obj/structure/lattice/catwalk ? 2 : 1)
	return FALSE

/obj/structure/lattice/rcd_act(mob/user, obj/item/construction/rcd/the_rcd, list/rcd_data)
	if(rcd_data["[RCD_DESIGN_MODE]"] == RCD_TURF)
		var/design_structure = rcd_data["[RCD_DESIGN_PATH]"]
		if(design_structure == /turf/open/floor/plating/rcd)
			var/turf/T = src.loc
			if(isgroundlessturf(T))
				T.place_on_top(/turf/open/floor/plating, flags = CHANGETURF_INHERIT_AIR)
				qdel(src)
				return TRUE
		if(design_structure == /obj/structure/lattice/catwalk)
			replace_with_catwalk()
			return TRUE
	return FALSE

/obj/structure/lattice/singularity_pull(atom/singularity, current_size)
	if(current_size >= STAGE_FOUR)
		deconstruct()

/obj/structure/lattice/proc/replace_with_catwalk()
	var/list/post_replacement_callbacks = list()
	SEND_SIGNAL(src, COMSIG_LATTICE_PRE_REPLACE_WITH_CATWALK, post_replacement_callbacks)
	var/turf/turf = loc
	qdel(src)
	var/new_catwalk = new /obj/structure/lattice/catwalk(turf)
	for(var/datum/callback/callback as anything in post_replacement_callbacks)
		callback.Invoke(new_catwalk)

/obj/structure/lattice/catwalk
	name = "catwalk"
	desc = "A catwalk for easier EVA maneuvering and cable placement."
	icon = 'icons/obj/smooth_structures/catwalk.dmi'
	icon_state = "catwalk-0"
	base_icon_state = "catwalk"
	number_of_mats = 2
	smoothing_flags = SMOOTH_BITMASK
	smoothing_groups = SMOOTH_GROUP_CATWALK + SMOOTH_GROUP_LATTICE + SMOOTH_GROUP_OPEN_FLOOR
	canSmoothWith = SMOOTH_GROUP_CATWALK
	obj_flags = CAN_BE_HIT | BLOCK_Z_OUT_DOWN | BLOCK_Z_IN_UP
	give_turf_traits = list(TRAIT_TURF_IGNORE_SLOWDOWN, TRAIT_LAVA_STOPPED, TRAIT_CHASM_STOPPED, TRAIT_IMMERSE_STOPPED, TRAIT_HYPERSPACE_STOPPED)

/obj/structure/lattice/catwalk/deconstruction_hints(mob/user)
	return span_notice("The supporting rods look like they could be <b>cut</b>.")

/obj/structure/lattice/catwalk/Move()
	var/turf/T = loc
	for(var/obj/structure/cable/C in T)
		C.deconstruct()
	..()

/obj/structure/lattice/catwalk/atom_deconstruct(disassembled = TRUE)
	..()
	var/turf/T = loc
	for(var/obj/structure/cable/C in T)
		C.deconstruct()

/obj/structure/lattice/catwalk/rcd_vals(mob/user, obj/item/construction/rcd/the_rcd)
	if(the_rcd.mode == RCD_DECONSTRUCT)
		return list("mode" = RCD_DECONSTRUCT, "delay" = 1 SECONDS, "cost" = 5)
	return FALSE

/obj/structure/lattice/catwalk/rcd_act(mob/user, obj/item/construction/rcd/the_rcd, passed_mode)
	if(passed_mode == RCD_DECONSTRUCT)
		var/turf/turf = loc
		for(var/obj/structure/cable/cable_coil in turf)
			cable_coil.deconstruct()
		qdel(src)
		return TRUE

/obj/structure/lattice/catwalk/mining
	name = "reinforced catwalk"
	desc = "A heavily reinforced catwalk used to build bridges in hostile environments. It doesn't look like anything could make this budge."
	resistance_flags = INDESTRUCTIBLE

/obj/structure/lattice/catwalk/mining/deconstruction_hints(mob/user)
	return

/obj/structure/lattice/lava
	name = "heatproof support lattice"
	desc = "A specialized support beam for building across lava. Watch your step."
	icon = 'icons/obj/smooth_structures/catwalk.dmi'
	icon_state = "catwalk-0"
	base_icon_state = "catwalk"
	number_of_mats = 1
	color = "#5286b9ff"
	smoothing_flags = SMOOTH_BITMASK
	smoothing_groups = SMOOTH_GROUP_LATTICE + SMOOTH_GROUP_OPEN_FLOOR
	canSmoothWith = SMOOTH_GROUP_LATTICE
	obj_flags = CAN_BE_HIT | BLOCK_Z_OUT_DOWN | BLOCK_Z_IN_UP
	resistance_flags = FIRE_PROOF | LAVA_PROOF
	give_turf_traits = list(TRAIT_LAVA_STOPPED, TRAIT_CHASM_STOPPED, TRAIT_IMMERSE_STOPPED, TRAIT_HYPERSPACE_STOPPED)

/obj/structure/lattice/lava/deconstruction_hints(mob/user)
	return span_notice("The rods look like they could be <b>cut</b>, but the <i>heat treatment will shatter off</i>. There's space for a <i>tile</i>.")

/obj/structure/lattice/lava/attackby(obj/item/attacking_item, mob/user, params)
	. = ..()
	if(!ismetaltile(attacking_item))
		return
	var/obj/item/stack/tile/iron/attacking_tiles = attacking_item
	if(!attacking_tiles.use(1))
		to_chat(user, span_warning("You need one floor tile to build atop [src]."))
		return
	to_chat(user, span_notice("You construct new plating with [src] as support."))
	playsound(src, 'sound/items/weapons/genhit.ogg', 50, TRUE)

	var/turf/turf_we_place_on = get_turf(src)
	turf_we_place_on.place_on_top(/turf/open/floor/plating, flags = CHANGETURF_INHERIT_AIR)

	qdel(src)
