#define DONUT_SPRINKLE_CHANCE 30

/obj/item/food/donut
	name = "donut"
	desc = "Goes great with robust coffee."
	icon = 'icons/obj/food/donuts.dmi'
	inhand_icon_state = "donut1"
	bite_consumption = 5
	food_reagents = list(/datum/reagent/consumable/nutriment = 3, /datum/reagent/consumable/sugar = 3)
	tastes = list("donut" = 1)
	foodtypes = JUNKFOOD | GRAIN | SUGAR | BREAKFAST
	food_flags = FOOD_FINGER_FOOD
	w_class = WEIGHT_CLASS_SMALL
	crafting_complexity = FOOD_COMPLEXITY_2
	var/decorated_icon = "donut_homer"
	var/is_decorated = FALSE
	var/extra_reagent = null
	var/decorated_adjective = "sprinkled"
	crafting_complexity = FOOD_COMPLEXITY_2

/obj/item/food/donut/Initialize(mapload)
	. = ..()
	AddElement(/datum/element/dunkable, amount_per_dunk = 10)
	if(prob(DONUT_SPRINKLE_CHANCE))
		decorate_donut()

// It is so stupid that we have to do this but because food crafting clears all reagents that got added during init,
// here we are adding it again (but only for crafting, maploaded and spawned donuts work fine).
// Until the issues with crafted items' reagents are resolved this will have to do
/obj/item/food/donut/plain/on_craft_completion(list/components, datum/crafting_recipe/current_recipe, atom/crafter)
	. = ..()
	if(is_decorated)
		reagents.add_reagent(/datum/reagent/consumable/sprinkles, 1)

///Override for checkliked callback
/obj/item/food/donut/make_edible()
	. = ..()
	AddComponent(/datum/component/edible, check_liked = CALLBACK(src, PROC_REF(check_liked)))

/obj/item/food/donut/proc/decorate_donut()
	if(is_decorated || !decorated_icon)
		return
	is_decorated = TRUE
	name = "[decorated_adjective] [name]"
	icon_state = decorated_icon //delish~!
	inhand_icon_state = "donut2"
	reagents.add_reagent(/datum/reagent/consumable/sprinkles, 1)
	return TRUE

/// Returns the sprite of the donut while in a donut box
/obj/item/food/donut/proc/in_box_sprite()
	return "[icon_state]_inbox"

///Override for checkliked in edible component, because all cops LOVE donuts
/obj/item/food/donut/proc/check_liked(mob/living/carbon/human/consumer)
	var/obj/item/organ/liver/liver = consumer.get_organ_slot(ORGAN_SLOT_LIVER)
	if(!HAS_TRAIT(consumer, TRAIT_AGEUSIA) && liver && HAS_TRAIT(liver, TRAIT_LAW_ENFORCEMENT_METABOLISM))
		return FOOD_LIKED

//Use this donut ingame
/obj/item/food/donut/plain
	icon_state = "donut"

/obj/item/food/donut/chaos
	name = "chaos donut"
	desc = "Like life, it never quite tastes the same."
	icon_state = "donut_chaos"
	bite_consumption = 10
	tastes = list("donut" = 3, "chaos" = 1)
	is_decorated = TRUE
	crafting_complexity = FOOD_COMPLEXITY_3

/obj/item/food/donut/chaos/Initialize(mapload)
	. = ..()
	extra_reagent = pick(
		/datum/reagent/consumable/nutriment,
		/datum/reagent/consumable/capsaicin,
		/datum/reagent/consumable/frostoil,
		/datum/reagent/drug/krokodil,
		/datum/reagent/toxin/plasma,
		/datum/reagent/consumable/coco,
		/datum/reagent/toxin/slimejelly,
		/datum/reagent/consumable/banana,
		/datum/reagent/consumable/berryjuice,
		/datum/reagent/medicine/omnizine,
	)
	reagents.add_reagent(extra_reagent, 3)

/obj/item/food/donut/meat
	name = "meat donut"
	desc = "Tastes as gross as it looks."
	icon_state = "donut_meat"
	food_reagents = list(
		/datum/reagent/consumable/nutriment = 2,
		/datum/reagent/consumable/nutriment/protein = 3,
		/datum/reagent/consumable/ketchup = 3,
	)
	tastes = list("meat" = 1)
	foodtypes = JUNKFOOD | MEAT | GORE | FRIED | BREAKFAST
	is_decorated = TRUE
	crafting_complexity = FOOD_COMPLEXITY_3

