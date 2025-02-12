// float bobbing
#define WAIT_PHASE 1
// Click now to start tgui part
#define BITING_PHASE 2
// UI minigame phase
#define MINIGAME_PHASE 3

// Acceleration mod when bait is over fish
#define FISH_ON_BAIT_ACCELERATION_MULT 0.6
/// The minimum velocity required for the bait to bounce
#define BAIT_MIN_VELOCITY_BOUNCE 150

/// Reduce initial completion rate depending on difficulty
#define MAX_FISH_COMPLETION_MALUS 15
/// The window of time between biting phase and back to baiting phase
#define BITING_TIME_WINDOW 4 SECONDS

/// The multiplier of how much the difficulty negatively impacts the bait height
#define BAIT_HEIGHT_DIFFICULTY_MALUS 1.3

/// Defines to know how the bait is moving on the minigame slider.
#define REELING_STATE_IDLE 0
#define REELING_STATE_UP 1
#define REELING_STATE_DOWN 2

/// The pixel height of the minigame bar
#define MINIGAME_SLIDER_HEIGHT 76
/// The standard pixel height of the bait
#define MINIGAME_BAIT_HEIGHT 27
/// How many pixels bottom and top parts of the bait take up
#define MINIGAME_BAIT_TOP_AND_BOTTOM_HEIGHT 6
/// The standard pixel height of the fish (minus a pixel on each direction for the sake of a better looking sprite)
#define MINIGAME_FISH_HEIGHT 4
/// Pixel height of the completion bar
#define MINIGAME_COMPLETION_BAR_HEIGHT 80

GLOBAL_LIST_EMPTY(fishing_challenges_by_user)

/datum/fishing_challenge
	/// When the ui minigame phase started
	var/start_time
	/// Is it finished (either by win/lose or window closing)
	var/completed = FALSE
	/// Rule modifiers (eg weighted bait)
	var/special_effects = NONE
	/// A list of possible active minigame effects. If not empty, one will be picked from time to time.
	var/list/active_effects
	/// The cooldown between switching active effects
	COOLDOWN_DECLARE(active_effect_cd)
	/// The current active effect
	var/current_active_effect
	/// Result path
	var/reward_path = FISHING_DUD
	/// Minigame difficulty
	var/difficulty = FISHING_DEFAULT_DIFFICULTY
	/// Current phase
	var/phase = WAIT_PHASE
	/// Timer for the next phase
	var/next_phase_timer
	/// The lower and upper bounds of the waiting phase timer
	var/list/wait_time_range = list(3 SECONDS, 25 SECONDS)
	/// The last time we clicked during the baiting phase
	var/last_baiting_click
	/// Fishing mob
	var/mob/user
	/// Rod that is used for the challenge
	var/obj/item/fishing_rod/used_rod
	/// float visual
	var/obj/effect/fishing_float/float
	///The physical fishing spot our float is hovering
	var/atom/location
	/// Background icon state from fishing_hud.dmi
	var/background = "background_default"
	/// Fish icon state from fishing_hud.dmi
	var/fish_icon = FISH_ICON_DEF

	/// Fishing line visual
	var/datum/beam/fishing_line

	var/experience_multiplier = 1

	/// How much space the fish takes on the minigame slider
	var/fish_height = 50
	/// How much space the bait takes on the minigame slider
	var/bait_height = 360
	/// The height in pixels of the bait bar
	var/bait_pixel_height = MINIGAME_BAIT_HEIGHT
	/// The height in pixels of the fish
	var/fish_pixel_height = MINIGAME_FISH_HEIGHT
	/// The position of the fish on the minigame slider
	var/fish_position = 0
	/// The position of the bait on the minigame slider
	var/bait_position = 0
	/// The current speed the bait is moving at
	var/bait_velocity = 0

	/// The completion score. If it reaches 100, it's a win. If it reaches 0, it's a loss.
	var/completion = 30
	/// How much completion is lost per second when the bait area is not intersecting with the fish's
	var/completion_loss = 6
	/// How much completion is gained per second when the bait area is intersecting with the fish's
	var/completion_gain = 5

	var/datum/fish_movement/mover

	/// Whether the bait is idle or reeling up or down (left and right click)
	var/reeling_state = REELING_STATE_IDLE
	/// The acceleration of the bait while not reeling
	var/gravity_velocity = -800
	/// The acceleration of the bait while reeling
	var/reeling_velocity = 1200
	/// By how much the bait recoils back when hitting the bounds of the slider while idle
	var/bait_bounce_mult = 0.6
	/// The multiplier of deceleration of velocity that happens when the bait switches direction
	var/deceleration_mult = 1.8

	///The background as shown in the minigame, and the holder of the other visual overlays
	var/atom/movable/screen/fishing_hud/fishing_hud

	///Keep track of the fish source from which we're pulling the reward
	var/datum/fish_source/fish_source

