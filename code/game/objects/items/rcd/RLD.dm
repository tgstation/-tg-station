// RAPID LIGHTING DEVICE

// modes of operation
#define GLOW_MODE 1
#define LIGHT_MODE 2
#define REMOVE_MODE 3

// operation costs
#define LIGHT_TUBE_COST 10
#define FLOOR_LIGHT_COST 15
#define GLOW_STICK_COST 5
#define DECONSTRUCT_COST 10

//operation delays
#define BUILD_DELAY 10
#define REMOVE_DELAY 15

/obj/item/construction/rld
	name = "Rapid Lighting Device"
	desc = "A device used to rapidly provide lighting sources to an area. Reload with iron, plasteel, glass or compressed matter cartridges."
	icon = 'icons/obj/tools.dmi'
	icon_state = "rld"
	worn_icon_state = "RPD"
	lefthand_file = 'icons/mob/inhands/equipment/tools_lefthand.dmi'
	righthand_file = 'icons/mob/inhands/equipment/tools_righthand.dmi'
	matter = 200
	max_matter = 200
	slot_flags = ITEM_SLOT_BELT
	has_ammobar = TRUE
	ammo_sections = 6
	banned_upgrades = RCD_ALL_UPGRADES & ~RCD_UPGRADE_SILO_LINK

	/// mode of operation see above defines
	var/mode = LIGHT_MODE

	///reference to thr original icons
	var/static/list/original_options = list(
		"Color Pick" = icon(icon = 'icons/hud/radial.dmi', icon_state = "omni"),
		"Glow Stick" = icon(icon = 'icons/obj/lighting.dmi', icon_state = "glowstick"),
		"Deconstruct" = icon(icon = 'icons/obj/tools.dmi', icon_state = "wrench"),
		"Light Fixture" = icon(icon = 'icons/obj/lighting.dmi', icon_state = "ltube"),
	)
	///will contain the original icons modified with the color choice
	var/list/display_options = list()
	var/color_choice = "#ffffff"

/obj/item/construction/rld/Initialize(mapload)
	. = ..()
	for(var/option in original_options)
		display_options[option] = icon(original_options[option])

/obj/item/construction/rld/attack_self(mob/user)
	. = ..()

	if((upgrade & RCD_UPGRADE_SILO_LINK) && display_options["Silo Link"] == null) //silo upgrade instaled but option was not updated then update it just one
		display_options["Silo Link"] = icon(icon = 'icons/obj/machines/ore_silo.dmi', icon_state = "silo")

	var/choice = show_radial_menu(user, src, display_options, custom_check = CALLBACK(src, PROC_REF(check_menu), user), require_near = TRUE, tooltips = TRUE)
	if(!check_menu(user))
		return
	if(!choice)
		return

	switch(choice)
		if("Light Fixture")
			mode = LIGHT_MODE
			to_chat(user, span_notice("You change RLD's mode to 'Permanent Light Construction'."))
		if("Glow Stick")
			mode = GLOW_MODE
			to_chat(user, span_notice("You change RLD's mode to 'Light Launcher'."))
		if("Color Pick")
			var/new_choice = input(user,"","Choose Color",color_choice) as color
			if(new_choice == null)
				return

			var/list/new_rgb = rgb2num(new_choice)
			for(var/option in original_options)
				if(option == "Color Pick" || option == "Deconstruct" || option == "Silo Link")
					continue
				var/icon/icon = icon(original_options[option])
				icon.SetIntensity(new_rgb[1]/255, new_rgb[2]/255, new_rgb[3]/255) //apply new scale
				display_options[option] = icon

			color_choice = new_choice
		if("Deconstruct")
			mode = REMOVE_MODE
			to_chat(user, span_notice("You change RLD's mode to 'Deconstruct'."))
		else
			toggle_silo(user)

/obj/item/construction/rld/ranged_interact_with_atom(atom/interacting_with, mob/living/user, list/modifiers)
	if(!range_check(interacting_with, user))
		return NONE
	return try_lighting(interacting_with, user)

/obj/item/construction/rld/interact_with_atom(atom/interacting_with, mob/living/user, list/modifiers)
	. = ..()
	if(. & ITEM_INTERACT_ANY_BLOCKER)
		return .
	return try_lighting(interacting_with, user)

/**
 * Try to place/remove a light or throw a glowstick
 * Arguments
 *
 * * atom/interacting_with - the target atom to light or throw glowsticks at
 * * mob/user - the player doing this action
 */