/obj/item/food/donut/berry
	name = "pink donut"
	desc = "Goes great with a soy latte."
	icon_state = "donut_pink"
	food_reagents = list(
		/datum/reagent/consumable/nutriment = 3,
		/datum/reagent/consumable/sugar = 3,
		/datum/reagent/consumable/berryjuice = 3,
		/datum/reagent/consumable/sprinkles = 1, //Extra sprinkles to reward frosting
	)
	decorated_icon = "donut_homer"

/obj/item/food/donut/trumpet
	name = "spaceman's donut"
	desc = "Goes great with a cold beaker of malk."
	icon_state = "donut_purple"
	food_reagents = list(
		/datum/reagent/consumable/nutriment = 3,
		/datum/reagent/consumable/sugar = 3,
		/datum/reagent/consumable/sprinkles = 1,
	)
	tastes = list("donut" = 3, "violets" = 1)
	is_decorated = TRUE
	crafting_complexity = FOOD_COMPLEXITY_3

/obj/item/food/donut/apple
	name = "apple donut"
	desc = "Goes great with a shot of cinnamon schnapps."
	icon_state = "donut_green"
	food_reagents = list(
		/datum/reagent/consumable/nutriment = 3,
		/datum/reagent/consumable/sugar = 3,
		/datum/reagent/consumable/applejuice = 3,
		/datum/reagent/consumable/sprinkles = 1,
	)
	tastes = list("donut" = 3, "green apples" = 1)
	is_decorated = TRUE

/obj/item/food/donut/caramel
	name = "caramel donut"
	desc = "Goes great with a mug of hot coco."
	icon_state = "donut_beige"
	food_reagents = list(
		/datum/reagent/consumable/nutriment = 3,
		/datum/reagent/consumable/sugar = 3,
		/datum/reagent/consumable/caramel = 3,
		/datum/reagent/consumable/sprinkles = 1,
	)
	tastes = list("donut" = 3, "buttery sweetness" = 1)
	is_decorated = TRUE

/obj/item/food/donut/choco
	name = "chocolate donut"
	desc = "Goes great with a glass of warm milk."
	icon_state = "donut_choc"
	food_reagents = list(
		/datum/reagent/consumable/nutriment = 3,
		/datum/reagent/consumable/sugar = 3,
		/datum/reagent/consumable/hot_coco = 3,
		/datum/reagent/consumable/sprinkles = 1,
	) //the coco reagent is just bitter.
	tastes = list("donut" = 4, "bitterness" = 1)
	decorated_icon = "donut_choc_sprinkles"
	crafting_complexity = FOOD_COMPLEXITY_3

/obj/item/food/donut/blumpkin
	name = "blumpkin donut"
	desc = "Goes great with a mug of soothing drunken blumpkin."
	icon_state = "donut_blue"
	food_reagents = list(
		/datum/reagent/consumable/nutriment = 3,
		/datum/reagent/consumable/sugar = 3,
		/datum/reagent/consumable/blumpkinjuice = 3,
		/datum/reagent/consumable/sprinkles = 1,
	)
	tastes = list("donut" = 2, "blumpkin" = 1)
	is_decorated = TRUE
	crafting_complexity = FOOD_COMPLEXITY_3

/obj/item/food/donut/bungo
	name = "bungo donut"
	desc = "Goes great with a mason jar of hippie's delight."
	icon_state = "donut_yellow"
	food_reagents = list(
		/datum/reagent/consumable/nutriment = 3,
		/datum/reagent/consumable/sugar = 3,
		/datum/reagent/consumable/bungojuice = 3,
		/datum/reagent/consumable/sprinkles = 1,
	)
	tastes = list("donut" = 3, "tropical sweetness" = 1)
	is_decorated = TRUE

/obj/item/food/donut/matcha
	name = "matcha donut"
	desc = "Goes great with a cup of tea."
	icon_state = "donut_olive"
	food_reagents = list(
		/datum/reagent/consumable/nutriment = 3,
		/datum/reagent/consumable/sugar = 3,
		/datum/reagent/toxin/teapowder = 3,
		/datum/reagent/consumable/sprinkles = 1,
	)
	tastes = list("donut" = 3, "matcha" = 1)
	is_decorated = TRUE

