//Largely beneficial effects go here, even if they have drawbacks.

/datum/status_effect/his_grace
	id = "his_grace"
	duration = STATUS_EFFECT_PERMANENT
	tick_interval = 0.4 SECONDS
	alert_type = /atom/movable/screen/alert/status_effect/his_grace
	var/bloodlust = 0

/atom/movable/screen/alert/status_effect/his_grace
	name = "His Grace"
	desc = "His Grace hungers, and you must feed Him."
	icon_state = "his_grace"
	alerttooltipstyle = "hisgrace"

/atom/movable/screen/alert/status_effect/his_grace/MouseEntered(location,control,params)
	desc = initial(desc)
	var/datum/status_effect/his_grace/HG = attached_effect
	desc += "<br><font size=3><b>Current Bloodthirst: [HG.bloodlust]</b></font>\
	<br>Becomes undroppable at <b>[HIS_GRACE_FAMISHED]</b>\
	<br>Will consume you at <b>[HIS_GRACE_CONSUME_OWNER]</b>"
	return ..()

/datum/status_effect/his_grace/on_apply()
	owner.add_stun_absorption(
		source = id,
		priority = 3,
		self_message = span_boldwarning("His Grace protects you from the stun!"),
	)
	return ..()

/datum/status_effect/his_grace/on_remove()
	owner.remove_stun_absorption(id)

/datum/status_effect/his_grace/tick(seconds_between_ticks)
	bloodlust = 0
	var/graces = 0
	for(var/obj/item/his_grace/HG in owner.held_items)
		if(HG.bloodthirst > bloodlust)
			bloodlust = HG.bloodthirst
		if(HG.awakened)
			graces++
	if(!graces)
		owner.apply_status_effect(/datum/status_effect/his_wrath)
		qdel(src)
		return
	var/grace_heal = bloodlust * 0.02
	var/need_mob_update = FALSE
	need_mob_update += owner.adjustBruteLoss(-grace_heal * seconds_between_ticks, updating_health = FALSE, forced = TRUE)
	need_mob_update += owner.adjustFireLoss(-grace_heal * seconds_between_ticks, updating_health = FALSE, forced = TRUE)
	need_mob_update += owner.adjustToxLoss(-grace_heal * seconds_between_ticks, forced = TRUE)
	need_mob_update += owner.adjustOxyLoss(-(grace_heal * 2) * seconds_between_ticks, updating_health = FALSE, forced = TRUE)
	if(need_mob_update)
		owner.updatehealth()

/datum/status_effect/wish_granters_gift //Fully revives after ten seconds.
	id = "wish_granters_gift"
	duration = 50
	alert_type = /atom/movable/screen/alert/status_effect/wish_granters_gift

/datum/status_effect/wish_granters_gift/on_apply()
	to_chat(owner, span_notice("Death is not your end! The Wish Granter's energy suffuses you, and you begin to rise..."))
	return ..()

/datum/status_effect/wish_granters_gift/on_remove()
	owner.revive(ADMIN_HEAL_ALL)
	owner.visible_message(span_warning("[owner] appears to wake from the dead, having healed all wounds!"), span_notice("You have regenerated."))


/atom/movable/screen/alert/status_effect/wish_granters_gift
	name = "Wish Granter's Immortality"
	desc = "You are being resurrected!"
	icon_state = "wish_granter"

/datum/status_effect/blooddrunk
	id = "blooddrunk"
	duration = 10
	tick_interval = STATUS_EFFECT_NO_TICK
	alert_type = /atom/movable/screen/alert/status_effect/blooddrunk

/atom/movable/screen/alert/status_effect/blooddrunk
	name = "Blood-Drunk"
	desc = "You are drunk on blood! Your pulse thunders in your ears! Nothing can harm you!" //not true, and the item description mentions its actual effect
	icon_state = "blooddrunk"

