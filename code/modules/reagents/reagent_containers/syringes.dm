/obj/item/reagent_containers/syringe
	name = "syringe"
	desc = "A syringe that can hold up to 15 units."
	icon = 'icons/obj/medical/syringe.dmi'
	base_icon_state = "syringe"
	lefthand_file = 'icons/mob/inhands/equipment/medical_lefthand.dmi'
	righthand_file = 'icons/mob/inhands/equipment/medical_righthand.dmi'
	icon_state = "syringe_0"
	inhand_icon_state = "syringe_0"
	worn_icon_state = "pen"
	amount_per_transfer_from_this = 5
	possible_transfer_amounts = list(5, 10, 15)
	volume = 15
	custom_materials = list(/datum/material/iron=SMALL_MATERIAL_AMOUNT, /datum/material/glass=SMALL_MATERIAL_AMOUNT*0.2)
	reagent_flags = TRANSPARENT
	custom_price = PAYCHECK_CREW * 0.5
	sharpness = SHARP_POINTY
	embed_type = /datum/embedding/syringe
	/// Flags used by the injection
	var/inject_flags = NONE
	/// Icon and states used when inserted into toy darts
	var/dart_insert_icon = 'icons/obj/weapons/guns/toy.dmi'
	var/dart_insert_casing_icon_state = "overlay_syringe"
	var/dart_insert_projectile_icon_state = "overlay_syringe_proj"

/obj/item/reagent_containers/syringe/Initialize(mapload)
	. = ..()
	AddElement(/datum/element/update_icon_updates_onmob)
	AddComponent(/datum/component/dart_insert, \
		dart_insert_icon, \
		dart_insert_casing_icon_state, \
		dart_insert_icon, \
		dart_insert_projectile_icon_state, \
		CALLBACK(src, PROC_REF(get_dart_var_modifiers))\
	)

/obj/item/reagent_containers/syringe/attackby(obj/item/I, mob/user, params)
	return

/obj/item/reagent_containers/syringe/proc/try_syringe(atom/target, mob/user)
	if(!target.reagents)
		return FALSE

	if(isliving(target))
		var/mob/living/living_target = target
		if(!living_target.try_inject(user, injection_flags = INJECT_TRY_SHOW_ERROR_MESSAGE|inject_flags))
			return FALSE

	return TRUE

/obj/item/reagent_containers/syringe/interact_with_atom(atom/target, mob/living/user, list/modifiers)
	if(!target.reagents)
		return NONE
	if(!try_syringe(target, user))
		return ITEM_INTERACT_BLOCKING

	SEND_SIGNAL(target, COMSIG_LIVING_TRY_SYRINGE_INJECT, user)

	var/contained = reagents.get_reagent_log_string()
	log_combat(user, target, "attempted to inject", src, addition="which had [contained]")

	if(!reagents.total_volume)
		to_chat(user, span_warning("[src] is empty! Right-click to draw."))
		return ITEM_INTERACT_BLOCKING

	if(!isliving(target) && !target.is_injectable(user))
		to_chat(user, span_warning("You cannot directly fill [target]!"))
		return ITEM_INTERACT_BLOCKING

	if(target.reagents.total_volume >= target.reagents.maximum_volume)
		to_chat(user, span_notice("[target] is full."))
		return ITEM_INTERACT_BLOCKING

	if(isliving(target))
		var/mob/living/living_target = target
		if(living_target != user)
			living_target.visible_message(
				span_danger("[user] is trying to inject [living_target]!"),
				span_userdanger("[user] is trying to inject you!"),
			)
			if(!do_after(user, CHEM_INTERACT_DELAY(3 SECONDS, user), living_target, extra_checks = CALLBACK(src, PROC_REF(try_syringe), living_target, user)))
				return ITEM_INTERACT_BLOCKING
			if(!reagents.total_volume)
				return ITEM_INTERACT_BLOCKING
			if(living_target.reagents.total_volume >= living_target.reagents.maximum_volume)
				return ITEM_INTERACT_BLOCKING
			living_target.visible_message(
				span_danger("[user] injects [living_target] with the syringe!"),
				span_userdanger("[user] injects you with the syringe!"),
			)

		if(living_target == user)
			living_target.log_message("injected themselves ([contained]) with [name]", LOG_ATTACK, color="orange")
		else
			log_combat(user, living_target, "injected", src, addition="which had [contained]")

	if(reagents.trans_to(target, amount_per_transfer_from_this, transferred_by = user, methods = INJECT))
		to_chat(user, span_notice("You inject [amount_per_transfer_from_this] units of the solution. The syringe now contains [reagents.total_volume] units."))
		target.update_appearance()
		return ITEM_INTERACT_SUCCESS

	return ITEM_INTERACT_BLOCKING

