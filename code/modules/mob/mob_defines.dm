/**
 * The mob, usually meant to be a creature of some type
 *
 * Has a client attached that is a living person (most of the time), although I have to admit
 * sometimes it's hard to tell they're sentient
 *
 * Has a lot of the creature game world logic, such as health etc
 */
/mob
	density = TRUE
	layer = MOB_LAYER
	animate_movement = SLIDE_STEPS
	hud_possible = list(ANTAG_HUD)
	pressure_resistance = 8
	mouse_drag_pointer = MOUSE_ACTIVE_POINTER
	throwforce = 10
	blocks_emissive = EMISSIVE_BLOCK_GENERIC
	pass_flags_self = PASSMOB
	// we never want to hide a turf because it's not lit
	// We can rely on the lighting plane to handle that for us
	see_in_dark = 1e6
	// A list of factions that this mob is currently in, for hostile mob targeting, amongst other things
	faction = list(FACTION_NEUTRAL)
	/// The current client inhabiting this mob. Managed by login/logout
	/// This exists so we can do cleanup in logout for occasions where a client was transfere rather then destroyed
	/// We need to do this because the mob on logout never actually has a reference to client
	/// We also need to clear this var/do other cleanup in client/Destroy, since that happens before logout
	/// HHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHH
	var/client/canon_client
	/// It's like a client, but persists! Persistent clients will stick to a mob until the client in question is logged into a different mob.
	var/datum/persistent_client/persistent_client

	var/shift_to_open_context_menu = TRUE

	/// Percentage of how much rgb to max the lighting plane at
	/// This lets us brighten it without washing out color
	/// Scale from 0-100, reset off update_sight()
	var/lighting_cutoff = LIGHTING_CUTOFF_VISIBLE
	// Individual color max for red, we can use this to color darkness without tinting the light
	var/lighting_cutoff_red = 0
	// Individual color max for green, we can use this to color darkness without tinting the light
	var/lighting_cutoff_green = 0
	// Individual color max for blue, we can use this to color darkness without tinting the light
	var/lighting_cutoff_blue = 0
	/// A list of red, green and blue cutoffs
	/// This is what actually gets applied to the mob, it's modified by things like glasses
	var/list/lighting_color_cutoffs = null
	var/datum/mind/mind
	var/static/next_mob_id = 0

	/// List of movement speed modifiers applying to this mob
	var/list/movespeed_modification //Lazy list, see mob_movespeed.dm
	/// List of movement speed modifiers ignored by this mob. List -> List (id) -> List (sources)
	var/list/movespeed_mod_immunities //Lazy list, see mob_movespeed.dm
	/// The calculated mob speed slowdown based on the modifiers list
	var/cached_multiplicative_slowdown
	/// List of action speed modifiers applying to this mob
	var/list/actionspeed_modification //Lazy list, see mob_movespeed.dm
	/// List of action speed modifiers ignored by this mob. List -> List (id) -> List (sources)
	var/list/actionspeed_mod_immunities //Lazy list, see mob_movespeed.dm
	/// The calculated mob action speed slowdown based on the modifiers list
	var/cached_multiplicative_actions_slowdown
	/// List of action hud items the user has
	var/list/datum/action/actions
	///Cursor icon used when holding shift over things
	var/examine_cursor_icon = 'icons/effects/mouse_pointers/examine_pointer.dmi'

	/// Mob bitflags
	var/mob_flags = NONE

	/// Whether a mob is alive or dead. TODO: Move this to living - Nodrak (2019, still here)
	var/stat = CONSCIOUS

	/**
	 * Whether and how a mob is incapacitated
	 *
	 * Normally being restrained, agressively grabbed, or in stasis counts as incapacitated
	 * unless there is a flag being used to check if it's ignored
	 *
	 * * bitflags: (see code/__DEFINES/status_effects.dm)
	 * * INCAPABLE_RESTRAINTS - if our mob is in a restraint (handcuffs)
	 * * INCAPABLE_STASIS - if our mob is in stasis (stasis bed, etc.)
	 * * INCAPABLE_GRAB - if our mob is being agressively grabbed
	 *
	**/
	VAR_FINAL/incapacitated = NONE

	/* A bunch of this stuff really needs to go under their own defines instead of being globally attached to mob.
	A variable should only be globally attached to turfs/objects/whatever, when it is in fact needed as such.
	The current method unnecessarily clusters up the variable list, especially for humans (although rearranging won't really clean it up a lot but the difference will be noticable for other mobs).
	I'll make some notes on where certain variable defines should probably go.
	Changing this around would probably require a good look-over the pre-existing code.
	*/

	/// The zone this mob is currently targeting
	var/zone_selected = BODY_ZONE_CHEST

	var/computer_id = null
	var/list/logging = list()

	/// Tick time the mob can next move
	var/next_move = null

	/// What is the mobs real name (name is overridden for disguises etc)
	var/real_name = null


	/// Default body temperature
	var/bodytemperature = BODYTEMP_NORMAL //310.15K / 98.6F
	/// Our body temperatue as of the last process, prevents pointless work when handling alerts
	var/old_bodytemperature = 0

	/// Hunger level of the mob
	var/nutrition = NUTRITION_LEVEL_START_MIN // randomised in Initialize
	/// Satiation level of the mob
	var/satiety = 0//Carbon

	/// How many ticks this mob has been over reating
	var/overeatduration = 0 // How long this guy is overeating //Carbon

	/// The last known IP of the client who was in this mob
	var/lastKnownIP = null

	/// movable atom we are buckled to
	var/atom/movable/buckled = null//Living

	//Hands
	///What hand is the active hand
	var/active_hand_index = 1
	/**
	  * list of items held in hands
	  *
	  * len = number of hands, eg: 2 nulls is 2 empty hands, 1 item and 1 null is 1 full hand
	  * and 1 empty hand.
	  *
	  * NB: contains nulls!
	  *
	  * `held_items[active_hand_index]` is the actively held item, but please use
	  * [get_active_held_item()][/mob/proc/get_active_held_item] instead, because OOP
	  */
	var/list/held_items = list()

	//HUD things

	/// Storage component (for mob inventory)
	var/datum/storage/active_storage
	/// Active hud
	var/datum/hud/hud_used = null

	/// Is the mob throw intent on
	var/throw_mode = THROW_MODE_DISABLED

	/// What job does this mob have
	var/job = null//Living

	/// bitflags defining which status effects can be inflicted (replaces canknockdown, canstun, etc)
	var/status_flags = CANSTUN|CANKNOCKDOWN|CANUNCONSCIOUS|CANPUSH

	///Calls relay_move() to whatever this is set to when the mob tries to move
	var/atom/movable/remote_control

	///the current turf being examined in the stat panel
	var/turf/listed_turf = null

	///The list of people observing this mob.
	var/list/observers = null

	///List of progress bars this mob is currently seeing for actions
	var/list/progressbars = null //for stacking do_after bars

	///For storing what do_after's someone has, key = string, value = amount of interactions of that type happening.
	var/list/do_afters

	///Allows a datum to intercept all click calls this mob is the source of
	var/datum/click_intercept

	///The z level this mob is currently registered in
	var/registered_z = null

	var/memory_throttle_time = 0

	/// Contains [/atom/movable/screen/alert] only.
	///
	/// On [/mob] so clientless mobs will throw alerts properly.
	var/list/alerts = list()
	var/list/screens = list()
	var/list/client_colours = list()
	var/hud_type = /datum/hud

	var/datum/focus //What receives our keyboard inputs. src by default

	/// Used for tracking last uses of emotes for cooldown purposes
	var/list/emotes_used

	///Whether the mob is updating glide size when movespeed updates or not
	var/updating_glide_size = TRUE

	///Override for sound_environments. If this is set the user will always hear a specific type of reverb (Instead of the area defined reverb)
	var/sound_environment_override = SOUND_ENVIRONMENT_NONE

	/// A mock client, provided by tests and friends
	var/datum/client_interface/mock_client

	var/interaction_range = 0 //how far a mob has to be to interact with something without caring about obsctruction, defaulted to 0 tiles

	///the icon currently used for the typing indicator's bubble
	var/active_typing_indicator
	///the icon currently used for the thinking indicator's bubble
	var/active_thinking_indicator

	/// A ref of the area we're taking our ambient loop from.
	var/area/ambience_tracked_area
