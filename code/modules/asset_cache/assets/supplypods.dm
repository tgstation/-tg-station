/datum/asset/spritesheet_batched/supplypods
	name = "supplypods"

/datum/asset/spritesheet_batched/supplypods/create_spritesheets()
	for (var/datum/pod_style/style as anything in typesof(/datum/pod_style))
		if (ispath(style, /datum/pod_style/seethrough))
			insert_icon("pod_asset[style::id]", uni_icon('icons/obj/supplypods.dmi' , "seethrough-icon"))
			continue
		var/base = style::icon_state
		if (!base)
			insert_icon("pod_asset[style::id]", uni_icon('icons/obj/supplypods.dmi', "invisible-icon"))
			continue
		var/datum/universal_icon/pod_icon = uni_icon('icons/obj/supplypods.dmi', base, SOUTH)
		var/door = style::has_door
		if (door)
			door = "[base]_door"
			pod_icon.blend_icon(uni_icon('icons/obj/supplypods.dmi', door), ICON_OVERLAY)
		var/shape = style::shape
		if (shape == POD_SHAPE_NORMAL)
			var/decal = style::decal_icon
			if (decal)
				pod_icon.blend_icon(uni_icon('icons/obj/supplypods.dmi', decal), ICON_OVERLAY)
			var/glow = style::glow_color
			if (glow)
				glow = "pod_glow_[glow]"
				pod_icon.blend_icon(uni_icon('icons/obj/supplypods.dmi', glow), ICON_OVERLAY)
		insert_icon("pod_asset[style::id]", pod_icon)
