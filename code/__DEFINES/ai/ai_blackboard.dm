
//Generic BB keys

#define BB_CURRENT_MIN_MOVE_DISTANCE "min_move_distance"
///time until we should next eat, set by the generic hunger subtree
#define BB_NEXT_HUNGRY "BB_NEXT_HUNGRY"
///what we're going to eat next
#define BB_FOOD_TARGET "bb_food_target"
///How close a mob must be for us to select it as a target, if that is less than how far we can maintain it as a target
#define BB_AGGRO_RANGE "BB_aggro_range"
///are we hungry? determined by the udder component
#define BB_CHECK_HUNGRY "BB_check_hungry"
///are we ready to breed?
#define BB_BREED_READY "BB_breed_ready"
///maximum kids we can have
#define BB_MAX_CHILDREN "BB_max_children"
///our current happiness level
#define BB_BASIC_HAPPINESS "BB_basic_happiness"
///can this mob heal?
#define BB_BASIC_MOB_HEALER "BB_basic_mob_healer"

///the owner we will try to play with
#define BB_OWNER_TARGET "BB_owner_target"
///the list of interactions we can have with the owner
#define BB_INTERACTIONS_WITH_OWNER "BB_interactions_with_owner"

///The trait checked by ai_behavior/find_potential_targets/prioritize_trait to return a target with a trait over the rest.
#define BB_TARGET_PRIORITY_TRAIT "target_priority_trait"

/// Store a single or list of emotes at this key
#define BB_EMOTE_KEY "BB_emotes"
/// Chance to perform an emote per second
#define BB_EMOTE_CHANCE "BB_EMOTE_CHANCE"

/// Something the mob will say when calling reinforcements
#define BB_REINFORCEMENTS_SAY "BB_reinforcements_say"
/// Something the mob will remote when calling reinforcements
#define BB_REINFORCEMENTS_EMOTE "BB_reinforcements_emote"

///Turf we want a mob to move to
#define BB_TRAVEL_DESTINATION "BB_travel_destination"

///song instrument blackboard, set by instrument subtrees
#define BB_SONG_INSTRUMENT "BB_SONG_INSTRUMENT"
///song lines blackboard, set by default on controllers
#define BB_SONG_LINES "song_lines"

///bane ai used by example script
#define BB_BANE_BATMAN "BB_bane_batman"
//yep that's it

/// Are we a panicking goose?
#define BB_GOOSE_PANICKED "BB_goose_panicked"
/// Are we a panicking goose?
#define BB_GOOSE_VOMIT_CHANCE "BB_goose_vomit_chance"

//Hunting BB keys
///key that holds our current hunting target
#define BB_CURRENT_HUNTING_TARGET "BB_current_hunting_target"
///key that holds our less priority hunting target
#define BB_LOW_PRIORITY_HUNTING_TARGET "BB_low_priority_hunting_target"
///key that holds the cooldown for our hunting subtree
#define BB_HUNTING_COOLDOWN(type) "BB_HUNTING_COOLDOWN_[type]"
///Basic Mob Keys

///Targeting subtrees
#define BB_BASIC_MOB_CURRENT_TARGET "BB_basic_current_target"
#define BB_BASIC_MOB_CURRENT_TARGET_HIDING_LOCATION "BB_basic_current_target_hiding_location"
#define BB_TARGETING_STRATEGY "targeting_strategy"
///some behaviors that check current_target also set this on deep crit mobs
#define BB_BASIC_MOB_EXECUTION_TARGET "BB_basic_execution_target"
///Blackboard key for a whitelist typecache of "things we can target while trying to move"
#define BB_OBSTACLE_TARGETING_WHITELIST "BB_targeting_whitelist"
/// Key for the minimum status at which we want to target mobs (does not need to be specified if CONSCIOUS)
#define BB_TARGET_MINIMUM_STAT "BB_target_minimum_stat"
/// Flag for whether to target only wounded mobs
#define BB_TARGET_WOUNDED_ONLY "BB_target_wounded_only"
/// What typepath the holding object targeting strategy should look for
#define BB_TARGET_HELD_ITEM "BB_target_held_item"
/// How likely is this mob to move when idle per tick?
#define BB_BASIC_MOB_IDLE_WALK_CHANCE "BB_basic_idle_walk_chance"

/// Minimum range to keep target within
#define BB_RANGED_SKIRMISH_MIN_DISTANCE "BB_ranged_skirmish_min_distance"
/// Maximum range to keep target within
#define BB_RANGED_SKIRMISH_MAX_DISTANCE "BB_ranged_skirmish_max_distance"

/// Blackboard key storing how long your targeting strategy has held a particular target
#define BB_BASIC_MOB_HAS_TARGET_TIME "BB_basic_mob_has_target_time"

///Targeting keys for something to run away from, if you need to store this separately from current target
#define BB_BASIC_MOB_FLEE_TARGET "BB_basic_flee_target"
#define BB_BASIC_MOB_FLEE_TARGET_HIDING_LOCATION "BB_basic_flee_target_hiding_location"
#define BB_FLEE_TARGETING_STRATEGY "flee_targeting_strategy"
#define BB_BASIC_MOB_FLEE_DISTANCE "BB_basic_flee_distance"
#define DEFAULT_BASIC_FLEE_DISTANCE 9

/// Generic key for a non-specific targeted action
#define BB_TARGETED_ACTION "BB_TARGETED_action"
/// Generic key for a non-specific action
#define BB_GENERIC_ACTION "BB_generic_action"

