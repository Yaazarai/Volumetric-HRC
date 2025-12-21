#macro INVALID_SURFACE -1

// Easy surface usage.
function surface(w, h, f) constructor { width = w; height = h; format = f; memory = INVALID_SURFACE; }
function surface_build(w, h, f, l) { var surf = new surface(w, h, f); ds_list_add(l, surf); return surf; }
function surface_rebuild(surf) { if (!surface_exists(surf.memory)) surf.memory = surface_create(surf.width, surf.height, surf.format); }
function surface_delete(surf) { if (surface_exists(surf.memory)) surface_free(surf.memory); delete surf; }
function surface_source(surf) { return surf.memory; }
function surface_update(surf, w, h, f) { surf.width = (w > 0)? w: surf.width; surf.height = (h > 0)? h : surf.height; surf.format = (f > 0)? f : surf.format; }
function surface_clear(surf) { surface_set_target(surf.memory); draw_clear_alpha(c_black, 0); surface_reset_target(); }

// Shader Functions
function texture(shd, uid) { return shader_get_sampler_index(shd, uid); }
function uniform(shd, uid) { return shader_get_uniform(shd, uid); }
function shader_texture(uid, surf) { texture_set_stage(uid, surface_get_texture(surf)); }
function shader_float(uid, f1) { shader_set_uniform_f(uid, f1); }
function shader_vec2(uid, f1, f2) { shader_set_uniform_f(uid, f1, f2); }
function shader_vec4(uid, f1, f2, f3, f4) { shader_set_uniform_f(uid, f1, f2, f3, f4); }

// Math Functions
function power_ofN(number, n) { return power(n, ceil(logn(n, number))); }
function multiple_ofN(number, n) { return (n == 0) ? number : ceil(number / n) * n; }
function geometric_ofN(number, n, p) { return (number * (1.0 - power(p, n))) / (1.0 - p); }
function log2_ofWH(w,h) { return ceil(log2(max(w,h))); }

// Color Functions
function make_color_normalized_rgb(red, green, blue) { return make_color_rgb(red * 255.0, green * 255.0, blue * 255.0); }