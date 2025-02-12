#define FISHING_ROD_REEL_CAST_RANGE 2

/obj/item/fishing_rod
	name = "fishing rod"
	desc = "You can fish with this."
	icon = 'icons/obj/fishing.dmi'
	icon_state = "fishing_rod"
	icon_angle = -45
	lefthand_file = 'icons/mob/inhands/equipment/fishing_rod_lefthand.dmi'
	righthand_file = 'icons/mob/inhands/equipment/fishing_rod_righthand.dmi'
	inhand_icon_state = "rod"
	inhand_x_dimension = 64
	inhand_y_dimension = 64
	force = 8
	w_class = WEIGHT_CLASS_HUGE

	/// How far can you cast this
	var/cast_range = 3
	/// Fishing minigame difficulty modifier (additive)
	var/difficulty_modifier = 0
	/// Explaination of rod functionality shown in the ui and the autowiki
	var/ui_description = "A classic fishing rod, with no special qualities."
	/// More explaination shown in the wiki after ui_description
	var/wiki_description = ""
	/// Is this fishing rod shown in the wiki
	var/show_in_wiki = TRUE

	var/obj/item/bait
	var/obj/item/fishing_line/line = /obj/item/fishing_line
	var/obj/item/fishing_hook/hook = /obj/item/fishing_hook

	/// Currently hooked item for item reeling
	var/atom/movable/currently_hooked

	/// Fishing line visual for the hooked item
	var/datum/beam/fishing_line/fishing_line

	/// Are we currently casting
	var/casting = FALSE

	/// The default color for the reel overlay if no line is equipped.
	var/default_line_color = "gray"

	/// Is this currently being used by the profound fisher component?
	var/internal = FALSE

	/// The name of the icon state of the reel overlay
	var/reel_overlay = "reel_overlay"

	/// Icon state of the frame overlay this rod uses for the minigame
	var/frame_state = "frame_wood"

	/**
	 * A list with two keys delimiting the spinning interval in which a mouse click has to be pressed while fishing.
	 * Inherited from baits, passed down to the minigame lure.
	 */
	var/list/spin_frequency

	///Prevents spamming the line casting, without affecting the player's click cooldown.
	COOLDOWN_DECLARE(casting_cd)

	///The chance of catching fish made of the same material of the fishing rod (if MATERIAL_EFFECTS is enabled)
	var/material_fish_chance = 10
	///The multiplier of how much experience is gained when fishing with this rod.
	var/experience_multiplier = 1
	///The multiplier of the completion gain during the minigame
	var/completion_speed_mult = 1
	///The multiplier of the speed of the bobber/bait during the minigame
	var/bait_speed_mult = 1
	///The multiplier of the decelaration during the minigame
	var/deceleration_mult = 1
	///The multiplier of the bounciness of the bobber/bait upon hitting the edges of the minigame area
	var/bounciness_mult = 1
	/// The multiplier of negative velocity that pulls the bait/bobber down when not holding the click
	var/gravity_mult = 1
	/**
	 * The multiplier of the bait height. Influenced by the strength_modifier of a material,
	 * unlike the other variables, lest we add too many vars to materials.
	 * Also materials with a strength_modifier lower than 1 don't do anything, since
	 * they're already likely to be quite bad
	 */
	var/bait_height_mult = 1

/obj/item/fishing_rod/Initialize(mapload)
	. = ..()
	register_context()
	register_item_context()

	if(ispath(bait))
		set_slot(new bait(src), ROD_SLOT_BAIT)
	if(ispath(hook))
		set_slot(new hook(src), ROD_SLOT_HOOK)
	if(ispath(line))
		set_slot(new line(src), ROD_SLOT_LINE)

	update_appearance()

	//Bane effect that make it extra-effective against mobs with water adaptation (read: fish infusion)
	AddElement(/datum/element/bane, target_type = /mob/living, damage_multiplier = 1.25)
	RegisterSignal(src, COMSIG_OBJECT_PRE_BANING, PROC_REF(attempt_bane))
	RegisterSignal(src, COMSIG_OBJECT_ON_BANING, PROC_REF(bane_effects))

/obj/item/fishing_rod/add_context(atom/source, list/context, obj/item/held_item, mob/user)
	if(src == held_item)
		if(currently_hooked)
			context[SCREENTIP_CONTEXT_LMB] = "Reel in"
		context[SCREENTIP_CONTEXT_RMB] = "Modify"
		return CONTEXTUAL_SCREENTIP_SET
	return NONE

/obj/item/fishing_rod/add_item_context(obj/item/source, list/context, atom/target, mob/living/user)
	. = ..()
	var/gone_fishing = GLOB.fishing_challenges_by_user[user]
	if(currently_hooked || gone_fishing)
		context[SCREENTIP_CONTEXT_LMB] = (gone_fishing && spin_frequency) ? "Spin" : "Reel in"
		if(!gone_fishing)
			context[SCREENTIP_CONTEXT_RMB] = "Unhook"
		return CONTEXTUAL_SCREENTIP_SET
	return NONE

