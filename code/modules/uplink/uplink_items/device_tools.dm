/datum/uplink_category/device_tools
	name = "Misc. Gadgets"
	weight = 3

/datum/uplink_item/device_tools
	category = /datum/uplink_category/device_tools

/datum/uplink_item/device_tools/soap
	name = "Syndicate Soap"
	desc = "A sinister-looking surfactant used to clean blood stains to hide murders and prevent DNA analysis. \
			You can also drop it underfoot to slip people."
	item = /obj/item/soap/syndie
	cost = 1
	surplus = 50
	uplink_item_flags = SYNDIE_TRIPS_CONTRABAND

/datum/uplink_item/device_tools/surgerybag
	name = "Syndicate Surgery Duffel Bag"
	desc = "The Syndicate surgery duffel bag is a toolkit containing all surgery tools, surgical drapes, \
			a Syndicate brand MMI, a straitjacket, and a muzzle."
	item = /obj/item/storage/backpack/duffelbag/syndie/surgery
	cost = 4
	surplus = 66

/datum/uplink_item/device_tools/encryptionkey
	name = "Syndicate Encryption Key"
	desc = "A key that, when inserted into a radio headset, allows you to listen to all station department channels \
			as well as talk on an encrypted Syndicate channel with other agents that have the same key. In addition, this key also protects \
			your headset from radio jammers."
	item = /obj/item/encryptionkey/syndicate
	cost = 2
	surplus = 75
	restricted = TRUE

/datum/uplink_item/device_tools/syndietome
	name = "Syndicate Tome"
	desc = "Using rare artifacts acquired at great cost, the Syndicate has reverse engineered \
			the seemingly magical books of a certain cult. Though lacking the esoteric abilities \
			of the originals, these inferior copies are still quite useful. \
			Often used by agents to protect themselves against foes who rely on magic while it's held. \
			Though, it can be used to heal and harm other people with decent effectiveness much like a regular bible. \
			Can also be used in-hand to 'claim' it, granting you priest-like abilities -- no training required!"
	item = /obj/item/book/bible/syndicate
	cost = 5

/datum/uplink_item/device_tools/tram_remote
	name = "Tram Remote Control"
	desc = "When linked to a tram's on board computer systems, this device allows the user to manipulate the controls remotely. \
		Includes direction toggle and a rapid mode to bypass door safety checks and crossing signals. \
		Perfect for running someone over in the name of a tram malfunction!"
	item = /obj/item/assembly/control/transport/remote
	cost = 2

/datum/uplink_item/device_tools/thermal
	name = "Thermal Imaging Glasses"
	desc = "These goggles can be turned to resemble common eyewear found throughout the station. \
			They allow you to see organisms through walls by capturing the upper portion of the infrared light spectrum, \
			emitted as heat and light by objects. Hotter objects, such as warm bodies, cybernetic organisms \
			and artificial intelligence cores emit more of this light than cooler objects like walls and airlocks."
	item = /obj/item/clothing/glasses/thermal/syndi
	cost = 4

/datum/uplink_item/device_tools/cutouts
	name = "Adaptive Cardboard Cutouts"
	desc = "These cardboard cutouts are coated with a thin material that prevents discoloration and makes the images on them appear more lifelike. \
			This pack contains three as well as a crayon for changing their appearances."
	item = /obj/item/storage/box/syndie_kit/cutouts
	cost = 1
	surplus = 20

/datum/uplink_item/device_tools/briefcase_launchpad
	name = "Briefcase Launchpad"
	desc = "A briefcase containing a launchpad, a device able to teleport items and people to and from targets up to eight tiles away from the briefcase. \
			Also includes a remote control, disguised as an ordinary folder. Touch the briefcase with the remote to link it."
	surplus = 0
	item = /obj/item/storage/briefcase/launchpad
	cost = 6

/datum/uplink_item/device_tools/syndicate_teleporter
	name = "Experimental Syndicate Teleporter"
	desc = "A handheld device that teleports the user 4-8 meters forward. \
			Beware, teleporting into a wall will trigger a parallel emergency teleport; \
			however if that fails, you may need to be stitched back together. \
			Comes with 4 charges, recharges randomly. Warranty null and void if exposed to an electromagnetic pulse."
	item = /obj/item/storage/box/syndie_kit/syndicate_teleporter
	cost = 8

/datum/uplink_item/device_tools/camera_app
	name = "SyndEye Program"
	desc = "A data disk containing a unique PC app that allows you to watch cameras and track crewmembers."
	item = /obj/item/computer_disk/syndicate/camera_app
	cost = 1
	surplus = 90
	purchasable_from = ~UPLINK_ALL_SYNDIE_OPS

