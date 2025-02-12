/*
 * HOW IT WORKS
 *
 *The SSradio is a global object maintaining all radio transmissions, think about it as about "ether".
 *Note that walkie-talkie, intercoms and headsets handle transmission using nonstandard way.
 *procs:
 *
 * add_object(obj/device as obj, new_frequency as num, filter as text|null = null)
 *   Adds listening object.
 *   parameters:
 *     device - device receiving signals, must have proc receive_signal (see description below).
 *       one device may listen several frequencies, but not same frequency twice.
 *     new_frequency - see possibly frequencies below;
 *     filter - thing for optimization. Optional, but recommended.
 *              All filters should be consolidated in this file, see defines later.
 *              Device without listening filter will receive all signals (on specified frequency).
 *              Device with filter will receive any signals sent without filter.
 *              Device with filter will not receive any signals sent with different filter.
 *   returns:
 *    Reference to frequency object.
 *
 * remove_object (obj/device, old_frequency)
 *   Obliviously, after calling this proc, device will not receive any signals on old_frequency.
 *   Other frequencies will left unaffected.
 *
 *return_frequency(var/frequency as num)
 *   returns:
 *    Reference to frequency object. Use it if you need to send and do not need to listen.
 *
 *radio_frequency is a global object maintaining list of devices that listening specific frequency.
 *procs:
 *
 *   post_signal(obj/source as obj|null, datum/signal/signal, filter as text|null = null, range as num|null = null)
 *     Sends signal to all devices that wants such signal.
 *     parameters:
 *       source - object, emitted signal. Usually, devices will not receive their own signals.
 *       signal - see description below.
 *       filter - described above.
 *       range - radius of regular byond's square circle on that z-level. null means everywhere, on all z-levels.
 *
 * obj/proc/receive_signal(datum/signal/signal, receive_method as num, receive_param)
 *   Handler from received signals. By default does nothing. Define your own for your object.
 *   Avoid of sending signals directly from this proc, use spawn(0). Do not use sleep() here please.
 *     parameters:
 *       signal - see description below. Extract all needed data from the signal before doing sleep(), spawn() or return!
 *       receive_method - may be TRANSMISSION_WIRE or TRANSMISSION_RADIO.
 *         TRANSMISSION_WIRE is currently unused.
 *       receive_param - for TRANSMISSION_RADIO here comes frequency.
 *
 * datum/signal
 *   vars:
 *   source
 *     an object that emitted signal. Used for debug and bearing.
 *   data
 *     list with transmitting data. Usual use pattern:
 *       data["msg"] = "hello world"
 *   encryption
 *     Some number symbolizing "encryption key".
 *     Note that game actually do not use any cryptography here.
 *     If receiving object don't know right key, it must ignore encrypted signal in its receive_signal.
 *
 */
/* the radio controller is a confusing piece of shit and didnt work
	so i made radios not use the radio controller.
*/
GLOBAL_LIST_EMPTY(all_radios)

/proc/add_radio(obj/item/radio, freq)
	if(!freq || !radio)
		return
	if(!GLOB.all_radios["[freq]"])
		GLOB.all_radios["[freq]"] = list(radio)
		return freq

	GLOB.all_radios["[freq]"] |= radio
	return freq

/proc/remove_radio(obj/item/radio, freq)
	if(!freq || !radio)
		return
	if(!GLOB.all_radios["[freq]"])
		return

	GLOB.all_radios["[freq]"] -= radio

/proc/remove_radio_all(obj/item/radio)
	for(var/freq in GLOB.all_radios)
		GLOB.all_radios["[freq]"] -= radio

// For information on what objects or departments use what frequencies,
// see __DEFINES/radio.dm. Mappers may also select additional frequencies for
// use in maps, such as in intercoms.

