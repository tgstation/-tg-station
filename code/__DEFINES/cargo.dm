#define RUBBLE_NONE 1
#define RUBBLE_NORMAL 2
#define RUBBLE_WIDE 3
#define RUBBLE_THIN 4

#define POD_SHAPE_NORMAL 1
#define POD_SHAPE_OTHER 2

#define POD_TRANSIT "1"
#define POD_FALLING "2"
#define POD_OPENING "3"
#define POD_LEAVING "4"

#define SUPPLYPOD_X_OFFSET -16

///DO NOT GO ANY LOWER THAN X1.4 the "CARGO_CRATE_VALUE" value if using regular crates, or infinite profit will be possible! This is also unit tested against.
#define CARGO_MINIMUM_COST CARGO_CRATE_VALUE * 1.4

/// The baseline unit for cargo crates. Adjusting this will change the cost of all in-game shuttles, crate export values, bounty rewards, and all supply pack import values, as they use this as their unit of measurement.
#define CARGO_CRATE_VALUE 200

/// The highest amount of orders you can have of one thing at any one time
#define CARGO_MAX_ORDER 50

/// Returned by /obj/docking_port/mobile/supply/proc/get_order_count to signify us going over the order limit
#define OVER_ORDER_LIMIT "GO AWAY"

/// Universal Scanner mode for export scanning.
#define SCAN_EXPORTS 1
/// Universal Scanner mode for using the sales tagger.
#define SCAN_SALES_TAG 2
/// Universal Scanner mode for using the price tagger.
#define SCAN_PRICE_TAG 3

///Used by coupons to define that they're cursed
#define COUPON_OMEN "omen"

///Discount categories for coupons. This one is for anything that isn't discountable.
#define SUPPLY_PACK_NOT_DISCOUNTABLE null
///Discount category for the standard stuff, mostly goodies.
#define SUPPLY_PACK_STD_DISCOUNTABLE "standard_discount"
///Discount category for stuff that's mostly niche and/or that might be useful.
#define SUPPLY_PACK_UNCOMMON_DISCOUNTABLE "uncommon_discount"
///Discount category for the silly, overpriced, joke content, sometimes useful or plain bad.
#define SUPPLY_PACK_RARE_DISCOUNTABLE "rare_discount"

///Standard export define for not selling the item.
#define EXPORT_NOT_SOLD 0
///Sell the item
#define EXPORT_SOLD 1
///Sell the item, but for the love of god, don't delete it, we're handling it in a fancier way.
#define EXPORT_SOLD_DONT_DELETE 2


//At 320 it's 7.5 minutes, at 1400 it's 12.44 minutes,  at 3000 (around gun crates) it's 15.5 minutes, at 8000 (hat crate) 20 minutes, at 9000 (expensive atmos cans) it's 20.58 minutes, and at the 20k crate it's 24.76 minutes.
/// Multiplies the logarithmic value calculating the free crate cooldown
#define DEPARTMENTAL_ORDER_COOLDOWN_COEFFICIENT 60
/// Used for the power of the logarithmic value for the free crate cooldown
#define DEPARTMENTAL_ORDER_COOLDOWN_EXPONENT 2.2

//At 320 it's 475 credits, at 1400 it's 669 credits,  at 3000 (around gun crates) its 778, at 8000 (hat crate) it's 925 credits, at 9000 (expensive atmos cans) it's 943 credits, and at the 20k crate it's 1070 credits.

/// Multiplies the logarithmic value calculating the free crate delivery reward
#define DEPARTMENTAL_ORDER_REWARD_COEFFICIENT 120
/// Used for the power of the logarithmic value for the free crate delivery reward
#define DEPARTMENTAL_ORDER_REWARD_EXPONENT 1.5
