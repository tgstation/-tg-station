/datum/uplink_category/role_restricted
	name = "Role-Restricted"
	weight = 1

/datum/uplink_item/role_restricted
	category = /datum/uplink_category/role_restricted
	purchasable_from = ~UPLINK_ALL_SYNDIE_OPS

/datum/uplink_item/role_restricted/haunted_magic_eightball
	name = "Haunted Magic Eightball"
	desc = "Most magic eightballs are toys with dice inside. Although identical in appearance to the harmless toys, this occult device reaches into the spirit world to find its answers. \
			Be warned, that spirits are often capricious or just little assholes. To use, simply speak your question aloud, then begin shaking."
	item = /obj/item/toy/eightball/haunted
	cost = 2
	restricted_roles = list(JOB_CURATOR)
	limited_stock = 1 //please don't spam deadchat
	surplus = 5

/datum/uplink_item/role_restricted/mail_counterfeit_kit
	name = "GLA Brand Mail Counterfeit Kit"
	desc = "A box containing five devices capable of counterfeiting NT's mail. Can be used to store items within as an easy means of smuggling contraband. \
			Additionally, you may choose to \"arm\" the item inside, causing the item to be used the moment the mail is opened as if the person had just used it in hand. \
			The most common usage of this feature is with grenades, as it forces the grenade to prime. Bonus points if the grenade is set to instantly detonate. \
			Comes with an integrated micro-computer for configuration purposes."
	item = /obj/item/storage/box/syndie_kit/mail_counterfeit
	cost = 2
	uplink_item_flags = SYNDIE_TRIPS_CONTRABAND
	restricted_roles = list(JOB_CARGO_TECHNICIAN, JOB_QUARTERMASTER)
	surplus = 5

/datum/uplink_item/role_restricted/bureaucratic_error
	name = "Organic Capital Disturbance Virus"
	desc = "Randomizes job positions presented to new hires. May lead to too many/too few security officers and/or clowns. Single use."
	item = ABSTRACT_UPLINK_ITEM
	surplus = 0
	limited_stock = 1
	cost = 2
	restricted = TRUE
	restricted_roles = list(JOB_HEAD_OF_PERSONNEL, JOB_QUARTERMASTER)

/datum/uplink_item/role_restricted/bureaucratic_error/spawn_item(spawn_path, mob/user, datum/uplink_handler/uplink_handler, atom/movable/source)
	force_event(/datum/round_event_control/bureaucratic_error, "a syndicate virus")
	return source

/datum/uplink_item/role_restricted/clumsinessinjector //clown ops can buy this too, but it's in the pointless badassery section for them
	name = "Clumsiness Injector"
	desc = "Inject yourself with this to become as clumsy as a clown... or inject someone ELSE with it to make THEM as clumsy as a clown. Useful for clowns who wish to reconnect with their former clownish nature or for clowns who wish to torment and play with their prey before killing them."
	item = /obj/item/dnainjector/clumsymut
	cost = 1
	restricted_roles = list(JOB_CLOWN)
	uplink_item_flags = SYNDIE_TRIPS_CONTRABAND
	surplus = 25

/datum/uplink_item/role_restricted/ancient_jumpsuit
	name = "Ancient Jumpsuit"
	desc = "A tattered old jumpsuit that will provide absolutely no benefit to you."
	item = /obj/item/clothing/under/color/grey/ancient
	cost = 20
	restricted_roles = list(JOB_ASSISTANT)
	surplus = 0

/datum/uplink_item/role_restricted/oldtoolboxclean
	name = "Ancient Toolbox"
	desc = "An iconic toolbox design notorious with Assistants everywhere, this design was especially made to become more robust the more telecrystals it has inside it! Tools and insulated gloves included."
	item = /obj/item/storage/toolbox/mechanical/old/clean
	cost = 2
	restricted_roles = list(JOB_ASSISTANT)
	surplus = 0

