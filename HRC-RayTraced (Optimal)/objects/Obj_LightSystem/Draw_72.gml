var xx = 1024 / render_expanses;
var cx = floor(render_expanses * 0.5) - 0.5;//floor(mouse_x / xx);
var cy = floor(render_expanses * 0.5) - 0.5;//floor(mouse_y / xx);
var mx = floor(mouse_x / xx);
var my = floor(mouse_y / xx);
xx = render_expanses / 1024;

surface_set_target(surface_source(render_emissivity));
draw_clear_alpha(c_black, 0);
	
	//draw_sprite_ext(Spr_Emission, 0, 0, 0, xx, xx, 0, c_white, 1);
	
	draw_set_color($FFFFFF);
	draw_circle(mx, my, 4, false);
	//draw_circle_color(mx, my, 8, c_white, c_gray, false);
	
	//draw_set_color($000000);
	//draw_circle(cx, cy, light_size*4, false);
	//draw_circle(mx, my, light_size*4, false);
	
surface_reset_target();
draw_set_color(c_black);

surface_set_target(surface_source(render_absorption));
draw_clear_alpha(c_black, 0);
gpu_set_blendmode(bm_add);
	
	//draw_sprite_ext(Spr_Absorption, 0, 0, 0, xx, xx, 0, c_white, 1);
	
	draw_set_color($FFFFFF);
	draw_circle(mx, my, 4, false);
	
	//draw_set_color($FFFFFF);
	//draw_circle(cx, cy, 16, false);
	//draw_circle(mx, my, light_size*4, false);
	
gpu_set_blendmode(bm_normal);
surface_reset_target();
draw_set_color(c_black);