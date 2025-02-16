/// Slime Extracts ///

/obj/item/slime_extract
	name = "slime extract"
	desc = "Goo extracted from a slime. Legends claim these to have \"magical powers\"."
	icon = 'icons/mob/simple/slimes.dmi'
	icon_state = "grey-core"
	force = 0
	w_class = WEIGHT_CLASS_TINY
	throwforce = 0
	throw_speed = 3
	throw_range = 6
	grind_results = list(/datum/reagent/toxin/slimejelly = 20)
	///uses before it goes inert
	var/extract_uses = 1
	///deletion timer, for delayed reactions
	var/qdel_timer = null
	///Which type of crossbred
	var/crossbreed_modification
	///Reagents required for activation
	var/list/activate_reagents = list()
	var/recurring = FALSE

/obj/item/slime_extract/examine(mob/user)
	. = ..()
	if(extract_uses > 1)
		. += "It has [extract_uses] uses remaining."

/obj/item/slime_extract/attackby(obj/item/O, mob/user)
	if(istype(O, /obj/item/slimepotion/enhancer))
		if(extract_uses >= 5 || recurring)
			to_chat(user, span_warning("You cannot enhance this extract further!"))
			return ..()
		if(O.type == /obj/item/slimepotion/enhancer) //Seriously, why is this defined here...?
			to_chat(user, span_notice("You apply the enhancer to the slime extract. It may now be reused one more time."))
			extract_uses++
		if(O.type == /obj/item/slimepotion/enhancer/max)
			to_chat(user, span_notice("You dump the maximizer on the slime extract. It can now be used a total of 5 times!"))
			extract_uses = 5
		qdel(O)
	..()

/obj/item/slime_extract/Initialize(mapload)
	. = ..()
	create_reagents(100, INJECTABLE | DRAWABLE)

/**
* Effect when activated by a Luminescent.
*
* This proc is called whenever a Luminescent consumes a slime extract. Each one is separated into major and minor effects depending on the extract. Cooldown is measured in deciseconds.
*
* * arg1 - The mob absorbing the slime extract.
* * arg2 - The valid species for the absorbtion. Should always be a Luminescent unless something very major has changed.
* * arg3 - Whether or not the activation is major or minor. Major activations have large, complex effects, minor are simple.
*/
/obj/item/slime_extract/proc/activate(mob/living/carbon/human/user, datum/species/jelly/luminescent/species, activation_type)
	to_chat(user, span_warning("Nothing happened... This slime extract cannot be activated this way."))
	return FALSE

/**
* Core-crossing: Feeding adult slimes extracts to obtain a much more powerful, single extract.
*
* By using a valid core on a living adult slime, then feeding it nine more of the same type, you can mutate it into more useful items. Not every slime type has an implemented core cross.
*/
/obj/item/slime_extract/attack(mob/living/basic/slime/target_slime, mob/user)
	if(!isslime(target_slime))
		return ..()
	if(target_slime.stat)
		to_chat(user, span_warning("The slime is dead!"))
		return
	if(target_slime.life_stage != SLIME_LIFE_STAGE_ADULT)
		to_chat(user, span_warning("The slime must be an adult to cross its core!"))
		return
	if(target_slime.crossbreed_modification && target_slime.crossbreed_modification != crossbreed_modification)
		to_chat(user, span_warning("The slime is already being crossed with a different extract!"))
		return

	if(!target_slime.crossbreed_modification)
		target_slime.crossbreed_modification = crossbreed_modification

	target_slime.applied_crossbreed_amount++
	qdel(src)
	to_chat(user, span_notice("You feed the slime [src], [target_slime.applied_crossbreed_amount == 1 ? "starting to mutate its core." : "further mutating its core."]"))
	playsound(target_slime, 'sound/effects/blob/attackblob.ogg', 50, TRUE)

	if(target_slime.applied_crossbreed_amount >= SLIME_EXTRACT_CROSSING_REQUIRED)
		target_slime.spawn_corecross()

/obj/item/slime_extract/grey
	name = "grey slime extract"
	icon_state = "grey-core"
	crossbreed_modification = "reproductive"
	activate_reagents = list(/datum/reagent/blood,/datum/reagent/toxin/plasma,/datum/reagent/water)

/obj/item/slime_extract/grey/activate(mob/living/carbon/human/user, datum/species/jelly/luminescent/species, activation_type)
	switch(activation_type)
		if(SLIME_ACTIVATE_MINOR)
			var/obj/item/food/monkeycube/M = new
			if(!user.put_in_active_hand(M))
				M.forceMove(user.drop_location())
			playsound(user, 'sound/effects/splat.ogg', 50, TRUE)
			to_chat(user, span_notice("You spit out a monkey cube."))
			return 120
		if(SLIME_ACTIVATE_MAJOR)
			to_chat(user, span_notice("Your [name] starts pulsing..."))
			if(do_after(user, 4 SECONDS, target = user))
				var/mob/living/basic/slime/new_slime = new(get_turf(user), /datum/slime_type/grey)
				playsound(user, 'sound/effects/splat.ogg', 50, TRUE)
				to_chat(user, span_notice("You spit out [new_slime]."))
				return 350
			else
				return 0

/obj/item/slime_extract/gold
	name = "gold slime extract"
	icon_state = "gold-core"
	crossbreed_modification = "symbiont"
	activate_reagents = list(/datum/reagent/blood,/datum/reagent/toxin/plasma,/datum/reagent/water)



/obj/item/slime_extract/gold/activate(mob/living/carbon/human/user, datum/species/jelly/luminescent/species, activation_type)
	switch(activation_type)
		if(SLIME_ACTIVATE_MINOR)
			user.visible_message(span_warning("[user] starts shaking!"),span_notice("Your [name] starts pulsing gently..."))
			if(do_after(user, 4 SECONDS, target = user))
				var/mob/living/spawned_mob = create_random_mob(user.drop_location(), FRIENDLY_SPAWN)
				spawned_mob.faction |= FACTION_NEUTRAL
				playsound(user, 'sound/effects/splat.ogg', 50, TRUE)
				user.visible_message(span_warning("[user] spits out [spawned_mob]!"), span_notice("You spit out [spawned_mob]!"))
				return 300

		if(SLIME_ACTIVATE_MAJOR)
			user.visible_message(span_warning("[user] starts shaking violently!"),span_warning("Your [name] starts pulsing violently..."))
			if(do_after(user, 5 SECONDS, target = user))
				var/mob/living/spawned_mob = create_random_mob(user.drop_location(), HOSTILE_SPAWN)
				if(!user.combat_mode)
					spawned_mob.faction |= FACTION_NEUTRAL
				else
					spawned_mob.faction |= FACTION_SLIME
				playsound(user, 'sound/effects/splat.ogg', 50, TRUE)
				user.visible_message(span_warning("[user] spits out [spawned_mob]!"), span_warning("You spit out [spawned_mob]!"))
				return 600

