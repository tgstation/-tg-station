/// How quicker is it for someone else to rip out an item?
#define RIPPING_OUT_HELP_TIME_MULTIPLIER 0.75
/// How much safer is it for someone else to rip out an item?
#define RIPPING_OUT_HELP_DAMAGE_MULTIPLIER 0.75

/*
 * The magical embedding datum which is a container for all embedding interactions an item (or a projectile) can have.
 * Whenever an item with an embedding datum is thrown into a carbon with either EMBED_THROWSPEED_THRESHOLD throwspeed or ignore_throwspeed_threshold set to TRUE, it will
 * embed into them, with latter option reserved for sticky items and shrapnel.
 * Whenever a projectile embeds, the datum is copied onto the shrapnel
 */

/datum/embedding
	/// Chance for an object to embed into somebody when thrown
	var/embed_chance = 45
	/// Chance for embedded object to fall out (causing pain but removing the object)
	var/fall_chance = 5
	/// Chance for embedded objects to cause pain (damage user)
	var/pain_chance = 15
	/// Coefficient of multiplication for the damage the item does while embedded (this*item.w_class)
	var/pain_mult = 2
	/// Coefficient of multiplication for the damage the item does when it first embeds (this*item.w_class)
	var/impact_pain_mult = 4
	/// Coefficient of multiplication for the damage the item does when it falls out or is removed without a surgery (this*item.w_class)
	var/remove_pain_mult = 6
	/// Time in ticks, total removal time = (this*item.w_class)
	var/rip_time = 3 SECONDS
	/// If this should ignore throw speed threshold of 4
	var/ignore_throwspeed_threshold = FALSE
	/// Chance for embedded objects to cause pain every time they move (jostle)
	var/jostle_chance = 5
	/// Coefficient of multiplication for the damage the item does while
	var/jostle_pain_mult = 1
	/// This percentage of all pain will be dealt as stam damage rather than brute (0-1)
	var/pain_stam_pct = 0
	/// Traits which make target immune to us embedding into them, any trait from the list works
	var/list/immune_traits = list(TRAIT_PIERCEIMMUNE)

	/// Thing that we're attached to
	VAR_FINAL/obj/item/parent
	/// Mob we've embedded into, if any
	VAR_FINAL/mob/living/carbon/owner
	/// Limb we've embedded into in whose contents we reside
	VAR_FINAL/obj/item/bodypart/owner_limb

/datum/embedding/New(obj/item/creator)
	. = ..()
	if (creator)
		register_on(creator)

/// Registers ourselves with an item
/datum/embedding/proc/register_on(obj/item/new_parent)
	if(!isitem(new_parent))
		CRASH("Embedding datum attempted to register on a non-item object [new_parent] ([new_parent?.type])")

	parent = new_parent
	RegisterSignal(parent, COMSIG_QDELETING, PROC_REF(on_qdel))

	RegisterSignal(parent, COMSIG_MOVABLE_IMPACT_ZONE, PROC_REF(try_embed))
	RegisterSignal(parent, COMSIG_ATOM_EXAMINE_TAGS, PROC_REF(examined_tags))

/datum/embedding/Destroy(force)
	if (!parent)
		return ..()
	parent.set_embed(null)
	UnregisterSignal(parent, list(COMSIG_QDELETING, COMSIG_MOVABLE_IMPACT_ZONE, COMSIG_ATOM_EXAMINE))
	owner = null
	owner_limb = null
	parent = null
	return ..()

/// Creates a copy and sets all of its *relevant* variables
/// Children should override this with new variables if they add any "generic" ones
/datum/embedding/proc/create_copy(atom/movable/new_owner)
	var/datum/embedding/brother = new type(new_owner)
	brother.embed_chance = embed_chance
	brother.fall_chance = fall_chance
	brother.pain_chance = pain_chance
	brother.pain_mult = pain_mult
	brother.impact_pain_mult = impact_pain_mult
	brother.remove_pain_mult = remove_pain_mult
	brother.rip_time = rip_time
	brother.ignore_throwspeed_threshold = ignore_throwspeed_threshold
	brother.jostle_chance = jostle_chance
	brother.jostle_pain_mult = jostle_pain_mult
	brother.pain_stam_pct = pain_stam_pct
	brother.immune_traits = immune_traits.Copy()
	return brother