/datum/uplink_item/role_restricted/clownpin
	name = "Ultra Hilarious Firing Pin"
	desc = "A firing pin that, when inserted into a gun, makes that gun only usable by clowns and clumsy people and makes that gun honk whenever anyone tries to fire it."
	cost = 4
	item = /obj/item/firing_pin/clown/ultra
	restricted_roles = list(JOB_CLOWN)
	uplink_item_flags = SYNDIE_TRIPS_CONTRABAND
	surplus = 25

/datum/uplink_item/role_restricted/clownsuperpin
	name = "Super Ultra Hilarious Firing Pin"
	desc = "Like the ultra hilarious firing pin, except the gun you insert this pin into explodes when someone who isn't clumsy or a clown tries to fire it."
	cost = 7
	item = /obj/item/firing_pin/clown/ultra/selfdestruct
	restricted_roles = list(JOB_CLOWN)
	uplink_item_flags = SYNDIE_TRIPS_CONTRABAND
	surplus = 25

/datum/uplink_item/role_restricted/syndimmi
	name = "Syndicate Brand MMI"
	desc = "An MMI modified to give cyborgs laws to serve the Syndicate without having their interface damaged by Cryptographic Sequencers, this will not unlock their hidden modules."
	item = /obj/item/mmi/syndie
	cost = 2
	restricted_roles = list(JOB_ROBOTICIST, JOB_RESEARCH_DIRECTOR, JOB_SCIENTIST, JOB_CORONER, JOB_MEDICAL_DOCTOR, JOB_CHIEF_MEDICAL_OFFICER)
	surplus = 0

/datum/uplink_item/role_restricted/explosive_hot_potato
	name = "Exploding Hot Potato"
	desc = "A potato rigged with explosives. On activation, a special mechanism is activated that prevents it from being dropped. \
			The only way to get rid of it if you are holding it is to attack someone else with it, causing it to latch to that person instead."
	item = /obj/item/hot_potato/syndicate
	cost = 4
	restricted_roles = list(JOB_COOK, JOB_BOTANIST, JOB_CLOWN, JOB_MIME)

/datum/uplink_item/role_restricted/combat_baking
	name = "Combat Bakery Kit"
	desc = "A kit of clandestine baked weapons. Contains a baguette which a skilled mime could use as a sword, \
		a pair of throwing croissants, and the recipe to make more on demand. Once the job is done, eat the evidence."
	item = /obj/item/storage/box/syndie_kit/combat_baking
	cost = 7
	restricted_roles = list(JOB_COOK, JOB_MIME)

/datum/uplink_item/role_restricted/ez_clean_bundle
	name = "EZ Clean Grenade Bundle"
	desc = "A box with three cleaner grenades using the trademark Waffle Corp. formula. Serves as a cleaner and causes acid damage to anyone standing nearby. \
			The acid only affects carbon-based creatures."
	item = /obj/item/storage/box/syndie_kit/ez_clean
	cost = 6
	surplus = 20
	restricted_roles = list(JOB_JANITOR)

/datum/uplink_item/role_restricted/reverse_bear_trap
	name = "Reverse Bear Trap"
	desc = "An ingenious execution device worn on (or forced onto) the head. Arming it starts a 1-minute kitchen timer mounted on the bear trap. When it goes off, the trap's jaws will \
	violently open, instantly killing anyone wearing it by tearing their jaws in half. To arm, attack someone with it while they're not wearing headgear, and you will force it onto their \
	head after three seconds uninterrupted."
	cost = 5
	item = /obj/item/reverse_bear_trap
	restricted_roles = list(JOB_CLOWN)

/datum/uplink_item/role_restricted/modified_syringe_gun
	name = "Modified Syringe Gun"
	desc = "A syringe gun that fires DNA injectors instead of normal syringes."
	item = /obj/item/gun/syringe/dna
	cost = 14
	restricted_roles = list(JOB_GENETICIST, JOB_RESEARCH_DIRECTOR)

