/datum/disease/transformation
	name = "Transformation"
	max_stages = 5
	spread_text = "Acute"
	spread_flags = DISEASE_SPREAD_SPECIAL
	cure_text = "A coder's love (theoretical)."
	agent = "Shenanigans"
	viable_mobtypes = list(/mob/living/carbon/human, /mob/living/carbon/alien)
	severity = DISEASE_SEVERITY_BIOHAZARD
	stage_prob = 5
	visibility_flags = HIDDEN_SCANNER|HIDDEN_PANDEMIC
	disease_flags = CURABLE
	bypasses_immunity = TRUE
	var/list/stage1 = list("You feel unremarkable.")
	var/list/stage2 = list("You feel boring.")
	var/list/stage3 = list("You feel utterly plain.")
	var/list/stage4 = list("You feel white bread.")
	var/list/stage5 = list("Oh the humanity!")
	var/new_form = /mob/living/carbon/human
	var/bantype
	var/transformed_antag_datum //Do we add a specific antag datum once the transformation is complete?

/datum/disease/transformation/Copy()
	var/datum/disease/transformation/D = ..()
	D.stage1 = stage1.Copy()
	D.stage2 = stage2.Copy()
	D.stage3 = stage3.Copy()
	D.stage4 = stage4.Copy()
	D.stage5 = stage5.Copy()
	D.new_form = D.new_form
	return D


/datum/disease/transformation/stage_act(seconds_per_tick, times_fired)
	. = ..()
	if(!.)
		return

	switch(stage)
		if(1)
			if (length(stage1) && SPT_PROB(stage_prob, seconds_per_tick))
				to_chat(affected_mob, pick(stage1))
		if(2)
			if (length(stage2) && SPT_PROB(stage_prob, seconds_per_tick))
				to_chat(affected_mob, pick(stage2))
		if(3)
			if (length(stage3) && SPT_PROB(stage_prob * 2, seconds_per_tick))
				to_chat(affected_mob, pick(stage3))
		if(4)
			if (length(stage4) && SPT_PROB(stage_prob * 2, seconds_per_tick))
				to_chat(affected_mob, pick(stage4))
		if(5)
			do_disease_transformation(affected_mob)


/datum/disease/transformation/proc/do_disease_transformation(mob/living/affected_mob)
	if(iscarbon(affected_mob) && affected_mob.stat != DEAD)
		if(length(stage5))
			to_chat(affected_mob, pick(stage5))
		if(QDELETED(affected_mob))
			return
		if(HAS_TRAIT_FROM(affected_mob, TRAIT_NO_TRANSFORM, REF(src)))
			return
		ADD_TRAIT(affected_mob, TRAIT_NO_TRANSFORM, REF(src))
		for(var/obj/item/W in affected_mob.get_equipped_items(INCLUDE_POCKETS))
			affected_mob.dropItemToGround(W)
		for(var/obj/item/I in affected_mob.held_items)
			affected_mob.dropItemToGround(I)
		var/mob/living/new_mob = new new_form(affected_mob.loc)
		if(istype(new_mob))
			if(bantype && is_banned_from(affected_mob.ckey, bantype))
				replace_banned_player(new_mob)
			new_mob.set_combat_mode(TRUE)
			if(affected_mob.mind)
				affected_mob.mind.transfer_to(new_mob)
			else
				new_mob.PossessByPlayer(affected_mob.ckey)
		if(transformed_antag_datum)
			new_mob.mind.add_antag_datum(transformed_antag_datum)
		new_mob.name = affected_mob.real_name
		new_mob.real_name = new_mob.name
		qdel(affected_mob)

