/obj/item/flamethrower
	name = "flamethrower"
	desc = "You are a firestarter!"
	icon = 'icons/obj/weapons/flamethrower.dmi'
	icon_state = "flamethrowerbase"
	inhand_icon_state = "flamethrower_0"
	lefthand_file = 'icons/mob/inhands/weapons/flamethrower_lefthand.dmi'
	righthand_file = 'icons/mob/inhands/weapons/flamethrower_righthand.dmi'
	obj_flags = CONDUCTS_ELECTRICITY
	force = 3
	throwforce = 10
	throw_speed = 1
	throw_range = 5
	w_class = WEIGHT_CLASS_NORMAL
	custom_materials = list(/datum/material/iron= HALF_SHEET_MATERIAL_AMOUNT * 0.5)
	resistance_flags = FIRE_PROOF
	trigger_guard = TRIGGER_GUARD_NORMAL
	light_system = OVERLAY_LIGHT
	light_color = LIGHT_COLOR_FLARE
	light_range = 2
	light_power = 2
	light_on = FALSE
	interaction_flags_click = NEED_DEXTERITY|NEED_HANDS|ALLOW_RESTING
	var/status = FALSE
	var/lit = FALSE //on or off
	var/operating = FALSE//cooldown
	var/obj/item/weldingtool/weldtool = null
	var/obj/item/assembly/igniter/igniter = null
	var/obj/item/tank/internals/plasma/ptank = null
	var/warned_admins = FALSE //for the message_admins() when lit
	//variables for prebuilt flamethrowers
	var/create_full = FALSE
	var/create_with_tank = FALSE
	var/igniter_type = /obj/item/assembly/igniter
	var/acti_sound = 'sound/items/tools/welderactivate.ogg'
	var/deac_sound = 'sound/items/tools/welderdeactivate.ogg'

/obj/item/flamethrower/Initialize(mapload)
	. = ..()
	AddElement(/datum/element/update_icon_updates_onmob)
	var/static/list/slapcraft_recipe_list = list(/datum/crafting_recipe/flamethrower)

	AddElement(
		/datum/element/slapcrafting,\
		slapcraft_recipes = slapcraft_recipe_list,\
	)

/obj/item/flamethrower/Destroy()
	if(weldtool)
		QDEL_NULL(weldtool)
	if(igniter)
		QDEL_NULL(igniter)
	if(ptank)
		QDEL_NULL(ptank)
	return ..()

/obj/item/flamethrower/process()
	if(!lit || !igniter)
		return PROCESS_KILL
	var/turf/location = loc
	if(ismob(location))
		var/mob/M = location
		if(M.is_holding(src))
			location = M.loc
	if(isturf(location)) //start a fire if possible
		igniter.flamethrower_process(location)


/obj/item/flamethrower/update_icon_state()
	inhand_icon_state = "flamethrower_[lit]"
	return ..()

/obj/item/flamethrower/update_overlays()
	. = ..()
	if(igniter)
		. += "+igniter[status]"
	if(ptank)
		. += "+ptank"
	if(lit)
		. += "+lit"

/obj/item/flamethrower/ranged_interact_with_atom(atom/interacting_with, mob/living/user, list/modifiers)
	if (!ptank)
		return NONE
	if(HAS_TRAIT(user, TRAIT_PACIFISM))
		to_chat(user, span_warning("You can't bring yourself to fire \the [src]! You don't want to risk harming anyone..."))
		log_combat(user, interacting_with, "attempted to flamethrower", src, "with gas mixture: {[print_gas_mixture(ptank.return_analyzable_air())]}, flamethrower: \"[name]\" ([src]), igniter: \"[igniter.name]\", tank: \"[ptank.name]\" and tank distribution pressure: \"[siunit(1000 * ptank.distribute_pressure, unit = "Pa", maxdecimals = 9)]\"" + (lit ? " while lit" : "" + " but failed due to pacifism."))
		return ITEM_INTERACT_BLOCKING
	var/turf/target_turf = get_turf(interacting_with)
	if(target_turf)
		var/turflist = get_line(user, target_turf)
		log_combat(user, interacting_with, "flamethrowered", src, "with gas mixture: {[print_gas_mixture(ptank.return_analyzable_air())]}, flamethrower: \"[name]\", igniter: \"[igniter.name]\", tank: \"[ptank.name]\" and tank distribution pressure: \"[siunit(1000 * ptank.distribute_pressure, unit = "Pa", maxdecimals = 9)]\"" + (lit ? " while lit." : "."))
		flame_turf(turflist)
	return ITEM_INTERACT_SUCCESS

