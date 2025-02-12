/mob/living/basic/clown
	name = "Clown"
	desc = "A denizen of clown planet."
	icon = 'icons/mob/simple/clown_mobs.dmi'
	icon_state = "clown"
	icon_living = "clown"
	icon_dead = "clown_dead"
	icon_gib = "clown_gib"
	health_doll_icon = "clown" //if >32x32, it will use this generic. for all the huge clown mobs that subtype from this
	mob_biotypes = MOB_ORGANIC|MOB_HUMANOID
	response_disarm_continuous = "gently pushes aside"
	response_disarm_simple = "gently push aside"
	response_harm_continuous = "robusts"
	response_harm_simple = "robust"
	combat_mode = TRUE
	maxHealth = 75
	health = 75
	melee_damage_lower = 10
	melee_damage_upper = 10
	attack_sound = 'sound/items/bikehorn.ogg'
	attacked_sound = 'sound/items/bikehorn.ogg'
	environment_smash = ENVIRONMENT_SMASH_NONE
	basic_mob_flags = DEL_ON_DEATH
	initial_language_holder = /datum/language_holder/clown
	habitable_atmos = list("min_oxy" = 5, "max_oxy" = 0, "min_plas" = 0, "max_plas" = 1, "min_co2" = 0, "max_co2" = 5, "min_n2" = 0, "max_n2" = 0)
	minimum_survivable_temperature = T0C
	maximum_survivable_temperature = (T0C + 100)
	unsuitable_atmos_damage = 10
	unsuitable_heat_damage = 15
	faction = list(FACTION_CLOWN)
	ai_controller = /datum/ai_controller/basic_controller/clown
	speed = 1.4 //roughly close to simpleanimal clowns
	///list of stuff we drop on death
	var/list/loot = list(/obj/effect/mob_spawn/corpse/human/clown)
	///blackboard emote list
	var/list/emotes = list(
		BB_EMOTE_SAY = list("HONK", "Honk!", "Welcome to clown planet!"),
		BB_EMOTE_HEAR = list("honks", "squeaks"),
		BB_EMOTE_SOUND = list('sound/items/bikehorn.ogg'), //WE LOVE TO PARTY
		BB_SPEAK_CHANCE = 5,
	)
	///do we waddle (honk)
	var/waddles = TRUE

/mob/living/basic/clown/Initialize(mapload)
	. = ..()
	AddElement(/datum/element/footstep, footstep_type = FOOTSTEP_MOB_SHOE)
	AddComponent(/datum/component/ai_retaliate_advanced, CALLBACK(src, PROC_REF(retaliate_callback)))
	ai_controller.set_blackboard_key(BB_BASIC_MOB_SPEAK_LINES, emotes)
	//im not putting dynamic humans or whatever its called here because this is the base path of nonhuman clownstrosities
	if(waddles)
		AddElementTrait(TRAIT_WADDLING, INNATE_TRAIT, /datum/element/waddling)
	if(length(loot))
		loot = string_list(loot)
		AddElement(/datum/element/death_drops, loot)

/mob/living/basic/clown/proc/retaliate_callback(mob/living/attacker)
	if (!istype(attacker))
		return
	for (var/mob/living/basic/clown/harbringer in oview(src, 7))
		harbringer.ai_controller.insert_blackboard_key_lazylist(BB_BASIC_MOB_RETALIATE_LIST, attacker)

/mob/living/basic/clown/melee_attack(atom/target, list/modifiers, ignore_cooldown = FALSE)
	if(!istype(target, /obj/item/food/grown/banana/bunch))
		return ..()
	var/obj/item/food/grown/banana/bunch/unripe_bunch = target
	unripe_bunch.start_ripening()
	log_combat(src, target, "explosively ripened")

