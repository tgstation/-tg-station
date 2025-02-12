/**
 * Client datum
 *
 * A datum that is created whenever a user joins a BYOND world, one will exist for every active connected
 * player
 *
 * when they first connect, this client object is created and [/client/New] is called
 *
 * When they disconnect, this client object is deleted and [/client/Del] is called
 *
 * All client topic calls go through [/client/Topic] first, so a lot of our specialised
 * topic handling starts here
 */
/client

	/**
	 * This line makes clients parent type be a datum
	 *
	 * By default in byond if you define a proc on datums, that proc will exist on nearly every single type
	 * from icons to images to atoms to mobs to objs to turfs to areas, it won't however, appear on client
	 *
	 * instead by default they act like their own independent type so while you can do isdatum(icon)
	 * and have it return true, you can't do isdatum(client), it will always return false.
	 *
	 * This makes writing oo code hard, when you have to consider this extra special case
	 *
	 * This line prevents that, and has never appeared to cause any ill effects, while saving us an extra
	 * pain to think about
	 *
	 * This line is widely considered black fucking magic, and the fact it works is a puzzle to everyone
	 * involved, including the current engine developer, lummox
	 *
	 * If you are a future developer and the engine source is now available and you can explain why this
	 * is the way it is, please do update this comment
	 */
	parent_type = /datum
		////////////////
		//ADMIN THINGS//
		////////////////
	/// hides the byond verb panel as we use our own custom version
	show_verb_panel = FALSE
	///Contains admin info. Null if client is not an admin.
	var/datum/admins/holder = null
	///Needs to implement InterceptClickOn(user,params,atom) proc
	var/datum/click_intercept = null
	///Time when the click was intercepted
	var/click_intercept_time = 0

	///Used to cache this client's bans to save on DB queries
	var/ban_cache = null
	///If we are currently building this client's ban cache, this var stores the timeofday we started at
	var/ban_cache_start = 0
	///Contains the last message sent by this client - used to protect against copy-paste spamming.
	var/last_message = ""
	///contins a number of how many times a message identical to last_message was sent.
	var/last_message_count = 0
	///How many messages sent in the last 10 seconds
	var/total_message_count = 0
	///Next tick to reset the total message counter
	var/total_count_reset = 0
	///Internal counter for clients sending external (IRC/Discord) relay messages via ahelp to prevent spamming. Set to a number every time an admin reply is sent, decremented for every client send.
	var/externalreplyamount = 0
	///Tracks say() usage for ic/dchat while slowmode is enabled
	COOLDOWN_DECLARE(say_slowmode)
	/// The last urgent ahelp that this player sent
	COOLDOWN_DECLARE(urgent_ahelp_cooldown)

		/////////
		//OTHER//
		/////////
	///Player preferences datum for the client
	var/datum/preferences/prefs = null
	///Move delay of controlled mob, any keypresses inside this period will persist until the next proper move
	var/move_delay = 0
	///The visual delay to use for the current client.Move(), mostly used for making a client based move look like it came from some other slower source
	var/visual_delay = 0

		///////////////
		//SOUND STUFF//
		///////////////

		////////////
		//SECURITY//
		////////////
	// comment out the line below when debugging locally to enable the options & messages menu
	control_freak = 1

		////////////////////////////////////
		//things that require the database//
		////////////////////////////////////
	///Used to determine how old the account is - in days.
	var/player_age = -1
	///Date that this account was first seen in the server
	var/player_join_date = null
	///So admins know why it isn't working - Used to determine what other accounts previously logged in from this ip
	var/related_accounts_ip = "Requires database"
	///So admins know why it isn't working - Used to determine what other accounts previously logged in from this computer id
	var/related_accounts_cid = "Requires database"
	///Date of byond account creation in ISO 8601 format
	var/account_join_date = null
	///Age of byond account in days
	var/account_age = -1

	preload_rsc = PRELOAD_RSC

	var/atom/movable/screen/click_catcher/void

	///used to make a special mouse cursor, this one for mouse up icon
	var/mouse_up_icon = null
	///used to make a special mouse cursor, this one for mouse up icon
	var/mouse_down_icon = null
	///used to override the mouse cursor so it doesnt get reset
	var/mouse_override_icon = null

	///Used for ip intel checking to identify evaders, disabled because of issues with traffic
	var/ip_intel = "Disabled"

	///datum that controls the displaying and hiding of tooltips
	var/datum/tooltip/tooltips

	///Last ping of the client
	var/lastping = 0
	///Average ping of the client
	var/avgping = 0
	///world.time they connected
	var/connection_time
	///world.realtime they connected
	var/connection_realtime
	///world.timeofday they connected
	var/connection_timeofday

	///Used for limiting the rate of topic sends by the client to avoid abuse
	var/list/topiclimiter
	///Used for limiting the rate of clicks sends by the client to avoid abuse
	var/list/clicklimiter

	///lazy list of all credit object bound to this client
	var/list/credits

	///these persist between logins/logouts during the same round.
	var/datum/persistent_client/persistent_client

	///Should only be a key-value list of north/south/east/west = atom/movable/screen.
	var/list/char_render_holders

	///Amount of keydowns in the last keysend checking interval
	var/client_keysend_amount = 0
	///World tick time where client_keysend_amount will reset
	var/next_keysend_reset = 0
	///World tick time where keysend_tripped will reset back to false
	var/next_keysend_trip_reset = 0
	///When set to true, user will be autokicked if they trip the keysends in a second limit again
	var/keysend_tripped = FALSE
	///custom movement keys for this client
	var/list/movement_keys = list()

	///Autoclick list of two elements, first being the clicked thing, second being the parameters.
	var/list/atom/selected_target[2]
	///Used in MouseDrag to preserve the original mouse click parameters
	var/mouseParams = ""
	///Used in MouseDrag to preserve the last mouse-entered location. Weakref
	var/datum/weakref/mouse_location_ref = null
	///Used in MouseDrag to preserve the last mouse-entered object. Weakref
	var/datum/weakref/mouse_object_ref
	//Middle-mouse-button click dragtime control for aimbot exploit detection.
	var/middragtime = 0
	//Middle-mouse-button clicked object control for aimbot exploit detection. Weakref
	var/datum/weakref/middle_drag_atom_ref
	//When we started the currently active drag
	var/drag_start = 0
	//The params we were passed at the start of the drag, in list form
	var/list/drag_details


	/// Messages currently seen by this client
	var/list/seen_messages

	//Hide top bars
	var/fullscreen = FALSE
	//Hide status bar (bottom left)
	var/show_status_bar = TRUE

	/// datum wrapper for client view
	var/datum/view_data/view_size

	/// our current tab
	var/stat_tab

	/// list of all tabs
	var/list/panel_tabs = list()
	/// list of tabs containing spells and abilities
	var/list/spell_tabs = list()
	///A lazy list of atoms we've examined in the last RECENT_EXAMINE_MAX_WINDOW (default 2) seconds, so that we will call [/atom/proc/examine_more] instead of [/atom/proc/examine] on them when examining
	var/list/recent_examines

	var/list/parallax_layers
	var/list/parallax_layers_cached
	var/atom/movable/screen/parallax_home/parallax_rock
	///this is the last recorded client eye by SSparallax/fire()
	var/atom/movable/movingmob
	var/turf/previous_turf
	///world.time of when we can state animate()ing parallax again
	var/dont_animate_parallax
	/// Direction our current area wants to move parallax
	var/parallax_movedir = 0
	/// How many parallax layers to show our client
	var/parallax_layers_max = 4
	/// Timers for the area directional animation, one for each layer
	var/list/parallax_animate_timers
	/// Do we want to do parallax animations at all?
	/// Exists to prevent laptop fires
	var/do_parallax_animations = TRUE

	///Are we locking our movement input?
	var/movement_locked = FALSE

	/**
	 * Assoc list with all the active maps - when a screen obj is added to
	 * a map, it's put in here as well.
	 *
	 * Format: list(<mapname> = list(/atom/movable/screen))
	 */
	var/list/screen_maps = list()

	// List of all asset filenames sent to this client by the asset cache, along with their assoicated md5s
	var/list/sent_assets = list()
	/// List of all completed blocking send jobs awaiting acknowledgement by send_asset
	var/list/completed_asset_jobs = list()
	/// Last asset send job id.
	var/last_asset_job = 0
	var/last_completed_asset_job = 0

	/// rate limiting for the crew manifest
	var/crew_manifest_delay

	/// A buffer of currently held keys.
	var/list/keys_held = list()
	/// A buffer for combinations such of modifiers + keys (ex: CtrlD, AltE, ShiftT). Format: `"key"` -> `"combo"` (ex: `"D"` -> `"CtrlD"`)
	var/list/key_combos_held = list()
	/// The direction we WANT to move, based off our keybinds
	/// Will be udpated to be the actual direction later on
	var/intended_direction = NONE
	/*
	** These next two vars are to apply movement for keypresses and releases made while move delayed.
	** Because discarding that input makes the game less responsive.
	*/
	/// On next move, add this dir to the move that would otherwise be done
	var/next_move_dir_add
	/// On next move, subtract this dir from the move that would otherwise be done
	var/next_move_dir_sub

	/// If the client is currently under the restrictions of the interview system
	var/interviewee = FALSE

	/// Whether or not this client has standard hotkeys enabled
	var/hotkeys = TRUE

	/// Whether or not this client has the combo HUD enabled
	var/combo_hud_enabled = FALSE

	/// If this client has been fully initialized or not
	var/fully_created = FALSE

	/// Does this client have typing indicators enabled?
	var/typing_indicators = FALSE

	/// Loot panel for the client
	var/datum/lootpanel/loot_panel

	///Which ambient sound this client is currently being provided.
	var/current_ambient_sound