/obj/item/fishing_rod/examine(mob/user)
	. = ..()
	var/list/equipped_stuff = list()
	if(line)
		equipped_stuff += "[icon2html(line, user)] <b>[line.name]</b>"
	if(hook)
		equipped_stuff += "[icon2html(hook, user)] <b>[hook.name]</b>"
	if(bait)
		equipped_stuff += "[icon2html(bait, user)] <b>[bait]</b>"
	if(length(equipped_stuff))
		. += span_notice("It has \a [english_list(equipped_stuff)] equipped.")
	if(!bait)
		. += span_warning("It doesn't have a bait attached to it. Fishing will be more tedious!")
	if(HAS_MIND_TRAIT(user, TRAIT_EXAMINE_FISH))
		. += "" //add a new line
		. += span_notice("Thanks to your fishing skills, you can examine it again for more in-depth information.")
		return
	if(HAS_TRAIT(src, TRAIT_ROD_MANSUS_INFUSED))
		if(IS_HERETIC(user))
			. += span_purple("This rod has been <b>infused</b> by a heretic, improving its ability to catch glimpses of the Mansus. And fish.")
		else
			. += span_purple("It's glowing an eerie purple...")
	else if(IS_HERETIC(user))
		. += span_purple("As a Heretic, you can infuse this fishing rod with your <b>Mansus Grasp</b> by activating the spell while wielding it, to enhance its fishing power.")

/obj/item/fishing_rod/examine_more(mob/user)
	. = ..()
	if(!HAS_MIND_TRAIT(user, TRAIT_EXAMINE_FISH))
		return

	var/list/block = list()
	var/get_percent = HAS_MIND_TRAIT(user, TRAIT_EXAMINE_DEEPER_FISH)
	block += span_info("You think you can cast it up to [get_cast_range()] tiles away.")
	block += get_stat_info(get_percent, difficulty_modifier * 0.01, "Fishing will be", "easier", "harder", "with this fishing rod", offset = 0)
	block += get_stat_info(get_percent, experience_multiplier, "You will gain experience", "faster", "slower")
	block += get_stat_info(get_percent, completion_speed_mult, "You should complete the minigame", "faster", "slower")
	block += get_stat_info(get_percent, bait_speed_mult, "Reeling is", "faster", "slower")
	block += get_stat_info(get_percent, deceleration_mult, "Deceleration is", "faster", "slower", less_is_better = TRUE)
	block += get_stat_info(get_percent, bounciness_mult, "This fishing rod is ", "bouncier", "less bouncy", "than a normal one", less_is_better = TRUE)
	block += get_stat_info(get_percent, gravity_mult, "The lure will sink", "faster", "slower", span_info = TRUE)

	list_clear_nulls(block)
	. += boxed_message(block.Join("\n"))

	if(get_percent && (material_flags & MATERIAL_EFFECTS) && length(custom_materials))
		block = list()
		block += span_info("Right now, fish caught by this fishing rod have a [get_material_fish_chance(user)]% of being made of its same materials.")
		var/datum/material/material = get_master_material()
		if(material.fish_weight_modifier != 1)
			var/heavier = material.fish_weight_modifier > 1 ? "heavier" : "lighter"
			block += span_info("Fish made of the same material as this rod tend to be [abs(material.fish_weight_modifier - 1) * 100]% [heavier].")
		. += boxed_message(block.Join("\n"))

	block = list()
	if(HAS_TRAIT(src, TRAIT_ROD_ATTRACT_SHINY_LOVERS))
		block += span_info("This fishing rod will attract shiny-loving fish.")
	if(HAS_TRAIT(src, TRAIT_ROD_IGNORE_ENVIRONMENT))
		block += span_info("Environment and light shouldn't be an issue with this rod.")
	if(HAS_TRAIT_NOT_FROM(src, TRAIT_ROD_REMOVE_FISHING_DUD, INNATE_TRAIT)) // Duds are innately removed by baits, we all know that.
		block += span_info("You won't catch duds with this rod.")
	if(HAS_TRAIT(src, TRAIT_ROD_LAVA_USABLE))
		block += span_info("This fishing rod can be used to fish on lava.")
	if(length(block))
		. += boxed_message(block.Join("\n"))

///Used in examine_more to reduce all the copypasta when getting more information about the various stats of the fishing rod.
/obj/item/fishing_rod/proc/get_stat_info(get_percent, value, prefix, easier, harder, suffix = "with this fishing rod", span_info = FALSE, less_is_better = FALSE, offset = 1)
	if(value == 1)
		return
	value -= offset
	var/percent = get_percent ? "[abs(value * 100)]% " : ""
	var/harder_easier = value > 0 ? easier : harder
	. = "[prefix] [percent][harder_easier] [suffix]."
	if(span_info)
		return span_info(.)
	if(less_is_better ? value < 0 : value > 0)
		return span_nicegreen(.)
	return span_danger(.)

/obj/item/fishing_rod/apply_single_mat_effect(datum/material/custom_material, amount, multiplier)
	. = ..()
	difficulty_modifier += custom_material.fishing_difficulty_modifier * multiplier
	cast_range += custom_material.fishing_cast_range * multiplier
	experience_multiplier *= GET_MATERIAL_MODIFIER(custom_material.fishing_experience_multiplier, multiplier)
	completion_speed_mult *= GET_MATERIAL_MODIFIER(custom_material.fishing_completion_speed, multiplier)
	bait_speed_mult *= GET_MATERIAL_MODIFIER(custom_material.fishing_bait_speed_mult, multiplier)
	deceleration_mult *= GET_MATERIAL_MODIFIER(custom_material.fishing_deceleration_mult, multiplier)
	bounciness_mult *= GET_MATERIAL_MODIFIER(custom_material.fishing_bounciness_mult, multiplier)
	gravity_mult *= GET_MATERIAL_MODIFIER(custom_material.fishing_gravity_mult, multiplier)
	var/height_mod = GET_MATERIAL_MODIFIER(custom_material.strength_modifier, multiplier)
	if(height_mod > 1)
		bait_height_mult *= height_mod**0.75


