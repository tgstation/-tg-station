
//Ancient cryogenic sleepers. Players become NT crewmen from a hundred year old space station, now on the verge of collapse.
/obj/effect/mob_spawn/ghost_role/human/oldsec
	name = "old cryogenics pod"
	desc = "A humming cryo pod. You can barely recognise a security uniform underneath the built up ice. The machine is attempting to wake up its occupant."
	prompt_name = "a security officer"
	icon = 'icons/obj/machines/sleeper.dmi'
	icon_state = "sleeper"
	mob_species = /datum/species/human
	you_are_text = "You are a security officer working for Nanotrasen, stationed onboard a state of the art research station."
	flavour_text = "You vaguely recall rushing into a cryogenics pod due to an oncoming radiation storm. \
	The last thing you remember is the station's Artificial Program telling you that you would only be asleep for eight hours. As you open \
	your eyes, everything seems rusted and broken, a dark feeling swells in your gut as you climb out of your pod."
	important_text = "Work as a team with your fellow survivors and do not abandon them."
	outfit = /datum/outfit/oldsec
	spawner_job_path = /datum/job/ancient_crew

/obj/effect/mob_spawn/ghost_role/human/oldsec/Destroy()
	new/obj/structure/showcase/machinery/oldpod/used(drop_location())
	return ..()

/datum/outfit/oldsec
	name = "Ancient Security"
	id = /obj/item/card/id/away/old/sec
	uniform = /obj/item/clothing/under/rank/security/officer
	shoes = /obj/item/clothing/shoes/jackboots
	l_pocket = /obj/item/assembly/flash/handheld
	r_pocket = /obj/item/restraints/handcuffs

/obj/effect/mob_spawn/ghost_role/human/oldeng
	name = "old cryogenics pod"
	desc = "A humming cryo pod. You can barely recognise an engineering uniform underneath the built up ice. The machine is attempting to wake up its occupant."
	prompt_name = "an engineer"
	icon = 'icons/obj/machines/sleeper.dmi'
	icon_state = "sleeper"
	mob_species = /datum/species/human
	you_are_text = "You are an engineer working for Nanotrasen, stationed onboard a state of the art research station."
	flavour_text = "You vaguely recall rushing into a cryogenics pod due to an oncoming radiation storm. The last thing \
	you remember is the station's Artificial Program telling you that you would only be asleep for eight hours. As you open \
	your eyes, everything seems rusted and broken, a dark feeling swells in your gut as you climb out of your pod."
	important_text = "Work as a team with your fellow survivors and do not abandon them."
	outfit = /datum/outfit/oldeng
	spawner_job_path = /datum/job/ancient_crew

/obj/effect/mob_spawn/ghost_role/human/oldeng/Destroy()
	new/obj/structure/showcase/machinery/oldpod/used(drop_location())
	return ..()

/datum/outfit/oldeng
	name = "Ancient Engineer"
	id = /obj/item/card/id/away/old/eng
	uniform = /obj/item/clothing/under/rank/engineering/engineer
	gloves = /obj/item/clothing/gloves/color/fyellow/old
	shoes = /obj/item/clothing/shoes/workboots
	l_pocket = /obj/item/tank/internals/emergency_oxygen

/datum/outfit/oldeng/mod
	name = "Ancient Engineer (MODsuit)"
	suit_store = /obj/item/tank/internals/oxygen
	back = /obj/item/mod/control/pre_equipped/prototype
	mask = /obj/item/clothing/mask/breath
	internals_slot = ITEM_SLOT_SUITSTORE

/obj/effect/mob_spawn/ghost_role/human/oldsci
	name = "old cryogenics pod"
	desc = "A humming cryo pod. You can barely recognise a science uniform underneath the built up ice. The machine is attempting to wake up its occupant."
	prompt_name = "a scientist"
	icon = 'icons/obj/machines/sleeper.dmi'
	icon_state = "sleeper"
	mob_species = /datum/species/human
	you_are_text = "You are a scientist working for Nanotrasen, stationed onboard a state of the art research station."
	flavour_text = "You vaguely recall rushing into a cryogenics pod due to an oncoming radiation storm. \
	The last thing you remember is the station's Artificial Program telling you that you would only be asleep for eight hours. As you open \
	your eyes, everything seems rusted and broken, a dark feeling swells in your gut as you climb out of your pod."
	important_text = "Work as a team with your fellow survivors and do not abandon them."
	outfit = /datum/outfit/oldsci
	spawner_job_path = /datum/job/ancient_crew