/mob/living/basic/clown/lube
	name = "Living Lube"
	desc = "A puddle of lube brought to life by the honkmother."
	icon_state = "lube"
	icon_living = "lube"
	response_help_continuous = "dips a finger into"
	response_help_simple = "dip a finger into"
	response_disarm_continuous = "gently scoops and pours aside"
	response_disarm_simple = "gently scoop and pour aside"
	emotes = list(
		BB_EMOTE_SAY = list("HONK", "Honk!", "Welcome to clown planet!"),
		BB_EMOTE_HEAR = list("bubbles", "oozes"),
	)
	waddles = FALSE
	loot = list(
		/obj/effect/spawner/foam_starter/small,
		/obj/item/clothing/mask/gas/clown_hat,
	)

/mob/living/basic/clown/lube/Initialize(mapload)
	. = ..()
	AddElement(/datum/element/lube_walking)

/mob/living/basic/clown/honkling
	name = "Honkling"
	desc = "A divine being sent by the Honkmother to spread joy. It's not dangerous, but it's a bit of a nuisance."
	icon_state = "honkling"
	icon_living = "honkling"
	speed = 1.1
	melee_damage_lower = 1
	melee_damage_upper = 1
	attack_verb_continuous = "cheers up"
	attack_verb_simple = "cheer up"
	loot = list(
		/obj/item/clothing/mask/gas/clown_hat,
		/obj/effect/gibspawner/human,
		/obj/item/soap,
		/obj/item/seeds/banana/bluespace,
	)

/mob/living/basic/clown/honkling/Initialize(mapload)
	. = ..()
	var/static/list/injection_range
	if(!injection_range)
		injection_range = string_numbers_list(list(1, 5))
	AddElement(\
		/datum/element/venomous,\
		/datum/reagent/consumable/laughter,\
		injection_range,\
		injection_flags = INJECT_CHECK_PENETRATE_THICK | INJECT_CHECK_IGNORE_SPECIES,\
	)

/mob/living/basic/clown/fleshclown
	name = "Fleshclown"
	desc = "A being forged out of the pure essence of pranking, cursed into existence by a cruel maker."
	icon_state = "fleshclown"
	icon_living = "fleshclown"
	response_help_continuous = "reluctantly pokes"
	response_help_simple = "reluctantly poke"
	response_disarm_continuous = "sinks his hands into the spongy flesh of"
	response_disarm_simple = "sink your hands into the spongy flesh of"
	response_harm_continuous = "cleanses the world of"
	response_harm_simple = "cleanse the world of"
	maxHealth = 140
	health = 140
	speed = 1
	melee_damage_upper = 15
	attack_verb_continuous = "limply slaps"
	attack_verb_simple = "limply slap"
	obj_damage = 5
	loot = list(
		/obj/effect/gibspawner/human,
		/obj/item/clothing/mask/gas/clown_hat,
		/obj/item/soap,
		/obj/item/clothing/suit/hooded/bloated_human,
	)
	emotes = list(
		BB_EMOTE_SAY = list(
			"HONK",
			"Honk!",
			"I didn't ask for this",
			"I feel constant and horrible pain",
			"I was born out of mirthful pranking but I live in suffering",
			"This body is a merciless and unforgiving prison",
			"YA-HONK!!!",
		),
		BB_EMOTE_HEAR = list("honks", "contemplates its existence"),
		BB_EMOTE_SEE = list("sweats", "jiggles"),
		BB_SPEAK_CHANCE = 5,
	)

/mob/living/basic/clown/fleshclown/Initialize(mapload)
	. = ..()
	ADD_TRAIT(src, TRAIT_VENTCRAWLER_ALWAYS, INNATE_TRAIT)

