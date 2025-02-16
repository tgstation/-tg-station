/mob/living/basic/pet/cat/cak
	name = "Keeki"
	desc = "She is a cat made out of cake."
	icon_state = "cak"
	icon_living = "cak"
	icon_dead = "cak_dead"
	health = 50
	maxHealth = 50
	gender = FEMALE
	butcher_results = list(
		/obj/item/organ/brain = 1,
		/obj/item/organ/heart = 1,
		/obj/item/food/cakeslice/birthday = 3,
		/obj/item/food/meat/slab = 2
	)
	response_harm_continuous = "takes a bite out of"
	response_harm_simple = "take a bite out of"
	ai_controller = /datum/ai_controller/basic_controller/cat/cake
	attacked_sound = 'sound/items/eatfood.ogg'
	death_message = "loses her false life and collapses!"
	death_sound = SFX_BODYFALL
	held_state = "cak"
	can_interact_with_stove = TRUE

/mob/living/basic/pet/cat/cak/Initialize(mapload)
	. = ..()
	AddComponent(/datum/component/regenerator,\
		regeneration_delay = 1 SECONDS,\
		brute_per_second = 5,\
		outline_colour = COLOR_PINK,\
	)
	var/static/list/on_consume = list(
		/datum/reagent/consumable/nutriment = 0.4,
		/datum/reagent/consumable/nutriment/vitamin = 0.4,
	)
	AddElement(/datum/element/consumable_mob, reagents_list = on_consume)

/mob/living/basic/pet/cat/cak/add_cell_sample()
	return

/mob/living/basic/pet/cat/cak/on_craft_completion(list/components, datum/crafting_recipe/current_recipe, atom/crafter)
	. = ..()
	var/obj/item/organ/brain/candidate = locate(/obj/item/organ/brain) in contents
	if(isnull(candidate?.brainmob?.mind))
		return
	var/datum/mind/candidate_mind = candidate.brainmob.mind
	candidate_mind.transfer_to(src)
	candidate_mind.grab_ghost()
	to_chat(src, "[span_boldbig("You are a cak!")]<b> You're a harmless cat/cake hybrid that everyone loves. People can take bites out of you if they're hungry, but you regenerate health \
	so quickly that it generally doesn't matter. You're remarkably resilient to any damage besides this and it's hard for you to really die at all. You should go around and bring happiness and \
	free cake to the station!</b>")
	var/default_name = initial(name)
	var/new_name = sanitize_name(reject_bad_text(tgui_input_text(src, "You are \the [src]. Would you like to change your name to something else?", "Name change", default_name, MAX_NAME_LEN)), cap_after_symbols = FALSE)
	if(new_name)
		to_chat(src, span_notice("Your name is now <b>[new_name]</b>!"))
		name = new_name

/mob/living/basic/pet/cat/cak/spin(spintime, speed)
	. = ..()
	for(var/obj/item/food/donut/target in oview(1, src))
		if(!target.is_decorated)
			target.decorate_donut()
