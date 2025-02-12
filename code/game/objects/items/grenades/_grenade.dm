/**
 * Base class for all grenades.
 */
/obj/item/grenade
	name = "grenade"
	desc = "It has an adjustable timer."
	w_class = WEIGHT_CLASS_SMALL
	icon = 'icons/obj/weapons/grenade.dmi'
	icon_state = "grenade"
	inhand_icon_state = "flashbang"
	worn_icon_state = "grenade"
	lefthand_file = 'icons/mob/inhands/equipment/security_lefthand.dmi'
	righthand_file = 'icons/mob/inhands/equipment/security_righthand.dmi'
	throw_speed = 3
	throw_range = 7
	flags_1 = PREVENT_CONTENTS_EXPLOSION_1 // We detonate upon being exploded.
	obj_flags = CONDUCTS_ELECTRICITY
	slot_flags = ITEM_SLOT_BELT
	max_integrity = 40
	pickup_sound = 'sound/items/handling/grenade/grenade_pick_up.ogg'
	drop_sound = 'sound/items/handling/grenade/grenade_drop.ogg'
	sound_vary = TRUE
	/// Bitfields which prevent the grenade from detonating if set. Includes ([GRENADE_DUD]|[GRENADE_USED])
	var/dud_flags = NONE
	///Is this grenade currently armed?
	var/active = FALSE
	/// Sound played when the grenade is armed
	var/grenade_arm_sound = 'sound/items/weapons/armbomb.ogg'
	/// If the sound of the grenade should be varied
	var/grenade_sound_vary = TRUE
	///Is it a cluster grenade? We don't wanna spam admin logs with these.
	var/type_cluster = FALSE
	///How long it takes for a grenade to explode after being armed
	var/det_time = 5 SECONDS
	///Will this state what its det_time is when examined?
	var/display_timer = TRUE
	///Used in botch_check to determine how a user's clumsiness affects that user's ability to prime a grenade correctly.
	var/clumsy_check = GRENADE_CLUMSY_FUMBLE
	///Was sticky tape used to make this sticky?
	var/sticky = FALSE
	// I moved the explosion vars and behavior to base grenades because we want all grenades to call [/obj/item/grenade/proc/detonate] so we can send COMSIG_GRENADE_DETONATE
	///how big of a devastation explosion radius on prime
	var/ex_dev = 0
	///how big of a heavy explosion radius on prime
	var/ex_heavy = 0
	///how big of a light explosion radius on prime
	var/ex_light = 0
	///how big of a flame explosion radius on prime
	var/ex_flame = 0

	// dealing with creating a [/datum/component/pellet_cloud] on detonate
	/// if set, will spew out projectiles of this type
	var/shrapnel_type
	/// the higher this number, the more projectiles are created as shrapnel
	var/shrapnel_radius
	///Did we add the component responsible for spawning shrapnel to this?
	var/shrapnel_initialized
	///Possible timers that can be assigned for detonation. Values are strings in SECONDS
	var/list/possible_fuse_time = list("Instant", "3", "4", "5")

/obj/item/grenade/Initialize(mapload)
	. = ..()
	ADD_TRAIT(src, TRAIT_ODD_CUSTOMIZABLE_FOOD_INGREDIENT, type)
	RegisterSignal(src, COMSIG_ITEM_USED_AS_INGREDIENT, PROC_REF(on_used_as_ingredient))

/obj/item/grenade/suicide_act(mob/living/carbon/user)
	user.visible_message(span_suicide("[user] primes [src], then eats it! It looks like [user.p_theyre()] trying to commit suicide!"))
	playsound(src, 'sound/items/eatfood.ogg', 50, TRUE)
	arm_grenade(user, det_time)
	user.transferItemToLoc(src, user, TRUE)//>eat a grenade set to 5 seconds >rush captain
	sleep(det_time)//so you don't die instantly
	return dud_flags ? SHAME : BRUTELOSS

/obj/item/grenade/atom_deconstruct(disassembled = TRUE)
	if(!disassembled)
		detonate()

/obj/item/grenade/apply_fantasy_bonuses(bonus)
	. = ..()
	apply_grenade_fantasy_bonuses(bonus)

/obj/item/grenade/remove_fantasy_bonuses(bonus)
	remove_grenade_fantasy_bonuses(bonus)
	return ..()

/obj/item/grenade/proc/apply_grenade_fantasy_bonuses(quality)
	if(ex_dev == 0 && ex_heavy == 0 && ex_light == 0 && ex_flame == 0)
		return
	var/devIncrease = round(quality / 10)
	var/heavyIncrease = round(quality / 5)
	var/lightIncrease = round(quality / 2)
	ex_dev = modify_fantasy_variable("ex_dev", ex_dev, devIncrease, 0)
	ex_heavy = modify_fantasy_variable("ex_heavy", ex_heavy, heavyIncrease, 0)
	ex_light = modify_fantasy_variable("ex_light", ex_light, lightIncrease, 0)

