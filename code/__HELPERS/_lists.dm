/*
 * Holds procs to help with list operations
 * Contains groups:
 * Misc
 * Sorting
 */

/*
 * Misc
 */

// Generic listoflist safe add and removal macros:
///If value is a list, wrap it in a list so it can be used with list add/remove operations
#define LIST_VALUE_WRAP_LISTS(value) (islist(value) ? list(value) : value)
///Add an untyped item to a list, taking care to handle list items by wrapping them in a list to remove the footgun
#define UNTYPED_LIST_ADD(list, item) (list += LIST_VALUE_WRAP_LISTS(item))
///Remove an untyped item to a list, taking care to handle list items by wrapping them in a list to remove the footgun
#define UNTYPED_LIST_REMOVE(list, item) (list -= LIST_VALUE_WRAP_LISTS(item))

/*
 * ## Lazylists
 *
 * * What is a lazylist?
 *
 * True to its name a lazylist is a lazy instantiated list.
 * It is a list that is only created when necessary (when it has elements) and is null when empty.
 *
 * * Why use a lazylist?
 *
 * Lazylists save memory - an empty list that is never used takes up more memory than just `null`.
 *
 * * When to use a lazylist?
 *
 * Lazylists are best used on hot types when making lists that are not always used.
 *
 * For example, if you were adding a list to all atoms that tracks the names of people who touched it,
 * you would want to use a lazylist because most atoms will never be touched by anyone.
 *
 * * How do I use a lazylist?
 *
 * A lazylist is just a list you defined as `null` rather than `list()`.
 * Then, you use the LAZY* macros to interact with it, which are essentially null-safe ways to interact with a list.
 *
 * Note that you probably should not be using these macros if your list is not a lazylist.
 * This will obfuscate the code and make it a bit harder to read and debug.
 *
 * Generally speaking you shouldn't be checking if your lazylist is `null` yourself, the macros will do that for you.
 * Remember that LAZYLEN (and by extension, length) will return 0 if the list is null.
 */

///Initialize the lazylist
#define LAZYINITLIST(L) if (!L) { L = list(); }
///If the provided list is empty, set it to null
#define UNSETEMPTY(L) if (L && !length(L)) L = null
///If the provided key -> list is empty, remove it from the list
#define ASSOC_UNSETEMPTY(L, K) if (!length(L[K])) L -= K;
///Like LAZYCOPY - copies an input list if the list has entries, If it doesn't the assigned list is nulled
#define LAZYLISTDUPLICATE(L) (L ? L.Copy() : null )
///Remove an item from the list, set the list to null if empty
#define LAZYREMOVE(L, I) if(L) { L -= I; if(!length(L)) { L = null; } }
///Add an item to the list, if the list is null it will initialize it
#define LAZYADD(L, I) if(!L) { L = list(); } L += I;
///Add an item to the list if not already present, if the list is null it will initialize it
#define LAZYOR(L, I) if(!L) { L = list(); } L |= I;
///Returns the key of the submitted item in the list
#define LAZYFIND(L, V) (L ? L.Find(V) : 0)
///returns L[I] if L exists and I is a valid index of L, runtimes if L is not a list
#define LAZYACCESS(L, I) (L ? (isnum(I) ? (I > 0 && I <= length(L) ? L[I] : null) : L[I]) : null)
///Sets the item K to the value V, if the list is null it will initialize it
#define LAZYSET(L, K, V) if(!L) { L = list(); } L[K] = V;
///Sets the length of a lazylist
#define LAZYSETLEN(L, V) if (!L) { L = list(); } L.len = V;
///Returns the length of the list
#define LAZYLEN(L) length(L)
///Sets a list to null
#define LAZYNULL(L) L = null
///Adds to the item K the value V, if the list is null it will initialize it
#define LAZYADDASSOC(L, K, V) if(!L) { L = list(); } L[K] += V;
///This is used to add onto lazy assoc list when the value you're adding is a /list/. This one has extra safety over lazyaddassoc because the value could be null (and thus cant be used to += objects)
#define LAZYADDASSOCLIST(L, K, V) if(!L) { L = list(); } L[K] += list(V);
///Removes the value V from the item K, if the item K is empty will remove it from the list, if the list is empty will set the list to null
#define LAZYREMOVEASSOC(L, K, V) if(L) { if(L[K]) { L[K] -= V; if(!length(L[K])) L -= K; } if(!length(L)) L = null; }
///Accesses an associative list, returns null if nothing is found
#define LAZYACCESSASSOC(L, I, K) L ? L[I] ? L[I][K] ? L[I][K] : null : null : null
///Qdel every item in the list before setting the list to null
#define QDEL_LAZYLIST(L) for(var/I in L) qdel(I); L = null;
//These methods don't null the list
///Use LAZYLISTDUPLICATE instead if you want it to null with no entries
#define LAZYCOPY(L) (L ? L.Copy() : list() )
/// Consider LAZYNULL instead
#define LAZYCLEARLIST(L) if(L) L.Cut()
///Returns the list if it's actually a valid list, otherwise will initialize it
#define SANITIZE_LIST(L) ( islist(L) ? L : list() )
/// Performs an insertion on the given lazy list with the given key and value. If the value already exists, a new one will not be made.
#define LAZYORASSOCLIST(lazy_list, key, value) \
	LAZYINITLIST(lazy_list); \
	LAZYINITLIST(lazy_list[key]); \
	lazy_list[key] |= value;

///Ensures the length of a list is at least I, prefilling it with V if needed. if V is a proc call, it is repeated for each new index so that list() can just make a new list for each item.
#define LISTASSERTLEN(L, I, V...) \
	if (length(L) < I) { \
		var/_OLD_LENGTH = length(L); \
		L.len = I; \
		/* Convert the optional argument to a if check */ \
		for (var/_USELESS_VAR in list(V)) { \
			for (var/_INDEX_TO_ASSIGN_TO in _OLD_LENGTH+1 to I) { \
				L[_INDEX_TO_ASSIGN_TO] = V; \
			} \
		} \
	}

#define reverseList(L) reverse_range(L.Copy())

