/obj/item/clothing/head/hats
	icon = 'icons/obj/clothing/head/hats.dmi'
	worn_icon = 'icons/mob/clothing/head/hats.dmi'

/obj/item/clothing/head/hats/centhat
	name = "\improper CentCom hat"
	icon_state = "centcom"
	desc = "It's good to be emperor."
	inhand_icon_state = "that"
	flags_inv = 0
	armor_type = /datum/armor/hats_centhat
	strip_delay = 80

/datum/armor/hats_centhat
	melee = 30
	bullet = 15
	laser = 30
	energy = 40
	bomb = 25
	fire = 50
	acid = 50

/obj/item/clothing/head/costume/constable
	name = "constable helmet"
	desc = "A British-looking helmet."
	icon_state = "constable"
	inhand_icon_state = null
	custom_price = PAYCHECK_COMMAND * 1.5
	worn_y_offset = 4

/obj/item/clothing/head/costume/spacepolice
	name = "space police cap"
	desc = "A blue cap for patrolling the daily beat."
	icon_state = "policecap_families"
	inhand_icon_state = null

/obj/item/clothing/head/costume/canada
	name = "striped red tophat"
	desc = "It smells like fresh donut holes. / <i>Il sent comme des trous de beignets frais.</i>"
	icon_state = "canada"
	inhand_icon_state = null

/obj/item/clothing/head/costume/redcoat
	name = "redcoat's hat"
	icon_state = "redcoat"
	desc = "<i>'I guess it's a redhead.'</i>"

/obj/item/clothing/head/costume/mailman
	name = "mailman's hat"
	icon_state = "mailman"
	desc = "<i>'Right-on-time'</i> mail service head wear."
	clothing_traits = list(TRAIT_HATED_BY_DOGS)
	custom_premium_price = PAYCHECK_CREW

/obj/item/clothing/head/bio_hood/plague
	name = "plague doctor's hat"
	desc = "These were once used by plague doctors. This hat will only slightly protect you from exposure to the Pestilence."
	icon_state = "plaguedoctor"
	armor_type = /datum/armor/bio_hood_plague
	flags_inv = NONE
	clothing_flags = SNUG_FIT
	flags_cover = NONE
	dirt_state = null

/datum/armor/bio_hood_plague
	bio = 100

/obj/item/clothing/head/costume/nursehat
	name = "nurse's hat"
	desc = "It allows quick identification of trained medical personnel."
	icon_state = "nursehat"
	dog_fashion = /datum/dog_fashion/head/nurse

/obj/item/clothing/head/hats/bowler
	name = "bowler-hat"
	desc = "Gentleman, elite aboard!"
	icon_state = "bowler"
	inhand_icon_state = null

/obj/item/clothing/head/costume/bearpelt
	name = "bear pelt hat"
	desc = "Fuzzy."
	icon_state = "bearpelt"
	inhand_icon_state = null

/obj/item/clothing/head/flatcap
	name = "flat cap"
	desc = "A working man's cap."
	icon_state = "beret_flat"
	icon_preview = 'icons/obj/clothing/head/beret.dmi'
	icon_state_preview = "beret_flat"
	greyscale_config = /datum/greyscale_config/beret
	greyscale_config_worn = /datum/greyscale_config/beret/worn
	greyscale_colors = "#8F7654"
	inhand_icon_state = null

/obj/item/clothing/head/cowboy
	name = "cowboy hat"
	desc = "Ain't nobody gonna cheat the hangman in my town."
	icon = 'icons/obj/clothing/head/cowboy.dmi'
	worn_icon = 'icons/mob/clothing/head/cowboy.dmi'
	icon_state = "cowboy_hat_brown"
	worn_icon_state = "hunter"
	inhand_icon_state = null
	armor_type = /datum/armor/head_cowboy
	resistance_flags = FIRE_PROOF | ACID_PROOF
	/// Chance that the hat will catch a bullet for you
	var/deflect_chance = 2

/obj/item/clothing/head/cowboy/Initialize(mapload)
	. = ..()
	AddComponent(\
		/datum/component/bullet_intercepting,\
		block_chance = deflect_chance,\
		active_slots = ITEM_SLOT_HEAD,\
		on_intercepted = CALLBACK(src, PROC_REF(on_intercepted_bullet)),\
	)