/datum/status_effect/blooddrunk/on_apply()
	owner.add_movespeed_mod_immunities(id, /datum/movespeed_modifier/damage_slowdown)
	if(ishuman(owner))
		var/mob/living/carbon/human/human_owner = owner
		human_owner.physiology.brute_mod *= 0.1
		human_owner.physiology.burn_mod *= 0.1
		human_owner.physiology.tox_mod *= 0.1
		human_owner.physiology.oxy_mod *= 0.1
		human_owner.physiology.stamina_mod *= 0.1
	owner.add_stun_absorption(source = id, priority = 4)
	owner.playsound_local(get_turf(owner), 'sound/effects/singlebeat.ogg', 40, 1, use_reverb = FALSE)
	return TRUE

/datum/status_effect/blooddrunk/on_remove()
	if(ishuman(owner))
		var/mob/living/carbon/human/human_owner = owner
		human_owner.physiology.brute_mod *= 10
		human_owner.physiology.burn_mod *= 10
		human_owner.physiology.tox_mod *= 10
		human_owner.physiology.oxy_mod *= 10
		human_owner.physiology.stamina_mod *= 10
	owner.remove_movespeed_mod_immunities(id, /datum/movespeed_modifier/damage_slowdown)
	owner.remove_stun_absorption(id)

//Used by changelings to rapidly heal
//Heals 10 brute and oxygen damage every second, and 5 fire
//Being on fire will suppress this healing
/datum/status_effect/fleshmend
	id = "fleshmend"
	duration = 10 SECONDS
	alert_type = /atom/movable/screen/alert/status_effect/fleshmend
	show_duration = TRUE

/datum/status_effect/fleshmend/on_apply()
	. = ..()
	if(iscarbon(owner))
		var/mob/living/carbon/carbon_owner = owner
		QDEL_LAZYLIST(carbon_owner.all_scars)

	RegisterSignal(owner, COMSIG_LIVING_IGNITED, PROC_REF(on_ignited))
	RegisterSignal(owner, COMSIG_LIVING_EXTINGUISHED, PROC_REF(on_extinguished))

/datum/status_effect/fleshmend/on_creation(mob/living/new_owner, ...)
	. = ..()
	if(!. || !owner || !linked_alert)
		return
	if(owner.on_fire)
		linked_alert.icon_state = "fleshmend_fire"

/datum/status_effect/fleshmend/on_remove()
	UnregisterSignal(owner, list(COMSIG_LIVING_IGNITED, COMSIG_LIVING_EXTINGUISHED))

/datum/status_effect/fleshmend/tick(seconds_between_ticks)
	if(owner.on_fire)
		return

	var/need_mob_update = FALSE
	need_mob_update += owner.adjustBruteLoss(-4 * seconds_between_ticks, updating_health = FALSE)
	need_mob_update += owner.adjustFireLoss(-2 * seconds_between_ticks, updating_health = FALSE)
	need_mob_update += owner.adjustOxyLoss(-4 * seconds_between_ticks, updating_health = FALSE)
	if(need_mob_update)
		owner.updatehealth()

/datum/status_effect/fleshmend/proc/on_ignited(datum/source)
	SIGNAL_HANDLER

	linked_alert?.icon_state = "fleshmend_fire"

/datum/status_effect/fleshmend/proc/on_extinguished(datum/source)
	SIGNAL_HANDLER

	linked_alert?.icon_state = "fleshmend"

/atom/movable/screen/alert/status_effect/fleshmend
	name = "Fleshmend"
	desc = "Our wounds are rapidly healing. <i>This effect is prevented if we are on fire.</i>"
	icon_state = "fleshmend"

