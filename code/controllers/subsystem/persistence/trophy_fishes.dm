#define PERSISTENCE_FISH_ID "fish_id"
#define PERSISTENCE_FISH_NAME "fish_name"
#define PERSISTENCE_FISH_SIZE "fish_size"
#define PERSISTENCE_FISH_WEIGHT "fish_weight"
#define PERSISTENCE_FISH_MATERIAL "fish_material"
#define PERSISTENCE_FISH_CATCHER "fish_catcher"
#define PERSISTENCE_FISH_CATCH_DATE "fish_catch_date"
#define PERSISTENCE_FISH_TRAITS "fish_traits"

///Instantiate a fish, then set its size, weight, eventually materials and finally add it to the mount.
/datum/controller/subsystem/persistence/proc/load_trophy_fish(obj/structure/fish_mount/mount)
	if(!mount.persistence_id)
		return
	if(isnull(trophy_fishes_database))
		trophy_fishes_database = new("data/trophy_fishes.json")

	var/list/data = trophy_fishes_database.get_key(mount.persistence_id)
	if(!length(data))
		return
	var/fish_id = data[PERSISTENCE_FISH_ID]
	if(!fish_id) //For a reason or another, the id isn't there
		return
	var/fish_path = SSfishing.catchable_fish[fish_id]
	if(!fish_path) //the fish was removed, uh uh.
		return
	var/obj/item/fish/fish = new fish_path(mount, /* apply_qualities = */ FALSE)
	var/list/traits_text = data[PERSISTENCE_FISH_TRAITS]
	if(!isnull(traits_text))
		var/list/traits = list()
		for(var/text_path in traits_text)
			var/path = text2path(text_path)
			if(path)
				traits |= path
		fish.fish_traits = traits
	fish.apply_traits()
	fish.update_size_and_weight(data[PERSISTENCE_FISH_SIZE], data[PERSISTENCE_FISH_WEIGHT])
	var/material_path = text2path(data[PERSISTENCE_FISH_MATERIAL])
	if(material_path)
		//setting the list inside the proccall doesn't seem to work
		var/list/mat_list = list(material_path = fish.weight)
		fish.set_custom_materials(mat_list)
	fish.persistence_load(data)
	fish.name = data[PERSISTENCE_FISH_NAME]
	fish.set_status(FISH_DEAD, silent = TRUE)
	fish.catch_date = data[PERSISTENCE_FISH_CATCH_DATE]
	mount.add_fish(fish, from_persistence = TRUE, catcher = data[PERSISTENCE_FISH_CATCHER])

/datum/controller/subsystem/persistence/proc/save_trophy_fish(obj/structure/fish_mount/mount)
	var/obj/item/fish/fish = mount.mounted_fish
	if(!fish || !mount.persistence_id)
		return
	if(isnull(trophy_fishes_database))
		trophy_fishes_database = new("data/trophy_fishes.json")

	var/list/data = list()
	var/fish_id = fish.fish_id
	if(fish.fish_id_redirect_path)
		var/obj/item/fish/other_path = fish.fish_id_redirect_path
		fish_id = initial(other_path.fish_id)

	data[PERSISTENCE_FISH_ID] = fish_id
	data[PERSISTENCE_FISH_NAME] = fish.name
	data[PERSISTENCE_FISH_SIZE] = fish.size
	data[PERSISTENCE_FISH_WEIGHT] = fish.weight / fish.material_weight_mult
	var/datum/material/material = fish.get_master_material()
	data[PERSISTENCE_FISH_MATERIAL] = "[material?.type]"
	data[PERSISTENCE_FISH_CATCHER] = fish.catcher_name
	data[PERSISTENCE_FISH_CATCH_DATE] = fish.catch_date
	var/list/traits = list()
	for(var/trait_path in fish.fish_traits)
		traits += "[trait_path]"
	data[PERSISTENCE_FISH_TRAITS] = traits

	fish.persistence_save(data)
	trophy_fishes_database.set_key(mount.persistence_id, data)

#undef PERSISTENCE_FISH_ID
#undef PERSISTENCE_FISH_NAME
#undef PERSISTENCE_FISH_SIZE
#undef PERSISTENCE_FISH_WEIGHT
#undef PERSISTENCE_FISH_MATERIAL
#undef PERSISTENCE_FISH_CATCHER
#undef PERSISTENCE_FISH_CATCH_DATE
#undef PERSISTENCE_FISH_TRAITS
