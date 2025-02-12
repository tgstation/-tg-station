#define FISH_ORGAN_COLOR "#875652" //dark moderate magenta
#define FISH_SCLERA_COLOR COLOR_WHITE
#define FISH_PUPIL_COLOR COLOR_BLUE
#define FISH_COLORS FISH_ORGAN_COLOR + FISH_SCLERA_COLOR + FISH_PUPIL_COLOR

///bonus of the observing gondola: you can ignore environmental hazards
/datum/status_effect/organ_set_bonus/fish
	id = "organ_set_bonus_fish"
	tick_interval = 1 SECONDS
	organs_needed = 3
	bonus_activate_text = span_notice("Fish DNA is deeply infused with you! While wet, you crawl faster, are slippery, cannot slip, and it takes longer to dry out. \
		You're also resistant to high pressure, better at fishing, but less resilient when dry, especially against burns.")
	bonus_deactivate_text = span_notice("You no longer feel as fishy. The moisture around your body begins to dissipate faster...")
	bonus_traits = list(
		TRAIT_RESISTHIGHPRESSURE,
		TRAIT_EXPERT_FISHER,
		TRAIT_EXAMINE_FISH,
		TRAIT_EXAMINE_DEEPER_FISH,
		TRAIT_REVEAL_FISH,
		TRAIT_EXAMINE_FISHING_SPOT,
		TRAIT_WET_FOR_LONGER,
		TRAIT_SLIPPERY_WHEN_WET,
		TRAIT_EXPANDED_FOV, //fish vision
		TRAIT_WATER_ADAPTATION,
		)
	bonus_biotype = MOB_AQUATIC

/datum/status_effect/organ_set_bonus/fish/enable_bonus()
	. = ..()
	if(!.)
		return
	RegisterSignals(owner, list(COMSIG_CARBON_GAIN_ORGAN, COMSIG_CARBON_LOSE_ORGAN), PROC_REF(check_tail))
	RegisterSignals(owner, list(SIGNAL_ADDTRAIT(TRAIT_IS_WET), SIGNAL_REMOVETRAIT(TRAIT_IS_WET)), PROC_REF(update_wetness))
	RegisterSignals(owner, COMSIG_LIVING_GET_PERCEIVED_FOOD_QUALITY, PROC_REF(get_perceived_food_quality))

	if(ishuman(owner))
		var/mob/living/carbon/human/human = owner
		//Fish is slightly weaker to being cooked. oh oh.
		human.physiology.burn_mod *= 1.15
		human.physiology.heat_mod *= 1.15
		human.physiology.damage_resistance += 8 //base 8% damage resistance, much wow.
	if(!HAS_TRAIT(owner, TRAIT_IS_WET))
		apply_debuff()
	else
		ADD_TRAIT(owner, TRAIT_GRABRESISTANCE, TRAIT_STATUS_EFFECT(id))
		owner.add_mood_event("fish_organs_bonus", /datum/mood_event/fish_water)
	if(HAS_TRAIT(owner, TRAIT_IS_WET) && istype(owner.get_organ_slot(ORGAN_SLOT_EXTERNAL_TAIL), /obj/item/organ/tail/fish))
		add_speed_buff()
	owner.mind?.adjust_experience(/datum/skill/fishing, SKILL_EXP_JOURNEYMAN, silent = TRUE)
	owner.grant_language(/datum/language/carptongue, ALL, type)

/datum/status_effect/organ_set_bonus/fish/disable_bonus()
	. = ..()
	UnregisterSignal(owner, list(
		COMSIG_CARBON_GAIN_ORGAN,
		COMSIG_CARBON_LOSE_ORGAN,
		SIGNAL_ADDTRAIT(TRAIT_IS_WET),
		SIGNAL_REMOVETRAIT(TRAIT_IS_WET),
		COMSIG_LIVING_TREAT_MESSAGE,
		COMSIG_LIVING_GET_PERCEIVED_FOOD_QUALITY,
	))
	if(!HAS_TRAIT(owner, TRAIT_IS_WET))
		remove_debuff()
	else
		REMOVE_TRAIT(owner, TRAIT_GRABRESISTANCE, TRAIT_STATUS_EFFECT(id))
	owner.clear_mood_event("fish_organs_bonus")
	if(ishuman(owner))
		var/mob/living/carbon/human/human = owner
		human.physiology.burn_mod /= 1.15
		human.physiology.heat_mod /= 1.15
		human.physiology.damage_resistance -= 8
	if(HAS_TRAIT(owner, TRAIT_IS_WET) && istype(owner.get_organ_slot(ORGAN_SLOT_EXTERNAL_TAIL), /obj/item/organ/tail/fish))
		remove_speed_buff()
	owner.mind?.adjust_experience(/datum/skill/fishing, -SKILL_EXP_JOURNEYMAN, silent = TRUE)
	owner.remove_language(/datum/language/carptongue, ALL, type)

