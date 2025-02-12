//shuttle mode defines
#define SHUTTLE_IDLE "idle"
#define SHUTTLE_IGNITING "igniting"
#define SHUTTLE_RECALL "recalled"
#define SHUTTLE_CALL "called"
#define SHUTTLE_DOCKED "docked"
#define SHUTTLE_STRANDED "stranded"
#define SHUTTLE_DISABLED "disabled"
#define SHUTTLE_ESCAPE "escape"
#define SHUTTLE_ENDGAME "endgame: game over"
#define SHUTTLE_RECHARGING "recharging"
#define SHUTTLE_PREARRIVAL "landing"

#define EMERGENCY_IDLE_OR_RECALLED (SSshuttle.emergency && ((SSshuttle.emergency.mode == SHUTTLE_IDLE) || (SSshuttle.emergency.mode == SHUTTLE_RECALL)))
#define EMERGENCY_ESCAPED_OR_ENDGAMED (SSshuttle.emergency && ((SSshuttle.emergency.mode == SHUTTLE_ESCAPE) || (SSshuttle.emergency.mode == SHUTTLE_ENDGAME)))
#define EMERGENCY_AT_LEAST_DOCKED (SSshuttle.emergency && SSshuttle.emergency.mode != SHUTTLE_IDLE && SSshuttle.emergency.mode != SHUTTLE_RECALL && SSshuttle.emergency.mode != SHUTTLE_CALL)
#define EMERGENCY_PAST_POINT_OF_NO_RETURN ((SSshuttle.emergency && SSshuttle.emergency.mode == SHUTTLE_CALL && !SSshuttle.canRecall()) || EMERGENCY_AT_LEAST_DOCKED)

// Shuttle return values
#define SHUTTLE_CAN_DOCK "can_dock"
#define SHUTTLE_NOT_A_DOCKING_PORT "not a docking port"
#define SHUTTLE_DWIDTH_TOO_LARGE "docking width too large"
#define SHUTTLE_WIDTH_TOO_LARGE "width too large"
#define SHUTTLE_DHEIGHT_TOO_LARGE "docking height too large"
#define SHUTTLE_HEIGHT_TOO_LARGE "height too large"
#define SHUTTLE_ALREADY_DOCKED "we are already docked"
#define SHUTTLE_SOMEONE_ELSE_DOCKED "someone else docked"

//Launching Shuttles to CentCom
#define NOLAUNCH -1
#define UNLAUNCHED 0
/// This shuttle launched to head to end game (or has arrived there), it will not update further
#define ENDGAME_LAUNCHED 1
#define EARLY_LAUNCHED 2
/// "Endgame transit" denotes shuttles which "fly into the sunset" when the round ends, such as the whiteship.
/// These shuttles leave when the main emergency shuttle does but don't dock anywhere (to save space), so this counts as "escaped".
#define ENDGAME_TRANSIT 3

//positive value = cannot purchase
#define SHUTTLEPURCHASE_PURCHASABLE 0 //station can buy a shuttle
#define SHUTTLEPURCHASE_PURCHASED 1 //station has already bought a shuttle, so cannot
#define SHUTTLEPURCHASE_FORCED 2 //station was given a new shuttle through events or other shenanigans

// Ripples, effects that signal a shuttle's arrival
#define SHUTTLE_RIPPLE_TIME 100

#define TRANSIT_REQUEST 1
#define TRANSIT_READY 2

#define SHUTTLE_TRANSIT_BORDER 16

#define PARALLAX_LOOP_TIME 25
#define HYPERSPACE_END_TIME 5

#define HYPERSPACE_WARMUP 1
#define HYPERSPACE_LAUNCH 2
#define HYPERSPACE_END 3

#define CALL_SHUTTLE_REASON_LENGTH 12

//Engine related
#define ENGINE_COEFF_MIN 0.5
#define ENGINE_COEFF_MAX 2
#define ENGINE_DEFAULT_MAXSPEED_ENGINES 5
#define ENGINE_START_TIME 100

