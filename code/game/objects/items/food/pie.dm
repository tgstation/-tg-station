/obj/item/food/pie
	icon = 'icons/obj/food/piecake.dmi'
	inhand_icon_state = "pie"
	bite_consumption = 3
	w_class = WEIGHT_CLASS_NORMAL
	max_volume = 80
	food_reagents = list(/datum/reagent/consumable/nutriment = 10, /datum/reagent/consumable/nutriment/vitamin = 2)
	tastes = list("pie" = 1)
	foodtypes = GRAIN
	venue_value = FOOD_PRICE_NORMAL
	crafting_complexity = FOOD_COMPLEXITY_2
	/// type is spawned 5 at a time and replaces this pie when processed by cutting tool
	var/obj/item/food/pieslice/slice_type
	/// so that the yield can change if it isn't 5
	var/yield = 5

/obj/item/food/pie/make_processable()
	if (slice_type)
		AddElement(/datum/element/processable, TOOL_KNIFE, slice_type, yield, table_required = TRUE, screentip_verb = "Slice")

/obj/item/food/pieslice
	name = "pie slice"
	icon = 'icons/obj/food/piecake.dmi'
	w_class = WEIGHT_CLASS_TINY
	food_reagents = list(/datum/reagent/consumable/nutriment = 2)
	tastes = list("pie" = 1, "uncertainty" = 1)
	foodtypes = GRAIN | VEGETABLES
	crafting_complexity = FOOD_COMPLEXITY_2

/obj/item/food/pie/plain
	name = "plain pie"
	desc = "A simple pie, still delicious."
	icon_state = "pie"
	food_reagents = list(
		/datum/reagent/consumable/nutriment = 8,
		/datum/reagent/consumable/nutriment/vitamin = 1,
	)
	tastes = list("pie" = 1)
	foodtypes = GRAIN
	crafting_complexity = FOOD_COMPLEXITY_2

/obj/item/food/pie/plain/Initialize(mapload)
	. = ..()
	AddComponent(/datum/component/ingredients_holder, /obj/item/food/pie/empty, CUSTOM_INGREDIENT_ICON_FILL, max_ingredients = 8)

/obj/item/food/pie/empty
	name = "pie"
	desc = "A custom pie made by a crazed chef."
	icon_state = "pie_custom"
	foodtypes = GRAIN
	slice_type = /obj/item/food/pieslice/empty

/obj/item/food/pieslice/empty
	name = "pie slice"
	desc = "A custom pie slice made by a crazed chef."
	icon_state = "pie_custom_slice"
	foodtypes = GRAIN

/obj/item/food/pieslice/empty/Initialize(mapload)
	. = ..()
	AddComponent(/datum/component/ingredients_holder, null, CUSTOM_INGREDIENT_ICON_FILL, max_ingredients = 8)

/obj/item/food/pie/cream
	name = "banana cream pie"
	desc = "Just like back home, on clown planet! HONK!"
	icon_state = "pie"
	food_reagents = list(
		/datum/reagent/consumable/nutriment = 8,
		/datum/reagent/consumable/banana = 5,
		/datum/reagent/consumable/nutriment/vitamin = 4,
	)
	tastes = list("pie" = 1)
	foodtypes = GRAIN | DAIRY | SUGAR
	var/stunning = TRUE
	crafting_complexity = FOOD_COMPLEXITY_3

/obj/item/food/pie/cream/Initialize(mapload)
	. = ..()
	AddComponent(/datum/component/splat, hit_callback = CALLBACK(src, PROC_REF(stun_and_blur)))

/obj/item/food/pie/cream/proc/stun_and_blur(mob/living/victim, can_splat_on)
	if(stunning)
		victim.Paralyze(2 SECONDS) //splat!
	if(can_splat_on)
		victim.adjust_eye_blur(2 SECONDS)
	victim.visible_message(span_warning("[victim] is creamed by [src]!"), span_userdanger("You've been creamed by [src]!"))
	playsound(victim, SFX_DESECRATION, 50, TRUE)

