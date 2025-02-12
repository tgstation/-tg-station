/client/proc/makepAI(turf/target in GLOB.mob_list)
	set category = "Admin.Fun"
	set name = "Make pAI"
	set desc = "Specify a location to spawn a pAI device, then specify a key to play that pAI"

	var/list/available = list()
	for(var/mob/player as anything in GLOB.player_list)
		if(player.client && player.key)
			available.Add(player)
	var/mob/choice = tgui_input_list(usr, "Choose a player to play the pAI", "Spawn pAI", sort_names(available))
	if(isnull(choice))
		return

	var/chosen_name = input(choice, "Enter your pAI name:", "pAI Name", "Personal AI") as text|null
	if (isnull(chosen_name))
		return

	if(!isobserver(choice))
		var/confirm = tgui_alert(usr, "[choice.key] isn't ghosting right now. Are you sure you want to yank them out of their body and place them in this pAI?", "Spawn pAI Confirmation", list("Yes", "No"))
		if(confirm != "Yes")
			return
	var/obj/item/pai_card/card = new(target)
	var/mob/living/silicon/pai/pai = new(card)

	pai.name = chosen_name
	pai.real_name = pai.name
	pai.PossessByPlayer(choice.key)
	card.set_personality(pai)
	if(SSpai.candidates[key])
		SSpai.candidates -= key
	BLACKBOX_LOG_ADMIN_VERB("Make pAI")

/**
 * Creates a new pAI.
 *
 * @param {boolean} delete_old - If TRUE, deletes the old pAI.
 */
/mob/proc/make_pai(delete_old)
	var/obj/item/pai_card/card = new(src)
	var/mob/living/silicon/pai/pai = new(card)
	pai.PossessByPlayer(key)
	pai.name = name
	card.set_personality(pai)
	if(delete_old)
		qdel(src)
