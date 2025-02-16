/// The minimum for glide_size to be clamped to.
#define MIN_GLIDE_SIZE 1
/// The maximum for glide_size to be clamped to.
/// This shouldn't be higher than the icon size, and generally you shouldn't be changing this, but it's here just in case.
#define MAX_GLIDE_SIZE ICON_SIZE_ALL

/// Compensating for time dilation
GLOBAL_VAR_INIT(glide_size_multiplier, 1.0)
GLOBAL_VAR_INIT(old_glide_size_multiplier, 1.0)
GLOBAL_VAR_INIT(use_new_glide, FALSE)

#define GLIDE_SIZE_MULTI (GLOB.use_new_glide ? GLOB.glide_size_multiplier : GLOB.old_glide_size_multiplier)

///Broken down, here's what this does:
/// divides the world icon_size by delay divided by ticklag to get the number of pixels something should be moving each tick.
/// The division result is given a min value of 1 to prevent obscenely slow glide sizes from being set
/// Then that's multiplied by the global glide size multiplier. 1.25 by default feels pretty close to spot on. This is just to try to get byond to behave.
/// The whole result is then clamped to within the range above.
/// Not very readable but it works
#define DELAY_TO_GLIDE_SIZE(delay) (clamp(((ICON_SIZE_ALL / max((delay) / world.tick_lag, 1)) * GLIDE_SIZE_MULTI), MIN_GLIDE_SIZE, MAX_GLIDE_SIZE))

///Similar to DELAY_TO_GLIDE_SIZE, except without the clamping, and it supports piping in an unrelated scalar
#define MOVEMENT_ADJUSTED_GLIDE_SIZE(delay, movement_disparity) (ICON_SIZE_ALL / ((delay) / world.tick_lag) * movement_disparity * GLIDE_SIZE_MULTI)

//Movement loop priority. Only one loop can run at a time, this dictates that
// Higher numbers beat lower numbers
///Standard, go lower then this if you want to override, higher otherwise
#define MOVEMENT_DEFAULT_PRIORITY 10
///Very few things should override this
#define MOVEMENT_SPACE_PRIORITY 100
///Higher then the heavens
#define MOVEMENT_ABOVE_SPACE_PRIORITY (MOVEMENT_SPACE_PRIORITY + 1)

//Movement loop flags
///Should the loop act immediately following its addition?
#define MOVEMENT_LOOP_START_FAST (1<<0)
///Do we not use the priority system?
#define MOVEMENT_LOOP_IGNORE_PRIORITY (1<<1)
///Should we override the loop's glide?
#define MOVEMENT_LOOP_IGNORE_GLIDE (1<<2)
///Should we not update our movables dir on move?
#define MOVEMENT_LOOP_NO_DIR_UPDATE (1<<3)
///Is the loop moving the movable outside its control, like it's an external force? e.g. footsteps won't play if enabled.
#define MOVEMENT_LOOP_OUTSIDE_CONTROL (1<<4)

// Movement loop status flags
/// Has the loop been paused, soon to be resumed?
#define MOVELOOP_STATUS_PAUSED (1<<0)
/// Is the loop running? (Is true even when paused)
#define MOVELOOP_STATUS_RUNNING (1<<1)
/// Is the loop queued in a subsystem?
#define MOVELOOP_STATUS_QUEUED (1<<2)

/**
 * Returns a bitfield containing flags both present in `flags` arg and the `processing_move_loop_flags` move_packet variable.
 * Has no use outside of procs called within the movement proc chain.
 */
#define CHECK_MOVE_LOOP_FLAGS(movable, flags) (movable.move_packet ? (movable.move_packet.processing_move_loop_flags & (flags)) : NONE)

//Index defines for movement bucket data packets
#define MOVEMENT_BUCKET_TIME 1
#define MOVEMENT_BUCKET_LIST 2

/**
 * currently_z_moving defines. Higher numbers mean higher priority.
 * This one is for falling down open space from stuff such as deleted tile, pit grate...
 */
#define CURRENTLY_Z_FALLING 1
/// currently_z_moving is set to this in zMove() if 0.
#define CURRENTLY_Z_MOVING_GENERIC 2
/// This one is for falling down open space from movement.
#define CURRENTLY_Z_FALLING_FROM_MOVE 3
/// This one is for going upstairs.
#define CURRENTLY_Z_ASCENDING 4

/// possible bitflag return values of [atom/proc/intercept_zImpact] calls
/// Stops the movable from falling further and crashing on the ground. Example: stairs.
#define FALL_INTERCEPTED (1<<0)
/// Suppresses the "[movable] falls through [old_turf]" message because it'd make little sense in certain contexts like climbing stairs.
#define FALL_NO_MESSAGE (1<<1)
/// Used when the whole intercept_zImpact forvar loop should be stopped. For example: when someone falls into the supermatter and becomes dust.
#define FALL_STOP_INTERCEPTING (1<<2)
/// Used when the grip on a pulled object shouldn't be broken.
#define FALL_RETAIN_PULL (1<<3)

