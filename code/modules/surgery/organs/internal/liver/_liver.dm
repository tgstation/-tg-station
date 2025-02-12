#define LIVER_DEFAULT_TOX_TOLERANCE 3 //amount of toxins the liver can filter out
#define LIVER_DEFAULT_TOX_RESISTANCE 1 //lower values lower how harmful toxins are to the liver
#define LIVER_FAILURE_STAGE_SECONDS 60 //amount of seconds before liver failure reaches a new stage

/obj/item/organ/liver
	name = "liver"
	desc = "Pairing suggestion: chianti and fava beans."
	icon_state = "liver"

	w_class = WEIGHT_CLASS_SMALL
	zone = BODY_ZONE_CHEST
	slot = ORGAN_SLOT_LIVER

	maxHealth = STANDARD_ORGAN_THRESHOLD
	healing_factor = STANDARD_ORGAN_HEALING
	decay_factor = STANDARD_ORGAN_DECAY // smack in the middle of decay times

	food_reagents = list(/datum/reagent/consumable/nutriment/organ_tissue = 5, /datum/reagent/iron = 5)
	grind_results = list(/datum/reagent/consumable/nutriment/peptides = 5)

	/// Affects how much damage the liver takes from alcohol
	var/alcohol_tolerance = ALCOHOL_RATE
	/// The maximum volume of toxins the liver will ignore
	var/toxTolerance = LIVER_DEFAULT_TOX_TOLERANCE
	/// Modifies how much damage toxin deals to the liver
	var/liver_resistance = LIVER_DEFAULT_TOX_RESISTANCE
	var/filterToxins = TRUE //whether to filter toxins
	var/operated = FALSE //whether the liver's been repaired with surgery and can be fixed again or not

/obj/item/organ/liver/Initialize(mapload)
	. = ..()
	// If the liver handles foods like a clown, it honks like a bike horn
	// Don't think about it too much.
	RegisterSignal(src, SIGNAL_ADDTRAIT(TRAIT_COMEDY_METABOLISM), PROC_REF(on_add_comedy_metabolism))
	RegisterSignal(src, SIGNAL_REMOVETRAIT(TRAIT_COMEDY_METABOLISM), PROC_REF(on_remove_comedy_metabolism))

/* Signal handler for the liver gaining the TRAIT_COMEDY_METABOLISM trait
 *
 * Adds the "squeak" component, so clown livers will act just like their
 * bike horns, and honk when you hit them with things, or throw them
 * against things, or step on them.
 *
 * The removal of the component, if this liver loses that trait, is handled
 * by the component itself.
 */
/obj/item/organ/liver/proc/on_add_comedy_metabolism()
	SIGNAL_HANDLER

	// Are clown "bike" horns made from the livers of ex-clowns?
	// Would that make the clown more or less likely to honk it
	AddComponent(/datum/component/squeak, list('sound/items/bikehorn.ogg'=1), 50, falloff_exponent = 20)

/* Signal handler for the liver losing the TRAIT_COMEDY_METABOLISM trait
 *
 * Basically just removes squeak component
 */
/obj/item/organ/liver/proc/on_remove_comedy_metabolism()
	SIGNAL_HANDLER

	qdel(GetComponent(/datum/component/squeak))

/// Registers COMSIG_SPECIES_HANDLE_CHEMICAL from owner
/obj/item/organ/liver/on_mob_insert(mob/living/carbon/organ_owner, special, movement_flags)
	. = ..()
	RegisterSignal(organ_owner, COMSIG_SPECIES_HANDLE_CHEMICAL, PROC_REF(handle_chemical))
	RegisterSignal(organ_owner, COMSIG_ATOM_EXAMINE, PROC_REF(on_owner_examine))

/// Unregisters COMSIG_SPECIES_HANDLE_CHEMICAL from owner
/obj/item/organ/liver/on_mob_remove(mob/living/carbon/organ_owner, special, movement_flags)
	. = ..()
	UnregisterSignal(organ_owner, list(COMSIG_SPECIES_HANDLE_CHEMICAL, COMSIG_ATOM_EXAMINE))

/**
 * This proc can be overriden by liver subtypes so they can handle certain chemicals in special ways.
 * Return null to continue running the normal on_mob_life() for that reagent.
 * Return COMSIG_MOB_STOP_REAGENT_CHECK to not run the normal metabolism effects.
 *
 * NOTE: If you return COMSIG_MOB_STOP_REAGENT_CHECK, that reagent will not be removed like normal! You must handle it manually.
 **/
