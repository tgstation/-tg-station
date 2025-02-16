#define BUTTON_COOLDOWN 60 // cant delay the bomb forever
#define BUTTON_DELAY 50 //five seconds

/obj/machinery/syndicatebomb
	icon = 'icons/obj/devices/assemblies.dmi'
	name = "syndicate bomb"
	icon_state = "syndicate-bomb"
	desc = "A large and menacing device. Can be bolted down with a wrench."

	anchored = FALSE
	density = FALSE
	layer = BELOW_MOB_LAYER //so people can't hide it and it's REALLY OBVIOUS
	resistance_flags = FIRE_PROOF | ACID_PROOF
	processing_flags = START_PROCESSING_MANUALLY
	subsystem_type = /datum/controller/subsystem/processing/fastprocess
	interaction_flags_machine = INTERACT_MACHINE_WIRES_IF_OPEN | INTERACT_MACHINE_OFFLINE
	use_power = NO_POWER_USE

	/// What is the lowest amount of time we can set the timer to?
	var/minimum_timer = SYNDIEBOMB_MIN_TIMER_SECONDS
	/// What is the highest amount of time we can set the timer to?
	var/maximum_timer = 100 MINUTES
	/// What is the default amount of time we set the timer to?
	var/timer_set = SYNDIEBOMB_MIN_TIMER_SECONDS
	/// Can we be unanchored?
	var/can_unanchor = TRUE
	/// Are the wires exposed?
	var/open_panel = FALSE
	/// Is the bomb counting down?
	var/active = FALSE
	/// What sound do we make as we beep down the timer?
	var/beepsound = 'sound/items/timer.ogg'
	/// Is the delay wire pulsed?
	var/delayedbig = FALSE
	/// Is the activation wire pulsed?
	var/delayedlittle = FALSE
	/// Should we just tell the payload to explode now? Usually triggered by an event (like cutting the wrong wire)
	var/explode_now = FALSE
	/// The timer for the bomb.
	var/detonation_timer
	/// When do we beep next?
	var/next_beep
	/// Reference to the bomb core inside the bomb, which is the part that actually explodes.
	var/obj/item/bombcore/payload = /obj/item/bombcore/syndicate
	/// The countdown that'll show up to ghosts regarding the bomb's timer.
	var/obj/effect/countdown/syndicatebomb/countdown
	/// Whether the countdown is visible on examine
	var/examinable_countdown = TRUE

/obj/machinery/syndicatebomb/proc/try_detonate(ignore_active = FALSE)
	. = (payload in src) && (active || ignore_active)
	if(.)
		payload.detonate()

/obj/machinery/syndicatebomb/atom_break()
	if(!try_detonate())
		..()

/obj/machinery/syndicatebomb/atom_destruction()
	if(!try_detonate())
		..()

/obj/machinery/syndicatebomb/ex_act(severity, target)
	return FALSE

/obj/machinery/syndicatebomb/process()
	if(!active)
		end_processing()
		detonation_timer = null
		next_beep = null
		countdown.stop()
		if(payload in src)
			payload.defuse()
		return

	if(!isnull(next_beep) && (next_beep <= world.time))
		var/volume
		switch(seconds_remaining())
			if(0 to 5)
				volume = 50
			if(5 to 10)
				volume = 40
			if(10 to 15)
				volume = 30
			if(15 to 20)
				volume = 20
			if(20 to 25)
				volume = 10
			else
				volume = 5
		playsound(loc, beepsound, volume, FALSE)
		next_beep = world.time + 10

	if(active && ((detonation_timer <= world.time) || explode_now))
		active = FALSE
		timer_set = initial(timer_set)
		update_appearance()
		try_detonate(TRUE)

/obj/machinery/syndicatebomb/Initialize(mapload)
	. = ..()
	set_wires(new /datum/wires/syndicatebomb(src))
	if(payload)
		payload = new payload(src)
	update_appearance()
	countdown = new(src)
	end_processing()

