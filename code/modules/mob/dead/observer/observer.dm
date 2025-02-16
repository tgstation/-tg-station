GLOBAL_LIST_EMPTY(ghost_images_default) //this is a list of the default (non-accessorized, non-dir) images of the ghosts themselves
GLOBAL_LIST_EMPTY(ghost_images_simple) //this is a list of all ghost images as the simple white ghost

GLOBAL_VAR_INIT(observer_default_invisibility, INVISIBILITY_OBSERVER)

/mob/dead/observer
	name = "ghost"
	desc = "It's a g-g-g-g-ghooooost!" //jinkies!
	icon = 'icons/mob/simple/mob.dmi'
	icon_state = "ghost"
	plane = GHOST_PLANE
	stat = DEAD
	density = FALSE
	see_invisible = SEE_INVISIBLE_OBSERVER
	lighting_cutoff = LIGHTING_CUTOFF_MEDIUM
	invisibility = INVISIBILITY_OBSERVER
	hud_type = /datum/hud/ghost
	movement_type = GROUND | FLYING
	light_system = OVERLAY_LIGHT
	light_range = 2.5
	light_power = 0.6
	light_on = FALSE
	shift_to_open_context_menu = FALSE
	var/can_reenter_corpse
	var/bootime = 0
	var/started_as_observer //This variable is set to 1 when you enter the game as an observer.
							//If you died in the game and are a ghost - this will remain as null.
							//Note that this is not a reliable way to determine if admins started as observers, since they change mobs a lot.
	var/atom/movable/following = null
	var/fun_verbs = 0
	var/image/ghostimage_default = null //this mobs ghost image without accessories and dirs
	var/image/ghostimage_simple = null //this mob with the simple white ghost sprite
	var/ghostvision = 1 //is the ghost able to see things humans can't?
	var/mob/observetarget = null //The target mob that the ghost is observing. Used as a reference in logout()
	var/data_huds_on = 0 //Are data HUDs currently enabled?
	var/health_scan = FALSE //Are health scans currently enabled?
	var/chem_scan = FALSE //Are chem scans currently enabled?
	var/gas_scan = FALSE //Are gas scans currently enabled?
	var/ghost_orbit = GHOST_ORBIT_CIRCLE

	//These variables store hair data if the ghost originates from a species with head and/or facial hair.
	var/hairstyle
	var/hair_color
	var/mutable_appearance/hair_overlay
	var/facial_hairstyle
	var/facial_hair_color
	var/mutable_appearance/facial_hair_overlay

	var/updatedir = 1 //Do we have to update our dir as the ghost moves around?
	var/lastsetting = null //Stores the last setting that ghost_others was set to, for a little more efficiency when we update ghost images. Null means no update is necessary

	//We store copies of the ghost display preferences locally so they can be referred to even if no client is connected.
	//If there's a bug with changing your ghost settings, it's probably related to this.
	var/ghost_accs = GHOST_ACCS_DEFAULT_OPTION
	var/ghost_others = GHOST_OTHERS_DEFAULT_OPTION
	// Used for displaying in ghost chat, without changing the actual name
	// of the mob
	var/deadchat_name
	var/datum/spawners_menu/spawners_menu
	var/datum/minigames_menu/minigames_menu

	/// The POI we're orbiting (orbit menu)
	var/orbiting_ref

	var/static/list/observer_hud_traits = list(
		TRAIT_SECURITY_HUD,
		TRAIT_MEDICAL_HUD,
		TRAIT_DIAGNOSTIC_HUD,
		TRAIT_BOT_PATH_HUD
	)

/mob/dead/observer/Initialize(mapload)
	set_invisibility(GLOB.observer_default_invisibility)

	add_verb(src, list(
		/mob/dead/observer/proc/dead_tele,
		/mob/dead/observer/proc/open_spawners_menu,
		/mob/dead/observer/proc/tray_view,
		/mob/dead/observer/proc/open_minigames_menu))

	if(icon_state in GLOB.ghost_forms_with_directions_list)
		ghostimage_default = image(src.icon,src,src.icon_state + "_nodir")
	else
		ghostimage_default = image(src.icon,src,src.icon_state)
	ghostimage_default.override = TRUE
	GLOB.ghost_images_default |= ghostimage_default

	ghostimage_simple = image(src.icon,src,"ghost_nodir")
	ghostimage_simple.override = TRUE
	GLOB.ghost_images_simple |= ghostimage_simple

	updateallghostimages()

	var/turf/T
	var/mob/body = loc
	if(ismob(body))
		T = get_turf(body) //Where is the body located?

		gender = body.gender
		if(body.mind && body.mind.name)
			name = body.mind.ghostname || body.mind.name
		else
			name = body.real_name || generate_random_mob_name(gender)


		mind = body.mind //we don't transfer the mind but we keep a reference to it.

		if(HAS_TRAIT_FROM_ONLY(body, TRAIT_SUICIDED, REF(body))) // transfer if the body was killed due to suicide
			ADD_TRAIT(src, TRAIT_SUICIDED, REF(body))

		if(ishuman(body))
			var/mob/living/carbon/human/body_human = body
			var/datum/species/human_species = body_human.dna.species
			if(human_species.check_head_flags(HEAD_HAIR))
				hairstyle = body_human.hairstyle
				hair_color = ghostify_color(body_human.hair_color)
			if(human_species.check_head_flags(HEAD_FACIAL_HAIR))
				facial_hairstyle = body_human.facial_hairstyle
				facial_hair_color = ghostify_color(body_human.facial_hair_color)

	update_appearance()

	if(!T || is_secret_level(T.z))
		var/list/turfs = get_area_turfs(/area/shuttle/arrival)
		if(length(turfs))
			T = pick(turfs)
		else
			T = SSmapping.get_station_center()

	abstract_move(T)

	//To prevent nameless ghosts
	name ||= generate_random_mob_name(FALSE)
	real_name = name

	if(!fun_verbs)
		remove_verb(src, /mob/dead/observer/verb/boo)
		remove_verb(src, /mob/dead/observer/verb/possess)

	AddElement(/datum/element/movetype_handler)

	add_to_dead_mob_list()

	for(var/datum/atom_hud/alternate_appearance/alt_hud as anything in GLOB.active_alternate_appearances)
		alt_hud.apply_to_new_mob(src)

	. = ..()

	grant_all_languages()
	setup_hud_traits()
	show_data_huds()
	data_huds_on = 1

	SSpoints_of_interest.make_point_of_interest(src)
	ADD_TRAIT(src, TRAIT_HEAR_THROUGH_DARKNESS, ref(src))