/mob/living/basic/clown/longface
	name = "Longface"
	desc = "Often found walking into the bar."
	icon_state = "long face"
	icon_living = "long face"
	move_resist = INFINITY
	response_help_continuous = "tries to awkwardly hug"
	response_help_simple = "try to awkwardly hug"
	response_disarm_continuous = "pushes the unwieldy frame of"
	response_disarm_simple = "push the unwieldy frame of"
	response_harm_continuous = "tries to shut up"
	response_harm_simple = "try to shut up"
	maxHealth = 150
	health = 150
	pixel_x = -16
	base_pixel_x = -16
	speed = 3
	melee_damage_lower = 5
	attack_verb_continuous = "YA-HONKs"
	attack_verb_simple = "YA-HONK"
	loot = list(
		/obj/effect/gibspawner/human,
		/obj/item/soap,
		/obj/item/clothing/mask/gas/clown_hat,
	)
	emotes = list(
		BB_EMOTE_SAY = list("YA-HONK!!!"),
		BB_EMOTE_HEAR = list("honks", "squeaks"),
		BB_SPEAK_CHANCE = 60,
	)

/mob/living/basic/clown/clownhulk
	name = "Honk Hulk"
	desc = "A cruel and fearsome clown. Don't make him angry."
	icon_state = "honkhulk"
	icon_living = "honkhulk"
	move_resist = INFINITY
	gender = MALE
	response_help_continuous = "tries desperately to appease"
	response_help_simple = "try desperately to appease"
	response_disarm_continuous = "foolishly pushes"
	response_disarm_simple = "foolishly push"
	response_harm_continuous = "angers"
	response_harm_simple = "anger"
	maxHealth = 400
	health = 400
	pixel_x = -16
	base_pixel_x = -16
	speed = 2
	melee_damage_lower = 15
	melee_damage_upper = 20
	attack_verb_continuous = "pummels"
	attack_verb_simple = "pummel"
	obj_damage = 30
	environment_smash = ENVIRONMENT_SMASH_WALLS
	loot = list(
		/obj/effect/gibspawner/human,
		/obj/item/soap,
		/obj/item/clothing/mask/gas/clown_hat,
	)
	emotes = list(
		BB_EMOTE_SAY = list("HONK", "Honk!", "HAUAUANK!!!", "GUUURRRRAAAHHH!!!"),
		BB_EMOTE_HEAR = list("honks", "grunts"),
		BB_EMOTE_SEE = list("sweats"),
		BB_SPEAK_CHANCE = 5,
	)

/mob/living/basic/clown/clownhulk/chlown
	name = "Chlown"
	desc = "A real lunkhead who somehow gets all the girls."
	icon_state = "chlown"
	icon_living = "chlown"
	gender = MALE
	response_help_continuous = "submits to"
	response_help_simple = "submit to"
	response_disarm_continuous = "tries to assert dominance over"
	response_disarm_simple = "try to assert dominance over"
	response_harm_continuous = "makes a weak beta attack at"
	response_harm_simple = "make a weak beta attack at"
	maxHealth = 500
	health = 500
	speed = -2 //ridicilously fast but i dont even know what this is used for
	armour_penetration = 20
	attack_verb_continuous = "steals the girlfriend of"
	attack_verb_simple = "steal the girlfriend of"
	attack_sound = 'sound/items/airhorn/airhorn2.ogg'
	loot = list(
		/obj/effect/gibspawner/human,
		/obj/effect/spawner/foam_starter/small,
		/obj/item/soap,
		/obj/item/clothing/mask/gas/clown_hat,
	)
	emotes = list(
		BB_EMOTE_SAY = list("HONK", "Honk!", "Bruh", "cheeaaaahhh?"),
		BB_EMOTE_SEE = list("asserts his dominance", "emasculates everyone implicitly"),
		BB_SPEAK_CHANCE = 5,
	)

/mob/living/basic/clown/clownhulk/honkmunculus
	name = "Honkmunculus"
	desc = "A slender wiry figure of alchemical origin."
	icon_state = "honkmunculus"
	icon_living = "honkmunculus"
	response_help_continuous = "skeptically pokes"
	response_help_simple = "skeptically poke"
	response_disarm_continuous = "pushes the unwieldy frame of"
	response_disarm_simple = "push the unwieldy frame of"
	maxHealth = 200
	health = 200
	speed = 1
	melee_damage_lower = 5
	melee_damage_upper = 10
	attack_verb_continuous = "ferociously mauls"
	attack_verb_simple = "ferociously maul"
	environment_smash = ENVIRONMENT_SMASH_NONE
	loot = list(
		/obj/effect/gibspawner/xeno/bodypartless,
		/obj/effect/spawner/foam_starter/small,
		/obj/item/soap,
		/obj/item/clothing/mask/gas/clown_hat,
	)
	emotes = list(
		BB_EMOTE_SAY = list("honk"),
		BB_EMOTE_SEE = list("squirms", "writhes"),
	)