/// When we catch a bullet, fling away
/obj/item/clothing/head/cowboy/proc/on_intercepted_bullet(mob/living/victim, obj/projectile/bullet)
	victim.visible_message(span_warning("\The [bullet] sends [victim]'s hat flying!"))
	victim.dropItemToGround(src, force = TRUE, silent = TRUE)
	throw_at(get_edge_target_turf(loc, pick(GLOB.alldirs)), range = 3, speed = 3)
	playsound(victim, SFX_RICOCHET, 100, TRUE)

/datum/armor/head_cowboy
	melee = 5
	bullet = 5
	laser = 5
	energy = 15

/// Bounty hunter's hat, very likely to intercept bullets
/obj/item/clothing/head/cowboy/bounty
	name = "bounty hunting hat"
	desc = "Reach for the skies, pardner."
	icon_state = "bounty_hunter"
	worn_icon_state = "hunter"
	deflect_chance = 50

/obj/item/clothing/head/cowboy/black
	name = "desperado hat"
	desc = "People with ropes around their necks don't always hang."
	icon_state = "cowboy_hat_black"
	worn_icon_state = "cowboy_hat_black"
	inhand_icon_state = "cowboy_hat_black"

/// More likely to intercept bullets, since you're likely to not be wearing your modsuit with this on
/obj/item/clothing/head/cowboy/black/syndicate
	deflect_chance = 25

/obj/item/clothing/head/cowboy/white
	name = "ten-gallon hat"
	desc = "There are two kinds of people in the world: those with guns and those that dig. You dig?"
	icon_state = "cowboy_hat_white"
	worn_icon_state = "cowboy_hat_white"
	inhand_icon_state = "cowboy_hat_white"

/obj/item/clothing/head/cowboy/grey
	name = "drifter hat"
	desc = "The hat for an assistant with no name."
	icon_state = "cowboy_hat_grey"
	worn_icon_state = "cowboy_hat_grey"
	inhand_icon_state = "cowboy_hat_grey"

/obj/item/clothing/head/cowboy/red
	name = "deputy hat"
	desc = "Don't let the garish coloration fool you. This hat has seen some terrible things."
	icon_state = "cowboy_hat_red"
	worn_icon_state = "cowboy_hat_red"
	inhand_icon_state = "cowboy_hat_red"

/obj/item/clothing/head/cowboy/brown
	name = "sheriff hat"
	desc = "Reach for the skies, pardner."
	icon_state = "cowboy_hat_brown"
	worn_icon_state = "cowboy_hat_brown"
	inhand_icon_state = "cowboy_hat_brown"

/obj/item/clothing/head/costume/santa
	name = "santa hat"
	desc = "On the first day of christmas my employer gave to me!"
	icon_state = "santahatnorm"
	inhand_icon_state = "that"
	cold_protection = HEAD
	min_cold_protection_temperature = FIRE_HELM_MIN_TEMP_PROTECT
	dog_fashion = /datum/dog_fashion/head/santa

/obj/item/clothing/head/costume/santa/gags
	name = "santa hat"
	desc = "On the first day of christmas my employer gave to me!"
	icon_state = "santa_hat"
	greyscale_colors = "#cc0000#f8f8f8"
	greyscale_config = /datum/greyscale_config/santa_hat
	greyscale_config_worn = /datum/greyscale_config/santa_hat/worn
	flags_1 = IS_PLAYER_COLORABLE_1

/obj/item/clothing/head/costume/jester
	name = "jester hat"
	desc = "A hat with bells, to add some merriness to the suit."
	icon_state = "jester_map"
	greyscale_colors = "#00ff00#ff0000"
	greyscale_config = /datum/greyscale_config/jester_hat
	greyscale_config_worn = /datum/greyscale_config/jester_hat/worn
	flags_1 = IS_PLAYER_COLORABLE_1

/obj/item/clothing/head/costume/jesteralt
	name = "jester hat"
	desc = "A hat with bells, to add some merriness to the suit."
	icon_state = "jester2"

/obj/item/clothing/head/costume/rice_hat
	name = "rice hat"
	desc = "Welcome to the rice fields, motherfucker."
	icon_state = "rice_hat"
	base_icon_state = "rice_hat"
	var/reversed = FALSE

/obj/item/clothing/head/costume/rice_hat/click_alt(mob/user)
	reversed = !reversed
	worn_icon_state = "[base_icon_state][reversed ? "_kim" : ""]"
	to_chat(user, span_notice("You [reversed ? "lower" : "raise"] the hat."))
	update_appearance()

/obj/item/clothing/head/costume/lizard
	name = "lizardskin cloche hat"
	desc = "How many lizards died to make this hat? Not enough."
	icon_state = "lizard"