/obj/item/food/pie/cream/nostun
	stunning = FALSE

/obj/item/food/pie/berryclafoutis
	name = "berry clafoutis"
	desc = "No black birds, this is a good sign."
	icon_state = "berryclafoutis"
	food_reagents = list(
		/datum/reagent/consumable/nutriment = 11,
		/datum/reagent/consumable/berryjuice = 5,
		/datum/reagent/consumable/nutriment/vitamin = 4,
	)
	tastes = list("pie" = 1, "blackberries" = 1)
	foodtypes = GRAIN | FRUIT | SUGAR
	venue_value = FOOD_PRICE_NORMAL
	crafting_complexity = FOOD_COMPLEXITY_3

/obj/item/food/pie/bearypie
	name = "beary pie"
	desc = "No brown bears, this is a good sign."
	icon_state = "bearypie"
	food_reagents = list(
		/datum/reagent/consumable/nutriment = 12,
		/datum/reagent/consumable/nutriment/protein = 5,
		/datum/reagent/consumable/nutriment/vitamin = 5,
	)
	tastes = list("pie" = 1, "meat" = 1, "salmon" = 1)
	foodtypes = GRAIN | SUGAR | MEAT | FRUIT
	crafting_complexity = FOOD_COMPLEXITY_4

/obj/item/food/pie/meatpie
	name = "meat-pie"
	icon_state = "meatpie"
	desc = "An old barber recipe, very delicious!"
	food_reagents = list(
		/datum/reagent/consumable/nutriment = 10,
		/datum/reagent/consumable/nutriment/vitamin = 4,
		/datum/reagent/consumable/nutriment/protein = 2,
	)
	tastes = list("pie" = 1, "meat" = 1)
	foodtypes = GRAIN | MEAT
	venue_value = FOOD_PRICE_NORMAL
	slice_type = /obj/item/food/pieslice/meatpie
	crafting_complexity = FOOD_COMPLEXITY_3

/obj/item/food/pieslice/meatpie
	name = "meat-pie slice"
	desc = "Oh nice, meat pie!"
	icon_state = "meatpie_slice"
	tastes = list("pie" = 1, "meat" = 1)
	foodtypes = GRAIN | MEAT
	crafting_complexity = FOOD_COMPLEXITY_3

/obj/item/food/pie/tofupie
	name = "tofu-pie"
	icon_state = "meatpie"
	desc = "A delicious tofu pie."
	food_reagents = list(
		/datum/reagent/consumable/nutriment = 11,
		/datum/reagent/consumable/nutriment/protein = 1,
		/datum/reagent/consumable/nutriment/vitamin = 6,
	)
	tastes = list("pie" = 1, "tofu" = 1)
	foodtypes = GRAIN | VEGETABLES
	slice_type = /obj/item/food/pieslice/tofupie
	crafting_complexity = FOOD_COMPLEXITY_3

/obj/item/food/pieslice/tofupie
	name = "tofu-pie slice"
	desc = "Oh nice, meat pie- WAIT A MINUTE!!"
	icon_state = "meatpie_slice"
	tastes = list("pie" = 1, "disappointment" = 1, "tofu" = 1)
	foodtypes = GRAIN | VEGETABLES
	crafting_complexity = FOOD_COMPLEXITY_3

/obj/item/food/pie/amanita_pie
	name = "amanita pie"
	desc = "Sweet and tasty poison pie."
	icon_state = "amanita_pie"
	bite_consumption = 4
	food_reagents = list(
		/datum/reagent/consumable/nutriment = 6,
		/datum/reagent/toxin/amatoxin = 3,
		/datum/reagent/drug/mushroomhallucinogen = 1,
		/datum/reagent/consumable/nutriment/vitamin = 4,
	)
	tastes = list("pie" = 1, "mushroom" = 1)
	foodtypes = GRAIN | VEGETABLES | TOXIC | GROSS
	crafting_complexity = FOOD_COMPLEXITY_3

