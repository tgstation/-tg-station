#define EMAG_LOCKED_SHUTTLE_COST (CARGO_CRATE_VALUE * 50)

/datum/map_template/shuttle/emergency
	port_id = "emergency"
	name = "Base Shuttle Template (Emergency)"
	///assoc list of shuttle events to add to this shuttle on spawn (typepath = weight)
	var/list/events
	///pick all events instead of random
	var/use_all_events = FALSE
	///how many do we pick
	var/event_amount = 1
	///do we empty the event list before adding our events
	var/events_override = FALSE

/datum/map_template/shuttle/emergency/New()
	. = ..()
	if(!occupancy_limit && who_can_purchase)
		CRASH("The [name] needs an occupancy limit!")
	if(HAS_TRAIT(SSstation, STATION_TRAIT_SHUTTLE_SALE) && credit_cost > 0 && prob(15))
		var/discount_amount = round(rand(25, 80), 5)
		name += " ([discount_amount]% Discount!)"
		var/discount_multiplier = 100 - discount_amount
		credit_cost = ((credit_cost * discount_multiplier) / 100)

///on post_load use our variables to change shuttle events
/datum/map_template/shuttle/emergency/post_load(obj/docking_port/mobile/mobile)
	. = ..()
	if(!events)
		return
	if(events_override)
		mobile.event_list.Cut()
	if(use_all_events)
		for(var/path in events)
			mobile.add_shuttle_event(path)
			events -= path
	else
		for(var/i in 1 to event_amount)
			var/path = pick_weight(events)
			events -= path
			mobile.add_shuttle_event(path)

/datum/map_template/shuttle/emergency/backup
	suffix = "backup"
	name = "Backup Shuttle"
	who_can_purchase = null

/datum/map_template/shuttle/emergency/construction
	suffix = "construction"
	name = "Build your own shuttle kit"
	description = "For the enterprising shuttle engineer! The chassis will dock upon purchase, but launch will have to be authorized as usual via shuttle call. Comes stocked with construction materials. Unlocks the ability to buy shuttle engine crates from cargo, which allow you to speed up shuttle transit time."
	admin_notes = "No brig, no medical facilities."
	credit_cost = CARGO_CRATE_VALUE * 5
	who_can_purchase = list(ACCESS_CAPTAIN, ACCESS_CE)
	occupancy_limit = "Flexible"

/datum/map_template/shuttle/emergency/asteroid
	suffix = "asteroid"
	name = "Asteroid Station Emergency Shuttle"
	description = "A respectable mid-sized shuttle that first saw service shuttling Nanotrasen crew to and from their asteroid belt embedded facilities."
	credit_cost = CARGO_CRATE_VALUE * 6
	occupancy_limit = "50"

/datum/map_template/shuttle/emergency/venture
	suffix = "venture"
	name = "Venture Emergency Shuttle"
	description = "A mid-sized shuttle for those who like a lot of space for their legs."
	credit_cost = CARGO_CRATE_VALUE * 10
	occupancy_limit = "45"

/datum/map_template/shuttle/emergency/humpback
	suffix = "humpback"
	name = "Humpback Emergency Shuttle"
	description = "A repurposed cargo hauling and salvaging ship, for sightseeing and tourism. Has a bar. Complete with a 2 minute vacation plan to carp territory."
	credit_cost = CARGO_CRATE_VALUE * 12
	occupancy_limit = "30"
	events = list(
		/datum/shuttle_event/simple_spawner/carp/friendly = 10,
		/datum/shuttle_event/simple_spawner/carp/friendly_but_no_personal_space = 2,
		/datum/shuttle_event/simple_spawner/carp = 2,
		/datum/shuttle_event/simple_spawner/carp/magic = 1,
	)

/datum/map_template/shuttle/emergency/bar
	suffix = "bar"
	name = "The Emergency Escape Bar"
	description = "Features include sentient bar staff (a Bardrone and a Barmaid), bathroom, a quality lounge for the heads, and a large gathering table."
	admin_notes = "Bardrone and Barmaid have TRAIT_GODMODE (basically invincibility), will be automatically sentienced by the fun balloon at 60 seconds before arrival. \
	Has medical facilities."
	credit_cost = CARGO_CRATE_VALUE * 10
	occupancy_limit = "30"

