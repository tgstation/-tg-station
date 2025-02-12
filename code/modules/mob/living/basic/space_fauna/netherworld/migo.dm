/mob/living/basic/migo
	name = "mi-go"
	desc = "A pinkish, fungoid crustacean-like creature with clawed appendages and a head covered with waving antennae."
	icon_state = "mi-go"
	icon_living = "mi-go"
	icon_dead = "mi-go-dead"
	health = 80
	maxHealth = 80
	obj_damage = 50
	melee_damage_lower = 25
	melee_damage_upper = 50
	speed = 1
	attack_verb_continuous = "lacerates"
	attack_verb_simple = "lacerate"
	melee_attack_cooldown = 1 SECONDS
	gold_core_spawnable = HOSTILE_SPAWN
	attack_sound = 'sound/items/weapons/bladeslice.ogg'
	attack_vis_effect = ATTACK_EFFECT_SLASH
	faction = list(FACTION_NETHER)
	speak_emote = list("screams", "clicks", "chitters", "barks", "moans", "growls", "meows", "reverberates", "roars", "squeaks", "rattles", "exclaims", "yells", "remarks", "mumbles", "jabbers", "stutters", "seethes")
	death_message = "wails as its form turns into a pulpy mush."
	death_sound = 'sound/mobs/non-humanoids/hiss/hiss6.ogg'
	unsuitable_atmos_damage = 0
	unsuitable_cold_damage = 0
	unsuitable_heat_damage = 0
	// Real blue, trying to go for the migo's look
	lighting_cutoff_red = 15
	lighting_cutoff_green = 15
	lighting_cutoff_blue = 50

	ai_controller = /datum/ai_controller/basic_controller/simple/simple_hostile_obstacles
	var/static/list/migo_sounds
	/// Odds migo will dodge
	var/dodge_prob = 10

