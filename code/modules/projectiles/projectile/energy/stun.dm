/obj/projectile/energy/electrode
	name = "electrode"
	icon_state = "spark"
	color = COLOR_YELLOW
	hitsound = 'sound/items/weapons/taserhit.ogg'
	range = 5
	reflectable = FALSE
	tracer_type = /obj/effect/projectile/tracer/stun
	muzzle_type = /obj/effect/projectile/muzzle/stun
	impact_type = /obj/effect/projectile/impact/stun
	/// How much stamina damage will the tase deal in 1 second
	VAR_PROTECTED/tase_stamina = 30
	/// Electrodes that follow the projectile
	VAR_PRIVATE/datum/weakref/beam_weakref
	/// We need to track who was the ORIGINAL firer of the projectile specifically to ensure deflects work correctly
	VAR_PRIVATE/datum/weakref/initial_firer_weakref

/obj/projectile/energy/electrode/is_hostile_projectile()
	return TRUE

/obj/projectile/energy/electrode/Destroy()
	QDEL_NULL(beam_weakref)
	return ..()

/obj/projectile/energy/electrode/fire(fire_angle, atom/direct_target)
	if(firer)
		beam_weakref = WEAKREF(firer.Beam(
			BeamTarget = src,
			icon = 'icons/effects/beam.dmi',
			icon_state = "electrodes_nozap",
			maxdistance = maximum_range + 1,
			beam_type = /obj/effect/ebeam/electrodes_nozap,
		))
		initial_firer_weakref = WEAKREF(firer)
	return ..()

/obj/projectile/energy/electrode/on_hit(mob/living/target, blocked = 0, pierce_hit)
	. = ..()
	if(pierce_hit)
		return
	if(. == BULLET_ACT_BLOCK || blocked >= 100 || !isliving(target))
		return
	// we need a "from", otherwise, where does the electricity come from?
	if(isnull(fired_from))
		target.visible_message(
			span_warning("[src]\s collide with [target] harmlessly[isfloorturf(target.loc) ? ", before falling to [target.loc]" : ""]."),
			span_notice("[src] collide with you harmlessly[isfloorturf(target.loc) ? ", before falling to [target.loc]" : ""]."),
		)
		return

	do_sparks(1, TRUE, src)
	do_sparks(1, TRUE, fired_from)
	target.apply_status_effect(
		/*type = *//datum/status_effect/tased,
		/*taser = */fired_from,
		/*firer = */initial_firer_weakref?.resolve() || firer,
		/*tase_stamina = */tase_stamina,
		/*energy_drain = */STANDARD_CELL_CHARGE * 0.05,
		/*electrode_name = */"\the [src]\s",
		/*tase_range = */maximum_range + 1,
	)

/obj/projectile/energy/electrode/on_range() //to ensure the bolt sparks when it reaches the end of its range if it didn't hit a target yet
	do_sparks(1, TRUE, src)
	return ..()

/obj/projectile/energy/electrode/ai_turrets
	tase_stamina = 120

/// Status effect tracking being tased by someone!
/datum/status_effect/tased
	id = "being_tased"
	status_type = STATUS_EFFECT_MULTIPLE
	alert_type = null
	tick_interval = 0.25 SECONDS
	on_remove_on_mob_delete = TRUE
	/// What atom is tasing us?
	VAR_PRIVATE/datum/taser
	/// What atom is using the atom tasing us? Sometimes the same as the taser, such as with turrets.
	VAR_PRIVATE/atom/movable/firer
	/// The beam datum representing the taser electrodes
	VAR_PRIVATE/datum/beam/tase_line
	/// How much stamina damage does it aim to cause in a second?
	VAR_FINAL/stamina_per_second = 20
	/// How much energy does the taser use per tick?
	VAR_FINAL/energy_drain = STANDARD_CELL_CHARGE * 0.05
	/// What do we name the electrodes?
	VAR_FINAL/electrode_name
	/// How far can the taser reach?
	VAR_FINAL/tase_range = 6

/datum/status_effect/tased/on_creation(
	mob/living/new_owner,
	datum/fired_from,
	atom/movable/firer,
	tase_stamina = 20,
	energy_drain = STANDARD_CELL_CHARGE * 0.05,
	electrode_name = "the electrodes",
	tase_range = 6,
)
	if(isnull(fired_from) || isnull(firer) || !can_tase_with(fired_from))
		qdel(src)
		return

	src.stamina_per_second = tase_stamina
	src.energy_drain = energy_drain
	src.electrode_name = electrode_name
	src.tase_range = tase_range

	. = ..()
	if(!.)
		return

	set_taser(fired_from)
	set_firer(firer)

