// This file contains all of the "static" define strings that tie to a trait.
// WARNING: The sections here actually matter in this file as it's tested by CI. Please do not toy with the sections."

// BEGIN TRAIT DEFINES

/*
Remember to update _globalvars/traits.dm if you're adding/removing/renaming traits.
*/

//mob traits
/// Forces the user to stay unconscious.
#define TRAIT_KNOCKEDOUT "knockedout"
/// Prevents voluntary movement.
#define TRAIT_IMMOBILIZED "immobilized"
/// Prevents voluntary standing or staying up on its own.
#define TRAIT_FLOORED "floored"
/// Forces user to stay standing
#define TRAIT_FORCED_STANDING "forcedstanding"
/// Prevents usage of manipulation appendages (picking, holding or using items, manipulating storage).
#define TRAIT_HANDS_BLOCKED "handsblocked"
/// Inability to access UI hud elements. Turned into a trait from [MOBILITY_UI] to be able to track sources.
#define TRAIT_UI_BLOCKED "uiblocked"
/// Inability to pull things. Turned into a trait from [MOBILITY_PULL] to be able to track sources.
#define TRAIT_PULL_BLOCKED "pullblocked"
/// Abstract condition that prevents movement if being pulled and might be resisted against. Handcuffs and straight jackets, basically.
#define TRAIT_RESTRAINED "restrained"
/// Apply this to make a mob not dense, and remove it when you want it to no longer make them undense, other sources of undesity will still apply. Always define a unique source when adding a new instance of this!
#define TRAIT_UNDENSE "undense"
/// Makes the mob immune to damage and several other ailments.
#define TRAIT_GODMODE "godmode"
/// Expands our FOV by 30 degrees if restricted
#define TRAIT_EXPANDED_FOV "expanded_fov"
/// Doesn't miss attacks
#define TRAIT_PERFECT_ATTACKER "perfect_attacker"
///Recolored by item/greentext
#define TRAIT_GREENTEXT_CURSED "greentext_curse"
#define TRAIT_INCAPACITATED "incapacitated"
/// In some kind of critical condition. Is able to succumb.
#define TRAIT_CRITICAL_CONDITION "critical-condition"
/// Whitelist for mobs that can read or write
#define TRAIT_LITERATE "literate"
/// Blacklist for mobs that can't read or write
#define TRAIT_ILLITERATE "illiterate"
/// Mute. Can't talk.
#define TRAIT_MUTE "mute"
/// Softspoken. Always whisper.
#define TRAIT_SOFTSPOKEN "softspoken"
/// Gibs on death and slips like ice.
#define TRAIT_CURSED "cursed"
/// Emotemute. Can't... emote.
#define TRAIT_EMOTEMUTE "emotemute"
#define TRAIT_DEAF "deaf"
#define TRAIT_FAT "fat"
/// Always hungry. They can eat as much as they want without eating slowdown.
#define TRAIT_GLUTTON "glutton"
#define TRAIT_HUSK "husk"
///Blacklisted from being revived via defibrillator
#define TRAIT_DEFIB_BLACKLISTED "defib_blacklisted"
#define TRAIT_BADDNA "baddna"
#define TRAIT_CLUMSY "clumsy"
/// Trait that means you are capable of holding items in some form
#define TRAIT_CAN_HOLD_ITEMS "can_hold_items"
/// Trait which lets you clamber over a barrier
#define TRAIT_FENCE_CLIMBER "can_climb_fences"
/// means that you can't use weapons with normal trigger guards.
#define TRAIT_CHUNKYFINGERS "chunkyfingers"
#define TRAIT_CHUNKYFINGERS_IGNORE_BATON "chunkyfingers_ignore_baton"
/// Allows you to mine with your bare hands
#define TRAIT_FIST_MINING "fist_mining"
#define TRAIT_DUMB "dumb"
/// Whether a mob is dexterous enough to use machines and certain items or not.
#define TRAIT_ADVANCEDTOOLUSER "advancedtooluser"
// Antagonizes the above.
#define TRAIT_DISCOORDINATED_TOOL_USER "discoordinated_tool_user"
#define TRAIT_PACIFISM "pacifism"
// Trait added to the user of a hippocratic oath status effect
#define TRAIT_HIPPOCRATIC_OATH "hippocratic_oath"
#define TRAIT_IGNORESLOWDOWN "ignoreslow"
/// Makes it so the mob can use guns regardless of tool user status
#define TRAIT_GUN_NATURAL "gunnatural"
/// Causes death-like unconsciousness
#define TRAIT_DEATHCOMA "deathcoma"
/// The mob has the stasis effect.
/// Does nothing on its own, applied via status effect.
#define TRAIT_STASIS "in_stasis"
/// Makes the owner appear as dead to most forms of medical examination
#define TRAIT_FAKEDEATH "fakedeath"
#define TRAIT_DISFIGURED "disfigured"
/// "Magic" trait that blocks the mob from moving or interacting with anything. Used for transient stuff like mob transformations or incorporality in special cases.
/// Will block movement, `Life()` (!!!), and other stuff based on the mob.
#define TRAIT_NO_TRANSFORM "block_transformations"
/// Tracks whether we're gonna be a baby alien's mummy.
#define TRAIT_XENO_HOST "xeno_host"
/// This parrot is currently perched
#define TRAIT_PARROT_PERCHED "parrot_perched"
/// This mob is immune to stun causing status effects and stamcrit.
/// Prefer to use [/mob/living/proc/check_stun_immunity] over checking for this trait exactly.
#define TRAIT_STUNIMMUNE "stun_immunity"
#define TRAIT_BATON_RESISTANCE "baton_resistance"
/// Anti Dual-baton cooldown bypass exploit.
#define TRAIT_IWASBATONED "iwasbatoned"
#define TRAIT_SLEEPIMMUNE "sleep_immunity"
#define TRAIT_PUSHIMMUNE "push_immunity"
/// can't be kicked to the side
#define TRAIT_NO_SIDE_KICK "no_side_kick"
/// Are we immune to shocks?
#define TRAIT_SHOCKIMMUNE "shock_immunity"
/// Are we immune to specifically tesla / SM shocks?
#define TRAIT_TESLA_SHOCKIMMUNE "tesla_shock_immunity"
#define TRAIT_AIRLOCK_SHOCKIMMUNE "airlock_shock_immunity"
/// Is this atom being actively shocked? Used to prevent repeated shocks.
#define TRAIT_BEING_SHOCKED "shocked"
#define TRAIT_STABLEHEART "stable_heart"
/// Prevents you from leaving your corpse
#define TRAIT_CORPSELOCKED "corpselocked"
#define TRAIT_STABLELIVER "stable_liver"
#define TRAIT_VATGROWN "vatgrown"
#define TRAIT_RESISTHEAT "resist_heat"
/// Trait for when you can no longer gain body heat
#define TRAIT_HYPOTHERMIC "body_hypothermic"
/// This non-living object is valid to be used in dna infusers
#define TRAIT_VALID_DNA_INFUSION "valid_dna_infusion"
///For when you've gotten a power from a dna vault
#define TRAIT_USED_DNA_VAULT "used_dna_vault"
/// For when you want to be able to touch hot things, but still want fire to be an issue.
#define TRAIT_RESISTHEATHANDS "resist_heat_handsonly"
#define TRAIT_RESISTCOLD "resist_cold"
#define TRAIT_RESISTHIGHPRESSURE "resist_high_pressure"
#define TRAIT_RESISTLOWPRESSURE "resist_low_pressure"
/// This human is immune to the effects of being exploded. (ex_act)
#define TRAIT_BOMBIMMUNE "bomb_immunity"
/// This mob won't get gibbed by nukes going off
#define TRAIT_NUKEIMMUNE "nuke_immunity"
/// Can't be given viruses
#define TRAIT_VIRUSIMMUNE "virus_immunity"
/// Won't become a husk under any circumstances
#define TRAIT_UNHUSKABLE "trait_unhuskable"
/// Reduces the chance viruses will spread to this mob, and if the mob has a virus, slows its advancement
#define TRAIT_VIRUS_RESISTANCE "virus_resistance"
#define TRAIT_GENELESS "geneless"
#define TRAIT_PIERCEIMMUNE "pierce_immunity"
#define TRAIT_NODISMEMBER "dismember_immunity"
#define TRAIT_NOFIRE "nonflammable"
#define TRAIT_NOFIRE_SPREAD "no_fire_spreading"
/// Prevents plasmamen from self-igniting if only their helmet is missing
#define TRAIT_HEAD_ATMOS_SEALED "no_selfignition_head_only"
#define TRAIT_NOGUNS "no_guns"
///Can toss a guns like a badass, causing additional damage/effect to their enemies
#define TRAIT_TOSS_GUN_HARD "toss_gun_hard"
/// Species with this trait are genderless
#define TRAIT_AGENDER "agender"
/// Species with this trait have a blood clan mechanic
#define TRAIT_BLOOD_CLANS "blood_clans"
/// Species with this trait use skin tones for coloration
#define TRAIT_USES_SKINTONES "uses_skintones"
/// Species with this trait use mutant colors for coloration
#define TRAIT_MUTANT_COLORS "mutcolors"
/// Species with this trait have mutant colors that cannot be chosen by the player, nor altered ingame by external means
#define TRAIT_FIXED_MUTANT_COLORS "fixed_mutcolors"
/// Humans with this trait won't get bloody hands, nor bloody feet
#define TRAIT_NO_BLOOD_OVERLAY "no_blood_overlay"
/// Humans with this trait cannot have underwear
#define TRAIT_NO_UNDERWEAR "no_underwear"
/// This carbon doesn't show an overlay when they have no brain
#define TRAIT_NO_DEBRAIN_OVERLAY "no_debrain_overlay"
/// Humans with this trait cannot get augmentation surgery
#define TRAIT_NO_AUGMENTS "no_augments"
/// This carbon doesn't get hungry
#define TRAIT_NOHUNGER "no_hunger"
/// This carbon doesn't bleed
#define TRAIT_NOBLOOD "noblood"
/// This just means that the carbon will always have functional liverless metabolism
#define TRAIT_LIVERLESS_METABOLISM "liverless_metabolism"
/// This carbon can't be overdosed by chems
#define TRAIT_OVERDOSEIMMUNE "overdose_immune"
/// Humans with this trait cannot be turned into zombies
#define TRAIT_NO_ZOMBIFY "no_zombify"
/// Carbons with this trait can't have their DNA copied by diseases nor changelings
#define TRAIT_NO_DNA_COPY "no_dna_copy"
/// Carbons with this trait can't have their DNA scrambled by genetics or a disease retrovirus.
#define TRAIT_NO_DNA_SCRAMBLE "no_dna_scramble"
/// Carbons with this trait can eat blood to regenerate their own blood volume, instead of injecting it
#define TRAIT_DRINKS_BLOOD "drinks_blood"
/// Mob is immune to toxin damage
#define TRAIT_TOXIMMUNE "toxin_immune"
/// Mob is immune to oxygen damage, does not need to breathe
#define TRAIT_NOBREATH "no_breath"
/// Mob is currently disguised as something else (like a morph being another mob or an object). Holds a reference to the thing that applied the trait.
#define TRAIT_DISGUISED "disguised"
/// Use when you want a mob to be able to metabolize plasma temporarily (e.g. plasma fixation disease symptom)
#define TRAIT_PLASMA_LOVER_METABOLISM "plasma_lover_metabolism"
/// The mob is not harmed by tetrodotoxin. Instead, it heals them like omnizine
#define TRAIT_TETRODOTOXIN_HEALING "tetrodotoxin_healing"
#define TRAIT_EASYDISMEMBER "easy_dismember"
#define TRAIT_LIMBATTACHMENT "limb_attach"
#define TRAIT_NOLIMBDISABLE "no_limb_disable"
#define TRAIT_EASILY_WOUNDED "easy_limb_wound"
#define TRAIT_HARDLY_WOUNDED "hard_limb_wound"
#define TRAIT_NEVER_WOUNDED "never_wounded"
/// Species with this trait have 50% extra chance of bleeding from piercing and slashing wounds
#define TRAIT_EASYBLEED "easybleed"
#define TRAIT_TOXINLOVER "toxinlover"
/// Doesn't get overlays from being in critical.
#define TRAIT_NOCRITOVERLAY "no_crit_overlay"
/// reduces the use time of syringes, pills, patches and medigels but only when using on someone
#define TRAIT_FASTMED "fast_med_use"
/// The mob is holy and resistance to cult magic
#define TRAIT_HOLY "holy"
/// This mob is antimagic, and immune to spells / cannot cast spells
#define TRAIT_ANTIMAGIC "anti_magic"
/// This allows a person who has antimagic to cast spells without getting blocked
#define TRAIT_ANTIMAGIC_NO_SELFBLOCK "anti_magic_no_selfblock"
/// This mob recently blocked magic with some form of antimagic
#define TRAIT_RECENTLY_BLOCKED_MAGIC "recently_blocked_magic"
/// The user can do things like use magic staffs without penalty
#define TRAIT_MAGICALLY_GIFTED "magically_gifted"
/// This object innately spawns with fantasy variables already applied (the magical component is given to it on initialize), and thus we never want to give it the component again.
#define TRAIT_INNATELY_FANTASTICAL_ITEM "innately_fantastical_item"
#define TRAIT_DEPRESSION "depression"
#define TRAIT_JOLLY "jolly"
#define TRAIT_NOCRITDAMAGE "no_crit"
/// Prevents shovies and some strong blows such as unarmed punches and (unreliably) tackles the owner down
#define TRAIT_BRAWLING_KNOCKDOWN_BLOCKED "brawling_knockdown_blocked"
/// Applies tackling defense bonus to any mob that has it
#define TRAIT_OFF_BALANCE_TACKLER "off_balance_tackler"
/// Prevents some severe head injuries being sustained from heavy collisions or blunt force injuries.
#define TRAIT_HEAD_INJURY_BLOCKED "head_injury_blocked"
/// Prevents staggering.
#define TRAIT_NO_STAGGER "no_stagger"
/// Getting hit by thrown movables won't push you away
#define TRAIT_NO_THROW_HITPUSH "no_throw_hitpush"
/// This mob likes to eat fish. Raw, uncut fish.
#define TRAIT_FISH_EATER "fish_eater"
///Added to mob or mind, changes the icons of the fish shown in the minigame UI depending on the possible reward.
#define TRAIT_REVEAL_FISH "reveal_fish"
///This trait gets you a list of fishes that can be caught when examining a fishing spot.
#define TRAIT_EXAMINE_FISHING_SPOT "examine_fishing_spot"
///lobstrosities and carps will prioritize/flee from those that have this trait (given by the skill-locked hat)
#define TRAIT_SCARY_FISHERMAN "scary_fisherman"
/// Atoms with this trait can be right-clicked with a fish to release them, presumably back in the fishing spot they were caught from.
#define TRAIT_CATCH_AND_RELEASE "catch_and_release"
///This trait lets you get the size and weight of the fish by examining them
#define TRAIT_EXAMINE_FISH "examine_fish"
///This trait lets you roughly know if the fish is dead, starving, drowning or sick by examining them
#define TRAIT_EXAMINE_DEEPER_FISH "examine_deeper_fish"
///Trait given to turfs or objects that can be fished from
#define TRAIT_FISHING_SPOT "fishing_spot"
///This trait prevents the fishing spot from being linked to the fish-porter when a multitool is being used.
#define TRAIT_UNLINKABLE_FISHING_SPOT "unlinkable_fishing_spot"
///Trait given to mobs that can fish without a rod
#define TRAIT_PROFOUND_FISHER "profound_fisher"
/// If an atom has this trait, then you can toss a bottle with a message in it.
#define TRAIT_MESSAGE_IN_A_BOTTLE_LOCATION "message_in_a_bottle_location"
/// Stops other objects of the same type from being inserted inside the same aquarium it's in.
#define TRAIT_UNIQUE_AQUARIUM_CONTENT "unique_aquarium_content"
/// Mobs that hate showers, being sprayed with water etc.
#define TRAIT_WATER_HATER "water_hater"
/// Improved boons from showers and some features centered around water, should also suppress TRAIT_WATER_HATER
#define TRAIT_WATER_ADAPTATION "water_adaptation"
/// Tells us that the mob urrently has the fire_handler/wet_stacks status effect
#define TRAIT_IS_WET "is_wet"
/// Mobs with this trait stay wet for longer and resist fire decaying wetness
#define TRAIT_WET_FOR_LONGER "wet_for_longer"
/// Mobs with this trait will be immune to slipping while also being slippery themselves when lying on the floor
#define TRAIT_SLIPPERY_WHEN_WET "slippery_when_wet"
/// This trait lets you evaluate someone's fitness level against your own
#define TRAIT_EXAMINE_FITNESS "reveal_power_level"
/// These mobs have particularly hygienic tongues
#define TRAIT_WOUND_LICKER "wound_licker"
/// Mobs with this trait are allowed to use silicon emotes
#define TRAIT_SILICON_EMOTES_ALLOWED "silicon_emotes_allowed"

