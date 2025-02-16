//cleansed 9/15/2012 17:48

/*
CONTAINS:
MATCHES
CIGARETTES
CIGARS
SMOKING PIPES

CIGARETTE PACKETS ARE IN FANCY.DM
*/

///////////
//MATCHES//
///////////
/obj/item/match
	name = "match"
	desc = "A simple match stick, used for lighting fine smokables."
	icon = 'icons/obj/cigarettes.dmi'
	icon_state = "match_unlit"
	inhand_icon_state = "cigoff"
	base_icon_state = "match"
	w_class = WEIGHT_CLASS_TINY
	heat = 1000
	grind_results = list(/datum/reagent/phosphorus = 2)
	/// Whether this match has been lit.
	var/lit = FALSE
	/// Whether this match has burnt out.
	var/burnt = FALSE
	/// How long the match lasts in seconds
	var/smoketime = 10 SECONDS
	/// If the match is broken
	var/broken = FALSE

/obj/item/match/process(seconds_per_tick)
	smoketime -= seconds_per_tick * (1 SECONDS)
	if(smoketime <= 0)
		matchburnout()
	else
		open_flame(heat)

/obj/item/match/fire_act(exposed_temperature, exposed_volume)
	. = ..()
	matchignite()

/obj/item/match/update_name(updates)
	. = ..()
	if(lit)
		name = "lit [initial(name)]"
	else if(burnt)
		name = "burnt [initial(name)]"
	else if(broken)
		name = "broken [initial(name)]"
	else
		name = "[initial(name)]"

/obj/item/match/update_desc(updates)
	. = ..()
	if(lit)
		desc = "[initial(desc)]. This one is lit."
	else if(burnt)
		desc = "[initial(desc)]. This one has seen better days."
	else if(broken)
		desc = "[initial(desc)]. This one is broken."
	else
		desc = initial(desc)

/obj/item/match/update_icon_state()
	. = ..()
	inhand_icon_state = "cigoff"
	if(lit)
		icon_state = "[base_icon_state]_lit"
		inhand_icon_state = "cigon"
	else if(burnt)
		icon_state = "[base_icon_state]_burnt"
	else if(broken)
		icon_state = "[base_icon_state]_broken"
	else
		icon_state = "[base_icon_state]_unlit"

/obj/item/match/proc/snap()
	if(broken)
		return
	if(lit)
		matchburnout()

	playsound(src, 'sound/effects/snap.ogg', 15, TRUE)
	broken = TRUE
	attack_verb_continuous = string_list(list("flicks"))
	attack_verb_simple = string_list(list("flick"))
	STOP_PROCESSING(SSobj, src)
	update_appearance()

/obj/item/match/proc/matchignite()
	if(lit || burnt || broken)
		return

	playsound(src, 'sound/items/match_strike.ogg', 15, TRUE)
	lit = TRUE
	damtype = BURN
	force = 3
	hitsound = 'sound/items/tools/welder.ogg'
	attack_verb_continuous = string_list(list("burns", "singes"))
	attack_verb_simple = string_list(list("burn", "singe"))
	if(isliving(loc))
		var/mob/living/male_model = loc
		if(male_model.fire_stacks && !(male_model.on_fire))
			male_model.ignite_mob()
	START_PROCESSING(SSobj, src)
	update_appearance()

/obj/item/match/proc/matchburnout()
	if(!lit)
		return

	lit = FALSE
	burnt = TRUE
	damtype = BRUTE
	force = initial(force)
	attack_verb_continuous = string_list(list("flicks"))
	attack_verb_simple = string_list(list("flick"))
	STOP_PROCESSING(SSobj, src)
	update_appearance()

/obj/item/match/extinguish()
	. = ..()
	matchburnout()

/obj/item/match/dropped(mob/user)
	matchburnout()
	return ..()

/obj/item/match/attack(mob/living/carbon/M, mob/living/carbon/user)
	if(!isliving(M))
		return

	if(lit && M.ignite_mob())
		message_admins("[ADMIN_LOOKUPFLW(user)] set [key_name_admin(M)] on fire with [src] at [AREACOORD(user)]")
		user.log_message("set [key_name(M)] on fire with [src]", LOG_ATTACK)

	var/obj/item/cigarette/cig = help_light_cig(M)
	if(!lit || !cig || user.combat_mode)
		..()
		return

	if(cig.lit)
		to_chat(user, span_warning("[cig] is already lit!"))
	if(M == user)
		cig.attackby(src, user)
	else
		cig.light(span_notice("[user] holds [src] out for [M], and lights [cig]."))

/// Finds a cigarette on another mob to help light.
/obj/item/proc/help_light_cig(mob/living/M)
	var/mask_item = M.get_item_by_slot(ITEM_SLOT_MASK)
	if(istype(mask_item, /obj/item/cigarette))
		return mask_item

/obj/item/match/get_temperature()
	return lit * heat

/obj/item/match/firebrand
	name = "firebrand"
	desc = "An unlit firebrand. It makes you wonder why it's not just called a stick."
	smoketime = 40 SECONDS
	custom_materials = list(/datum/material/wood = SHEET_MATERIAL_AMOUNT)
	grind_results = list(/datum/reagent/carbon = 2)

/obj/item/match/firebrand/Initialize(mapload)
	. = ..()
	matchignite()

//////////////////
//FINE SMOKABLES//
//////////////////

