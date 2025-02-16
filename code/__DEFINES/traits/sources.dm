// This file contains all of the trait sources, or all of the things that grant traits.
// Several things such as `type` or `REF(src)` may be used in the ADD_TRAIT() macro as the "source", but this file contains all of the defines for immutable static strings.

// common trait sources
#define TRAIT_GENERIC "generic"
#define UNCONSCIOUS_TRAIT "unconscious"
#define EYE_DAMAGE "eye_damage"
#define EAR_DAMAGE "ear_damage"
#define GENETIC_MUTATION "genetic"
#define OBESITY "obesity"
#define MAGIC_TRAIT "magic"
#define TRAUMA_TRAIT "trauma"
#define FLIGHTPOTION_TRAIT "flightpotion"
#define SLIME_POTION_TRAIT "slime_potion"
/// Trait inherited by experimental surgeries
#define EXPERIMENTAL_SURGERY_TRAIT "experimental_surgery"
#define DISEASE_TRAIT "disease"
#define SPECIES_TRAIT "species"
#define ORGAN_TRAIT "organ"
/// Trait given by augmented limbs
#define AUGMENTATION_TRAIT "augments"
/// Trait given by organ gained via abductor surgery
#define ABDUCTOR_GLAND_TRAIT "abductor_gland"
/// cannot be removed without admin intervention
#define ROUNDSTART_TRAIT "roundstart"
#define JOB_TRAIT "job"
#define CYBORG_ITEM_TRAIT "cyborg-item"
/// Any traits granted by quirks.
#define QUIRK_TRAIT "quirk_trait"
/// (B)admins only.
#define ADMIN_TRAIT "admin"
/// Any traits given through a smite.
#define SMITE_TRAIT "smite"
#define CHANGELING_TRAIT "changeling"
#define CULT_TRAIT "cult"
#define LICH_TRAIT "lich"

#define VENDING_MACHINE_TRAIT "vending_machine"

///A trait given by a held item
#define HELD_ITEM_TRAIT "held-item-trait"
#define ABSTRACT_ITEM_TRAIT "abstract-item"

/// Trait from light debugging
#define LIGHT_DEBUG_TRAIT "light-debug"

/// Trait given by an Action datum
#define ACTION_TRAIT "action"
///A trait given by someone blocking.
#define BLOCKING_TRAIT "blocking"
#define CLOTHING_TRAIT "clothing"
#define HELMET_TRAIT "helmet"
/// inherited from the mask
#define MASK_TRAIT "mask"
/// inherited from your sweet kicks
#define SHOES_TRAIT "shoes"
/// Trait inherited by implants
#define IMPLANT_TRAIT "implant"
/// Traits given by the heretic arena spell
#define HERETIC_ARENA_TRAIT "heretic_arena"
#define GLASSES_TRAIT "glasses"
/// inherited from riding vehicles
#define VEHICLE_TRAIT "vehicle"
#define INNATE_TRAIT "innate"
#define CRIT_HEALTH_TRAIT "crit_health"
#define OXYLOSS_TRAIT "oxyloss"
/// Trait sorce for "was recently shocked by something"
#define WAS_SHOCKED "was_shocked"
#define TURF_TRAIT "turf"
/// trait associated to being buckled
#define BUCKLED_TRAIT "buckled"
/// trait associated to being held in a chokehold
#define CHOKEHOLD_TRAIT "chokehold"
/// trait associated to resting
#define RESTING_TRAIT "resting"
/// trait associated to a stat value or range of
#define STAT_TRAIT "stat"
#define STATION_TRAIT "station-trait"
/// obtained from mapping helper
#define MAPPING_HELPER_TRAIT "mapping-helper"
/// Trait associated to wearing a suit
#define SUIT_TRAIT "suit"
/// Trait associated to lying down (having a [lying_angle] of a different value than zero).
#define LYING_DOWN_TRAIT "lying-down"
/// A trait gained by leaning against a wall
#define LEANING_TRAIT "leaning"
/// Trait associated to lacking electrical power.
#define POWER_LACK_TRAIT "power-lack"
/// Trait associated to lacking motor movement
#define MOTOR_LACK_TRAIT "motor-lack"
/// Trait associated with mafia
#define MAFIA_TRAIT "mafia"
/// Trait associated with ctf
#define CTF_TRAIT "ctf"
/// Trait associated with deathmatch
#define DEATHMATCH_TRAIT "deathmatch"
/// Trait associated with highlander
#define HIGHLANDER_TRAIT "highlander"
/// Trait given from playing pretend with baguettes
#define SWORDPLAY_TRAIT "swordplay"
/// Trait given by being recruited as a nuclear operative
#define NUKE_OP_MINION_TRAIT "nuke-op-minion"