/mob/dead/observer/get_photo_description(obj/item/camera/camera)
	if(!invisibility || camera.see_ghosts)
		return "You can also see a g-g-g-g-ghooooost!"

/mob/dead/observer/narsie_act()
	var/old_color = color
	color = COLOR_CULT_RED
	animate(src, color = old_color, time = 10, flags = ANIMATION_PARALLEL)
	addtimer(CALLBACK(src, TYPE_PROC_REF(/atom, update_atom_colour)), 1 SECONDS)

/mob/dead/observer/Destroy()
	if(data_huds_on)
		remove_data_huds()

	// Update our old body's medhud since we're abandoning it
	if(isliving(mind?.current))
		mind.current.med_hud_set_status()

	GLOB.ghost_images_default -= ghostimage_default
	ghostimage_default = null

	GLOB.ghost_images_simple -= ghostimage_simple
	ghostimage_simple = null

	updateallghostimages()

	QDEL_NULL(spawners_menu)
	QDEL_NULL(minigames_menu)
	return ..()

/*
 * This proc will update the icon of the ghost itself, with hair overlays, as well as the ghost image.
 * Please call update_icon(updates, icon_state) from now on when you want to update the icon_state of the ghost,
 * or you might end up with hair on a sprite that's not supposed to get it.
 * Hair will always update its dir, so if your sprite has no dirs the haircut will go all over the place.
 * |- Ricotez
 */
/mob/dead/observer/update_icon(updates=ALL, new_form)
	. = ..()

	if(client) //We update our preferences in case they changed right before update_appearance was called.
		ghost_accs = client.prefs.read_preference(/datum/preference/choiced/ghost_accessories)
		ghost_others = client.prefs.read_preference(/datum/preference/choiced/ghost_others)

	if(hair_overlay)
		cut_overlay(hair_overlay)
		hair_overlay = null

	if(facial_hair_overlay)
		cut_overlay(facial_hair_overlay)
		facial_hair_overlay = null


	if(new_form)
		icon_state = new_form
		if(icon_state in GLOB.ghost_forms_with_directions_list)
			ghostimage_default.icon_state = new_form + "_nodir" //if this icon has dirs, the default ghostimage must use its nodir version or clients with the preference set to default sprites only will see the dirs
		else
			ghostimage_default.icon_state = new_form

	if((ghost_accs == GHOST_ACCS_DIR || ghost_accs == GHOST_ACCS_FULL) && (icon_state in GLOB.ghost_forms_with_directions_list)) //if this icon has dirs AND the client wants to show them, we make sure we update the dir on movement
		updatedir = 1
	else
		updatedir = 0 //stop updating the dir in case we want to show accessories with dirs on a ghost sprite without dirs
		setDir(2 )//reset the dir to its default so the sprites all properly align up

	if(ghost_accs == GHOST_ACCS_FULL && (icon_state in GLOB.ghost_forms_with_accessories_list)) //check if this form supports accessories and if the client wants to show them
		if(facial_hairstyle)
			var/datum/sprite_accessory/S = SSaccessories.facial_hairstyles_list[facial_hairstyle]
			if(S)
				facial_hair_overlay = mutable_appearance(S.icon, "[S.icon_state]", -HAIR_LAYER)
				if(facial_hair_color)
					facial_hair_overlay.color = facial_hair_color
				facial_hair_overlay.alpha = 200
				add_overlay(facial_hair_overlay)
		if(hairstyle)
			var/datum/sprite_accessory/hair/S = SSaccessories.hairstyles_list[hairstyle]
			if(S)
				hair_overlay = mutable_appearance(S.icon, "[S.icon_state]", -HAIR_LAYER)
				if(hair_color)
					hair_overlay.color = hair_color
				hair_overlay.alpha = 200
				hair_overlay.pixel_y = S.y_offset
				add_overlay(hair_overlay)

/*
 * Increase the brightness of a color and desaturates it slightly to make it suitable for ghosts
 * We use HSL for this, makes life SOOO easy
 */