/datum/disease/transformation/proc/replace_banned_player(mob/living/new_mob) // This can run well after the mob has been transferred, so need a handle on the new mob to kill it if needed.
	set waitfor = FALSE

	var/mob/chosen_one = SSpolling.poll_ghosts_for_target("Do you want to play as [span_notice(affected_mob.real_name)]?", check_jobban = bantype, role = bantype, poll_time = 5 SECONDS, checked_target = affected_mob, alert_pic = affected_mob, role_name_text = "transformation victim")
	if(chosen_one)
		to_chat(affected_mob, span_userdanger("Your mob has been taken over by a ghost! Appeal your job ban if you want to avoid this in the future!"))
		message_admins("[key_name_admin(chosen_one)] has taken control of ([key_name_admin(affected_mob)]) to replace a jobbanned player.")
		affected_mob.ghostize(FALSE)
		affected_mob.PossessByPlayer(chosen_one.ckey)
	else
		to_chat(new_mob, span_userdanger("Your mob has been claimed by death! Appeal your job ban if you want to avoid this in the future!"))
		new_mob.investigate_log("has been killed because there was no one to replace them as a job-banned player.", INVESTIGATE_DEATHS)
		new_mob.death()
		if (!QDELETED(new_mob))
			new_mob.ghostize(can_reenter_corpse = FALSE)

/datum/disease/transformation/jungle_flu
	name = "Jungle Flu"
	cure_text = "Death."
	cures = list(/datum/reagent/medicine/adminordrazine)
	spread_text = "Unknown"
	spread_flags = DISEASE_SPREAD_NON_CONTAGIOUS
	viable_mobtypes = list(/mob/living/carbon/human)
	spreading_modifier = 1
	cure_chance = 0.5
	disease_flags = CAN_CARRY|CAN_RESIST
	desc = "A neutered but still dangerous descendent of the ancient \"Jungle Fever\", victims will eventually genetically backtrack into a primate. \
	Luckily, once turned the new monkey will not gain the rabies-like rage of the fever."
	severity = DISEASE_SEVERITY_BIOHAZARD
	stage_prob = 2
	visibility_flags = NONE
	agent = "Kongey Vibrion M-909"
	new_form = /mob/living/carbon/human/species/monkey

	stage1 = list()
	stage2 = list()
	stage3 = list()
	stage4 = list(
		span_warning("You breathe through your mouth."),
		span_warning("You have a craving for bananas."),
		span_warning("Your back hurts."),
		span_warning("Your mind feels clouded."),
	)
	stage5 = list(span_warning("You feel like monkeying around."))

/datum/disease/transformation/jungle_flu/do_disease_transformation(mob/living/carbon/affected_mob)
	affected_mob.monkeyize()

/datum/disease/transformation/jungle_flu/stage_act(seconds_per_tick, times_fired)
	. = ..()
	if(!.)
		return

	switch(stage)
		if(2)
			if(SPT_PROB(1, seconds_per_tick))
				to_chat(affected_mob, span_notice("Your [pick("arm", "back", "elbow", "head", "leg")] itches."))
		if(3)
			if(SPT_PROB(2, seconds_per_tick))
				to_chat(affected_mob, span_danger("You feel a stabbing pain in your head."))
				affected_mob.adjust_confusion(10 SECONDS)
		if(4)
			if(SPT_PROB(1.5, seconds_per_tick))
				affected_mob.say(pick("Eeee!", "Eeek, ook ook!", "Eee-eeek!", "Ungh, ungh."), forced = "jungle fever")

/datum/disease/transformation/robot
	name = "Robotic Transformation"
	cure_text = "An injection of copper."
	cures = list(/datum/reagent/copper)
	cure_chance = 2.5
	agent = "R2D2 Nanomachines"
	desc = "This disease, actually acute nanomachine infection, converts the victim into a cyborg."
	severity = DISEASE_SEVERITY_BIOHAZARD
	visibility_flags = NONE
	stage1 = list()
	stage2 = list(span_danger("Beep...boop.."), "Your joints feel stiff.")
	stage3 = list(
		span_danger("You can feel something move...inside."),
		span_danger("Your joints feel very stiff."),
		span_warning("Your skin feels loose."),
	)
	stage4 = list(span_danger("You can feel... something...inside you."), span_danger("Your skin feels very loose."),)
	stage5 = list(span_danger("Your skin feels as if it's about to burst off!"))
	new_form = /mob/living/silicon/robot
	infectable_biotypes = MOB_ORGANIC|MOB_UNDEAD|MOB_ROBOTIC
	bantype = JOB_CYBORG