/// Trait given to you by shapeshifting
#define SHAPESHIFT_TRAIT "shapeshift_trait"

// unique trait sources, still defines
#define EMP_TRAIT "emp_trait"
#define STATUE_MUTE "statue"
#define CHANGELING_DRAIN "drain"

#define STASIS_MUTE "stasis"
#define GENETICS_SPELL "genetics_spell"
#define EYES_COVERED "eyes_covered"
#define NO_EYES "no_eyes"
#define HYPNOCHAIR_TRAIT "hypnochair"
#define FLASHLIGHT_EYES "flashlight_eyes"
#define IMPURE_OCULINE "impure_oculine"
#define HAUNTIUM_REAGENT_TRAIT "hauntium_reagent_trait"
#define TRAIT_SANTA "santa"
#define SCRYING_ORB "scrying-orb"
#define ABDUCTOR_ANTAGONIST "abductor-antagonist"
#define JUNGLE_FEVER_TRAIT "jungle_fever"
#define MEGAFAUNA_TRAIT "megafauna"
#define CLOWN_NUKE_TRAIT "clown-nuke"
#define STICKY_MOUSTACHE_TRAIT "sticky-moustache"
#define CHRONO_GUN_TRAIT "chrono-gun"
#define REVERSE_BEAR_TRAP_TRAIT "reverse-bear-trap"
#define CURSED_MASK_TRAIT "cursed-mask"
#define HIS_GRACE_TRAIT "his-grace"
#define HAND_REPLACEMENT_TRAIT "magic-hand"
#define HOT_POTATO_TRAIT "hot-potato"
#define SABRE_SUICIDE_TRAIT "sabre-suicide"
#define ABDUCTOR_VEST_TRAIT "abductor-vest"
#define CAPTURE_THE_FLAG_TRAIT "capture-the-flag"
#define BASKETBALL_MINIGAME_TRAIT "basketball-minigame"
#define EYE_OF_GOD_TRAIT "eye-of-god"
#define SHAMEBRERO_TRAIT "shamebrero"
#define CHRONOSUIT_TRAIT "chronosuit"
#define LOCKED_HELMET_TRAIT "locked-helmet"
#define NINJA_SUIT_TRAIT "ninja-suit"
#define SLEEPING_CARP_TRAIT "sleeping_carp"
#define BOXING_TRAIT "boxing"
#define TIMESTOP_TRAIT "timestop"
#define LIFECANDLE_TRAIT "lifecandle"
#define VENTCRAWLING_TRAIT "ventcrawling"
#define SPECIES_FLIGHT_TRAIT "species-flight"
#define FROSTMINER_ENRAGE_TRAIT "frostminer-enrage"
#define NO_GRAVITY_TRAIT "no-gravity"
#define NEGATIVE_GRAVITY_TRAIT "negative-gravity"