/obj/item/grenade/proc/remove_grenade_fantasy_bonuses(quality)
	ex_dev = reset_fantasy_variable("ex_dev", ex_dev)
	ex_heavy = reset_fantasy_variable("ex_heavy", ex_heavy)
	ex_light = reset_fantasy_variable("ex_light", ex_light)

/**
 * Checks for various ways to botch priming a grenade.
 *
 * Arguments:
 * * mob/living/carbon/human/user - who is priming our grenade?
 */
/obj/item/grenade/proc/botch_check(mob/living/carbon/human/user)
	if(sticky && prob(50)) // to add risk to sticky tape grenade cheese, no return cause we still prime as normal after.
		to_chat(user, span_warning("What the... [src] is stuck to your hand!"))
		ADD_TRAIT(src, TRAIT_NODROP, STICKY_NODROP)

	var/clumsy = HAS_TRAIT(user, TRAIT_CLUMSY)
	if(clumsy && (clumsy_check == GRENADE_CLUMSY_FUMBLE) && prob(50))
		to_chat(user, span_warning("Huh? How does this thing work?"))
		arm_grenade(user, 5, FALSE)
		return TRUE
	else if(!clumsy && (clumsy_check == GRENADE_NONCLUMSY_FUMBLE))
		to_chat(user, span_warning("You pull the pin on [src]. Attached to it is a pink ribbon that says, \"[span_clown("HONK")]\""))
		arm_grenade(user, 5, FALSE)
		return TRUE

/obj/item/grenade/examine(mob/user)
	. = ..()
	if(display_timer)
		if(det_time > 0)
			. += "The timer is set to [DisplayTimeText(det_time)]."
		else
			. += "\The [src] is set for instant detonation."
	if (dud_flags & GRENADE_USED)
		. += span_warning("It looks like [p_theyve()] already been used.")

/obj/item/grenade/attack_self(mob/user)
	if(HAS_TRAIT(src, TRAIT_NODROP))
		to_chat(user, span_notice("You try prying [src] off your hand..."))
		if(do_after(user, 7 SECONDS, target = src))
			to_chat(user, span_notice("You manage to remove [src] from your hand."))
			REMOVE_TRAIT(src, TRAIT_NODROP, STICKY_NODROP)
		return

	if (active)
		return
	if(!botch_check(user)) // if they botch the prime, it'll be handled in botch_check
		arm_grenade(user)

/obj/item/grenade/proc/log_grenade(mob/user)
	if(!type_cluster)
		log_bomber(user, "has primed a", src, "for detonation", message_admins = dud_flags != NONE)

/**
 * arm_grenade (formerly preprime) refers to when a grenade with a standard time fuze is activated, making it go beepbeepbeep and then detonate a few seconds later.
 * Grenades with other triggers like remote igniters probably skip this step and go straight to [/obj/item/grenade/proc/detonate]
 */
/obj/item/grenade/proc/arm_grenade(mob/user, delayoverride, msg = TRUE, volume = 60)
	log_grenade(user) //Inbuilt admin procs already handle null users
	if(user)
		add_fingerprint(user)
		if(msg)
			to_chat(user, span_warning("You prime [src]! [capitalize(DisplayTimeText(det_time))]!"))
	if(shrapnel_type && shrapnel_radius)
		shrapnel_initialized = TRUE
		AddComponent(/datum/component/pellet_cloud, projectile_type = shrapnel_type, magnitude = shrapnel_radius)
	playsound(src, grenade_arm_sound, volume, grenade_sound_vary)
	if(istype(user))
		user.add_mob_memory(/datum/memory/bomb_planted, antagonist = src)
	active = TRUE
	icon_state = (base_icon_state || initial(icon_state)) + "_active"
	SEND_SIGNAL(src, COMSIG_GRENADE_ARMED, det_time, delayoverride)
	addtimer(CALLBACK(src, PROC_REF(detonate)), isnull(delayoverride)? det_time : delayoverride)

/**
 * detonate (formerly prime) refers to when the grenade actually delivers its payload (whether or not a boom/bang/detonation is involved)
 *
 * Arguments:
 * * lanced_by- If this grenade was detonated by an elance, we need to pass that along with the COMSIG_GRENADE_DETONATE signal for pellet clouds
 */
/obj/item/grenade/proc/detonate(mob/living/lanced_by)
	if (dud_flags)
		active = FALSE
		update_appearance()
		return FALSE

	dud_flags |= GRENADE_USED // Don't detonate if we have already detonated.
	if(shrapnel_type && shrapnel_radius && !shrapnel_initialized) // add a second check for adding the component in case whatever triggered the grenade went straight to prime (badminnery for example)
		shrapnel_initialized = TRUE
		AddComponent(/datum/component/pellet_cloud, projectile_type = shrapnel_type, magnitude = shrapnel_radius)

	SEND_SIGNAL(src, COMSIG_GRENADE_DETONATE, lanced_by)
	if(ex_dev || ex_heavy || ex_light || ex_flame)
		explosion(src, ex_dev, ex_heavy, ex_light, ex_flame)

	return TRUE