/datum/map_template/shuttle/emergency/pod
	suffix = "pod"
	name = "Emergency Pods"
	description = "We did not expect an evacuation this quickly. All we have available is two escape pods."
	admin_notes = "For player punishment."
	who_can_purchase = null
	occupancy_limit = "10"

/datum/map_template/shuttle/emergency/russiafightpit
	suffix = "russiafightpit"
	name = "Mother Russia Bleeds"
	description = "Dis is a high-quality shuttle, da. Many seats, lots of space, all equipment! Even includes entertainment! Such as lots to drink, and a fighting arena for drunk crew to have fun! If arena not fun enough, simply press button of releasing bears. Do not worry, bears trained not to break out of fighting pit, so totally safe so long as nobody stupid or drunk enough to leave door open. Try not to let asimov babycons ruin fun!"
	admin_notes = "Includes a small variety of weapons. And bears. Only captain-access can release the bears. Bears won't smash the windows themselves, but they can escape if someone lets them."
	credit_cost = CARGO_CRATE_VALUE * 10 // While the shuttle is rusted and poorly maintained, trained bears are costly.
	occupancy_limit = "40"

/datum/map_template/shuttle/emergency/meteor
	suffix = "meteor"
	name = "Asteroid With Engines Strapped To It"
	description = "A hollowed out asteroid with engines strapped to it, the hollowing procedure makes it very difficult to hijack but is very expensive. Due to its size and difficulty in steering it, this shuttle may damage the docking area."
	admin_notes = "This shuttle will likely crush escape, killing anyone there."
	credit_cost = CARGO_CRATE_VALUE * 30
	movement_force = list("KNOCKDOWN" = 3, "THROW" = 2)
	occupancy_limit = "CONDEMNED"

/datum/map_template/shuttle/emergency/monastery
	suffix = "monastery"
	name = "Grand Corporate Monastery"
	description = "Originally built for a public station, this grand edifice to religion, due to budget cuts, is now available as an escape shuttle for the right... donation. Due to its large size and callous owners, this shuttle may cause collateral damage."
	admin_notes = "WARNING: This shuttle WILL destroy a fourth of the station, likely picking up a lot of objects with it."
	emag_only = TRUE
	credit_cost = EMAG_LOCKED_SHUTTLE_COST * 1.8
	movement_force = list("KNOCKDOWN" = 3, "THROW" = 5)
	occupancy_limit = "70"

/datum/map_template/shuttle/emergency/luxury
	suffix = "luxury"
	name = "Luxury Shuttle"
	description = "A luxurious golden shuttle complete with an indoor swimming pool. Each crewmember wishing to board must bring 500 credits, payable in cash and mineral coin."
	extra_desc = "This shuttle costs 500 credits to board."
	admin_notes = "Due to the limited space for non paying crew, this shuttle may cause a riot."
	emag_only = TRUE
	credit_cost = EMAG_LOCKED_SHUTTLE_COST
	occupancy_limit = "75"

/datum/map_template/shuttle/emergency/medisim
	suffix = "medisim"
	name = "Medieval Reality Simulation Dome"
	description = "A state of the art simulation dome, loaded onto your shuttle! Watch and laugh at how petty humanity used to be before it reached the stars. Guaranteed to be at least 40% historically accurate."
	prerequisites = "A special holodeck simulation must be loaded before this shuttle can be purchased."
	admin_notes = "Ghosts can spawn in and fight as knights or archers. The CTF auto restarts, so no admin intervention necessary."
	credit_cost = 20000
	occupancy_limit = "30"

/datum/map_template/shuttle/emergency/medisim/prerequisites_met()
	return SSshuttle.shuttle_purchase_requirements_met[SHUTTLE_UNLOCK_MEDISIM]