/// Passed into BINARY_INSERT to compare keys
#define COMPARE_KEY __BIN_LIST[__BIN_MID]
/// Passed into BINARY_INSERT to compare values
#define COMPARE_VALUE __BIN_LIST[__BIN_LIST[__BIN_MID]]

/****
	* Binary search sorted insert
	* INPUT: Object to be inserted
	* LIST: List to insert object into
	* TYPECONT: The typepath of the contents of the list
	* COMPARE: The object to compare against, usualy the same as INPUT
	* COMPARISON: The variable on the objects to compare
	* COMPTYPE: How should the values be compared? Either COMPARE_KEY or COMPARE_VALUE.
	*/
#define BINARY_INSERT(INPUT, LIST, TYPECONT, COMPARE, COMPARISON, COMPTYPE) \
	do {\
		var/list/__BIN_LIST = LIST;\
		var/__BIN_CTTL = length(__BIN_LIST);\
		if(!__BIN_CTTL) {\
			__BIN_LIST += INPUT;\
		} else {\
			var/__BIN_LEFT = 1;\
			var/__BIN_RIGHT = __BIN_CTTL;\
			var/__BIN_MID = (__BIN_LEFT + __BIN_RIGHT) >> 1;\
			var ##TYPECONT/__BIN_ITEM;\
			while(__BIN_LEFT < __BIN_RIGHT) {\
				__BIN_ITEM = COMPTYPE;\
				if(__BIN_ITEM.##COMPARISON <= COMPARE.##COMPARISON) {\
					__BIN_LEFT = __BIN_MID + 1;\
				} else {\
					__BIN_RIGHT = __BIN_MID;\
				};\
				__BIN_MID = (__BIN_LEFT + __BIN_RIGHT) >> 1;\
			};\
			__BIN_ITEM = COMPTYPE;\
			__BIN_MID = __BIN_ITEM.##COMPARISON > COMPARE.##COMPARISON ? __BIN_MID : __BIN_MID + 1;\
			__BIN_LIST.Insert(__BIN_MID, INPUT);\
		};\
	} while(FALSE)

/**
 * Custom binary search sorted insert utilising comparison procs instead of vars.
 * INPUT: Object to be inserted
 * LIST: List to insert object into
 * TYPECONT: The typepath of the contents of the list
 * COMPARE: The object to compare against, usualy the same as INPUT
 * COMPARISON: The plaintext name of a proc on INPUT that takes a single argument to accept a single element from LIST and returns a positive, negative or zero number to perform a comparison.
 * COMPTYPE: How should the values be compared? Either COMPARE_KEY or COMPARE_VALUE.
 */
#define BINARY_INSERT_PROC_COMPARE(INPUT, LIST, TYPECONT, COMPARE, COMPARISON, COMPTYPE) \
	do {\
		var/list/__BIN_LIST = LIST;\
		var/__BIN_CTTL = length(__BIN_LIST);\
		if(!__BIN_CTTL) {\
			__BIN_LIST += INPUT;\
		} else {\
			var/__BIN_LEFT = 1;\
			var/__BIN_RIGHT = __BIN_CTTL;\
			var/__BIN_MID = (__BIN_LEFT + __BIN_RIGHT) >> 1;\
			var ##TYPECONT/__BIN_ITEM;\
			while(__BIN_LEFT < __BIN_RIGHT) {\
				__BIN_ITEM = COMPTYPE;\
				if(__BIN_ITEM.##COMPARISON(COMPARE) <= 0) {\
					__BIN_LEFT = __BIN_MID + 1;\
				} else {\
					__BIN_RIGHT = __BIN_MID;\
				};\
				__BIN_MID = (__BIN_LEFT + __BIN_RIGHT) >> 1;\
			};\
			__BIN_ITEM = COMPTYPE;\
			__BIN_MID = __BIN_ITEM.##COMPARISON(COMPARE) > 0 ? __BIN_MID : __BIN_MID + 1;\
			__BIN_LIST.Insert(__BIN_MID, INPUT);\
		};\
	} while(FALSE)

#define SORT_FIRST_INDEX(list) (list[1])
#define SORT_COMPARE_DIRECTLY(thing) (thing)
#define SORT_VAR_NO_TYPE(varname) var/varname
/****
	* Even more custom binary search sorted insert, using defines instead of vars
	* INPUT: Item to be inserted
	* LIST: List to insert INPUT into
	* TYPECONT: A define setting the var to the typepath of the contents of the list
	* COMPARE: The item to compare against, usualy the same as INPUT
	* COMPARISON: A define that takes an item to compare as input, and returns their comparable value
	* COMPTYPE: How should the list be compared? Either COMPARE_KEY or COMPARE_VALUE.
	*/
#define BINARY_INSERT_DEFINE(INPUT, LIST, TYPECONT, COMPARE, COMPARISON, COMPTYPE) \
	do {\
		var/list/__BIN_LIST = LIST;\
		var/__BIN_CTTL = length(__BIN_LIST);\
		if(!__BIN_CTTL) {\
			__BIN_LIST += INPUT;\
		} else {\
			var/__BIN_LEFT = 1;\
			var/__BIN_RIGHT = __BIN_CTTL;\
			var/__BIN_MID = (__BIN_LEFT + __BIN_RIGHT) >> 1;\
			##TYPECONT(__BIN_ITEM);\
			while(__BIN_LEFT < __BIN_RIGHT) {\
				__BIN_ITEM = COMPTYPE;\
				if(##COMPARISON(__BIN_ITEM) <= ##COMPARISON(COMPARE)) {\
					__BIN_LEFT = __BIN_MID + 1;\
				} else {\
					__BIN_RIGHT = __BIN_MID;\
				};\
				__BIN_MID = (__BIN_LEFT + __BIN_RIGHT) >> 1;\
			};\
			__BIN_ITEM = COMPTYPE;\
			__BIN_MID = ##COMPARISON(__BIN_ITEM) > ##COMPARISON(COMPARE) ? __BIN_MID : __BIN_MID + 1;\
			__BIN_LIST.Insert(__BIN_MID, INPUT);\
		};\
	} while(FALSE)

