#define TAB_POD 0 //Used to check if the UIs built in camera is looking at the pod
#define TAB_BAY 1 //Used to check if the UIs built in camera is looking at the launch bay area

#define LAUNCH_ALL 0 //Used to check if we're launching everything from the bay area at once
#define LAUNCH_ORDERED 1 //Used to check if we're launching everything from the bay area in order
#define LAUNCH_RANDOM 2 //Used to check if we're launching everything from the bay area randomly

//The Great and Mighty CentCom Pod Launcher - MrDoomBringer
//This was originally created as a way to get adminspawned items to the station in an IC manner. It's evolved to contain a few more
//features such as item removal, smiting, controllable delivery mobs, and more.

//This works by creating a supplypod (refered to as temp_pod) in a special room in the centcom map.
//IMPORTANT: Even though we call it a supplypod for our purposes, it can take on the appearance and function of many other things: Eg. cruise missiles, boxes, or walking, living gondolas.
//When the user launched the pod, items from special "bays" on the centcom map are taken and put into the supplypod

//The user can change properties of the supplypod using the UI, and change the way that items are taken from the bay (One at a time, ordered, random, etc)
//Many of the effects of the supplypod set here are put into action in supplypod.dm

ADMIN_VERB(centcom_podlauncher, R_ADMIN, "Config/Launch Supplypod", "Configure and launch a CentCom supplypod full of whatever your heart desires!", ADMIN_CATEGORY_EVENTS)
	new /datum/centcom_podlauncher(user.mob)

//Variables declared to change how items in the launch bay are picked and launched. (Almost) all of these are changed in the ui_act proc
//Some effect groups are choices, while other are booleans. This is because some effects can stack, while others dont (ex: you can stack explosion and quiet, but you cant stack ordered launch and random launch)
/datum/centcom_podlauncher
	/// Static typecache of atoms we won't lift up, or pod or whatever.
	var/static/list/ignored_atoms = typecacheof(list(
		null, // I don't know why null is the first element of this typepache but it was there when I found it
		/mob/dead,
		/obj/effect/landmark,
		/obj/docking_port,
		/obj/effect/particle_effect/sparks,
		/obj/effect/pod_landingzone,
		/obj/effect/client_image_holder,
		/obj/effect/light_emitter/podbay,
	))

	var/turf/oldTurf //Keeps track of where the user was at if they use the "teleport to centcom" button, so they can go back
	var/client/holder //client of whoever is using this datum
	var/area/centcom/central_command_areas/supplypod/loading/bay //What bay we're using to launch shit from.
	var/bayNumber //Quick reference to what bay we're in. Usually set to the loading_id variable for the related area type
	var/customDropoff = FALSE
	var/picking_dropoff_turf = FALSE
	var/launchClone = FALSE //If true, then we don't actually launch the thing in the bay. Instead we call duplicate_object() and send the result
	var/launchRandomItem = FALSE //If true, lauches a single random item instead of everything on a turf.
	var/launchChoice = LAUNCH_RANDOM //Determines if we launch all at once (0) , in order (1), or at random(2)
	var/explosionChoice = 0 //Determines if there is no explosion (0), custom explosion (1), or just do a maxcap (2)
	var/damageChoice = 0 //Determines if we do no damage (0), custom amnt of damage (1), or gib + 5000dmg (2)
	var/launcherActivated = FALSE //check if we've entered "launch mode" (when we click a pod is launched). Used for updating mouse cursor
	var/effectBurst = FALSE //Effect that launches 5 at once in a 3x3 area centered on the target
	var/effectAnnounce = TRUE
	var/numTurfs = 0 //Counts the number of turfs with things we can launch in the chosen bay (in the centcom map)
	var/launchCounter = 1 //Used with the "Ordered" launch mode (launchChoice = 1) to see what item is launched
	var/atom/specificTarget //Do we want to target a specific mob instead of where we click? Also used for smiting
	var/list/orderedArea = list() //Contains an ordered list of turfs in an area (filled in the createOrderedArea() proc), read top-left to bottom-right. Used for the "ordered" launch mode (launchChoice = 1)
	var/list/turf/acceptableTurfs = list() //Contians a list of turfs (in the "bay" area on centcom) that have items that can be launched. Taken from orderedArea
	var/list/launchList = list() //Contains whatever is going to be put in the supplypod and fired. Taken from acceptableTurfs

	/// An effect used for showing where a reverse pod will land
	var/obj/effect/client_image_holder/dropoff_location/indicator
	/// An effect used for keeping track of what item is going to be launched next when in "ordered" mode (launchChoice = 1)
	var/obj/effect/client_image_holder/supplypod_selector/selector

	var/obj/structure/closet/supplypod/centcompod/temp_pod //The temporary pod that is modified by this datum, then cloned. The buildObject() clone of this pod is what is launched
	// Stuff needed to render the map
	var/map_name
	var/atom/movable/screen/map_view/cam_screen
	var/atom/movable/screen/background/cam_background
	var/tabIndex = 1
	var/renderLighting = FALSE
	var/static/list/pod_style_info
	var/static/list/pod_style_lookup

/datum/centcom_podlauncher/New(user) //user can either be a client or a mob
	if (user) //Prevents runtimes on datums being made without clients
		setup(user)
	if (!isnull(pod_style_info))
		return
	pod_style_info = list()
	pod_style_lookup = list()
	for (var/datum/pod_style/style as anything in typesof(/datum/pod_style))
		pod_style_info += list(list("id" = style::id, "title" = style::ui_name))
		pod_style_lookup[style::id] = style

/datum/centcom_podlauncher/proc/setup(user) //H can either be a client or a mob
	if (istype(user,/client))
		var/client/user_client = user
		holder = user_client //if its a client, assign it to holder
	else
		var/mob/user_mob = user
		holder = user_mob.client //if its a mob, assign the mob's client to holder
	bay = locate(/area/centcom/central_command_areas/supplypod/loading/one) in GLOB.areas //Locate the default bay (one) from the centcom map
	bayNumber = bay.loading_id //Used as quick reference to what bay we're taking items from
	var/area/pod_storage_area = locate(/area/centcom/central_command_areas/supplypod/pod_storage) in GLOB.areas
	temp_pod = new(pick(get_area_turfs(pod_storage_area))) //Create a new temp_pod in the podStorage area on centcom (so users are free to look at it and change other variables if needed)
	orderedArea = createOrderedArea(bay) //Order all the turfs in the selected bay (top left to bottom right) to a single list. Used for the "ordered" mode (launchChoice = 1)
	selector = new(null, holder.mob)
	indicator = new(null, holder.mob)
	setDropoff(bay)
	initMap()
	refreshBay()
	ui_interact(holder.mob)

