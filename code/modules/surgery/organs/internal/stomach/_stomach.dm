//The contant in the rate of reagent transfer on life ticks
#define STOMACH_METABOLISM_CONSTANT 0.25

/obj/item/organ/stomach
	name = "stomach"
	desc = "Onaka ga suite imasu."
	icon_state = "stomach"

	w_class = WEIGHT_CLASS_SMALL
	zone = BODY_ZONE_CHEST
	slot = ORGAN_SLOT_STOMACH
	attack_verb_continuous = list("gores", "squishes", "slaps", "digests")
	attack_verb_simple = list("gore", "squish", "slap", "digest")

	healing_factor = STANDARD_ORGAN_HEALING
	decay_factor = STANDARD_ORGAN_DECAY * 1.15 // ~13 minutes, the stomach is one of the first organs to die

	low_threshold_passed = span_info("Your stomach flashes with pain before subsiding. Food doesn't seem like a good idea right now.")
	high_threshold_passed = span_warning("Your stomach flares up with constant pain- you can hardly stomach the idea of food right now!")
	high_threshold_cleared = span_info("The pain in your stomach dies down for now, but food still seems unappealing.")
	low_threshold_cleared = span_info("The last bouts of pain in your stomach have died out.")

	food_reagents = list(/datum/reagent/consumable/nutriment/organ_tissue/stomach_lining = 5)
	//This is a reagent user and needs more then the 10u from edible component
	reagent_vol = 1000

	///The rate that disgust decays
	var/disgust_metabolism = 1

	///The rate that the stomach will transfer reagents to the body
	var/metabolism_efficiency = 0.05 // the lowest we should go is 0.025

	/// Multiplier for hunger rate
	var/hunger_modifier = 1

	var/operated = FALSE //whether the stomach's been repaired with surgery and can be fixed again or not

/obj/item/organ/stomach/Initialize(mapload)
	. = ..()
	//None edible organs do not get a reagent holder by default
	if(!reagents)
		create_reagents(reagent_vol, REAGENT_HOLDER_ALIVE)
	else
		reagents.flags |= REAGENT_HOLDER_ALIVE

/obj/item/organ/stomach/on_life(seconds_per_tick, times_fired)
	. = ..()

	//Manage species digestion
	if(ishuman(owner))
		var/mob/living/carbon/human/humi = owner
		if(!(organ_flags & ORGAN_FAILING))
			handle_hunger(humi, seconds_per_tick, times_fired)

	var/mob/living/carbon/body = owner

	// digest food, sent all reagents that can metabolize to the body
	for(var/datum/reagent/bit as anything in reagents?.reagent_list)

		// If the reagent does not metabolize then it will sit in the stomach
		// This has an effect on items like plastic causing them to take up space in the stomach
		if(bit.metabolization_rate <= 0)
			continue

		//Ensure that the the minimum is equal to the metabolization_rate of the reagent if it is higher then the STOMACH_METABOLISM_CONSTANT
		var/rate_min = max(bit.metabolization_rate, STOMACH_METABOLISM_CONSTANT)
		//Do not transfer over more then we have
		var/amount_max = bit.volume

		//If the reagent is part of the food reagents for the organ
		//prevent all the reagents form being used leaving the food reagents
		var/amount_food = food_reagents[bit.type]
		if(amount_food)
			amount_max = max(amount_max - amount_food, 0)

		// Transfer the amount of reagents based on volume with a min amount of 1u
		var/amount = min((round(metabolism_efficiency * amount_max, 0.05) + rate_min) * seconds_per_tick, amount_max)

		if(amount <= 0)
			continue

		// transfer the reagents over to the body at the rate of the stomach metabolim
		// this way the body is where all reagents that are processed and react
		// the stomach manages how fast they are feed in a drip style
		reagents.trans_to(body, amount, target_id = bit.type)

	//Handle disgust
	if(body)
		handle_disgust(body, seconds_per_tick, times_fired)

	//If the stomach is not damage exit out
	if(damage < low_threshold)
		return

	//We are checking if we have nutriment in a damaged stomach.
	var/datum/reagent/nutri = locate(/datum/reagent/consumable/nutriment) in reagents?.reagent_list
	//No nutriment found lets exit out
	if(!nutri)
		return

	// remove the food reagent amount
	var/nutri_vol = nutri.volume
	var/amount_food = food_reagents[nutri.type]
	if(amount_food)
		nutri_vol = max(nutri_vol - amount_food, 0)

	// found nutriment was stomach food reagent
	if(!(nutri_vol > 0))
		return

	//The stomach is damage has nutriment but low on theshhold, lo prob of vomit
	if(SPT_PROB(0.0125 * damage * nutri_vol * nutri_vol, seconds_per_tick))
		body.vomit(VOMIT_CATEGORY_DEFAULT, lost_nutrition = damage)
		to_chat(body, span_warning("Your stomach reels in pain as you're incapable of holding down all that food!"))
		return

	// the change of vomit is now high
	if(damage > high_threshold && SPT_PROB(0.05 * damage * nutri_vol * nutri_vol, seconds_per_tick))
		body.vomit(VOMIT_CATEGORY_DEFAULT, lost_nutrition = damage)
		to_chat(body, span_warning("Your stomach reels in pain as you're incapable of holding down all that food!"))

