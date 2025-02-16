/obj/item/food/cake
	icon = 'icons/obj/food/piecake.dmi'
	bite_consumption = 3
	max_volume = 80
	food_reagents = list(
		/datum/reagent/consumable/nutriment = 20,
		/datum/reagent/consumable/nutriment/vitamin = 5,
	)
	tastes = list("cake" = 1)
	foodtypes = GRAIN | DAIRY
	crafting_complexity = FOOD_COMPLEXITY_2
	/// type is spawned 5 at a time and replaces this cake when processed by cutting tool
	var/obj/item/food/cakeslice/slice_type
	/// changes yield of sliced cake, default for cake is 5
	var/yield = 5

/obj/item/food/cake/Initialize(mapload)
	. = ..()
	AddComponent(/datum/component/food_storage)

/obj/item/food/cake/make_processable()
	if (slice_type)
		AddElement(/datum/element/processable, TOOL_KNIFE, slice_type, yield, 3 SECONDS, table_required = TRUE, screentip_verb = "Slice")

/obj/item/food/cakeslice
	icon = 'icons/obj/food/piecake.dmi'
	food_reagents = list(
		/datum/reagent/consumable/nutriment = 4,
		/datum/reagent/consumable/nutriment/vitamin = 1,
	)
	tastes = list("cake" = 1)
	foodtypes = GRAIN | DAIRY
	w_class = WEIGHT_CLASS_SMALL
	crafting_complexity = FOOD_COMPLEXITY_2

/obj/item/food/cake/plain
	name = "plain cake"
	desc = "A plain cake, not a lie."
	icon_state = "plaincake"
	food_reagents = list(
		/datum/reagent/consumable/nutriment = 30,
		/datum/reagent/consumable/nutriment/vitamin = 7,
	)
	tastes = list("sweetness" = 2, "cake" = 5)
	foodtypes = GRAIN | DAIRY | SUGAR
	slice_type = /obj/item/food/cakeslice/plain

/obj/item/food/cake/plain/Initialize(mapload)
	. = ..()
	AddComponent(/datum/component/ingredients_holder, /obj/item/food/cake/empty, CUSTOM_INGREDIENT_ICON_FILL, max_ingredients = 16)

/obj/item/food/cakeslice/plain
	name = "plain cake slice"
	desc = "Just a slice of cake, it is enough for everyone."
	icon_state = "plaincake_slice"
	tastes = list("sweetness" = 2, "cake" = 5)
	foodtypes = GRAIN | DAIRY | SUGAR

/obj/item/food/cake/empty
	name = "cake"
	desc = "A custom cake made by an insane chef."
	icon_state = "cake_custom"
	foodtypes = GRAIN | DAIRY | SUGAR
	slice_type = /obj/item/food/cakeslice/empty

/obj/item/food/cakeslice/empty
	name = "cake slice"
	desc = "A slice of custom cake, made by an insane chef."
	icon_state = "cake_custom_slice"
	foodtypes = GRAIN | DAIRY | SUGAR

/obj/item/food/cakeslice/empty/Initialize(mapload)
	. = ..()
	AddComponent(/datum/component/ingredients_holder, null, CUSTOM_INGREDIENT_ICON_FILL, max_ingredients = 16)

/obj/item/food/cake/carrot
	name = "carrot cake"
	desc = "A favorite desert of a certain wascally wabbit. Not a lie."
	icon_state = "carrotcake"
	tastes = list("cake" = 5, "sweetness" = 2, "carrot" = 1)
	foodtypes = GRAIN | DAIRY | VEGETABLES | SUGAR
	venue_value = FOOD_PRICE_CHEAP
	slice_type = /obj/item/food/cakeslice/carrot
	crafting_complexity = FOOD_COMPLEXITY_3

/obj/item/food/cakeslice/carrot
	name = "carrot cake slice"
	desc = "Carrotty slice of Carrot Cake, carrots are good for your eyes! Also not a lie."
	icon_state = "carrotcake_slice"
	tastes = list("cake" = 5, "sweetness" = 2, "carrot" = 1)
	foodtypes = GRAIN | DAIRY | VEGETABLES | SUGAR
	crafting_complexity = FOOD_COMPLEXITY_3