/datum/centcom_podlauncher/proc/initMap()
	if(map_name)
		holder.clear_map(map_name)

	map_name = "admin_supplypod_bay_[REF(src)]_map"
	// Initialize map objects
	cam_screen = new
	cam_screen.generate_view(map_name)

	var/datum/plane_master_group/planes = cam_screen.display_to(holder.mob)

	if(!renderLighting)
		for(var/atom/movable/screen/plane_master/instance as anything in holder.mob.hud_used.get_true_plane_masters(LIGHTING_PLANE, planes.key))
			instance.set_alpha(100)

	cam_background = new
	cam_background.assigned_map = map_name
	cam_background.del_on_map_removal = TRUE
	refreshView()
	holder.register_map_obj(cam_background)

/datum/centcom_podlauncher/ui_state(mob/user)
	if (SSticker.current_state >= GAME_STATE_FINISHED)
		return GLOB.always_state //Allow the UI to be given to players by admins after roundend
	return ADMIN_STATE(R_ADMIN)

/datum/centcom_podlauncher/ui_assets(mob/user)
	return list(
		get_asset_datum(/datum/asset/spritesheet/supplypods),
	)

/datum/centcom_podlauncher/ui_interact(mob/user, datum/tgui/ui)
	ui = SStgui.try_update_ui(user, src, ui)
	if(!ui)
		// Open UI
		ui = new(user, src, "CentcomPodLauncher")
		ui.open()
		refreshView()

/datum/centcom_podlauncher/ui_static_data(mob/user)
	var/list/data = list()
	data["mapRef"] = map_name
	data["defaultSoundVolume"] = initial(temp_pod.soundVolume) //default volume for pods
	data["podStyles"] = pod_style_info
	return data

/datum/centcom_podlauncher/ui_data(mob/user) //Sends info about the pod to the UI.
	var/list/data = list() //*****NOTE*****: Many of these comments are similarly described in supplypod.dm. If you change them here, please consider doing so in the supplypod code as well!
	bayNumber = bay?.loading_id //Used as quick reference to what bay we're taking items from
	data["bayNumber"] = bayNumber //Holds the bay as a number. Useful for comparisons in centcom_podlauncher.ract
	data["oldArea"] = (oldTurf ? get_area(oldTurf) : null) //Holds the name of the area that the user was in before using the teleportCentcom action
	data["picking_dropoff_turf"] = picking_dropoff_turf //If we're picking or have picked a dropoff turf. Only works when pod is in reverse mode
	data["customDropoff"] = customDropoff
	data["renderLighting"] = renderLighting
	data["launchClone"] = launchClone //Do we launch the actual items in the bay or just launch clones of them?
	data["launchRandomItem"] = launchRandomItem //Do we launch a single random item instead of everything on the turf?
	data["launchChoice"] = launchChoice //Launch turfs all at once (0), ordered (1), or randomly(1)
	data["explosionChoice"] = explosionChoice //An explosion that occurs when landing. Can be no explosion (0), custom explosion (1), or maxcap (2)
	data["damageChoice"] = damageChoice //Damage that occurs to any mob under the pod when it lands. Can be no damage (0), custom damage (1), or gib+5000dmg (2)
	data["delays"] = temp_pod.delays
	data["rev_delays"] = temp_pod.reverse_delays
	data["custom_rev_delay"] = temp_pod.custom_rev_delay
	data["styleChoice"] = temp_pod.style::id //Style is a variable that keeps track of what the pod is supposed to look like.
	data["effectShrapnel"] = temp_pod.effectShrapnel //If true, creates a cloud of shrapnel of a decided type and magnitude on landing
	data["shrapnelType"] = "[temp_pod.shrapnel_type]" //Path2String
	data["shrapnelMagnitude"] = temp_pod.shrapnel_magnitude
	data["effectStun"] = temp_pod.effectStun //If true, stuns anyone under the pod when it launches until it lands, forcing them to get hit by the pod. Devilish!
	data["effectLimb"] = temp_pod.effectLimb //If true, pops off a limb (if applicable) from anyone caught under the pod when it lands
	data["effectOrgans"] = temp_pod.effectOrgans //If true, yeets the organs out of any bodies caught under the pod when it lands
	data["effectBluespace"] = temp_pod.bluespace //If true, the pod deletes (in a shower of sparks) after landing
	data["effectStealth"] = temp_pod.effectStealth //If true, a target icon isn't displayed on the turf where the pod will land
	data["effectQuiet"] = temp_pod.effectQuiet //The female sniper. If true, the pod makes no noise (including related explosions, opening sounds, etc)
	data["effectMissile"] = temp_pod.effectMissile //If true, the pod deletes the second it lands. If you give it an explosion, it will act like a missile exploding as it hits the ground
	data["effectCircle"] = temp_pod.effectCircle //If true, allows the pod to come in at any angle. Bit of a weird feature but whatever its here
	data["effectBurst"] = effectBurst //IOf true, launches five pods at once (with a very small delay between for added coolness), in a 3x3 area centered around the area
	data["effectReverse"] = temp_pod.reversing //If true, the pod will not send any items. Instead, after opening, it will close again (picking up items/mobs) and fly back to centcom
	data["create_sparks"] = temp_pod.create_sparks //If true, the pod will create sparks before being deleted. This might cause fires if there is plasma in the air.
	data["reverse_option_list"] = temp_pod.reverse_option_list
	data["effectTarget"] = specificTarget //Launches the pod at the turf of a specific mob target, rather than wherever the user clicked. Useful for smites
	data["effectName"] = temp_pod.adminNamed //Determines whether or not the pod has been named by an admin. If true, the pod's name will not get overridden when the style of the pod changes (changing the style of the pod normally also changes the name+desc)
	data["podName"] = temp_pod.name
	data["podDesc"] = temp_pod.desc
	data["effectAnnounce"] = effectAnnounce
	data["giveLauncher"] = launcherActivated //If true, the user is in launch mode, and whenever they click a pod will be launched (either at their mouse position or at a specific target)
	data["numObjects"] = numTurfs //Counts the number of turfs that contain a launchable object in the centcom supplypod bay
	data["fallingSound"] = temp_pod.fallingSound != initial(temp_pod.fallingSound)//Admin sound to play as the pod falls
	data["landingSound"] = temp_pod.landingSound //Admin sound to play when the pod lands
	data["openingSound"] = temp_pod.openingSound //Admin sound to play when the pod opens
	data["leavingSound"] = temp_pod.leavingSound //Admin sound to play when the pod leaves
	data["soundVolume"] = temp_pod.soundVolume //Admin sound to play when the pod leaves
	return data

