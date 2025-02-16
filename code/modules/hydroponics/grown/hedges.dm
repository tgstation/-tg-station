/obj/item/seeds/shrub
	name = "shrub seed pack"
	desc = "These seeds grow into hedge shrubs."
	icon_state = "seed-shrub"
	species = "shrub"
	plantname = "Shrubbery"
	product = /obj/item/grown/shrub
	lifespan = 40
	endurance = 30
	maturation = 4
	production = 6
	yield = 2
	instability = 10
	growthstages = 3
	reagents_add = list()
	mutatelist = list(/obj/item/seeds/organ_tree)

/obj/item/grown/shrub
	seed = /obj/item/seeds/shrub
	name = "shrub"
	desc = "A shrubbery, it looks nice and it was only a few credits too. Plant it on the ground to grow a hedge, shrubbing skills not required."
	icon_state = "shrub"

/obj/item/grown/shrub/attack_self(mob/user)
	var/turf/player_turf = get_turf(user)
	if(player_turf?.is_blocked_turf(TRUE))
		return FALSE
	user.visible_message(span_danger("[user] begins to plant \the [src]..."))
	if(do_after(user, 8 SECONDS, target = user.drop_location(), progress = TRUE))
		new /obj/structure/hedge/opaque(user.drop_location())
		to_chat(user, span_notice("You plant \the [src]."))
		qdel(src)

///the structure placed by the shrubs
/obj/structure/hedge
	name = "hedge"
	desc = "A large bushy hedge."
	icon = 'icons/obj/smooth_structures/hedge.dmi'
	icon_state = "hedge-0"
	base_icon_state = "hedge"
	smoothing_flags = SMOOTH_BITMASK
	smoothing_groups = SMOOTH_GROUP_HEDGE_FLUFF
	canSmoothWith = SMOOTH_GROUP_HEDGE_FLUFF
	density = TRUE
	anchored = TRUE
	opacity = FALSE
	max_integrity = 80

/obj/structure/hedge/attacked_by(obj/item/I, mob/living/user)
	if(opacity && HAS_TRAIT(user, TRAIT_BONSAI) && I.get_sharpness())
		to_chat(user,span_notice("You start trimming \the [src]."))
		if(do_after(user, 3 SECONDS,target=src))
			to_chat(user,span_notice("You finish trimming \the [src]."))
			opacity = FALSE
	else
		return ..()
/**
 * useful for mazes and such
 */
/obj/structure/hedge/opaque
	opacity = TRUE

/obj/item/seeds/organ_tree
	name = "organ tree seed pack"
	desc = "These seeds grow into an organ tree."
	icon_state = "seed-organ"
	species = "organ"
	plantname = "Organ Tree"
	product = null // handled snowflake
	lifespan = 10 // organs rot fast
	maturation = 5
	production = 15 // organ growing takes a while
	endurance = 50
	yield = 1
	instability = 2
	growthstages = 3
	genes = list(/datum/plant_gene/trait/complex_harvest)

/obj/item/seeds/organ_tree/harvest(mob/user)
	var/yield_amount = getYield()
	var/obj/machinery/hydroponics/parent = loc
	if(yield_amount <= 0)
		parent.update_tray(user, yield_amount)
		return list()

	var/list/possible_organs = list(
		/obj/item/bodypart/arm/left/pod = 2,
		/obj/item/bodypart/arm/right/pod = 2,
		/obj/item/bodypart/leg/left/pod = 2,
		/obj/item/bodypart/leg/right/pod = 2,
		/obj/item/food/meat/slab/human/mutant/plant = 3,
		/obj/item/organ/appendix/pod = 1,
		/obj/item/organ/brain/pod = 1,
		/obj/item/organ/ears/pod = 1,
		/obj/item/organ/eyes/pod = 1,
		/obj/item/organ/heart/pod = 1,
		/obj/item/organ/liver/pod = 1,
		/obj/item/organ/lungs/pod = 1,
		/obj/item/organ/stomach/pod = 1,
		/obj/item/organ/tongue/pod = 1,
	)

	var/list/created = list()
	var/atom/drop_at = user.Adjacent(loc) ? user.drop_location() : drop_location()
	for(var/i in 1 to yield)
		var/organ = pick_weight(possible_organs)
		if(prob(66)) // 66% chance to reduce the chance to 0 so we get less duplicates
			possible_organs[organ] = 0
		var/obj/item/spawned = new organ(drop_at)
		if(isbodypart(spawned))
			var/obj/item/bodypart/bodypart_spawned = spawned
			bodypart_spawned.species_color = COLOR_GREEN
			bodypart_spawned.update_icon_dropped()
		qdel(spawned.GetComponent(/datum/component/decomposition))
		qdel(spawned.GetComponent(/datum/component/germ_sensitive))
		created += spawned

	parent.update_tray(user, yield_amount)

	return created