/obj/item/slime_extract/silver
	name = "silver slime extract"
	icon_state = "silver-core"
	crossbreed_modification = "consuming"
	activate_reagents = list(/datum/reagent/toxin/plasma,/datum/reagent/water)



/obj/item/slime_extract/silver/activate(mob/living/carbon/human/user, datum/species/jelly/luminescent/species, activation_type)
	switch(activation_type)
		if(SLIME_ACTIVATE_MINOR)
			var/food_type = get_random_food()
			var/obj/item/food/food_item = new food_type
			ADD_TRAIT(food_item, TRAIT_FOOD_SILVER, INNATE_TRAIT)
			if(!user.put_in_active_hand(food_item))
				food_item.forceMove(user.drop_location())
			playsound(user, 'sound/effects/splat.ogg', 50, TRUE)
			user.visible_message(span_warning("[user] spits out [food_item]!"), span_notice("You spit out [food_item]!"))
			return 200
		if(SLIME_ACTIVATE_MAJOR)
			var/drink_type = get_random_drink()
			var/obj/O = new drink_type
			if(!user.put_in_active_hand(O))
				O.forceMove(user.drop_location())
			playsound(user, 'sound/effects/splat.ogg', 50, TRUE)
			user.visible_message(span_warning("[user] spits out [O]!"), span_notice("You spit out [O]!"))
			return 200

/obj/item/slime_extract/metal
	name = "metal slime extract"
	icon_state = "metal-core"
	crossbreed_modification = "industrial"
	activate_reagents = list(/datum/reagent/toxin/plasma,/datum/reagent/water)

/obj/item/slime_extract/metal/activate(mob/living/carbon/human/user, datum/species/jelly/luminescent/species, activation_type)
	switch(activation_type)
		if(SLIME_ACTIVATE_MINOR)
			var/obj/item/stack/sheet/glass/O = new(null, 5)
			if(!user.put_in_active_hand(O))
				O.forceMove(user.drop_location())
			playsound(user, 'sound/effects/splat.ogg', 50, TRUE)
			user.visible_message(span_warning("[user] spits out [O]!"), span_notice("You spit out [O]!"))
			return 150

		if(SLIME_ACTIVATE_MAJOR)
			var/obj/item/stack/sheet/iron/O = new(null, 5)
			if(!user.put_in_active_hand(O))
				O.forceMove(user.drop_location())
			playsound(user, 'sound/effects/splat.ogg', 50, TRUE)
			user.visible_message(span_warning("[user] spits out [O]!"), span_notice("You spit out [O]!"))
			return 200

/obj/item/slime_extract/purple
	name = "purple slime extract"
	icon_state = "purple-core"
	crossbreed_modification = "regenerative"
	activate_reagents = list(/datum/reagent/blood,/datum/reagent/toxin/plasma)

/obj/item/slime_extract/purple/activate(mob/living/carbon/human/user, datum/species/jelly/luminescent/species, activation_type)
	switch(activation_type)
		if(SLIME_ACTIVATE_MINOR)
			user.adjust_nutrition(50)
			user.blood_volume += 50
			to_chat(user, span_notice("You activate [src], and your body is refilled with fresh slime jelly!"))
			return 150

		if(SLIME_ACTIVATE_MAJOR)
			to_chat(user, span_notice("You activate [src], and it releases regenerative chemicals!"))
			user.reagents.add_reagent(/datum/reagent/medicine/regen_jelly,10)
			return 600

/obj/item/slime_extract/darkpurple
	name = "dark purple slime extract"
	icon_state = "dark-purple-core"
	crossbreed_modification = "self-sustaining"
	activate_reagents = list(/datum/reagent/toxin/plasma)

/obj/item/slime_extract/darkpurple/activate(mob/living/carbon/human/user, datum/species/jelly/luminescent/species, activation_type)
	switch(activation_type)
		if(SLIME_ACTIVATE_MINOR)
			var/obj/item/stack/sheet/mineral/plasma/O = new(null, 1)
			if(!user.put_in_active_hand(O))
				O.forceMove(user.drop_location())
			playsound(user, 'sound/effects/splat.ogg', 50, TRUE)
			user.visible_message(span_warning("[user] spits out [O]!"), span_notice("You spit out [O]!"))
			return 150

		if(SLIME_ACTIVATE_MAJOR)
			var/turf/open/T = get_turf(user)
			if(istype(T))
				T.atmos_spawn_air("[GAS_PLASMA]=20")
			to_chat(user, span_warning("You activate [src], and a cloud of plasma bursts out of your skin!"))
			return 900

/obj/item/slime_extract/orange
	name = "orange slime extract"
	icon_state = "orange-core"
	crossbreed_modification = "burning"
	activate_reagents = list(/datum/reagent/blood,/datum/reagent/toxin/plasma,/datum/reagent/water)

/obj/item/slime_extract/orange/activate(mob/living/carbon/human/user, datum/species/jelly/luminescent/species, activation_type)
	switch(activation_type)
		if(SLIME_ACTIVATE_MINOR)
			to_chat(user, span_notice("You activate [src]. You start feeling hot!"))
			user.reagents.add_reagent(/datum/reagent/consumable/capsaicin,10)
			return 150

		if(SLIME_ACTIVATE_MAJOR)
			user.reagents.add_reagent(/datum/reagent/phosphorus,5)//
			user.reagents.add_reagent(/datum/reagent/potassium,5) // = smoke, along with any reagents inside mr. slime
			user.reagents.add_reagent(/datum/reagent/consumable/sugar,5)     //
			to_chat(user, span_warning("You activate [src], and a cloud of smoke bursts out of your skin!"))
			return 450

/obj/item/slime_extract/yellow
	name = "yellow slime extract"
	icon_state = "yellow-core"
	crossbreed_modification = "charged"
	activate_reagents = list(/datum/reagent/blood,/datum/reagent/toxin/plasma,/datum/reagent/water)

/obj/item/slime_extract/yellow/activate(mob/living/carbon/human/user, datum/species/jelly/luminescent/species, activation_type)
	switch(activation_type)
		if(SLIME_ACTIVATE_MINOR)
			if(species.glow_intensity != LUMINESCENT_DEFAULT_GLOW)
				to_chat(user, span_warning("Your glow is already enhanced!"))
				return
			species.update_glow(user, 5)
			addtimer(CALLBACK(species, TYPE_PROC_REF(/datum/species/jelly/luminescent, update_glow), user, LUMINESCENT_DEFAULT_GLOW), 1 MINUTES)
			to_chat(user, span_notice("You start glowing brighter."))

		if(SLIME_ACTIVATE_MAJOR)
			user.visible_message(span_warning("[user]'s skin starts flashing intermittently..."), span_warning("Your skin starts flashing intermittently..."))
			if(do_after(user, 2.5 SECONDS, target = user))
				empulse(user, 1, 2)
				user.visible_message(span_warning("[user]'s skin flashes!"), span_warning("Your skin flashes as you emit an electromagnetic pulse!"))
				return 600