/proc/ghostify_color(input_color)
	var/list/read_color = rgb2num(input_color, COLORSPACE_HSL)
	var/sat = read_color[2]
	var/lum = read_color[3]

	// Clamp so it still has color, can't get too bright/desaturated
	sat -= 15
	if(sat < 30)
		sat = min(read_color[2], 30)

	lum += 15
	if(lum > 80)
		lum = max(read_color[3], 80)
	return rgb(read_color[1], sat, lum, space = COLORSPACE_HSL)

/*
Transfer_mind is there to check if mob is being deleted/not going to have a body.
Works together with spawning an observer, noted above.
*/

/mob/proc/ghostize(can_reenter_corpse = TRUE, admin_ghost = FALSE)
	if(!key)
		return
	if(key[1] == "@") // Skip aghosts.
		return

	if(HAS_TRAIT(src, TRAIT_CORPSELOCKED) && !admin_ghost)
		if(can_reenter_corpse) //If you can re-enter the corpse you can't leave when corpselocked
			return
		if(ishuman(usr)) //following code only applies to those capable of having an ethereal heart, ie humans
			var/mob/living/carbon/human/crystal_fella = usr
			var/our_heart = crystal_fella.get_organ_slot(ORGAN_SLOT_HEART)
			if(istype(our_heart, /obj/item/organ/heart/ethereal)) //so you got the heart?
				var/obj/item/organ/heart/ethereal/ethereal_heart = our_heart
				ethereal_heart.stop_crystalization_process(crystal_fella) //stops the crystallization process

	stop_sound_channel(CHANNEL_HEARTBEAT) //Stop heartbeat sounds because You Are A Ghost Now
	var/mob/dead/observer/ghost = new(src) // Transfer safety to observer spawning proc.
	SStgui.on_transfer(src, ghost) // Transfer NanoUIs.
	ghost.can_reenter_corpse = can_reenter_corpse
	ghost.PossessByPlayer(key)
	ghost.client?.init_verbs()
	if(!can_reenter_corpse)// Disassociates observer mind from the body mind
		ghost.mind = null

	var/recordable_time = world.time
	var/mob/living/former_mob = ghost.mind?.current
	if(isliving(former_mob))
		recordable_time = former_mob.timeofdeath

	ghost.persistent_client?.time_of_death = recordable_time
	SEND_SIGNAL(src, COMSIG_MOB_GHOSTIZED)
	return ghost

/mob/living/ghostize(can_reenter_corpse = TRUE)
	. = ..()
	if(. && can_reenter_corpse)
		var/mob/dead/observer/ghost = .
		ghost.mind.current?.med_hud_set_status()

/*
This is the proc mobs get to turn into a ghost. Forked from ghostize due to compatibility issues.
*/
/mob/living/verb/ghost()
	set category = "OOC"
	set name = "Ghost"
	set desc = "Relinquish your life and enter the land of the dead."

	if(stat != CONSCIOUS && stat != DEAD)
		succumb()
	if(stat == DEAD)
		if(!HAS_TRAIT(src, TRAIT_CORPSELOCKED)) //corpse-locked have to confirm with the alert below
			ghostize(TRUE)
			return TRUE
	var/response = tgui_alert(usr, "Are you sure you want to ghost? You won't be able to re-enter your body!", "Confirm Ghost Observe", list("Ghost", "Stay in Body"))
	if(response != "Ghost")
		return FALSE//didn't want to ghost after-all
	ghostize(FALSE) // FALSE parameter is so we can never re-enter our body. U ded.
	return TRUE

/mob/eye/verb/ghost()
	set category = "OOC"
	set name = "Ghost"
	set desc = "Relinquish your life and enter the land of the dead."

	var/response = tgui_alert(usr, "Are you sure you want to ghost? If you ghost whilst still alive you cannot re-enter your body!", "Confirm Ghost Observe", list("Ghost", "Stay in Body"))
	if(response != "Ghost")
		return
	ghostize(FALSE)

/mob/dead/observer/Move(NewLoc, direct, glide_size_override = 32)
	if(updatedir)
		setDir(direct)//only update dir if we actually need it, so overlays won't spin on base sprites that don't have directions of their own

	if(glide_size_override)
		set_glide_size(glide_size_override)
	if(NewLoc)
		abstract_move(NewLoc)
	else
		var/turf/destination = get_turf(src)

		if((direct & NORTH) && y < world.maxy)
			destination = get_step(destination, NORTH)

		else if((direct & SOUTH) && y > 1)
			destination = get_step(destination, SOUTH)

		if((direct & EAST) && x < world.maxx)
			destination = get_step(destination, EAST)

		else if((direct & WEST) && x > 1)
			destination = get_step(destination, WEST)

		abstract_move(destination)//Get out of closets and such as a ghost

/mob/dead/observer/forceMove(atom/destination)
	abstract_move(destination) // move like the wind
	return TRUE

/mob/dead/observer/Moved(atom/old_loc, movement_dir, forced, list/old_locs, momentum_change)
	. = ..()
	var/area/new_area = get_area(src)
	if(new_area != ambience_tracked_area)
		update_ambience_area(new_area)