/obj/item/food/pie/plump_pie
	name = "plump pie"
	desc = "I bet you love stuff made out of plump helmets!"
	icon_state = "plump_pie"
	food_reagents = list(
		/datum/reagent/consumable/nutriment = 11,
		/datum/reagent/consumable/nutriment/vitamin = 4,
	)
	tastes = list("pie" = 1, "mushroom" = 1)
	foodtypes = GRAIN | VEGETABLES
	crafting_complexity = FOOD_COMPLEXITY_3

/obj/item/food/pie/plump_pie/Initialize(mapload)
	var/fey = prob(10)
	if(fey)
		name = "exceptional plump pie"
		desc = "Microwave is taken by a fey mood! It has cooked an exceptional plump pie!"
		food_reagents = list(
			/datum/reagent/consumable/nutriment = 11,
			/datum/reagent/medicine/omnizine = 5,
			/datum/reagent/consumable/nutriment/vitamin = 4,
		)
	. = ..()

/obj/item/food/pie/xemeatpie
	name = "xeno-pie"
	icon_state = "xenomeatpie"
	desc = "A delicious meatpie. Probably heretical."
	food_reagents = list(
		/datum/reagent/consumable/nutriment = 11,
		/datum/reagent/consumable/nutriment/protein = 4,
		/datum/reagent/consumable/nutriment/vitamin = 6,
	)
	tastes = list("pie" = 1, "meat" = 1, "acid" = 1)
	foodtypes = GRAIN | MEAT
	slice_type = /obj/item/food/pieslice/xemeatpie
	crafting_complexity = FOOD_COMPLEXITY_3

/obj/item/food/pieslice/xemeatpie
	name = "xeno-pie slice"
	desc = "Oh god... Is that still moving?"
	icon_state = "xenopie_slice"
	tastes = list("pie" = 1, "acid" = 1, "meat" = 1)
	foodtypes = GRAIN | MEAT
	crafting_complexity = FOOD_COMPLEXITY_3

/obj/item/food/pie/applepie
	name = "apple pie"
	desc = "A pie containing sweet sweet love... or apple."
	icon_state = "applepie"
	food_reagents = list(
		/datum/reagent/consumable/nutriment = 11,
		/datum/reagent/consumable/nutriment/vitamin = 5,
	)
	tastes = list("pie" = 1, "apple" = 1)
	foodtypes = GRAIN | FRUIT | SUGAR
	slice_type = /obj/item/food/pieslice/apple
	crafting_complexity = FOOD_COMPLEXITY_3

/obj/item/food/pieslice/apple
	name = "apple pie slice"
	desc = "A slice of comfy apple pie, warm autumn memories ahead."
	icon_state = "applepie_slice"
	tastes = list("pie" = 1, "apples" = 1)
	foodtypes = GRAIN | FRUIT | SUGAR
	crafting_complexity = FOOD_COMPLEXITY_3


/obj/item/food/pie/cherrypie
	name = "cherry pie"
	desc = "Taste so good, make a grown man cry."
	icon_state = "cherrypie"
	food_reagents = list(
		/datum/reagent/consumable/nutriment = 11,
		/datum/reagent/consumable/nutriment/vitamin = 5,
	)
	tastes = list("pie" = 7, "Nicole Paige Brooks" = 2)
	foodtypes = GRAIN | FRUIT | SUGAR
	slice_type = /obj/item/food/pieslice/cherry
	crafting_complexity = FOOD_COMPLEXITY_3

/obj/item/food/pieslice/cherry
	name = "cherry pie slice"
	desc = "A slice of delicious cherry pie, I hope it's morellos!"
	icon_state = "cherrypie_slice"
	tastes = list("pie" = 1, "apples" = 1)
	foodtypes = GRAIN | FRUIT | SUGAR
	crafting_complexity = FOOD_COMPLEXITY_3

