#define VV_NUM "Number"
#define VV_TEXT "Text"
#define VV_MESSAGE "Multiline Text"
#define VV_COLOR "Color"
#define VV_COLOR_MATRIX "Color Matrix"
#define VV_ICON "Icon"
#define VV_ATOM_REFERENCE "Atom Reference"
#define VV_DATUM_REFERENCE "Datum Reference"
#define VV_MOB_REFERENCE "Mob Reference"
#define VV_CLIENT "Client"
#define VV_ATOM_TYPE "Atom Typepath"
#define VV_DATUM_TYPE "Datum Typepath"
#define VV_TYPE "Custom Typepath"
#define VV_FILE "File"
#define VV_LIST "List"
#define VV_NEW_ATOM "New Atom"
#define VV_NEW_DATUM "New Datum"
#define VV_NEW_TYPE "New Custom Typepath"
#define VV_NEW_LIST "New List"
#define VV_NULL "NULL"
#define VV_INFINITY "Infinity"
#define VV_RESTORE_DEFAULT "Restore to Default"
#define VV_MARKED_DATUM "Marked Datum"
#define VV_TAGGED_DATUM "Tagged Datum"
#define VV_BITFIELD "Bitfield"
#define VV_TEXT_LOCATE "Custom Reference Locate"
#define VV_PROCCALL_RETVAL "Return Value of Proccall"
#define VV_WEAKREF "Weak Reference Datum"

#define VV_MSG_MARKED "<br><font size='1' color='red'><b>Marked Object</b></font>"
#define VV_MSG_TAGGED(num) "<br><font size='1' color='red'><b>Tagged Datum #[num]</b></font>"
#define VV_MSG_EDITED "<br><font size='1' color='red'><b>Var Edited</b></font>"
#define VV_MSG_DELETED "<br><font size='1' color='red'><b>Deleted</b></font>"

#define VV_NORMAL_LIST_NO_EXPAND_THRESHOLD 50
#define VV_SPECIAL_LIST_NO_EXPAND_THRESHOLD 150

//#define IS_VALID_ASSOC_KEY(V) (istext(V) || ispath(V) || isdatum(V) || islist(V))
#define IS_VALID_ASSOC_KEY(V) (!isnum(V)) //hhmmm..

//General helpers
#define VV_HREF_TARGET_INTERNAL(target, href_key) "byond://?_src_=vars;[HrefToken()];[href_key]=TRUE;[VV_HK_TARGET]=[REF(target)]"
#define VV_HREF_TARGETREF_INTERNAL(targetref, href_key) "byond://?_src_=vars;[HrefToken()];[href_key]=TRUE;[VV_HK_TARGET]=[targetref]"
#define VV_HREF_TARGET(target, href_key, text) "<a href='[VV_HREF_TARGET_INTERNAL(target, href_key)]'>[text]</a>"
#define VV_HREF_TARGETREF(targetref, href_key, text) "<a href='[VV_HREF_TARGETREF_INTERNAL(targetref, href_key)]'>[text]</a>"
#define VV_HREF_TARGET_1V(target, href_key, text, varname) "<a href='[VV_HREF_TARGET_INTERNAL(target, href_key)];[VV_HK_VARNAME]=[varname]'>[text]</a>" //for stuff like basic varedits, one variable
#define VV_HREF_TARGETREF_1V(targetref, href_key, text, varname) "<a href='[VV_HREF_TARGETREF_INTERNAL(targetref, href_key)];[VV_HK_VARNAME]=[varname]'>[text]</a>"

#define GET_VV_TARGET locate(href_list[VV_HK_TARGET])
#define GET_VV_VAR_TARGET href_list[VV_HK_VARNAME]

//Helper for getting something to vv_do_topic in general
#define VV_TOPIC_LINK(datum, href_key, text) "<a href='byond://?_src_=vars;[HrefToken()];[href_key]=TRUE;target=[REF(datum)]'>text</a>"

//Helpers for vv_get_dropdown()
#define VV_DROPDOWN_OPTION(href_key, name) . += "<option value='?_src_=vars;[HrefToken()];[href_key]=TRUE;target=[REF(src)]'>[name]</option>"

// VV HREF KEYS
#define VV_HK_TARGET "target"
#define VV_HK_VARNAME "targetvar" //name or index of var for 1 variable targeting hrefs.

// vv_do_list() keys
#define VV_HK_LIST_ADD "listadd"
#define VV_HK_LIST_EDIT "listedit"
#define VV_HK_LIST_CHANGE "listchange"
#define VV_HK_LIST_REMOVE "listremove"
#define VV_HK_LIST_ERASE_NULLS "listnulls"
#define VV_HK_LIST_ERASE_DUPES "listdupes"
#define VV_HK_LIST_SHUFFLE "listshuffle"
#define VV_HK_LIST_SET_LENGTH "listlen"

// vv_do_basic() keys
#define VV_HK_BASIC_EDIT "datumedit"
#define VV_HK_BASIC_CHANGE "datumchange"
#define VV_HK_BASIC_MASSEDIT "massedit"