/datum/disease/transformation/robot/stage_act(seconds_per_tick, times_fired)
	. = ..()
	if(!.)
		return

	switch(stage)
		if(3)
			if (SPT_PROB(4, seconds_per_tick))
				affected_mob.say(pick("beep, beep!", "Beep, boop", "Boop...bop"), forced = "robotic transformation")
			if (SPT_PROB(2, seconds_per_tick))
				to_chat(affected_mob, span_danger("You feel a stabbing pain in your head."))
				affected_mob.Unconscious(40)
		if(4)
			if (SPT_PROB(10, seconds_per_tick))
				affected_mob.say(pick("beep, beep!", "Boop bop boop beep.", "I wwwaaannntt tttoo dddiiieeee...", "kkkiiiill mmme"), forced = "robotic transformation")


/datum/disease/transformation/xeno

	name = "Xenomorph Transformation"
	cure_text = "Spaceacillin & Glycerol"
	cures = list(/datum/reagent/medicine/spaceacillin, /datum/reagent/glycerol)
	cure_chance = 2.5
	agent = "Rip-LEY Alien Microbes"
	desc = "This disease changes the victim into a xenomorph."
	severity = DISEASE_SEVERITY_BIOHAZARD
	visibility_flags = NONE
	stage1 = list()
	stage2 = list("Your throat feels scratchy.", span_danger("Kill..."))
	stage3 = list(
		span_danger("You can feel something move...inside."),
		span_danger("Your throat feels very scratchy."),
		span_warning("Your skin feels tight."),
	)
	stage4 = list(
		span_danger("You can feel... something...inside you."),
		span_danger("Your blood boils!"),
		span_danger("Your skin feels very tight."),
	)
	stage5 = list(span_danger("Your skin feels as if it's about to burst off!"))
	new_form = /mob/living/carbon/alien/adult/hunter
	bantype = ROLE_ALIEN


/datum/disease/transformation/xeno/stage_act(seconds_per_tick, times_fired)
	. = ..()
	if(!.)
		return

	switch(stage)
		if(3)
			if(SPT_PROB(2, seconds_per_tick))
				to_chat(affected_mob, span_danger("You feel a stabbing pain in your head."))
				affected_mob.Unconscious(40)
		if(4)
			if(SPT_PROB(10, seconds_per_tick))
				affected_mob.say(pick("Going to... devour you...", "Hsssshhhhh!", "You look delicious."), forced = "xenomorph transformation")


/datum/disease/transformation/slime
	name = "Advanced Mutation Transformation"
	cure_text = "Frost oil"
	cures = list(/datum/reagent/consumable/frostoil)
	cure_chance = 55
	agent = "Advanced Mutation Toxin"
	desc = "This highly concentrated extract converts anything into more of itself."
	severity = DISEASE_SEVERITY_BIOHAZARD
	visibility_flags = NONE
	stage1 = list("You don't feel very well.")
	stage2 = list("Your skin feels a little slimy.")
	stage3 = list(span_danger("Your appendages are melting away."), span_danger("Your limbs begin to lose their shape."))
	stage4 = list(span_danger("You are turning into a slime."))
	stage5 = list(span_danger("You have become a slime."))
	new_form = /mob/living/basic/slime


/datum/disease/transformation/slime/stage_act(seconds_per_tick, times_fired)
	. = ..()
	if(!.)
		return

	switch(stage)
		if(1)
			if(ishuman(affected_mob))
				var/mob/living/carbon/human/human = affected_mob
				if(isjellyperson(human))
					update_stage(5)
		if(3)
			if(ishuman(affected_mob))
				var/mob/living/carbon/human/human = affected_mob
				if(!ismonkey(human) && !isjellyperson(human))
					human.set_species(/datum/species/jelly/slime)

/datum/disease/transformation/slime/do_disease_transformation(mob/living/affected_mob)
	if(affected_mob.client && ishuman(affected_mob)) // if they are a human who's not a monkey and are sentient, then let them have the old fun
		var/mob/living/carbon/human/human = affected_mob
		if(!ismonkey(human))
			new_form = /mob/living/basic/slime/random
	return ..()

