/datum/asset/spritesheet_batched/fish
	name = "fish"

/datum/asset/spritesheet_batched/fish/create_spritesheets()
	var/list/id_list = list()
	for (var/obj/item/fish/fish_type as anything in subtypesof(/obj/item/fish))
		var/fish_icon = initial(fish_type.icon)
		var/fish_icon_state = initial(fish_type.icon_state)
		var/id = sanitize_css_class_name("[fish_icon][fish_icon_state]")
		if(id in id_list) //no dupes
			continue
		id_list += id
		insert_icon(id, uni_icon(fish_icon, fish_icon_state))