/mob/living/basic/migo/Initialize(mapload)
	. = ..()
	migo_sounds = list('sound/items/bubblewrap.ogg', 'sound/items/tools/change_jaws.ogg', 'sound/items/tools/crowbar.ogg', 'sound/items/drink.ogg', 'sound/items/deconstruct.ogg', 'sound/items/carhorn.ogg', 'sound/items/tools/change_drill.ogg', 'sound/items/dodgeball.ogg', 'sound/items/eatfood.ogg', 'sound/items/megaphone.ogg', 'sound/items/tools/screwdriver.ogg', 'sound/items/weeoo1.ogg', 'sound/items/tools/wirecutter.ogg', 'sound/items/tools/welder.ogg', 'sound/items/zip/zip.ogg', 'sound/items/tools/rped.ogg', 'sound/items/tools/ratchet.ogg', 'sound/items/polaroid/polaroid1.ogg', 'sound/items/pshoom/pshoom.ogg', 'sound/items/airhorn/airhorn.ogg', 'sound/items/geiger/high1.ogg', 'sound/items/geiger/high2.ogg', 'sound/mobs/non-humanoids/beepsky/creep.ogg', 'sound/mobs/non-humanoids/beepsky/iamthelaw.ogg', 'sound/mobs/non-humanoids/ed209/ed209_20sec.ogg', 'sound/mobs/non-humanoids/hiss/hiss3.ogg', 'sound/mobs/non-humanoids/hiss/hiss6.ogg', 'sound/mobs/non-humanoids/medbot/patchedup.ogg', 'sound/mobs/non-humanoids/medbot/feelbetter.ogg', 'sound/mobs/humanoids/human/laugh/manlaugh1.ogg', 'sound/mobs/humanoids/human/laugh/womanlaugh.ogg', 'sound/items/weapons/sear.ogg', 'sound/music/antag/clockcultalr.ogg', 'sound/music/antag/ling_alert.ogg', 'sound/music/antag/traitor/tatoralert.ogg', 'sound/music/antag/monkey.ogg', 'sound/vehicles/mecha/nominal.ogg', 'sound/vehicles/mecha/weapdestr.ogg', 'sound/vehicles/mecha/critdestr.ogg', 'sound/vehicles/mecha/imag_enh.ogg', 'sound/effects/adminhelp.ogg', 'sound/effects/alert.ogg', 'sound/effects/blob/attackblob.ogg', 'sound/effects/bamf.ogg', 'sound/effects/blob/blobattack.ogg', 'sound/effects/break_stone.ogg', 'sound/effects/bubbles/bubbles.ogg', 'sound/effects/bubbles/bubbles2.ogg', 'sound/effects/clang.ogg', 'sound/effects/clockcult_gateway_disrupted.ogg', 'sound/effects/footstep/clownstep2.ogg', 'sound/effects/curse/curse1.ogg', 'sound/effects/dimensional_rend.ogg', 'sound/effects/doorcreaky.ogg', 'sound/effects/empulse.ogg', 'sound/effects/explosion/explosion_distant.ogg', 'sound/effects/explosion/explosionfar.ogg', 'sound/effects/explosion/explosion1.ogg', 'sound/effects/grillehit.ogg', 'sound/effects/genetics.ogg', 'sound/effects/heart_beat.ogg', 'sound/runtime/hyperspace/hyperspace_begin.ogg', 'sound/runtime/hyperspace/hyperspace_end.ogg', 'sound/effects/his_grace/his_grace_awaken.ogg', 'sound/effects/pai_boot.ogg', 'sound/effects/phasein.ogg', 'sound/effects/pickaxe/picaxe1.ogg', 'sound/effects/sparks/sparks1.ogg', 'sound/effects/smoke.ogg', 'sound/effects/splat.ogg', 'sound/effects/snap.ogg', 'sound/effects/tendril_destroyed.ogg', 'sound/effects/supermatter.ogg', 'sound/effects/desecration/desecration-01.ogg', 'sound/effects/desecration/desecration-02.ogg', 'sound/effects/desecration/desecration-03.ogg', 'sound/announcer/alarm/bloblarm.ogg', 'sound/announcer/alarm/airraid.ogg', 'sound/misc/bang.ogg','sound/misc/highlander.ogg', 'sound/misc/interference.ogg', 'sound/announcer/notice/notice1.ogg', 'sound/announcer/notice/notice2.ogg', 'sound/misc/sadtrombone.ogg', 'sound/misc/slip.ogg', 'sound/misc/splort.ogg', 'sound/items/weapons/armbomb.ogg', 'sound/items/weapons/beam_sniper.ogg', 'sound/items/weapons/chainsawhit.ogg', 'sound/items/weapons/emitter.ogg', 'sound/items/weapons/emitter2.ogg', 'sound/items/weapons/blade1.ogg', 'sound/items/weapons/bladeslice.ogg', 'sound/items/weapons/blastcannon.ogg', 'sound/items/weapons/blaster.ogg', 'sound/items/weapons/bulletflyby3.ogg', 'sound/items/weapons/circsawhit.ogg', 'sound/items/weapons/cqchit2.ogg', 'sound/items/weapons/drill.ogg', 'sound/items/weapons/genhit1.ogg', 'sound/items/weapons/gun/pistol/shot_suppressed.ogg', 'sound/items/weapons/gun/pistol/shot.ogg', 'sound/items/weapons/handcuffs.ogg', 'sound/items/weapons/homerun.ogg', 'sound/items/weapons/kinetic_accel.ogg', 'sound/machines/clockcult/steam_whoosh.ogg', 'sound/machines/fryer/deep_fryer_emerge.ogg', 'sound/machines/airlock/airlock.ogg', 'sound/machines/airlock/airlock_alien_prying.ogg', 'sound/machines/airlock/airlockclose.ogg', 'sound/machines/airlock/airlockforced.ogg', 'sound/machines/airlock/airlockopen.ogg', 'sound/announcer/alarm/nuke_alarm.ogg', 'sound/machines/blender.ogg', 'sound/machines/airlock/boltsdown.ogg', 'sound/machines/airlock/boltsup.ogg', 'sound/machines/buzz/buzz-sigh.ogg', 'sound/machines/buzz/buzz-two.ogg', 'sound/machines/chime.ogg', 'sound/machines/cryo_warning.ogg', 'sound/machines/defib/defib_charge.ogg', 'sound/machines/defib/defib_failed.ogg', 'sound/machines/defib/defib_ready.ogg', 'sound/machines/defib/defib_zap.ogg', 'sound/machines/beep/deniedbeep.ogg', 'sound/machines/ding.ogg', 'sound/machines/disposalflush.ogg', 'sound/machines/door/door_close.ogg', 'sound/machines/door/door_open.ogg', 'sound/machines/engine_alert/engine_alert1.ogg', 'sound/machines/engine_alert/engine_alert2.ogg', 'sound/machines/hiss.ogg', 'sound/mobs/non-humanoids/honkbot/honkbot_evil_laugh.ogg', 'sound/machines/juicer.ogg', 'sound/machines/ping.ogg', 'sound/ambience/misc/signal.ogg', 'sound/machines/synth/synth_no.ogg', 'sound/machines/synth/synth_yes.ogg', 'sound/machines/terminal/terminal_alert.ogg', 'sound/machines/beep/triple_beep.ogg', 'sound/machines/beep/twobeep.ogg', 'sound/machines/ventcrawl.ogg', 'sound/machines/warning-buzzer.ogg', 'sound/announcer/default/outbreak5.ogg', 'sound/announcer/default/outbreak7.ogg', 'sound/announcer/default/poweroff.ogg', 'sound/announcer/default/radiation.ogg', 'sound/announcer/default/shuttlecalled.ogg', 'sound/announcer/default/shuttledock.ogg', 'sound/announcer/default/shuttlerecalled.ogg', 'sound/announcer/default/aimalf.ogg') //hahahaha fuck you code divers

	if(!istype(src, /mob/living/basic/migo/hatsune) && prob(0.1)) // chance on-load mi-gos will spawn with a miku wig on (shiny variant)
		new /mob/living/basic/migo/hatsune(get_turf(loc), mapload)
		return INITIALIZE_HINT_QDEL

	AddElement(/datum/element/swabable, CELL_LINE_TABLE_NETHER, CELL_VIRUS_TABLE_GENERIC_MOB, 1, 0)
	AddComponent(/datum/component/health_scaling_effects, min_health_slowdown = -1.5, additional_status_callback = CALLBACK(src, PROC_REF(update_dodge_chance)))

