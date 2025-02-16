/* Pens!
 * Contains:
 * Pens
 * Sleepy Pens
 * Parapens
 * Edaggers
 */


/*
 * Pens
 */
/obj/item/pen
	name = "pen"
	desc = "It's a normal black ink pen."
	icon = 'icons/obj/service/bureaucracy.dmi'
	icon_state = "pen"
	inhand_icon_state = "pen"
	worn_icon_state = "pen"
	icon_angle = -135
	slot_flags = ITEM_SLOT_BELT | ITEM_SLOT_EARS
	throwforce = 0
	w_class = WEIGHT_CLASS_TINY
	throw_speed = 3
	throw_range = 7
	custom_materials = list(/datum/material/iron = SMALL_MATERIAL_AMOUNT*0.1)
	pressure_resistance = 2
	grind_results = list(/datum/reagent/iron = 2, /datum/reagent/iodine = 1)
	var/colour = COLOR_BLACK //what colour the ink is!
	var/degrees = 0
	var/font = PEN_FONT
	var/requires_gravity = TRUE // can you use this to write in zero-g
	embed_type = /datum/embedding/pen
	sharpness = SHARP_POINTY
	var/dart_insert_icon = 'icons/obj/weapons/guns/toy.dmi'
	var/dart_insert_casing_icon_state = "overlay_pen"
	var/dart_insert_projectile_icon_state = "overlay_pen_proj"
	/// If this pen can be clicked in order to retract it
	var/can_click = TRUE

/datum/embedding/pen
	embed_chance = 50

/obj/item/pen/Initialize(mapload)
	. = ..()
	AddComponent(/datum/component/dart_insert, \
		dart_insert_icon, \
		dart_insert_casing_icon_state, \
		dart_insert_icon, \
		dart_insert_projectile_icon_state, \
		CALLBACK(src, PROC_REF(get_dart_var_modifiers))\
	)
	AddElement(/datum/element/tool_renaming)
	RegisterSignal(src, COMSIG_DART_INSERT_ADDED, PROC_REF(on_inserted_into_dart))
	RegisterSignal(src, COMSIG_DART_INSERT_REMOVED, PROC_REF(on_removed_from_dart))
	if (!can_click)
		return
	create_transform_component()
	RegisterSignal(src, COMSIG_TRANSFORMING_ON_TRANSFORM, PROC_REF(on_transform))

/// Proc that child classes can override to have custom transforms, like edaggers or pendrivers
/obj/item/pen/proc/create_transform_component()
	AddComponent( \
		/datum/component/transforming, \
		sharpness_on = NONE, \
		inhand_icon_change = FALSE, \
		w_class_on = w_class, \
	)

/*
 * Signal proc for [COMSIG_TRANSFORMING_ON_TRANSFORM].
 *
 * Clicks the pen to make an annoying sound. Clickity clickery click!
 */
/obj/item/pen/proc/on_transform(obj/item/source, mob/user, active)
	SIGNAL_HANDLER

	if(user)
		balloon_alert(user, "clicked")
	playsound(src, 'sound/items/pen_click.ogg', 30, TRUE, -3)
	icon_state = initial(icon_state) + (active ? "_retracted" : "")
	update_appearance(UPDATE_ICON)

	return COMPONENT_NO_DEFAULT_MESSAGE

/obj/item/pen/proc/on_inserted_into_dart(datum/source, obj/projectile/dart, mob/user, embedded = FALSE)
	SIGNAL_HANDLER

/obj/item/pen/proc/get_dart_var_modifiers(obj/projectile/projectile)
	return list(
		"damage" = max(5, throwforce),
		"speed" = max(0, throw_speed - 3),
		"embedding" = get_embed().create_copy(),
		"armour_penetration" = armour_penetration,
		"wound_bonus" = wound_bonus,
		"bare_wound_bonus" = bare_wound_bonus,
		"demolition_mod" = demolition_mod,
	)