/obj/item/reagent_containers/syringe/interact_with_atom_secondary(atom/target, mob/living/user, list/modifiers)
	if (!target.reagents)
		return NONE
	if (!try_syringe(target, user))
		return ITEM_INTERACT_BLOCKING

	SEND_SIGNAL(target, COMSIG_LIVING_TRY_SYRINGE_WITHDRAW, user)

	if(reagents.total_volume >= reagents.maximum_volume)
		to_chat(user, span_notice("[src] is full."))
		return ITEM_INTERACT_BLOCKING

	if(isliving(target))
		var/mob/living/living_target = target
		var/drawn_amount = reagents.maximum_volume - reagents.total_volume
		if(target != user)
			target.visible_message(
				span_danger("[user] is trying to take a blood sample from [target]!"),
				span_userdanger("[user] is trying to take a blood sample from you!"),
			)
			if(!do_after(user, CHEM_INTERACT_DELAY(3 SECONDS, user), target, extra_checks = CALLBACK(src, PROC_REF(try_syringe), living_target, user)))
				return ITEM_INTERACT_BLOCKING
			if(reagents.total_volume >= reagents.maximum_volume)
				return ITEM_INTERACT_BLOCKING
		if(living_target.transfer_blood_to(src, drawn_amount))
			user.visible_message(span_notice("[user] takes a blood sample from [living_target]."))
		else
			to_chat(user, span_warning("You are unable to draw any blood from [living_target]!"))
		return ITEM_INTERACT_SUCCESS

	if(!target.reagents.total_volume)
		to_chat(user, span_warning("[target] is empty!"))
		return ITEM_INTERACT_BLOCKING

	if(!target.is_drawable(user))
		to_chat(user, span_warning("You cannot directly remove reagents from [target]!"))
		return ITEM_INTERACT_BLOCKING

	var/trans = target.reagents.trans_to(src, amount_per_transfer_from_this, transferred_by = user) // transfer from, transfer to - who cares?

	to_chat(user, span_notice("You fill [src] with [trans] units of the solution. It now contains [reagents.total_volume] units."))
	target.update_appearance()
	return ITEM_INTERACT_SUCCESS

/*
 * On accidental consumption, inject the eater with 2/3rd of the syringe and reveal it
 */
/obj/item/reagent_containers/syringe/on_accidental_consumption(mob/living/carbon/victim, mob/living/carbon/user, obj/item/source_item,  discover_after = TRUE)
	if(source_item)
		to_chat(victim, span_boldwarning("There's \a [src] in [source_item]!!"))
	else
		to_chat(victim, span_boldwarning("[src] injects you!"))

	victim.apply_damage(5, BRUTE, BODY_ZONE_HEAD)
	reagents?.trans_to(victim, round(reagents.total_volume*(2/3)), transferred_by = user, methods = INJECT)

	return discover_after

/obj/item/reagent_containers/syringe/update_icon_state()
	var/rounded_vol = get_rounded_vol()
	icon_state = inhand_icon_state = "[base_icon_state]_[rounded_vol]"
	return ..()

/obj/item/reagent_containers/syringe/update_overlays()
	. = ..()
	var/list/reagent_overlays = update_reagent_overlay()
	if(reagent_overlays)
		. += reagent_overlays

/// Returns a list of overlays to add that relate to the reagents inside the syringe
/obj/item/reagent_containers/syringe/proc/update_reagent_overlay()
	if(reagents?.total_volume)
		var/mutable_appearance/filling_overlay = mutable_appearance('icons/obj/medical/reagent_fillings.dmi', "syringe[get_rounded_vol()]")
		filling_overlay.color = mix_color_from_reagents(reagents.reagent_list)
		. += filling_overlay