/obj/item/organ/stomach/proc/handle_hunger(mob/living/carbon/human/human, seconds_per_tick, times_fired)
	if(HAS_TRAIT(human, TRAIT_NOHUNGER))
		return //hunger is for BABIES

	//The fucking TRAIT_FAT mutation is the dumbest shit ever. It makes the code so difficult to work with
	if(HAS_TRAIT_FROM(human, TRAIT_FAT, OBESITY))//I share your pain, past coder.
		if(human.overeatduration < (200 SECONDS))
			to_chat(human, span_notice("You feel fit again!"))
			human.remove_traits(list(TRAIT_FAT, TRAIT_OFF_BALANCE_TACKLER), OBESITY)

	else
		if(human.overeatduration >= (200 SECONDS))
			to_chat(human, span_danger("You suddenly feel blubbery!"))
			human.add_traits(list(TRAIT_FAT, TRAIT_OFF_BALANCE_TACKLER), OBESITY)

	// nutrition decrease and satiety
	if (human.nutrition > 0 && human.stat != DEAD)
		// THEY HUNGER
		var/hunger_rate = HUNGER_FACTOR
		if(human.mob_mood && human.mob_mood.sanity > SANITY_DISTURBED)
			hunger_rate *= max(1 - 0.002 * human.mob_mood.sanity, 0.5) //0.85 to 0.75
		// Whether we cap off our satiety or move it towards 0
		if(human.satiety > MAX_SATIETY)
			human.satiety = MAX_SATIETY
		else if(human.satiety > 0)
			human.satiety--
		else if(human.satiety < -MAX_SATIETY)
			human.satiety = -MAX_SATIETY
		else if(human.satiety < 0)
			human.satiety++
			if(SPT_PROB(round(-human.satiety/77), seconds_per_tick))
				human.set_jitter_if_lower(10 SECONDS)
			hunger_rate = 3 * HUNGER_FACTOR
		hunger_rate *= hunger_modifier
		hunger_rate *= human.physiology.hunger_mod
		human.adjust_nutrition(-hunger_rate * seconds_per_tick)

	var/nutrition = human.nutrition
	if(nutrition > NUTRITION_LEVEL_FULL && !HAS_TRAIT(human, TRAIT_NOFAT))
		if(human.overeatduration < 20 MINUTES) //capped so people don't take forever to unfat
			human.overeatduration = min(human.overeatduration + (1 SECONDS * seconds_per_tick), 20 MINUTES)
	else
		if(human.overeatduration > 0)
			human.overeatduration = max(human.overeatduration - (2 SECONDS * seconds_per_tick), 0) //doubled the unfat rate

	//metabolism change
	if(nutrition > NUTRITION_LEVEL_FAT)
		human.metabolism_efficiency = 1
	else if(nutrition > NUTRITION_LEVEL_FED && human.satiety > 80)
		if(human.metabolism_efficiency != 1.25)
			to_chat(human, span_notice("You feel vigorous."))
			human.metabolism_efficiency = 1.25
	else if(nutrition < NUTRITION_LEVEL_STARVING + 50)
		if(human.metabolism_efficiency != 0.8)
			to_chat(human, span_notice("You feel sluggish."))
		human.metabolism_efficiency = 0.8
	else
		if(human.metabolism_efficiency == 1.25)
			to_chat(human, span_notice("You no longer feel vigorous."))
		human.metabolism_efficiency = 1

	//Hunger slowdown for if mood isn't enabled
	if(CONFIG_GET(flag/disable_human_mood))
		handle_hunger_slowdown(human)