/obj/item/cigarette
	name = "cigarette"
	desc = "A roll of tobacco and nicotine. It is not food."
	icon = 'icons/obj/cigarettes.dmi'
	worn_icon = 'icons/mob/clothing/mask.dmi'
	icon_state = "cigoff"
	inhand_icon_state = "cigon" //gets overriden during intialize(), just have it for unit test sanity.
	throw_speed = 0.5
	w_class = WEIGHT_CLASS_TINY
	slot_flags = ITEM_SLOT_MASK
	grind_results = list()
	heat = 1000
	throw_verb = "flick"
	/// Whether this cigarette has been lit.
	VAR_FINAL/lit = FALSE
	/// Whether this cigarette should start lit.
	var/starts_lit = FALSE
	// Note - these are in masks.dmi not in cigarette.dmi
	/// The icon state used when this is lit.
	var/icon_on = "cigon"
	/// The icon state used when this is extinguished.
	var/icon_off = "cigoff"
	/// The inhand icon state used when this is lit.
	var/inhand_icon_on = "cigon"
	/// The inhand icon state used when this is extinguished.
	var/inhand_icon_off = "cigoff"
	/// How long the cigarette lasts in seconds
	var/smoketime = 6 MINUTES
	/// How much time between drags of the cigarette.
	var/dragtime = 10 SECONDS
	/// The cooldown that prevents just huffing the entire cigarette at once.
	COOLDOWN_DECLARE(drag_cooldown)
	/// The type of cigarette butt spawned when this burns out.
	var/type_butt = /obj/item/cigbutt
	/// The capacity for chems this cigarette has.
	var/chem_volume = 30
	/// The reagents that this cigarette starts with.
	var/list/list_reagents = list(/datum/reagent/drug/nicotine = 15)
	/// Should we smoke all of the chems in the cig before it runs out. Splits each puff to take a portion of the overall chems so by the end you'll always have consumed all of the chems inside.
	var/smoke_all = FALSE
	/// How much damage this deals to the lungs per drag.
	var/lung_harm = 1
	/// If, when glorf'd, we will choke on this cig forever
	var/choke_forever = FALSE
	/// When choking, what is the maximum amount of time we COULD choke for
	var/choke_time_max = 30 SECONDS // I am mean
	/// The particle effect of the smoke rising out of the cigarette when lit
	VAR_PRIVATE/obj/effect/abstract/particle_holder/cig_smoke
	/// The particle effect of the smoke rising out of the mob when...smoked
	VAR_PRIVATE/obj/effect/abstract/particle_holder/mob_smoke
	/// How long the current mob has been smoking this cigarette
	VAR_FINAL/how_long_have_we_been_smokin = 0 SECONDS
	/// Which people ate cigarettes and how many
	var/static/list/cigarette_eaters = list()

/obj/item/cigarette/Initialize(mapload)
	. = ..()
	AddComponent(/datum/component/knockoff, 90, list(BODY_ZONE_PRECISE_MOUTH), slot_flags) //90% to knock off when wearing a mask
	AddElement(/datum/element/update_icon_updates_onmob)
	RegisterSignal(src, COMSIG_ATOM_TOUCHED_SPARKS, PROC_REF(sparks_touched))
	icon_state = icon_off
	inhand_icon_state = inhand_icon_off

	// "It is called a cigarette"
	AddComponent(/datum/component/edible,\
		initial_reagents = list_reagents,\
		food_flags = FOOD_NO_EXAMINE,\
		foodtypes = JUNKFOOD,\
		volume = chem_volume,\
		eat_time = 0 SECONDS,\
		tastes = list("a never before experienced flavour", "finally sitting down after standing your entire life"),\
		eatverbs = list("taste"),\
		bite_consumption = chem_volume,\
		junkiness = 0,\
		reagent_purity = null,\
		on_consume = CALLBACK(src, PROC_REF(on_consume)),\
	)
	if(starts_lit)
		light()

/obj/item/cigarette/Destroy()
	STOP_PROCESSING(SSobj, src)
	QDEL_NULL(mob_smoke)
	QDEL_NULL(cig_smoke)
	return ..()

/obj/item/cigarette/proc/on_consume(mob/living/eater, mob/living/feeder)
	if(isnull(eater.client))
		return
	var/ckey = eater.client.ckey
	// We must have more!
	cigarette_eaters[ckey]++
	if(cigarette_eaters[ckey] >= 500)
		eater.client.give_award(/datum/award/achievement/misc/cigarettes)

/obj/item/cigarette/equipped(mob/equipee, slot)
	. = ..()
	if(!(slot & ITEM_SLOT_MASK))
		UnregisterSignal(equipee, list(COMSIG_HUMAN_FORCESAY, COMSIG_ATOM_DIR_CHANGE))
		return
	RegisterSignal(equipee, COMSIG_HUMAN_FORCESAY, PROC_REF(on_forcesay))
	RegisterSignal(equipee, COMSIG_ATOM_DIR_CHANGE, PROC_REF(on_mob_dir_change))
	if(lit && iscarbon(loc))
		make_mob_smoke(loc)

/obj/item/cigarette/dropped(mob/dropee)
	. = ..()
	// Moving the cigarette from mask to hands (or pocket I guess) will emit a larger puff of smoke
	if(!QDELETED(src) && !QDELETED(dropee) && how_long_have_we_been_smokin >= 4 SECONDS && iscarbon(dropee) && iscarbon(loc))
		var/mob/living/carbon/smoker = dropee
		// This relies on the fact that dropped is called before slot is nulled
		if(src == smoker.wear_mask && !smoker.incapacitated)
			long_exhale(smoker)

	UnregisterSignal(dropee, list(COMSIG_HUMAN_FORCESAY, COMSIG_ATOM_DIR_CHANGE))
	QDEL_NULL(mob_smoke)
	how_long_have_we_been_smokin = 0 SECONDS