/// This trait designate that the mob was originally a monkey
#define TRAIT_BORN_MONKEY "born_as_a_monkey"

/// Added to a mob, allows that mob to experience flavour-based moodlets when examining food
#define TRAIT_REMOTE_TASTING "remote_tasting"

/// Stops the mob from slipping on water, or banana peels, or pretty much anything that doesn't have [GALOSHES_DONT_HELP] set
#define TRAIT_NO_SLIP_WATER "noslip_water"
/// Stops the mob from slipping on permafrost ice (not any other ice) (but anything with [SLIDE_ICE] set)
#define TRAIT_NO_SLIP_ICE "noslip_ice"
/// Stop the mob from sliding around from being slipped, but not the slip part.
/// DOES NOT include ice slips.
#define TRAIT_NO_SLIP_SLIDE "noslip_slide"
/// Stops all slipping and sliding from occurring
#define TRAIT_NO_SLIP_ALL "noslip_all"

/// Unlinks gliding from movement speed, meaning that there will be a delay between movements rather than a single move movement between tiles
#define TRAIT_NO_GLIDE "no_glide"

/// Applied into wounds when they're scanned with the wound analyzer, halves time to treat them manually.
#define TRAIT_WOUND_SCANNED "wound_scanned"

/// Owner will ignore any fire protection when calculating fire damage
#define TRAIT_IGNORE_FIRE_PROTECTION "ignore_fire_protection"

#define TRAIT_NODEATH "nodeath"
#define TRAIT_NOHARDCRIT "nohardcrit"
#define TRAIT_NOSOFTCRIT "nosoftcrit"
/// Makes someone show up as mindshielded on sechuds. Does NOT actually make them unconvertable - See TRAIT_UNCONVERTABLE for that
#define TRAIT_MINDSHIELD "mindshield"
/// Makes it impossible for someone to be converted by cult/revs/etc.
#define TRAIT_UNCONVERTABLE "unconvertable"
#define TRAIT_DISSECTED "dissected"
#define TRAIT_SURGICALLY_ANALYZED "surgically_analyzed"
/// Lets the user succumb even if they got NODEATH
#define TRAIT_SUCCUMB_OVERRIDE "succumb_override"
/// Can hear observers
#define TRAIT_SIXTHSENSE "sixth_sense"
#define TRAIT_FEARLESS "fearless"
/// Ignores darkness for hearing
#define TRAIT_HEAR_THROUGH_DARKNESS "hear_through_darkness"
/// These are used for brain-based paralysis, where replacing the limb won't fix it
#define TRAIT_PARALYSIS_L_ARM "para-l-arm"
#define TRAIT_PARALYSIS_R_ARM "para-r-arm"
#define TRAIT_PARALYSIS_L_LEG "para-l-leg"
#define TRAIT_PARALYSIS_R_LEG "para-r-leg"
#define TRAIT_CANNOT_OPEN_PRESENTS "cannot-open-presents"
#define TRAIT_PRESENT_VISION "present-vision"
#define TRAIT_DISK_VERIFIER "disk-verifier"
#define TRAIT_NOMOBSWAP "no-mob-swap"
/// Can examine IDs to see if they are roundstart.
#define TRAIT_ID_APPRAISER "id_appraiser"
/// Gives us turf, mob and object vision through walls
#define TRAIT_XRAY_VISION "xray_vision"
/// Gives us mob vision through walls and slight night vision
#define TRAIT_THERMAL_VISION "thermal_vision"
/// Gives us turf vision through walls and slight night vision
#define TRAIT_MESON_VISION "meson_vision"
/// Gives us Night vision
#define TRAIT_TRUE_NIGHT_VISION "true_night_vision"
/// Gives us minor night vision
#define TRAIT_MINOR_NIGHT_VISION "minor_night_vision"
/// Negates our gravity, letting us move normally on floors in 0-g
#define TRAIT_NEGATES_GRAVITY "negates_gravity"
/// We are ignoring gravity
#define TRAIT_IGNORING_GRAVITY "ignores_gravity"
/// We have some form of forced gravity acting on us
#define TRAIT_FORCED_GRAVITY "forced_gravity"
/// Makes whispers clearly heard from seven tiles away, the full hearing range
#define TRAIT_GOOD_HEARING "good_hearing"
/// Allows you to hear speech through walls
#define TRAIT_XRAY_HEARING "xray_hearing"