/obj/item/organ/liver/proc/handle_chemical(mob/living/carbon/organ_owner, datum/reagent/chem, seconds_per_tick, times_fired)
	SIGNAL_HANDLER

/obj/item/organ/liver/examine(mob/user)
	. = ..()

	if(HAS_MIND_TRAIT(user, TRAIT_ENTRAILS_READER) || isobserver(user))
		if(HAS_TRAIT(src, TRAIT_LAW_ENFORCEMENT_METABOLISM))
			. += span_info("Fatty deposits and sprinkle residue, imply that this is the liver of someone in <em>security</em>.")
		if(HAS_TRAIT(src, TRAIT_CULINARY_METABOLISM))
			. += span_info("The high iron content and slight smell of garlic, implies that this is the liver of a <em>cook</em>.")
		if(HAS_TRAIT(src, TRAIT_COMEDY_METABOLISM))
			. += span_info("A smell of bananas, a slippery sheen and [span_clown("honking")] when depressed, implies that this is the liver of a <em>clown</em>.")
		if(HAS_TRAIT(src, TRAIT_MEDICAL_METABOLISM))
			. += span_info("Marks of stress and a faint whiff of medicinal alcohol, imply that this is the liver of a <em>medical worker</em>.")
		if(HAS_TRAIT(src, TRAIT_ENGINEER_METABOLISM))
			. += span_info("Signs of radiation exposure and space adaption, implies that this is the liver of an <em>engineer</em>.")
		if(HAS_TRAIT(src, TRAIT_BALLMER_SCIENTIST))
			. += span_info("Strange glowing residues, sprinklings of congealed solid plasma, and what seem to be tumors indicate this is the radiated liver of a <em>scientist</em>.")
		if(HAS_TRAIT(src, TRAIT_MAINTENANCE_METABOLISM))
			. += span_info("A half-digested rat's tail (somehow), disgusting sludge, and the faint smell of Grey Bull imply this is what remains of an <em>assistant</em>'s liver.")
		if(HAS_TRAIT(src, TRAIT_CORONER_METABOLISM))
			. += span_info("An aroma of pickles and sea water, along with being remarkably well-preserved, imply this is what remains of a <em>coroner</em>'s liver.")
		if(HAS_TRAIT(src, TRAIT_HUMAN_AI_METABOLISM))
			. += span_info("The liver appears barely human and entirely self-sufficient, implying this is what remains of a <em>human AI</em>'s liver.")

		// royal trumps pretender royal
		if(HAS_TRAIT(src, TRAIT_ROYAL_METABOLISM))
			. += span_info("A rich diet of luxury food, suppleness from soft beds, implies that this is the liver of a <em>head of staff</em>.")
		else if(HAS_TRAIT(src, TRAIT_PRETENDER_ROYAL_METABOLISM))
			. += span_info("A diet of imitation caviar, and signs of insomnia, implies that this is the liver of <em>someone who wants to be a head of staff</em>.")

/obj/item/organ/liver/before_organ_replacement(obj/item/organ/replacement)
	. = ..()
	if(!istype(replacement, type))
		return

	var/datum/job/owner_job = owner.mind?.assigned_role
	if(!owner_job || !LAZYLEN(owner_job.liver_traits))
		return

	// Transfer over liver traits from jobs, if we should have them
	for(var/readded_trait in owner_job.liver_traits)
		if(!HAS_TRAIT_FROM(src, readded_trait, JOB_TRAIT))
			continue
		ADD_TRAIT(replacement, readded_trait, JOB_TRAIT)

/obj/item/organ/liver/on_life(seconds_per_tick, times_fired)
	. = ..()
	//If your liver is failing, then we use the liverless version of metabolize
	if((organ_flags & ORGAN_FAILING) || HAS_TRAIT(owner, TRAIT_LIVERLESS_METABOLISM))
		owner.reagents.end_metabolization(keep_liverless = TRUE)
		owner.reagents.metabolize(owner, seconds_per_tick, times_fired, can_overdose = TRUE, liverless = TRUE)
		return

	owner.reagents?.metabolize(owner, seconds_per_tick, times_fired, can_overdose = TRUE)

/obj/item/organ/liver/handle_failing_organs(seconds_per_tick)
	if(HAS_TRAIT(owner, TRAIT_STABLELIVER) || HAS_TRAIT(owner, TRAIT_LIVERLESS_METABOLISM))
		return
	return ..()