/// Checks if the passed atom is captable of being used to tase someone
/datum/status_effect/tased/proc/can_tase_with(datum/with_what)
	if(istype(with_what, /obj/item/gun/energy))
		var/obj/item/gun/energy/taser_gun = with_what
		if(isnull(taser_gun.cell))
			return FALSE

	else if(istype(with_what, /obj/machinery))
		var/obj/machinery/taser_machine = with_what
		if(!taser_machine.is_operational)
			return FALSE

	return TRUE

/// Actually does the tasing with the passed atom
/// Returns TRUE if the tasing was successful, FALSE if it failed
/datum/status_effect/tased/proc/do_tase_with(atom/with_what, seconds_between_ticks)
	if(!can_see(taser, owner, 5))
		return FALSE
	if(istype(with_what, /obj/item/gun/energy))
		var/obj/item/gun/energy/taser_gun = with_what
		if(!taser_gun.cell?.use(energy_drain * seconds_between_ticks))
			return FALSE
		taser_gun.update_appearance()
		return TRUE

	if(istype(taser, /obj/machinery))
		var/obj/machinery/taser_machine = taser
		if(!taser_machine.is_operational)
			return FALSE
		if(!taser_machine.use_energy(energy_drain * seconds_between_ticks, force = FALSE))
			return FALSE
		return TRUE

	if(istype(taser, /obj/item/mecha_parts/mecha_equipment))
		var/obj/item/mecha_parts/mecha_equipment/taser_equipment = taser
		if(!taser_equipment.chassis \
			|| !taser_equipment.active \
			|| taser_equipment.get_integrity() <= 1 \
			|| taser_equipment.chassis.is_currently_ejecting \
			|| taser_equipment.chassis.equipment_disabled \
			|| !taser_equipment.chassis.use_energy(energy_drain * seconds_between_ticks))
			return FALSE
		return TRUE

	return TRUE

/datum/status_effect/tased/on_apply()
	if(issilicon(owner) || isbot(owner) || isdrone(owner) || HAS_TRAIT(owner, TRAIT_PIERCEIMMUNE))
		owner.visible_message(span_warning("[capitalize(electrode_name)] fail to catch [owner][isfloorturf(owner.loc) ? ", falling to [owner.loc]" : ""]!"))
		return FALSE

	RegisterSignal(owner, COMSIG_LIVING_RESIST, PROC_REF(try_remove_taser))
	RegisterSignal(owner, COMSIG_CARBON_PRE_MISC_HELP, PROC_REF(someome_removing_taser))
	SEND_SIGNAL(owner, COMSIG_LIVING_MINOR_SHOCK)
	if(!owner.has_status_effect(type))
		// does not use the status effect api because we snowflake it a bit
		owner.throw_alert(type, /atom/movable/screen/alert/tazed)
		owner.add_mood_event("tased", /datum/mood_event/tased)
		owner.add_movespeed_modifier(/datum/movespeed_modifier/being_tased)
		if(!HAS_TRAIT(owner, TRAIT_ANALGESIA))
			owner.emote("scream")
		if(HAS_TRAIT(owner, TRAIT_HULK))
			owner.say(pick(
				";RAAAAAAAARGH!",
				";HNNNNNNNNNGGGGGGH!",
				";GWAAAAAAAARRRHHH!",
				"NNNNNNNNGGGGGGGGHH!",
				";AAAAAAARRRGH!",
			), forced = "hulk")
		if(HAS_TRAIT(owner, TRAIT_BATON_RESISTANCE)) // If you have baton resistance while being tased, significantly decreases the stamina damage.
			to_chat(owner, span_notice("You feel a slight shock, and attempt to shrug it off."))
			stamina_per_second = 15
		if(HAS_TRAIT(owner, TRAIT_SHOCKIMMUNE)) // genetics mutation insulated protects from taser shock, as well as voltaic heart
			to_chat(owner, span_notice("The electrode hits you, but it only tickles."))
			stamina_per_second = 0
	if(ishuman(owner))
		var/mob/living/carbon/human/human_owner = owner
		human_owner.force_say()
	return TRUE

/datum/status_effect/tased/on_remove()
	if(istype(taser, /obj/machinery/porta_turret))
		var/obj/machinery/porta_turret/taser_turret = taser
		taser_turret.manual_control = initial(taser_turret.manual_control)
		taser_turret.always_up = initial(taser_turret.always_up)
		taser_turret.check_should_process()
	else if(istype(taser, /obj/machinery/power/emitter))
		var/obj/machinery/power/emitter/taser_emitter = taser
		taser_emitter.manual = initial(taser_emitter.manual)

	var/mob/living/mob_firer = firer
	if(istype(mob_firer))
		mob_firer.remove_movespeed_modifier(/datum/movespeed_modifier/tasing_someone)

	if(!QDELING(owner) && !owner.has_status_effect(type))
		owner.adjust_jitter_up_to(10 SECONDS, 1 MINUTES)
		owner.remove_movespeed_modifier(/datum/movespeed_modifier/being_tased)
		owner.clear_alert(type)

	taser = null
	firer = null
	QDEL_NULL(tase_line)