///Returns a list in plain english as a string
/proc/english_list(list/input, nothing_text = "nothing", and_text = " and ", comma_text = ", ", final_comma_text = "" )
	var/total = length(input)
	switch(total)
		if (0)
			return "[nothing_text]"
		if (1)
			return "[input[1]]"
		if (2)
			return "[input[1]][and_text][input[2]]"
		else
			var/output = ""
			var/index = 1
			while (index < total)
				if (index == total - 1)
					comma_text = final_comma_text

				output += "[input[index]][comma_text]"
				index++

			return "[output][and_text][input[index]]"

///Returns a list of atom types in plain english as a string of each type name
/proc/type_english_list(list/input, nothing_text = "nothing", and_text = " and ", comma_text = ", ", final_comma_text = "" )
	var/list/english_input = list()
	for(var/atom/type as anything in input)
		english_input += "[initial(type.name)]"
	return english_list(english_input, nothing_text, and_text, comma_text, final_comma_text)

/**
 * Checks for specific types in a list.
 *
 * If using zebra mode the list should be an assoc list with truthy/falsey values.
 * The check short circuits so earlier entries in the input list will take priority.
 * Ergo, subtypes should come before parent types.
 * Notice that this is the opposite priority of [/proc/typecacheof].
 *
 * Arguments:
 * - [type_to_check][/datum]: An instance to check.
 * - [list_to_check][/list]: A list of typepaths to check the type_to_check against.
 * - zebra: Whether to use the value of the matching type in the list instead of just returning true when a match is found.
 */
/proc/is_type_in_list(datum/type_to_check, list/list_to_check, zebra = FALSE)
	if(!LAZYLEN(list_to_check) || !type_to_check)
		return FALSE
	for(var/type in list_to_check)
		if(istype(type_to_check, type))
			return !zebra || list_to_check[type] // Subtypes must come first in zebra lists.
	return FALSE

/**
 * Checks for specific paths in a list.
 *
 * If using zebra mode the list should be an assoc list with truthy/falsey values.
 * The check short circuits so earlier entries in the input list will take priority.
 * Ergo, subpaths should come before parent paths.
 * Notice that this is the opposite priority of [/proc/typecacheof].
 *
 * Arguments:
 * - path_to_check: A typepath to check.
 * - [list_to_check][/list]: A list of typepaths to check the path_to_check against.
 * - zebra: Whether to use the value of the mathing path in the list instead of just returning true when a match is found.
 */
/proc/is_path_in_list(path_to_check, list/list_to_check, zebra = FALSE)
	if(!LAZYLEN(list_to_check) || !path_to_check)
		return FALSE
	for(var/path in list_to_check)
		if(ispath(path_to_check, path))
			return !zebra || list_to_check[path]
	return FALSE

///Checks for specific types in specifically structured (Assoc "type" = TRUE|FALSE) lists ('typecaches')
#define is_type_in_typecache(A, L) (A && length(L) && L[(ispath(A) ? A : A:type)])

///returns a new list with only atoms that are in the typecache list
/proc/typecache_filter_list(list/atoms, list/typecache)
	RETURN_TYPE(/list)
	. = list()
	for(var/atom/atom_checked as anything in atoms)
		if (typecache[atom_checked.type])
			. += atom_checked

///return a new list with atoms that are not in the typecache list
/proc/typecache_filter_list_reverse(list/atoms, list/typecache)
	RETURN_TYPE(/list)
	. = list()
	for(var/atom/atom_checked as anything in atoms)
		if(!typecache[atom_checked.type])
			. += atom_checked

///similar to typecache_filter_list and typecache_filter_list_reverse but it supports an inclusion list and and exclusion list
/proc/typecache_filter_multi_list_exclusion(list/atoms, list/typecache_include, list/typecache_exclude)
	. = list()
	for(var/atom/atom_checked as anything in atoms)
		if(typecache_include[atom_checked.type] && !typecache_exclude[atom_checked.type])
			. += atom_checked

/**
 * Like typesof() or subtypesof(), but returns a typecache instead of a list.
 *
 * Arguments:
 * - path: A typepath or list of typepaths.
 * - only_root_path: Whether the typecache should be specifically of the passed types.
 * - ignore_root_path: Whether to ignore the root path when caching subtypes.
 */
/proc/typecacheof(path, only_root_path = FALSE, ignore_root_path = FALSE)
	if(isnull(path))
		return

	if(ispath(path))
		. = list()
		if(only_root_path)
			.[path] = TRUE
			return

		for(var/subtype in (ignore_root_path ? subtypesof(path) : typesof(path)))
			.[subtype] = TRUE
		return

	if(!islist(path))
		CRASH("Tried to create a typecache of [path] which is neither a typepath nor a list.")

	. = list()
	var/list/pathlist = path
	if(only_root_path)
		for(var/current_path in pathlist)
			.[current_path] = TRUE
	else if(ignore_root_path)
		for(var/current_path in pathlist)
			for(var/subtype in subtypesof(current_path))
				.[subtype] = TRUE
	else
		for(var/current_path in pathlist)
			for(var/subpath in typesof(current_path))
				.[subpath] = TRUE

/**
 * Like typesof() or subtypesof(), but returns a typecache instead of a list.
 * This time it also uses the associated values given by the input list for the values of the subtypes.
 *
 * Latter values from the input list override earlier values.
 * Thus subtypes should come _after_ parent types in the input list.
 * Notice that this is the opposite priority of [/proc/is_type_in_list] and [/proc/is_path_in_list].
 *
 * Arguments:
 * - path: A typepath or list of typepaths with associated values.
 * - single_value: The assoc value used if only a single path is passed as the first variable.
 * - only_root_path: Whether the typecache should be specifically of the passed types.
 * - ignore_root_path: Whether to ignore the root path when caching subtypes.
 * - clear_nulls: Whether to remove keys with null assoc values from the typecache after generating it.
 */