/obj/item/organ/liver/organ_failure(seconds_per_tick)
	switch(failure_time/LIVER_FAILURE_STAGE_SECONDS)
		if(1)
			to_chat(owner, span_userdanger("You feel stabbing pain in your abdomen!"))
		if(2)
			to_chat(owner, span_userdanger("You feel a burning sensation in your gut!"))
			owner.vomit(VOMIT_CATEGORY_DEFAULT)
		if(3)
			to_chat(owner, span_userdanger("You feel painful acid in your throat!"))
			owner.vomit(VOMIT_CATEGORY_BLOOD)
		if(4)
			to_chat(owner, span_userdanger("Overwhelming pain knocks you out!"))
			owner.vomit(VOMIT_CATEGORY_BLOOD, distance = rand(1,2))
			owner.emote("Scream")
			owner.AdjustUnconscious(2.5 SECONDS)
		if(5)
			to_chat(owner, span_userdanger("You feel as if your guts are about to melt!"))
			owner.vomit(VOMIT_CATEGORY_BLOOD, distance = rand(1,3))
			owner.emote("Scream")
			owner.AdjustUnconscious(5 SECONDS)

	switch(failure_time)
		//After 60 seconds we begin to feel the effects
		if(1 * LIVER_FAILURE_STAGE_SECONDS to 2 * LIVER_FAILURE_STAGE_SECONDS - 1)
			owner.adjustToxLoss(0.2 * seconds_per_tick,forced = TRUE)
			owner.adjust_disgust(0.1 * seconds_per_tick)

		if(2 * LIVER_FAILURE_STAGE_SECONDS to 3 * LIVER_FAILURE_STAGE_SECONDS - 1)
			owner.adjustToxLoss(0.4 * seconds_per_tick,forced = TRUE)
			owner.adjust_drowsiness(0.5 SECONDS * seconds_per_tick)
			owner.adjust_disgust(0.3 * seconds_per_tick)

		if(3 * LIVER_FAILURE_STAGE_SECONDS to 4 * LIVER_FAILURE_STAGE_SECONDS - 1)
			owner.adjustToxLoss(0.6 * seconds_per_tick,forced = TRUE)
			owner.adjustOrganLoss(pick(ORGAN_SLOT_HEART,ORGAN_SLOT_LUNGS,ORGAN_SLOT_STOMACH,ORGAN_SLOT_EYES,ORGAN_SLOT_EARS),0.2 * seconds_per_tick)
			owner.adjust_drowsiness(1 SECONDS * seconds_per_tick)
			owner.adjust_disgust(0.6 * seconds_per_tick)

			if(SPT_PROB(1.5, seconds_per_tick))
				owner.emote("drool")

		if(4 * LIVER_FAILURE_STAGE_SECONDS to INFINITY)
			owner.adjustToxLoss(0.8 * seconds_per_tick,forced = TRUE)
			owner.adjustOrganLoss(pick(ORGAN_SLOT_HEART,ORGAN_SLOT_LUNGS,ORGAN_SLOT_STOMACH,ORGAN_SLOT_EYES,ORGAN_SLOT_EARS),0.5 * seconds_per_tick)
			owner.adjust_drowsiness(1.6 SECONDS * seconds_per_tick)
			owner.adjust_disgust(1.2 * seconds_per_tick)

			if(SPT_PROB(3, seconds_per_tick))
				owner.emote("drool")

/obj/item/organ/liver/proc/on_owner_examine(datum/source, mob/user, list/examine_list)
	if(!ishuman(owner) || !(organ_flags & ORGAN_FAILING))
		return

	var/mob/living/carbon/human/humie_owner = owner
	if(!humie_owner.get_organ_slot(ORGAN_SLOT_EYES) || humie_owner.is_eyes_covered())
		return
	switch(failure_time)
		if(0 to 3 * LIVER_FAILURE_STAGE_SECONDS - 1)
			examine_list += span_notice("[owner]'s eyes are slightly yellow.")
		if(3 * LIVER_FAILURE_STAGE_SECONDS to 4 * LIVER_FAILURE_STAGE_SECONDS - 1)
			examine_list += span_notice("[owner]'s eyes are completely yellow, and [owner.p_they()] [owner.p_are()] visibly suffering.")
		if(4 * LIVER_FAILURE_STAGE_SECONDS to INFINITY)
			examine_list += span_danger("[owner]'s eyes are completely yellow and swelling with pus. [owner.p_They()] [owner.p_do()]n't look like [owner.p_they()] will be alive for much longer.")

/obj/item/organ/liver/get_availability(datum/species/owner_species, mob/living/owner_mob)
	return owner_species.mutantliver