/obj/item/fishing_rod/remove_single_mat_effect(datum/material/custom_material, amount, multiplier)
	. = ..()
	difficulty_modifier -= custom_material.fishing_difficulty_modifier * multiplier
	cast_range -= custom_material.fishing_cast_range * multiplier
	experience_multiplier /= GET_MATERIAL_MODIFIER(custom_material.fishing_experience_multiplier, multiplier)
	completion_speed_mult /= GET_MATERIAL_MODIFIER(custom_material.fishing_completion_speed, multiplier)
	bait_speed_mult /= GET_MATERIAL_MODIFIER(custom_material.fishing_bait_speed_mult, multiplier)
	deceleration_mult /= GET_MATERIAL_MODIFIER(custom_material.fishing_deceleration_mult, multiplier)
	bounciness_mult /= GET_MATERIAL_MODIFIER(custom_material.fishing_bounciness_mult, multiplier)
	gravity_mult /= GET_MATERIAL_MODIFIER(custom_material.fishing_gravity_mult, multiplier)
	var/height_mod = GET_MATERIAL_MODIFIER(custom_material.strength_modifier, multiplier)
	if(height_mod > 1)
		bait_height_mult *= 1/(height_mod**0.75)

/**
 * Is there a reason why this fishing rod couldn't fish in target_fish_source?
 * If so, return the denial reason as a string, otherwise return `null`.
 *
 * Arguments:
 * * target_fish_source - The /datum/fish_source we're trying to fish in.
 */
/obj/item/fishing_rod/proc/reason_we_cant_fish(datum/fish_source/target_fish_source)
	return hook?.reason_we_cant_fish(target_fish_source)

///Called at the end of on_challenge_completed() once the reward has been spawned
/obj/item/fishing_rod/proc/on_reward_caught(atom/movable/reward, mob/user)
	if(isnull(reward))
		return
	var/isfish = isfish(reward)
	if((material_flags & MATERIAL_EFFECTS) && isfish && length(custom_materials))
		if(prob(get_material_fish_chance(user)))
			var/obj/item/fish/fish = reward
			var/datum/material/material = get_master_material()
			fish.set_custom_materials(list(material.type = fish.weight))
	// catching things that aren't fish or alive mobs doesn't consume baits.
	if(isnull(bait) || HAS_TRAIT(bait, TRAIT_BAIT_UNCONSUMABLE))
		return
	if(isliving(reward))
		var/mob/living/caught_mob = reward
		if(caught_mob.stat == DEAD)
			return
	else
		if(!isfish)
			return
		var/obj/item/fish/fish = reward
		if(HAS_TRAIT(bait, TRAIT_POISONOUS_BAIT) && !HAS_TRAIT(fish, TRAIT_FISH_TOXIN_IMMUNE))
			var/kill_fish = TRUE
			for(var/bait_identifer in fish.favorite_bait)
				if(is_matching_bait(bait, bait_identifer))
					kill_fish = FALSE
					break
			if(kill_fish)
				fish.set_status(FISH_DEAD, silent = TRUE)

	qdel(bait)
	update_icon()

///Returns the probability that a fish caught by this (custom material) rod will be of the same material.
/obj/item/fishing_rod/proc/get_material_fish_chance(mob/user)
	var/material_chance = material_fish_chance
	if(bait)
		if(HAS_TRAIT(bait, TRAIT_GREAT_QUALITY_BAIT))
			material_chance += 16
		else if(HAS_TRAIT(bait, TRAIT_GOOD_QUALITY_BAIT))
			material_chance += 8
		else if(HAS_TRAIT(bait, TRAIT_BASIC_QUALITY_BAIT))
			material_chance += 4
	material_chance += user.mind?.get_skill_level(/datum/skill/fishing) * 1.5
	return material_chance

///Fishing rodss should only bane fish DNA-infused spessman
/obj/item/fishing_rod/proc/attempt_bane(datum/source, mob/living/fish)
	SIGNAL_HANDLER
	if(!force || !HAS_TRAIT(fish, TRAIT_WATER_ADAPTATION))
		return COMPONENT_CANCEL_BANING

///Fishing rods should hard-counter fish DNA-infused spessman
/obj/item/fishing_rod/proc/bane_effects(datum/source, mob/living/fish)
	SIGNAL_HANDLER
	fish.adjust_staggered_up_to(STAGGERED_SLOWDOWN_LENGTH, 4 SECONDS)
	fish.adjust_confusion_up_to(1.5 SECONDS, 3 SECONDS)
	fish.adjust_wet_stacks(-4)

/obj/item/fishing_rod/interact(mob/user)
	if(currently_hooked)
		reel(user)

/obj/item/fishing_rod/proc/reel(mob/user)
	if(DOING_INTERACTION_WITH_TARGET(user, currently_hooked))
		return

	playsound(src, SFX_REEL, 50, vary = FALSE)
	var/time = (0.8 - round(user.mind?.get_skill_level(/datum/skill/fishing) * 0.04, 0.1)) SECONDS * bait_speed_mult
	if(!do_after(user, time, currently_hooked, timed_action_flags = IGNORE_USER_LOC_CHANGE|IGNORE_TARGET_LOC_CHANGE, extra_checks = CALLBACK(src, PROC_REF(fishing_line_check))))
		return

	if(currently_hooked.anchored || currently_hooked.move_resist >= MOVE_FORCE_STRONG)
		balloon_alert(user, "[currently_hooked.p_they()] won't budge!")
		return

	//About thirty minutes of non-stop reeling to get from zero to master... not worth it but hey, you do what you do.
	user.mind?.adjust_experience(/datum/skill/fishing, time * 0.13 * experience_multiplier)

	//Try to move it 'till it's under the user's feet, then try to pick it up
	if(isitem(currently_hooked))
		var/obj/item/item = currently_hooked
		step_towards(item, get_turf(src))
		if(item.loc == user.loc && (item.interaction_flags_item & INTERACT_ITEM_ATTACK_HAND_PICKUP))
			user.put_in_inactive_hand(item)
			QDEL_NULL(fishing_line)
	//Not an item, so just delete the line if it's adjacent to the user.
	else if(get_dist(currently_hooked,get_turf(src)) > 1)
		step_towards(currently_hooked, get_turf(src))
		if(get_dist(currently_hooked,get_turf(src)) <= 1)
			QDEL_NULL(fishing_line)
	else
		QDEL_NULL(fishing_line)