/datum/status_effect/organ_set_bonus/fish/proc/get_perceived_food_quality(datum/source, datum/component/edible/edible, list/extra_quality)
	SIGNAL_HANDLER
	if(HAS_TRAIT(edible.parent, TRAIT_GREAT_QUALITY_BAIT))
		extra_quality += LIKED_FOOD_QUALITY_CHANGE * 3
	else if(HAS_TRAIT(edible.parent, TRAIT_GOOD_QUALITY_BAIT))
		extra_quality += LIKED_FOOD_QUALITY_CHANGE * 2
	else if(HAS_TRAIT(edible.parent, TRAIT_BASIC_QUALITY_BAIT))
		extra_quality += LIKED_FOOD_QUALITY_CHANGE

/datum/status_effect/organ_set_bonus/fish/tick(seconds_between_ticks)
	. = ..()
	if(!bonus_active || !HAS_TRAIT(owner, TRAIT_IS_WET))
		return
	owner.adjust_bodytemperature(-2 * seconds_between_ticks, min_temp = owner.get_body_temp_normal())
	owner.adjustStaminaLoss(-1.5 * seconds_between_ticks)

/datum/status_effect/organ_set_bonus/fish/proc/update_wetness(datum/source)
	SIGNAL_HANDLER
	if(HAS_TRAIT(owner, TRAIT_IS_WET)) //remove the debuffs from being dry
		remove_debuff()
		if(istype(owner.get_organ_slot(ORGAN_SLOT_EXTERNAL_TAIL), /obj/item/organ/tail/fish))
			add_speed_buff()
		return
	apply_debuff()
	if(istype(owner.get_organ_slot(ORGAN_SLOT_EXTERNAL_TAIL), /obj/item/organ/tail/fish))
		remove_speed_buff()

/datum/status_effect/organ_set_bonus/fish/proc/apply_debuff()
	REMOVE_TRAIT(owner, TRAIT_GRABRESISTANCE, REF(src))
	owner.add_movespeed_modifier(/datum/movespeed_modifier/fish_waterless)
	owner.add_mood_event("fish_organs_bonus", /datum/mood_event/fish_waterless)
	if(!ishuman(owner))
		return
	var/mob/living/carbon/human/human = owner
	human.physiology.burn_mod *= 1.5
	human.physiology.heat_mod *= 1.2
	human.physiology.brute_mod *= 1.1
	human.physiology.stun_mod *= 1.1
	human.physiology.knockdown_mod *= 1.1
	human.physiology.stamina_mod *= 1.1
	human.physiology.damage_resistance -= 16 //from +8% to -8%

/datum/status_effect/organ_set_bonus/fish/proc/remove_debuff()
	ADD_TRAIT(owner, TRAIT_GRABRESISTANCE, TRAIT_STATUS_EFFECT(id)) //harder to grab when wet.
	owner.remove_movespeed_modifier(/datum/movespeed_modifier/fish_waterless)
	owner.add_mood_event("fish_organs_bonus", /datum/mood_event/fish_water)
	if(!ishuman(owner))
		return
	var/mob/living/carbon/human/human = owner
	human.physiology.burn_mod /= 1.5
	human.physiology.heat_mod /= 1.2
	human.physiology.brute_mod /= 1.1
	human.physiology.stun_mod /= 1.1
	human.physiology.knockdown_mod /= 1.1
	human.physiology.stamina_mod /= 1.1
	human.physiology.damage_resistance += 16 //from -8% to +8%

/datum/status_effect/organ_set_bonus/fish/proc/check_tail(mob/living/carbon/source, obj/item/organ/organ, special)
	SIGNAL_HANDLER
	if(!HAS_TRAIT(owner, TRAIT_IS_WET) || !istype(organ, /obj/item/organ/tail/fish))
		return
	var/obj/item/organ/tail = owner.get_organ_slot(ORGAN_SLOT_EXTERNAL_TAIL)
	if(tail != organ)
		remove_speed_buff()
		return
	add_speed_buff()