/// Runs check_pulling() by the end of [/atom/movable/proc/zMove] for every movable that's pulling something. Should be kept enabled unless you know what you are doing.
#define ZMOVE_CHECK_PULLING (1<<0)
/// Checks if pulledby is nearby. if not, stop being pulled.
#define ZMOVE_CHECK_PULLEDBY (1<<1)
/// flags for different checks done in [/atom/movable/proc/can_z_move]. Should be self-explainatory.
#define ZMOVE_FALL_CHECKS (1<<2)
#define ZMOVE_CAN_FLY_CHECKS (1<<3)
#define ZMOVE_INCAPACITATED_CHECKS (1<<4)
/// Doesn't call zPassIn() and zPassOut()
#define ZMOVE_IGNORE_OBSTACLES (1<<5)
/// Gives players chat feedbacks if they're unable to move through z levels.
#define ZMOVE_FEEDBACK (1<<6)
/// Whether we check the movable (if it exists) the living mob is buckled on or not.
#define ZMOVE_ALLOW_BUCKLED (1<<7)
/// If the movable is actually ventcrawling vertically.
#define ZMOVE_VENTCRAWLING (1<<8)
/// Includes movables that're either pulled by the source or mobs buckled to it in the list of moving movables.
#define ZMOVE_INCLUDE_PULLED (1<<9)
/// Skips check for whether the moving atom is anchored or not.
#define ZMOVE_ALLOW_ANCHORED (1<<10)

#define ZMOVE_CHECK_PULLS (ZMOVE_CHECK_PULLING|ZMOVE_CHECK_PULLEDBY)

/// Flags used in "Move Upwards" and "Move Downwards" verbs.
#define ZMOVE_FLIGHT_FLAGS (ZMOVE_CAN_FLY_CHECKS|ZMOVE_INCAPACITATED_CHECKS|ZMOVE_CHECK_PULLS|ZMOVE_ALLOW_BUCKLED|ZMOVE_INCLUDE_PULLED)
/// Used when walking upstairs
#define ZMOVE_STAIRS_FLAGS (ZMOVE_CHECK_PULLEDBY|ZMOVE_ALLOW_BUCKLED)
/// Used for falling down open space.
#define ZMOVE_FALL_FLAGS (ZMOVE_FALL_CHECKS|ZMOVE_ALLOW_BUCKLED)

//Diagonal movement is split into two cardinal moves
/// The first step of the diagnonal movement
#define FIRST_DIAG_STEP 1
/// The second step of the diagnonal movement
#define SECOND_DIAG_STEP 2

/// Classic bluespace teleportation, requires a sender but no receiver
#define TELEPORT_CHANNEL_BLUESPACE "bluespace"
/// Quantum-based teleportation, requires both sender and receiver, but is free from normal disruption
#define TELEPORT_CHANNEL_QUANTUM "quantum"
/// Wormhole teleportation, is not disrupted by bluespace fluctuations but tends to be very random or unsafe
#define TELEPORT_CHANNEL_WORMHOLE "wormhole"
/// Magic teleportation, does whatever it wants (unless there's antimagic)
#define TELEPORT_CHANNEL_MAGIC "magic"
/// Cult teleportation, does whatever it wants (unless there's holiness)
#define TELEPORT_CHANNEL_CULT "cult"
/// Eigenstate teleportation, can do most things (that aren't in a teleport-prevented zone)
#define TELEPORT_CHANNEL_EIGENSTATE "eigenstate"
/// Anything else
#define TELEPORT_CHANNEL_FREE "free"

///Return values for moveloop Move()
#define MOVELOOP_FAILURE 0
#define MOVELOOP_SUCCESS 1
#define MOVELOOP_NOT_READY 2

#define NEWTONS *1

#define DEFAULT_INERTIA_SPEED 5
/// Maximum inertia that an object can hold. Used to prevent objects from getting to stupid speeds.
#define INERTIA_FORCE_CAP 25 NEWTONS
/// How much inertia is deducted when a mob has newtonian spacemove capabilities and is not moving in the same direction
#define INERTIA_FORCE_SPACEMOVE_REDUCTION 0.75 NEWTONS
/// How much inertia we must have to not be able to instantly stop after having something to grab
#define INERTIA_FORCE_SPACEMOVE_GRAB 1.5 NEWTONS
/// How much inertia is required for the impacted object to be thrown at the wall
#define INERTIA_FORCE_THROW_FLOOR 10 NEWTONS
/// How much inertia is required past the floor to add 1 strength
#define INERTIA_FORCE_PER_THROW_FORCE 5 NEWTONS
// Results in maximum speed of 1 tile per tick, capped at about 2/3rds of maximum force
#define INERTIA_SPEED_COEF 0.375