/datum/fishing_challenge/New(datum/component/fishing_spot/comp, obj/item/fishing_rod/rod, mob/user)
	src.user = user
	used_rod = rod
	location = comp.parent
	float = new(get_turf(location), location)
	float.spin_frequency = rod.spin_frequency
	RegisterSignal(location, COMSIG_QDELETING, PROC_REF(on_spot_gone))
	RegisterSignal(comp, COMSIG_QDELETING, PROC_REF(on_spot_gone))
	register_reward_signals(comp.fish_source)
	RegisterSignal(fish_source, COMSIG_FISHING_SOURCE_INTERRUPT_CHALLENGE, PROC_REF(interrupt_challenge))
	background = comp.fish_source.background
	if(comp.fish_source.wait_time_range)
		wait_time_range = comp.fish_source.wait_time_range
	if(float.spin_frequency) //Using a fishing lure narrows the range a bit, for better or worse.
		wait_time_range = list(wait_time_range[1] + 8 SECONDS, wait_time_range[2] - 8 SECONDS)
	SEND_SIGNAL(user, COMSIG_MOB_BEGIN_FISHING, src)
	SEND_SIGNAL(rod, COMSIG_ROD_BEGIN_FISHING, src)
	GLOB.fishing_challenges_by_user[user] = src

	/// Enable special parameters
	if(rod.line)
		completion_gain += 1 // Any fishing line will provide a small boost by default
		if(rod.line.fishing_line_traits & FISHING_LINE_BOUNCY)
			completion_loss -= 2
		if(rod.line.fishing_line_traits & FISHING_LINE_STIFF)
			completion_loss += 1
			completion_gain -= 1
		if(rod.line.fishing_line_traits & FISHING_LINE_AUTOREEL)
			special_effects |= FISHING_MINIGAME_AUTOREEL
	if(rod.hook)
		if(rod.hook.fishing_hook_traits & FISHING_HOOK_WEIGHTED)
			bait_bounce_mult = 0.1
		if(rod.hook.fishing_hook_traits & FISHING_HOOK_BIDIRECTIONAL)
			special_effects |= FISHING_MINIGAME_RULE_BIDIRECTIONAL
		if(rod.hook.fishing_hook_traits & FISHING_HOOK_NO_ESCAPE)
			special_effects |= FISHING_MINIGAME_RULE_NO_ESCAPE
		if(rod.hook.fishing_hook_traits & FISHING_HOOK_ENSNARE)
			completion_loss -= 2
		if(rod.hook.fishing_hook_traits & FISHING_HOOK_KILL)
			special_effects |= FISHING_MINIGAME_RULE_KILL

	//Finish the minigame faster at higher skill. The value modifiers for fishing are negative values btw.
	completion_loss += user.mind?.get_skill_modifier(/datum/skill/fishing, SKILL_VALUE_MODIFIER)/5
	completion_gain -= user.mind?.get_skill_modifier(/datum/skill/fishing, SKILL_VALUE_MODIFIER)/7.5

	reeling_velocity *= rod.bait_speed_mult
	completion_gain *= rod.completion_speed_mult
	bait_bounce_mult *= rod.bounciness_mult
	deceleration_mult *= rod.deceleration_mult
	gravity_velocity *= rod.gravity_mult

/datum/fishing_challenge/Destroy(force)
	GLOB.fishing_challenges_by_user -= user
	if(!completed)
		complete(win = FALSE)
	if(fishing_line)
		//Stops the line snapped message from appearing everytime the minigame is over.
		UnregisterSignal(fishing_line, COMSIG_QDELETING)
		QDEL_NULL(fishing_line)
	QDEL_NULL(float)
	SStgui.close_uis(src)
	user = null
	used_rod = null
	location = null
	QDEL_NULL(mover)
	return ..()

/**
 * Proc responsible for registering the signals for difficulty, possible reward, and challenge completion.
 * Call this if you want to override the fish source from which we roll rewards (preferably before the minigame phase).
 */
/datum/fishing_challenge/proc/register_reward_signals(datum/fish_source/new_fish_source)
	if(fish_source)
		fish_source.UnregisterSignal(src, list(
			COMSIG_FISHING_CHALLENGE_ROLL_REWARD,
			COMSIG_FISHING_CHALLENGE_GET_DIFFICULTY,
		))
		fish_source.UnregisterSignal(user, COMSIG_MOB_COMPLETE_FISHING)
	fish_source = new_fish_source
	fish_source.RegisterSignal(src, COMSIG_FISHING_CHALLENGE_ROLL_REWARD, TYPE_PROC_REF(/datum/fish_source, roll_reward_minigame))
	fish_source.RegisterSignal(src, COMSIG_FISHING_CHALLENGE_GET_DIFFICULTY, TYPE_PROC_REF(/datum/fish_source, calculate_difficulty_minigame))
	fish_source.RegisterSignal(user, COMSIG_MOB_COMPLETE_FISHING, TYPE_PROC_REF(/datum/fish_source, on_challenge_completed))

/datum/fishing_challenge/proc/send_alert(message)
	location?.balloon_alert(user, message)

/datum/fishing_challenge/proc/on_spot_gone(datum/source)
	SIGNAL_HANDLER
	send_alert("fishing spot gone!")
	interrupt()

/datum/fishing_challenge/proc/interrupt_challenge(datum/source, reason)
	SIGNAL_HANDLER
	if(reason)
		send_alert(reason)
	interrupt()

/datum/fishing_challenge/proc/start(mob/living/user)
	/// Create fishing line visuals
	if(!used_rod.internal)
		fishing_line = used_rod.create_fishing_line(float, user, target_py = float.pixel_y + 4)
		if(isnull(fishing_line)) //couldn't create a fishing line, probably because we don't have a good line of sight.
			qdel(src)
			return
		RegisterSignal(fishing_line, COMSIG_QDELETING, PROC_REF(on_line_deleted))
	else //if the rod doesnt have a fishing line, then it ends when they move away
		RegisterSignal(user, COMSIG_MOVABLE_MOVED, PROC_REF(on_float_or_user_move))
		RegisterSignal(float, COMSIG_MOVABLE_MOVED, PROC_REF(on_float_or_user_move))
		RegisterSignal(user, SIGNAL_ADDTRAIT(TRAIT_HANDS_BLOCKED), PROC_REF(on_hands_blocked))
	RegisterSignal(user, SIGNAL_REMOVETRAIT(TRAIT_PROFOUND_FISHER), PROC_REF(no_longer_fishing))
	active_effects = bitfield_to_list(special_effects & FISHING_MINIGAME_ACTIVE_EFFECTS)
	// If fishing line breaks los / rod gets dropped / deleted
	RegisterSignal(used_rod, COMSIG_ITEM_ATTACK_SELF, PROC_REF(on_attack_self))
	user.add_mood_event("fishing", /datum/mood_event/fishing)
	RegisterSignal(user, COMSIG_MOB_CLICKON, PROC_REF(handle_click))
	start_baiting_phase()
	to_chat(user, span_notice("You start fishing..."))
	playsound(location, 'sound/effects/splash.ogg', 100)

