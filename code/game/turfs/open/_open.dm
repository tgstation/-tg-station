/turf/open
	layer = LOW_FLOOR_LAYER
	plane = FLOOR_PLANE
	///negative for faster, positive for slower
	var/slowdown = 0

	var/footstep = null
	var/barefootstep = null
	var/clawfootstep = null
	var/heavyfootstep = null

	/// Determines the type of damage overlay that will be used for the tile
	var/damaged_dmi = null
	var/broken = FALSE
	/// Are broken overlays smoothed? if they are we have to change a little bit about how we render them
	var/smooth_broken = FALSE
	var/burnt = FALSE
	/// Are burnt overlays smoothed? if they are we have to change a little bit about how we render them
	var/smooth_burnt = FALSE


/// Returns a list of every turf state considered "broken".
/// Will be randomly chosen if a turf breaks at runtime.
/turf/open/proc/broken_states()
	return list()

/// Returns a list of every turf state considered "burnt".
/// Will be randomly chosen if a turf is burnt at runtime.
/turf/open/proc/burnt_states()
	return list()

/turf/open/break_tile()
	if(isnull(damaged_dmi) || broken)
		return FALSE
	broken = TRUE
	update_appearance()
	return TRUE

/turf/open/burn_tile()
	if(isnull(damaged_dmi) || burnt)
		return FALSE
	burnt = TRUE
	update_appearance()
	return TRUE

/turf/open/update_overlays()
	if(isnull(damaged_dmi))
		return ..()

	. = ..()

	if(broken)
		var/mutable_appearance/broken_appearance = mutable_appearance(damaged_dmi, pick(broken_states()))

		if(smoothing_flags && !smooth_broken)
			var/matrix/translation = new
			translation.Translate(-LARGE_TURF_SMOOTHING_X_OFFSET, -LARGE_TURF_SMOOTHING_Y_OFFSET)
			broken_appearance.transform = translation

		. += broken_appearance

	else if(burnt)
		var/list/burnt_states = burnt_states()
		var/mutable_appearance/burnt_appearance
		if(burnt_states.len)
			burnt_appearance = mutable_appearance(damaged_dmi, pick(burnt_states))
		else
			burnt_appearance = mutable_appearance(damaged_dmi, pick(broken_states()))

		if(smoothing_flags && !smooth_burnt)
			var/matrix/translation = new
			translation.Translate(-LARGE_TURF_SMOOTHING_X_OFFSET, -LARGE_TURF_SMOOTHING_Y_OFFSET)
			burnt_appearance.transform = translation

		. += burnt_appearance

/turf/open/examine_descriptor(mob/user)
	return "floor"

//direction is direction of travel of A
/turf/open/zPassIn(direction)
	if(direction != DOWN)
		return FALSE
	for(var/obj/on_us in contents)
		if(on_us.obj_flags & BLOCK_Z_IN_DOWN)
			return FALSE
	return TRUE

//direction is direction of travel of an atom
/turf/open/zPassOut(direction)
	if(direction != UP)
		return FALSE
	for(var/obj/on_us in contents)
		if(on_us.obj_flags & BLOCK_Z_OUT_UP)
			return FALSE
	return TRUE

//direction is direction of travel of air
/turf/open/zAirIn(direction, turf/source)
	return (direction == DOWN)

//direction is direction of travel of air
/turf/open/zAirOut(direction, turf/source)
	return (direction == UP)

/turf/open/update_icon()
	. = ..()
	update_visuals()

/**
 * Replace an open turf with another open turf while avoiding the pitfall of replacing plating with a floor tile, leaving a hole underneath.
 * This replaces the current turf if it is plating and is passed plating, is tile and is passed tile.
 * It places the new turf on top of itself if it is plating and is passed a tile.
 * It also replaces the turf if it is tile and is passed plating, essentially destroying the over turf.
 * Flags argument is passed directly to ChangeTurf or PlaceOnTop
 */
/turf/open/proc/replace_floor(turf/open/new_floor_path, flags)
	if (!overfloor_placed && initial(new_floor_path.overfloor_placed))
		place_on_top(new_floor_path, flags = flags)
		return
	ChangeTurf(new_floor_path, flags = flags)