/// This mob can not enter or move on a shuttle
#define TRAIT_BLOCK_SHUTTLE_MOVEMENT "block_shuttle_movement"

/// Lets us scan reagents
#define TRAIT_REAGENT_SCANNER "reagent_scanner"
/// Lets us scan machine parts and tech unlocks
#define TRAIT_RESEARCH_SCANNER "research_scanner"
/// Can weave webs into cloth
#define TRAIT_WEB_WEAVER "web_weaver"
/// Can navigate the web without getting stuck
#define TRAIT_WEB_SURFER "web_surfer"
/// A web is being spun on this turf presently
#define TRAIT_SPINNING_WEB_TURF "spinning_web_turf"
#define TRAIT_ABDUCTOR_TRAINING "abductor-training"
#define TRAIT_ABDUCTOR_SCIENTIST_TRAINING "abductor-scientist-training"
#define TRAIT_SURGEON "surgeon"
#define TRAIT_STRONG_GRABBER "strong_grabber"
#define TRAIT_SOOTHED_THROAT "soothed-throat"
#define TRAIT_BOOZE_SLIDER "booze-slider"
/// We place people into a fireman carry quicker than standard
#define TRAIT_QUICK_CARRY "quick-carry"
/// We place people into a fireman carry especially quickly compared to quick_carry
#define TRAIT_QUICKER_CARRY "quicker-carry"
#define TRAIT_QUICK_BUILD "quick-build"
/// We can handle 'dangerous' plants in botany safely
#define TRAIT_PLANT_SAFE "plant_safe"
/// Prevents the overlay from nearsighted
#define TRAIT_NEARSIGHTED_CORRECTED "fixes_nearsighted"
#define TRAIT_UNINTELLIGIBLE_SPEECH "unintelligible-speech"
#define TRAIT_UNSTABLE "unstable"
#define TRAIT_OIL_FRIED "oil_fried"
#define TRAIT_MEDICAL_HUD "med_hud"
#define TRAIT_SECURITY_HUD "sec_hud"
/// for something granting you a diagnostic hud
#define TRAIT_DIAGNOSTIC_HUD "diag_hud"
#define TRAIT_BOT_PATH_HUD "bot_path_hud"
#define TRAIT_PASSTABLE "passtable"
/// Lets you fly through windows
#define TRAIT_PASSWINDOW "passwindow"
/// Makes you immune to flashes
#define TRAIT_NOFLASH "noflash"
/// prevents xeno huggies implanting skeletons
#define TRAIT_XENO_IMMUNE "xeno_immune"
/// Allows the species to equip items that normally require a jumpsuit without having one equipped. Used by golems.
#define TRAIT_NO_JUMPSUIT "no_jumpsuit"
#define TRAIT_NAIVE "naive"
/// always detect storms on icebox
#define TRAIT_DETECT_STORM "detect_storm"
#define TRAIT_PRIMITIVE "primitive"
#define TRAIT_GUNFLIP "gunflip"
/// eignore blindness or blurriness or nearsightedness
#define TRAIT_SIGHT_BYPASS "perfect_sight"
/// ignore traumas that make you 'hallucinate' something
#define TRAIT_PERCEPTUAL_TRAUMA_BYPASS "trauma_bypass"
/// mob is immune to hallucinations
#define TRAIT_HALLUCINATION_IMMUNE "hallucination_immune"
/// Increases chance of getting special traumas, makes them harder to cure
#define TRAIT_SPECIAL_TRAUMA_BOOST "special_trauma_boost"
#define TRAIT_SPACEWALK "spacewalk"
/// Sanity trait to keep track of when we're in hyperspace and add the appropriate element if we weren't
#define TRAIT_HYPERSPACED "hyperspaced"
///Gives the movable free hyperspace movement without being pulled during shuttle transit
#define TRAIT_FREE_HYPERSPACE_MOVEMENT "free_hyperspace_movement"
///Lets the movable move freely in the soft-cordon area of transit space, which would otherwise teleport them away just before they got to see the true cordon
#define TRAIT_FREE_HYPERSPACE_SOFTCORDON_MOVEMENT "free_hyperspace_softcordon_movement"
///Deletes the object upon being dumped into space, usually from exiting hyperspace. Useful if you're spawning in a lot of stuff for hyperspace events that don't need to flood the entire game
#define TRAIT_DEL_ON_SPACE_DUMP "del_on_hyperspace_leave"
/// We can walk up or around cliffs, or at least we don't fall off of it
#define TRAIT_CLIFF_WALKER "cliff_walker"
/// This means the user is currently holding/wearing a "tactical camouflage" item (like a potted plant).
#define TRAIT_TACTICALLY_CAMOUFLAGED "tactically_camouflaged"
/// Gets double arcade prizes
#define TRAIT_GAMERGOD "gamer-god"
#define TRAIT_GIANT "giant"
#define TRAIT_DWARF "dwarf"
/// Makes you way too tall. Like just too much, dude, it's kind of creepy. Humanoid only.
#define TRAIT_TOO_TALL "too_tall"
/// makes your footsteps completely silent
#define TRAIT_SILENT_FOOTSTEPS "silent_footsteps"
/// hnnnnnnnggggg..... you're pretty good....
#define TRAIT_NICE_SHOT "nice_shot"
/// prevents the damage done by a brain tumor
#define TRAIT_TUMOR_SUPPRESSED "brain_tumor_suppressed"
/// Prevents hallucinations from the hallucination brain trauma (RDS)
#define TRAIT_RDS_SUPPRESSED "rds_suppressed"
/// Mobs that have this trait cannot be extinguished
#define TRAIT_NO_EXTINGUISH "no_extinguish"
/// Indicates if the mob is currently speaking with sign language
#define TRAIT_SIGN_LANG "sign_language"
/// Trait given to mobs to indicate that they can catch papers thrown at them midair without trying,
/// and make syndicate airplanes when folding paper up.
#define TRAIT_PAPER_MASTER "paper_master"
/// This mob is able to use sign language over the radio.
#define TRAIT_CAN_SIGN_ON_COMMS "can_sign_on_comms"
/// nobody can use martial arts on this mob
#define TRAIT_MARTIAL_ARTS_IMMUNE "martial_arts_immune"
/// Immune to being afflicted by time stop (spell)
#define TRAIT_TIME_STOP_IMMUNE "time_stop_immune"
/// Revenants draining you only get a very small benefit.
#define TRAIT_WEAK_SOUL "weak_soul"
/// This mob has no soul
#define TRAIT_NO_SOUL "no_soul"
/// Prevents mob from riding mobs when buckled onto something
#define TRAIT_CANT_RIDE "cant_ride"
/// Prevents a mob from being unbuckled, currently only used to prevent people from falling over on the tram
#define TRAIT_CANNOT_BE_UNBUCKLED "cannot_be_unbuckled"
/// from heparin and nitrous oxide, makes open bleeding wounds rapidly spill more blood
#define TRAIT_BLOODY_MESS "bloody_mess"
/// from coagulant reagents, this doesn't affect the bleeding itself but does affect the bleed warning messages
#define TRAIT_COAGULATING "coagulating"
/// From anti-convulsant medication against seizures.
#define TRAIT_ANTICONVULSANT "anticonvulsant"
/// From stimulant reagents, this affects whether the all-nighter lack of sleep penalty should be countered
#define TRAIT_STIMULATED "stimulated"
/// The holder of this trait has antennae or whatever that hurt a ton when noogied
#define TRAIT_ANTENNAE "antennae"
/// Blowing kisses actually does damage to the victim
#define TRAIT_KISS_OF_DEATH "kiss_of_death"
/// Syndie kisses can apply burn damage
#define TRAIT_SYNDIE_KISS "syndie_kiss"
/// Used to activate french kissing
#define TRAIT_GARLIC_BREATH "kiss_of_garlic_death"
/// Addictions don't tick down, basically they're permanently addicted
#define TRAIT_HOPELESSLY_ADDICTED "hopelessly_addicted"
/// This mob has a cult halo.
#define TRAIT_CULT_HALO "cult_halo"
/// Their eyes glow an unnatural red colour. Currently used to set special examine text on humans. Does not guarantee the mob's eyes are coloured red, nor that there is any visible glow on their character sprite.
#define TRAIT_UNNATURAL_RED_GLOWY_EYES "unnatural_red_glowy_eyes"
/// Their eyes are bloodshot. Currently used to set special examine text on humans. Examine text is overridden by TRAIT_UNNATURAL_RED_GLOWY_EYES.
#define TRAIT_BLOODSHOT_EYES "bloodshot_eyes"
/// This mob should never close UI even if it doesn't have a client
#define TRAIT_PRESERVE_UI_WITHOUT_CLIENT "preserve_ui_without_client"
/// This mob overrides certain SSlag_switch measures with this special trait
#define TRAIT_BYPASS_MEASURES "bypass_lagswitch_measures"
/// The user is sparring
#define TRAIT_SPARRING "sparring"
/// The user is currently challenging an elite mining mob. Prevents him from challenging another until he's either lost or won.
#define TRAIT_ELITE_CHALLENGER "elite_challenger"
/// For living mobs. It signals that the mob shouldn't have their data written in an external json for persistence.
#define TRAIT_DONT_WRITE_MEMORY "dont_write_memory"
/// This mob can be painted with the spraycan
#define TRAIT_SPRAY_PAINTABLE "spray_paintable"
/// This atom can ignore the "is on a turf" check for simple AI datum attacks, allowing them to attack from bags or lockers as long as any other conditions are met
#define TRAIT_AI_BAGATTACK "bagattack"
/// This mobs bodyparts are invisible but still clickable.
#define TRAIT_INVISIBLE_MAN "invisible_man"
/// Don't draw external organs/species features like wings, horns, frills and stuff
#define TRAIT_HIDE_EXTERNAL_ORGANS "hide_external_organs"
///When people are floating from zero-grav or something, we can move around freely!
#define TRAIT_FREE_FLOAT_MOVEMENT "free_float_movement"
// You can stare into the abyss, but it does not stare back.
// You're immune to the hallucination effect of the supermatter, either
// through force of will, or equipment. Present on /mob or /datum/mind
#define TRAIT_MADNESS_IMMUNE "supermatter_madness_immune"
// You can stare into the abyss, and it turns pink.
// Being close enough to the supermatter makes it heal at higher temperatures
// and emit less heat. Present on /mob or /datum/mind
#define TRAIT_SUPERMATTER_SOOTHER "supermatter_soother"
/// Mob has fov applied to it
#define TRAIT_FOV_APPLIED "fov_applied"
/// Mob is using the scope component
#define TRAIT_USER_SCOPED "user_scoped"
/// Mob is unable to feel pain
#define TRAIT_ANALGESIA "analgesia"
/// Mob does not get a damage overlay from brute/burn
#define TRAIT_NO_DAMAGE_OVERLAY "no_damage_overlay"
/// Mob has a scar on their left/right eye
#define TRAIT_RIGHT_EYE_SCAR "right_eye_scar"
#define TRAIT_LEFT_EYE_SCAR "left_eye_scar"