///Set the timers for lure that need to be spun at intervals.
/datum/fishing_challenge/proc/set_lure_timers()
	float.spin_ready = FALSE
	addtimer(CALLBACK(src, PROC_REF(set_lure_ready)), float.spin_frequency[1], TIMER_UNIQUE|TIMER_OVERRIDE|TIMER_DELETE_ME)
	addtimer(CALLBACK(src, PROC_REF(missed_lure)), float.spin_frequency[2], TIMER_UNIQUE|TIMER_OVERRIDE|TIMER_DELETE_ME)
	float.update_appearance(UPDATE_OVERLAYS)

/datum/fishing_challenge/proc/set_lure_ready()
	if(phase != WAIT_PHASE)
		return
	float.spin_ready = TRUE
	float.update_appearance(UPDATE_OVERLAYS)
	if(special_effects & FISHING_MINIGAME_AUTOREEL)
		addtimer(CALLBACK(src, PROC_REF(auto_spin)), 0.2 SECONDS)
	playsound(float, 'sound/machines/ping.ogg', 10, TRUE, SHORT_RANGE_SOUND_EXTRARANGE)

/datum/fishing_challenge/proc/auto_spin()
	if(phase != WAIT_PHASE || !float.spin_ready)
		return
	float.spin_ready = FALSE
	float.update_appearance(UPDATE_OVERLAYS)
	set_lure_timers()
	send_alert("spun")

/datum/fishing_challenge/proc/missed_lure()
	if(phase != WAIT_PHASE)
		return
	send_alert("miss!")
	start_baiting_phase(TRUE) //Add in another 3 to 5 seconds for not spinning the lure.

/datum/fishing_challenge/proc/on_line_deleted(datum/source)
	SIGNAL_HANDLER
	fishing_line = null
	///The float may be out of sight if the user has moed around a corner, so the message should be displayed over him instead.
	user.balloon_alert(user, user.is_holding(used_rod) ? "line snapped" : "rod dropped")
	interrupt()

/datum/fishing_challenge/proc/on_float_or_user_move(datum/source)
	SIGNAL_HANDLER

	if(!user.CanReach(location))
		user.balloon_alert(user, "too far!")
		interrupt()

/datum/fishing_challenge/proc/on_hands_blocked(datum/source)
	SIGNAL_HANDLER
	if(completed) //the rod was dropped and therefore challenge already completed.
		return
	user.balloon_alert(user, "hands blocked!")
	interrupt()

/datum/fishing_challenge/proc/no_longer_fishing(datum/source)
	SIGNAL_HANDLER
	if(completed) //we already won/lost
		return
	user.balloon_alert(user, "interrupted!")
	interrupt()

/datum/fishing_challenge/proc/handle_click(mob/source, atom/target, modifiers)
	SIGNAL_HANDLER
	if(HAS_TRAIT(source, TRAIT_HANDS_BLOCKED)) //blocked, can't do stuff
		return
	//Doing other stuff
	if(LAZYACCESS(modifiers, SHIFT_CLICK) || LAZYACCESS(modifiers, CTRL_CLICK) || LAZYACCESS(modifiers, ALT_CLICK))
		return
	//You need to be actively holding on the fishing rod to use it, unless you've the profound_fisher trait.
	if(!HAS_TRAIT(source, TRAIT_PROFOUND_FISHER) && source.get_active_held_item() != used_rod)
		return
	if(phase == WAIT_PHASE)
		if(world.time < last_baiting_click + 0.25 SECONDS)
			return COMSIG_MOB_CANCEL_CLICKON //Don't punish players if they accidentally double clicked.
		if(float.spin_frequency)
			if(!float.spin_ready)
				send_alert("too early!")
				start_baiting_phase(TRUE) //Add in another 3 to 5 seconds for that blunder.
			else
				send_alert("spun")
				last_baiting_click = world.time
			float.spin_ready = FALSE
			set_lure_timers()
		else
			send_alert("miss!")
			start_baiting_phase(TRUE) //Add in another 3 to 5 seconds for that blunder.
	else if(phase == BITING_PHASE)
		start_minigame_phase()
	return COMSIG_MOB_CANCEL_CLICKON

/// Challenge interrupted by something external
/datum/fishing_challenge/proc/interrupt()
	if(!completed)
		experience_multiplier *= 0.5
		complete(FALSE)

/datum/fishing_challenge/proc/on_attack_self(obj/item/source, mob/user)
	SIGNAL_HANDLER
	INVOKE_ASYNC(src, PROC_REF(stop_fishing), source, user)

/datum/fishing_challenge/proc/stop_fishing(obj/item/rod, mob/user)
	if((phase != MINIGAME_PHASE || do_after(user, 3 SECONDS, rod)) && !QDELETED(src) && !completed)
		experience_multiplier *= 0.5
		send_alert("stopped fishing")
		complete(FALSE)

///The multiplier of the fishing experience malus if the user's level is substantially above the difficulty.
#define EXPERIENCE_MALUS_MULT 0.08