/mob/dead/observer/verb/reenter_corpse()
	set category = "Ghost"
	set name = "Re-enter Corpse"
	if(!client)
		return
	if(!mind || QDELETED(mind.current))
		to_chat(src, span_warning("You have no body."))
		return
	if(!can_reenter_corpse)
		to_chat(src, span_warning("You cannot re-enter your body."))
		return
	if(mind.current.key && mind.current.key[1] != "@") //makes sure we don't accidentally kick any clients
		to_chat(usr, span_warning("Another consciousness is in your body...It is resisting you."))
		return
	client.view_size.setDefault(getScreenSize(client.prefs.read_preference(/datum/preference/toggle/widescreen)))//Let's reset so people can't become allseeing gods
	SStgui.on_transfer(src, mind.current) // Transfer NanoUIs.
	if(mind.current.stat == DEAD && SSlag_switch.measures[DISABLE_DEAD_KEYLOOP])
		to_chat(src, span_warning("To leave your body again use the Ghost verb."))
	mind.current.PossessByPlayer(key)
	mind.current.client.init_verbs()
	return TRUE

/mob/dead/observer/verb/stay_dead()
	set category = "Ghost"
	set name = "Do Not Resuscitate"
	if(!client)
		return
	if(!can_reenter_corpse)
		to_chat(usr, span_warning("You're already stuck out of your body!"))
		return FALSE

	var/response = tgui_alert(usr, "Are you sure you want to prevent (almost) all means of resuscitation? This cannot be undone.", "Are you sure you want to stay dead?", list("DNR","Save Me"))
	if(response != "DNR")
		return

	can_reenter_corpse = FALSE
	var/mob/living/current_mob = mind.current
	if(istype(current_mob))
		// Update med huds
		current_mob.med_hud_set_status()
		current_mob.log_message("had their player ([key_name(src)]) do-not-resuscitate / DNR", LOG_GAME, color = COLOR_GREEN, log_globally = FALSE)
	log_message("has opted to do-not-resuscitate / DNR from their body ([current_mob])", LOG_GAME, color = COLOR_GREEN)

	// Disassociates observer mind from the body mind
	mind = null

	to_chat(src, span_boldnotice("You can no longer be brought back into your body."))
	return TRUE

/mob/dead/observer/proc/send_revival_notification(message, sound, atom/source, flashwindow)
	if(flashwindow)
		window_flash(client)
	if(message)
		to_chat(src, span_ghostalert("[message]"))
		if(source)
			var/atom/movable/screen/alert/A = throw_alert("[REF(source)]_revival", /atom/movable/screen/alert/revival)
			if(A)
				var/ui_style = client?.prefs?.read_preference(/datum/preference/choiced/ui_style)
				if(ui_style)
					A.icon = ui_style2icon(ui_style)
				A.desc = message
				var/old_layer = source.layer
				var/old_plane = source.plane
				source.layer = FLOAT_LAYER
				source.plane = FLOAT_PLANE
				A.add_overlay(source)
				source.layer = old_layer
				source.plane = old_plane
	to_chat(src, span_ghostalert("<a href=byond://?src=[REF(src)];reenter=1>(Click to re-enter)</a>"))
	if(sound)
		SEND_SOUND(src, sound(sound))

/mob/dead/observer/proc/dead_tele()
	set category = "Ghost"
	set name = "Teleport"
	set desc= "Teleport to a location"
	if(!isobserver(usr))
		to_chat(usr, span_warning("Not when you're not dead!"))
		return
	var/list/filtered = list()
	for(var/area/A as anything in get_sorted_areas())
		if(!(A.area_flags & HIDDEN_AREA))
			filtered += A
	var/area/thearea = tgui_input_list(usr, "Area to jump to", "BOOYEA", filtered)

	if(isnull(thearea))
		return
	if(!isobserver(usr))
		to_chat(usr, span_warning("Not when you're not dead!"))
		return

	var/list/L = list()
	for(var/turf/T in get_area_turfs(thearea.type))
		L+=T

	if(!L || !length(L))
		to_chat(usr, span_warning("No area available."))
		return

	usr.abstract_move(pick(L))

/mob/dead/observer/verb/follow()
	set category = "Ghost"
	set name = "Orbit" // "Haunt"
	set desc = "Follow and orbit a mob."

	GLOB.orbit_menu.show(src)

// This is the ghost's follow verb with an argument
/mob/dead/observer/proc/ManualFollow(atom/movable/target)
	if (!istype(target) || (is_secret_level(target.z) && !client?.holder))
		return

	var/list/icon_dimensions = get_icon_dimensions(target.icon)
	var/orbitsize = (icon_dimensions["width"] + icon_dimensions["height"]) * 0.5
	orbitsize -= (orbitsize/ICON_SIZE_ALL)*(ICON_SIZE_ALL*0.25)

	var/rot_seg

	switch(ghost_orbit)
		if(GHOST_ORBIT_TRIANGLE)
			rot_seg = 3
		if(GHOST_ORBIT_SQUARE)
			rot_seg = 4
		if(GHOST_ORBIT_PENTAGON)
			rot_seg = 5
		if(GHOST_ORBIT_HEXAGON)
			rot_seg = 6
		else //Circular
			rot_seg = 36 //360/10 bby, smooth enough aproximation of a circle

	orbit(target,orbitsize, FALSE, 20, rot_seg)

/mob/dead/observer/orbit()
	setDir(2)//reset dir so the right directional sprites show up
	return ..()