/obj/item/food/cake/brain
	name = "brain cake"
	desc = "A squishy cake-thing."
	icon_state = "braincake"
	food_reagents = list(
		/datum/reagent/consumable/nutriment = 15,
		/datum/reagent/consumable/nutriment/protein = 5,
		/datum/reagent/medicine/mannitol = 10,
		/datum/reagent/consumable/nutriment/vitamin = 5,
	)
	tastes = list("cake" = 5, "sweetness" = 2, "brains" = 1)
	foodtypes = GRAIN | DAIRY | MEAT | GORE | SUGAR
	slice_type = /obj/item/food/cakeslice/brain
	crafting_complexity = FOOD_COMPLEXITY_3

/obj/item/food/cakeslice/brain
	name = "brain cake slice"
	desc = "Lemme tell you something about prions. THEY'RE DELICIOUS."
	icon_state = "braincakeslice"
	food_reagents = list(
		/datum/reagent/consumable/nutriment = 4,
		/datum/reagent/consumable/nutriment/protein = 1,
		/datum/reagent/medicine/mannitol = 2,
		/datum/reagent/consumable/nutriment/vitamin = 1,
	)
	tastes = list("cake" = 5, "sweetness" = 2, "brains" = 1)
	foodtypes = GRAIN | DAIRY | MEAT | GORE | SUGAR
	crafting_complexity = FOOD_COMPLEXITY_3

/obj/item/food/cake/cheese
	name = "cheese cake"
	desc = "DANGEROUSLY cheesy."
	icon_state = "cheesecake"
	food_reagents = list(
		/datum/reagent/consumable/nutriment = 20,
		/datum/reagent/consumable/nutriment/vitamin = 8,
		/datum/reagent/consumable/nutriment/protein = 5,
	)
	tastes = list("cake" = 4, "cream cheese" = 3)
	foodtypes = GRAIN | DAIRY
	venue_value = FOOD_PRICE_CHEAP
	slice_type = /obj/item/food/cakeslice/cheese
	crafting_complexity = FOOD_COMPLEXITY_3

/obj/item/food/cakeslice/cheese
	name = "cheese cake slice"
	desc = "Slice of pure cheestisfaction."
	icon_state = "cheesecake_slice"
	food_reagents = list(
		/datum/reagent/consumable/nutriment = 4,
		/datum/reagent/consumable/nutriment/protein = 1,
		/datum/reagent/consumable/nutriment/vitamin = 1.3,
	)
	tastes = list("cake" = 4, "cream cheese" = 3)
	foodtypes = GRAIN | DAIRY
	crafting_complexity = FOOD_COMPLEXITY_3

/obj/item/food/cake/orange
	name = "orange cake"
	desc = "A cake with added orange."
	icon_state = "orangecake"
	tastes = list("cake" = 5, "sweetness" = 2, "oranges" = 2)
	foodtypes = GRAIN | DAIRY | FRUIT | SUGAR | ORANGES
	venue_value = FOOD_PRICE_CHEAP
	slice_type = /obj/item/food/cakeslice/orange
	crafting_complexity = FOOD_COMPLEXITY_3

/obj/item/food/cakeslice/orange
	name = "orange cake slice"
	desc = "Just a slice of cake, it is enough for everyone."
	icon_state = "orangecake_slice"
	tastes = list("cake" = 5, "sweetness" = 2, "oranges" = 2)
	foodtypes = GRAIN | DAIRY | FRUIT | SUGAR | ORANGES
	crafting_complexity = FOOD_COMPLEXITY_3

/obj/item/food/cake/lime
	name = "lime cake"
	desc = "A cake with added lime."
	icon_state = "limecake"
	food_reagents = list(
		/datum/reagent/consumable/nutriment = 20,
		/datum/reagent/consumable/nutriment/vitamin = 10,
	)
	tastes = list("cake" = 5, "sweetness" = 2, "unbearable sourness" = 2)
	foodtypes = GRAIN | DAIRY | FRUIT | SUGAR
	venue_value = FOOD_PRICE_CHEAP
	slice_type = /obj/item/food/cakeslice/lime
	crafting_complexity = FOOD_COMPLEXITY_3

/obj/item/food/cakeslice/lime
	name = "lime cake slice"
	desc = "Just a slice of cake, it is enough for everyone."
	icon_state = "limecake_slice"
	tastes = list("cake" = 5, "sweetness" = 2, "unbearable sourness" = 2)
	foodtypes = GRAIN | DAIRY | FRUIT | SUGAR
	crafting_complexity = FOOD_COMPLEXITY_3

