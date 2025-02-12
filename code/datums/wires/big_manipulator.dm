/datum/wires/big_manipulator
	holder_type = /obj/machinery/big_manipulator
	proper_name = "Big_Manipulator"

/datum/wires/big_manipulator/New(atom/holder)
	wires = list(
		WIRE_ON,
		WIRE_DROP,
		WIRE_ITEM_TYPE,
		WIRE_CHANGE_MODE,
		WIRE_ONE_PRIORITY_BUTTON,
		WIRE_THROW_RANGE
	)
	return ..()

/datum/wires/big_manipulator/interactable(mob/user)
	var/obj/machinery/big_manipulator/manipulator_big = holder

	return manipulator_big.panel_open ? ..() : FALSE

/datum/wires/big_manipulator/get_status()
	var/obj/machinery/big_manipulator/manipulator_big = holder
	var/list/status = list()
	status += "The big light bulb is [manipulator_big.on_button_cutted ? "went out" : manipulator_big.on ? "green" : "red"]."
	status += "The small red light shows: [isnull(manipulator_big.containment_obj) ? "empty" : "full"]."
	status += "Text on the yellow board shows: [manipulator_big.selected_type.name]."
	status += "There are [manipulator_big.manipulate_mode] text on the small blue panel."
	status += "The purple light is [manipulator_big.only_highest_priority ? "on" : "off"]."
	status += "The number on small white panel shows [manipulator_big.manipulator_throw_range]."
	return status

/datum/wires/big_manipulator/on_pulse(wire)
	var/obj/machinery/big_manipulator/manipulator_big = holder
	switch(wire)
		if(WIRE_ON)
			manipulator_big.try_press_on(usr)
		if(WIRE_DROP)
			manipulator_big.drop_containment_item()
		if(WIRE_ITEM_TYPE)
			manipulator_big.change_what_take_type()
		if(WIRE_CHANGE_MODE)
			manipulator_big.change_mode()
		if(WIRE_ONE_PRIORITY_BUTTON)
			manipulator_big.only_highest_priority = !manipulator_big.only_highest_priority
		if(WIRE_THROW_RANGE)
			manipulator_big.change_throw_range()

/datum/wires/big_manipulator/on_cut(wire, mend, source)
	var/obj/machinery/big_manipulator/manipulator_big = holder
	if(wire == WIRE_ON)
		if(mend)
			manipulator_big.on_button_cutted = FALSE
			return
		manipulator_big.on_button_cutted = TRUE