/// A trait gained from a mob's leap action, like the leaper
#define LEAPING_TRAIT "leaping"
/// From grabbing someone
#define GRABBING_TRAIT "grabbing"
/// A trait gained from a mob's vanish action, like the herophant
#define VANISHING_TRAIT "vanishing"
/// A trait gained from a mob's swoop action, like the ash drake
#define SWOOPING_TRAIT "swooping"
/// A trait gained from a mob's mimic ability, like the mimic
#define MIMIC_TRAIT "mimic"
#define SHRUNKEN_TRAIT "shrunken"
#define LEAPER_BUBBLE_TRAIT "leaper-bubble"
#define DNA_VAULT_TRAIT "dna_vault"
/// sticky nodrop sounds like a bad soundcloud rapper's name
#define STICKY_NODROP "sticky-nodrop"
#define SKILLCHIP_TRAIT "skillchip"
#define SKILL_TRAIT "skill"
#define PULLED_WHILE_SOFTCRIT_TRAIT "pulled-while-softcrit"
#define LOCKED_BORG_TRAIT "locked-borg"
/// trait associated to not having locomotion appendages nor the ability to fly or float
#define LACKING_LOCOMOTION_APPENDAGES_TRAIT "lacking-locomotion-appengades"
#define CRYO_TRAIT "cryo"
/// trait associated to not having fine manipulation appendages such as hands
#define LACKING_MANIPULATION_APPENDAGES_TRAIT "lacking-manipulation-appengades"
#define HANDCUFFED_TRAIT "handcuffed"
/// Trait granted by [/obj/item/warp_whistle]
#define WARPWHISTLE_TRAIT "warpwhistle"
///Turf trait for when a turf is transparent
#define TURF_Z_TRANSPARENT_TRAIT "turf_z_transparent"
/// Trait applied by [/datum/component/soulstoned]
#define SOULSTONE_TRAIT "soulstone"
/// Trait applied to slimes by low temperature
#define SLIME_COLD "slime-cold"
/// Trait applied to mobs by being tipped over
#define TIPPED_OVER "tipped-over"
/// Trait applied to PAIs by being folded
#define PAI_FOLDED "pai-folded"
/// Trait applied to brain mobs when they lack external aid for locomotion, such as being inside a mech.
#define BRAIN_UNAIDED "brain-unaided"
/// Trait applied to a mob when it gets a required "operational datum" (components/elements). Sends out the source as the type of the element.
#define TRAIT_SUBTREE_REQUIRED_OPERATIONAL_DATUM "element-required"
/// Trait applied by MODsuits.
#define MOD_TRAIT "mod"
/// Trait applied to tram passengers
#define TRAM_PASSENGER_TRAIT "tram-passenger"
/// Trait given by a fulton extraction pack
#define FULTON_PACK_TRAIT "fulton-pack"

/// Trait from mob/living/update_transform()
#define UPDATE_TRANSFORM_TRAIT "update_transform"
/// Trait from mob/living/update_offsets()
#define UPDATE_OFFSET_TRAIT "update_offset"

/// Trait granted by the berserker hood.
#define BERSERK_TRAIT "berserk_trait"
/// Trait granted by [/obj/item/rod_of_asclepius]
#define HIPPOCRATIC_OATH_TRAIT "hippocratic_oath"
/// Trait granted by [/datum/status_effect/blooddrunk]
#define BLOODDRUNK_TRAIT "blooddrunk"
/// Trait granted by lipstick
#define LIPSTICK_TRAIT "lipstick_trait"
/// Self-explainatory.
#define BEAUTY_ELEMENT_TRAIT "beauty_element"
#define MOOD_DATUM_TRAIT "mood_datum"
#define DRONE_SHY_TRAIT "drone_shy"
/// Trait given by adamantine extracts
#define ADAMANTINE_EXTRACT_TRAIT "adamantine_extract"
/// Given by the multiple_lives component to the previous body of the mob upon death.
#define EXPIRED_LIFE_TRAIT "expired_life"
/// Trait given to an atom/movable when they orbit something.
#define ORBITING_TRAIT "orbiting"
/// From the item_scaling element
#define ITEM_SCALING_TRAIT "item_scaling"
/// Trait given by choking
#define CHOKING_TRAIT "choking_trait"
/// Trait given by hallucinations
#define HALLUCINATION_TRAIT "hallucination_trait"
/// Trait given by simple/basic mob death
#define BASIC_MOB_DEATH_TRAIT "basic_mob_death"
/// Trait given by your current speed
#define SPEED_TRAIT "speed_trait"
/// Trait given to mobs that have been autopsied
#define AUTOPSY_TRAIT "autopsy_trait"
#define EYE_SCARRING_TRAIT "eye_scarring_trait"