/proc/zebra_typecacheof(path, single_value = TRUE, only_root_path = FALSE, ignore_root_path = FALSE, clear_nulls = FALSE)
	if(isnull(path))
		return

	if(ispath(path))
		if (isnull(single_value))
			return

		. = list()
		if(only_root_path)
			.[path] = single_value
			return

		for(var/subtype in (ignore_root_path ? subtypesof(path) : typesof(path)))
			.[subtype] = single_value
		return

	if(!islist(path))
		CRASH("Tried to create a typecache of [path] which is neither a typepath nor a list.")

	. = list()
	var/list/pathlist = path
	if(only_root_path)
		for(var/current_path in pathlist)
			.[current_path] = pathlist[current_path]
	else if(ignore_root_path)
		for(var/current_path in pathlist)
			for(var/subtype in subtypesof(current_path))
				.[subtype] = pathlist[current_path]
	else
		for(var/current_path in pathlist)
			for(var/subpath in typesof(current_path))
				.[subpath] = pathlist[current_path]

	if(!clear_nulls)
		return

	for(var/cached_path in .)
		if (isnull(.[cached_path]))
			. -= cached_path


/**
 * Removes any null entries from the list
 * Returns TRUE if the list had nulls, FALSE otherwise
**/
/proc/list_clear_nulls(list/list_to_clear)
	return (list_to_clear.RemoveAll(null) > 0)


/**
 * Removes any empty weakrefs from the list
 * Returns TRUE if the list had empty refs, FALSE otherwise
**/
/proc/list_clear_empty_weakrefs(list/list_to_clear)
	var/start_len = list_to_clear.len
	for(var/datum/weakref/entry in list_to_clear)
		if(!entry.resolve())
			list_to_clear -= entry
	return list_to_clear.len < start_len

/*
 * Returns list containing all the entries from first list that are not present in second.
 * If skiprep = 1, repeated elements are treated as one.
 * If either of arguments is not a list, returns null
 */
/proc/difflist(list/first, list/second, skiprep=0)
	if(!islist(first) || !islist(second))
		return
	var/list/result = new
	if(skiprep)
		for(var/entry in first)
			if(!(entry in result) && !(entry in second))
				UNTYPED_LIST_ADD(result, entry)
	else
		result = first - second
	return result

/*
 * Returns list containing entries that are in either list but not both.
 * If skipref = 1, repeated elements are treated as one.
 * If either of arguments is not a list, returns null
 */
/proc/unique_merge_list(list/first, list/second, skiprep=0)
	if(!islist(first) || !islist(second))
		return
	var/list/result = new
	if(skiprep)
		result = difflist(first, second, skiprep)+difflist(second, first, skiprep)
	else
		result = first ^ second
	return result

/**
 * Picks a random element from a list based on a weighting system.
 * For example, given the following list:
 * A = 6, B = 3, C = 1, D = 0
 * A would have a 60% chance of being picked,
 * B would have a 30% chance of being picked,
 * C would have a 10% chance of being picked,
 * and D would have a 0% chance of being picked.
 * You should only pass integers in.
 */
/proc/pick_weight(list/list_to_pick)
	if(length(list_to_pick) == 0)
		return null

	var/total = 0
	for(var/item in list_to_pick)
		if(!list_to_pick[item])
			list_to_pick[item] = 0
		total += list_to_pick[item]

	total = rand(1, total)
	for(var/item in list_to_pick)
		var/item_weight = list_to_pick[item]
		if(item_weight == 0)
			continue

		total -= item_weight
		if(total <= 0)
			return item

	return null

/**
 * Like pick_weight, but allowing for nested lists.
 *
 * For example, given the following list:
 * list(A = 1, list(B = 1, C = 1))
 * A would have a 50% chance of being picked,
 * and list(B, C) would have a 50% chance of being picked.
 * If list(B, C) was picked, B and C would then each have a 50% chance of being picked.
 * So the final probabilities would be 50% for A, 25% for B, and 25% for C.
 *
 * Weights should be integers. Entries without weights are assigned weight 1 (so unweighted lists can be used as well)
 */
/proc/pick_weight_recursive(list/list_to_pick)
	var/result = pick_weight(fill_with_ones(list_to_pick))
	while(islist(result))
		result = pick_weight(fill_with_ones(result))
	return result

/**
 * Given a list, return a copy where values without defined weights are given weight 1.
 * For example, fill_with_ones(list(A, B=2, C)) = list(A=1, B=2, C=1)
 * Useful for weighted random choices (loot tables, syllables in languages, etc.)
 */
/proc/fill_with_ones(list/list_to_pad)
	if (!islist(list_to_pad))
		return list_to_pad

	var/list/final_list = list()

	for (var/key in list_to_pad)
		if (list_to_pad[key])
			final_list[key] = list_to_pad[key]
		else
			final_list[key] = 1

	return final_list

/// Takes a weighted list (see above) and expands it into raw entries
/// This eats more memory, but saves time when actually picking from it
/proc/expand_weights(list/list_to_pick)
	var/list/values = list()
	for(var/item in list_to_pick)
		var/value = list_to_pick[item]
		if(!value)
			continue
		values += value

	var/gcf = greatest_common_factor(values)

	var/list/output = list()
	for(var/item in list_to_pick)
		var/value = list_to_pick[item]
		if(!value)
			continue
		for(var/i in 1 to value / gcf)
			UNTYPED_LIST_ADD(output, item)
	return output

/// Takes a list of numbers as input, returns the highest value that is cleanly divides them all
/// Note: this implementation is expensive as heck for large numbers, I only use it because most of my usecase
/// Is < 10 ints
/proc/greatest_common_factor(list/values)
	var/smallest = min(arglist(values))
	for(var/i in smallest to 1 step -1)
		var/safe = TRUE
		for(var/entry in values)
			if(entry % i != 0)
				safe = FALSE
				break
		if(safe)
			return i

/// Pick a random element from the list and remove it from the list.
/proc/pick_n_take(list/list_to_pick)
	RETURN_TYPE(list_to_pick[_].type)
	if(list_to_pick.len)
		var/picked = rand(1,list_to_pick.len)
		. = list_to_pick[picked]
		list_to_pick.Cut(picked,picked+1) //Cut is far more efficient that Remove()

///Returns the top(last) element from the list and removes it from the list (typical stack function)
/proc/pop(list/L)
	if(L.len)
		. = L[L.len]
		L.len--

