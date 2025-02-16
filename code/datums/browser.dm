/datum/browser
	var/mob/user
	var/title
	var/window_id // window_id is used as the window name for browse and onclose
	var/width = 0
	var/height = 0
	var/datum/weakref/ref = null
	var/window_options = "can_close=1;can_minimize=1;can_maximize=0;can_resize=1;titlebar=1;" // window option is set using window_id
	var/stylesheets[0]
	var/scripts[0]
	var/head_elements
	var/body_elements
	var/head_content = ""
	var/content = ""

/datum/browser/New(nuser, nwindow_id, ntitle = 0, nwidth = 0, nheight = 0, atom/nref = null)
	user = nuser
	RegisterSignal(user, COMSIG_QDELETING, PROC_REF(user_deleted))
	window_id = nwindow_id
	if (ntitle)
		title = format_text(ntitle)
	if (nwidth)
		width = nwidth
	if (nheight)
		height = nheight
	if (nref)
		ref = WEAKREF(nref)

/datum/browser/proc/user_deleted(datum/source)
	SIGNAL_HANDLER
	user = null

/datum/browser/proc/add_head_content(nhead_content)
	head_content = nhead_content

/datum/browser/proc/set_window_options(nwindow_options)
	window_options = nwindow_options

/datum/browser/proc/add_stylesheet(name, file)
	if (istype(name, /datum/asset/spritesheet))
		var/datum/asset/spritesheet/sheet = name
		stylesheets["spritesheet_[sheet.name].css"] = "data/spritesheets/[sheet.name]"
	else if (istype(name, /datum/asset/spritesheet_batched))
		var/datum/asset/spritesheet_batched/sheet = name
		stylesheets["spritesheet_[sheet.name].css"] = "data/spritesheets/[sheet.name]"
	else
		var/asset_name = "[name].css"

		stylesheets[asset_name] = file

		if (!SSassets.cache[asset_name])
			SSassets.transport.register_asset(asset_name, file)

/datum/browser/proc/add_script(name, file)
	scripts["[ckey(name)].js"] = file
	SSassets.transport.register_asset("[ckey(name)].js", file)

/datum/browser/proc/set_content(ncontent)
	content = ncontent

/datum/browser/proc/add_content(ncontent)
	content += ncontent

