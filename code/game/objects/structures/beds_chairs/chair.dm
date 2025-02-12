/obj/structure/chair
	name = "chair"
	desc = "You sit in this. Either by will or force."
	icon = 'icons/obj/chairs.dmi'
	icon_state = "chair"
	anchored = TRUE
	can_buckle = TRUE
	buckle_lying = 0 //you sit in a chair, not lay
	resistance_flags = NONE
	max_integrity = 100
	integrity_failure = 0.1
	custom_materials = list(/datum/material/iron =SHEET_MATERIAL_AMOUNT)
	layer = OBJ_LAYER
	interaction_flags_mouse_drop = ALLOW_RESTING

	var/buildstacktype = /obj/item/stack/sheet/iron
	var/buildstackamount = 1
	var/item_chair = /obj/item/chair // if null it can't be picked up
	///How much sitting on this chair influences fishing difficulty
	var/fishing_modifier = -5
	var/has_armrest = FALSE
	// The mutable appearance used for the overlay over buckled mobs.
	var/mutable_appearance/armrest

/obj/structure/chair/Initialize(mapload)
	. = ..()
	if(prob(0.2))
		name = "tactical [name]"
		fishing_modifier -= 8
	MakeRotate()
	if (has_armrest)
		gen_armrest()
	if(can_buckle && fishing_modifier)
		AddComponent(/datum/component/adjust_fishing_difficulty, fishing_modifier)

/obj/structure/chair/on_changed_z_level(turf/old_turf, turf/new_turf, same_z_layer, notify_contents)
	if(same_z_layer || !has_armrest)
		return ..()
	cut_overlay(armrest)
	QDEL_NULL(armrest)
	gen_armrest()
	return ..()

/obj/structure/chair/examine(mob/user)
	. = ..()
	. += span_notice("It's held together by a couple of <b>bolts</b>.")
	if(!has_buckled_mobs() && can_buckle)
		. += span_notice("While standing on [src], drag and drop your sprite onto [src] to buckle to it.")

///This proc adds the rotate component, overwrite this if you for some reason want to change some specific args.
/obj/structure/chair/proc/MakeRotate()
	AddComponent(/datum/component/simple_rotation, ROTATION_IGNORE_ANCHORED|ROTATION_GHOSTS_ALLOWED)

/obj/structure/chair/Destroy()
	SSjob.latejoin_trackers -= src //These may be here due to the arrivals shuttle
	QDEL_NULL(armrest)
	return ..()

/obj/structure/chair/atom_deconstruct(disassembled)
	if(buildstacktype)
		new buildstacktype(loc,buildstackamount)
	else
		for(var/datum/material/mat as anything in custom_materials)
			new mat.sheet_type(loc, FLOOR(custom_materials[mat] / SHEET_MATERIAL_AMOUNT, 1))

/obj/structure/chair/attack_paw(mob/user, list/modifiers)
	return attack_hand(user, modifiers)

/obj/structure/chair/narsie_act()
	var/obj/structure/chair/wood/W = new/obj/structure/chair/wood(get_turf(src))
	W.setDir(dir)
	qdel(src)

/obj/structure/chair/attackby(obj/item/W, mob/user, params)
	if(istype(W, /obj/item/assembly/shock_kit) && !HAS_TRAIT(src, TRAIT_ELECTRIFIED_BUCKLE))
		electrify_self(W, user)
		return
	. = ..()

/obj/structure/chair/update_atom_colour()
	. = ..()
	if (armrest)
		color_atom_overlay(armrest)

/obj/structure/chair/proc/gen_armrest()
	armrest = GetArmrest()
	armrest.layer = ABOVE_MOB_LAYER
	armrest.appearance_flags |= KEEP_APART
	update_armrest()

/obj/structure/chair/proc/GetArmrest()
	return mutable_appearance(icon, "[icon_state]_armrest")

/obj/structure/chair/proc/update_armrest()
	if (cached_color_filter)
		armrest = filter_appearance_recursive(armrest, cached_color_filter)
	update_appearance()

/obj/structure/chair/update_overlays()
	. = ..()
	if(has_buckled_mobs())
		. += armrest

