/*
Mineral Sheets
	Contains:
		- Sandstone
		- Sandbags
		- Diamond
		- Snow
		- Uranium
		- Plasma
		- Gold
		- Silver
		- Clown
		- Titanium
		- Plastitanium
	Others:
		- Adamantine
		- Mythril
		- Alien Alloy
		- Coal
*/

/*
 * Sandstone
 */

GLOBAL_LIST_INIT(sandstone_recipes, list ( \
	new/datum/stack_recipe("sandstone door", /obj/structure/mineral_door/sandstone, 10, time = 5 SECONDS, crafting_flags = CRAFT_CHECK_DENSITY | CRAFT_ONE_PER_TURF | CRAFT_ON_SOLID_GROUND | CRAFT_APPLIES_MATS, category = CAT_DOORS), \
	new/datum/stack_recipe("Breakdown into sand", /obj/item/stack/ore/glass, 1, crafting_flags = CRAFT_CHECK_DENSITY | CRAFT_ON_SOLID_GROUND, category = CAT_MISC) \
	))

/obj/item/stack/sheet/mineral/sandstone
	name = "sandstone brick"
	desc = "This appears to be a combination of both sand and stone."
	singular_name = "sandstone brick"
	icon_state = "sheet-sandstone"
	inhand_icon_state = null
	throw_speed = 3
	throw_range = 5
	mats_per_unit = list(/datum/material/sandstone=SHEET_MATERIAL_AMOUNT)
	sheettype = "sandstone"
	merge_type = /obj/item/stack/sheet/mineral/sandstone
	walltype = /turf/closed/wall/mineral/sandstone
	material_type = /datum/material/sandstone
	drop_sound = SFX_STONE_DROP
	pickup_sound = SFX_STONE_PICKUP

/obj/item/stack/sheet/mineral/sandstone/get_main_recipes()
	. = ..()
	. += GLOB.sandstone_recipes

/obj/item/stack/sheet/mineral/sandstone/thirty
	amount = 30

/*
 * Sandbags
 */

/obj/item/stack/sheet/mineral/sandbags
	name = "sandbags"
	icon_state = "sandbags"
	singular_name = "sandbag"
	layer = LOW_ITEM_LAYER
	novariants = TRUE
	merge_type = /obj/item/stack/sheet/mineral/sandbags

GLOBAL_LIST_INIT(sandbag_recipes, list ( \
	new/datum/stack_recipe("sandbags", /obj/structure/barricade/sandbags, 1, time = 3 SECONDS, crafting_flags = CRAFT_CHECK_DENSITY | CRAFT_ONE_PER_TURF | CRAFT_ON_SOLID_GROUND, category = CAT_STRUCTURE), \
	))

/obj/item/stack/sheet/mineral/sandbags/get_main_recipes()
	. = ..()
	. += GLOB.sandbag_recipes

/obj/item/emptysandbag
	name = "empty sandbag"
	desc = "A bag to be filled with sand."
	icon = 'icons/obj/stack_objects.dmi'
	icon_state = "sandbag"
	w_class = WEIGHT_CLASS_TINY

/obj/item/emptysandbag/attackby(obj/item/W, mob/user, params)
	if(istype(W, /obj/item/stack/ore/glass))
		var/obj/item/stack/ore/glass/G = W
		to_chat(user, span_notice("You fill the sandbag."))
		var/obj/item/stack/sheet/mineral/sandbags/I = new /obj/item/stack/sheet/mineral/sandbags(drop_location())
		qdel(src)
		if (Adjacent(user) && !issilicon(user))
			user.put_in_hands(I)
		G.use(1)
	else
		return ..()

/*
 * Diamond
 */
/obj/item/stack/sheet/mineral/diamond
	name = "diamond"
	icon_state = "sheet-diamond"
	inhand_icon_state = "sheet-diamond"
	singular_name = "diamond"
	sheettype = "diamond"
	mats_per_unit = list(/datum/material/diamond=SHEET_MATERIAL_AMOUNT)
	grind_results = list(/datum/reagent/carbon = 20)
	gulag_valid = TRUE
	merge_type = /obj/item/stack/sheet/mineral/diamond
	material_type = /datum/material/diamond
	walltype = /turf/closed/wall/mineral/diamond

