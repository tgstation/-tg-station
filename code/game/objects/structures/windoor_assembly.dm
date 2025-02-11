
/obj/structure/windoor_assembly
	icon = 'icons/obj/doors/windoor.dmi'

	name = "windoor Assembly"
	icon_state = "l_windoor_assembly01"
	desc = "A small glass and wire assembly for windoors."
	anchored = FALSE
	density = FALSE
	dir = NORTH
	obj_flags = CAN_BE_HIT | BLOCKS_CONSTRUCTION_DIR
	set_dir_on_move = FALSE
	can_atmos_pass = ATMOS_PASS_PROC

	/// Reference to the airlock electronics inside for determining window access.
	var/obj/item/electronics/airlock/electronics = null
	/// Player generated name string from renaming.
	var/created_name = null

	//Vars to help with the icon's name
	///Does the windoor open to the left or right?
	var/facing = "l"
	///Whether or not this creates a secure windoor
	var/secure = FALSE
	/**
	  * Windoor (window door) assembly -Nodrak
	  * Step 1: Create a windoor out of rglass
	  * Step 2: Add r-glass to the assembly to make a secure windoor (Optional)
	  * Step 3: Rotate or Flip the assembly to face and open the way you want
	  * Step 4: Wrench the assembly in place
	  * Step 5: Add cables to the assembly
	  * Step 6: Set access for the door.
	  * Step 7: Crowbar the door to complete
	 */
	var/state = "01"


/obj/structure/windoor_assembly/Initialize(mapload, set_dir)
	. = ..()
	if(set_dir)
		setDir(set_dir)
	air_update_turf(TRUE, TRUE)

	var/static/list/loc_connections = list(
		COMSIG_ATOM_EXIT = PROC_REF(on_exit),
	)

	AddElement(/datum/element/connect_loc, loc_connections)
	AddComponent(/datum/component/simple_rotation, ROTATION_NEEDS_ROOM)

/obj/structure/windoor_assembly/Destroy()
	set_density(FALSE)
	air_update_turf(TRUE, FALSE)
	return ..()

/obj/structure/windoor_assembly/Move()
	var/turf/T = loc
	. = ..()
	move_update_air(T)

/obj/structure/windoor_assembly/update_icon_state()
	icon_state = "[facing]_[secure ? "secure_" : ""]windoor_assembly[state]"
	return ..()

/obj/structure/windoor_assembly/CanAllowThrough(atom/movable/mover, border_dir)
	. = ..()

	if(border_dir == dir)
		return

	if(istype(mover, /obj/structure/window))
		var/obj/structure/window/moved_window = mover
		return valid_build_direction(loc, moved_window.dir, is_fulltile = moved_window.fulltile)

	if(istype(mover, /obj/structure/windoor_assembly) || istype(mover, /obj/machinery/door/window))
		return valid_build_direction(loc, mover.dir, is_fulltile = FALSE)

/obj/structure/windoor_assembly/can_atmos_pass(turf/T, vertical = FALSE)
	if(get_dir(loc, T) == dir)
		return !density
	else
		return TRUE

/obj/structure/windoor_assembly/proc/on_exit(datum/source, atom/movable/leaving, direction)
	SIGNAL_HANDLER

	if(leaving.movement_type & PHASING)
		return

	if(leaving == src)
		return // Let's not block ourselves.

	if (leaving.pass_flags & pass_flags_self)
		return

	if (direction == dir && density)
		leaving.Bump(src)
		return COMPONENT_ATOM_BLOCK_EXIT