/obj/machinery/syndicatebomb/Destroy()
	QDEL_NULL(countdown)
	end_processing()
	return ..()

/obj/machinery/syndicatebomb/examine(mob/user)
	. = ..()
	. += "The patented external shell design is resistant to \"probably all\" forms of external explosive compression, protecting the electronically-trigged bomb core from accidental early detonation."
	if(istype(payload))
		. += "A small window reveals some information about the payload: [payload.desc]."
	if(examinable_countdown)
		. += span_notice("A digital display on it reads \"[seconds_remaining()]\".")
		if(active)
			balloon_alert(user, "[seconds_remaining()]")
	else
		. += span_notice({"The digital display on it is inactive."})

/obj/machinery/syndicatebomb/update_icon_state()
	icon_state = "[initial(icon_state)][active ? "-active" : "-inactive"][open_panel ? "-wires" : ""]"
	return ..()

/obj/machinery/syndicatebomb/proc/seconds_remaining()
	if(active)
		. = max(0, round((detonation_timer - world.time) / 10))

	else
		. = timer_set

/obj/machinery/syndicatebomb/wrench_act(mob/living/user, obj/item/tool)
	if(!can_unanchor)
		return FALSE
	if(!anchored)
		if(!isturf(loc) || isspaceturf(loc))
			to_chat(user, span_notice("The bomb must be placed on solid ground to attach it."))
		else
			to_chat(user, span_notice("You firmly wrench the bomb to the floor."))
			tool.play_tool_sound(src)
			set_anchored(TRUE)
			if(active)
				to_chat(user, span_notice("The bolts lock in place."))
	else
		if(!active)
			to_chat(user, span_notice("You wrench the bomb from the floor."))
			tool.play_tool_sound(src)
			set_anchored(FALSE)
		else
			to_chat(user, span_warning("The bolts are locked down!"))

	return TRUE

/obj/machinery/syndicatebomb/screwdriver_act(mob/living/user, obj/item/tool)
	tool.play_tool_sound(src, 50)
	open_panel = !open_panel
	update_appearance()
	to_chat(user, span_notice("You [open_panel ? "open" : "close"] the wire panel."))
	return TRUE

/obj/machinery/syndicatebomb/crowbar_act(mob/living/user, obj/item/tool)
	. = TRUE
	if(open_panel && wires.is_all_cut())
		if(payload)
			tool.play_tool_sound(src, 25) // sshhh
			to_chat(user, span_notice("You carefully pry out [payload]."))
			payload.forceMove(drop_location())
			payload = null
		else
			to_chat(user, span_warning("There isn't anything in here to remove!"))
	else if (open_panel)
		to_chat(user, span_warning("The wires connecting the shell to the explosives are holding it down!"))
	else
		to_chat(user, span_warning("The cover is screwed on, it won't pry off!"))

/obj/machinery/syndicatebomb/welder_act(mob/living/user, obj/item/tool)
	if(payload || !wires.is_all_cut() || !open_panel)
		return FALSE

	if(!tool.tool_start_check(user, amount=1))
		return TRUE

	to_chat(user, span_notice("You start to cut [src] apart..."))
	if(tool.use_tool(src, user, 20, volume=50))
		to_chat(user, span_notice("You cut [src] apart."))
		new /obj/item/stack/sheet/plasteel(loc, 5)
		qdel(src)
	return TRUE


/obj/machinery/syndicatebomb/attackby(obj/item/I, mob/user, params)

	if(is_wire_tool(I) && open_panel)
		wires.interact(user)

	else if(istype(I, /obj/item/bombcore))
		if(!payload)
			if(!user.transferItemToLoc(I, src))
				return
			payload = I
			to_chat(user, span_notice("You place [payload] into [src]."))
		else
			to_chat(user, span_warning("[payload] is already loaded into [src]! You'll have to remove it first."))
	else
		var/old_integ = atom_integrity
		. = ..()
		if((old_integ > atom_integrity) && active && (payload in src))
			to_chat(user, span_warning("That seems like a really bad idea..."))

