/datum/quirk/nyctophobia
	name = "Nyctophobia"
	desc = "As far as you can remember, you've always been afraid of the dark. While in the dark without a light source, you instinctively act careful, and constantly feel a sense of dread."
	icon = FA_ICON_LIGHTBULB
	value = -3
	medical_record_text = "Patient demonstrates a fear of the dark. (Seriously?)"
	hardcore_value = 5
	mail_goodies = list(/obj/effect/spawner/random/engineering/flashlight)
	no_process_traits = list(TRAIT_MIND_TEMPORARILY_GONE, TRAIT_FEARLESS, TRAIT_KNOCKEDOUT)

/datum/quirk/nyctophobia/add(client/client_source)
	RegisterSignal(quirk_holder, COMSIG_MOVABLE_MOVED, PROC_REF(on_holder_moved))

/datum/quirk/nyctophobia/remove()
	UnregisterSignal(quirk_holder, COMSIG_MOVABLE_MOVED)
	quirk_holder.clear_mood_event("nyctophobia")

/// Called when the quirk holder moves. Updates the quirk holder's mood.
/datum/quirk/nyctophobia/proc/on_holder_moved(mob/living/source, atom/old_loc, dir, forced)
	SIGNAL_HANDLER

	if(quirk_holder.stat != CONSCIOUS || quirk_holder.IsSleeping() || quirk_holder.IsUnconscious())
		return

	if(HAS_TRAIT(quirk_holder, TRAIT_FEARLESS))
		return

	var/mob/living/carbon/human/human_holder = quirk_holder

	if(human_holder.dna?.species.id in list(SPECIES_SHADOW, SPECIES_NIGHTMARE))
		return

	if((human_holder.sight & SEE_TURFS) == SEE_TURFS)
		return

	var/turf/holder_turf = get_turf(quirk_holder)

	var/lums = holder_turf.get_lumcount()

	if(lums > LIGHTING_TILE_IS_DARK)
		quirk_holder.clear_mood_event("nyctophobia")
		return

	if(quirk_holder.move_intent == MOVE_INTENT_RUN)
		to_chat(quirk_holder, span_warning("Easy, easy, take it slow... you're in the dark..."))
		quirk_holder.toggle_move_intent()
	quirk_holder.add_mood_event("nyctophobia", /datum/mood_event/nyctophobia)
