#define CHANGETURF_DEFER_CHANGE (1<<0)
#define CHANGETURF_IGNORE_AIR (1<<1) // This flag prevents changeturf from gathering air from nearby turfs to fill the new turf with an approximation of local air
#define CHANGETURF_FORCEOP (1<<2)
#define CHANGETURF_SKIP (1<<3) // A flag for PlaceOnTop to just instance the new turf instead of calling ChangeTurf. Used for uninitialized turfs NOTHING ELSE
#define CHANGETURF_INHERIT_AIR (1<<4) // Inherit air from previous turf. Implies CHANGETURF_IGNORE_AIR
#define CHANGETURF_RECALC_ADJACENT (1<<5) //Immediately recalc adjacent atmos turfs instead of queuing.
#define CHANGETURF_TRAPDOOR_INDUCED (1<<6) // Caused by a trapdoor, for trapdoor to know that this changeturf was caused by itself
#define CHANGETURF_GENERATE_SHUTTLE_CEILING (1<<7) // Generate a shuttle ceiling on the above turf

#define IS_OPAQUE_TURF(turf) (turf.directional_opacity == ALL_CARDINALS)

//supposedly the fastest way to do this according to https://gist.github.com/Giacom/be635398926bb463b42a
///Returns a list of turf in a square
#define RANGE_TURFS(RADIUS, CENTER) \
	RECT_TURFS(RADIUS, RADIUS, CENTER)

#define RECT_TURFS(H_RADIUS, V_RADIUS, CENTER) \
	block( \
	(CENTER).x - (H_RADIUS), (CENTER).y - (V_RADIUS), (CENTER).z, \
	(CENTER).x + (H_RADIUS), (CENTER).y + (V_RADIUS), (CENTER).z \
	)

///Returns all turfs in a zlevel
#define Z_TURFS(ZLEVEL) block(1, 1, ZLEVEL, world.maxx, world.maxy, ZLEVEL)

///Returns all currently loaded turfs
#define ALL_TURFS(...) block(1, 1, 1, world.maxx, world.maxy, world.maxz)

#define TURF_FROM_COORDS_LIST(List) (locate(List[1], List[2], List[3]))

/// Returns a list of turfs in the rectangle specified by BOTTOM LEFT corner and height/width, checks for being outside the world border for you
#define CORNER_BLOCK(corner, width, height) CORNER_BLOCK_OFFSET(corner, width, height, 0, 0)

/// Returns a list of turfs similar to CORNER_BLOCK but with offsets
#define CORNER_BLOCK_OFFSET(corner, width, height, offset_x, offset_y) ((block(corner.x + offset_x, corner.y + offset_y, corner.z, corner.x + (width - 1) + offset_x, corner.y + (height - 1) + offset_y, corner.z)))

/// Returns an outline (neighboring turfs) of the given block
#define CORNER_OUTLINE(corner, width, height) ( \
	CORNER_BLOCK_OFFSET(corner, width + 2, 1, -1, -1) + \
	CORNER_BLOCK_OFFSET(corner, width + 2, 1, -1, height) + \
	CORNER_BLOCK_OFFSET(corner, 1, height, -1, 0) + \
	CORNER_BLOCK_OFFSET(corner, 1, height, width, 0))

/// Returns a list of around us
#define TURF_NEIGHBORS(turf) (CORNER_BLOCK_OFFSET(turf, 3, 3, -1, -1) - turf)

/// The pipes, disposals, and wires are hidden
#define UNDERFLOOR_HIDDEN 0
/// The pipes, disposals, and wires are visible but cannot be interacted with
#define UNDERFLOOR_VISIBLE 1
/// The pipes, disposals, and wires are visible and can be interacted with
#define UNDERFLOOR_INTERACTABLE 2