// alien livers can ignore up to 15u of toxins, but they take x3 liver damage
/obj/item/organ/liver/alien
	name = "alien liver" // doesnt matter for actual aliens because they dont take toxin damage
	desc = "A liver that used to belong to a killer alien, who knows what it used to eat."
	icon_state = "liver-x" // Same sprite as fly-person liver.
	liver_resistance = 0.333 * LIVER_DEFAULT_TOX_RESISTANCE // -66%
	toxTolerance = 15 // complete toxin immunity like xenos have would be too powerful

/obj/item/organ/liver/cybernetic
	name = "basic cybernetic liver"
	desc = "A very basic device designed to mimic the functions of a human liver. Handles toxins slightly worse than an organic liver."
	failing_desc = "seems to be broken."
	icon_state = "liver-c"
	organ_flags = ORGAN_ROBOTIC
	maxHealth = STANDARD_ORGAN_THRESHOLD*0.5
	toxTolerance = 2
	liver_resistance = 0.9 * LIVER_DEFAULT_TOX_RESISTANCE // -10%
	var/emp_vulnerability = 80 //Chance of permanent effects if emp-ed.

/obj/item/organ/liver/cybernetic/emp_act(severity)
	. = ..()
	if(. & EMP_PROTECT_SELF)
		return
	if(!COOLDOWN_FINISHED(src, severe_cooldown)) //So we cant just spam emp to kill people.
		owner.adjustToxLoss(10)
		COOLDOWN_START(src, severe_cooldown, 10 SECONDS)
	if(prob(emp_vulnerability/severity)) //Chance of permanent effects
		organ_flags |= ORGAN_EMP //Starts organ faliure - gonna need replacing soon.

/obj/item/organ/liver/cybernetic/tier2
	name = "cybernetic liver"
	desc = "An electronic device designed to mimic the functions of a human liver. Handles toxins slightly better than an organic liver."
	icon_state = "liver-c-u"
	maxHealth = 1.5 * STANDARD_ORGAN_THRESHOLD
	toxTolerance = 5 //can shrug off up to 5u of toxins
	liver_resistance = 1.2 * LIVER_DEFAULT_TOX_RESISTANCE // +20%
	emp_vulnerability = 40

/obj/item/organ/liver/cybernetic/tier3
	name = "upgraded cybernetic liver"
	desc = "An upgraded version of the cybernetic liver, designed to improve further upon organic livers. It is resistant to alcohol poisoning and is very robust at filtering toxins."
	icon_state = "liver-c-u2"
	alcohol_tolerance = ALCOHOL_RATE * 0.2
	maxHealth = 2 * STANDARD_ORGAN_THRESHOLD
	toxTolerance = 10 //can shrug off up to 10u of toxins
	liver_resistance = 1.5 * LIVER_DEFAULT_TOX_RESISTANCE // +50%
	emp_vulnerability = 20

/obj/item/organ/liver/cybernetic/surplus
	name = "surplus prosthetic liver"
	desc = "A very cheap prosthetic liver, mass produced for low-functioning alcoholics... It looks more like a water filter than \
		an actual liver. \
		Very fragile, absolutely terrible at filtering toxins and substantially weak to alcohol. \
		Offers no protection against EMPs."
	icon_state = "liver-c-s"
	maxHealth = STANDARD_ORGAN_THRESHOLD * 0.35
	alcohol_tolerance = ALCOHOL_RATE * 2 // can barely handle alcohol
	toxTolerance = 1 //basically can't shrug off any toxins
	liver_resistance = 0.75 * LIVER_DEFAULT_TOX_RESISTANCE // -25%
	emp_vulnerability = 100

//surplus organs are so awful that they explode when removed, unless failing
/obj/item/organ/liver/cybernetic/surplus/Initialize(mapload)
	. = ..()
	AddElement(/datum/element/dangerous_organ_removal, /*surgical = */ TRUE)

/obj/item/organ/liver/pod
	name = "pod peroxisome"
	desc = "A small plant-like organ found in podpeople responsible for filtering toxins while aiding in photosynthesis."
	foodtype_flags = PODPERSON_ORGAN_FOODTYPES
	color = COLOR_LIME

/obj/item/organ/liver/pod/handle_chemical(mob/living/carbon/organ_owner, datum/reagent/chem, seconds_per_tick, times_fired)
	. = ..()
	if(. & COMSIG_MOB_STOP_REAGENT_CHECK)
		return
	if(!(organ_owner.mob_biotypes & MOB_PLANT))
		return
	if(chem.type == /datum/reagent/toxin/plantbgone)
		organ_owner.adjustToxLoss(3 * REM * seconds_per_tick)

#undef LIVER_DEFAULT_TOX_TOLERANCE
#undef LIVER_DEFAULT_TOX_RESISTANCE
#undef LIVER_FAILURE_STAGE_SECONDS