/datum/centcom_podlauncher/ui_act(action, list/params, datum/tgui/ui, datum/ui_state/state)
	. = ..()
	if(.)
		return
	switch(action)
		////////////////////////////UTILITIES//////////////////
		if("gamePanel")
			holder.holder.Game()
			BLACKBOX_LOG_ADMIN_VERB("Game Panel")
			. = TRUE
		if("buildMode")
			var/mob/holder_mob = holder.mob
			if (holder_mob && (holder.holder?.rank_flags() & R_BUILD))
				togglebuildmode(holder_mob)
				BLACKBOX_LOG_ADMIN_VERB("Toggle Build Mode")
			. = TRUE
		if("loadDataFromPreset")
			var/list/savedData = params["payload"]
			loadData(savedData)
			. = TRUE
		if("switchBay")
			bayNumber = params["bayNumber"]
			refreshBay()
			. = TRUE
		if("pickDropoffTurf") //Enters a mode that lets you pick the dropoff location for reverse pods
			if (picking_dropoff_turf)
				picking_dropoff_turf = FALSE
				updateCursor() //Update the cursor of the user to a cool looking target icon
				return
			if (launcherActivated)
				launcherActivated = FALSE //We don't want to have launch mode enabled while we're picking a turf
			picking_dropoff_turf = TRUE
			updateCursor() //Update the cursor of the user to a cool looking target icon
			. = TRUE
		if("clearDropoffTurf")
			setDropoff(bay)
			customDropoff = FALSE
			picking_dropoff_turf = FALSE
			updateCursor()
			. = TRUE
		if("teleportDropoff") //Teleports the user to the dropoff point.
			var/mob/M = holder.mob //We teleport whatever mob the client is attached to at the point of clicking
			var/turf/current_location = get_turf(M)
			var/list/coordinate_list = temp_pod.reverse_dropoff_coords
			var/turf/dropoff_turf = locate(coordinate_list[1], coordinate_list[2], coordinate_list[3])
			if (current_location != dropoff_turf)
				oldTurf = current_location
			M.forceMove(dropoff_turf) //Perform the actual teleport
			log_admin("[key_name(usr)] jumped to [AREACOORD(dropoff_turf)]")
			message_admins("[key_name_admin(usr)] jumped to [AREACOORD(dropoff_turf)]")
			. = TRUE
		if("teleportCentcom") //Teleports the user to the centcom supply loading facility.
			var/mob/holder_mob = holder.mob //We teleport whatever mob the client is attached to at the point of clicking
			var/turf/current_location = get_turf(holder_mob)
			var/area/bay_area = bay
			if (current_location.loc != bay_area)
				oldTurf = current_location
			var/turf/teleport_turf = pick(get_area_turfs(bay_area))
			holder_mob.forceMove(teleport_turf) //Perform the actual teleport
			if (holder.holder)
				log_admin("[key_name(usr)] jumped to [AREACOORD(teleport_turf)]")
				message_admins("[key_name_admin(usr)] jumped to [AREACOORD(teleport_turf)]")
			. = TRUE
		if("teleportBack") //After teleporting to centcom/dropoff, this button allows the user to teleport to the last spot they were at.
			var/mob/M = holder.mob
			if (!oldTurf) //If theres no turf to go back to, error and cancel
				to_chat(M, "Nowhere to jump to!")
				return
			M.forceMove(oldTurf) //Perform the actual teleport
			if (holder.holder)
				log_admin("[key_name(usr)] jumped to [AREACOORD(oldTurf)]")
				message_admins("[key_name_admin(usr)] jumped to [AREACOORD(oldTurf)]")
			. = TRUE

		////////////////////////////LAUNCH STYLE CHANGES//////////////////
		if("launchClone") //Toggles the launchClone var. See variable declarations above for what this specifically means
			launchClone = !launchClone
			. = TRUE
		if("launchRandomItem") //Pick random turfs from the supplypod bay at centcom to launch
			launchRandomItem = TRUE
			. = TRUE
		if("launchWholeTurf") //Pick random turfs from the supplypod bay at centcom to launch
			launchRandomItem = FALSE
			. = TRUE
		if("launchAll") //Launch turfs (from the orderedArea list) all at once, from the supplypod bay at centcom
			launchChoice = LAUNCH_ALL
			updateSelector()
			. = TRUE
		if("launchOrdered") //Launch turfs (from the orderedArea list) one at a time in order, from the supplypod bay at centcom
			launchChoice = LAUNCH_ORDERED
			updateSelector()
			. = TRUE
		if("launchRandomTurf") //Pick random turfs from the supplypod bay at centcom to launch
			launchChoice = LAUNCH_RANDOM
			updateSelector()
			. = TRUE

		////////////////////////////POD EFFECTS//////////////////
		if("explosionCustom") //Creates an explosion when the pod lands
			if (explosionChoice == 1) //If already a custom explosion, set to default (no explosion)
				explosionChoice = 0
				temp_pod.explosionSize = list(0,0,0,0)
				return
			var/list/expNames = list("Devastation", "Heavy Damage", "Light Damage", "Flame") //Explosions have a range of different types of damage
			var/list/boomInput = list()
			for (var/i=1 to length(expNames)) //Gather input from the user for the value of each type of damage
				boomInput.Add(input("Enter the [expNames[i]] range of the explosion. WARNING: This ignores the bomb cap!", "[expNames[i]] Range",  0) as null|num)
				if (isnull(boomInput[i]))
					return
				if (!isnum(boomInput[i])) //If the user doesn't input a number, set that specific explosion value to zero
					tgui_alert(usr, "That wasn't a number! Value set to default (zero) instead.")
					boomInput[i] = 0
			explosionChoice = 1
			temp_pod.explosionSize = boomInput
			. = TRUE
		if("explosionBus") //Creates a maxcap when the pod lands
			if (explosionChoice == 2) //If already a maccap, set to default (no explosion)
				explosionChoice = 0
				temp_pod.explosionSize = list(0,0,0,0)
				return
			explosionChoice = 2
			temp_pod.explosionSize = list(GLOB.MAX_EX_DEVESTATION_RANGE, GLOB.MAX_EX_HEAVY_RANGE, GLOB.MAX_EX_LIGHT_RANGE,GLOB.MAX_EX_FLAME_RANGE) //Set explosion to max cap of server
			. = TRUE
		if("damageCustom") //Deals damage to whoevers under the pod when it lands
			if (damageChoice == 1) //If already doing custom damage, set back to default (no damage)
				damageChoice = 0
				temp_pod.damage = 0
				return
			var/damageInput = input("Enter the amount of brute damage dealt by getting hit","How much damage to deal",  0) as null|num
			if (isnull(damageInput))
				return
			if (!isnum(damageInput)) //Sanitize the input for damage to deal.s
				tgui_alert(usr, "That wasn't a number! Value set to default (zero) instead.")
				damageInput = 0
			damageChoice = 1
			temp_pod.damage = damageInput
			. = TRUE
		if("damageGib") //Gibs whoever is under the pod when it lands. Also deals 5000 damage, just to be sure.
			if (damageChoice == 2) //If already gibbing, set back to default (no damage)
				damageChoice = 0
				temp_pod.damage = 0
				temp_pod.effectGib = FALSE
				return
			damageChoice = 2
			temp_pod.damage = 5000
			temp_pod.effectGib = TRUE //Gibs whoever is under the pod when it lands
			. = TRUE
		if("effectName") //Give the supplypod a custom name. Supplypods automatically get their name based on their style (see supplypod/setStyle() proc), so doing this overrides that.
			if (temp_pod.adminNamed) //If we're already adminNamed, set the name of the pod back to default
				temp_pod.adminNamed = FALSE
				temp_pod.setStyle(temp_pod.style) //This resets the name of the pod based on its current style (see supplypod/setStyle() proc)
				return
			var/nameInput= tgui_input_text(usr, "Enter a custom name", "Custom name", temp_pod.style::name, max_length = MAX_NAME_LEN)
			if (isnull(nameInput))
				return
			var/descInput = tgui_input_text(usr, "Enter a custom desc", "Custom description", temp_pod.style::desc, max_length = MAX_DESC_LEN)
			if (isnull(descInput))
				return
			temp_pod.name = nameInput
			temp_pod.desc = descInput
			temp_pod.adminNamed = TRUE //This variable is checked in the supplypod/setStyle() proc
			. = TRUE
		if("effectShrapnel") //Creates a cloud of shrapnel on landing
			if (temp_pod.effectShrapnel == TRUE) //If already doing custom damage, set back to default (no shrapnel)
				temp_pod.effectShrapnel = FALSE
				return
			var/shrapnelInput = input("Please enter the type of pellet cloud you'd like to create on landing (Can be any projectile!)", "Projectile Typepath",  0) in sort_list(subtypesof(/obj/projectile), GLOBAL_PROC_REF(cmp_typepaths_asc))
			if (isnull(shrapnelInput))
				return
			var/shrapnelMagnitude = input("Enter the magnitude of the pellet cloud. This is usually a value around 1-5. Please note that Ryll-Ryll has asked me to tell you that if you go too crazy with the projectiles you might crash the server. So uh, be gentle!", "Shrapnel Magnitude", 0) as null|num
			if (isnull(shrapnelMagnitude))
				return
			if (!isnum(shrapnelMagnitude))
				tgui_alert(usr, "That wasn't a number! Value set to 3 instead.")
				shrapnelMagnitude = 3
			temp_pod.shrapnel_type = shrapnelInput
			temp_pod.shrapnel_magnitude = shrapnelMagnitude
			temp_pod.effectShrapnel = TRUE
			. = TRUE
		if("effectStun") //Toggle: Any mob under the pod is stunned (cant move) until the pod lands, hitting them!
			temp_pod.effectStun = !temp_pod.effectStun
			. = TRUE
		if("effectLimb") //Toggle: Anyone carbon mob under the pod loses a limb when it lands
			temp_pod.effectLimb = !temp_pod.effectLimb
			. = TRUE
		if("effectOrgans") //Toggle: Anyone carbon mob under the pod loses a limb when it lands
			temp_pod.effectOrgans = !temp_pod.effectOrgans
			. = TRUE
		if("effectBluespace") //Toggle: Deletes the pod after landing
			temp_pod.bluespace = !temp_pod.bluespace
			. = TRUE
		if("effectStealth") //Toggle: There is no red target indicator showing where the pod will land
			temp_pod.effectStealth = !temp_pod.effectStealth
			. = TRUE
		if("effectQuiet") //Toggle: The pod makes no noise (explosions, opening sounds, etc)
			temp_pod.effectQuiet = !temp_pod.effectQuiet
			. = TRUE
		if("effectMissile") //Toggle: The pod deletes the instant it lands. Looks nicer than just setting the open delay and leave delay to zero. Useful for combo-ing with explosions
			temp_pod.effectMissile = !temp_pod.effectMissile
			. = TRUE
		if("effectCircle") //Toggle: The pod can come in from any descent angle. Goof requested this im not sure why but it looks p funny actually
			temp_pod.effectCircle = !temp_pod.effectCircle
			. = TRUE
		if("effectBurst") //Toggle: Launch 5 pods (with a very slight delay between) in a 3x3 area centered around the target
			effectBurst = !effectBurst
			. = TRUE
		if("effectAnnounce") //Toggle: Launch 5 pods (with a very slight delay between) in a 3x3 area centered around the target
			effectAnnounce = !effectAnnounce
			. = TRUE
		if("effectReverse") //Toggle: Don't send any items. Instead, after landing, close (taking any objects inside) and go back to the centcom bay it came from
			temp_pod.reversing = !temp_pod.reversing
			if (temp_pod.reversing)
				indicator.alpha = 150
			else
				indicator.alpha = 0
			. = TRUE
		if("reverseOption")
			var/reverseOption = params["reverseOption"]
			temp_pod.reverse_option_list[reverseOption] = !temp_pod.reverse_option_list[reverseOption]
			. = TRUE
		if("create_sparks") //Toggle: The creates sparks before the pod is deleted
			temp_pod.create_sparks = !temp_pod.create_sparks
			. = TRUE
		if("effectTarget") //Toggle: Launch at a specific mob (instead of at whatever turf you click on). Used for the supplypod smite
			if (specificTarget)
				specificTarget = null
				return

			var/list/possible_destinations = SSpoints_of_interest.get_mob_pois()
			var/target = tgui_input_list(usr, "Select a mob! (Smiting does this automatically)", "Target", possible_destinations)

			if (isnull(target))
				return

			var/mob/mob_target = possible_destinations[target]

			// During the break between opening the input menu and selecting our target, has this become an invalid option?
			if(!SSpoints_of_interest.is_valid_poi(mob_target))
				return

			specificTarget = mob_target

			. = TRUE
		////////////////////////////TIMER DELAYS//////////////////
		if("editTiming") //Change the different timers relating to the pod
			var/delay = params["timer"]
			var/value = params["value"]
			var/reverse = params["reverse"]
			if (reverse)
				temp_pod.reverse_delays[delay] = value * 10
			else
				temp_pod.delays[delay] = value * 10
			. = TRUE
		if("resetTiming")
			temp_pod.delays = list(POD_TRANSIT = 20, POD_FALLING = 4, POD_OPENING = 30, POD_LEAVING = 30)
			temp_pod.reverse_delays = list(POD_TRANSIT = 20, POD_FALLING = 4, POD_OPENING = 30, POD_LEAVING = 30)
			. = TRUE
		if("toggleRevDelays")
			temp_pod.custom_rev_delay = !temp_pod.custom_rev_delay
			. = TRUE
		////////////////////////////ADMIN SOUNDS//////////////////
		if("fallingSound") //Admin sound from a local file that plays when the pod lands
			if ((temp_pod.fallingSound) != initial(temp_pod.fallingSound))
				temp_pod.fallingSound = initial(temp_pod.fallingSound)
				temp_pod.fallingSoundLength = initial(temp_pod.fallingSoundLength)
				return
			var/soundInput = input(holder, "Please pick a sound file to play when the pod lands! Sound will start playing and try to end when the pod lands", "Pick a Sound File") as null|sound
			if (isnull(soundInput))
				return
			var/sound/tempSound = sound(soundInput)
			playsound(holder.mob, tempSound, 1)
			var/list/sounds_list = holder.SoundQuery()
			var/soundLen = 0
			for (var/playing_sound in sounds_list)
				if (isnull(playing_sound))
					stack_trace("client.SoundQuery() Returned a list containing a null sound! Somehow!")
					continue
				var/sound/found = playing_sound
				if (found.file == tempSound.file)
					soundLen = length(found)
			if (!soundLen)
				soundLen = input(holder, "Couldn't auto-determine sound file length. What is the exact length of the sound file, in seconds. This number will be used to line the sound up so that it finishes right as the pod lands!", "Pick a Sound File", 0.3) as null|num
				if (isnull(soundLen))
					return
				if (!isnum(soundLen))
					tgui_alert(usr, "That wasn't a number! Value set to default ([initial(temp_pod.fallingSoundLength)*0.1]) instead.")
			temp_pod.fallingSound = soundInput
			temp_pod.fallingSoundLength = 10 * soundLen
			. = TRUE
		if("landingSound") //Admin sound from a local file that plays when the pod lands
			if (!isnull(temp_pod.landingSound))
				temp_pod.landingSound = null
				return
			var/soundInput = input(holder, "Please pick a sound file to play when the pod lands! I reccomend a nice \"oh shit, i'm sorry\", incase you hit someone with the pod.", "Pick a Sound File") as null|sound
			if (isnull(soundInput))
				return
			temp_pod.landingSound = soundInput
			. = TRUE
		if("openingSound") //Admin sound from a local file that plays when the pod opens
			if (!isnull(temp_pod.openingSound))
				temp_pod.openingSound = null
				return
			var/soundInput = input(holder, "Please pick a sound file to play when the pod opens! I reccomend a stock sound effect of kids cheering at a party, incase your pod is full of fun exciting stuff!", "Pick a Sound File") as null|sound
			if (isnull(soundInput))
				return
			temp_pod.openingSound = soundInput
			. = TRUE
		if("leavingSound") //Admin sound from a local file that plays when the pod leaves
			if (!isnull(temp_pod.leavingSound))
				temp_pod.leavingSound = null
				return
			var/soundInput = input(holder, "Please pick a sound file to play when the pod leaves! I reccomend a nice slide whistle sound, especially if you're using the reverse pod effect.", "Pick a Sound File") as null|sound
			if (isnull(soundInput))
				return
			temp_pod.leavingSound = soundInput
			. = TRUE
		if("soundVolume") //Admin sound from a local file that plays when the pod leaves
			if (temp_pod.soundVolume != initial(temp_pod.soundVolume))
				temp_pod.soundVolume = initial(temp_pod.soundVolume)
				return
			var/soundInput = input(holder, "Please pick a volume. Default is between 1 and 100 with 50 being average, but pick whatever. I'm a notification, not a cop. If you still cant hear your sound, consider turning on the Quiet effect. It will silence all pod sounds except for the custom admin ones set by the previous three buttons.", "Pick Admin Sound Volume") as null|num
			if (isnull(soundInput))
				return
			temp_pod.soundVolume = soundInput
			. = TRUE
		////////////////////////////STYLE CHANGES//////////////////
		//as a way to get the proper icon state, name, and description of the pod.
		if("tabSwitch")
			tabIndex = params["tabIndex"]
			refreshView()
			. = TRUE
		if("refreshView")
			initMap()
			refreshView()
			. = TRUE
		if("renderLighting")
			renderLighting = !renderLighting
			. = TRUE
		if("setStyle")
			var/chosenStyle = params["style"]
			temp_pod.setStyle(pod_style_lookup[chosenStyle])
			. = TRUE
		if("refresh") //Refresh the Pod bay. User should press this if they spawn something new in the centcom bay. Automatically called whenever the user launches a pod
			refreshBay()
			. = TRUE
		if("giveLauncher") //Enters the "Launch Mode". When the launcher is activated, temp_pod is cloned, and the result it filled and launched anywhere the user clicks (unless specificTarget is true)
			launcherActivated = !launcherActivated
			if (picking_dropoff_turf)
				picking_dropoff_turf = FALSE //We don't want to have launch mode enabled while we're picking a turf
			updateCursor() //Update the cursor of the user to a cool looking target icon
			updateSelector()
			. = TRUE
		if("clearBay") //Delete all mobs and objs in the selected bay
			if(tgui_alert(usr, "This will delete all objs and mobs in [bay]. Are you sure?", "Confirmation", list("Delete that shit", "No")) == "Delete that shit")
				clearBay()
				refreshBay()
			. = TRUE