///for when mood is disabled and hunger should handle slowdowns
/obj/item/organ/stomach/proc/handle_hunger_slowdown(mob/living/carbon/human/human)
	var/hungry = (500 - human.nutrition) / 5 //So overeat would be 100 and default level would be 80
	if(hungry >= 70)
		human.add_or_update_variable_movespeed_modifier(/datum/movespeed_modifier/hunger, multiplicative_slowdown = (hungry / 50))
	else
		human.remove_movespeed_modifier(/datum/movespeed_modifier/hunger)

/obj/item/organ/stomach/get_availability(datum/species/owner_species, mob/living/owner_mob)
	return owner_species.mutantstomach

///This gets called after the owner takes a bite of food
/obj/item/organ/stomach/proc/after_eat(atom/edible)
	return

/obj/item/organ/stomach/proc/handle_disgust(mob/living/carbon/human/disgusted, seconds_per_tick, times_fired)
	var/old_disgust = disgusted.old_disgust
	var/disgust = disgusted.disgust

	if(disgust)
		var/pukeprob = 2.5 + (0.025 * disgust)
		if(disgust >= DISGUST_LEVEL_GROSS)
			if(SPT_PROB(5, seconds_per_tick))
				disgusted.adjust_stutter(2 SECONDS)
				disgusted.adjust_confusion(2 SECONDS)
			if(SPT_PROB(5, seconds_per_tick) && !disgusted.stat)
				to_chat(disgusted, span_warning("You feel kind of iffy..."))
			disgusted.adjust_jitter(-6 SECONDS)
		if(disgust >= DISGUST_LEVEL_VERYGROSS)
			if(SPT_PROB(pukeprob, seconds_per_tick)) //iT hAndLeS mOrE ThaN PukInG
				disgusted.adjust_confusion(2.5 SECONDS)
				disgusted.adjust_stutter(2 SECONDS)
				disgusted.vomit(VOMIT_CATEGORY_KNOCKDOWN, distance = 0)
				disgusted.adjust_disgust(-50)
			disgusted.set_dizzy_if_lower(10 SECONDS)
		if(disgust >= DISGUST_LEVEL_DISGUSTED)
			if(SPT_PROB(13, seconds_per_tick))
				disgusted.set_eye_blur_if_lower(6 SECONDS) //We need to add more shit down here

		disgusted.adjust_disgust(-0.25 * disgust_metabolism * seconds_per_tick)

	// I would consider breaking this up into steps matching the disgust levels
	// But disgust is used so rarely it wouldn't save a significant amount of time, and it makes the code just way worse
	// We're in the same state as the last time we processed, so don't bother
	if(old_disgust == disgust)
		return

	disgusted.old_disgust = disgust
	switch(disgust)
		if(0 to DISGUST_LEVEL_GROSS)
			disgusted.clear_alert(ALERT_DISGUST)
			disgusted.clear_mood_event("disgust")
		if(DISGUST_LEVEL_GROSS to DISGUST_LEVEL_VERYGROSS)
			disgusted.throw_alert(ALERT_DISGUST, /atom/movable/screen/alert/gross)
			disgusted.add_mood_event("disgust", /datum/mood_event/gross)
		if(DISGUST_LEVEL_VERYGROSS to DISGUST_LEVEL_DISGUSTED)
			disgusted.throw_alert(ALERT_DISGUST, /atom/movable/screen/alert/verygross)
			disgusted.add_mood_event("disgust", /datum/mood_event/verygross)
		if(DISGUST_LEVEL_DISGUSTED to INFINITY)
			disgusted.throw_alert(ALERT_DISGUST, /atom/movable/screen/alert/disgusted)
			disgusted.add_mood_event("disgust", /datum/mood_event/disgusted)

