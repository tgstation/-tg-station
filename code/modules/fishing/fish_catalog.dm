///Book detailing where to get the fish and their properties.
/obj/item/book/manual/fish_catalog
	name = "Fish Encyclopedia"
	desc = "Indexes all fish known to mankind (and related species)."
	icon_state = "fishbook"
	custom_price = PAYCHECK_CREW * 2
	starting_content = "Lot of fish stuff" //book wrappers could use cleaning so this is not necessary

/obj/item/book/manual/fish_catalog/Initialize(mapload)
	. = ..()
	AddComponent(/datum/component/adjust_fishing_difficulty, -7, ITEM_SLOT_HANDS)

/obj/item/book/manual/fish_catalog/ui_interact(mob/user, datum/tgui/ui)
	ui = SStgui.try_update_ui(user, src, ui)
	if(!ui)
		ui = new(user, src, "FishCatalog", name)
		ui.open()

/obj/item/book/manual/fish_catalog/ui_static_data(mob/user)
	. = ..()
	var/static/fish_info
	if(!fish_info)
		fish_info = list()
		for(var/obj/item/fish/fish as anything in subtypesof(/obj/item/fish))
			if(!(initial(fish.fish_flags) & FISH_FLAG_SHOW_IN_CATALOG))
				continue
			var/list/fish_data = list()
			fish_data["name"] = initial(fish.name)
			fish_data["desc"] = initial(fish.desc)
			fish_data["fluid"] = initial(fish.required_fluid_type)
			fish_data["temp_min"] = initial(fish.required_temperature_min)
			fish_data["temp_max"] = initial(fish.required_temperature_max)
			fish_data["icon"] = sanitize_css_class_name("[initial(fish.icon)][initial(fish.icon_state)]")
			fish_data["color"] = initial(fish.color)
			fish_data["source"] = initial(fish.random_case_rarity) ? "[AQUARIUM_COMPANY] Fish Packs" : "Unknown"
			fish_data["size"] = initial(fish.average_size)
			fish_data["weight"] = initial(fish.average_weight)
			var/datum/reagent/food_type = initial(fish.food)
			if(food_type != /datum/reagent/consumable/nutriment)
				fish_data["feed"] = initial(food_type.name)
			else
				fish_data["feed"] = "[AQUARIUM_COMPANY] Fish Feed"
			fish_data["fishing_tips"] = build_fishing_tips(fish)
			fish_data["beauty"] = SSfishing.fish_properties[fish][FISH_PROPERTIES_BEAUTY_SCORE]

			fish_info += list(fish_data)

	.["fish_info"] = fish_info
	.["sponsored_by"] = AQUARIUM_COMPANY

/obj/item/book/manual/fish_catalog/proc/bait_description(bait)
	if(ispath(bait))
		var/obj/bait_item = bait
		return initial(bait_item.name)
	if(islist(bait))
		var/list/special_identifier = bait
		switch(special_identifier[FISH_BAIT_TYPE])
			if(FISH_BAIT_FOODTYPE)
				return jointext(bitfield_to_list(special_identifier[FISH_BAIT_VALUE], FOOD_FLAGS_IC),",")
			if(FISH_BAIT_REAGENT)
				var/datum/reagent/prototype = special_identifier[FISH_BAIT_VALUE]
				return "[initial(prototype.name)] (at least [special_identifier[FISH_BAIT_AMOUNT]]u)"
			else
				stack_trace("Unknown bait identifier in fish favourite/disliked list")
				return "SOMETHING VERY WEIRD"
	else
		//Here we handle descriptions of traits fish use as qualifiers
		return "something special"

/obj/item/book/manual/fish_catalog/proc/build_fishing_tips(fish_type)
	var/obj/item/fish/fishy = fish_type
	. = list()
	//// Where can it be found - iterate fish sources, how should this handle key
	var/list/spot_descriptions = list()
	for(var/datum/fish_source/source as anything in GLOB.preset_fish_sources)
		if(source.catalog_description && (fish_type in source.fish_table))
			spot_descriptions += source.catalog_description
	.["spots"] = english_list(spot_descriptions, nothing_text = "Unknown")
	var/list/fish_list_properties = SSfishing.fish_properties
	var/list/fav_bait = fish_list_properties[fishy][FISH_PROPERTIES_FAV_BAIT]
	var/list/disliked_bait = fish_list_properties[fishy][FISH_PROPERTIES_BAD_BAIT]
	var/list/bait_list = list()
	// Favourite/Disliked bait
	for(var/bait_type_or_trait in fav_bait)
		bait_list += bait_description(bait_type_or_trait)
	.["favorite_bait"] = english_list(bait_list, nothing_text = "None")
	bait_list.Cut()
	for(var/bait_type_or_trait in disliked_bait)
		bait_list += bait_description(bait_type_or_trait)
	.["disliked_bait"] = english_list(bait_list, nothing_text = "None")
	// Fish traits description
	var/list/trait_descriptions = list()
	var/list/fish_traits = fish_list_properties[fishy][FISH_PROPERTIES_TRAITS]
	var/fish_difficulty = initial(fishy.fishing_difficulty_modifier)
	for(var/fish_trait in fish_traits)
		var/datum/fish_trait/trait = GLOB.fish_traits[fish_trait]
		trait_descriptions += trait.catalog_description
		fish_difficulty += trait.added_difficulty
	if(!length(trait_descriptions))
		trait_descriptions += "This fish exhibits no special behavior."
	.["traits"] = trait_descriptions
	///Difficulty descriptor
	switch(fish_difficulty)
		if(-INFINITY to 9)
			.["difficulty"] = "Easy"
		if(10 to 19)
			.["difficulty"] = "Medium"
		else
			.["difficulty"] = "Hard"
	return .

/obj/item/book/manual/fish_catalog/ui_assets(mob/user)
	return list(
		get_asset_datum(/datum/asset/spritesheet_batched/fish)
	)