/datum/centcom_podlauncher/ui_close(mob/user) //Uses the destroy() proc. When the user closes the UI, we clean up the temp_pod and supplypod_selector variables.
	QDEL_NULL(temp_pod)
	QDEL_NULL(cam_screen)
	QDEL_NULL(cam_background)
	qdel(src)

/datum/centcom_podlauncher/proc/setupViewPod()
	setupView(RANGE_TURFS(2, temp_pod))

/datum/centcom_podlauncher/proc/setupViewBay()
	var/list/visible_turfs = list()
	for(var/turf/bay_turf in bay)
		visible_turfs += bay_turf
	setupView(visible_turfs)

/datum/centcom_podlauncher/proc/setupViewDropoff()
	var/list/coords_list = temp_pod.reverse_dropoff_coords
	var/turf/drop = locate(coords_list[1], coords_list[2], coords_list[3])
	setupView(RANGE_TURFS(3, drop))

/datum/centcom_podlauncher/proc/setupView(list/visible_turfs)
	var/list/bbox = get_bbox_of_atoms(visible_turfs)
	var/size_x = bbox[3] - bbox[1] + 1
	var/size_y = bbox[4] - bbox[2] + 1

	cam_screen.vis_contents = visible_turfs
	cam_background.icon_state = "clear"
	cam_background.fill_rect(1, 1, size_x, size_y)

