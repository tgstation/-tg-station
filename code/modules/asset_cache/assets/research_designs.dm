// Representative icons for each research design
/datum/asset/spritesheet_batched/research_designs
	name = "design"

/datum/asset/spritesheet_batched/research_designs/create_spritesheets()
	for (var/datum/design/path as anything in subtypesof(/datum/design))
		if(initial(path.id) == DESIGN_ID_IGNORE)
			continue

		var/icon_file
		var/icon_state
		var/datum/icon_transformer/transform = null

		if(initial(path.research_icon) && initial(path.research_icon_state)) //If the design has an icon replacement skip the rest
			icon_file = initial(path.research_icon)
			icon_state = initial(path.research_icon_state)
			if (PERFORM_ALL_TESTS(focus_only/invalid_research_designs))
				if(!icon_exists(icon_file, icon_state))
					stack_trace("design [path] with icon '[icon_file]' missing state '[icon_state]'")
					continue
		else
			// construct the icon and slap it into the resource cache
			var/atom/item = initial(path.build_path)
			if (!ispath(item, /atom))
				// biogenerator reagent designs display their default container
				if(initial(path.make_reagent))
					var/datum/reagent/reagent = initial(path.make_reagent)
					item = initial(reagent.default_container)
				else
					continue  // shouldn't happen, but just in case

			// circuit boards become their resulting machines or computers
			if (ispath(item, /obj/item/circuitboard))
				var/obj/item/circuitboard/C = item
				var/machine = initial(C.build_path)
				if (machine)
					item = machine

			// GAGS icon short-circuit the rest of the checks
			if (initial(item.greyscale_config) && initial(item.greyscale_colors))
				insert_icon(initial(path.id), gags_to_universal_icon(item))
				continue
			else
				icon_file = initial(item.icon)

			icon_state = initial(item.icon_state)
			if(initial(item.color))
				transform = color_transform(initial(item.color))
			if (PERFORM_ALL_TESTS(focus_only/invalid_research_designs))
				if(!icon_exists(icon_file, icon_state))
					stack_trace("design [path] with icon '[icon_file]' missing state '[icon_state]'")
					continue

			// computers (and snowflakes) get their screen and keyboard sprites
			if (ispath(item, /obj/machinery/computer) || ispath(item, /obj/machinery/power/solar_control))
				if(!transform)
					transform = new()
				var/obj/machinery/computer/C = item
				var/screen = initial(C.icon_screen)
				var/keyboard = initial(C.icon_keyboard)
				var/all_states = icon_states(icon_file)
				if (screen && (screen in all_states))
					transform.blend_icon(uni_icon(icon_file, screen), ICON_OVERLAY)
				if (keyboard && (keyboard in all_states))
					transform.blend_icon(uni_icon(icon_file, keyboard), ICON_OVERLAY)

		insert_icon(initial(path.id), uni_icon(icon_file, icon_state, transform=transform))