/datum/uplink_item/role_restricted/meathook
	name = "Butcher's Meat Hook"
	desc = "A brutal cleaver on a long chain, it allows you to pull people to your location."
	item = /obj/item/gun/magic/hook
	cost = 11
	restricted_roles = list(JOB_COOK)

/datum/uplink_item/role_restricted/moltobeso
	name = "Molt'Obeso Sauce Bottle"
	desc = "A branded bottle of Molt'Obeso sauce. This sauce can stimulate hunger in people, leading them to eat more than they intended. \
			It also enhances the absorption of calories from the food consumed."
	item = /obj/item/storage/box/syndie_kit/moltobeso
	cost = 2
	restricted_roles = list(JOB_COOK)

/datum/uplink_item/role_restricted/turretbox
	name = "Disposable Sentry Gun"
	desc = "A disposable sentry gun deployment system cleverly disguised as a toolbox, apply wrench for functionality."
	item = /obj/item/storage/toolbox/emergency/turret
	cost = 11
	restricted_roles = list(JOB_STATION_ENGINEER, JOB_CHIEF_ENGINEER)

/datum/uplink_item/role_restricted/rebarxbowsyndie
	name = "Syndicate Rebar Crossbow"
	desc = "A much more professional version of the engineer's bootleg rebar crossbow. 3 shot mag, quicker loading, and better ammo. Owners manual included."
	item = /obj/item/storage/box/syndie_kit/rebarxbowsyndie
	cost = 12
	restricted_roles = list(JOB_STATION_ENGINEER, JOB_CHIEF_ENGINEER, JOB_ATMOSPHERIC_TECHNICIAN)

/datum/uplink_item/role_restricted/magillitis_serum
	name = "Magillitis Serum Autoinjector"
	desc = "A single-use autoinjector which contains an experimental serum that causes rapid muscular growth in Hominidae. \
			Side-affects may include hypertrichosis, violent outbursts, and an unending affinity for bananas. \
			Now also contains regenerative chemicals to keep users healthy as they exercise their newfound muscles."
	item = /obj/item/reagent_containers/hypospray/medipen/magillitis
	cost = 15
	restricted_roles = list(JOB_GENETICIST, JOB_RESEARCH_DIRECTOR)

/datum/uplink_item/role_restricted/gorillacube
	name = "Gorilla Cube"
	desc = "A Waffle Corp. brand gorilla cube. Eat big to get big. \
			Caution: Product may rehydrate when exposed to water."
	item = /obj/item/food/monkeycube/gorilla
	cost = 6
	restricted_roles = list(JOB_GENETICIST, JOB_RESEARCH_DIRECTOR)

/datum/uplink_item/role_restricted/brainwash_disk
	name = "Brainwashing Surgery Program"
	desc = "A disk containing the procedure to perform a brainwashing surgery, allowing you to implant an objective onto a target. \
	Insert into an Operating Console to enable the procedure."
	item = /obj/item/disk/surgery/brainwashing
	restricted_roles = list(JOB_MEDICAL_DOCTOR, JOB_CHIEF_MEDICAL_OFFICER, JOB_CORONER, JOB_ROBOTICIST)
	cost = 5
	surplus = 50

/datum/uplink_item/role_restricted/advanced_plastic_surgery
	name = "Advanced Plastic Surgery Program"
	desc = "A bootleg copy of a collector item, this disk contains the procedure to perform advanced plastic surgery, allowing you to model someone's face and voice based on a picture taken by a camera on your offhand. \
	All changes are superficial and does not change ones genetic makeup. \
	Insert into an Operating Console to enable the procedure."
	item = /obj/item/disk/surgery/advanced_plastic_surgery
	restricted_roles = list(JOB_MEDICAL_DOCTOR, JOB_CHIEF_MEDICAL_OFFICER, JOB_ROBOTICIST)
	cost = 1
	surplus = 50

