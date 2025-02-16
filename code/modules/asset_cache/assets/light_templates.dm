/datum/asset/spritesheet_batched/lights
	name = "lights"

/datum/asset/spritesheet_batched/lights/create_spritesheets()
	for(var/id in GLOB.light_types)
		var/datum/light_template/template = GLOB.light_types[id]
		insert_icon("light_fantastic_[template.id]", uni_icon(template.icon, template.icon_state))
