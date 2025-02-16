/// Adds a newline to the examine list if the above entry is not empty and it is not the first element in the list
#define ADD_NEWLINE_IF_NECESSARY(list) if(length(list) > 0 && list[length(list)]) { list += "" }
#define CARBON_EXAMINE_EMBEDDING_MAX_DIST 4

/mob/living/carbon/human/get_examine_name(mob/user)
	if(!HAS_TRAIT(user, TRAIT_PROSOPAGNOSIA))
		return ..()

	return "Unknown"

/mob/living/carbon/human/get_examine_icon(mob/user)
	return null

/mob/living/carbon/examine(mob/user)
	if(HAS_TRAIT(src, TRAIT_UNKNOWN))
		return list(span_warning("You're struggling to make out any details..."))

	var/t_He = p_They()
	var/t_His = p_Their()
	var/t_his = p_their()
	var/t_him = p_them()
	var/t_has = p_have()
	var/t_is = p_are()

	. = list()
	. += get_clothing_examine_info(user)
	// give us some space between clothing examine and the rest
	ADD_NEWLINE_IF_NECESSARY(.)

	var/appears_dead = FALSE
	var/just_sleeping = FALSE

	if(!appears_alive())
		appears_dead = TRUE

		var/obj/item/clothing/glasses/shades = get_item_by_slot(ITEM_SLOT_EYES)
		var/are_we_in_weekend_at_bernies = shades?.tint && buckled && istype(buckled, /obj/vehicle/ridden/wheelchair)

		if(isliving(user) && (HAS_MIND_TRAIT(user, TRAIT_NAIVE) || are_we_in_weekend_at_bernies))
			just_sleeping = TRUE

		if(!just_sleeping)
			// since this is relatively important and giving it space makes it easier to read
			ADD_NEWLINE_IF_NECESSARY(.)
			if(HAS_TRAIT(src, TRAIT_SUICIDED))
				. += span_warning("[t_He] appear[p_s()] to have committed suicide... there is no hope of recovery.")

			. += generate_death_examine_text()

	//Status effects
	var/list/status_examines = get_status_effect_examinations()
	if (length(status_examines))
		. += status_examines

	if(get_bodypart(BODY_ZONE_HEAD) && !get_organ_by_type(/obj/item/organ/brain))
		. += span_deadsay("It appears that [t_his] brain is missing...")

	var/list/missing = list(BODY_ZONE_HEAD, BODY_ZONE_CHEST, BODY_ZONE_L_ARM, BODY_ZONE_R_ARM, BODY_ZONE_L_LEG, BODY_ZONE_R_LEG)
	var/list/disabled = list()
	for(var/obj/item/bodypart/body_part as anything in bodyparts)
		if(body_part.bodypart_disabled)
			disabled += body_part
		missing -= body_part.body_zone
		for(var/obj/item/embedded as anything in body_part.embedded_objects)
			var/harmless = embedded.get_embed().is_harmless()
			var/stuck_wordage = harmless ? "stuck to" : "embedded in"
			var/embed_line = "\a [embedded]"
			if (get_dist(src, user) <= CARBON_EXAMINE_EMBEDDING_MAX_DIST)
				embed_line = "<a href='byond://?src=[REF(src)];embedded_object=[REF(embedded)];embedded_limb=[REF(body_part)]'>\a [embedded]</a>"
			var/embed_text = "[t_He] [t_has] [icon2html(embedded, user)] [embed_line] [stuck_wordage] [t_his] [body_part.plaintext_zone]!"
			if (harmless)
				. += span_italics(span_notice(embed_text))
			else
				. += span_boldwarning(embed_text)

		for(var/datum/wound/iter_wound as anything in body_part.wounds)
			. += span_danger(iter_wound.get_examine_description(user))

	for(var/obj/item/bodypart/body_part as anything in disabled)
		var/damage_text
		if(HAS_TRAIT(body_part, TRAIT_DISABLED_BY_WOUND))
			continue // skip if it's disabled by a wound (cuz we'll be able to see the bone sticking out!)
		if(body_part.get_damage() < body_part.max_damage) //we don't care if it's stamcritted
			damage_text = "limp and lifeless"
		else
			damage_text = (body_part.brute_dam >= body_part.burn_dam) ? body_part.heavy_brute_msg : body_part.heavy_burn_msg
		. += span_boldwarning("[capitalize(t_his)] [body_part.plaintext_zone] is [damage_text]!")

	//stores missing limbs
	var/l_limbs_missing = 0
	var/r_limbs_missing = 0
	for(var/gone in missing)
		if(gone == BODY_ZONE_HEAD)
			. += span_deadsay("<B>[t_His] [parse_zone(gone)] is missing!</B>")
			continue
		if(gone == BODY_ZONE_L_ARM || gone == BODY_ZONE_L_LEG)
			l_limbs_missing++
		else if(gone == BODY_ZONE_R_ARM || gone == BODY_ZONE_R_LEG)
			r_limbs_missing++

		. += span_boldwarning("[capitalize(t_his)] [parse_zone(gone)] is missing!")

	if(l_limbs_missing >= 2 && r_limbs_missing == 0)
		. += span_tinydanger("[t_He] look[p_s()] all right now...")
	else if(l_limbs_missing == 0 && r_limbs_missing >= 2)
		. += span_tinydanger("[t_He] really keep[p_s()] to the left...")
	else if(l_limbs_missing >= 2 && r_limbs_missing >= 2)
		. += span_tinydanger("[t_He] [p_do()]n't seem all there...")

	if(!(user == src && has_status_effect(/datum/status_effect/grouped/screwy_hud/fake_healthy))) //fake healthy
		var/temp
		if(user == src && has_status_effect(/datum/status_effect/grouped/screwy_hud/fake_crit))//fake damage
			temp = 50
		else
			temp = getBruteLoss()
		var/list/damage_desc = get_majority_bodypart_damage_desc()
		if(temp)
			if(temp < 25)
				. += span_danger("[t_He] [t_has] minor [damage_desc[BRUTE]].")
			else if(temp < 50)
				. += span_danger("[t_He] [t_has] <b>moderate</b> [damage_desc[BRUTE]]!")
			else
				. += span_bolddanger("[t_He] [t_has] severe [damage_desc[BRUTE]]!")

		temp = getFireLoss()
		if(temp)
			if(temp < 25)
				. += span_danger("[t_He] [t_has] minor [damage_desc[BURN]].")
			else if (temp < 50)
				. += span_danger("[t_He] [t_has] <b>moderate</b> [damage_desc[BURN]]!")
			else
				. += span_bolddanger("[t_He] [t_has] severe [damage_desc[BURN]]!")

	if(pulledby?.grab_state)
		. += span_warning("[t_He] [t_is] restrained by [pulledby]'s grip.")

	if(nutrition < NUTRITION_LEVEL_STARVING - 50)
		. += span_warning("[t_He] [t_is] severely malnourished.")
	else if(nutrition >= NUTRITION_LEVEL_FAT)
		if(user.nutrition < NUTRITION_LEVEL_STARVING - 50)
			. += span_hypnophrase("[t_He] [t_is] plump and delicious looking - Like a fat little piggy. A tasty piggy.")
		else
			. += "<b>[t_He] [t_is] quite chubby.</b>"
	switch(disgust)
		if(DISGUST_LEVEL_GROSS to DISGUST_LEVEL_VERYGROSS)
			. += "[t_He] look[p_s()] a bit grossed out."
		if(DISGUST_LEVEL_VERYGROSS to DISGUST_LEVEL_DISGUSTED)
			. += "[t_He] look[p_s()] really grossed out."
		if(DISGUST_LEVEL_DISGUSTED to INFINITY)
			. += "[t_He] look[p_s()] extremely disgusted."

	var/apparent_blood_volume = blood_volume
	if(HAS_TRAIT(src, TRAIT_USES_SKINTONES) && ishuman(src))
		var/mob/living/carbon/human/husrc = src // gross istypesrc but easier than refactoring even further for now
		if(husrc.skin_tone == "albino")
			apparent_blood_volume -= (BLOOD_VOLUME_NORMAL * 0.25) // knocks you down a few pegs
	switch(apparent_blood_volume)
		if(BLOOD_VOLUME_OKAY to BLOOD_VOLUME_SAFE)
			. += span_warning("[t_He] [t_has] pale skin.")
		if(BLOOD_VOLUME_BAD to BLOOD_VOLUME_OKAY)
			. += span_boldwarning("[t_He] look[p_s()] like pale death.")
		if(-INFINITY to BLOOD_VOLUME_BAD)
			. += span_deadsay("<b>[t_He] resemble[p_s()] a crushed, empty juice pouch.</b>")

	if(is_bleeding())
		var/list/obj/item/bodypart/bleeding_limbs = list()
		var/list/obj/item/bodypart/grasped_limbs = list()

		for(var/obj/item/bodypart/body_part as anything in bodyparts)
			if(body_part.get_modified_bleed_rate())
				bleeding_limbs += body_part.plaintext_zone
			if(body_part.grasped_by)
				grasped_limbs += body_part.plaintext_zone

		if(LAZYLEN(bleeding_limbs))
			var/bleed_text = "<b>"
			if(appears_dead)
				bleed_text += "<span class='deadsay'>"
				bleed_text += "Blood is visible in [t_his] open "
			else
				bleed_text += "<span class='warning'>"
				bleed_text += "[t_He] [t_is] bleeding from [t_his] "

			bleed_text += english_list(bleeding_limbs, and_text = " and ")

			if(appears_dead)
				bleed_text += ", but it has pooled and is not flowing."
			else
				if(HAS_TRAIT(src, TRAIT_BLOODY_MESS))
					bleed_text += " incredibly quickly"
				bleed_text += "!"

			if(appears_dead)
				bleed_text += "<span class='deadsay'>"
			else
				bleed_text += "<span class='warning'>"
			bleed_text += "</b>"

			. += bleed_text
			if(LAZYLEN(grasped_limbs))
				for(var/grasped_part in grasped_limbs)
					. += "[t_He] [t_is] holding [t_his] [grasped_part] to slow the bleeding!"

	if(reagents.has_reagent(/datum/reagent/teslium, needs_metabolizing = TRUE))
		. += span_smallnoticeital("[t_He] [t_is] emitting a gentle blue glow!") // this should be signalized

	if(just_sleeping)
		. += span_notice("[t_He] [t_is]n't responding to anything around [t_him] and seem[p_s()] to be asleep.")

	else if(!appears_dead)
		var/mob/living/living_user = user
		if(src != user)
			if(HAS_TRAIT(user, TRAIT_EMPATH))
				if (combat_mode)
					. += "[t_He] seem[p_s()] to be on guard."
				if (getOxyLoss() >= 10)
					. += "[t_He] seem[p_s()] winded."
				if (getToxLoss() >= 10)
					. += "[t_He] seem[p_s()] sickly."
				if(mob_mood.sanity <= SANITY_DISTURBED)
					. += "[t_He] seem[p_s()] distressed."
					living_user.add_mood_event("empath", /datum/mood_event/sad_empath, src)
				if(is_blind())
					. += "[t_He] appear[p_s()] to be staring off into space."
				if (HAS_TRAIT(src, TRAIT_DEAF))
					. += "[t_He] appear[p_s()] to not be responding to noises."
				if (bodytemperature > dna.species.bodytemp_heat_damage_limit)
					. += "[t_He] [t_is] flushed and wheezing."
				if (bodytemperature < dna.species.bodytemp_cold_damage_limit)
					. += "[t_He] [t_is] shivering."
				if(HAS_TRAIT(src, TRAIT_EVIL))
					. += "[t_His] eyes radiate with a unfeeling, cold detachment. There is nothing but darkness within [t_his] soul."
					if(living_user.mind?.holy_role >= HOLY_ROLE_PRIEST)
						. += span_warning("PERFECT FOR SMITING!!")
					else
						living_user.add_mood_event("encountered_evil", /datum/mood_event/encountered_evil)
						living_user.set_jitter_if_lower(15 SECONDS)

			if(HAS_TRAIT(user, TRAIT_SPIRITUAL) && mind?.holy_role)
				. += "[t_He] [t_has] a holy aura about [t_him]."
				living_user.add_mood_event("religious_comfort", /datum/mood_event/religiously_comforted)

		switch(stat)
			if(UNCONSCIOUS, HARD_CRIT)
				. += span_notice("[t_He] [t_is]n't responding to anything around [t_him] and seem[p_s()] to be asleep.")
			if(SOFT_CRIT)
				. += span_notice("[t_He] [t_is] barely conscious.")
			if(CONSCIOUS)
				if(HAS_TRAIT(src, TRAIT_DUMB))
					. += "[t_He] [t_has] a stupid expression on [t_his] face."
		var/obj/item/organ/brain/brain = get_organ_by_type(/obj/item/organ/brain)
		if(brain && isnull(ai_controller))
			var/npc_message = ""
			if(HAS_TRAIT(brain, TRAIT_GHOSTROLE_ON_REVIVE))
				npc_message = "Soul is pending..."
			else if(!key)
				npc_message = "[t_He] [t_is] totally catatonic. The stresses of life in deep-space must have been too much for [t_him]. Any recovery is unlikely."
			else if(!client)
				npc_message ="[t_He] [t_has] a blank, absent-minded stare and appears completely unresponsive to anything. [t_He] may snap out of it soon."
			if(npc_message)
				// give some space since this is usually near the end
				ADD_NEWLINE_IF_NECESSARY(.)
				. += span_deadsay(npc_message)

	var/scar_severity = 0
	for(var/datum/scar/scar as anything in all_scars)
		if(scar.is_visible(user))
			scar_severity += scar.severity

	if(scar_severity >= 1)
		// give some space since this is even more usually near the end
		ADD_NEWLINE_IF_NECESSARY(.)
		switch(scar_severity)
			if(1 to 4)
				. += span_tinynoticeital("[t_He] [t_has] visible scarring, you can look again to take a closer look...")
			if(5 to 8)
				. += span_smallnoticeital("[t_He] [t_has] several bad scars, you can look again to take a closer look...")
			if(9 to 11)
				. += span_notice("<i>[t_He] [t_has] significantly disfiguring scarring, you can look again to take a closer look...</i>")
			if(12 to INFINITY)
				. += span_notice("<b><i>[t_He] [t_is] just absolutely fucked up, you can look again to take a closer look...</i></b>")

	if(HAS_TRAIT(src, TRAIT_HUSK))
		. += span_warning("This body has been reduced to a grotesque husk.")
	if(HAS_MIND_TRAIT(user, TRAIT_MORBID))
		if(HAS_TRAIT(src, TRAIT_DISSECTED))
			. += span_notice("[t_He] appear[p_s()] to have been dissected. Useless for examination... <b><i>for now.</i></b>")
		if(HAS_TRAIT(src, TRAIT_SURGICALLY_ANALYZED))
			. += span_notice("A skilled hand has mapped this one's internal intricacies. It will be far easier to perform future experimentations upon [user.p_them()]. <b><i>Exquisite.</i></b>")
	if(isliving(user) && HAS_MIND_TRAIT(user, TRAIT_EXAMINE_FITNESS))
		. += compare_fitness(user)

	var/hud_info = get_hud_examine_info(user)
	if(length(hud_info))
		. += hud_info

	if(isobserver(user))
		ADD_NEWLINE_IF_NECESSARY(.)
		. += "<b>Quirks:</b> [get_quirk_string(FALSE, CAT_QUIRK_ALL)]"

	SEND_SIGNAL(src, COMSIG_ATOM_EXAMINE, user, .)
	if(length(.))
		.[1] = "<span class='info'>" + .[1]
		.[length(.)] += "</span>"
	return .