/obj/item/organ/stomach/on_mob_insert(mob/living/carbon/receiver, special, movement_flags)
	. = ..()
	receiver.hud_used?.hunger?.update_appearance()

/obj/item/organ/stomach/on_mob_remove(mob/living/carbon/stomach_owner, special, movement_flags)
	if(ishuman(stomach_owner))
		var/mob/living/carbon/human/human_owner = stomach_owner
		human_owner.clear_alert(ALERT_DISGUST)
		human_owner.clear_mood_event("disgust")
	stomach_owner.hud_used?.hunger?.update_appearance()
	return ..()

/obj/item/organ/stomach/bone
	name = "mass of bones"
	desc = "You have no idea what this strange ball of bones does."
	icon_state = "stomach-bone"
	metabolism_efficiency = 0.025 //very bad
	organ_traits = list(TRAIT_NOHUNGER)

/obj/item/organ/stomach/bone/plasmaman
	name = "digestive crystal"
	desc = "A strange crystal that is responsible for metabolizing the unseen energy force that feeds plasmamen."
	icon_state = "stomach-p"
	metabolism_efficiency = 0.06
	organ_traits = null

/obj/item/organ/stomach/cybernetic
	name = "basic cybernetic stomach"
	desc = "A basic device designed to mimic the functions of a human stomach"
	failing_desc = "seems to be broken."
	icon_state = "stomach-c"
	organ_flags = ORGAN_ROBOTIC
	maxHealth = STANDARD_ORGAN_THRESHOLD * 0.5
	metabolism_efficiency = 0.035 // not as good at digestion
	var/emp_vulnerability = 80 //Chance of permanent effects if emp-ed.

/obj/item/organ/stomach/cybernetic/emp_act(severity)
	. = ..()
	if(. & EMP_PROTECT_SELF)
		return
	if(!COOLDOWN_FINISHED(src, severe_cooldown)) //So we cant just spam emp to kill people.
		owner.vomit(vomit_flags = (MOB_VOMIT_MESSAGE | MOB_VOMIT_HARM))
		COOLDOWN_START(src, severe_cooldown, 10 SECONDS)
	if(prob(emp_vulnerability/severity)) //Chance of permanent effects
		organ_flags |= ORGAN_EMP //Starts organ faliure - gonna need replacing soon.

/obj/item/organ/stomach/cybernetic/tier2
	name = "cybernetic stomach"
	desc = "An electronic device designed to mimic the functions of a human stomach. Handles disgusting food a bit better."
	icon_state = "stomach-c-u"
	maxHealth = 1.5 * STANDARD_ORGAN_THRESHOLD
	disgust_metabolism = 2
	emp_vulnerability = 40
	metabolism_efficiency = 0.07

/obj/item/organ/stomach/cybernetic/tier3
	name = "upgraded cybernetic stomach"
	desc = "An upgraded version of the cybernetic stomach, designed to improve further upon organic stomachs. Handles disgusting food very well."
	icon_state = "stomach-c-u2"
	maxHealth = 2 * STANDARD_ORGAN_THRESHOLD
	disgust_metabolism = 3
	emp_vulnerability = 20
	metabolism_efficiency = 0.1

/obj/item/organ/stomach/cybernetic/surplus
	name = "surplus prosthetic stomach"
	desc = "A mechanical plastic oval that utilizes sulfuric acid instead of stomach acid. \
		Very fragile, with painfully slow metabolism.\
		Offers no protection against EMPs."
	icon_state = "stomach-c-s"
	maxHealth = STANDARD_ORGAN_THRESHOLD * 0.35
	emp_vulnerability = 100
	metabolism_efficiency = 0.025

//surplus organs are so awful that they explode when removed, unless failing
/obj/item/organ/stomach/cybernetic/surplus/Initialize(mapload)
	. = ..()
	AddElement(/datum/element/dangerous_organ_removal, /*surgical = */ TRUE)

/obj/item/organ/stomach/pod
	name = "pod chloroplast"
	desc = "A green plant-like organ that functions similarly to a human stomach."
	foodtype_flags = PODPERSON_ORGAN_FOODTYPES
	color = COLOR_LIME

#undef STOMACH_METABOLISM_CONSTANT