/// Trait added when a revenant is visible.
#define TRAIT_REVENANT_REVEALED "revenant_revealed"
/// Trait added when a revenant has been inhibited (typically by the bane of a holy weapon)
#define TRAIT_REVENANT_INHIBITED "revenant_inhibited"

/// Trait which prevents you from becoming overweight
#define TRAIT_NOFAT "cant_get_fat"

/// Trait which allows you to eat rocks
#define TRAIT_ROCK_EATER "rock_eater"
/// Trait which allows you to gain bonuses from consuming rocks
#define TRAIT_ROCK_METAMORPHIC "rock_metamorphic"

/// `do_teleport` will not allow this atom to teleport
#define TRAIT_NO_TELEPORT "no-teleport"
/// This atom is a secluded location, which is counted as out of bounds.
/// Anything that enters this atom's contents should react if it wants to stay in bounds.
#define TRAIT_SECLUDED_LOCATION "secluded_loc"

/// Trait used by fugu glands to avoid double buffing
#define TRAIT_FUGU_GLANDED "fugu_glanded"

/// Trait that tracks if something has been renamed. Typically holds a REF() to the object itself (AKA src) for wide addition/removal.
#define TRAIT_WAS_RENAMED "was_renamed"

/// When someone with this trait fires a ranged weapon, their fire delays and click cooldowns are halved
#define TRAIT_DOUBLE_TAP "double_tap"

/// Trait applied to [/datum/mind] to stop someone from using the cursed hot springs to polymorph more than once.
#define TRAIT_HOT_SPRING_CURSED "hot_spring_cursed"

/// If something has been engraved/cannot be engraved
#define TRAIT_NOT_ENGRAVABLE "not_engravable"

/// Whether or not orbiting is blocked or not
#define TRAIT_ORBITING_FORBIDDEN "orbiting_forbidden"
/// Trait applied to mob/living to mark that spiders should not gain further enriched eggs from eating their corpse.
#define TRAIT_SPIDER_CONSUMED "spider_consumed"
/// Whether we're sneaking, from the creature sneak ability.
#define TRAIT_SNEAK "sneaking_creatures"

/// Item still allows you to examine items while blind and actively held.
#define TRAIT_BLIND_TOOL "blind_tool"

/// The person with this trait always appears as 'unknown'.
#define TRAIT_UNKNOWN "unknown"

/// If the mob has this trait and die, their bomb implant doesn't detonate automatically. It must be consciously activated.
#define TRAIT_PREVENT_IMPLANT_AUTO_EXPLOSION "prevent_implant_auto_explosion"

/// If applied to a mob, nearby dogs will have a small chance to nonharmfully harass said mob
#define TRAIT_HATED_BY_DOGS "hated_by_dogs"
/// Mobs with this trait will not be immobilized when held up
#define TRAIT_NOFEAR_HOLDUPS "no_fear_holdup"
/// Mob has gotten an armor buff from adamantine extract
#define TRAIT_ADAMANTINE_EXTRACT_ARMOR "adamantine_extract_armor"
/// Mobs with this trait won't be able to dual wield guns.
#define TRAIT_NO_GUN_AKIMBO "no_gun_akimbo"
/// Mobs with this trait cannot be hit by projectiles, meaning the projectiles will just go through.
#define TRAIT_UNHITTABLE_BY_PROJECTILES "unhittable_by_projectiles"

/// Mobs with this trait do care about a few grisly things, such as digging up graves. They also really do not like bringing people back to life or tending wounds, but love autopsies and amputations.
#define TRAIT_MORBID "morbid"

/// Whether or not the user is in a MODlink call, prevents making more calls
#define TRAIT_IN_CALL "in_call"

/// Does the mob ignore elevation? (e.g. xeno larvas on hiding)
#define TRAIT_IGNORE_ELEVATION "ignore_elevation"

/// Prevents you from twohanding weapons.
#define TRAIT_NO_TWOHANDING "no_twohanding"

/// Improves boxing damage against boxers and athletics experience gain
#define TRAIT_STRENGTH "strength"

/// Increases the duration of having exercised
#define TRAIT_STIMMED "stimmed"

/// Indicates that the target is able to be boxed at a boxer's full power.
#define TRAIT_BOXING_READY "boxing_ready"

/// Halves the time of tying a tie.
#define TRAIT_FAST_TYING "fast_tying"

/// Sells for more money on the pirate bounty pad.
#define TRAIT_HIGH_VALUE_RANSOM "high_value_ransom"

/// Makes the user handcuff others faster
#define TRAIT_FAST_CUFFING "fast_cuffing"

///Given by /obj/item/virgin_mary, mobs that used this can no longer use it again ever
#define TRAIT_MAFIAINITIATE "mafiainitiate"

/// Our mob has the mind reading genetic mutation.
#define TRAIT_MIND_READER "mind reader"

///Makes the player appear as their respective job in Binary Talk rather than being a 'Default Cyborg'.
#define TRAIT_DISPLAY_JOB_IN_BINARY "display job in binary"

/// Trait that determines vulnerability to being stunned from a shove
#define TRAIT_DAZED "dazed"

/// Trait that determines whether our mob gains more strength from drinking during a fist fight
#define TRAIT_DRUNKEN_BRAWLER "drunken brawler"

// METABOLISMS
// Various jobs on the station have historically had better reactions
// to various drinks and foodstuffs. Security liking donuts is a classic
// example. Through years of training/abuse, their livers have taken
// a liking to those substances. Steal a sec officer's liver, eat donuts good.

// These traits are applied to /obj/item/organ/liver
#define TRAIT_LAW_ENFORCEMENT_METABOLISM "law_enforcement_metabolism"
#define TRAIT_CULINARY_METABOLISM "culinary_metabolism"
#define TRAIT_COMEDY_METABOLISM "comedy_metabolism"
#define TRAIT_MEDICAL_METABOLISM "medical_metabolism"
#define TRAIT_ENGINEER_METABOLISM "engineer_metabolism"
#define TRAIT_ROYAL_METABOLISM "royal_metabolism"
#define TRAIT_PRETENDER_ROYAL_METABOLISM "pretender_royal_metabolism"
#define TRAIT_BALLMER_SCIENTIST "ballmer_scientist"
#define TRAIT_MAINTENANCE_METABOLISM "maintenance_metabolism"
#define TRAIT_CORONER_METABOLISM "coroner_metabolism"
#define TRAIT_HUMAN_AI_METABOLISM "human_ai_metabolism"

//LUNG TRAITS
/// Lungs always breathe normally when in vacuum/space.
#define TRAIT_SPACEBREATHING "spacebreathing"

/// This mob can strip other mobs.
#define TRAIT_CAN_STRIP "can_strip"
/// Can use the nuclear device's UI, regardless of a lack of hands
#define TRAIT_CAN_USE_NUKE "can_use_nuke"

// If present on a mob or mobmind, allows them to "suplex" an immovable rod
// turning it into a glorified potted plant, and giving them an
// achievement. Can also be used on rod-form wizards.
// Normally only present in the mind of a Research Director.
#define TRAIT_ROD_SUPLEX "rod_suplex"
/// The mob has an active mime vow of silence, and thus is unable to speak and has other mime things going on
#define TRAIT_MIMING "miming"

/// This mob is phased out of reality from magic, either a jaunt or rod form
#define TRAIT_MAGICALLY_PHASED "magically_phased"

//SKILLS
#define TRAIT_UNDERWATER_BASKETWEAVING_KNOWLEDGE "underwater_basketweaving"
#define TRAIT_WINE_TASTER "wine_taster"
#define TRAIT_BONSAI "bonsai"
#define TRAIT_LIGHTBULB_REMOVER "lightbulb_remover"
#define TRAIT_KNOW_ROBO_WIRES "know_robo_wires"
#define TRAIT_KNOW_ENGI_WIRES "know_engi_wires"
#define TRAIT_ENTRAILS_READER "entrails_reader"
#define TRAIT_SABRAGE_PRO "sabrage_pro"
/// this skillchip trait lets you wash brains in washing machines to heal them
#define TRAIT_BRAINWASHING "brainwashing"
/// Allows chef's to chefs kiss their food, to make them with love
#define TRAIT_CHEF_KISS "chefs_kiss"
/// Allows clowns to bend balloons into animals
#define TRAIT_BALLOON_SUTRA "balloon_sutra"
/// Allows detectives to identify chemicals by taste
#define TRAIT_DETECTIVES_TASTE "detectives_taste"

///Movement type traits for movables. See elements/movetype_handler.dm
#define TRAIT_MOVE_GROUND "move_ground"
#define TRAIT_MOVE_FLYING "move_flying"
#define TRAIT_MOVE_VENTCRAWLING "move_ventcrawling"
#define TRAIT_MOVE_FLOATING "move_floating"
#define TRAIT_MOVE_PHASING "move_phasing"
#define TRAIT_MOVE_UPSIDE_DOWN "move_upside_down"
/// Disables the floating animation. See above.
#define TRAIT_NO_FLOATING_ANIM "no-floating-animation"

/// Cannot be turned into a funny skeleton by the plasma river
#define TRAIT_NO_PLASMA_TRANSFORM "no_plasma_transform"

