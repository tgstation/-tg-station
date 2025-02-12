// Some flavor additions for wolf-related pet commands
/datum/pet_command/good_boy/wolf
	speech_commands = list("good wolf")

/datum/pet_command/follow/wolf
	// Nordic-themed for a bit of extra flavor
	speech_commands = list("heel", "follow", "fylgja", "fyl")

// Contains pixel offset data for sprites riding wolves
/datum/component/riding/creature/wolf

/datum/component/riding/creature/wolf/get_rider_offsets_and_layers(pass_index, mob/offsetter)
	return list(
		TEXT_NORTH = list(1, 9, OBJ_LAYER),
		TEXT_SOUTH = list(1, 9, ABOVE_MOB_LAYER),
		TEXT_EAST =  list(0, 9, OBJ_LAYER),
		TEXT_WEST =  list(2, 9, OBJ_LAYER),
	)