///From the market_crash event
#define MARKET_CRASH_EVENT_TRAIT "crashed_market_event"

/// Traits granted to items due to their chameleon properties.
#define CHAMELEON_ITEM_TRAIT "chameleon_item_trait"

// some trait sources dirived from bodyparts - BODYPART_TRAIT is generic.
#define BODYPART_TRAIT "bodypart"
#define HEAD_TRAIT "head"
#define CHEST_TRAIT "chest"
#define RIGHT_ARM_TRAIT "right_arm"
#define LEFT_ARM_TRAIT "left_arm"
#define RIGHT_LEG_TRAIT "right_leg"
#define LEFT_LEG_TRAIT "left_leg"

///coming from a fish trait datum.
#define FISH_TRAIT_DATUM "fish_trait_datum"
///coming from a fish evolution datum
#define FISH_EVOLUTION "fish_evolution"

/// Trait given by echolocation component.
#define ECHOLOCATION_TRAIT "echolocation"

///trait source that tongues should use
#define SPEAKING_FROM_TONGUE "tongue"
///trait source that sign language should use
#define SPEAKING_FROM_HANDS "hands"

/// Sources for TRAIT_IGNORING_GRAVITY
#define IGNORING_GRAVITY_NEGATION "ignoring_gravity_negation"

/// Hearing trait that is from the hearing component
#define CIRCUIT_HEAR_TRAIT "circuit_hear"

/// This trait comes from when a mob is currently typing.
#define CURRENTLY_TYPING_TRAIT "currently_typing"

/**
* Trait granted by [/mob/living/carbon/Initialize] and
* granted/removed by [/obj/item/organ/tongue]
* Used for ensuring that carbons without tongues cannot taste anything
* so it is added in Initialize, and then removed when a tongue is inserted
* and readded when a tongue is removed.
*/
#define NO_TONGUE_TRAIT "no_tongue_trait"

/// Trait granted by [/mob/living/silicon/robot]
/// Traits applied to a silicon mob by their model.
#define MODEL_TRAIT "model_trait"

/// Trait granted by [mob/living/silicon/ai]
/// Applied when the ai anchors itself
#define AI_ANCHOR_TRAIT "ai_anchor"

/// Trait from [/datum/antagonist/nukeop/clownop]
#define CLOWNOP_TRAIT "clownop"

#define ANALYZER_TRAIT "analyzer_trait"

/// Trait from an organ being inside a bodypart
#define ORGAN_INSIDE_BODY_TRAIT "organ_inside_body"

/// Trait when a drink was renamed by a shaker
#define SHAKER_LABEL_TRAIT "shaker_trait"

/// Trait given by a jetpack
#define JETPACK_TRAIT "jetpack_trait"

/// Trait added by style component
#define STYLE_TRAIT "style"

/// Trait added by a xenobio console
#define XENOBIO_CONSOLE_TRAIT "xenobio_console_trait"

/// Trait from an engraving
#define ENGRAVED_TRAIT "engraved"

/// From the aquarium component
#define AQUARIUM_TRAIT "aquarium"

/// Trait acquired from being painted a certain color
#define ATOM_COLOR_TRAIT "atom_color"

/// Permanent trait from an overdose effect
#define OVERDOSE_TRAIT "overdose"