/obj/item/construction/rld/proc/try_lighting(atom/interacting_with, mob/user)
	PRIVATE_PROC(TRUE)

	if(HAS_TRAIT(interacting_with, TRAIT_COMBAT_MODE_SKIP_INTERACTION))
		return NONE

	var/turf/start = get_turf(src)
	switch(mode)
		if(REMOVE_MODE)
			if(!istype(interacting_with, /obj/machinery/light))
				return NONE

			//resource sanity checks before & after delay
			if(!checkResource(DECONSTRUCT_COST, user))
				return ITEM_INTERACT_BLOCKING
			var/beam = user.Beam(interacting_with, icon_state="light_beam", time = 15)
			playsound(src, 'sound/machines/click.ogg', 50, TRUE)
			if(!do_after(user, REMOVE_DELAY, target = interacting_with))
				qdel(beam)
				return ITEM_INTERACT_BLOCKING
			if(!checkResource(DECONSTRUCT_COST, user))
				return ITEM_INTERACT_BLOCKING
			if(!useResource(DECONSTRUCT_COST, user))
				return ITEM_INTERACT_BLOCKING
			activate()
			qdel(interacting_with)
			return ITEM_INTERACT_SUCCESS

		if(LIGHT_MODE)
			//resource sanity checks before & after delay
			var/cost = iswallturf(interacting_with) ? LIGHT_TUBE_COST : FLOOR_LIGHT_COST

			if(!checkResource(cost, user))
				return ITEM_INTERACT_BLOCKING
			var/beam = user.Beam(interacting_with, icon_state="light_beam", time = BUILD_DELAY)
			playsound(loc, 'sound/machines/click.ogg', 50, TRUE)
			playsound(loc, 'sound/effects/light_flicker.ogg', 50, FALSE)
			if(!do_after(user, BUILD_DELAY, target = interacting_with))
				qdel(beam)
				return ITEM_INTERACT_BLOCKING
			if(!checkResource(cost, user))
				return ITEM_INTERACT_BLOCKING

			if(iswallturf(interacting_with))
				var/turf/open/winner = null
				var/winning_dist = null
				for(var/direction in GLOB.cardinals)
					var/turf/C = get_step(interacting_with, direction)
					//turf already has a light
					if(locate(/obj/machinery/light) in C)
						continue
					//can't put a light here
					if(!(isspaceturf(C) || TURF_SHARES(C)))
						continue
					//find turf closest to our player
					var/x0 = C.x
					var/y0 = C.y
					var/contender = CHEAP_HYPOTENUSE(start.x, start.y, x0, y0)
					if(!winner)
						winner = C
						winning_dist = contender
					else if(contender < winning_dist) // lower is better
						winner = C
						winning_dist = contender
				if(!winner)
					balloon_alert(user, "no valid target!")
					return ITEM_INTERACT_BLOCKING
				if(!useResource(cost, user))
					return ITEM_INTERACT_BLOCKING
				activate()
				var/obj/machinery/light/L = new /obj/machinery/light(get_turf(winner))
				L.setDir(get_dir(winner, interacting_with))
				L.color = color_choice
				L.set_light_color(color_choice)
				return ITEM_INTERACT_SUCCESS

			if(isfloorturf(interacting_with))
				var/turf/target = get_turf(interacting_with)
				if(locate(/obj/machinery/light/floor) in target)
					return ITEM_INTERACT_BLOCKING
				if(!useResource(cost, user))
					return ITEM_INTERACT_BLOCKING
				activate()
				var/obj/machinery/light/floor/FL = new /obj/machinery/light/floor(target)
				FL.color = color_choice
				FL.set_light_color(color_choice)
				return ITEM_INTERACT_SUCCESS

		if(GLOW_MODE)
			if(!useResource(GLOW_STICK_COST, user))
				return ITEM_INTERACT_BLOCKING
			activate()
			// Picks the closest fitting color for the fluid by hue
			var/closest_diff = null
			var/closest_fluid = null
			var/list/unwrapped_color = rgb2num(color_choice, COLORSPACE_HSV)
			var/chosen_hue = unwrapped_color[1]
			for (var/datum/reagent/luminescent_fluid/glowstick_fluid as anything in typesof(/datum/reagent/luminescent_fluid))
				unwrapped_color = rgb2num(glowstick_fluid::color, COLORSPACE_HSV)
				var/hue_diff = abs(chosen_hue - unwrapped_color[1])
				if (hue_diff > 180)
					hue_diff = 360 - hue_diff
				if (isnull(closest_diff) || hue_diff < closest_diff)
					closest_diff = hue_diff
					closest_fluid = glowstick_fluid
			var/obj/item/flashlight/glowstick/new_stick = new /obj/item/flashlight/glowstick(start, null, closest_fluid)
			new_stick.color = color_choice
			new_stick.set_light_color(new_stick.color)
			new_stick.throw_at(interacting_with, 9, 3, user)
			new_stick.turn_on()
			new_stick.update_brightness()
			return ITEM_INTERACT_SUCCESS

	return NONE

/obj/item/construction/rld/mini
	name = "mini-rapid-light-device"
	desc = "A device used to rapidly provide lighting sources to an area. Reload with iron, plasteel, glass or compressed matter cartridges."
	icon = 'icons/obj/tools.dmi'
	icon_state = "rld"
	lefthand_file = 'icons/mob/inhands/equipment/tools_lefthand.dmi'
	righthand_file = 'icons/mob/inhands/equipment/tools_righthand.dmi'
	matter = 100
	max_matter = 100

#undef LIGHT_TUBE_COST
#undef FLOOR_LIGHT_COST
#undef GLOW_STICK_COST
#undef DECONSTRUCT_COST

#undef BUILD_DELAY
#undef REMOVE_DELAY

#undef GLOW_MODE
#undef LIGHT_MODE
#undef REMOVE_MODE