///allows each chair to request the electrified_buckle component with overlays that dont look ridiculous
/obj/structure/chair/proc/electrify_self(obj/item/assembly/shock_kit/input_shock_kit, mob/user, list/overlays_from_child_procs)
	SHOULD_CALL_PARENT(TRUE)
	if(!user.temporarilyRemoveItemFromInventory(input_shock_kit))
		return
	if(!overlays_from_child_procs || overlays_from_child_procs.len == 0)
		var/mutable_appearance/echair_overlay = mutable_appearance('icons/obj/chairs.dmi', "echair_over", OBJ_LAYER, src, appearance_flags = KEEP_APART)
		AddComponent(/datum/component/electrified_buckle, (SHOCK_REQUIREMENT_ITEM | SHOCK_REQUIREMENT_LIVE_CABLE | SHOCK_REQUIREMENT_SIGNAL_RECEIVED_TOGGLE), input_shock_kit, list(echair_overlay), FALSE)
	else
		AddComponent(/datum/component/electrified_buckle, (SHOCK_REQUIREMENT_ITEM | SHOCK_REQUIREMENT_LIVE_CABLE | SHOCK_REQUIREMENT_SIGNAL_RECEIVED_TOGGLE), input_shock_kit, overlays_from_child_procs, FALSE)

	if(HAS_TRAIT(src, TRAIT_ELECTRIFIED_BUCKLE))
		to_chat(user, span_notice("You connect the shock kit to \the [src], electrifying it "))
	else
		user.put_in_active_hand(input_shock_kit)
		to_chat(user, span_notice("You cannot fit the shock kit onto \the [src]!"))


/obj/structure/chair/wrench_act_secondary(mob/living/user, obj/item/weapon)
	..()
	weapon.play_tool_sound(src)
	deconstruct(disassembled = TRUE)
	return TRUE

/obj/structure/chair/attack_tk(mob/user)
	if(!anchored || has_buckled_mobs() || !isturf(user.loc))
		return ..()
	setDir(turn(dir,-90))
	return COMPONENT_CANCEL_ATTACK_CHAIN


/obj/structure/chair/proc/handle_rotation(direction)
	handle_layer()
	if(has_buckled_mobs())
		for(var/m in buckled_mobs)
			var/mob/living/buckled_mob = m
			buckled_mob.setDir(direction)

/obj/structure/chair/proc/handle_layer()
	if(has_buckled_mobs() && dir == NORTH)
		layer = ABOVE_MOB_LAYER
	else
		layer = OBJ_LAYER

/obj/structure/chair/post_buckle_mob(mob/living/M)
	. = ..()
	handle_layer()
	if (has_armrest)
		update_armrest()

/obj/structure/chair/post_unbuckle_mob()
	. = ..()
	handle_layer()
	if (has_armrest)
		update_armrest()

/obj/structure/chair/setDir(newdir)
	..()
	handle_rotation(newdir)

// Chair types

///Material chair
/obj/structure/chair/greyscale
	material_flags = MATERIAL_EFFECTS | MATERIAL_ADD_PREFIX | MATERIAL_COLOR | MATERIAL_AFFECT_STATISTICS
	item_chair = /obj/item/chair/greyscale
	buildstacktype = null //Custom mats handle this


/obj/structure/chair/wood
	icon_state = "wooden_chair"
	name = "wooden chair"
	desc = "Old is never too old to not be in fashion."
	resistance_flags = FLAMMABLE
	max_integrity = 40
	buildstacktype = /obj/item/stack/sheet/mineral/wood
	buildstackamount = 3
	item_chair = /obj/item/chair/wood
	fishing_modifier = -6

/obj/structure/chair/wood/narsie_act()
	return

/obj/structure/chair/wood/wings
	icon_state = "wooden_chair_wings"
	item_chair = /obj/item/chair/wood/wings

/obj/structure/chair/comfy
	name = "comfy chair"
	desc = "It looks comfy."
	icon_state = "comfychair"
	color = rgb(255, 255, 255)
	resistance_flags = FLAMMABLE
	max_integrity = 70
	buildstackamount = 2
	item_chair = null
	fishing_modifier = -7
	has_armrest = TRUE

/obj/structure/chair/comfy/brown
	color = rgb(70, 47, 28)

/obj/structure/chair/comfy/beige
	color = rgb(240, 238, 198)

/obj/structure/chair/comfy/teal
	color = rgb(117, 214, 214)

/obj/structure/chair/comfy/black
	color = rgb(61, 60, 56)

/obj/structure/chair/comfy/lime
	color = rgb(193, 248, 104)

