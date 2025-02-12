/mob/living/basic/pet/cat/feral
	name = "feral cat"
	desc = "Kitty!! Wait, no no DON'T BITE-"
	health = 30
	maxHealth = 30
	melee_damage_lower = 7
	melee_damage_upper = 15
	ai_controller = /datum/ai_controller/basic_controller/simple/simple_hostile
	faction = list(FACTION_CAT, ROLE_SYNDICATE)
