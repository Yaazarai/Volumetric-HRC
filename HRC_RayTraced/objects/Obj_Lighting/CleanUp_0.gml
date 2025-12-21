for(var i = 0; i < ds_list_size(render_surflist); i++)
	surface_delete(ds_list_find_value(render_surflist, i));

ds_list_destroy(render_surflist);