# Code Standards

These are our code standards. They include information about how to properly work with our code, rules about how to structure what you're writing, and some more general information about BYOND and Dream Maker.

As with the style guide, you are expected to follow these specifications in order to make everyone's lives easier. It'll save both your time and ours, by making sure you don't have to make any changes and we don't have to ask you to. Thank you for reading this file!

1. [General](#general)
2. [Structural](#structural)
3. [Optimization](#optimization)
4. [BYOND Quirks](#dream-maker-quirks/tricks)
5. [SQL](#sql)

## General

### Object Oriented Code

As BYOND's Dream Maker (henceforth "DM") is an object-oriented language, code must be object-oriented when possible in order to be more flexible when adding content to it. If you don't know what "object-oriented" means, we highly recommend you do some light research to grasp the basics.

### Avoid hacky code
Hacky code, such as adding specific checks, is highly discouraged and only allowed when there is ***no*** other option. (Protip: "I couldn't immediately think of a proper way so thus there must be no other option" is not gonna cut it here! If you can't think of anything else, say that outright and admit that you need help with it. Maintainers exist for exactly that reason.)

You can avoid hacky code by using object-oriented methodologies, such as overriding a function (called "procs" in DM) or sectioning code into functions and then overriding them as required.

### Develop Secure Code

* Player input must always be escaped safely, we recommend you use stripped_input in all cases where you would use input. Essentially, just always treat input from players as inherently malicious and design with that use case in mind.
	* This extends to much further than just numbers or strings. You should always sanity check that an input is valid, especially when it comes to datums or references!
	* Input stalling is a very common exploit / bug that involves opening an input window when in a valid state, and triggering the input after exiting the valid state. These can be very serious, and allow players to teleport across the map or remove someone's brain at any given moment. If you check the player must be in a specific context before an input, you should generally check that they are still in the context AFTER the input resolves.
		* For example, if you have an item which can be used (in hand) by a player to make it explode, but you want them to confirm (via prompt) that they want it to explode, you should check that the item is still in the player's hands after confirming. Otherwise, they could drop it and explode it at any moment they want.
	* Another less common exploit involves allowing a player to open multiple of an input at once. This may allow the player to stack effects, such as triggering 10 explosions when only 1 should be allowed. While a lot of code is generally built in a way making this infeasible (usually due to runtime errors), it is noteworthy regardless.
		* You should also consider if it would make sense to apply a timeout to your input, to prevent players from opening it and keeping it on their screen until convenient.

* Calls to the database must be escaped properly - use sanitizeSQL to escape text based database entries from players or admins, and isnum() for number based database entries from players or admins.

* All calls to topics must be checked for correctness. Topic href calls can be easily faked by clients, so you should ensure that the call is valid for the state the item is in. Do not rely on the UI code to provide only valid topic calls, because it won't.
	* Don't expose a topic call to more than what you need it to. If you are only looking for an item inside an atom, don't look for every item in the world - just look in the atom's contents.
		* You rarely should call `locate(ref)` without specifying a list! This is a serious exploit vector which can be used to spawn Nar'sie or delete players across the map. Try narrowing it down via a list - such as `locate(ref) in contents`, to find an item in an atom's contents.

* Information that players could use to metagame (that is, to identify round information and/or antagonist type via information that would not be available to them in character) should be kept as administrator only.

* It is recommended as well you do not expose information about the players - even something as simple as the number of people who have readied up at the start of the round can and has been used to try to identify the round type.

* Where you have code that can cause large-scale modification and *FUN*, make sure you start it out locked behind one of the default admin roles - use common sense to determine which role fits the level of damage a function could do.

### User Interfaces

* All new player-facing user interfaces must use TGUI, unless they are critical user interfaces.
* All critical user interfaces must be usable with HTML or the interface.dmf, with tgui being *optional* for this UI.
	* Examples of critical user interfaces are the chat box, the observe button, the stat panel, and the chat input.
* Documentation for TGUI can be found at:
	* [tgui/README.md](../tgui/README.md)
	* [tgui/tutorial-and-examples.md](../tgui/docs/tutorial-and-examples.md)

### Dont override type safety checks

The use of the : operator to override type safety checks is not allowed. You must cast the variable to the proper type.

### Do not use text/string based type paths

It is rarely allowed to put type paths in a text format, as there are no compile errors if the type path no longer exists. Here is an example:

```DM
//Good
var/path_type = /obj/item/baseball_bat

//Bad
var/path_type = "/obj/item/baseball_bat"
```

### Other Notes

* Code should be modular where possible; if you are working on a new addition, then strongly consider putting it in its own file unless it makes sense to put it with similar ones (i.e. a new tool would go in the "tools.dm" file)

* Bloated code may be necessary to add a certain feature, which means there has to be a judgement over whether the feature is worth having or not. You can help make this decision easier by making sure your code is modular.

* You are expected to help maintain the code that you add, meaning that if there is a problem then you are likely to be approached in order to fix any issues, runtimes, or bugs.

* Separating single lines into more readable blocks is not banned, however you should use it only where it makes new information more accessible, or aids maintainability. We do not have a column limit, and mass conversions will not be received well.

* If you used regex to replace code during development of your code, post the regex in your PR for the benefit of future developers and downstream users.

* Changes to the `/config` tree must be made in a way that allows for updating server deployments while preserving previous behaviour. This is due to the fact that the config tree is to be considered owned by the user and not necessarily updated alongside the remainder of the code. The code to preserve previous behaviour may be removed at some point in the future given the OK by maintainers.

## Structural
### No duplicated code (Don't repeat yourself)
Copying code from one place to another may be suitable for small, short-time projects, but /tg/station is a long-term project and highly discourages this.

Instead you can use object orientation, or simply placing repeated code in a function, to obey this specification easily.

### Prefer `Initialize()` over `New()` for atoms

Our game controller is pretty good at handling long operations and lag, but it can't control what happens when the map is loaded, which calls `New` for all atoms on the map. If you're creating a new atom, use the `Initialize` proc to do what you would normally do in `New`. This cuts down on the number of proc calls needed when the world is loaded. See here for details on `Initialize`: https://github.com/tgstation/tgstation/blob/34775d42a2db4e0f6734560baadcfcf5f5540910/code/game/atoms.dm#L166
While we normally encourage (and in some cases, even require) bringing out of date code up to date when you make unrelated changes near the out of date code, that is not the case for `New` -> `Initialize` conversions. These systems are generally more dependent on parent and children procs so unrelated random conversions of existing things can cause bugs that take months to figure out.

### Files

* Because runtime errors do not give the full path, try to avoid having files with the same name across folders.

* File names should not be mixed case, or contain spaces or any character that would require escaping in a uri.

* Files and path accessed and referenced by code above simply being #included should be strictly lowercase to avoid issues on filesystems where case matters.

### RegisterSignal()

#### PROC_REF Macros
When referencing procs in RegisterSignal, Callback and other procs you should use PROC_REF, TYPE_PROC_REF and GLOBAL_PROC_REF macros.
They ensure compilation fails if the reffered to procs change names or get removed.
The macro to be used depends on how the proc you're in relates to the proc you want to use:

PROC_REF if the proc you want to use is defined on the current proc type or any of its ancestor types.
Example:
```
/mob/proc/funny()
	to_chat(world,"knock knock")

/mob/subtype/proc/very_funny()
	to_chat(world,"who's there?")

/mob/subtype/proc/do_something()
	// Proc on our own type
	RegisterSignal(x, COMSIG_OTHER_FAKE, PROC_REF(very_funny))
	// Proc on ancestor type, /mob is parent type of /mob/subtype
	RegisterSignal(x, COMSIG_FAKE, PROC_REF(funny))
```

TYPE_PROC_REF if the proc you want to use is defined on a different unrelated type
Example:
```
/obj/thing/proc/funny()
	to_chat(world,"knock knock")

/mob/subtype/proc/do_something()
	var/obj/thing/x = new()
	// we're referring to /obj/thing proc inside /mob/subtype proc
	RegisterSignal(x, COMSIG_FAKE, TYPE_PROC_REF(/obj/thing, funny))
```

GLOBAL_PROC_REF if the proc you want to use is a global proc.
Example:
```
/proc/funny()
	to_chat(world,"knock knock")

/mob/subtype/proc/do_something()
	addtimer(CALLBACK(GLOBAL_PROC, GLOBAL_PROC_REF(funny)), 100))
```

Note that the same rules go for verbs too! We have VERB_REF() and TYPE_VERB_REF() as you need it in these same cases. GLOBAL_VERB_REF() isn't a thing however, as verbs are not global.

#### Signal Handlers

All procs that are registered to listen for signals using `RegisterSignal()` must contain at the start of the proc `SIGNAL_HANDLER` eg;
```
/type/path/proc/signal_callback()
	SIGNAL_HANDLER
	// rest of the code
```
This is to ensure that it is clear the proc handles signals and turns on a lint to ensure it does not sleep.

Any sleeping behaviour that you need to perform inside a `SIGNAL_HANDLER` proc must be called asynchronously (e.g. with `INVOKE_ASYNC()`) or be redone to work asynchronously.

#### `override`

Each atom can only register a signal on the same object once, or else you will get a runtime. Overriding signals is usually a bug, but if you are confident that it is not, you can silence this runtime with `override = TRUE`.

```dm
RegisterSignal(fork, COMSIG_FORK_STAB, PROC_REF(on_fork_stab), override = TRUE)
```

If you decide to do this, you should make it clear with a comment explaining why it is necessary. This helps us to understand that the signal override is not a bug, and may help us to remove it in the future if the assumptions change.

### Enforcing parent calling

When adding new signals to root level procs, eg;
```
/atom/proc/setDir(newdir)
	SHOULD_CALL_PARENT(TRUE)
	SEND_SIGNAL(src, COMSIG_ATOM_DIR_CHANGE, dir, newdir)
	dir = newdir
```
The `SHOULD_CALL_PARENT(TRUE)` lint should be added to ensure that overrides/child procs call the parent chain and ensure the signal is sent.

### Avoid unnecessary type checks and obscuring nulls in lists

Typecasting in `for` loops carries an implied `istype()` check that filters non-matching types, nulls included. The `as anything` key can be used to skip the check.

If we know the list is supposed to only contain the desired type then we want to skip the check not only for the small optimization it offers, but also to catch any null entries that may creep into the list.

Nulls in lists tend to point to improperly-handled references, making hard deletes hard to debug. Generating a runtime in those cases is more often than not positive.

This is bad:
```DM
var/list/bag_of_atoms = list(new /obj, new /mob, new /atom, new /atom/movable, new /atom/movable)
var/highest_alpha = 0
for(var/atom/thing in bag_of_atoms)
	if(thing.alpha <= highest_alpha)
		continue
	highest_alpha = thing.alpha
```

This is good:
```DM
var/list/bag_of_atoms = list(new /obj, new /mob, new /atom, new /atom/movable, new /atom/movable)
var/highest_alpha = 0
for(var/atom/thing as anything in bag_of_atoms)
	if(thing.alpha <= highest_alpha)
		continue
	highest_alpha = thing.alpha
```

### All `process` procs need to make use of delta-time and be frame independent

In a lot of our older code, `process()` is frame dependent. Here's some example mob code:

```DM
/mob/testmob
	var/health = 100
	var/health_loss = 4 //We want to lose 2 health per second, so 4 per SSmobs process

/mob/testmob/process(seconds_per_tick) //SSmobs runs once every 2 seconds
	health -= health_loss
```

As the mobs subsystem runs once every 2 seconds, the mob now loses 4 health every process, or 2 health per second. This is called frame dependent programming.

Why is this an issue? If someone decides to make it so the mobs subsystem processes once every second (2 times as fast), your effects in process() will also be two times as fast. Resulting in 4 health loss per second rather than 2.

How do we solve this? By using delta-time. Delta-time is the amount of seconds you would theoretically have between 2 process() calls. In the case of the mobs subsystem, this would be 2 (As there is 2 seconds between every call in `process()`). Here is a new example using delta-time:

```DM
/mob/testmob
	var/health = 100
	var/health_loss = 2 //Health loss every second

/mob/testmob/process(seconds_per_tick) //SSmobs runs once every 2 seconds
	health -= health_loss * seconds_per_tick
```

In the above example, we made our health_loss variable a per second value rather than per process. In the actual process() proc we then make use of deltatime. Because SSmobs runs once every  2 seconds. Delta_time would have a value of 2. This means that by doing health_loss * seconds_per_tick, you end up with the correct amount of health_loss per process, but if for some reason the SSmobs subsystem gets changed to be faster or slower in a PR, your health_loss variable will work the same.

For example, if SSmobs is set to run once every 4 seconds, it would call process once every 4 seconds and multiply your health_loss var by 4 before subtracting it. Ensuring that your code is frame independent.

## Optimization
### Startup/Runtime tradeoffs with lists and the "hidden" init proc

First, read the comments in [this BYOND thread](http://www.byond.com/forum/?post=2086980&page=2#comment19776775), starting where the link takes you.

There are two key points here:

1) Defining a list in the variable's definition calls a hidden proc - init. If you have to define a list at startup, do so in New() (or preferably Initialize()) and avoid the overhead of a second call (Init() and then New())

2) It also consumes more memory to the point where the list is actually required, even if the object in question may never use it!

Remember: although this tradeoff makes sense in many cases, it doesn't cover them all. Think carefully about your addition before deciding if you need to use it.

### Icons are for image manipulation and defining an obj's `.icon` var, appearances are for everything else.

BYOND will allow you to use a raw icon file or even an icon datum for underlays, overlays, and what not (you can even use strings to refer to an icon state on the current icon). The issue is these get converted by BYOND to appearances on every overlay insert or removal involving them, and this process requires inserting the new appearance into the global list of appearances, and informing clients about them.

Converting them yourself to appearances and storing this converted value will ensure this process only has to happen once for the lifetime of the round. Helper functions exist to do most of the work for you.


Bad:
```dm
/obj/machine/update_overlays(blah)
	if (stat & broken)
		add_overlay(icon(broken_icon))  //this icon gets created, passed to byond, converted to an appearance, then deleted.
		return
	if (is_on)
		add_overlay("on") //also bad, the converstion to an appearance still has to happen
	else
		add_overlay(iconstate2appearance(icon, "off")) //this might seem alright, but not storing the value just moves the repeated appearance generation to this proc rather then the core overlay management. It would only be acceptable (and to some degree perferred) if this overlay is only ever added once (like in init code)
```

Good:
```dm
/obj/machine/update_overlays(var/blah)
	var/static/on_overlay
	var/static/off_overlay
	var/static/broken_overlay
	if(isnull(on_overlay)) //static vars initialize with global variables, meaning src is null and this won't pass integration tests unless you check.
		on_overlay = iconstate2appearance(icon, "on")
		off_overlay = iconstate2appearance(icon, "off")
		broken_overlay = icon2appearance(broken_icon)
	if (stat & broken)
		add_overlay(broken_overlay)
		return
	if (is_on)
		add_overlay(on_overlay)
	else
		add_overlay(off_overlay)
	...
```

Note: images are appearances with extra steps, and don't incur the overhead in conversion.


### Do not abuse associated lists.

Associated lists that could instead be variables or statically defined number indexed lists will use more memory, as associated lists have a 24 bytes per item overhead (vs 8 for lists and most vars), and are slower to search compared to static/global variables and lists with known indexes.


Bad:
```dm
/obj/machine/update_overlays(var/blah)
	var/static/our_overlays
	if (isnull(our_overlays))
		our_overlays = list("on" = iconstate2appearance(overlay_icon, "on"), "off" = iconstate2appearance(overlay_icon, "off"), "broken" = iconstate2appearance(overlay_icon, "broken"))
	if (stat & broken)
		add_overlay(our_overlays["broken"])
		return
	...
```

Good:
```dm
#define OUR_ON_OVERLAY 1
#define OUR_OFF_OVERLAY 2
#define OUR_BROKEN_OVERLAY 3

/obj/machine/update_overlays(var/blah)
	var/static/our_overlays
	if (isnull(our_overlays))
		our_overlays = list(iconstate2appearance(overlay_icon, "on"), iconstate2appearance(overlay_icon, "off"), iconstate2appearance(overlay_icon, "broken"))
	if (stat & broken)
		add_overlay(our_overlays[OUR_BROKEN_OVERLAY])
		return
	...

#undef OUR_ON_OVERLAY
#undef OUR_OFF_OVERLAY
#undef OUR_BROKEN_OVERLAY
```
Storing these in a flat (non-associated) list saves on memory, and using defines to reference locations in the list saves CPU time searching the list.

Also good:
```dm
/obj/machine/update_overlays(var/blah)
	var/static/on_overlay
	var/static/off_overlay
	var/static/broken_overlay
	if(isnull(on_overlay))
		on_overlay = iconstate2appearance(overlay_icon, "on")
		off_overlay = iconstate2appearance(overlay_icon, "off")
		broken_overlay = iconstate2appearance(overlay_icon, "broken")
	if (stat & broken)
		add_overlay(broken_overlay)
		return
	...
```
Proc variables, static variables, and global variables are resolved at compile time, so the above is equivalent to the second example, but is easier to read, and avoids the need to store a list.

Note: While there has historically been a strong impulse to use associated lists for caching of computed values, this is the easy way out and leaves a lot of hidden overhead. Please keep this in mind when designing core/root systems that are intended for use by other code/coders. It's normally better for consumers of such systems to handle their own caching using vars and number indexed lists, than for you to do it using associated lists.

## Dream Maker Quirks/Tricks

Like all languages, Dream Maker has its quirks, some of them are beneficial to us, some are harmful.

### Loops
#### In-To for-loops

`for(var/i = 1, i <= some_value, i++)` is a fairly standard way to write an incremental for loop in most languages (especially those in the C family), but DM's `for(var/i in 1 to some_value)` syntax is oddly faster than its implementation of the former syntax; where possible, it's advised to use DM's syntax. (Note, the `to` keyword is inclusive, so it automatically defaults to replacing `<=`; if you want `<` then you should write it as `1 to some_value-1`).

HOWEVER, if either `some_value` or `i` changes within the body of the for (underneath the `for(...)` header) or if you are looping over a list AND changing the length of the list then you can NOT use this type of for-loop!

#### `for(var/A in list)` versus `for(var/i in 1 to list.len)`

The former is faster than the latter, as shown by the following profile results:
https://file.house/zy7H.png
Code used for the test in a readable format:
https://pastebin.com/w50uERkG

### Dot variable (`.`)

The `.` variable is present in all procs. It refers to the value returned by a proc.

```dm
/proc/return_six()
	. = 3
	. *= 2

// ...is equivalent to...
/proc/return_six()
	var/output = 3
	output *= 2
	return output
```

At its best, it can make some very common patterns easy to use, and harder to mess up. However, at its worst, it can make it significantly harder to understand what a proc does.

```dm
/proc/complex_proc()
	if (do_something())
		some_code()
		if (do_something_else())
			. = TRUE // Uh oh, what's going on!

	// even
	// more
	// code
	if (bad_condition())
		return // This actually will return something set from earlier!
```

This sort of behavior can create some nasty to debug errors with things returning when you don't expect them to. Would you see `return` and it expect it to return a value, without reading all the code before it? Furthermore, a simple `return` statement cannot easily be checked by the LSP, meaning you can't easily check what is actually being returned. Basically, `return output` lets you go to where `output` is defined/set. `return` does not.

Even in simple cases, this can create some just generally hard to read code, seemingly in the pursuit of being clever.

```dm
/client/p_were(gender)
	. = "was"
	if (gender == PLURAL || gender == NEUTER)
		. = "were"
```

Because of these problems, it is encouraged to prefer standard, explicit return statements. The above code would be best written as:

```dm
/client/p_were(gender)
	if (gender == PLURAL || gender == NEUTER)
		return "were"
	else
		return "was"
```

#### Exception: `. = ..()`

As hinted at before, `. = ..()` is *extremely* common. This will call the parent function, and preserve its return type. Code like this:

```dm
/obj/item/spoon/attack()
	. = ..()
	visible_message("Whack!")
```

...is completely accepted, and in fact, usually *prefered* over:

```dm
/obj/item/spoon/attack()
	var/output = ..()
	visible_message("Whack!")
	return output
```

#### Exception: Runtime resilience

One unique property of DM is the ability for procs to error, but for code to continue. For instance, the following:

```dm
/proc/uh_oh()
	CRASH("oh no!")

/proc/main()
	to_chat(world, "1")
	uh_oh()
	to_chat(world, "2")
```

...would print both 1 *and* 2, which may be unexpected if you come from other languages.

This is where `.` provides a new useful behavior--**a proc that runtimes will return `.`**.

Meaning:

```dm
/proc/uh_oh()
	. = "woah!"
	CRASH("oh no!")

/proc/main()
	to_chat(world, uh_oh())
```

...will print `woah!`.

For this reason, it is acceptable for `.` to be used in places where consumers can reasonably continue in the event of a runtime.

If you are using `.` in this case (or for another case that might be acceptable, other than most uses of `. = ..()`), it is still prefered that you explicitly `return .` in order to prevent both editor issues and readability/error-prone issues.

```dm
/proc/uh_oh()
	. = "woah!"

	if (do_something())
		call_code()
		if (!working_fine())
			return . // Instead of `return`, we explicitly `return .`

	if (some_fail_state())
		CRASH("youch!")

	return . // `return .` is used at the end, to signify it has been used
```

```dm
/obj/item/spoon/super_attack()
	. = ..()
	if (. == BIGGER_SUPER_ATTACK)
		return BIGGER_SUPER_ATTACK // More readable than `.`

	// Due to how common it is, most uses of `. = ..()` do not need a trailing `return .`
```

### The BYOND walk procs

BYOND has a few procs that move one atom towards/away from another, `walk()`, `walk_to()`, `walk_towards`, `walk_away()` and `walk_rand()`.

The way they pull this off, while fine for the language itself, makes a mess of our master-controller, and can cause the whole game to slow down. Do not use them.

The following is a list of procs, and their safe replacements.

* Removing something from the loop `walk(0)` -> `SSmove_manager.stop_looping()`
* Move in a direction `walk()` -> `SSmove_manager.move()`
* Move towards a thing, taking turf density into account`walk_to()` -> `SSmove_manager.move_to()`
* Move in a thing's direction, ignoring turf density `walk_towards()` -> `SSmove_manager.home_onto()` and `SSmove_manager.move_towards_legacy()`, check the documentation to see which you like better
* Move away from something, taking turf density into account `walk_away()` -> `SSmove_manager.move_away()`
* Move to a random place nearby. NOT random walk `walk_rand()` -> `SSmove_manager.move_rand()` is random walk, `SSmove_manager.move_to_rand()` is walk to a random place

### Avoid pointer use

BYOND has a variable type called pointers, which allow you to reference a variable rather then its value. As an example of how this works:

```
var/pointed_at = "text"
var/value = pointed_at // copies the VALUE of pointed at
var/reference = &pointed_at // points at pointed_at itself

// so we can retain a reference even if pointed_at changes
pointed_at = "text AGAIN"
world << (*reference) // Deref to get the value, outputs "text AGAIN"

// or modify the var remotely
*reference = "text a THIRD TIME"
world << pointed_at // outputs "text a THIRD TIME"
```

The problem with this is twofold.
- First: if you use a pointer to reference a var on a datum, it is essentially as if you held an invisible reference to that datum. This risks hard deletes in very unclear ways that cannot be tested for.
- Second: People don't like, understand how pointers work? They mix them up with classical C pointers, when they're more like `std::shared_ptr`. This leads to code that just doesn't work properly, or is hard to follow without first getting your mind around it. It also risks hiding what code does in dumb ways because pointers don't have unique types.

For these reasons and with the hope of avoiding pointers entering general use, be very careful using them, if you use them at all.

### BYOND hellspawn

What follows is documentation of inconsistent or strange behavior found in our engine, BYOND.
It's listed here in the hope that it will prevent fruitless debugging in future.

#### Icon hell

Due to how they are internally represented as part of appearance, overlays and underlays which have an icon_state named the same as an icon_state on the parent object will use the parent's icon_state and look completely wrong. This has caused two bugs with underlay lighting whenever a turf had the icon_state of "transparent" or "dark" and their lighting objects also had those states - because when the lighting underlays were in those modes they would be rendered by the client to look like the icons the floor used. When adding something as an overlay or an underlay make sure it can't match icon_state names with whatever you're adding it to.

## SQL

* Do not use the shorthand sql insert format (where no column names are specified) because it unnecessarily breaks all queries on minor column changes and prevents using these tables for tracking outside related info such as in a connected site/forum.

* All changes to the database's layout(schema) must be specified in the database changelog in SQL, as well as reflected in the schema files

* Any time the schema is changed the `schema_revision` table and `DB_MAJOR_VERSION` or `DB_MINOR_VERSION` defines must be incremented.

* Queries must never specify the database, be it in code, or in text files in the repo.

* Primary keys are inherently immutable and you must never do anything to change the primary key of a row or entity. This includes preserving auto increment numbers of rows when copying data to a table in a conversion script. No amount of bitching about gaps in ids or out of order ids will save you from this policy.

* The ttl for data from the database is 10 seconds. You must have a compelling reason to store and reuse data for longer then this.

* Do not write stored and transformed data to the database, instead, apply the transformation to the data in the database directly.
	* ie: SELECTing a number from the database, doubling it, then updating the database with the doubled number. If the data in the database changed between step 1 and 3, you'll get an incorrect result. Instead, directly double it in the update query. `UPDATE table SET num = num*2` instead of `UPDATE table SET num = [num]`.
	* if the transformation is user provided (such as allowing a user to edit a string), you should confirm the value being updated did not change in the database in the intervening time before writing the new user provided data by checking the old value with the current value in the database, and if it has changed, allow the user to decide what to do next.