GLOBAL_LIST_INIT(radiochannels, list(
	RADIO_CHANNEL_COMMON = FREQ_COMMON,
	RADIO_CHANNEL_SCIENCE = FREQ_SCIENCE,
	RADIO_CHANNEL_COMMAND = FREQ_COMMAND,
	RADIO_CHANNEL_MEDICAL = FREQ_MEDICAL,
	RADIO_CHANNEL_ENGINEERING = FREQ_ENGINEERING,
	RADIO_CHANNEL_SECURITY = FREQ_SECURITY,
	RADIO_CHANNEL_CENTCOM = FREQ_CENTCOM,
	RADIO_CHANNEL_SYNDICATE = FREQ_SYNDICATE,
	RADIO_CHANNEL_UPLINK = FREQ_UPLINK,
	RADIO_CHANNEL_SUPPLY = FREQ_SUPPLY,
	RADIO_CHANNEL_SERVICE = FREQ_SERVICE,
	RADIO_CHANNEL_AI_PRIVATE = FREQ_AI_PRIVATE,
	RADIO_CHANNEL_ENTERTAINMENT = FREQ_ENTERTAINMENT,
	RADIO_CHANNEL_CTF_BLUE = FREQ_CTF_BLUE,
	RADIO_CHANNEL_CTF_GREEN = FREQ_CTF_GREEN,
	RADIO_CHANNEL_CTF_RED = FREQ_CTF_RED,
	RADIO_CHANNEL_CTF_YELLOW = FREQ_CTF_YELLOW,
	STATUS_DISPLAY_RELAY = FREQ_STATUS_DISPLAYS,
))

GLOBAL_LIST_INIT(reverseradiochannels, list(
	"[FREQ_COMMON]" = RADIO_CHANNEL_COMMON,
	"[FREQ_SCIENCE]" = RADIO_CHANNEL_SCIENCE,
	"[FREQ_COMMAND]" = RADIO_CHANNEL_COMMAND,
	"[FREQ_MEDICAL]" = RADIO_CHANNEL_MEDICAL,
	"[FREQ_ENGINEERING]" = RADIO_CHANNEL_ENGINEERING,
	"[FREQ_SECURITY]" = RADIO_CHANNEL_SECURITY,
	"[FREQ_CENTCOM]" = RADIO_CHANNEL_CENTCOM,
	"[FREQ_SYNDICATE]" = RADIO_CHANNEL_SYNDICATE,
	"[FREQ_UPLINK]" = RADIO_CHANNEL_UPLINK,
	"[FREQ_SUPPLY]" = RADIO_CHANNEL_SUPPLY,
	"[FREQ_SERVICE]" = RADIO_CHANNEL_SERVICE,
	"[FREQ_AI_PRIVATE]" = RADIO_CHANNEL_AI_PRIVATE,
	"[FREQ_ENTERTAINMENT]" = RADIO_CHANNEL_ENTERTAINMENT,
	"[FREQ_CTF_RED]" = RADIO_CHANNEL_CTF_RED,
	"[FREQ_CTF_BLUE]" = RADIO_CHANNEL_CTF_BLUE,
	"[FREQ_CTF_GREEN]" = RADIO_CHANNEL_CTF_GREEN,
	"[FREQ_CTF_YELLOW]" = RADIO_CHANNEL_CTF_YELLOW,
	"[FREQ_STATUS_DISPLAYS]" = STATUS_DISPLAY_RELAY,
))