/obj/machinery/syndicatebomb/interact(mob/user)
	wires.interact(user)
	if(!open_panel)
		if(!active)
			settings(user)
		else if(anchored)
			to_chat(user, span_warning("The bomb is bolted to the floor!"))

/obj/machinery/syndicatebomb/proc/activate()
	active = TRUE
	begin_processing()
	countdown.start()
	next_beep = world.time + 10
	detonation_timer = world.time + (timer_set * 10)
	playsound(loc, 'sound/machines/click.ogg', 30, TRUE)
	update_appearance()

/obj/machinery/syndicatebomb/proc/settings(mob/user)
	if(!user.can_perform_action(src, ALLOW_SILICON_REACH) || !user.can_interact_with(src))
		return
	var/new_timer = tgui_input_number(user, "Set the timer", "Countdown", timer_set, maximum_timer, minimum_timer)
	if(!new_timer || QDELETED(user) || QDELETED(src) || !user.can_perform_action(src, FORBID_TELEKINESIS_REACH))
		return
	timer_set = new_timer
	loc.visible_message(span_notice("[icon2html(src, viewers(src))] timer set for [timer_set] seconds."))
	var/choice = tgui_alert(user, "Would you like to start the countdown now?", "Bomb Timer", list("Yes","No"))
	if(choice != "Yes")
		return
	if(active)
		to_chat(user, span_warning("The bomb is already active!"))
		return
	visible_message(span_danger("[icon2html(src, viewers(loc))] [timer_set] seconds until detonation, please clear the area."))
	activate()
	add_fingerprint(user)
	// We don't really concern ourselves with duds or fakes after this
	if(isnull(payload) || istype(payload, /obj/machinery/syndicatebomb/training))
		return

	notify_ghosts(
		"\A [src] has been activated at [get_area(src)]!",
		source = src,
		header = "Bomb Planted",
	)
	user.add_mob_memory(/datum/memory/bomb_planted/syndicate, antagonist = src)
	log_bomber(user, "has primed a", src, "for detonation (Payload: [payload.name])")
	payload.adminlog = "\The [src] that [key_name(user)] had primed detonated!"
	user.log_message("primed the [src]. (Payload: [payload.name])", LOG_GAME, log_globally = FALSE)

///Bomb Subtypes///

/obj/machinery/syndicatebomb/training
	name = "training bomb"
	icon_state = "training-bomb"
	desc = "A salvaged syndicate device gutted of its explosives to be used as a training aid for aspiring bomb defusers."
	payload = /obj/item/bombcore/training

/obj/machinery/syndicatebomb/emp
	name = "EMP Bomb"
	desc = "A modified bomb designed to release a crippling electromagnetic pulse instead of explode"
	payload = /obj/item/bombcore/emp

/obj/machinery/syndicatebomb/badmin
	name = "generic summoning badmin bomb"
	desc = "Oh god what is in this thing?"
	payload = /obj/item/bombcore/badmin/summon

/obj/machinery/syndicatebomb/badmin/clown
	name = "clown bomb"
	icon_state = "clown-bomb"
	desc = "HONK."
	payload = /obj/item/bombcore/badmin/summon/clown
	beepsound = 'sound/items/bikehorn.ogg'

/obj/machinery/syndicatebomb/empty
	name = "bomb"
	icon_state = "base-bomb"
	desc = "An ominous looking device designed to detonate an explosive payload. Can be bolted down using a wrench."
	payload = null
	open_panel = TRUE
	timer_set = 120

/obj/machinery/syndicatebomb/empty/Initialize(mapload)
	. = ..()
	wires.cut_all()

/obj/machinery/syndicatebomb/self_destruct
	name = "self-destruct device"
	desc = "Do not taunt. Warranty invalid if exposed to high temperature. Not suitable for agents under 3 years of age."
	payload = /obj/item/bombcore/syndicate/large
	can_unanchor = FALSE

