/datum/ai_planning_subtree/random_speech
	//The chance of an emote occurring each second
	var/speech_chance = 0
	///Hearable emotes
	var/list/emote_hear = list()
	///Unlike speak_emote, the list of things in this variable only show by themselves with no spoken text. IE: Ian barks, Ian yaps
	var/list/emote_see = list()
	///Possible lines of speech the AI can have
	var/list/speak = list()
	///The sound effects associated with this speech, if any
	var/list/sound = list()

/datum/ai_planning_subtree/random_speech/New()
	. = ..()
	if(speak)
		speak = string_list(speak)
	if(sound)
		sound = string_list(sound)
	if(emote_hear)
		emote_hear = string_list(emote_hear)
	if(emote_see)
		emote_see = string_list(emote_see)

/datum/ai_planning_subtree/random_speech/SelectBehaviors(datum/ai_controller/controller, seconds_per_tick)
	if(!SPT_PROB(speech_chance, seconds_per_tick))
		return
	speak(controller)

/// Actually perform an action
/datum/ai_planning_subtree/random_speech/proc/speak(datum/ai_controller/controller)
	var/audible_emotes_length = emote_hear?.len
	var/non_audible_emotes_length = emote_see?.len
	var/speak_lines_length = speak?.len

	var/total_choices_length = audible_emotes_length + non_audible_emotes_length + speak_lines_length

	if (total_choices_length == 0)
		return

	var/random_number_in_range = rand(1, total_choices_length)
	var/sound_to_play = length(sound) > 0 ? pick(sound) : null

	if(random_number_in_range <= audible_emotes_length)
		controller.queue_behavior(/datum/ai_behavior/perform_emote, pick(emote_hear), sound_to_play)
	else if(random_number_in_range <= (audible_emotes_length + non_audible_emotes_length))
		controller.queue_behavior(/datum/ai_behavior/perform_emote, pick(emote_see))
	else
		controller.queue_behavior(/datum/ai_behavior/perform_speech, pick(speak), sound_to_play)

/datum/ai_planning_subtree/random_speech/insect
	speech_chance = 5
	sound = list('sound/mobs/non-humanoids/insect/chitter.ogg')
	emote_hear = list("chitters.")

/datum/ai_planning_subtree/random_speech/mothroach
	speech_chance = 15
	emote_hear = list("flutters.")

/datum/ai_planning_subtree/random_speech/mouse
	speech_chance = 1
	speak = list("Squeak!", "SQUEAK!", "Squeak?")
	sound = list('sound/mobs/non-humanoids/mouse/mousesqueek.ogg')
	emote_hear = list("squeaks.")
	emote_see = list("runs in a circle.", "shakes.")

/datum/ai_planning_subtree/random_speech/frog
	speech_chance = 3
	emote_see = list("jumps in a circle.", "shakes.")

/datum/ai_planning_subtree/random_speech/lizard // all of these have to be three words long or i'm killing you. you're dead.
	speech_chance = 3
	emote_hear = list("stamps around some.", "hisses a bit.")
	emote_see = list("blehs the tongue.", "tilts the head.", "does a spin.")

/datum/ai_planning_subtree/random_speech/sheep
	speech_chance = 5
	speak = list("baaa","baaaAAAAAH!","baaah")
	sound = list('sound/mobs/non-humanoids/sheep/sheep1.ogg', 'sound/mobs/non-humanoids/sheep/sheep2.ogg', 'sound/mobs/non-humanoids/sheep/sheep3.ogg')
	emote_hear = list("bleats.")
	emote_see = list("shakes her head.", "stares into the distance.")

/datum/ai_planning_subtree/random_speech/rabbit
	speech_chance = 10
	speak = list("Mrrp.", "CHIRP!", "Mrrp?") // rabbits make some weird noises dude i don't know what to tell you
	emote_hear = list("hops.")
	emote_see = list("hops around.", "bounces up and down.")

/// For the easter subvariant of rabbits, these ones actually speak catchphrases.
/datum/ai_planning_subtree/random_speech/rabbit/easter
	speak = list(
		"Hop into Easter!",
		"Come get your eggs!",
		"Prizes for everyone!",
	)

/// These ones have a space mask on, so their catchphrases are muffled.
/datum/ai_planning_subtree/random_speech/rabbit/easter/space
	speak = list(
		"Hmph mmph mmmph!",
		"Mmphe mmphe mmphe!",
		"Hmm mmm mmm!",
	)

/datum/ai_planning_subtree/random_speech/chicken
	speech_chance = 15 // really talkative ladies
	speak = list("Cluck!", "BWAAAAARK BWAK BWAK BWAK!", "Bwaak bwak.")
	sound = list('sound/mobs/non-humanoids/chicken/clucks.ogg', 'sound/mobs/non-humanoids/chicken/bagawk.ogg')
	emote_hear = list("clucks.", "croons.")
	emote_see = list("pecks at the ground.","flaps her wings viciously.")

/datum/ai_planning_subtree/random_speech/chick
	speech_chance = 4
	speak = list("Cherp.", "Cherp?", "Chirrup.", "Cheep!")
	sound = list('sound/mobs/non-humanoids/chicken/chick_peep.ogg')
	emote_hear = list("cheeps.")
	emote_see = list("pecks at the ground.","flaps her tiny wings.")

/datum/ai_planning_subtree/random_speech/cow
	speech_chance = 1
	speak = list("moo?","moo","MOOOOOO")
	sound = list('sound/mobs/non-humanoids/cow/cow.ogg')
	emote_hear = list("brays.")
	emote_see = list("shakes her head.")

