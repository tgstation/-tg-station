/datum/action/cooldown/dagger_swing
	name = "Dagger swing"
	desc = "Swing your daggers around."
	button_icon = 'icons/obj/mining_zones/artefacts.dmi'
	button_icon_state = "cain_and_abel"
	background_icon_state = "bg_default"
	overlay_icon_state = "bg_default_border"
	cooldown_time = 20 SECONDS

/datum/action/cooldown/dagger_swing/Activate(atom/target_atom)
	. = ..()
	var/mob/living/living_owner = owner
	living_owner.apply_status_effect(/datum/status_effect/dagger_swinging)

	var/static/list/possible_sounds = list(
		'sound/items/weapons/cain_and_abel/dagger_slash_1.ogg',
		'sound/items/weapons/cain_and_abel/dagger_slash_2.ogg',
		'sound/items/weapons/cain_and_abel/dagger_slash_3.ogg',
		'sound/items/weapons/cain_and_abel/dagger_slash_4.ogg',
		'sound/items/weapons/cain_and_abel/dagger_slash_5.ogg',
		'sound/items/weapons/cain_and_abel/dagger_slash_6.ogg',
	)

	var/list/sounds_to_pick_from = possible_sounds.Copy()
	for(var/index in 0 to 5)
		addtimer(CALLBACK(GLOBAL_PROC, GLOBAL_PROC_REF(playsound), owner, pick_n_take(sounds_to_pick_from), 65, TRUE), 0.15 SECONDS * index)