/datum/centcom_podlauncher/proc/updateCursor(forceClear = FALSE) //Update the mouse of the user
	if (!holder) //Can't update the mouse icon if the client doesnt exist!
		return
	if (!forceClear && (launcherActivated || picking_dropoff_turf)) //If the launching param is true, we give the user new mouse icons.
		if(launcherActivated)
			holder.mouse_up_icon = 'icons/effects/mouse_pointers/supplypod_target.dmi' //Icon for when mouse is released
			holder.mouse_down_icon = 'icons/effects/mouse_pointers/supplypod_down_target.dmi' //Icon for when mouse is pressed
		else if(picking_dropoff_turf)
			holder.mouse_up_icon = 'icons/effects/mouse_pointers/supplypod_pickturf.dmi' //Icon for when mouse is released
			holder.mouse_down_icon = 'icons/effects/mouse_pointers/supplypod_pickturf_down.dmi' //Icon for when mouse is pressed
		holder.mouse_override_icon = holder.mouse_up_icon //Icon for idle mouse (same as icon for when released)
		holder.mouse_pointer_icon = holder.mouse_override_icon
		holder.click_intercept = src //Create a click_intercept so we know where the user is clicking
	else
		var/mob/holder_mob = holder.mob
		holder.mouse_up_icon = null
		holder.mouse_down_icon = null
		holder.mouse_override_icon = null
		holder.click_intercept = null
		holder_mob?.update_mouse_pointer() //set the moues icons to null, then call update_moues_pointer() which resets them to the correct values based on what the mob is doing (in a mech, holding a spell, etc)()