/obj/item/slime_extract/red
	name = "red slime extract"
	icon_state = "red-core"
	crossbreed_modification = "sanguine"
	activate_reagents = list(/datum/reagent/blood,/datum/reagent/toxin/plasma,/datum/reagent/water)

/obj/item/slime_extract/red/activate(mob/living/carbon/human/user, datum/species/jelly/luminescent/species, activation_type)
	switch(activation_type)
		if(SLIME_ACTIVATE_MINOR)
			to_chat(user, span_notice("You activate [src]. You start feeling fast!"))
			user.reagents.add_reagent(/datum/reagent/medicine/ephedrine,5)
			return 450

		if(SLIME_ACTIVATE_MAJOR)
			user.visible_message(span_warning("[user]'s skin flashes red for a moment..."), span_warning("Your skin flashes red as you emit rage-inducing pheromones..."))
			for(var/mob/living/basic/slime/slime in viewers(get_turf(user), null))
				slime.ai_controller?.set_blackboard_key(BB_SLIME_RABID, TRUE)
				slime.visible_message(span_danger("The [slime] is driven into a frenzy!"))
			return 600

/obj/item/slime_extract/blue
	name = "blue slime extract"
	icon_state = "blue-core"
	crossbreed_modification = "stabilized"
	activate_reagents = list(/datum/reagent/blood,/datum/reagent/toxin/plasma,/datum/reagent/water)

/obj/item/slime_extract/blue/activate(mob/living/carbon/human/user, datum/species/jelly/luminescent/species, activation_type)
	switch(activation_type)
		if(SLIME_ACTIVATE_MINOR)
			to_chat(user, span_notice("You activate [src]. Your genome feels more stable!"))
			user.reagents.add_reagent(/datum/reagent/medicine/mutadone, 10)
			user.reagents.add_reagent(/datum/reagent/medicine/potass_iodide, 10)
			return 250

		if(SLIME_ACTIVATE_MAJOR)
			user.reagents.create_foam(/datum/effect_system/fluid_spread/foam, 20, log = TRUE)
			user.visible_message(span_danger("Foam spews out from [user]'s skin!"), span_warning("You activate [src], and foam bursts out of your skin!"))
			return 600

/obj/item/slime_extract/darkblue
	name = "dark blue slime extract"
	icon_state = "dark-blue-core"
	crossbreed_modification = "chilling"
	activate_reagents = list(/datum/reagent/toxin/plasma,/datum/reagent/water)

/obj/item/slime_extract/darkblue/activate(mob/living/carbon/human/user, datum/species/jelly/luminescent/species, activation_type)
	switch(activation_type)
		if(SLIME_ACTIVATE_MINOR)
			to_chat(user, span_notice("You activate [src]. You start feeling colder!"))
			user.extinguish_mob()
			user.adjust_wet_stacks(20)
			user.reagents.add_reagent(/datum/reagent/consumable/frostoil,6)
			user.reagents.add_reagent(/datum/reagent/medicine/regen_jelly,7)
			return 100

		if(SLIME_ACTIVATE_MAJOR)
			var/turf/open/T = get_turf(user)
			if(istype(T))
				T.atmos_spawn_air("[GAS_N2]=40;[TURF_TEMPERATURE(2.7)]")
			to_chat(user, span_warning("You activate [src], and icy air bursts out of your skin!"))
			return 900

/obj/item/slime_extract/pink
	name = "pink slime extract"
	icon_state = "pink-core"
	crossbreed_modification = "gentle"
	activate_reagents = list(/datum/reagent/blood,/datum/reagent/toxin/plasma)

/obj/item/slime_extract/pink/activate(mob/living/carbon/human/user, datum/species/jelly/luminescent/species, activation_type)
	switch(activation_type)
		if(SLIME_ACTIVATE_MINOR)
			if(user.gender != MALE && user.gender != FEMALE)
				to_chat(user, span_warning("You can't swap your gender!"))
				return

			if(user.gender == MALE)
				user.gender = FEMALE
				user.visible_message(span_boldnotice("[user] suddenly looks more feminine!"), span_boldwarning("You suddenly feel more feminine!"))
			else
				user.gender = MALE
				user.visible_message(span_boldnotice("[user] suddenly looks more masculine!"), span_boldwarning("You suddenly feel more masculine!"))
			return 100

		if(SLIME_ACTIVATE_MAJOR)
			user.visible_message(span_warning("[user]'s skin starts flashing hypnotically..."), span_notice("Your skin starts forming odd patterns, pacifying creatures around you."))
			for(var/mob/living/carbon/C in viewers(user, null))
				if(C != user)
					C.reagents.add_reagent(/datum/reagent/pax,2)
			return 600

/obj/item/slime_extract/green
	name = "green slime extract"
	icon_state = "green-core"
	crossbreed_modification = "mutative"
	activate_reagents = list(/datum/reagent/blood,/datum/reagent/toxin/plasma,/datum/reagent/uranium/radium)

/obj/item/slime_extract/green/activate(mob/living/carbon/human/user, datum/species/jelly/luminescent/species, activation_type)
	switch(activation_type)
		if(SLIME_ACTIVATE_MINOR)
			to_chat(user, span_warning("You feel yourself reverting to human form..."))
			if(do_after(user, 12 SECONDS, target = user))
				to_chat(user, span_warning("You feel human again!"))
				user.set_species(/datum/species/human)
				return
			to_chat(user, span_notice("You stop the transformation."))

		if(SLIME_ACTIVATE_MAJOR)
			to_chat(user, span_warning("You feel yourself radically changing your slime type..."))
			if(do_after(user, 12 SECONDS, target = user))
				to_chat(user, span_warning("You feel different!"))
				user.set_species(pick(/datum/species/jelly/slime, /datum/species/jelly/stargazer))
				return
			to_chat(user, span_notice("You stop the transformation."))

/obj/item/slime_extract/lightpink
	name = "light pink slime extract"
	icon_state = "light-pink-core"
	crossbreed_modification = "loyal"
	activate_reagents = list(/datum/reagent/toxin/plasma)