/obj/structure/chair/comfy/shuttle
	name = "shuttle seat"
	desc = "A comfortable, secure seat. It has a more sturdy looking buckling system, for smoother flights."
	icon_state = "shuttle_chair"
	buildstacktype = /obj/item/stack/sheet/mineral/titanium
	buckle_sound = SFX_SEATBELT_BUCKLE
	unbuckle_sound = SFX_SEATBELT_UNBUCKLE

/obj/structure/chair/comfy/shuttle/electrify_self(obj/item/assembly/shock_kit/input_shock_kit, mob/user, list/overlays_from_child_procs)
	if(!overlays_from_child_procs)
		var/mutable_appearance/echair_overlay = mutable_appearance('icons/obj/chairs.dmi', "echair_over", OBJ_LAYER, src, appearance_flags = KEEP_APART)
		echair_overlay.pixel_x = -1
		overlays_from_child_procs = list(echair_overlay)
	. = ..()

/obj/structure/chair/comfy/shuttle/tactical
	name = "tactical chair"

/obj/structure/chair/comfy/carp
	name = "carpskin chair"
	desc = "A luxurious chair, the many purple scales reflect the light in a most pleasing manner."
	icon_state = "carp_chair"
	buildstacktype = /obj/item/stack/sheet/animalhide/carp
	fishing_modifier = -12

/obj/structure/chair/office
	name = "office chair"
	anchored = FALSE
	buildstackamount = 5
	item_chair = null
	fishing_modifier = -6
	icon_state = "officechair_dark"

/obj/structure/chair/office/Initialize(mapload)
	. = ..()
	AddElement(/datum/element/noisy_movement)

/obj/structure/chair/office/electrify_self(obj/item/assembly/shock_kit/input_shock_kit, mob/user, list/overlays_from_child_procs)
	if(!overlays_from_child_procs)
		var/mutable_appearance/echair_overlay = mutable_appearance('icons/obj/chairs.dmi', "echair_over", OBJ_LAYER, src, appearance_flags = KEEP_APART)
		echair_overlay.pixel_x = -1
		overlays_from_child_procs = list(echair_overlay)
	. = ..()

/obj/structure/chair/office/tactical
	name = "tactical swivel chair"
	fishing_modifier = -10

/obj/structure/chair/office/light
	name = "office chair"
	icon_state = "officechair_white"

//Stool

/obj/structure/chair/stool
	name = "stool"
	desc = "Apply butt."
	icon_state = "stool"
	can_buckle = FALSE
	buildstackamount = 1
	item_chair = /obj/item/chair/stool
	max_integrity = 300

MAPPING_DIRECTIONAL_HELPERS(/obj/structure/chair/stool, 0)

/obj/structure/chair/stool/narsie_act()
	return

/obj/structure/chair/mouse_drop_dragged(atom/over_object, mob/user, src_location, over_location, params)
	if(!isliving(user) || over_object != user)
		return
	if(!item_chair || has_buckled_mobs())
		return
	if(flags_1 & HOLOGRAM_1)
		to_chat(user, span_notice("You try to pick up \the [src], but it fades away!"))
		qdel(src)
		return

	user.visible_message(span_notice("[user] grabs \the [src.name]."), span_notice("You grab \the [src.name]."))
	var/obj/item/chair_item = new item_chair(loc)
	chair_item.set_custom_materials(custom_materials)
	TransferComponents(chair_item)
	chair_item.update_integrity(get_integrity())
	user.put_in_hands(chair_item)
	qdel(src)

/obj/structure/chair/user_buckle_mob(mob/living/M, mob/user, check_loc = TRUE)
	return ..()

/obj/structure/chair/stool/bar
	name = "bar stool"
	desc = "It has some unsavory stains on it..."
	icon_state = "bar"
	item_chair = /obj/item/chair/stool/bar
	can_buckle = TRUE

/obj/structure/chair/stool/bar/post_buckle_mob(mob/living/M)
	M.pixel_y += 4

/obj/structure/chair/stool/bar/post_unbuckle_mob(mob/living/M)
	M.pixel_y -= 4

MAPPING_DIRECTIONAL_HELPERS(/obj/structure/chair/stool/bar, 0)

