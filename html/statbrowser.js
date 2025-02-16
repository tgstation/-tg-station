// Polyfills and compatibility ------------------------------------------------
var decoder = decodeURIComponent || unescape;
if (!Array.prototype.includes) {
	Array.prototype.includes = function (thing) {
		for (var i = 0; i < this.length; i++) {
			if (this[i] == thing) return true;
		}
		return false;
	}
}
if (!String.prototype.trim) {
	String.prototype.trim = function () {
		return this.replace(/^[\s\uFEFF\xA0]+|[\s\uFEFF\xA0]+$/g, '');
	};
}

// Status panel implementation ------------------------------------------------
var status_tab_parts = ["Loading..."];
var current_tab = null;
var mc_tab_parts = [["Loading...", ""]];
var href_token = null;
var spells = [];
var spell_tabs = [];
var verb_tabs = [];
var verbs = [["", ""]]; // list with a list inside
var tickets = [];
var interviewManager = { status: "", interviews: [] };
var sdql2 = [];
var permanent_tabs = []; // tabs that won't be cleared by wipes
var turfcontents = [];
var turfname = "";
var imageRetryDelay = 500;
var imageRetryLimit = 50;
var menu = document.getElementById('menu');
var statcontentdiv = document.getElementById('statcontent');
var storedimages = [];
var split_admin_tabs = false;

// Any BYOND commands that could result in the client's focus changing go through this
// to ensure that when we relinquish our focus, we don't do it after the result of
// a command has already taken focus for itself.
function run_after_focus(callback) {
	setTimeout(callback, 0);
}

function createStatusTab(name) {
	if (name.indexOf(".") != -1) {
		var splitName = name.split(".");
		if (split_admin_tabs && splitName[0] === "Admin")
			name = splitName[1];
		else
			name = splitName[0];
	}
	if (document.getElementById(name) || name.trim() == "") {
		return;
	}
	if (!verb_tabs.includes(name) && !permanent_tabs.includes(name)) {
		return;
	}
	var button = document.createElement("DIV");
	button.onclick = function () {
		tab_change(name);
		this.blur();
		statcontentdiv.focus();
	};
	button.id = name;
	button.textContent = name;
	button.className = "button";
	//ORDERING ALPHABETICALLY
	button.style.order = ({"Status": 1, "MC": 2})[name] || name.charCodeAt(0);
	//END ORDERING
	menu.appendChild(button);
	SendTabToByond(name);
}

function removeStatusTab(name) {
	if (!document.getElementById(name) || permanent_tabs.includes(name)) {
		return;
	}
	for (var i = verb_tabs.length - 1; i >= 0; --i) {
		if (verb_tabs[i] == name) {
			verb_tabs.splice(i, 1);
		}
	}
	menu.removeChild(document.getElementById(name));
	TakeTabFromByond(name);
}

function sortVerbs() {
	verbs.sort(function (a, b) {
		var selector = a[0] == b[0] ? 1 : 0;
		if (a[selector].toUpperCase() < b[selector].toUpperCase()) {
			return 1;
		}
		else if (a[selector].toUpperCase() > b[selector].toUpperCase()) {
			return -1;
		}
		return 0;
	})
}

function addPermanentTab(name) {
	if (!permanent_tabs.includes(name)) {
		permanent_tabs.push(name);
	}
	createStatusTab(name);
}

function removePermanentTab(name) {
	for (var i = permanent_tabs.length - 1; i >= 0; --i) {
		if (permanent_tabs[i] == name) {
			permanent_tabs.splice(i, 1);
		}
	}
	removeStatusTab(name);
}

function checkStatusTab() {
	for (var i = 0; i < menu.children.length; i++) {
		if (!verb_tabs.includes(menu.children[i].id) && !permanent_tabs.includes(menu.children[i].id)) {
			menu.removeChild(menu.children[i]);
		}
	}
}

function remove_verb(v) {
	var verb_to_remove = v; // to_remove = [verb:category, verb:name]
	for (var i = verbs.length - 1; i >= 0; i--) {
		var part_to_remove = verbs[i];
		if (part_to_remove[1] == verb_to_remove[1]) {
			verbs.splice(i, 1)
		}
	}
}

function check_verbs() {
	for (var v = verb_tabs.length - 1; v >= 0; v--) {
		verbs_cat_check(verb_tabs[v]);
	}
}