/datum/status_effect/organ_set_bonus/fish/proc/add_speed_buff(datum/source)
	SIGNAL_HANDLER
	RegisterSignal(owner, COMSIG_LIVING_SET_BODY_POSITION, PROC_REF(check_body_position))
	check_body_position()

/datum/status_effect/organ_set_bonus/fish/proc/remove_speed_buff(datum/source)
	SIGNAL_HANDLER
	UnregisterSignal(owner, COMSIG_LIVING_SET_BODY_POSITION)
	owner.remove_movespeed_modifier(/datum/movespeed_modifier/fish_flopping)

/datum/status_effect/organ_set_bonus/fish/proc/check_body_position(datum/source)
	SIGNAL_HANDLER
	if(owner.body_position == LYING_DOWN)
		owner.add_movespeed_modifier(/datum/movespeed_modifier/fish_flopping)
	else
		owner.remove_movespeed_modifier(/datum/movespeed_modifier/fish_flopping)


///Tail for fish DNA-infused spacemen. It provides a speed buff while in water. It's also needed for the crawl speed bonus once the threshold is reached.
/obj/item/organ/tail/fish
	name = "fish tail"
	desc = "A severed tail from some sort of marine creature... or a fish-infused spaceman. It's smooth, faintly wet and definitely not flopping."
	icon = 'icons/obj/medical/organs/infuser_organs.dmi'
	icon_state = "fish_tail"
	greyscale_config = /datum/greyscale_config/fish_tail
	greyscale_colors = FISH_ORGAN_COLOR

	bodypart_overlay = /datum/bodypart_overlay/mutant/tail/fish
	dna_block = DNA_FISH_TAIL_BLOCK
	wag_flags = NONE
	organ_traits = list(TRAIT_FLOPPING)
	restyle_flags = EXTERNAL_RESTYLE_FLESH

	// Fishlike reagents, you could serve it raw like fish
	food_reagents = list(
		/datum/reagent/consumable/nutriment/protein = 10,
		/datum/reagent/consumable/nutriment/vitamin = 5,
		/datum/reagent/consumable/nutriment/fat = 10,
	)
	// Seafood instead of meat, because it's a fish organ
	foodtype_flags = RAW | SEAFOOD | GORE
	// Also just tastes like fish
	food_tastes = list("fatty fish" = 1)
	/// The fillet type this fish tail is processable into
	var/fillet_type = /obj/item/food/fishmeat/fish_tail
	/// The amount of fillets this gets processed into
	var/fillet_amount = 5

/obj/item/organ/tail/fish/Initialize(mapload)
	. = ..()
	AddElement(/datum/element/organ_set_bonus, /datum/status_effect/organ_set_bonus/fish)
	var/time_to_fillet = fillet_amount * 0.5 SECONDS
	AddElement(/datum/element/processable, TOOL_KNIFE, fillet_type, fillet_amount, time_to_fillet, screentip_verb = "Cut")

/obj/item/organ/tail/fish/on_mob_insert(mob/living/carbon/owner)
	. = ..()
	owner.AddElementTrait(TRAIT_WADDLING, type, /datum/element/waddling)
	RegisterSignal(owner, COMSIG_MOVABLE_MOVED, PROC_REF(check_location))
	RegisterSignal(owner, COMSIG_LIVING_GIBBER_ACT, PROC_REF(on_gibber_processed))
	check_location(owner, null)

/obj/item/organ/tail/fish/on_mob_remove(mob/living/carbon/owner)
	. = ..()
	owner.remove_traits(list(TRAIT_WADDLING, TRAIT_NO_STAGGER), type)
	owner.remove_movespeed_modifier(/datum/movespeed_modifier/fish_on_water)
	owner.remove_actionspeed_modifier(/datum/actionspeed_modifier/fish_on_water)
	UnregisterSignal(owner, list(COMSIG_MOVABLE_MOVED, COMSIG_LIVING_GIBBER_ACT))

/obj/item/organ/tail/fish/proc/on_gibber_processed(mob/living/carbon/owner, mob/living/user, obj/machinery/gibber, list/results)
	SIGNAL_HANDLER
	for(var/iteration in 1 to fillet_amount * 0.5)
		results += new fillet_type