/// Makes the migo more likely to dodge around the more damaged it is
/mob/living/basic/migo/proc/update_dodge_chance(health_ratio)
	dodge_prob = LERP(50, 10, health_ratio)

/mob/living/basic/migo/proc/make_migo_sound()
	playsound(src, pick(migo_sounds), 50, TRUE)

/mob/living/basic/migo/send_speech(message_raw, message_range, obj/source, bubble_type, list/spans, datum/language/message_language, list/message_mods, forced, tts_message, list/tts_filter)
	. = ..()
	if(stat != CONSCIOUS)
		return
	make_migo_sound()

/mob/living/basic/migo/Life(seconds_per_tick = SSMOBS_DT, times_fired)
	..()
	if(stat)
		return
	if(SPT_PROB(5, seconds_per_tick))
		make_migo_sound()

/mob/living/basic/migo/Move(atom/newloc, dir, step_x, step_y)
	if(!ckey && prob(dodge_prob) && moving_diagonally == 0 && isturf(loc) && isturf(newloc))
		return dodge(newloc, dir)
	else
		return ..()

/mob/living/basic/migo/proc/dodge(moving_to, move_direction)
	//Assuming we move towards the target we want to swerve toward them to get closer
	var/cdir = turn(move_direction, 45)
	var/ccdir = turn(move_direction, -45)
	. = Move(get_step(loc,pick(cdir, ccdir)))
	if(!.)//Can't dodge there so we just carry on
		. = Move(moving_to, move_direction)

/// The special hatsune miku themed mi-go.
/mob/living/basic/migo/hatsune
	name = "hatsune mi-go"
	desc = parent_type::desc + " This one is wearing a bright blue wig."
	icon_state = "mi-go-h"
	icon_living = "mi-go-h"

	gender = FEMALE
	gold_core_spawnable = FRIENDLY_SPAWN
	faction = list(FACTION_NEUTRAL)

/mob/living/basic/migo/hatsune/make_migo_sound()
	playsound(src, 'sound/mobs/non-humanoids/tourist/tourist_talk_japanese1.ogg', 50, TRUE)

/mob/living/basic/migo/hatsune/Initialize(mapload)
	. = ..()
	var/static/list/death_loot = list(/obj/item/instrument/piano_synth)
	AddElement(/datum/element/death_drops, death_loot)
