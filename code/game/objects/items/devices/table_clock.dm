///Maximum amount of times a clock can be repaired until it's destroyed beyond repair.
#define MAX_CLOCK_REPAIRS 2

/obj/item/table_clock
	name = "table clock"
	desc = "An annoying clock that keeps you sane through tireless nights."
	icon = 'icons/obj/fluff/general.dmi'
	icon_state = "table_clock"
	inhand_icon_state = "table_clock"
	base_icon_state = "table_clock"
	w_class = WEIGHT_CLASS_TINY

	///Soundloop we use of a clock ticking.
	var/datum/looping_sound/clock/soundloop
	///Boolean on whether the clock has been destroyed.
	var/broken = FALSE
	///Amount of times the clock has been destroyed. It becomes unrepairable the third time.
	var/times_broken

/obj/item/table_clock/Initialize(mapload)
	. = ..()
	soundloop = new(src, TRUE)

/obj/item/table_clock/Destroy(force)
	soundloop.stop()
	return ..()

/obj/item/table_clock/examine(mob/user)
	. = ..()
	if(broken)
		. += span_info("It appears to be currently broken. You can use it in-hand to repair it.")
	else
		. += span_info("The current CST (local) time is: [station_time_timestamp()].")
		. += span_info("The current TCT (galactic) time is: [time2text(world.realtime, "hh:mm:ss")].")

/obj/item/table_clock/attackby(obj/item/attacking_item, mob/user, params)
	. = ..()
	if(attacking_item.force < 5 || broken)
		return
	if(break_clock(break_sound = 'sound/effects/magic/clockwork/ark_activation.ogg'))
		user.visible_message(
			span_warning("[user] smashes \the [src] so hard it stops breaking!"),
			span_bolddanger("I can't stand this stupid machine anymore! Shut up already!"),
			span_notice("You hear repeated smashing!"),
		)

/obj/item/table_clock/throw_at(atom/target, range, speed, mob/thrower, spin, diagonals_first, datum/callback/callback, force, gentle, quickstart, throw_type_path = /datum/thrownthing)
	. = ..()
	if(!.)
		return
	break_clock(break_sound = 'sound/effects/footstep/glass_step.ogg')

/obj/item/table_clock/interact(mob/user)
	. = ..()
	if(!broken)
		to_chat(user, span_warning("Touch the clock? And risk breaking it? Are you crazy??"))
		return
	if(times_broken > MAX_CLOCK_REPAIRS)
		user.balloon_alert(user, "clock unrepairable!")
		return
	user.balloon_alert(user, "fixing clock...")
	if(!do_after(user, 10 SECONDS, src))
		return
	user.balloon_alert(user, "clock repaired!")
	broken = FALSE
	soundloop.start()
	update_appearance(UPDATE_ICON)

/obj/item/table_clock/update_icon_state()
	icon_state = "[base_icon_state][broken ? "_broken" : null]"
	return ..()

/**
 * Breaks the clock, turning off the soundloop.
 * Returns TRUE if it successfully breaks, FALSE otherwise.
 */
/obj/item/table_clock/proc/break_clock(break_sound)
	if(broken)
		return FALSE

	broken = TRUE
	soundloop.stop()
	playsound(src, break_sound, 40, FALSE)
	times_broken++
	update_appearance(UPDATE_ICON)
	return TRUE

#undef MAX_CLOCK_REPAIRS