/mob/living/carbon/examine_more(mob/user)
	. = ..()
	if(HAS_TRAIT(src, TRAIT_INVISIBLE_MAN))
		return
	for(var/datum/scar/iter_scar as anything in all_scars)
		if(iter_scar.is_visible(user))
			. += iter_scar.get_examine_description(user)

/**
 * Shows any and all examine text related to any status effects the user has.
 */
/mob/living/proc/get_status_effect_examinations()
	var/list/examine_list = list()

	for(var/datum/status_effect/effect as anything in status_effects)
		var/effect_text = effect.get_examine_text()
		if(!effect_text)
			continue

		examine_list += effect_text

	if(!length(examine_list))
		return

	return examine_list.Join("<br>")

/// Returns death message for mob examine text
/mob/living/carbon/proc/generate_death_examine_text()
	var/mob/dead/observer/ghost = get_ghost(TRUE, TRUE)
	var/t_He = p_They()
	var/t_his = p_their()
	var/t_is = p_are()
	//This checks to see if the body is revivable
	var/obj/item/organ/brain = get_organ_by_type(/obj/item/organ/brain)
	if(brain && HAS_TRAIT(brain, TRAIT_GHOSTROLE_ON_REVIVE))
		return span_deadsay("[t_He] [t_is] limp and unresponsive; but [t_his] soul might yet come back...")
	var/client_like = client || HAS_TRAIT(src, TRAIT_MIND_TEMPORARILY_GONE)
	var/valid_ghost = ghost?.can_reenter_corpse && ghost?.client
	var/valid_soul = brain || !HAS_TRAIT(src, TRAIT_FAKE_SOULLESS)
	if((brain && client_like) || (valid_ghost && valid_soul))
		return span_deadsay("[t_He] [t_is] limp and unresponsive; there are no signs of life...")
	return span_deadsay("[t_He] [t_is] limp and unresponsive; there are no signs of life and [t_his] soul has departed...")