/mob/living/basic/clown/clownhulk/honkmunculus/Initialize(mapload)
	. = ..()
	var/static/list/injection_range
	if(!injection_range)
		injection_range = string_numbers_list(list(1, 5))
	AddElement(\
		/datum/element/venomous,\
		/datum/reagent/peaceborg/confuse,\
		injection_range,\
		injection_flags = INJECT_CHECK_PENETRATE_THICK | INJECT_CHECK_IGNORE_SPECIES,\
	) // I don't really know what a clown is using to inject people but let's assume it doesn't need to penetrate at all

/mob/living/basic/clown/clownhulk/destroyer
	name = "The Destroyer"
	desc = "An ancient being born of arcane honking."
	icon_state = "destroyer"
	icon_living = "destroyer"
	response_disarm_continuous = "bounces off of"
	response_harm_continuous = "bounces off of"
	maxHealth = 400
	health = 400
	speed = 5
	melee_damage_lower = 20
	melee_damage_upper = 40
	armour_penetration = 30
	attack_verb_continuous = "acts out divine vengeance on"
	attack_verb_simple = "act out divine vengeance on"
	obj_damage = 50
	environment_smash = ENVIRONMENT_SMASH_RWALLS
	ai_controller = /datum/ai_controller/basic_controller/clown/murder
	loot = list(
		/obj/effect/gibspawner/human,
		/obj/effect/spawner/foam_starter/small,
		/obj/item/soap,
		/obj/item/clothing/mask/gas/clown_hat,
	)
	emotes = list(
		BB_EMOTE_SAY = list("HONK!!!", "The Honkmother is merciful, so I must act out her wrath.", "parce mihi ad beatus honkmother placet mihi ut peccata committere,", "DIE!!!"),
		BB_EMOTE_HEAR = list("honks", "grunts"),
		BB_EMOTE_SEE = list("sweats"),
		BB_SPEAK_CHANCE = 5,
	)

/mob/living/basic/clown/mutant
	name = "Unknown"
	desc = "Kill it for its own sake."
	icon_state = "mutant"
	icon_living = "mutant"
	move_resist = INFINITY
	response_help_continuous = "reluctantly sinks a finger into"
	response_help_simple = "reluctantly sink a finger into"
	response_disarm_continuous = "squishes into"
	response_disarm_simple = "squish into"
	response_harm_continuous = "squishes into"
	response_harm_simple = "squish into"
	maxHealth = 130
	health = 130
	pixel_x = -16
	base_pixel_x = -16
	speed = -5
	melee_damage_lower = 10
	melee_damage_upper = 20
	attack_verb_continuous = "awkwardly flails at"
	attack_verb_simple = "awkwardly flail at"
	loot = list(
		/obj/effect/gibspawner/generic,
		/obj/effect/gibspawner/generic/animal,
		/obj/effect/gibspawner/human,
		/obj/effect/gibspawner/human/bodypartless,
		/obj/effect/gibspawner/xeno/bodypartless,
		/obj/item/soap,
		/obj/item/clothing/mask/gas/clown_hat,
	)
	emotes = list(
		BB_EMOTE_SAY = list("aaaaaahhhhuuhhhuhhhaaaaa", "AAAaaauuuaaAAAaauuhhh", "huuuuuh... hhhhuuuooooonnnnkk", "HuaUAAAnKKKK"),
		BB_EMOTE_SEE = list("squirms", "writhes", "pulsates", "froths", "oozes"),
		BB_SPEAK_CHANCE = 10,
	)

