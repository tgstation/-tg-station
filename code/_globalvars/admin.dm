GLOBAL_LIST_EMPTY(stickybanadminexemptions) //stores a list of ckeys exempted from a stickyban (workaround for a bug)
GLOBAL_LIST_EMPTY(stickybanadmintexts) //stores the entire stickyban list temporarily
GLOBAL_VAR(stickbanadminexemptiontimerid) //stores the timerid of the callback that restores all stickybans after an admin joins

/proc/init_smites()
	var/list/smites = list()
	for (var/_smite_path in subtypesof(/datum/smite))
		var/datum/smite/smite_path = _smite_path
		smites[initial(smite_path.name)] = smite_path
	return smites

GLOBAL_LIST_INIT_TYPED(smites, /datum/smite, init_smites())

GLOBAL_VAR_INIT(admin_notice, "") // Admin notice that all clients see when joining the server

// A list of all the special byond lists that need to be handled different by vv
GLOBAL_LIST_INIT(vv_special_lists, init_special_list_names())

/proc/init_special_list_names()
	var/list/output = list()
	var/obj/sacrifice = new
	for(var/varname in sacrifice.vars)
		var/value = sacrifice.vars[varname]
		if(!islist(value))
			if(!isdatum(value) && hascall(value, "Cut"))
				output += varname
			continue
		if(isnull(locate(REF(value))))
			output += varname
	return output

///A giant associative list of span names, and the associated key to create the text span. Used for narrate verbs.
GLOBAL_LIST_INIT(spanname_to_formatting, list(
	"Abductor" = "abductor",
	"Admin" = "admin",
	"Adminhelp" = "adminhelp",
	"Admin Notice" = "adminnotice",
	"Admin Observer OOC" = "adminobserverooc",
	"Admin OOC" = "adminooc",
	"Adminsay" = "adminsay",
	"AI Private Radio" = "aiprivradio",
	"Alert" = "alert",
	"Alien Alert" = "alertalien",
	"Syndie Alert" = "alertsyndie",
	"Alert Warning" = "alertwarning",
	"Alien" = "alien",
	"Average" = "average",
	"Bad" = "bad",
	"Big" = "big",
	"Binary Say" = "binarysay",
	"Blob" = "blob",
	"Blob Announce" = "blobannounce",
	"Blue" = "blue",
	"Blue Team Radio" = "blueteamradio",
	"Bold" = "bold",
	"Bold Announce" = "boldannounce",
	"Bold Danger" = "bolddanger",
	"Bold Italic" = "bolditalic",
	"Bold Nice Green" = "boldnicegreen",
	"Bold Notice" = "boldnotice",
	"Bold Warning" = "boldwarning",
	"Big Bold" = "big bold",
	"Captain-Cast" = "captaincast",
	"Centcom Radio" = "centcomradio",
	"Changeling" = "changeling",
	"Clown" = "clown",
	"Colossus" = "colossus",
	"Command Headset" = "command_headset",
	"Cult" = "cult",
	"Cult Bold" = "cult_bold",
	"Cult Bold Italic" = "cult_bold_italic",
	"Cult Italic" = "cult_italic",
	"Cult Large" = "cult_large",
	"Danger" = "danger",
	"Deadchat" = "deadsay",
	"Deconversion Message" = "deconversion_message",
	"Drone Radio" = "drone",
	"Engineering Radio" = "engradio",
	"Extremely Big" = "extremelybig",
	"Entertainment Radio" = "enteradio",
	"Game Say" = "game say",
	"Ghost Alert" = "ghostalert",
	"Green" = "green",
	"Green Announce" = "greenannounce",
	"Green Team Radio" = "greenteamradio",
	"Greentext" = "greentext",
	"Grey" = "grey",
	"Hierophant" = "hierophant",
	"Hierophant Warning" = "hierophant_warning",
	"Highlight" = "highlight",
	"His Grace" = "his_grace",
	"Holoparasite" = "holoparasite",
	"Holoparasite Bold" = "holoparasite bold",
	"Hypnosis" = "hypnophrase",
	"Icon" = "icon",
	"Info" = "info",
	"Info Plain" = "infoplain",
	"Interface" = "interface",
	"Looc" = "looc",
	"Medal" = "medal",
	"Medradio" = "medradio",
	"Message" = "message",
	"Mind Control" = "mind_control",
	"Monkey" = "monkey",
	"Narsie" = "narsie",
	"Narsie Small" = "narsiesmall",
	"Nice Green" = "nicegreen",
	"Notice" = "notice",
	"Notice Alien" = "noticealien",
	"OOC" = "ooc",
	"Papyrus" = "papyrus",
	"Phobia" = "phobia",
	"Prefix" = "prefix",
	"Purple" = "purple",
	"Radio" = "radio",
	"Really Big" = "reallybig",
	"Red" = "red",
	"Red Team Radio" = "redteamradio",
	"Red Text" = "redtext",
	"Golem Resonate" = "resonate",
	"Revenant Big Notice" = "revenbignotice",
	"Revenant Bold Notice" = "revenboldnotice",
	"Revenant Danger" = "revendanger",
	"Revenant Minor" = "revenminor",
	"Revenant Notice" = "revennotice",
	"Revenant Warning" = "revenwarning",
	"Robot" = "robot",
	"Rose" = "rose",
	"Comic Sans" = "sans",
	"Science Radio" = "sciradio",
	"Security Radio" = "secradio",
	"Service Radio" = "servradio",
	"Singing" = "singing",
	"Slime" = "slime",
	"Small" = "small",
	"Small Notice" = "smallnotice",
	"Small Notice Italic" = "smallnoticeital",
	"Spider Broodmother" = "spiderbroodmother",
	"Spider Scout" = "spiderscout",
	"Spider Breacher" = "spiderbreacher",
	"Suicide" = "suicide",
	"Supply Radio" = "suppradio",
	"Syndicate Radio" = "syndradio",
	"Tape Recorder" = "tape_recorder",
	"Tiny Notice" = "tinynotice",
	"Tiny Notice Italic" = "tinynoticeital",
	"Unconscious" = "unconscious",
	"User Danger" = "userdanger",
	"Warning" = "warning",
	"Yelling" = "yell",
	"Yellow Team Radio" = "yellowteamradio",
	))
