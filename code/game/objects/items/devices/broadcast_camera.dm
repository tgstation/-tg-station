// Unique broadcast camera given to the first Curator
// Only one should exist ideally, if other types are created they must have different camera_networks
// Broadcasts its surroundings to entertainment monitors and its audio to entertainment radio channel
/obj/item/broadcast_camera
	name = "broadcast camera"
	desc = "A large camera that streams its live feed and audio to entertainment monitors across the station, allowing everyone to watch the broadcast."
	desc_controls = "Right-click to change the broadcast name. Alt-click to toggle microphone."
	icon = 'icons/obj/service/broadcast.dmi'
	icon_state = "broadcast_cam0"
	base_icon_state = "broadcast_cam"
	lefthand_file = 'icons/mob/inhands/items/devices_lefthand.dmi'
	righthand_file = 'icons/mob/inhands/items/devices_righthand.dmi'
	force = 8
	throwforce = 12
	w_class = WEIGHT_CLASS_NORMAL
	resistance_flags = INDESTRUCTIBLE | LAVA_PROOF | FIRE_PROOF | UNACIDABLE | ACID_PROOF
	slot_flags = NONE
	light_system = OVERLAY_LIGHT
	light_color = COLOR_SOFT_RED
	light_range = 1
	light_power = 0.3
	light_on = FALSE
	/// Is camera streaming
	var/active = FALSE
	/// Is the microphone turned on
	var/active_microphone = TRUE
	/// The name of the broadcast
	var/broadcast_name = "Curator News"
	/// The networks it broadcasts to, default is CAMERANET_NETWORK_CURATOR
	var/list/camera_networks = list(CAMERANET_NETWORK_CURATOR)
	/// The "virtual" security camera inside of the physical camera
	var/obj/machinery/camera/internal_camera
	/// The "virtual" radio inside of the the physical camera, a la microphone
	var/obj/item/radio/entertainment/microphone/internal_radio

/obj/item/broadcast_camera/Initialize(mapload)
	. = ..()

	AddElement(/datum/element/empprotection, EMP_PROTECT_ALL)

/obj/item/broadcast_camera/Destroy(force)
	QDEL_NULL(internal_radio)
	QDEL_NULL(internal_camera)
	return ..()

/obj/item/broadcast_camera/update_icon_state()
	icon_state = "[base_icon_state][active]"
	return ..()

/obj/item/broadcast_camera/attack_self(mob/user, modifiers)
	. = ..()
	active = !active
	if(active)
		on_activating()
	else
		on_deactivating()

/obj/item/broadcast_camera/attack_self_secondary(mob/user, modifiers)
	. = ..()
	broadcast_name = tgui_input_text(user = user, title = "Broadcast Name", message = "What will be the name of your broadcast?", default = "[broadcast_name]", max_length = MAX_CHARTER_LEN)

/obj/item/broadcast_camera/examine(mob/user)
	. = ..()
	. += span_notice("Broadcast name is <b>[broadcast_name]</b>")
	. += span_notice("The microphone is <b>[active_microphone ? "On" : "Off"]</b>")

/obj/item/broadcast_camera/on_enter_storage(datum/storage/master_storage)
	. = ..()
	if(active)
		on_deactivating()

/obj/item/broadcast_camera/dropped(mob/user, silent)
	. = ..()
	if(active)
		on_deactivating()

/// When activating the camera
/obj/item/broadcast_camera/proc/on_activating()
	if(!iscarbon(loc))
		return
	active = TRUE
	update_icon_state()
	/// The carbon who wielded the camera, allegedly
	var/mob/living/carbon/wielding_carbon = loc

	// INTERNAL CAMERA
	internal_camera = new(wielding_carbon) // Cameras for some reason do not work inside of obj's
	internal_camera.internal_light = FALSE
	internal_camera.network = camera_networks
	internal_camera.c_tag = "LIVE: [broadcast_name]"
	start_broadcasting_network(camera_networks, "[broadcast_name] is now LIVE!")

	// INTERNAL RADIO
	internal_radio = new(src)
	/// Sets the state of the microphone
	set_microphone_state()

	set_light_on(TRUE)
	playsound(source = src, soundin = 'sound/machines/terminal/terminal_processing.ogg', vol = 20, vary = FALSE, ignore_walls = FALSE)
	balloon_alert_to_viewers("live!")

/// When deactivating the camera
/obj/item/broadcast_camera/proc/on_deactivating()
	active = FALSE
	update_icon_state()
	QDEL_NULL(internal_camera)
	QDEL_NULL(internal_radio)

	stop_broadcasting_network(camera_networks)

	set_light_on(FALSE)
	playsound(source = src, soundin = 'sound/machines/terminal/terminal_prompt_deny.ogg', vol = 20, vary = FALSE, ignore_walls = FALSE)
	balloon_alert_to_viewers("offline")

/obj/item/broadcast_camera/click_alt(mob/user)
	active_microphone = !active_microphone

	/// Text popup for letting the user know that the microphone has changed state
	balloon_alert(user, "microphone [active_microphone ? "" : "de"]activated")

	///If the radio exists as an object, set its state accordingly
	if(active)
		set_microphone_state()

	return CLICK_ACTION_SUCCESS

/obj/item/broadcast_camera/proc/set_microphone_state()
	internal_radio.set_broadcasting(active_microphone)
