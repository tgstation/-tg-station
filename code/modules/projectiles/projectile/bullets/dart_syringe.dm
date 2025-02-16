/obj/projectile/bullet/dart
	name = "dart"
	icon_state = "cbbolt"
	damage = 6
	embed_type = null
	shrapnel_type = null
	var/inject_flags = null

/obj/projectile/bullet/dart/Initialize(mapload)
	. = ..()
	create_reagents(50, NO_REACT)

/obj/projectile/bullet/dart/on_hit(atom/target, blocked = 0, pierce_hit)
	if(iscarbon(target))
		var/mob/living/carbon/M = target
		if(blocked != 100) // not completely blocked
			if(M.can_inject(target_zone = def_zone, injection_flags = inject_flags)) // Pass the hit zone to see if it can inject by whether it hit the head or the body.
				..()
				reagents.trans_to(M, reagents.total_volume, methods = INJECT)
				return BULLET_ACT_HIT
			else
				blocked = 100
				target.visible_message(span_danger("\The [src] is deflected!"), \
									   span_userdanger("You are protected against \the [src]!"))

	..(target, blocked)
	reagents.flags &= ~(NO_REACT)
	reagents.handle_reactions()
	return BULLET_ACT_HIT

/obj/projectile/bullet/dart/metalfoam/Initialize(mapload)
	. = ..()
	reagents.add_reagent(/datum/reagent/aluminium, 15)
	reagents.add_reagent(/datum/reagent/foaming_agent, 5)
	reagents.add_reagent(/datum/reagent/toxin/acid/fluacid, 5)

/obj/projectile/bullet/dart/syringe
	name = "syringe"
	icon_state = "syringeproj"
	/// Syringe stored by this projectile
	var/obj/item/reagent_containers/syringe/inner_syringe

/obj/projectile/bullet/dart/syringe/Initialize(mapload)
	. = ..()
	// This prevents the Ody from being used as a combat mech spamming RDX/Teslium syringes all over the place.
	// Other syringe guns are loaded manually with pre-filled syringes which will react chems themselves.
	// The traitor chem dartgun uses /obj/projectile/bullet/dart/piercing, so this does not impact it.
	reagents.flags &= ~NO_REACT

/obj/projectile/bullet/dart/syringe/on_range()
	if (inner_syringe)
		inner_syringe.forceMove(drop_location())
	return ..()

/obj/projectile/bullet/dart/syringe/on_hit(atom/target, blocked, pierce_hit)
	. = ..()
	if (inner_syringe)
		inner_syringe.forceMove(drop_location())

/obj/projectile/bullet/dart/piercing
	inject_flags = INJECT_CHECK_PENETRATE_THICK