/datum/uplink_item/device_tools/military_belt
	name = "Chest Rig"
	desc = "A robust seven-slot set of webbing that is capable of holding all manner of tactical equipment."
	item = /obj/item/storage/belt/military
	cost = 1

/datum/uplink_item/device_tools/doorjack
	name = "Airlock Authentication Override Card"
	desc = "A specialized cryptographic sequencer specifically designed to override station airlock access codes. \
			After hacking a certain number of airlocks, the device will require some time to recharge."
	item = /obj/item/card/emag/doorjack
	cost = 3

/datum/uplink_item/device_tools/fakenucleardisk
	name = "Decoy Nuclear Authentication Disk"
	desc = "It's just a normal disk. Visually it's identical to the real deal, but it won't hold up under closer scrutiny by the Captain. \
			Don't try to give this to us to complete your objective, we know better!"
	item = /obj/item/disk/nuclear/fake
	cost = 1
	surplus = 1
	uplink_item_flags = NONE

/datum/uplink_item/device_tools/frame
	name = "F.R.A.M.E. disk"
	desc = "When inserted into a tablet, this cartridge gives you five messenger viruses which \
			when used cause the targeted tablet to become a new uplink with zero TCs, and immediately become unlocked. \
			You will receive the unlock code upon activating the virus, and the new uplink may be charged with \
			telecrystals normally."
	item = /obj/item/computer_disk/virus/frame
	cost = 4
	restricted = TRUE
	purchasable_from = ~UPLINK_ALL_SYNDIE_OPS

/datum/uplink_item/device_tools/frame/spawn_item(spawn_path, mob/user, datum/uplink_handler/uplink_handler, atom/movable/source)
	. = ..()
	var/obj/item/computer_disk/virus/frame/target = .
	if(!target)
		return
	target.current_progression = uplink_handler.progression_points

/datum/uplink_item/device_tools/failsafe
	name = "Failsafe Uplink Code"
	desc = "When entered the uplink will self-destruct immediately."
	item = ABSTRACT_UPLINK_ITEM
	cost = 1
	surplus = 0
	restricted = TRUE
	purchasable_from = ~UPLINK_ALL_SYNDIE_OPS

/datum/uplink_item/device_tools/failsafe/spawn_item(spawn_path, mob/user, datum/uplink_handler/uplink_handler, atom/movable/source)
	var/datum/component/uplink/uplink = source.GetComponent(/datum/component/uplink)
	if(!uplink)
		return
	if(!uplink.unlock_note) //no note means it can't be locked (typically due to being an implant.)
		to_chat(user, span_warning("This device doesn't support code entry!"))
		return

	uplink.failsafe_code = uplink.generate_code()
	var/code = "[islist(uplink.failsafe_code) ? english_list(uplink.failsafe_code) : uplink.failsafe_code]"
	var/datum/antagonist/traitor/traitor_datum = user.mind?.has_antag_datum(/datum/antagonist/traitor)
	if(traitor_datum)
		traitor_datum.antag_memory += "<b>Uplink Failsafe Code:</b> [code]" + "<br>"
		traitor_datum.update_static_data_for_all_viewers()
	to_chat(user, span_warning("The new failsafe code for this uplink is now: [code].[traitor_datum ? " You may check your antagonist info to recall this." : null]"))
	return source //For log icon

/datum/uplink_item/device_tools/toolbox
	name = "Full Syndicate Toolbox"
	desc = "The Syndicate toolbox is a suspicious black and red. It comes loaded with a full tool set including a \
			multitool and combat gloves that are resistant to shocks and heat."
	item = /obj/item/storage/toolbox/syndicate
	cost = 1
	uplink_item_flags = SYNDIE_TRIPS_CONTRABAND

/datum/uplink_item/device_tools/rad_laser
	name = "Radioactive Microlaser"
	desc = "A radioactive microlaser disguised as a standard Nanotrasen health analyzer. When used, it emits a \
			powerful burst of radiation, which, after a short delay, can incapacitate all but the most protected \
			of humanoids. It has two settings: intensity, which controls the power of the radiation, \
			and wavelength, which controls the delay before the effect kicks in."
	item = /obj/item/healthanalyzer/rad_laser
	cost = 3
	purchasable_from = ~UPLINK_ALL_SYNDIE_OPS