/obj/item/fishing_rod/proc/fishing_line_check()
	return !QDELETED(fishing_line)

/obj/item/fishing_rod/attack_self_secondary(mob/user, modifiers)
	. = ..()
	ui_interact(user)

/// Generates the fishing line visual from the current user to the target and updates inhands
/obj/item/fishing_rod/proc/create_fishing_line(atom/movable/target, mob/living/firer, target_py = null)
	if(internal)
		return null
	if(fishing_line)
		QDEL_NULL(fishing_line)
	var/beam_color = line?.line_color || default_line_color
	fishing_line = new(firer, target, icon_state = "fishing_line", beam_color = beam_color, emissive = FALSE, override_target_pixel_y = target_py)
	fishing_line.lefthand = IS_LEFT_INDEX(firer.get_held_index_of_item(src))
	RegisterSignal(fishing_line, COMSIG_BEAM_BEFORE_DRAW, PROC_REF(check_los))
	RegisterSignal(fishing_line, COMSIG_QDELETING, PROC_REF(clear_line))
	INVOKE_ASYNC(fishing_line, TYPE_PROC_REF(/datum/beam/, Start))
	if(QDELETED(fishing_line))
		return null
	firer.update_held_items()
	return fishing_line

/obj/item/fishing_rod/proc/clear_line(datum/source)
	SIGNAL_HANDLER
	if(ismob(loc))
		var/mob/user = loc
		user.update_held_items()
	fishing_line = null
	currently_hooked = null

/obj/item/fishing_rod/proc/get_cast_range(mob/living/user)
	. = max(cast_range, 1)
	user = user || loc
	if (!isliving(user) || !user.mind || !user.is_holding(src))
		return
	. += round(user.mind.get_skill_level(/datum/skill/fishing) * 0.3)
	return max(., 1)

/obj/item/fishing_rod/dropped(mob/user, silent)
	. = ..()
	QDEL_NULL(fishing_line)

/// Hooks the item
/obj/item/fishing_rod/proc/hook_item(mob/user, atom/target_atom)
	if(currently_hooked)
		return
	if(!hook.can_be_hooked(target_atom))
		return
	currently_hooked = target_atom
	create_fishing_line(target_atom, user)
	hook.hook_attached(target_atom, src)
	SEND_SIGNAL(src, COMSIG_FISHING_ROD_HOOKED_ITEM, target_atom, user)

// Checks fishing line for interruptions and range
/obj/item/fishing_rod/proc/check_los(datum/beam/source)
	SIGNAL_HANDLER
	. = NONE

	if(!CheckToolReach(src, source.target, get_cast_range()))
		qdel(source)
		return BEAM_CANCEL_DRAW

/obj/item/fishing_rod/interact_with_atom(atom/interacting_with, mob/living/user, list/modifiers)
	//this prevent trying to use telekinesis to fish (which would be broken anyway), also whacking people with a rod.
	if(!user.contains(src) || (user.combat_mode && !isturf(interacting_with)) ||HAS_TRAIT(interacting_with, TRAIT_COMBAT_MODE_SKIP_INTERACTION))
		return ..()
	return ranged_interact_with_atom(interacting_with, user, modifiers)

/obj/item/fishing_rod/ranged_interact_with_atom(atom/interacting_with, mob/living/user, list/modifiers)
	if(!hook)
		balloon_alert(user, "install a hook first!")
		return ITEM_INTERACT_BLOCKING

	// Reel in if able
	if(currently_hooked)
		reel(user)
		return ITEM_INTERACT_BLOCKING

	cast_line(interacting_with, user)
	return ITEM_INTERACT_SUCCESS

/obj/item/fishing_rod/interact_with_atom_secondary(atom/interacting_with, mob/living/user, list/modifiers)
	return ranged_interact_with_atom_secondary(interacting_with, user, modifiers)

/obj/item/fishing_rod/ranged_interact_with_atom_secondary(atom/interacting_with, mob/living/user, list/modifiers)
	//Stop reeling, delete the fishing line
	if(currently_hooked)
		QDEL_NULL(fishing_line)
		return ITEM_INTERACT_BLOCKING
	return ..()