/datum/map_template/shuttle/emergency/discoinferno
	suffix = "discoinferno"
	name = "Disco Inferno"
	description = "The glorious results of centuries of plasma research done by Nanotrasen employees. This is the reason why you are here. Get on and dance like you're on fire, burn baby burn!"
	admin_notes = "Flaming hot. The main area has a dance machine as well as plasma floor tiles that will be ignited by players every single time."
	emag_only = TRUE
	credit_cost = EMAG_LOCKED_SHUTTLE_COST
	occupancy_limit = "10"

/datum/map_template/shuttle/emergency/arena
	suffix = "arena"
	name = "The Arena"
	description = "The crew must pass through an otherworldly arena to board this shuttle. Expect massive casualties."
	prerequisites = "The source of the Bloody Signal must be tracked down and eliminated to unlock this shuttle."
	admin_notes = "RIP AND TEAR."
	credit_cost = CARGO_CRATE_VALUE * 20
	occupancy_limit = "1/2"
	/// Whether the arena z-level has been created
	var/arena_loaded = FALSE

/datum/map_template/shuttle/emergency/arena/prerequisites_met()
	return SSshuttle.shuttle_purchase_requirements_met[SHUTTLE_UNLOCK_BUBBLEGUM]

/datum/map_template/shuttle/emergency/arena/post_load(obj/docking_port/mobile/M)
	. = ..()
	if(!arena_loaded)
		arena_loaded = TRUE
		var/datum/map_template/arena/arena_template = new()
		arena_template.load_new_z()

/datum/map_template/arena
	name = "The Arena"
	mappath = "_maps/templates/the_arena.dmm"

/datum/map_template/shuttle/emergency/birdboat
	suffix = "birdboat"
	name = "Birdboat Station Emergency Shuttle"
	description = "Though a little on the small side, this shuttle is feature complete, which is more than can be said for the pattern of station it was commissioned for."
	credit_cost = CARGO_CRATE_VALUE * 2
	occupancy_limit = "25"

/datum/map_template/shuttle/emergency/box
	suffix = "box"
	name = "Box Station Emergency Shuttle"
	credit_cost = CARGO_CRATE_VALUE * 4
	description = "The gold standard in emergency exfiltration, this tried and true design is equipped with everything the crew needs for a safe flight home."
	occupancy_limit = "45"

/datum/map_template/shuttle/emergency/donut
	suffix = "donut"
	name = "Donutstation Emergency Shuttle"
	description = "The perfect spearhead for any crude joke involving the station's shape, this shuttle supports a separate containment cell for prisoners and a compact medical wing."
	admin_notes = "Has airlocks on both sides of the shuttle and will probably intersect near the front on some stations that build past departures."
	credit_cost = CARGO_CRATE_VALUE * 5
	occupancy_limit = "60"

/datum/map_template/shuttle/emergency/clown
	suffix = "clown"
	name = "Snappop(tm)!"
	description = "Hey kids and grownups! \
	Are you bored of DULL and TEDIOUS shuttle journeys after you're evacuating for probably BORING reasons. Well then order the Snappop(tm) today! \
	We've got fun activities for everyone, an all access cockpit, and no boring security brig! Boo! Play dress up with your friends! \
	Collect all the bedsheets before your neighbour does! Check if the AI is watching you with our patent pending \"Peeping Tom AI Multitool Detector\" or PEEEEEETUR for short. \
	Have a fun ride!"
	admin_notes = "Brig is replaced by anchored greentext book surrounded by lavaland chasms, stationside door has been removed to prevent accidental dropping. No brig."
	credit_cost = CARGO_CRATE_VALUE * 16
	occupancy_limit = "HONK"

/datum/map_template/shuttle/emergency/cramped
	suffix = "cramped"
	name = "Secure Transport Vessel 5 (STV5)"
	description = "Well, looks like CentCom only had this ship in the area, they probably weren't expecting you to need evac for a while. \
	Probably best if you don't rifle around in whatever equipment they were transporting. I hope you're friendly with your coworkers, because there is very little space in this thing.\n\
	\n\
	Contains contraband armory guns, maintenance loot, and abandoned crates!"
	admin_notes = "Due to origin as a solo piloted secure vessel, has an active GPS onboard labeled STV5. Has roughly as much space as Hi Daniel, except with explosive crates."
	occupancy_limit = "5"