/datum/status_effect/exercised
	id = "Exercised"
	duration = 15 SECONDS
	status_type = STATUS_EFFECT_REFRESH // New effects will add to total duration
	alert_type = null
	processing_speed = STATUS_EFFECT_NORMAL_PROCESS
	alert_type = /atom/movable/screen/alert/status_effect/exercised
	/// Having any of these reagents in your system extends the duration
	var/static/list/supplementary_reagents_bonus = list(
		/datum/reagent/consumable/ethanol/protein_blend = 10 SECONDS, // protein shakes are very robust
		/datum/reagent/inverse/oxandrolone = 8 SECONDS,
		/datum/reagent/consumable/nutriment/protein = 5 SECONDS,
		/datum/reagent/consumable/nutriment/vitamin = 4 SECONDS,
		/datum/reagent/consumable/milk = 4 SECONDS,
		/datum/reagent/consumable/rice = 3 SECONDS,
		// keep in mind you can eat a raw egg to acquire both these reagents at the same time
		/datum/reagent/consumable/eggwhite = 3 SECONDS,
		/datum/reagent/consumable/eggyolk = 2 SECONDS,
		// weak workout food
		/datum/reagent/consumable/nutraslop = 2 SECONDS, // prison food to bulk up with
		/datum/reagent/consumable/soymilk = 1 SECONDS, // darn vegans!
		// time for the bad stuff
		/datum/reagent/consumable/sugar = -1 SECONDS,
		/datum/reagent/consumable/monkey_energy = -1 SECONDS, // the marketing was a lie
		/datum/reagent/consumable/nutriment/fat = -1 SECONDS,
	)

/datum/status_effect/exercised/proc/workout_duration(mob/living/new_owner, bonus_time)
	if(!bonus_time || !new_owner.mind || !iscarbon(new_owner))
		return 0 SECONDS

	var/modifier = 1
	if(HAS_TRAIT(new_owner, TRAIT_HULK))
		modifier += 0.5

	if(HAS_TRAIT(new_owner, TRAIT_STIMMED)) // Naturally produces stimulants to help get you PUMPED
		modifier += 1

	if(HAS_TRAIT(new_owner, TRAIT_FAT)) // less xp until you get into shape
		modifier -= 0.5

	if(new_owner.reagents.has_reagent(/datum/reagent/drug/pumpup)) // steriods? yes please!
		modifier += 3

	if(new_owner.reagents.has_reagent(/datum/reagent/inverse/oxandrolone)) // MOREEEEE
		modifier += 2

	var/food_boost = 0
	for(var/datum/reagent/workout_reagent in supplementary_reagents_bonus)
		if(new_owner.reagents.has_reagent(workout_reagent))
			food_boost += supplementary_reagents_bonus[workout_reagent]

	var/skill_level_boost = (new_owner.mind.get_skill_level(/datum/skill/athletics) - 1) * 2 SECONDS
	bonus_time = (bonus_time + food_boost + skill_level_boost) * modifier

	var/exhaustion_limit = new_owner.mind.get_skill_modifier(/datum/skill/athletics, SKILL_VALUE_MODIFIER) + world.time
	if(duration + bonus_time >= exhaustion_limit)
		duration = exhaustion_limit
		to_chat(new_owner, span_userdanger("Your muscles are exhausted! Might be a good idea to sleep..."))
		new_owner.emote("scream")
		return // exhaustion_limit

	return bonus_time

/datum/status_effect/exercised/on_creation(mob/living/new_owner, bonus_time)
	duration += workout_duration(new_owner, bonus_time)
	return ..()

/datum/status_effect/exercised/refresh(mob/living/new_owner, bonus_time)
	duration += workout_duration(new_owner, bonus_time)
	new_owner.clear_mood_event("exercise") // we need to reset the old mood event in case our fitness skill changes
	new_owner.add_mood_event("exercise", /datum/mood_event/exercise, new_owner.mind.get_skill_level(/datum/skill/athletics))

/datum/status_effect/exercised/on_apply()
	owner.add_mood_event("exercise", /datum/mood_event/exercise, owner.mind.get_skill_level(/datum/skill/athletics))
	return ..()

/datum/status_effect/exercised/on_remove()
	owner.clear_mood_event("exercise")

/atom/movable/screen/alert/status_effect/exercised
	name = "Exercise"
	desc = "You feel well exercised! Sleeping will improve your fitness."
	icon_state = "exercised"