/obj/item/cigarette/proc/on_forcesay(mob/living/source)
	SIGNAL_HANDLER
	source.apply_status_effect(/datum/status_effect/choke, src, lit, choke_forever ? -1 : rand(25 SECONDS, choke_time_max))

/obj/item/cigarette/proc/on_mob_dir_change(mob/living/source, old_dir, new_dir)
	SIGNAL_HANDLER
	if(isnull(mob_smoke))
		return
	update_particle_position(mob_smoke, new_dir)

/obj/item/cigarette/proc/update_particle_position(obj/effect/abstract/particle_holder/to_edit, new_dir = loc.dir)
	var/new_x = 0
	var/new_layer = initial(to_edit.layer)
	if(new_dir & NORTH)
		new_x = 4
		new_layer = BELOW_MOB_LAYER
	else if(new_dir & SOUTH)
		new_x = -4
	else if(new_dir & EAST)
		new_x = 8
	else if(new_dir & WEST)
		new_x = -8
	to_edit.set_particle_position(new_x, 8, 0)
	to_edit.layer = new_layer

/obj/item/cigarette/suicide_act(mob/living/user)
	user.visible_message(span_suicide("[user] is huffing [src] as quickly as [user.p_they()] can! It looks like [user.p_theyre()] trying to give [user.p_them()]self cancer."))
	return (TOXLOSS|OXYLOSS)

/obj/item/cigarette/attackby(obj/item/W, mob/user, params)
	if(lit)
		return ..()

	var/lighting_text = W.ignition_effect(src, user)
	if(!lighting_text)
		return ..()

	if(!check_oxygen(user)) //cigarettes need oxygen
		balloon_alert(user, "no air!")
		return ..()

	if(smoketime > 0)
		light(lighting_text)
	else
		to_chat(user, span_warning("There is nothing to smoke!"))

/// Checks that we have enough air to smoke
/obj/item/cigarette/proc/check_oxygen(mob/user)
	if (reagents.has_reagent(/datum/reagent/oxygen))
		return TRUE
	var/datum/gas_mixture/air = return_air()
	if (!isnull(air) && air.has_gas(/datum/gas/oxygen, 1))
		return TRUE
	if (!iscarbon(user))
		return FALSE
	var/mob/living/carbon/the_smoker = user
	return the_smoker.can_breathe_helmet()

/obj/item/cigarette/interact_with_atom(atom/interacting_with, mob/living/user, list/modifiers)
	if(lit) //can't dip if cigarette is lit (it will heat the reagents in the glass instead)
		return NONE
	var/obj/item/reagent_containers/cup/glass = interacting_with
	if(!istype(glass)) //you can dip cigarettes into beakers
		return NONE
	if(istype(glass, /obj/item/reagent_containers/cup/mortar))
		return NONE
	if(glass.reagents.trans_to(src, chem_volume, transferred_by = user)) //if reagents were transferred, show the message
		to_chat(user, span_notice("You dip \the [src] into \the [glass]."))
	//if not, either the beaker was empty, or the cigarette was full
	else if(!glass.reagents.total_volume)
		to_chat(user, span_warning("[glass] is empty!"))
	else
		to_chat(user, span_warning("[src] is full!"))
	return ITEM_INTERACT_SUCCESS

/obj/item/cigarette/update_icon_state()
	. = ..()
	if(lit)
		icon_state = icon_on
		inhand_icon_state = inhand_icon_on
	else
		icon_state = icon_off
		inhand_icon_state = inhand_icon_off


/obj/item/cigarette/proc/sparks_touched(datum/source, obj/effect/particle_effect)
	SIGNAL_HANDLER

	if(lit)
		return
	light()

/// Lights the cigarette with given flavor text.
/obj/item/cigarette/proc/light(flavor_text = null)
	if(lit)
		return

	lit = TRUE
	playsound(src.loc, 'sound/items/lighter/cig_light.ogg', 100, 1)
	make_cig_smoke()
	if(!(flags_1 & INITIALIZED_1))
		update_appearance(UPDATE_ICON)
		return

	attack_verb_continuous = string_list(list("burns", "singes"))
	attack_verb_simple = string_list(list("burn", "singe"))
	hitsound = 'sound/items/tools/welder.ogg'
	damtype = BURN
	force = 4
	if(reagents.get_reagent_amount(/datum/reagent/toxin/plasma)) // the plasma explodes when exposed to fire
		var/datum/effect_system/reagents_explosion/e = new()
		e.set_up(round(reagents.get_reagent_amount(/datum/reagent/toxin/plasma) / 2.5, 1), get_turf(src), 0, 0)
		e.start(src)
		qdel(src)
		return
	if(reagents.get_reagent_amount(/datum/reagent/fuel)) // the fuel explodes, too, but much less violently
		var/datum/effect_system/reagents_explosion/e = new()
		e.set_up(round(reagents.get_reagent_amount(/datum/reagent/fuel) / 5, 1), get_turf(src), 0, 0)
		e.start(src)
		qdel(src)
		return
	// allowing reagents to react after being lit
	reagents.flags &= ~(NO_REACT)
	reagents.handle_reactions()
	update_appearance(UPDATE_ICON)
	if(flavor_text)
		var/turf/T = get_turf(src)
		T.visible_message(flavor_text)
	START_PROCESSING(SSobj, src)

	if(iscarbon(loc))
		var/mob/living/carbon/smoker = loc
		if(src == smoker.wear_mask)
			make_mob_smoke(smoker)

