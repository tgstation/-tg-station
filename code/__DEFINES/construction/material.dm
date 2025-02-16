//Defines for amount of material retrieved from sheets & other items
/// The amount of materials you get from a sheet of mineral like iron/diamond/glass etc. 100 Units.
#define SHEET_MATERIAL_AMOUNT 100
/// The amount of materials you get from half a sheet. Used in standard object quantities. 50 units.
#define HALF_SHEET_MATERIAL_AMOUNT (SHEET_MATERIAL_AMOUNT / 2)
/// The amount of materials used in the smallest of objects, like pens and screwdrivers. 10 units.
#define SMALL_MATERIAL_AMOUNT (HALF_SHEET_MATERIAL_AMOUNT / 5)
/// The amount of material that goes into a coin, which determines the value of the coin.
#define COIN_MATERIAL_AMOUNT (HALF_SHEET_MATERIAL_AMOUNT * 0.4)

//Cable related values
/// The maximum size of a stack object.
#define MAX_STACK_SIZE 50
/// Maximum amount of cable in a coil
#define MAXCOIL 30

//Category of materials
/// Can this material be stored in the ore silo
#define MAT_CATEGORY_SILO "silo capable"
/// Hard materials, such as iron or silver
#define MAT_CATEGORY_RIGID "rigid material"
/// Materials that can be used to craft items
#define MAT_CATEGORY_ITEM_MATERIAL "item material"
/**
 * Materials that can also be used to craft items for designs that require two custom mats.
 * This is mainly a work around to the fact we can't (easily) have the same category show
 * multiple times in a list with different values, because list access operator [] will fetch the
 * top-most value.
 */
#define MAT_CATEGORY_ITEM_MATERIAL_COMPLEMENTARY "item material complementary"

/// Use this flag on TRUE if you want the basic recipes
#define MAT_CATEGORY_BASE_RECIPES "basic recipes"

///Flags for map loaded materials
/// Used to make a material initialize at roundstart.
#define MATERIAL_INIT_MAPLOAD (1<<0)
/// Used to make a material type able to be instantiated on demand after roundstart.
#define MATERIAL_INIT_BESPOKE (1<<1)

//Material Container Flags.
///If the container shows the amount of contained materials on examine.
#define MATCONTAINER_EXAMINE (1<<0)
///If the container cannot have materials inserted through attackby().
#define MATCONTAINER_NO_INSERT (1<<1)
///If the user can insert mats into the container despite the intent.
#define MATCONTAINER_ANY_INTENT (1<<2)
///If the user won't receive a warning when attacking the container with an unallowed item.
#define MATCONTAINER_SILENT (1<<3)

/// Whether a material's mechanical effects should apply to the atom. This is necessary for other flags to work.
#define MATERIAL_EFFECTS (1<<0)
/// Applies the material color to the atom's color. Deprecated, use MATERIAL_GREYSCALE instead
#define MATERIAL_COLOR (1<<1)
/// Whether a prefix describing the material should be added to the name
#define MATERIAL_ADD_PREFIX (1<<2)
/// Whether a material should affect the stats of the atom
#define MATERIAL_AFFECT_STATISTICS (1<<3)
/// Applies the material greyscale color to the atom's greyscale color.
#define MATERIAL_GREYSCALE (1<<4)
/// Materials like plasteel and alien alloy won't apply slowdowns.
#define MATERIAL_NO_SLOWDOWN (1<<5)
/// This item is not affected by food-related effects of materials like meat and pizza
#define MATERIAL_NO_EDIBILITY (1<<6)

//Special return values of [/datum/component/material_container/insert_item]
/// No material was found inside them item
#define MATERIAL_INSERT_ITEM_NO_MATS -1
/// The container does not have the space for the item
#define MATERIAL_INSERT_ITEM_NO_SPACE -2
/// The item material type was not accepted or other reasons
#define MATERIAL_INSERT_ITEM_FAILURE 0


// Slowdown values.
/// The slowdown value of one [SHEET_MATERIAL_AMOUNT] of plasteel.
#define MATERIAL_SLOWDOWN_PLASTEEL (0.05)
/// The slowdown value of one [SHEET_MATERIAL_AMOUNT] of alien alloy.
#define MATERIAL_SLOWDOWN_ALIEN_ALLOY (0.1)

//Stock market stock values.
/// How much quantity of a material stock exists for common materials like iron & glass.
#define MATERIAL_QUANTITY_COMMON 5000
/// How much quantity of a material stock exists for uncommon materials like silver & titanium.
#define MATERIAL_QUANTITY_UNCOMMON 1000
/// How much quantity of a material stock exists for rare materials like gold, uranium, & diamond.
#define MATERIAL_QUANTITY_RARE 200
/// How much quantity of a material stock exists for exotic materials like diamond & bluespace crystals.
#define MATERIAL_QUANTITY_EXOTIC 50

// The number of ore vents that will spawn boulders with this material.
/// Is this material going to spawn often in ore vents? (80% of vents on lavaland)
#define MATERIAL_RARITY_COMMON 12
/// Is this material going to spawn often in ore vents? (53% of vents on lavaland)
#define MATERIAL_RARITY_SEMIPRECIOUS 8
/// Is this material going to spawn uncommonly in ore vents? (33% of vents on lavaland)
#define MATERIAL_RARITY_PRECIOUS 5
/// Is this material going to spawn rarely in ore vents? (20% of vents on lavaland)
#define MATERIAL_RARITY_RARE 3
/// Is this material only going to spawn once in ore vents? (6% of vents on lavaland)
#define MATERIAL_RARITY_UNDISCOVERED 1

///The key to access the 'optimal' amount of a material key from its assoc value list.
#define MATERIAL_LIST_OPTIMAL_AMOUNT "optimal_amount"
///The key to access the multiplier used to selectively control effects and modifiers of a material.
#define MATERIAL_LIST_MULTIPLIER "multiplier"
///A macro that ensures some multiplicative modifiers higher than 1 don't become lower than 1 and vice-versa because of the multiplier.
#define GET_MATERIAL_MODIFIER(modifier, multiplier) (modifier >= 1 ? 1 + ((modifier) - 1) * (multiplier) : (modifier)**(multiplier))