/// Returns a list of "damtype" => damage description based off of which bodypart description is most common
/mob/living/carbon/proc/get_majority_bodypart_damage_desc()
	var/list/seen_damage = list() // This looks like: ({Damage type} = list({Damage description for that damage type} = {number of times it has appeared}, ...), ...)
	var/list/most_seen_damage = list() // This looks like: ({Damage type} = {Frequency of the most common description}, ...)
	var/list/final_descriptions = list() // This looks like: ({Damage type} = {Most common damage description for that type}, ...)
	for(var/obj/item/bodypart/part as anything in bodyparts)
		for(var/damage_type in part.damage_examines)
			var/damage_desc = part.damage_examines[damage_type]
			if(!seen_damage[damage_type])
				seen_damage[damage_type] = list()

			if(!seen_damage[damage_type][damage_desc])
				seen_damage[damage_type][damage_desc] = 1
			else
				seen_damage[damage_type][damage_desc] += 1

			if(seen_damage[damage_type][damage_desc] > most_seen_damage[damage_type])
				most_seen_damage[damage_type] = seen_damage[damage_type][damage_desc]
				final_descriptions[damage_type] = damage_desc
	return final_descriptions

/// Coolects examine information about the mob's clothing and equipment
/mob/living/carbon/proc/get_clothing_examine_info(mob/living/user)
	. = list()
	var/obscured = check_obscured_slots()
	var/t_He = p_They()
	var/t_His = p_Their()
	var/t_his = p_their()
	var/t_has = p_have()
	var/t_is = p_are()
	//head
	if(head && !(obscured & ITEM_SLOT_HEAD) && !HAS_TRAIT(head, TRAIT_EXAMINE_SKIP))
		. += "[t_He] [t_is] wearing [head.examine_title(user)] on [t_his] head."
	//back
	if(back && !HAS_TRAIT(back, TRAIT_EXAMINE_SKIP))
		. += "[t_He] [t_has] [back.examine_title(user)] on [t_his] back."
	//Hands
	for(var/obj/item/held_thing in held_items)
		if((held_thing.item_flags & (ABSTRACT|HAND_ITEM)) || HAS_TRAIT(held_thing, TRAIT_EXAMINE_SKIP))
			continue
		. += "[t_He] [t_is] holding [held_thing.examine_title(user)] in [t_his] [get_held_index_name(get_held_index_of_item(held_thing))]."
	//gloves
	if(gloves && !(obscured & ITEM_SLOT_GLOVES) && !HAS_TRAIT(gloves, TRAIT_EXAMINE_SKIP))
		. += "[t_He] [t_has] [gloves.examine_title(user)] on [t_his] hands."
	else if(GET_ATOM_BLOOD_DNA_LENGTH(src))
		if(num_hands)
			. += span_warning("[t_He] [t_has] [num_hands > 1 ? "" : "a "]blood-stained hand[num_hands > 1 ? "s" : ""]!")
	//handcuffed?
	if(handcuffed)
		var/cables_or_cuffs = istype(handcuffed, /obj/item/restraints/handcuffs/cable) ? "restrained with cable" : "handcuffed"
		. += span_warning("[t_He] [t_is] [icon2html(handcuffed, user)] [cables_or_cuffs]!")
	//shoes
	if(shoes && !(obscured & ITEM_SLOT_FEET)  && !HAS_TRAIT(shoes, TRAIT_EXAMINE_SKIP))
		. += "[t_He] [t_is] wearing [shoes.examine_title(user)] on [t_his] feet."
	//mask
	if(wear_mask && !(obscured & ITEM_SLOT_MASK)  && !HAS_TRAIT(wear_mask, TRAIT_EXAMINE_SKIP))
		. += "[t_He] [t_has] [wear_mask.examine_title(user)] on [t_his] face."
	if(wear_neck && !(obscured & ITEM_SLOT_NECK)  && !HAS_TRAIT(wear_neck, TRAIT_EXAMINE_SKIP))
		. += "[t_He] [t_is] wearing [wear_neck.examine_title(user)] around [t_his] neck."
	//eyes
	if(!(obscured & ITEM_SLOT_EYES) )
		if(glasses  && !HAS_TRAIT(glasses, TRAIT_EXAMINE_SKIP))
			. += "[t_He] [t_has] [glasses.examine_title(user)] covering [t_his] eyes."
		else if(HAS_TRAIT(src, TRAIT_UNNATURAL_RED_GLOWY_EYES))
			. += span_warning("<B>[t_His] eyes are glowing with an unnatural red aura!</B>")
		else if(HAS_TRAIT(src, TRAIT_BLOODSHOT_EYES))
			. += span_warning("<B>[t_His] eyes are bloodshot!</B>")
	//ears
	if(ears && !(obscured & ITEM_SLOT_EARS) && !HAS_TRAIT(ears, TRAIT_EXAMINE_SKIP))
		. += "[t_He] [t_has] [ears.examine_title(user)] on [t_his] ears."