// /datum
#define VV_HK_DELETE "delete"
#define VV_HK_EXPOSE "expose"
#define VV_HK_CALLPROC "proc_call"
#define VV_HK_MARK "mark"
#define VV_HK_TAG "tag"
#define VV_HK_ADDCOMPONENT "addcomponent"
#define VV_HK_REMOVECOMPONENT "removecomponent"
#define VV_HK_MASS_REMOVECOMPONENT "massremovecomponent"
#define VV_HK_MODIFY_TRAITS "modtraits"

// /atom
#define VV_HK_MODIFY_TRANSFORM "atom_transform"
#define VV_HK_SPIN_ANIMATION "atom_spin"
#define VV_HK_STOP_ALL_ANIMATIONS "stop_animations"
#define VV_HK_MODIFY_GREYSCALE "modify_greyscale"
#define VV_HK_ADD_REAGENT "addreagent"
#define VV_HK_SHOW_HIDDENPRINTS "show_hiddenprints"
#define VV_HK_TRIGGER_EMP "empulse"
#define VV_HK_TRIGGER_EXPLOSION "explode"
#define VV_HK_AUTO_RENAME "auto_rename"
#define VV_HK_EDIT_FILTERS "edit_filters"
#define VV_HK_EDIT_PARTICLES "edit_particles"
#define VV_HK_EDIT_COLOR_MATRIX "edit_color_matrix"
#define VV_HK_TEST_MATRIXES "test_matrixes"
#define VV_HK_ADD_AI "add_ai"
#define VV_HK_ARMOR_MOD "mod_obj_armor"

// /atom/movable
#define VV_HK_OBSERVE_FOLLOW "observe_follow"
#define VV_HK_GET_MOVABLE "get_movable"
#define VV_HK_DEADCHAT_PLAYS "deadchat_plays"

// /obj
#define VV_HK_OSAY "osay"
#define VV_HK_MASS_DEL_TYPE "mass_delete_type"

// /obj/item
#define VV_HK_ADD_FANTASY_AFFIX "add_fantasy_affix"

// /obj/narsie
#define VV_HK_BEGIN_NARSIE_ROUNDEND "begin_narsie_roundend"

// /mob
#define VV_HK_GIB "gib"
#define VV_HK_GIVE_MOB_ACTION "give_mob_action"
#define VV_HK_REMOVE_MOB_ACTION "remove_mob_action"
#define VV_HK_GIVE_SPELL "give_spell"
#define VV_HK_REMOVE_SPELL "remove_spell"
#define VV_HK_GIVE_DISEASE "give_disease"
#define VV_HK_GODMODE "godmode"
#define VV_HK_DROP_ALL "dropall"
#define VV_HK_REGEN_ICONS "regen_icons"
#define VV_HK_REGEN_ICONS_FULL "regen_icons_full"
#define VV_HK_PLAYER_PANEL "player_panel"
#define VV_HK_BUILDMODE "buildmode"
#define VV_HK_DIRECT_CONTROL "direct_control"
#define VV_HK_GIVE_DIRECT_CONTROL "give_direct_control"
#define VV_HK_OFFER_GHOSTS "offer_ghosts"
#define VV_HK_VIEW_PLANES "view_planes"
#define VV_HK_GIVE_AI "give_ai"

// /mob/living
#define VV_HK_GIVE_SPEECH_IMPEDIMENT "impede_speech"
#define VV_HK_ADMIN_RENAME "admin_rename"
#define VV_HK_ADD_MOOD "addmood"
#define VV_HK_REMOVE_MOOD "removemood"
#define VV_HK_GIVE_HALLUCINATION "give_hallucination"
#define VV_HK_GIVE_DELUSION_HALLUCINATION "give_hallucination_delusion"
#define VV_HK_GIVE_GUARDIAN_SPIRIT "give_guardian_spirit"

// /mob/living/carbon
#define VV_HK_MODIFY_BODYPART "mod_bodypart"
#define VV_HK_MODIFY_ORGANS "organs_modify"
#define VV_HK_MARTIAL_ART "give_martial_art"
#define VV_HK_GIVE_TRAUMA "give_trauma"
#define VV_HK_CURE_TRAUMA "cure_trauma"

// /mob/living/carbon/human
#define VV_HK_COPY_OUTFIT "copy_outfit"
#define VV_HK_MOD_MUTATIONS "quirkmut"
#define VV_HK_MOD_QUIRKS "quirkmod"
#define VV_HK_SET_SPECIES "setspecies"
#define VV_HK_PURRBATION "purrbation"
#define VV_HK_APPLY_DNA_INFUSION "apply_dna_infusion"
#define VV_HK_TURN_INTO_MMI "turn_into_mmi"

// misc
#define VV_HK_SPACEVINE_PURGE "spacevine_purge"

// paintings
#define VV_HK_REMOVE_PAINTING "remove_painting"

//outfits
#define VV_HK_TO_OUTFIT_EDITOR "outfit_editor"

#define VV_HK_WEAKREF_RESOLVE "weakref_resolve"

// Flags for debug_variable() that do little things to what we end up rendering

/// ALWAYS render a reduced list, useful for fuckoff big datums that need to be condensed for the sake of client load
#define VV_ALWAYS_CONTRACT_LIST (1<<0)