/obj/structure/windoor_assembly/attackby(obj/item/W, mob/user, params)
	//I really should have spread this out across more states but thin little windoors are hard to sprite.
	add_fingerprint(user)
	switch(state)
		if("01")
			if(W.tool_behaviour == TOOL_WELDER && !anchored)
				if(!W.tool_start_check(user, amount=1))
					return

				user.visible_message(span_notice("[user] disassembles the windoor assembly."),
					span_notice("You start to disassemble the windoor assembly..."))

				if(W.use_tool(src, user, 40, volume=50))
					to_chat(user, span_notice("You disassemble the windoor assembly."))
					var/obj/item/stack/sheet/rglass/RG = new (get_turf(src), 5)
					if (!QDELETED(RG))
						RG.add_fingerprint(user)
					if(secure)
						var/obj/item/stack/rods/R = new (get_turf(src), 4)
						if (!QDELETED(R))
							R.add_fingerprint(user)
					qdel(src)
				return

			//Wrenching an unsecure assembly anchors it in place. Step 4 complete
			if(W.tool_behaviour == TOOL_WRENCH && !anchored)
				for(var/obj/machinery/door/window/WD in loc)
					if(WD.dir == dir)
						to_chat(user, span_warning("There is already a windoor in that location!"))
						return
				user.visible_message(span_notice("[user] secures the windoor assembly to the floor."),
					span_notice("You start to secure the windoor assembly to the floor..."))

				if(W.use_tool(src, user, 40, volume=100))
					if(anchored)
						return
					for(var/obj/machinery/door/window/WD in loc)
						if(WD.dir == dir)
							to_chat(user, span_warning("There is already a windoor in that location!"))
							return
					to_chat(user, span_notice("You secure the windoor assembly."))
					set_anchored(TRUE)
					if(secure)
						name = "secure anchored windoor assembly"
					else
						name = "anchored windoor assembly"

			//Unwrenching an unsecure assembly un-anchors it. Step 4 undone
			else if(W.tool_behaviour == TOOL_WRENCH && anchored)
				user.visible_message(span_notice("[user] unsecures the windoor assembly to the floor."),
					span_notice("You start to unsecure the windoor assembly to the floor..."))

				if(W.use_tool(src, user, 40, volume=100))
					if(!anchored)
						return
					to_chat(user, span_notice("You unsecure the windoor assembly."))
					set_anchored(FALSE)
					if(secure)
						name = "secure windoor assembly"
					else
						name = "windoor assembly"

			//Adding plasteel makes the assembly a secure windoor assembly. Step 2 (optional) complete.
			else if(istype(W, /obj/item/stack/sheet/plasteel) && !secure)
				var/obj/item/stack/sheet/plasteel/P = W
				if(P.get_amount() < 2)
					to_chat(user, span_warning("You need more plasteel to do this!"))
					return
				to_chat(user, span_notice("You start to reinforce the windoor with plasteel..."))

				if(do_after(user,40, target = src))
					if(!src || secure || P.get_amount() < 2)
						return

					P.use(2)
					to_chat(user, span_notice("You reinforce the windoor."))
					secure = TRUE
					if(anchored)
						name = "secure anchored windoor assembly"
					else
						name = "secure windoor assembly"

			//Adding cable to the assembly. Step 5 complete.
			else if(istype(W, /obj/item/stack/cable_coil) && anchored)
				user.visible_message(span_notice("[user] wires the windoor assembly."), span_notice("You start to wire the windoor assembly..."))

				if(do_after(user, 4 SECONDS, target = src))
					if(!src || !anchored || src.state != "01")
						return
					var/obj/item/stack/cable_coil/CC = W
					if(!CC.use(1))
						to_chat(user, span_warning("You need more cable to do this!"))
						return
					to_chat(user, span_notice("You wire the windoor."))
					state = "02"
					if(secure)
						name = "secure wired windoor assembly"
					else
						name = "wired windoor assembly"
			else
				return ..()

		if("02")

			//Removing wire from the assembly. Step 5 undone.
			if(W.tool_behaviour == TOOL_WIRECUTTER)
				user.visible_message(span_notice("[user] cuts the wires from the airlock assembly."), span_notice("You start to cut the wires from airlock assembly..."))

				if(W.use_tool(src, user, 40, volume=100))
					if(state != "02")
						return

					to_chat(user, span_notice("You cut the windoor wires."))
					new/obj/item/stack/cable_coil(get_turf(user), 1)
					state = "01"
					if(secure)
						name = "secure anchored windoor assembly"
					else
						name = "anchored windoor assembly"

			//Adding airlock electronics for access. Step 6 complete.
			else if(istype(W, /obj/item/electronics/airlock))
				if(!user.transferItemToLoc(W, src))
					return
				W.play_tool_sound(src, 100)
				user.visible_message(span_notice("[user] installs the electronics into the airlock assembly."),
					span_notice("You start to install electronics into the airlock assembly..."))

				if(do_after(user, 4 SECONDS, target = src))
					if(!src || electronics)
						W.forceMove(drop_location())
						return
					to_chat(user, span_notice("You install the airlock electronics."))
					name = "near finished windoor assembly"
					electronics = W
				else
					W.forceMove(drop_location())

			//Screwdriver to remove airlock electronics. Step 6 undone.
			else if(W.tool_behaviour == TOOL_SCREWDRIVER)
				if(!electronics)
					return

				user.visible_message(span_notice("[user] removes the electronics from the airlock assembly."),
					span_notice("You start to uninstall electronics from the airlock assembly..."))

				if(W.use_tool(src, user, 40, volume=100) && electronics)
					to_chat(user, span_notice("You remove the airlock electronics."))
					name = "wired windoor assembly"
					var/obj/item/electronics/airlock/ae
					ae = electronics
					electronics = null
					ae.forceMove(drop_location())

			else if(IS_WRITING_UTENSIL(W))
				var/t = tgui_input_text(user, "Enter the name for the door", "Windoor Renaming", created_name, max_length = MAX_NAME_LEN)
				if(!t)
					return
				if(!in_range(src, usr) && loc != usr)
					return
				created_name = t
				return



			//Crowbar to complete the assembly, Step 7 complete.
			else if(W.tool_behaviour == TOOL_CROWBAR)
				if(!electronics)
					to_chat(usr, span_warning("The assembly is missing electronics!"))
					return
				user.visible_message(span_notice("[user] pries the windoor into the frame."),
					span_notice("You start prying the windoor into the frame..."))

				if(W.use_tool(src, user, 40, volume=100) && electronics)
					set_density(TRUE) //Shouldn't matter but just incase
					to_chat(user, span_notice("You finish the windoor."))
					finish_door()

			else
				return ..()

	//Update to reflect changes(if applicable)
	update_appearance()