/datum/fishing_challenge/proc/complete(win = FALSE)
	if(completed)
		return
	deltimer(next_phase_timer)
	completed = TRUE
	if(phase == MINIGAME_PHASE)
		remove_minigame_hud()

	if(!QDELETED(user) && user.mind && start_time && !(special_effects & FISHING_MINIGAME_RULE_NO_EXP))
		var/seconds_spent = (world.time - start_time) * 0.1
		var/extra_exp_malus = user.mind.get_skill_level(/datum/skill/fishing) - difficulty * 0.1
		if(extra_exp_malus > 0)
			experience_multiplier /= (1 + extra_exp_malus * EXPERIENCE_MALUS_MULT)
		experience_multiplier *= used_rod.experience_multiplier
		user.mind.adjust_experience(/datum/skill/fishing, round(seconds_spent * FISHING_SKILL_EXP_PER_SECOND * experience_multiplier))
		if(user.mind.get_skill_level(/datum/skill/fishing) >= SKILL_LEVEL_LEGENDARY)
			user.client?.give_award(/datum/award/achievement/skill/legendary_fisher, user)

	if(!win)
		SEND_SIGNAL(user, COMSIG_MOB_COMPLETE_FISHING, src, FALSE)
		if(!QDELETED(src))
			qdel(src)
		return

	if(reward_path != FISHING_DUD)
		playsound(location, 'sound/effects/bigsplash.ogg', 100)

	var/valid_achievement_catch = FALSE
	if (ispath(reward_path, /obj/item/fish))
		valid_achievement_catch = TRUE
	else if (isfish(reward_path))
		var/obj/item/fish/fishy_individual = reward_path
		if (!HAS_TRAIT(fishy_individual, TRAIT_NO_FISHING_ACHIEVEMENT) && fishy_individual.status == FISH_ALIVE)
			valid_achievement_catch = TRUE

	if(valid_achievement_catch)
		var/obj/item/fish/fish_reward = reward_path
		var/obj/item/fish/redirect_path = initial(fish_reward.fish_id_redirect_path)
		var/fish_id = ispath(redirect_path, /obj/item/fish) ? initial(redirect_path.fish_id) : initial(fish_reward.fish_id)
		if(fish_id)
			user.client?.give_award(/datum/award/score/progress/fish, user, fish_id)

	SEND_SIGNAL(user, COMSIG_MOB_COMPLETE_FISHING, src, TRUE)
	if(!QDELETED(src))
		qdel(src)

#undef EXPERIENCE_MALUS_MULT

/datum/fishing_challenge/proc/start_baiting_phase(penalty = FALSE)
	reward_path = null //In case we missed the biting phase, set the path back to null
	var/wait_time
	last_baiting_click = world.time
	if(penalty)
		wait_time = min(timeleft(next_phase_timer) + rand(3 SECONDS, 5 SECONDS), 30 SECONDS)
	else
		wait_time = rand(wait_time_range[1], wait_time_range[2])
		if(special_effects & FISHING_MINIGAME_AUTOREEL && wait_time >= 15 SECONDS)
			wait_time = max(wait_time - 7.5 SECONDS, 15 SECONDS)
	deltimer(next_phase_timer)
	phase = WAIT_PHASE
	//Bobbing animation
	animate(float, pixel_y = 1, time = 1 SECONDS, loop = -1, flags = ANIMATION_RELATIVE)
	animate(pixel_y = -1, time = 1 SECONDS, flags = ANIMATION_RELATIVE)
	next_phase_timer = addtimer(CALLBACK(src, PROC_REF(start_biting_phase)), wait_time, TIMER_STOPPABLE|TIMER_DELETE_ME)
	if(float.spin_frequency)
		set_lure_timers()

/datum/fishing_challenge/proc/start_biting_phase()
	phase = BITING_PHASE

	var/list/rewards = list()
	SEND_SIGNAL(src, COMSIG_FISHING_CHALLENGE_ROLL_REWARD, used_rod, user, location, rewards)
	if(length(rewards))
		reward_path = pick(rewards)
	playsound(location, 'sound/effects/fish_splash.ogg', 100)

	if(HAS_MIND_TRAIT(user, TRAIT_REVEAL_FISH))
		var/possible_icon
		if(isdatum(reward_path))
			var/datum/reward = reward_path
			possible_icon = GLOB.specific_fish_icons[reward.type]
		else
			possible_icon = GLOB.specific_fish_icons[reward_path]
		fish_icon = possible_icon || FISH_ICON_DEF
		switch(fish_icon)
			if(FISH_ICON_DEF)
				send_alert("fish!!!")
			if(FISH_ICON_HOSTILE)
				send_alert("hostile!!!")
			if(FISH_ICON_STAR)
				send_alert("starfish!!!")
			if(FISH_ICON_CHUNKY)
				send_alert("round fish!!!")
			if(FISH_ICON_JELLYFISH)
				send_alert("jellyfish!!!")
			if(FISH_ICON_SLIME)
				send_alert("slime!!!")
			if(FISH_ICON_COIN)
				send_alert("valuable!!!")
			if(FISH_ICON_GEM)
				send_alert("ore!!!")
			if(FISH_ICON_CRAB)
				send_alert("crustacean!!!")
			if(FISH_ICON_BONE)
				send_alert("bones!!!")
			if(FISH_ICON_ELECTRIC)
				send_alert("zappy!!!")
			if(FISH_ICON_WEAPON)
				send_alert("weapon!!!")
			if(FISH_ICON_CRITTER)
				send_alert("critter!!!")
			if(FISH_ICON_SEED)
				send_alert("seed!!!")
			if(FISH_ICON_BOTTLE)
				send_alert("bottle!!!")
			if(FISH_ICON_ORGAN)
				send_alert("organ!!!")
	else
		send_alert("!!!")
	animate(float, pixel_y = 3, time = 5, loop = -1, flags = ANIMATION_RELATIVE)
	animate(pixel_y = -3, time = 5, flags = ANIMATION_RELATIVE)
	if(special_effects & FISHING_MINIGAME_AUTOREEL)
		addtimer(CALLBACK(src, PROC_REF(automatically_start_minigame)), 0.2 SECONDS)
	// Setup next phase
	next_phase_timer = addtimer(CALLBACK(src, PROC_REF(start_baiting_phase)), BITING_TIME_WINDOW, TIMER_STOPPABLE|TIMER_DELETE_ME)
	///If we're using a lure, we want the float to show a little green light during the minigame phase and not a red one.
	float.spin_ready = TRUE
	float.update_appearance(UPDATE_OVERLAYS)