/obj/item/pen/proc/on_removed_from_dart(datum/source, obj/projectile/dart, mob/user)
	SIGNAL_HANDLER

/obj/item/pen/suicide_act(mob/living/user)
	user.visible_message(span_suicide("[user] is scribbling numbers all over [user.p_them()]self with [src]! It looks like [user.p_theyre()] trying to commit sudoku..."))
	return BRUTELOSS

/obj/item/pen/blue
	desc = "It's a normal blue ink pen."
	icon_state = "pen_blue"
	colour = COLOR_BLUE

/obj/item/pen/red
	desc = "It's a normal red ink pen."
	icon_state = "pen_red"
	colour = COLOR_RED
	throw_speed = 4 // red ones go faster (in this case, fast enough to embed!)

/obj/item/pen/invisible
	desc = "It's an invisible pen marker."
	icon_state = "pen"
	colour = COLOR_WHITE

/obj/item/pen/fourcolor
	desc = "It's a fancy four-color ink pen, set to black."
	name = "four-color pen"
	icon_state = "pen_4color"
	colour = COLOR_BLACK
	can_click = FALSE

/obj/item/pen/fourcolor/attack_self(mob/living/carbon/user)
	. = ..()
	var/chosen_color = "black"
	switch(colour)
		if(COLOR_BLACK)
			colour = COLOR_RED
			chosen_color = "red"
			throw_speed++
		if(COLOR_RED)
			colour = COLOR_VIBRANT_LIME
			chosen_color = "green"
			throw_speed--
		if(COLOR_VIBRANT_LIME)
			colour = COLOR_BLUE
			chosen_color = "blue"
		else
			colour = COLOR_BLACK
	to_chat(user, span_notice("\The [src] will now write in [chosen_color]."))
	desc = "It's a fancy four-color ink pen, set to [chosen_color]."
	balloon_alert(user, "clicked")
	playsound(src, 'sound/machines/click.ogg', 30, TRUE, -3)

/obj/item/pen/fountain
	name = "fountain pen"
	desc = "It's a common fountain pen, with a faux wood body. Rumored to work in zero gravity situations."
	icon_state = "pen-fountain"
	font = FOUNTAIN_PEN_FONT
	requires_gravity = FALSE // fancy spess pens
	dart_insert_casing_icon_state = "overlay_fountainpen"
	dart_insert_projectile_icon_state = "overlay_fountainpen_proj"
	can_click = FALSE

/obj/item/pen/charcoal
	name = "charcoal stylus"
	desc = "It's just a wooden stick with some compressed ash on the end. At least it can write."
	icon_state = "pen-charcoal"
	colour = "#696969"
	font = CHARCOAL_FONT
	custom_materials = null
	grind_results = list(/datum/reagent/ash = 5, /datum/reagent/cellulose = 10)
	requires_gravity = FALSE // this is technically a pencil
	can_click = FALSE

/datum/crafting_recipe/charcoal_stylus
	name = "Charcoal Stylus"
	result = /obj/item/pen/charcoal
	reqs = list(/obj/item/stack/sheet/mineral/wood = 1, /datum/reagent/ash = 30)
	time = 3 SECONDS
	category = CAT_TOOLS

/obj/item/pen/fountain/captain
	name = "captain's fountain pen"
	desc = "It's an expensive Oak fountain pen. The nib is quite sharp."
	icon_state = "pen-fountain-o"
	force = 5
	throwforce = 5
	throw_speed = 4
	colour = "#DC143C"
	custom_materials = list(/datum/material/gold = SMALL_MATERIAL_AMOUNT*7.5)
	sharpness = SHARP_EDGED
	resistance_flags = FIRE_PROOF
	unique_reskin = list(
		"Oak" = "pen-fountain-o",
		"Gold" = "pen-fountain-g",
		"Rosewood" = "pen-fountain-r",
		"Black and Silver" = "pen-fountain-b",
		"Command Blue" = "pen-fountain-cb"
	)
	embed_type = /datum/embedding/pen/captain
	dart_insert_casing_icon_state = "overlay_fountainpen_gold"
	dart_insert_projectile_icon_state = "overlay_fountainpen_gold_proj"
	var/list/overlay_reskin = list(
		"Oak" = "overlay_fountainpen_gold",
		"Gold" = "overlay_fountainpen_gold",
		"Rosewood" = "overlay_fountainpen_gold",
		"Black and Silver" = "overlay_fountainpen",
		"Command Blue" = "overlay_fountainpen_gold"
	)