//Wet floor type flags. Stronger ones should be higher in number.
/// Turf is dry and mobs won't slip
#define TURF_DRY (0)
/// Turf has water on the floor and mobs will slip unless walking or using galoshes
#define TURF_WET_WATER (1<<0)
/// Turf has a thick layer of ice on the floor and mobs will slip in the direction until they bump into something
#define TURF_WET_PERMAFROST (1<<1)
/// Turf has a thin layer of ice on the floor and mobs will slip
#define TURF_WET_ICE (1<<2)
/// Turf has lube on the floor and mobs will slip
#define TURF_WET_LUBE (1<<3)
/// Turf has superlube on the floor and mobs will slip even if they are crawling
#define TURF_WET_SUPERLUBE (1<<4)

/// Maximum amount of time, (in deciseconds) a tile can be wet for.
#define MAXIMUM_WET_TIME (5 MINUTES)

/**
 * Get the turf that `A` resides in, regardless of any containers.
 *
 * Use in favor of `A.loc` or `src.loc` so that things work correctly when
 * stored inside an inventory, locker, or other container.
 */
#define get_turf(A) (get_step(A, 0))

/**
 * Get the ultimate area of `A`, similarly to [get_turf].
 *
 * Use instead of `A.loc.loc`.
 */
#define get_area(A) (isarea(A) ? A : get_step(A, 0)?.loc)

// Defines for turfs rust resistance
#define RUST_RESISTANCE_BASIC 1
#define RUST_RESISTANCE_REINFORCED 2
#define RUST_RESISTANCE_TITANIUM 3
#define RUST_RESISTANCE_ORGANIC 4
#define RUST_RESISTANCE_ABSOLUTE 5

/// Turf will be passable if density is 0
#define TURF_PATHING_PASS_DENSITY 0
/// Turf will be passable depending on [CanAStarPass] return value
#define TURF_PATHING_PASS_PROC 1
/// Turf is never passable
#define TURF_PATHING_PASS_NO 2

/// Define the alpha for holiday/colored tile decals
#define DECAL_ALPHA 60
/// Generate horizontal striped color turf decals
#define PATTERN_DEFAULT "default"
/// Generate vertical striped color turf decals
#define PATTERN_VERTICAL_STRIPE "vertical"
/// Generate random color turf decals
#define PATTERN_RANDOM "random"
/// Generate rainbow color turf decals
#define PATTERN_RAINBOW "rainbow"

/**
 * Finds the midpoint of two given turfs.
 */
#define TURF_MIDPOINT(a, b) (locate(((a.x + b.x) * 0.5), (a.y + b.y) * 0.5, (a.z + b.z) * 0.5))

/// Defines the x offset to apply to larger smoothing turfs (such as grass).
#define LARGE_TURF_SMOOTHING_X_OFFSET -9
/// Defines the y offset to apply to larger smoothing turfs (such as grass).
#define LARGE_TURF_SMOOTHING_Y_OFFSET -9

/// Defines a consistent light power for our various basalt turfs
#define BASALT_LIGHT_POWER 0.6
/// Defines a consistent light range for basalt turfs that have a bigger area of lava
#define BASALT_LIGHT_RANGE_BRIGHT 2
/// Defines a consistent light range for basalt turfs that have a smaller area of lava
#define BASALT_LIGHT_RANGE_DIM 1.4

/// Makes the set turf transparent
#define ADD_TURF_TRANSPARENCY(modturf, source) \
	if(!HAS_TRAIT(modturf, TURF_Z_TRANSPARENT_TRAIT)) { modturf.AddElement(/datum/element/turf_z_transparency) }; \
	ADD_TRAIT(modturf, TURF_Z_TRANSPARENT_TRAIT, (source))

/// Removes the transparency from the set turf
#define REMOVE_TURF_TRANSPARENCY(modturf, source) \
	REMOVE_TRAIT(modturf, TURF_Z_TRANSPARENT_TRAIT, (source)); \
	if(!HAS_TRAIT(modturf, TURF_Z_TRANSPARENT_TRAIT)) { modturf.RemoveElement(/datum/element/turf_z_transparency) }