/obj/effect/mob_spawn/ghost_role/human/oldsci/Destroy()
	new/obj/structure/showcase/machinery/oldpod/used(drop_location())
	return ..()

/datum/outfit/oldsci
	name = "Ancient Scientist"
	id = /obj/item/card/id/away/old/sci
	uniform = /obj/item/clothing/under/rank/rnd/scientist
	shoes = /obj/item/clothing/shoes/laceup
	l_pocket = /obj/item/stack/medical/bruise_pack

///asteroid comms agent

/obj/effect/mob_spawn/ghost_role/human/lavaland_syndicate/comms/space
	you_are_text = "You are a syndicate agent, assigned to a small listening post station situated near your hated enemy's top secret research facility: Space Station 13."
	flavour_text = "Monitor enemy activity as best you can, and try to keep a low profile. Use the communication equipment to provide support to any field agents, and sow disinformation to throw Nanotrasen off your trail. Do not let the base fall into enemy hands!"
	important_text = "DO NOT abandon the base."

/obj/effect/mob_spawn/ghost_role/human/lavaland_syndicate/comms/space/Initialize(mapload)
	. = ..()
	if(prob(85)) //only has a 15% chance of existing, otherwise it'll just be a NPC syndie.
		new /mob/living/basic/trooper/syndicate/ranged(get_turf(src))
		return INITIALIZE_HINT_QDEL

///battlecruiser stuff

/obj/effect/mob_spawn/ghost_role/human/syndicate/battlecruiser
	name = "Syndicate Battlecruiser Ship Operative"
	you_are_text = "You are a crewmember aboard the syndicate flagship: the SBC Starfury."
	flavour_text = "Your job is to follow your captain's orders, maintain the ship, and keep the power flowing."
	important_text = "The armory is not a candy store, and your role is not to assault the station directly, leave that work to the assault operatives."
	prompt_name = "a battlecruiser crewmember"
	outfit = /datum/outfit/syndicate_empty/battlecruiser
	spawner_job_path = /datum/job/battlecruiser_crew
	uses = 4

	/// The antag team to apply the player to
	var/datum/team/antag_team
	/// The antag datum to give to the player spawned
	var/antag_datum_to_give = /datum/antagonist/battlecruiser

/obj/effect/mob_spawn/ghost_role/human/syndicate/battlecruiser/allow_spawn(mob/user, silent = FALSE)
	if(!(user.ckey in antag_team.players_spawned))
		return TRUE
	if(!silent)
		to_chat(user, span_boldwarning("You have already used up your chance to roll as Battlecruiser."))
	return FALSE

/obj/effect/mob_spawn/ghost_role/human/syndicate/battlecruiser/special(mob/living/spawned_mob, mob/possesser)
	. = ..()
	if(!spawned_mob.mind)
		spawned_mob.mind_initialize()
	var/datum/mind/mob_mind = spawned_mob.mind
	mob_mind.add_antag_datum(antag_datum_to_give, antag_team)
	antag_team.players_spawned += (spawned_mob.ckey)

/datum/outfit/syndicate_empty/battlecruiser
	name = "Syndicate Battlecruiser Ship Operative"
	belt = /obj/item/storage/belt/military/assault
	l_pocket = /obj/item/gun/ballistic/automatic/pistol/clandestine
	r_pocket = /obj/item/knife/combat/survival

	box = /obj/item/storage/box/survival/syndie

/obj/effect/mob_spawn/ghost_role/human/syndicate/battlecruiser/assault
	name = "Syndicate Battlecruiser Assault Operative"
	you_are_text = "You are an assault operative aboard the syndicate flagship: the SBC Starfury."
	flavour_text = "Your job is to follow your captain's orders, keep intruders out of the ship, and assault Space Station 13. There is an armory, multiple assault ships, and beam cannons to attack the station with."
	important_text = "Work as a team with your fellow operatives and work out a plan of attack. If you are overwhelmed, escape back to your ship!"
	prompt_name = "a battlecruiser operative"
	outfit = /datum/outfit/syndicate_empty/battlecruiser/assault
	uses = 8