/// Weather immunities, also protect mobs inside them.
#define TRAIT_LAVA_IMMUNE "lava_immune" //Used by lava turfs and The Floor Is Lava.
#define TRAIT_ASHSTORM_IMMUNE "ashstorm_immune"
#define TRAIT_SNOWSTORM_IMMUNE "snowstorm_immune"
#define TRAIT_RADSTORM_IMMUNE "radstorm_immune"
#define TRAIT_WEATHER_IMMUNE "weather_immune" //Immune to ALL weather effects.

/// Cannot be grabbed by goliath tentacles
#define TRAIT_TENTACLE_IMMUNE "tentacle_immune"
/// Currently under the effect of overwatch
#define TRAIT_OVERWATCHED "watcher_overwatched"
/// Cannot be targeted by watcher overwatch
#define TRAIT_OVERWATCH_IMMUNE "overwatch_immune"

//non-mob traits
/// Used for limb-based paralysis, where replacing the limb will fix it.
#define TRAIT_PARALYSIS "paralysis"
/// Used for limbs.
#define TRAIT_DISABLED_BY_WOUND "disabled-by-wound"
/// This movable atom has the explosive block element
#define TRAIT_BLOCKING_EXPLOSIVES "blocking_explosives"
/// This object has been slathered with a speed potion
#define TRAIT_SPEED_POTIONED "speed_potioned"

///This mob is currently blocking a projectile.
#define TRAIT_BLOCKING_PROJECTILES "blocking_projectiles"
///Lava will be safe to cross while it has this trait.
#define TRAIT_LAVA_STOPPED "lava_stopped"
///Chasms will be safe to cross while they've this trait.
#define TRAIT_CHASM_STOPPED "chasm_stopped"
///Chasms will be safe to cross if there is something with this trait on it
#define TRAIT_CHASM_STOPPER "chasm_stopper"
///The effects of the immerse element will be halted while this trait is present.
#define TRAIT_IMMERSE_STOPPED "immerse_stopped"
/// The effects of hyperspace drift are blocked when the tile has this trait
#define TRAIT_HYPERSPACE_STOPPED "hyperspace_stopped"

///Turf slowdown will be ignored when this trait is added to a turf.
#define TRAIT_TURF_IGNORE_SLOWDOWN "turf_ignore_slowdown"
///Mobs won't slip on a wet turf while it has this trait
#define TRAIT_TURF_IGNORE_SLIPPERY "turf_ignore_slippery"

///failsafe for whether an item with the beauty element is influencing the beauty of the area of not.
#define TRAIT_BEAUTY_APPLIED "beauty_applied"

/// Mobs with this trait can't send the mining shuttle console when used outside the station itself
#define TRAIT_FORBID_MINING_SHUTTLE_CONSOLE_OUTSIDE_STATION "forbid_mining_shuttle_console_outside_station"

//important_recursive_contents traits
/*
 * Used for movables that need to be updated, via COMSIG_ENTER_AREA and COMSIG_EXIT_AREA, when transitioning areas.
 * Use [/atom/movable/proc/become_area_sensitive(trait_source)] to properly enable it. How you remove it isn't as important.
 */
#define TRAIT_AREA_SENSITIVE "area-sensitive"
///every hearing sensitive atom has this trait
#define TRAIT_HEARING_SENSITIVE "hearing_sensitive"
///every object that is currently the active storage of some client mob has this trait
#define TRAIT_ACTIVE_STORAGE "active_storage"

/// Climbable trait, given and taken by the climbable element when added or removed. Exists to be easily checked via HAS_TRAIT().
#define TRAIT_CLIMBABLE "trait_climbable"

/// Used by the honkspam element to avoid spamming the sound. Amusing considering its name.
#define TRAIT_HONKSPAMMING "trait_honkspamming"
/// Required by the waddling element since there are multiple sources of it.
#define TRAIT_WADDLING "trait_waddling"
/// Mobs with trait will still waddle even when lying on the floor and make a different footstep sound when doing so.
#define TRAIT_FLOPPING "trait_flopping"
/// Required by the on_hit_effect element, which is in turn added by other elements.
#define TRAIT_ON_HIT_EFFECT "trait_on_hit_effect"

///Used for managing KEEP_TOGETHER in [/atom/var/appearance_flags]
#define TRAIT_KEEP_TOGETHER "keep-together"

// cargo traits
///If the item will block the cargo shuttle from flying to centcom
#define TRAIT_BANNED_FROM_CARGO_SHUTTLE "banned_from_cargo_shuttle"
///If the crate's contents are immune to the missing item manifest error
#define TRAIT_NO_MISSING_ITEM_ERROR "no_missing_item_error"
///If the crate is immune to the wrong content in manifest error
#define TRAIT_NO_MANIFEST_CONTENTS_ERROR "no_manifest_contents_error"

///SSeconomy trait, if the market is crashing and people can't withdraw credits from ID cards.
#define TRAIT_MARKET_CRASHING "market_crashing"

// item traits
#define TRAIT_NODROP "nodrop"
/// cannot be inserted in a storage.
#define TRAIT_NO_STORAGE_INSERT "no_storage_insert"
/// Visible on t-ray scanners if the atom/var/level == 1
#define TRAIT_T_RAY_VISIBLE "t-ray-visible"
/// If this item's been fried
#define TRAIT_FOOD_FRIED "food_fried"
/// If this item's been bbq grilled
#define TRAIT_FOOD_BBQ_GRILLED "food_bbq_grilled"
/// This is a silver slime created item
#define TRAIT_FOOD_SILVER "food_silver"
/// If this item's been made by a chef instead of being map-spawned or admin-spawned or such
#define TRAIT_FOOD_CHEF_MADE "food_made_by_chef"
/// This atom has a quality_food_ingredient element attached
#define TRAIT_QUALITY_FOOD_INGREDIENT "quality_food_ingredient"
/// The items needs two hands to be carried
#define TRAIT_NEEDS_TWO_HANDS "needstwohands"
/// Can't be catched when thrown
#define TRAIT_UNCATCHABLE "uncatchable"
/// You won't catch duds while fishing with this rod.
#define TRAIT_ROD_REMOVE_FISHING_DUD "rod_remove_fishing_dud"
/// This rod ignores environmental conditions for fishing (like low light for nocturnal fish)
#define TRAIT_ROD_IGNORE_ENVIRONMENT "rod_ignore_environment"
/// This rod attracts fish with the shiny lover fish trait
#define TRAIT_ROD_ATTRACT_SHINY_LOVERS "rod_attract_shiny_lovers"
/// This rod can be used to fish on lava
#define TRAIT_ROD_LAVA_USABLE "rod_lava_usable"
/// This rod was infused by a heretic, making it awesome and improving influence gain
#define TRAIT_ROD_MANSUS_INFUSED "rod_infused"
/// Stuff that can go inside fish cases and aquariums
#define TRAIT_AQUARIUM_CONTENT "aquarium_content"
/// If the item can be used as a bit.
#define TRAIT_FISHING_BAIT "fishing_bait"
/// This bait will kill any fish that doesn't have it on its favorite_bait list
#define TRAIT_POISONOUS_BAIT "poisonous_bait"
/// The quality of the bait. It influences odds of catching fish
#define TRAIT_BASIC_QUALITY_BAIT "baic_quality_bait"
#define TRAIT_GOOD_QUALITY_BAIT "good_quality_bait"
#define TRAIT_GREAT_QUALITY_BAIT "great_quality_bait"
/// Baits with this trait will ignore bait preferences and related fish traits.
#define TRAIT_OMNI_BAIT "omni_bait"
/// The bait won't be consumed when used
#define TRAIT_BAIT_UNCONSUMABLE "bait_unconsumable"
/**
 * This bait won't apply TRAIT_ROD_REMOVE_FISHING_DUD to the rod it's attached on,
 * instead, it'll allow the fishing dud to be there unless there's at least one fish that likes the bait
 */
#define TRAIT_BAIT_ALLOW_FISHING_DUD "bait_dont_affect_fishing_dud"
/**
 * This location has the aquarium component. Not much different than a GetComponent()
 * disguised as an 'is_x' macro, but I don't have to hide anything here.
 * I just don't want a confusing 'is_aquarium(A)' macro which people think it's interchangable with
 * an 'istype(A, /obj/structure/aquarium)' when it's the component what truly matters.
 */
#define TRAIT_IS_AQUARIUM "is_aquarium"
/// A location (probably aquarium) that amplifies the zaps of electricity-generating fish.
#define TRAIT_BIOELECTRIC_GENERATOR "bioelectric_generator"
/// A location (likely aquarium) that doesn't allow fish to growth and reproduce
#define TRAIT_STOP_FISH_REPRODUCTION_AND_GROWTH "stop_fish_reproduction_and_growth"
/// This is an aquarium with an open panel
#define TRAIT_AQUARIUM_PANEL_OPEN "aquarium_panel_open"
/// For locations that prevent fish flopping animation, namely aquariums
#define TRAIT_STOP_FISH_FLOPPING "stop_fish_flopping"
/// Plants that were mutated as a result of passive instability, not a mutation threshold.
#define TRAIT_PLANT_WILDMUTATE "wildmutation"
/// If you hit an APC with exposed internals with this item it will try to shock you
#define TRAIT_APC_SHOCKING "apc_shocking"
/// Properly wielded two handed item
#define TRAIT_WIELDED "wielded"
/// A transforming item that is actively extended / transformed
#define TRAIT_TRANSFORM_ACTIVE "active_transform"
/// Buckling yourself to objects with this trait won't immobilize you
#define TRAIT_NO_IMMOBILIZE "no_immobilize"
/// Prevents stripping this equipment
#define TRAIT_NO_STRIP "no_strip"
/// Disallows this item from being pricetagged with a barcode
#define TRAIT_NO_BARCODES "no_barcode"
/// Allows heretics to cast their spells.
#define TRAIT_ALLOW_HERETIC_CASTING "allow_heretic_casting"
/// Designates a heart as a living heart for a heretic.
#define TRAIT_LIVING_HEART "living_heart"
/// Prevents the same person from being chosen multiple times for kidnapping objective
#define TRAIT_HAS_BEEN_KIDNAPPED "has_been_kidnapped"
/// An item still plays its hitsound even if it has 0 force, instead of the tap
#define TRAIT_CUSTOM_TAP_SOUND "no_tap_sound"
/// Makes the feedback message when someone else is putting this item on you more noticeable
#define TRAIT_DANGEROUS_OBJECT "dangerous_object"
/// determines whether or not objects are haunted and teleport/attack randomly
#define TRAIT_HAUNTED "haunted"
/// An item that, if it has contents, will ignore its contents when scanning for contraband.
#define TRAIT_CONTRABAND_BLOCKER "contraband_blocker"
/// For edible items that cannot be composted inside hydro trays
#define TRAIT_UNCOMPOSTABLE "uncompostable"
/// Items with this trait will not have their worn icon overlayed.
#define TRAIT_NO_WORN_ICON "no_worn_icon"
/// Items with this trait will not appear when examined.
#define TRAIT_EXAMINE_SKIP "examine_skip"