///Someone inspected our embeddable item
/datum/embedding/proc/examined_tags(obj/item/source, mob/user, list/examine_list)
	SIGNAL_HANDLER

	if(is_harmless())
		examine_list["sticky"] = "[parent] looks sticky, and could probably get stuck to someone if thrown properly!"
	else
		examine_list["embeddable"] = "[parent] has a fine point, and could probably embed in someone if thrown properly!"

/// Is passed victim a valid target for us to embed into?
/datum/embedding/proc/can_embed(atom/movable/source, mob/living/carbon/victim, hit_zone, datum/thrownthing/throwingdatum)
	if (!istype(victim))
		return FALSE

	if (HAS_TRAIT(victim, TRAIT_GODMODE))
		return

	if (immune_traits)
		for (var/immunity_trait in immune_traits)
			if (HAS_TRAIT(victim, immunity_trait))
				return FALSE

	if (isitem(source))
		var/flying_speed = throwingdatum?.speed || source.throw_speed
		if(flying_speed < EMBED_THROWSPEED_THRESHOLD && !ignore_throwspeed_threshold)
			return FALSE

	return TRUE

/// Attempts to embed an object
/datum/embedding/proc/try_embed(obj/item/weapon, mob/living/carbon/victim, hit_zone, blocked, datum/thrownthing/throwingdatum)
	SIGNAL_HANDLER

	if (blocked || !can_embed(parent, victim, hit_zone, throwingdatum))
		failed_embed(victim, hit_zone)
		return

	if (!roll_embed_chance(victim, hit_zone, throwingdatum))
		failed_embed(victim, hit_zone, random = TRUE)
		return

	var/obj/item/bodypart/limb = victim.get_bodypart(hit_zone) || victim.bodyparts[1]
	embed_into(victim, limb)
	return MOVABLE_IMPACT_ZONE_OVERRIDE

/// Attempts to embed shrapnel from a projectile
/datum/embedding/proc/try_embed_projectile(obj/projectile/source, atom/hit, hit_zone, blocked, pierce_hit)
	if (pierce_hit)
		return

	if (blocked || !can_embed(source, hit))
		failed_embed(hit, hit_zone)
		return

	var/mob/living/carbon/victim = hit
	var/obj/item/payload = setup_shrapnel(source, victim)

	if (!roll_embed_chance(victim, hit_zone))
		failed_embed(victim, hit_zone, random = TRUE)
		return

	var/obj/item/bodypart/limb = victim.get_bodypart(hit_zone) || victim.bodyparts[1]
	embed_into(victim, limb)
	SEND_SIGNAL(source, COMSIG_PROJECTILE_ON_EMBEDDED, payload, hit)

/// Used for custom logic while setting up shrapnel payload
/datum/embedding/proc/setup_shrapnel(obj/projectile/source, mob/living/carbon/victim)
	var/shrapnel_type = source.shrapnel_type
	var/obj/item/payload = new shrapnel_type(get_turf(victim))
	// Detach from parent, we don't want em to delete us
	source.set_embed(null, dont_delete = TRUE)
	// Hook signals up first, as payload sends a comsig upon embed update
	register_on(payload)
	payload.set_embed(src)
	if(istype(payload, /obj/item/shrapnel/bullet))
		payload.name = source.name
	SEND_SIGNAL(source, COMSIG_PROJECTILE_ON_SPAWN_EMBEDDED, payload, victim)

/// Calculates the actual chance to embed based on armour penetration and throwing speed, then returns true if we pass that probability check
/datum/embedding/proc/roll_embed_chance(mob/living/carbon/victim, hit_zone, datum/thrownthing/throwingdatum)
	var/chance = embed_chance

	// Something threw us really, really fast
	if (throwingdatum?.speed > parent.throw_speed)
		chance += (throwingdatum.speed - parent.throw_speed) * EMBED_CHANCE_SPEED_BONUS

	if (is_harmless())
		return prob(embed_chance)

	// We'll be nice and take the better of bullet and bomb armor, halved
	var/armor = max(victim.run_armor_check(hit_zone, BULLET, armour_penetration = parent.armour_penetration, silent = TRUE), victim.run_armor_check(hit_zone, BOMB, armour_penetration = parent.armour_penetration,  silent = TRUE)) * 0.5
	// We only care about armor penetration if there's actually armor to penetrate
	if(!armor)
		return prob(chance)

	if (parent.weak_against_armour)
		armor *= ARMOR_WEAKENED_MULTIPLIER

	chance -= armor
	if (chance < 0)
		victim.visible_message(span_danger("[parent] bounces off [victim]'s armor, unable to embed!"),
			span_notice("[parent] bounces off your armor, unable to embed!"), vision_distance = COMBAT_MESSAGE_RANGE)
		return FALSE

	return prob(chance)

