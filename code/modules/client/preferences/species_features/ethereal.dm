/datum/preference/choiced/ethereal_color
	savefile_key = "feature_ethcolor"
	savefile_identifier = PREFERENCE_CHARACTER
	category = PREFERENCE_CATEGORY_FEATURES
	main_feature_name = "Ethereal color"
	should_generate_icons = TRUE

/datum/preference/choiced/ethereal_color/init_possible_values()
	return assoc_to_keys(GLOB.color_list_ethereal)

/datum/preference/choiced/ethereal_color/icon_for(value)
	var/static/datum/universal_icon/ethereal_base
	if (isnull(ethereal_base))
		ethereal_base = uni_icon('icons/mob/human/species/ethereal/bodyparts.dmi', "ethereal_head")
		ethereal_base.blend_icon(uni_icon('icons/mob/human/species/ethereal/bodyparts.dmi', "ethereal_chest"), ICON_OVERLAY)
		ethereal_base.blend_icon(uni_icon('icons/mob/human/species/ethereal/bodyparts.dmi', "ethereal_l_arm"), ICON_OVERLAY)
		ethereal_base.blend_icon(uni_icon('icons/mob/human/species/ethereal/bodyparts.dmi', "ethereal_r_arm"), ICON_OVERLAY)

		var/datum/universal_icon/eyes = uni_icon('icons/mob/human/human_face.dmi', "eyes_l")
		eyes.blend_icon(uni_icon('icons/mob/human/human_face.dmi', "eyes_r"), ICON_OVERLAY)
		eyes.blend_color(COLOR_BLACK, ICON_MULTIPLY)
		ethereal_base.blend_icon(eyes, ICON_OVERLAY)

		ethereal_base.scale(64, 64)
		ethereal_base.crop(15, 64 - 31, 15 + 31, 64)

	var/datum/universal_icon/icon = ethereal_base.copy()
	icon.blend_color(GLOB.color_list_ethereal[value], ICON_MULTIPLY)
	return icon

/datum/preference/choiced/ethereal_color/apply_to_human(mob/living/carbon/human/target, value)
	target.dna.features["ethcolor"] = GLOB.color_list_ethereal[value]