/obj/item/cigarette/extinguish()
	. = ..()
	if(!lit)
		return
	attack_verb_continuous = null
	attack_verb_simple = null
	hitsound = null
	damtype = BRUTE
	force = 0
	STOP_PROCESSING(SSobj, src)
	reagents.flags |= NO_REACT
	lit = FALSE
	playsound(src.loc, 'sound/items/lighter/cig_snuff.ogg', 100, 1)
	update_appearance(UPDATE_ICON)
	if(ismob(loc))
		to_chat(loc, span_notice("Your [name] goes out."))
	QDEL_NULL(cig_smoke)
	QDEL_NULL(mob_smoke)

/obj/item/cigarette/proc/long_exhale(mob/living/carbon/smoker)
	smoker.visible_message(
		span_notice("[smoker] exhales a large cloud of smoke from [src]."),
		span_notice("You exhale a large cloud of smoke from [src]."),
	)
	if(!isturf(smoker.loc))
		return

	var/obj/effect/abstract/particle_holder/big_smoke = new(smoker.loc, /particles/smoke/cig/big)
	update_particle_position(big_smoke, smoker.dir)
	QDEL_IN(big_smoke, big_smoke.particles.lifespan)

/// Handles processing the reagents in the cigarette.
/obj/item/cigarette/proc/handle_reagents(seconds_per_tick)
	if(!reagents.total_volume)
		return
	reagents.expose_temperature(heat, 0.05)
	if(!reagents.total_volume) //may have reacted and gone to 0 after expose_temperature
		return
	var/to_smoke = smoke_all ? (reagents.total_volume * (dragtime / smoketime)) : REAGENTS_METABOLISM
	var/mob/living/carbon/smoker = loc
	// These checks are a bit messy but at least they're fairly readable
	// Check if the smoker is a carbon mob, since it needs to have wear_mask
	if(!istype(smoker))
		// If not, check if it's a gas mask
		if(!istype(smoker, /obj/item/clothing/mask/gas))
			reagents.remove_all(to_smoke)
			return

		smoker = smoker.loc

		// If it is, check if that mask is on a carbon mob
		if(!istype(smoker) || smoker.get_item_by_slot(ITEM_SLOT_MASK) != loc)
			reagents.remove_all(to_smoke)
			return
	else
		if(src != smoker.wear_mask)
			reagents.remove_all(to_smoke)
			return

	how_long_have_we_been_smokin += seconds_per_tick * (1 SECONDS)
	reagents.expose(smoker, INHALE, min(to_smoke / reagents.total_volume, 1))
	var/obj/item/organ/lungs/lungs = smoker.get_organ_slot(ORGAN_SLOT_LUNGS)
	if(lungs && IS_ORGANIC_ORGAN(lungs))
		var/smoker_resistance = HAS_TRAIT(smoker, TRAIT_SMOKER) ? 0.5 : 1
		smoker.adjustOrganLoss(ORGAN_SLOT_LUNGS, lung_harm * smoker_resistance)
	if(!reagents.trans_to(smoker, to_smoke, methods = INHALE, ignore_stomach = TRUE))
		reagents.remove_all(to_smoke)

/obj/item/cigarette/process(seconds_per_tick)
	var/mob/living/user = isliving(loc) ? loc : null
	user?.ignite_mob()

	if(!check_oxygen(user))
		extinguish()
		return

	smoketime -= seconds_per_tick * (1 SECONDS)
	if(smoketime <= 0)
		put_out(user)
		return

	open_flame(heat)
	if((reagents?.total_volume) && COOLDOWN_FINISHED(src, drag_cooldown))
		COOLDOWN_START(src, drag_cooldown, dragtime)
		handle_reagents(seconds_per_tick)

/obj/item/cigarette/attack_self(mob/user)
	if(lit)
		put_out(user, TRUE)
	return ..()

/obj/item/cigarette/proc/put_out(mob/user, done_early = FALSE)
	var/atom/location = drop_location()
	if(!isnull(user))
		if(done_early)
			if(isfloorturf(location) && location.has_gravity())
				user.visible_message(span_notice("[user] calmly drops and treads on [src], putting it out instantly."))
				new /obj/effect/decal/cleanable/ash(location)
				long_exhale(user)
			else
				user.visible_message(span_notice("[user] pinches out [src]."))
			how_long_have_we_been_smokin = 0 SECONDS
		else
			to_chat(user, span_notice("Your [name] goes out."))
	new type_butt(location)
	qdel(src)

/obj/item/cigarette/attack(mob/living/carbon/M, mob/living/carbon/user)
	if(!istype(M))
		return ..()
	if(M.on_fire && !lit)
		light(span_notice("[user] lights [src] with [M]'s burning body. What a cold-blooded badass."))
		return
	var/obj/item/cigarette/cig = help_light_cig(M)
	if(!lit || !cig || user.combat_mode)
		return ..()

	if(cig.lit)
		to_chat(user, span_warning("\The [cig] is already lit!"))
	if(M == user)
		cig.attackby(src, user)
	else
		cig.light(span_notice("[user] holds \the [src] out for [M], and lights [M.p_their()] [cig.name]."))

