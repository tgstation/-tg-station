// Replaces chemgrenade stuff, allowing reagent explosions to be called from anywhere.
// It should be called using a location, the range, and a list of reagents involved.

// Threatscale is a multiplier for the 'threat' of the grenade. If you're increasing the affected range drastically, you might want to improve this.
// Extra heat affects the temperature of the mixture, and may cause it to react in different ways.

/**
 * The basic chemical bomb proc.
 * Combines a set of reagent holders into one holder and reacts it.
 * If there are any reagents left over it spreads them across the surrounding environment.
 * The maximum volume of the holder is temporarily adjusted to allow for reactions which increase total volume to work at full effectiveness.
 * The maximum volume of the holder is then reset to its original value.
 *
 * Arguments:
 * - [epicenter][/turf]: The epicenter of the splash if some of the reagents aren't consumed.
 * - [holder][/datum/reagents]: The holder to combine all of the reagents into. A temporary one is created if this is null.
 * - [reactants][/list/datum/reagents]: The set of reagent holders to combine.
 * - extra_heat: Some amount to heat the combined reagents by before reacting them.
 * - threatscale: A multiplier for the reagent quantities involved.
 * - adminlog: Whether to alert the admins that this has occured.
 */
/proc/chem_splash(turf/epicenter, datum/reagents/holder = null, affected_range = 3, list/datum/reagents/reactants = list(), extra_heat = 0, threatscale = 1, adminlog = 1)
	if(!isturf(epicenter) || !reactants.len || threatscale <= 0)
		return

	var/total_reagents = holder?.total_volume
	var/maximum_reagents = holder?.maximum_volume
	for(var/datum/reagents/reactant in reactants)
		if(reactant.total_volume)
			total_reagents += reactant.total_volume
		maximum_reagents += reactant.maximum_volume

	if (total_reagents <= 0)
		return FALSE

	var/tmp_holder = null
	var/original_max_volume = null
	if (isnull(holder))
		tmp_holder = TRUE
		holder = new /datum/reagents(maximum_reagents * threatscale)
		holder.my_atom = epicenter
	else
		tmp_holder = FALSE
		original_max_volume = holder.maximum_volume
		if(threatscale < 1)
			holder.multiply(threatscale)
			holder.maximum_volume = maximum_reagents * threatscale
		else
			holder.maximum_volume = maximum_reagents * threatscale
			holder.multiply(threatscale)

	for(var/datum/reagents/reactant as anything in reactants)
		reactant.trans_to(holder, reactant.total_volume, threatscale, no_react = TRUE)

	holder.chem_temp += extra_heat // Average temperature of reagents + extra heat.
	holder.handle_reactions() // React them now.

	if(holder.total_volume)
		if(affected_range >= 0)
			spread_reagents(holder, epicenter, affected_range)
		holder.clear_reagents()

	if(tmp_holder)
		qdel(holder)
	else
		holder.maximum_volume = original_max_volume

	return TRUE


/**
 * Exposes all accessible atoms within some distance of an epicenter to some reagents.
 * Does not clear the source reagent holder; that must be done manually if it is desired.
 *
 * Arguments:
 * - [source][/datum/reagents]: The reagents to spread around.
 * - [epicenter][/atom]: The epicenter/source location of the reagent spread.
 * - spread_range: The range in which to spread the reagents. Will not go over 20
 */
/proc/spread_reagents(datum/reagents/source, atom/epicenter, spread_range)
	spread_range = min(spread_range, 20) // Fuck off with trying to do more then this
	var/datum/effect_system/steam_spread/steam = new /datum/effect_system/steam_spread()
	steam.set_up(10, 0, epicenter)
	steam.attach(epicenter)
	steam.start()

	// This is a basic floodfill algorithm of atmos connected tiles
	// Turfs will be stored in the form turf -> TRUE
	var/chem_temp = source.chem_temp
	var/hot_chem = chem_temp >= 300
	var/list/turflist = list()
	var/list/reactable = list()
	turflist[epicenter] = TRUE
	for(var/i = 1; i <= length(turflist); i++)
		var/turf/valid_step = turflist[i]
		if(get_dist(valid_step, epicenter) > spread_range) // We are over threshold, don't add anything new and just keep goin
			turflist.Cut(i, i+1)
			i--
			continue

		for(var/turf/lad as anything in valid_step.atmos_adjacent_turfs)
			if(turflist[lad])
				continue
			turflist[lad] = TRUE

		reactable += valid_step.get_all_contents() // Yes this means multitile objects double react. I don't care. skill issue
		if(hot_chem)
			valid_step.hotspot_expose(chem_temp*2, 5)

	// Remove anything we can't see
	for(var/atom/thing as anything in (dview(spread_range, epicenter) & reactable))
		var/distance = max(1, get_dist(thing, epicenter))
		var/fraction = 0.5 / (2 ** distance) //50/25/12/6... for a 200u splash, 25/12/6/3... for a 100u, 12/6/3/1 for a 50u
		source.expose(thing, TOUCH, fraction)