/obj/item/flamethrower/wrench_act(mob/living/user, obj/item/tool)
	. = TRUE
	if(status)
		return FALSE
	tool.play_tool_sound(src)
	var/turf/T = get_turf(src)
	if(weldtool)
		weldtool.forceMove(T)
		weldtool = null
	if(igniter)
		igniter.forceMove(T)
		igniter = null
	if(ptank)
		ptank.forceMove(T)
		ptank = null
	new /obj/item/stack/rods(T)
	qdel(src)

/obj/item/flamethrower/screwdriver_act(mob/living/user, obj/item/tool)
	if(igniter && !lit)
		tool.play_tool_sound(src)
		status = !status
		to_chat(user, span_notice("[igniter] is now [status ? "secured" : "unsecured"]!"))
		update_appearance()
		return TRUE

/obj/item/flamethrower/attackby(obj/item/W, mob/user, params)
	if(isigniter(W))
		var/obj/item/assembly/igniter/I = W
		if(I.secured)
			return
		if(igniter)
			return
		if(!user.transferItemToLoc(W, src))
			return
		igniter = I
		update_appearance()
		return

	else if(istype(W, /obj/item/tank/internals/plasma))
		if(ptank)
			if(user.transferItemToLoc(W,src))
				ptank.forceMove(get_turf(src))
				ptank = W
				to_chat(user, span_notice("You swap the plasma tank in [src]!"))
			return
		if(!user.transferItemToLoc(W, src))
			return
		ptank = W
		update_appearance()
		return

	else
		return ..()

/obj/item/flamethrower/return_analyzable_air()
	if(ptank)
		return ptank.return_analyzable_air()
	else
		return null

/obj/item/flamethrower/attack_self(mob/user)
	toggle_igniter(user)

/obj/item/flamethrower/click_alt(mob/user)
	if(isnull(ptank))
		return NONE

	user.put_in_hands(ptank)
	ptank = null
	to_chat(user, span_notice("You remove the plasma tank from [src]!"))
	update_appearance()
	return CLICK_ACTION_SUCCESS

/obj/item/flamethrower/examine(mob/user)
	. = ..()
	if(ptank)
		. += span_notice("\The [src] has \a [ptank] attached. Alt-click to remove it.")

/obj/item/flamethrower/proc/toggle_igniter(mob/user)
	if(!ptank)
		to_chat(user, span_notice("Attach a plasma tank first!"))
		return
	if(!status)
		to_chat(user, span_notice("Secure the igniter first!"))
		return
	to_chat(user, span_notice("You [lit ? "extinguish" : "ignite"] [src]!"))
	lit = !lit
	if(lit)
		playsound(loc, acti_sound, 50, TRUE)
		START_PROCESSING(SSobj, src)
		if(!warned_admins)
			message_admins("[ADMIN_LOOKUPFLW(user)] has lit a flamethrower.")
			warned_admins = TRUE
	else
		playsound(loc, deac_sound, 50, TRUE)
		STOP_PROCESSING(SSobj,src)
	set_light_on(lit)
	update_appearance()

/obj/item/flamethrower/on_craft_completion(list/components, datum/crafting_recipe/current_recipe, atom/crafter)
	. =..()
	weldtool = locate(/obj/item/weldingtool) in contents
	igniter = locate(/obj/item/assembly/igniter) in contents
	weldtool.status = FALSE
	igniter.secured = FALSE
	status = TRUE
	update_appearance()

