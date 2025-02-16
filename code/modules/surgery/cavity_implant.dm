/datum/surgery/cavity_implant
	name = "Cavity implant"
	possible_locs = list(BODY_ZONE_CHEST)
	steps = list(
		/datum/surgery_step/incise,
		/datum/surgery_step/retract_skin,
		/datum/surgery_step/clamp_bleeders,
		/datum/surgery_step/incise,
		/datum/surgery_step/handle_cavity,
		/datum/surgery_step/close)

GLOBAL_LIST_INIT(heavy_cavity_implants, typecacheof(list(/obj/item/transfer_valve)))

//handle cavity
/datum/surgery_step/handle_cavity
	name = "implant item"
	accept_hand = 1
	implements = list(/obj/item = 100)
	repeatable = TRUE
	time = 32
	preop_sound = 'sound/items/handling/surgery/organ1.ogg'
	success_sound = 'sound/items/handling/surgery/organ2.ogg'
	var/obj/item/item_for_cavity

/datum/surgery_step/handle_cavity/tool_check(mob/user, obj/item/tool)
	if(tool.tool_behaviour == TOOL_CAUTERY || istype(tool, /obj/item/gun/energy/laser))
		return FALSE
	return !tool.get_temperature()

/datum/surgery_step/handle_cavity/preop(mob/user, mob/living/carbon/human/target, target_zone, obj/item/tool, datum/surgery/surgery)
	var/obj/item/bodypart/chest/target_chest = target.get_bodypart(BODY_ZONE_CHEST)
	item_for_cavity = target_chest.cavity_item
	if(tool)
		display_results(
			user,
			target,
			span_notice("You begin to insert [tool] into [target]'s [target_zone]..."),
			span_notice("[user] begins to insert [tool] into [target]'s [target_zone]."),
			span_notice("[user] begins to insert [tool.w_class > WEIGHT_CLASS_SMALL ? tool : "something"] into [target]'s [target_zone]."),
		)
		display_pain(target, "You can feel something being inserted into your [target_zone], it hurts like hell!")
		return

	display_results(
		user,
		target,
		span_notice("You check for items in [target]'s [target_zone]..."),
		span_notice("[user] checks for items in [target]'s [target_zone]."),
		span_notice("[user] looks for something in [target]'s [target_zone]."),
	)

/datum/surgery_step/handle_cavity/success(mob/user, mob/living/carbon/human/target, target_zone, obj/item/tool, datum/surgery/surgery = FALSE)
	var/obj/item/bodypart/chest/target_chest = target.get_bodypart(BODY_ZONE_CHEST)
	if(tool)
		if(item_for_cavity || ((tool.w_class > WEIGHT_CLASS_NORMAL) && !is_type_in_typecache(tool, GLOB.heavy_cavity_implants)) || HAS_TRAIT(tool, TRAIT_NODROP) || (tool.item_flags & ABSTRACT) || isorgan(tool))
			to_chat(user, span_warning("You can't seem to fit [tool] in [target]'s [target_zone]!"))
			return FALSE

		display_results(
			user,
			target,
			span_notice("You stuff [tool] into [target]'s [target_zone]."),
			span_notice("[user] stuffs [tool] into [target]'s [target_zone]!"),
			span_notice("[user] stuffs [tool.w_class > WEIGHT_CLASS_SMALL ? tool : "something"] into [target]'s [target_zone]."),
		)

		if (!user.transferItemToLoc(tool, target, TRUE))
			return FALSE

		target_chest.cavity_item = tool
		return ..()

	if(!item_for_cavity)
		to_chat(user, span_warning("You don't find anything in [target]'s [target_zone]."))
		return FALSE

	display_results(
		user,
		target,
		span_notice("You pull [item_for_cavity] out of [target]'s [target_zone]."),
		span_notice("[user] pulls [item_for_cavity] out of [target]'s [target_zone]!"),
		span_notice("[user] pulls [item_for_cavity.w_class > WEIGHT_CLASS_SMALL ? item_for_cavity : "something"] out of [target]'s [target_zone]."),
	)
	display_pain(target, "Something is pulled out of your [target_zone]! It hurts like hell!")
	user.put_in_hands(item_for_cavity)
	target_chest.cavity_item = null
	return ..()
