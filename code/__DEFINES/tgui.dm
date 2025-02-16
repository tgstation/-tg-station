/// Green eye; fully interactive
#define UI_INTERACTIVE 2
/// Orange eye; updates but is not interactive
#define UI_UPDATE 1
/// Red eye; disabled, does not update
#define UI_DISABLED 0
/// UI Should close
#define UI_CLOSE -1

/// Maximum number of windows that can be suspended/reused
#define TGUI_WINDOW_SOFT_LIMIT 5
/// Maximum number of open windows
#define TGUI_WINDOW_HARD_LIMIT 9

/// Maximum ping timeout allowed to detect zombie windows
#define TGUI_PING_TIMEOUT (4 SECONDS)
/// Used for rate-limiting to prevent DoS by excessively refreshing a TGUI window
#define TGUI_REFRESH_FULL_UPDATE_COOLDOWN (1 SECONDS)

/// Window does not exist
#define TGUI_WINDOW_CLOSED 0
/// Window was just opened, but is still not ready to be sent data
#define TGUI_WINDOW_LOADING 1
/// Window is free and ready to receive data
#define TGUI_WINDOW_READY 2

/// Get a window id based on the provided pool index
#define TGUI_WINDOW_ID(index) "tgui-window-[index]"
/// Get a pool index of the provided window id
#define TGUI_WINDOW_INDEX(window_id) text2num(copytext(window_id, 13))

/// Creates a message packet for sending via output()
// This is {"type":type,"payload":payload}, but pre-encoded. This is much faster
// than doing it the normal way.
// To ensure this is correct, this is unit tested in tgui_create_message.
#define TGUI_CREATE_MESSAGE(type, payload) ( \
	"%7b%22type%22%3a%22[type]%22%2c%22payload%22%3a[url_encode(json_encode(payload))]%7d" \
)

/**
 * Gets a ui_state that checks to see if the user has specific admin permissions.
 *
 * Arguments:
 * * required_perms: Which admin permission flags to check the user for, such as [R_ADMIN]
 */
#define ADMIN_STATE(required_perms) (GLOB.admin_states["[required_perms]"] ||= new /datum/ui_state/admin_state(required_perms))