/mob/dead/observer/stop_orbit(datum/component/orbiter/orbits)
	. = ..()
	//restart our floating animation after orbit is done.
	pixel_y = base_pixel_y
	// if we were autoobserving, reset perspective
	if (!isnull(client) && !isnull(client.eye))
		reset_perspective(null)

/mob/dead/observer/verb/jumptomob() //Moves the ghost instead of just changing the ghosts's eye -Nodrak
	set category = "Ghost"
	set name = "Jump to Mob"
	set desc = "Teleport to a mob"

	if(!isobserver(usr)) //Make sure they're an observer!
		return

	var/list/possible_destinations = SSpoints_of_interest.get_mob_pois()
	var/target = null

	target = tgui_input_list(usr, "Please, select a player!", "Jump to Mob", possible_destinations)
	if(isnull(target))
		return
	if (!isobserver(usr))
		return

	var/mob/destination_mob = possible_destinations[target] //Destination mob

	// During the break between opening the input menu and selecting our target, has this become an invalid option?
	if(!SSpoints_of_interest.is_valid_poi(destination_mob))
		return

	var/mob/source_mob = src  //Source mob
	var/turf/destination_turf = get_turf(destination_mob) //Turf of the destination mob

	if(isturf(destination_turf))
		source_mob.abstract_move(destination_turf)
	else
		to_chat(source_mob, span_danger("This mob is not located in the game world."))

/mob/dead/observer/verb/change_view_range()
	set category = "Ghost"
	set name = "View Range"
	set desc = "Change your view range."

	if(SSlag_switch.measures[DISABLE_GHOST_ZOOM_TRAY] && !client?.holder)
		to_chat(usr, span_notice("That verb is currently globally disabled."))
		return

	var/max_view = client.prefs.unlock_content ? GHOST_MAX_VIEW_RANGE_MEMBER : GHOST_MAX_VIEW_RANGE_DEFAULT
	if(client.view_size.getView() == client.view_size.default)
		var/list/views = list()
		for(var/i in 7 to max_view)
			views |= i
		var/new_view = tgui_input_list(usr, "New view", "Modify view range", views)
		if(new_view)
			client.view_size.setTo(clamp(new_view, 7, max_view) - 7)
	else
		client.view_size.resetToDefault()

/mob/dead/observer/verb/add_view_range(input as num)
	set name = "Add View Range"
	set hidden = TRUE

	if(SSlag_switch.measures[DISABLE_GHOST_ZOOM_TRAY] && !client?.holder)
		to_chat(usr, span_notice("That verb is currently globally disabled."))
		return

	var/max_view = client.prefs.unlock_content ? GHOST_MAX_VIEW_RANGE_MEMBER : GHOST_MAX_VIEW_RANGE_DEFAULT
	if(input)
		client.rescale_view(input, 0, ((max_view*2)+1) - 15)

/mob/dead/observer/verb/boo()
	set category = "Ghost"
	set name = "Boo!"
	set desc= "Scare your crew members because of boredom!"

	if(bootime > world.time)
		return
	var/obj/machinery/light/L = locate(/obj/machinery/light) in view(1, src)
	if(L?.flicker())
		bootime = world.time + 600
	//Maybe in the future we can add more <i>spooky</i> code here!


/mob/dead/observer/verb/toggle_ghostsee()
	set name = "Toggle Ghost Vision"
	set desc = "Toggles your ability to see things only ghosts can see, like other ghosts"
	set category = "Ghost"
	ghostvision = !(ghostvision)
	update_sight()
	to_chat(usr, span_boldnotice("You [(ghostvision?"now":"no longer")] have ghost vision."))

/mob/dead/observer/verb/toggle_darkness()
	set name = "Toggle Darkness"
	set category = "Ghost"
	switch(lighting_cutoff)
		if (LIGHTING_CUTOFF_VISIBLE)
			lighting_cutoff = LIGHTING_CUTOFF_MEDIUM
		if (LIGHTING_CUTOFF_MEDIUM)
			lighting_cutoff = LIGHTING_CUTOFF_HIGH
		if (LIGHTING_CUTOFF_HIGH)
			lighting_cutoff = LIGHTING_CUTOFF_FULLBRIGHT
		else
			lighting_cutoff = LIGHTING_CUTOFF_VISIBLE

	update_sight()

/mob/dead/observer/update_sight()
	if(client)
		ghost_others = client.prefs.read_preference(/datum/preference/choiced/ghost_others) //A quick update just in case this setting was changed right before calling the proc

	if (!ghostvision)
		set_invis_see(SEE_INVISIBLE_LIVING)
	else
		set_invis_see(SEE_INVISIBLE_OBSERVER)


	updateghostimages()
	..()

/proc/updateallghostimages()
	list_clear_nulls(GLOB.ghost_images_default)
	list_clear_nulls(GLOB.ghost_images_simple)

	for (var/mob/dead/observer/O in GLOB.player_list)
		O.updateghostimages()