/// We've tried to embed into something and failed
/// Random being TRUE means we've lost the roulette, FALSE means we've either been blocked or the target is invalid
/datum/embedding/proc/failed_embed(mob/living/carbon/victim, hit_zone, random = FALSE)
	if (!istype(parent))
		return
	SEND_SIGNAL(parent, COMSIG_ITEM_FAILED_EMBED, victim, hit_zone)
	if((parent.item_flags & DROPDEL) && !QDELETED(parent))
		qdel(parent)

/// Does this item deal any damage when embedding or jostling inside of someone?
/datum/embedding/proc/is_harmless(consider_stamina = FALSE)
	return pain_mult == 0 && jostle_pain_mult == 0 && (consider_stamina || pain_stam_pct < 1)

//Handles actual embedding logic.
/datum/embedding/proc/embed_into(mob/living/carbon/victim, obj/item/bodypart/target_limb)
	SHOULD_NOT_OVERRIDE(TRUE)

	set_owner(victim, target_limb)

	START_PROCESSING(SSprocessing, src)
	owner_limb._embed_object(parent)
	parent.forceMove(owner)
	RegisterSignal(parent, COMSIG_MOVABLE_MOVED, PROC_REF(weapon_disappeared))
	RegisterSignal(parent, COMSIG_MAGIC_RECALL, PROC_REF(magic_pull))
	owner.visible_message(span_danger("[parent] [is_harmless() ? "sticks itself to" : "embeds itself in"] [owner]'s [owner_limb.plaintext_zone]!"),
		span_userdanger("[parent] [is_harmless() ? "sticks itself to" : "embeds itself in"] your [owner_limb.plaintext_zone]!"))

	var/damage = parent.throwforce
	if (!is_harmless(consider_stamina = TRUE))
		owner.throw_alert(ALERT_EMBEDDED_OBJECT, /atom/movable/screen/alert/embeddedobject)
		if (!is_harmless())
			playsound(owner,'sound/items/weapons/bladeslice.ogg', 40)
			if (owner_limb.can_bleed())
				parent.add_mob_blood(owner) // it embedded itself in you, of course it's bloody!
		owner.add_mood_event("embedded", /datum/mood_event/embedded)
		damage += parent.w_class * impact_pain_mult

	SEND_SIGNAL(parent, COMSIG_ITEM_EMBEDDED, victim, target_limb)
	on_successful_embed(victim, target_limb)

	if (damage <= 0)
		return TRUE

	var/armor = owner.run_armor_check(owner_limb.body_zone, MELEE, "Your armor has protected your [owner_limb.plaintext_zone].",
		"Your armor has softened a hit to your [owner_limb.plaintext_zone].", parent.armour_penetration,
		weak_against_armour = parent.weak_against_armour,
	)

	owner.apply_damage(
		damage = (1 - pain_stam_pct) * damage,
		damagetype = BRUTE,
		def_zone = owner_limb.body_zone,
		blocked = armor,
		wound_bonus = parent.wound_bonus,
		bare_wound_bonus = parent.bare_wound_bonus,
		sharpness = parent.get_sharpness(),
		attacking_item = parent,
	)

	owner.apply_damage(
		damage = pain_stam_pct * damage,
		damagetype = STAMINA,
	)
	return TRUE

/// Proc which is called upon successfully embedding into someone/something, for children to override
/datum/embedding/proc/on_successful_embed(mob/living/carbon/victim, obj/item/bodypart/target_limb)
	return

