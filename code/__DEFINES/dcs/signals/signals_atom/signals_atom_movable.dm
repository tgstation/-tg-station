// Atom movable signals. Format:
// When the signal is called: (signal arguments)
// All signals send the source datum of the signal as the first argument

///from base of atom/movable/Moved(): (/atom)
#define COMSIG_MOVABLE_PRE_MOVE "movable_pre_move"
	#define COMPONENT_MOVABLE_BLOCK_PRE_MOVE (1<<0)
///from base of atom/movable/Moved(): (atom/old_loc, dir, forced, list/old_locs)
#define COMSIG_MOVABLE_MOVED "movable_moved"
///from base of atom/movable/Cross(): (/atom/movable)
#define COMSIG_MOVABLE_CROSS "movable_cross"
	#define COMPONENT_BLOCK_CROSS (1<<0)
///from base of atom/movable/Move(): (/atom/movable)
#define COMSIG_MOVABLE_CROSS_OVER "movable_cross_am"
///from base of atom/movable/Bump(): (/atom)
#define COMSIG_MOVABLE_BUMP "movable_bump"
	#define COMPONENT_INTERCEPT_BUMPED (1<<0)
///from datum/component/drift/apply_initial_visuals(): ()
#define COMSIG_MOVABLE_DRIFT_VISUAL_ATTEMPT "movable_drift_visual_attempt"
	#define DRIFT_VISUAL_FAILED (1<<0)
///from datum/component/drift/allow_final_movement(): ()
#define COMSIG_MOVABLE_DRIFT_BLOCK_INPUT "movable_drift_block_input"
	#define DRIFT_ALLOW_INPUT (1<<0)
///from base of atom/movable/throw_impact(): (/atom/hit_atom, /datum/thrownthing/throwingdatum)
#define COMSIG_MOVABLE_PRE_IMPACT "movable_pre_impact"
	#define COMPONENT_MOVABLE_IMPACT_FLIP_HITPUSH (1<<0) //if true, flip if the impact will push what it hits
	#define COMPONENT_MOVABLE_IMPACT_NEVERMIND (1<<1) //return true if you destroyed whatever it was you're impacting and there won't be anything for hitby() to run on
///from base of atom/movable/throw_impact() after confirming a hit: (/atom/hit_atom, /datum/thrownthing/throwingdatum)
#define COMSIG_MOVABLE_IMPACT "movable_impact"
///from base of mob/living/hitby(): (mob/living/target, hit_zone, blocked, datum/thrownthing/throwingdatum)
#define COMSIG_MOVABLE_IMPACT_ZONE "item_impact_zone"
	#define MOVABLE_IMPACT_ZONE_OVERRIDE (1<<0)
///from /atom/movable/proc/buckle_mob(): (mob/living/M, force, check_loc, buckle_mob_flags)
#define COMSIG_MOVABLE_PREBUCKLE "prebuckle" // this is the last chance to interrupt and block a buckle before it finishes
	#define COMPONENT_BLOCK_BUCKLE (1<<0)
///from base of atom/movable/buckle_mob(): (mob, force)
#define COMSIG_MOVABLE_BUCKLE "buckle"
///from base of atom/movable/unbuckle_mob(): (mob, force)
#define COMSIG_MOVABLE_UNBUCKLE "unbuckle"
///from /atom/movable/proc/buckle_mob(): (buckled_movable)
#define COMSIG_MOB_BUCKLED "mob_buckle"
///from /atom/movable/proc/unbuckle_mob(): (buckled_movable)
#define COMSIG_MOB_UNBUCKLED "mob_unbuckle"
///from /obj/vehicle/proc/driver_move, caught by the riding component to check and execute the driver trying to drive the vehicle
#define COMSIG_RIDDEN_DRIVER_MOVE "driver_move"
	#define COMPONENT_DRIVER_BLOCK_MOVE (1<<0)
///from base of atom/movable/throw_at(): (list/args)
#define COMSIG_MOVABLE_PRE_THROW "movable_pre_throw"
	#define COMPONENT_CANCEL_THROW (1<<0)
///from base of atom/movable/throw_at(): (datum/thrownthing, spin)
#define COMSIG_MOVABLE_POST_THROW "movable_post_throw"
///from base of datum/thrownthing/finalize(): (obj/thrown_object, datum/thrownthing) used for when a throw is finished
#define COMSIG_MOVABLE_THROW_LANDED "movable_throw_landed"
///from base of atom/movable/on_changed_z_level(): (turf/old_turf, turf/new_turf, same_z_layer)
#define COMSIG_MOVABLE_Z_CHANGED "movable_ztransit"
/// from /atom/movable/can_z_move(): (turf/start, turf/destination)
#define COMSIG_CAN_Z_MOVE "movable_can_z_move"
	/// Return to block z movement
	#define COMPONENT_CANT_Z_MOVE (1<<0)
///called before hearing a message from atom/movable/Hear():
#define COMSIG_MOVABLE_PRE_HEAR "movable_pre_hear"
	///cancel hearing the message because we're doing something else presumably
	#define COMSIG_MOVABLE_CANCEL_HEARING (1<<0)