//Hippocratic Oath: Applied when the Rod of Asclepius is activated.
/datum/status_effect/hippocratic_oath
	id = "Hippocratic Oath"
	status_type = STATUS_EFFECT_UNIQUE
	duration = STATUS_EFFECT_PERMANENT
	tick_interval = 2.5 SECONDS
	alert_type = null

	var/datum/component/aura_healing/aura_healing
	var/hand
	var/deathTick = 0

/datum/status_effect/hippocratic_oath/on_apply()
	var/static/list/organ_healing = list(
		ORGAN_SLOT_BRAIN = 1.4,
	)

	aura_healing = owner.AddComponent( \
		/datum/component/aura_healing, \
		range = 7, \
		brute_heal = 1.4, \
		burn_heal = 1.4, \
		toxin_heal = 1.4, \
		suffocation_heal = 1.4, \
		stamina_heal = 1.4, \
		simple_heal = 1.4, \
		organ_healing = organ_healing, \
		healing_color = "#375637", \
	)

	//Makes the user passive, it's in their oath not to harm!
	owner.add_traits(list(TRAIT_PACIFISM, TRAIT_HIPPOCRATIC_OATH), HIPPOCRATIC_OATH_TRAIT)
	var/datum/atom_hud/med_hud = GLOB.huds[DATA_HUD_MEDICAL_ADVANCED]
	med_hud.show_to(owner)
	return ..()

/datum/status_effect/hippocratic_oath/on_remove()
	QDEL_NULL(aura_healing)
	owner.remove_traits(list(TRAIT_PACIFISM, TRAIT_HIPPOCRATIC_OATH), HIPPOCRATIC_OATH_TRAIT)
	var/datum/atom_hud/med_hud = GLOB.huds[DATA_HUD_MEDICAL_ADVANCED]
	med_hud.hide_from(owner)

/datum/status_effect/hippocratic_oath/get_examine_text()
	return span_notice("[owner.p_They()] seem[owner.p_s()] to have an aura of healing and helpfulness about [owner.p_them()].")

/datum/status_effect/hippocratic_oath/tick(seconds_between_ticks)
	if(owner.stat == DEAD)
		if(deathTick < 4)
			deathTick += 1
		else
			consume_owner()
	else
		if(iscarbon(owner))
			var/mob/living/carbon/itemUser = owner
			var/obj/item/heldItem = itemUser.get_item_for_held_index(hand)
			if(heldItem == null || heldItem.type != /obj/item/rod_of_asclepius) //Checks to make sure the rod is still in their hand
				var/obj/item/rod_of_asclepius/newRod = new(itemUser.loc)
				newRod.activated()
				if(!itemUser.has_hand_for_held_index(hand))
					//If user does not have the corresponding hand anymore, give them one and return the rod to their hand
					var/zone = IS_LEFT_INDEX(hand) ? BODY_ZONE_L_ARM : BODY_ZONE_R_ARM
					if(itemUser.regenerate_limb(zone, FALSE))
						itemUser.put_in_hand(newRod, hand, forced = TRUE)
					else
						consume_owner() //we can't regrow, abort abort
						return
					to_chat(itemUser, span_notice("Your arm suddenly grows back with the Rod of Asclepius still attached!"))
				else
					//Otherwise get rid of whatever else is in their hand and return the rod to said hand
					itemUser.put_in_hand(newRod, hand, forced = TRUE)
					to_chat(itemUser, span_notice("The Rod of Asclepius suddenly grows back out of your arm!"))
			//Because a servant of medicines stops at nothing to help others, lets keep them on their toes and give them an additional boost.
			if(itemUser.health < itemUser.maxHealth)
				new /obj/effect/temp_visual/heal(get_turf(itemUser), "#375637")
			var/need_mob_update = FALSE
			need_mob_update += itemUser.adjustBruteLoss(-0.6 * seconds_between_ticks, updating_health = FALSE, forced = TRUE)
			need_mob_update += itemUser.adjustFireLoss(-0.6 * seconds_between_ticks, updating_health = FALSE, forced = TRUE)
			need_mob_update += itemUser.adjustToxLoss(-0.6 * seconds_between_ticks, updating_health = FALSE, forced = TRUE) //Because Slime People are people too
			need_mob_update += itemUser.adjustOxyLoss(-0.6 * seconds_between_ticks, updating_health = FALSE, forced = TRUE)
			need_mob_update += itemUser.adjustStaminaLoss(-3 * seconds_between_ticks, updating_stamina = FALSE, forced = TRUE)
			need_mob_update += itemUser.adjustOrganLoss(ORGAN_SLOT_BRAIN, -0.6 * seconds_between_ticks)
			if(need_mob_update)
				itemUser.updatehealth()