/obj/item/cigarette/fire_act(exposed_temperature, exposed_volume)
	light()

/obj/item/cigarette/get_temperature()
	return lit * heat

/obj/item/cigarette/proc/make_mob_smoke(mob/living/smoker)
	mob_smoke = new(smoker, /particles/smoke/cig)
	update_particle_position(mob_smoke, smoker.dir)
	return mob_smoke

/obj/item/cigarette/proc/make_cig_smoke()
	cig_smoke = new(src, /particles/smoke/cig)
	cig_smoke.particles?.scale *= 1.5
	return cig_smoke

// Cigarette brands.
/obj/item/cigarette/space_cigarette
	desc = "A Space brand cigarette that can be smoked anywhere."
	list_reagents = list(/datum/reagent/drug/nicotine = 9, /datum/reagent/oxygen = 9)
	smoketime = 4 MINUTES // space cigs have a shorter burn time than normal cigs
	smoke_all = TRUE // so that it doesn't runout of oxygen while being smoked in space

/obj/item/cigarette/dromedary
	desc = "A DromedaryCo brand cigarette. Contrary to popular belief, does not contain Calomel, but is reported to have a watery taste."
	list_reagents = list(/datum/reagent/drug/nicotine = 13, /datum/reagent/water = 5) //camel has water

/obj/item/cigarette/uplift
	desc = "An Uplift Smooth brand cigarette. Smells refreshing."
	list_reagents = list(/datum/reagent/drug/nicotine = 13, /datum/reagent/consumable/menthol = 5)

/obj/item/cigarette/robust
	desc = "A Robust brand cigarette."

/obj/item/cigarette/robustgold
	desc = "A Robust Gold brand cigarette."
	list_reagents = list(/datum/reagent/drug/nicotine = 15, /datum/reagent/gold = 3) // Just enough to taste a hint of expensive metal.

/obj/item/cigarette/carp
	desc = "A Carp Classic brand cigarette. A small label on its side indicates that it does NOT contain carpotoxin."

/obj/item/cigarette/carp/Initialize(mapload)
	. = ..()
	if(!prob(5))
		return
	reagents?.add_reagent(/datum/reagent/toxin/carpotoxin , 3) // They lied

/obj/item/cigarette/syndicate
	desc = "An unknown brand cigarette."
	chem_volume = 60
	smoketime = 2 MINUTES
	smoke_all = TRUE
	lung_harm = 1.5
	list_reagents = list(/datum/reagent/drug/nicotine = 10, /datum/reagent/medicine/omnizine = 15)

/obj/item/cigarette/shadyjims
	desc = "A Shady Jim's Super Slims cigarette."
	lung_harm = 1.5
	list_reagents = list(/datum/reagent/drug/nicotine = 15, /datum/reagent/toxin/lipolicide = 4, /datum/reagent/ammonia = 2, /datum/reagent/toxin/plantbgone = 1, /datum/reagent/toxin = 1.5)

/obj/item/cigarette/xeno
	desc = "A Xeno Filtered brand cigarette."
	lung_harm = 2
	list_reagents = list (/datum/reagent/drug/nicotine = 20, /datum/reagent/medicine/regen_jelly = 15, /datum/reagent/drug/krokodil = 4)

// Rollies.

/obj/item/cigarette/rollie
	name = "rollie"
	desc = "A roll of dried plant matter wrapped in thin paper."
	icon_state = "spliffoff"
	icon_on = "spliffon"
	icon_off = "spliffoff"
	type_butt = /obj/item/cigbutt/roach
	throw_speed = 0.5
	smoketime = 4 MINUTES
	chem_volume = 50
	list_reagents = null
	choke_time_max = 40 SECONDS

/obj/item/cigarette/rollie/Initialize(mapload)
	name = pick(list(
		"bifta",
		"bifter",
		"bird",
		"blunt",
		"bloint",
		"boof",
		"boofer",
		"bomber",
		"bone",
		"bun",
		"doink",
		"doob",
		"doober",
		"doobie",
		"dutch",
		"fatty",
		"hogger",
		"hooter",
		"hootie",
		"\improper J",
		"jay",
		"jimmy",
		"joint",
		"juju",
		"jeebie weebie",
		"number",
		"owl",
		"phattie",
		"puffer",
		"reef",
		"reefer",
		"rollie",
		"scoobie",
		"shorty",
		"spiff",
		"spliff",
		"toke",
		"torpedo",
		"zoot",
		"zooter"))
	. = ..()
	pixel_x = rand(-5, 5)
	pixel_y = rand(-5, 5)

/obj/item/cigarette/rollie/nicotine
	list_reagents = list(/datum/reagent/drug/nicotine = 15)

/obj/item/cigarette/rollie/trippy
	list_reagents = list(/datum/reagent/drug/nicotine = 15, /datum/reagent/drug/mushroomhallucinogen = 35)
	starts_lit = TRUE

/obj/item/cigarette/rollie/cannabis
	list_reagents = list(/datum/reagent/drug/cannabis = 15)

/obj/item/cigarette/rollie/mindbreaker
	list_reagents = list(/datum/reagent/toxin/mindbreaker = 35, /datum/reagent/toxin/lipolicide = 15)

