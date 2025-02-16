
///assoc list of ckey -> /datum/persistent_client
GLOBAL_LIST_EMPTY_TYPED(persistent_clients_by_ckey, /datum/persistent_client)
/// A flat list of all persistent clients, for her looping pleasure.
GLOBAL_LIST_EMPTY_TYPED(persistent_clients, /datum/persistent_client)

/// Tracks information about a client between log in and log outs
/datum/persistent_client
	/// The true client
	var/client/client
	/// The mob this pclient is currently bound to.
	var/mob/mob

	/// Major version of BYOND this client is using.
	var/byond_version
	/// Build number of BYOND this client is using.
	var/byond_build

	/// Action datums assigned to this player
	var/list/datum/action/player_actions = list()
	/// Tracks client action logging
	var/list/logging = list()

	/// Callbacks invoked when this client logs in again
	var/list/post_login_callbacks = list()
	/// Callbacks invoked when this client logs out
	var/list/post_logout_callbacks = list()

	/// List of names this key played under this round
	/// assoc list of name -> mob tag
	var/list/played_names = list()
	/// Lazylist of preference slots this client has joined the round under
	/// Numbers are stored as strings
	var/list/joined_as_slots

	/// Tracks achievements they have earned
	var/datum/achievement_data/achievements

	/// World.time this player last died
	var/time_of_death = 0

/datum/persistent_client/New(ckey, client)
	src.client = client
	achievements = new(ckey)
	GLOB.persistent_clients_by_ckey[ckey] = src
	GLOB.persistent_clients += src

/datum/persistent_client/Destroy(force)
	SHOULD_CALL_PARENT(FALSE)
	. = QDEL_HINT_LETMELIVE
	CRASH("Who the FUCK tried to delete a persistent client? Get your head checked you leadskull.")

/// Setter for the mob var, handles both references.
/datum/persistent_client/proc/SetMob(mob/new_mob)
	if(mob == new_mob)
		return

	mob?.persistent_client = null
	new_mob?.persistent_client?.SetMob(null)

	mob = new_mob
	new_mob?.persistent_client = src

/// Writes all of the `played_names` into an HTML-escaped string.
/datum/persistent_client/proc/get_played_names()
	var/list/previous_names = list()
	for(var/previous_name in played_names)
		previous_names += html_encode("[previous_name] ([played_names[previous_name]])")
	return previous_names.Join("; ")

/// Returns the full version string (i.e 515.1642) of the BYOND version and build.
/datum/persistent_client/proc/full_byond_version()
	if(!byond_version)
		return "Unknown"
	return "[byond_version].[byond_build || "xxx"]"

/// Adds the new names to the player's played_names list on their /datum/persistent_client for use of admins.
/// `ckey` should be their ckey, and `data` should be an associative list with the keys being the names they played under and the values being the unique mob ID tied to that name.
/proc/log_played_names(ckey, data)
	if(!ckey)
		return

	var/datum/persistent_client/writable = GLOB.persistent_clients_by_ckey[ckey]
	if(isnull(writable))
		return

	for(var/name in data)
		if(!name)
			continue
		var/mob_tag = data[name]
		var/encoded_name = html_encode(name)
		if(writable.played_names.Find("[encoded_name]"))
			continue

		writable.played_names += list("[encoded_name]" = mob_tag)
