var xx = 1024 / render_extent;
var cx = floor(render_extent * 0.5) - 0.5;//floor(mouse_x / xx);
var cy = floor(render_extent * 0.5) - 0.5;//floor(mouse_y / xx);
var mx = floor(mouse_x / xx);
var my = floor(mouse_y / xx);

surface_set_target(render_emissv.memory);
draw_clear_alpha(c_black, 0);
	
	draw_sprite_ext(Spr_TestEmission, 0, 0, 0, 1, 1, 0, c_white, 1);
	
	draw_set_color($FFFFFF);
	draw_circle(mx, my, light_size, false);
	
	draw_set_color($000000);
	//draw_circle(cx, cy, light_size*4, false);
	//draw_circle(mx, my, light_size*4, false);
	
surface_reset_target();
draw_set_color(c_black);

surface_set_target(render_absorp.memory);
draw_clear_alpha(c_black, 0);
gpu_set_blendmode(bm_add);
	
	draw_sprite_ext(Spr_TestAbsorption, 0, 0, 0, 1, 1, 0, c_white, 1);
	
	draw_set_color($FFFFFF);
	draw_circle(mx, my, light_size, false);
	
	draw_set_color($FFFFFF);
	//draw_circle(cx, cy, light_size*4, false);
	//draw_circle(mx, my, light_size*4, false);
	
gpu_set_blendmode(bm_normal);
surface_reset_target();
draw_set_color(c_black);