/obj/item/grenade/proc/update_mob()
	if(ismob(loc))
		var/mob/mob = loc
		mob.dropItemToGround(src)

///Signal sent by someone putting the grenade in as an ingredient. Registers signals onto what it was put into so it can explode.
/obj/item/grenade/proc/on_used_as_ingredient(datum/source, atom/used_in)
	SIGNAL_HANDLER

	RegisterSignal(used_in, COMSIG_FOOD_EATEN, PROC_REF(ingredient_detonation))
	RegisterSignal(used_in, COMSIG_TOOL_ATOM_ACTED_PRIMARY(TOOL_KNIFE), PROC_REF(ingredient_detonation))
	RegisterSignal(used_in, COMSIG_TOOL_ATOM_ACTED_PRIMARY(TOOL_ROLLINGPIN), PROC_REF(ingredient_detonation))

///Signal sent by someone eating food this is an ingredient in "used_in". Makes the grenade go kerblooey, destroying the food.
/obj/item/grenade/proc/ingredient_detonation(atom/used_in, mob/living/target, mob/living/user, bitecount, bitesize)
	SIGNAL_HANDLER

	detonate()
	//can't remove it as an ingredient so we need to get rid of the food. deleted ingredients not good
	return DESTROY_FOOD

/obj/item/grenade/screwdriver_act(mob/living/user, obj/item/tool)
	if(active)
		return FALSE
	if(change_det_time())
		tool.play_tool_sound(src)
		if(det_time == 0)
			to_chat(user, span_notice("You modify the time delay. It's set to be instantaneous."))
		else
			to_chat(user, span_notice("You modify the time delay. It's set for [DisplayTimeText(det_time)]."))
		return TRUE

/obj/item/grenade/multitool_act(mob/living/user, obj/item/tool)
	. = ..()
	if(active)
		return FALSE

	. = TRUE

	var/newtime = tgui_input_list(user, "Please enter a new detonation time", "Detonation Timer", possible_fuse_time)
	if (isnull(newtime))
		return
	if(!user.can_perform_action(src))
		return
	if(newtime == "Instant" && change_det_time(0))
		to_chat(user, span_notice("You modify the time delay. It's set to be instantaneous."))
		return
	newtime = round(text2num(newtime))
	if(change_det_time(newtime))
		to_chat(user, span_notice("You modify the time delay. It's set for [DisplayTimeText(det_time)]."))

/**
 * Sets det_time to a number in SECONDS
 *
 * if time is passed as an argument, `det_time` will be `time SECONDS`
 *
 * Cycles the duration of the fuse of the grenade `det_time` based on the options provided in list/possible_fuse_time
*/
/obj/item/grenade/proc/change_det_time(time)
	. = TRUE
	//Multitool
	if(!isnull(time))
		det_time = round(clamp(time SECONDS, 0, 5 SECONDS)) //This is fine for now but consider making this a variable if you want >5s fuse
		return

	//Screwdriver
	if(det_time == 0)
		det_time = "Instant"
	else
		det_time = num2text(det_time * 0.1)

	var/old_selection = possible_fuse_time.Find(det_time) //Position of det_time in the list
	if(old_selection >= possible_fuse_time.len)
		det_time = possible_fuse_time[1]
	else
		det_time = possible_fuse_time[old_selection+1]

	if(det_time == "Instant")
		det_time = 0 //String to num conversion because I hate coders
		return
	det_time = text2num(det_time) SECONDS

/obj/item/grenade/attack_paw(mob/user, list/modifiers)
	return attack_hand(user, modifiers)

/obj/item/grenade/hit_reaction(mob/living/carbon/human/owner, atom/movable/hitby, attack_text = "the attack", final_block_chance = 0, damage = 0, attack_type = MELEE_ATTACK, damage_type = BRUTE)
	if(damage && attack_type == PROJECTILE_ATTACK && damage_type != STAMINA && prob(15))
		owner.visible_message(span_danger("[attack_text] hits [owner]'s [src], setting it off! What a shot!"))
		var/turf/source_turf = get_turf(src)
		var/logmsg = "held a grenade detonated by a projectile ([hitby]) at [COORD(source_turf)]"
		owner.log_message(logmsg, LOG_GAME)
		owner.log_message(logmsg, LOG_VICTIM, log_globally = FALSE)
		message_admins("A projectile ([hitby]) detonated a grenade held by [key_name_admin(owner)] at [ADMIN_COORDJMP(source_turf)]")
		detonate()

		if(!QDELETED(src)) // some grenades don't detonate but we want them destroyed
			qdel(src)
		return TRUE //It hit the grenade, not them

/obj/item/grenade/ranged_interact_with_atom(atom/interacting_with, mob/living/user, list/modifiers)
	if(active)
		user.throw_item(interacting_with)
		return ITEM_INTERACT_SUCCESS
	return NONE