/datum/centcom_podlauncher/proc/InterceptClickOn(user,params,atom/target) //Click Intercept so we know where to send pods where the user clicks
	var/list/modifiers = params2list(params)

	var/left_click = LAZYACCESS(modifiers, LEFT_CLICK)

	if (launcherActivated)
		//Clicking on UI elements shouldn't launch a pod
		if(istype(target,/atom/movable/screen))
			return FALSE

		. = TRUE

		if(left_click) //When we left click:
			preLaunch() //Fill the acceptableTurfs list from the orderedArea list. Then, fill up the launchList list with items from the acceptableTurfs list based on the manner of launch (ordered, random, etc)
			if (!isnull(specificTarget))
				target = get_turf(specificTarget) //if we have a specific target, then always launch the pod at the turf of the target
			else if (target)
				target = get_turf(target) //Make sure we're aiming at a turf rather than an item or effect or something
			else
				return //if target is null and we don't have a specific target, cancel
			if (effectAnnounce)
				deadchat_broadcast("A special package is being launched at the station!", turf_target = target, message_type=DEADCHAT_ANNOUNCEMENT)
			var/list/bouttaDie = list()
			for (var/mob/living/target_mob in target)
				bouttaDie.Add(target_mob)
			if (holder.holder)
				supplypod_punish_log(bouttaDie)
			if (!effectBurst) //If we're not using burst mode, just launch normally.
				launch(target)
			else
				for (var/i in 1 to 5) //If we're using burst mode, launch 5 pods
					if (isnull(target))
						break //if our target gets deleted during this, we stop the show
					preLaunch() //Same as above
					var/landingzone = locate(target.x + rand(-1,1), target.y + rand(-1,1), target.z) //Pods are randomly adjacent to (or the same as) the target
					if (landingzone) //just incase we're on the edge of the map or something that would cause target.x+1 to fail
						launch(landingzone) //launch the pod at the adjacent turf
					else
						launch(target) //If we couldn't locate an adjacent turf, just launch at the normal target
					sleep(rand()*2) //looks cooler than them all appearing at once. Gives the impression of burst fire.
	else if (picking_dropoff_turf)
		//Clicking on UI elements shouldn't pick a dropoff turf
		if(istype(target,/atom/movable/screen))
			return FALSE

		. = TRUE
		if(left_click) //When we left click:
			var/turf/target_turf = get_turf(target)
			setDropoff(target_turf)
			customDropoff = TRUE
			to_chat(user, span_notice("You've selected [target_turf] at [COORD(target_turf)] as your dropoff location."))

/datum/centcom_podlauncher/proc/refreshView()
	switch(tabIndex)
		if (TAB_POD)
			setupViewPod()
		if (TAB_BAY)
			setupViewBay()
		else
			setupViewDropoff()

/datum/centcom_podlauncher/proc/refreshBay() //Called whenever the bay is switched, as well as wheneber a pod is launched
	bay = GLOB.supplypod_loading_bays[bayNumber]
	orderedArea = createOrderedArea(bay) //Create an ordered list full of turfs form the bay
	preLaunch() //Fill acceptable turfs from orderedArea, then fill launchList from acceptableTurfs (see proc for more info)
	refreshView()

/datum/centcom_podlauncher/proc/createOrderedArea(area/area_to_order) //This assumes the area passed in is a continuous square
	if (isnull(area_to_order)) //If theres no supplypod bay mapped into centcom, throw an error
		to_chat(holder.mob, "No /area/centcom/central_command_areas/supplypod/loading/one (or /two or /three or /four) in the world! You can make one yourself (then refresh) for now, but yell at a mapper to fix this, today!")
		CRASH("No /area/centcom/central_command_areas/supplypod/loading/one (or /two or /three or /four) has been mapped into the centcom z-level!")
	orderedArea = list()
	if (length(area_to_order.contents)) //Go through the area passed into the proc, and figure out the top left and bottom right corners by calculating max and min values
		var/startX = area_to_order.contents[1].x //Create the four values (we do it off a.contents[1] so they have some sort of arbitrary initial value. They should be overwritten in a few moments)
		var/endX = area_to_order.contents[1].x
		var/startY = area_to_order.contents[1].y
		var/endY = area_to_order.contents[1].y
		for (var/turf/turf_in_area in area_to_order) //For each turf in the area, go through and find:
			if (turf_in_area.x < startX) //The turf with the smallest x value. This is our startX
				startX = turf_in_area.x
			else if (turf_in_area.x > endX) //The turf with the largest x value. This is our endX
				endX = turf_in_area.x
			else if (turf_in_area.y > startY) //The turf with the largest Y value. This is our startY
				startY = turf_in_area.y
			else if (turf_in_area.y < endY) //The turf with the smallest Y value. This is our endY
				endY = turf_in_area.y
		for (var/vertical in endY to startY)
			for (var/horizontal in startX to endX)
				orderedArea.Add(locate(horizontal, startY - (vertical - endY), 1)) //After gathering the start/end x and y, go through locating each turf from top left to bottom right, like one would read a book
	return orderedArea //Return the filled list

