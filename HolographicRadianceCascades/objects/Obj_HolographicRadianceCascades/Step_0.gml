light_size += mouse_wheel_up() - mouse_wheel_down();
light_size = clamp(light_size, 1.0, 128.0);

if (keyboard_check_pressed(vk_space)) {
	var spr = sprite_create_from_surface(render_fluence.memory, 0, 0, render_extent, render_extent, false, false, 0, 0);
	var fname = get_save_filename("screenshot|*.png", "");
	sprite_save(spr, 0, fname);
	sprite_delete(spr);
}