GLOBAL_LIST_INIT(diamond_recipes, list ( \
	new/datum/stack_recipe("diamond door", /obj/structure/mineral_door/transparent/diamond, 10, time = 5 SECONDS, crafting_flags = CRAFT_CHECK_DENSITY | CRAFT_ONE_PER_TURF | CRAFT_ON_SOLID_GROUND | CRAFT_APPLIES_MATS, category = CAT_DOORS), \
	new/datum/stack_recipe("diamond tile", /obj/item/stack/tile/mineral/diamond, 1, 4, 20, crafting_flags = NONE, category = CAT_TILES),  \
	))

/obj/item/stack/sheet/mineral/diamond/get_main_recipes()
	. = ..()
	. += GLOB.diamond_recipes

/obj/item/stack/sheet/mineral/diamond/five
	amount = 5

/*
 * Uranium
 */
/obj/item/stack/sheet/mineral/uranium
	name = "uranium"
	icon_state = "sheet-uranium"
	inhand_icon_state = "sheet-uranium"
	singular_name = "uranium sheet"
	sheettype = "uranium"
	mats_per_unit = list(/datum/material/uranium=SHEET_MATERIAL_AMOUNT)
	grind_results = list(/datum/reagent/uranium = 20)
	gulag_valid = TRUE
	merge_type = /obj/item/stack/sheet/mineral/uranium
	material_type = /datum/material/uranium
	walltype = /turf/closed/wall/mineral/uranium

GLOBAL_LIST_INIT(uranium_recipes, list ( \
	new/datum/stack_recipe("uranium door", /obj/structure/mineral_door/uranium, 10, time = 5 SECONDS, crafting_flags = CRAFT_CHECK_DENSITY | CRAFT_ONE_PER_TURF | CRAFT_ON_SOLID_GROUND | CRAFT_APPLIES_MATS, category = CAT_DOORS), \
	new/datum/stack_recipe("uranium tile", /obj/item/stack/tile/mineral/uranium, 1, 4, 20, crafting_flags = NONE, category = CAT_TILES), \
	))

/obj/item/stack/sheet/mineral/uranium/get_main_recipes()
	. = ..()
	. += GLOB.uranium_recipes

/obj/item/stack/sheet/mineral/uranium/five
	amount = 5

/obj/item/stack/sheet/mineral/uranium/half
	amount = 25

/*
 * Plasma
 */
/obj/item/stack/sheet/mineral/plasma
	name = "solid plasma"
	icon_state = "sheet-plasma"
	inhand_icon_state = "sheet-plasma"
	singular_name = "plasma sheet"
	sheettype = "plasma"
	resistance_flags = FLAMMABLE
	max_integrity = 100
	mats_per_unit = list(/datum/material/plasma=SHEET_MATERIAL_AMOUNT)
	grind_results = list(/datum/reagent/toxin/plasma = 20)
	gulag_valid = TRUE
	merge_type = /obj/item/stack/sheet/mineral/plasma
	material_type = /datum/material/plasma
	walltype = /turf/closed/wall/mineral/plasma

/obj/item/stack/sheet/mineral/plasma/suicide_act(mob/living/carbon/user)
	user.visible_message(span_suicide("[user] begins licking \the [src]! It looks like [user.p_theyre()] trying to commit suicide!"))
	return TOXLOSS//dont you kids know that stuff is toxic?

GLOBAL_LIST_INIT(plasma_recipes, list ( \
	new/datum/stack_recipe("plasma door", /obj/structure/mineral_door/transparent/plasma, 10, time = 5 SECONDS, crafting_flags = CRAFT_CHECK_DENSITY | CRAFT_ONE_PER_TURF | CRAFT_ON_SOLID_GROUND | CRAFT_APPLIES_MATS, category = CAT_DOORS), \
	new/datum/stack_recipe("plasma tile", /obj/item/stack/tile/mineral/plasma, 1, 4, 20, crafting_flags = NONE, category = CAT_TILES), \
	))

/obj/item/stack/sheet/mineral/plasma/get_main_recipes()
	. = ..()
	. += GLOB.plasma_recipes

/obj/item/stack/sheet/mineral/plasma/five
	amount = 5

/obj/item/stack/sheet/mineral/plasma/thirty
	amount = 30

/*
 * Gold
 */
/obj/item/stack/sheet/mineral/gold
	name = "gold"
	icon_state = "sheet-gold"
	inhand_icon_state = "sheet-gold"
	singular_name = "gold bar"
	sheettype = "gold"
	mats_per_unit = list(/datum/material/gold=SHEET_MATERIAL_AMOUNT)
	grind_results = list(/datum/reagent/gold = 20)
	gulag_valid = TRUE
	merge_type = /obj/item/stack/sheet/mineral/gold
	material_type = /datum/material/gold
	walltype = /turf/closed/wall/mineral/gold