/datum/fishing_challenge/proc/automatically_start_minigame()
	if(phase == BITING_PHASE)
		start_minigame_phase(auto_reel = TRUE)

///The damage dealt per second to the fish when FISHING_MINIGAME_RULE_KILL is active.
#define FISH_DAMAGE_PER_SECOND 2

///The player is no longer around to play the minigame, so we interrupt it.
/datum/fishing_challenge/proc/on_user_logout(datum/source)
	SIGNAL_HANDLER
	interrupt()

/datum/fishing_challenge/proc/on_reward_removed(datum/source)
	SIGNAL_HANDLER
	send_alert("reward gone!")
	interrupt()

/datum/fishing_challenge/proc/on_fish_death(obj/item/fish/source)
	SIGNAL_HANDLER
	if(source.status == FISH_DEAD)
		win_anyway()

/datum/fishing_challenge/proc/win_anyway()
	if(completed)
		return
	//winning by timeout / fish death shouldn't give as much experience.
	experience_multiplier *= 0.5
	complete(TRUE)

/datum/fishing_challenge/proc/hurt_fish(datum/source, obj/item/fish/reward)
	SIGNAL_HANDLER
	if(istype(reward))
		var/damage = CEILING((world.time - start_time)/10 * FISH_DAMAGE_PER_SECOND, 1)
		reward.adjust_health(reward.health - damage)

/datum/fishing_challenge/proc/get_difficulty()
	var/list/difficulty_holder = list(0)
	SEND_SIGNAL(src, COMSIG_FISHING_CHALLENGE_GET_DIFFICULTY, reward_path, used_rod, user, difficulty_holder)
	difficulty = difficulty_holder[1]
	//If you manage to be so well-equipped and skilled to completely crush the difficulty, just skip to the reward.
	if(difficulty <= 0)
		complete(TRUE)
		return FALSE
	difficulty = clamp(round(difficulty), FISHING_MINIMUM_DIFFICULTY, 100)
	return TRUE

/datum/fishing_challenge/proc/update_difficulty()
	if(phase != MINIGAME_PHASE)
		return
	var/old_difficulty = difficulty
	//early return if the difficulty is the same or we crush the minigame all the way to 0 difficulty
	if(!get_difficulty() || difficulty == old_difficulty)
		return
	bait_height = initial(bait_height) * used_rod.bait_height_mult
	experience_multiplier -= difficulty * FISHING_SKILL_DIFFIULTY_EXP_MULT
	mover.reset_difficulty_values()
	adjust_to_difficulty()

/datum/fishing_challenge/proc/adjust_to_difficulty()
	mover.adjust_to_difficulty()
	bait_height -= round(difficulty * BAIT_HEIGHT_DIFFICULTY_MALUS)
	bait_pixel_height = round(MINIGAME_BAIT_HEIGHT * (bait_height/initial(bait_height)), 1)
	experience_multiplier += difficulty * FISHING_SKILL_DIFFIULTY_EXP_MULT
	fishing_hud.hud_bait.adjust_to_difficulty(src)

///Get the difficulty and other variables, than start the minigame
/datum/fishing_challenge/proc/start_minigame_phase(auto_reel = FALSE)
	SEND_SIGNAL(user, COMSIG_MOB_BEGIN_FISHING_MINIGAME, src)
	if(!get_difficulty()) //we totalized 0 or less difficulty, instant win.
		return

	if(difficulty > FISHING_DEFAULT_DIFFICULTY)
		completion -= MAX_FISH_COMPLETION_MALUS * (difficulty * 0.01)

	var/is_fish_instance = isfish(reward_path)

	/// Fish minigame properties
	if(ispath(reward_path,/obj/item/fish) || is_fish_instance)
		var/obj/item/fish/fish = reward_path
		var/movement_path = initial(fish.fish_movement_type)
		mover = new movement_path(src)
		// Apply fish trait modifiers
		var/list/fish_traits = is_fish_instance ? fish.fish_traits : SSfishing.fish_properties[fish][FISH_PROPERTIES_TRAITS]
		for(var/fish_trait in fish_traits)
			var/datum/fish_trait/trait = GLOB.fish_traits[fish_trait]
			trait.minigame_mod(used_rod, user, src)
	else
		mover = new /datum/fish_movement(src)

	SEND_SIGNAL(src, COMSIG_FISHING_CHALLENGE_MOVER_INITIALIZED, mover)

	if(auto_reel)
		completion *= 1.3
	else
		var/time_left = timeleft(next_phase_timer)
		switch(time_left)
			if(0 to BITING_TIME_WINDOW - 3 SECONDS)
				completion *= 0.65
			if(BITING_TIME_WINDOW - 3 SECONDS to BITING_TIME_WINDOW - 2 SECONDS)
				completion *= 0.82
			if(BITING_TIME_WINDOW - 1 SECONDS to BITING_TIME_WINDOW - 0.5 SECONDS)
				completion *= 1.2
			if(BITING_TIME_WINDOW - 0.5 SECONDS to BITING_TIME_WINDOW)
				completion *= 1.4
	//randomize the position of the fish a little
	fish_position = rand(0, (FISHING_MINIGAME_AREA - fish_height) * 0.8)
	var/diff_dist = 100 + difficulty
	bait_position = clamp(round(fish_position + rand(-diff_dist, diff_dist) - bait_height * 0.5), 0, FISHING_MINIGAME_AREA - bait_height)

	if(!prepare_minigame_hud())
		get_stack_trace("couldn't prepare minigame hud for a fishing challenge.") //just to be sure. This shouldn't happen.
		qdel(src)
		return

	adjust_to_difficulty()

	phase = MINIGAME_PHASE
	deltimer(next_phase_timer)
	if((FISHING_MINIGAME_RULE_KILL in special_effects) && ispath(reward_path,/obj/item/fish))
		var/obj/item/fish/fish = reward_path
		var/wait_time = (initial(fish.health) / FISH_DAMAGE_PER_SECOND) SECONDS
		addtimer(CALLBACK(src, PROC_REF(win_anyway)), wait_time, TIMER_DELETE_ME)
	else if(ismovable(reward_path))
		var/atom/movable/reward = reward_path
		RegisterSignal(reward, COMSIG_MOVABLE_MOVED, PROC_REF(on_reward_removed))
		if(is_fish_instance)
			RegisterSignal(reward, COMSIG_FISH_STATUS_CHANGED, PROC_REF(on_fish_death))
	start_time = world.time

