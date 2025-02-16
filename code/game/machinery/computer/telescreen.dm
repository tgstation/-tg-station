/obj/machinery/computer/security/telescreen
	name = "\improper Telescreen"
	desc = "Used for watching an empty arena."
	icon = 'icons/obj/wallmounts.dmi'
	icon_state = "telescreen"
	icon_keyboard = null
	icon_screen = null
	layer = SIGN_LAYER
	network = list(CAMERANET_NETWORK_THUNDERDOME)
	density = FALSE
	circuit = null
	light_power = 0
	/// The kind of wallframe that this telescreen drops
	var/frame_type = /obj/item/wallframe/telescreen
	projectiles_pass_chance = 100

/obj/item/wallframe/telescreen
	name = "telescreen frame"
	desc = "A wall-mountable telescreen frame. Apply to wall to use."
	icon = 'icons/obj/wallmounts.dmi'
	icon_state = "telescreen"
	result_path = /obj/machinery/computer/security/telescreen
	pixel_shift = 32

/obj/machinery/computer/security/telescreen/on_deconstruction(disassembled)
	new frame_type(loc)

/obj/machinery/computer/security/telescreen/update_icon_state()
	icon_state = initial(icon_state)
	if(machine_stat & BROKEN)
		icon_state += "b"
	return ..()

/obj/machinery/computer/security/telescreen/entertainment
	name = "entertainment monitor"
	desc = "Damn, they better have the /tg/ channel on these things."
	icon = 'icons/obj/machines/status_display.dmi'
	icon_state = "entertainment_blank"
	network = list()
	density = FALSE
	circuit = null
	interaction_flags_atom = INTERACT_ATOM_UI_INTERACT | INTERACT_ATOM_NO_FINGERPRINT_INTERACT | INTERACT_ATOM_NO_FINGERPRINT_ATTACK_HAND | INTERACT_MACHINE_REQUIRES_SIGHT
	frame_type = /obj/item/wallframe/telescreen/entertainment
	/// Virtual radio inside of the entertainment monitor to broadcast audio
	var/obj/item/radio/entertainment/speakers/speakers
	var/icon_state_off = "entertainment_blank"
	var/icon_state_on = "entertainment"

/obj/machinery/computer/security/telescreen/entertainment/add_context(atom/source, list/context, obj/item/held_item, mob/user)
	context[SCREENTIP_CONTEXT_CTRL_LMB] = "Toggle mute button"
	return CONTEXTUAL_SCREENTIP_SET

/obj/machinery/computer/security/telescreen/entertainment/click_ctrl(mob/user)
	. = ..()
	balloon_alert(user, speakers.should_be_listening ? "muted" : "unmuted")
	speakers.toggle_mute()

MAPPING_DIRECTIONAL_HELPERS(/obj/machinery/computer/security/telescreen/entertainment, 32)

/obj/item/wallframe/telescreen/entertainment
	name = "entertainment telescreen frame"
	icon = 'icons/obj/machines/status_display.dmi'
	icon_state = "entertainment_blank"
	result_path = /obj/machinery/computer/security/telescreen/entertainment

/obj/machinery/computer/security/telescreen/entertainment/Initialize(mapload)
	. = ..()
	find_and_hang_on_wall()
	register_context()
	RegisterSignal(SSdcs, COMSIG_GLOB_NETWORK_BROADCAST_UPDATED, PROC_REF(on_network_broadcast_updated))
	speakers = new(src)

/obj/machinery/computer/security/telescreen/entertainment/Destroy()
	UnregisterSignal(SSdcs, COMSIG_GLOB_NETWORK_BROADCAST_UPDATED)
	QDEL_NULL(speakers)
	return ..()

/obj/machinery/computer/security/telescreen/entertainment/examine(mob/user)
	. = ..()
	. += length(network) ? span_notice("The TV is broadcasting something!") : span_notice("<i>There's nothing on TV.</i>")
	. += span_notice("The volume is currently [speakers.should_be_listening ? "on" : "off"]")

/obj/machinery/computer/security/telescreen/entertainment/ui_state(mob/user)
	return GLOB.always_state