/datum/status_effect/tased/tick(seconds_between_ticks)
	if(!do_tase_with(taser, seconds_between_ticks))
		end_tase()
		return

	owner.adjust_stutter_up_to(10 SECONDS, 20 SECONDS)
	owner.adjust_jitter_up_to(20 SECONDS, 30 SECONDS)
	if(owner.stat <= SOFT_CRIT)
		owner.do_jitter_animation(INFINITY) // maximum POWER

	// You are damp, that's bad when you're being tased
	if(owner.fire_stacks < 0)
		owner.apply_damage(max(1, owner.fire_stacks * -0.5 * seconds_between_ticks), FIRE, spread_damage = TRUE)
		if(SPT_PROB(25, seconds_between_ticks))
			do_sparks(1, FALSE, owner)

	// clumsy people might hit their head while being tased
	if(HAS_TRAIT(owner, TRAIT_CLUMSY) && owner.body_position == LYING_DOWN && SPT_PROB(20, seconds_between_ticks))
		owner.apply_damage(10, BRUTE, BODY_ZONE_HEAD)
		playsound(owner, 'sound/effects/tableheadsmash.ogg', 75, TRUE)

	// the actual stunning is here
	if(!owner.check_stun_immunity(CANSTUN|CANKNOCKDOWN))
		owner.apply_damage(stamina_per_second * seconds_between_ticks, STAMINA)

/// Sets the passed atom as the "taser"
/datum/status_effect/tased/proc/set_taser(datum/new_taser)
	taser = new_taser
	RegisterSignals(taser, list(COMSIG_QDELETING, COMSIG_ITEM_DROPPED, COMSIG_ITEM_EQUIPPED), PROC_REF(end_tase))
	RegisterSignal(taser, COMSIG_GUN_TRY_FIRE, PROC_REF(block_firing))
	// snowflake cases! yay!
	if(istype(taser, /obj/machinery/porta_turret))
		var/obj/machinery/porta_turret/taser_turret = taser
		taser_turret.manual_control = TRUE
		taser_turret.always_up = TRUE
	else if(istype(taser, /obj/machinery/power/emitter))
		var/obj/machinery/power/emitter/taser_emitter = taser
		taser_emitter.manual = TRUE

/// Sets the passed atom as the person operating the taser, the "firer"
/datum/status_effect/tased/proc/set_firer(atom/new_firer)
	firer = new_firer
	if(taser != firer) // Turrets, notably, are both
		RegisterSignal(firer, COMSIG_QDELETING, PROC_REF(end_tase))

	RegisterSignal(firer, COMSIG_MOB_CLICKON, PROC_REF(user_cancel_tase))

	// Ensures AI mobs or turrets don't tase players until they run out of power
	var/mob/living/mob_firer = new_firer
	if(!istype(mob_firer) || isnull(mob_firer.client))
		// If multiple things are tasing the same mob, give up sooner, so they can select a new target potentially
		addtimer(CALLBACK(src, PROC_REF(end_tase)), (owner.has_status_effect(type) != src) ? 2 SECONDS : 8 SECONDS)
	if(istype(mob_firer))
		mob_firer.add_movespeed_modifier(/datum/movespeed_modifier/tasing_someone)

	if(firer == owner)
		return

	tase_line = firer.Beam(
		BeamTarget = owner,
		icon = 'icons/effects/beam.dmi',
		icon_state = "electrodes",
		maxdistance = tase_range,
		beam_type = /obj/effect/ebeam/reacting/electrodes,
	)
	RegisterSignal(tase_line, COMSIG_BEAM_ENTERED, PROC_REF(disrupt_tase))
	RegisterSignal(tase_line, COMSIG_QDELETING, PROC_REF(end_tase))
	// moves the tase beam up or down if the target moves up or down
	tase_line.RegisterSignal(owner, COMSIG_LIVING_SET_BODY_POSITION, TYPE_PROC_REF(/datum/beam, redrawing))

/datum/status_effect/tased/proc/block_firing(...)
	SIGNAL_HANDLER
	return COMPONENT_CANCEL_GUN_FIRE