function verbs_cat_check(cat) {
	var tabCat = cat;
	if (cat.indexOf(".") != -1) {
		var splitName = cat.split(".");
		if (split_admin_tabs && splitName[0] === "Admin")
			tabCat = splitName[1];
		else
			tabCat = splitName[0];
	}
	var verbs_in_cat = 0;
	var verbcat = "";
	if (!verb_tabs.includes(tabCat)) {
		removeStatusTab(tabCat);
		return;
	}
	for (var v = 0; v < verbs.length; v++) {
		var part = verbs[v];
		verbcat = part[0];
		if (verbcat.indexOf(".") != -1) {
			var splitName = verbcat.split(".");
			if (split_admin_tabs && splitName[0] === "Admin")
				verbcat = splitName[1];
			else
				verbcat = splitName[0];
		}
		if (verbcat != tabCat || verbcat.trim() == "") {
			continue;
		}
		else {
			verbs_in_cat = 1;
			break; // we only need one
		}
	}
	if (verbs_in_cat != 1) {
		removeStatusTab(tabCat);
		if (current_tab == tabCat)
			tab_change("Status");
	}
}

function findVerbindex(name, verblist) {
	for (var i = 0; i < verblist.length; i++) {
		var part = verblist[i];
		if (part[1] == name)
			return i;
	}
}
function wipe_verbs() {
	verbs = [["", ""]];
	verb_tabs = [];
	checkStatusTab(); // remove all empty verb tabs
}

function update_verbs() {
	wipe_verbs();
	Byond.sendMessage("Update-Verbs");
}

function SendTabsToByond() {
	var tabstosend = [];
	tabstosend = tabstosend.concat(permanent_tabs, verb_tabs);
	for (var i = 0; i < tabstosend.length; i++) {
		SendTabToByond(tabstosend[i]);
	}
}

function SendTabToByond(tab) {
	Byond.sendMessage("Send-Tabs", {tab: tab});
}

//Byond can't have this tab anymore since we're removing it
function TakeTabFromByond(tab) {
	Byond.sendMessage("Remove-Tabs", {tab: tab});
}

function spell_cat_check(cat) {
	var spells_in_cat = 0;
	var spellcat = "";
	for (var s = 0; s < spells.length; s++) {
		var spell = spells[s];
		spellcat = spell[0];
		if (spellcat == cat) {
			spells_in_cat++;
		}
	}
	if (spells_in_cat < 1) {
		removeStatusTab(cat);
	}
}

function tab_change(tab) {
	if (tab == current_tab) return;
	if (document.getElementById(current_tab))
		document.getElementById(current_tab).className = "button"; // disable active on last button
	current_tab = tab;
	set_byond_tab(tab);
	if (document.getElementById(tab))
		document.getElementById(tab).className = "button active"; // make current button active
	var spell_tabs_thingy = (spell_tabs.includes(tab));
	var verb_tabs_thingy = (verb_tabs.includes(tab));
	if (tab == "Status") {
		draw_status();
	} else if (tab == "MC") {
		draw_mc();
	} else if (spell_tabs_thingy) {
		draw_spells(tab);
	} else if (verb_tabs_thingy) {
		draw_verbs(tab);
	} else if (tab == "Debug Stat Panel") {
		draw_debug();
	} else if (tab == "Tickets") {
		draw_tickets();
		draw_interviews();
	} else if (tab == "SDQL2") {
		draw_sdql2();
	} else if (tab == turfname) {
		draw_listedturf();
	} else {
		statcontentdiv.textContext = "Loading...";
	}
	Byond.winset(Byond.windowId, {
		'is-visible': true,
	});
}

function set_byond_tab(tab) {
	Byond.sendMessage("Set-Tab", {tab: tab});
}

