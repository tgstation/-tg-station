// /program/ files are executable programs that do things.
/datum/computer_file/program
	filetype = "PRG"
	/// File name. FILE NAME MUST BE UNIQUE IF YOU WANT THE PROGRAM TO BE DOWNLOADABLE FROM NTNET!
	filename = "UnknownProgram"

	/// Program-specific bitflags that tell the app what it runs on.
	/// (PROGRAM_ALL | PROGRAM_CONSOLE | PROGRAM_LAPTOP | PROGRAM_PDA)
	var/can_run_on_flags = PROGRAM_ALL
	/// Program-specific bitflags that tells the ModPC what the app is able to do special.
	/// (PROGRAM_REQUIRES_NTNET|PROGRAM_ON_NTNET_STORE|PROGRAM_ON_SYNDINET_STORE|PROGRAM_UNIQUE_COPY|PROGRAM_HEADER|PROGRAM_RUNS_WITHOUT_POWER)
	var/program_flags = PROGRAM_ON_NTNET_STORE
	///How much power running this program costs.
	var/power_cell_use = PROGRAM_BASIC_CELL_USE
	///List of required accesses to *run* the program. Any match will do.
	///This also acts as download_access if that is not set, making this more draconic and restrictive.
	var/list/run_access = list()
	///List of required access to download or file host the program. Any match will do.
	var/list/download_access = list()
	/// User-friendly name of this program.
	var/filedesc = "Unknown Program"
	/// Short description of this program's function.
	var/extended_desc = "N/A"
	///What category this program can be found in within NTNetDownloader.
	///This is required if PROGRAM_ON_NTNET_STORE or PROGRAM_ON_SYNDINET_STORE is on.
	var/downloader_category = PROGRAM_CATEGORY_DEVICE
	///The overlay to add ontop of the ModPC running the app while it's open.
	///This is taken from the same file as the ModPC, so you can use can_run_on_flags to prevent
	///the program from being used on devices that don't have sprites for it.
	var/program_open_overlay = null
	/// NTNet status, updated every tick by computer running this program. Don't use this for checks if NTNet works, computers do that. Use this for calculations, etc.
	var/ntnet_status = 1
	/// Name of the tgui interface. If this is not defined, this will not be available in NTNet.
	var/tgui_id
	/// Example: "something.gif" - a header image that will be rendered in computer's UI when this program is running at background. Images must also be inserted into /datum/asset/simple/headers.
	var/ui_header = null
	/// Font Awesome icon to use as this program's icon in the modular computer main menu. Defaults to a basic program maximize window icon if not overridden.
	var/program_icon = "window-maximize-o"
	/// Whether this program can send alerts while minimized or closed. Used to show a mute button per program in the file manager
	var/alert_able = FALSE
	/// Whether the user has muted this program's ability to send alerts.
	var/alert_silenced = FALSE
	/// Whether to highlight our program in the main screen. Intended for alerts, but loosely available for any need to notify of changed conditions. Think Windows task bar highlighting. Available even if alerts are muted.
	var/alert_pending = FALSE
	/// How well this program will help combat detomatix viruses.
	var/detomatix_resistance = NONE
	/// Unremovable circuit componentn added to the physical computer while the program is installed
	var/obj/item/circuit_component/mod_program/circuit_comp_type

/datum/computer_file/program/New()
	..()
	///We need to ensure that different programs (subtypes mostly) won't try to load in the same circuit comps into the shell or usb port of the modpc.
	if(circuit_comp_type && initial(circuit_comp_type.associated_program) != type)
		stack_trace("circuit comp type mismatch: [type] has circuit comp type \[[circuit_comp_type]\], while \[[circuit_comp_type]\] has associated program \[[initial(circuit_comp_type.associated_program)]\].")

/**
 * Here we deal with peculiarity of adding unremovable components to the computer shell.
 * It probably doesn't look badass, but it's a decent way of doing it without taining the component with
 * oddities like this.
 */
