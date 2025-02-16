/***************************************************************
** Design Datums   **
** All the data for building stuff.   **
***************************************************************/
/*
For the materials datum, it assumes you need reagents unless specified otherwise. To designate a material that isn't a reagent,
you use one of the material IDs below. These are NOT ids in the usual sense (they aren't defined in the object or part of a datum),
they are simply references used as part of a "has materials?" type proc. They all start with a $ to denote that they aren't reagents.
The currently supporting non-reagent materials. All material amounts are set as the define SHEET_MATERIAL_AMOUNT, which defaults to 100

Don't add new keyword/IDs if they are made from an existing one (such as rods which are made from iron). Only add raw materials.

Design Guidelines
- When adding new designs, check rdreadme.dm to see what kind of things have already been made and where new stuff is needed.
- A single sheet of anything is 100 units of material. Materials besides iron/glass require help from other jobs (mining for
other types of metals and chemistry for reagents).
- Add the AUTOLATHE tag to
*/

//DESIGNS ARE GLOBAL. DO NOT CREATE OR DESTROY THEM AT RUNTIME OUTSIDE OF INIT, JUST REFERENCE THEM TO WHATEVER YOU'RE DOING! //why are you yelling?
//DO NOT REFERENCE OUTSIDE OF SSRESEARCH. USE THE PROCS IN SSRESEARCH TO OBTAIN A REFERENCE.

/datum/design //Datum for object designs, used in construction
	/// Name of the created object
	var/name = "Name"
	/// Description of the created object
	var/desc = null
	/// The ID of the design. Used for quick reference. Alphanumeric, lower-case, no symbols
	var/id = DESIGN_ID_IGNORE
	/// Bitflags indicating what machines this design is compatable with. ([IMPRINTER]|[AWAY_IMPRINTER]|[PROTOLATHE]|[AWAY_LATHE]|[AUTOLATHE]|[MECHFAB]|[BIOGENERATOR]|[LIMBGROWER]|[SMELTER])
	var/build_type = null
	/// List of materials required to create one unit of the product. Format is (typepath or caregory) -> amount
	var/list/materials = list()
	/// The amount of time required to create one unit of the product.
	var/construction_time = 3.2 SECONDS
	/// The typepath of the object produced by this design
	var/build_path = null
	/// Reagent produced by this design. Currently only supported by the biogenerator.
	var/make_reagent
	/// What categories this design falls under. Used for sorting in production machines.
	var/list/category = list()
	/// List of reagents required to create one unit of the product. Currently only supported by the limb grower.
	var/list/reagents_list = list()
	/// How many times faster than normal is this to build on the protolathe
	var/lathe_time_factor = 1
	/// Bitflags indicating what departmental lathes should be allowed to process this design.
	var/departmental_flags = ALL
	/// What techwebs nodes unlock this design. Constructed by SSresearch
	var/list/datum/techweb_node/unlocked_by = list()
	/// Override for the automatic icon generation used for the research console.
	var/research_icon
	/// Override for the automatic icon state generation used for the research console.
	var/research_icon_state
	/// Appears to be unused.
	var/icon_cache
	/// Optional string that interfaces can use as part of search filters. See- item/borg/upgrade/ai and the Exosuit Fabs.
	var/search_metadata
	/// For protolathe designs that don't require reagents: If they can be exported to autolathes with a design disk or not.
	var/autolathe_exportable = TRUE

/datum/design/error_design
	name = "ERROR"
	desc = "This usually means something in the database has corrupted. If this doesn't go away automatically, inform Central Command so their techs can fix this ASAP(tm)"

/datum/design/Destroy()
	SSresearch.techweb_designs -= id
	return ..()

/datum/design/proc/InitializeMaterials()
	var/list/temp_list = list()
	for(var/i in materials) //Go through all of our materials, get the subsystem instance, and then replace the list.
		var/amount = materials[i]
		if(!istext(i)) //Not a category, so get the ref the normal way
			var/datum/material/M = GET_MATERIAL_REF(i)
			temp_list[M] = amount
		else
			temp_list[i] = amount
	materials = temp_list

/datum/design/proc/icon_html(client/user)
	var/datum/asset/spritesheet_batched/sheet = get_asset_datum(/datum/asset/spritesheet_batched/research_designs)
	sheet.send(user)
	return sheet.icon_tag(id)

/// Returns the description of the design
/datum/design/proc/get_description()
	var/obj/object_build_item_path = build_path

	return isnull(desc) ? initial(object_build_item_path.desc) : desc


////////////////////////////////////////
//Disks for transporting design datums//
////////////////////////////////////////

/obj/item/disk/design_disk
	name = "Component Design Disk"
	desc = "A disk for storing device design data for construction in lathes."
	icon_state = "datadisk1"
	custom_materials = list(/datum/material/iron =SMALL_MATERIAL_AMOUNT * 3, /datum/material/glass =SMALL_MATERIAL_AMOUNT)

	///List of all `/datum/design` stored on the disk.
	var/list/blueprints = list()

/obj/item/disk/design_disk/Initialize(mapload)
	. = ..()
	if(mapload)
		pixel_x = base_pixel_x + rand(-5, 5)
		pixel_y = base_pixel_y + rand(-5, 5)

/**
 * Used for special interactions with a techweb when uploading the designs.
 * Args:
 * - stored_research - The techweb that's storing us.
 */
/obj/item/disk/design_disk/proc/on_upload(datum/techweb/stored_research, atom/research_source)
	return

/obj/item/disk/design_disk/bepis
	name = "Old experimental technology disk"
	desc = "A disk containing some long-forgotten technology from a past age. You hope it still works after all these years. Upload the disk to an R&D Console to redeem the tech."
	icon_state = "rndmajordisk"

	///The bepis node we have the design id's of
	var/datum/techweb_node/bepis_node

/obj/item/disk/design_disk/bepis/Initialize(mapload)
	. = ..()
	var/bepis_id = pick(SSresearch.techweb_nodes_experimental)
	bepis_node = (SSresearch.techweb_node_by_id(bepis_id))

	for(var/entry in bepis_node.design_ids)
		var/datum/design/new_entry = SSresearch.techweb_design_by_id(entry)
		blueprints += new_entry

///Unhide and research our node so we show up in the R&D console.
/obj/item/disk/design_disk/bepis/on_upload(datum/techweb/stored_research, atom/research_source)
	stored_research.hidden_nodes -= bepis_node.id
	stored_research.research_node(bepis_node, force = TRUE, auto_adjust_cost = FALSE, research_source = research_source)

/**
 * Subtype of Bepis tech disk
 * Removes the tech disk that's held on it from the experimental node list, making them not show up in future disks.
 */
/obj/item/disk/design_disk/bepis/remove_tech
	name = "Reformatted technology disk"
	desc = "A disk containing a new, completed tech from the B.E.P.I.S. Upload the disk to an R&D Console to redeem the tech."

/obj/item/disk/design_disk/bepis/remove_tech/Initialize(mapload)
	. = ..()
	SSresearch.techweb_nodes_experimental -= bepis_node.id
	log_research("[bepis_node.display_name] has been removed from experimental nodes through the BEPIS techweb's \"remove tech\" feature.")