/turf/open/indestructible
	name = "floor"
	desc = "The floor you walk on. It looks near-impervious to damage."
	icon = 'icons/turf/floors.dmi'
	icon_state = "floor"
	footstep = FOOTSTEP_FLOOR
	barefootstep = FOOTSTEP_HARD_BAREFOOT
	clawfootstep = FOOTSTEP_HARD_CLAW
	heavyfootstep = FOOTSTEP_GENERIC_HEAVY
	tiled_dirt = TRUE

/turf/open/indestructible/Melt()
	to_be_destroyed = FALSE
	return src

/turf/open/indestructible/singularity_act()
	return

/turf/open/indestructible/TerraformTurf(path, new_baseturf, flags, defer_change = FALSE, ignore_air = FALSE)
	return


/turf/open/indestructible/large
	icon_state = "floor_large"

/turf/open/indestructible/white
	icon_state = "white"

/turf/open/indestructible/white/smooth_large
	icon_state = "white_large"

/turf/open/indestructible/white/textured
	icon_state = "textured_white"

/turf/open/indestructible/dark
	icon_state = "darkfull"

/turf/open/indestructible/dark/textured
	icon_state = "textured_dark"

/turf/open/indestructible/dark/smooth_large
	icon_state = "dark_large"

/turf/open/indestructible/light
	icon_state = "light_on-1"
	light_range = 3
	light_color = LIGHT_COLOR_CYAN
	light_on = TRUE

/turf/open/indestructible/permalube
	icon_state = "darkfull"

/turf/open/indestructible/permalube/Initialize(mapload)
	. = ..()
	AddComponent(/datum/component/wet_floor, TURF_WET_LUBE, INFINITY, 0, INFINITY, TRUE)

/turf/open/indestructible/honk
	name = "bananium floor"
	icon_state = "bananium"
	footstep = null
	barefootstep = null
	clawfootstep = null
	heavyfootstep = null
	var/sound = 'sound/effects/footstep/clownstep1.ogg'

/turf/open/indestructible/honk/Initialize(mapload)
	. = ..()
	AddComponent(/datum/component/wet_floor, TURF_WET_SUPERLUBE, INFINITY, 0, INFINITY, TRUE)

/turf/open/indestructible/honk/Entered(atom/movable/arrived, atom/old_loc, list/atom/old_locs)
	. = ..()
	if(ismob(arrived))
		playsound(src, sound, 50, TRUE)

/turf/open/indestructible/necropolis
	name = "necropolis floor"
	desc = "It's regarding you suspiciously."
	icon = 'icons/turf/floors.dmi'
	icon_state = "necro1"
	baseturfs = /turf/open/indestructible/necropolis
	initial_gas_mix = LAVALAND_DEFAULT_ATMOS
	footstep = FOOTSTEP_LAVA
	barefootstep = FOOTSTEP_LAVA
	clawfootstep = FOOTSTEP_LAVA
	heavyfootstep = FOOTSTEP_LAVA
	tiled_dirt = FALSE

/turf/open/indestructible/necropolis/Initialize(mapload)
	. = ..()
	if(prob(12))
		icon_state = "necro[rand(2,3)]"

/turf/open/indestructible/necropolis/air
	initial_gas_mix = OPENTURF_DEFAULT_ATMOS

/turf/open/indestructible/boss //you put stone tiles on this and use it as a base
	name = "necropolis floor"
	icon = 'icons/turf/boss_floors.dmi'
	icon_state = "boss"
	baseturfs = /turf/open/indestructible/boss
	planetary_atmos = TRUE
	initial_gas_mix = LAVALAND_DEFAULT_ATMOS

/turf/open/indestructible/boss/air
	initial_gas_mix = OPENTURF_DEFAULT_ATMOS

/turf/open/indestructible/hierophant
	icon = 'icons/turf/floors/hierophant_floor.dmi'
	planetary_atmos = TRUE
	initial_gas_mix = LAVALAND_DEFAULT_ATMOS
	baseturfs = /turf/open/indestructible/hierophant
	smoothing_flags = SMOOTH_CORNERS
	tiled_dirt = FALSE

/turf/open/indestructible/hierophant/two