/obj/item/food/donut/laugh
	name = "sweet pea donut"
	desc = "Goes great with a bottle of Bastion Bourbon!"
	icon_state = "donut_laugh"
	food_reagents = list(
		/datum/reagent/consumable/nutriment = 3,
		/datum/reagent/consumable/sugar = 3,
		/datum/reagent/consumable/laughter = 3,
	)
	tastes = list("donut" = 3, "fizzy tutti frutti" = 1,)
	is_decorated = TRUE
	crafting_complexity = FOOD_COMPLEXITY_3

//////////////////////JELLY DONUTS/////////////////////////

/obj/item/food/donut/jelly
	name = "jelly donut"
	desc = "You jelly?"
	icon_state = "jelly"
	food_reagents = list(
		/datum/reagent/consumable/nutriment = 3,
		/datum/reagent/consumable/sugar = 3,
		/datum/reagent/consumable/sugar = 1,
		/datum/reagent/consumable/nutriment/vitamin = 1,
	)
	extra_reagent = /datum/reagent/consumable/berryjuice
	tastes = list("jelly" = 1, "donut" = 3)
	foodtypes = JUNKFOOD | GRAIN | FRIED | FRUIT | SUGAR | BREAKFAST

// Jelly donuts don't have holes, but look the same on the outside
/obj/item/food/donut/jelly/in_box_sprite()
	return "[replacetext(icon_state, "jelly", "donut")]_inbox"

/obj/item/food/donut/jelly/Initialize(mapload)
	. = ..()
	if(extra_reagent)
		reagents.add_reagent(extra_reagent, 3)

/obj/item/food/donut/jelly/plain //use this ingame to avoid inheritance related crafting issues.
	decorated_icon = "jelly_homer"

/obj/item/food/donut/jelly/berry
	name = "pink jelly donut"
	desc = "Goes great with a soy latte."
	icon_state = "jelly_pink"
	food_reagents = list(/datum/reagent/consumable/nutriment = 3, /datum/reagent/consumable/sugar = 3, /datum/reagent/consumable/berryjuice = 3, /datum/reagent/consumable/sprinkles = 1, /datum/reagent/consumable/nutriment/vitamin = 1) //Extra sprinkles to reward frosting.
	decorated_icon = "jelly_homer"

/obj/item/food/donut/jelly/trumpet
	name = "spaceman's jelly donut"
	desc = "Goes great with a cold beaker of malk."
	icon_state = "jelly_purple"
	food_reagents = list(
		/datum/reagent/consumable/nutriment = 3,
		/datum/reagent/consumable/sugar = 3,
		/datum/reagent/consumable/sprinkles = 1,
		/datum/reagent/consumable/nutriment/vitamin = 1,
	)
	tastes = list("jelly" = 1, "donut" = 3, "violets" = 1)
	is_decorated = TRUE
	crafting_complexity = FOOD_COMPLEXITY_3

/obj/item/food/donut/jelly/apple
	name = "apple jelly donut"
	desc = "Goes great with a shot of cinnamon schnapps."
	icon_state = "jelly_green"
	food_reagents = list(
		/datum/reagent/consumable/nutriment = 3,
		/datum/reagent/consumable/sugar = 3,
		/datum/reagent/consumable/applejuice = 3,
		/datum/reagent/consumable/sprinkles = 1,
		/datum/reagent/consumable/nutriment/vitamin = 1,
	)
	tastes = list("jelly" = 1, "donut" = 3, "green apples" = 1)
	is_decorated = TRUE

/obj/item/food/donut/jelly/caramel
	name = "caramel jelly donut"
	desc = "Goes great with a mug of hot coco."
	icon_state = "jelly_beige"
	food_reagents = list(
		/datum/reagent/consumable/nutriment = 3,
		/datum/reagent/consumable/sugar = 3,
		/datum/reagent/consumable/caramel = 3,
		/datum/reagent/consumable/sprinkles = 1,
		/datum/reagent/consumable/nutriment/vitamin = 1,
	)
	tastes = list("jelly" = 1, "donut" = 3, "buttery sweetness" = 1)
	is_decorated = TRUE

/obj/item/food/donut/jelly/choco
	name = "chocolate jelly donut"
	desc = "Goes great with a glass of warm milk."
	icon_state = "jelly_choc"
	food_reagents = list(
		/datum/reagent/consumable/nutriment = 3,
		/datum/reagent/consumable/sugar = 3,
		/datum/reagent/consumable/hot_coco = 3,
		/datum/reagent/consumable/sprinkles = 1,
		/datum/reagent/consumable/nutriment/vitamin = 1,
	)
	tastes = list("jelly" = 1, "donut" = 4, "bitterness" = 1)
	decorated_icon = "jelly_choc_sprinkles"
	crafting_complexity = FOOD_COMPLEXITY_3