/datum/computer_file/program/on_install(datum/computer_file/source, obj/item/modular_computer/computer_installing)
	. = ..()
	if(isnull(circuit_comp_type) || isnull(computer.shell))
		return
	if(!(locate(circuit_comp_type) in computer.shell.unremovable_circuit_components))
		var/obj/item/circuit_component/mod_program/comp = new circuit_comp_type()
		computer.shell.add_unremovable_circuit_component(comp)
		if(computer.shell.attached_circuit)
			comp.forceMove(computer.shell.attached_circuit)
			computer.shell.attached_circuit.add_component(comp)

///Here we deal with killing the associated components instead.
/datum/computer_file/program/Destroy()
	if(isnull(circuit_comp_type) || isnull(computer?.shell))
		return ..()
	for(var/obj/item/circuit_component/mod_program/comp in computer.shell.unremovable_circuit_components)
		if(comp.associated_program == src)
			computer.shell.unremovable_circuit_components -= comp
			qdel(comp)
	return ..()

/datum/computer_file/program/clone()
	var/datum/computer_file/program/temp = ..()
	temp.run_access = run_access
	temp.filedesc = filedesc
	temp.program_open_overlay = program_open_overlay
	temp.program_flags = program_flags
	temp.can_run_on_flags = can_run_on_flags
	if(program_flags & PROGRAM_UNIQUE_COPY)
		if(computer)
			computer.remove_file(src)
		if(disk_host)
			disk_host.remove_file(src)
	return temp

/**
 * WARNING: this proc does not work the same as normal `ui_interact`, as the
 * computer takes care of opening the UI. The `datum/tgui/ui` parameter will always exist.
 * This proc only serves as a callback.
 */
/datum/computer_file/program/ui_interact(mob/user, datum/tgui/ui)
	SHOULD_CALL_PARENT(FALSE)

// Relays icon update to the computer.
/datum/computer_file/program/proc/update_computer_icon()
	if(computer)
		computer.update_appearance()

///Attempts to generate an Ntnet log, returns the log on success, FALSE otherwise.
/datum/computer_file/program/proc/generate_network_log(text)
	if(!computer || computer.obj_flags & EMAGGED)
		return FALSE
	return computer.add_log(text)

/**
 *Runs when the device is used to attack an atom in non-combat mode using right click (secondary).
 *
 *Simulates using the device to read or scan something. Tap is called by the computer during pre_attack
 *and sends us all of the related info. If we return TRUE, the computer will stop the attack process
 *there. What we do with the info is up to us, but we should only return TRUE if we actually perform
 *an action of some sort.
 *Arguments:
 *A is the atom being tapped
 *user is the person making the attack action
 *modifiers is anything the pre_attack() proc had in the same-named variable.
*/
/datum/computer_file/program/proc/tap(atom/tapped_atom, mob/living/user, list/modifiers)
	return FALSE

///Makes sure a program can run on this hardware (for apps limited to tablets/computers/laptops)
/datum/computer_file/program/proc/is_supported_by_hardware(hardware_flag = NONE, loud = FALSE, mob/user)
	if(!(hardware_flag & can_run_on_flags))
		if(loud && computer && user)
			to_chat(user, span_danger("\The [computer] flashes a \"Hardware Error - Incompatible software\" warning."))
		return FALSE
	return TRUE

// Called by Process() on device that runs us, once every tick.
/datum/computer_file/program/proc/process_tick(seconds_per_tick)
	return TRUE

/**
 * Checks if the user can run program. Only humans and silicons can operate computer. Automatically called in on_start()
 * ID must be inserted into a card slot to be read. If the program is not currently installed (as is the case when
 * NT Software Hub is checking available software), a list can be given to be used instead.
 * Args:
 * user is a ref of the mob using the device.
 * loud is a bool deciding if this proc should use to_chats
 * access_to_check is an access level that will be checked against the ID
 * downloading: Boolean on whether it's downloading the app or not. If it is, it will check download_access instead of run_access.
 * access can contain a list of access numbers to check against. If access is not empty, it will be used istead of checking any inserted ID.
 */