function draw_debug() {
	statcontentdiv.textContent = "";
	var wipeverbstabs = document.createElement("div");
	var link = document.createElement("a");
	link.onclick = function () { wipe_verbs() };
	link.textContent = "Wipe All Verbs";
	wipeverbstabs.appendChild(link);
	document.getElementById("statcontent").appendChild(wipeverbstabs);
	var wipeUpdateVerbsTabs = document.createElement("div");
	var updateLink = document.createElement("a");
	updateLink.onclick = function () { update_verbs() };
	updateLink.textContent = "Wipe and Update All Verbs";
	wipeUpdateVerbsTabs.appendChild(updateLink);
	document.getElementById("statcontent").appendChild(wipeUpdateVerbsTabs);
	var text = document.createElement("div");
	text.textContent = "Verb Tabs:";
	document.getElementById("statcontent").appendChild(text);
	var table1 = document.createElement("table");
	for (var i = 0; i < verb_tabs.length; i++) {
		var part = verb_tabs[i];
		// Hide subgroups except admin subgroups if they are split
		if (verb_tabs[i].lastIndexOf(".") != -1) {
			var splitName = verb_tabs[i].split(".");
			if (split_admin_tabs && splitName[0] === "Admin")
				part = splitName[1];
			else
				continue;
		}
		var tr = document.createElement("tr");
		var td1 = document.createElement("td");
		td1.textContent = part;
		var a = document.createElement("a");
		a.onclick = function (part) {
			return function () { removeStatusTab(part) };
		}(part);
		a.textContent = " Delete Tab " + part;
		td1.appendChild(a);
		tr.appendChild(td1);
		table1.appendChild(tr);
	}
	document.getElementById("statcontent").appendChild(table1);
	var header2 = document.createElement("div");
	header2.textContent = "Verbs:";
	document.getElementById("statcontent").appendChild(header2);
	var table2 = document.createElement("table");
	for (var v = 0; v < verbs.length; v++) {
		var part2 = verbs[v];
		var trr = document.createElement("tr");
		var tdd1 = document.createElement("td");
		tdd1.textContent = part2[0];
		var tdd2 = document.createElement("td");
		tdd2.textContent = part2[1];
		trr.appendChild(tdd1);
		trr.appendChild(tdd2);
		table2.appendChild(trr);
	}
	document.getElementById("statcontent").appendChild(table2);
	var text3 = document.createElement("div");
	text3.textContent = "Permanent Tabs:";
	document.getElementById("statcontent").appendChild(text3);
	var table3 = document.createElement("table");
	for (var i = 0; i < permanent_tabs.length; i++) {
		var part3 = permanent_tabs[i];
		var trrr = document.createElement("tr");
		var tddd1 = document.createElement("td");
		tddd1.textContent = part3;
		trrr.appendChild(tddd1);
		table3.appendChild(trrr);
	}
	document.getElementById("statcontent").appendChild(table3);

}
function draw_status() {
	if (!document.getElementById("Status")) {
		createStatusTab("Status");
		current_tab = "Status";
	}
	statcontentdiv.textContent = '';
	for (var i = 0; i < status_tab_parts.length; i++) {
		if (status_tab_parts[i].trim() == "") {
			document.getElementById("statcontent").appendChild(document.createElement("br"));
		} else {
			var div = document.createElement("div");
			div.textContent = status_tab_parts[i];
			div.className = "status-info";
			document.getElementById("statcontent").appendChild(div);
		}
	}
	if (verb_tabs.length == 0 || !verbs) {
		Byond.command("Fix-Stat-Panel");
	}
}

function draw_mc() {
	statcontentdiv.textContent = "";
	var table = document.createElement("table");
	for (var i = 0; i < mc_tab_parts.length; i++) {
		var part = mc_tab_parts[i];
		var tr = document.createElement("tr");
		var td1 = document.createElement("td");
		td1.textContent = part[0];
		var td2 = document.createElement("td");
		if (part[2]) {
			var a = document.createElement("a");
			a.href = "byond://?_src_=vars;admin_token=" + href_token + ";Vars=" + part[2];
			a.textContent = part[1];
			td2.appendChild(a);
		} else {
			td2.textContent = part[1];
		}
		tr.appendChild(td1);
		tr.appendChild(td2);
		table.appendChild(tr);
	}
	document.getElementById("statcontent").appendChild(table);
}

function remove_tickets() {
	if (tickets) {
		tickets = [];
		removePermanentTab("Tickets");
		if (current_tab == "Tickets")
			tab_change("Status");
	}
	checkStatusTab();
}

function remove_sdql2() {
	if (sdql2) {
		sdql2 = [];
		removePermanentTab("SDQL2");
		if (current_tab == "SDQL2")
			tab_change("Status");
	}
	checkStatusTab();
}

function remove_interviews() {
	if (tickets) {
		tickets = [];
	}
	checkStatusTab();
}

function iconError(e) {
	if(current_tab != turfname) {
		return;
	}
	setTimeout(function () {
		var node = e.target;
		var current_attempts = Number(node.getAttribute("data-attempts")) || 0
		if (current_attempts > imageRetryLimit) {
			return;
		}
		var src = node.src;
		node.src = null;
		node.src = src + '#' + current_attempts;
		node.setAttribute("data-attempts", current_attempts + 1)
		draw_listedturf();
	}, imageRetryDelay);
}