/obj/item/food/pie/pumpkinpie
	name = "pumpkin pie"
	desc = "A delicious treat for the autumn months."
	icon_state = "pumpkinpie"
	food_reagents = list(
		/datum/reagent/consumable/nutriment = 11,
		/datum/reagent/consumable/nutriment/vitamin = 5,
	)
	tastes = list("pie" = 1, "pumpkin" = 1)
	foodtypes = GRAIN | VEGETABLES | SUGAR
	slice_type = /obj/item/food/pieslice/pumpkin
	crafting_complexity = FOOD_COMPLEXITY_3

/obj/item/food/pieslice/pumpkin
	name = "pumpkin pie slice"
	desc = "A slice of pumpkin pie, with whipped cream on top. Perfection."
	icon_state = "pumpkinpieslice"
	tastes = list("pie" = 1, "pumpkin" = 1)
	foodtypes = GRAIN | VEGETABLES | SUGAR
	crafting_complexity = FOOD_COMPLEXITY_3

/obj/item/food/pie/appletart
	name = "golden apple streusel tart"
	desc = "A tasty dessert that won't make it through a metal detector."
	icon_state = "gappletart"
	food_reagents = list(
		/datum/reagent/consumable/nutriment = 8,
		/datum/reagent/gold = 5,
		/datum/reagent/consumable/nutriment/vitamin = 4,
	)
	tastes = list("pie" = 1, "apple" = 1, "expensive metal" = 1)
	foodtypes = GRAIN | FRUIT | SUGAR
	crafting_complexity = FOOD_COMPLEXITY_4

/obj/item/food/pie/grapetart
	name = "grape tart"
	desc = "A tasty dessert that reminds you of the wine you didn't make."
	icon_state = "grapetart"
	food_reagents = list(
		/datum/reagent/consumable/nutriment = 4,
		/datum/reagent/consumable/nutriment/vitamin = 4,
	)
	tastes = list("pie" = 1, "grape" = 1)
	foodtypes = GRAIN | FRUIT | SUGAR
	crafting_complexity = FOOD_COMPLEXITY_4

/obj/item/food/pie/mimetart
	name = "mime tart"
	desc = "..."
	icon_state = "mimetart"
	food_reagents = list(
		/datum/reagent/consumable/nutriment = 5,
		/datum/reagent/consumable/nutriment/vitamin = 5,
		/datum/reagent/consumable/nothing = 10,
	)
	tastes = list("nothing" = 3)
	foodtypes = GRAIN
	crafted_food_buff = /datum/status_effect/food/trait/mute

/obj/item/food/pie/berrytart
	name = "berry tart"
	desc = "A tasty dessert of many different small barries on a thin pie crust."
	icon_state = "berrytart"
	food_reagents = list(
		/datum/reagent/consumable/nutriment = 3,
		/datum/reagent/consumable/nutriment/vitamin = 5,
	)
	tastes = list("pie" = 1, "berries" = 2)
	foodtypes = GRAIN | FRUIT

/obj/item/food/pie/cocolavatart
	name = "chocolate lava tart"
	desc = "A tasty dessert made of chocolate, with a liquid core." //But it doesn't even contain chocolate...
	icon_state = "cocolavatart"
	food_reagents = list(
		/datum/reagent/consumable/nutriment = 4,
		/datum/reagent/consumable/nutriment/vitamin = 4,
	)
	tastes = list("pie" = 1, "dark chocolate" = 3)
	foodtypes = GRAIN | SUGAR

/obj/item/food/pie/blumpkinpie
	name = "blumpkin pie"
	desc = "An odd blue pie made with toxic blumpkin."
	icon_state = "blumpkinpie"
	food_reagents = list(
		/datum/reagent/consumable/nutriment = 13,
		/datum/reagent/consumable/nutriment/vitamin = 6,
	)
	tastes = list("pie" = 1, "a mouthful of pool water" = 1)
	foodtypes = GRAIN | VEGETABLES
	slice_type = /obj/item/food/pieslice/blumpkin
	crafting_complexity = FOOD_COMPLEXITY_3