// Yes there's a lot of copypasta here, we can improve this later when carbons are less dumb in general
/mob/living/carbon/human/get_clothing_examine_info(mob/living/user)
	. = list()
	var/obscured = check_obscured_slots()
	var/t_He = p_They()
	var/t_His = p_Their()
	var/t_his = p_their()
	var/t_has = p_have()
	var/t_is = p_are()

	//uniform
	if(w_uniform && !(obscured & ITEM_SLOT_ICLOTHING) && !HAS_TRAIT(w_uniform, TRAIT_EXAMINE_SKIP))
		//accessory
		var/accessory_message = ""
		if(istype(w_uniform, /obj/item/clothing/under))
			var/obj/item/clothing/under/undershirt = w_uniform
			var/list/accessories = undershirt.list_accessories_with_icon(user)
			if(length(accessories))
				accessory_message = " with [english_list(accessories)] attached"

		. += "[t_He] [t_is] wearing [w_uniform.examine_title(user)][accessory_message]."
	//head
	if(head && !(obscured & ITEM_SLOT_HEAD) && !HAS_TRAIT(head, TRAIT_EXAMINE_SKIP))
		. += "[t_He] [t_is] wearing [head.examine_title(user)] on [t_his] head."
	//mask
	if(wear_mask && !(obscured & ITEM_SLOT_MASK)  && !HAS_TRAIT(wear_mask, TRAIT_EXAMINE_SKIP))
		. += "[t_He] [t_has] [wear_mask.examine_title(user)] on [t_his] face."
	//neck
	if(wear_neck && !(obscured & ITEM_SLOT_NECK)  && !HAS_TRAIT(wear_neck, TRAIT_EXAMINE_SKIP))
		. += "[t_He] [t_is] wearing [wear_neck.examine_title(user)] around [t_his] neck."
	//eyes
	if(!(obscured & ITEM_SLOT_EYES) )
		if(glasses  && !HAS_TRAIT(glasses, TRAIT_EXAMINE_SKIP))
			. += "[t_He] [t_has] [glasses.examine_title(user)] covering [t_his] eyes."
		else if(HAS_TRAIT(src, TRAIT_UNNATURAL_RED_GLOWY_EYES))
			. += span_warning("<B>[t_His] eyes are glowing with an unnatural red aura!</B>")
		else if(HAS_TRAIT(src, TRAIT_BLOODSHOT_EYES))
			. += span_warning("<B>[t_His] eyes are bloodshot!</B>")
	//ears
	if(ears && !(obscured & ITEM_SLOT_EARS) && !HAS_TRAIT(ears, TRAIT_EXAMINE_SKIP))
		. += "[t_He] [t_has] [ears.examine_title(user)] on [t_his] ears."
	//suit/armor
	if(wear_suit && !HAS_TRAIT(wear_suit, TRAIT_EXAMINE_SKIP))
		. += "[t_He] [t_is] wearing [wear_suit.examine_title(user)]."
		//suit/armor storage
		if(s_store && !(obscured & ITEM_SLOT_SUITSTORE) && !HAS_TRAIT(s_store, TRAIT_EXAMINE_SKIP))
			. += "[t_He] [t_is] carrying [s_store.examine_title(user)] on [t_his] [wear_suit.name]."
	//back
	if(back && !HAS_TRAIT(back, TRAIT_EXAMINE_SKIP))
		. += "[t_He] [t_has] [back.examine_title(user)] on [t_his] back."
	//ID
	if(wear_id && !HAS_TRAIT(wear_id, TRAIT_EXAMINE_SKIP))
		var/obj/item/card/id/id = wear_id.GetID()
		if(id && get_dist(user, src) <= ID_EXAMINE_DISTANCE)
			var/id_href = "<a href='byond://?src=[REF(src)];see_id=1;id_ref=[REF(id)];id_name=[id.registered_name];examine_time=[world.time]'>[wear_id.examine_title(user)]</a>"
			. += "[t_He] [t_is] wearing [id_href]."

		else
			. += "[t_He] [t_is] wearing [wear_id.examine_title(user)]."
	//Hands
	for(var/obj/item/held_thing in held_items)
		if((held_thing.item_flags & (ABSTRACT|HAND_ITEM)) || HAS_TRAIT(held_thing, TRAIT_EXAMINE_SKIP))
			continue
		. += "[t_He] [t_is] holding [held_thing.examine_title(user)] in [t_his] [get_held_index_name(get_held_index_of_item(held_thing))]."
	//gloves
	if(gloves && !(obscured & ITEM_SLOT_GLOVES) && !HAS_TRAIT(gloves, TRAIT_EXAMINE_SKIP))
		. += "[t_He] [t_has] [gloves.examine_title(user)] on [t_his] hands."
	else if(GET_ATOM_BLOOD_DNA_LENGTH(src) || blood_in_hands)
		if(num_hands)
			. += span_warning("[t_He] [t_has] [num_hands > 1 ? "" : "a "]blood-stained hand[num_hands > 1 ? "s" : ""]!")
	//handcuffed?
	if(handcuffed)
		var/cables_or_cuffs = istype(handcuffed, /obj/item/restraints/handcuffs/cable) ? "restrained with cable" : "handcuffed"
		. += span_warning("[t_He] [t_is] [icon2html(handcuffed, user)] [cables_or_cuffs]!")
	//belt
	if(belt && !(obscured & ITEM_SLOT_BELT) && !HAS_TRAIT(belt, TRAIT_EXAMINE_SKIP))
		. += "[t_He] [t_has] [belt.examine_title(user)] about [t_his] waist."
	//shoes
	if(shoes && !(obscured & ITEM_SLOT_FEET)  && !HAS_TRAIT(shoes, TRAIT_EXAMINE_SKIP))
		. += "[t_He] [t_is] wearing [shoes.examine_title(user)] on [t_his] feet."