function draw_listedturf() {
	statcontentdiv.textContent = "";
	var table = document.createElement("table");
	for (var i = 0; i < turfcontents.length; i++) {
		var part = turfcontents[i];
		var clickfunc = function (part) {
			// The outer function is used to close over a fresh "part" variable,
			// rather than every onmousedown getting the "part" of the last entry.
			return function (e) {
				e.preventDefault();
				clickcatcher = "byond://?src=" + part[1];
				switch (e.button) {
					case 1:
						clickcatcher += ";statpanel_item_click=middle"
						break;
					case 2:
						clickcatcher += ";statpanel_item_click=right"
						break;
					default:
						clickcatcher += ";statpanel_item_click=left"
				}
				if (e.shiftKey) {
					clickcatcher += ";statpanel_item_shiftclick=1";
				}
				if (e.ctrlKey) {
					clickcatcher += ";statpanel_item_ctrlclick=1";
				}
				if (e.altKey) {
					clickcatcher += ";statpanel_item_altclick=1";
				}
				window.location.href = clickcatcher;
			}
		}(part);
		if (storedimages[part[1]] == null && part[2]) {
			var img = document.createElement("img");
			img.src = part[2];
			img.id = part[1];
			storedimages[part[1]] = part[2];
			img.onerror = iconError;
			img.onmousedown = clickfunc;
			table.appendChild(img);
		} else {
			var img = document.createElement("img");
			img.onerror = iconError;
			img.onmousedown = clickfunc;
			img.src = storedimages[part[1]];
			img.id = part[1];
			table.appendChild(img);
		}
		var b = document.createElement("div");
		var clickcatcher = "";
		b.className = "link";
		b.onmousedown = clickfunc;
		b.textContent = part[0];
		table.appendChild(b);
		table.appendChild(document.createElement("br"));
	}
	document.getElementById("statcontent").appendChild(table);
}

function remove_listedturf() {
	removePermanentTab(turfname);
	checkStatusTab();
	if (current_tab == turfname) {
		tab_change("Status");
	}
}

function remove_mc() {
	removePermanentTab("MC");
	if (current_tab == "MC") {
		tab_change("Status");
	}
};

function draw_sdql2() {
	statcontentdiv.textContent = "";
	var table = document.createElement("table");
	for (var i = 0; i < sdql2.length; i++) {
		var part = sdql2[i];
		var tr = document.createElement("tr");
		var td1 = document.createElement("td");
		td1.textContent = part[0];
		var td2 = document.createElement("td");
		if (part[2]) {
			var a = document.createElement("a");
			a.href = "byond://?src=" + part[2] + ";statpanel_item_click=left";
			a.textContent = part[1];
			td2.appendChild(a);
		} else {
			td2.textContent = part[1];
		}
		tr.appendChild(td1);
		tr.appendChild(td2);
		table.appendChild(tr);
	}
	document.getElementById("statcontent").appendChild(table);
}

function draw_tickets() {
	statcontentdiv.textContent = "";
	var table = document.createElement("table");
	if (!tickets) {
		return;
	}
	for (var i = 0; i < tickets.length; i++) {
		var part = tickets[i];
		var tr = document.createElement("tr");
		var td1 = document.createElement("td");
		td1.textContent = part[0];
		var td2 = document.createElement("td");
		if (part[2]) {
			var a = document.createElement("a");
			a.href = "byond://?_src_=holder;admin_token=" + href_token + ";ahelp=" + part[2] + ";ahelp_action=ticket;statpanel_item_click=left;action=ticket";
			a.textContent = part[1];
			td2.appendChild(a);
		} else if (part[3]) {
			var a = document.createElement("a");
			a.href = "byond://?src=" + part[3] + ";statpanel_item_click=left";
			a.textContent = part[1];
			td2.appendChild(a);
		} else {
			td2.textContent = part[1];
		}
		tr.appendChild(td1);
		tr.appendChild(td2);
		table.appendChild(tr);
	}
	document.getElementById("statcontent").appendChild(table);
}