//quirk traits
#define TRAIT_ALCOHOL_TOLERANCE "alcohol_tolerance"
#define TRAIT_ANOSMIA "anosmia"
#define TRAIT_HEAVY_DRINKER "heavy_drinker"
#define TRAIT_AGEUSIA "ageusia"
#define TRAIT_HEAVY_SLEEPER "heavy_sleeper"
#define TRAIT_NIGHT_VISION "night_vision"
#define TRAIT_LIGHT_STEP "light_step"
#define TRAIT_SPIRITUAL "spiritual"
#define TRAIT_CLOWN_ENJOYER "clown_enjoyer"
#define TRAIT_MIME_FAN "mime_fan"
#define TRAIT_VORACIOUS "voracious"
#define TRAIT_SELF_AWARE "self_aware"
#define TRAIT_FREERUNNING "freerunning"
#define TRAIT_SKITTISH "skittish"
#define TRAIT_PROSOPAGNOSIA "prosopagnosia"
#define TRAIT_TAGGER "tagger"
#define TRAIT_PHOTOGRAPHER "photographer"
#define TRAIT_MUSICIAN "musician"
#define TRAIT_LIGHT_DRINKER "light_drinker"
#define TRAIT_EMPATH "empath"
#define TRAIT_EVIL "evil"
#define TRAIT_FRIENDLY "friendly"
#define TRAIT_GRABWEAKNESS "grab_weakness"
#define TRAIT_GRABRESISTANCE "grab_resistance"
#define TRAIT_SNOB "snob"
#define TRAIT_BALD "bald"
#define TRAIT_SHAVED "shaved"
#define TRAIT_BADTOUCH "bad_touch"
#define TRAIT_EXTROVERT "extrovert"
#define TRAIT_INTROVERT "introvert"
#define TRAIT_ANXIOUS "anxious"
#define TRAIT_SMOKER "smoker"
#define TRAIT_POSTERBOY "poster_boy"
#define TRAIT_THROWINGARM "throwing_arm"
#define TRAIT_SETTLER "settler"
#define TRAIT_STRONG_STOMACH "strong_stomach"
#define TRAIT_VEGETARIAN "trait_vegetarian"

/// This mob always lands on their feet when they fall, for better or for worse.
#define TRAIT_CATLIKE_GRACE "catlike_grace"

///if the atom has a sticker attached to it
#define TRAIT_STICKERED "stickered"

// Debug traits
/// This object has light debugging tools attached to it
#define TRAIT_LIGHTING_DEBUGGED "lighting_debugged"
/// This object has sound debugging tools attached to it
#define TRAIT_SOUND_DEBUGGED "sound_debugged"

/// Gives you the Shifty Eyes quirk, rarely making people who examine you think you examined them back even when you didn't
#define TRAIT_SHIFTY_EYES "shifty_eyes"

///Trait for the gamer quirk.
#define TRAIT_GAMER "gamer"

///Trait for dryable items
#define TRAIT_DRYABLE "trait_dryable"
///Trait for dried items
#define TRAIT_DRIED "trait_dried"
/// Trait for customizable reagent holder
#define TRAIT_CUSTOMIZABLE_REAGENT_HOLDER "customizable_reagent_holder"
/// Trait for allowing an item that isn't food into the customizable reagent holder
#define TRAIT_ODD_CUSTOMIZABLE_FOOD_INGREDIENT "odd_customizable_food_ingredient"

/// Used to prevent multiple floating blades from triggering over the same target
#define TRAIT_BEING_BLADE_SHIELDED "being_blade_shielded"

/// This mob doesn't count as looking at you if you can only act while unobserved
#define TRAIT_UNOBSERVANT "trait_unobservant"

/* Traits for ventcrawling.
 * Both give access to ventcrawling, but *_NUDE requires the user to be
 * wearing no clothes and holding no items. If both present, *_ALWAYS
 * takes precedence.
 */
#define TRAIT_VENTCRAWLER_ALWAYS "ventcrawler_always"
#define TRAIT_VENTCRAWLER_NUDE "ventcrawler_nude"

/// Trait put on [/mob/living/carbon/human]. If that mob has a crystal core, also known as an ethereal heart, it will not try to revive them if the mob dies.
#define TRAIT_CANNOT_CRYSTALIZE "cannot_crystalize"

///Trait applied to turfs when an atmos holosign is placed on them. It will stop firedoors from closing.
#define TRAIT_FIREDOOR_STOP "firedoor_stop"

///Trait applied to turf blocked by a containment field
#define TRAIT_CONTAINMENT_FIELD "containment_field"

/// Trait applied when the MMI component is added to an [/obj/item/integrated_circuit]
#define TRAIT_COMPONENT_MMI "component_mmi"

/// Trait applied when an integrated circuit/module becomes undupable
#define TRAIT_CIRCUIT_UNDUPABLE "circuit_undupable"

/// Trait applied when an integrated circuit opens a UI on a player (see list pick component)
#define TRAIT_CIRCUIT_UI_OPEN "circuit_ui_open"

/// PDA/ModPC Traits. This one makes PDAs explode if the user opens the messages menu
#define TRAIT_PDA_MESSAGE_MENU_RIGGED "pda_message_menu_rigged"
/// This one denotes a PDA has received a rigged message and will explode when the user tries to reply to a rigged PDA message
#define TRAIT_PDA_CAN_EXPLODE "pda_can_explode"
///The download speeds of programs from the dowloader is halved.
#define TRAIT_MODPC_HALVED_DOWNLOAD_SPEED "modpc_halved_download_speed"
///Dictates whether a user (source) is interacting with the frame of a stationary modular computer or the pc inside it. Needed for circuits I guess.
#define TRAIT_MODPC_INTERACTING_WITH_FRAME "modpc_interacting_with_frame"

/// If present on a [/mob/living/carbon], will make them appear to have a medium level disease on health HUDs.
#define TRAIT_DISEASELIKE_SEVERITY_MEDIUM "diseaselike_severity_medium"

/// trait denoting someone will crawl faster in soft crit
#define TRAIT_TENACIOUS "tenacious"

/// trait denoting someone will sometimes recover out of crit
#define TRAIT_UNBREAKABLE "unbreakable"

/// trait that prevents AI controllers from planning detached from ai_status to prevent weird state stuff.
#define TRAIT_AI_PAUSED "TRAIT_AI_PAUSED"

/// this is used to bypass tongue language restrictions but not tongue disabilities
#define TRAIT_TOWER_OF_BABEL "tower_of_babel"

/// This target has recently been shot by a marksman coin and is very briefly immune to being hit by one again to prevent recursion
#define TRAIT_RECENTLY_COINED "recently_coined"

/// Receives echolocation images.
#define TRAIT_ECHOLOCATION_RECEIVER "echolocation_receiver"
/// Echolocation has a higher range.
#define TRAIT_ECHOLOCATION_EXTRA_RANGE "echolocation_extra_range"

/// Trait given to a living mob and any observer mobs that stem from them if they suicide.
/// For clarity, this trait should always be associated/tied to a reference to the mob that suicided- not anything else.
#define TRAIT_SUICIDED "committed_suicide"

/// Trait given to a living mob to prevent wizards from making it immortal
#define TRAIT_PERMANENTLY_MORTAL "permanently_mortal"

///Trait given to a mob with a ckey currently in a temporary body, allowing people to know someone will re-enter the round later.
#define TRAIT_MIND_TEMPORARILY_GONE "temporarily_gone"

/// Mobs with this trait will show up as soulless if their brain is missing even if their ghost can reenter the corpse
#define TRAIT_FAKE_SOULLESS "fake_soulless"

/// Similar trait given to temporary bodies inhabited by players
#define TRAIT_TEMPORARY_BODY "temporary_body"

/// Trait given to objects with the wallmounted component
#define TRAIT_WALLMOUNTED "wallmounted"

/// Trait given to mechs that can have orebox functionality on movement
#define TRAIT_OREBOX_FUNCTIONAL "orebox_functional"

///A trait for mechs that were created through the normal construction process, and not spawned by map or other effects.
#define TRAIT_MECHA_CREATED_NORMALLY "trait_mecha_created_normally"

/// Stops a movable from being removed from the mob it's in by the content_barfer component.
#define TRAIT_NOT_BARFABLE "not_barfable"

///fish traits
#define TRAIT_FISH_STASIS "fish_stasis"
#define TRAIT_FISH_FLOPPING "fish_flopping"
#define TRAIT_RESIST_PSYCHIC "resist_psychic"
#define TRAIT_RESIST_EMULSIFY "resist_emulsify"
#define TRAIT_FISH_SELF_REPRODUCE "fish_self_reproduce"
#define TRAIT_FISH_NO_MATING "fish_no_mating"
#define TRAIT_YUCKY_FISH "yucky_fish"
#define TRAIT_FISH_TOXIN_IMMUNE "fish_toxin_immune"
#define TRAIT_FISH_CROSSBREEDER "fish_crossbreeder"
#define TRAIT_FISH_AMPHIBIOUS "fish_amphibious"
///Trait needed for the lubefish evolution
#define TRAIT_FISH_FED_LUBE "fish_fed_lube"
#define TRAIT_FISH_WELL_COOKED "fish_well_cooked"
#define TRAIT_FISH_NO_HUNGER "fish_no_hunger"
///It comes from a fish case. Relevant for bounties so far.
#define TRAIT_FISH_FROM_CASE "fish_from_case"
///Fish will also occasionally fire weak tesla zaps
#define TRAIT_FISH_ELECTROGENESIS "fish_electrogenesis"
///Offsprings from this fish will never be of its same type (unless it's self-reproducing).
#define TRAIT_FISH_RECESSIVE "fish_recessive"
///This fish comes equipped with a stinger (increased damage and potentially venomous if also toxic)
#define TRAIT_FISH_STINGER "fish_stinger"
///This fish is currently on cooldown and cannot splash ink unto people's faces
#define TRAIT_FISH_INK_ON_COOLDOWN "fish_ink_on_cooldown"
///This fish requires two hands to carry even if smaller than FISH_SIZE_TWO_HANDS_REQUIRED, as long as it's bulky-sized.
#define TRAIT_FISH_SHOULD_TWOHANDED "fish_should_twohanded"
///This fish won't be killed when cooked.
#define TRAIT_FISH_SURVIVE_COOKING "fish_survive_cooking"
///This fish is healed by milk and hurt by bone hurting juice
#define TRAIT_FISH_MADE_OF_BONE "fish_made_of_bone"
/**
 * This fish has been fed teslium without the electrogenesis having trait.
 * Gives the electrogenesis, but at halved output, and it hurts the fish over time.
 */