GLOBAL_LIST_INIT(gold_recipes, list ( \
	new/datum/stack_recipe("golden door", /obj/structure/mineral_door/gold, 10, time = 5 SECONDS, crafting_flags = CRAFT_CHECK_DENSITY | CRAFT_ONE_PER_TURF | CRAFT_ON_SOLID_GROUND | CRAFT_APPLIES_MATS, category = CAT_DOORS), \
	new/datum/stack_recipe("gold tile", /obj/item/stack/tile/mineral/gold, 1, 4, 20, crafting_flags = NONE, category = CAT_TILES), \
	new/datum/stack_recipe("blank plaque", /obj/item/plaque, 1, crafting_flags = NONE, category = CAT_FURNITURE), \
	new/datum/stack_recipe("Simple Crown", /obj/item/clothing/head/costume/crown, 5, crafting_flags = NONE, category = CAT_CLOTHING), \
	))

/obj/item/stack/sheet/mineral/gold/get_main_recipes()
	. = ..()
	. += GLOB.gold_recipes

/*
 * Silver
 */
/obj/item/stack/sheet/mineral/silver
	name = "silver"
	icon_state = "sheet-silver"
	inhand_icon_state = "sheet-silver"
	singular_name = "silver bar"
	sheettype = "silver"
	mats_per_unit = list(/datum/material/silver=SHEET_MATERIAL_AMOUNT)
	grind_results = list(/datum/reagent/silver = 20)
	gulag_valid = TRUE
	merge_type = /obj/item/stack/sheet/mineral/silver
	material_type = /datum/material/silver
	tableVariant = /obj/structure/table/optable
	walltype = /turf/closed/wall/mineral/silver

GLOBAL_LIST_INIT(silver_recipes, list ( \
	new/datum/stack_recipe("silver door", /obj/structure/mineral_door/silver, 10, time = 5 SECONDS, crafting_flags = CRAFT_CHECK_DENSITY | CRAFT_ONE_PER_TURF | CRAFT_ON_SOLID_GROUND | CRAFT_APPLIES_MATS, category = CAT_DOORS), \
	new/datum/stack_recipe("silver tile", /obj/item/stack/tile/mineral/silver, 1, 4, 20, crafting_flags = NONE, category = CAT_TILES), \
	))

/obj/item/stack/sheet/mineral/silver/get_main_recipes()
	. = ..()
	. += GLOB.silver_recipes

/*
 * Clown
 */
/obj/item/stack/sheet/mineral/bananium
	name = "bananium"
	icon_state = "sheet-bananium"
	inhand_icon_state = null
	singular_name = "bananium sheet"
	sheettype = "bananium"
	mats_per_unit = list(/datum/material/bananium=SHEET_MATERIAL_AMOUNT)
	grind_results = list(/datum/reagent/consumable/banana = 20)
	gulag_valid = TRUE
	merge_type = /obj/item/stack/sheet/mineral/bananium
	material_type = /datum/material/bananium
	walltype = /turf/closed/wall/mineral/bananium

GLOBAL_LIST_INIT(bananium_recipes, list ( \
	new/datum/stack_recipe("bananium tile", /obj/item/stack/tile/mineral/bananium, 1, 4, 20, crafting_flags = NONE, category = CAT_TILES), \
	))

/obj/item/stack/sheet/mineral/bananium/get_main_recipes()
	. = ..()
	. += GLOB.bananium_recipes

/obj/item/stack/sheet/mineral/bananium/five
	amount = 5

/*
 * Titanium
 */
/obj/item/stack/sheet/mineral/titanium
	name = "titanium"
	icon_state = "sheet-titanium"
	inhand_icon_state = "sheet-titanium"
	singular_name = "titanium sheet"
	force = 5
	throwforce = 5
	w_class = WEIGHT_CLASS_NORMAL
	throw_speed = 1
	throw_range = 3
	sheettype = "titanium"
	mats_per_unit = list(/datum/material/titanium=SHEET_MATERIAL_AMOUNT)
	gulag_valid = TRUE
	merge_type = /obj/item/stack/sheet/mineral/titanium
	material_type = /datum/material/titanium
	walltype = /turf/closed/wall/mineral/titanium

