/// from base of /datum/wires/proc/cut : (wire)
#define COMSIG_CUT_WIRE(wire) "cut_wire [wire]"
#define COMSIG_MEND_WIRE(wire) "mend_wire [wire]"

/// from base of /datum/wires/proc/on_pulse : (wire, mob/user)
#define COMSIG_PULSE_WIRE "pulse_wire"

// Directionality of wire pulses

/// The wires interact with their holder when pulsed
#define WIRES_INPUT (1<<0)
/// The wires have a reason to toggle whether attached assemblies are armed
#define WIRES_TOGGLE_ARMED (1<<1)
/// The wires only want to activate assemblies that do something other than (dis)arming themselves
#define WIRES_FUNCTIONAL_OUTPUT (1<<2)
/// The holder can both pulse its wires and be affected by its wires getting pulsed
#define WIRES_ALL (WIRES_INPUT | WIRES_TOGGLE_ARMED | WIRES_FUNCTIONAL_OUTPUT)

/// The assembly can pulse a wire it is attached to
#define ASSEMBLY_INPUT (1<<0)
/// The assembly toggles whether it will pulse the attached wire when it is pulsed by the attached wire
#define ASSEMBLY_TOGGLE_ARMED (1<<1)
/// The assembly does something other than just (dis)arming itself when it is pulsed by the wire it is attached to
#define ASSEMBLY_FUNCTIONAL_OUTPUT (1<<2)
/// The assembly can both pulse the wire it is attached to, and (dis)arms itself when pulsed by the wire
#define ASSEMBLY_TOGGLEABLE_INPUT (ASSEMBLY_INPUT | ASSEMBLY_TOGGLE_ARMED)
#define ASSEMBLY_ALL (ASSEMBLY_TOGGLEABLE_INPUT | ASSEMBLY_FUNCTIONAL_OUTPUT)

//retvals for attempt_wires_interaction
#define WIRE_INTERACTION_FAIL 0
#define WIRE_INTERACTION_SUCCESSFUL 1
#define WIRE_INTERACTION_BLOCK 2 //don't do anything else rather than open wires and whatever else.

#define WIRE_ACCEPT "Scan Success"
#define WIRE_ACTIVATE "Activate"
#define WIRE_LAUNCH "Launch"
#define WIRE_SAFETIES "Safeties"
#define WIRE_AGELIMIT "Age Limit"
#define WIRE_AI "AI Connection"
#define WIRE_ALARM "Alarm"
#define WIRE_AVOIDANCE "Avoidance"
#define WIRE_BACKUP1 "Auxiliary Power 1"
#define WIRE_BACKUP2 "Auxiliary Power 2"
#define WIRE_BEACON "Beacon"
#define WIRE_BOLTLIGHT "Bolt Lights"
#define WIRE_BOLTS "Bolts"
#define WIRE_BOOM "Boom Wire 1"
#define WIRE_BOOM2 "Boom Wire 2"
#define WIRE_CAMERA "Camera"
#define WIRE_CONTRABAND "Contraband"
#define WIRE_DELAY "Delay"
#define WIRE_DENY "Scan Fail"
#define WIRE_DISABLE "Disable"
#define WIRE_DISARM "Disarm"
#define	WIRE_ON "On"
#define	WIRE_DROP "Drop"
#define	WIRE_ITEM_TYPE "Item Type"
#define	WIRE_CHANGE_MODE "Change Mode"
#define	WIRE_ONE_PRIORITY_BUTTON "One Priority Button"
#define	WIRE_THROW_RANGE "Throw Range"
#define WIRE_DUD_PREFIX "__dud"
#define WIRE_HACK "Hack"
#define WIRE_IDSCAN "ID Scan"
#define WIRE_INTERFACE "Interface"
#define WIRE_LAWSYNC "AI Law Synchronization"
#define WIRE_LIGHT "Lights"
#define WIRE_LIMIT "Limiter"
#define WIRE_LOADCHECK "Load Check"
#define WIRE_LOCKDOWN "Lockdown"
#define WIRE_MODE_SELECT "Mode Select"
#define WIRE_MOTOR1 "Motor 1"
#define WIRE_MOTOR2 "Motor 2"
#define WIRE_OPEN "Open"
#define WIRE_PANIC "Panic Siphon"
#define WIRE_POWER "Power"
#define WIRE_POWER1 "Main Power 1"
#define WIRE_POWER2 "Main Power 2"
#define WIRE_PRIZEVEND "Emergency Prize Vend"
#define WIRE_PROCEED "Proceed"
#define WIRE_RESET_MODEL "Reset Model"
#define WIRE_RESETOWNER "Reset Owner"
#define WIRE_UNRESTRICTED_EXIT "Unrestricted Exit"
#define WIRE_RX "Receive"
#define WIRE_SAFETY "Safety"
#define WIRE_SHOCK "High Voltage Ground"
#define WIRE_SIGNAL "Signal"
#define WIRE_SPEAKER "Speaker"
#define WIRE_STRENGTH "Strength"
#define WIRE_THROW "Throw"
#define WIRE_TIMING "Timing"
#define WIRE_TX "Transmit"
#define WIRE_UNBOLT "Unbolt"
#define WIRE_ZAP "High Voltage Circuit"
#define WIRE_ZAP1 "High Voltage Circuit 1"
#define WIRE_ZAP2 "High Voltage Circuit 2"
#define WIRE_OVERCLOCK "Overclock"
#define WIRE_EQUIPMENT "Equipment"
#define WIRE_ENVIRONMENT "Environment"

// Wire states for the AI
#define AI_WIRE_NORMAL 0
#define AI_WIRE_DISABLED 1
#define AI_WIRE_HACKED 2
#define AI_WIRE_DISABLED_HACKED -1

#define MAX_WIRE_COUNT 17