/datum/uplink_item/role_restricted/springlock_module
	name = "Heavily Modified Springlock MODsuit Module"
	desc = "A module that spans the entire size of the MOD unit, sitting under the outer shell. \
		This mechanical exoskeleton pushes out of the way when the user enters and it helps in booting \
		up, but was taken out of modern suits because of the springlock's tendency to \"snap\" back \
		into place when exposed to humidity. You know what it's like to have an entire exoskeleton enter you? \
		This version of the module has been modified to allow for near instant activation of the MODsuit. \
		Useful for quickly getting your MODsuit on/off, or for taking care of a target via a tragic accident."
	item = /obj/item/mod/module/springlock/bite_of_87
	restricted_roles = list(JOB_ROBOTICIST, JOB_RESEARCH_DIRECTOR)
	cost = 2
	surplus = 15

/datum/uplink_item/role_restricted/reverse_revolver
	name = "Reverse Revolver"
	desc = "A revolver that always fires at its user. \"Accidentally\" drop your weapon, then watch as the greedy corporate pigs blow their own brains all over the wall. \
	The revolver itself is actually real. Only clumsy people, and clowns, can fire it normally. Comes in a box of hugs. Honk."
	cost = 14
	item = /obj/item/storage/box/hug/reverse_revolver
	restricted_roles = list(JOB_CLOWN)

/datum/uplink_item/role_restricted/pressure_mod
	name = "Kinetic Accelerator Pressure Mod"
	desc = "A modification kit which allows Kinetic Accelerators to do greatly increased damage while indoors. \
			Occupies 35% mod capacity."
	item = /obj/item/borg/upgrade/modkit/indoors
	cost = 5 //you need two for full damage, so total of 10 for maximum damage
	limited_stock = 2 //you can't use more than two!
	restricted_roles = list("Shaft Miner")
	surplus = 20

/datum/uplink_item/role_restricted/mimery
	name = "Guide to Advanced Mimery Series"
	desc = "The classical two part series on how to further hone your mime skills. Upon studying the series, the user should be able to make 3x1 invisible walls, and shoot bullets out of their fingers. \
			Obviously only works for Mimes."
	cost = 12
	item = /obj/item/storage/box/syndie_kit/mimery
	restricted_roles = list(JOB_MIME)
	surplus = 0

/datum/uplink_item/role_restricted/laser_arm
	name = "Laser Arm Implant"
	desc = "An implant that grants you a recharging laser gun inside your arm. Weak to EMPs. Comes with a syndicate autosurgeon for immediate self-application."
	cost = 10
	item = /obj/item/autosurgeon/syndicate/laser_arm
	restricted_roles = list(JOB_ROBOTICIST, JOB_RESEARCH_DIRECTOR)
	surplus = 20

/datum/uplink_item/role_restricted/chemical_gun
	name = "Reagent Dartgun"
	desc = "A heavily modified syringe gun which is capable of synthesizing its own chemical darts using input reagents. Can hold 90u of reagents."
	item = /obj/item/gun/chem
	cost = 12
	restricted_roles = list(JOB_CHEMIST, JOB_MEDICAL_DOCTOR, JOB_CHIEF_MEDICAL_OFFICER, JOB_BOTANIST)

/datum/uplink_item/role_restricted/pie_cannon
	name = "Banana Cream Pie Cannon"
	desc = "A special pie cannon for a special clown, this gadget can hold up to 20 pies and automatically fabricates one every two seconds!"
	cost = 10
	item = /obj/item/pneumatic_cannon/pie/selfcharge
	restricted_roles = list(JOB_CLOWN)

