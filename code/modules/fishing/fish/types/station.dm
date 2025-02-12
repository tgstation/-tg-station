/obj/item/fish/ratfish
	name = "ratfish"
	fish_id = "ratfish"
	desc = "A rat exposed to the murky waters of maintenance too long. Any higher power, if it revealed itself, would state that the ratfish's continued existence is extremely unwelcome."
	icon_state = "ratfish"
	sprite_width = 7
	sprite_height = 5
	random_case_rarity = FISH_RARITY_RARE
	required_fluid_type = AQUARIUM_FLUID_FRESHWATER
	stable_population = /datum/config_entry/number/mice_roundstart::default //set by New, but this is the default config value
	fillet_type = /obj/item/food/meat/slab/human/mutant/zombie //eww...
	fish_traits = list(/datum/fish_trait/necrophage)
	required_temperature_min = MIN_AQUARIUM_TEMP+15
	required_temperature_max = MIN_AQUARIUM_TEMP+35
	fish_movement_type = /datum/fish_movement/zippy
	favorite_bait = list(
		list(
			FISH_BAIT_TYPE = FISH_BAIT_FOODTYPE,
			FISH_BAIT_VALUE = DAIRY
		)
	)
	beauty = FISH_BEAUTY_DISGUSTING

/obj/item/fish/ratfish/get_fish_taste()
	return list("vermin" = 2, "maintenance" = 1)

/obj/item/fish/ratfish/get_fish_taste_cooked()
	return list("cooked vermin" = 2, "burned fur" = 0.5)

/obj/item/fish/ratfish/get_food_types()
	return MEAT|RAW|GORE //Not-so-quite-seafood

/obj/item/fish/ratfish/get_base_edible_reagents_to_add()
	var/list/return_list = ..()
	return_list[/datum/reagent/rat_spit] = 1
	return return_list

/obj/item/fish/ratfish/Initialize(mapload, apply_qualities = TRUE)
	. = ..()
	//stable pop reflects the config for how many mice migrate. powerful...
	stable_population = CONFIG_GET(number/mice_roundstart)

/obj/item/fish/sludgefish
	name = "sludgefish"
	fish_id = "sludgefish"
	desc = "A misshapen, fragile, loosely fish-like living goop, the only thing that'd ever thrive in the acidic and claustrophobic cavities of the station's organic waste disposal system."
	icon_state = "sludgefish"
	sprite_width = 7
	sprite_height = 6
	required_fluid_type = AQUARIUM_FLUID_SULPHWATEVER
	stable_population = 8
	average_size = 20
	average_weight = 400
	health = 50
	breeding_timeout = 2.5 MINUTES
	fish_traits = list(/datum/fish_trait/parthenogenesis, /datum/fish_trait/no_mating)
	required_temperature_min = MIN_AQUARIUM_TEMP+10
	required_temperature_max = MIN_AQUARIUM_TEMP+40
	evolution_types = list(/datum/fish_evolution/purple_sludgefish)
	beauty = FISH_BEAUTY_NULL

/obj/item/fish/sludgefish/get_fish_taste()
	return list("raw fish" = 2, "eau de toilet" = 1)

/obj/item/fish/sludgefish/purple
	name = "purple sludgefish"
	fish_id = "purple_sludgefish"
	desc = "A misshapen, fragile, loosely fish-like living goop. This one has developed sexual reproduction mechanisms, and a purple tint to boot."
	icon_state = "sludgefish_purple"
	random_case_rarity = FISH_RARITY_NOPE
	fish_traits = list(/datum/fish_trait/parthenogenesis)