#define TRAIT_FISH_ON_TESLIUM "fish_on_teslium"
/// This fish has been fed growth serum or something and will grow 5 times faster, up to 50% weight and size gain when fed.
#define TRAIT_FISH_QUICK_GROWTH "fish_quick_growth"
/// This fish has been fed mutagen or something. Evolutions will have more than twice the probability
#define TRAIT_FISH_MUTAGENIC "fish_mutagenic"

/// Trait given to angelic constructs to let them purge cult runes
#define TRAIT_ANGELIC "angelic"

/// Trait given to a dreaming carbon when they are currently doing dreaming stuff
#define TRAIT_DREAMING "currently_dreaming"

/// Whether bots will salute this mob.
#define TRAIT_COMMISSIONED "commissioned"

///generic atom traits
/// Trait from [/datum/element/rust]. Its rusty and should be applying a special overlay to denote this.
#define TRAIT_RUSTY "rust_trait"
/// Stops someone from splashing their reagent_container on an object with this trait
#define TRAIT_DO_NOT_SPLASH "do_not_splash"
/// Marks an atom when the cleaning of it is first started, so that the cleaning overlay doesn't get removed prematurely
#define TRAIT_CURRENTLY_CLEANING "currently_cleaning"
/// Objects with this trait are deleted if they fall into chasms, rather than entering abstract storage
#define TRAIT_CHASM_DESTROYED "chasm_destroyed"
/// Trait from being under the floor in some manner
#define TRAIT_UNDERFLOOR "underfloor"
/// If the movable shouldn't be reflected by mirrors.
#define TRAIT_NO_MIRROR_REFLECTION "no_mirror_reflection"
/// If this movable is currently treading in a turf with the immerse element.
#define TRAIT_IMMERSED "immersed"
/// From [/datum/element/elevation_core] for purpose of checking if the turf has the trait from an instance of the element
#define TRAIT_ELEVATED_TURF "elevated_turf"
/**
 * With this, the immerse overlay will give the atom its own submersion visual overlay
 * instead of one that's also shared with other movables, thus making editing its appearance possible.
 */
#define TRAIT_UNIQUE_IMMERSE "unique_immerse"

/// This item is currently under the control of telekinesis
#define TRAIT_TELEKINESIS_CONTROLLED "telekinesis_controlled"

/// changelings with this trait can no longer talk over the hivemind
#define TRAIT_CHANGELING_HIVEMIND_MUTE "ling_mute"
/// This guy is a hulk! (Bulky and green, lacks tact)
#define TRAIT_HULK "hulk"
/// Isn't attacked harmfully by blob structures
#define TRAIT_BLOB_ALLY "blob_ally"
/// Has the chuuni component
#define TRAIT_CHUUNIBYOU "chuunibyou"
/// Has splattercasting
#define TRAIT_SPLATTERCASTER "splattercaster"

///Traits given by station traits
#define STATION_TRAIT_ASSISTANT_GIMMICKS "station_trait_assistant_gimmicks"
#define STATION_TRAIT_BANANIUM_SHIPMENTS "station_trait_bananium_shipments"
#define STATION_TRAIT_BIGGER_PODS "station_trait_bigger_pods"
#define STATION_TRAIT_BIRTHDAY "station_trait_birthday"
#define STATION_TRAIT_BOTS_GLITCHED "station_trait_bot_glitch"
#define STATION_TRAIT_MACHINES_GLITCHED "station_trait_machine_glitch"
#define STATION_TRAIT_BRIGHT_DAY "station_trait_bright_day"
#define STATION_TRAIT_CARP_INFESTATION "station_trait_carp_infestation"
#define STATION_TRAIT_CYBERNETIC_REVOLUTION "station_trait_cybernetic_revolution"
#define STATION_TRAIT_ECONOMY_ALERTS "station_trait_economy_alerts"
#define STATION_TRAIT_EMPTY_MAINT "station_trait_empty_maint"
#define STATION_TRAIT_FILLED_MAINT "station_trait_filled_maint"
#define STATION_TRAIT_FORESTED "station_trait_forested"
#define STATION_TRAIT_HANGOVER "station_trait_hangover"
#define STATION_TRAIT_HUMAN_AI "station_trait_human_ai"
#define STATION_TRAIT_LATE_ARRIVALS "station_trait_late_arrivals"
#define STATION_TRAIT_LOANER_SHUTTLE "station_trait_loaner_shuttle"
#define STATION_TRAIT_MEDBOT_MANIA "station_trait_medbot_mania"
#define STATION_TRAIT_PDA_GLITCHED "station_trait_pda_glitched"
#define STATION_TRAIT_PREMIUM_INTERNALS "station_trait_premium_internals"
#define STATION_TRAIT_RADIOACTIVE_NEBULA "station_trait_radioactive_nebula"
#define STATION_TRAIT_RANDOM_ARRIVALS "station_trait_random_arrivals"
#define STATION_TRAIT_REVOLUTIONARY_TRASHING "station_trait_revolutionary_trashing"
#define STATION_TRAIT_SHUTTLE_SALE "station_trait_shuttle_sale"
#define STATION_TRAIT_SMALLER_PODS "station_trait_smaller_pods"
#define STATION_TRAIT_SPIDER_INFESTATION "station_trait_spider_infestation"
#define STATION_TRAIT_UNIQUE_AI "station_trait_unique_ai"
#define STATION_TRAIT_UNNATURAL_ATMOSPHERE "station_trait_unnatural_atmosphere"
#define STATION_TRAIT_SPIKED_DRINKS "station_trait_spiked_drinks"

///Deathmatch traits
#define TRAIT_DEATHMATCH_EXPLOSIVE_IMPLANTS "deathmath_explosive_implants"

/// This atom is currently spinning.
#define TRAIT_SPINNING "spinning"

/// This limb can't be torn open anymore
#define TRAIT_IMMUNE_TO_CRANIAL_FISSURE "immune_to_cranial_fissure"
/// Trait given if the mob has a cranial fissure.
#define TRAIT_HAS_CRANIAL_FISSURE "has_cranial_fissure"

/// Denotes that this id card was given via the job outfit, aka the first ID this player got.
#define TRAIT_JOB_FIRST_ID_CARD "job_first_id_card"
/// ID cards with this trait will attempt to forcibly occupy the front-facing ID card slot in wallets.
#define TRAIT_MAGNETIC_ID_CARD "magnetic_id_card"
/// ID cards with this trait have special appraisal text.
#define TRAIT_TASTEFULLY_THICK_ID_CARD "impressive_very_nice"

///The entity has Silicon 'access', so is either a silicon, has an access wand, or is an admin ghost AI.
///This is put on the mob, it is used on the client for Admins but they are the exception as they use `isAdminGhostAI`.
#define TRAIT_SILICON_ACCESS "silicon_access_trait"
///The entity has AI 'access', so is either an AI, has an access wand, or is an admin ghost AI. Used to block off regular Silicons from things.
///This is put on the mob, it is used on the client for Admins but they are the exception as they use `isAdminGhostAI`.
#define TRAIT_AI_ACCESS "ai_access_trait"

///Used by wearable_client_colour to determine whether the mob wants to have the colours of the screen affected by worn items (some still do regardless).
#define TRAIT_SEE_WORN_COLOURS "see_worn_colour"

// Radiation defines

/// Marks that this object is irradiated
#define TRAIT_IRRADIATED "iraddiated"

/// Immune to being irradiated
#define TRAIT_RADIMMUNE "rad_immunity"

/// Harmful radiation effects, the toxin damage and the burns, will not occur while this trait is active
#define TRAIT_HALT_RADIATION_EFFECTS "halt_radiation_effects"

/// This clothing protects the user from radiation.
/// This should not be used on clothing_traits, but should be applied to the clothing itself.
#define TRAIT_RADIATION_PROTECTED_CLOTHING "radiation_protected_clothing"

/// Whether or not this item will allow the radiation SS to go through standard
/// radiation processing as if this wasn't already irradiated.
/// Basically, without this, COMSIG_IN_RANGE_OF_IRRADIATION won't fire once the object is irradiated.
#define TRAIT_BYPASS_EARLY_IRRADIATED_CHECK "radiation_bypass_early_irradiated_check"

/// Simple trait that just holds if we came into growth from a specific mob type. Should hold a REF(src) to the type of mob that caused the growth, not anything else.
#define TRAIT_WAS_EVOLVED "was_evolved_from_the_mob_we_hold_a_textref_to"

// Traits to heal for

/// This mob heals from carp rifts.
#define TRAIT_HEALS_FROM_CARP_RIFTS "heals_from_carp_rifts"

/// This mob heals from cult pylons.
#define TRAIT_HEALS_FROM_CULT_PYLONS "heals_from_cult_pylons"

/// Ignore Crew monitor Z levels
#define TRAIT_MULTIZ_SUIT_SENSORS "multiz_suit_sensors"

/// Ignores body_parts_covered during the add_fingerprint() proc. Works both on the person and the item in the glove slot.
#define TRAIT_FINGERPRINT_PASSTHROUGH "fingerprint_passthrough"

/// this object has been frozen
#define TRAIT_FROZEN "frozen"

/// Makes a character be better/worse at tackling depending on their wing's status
#define TRAIT_TACKLING_WINGED_ATTACKER "tacking_winged_attacker"

/// Makes a character be frail and more likely to roll bad results if they hit a wall
#define TRAIT_TACKLING_FRAIL_ATTACKER "tackling_frail_attacker"

/// Makes a character be better/worse at defending against tackling depending on their tail's status
#define TRAIT_TACKLING_TAILED_DEFENDER "tackling_tailed_defender"

/// Is runechat for this atom/movable currently disabled, regardless of prefs or anything?
#define TRAIT_RUNECHAT_HIDDEN "runechat_hidden"

/// the object has a label applied
#define TRAIT_HAS_LABEL "labeled"