/mob/living/basic/clown/mutant/slow
	speed = 20

/mob/living/basic/clown/mutant/glutton
	name = "banana glutton"
	desc = "Something that was once a clown"
	icon_state = "glutton"
	icon_living = "glutton"
	health = 200
	mob_size = MOB_SIZE_LARGE
	speed = 1
	melee_damage_lower = 10
	melee_damage_upper = 15
	damage_coeff = list(BRUTE = 1, BURN = 1, TOX = 1, STAMINA = 0, OXY = 1)
	attack_verb_continuous = "slams"
	attack_verb_simple = "slam"
	loot = list(
		/obj/effect/gibspawner/generic,
		/obj/effect/gibspawner/generic/animal,
		/obj/effect/gibspawner/human/bodypartless,
		/obj/effect/gibspawner/xeno/bodypartless,
	)
	emotes = list(
		BB_EMOTE_SAY = list("hey, buddy", "HONK!!!", "H-h-h-H-HOOOOONK!!!!", "HONKHONKHONK!!!", "HEY, BUCKO, GET BACK HERE!!!", "HOOOOOOOONK!!!"),
		BB_EMOTE_SEE = list("jiggles", "wobbles"),
	)
	death_sound = 'sound/misc/sadtrombone.ogg'
	waddles = FALSE
	///This is the list of items we are ready to regurgitate,
	var/list/prank_pouch = list()

/mob/living/basic/clown/mutant/glutton/Initialize(mapload)
	. = ..()
	GRANT_ACTION(/datum/action/cooldown/regurgitate)

	AddElement(/datum/element/swabable, CELL_LINE_TABLE_GLUTTON, CELL_VIRUS_TABLE_GENERIC_MOB, 1, 5)
	var/static/list/food_types = list(
		/obj/item/food/cheesiehonkers,
		/obj/item/food/cornchips,
	)
	AddComponent(/datum/component/tameable, food_types = food_types, tame_chance = 30, bonus_tame_chance = 0)
	AddElement(/datum/element/damage_threshold, 10) //lots of fat to cushion blows.

/mob/living/basic/clown/mutant/glutton/attacked_by(obj/item/item, mob/living/user)
	if(!check_edible(item))
		return ..()
	eat_atom(item)

/mob/living/basic/clown/mutant/glutton/melee_attack(atom/target, list/modifiers, ignore_cooldown = FALSE)
	if(!check_edible(target))
		return ..()
	eat_atom(target)

/mob/living/basic/clown/mutant/glutton/UnarmedAttack(atom/victim, proximity_flag, list/modifiers)
	if(!check_edible(victim))
		return ..()
	eat_atom(victim)

///Returns whether or not the supplied movable atom is edible.
/mob/living/basic/clown/mutant/glutton/proc/check_edible(atom/movable/potential_food)
	if(isliving(potential_food))
		var/mob/living/living_morsel = potential_food
		if(living_morsel.mob_size > MOB_SIZE_SMALL)
			return FALSE
		else
			return TRUE

	if(IS_EDIBLE(potential_food))
		if(prank_pouch.len >= 8)
			to_chat(src, span_warning("Your prank pouch is filled to the brim! You don't think you can swallow any more morsels right now."))
			return FALSE
		return TRUE

///This proc eats the atom, certain funny items are stored directly in the prank pouch while bananas grant a heal based on their potency and the peels are retained in the pouch.
/mob/living/basic/clown/mutant/glutton/proc/eat_atom(atom/movable/eaten_atom)

	var/static/funny_items = list(
		/obj/item/food/pie/cream,
		/obj/item/food/grown/tomato,
		/obj/item/food/meatclown,
	)

	visible_message(span_warning("[src] eats [eaten_atom]!"), span_notice("You eat [eaten_atom]."))
	if(is_type_in_list(eaten_atom, funny_items))
		eaten_atom.forceMove(src)
		prank_pouch += eaten_atom

	else
		if(istype(eaten_atom, /obj/item/food/grown/banana))
			var/obj/item/food/grown/banana/banana_morsel = eaten_atom
			adjustBruteLoss(-banana_morsel.seed.potency * 0.25)
			prank_pouch += banana_morsel.generate_trash(src)

		qdel(eaten_atom)

	playsound(loc,'sound/items/eatfood.ogg', rand(30,50), TRUE)
	flick("glutton_mouth", src)