/// Returns the top (last) element from the list, does not remove it from the list. Stack functionality.
/proc/peek(list/target_list)
	var/list_length = length(target_list)
	if(list_length != 0)
		return target_list[list_length]

/proc/popleft(list/L)
	if(L.len)
		. = L[1]
		L.Cut(1,2)

/proc/sorted_insert(list/L, thing, comparator)
	var/pos = L.len
	while(pos > 0 && call(comparator)(thing, L[pos]) > 0)
		pos--
	L.Insert(pos+1, thing)

/// Returns the next item in a list
/proc/next_list_item(item, list/inserted_list)
	var/i
	i = inserted_list.Find(item)
	if(i == inserted_list.len)
		i = 1
	else
		i++
	return inserted_list[i]

/// Returns the previous item in a list
/proc/previous_list_item(item, list/inserted_list)
	var/i
	i = inserted_list.Find(item)
	if(i == 1)
		i = inserted_list.len
	else
		i--
	return inserted_list[i]

///Randomize: Return the list in a random order
/proc/shuffle(list/inserted_list)
	if(!inserted_list)
		return
	inserted_list = inserted_list.Copy()

	for(var/i in 1 to inserted_list.len - 1)
		inserted_list.Swap(i, rand(i, inserted_list.len))

	return inserted_list

///same as shuffle, but returns nothing and acts on list in place
/proc/shuffle_inplace(list/inserted_list)
	if(!inserted_list)
		return

	for(var/i in 1 to inserted_list.len - 1)
		inserted_list.Swap(i, rand(i, inserted_list.len))

///Return a list with no duplicate entries
/proc/unique_list(list/inserted_list)
	. = list()
	for(var/i in inserted_list)
		. |= LIST_VALUE_WRAP_LISTS(i)

///same as unique_list, but returns nothing and acts on list in place (also handles associated values properly)
/proc/unique_list_in_place(list/inserted_list)
	var/temp = inserted_list.Copy()
	inserted_list.len = 0
	for(var/key in temp)
		if (isnum(key))
			inserted_list |= key
		else
			inserted_list[key] = temp[key]

///for sorting clients or mobs by ckey
/proc/sort_key(list/ckey_list, order = 1)
	return sortTim(ckey_list, order >= 0 ? GLOBAL_PROC_REF(cmp_ckey_asc) : GLOBAL_PROC_REF(cmp_ckey_dsc))

///Specifically for record datums in a list.
/proc/sort_record(list/record_list, order = 1)
	return sortTim(record_list, order >= 0 ? GLOBAL_PROC_REF(cmp_records_asc) : GLOBAL_PROC_REF(cmp_records_dsc))

///sort any value in a list
/proc/sort_list(list/list_to_sort, cmp=/proc/cmp_text_asc)
	return sortTim(list_to_sort.Copy(), cmp)

///uses sort_list() but uses the var's name specifically. This should probably be using mergeAtom() instead
/proc/sort_names(list/list_to_sort, order=1)
	return sortTim(list_to_sort.Copy(), order >= 0 ? GLOBAL_PROC_REF(cmp_name_asc) : GLOBAL_PROC_REF(cmp_name_dsc))

///Converts a bitfield to a list of numbers (or words if a wordlist is provided)
/proc/bitfield_to_list(bitfield = 0, list/wordlist)
	var/list/return_list = list()
	if(islist(wordlist))
		var/max = min(wordlist.len, 24)
		var/bit = 1
		for(var/i in 1 to max)
			if(bitfield & bit)
				return_list += wordlist[i]
			bit = bit << 1
	else
		for(var/bit_number = 0 to 23)
			var/bit = 1 << bit_number
			if(bitfield & bit)
				return_list += bit

	return return_list

/// Returns the key based on the index
#define KEYBYINDEX(L, index) (((index <= length(L)) && (index > 0)) ? L[index] : null)

///return the amount of items of the same type inside a list
/proc/count_by_type(list/inserted_list, type)
	var/i = 0
	for(var/item_type in inserted_list)
		if(istype(item_type, type))
			i++
	return i

/**
 * Returns the first record in the list that matches the name
 *
 * If locked_only is TRUE, locked records will be checked
 *
 * If locked_only is FALSE, crew records will be checked
 *
 * If no record is found, returns null
 */
/proc/find_record(value, locked_only = FALSE)
	if(locked_only)
		for(var/datum/record/locked/target in GLOB.manifest.locked)
			if(target.name != value)
				continue
			return target
		return null

	for(var/datum/record/crew/target in GLOB.manifest.general)
		if(target.name != value)
			continue
		return target
	return null


/**
 * Move a single element from position from_index within a list, to position to_index
 * All elements in the range [1,to_index) before the move will be before the pivot afterwards
 * All elements in the range [to_index, L.len+1) before the move will be after the pivot afterwards
 * In other words, it's as if the range [from_index,to_index) have been rotated using a <<< operation common to other languages.
 * from_index and to_index must be in the range [1,L.len+1]
 * This will preserve associations ~Carnie
**/
/proc/move_element(list/inserted_list, from_index, to_index)
	if(from_index == to_index || from_index + 1 == to_index) //no need to move
		return
	if(from_index > to_index)
		++from_index //since a null will be inserted before from_index, the index needs to be nudged right by one

	inserted_list.Insert(to_index, null)
	inserted_list.Swap(from_index, to_index)
	inserted_list.Cut(from_index, from_index + 1)


/**
 * Move elements [from_index,from_index+len) to [to_index-len, to_index)
 * Same as moveElement but for ranges of elements
 * This will preserve associations ~Carnie
**/
/proc/move_range(list/inserted_list, from_index, to_index, len = 1)
	var/distance = abs(to_index - from_index)
	if(len >= distance) //there are more elements to be moved than the distance to be moved. Therefore the same result can be achieved (with fewer operations) by moving elements between where we are and where we are going. The result being, our range we are moving is shifted left or right by dist elements
		if(from_index <= to_index)
			return //no need to move
		from_index += len //we want to shift left instead of right

		for(var/i in 1 to distance)
			inserted_list.Insert(from_index, null)
			inserted_list.Swap(from_index, to_index)
			inserted_list.Cut(to_index, to_index + 1)
	else
		if(from_index > to_index)
			from_index += len

		for(var/i in 1 to len)
			inserted_list.Insert(to_index, null)
			inserted_list.Swap(from_index, to_index)
			inserted_list.Cut(from_index, from_index + 1)