/obj/item/food/donut/jelly/blumpkin
	name = "blumpkin jelly donut"
	desc = "Goes great with a mug of soothing drunken blumpkin."
	icon_state = "jelly_blue"
	food_reagents = list(
		/datum/reagent/consumable/nutriment = 3,
		/datum/reagent/consumable/sugar = 3,
		/datum/reagent/consumable/blumpkinjuice = 3,
		/datum/reagent/consumable/sprinkles = 1,
		/datum/reagent/consumable/nutriment/vitamin = 1,
	)
	tastes = list("jelly" = 1, "donut" = 2, "blumpkin" = 1)
	is_decorated = TRUE
	crafting_complexity = FOOD_COMPLEXITY_3

/obj/item/food/donut/jelly/bungo
	name = "bungo jelly donut"
	desc = "Goes great with a mason jar of hippie's delight."
	icon_state = "jelly_yellow"
	food_reagents = list(
		/datum/reagent/consumable/nutriment = 3,
		/datum/reagent/consumable/sugar = 3,
		/datum/reagent/consumable/bungojuice = 3,
		/datum/reagent/consumable/sprinkles = 1,
		/datum/reagent/consumable/nutriment/vitamin = 1,
	)
	tastes = list("jelly" = 1, "donut" = 3, "tropical sweetness" = 1)
	is_decorated = TRUE

/obj/item/food/donut/jelly/matcha
	name = "matcha jelly donut"
	desc = "Goes great with a cup of tea."
	icon_state = "jelly_olive"
	food_reagents = list(
		/datum/reagent/consumable/nutriment = 3,
		/datum/reagent/consumable/sugar = 3,
		/datum/reagent/toxin/teapowder = 3,
		/datum/reagent/consumable/sprinkles = 1,
		/datum/reagent/consumable/nutriment/vitamin = 1,
	)
	tastes = list("jelly" = 1, "donut" = 3, "matcha" = 1)
	is_decorated = TRUE

/obj/item/food/donut/jelly/laugh
	name = "sweet pea jelly donut"
	desc = "Goes great with a bottle of Bastion Bourbon!"
	icon_state = "jelly_laugh"
	food_reagents = list(
		/datum/reagent/consumable/nutriment = 3,
		/datum/reagent/consumable/sugar = 3,
		/datum/reagent/consumable/laughter = 3,
	)
	tastes = list("jelly" = 3, "donut" = 1, "fizzy tutti frutti" = 1)
	is_decorated = TRUE
	crafting_complexity = FOOD_COMPLEXITY_3

//////////////////////////SLIME DONUTS/////////////////////////

/obj/item/food/donut/jelly/slimejelly
	name = "jelly donut"
	desc = "You jelly?"
	extra_reagent = /datum/reagent/toxin/slimejelly
	foodtypes = JUNKFOOD | GRAIN | FRIED | TOXIC | SUGAR | BREAKFAST

/obj/item/food/donut/jelly/slimejelly/plain
	icon_state = "jelly"

/obj/item/food/donut/jelly/slimejelly/berry
	name = "pink jelly donut"
	desc = "Goes great with a soy latte."
	icon_state = "jelly_pink"
	food_reagents = list(
		/datum/reagent/consumable/nutriment = 3,
		/datum/reagent/consumable/sugar = 3,
		/datum/reagent/consumable/berryjuice = 3,
		/datum/reagent/consumable/sprinkles = 1,
		/datum/reagent/consumable/nutriment/vitamin = 1,
	) //Extra sprinkles to reward frosting

/obj/item/food/donut/jelly/slimejelly/trumpet
	name = "spaceman's jelly donut"
	desc = "Goes great with a cold beaker of malk."
	icon_state = "jelly_purple"
	food_reagents = list(
		/datum/reagent/consumable/nutriment = 3,
		/datum/reagent/consumable/sugar = 3,
		/datum/reagent/consumable/sprinkles = 1,
		/datum/reagent/consumable/nutriment/vitamin = 1,
	)
	tastes = list("jelly" = 1, "donut" = 3, "violets" = 1)
	is_decorated = TRUE
	crafting_complexity = FOOD_COMPLEXITY_3

