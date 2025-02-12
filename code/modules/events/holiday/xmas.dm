/obj/item/toy/xmas_cracker
	name = "xmas cracker"
	icon = 'icons/obj/holiday/christmas.dmi'
	icon_state = "cracker"
	desc = "Directions for use: Requires two people, one to pull each end."
	w_class = WEIGHT_CLASS_TINY
	/// The crack state of the toy. If set to TRUE, you can no longer crack it by attacking.
	var/cracked = FALSE

/obj/item/toy/xmas_cracker/attack(mob/target, mob/user)
	if( !cracked && ishuman(target) && (target.stat == CONSCIOUS) && !target.get_active_held_item() )
		target.visible_message(span_notice("[user] and [target] pop \an [src]! *pop*"), span_notice("You pull \an [src] with [target]! *pop*"), span_hear("You hear a pop."))
		var/obj/item/paper/joke_paper = new /obj/item/paper(user.loc)
		joke_paper.name = "[pick("awful","terrible","unfunny")] joke"
		joke_paper.add_raw_text(pick("What did one snowman say to the other?\n\n<i>'Is it me or can you smell carrots?'</i>",
			"Why couldn't the snowman get laid?\n\n<i>He was frigid!</i>",
			"Where are Santa's helpers educated?\n\n<i>Nowhere, they're ELF-taught.</i>",
			"What happened to the man who stole advent calanders?\n\n<i>He got 25 days.</i>",
			"What does Santa get when he gets stuck in a chimney?\n\n<i>Claus-trophobia.</i>",
			"Where do you find chili beans?\n\n<i>The north pole.</i>",
			"What do you get from eating tree decorations?\n\n<i>Tinsilitis!</i>",
			"What do snowmen wear on their heads?\n\n<i>Ice caps!</i>",
			"Why is Christmas just like life on ss13?\n\n<i>You do all the work and the fat guy gets all the credit.</i>",
			"Why doesn't Santa have any children?\n\n<i>Because he only comes down the chimney.</i>"))
		joke_paper.update_appearance()
		new /obj/item/clothing/head/costume/festive(target.loc)
		user.update_icons()
		cracked = TRUE
		icon_state = "cracker1"
		var/obj/item/toy/xmas_cracker/other_half = new /obj/item/toy/xmas_cracker(target)
		other_half.cracked = 1
		other_half.icon_state = "cracker2"
		target.put_in_active_hand(other_half)
		playsound(user, 'sound/effects/snap.ogg', 50, TRUE)
		return TRUE
	return ..()

/obj/item/clothing/head/costume/festive
	name = "festive paper hat"
	icon_state = "xmashat"
	desc = "A crappy paper hat that you are REQUIRED to wear."
	flags_inv = 0
	armor_type = /datum/armor/none
	dog_fashion = /datum/dog_fashion/head/festive

/obj/effect/spawner/xmastree
	name = "christmas tree spawner"
	icon = 'icons/effects/landmarks_static.dmi'
	icon_state = "x2"
	layer = FLY_LAYER
	plane = ABOVE_GAME_PLANE

	/// Christmas tree, no presents included.
	var/festive_tree = /obj/structure/flora/tree/pine/xmas
	/// Christmas tree, presents included.
	var/christmas_tree = /obj/structure/flora/tree/pine/xmas/presents

/obj/effect/spawner/xmastree/Initialize(mapload)
	. = ..()
	if(check_holidays(CHRISTMAS) && christmas_tree)
		new christmas_tree(get_turf(src))
	else if(check_holidays(FESTIVE_SEASON) && festive_tree)
		new festive_tree(get_turf(src))

/obj/effect/spawner/xmastree/rdrod
	name = "festivus pole spawner"
	festive_tree = /obj/structure/festivus
	christmas_tree = null

/datum/round_event_control/santa
	name = "Visit by Santa"
	holidayID = CHRISTMAS
	typepath = /datum/round_event/ghost_role/santa
	weight = 20
	max_occurrences = 1
	earliest_start = 30 MINUTES
	category = EVENT_CATEGORY_HOLIDAY
	description = "Spawns Santa, who shall roam the station, handing out gifts."

/datum/round_event/ghost_role/santa
	role_name = "Santa"
	var/mob/living/carbon/human/santa //who is our santa?

/datum/round_event/ghost_role/santa/announce(fake)
	priority_announce("Santa is coming to town!", "Unknown Transmission")

/datum/round_event/ghost_role/santa/start()
	var/mob/chosen_one = SSpolling.poll_ghost_candidates("Santa is coming to town! Do you want to be [span_notice("Santa")]?", poll_time = 15 SECONDS, alert_pic = /obj/item/clothing/head/costume/santa, role_name_text = "Santa", amount_to_pick = 1)
	if(isnull(chosen_one))
		return NOT_ENOUGH_PLAYERS
	santa = new /mob/living/carbon/human(pick(GLOB.blobstart))
	santa.PossessByPlayer(chosen_one.key)
	var/datum/antagonist/santa/A = new
	santa.mind.add_antag_datum(A)