///Bomb Cores///

/obj/item/bombcore
	name = "bomb payload"
	desc = "A powerful secondary explosive of syndicate design and unknown composition, it should be stable under normal conditions..."
	icon = 'icons/obj/devices/assemblies.dmi'
	icon_state = "bombcore"
	inhand_icon_state = "eshield"
	lefthand_file = 'icons/mob/inhands/equipment/shields_lefthand.dmi'
	righthand_file = 'icons/mob/inhands/equipment/shields_righthand.dmi'
	w_class = WEIGHT_CLASS_NORMAL
	flags_1 = PREVENT_CONTENTS_EXPLOSION_1 // We detonate upon being exploded.
	resistance_flags = FLAMMABLE //Burnable (but the casing isn't)
	var/adminlog = null
	var/range_heavy = 3
	var/range_medium = 9
	var/range_light = 17
	var/range_flame = 17

/obj/item/bombcore/ex_act(severity, target) // Little boom can chain a big boom.
	detonate()
	return TRUE

/obj/item/bombcore/burn()
	detonate()
	..()

/obj/item/bombcore/proc/detonate()
	if(adminlog)
		message_admins(adminlog)
		log_game(adminlog)
	explosion(src, range_heavy, range_medium, range_light, range_flame)
	if(loc && istype(loc, /obj/machinery/syndicatebomb/))
		qdel(loc)
	qdel(src)

/obj/item/bombcore/proc/defuse()
//Note: the machine's defusal is mostly done from the wires code, this is here if you want the core itself to do anything.

///Bomb Core Subtypes///

/// Subtype for the bomb cores found inside syndicate bombs, which will not detonate due to explosion/burning.
/obj/item/bombcore/syndicate
	name = "Donk Co. Super-Stable Bomb Payload"
	desc = "After a string of unwanted detonations, this payload has been specifically redesigned to not explode unless triggered electronically by a bomb shell."

/obj/item/bombcore/syndicate/ex_act(severity, target)
	return FALSE

/obj/item/bombcore/syndicate/burn()
	return ..()

/obj/item/bombcore/syndicate/large
	name = "Donk Co. Super-Stable Bomb Payload XL"
	range_heavy = 5
	range_medium = 10
	range_light = 20
	range_flame = 20

/obj/item/bombcore/training
	name = "dummy payload"
	desc = "A Nanotrasen replica of a syndicate payload. It's not intended to explode but to announce that it WOULD have exploded, then rewire itself to allow for more training."
	var/defusals = 0
	var/attempts = 0

/obj/item/bombcore/training/proc/reset()
	var/obj/machinery/syndicatebomb/holder = loc
	if(istype(holder))
		if(holder.wires)
			holder.wires.repair()
			holder.wires.shuffle_wires()
		holder.delayedbig = FALSE
		holder.delayedlittle = FALSE
		holder.explode_now = FALSE
		holder.update_appearance()
		STOP_PROCESSING(SSfastprocess, holder)

/obj/item/bombcore/training/detonate()
	var/obj/machinery/syndicatebomb/holder = loc
	if(istype(holder))
		attempts++
		holder.loc.visible_message(span_danger("[icon2html(holder, viewers(holder))] Alert: Bomb has detonated. Your score is now [defusals] for [attempts]. Resetting wires..."))
		reset()
	else
		qdel(src)

/obj/item/bombcore/training/defuse()
	var/obj/machinery/syndicatebomb/holder = loc
	if(istype(holder))
		attempts++
		defusals++
		holder.loc.visible_message(span_notice("[icon2html(holder, viewers(holder))] Alert: Bomb has been defused. Your score is now [defusals] for [attempts]! Resetting wires in 5 seconds..."))
		addtimer(CALLBACK(src, PROC_REF(reset)), 5 SECONDS) //Just in case someone is trying to remove the bomb core this gives them a little window to crowbar it out

/obj/item/bombcore/badmin
	name = "badmin payload"
	desc = "If you're seeing this someone has either made a mistake or gotten dangerously savvy with var editing!"