/// If the line to whatever that is is clear and we're not already busy, try fishing in it
/obj/item/fishing_rod/proc/cast_line(atom/target, mob/user)
	if(casting || currently_hooked)
		return
	if(!hook)
		balloon_alert(user, "install a hook first!")
		return
	if(!COOLDOWN_FINISHED(src, casting_cd))
		return
	COOLDOWN_START(src, casting_cd, 1 SECONDS)
	// skip firing a projectile if the target is adjacent and can be reached (no order windows in the way),
	// otherwise it may end up hitting other things on its turf, which is problematic
	// especially for entities with the profound fisher component, which should only work on
	// proper fishing spots.
	if(user.CanReach(target, src))
		hook_hit(target, user)
		return
	casting = TRUE
	var/obj/projectile/fishing_cast/cast_projectile = new(get_turf(src))
	cast_projectile.range = get_cast_range(user)
	cast_projectile.maximum_range = get_cast_range(user)
	cast_projectile.owner = src
	cast_projectile.original = target
	cast_projectile.fired_from = src
	cast_projectile.firer = user
	cast_projectile.impacted = list(WEAKREF(user) = TRUE)
	cast_projectile.aim_projectile(target, user)
	cast_projectile.fire()

/// Called by hook projectile when hitting things
/obj/item/fishing_rod/proc/hook_hit(atom/atom_hit_by_hook_projectile, mob/user)
	if(!hook)
		return
	if(SEND_SIGNAL(atom_hit_by_hook_projectile, COMSIG_FISHING_ROD_CAST, src, user) & FISHING_ROD_CAST_HANDLED)
		return
	/// If you can't fish in it, try hooking it
	hook_item(user, atom_hit_by_hook_projectile)

/obj/item/fishing_rod/ui_interact(mob/user, datum/tgui/ui)
	ui = SStgui.try_update_ui(user, src, ui)
	if(!ui)
		ui = new(user, src, "FishingRod", name)
		ui.set_autoupdate(FALSE)
		ui.open()

/obj/item/fishing_rod/ui_state()
	if(internal)
		return GLOB.deep_inventory_state
	else
		return GLOB.default_state

/obj/item/fishing_rod/update_overlays()
	. = ..()
	. += get_fishing_overlays()

/obj/item/fishing_rod/proc/get_fishing_overlays()
	. = list()
	var/line_color = line?.line_color || default_line_color
	/// Line part by the rod.
	if(reel_overlay)
		var/mutable_appearance/reel_appearance = mutable_appearance(icon, reel_overlay)
		reel_appearance.appearance_flags = RESET_COLOR
		reel_appearance.color = line_color
		. += reel_appearance

	// Line & hook is also visible when only bait is equipped but it uses default appearances then
	if(hook || bait)
		var/mutable_appearance/line_overlay = mutable_appearance(icon, "line_overlay")
		line_overlay.appearance_flags = RESET_COLOR
		line_overlay.color = line_color
		. += line_overlay
		. += hook?.rod_overlay_icon_state || "hook_overlay"

	if(bait)
		var/bait_state = "worm_overlay" //default to worm overlay for anything without specific one
		if(istype(bait, /obj/item/food/bait))
			var/obj/item/food/bait/real_bait = bait
			bait_state = real_bait.rod_overlay_icon_state
		if(istype(bait, /obj/item/stock_parts/power_store/cell/lead))
			bait_state = "battery_overlay"
		. += bait_state

/obj/item/fishing_rod/worn_overlays(mutable_appearance/standing, isinhands, icon_file)
	. = ..()
	. += get_fishing_worn_overlays(standing, isinhands, icon_file)

/obj/item/fishing_rod/proc/get_fishing_worn_overlays(mutable_appearance/standing, isinhands, icon_file)
	. = list()
	var/line_color = line?.line_color || default_line_color
	var/mutable_appearance/reel_overlay = mutable_appearance(icon_file, "reel_overlay")
	reel_overlay.appearance_flags |= RESET_COLOR
	reel_overlay.color = line_color
	. += reel_overlay
	/// if we don't have anything hooked show the dangling hook & line
	if(isinhands && !fishing_line)
		var/mutable_appearance/line_overlay = mutable_appearance(icon_file, "line_overlay")
		line_overlay.appearance_flags |= RESET_COLOR
		line_overlay.color = line_color
		. += line_overlay
		. += mutable_appearance(icon_file, "hook_overlay")

/obj/item/fishing_rod/attackby(obj/item/attacking_item, mob/user, params)
	if(slot_check(attacking_item,ROD_SLOT_LINE))
		use_slot(ROD_SLOT_LINE, user, attacking_item)
		SStgui.update_uis(src)
		return TRUE
	else if(slot_check(attacking_item,ROD_SLOT_HOOK))
		use_slot(ROD_SLOT_HOOK, user, attacking_item)
		SStgui.update_uis(src)
		return TRUE
	else if(slot_check(attacking_item,ROD_SLOT_BAIT))
		use_slot(ROD_SLOT_BAIT, user, attacking_item)
		SStgui.update_uis(src)
		return TRUE
	else if(istype(attacking_item, /obj/item/bait_can)) //Quicker filling from bait can
		var/obj/item/bait_can/can = attacking_item
		var/bait = can.retrieve_bait(user)
		if(bait)
			use_slot(ROD_SLOT_BAIT, user, bait)
			SStgui.update_uis(src)
		return TRUE
	. = ..()

/obj/item/fishing_rod/ui_data(mob/user)
	. = ..()
	var/list/data = list()

	data["bait_name"] = format_text(bait?.name)
	data["bait_icon"] = bait != null ? icon2base64(icon(bait.icon, bait.icon_state)) : null

	data["line_name"] = format_text(line?.name)
	data["line_icon"] = line != null ? icon2base64(icon(line.icon, line.icon_state)) : null

	data["hook_name"] = format_text(hook?.name)
	data["hook_icon"] = hook != null ? icon2base64(icon(hook.icon, hook.icon_state)) : null

	data["busy"] = fishing_line

	data["description"] = ui_description

	return data

