/obj/item/implant/freedom
	name = "freedom implant"
	desc = "Use this to escape from those evil Red Shirts."
	icon_state = "freedom"
	implant_color = "r"
	uses = FREEDOM_IMPLANT_CHARGES

/obj/item/implant/freedom/implant(mob/living/target, mob/user, silent, force)
	. = ..()
	if(!.)
		return FALSE
	if(!iscarbon(target)) //This is pretty much useless for anyone else since they can't be cuffed
		balloon_alert(user, "that would be a waste!")
		return FALSE
	return TRUE

/obj/item/implant/freedom/activate()
	. = ..()
	var/mob/living/carbon/carbon_imp_in = imp_in
	if(!can_trigger(carbon_imp_in))
		balloon_alert(carbon_imp_in, "no restraints!")
		return

	uses--
	carbon_imp_in.uncuff()
	var/obj/item/clothing/shoes/shoes = carbon_imp_in.shoes
	if(istype(shoes) && shoes.tied == SHOES_KNOTTED)
		shoes.adjust_laces(SHOES_TIED, carbon_imp_in)

	if(!uses)
		addtimer(CALLBACK(carbon_imp_in, TYPE_PROC_REF(/atom, balloon_alert), carbon_imp_in, "implant degraded!"), 1 SECONDS)
		qdel(src)
		// if being tased, removes the status on use, and detaches the electrode.

	carbon_imp_in.remove_status_effect(/datum/status_effect/tased)


/obj/item/implant/freedom/proc/can_trigger(mob/living/carbon/implanted_in)
	if(implanted_in.handcuffed || implanted_in.legcuffed)
		return TRUE

	if(implanted_in.has_status_effect(/datum/status_effect/tased))
		return TRUE

	var/obj/item/clothing/shoes/shoes = implanted_in.shoes
	if(istype(shoes) && shoes.tied == SHOES_KNOTTED)
		return TRUE

	return FALSE

/obj/item/implant/freedom/get_data()
	return "<b>Implant Specifications:</b><BR> \
		<b>Name:</b> Freedom Beacon<BR> \
		<b>Life:</b> Optimum [initial(uses)] uses<BR> \
		<b>Important Notes:</b> <font color='red'>Illegal</font><BR> \
		<HR> \
		<b>Implant Details:</b> <BR> \
		<b>Function:</b> Transmits a specialized cluster of signals to override handcuff locking \
		mechanisms. These signals will release any bindings on both the arms and legs.<BR> \
		<b>Disclaimer:</b> Heavy-duty restraints such as straightjackets are deemed \"too complex\" to release from."

/obj/item/implanter/freedom
	name = "implanter (freedom)"
	imp_type = /obj/item/implant/freedom

/obj/item/implantcase/freedom
	name = "implant case - 'Freedom'"
	desc = "A glass case containing a freedom implant."
	imp_type = /obj/item/implant/freedom