/mob/living/basic/clown/mutant/glutton/tamed(mob/living/tamer, atom/food)
	buckle_lying = 0
	AddElement(/datum/element/ridable, /datum/component/riding/creature/glutton)

/mob/living/basic/clown/mutant/glutton/Exited(atom/movable/gone, direction)
	. = ..()
	prank_pouch -= gone

///This ability will let you fire one random item from your pouch,
/datum/action/cooldown/regurgitate
	name = "Regurgitate"
	desc = "Regurgitates a single item from the depths of your pouch."
	background_icon_state = "bg_changeling"
	overlay_icon_state = "bg_changeling_border"
	button_icon = 'icons/mob/actions/actions_animal.dmi'
	button_icon_state = "regurgitate"
	check_flags = AB_CHECK_CONSCIOUS|AB_CHECK_INCAPACITATED
	click_to_activate = TRUE

/datum/action/cooldown/regurgitate/set_click_ability(mob/on_who)
	. = ..()
	if(!.)
		return

	to_chat(on_who, span_notice("Your throat muscles tense up. <B>Left-click to regurgitate a funny morsel!</B>"))
	on_who.icon_state = "glutton_tongue"
	on_who.update_appearance(UPDATE_ICON)

/datum/action/cooldown/regurgitate/unset_click_ability(mob/on_who, refund_cooldown = TRUE)
	. = ..()
	if(!.)
		return

	if(refund_cooldown)
		to_chat(on_who, span_notice("Your throat muscles relax."))
	on_who.icon_state = initial(on_who.icon_state)
	on_who.update_appearance(UPDATE_ICON)

/datum/action/cooldown/regurgitate/IsAvailable(feedback = FALSE)
	. = ..()
	if(!.)
		return FALSE

	// Hardcoded to only work with gluttons. Come back next year
	return istype(owner, /mob/living/basic/clown/mutant/glutton)

/datum/action/cooldown/regurgitate/Activate(atom/spit_at)
	StartCooldown(cooldown_time / 4)

	var/mob/living/basic/clown/mutant/glutton/pouch_owner = owner
	if(!length(pouch_owner.prank_pouch))
		pouch_owner.icon_state = initial(pouch_owner.icon_state)
		to_chat(pouch_owner, span_notice("Your prank pouch is empty."))
		return TRUE

	var/obj/item/projected_morsel = pick(pouch_owner.prank_pouch)
	projected_morsel.forceMove(pouch_owner.loc)
	projected_morsel.throw_at(spit_at, 8, 2, pouch_owner)
	flick("glutton_mouth", pouch_owner)
	playsound(pouch_owner, 'sound/misc/soggy.ogg', 75)

	StartCooldown()
	return TRUE

/mob/living/basic/clown/banana
	name = "Clownana"
	desc = "A fusion of clown and banana DNA birthed from a botany experiment gone wrong."
	icon_state = "banana tree"
	icon_living = "banana tree"
	response_disarm_continuous = "peels"
	response_disarm_simple = "peel"
	response_harm_continuous = "peels"
	response_harm_simple = "peel"
	maxHealth = 120
	health = 120
	speed = -1
	loot = list(
		/obj/effect/gibspawner/human,
		/obj/item/seeds/banana,
		/obj/item/soap,
		/obj/item/clothing/mask/gas/clown_hat,
	)
	emotes = list(
		BB_EMOTE_SAY = list("HONK", "Honk!", "YA-HONK!!!"),
		BB_EMOTE_SEE = list("bites into the banana", "plucks a banana off its head", "photosynthesizes"),
		BB_EMOTE_SOUND = list('sound/items/bikehorn.ogg'),
	)