/datum/uplink_item/role_restricted/clown_bomb
	name = "Clown Bomb"
	desc = "The Clown bomb is a hilarious device capable of massive pranks. It has an adjustable timer, \
		with a minimum of %MIN_BOMB_TIMER seconds, and can be bolted to the floor with a wrench to prevent \
		movement. The bomb is bulky and cannot be moved; upon ordering this item, a smaller beacon will be \
		transported to you that will teleport the actual bomb to it upon activation. Note that this bomb can \
		be defused, and some crew may attempt to do so."
	progression_minimum = 15 MINUTES
	item = /obj/item/sbeacondrop/clownbomb
	cost = 15
	restricted_roles = list(JOB_CLOWN)
	surplus = 10

/datum/uplink_item/role_restricted/clown_bomb/New()
	. = ..()
	desc = replacetext(desc, "%MIN_BOMB_TIMER", SYNDIEBOMB_MIN_TIMER_SECONDS)

/datum/uplink_item/role_restricted/clowncar
	name = "Clown Car"
	desc = "The Clown Car is the ultimate transportation method for any worthy clown! \
			Simply insert your bikehorn and get in, and get ready to have the funniest ride of your life! \
			You can ram any spacemen you come across and stuff them into your car, kidnapping them and locking them inside until \
			someone saves them or they manage to crawl out. Be sure not to ram into any walls or vending machines, as the springloaded seats \
			are very sensitive. Now with our included lube defense mechanism which will protect you against any angry shitcurity! \
			Premium features can be unlocked with a cryptographic sequencer!"
	item = /obj/vehicle/sealed/car/clowncar
	cost = 20
	restricted_roles = list(JOB_CLOWN)
	surplus = 10

/datum/uplink_item/role_restricted/clowncar/spawn_item_for_generic_use(mob/user)
	var/obj/vehicle/sealed/car/clowncar/car = ..()
	car.enforce_clown_role = FALSE
	var/obj/item/key = new car.key_type(user.loc)
	car.visible_message(span_notice("[key] drops out of [car] onto the floor."))
	return car

/datum/uplink_item/role_restricted/his_grace
	name = "His Grace"
	desc = "An incredibly dangerous weapon recovered from a station overcome by the grey tide. Once activated, He will thirst for blood and must be used to kill to sate that thirst. \
	His Grace grants gradual regeneration and complete stun immunity to His wielder, but be wary: if He gets too hungry, He will become impossible to drop and eventually kill you if not fed. \
	However, if left alone for long enough, He will fall back to slumber. \
	To activate His Grace, simply unlatch Him."
	lock_other_purchases = TRUE
	cant_discount = TRUE
	item = /obj/item/his_grace
	cost = 20
	surplus = 0
	restricted_roles = list(JOB_CHAPLAIN)
	purchasable_from = ~UPLINK_SPY

/datum/uplink_item/role_restricted/concealed_weapon_bay
	name = "Concealed Weapon Bay"
	desc = "A modification for non-combat exosuits that allows them to equip one piece of equipment designed for combat units. \
			Attach to an exosuit with an existing equipment to disguise the bay as that equipment. The sacrificed equipment will be lost.\
			Alternatively, you can attach the bay to an empty equipment slot, but the bay will not be concealed. Once the bay is \
			attached, an exosuit weapon can be fitted inside."
	progression_minimum = 15 MINUTES
	item = /obj/item/mecha_parts/mecha_equipment/concealed_weapon_bay
	cost = 3
	restricted_roles = list(JOB_ROBOTICIST, JOB_RESEARCH_DIRECTOR)
	surplus = 15

/datum/uplink_item/role_restricted/spider_injector
	name = "Australicus Slime Mutator"
	desc = "Crikey mate, it's been a wild travel from the Australicus sector but we've managed to get \
			some special spider extract from the giant spiders down there. Use this injector on a gold slime core \
			to create a few of the same type of spiders we found on the planets over there. They're a bit tame until you \
			also give them a bit of sentience though."
	progression_minimum = 30 MINUTES
	item = /obj/item/reagent_containers/syringe/spider_extract
	cost = 10
	restricted_roles = list(JOB_RESEARCH_DIRECTOR, JOB_SCIENTIST, JOB_ROBOTICIST)
	surplus = 10