/obj/item/slime_extract/lightpink/activate(mob/living/carbon/human/user, datum/species/jelly/luminescent/species, activation_type)
	switch(activation_type)
		if(SLIME_ACTIVATE_MINOR)
			var/obj/item/slimepotion/slime/renaming/O = new(null, 1)
			if(!user.put_in_active_hand(O))
				O.forceMove(user.drop_location())
			playsound(user, 'sound/effects/splat.ogg', 50, TRUE)
			user.visible_message(span_warning("[user] spits out [O]!"), span_notice("You spit out [O]!"))
			return 150

		if(SLIME_ACTIVATE_MAJOR)
			var/obj/item/slimepotion/slime/sentience/O = new(null, 1)
			if(!user.put_in_active_hand(O))
				O.forceMove(user.drop_location())
			playsound(user, 'sound/effects/splat.ogg', 50, TRUE)
			user.visible_message(span_warning("[user] spits out [O]!"), span_notice("You spit out [O]!"))
			return 450

/obj/item/slime_extract/black
	name = "black slime extract"
	icon_state = "black-core"
	crossbreed_modification = "transformative"
	activate_reagents = list(/datum/reagent/toxin/plasma)

/obj/item/slime_extract/black/activate(mob/living/carbon/human/user, datum/species/jelly/luminescent/species, activation_type)
	switch(activation_type)
		if(SLIME_ACTIVATE_MINOR)
			to_chat(user, span_userdanger("You feel something <i>wrong</i> inside you..."))
			user.ForceContractDisease(new /datum/disease/transformation/slime(), FALSE, TRUE)
			return 100

		if(SLIME_ACTIVATE_MAJOR)
			to_chat(user, span_warning("You feel your own light turning dark..."))
			if(do_after(user, 12 SECONDS, target = user))
				to_chat(user, span_warning("You feel a longing for darkness."))
				user.set_species(pick(/datum/species/shadow))
				return
			to_chat(user, span_notice("You stop feeding [src]."))

/obj/item/slime_extract/oil
	name = "oil slime extract"
	icon_state = "oil-core"
	crossbreed_modification = "detonating"
	activate_reagents = list(/datum/reagent/blood,/datum/reagent/toxin/plasma)

/obj/item/slime_extract/oil/activate(mob/living/carbon/human/user, datum/species/jelly/luminescent/species, activation_type)
	switch(activation_type)
		if(SLIME_ACTIVATE_MINOR)
			to_chat(user, span_warning("You vomit slippery oil."))
			playsound(user, 'sound/effects/splat.ogg', 50, TRUE)
			new /obj/effect/decal/cleanable/oil/slippery(get_turf(user))
			return 450

		if(SLIME_ACTIVATE_MAJOR)
			user.visible_message(span_warning("[user]'s skin starts pulsing and glowing ominously..."), span_userdanger("You feel unstable..."))
			if(do_after(user, 6 SECONDS, target = user))
				to_chat(user, span_userdanger("You explode!"))
				explosion(user, devastation_range = 1, heavy_impact_range = 3, light_impact_range = 6, explosion_cause = src)
				user.investigate_log("has been gibbed by an oil slime extract explosion.", INVESTIGATE_DEATHS)
				user.gib(DROP_ALL_REMAINS)
				return
			to_chat(user, span_notice("You stop feeding [src], and the feeling passes."))

/obj/item/slime_extract/adamantine
	name = "adamantine slime extract"
	icon_state = "adamantine-core"
	crossbreed_modification = "crystalline"
	activate_reagents = list(/datum/reagent/toxin/plasma)

/obj/item/slime_extract/adamantine/activate(mob/living/carbon/human/user, datum/species/jelly/luminescent/species, activation_type)
	switch(activation_type)
		if(SLIME_ACTIVATE_MINOR)
			if(HAS_TRAIT(user, TRAIT_ADAMANTINE_EXTRACT_ARMOR))
				to_chat(user, span_warning("Your skin is already hardened!"))
				return
			ADD_TRAIT(user, TRAIT_ADAMANTINE_EXTRACT_ARMOR, ADAMANTINE_EXTRACT_TRAIT)
			to_chat(user, span_notice("You feel your skin harden and become more resistant."))
			user.physiology.damage_resistance += 25
			addtimer(CALLBACK(src, PROC_REF(reset_armor), user), 120 SECONDS)
			return 450

		if(SLIME_ACTIVATE_MAJOR)
			to_chat(user, span_warning("You feel your body rapidly hardening..."))
			if(do_after(user, 12 SECONDS, target = user))
				to_chat(user, span_warning("You feel solid."))
				user.set_species(/datum/species/golem)
				return
			to_chat(user, span_notice("You stop feeding [src], and your body returns to its slimelike state."))

/obj/item/slime_extract/adamantine/proc/reset_armor(mob/living/carbon/human/user)
	REMOVE_TRAIT(user, TRAIT_ADAMANTINE_EXTRACT_ARMOR, ADAMANTINE_EXTRACT_TRAIT)
	user.physiology.damage_resistance -= 25

/obj/item/slime_extract/bluespace
	name = "bluespace slime extract"
	icon_state = "bluespace-core"
	crossbreed_modification = "warping"
	activate_reagents = list(/datum/reagent/blood,/datum/reagent/toxin/plasma)
	var/teleport_ready = FALSE
	var/teleport_x = 0
	var/teleport_y = 0
	var/teleport_z = 0

/obj/item/slime_extract/bluespace/activate(mob/living/carbon/human/user, datum/species/jelly/luminescent/species, activation_type)
	switch(activation_type)
		if(SLIME_ACTIVATE_MINOR)
			to_chat(user, span_warning("You feel your body vibrating..."))
			if(do_after(user, 2.5 SECONDS, target = user))
				to_chat(user, span_warning("You teleport!"))
				do_teleport(user, get_turf(user), 6, asoundin = 'sound/items/weapons/emitter2.ogg', channel = TELEPORT_CHANNEL_BLUESPACE)
				return 300

		if(SLIME_ACTIVATE_MAJOR)
			if(!teleport_ready)
				to_chat(user, span_notice("You feel yourself anchoring to this spot..."))
				var/turf/T = get_turf(user)
				teleport_x = T.x
				teleport_y = T.y
				teleport_z = T.z
				teleport_ready = TRUE
			else
				teleport_ready = FALSE
				if(teleport_x && teleport_y && teleport_z)
					var/turf/T = locate(teleport_x, teleport_y, teleport_z)
					to_chat(user, span_notice("You snap back to your anchor point!"))
					do_teleport(user, T,  asoundin = 'sound/items/weapons/emitter2.ogg', channel = TELEPORT_CHANNEL_BLUESPACE)
					return 450