// Alert level related
#define ALERT_COEFF_AUTOEVAC_NORMAL 2.5
#define ALERT_COEFF_GREEN 2
#define ALERT_COEFF_BLUE 1
#define ALERT_COEFF_RED 0.5
#define ALERT_COEFF_AUTOEVAC_CRITICAL 0.4
#define ALERT_COEFF_DELTA 0.25

//Docking error flags
#define DOCKING_SUCCESS 0
#define DOCKING_BLOCKED (1<<0)
#define DOCKING_IMMOBILIZED (1<<1)
#define DOCKING_AREA_EMPTY (1<<2)
#define DOCKING_NULL_DESTINATION (1<<3)
#define DOCKING_NULL_SOURCE (1<<4)

//Docking turf movements
#define MOVE_TURF 1
#define MOVE_AREA 2
#define MOVE_CONTENTS 4

//Rotation params
#define ROTATE_DIR 1
#define ROTATE_SMOOTH 2
#define ROTATE_OFFSET 4

#define SHUTTLE_DOCKER_LANDING_CLEAR 1
#define SHUTTLE_DOCKER_BLOCKED_BY_HIDDEN_PORT 2
#define SHUTTLE_DOCKER_BLOCKED 3

//Shuttle defaults
#define SHUTTLE_DEFAULT_SHUTTLE_AREA_TYPE /area/shuttle
#define SHUTTLE_DEFAULT_UNDERLYING_AREA /area/space

/// Shuttle unlocks
// Needs Alien Technology researched.
#define SHUTTLE_UNLOCK_ALIENTECH "abductor"
// Needs bubblegum to die.
#define SHUTTLE_UNLOCK_BUBBLEGUM "bubblegum"
// Needs one to set the holodeck to Medieval Sim.
#define SHUTTLE_UNLOCK_MEDISIM "holodeck"
// Needs a rune to be cleared by a null rod.
#define SHUTTLE_UNLOCK_NARNAR "narnar"
// Needs someone to be polymorphed - Pride Mirror, Magic Mirror, Race Swap, Polymorph Staff/Wand. Badmin Mirror doesn't count, neither does xenobio.
#define SHUTTLE_UNLOCK_WABBAJACK "wabbajack"
// Needs cargo budget to be almost empty to be purchasable.
#define SHUTTLE_UNLOCK_SCRAPHEAP "scrapheap"

//Shuttle Events

///Self destruct if this is returned in process
#define SHUTTLE_EVENT_CLEAR 2

///spawned stuff should float by the window and not hit the shuttle
#define SHUTTLE_EVENT_MISS_SHUTTLE 1 << 0
///spawned stuff should hit the shuttle
#define SHUTTLE_EVENT_HIT_SHUTTLE 1 << 1

// Hijack stages

#define HIJACK_NOT_BEGUN 0
#define HIJACK_STAGE_1 1
#define HIJACK_STAGE_2 2
#define HIJACK_STAGE_3 3
#define HIJACK_STAGE_4 4
#define HIJACK_COMPLETED 5

// Custom shuttle construction errors
#define ORIGIN_NOT_ON_SHUTTLE 1 << 0

// The following two errors occur in mutually exclusive contexts, so they can share the same bitflag
#define TOO_MANY_SHUTTLES 1 << 1
#define FRAME_NOT_ADJACENT_TO_LINKED_SHUTTLE 1 << 1

#define ABOVE_MAX_SHUTTLE_SIZE 1 << 2
#define CUSTOM_AREA_NOT_COMPLETELY_CONTAINED 1 << 3
#define INTERSECTS_NON_WHITELISTED_AREA 1 << 4

// Custom shuttle engine defines
#define CUSTOM_ENGINE_COEFF_MIN 0.5
#define CUSTOM_ENGINE_COEFF_MAX 10

#define CUSTOM_ENGINE_POWER_MULTIPLIER 25
#define CUSTOM_ENGINE_POWER_TURF_COUNT_OFFSET 5