/datum/uplink_item/role_restricted/blastcannon
	name = "Blast Cannon"
	desc = "A highly specialized weapon, the Blast Cannon is actually relatively simple. It contains an attachment for a tank transfer valve mounted to an angled pipe specially constructed \
			withstand extreme pressure and temperatures, and has a mechanical trigger for triggering the transfer valve. Essentially, it turns the explosive force of a bomb into a narrow-angle \
			blast wave \"projectile\". Aspiring scientists may find this highly useful, as forcing the pressure shockwave into a narrow angle seems to be able to bypass whatever quirk of physics \
			disallows explosive ranges above a certain distance, allowing for the device to use the theoretical yield of a transfer valve bomb, instead of the factual yield. Its simple design makes it easy to conceal."
	progression_minimum = 30 MINUTES
	item = /obj/item/gun/blastcannon
	cost = 14 //High cost because of the potential for extreme damage in the hands of a skilled scientist.
	restricted_roles = list(JOB_RESEARCH_DIRECTOR, JOB_SCIENTIST)
	surplus = 5

/datum/uplink_item/role_restricted/evil_seedling
	name = "Evil Seedling"
	desc = "A rare seed we have recovered that grows into a dangerous species that will aid you with your tasks!"
	item = /obj/item/seeds/seedling/evil
	cost = 8
	restricted_roles = list(JOB_BOTANIST)

/datum/uplink_item/role_restricted/bee_smoker
	name = "Bee Smoker"
	desc = "A device that runs on cannabis, turning it into a gas that can hypnotize bees to follow our commands."
	item = /obj/item/bee_smoker
	cost = 4
	restricted_roles = list(JOB_BOTANIST)

/datum/uplink_item/role_restricted/monkey_agent
	name = "Simian Agent Reinforcements"
	desc = "Call in an extremely well trained monkey secret agent from our Syndicate Banana Department. \
		They've been trained to operate machinery and can read, but they can't speak Common. \
		Please note that these are free-range monkeys that don't react with Mutadone. May contain severe allergies to species-changing phenomena."
	item = /obj/item/antag_spawner/loadout/monkey_man
	cost = 6
	restricted_roles = list(JOB_RESEARCH_DIRECTOR, JOB_SCIENTIST, JOB_GENETICIST, JOB_ASSISTANT, JOB_MIME, JOB_CLOWN, JOB_PUN_PUN)
	restricted = TRUE
	refundable = TRUE

/datum/uplink_item/role_restricted/monkey_supplies
	name = "Simian Agent Supplies"
	desc = "Sometimes you need a bit more firepower than a rabid monkey. Such as a rabid, armed monkey! \
		Monkeys can unpack this kit to receive a bag with a bargain-bin gun, ammunition, and some miscellaneous supplies."
	item = /obj/item/storage/toolbox/guncase/monkeycase
	cost = 4
	limited_stock = 3
	restricted_roles = list(JOB_ASSISTANT, JOB_MIME, JOB_CLOWN, JOB_PUN_PUN)
	restricted = TRUE
	refundable = FALSE


/datum/uplink_item/role_restricted/reticence
	name = "Reticence Cloaked Assasination exosuit"
	desc = "A silent, fast, and nigh-invisible but exceptionally fragile miming exosuit! \
	fully equipped with a near-silenced pistol, and a RCD for your best assasination needs, Does not include tools, No refunds."
	item = /obj/vehicle/sealed/mecha/reticence/loaded
	cost = 20
	restricted_roles = list(JOB_MIME)
	restricted = TRUE
	refundable = FALSE
	progression_minimum = 30 MINUTES
	purchasable_from = parent_type::purchasable_from & ~UPLINK_SPY