///Throws a stack with prefixed text.
/datum/fishing_challenge/proc/get_stack_trace(init_text)
	var/text = "[init_text] "
	text += "used rod: [used_rod || "null"], "
	if(used_rod)
		text += "bait: [used_rod.bait || "null"], "
	text += "reward: [reward_path || "null"], "
	text += "user: [user || "null"]"
	if(user)
		if(QDELING(user))
			text += ", user qdeling"
		else if(!user.client)
			text += ", user clientless"
	text += "."
	stack_trace(text)

#undef FISH_DAMAGE_PER_SECOND

///Initialize the minigame hud and register some signals to make it work.
/datum/fishing_challenge/proc/prepare_minigame_hud()
	if(!user.client || user.incapacitated)
		return FALSE
	. = TRUE
	fishing_hud = new
	fishing_hud.prepare_minigame(src)
	RegisterSignal(user.client, COMSIG_CLIENT_MOUSEDOWN, PROC_REF(start_reeling))
	RegisterSignal(user.client, COMSIG_CLIENT_MOUSEUP, PROC_REF(stop_reeling))
	RegisterSignal(user, COMSIG_MOB_LOGOUT, PROC_REF(on_user_logout))
	if(length(active_effects))
		// Give the player a moment to prepare for active minigame effects
		COOLDOWN_START(src, active_effect_cd, rand(5, 9) SECONDS)
	START_PROCESSING(SSfishing, src)

///Stop processing and remove references to the minigame hud
/datum/fishing_challenge/proc/remove_minigame_hud()
	STOP_PROCESSING(SSfishing, src)
	QDEL_NULL(fishing_hud)

///While the mouse button is held down, the bait will be reeling up (or down on r-click if the bidirectional rule is enabled)
/datum/fishing_challenge/proc/start_reeling(client/source, datum/object, location, control, params)
	SIGNAL_HANDLER
	var/bidirectional = special_effects & FISHING_MINIGAME_RULE_BIDIRECTIONAL
	var/list/modifiers = params2list(params)
	if(bidirectional && LAZYACCESS(modifiers, RIGHT_CLICK))
		reeling_state = REELING_STATE_DOWN
	else
		reeling_state = REELING_STATE_UP

///Reset the reeling state to idle once the mouse button is released
/datum/fishing_challenge/proc/stop_reeling(client/source, datum/object, location, control, params)
	SIGNAL_HANDLER
	reeling_state = REELING_STATE_IDLE

///Update the state of the fish, the bait and the hud
/datum/fishing_challenge/process(seconds_per_tick)
	if(length(active_effects) && COOLDOWN_FINISHED(src, active_effect_cd))
		select_active_effect()
	mover.move_fish(seconds_per_tick)
	move_bait(seconds_per_tick)
	if(!QDELETED(fishing_hud))
		update_visuals(seconds_per_tick)

///The proc that handles fancy effects like flipping the hud or skewing movement
/datum/fishing_challenge/proc/select_active_effect()
	///bring forth an active effect
	if(isnull(current_active_effect))
		current_active_effect = pick(active_effects)
		switch(current_active_effect)
			if(FISHING_MINIGAME_RULE_ANTIGRAV)
				fishing_hud.icon_state = "background_antigrav"
				SEND_SOUND(user, sound('sound/effects/arcade_jump.ogg', volume = 50))
				COOLDOWN_START(src, active_effect_cd, rand(6, 9) SECONDS)
			if(FISHING_MINIGAME_RULE_FLIP)
				fishing_hud.icon_state = "background_flip"
				fishing_hud.transform = fishing_hud.transform.Scale(1, -1)
				SEND_SOUND(user, sound('sound/effects/boing.ogg'))
				COOLDOWN_START(src, active_effect_cd, rand(5, 6) SECONDS)
			if(FISHING_MINIGAME_RULE_CAMO)
				fishing_hud.icon_state = "background_camo"
				SEND_SOUND(user, sound('sound/effects/nightmare_poof.ogg', volume = 15))
				COOLDOWN_START(src, active_effect_cd, rand(6, 8) SECONDS)
				animate(fishing_hud.hud_fish, alpha = 7, time = 2 SECONDS)
		return

	///go back to normal
	switch(current_active_effect)
		if(FISHING_MINIGAME_RULE_ANTIGRAV)
			var/sound/inverted_sound = sound('sound/effects/arcade_jump.ogg', volume = 50)
			inverted_sound.frequency = -1
			SEND_SOUND(user, inverted_sound)
			COOLDOWN_START(src, active_effect_cd, rand(10, 13) SECONDS)
		if(FISHING_MINIGAME_RULE_FLIP)
			fishing_hud.transform = fishing_hud.transform.Scale(1, -1)
			COOLDOWN_START(src, active_effect_cd, rand(8, 12) SECONDS)
		if(FISHING_MINIGAME_RULE_CAMO)
			COOLDOWN_START(src, active_effect_cd, rand(9, 16) SECONDS)
			SEND_SOUND(user, sound('sound/effects/nightmare_reappear.ogg', volume = 15))
			animate(fishing_hud.hud_fish, alpha = 255, time = 1.2 SECONDS)

	fishing_hud.icon_state = background
	current_active_effect = null