///Move elements from [from_index, from_index+len) to [to_index, to_index+len)
///Move any elements being overwritten by the move to the now-empty elements, preserving order
///Note: if the two ranges overlap, only the destination order will be preserved fully, since some elements will be within both ranges ~Carnie
/proc/swap_range(list/inserted_list, from_index, to_index, len=1)
	var/distance = abs(to_index - from_index)
	if(len > distance) //there is an overlap, therefore swapping each element will require more swaps than inserting new elements
		if(from_index < to_index)
			to_index += len
		else
			from_index += len

		for(var/i in 1 to distance)
			inserted_list.Insert(from_index, null)
			inserted_list.Swap(from_index, to_index)
			inserted_list.Cut(to_index, to_index + 1)
	else
		if(to_index > from_index)
			var/temp = to_index
			to_index = from_index
			from_index = temp

		for(var/i in 1 to len)
			inserted_list.Swap(from_index++, to_index++)

///replaces reverseList ~Carnie
/proc/reverse_range(list/inserted_list, start = 1, end = 0)
	if(inserted_list.len)
		start = start % inserted_list.len
		end = end % (inserted_list.len + 1)
		if(start <= 0)
			start += inserted_list.len
		if(end <= 0)
			end += inserted_list.len + 1

		--end
		while(start < end)
			inserted_list.Swap(start++, end--)

	return inserted_list


///return first thing in L which has var/varname == value
///this is typecaste as list/L, but you could actually feed it an atom instead.
///completely safe to use
/proc/get_element_by_var(list/inserted_list, varname, value)
	varname = "[varname]"
	for(var/datum/checked_datum in inserted_list)
		if(!checked_datum.vars.Find(varname))
			continue
		if(checked_datum.vars[varname] == value)
			return checked_datum


///Copies a list, and all lists inside it recusively
///Does not copy any other reference type
/proc/deep_copy_list(list/inserted_list)
	if(!islist(inserted_list))
		return inserted_list
	. = inserted_list.Copy()
	for(var/i in 1 to inserted_list.len)
		var/key = .[i]
		if(isnum(key))
			// numbers cannot ever be associative keys
			continue
		var/value = .[key]
		if(islist(value))
			value = deep_copy_list(value)
			.[key] = value
		if(islist(key))
			key = deep_copy_list(key)
			.[i] = key
			.[key] = value

/// A version of deep_copy_list that actually supports associative list nesting: list(list(list("a" = "b"))) will actually copy correctly.
/proc/deep_copy_list_alt(list/inserted_list)
	if(!islist(inserted_list))
		return inserted_list
	var/copied_list = inserted_list.Copy()
	. = copied_list
	for(var/key_or_value in inserted_list)
		if(isnum(key_or_value) || !inserted_list[key_or_value])
			continue
		var/value = inserted_list[key_or_value]
		var/new_value = value
		if(islist(value))
			new_value = deep_copy_list_alt(value)
		copied_list[key_or_value] = new_value

///takes an input_key, as text, and the list of keys already used, outputting a replacement key in the format of "[input_key] ([number_of_duplicates])" if it finds a duplicate
///use this for lists of things that might have the same name, like mobs or objects, that you plan on giving to a player as input
/proc/avoid_assoc_duplicate_keys(input_key, list/used_key_list)
	if(!input_key || !istype(used_key_list))
		return
	if(used_key_list[input_key])
		used_key_list[input_key]++
		input_key = "[input_key] ([used_key_list[input_key]])"
	else
		used_key_list[input_key] = 1
	return input_key

///Flattens a keyed list into a list of its contents
/proc/flatten_list(list/key_list)
	if(!islist(key_list))
		return null
	. = list()
	for(var/key in key_list)
		. |= LIST_VALUE_WRAP_LISTS(key_list[key])

///Make a normal list an associative one
/proc/make_associative(list/flat_list)
	. = list()
	for(var/thing in flat_list)
		.[thing] = TRUE

///Picks from the list, with some safeties, and returns the "default" arg if it fails
#define DEFAULTPICK(L, default) ((islist(L) && length(L)) ? pick(L) : default)

/* Definining a counter as a series of key -> numeric value entries

 * All these procs modify in place.
*/

/proc/counterlist_scale(list/L, scalar)
	var/list/out = list()
	for(var/key in L)
		out[key] = L[key] * scalar
	. = out

/proc/counterlist_sum(list/L)
	. = 0
	for(var/key in L)
		. += L[key]

/proc/counterlist_normalise(list/L)
	var/avg = counterlist_sum(L)
	if(avg != 0)
		. = counterlist_scale(L, 1 / avg)
	else
		. = L

/proc/counterlist_combine(list/L1, list/L2)
	for(var/key in L2)
		var/other_value = L2[key]
		if(key in L1)
			L1[key] += other_value
		else
			L1[key] = other_value

/// Turns an associative list into a flat list of keys
/proc/assoc_to_keys(list/input)
	var/list/keys = list()
	for(var/key in input)
		UNTYPED_LIST_ADD(keys, key)
	return keys

/// Turns an associative list into a flat list of keys, but for sprite accessories, respecting the locked variable
/proc/assoc_to_keys_features(list/input)
	var/list/keys = list()
	for(var/key in input)
		var/datum/sprite_accessory/value = input[key]
		if(value?.locked)
			continue
		UNTYPED_LIST_ADD(keys, key)
	return keys

///Gets the total amount of everything in the associative list.
/proc/assoc_value_sum(list/input)
	var/keys = 0
	for(var/key in input)
		keys += input[key]
	return keys

///compare two lists, returns TRUE if they are the same
/proc/compare_list(list/l,list/d)
	if(!islist(l) || !islist(d))
		return FALSE

	if(l.len != d.len)
		return FALSE

	for(var/i in 1 to l.len)
		if(l[i] != d[i])
			return FALSE

	return TRUE