/obj/item/organ/tail/fish/get_greyscale_color_from_draw_color()
	set_greyscale(bodypart_overlay.draw_color)

/obj/item/organ/tail/fish/proc/check_location(mob/living/carbon/source, atom/movable/old_loc, dir, forced)
	SIGNAL_HANDLER
	var/was_water = istype(old_loc, /turf/open/water)
	var/is_water = istype(source.loc, /turf/open/water) && !HAS_TRAIT(source.loc, TRAIT_TURF_IGNORE_SLOWDOWN)
	if(was_water && !is_water)
		source.remove_movespeed_modifier(/datum/movespeed_modifier/fish_on_water)
		source.remove_actionspeed_modifier(/datum/actionspeed_modifier/fish_on_water)
		source.add_traits(list(TRAIT_OFF_BALANCE_TACKLER, TRAIT_NO_STAGGER, TRAIT_NO_THROW_HITPUSH), type)
	else if(!was_water && is_water)
		source.add_movespeed_modifier(/datum/movespeed_modifier/fish_on_water)
		source.add_actionspeed_modifier(/datum/actionspeed_modifier/fish_on_water)
		source.add_traits(list(TRAIT_OFF_BALANCE_TACKLER, TRAIT_NO_STAGGER, TRAIT_NO_THROW_HITPUSH), type)

/datum/bodypart_overlay/mutant/tail/fish
	feature_key = "fish_tail"
	color_source = ORGAN_COLOR_OVERRIDE

/datum/bodypart_overlay/mutant/tail/fish/on_mob_insert(obj/item/organ/parent, mob/living/carbon/receiver)
	//Initialize the related dna feature block if we don't have any so it doesn't error out.
	//This isn't tied to any species, but I kinda want it to be mutable instead of having a fixed sprite accessory.
	if(imprint_on_next_insertion && !receiver.dna.features["fish_tail"])
		receiver.dna.features["fish_tail"] = pick(SSaccessories.tails_list_fish)
		receiver.dna.update_uf_block(DNA_FISH_TAIL_BLOCK)

	return ..()

/datum/bodypart_overlay/mutant/tail/fish/override_color(obj/item/bodypart/bodypart_owner)
	//If the owner uses mutant colors, inherit the color of the bodypart
	if(!bodypart_owner.owner || HAS_TRAIT(bodypart_owner.owner, TRAIT_MUTANT_COLORS))
		return bodypart_owner.draw_color
	else //otherwise get one from a set of faded out blue and some greys colors.
		return pick("#B4B8DD", "#85C7D0", "#67BBEE", "#2F4450", "#55CCBB", "#999FD0", "#345066", "#585B69", "#7381A0", "#B6DDE5", "#4E4E50")

/datum/bodypart_overlay/mutant/tail/fish/get_global_feature_list()
	return SSaccessories.tails_list_fish


///Lungs that replace the need of oxygen with water vapor or being wet
/obj/item/organ/lungs/fish
	name = "mutated gills"
	desc = "Fish DNA infused on what once was a normal pair of lungs that now require spacemen to breathe water vapor, or keep themselves covered in water."
	icon = 'icons/obj/medical/organs/infuser_organs.dmi'
	icon_state = "gills"

	// Seafood instead of meat, because it's a fish organ. Additionally gross for being gills
	foodtype_flags = RAW | SEAFOOD | GORE | GROSS
	food_tastes = list("gross fish" = 1)
	safe_oxygen_min = 0 //We don't breathe this
	///The required partial pressure of water_vapor for not suffocating.
	var/safe_water_level = parent_type::safe_oxygen_min

	/// Bodypart overlay applied to the chest where the lungs are in
	var/datum/bodypart_overlay/simple/gills/gills

	var/has_gills = TRUE

/obj/item/organ/lungs/fish/Initialize(mapload)
	. = ..()
	add_gas_reaction(/datum/gas/water_vapor, always = PROC_REF(breathe_water))
	respiration_type |= RESPIRATION_OXYGEN //after all, we get oxygen from water
	AddElement(/datum/element/organ_set_bonus, /datum/status_effect/organ_set_bonus/fish)
	if(has_gills)
		gills = new()
		AddElement(/datum/element/noticable_organ, "%PRONOUN_Theyve a set of gills on %PRONOUN_their neck.", BODY_ZONE_PRECISE_MOUTH)
	AddComponent(/datum/component/bubble_icon_override, "fish", BUBBLE_ICON_PRIORITY_ORGAN)
	AddComponent(/datum/component/speechmod, replacements = strings("crustacean_replacement.json", "crustacean"))