/obj/item/food/pieslice/blumpkin
	name = "blumpkin pie slice"
	desc = "A slice of blumpkin pie, with whipped cream on top. Is this edible?"
	icon_state = "blumpkinpieslice"
	tastes = list("pie" = 1, "a mouthful of pool water" = 1)
	foodtypes = GRAIN | VEGETABLES
	crafting_complexity = FOOD_COMPLEXITY_3

/obj/item/food/pie/dulcedebatata
	name = "dulce de batata"
	desc = "A delicious jelly made with sweet potatoes."
	icon_state = "dulcedebatata"
	food_reagents = list(
		/datum/reagent/consumable/nutriment = 14,
		/datum/reagent/consumable/nutriment/vitamin = 8,
	)
	tastes = list("jelly" = 1, "sweet potato" = 1)
	foodtypes = VEGETABLES | SUGAR
	venue_value = FOOD_PRICE_EXOTIC
	slice_type = /obj/item/food/pieslice/dulcedebatata
	crafting_complexity = FOOD_COMPLEXITY_3

/obj/item/food/pieslice/dulcedebatata
	name = "dulce de batata slice"
	desc = "A slice of sweet dulce de batata jelly."
	icon_state = "dulcedebatataslice"
	tastes = list("jelly" = 1, "sweet potato" = 1)
	foodtypes = VEGETABLES | SUGAR
	crafting_complexity = FOOD_COMPLEXITY_3

/obj/item/food/pie/frostypie
	name = "frosty pie"
	desc = "Tastes like blue and cold."
	icon_state = "frostypie"
	food_reagents = list(
		/datum/reagent/consumable/nutriment = 14,
		/datum/reagent/consumable/nutriment/vitamin = 6,
	)
	tastes = list("mint" = 1, "pie" = 1)
	foodtypes = GRAIN | FRUIT | SUGAR
	slice_type = /obj/item/food/pieslice/frostypie
	crafting_complexity = FOOD_COMPLEXITY_3

/obj/item/food/pieslice/frostypie
	name = "frosty pie slice"
	desc = "Tasty blue, like my favourite crayon!"
	icon_state = "frostypie_slice"
	tastes = list("pie" = 1, "mint" = 1)
	foodtypes = GRAIN | FRUIT | SUGAR
	crafting_complexity = FOOD_COMPLEXITY_3

/obj/item/food/pie/baklava
	name = "baklava"
	desc = "A delightful healthy snack made of nut layers with thin bread."
	icon_state = "baklava"
	food_reagents = list(
		/datum/reagent/consumable/nutriment = 12,
		/datum/reagent/consumable/nutriment/vitamin = 6,
	)
	tastes = list("nuts" = 1, "pie" = 1)
	foodtypes = NUTS | SUGAR
	slice_type = /obj/item/food/pieslice/baklava
	yield = 6
	crafting_complexity = FOOD_COMPLEXITY_4

/obj/item/food/pieslice/baklava
	name = "baklava dish"
	desc = "A portion of a delightful healthy snack made of nut layers with thin bread"
	icon_state = "baklavaslice"
	tastes = list("nuts" = 1, "pie" = 1)
	foodtypes = NUTS | SUGAR
	crafting_complexity = FOOD_COMPLEXITY_4

/obj/item/food/pie/frenchsilkpie
	name = "french silk pie"
	desc = "A decadent pie made of a creamy chocolate mousse filling topped with a layer of whipped cream and chocolate shavings. Sliceable."
	icon_state = "frenchsilkpie"
	food_reagents = list(
		/datum/reagent/consumable/nutriment = 12,
		/datum/reagent/consumable/nutriment/vitamin = 4,
	)
	tastes = list("pie" = 1, "smooth chocolate" = 1, "whipped cream" = 1)
	foodtypes = GRAIN | DAIRY | SUGAR
	slice_type = /obj/item/food/pieslice/frenchsilk
	crafting_complexity = FOOD_COMPLEXITY_3

