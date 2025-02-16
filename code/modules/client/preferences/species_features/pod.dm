/datum/preference/choiced/pod_hair
	savefile_key = "feature_pod_hair"
	savefile_identifier = PREFERENCE_CHARACTER
	category = PREFERENCE_CATEGORY_FEATURES
	main_feature_name = "Hairstyle"
	should_generate_icons = TRUE

/datum/preference/choiced/pod_hair/init_possible_values()
	return assoc_to_keys_features(SSaccessories.pod_hair_list)

/datum/preference/choiced/pod_hair/icon_for(value)
	var/datum/sprite_accessory/pod_hair = SSaccessories.pod_hair_list[value]

	var/datum/universal_icon/icon_with_hair = uni_icon('icons/mob/human/bodyparts_greyscale.dmi', "pod_head_m")

	var/datum/universal_icon/icon_adj = uni_icon(pod_hair.icon, "m_pod_hair_[pod_hair.icon_state]_ADJ")
	var/datum/universal_icon/icon_front = uni_icon(pod_hair.icon, "m_pod_hair_[pod_hair.icon_state]_FRONT")
	icon_adj.blend_icon(icon_front, ICON_OVERLAY)
	icon_with_hair.blend_icon(icon_adj, ICON_OVERLAY)
	icon_with_hair.scale(64, 64)
	icon_with_hair.crop(15, 64 - 31, 15 + 31, 64)
	icon_with_hair.blend_color(COLOR_GREEN, ICON_MULTIPLY)

	return icon_with_hair

/datum/preference/choiced/pod_hair/create_default_value()
	return pick(assoc_to_keys_features(SSaccessories.pod_hair_list))

/datum/preference/choiced/pod_hair/apply_to_human(mob/living/carbon/human/target, value)
	target.dna.features["pod_hair"] = value
