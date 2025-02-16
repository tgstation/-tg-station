//Suits for the pink and grey skeletons! //EVA version no longer used in favor of the Jumpsuit version

/obj/item/clothing/suit/space/eva/plasmaman
	name = "EVA plasma envirosuit"
	desc = "A special plasma containment suit designed to be space-worthy, as well as worn over other clothing. Like its smaller counterpart, it can automatically extinguish the wearer in a crisis, and holds twice as many charges."
	allowed = list(/obj/item/gun, /obj/item/ammo_casing, /obj/item/ammo_casing, /obj/item/melee/baton, /obj/item/melee/energy/sword, /obj/item/restraints/handcuffs, /obj/item/tank)
	armor_type = /datum/armor/eva_plasmaman
	resistance_flags = FIRE_PROOF
	icon_state = "plasmaman_suit"
	inhand_icon_state = "plasmaman_suit"
	fishing_modifier = 0
	COOLDOWN_DECLARE(extinguish_timer)
	var/extinguish_cooldown = 100
	var/extinguishes_left = 10

/datum/armor/eva_plasmaman
	bio = 100
	fire = 100
	acid = 75

/obj/item/clothing/suit/space/eva/plasmaman/examine(mob/user)
	. = ..()
	. += span_notice("There [extinguishes_left == 1 ? "is" : "are"] [extinguishes_left] extinguisher charge\s left in this suit.")

/obj/item/clothing/suit/space/eva/plasmaman/equipped(mob/living/user, slot)
	. = ..()
	if (slot & ITEM_SLOT_OCLOTHING)
		RegisterSignals(user, list(COMSIG_MOB_EQUIPPED_ITEM, COMSIG_LIVING_IGNITED, SIGNAL_ADDTRAIT(TRAIT_HEAD_ATMOS_SEALED)), PROC_REF(check_fire_state))
		check_fire_state()

/obj/item/clothing/suit/space/eva/plasmaman/dropped(mob/living/user)
	. = ..()
	UnregisterSignal(user, list(COMSIG_MOB_EQUIPPED_ITEM, COMSIG_LIVING_IGNITED, SIGNAL_ADDTRAIT(TRAIT_HEAD_ATMOS_SEALED)))

/obj/item/clothing/suit/space/eva/plasmaman/proc/check_fire_state(datum/source)
	SIGNAL_HANDLER

	if (!ishuman(loc))
		return

	// This is weird but basically we're calling this proc once the cooldown ends in case our wearer gets set on fire again during said cooldown
	// This is why we're ignoring source and instead checking by loc
	var/mob/living/carbon/human/owner = loc
	if (!owner.on_fire || !owner.is_atmos_sealed(additional_flags = PLASMAMAN_PREVENT_IGNITION, check_hands = TRUE, alt_flags = TRUE))
		return

	if (!extinguishes_left || !COOLDOWN_FINISHED(src, extinguish_timer))
		return

	extinguishes_left -= 1
	COOLDOWN_START(src, extinguish_timer, extinguish_cooldown)
	// Check if our (possibly other) wearer is on fire once the cooldown ends
	addtimer(CALLBACK(src, PROC_REF(check_fire_state)), extinguish_cooldown)
	owner.visible_message(span_warning("[owner]'s suit automatically extinguishes [owner.p_them()]!"), span_warning("Your suit automatically extinguishes you."))
	owner.extinguish_mob()
	new /obj/effect/particle_effect/water(get_turf(owner))

/obj/item/clothing/suit/space/eva/plasmaman/item_interaction(mob/living/user, obj/item/tool, list/modifiers)
	if (!istype(tool, /obj/item/extinguisher_refill))
		return

	if (extinguishes_left == 5)
		to_chat(user, span_notice("The inbuilt extinguisher is full."))
		return ITEM_INTERACT_BLOCKING

	extinguishes_left = 5
	to_chat(user, span_notice("You refill the suit's built-in extinguisher, using up the cartridge."))
	check_fire_state()
	qdel(tool)
	return ITEM_INTERACT_SUCCESS