/obj/item/food/cake/lemon
	name = "lemon cake"
	desc = "A cake with added lemon."
	icon_state = "lemoncake"
	food_reagents = list(
		/datum/reagent/consumable/nutriment = 20,
		/datum/reagent/consumable/nutriment/vitamin = 10,
	)
	tastes = list("cake" = 5, "sweetness" = 2, "sourness" = 2)
	foodtypes = GRAIN | DAIRY | FRUIT | SUGAR
	venue_value = FOOD_PRICE_CHEAP
	slice_type = /obj/item/food/cakeslice/lemon
	crafting_complexity = FOOD_COMPLEXITY_3

/obj/item/food/cakeslice/lemon
	name = "lemon cake slice"
	desc = "Just a slice of cake, it is enough for everyone."
	icon_state = "lemoncake_slice"
	tastes = list("cake" = 5, "sweetness" = 2, "sourness" = 2)
	foodtypes = GRAIN | DAIRY | FRUIT | SUGAR
	crafting_complexity = FOOD_COMPLEXITY_3

/obj/item/food/cake/chocolate
	name = "chocolate cake"
	desc = "A cake with added chocolate."
	icon_state = "chocolatecake"
	food_reagents = list(
		/datum/reagent/consumable/nutriment = 20,
		/datum/reagent/consumable/nutriment/vitamin = 10,
	)
	tastes = list("cake" = 5, "sweetness" = 1, "chocolate" = 4)
	foodtypes = GRAIN | DAIRY | JUNKFOOD | SUGAR
	venue_value = FOOD_PRICE_CHEAP
	slice_type = /obj/item/food/cakeslice/chocolate
	crafting_complexity = FOOD_COMPLEXITY_3

/obj/item/food/cakeslice/chocolate
	name = "chocolate cake slice"
	desc = "Just a slice of cake, it is enough for everyone."
	icon_state = "chocolatecake_slice"
	tastes = list("cake" = 5, "sweetness" = 1, "chocolate" = 4)
	foodtypes = GRAIN | DAIRY | JUNKFOOD | SUGAR
	crafting_complexity = FOOD_COMPLEXITY_3

/obj/item/food/cake/birthday
	name = "birthday cake"
	desc = "Happy Birthday little clown..."
	icon_state = "birthdaycake"
	food_reagents = list(
		/datum/reagent/consumable/nutriment = 20,
		/datum/reagent/consumable/sprinkles = 10,
		/datum/reagent/consumable/nutriment/vitamin = 5,
	)
	tastes = list("cake" = 5, "sweetness" = 1)
	foodtypes = GRAIN | DAIRY | JUNKFOOD | SUGAR
	slice_type = /obj/item/food/cakeslice/birthday
	crafting_complexity = FOOD_COMPLEXITY_3

/obj/item/food/cake/birthday/make_microwaveable() // super sekrit club
	AddElement(/datum/element/microwavable, /obj/item/clothing/head/utility/hardhat/cakehat)

/obj/item/food/cakeslice/birthday
	name = "birthday cake slice"
	desc = "A slice of your birthday."
	icon_state = "birthdaycakeslice"
	food_reagents = list(
		/datum/reagent/consumable/nutriment = 4,
		/datum/reagent/consumable/sprinkles = 2,
		/datum/reagent/consumable/nutriment/vitamin = 1,
	)
	tastes = list("cake" = 5, "sweetness" = 1)
	foodtypes = GRAIN | DAIRY | JUNKFOOD | SUGAR
	crafting_complexity = FOOD_COMPLEXITY_3

/obj/item/food/cake/birthday/energy
	name = "energy cake"
	desc = "Just enough calories for a whole nuclear operative squad."
	icon_state = "energycake"
	force = 5
	hitsound = 'sound/items/weapons/blade1.ogg'
	food_reagents = list(
		/datum/reagent/consumable/nutriment = 10,
		/datum/reagent/consumable/sprinkles = 10,
		/datum/reagent/consumable/nutriment/vitamin = 5,
		/datum/reagent/consumable/pwr_game = 10,
		/datum/reagent/consumable/liquidelectricity/enriched = 10,
	)
	tastes = list("cake" = 3, "a Vlad's Salad" = 1)
	slice_type = /obj/item/food/cakeslice/birthday/energy
	crafting_complexity = FOOD_COMPLEXITY_4

/obj/item/food/cake/birthday/energy/make_microwaveable() //super sekriter club
	AddElement(/datum/element/microwavable, /obj/item/clothing/head/utility/hardhat/cakehat/energycake)