/datum/embedding/pen/captain
	embed_chance = 50

/obj/item/pen/fountain/captain/Initialize(mapload)
	. = ..()
	AddComponent(/datum/component/butchering, \
	speed = 20 SECONDS, \
	effectiveness = 115, \
	)
	//the pen is mightier than the sword
	RegisterSignal(src, COMSIG_DART_INSERT_PARENT_RESKINNED, PROC_REF(reskin_dart_insert))

/obj/item/pen/fountain/captain/reskin_obj(mob/M)
	..()
	if(current_skin)
		desc = "It's an expensive [current_skin] fountain pen. The nib is quite sharp."


/obj/item/pen/fountain/captain/proc/reskin_dart_insert(datum/component/dart_insert/insert_comp)
	if(!istype(insert_comp)) //You really shouldn't be sending this signal from anything other than a dart_insert component
		return
	insert_comp.casing_overlay_icon_state = overlay_reskin[current_skin]
	insert_comp.projectile_overlay_icon_state = "[overlay_reskin[current_skin]]_proj"

/obj/item/pen/item_ctrl_click(mob/living/carbon/user)
	if(loc != user)
		to_chat(user, span_warning("You must be holding the pen to continue!"))
		return CLICK_ACTION_BLOCKING
	var/deg = tgui_input_number(user, "What angle would you like to rotate the pen head to? (0-360)", "Rotate Pen Head", max_value = 360)
	if(isnull(deg) || QDELETED(user) || QDELETED(src) || !user.can_perform_action(src, FORBID_TELEKINESIS_REACH) || loc != user)
		return CLICK_ACTION_BLOCKING
	degrees = deg
	to_chat(user, span_notice("You rotate the top of the pen to [deg] degrees."))
	SEND_SIGNAL(src, COMSIG_PEN_ROTATED, deg, user)
	return CLICK_ACTION_SUCCESS

/obj/item/pen/attack(mob/living/M, mob/user, params)
	if(force) // If the pen has a force value, call the normal attack procs. Used for e-daggers and captain's pen mostly.
		return ..()
	if(!M.try_inject(user, injection_flags = INJECT_TRY_SHOW_ERROR_MESSAGE))
		return FALSE
	to_chat(user, span_warning("You stab [M] with the pen."))
	to_chat(M, span_danger("You feel a tiny prick!"))
	log_combat(user, M, "stabbed", src)
	return TRUE

/obj/item/pen/get_writing_implement_details()
	if (HAS_TRAIT(src, TRAIT_TRANSFORM_ACTIVE))
		return null
	return list(
		interaction_mode = MODE_WRITING,
		font = font,
		color = colour,
		use_bold = FALSE,
	)

/*
 * Sleepypens
 */

/obj/item/pen/sleepy/attack(mob/living/M, mob/user, params)
	. = ..()
	if(!.)
		return
	if(!reagents.total_volume)
		return
	if(!M.reagents)
		return
	reagents.trans_to(M, reagents.total_volume, transferred_by = user, methods = INJECT)


/obj/item/pen/sleepy/Initialize(mapload)
	. = ..()
	create_reagents(45, OPENCONTAINER)
	reagents.add_reagent(/datum/reagent/toxin/chloralhydrate, 20)
	reagents.add_reagent(/datum/reagent/toxin/mutetoxin, 15)
	reagents.add_reagent(/datum/reagent/toxin/staminatoxin, 10)