//I just want the light feature of helmets
/obj/item/clothing/head/helmet/space/plasmaman
	name = "plasma envirosuit helmet"
	desc = "A special containment helmet that allows plasma-based lifeforms to exist safely in an oxygenated environment. It is space-worthy, and may be worn in tandem with other EVA gear."
	icon = 'icons/obj/clothing/head/plasmaman_hats.dmi'
	worn_icon = 'icons/mob/clothing/head/plasmaman_head.dmi'
	clothing_flags = STOPSPRESSUREDAMAGE | THICKMATERIAL | SNUG_FIT | STACKABLE_HELMET_EXEMPT | PLASMAMAN_PREVENT_IGNITION | HEADINTERNALS
	icon_state = "plasmaman-helm"
	inhand_icon_state = "plasmaman-helm"
	strip_delay = 80
	flash_protect = FLASH_PROTECTION_WELDER
	tint = 2
	armor_type = /datum/armor/space_plasmaman
	resistance_flags = FIRE_PROOF
	light_system = OVERLAY_LIGHT_DIRECTIONAL
	light_range = 4
	light_power = 0.8
	light_color = "#ffcc99"
	light_on = FALSE
	fishing_modifier = 0
	actions_types = list(/datum/action/item_action/toggle_helmet_light, /datum/action/item_action/toggle_welding_screen)
	visor_vars_to_toggle = VISOR_FLASHPROTECT | VISOR_TINT
	flags_inv = HIDEMASK|HIDEEARS|HIDEEYES|HIDEFACE|HIDEHAIR|HIDEFACIALHAIR|HIDESNOUT
	flags_cover = HEADCOVERSMOUTH|HEADCOVERSEYES|PEPPERPROOF
	visor_flags_inv = HIDEEYES|HIDEFACE
	slowdown = 0
	visor_dirt = null
	var/helmet_on = FALSE
	var/smile = FALSE
	var/smile_color = COLOR_RED
	var/visor_icon = "envisor"
	var/smile_state = "envirohelm_smile"

/datum/armor/space_plasmaman
	bio = 100
	fire = 100
	acid = 75

/obj/item/clothing/head/helmet/space/plasmaman/Initialize(mapload)
	. = ..()
	visor_toggling()
	update_appearance()
	register_context()

/obj/item/clothing/head/helmet/space/plasmaman/add_stabilizer(loose_hat = FALSE)
	..()

/obj/item/clothing/head/helmet/space/plasmaman/add_context(atom/source, list/context, obj/item/held_item, mob/living/user)
	context[SCREENTIP_CONTEXT_ALT_LMB] = "Toggle Welding Screen"
	if(istype(held_item, /obj/item/toy/crayon))
		context[SCREENTIP_CONTEXT_LMB] = "Vandalize"

	return CONTEXTUAL_SCREENTIP_SET

/obj/item/clothing/head/helmet/space/plasmaman/click_alt(mob/user)
	if(user.can_perform_action(src))
		adjust_visor(user)

/obj/item/clothing/head/helmet/space/plasmaman/ui_action_click(mob/user, action)
	if(istype(action, /datum/action/item_action/toggle_welding_screen))
		adjust_visor(user)
		return

	return ..()

/obj/item/clothing/head/helmet/space/plasmaman/adjust_visor(mob/living/user)
	. = ..()
	if(!.)
		return
	if(helmet_on)
		to_chat(user, span_notice("Your helmet's torch can't pass through your welding visor!"))
		set_light_on(FALSE)
		helmet_on = FALSE
	playsound(src, up ? SFX_VISOR_UP : SFX_VISOR_DOWN, 50, TRUE)
	update_appearance()

/obj/item/clothing/head/helmet/space/plasmaman/update_icon_state()
	. = ..()
	icon_state = "[initial(icon_state)][helmet_on ? "-light":""]"
	inhand_icon_state = icon_state