/obj/item/slime_extract/pyrite
	name = "pyrite slime extract"
	icon_state = "pyrite-core"
	crossbreed_modification = "prismatic"
	activate_reagents = list(/datum/reagent/blood,/datum/reagent/toxin/plasma)

/obj/item/slime_extract/pyrite/activate(mob/living/carbon/human/user, datum/species/jelly/luminescent/species, activation_type)
	switch(activation_type)
		if(SLIME_ACTIVATE_MINOR)
			var/chosen = pick(difflist(subtypesof(/obj/item/toy/crayon),typesof(/obj/item/toy/crayon/spraycan)))
			var/obj/item/O = new chosen(null)
			if(!user.put_in_active_hand(O))
				O.forceMove(user.drop_location())
			playsound(user, 'sound/effects/splat.ogg', 50, TRUE)
			user.visible_message(span_warning("[user] spits out [O]!"), span_notice("You spit out [O]!"))
			return 150

		if(SLIME_ACTIVATE_MAJOR)
			var/blacklisted_cans = list(/obj/item/toy/crayon/spraycan/borg, /obj/item/toy/crayon/spraycan/infinite)
			var/chosen = pick(subtypesof(/obj/item/toy/crayon/spraycan) - blacklisted_cans)
			var/obj/item/O = new chosen(null)
			if(!user.put_in_active_hand(O))
				O.forceMove(user.drop_location())
			playsound(user, 'sound/effects/splat.ogg', 50, TRUE)
			user.visible_message(span_warning("[user] spits out [O]!"), span_notice("You spit out [O]!"))
			return 250

/obj/item/slime_extract/cerulean
	name = "cerulean slime extract"
	icon_state = "cerulean-core"
	crossbreed_modification = "recurring"
	activate_reagents = list(/datum/reagent/blood,/datum/reagent/toxin/plasma)

/obj/item/slime_extract/cerulean/activate(mob/living/carbon/human/user, datum/species/jelly/luminescent/species, activation_type)
	switch(activation_type)
		if(SLIME_ACTIVATE_MINOR)
			user.reagents.add_reagent(/datum/reagent/medicine/salbutamol,15)
			to_chat(user, span_notice("You feel like you don't need to breathe!"))
			return 150

		if(SLIME_ACTIVATE_MAJOR)
			var/turf/open/T = get_turf(user)
			if(istype(T))
				T.atmos_spawn_air("[GAS_O2]=11;[GAS_N2]=41;[TURF_TEMPERATURE(T20C)]")
				to_chat(user, span_warning("You activate [src], and fresh air bursts out of your skin!"))
				return 600

/obj/item/slime_extract/sepia
	name = "sepia slime extract"
	icon_state = "sepia-core"
	crossbreed_modification = "lengthened"
	activate_reagents = list(/datum/reagent/blood,/datum/reagent/toxin/plasma,/datum/reagent/water)

/obj/item/slime_extract/sepia/activate(mob/living/carbon/human/user, datum/species/jelly/luminescent/species, activation_type)
	switch(activation_type)
		if(SLIME_ACTIVATE_MINOR)
			var/obj/item/camera/O = new(null, 1)
			if(!user.put_in_active_hand(O))
				O.forceMove(user.drop_location())
			playsound(user, 'sound/effects/splat.ogg', 50, TRUE)
			user.visible_message(span_warning("[user] spits out [O]!"), span_notice("You spit out [O]!"))
			return 150

		if(SLIME_ACTIVATE_MAJOR)
			to_chat(user, span_warning("You feel time slow down..."))
			if(do_after(user, 3 SECONDS, target = user))
				new /obj/effect/timestop(get_turf(user), 2, 50, list(user))
				return 900

/obj/item/slime_extract/rainbow
	name = "rainbow slime extract"
	icon_state = "rainbow-core"
	crossbreed_modification = "hyperchromatic"
	activate_reagents = list(/datum/reagent/blood,/datum/reagent/toxin/plasma,"lesser plasma",/datum/reagent/toxin/slimejelly,"holy water and uranium") //Curse this snowflake reagent list.

/obj/item/slime_extract/rainbow/activate(mob/living/carbon/human/user, datum/species/jelly/luminescent/species, activation_type)
	switch(activation_type)
		if(SLIME_ACTIVATE_MINOR)
			user.dna.features["mcolor"] = "#[pick("7F", "FF")][pick("7F", "FF")][pick("7F", "FF")]"
			user.dna.update_uf_block(DNA_MUTANT_COLOR_BLOCK)
			user.updateappearance(mutcolor_update=1)
			species.update_glow(user)
			to_chat(user, span_notice("You feel different..."))
			return 100

		if(SLIME_ACTIVATE_MAJOR)
			var/chosen = pick(subtypesof(/obj/item/slime_extract))
			var/obj/item/O = new chosen(null)
			if(!user.put_in_active_hand(O))
				O.forceMove(user.drop_location())
			playsound(user, 'sound/effects/splat.ogg', 50, TRUE)
			user.visible_message(span_warning("[user] spits out [O]!"), span_notice("You spit out [O]!"))
			return 150

////Slime-derived potions///

/**
* #Slime potions
*
* Feed slimes potions either by hand or using the slime console.
*
* Slime potions either augment the slime's behavior, its extract output, or its intelligence. These all come either from extract effects or cross cores.
* A few of the more powerful ones can modify someone's equipment or gender.
* New ones should probably be accessible only through cross cores as all the normal core types already have uses. Rule of thumb is 'stronger effects go in cross cores'.
*/

/obj/item/slimepotion
	name = "slime potion"
	desc = "A hard yet gelatinous capsule excreted by a slime, containing mysterious substances."
	w_class = WEIGHT_CLASS_TINY

/obj/item/slimepotion/interact_with_atom(atom/interacting_with, mob/living/user, list/modifiers)
	if(is_reagent_container(interacting_with))
		to_chat(user, span_warning("You cannot transfer [src] to [interacting_with]! \
			It appears the potion must be given directly to a slime to absorb.") )
		return ITEM_INTERACT_BLOCKING
	return NONE

/obj/item/slimepotion/slime/docility
	name = "docility potion"
	desc = "A potent chemical mix that nullifies a slime's hunger, causing it to become docile and tame."
	icon = 'icons/obj/medical/chemical.dmi'
	icon_state = "potsilver"