///from base of atom/movable/Hear(): (proc args list(message, atom/movable/speaker, message_language, raw_message, radio_freq, list/spans, list/message_mods = list(), message_range))
#define COMSIG_MOVABLE_HEAR "movable_hear"
	#define HEARING_MESSAGE 1
	#define HEARING_SPEAKER 2
	#define HEARING_LANGUAGE 3
	#define HEARING_RAW_MESSAGE 4
	#define HEARING_RADIO_FREQ 5
	#define HEARING_SPANS 6
	#define HEARING_MESSAGE_MODE 7
	#define HEARING_RANGE 8

///called when the movable is added to a disposal holder object for disposal movement: (obj/structure/disposalholder/holder, obj/machinery/disposal/source)
#define COMSIG_MOVABLE_DISPOSING "movable_disposing"
// called when movable is expelled from a disposal pipe, bin or outlet on obj/pipe_eject: (direction)
#define COMSIG_MOVABLE_PIPE_EJECTING "movable_pipe_ejecting"
///called when the movable successfully has its anchored var changed, from base atom/movable/set_anchored(): (value)
#define COMSIG_MOVABLE_SET_ANCHORED "movable_set_anchored"
///from base of atom/movable/setGrabState(): (newstate)
#define COMSIG_MOVABLE_SET_GRAB_STATE "living_set_grab_state"
///called when the movable's glide size is updated: (new_glide_size)
#define COMSIG_MOVABLE_UPDATE_GLIDE_SIZE "movable_glide_size"
///Called when a movable is hit by a plunger in layer mode, from /obj/item/plunger/attack_atom()
#define COMSIG_MOVABLE_CHANGE_DUCT_LAYER "movable_change_duct_layer"
///Called before a movable is being teleported from `check_teleport_valid()`: (destination, channel)
#define COMSIG_MOVABLE_TELEPORTING "movable_teleporting"
///Called when a movable is being teleported from `do_teleport()`: (destination, channel)
#define COMSIG_MOVABLE_TELEPORTED "movable_teleported"
///Called after a movable is teleported from `do_teleport()`: ()
#define COMSIG_MOVABLE_POST_TELEPORT "movable_post_teleport"
/// from /mob/living/can_z_move, sent to whatever the mob is buckled to. Only ridable movables should be ridden up or down btw.
#define COMSIG_BUCKLED_CAN_Z_MOVE "ridden_pre_can_z_move"
	#define COMPONENT_RIDDEN_STOP_Z_MOVE 1
	#define COMPONENT_RIDDEN_ALLOW_Z_MOVE 2
/// from base of atom/movable/Process_Spacemove(): (movement_dir, continuous_move)
#define COMSIG_MOVABLE_SPACEMOVE "spacemove"
	#define COMSIG_MOVABLE_STOP_SPACEMOVE (1<<0)

/// Sent from /obj/item/radio/talk_into(): (obj/item/radio/used_radio)
#define COMSIG_MOVABLE_USING_RADIO "movable_radio"
	/// Return to prevent the movable from talking into the radio.
	#define COMPONENT_CANNOT_USE_RADIO (1<<0)

/// Sent from /atom/movable/proc/say_quote() after say verb is chosen and before spans are applied.
#define COMSIG_MOVABLE_SAY_QUOTE "movable_say_quote"
	// Used to access COMSIG_MOVABLE_SAY_QUOTE argslist
	/// The index of args that corresponds to the actual message
	#define MOVABLE_SAY_QUOTE_MESSAGE 1
	#define MOVABLE_SAY_QUOTE_MESSAGE_SPANS 2
	#define MOVABLE_SAY_QUOTE_MESSAGE_MODS 3

/// Sent from /atom/movable/proc/compose_message() after the name part: (list/stored_name, visible_name)
#define COMSIG_MOVABLE_MESSAGE_GET_NAME_PART "movable_message_get_name_part"
	///The index of the name part
	#define NAME_PART_INDEX 1

/// From /datum/element/immerse/proc/add_submerge_overlay(): (visual_overlay)
#define COMSIG_MOVABLE_EDIT_UNIQUE_IMMERSE_OVERLAY "movable_edit_unique_submerge_overlay"
/// From base of area/Exited(): (area/left, direction)
#define COMSIG_MOVABLE_EXITED_AREA "movable_exited_area"

///from base of /datum/component/splat/splat: (hit_atom)
#define COMSIG_MOVABLE_SPLAT "movable_splat"

///from base of /atom/movable/point_at: (atom/A, obj/effect/temp_visual/point/point)
#define COMSIG_MOVABLE_POINTED "movable_pointed"

///From /datum/component/aquarium/get_content_beauty: (beauty_holder)
#define COMSIG_MOVABLE_GET_AQUARIUM_BEAUTY "movable_ge_aquarium_beauty"

/// Sent to movables when they are being stolen by a spy: (mob/living/spy, datum/spy_bounty/bounty)
#define COMSIG_MOVABLE_SPY_STEALING "movable_spy_stealing"
/// Called when something is pushed by a living mob bumping it: (mob/living/pusher, push force)
#define COMSIG_MOVABLE_BUMP_PUSHED "movable_bump_pushed"
	/// Stop it from moving
	#define COMPONENT_NO_PUSH (1<<0)