// Snowflake ui status to allow mobs to watch TV from across the room,
// but only allow adjacent mobs / tk users / silicon to change the channel
/obj/machinery/computer/security/telescreen/entertainment/ui_status(mob/living/user, datum/ui_state/state)
	if(!can_watch_tv(user))
		return UI_CLOSE
	if(!isliving(user))
		return isAdminGhostAI(user) ? UI_INTERACTIVE : UI_UPDATE
	if(user.stat >= SOFT_CRIT)
		return UI_UPDATE

	var/can_range = FALSE
	if(iscarbon(user))
		var/mob/living/carbon/carbon_user = user
		if(carbon_user.dna?.check_mutation(/datum/mutation/human/telekinesis) && tkMaxRangeCheck(user, src))
			can_range = TRUE
	if(HAS_SILICON_ACCESS(user) || (user.interaction_range && user.interaction_range >= get_dist(user, src)))
		can_range = TRUE

	if((can_range || user.CanReach(src)) && ISADVANCEDTOOLUSER(user))
		if(user.incapacitated)
			return UI_UPDATE
		if(!can_range && user.can_hold_items() && (user.usable_hands <= 0 || HAS_TRAIT(user, TRAIT_HANDS_BLOCKED)))
			return UI_UPDATE
		return UI_INTERACTIVE
	return UI_UPDATE

/obj/machinery/computer/security/telescreen/entertainment/Click(location, control, params)
	if(world.time <= usr.next_click + 1)
		return // just so someone can't turn an auto clicker on and spam tvs

	. = ..()
	if(!can_watch_tv(usr))
		return
	if((!length(network) && !Adjacent(usr)) || LAZYACCESS(params2list(params), SHIFT_CLICK)) // let people examine
		return
	// Lets us see the tv regardless of click results
	INVOKE_ASYNC(src, TYPE_PROC_REF(/atom, interact), usr)

/obj/machinery/computer/security/telescreen/entertainment/proc/can_watch_tv(mob/living/watcher)
	if(!is_operational)
		return FALSE
	if((watcher.sight & SEE_OBJS) || HAS_SILICON_ACCESS(watcher))
		if(get_dist(watcher, src) > 7)
			return FALSE
	else
		if(!can_see(watcher, src, 7))
			return FALSE
	if(watcher.is_blind())
		return FALSE
	if(!isobserver(watcher) && watcher.stat >= UNCONSCIOUS)
		return FALSE
	return TRUE

/// Sets the monitor's icon to the selected state, and says an announcement
/obj/machinery/computer/security/telescreen/entertainment/proc/notify(on, announcement)
	if(on && icon_state == icon_state_off)
		icon_state = icon_state_on
	else
		icon_state = icon_state_off
	if(announcement)
		say(announcement)

/// Adds a camera network ID to the entertainment monitor, and turns off the monitor if network list is empty
/obj/machinery/computer/security/telescreen/entertainment/proc/on_network_broadcast_updated(datum/source, tv_show_id, is_show_active, announcement)
	SIGNAL_HANDLER
	if(!network)
		return

	if(is_show_active)
		network |= tv_show_id
	else
		network -= tv_show_id

	INVOKE_ASYNC(src, TYPE_PROC_REF(/datum, update_static_data_for_all_viewers))
	notify(length(network), announcement)

/**
 * Adds a camera network to all entertainment monitors.
 *
 * * camera_net - The camera network ID to add to the monitors.
 * * announcement - Optional, what announcement to make when the show starts.
 */
/proc/start_broadcasting_network(camera_net, announcement)
	SEND_GLOBAL_SIGNAL(COMSIG_GLOB_NETWORK_BROADCAST_UPDATED, camera_net, TRUE, announcement)

/**
 * Removes a camera network from all entertainment monitors.
 *
 * * camera_net - The camera network ID to remove from the monitors.
 * * announcement - Optional, what announcement to make when the show ends.
 */
/proc/stop_broadcasting_network(camera_net, announcement)
	SEND_GLOBAL_SIGNAL(COMSIG_GLOB_NETWORK_BROADCAST_UPDATED, camera_net, FALSE, announcement)

/**
 * Sets the camera network status on all entertainment monitors.
 * A way to force a network to a status if you are unsure of the current state.
 *
 * * camera_net - The camera network ID to set on the monitors.
 * * is_show_active - Whether the show is active or not.
 * * announcement - Optional, what announcement to make.
 * Note this announcement will be made regardless of the current state of the show:
 * This means if it's currently on and you set it to on, the announcement will still be made.
 * Likewise, there's no way to differentiate off -> on and on -> off, unless you handle that yourself.
 */