/datum/map_template/shuttle/emergency/meta
	suffix = "meta"
	name = "Meta Station Emergency Shuttle"
	credit_cost = CARGO_CRATE_VALUE * 8
	description = "A fairly standard shuttle, though larger and slightly better equipped than the Box Station variant."
	occupancy_limit = "45"

/datum/map_template/shuttle/emergency/kilo
	suffix = "kilo"
	name = "Kilo Station Emergency Shuttle"
	credit_cost = CARGO_CRATE_VALUE * 10
	description = "A fully functional shuttle including a complete infirmary, storage facilities and regular amenities."
	occupancy_limit = "55"

/datum/map_template/shuttle/emergency/mini
	suffix = "mini"
	name = "Ministation emergency shuttle"
	credit_cost = CARGO_CRATE_VALUE * 2
	description = "Despite its namesake, this shuttle is actually only slightly smaller than standard, and still complete with a brig and medbay."
	occupancy_limit = "35"

/datum/map_template/shuttle/emergency/tram
	suffix = "tram"
	name = "Tram Station Emergency Shuttle"
	credit_cost = CARGO_CRATE_VALUE * 4
	description = "A train but in space, choo choo!"
	occupancy_limit = "35"

/datum/map_template/shuttle/emergency/birdshot
	suffix = "birdshot"
	name = "Birdshot Station Emergency Shuttle"
	credit_cost = CARGO_CRATE_VALUE * 2
	description = "We pulled this one out of Mothball just for you!"
	occupancy_limit = "40"

/datum/map_template/shuttle/emergency/wawa
	suffix = "wawa"
	name = "Wawa Stand-in Emergency Shuttle"
	description = "Due to a recent clerical error in the funding department, a lot of funding went to lizard plushies. Due to the costs, Nanotrasen has supplied a nearby garbage truck as a stand-in. Better learn how to share spots."
	credit_cost = CARGO_CRATE_VALUE * 6
	occupancy_limit = "25"

/datum/map_template/shuttle/emergency/scrapheap
	suffix = "scrapheap"
	name = "Standby Evacuation Vessel \"Scrapheap Challenge\""
	credit_cost = CARGO_CRATE_VALUE * -18
	description = "Comrade! We see you are having trouble with money, yes? If you have money issue, very little money, we are looking for good shuttle, emergency shuttle. You take best in sector shuttle, we take yours, you get money, da? Please do not lean on window, fragile like fina china. -Ivan"
	admin_notes = "An abomination with no functional medbay, sections missing, and some very fragile windows. Surprisingly airtight. When bought, gives a good influx of money, but can only be bought if the budget is literally 0 credits."
	movement_force = list("KNOCKDOWN" = 3, "THROW" = 2)
	occupancy_limit = "30"
	prerequisites = "This shuttle is only offered for purchase when the station is low on funds."

/datum/map_template/shuttle/emergency/scrapheap/prerequisites_met()
	return SSshuttle.shuttle_purchase_requirements_met[SHUTTLE_UNLOCK_SCRAPHEAP]

/datum/map_template/shuttle/emergency/narnar
	suffix = "narnar"
	name = "Shuttle 667"
	description = "Looks like this shuttle may have wandered into the darkness between the stars on route to the station. Let's not think too hard about where all the bodies came from."
	admin_notes = "Contains real cult ruins, mob eyeballs, and inactive constructs. Cult mobs will automatically be sentienced by fun balloon. \
	Cloning pods in 'medbay' area are showcases and nonfunctional."
	prerequisites = "A mysterious cult rune will need to be banished before this shuttle can be summoned."
	credit_cost = 6667 ///The joke is the number so no defines
	occupancy_limit = "666"

/datum/map_template/shuttle/emergency/narnar/prerequisites_met()
	return SSshuttle.shuttle_purchase_requirements_met[SHUTTLE_UNLOCK_NARNAR]

