/datum/asset/spritesheet_batched/bibles
	name = "bibles"

/datum/asset/spritesheet_batched/bibles/create_spritesheets()
	var/obj/item/book/bible/holy_template = /obj/item/book/bible
	var/target_icon = initial(holy_template.icon)
	var/datum/icon_transformer/transform = new()
	transform.scale(224, 224) // Scale up by 7x

	for (var/icon_state_name in icon_states(target_icon))
		insert_icon("display-[icon_state_name]", uni_icon(target_icon, icon_state_name, transform=transform))