/datum/centcom_podlauncher/proc/preLaunch() //Creates a list of acceptable items,
	numTurfs = 0 //Counts the number of turfs that can be launched (remember, supplypods either launch all at once or one turf-worth of items at a time)
	acceptableTurfs = list()
	for (var/t in orderedArea) //Go through the orderedArea list
		var/turf/unchecked_turf = t
		if (iswallturf(unchecked_turf) || length(typecache_filter_list_reverse(unchecked_turf.contents, ignored_atoms))) //if there is something in this turf that isn't in the blacklist, we consider this turf "acceptable" and add it to the acceptableTurfs list
			acceptableTurfs.Add(unchecked_turf) //Because orderedArea was an ordered linear list, acceptableTurfs will be as well.
			numTurfs ++

	launchList = list() //Anything in launchList will go into the supplypod when it is launched
	if (length(acceptableTurfs) && !temp_pod.reversing && !temp_pod.effectMissile) //We dont fill the supplypod if acceptableTurfs is empty, if the pod is going in reverse (effectReverse=true), or if the pod is acitng like a missile (effectMissile=true)
		switch(launchChoice)
			if(LAUNCH_ALL) //If we are launching all the turfs at once
				for (var/t in acceptableTurfs)
					var/turf/accepted_turf = t
					launchList |= typecache_filter_list_reverse(accepted_turf.contents, ignored_atoms) //We filter any blacklisted atoms and add the rest to the launchList
					if (iswallturf(accepted_turf))
						launchList += accepted_turf
			if(LAUNCH_ORDERED) //If we are launching one at a time
				if (launchCounter > length(acceptableTurfs)) //Check if the launchCounter, which acts as an index, is too high. If it is, reset it to 1
					launchCounter = 1 //Note that the launchCounter index is incremented in the launch() proc
				var/turf/next_turf_in_line = acceptableTurfs[launchCounter]
				launchList |= typecache_filter_list_reverse(next_turf_in_line.contents, ignored_atoms) //Filter the specicic turf chosen from acceptableTurfs, and add it to the launchList
				if (iswallturf(next_turf_in_line))
					launchList += next_turf_in_line
			if(LAUNCH_RANDOM) //If we are launching randomly
				var/turf/acceptable_turf = pick_n_take(acceptableTurfs)
				launchList |= typecache_filter_list_reverse(acceptable_turf.contents, ignored_atoms) //filter a random turf from the acceptableTurfs list and add it to the launchList
				if (iswallturf(acceptable_turf))
					launchList += acceptable_turf
	updateSelector() //Call updateSelector(), which, if we are launching one at a time (launchChoice == 2), will move to the next turf that will be launched
	//UpdateSelector() is here (instead if the if(1) switch block) because it also moves the selector to nullspace (to hide it) if needed

/datum/centcom_podlauncher/proc/launch(turf/target_turf) //Game time started
	if (isnull(target_turf))
		return
	var/obj/structure/closet/supplypod/centcompod/toLaunch = duplicate_object(temp_pod) //Duplicate the temp_pod (which we have been varediting or configuring with the UI) and store the result
	toLaunch.update_appearance()//we update_appearance() here so that the door doesnt "flicker on" right after it lands
	var/shippingLane = GLOB.areas_by_type[/area/centcom/central_command_areas/supplypod/supplypod_temp_holding]
	toLaunch.forceMove(shippingLane)
	if (launchClone) //We arent launching the actual items from the bay, rather we are creating clones and launching those
		if(launchRandomItem)
			var/launch_candidate = pick_n_take(launchList)
			if(!isnull(launch_candidate))
				if (iswallturf(launch_candidate))
					var/atom/atom_to_launch = launch_candidate
					toLaunch.turfs_in_cargo += atom_to_launch.type
				else
					var/atom/movable/movable_to_launch = launch_candidate
					duplicate_object(movable_to_launch).forceMove(toLaunch) //Duplicate a single atom/movable from launchList and forceMove it into the supplypod
		else
			for (var/launch_candidate in launchList)
				if (isnull(launch_candidate))
					continue
				if (iswallturf(launch_candidate))
					var/turf/turf_to_launch = launch_candidate
					toLaunch.turfs_in_cargo += turf_to_launch.type
				else
					var/atom/movable/movable_to_launch = launch_candidate
					duplicate_object(movable_to_launch).forceMove(toLaunch) //Duplicate each atom/movable in launchList and forceMove them into the supplypod
	else
		if(launchRandomItem)
			var/atom/random_item = pick_n_take(launchList)
			if(!isnull(random_item))
				if (iswallturf(random_item))
					var/turf/wall = random_item
					toLaunch.turfs_in_cargo += wall.type
					wall.ScrapeAway()
				else
					var/atom/movable/random_item_movable = random_item
					random_item_movable.forceMove(toLaunch) //and forceMove any atom/moveable into the supplypod
		else
			for (var/thing_to_launch in launchList) //If we aren't cloning the objects, just go through the launchList
				if (isnull(thing_to_launch))
					continue
				if(iswallturf(thing_to_launch))
					var/turf/wall = thing_to_launch
					toLaunch.turfs_in_cargo += wall.type
					wall.ScrapeAway()
				else
					var/atom/movable/movable_to_launch = thing_to_launch
					movable_to_launch.forceMove(toLaunch) //and forceMove any atom/moveable into the supplypod
	new /obj/effect/pod_landingzone(target_turf, toLaunch) //Then, create the DPTarget effect, which will eventually forceMove the temp_pod to its location
	if (launchClone)
		launchCounter++ //We only need to increment launchCounter if we are cloning objects.
		//If we aren't cloning objects, taking and removing the first item each time from the acceptableTurfs list will inherently iterate through the list in order

/datum/centcom_podlauncher/proc/updateSelector() //Ensures that the selector effect will showcase the next item if needed
	if (launchChoice == LAUNCH_ORDERED && length(acceptableTurfs) > 1 && !temp_pod.reversing && !temp_pod.effectMissile) //We only show the selector if we are taking items from the bay
		var/index = (launchCounter == 1 ? launchCounter : launchCounter + 1) //launchCounter acts as an index to the ordered acceptableTurfs list, so adding one will show the next item in the list. We don't want to do this for the very first item tho
		if (index > length(acceptableTurfs)) //out of bounds check
			index = 1
		selector.forceMove(acceptableTurfs[index]) //forceMove the selector to the next turf in the ordered acceptableTurfs list
	else
		selector.moveToNullspace() //Otherwise, we move the selector to nullspace until it is needed again

/datum/centcom_podlauncher/proc/clearBay() //Clear all objs and mobs from the selected bay
	for (var/obj/object in bay.get_all_contents())
		if (istype(object.type, /obj/effect/light_emitter/podbay))
			continue
		qdel(object)
	for (var/mob/mob in bay.get_all_contents())
		qdel(mob)
	for (var/bayturf in bay)
		var/turf/turf_to_clear = bayturf
		if (istype(turf_to_clear, /obj/effect/light_emitter/podbay))
			continue
		turf_to_clear.ChangeTurf(/turf/open/floor/iron)

/datum/centcom_podlauncher/Destroy() //The Destroy() proc. This is called by ui_close proc, or whenever the user leaves the game
	updateCursor(TRUE) //Make sure our moues cursor resets to default. False means we are not in launch mode
	QDEL_NULL(temp_pod) //Delete the temp_pod
	QDEL_NULL(selector) //Delete the selector effect
	QDEL_NULL(indicator)
	return ..()