/datum/map_template/shuttle/emergency/pubby
	suffix = "pubby"
	name = "Pubby Station Emergency Shuttle"
	description = "A train but in space! Complete with a first, second class, brig and storage area."
	admin_notes = "Choo choo motherfucker!"
	credit_cost = CARGO_CRATE_VALUE * 2
	occupancy_limit = "50"

/datum/map_template/shuttle/emergency/cere
	suffix = "cere"
	name = "Cere Station Emergency Shuttle"
	description = "The large, beefed-up version of the box-standard shuttle. Includes an expanded brig, fully stocked medbay, enhanced cargo storage with mech chargers, \
	an engine room stocked with various supplies, and a crew capacity of 80+ to top it all off. Live large, live Cere."
	admin_notes = "Seriously big, even larger than the Delta shuttle."
	credit_cost = CARGO_CRATE_VALUE * 20
	occupancy_limit = "110"

/datum/map_template/shuttle/emergency/supermatter
	suffix = "supermatter"
	name = "Hyperfractal Gigashuttle"
	description = "\"I dunno, this seems kinda needlessly complicated.\"\n\
	\"This shuttle has very a very high safety record, according to CentCom Officer Cadet Yins.\"\n\
	\"Are you sure?\"\n\
	\"Yes, it has a safety record of N-A-N, which is apparently larger than 100%.\""
	admin_notes = "Supermatter that spawns on shuttle is special anchored 'hugbox' supermatter that cannot take damage and does not take in or emit gas. \
	Outside of admin intervention, it cannot explode. \
	It does, however, still dust anything on contact, emits high levels of radiation, and induce hallucinations in anyone looking at it without protective goggles. \
	Emitters spawn powered on, expect admin notices, they are harmless."
	emag_only = TRUE
	credit_cost = EMAG_LOCKED_SHUTTLE_COST
	movement_force = list("KNOCKDOWN" = 3, "THROW" = 2)
	occupancy_limit = "15"

/datum/map_template/shuttle/emergency/imfedupwiththisworld
	suffix = "imfedupwiththisworld"
	name = "Oh, Hi Daniel"
	description = "How was space work today? Oh, pretty good. We got a new space station and the company will make a lot of money. What space station? I cannot tell you; it's space confidential. \
	Aw, come space on. Why not? No, I can't. Anyway, how is your space roleplay life?"
	admin_notes = "Tiny, with a single airlock and wooden walls. What could go wrong?"
	emag_only = TRUE
	credit_cost = EMAG_LOCKED_SHUTTLE_COST
	movement_force = list("KNOCKDOWN" = 3, "THROW" = 2)
	occupancy_limit = "5"

/datum/map_template/shuttle/emergency/goon
	suffix = "goon"
	name = "NES Port"
	description = "The Nanotrasen Emergency Shuttle Port(NES Port for short) is a shuttle used at other less known Nanotrasen facilities and has a more open inside for larger crowds, but fewer onboard shuttle facilities."
	credit_cost = CARGO_CRATE_VALUE
	occupancy_limit = "40"

/datum/map_template/shuttle/emergency/rollerdome
	suffix = "rollerdome"
	name = "Uncle Pete's Rollerdome"
	description = "Developed by a member of Nanotrasen's R&D crew that claims to have travelled from the year 2028. \
	He says this shuttle is based off an old entertainment complex from the 1990s, though our database has no records on anything pertaining to that decade."
	admin_notes = "ONLY NINETIES KIDS REMEMBER. Uses the fun balloon and drone from the Emergency Bar."
	credit_cost = CARGO_CRATE_VALUE * 30
	occupancy_limit = "5"

/datum/map_template/shuttle/emergency/basketball
	suffix = "bballhooper"
	name = "Basketballer's Stadium"
	description = "Hoop, man, hoop! Get your shooting game on with this sleek new basketball stadium! Do keep in mind that several other features \
	that you may expect to find common-place on other shuttles aren't present to give you this sleek stadium at an affordable cost. \
	It also wasn't manufactured to deal with the form-factor of some of your stations... good luck with that."
	admin_notes = "A larger shuttle built around a basketball stadium: entirely impractical but just a complete blast!"
	credit_cost = CARGO_CRATE_VALUE * 10
	occupancy_limit = "30"