/obj/item/cigarette/candy
	name = "\improper Little Timmy's candy cigarette"
	desc = "For all ages*! Doesn't contain any amount of nicotine. Health and safety risks can be read on the tip of the cigarette."
	smoketime = 2 MINUTES
	icon_state = "candyoff"
	icon_on = "candyon"
	icon_off = "candyoff" //make sure to add positional sprites in icons/obj/cigarettes.dmi if you add more.
	inhand_icon_off = "candyoff"
	type_butt = /obj/item/food/candy_trash
	heat = 473.15 // Lowered so that the sugar can be carmalized, but not burnt.
	lung_harm = 0.5
	list_reagents = list(/datum/reagent/consumable/sugar = 20)
	choke_time_max = 70 SECONDS // This shit really is deadly

/obj/item/cigarette/candy/nicotine
	desc = "For all ages*! Doesn't contain any* amount of nicotine. Health and safety risks can be read on the tip of the cigarette."
	type_butt = /obj/item/food/candy_trash/nicotine
	list_reagents = list(/datum/reagent/consumable/sugar = 20, /datum/reagent/drug/nicotine = 20) //oh no!
	smoke_all = TRUE //timmy's not getting out of this one

/obj/item/cigbutt/roach
	name = "roach"
	desc = "A manky old roach, or for non-stoners, a used rollup."
	icon_state = "roach"

/obj/item/cigbutt/roach/Initialize(mapload)
	. = ..()
	pixel_x = rand(-5, 5)
	pixel_y = rand(-5, 5)


/obj/item/cigarette/dart
	name = "fat dart"
	desc = "Chuff back this fat dart"
	icon_state = "bigon"
	icon_on = "bigon"
	icon_off = "bigoff"
	w_class = WEIGHT_CLASS_BULKY
	smoketime = 18 MINUTES
	chem_volume = 65
	list_reagents = list(/datum/reagent/drug/nicotine = 45)
	choke_time_max = 40 SECONDS
	lung_harm = 2

/obj/item/cigarette/dart/Initialize(mapload)
	. = ..()
	//the compiled icon state is how it appears when it's on.
	//That's how we want it to show on orbies (little virtual PDA pets).
	//However we should reset their appearance on runtime.
	update_appearance(UPDATE_ICON_STATE)


////////////
// CIGARS //
////////////
/obj/item/cigarette/cigar
	name = "cigar"
	desc = "A brown roll of tobacco and... well, you're not quite sure. This thing's huge!"
	icon_state = "cigaroff"
	icon_on = "cigaron"
	icon_off = "cigaroff" //make sure to add positional sprites in icons/obj/cigarettes.dmi if you add more.
	inhand_icon_state = "cigaron" //gets overriden during intialize(), just have it for unit test sanity.
	inhand_icon_on = "cigaron"
	inhand_icon_off = "cigaroff"
	type_butt = /obj/item/cigbutt/cigarbutt
	throw_speed = 0.5
	smoketime = 11 MINUTES
	chem_volume = 40
	list_reagents = list(/datum/reagent/drug/nicotine = 25)
	choke_time_max = 40 SECONDS

/obj/item/cigarette/cigar/premium
	name = "premium cigar"
	//this is the version that actually spawns in premium cigar cases, the distinction is made so that the smoker quirk can differentiate between the default cigar box and its subtypes

/obj/item/cigarette/cigar/cohiba
	name = "\improper Cohiba Robusto cigar"
	desc = "There's little more you could want from a cigar."
	icon_state = "cigar2off"
	icon_on = "cigar2on"
	icon_off = "cigar2off"
	smoketime = 20 MINUTES
	chem_volume = 80
	list_reagents = list(/datum/reagent/drug/nicotine = 40)

/obj/item/cigarette/cigar/havana
	name = "premium Havanian cigar"
	desc = "A cigar fit for only the best of the best."
	icon_state = "cigar2off"
	icon_on = "cigar2on"
	icon_off = "cigar2off"
	smoketime = 30 MINUTES
	chem_volume = 60
	list_reagents = list(/datum/reagent/drug/nicotine = 45)

/obj/item/cigbutt
	name = "cigarette butt"
	desc = "A manky old cigarette butt."
	icon = 'icons/obj/cigarettes.dmi'
	icon_state = "cigbutt"
	w_class = WEIGHT_CLASS_TINY
	throwforce = 0
	grind_results = list(/datum/reagent/carbon = 2)

/obj/item/cigbutt/cigarbutt
	name = "cigar butt"
	desc = "A manky old cigar butt."
	icon_state = "cigarbutt"

/////////////////
//SMOKING PIPES//
/////////////////
/obj/item/cigarette/pipe
	name = "smoking pipe"
	desc = "A pipe, for smoking. Probably made of meerschaum or something."
	icon_state = "pipeoff"
	icon_on = "pipeoff"  //Note - these are in masks.dmi
	icon_off = "pipeoff"
	inhand_icon_state = null
	inhand_icon_on = null
	inhand_icon_off = null
	smoketime = 0
	chem_volume = 200 // So we can fit densified chemicals plants
	list_reagents = null
	w_class = WEIGHT_CLASS_SMALL
	choke_forever = TRUE
	///name of the stuff packed inside this pipe
	var/packeditem

/obj/item/cigarette/pipe/Initialize(mapload)
	. = ..()
	update_appearance(UPDATE_NAME)

/obj/item/cigarette/pipe/update_name()
	. = ..()
	name = packeditem ? "[packeditem]-packed [initial(name)]" : "empty [initial(name)]"

