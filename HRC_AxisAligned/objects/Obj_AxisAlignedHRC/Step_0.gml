scalar += (mouse_wheel_up() - mouse_wheel_down()) * 1.0;
scalar = clamp(scalar, 1.0, 128);

//light_size += (mouse_wheel_up() - mouse_wheel_down()) * 2.0;
//light_size = clamp(light_size, 2.0, 128);

render_index += (keyboard_check_pressed(vk_right) - keyboard_check_pressed(vk_left)) * 1.0;
render_index = clamp(render_index, 0, render_count - 1);