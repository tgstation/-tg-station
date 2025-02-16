/*!
 * Contains Heretic grenades
 * They spread rust and obliterate borgs/mechs
 */

/obj/item/grenade/chem_grenade/rust_sower
	name = "\improper Rust sower"
	desc = "A nifty little thing that explodes into rust. Causes borgs and mechs to get utterly obliterated"
	possible_fuse_time = list("5")
	stage = GRENADE_READY
	base_icon_state = "rustgrenade"
	inhand_icon_state = "rustgrenade"
	grenade_arm_sound = 'sound/items/weapons/rust_sower_armbomb.ogg'
	grenade_sound_vary = FALSE

/obj/item/grenade/chem_grenade/rust_sower/update_icon_state()
	. = ..()
	if(active)
		icon_state = "[base_icon_state]_active"
	else
		icon_state = base_icon_state

/obj/item/grenade/chem_grenade/rust_sower/Initialize(mapload)
	. = ..()
	RegisterSignal(src, COMSIG_ITEM_ON_GRIND, PROC_REF(on_try_grind))
	var/obj/item/reagent_containers/cup/beaker/large/beaker_one = new(src)
	var/obj/item/reagent_containers/cup/beaker/large/beaker_two = new(src)

	beaker_one.reagents.add_reagent(/datum/reagent/heretic_rust, 50)
	beaker_one.reagents.add_reagent(/datum/reagent/potassium, 50)
	beaker_two.reagents.add_reagent(/datum/reagent/phosphorus, 50)
	beaker_two.reagents.add_reagent(/datum/reagent/consumable/sugar, 50)

	beakers += beaker_one
	beakers += beaker_two

/obj/item/grenade/chem_grenade/rust_sower/detonate(mob/living/lanced_by)
	. = ..()
	playsound(src, 'sound/items/weapons/rust_sower_explode.ogg', 70, FALSE)
	qdel(src)

/obj/item/grenade/chem_grenade/rust_sower/screwdriver_act(mob/living/user, obj/item/tool)
	return NONE

/obj/item/grenade/chem_grenade/rust_sower/wrench_act(mob/living/user, obj/item/tool)
	return NONE

/obj/item/grenade/chem_grenade/rust_sower/multitool_act(mob/living/user, obj/item/tool)
	return NONE

/// Returns -1 so that you cant extract the chems
/obj/item/grenade/chem_grenade/rust_sower/proc/on_try_grind()
	SIGNAL_HANDLER
	return -1

/datum/reagent/heretic_rust
	name = "Eldritch Rust"
	description = "A slurry of viscous, chunky brown liquid."
	color = COLOR_CARGO_BROWN // Rust color
	taste_description = "rotten copper"
	penetrates_skin = NONE
	ph = 7.4
	default_container = /obj/item/reagent_containers/cup/bottle/capsaicin

/datum/reagent/heretic_rust/expose_atom(atom/exposed_atom, reac_volume)
	. = ..()
	if(ismecha(exposed_atom))
		var/obj/vehicle/sealed/mecha/to_wreck = exposed_atom
		to_wreck.take_damage(300, BURN)

/datum/reagent/heretic_rust/expose_mob(mob/living/exposed_mob, methods=TOUCH, reac_volume)
	. = ..()
	if(!ishuman(exposed_mob))
		if(issilicon(exposed_mob) || ismecha(exposed_mob) || isbot(exposed_mob))
			exposed_mob.adjustBruteLoss(500)
		return
	if(IS_HERETIC(exposed_mob))
		return
	if(exposed_mob.can_block_magic(MAGIC_RESISTANCE_HOLY))
		return

	var/mob/living/carbon/victim = exposed_mob
	if(methods & (TOUCH|VAPOR|INHALE))
		//check for protection
		//actually handle the pepperspray effects
		if(!victim.is_pepper_proof()) // you need both eye and mouth protection
			if(prob(5))
				victim.emote("scream")
			victim.emote("cry")
			victim.set_eye_blur_if_lower(10 SECONDS)
			victim.adjust_temp_blindness(6 SECONDS)
			victim.set_confusion_if_lower(5 SECONDS)
			victim.Knockdown(3 SECONDS)
			victim.add_movespeed_modifier(/datum/movespeed_modifier/reagent/pepperspray)
			addtimer(CALLBACK(victim, TYPE_PROC_REF(/mob, remove_movespeed_modifier), /datum/movespeed_modifier/reagent/pepperspray), 10 SECONDS)
		victim.update_damage_hud()
		victim.adjust_disgust(5)
		for(var/obj/item/bodypart/robotic_limb in victim.bodyparts)
			if(robotic_limb.biological_state & BIO_ROBOTIC)
				robotic_limb.receive_damage(5, 5)
	if(methods & INGEST)
		if(!holder.has_reagent(/datum/reagent/consumable/milk))
			if(prob(15))
				to_chat(exposed_mob, span_danger("[pick("Your head pounds.", "Your mouth feels like it's on fire.", "You feel dizzy.")]"))
			if(prob(10))
				victim.set_eye_blur_if_lower(2 SECONDS)
			if(prob(10))
				victim.set_dizzy_if_lower(2 SECONDS)
			if(prob(5))
				victim.vomit(VOMIT_CATEGORY_DEFAULT)

/datum/reagent/heretic_rust/expose_turf(turf/exposed_turf, reac_volume)
	. = ..()
	exposed_turf.rust_turf()

/datum/reagent/heretic_rust/on_mob_life(mob/living/carbon/affected_mob, seconds_per_tick, times_fired)
	. = ..()
	if(!holder.has_reagent(/datum/reagent/consumable/milk))
		if(SPT_PROB(5, seconds_per_tick))
			affected_mob.visible_message(span_warning("[affected_mob] [pick("dry heaves!","coughs!","splutters!")]"))