/datum/uplink_item/device_tools/suspiciousphone
	name = "Protocol CRAB-17 Phone"
	desc = "The Protocol CRAB-17 Phone, a phone borrowed from an unknown third party, it can be used to crash the space market, funneling the losses of the crew to your bank account.\
	The crew can move their funds to a new banking site though, unless they HODL, in which case they deserve it."
	item = /obj/item/suspiciousphone
	restricted = TRUE
	cost = 7
	limited_stock = 1

/datum/uplink_item/device_tools/binary
	name = "Binary Translator Key"
	desc = "A key that, when inserted into a radio headset, allows you to listen to and talk with silicon-based lifeforms, \
			such as AI units and cyborgs, over their private binary channel. Caution should \
			be taken while doing this, as unless they are allied with you, they are programmed to report such intrusions."
	item = /obj/item/encryptionkey/binary
	cost = 5
	surplus = 75
	restricted = TRUE

/datum/uplink_item/device_tools/emag
	name = "Cryptographic Sequencer"
	desc = "The cryptographic sequencer, electromagnetic card, or emag, is a small card that unlocks hidden functions \
			in electronic devices, subverts intended functions, and easily breaks security mechanisms. Cannot be used to open airlocks."
	item = /obj/item/card/emag
	cost = 4

/datum/uplink_item/device_tools/stimpack
	name = "Stimpack"
	desc = "Stimpacks, the tool of many great heroes, make you nearly immune to stuns and knockdowns for about \
			5 minutes after injection."
	item = /obj/item/reagent_containers/hypospray/medipen/stimulants
	cost = 5
	surplus = 90

/datum/uplink_item/device_tools/super_pointy_tape
	name = "Super Pointy Tape"
	desc = "An all-purpose super pointy tape roll. The tape is built with hundreds of tiny metal needles, the roll comes with in 5 pieces. When added to items the \
			item that was taped will embed when thrown at people. Taping people's mouthes with it will hurt them if pulled off by someone else."
	item = /obj/item/stack/sticky_tape/pointy/super
	cost = 1

/datum/uplink_item/device_tools/hacked_module
	name = "Hacked AI Law Upload Module"
	desc = "When used with an upload console, this module allows you to upload priority laws to an artificial intelligence. \
			Be careful with wording, as artificial intelligences may look for loopholes to exploit."
	progression_minimum = 30 MINUTES
	item = /obj/item/ai_module/syndicate
	cost = 4

/datum/uplink_item/device_tools/hypnotic_flash
	name = "Hypnotic Flash"
	desc = "A modified flash able to hypnotize targets. If the target is not in a mentally vulnerable state, it will only confuse and pacify them temporarily."
	item = /obj/item/assembly/flash/hypnotic
	cost = 7

/datum/uplink_item/device_tools/hypnotic_grenade
	name = "Hypnotic Grenade"
	desc = "A modified flashbang grenade able to hypnotize targets. The sound portion of the flashbang causes hallucinations, and will allow the flash to induce a hypnotic trance to viewers."
	item = /obj/item/grenade/hypnotic
	cost = 12

/datum/uplink_item/device_tools/singularity_beacon
	name = "Power Beacon"
	desc = "When screwed to wiring attached to an electric grid and activated, this large device pulls any \
			active gravitational singularities or tesla balls towards it. This will not work when the engine is still \
			in containment. Because of its size, it cannot be carried. Ordering this \
			sends you a small beacon that will teleport the larger beacon to your location upon activation."
	progression_minimum = 20 MINUTES
	item = /obj/item/sbeacondrop
	cost = 4
	surplus = 0 // not while there isnt one on any station
	purchasable_from = ~UPLINK_ALL_SYNDIE_OPS

/datum/uplink_item/device_tools/powersink
	name = "Power Sink"
	desc = "When screwed to wiring attached to a power grid and activated, this large device lights up and places excessive \
			load on the grid, causing a station-wide blackout. The sink is large and cannot be stored in most \
			traditional bags and boxes. Caution: Will explode if the powernet contains sufficient amounts of energy."
	progression_minimum = 20 MINUTES
	item = /obj/item/powersink
	cost = 11

/datum/uplink_item/device_tools/syndicate_contacts
	name = "Polarized Contact Lenses"
	desc = "High tech contact lenses that bind directly with the surface of your eyes to give them immunity to flashes and \
			bright lights. Effective, affordable, and nigh undetectable."
	item = /obj/item/syndicate_contacts
	cost = 3

/datum/uplink_item/device_tools/syndicate_climbing_hook
	name = "Syndicate Climbing Hook"
	desc = "High-tech rope, a refined hook structure, the peak of climbing technology. Only useful for climbing up holes, provided the operation site has any."
	item = /obj/item/climbing_hook/syndicate
	cost = 1
