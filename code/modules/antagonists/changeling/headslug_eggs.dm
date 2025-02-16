#define EGG_INCUBATION_TIME (4 MINUTES)

/// The actual organ that the changeling headslug implants into a dead host.
/obj/item/organ/body_egg/changeling_egg
	name = "changeling egg"
	desc = "Twitching and disgusting."
	/// The mind of the original changeling that gave forth to the headslug mob.
	var/datum/mind/origin
	/// When we're expected to hatch.
	var/hatch_time = 0
	/// When this egg last got removed from a body. If -1, the egg hasn't been removed from a body.
	var/removal_time = -1

/obj/item/organ/body_egg/changeling_egg/on_mob_insert(mob/living/carbon/egg_owner, special = FALSE, movement_flags)
	. = ..()
	hatch_time = world.time + (removal_time == -1 ? EGG_INCUBATION_TIME : (hatch_time - removal_time))

/obj/item/organ/body_egg/changeling_egg/on_mob_remove(mob/living/carbon/egg_owner, special, movement_flags)
	. = ..()
	removal_time = world.time

/obj/item/organ/body_egg/changeling_egg/egg_process(seconds_per_tick, times_fired)
	if(owner && hatch_time <= world.time)
		pop()

/// Once the egg is fully grown, we gib the host and spawn a monkey (with the changeling's player controlling it). Very descriptive proc name.
/obj/item/organ/body_egg/changeling_egg/proc/pop()
	var/mob/living/carbon/human/spawned_monkey = new(owner)
	spawned_monkey.monkeyize(instant = TRUE)

	for(var/obj/item/organ/insertable in src)
		insertable.Insert(spawned_monkey, 1)

	if(origin && (origin.current ? (origin.current.stat == DEAD) : origin.get_ghost()))
		origin.transfer_to(spawned_monkey)
		spawned_monkey.PossessByPlayer(origin.key)
		var/datum/antagonist/changeling/changeling_datum = origin.has_antag_datum(/datum/antagonist/changeling)
		if(!changeling_datum)
			changeling_datum = origin.add_antag_datum(/datum/antagonist/changeling/headslug)
		if(changeling_datum.can_absorb_dna(owner))
			changeling_datum.add_new_profile(owner)

		var/datum/action/changeling/lesserform/transform = new()
		changeling_datum.purchased_powers[transform.type] = transform
		changeling_datum.regain_powers()

	owner.investigate_log("has been gibbed by a changeling egg burst.", INVESTIGATE_DEATHS)
	owner.gib(DROP_ALL_REMAINS)
	qdel(src)

#undef EGG_INCUBATION_TIME
