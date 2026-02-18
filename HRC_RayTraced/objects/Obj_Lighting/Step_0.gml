light_size += (mouse_wheel_up() - mouse_wheel_down()) * 1.0;
light_size = clamp(light_size, 1, 128);