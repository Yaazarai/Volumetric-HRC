var xx = 1024 / render_extent;
var mx = floor(mouse_x / xx);
var my = floor(mouse_y / xx);

surface_set_target(render_emissv.memory);
draw_clear_alpha(c_black, 0);
//gpu_set_blendmode(bm_add);
	
	draw_set_color($FFFFFF);
	draw_circle(mx, my, light_size, false);
	
//gpu_set_blendmode(bm_normal);
surface_reset_target();
draw_set_color(c_black);

surface_set_target(render_absorp.memory);
draw_clear_alpha(c_black, 0);
gpu_set_blendmode(bm_add);
	
	draw_set_color($FFFFFF);
	draw_circle(mx, my, light_size, false);
	
	draw_set_color($FFFFFF);
	draw_circle(floor(render_extent / 2), floor(render_extent / 2), light_size, false);
	
gpu_set_blendmode(bm_normal);
surface_reset_target();
draw_set_color(c_black);