/obj/item/food/donut/jelly/slimejelly/apple
	name = "apple jelly donut"
	desc = "Goes great with a shot of cinnamon schnapps."
	icon_state = "jelly_green"
	food_reagents = list(
		/datum/reagent/consumable/nutriment = 3,
		/datum/reagent/consumable/sugar = 3,
		/datum/reagent/consumable/applejuice = 3,
		/datum/reagent/consumable/sprinkles = 1,
		/datum/reagent/consumable/nutriment/vitamin = 1,
	)
	tastes = list("jelly" = 1, "donut" = 3, "green apples" = 1)
	is_decorated = TRUE

/obj/item/food/donut/jelly/slimejelly/caramel
	name = "caramel jelly donut"
	desc = "Goes great with a mug of hot coco."
	icon_state = "jelly_beige"
	food_reagents = list(
		/datum/reagent/consumable/nutriment = 3,
		/datum/reagent/consumable/sugar = 3,
		/datum/reagent/consumable/caramel = 3,
		/datum/reagent/consumable/sprinkles = 1,
		/datum/reagent/consumable/nutriment/vitamin = 1,
	)
	tastes = list("jelly" = 1, "donut" = 3, "buttery sweetness" = 1)
	is_decorated = TRUE

/obj/item/food/donut/jelly/slimejelly/choco
	name = "chocolate jelly donut"
	desc = "Goes great with a glass of warm milk."
	icon_state = "jelly_choc"
	food_reagents = list(
		/datum/reagent/consumable/nutriment = 3,
		/datum/reagent/consumable/sugar = 3,
		/datum/reagent/consumable/hot_coco = 3,
		/datum/reagent/consumable/sprinkles = 1,
		/datum/reagent/consumable/nutriment/vitamin = 1,
	)
	tastes = list("jelly" = 1, "donut" = 4, "bitterness" = 1)
	decorated_icon = "jelly_choc_sprinkles"
	crafting_complexity = FOOD_COMPLEXITY_3

/obj/item/food/donut/jelly/slimejelly/blumpkin
	name = "blumpkin jelly donut"
	desc = "Goes great with a mug of soothing drunken blumpkin."
	icon_state = "jelly_blue"
	food_reagents = list(
		/datum/reagent/consumable/nutriment = 3,
		/datum/reagent/consumable/sugar = 3,
		/datum/reagent/consumable/blumpkinjuice = 3,
		/datum/reagent/consumable/sprinkles = 1,
		/datum/reagent/consumable/nutriment/vitamin = 1,
	)
	tastes = list("jelly" = 1, "donut" = 2, "blumpkin" = 1)
	is_decorated = TRUE
	crafting_complexity = FOOD_COMPLEXITY_3

/obj/item/food/donut/jelly/slimejelly/bungo
	name = "bungo jelly donut"
	desc = "Goes great with a mason jar of hippie's delight."
	icon_state = "jelly_yellow"
	food_reagents = list(
		/datum/reagent/consumable/nutriment = 3,
		/datum/reagent/consumable/sugar = 3,
		/datum/reagent/consumable/bungojuice = 3,
		/datum/reagent/consumable/sprinkles = 1,
		/datum/reagent/consumable/nutriment/vitamin = 1,
	)
	tastes = list("jelly" = 1, "donut" = 3, "tropical sweetness" = 1)
	is_decorated = TRUE

/obj/item/food/donut/jelly/slimejelly/matcha
	name = "matcha jelly donut"
	desc = "Goes great with a cup of tea."
	icon_state = "jelly_olive"
	food_reagents = list(
		/datum/reagent/consumable/nutriment = 3,
		/datum/reagent/consumable/sugar = 3,
		/datum/reagent/toxin/teapowder = 3,
		/datum/reagent/consumable/sprinkles = 1,
		/datum/reagent/consumable/nutriment/vitamin = 1,
	)
	tastes = list("jelly" = 1, "donut" = 3, "matcha" = 1)
	is_decorated = TRUE

/obj/item/food/donut/jelly/slimejelly/laugh
	name = "sweet pea jelly donut"
	desc = "Goes great with a bottle of Bastion Bourbon!"
	icon_state = "jelly_laugh"
	food_reagents = list(
		/datum/reagent/consumable/nutriment = 3,
		/datum/reagent/consumable/sugar = 3,
		/datum/reagent/consumable/laughter = 3,
	)
	tastes = list("jelly" = 3, "donut" = 1, "fizzy tutti frutti" = 1)
	is_decorated = TRUE
	crafting_complexity = FOOD_COMPLEXITY_3

#undef DONUT_SPRINKLE_CHANCE
