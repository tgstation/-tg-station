#define THROW_CRYSTALS_COOLDOWN 15 SECONDS
#define THROW_LAUNCH_COOLDOWN 7 SECONDS

/obj/item/cain_and_abel/on_thrown(mob/living/carbon/user, atom/target)
	. = null
	if(!COOLDOWN_FINISHED(src, throw_cooldown))
		user.balloon_alert(user, "on cooldown!")
		return

	if(user.incapacitated || HAS_TRAIT(user, TRAIT_NO_THROWING) || !isturf(user.loc) || user.buckled)
		user.balloon_alert(user, "unable!")
		return

	if(get_dist(target, user) > 9)
		user.balloon_alert(user, "too far away!")
		return

	var/static/list/throw_options = list(
		THROW_MODE_LAUNCH = list(
			"cooldown" = THROW_LAUNCH_COOLDOWN,
			"projectile" = /obj/projectile/dagger/launch,
		),
		THROW_MODE_CRYSTALS = list(
			"cooldown" = THROW_CRYSTALS_COOLDOWN,
			"projectile" = /obj/projectile/dagger/crystal,
		),
	)

	var/list/throw_settings = throw_options[throw_mode]
	COOLDOWN_START(src, throw_cooldown, throw_settings["cooldown"])
	var/atom/dagger = user.fire_projectile(throw_settings["projectile"], target, 'sound/items/weapons/fwoosh.ogg', user)
	if(isnull(dagger))
		return

	set_dagger_icon(thrown = TRUE) //when we throw a dagger, we'll only be holding 1
	user.Beam(dagger, icon_state = "chain", icon = 'icons/obj/mining_zones/artefacts.dmi', maxdistance = 9, layer = BELOW_MOB_LAYER)
	RegisterSignal(dagger, COMSIG_QDELETING, PROC_REF(reset_dagger_icon))
	RegisterSignal(dagger, COMSIG_PROJECTILE_SELF_ON_HIT, PROC_REF(on_dagger_hit))

/obj/item/cain_and_abel/proc/on_dagger_hit(obj/projectile/dagger/source, atom/movable/firer, atom/target, Angle)
	SIGNAL_HANDLER

	UnregisterSignal(source, list(COMSIG_QDELETING, COMSIG_PROJECTILE_SELF_ON_HIT))
	if(!ismob(loc))
		return

	var/atom/dagger_visual = source.dagger_effects(target)
	if(!QDELETED(dagger_visual))
		RegisterSignal(dagger_visual, COMSIG_QDELETING, PROC_REF(reset_dagger_icon))
		return

	set_dagger_icon(thrown = FALSE)

/obj/item/cain_and_abel/proc/set_dagger_icon(thrown = FALSE)
	inhand_icon_state = "[src::inhand_icon_state][thrown ? "_thrown" : ""]"
	update_inhand_icon()

/obj/item/cain_and_abel/proc/reset_dagger_icon(datum/source)
	SIGNAL_HANDLER
	set_dagger_icon(thrown = FALSE)

#undef THROW_CRYSTALS_COOLDOWN
#undef THROW_LAUNCH_COOLDOWN