/obj/item/food/pieslice/frenchsilk
	name = "french silk pie slice"
	desc = "A slice of french silk pie, filled with a chocolate mousse and topped with a layer of whipped cream and chocolate shavings. Delicious enough to make you cry."
	icon_state = "frenchsilkpieslice"
	tastes = list("pie" = 1, "smooth chocolate" = 1, "whipped cream" = 1)
	foodtypes = GRAIN | DAIRY | SUGAR
	crafting_complexity = FOOD_COMPLEXITY_3

/obj/item/food/pie/shepherds_pie
	name = "shepherds pie"
	desc = "A dish of minced meat and mixed vegetables baked under a layer of creamy mashed potatoes. Sliceable."
	icon_state = "shepherds_pie"
	food_reagents = list(
		/datum/reagent/consumable/nutriment = 40,
		/datum/reagent/consumable/nutriment/vitamin = 12,
		/datum/reagent/consumable/nutriment/protein = 20,
	)
	tastes = list("juicy meat" = 2, "mashed potatoes" = 2, "baked veggies" = 2)
	foodtypes = MEAT | DAIRY | VEGETABLES
	slice_type = /obj/item/food/pieslice/shepherds_pie
	yield = 4
	crafting_complexity = FOOD_COMPLEXITY_5

/obj/item/food/pieslice/shepherds_pie
	name = "shepherds pie slice"
	desc = "A messy slice of shepherds pie, made of minced meat and mixed vegetables baked under a layer of creamy mashed potatoes. Dangerously tasty."
	icon_state = "shepherds_pie_slice"
	food_reagents = list(
		/datum/reagent/consumable/nutriment = 10,
		/datum/reagent/consumable/nutriment/vitamin = 3,
		/datum/reagent/consumable/nutriment/protein = 5,
	)
	tastes = list("juicy meat" = 1, "mashed potatoes" = 1, "baked veggies" = 1)
	foodtypes = MEAT | DAIRY | VEGETABLES
	crafting_complexity = FOOD_COMPLEXITY_5

/obj/item/food/pie/asdfpie
	name = "pie-flavored pie"
	desc = "I baked you a pie!"
	icon_state = "asdfpie"
	food_reagents = list(
		/datum/reagent/consumable/nutriment = 16,
		/datum/reagent/consumable/nutriment/vitamin = 2,
	)
	tastes = list("pie" = 1, "the far off year of 2010" = 1)
	foodtypes = GRAIN
	crafting_complexity = FOOD_COMPLEXITY_2

/obj/item/food/pie/bacid_pie
	name = "battery acid pie"
	desc = "Ooh it's a pie made of... battery acid? You suppose an ethereal could find some enjoyement in eating this."
	icon_state = "bacid_pie"
	food_reagents = list(
		/datum/reagent/consumable/nutriment = 18,
		/datum/reagent/consumable/liquidelectricity/enriched = 18
	)
	tastes = list("battery acid" = 2, "electricity" = 2, "a cyber world" = 2)
	foodtypes = TOXIC
	slice_type = /obj/item/food/pieslice/bacid_pie
	yield = 4
	crafting_complexity = FOOD_COMPLEXITY_3


/obj/item/food/pieslice/bacid_pie
	name = "battery acid pie slice"
	desc = "The battery acid filling has a concerningly appealing bright green color"
	icon_state = "bacid_pie_slice"
	food_reagents = list(
		/datum/reagent/consumable/nutriment = 4.5,
		/datum/reagent/consumable/liquidelectricity/enriched = 4.5
	)
	tastes = list("battery acid" = 1, "electricity" = 1, "a cyber world" = 1)
	foodtypes = TOXIC
	crafting_complexity = FOOD_COMPLEXITY_3