/obj/item/clothing/head/helmet/space/plasmaman/update_overlays()
	. = ..()
	if(!up)
		. += visor_icon
	if(smile)
		var/mutable_appearance/smiley = mutable_appearance(icon, smile_state)
		smiley.color = smile_color
		. += smiley

/obj/item/clothing/head/helmet/space/plasmaman/item_interaction(mob/living/user, obj/item/tool, list/modifiers)
	if(!istype(tool, /obj/item/toy/crayon))
		return NONE

	if(smile)
		to_chat(user, span_warning("Seems like someone already drew something on [src]'s visor!"))
		return ITEM_INTERACT_BLOCKING

	var/obj/item/toy/crayon/crayon = tool
	to_chat(user, span_notice("You start drawing a smiley face on [src]'s visor..."))
	if(!do_after(user, 2.5 SECONDS, target = src))
		return ITEM_INTERACT_BLOCKING

	smile = TRUE
	smile_color = crayon.paint_color
	to_chat(user, "You draw a smiley on [src] visor.")
	update_appearance()
	return ITEM_INTERACT_SUCCESS

///By the by, helmets have the update_icon_updates_onmob element, so we don't have to call mob.update_worn_head()
/obj/item/clothing/head/helmet/space/plasmaman/worn_overlays(mutable_appearance/standing, isinhands)
	. = ..()
	if(!isinhands && smile)
		var/mutable_appearance/smiley = mutable_appearance('icons/mob/clothing/head/plasmaman_head.dmi', smile_state)
		smiley.color = smile_color
		. += smiley
	if(!isinhands && !up)
		. += mutable_appearance('icons/mob/clothing/head/plasmaman_head.dmi', visor_icon)
	else
		cut_overlays()

/obj/item/clothing/head/helmet/space/plasmaman/wash(clean_types)
	. = ..()
	if(smile && (clean_types & CLEAN_TYPE_HARD_DECAL))
		smile = FALSE
		update_appearance()
		return TRUE

/obj/item/clothing/head/helmet/space/plasmaman/attack_self(mob/user)
	helmet_on = !helmet_on
	update_appearance()

	if(helmet_on)
		if(!up)
			to_chat(user, span_notice("Your helmet's torch can't pass through your welding visor!"))
			set_light_on(FALSE)
		else
			set_light_on(TRUE)
	else
		set_light_on(FALSE)

	update_item_action_buttons()

/obj/item/clothing/head/helmet/space/plasmaman/on_saboteur(datum/source, disrupt_duration)
	. = ..()
	if(!helmet_on)
		return FALSE
	helmet_on = FALSE
	update_appearance()
	return TRUE

/obj/item/clothing/head/helmet/space/plasmaman/security
	name = "security plasma envirosuit helmet"
	desc = "A plasmaman containment helmet designed for security officers, protecting them from burning alive, alongside other undesirables."
	icon_state = "security_envirohelm"
	inhand_icon_state = null
	armor_type = /datum/armor/head_helmet/plasmaman

/datum/armor/head_helmet/plasmaman
	bio = 100
	fire = 100
	acid = 75

/obj/item/clothing/head/helmet/space/plasmaman/security/detective
	name = "detective's plasma envirosuit helmet"
	desc = "A special containment helmet designed for detectives, protecting them from burning alive, alongside other undesirables."
	icon_state = "white_envirohelm"
	inhand_icon_state = null
	armor_type = /datum/armor/fedora_det_hat/plasmaman

/datum/armor/fedora_det_hat/plasmaman
	bio = 100
	fire = 100
	acid = 75

/obj/item/clothing/head/helmet/space/plasmaman/security/warden
	name = "warden's plasma envirosuit helmet"
	desc = "A plasmaman containment helmet designed for the warden. A pair of white stripes being added to differeciate them from other members of security."
	icon_state = "warden_envirohelm"
	inhand_icon_state = null
	armor_type = /datum/armor/hats_warden/plasmaman