/obj/item/pen/sleepy/on_inserted_into_dart(datum/source, obj/item/ammo_casing/dart, mob/user)
	. = ..()
	var/obj/projectile/proj = dart.loaded_projectile
	RegisterSignal(proj, COMSIG_PROJECTILE_SELF_ON_HIT, PROC_REF(on_dart_hit))

/obj/item/pen/sleepy/on_removed_from_dart(datum/source, obj/item/ammo_casing/dart, obj/projectile/proj, mob/user)
	. = ..()
	if(istype(proj))
		UnregisterSignal(proj, COMSIG_PROJECTILE_SELF_ON_HIT)

/obj/item/pen/sleepy/proc/on_dart_hit(datum/source, atom/movable/firer, atom/target, angle, hit_limb, blocked)
	SIGNAL_HANDLER
	var/mob/living/carbon/carbon_target = target
	if(!istype(carbon_target) || blocked == 100)
		return
	if(carbon_target.can_inject(target_zone = hit_limb))
		reagents.trans_to(carbon_target, reagents.total_volume, transferred_by = firer, methods = INJECT)
/*
 * (Alan) Edaggers
 */
/obj/item/pen/edagger
	attack_verb_continuous = list("slashes", "slices", "tears", "lacerates", "rips", "dices", "cuts") //these won't show up if the pen is off
	attack_verb_simple = list("slash", "slice", "tear", "lacerate", "rip", "dice", "cut")
	sharpness = SHARP_POINTY
	armour_penetration = 20
	bare_wound_bonus = 10
	item_flags = NO_BLOOD_ON_ITEM
	light_system = OVERLAY_LIGHT
	light_range = 1.5
	light_power = 1.3
	light_color = "#FA8282"
	light_on = FALSE
	dart_insert_projectile_icon_state = "overlay_edagger"
	/// The real name of our item when extended.
	var/hidden_name = "energy dagger"
	/// The real desc of our item when extended.
	var/hidden_desc = "It's a normal black ink pe- Wait. That's a thing used to stab people!"
	/// The real icons used when extended.
	var/hidden_icon = "edagger"
	var/list/alt_continuous = list("stabs", "pierces", "shanks")
	var/list/alt_simple = list("stab", "pierce", "shank")

/obj/item/pen/edagger/Initialize(mapload)
	. = ..()
	alt_continuous = string_list(alt_continuous)
	alt_simple = string_list(alt_simple)
	AddComponent(/datum/component/alternative_sharpness, SHARP_POINTY, alt_continuous, alt_simple, -5, TRAIT_TRANSFORM_ACTIVE)
	AddComponent(/datum/component/butchering, \
	speed = 6 SECONDS, \
	butcher_sound = 'sound/items/weapons/blade1.ogg', \
	)
	RegisterSignal(src, COMSIG_DETECTIVE_SCANNED, PROC_REF(on_scan))

/obj/item/pen/edagger/create_transform_component()
	AddComponent( \
		/datum/component/transforming, \
		force_on = 18, \
		throwforce_on = 35, \
		throw_speed_on = 4, \
		sharpness_on = SHARP_EDGED, \
		w_class_on = WEIGHT_CLASS_NORMAL, \
		inhand_icon_change = FALSE, \
	)

/obj/item/pen/edagger/on_inserted_into_dart(datum/source, obj/item/ammo_casing/dart, mob/user)
	. = ..()
	var/datum/component/transforming/transform_comp = GetComponent(/datum/component/transforming)
	if(HAS_TRAIT(src, TRAIT_TRANSFORM_ACTIVE))
		transform_comp.do_transform(src, user)
	RegisterSignal(dart.loaded_projectile, COMSIG_PROJECTILE_FIRE, PROC_REF(on_containing_dart_fired))
	RegisterSignal(dart.loaded_projectile, COMSIG_PROJECTILE_ON_SPAWN_DROP, PROC_REF(on_containing_dart_drop))
	RegisterSignal(dart.loaded_projectile, COMSIG_PROJECTILE_ON_SPAWN_EMBEDDED, PROC_REF(on_containing_dart_embedded))