/datum/outfit/syndicate_empty/battlecruiser/assault
	name = "Syndicate Battlecruiser Assault Operative"
	uniform = /obj/item/clothing/under/syndicate/combat
	suit = /obj/item/clothing/suit/armor/vest
	suit_store = /obj/item/gun/ballistic/automatic/pistol/clandestine
	back = /obj/item/storage/backpack
	belt = /obj/item/storage/belt/military
	mask = /obj/item/clothing/mask/gas/syndicate
	l_pocket = /obj/item/uplink/nuclear
	r_pocket = /obj/item/modular_computer/pda/nukeops

	skillchips = list(/obj/item/skillchip/disk_verifier)

/obj/effect/mob_spawn/ghost_role/human/syndicate/battlecruiser/captain
	name = "Syndicate Battlecruiser Captain"
	you_are_text = "You are the captain aboard the syndicate flagship: the SBC Starfury."
	flavour_text = "Your job is to oversee your crew, defend the ship, and destroy Space Station 13. The ship has an armory, multiple ships, beam cannons, and multiple crewmembers to accomplish this goal."
	important_text = "As the captain, this whole operation falls on your shoulders. Help your assault operatives detonate a nuke on the station."
	prompt_name = "a battlecruiser captain"
	outfit = /datum/outfit/syndicate_empty/battlecruiser/assault/captain
	spawner_job_path = /datum/job/battlecruiser_captain
	antag_datum_to_give = /datum/antagonist/battlecruiser/captain
	uses = 1

/datum/outfit/syndicate_empty/battlecruiser/assault/captain
	name = "Syndicate Battlecruiser Captain"
	id = /obj/item/card/id/advanced/black/syndicate_command/captain_id
	id_trim = /datum/id_trim/battlecruiser/captain
	suit = /obj/item/clothing/suit/armor/vest/capcarapace/syndicate
	suit_store = /obj/item/gun/ballistic/revolver/mateba
	back = /obj/item/storage/backpack/satchel/leather
	ears = /obj/item/radio/headset/syndicate/alt/leader
	glasses = /obj/item/clothing/glasses/thermal/eyepatch
	head = /obj/item/clothing/head/hats/hos/cap/syndicate
	mask = /obj/item/cigarette/cigar/havana
	l_pocket = /obj/item/melee/energy/sword/saber/red
	r_pocket = /obj/item/melee/baton/telescopic

//film studio space ruins, actors and such.
/obj/effect/mob_spawn/ghost_role/human/actor
	name = "cryogenics pod"
	desc = "A humming cryo pod. You recognize the person inside as a local celebrity of sort."
	prompt_name = "a actor"
	icon = 'icons/obj/machines/sleeper.dmi'
	icon_state = "sleeper"
	mob_species = /datum/species/human
	you_are_text = "You are an actor/actress working for Sophronia Broadcasting Inc., stationed onboard the local TV studio."
	flavour_text = "You last remember corporate told everyone to go to cryosleep for whatever reason, where did everyone else go?"
	important_text = "Work as a team with your fellow actors and the director to make entertainment for the massses."
	outfit = /datum/outfit/actor
	spawner_job_path = /datum/job/ghost_role

/datum/outfit/actor
	name = "Actor"
	id = /obj/item/card/id/away/filmstudio
	id_trim= /datum/id_trim/away/actor
	ears = /obj/item/radio/headset
	uniform = /obj/item/clothing/under/suit/charcoal
	back = /obj/item/storage/backpack/satchel
	shoes = /obj/item/clothing/shoes/laceup
	l_pocket = /obj/item/clothing/mask/chameleon
	r_pocket = /obj/item/card/id/advanced/chameleon

/obj/effect/mob_spawn/ghost_role/human/director
	name = "cryogenics pod"
	desc = "A humming cryo pod. You recognize the person inside as a local celebrity of sort."
	prompt_name = "a director"
	icon = 'icons/obj/machines/sleeper.dmi'
	icon_state = "sleeper"
	mob_species = /datum/species/human
	you_are_text = "You are a director working for Sophronia Broadcasting Inc., stationed onboard the local TV studio."
	flavour_text = "You just got hired to direct shows and entertainment for a local tv studio, make do with your team and produce something!"
	important_text = "Work as a team with your fellow actors and the director to make entertainment for the masses."
	outfit = /datum/outfit/actor/director
	spawner_job_path = /datum/job/ghost_role

/datum/outfit/actor/director
	name = "Director"
	id_trim = /datum/id_trim/away/director
	uniform = /obj/item/clothing/under/suit/red
	head = /obj/item/clothing/head/frenchberet