/obj/structure/chair/stool/bamboo
	name = "bamboo stool"
	desc = "A makeshift bamboo stool with a rustic look."
	icon_state = "bamboo_stool"
	resistance_flags = FLAMMABLE
	max_integrity = 40
	buildstacktype = /obj/item/stack/sheet/mineral/bamboo
	buildstackamount = 2
	item_chair = /obj/item/chair/stool/bamboo

/obj/item/chair
	name = "chair"
	desc = "Bar brawl essential."
	icon = 'icons/obj/chairs.dmi'
	icon_state = "chair_toppled"
	inhand_icon_state = "chair"
	icon_angle = 180
	lefthand_file = 'icons/mob/inhands/items/chairs_lefthand.dmi'
	righthand_file = 'icons/mob/inhands/items/chairs_righthand.dmi'
	w_class = WEIGHT_CLASS_HUGE
	force = 8
	throwforce = 10
	demolition_mod = 1.25
	throw_range = 3
	max_integrity = 100
	hitsound = 'sound/items/trayhit/trayhit1.ogg'
	hit_reaction_chance = 50
	custom_materials = list(/datum/material/iron =SHEET_MATERIAL_AMOUNT)
	item_flags = SKIP_FANTASY_ON_SPAWN

	// Duration of daze inflicted when the chair is smashed against someone from behind.
	var/daze_amount = 3 SECONDS

	// What structure type does this chair become when placed?
	var/obj/structure/chair/origin_type = /obj/structure/chair

/obj/item/chair/suicide_act(mob/living/carbon/user)
	user.visible_message(span_suicide("[user] begins hitting [user.p_them()]self with \the [src]! It looks like [user.p_theyre()] trying to commit suicide!"))
	playsound(src,hitsound,50,TRUE)
	return BRUTELOSS

/obj/item/chair/narsie_act()
	var/obj/item/chair/wood/W = new/obj/item/chair/wood(get_turf(src))
	W.setDir(dir)
	qdel(src)

/obj/item/chair/attack_self(mob/user)
	plant(user)

/obj/item/chair/proc/plant(mob/user)
	var/turf/T = get_turf(loc)
	if(isgroundlessturf(T))
		to_chat(user, span_warning("You need ground to plant this on!"))
		return
	if(flags_1 & HOLOGRAM_1)
		to_chat(user, span_notice("You try to place down \the [src], but it fades away!"))
		qdel(src)
		return

	for(var/obj/A in T)
		if(istype(A, /obj/structure/chair))
			to_chat(user, span_warning("There is already a chair here!"))
			return
		if(A.density && !(A.flags_1 & ON_BORDER_1))
			to_chat(user, span_warning("There is already something here!"))
			return

	user.visible_message(span_notice("[user] rights \the [src.name]."), span_notice("You right \the [name]."))
	var/obj/structure/chair/chair = new origin_type(get_turf(loc))
	chair.set_custom_materials(custom_materials)
	TransferComponents(chair)
	chair.setDir(user.dir)
	chair.update_integrity(get_integrity())
	qdel(src)

/obj/item/chair/proc/smash(mob/living/user)
	var/stack_type = initial(origin_type.buildstacktype)
	if(!stack_type)
		return
	var/remaining_mats = initial(origin_type.buildstackamount)
	remaining_mats-- //Part of the chair was rendered completely unusable. It magically disappears. Maybe make some dirt?
	if(remaining_mats)
		for(var/M=1 to remaining_mats)
			new stack_type(get_turf(loc))
	else if(custom_materials[GET_MATERIAL_REF(/datum/material/iron)])
		new /obj/item/stack/rods(get_turf(loc), 2)
	qdel(src)

/obj/item/chair/hit_reaction(mob/living/carbon/human/owner, atom/movable/hitby, attack_text = "the attack", final_block_chance = 0, damage = 0, attack_type = MELEE_ATTACK, damage_type = BRUTE)
	if(attack_type == UNARMED_ATTACK && prob(hit_reaction_chance) || attack_type == LEAP_ATTACK && prob(hit_reaction_chance))
		owner.visible_message(span_danger("[owner] fends off [attack_text] with [src]!"))
		if(take_chair_damage(damage, damage_type, MELEE)) // Our chair takes our incoming damage for us, which can result in it smashing.
			smash(owner)
		return TRUE
	return FALSE