/obj/item/pen/edagger/on_removed_from_dart(datum/source, obj/item/ammo_casing/dart, obj/projectile/projectile, mob/user)
	. = ..()
	if(istype(dart))
		UnregisterSignal(dart, list(COMSIG_ITEM_UNEMBEDDED, COMSIG_ITEM_FAILED_EMBED))
	if(istype(projectile))
		UnregisterSignal(projectile, list(COMSIG_PROJECTILE_FIRE, COMSIG_PROJECTILE_ON_SPAWN_DROP, COMSIG_PROJECTILE_ON_SPAWN_EMBEDDED))

/obj/item/pen/edagger/get_dart_var_modifiers()
	. = ..()
	var/datum/component/transforming/transform_comp = GetComponent(/datum/component/transforming)
	.["damage"] = max(5, transform_comp.throwforce_on)
	.["speed"] = max(0, transform_comp.throw_speed_on - 3)
	var/datum/embedding/data = .["embedding"]
	data.embed_chance = 100

/obj/item/pen/edagger/proc/on_containing_dart_fired(obj/projectile/source)
	SIGNAL_HANDLER
	playsound(source, 'sound/items/weapons/saberon.ogg', 5, TRUE)
	var/datum/component/transforming/transform_comp = GetComponent(/datum/component/transforming)
	source.hitsound = transform_comp.hitsound_on
	source.set_light(light_range, light_power, light_color, l_on = TRUE)

/obj/item/pen/edagger/proc/on_containing_dart_drop(datum/source, obj/item/ammo_casing/new_casing)
	SIGNAL_HANDLER
	playsound(new_casing, 'sound/items/weapons/saberoff.ogg', 5, TRUE)

/obj/item/pen/edagger/proc/on_containing_dart_embedded(datum/source, obj/item/ammo_casing/new_casing)
	SIGNAL_HANDLER
	RegisterSignal(new_casing, COMSIG_ITEM_UNEMBEDDED, PROC_REF(on_embedded_removed))
	RegisterSignal(new_casing, COMSIG_ITEM_FAILED_EMBED, PROC_REF(on_containing_dart_failed_embed))

/obj/item/pen/edagger/proc/on_containing_dart_failed_embed(obj/item/ammo_casing/source)
	SIGNAL_HANDLER
	playsound(source, 'sound/items/weapons/saberoff.ogg', 5, TRUE)
	UnregisterSignal(source, list(COMSIG_ITEM_UNEMBEDDED, COMSIG_ITEM_FAILED_EMBED))

/obj/item/pen/edagger/proc/on_embedded_removed(obj/item/ammo_casing/source, mob/living/carbon/victim)
	SIGNAL_HANDLER
	playsound(source, 'sound/items/weapons/saberoff.ogg', 5, TRUE)
	UnregisterSignal(source, list(COMSIG_ITEM_UNEMBEDDED, COMSIG_ITEM_FAILED_EMBED))
	victim.visible_message(
		message = span_warning("The blade of the [hidden_name] retracts as \the [source] is removed from [victim]!"),
		self_message = span_warning("The blade of the [hidden_name] retracts as \the [source] is removed from you!"),
		blind_message = span_warning("You hear an energy blade retract!"),
		vision_distance = 1
	)

/obj/item/pen/edagger/suicide_act(mob/living/user)
	if(HAS_TRAIT(src, TRAIT_TRANSFORM_ACTIVE))
		user.visible_message(span_suicide("[user] forcefully rams the pen into their mouth!"))
	else
		user.visible_message(span_suicide("[user] is holding a pen up to their mouth! It looks like [user.p_theyre()] trying to commit suicide!"))
		attack_self(user)
	return BRUTELOSS