///The proc that moves the bait around, just like in the old TGUI, mostly.
/datum/fishing_challenge/proc/move_bait(seconds_per_tick)
	var/should_bounce = abs(bait_velocity) > BAIT_MIN_VELOCITY_BOUNCE
	bait_position += bait_velocity * seconds_per_tick
	// Hitting the top bound
	if(bait_position > FISHING_MINIGAME_AREA - bait_height)
		bait_position = FISHING_MINIGAME_AREA - bait_height
		if(reeling_state == REELING_STATE_UP || !should_bounce)
			bait_velocity = 0
		else
			bait_velocity = -bait_velocity * bait_bounce_mult
	// Hitting rock bottom
	else if(bait_position < 0)
		bait_position = 0
		if(reeling_state == REELING_STATE_DOWN || !should_bounce)
			bait_velocity = 0
		else
			bait_velocity = -bait_velocity * bait_bounce_mult

	var/fish_on_bait = (fish_position + fish_height >= bait_position) && (bait_position + bait_height >= fish_position)

	var/bidirectional = special_effects & FISHING_MINIGAME_RULE_BIDIRECTIONAL

	var/velocity_change
	switch(reeling_state)
		if(REELING_STATE_UP)
			velocity_change = reeling_velocity
		if(REELING_STATE_DOWN)
			velocity_change = -reeling_velocity
		if(REELING_STATE_IDLE)
			if(!bidirectional || bait_velocity > 0)
				velocity_change = gravity_velocity
			else
				velocity_change = -gravity_velocity
	velocity_change *= (fish_on_bait ? FISH_ON_BAIT_ACCELERATION_MULT : 1) * seconds_per_tick

	velocity_change = round(velocity_change)

	if(current_active_effect == FISHING_MINIGAME_RULE_ANTIGRAV)
		velocity_change = -velocity_change

	/**
	 * Pull the brake on the velocity if the current velocity and the acceleration
	 * have different directions, making the bait less slippery, thus easier to control
	 */
	if(bait_velocity > 0 && velocity_change < 0)
		bait_velocity += max(-bait_velocity, velocity_change * deceleration_mult)
	else if(bait_velocity < 0 && velocity_change > 0)
		bait_velocity += min(-bait_velocity, velocity_change * deceleration_mult)

	///bidirectional baits stay bouyant while idle
	if(bidirectional && reeling_state == REELING_STATE_IDLE)
		if(velocity_change < 0)
			bait_velocity = max(bait_velocity + velocity_change, 0)
		else if(velocity_change > 0)
			bait_velocity = min(bait_velocity + velocity_change, 0)
	else
		bait_velocity += velocity_change

	//check that the fish area is still intersecting the bait now that it has moved
	if(is_fish_on_bait())
		completion += completion_gain * seconds_per_tick
		if(completion >= 100)
			complete(TRUE)
	else
		completion -= completion_loss * seconds_per_tick
		if(completion <= 0 && !(special_effects & FISHING_MINIGAME_RULE_NO_ESCAPE))
			user.balloon_alert(user, "it got away!")
			complete(FALSE)

	completion = clamp(completion, 0, 100)

///Returns TRUE if the fish and the bait are intersecting
/datum/fishing_challenge/proc/is_fish_on_bait()
	return (fish_position + fish_height >= bait_position) && (bait_position + bait_height >= fish_position)

///update the vertical pixel position of both fish and bait, and the icon state of the completion bar
/datum/fishing_challenge/proc/update_visuals(seconds_per_tick)
	var/bait_offset_mult = bait_position / FISHING_MINIGAME_AREA
	animate(fishing_hud.hud_bait, pixel_y = MINIGAME_SLIDER_HEIGHT * bait_offset_mult, time = seconds_per_tick SECONDS)
	var/fish_offset_mult = fish_position / FISHING_MINIGAME_AREA
	animate(fishing_hud.hud_fish, pixel_y = MINIGAME_SLIDER_HEIGHT * fish_offset_mult, time = seconds_per_tick SECONDS)
	fishing_hud.hud_completion.update_state(completion, seconds_per_tick)

///The screen object which bait, fish, and completion bar are visually attached to.
/atom/movable/screen/fishing_hud
	icon = 'icons/hud/fishing_hud.dmi'
	screen_loc = "CENTER+1:8,CENTER:2"
	name = "fishing minigame"
	appearance_flags = APPEARANCE_UI|KEEP_TOGETHER
	///The fish as shown in the minigame
	var/atom/movable/screen/hud_fish/hud_fish
	///The bait as shown in the minigame
	var/atom/movable/screen/hud_bait/hud_bait
	///The completion bar as shown in the minigame
	var/atom/movable/screen/hud_completion/hud_completion

///Initialize bait, fish and completion bar and add them to the visual appearance of this screen object.
/atom/movable/screen/fishing_hud/proc/prepare_minigame(datum/fishing_challenge/challenge)
	icon_state = challenge.background
	add_overlay(challenge.used_rod?.get_frame(challenge) || "frame_wood")
	hud_bait = new(null, null, challenge)
	hud_fish = new(null, null, challenge)
	hud_completion = new(null, null)
	vis_contents += list(hud_bait, hud_fish, hud_completion)
	challenge.user.client.screen += src
	challenge.update_visuals(0) // Set all states to their initial positions so they don't jump around when the game starts
	master_ref = WEAKREF(challenge)