GLOBAL_LIST_INIT(radiocolors, list(
	RADIO_CHANNEL_COMMON = "#008000",
	RADIO_CHANNEL_SCIENCE = "#993399",
	RADIO_CHANNEL_COMMAND = "#948f02",
	RADIO_CHANNEL_MEDICAL = "#337296",
	RADIO_CHANNEL_ENGINEERING = "#fb5613",
	RADIO_CHANNEL_SECURITY = "#a30000",
	RADIO_CHANNEL_CENTCOM = "#686868",
	RADIO_CHANNEL_SYNDICATE = "#6d3f40",
	RADIO_CHANNEL_SUPPLY = "#a8732b",
	RADIO_CHANNEL_SERVICE = "#6eaa2c",
	RADIO_CHANNEL_AI_PRIVATE = "#ff00ff",
	RADIO_CHANNEL_ENTERTAINMENT = "#00ff99",
	RADIO_CHANNEL_CTF_RED = "#ff0000",
	RADIO_CHANNEL_CTF_BLUE = "#0000ff",
	RADIO_CHANNEL_CTF_GREEN = "#00ff00",
	RADIO_CHANNEL_CTF_YELLOW = "#d1ba22",
	STATUS_DISPLAY_RELAY = "#00ff99",
))

/datum/radio_frequency
	/// The frequency of this radio frequency. Of course.
	var/frequency
	/// List of filters -> list of devices
	var/list/list/datum/weakref/devices = list()

/datum/radio_frequency/New(freq)
	frequency = freq

//If range > 0, only post to devices on the same z_level and within range
//Use range = -1, to restrain to the same z_level without limiting range
/datum/radio_frequency/proc/post_signal(obj/source as obj|null, datum/signal/signal, filter = null as text|null, range = null as num|null)
	// Ensure the signal's data is fully filled
	signal.source = source
	signal.frequency = frequency

	//Apply filter to the signal. If none supply, broadcast to every devices
	//_default channel is always checked
	var/list/filter_list

	if(filter)
		filter_list = list(filter,"_default")
	else
		filter_list = devices

	//If checking range, find the source turf
	var/turf/start_point
	if(range)
		start_point = get_turf(source)
		if(!start_point)
			return

	//Send the data
	for(var/current_filter in filter_list)
		for(var/datum/weakref/device_ref as anything in devices[current_filter])
			var/obj/device = device_ref.resolve()
			if(!device)
				devices[current_filter] -= device_ref
				continue
			if(device == source)
				continue
			if(range)
				var/turf/end_point = get_turf(device)
				if(!end_point)
					continue
				if(start_point.z != end_point.z || (range > 0 && get_dist(start_point, end_point) > range))
					continue
			device.receive_signal(signal)
			CHECK_TICK

/// Handles adding a listener to the radio frequency.
/datum/radio_frequency/proc/add_listener(obj/device, filter as text|null)
	if (!filter)
		filter = "_default"

	var/datum/weakref/new_listener = WEAKREF(device)
	if(isnull(new_listener))
		return stack_trace("null, non-datum, or qdeleted device")
	var/list/devices_line = devices[filter]
	if(!devices_line)
		devices[filter] = devices_line = list()
	devices_line += new_listener

/// Handles removing a listener from this radio frequency.
/datum/radio_frequency/proc/remove_listener(obj/device)
	for(var/devices_filter in devices)
		var/list/devices_line = devices[devices_filter]
		if(!devices_line)
			devices -= devices_filter
		devices_line -= WEAKREF(device)
		if(!devices_line.len)
			devices -= devices_filter

/**
 * Proc for reacting to a received `/datum/signal`. To be implemented as needed,
 * does nothing by default.
 */
/obj/proc/receive_signal(datum/signal/signal)
	set waitfor = FALSE
	return

/datum/signal
	/// The source of this signal.
	var/obj/source
	/// The frequency on which this signal was emitted.
	var/frequency = 0
	/// The method through which this signal was transmitted.
	/// See all of the `TRANSMISSION_X` in `code/__DEFINES/radio.dm` for
	/// all of the possible options.
	var/transmission_method
	/// The data carried through this signal. Defaults to `null`, otherwise it's
	/// an associative list of (string, any).
	var/list/data
	/// Logging data, used for logging purposes. Makes sense, right?
	var/logging_data

/datum/signal/New(data, transmission_method = TRANSMISSION_RADIO, logging_data = null)
	src.data = data || list()
	src.transmission_method = transmission_method
	src.logging_data = logging_data