/obj/item/bombcore/badmin/defuse() //because we wouldn't want them being harvested by players
	var/obj/machinery/syndicatebomb/B = loc
	qdel(B)
	qdel(src)

/obj/item/bombcore/badmin/summon
	var/summon_path = /obj/item/food/cookie
	var/amt_summon = 1

/obj/item/bombcore/badmin/summon/detonate()
	var/obj/machinery/syndicatebomb/B = loc
	spawn_and_random_walk(summon_path, src, amt_summon, walk_chance=50, admin_spawn=TRUE, cardinals_only = FALSE)
	qdel(B)
	qdel(src)

/obj/item/bombcore/badmin/summon/clown
	name = "bananium payload"
	desc = "Clowns delivered fast and cheap!"
	summon_path = /mob/living/basic/clown
	amt_summon = 50

/obj/item/bombcore/badmin/summon/clown/defuse()
	playsound(src, 'sound/misc/sadtrombone.ogg', 50)
	..()

/obj/item/bombcore/large
	name = "large bomb payload"
	range_heavy = 5
	range_medium = 10
	range_light = 20
	range_flame = 20

/obj/item/bombcore/miniature
	name = "small bomb core"
	w_class = WEIGHT_CLASS_SMALL
	range_heavy = 1
	range_medium = 2
	range_light = 4
	range_flame = 2

/obj/item/bombcore/chemical
	name = "chemical payload"
	desc = "An explosive payload designed to spread chemicals, dangerous or otherwise, across a large area. Properties of the core may vary with grenade casing type, and must be loaded before use."
	icon_state = "chemcore"
	/// The initial volume of the reagent holder the bombcore has.
	var/core_holder_volume = 1000
	/// The set of beakers that have been inserted into the bombcore.
	var/list/beakers = list()
	/// The maximum number of beakers that this bombcore can have.
	var/max_beakers = 1 // Read on about grenade casing properties below
	/// The range this spreads the reagents added to the bombcore.
	var/spread_range = 5
	/// How much this heats the reagents in it on detonation.
	var/temp_boost = 50
	/// The amount of reagents released with each detonation.
	var/time_release = 0

/obj/item/bombcore/chemical/Initialize(mapload)
	. = ..()
	create_reagents(core_holder_volume)

/obj/item/bombcore/chemical/detonate()

	if(time_release > 0)
		var/total_volume = reagents.total_volume
		for(var/obj/item/reagent_containers/RC in beakers)
			total_volume += RC.reagents.total_volume

		if(total_volume < time_release) // If it's empty, the detonation is complete.
			if(loc && istype(loc, /obj/machinery/syndicatebomb/))
				qdel(loc)
			qdel(src)
			return

		var/fraction = time_release/total_volume
		var/datum/reagents/reactants = new(time_release)
		reactants.my_atom = src
		for(var/obj/item/reagent_containers/RC in beakers)
			RC.reagents.trans_to(reactants, RC.reagents.total_volume * fraction, no_react = TRUE)
		chem_splash(get_turf(src), reagents, spread_range, list(reactants), temp_boost)

		// Detonate it again in one second, until it's out of juice.
		addtimer(CALLBACK(src, PROC_REF(detonate)), 1 SECONDS)

	// If it's not a time release bomb, do normal explosion

	var/list/reactants = list()

	for(var/obj/item/reagent_containers/cup/G in beakers)
		reactants += G.reagents

	for(var/obj/item/slime_extract/S in beakers)
		if(S.extract_uses)
			for(var/obj/item/reagent_containers/cup/G in beakers)
				G.reagents.trans_to(S, G.reagents.total_volume)

			if(S && S.reagents && S.reagents.total_volume)
				reactants += S.reagents

	if(!chem_splash(get_turf(src), reagents, spread_range, reactants, temp_boost))
		playsound(loc, 'sound/items/tools/screwdriver2.ogg', 50, TRUE)
		return // The Explosion didn't do anything. No need to log, or disappear.

	if(adminlog)
		message_admins(adminlog)
		log_game(adminlog)

	playsound(loc, 'sound/effects/bamf.ogg', 75, TRUE, 5)