/mob/dead/observer/proc/updateghostimages()
	if (!client)
		return

	if(lastsetting)
		switch(lastsetting) //checks the setting we last came from, for a little efficiency so we don't try to delete images from the client that it doesn't have anyway
			if(GHOST_OTHERS_DEFAULT_SPRITE)
				client?.images -= GLOB.ghost_images_default
			if(GHOST_OTHERS_SIMPLE)
				client?.images -= GLOB.ghost_images_simple
	lastsetting = client?.prefs.read_preference(/datum/preference/choiced/ghost_others)
	if(!ghostvision)
		return
	if(lastsetting != GHOST_OTHERS_THEIR_SETTING)
		switch(lastsetting)
			if(GHOST_OTHERS_DEFAULT_SPRITE)
				client?.images |= (GLOB.ghost_images_default-ghostimage_default)
			if(GHOST_OTHERS_SIMPLE)
				client?.images |= (GLOB.ghost_images_simple-ghostimage_simple)

/mob/dead/observer/verb/possess()
	set category = "Ghost"
	set name = "Possess!"
	set desc= "Take over the body of a mindless creature!"

	var/list/possessible = list()
	for(var/mob/living/L in GLOB.alive_mob_list)
		if(istype(L,/mob/living/carbon/human/dummy) || !get_turf(L)) //Haha no.
			continue
		if(!(L in GLOB.player_list) && !L.mind)
			possessible += L

	var/mob/living/target = tgui_input_list(usr, "Your new life begins today!", "Possess Mob", sort_names(possessible))

	if(!target)
		return FALSE

	if(ismegafauna(target))
		to_chat(src, span_warning("This creature is too powerful for you to possess!"))
		return FALSE

	if(can_reenter_corpse && mind?.current)
		if(tgui_alert(usr, "Your soul is still tied to your former life as [mind.current.name], if you go forward there is no going back to that life. Are you sure you wish to continue?", "Move On", list("Yes", "No")) == "No")
			return FALSE
	if(target.key)
		to_chat(src, span_warning("Someone has taken this body while you were choosing!"))
		return FALSE

	target.PossessByPlayer(key)
	target.faction = list(FACTION_NEUTRAL)
	return TRUE

/mob/dead/observer/_pointed(atom/pointed_at)
	if(!..())
		return FALSE

	visible_message(span_deadsay("<b>[src]</b> points to [pointed_at]."))

/mob/dead/observer/verb/view_manifest()
	set name = "View Crew Manifest"
	set category = "Ghost"

	if(!client)
		return
	if(world.time < client.crew_manifest_delay)
		return
	client.crew_manifest_delay = world.time + (1 SECONDS)

	GLOB.manifest.ui_interact(src)

//this is called when a ghost is drag clicked to something.
/mob/dead/observer/mouse_drop_dragged(atom/over, mob/user)
	if (isobserver(user) && user.client.holder && (isliving(over) || iseyemob(over)))
		user.client.holder.cmd_ghost_drag(src, over)

/mob/dead/observer/Topic(href, href_list)
	..()
	if(usr == src)
		if(href_list["follow"])
			var/atom/movable/target = locate(href_list["follow"])
			if(istype(target) && (target != src))
				ManualFollow(target)
				return

		if(href_list["x"] && href_list["y"] && href_list["z"])
			var/tx = text2num(href_list["x"])
			var/ty = text2num(href_list["y"])
			var/tz = text2num(href_list["z"])
			var/turf/target = locate(tx, ty, tz)
			if(istype(target))
				abstract_move(target)
				return

		if(href_list["reenter"])
			reenter_corpse()
			return

		if(href_list["view"])
			var/atom/target = locate(href_list["view"])
			observer_view(target)
			return

		if(href_list["play"])
			var/atom/movable/target = locate(href_list["play"])
			jump_to_interact(target)

/// We orbit and interact with the target
/mob/dead/observer/proc/jump_to_interact(atom/target)
	if(isnull(target) || target == src)
		return

	ManualFollow(target)
	target.attack_ghost(usr)

/// We orbit the target or jump if its a turf
/mob/dead/observer/proc/observer_view(atom/target)
	if(isnull(target) || target == src)
		return

	if(isturf(target))
		abstract_move(target)
		return

	ManualFollow(target)

//We don't want to update the current var
//But we will still carry a mind.
/mob/dead/observer/mind_initialize()
	return

/mob/dead/observer/proc/show_data_huds()
	add_traits(observer_hud_traits, REF(src))

/mob/dead/observer/proc/remove_data_huds()
	remove_traits(observer_hud_traits, REF(src))

/mob/dead/observer/verb/toggle_data_huds()
	set name = "Toggle Sec/Med/Diag HUD"
	set desc = "Toggles whether you see medical/security/diagnostic HUDs"
	set category = "Ghost"

	if(data_huds_on) //remove old huds
		remove_data_huds()
		to_chat(src, span_notice("Data HUDs disabled."))
		data_huds_on = 0
	else
		show_data_huds()
		to_chat(src, span_notice("Data HUDs enabled."))
		data_huds_on = 1

/mob/dead/observer/verb/toggle_health_scan()
	set name = "Toggle Health Scan"
	set desc = "Toggles whether you health-scan living beings on click"
	set category = "Ghost"

	if(health_scan) //remove old huds
		to_chat(src, span_notice("Health scan disabled."))
		health_scan = FALSE
	else
		to_chat(src, span_notice("Health scan enabled."))
		health_scan = TRUE