/proc/set_network_broadcast_status(camera_net, is_show_active, announcement)
	SEND_GLOBAL_SIGNAL(COMSIG_GLOB_NETWORK_BROADCAST_UPDATED, camera_net, is_show_active, announcement)

/obj/machinery/computer/security/telescreen/rd
	name = "\improper Research Director's telescreen"
	desc = "Used for watching the AI and the RD's goons from the safety of his office."
	network = list(
		CAMERANET_NETWORK_RD,
		CAMERANET_NETWORK_AI_CORE,
		CAMERANET_NETWORK_AI_UPLOAD,
		CAMERANET_NETWORK_MINISAT,
		CAMERANET_NETWORK_XENOBIOLOGY,
		CAMERANET_NETWORK_TEST_CHAMBER,
		CAMERANET_NETWORK_ORDNANCE,
	)
	frame_type = /obj/item/wallframe/telescreen/rd

MAPPING_DIRECTIONAL_HELPERS(/obj/machinery/computer/security/telescreen/rd, 32)

/obj/item/wallframe/telescreen/rd
	name = "\improper Research Director's telescreen frame"
	result_path = /obj/machinery/computer/security/telescreen/rd

/obj/machinery/computer/security/telescreen/research
	name = "research telescreen"
	desc = "A telescreen with access to the research division's camera network."
	network = list(CAMERANET_NETWORK_RD)
	frame_type = /obj/item/wallframe/telescreen/research

/obj/item/wallframe/telescreen/research
	name = "research telescreen frame"
	result_path = /obj/machinery/computer/security/telescreen/research

MAPPING_DIRECTIONAL_HELPERS(/obj/machinery/computer/security/telescreen/research, 32)

/obj/machinery/computer/security/telescreen/ce
	name = "\improper Chief Engineer's telescreen"
	desc = "Used for watching the engine, telecommunications and the minisat."
	network = list(CAMERANET_NETWORK_ENGINE, CAMERANET_NETWORK_TELECOMMS, CAMERANET_NETWORK_MINISAT)
	frame_type = /obj/item/wallframe/telescreen/ce

/obj/item/wallframe/telescreen/ce
	name = "\improper Chief Engineer's telescreen frame"
	result_path = /obj/machinery/computer/security/telescreen/ce

MAPPING_DIRECTIONAL_HELPERS(/obj/machinery/computer/security/telescreen/ce, 32)

/obj/machinery/computer/security/telescreen/cmo
	name = "\improper Chief Medical Officer's telescreen"
	desc = "A telescreen with access to the medbay's camera network."
	network = list(CAMERANET_NETWORK_MEDBAY)
	frame_type = /obj/item/wallframe/telescreen/cmo

/obj/item/wallframe/telescreen/cmo
	name = "\improper Chief Medical Officer's telescreen frame"
	result_path = /obj/machinery/computer/security/telescreen/cmo

MAPPING_DIRECTIONAL_HELPERS(/obj/machinery/computer/security/telescreen/cmo, 32)

/obj/machinery/computer/security/telescreen/med_sec
	name = "\improper medical telescreen"
	desc = "A telescreen with access to the medbay's camera network."
	network = list(CAMERANET_NETWORK_MEDBAY)
	frame_type = /obj/item/wallframe/telescreen/med_sec

/obj/item/wallframe/telescreen/med_sec
	name = "\improper medical telescreen frame"
	result_path = /obj/machinery/computer/security/telescreen/med_sec

MAPPING_DIRECTIONAL_HELPERS(/obj/machinery/computer/security/telescreen/med_sec, 32)

/obj/machinery/computer/security/telescreen/vault
	name = "vault monitor"
	desc = "A telescreen that connects to the vault's camera network."
	network = list(CAMERANET_NETWORK_VAULT)
	frame_type = /obj/item/wallframe/telescreen/vault

/obj/item/wallframe/telescreen/vault
	name = "vault telescreen frame"
	result_path = /obj/machinery/computer/security/telescreen/vault