/obj/item/organ/lungs/fish/Destroy()
	QDEL_NULL(gills)
	return ..()

/obj/item/organ/lungs/fish/on_bodypart_insert(obj/item/bodypart/limb)
	. = ..()
	if(gills)
		limb.add_bodypart_overlay(gills)

/obj/item/organ/lungs/fish/on_bodypart_remove(obj/item/bodypart/limb)
	. = ..()
	if(gills)
		limb.remove_bodypart_overlay(gills)

/obj/item/organ/lungs/fish/on_mob_remove(mob/living/carbon/owner)
	. = ..()
	owner.clear_alert(ALERT_NOT_ENOUGH_WATER)

/// Requires the spaceman to have either water vapor or be wet.
/obj/item/organ/lungs/fish/proc/breathe_water(mob/living/carbon/breather, datum/gas_mixture/breath, water_pp, old_water_pp)
	var/need_to_breathe = !HAS_TRAIT(src, TRAIT_SPACEBREATHING) && !HAS_TRAIT(breather, TRAIT_IS_WET)
	if(water_pp < safe_water_level && need_to_breathe)
		on_low_water(breather, breath, water_pp)
		return

	if(old_water_pp < safe_water_level || breather.failed_last_breath)
		breather.failed_last_breath = FALSE
		breather.clear_alert(ALERT_NOT_ENOUGH_WATER)

	if(need_to_breathe)
		breathe_gas_volume(breath, /datum/gas/water_vapor, /datum/gas/carbon_dioxide)
	// Heal mob if not in crit.
	if(breather.health >= breather.crit_threshold && breather.oxyloss)
		breather.adjustOxyLoss(-5)

/// Called when there isn't enough water to breath
/obj/item/organ/lungs/fish/proc/on_low_water(mob/living/carbon/breather, datum/gas_mixture/breath, water_pp)
	breather.throw_alert(ALERT_NOT_ENOUGH_WATER, /atom/movable/screen/alert/not_enough_water)
	var/gas_breathed = handle_suffocation(breather, water_pp, safe_water_level, breath.gases[/datum/gas/water_vapor][MOLES])
	if(water_pp)
		breathe_gas_volume(breath, /datum/gas/water_vapor, /datum/gas/carbon_dioxide, volume = gas_breathed)

// Simple overlay so we can add gills to those with fish lungs
/datum/bodypart_overlay/simple/gills
	icon = 'icons/mob/human/fish_features.dmi'
	icon_state = "gills"
	layers = EXTERNAL_ADJACENT

/datum/bodypart_overlay/simple/gills/get_image(image_layer, obj/item/bodypart/limb)
	return image(
		icon = icon,
		icon_state = "[icon_state]_[mutant_bodyparts_layertext(image_layer)]",
		layer = image_layer,
	)

/// Subtype of gills that allow the mob to optionally breathe water.
/obj/item/organ/lungs/fish/amphibious
	name = "mutated semi-aquatic lungs"
	desc = "DNA from an amphibious or semi-aquatic creature infused on a pair lungs. Enjoy breathing underwater without drowning outside water."
	safe_oxygen_min = /obj/item/organ/lungs::safe_oxygen_min
	has_gills = FALSE
	/**
	 * If false, we don't breathe air since we've got water instead.
	 * Set to FALSE at the start of each cycle and TRUE on on_low_water()
	 */
	var/should_breathe_oxygen = FALSE

/obj/item/organ/lungs/fish/amphibious/Initialize(mapload)
	. = ..()
	/**
	 * We're setting the gas reaction for breathing oxygen here,
	 * since gas reation procs are run in the order they're added,
	 * and we want breathe_water() to run before breathe_oxygen,
	 * so that if we're breathing water vapor (or are wet), we won't have to breathe oxygen.
	 */
	safe_oxygen_min = /obj/item/organ/lungs::safe_oxygen_min
	add_gas_reaction(/datum/gas/oxygen, always = PROC_REF(breathe_oxygen))

/obj/item/organ/lungs/fish/amphibious/check_breath(datum/gas_mixture/breath, mob/living/carbon/human/breather)
	should_breathe_oxygen = FALSE //assume we don't have to breathe oxygen until we fail to breathe water
	return ..()