/mob/dead/observer/verb/toggle_chem_scan()
	set name = "Toggle Chem Scan"
	set desc = "Toggles whether you scan living beings for chemicals and addictions on click"
	set category = "Ghost"

	if(chem_scan) //remove old huds
		to_chat(src, span_notice("Chem scan disabled."))
		chem_scan = FALSE
	else
		to_chat(src, span_notice("Chem scan enabled."))
		chem_scan = TRUE

/mob/dead/observer/verb/toggle_gas_scan()
	set name = "Toggle Gas Scan"
	set desc = "Toggles whether you analyze gas contents on click"
	set category = "Ghost"

	if(gas_scan)
		to_chat(src, span_notice("Gas scan disabled."))
		gas_scan = FALSE
	else
		to_chat(src, span_notice("Gas scan enabled."))
		gas_scan = TRUE

/mob/dead/observer/verb/restore_ghost_appearance()
	set name = "Restore Ghost Character"
	set desc = "Sets your deadchat name and ghost appearance to your \
		roundstart character."
	set category = "Ghost"

	set_ghost_appearance()
	if(client?.prefs)
		var/real_name = client.prefs.read_preference(/datum/preference/name/real_name)
		deadchat_name = real_name
		if(mind)
			mind.ghostname = real_name
		name = real_name

/mob/dead/observer/proc/set_ghost_appearance()
	if(!client?.prefs)
		return

	client.prefs.apply_character_randomization_prefs()

	var/species_type = client.prefs.read_preference(/datum/preference/choiced/species)
	var/datum/species/species = GLOB.species_prototypes[species_type]
	if(species.check_head_flags(HEAD_HAIR))
		hairstyle = client.prefs.read_preference(/datum/preference/choiced/hairstyle)
		hair_color = ghostify_color(client.prefs.read_preference(/datum/preference/color/hair_color))

	if(species.check_head_flags(HEAD_FACIAL_HAIR))
		facial_hairstyle = client.prefs.read_preference(/datum/preference/choiced/facial_hairstyle)
		facial_hair_color = ghostify_color(client.prefs.read_preference(/datum/preference/color/facial_hair_color))

	update_appearance()

/mob/dead/observer/can_perform_action(atom/movable/target, action_bitflags)
	return isAdminGhostAI(usr)

/mob/dead/observer/is_literate()
	return TRUE

/mob/dead/observer/can_read(atom/viewed_atom, reading_check_flags, silent)
	return TRUE // we want to bypass all the checks

/mob/dead/observer/vv_edit_var(var_name, var_value)
	. = ..()
	switch(var_name)
		if(NAMEOF(src, icon))
			ghostimage_default.icon = icon
			ghostimage_simple.icon = icon
		if(NAMEOF(src, icon_state))
			ghostimage_default.icon_state = icon_state
			ghostimage_simple.icon_state = icon_state
		if(NAMEOF(src, fun_verbs))
			if(fun_verbs)
				add_verb(src, /mob/dead/observer/verb/boo)
				add_verb(src, /mob/dead/observer/verb/possess)
			else
				remove_verb(src, /mob/dead/observer/verb/boo)
				remove_verb(src, /mob/dead/observer/verb/possess)

/mob/dead/observer/reset_perspective(atom/A)
	if(client)
		if(ismob(client.eye) && (client.eye != src))
			cleanup_observe()
	if(..())
		if(hud_used)
			client.clear_screen()
			hud_used.show_hud(hud_used.hud_version)


/mob/dead/observer/proc/cleanup_observe()
	if(isnull(observetarget))
		return
	var/mob/target = observetarget
	observetarget = null
	client?.perspective = initial(client.perspective)
	set_sight(initial(sight))
	if(target)
		UnregisterSignal(target, COMSIG_MOVABLE_Z_CHANGED)
		hide_other_mob_action_buttons(target)
		LAZYREMOVE(target.observers, src)

/mob/dead/observer/verb/observe()
	set name = "Observe"
	set category = "Ghost"

	if(!isobserver(usr)) //Make sure they're an observer!
		return

	reset_perspective(null)

	var/list/possible_destinations = SSpoints_of_interest.get_mob_pois()
	var/target = null

	target = tgui_input_list(usr, "Please, select a player!", "Jump to Mob", possible_destinations)
	if(isnull(target))
		return
	if (!isobserver(usr))
		return

	reset_perspective(null) // Reset again for sanity

	var/mob/chosen_target = possible_destinations[target]

	// During the break between opening the input menu and selecting our target, has this become an invalid option?
	if(!SSpoints_of_interest.is_valid_poi(chosen_target))
		return

	do_observe(chosen_target)

/mob/dead/observer/proc/do_observe(mob/mob_eye)
	if(isnewplayer(mob_eye))
		stack_trace("/mob/dead/new_player: \[[mob_eye]\] is being observed by [key_name(src)]. This should never happen and has been blocked.")
		message_admins("[ADMIN_LOOKUPFLW(src)] attempted to observe someone in the lobby: [ADMIN_LOOKUPFLW(mob_eye)]. This should not be possible and has been blocked.")
		return

	if(!isnull(observetarget))
		stack_trace("do_observe called on an observer ([src]) who was already observing something! (observing: [observetarget], new target: [mob_eye])")
		message_admins("[ADMIN_LOOKUPFLW(src)] attempted to observe someone while already observing someone, \
			this is a bug (and a past exploit) and should be investigated.")
		return

	//Istype so we filter out points of interest that are not mobs
	if(client && mob_eye && istype(mob_eye))
		client.set_eye(mob_eye)
		client.perspective = EYE_PERSPECTIVE
		if(is_secret_level(mob_eye.z) && !client?.holder)
			set_sight(null) //we dont want ghosts to see through walls in secret areas
		RegisterSignal(mob_eye, COMSIG_MOVABLE_Z_CHANGED, PROC_REF(on_observing_z_changed))
		if(mob_eye.hud_used)
			client.clear_screen()
			LAZYOR(mob_eye.observers, src)
			mob_eye.hud_used.show_hud(mob_eye.hud_used.hud_version, src)
			observetarget = mob_eye