/// Collects info displayed about any HUDs the user has when examining src
/mob/living/carbon/proc/get_hud_examine_info(mob/living/user)
	return

/mob/living/carbon/human/get_hud_examine_info(mob/living/user)
	. = list()

	var/perpname = get_face_name(get_id_name(""))
	var/title = ""
	if(perpname && (HAS_TRAIT(user, TRAIT_SECURITY_HUD) || HAS_TRAIT(user, TRAIT_MEDICAL_HUD)) && (user.stat == CONSCIOUS || isobserver(user)) && user != src)
		var/datum/record/crew/target_record = find_record(perpname)
		if(target_record)
			. += "Rank: [target_record.rank]"
			. += "<a href='byond://?src=[REF(src)];hud=1;photo_front=1;examine_time=[world.time]'>\[Front photo\]</a><a href='byond://?src=[REF(src)];hud=1;photo_side=1;examine_time=[world.time]'>\[Side photo\]</a>"
		if(HAS_TRAIT(user, TRAIT_MEDICAL_HUD) && HAS_TRAIT(user, TRAIT_SECURITY_HUD))
			title = separator_hr("Medical & Security Analysis")
			. += get_medhud_examine_info(user, target_record)
			. += get_sechud_examine_info(user, target_record)

		else if(HAS_TRAIT(user, TRAIT_MEDICAL_HUD))
			title = separator_hr("Medical Analysis")
			. += get_medhud_examine_info(user, target_record)

		else if(HAS_TRAIT(user, TRAIT_SECURITY_HUD))
			title = separator_hr("Security Analysis")
			. += get_sechud_examine_info(user, target_record)

	// applies the separator correctly without an extra line break
	if(title && length(.))
		.[1] = title + .[1]
	return .