MAPPING_DIRECTIONAL_HELPERS(/obj/machinery/computer/security/telescreen/vault, 32)

/obj/machinery/computer/security/telescreen/ordnance
	name = "bomb test site monitor"
	desc = "A telescreen that connects to the bomb test site's camera."
	network = list(CAMERANET_NETWORK_ORDNANCE)
	frame_type = /obj/item/wallframe/telescreen/ordnance

/obj/item/wallframe/telescreen/ordnance
	name = "bomb test site telescreen frame"
	result_path = /obj/machinery/computer/security/telescreen/ordnance

MAPPING_DIRECTIONAL_HELPERS(/obj/machinery/computer/security/telescreen/ordnance, 32)

/obj/machinery/computer/security/telescreen/engine
	name = "engine monitor"
	desc = "A telescreen that connects to the engine's camera network."
	network = list(CAMERANET_NETWORK_ENGINE)
	frame_type = /obj/item/wallframe/telescreen/engine

/obj/item/wallframe/telescreen/engine
	name = "engine telescreen frame"
	result_path = /obj/machinery/computer/security/telescreen/engine

MAPPING_DIRECTIONAL_HELPERS(/obj/machinery/computer/security/telescreen/engine, 32)

/obj/machinery/computer/security/telescreen/turbine
	name = "turbine monitor"
	desc = "A telescreen that connects to the turbine's camera."
	network = list(CAMERANET_NETWORK_TURBINE)
	frame_type = /obj/item/wallframe/telescreen/turbine

/obj/item/wallframe/telescreen/turbine
	name = "turbine telescreen frame"
	result_path = /obj/machinery/computer/security/telescreen/turbine

MAPPING_DIRECTIONAL_HELPERS(/obj/machinery/computer/security/telescreen/turbine, 32)

/obj/machinery/computer/security/telescreen/interrogation
	name = "interrogation room monitor"
	desc = "A telescreen that connects to the interrogation room's camera."
	network = list(CAMERANET_NETWORK_INTERROGATION)
	frame_type = /obj/item/wallframe/telescreen/interrogation

/obj/item/wallframe/telescreen/interrogation
	name = "interrogation telescreen frame"
	result_path = /obj/machinery/computer/security/telescreen/interrogation

MAPPING_DIRECTIONAL_HELPERS(/obj/machinery/computer/security/telescreen/interrogation, 32)

/obj/machinery/computer/security/telescreen/prison
	name = "prison monitor"
	desc = "A telescreen that connects to the permabrig's camera network."
	network = list(CAMERANET_NETWORK_PRISON)
	frame_type = /obj/item/wallframe/telescreen/prison

/obj/item/wallframe/telescreen/prison
	name = "prison telescreen frame"
	result_path = /obj/machinery/computer/security/telescreen/prison

MAPPING_DIRECTIONAL_HELPERS(/obj/machinery/computer/security/telescreen/prison, 32)

/obj/machinery/computer/security/telescreen/auxbase
	name = "auxiliary base monitor"
	desc = "A telescreen that connects to the auxiliary base's camera."
	network = list(CAMERANET_NETWORK_AUXBASE)
	frame_type = /obj/item/wallframe/telescreen/auxbase

/obj/item/wallframe/telescreen/auxbase
	name = "auxiliary base telescreen frame"
	result_path = /obj/machinery/computer/security/telescreen/auxbase

MAPPING_DIRECTIONAL_HELPERS(/obj/machinery/computer/security/telescreen/auxbase, 32)

/obj/machinery/computer/security/telescreen/minisat
	name = "minisat monitor"
	desc = "A telescreen that connects to the minisat's camera network."
	network = list(CAMERANET_NETWORK_MINISAT)
	frame_type = /obj/item/wallframe/telescreen/minisat

/obj/item/wallframe/telescreen/minisat
	name = "minisat telescreen frame"
	result_path = /obj/machinery/computer/security/telescreen/minisat

MAPPING_DIRECTIONAL_HELPERS(/obj/machinery/computer/security/telescreen/minisat, 32)

/obj/machinery/computer/security/telescreen/aiupload
	name = "\improper AI upload monitor"
	desc = "A telescreen that connects to the AI upload's camera network."
	network = list(CAMERANET_NETWORK_AI_UPLOAD)
	frame_type = /obj/item/wallframe/telescreen/aiupload