///Used by update_appearance() and update_overlays()
/obj/item/reagent_containers/syringe/proc/get_rounded_vol()
	if(!reagents?.total_volume)
		return 0
	return clamp(round((reagents.total_volume / volume * 15), 5), 1, 15)

/obj/item/reagent_containers/syringe/proc/get_dart_var_modifiers(obj/projectile/projectile)
	var/datum/embedding/embed_data = get_embed().create_copy()
	embed_data.rip_time += projectile.get_embed()?.rip_time
	return list(
		"damage" = max(6, volume / 5), // Scales with size?
		"speed" = max(0, throw_speed - 3),
		"embedding" = embed_data,
		"armour_penetration" = armour_penetration,
		"wound_bonus" = wound_bonus,
		"bare_wound_bonus" = bare_wound_bonus,
		"demolition_mod" = demolition_mod,
	)

/datum/embedding/syringe
	embed_chance = 85
	fall_chance = 2
	jostle_chance = 2
	pain_stam_pct = 0.75
	pain_mult = 3
	jostle_pain_mult = 3
	rip_time = 0.5 SECONDS
	/// How much reagents are transferred per second
	var/transfer_per_second = 1.5

/datum/embedding/syringe/process_effect(seconds_per_tick)
	var/obj/item/reagent_containers/syringe = parent
	if (!istype(syringe))
		syringe = locate() in parent
		if (!istype(syringe) && isammocasing(parent))
			var/obj/item/ammo_casing/casing = parent
			syringe = locate() in casing.loaded_projectile
		if (!istype(syringe))
			return

	if (!IS_ORGANIC_LIMB(owner_limb))
		return

	if (!owner.reagents || !syringe.reagents.total_volume)
		return

	// Only show message at a small chance, otherwise this'll get spammy
	syringe.reagents.trans_to(owner, transfer_per_second * seconds_per_tick, methods = INJECT, show_message = SPT_PROB(15, seconds_per_tick))

// For syringe guns, syringe itself becomes the shrapnel
/datum/embedding/syringe/setup_shrapnel(obj/projectile/source, mob/living/carbon/victim)
	if (!istype(source, /obj/projectile/bullet/dart/syringe))
		return ..()
	var/obj/projectile/bullet/dart/syringe/syringe_dart = source
	var/obj/item/reagent_containers/syringe/syringe = syringe_dart.inner_syringe
	if (!syringe)
		return ..()
	syringe_dart.inner_syringe = null
	source.set_embed(null, dont_delete = TRUE)
	register_on(syringe)
	syringe.set_embed(src)

/datum/embedding/syringe/fall_out()
	. = ..()
	// Nothing should modify this directly (hopefully), and this makes sure that ones fired from a syringe gun don't have 100% embedding later down the line
	embed_chance = initial(embed_chance)

/obj/item/reagent_containers/syringe/epinephrine
	name = "syringe (epinephrine)"
	desc = "Contains epinephrine - used to stabilize patients."
	list_reagents = list(/datum/reagent/medicine/epinephrine = 15)

/obj/item/reagent_containers/syringe/multiver
	name = "syringe (multiver)"
	desc = "Contains multiver. Diluted with granibitaluri."
	list_reagents = list(/datum/reagent/medicine/c2/multiver = 6, /datum/reagent/medicine/granibitaluri = 9)

/obj/item/reagent_containers/syringe/calomel
	name = "syringe (calomel)"
	desc = "Contains calomel - a toxic drug for rapidly removing chemicals from the body."
	list_reagents = list(/datum/reagent/medicine/calomel = 15)

/obj/item/reagent_containers/syringe/convermol
	name = "syringe (convermol)"
	desc = "Contains convermol. Diluted with granibitaluri."
	list_reagents = list(/datum/reagent/medicine/c2/convermol = 6, /datum/reagent/medicine/granibitaluri = 9)