/// Collects information displayed about src when examined by a user with a medical HUD.
/mob/living/carbon/proc/get_medhud_examine_info(mob/living/user, datum/record/crew/target_record)
	. = list()

	var/list/cybers = list()
	for(var/obj/item/organ/cyberimp/cyberimp in organs)
		if(IS_ROBOTIC_ORGAN(cyberimp) && !(cyberimp.organ_flags & ORGAN_HIDDEN))
			cybers += cyberimp.examine_title(user)
	if(length(cybers))
		. += "<span class='notice ml-1'>Detected cybernetic modifications:</span>"
		. += "<span class='notice ml-2'>[english_list(cybers, and_text = ", and")]</span>"
	if(target_record)
		. += "<a href='byond://?src=[REF(src)];hud=m;physical_status=1;examine_time=[world.time]'>\[[target_record.physical_status]\]</a>"
		. += "<a href='byond://?src=[REF(src)];hud=m;mental_status=1;examine_time=[world.time]'>\[[target_record.mental_status]\]</a>"
	else
		. += "\[Record Missing\]"
		. += "\[Record Missing\]"
	. += "<a href='byond://?src=[REF(src)];hud=m;evaluation=1;examine_time=[world.time]'>\[Medical evaluation\]</a>"
	. += "<a href='byond://?src=[REF(src)];hud=m;quirk=1;examine_time=[world.time]'>\[See quirks\]</a>"