/obj/item/wallframe/telescreen/aiupload
	name = "\improper AI upload telescreen frame"
	result_path = /obj/machinery/computer/security/telescreen/aiupload

MAPPING_DIRECTIONAL_HELPERS(/obj/machinery/computer/security/telescreen/aiupload, 32)

/obj/machinery/computer/security/telescreen/bar
	name = "bar monitor"
	desc = "A telescreen that connects to the bar's camera network. Perfect for checking on customers."
	network = list(CAMERANET_NETWORK_BAR)
	frame_type = /obj/item/wallframe/telescreen/bar

/obj/item/wallframe/telescreen/bar
	name = "bar telescreen frame"
	result_path = /obj/machinery/computer/security/telescreen/bar

MAPPING_DIRECTIONAL_HELPERS(/obj/machinery/computer/security/telescreen/bar, 32)

/obj/machinery/computer/security/telescreen/isolation
	name = "isolation cell monitor"
	desc = "A telescreen that connects to the isolation cells camera network."
	network = list(CAMERANET_NETWORK_ISOLATION)
	frame_type = /obj/item/wallframe/telescreen/bar

/obj/item/wallframe/telescreen/isolation
	name = "isolation telescreen frame"
	result_path = /obj/machinery/computer/security/telescreen/isolation

MAPPING_DIRECTIONAL_HELPERS(/obj/machinery/computer/security/telescreen/isolation, 32)

/obj/machinery/computer/security/telescreen/normal
	name = "security camera monitor"
	desc = "A telescreen that connects to the stations camera network."
	network = list(CAMERANET_NETWORK_SS13)
	frame_type = /obj/item/wallframe/telescreen/normal

/obj/item/wallframe/telescreen/normal
	name = "security camera telescreen frame"
	result_path = /obj/machinery/computer/security/telescreen/normal

MAPPING_DIRECTIONAL_HELPERS(/obj/machinery/computer/security/telescreen/normal, 32)

/obj/machinery/computer/security/telescreen/tcomms
	name = "tcomms camera monitor"
	desc = "A telescreen that connects to the tcomms camera network."
	network = list(CAMERANET_NETWORK_TELECOMMS)
	frame_type = /obj/item/wallframe/telescreen/tcomms

/obj/item/wallframe/telescreen/tcomms
	name = "tcomms camera telescreen frame"
	result_path = /obj/machinery/computer/security/telescreen/tcomms

MAPPING_DIRECTIONAL_HELPERS(/obj/machinery/computer/security/telescreen/tcomms, 32)

/obj/machinery/computer/security/telescreen/test_chamber
	name = "xenobiology test chamber camera monitor"
	desc = "A telescreen that connects to the xenobiology test chamber camera network."
	network = list(CAMERANET_NETWORK_XENOBIOLOGY)
	frame_type = /obj/item/wallframe/telescreen/test_chamber

/obj/item/wallframe/telescreen/test_chamber
	name = "xenobiology test chamber camera telescreen frame"
	result_path = /obj/machinery/computer/security/telescreen/test_chamber

MAPPING_DIRECTIONAL_HELPERS(/obj/machinery/computer/security/telescreen/test_chamber, 32)

/obj/machinery/computer/security/telescreen/engine_waste
	name = "\improper Engine Waste Monitor"
	desc = "A telescreen that connects to the engine waste camera network."
	network = list(CAMERANET_NETWORK_WASTE)
	frame_type = /obj/item/wallframe/telescreen/engine_waste

/obj/item/wallframe/telescreen/engine_waste
	name = "\improper Engine Waste telescreen frame"
	result_path = /obj/machinery/computer/security/telescreen/engine_waste

MAPPING_DIRECTIONAL_HELPERS(/obj/machinery/computer/security/telescreen/engine_waste, 32)

/obj/machinery/computer/security/telescreen/cargo_sec
	name = "cargo camera monitor"
	desc = "A telescreen that connects to the cargo and main station camera network."
	network = list(CAMERANET_NETWORK_SS13,
					CAMERA_NETWORK_CARGO,
					)
	frame_type = /obj/item/wallframe/telescreen/cargo_sec