/datum/armor/hats_warden/plasmaman
	bio = 100
	fire = 100
	acid = 75

/obj/item/clothing/head/helmet/space/plasmaman/security/head_of_security
	name = "head of security's plasma envirosuit helmet"
	desc = "A special containment helmet designed for the Head of Security. A pair of gold stripes are added to differentiate them from other members of security."
	icon_state = "hos_envirohelm"
	inhand_icon_state = null
	armor_type = /datum/armor/hats_hos/plasmaman

/datum/armor/hats_hos/plasmaman
	bio = 100
	fire = 100
	acid = 75

/obj/item/clothing/head/helmet/space/plasmaman/prisoner
	name = "prisoner's plasma envirosuit helmet"
	desc = "A plasmaman containment helmet for prisoners."
	icon_state = "prisoner_envirohelm"
	inhand_icon_state = null

/obj/item/clothing/head/helmet/space/plasmaman/medical
	name = "medical doctor's plasma envirosuit helmet"
	desc = "An envirohelmet designed for plasmaman medical doctors, having two stripes down its length to denote as much."
	icon_state = "doctor_envirohelm"
	inhand_icon_state = null

/obj/item/clothing/head/helmet/space/plasmaman/coroner
	name = "coroners's plasma envirosuit helmet"
	desc = "An envirohelmet designed for plasmaman coroners, having more edge than the usual model."
	icon_state = "coroner_envirohelm"
	inhand_icon_state = null

/obj/item/clothing/head/helmet/space/plasmaman/paramedic
	name = "paramedic plasma envirosuit helmet"
	desc = "An envirohelmet designed for plasmaman paramedics, with darker blue stripes compared to the medical model."
	icon_state = "paramedic_envirohelm"
	inhand_icon_state = null

/obj/item/clothing/head/helmet/space/plasmaman/viro
	name = "virology plasma envirosuit helmet"
	desc = "The helmet worn by the safest people on the station, those who are completely immune to the monstrosities they create."
	icon_state = "virologist_envirohelm"
	inhand_icon_state = null

/obj/item/clothing/head/helmet/space/plasmaman/chemist
	name = "chemistry plasma envirosuit helmet"
	desc = "A plasmaman envirosuit designed for chemists, two orange stripes going down its face."
	icon_state = "chemist_envirohelm"
	inhand_icon_state = null

/obj/item/clothing/head/helmet/space/plasmaman/chief_medical_officer
	name = "chief medical officer's plasma envirosuit helmet"
	desc = "A special containment helmet designed for the Chief Medical Officer. A gold stripe applied to differentiate them from other medical staff."
	icon_state = "cmo_envirohelm"
	inhand_icon_state = null

/obj/item/clothing/head/helmet/space/plasmaman/science
	name = "science plasma envirosuit helmet"
	desc = "A plasmaman envirohelmet designed for scientists."
	icon_state = "scientist_envirohelm"
	inhand_icon_state = null

/obj/item/clothing/head/helmet/space/plasmaman/robotics
	name = "robotics plasma envirosuit helmet"
	desc = "A plasmaman envirohelmet designed for roboticists."
	icon_state = "roboticist_envirohelm"
	inhand_icon_state = null

/obj/item/clothing/head/helmet/space/plasmaman/genetics
	name = "geneticist's plasma envirosuit helmet"
	desc = "A plasmaman envirohelmet designed for geneticists."
	icon_state = "geneticist_envirohelm"
	inhand_icon_state = null

/obj/item/clothing/head/helmet/space/plasmaman/research_director
	name = "research director's plasma envirosuit helmet"
	desc = "A special containment helmet designed for the Research Director. A light brown design is applied to differentiate them from other scientists."
	icon_state = "rd_envirohelm"
	inhand_icon_state = null