/datum/disease/transformation/corgi
	name = "The Barkening"
	cure_text = "Death"
	cures = list(/datum/reagent/medicine/adminordrazine)
	agent = "Fell Doge Majicks"
	desc = "This disease transforms the victim into a corgi."
	severity = DISEASE_SEVERITY_BIOHAZARD
	visibility_flags = NONE
	stage1 = list("BARK.")
	stage2 = list("You feel the need to wear silly hats.")
	stage3 = list(span_danger("Must... eat... chocolate...."), span_danger("YAP"))
	stage4 = list(span_danger("Visions of washing machines assail your mind!"))
	stage5 = list(span_danger("AUUUUUU!!!"))
	new_form = /mob/living/basic/pet/dog/corgi


/datum/disease/transformation/corgi/stage_act(seconds_per_tick, times_fired)
	. = ..()
	if(!.)
		return
	switch(stage)
		if(3)
			if (SPT_PROB(4, seconds_per_tick))
				affected_mob.say(pick("Woof!", "YAP"), forced = "corgi transformation")
		if(4)
			if (SPT_PROB(10, seconds_per_tick))
				affected_mob.say(pick("AUUUUUU", "Bark!"), forced = "corgi transformation")


/datum/disease/transformation/morph
	name = "Gluttony's Blessing"
	cure_text = "Nothing"
	cures = list(/datum/reagent/consumable/nothing)
	agent = "Gluttony's Blessing"
	desc = "A 'gift' from somewhere terrible."
	stage_prob = 10
	severity = DISEASE_SEVERITY_BIOHAZARD
	visibility_flags = NONE
	stage1 = list("Your stomach rumbles.")
	stage2 = list("Your skin feels saggy.")
	stage3 = list(span_danger("Your appendages are melting away."), span_danger("Your limbs begin to lose their shape."))
	stage4 = list(span_danger("You're ravenous."))
	stage5 = list(span_danger("You have become a morph."))
	new_form = /mob/living/basic/morph
	infectable_biotypes = MOB_ORGANIC|MOB_MINERAL|MOB_UNDEAD //magic!
	transformed_antag_datum = /datum/antagonist/morph

/datum/disease/transformation/gondola
	name = "Gondola Transformation"
	cure_text = "Condensed Capsaicin, ingested or injected." //getting pepper sprayed doesn't help
	cures = list(/datum/reagent/consumable/condensedcapsaicin) //beats the hippie crap right out of your system
	cure_chance = 55
	stage_prob = 2.5
	agent = "Tranquility"
	desc = "Consuming the flesh of a Gondola comes at a terrible price."
	severity = DISEASE_SEVERITY_BIOHAZARD
	visibility_flags = NONE
	stage1 = list("You seem a little lighter in your step.")
	stage2 = list("You catch yourself smiling for no reason.")
	stage3 = list(
		span_danger("A cruel sense of calm overcomes you."),
		span_danger("You can't feel your arms!"),
		span_danger("You let go of the urge to hurt clowns."),
	)
	stage4 = list(span_danger("You can't feel your arms. It does not bother you anymore."), span_danger("You forgive the clown for hurting you."))
	stage5 = list(span_danger("You have become a Gondola."))
	new_form = /mob/living/basic/pet/gondola


/datum/disease/transformation/gondola/stage_act(seconds_per_tick, times_fired)
	. = ..()
	if(!.)
		return

	switch(stage)
		if(2)
			if(SPT_PROB(2.5, seconds_per_tick))
				affected_mob.emote("smile")
			if(SPT_PROB(10, seconds_per_tick))
				affected_mob.reagents.add_reagent_list(list(/datum/reagent/pax = 5))
		if(3)
			if(SPT_PROB(2.5, seconds_per_tick))
				affected_mob.emote("smile")
			if(SPT_PROB(10, seconds_per_tick))
				affected_mob.reagents.add_reagent_list(list(/datum/reagent/pax = 5))
		if(4)
			if(SPT_PROB(2.5, seconds_per_tick))
				affected_mob.emote("smile")
			if(SPT_PROB(10, seconds_per_tick))
				affected_mob.reagents.add_reagent_list(list(/datum/reagent/pax = 5))
			if(SPT_PROB(1, seconds_per_tick))
				var/obj/item/held_item = affected_mob.get_active_held_item()
				if(held_item)
					to_chat(affected_mob, span_danger("You let go of what you were holding."))
					affected_mob.dropItemToGround(held_item)
