/obj/item/clothing/shoes/cowboy
	name = "cowboy boots"
	desc = "A small sticker lets you know they've been inspected for snakes, It is unclear how long ago the inspection took place..."
	icon_state = "cowboy_brown"
	armor_type = /datum/armor/shoes_cowboy
	custom_price = PAYCHECK_CREW
	can_be_tied = FALSE
	interaction_flags_mouse_drop = NEED_HANDS | NEED_DEXTERITY

	var/max_occupants = 4
	/// Do these boots have spur sounds?
	var/has_spurs = FALSE
	/// The jingle jangle jingle of our spurs
	var/list/spur_sound = list('sound/effects/footstep/spurs1.ogg'=1,'sound/effects/footstep/spurs2.ogg'=1,'sound/effects/footstep/spurs3.ogg'=1)

/datum/armor/shoes_cowboy
	bio = 90

/obj/item/clothing/shoes/cowboy/Initialize(mapload)
	. = ..()
	create_storage(storage_type = /datum/storage/pockets/shoes)
	if(prob(2)) //There's a snake in my boot
		new /mob/living/basic/snake(src)
	if(has_spurs)
		LoadComponent(/datum/component/squeak, spur_sound, 50, falloff_exponent = 20)
	AddElement(/datum/element/ignites_matches)

/obj/item/clothing/shoes/cowboy/equipped(mob/living/carbon/user, slot)
	. = ..()
	RegisterSignal(user, COMSIG_LIVING_SLAM_TABLE, PROC_REF(table_slam), override = TRUE)
	if(slot & ITEM_SLOT_FEET)
		for(var/mob/living/occupant in contents)
			var/target_zone = user.get_random_valid_zone(blacklisted_parts = list(BODY_ZONE_CHEST, BODY_ZONE_HEAD, BODY_ZONE_L_ARM, BODY_ZONE_R_ARM), even_weights = TRUE, bypass_warning = TRUE)
			if(!target_zone) //we broke their legs right on off!
				break
			occupant.forceMove(user.drop_location())
			user.visible_message(span_warning("[user] recoils as something slithers out of [src]."), span_userdanger("You feel a sudden stabbing pain in your [pick("foot", "toe", "ankle")]!"))
			user.Knockdown(20) //Is one second paralyze better here? I feel you would fall on your ass in some fashion.
			occupant.UnarmedAttack(user, proximity_flag = TRUE)

/obj/item/clothing/shoes/cowboy/dropped(mob/living/user)
	. = ..()
	UnregisterSignal(user, COMSIG_LIVING_SLAM_TABLE)

/obj/item/clothing/shoes/cowboy/proc/table_slam(mob/living/source, obj/structure/table/the_table)
	SIGNAL_HANDLER
	INVOKE_ASYNC(src, PROC_REF(handle_table_slam), source)

/obj/item/clothing/shoes/cowboy/proc/handle_table_slam(mob/living/user)
	user.say(pick("Hot damn!", "Hoo-wee!", "Got-dang!"), spans = list(SPAN_YELL), forced=TRUE)
	user.client?.give_award(/datum/award/achievement/misc/hot_damn, user)

/obj/item/clothing/shoes/cowboy/mouse_drop_receive(mob/living/target, mob/living/user, params)
	. = ..()
	if(!(user.mobility_flags & MOBILITY_USE) || !isliving(target))
		return
	if(contents.len >= max_occupants)
		to_chat(user, span_warning("[src] are full!"))
		return
	if(istype(target, /mob/living/basic/snake) || istype(target, /mob/living/basic/headslug) || islarva(target))
		target.forceMove(src)
		to_chat(user, span_notice("[target] slithers into [src]."))

/obj/item/clothing/shoes/cowboy/container_resist_act(mob/living/user)
	if(!do_after(user, 1 SECONDS, target = user))
		return
	user.forceMove(drop_location())

/obj/item/clothing/shoes/cowboy/white
	name = "white cowboy boots"
	icon_state = "cowboy_white"

/obj/item/clothing/shoes/cowboy/black
	name = "black cowboy boots"
	desc = "You get the feeling someone might have been hanged in these boots."
	icon_state = "cowboy_black"

/obj/item/clothing/shoes/cowboy/fancy
	name = "bilton wrangler boots"
	desc = "A pair of authentic haute couture boots from Japanifornia. You doubt they have ever been close to cattle."
	icon_state = "cowboy_fancy"
	armor_type = /datum/armor/cowboy_fancy

/datum/armor/cowboy_fancy
	bio = 95

/obj/item/clothing/shoes/cowboy/lizard
	name = "lizard skin boots"
	desc = "You can hear a faint hissing from inside the boots; you hope it is just a mournful ghost."
	icon_state = "lizardboots_green"
	armor_type = /datum/armor/cowboy_lizard

/datum/armor/cowboy_lizard
	bio = 90
	fire = 40

/obj/item/clothing/shoes/cowboy/lizard/masterwork
	name = "\improper Hugs-The-Feet lizard skin boots"
	desc = "A pair of masterfully crafted lizard skin boots. Finally a good application for the station's most bothersome inhabitants."
	icon_state = "lizardboots_blue"

/// Shoes for the nuke-ops cowboy fit
/obj/item/clothing/shoes/cowboy/black/syndicate
	name = "black spurred cowboy boots"
	desc = "And they sing, oh, ain't you glad you're single? And that song ain't so very far from wrong."
	armor_type = /datum/armor/shoes_combat
	has_spurs = TRUE
	body_parts_covered = FEET|LEGS

// Laced variants for loadout
/obj/item/clothing/shoes/cowboy/laced
	can_be_tied = TRUE

/obj/item/clothing/shoes/cowboy/white/laced
	can_be_tied = TRUE

/obj/item/clothing/shoes/cowboy/black/laced
	can_be_tied = TRUE
