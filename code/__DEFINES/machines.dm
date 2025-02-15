// channel numbers for power
// These are indexes in a list, and indexes for "dynamic" and static channels should be kept contiguous
#define AREA_USAGE_EQUIP 1
#define AREA_USAGE_LIGHT 2
#define AREA_USAGE_ENVIRON 3
#define AREA_USAGE_STATIC_EQUIP 4
#define AREA_USAGE_STATIC_LIGHT 5
#define AREA_USAGE_STATIC_ENVIRON 6
#define AREA_USAGE_APC_CHARGE 7
#define AREA_USAGE_LEN AREA_USAGE_APC_CHARGE // largest idx

/// Index of the first dynamic usage channel
#define AREA_USAGE_DYNAMIC_START AREA_USAGE_EQUIP
/// Index of the last dynamic usage channel
#define AREA_USAGE_DYNAMIC_END AREA_USAGE_ENVIRON

/// Index of the first static usage channel
#define AREA_USAGE_STATIC_START AREA_USAGE_STATIC_EQUIP
/// Index of the last static usage channel
#define AREA_USAGE_STATIC_END AREA_USAGE_STATIC_ENVIRON

#define DYNAMIC_TO_STATIC_CHANNEL(dyn_channel) (dyn_channel + (AREA_USAGE_STATIC_START - AREA_USAGE_DYNAMIC_START))
#define STATIC_TO_DYNAMIC_CHANNEL(static_channel) (static_channel - (AREA_USAGE_STATIC_START - AREA_USAGE_DYNAMIC_START))

//Power use

/// dont use power
#define NO_POWER_USE 0
/// use idle_power_usage i.e. the power needed just to keep the machine on
#define IDLE_POWER_USE 1
/// use active_power_usage i.e. the power the machine consumes to perform a specific task
#define ACTIVE_POWER_USE 2

///Base global power consumption for idling machines
#define BASE_MACHINE_IDLE_CONSUMPTION (100 WATTS)
///Base global power consumption for active machines. The unit is ambiguous (joules or watts) depending on the use case for dynamic users.
#define BASE_MACHINE_ACTIVE_CONSUMPTION (BASE_MACHINE_IDLE_CONSUMPTION * 10)

/// Bitflags for a machine's preferences on when it should start processing. For use with machinery's `processing_flags` var.
#define START_PROCESSING_ON_INIT (1<<0) /// Indicates the machine will automatically start processing right after its `Initialize()` is ran.
#define START_PROCESSING_MANUALLY (1<<1) /// Machines with this flag will not start processing when it's spawned. Use this if you want to manually control when a machine starts processing.

//bitflags for door switches.
#define OPEN (1<<0)
#define IDSCAN (1<<1)
#define BOLTS (1<<2)
#define SHOCK (1<<3)
#define SAFE (1<<4)

//defines to be used with the door's open()/close() procs in order to discriminate what type of open is being done. The door will never open if it's been physically disabled (i.e. welded, sealed, etc.).
/// We should go through the door's normal opening procedure, no overrides.
#define DEFAULT_DOOR_CHECKS 0
/// We're not going through the door's normal opening procedure, we're forcing it open. Can still fail if it's emagged or something. Costs power.
#define FORCING_DOOR_CHECKS 1
/// We are getting this door open if it has not been physically held shut somehow. Play a special sound to signify this level of opening.
#define BYPASS_DOOR_CHECKS 2

//used in design to specify which machine can build it
//Note: More than one of these can be added to a design but imprinter and lathe designs are incompatible.
#define IMPRINTER (1<<0) //For circuits. Uses glass/chemicals.
#define PROTOLATHE (1<<1) //New stuff. Uses various minerals
#define AUTOLATHE (1<<2) //Prints basic designs without research
#define MECHFAB (1<<3) //Remember, objects utilising this flag should have construction_time and construction_cost vars.
#define BIOGENERATOR (1<<4) //Uses biomass
#define LIMBGROWER (1<<5) //Uses synthetic flesh
#define SMELTER (1<<6) //uses various minerals
/// Protolathes for offstation roles. More limited tech tree.
#define AWAY_LATHE (1<<8)
/// Imprinters for offstation roles. More limited tech tree.
#define AWAY_IMPRINTER (1<<9)
/// For wiremod/integrated circuits. Uses various minerals.
#define COMPONENT_PRINTER (1<<10)

#define HYPERTORUS_INACTIVE 0 // No or minimal energy
#define HYPERTORUS_NOMINAL 1 // Normal operation
#define HYPERTORUS_WARNING 2 // Integrity damaged
#define HYPERTORUS_DANGER 3 // Integrity < 50%
#define HYPERTORUS_EMERGENCY 4 // Integrity < 25%
#define HYPERTORUS_MELTING 5 // Pretty obvious.

#define MACHINE_NOT_ELECTRIFIED 0
#define MACHINE_ELECTRIFIED_PERMANENT -1
#define MACHINE_DEFAULT_ELECTRIFY_TIME 30

//mass drivers and related machinery
#define MASSDRIVER_ORDNANCE "ordnancedriver"
#define MASSDRIVER_CHAPEL "chapelgun"
#define MASSDRIVER_DISPOSALS "trash"
#define MASSDRIVER_SHACK "shack"

//orion game states
#define ORION_STATUS_START 0
#define ORION_STATUS_INSTRUCTIONS 1
#define ORION_STATUS_NORMAL 2
#define ORION_STATUS_GAMEOVER 3
#define ORION_STATUS_MARKET 4

//orion delays (how many turns an action costs)
#define ORION_SHORT_DELAY 2
#define ORION_LONG_DELAY 6

//starting orion crew count
#define ORION_STARTING_CREW_COUNT 4

//orion food to fuel / fuel to food conversion rate
#define ORION_TRADE_RATE 5

//and whether you want fuel or food
#define ORION_I_WANT_FUEL 1
#define ORION_I_WANT_FOOD 2

//orion price of buying pioneer
#define ORION_BUY_CREW_PRICE 10

//...and selling one (its less because having less pioneers is actually not that bad)
#define ORION_SELL_CREW_PRICE 7

//defining the magic numbers sent by tgui
#define ORION_BUY_ENGINE_PARTS 1
#define ORION_BUY_ELECTRONICS 2
#define ORION_BUY_HULL_PARTS 3

//orion gaming record (basically how worried it is that you're a deranged gunk gamer)
//game gives up on trying to help you
#define ORION_GAMER_GIVE_UP -2
//game spawns a pamphlet, post report
#define ORION_GAMER_PAMPHLET -1
//game begins to have a chance to warn sec and med
#define ORION_GAMER_REPORT_THRESHOLD 2

/// What's the minimum duration of a syndie bomb (in seconds)
#define SYNDIEBOMB_MIN_TIMER_SECONDS 90

// Camera upgrade bitflags.
#define CAMERA_UPGRADE_XRAY (1<<0)
#define CAMERA_UPGRADE_EMP_PROOF (1<<1)
#define CAMERA_UPGRADE_MOTION (1<<2)

/// Max length of a status line in the status display
#define MAX_STATUS_LINE_LENGTH 40

/// Blank Status Display
#define SD_BLANK 0
/// Shows the emergency shuttle timer
#define SD_EMERGENCY 1
/// Shows an arbitrary message, user-set
#define SD_MESSAGE 2
/// Shows an alert picture (e.g. red alert, radiation, etc.)
#define SD_PICTURE 3