/obj/structure/windoor_assembly/examine(mob/user)
	. = ..()
	if(!anchored)
		. += span_notice("\The [src] can be [span_boldnotice("wrenched")] down.")
		. += span_notice("\The [src] could also be [span_boldnotice("cut apart")] with a [span_boldnotice("welder")].")
		return
	switch(state)
		if("01")
			. += span_notice("\The [src] needs [span_boldnotice("wiring")], or could be [span_boldnotice("un-wrenched")] from the floor.")
		if("02")
			if(!electronics)
				. += span_notice("\The [src] needs [span_boldnotice("airlock electronics")] to continue installation, or [span_boldnotice("wirecutters")] to take apart.")
			else
				. += span_notice("\The [src] is ready to be [span_boldnotice("levered")] into place with a [span_boldnotice("crowbar")].")

/obj/structure/windoor_assembly/proc/finish_door()
	var/obj/machinery/door/window/windoor
	if(secure)
		windoor = new /obj/machinery/door/window/brigdoor(loc)
		if(facing == "l")
			windoor.icon_state = "leftsecureopen"
			windoor.base_state = "leftsecure"
		else
			windoor.icon_state = "rightsecureopen"
			windoor.base_state = "rightsecure"

	else
		windoor = new /obj/machinery/door/window(loc)
		if(facing == "l")
			windoor.icon_state = "leftopen"
			windoor.base_state = "left"
		else
			windoor.icon_state = "rightopen"
			windoor.base_state = "right"

	windoor.setDir(dir)
	windoor.set_density(FALSE)
	if(created_name)
		windoor.name = created_name
	else if(electronics.passed_name)
		windoor.name = electronics.passed_name
	if(electronics.one_access)
		windoor.req_one_access = electronics.accesses
	else
		windoor.req_access = electronics.accesses
	if(electronics.unres_sides)
		windoor.unres_sides = electronics.unres_sides
		switch(dir)
			if(NORTH,SOUTH)
				windoor.unres_sides &= ~EAST
				windoor.unres_sides &= ~WEST
			if(EAST,WEST)
				windoor.unres_sides &= ~NORTH
				windoor.unres_sides &= ~SOUTH
		windoor.unres_sensor = TRUE
	electronics.forceMove(windoor)
	windoor.electronics = electronics
	windoor.autoclose = TRUE
	windoor.close()
	windoor.update_appearance()

	qdel(src)


//Flips the windoor assembly, determines whather the door opens to the left or the right
/obj/structure/windoor_assembly/verb/flip()
	set name = "Flip Windoor Assembly"
	set category = "Object"
	set src in oview(1)
	if(usr.stat != CONSCIOUS || HAS_TRAIT(usr, TRAIT_HANDS_BLOCKED))
		return

	if(isliving(usr))
		var/mob/living/L = usr
		if(!(L.mobility_flags & MOBILITY_USE))
			return

	if(facing == "l")
		to_chat(usr, span_notice("The windoor will now slide to the right."))
		facing = "r"
	else
		facing = "l"
		to_chat(usr, span_notice("The windoor will now slide to the left."))

	update_appearance()
	return
