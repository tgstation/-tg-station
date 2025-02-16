/datum/asset/spritesheet_batched/rtd
	name = "rtd"

/datum/asset/spritesheet_batched/rtd/create_spritesheets()
	var/list/registered = list()

	for(var/main_root in GLOB.floor_designs)
		for(var/sub_category in GLOB.floor_designs[main_root])
			for(var/list/design in  GLOB.floor_designs[main_root][sub_category])
				var/obj/item/stack/tile/type = design["type"]
				var/icon_state = initial(type.icon_state)
				if(registered[icon_state])
					continue

				insert_icon(icon_state, uni_icon('icons/obj/tiles.dmi', icon_state))
				registered[icon_state] = TRUE

				var/list/tile_directions = design["tile_rotate_dirs"]
				if(tile_directions == null)
					continue

				for(var/direction as anything in tile_directions)
					//we can rotate the icon is css for these directions
					if(direction in GLOB.tile_dont_rotate)
						continue

					insert_icon("[icon_state]-[dir2text(direction)]", uni_icon('icons/obj/tiles.dmi', icon_state, direction))