/obj/item/reagent_containers/syringe/antiviral
	name = "syringe (spaceacillin)"
	desc = "Contains antiviral agents."
	list_reagents = list(/datum/reagent/medicine/spaceacillin = 15)

/obj/item/reagent_containers/syringe/bioterror
	name = "bioterror syringe"
	desc = "Contains several paralyzing reagents."
	list_reagents = list(/datum/reagent/consumable/ethanol/neurotoxin = 5, /datum/reagent/toxin/mutetoxin = 5, /datum/reagent/toxin/sodium_thiopental = 5)

/obj/item/reagent_containers/syringe/calomel
	name = "syringe (calomel)"
	desc = "Contains calomel."
	list_reagents = list(/datum/reagent/medicine/calomel = 15)

/obj/item/reagent_containers/syringe/plasma
	name = "syringe (plasma)"
	desc = "Contains plasma."
	list_reagents = list(/datum/reagent/toxin/plasma = 15)

/obj/item/reagent_containers/syringe/lethal
	name = "lethal injection syringe"
	desc = "A syringe used for lethal injections. It can hold up to 50 units."
	amount_per_transfer_from_this = 50
	has_variable_transfer_amount = FALSE
	volume = 50

/obj/item/reagent_containers/syringe/lethal/choral
	list_reagents = list(/datum/reagent/toxin/chloralhydrate = 50)

/obj/item/reagent_containers/syringe/lethal/execution
	list_reagents = list(/datum/reagent/toxin/plasma = 15, /datum/reagent/toxin/formaldehyde = 15, /datum/reagent/toxin/cyanide = 10, /datum/reagent/toxin/acid/fluacid = 10)

/obj/item/reagent_containers/syringe/mulligan
	name = "Mulligan"
	desc = "A syringe used to completely change the users identity."
	amount_per_transfer_from_this = 1
	has_variable_transfer_amount = FALSE
	volume = 1
	list_reagents = list(/datum/reagent/mulligan = 1)

/obj/item/reagent_containers/syringe/gluttony
	name = "Gluttony's Blessing"
	desc = "A syringe recovered from a dread place. It probably isn't wise to use."
	amount_per_transfer_from_this = 1
	has_variable_transfer_amount = FALSE
	volume = 1
	list_reagents = list(/datum/reagent/gluttonytoxin = 1)

/obj/item/reagent_containers/syringe/bluespace
	name = "bluespace syringe"
	desc = "An advanced syringe that can hold 60 units of chemicals."
	icon_state = "bluespace_0"
	inhand_icon_state = "bluespace_0"
	base_icon_state = "bluespace"
	amount_per_transfer_from_this = 20
	possible_transfer_amounts = list(10, 20, 30, 40, 50, 60)
	volume = 60
	dart_insert_casing_icon_state = "overlay_syringe_bluespace"
	dart_insert_projectile_icon_state = "overlay_syringe_bluespace_proj"

/obj/item/reagent_containers/syringe/piercing
	name = "piercing syringe"
	desc = "A diamond-tipped syringe that pierces armor when launched at high velocity. It can hold up to 10 units."
	icon_state = "piercing_0"
	inhand_icon_state = "piercing_0"
	base_icon_state = "piercing"
	volume = 10
	possible_transfer_amounts = list(5, 10)
	inject_flags = INJECT_CHECK_PENETRATE_THICK
	armour_penetration = 40
	dart_insert_casing_icon_state = "overlay_syringe_piercing"
	dart_insert_projectile_icon_state = "overlay_syringe_piercing_proj"
	embed_type = /datum/embedding/syringe/piercing

/datum/embedding/syringe/piercing
	embed_chance = 100
	fall_chance = 1.5
	pain_stam_pct = 0.6
	transfer_per_second = 1

/obj/item/reagent_containers/syringe/crude
	name = "crude syringe"
	desc = "A crudely made syringe. The flimsy wooden construction makes it hold a minimal amounts of reagents, but its very disposable."
	icon_state = "crude_0"
	base_icon_state = "crude"
	possible_transfer_amounts = list(1,5)
	volume = 5
	dart_insert_casing_icon_state = "overlay_crude_bluespace"
	dart_insert_projectile_icon_state = "overlay_syringe_crude_proj"
	embed_type = /datum/embedding/syringe/crude