/obj/item/clothing/head/helmet/space/plasmaman/engineering
	name = "engineering plasma envirosuit helmet"
	desc = "A space-worthy helmet specially designed for engineer plasmamen, the usual purple stripes being replaced by engineering's orange."
	icon_state = "engineer_envirohelm"
	inhand_icon_state = null
	armor_type = /datum/armor/space_plasmaman/engineering_atmos

/datum/armor/space_plasmaman/engineering_atmos
	acid = 95

/obj/item/clothing/head/helmet/space/plasmaman/atmospherics
	name = "atmospherics plasma envirosuit helmet"
	desc = "A space-worthy helmet specially designed for atmos technician plasmamen, the usual purple stripes being replaced by atmos' blue. Has improved thermal shielding."
	icon_state = "atmos_envirohelm"
	inhand_icon_state = null
	armor_type = /datum/armor/space_plasmaman/engineering_atmos
	max_heat_protection_temperature = FIRE_IMMUNITY_MAX_TEMP_PROTECT // Same protection as the Atmospherics Hardhat

/obj/item/clothing/head/helmet/space/plasmaman/chief_engineer
	name = "chief engineer's plasma envirosuit helmet"
	desc = "A special containment helmet designed for the Chief Engineer, the usual purple stripes being replaced by the chief's green. Has improved thermal shielding."
	icon_state = "ce_envirohelm"
	inhand_icon_state = null
	armor_type = /datum/armor/space_plasmaman/engineering_atmos
	max_heat_protection_temperature = FIRE_IMMUNITY_MAX_TEMP_PROTECT // Same protection as the Atmospherics Hardhat

/obj/item/clothing/head/helmet/space/plasmaman/cargo
	name = "cargo plasma envirosuit helmet"
	desc = "A plasmaman envirohelmet designed for cargo techs and quartermasters."
	icon_state = "cargo_envirohelm"
	inhand_icon_state = null

/obj/item/clothing/head/helmet/space/plasmaman/mining
	name = "mining plasma envirosuit helmet"
	desc = "A khaki helmet given to plasmamen miners operating on lavaland."
	icon_state = "explorer_envirohelm"
	inhand_icon_state = null
	visor_icon = "explorer_envisor"

/obj/item/clothing/head/helmet/space/plasmaman/chaplain
	name = "chaplain's plasma envirosuit helmet"
	desc = "An envirohelmet specially designed for only the most pious of plasmamen."
	icon_state = "chap_envirohelm"
	inhand_icon_state = null

/obj/item/clothing/head/helmet/space/plasmaman/white
	name = "white plasma envirosuit helmet"
	desc = "A generic white envirohelm."
	icon_state = "white_envirohelm"
	inhand_icon_state = null

/obj/item/clothing/head/helmet/space/plasmaman/curator
	name = "curator's plasma envirosuit helmet"
	desc = "A slight modification on a traditional voidsuit helmet, this helmet was Nanotrasen's first solution to the *logistical problems* that come with employing plasmamen. Despite their limitations, these helmets still see use by historians and old-school plasmamen alike."
	icon_state = "prototype_envirohelm"
	inhand_icon_state = "void_helmet"
	actions_types = list(/datum/action/item_action/toggle_welding_screen)
	smile_state = "prototype_smile"
	visor_icon = "prototype_envisor"

/obj/item/clothing/head/helmet/space/plasmaman/botany
	name = "botany plasma envirosuit helmet"
	desc = "A green and blue envirohelmet designating its wearer as a botanist. While not specifically designed for it, it would protect against minor plant-related injuries."
	icon_state = "botany_envirohelm"
	inhand_icon_state = null

/obj/item/clothing/head/helmet/space/plasmaman/janitor
	name = "janitor's plasma envirosuit helmet"
	desc = "A grey helmet bearing a pair of purple stripes, designating the wearer as a janitor."
	icon_state = "janitor_envirohelm"
	inhand_icon_state = null