/// Generic key for a shapeshifting action
#define BB_SHAPESHIFT_ACTION "BB_shapeshift_action"

///How long have we spent with no target?
#define BB_TARGETLESS_TIME "BB_targetless_time"

///Tipped blackboards
///Bool that means a basic mob will start reacting to being tipped in its planning
#define BB_BASIC_MOB_TIP_REACTING "BB_basic_tip_reacting"
///the motherfucker who tipped us
#define BB_BASIC_MOB_TIPPER "BB_basic_tip_tipper"

/// Is there something that scared us into being stationary? If so, hold the reference here
#define BB_STATIONARY_CAUSE "BB_thing_that_made_us_stationary"
///How long should we remain stationary for?
#define BB_STATIONARY_SECONDS "BB_stationary_time_in_seconds"
///Should we move towards the target that triggered us to be stationary?
#define BB_STATIONARY_MOVE_TO_TARGET "BB_stationary_move_to_target"
/// What targets will trigger us to be stationary? Must be a list.
#define BB_STATIONARY_TARGETS "BB_stationary_targets"
/// How often can we get spooked by a target?
#define BB_STATIONARY_COOLDOWN "BB_stationary_cooldown"

///List of mobs who have damaged us
#define BB_BASIC_MOB_RETALIATE_LIST "BB_basic_mob_shitlist"

/// Chance to randomly acquire a new target
#define BB_RANDOM_AGGRO_CHANCE "BB_random_aggro_chance"
/// Chance to randomly drop all of our targets
#define BB_RANDOM_DEAGGRO_CHANCE "BB_random_deaggro_chance"

/// Flag to set on if you want your mob to STOP running away
#define BB_BASIC_MOB_STOP_FLEEING "BB_basic_stop_fleeing"

///list of foods this mob likes
#define BB_BASIC_FOODS "BB_basic_foods"

///key holding any food we've found
#define BB_TARGET_FOOD "BB_TARGET_FOOD"

///key holding emotes we play after eating
#define BB_EAT_EMOTES "BB_eat_emotes"

///key holding the next time we eat
#define BB_NEXT_FOOD_EAT "BB_next_food_eat"

///key holding our eating cooldown
#define BB_EAT_FOOD_COOLDOWN "BB_eat_food_cooldown"

/// Blackboard key for a held item
#define BB_SIMPLE_CARRY_ITEM "BB_SIMPLE_CARRY_ITEM"

///key holding a range to look for stuff in
#define BB_SEARCH_RANGE "BB_search_range"

///Mob the MOD is trying to attach to
#define BB_MOD_TARGET "BB_mod_target"
///The implant the AI was created from
#define BB_MOD_IMPLANT "BB_mod_implant"
///Range for a MOD AI controller.
#define MOD_AI_RANGE 200

///Only target mobs with these traits
#define BB_TARGET_ONLY_WITH_TRAITS "BB_target_only_with_traits"

///should we skip the faction check for the targeting strategy?
#define BB_ALWAYS_IGNORE_FACTION "BB_always_ignore_factions"
///are we in some kind of temporary state of ignoring factions when targeting? can result in volatile results if multiple behaviours touch this
#define BB_TEMPORARILY_IGNORE_FACTION "BB_temporarily_ignore_factions"

///currently only used by clowns, a list of what can the mob speak randomly
#define BB_BASIC_MOB_SPEAK_LINES "BB_speech_lines"
#define BB_EMOTE_SAY "emote_say"
#define BB_EMOTE_HEAR "emote_hear"
#define BB_EMOTE_SEE "emote_see"
#define BB_EMOTE_SOUND "emote_sound"
#define BB_SPEAK_CHANCE "emote_chance"

/// A target that has called this mob for reinforcements
#define BB_BASIC_MOB_REINFORCEMENT_TARGET "BB_basic_mob_reinforcement_target"
/// The next time at which this mob can call for reinforcements
#define BB_BASIC_MOB_REINFORCEMENTS_COOLDOWN "BB_basic_mob_reinforcements_cooldown"

/// the direction we started when executing stare at things
#define BB_STARTING_DIRECTION "BB_startdir"

///Text we display when we befriend someone
#define BB_FRIENDLY_MESSAGE "friendly_message"

//fishing!

///our fishing target
#define BB_FISHING_TARGET "BB_fishing_target"

///key holding the list of things we are able to fish from
#define BB_FISHABLE_LIST "BB_fishable_list"

///key holding our cooldown between fishing attempts
#define BB_FISHING_COOLDOWN "BB_fishing_cooldown"

///key that holds the next time we will start fishing
#define BB_FISHING_TIMER "BB_fishing_timer"

///are we ONLY allowed to fish when we're hungry?
#define BB_ONLY_FISH_WHILE_HUNGRY "BB_only_fish_while_hungry"

///drillable ice we can make holes in
#define BB_DRILLABLE_ICE "BB_drillable_ice"


//emotions we displays depending on our happiness
///emotions we display when happy
#define BB_HAPPY_EMOTIONS "happy_emotions"
///emotions we display when neutral
#define BB_MODERATE_EMOTIONS "moderate_emotions"
///emotions we display when depressed
#define BB_SAD_EMOTIONS "sad_emotions"

// Keys used by one and only one behavior
// Used to hold state without making bigass lists
/// For /datum/ai_behavior/find_potential_targets, what if any field are we using currently
#define BB_FIND_TARGETS_FIELD(type) "bb_find_targets_field_[type]"