/obj/item/bombcore/chemical/attackby(obj/item/I, mob/user, params)
	if(I.tool_behaviour == TOOL_CROWBAR && beakers.len > 0)
		I.play_tool_sound(src)
		for (var/obj/item/B in beakers)
			B.forceMove(drop_location())
			beakers -= B
		return
	else if(istype(I, /obj/item/reagent_containers/cup/beaker) || istype(I, /obj/item/reagent_containers/cup/bottle))
		if(beakers.len < max_beakers)
			if(!user.transferItemToLoc(I, src))
				return
			beakers += I
			to_chat(user, span_notice("You load [src] with [I]."))
		else
			to_chat(user, span_warning("[I] won't fit! \The [src] can only hold up to [max_beakers] containers."))
			return
	..()

/obj/item/bombcore/chemical/on_craft_completion(list/components, datum/crafting_recipe/current_recipe, atom/crafter)
	// Using different grenade casings, causes the payload to have different properties.
	var/obj/item/stock_parts/matter_bin/bin = locate(/obj/item/stock_parts/matter_bin) in components
	if(bin)
		max_beakers += bin.rating // max beakers = 2-5.
	for(var/obj/item/grenade/chem_grenade/nade in components)

		if(istype(nade, /obj/item/grenade/chem_grenade/large))
			max_beakers += 1 // Adding two large grenades only allows for a maximum of 7 beakers.
			spread_range += 2 // Extra range, reduced density.
			temp_boost += 50 // maximum of +150K blast using only large beakers. Not enough to self ignite.
			for(var/obj/item/slime_extract/slime in nade.beakers) // And slime cores.
				if(beakers.len < max_beakers)
					beakers += slime
					slime.forceMove(src)
				else
					slime.forceMove(drop_location())

		if(istype(nade, /obj/item/grenade/chem_grenade/cryo))
			spread_range -= 1 // Reduced range, but increased density.
			temp_boost -= 100 // minimum of -150K blast.

		if(istype(nade, /obj/item/grenade/chem_grenade/pyro))
			temp_boost += 150 // maximum of +350K blast, which is enough to self ignite. Which means a self igniting bomb can't take advantage of other grenade casing properties. Sorry?

		if(istype(nade, /obj/item/grenade/chem_grenade/adv_release))
			time_release += 5 SECONDS // A typical bomb, using basic beakers, will explode over 2-4 seconds. Using two will make the reaction last for less time, but it will be more dangerous overall.

		for(var/obj/item/reagent_containers/cup/beaker in nade)
			if(beakers.len < max_beakers)
				beakers += beaker
				beaker.forceMove(src)
			else
				beaker.forceMove(drop_location())

	return ..()

/obj/item/bombcore/emp
	name = "EMP payload"
	desc = "A set of superconducting electromagnetic coils designed to release a powerful pulse to destroy electronics and scramble circuits"
	range_heavy = 15
	range_medium = 25

/obj/item/bombcore/emp/detonate()
	if(adminlog)
		message_admins(adminlog)
		log_game(adminlog)

	empulse(src, range_heavy, range_medium)

	qdel(src)

#define DIMENSION_CHOICE_RANDOM "None/Randomized"

/obj/item/bombcore/dimensional
	name = "multi-dimensional payload"
	desc = "A wicked payload meant to wildly transmutate terrain over a wide area, a power no mere human should wield."
	range_heavy = 17
	var/datum/dimension_theme/chosen_theme

/obj/item/bombcore/dimensional/Destroy()
	chosen_theme = null
	return ..()

/obj/item/bombcore/dimensional/examine(mob/user)
	. = ..()
	. += span_notice("Use in hand to change the linked dimension. Current dimension: [chosen_theme?.name || "None, output will be random"].")