/obj/item/food/cake/birthday/energy/proc/energy_bite(mob/living/user)
	to_chat(user, "<font color='red' size='5'>As you eat the cake, you accidentally hurt yourself on the embedded energy sword!</font>")
	user.apply_damage(30, BRUTE, BODY_ZONE_HEAD)
	playsound(user, 'sound/items/weapons/blade1.ogg', 5, TRUE)

/obj/item/food/cake/birthday/energy/attack(mob/living/target_mob, mob/living/user)
	. = ..()
	if(HAS_TRAIT(user, TRAIT_PACIFISM) && target_mob != user) //Prevents pacifists from attacking others directly
		return
	energy_bite(target_mob, user)

/obj/item/food/cakeslice/birthday/energy
	name = "energy cake slice"
	desc = "For the traitor on the go."
	icon_state = "energycakeslice"
	force = 2
	hitsound = 'sound/items/weapons/blade1.ogg'
	food_reagents = list(
		/datum/reagent/consumable/nutriment = 4,
		/datum/reagent/consumable/sprinkles = 2,
		/datum/reagent/consumable/nutriment/vitamin = 1,
		/datum/reagent/consumable/pwr_game = 2,
		/datum/reagent/consumable/liquidelectricity/enriched = 2,
	)
	tastes = list("cake" = 3, "a Vlad's Salad" = 1)
	crafting_complexity = FOOD_COMPLEXITY_4

/obj/item/food/cakeslice/birthday/energy/Initialize(mapload)
	. = ..()
	RegisterSignal(src, COMSIG_FOOD_EATEN, PROC_REF(bite_taken))

/obj/item/food/cakeslice/birthday/energy/attack(mob/living/target_mob, mob/living/user)
	if(HAS_TRAIT(user, TRAIT_PACIFISM) && target_mob != user) //Prevents pacifists from attacking others directly
		balloon_alert(user, "that's dangerous!")
		return FALSE
	return ..()

/obj/item/food/cakeslice/birthday/energy/proc/bite_taken(datum/source, mob/living/eater, mob/living/feeder)
	SIGNAL_HANDLER
	to_chat(eater, "<font color='red' size='5'>As you eat the cake slice, you accidentally hurt yourself on the embedded energy dagger!</font>")
	if(eater != feeder)
		log_combat(feeder, eater, "fed an energy cake to", src)
	eater.apply_damage(18, BRUTE, BODY_ZONE_HEAD)
	playsound(eater, 'sound/items/weapons/blade1.ogg', 5, TRUE)

/obj/item/food/cake/apple
	name = "apple cake"
	desc = "A cake centred with Apple."
	icon_state = "applecake"
	food_reagents = list(
		/datum/reagent/consumable/nutriment = 20,
		/datum/reagent/consumable/nutriment/vitamin = 10,
	)
	tastes = list("cake" = 5, "sweetness" = 1, "apple" = 1)
	foodtypes = GRAIN | DAIRY | FRUIT | SUGAR
	venue_value = FOOD_PRICE_CHEAP
	slice_type = /obj/item/food/cakeslice/apple
	crafting_complexity = FOOD_COMPLEXITY_3

/obj/item/food/cakeslice/apple
	name = "apple cake slice"
	desc = "A slice of heavenly cake."
	icon_state = "applecakeslice"
	tastes = list("cake" = 5, "sweetness" = 1, "apple" = 1)
	foodtypes = GRAIN | DAIRY | FRUIT | SUGAR
	crafting_complexity = FOOD_COMPLEXITY_3

/obj/item/food/cake/slimecake
	name = "Slime cake"
	desc = "A cake made of slimes. Probably not electrified."
	icon_state = "slimecake"
	tastes = list("cake" = 5, "sweetness" = 1, "slime" = 1)
	foodtypes = GRAIN | DAIRY | SUGAR
	slice_type = /obj/item/food/cakeslice/slimecake
	crafting_complexity = FOOD_COMPLEXITY_3

/obj/item/food/cakeslice/slimecake
	name = "slime cake slice"
	desc = "A slice of slime cake."
	icon_state = "slimecake_slice"
	tastes = list("cake" = 5, "sweetness" = 1, "slime" = 1)
	foodtypes = GRAIN | DAIRY | SUGAR
	crafting_complexity = FOOD_COMPLEXITY_3

/obj/item/food/cake/pumpkinspice
	name = "pumpkin spice cake"
	desc = "A hollow cake with real pumpkin."
	icon_state = "pumpkinspicecake"
	tastes = list("cake" = 5, "sweetness" = 1, "pumpkin" = 1)
	foodtypes = GRAIN | DAIRY | VEGETABLES | SUGAR
	venue_value = FOOD_PRICE_CHEAP
	slice_type = /obj/item/food/cakeslice/pumpkinspice
	crafting_complexity = FOOD_COMPLEXITY_3

