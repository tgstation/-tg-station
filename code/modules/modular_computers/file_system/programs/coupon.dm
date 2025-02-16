#define COUPON_PAPER_USE 1
#define COUPON_TONER_USE 0.250

///A program that enables the user to redeem randomly generated coupons for several cargo packs (mostly goodies).
/datum/computer_file/program/coupon
	filename = "couponmaster"
	filedesc = "Coupon Master"
	downloader_category = PROGRAM_CATEGORY_SUPPLY
	extended_desc = "Program for receiving discounts for several cargo goodies. After redeeming a coupon, hit a photocopier with your PDA to print it."
	program_flags = PROGRAM_ON_NTNET_STORE | PROGRAM_REQUIRES_NTNET
	size = 5
	tgui_id = "NtosCouponMaster"
	program_icon = "ticket"
	can_run_on_flags = PROGRAM_PDA //It relies on the PDA messenger to let you know of new codes
	detomatix_resistance = DETOMATIX_RESIST_MALUS

/datum/computer_file/program/coupon/on_install()
	. = ..()
	///set the discount_coupons list, which means SSmodular_computers will now begin to periodically produce new coupon codes.
	LAZYINITLIST(SSmodular_computers.discount_coupons)
	ADD_TRAIT(computer, TRAIT_MODPC_HALVED_DOWNLOAD_SPEED, REF(src)) //All that glitters is not gold

/datum/computer_file/program/coupon/Destroy()
	if(computer)
		REMOVE_TRAIT(computer, TRAIT_MODPC_HALVED_DOWNLOAD_SPEED, REF(src))
	return ..()

/datum/computer_file/program/coupon/ui_data(mob/user)
	var/list/data = list()
	data["printed_coupons"] = list()
	data["redeemed_coupons"] = list()
	data["valid_id"] = FALSE
	var/obj/item/card/id/user_id = computer.computer_id_slot
	if(user_id?.registered_account.add_to_accounts)
		for(var/datum/coupon_code/coupon as anything in user_id.registered_account.redeemed_coupons)
			var/list/coupon_data = list(
				"goody" = initial(coupon.discounted_pack.name),
				"discount" = coupon.discount*100,
			)
			if(coupon.printed)
				data["printed_coupons"] += list(coupon_data)
			else
				data["redeemed_coupons"] += list(coupon_data)
		data["valid_id"] = TRUE
	return data

/datum/computer_file/program/coupon/ui_act(action, params, datum/tgui/ui, datum/ui_state/state)
	. = ..()
	var/obj/item/card/id/user_id = computer.computer_id_slot
	if(!(user_id?.registered_account.add_to_accounts))
		return TRUE
	switch(action)
		if("redeem")
			var/code = params["code"]
			if(!length(code))
				return TRUE
			var/datum/coupon_code/coupon = SSmodular_computers.discount_coupons[code]
			if(isnull(coupon))
				user_id.registered_account.bank_card_talk("Invalid coupon code.", TRUE)
				return TRUE
			if(coupon.expires_in && coupon.expires_in < world.time)
				user_id.registered_account.bank_card_talk("Expired coupon code.", TRUE)
				return TRUE
			if(coupon in user_id.registered_account.redeemed_coupons)
				user_id.registered_account.bank_card_talk("Coupon [code] already redeemed.", TRUE)
				return TRUE
			coupon.copy(user_id.registered_account)
			var/static/list/goodbye = list(
				"Have a wonderful day.",
				"Don't forget to print it.",
				"Time to get shopping!",
				"Enjoy your discount!",
				"Congratulations!",
				"Bye Bye~.",
			)
			user_id.registered_account.bank_card_talk("Coupon [code] redeemed. [pick(goodbye)]", TRUE)
			//Well, guess you're redeeming something else too.
			if(prob(40) && computer.used_capacity < computer.max_capacity)
				var/datum/computer_file/warez = new()
				warez.filename = random_string(rand(6, 12), GLOB.alphabet + GLOB.alphabet_upper + GLOB.numerals)
				warez.filetype = pick("DAT", "XXX", "TMP", "FILE", "MNT", "MINER", "SYS", "PNG.EXE")
				warez.size = min(rand(1, 4), computer.max_capacity - computer.used_capacity)
				if(prob(25))
					warez.undeletable = TRUE
				computer.store_file(warez)

/**
 * Normally, modular PCs can be print paper already, but I find this additional step
 * to be less lazy and fitting to the "I gotta go print it before it expires" aspect of it.
 */
/datum/computer_file/program/coupon/tap(atom/tapped_atom, mob/living/user, list/modifiers)
	if(!istype(tapped_atom, /obj/machinery/photocopier))
		return FALSE
	var/obj/item/card/id/user_id = computer.computer_id_slot
	if(!(user_id?.registered_account))
		computer.balloon_alert(user, "no bank account found!")
		return TRUE
	var/obj/machinery/photocopier/copier = tapped_atom
	if(copier.check_busy(user))
		return TRUE
	var/num_coupons = 0
	for(var/datum/coupon_code/coupon as anything in user_id.registered_account.redeemed_coupons)
		if(!coupon.printed)
			num_coupons++
	if(!num_coupons)
		computer.balloon_alert(user, "no coupon available!")
		return TRUE
	copier.do_copies(CALLBACK(src, PROC_REF(print_coupon), user_id.registered_account), user, COUPON_PAPER_USE, COUPON_TONER_USE, num_coupons)
	return TRUE

/datum/computer_file/program/coupon/proc/print_coupon(datum/bank_account/account)
	var/datum/coupon_code/coupon
	for(var/datum/coupon_code/possible_coupon as anything in account.redeemed_coupons)
		if(!possible_coupon.printed)
			coupon = possible_coupon
			break
	return coupon?.generate()

#undef COUPON_PAPER_USE
#undef COUPON_TONER_USE