/obj/item/bombcore/dimensional/attack_self(mob/user)
	. = ..()
	var/list/choosable_dimensions = list()
	var/datum/radial_menu_choice/null_choice = new
	null_choice.name = DIMENSION_CHOICE_RANDOM
	choosable_dimensions[DIMENSION_CHOICE_RANDOM] = null_choice
	for(var/datum/dimension_theme/theme as anything in SSmaterials.dimensional_themes)
		var/datum/radial_menu_choice/theme_choice = new
		theme_choice.image = image(initial(theme.icon), initial(theme.icon_state))
		theme_choice.name = initial(theme.name)
		choosable_dimensions[theme] = theme_choice

	var/datum/dimension_theme/picked = show_radial_menu(user, src, choosable_dimensions, custom_check = CALLBACK(src, PROC_REF(check_menu), user), radius = 38, require_near = TRUE)
	if(isnull(picked))
		return
	if(picked == DIMENSION_CHOICE_RANDOM)
		chosen_theme = null
	else
		chosen_theme = picked
	balloon_alert(user, "set to [chosen_theme?.name || DIMENSION_CHOICE_RANDOM]")

/obj/item/bombcore/dimensional/proc/check_menu(mob/user)
	if(!user.is_holding(src) || user.incapacitated)
		return FALSE
	return TRUE

/obj/item/bombcore/dimensional/detonate()
	var/list/affected_turfs = circle_range_turfs(src, range_heavy)
	var/theme_count = length(SSmaterials.dimensional_themes)
	var/num_affected = 0
	for(var/turf/affected as anything in affected_turfs)
		var/datum/dimension_theme/theme_to_use
		if(isnull(chosen_theme))
			theme_to_use = SSmaterials.dimensional_themes[SSmaterials.dimensional_themes[rand(1, theme_count)]]
		else
			theme_to_use = SSmaterials.dimensional_themes[chosen_theme]
		if(!theme_to_use.can_convert(affected))
			continue
		num_affected++
		var/skip_sound = TRUE
		if(num_affected % 5) //makes it play the sound more sparingly
			skip_sound = FALSE
		var/time_mult = round(get_dist_euclidean(get_turf(src), affected)) + 1
		addtimer(CALLBACK(theme_to_use, TYPE_PROC_REF(/datum/dimension_theme, apply_theme), affected, skip_sound, TRUE), 0.1 SECONDS * time_mult)
	qdel(src)

#undef DIMENSION_CHOICE_RANDOM

///Syndicate Detonator (aka the big red button)///

/obj/item/syndicatedetonator
	name = "big red button"
	desc = "Your standard issue bomb synchronizing button. Five second safety delay to prevent 'accidents'."
	icon = 'icons/obj/devices/assemblies.dmi'
	icon_state = "bigred"
	inhand_icon_state = "electronic"
	lefthand_file = 'icons/mob/inhands/items/devices_lefthand.dmi'
	righthand_file = 'icons/mob/inhands/items/devices_righthand.dmi'
	w_class = WEIGHT_CLASS_TINY
	var/timer = 0
	var/detonated = 0
	var/existent = 0

/obj/item/syndicatedetonator/attack_self(mob/user)
	if(timer < world.time)
		for(var/obj/machinery/syndicatebomb/B as anything in SSmachines.get_machines_by_type_and_subtypes(/obj/machinery/syndicatebomb))
			if(B.active)
				B.detonation_timer = world.time + BUTTON_DELAY
				detonated++
			existent++
		playsound(user, 'sound/machines/click.ogg', 20, TRUE)
		to_chat(user, span_notice("[existent] found, [detonated] triggered."))
		if(detonated)
			detonated--
			log_bomber(user, "remotely detonated [detonated ? "syndicate bombs" : "a syndicate bomb"] using a", src)
		detonated = 0
		existent = 0
		timer = world.time + BUTTON_COOLDOWN



#undef BUTTON_COOLDOWN
#undef BUTTON_DELAY