/// Registers signals that our owner should have
/// Handles jostling, tweezing embedded items out and grenade chain reactions
/datum/embedding/proc/set_owner(mob/living/carbon/victim, obj/item/bodypart/target_limb)
	owner = victim
	owner_limb = target_limb
	RegisterSignal(owner, COMSIG_MOVABLE_MOVED, PROC_REF(owner_moved))
	RegisterSignal(owner, COMSIG_ATOM_ATTACKBY, PROC_REF(on_attackby))
	RegisterSignal(owner, COMSIG_ATOM_EX_ACT, PROC_REF(on_ex_act))
	RegisterSignal(owner_limb, COMSIG_BODYPART_REMOVED, PROC_REF(on_removed))

/// Avoid calling this directly as this doesn't move the object from its owner's contents
/// Returns TRUE if the item got deleted due to DROPDEL flag
/datum/embedding/proc/stop_embedding()
	STOP_PROCESSING(SSprocessing, src)
	if (owner_limb)
		UnregisterSignal(owner_limb, COMSIG_BODYPART_REMOVED)
		owner_limb._unembed_object(parent)
	if (owner)
		UnregisterSignal(owner, list(COMSIG_MOVABLE_MOVED, COMSIG_ATOM_ATTACKBY, COMSIG_ATOM_EX_ACT))
		if (!owner.has_embedded_objects())
			owner.clear_alert(ALERT_EMBEDDED_OBJECT)
			owner.clear_mood_event("embedded")
	UnregisterSignal(parent, list(COMSIG_MOVABLE_MOVED, COMSIG_MAGIC_RECALL))
	SEND_SIGNAL(parent, COMSIG_ITEM_UNEMBEDDED, owner, owner_limb)
	owner = null
	owner_limb = null
	if((parent.item_flags & DROPDEL) && !QDELETED(parent))
		qdel(parent)
		return TRUE
	return FALSE

/datum/embedding/proc/on_qdel(atom/movable/source)
	SIGNAL_HANDLER
	if (owner_limb)
		weapon_disappeared()
	qdel(src)

/// Move self to owner's turf when our limb gets removed
/datum/embedding/proc/on_removed(datum/source, mob/living/carbon/old_owner)
	SIGNAL_HANDLER
	stop_embedding()
	parent.forceMove(old_owner.drop_location())

/// Someone attempted to pull us out! Either the owner by inspecting themselves, or someone else by examining the owner and clicking the link.
/datum/embedding/proc/rip_out(mob/living/jack_the_ripper)
	if (!jack_the_ripper.CanReach(owner))
		return

	if (!jack_the_ripper.can_perform_action(owner, FORBID_TELEKINESIS_REACH | NEED_HANDS | ALLOW_RESTING))
		return

	var/time_taken = rip_time * parent.w_class
	var/damage_mult = 1
	if (jack_the_ripper != owner)
		time_taken *= RIPPING_OUT_HELP_TIME_MULTIPLIER
		damage_mult *= RIPPING_OUT_HELP_DAMAGE_MULTIPLIER
		owner.visible_message(span_warning("[jack_the_ripper] attempts to remove [parent] from [owner]'s [owner_limb.plaintext_zone]!"),
			span_userdanger("[jack_the_ripper] attempt to remove [parent] from your [owner_limb.plaintext_zone]!"), ignored_mobs = jack_the_ripper)
		to_chat(jack_the_ripper, span_notice("You attempt to remove [parent] from [owner]'s [owner_limb.plaintext_zone]..."))
	else
		owner.visible_message(span_warning("[owner] attempts to remove [parent] from [owner.p_their()] [owner_limb.plaintext_zone]."),
			span_notice("You attempt to remove [parent] from your [owner_limb.plaintext_zone]..."))

	if (!do_after(jack_the_ripper, time_taken, owner, extra_checks = CALLBACK(src, PROC_REF(still_in))))
		return

	if (parent.loc != owner || !(parent in owner_limb?.embedded_objects))
		return

	if (jack_the_ripper == owner)
		owner.visible_message(span_notice("[owner] successfully rips [parent] [is_harmless() ? "off" : "out"] of [owner.p_their()] [owner_limb.plaintext_zone]!"),
			span_notice("You successfully remove [parent] from your [owner_limb.plaintext_zone]."))
	else
		owner.visible_message(span_notice("[jack_the_ripper] successfully rips [parent] [is_harmless() ? "off" : "out"] of [owner]'s [owner_limb.plaintext_zone]!"),
			span_userdanger("[jack_the_ripper] removes [parent] from your [owner_limb.plaintext_zone]!"), ignored_mobs = jack_the_ripper)
		to_chat(jack_the_ripper, span_notice("You successfully remove [parent] from [owner]'s [owner_limb.plaintext_zone]."))

	if (!is_harmless())
		damaging_removal_effect(damage_mult)
	remove_embedding(jack_the_ripper)

