// Various modular computer signals.

/// From /obj/item/modular_computer/proc/turn_on: (user)
#define COMSIG_MODULAR_COMPUTER_TURNED_ON "comsig_modular_computer_turned_on"
/// From /obj/item/modular_computer/proc/shutdown_computer: (loud)
#define COMSIG_MODULAR_COMPUTER_SHUT_DOWN "comsig_modular_computer_shut_down"

/// From /obj/item/modular_computer/proc/store_file: (datum/computer_file/file_storing)
#define COMSIG_MODULAR_COMPUTER_FILE_STORE "comsig_modular_computer_file_store"
/// From /obj/item/modular_computer/proc/remove_file: (datum/computer_file/file_removing)
#define COMSIG_MODULAR_COMPUTER_FILE_DELETE "comsig_modular_computer_file_delete"
/// From /obj/item/modular_computer/proc/store_file: (datum/computer_file/file_source, obj/item/modular_computer/host)
#define COMSIG_COMPUTER_FILE_STORE "comsig_computer_file_store"
/// From /obj/item/modular_computer/proc/store_file: ()
#define COMSIG_COMPUTER_FILE_DELETE "comsig_computer_file_delete"

/// From /obj/item/modular_computer/proc/InsertID: (inserting_id, user)
#define COMSIG_MODULAR_COMPUTER_INSERTED_ID "comsig_computer_inserted_id"

/// From /datum/computer_file/program/on_start: (user)
#define COMSIG_COMPUTER_PROGRAM_START "computer_program_start"

/// From /datum/computer_file/program/kill_program: (user)
#define COMSIG_COMPUTER_PROGRAM_KILL "computer_program_kill"

/// From /datum/computer_file/program/nt_pay/make_payment: (payment_result)
#define COMSIG_MODULAR_COMPUTER_NT_PAY_RESULT "comsig_modular_computer_nt_pay_result"

/// From /datum/computer_file/program/nt_pay/make_payment: (spookiness, manual)
#define COMSIG_MODULAR_COMPUTER_SPECTRE_SCAN "comsig_modular_computer_spectre_scan"

/// From /datum/computer_file/program/radar/trackable: (atom/signal, turf/signal_turf, turf/computer_turf)
#define COMSIG_MODULAR_COMPUTER_RADAR_TRACKABLE "comsig_modular_computer_radar_trackable"
	#define COMPONENT_RADAR_TRACK_ANYWAY (1<<0)
	#define COMPONENT_RADAR_DONT_TRACK (1<<1)
/// From /datum/computer_file/program/radar/find_atom: (list/atom_container)
#define COMSIG_MODULAR_COMPUTER_RADAR_FIND_ATOM "comsig_modular_computer_radar_find_atom"
/// From /datum/computer_file/program/radar/ui_act, when action is "selecttarget": (selected_ref)
#define COMSIG_MODULAR_COMPUTER_RADAR_SELECTED "comsig_modular_computer_radar_selected"

/// from /obj/item/modular_computer/imprint_id(): (name, job, id_card)
#define COMSIG_MODULAR_PDA_IMPRINT_UPDATED "comsig_modular_pda_imprint_updated"
/// from /obj/item/modular_computer/reset_id(): ()
#define COMSIG_MODULAR_PDA_IMPRINT_RESET "comsig_modular_pda_imprint_reset"

/// From /datum/computer_file/program/messenger/receive_message, sent to the computer: (signal/subspace/messaging/tablet_message/signal, sender_job, sender_name)
#define COMSIG_MODULAR_PDA_MESSAGE_RECEIVED "comsig_modular_pda_message_received"
/// From /datum/computer_file/program/messenger/send_message_signal, sent to the computer: (atom/origin, datum/signal/subspace/messaging/tablet_message/signal)
#define COMSIG_MODULAR_PDA_MESSAGE_SENT "comsig_modular_pda_message_sent"