GLOBAL_LIST_INIT(titanium_recipes, list ( \
	new /datum/stack_recipe("Titanium tile", /obj/item/stack/tile/mineral/titanium, 1, 4, 20, crafting_flags = NONE, category = CAT_TILES), \
	new /datum/stack_recipe("Shuttle seat", /obj/structure/chair/comfy/shuttle, 2, crafting_flags = CRAFT_CHECK_DENSITY | CRAFT_ONE_PER_TURF | CRAFT_ON_SOLID_GROUND, category = CAT_FURNITURE), \
	new /datum/stack_recipe("Material tram door assembly", /obj/structure/door_assembly/multi_tile/door_assembly_tram, 8, time = 5 SECONDS, crafting_flags = CRAFT_CHECK_DENSITY | CRAFT_ONE_PER_TURF | CRAFT_ON_SOLID_GROUND, category = CAT_DOORS), \
	))

/obj/item/stack/sheet/mineral/titanium/get_main_recipes()
	. = ..()
	. += GLOB.titanium_recipes

/obj/item/stack/sheet/mineral/titanium/attackby(obj/item/W, mob/user, params)
	add_fingerprint(user)
	if(istype(W, /obj/item/stack/rods))
		var/obj/item/stack/rods/old_rods = W
		if(old_rods.merge_type != /obj/item/stack/rods)
			to_chat(user, span_warning("You can't craft shuttle frame rods with this type of rod!"))
		if (old_rods.get_amount() >= 5 && get_amount() >= 1)
			var/obj/item/stack/rods/shuttle/five/new_rods = new (get_turf(user))
			if(!QDELETED(new_rods))
				new_rods.add_fingerprint(user)
			var/replace = user.get_inactive_held_item() == src
			old_rods.use(5)
			use(1)
			if(QDELETED(src) && replace && !QDELETED(new_rods))
				user.put_in_hands(new_rods)
		else
			to_chat(user, span_warning("You need five rods and one sheet of titanium to make shuttle frame rods!"))
		return
	return ..()

/obj/item/stack/sheet/mineral/titanium/fifty
	amount = 50

/*
 * Plastitanium
 */
/obj/item/stack/sheet/mineral/plastitanium
	name = "plastitanium"
	icon_state = "sheet-plastitanium"
	inhand_icon_state = "sheet-plastitanium"
	singular_name = "plastitanium sheet"
	force = 5
	throwforce = 5
	w_class = WEIGHT_CLASS_NORMAL
	throw_speed = 1
	throw_range = 3
	sheettype = "plastitanium"
	mats_per_unit = list(/datum/material/alloy/plastitanium=SHEET_MATERIAL_AMOUNT)
	gulag_valid = TRUE
	material_type = /datum/material/alloy/plastitanium
	merge_type = /obj/item/stack/sheet/mineral/plastitanium
	material_flags = NONE
	walltype = /turf/closed/wall/mineral/plastitanium

GLOBAL_LIST_INIT(plastitanium_recipes, list ( \
	new/datum/stack_recipe("plastitanium tile", /obj/item/stack/tile/mineral/plastitanium, 1, 4, 20, crafting_flags = NONE, category = CAT_TILES), \
	))

/obj/item/stack/sheet/mineral/plastitanium/get_main_recipes()
	. = ..()
	. += GLOB.plastitanium_recipes


/*
 * Snow
 */

/obj/item/stack/sheet/mineral/snow
	name = "snow"
	icon_state = "sheet-snow"
	inhand_icon_state = null
	mats_per_unit = list(/datum/material/snow = SHEET_MATERIAL_AMOUNT)
	singular_name = "snow block"
	force = 1
	throwforce = 2
	grind_results = list(/datum/reagent/consumable/ice = 20)
	merge_type = /obj/item/stack/sheet/mineral/snow
	walltype = /turf/closed/wall/mineral/snow
	material_type = /datum/material/snow
	pickup_sound = 'sound/items/handling/materials/snow_pick_up.ogg'
	drop_sound = 'sound/items/handling/materials/snow_drop.ogg'

GLOBAL_LIST_INIT(snow_recipes, list ( \
	new/datum/stack_recipe("snow wall", /turf/closed/wall/mineral/snow, 5, time = 4 SECONDS, crafting_flags = CRAFT_CHECK_DENSITY | CRAFT_ONE_PER_TURF | CRAFT_ON_SOLID_GROUND, category = CAT_STRUCTURE), \
	new/datum/stack_recipe("snowman", /obj/structure/statue/snow/snowman, 5, crafting_flags = CRAFT_CHECK_DENSITY | CRAFT_ONE_PER_TURF | CRAFT_ON_SOLID_GROUND, category = CAT_ENTERTAINMENT), \
	new/datum/stack_recipe("snowball", /obj/item/toy/snowball, 1, crafting_flags = NONE, category = CAT_WEAPON_RANGED), \
	new/datum/stack_recipe("snow tile", /obj/item/stack/tile/mineral/snow, 1, 4, 20, crafting_flags = NONE, category = CAT_TILES), \
))

