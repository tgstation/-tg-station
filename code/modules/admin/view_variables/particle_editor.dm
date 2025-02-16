/datum/particle_editor
	/// movable whose particles we want to be editing
	var/atom/movable/target

/datum/particle_editor/New(atom/target)
	src.target = target

/datum/particle_editor/ui_state(mob/user)
	return ADMIN_STATE(R_VAREDIT)

/datum/particle_editor/ui_interact(mob/user, datum/tgui/ui)
	ui = SStgui.try_update_ui(user, src, ui)
	if(!ui)
		ui = new(user, src, "ParticleEdit")
		ui.open()

/datum/particle_editor/ui_assets(mob/user)
	. = ..()
	. += get_asset_datum(/datum/asset/simple/particle_editor)

///returns ui_data values for the particle editor
/particles/proc/return_ui_representation(mob/user)
	var/data = list()
	//affect entire set: no generators
	data["width"] = width //float
	data["height"] = height //float
	data["count"] = count //float
	data["spawning"] = spawning //float
	data["bound1"] = islist(bound1) ? bound1 : list(bound1,bound1,bound1) //float OR list(x, y, z)
	data["bound2"] = islist(bound2) ? bound2 : list(bound2,bound2,bound2) //float OR list(x, y, z)
	data["gravity"] = gravity //list(x, y, z)
	data["gradient"] = gradient //gradient array list(number, string, number, string, "loop", "space"=COLORSPACE_RGB)
	data["transform"] = transform //list(a, b, c, d, e, f) OR list(xx,xy,xz, yx,yy,yz, zx,zy,zz) OR list(xx,xy,xz, yx,yy,yz, zx,zy,zz, cx,cy,cz) OR list(xx,xy,xz,xw, yx,yy,yz,yw, zx,zy,zz,zw, wx,wy,wz,ww)

	//applied on spawn
	if(islist(icon))
		var/list/icon_data = list()
		for(var/file in icon)
			icon_data["[file]"] = icon[file]
		data["icon"] = icon_data
	else
		data["icon"] = "[icon]"  //list(icon = weight) OR file reference
	data["icon_state"] = icon_state // list(icon_state = weight) OR string
	if(isgenerator(lifespan))
		data["lifespan"] = return_generator_args(lifespan)
	else
		data["lifespan"] = lifespan //float
	if(isgenerator(fade))
		data["fade"] = return_generator_args(fade)
	else
		data["fade"] = fade //float
	if(isgenerator(fadein))
		data["fadein"] = return_generator_args(fadein)
	else
		data["fadein"] = fadein //float
	if(isgenerator(color))
		data["color"] = return_generator_args(color)
	else
		data["color"] = color //float OR string
	if(isgenerator(color_change))
		data["color_change"] = return_generator_args(color_change)
	else
		data["color_change"] = color_change //float
	if(isgenerator(position))
		data["position"] = return_generator_args(position)
	else
		data["position"] = position //list(x,y) OR list(x,y,z)
	if(isgenerator(velocity))
		data["velocity"] = return_generator_args(velocity)
	else
		data["velocity"] = velocity //list(x,y) OR list(x,y,z)
	if(isgenerator(scale))
		data["scale"] = return_generator_args(scale)
	else
		data["scale"] = scale
	if(isgenerator(grow))
		data["grow"] = return_generator_args(grow)
	else
		data["grow"] = grow //float OR list(x,y)
	if(isgenerator(rotation))
		data["rotation"] = return_generator_args(rotation)
	else
		data["rotation"] = rotation
	if(isgenerator(spin))
		data["spin"] = return_generator_args(spin)
	else
		data["spin"] = spin //float
	if(isgenerator(friction))
		data["friction"] = return_generator_args(friction)
	else
		data["friction"] = friction //float: 0-1

	//evaluated every tick
	if(isgenerator(drift))
		data["drift"] = return_generator_args(drift)
	else
		data["drift"] = drift
	return data

/datum/particle_editor/ui_data(mob/user)
	var/list/data = list()
	data["target_name"] = target.name
	if(!target.particles)
		target.particles = new /particles
	data["particle_data"] = target.particles.return_ui_representation(user)
	return data

/datum/particle_editor/ui_act(action, list/params, datum/tgui/ui, datum/ui_state/state)
	. = ..()
	if(.)
		return

	switch(action)
		if("delete_and_close")
			ui.close()
			target.particles = null
			target = null
			. = FALSE
		if("new_type")
			var/new_type = pick_closest_path(/particles, make_types_fancy(typesof(/particles)))
			if(!new_type)
				return FALSE
			target.particles = new new_type
			target.particles.datum_flags |= DF_VAR_EDITED
			. = TRUE
		if("transform_size")
			var/list/values = list("Simple Matrix" = 6, "Complex Matrix" = 12, "Projection Matrix" = 16)
			var/new_size = values[params["new_value"]]
			if(!new_size)
				return FALSE
			. = TRUE
			target.particles.datum_flags |= DF_VAR_EDITED
			if(!target.particles.transform)
				target.particles.transform = new /list(new_size)
				return
			var/size = length(target.particles.transform)
			if(size < new_size)
				target.particles.transform += new /list(new_size-size)
				return
			//transform is not cast as a list
			var/list/holder =  target.particles.transform
			holder.Cut(new_size)
		if("edit")
			var/particles/owner = target.particles
			var/param_var_name = params["var"]
			if(!(param_var_name in owner.vars))
				return FALSE
			var/var_value = params["new_value"]
			var/var_mod = params["var_mod"]
			// we can only return arrays from tgui so lets convert it to something usable if needed
			switch(var_mod)
				if(P_DATA_GENERATOR)
					//these MUST be vectors and the others MUST be floats
					if(var_value[1] in list(GEN_VECTOR, GEN_BOX))
						if(!islist(var_value[2]))
							var_value[2] = list(var_value[2],var_value[2],var_value[2])
						if(!islist(var_value[3]))
							var_value[3] = list(var_value[3],var_value[3],var_value[3])
					//this means we just switched off a vector-requiring generator type
					else if(islist(var_value[2]) && islist(var_value[3]))
						var_value[2] = var_value[1]
						var_value[3] = var_value[1]
					var_value = generator(arglist(var_value))
				if(P_DATA_ICON_ADD)
					var_value = input("Pick icon:", "Icon") as null|icon
					if(!var_value)
						return FALSE
					var/list/new_values = list()
					new_values += var_value
					new_values[var_value] = 1
					if(isicon(owner.icon))
						new_values[owner.icon] = 1
						owner.icon = new_values
					else if(islist(owner.icon))
						owner.icon[var_value] = 1
					else
						owner.icon = new_values
					target.particles.datum_flags |= DF_VAR_EDITED
					return TRUE
				if(P_DATA_ICON_REMOVE)
					for(var/file in owner.icon)
						if("[file]" == var_value)
							owner.icon -= file
					UNSETEMPTY(owner.icon)
					target.particles.datum_flags |= DF_VAR_EDITED
					return TRUE
				if(P_DATA_ICON_WEIGHT)
					// [filename, new_weight]
					var/list/mod_data = var_value
					for(var/file in owner.icon)
						if("[file]" == mod_data[1])
							owner.icon[file] = mod_data[2]
					target.particles.datum_flags |= DF_VAR_EDITED
					return TRUE

			owner.vars[param_var_name] = var_value
			target.particles.datum_flags |= DF_VAR_EDITED
			return TRUE