/// Checks if the item fits the slot
/obj/item/fishing_rod/proc/slot_check(obj/item/item,slot)
	if(!istype(item))
		return FALSE
	switch(slot)
		if(ROD_SLOT_HOOK)
			if(!istype(item,/obj/item/fishing_hook))
				return FALSE
		if(ROD_SLOT_LINE)
			if(!istype(item,/obj/item/fishing_line))
				return FALSE
		if(ROD_SLOT_BAIT)
			if(!HAS_TRAIT(item, TRAIT_FISHING_BAIT))
				return FALSE
	return TRUE

/obj/item/fishing_rod/ui_act(action, list/params, datum/tgui/ui, datum/ui_state/state)
	. = ..()
	if(.)
		return .
	var/mob/user = usr
	switch(action)
		if("slot_action")
			// Simple click with empty hand to remove, click with item to insert/switch
			var/obj/item/held_item = user.get_active_held_item()
			use_slot(params["slot"], user, held_item == src ? null : held_item)
			return TRUE

/// Ideally this will be replaced with generic slotted storage datum + display
/obj/item/fishing_rod/proc/use_slot(slot, mob/user, obj/item/new_item)
	if(fishing_line || GLOB.fishing_challenges_by_user[user])
		return
	var/obj/item/current_item
	switch(slot)
		if(ROD_SLOT_BAIT)
			current_item = bait
		if(ROD_SLOT_HOOK)
			current_item = hook
		if(ROD_SLOT_LINE)
			current_item = line
	if(!new_item && !current_item)
		return
	// Trying to remove the item
	if(!new_item && current_item)
		user.put_in_hands(current_item)
		balloon_alert(user, "[slot] removed")
	// Trying to insert item into empty slot
	else if(new_item && !current_item)
		if(!slot_check(new_item, slot))
			return
		if(user.transferItemToLoc(new_item,src))
			set_slot(new_item, slot)
			balloon_alert(user, "[slot] installed")
		else
			balloon_alert(user, "stuck to your hands!")
			return
	/// Trying to swap item
	else if(new_item && current_item)
		if(!slot_check(new_item,slot))
			return
		if(user.transferItemToLoc(new_item, src))
			user.put_in_hands(current_item)
			set_slot(new_item, slot)
			balloon_alert(user, "[slot] swapped")
		else
			balloon_alert(user, "stuck to your hands!")
			return

	update_icon()
	playsound(src, 'sound/items/click.ogg', 50, TRUE)

///assign an item to the given slot and its standard effects, while Exited() should handle unsetting the slot.
/obj/item/fishing_rod/proc/set_slot(obj/item/equipment, slot)
	switch(slot)
		if(ROD_SLOT_BAIT)
			bait = equipment
			if(!HAS_TRAIT(bait, TRAIT_BAIT_ALLOW_FISHING_DUD))
				ADD_TRAIT(src, TRAIT_ROD_REMOVE_FISHING_DUD, INNATE_TRAIT)
		if(ROD_SLOT_HOOK)
			hook = equipment
		if(ROD_SLOT_LINE)
			line = equipment
			cast_range += FISHING_ROD_REEL_CAST_RANGE
		else
			CRASH("set_slot called with an undefined slot: [slot]")

	SEND_SIGNAL(equipment, COMSIG_ITEM_FISHING_ROD_SLOTTED, src, slot)

/obj/item/fishing_rod/Exited(atom/movable/gone, direction)
	. = ..()
	var/slot
	if(gone == bait)
		slot = ROD_SLOT_BAIT
		bait = null
		REMOVE_TRAIT(src, TRAIT_ROD_REMOVE_FISHING_DUD, INNATE_TRAIT)
	if(gone == line)
		slot = ROD_SLOT_LINE
		cast_range -= FISHING_ROD_REEL_CAST_RANGE
		line = null
	if(gone == hook)
		slot = ROD_SLOT_HOOK
		QDEL_NULL(fishing_line)
		hook = null

	if(slot)
		SEND_SIGNAL(gone, COMSIG_ITEM_FISHING_ROD_UNSLOTTED, src, slot)

/obj/item/fishing_rod/proc/get_frame(datum/fishing_challenge/challenge)
	return mutable_appearance('icons/hud/fishing_hud.dmi', frame_state)

///Found in the fishing toolbox (the hook and line are separate items)
/obj/item/fishing_rod/unslotted
	hook = null
	line = null
	show_in_wiki = FALSE

///From the mining order console, meant to help miners rescue their fallen brethren
/obj/item/fishing_rod/rescue
	hook = /obj/item/fishing_hook/rescue
	show_in_wiki = FALSE

/obj/item/fishing_rod/bone
	name = "bone fishing rod"
	desc = "A humble rod, made with whatever happened to be on hand."
	ui_description = "A fishing rod crafted with leather, sinew and bones."
	icon_state = "fishing_rod_bone"
	reel_overlay = "reel_bone"
	default_line_color = "red"
	frame_state = "frame_bone"
	line = null //sinew line (usable to fish in lava) not included
	hook = /obj/item/fishing_hook/bone

/obj/item/fishing_rod/telescopic
	name = "telescopic fishing rod"
	icon_state = "fishing_rod_telescopic"
	desc = "A lightweight, ergonomic, easy to store telescopic fishing rod. "
	inhand_icon_state = null
	custom_price = PAYCHECK_CREW * 9
	force = 0
	w_class = WEIGHT_CLASS_NORMAL
	ui_description = "A collapsible fishing rod that can fit within a backpack."
	wiki_description = "<b>It has to be bought from Cargo</b>."
	reel_overlay = "reel_telescopic"
	frame_state = "frame_telescopic"
	completion_speed_mult = 1.1
	bait_speed_mult = 1.1
	deceleration_mult = 1.1
	bounciness_mult = 0.9
	gravity_mult = 0.9
	///The force of the item when extended.
	var/active_force = 8

