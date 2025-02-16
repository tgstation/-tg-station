/datum/asset/spritesheet_batched/seeds
	name = "seeds"

/datum/asset/spritesheet_batched/seeds/create_spritesheets()
	var/list/id_list = list()
	for (var/obj/item/seeds/seed_type as anything in subtypesof(/obj/item/seeds))
		var/icon = initial(seed_type.icon)
		var/icon_state = initial(seed_type.icon_state)
		var/id = sanitize_css_class_name("[icon][icon_state]")
		if(id in id_list) //no dupes
			continue
		id_list += id
		insert_icon(id, uni_icon(icon, icon_state))