/datum/browser/proc/get_header()
	var/datum/asset/simple/namespaced/common/common_asset = get_asset_datum(/datum/asset/simple/namespaced/common)
	var/file
	head_content += "<link rel='stylesheet' type='text/css' href='[common_asset.get_url_mappings()["common.css"]]'>"
	for (file in stylesheets)
		head_content += "<link rel='stylesheet' type='text/css' href='[SSassets.transport.get_asset_url(file)]'>"


	for (file in scripts)
		head_content += "<script type='text/javascript' src='[SSassets.transport.get_asset_url(file)]'></script>"

	return {"<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.01 Transitional//EN" "http://www.w3.org/TR/html4/loose.dtd">
<html>
	<head>
		<meta http-equiv='Content-Type' content='text/html; charset=UTF-8'>
		<meta http-equiv='X-UA-Compatible' content='IE=edge'>
		[head_content]
	</head>
	<body scroll=auto>
		<div class='uiWrapper'>
			[title ? "<div class='uiTitleWrapper'><div class='uiTitle'><tt>[title]</tt></div></div>" : ""]
			<div class='uiContent'>
	"}
//" This is here because else the rest of the file looks like a string in notepad++.
/datum/browser/proc/get_footer()
	return {"
			</div>
		</div>
	</body>
</html>"}

/datum/browser/proc/get_content()
	return {"
	[get_header()]
	[content]
	[get_footer()]
	"}

/datum/browser/proc/open(use_onclose = TRUE)
	if(isnull(window_id)) //null check because this can potentially nuke goonchat
		WARNING("Browser [title] tried to open with a null ID")
		to_chat(user, span_userdanger("The [title] browser you tried to open failed a sanity check! Please report this on GitHub!"))
		return
	var/window_size = ""
	if (width && height)
		window_size = "size=[width]x[height];"
	var/datum/asset/simple/namespaced/common/common_asset = get_asset_datum(/datum/asset/simple/namespaced/common)
	common_asset.send(user)
	if (stylesheets.len)
		SSassets.transport.send_assets(user, stylesheets)
	if (scripts.len)
		SSassets.transport.send_assets(user, scripts)
	user << browse(get_content(), "window=[window_id];[window_size][window_options]")
	if (use_onclose)
		setup_onclose()

/datum/browser/proc/setup_onclose()
	set waitfor = 0 //winexists sleeps, so we don't need to.
	for (var/i in 1 to 10)
		if (user?.client && winexists(user, window_id))
			var/atom/send_ref
			if(ref)
				send_ref = ref.resolve()
				if(!send_ref)
					ref = null
			onclose(user, window_id, send_ref)
			break

/datum/browser/proc/close()
	if(!isnull(window_id))//null check because this can potentially nuke goonchat
		user << browse(null, "window=[window_id]")
	else
		WARNING("Browser [title] tried to close with a null ID")

/datum/browser/modal/alert/New(User,Message,Title,Button1="Ok",Button2,Button3,StealFocus = 1,Timeout=6000)
	if (!User)
		return

	var/output = {"<center><b>[Message]</b></center><br />
		<div style="text-align:center">
		<a style="font-size:large;float:[( Button2 ? "left" : "right" )]" href='byond://?src=[REF(src)];button=1'>[Button1]</a>"}

	if (Button2)
		output += {"<a style="font-size:large;[( Button3 ? "" : "float:right" )]" href='byond://?src=[REF(src)];button=2'>[Button2]</a>"}

	if (Button3)
		output += {"<a style="font-size:large;float:right" href='byond://?src=[REF(src)];button=3'>[Button3]</a>"}

	output += {"</div>"}

	..(User, ckey("[User]-[Message]-[Title]-[world.time]-[rand(1,10000)]"), Title, 350, 150, src, StealFocus, Timeout)
	set_content(output)

/datum/browser/modal/alert/Topic(href,href_list)
	if (href_list["close"] || !user || !user.client)
		opentime = 0
		return
	if (href_list["button"])
		var/button = text2num(href_list["button"])
		if (button <= 3 && button >= 1)
			selectedbutton = button
	opentime = 0
	close()

/**
 * **DEPRECATED: USE tgui_alert(...) INSTEAD**
 *
 * Designed as a drop in replacement for alert(); functions the same. (outside of needing User specified)
 * Arguments:
 * * User - The user to show the alert to.
 * * Message - The textual body of the alert.
 * * Title - The title of the alert's window.
 * * Button1 - The first button option.
 * * Button2 - The second button option.
 * * Button3 - The third button option.
 * * StealFocus - Boolean operator controlling if the alert will steal the user's window focus.
 * * Timeout - The timeout of the window, after which no responses will be valid.
 */
/proc/tgalert(mob/User, Message, Title, Button1="Ok", Button2, Button3, StealFocus = TRUE, Timeout = 6000)
	if (!User)
		User = usr
	if (!istype(User))
		if (istype(User, /client))
			var/client/client = User
			User = client.mob
		else
			return

	// Get user's response using a modal
	var/datum/browser/modal/alert/A = new(User, Message, Title, Button1, Button2, Button3, StealFocus, Timeout)
	A.open()
	A.wait()
	switch(A.selectedbutton)
		if (1)
			return Button1
		if (2)
			return Button2
		if (3)
			return Button3

/datum/browser/modal
	var/opentime = 0
	var/timeout
	var/selectedbutton = 0
	var/stealfocus

/datum/browser/modal/New(nuser, nwindow_id, ntitle = 0, nwidth = 0, nheight = 0, atom/nref = null, StealFocus = 1, Timeout = 6000)
	..()
	stealfocus = StealFocus
	if (!StealFocus)
		window_options += "focus=false;"
	timeout = Timeout


/datum/browser/modal/close()
	.=..()
	opentime = 0

/datum/browser/modal/open(use_onclose)
	set waitfor = FALSE
	opentime = world.time

	if (stealfocus)
		. = ..(use_onclose = 1)
	else
		var/focusedwindow = winget(user, null, "focus")
		. = ..(use_onclose = 1)

		//waits for the window to show up client side before attempting to un-focus it
		//winexists sleeps until it gets a reply from the client, so we don't need to bother sleeping
		for (var/i in 1 to 10)
			if (user && winexists(user, window_id))
				if (focusedwindow)
					winset(user, focusedwindow, "focus=true")
				else
					winset(user, "mapwindow", "focus=true")
				break
	if (timeout)
		addtimer(CALLBACK(src, PROC_REF(close)), timeout)

/datum/browser/modal/proc/wait()
	while (opentime && selectedbutton <= 0 && (!timeout || opentime+timeout > world.time))
		stoplag(1)

/datum/browser/modal/listpicker
	var/valueslist = list()

/datum/browser/modal/listpicker/New(User,Message,Title,Button1="Ok",Button2,Button3,StealFocus = 1, Timeout = FALSE,list/values,inputtype="checkbox", width, height, slidecolor)
	if (!User)
		return

	var/output = {"<form><input type="hidden" name="src" value="[REF(src)]"><ul class="sparse">"}
	if (inputtype == "checkbox" || inputtype == "radio")
		for (var/i in values)
			var/div_slider = slidecolor
			if(!i["allowed_edit"])
				div_slider = "locked"
			output += {"<li>
						<label class="switch">
							<input type="[inputtype]" value="1" name="[i["name"]]"[i["checked"] ? " checked" : ""][i["allowed_edit"] ? "" : " onclick='return false' onkeydown='return false'"]>
								<div class="slider [div_slider ? "[div_slider]" : ""]"></div>
									<span>[i["name"]]</span>
						</label>
						</li>"}
	else
		for (var/i in values)
			output += {"<li><input id="name="[i["name"]]"" style="width: 50px" type="[type]" name="[i["name"]]" value="[i["value"]]">
			<label for="[i["name"]]">[i["name"]]</label></li>"}
	output += {"</ul><div style="text-align:center">
		<button type="submit" name="button" value="1" style="font-size:large;float:[( Button2 ? "left" : "right" )]">[Button1]</button>"}

	if (Button2)
		output += {"<button type="submit" name="button" value="2" style="font-size:large;[( Button3 ? "" : "float:right" )]">[Button2]</button>"}

	if (Button3)
		output += {"<button type="submit" name="button" value="3" style="font-size:large;float:right">[Button3]</button>"}

	output += {"</form></div>"}
	..(User, ckey("[User]-[Message]-[Title]-[world.time]-[rand(1,10000)]"), Title, width, height, src, StealFocus, Timeout)
	set_content(output)

/datum/browser/modal/listpicker/Topic(href,href_list)
	if (href_list["close"] || !user || !user.client)
		opentime = 0
		return
	if (href_list["button"])
		var/button = text2num(href_list["button"])
		if (button <= 3 && button >= 1)
			selectedbutton = button
	for (var/item in href_list)
		switch(item)
			if ("close", "button", "src")
				continue
			else
				valueslist[item] = href_list[item]
	opentime = 0
	close()

/proc/presentpicker(mob/User,Message, Title, Button1="Ok", Button2, Button3, StealFocus = 1,Timeout = 6000,list/values, inputtype = "checkbox", width, height, slidecolor)
	if (!istype(User))
		if (istype(User, /client/))
			var/client/C = User
			User = C.mob
		else
			return
	var/datum/browser/modal/listpicker/A = new(User, Message, Title, Button1, Button2, Button3, StealFocus,Timeout, values, inputtype, width, height, slidecolor)
	A.open()
	A.wait()
	if (A.selectedbutton)
		return list("button" = A.selectedbutton, "values" = A.valueslist)

/proc/input_bitfield(mob/User, title, bitfield, current_value, nwidth = 350, nheight = 350, nslidecolor, allowed_edit_list = null)
	if (!User || !(bitfield in GLOB.bitfields))
		return
	var/list/pickerlist = list()
	for (var/i in GLOB.bitfields[bitfield])
		var/can_edit = 1
		if(!isnull(allowed_edit_list) && !(allowed_edit_list & GLOB.bitfields[bitfield][i]))
			can_edit = 0
		if (current_value & GLOB.bitfields[bitfield][i])
			pickerlist += list(list("checked" = 1, "value" = GLOB.bitfields[bitfield][i], "name" = i, "allowed_edit" = can_edit))
		else
			pickerlist += list(list("checked" = 0, "value" = GLOB.bitfields[bitfield][i], "name" = i, "allowed_edit" = can_edit))
	var/list/result = presentpicker(User, "", title, Button1="Save", Button2 = "Cancel", Timeout=FALSE, values = pickerlist, width = nwidth, height = nheight, slidecolor = nslidecolor)
	if (islist(result))
		if (result["button"] == 2) // If the user pressed the cancel button
			return
		. = 0
		for (var/flag in result["values"])
			. |= GLOB.bitfields[bitfield][flag]
	else
		return

/datum/browser/modal/preflikepicker
	var/settings = list()
	var/icon/preview_icon = null
	var/datum/callback/preview_update

/datum/browser/modal/preflikepicker/New(User,Message,Title,Button1="Ok",Button2,Button3,StealFocus = 1, Timeout = FALSE,list/settings,inputtype="checkbox", width = 600, height, slidecolor)
	if (!User)
		return
	src.settings = settings

	..(User, ckey("[User]-[Message]-[Title]-[world.time]-[rand(1,10000)]"), Title, width, height, src, StealFocus, Timeout)
	set_content(ShowChoices(User))

/datum/browser/modal/preflikepicker/proc/ShowChoices(mob/user)
	if (settings["preview_callback"])
		var/datum/callback/callback = settings["preview_callback"]
		preview_icon = callback.Invoke(settings)
		if (preview_icon)
			user << browse_rsc(preview_icon, "previewicon.png")
	var/dat = ""

	for (var/name in settings["mainsettings"])
		var/setting = settings["mainsettings"][name]
		if (setting["type"] == "datum")
			if (setting["subtypesonly"])
				dat += "<b>[setting["desc"]]:</b> <a href='byond://?src=[REF(src)];setting=[name];task=input;subtypesonly=1;type=datum;path=[setting["path"]]'>[setting["value"]]</a><BR>"
			else
				dat += "<b>[setting["desc"]]:</b> <a href='byond://?src=[REF(src)];setting=[name];task=input;type=datum;path=[setting["path"]]'>[setting["value"]]</a><BR>"
		else
			dat += "<b>[setting["desc"]]:</b> <a href='byond://?src=[REF(src)];setting=[name];task=input;type=[setting["type"]]'>[setting["value"]]</a><BR>"

	if (preview_icon)
		dat += "<td valign='center'>"

		dat += "<div class='statusDisplay'><center><img src=previewicon.png width=[preview_icon.Width()] height=[preview_icon.Height()]></center></div>"

		dat += "</td>"

	dat += "</tr></table>"

	dat += "<hr><center><a href='byond://?src=[REF(src)];button=1'>Ok</a> "

	dat += "</center>"

	return dat

/datum/browser/modal/preflikepicker/Topic(href,href_list)
	if (href_list["close"] || !user || !user.client)
		opentime = 0
		return
	if (href_list["task"] == "input")
		var/setting = href_list["setting"]
		switch (href_list["type"])
			if ("datum")
				var/oldval = settings["mainsettings"][setting]["value"]
				if (href_list["subtypesonly"])
					settings["mainsettings"][setting]["value"] = pick_closest_path(null, make_types_fancy(subtypesof(text2path(href_list["path"]))))
				else
					settings["mainsettings"][setting]["value"] = pick_closest_path(null, make_types_fancy(typesof(text2path(href_list["path"]))))
				if (isnull(settings["mainsettings"][setting]["value"]))
					settings["mainsettings"][setting]["value"] = oldval
			if ("string")
				settings["mainsettings"][setting]["value"] = stripped_input(user, "Enter new value for [settings["mainsettings"][setting]["desc"]]", "Enter new value for [settings["mainsettings"][setting]["desc"]]", settings["mainsettings"][setting]["value"])
			if ("number")
				settings["mainsettings"][setting]["value"] = input(user, "Enter new value for [settings["mainsettings"][setting]["desc"]]", "Enter new value for [settings["mainsettings"][setting]["desc"]]") as num
			if ("color")
				settings["mainsettings"][setting]["value"] = input(user, "Enter new value for [settings["mainsettings"][setting]["desc"]]", "Enter new value for [settings["mainsettings"][setting]["desc"]]", settings["mainsettings"][setting]["value"]) as color
			if ("boolean")
				settings["mainsettings"][setting]["value"] = (settings["mainsettings"][setting]["value"] == "Yes") ? "No" : "Yes"
			if ("ckey")
				settings["mainsettings"][setting]["value"] = input(user, "[settings["mainsettings"][setting]["desc"]]?") in list("none") + GLOB.directory
		if (settings["mainsettings"][setting]["callback"])
			var/datum/callback/callback = settings["mainsettings"][setting]["callback"]
			settings = callback.Invoke(settings)
	if (href_list["button"])
		var/button = text2num(href_list["button"])
		if (button <= 3 && button >= 1)
			selectedbutton = button
	if (selectedbutton != 1)
		set_content(ShowChoices(user))
		open()
		return
	for (var/item in href_list)
		switch(item)
			if ("close", "button", "src")
				continue
	opentime = 0
	close()

/proc/presentpreflikepicker(mob/User,Message, Title, Button1="Ok", Button2, Button3, StealFocus = 1,Timeout = 6000,list/settings, width, height, slidecolor)
	if (!istype(User))
		if (istype(User, /client/))
			var/client/C = User
			User = C.mob
		else
			return
	var/datum/browser/modal/preflikepicker/A = new(User, Message, Title, Button1, Button2, Button3, StealFocus,Timeout, settings, width, height, slidecolor)
	A.open()
	A.wait()
	if (A.selectedbutton)
		return list("button" = A.selectedbutton, "settings" = A.settings)

// Registers the on-close verb for a browse window (client/verb/.windowclose)
// this will be called when the close-button of a window is pressed.
//
// This is usually only needed for devices that regularly update the browse window,
// e.g. canisters, timers, etc.
//
// windowid should be the specified window name
// e.g. code is : user << browse(text, "window=fred")
// then use : onclose(user, "fred")
//
// Optionally, specify the "ref" parameter as the controlled atom (usually src)
// to pass a "close=1" parameter to the atom's Topic() proc for special handling.
// Otherwise, the user mob's machine var will be reset directly.
//
/proc/onclose(mob/user, windowid, atom/ref=null)
	if(!user.client)
		return
	var/param = "null"
	if(ref)
		param = "[REF(ref)]"

	winset(user, windowid, "on-close=\".windowclose [param]\"")



// the on-close client verb
// called when a browser popup window is closed after registering with proc/onclose()
// if a valid atom reference is supplied, call the atom's Topic() with "close=1"
// otherwise, just reset the client mob's machine var.
//
/client/verb/windowclose(atomref as text)
	set hidden = TRUE // hide this verb from the user's panel
	set name = ".windowclose" // no autocomplete on cmd line

	if(atomref != "null") // if passed a real atomref
		var/hsrc = locate(atomref) // find the reffed atom
		var/href = "close=1"
		if(hsrc)
			usr = src.mob
			src.Topic(href, params2list(href), hsrc) // this will direct to the atom's
			return // Topic() proc via client.Topic()