/obj/item/slimepotion/slime/docility/attack(mob/living/basic/slime/target_slime, mob/user)
	if(!isslime(target_slime))
		to_chat(user, span_warning("The potion only works on slimes!"))
		return ..()
	if(target_slime.stat)
		to_chat(user, span_warning("The slime is dead!"))
		return
	if(target_slime.ai_controller?.clear_blackboard_key(BB_SLIME_RABID)) //Stops being rabid, but doesn't become truly docile.
		to_chat(target_slime, span_warning("You absorb the potion, and your rabid hunger finally settles to a normal desire to feed."))
		to_chat(user, span_notice("You feed the slime the potion, calming its rabid rage."))
		target_slime.set_default_behaviour()
		qdel(src)
		return
	target_slime.set_pacified_behaviour()
	to_chat(target_slime, span_warning("You absorb the potion and feel your intense desire to feed melt away."))
	to_chat(user, span_notice("You feed the slime the potion, removing its hunger and calming it."))
	var/newname = sanitize_name(tgui_input_text(user, "Would you like to give the slime a name?", "Name your new pet", "Pet Slime", MAX_NAME_LEN))

	if (!newname)
		newname = "Pet Slime"
	target_slime.name = newname
	target_slime.real_name = newname
	qdel(src)

/obj/item/slimepotion/slime/sentience
	name = "intelligence potion"
	desc = "A miraculous chemical mix that grants human like intelligence to living beings."
	icon = 'icons/obj/medical/chemical.dmi'
	icon_state = "potpink"
	/// Are we being offered to a mob, and therefore is a ghost poll currently in progress for the sentient mob?
	var/being_used = FALSE
	var/sentience_type = SENTIENCE_ORGANIC
	/// Reason for offering potion. This will be displayed in the poll alert to ghosts.
	var/potion_reason

/obj/item/slimepotion/slime/sentience/examine(mob/user)
	. = ..()
	. += span_notice("Alt-click to set potion offer reason. [potion_reason ? "Current reason: [span_warning(potion_reason)]" : null]")

/obj/item/slimepotion/slime/sentience/Initialize(mapload)
	register_context()
	return ..()

/obj/item/slimepotion/slime/sentience/add_context(atom/source, list/context, obj/item/held_item, mob/user)
	context[SCREENTIP_CONTEXT_ALT_LMB] = "Set potion offer reason"
	return CONTEXTUAL_SCREENTIP_SET

/obj/item/slimepotion/slime/sentience/click_alt(mob/living/user)
	potion_reason = tgui_input_text(user, "Enter reason for offering potion", "Intelligence Potion", potion_reason, max_length = MAX_MESSAGE_LEN, multiline = TRUE)
	return CLICK_ACTION_SUCCESS

/obj/item/slimepotion/slime/sentience/attack(mob/living/dumb_mob, mob/user)
	if(being_used || !isliving(dumb_mob))
		return
	if(dumb_mob.ckey) //only works on animals that aren't player controlled
		balloon_alert(user, "already sentient!")
		return
	if(dumb_mob.stat)
		balloon_alert(user, "it's dead!")
		return
	if(!dumb_mob.compare_sentience_type(sentience_type)) // Will also return false if not a basic or simple mob, which are the only two we want anyway
		balloon_alert(user, "invalid creature!")
		return
	balloon_alert(user, "offering...")
	being_used = TRUE
	var/mob/chosen_one = SSpolling.poll_ghosts_for_target(
		question = "[span_danger(user.name)] is offering [span_notice(dumb_mob.name)] an intelligence potion![potion_reason ? " Reason: [span_boldnotice(potion_reason)]" : ""]",
		check_jobban = ROLE_SENTIENCE,
		poll_time = 20 SECONDS,
		checked_target = dumb_mob,
		ignore_category = POLL_IGNORE_SENTIENCE_POTION,
		alert_pic = dumb_mob,
		role_name_text = "intelligence potion",
		chat_text_border_icon = src,
	)
	on_poll_concluded(user, dumb_mob, chosen_one)

/// Assign the chosen ghost to the mob
/obj/item/slimepotion/slime/sentience/proc/on_poll_concluded(mob/user, mob/living/dumb_mob, mob/dead/observer/ghost)
	if(isnull(ghost))
		balloon_alert(user, "try again later!")
		being_used = FALSE
		return

	dumb_mob.PossessByPlayer(ghost.key)
	dumb_mob.mind.enslave_mind_to_creator(user)
	SEND_SIGNAL(dumb_mob, COMSIG_SIMPLEMOB_SENTIENCEPOTION, user)

	if(isanimal(dumb_mob))
		var/mob/living/simple_animal/smart_animal = dumb_mob
		smart_animal.sentience_act()

	dumb_mob.mind.add_antag_datum(/datum/antagonist/sentient_creature)
	balloon_alert(user, "success")
	after_success(user, dumb_mob)
	qdel(src)

/obj/item/slimepotion/slime/sentience/proc/after_success(mob/living/user, mob/living/smart_mob)
	return

/obj/item/slimepotion/slime/sentience/nuclear
	name = "syndicate intelligence potion"
	desc = "A miraculous chemical mix that grants human like intelligence to living beings. It has been modified with Syndicate technology to also grant an internal radio implant to the target and authenticate with identification systems."

/obj/item/slimepotion/slime/sentience/nuclear/after_success(mob/living/user, mob/living/smart_mob)
	var/obj/item/implant/radio/syndicate/imp = new(src)
	imp.implant(smart_mob, user)
	smart_mob.AddComponent(/datum/component/simple_access, list(ACCESS_SYNDICATE, ACCESS_MAINT_TUNNELS))

/obj/item/slimepotion/transference
	name = "consciousness transference potion"
	desc = "A strange slime-based chemical that, when used, allows the user to transfer their consciousness to a lesser being."
	icon = 'icons/obj/medical/chemical.dmi'
	icon_state = "potorange"
	var/prompted = 0
	var/animal_type = SENTIENCE_ORGANIC