/datum/centcom_podlauncher/proc/supplypod_punish_log(list/whoDyin)
	var/podString = effectBurst ? "5 pods" : "a pod"
	var/whomString = ""
	if (LAZYLEN(whoDyin))
		for (var/mob/living/M in whoDyin)
			whomString += "[key_name(M)], "

	var/msg = "launched [podString] towards [whomString]"
	message_admins("[key_name_admin(usr)] [msg] in [ADMIN_VERBOSEJMP(specificTarget)].")
	if (length(whoDyin))
		for (var/mob/living/M in whoDyin)
			admin_ticket_log(M, "[key_name_admin(usr)] [msg]")

/datum/centcom_podlauncher/proc/loadData(list/dataToLoad)
	bayNumber = dataToLoad["bayNumber"]
	customDropoff = dataToLoad["customDropoff"]
	renderLighting = dataToLoad["renderLighting"]
	launchClone = dataToLoad["launchClone"] //Do we launch the actual items in the bay or just launch clones of them?
	launchRandomItem = dataToLoad["launchRandomItem"] //Do we launch a single random item instead of everything on the turf?
	launchChoice = dataToLoad["launchChoice"] //Launch turfs all at once (0), ordered (1), or randomly(1)
	explosionChoice = dataToLoad["explosionChoice"] //An explosion that occurs when landing. Can be no explosion (0), custom explosion (1), or maxcap (2)
	damageChoice = dataToLoad["damageChoice"] //Damage that occurs to any mob under the pod when it lands. Can be no damage (0), custom damage (1), or gib+5000dmg (2)
	temp_pod.delays = dataToLoad["delays"]
	temp_pod.reverse_delays = dataToLoad["rev_delays"]
	temp_pod.custom_rev_delay = dataToLoad["custom_rev_delay"]
	temp_pod.setStyle(dataToLoad["styleChoice"])  //Style is a variable that keeps track of what the pod is supposed to look like.
	temp_pod.effectShrapnel = dataToLoad["effectShrapnel"] //If true, creates a cloud of shrapnel of a decided type and magnitude on landing
	temp_pod.shrapnel_type = text2path(dataToLoad["shrapnelType"])
	temp_pod.shrapnel_magnitude = dataToLoad["shrapnelMagnitude"]
	temp_pod.effectStun = dataToLoad["effectStun"]//If true, stuns anyone under the pod when it launches until it lands, forcing them to get hit by the pod. Devilish!
	temp_pod.effectLimb = dataToLoad["effectLimb"]//If true, pops off a limb (if applicable) from anyone caught under the pod when it lands
	temp_pod.effectOrgans = dataToLoad["effectOrgans"]//If true, yeets the organs out of any bodies caught under the pod when it lands
	temp_pod.bluespace = dataToLoad["effectBluespace"] //If true, the pod deletes (in a shower of sparks) after landing
	temp_pod.effectStealth = dataToLoad["effectStealth"]//If true, a target icon isn't displayed on the turf where the pod will land
	temp_pod.effectQuiet = dataToLoad["effectQuiet"] //The female sniper. If true, the pod makes no noise (including related explosions, opening sounds, etc)
	temp_pod.effectMissile = dataToLoad["effectMissile"] //If true, the pod deletes the second it lands. If you give it an explosion, it will act like a missile exploding as it hits the ground
	temp_pod.effectCircle = dataToLoad["effectCircle"] //If true, allows the pod to come in at any angle. Bit of a weird feature but whatever its here
	effectBurst = dataToLoad["effectBurst"] //IOf true, launches five pods at once (with a very small delay between for added coolness), in a 3x3 area centered around the area
	temp_pod.reversing = dataToLoad["effectReverse"] //If true, the pod will not send any items. Instead, after opening, it will close again (picking up items/mobs) and fly back to centcom
	temp_pod.reverse_option_list = dataToLoad["reverse_option_list"]
	temp_pod.create_sparks = dataToLoad["create_sparks"] // If true, creates sparks when the pod vanishes.
	specificTarget = dataToLoad["effectTarget"] //Launches the pod at the turf of a specific mob target, rather than wherever the user clicked. Useful for smites
	temp_pod.adminNamed = dataToLoad["effectName"] //Determines whether or not the pod has been named by an admin. If true, the pod's name will not get overridden when the style of the pod changes (changing the style of the pod normally also changes the name+desc)
	temp_pod.name = dataToLoad["podName"]
	temp_pod.desc = dataToLoad["podDesc"]
	effectAnnounce = dataToLoad["effectAnnounce"]
	numTurfs = dataToLoad["numObjects"] //Counts the number of turfs that contain a launchable object in the centcom supplypod bay
	temp_pod.fallingSound = dataToLoad["fallingSound"]//Admin sound to play as the pod falls
	temp_pod.landingSound = dataToLoad["landingSound"]//Admin sound to play when the pod lands
	temp_pod.openingSound = dataToLoad["openingSound"]//Admin sound to play when the pod opens
	temp_pod.leavingSound = dataToLoad["leavingSound"]//Admin sound to play when the pod leaves
	temp_pod.soundVolume = dataToLoad["soundVolume"] //Admin sound to play when the pod leaves
	picking_dropoff_turf = FALSE
	launcherActivated = FALSE
	updateCursor()
	refreshView()

GLOBAL_DATUM_INIT(podlauncher, /datum/centcom_podlauncher, new)

//Set the dropoff location and indicator to either a specific turf or somewhere in an area
/datum/centcom_podlauncher/proc/setDropoff(target)
	var/turf/target_turf
	if (isturf(target))
		target_turf = target
	else if (isarea(target))
		target_turf = pick(get_area_turfs(target))
	else
		CRASH("Improper type passed to setDropoff! Should be /turf or /area")
	temp_pod.reverse_dropoff_coords = list(target_turf.x, target_turf.y, target_turf.z)
	indicator.forceMove(target_turf)

/obj/effect/client_image_holder/supplypod_selector // Shows which item will be taken next
	name = "Supply Selector (Only you can see this)"
	image_icon = 'icons/obj/supplypods_32x32.dmi'
	image_state = "selector"
	image_layer = FLY_LAYER
	layer = FLY_LAYER
	plane = ABOVE_GAME_PLANE
	alpha = 150

/obj/effect/client_image_holder/dropoff_location // Shows where revese pods lands
	name = "Dropoff Location (Only you can see this)"
	image_icon = 'icons/obj/supplypods_32x32.dmi'
	image_state = "dropoff_indicator"
	image_layer = FLY_LAYER
	layer = FLY_LAYER
	plane = ABOVE_GAME_PLANE
	alpha = 0

#undef LAUNCH_ALL
#undef LAUNCH_ORDERED
#undef LAUNCH_RANDOM
#undef TAB_BAY
#undef TAB_POD
