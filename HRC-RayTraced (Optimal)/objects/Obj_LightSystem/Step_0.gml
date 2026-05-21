render_index += keyboard_check_pressed(vk_right) - keyboard_check_pressed(vk_left);
render_index = clamp(render_index, 0, render_cascades - 1);