/obj/item/chair/afterattack(atom/target, mob/user, click_parameters)
	if(!ishuman(target))
		return

	var/mob/living/carbon/human/give_this_fucker_the_chair = target

	// Here we determine if our attack is against a vulnerable target
	var/vulnerable_hit = check_behind(user, give_this_fucker_the_chair)

	// If our attack is against a vulnerable target, we do additional damage to the chair
	var/damage_to_inflict = vulnerable_hit ? (force * 5) : (force * 2.5)

	if(!take_chair_damage(damage_to_inflict, damtype, MELEE)) // If we would do enough damage to bring our chair's integrity to 0, we instead go past the check to smash it against our target
		return

	user.visible_message(span_danger("[user] smashes [src] to pieces against [give_this_fucker_the_chair]"))
	if(!HAS_TRAIT(give_this_fucker_the_chair, TRAIT_BRAWLING_KNOCKDOWN_BLOCKED))
		if(vulnerable_hit || give_this_fucker_the_chair.get_timed_status_effect_duration(/datum/status_effect/staggered))
			give_this_fucker_the_chair.Knockdown(2 SECONDS, daze_amount = daze_amount)
			if(give_this_fucker_the_chair.health < give_this_fucker_the_chair.maxHealth*0.5)
				give_this_fucker_the_chair.adjust_confusion(10 SECONDS)

	smash(user)

/obj/item/chair/proc/take_chair_damage(damage_to_inflict, damage_type, armor_flag)
	if(damage_to_inflict >= atom_integrity)
		return TRUE
	take_damage(damage_to_inflict, damage_type, armor_flag)
	return FALSE

/obj/item/chair/greyscale
	material_flags = MATERIAL_EFFECTS | MATERIAL_ADD_PREFIX | MATERIAL_COLOR | MATERIAL_AFFECT_STATISTICS
	origin_type = /obj/structure/chair/greyscale

/obj/item/chair/stool
	name = "stool"
	icon_state = "stool_toppled"
	inhand_icon_state = "stool"
	origin_type = /obj/structure/chair/stool
	max_integrity = 300 //It's too sturdy.

/obj/item/chair/stool/bar
	name = "bar stool"
	icon_state = "bar_toppled"
	inhand_icon_state = "stool_bar"
	origin_type = /obj/structure/chair/stool/bar

/obj/item/chair/stool/bamboo
	name = "bamboo stool"
	icon_state = "bamboo_stool"
	inhand_icon_state = "stool_bamboo"
	hitsound = 'sound/items/weapons/genhit1.ogg'
	origin_type = /obj/structure/chair/stool/bamboo
	max_integrity = 40 //Submissive and breakable unlike the chad iron stool
	daze_amount = 0 //Not hard enough to cause them to become dazed

/obj/item/chair/stool/narsie_act()
	return //sturdy enough to ignore a god

/obj/item/chair/wood
	name = "wooden chair"
	icon_state = "wooden_chair_toppled"
	inhand_icon_state = "woodenchair"
	resistance_flags = FLAMMABLE
	max_integrity = 40
	hitsound = 'sound/items/weapons/genhit1.ogg'
	origin_type = /obj/structure/chair/wood
	custom_materials = null
	daze_amount = 0

/obj/item/chair/wood/narsie_act()
	return

/obj/item/chair/wood/wings
	icon_state = "wooden_chair_wings_toppled"
	origin_type = /obj/structure/chair/wood/wings

/obj/structure/chair/old
	name = "strange chair"
	desc = "You sit in this. Either by will or force. Looks REALLY uncomfortable."
	icon_state = "chairold"
	item_chair = null
	fishing_modifier = 4

/obj/structure/chair/bronze
	name = "brass chair"
	desc = "A spinny chair made of bronze. It has little cogs for wheels!"
	anchored = FALSE
	icon_state = "brass_chair"
	buildstacktype = /obj/item/stack/sheet/bronze
	buildstackamount = 1
	item_chair = null
	fishing_modifier = -13 //the pinnacle of Ratvarian technology.
	has_armrest = TRUE
	/// Total rotations made
	var/turns = 0

/obj/structure/chair/bronze/Initialize(mapload)
	. = ..()
	AddElement(/datum/element/noisy_movement, 'sound/machines/clockcult/integration_cog_install.ogg', 50)

/obj/structure/chair/bronze/Destroy()
	STOP_PROCESSING(SSfastprocess, src)
	. = ..()