/datum/map_template/shuttle/emergency/wabbajack
	suffix = "wabbajack"
	name = "NT Lepton Violet"
	description = "The research team based on this vessel went missing one day, and no amount of investigation could discover what happened to them. \
	The only occupants were a number of dead rodents, who appeared to have clawed each other to death. \
	Needless to say, no engineering team wanted to go near the thing, and it's only being used as an Emergency Escape Shuttle because there is literally nothing else available."
	admin_notes = "If the crew can solve the puzzle, they will wake the wabbajack statue. It will likely not end well. There's a reason it's boarded up. Maybe they should have just left it alone."
	credit_cost = CARGO_CRATE_VALUE * 30
	occupancy_limit = "30"
	prerequisites = "This shuttle requires an act of magical polymorphism to occur before it can be purchased."

/datum/map_template/shuttle/emergency/wabbajack/prerequisites_met()
	return SSshuttle.shuttle_purchase_requirements_met[SHUTTLE_UNLOCK_WABBAJACK]

/datum/map_template/shuttle/emergency/omega
	suffix = "omega"
	name = "Omegastation Emergency Shuttle"
	description = "On the smaller size with a modern design, this shuttle is for the crew who like the cosier things, while still being able to stretch their legs."
	credit_cost = CARGO_CRATE_VALUE * 2
	occupancy_limit = "30"

/datum/map_template/shuttle/emergency/cruise
	suffix = "cruise"
	name = "The NTSS Independence"
	description = "Ordinarily reserved for special functions and events, the Cruise Shuttle Independence can bring a summery cheer to your next station evacuation for a 'modest' fee!"
	admin_notes = "This motherfucker is BIG. You might need to force dock it."
	credit_cost = CARGO_CRATE_VALUE * 100
	occupancy_limit = "80"

/datum/map_template/shuttle/emergency/monkey
	suffix = "nature"
	name = "Dynamic Environmental Interaction Shuttle"
	description = "A large shuttle with a center biodome that is flourishing with life. Frolic with the monkeys! (Extra monkeys are stored on the bridge.)"
	admin_notes = "Pretty freakin' large, almost as big as Raven or Cere. Exercise caution with it."
	credit_cost = CARGO_CRATE_VALUE * 16
	occupancy_limit = "45"

/datum/map_template/shuttle/emergency/casino
	suffix = "casino"
	name = "Lucky Jackpot Casino Shuttle"
	description = "A luxurious casino packed to the brim with everything you need to start new gambling addictions!"
	admin_notes = "The ship is a bit chunky, so watch where you park it."
	credit_cost = 7777
	occupancy_limit = "85"

/datum/map_template/shuttle/emergency/shadow
	suffix = "shadow"
	name = "The NTSS Shadow"
	description = "Guaranteed to get you somewhere FAST. With a custom-built plasma engine, this bad boy will put more distance between you and certain danger than any other!"
	admin_notes = "The aft of the ship has a plasma tank that starts ignited. May get released by crew. The plasma windows next to the engine heaters will also erupt into flame, and also risk getting released by crew."
	credit_cost = CARGO_CRATE_VALUE * 50
	occupancy_limit = "40"

/datum/map_template/shuttle/emergency/fish
	suffix = "fish"
	name = "Angler's Choice Emergency Shuttle"
	description = "Trades such amenities as 'storage space' and 'sufficient seating' for an artificial environment ideal for fishing, plus ample supplies (also for fishing)."
	admin_notes = "There's a chasm in it, it has railings but that won't stop determined players."
	credit_cost = CARGO_CRATE_VALUE * 10
	occupancy_limit = "35"

/datum/map_template/shuttle/emergency/lance
	suffix = "lance"
	name = "The Lance Crew Evacuation System"
	description = "A brand new shuttle by Nanotrasen's finest in shuttle-engineering, it's designed to tactically slam into a destroyed station, dispatching threats and saving crew at the same time! Be careful to stay out of its path."
	admin_notes = "WARNING: This shuttle is designed to crash into the station. It has turrets, similar to the raven."
	credit_cost = CARGO_CRATE_VALUE * 70
	occupancy_limit = "50"