/obj/item/food/cakeslice/pumpkinspice
	name = "pumpkin spice cake slice"
	desc = "A spicy slice of pumpkin goodness."
	icon_state = "pumpkinspicecakeslice"
	tastes = list("cake" = 5, "sweetness" = 1, "pumpkin" = 1)
	foodtypes = GRAIN | DAIRY | VEGETABLES | SUGAR
	crafting_complexity = FOOD_COMPLEXITY_3

/obj/item/food/cake/berry_vanilla_cake // blackberry strawberries vanilla cake
	name = "blackberry and strawberry vanilla cake"
	desc = "A plain cake, filled with assortment of blackberries and strawberries!"
	icon_state = "blackbarry_strawberries_cake_vanilla_cake"
	tastes = list("blackberry" = 2, "strawberries" = 2, "vanilla" = 2, "sweetness" = 2, "cake" = 3)
	foodtypes = GRAIN | DAIRY | FRUIT | SUGAR
	slice_type = /obj/item/food/cakeslice/berry_vanilla_cake
	crafting_complexity = FOOD_COMPLEXITY_3

/obj/item/food/cakeslice/berry_vanilla_cake
	name = "blackberry and strawberry vanilla cake slice"
	desc = "Just a slice of cake  filled with assortment of blackberries and strawberries!"
	icon_state = "blackbarry_strawberries_cake_vanilla_slice"
	tastes = list("blackberry" = 2, "strawberries" = 2, "vanilla" = 2, "sweetness" = 2, "cake" = 3)
	foodtypes = GRAIN | DAIRY | FRUIT | SUGAR
	crafting_complexity = FOOD_COMPLEXITY_3

/obj/item/food/cake/berry_chocolate_cake // blackbarry strawberries chocolate cake <- this is a relic from before resprite
	name = "strawberry chocolate cake"
	desc = "A chocolate cake with five strawberries on top. For some reason, this configuration of cake is particularly aesthetically pleasing to AIs in SELF."
	icon_state = "liars_cake"
	food_reagents = list(
		/datum/reagent/consumable/nutriment = 20,
		/datum/reagent/consumable/nutriment/vitamin = 5,
		/datum/reagent/consumable/coco = 5,
	)
	tastes = list("blackberry" = 2, "strawberries" = 2, "chocolate" = 2, "sweetness" = 2, "cake" = 3)
	foodtypes = GRAIN | DAIRY | FRUIT | SUGAR
	slice_type = /obj/item/food/cakeslice/berry_chocolate_cake
	crafting_complexity = FOOD_COMPLEXITY_4

/obj/item/food/cakeslice/berry_chocolate_cake
	name = "strawberry chocolate cake slice"
	desc = "Just a slice of cake with five strawberries on top. \
		For some reason, this configuration of cake is particularly aesthetically pleasing to AIs in SELF."
	icon_state = "liars_slice"
	tastes = list("strawberries" = 2, "chocolate" = 2, "sweetness" = 2, "cake" = 3)
	foodtypes = GRAIN | DAIRY | FRUIT | SUGAR
	crafting_complexity = FOOD_COMPLEXITY_4

/obj/item/food/cake/holy_cake
	name = "angel food cake"
	desc = "A cake made for angels and chaplains alike! Contains holy water."
	icon_state = "holy_cake"
	food_reagents = list(
		/datum/reagent/consumable/nutriment = 1,
		/datum/reagent/consumable/nutriment/vitamin = 3,
		/datum/reagent/water/holywater = 10,
	)
	tastes = list("cake" = 5, "sweetness" = 1, "clouds" = 1)
	foodtypes = GRAIN | DAIRY | SUGAR
	slice_type = /obj/item/food/cakeslice/holy_cake_slice

/obj/item/food/cakeslice/holy_cake_slice
	name = "angel food cake slice"
	desc = "A slice of heavenly cake."
	icon_state = "holy_cake_slice"
	tastes = list("cake" = 5, "sweetness" = 1, "clouds" = 1)
	foodtypes = GRAIN | DAIRY | SUGAR