/obj/structure/chair/bronze/process()
	setDir(turn(dir,-90))
	playsound(src, 'sound/effects/servostep.ogg', 50, FALSE)
	turns++
	if(turns >= 8)
		STOP_PROCESSING(SSfastprocess, src)

/obj/structure/chair/bronze/MakeRotate()
	return

/obj/structure/chair/bronze/click_alt(mob/user)
	turns = 0
	if(!(datum_flags & DF_ISPROCESSING))
		user.visible_message(span_notice("[user] spins [src] around, and the last vestiges of Ratvarian technology keeps it spinning FOREVER."), \
		span_notice("Automated spinny chairs. The pinnacle of ancient Ratvarian technology."))
		START_PROCESSING(SSfastprocess, src)
	else
		user.visible_message(span_notice("[user] stops [src]'s uncontrollable spinning."), \
		span_notice("You grab [src] and stop its wild spinning."))
		STOP_PROCESSING(SSfastprocess, src)
	return CLICK_ACTION_SUCCESS

/obj/structure/chair/mime
	name = "invisible chair"
	desc = "The mime needs to sit down and shut up."
	anchored = FALSE
	icon_state = null
	buildstacktype = null
	item_chair = null
	obj_flags = parent_type::obj_flags | NO_DEBRIS_AFTER_DECONSTRUCTION
	alpha = 0
	fishing_modifier = -21 //it only lives for 25 seconds, so we make them worth it.

/obj/structure/chair/mime/wrench_act_secondary(mob/living/user, obj/item/weapon)
	return NONE

/obj/structure/chair/mime/post_buckle_mob(mob/living/M)
	M.add_offsets(type, z_add = 5)

/obj/structure/chair/mime/post_unbuckle_mob(mob/living/M)
	M.remove_offsets(type)

/obj/structure/chair/plastic
	icon_state = "plastic_chair"
	name = "folding plastic chair"
	desc = "No matter how much you squirm, it'll still be uncomfortable."
	resistance_flags = FLAMMABLE
	max_integrity = 70
	custom_materials = list(/datum/material/plastic =SHEET_MATERIAL_AMOUNT)
	buildstacktype = /obj/item/stack/sheet/plastic
	buildstackamount = 2
	item_chair = /obj/item/chair/plastic
	fishing_modifier = -10

/obj/structure/chair/plastic/post_buckle_mob(mob/living/Mob)
	Mob.add_offsets(type, z_add = 2)
	. = ..()
	if(iscarbon(Mob))
		INVOKE_ASYNC(src, PROC_REF(snap_check), Mob)

/obj/structure/chair/plastic/post_unbuckle_mob(mob/living/Mob)
	Mob.remove_offsets(type)

/obj/structure/chair/plastic/proc/snap_check(mob/living/carbon/Mob)
	if (Mob.nutrition >= NUTRITION_LEVEL_FAT)
		to_chat(Mob, span_warning("The chair begins to pop and crack, you're too heavy!"))
		if(do_after(Mob, 6 SECONDS, progress = FALSE))
			Mob.visible_message(span_notice("The plastic chair snaps under [Mob]'s weight!"))
			new /obj/effect/decal/cleanable/plastic(loc)
			qdel(src)

/obj/item/chair/plastic
	name = "folding plastic chair"
	desc = "Somehow, you can always find one under the wrestling ring."
	icon = 'icons/obj/chairs.dmi'
	icon_state = "folded_chair"
	inhand_icon_state = "folded_chair"
	lefthand_file = 'icons/mob/inhands/items/chairs_lefthand.dmi'
	righthand_file = 'icons/mob/inhands/items/chairs_righthand.dmi'
	w_class = WEIGHT_CLASS_NORMAL
	force = 7
	throw_range = 5 //Lighter Weight --> Flies Farther.
	custom_materials = list(/datum/material/plastic =SHEET_MATERIAL_AMOUNT)
	max_integrity = 70
	daze_amount = 0
	origin_type = /obj/structure/chair/plastic

/obj/structure/chair/musical
	name = "musical chair"
	desc = "You listen to this. Either by will or by force."
	item_chair = /obj/item/chair/musical
	particles = new /particles/musical_notes

/obj/item/chair/musical
	name = "musical chair"
	desc = "Oh, so this is like the fucked up Monopoly rules where there are no rules and you can pick up and place the musical chairs as you please."
	particles = new /particles/musical_notes
	origin_type = /obj/structure/chair/musical