/obj/item/slimepotion/transference/interact_with_atom(atom/interacting_with, mob/living/user, list/modifiers)
	. = ..()
	if(. & ITEM_INTERACT_ANY_BLOCKER)
		return .
	var/mob/living/switchy_mob = interacting_with
	if(prompted || !isliving(switchy_mob))
		return ITEM_INTERACT_BLOCKING
	if(switchy_mob.ckey) //much like sentience, these will not work on something that is already player controlled
		balloon_alert(user, "already sentient!")
		return ITEM_INTERACT_BLOCKING
	if(switchy_mob.stat)
		balloon_alert(user, "it's dead!")
		return ITEM_INTERACT_BLOCKING
	if(!switchy_mob.compare_sentience_type(animal_type))
		balloon_alert(user, "invalid creature!")
		return ITEM_INTERACT_BLOCKING

	var/job_banned = is_banned_from(user.ckey, ROLE_MIND_TRANSFER)
	if(QDELETED(src) || QDELETED(switchy_mob) || QDELETED(user))
		return ITEM_INTERACT_BLOCKING

	if(job_banned)
		balloon_alert(user, "you're banned!")
		return ITEM_INTERACT_BLOCKING

	user.do_attack_animation(interacting_with)
	prompted = 1
	if(tgui_alert(usr,"This will permanently transfer your consciousness to [switchy_mob]. Are you sure you want to do this?",,list("Yes","No")) != "Yes")
		prompted = 0
		return ITEM_INTERACT_BLOCKING

	to_chat(user, span_notice("You drink the potion then place your hands on [switchy_mob]..."))

	user.mind.transfer_to(switchy_mob)
	SEND_SIGNAL(switchy_mob, COMSIG_SIMPLEMOB_TRANSFERPOTION, user)
	switchy_mob.faction = user.faction.Copy()
	switchy_mob.copy_languages(user, LANGUAGE_MIND)
	user.death()
	to_chat(switchy_mob, span_notice("In a quick flash, you feel your consciousness flow into [switchy_mob]!"))
	to_chat(switchy_mob, span_warning("You are now [switchy_mob]. Your allegiances, alliances, and role is still the same as it was prior to consciousness transfer!"))
	switchy_mob.name = "[user.real_name]"
	qdel(src)
	if(isanimal(switchy_mob))
		var/mob/living/simple_animal/switchy_animal= switchy_mob
		switchy_animal.sentience_act()
	return ITEM_INTERACT_SUCCESS

/obj/item/slimepotion/slime/steroid
	name = "slime steroid"
	desc = "A potent chemical mix that will cause a baby slime to generate more extract."
	icon = 'icons/obj/medical/chemical.dmi'
	icon_state = "potred"

/obj/item/slimepotion/slime/steroid/attack(mob/living/basic/slime/target, mob/user)
	if(!isslime(target))//If target is not a slime.
		to_chat(user, span_warning("The steroid only works on baby slimes!"))
		return ..()
	if(target.life_stage == SLIME_LIFE_STAGE_ADULT) //Can't steroidify adults
		to_chat(user, span_warning("Only baby slimes can use the steroid!"))
		return
	if(target.stat)
		to_chat(user, span_warning("The slime is dead!"))
		return
	if(target.cores >= 5)
		to_chat(user, span_warning("The slime already has the maximum amount of extract!"))
		return

	to_chat(user, span_notice("You feed the slime the steroid. It will now produce one more extract."))
	target.cores++
	qdel(src)

/obj/item/slimepotion/enhancer
	name = "extract enhancer"
	desc = "A potent chemical mix that will give a slime extract an additional use."
	icon = 'icons/obj/medical/chemical.dmi'
	icon_state = "potpurple"

/obj/item/slimepotion/slime/stabilizer
	name = "slime stabilizer"
	desc = "A potent chemical mix that will reduce the chance of a slime mutating."
	icon = 'icons/obj/medical/chemical.dmi'
	icon_state = "potcyan"

/obj/item/slimepotion/slime/stabilizer/attack(mob/living/basic/slime/target_slime, mob/user)
	if(!isslime(target_slime))
		to_chat(user, span_warning("The stabilizer only works on slimes!"))
		return ..()
	if(target_slime.stat)
		to_chat(user, span_warning("The slime is dead!"))
		return
	if(target_slime.mutation_chance == 0)
		to_chat(user, span_warning("The slime already has no chance of mutating!"))
		return

	to_chat(user, span_notice("You feed the slime the stabilizer. It is now less likely to mutate."))
	target_slime.mutation_chance = clamp(target_slime.mutation_chance-15,0,100)
	qdel(src)

/obj/item/slimepotion/slime/mutator
	name = "slime mutator"
	desc = "A potent chemical mix that will increase the chance of a slime mutating."
	icon = 'icons/obj/medical/chemical.dmi'
	icon_state = "potgreen"

/obj/item/slimepotion/slime/mutator/attack(mob/living/basic/slime/target_slime, mob/user)
	if(!isslime(target_slime))
		to_chat(user, span_warning("The mutator only works on slimes!"))
		return ..()
	if(target_slime.stat)
		to_chat(user, span_warning("The slime is dead!"))
		return
	if(target_slime.mutator_used)
		to_chat(user, span_warning("This slime has already consumed a mutator, any more would be far too unstable!"))
		return
	if(target_slime.mutation_chance == 100)
		to_chat(user, span_warning("The slime is already guaranteed to mutate!"))
		return

	to_chat(user, span_notice("You feed the slime the mutator. It is now more likely to mutate."))
	target_slime.mutation_chance = clamp(target_slime.mutation_chance+12,0,100)
	target_slime.mutator_used = TRUE
	qdel(src)

/obj/item/slimepotion/speed
	name = "slime speed potion"
	desc = "A potent chemical mix that will remove the slowdown from any item."
	icon = 'icons/obj/medical/chemical.dmi'
	icon_state = "potred"

/obj/item/slimepotion/speed/interact_with_atom(obj/interacting_with, mob/living/user, list/modifiers)
	. = ..()
	if(. & ITEM_INTERACT_ANY_BLOCKER)
		return .
	if(!isobj(interacting_with))
		to_chat(user, span_warning("The potion can only be used on objects!"))
		return ITEM_INTERACT_BLOCKING
	if(HAS_TRAIT(interacting_with, TRAIT_SPEED_POTIONED))
		to_chat(user, span_warning("[interacting_with] can't be made any faster!"))
		return ITEM_INTERACT_BLOCKING
	if(SEND_SIGNAL(interacting_with, COMSIG_SPEED_POTION_APPLIED, src, user) & SPEED_POTION_STOP)
		return ITEM_INTERACT_SUCCESS
	if(isitem(interacting_with))
		var/obj/item/apply_to = interacting_with
		if(apply_to.slowdown <= 0 || (apply_to.item_flags & IMMUTABLE_SLOW))
			if(interacting_with.atom_storage)
				return NONE // lets us put the potion in the bag
			to_chat(user, span_warning("[apply_to] can't be made any faster!"))
			return ITEM_INTERACT_BLOCKING
		apply_to.slowdown = 0

	to_chat(user, span_notice("You slather the red gunk over the [interacting_with], making it faster."))
	interacting_with.remove_atom_colour(WASHABLE_COLOUR_PRIORITY)
	interacting_with.add_atom_colour(color_transition_filter(COLOR_RED, SATURATION_OVERRIDE), FIXED_COLOUR_PRIORITY)
	interacting_with.drag_slowdown = 0
	ADD_TRAIT(interacting_with, TRAIT_SPEED_POTIONED, SLIME_POTION_TRAIT)
	qdel(src)
	return ITEM_INTERACT_SUCCESS

/obj/item/slimepotion/fireproof
	name = "slime chill potion"
	desc = "A potent chemical mix that will fireproof any article of clothing. Has three uses."
	icon = 'icons/obj/medical/chemical.dmi'
	icon_state = "potblue"
	resistance_flags = FIRE_PROOF
	var/uses = 3