/// Handles damage effects upon forceful removal
/datum/embedding/proc/damaging_removal_effect(ouchies_multiplier)
	var/damage = parent.w_class * remove_pain_mult * ouchies_multiplier
	owner.apply_damage(
		damage = (1 - pain_stam_pct) * damage,
		damagetype = BRUTE,
		def_zone = owner_limb,
		wound_bonus = max(0, parent.wound_bonus), // It hurts to rip it out, get surgery you dingus. unlike the others, this CAN wound + increase slash bloodflow
		sharpness = parent.get_sharpness() || SHARP_EDGED, // always sharp, even if the object isn't
		attacking_item = parent,
	)

	owner.apply_damage(
		damage = pain_stam_pct * damage,
		damagetype = STAMINA,
	)

	owner.emote("scream")

/// The proper proc to call when you want to remove something. If a mob is passed, the item will be put in its hands - otherwise it's just dumped onto the ground
/datum/embedding/proc/remove_embedding(mob/living/to_hands)
	var/mob/living/carbon/stored_owner = owner
	if (stop_embedding()) // Dropdel?
		return
	parent.forceMove(stored_owner.drop_location())
	if (!isnull(to_hands))
		to_hands.put_in_hands(parent)

/// When owner moves around, attempt to jostle the item
/datum/embedding/proc/owner_moved(mob/living/carbon/source, atom/old_loc, dir, forced, list/old_locs)
	SIGNAL_HANDLER

	var/chance = jostle_chance
	if(!forced && (owner.move_intent == MOVE_INTENT_WALK || owner.body_position == LYING_DOWN) && !CHECK_MOVE_LOOP_FLAGS(source, MOVEMENT_LOOP_OUTSIDE_CONTROL))
		chance *= 0.5

	if(is_harmless(consider_stamina = TRUE) || !prob(chance))
		return

	var/damage = parent.w_class * jostle_pain_mult
	owner.apply_damage(
		damage = (1 - pain_stam_pct) * damage,
		damagetype = BRUTE,
		def_zone = owner_limb,
		wound_bonus = CANT_WOUND,
		sharpness = parent.get_sharpness(),
		attacking_item = parent,
	)

	owner.apply_damage(
		damage = pain_stam_pct * damage,
		damagetype = STAMINA,
	)

	to_chat(owner, span_userdanger("[parent] embedded in your [owner_limb.plaintext_zone] jostles and stings!"))
	jostle_effects()

/// Effects which should occur when the owner moves, sometimes
/datum/embedding/proc/jostle_effects()
	return

/// When someone attempts to pluck us with tweezers or wirecutters
/datum/embedding/proc/on_attackby(mob/living/carbon/victim, obj/item/tool, mob/user)
	SIGNAL_HANDLER

	if (user.zone_selected != owner_limb.body_zone || (tool.tool_behaviour != TOOL_HEMOSTAT && tool.tool_behaviour != TOOL_WIRECUTTER))
		return

	if (parent != owner_limb.embedded_objects[1]) // Don't pluck everything at the same time
		return

	// Ensure that we can actually
	if (!owner.try_inject(user, owner_limb.body_zone, INJECT_CHECK_IGNORE_SPECIES | INJECT_TRY_SHOW_ERROR_MESSAGE))
		return COMPONENT_NO_AFTERATTACK

	INVOKE_ASYNC(src, PROC_REF(try_pluck), tool, user)
	return COMPONENT_NO_AFTERATTACK