/obj/item/food/cake/pound_cake
	name = "pound cake"
	desc = "A condensed cake made for filling people up quickly."
	icon_state = "pound_cake"
	food_reagents = list(
		/datum/reagent/consumable/nutriment = 60,
		/datum/reagent/consumable/nutriment/vitamin = 20,
	)
	tastes = list("cake" = 5, "sweetness" = 5, "batter" = 1)
	foodtypes = GRAIN | DAIRY | SUGAR | JUNKFOOD
	venue_value = FOOD_PRICE_CHEAP
	slice_type = /obj/item/food/cakeslice/pound_cake_slice
	yield = 7
	crafting_complexity = FOOD_COMPLEXITY_2

/obj/item/food/cakeslice/pound_cake_slice
	name = "pound cake slice"
	desc = "A slice of condensed cake made for filling people up quickly."
	icon_state = "pound_cake_slice"
	food_reagents = list(
		/datum/reagent/consumable/nutriment = 9,
		/datum/reagent/consumable/nutriment/vitamin = 4,
	)
	tastes = list("cake" = 5, "sweetness" = 5, "batter" = 1)
	foodtypes = GRAIN | DAIRY | SUGAR | JUNKFOOD
	crafting_complexity = FOOD_COMPLEXITY_2

/obj/item/food/cake/hardware_cake
	name = "hardware cake"
	desc = "A \"cake\" that is made with electronic boards and leaks acid..."
	icon_state = "hardware_cake"
	food_reagents = list(
		/datum/reagent/consumable/nutriment = 20,
		/datum/reagent/consumable/nutriment/vitamin = 5,
		/datum/reagent/toxin/acid = 15,
		/datum/reagent/fuel/oil = 15,
	)
	tastes = list("acid" = 3, "metal" = 4, "glass" = 5)
	foodtypes = GRAIN | GROSS
	slice_type = /obj/item/food/cakeslice/hardware_cake_slice
	crafting_complexity = FOOD_COMPLEXITY_3

/obj/item/food/cakeslice/hardware_cake_slice
	name = "hardware cake slice"
	desc = "A slice of electronic boards and some acid."
	icon_state = "hardware_cake_slice"
	food_reagents = list(
		/datum/reagent/consumable/nutriment = 4,
		/datum/reagent/consumable/nutriment/vitamin = 1,
		/datum/reagent/toxin/acid = 3,
		/datum/reagent/fuel/oil = 3,
	)
	tastes = list("acid" = 3, "metal" = 4, "glass" = 5)
	foodtypes = GRAIN | GROSS
	crafting_complexity = FOOD_COMPLEXITY_3

/obj/item/food/cake/vanilla_cake
	name = "vanilla cake"
	desc = "A vanilla frosted cake."
	icon_state = "vanillacake"
	food_reagents = list(
		/datum/reagent/consumable/nutriment = 20,
		/datum/reagent/consumable/nutriment/vitamin = 5,
		/datum/reagent/consumable/sugar = 15,
		/datum/reagent/consumable/vanilla = 15,
	)
	tastes = list("cake" = 1, "sugar" = 1, "vanilla" = 10)
	foodtypes = GRAIN | SUGAR | DAIRY
	slice_type = /obj/item/food/cakeslice/vanilla_slice
	crafting_complexity = FOOD_COMPLEXITY_3

/obj/item/food/cakeslice/vanilla_slice
	name = "vanilla cake slice"
	desc = "A slice of vanilla frosted cake."
	icon_state = "vanillacake_slice"
	food_reagents = list(
		/datum/reagent/consumable/nutriment = 4,
		/datum/reagent/consumable/nutriment/vitamin = 1,
		/datum/reagent/consumable/sugar = 3,
		/datum/reagent/consumable/vanilla = 3,
	)
	tastes = list("cake" = 1, "sugar" = 1, "vanilla" = 10)
	foodtypes = GRAIN | SUGAR | DAIRY
	crafting_complexity = FOOD_COMPLEXITY_3

/obj/item/food/cake/clown_cake
	name = "clown cake"
	desc = "A funny cake with a clown face on it."
	icon_state = "clowncake"
	food_reagents = list(
		/datum/reagent/consumable/nutriment = 20,
		/datum/reagent/consumable/nutriment/vitamin = 5,
		/datum/reagent/consumable/banana = 15,
	)
	tastes = list("cake" = 1, "sugar" = 1, "joy" = 10)
	foodtypes = GRAIN | SUGAR | DAIRY
	slice_type = /obj/item/food/cakeslice/clown_slice
	crafting_complexity = FOOD_COMPLEXITY_5
	crafted_food_buff = /datum/status_effect/food/trait/waddle