/atom/movable/screen/fishing_hud/Destroy()
	var/datum/fishing_challenge/challenge = master_ref?.resolve()
	if(!isnull(challenge))
		challenge.user.client.screen -= src
	QDEL_NULL(hud_fish)
	QDEL_NULL(hud_bait)
	QDEL_NULL(hud_completion)
	return ..()

/atom/movable/screen/hud_bait
	icon = 'icons/hud/fishing_hud.dmi'
	icon_state = "bait_bottom"
	vis_flags = VIS_INHERIT_ID
	var/cur_height = MINIGAME_BAIT_HEIGHT

/atom/movable/screen/hud_bait/Initialize(mapload, datum/hud/hud_owner, datum/fishing_challenge/challenge)
	. = ..()
	if(!challenge || challenge.bait_pixel_height == MINIGAME_BAIT_HEIGHT)
		update_icon()
		return

	adjust_to_difficulty(challenge)

/atom/movable/screen/hud_bait/proc/adjust_to_difficulty(datum/fishing_challenge/challenge)
	cur_height = challenge.bait_pixel_height
	update_icon()

/atom/movable/screen/hud_bait/update_overlays()
	. = ..()
	var/mutable_appearance/bait_top = mutable_appearance(icon, "bait_top")
	bait_top.pixel_y += cur_height - MINIGAME_BAIT_TOP_AND_BOTTOM_HEIGHT
	. += bait_top
	for (var/i in 1 to (cur_height - MINIGAME_BAIT_TOP_AND_BOTTOM_HEIGHT))
		var/mutable_appearance/bait_bar = mutable_appearance(icon, "bait_bar")
		bait_bar.pixel_y += i
		. += bait_bar

/atom/movable/screen/hud_fish
	icon = 'icons/hud/fishing_hud.dmi'
	icon_state = "fish"
	vis_flags = VIS_INHERIT_ID

/atom/movable/screen/hud_fish/Initialize(mapload, datum/hud/hud_owner, datum/fishing_challenge/challenge)
	. = ..()
	if(challenge)
		icon_state = challenge.fish_icon

/atom/movable/screen/hud_completion
	icon = 'icons/hud/fishing_hud.dmi'
	icon_state = "completion_overlay"
	vis_flags = VIS_INHERIT_ID

/atom/movable/screen/hud_completion/Initialize(mapload, datum/hud/hud_owner)
	. = ..()
	add_filter("completion_mask", 1, alpha_mask_filter(icon = icon(icon, "completion_overlay")))

/atom/movable/screen/hud_completion/proc/update_state(completion, seconds_per_tick)
	animate(get_filter("completion_mask"), y = -MINIGAME_COMPLETION_BAR_HEIGHT * (1 - completion * 0.01), time = seconds_per_tick SECONDS)

/// The visual that appears over the fishing spot
/obj/effect/fishing_float
	name = "float"
	icon = 'icons/obj/fishing.dmi'
	icon_state = "float"
	mouse_opacity = MOUSE_OPACITY_TRANSPARENT
	/**
	 * A list with two keys delimiting the spinning interval in which a mouse click has to be pressed while fishing.
	 * If set, an emissive overlay will be added, colored green when the lure is ready to be spun, otherwise red.
	 */
	var/list/spin_frequency
	///Is the bait ready to be spun?
	var/spin_ready = FALSE

/obj/effect/fishing_float/Initialize(mapload, atom/spot)
	. = ..()
	if(!spot)
		return
	if(ismovable(spot)) // we want the float and therefore the fishing line to stay connected with the fishing spot.
		RegisterSignal(spot, COMSIG_MOVABLE_MOVED, PROC_REF(follow_movable))
	SET_BASE_PIXEL(spot.pixel_x, spot.pixel_y)
	SET_BASE_VISUAL_PIXEL(spot.pixel_w, spot.pixel_z)
	// early return for spots with a plane lower than this. the floor plane is topdown and we don't want to inherit their layers.
	if(spot.plane < plane)
		return
	if(spot.plane > plane) //We want this to render above the fishing spot.
		var/turf/turf = get_turf(spot)
		SET_PLANE_EXPLICIT(src, PLANE_TO_TRUE(spot.plane), turf)
	if(spot.layer > layer) //Ditto. New stuff renders above old stuff if the layer is the same iirc (with some caveats).
		layer = spot.layer

/obj/effect/fishing_float/proc/follow_movable(atom/movable/source)
	SIGNAL_HANDLER

	set_glide_size(source.glide_size)
	forceMove(source.loc)

/obj/effect/fishing_float/update_overlays()
	. = ..()
	if(!spin_frequency)
		return
	var/mutable_appearance/overlay = mutable_appearance(icon, "lure_light")
	overlay.color = spin_ready ? COLOR_GREEN : COLOR_RED
	. += overlay
	. += emissive_appearance(icon, "lure_light_emissive", src, alpha = src.alpha)

#undef WAIT_PHASE
#undef BITING_PHASE
#undef MINIGAME_PHASE

#undef MINIGAME_SLIDER_HEIGHT
#undef MINIGAME_BAIT_HEIGHT
#undef MINIGAME_FISH_HEIGHT
#undef MINIGAME_BAIT_TOP_AND_BOTTOM_HEIGHT
#undef MINIGAME_COMPLETION_BAR_HEIGHT

#undef BAIT_HEIGHT_DIFFICULTY_MALUS

#undef REELING_STATE_IDLE
#undef REELING_STATE_UP
#undef REELING_STATE_DOWN

#undef FISH_ON_BAIT_ACCELERATION_MULT
#undef BAIT_MIN_VELOCITY_BOUNCE

#undef MAX_FISH_COMPLETION_MALUS
#undef BITING_TIME_WINDOW