/obj/item/stack/sheet/mineral/snow/Initialize(mapload, new_amount, merge, list/mat_override, mat_amt)
	. = ..()
	AddComponent(/datum/component/storm_hating)

/obj/item/stack/sheet/mineral/snow/get_main_recipes()
	. = ..()
	. += GLOB.snow_recipes

/****************************** Others ****************************/

/*
 * Adamantine
*/


GLOBAL_LIST_INIT(adamantine_recipes, list(
	new /datum/stack_recipe("incomplete servant golem shell", /obj/item/golem_shell/servant, req_amount=3, res_amount=1, category = CAT_ROBOT),
	))

/obj/item/stack/sheet/mineral/adamantine
	name = "adamantine"
	icon_state = "sheet-adamantine"
	inhand_icon_state = "sheet-adamantine"
	singular_name = "adamantine sheet"
	mats_per_unit = list(/datum/material/adamantine=SHEET_MATERIAL_AMOUNT)
	merge_type = /obj/item/stack/sheet/mineral/adamantine

/obj/item/stack/sheet/mineral/adamantine/get_main_recipes()
	. = ..()
	. += GLOB.adamantine_recipes

/*
 * Runite
 */

/obj/item/stack/sheet/mineral/runite
	name = "runite"
	desc = "Rare material found in distant lands."
	singular_name = "runite bar"
	icon_state = "sheet-runite"
	inhand_icon_state = "sheet-runite"
	mats_per_unit = list(/datum/material/runite=SHEET_MATERIAL_AMOUNT)
	merge_type = /obj/item/stack/sheet/mineral/runite
	material_type = /datum/material/runite


/*
 * Mythril
 */
/obj/item/stack/sheet/mineral/mythril
	name = "mythril"
	icon_state = "sheet-mythril"
	inhand_icon_state = "sheet-mythril"
	singular_name = "mythril sheet"
	novariants = TRUE
	mats_per_unit = list(/datum/material/mythril=SHEET_MATERIAL_AMOUNT)
	merge_type = /obj/item/stack/sheet/mineral/mythril

/*
 * Alien Alloy
 */
/obj/item/stack/sheet/mineral/abductor
	name = "alien alloy"
	icon = 'icons/obj/antags/abductor.dmi'
	icon_state = "sheet-abductor"
	inhand_icon_state = "sheet-abductor"
	singular_name = "alien alloy sheet"
	sheettype = "abductor"
	mats_per_unit = list(/datum/material/alloy/alien=SHEET_MATERIAL_AMOUNT)
	merge_type = /obj/item/stack/sheet/mineral/abductor
	material_type = /datum/material/alloy/alien
	walltype = /turf/closed/wall/mineral/abductor

GLOBAL_LIST_INIT(abductor_recipes, list ( \
	new/datum/stack_recipe("alien bed", /obj/structure/bed/abductor, 2, crafting_flags = CRAFT_CHECK_DENSITY | CRAFT_ONE_PER_TURF | CRAFT_ON_SOLID_GROUND, category = CAT_FURNITURE), \
	new/datum/stack_recipe("alien locker", /obj/structure/closet/abductor, 2, time = 2 SECONDS, crafting_flags = CRAFT_CHECK_DENSITY | CRAFT_ONE_PER_TURF | CRAFT_ON_SOLID_GROUND, category = CAT_FURNITURE), \
	new/datum/stack_recipe("alien table frame", /obj/structure/table_frame/abductor, 1, time = 2 SECONDS, crafting_flags = CRAFT_CHECK_DENSITY | CRAFT_ONE_PER_TURF | CRAFT_ON_SOLID_GROUND, category = CAT_FURNITURE), \
	new/datum/stack_recipe("alien airlock assembly", /obj/structure/door_assembly/door_assembly_abductor, 4, time = 5 SECONDS, crafting_flags = CRAFT_CHECK_DENSITY | CRAFT_ONE_PER_TURF | CRAFT_ON_SOLID_GROUND, category = CAT_DOORS), \
	null, \
	new/datum/stack_recipe("alien floor tile", /obj/item/stack/tile/mineral/abductor, 1, 4, 20, crafting_flags = NONE, category = CAT_TILES), \
	))