/obj/item/food/cakeslice/clown_slice
	name = "clown cake slice"
	desc = "A slice of bad jokes, and silly props."
	icon_state = "clowncake_slice"
	food_reagents = list(
		/datum/reagent/consumable/nutriment = 4,
		/datum/reagent/consumable/nutriment/vitamin = 1,
		/datum/reagent/consumable/banana = 3,
	)
	tastes = list("cake" = 1, "sugar" = 1, "joy" = 10)
	foodtypes = GRAIN | SUGAR | DAIRY
	crafting_complexity = FOOD_COMPLEXITY_5
	crafted_food_buff = /datum/status_effect/food/trait/waddle

/obj/item/food/cake/trumpet
	name = "spaceman's cake"
	desc = "A spaceman's trumpet frosted cake."
	icon_state = "trumpetcake"
	food_reagents = list(
		/datum/reagent/consumable/nutriment = 20,
		/datum/reagent/consumable/nutriment/vitamin = 5,
		/datum/reagent/consumable/cream = 5,
		/datum/reagent/consumable/nutriment/vitamin = 5,
		/datum/reagent/consumable/berryjuice = 5,
	)
	tastes = list("cake" = 4, "violets" = 2, "jam" = 2)
	foodtypes = GRAIN | DAIRY | FRUIT | SUGAR
	slice_type = /obj/item/food/cakeslice/trumpet
	crafting_complexity = FOOD_COMPLEXITY_4

/obj/item/food/cakeslice/trumpet
	name = "spaceman's cake slice"
	desc = "A spaceman's trumpet frosted cake."
	icon_state = "trumpetcakeslice"
	food_reagents = list(
		/datum/reagent/consumable/nutriment = 4,
		/datum/reagent/consumable/nutriment/vitamin = 1,
		/datum/reagent/consumable/cream = 1,
		/datum/reagent/consumable/nutriment/vitamin = 1,
		/datum/reagent/consumable/berryjuice = 1,
	)
	tastes = list("cake" = 4, "violets" = 2, "jam" = 2)
	foodtypes = GRAIN | DAIRY | FRUIT | SUGAR
	crafting_complexity = FOOD_COMPLEXITY_4

/obj/item/food/cake/brioche
	name = "brioche cake"
	desc = "A ring of sweet, glazed buns."
	icon_state = "briochecake"
	tastes = list("cake" = 4, "butter" = 2, "cream" = 1)
	foodtypes = GRAIN | DAIRY | SUGAR
	slice_type = /obj/item/food/cakeslice/brioche
	yield = 6
	crafting_complexity = FOOD_COMPLEXITY_2

/obj/item/food/cakeslice/brioche
	name = "brioche cake slice"
	desc = "Delicious sweet-bread. Who needs anything else?"
	icon_state = "briochecake_slice"
	tastes = list("cake" = 4, "butter" = 2, "cream" = 1)
	foodtypes = GRAIN | DAIRY | SUGAR
	crafting_complexity = FOOD_COMPLEXITY_2

/obj/item/food/cake/pavlova
	name = "pavlova"
	desc = "A sweet berry pavlova. Invented in New Zealand, but named after a Russian ballerina... And scientifically proven to be the best at dinner parties!"
	icon_state = "pavlova"
	tastes = list("meringue" = 5, "creaminess" = 1, "berries" = 1)
	foodtypes = DAIRY | FRUIT | SUGAR
	slice_type = /obj/item/food/cakeslice/pavlova
	crafting_complexity = FOOD_COMPLEXITY_3

/obj/item/food/cake/pavlova/nuts
	name = "pavlova with nuts"
	foodtypes = NUTS | FRUIT | SUGAR
	slice_type = /obj/item/food/cakeslice/pavlova/nuts

/obj/item/food/cakeslice/pavlova
	name = "pavlova slice"
	desc = "A cracked slice of pavlova stacked with berries. \
		You even got it sliced in such a way that more berries ended up on your slice, how delightfully devilish."
	icon_state = "pavlova_slice"
	tastes = list("meringue" = 5, "creaminess" = 1, "berries" = 1)
	foodtypes = DAIRY | FRUIT | SUGAR
	crafting_complexity = FOOD_COMPLEXITY_3

/obj/item/food/cakeslice/pavlova/nuts
	foodtypes = NUTS | FRUIT | SUGAR