/datum/status_effect/hippocratic_oath/proc/consume_owner()
	owner.visible_message(span_notice("[owner]'s soul is absorbed into the rod, relieving the previous snake of its duty."))
	var/list/chems = list(/datum/reagent/medicine/sal_acid, /datum/reagent/medicine/c2/convermol, /datum/reagent/medicine/oxandrolone)
	var/mob/living/basic/snake/spawned = new(owner.loc, pick(chems))
	spawned.name = "Asclepius's Snake"
	spawned.real_name = "Asclepius's Snake"
	spawned.desc = "A mystical snake previously trapped upon the Rod of Asclepius, now freed of its burden. Unlike the average snake, its bites contain chemicals with minor healing properties."
	new /obj/effect/decal/cleanable/ash(owner.loc)
	new /obj/item/rod_of_asclepius(owner.loc)
	owner.investigate_log("has been consumed by the Rod of Asclepius.", INVESTIGATE_DEATHS)
	qdel(owner)

/datum/status_effect/good_music
	id = "Good Music"
	alert_type = null
	duration = 6 SECONDS
	tick_interval = 1 SECONDS
	status_type = STATUS_EFFECT_REFRESH

/datum/status_effect/good_music/tick(seconds_between_ticks)
	if(owner.can_hear())
		owner.adjust_dizzy(-4 SECONDS)
		owner.adjust_jitter(-4 SECONDS)
		owner.adjust_confusion(-1 SECONDS)
		owner.add_mood_event("goodmusic", /datum/mood_event/goodmusic)

/atom/movable/screen/alert/status_effect/regenerative_core
	name = "Regenerative Core Tendrils"
	desc = "You can move faster than your broken body could normally handle!"
	icon_state = "regenerative_core"

/datum/status_effect/regenerative_core
	id = "Regenerative Core"
	duration = 1 MINUTES
	status_type = STATUS_EFFECT_REPLACE
	alert_type = /atom/movable/screen/alert/status_effect/regenerative_core
	show_duration = TRUE

/datum/status_effect/regenerative_core/on_apply()
	owner.add_movespeed_mod_immunities(id, /datum/movespeed_modifier/damage_slowdown)
	owner.adjustBruteLoss(-25)
	owner.adjustFireLoss(-25)
	owner.fully_heal(HEAL_CC_STATUS)
	owner.bodytemperature = owner.get_body_temp_normal()
	if(ishuman(owner))
		var/mob/living/carbon/human/humi = owner
		humi.set_coretemperature(humi.get_body_temp_normal())
	return TRUE

/datum/status_effect/regenerative_core/on_remove()
	owner.remove_movespeed_mod_immunities(id, /datum/movespeed_modifier/damage_slowdown)

/datum/status_effect/lightningorb
	id = "Lightning Orb"
	duration = 30 SECONDS
	alert_type = /atom/movable/screen/alert/status_effect/lightningorb
	show_duration = TRUE

/datum/status_effect/lightningorb/on_apply()
	. = ..()
	owner.add_movespeed_modifier(/datum/movespeed_modifier/yellow_orb)
	to_chat(owner, span_notice("You feel fast!"))

