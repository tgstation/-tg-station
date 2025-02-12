#define MOTH_WING_FORCE 1 NEWTONS

///Moth wings! They can flutter in low-grav and burn off in heat
/obj/item/organ/wings/moth
	name = "moth wings"
	desc = "Spread your wings and FLOOOOAAAAAT!"

	preference = "feature_moth_wings"

	dna_block = DNA_MOTH_WINGS_BLOCK

	bodypart_overlay = /datum/bodypart_overlay/mutant/wings/moth
	restyle_flags = EXTERNAL_RESTYLE_FLESH

	///Are we burned?
	var/burnt = FALSE
	///Store our old datum here for if our burned wings are healed
	var/original_sprite_datum

	var/drift_force = MOTH_WING_FORCE
	var/stabilizer_force = MOTH_WING_FORCE

/obj/item/organ/wings/moth/Initialize(mapload)
	. = ..()
	AddComponent( \
		/datum/component/jetpack, \
		TRUE, \
		drift_force, \
		stabilizer_force, \
		COMSIG_ORGAN_IMPLANTED, \
		COMSIG_ORGAN_REMOVED, \
		null, \
		CALLBACK(src, PROC_REF(allow_flight)), \
		null, \
	)

/obj/item/organ/wings/moth/on_mob_insert(mob/living/carbon/receiver)
	. = ..()
	RegisterSignal(receiver, COMSIG_HUMAN_BURNING, PROC_REF(try_burn_wings))
	RegisterSignal(receiver, COMSIG_LIVING_POST_FULLY_HEAL, PROC_REF(heal_wings))

/obj/item/organ/wings/moth/on_mob_remove(mob/living/carbon/organ_owner)
	. = ..()
	UnregisterSignal(organ_owner, list(COMSIG_HUMAN_BURNING, COMSIG_LIVING_POST_FULLY_HEAL))

/obj/item/organ/wings/moth/make_flap_sound(mob/living/carbon/wing_owner)
	playsound(wing_owner, 'sound/mobs/humanoids/moth/moth_flutter.ogg', 50, TRUE)

/obj/item/organ/wings/moth/can_soften_fall()
	return !burnt

/obj/item/organ/wings/moth/proc/allow_flight()
	if(!owner || !owner.client)
		return FALSE
	if(owner.has_gravity())
		return FALSE
	if(ishuman(owner))
		var/mob/living/carbon/human/human_owner = owner
		if(human_owner.wear_suit?.flags_inv & HIDEMUTWINGS)
			return FALSE //Can't fly with hidden wings
	if(burnt)
		return FALSE
	var/datum/gas_mixture/current = owner.loc.return_air()
	if(current && (current.return_pressure() >= ONE_ATMOSPHERE*0.85))
		return TRUE
	return FALSE

///check if our wings can burn off ;_;
/obj/item/organ/wings/moth/proc/try_burn_wings(mob/living/carbon/human/human)
	SIGNAL_HANDLER

	if(!burnt && human.bodytemperature >= 800 && human.fire_stacks > 0) //do not go into the extremely hot light. you will not survive
		to_chat(human, span_danger("Your precious wings burn to a crisp!"))
		human.add_mood_event("burnt_wings", /datum/mood_event/burnt_wings)

		burn_wings()
		human.update_body_parts()

///burn the wings off
/obj/item/organ/wings/moth/proc/burn_wings()
	var/datum/bodypart_overlay/mutant/wings/moth/wings = bodypart_overlay
	wings.burnt = TRUE
	burnt = TRUE

///heal our wings back up!!
/obj/item/organ/wings/moth/proc/heal_wings(datum/source, heal_flags)
	SIGNAL_HANDLER

	if(!burnt)
		return

	if(heal_flags & (HEAL_LIMBS|HEAL_ORGANS))
		var/datum/bodypart_overlay/mutant/wings/moth/wings = bodypart_overlay
		wings.burnt = FALSE
		burnt = FALSE

///Moth wing bodypart overlay, including burn functionality!
/datum/bodypart_overlay/mutant/wings/moth
	feature_key = "moth_wings"
	layers = EXTERNAL_BEHIND | EXTERNAL_FRONT
	///Accessory datum of the burn sprite
	var/datum/sprite_accessory/burn_datum = /datum/sprite_accessory/moth_wings/burnt_off
	///Are we burned? If so we draw differently
	var/burnt

/datum/bodypart_overlay/mutant/wings/moth/New()
	. = ..()

	burn_datum = fetch_sprite_datum(burn_datum)

/datum/bodypart_overlay/mutant/wings/moth/get_global_feature_list()
	return SSaccessories.moth_wings_list

/datum/bodypart_overlay/mutant/wings/moth/can_draw_on_bodypart(mob/living/carbon/human/human)
	if(!(human.wear_suit?.flags_inv & HIDEMUTWINGS))
		return TRUE
	return FALSE

/datum/bodypart_overlay/mutant/wings/moth/get_base_icon_state()
	return burnt ? burn_datum.icon_state : sprite_datum.icon_state

#undef MOTH_WING_FORCE