/obj/item/food/cake/fruit
	name = "english fruitcake"
	desc = "A proper good cake, innit?"
	icon_state = "fruitcake"
	food_reagents = list(
		/datum/reagent/consumable/nutriment = 15,
		/datum/reagent/consumable/sugar = 10,
		/datum/reagent/consumable/cherryjelly = 5,
	)
	tastes = list("dried fruit" = 5, "treacle" = 2, "christmas" = 2)
	force = 7
	throwforce = 7
	foodtypes = GRAIN | DAIRY | FRUIT | SUGAR
	slice_type = /obj/item/food/cakeslice/fruit
	crafting_complexity = FOOD_COMPLEXITY_4

/obj/item/food/cakeslice/fruit
	name = "english fruitcake slice"
	desc = "A proper good slice, innit?"
	icon_state = "fruitcake_slice1"
	base_icon_state = "fruitcake_slice"
	tastes = list("dried fruit" = 5, "treacle" = 2, "christmas" = 2)
	force = 2
	throwforce = 2
	foodtypes = GRAIN | DAIRY | FRUIT | SUGAR
	crafting_complexity = FOOD_COMPLEXITY_4

/obj/item/food/cakeslice/fruit/Initialize(mapload)
	. = ..()
	icon_state = "[base_icon_state][rand(1,3)]"

/obj/item/food/cake/plum
	name = "plum cake"
	desc = "A cake centred with Plums."
	icon_state = "plumcake"
	food_reagents = list(
		/datum/reagent/consumable/nutriment = 20,
		/datum/reagent/consumable/nutriment/vitamin = 10,
		/datum/reagent/impurity/rosenol = 8,
	)
	tastes = list("cake" = 5, "sweetness" = 1, "plum" = 2)
	foodtypes = GRAIN | DAIRY | FRUIT | SUGAR
	venue_value = FOOD_PRICE_CHEAP
	slice_type = /obj/item/food/cakeslice/plum
	crafting_complexity = FOOD_COMPLEXITY_3

/obj/item/food/cakeslice/plum
	name = "plum cake slice"
	desc = "A slice of plum cake."
	icon_state = "plumcakeslice"
	tastes = list("cake" = 5, "sweetness" = 1, "plum" = 2)
	foodtypes = GRAIN | DAIRY | FRUIT | SUGAR
	crafting_complexity = FOOD_COMPLEXITY_3

/obj/item/food/cake/wedding
	name = "wedding cake"
	desc = "An expensive, multi-tiered cake."
	icon_state = "weddingcake"
	food_reagents = list(
		/datum/reagent/consumable/nutriment = 40,
		/datum/reagent/consumable/sugar = 30,
		/datum/reagent/consumable/nutriment/vitamin = 10,
	)
	tastes = list("cake" = 3, "frosting" = 1)
	foodtypes = GRAIN | DAIRY | SUGAR
	slice_type = /obj/item/food/cakeslice/wedding
	crafting_complexity = FOOD_COMPLEXITY_3

/obj/item/food/cakeslice/wedding
	name = "wedding cake slice"
	desc = "Traditionally, those getting married feed each other a slice of cake."
	icon_state = "weddingcake_slice"
	tastes = list("cake" = 3, "frosting" = 1)
	foodtypes = GRAIN | DAIRY | SUGAR

/obj/item/food/cake/pineapple_cream_cake
	name = "pineapple cream cake"
	desc = "A vibrant cake with a layer of thick cream and pineapple on top."
	icon_state = "pineapple_cream_cake"
	food_reagents = list(
		/datum/reagent/consumable/nutriment = 30,
		/datum/reagent/consumable/sugar = 15,
		/datum/reagent/consumable/nutriment/vitamin = 15,
	)
	tastes = list("cake" = 2, "cream" = 3, "pineapple" = 4)
	foodtypes = GRAIN | DAIRY | SUGAR | FRUIT | PINEAPPLE
	slice_type = /obj/item/food/cakeslice/pineapple_cream_cake
	crafting_complexity = FOOD_COMPLEXITY_3

/obj/item/food/cakeslice/pineapple_cream_cake
	name = "pineapple cream cake slice"
	desc = "A vibrant cake with a layer of thick cream and pineapple on top."
	icon_state = "pineapple_cream_cake_slice"
	food_reagents = list(
		/datum/reagent/consumable/nutriment = 6,
		/datum/reagent/consumable/sugar = 3,
		/datum/reagent/consumable/nutriment/vitamin = 3,
	)
	tastes = list("cake" = 2, "cream" = 3, "pineapple" = 4)
	foodtypes = GRAIN | DAIRY | SUGAR | FRUIT | PINEAPPLE
	crafting_complexity = FOOD_COMPLEXITY_3