/datum/embedding/process(seconds_per_tick)
	if (!owner || !owner_limb || owner_limb.owner != owner)
		stack_trace("Attempted to process embedding on [parent] ([parent.type]) without an owner, owner_limb or owner-less limb!")
		parent.forceMove(get_turf(parent))
		return

	if (process_effect(seconds_per_tick))
		return

	if (owner.stat == DEAD)
		return

	var/fall_chance_current = SPT_PROB_RATE(fall_chance / 100, seconds_per_tick) * 100
	if(owner.body_position == LYING_DOWN)
		fall_chance_current *= 0.2

	if(prob(fall_chance_current))
		fall_out()
		return

	var/damage = parent.w_class * pain_mult
	var/pain_chance_current = SPT_PROB_RATE(pain_chance / 100, seconds_per_tick) * 100
	if(pain_stam_pct && HAS_TRAIT_FROM(owner, TRAIT_INCAPACITATED, STAMINA)) //if it's a less-lethal embed, give them a break if they're already stamcritted
		pain_chance_current *= 0.2
		damage *= 0.5
	else if(owner.body_position == LYING_DOWN)
		pain_chance_current *= 0.2

	if (is_harmless(consider_stamina = TRUE) || !prob(pain_chance_current))
		return

	owner.apply_damage(
		damage = (1 - pain_stam_pct) * damage,
		damagetype = BRUTE,
		def_zone = owner_limb,
		wound_bonus = CANT_WOUND,
		sharpness = parent.get_sharpness(),
		attacking_item = parent,
	)

	owner.apply_damage(
		damage = pain_stam_pct * damage,
		damagetype = STAMINA,
	)

	to_chat(owner, span_userdanger("[parent] embedded in your [owner_limb.plaintext_zone] [pain_stam_pct < 1 ? "hurts!" : "weighs you down."]"))

/// Called every process, return TRUE in order to abort further processing - if it falls out, etc
/datum/embedding/proc/process_effect(seconds_per_tick)
	return

/// Attempt to pluck out the embedded item using tweezers of some kind
/datum/embedding/proc/try_pluck(obj/item/tool, mob/user)
	var/pluck_time = rip_time * (parent.w_class * 0.3) * tool.toolspeed
	var/self_pluck = (user == owner)
	var/safe_pluck = tool.tool_behaviour != TOOL_HEMOSTAT
	// Don't harm ourselves if we're just stuck
	if (is_harmless())
		safe_pluck = TRUE
	if (self_pluck)
		pluck_time *= 1.5
	// Wirecutters are harder to use for this
	if (safe_pluck)
		pluck_time *= 1.5

	if (self_pluck)
		owner.visible_message(span_danger("[owner] begins plucking [parent] from [owner.p_their()] [owner_limb.plaintext_zone] with [tool]..."),
			span_notice("You start plucking [parent] from your [owner_limb.plaintext_zone] with [tool]..."), visible_message_flags = ALWAYS_SHOW_SELF_MESSAGE)
	else
		user.visible_message(span_danger("[user] begins plucking [parent] from [owner]'s [owner_limb.plaintext_zone] with [tool]..."),
			span_notice("You start plucking [parent] from [owner]'s [owner_limb.plaintext_zone] with [tool]..."), ignored_mobs = owner)
		to_chat(owner, span_userdanger("[user] begins plucking [parent] from your [owner_limb.plaintext_zone] with [tool]... "))

	if (!do_after(user, pluck_time, owner, extra_checks = CALLBACK(src, PROC_REF(still_in))))
		if (self_pluck)
			to_chat(user, span_danger("You fail to pluck [parent] from your [owner_limb.plaintext_zone]."))
		else
			to_chat(user, span_danger("You fail to pluck [parent] from [owner]'s [owner_limb.plaintext_zone]."))
			to_chat(owner, span_danger("[user] fails to pluck [parent] from your [owner_limb.plaintext_zone]."))
		return

	if (self_pluck)
		to_chat(span_notice("You pluck [parent] from your [owner_limb.plaintext_zone][safe_pluck ? "." : span_danger(", but it hurts like hell")]"))

	if(!safe_pluck)
		damaging_removal_effect(min(self_pluck ? 1 : RIPPING_OUT_HELP_DAMAGE_MULTIPLIER, 0.4 * tool.w_class))

	remove_embedding(user)