#define LAZY_LISTS_OR(left_list, right_list)\
	( length(left_list)\
		? length(right_list)\
			? (left_list | right_list)\
			: left_list.Copy()\
		: length(right_list)\
			? right_list.Copy()\
			: null\
	)

///Returns a list with items filtered from a list that can call callback
/proc/special_list_filter(list/list_to_filter, datum/callback/condition)
	if(!islist(list_to_filter) || !length(list_to_filter) || !istype(condition))
		return list()
	. = list()
	for(var/i in list_to_filter)
		if(condition.Invoke(i))
			. |= LIST_VALUE_WRAP_LISTS(i)

///Returns a list with all weakrefs resolved
/proc/recursive_list_resolve(list/list_to_resolve)
	. = list()
	for(var/element in list_to_resolve)
		if(istext(element))
			. += element
			var/possible_assoc_value = list_to_resolve[element]
			if(possible_assoc_value)
				.[element] = recursive_list_resolve_element(possible_assoc_value)
		else
			. += list(recursive_list_resolve_element(element))

///Helper for recursive_list_resolve()
/proc/recursive_list_resolve_element(element)
	if(islist(element))
		var/list/inner_list = element
		return recursive_list_resolve(inner_list)
	else if(isweakref(element))
		var/datum/weakref/ref = element
		return ref.resolve()
	else
		return element

/**
 * Intermediate step for preparing lists to be passed into the lua editor tgui.
 * Resolves weakrefs, converts some values without a standard textual representation to text,
 * and can handle self-referential lists and potential duplicate output keys.
 */
/proc/prepare_lua_editor_list(list/target_list, list/visited)
	if(!visited)
		visited = list()
	var/list/ret = list()
	visited[target_list] = ret
	var/list/duplicate_keys = list()
	for(var/i in 1 to target_list.len)
		var/key = target_list[i]
		var/new_key = key
		if(isweakref(key))
			var/datum/weakref/ref = key
			new_key = ref.resolve() || "null weakref"
		else if(key == world)
			new_key = world.name
		else if(ref(key) == "\[0xe000001\]")
			new_key = "global"
		else if(islist(key))
			if(visited[key])
				new_key = visited[key]
			else
				new_key = prepare_lua_editor_list(key, visited)
		var/value
		if(!isnull(key) && !isnum(key))
			value = target_list[key]
		if(isweakref(value))
			var/datum/weakref/ref = value
			value = ref.resolve() || "null weakref"
		if(value == world)
			value = "world"
		else if(ref(value) == "\[0xe000001\]")
			value = "global"
		else if(islist(value))
			if(visited[value])
				value = visited[value]
			else
				value = prepare_lua_editor_list(value, visited)
		var/list/to_add = list()
		if(!isnull(value))
			var/final_key = new_key
			while(duplicate_keys[final_key])
				duplicate_keys[new_key]++
				final_key = "[new_key] ([duplicate_keys[new_key]])"
			duplicate_keys[final_key] = 1
			to_add[final_key] = value
		else
			to_add += list(new_key)
		ret += to_add
		if(i < target_list.len)
			CHECK_TICK
	return ret

/**
 * Converts a list into a list of assoc lists of the form ("key" = key, "value" = value)
 * so that list keys that are themselves lists can be fully json-encoded
 * and that unique objects with the same string representation do not
 * produce duplicate keys that are clobbered by the standard JavaScript JSON.parse function
 */
/proc/kvpify_list(list/target_list, depth = INFINITY, list/visited)
	if(!visited)
		visited = list()
	var/list/ret = list()
	visited[target_list] = ret
	for(var/i in 1 to target_list.len)
		var/key = target_list[i]
		var/new_key = key
		if(islist(key) && depth)
			if(visited[key])
				new_key = visited[key]
			else
				new_key = kvpify_list(key, depth-1, visited)
		var/value
		if(!isnull(key) && !isnum(key))
			value = target_list[key]
		if(islist(value) && depth)
			if(visited[value])
				value = visited[value]
			else
				value = kvpify_list(value, depth-1, visited)
		if(!isnull(value))
			ret += list(list("key" = new_key, "value" = value))
		else
			ret += list(list("key" = i, "value" = new_key))
		if(i < target_list.len)
			CHECK_TICK
	return ret

/// Compares 2 lists, returns TRUE if they are the same
/proc/deep_compare_list(list/list_1, list/list_2)
	if(list_1 == list_2)
		return TRUE

	if(!islist(list_1) || !islist(list_2))
		return FALSE

	if(list_1.len != list_2.len)
		return FALSE

	for(var/i in 1 to list_1.len)
		var/key_1 = list_1[i]
		var/key_2 = list_2[i]
		if (islist(key_1) && islist(key_2))
			if(!deep_compare_list(key_1, key_2))
				return FALSE
		else if(key_1 != key_2)
			return FALSE
		if(istext(key_1) || islist(key_1) || ispath(key_1) || isdatum(key_1) || key_1 == world)
			var/value_1 = list_1[key_1]
			var/value_2 = list_2[key_1]
			if (islist(value_1) && islist(value_2))
				if(!deep_compare_list(value_1, value_2))
					return FALSE
			else if(value_1 != value_2)
				return FALSE
	return TRUE

/// Returns a copy of the list where any element that is a datum is converted into a weakref
/proc/weakrefify_list(list/target_list, list/visited)
	if(!visited)
		visited = list()
	var/list/ret = list()
	visited[target_list] = ret
	for(var/i in 1 to target_list.len)
		var/key = target_list[i]
		var/new_key = key
		if(isdatum(key))
			new_key = WEAKREF(key)
		else if(islist(key))
			if(visited.Find(key))
				new_key = visited[key]
			else
				new_key = weakrefify_list(key, visited)
		var/value
		if(!isnull(key) && !isnum(key))
			value = target_list[key]
		if(isdatum(value))
			value = WEAKREF(value)
		else if(islist(value))
			if(visited[value])
				value = visited[value]
			else
				value = weakrefify_list(value, visited)
		var/list/to_add = list(new_key)
		if(!isnull(value))
			to_add[new_key] = value
		ret += to_add
		if(i < target_list.len)
			CHECK_TICK
	return ret