/// Trait given to a mob that is currently thinking (giving off the "thinking" icon), used in an IC context
#define TRAIT_THINKING_IN_CHARACTER "currently_thinking_IC"

///without a human having this trait, they speak as if they have no tongue.
#define TRAIT_SPEAKS_CLEARLY "speaks_clearly"

// specific sources for TRAIT_SPEAKS_CLEARLY

///Trait given by /datum/component/germ_sensitive
#define TRAIT_GERM_SENSITIVE "germ_sensitive"

/// This atom can have spells cast from it if a mob is within it
/// This means the "caster" of the spell is changed to the mob's loc
/// Note this doesn't mean all spells are guaranteed to work or the mob is guaranteed to cast
#define TRAIT_CASTABLE_LOC "castable_loc"

/// Needs above trait to work.
/// This trait makes it so that any cast spells will attempt to transfer to the location's location.
/// For example, a heretic inside the haunted blade's spells would emanate from the mob wielding the sword.
#define TRAIT_SPELLS_TRANSFER_TO_LOC "spells_transfer_to_loc"

///Trait given by /datum/element/relay_attacker
#define TRAIT_RELAYING_ATTACKER "relaying_attacker"

///Trait given to limb by /mob/living/basic/living_limb_flesh
#define TRAIT_IGNORED_BY_LIVING_FLESH "livingflesh_ignored"

///Trait given to organs that have been inside a living being previously
#define TRAIT_USED_ORGAN "used_organ"
///Trait given to organs that have started inside a being with a client
#define TRAIT_CLIENT_STARTING_ORGAN "client_starting_organ"

/// Trait given while using /datum/action/cooldown/mob_cooldown/wing_buffet
#define TRAIT_WING_BUFFET "wing_buffet"
/// Trait given while tired after using /datum/action/cooldown/mob_cooldown/wing_buffet
#define TRAIT_WING_BUFFET_TIRED "wing_buffet_tired"
/// Trait given to a dragon who fails to defend their rifts
#define TRAIT_RIFT_FAILURE "fail_dragon_loser"

///this trait hides most visible fluff and interactions of happiness, likely temporarily.
#define TRAIT_MOB_HIDE_HAPPINESS "mob_hide_happiness"
///trait determines if this mob can breed given by /datum/component/breeding
#define TRAIT_MOB_BREEDER "mob_breeder"
///trait given to mobs that are hatched
#define TRAIT_MOB_HATCHED "mob_hatched"
/// Trait given to mobs that we do not want to mindswap
#define TRAIT_NO_MINDSWAP "no_mindswap"
///trait given to food that can be baked by /datum/component/bakeable
#define TRAIT_BAKEABLE "bakeable"

/// Trait given to foam darts that have an insert in them
#define TRAIT_DART_HAS_INSERT "dart_has_insert"

/// Trait determines if this mob has examined an eldritch painting
#define TRAIT_ELDRITCH_PAINTING_EXAMINE "eldritch_painting_examine"

/// Trait used by the /datum/brain_trauma/severe/flesh_desire trauma to change their preferences of what they eat
#define TRAIT_FLESH_DESIRE "flesh_desire"

///Trait granted by janitor skillchip, allows communication with cleanbots
#define TRAIT_CLEANBOT_WHISPERER "cleanbot_whisperer"

///Trait granted by the miner skillchip, allows communication with minebots
#define TRAIT_ROCK_STONER "rock_stoner"

///Trait given by the regenerative shield component
#define TRAIT_REGEN_SHIELD "regen_shield"

/// Trait given when a mob is currently in invisimin mode
#define TRAIT_INVISIMIN "invisimin"

///Trait given when a mob has been tipped
#define TRAIT_MOB_TIPPED "mob_tipped"

/// Trait which self-identifies as an enemy of the law
#define TRAIT_ALWAYS_WANTED "always_wanted"

/// Trait given to mobs that have the basic eating element
#define TRAIT_MOB_EATER "mob_eater"
/// Trait which means whatever has this is dancing by a dance machine
#define TRAIT_DISCO_DANCER "disco_dancer"

/// Trait which allows mobs to instantly break down boulders.
#define TRAIT_INSTANTLY_PROCESSES_BOULDERS "instantly_processes_boulders"

/// Trait applied to objects and mobs that can attack a boulder and break it down. (See /obj/item/boulder/manual_process())
#define TRAIT_BOULDER_BREAKER "boulder_breaker"

/// Trait given to anything linked to, not necessarily allied to, the mansus
#define TRAIT_MANSUS_TOUCHED "mansus_touched"

/// Trait given to all participants in a heretic arena
#define TRAIT_ELDRITCH_ARENA_PARTICIPANT "eldritch_arena_participant"

// These traits are used in IS_X() as an OR, and is utilized for pseudoantags (such as deathmatch or domains) so they don't need to actually get antag status.
// To specifically and only get the antag datum, GET_X() exists now.
#define TRAIT_ACT_AS_CULTIST "act_as_cultist"
#define TRAIT_ACT_AS_HERETIC "act_as_heretic"

/// Appiled when wizard buy (/datum/spellbook_entry/perks/spalls_lottery) perk.
/// Give 50/25% chance not spend a spellbook charge on 1/2 cost spell.
/// Appiled it wizard can't refund any spells.
#define TRAIT_SPELLS_LOTTERY "spell_for_sale"

/// Trait given to mobs wearing the clown mask
#define TRAIT_PERCEIVED_AS_CLOWN "perceived_as_clown"
/// Does this item bypass ranged armor checks?
#define TRAIT_BYPASS_RANGED_ARMOR "bypass_ranged_armor"

/// Trait which means that this item is considered illegal contraband, and valid for the contraband bounty or when scanned by an nspect scanner.
#define TRAIT_CONTRABAND "illegal_contraband"

/// Traits given by settler, each with their own specific effects for cases where someone would have that trait, but not the other settler effects

#define TRAIT_EXPERT_FISHER "expert_fisher" // fishing is easier
#define TRAIT_ROUGHRIDER "roughrider" // you can improve speed on mounted animals with a good mood
#define TRAIT_STUBBY_BODY "stubby_body" // you have a stubby body that lessens your agility
#define TRAIT_BEAST_EMPATHY "beast_empathy" // you're good with animals, such as with taming them
#define TRAIT_STURDY_FRAME "sturdy_frame" // you suffer much lesser effects from equipment that slows you down

/// This item cannot be selected for or used by a theft objective (Spies, Traitors, etc.)
#define TRAIT_ITEM_OBJECTIVE_BLOCKED "item_objective_blocked"
/// This trait lets you attach limbs to any player without surgery.
#define TRAIT_EASY_ATTACH "easy_attach"

///Trait given to the birthday boy
#define TRAIT_BIRTHDAY_BOY "birthday_boy"

///Trait given to a turf that should not be allowed to be terraformed, such as turfs holding ore vents.
#define TRAIT_NO_TERRAFORM "no_terraform"

///Trait that prevents mobs from stopping by grabbing objects
#define TRAIT_NOGRAV_ALWAYS_DRIFT "nograv_always_drift"

///Mobs with these trait do not get italicized/quiet speech when speaking in low pressure
#define TRAIT_SPEECH_BOOSTER "speech_booster"

/// Given to a mob that can throw to make them not able to throw
#define TRAIT_NO_THROWING "no_throwing"

///Trait which allows mobs to parry mining mob projectiles
#define TRAIT_MINING_PARRYING "mining_parrying"

///Mob that can merge stacks in its contents
#define TRAIT_MOB_MERGE_STACKS "mob_merge_stacks"

//things that can pass through airlocks
#define TRAIT_FIREDOOR_OPENER "firedoor_opener"
///Trait which silences all chemical reactions in its container
#define TRAIT_SILENT_REACTIONS "silent_reactions"

///Trait given to mobs that can dig
#define TRAIT_MOB_CAN_DIG "mob_can_dig"

/// This atom has a tether attached to it
#define TRAIT_TETHER_ATTACHED "tether_attached"

/**
 *
 * This trait is used in some interactions very high in the interaction chain to allow
 * certain atoms to be skipped by said interactions if the user is in combat mode.
 *
 * Its primarily use case is for stuff like storage and tables, to allow things like emags to be bagged
 * (because in some contexts you might want to be emagging a bag, and in others you might want to be storing it.)
 *
 * This is only checked by certain items explicitly so you can't just add the trait and expect it to work.
 * (This may be changed later but I chose to do it this way to avoid messing up interactions which require combat mode)
 */
#define TRAIT_COMBAT_MODE_SKIP_INTERACTION "combat_mode_skip_interaction"
// bars change of combat mode
#define TRAIT_COMBAT_MODE_LOCK "combat_mode_lock"

///A "fake" effect that should not be subject to normal effect removal methods (like the effect remover component)
#define TRAIT_ILLUSORY_EFFECT "illusory_effect"
/// Gives a little examine to their body that they can be revived with a soul
#define TRAIT_GHOSTROLE_ON_REVIVE "ghostrole_on_revive"

///Trait given to atoms currently affected by projectile dampeners
#define TRAIT_GOT_DAMPENED "got_dampened"

/// humans with this trait will have their health visible to AIs without suit
#define HUMAN_SENSORS_VISIBLE_WITHOUT_SUIT "hmsensorsvisiblewithoutsuit"
/// Apply to movables to say "hey, this movable is technically flat on the floor, so it'd be mopped up by a mop"
#define TRAIT_MOPABLE "mopable"

/// Humans with this trait do not blink
#define TRAIT_PREVENT_BLINKING "prevent_blinking"

/// Prevents animations for blinking from looping
#define TRAIT_PREVENT_BLINK_LOOPS "prevent_blink_loops"

/// Mob doesn't get closed eyelids overlay when it gets knocked out cold or dies
#define TRAIT_NO_EYELIDS "no_eyelids"

/// Trait applied when the wire bundle component is added to an [/obj/item/integrated_circuit]
#define TRAIT_COMPONENT_WIRE_BUNDLE "component_wire_bundle"

/// Apply this trait to mobs which can "buckle" to humans
#define TRAIT_CAN_MOUNT_HUMANS "can_mount_humans"
/// Apply this trait to mobs which can "buckle" to cyborgs
#define TRAIT_CAN_MOUNT_CYBORGS "can_mount_cyborgs"

/// Trait that is added to fishes that someone already caught, be it in-game or just theoretically, such as when they're bought
/// Prevents fishing achievement from being granted by catching one of these
#define TRAIT_NO_FISHING_ACHIEVEMENT "no_fishing_achievement"

// END TRAIT DEFINES