/obj/item/cigarette/pipe/put_out(mob/user, done_early = FALSE)
	lit = FALSE
	if(done_early)
		user.visible_message(span_notice("[user] puts out [src]."), span_notice("You put out [src]."))

	else
		if(user)
			to_chat(user, span_notice("Your [name] goes out."))
		packeditem = null
	update_appearance(UPDATE_ICON)
	STOP_PROCESSING(SSobj, src)
	QDEL_NULL(cig_smoke)

/obj/item/cigarette/pipe/attackby(obj/item/thing, mob/user, params)
	if(!istype(thing, /obj/item/food/grown))
		return ..()

	var/obj/item/food/grown/to_smoke = thing
	if(packeditem)
		to_chat(user, span_warning("It is already packed!"))
		return
	if(!HAS_TRAIT(to_smoke, TRAIT_DRIED))
		to_chat(user, span_warning("It has to be dried first!"))
		return

	to_chat(user, span_notice("You stuff [to_smoke] into [src]."))
	smoketime = 13 MINUTES
	packeditem = to_smoke.name
	update_name()
	if(to_smoke.reagents)
		to_smoke.reagents.trans_to(src, to_smoke.reagents.total_volume, transferred_by = user)
	qdel(to_smoke)


/obj/item/cigarette/pipe/attack_self(mob/user)
	var/atom/location = drop_location()
	if(packeditem && !lit)
		to_chat(user, span_notice("You empty [src] onto [location]."))
		new /obj/effect/decal/cleanable/ash(location)
		packeditem = null
		smoketime = 0
		reagents.clear_reagents()
		update_name()
		return
	return ..()

/obj/item/cigarette/pipe/cobpipe
	name = "corn cob pipe"
	desc = "A nicotine delivery system popularized by folksy backwoodsmen and kept popular in the modern age and beyond by space hipsters. Can be loaded with objects."
	icon_state = "cobpipeoff"
	icon_on = "cobpipeoff"  //Note - these are in masks.dmi
	icon_off = "cobpipeoff"
	inhand_icon_on = null
	inhand_icon_off = null

///////////
//ROLLING//
///////////
/obj/item/rollingpaper
	name = "rolling paper"
	desc = "A thin piece of paper used to make fine smokeables."
	icon = 'icons/obj/cigarettes.dmi'
	icon_state = "cig_paper"
	w_class = WEIGHT_CLASS_TINY

/obj/item/rollingpaper/Initialize(mapload)
	. = ..()
	AddComponent(/datum/component/ingredients_holder, /obj/item/cigarette/rollie, CUSTOM_INGREDIENT_ICON_NOCHANGE, ingredient_type=CUSTOM_INGREDIENT_TYPE_DRYABLE, max_ingredients=2)


///////////////
//VAPE NATION//
///////////////
/obj/item/vape
	name = "\improper E-Cigarette"
	desc = "A classy and highly sophisticated electronic cigarette, for classy and dignified gentlemen. A warning label reads \"Warning: Do not fill with flammable materials.\""//<<< i'd vape to that.
	icon_state = "vape"
	worn_icon_state = "vape_worn"
	greyscale_config = /datum/greyscale_config/vape
	greyscale_config_worn = /datum/greyscale_config/vape/worn
	greyscale_colors = "#2e2e2e"
	inhand_icon_state = null
	w_class = WEIGHT_CLASS_TINY
	slot_flags = ITEM_SLOT_MASK
	flags_1 = IS_PLAYER_COLORABLE_1

	/// The capacity of the vape.
	var/chem_volume = 100
	/// The amount of time between drags.
	var/dragtime = 8 SECONDS
	/// A cooldown to prevent huffing the vape all at once.
	COOLDOWN_DECLARE(drag_cooldown)
	/// Whether the resevoir is open and we can add reagents.
	var/screw = FALSE
	/// Whether the vape has been overloaded to spread smoke.
	var/super = FALSE

/obj/item/vape/Initialize(mapload)
	. = ..()
	create_reagents(chem_volume, NO_REACT)
	reagents.add_reagent(/datum/reagent/drug/nicotine, 50)

/obj/item/vape/suicide_act(mob/living/user)
	user.visible_message(span_suicide("[user] is puffin hard on dat vape, [user.p_they()] trying to join the vape life on a whole notha plane!"))//it doesn't give you cancer, it is cancer
	return (TOXLOSS|OXYLOSS)

/obj/item/vape/screwdriver_act(mob/living/user, obj/item/tool)
	if(!screw)
		screw = TRUE
		to_chat(user, span_notice("You open the cap on [src]."))
		reagents.flags |= OPENCONTAINER
		if(obj_flags & EMAGGED)
			icon_state = "vapeopen_high"
			set_greyscale(new_config = /datum/greyscale_config/vape/open_high)
		else if(super)
			icon_state = "vapeopen_med"
			set_greyscale(new_config = /datum/greyscale_config/vape/open_med)
		else
			icon_state = "vapeopen_low"
			set_greyscale(new_config = /datum/greyscale_config/vape/open_low)
	else
		screw = FALSE
		to_chat(user, span_notice("You close the cap on [src]."))
		reagents.flags &= ~(OPENCONTAINER)
		icon_state = initial(icon_state)
		set_greyscale(new_config = initial(greyscale_config))