/obj/item/stack/sheet/mineral/abductor/get_main_recipes()
	. = ..()
	. += GLOB.abductor_recipes

/*
 * Coal
 */

/obj/item/stack/sheet/mineral/coal
	name = "coal"
	desc = "Someone's gotten on the naughty list."
	icon = 'icons/obj/ore.dmi'
	icon_state = "slag"
	singular_name = "coal lump"
	merge_type = /obj/item/stack/sheet/mineral/coal
	grind_results = list(/datum/reagent/carbon = 20)
	novariants = TRUE

/obj/item/stack/sheet/mineral/coal/attackby(obj/item/W, mob/user, params)
	if(W.get_temperature() > 300)//If the temperature of the object is over 300, then ignite
		var/turf/T = get_turf(src)
		message_admins("Coal ignited by [ADMIN_LOOKUPFLW(user)] in [ADMIN_VERBOSEJMP(T)]")
		user.log_message("ignited coal", LOG_GAME)
		fire_act(W.get_temperature())
		return TRUE
	else
		return ..()

/obj/item/stack/sheet/mineral/coal/fire_act(exposed_temperature, exposed_volume)
	atmos_spawn_air("[GAS_CO2]=[amount*10];[TURF_TEMPERATURE(exposed_temperature)]")
	qdel(src)

/obj/item/stack/sheet/mineral/coal/five
	amount = 5

/obj/item/stack/sheet/mineral/coal/ten
	amount = 10

//Metal Hydrogen
GLOBAL_LIST_INIT(metalhydrogen_recipes, list(
	new /datum/stack_recipe("incomplete servant golem shell", /obj/item/golem_shell/servant, req_amount=20, res_amount=1, crafting_flags = NONE, category = CAT_ROBOT),
	new /datum/stack_recipe("ancient armor", /obj/item/clothing/suit/armor/elder_atmosian, req_amount = 5, res_amount = 1, crafting_flags = NONE, category = CAT_CLOTHING),
	new /datum/stack_recipe("ancient helmet", /obj/item/clothing/head/helmet/elder_atmosian, req_amount = 3, res_amount = 1, crafting_flags = NONE, category = CAT_CLOTHING),
	new /datum/stack_recipe("metallic hydrogen axe", /obj/item/fireaxe/metal_h2_axe, req_amount = 15, res_amount = 1, crafting_flags = NONE, category = CAT_WEAPON_MELEE),
	new /datum/stack_recipe("metallic hydrogen bolts", /obj/item/ammo_casing/rebar/hydrogen, req_amount = 1, res_amount = 1, crafting_flags = NONE, category = CAT_WEAPON_AMMO),
	))

/obj/item/stack/sheet/mineral/metal_hydrogen
	name = "metal hydrogen"
	icon_state = "sheet-metalhydrogen"
	inhand_icon_state = null
	singular_name = "metal hydrogen sheet"
	w_class = WEIGHT_CLASS_NORMAL
	resistance_flags = FIRE_PROOF | LAVA_PROOF | ACID_PROOF | INDESTRUCTIBLE
	gulag_valid = TRUE
	mats_per_unit = list(/datum/material/metalhydrogen = SHEET_MATERIAL_AMOUNT)
	material_type = /datum/material/metalhydrogen
	merge_type = /obj/item/stack/sheet/mineral/metal_hydrogen

/obj/item/stack/sheet/mineral/metal_hydrogen/get_main_recipes()
	. = ..()
	. += GLOB.metalhydrogen_recipes



GLOBAL_LIST_INIT(zaukerite_recipes, list(
	new /datum/stack_recipe("zaukerite shard", /obj/item/ammo_casing/rebar/zaukerite, req_amount=1, res_amount=1, category = CAT_WEAPON_AMMO),
	))

/obj/item/stack/sheet/mineral/zaukerite
	name = "zaukerite"
	icon_state = "zaukerite"
	inhand_icon_state = "sheet-zaukerite"
	singular_name = "zaukerite crystal"
	w_class = WEIGHT_CLASS_NORMAL
	gulag_valid = TRUE
	mats_per_unit = list(/datum/material/zaukerite = SHEET_MATERIAL_AMOUNT)
	merge_type = /obj/item/stack/sheet/mineral/zaukerite
	material_type = /datum/material/zaukerite

/obj/item/stack/sheet/mineral/zaukerite/get_main_recipes()
	. = ..()
	. += GLOB.zaukerite_recipes