/obj/item/fish/slimefish
	name = "aquatic slime"
	fish_id = "slimefish"
	desc = "Kids, this is what happens when a slime overcomes its hydrophobic nature. It goes glug glug."
	icon_state = "slimefish"
	icon_state_dead = "slimefish_dead"
	sprite_width = 7
	sprite_height = 7
	fish_flags = parent_type::fish_flags & ~FISH_DO_FLOP_ANIM //it already has a cute bouncy wiggle. :3
	random_case_rarity = FISH_RARITY_VERY_RARE
	required_fluid_type = AQUARIUM_FLUID_ANADROMOUS
	stable_population = 4
	health = 150
	fillet_type = /obj/item/slime_extract/grey
	fish_traits = list(/datum/fish_trait/toxin_immunity, /datum/fish_trait/crossbreeder)
	favorite_bait = list(
		list(
			FISH_BAIT_TYPE = FISH_BAIT_FOODTYPE,
			FISH_BAIT_VALUE = TOXIC,
		),
		list(
			FISH_BAIT_TYPE = FISH_BAIT_REAGENT,
			FISH_BAIT_VALUE = /datum/reagent/toxin,
			FISH_BAIT_AMOUNT = 5,
		),
	)
	required_temperature_min = MIN_AQUARIUM_TEMP+20
	beauty = FISH_BEAUTY_GREAT

/obj/item/fish/slimefish/get_food_types()
	return SEAFOOD|TOXIC

/obj/item/fish/slimefish/get_base_edible_reagents_to_add()
	return list(/datum/reagent/toxin/slimejelly = 5)

/obj/item/fish/fryish
	name = "fryish"
	fish_id = "fryish"
	desc = "A youngling of the Fritterish family of <u>delicious</u> extremophile, piscine lifeforms. Just don't tell 'Mankind for Ethical Animal Treatment' you ate it."
	icon_state = "fryish"
	sprite_width = 3
	sprite_height = 3
	average_size = 20
	average_weight = 400
	random_case_rarity = FISH_RARITY_VERY_RARE
	required_fluid_type = AQUARIUM_FLUID_ANY_WATER
	stable_population = 8
	fillet_type = /obj/item/food/nugget/fish
	fish_traits = list(/datum/fish_trait/picky_eater, /datum/fish_trait/no_mating)
	compatible_types = list(/obj/item/fish/fryish/fritterish, /obj/item/fish/fryish/nessie)
	spawn_types = list(/obj/item/fish/fryish)
	required_temperature_min = MIN_AQUARIUM_TEMP+50
	required_temperature_max = MIN_AQUARIUM_TEMP+220
	fish_movement_type = /datum/fish_movement/zippy
	favorite_bait = list(
		list(
			FISH_BAIT_TYPE = FISH_BAIT_FOODTYPE,
			FISH_BAIT_VALUE = FRIED,
		)
	)
	disliked_bait = list(
		list(
			FISH_BAIT_TYPE = FISH_BAIT_FOODTYPE,
			FISH_BAIT_VALUE = GROSS|RAW,
		)
	)
	beauty = FISH_BEAUTY_GOOD
	fishing_difficulty_modifier = -5
	///Is this a baitfish?
	var/is_bait = TRUE
	///The evolution datum of the next thing we grow into, given time (and food)
	var/next_type = /datum/fish_evolution/fritterish
	///How long does it take for us to grow up?
	var/growth_time = 3.5 MINUTES

/obj/item/fish/fryish/Initialize(mapload, apply_qualities = TRUE)
	. = ..()
	if(is_bait)
		add_traits(list(TRAIT_FISHING_BAIT, TRAIT_GREAT_QUALITY_BAIT), INNATE_TRAIT)
	ADD_TRAIT(src, TRAIT_FISH_SURVIVE_COOKING, INNATE_TRAIT)

/obj/item/fish/fryish/suicide_act(mob/living/user)
	user.visible_message(span_suicide("[user] swallows [src] whole! It looks like [user.p_theyre()] trying to commit suicide!"))
	user.say("Mmmm! Delicious!", forced = "fryfish suicide")
	qdel(src)
	return OXYLOSS

/obj/item/fish/fryish/update_size_and_weight(new_size = average_size, new_weight = average_weight, update_materials = TRUE)
	. = ..()
	if(!next_type)
		return
	var/multiplier = (size / average_size) * (weight / average_weight)

	AddComponent(/datum/component/fish_growth, next_type, growth_time * multiplier, use_drop_loc = FALSE)

/obj/item/fish/fryish/get_fish_taste()
	return list("fried fish" = 1)

/obj/item/fish/fryish/get_fish_taste_cooked()
	return list("extra-fried fish" = 1)

/obj/item/fish/fryish/get_food_types()
	return FRIED|MEAT|SEAFOOD