/datum/computer_file/program/proc/can_run(mob/user, loud = FALSE, access_to_check, downloading = FALSE, list/access)
	if(user)
		if(issilicon(user) && !ispAI(user))
			return TRUE
		if(isAdminGhostAI(user))
			return TRUE

	if(computer && (computer.obj_flags & EMAGGED) && (program_flags & PROGRAM_ON_SYNDINET_STORE || !downloading)) //emagged can run anything on syndinet, and can bypass execution locks, but not download.
		return TRUE

	if(!access_to_check)
		if(downloading && length(download_access))
			access_to_check = download_access
		else
			access_to_check = run_access
	if(!length(access_to_check)) // No access requirements, allow it.
		return TRUE

	if(!length(access))
		var/obj/item/card/id/accesscard
		if(computer)
			accesscard = computer.computer_id_slot?.GetID()

		if(!accesscard)
			if(loud && user)
				to_chat(user, span_danger("\The [computer] flashes an \"RFID Error - Unable to scan ID\" warning."))
			return FALSE
		access = accesscard.GetAccess()

	for(var/singular_access in access_to_check)
		if(singular_access in access) //For loop checks every individual access entry in the access list. If the user's ID has access to any entry, then we're good.
			return TRUE

	if(loud && user)
		to_chat(user, span_danger("\The [computer] flashes an \"Access Denied\" warning."))
	return FALSE

/**
 * Called on program startup.
 *
 * May be overridden to add extra logic. Remember to include ..() call. Return 1 on success, 0 on failure.
 * When implementing new program based device, use this to run the program.
 * Arguments:
 * * user - The mob that started the program
 **/
/datum/computer_file/program/proc/on_start(mob/living/user)
	SHOULD_CALL_PARENT(TRUE)
	if(!can_run(user, loud = TRUE))
		return FALSE
	if(program_flags & PROGRAM_REQUIRES_NTNET)
		var/obj/item/card/id/ID = computer.computer_id_slot?.GetID()
		generate_network_log("Connection opened -- Program ID:[filename] User:[ID?"[ID.registered_name]":"None"]")
	SEND_SIGNAL(src, COMSIG_COMPUTER_PROGRAM_START, user)
	return TRUE

/**
 * Kills the running program
 *
 * Use this proc to kill the program.
 * Designed to be implemented by each program if it requires on-quit logic, such as the NTNRC client.
 * Args:
 * - user - If there's a user, this is the person killing the program.
 **/
/datum/computer_file/program/proc/kill_program(mob/user)
	SHOULD_CALL_PARENT(TRUE)

	if(src == computer.active_program)
		computer.active_program = null
		if(!QDELETED(computer) && computer.enabled)
			INVOKE_ASYNC(computer, TYPE_PROC_REF(/obj/item/modular_computer, update_tablet_open_uis), user)
	else if(src in computer.idle_threads)
		computer.idle_threads.Remove(src)
	else //The program wasn't running to begin with.
		return FALSE

	if(program_flags & PROGRAM_REQUIRES_NTNET)
		var/obj/item/card/id/ID = computer.computer_id_slot?.GetID()
		generate_network_log("Connection closed -- Program ID: [filename] User:[ID ? "[ID.registered_name]" : "None"]")

	computer.update_appearance(UPDATE_ICON)
	SEND_SIGNAL(src, COMSIG_COMPUTER_PROGRAM_KILL, user)
	return TRUE

///Sends the running program to the background/idle threads. Header programs can't be minimized and will kill instead.
/datum/computer_file/program/proc/background_program(mob/user)
	SHOULD_CALL_PARENT(TRUE)
	if(program_flags & PROGRAM_HEADER || length(computer.idle_threads) > computer.max_idle_programs)
		return kill_program()

	computer.idle_threads.Add(src)
	computer.active_program = null

	if(user)
		INVOKE_ASYNC(computer, TYPE_PROC_REF(/obj/item/modular_computer, update_tablet_open_uis), user)
	computer.update_appearance(UPDATE_ICON)
	return TRUE
