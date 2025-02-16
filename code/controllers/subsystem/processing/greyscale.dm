PROCESSING_SUBSYSTEM_DEF(greyscale)
	name = "Greyscale"
	flags = SS_BACKGROUND
	init_order = INIT_ORDER_GREYSCALE
	wait = 3 SECONDS

	var/list/datum/greyscale_config/configurations = list()
	var/list/datum/greyscale_layer/layer_types = list()

/datum/controller/subsystem/processing/greyscale/Initialize()
	for(var/datum/greyscale_layer/fake_type as anything in subtypesof(/datum/greyscale_layer))
		layer_types[initial(fake_type.layer_type)] = fake_type

	for(var/greyscale_type in subtypesof(/datum/greyscale_config))
		var/datum/greyscale_config/config = new greyscale_type()
		configurations["[greyscale_type]"] = config

	// We do this after all the types have been loaded into the listing so reference layers don't care about init order
	for(var/greyscale_type in configurations)
		CHECK_TICK
		var/datum/greyscale_config/config = configurations[greyscale_type]
		config.Refresh()

	// This final verification step is for things that need other greyscale configurations to be finished loading
	for(var/greyscale_type as anything in configurations)
		CHECK_TICK
		var/datum/greyscale_config/config = configurations[greyscale_type]
		config.CrossVerify()

	return SS_INIT_SUCCESS

/datum/controller/subsystem/processing/greyscale/proc/RefreshConfigsFromFile()
	for(var/i in configurations)
		configurations[i].Refresh(TRUE)

/datum/controller/subsystem/processing/greyscale/proc/GetColoredIconByType(type, list/colors)
	if(!ispath(type, /datum/greyscale_config))
		CRASH("An invalid greyscale configuration was given to `GetColoredIconByType()`: [type]")
	type = "[type]"
	if(istype(colors)) // It's the color list format
		colors = colors.Join()
	else if(!istext(colors))
		CRASH("Invalid colors were given to `GetColoredIconByType()`: [colors]")
	return configurations[type].Generate(colors)

/datum/controller/subsystem/processing/greyscale/proc/GetColoredIconByType_universal_icon(type, list/colors, target_icon_state)
	if(!ispath(type, /datum/greyscale_config))
		CRASH("An invalid greyscale configuration was given to `GetColoredIconByType_universal_icon()`: [type]")
	type = "[type]"
	if(istype(colors)) // It's the color list format
		colors = colors.Join()
	else if(!istext(colors))
		CRASH("Invalid colors were given to `GetColoredIconByType_universal_icon()`: [colors]")
	return configurations[type].Generate_universal_icon(colors, target_icon_state)

/datum/controller/subsystem/processing/greyscale/proc/ParseColorString(color_string)
	. = list()
	var/list/split_colors = splittext(color_string, "#")
	for(var/color in 2 to length(split_colors))
		. += "#[split_colors[color]]"