function draw_interviews() {
	var body = document.createElement("div");
	var header = document.createElement("h3");
	header.textContent = "Interviews";
	body.appendChild(header);
	var manDiv = document.createElement("div");
	manDiv.className = "interview_panel_controls"
	var manLink = document.createElement("a");
	manLink.textContent = "Open Interview Manager Panel";
	manLink.href = "byond://?_src_=holder;admin_token=" + href_token + ";interview_man=1;statpanel_item_click=left";
	manDiv.appendChild(manLink);
	body.appendChild(manDiv);

	// List interview stats
	var statsDiv = document.createElement("table");
	statsDiv.className = "interview_panel_stats";
	for (var key in interviewManager.status) {
		var d = document.createElement("div");
		var tr = document.createElement("tr");
		var stat_name = document.createElement("td");
		var stat_text = document.createElement("td");
		stat_name.textContent = key;
		stat_text.textContent = interviewManager.status[key];
		tr.appendChild(stat_name);
		tr.appendChild(stat_text);
		statsDiv.appendChild(tr);
	}
	body.appendChild(statsDiv);
	document.getElementById("statcontent").appendChild(body);

	// List interviews if any are open
	var table = document.createElement("table");
	table.className = "interview_panel_table";
	if (!interviewManager) {
		return;
	}
	for (var i = 0; i < interviewManager.interviews.length; i++) {
		var part = interviewManager.interviews[i];
		var tr = document.createElement("tr");
		var td = document.createElement("td");
		var a = document.createElement("a");
		a.textContent = part["status"];
		a.href = "byond://?_src_=holder;admin_token=" + href_token + ";interview=" + part["ref"] + ";statpanel_item_click=left";
		td.appendChild(a);
		tr.appendChild(td);
		table.appendChild(tr);
	}
	document.getElementById("statcontent").appendChild(table);
}

function draw_spells(cat) {
	statcontentdiv.textContent = "";
	var table = document.createElement("table");
	for (var i = 0; i < spells.length; i++) {
		var part = spells[i];
		if (part[0] != cat) continue;
		var tr = document.createElement("tr");
		var td1 = document.createElement("td");
		td1.textContent = part[1];
		var td2 = document.createElement("td");
		if (part[3]) {
			var a = document.createElement("a");
			a.href = "byond://?src=" + part[3] + ";statpanel_item_click=left";
			a.textContent = part[2];
			td2.appendChild(a);
		} else {
			td2.textContent = part[2];
		}
		tr.appendChild(td1);
		tr.appendChild(td2);
		table.appendChild(tr);
	}
	document.getElementById("statcontent").appendChild(table);
}

function make_verb_onclick(command) {
	return function () {
		run_after_focus(function () {
			Byond.command(command);
		});
	};
}

function draw_verbs(cat) {
	statcontentdiv.textContent = "";
	var table = document.createElement("div");
	var additions = {}; // additional sub-categories to be rendered
	table.className = "grid-container";
	sortVerbs();
	if (split_admin_tabs && cat.lastIndexOf(".") != -1) {
		var splitName = cat.split(".");
		if (splitName[0] === "Admin")
			cat = splitName[1];
	}
	verbs.reverse(); // sort verbs backwards before we draw
	for (var i = 0; i < verbs.length; ++i) {
		var part = verbs[i];
		var name = part[0];
		if (split_admin_tabs && name.lastIndexOf(".") != -1) {
			var splitName = name.split(".");
			if (splitName[0] === "Admin")
				name = splitName[1];
		}
		var command = part[1];

		if (command && name.lastIndexOf(cat, 0) != -1 && (name.length == cat.length || name.charAt(cat.length) == ".")) {
			var subCat = name.lastIndexOf(".") != -1 ? name.split(".")[1] : null;
			if (subCat && !additions[subCat]) {
				var newTable = document.createElement("div");
				newTable.className = "grid-container";
				additions[subCat] = newTable;
			}

			var a = document.createElement("a");
			a.href = "#";
			a.onclick = make_verb_onclick(command.replace(/\s/g, "-"));
			a.className = "grid-item";
			var t = document.createElement("span");
			t.textContent = command;
			t.className = "grid-item-text";
			a.appendChild(t);
			(subCat ? additions[subCat] : table).appendChild(a);
		}
	}

	// Append base table to view
	var content = document.getElementById("statcontent");
	content.appendChild(table);

	// Append additional sub-categories if relevant
	for (var cat in additions) {
		if (additions.hasOwnProperty(cat)) {
			// do addition here
			var header = document.createElement("h3");
			header.textContent = cat;
			content.appendChild(header);
			content.appendChild(additions[cat]);
		}
	}
}