/*
 * Signal proc for [COMSIG_TRANSFORMING_ON_TRANSFORM].
 *
 * Handles swapping their icon files to edagger related icon files -
 * as they're supposed to look like a normal pen.
 */
/obj/item/pen/edagger/on_transform(obj/item/source, mob/user, active)
	if(active)
		name = hidden_name
		desc = hidden_desc
		icon_state = hidden_icon
		inhand_icon_state = hidden_icon
		lefthand_file = 'icons/mob/inhands/weapons/swords_lefthand.dmi'
		righthand_file = 'icons/mob/inhands/weapons/swords_righthand.dmi'
		set_embed(/datum/embedding/edagger_active)
	else
		name = initial(name)
		desc = initial(desc)
		icon_state = initial(icon_state)
		inhand_icon_state = initial(inhand_icon_state)
		lefthand_file = initial(lefthand_file)
		righthand_file = initial(righthand_file)
		set_embed(embed_type)

	if(user)
		balloon_alert(user, "[hidden_name] [active ? "active" : "concealed"]")
	playsound(src, active ? 'sound/items/weapons/saberon.ogg' : 'sound/items/weapons/saberoff.ogg', 5, TRUE)
	set_light_on(active)
	return COMPONENT_NO_DEFAULT_MESSAGE

/datum/embedding/edagger_active
	embed_chance = 100

/obj/item/pen/edagger/proc/on_scan(datum/source, mob/user, list/extra_data)
	SIGNAL_HANDLER
	LAZYADD(extra_data[DETSCAN_CATEGORY_ILLEGAL], "Hard-light generator detected.")

/obj/item/pen/survival
	name = "survival pen"
	desc = "The latest in portable survival technology, this pen was designed as a miniature diamond pickaxe. Watchers find them very desirable for their diamond exterior."
	icon = 'icons/obj/service/bureaucracy.dmi'
	icon_state = "digging_pen"
	inhand_icon_state = "pen"
	worn_icon_state = "pen"
	force = 3
	w_class = WEIGHT_CLASS_TINY
	custom_materials = list(/datum/material/iron=SMALL_MATERIAL_AMOUNT*0.1, /datum/material/diamond=SMALL_MATERIAL_AMOUNT, /datum/material/titanium = SMALL_MATERIAL_AMOUNT*0.1)
	pressure_resistance = 2
	grind_results = list(/datum/reagent/iron = 2, /datum/reagent/iodine = 1)
	tool_behaviour = TOOL_MINING //For the classic "digging out of prison with a spoon but you're in space so this analogy doesn't work" situation.
	toolspeed = 10 //You will never willingly choose to use one of these over a shovel.
	font = FOUNTAIN_PEN_FONT
	colour = COLOR_BLUE
	dart_insert_casing_icon_state = "overlay_survivalpen"
	dart_insert_projectile_icon_state = "overlay_survivalpen_proj"
	can_click = FALSE

/obj/item/pen/survival/on_inserted_into_dart(datum/source, obj/item/ammo_casing/dart, mob/user)
	. = ..()
	RegisterSignal(dart.loaded_projectile, COMSIG_PROJECTILE_SELF_ON_HIT, PROC_REF(on_dart_hit))

/obj/item/pen/survival/on_removed_from_dart(datum/source, obj/item/ammo_casing/dart, obj/projectile/proj, mob/user)
	. = ..()
	if(istype(proj))
		UnregisterSignal(proj, COMSIG_PROJECTILE_SELF_ON_HIT)

/obj/item/pen/survival/proc/on_dart_hit(obj/projectile/source, atom/movable/firer, atom/target)
	var/turf/target_turf = get_turf(target)
	if(!target_turf)
		target_turf = get_turf(src)
	if(ismineralturf(target_turf))
		var/turf/closed/mineral/mineral_turf = target_turf
		mineral_turf.gets_drilled(firer, TRUE)