/mob/living/basic/clown/banana/Initialize(mapload)
	. = ..()

	var/static/list/innate_actions = list(
		/datum/action/cooldown/exquisite_bunch,
		/datum/action/cooldown/rustle,
	)
	grant_actions_by_list(innate_actions)

///drops peels around the mob when activated
/datum/action/cooldown/rustle
	name = "Rustle"
	desc = "Shake loose a few banana peels."
	cooldown_time = 8 SECONDS
	button_icon_state = "rustle"
	button_icon = 'icons/mob/actions/actions_clown.dmi'
	background_icon_state = "bg_nature"
	overlay_icon_state = "bg_nature_border"
	///which type of peel to spawn
	var/banana_type = /obj/item/grown/bananapeel
	///How many peels to spawn
	var/peel_amount = 3

/datum/action/cooldown/rustle/Activate(atom/target)
	. = ..()
	var/list/reachable_turfs = list()
	for(var/turf/adjacent_turf in RANGE_TURFS(1, owner.loc))
		if(adjacent_turf == owner.loc || !owner.CanReach(adjacent_turf) || !isopenturf(adjacent_turf))
			continue
		reachable_turfs += adjacent_turf

	var/peels_to_spawn = min(peel_amount, reachable_turfs.len)
	for(var/i in 1 to peels_to_spawn)
		new banana_type(pick_n_take(reachable_turfs))
	playsound(owner, 'sound/mobs/non-humanoids/clown/clownana_rustle.ogg', 60)
	animate(owner, time = 0.1 SECONDS, pixel_w = 6, easing = CUBIC_EASING | EASE_OUT, flags = ANIMATION_PARALLEL|ANIMATION_RELATIVE)
	animate(time = 0.2 SECONDS, pixel_w = -8, easing = CUBIC_EASING, flags = ANIMATION_RELATIVE)
	animate(time = 0.1 SECONDS, pixel_w = 2, easing = CUBIC_EASING | EASE_IN, flags = ANIMATION_RELATIVE)
	StartCooldown()

///spawns a plumb bunch of bananas imbued with mystical power.
/datum/action/cooldown/exquisite_bunch
	name = "Exquisite Bunch"
	desc = "Pluck your finest bunch of bananas from your head. This bunch is especially nutrious to monkeykind. A gentle tap will trigger an explosive ripening process."
	button_icon = 'icons/obj/service/hydroponics/harvest.dmi'
	cooldown_time = 60 SECONDS
	button_icon_state = "banana_bunch"
	background_icon_state = "bg_nature"
	overlay_icon_state = "bg_nature_border"
	///If we are currently activating our ability.
	var/activating = FALSE

/datum/action/cooldown/exquisite_bunch/Trigger(trigger_flags, atom/target)
	if(activating)
		return
	var/bunch_turf = get_step(owner.loc, owner.dir)
	if(!bunch_turf)
		return
	if(!owner.CanReach(bunch_turf) || !isopenturf(bunch_turf))
		owner.balloon_alert(owner, "can't do that here!")
		return
	activating = TRUE
	if(!do_after(owner, 1 SECONDS))
		activating = FALSE
		return
	playsound(owner, 'sound/mobs/non-humanoids/clown/hehe.ogg', 100)
	if(!do_after(owner, 1 SECONDS))
		activating = FALSE
		return
	activating = FALSE
	return ..()

/datum/action/cooldown/exquisite_bunch/Activate(atom/target)
	. = ..()
	new /obj/item/food/grown/banana/bunch(get_step(owner.loc, owner.dir))
	playsound(owner, 'sound/items/bikehorn.ogg', 60)
	addtimer(CALLBACK(GLOBAL_PROC, GLOBAL_PROC_REF(playsound), owner, 'sound/mobs/non-humanoids/clown/hohoho.ogg', 100, 1), 1 SECONDS)
	StartCooldown()