/turf/open/indestructible/hierophant/get_smooth_underlay_icon(mutable_appearance/underlay_appearance, turf/asking_turf, adjacency_dir)
	return FALSE

/turf/open/indestructible/paper
	name = "notebook floor"
	desc = "A floor made of invulnerable notebook paper."
	icon_state = "paperfloor"
	footstep = null
	barefootstep = null
	clawfootstep = null
	heavyfootstep = null
	tiled_dirt = FALSE

/turf/open/indestructible/binary
	name = "tear in the fabric of reality"
	can_atmos_pass = ATMOS_PASS_NO
	baseturfs = /turf/open/indestructible/binary
	icon_state = "binary"
	footstep = null
	barefootstep = null
	clawfootstep = null
	heavyfootstep = null

/turf/open/indestructible/airblock
	icon_state = "bluespace"
	blocks_air = TRUE
	init_air = FALSE
	baseturfs = /turf/open/indestructible/airblock

/turf/open/indestructible/meat
	icon_state = "meat"
	footstep = FOOTSTEP_MEAT
	barefootstep = FOOTSTEP_MEAT
	clawfootstep = FOOTSTEP_MEAT
	heavyfootstep = FOOTSTEP_MEAT
	initial_gas_mix = OPENTURF_DEFAULT_ATMOS
	baseturfs = /turf/open/indestructible/meat

/turf/open/indestructible/meat/airless
	initial_gas_mix = AIRLESS_ATMOS

/turf/open/indestructible/vault
	icon_state = "rockvault"

/turf/open/indestructible/plating
	name = "plating"
	icon_state = "plating"
	desc = "The attachment points are all bent to uselessness, looks nigh-impervious to damage."
	overfloor_placed = FALSE
	underfloor_accessibility = UNDERFLOOR_INTERACTABLE
	footstep = FOOTSTEP_PLATING

/turf/open/indestructible/plating/airless
	initial_gas_mix = AIRLESS_ATMOS

/turf/open/indestructible/kitchen
	icon_state = /turf/open/floor/iron/kitchen::icon_state

/turf/open/indestructible/rockyground
	icon_state = /turf/open/misc/ashplanet/rocky::icon_state
	icon = /turf/open/misc/ashplanet/rocky::icon
	name = /turf/open/misc/ashplanet/rocky::name

/turf/open/indestructible/stone
	icon_state = /turf/open/floor/stone::icon_state
	name = /turf/open/floor/stone::name

/turf/open/Initalize_Atmos(time)
	excited = FALSE
	update_visuals()

	current_cycle = time
	init_immediate_calculate_adjacent_turfs()

/turf/open/GetHeatCapacity()
	. = air.heat_capacity()

/turf/open/GetTemperature()
	. = air.temperature

/turf/open/TakeTemperature(temp)
	air.temperature += temp
	air_update_turf(FALSE, FALSE)

/turf/open/proc/freeze_turf()
	for(var/obj/I in contents)
		if(!HAS_TRAIT(I, TRAIT_FROZEN) && !(I.resistance_flags & FREEZE_PROOF))
			I.AddElement(/datum/element/frozen)

	for(var/mob/living/L in contents)
		if(L.bodytemperature <= 50 && !HAS_TRAIT(L, TRAIT_RESISTCOLD))
			L.apply_status_effect(/datum/status_effect/freon)
	MakeSlippery(TURF_WET_PERMAFROST, 10 SECONDS)
	return TRUE

/turf/open/proc/water_vapor_gas_act()
	MakeSlippery(TURF_WET_WATER, min_wet_time = 100, wet_time_to_add = 50)

	for(var/mob/living/basic/slime/M in src)
		M.apply_water()

	wash(CLEAN_WASH, TRUE)
	return TRUE