/obj/item/pen/destroyer
	name = "Fine Tipped Pen"
	desc = "A pen with an infinitely-sharpened tip. Capable of striking the weakest point of a strucutre or robot and annihilating it instantly. Good at putting holes in people too."
	force = 5
	wound_bonus = 100
	demolition_mod = 9000

// screwdriver pen!

/obj/item/pen/screwdriver
	desc = "A pen with an extendable screwdriver tip. This one has a yellow cap."
	icon_state = "pendriver"
	toolspeed = 1.2  // gotta have some downside
	dart_insert_projectile_icon_state = "overlay_pendriver"

/obj/item/pen/screwdriver/get_all_tool_behaviours()
	return list(TOOL_SCREWDRIVER)

/obj/item/pen/screwdriver/Initialize(mapload)
	. = ..()
	AddElement(/datum/element/update_icon_updates_onmob)

/obj/item/pen/screwdriver/create_transform_component()
	AddComponent( \
		/datum/component/transforming, \
		throwforce_on = 5, \
		w_class_on = WEIGHT_CLASS_SMALL, \
		sharpness_on = TRUE, \
		inhand_icon_change = FALSE, \
	)

/obj/item/pen/screwdriver/on_transform(obj/item/source, mob/user, active)
	if(user)
		balloon_alert(user, active ? "extended" : "retracted")
	playsound(src, 'sound/items/weapons/batonextend.ogg', 50, TRUE)

	if(!active)
		tool_behaviour = initial(tool_behaviour)
		RemoveElement(/datum/element/eyestab)
	else
		tool_behaviour = TOOL_SCREWDRIVER
		AddElement(/datum/element/eyestab)

	update_appearance(UPDATE_ICON)
	return COMPONENT_NO_DEFAULT_MESSAGE

/obj/item/pen/screwdriver/update_icon_state()
	. = ..()
	icon_state = "[initial(icon_state)][HAS_TRAIT(src, TRAIT_TRANSFORM_ACTIVE) ? "_out" : null]"
	inhand_icon_state = initial(inhand_icon_state) //since transforming component switches the icon.

//The Security holopen
/obj/item/pen/red/security
	name = "security pen"
	desc = "This is a red ink pen exclusively provided to members of the Security Department. Its opposite end features a built-in holographic projector designed for issuing arrest prompts to individuals."
	icon_state = "pen_sec"
	COOLDOWN_DECLARE(holosign_cooldown)

/obj/item/pen/red/security/examine(mob/user)
	. = ..()
	. += span_notice("To initiate the surrender prompt, simply click on an individual within your proximity.")

//Code from the medical penlight
/obj/item/pen/red/security/ranged_interact_with_atom(atom/interacting_with, mob/living/user, list/modifiers)
	if(!COOLDOWN_FINISHED(src, holosign_cooldown))
		balloon_alert(user, "not ready!")
		return ITEM_INTERACT_BLOCKING

	var/turf/target_turf = get_turf(interacting_with)
	var/mob/living/living_target = locate(/mob/living) in target_turf

	if(!living_target || (living_target == user))
		return ITEM_INTERACT_BLOCKING

	living_target.apply_status_effect(/datum/status_effect/surrender_timed)
	to_chat(living_target, span_userdanger("[user] requests your immediate surrender! You are given 30 seconds to comply!"))
	new /obj/effect/temp_visual/security_holosign(target_turf, user) //produce a holographic glow
	COOLDOWN_START(src, holosign_cooldown, 30 SECONDS)
	return ITEM_INTERACT_SUCCESS

/obj/effect/temp_visual/security_holosign
	name = "security holosign"
	desc = "A small holographic glow that indicates you're under arrest."
	icon_state = "sec_holo"
	duration = 60

/obj/effect/temp_visual/security_holosign/Initialize(mapload, creator)
	. = ..()
	playsound(loc, 'sound/machines/chime.ogg', 50, FALSE) //make some noise!
	if(creator)
		visible_message(span_danger("[creator] created a security hologram!"))