/datum/map_template/shuttle/emergency/tranquility
	suffix = "tranquility"
	name = "The Tranquility Relocation Shuttle"
	description = "A large shuttle, covered in flora and comfortable resting areas. The perfect way to end a peaceful shift"
	admin_notes = "it's pretty big, and comfy. Be careful when placing it down!"
	credit_cost = CARGO_CRATE_VALUE * 25
	occupancy_limit = "40"

/datum/map_template/shuttle/emergency/hugcage
	suffix = "hugcage"
	name = "Hug Relaxation Shuttle"
	description = "A small cozy shuttle with plenty of beds for tired or sensitive spacemen, and a box for pillow-fights."
	admin_notes = "Has a sentience fun balloon for pets."
	credit_cost = CARGO_CRATE_VALUE * 16
	occupancy_limit = "20"

/datum/map_template/shuttle/emergency/fame
	suffix = "fame"
	name = "Hall of Fame Shuttle"
	description = "A grandiose shuttle that has a red carpet leading to the hall of fame. Are you worthy to stand among the best spessmen in existence?"
	admin_notes = "Designed around persistence from memories, trophies, photos, and statues."
	credit_cost = CARGO_CRATE_VALUE * 25
	occupancy_limit = "55"

/datum/map_template/shuttle/emergency/delta
	suffix = "delta"
	name = "Delta Station Emergency Shuttle"
	description = "A large shuttle for a large station, this shuttle can comfortably fit all your overpopulation and crowding needs. Complete with all facilities plus additional equipment."
	admin_notes = "Go big or go home."
	credit_cost = CARGO_CRATE_VALUE * 15
	occupancy_limit = "75"

/datum/map_template/shuttle/emergency/northstar
	suffix = "northstar"
	name = "North Star Emergency Shuttle"
	description = "A rugged shuttle meant for long-distance transit from the tips of the frontier to Central Command and back. \
	moderately comfortable and large, but cramped."
	credit_cost = CARGO_CRATE_VALUE * 14
	occupancy_limit = "55"

/datum/map_template/shuttle/emergency/nebula
	suffix = "nebula"
	name = "Nebula Station Emergency Shuttle"
	description = "AAn excellent luxury shuttle for transporting a large number of passengers. \
	It is richly equipped with bushes and free oxygen"
	credit_cost = CARGO_CRATE_VALUE * 18
	occupancy_limit = "80"

/datum/map_template/shuttle/emergency/raven
	suffix = "raven"
	name = "CentCom Raven Cruiser"
	description = "The CentCom Raven Cruiser is a former high-risk salvage vessel, now repurposed into an emergency escape shuttle. \
	Once first to the scene to pick through warzones for valuable remains, it now serves as an excellent escape option for stations under heavy fire from outside forces. \
	This escape shuttle boasts shields and numerous anti-personnel turrets guarding its perimeter to fend off meteors and enemy boarding attempts."
	admin_notes = "Comes with turrets that will target anything without the neutral faction (nuke ops, xenos etc, but not pets)."
	credit_cost = CARGO_CRATE_VALUE * 60
	occupancy_limit = "CLASSIFIED"

/datum/map_template/shuttle/emergency/zeta
	suffix = "zeta"
	name = "Tr%nPo2r& Z3TA"
	description = "A glitch appears on your monitor, flickering in and out of the options laid before you. \
	It seems strange and alien..."
	prerequisites = "You will need to research special alien technology to access the signal."
	admin_notes = "Has alien surgery tools, and a void core that provides unlimited power."
	credit_cost = CARGO_CRATE_VALUE * 16
	occupancy_limit = "xxx"

/datum/map_template/shuttle/emergency/zeta/prerequisites_met()
	return SSshuttle.shuttle_purchase_requirements_met[SHUTTLE_UNLOCK_ALIENTECH]

#undef EMAG_LOCKED_SHUTTLE_COST
