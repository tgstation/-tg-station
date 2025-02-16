///Representative icons for the contents of each crafting recipe
/datum/asset/spritesheet_batched/crafting
	name = "crafting"

/datum/asset/spritesheet_batched/crafting/create_spritesheets()
	var/id = 1
	for(var/atom in GLOB.crafting_recipes_atoms)
		add_atom_icon(atom, id++)
	add_tool_icons()

/datum/asset/spritesheet_batched/crafting/cooking
	name = "cooking"

/datum/asset/spritesheet_batched/crafting/cooking/create_spritesheets()
	var/id = 1
	for(var/atom in GLOB.cooking_recipes_atoms)
		add_atom_icon(atom, id++)

/**
 * Adds the ingredient icon to the spritesheet with given ID
 *
 * ingredient_typepath can be an obj typepath OR a reagent typepath
 *
 * If it a reagent, it will use the default container's icon state,
 * OR if it has a glass style associated, it will use that
 */
/datum/asset/spritesheet_batched/crafting/proc/add_atom_icon(ingredient_typepath, id)
	var/icon_file
	var/icon_state
	var/obj/preview_item = ingredient_typepath
	if(ispath(ingredient_typepath, /datum/reagent))
		var/datum/reagent/reagent = ingredient_typepath
		preview_item = initial(reagent.default_container)
		var/datum/glass_style/style = GLOB.glass_style_singletons[preview_item]?[reagent]
		if(istype(style))
			icon_file = style.icon
			icon_state = style.icon_state

	icon_file ||= initial(preview_item.icon_preview) || initial(preview_item.icon)
	icon_state ||= initial(preview_item.icon_state_preview) || initial(preview_item.icon_state)

	if(PERFORM_ALL_TESTS(focus_only/bad_cooking_crafting_icons))
		if(!icon_exists_or_scream(icon_file, icon_state))
			return

	insert_icon("a[id]", uni_icon(icon_file, icon_state, SOUTH))

///Adds tool icons to the spritesheet
/datum/asset/spritesheet_batched/crafting/proc/add_tool_icons()
	var/list/tool_icons = list(
		TOOL_CROWBAR = uni_icon('icons/obj/tools.dmi', "crowbar"),
		TOOL_MULTITOOL = uni_icon('icons/obj/devices/tool.dmi', "multitool"),
		TOOL_SCREWDRIVER = uni_icon('icons/obj/tools.dmi', "screwdriver_map"),
		TOOL_WIRECUTTER = uni_icon('icons/obj/tools.dmi', "cutters_map"),
		TOOL_WRENCH = uni_icon('icons/obj/tools.dmi', "wrench"),
		TOOL_WELDER = uni_icon('icons/obj/tools.dmi', "welder"),
		TOOL_ANALYZER = uni_icon('icons/obj/devices/scanner.dmi', "analyzer"),
		TOOL_MINING = uni_icon('icons/obj/mining.dmi', "minipick"),
		TOOL_SHOVEL = uni_icon('icons/obj/mining.dmi', "spade"),
		TOOL_RETRACTOR = uni_icon('icons/obj/medical/surgery_tools.dmi', "retractor"),
		TOOL_HEMOSTAT = uni_icon('icons/obj/medical/surgery_tools.dmi', "hemostat"),
		TOOL_CAUTERY = uni_icon('icons/obj/medical/surgery_tools.dmi', "cautery"),
		TOOL_DRILL = uni_icon('icons/obj/medical/surgery_tools.dmi', "drill"),
		TOOL_SCALPEL = uni_icon('icons/obj/medical/surgery_tools.dmi', "scalpel"),
		TOOL_SAW = uni_icon('icons/obj/medical/surgery_tools.dmi', "saw"),
		TOOL_BONESET = uni_icon('icons/obj/medical/surgery_tools.dmi', "bonesetter"),
		TOOL_KNIFE = uni_icon('icons/obj/service/kitchen.dmi', "knife"),
		TOOL_BLOODFILTER = uni_icon('icons/obj/medical/surgery_tools.dmi', "bloodfilter"),
		TOOL_ROLLINGPIN = uni_icon('icons/obj/service/kitchen.dmi', "rolling_pin"),
		TOOL_RUSTSCRAPER = uni_icon('icons/obj/tools.dmi', "wirebrush"),
	)

	for(var/tool in tool_icons)
		insert_icon(replacetext(tool, " ", ""), tool_icons[tool])