/datum/embedding/syringe/crude
	embed_chance = 75
	fall_chance = 3.5
	jostle_chance = 4
	pain_stam_pct = 0.5
	pain_mult = 5
	jostle_pain_mult = 5
	rip_time = 1 SECONDS
	transfer_per_second = 0.5

/obj/item/reagent_containers/syringe/crude/update_reagent_overlay()
	return

// Used by monkeys from the elemental plane of bananas. Reagents come from bungo pit, death berries, destroying angel, jupiter cups, and jumping beans.
/obj/item/reagent_containers/syringe/crude/tribal
	name = "tribal syringe"
	desc = "A crudely made syringe. Smells like bananas."

/obj/item/reagent_containers/syringe/crude/tribal/Initialize(mapload)
	var/toxin_to_get = pick(/datum/reagent/toxin/bungotoxin, /datum/reagent/toxin/coniine, /datum/reagent/toxin/amanitin, /datum/reagent/consumable/liquidelectricity/enriched, /datum/reagent/ants)
	list_reagents = list((toxin_to_get) = 5)
	return ..()

/obj/item/reagent_containers/syringe/crude/mushroom
	list_reagents = list(/datum/reagent/drug/mushroomhallucinogen = 5)

/obj/item/reagent_containers/syringe/crude/blastoff
	list_reagents = list(/datum/reagent/drug/blastoff = 5)

/obj/item/reagent_containers/syringe/spider_extract
	name = "spider extract syringe"
	desc = "Contains crikey juice - makes any gold core create the most deadly companions in the world."
	list_reagents = list(/datum/reagent/spider_extract = 1)

/obj/item/reagent_containers/syringe/oxandrolone
	name = "syringe (oxandrolone)"
	desc = "Contains oxandrolone, used to treat severe burns."
	list_reagents = list(/datum/reagent/medicine/oxandrolone = 15)

/obj/item/reagent_containers/syringe/salacid
	name = "syringe (salicylic acid)"
	desc = "Contains salicylic acid, used to treat severe brute damage."
	list_reagents = list(/datum/reagent/medicine/sal_acid = 15)

/obj/item/reagent_containers/syringe/penacid
	name = "syringe (pentetic acid)"
	desc = "Contains pentetic acid, used to reduce high levels of radiation and heal severe toxins."
	list_reagents = list(/datum/reagent/medicine/pen_acid = 15)

/obj/item/reagent_containers/syringe/syriniver
	name = "syringe (syriniver)"
	desc = "Contains syriniver, used to treat toxins and purge chemicals.The tag on the syringe states 'Inject one time per minute'"
	list_reagents = list(/datum/reagent/medicine/c2/syriniver = 15)

/obj/item/reagent_containers/syringe/contraband
	name = "unlabeled syringe"
	desc = "A syringe containing some sort of unknown chemical cocktail."

/obj/item/reagent_containers/syringe/contraband/Initialize(mapload)
	. = ..()
	ADD_TRAIT(src, TRAIT_CONTRABAND, INNATE_TRAIT)

/obj/item/reagent_containers/syringe/contraband/space_drugs
	list_reagents = list(/datum/reagent/drug/space_drugs = 15)

/obj/item/reagent_containers/syringe/contraband/krokodil
	list_reagents = list(/datum/reagent/drug/krokodil = 15)

/obj/item/reagent_containers/syringe/contraband/saturnx
	list_reagents = list(/datum/reagent/drug/saturnx = 15)

/obj/item/reagent_containers/syringe/contraband/methamphetamine
	list_reagents = list(/datum/reagent/drug/methamphetamine = 15)

/obj/item/reagent_containers/syringe/contraband/bath_salts
	list_reagents = list(/datum/reagent/drug/bath_salts = 15)

/obj/item/reagent_containers/syringe/contraband/fentanyl
	list_reagents = list(/datum/reagent/toxin/fentanyl = 15)

/obj/item/reagent_containers/syringe/contraband/morphine
	list_reagents = list(/datum/reagent/medicine/morphine = 15)