///unlike normal cows, wisdom cows speak of wisdom and won't shut the fuck up
/datum/ai_planning_subtree/random_speech/cow/wisdom
	speech_chance = 15

/datum/ai_planning_subtree/random_speech/cow/wisdom/New()
	. = ..()
	speak = GLOB.wisdoms //Done here so it's setup properly
	sound = list()

/datum/ai_planning_subtree/random_speech/deer
	speech_chance = 1
	speak = list("Weeeeeeee?", "Weeee", "WEOOOOOOOOOO")
	emote_hear = list("brays.")
	emote_see = list("shakes her head.")

/datum/ai_planning_subtree/random_speech/dog
	speech_chance = 1

/datum/ai_planning_subtree/random_speech/dog/SelectBehaviors(datum/ai_controller/controller, seconds_per_tick)
	if(!isdog(controller.pawn))
		return

	// Stay in sync with dog fashion.
	var/mob/living/basic/pet/dog/dog_pawn = controller.pawn
	dog_pawn.update_dog_speech(src)

	return ..()

/datum/ai_planning_subtree/random_speech/faithless
	speech_chance = 1
	emote_see = list("wails.")

/datum/ai_planning_subtree/random_speech/garden_gnome
	speech_chance = 5
	speak = list("Gnot a gnelf!", "Gnot a gnoblin!", "Howdy chum!")
	emote_hear = list("snores.", "burps.")
	emote_see = list("blinks.")

/datum/ai_planning_subtree/random_speech/tree
	speech_chance = 3
	emote_see = list("photosynthesizes angrily.")

/datum/ai_planning_subtree/random_speech/pig
	speech_chance = 3
	speak = list("oink?","oink","snurf")
	sound = list('sound/mobs/non-humanoids/pig/pig1.ogg', 'sound/mobs/non-humanoids/pig/pig2.ogg')
	emote_hear = list("snorts.")
	emote_see = list("sniffs around.")

/datum/ai_planning_subtree/random_speech/pony
	speech_chance = 3
	sound = list('sound/mobs/non-humanoids/pony/whinny01.ogg', 'sound/mobs/non-humanoids/pony/whinny02.ogg', 'sound/mobs/non-humanoids/pony/whinny03.ogg')
	emote_hear = list("whinnies!")
	emote_see = list("horses around.")

/datum/ai_planning_subtree/random_speech/pony/tamed
	speech_chance = 3
	sound = list('sound/mobs/non-humanoids/pony/snort.ogg')
	emote_hear = list("snorts.")
	emote_see = list("snorts.")

/datum/ai_planning_subtree/random_speech/killer_tomato
	speech_chance = 3
	emote_hear = list("gnashes.", "growls lowly.", "snarls.")
	emote_see = list("salivates.")

/datum/ai_planning_subtree/random_speech/ant
	speech_chance = 1
	speak = list("BZZZZT!", "CHTCHTCHT!", "Bzzz", "ChtChtCht")
	sound = list('sound/mobs/non-humanoids/insect/chitter.ogg')
	emote_hear = list("buzzes.", "clacks.")
	emote_see = list("shakes their head.", "twitches their antennae.")

/datum/ai_planning_subtree/random_speech/fox
	speech_chance = 1
	speak = list("Ack-Ack", "Ack-Ack-Ack-Ackawoooo", "Geckers", "Awoo", "Tchoff")
	emote_hear = list("howls.", "barks.", "screams.")
	emote_see = list("shakes their head.", "shivers.")

/datum/ai_planning_subtree/random_speech/crab
	speech_chance = 1
	sound = list('sound/mobs/non-humanoids/crab/claw_click.ogg')
	emote_hear = list("clicks.")
	emote_see = list("clacks.")

/datum/ai_planning_subtree/random_speech/penguin
	speech_chance = 5
	speak = list("Gah Gah!", "NOOT NOOT!", "NOOT!", "Noot", "noot", "Prah!", "Grah!")
	emote_hear = list("squawks", "gakkers")

/datum/ai_planning_subtree/random_speech/bear
	speech_chance = 5
	emote_hear = list("rawrs.","grumbles.","grawls.", "stomps!")
	emote_see = list("stares ferociously.")

/datum/ai_planning_subtree/random_speech/cats
	speech_chance = 10
	sound = list(SFX_CAT_MEOW)
	emote_hear = list("meows.")
	emote_see = list("meows.")

/datum/ai_planning_subtree/random_speech/blackboard //literal tower of babel, subtree form
	speech_chance = 1

/datum/ai_planning_subtree/random_speech/blackboard/SelectBehaviors(datum/ai_controller/controller, seconds_per_tick)
	var/list/speech_lines = controller.blackboard[BB_BASIC_MOB_SPEAK_LINES]
	if(isnull(speech_lines))
		return ..()

	// Note to future developers: this behaviour a singleton so this probably doesn't work as you would expect
	// The whole speech tree really needs to be refactored because this isn't how we use AI data these days
	speak = speech_lines[BB_EMOTE_SAY] || list()
	emote_see = speech_lines[BB_EMOTE_SEE] || list()
	emote_hear = speech_lines[BB_EMOTE_HEAR] || list()
	sound = speech_lines[BB_EMOTE_SOUND] || list()
	speech_chance = speech_lines[BB_SPEAK_CHANCE] ? speech_lines[BB_SPEAK_CHANCE] : initial(speech_chance)

	return ..()