//Called from turf.dm turf/dblclick
/obj/item/flamethrower/proc/flame_turf(turflist)
	if(!lit || operating)
		return
	operating = TRUE
	var/turf/previousturf = get_turf(src)
	for(var/turf/T in turflist)
		if(T == previousturf)
			continue //so we don't burn the tile we be standin on
		var/list/turfs_sharing_with_prev = previousturf.get_atmos_adjacent_turfs(alldir=1)
		if(!(T in turfs_sharing_with_prev))
			break
		if(igniter)
			igniter.ignite_turf(src,T)
		else
			default_ignite(T)
		sleep(0.1 SECONDS)
		previousturf = T
	operating = FALSE

/obj/item/flamethrower/proc/default_ignite(turf/target, release_amount = 0.05)
	//TODO: DEFERRED Consider checking to make sure tank pressure is high enough before doing this...
	//Transfer 5% of current tank air contents to turf
	var/datum/gas_mixture/tank_mix = ptank.return_air()
	var/datum/gas_mixture/air_transfer = tank_mix.remove_ratio(release_amount)

	if(air_transfer.gases[/datum/gas/plasma])
		air_transfer.gases[/datum/gas/plasma][MOLES] *= 5 //Suffering
	target.assume_air(air_transfer)
	//Burn it based on transferred gas
	target.hotspot_expose((tank_mix.temperature*2) + 380,500)
	//location.hotspot_expose(1000,500,1)

/obj/item/flamethrower/Initialize(mapload)
	. = ..()
	if(create_full)
		if(!weldtool)
			weldtool = new /obj/item/weldingtool(src)
		weldtool.status = FALSE
		if(!igniter)
			igniter = new igniter_type(src)
		igniter.secured = FALSE
		status = TRUE
		if(create_with_tank)
			ptank = new /obj/item/tank/internals/plasma/full(src)
		update_appearance()
	RegisterSignal(src, COMSIG_ITEM_RECHARGED, PROC_REF(instant_refill))

/obj/item/flamethrower/full
	create_full = TRUE

/obj/item/flamethrower/full/tank
	create_with_tank = TRUE

/obj/item/flamethrower/hit_reaction(mob/living/carbon/human/owner, atom/movable/hitby, attack_text = "the attack", final_block_chance = 0, damage = 0, attack_type = MELEE_ATTACK, damage_type = BRUTE)
	if(damage && attack_type == PROJECTILE_ATTACK && damage_type != STAMINA && prob(15))
		owner.visible_message(span_danger("\The [attack_text] hits the fuel tank on [owner]'s [name], rupturing it! What a shot!"))
		var/turf/target_turf = get_turf(owner)
		owner.log_message("held a flamethrower tank detonated by a projectile ([hitby])", LOG_GAME)
		igniter.ignite_turf(src,target_turf, release_amount = 100)
		qdel(ptank)
		return 1 //It hit the flamethrower, not them


/obj/item/assembly/igniter/proc/flamethrower_process(turf/open/location)
	location.hotspot_expose(heat,2)

/obj/item/assembly/igniter/proc/ignite_turf(obj/item/flamethrower/F,turf/open/location,release_amount = 0.05)
	F.default_ignite(location,release_amount)

/obj/item/flamethrower/proc/instant_refill()
	SIGNAL_HANDLER
	if(ptank)
		var/datum/gas_mixture/tank_mix = ptank.return_air()
		tank_mix.assert_gas(/datum/gas/plasma)
		tank_mix.gases[/datum/gas/plasma][MOLES] = (10*ONE_ATMOSPHERE)*ptank.volume/(R_IDEAL_GAS_EQUATION*T20C)
	else
		ptank = new /obj/item/tank/internals/plasma/full(src)
	update_appearance()