/// Collects information displayed about src when examined by a user with a security HUD.
/mob/living/carbon/proc/get_sechud_examine_info(mob/living/user, datum/record/crew/target_record)
	. = list()

	var/wanted_status = WANTED_NONE
	var/security_note = "None."

	if(target_record)
		wanted_status = target_record.wanted_status
		if(target_record.security_note)
			security_note = target_record.security_note
	if(ishuman(user))
		. += "Criminal status: <a href='byond://?src=[REF(src)];hud=s;status=1;examine_time=[world.time]'>\[[wanted_status]\]</a>"
	else
		. += "Criminal status: [wanted_status]"
	. += "Important Notes: [security_note]"
	. += "Security record: <a href='byond://?src=[REF(src)];hud=s;view=1;examine_time=[world.time]'>\[View\]</a>"
	if(ishuman(user))
		. += "<a href='byond://?src=[REF(src)];hud=s;add_citation=1;examine_time=[world.time]'>\[Add citation\]</a>\
			<a href='byond://?src=[REF(src)];hud=s;add_crime=1;examine_time=[world.time]'>\[Add crime\]</a>\
			<a href='byond://?src=[REF(src)];hud=s;add_note=1;examine_time=[world.time]'>\[Add note\]</a>"

/mob/living/carbon/human/examine_more(mob/user)
	. = ..()

	if(istype(w_uniform, /obj/item/clothing/under) && !(check_obscured_slots() & ITEM_SLOT_ICLOTHING) && !HAS_TRAIT(w_uniform, TRAIT_EXAMINE_SKIP))
		var/obj/item/clothing/under/undershirt = w_uniform
		if(undershirt.has_sensor == BROKEN_SENSORS)
			. += list(span_notice("\The [undershirt]'s medical sensors are sparking."))

	if(HAS_TRAIT(src, TRAIT_UNKNOWN) || HAS_TRAIT(src, TRAIT_INVISIBLE_MAN))
		return

	if((wear_mask && (wear_mask.flags_inv & HIDEFACE)) || (head && (head.flags_inv & HIDEFACE)))
		return

	var/age_text
	switch(age)
		if(-INFINITY to 25)
			age_text = "very young"
		if(26 to 35)
			age_text = "of adult age"
		if(36 to 55)
			age_text = "middle-aged"
		if(56 to 75)
			age_text = "rather old"
		if(76 to 100)
			age_text = "very old"
		if(101 to INFINITY)
			age_text = "withering away"
	. += list(span_notice("[p_They()] appear[p_s()] to be [age_text]."))

#undef ADD_NEWLINE_IF_NECESSARY
#undef CARBON_EXAMINE_EMBEDDING_MAX_DIST
