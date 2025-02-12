//Vehicle control flags. control flags describe access to actions in a vehicle.

///controls the vehicles movement
#define VEHICLE_CONTROL_DRIVE (1<<0)
///Can't leave vehicle voluntarily, has to resist.
#define VEHICLE_CONTROL_KIDNAPPED (1<<1)
///melee attacks/shoves a vehicle may have
#define VEHICLE_CONTROL_MELEE (1<<2)
///using equipment/weapons on the vehicle
#define VEHICLE_CONTROL_EQUIPMENT (1<<3)
///changing around settings and the like.
#define VEHICLE_CONTROL_SETTINGS (1<<4)

///ez define for giving a single pilot mech all the flags it needs.
#define FULL_MECHA_CONTROL ALL

//Ridden vehicle flags

/// Does our vehicle require arms to operate? Also used for piggybacking on humans to reserve arms on the rider
#define RIDER_NEEDS_ARMS   (1<<0)
// As above but only used for riding cyborgs, and only reserves 1 arm instead of 2
#define RIDER_NEEDS_ARM (1<<1)
/// Do we need legs to ride this (checks against TRAIT_FLOORED)
#define RIDER_NEEDS_LEGS   (1<<2)
/// If the rider is disabled or loses their needed limbs, do they fall off?
#define UNBUCKLE_DISABLED_RIDER (1<<3)
// For fireman carries, the carrying human needs an arm
#define CARRIER_NEEDS_ARM (1<<4)
// This rider must be our friend
#define JUST_FRIEND_RIDERS (1<<5)

//car_traits flags
///Will this car kidnap people by ramming into them?
#define CAN_KIDNAP (1<<0)

#define CLOWN_CANNON_INACTIVE 0
#define CLOWN_CANNON_BUSY 1
#define CLOWN_CANNON_READY 2

//Vim defines
///cooldown between uses of the sound maker
#define VIM_SOUND_COOLDOWN (1 SECONDS)
///how much vim heals per weld
#define VIM_HEAL_AMOUNT 20