/datum/status_effect/tased/proc/user_cancel_tase(mob/living/source, atom/clicked_on, modifiers)
	SIGNAL_HANDLER
	if(clicked_on != owner)
		return NONE
	if(LAZYACCESS(modifiers, SHIFT_CLICK))
		return NONE
	end_tase()
	source.changeNext_move(CLICK_CD_GRABBING)
	return COMSIG_MOB_CANCEL_CLICKON

/datum/status_effect/tased/proc/end_tase(...)
	SIGNAL_HANDLER
	if(QDELING(src))
		return
	owner.visible_message(
		span_warning("[capitalize(electrode_name)] stop shocking [owner][isfloorturf(owner.loc) ? ", falling to [owner.loc]" : ""]."),
		span_notice("[capitalize(electrode_name)] stop shocking you[isfloorturf(owner.loc) ? ", falling to [owner.loc]" : ""]."),
	)
	qdel(src)

/datum/status_effect/tased/proc/try_remove_taser(datum/source)
	SIGNAL_HANDLER
	INVOKE_ASYNC(src, PROC_REF(try_remove_taser_async), owner)

/datum/status_effect/tased/proc/someome_removing_taser(datum/source, mob/living/helper)
	SIGNAL_HANDLER
	INVOKE_ASYNC(src, PROC_REF(try_remove_taser_async), helper)
	return COMPONENT_BLOCK_MISC_HELP

/datum/status_effect/tased/proc/try_remove_taser_async(mob/living/remover)
	if(DOING_INTERACTION(remover, id))
		return
	owner.shake_up_animation()
	playsound(owner, 'sound/items/weapons/thudswoosh.ogg', 50, TRUE, -1)
	remover.visible_message(
		span_warning("[owner] tries to remove [electrode_name][remover == owner ? "" : " from [owner]"]!"),
		span_notice("You try to remove [electrode_name][remover == owner ? "" : " from [owner]"]!"),
	)
	// If embedding was less... difficult to work with, I would make tasers rely on an embedded object to handle this
	if(!do_after(remover, 5 SECONDS, owner, extra_checks = CALLBACK(src, PROC_REF(try_remove_taser_checks)), interaction_key = id))
		return
	remover.visible_message(
		span_warning("[owner] removes [electrode_name] from [remover == owner ? "[owner.p_their()]" : "[owner]'s"] body!"),
		span_notice("You remove [electrode_name][remover == owner ? "" : " from [owner]'s body"]!"),
	)
	end_tase()

/datum/status_effect/tased/proc/try_remove_taser_checks()
	return !QDELETED(src)

/datum/status_effect/tased/proc/disrupt_tase(datum/beam/source, obj/effect/ebeam/beam_effect, atom/movable/entering)
	SIGNAL_HANDLER

	if(!isliving(entering) || entering == taser || entering == firer || entering == owner)
		return
	if(entering.pass_flags & (PASSMOB|PASSGRILLE|PASSTABLE))
		return
	var/mob/living/disruptor = entering
	if(!HAS_TRAIT(entering, TRAIT_CLUMSY) || prob(50))
		if(isliving(firer))
			// taser firer can lie down so people can cross over it!
			var/mob/living/firer_living = firer
			if(firer_living.body_position != disruptor.body_position)
				return
		else
			// otherwise you can limbo under it
			if(disruptor.body_position == LYING_DOWN)
				return
	disruptor.visible_message(
		span_warning("[disruptor] gets tangled in [electrode_name]!"),
		span_warning("You get tangled in [electrode_name]!"),
	)
	if(!disruptor.check_stun_immunity(CANSTUN|CANKNOCKDOWN))
		disruptor.apply_damage(90, STAMINA)
		disruptor.Knockdown(5 SECONDS)
	disruptor.adjust_jitter_up_to(10 SECONDS, 30 SECONDS)
	qdel(src)

/// Screen alert for being tased, clicking does a resist
/atom/movable/screen/alert/tazed
	name = "Tased!"
	desc = "You're being tased! You can click this or resist to attempt to stop it, assuming you've not already collapsed."
	icon_state = "stun"
	clickable_glow = TRUE

/atom/movable/screen/alert/tazed/Click(location, control, params)
	. = ..()
	if(!.)
		return
	var/mob/living/clicker = usr
	clicker.resist()

/obj/effect/ebeam/electrodes_nozap
	name = "electrodes"
	alpha = 192

/obj/effect/ebeam/reacting/electrodes
	name = "electrodes"
	light_system = OVERLAY_LIGHT
	light_on = TRUE
	light_color = COLOR_YELLOW
	light_power = 1
	light_range = 1.5

// movespeed mods
/datum/movespeed_modifier/tasing_someone
	multiplicative_slowdown = 2

/datum/movespeed_modifier/being_tased
	multiplicative_slowdown = 4