/turf/open/handle_slip(mob/living/slipper, knockdown_amount, obj/slippable, lube, paralyze_amount, daze_amount, force_drop)
	if(slipper.movement_type & MOVETYPES_NOT_TOUCHING_GROUND)
		return FALSE
	if(!has_gravity(src))
		return FALSE

	var/slide_distance = 4
	if(lube & SLIDE_ICE)
		// Ice slides only go 1 tile, this is so you will slip across ice until you reach a non-slip tile
		slide_distance = 1
	else if(HAS_TRAIT(slipper, TRAIT_CURSED) && !(lube & WEAK_SLIDE))
		// When cursed, all slips send you flying
		lube |= SLIDE
		slide_distance = rand(5, 9)
	else if(HAS_TRAIT(slipper, TRAIT_NO_SLIP_SLIDE))
		// Stops sliding
		slide_distance = 0
	else if(lube & WEAK_SLIDE)
		slide_distance = rand(1, 2)

	var/obj/buckled_obj
	if(slipper.buckled)
		if(!(lube & GALOSHES_DONT_HELP)) //can't slip while buckled unless it's lube.
			return FALSE
		buckled_obj = slipper.buckled
	else
		if(!(lube & SLIP_WHEN_CRAWLING) && (slipper.body_position == LYING_DOWN || !(slipper.status_flags & CANKNOCKDOWN))) // can't slip unbuckled mob if they're lying or can't fall.
			return FALSE
		if(slipper.move_intent == MOVE_INTENT_WALK && (lube & NO_SLIP_WHEN_WALKING))
			return FALSE

	if(!(lube & SLIDE_ICE))
		// Ice slides are intended to be combo'd so don't give the feedback
		to_chat(slipper, span_notice("You slipped[ slippable ? " on \the [slippable]" : ""]!"))
		playsound(slipper.loc, 'sound/misc/slip.ogg', 50, TRUE, -3)

	SEND_SIGNAL(slipper, COMSIG_ON_CARBON_SLIP)
	slipper.add_mood_event("slipped", /datum/mood_event/slipped)
	if(force_drop && iscarbon(slipper)) //carbon specific behavior that living doesn't have
		var/mob/living/carbon/carbon = slipper
		for(var/obj/item/item in slipper.held_items)
			carbon.accident(item)

	var/olddir = slipper.dir
	slipper.moving_diagonally = 0 //If this was part of diagonal move slipping will stop it.
	if(lube & SLIDE_ICE)
		// They need to be kept upright to maintain the combo effect (So don't knockdown)
		slipper.Immobilize(1 SECONDS)
		slipper.incapacitate(1 SECONDS)
	else if(lube & WEAK_SLIDE)
		slipper.adjust_staggered_up_to(STAGGERED_SLOWDOWN_LENGTH, 10 SECONDS)
		slipper.stop_pulling()
	else
		slipper.Paralyze(paralyze_amount)
		slipper.Knockdown(knockdown_amount, daze_amount = daze_amount)

	if(!isnull(buckled_obj) && !ismob(buckled_obj))
		buckled_obj.unbuckle_mob(slipper)
		// This is added onto the end so they slip "out of their chair" (one tile)
		lube |= SLIDE_ICE
		slide_distance = 1

	if(slide_distance)
		var/turf/target = get_ranged_target_turf(slipper, olddir, slide_distance)
		if(lube & (SLIDE|WEAK_SLIDE))
			slipper.AddComponent(/datum/component/force_move, target, TRUE)
		else if(lube & SLIDE_ICE)
			slipper.AddComponent(/datum/component/force_move, target, FALSE)//spinning would be bad for ice, fucks up the next dir
	return TRUE

/turf/open/proc/MakeSlippery(wet_setting = TURF_WET_WATER, min_wet_time = 0, wet_time_to_add = 0, max_wet_time = MAXIMUM_WET_TIME, permanent = FALSE, should_display_overlay = TRUE)
	AddComponent(/datum/component/wet_floor, wet_setting, min_wet_time, wet_time_to_add, max_wet_time, permanent, should_display_overlay)

/turf/open/proc/MakeDry(wet_setting = TURF_WET_WATER, immediate = FALSE, amount = INFINITY)
	SEND_SIGNAL(src, COMSIG_TURF_MAKE_DRY, wet_setting, immediate, amount)

/turf/open/get_dumping_location()
	return src

/turf/open/proc/ClearWet()//Nuclear option of immediately removing slipperiness from the tile instead of the natural drying over time
	qdel(GetComponent(/datum/component/wet_floor))

