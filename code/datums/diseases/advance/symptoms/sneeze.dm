/*Sneezing
 * Reduces stealth
 * Greatly increases resistance
 * No effect to stage speed
 * Increases transmission tremendously
 * Low level
 * Bonus: Forces a spread type of AIRBORNE with extra range!
*/
/datum/symptom/sneeze
	name = "Sneezing"
	desc = "The virus causes irritation of the nasal cavity, making the host sneeze occasionally. Sneezes from this symptom will spread the virus in a 4 meter cone in front of the host."
	illness = "Bard Flu"
	stealth = -2
	resistance = 3
	stage_speed = 0
	transmittable = 4
	level = 1
	severity = 1
	symptom_delay_min = 5
	symptom_delay_max = 35
	required_organ = ORGAN_SLOT_LUNGS
	threshold_descs = list(
		"Transmission 9" = "Increases sneezing range, spreading the virus over 6 meter cone instead of over a 4 meter cone.",
		"Stealth 4" = "The symptom remains hidden until active.",
		"Stage Speed 17" = "The force of each sneeze catapults the host backwards, potentially stunning and lightly damaging them if they hit a wall or another person mid-flight."
	)
	///Emote cooldowns
	COOLDOWN_DECLARE(sneeze_cooldown)
	var/spread_range = 4
	var/cartoon_sneezing = FALSE //ah, ah, AH, AH-CHOO!!
	///if FALSE, there is a percentage chance that the mob will emote sneezing while sneeze_cooldown is on cooldown. If TRUE, won't emote again until after the off cooldown sneeze occurs.
	var/off_cooldown_sneezed = FALSE

/datum/symptom/sneeze/Start(datum/disease/advance/active_disease)
	. = ..()
	if(!.)
		return
	if(active_disease.totalTransmittable() >= 9) //longer spread range
		spread_range = 6
	if(active_disease.totalStealth() >= 4)
		suppress_warning = TRUE
	if(active_disease.totalStageSpeed() >= 17) //Yep, stage speed 17, not stage speed 7. This is a big boy threshold (effect), like the language-scrambling transmission one for the voice change symptom.
		cartoon_sneezing = TRUE //for a really fun time, distribute a disease with this threshold met while the gravity generator is down

/datum/symptom/sneeze/Activate(datum/disease/advance/active_disease)
	. = ..()
	if(!.)
		return
	var/mob/living/affected_mob = active_disease.affected_mob
	switch(active_disease.stage)
		if(1, 2, 3)
			if(!suppress_warning)
				affected_mob.emote("sniff")
		else
			affected_mob.emote("sneeze")
			active_disease.airborne_spread(spread_range = src.spread_range, force_spread = TRUE, require_facing = TRUE)
			if(cartoon_sneezing) //Yeah, this can fling you around even if you have a space suit helmet on. It's, uh, bluespace snot, yeah.
				to_chat(affected_mob, span_userdanger("You are launched violently backwards by an all-mighty sneeze!"))
				var/sneeze_distance = rand(2,4) //twice as far as a normal baseball bat strike will fling you
				var/turf/target = get_ranged_target_turf(affected_mob, REVERSE_DIR(affected_mob.dir), sneeze_distance)
				affected_mob.throw_at(target, sneeze_distance, rand(1,4)) //with the wounds update, sneezing at 7 speed was causing peoples bones to spontaneously explode, turning cartoonish sneezing into a nightmarishly lethal GBS 2.0 outbreak
			else if(COOLDOWN_FINISHED(src, sneeze_cooldown) || !COOLDOWN_FINISHED(src, sneeze_cooldown) && prob(60) && !off_cooldown_sneezed)
				COOLDOWN_START(src, sneeze_cooldown, 5 SECONDS)
				if(!off_cooldown_sneezed && !COOLDOWN_FINISHED(src, sneeze_cooldown))
					off_cooldown_sneezed = TRUE
				else
					off_cooldown_sneezed = FALSE