/obj/item/fishing_rod/telescopic/Initialize(mapload)
	. = ..()
	AddComponent(/datum/component/transforming, force_on = 8, hitsound_on = hitsound, w_class_on = WEIGHT_CLASS_HUGE, clumsy_check = FALSE)
	RegisterSignal(src, COMSIG_TRANSFORMING_PRE_TRANSFORM, PROC_REF(pre_transform))
	RegisterSignal(src, COMSIG_TRANSFORMING_ON_TRANSFORM, PROC_REF(on_transform))

/obj/item/fishing_rod/telescopic/reason_we_cant_fish(datum/fish_source/target_fish_source)
	if(!HAS_TRAIT(src, TRAIT_TRANSFORM_ACTIVE))
		return "You need to extend your fishing rod before you can cast the line."
	return ..()

/obj/item/fishing_rod/telescopic/cast_line(atom/target, mob/user, proximity_flag)
	if(!HAS_TRAIT(src, TRAIT_TRANSFORM_ACTIVE))
		if(!proximity_flag)
			balloon_alert(user, "extend the rod first!")
		return
	return ..()

/obj/item/fishing_rod/telescopic/get_fishing_overlays()
	if(!HAS_TRAIT(src, TRAIT_TRANSFORM_ACTIVE))
		return list()
	return ..()

/obj/item/fishing_rod/telescopic/get_fishing_worn_overlays(mutable_appearance/standing, isinhands, icon_file)
	if(!HAS_TRAIT(src, TRAIT_TRANSFORM_ACTIVE))
		return list()
	return ..()

///Stops the fishing rod from being collapsed while fishing.
/obj/item/fishing_rod/telescopic/proc/pre_transform(obj/item/source, mob/user, active)
	SIGNAL_HANDLER
	if(HAS_TRAIT(src, TRAIT_TRANSFORM_ACTIVE))
		return
	//the fishing minigame uses the attack_self signal to let the user end it early without having to drop the rod.
	if(GLOB.fishing_challenges_by_user[user])
		return COMPONENT_BLOCK_TRANSFORM

///Gives feedback to the user, makes it show up inhand, toggles whether it can be used for fishing.
/obj/item/fishing_rod/telescopic/proc/on_transform(obj/item/source, mob/user, active)
	SIGNAL_HANDLER

	inhand_icon_state = active ? "rod" : null // When inactive, there is no inhand icon_state.
	if(user)
		balloon_alert(user, active ? "extended" : "collapsed")
	playsound(src, 'sound/items/weapons/batonextend.ogg', 50, TRUE)
	update_appearance()
	QDEL_NULL(fishing_line)
	return COMPONENT_NO_DEFAULT_MESSAGE

/obj/item/fishing_rod/telescopic/update_icon_state()
	. = ..()
	icon_state = "[initial(icon_state)][!HAS_TRAIT(src, TRAIT_TRANSFORM_ACTIVE) ? "_collapsed" : ""]"

/obj/item/fishing_rod/telescopic/master
	name = "master fishing rod"
	desc = "The mythical rod of a lost fisher king. Said to be imbued with unparalleled fishing power. There's writing on the back of the pole. \"中国航天制造\""
	difficulty_modifier = -10
	ui_description = "A mythical telescopic fishing rod that makes fishing quite easier."
	wiki_description = null
	icon_state = "fishing_rod_master"
	reel_overlay = "reel_master"
	frame_state = "frame_master"
	active_force = 13 //It's that sturdy
	cast_range = 5
	line = /obj/item/fishing_line/bouncy
	hook = /obj/item/fishing_hook/weighted
	completion_speed_mult = 1.55
	bait_speed_mult = 1.2
	deceleration_mult = 1.2
	bounciness_mult = 0.3
	gravity_mult = 1.2
	material_fish_chance = 33 //if somehow you metalgen it.
	bait_height_mult = 1.4

/obj/item/fishing_rod/tech
	name = "advanced fishing rod"
	desc = "An embedded universal constructor along with micro-fusion generator makes this marvel of technology never run out of bait. Interstellar treaties prevent using it outside of recreational fishing. And you can fish with this. "
	ui_description = "A rod with an infinite supply of synthetic bait. Doubles as an Experi-Scanner for fish."
	wiki_description = "<b>It requires the Advanced Fishing Technology Node to be researched to be printed.</b>"
	icon_state = "fishing_rod_science"
	reel_overlay = "reel_science"
	frame_state = "frame_science"
	bait = /obj/item/food/bait/doughball/synthetic/unconsumable
	completion_speed_mult = 1.1
	bait_speed_mult = 1.1
	deceleration_mult = 1.1
	gravity_mult = 1.2

/obj/item/fishing_rod/tech/Initialize(mapload)
	. = ..()

	var/static/list/fishing_signals = list(
		COMSIG_FISHING_ROD_HOOKED_ITEM = TYPE_PROC_REF(/datum/component/experiment_handler, try_run_handheld_experiment),
		COMSIG_FISHING_ROD_CAUGHT_FISH = TYPE_PROC_REF(/datum/component/experiment_handler, try_run_handheld_experiment),
		COMSIG_ITEM_PRE_ATTACK = TYPE_PROC_REF(/datum/component/experiment_handler, try_run_handheld_experiment),
		COMSIG_ITEM_AFTERATTACK = TYPE_PROC_REF(/datum/component/experiment_handler, ignored_handheld_experiment_attempt),
	)
	AddComponent(/datum/component/experiment_handler, \
		config_mode = EXPERIMENT_CONFIG_ALTCLICK, \
		allowed_experiments = list(/datum/experiment/scanning/fish), \
		config_flags = EXPERIMENT_CONFIG_SILENT_FAIL|EXPERIMENT_CONFIG_IMMEDIATE_ACTION, \
		experiment_signals = fishing_signals, \
	)

