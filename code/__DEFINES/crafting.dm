///If the machine is used/deleted in the crafting process
#define CRAFTING_MACHINERY_CONSUME 1
///If the structure is used/deleted in the crafting process
#define CRAFTING_STRUCTURE_CONSUME 1
///If the machine is only "used" i.e. it checks to see if it's nearby and allows crafting, but doesn't delete it
#define CRAFTING_MACHINERY_USE 0
///If the structure is only "used" i.e. it checks to see if it's nearby and allows crafting, but doesn't delete it
#define CRAFTING_STRUCTURE_USE 0
///If the ingredient is only "used" i.e. it checks to see if it's nearby and allows crafting, but doesn't delete it
#define CRAFTING_INGREDIENT_USE 0

//stack recipe placement check types
/// Checks if there is an object of the result type in any of the cardinal directions
#define STACK_CHECK_CARDINALS (1<<0)
/// Checks if there is an object of the result type within one tile
#define STACK_CHECK_ADJACENT (1<<1)

//---- Defines for var/crafting_flags
///If this craft must be learned before it becomes available
#define CRAFT_MUST_BE_LEARNED (1<<0)
///Should only one object exist on the same turf?
#define CRAFT_ONE_PER_TURF (1<<1)
/// Setting this to true will effectively set check_direction to true.
#define CRAFT_IS_FULLTILE (1<<2)
/// If this craft should run the direction check, for use when building things like directional windows where you can have more than one per turf
#define CRAFT_CHECK_DIRECTION (1<<3)
/// If the craft requires a floor below
#define CRAFT_ON_SOLID_GROUND (1<<4)
/// If the craft checks that there are objects with density in the same turf when being built
#define CRAFT_CHECK_DENSITY (1<<5)
/// If the created atom will gain custom mat datums
#define CRAFT_APPLIES_MATS (1<<6)
/// Crafting passes reagents of components to the finished product
#define CRAFT_TRANSFERS_REAGENTS (1<<7)
/// Crafting clears all reagents present in the finished product
#define CRAFT_CLEARS_REAGENTS (1<<8)

//food/drink crafting defines
//When adding new defines, please make sure to also add them to the encompassing list
#define CAT_FOOD "Foods"
#define CAT_BREAD "Breads"
#define CAT_BURGER "Burgers"
#define CAT_CAKE "Cakes"
#define CAT_EGG "Egg-Based Food"
#define CAT_LIZARD "Lizard Food"
#define CAT_MEAT "Meats"
#define CAT_SEAFOOD "Seafood"
#define CAT_MARTIAN "Martian Food"
#define CAT_MISCFOOD "Misc. Food"
#define CAT_MEXICAN "Mexican Food"
#define CAT_MOTH "Mothic Food"
#define CAT_PASTRY "Pastries"
#define CAT_PIE "Pies"
#define CAT_PIZZA "Pizzas"
#define CAT_SALAD "Salads"
#define CAT_SANDWICH "Sandwiches"
#define CAT_SOUP "Soups"
#define CAT_SPAGHETTI "Spaghettis"
#define CAT_ICE "Frozen"
#define CAT_DRINK "Drinks"

//crafting defines
//When adding new defines, please make sure to also add them to the encompassing list
#define CAT_WEAPON_RANGED "Weapons Ranged"
#define CAT_WEAPON_MELEE "Weapons Melee"
#define CAT_WEAPON_AMMO "Weapon Ammo"
#define CAT_ROBOT "Robotics"
#define CAT_MISC "Misc"
#define CAT_CLOTHING "Clothing"
#define CAT_CHEMISTRY "Chemistry"
#define CAT_ATMOSPHERIC "Atmospherics"
#define CAT_STRUCTURE "Structures"
#define CAT_TILES "Tiles"
#define CAT_WINDOWS "Windows"
#define CAT_DOORS "Doors"
#define CAT_FURNITURE "Furniture"
#define CAT_EQUIPMENT "Equipment"
#define CAT_CONTAINERS "Containers"
#define CAT_ENTERTAINMENT "Entertainment"
#define CAT_TOOLS "Tools"
#define CAT_CULT "Blood Cult"