function set_theme(which) {
	if (which == "light") {
		document.body.className = "";
		document.documentElement.className = 'light';
		set_style_sheet("browserOutput_white");
	} else if (which == "dark") {
		document.body.className = "dark";
		document.documentElement.className = 'dark';
		set_style_sheet("browserOutput");
	}
}

function set_font_size(size) {
	document.body.style.setProperty('font-size', size);
}

function set_tabs_style(style) {
	if (style == "default") {
		menu.classList.add('menu-wrap');
		menu.classList.remove('tabs-classic');
	} else if (style == "classic") {
		menu.classList.add('menu-wrap');
		menu.classList.add('tabs-classic');
	} else if (style == "scrollable") {
		menu.classList.remove('menu-wrap');
		menu.classList.remove('tabs-classic');
	}
}

function set_style_sheet(sheet) {
	if (document.getElementById("goonStyle")) {
		var currentSheet = document.getElementById("goonStyle");
		currentSheet.parentElement.removeChild(currentSheet);
	}
	var head = document.getElementsByTagName('head')[0];
	var sheetElement = document.createElement("link");
	sheetElement.id = "goonStyle";
	sheetElement.rel = "stylesheet";
	sheetElement.type = "text/css";
	sheetElement.href = sheet + ".css";
	sheetElement.media = 'all';
	head.appendChild(sheetElement);
}

function restoreFocus() {
	run_after_focus(function () {
		Byond.winset('map', {
			focus: true,
		});
	});
}

function getCookie(cname) {
	var name = cname + '=';
	var ca = document.cookie.split(';');
	for (var i = 0; i < ca.length; i++) {
		var c = ca[i];
		while (c.charAt(0) == ' ') c = c.substring(1);
		if (c.indexOf(name) === 0) {
			return decoder(c.substring(name.length, c.length));
		}
	}
	return '';
}

function add_verb_list(payload) {
	var to_add = payload; // list of a list with category and verb inside it
	to_add.sort(); // sort what we're adding
	for (var i = 0; i < to_add.length; i++) {
		var part = to_add[i];
		if (!part[0])
			continue;
		var category = part[0];
		if (category.indexOf(".") != -1) {
			var splitName = category.split(".");
			if (split_admin_tabs && splitName[0] === "Admin")
				category = splitName[1];
			else
				category = splitName[0];
		}
		if (findVerbindex(part[1], verbs))
			continue;
		if (verb_tabs.includes(category)) {
			verbs.push(part);
			if (current_tab == category) {
				draw_verbs(category); // redraw if we added a verb to the tab we're currently in
			}
		} else if (category) {
			verb_tabs.push(category);
			verbs.push(part);
			createStatusTab(category);
		}
	}
};

function init_spells() {
	var cat = "";
	for (var i = 0; i < spell_tabs.length; i++) {
		cat = spell_tabs[i];
		if (cat.length > 0) {
			verb_tabs.push(cat);
			createStatusTab(cat);
		}
	}
}

document.addEventListener("mouseup", restoreFocus);
document.addEventListener("keyup", restoreFocus);

if (!current_tab) {
	addPermanentTab("Status");
	tab_change("Status");
}

window.onload = function () {
	Byond.sendMessage("Update-Verbs");
};

Byond.subscribeTo('update_spells', function (payload) {
	spell_tabs = payload.spell_tabs;
	var do_update = false;
	if (spell_tabs.includes(current_tab)) {
		do_update = true;
	}
	init_spells();
	if (payload.actions) {
		spells = payload.actions;
		if (do_update) {
			draw_spells(current_tab);
		}
	} else {
		remove_spells();
	}
});

Byond.subscribeTo('remove_verb_list', function (v) {
	var to_remove = v;
	for (var i = 0; i < to_remove.length; i++) {
		remove_verb(to_remove[i]);
	}
	check_verbs();
	sortVerbs();
	if (verb_tabs.includes(current_tab))
		draw_verbs(current_tab);
});