/obj/item/organ/lungs/fish/amphibious/on_low_water(mob/living/carbon/breather, datum/gas_mixture/breath, water_pp)
	should_breathe_oxygen = TRUE
	return

/obj/item/organ/lungs/fish/amphibious/breathe_oxygen(mob/living/carbon/breather, datum/gas_mixture/breath, o2_pp, old_o2_pp)
	if(!should_breathe_oxygen)
		if(breather.failed_last_breath) //in case we had neither oxygen nor water last tick.
			breather.clear_alert(ALERT_NOT_ENOUGH_OXYGEN)
		return
	return ..()

///Fish infuser organ, allows mobs to safely eat raw fish.
/obj/item/organ/stomach/fish
	name = "mutated fish-stomach"
	desc = "Fish DNA infused into a stomach now permeated by the faint smell of salt and slightly putrefied fish."
	icon = 'icons/obj/medical/organs/infuser_organs.dmi'
	icon_state = "stomach"
	greyscale_config = /datum/greyscale_config/mutant_organ
	greyscale_colors = FISH_COLORS

	organ_traits = list(TRAIT_STRONG_STOMACH, TRAIT_FISH_EATER)
	disgust_metabolism = 2.5

	// Seafood instead of meat, because it's a fish organ
	foodtype_flags = RAW | SEAFOOD | GORE
	// Salty and putrid like it smells, yum
	food_tastes = list(
		"salt" = 1,
		"putrid fish" = 1,
	)

/obj/item/organ/stomach/fish/Initialize(mapload)
	. = ..()
	AddElement(/datum/element/organ_set_bonus, /datum/status_effect/organ_set_bonus/fish)


///Organ from fish with the ink production trait. Doesn't count toward the organ set bonus but is buffed once it's active.
/obj/item/organ/tongue/inky
	name = "ink-secreting tongue"
	desc = "A black tongue linked to two swollen black sacs underneath the palate."
	icon = 'icons/obj/medical/organs/infuser_organs.dmi'
	icon_state = "inky_tongue"
	actions_types = list(/datum/action/cooldown/ink_spit)

	// Seafood instead of meat, because it's a fish organ
	foodtype_flags = RAW | SEAFOOD | GORE
	// Squid with a hint of the sea (from the ink)
	food_tastes = list(
		"squid" = 1,
		"the sea" = 0.2,
	)

/obj/item/organ/tongue/inky/Initialize(mapload)
	. = ..()
	AddElement(/datum/element/noticable_organ, "Slick black ink seldom rivulets from %PRONOUN_their mouth.", BODY_ZONE_PRECISE_MOUTH)

/obj/item/organ/tongue/inky/get_possible_languages()
	. = ..()
	. += /datum/language/carptongue

///Organ from fish with the toxic trait. Allows the user to use tetrodotoxin as a healing chem instead of a toxin.
/obj/item/organ/liver/fish
	name = "mutated fish-liver"
	desc = "Fish DNA infused into a stomach that now uses tetrodotoxin as regenerative material. It also processes alcohol quite well."
	icon = 'icons/obj/medical/organs/infuser_organs.dmi'
	icon_state = "liver"
	greyscale_config = /datum/greyscale_config/mutant_organ
	greyscale_colors = FISH_COLORS

	organ_traits = list(TRAIT_TETRODOTOXIN_HEALING, TRAIT_ALCOHOL_TOLERANCE) //drink like a fish :^)
	liver_resistance = parent_type::liver_resistance * 1.5
	food_reagents = list(/datum/reagent/consumable/nutriment/organ_tissue = 5, /datum/reagent/iron = 5, /datum/reagent/toxin/tetrodotoxin = 5)
	grind_results = list(/datum/reagent/consumable/nutriment/peptides = 5, /datum/reagent/toxin/tetrodotoxin = 5)

	// Seafood instead of meat, because it's a fish organ
	foodtype_flags = RAW | SEAFOOD | GORE
	// Just fish, the toxin isn't obvious
	food_tastes = list("fish" = 1)

/obj/item/organ/liver/fish/Initialize(mapload)
	. = ..()
	AddElement(/datum/element/organ_set_bonus, /datum/status_effect/organ_set_bonus/fish)

#undef FISH_ORGAN_COLOR
#undef FISH_SCLERA_COLOR
#undef FISH_PUPIL_COLOR
#undef FISH_COLORS