/// Builds with rods. This doesn't exist to be overridden, just to remove duplicate logic for turfs that want
/// To support floor tile creation
/// I'd make it a component, but one of these things is space. So no.
/turf/open/proc/build_with_rods(obj/item/stack/rods/used_rods, mob/user)
	var/obj/structure/lattice/catwalk_bait = locate(/obj/structure/lattice, src)
	var/obj/structure/lattice/catwalk/existing_catwalk = locate(/obj/structure/lattice/catwalk, src)
	if(existing_catwalk)
		to_chat(user, span_warning("There is already a catwalk here!"))
		return

	if(catwalk_bait)
		if(used_rods.use(1))
			to_chat(user, span_notice("You construct a catwalk."))
			playsound(src, 'sound/items/weapons/genhit.ogg', 50, TRUE)
			catwalk_bait.replace_with_catwalk()
		else
			to_chat(user, span_warning("You need two rods to build a catwalk!"))
		return

	if(used_rods.use(1))
		to_chat(user, span_notice("You construct a lattice."))
		playsound(src, 'sound/items/weapons/genhit.ogg', 50, TRUE)
		var/obj/structure/lattice/new_lattice = new (src)
		if(istype(used_rods, /obj/item/stack/rods/shuttle) && !istype(loc, /area/shuttle))
			new_lattice.AddElement(/datum/element/shuttle_construction_lattice)
	else
		to_chat(user, span_warning("You need one rod to build a lattice."))

/// Very similar to build_with_rods, this exists to allow consistent behavior between different types in terms of how
/// Building floors works
/turf/open/proc/build_with_floor_tiles(obj/item/stack/tile/iron/used_tiles, user)
	var/obj/structure/lattice/lattice = locate(/obj/structure/lattice, src)
	if(!has_valid_support() && !lattice)
		balloon_alert(user, "needs support, place rods!")
		return
	if(!used_tiles.use(1))
		balloon_alert(user, "need a floor tile to build!")
		return

	playsound(src, 'sound/items/weapons/genhit.ogg', 50, TRUE)
	var/turf/open/floor/plating/new_plating = place_on_top(/turf/open/floor/plating, flags = CHANGETURF_INHERIT_AIR)
	if(istype(loc, /area/shuttle))
		new_plating.insert_baseturf(turf_type = /turf/baseturf_skipover/shuttle)
	if(lattice)
		qdel(lattice)
	else
		new_plating.lattice_underneath = FALSE

/turf/open/proc/has_valid_support()
	for (var/direction in GLOB.cardinals)
		if(istype(get_step(src, direction), /turf/open/floor))
			return TRUE
	return FALSE

/// Very similar to build_with_rods, this exists to allow consistent behavior between different types in terms of how
/// Building floors works
/turf/open/proc/build_with_transport_tiles(obj/item/stack/thermoplastic/used_tiles, user)
	var/obj/structure/transport/linear/platform = locate(/obj/structure/transport/linear, src)
	if(!platform)
		balloon_alert(user, "no tram base!")
		return
	if(!used_tiles.use(1))
		balloon_alert(user, "no tile!")
		return

	playsound(src, 'sound/items/weapons/genhit.ogg', 50, TRUE)
	new used_tiles.tile_type(src)

/turf/open/apply_main_material_effects(datum/material/main_material, amount, multipier)
	. = ..()
	if(!main_material.turf_sound_override)
		return
	footstep = main_material.turf_sound_override
	barefootstep = main_material.turf_sound_override + "barefoot"
	clawfootstep = main_material.turf_sound_override + "claw"
	heavyfootstep = FOOTSTEP_GENERIC_HEAVY

/// Very similar to build_with_rods, this exists to allow building transport/tram girders on openspace
/turf/open/proc/build_with_titanium(obj/item/stack/sheet/mineral/titanium/used_stack, user)
	var/obj/structure/transport/linear/platform = locate(/obj/structure/transport/linear, src)
	if(!platform)
		to_chat(user, span_warning("There is no transport frame to attach the anchor!"))
		return
	if(!used_stack.use(2))
		balloon_alert(user, "not enough titanium!")
		return

	playsound(src, 'sound/items/weapons/genhit.ogg', 50, TRUE)
	new /obj/structure/girder/tram(src)
