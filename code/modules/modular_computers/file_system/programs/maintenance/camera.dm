/datum/computer_file/program/maintenance/camera
	filename = "camera_app"
	filedesc = "Camera"
	program_open_overlay = "camera"
	downloader_category = PROGRAM_CATEGORY_EQUIPMENT
	extended_desc = "This program allows the taking of pictures."
	size = 4
	can_run_on_flags = PROGRAM_PDA
	tgui_id = "NtosCamera"
	program_icon = "camera"
	circuit_comp_type = /obj/item/circuit_component/mod_program/camera

	/// Camera built-into the tablet.
	var/obj/item/camera/app/internal_camera
	/// Latest picture taken by the app.
	var/datum/picture/internal_picture
	/// How many pictures were taken already, used for the camera's TGUI photo display
	var/picture_number = 1

// Special type of camera for this exact usecase to prevent harddels
/obj/item/camera/app
	name = "internal camera"
	desc = "Specialized internal camera protected from the hellish depths of SSWardrobe. \
	Yell at coders if you somehow manage to see this"

/datum/computer_file/program/maintenance/camera/on_install()
	. = ..()
	internal_camera = new(computer)
	internal_camera.print_picture_on_snap = FALSE

/datum/computer_file/program/maintenance/camera/Destroy()
	if(internal_camera)
		QDEL_NULL(internal_camera)
	if(internal_picture)
		QDEL_NULL(internal_picture)
	return ..()

/datum/computer_file/program/maintenance/camera/tap(atom/tapped_atom, mob/living/user, list/modifiers)
	. = ..()
	if(internal_picture)
		QDEL_NULL(internal_picture)
	var/turf/our_turf = get_turf(tapped_atom)
	var/spooky_camera = locate(/datum/computer_file/program/maintenance/spectre_meter) in computer.stored_files
	internal_camera.see_ghosts = spooky_camera ?  CAMERA_SEE_GHOSTS_BASIC : CAMERA_NO_GHOSTS
	internal_picture = internal_camera.captureimage(our_turf, user, internal_camera.picture_size_x + 1, internal_camera.picture_size_y + 1)
	picture_number++
	computer.save_photo(internal_picture.picture_image)

/datum/computer_file/program/maintenance/camera/ui_data(mob/user)
	var/list/data = list()

	if(!isnull(internal_picture))
		user << browse_rsc(internal_picture.picture_image, "tmp_photo[picture_number].png")
		data["photo"] = "tmp_photo[picture_number].png"

	data["paper_left"] = computer.stored_paper

	return data

/datum/computer_file/program/maintenance/camera/ui_act(action, params, datum/tgui/ui, datum/ui_state/state)
	. = ..()
	switch(action)
		if("print_photo")
			if(computer.stored_paper <= 0)
				to_chat(usr, span_notice("Hardware error: Printer out of paper."))
				return
			internal_camera.printpicture(usr, internal_picture)
			computer.stored_paper--
			computer.visible_message(span_notice("\The [computer] prints out a paper."))

/obj/item/circuit_component/mod_program/camera
	associated_program = /datum/computer_file/program/maintenance/camera
	circuit_flags = CIRCUIT_FLAG_INPUT_SIGNAL

	///A target to take a picture of.
	var/datum/port/input/picture_target
	///The photographed target
	var/datum/port/output/photographed
	/**
	 * Pinged when the image has been captured.
	 * I'm not using the default trigger output here because the process is asynced,
	 * even though I'm mostly sure it only sleeps if there's a set user.
	 */
	var/datum/port/output/photo_taken

/obj/item/circuit_component/mod_program/camera/populate_ports()
	. = ..()
	picture_target = add_input_port("Picture Target", PORT_TYPE_ATOM)
	photographed = add_output_port("Photographed Entity", PORT_TYPE_ATOM)
	photo_taken = add_output_port("Photo Taken", PORT_TYPE_SIGNAL)

/obj/item/circuit_component/mod_program/camera/register_shell(atom/movable/shell)
	. = ..()
	var/datum/computer_file/program/maintenance/camera/cam = associated_program
	RegisterSignal(cam.internal_camera, COMSIG_CAMERA_IMAGE_CAPTURED, PROC_REF(on_image_captured))

/obj/item/circuit_component/mod_program/camera/unregister_shell()
	var/datum/computer_file/program/maintenance/camera/cam = associated_program
	UnregisterSignal(cam.internal_camera, COMSIG_CAMERA_IMAGE_CAPTURED)
	return ..()

/obj/item/circuit_component/mod_program/camera/input_received(datum/port/input/port)
	var/atom/target = picture_target.value
	if(!target)
		var/turf/our_turf = get_location()
		target = locate(our_turf.x, our_turf.y, our_turf.z)
		if(!target)
			return
	var/datum/computer_file/program/maintenance/camera/cam = associated_program
	if(!cam.internal_camera.can_target(target))
		return
	var/pic_size_x = cam.internal_camera.picture_size_x - 1
	var/pic_size_y = cam.internal_camera.picture_size_y - 1
	INVOKE_ASYNC(cam.internal_camera, TYPE_PROC_REF(/obj/item/camera, captureimage), target, null, pic_size_x, pic_size_y)

/obj/item/circuit_component/mod_program/camera/proc/on_image_captured(obj/item/camera/source, atom/target, mob/user)
	SIGNAL_HANDLER
	photographed.set_output(target)
	photo_taken.set_output(COMPONENT_SIGNAL)