/// Runtimes if the passed in list is not sorted
/proc/assert_sorted(list/list, name, cmp = GLOBAL_PROC_REF(cmp_numeric_asc))
	var/last_value = list[1]

	for (var/index in 2 to list.len)
		var/value = list[index]

		if (call(cmp)(value, last_value) < 0)
			stack_trace("[name] is not sorted. value at [index] ([value]) is in the wrong place compared to the previous value of [last_value] (when compared to by [cmp])")

		last_value = value

/**
 * Converts a list of coordinates, or an assosciative list if passed, into a turf by calling locate(x, y, z) based on the values in the list
 */
/proc/coords2turf(list/coords)
	if("x" in coords)
		return locate(coords["x"], coords["y"], coords["z"])
	return locate(coords[1], coords[2], coords[3])

/**
 * Given a list and a list of its variant hints, appends variants that aren't explicitly required by dreamluau,
 * but are required by the lua editor tgui.
 */
/proc/add_lua_editor_variants(list/values, list/variants, list/visited, path = "")
	if(!islist(visited))
		visited = list()
		visited[values] = "\[\]"
	if(!islist(values) || !islist(variants))
		return
	if(values.len != variants.len)
		CRASH("values and variants must be the same length")
	for(var/i in 1 to variants.len)
		var/pair = variants[i]
		var/pair_modified = FALSE
		if(isnull(pair))
			pair = list("key", "value")
		var/key = values[i]
		if(islist(key))
			if(visited[key])
				pair["key"] = list("cycle", visited[key])
			else
				var/list/key_variants = pair["key"]
				var/new_path = path + "\[[i], \"key\"\],"
				visited[key] = new_path
				add_lua_editor_variants(key, key_variants, visited, new_path)
				visited -= key
				pair["key"] = list("list", key_variants)
			pair_modified = TRUE
		else if(isdatum(key) || key == world || ref(key) == "\[0xe000001\]")
			pair["key"] = list("ref", ref(key))
			pair_modified = TRUE
		var/value
		if(!isnull(key) && !isnum(key))
			value = values[key]
		if(islist(value))
			if(visited[value])
				pair["value"] = list("cycle", visited[value])
			else
				var/list/value_variants = pair["value"]
				var/new_path = path + "\[[i], \"value\"\],"
				visited[value] = new_path
				add_lua_editor_variants(value, value_variants, visited, new_path)
				visited -= value
				pair["value"] = list("list", value_variants)
			pair_modified = TRUE
		else if(isdatum(value) || value == world || ref(value) == "\[0xe000001\]")
			pair["value"] = list("ref", ref(value))
			pair_modified = TRUE
		if(pair_modified && pair != variants[i])
			variants[i] = pair
		if(i < variants.len)
			CHECK_TICK

/proc/add_lua_return_value_variants(list/values, list/variants)
	if(!islist(values) || !islist(variants))
		return
	if(values.len != variants.len)
		CRASH("values and variants must be the same length")
	for(var/i in 1 to values.len)
		var/value = values[i]
		if(islist(value))
			add_lua_editor_variants(value, variants[i])
		else if(isdatum(value) || value == world || ref(value) == "\[0xe000001\]")
			variants[i] = list("ref", ref(value))

/proc/deep_copy_without_cycles(list/values, list/visited)
	if(!islist(visited))
		visited = list()
	if(!islist(values))
		return values
	var/list/ret = list()
	var/cycle_count = 0
	visited[values] = TRUE
	for(var/i in 1 to values.len)
		var/key = values[i]
		var/out_key = key
		if(islist(key))
			if(visited[key])
				do
					out_key = "\[cyclical reference[cycle_count ? " (i)" : ""]\]"
					cycle_count++
				while(values.Find(out_key))
			else
				visited[key] = TRUE
				out_key = deep_copy_without_cycles(key, visited)
				visited -= key
		var/value
		if(!isnull(key) && !isnum(key))
			value = values[key]
		var/out_value = value
		if(islist(value))
			if(visited[value])
				out_value = "\[cyclical reference\]"
			else
				visited[value] = TRUE
				out_value = deep_copy_without_cycles(value, visited)
				visited -= value
		var/list/to_add = list(out_key)
		if(!isnull(out_value))
			to_add[out_key] = out_value
		ret += to_add
		if(i < values.len)
			CHECK_TICK
	return ret

/**
 * Given a list and a list of its variant hints, removes any list key/values that are represent lua values that could not be directly converted to DM.
 */
/proc/remove_non_dm_variants(list/return_values, list/variants, list/visited)
	if(!islist(visited))
		visited = list()
	if(!islist(return_values) || !islist(variants) || visited[return_values])
		return
	visited[return_values] = TRUE
	if(return_values.len != variants.len)
		CRASH("return_values and variants must be the same length")
	for(var/i in 1 to variants.len)
		var/pair = variants[i]
		if(!islist(variants))
			continue
		var/key = return_values[i]
		if(pair["key"])
			if(!islist(pair["key"]))
				return_values[i] = null
				continue
			remove_non_dm_variants(key, pair["key"], visited)
		if(pair["value"])
			if(!islist(pair["value"]))
				return_values[key] = null
				continue
			remove_non_dm_variants(return_values[key], pair["value"], visited)

/proc/compare_lua_logs(list/log_1, list/log_2)
	if(log_1 == log_2)
		return TRUE
	for(var/field in list("status", "name", "message", "chunk"))
		if(log_1[field] != log_2[field])
			return FALSE
	switch(log_1["status"])
		if("finished", "yield")
			return deep_compare_list(
					recursive_list_resolve(log_1["return_values"]),
					recursive_list_resolve(log_2["return_values"])
					) && deep_compare_list(log_1["variants"], log_2["variants"])
		if("runtime")
			return log_1["file"] == log_2["file"]\
				&& log_1["line"] == log_2["line"]\
				&& deep_compare_list(log_1["stack"], log_2["stack"])
		else
			return TRUE