/mob/dead/observer/proc/on_observing_z_changed(datum/source, turf/old_turf, turf/new_turf)
	SIGNAL_HANDLER

	if(is_secret_level(new_turf.z) && !client?.holder)
		set_sight(null) //we dont want ghosts to see through walls in secret areas
	else
		set_sight(initial(sight))

/mob/dead/observer/verb/register_pai_candidate()
	set category = "Ghost"
	set name = "pAI Setup"
	set desc = "Upload a fragment of your personality to the global pAI databanks"

	register_pai()

/mob/dead/observer/proc/register_pai()
	if(isobserver(src))
		SSpai.recruit_window(src)
	else
		to_chat(usr, span_warning("Can't become a pAI candidate while not dead!"))

/mob/dead/observer/verb/mafia_game_signup()
	set category = "Ghost"
	set name = "Signup for Mafia"
	set desc = "Sign up for a game of Mafia to pass the time while dead."

	mafia_signup()

/mob/dead/observer/proc/mafia_signup()
	if(!client)
		return
	if(!isobserver(src))
		to_chat(usr, span_warning("You must be a ghost to join mafia!"))
		return
	var/datum/mafia_controller/game = GLOB.mafia_game //this needs to change if you want multiple mafia games up at once.
	if(!game)
		game = create_mafia_game()
	game.ui_interact(usr)

/mob/dead/observer/AltClickOn(atom/target)
	client.loot_panel.open(get_turf(target))

/mob/dead/observer/AltClickSecondaryOn(atom/target)
	if(client && check_rights_for(client, R_DEBUG))
		client.toggle_tag_datum(src)

/mob/dead/observer/CtrlShiftClickOn(atom/target)
	if(isobserver(target) && check_rights(R_SPAWN))
		var/mob/dead/observer/target_ghost = target

		target_ghost.change_mob_type(/mob/living/carbon/human , null, null, TRUE) //always delmob, ghosts shouldn't be left lingering

/mob/dead/observer/examine(mob/user)
	. = ..()
	if(!invisibility)
		. += "It seems extremely obvious."

/mob/dead/observer/examine_more(mob/user)
	if(!isAdminObserver(user))
		return ..()
	. = list(span_notice("<i>You examine [src] closer, and note the following...</i>"))
	. += list("\t>[span_admin("[ADMIN_FULLMONTY(src)]")]")


/mob/dead/observer/proc/set_invisibility(value)
	SetInvisibility(value, id=type)
	set_light_on(!value ? TRUE : FALSE)


// Ghosts have no momentum, being massless ectoplasm
/mob/dead/observer/Process_Spacemove(movement_dir, continuous_move = FALSE)
	return TRUE

/mob/dead/observer/vv_edit_var(var_name, var_value)
	. = ..()
	if(var_name == NAMEOF(src, invisibility))
		set_invisibility(invisibility) // updates light

/proc/set_observer_default_invisibility(amount, message=null)
	for(var/mob/dead/observer/G in GLOB.player_list)
		G.set_invisibility(amount)
		if(message)
			to_chat(G, message)
	GLOB.observer_default_invisibility = amount

/mob/dead/observer/proc/open_spawners_menu()
	set name = "Spawners Menu"
	set desc = "See all currently available spawners"
	set category = "Ghost"
	if(!spawners_menu)
		spawners_menu = new(src)

	spawners_menu.ui_interact(src)

/mob/dead/observer/proc/open_minigames_menu()
	set name = "Minigames Menu"
	set desc = "See all currently available minigames"
	set category = "Ghost"
	if(!client)
		return
	if(!isobserver(src))
		to_chat(usr, span_warning("You must be a ghost to play minigames!"))
		return
	if(!minigames_menu)
		minigames_menu = new(src)

	minigames_menu.ui_interact(src)

/mob/dead/observer/proc/tray_view()
	set category = "Ghost"
	set name = "T-ray scan"
	set desc = "Perfom a scan to view sub-floor objects"

	if(SSlag_switch.measures[DISABLE_GHOST_ZOOM_TRAY] && !client?.holder)
		to_chat(usr, span_notice("That verb is currently globally disabled."))
		return

	t_ray_scan(src)

/mob/dead/observer/default_lighting_cutoff()
	var/datum/preferences/prefs = client?.prefs
	if(!prefs || (client?.combo_hud_enabled && prefs.toggles & COMBOHUD_LIGHTING))
		return ..()
	return GLOB.ghost_lighting_options[prefs.read_preference(/datum/preference/choiced/ghost_lighting)]


/// Called when we exit the orbiting state
/mob/dead/observer/proc/on_deorbit(datum/source)
	SIGNAL_HANDLER

	orbiting_ref = null