/obj/item/clothing/head/helmet/space/plasmaman/mime
	name = "mime envirosuit helmet"
	desc = "The make-up is painted on, it's a miracle it doesn't chip. It's not very colourful."
	icon_state = "mime_envirohelm"
	inhand_icon_state = null
	visor_icon = "mime_envisor"

/obj/item/clothing/head/helmet/space/plasmaman/clown
	name = "clown envirosuit helmet"
	desc = "The make-up is painted on, it's a miracle it doesn't chip. <i>'HONK!'</i>"
	icon_state = "clown_envirohelm"
	inhand_icon_state = null
	visor_icon = "clown_envisor"
	smile_state = "clown_smile"

/obj/item/clothing/head/helmet/space/plasmaman/clown/Initialize(mapload)
	. = ..()
	AddElement(/datum/element/swabable, CELL_LINE_TABLE_CLOWN, CELL_VIRUS_TABLE_GENERIC, rand(2,3), 0)

/obj/item/clothing/head/helmet/space/plasmaman/head_of_personnel
	name = "head of personnel's envirosuit helmet"
	desc = "A special containment helmet designed for the Head of Personnel. Embarrassingly enough, it looks way too much like the captain's design save for the red stripes."
	icon_state = "hop_envirohelm"
	inhand_icon_state = null
	armor_type = /datum/armor/hats_hopcap/plasmaman

/datum/armor/hats_hopcap/plasmaman
	bio = 100
	fire = 100
	acid = 75

/obj/item/clothing/head/helmet/space/plasmaman/captain
	name = "captain's plasma envirosuit helmet"
	desc = "A special containment helmet designed for the Captain. Embarrassingly enough, it looks way too much like the Head of Personnel's design save for the gold stripes. I mean, come on. Gold stripes can fix anything."
	icon_state = "captain_envirohelm"
	inhand_icon_state = null
	armor_type = /datum/armor/hats_caphat/plasmaman

/datum/armor/hats_caphat/plasmaman
	bio = 100
	fire = 100
	acid = 75

/obj/item/clothing/head/helmet/space/plasmaman/centcom_commander
	name = "CentCom commander plasma envirosuit helmet"
	desc = "A special containment helmet designed for the Higher Central Command Staff. Not many of these exist, as CentCom does not usually employ plasmamen to higher staff positions due to their complications."
	icon_state = "commander_envirohelm"
	inhand_icon_state = null
	armor_type = /datum/armor/hats_centhat/plasmaman

/datum/armor/hats_centhat/plasmaman
	bio = 100
	fire = 100
	acid = 75

/obj/item/clothing/head/helmet/space/plasmaman/centcom_official
	name = "CentCom official plasma envirosuit helmet"
	desc = "A special containment helmet designed for CentCom Staff. They sure do love their green."
	icon_state = "official_envirohelm"
	inhand_icon_state = null

/obj/item/clothing/head/helmet/space/plasmaman/centcom_intern
	name = "CentCom intern plasma envirosuit helmet"
	desc = "A special containment helmet designed for CentCom Staff. You know, so any coffee spills don't kill the poor sod."
	icon_state = "intern_envirohelm"
	inhand_icon_state = null

/obj/item/clothing/head/helmet/space/plasmaman/syndie
	name = "tacticool envirosuit helmet"
	desc = "There's no doubt about it, this helmet puts you above ALL of the other plasmamen. If you see another plasmaman wearing a helmet like this, it's either because they're a fellow badass, \
		or they've murdered one of your fellow badasses and have taken it from them as a trophy. Either way, anyone wearing this deserves at least a cursory nod of respect."
	icon_state = "syndie_envirohelm"
	inhand_icon_state = null

/obj/item/clothing/head/helmet/space/plasmaman/bitrunner
	name = "bitrunner's plasma envirosuit helmet"
	desc = "An envirohelmet with extended blue light filters for bitrunning plasmamen."
	icon_state = "bitrunner_envirohelm"