/obj/item/wallframe/telescreen/cargo_sec
	name = "cargo telescreen frame"
	result_path = /obj/machinery/computer/security/telescreen/cargo_sec

MAPPING_DIRECTIONAL_HELPERS(/obj/machinery/computer/security/telescreen/cargo_sec, 32)

// This is used in moonoutpost19.dmm
/obj/machinery/computer/security/telescreen/moon_outpost

/obj/machinery/computer/security/telescreen/moon_outpost/research
	name = "research monitor"
	desc = "Used for monitoring the research division and the labs within."
	network = list(CAMERANET_NETWORK_MOON19_RESEARCH,
					CAMERANET_NETWORK_MOON19_XENO,
					)

MAPPING_DIRECTIONAL_HELPERS(/obj/machinery/computer/security/telescreen/moon_outpost/research, 32)

/obj/machinery/computer/security/telescreen/moon_outpost/xenobio
	name = "xenobiology monitor"
	desc = "Used for watching the contents of the xenobiology containment pen."
	network = list(CAMERANET_NETWORK_MOON19_XENO)

MAPPING_DIRECTIONAL_HELPERS(/obj/machinery/computer/security/telescreen/moon_outpost/xenobio, 32)

// This is used in undergroundoutpost45.dmm
/obj/machinery/computer/security/telescreen/underground_outpost

/obj/machinery/computer/security/telescreen/underground_outpost/research
	name = "research monitor"
	desc = "Used for monitoring the research division and the labs within."
	network = list(CAMERANET_NETWORK_UGO45_RESEARCH)

MAPPING_DIRECTIONAL_HELPERS(/obj/machinery/computer/security/telescreen/underground_outpost/research, 32)

// This is used in forgottenship.dmm
/obj/machinery/computer/security/telescreen/forgotten_ship

/obj/machinery/computer/security/telescreen/forgotten_ship/sci
	name = "Cameras monitor"
	network = list(CAMERANET_NETWORK_FSCI)
	req_access = list("syndicate")

MAPPING_DIRECTIONAL_HELPERS(/obj/machinery/computer/security/telescreen/forgotten_ship/sci, 32)

// This is used in deepstorage.dmm
/obj/machinery/computer/security/telescreen/deep_storage

/obj/machinery/computer/security/telescreen/deep_storage/bunker
	name = "Bunker Entrance monitor"
	network = list(CAMERA_NETWORK_BUNKER)

MAPPING_DIRECTIONAL_HELPERS(/obj/machinery/computer/security/telescreen/deep_storage/bunker, 32)

/// A button that adds a camera network to the entertainment monitors
/obj/machinery/button/showtime
	name = "thunderdome showtime button"
	desc = "Use this button to allow entertainment monitors to broadcast the big game."
	device_type = /obj/item/assembly/control/showtime
	req_access = list()
	id = "showtime_1"

/obj/machinery/button/showtime/Initialize(mapload)
	. = ..()
	if(device)
		var/obj/item/assembly/control/showtime/ours = device
		ours.id = id

/obj/item/assembly/control/showtime
	name = "showtime controller"
	desc = "A remote controller for entertainment monitors."
	/// Stores if the show associated with this controller is active or not
	var/is_show_active = FALSE
	/// The camera network id this controller toggles
	var/tv_network_id = "thunder"
	/// The display TV show name
	var/tv_show_name = "Thunderdome"
	/// List of phrases the entertainment console may say when the show begins
	var/list/tv_starters = list(
		"Feats of bravery live now at the thunderdome!",
		"Two enter, one leaves! Tune in now!",
		"Violence like you've never seen it before!",
		"Spears! Camera! Action! LIVE NOW!",
	)
	/// List of phrases the entertainment console may say when the show ends
	var/list/tv_enders = list(
		"Thank you for tuning in to the slaughter!",
		"What a show! And we guarantee next one will be bigger!",
		"Celebrate the results with Thundermerch!",
		"This show was brought to you by Nanotrasen.",
	)

/obj/item/assembly/control/showtime/activate()
	is_show_active = !is_show_active
	say("The [tv_show_name] show has [is_show_active ? "begun" : "ended"]")
	var/announcement = is_show_active ? pick(tv_starters) : pick(tv_enders)
	set_network_broadcast_status(tv_network_id, is_show_active, announcement)
