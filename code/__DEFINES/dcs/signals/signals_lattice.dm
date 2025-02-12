//From base of /obj/structure/lattice/proc/replace_with_catwalk() : (list/post_replacement_callbacks)
/// `post_replacement_callbacks` is a list that signal handlers can mutate to append `/datum/callback` objects.
/// They will be called with the new catwalk after it has been initialized.
#define COMSIG_LATTICE_PRE_REPLACE_WITH_CATWALK "lattice_pre_replace_with_catwalk"
