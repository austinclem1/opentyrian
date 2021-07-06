const std = @import("std");
const debug = std.debug;
const mem = std.mem;
const c = @cImport({
    @cInclude("sprite.h");
});

// does not clip on left or right edges of surface
fn blit_sprite2_generic(surface: *c.SDL_Surface, x: c_int, y: c_int, sprite2s: c.Sprite2_array, index: c_uint, copyFunc: fn (*u8, *u8, ?u8) void, filter: ?u8) void {
    debug.assert(surface.format.*.BitsPerPixel == 8);

    const sprite_width = 12;

    const pixel_buffer_size = @intCast(usize, surface.h * surface.pitch);
    var pixels = @ptrCast([*]u8, surface.pixels)[0..pixel_buffer_size];

    var d_index = @intCast(isize, (y * surface.pitch) + x); // destination pixel index

    // const Uint8 *data = sprite2s.data + SDL_SwapLE16(((Uint16 *)sprite2s.data)[index - 1]);
    const sprite_data_offset: u16 = @ptrCast([*]align(1) u16, sprite2s.data)[index - 1];
    // const sprite2s_end = sprite2s.size - sprite_data_offset;
    // var sprite_data: []u8 = sprite2s.data[sprite_data_offset..sprite2s_end];
    var sprite_data: [*]u8 = @ptrCast([*]u8, &sprite2s.data[sprite_data_offset]);
    var s_index: usize = 0; // source sprite pixel index

    while (sprite_data[s_index] != 0x0f) : (s_index += 1) {
        d_index += (sprite_data[s_index] & 0x0f); // low nibble is how many empty pixels to "draw"
        var pixels_to_write = @shrExact(sprite_data[s_index] & 0xf0, 4); // high nibble is how many pixels to copy to dest

        if (pixels_to_write == 0) { // we're done with this row, advance by pitch
            d_index += @intCast(isize, surface.pitch - sprite_width);
            continue;
        }
        while (pixels_to_write > 0) : (pixels_to_write -= 1) {
            s_index += 1;
            if (d_index >= pixel_buffer_size) return;
            if (d_index >= 0) {
                // pixels[@intCast(usize, d_index)] = sprite_data[s_index];
                if (filter) |f| {
                    copyFunc(&sprite_data[s_index], &pixels[@intCast(usize, d_index)], f);
                } else {
                    copyFunc(&sprite_data[s_index], &pixels[@intCast(usize, d_index)], null);
                }
            }
            d_index += 1;
        }
    }
}

export fn blit_sprite2(surface: *c.SDL_Surface, x: c_int, y: c_int, sprite2s: c.Sprite2_array, index: c_uint) void {
    blit_sprite2_generic(surface, x, y, sprite2s, index, copyPixel, null);
}
export fn blit_sprite2_blend(surface: *c.SDL_Surface, x: c_int, y: c_int, sprite2s: c.Sprite2_array, index: c_uint) void {
    blit_sprite2_generic(surface, x, y, sprite2s, index, copyPixelBlend, null);
}
export fn blit_sprite2_darken(surface: *c.SDL_Surface, x: c_int, y: c_int, sprite2s: c.Sprite2_array, index: c_uint) void {
    blit_sprite2_generic(surface, x, y, sprite2s, index, copyPixelDarken, null);
}
export fn blit_sprite2_filter(surface: *c.SDL_Surface, x: c_int, y: c_int, sprite2s: c.Sprite2_array, index: c_uint, filter: u8) void {
    blit_sprite2_generic(surface, x, y, sprite2s, index, copyPixelFilter, filter);
}

fn copyPixel(src: *u8, dest: *u8, filter: ?u8) void {
    _ = filter;
    dest.* = src.*;
}
fn copyPixelBlend(src: *u8, dest: *u8, filter: ?u8) void {
    _ = filter;
    dest.* = (((src.* & 0x0f) + (dest.* & 0x0f)) / 2) | (src.* & 0xf0);
}
fn copyPixelDarken(src: *u8, dest: *u8, filter: ?u8) void {
    _ = filter;
    _ = src;
    dest.* = ((dest.* & 0x0f) / 2) + (dest.* & 0xf0);
}
fn copyPixelFilter(src: *u8, dest: *u8, filter: ?u8) void {
    _ = src;
    dest.* = filter.? | (src.* & 0x0f);
}