// passes a 2D list of (verbcategory, verbname) creates tabs and adds verbs to respective list
// example (IC, Say)
Byond.subscribeTo('init_verbs', function (payload) {
	wipe_verbs(); // remove all verb categories so we can replace them
	checkStatusTab(); // remove all status tabs
	verb_tabs = payload.panel_tabs;
	verb_tabs.sort(); // sort it
	var do_update = false;
	var cat = "";
	for (var i = 0; i < verb_tabs.length; i++) {
		cat = verb_tabs[i];
		createStatusTab(cat); // create a category if the verb doesn't exist yet
	}
	if (verb_tabs.includes(current_tab)) {
		do_update = true;
	}
	if (payload.verblist) {
		add_verb_list(payload.verblist);
		sortVerbs(); // sort them
		if (do_update) {
			draw_verbs(current_tab);
		}
	}
	SendTabsToByond();
});

Byond.subscribeTo('update_stat', function (payload) {
	status_tab_parts = [payload.ping_str];
	var parsed = payload.global_data;

	for (var i = 0; i < parsed.length; i++) if (parsed[i] != null) status_tab_parts.push(parsed[i]);

	parsed = payload.other_str;

	for (var i = 0; i < parsed.length; i++) if (parsed[i] != null) status_tab_parts.push(parsed[i]);

	if (current_tab == "Status") {
		draw_status();
	} else if (current_tab == "Debug Stat Panel") {
		draw_debug();
	}
});

Byond.subscribeTo('update_mc', function (payload) {
	mc_tab_parts = payload.mc_data;
	mc_tab_parts.splice(0, 0, ["Location:", payload.coord_entry]);

	if (!verb_tabs.includes("MC")) {
		verb_tabs.push("MC");
	}

	createStatusTab("MC");

	if (current_tab == "MC") {
		draw_mc();
	}
});

Byond.subscribeTo('remove_spells', function () {
	for (var s = 0; s < spell_tabs.length; s++) {
		removeStatusTab(spell_tabs[s]);
	}
});

Byond.subscribeTo('init_spells', function () {
	var cat = "";
	for (var i = 0; i < spell_tabs.length; i++) {
		cat = spell_tabs[i];
		if (cat.length > 0) {
			verb_tabs.push(cat);
			createStatusTab(cat);
		}
	}
});

Byond.subscribeTo('check_spells', function () {
	for (var v = 0; v < spell_tabs.length; v++) {
		spell_cat_check(spell_tabs[v]);
	}
});

Byond.subscribeTo('create_debug', function () {
	if (!document.getElementById("Debug Stat Panel")) {
		addPermanentTab("Debug Stat Panel");
	} else {
		removePermanentTab("Debug Stat Panel");
	}
});

Byond.subscribeTo('create_listedturf', function (TN) {
	remove_listedturf(); // remove the last one if we had one
	turfname = TN;
	addPermanentTab(turfname);
	tab_change(turfname);
});

Byond.subscribeTo('remove_admin_tabs', function () {
	href_token = null;
	remove_mc();
	remove_tickets();
	remove_sdql2();
	remove_interviews();
});

Byond.subscribeTo('update_listedturf', function (TC) {
	turfcontents = TC;
	if (current_tab == turfname) {
		draw_listedturf();
	}
});

Byond.subscribeTo('update_interviews', function (I) {
	interviewManager = I;
	if (current_tab == "Tickets") {
		draw_interviews();
	}
});

Byond.subscribeTo('update_split_admin_tabs', function (status) {
	status = (status == true);

	if (split_admin_tabs !== status) {
		if (split_admin_tabs === true) {
			removeStatusTab("Events");
			removeStatusTab("Fun");
			removeStatusTab("Game");
		}
		update_verbs();
	}
	split_admin_tabs = status;
});

Byond.subscribeTo('add_admin_tabs', function (ht) {
	href_token = ht;
	addPermanentTab("MC");
	addPermanentTab("Tickets");
});

Byond.subscribeTo('update_sdql2', function (S) {
	sdql2 = S;
	if (sdql2.length > 0 && !verb_tabs.includes("SDQL2")) {
		verb_tabs.push("SDQL2");
		addPermanentTab("SDQL2");
	}
	if (current_tab == "SDQL2") {
		draw_sdql2();
	}
});

Byond.subscribeTo('update_tickets', function (T) {
	tickets = T;
	if (!verb_tabs.includes("Tickets")) {
		verb_tabs.push("Tickets");
		addPermanentTab("Tickets");
	}
	if (current_tab == "Tickets") {
		draw_tickets();
	}
});

Byond.subscribeTo('remove_listedturf', remove_listedturf);

Byond.subscribeTo('remove_sdql2', remove_sdql2);

Byond.subscribeTo('remove_mc', remove_mc);

Byond.subscribeTo('add_verb_list', add_verb_list);