/obj/item/vape/multitool_act(mob/living/user, obj/item/tool)
	. = TRUE
	if(screw && !(obj_flags & EMAGGED))//also kinky
		if(!super)
			super = TRUE
			to_chat(user, span_notice("You increase the voltage of [src]."))
			icon_state = "vapeopen_med"
			set_greyscale(new_config = /datum/greyscale_config/vape/open_med)
		else
			super = FALSE
			to_chat(user, span_notice("You decrease the voltage of [src]."))
			icon_state = "vapeopen_low"
			set_greyscale(new_config = /datum/greyscale_config/vape/open_low)

	if(screw && (obj_flags & EMAGGED))
		to_chat(user, span_warning("[src] can't be modified!"))

/obj/item/vape/emag_act(mob/user, obj/item/card/emag/emag_card) // I WON'T REGRET WRITTING THIS, SURLY.

	if (!screw)
		balloon_alert(user, "open the cap first!")
		return FALSE

	if (obj_flags & EMAGGED)
		balloon_alert(user, "already emagged!")
		return FALSE

	obj_flags |= EMAGGED
	super = FALSE
	balloon_alert(user, "voltage maximized")
	icon_state = "vapeopen_high"
	set_greyscale(new_config = /datum/greyscale_config/vape/open_high)
	var/datum/effect_system/spark_spread/sp = new /datum/effect_system/spark_spread //for effect
	sp.set_up(5, 1, src)
	sp.start()
	return TRUE

/obj/item/vape/attack_self(mob/user)
	if(!screw)
		balloon_alert(user, "open the cap first!")
		return
	if(reagents.total_volume > 0)
		to_chat(user, span_notice("You empty [src] of all reagents."))
		reagents.clear_reagents()

/obj/item/vape/equipped(mob/user, slot)
	. = ..()
	if(!(slot & ITEM_SLOT_MASK))
		return

	if(screw)
		to_chat(user, span_warning("You need to close the cap first!"))
		return

	to_chat(user, span_notice("You start puffing on the vape."))
	reagents.flags &= ~(NO_REACT)
	START_PROCESSING(SSobj, src)

/obj/item/vape/dropped(mob/user)
	. = ..()
	if(user.get_item_by_slot(ITEM_SLOT_MASK) == src)
		reagents.flags |= NO_REACT
		STOP_PROCESSING(SSobj, src)

/obj/item/vape/proc/handle_reagents()
	if(!reagents.total_volume)
		return

	var/mob/living/carbon/vaper = loc
	if(!iscarbon(vaper) || src != vaper.wear_mask)
		reagents.remove_all(REAGENTS_METABOLISM)
		return

	if(reagents.get_reagent_amount(/datum/reagent/fuel))
		//HOT STUFF
		vaper.adjust_fire_stacks(2)
		vaper.ignite_mob()

	if(reagents.get_reagent_amount(/datum/reagent/toxin/plasma)) // the plasma explodes when exposed to fire
		var/datum/effect_system/reagents_explosion/e = new()
		e.set_up(round(reagents.get_reagent_amount(/datum/reagent/toxin/plasma) / 2.5, 1), get_turf(src), 0, 0)
		e.start(src)
		qdel(src)

	if(!reagents.trans_to(vaper, REAGENTS_METABOLISM, methods = INHALE, ignore_stomach = TRUE))
		reagents.remove_all(REAGENTS_METABOLISM)

/obj/item/vape/process(seconds_per_tick)
	var/mob/living/M = loc

	if(isliving(loc))
		M.ignite_mob()

	if(!reagents.total_volume)
		if(ismob(loc))
			to_chat(M, span_warning("[src] is empty!"))
			STOP_PROCESSING(SSobj, src)
			//it's reusable so it won't unequip when empty
		return

	if(!COOLDOWN_FINISHED(src, drag_cooldown))
		return

	//Time to start puffing those fat vapes, yo.
	COOLDOWN_START(src, drag_cooldown, dragtime)
	if(obj_flags & EMAGGED)
		var/datum/effect_system/fluid_spread/smoke/chem/smoke_machine/puff = new
		puff.set_up(4, holder = src, location = loc, carry = reagents, efficiency = 24)
		puff.start()
		if(prob(5)) //small chance for the vape to break and deal damage if it's emagged
			playsound(get_turf(src), 'sound/effects/pop_expl.ogg', 50, FALSE)
			M.apply_damage(20, BURN, BODY_ZONE_HEAD)
			M.Paralyze(300)
			var/datum/effect_system/spark_spread/sp = new /datum/effect_system/spark_spread
			sp.set_up(5, 1, src)
			sp.start()
			to_chat(M, span_userdanger("[src] suddenly explodes in your mouth!"))
			qdel(src)
			return
	else if(super)
		var/datum/effect_system/fluid_spread/smoke/chem/smoke_machine/puff = new
		puff.set_up(1, holder = src, location = loc, carry = reagents, efficiency = 24)
		puff.start()

	handle_reagents()

/obj/item/vape/red
	greyscale_colors = "#A02525"
	flags_1 = NONE

/obj/item/vape/blue
	greyscale_colors = "#294A98"
	flags_1 = NONE

/obj/item/vape/purple
	greyscale_colors = "#9900CC"
	flags_1 = NONE

/obj/item/vape/green
	greyscale_colors = "#3D9829"
	flags_1 = NONE

/obj/item/vape/yellow
	greyscale_colors = "#DAC20E"
	flags_1 = NONE

/obj/item/vape/orange
	greyscale_colors = "#da930e"
	flags_1 = NONE

/obj/item/vape/black
	greyscale_colors = "#2e2e2e"
	flags_1 = NONE

/obj/item/vape/white
	greyscale_colors = "#DCDCDC"
	flags_1 = NONE