/obj/item/fishing_rod/tech/examine(mob/user)
	. = ..()
	. += span_notice("<b>Alt-Click</b> to access the Experiment Configuration UI")

/obj/item/fishing_rod/tech/use_slot(slot, mob/user, obj/item/new_item)
	if(slot == ROD_SLOT_BAIT)
		return
	return ..()

/obj/item/fishing_rod/material
	name = "material fishing rod" //name shown on the autowiki.
	desc = "A custom fishing rod from your local autolathe."
	icon_state = "fishing_rod_material"
	reel_overlay = "reel_material"
	frame_state = "frame_material"
	ui_description = "An autolathe-printable fishing rod made of some material."
	wiki_description = "Different materials can have different effects. They also catch fish made of the same material used to print the rod."
	material_flags = MATERIAL_EFFECTS|MATERIAL_AFFECT_STATISTICS|MATERIAL_COLOR|MATERIAL_ADD_PREFIX

/obj/item/fishing_rod/material/Initialize(mapload)
	. = ..()
	name = "fishing rod"

/obj/item/fishing_rod/material/finalize_remove_material_effects(list/materials)
	. = ..()
	name = "fishing rod" //so it doesn't reset to "material fishing rod"

/obj/item/fishing_rod/material/get_frame(datum/fishing_challenge/challenge)
	var/mutable_appearance/frame = ..()
	frame.color = color
	return frame

#undef ROD_SLOT_BAIT
#undef ROD_SLOT_LINE
#undef ROD_SLOT_HOOK

/obj/projectile/fishing_cast
	name = "fishing hook"
	icon = 'icons/obj/fishing.dmi'
	icon_state = "hook"
	damage = 0
	range = 5
	suppressed =  SUPPRESSED_VERY
	can_hit_turfs = TRUE
	projectile_angle = 180

	var/obj/item/fishing_rod/owner
	var/datum/beam/our_line

/obj/projectile/fishing_cast/fire(angle, atom/direct_target)
	if(owner.hook)
		icon_state = owner.hook.icon_state
	. = ..()
	if(!QDELETED(src))
		our_line = owner.create_fishing_line(src, firer)

/obj/projectile/fishing_cast/on_hit(atom/target, blocked = 0, pierce_hit)
	. = ..()
	if(blocked < 100)
		QDEL_NULL(our_line) //we need to delete the old beam datum, otherwise it won't let you fish.
		owner.hook_hit(target, firer)

/obj/projectile/fishing_cast/Destroy()
	QDEL_NULL(our_line)
	owner?.casting = FALSE
	owner = null
	return ..()

/datum/beam/fishing_line
	// Is the fishing rod held in left side hand
	var/lefthand = FALSE

	// Make these inline with final sprites
	var/righthand_s_px = 13
	var/righthand_s_py = 16

	var/righthand_e_px = 18
	var/righthand_e_py = 16

	var/righthand_w_px = -20
	var/righthand_w_py = 18

	var/righthand_n_px = -14
	var/righthand_n_py = 16

	var/lefthand_s_px = -13
	var/lefthand_s_py = 15

	var/lefthand_e_px = 24
	var/lefthand_e_py = 18

	var/lefthand_w_px = -17
	var/lefthand_w_py = 16

	var/lefthand_n_px = 13
	var/lefthand_n_py = 15

/datum/beam/fishing_line/Start()
	update_offsets(origin.dir)
	. = ..()
	RegisterSignal(origin, COMSIG_ATOM_DIR_CHANGE, PROC_REF(handle_dir_change))

/datum/beam/fishing_line/Destroy()
	UnregisterSignal(origin, COMSIG_ATOM_DIR_CHANGE)
	. = ..()

/datum/beam/fishing_line/proc/handle_dir_change(atom/movable/source, olddir, newdir)
	SIGNAL_HANDLER
	update_offsets(newdir)
	INVOKE_ASYNC(src, TYPE_PROC_REF(/datum/beam/, redrawing))

/datum/beam/fishing_line/proc/update_offsets(user_dir)
	switch(user_dir)
		if(SOUTH)
			override_origin_pixel_x = lefthand ? lefthand_s_px : righthand_s_px
			override_origin_pixel_y = lefthand ? lefthand_s_py : righthand_s_py
		if(EAST)
			override_origin_pixel_x = lefthand ? lefthand_e_px : righthand_e_px
			override_origin_pixel_y = lefthand ? lefthand_e_py : righthand_e_py
		if(WEST)
			override_origin_pixel_x = lefthand ? lefthand_w_px : righthand_w_px
			override_origin_pixel_y = lefthand ? lefthand_w_py : righthand_w_py
		if(NORTH)
			override_origin_pixel_x = lefthand ? lefthand_n_px : righthand_n_px
			override_origin_pixel_y = lefthand ? lefthand_n_py : righthand_n_py

	override_origin_pixel_x += origin.pixel_x
	override_origin_pixel_y += origin.pixel_y

#undef FISHING_ROD_REEL_CAST_RANGE