/obj/item/slimepotion/fireproof/interact_with_atom(atom/interacting_with, mob/living/user, list/modifiers)
	. = ..()
	if(. & ITEM_INTERACT_ANY_BLOCKER)
		return .
	if(uses <= 0)
		qdel(src)
		return ITEM_INTERACT_BLOCKING
	var/obj/item/clothing/clothing = interacting_with
	if(!istype(clothing))
		to_chat(user, span_warning("The potion can only be used on clothing!"))
		return ITEM_INTERACT_BLOCKING
	if(clothing.max_heat_protection_temperature >= FIRE_IMMUNITY_MAX_TEMP_PROTECT)
		to_chat(user, span_warning("The [clothing] is already fireproof!"))
		return ITEM_INTERACT_BLOCKING
	to_chat(user, span_notice("You slather the blue gunk over the [clothing], fireproofing it."))
	clothing.name = "fireproofed [clothing.name]"
	clothing.remove_atom_colour(WASHABLE_COLOUR_PRIORITY)
	clothing.add_atom_colour(color_transition_filter(COLOR_NAVY, SATURATION_OVERRIDE), FIXED_COLOUR_PRIORITY)
	clothing.max_heat_protection_temperature = FIRE_IMMUNITY_MAX_TEMP_PROTECT
	clothing.heat_protection = clothing.body_parts_covered
	clothing.resistance_flags |= FIRE_PROOF
	uses --
	if(uses <= 0)
		qdel(src)
	return ITEM_INTERACT_BLOCKING

/obj/item/slimepotion/genderchange
	name = "gender change potion"
	desc = "An interesting chemical mix that changes the biological gender of what its applied to. Cannot be used on things that lack gender entirely."
	icon = 'icons/obj/medical/chemical.dmi'
	icon_state = "potrainbow"

/obj/item/slimepotion/genderchange/attack(mob/living/L, mob/user)
	if(!istype(L) || L.stat == DEAD)
		to_chat(user, span_warning("The potion can only be used on living things!"))
		return

	if(L.gender != MALE && L.gender != FEMALE)
		to_chat(user, span_warning("The potion can only be used on gendered things!"))
		return

	if(L.gender == MALE)
		L.gender = FEMALE
		L.visible_message(span_boldnotice("[L] suddenly looks more feminine!"), span_boldwarning("You suddenly feel more feminine!"))
	else
		L.gender = MALE
		L.visible_message(span_boldnotice("[L] suddenly looks more masculine!"), span_boldwarning("You suddenly feel more masculine!"))
	L.regenerate_icons()
	qdel(src)

/obj/item/slimepotion/slime/renaming
	name = "renaming potion"
	desc = "A potion that allows a self-aware being to change what name it subconsciously presents to the world."
	icon = 'icons/obj/medical/chemical.dmi'
	icon_state = "potbrown"

	var/being_used = FALSE

/obj/item/slimepotion/slime/renaming/attack(mob/living/M, mob/user)
	if(being_used || !ismob(M))
		return
	if(!M.ckey) //only works on animals that aren't player controlled
		to_chat(user, span_warning("[M] is not self aware, and cannot pick its own name."))
		return

	being_used = TRUE

	to_chat(user, span_notice("You offer [src] to [user]..."))

	var/new_name = sanitize_name(tgui_input_text(M, "What would you like your name to be?", "Input a name", M.real_name, MAX_NAME_LEN))

	if(!new_name || QDELETED(src) || QDELETED(M) || new_name == M.real_name || !M.Adjacent(user))
		being_used = FALSE
		return

	M.visible_message(span_notice("[span_name("[M]")] has a new name, [span_name("[new_name]")]."), span_notice("Your old name of [span_name("[M.real_name]")] fades away, and your new name [span_name("[new_name]")] anchors itself in your mind."))
	message_admins("[ADMIN_LOOKUPFLW(user)] used [src] on [ADMIN_LOOKUPFLW(M)], letting them rename themselves into [new_name].")
	user.log_message("used [src] on [key_name(M)], letting them rename themselves into [new_name].", LOG_GAME)

	// pass null as first arg to not update records or ID/PDA
	M.fully_replace_character_name(null, new_name)

	qdel(src)

/obj/item/slimepotion/slime/slimeradio
	name = "bluespace radio potion"
	desc = "A strange chemical that grants those who ingest it the ability to broadcast and receive subscape radio waves."
	icon = 'icons/obj/medical/chemical.dmi'
	icon_state = "potbluespace"

/obj/item/slimepotion/slime/slimeradio/attack(mob/living/radio_head, mob/user)
	if(!isanimal_or_basicmob(radio_head))
		to_chat(user, span_warning("[radio_head] is too complex for the potion!"))
		return
	if(radio_head.stat)
		to_chat(user, span_warning("[radio_head] is dead!"))
		return

	to_chat(user, span_notice("You feed the potion to [radio_head]."))
	to_chat(radio_head, span_notice("Your mind tingles as you are fed the potion. You can hear radio waves now!"))
	var/obj/item/implant/radio/slime/imp = new(src)
	imp.implant(radio_head, user)
	qdel(src)

///Definitions for slime products that don't have anywhere else to go (Floor tiles, blueprints).

/obj/item/stack/tile/bluespace
	name = "bluespace floor tile"
	singular_name = "floor tile"
	desc = "Through a series of micro-teleports these tiles let people move at incredible speeds."
	icon_state = "tile_bluespace"
	inhand_icon_state = "tile-bluespace"
	w_class = WEIGHT_CLASS_NORMAL
	force = 6
	mats_per_unit = list(/datum/material/iron=SMALL_MATERIAL_AMOUNT*5)
	throwforce = 10
	throw_speed = 3
	throw_range = 7
	obj_flags = CONDUCTS_ELECTRICITY
	max_amount = 60
	turf_type = /turf/open/floor/bluespace
	merge_type = /obj/item/stack/tile/bluespace

/obj/item/stack/tile/sepia
	name = "sepia floor tile"
	singular_name = "floor tile"
	desc = "Time seems to flow very slowly around these tiles."
	icon_state = "tile_sepia"
	inhand_icon_state = "tile-sepia"
	w_class = WEIGHT_CLASS_NORMAL
	force = 6
	mats_per_unit = list(/datum/material/iron=SMALL_MATERIAL_AMOUNT*5)
	throwforce = 10
	throw_speed = 0.1
	throw_range = 28
	obj_flags = CONDUCTS_ELECTRICITY
	max_amount = 60
	turf_type = /turf/open/floor/sepia
	merge_type = /obj/item/stack/tile/sepia