/// Called when then item randomly falls out of a carbon. This handles the damage and descriptors, then calls remove_embedding()
/datum/embedding/proc/fall_out()
	if(is_harmless())
		owner.visible_message(span_danger("[parent] falls off of [owner.name]'s [owner_limb.plaintext_zone]!"),
			span_userdanger("[parent] falls off of your [owner_limb.plaintext_zone]!"))
		remove_embedding()
		return

	var/damage = parent.w_class * remove_pain_mult
	owner.apply_damage(
		damage = (1 - pain_stam_pct) * damage,
		damagetype = BRUTE,
		def_zone = owner_limb,
		wound_bonus = CANT_WOUND,
		sharpness = parent.get_sharpness(),
		attacking_item = parent,
	)

	owner.apply_damage(
		damage = pain_stam_pct * damage,
		damagetype = STAMINA,
	)

	owner.visible_message(span_danger("[parent] falls out of [owner.name]'s [owner_limb.plaintext_zone]!"),
		span_userdanger("[parent] falls out of your [owner_limb.plaintext_zone]!"))
	remove_embedding()

/// Whenever the parent item is forcefully moved by some weird means
/datum/embedding/proc/weapon_disappeared(atom/old_loc, dir, forced)
	SIGNAL_HANDLER
	// If something moved it to their limb, its not really *disappearing*, is it?
	if (owner && parent.loc != owner_limb)
		to_chat(owner, span_userdanger("[parent] that was embedded in your [owner_limb.plaintext_zone] disappears!"))
	stop_embedding()

/// So the sticky grenades chain-detonate, because mobs are very careful with which of their contents they blow up
/datum/embedding/proc/on_ex_act(atom/source, severity)
	SIGNAL_HANDLER
	// In the process of owner's ex_act
	if (QDELETED(parent))
		return
	switch(severity)
		if(EXPLODE_DEVASTATE)
			SSexplosions.high_mov_atom += parent
		if(EXPLODE_HEAVY)
			SSexplosions.med_mov_atom += parent
		if(EXPLODE_LIGHT)
			SSexplosions.low_mov_atom += parent

/// Called when an object is ripped out of someone's body by magic or other abnormal means
/datum/embedding/proc/magic_pull(obj/item/weapon, mob/living/caster)
	SIGNAL_HANDLER

	if(is_harmless())
		owner.visible_message(span_danger("[parent] vanishes from [owner]'s [owner_limb.plaintext_zone]!"), span_userdanger("[parent] vanishes from [owner_limb.plaintext_zone]!"))
		return

	var/damage = parent.w_class * remove_pain_mult

	owner.apply_damage(
		damage = (1 - pain_stam_pct) * damage * 1.5,
		damagetype = BRUTE,
		def_zone = owner_limb,
		wound_bonus = max(0, parent.wound_bonus), // Performs exit wounds and flings the user to the caster if nearby
		sharpness = parent.get_sharpness() || SHARP_EDGED,
		attacking_item = parent,
	)

	owner.apply_damage(
		damage = pain_stam_pct * damage,
		damagetype = STAMINA,
	)

	owner.cause_wound_of_type_and_severity(WOUND_PIERCE, owner_limb, WOUND_SEVERITY_MODERATE)
	playsound(owner, 'sound/effects/wounds/blood2.ogg', 50, TRUE)

	var/dist = get_dist(caster, owner) //Check if the caster is close enough to yank them in
	if(dist >= 7)
		owner.visible_message(span_danger("[parent] is violently torn from [owner]'s [owner_limb.plaintext_zone]!"), span_userdanger("[parent] is violently torn from your [owner_limb.plaintext_zone]!"))
		return

	owner.throw_at(caster, get_dist(owner, caster) - 1, 1, caster)
	owner.Paralyze(1 SECONDS)
	owner.visible_message(span_alert("[owner] is sent flying towards [caster] as the [parent] tears out of them!"), span_alert("You are launched at [caster] as the [parent] tears from your body and towards their hand!"))

/datum/embedding/proc/still_in()
	if (parent.loc != owner)
		return FALSE
	if (!(parent in owner_limb?.embedded_objects))
		return FALSE
	if (owner_limb?.owner != owner)
		return FALSE
	return TRUE

#undef RIPPING_OUT_HELP_TIME_MULTIPLIER
#undef RIPPING_OUT_HELP_DAMAGE_MULTIPLIER