/obj/item/clothing/head/costume/scarecrow_hat
	name = "scarecrow hat"
	desc = "A simple straw hat."
	icon_state = "scarecrow_hat"

/obj/item/clothing/head/costume/pharaoh
	name = "pharaoh hat"
	desc = "Walk like an Egyptian."
	icon_state = "pharoah_hat"
	inhand_icon_state = null

/obj/item/clothing/head/costume/nemes
	name = "headdress of Nemes"
	desc = "Lavish space tomb not included."
	icon_state = "nemes_headdress"

/obj/item/clothing/head/costume/delinquent
	name = "delinquent hat"
	desc = "Good grief."
	icon_state = "delinquent"

/obj/item/clothing/head/hats/intern
	name = "\improper CentCom Head Intern beancap"
	desc = "A horrifying mix of beanie and softcap in CentCom green. You'd have to be pretty desperate for power over your peers to agree to wear this."
	icon_state = "intern_hat"
	inhand_icon_state = null

/obj/item/clothing/head/hats/coordinator
	name = "coordinator cap"
	desc = "A cap for a party coordinator, stylish!."
	icon_state = "capcap"
	inhand_icon_state = "that"
	armor_type = /datum/armor/hats_coordinator

/datum/armor/hats_coordinator
	melee = 25
	bullet = 15
	laser = 25
	energy = 35
	bomb = 25
	fire = 50
	acid = 50

/obj/item/clothing/head/costume/jackbros
	name = "frosty hat"
	desc = "Hee-ho!"
	icon_state = "JackFrostHat"
	inhand_icon_state = null

/obj/item/clothing/head/costume/weddingveil
	name = "wedding veil"
	desc = "A gauzy white veil."
	icon_state = "weddingveil"
	inhand_icon_state = null

/obj/item/clothing/head/hats/centcom_cap
	name = "\improper CentCom commander cap"
	icon_state = "centcom_cap"
	desc = "Worn by the finest of CentCom commanders. Inside the lining of the cap, lies two faint initials."
	inhand_icon_state = "that"
	flags_inv = 0
	armor_type = /datum/armor/hats_centcom_cap
	strip_delay = (8 SECONDS)

/datum/armor/hats_centcom_cap
	melee = 30
	bullet = 15
	laser = 30
	energy = 40
	bomb = 25
	fire = 50
	acid = 50

/obj/item/clothing/head/fedora/human_leather
	name = "human skin hat"
	desc = "This will scare them. All will know my power."
	icon_state = "human_leather"
	inhand_icon_state = null

/obj/item/clothing/head/costume/ushanka
	name = "ushanka"
	desc = "Perfect for winter in Siberia, da?"
	icon_state = "ushankadown"
	inhand_icon_state = null
	flags_inv = HIDEEARS|HIDEHAIR
	cold_protection = HEAD
	min_cold_protection_temperature = FIRE_HELM_MIN_TEMP_PROTECT
	dog_fashion = /datum/dog_fashion/head/ushanka
	var/earflaps = TRUE
	///Sprite visible when the ushanka flaps are folded up.
	var/upsprite = "ushankaup"
	///Sprite visible when the ushanka flaps are folded down.
	var/downsprite = "ushankadown"

/obj/item/clothing/head/costume/ushanka/attack_self(mob/user)
	if(earflaps)
		icon_state = upsprite
		inhand_icon_state = upsprite
		to_chat(user, span_notice("You raise the ear flaps on the ushanka."))
	else
		icon_state = downsprite
		inhand_icon_state = downsprite
		to_chat(user, span_notice("You lower the ear flaps on the ushanka."))
	earflaps = !earflaps

/obj/item/clothing/head/costume/ushanka/polar
	name = "bear hunter's ushanka"
	desc = "Handcrafted in Siberia from real polar bears."
	icon_state = "ushankadown_polar"
	upsprite = "ushankaup_polar"
	downsprite = "ushankadown_polar"

/obj/item/clothing/head/costume/nightcap/blue
	name = "blue nightcap"
	desc = "A blue nightcap for all the dreamers and snoozers out there."
	icon_state = "sleep_blue"

/obj/item/clothing/head/costume/nightcap/red
	name = "red nightcap"
	desc = "A red nightcap for all the sleepyheads and dozers out there."
	icon_state = "sleep_red"

/obj/item/clothing/head/costume/paper_hat
	name = "paper hat"
	desc = "A flimsy hat made of paper."
	icon_state = "paper"
	worn_icon_state = "paper"
	dog_fashion = /datum/dog_fashion/head