/datum/status_effect/lightningorb/on_remove()
	. = ..()
	owner.remove_movespeed_modifier(/datum/movespeed_modifier/yellow_orb)
	to_chat(owner, span_notice("You slow down."))

/atom/movable/screen/alert/status_effect/lightningorb
	name = "Lightning Orb"
	desc = "The speed surges through you!"
	icon_state = "lightningorb"

/datum/status_effect/mayhem
	id = "Mayhem"
	duration = 2 MINUTES
	alert_type = null
	/// The chainsaw spawned by the status effect
	var/obj/item/chainsaw/doomslayer/chainsaw

/datum/status_effect/mayhem/on_apply()
	. = ..()
	to_chat(owner, "<span class='reallybig redtext'>RIP AND TEAR</span>")
	SEND_SOUND(owner, sound('sound/effects/hallucinations/veryfar_noise.ogg'))
	owner.cause_hallucination( \
		/datum/hallucination/delusion/preset/demon, \
		"[id] status effect", \
		duration = duration, \
		affects_us = FALSE, \
		affects_others = TRUE, \
		skip_nearby = FALSE, \
		play_wabbajack = FALSE, \
	)

	owner.drop_all_held_items()

	if(iscarbon(owner))
		chainsaw = new(get_turf(owner))
		ADD_TRAIT(chainsaw, TRAIT_NODROP, TRAIT_STATUS_EFFECT(id))
		owner.put_in_hands(chainsaw, forced = TRUE)
		chainsaw.attack_self(owner)
		owner.reagents.add_reagent(/datum/reagent/medicine/adminordrazine, 25)

	owner.log_message("entered a blood frenzy", LOG_ATTACK)
	to_chat(owner, span_narsiesmall("KILL, KILL, KILL! YOU HAVE NO ALLIES ANYMORE, NO TEAM MATES OR ALLEGIANCES! KILL THEM ALL!"))

	var/datum/client_colour/colour = owner.add_client_colour(/datum/client_colour/bloodlust)
	QDEL_IN(colour, 1.1 SECONDS)
	return TRUE

/datum/status_effect/mayhem/on_remove()
	. = ..()
	to_chat(owner, span_notice("Your bloodlust seeps back into the bog of your subconscious and you regain self control."))
	owner.log_message("exited a blood frenzy", LOG_ATTACK)
	QDEL_NULL(chainsaw)

/datum/status_effect/speed_boost
	id = "speed_boost"
	duration = 2 SECONDS
	status_type = STATUS_EFFECT_REPLACE
	show_duration = TRUE
	alert_type = null

/datum/status_effect/speed_boost/on_creation(mob/living/new_owner, set_duration)
	if(isnum(set_duration))
		duration = set_duration
	. = ..()

/datum/status_effect/speed_boost/on_apply()
	owner.add_movespeed_modifier(/datum/movespeed_modifier/status_speed_boost, update = TRUE)
	return ..()

/datum/status_effect/speed_boost/on_remove()
	owner.remove_movespeed_modifier(/datum/movespeed_modifier/status_speed_boost, update = TRUE)

/datum/movespeed_modifier/status_speed_boost
	multiplicative_slowdown = -1

///this buff provides a max health buff and a heal.
/datum/status_effect/limited_buff/health_buff
	id = "health_buff"
	alert_type = null
	///This var stores the mobs max health when the buff was first applied, and determines the size of future buffs.database.database.
	var/historic_max_health
	///This var determines how large the health buff will be. health_buff_modifier * historic_max_health * stacks
	var/health_buff_modifier = 0.1 //translate to a 10% buff over historic health per stack
	///This modifier multiplies the healing by the effect.
	var/healing_modifier = 2
	///If the mob has a low max health, we instead use this flat value to increase max health and calculate any heal.
	var/fragile_mob_health_buff = 10