/obj/item/fish/fryish/get_base_edible_reagents_to_add()
	var/list/return_list = list(
		/datum/reagent/consumable/nutriment/protein = 2,
		/datum/reagent/consumable/nutriment/fat = 1.5,
	)
	return return_list

#define FISH_FRITTERISH "fritterish"
#define FISH_BERNARD "bernard"
#define FISH_MATTHEW "matthew"

/obj/item/fish/fryish/fritterish
	name = "fritterish"
	fish_id = "fritterish"
	desc = "A <u>deliciously</u> extremophile alien fish. This one looks like a taiyaki."
	icon_state = "fritterish"
	average_size = 50
	average_weight = 1000
	sprite_width = 5
	sprite_height = 3
	stable_population = 5
	fish_traits = list(/datum/fish_trait/picky_eater)
	compatible_types = list(/obj/item/fish/fryish, /obj/item/fish/fryish/nessie)
	fish_movement_type = /datum/fish_movement
	is_bait = FALSE
	next_type = /datum/fish_evolution/nessie
	growth_time = 8 MINUTES
	///fritterish can have different forms assigned to them on init. These are purely visual.
	var/variant = FISH_FRITTERISH

/obj/item/fish/fryish/fritterish/Initialize(mapload, apply_qualities = TRUE)
	. = ..()
	variant = pick(FISH_FRITTERISH, FISH_BERNARD, FISH_MATTHEW)
	load_variant(pick(FISH_FRITTERISH, FISH_BERNARD, FISH_MATTHEW))

/obj/item/fish/fryish/fritterish/proc/load_variant(new_variant)
	variant = new_variant
	switch(variant)
		if(FISH_BERNARD)
			sprite_width = 4
			sprite_height = 6
			base_icon_state = "bernardfish"
		if(FISH_MATTHEW)
			sprite_width = 6
			base_icon_state = "matthewfish"
	update_appearance()

#define PERSISTENCE_FISH_FRITTERISH_VARIANT "fritterish_variant"

/obj/item/fish/fryish/fritterish/persistence_save(list/data)
	data[PERSISTENCE_FISH_FRITTERISH_VARIANT] = variant

/obj/item/fish/fryish/fritterish/persistence_load(list/data)
	load_variant(data[PERSISTENCE_FISH_FRITTERISH_VARIANT])

#undef PERSISTENCE_FISH_FRITTERISH_VARIANT

/obj/item/fish/fryish/fritterish/update_name()
	switch(variant)
		if(FISH_BERNARD)
			name = "bernard-fish"
		if(FISH_MATTHEW)
			name = "matthew-fish"
	return ..()

/obj/item/fish/fryish/fritterish/update_desc()
	switch(variant)
		if(FISH_BERNARD)
			desc = "A <u>deliciously</> extremophile alien fish shaped like a dinosaur. Children love it."
		if(FISH_MATTHEW)
			desc = "A <u>deliciously</> extremophile alien fish shaped like a pterodactyl. Children love it."
	return ..()

#undef FISH_FRITTERISH
#undef FISH_BERNARD
#undef FISH_MATTHEW

/obj/item/fish/fryish/nessie
	name = "nessie-fish"
	fish_id = "nessie"
	desc = "A <u>deliciously</u> extremophile alien fish. This one is so big, you could write legends about it."
	icon = 'icons/obj/aquarium/wide.dmi'
	icon_state = "nessiefish"
	base_pixel_w = -16
	pixel_w = -16
	sprite_width = 12
	sprite_height = 4
	average_size = 150
	average_weight = 6000
	health = 125
	feeding_frequency = 5 MINUTES
	breeding_timeout = 5 MINUTES
	random_case_rarity = FISH_RARITY_NOPE
	stable_population = 3
	num_fillets = 2
	fish_traits = list(/datum/fish_trait/picky_eater, /datum/fish_trait/predator)
	compatible_types = list(/obj/item/fish/fryish, /obj/item/fish/fryish/fritterish)
	spawn_types = list(/obj/item/fish/fryish/fritterish)
	fish_movement_type = /datum/fish_movement
	beauty = FISH_BEAUTY_EXCELLENT
	fishing_difficulty_modifier = 45
	fish_flags = parent_type::fish_flags & ~FISH_FLAG_SHOW_IN_CATALOG
	is_bait = FALSE
	next_type = null
