/obj/item/aicard
	name = "intelliCard"
	desc = "A storage device for AIs. Patent pending."
	icon = 'icons/obj/aicards.dmi'
	icon_state = "aicard" // aicard-full
	base_icon_state = "aicard"
	inhand_icon_state = "electronic"
	worn_icon_state = "electronic"
	lefthand_file = 'icons/mob/inhands/items/devices_lefthand.dmi'
	righthand_file = 'icons/mob/inhands/items/devices_righthand.dmi'
	w_class = WEIGHT_CLASS_SMALL
	slot_flags = ITEM_SLOT_BELT
	item_flags = NOBLUDGEON
	var/flush = FALSE
	var/mob/living/silicon/ai/AI

/obj/item/aicard/Initialize(mapload)
	. = ..()
	if(mapload && HAS_TRAIT(SSstation, STATION_TRAIT_HUMAN_AI))
		return INITIALIZE_HINT_QDEL
	ADD_TRAIT(src, TRAIT_CASTABLE_LOC, INNATE_TRAIT)

/obj/item/aicard/Destroy(force)
	if(AI)
		AI.ghostize(can_reenter_corpse = FALSE)
		QDEL_NULL(AI)

	return ..()

/obj/item/aicard/aitater
	name = "intelliTater"
	desc = "A stylish upgrade (?) to the intelliCard."
	icon_state = "aitater"
	base_icon_state = "aitater"

/obj/item/aicard/aispook
	name = "intelliLantern"
	desc = "A spoOoOoky upgrade to the intelliCard."
	icon_state = "aispook"
	base_icon_state = "aispook"

/obj/item/aicard/suicide_act(mob/living/user)
	user.visible_message(span_suicide("[user] is trying to upload [user.p_them()]self into [src]! That's not going to work out well!"))
	return BRUTELOSS

/obj/item/aicard/interact_with_atom(atom/interacting_with, mob/living/user, list/modifiers)
	if(AI)
		if(upload_ai(interacting_with, user))
			return ITEM_INTERACT_SUCCESS
	else
		if(capture_ai(interacting_with, user))
			return ITEM_INTERACT_SUCCESS

	return NONE

/// Tries to get an AI from the atom clicked
/obj/item/aicard/proc/capture_ai(atom/from_what, mob/living/user)
	from_what.transfer_ai(AI_TRANS_TO_CARD, user, null, src)
	if(isnull(AI))
		return FALSE

	log_silicon("[key_name(user)] carded [key_name(AI)]", list(src))
	update_appearance()
	AI.cancel_camera()
	RegisterSignal(AI, COMSIG_MOB_STATCHANGE, PROC_REF(on_ai_stat_change))
	return TRUE

/// Tries to upload the AI we have captured to the atom clicked
/obj/item/aicard/proc/upload_ai(atom/to_what, mob/living/user)
	var/mob/living/silicon/ai/old_ai = AI
	to_what.transfer_ai(AI_TRANS_FROM_CARD, user, AI, src)
	if(!isnull(AI))
		return FALSE

	log_combat(user, old_ai, "uploaded", src, "to [to_what].")
	update_appearance()
	old_ai.cancel_camera()
	UnregisterSignal(old_ai, COMSIG_MOB_STATCHANGE)
	return TRUE

/obj/item/aicard/proc/on_ai_stat_change(datum/source, new_stat, old_stat)
	SIGNAL_HANDLER

	if(new_stat == DEAD || old_stat == DEAD)
		update_appearance()

/obj/item/aicard/update_name(updates)
	. = ..()
	if(AI)
		name = "[initial(name)] - [AI.name]"
	else
		name = initial(name)

/obj/item/aicard/update_icon_state()
	if(AI)
		icon_state = "[base_icon_state][AI.stat == DEAD ? "-404" : "-full"]"
	else
		icon_state = base_icon_state
	return ..()

/obj/item/aicard/update_overlays()
	. = ..()
	if(!AI?.control_disabled)
		return
	. += "[base_icon_state]-on"

/obj/item/aicard/ui_state(mob/user)
	return GLOB.hands_state

/obj/item/aicard/ui_interact(mob/user, datum/tgui/ui)
	ui = SStgui.try_update_ui(user, src, ui)
	if(!ui)
		ui = new(user, src, "Intellicard", name)
		ui.open()

/obj/item/aicard/ui_data()
	var/list/data = list()
	if(AI)
		data["name"] = AI.name
		data["laws"] = AI.laws.get_law_list(include_zeroth = TRUE, render_html = FALSE)
		data["health"] = (AI.health + 100) / 2
		data["wireless"] = !AI.control_disabled //todo disabled->enabled
		data["radio"] = AI.radio_enabled
		data["isDead"] = AI.stat == DEAD
		data["isBraindead"] = AI.client ? FALSE : TRUE
	data["wiping"] = flush
	return data

/obj/item/aicard/ui_act(action,params)
	. = ..()
	if(.)
		return
	switch(action)
		if("wipe")
			if(flush)
				flush = FALSE
			else
				var/confirm = tgui_alert(usr, "Are you sure you want to wipe this card's memory?", name, list("Yes", "No"))
				if(confirm == "Yes" && !..())
					flush = TRUE
					wipe_ai()
			. = TRUE
		if("wireless")
			AI.control_disabled = !AI.control_disabled
			to_chat(AI, span_warning("[src]'s wireless port has been [AI.control_disabled ? "disabled" : "enabled"]!"))
			. = TRUE
		if("radio")
			AI.radio_enabled = !AI.radio_enabled
			to_chat(AI, span_warning("Your Subspace Transceiver has been [AI.radio_enabled ? "enabled" : "disabled"]!"))
			. = TRUE
	update_appearance()

/obj/item/aicard/proc/wipe_ai()
	set waitfor = FALSE

	if(AI && AI.loc == src)
		to_chat(AI, span_userdanger("Your core files are being wiped!"))
		while(AI.stat != DEAD && flush)
			AI.adjustOxyLoss(5)
			AI.updatehealth()
			sleep(0.5 SECONDS)
		flush = FALSE

/obj/item/aicard/used_in_craft(atom/result, datum/crafting_recipe/current_recipe)
	. = ..()
	if(!AI || !istype(result, /obj/item/aicard))
		return
	var/obj/item/aicard/new_card = result
	AI.forceMove(new_card)
	new_card.AI = AI
	new_card.update_appearance()
	AI = null