/datum/status_effect/limited_buff/health_buff/on_creation(mob/living/new_owner)
	historic_max_health = new_owner.maxHealth
	. = ..()

/datum/status_effect/limited_buff/health_buff/on_apply()
	. = ..()
	var/health_increase = round(max(fragile_mob_health_buff, historic_max_health * health_buff_modifier))
	owner.maxHealth += health_increase
	owner.balloon_alert_to_viewers("health buffed")
	to_chat(owner, span_nicegreen("You feel healthy, like if your body is little stronger than it was a moment ago."))

	if(isanimal(owner))	//dumb animals have their own proc for healing.
		var/mob/living/simple_animal/healthy_animal = owner
		healthy_animal.adjustHealth(-(health_increase * healing_modifier))
	else
		owner.adjustBruteLoss(-(health_increase * healing_modifier))

/datum/status_effect/limited_buff/health_buff/maxed_out()
	. = ..()
	to_chat(owner, span_warning("You don't feel any healthier."))

/datum/status_effect/nest_sustenance
	id = "nest_sustenance"
	duration = STATUS_EFFECT_PERMANENT
	tick_interval = 0.4 SECONDS
	alert_type = /atom/movable/screen/alert/status_effect/nest_sustenance

/datum/status_effect/nest_sustenance/tick(seconds_between_ticks)
	. = ..()

	if(owner.stat == DEAD) //If the victim has died due to complications in the nest
		qdel(src)
		return

	var/need_mob_update = FALSE
	need_mob_update += owner.adjustBruteLoss(-2 * seconds_between_ticks, updating_health = FALSE)
	need_mob_update += owner.adjustFireLoss(-2 * seconds_between_ticks, updating_health = FALSE)
	need_mob_update += owner.adjustOxyLoss(-4 * seconds_between_ticks, updating_health = FALSE)
	need_mob_update += owner.adjustStaminaLoss(-4 * seconds_between_ticks, updating_stamina = FALSE)
	if(need_mob_update)
		owner.updatehealth()
	owner.adjust_bodytemperature(BODYTEMP_NORMAL, 0, BODYTEMP_NORMAL) //Won't save you from the void of space, but it will stop you from freezing or suffocating in low pressure


/atom/movable/screen/alert/status_effect/nest_sustenance
	name = "Nest Vitalization"
	desc = "The resin seems to pulsate around you. It seems to be sustaining your vital functions. You feel ill..."
	icon_state = "nest_life"

/**
 * Granted to wizards upon satisfying the cheese sacrifice during grand rituals.
 * Halves incoming damage and makes the owner stun immune, damage slow immune, levitating(even in space and hyperspace!) and glowing.
 */
/datum/status_effect/blessing_of_insanity
	id = "blessing_of_insanity"
	duration = STATUS_EFFECT_PERMANENT
	tick_interval = STATUS_EFFECT_NO_TICK
	alert_type = /atom/movable/screen/alert/status_effect/blessing_of_insanity

/atom/movable/screen/alert/status_effect/blessing_of_insanity
	name = "Blessing of Insanity"
	desc = "Your devotion to madness has improved your resilience to all damage and you gain the power to levitate!"
	//no screen alert - the gravity already throws one

/datum/status_effect/blessing_of_insanity/on_apply()
	if(ishuman(owner))
		var/mob/living/carbon/human/human_owner = owner
		var/datum/physiology/owner_physiology = human_owner.physiology
		owner_physiology.brute_mod *= 0.5
		owner_physiology.burn_mod *= 0.5
		owner_physiology.tox_mod *= 0.5
		owner_physiology.oxy_mod *= 0.5
		owner_physiology.stamina_mod *= 0.5
	owner.add_filter("mad_glow", 2, list("type" = "outline", "color" = "#eed811c9", "size" = 2))
	owner.AddElement(/datum/element/forced_gravity, 0)
	owner.AddElement(/datum/element/simple_flying)
	owner.add_stun_absorption(source = id, priority = 4)
	owner.add_movespeed_mod_immunities(id, /datum/movespeed_modifier/damage_slowdown)
	ADD_TRAIT(owner, TRAIT_FREE_HYPERSPACE_MOVEMENT, TRAIT_STATUS_EFFECT(id))
	owner.playsound_local(get_turf(owner), 'sound/effects/chemistry/ahaha.ogg', vol = 100, vary = TRUE, use_reverb = TRUE)
	return TRUE

/datum/status_effect/blessing_of_insanity/on_remove()
	if(ishuman(owner))
		var/mob/living/carbon/human/human_owner = owner
		var/datum/physiology/owner_physiology = human_owner.physiology
		owner_physiology.brute_mod *= 2
		owner_physiology.burn_mod *= 2
		owner_physiology.tox_mod *= 2
		owner_physiology.oxy_mod *= 2
		owner_physiology.stamina_mod *= 2
	owner.remove_filter("mad_glow")
	owner.RemoveElement(/datum/element/forced_gravity, 0)
	owner.RemoveElement(/datum/element/simple_flying)
	owner.remove_stun_absorption(id)
	owner.remove_movespeed_mod_immunities(id, /datum/movespeed_modifier/damage_slowdown)
	REMOVE_TRAIT(owner, TRAIT_FREE_HYPERSPACE_MOVEMENT, TRAIT_STATUS_EFFECT(id))

/// Gives you a brief period of anti-gravity
/datum/status_effect/jump_jet
	id = "jump_jet"
	alert_type = null
	duration = 5 SECONDS

/datum/status_effect/jump_jet/on_apply()
	owner.AddElement(/datum/element/forced_gravity, 0)
	return TRUE

/datum/status_effect/jump_jet/on_remove()
	owner.RemoveElement(/datum/element/forced_gravity, 0)

/// Makes the mob immune to radiation for a short bit to help with safely spawning in hazardous areas
/datum/status_effect/radiation_immunity
	id = "radiation_immunity"
	duration = 1 MINUTES
	show_duration = TRUE
	alert_type = null

/datum/status_effect/radiation_immunity/on_apply()
	ADD_TRAIT(owner, TRAIT_RADIMMUNE, TRAIT_STATUS_EFFECT(id))
	return TRUE

/datum/status_effect/radiation_immunity/on_remove()
	REMOVE_TRAIT(owner, TRAIT_RADIMMUNE, TRAIT_STATUS_EFFECT(id))

/datum/status_effect/radiation_immunity/radnebula
	alert_type = /atom/movable/screen/alert/status_effect/radiation_immunity

/atom/movable/screen/alert/status_effect/radiation_immunity
	name = "Radiation shielding"
	desc = "You're immune to radiation, get settled quick!"
	icon_state = "radiation_shield"

/// Throw an alert we're in darkness!! Nightvision can make it hard to tell so this is useful
/datum/status_effect/shadow
	id = "shadow"
	duration = 2 SECONDS
	status_type = STATUS_EFFECT_REFRESH
	alert_type = /atom/movable/screen/alert/status_effect/shadow_regeneration

/// Same as above, but also heal in darkness!! Mostly superseded but some simple mobs use this
/datum/status_effect/shadow/regeneration
	id = "shadow_regeneration"

/datum/status_effect/shadow/regeneration/on_apply()
	. = ..()
	if (!.)
		return FALSE
	heal_owner()
	return TRUE

/datum/status_effect/shadow/regeneration/refresh(effect)
	. = ..()
	heal_owner()

/// Regenerate health whenever this status effect is applied or reapplied
/datum/status_effect/shadow/regeneration/proc/heal_owner()
	owner.heal_overall_damage(brute = 1, burn = 1, required_bodytype = BODYTYPE_ORGANIC)

/atom/movable/screen/alert/status_effect/shadow_regeneration
	name = "Shadow Regeneration"
	desc = "Bathed in soothing darkness, you will slowly heal yourself"
	icon_state = "lightless"
