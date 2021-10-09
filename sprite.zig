const std = @import("std");
const debug = std.debug;
const mem = std.mem;
const c = @cImport({
    @cInclude("sprite.h");
});

const BlitMode = union(enum) {
    generic,
    blend,
    darken,
    filter: u8,
};

// does not clip on left or right edges of surface
fn blit_sprite2_generic(surface: *c.SDL_Surface, x: c_int, y: c_int, sprite2s: c.Sprite2_array, sprite_index: c_uint, blit_mode: BlitMode) void {
    debug.assert(surface.format.*.BitsPerPixel == 8);

    const sprite_width = 12;

    const pixel_buffer_size = @intCast(usize, surface.h * surface.pitch);
    var pixels = @ptrCast([*]u8, surface.pixels)[0..pixel_buffer_size];

    // destination pixel index
    var dest_i = @intCast(isize, (y * surface.pitch) + x);
    // source sprite pixel index
    var src_i: usize = 0;

    const sprite_data_offset: u16 = @ptrCast([*]align(1) u16, sprite2s.data)[sprite_index - 1];
    // const sprite_data_offset: u16 = @ptrCast([*]u16, sprite2s.data)[sprite_index - 1];
    // const sprite_data_end: u16 = @ptrCast([*]align(1) u16, sprite2s.data)[sprite_index];
    // const sprite_data: [*]u8 = @ptrCast([*]u8, &sprite2s.data[sprite_data_offset]);
    const sprite_data: [*]u8 = @ptrCast([*]u8, &sprite2s.data[sprite_data_offset]);
    // const sprite2s_end = sprite2s.size - sprite_data_offset;
    // var sprite_data: []u8 = sprite2s.data[sprite_data_offset..sprite_data_end];

    while (sprite_data[src_i] != 0x0f) : (src_i += 1) {
        dest_i += (sprite_data[src_i] & 0x0f); // low nibble is how many "empty" pixels to skip over in the dest buffer
        var pixels_to_copy = @shrExact(sprite_data[src_i] & 0xf0, 4); // high nibble is how many pixels to copy to dest

        if (pixels_to_copy == 0) { // we're done with this row, advance by pitch
            dest_i += @intCast(isize, surface.pitch - sprite_width);
            continue;
        }
        while (pixels_to_copy > 0) : (pixels_to_copy -= 1) {
            src_i += 1;
            // If we are past the end of the dest pixel buffer, nothing more can be drawn
            if (dest_i >= pixel_buffer_size) return;
            if (dest_i >= 0) {
                // pixels[@intCast(usize, dest_i)] = sprite_data[src_i];
                const src = &sprite_data[src_i];
                var dest = &pixels[@intCast(usize, dest_i)];
                switch (blit_mode) {
                    .generic => dest.* = src.*,
                    .blend => dest.* = (((src.* & 0x0f) + (dest.* & 0x0f)) / 2) | (src.* & 0xf0),
                    .darken => dest.* = ((dest.* & 0x0f) / 2) + (dest.* & 0xf0),
                    .filter => |f| dest.* = f | (src.* & 0x0f),
                }
            }
            dest_i += 1;
        }
    }
}

export fn blit_sprite2(surface: *c.SDL_Surface, x: c_int, y: c_int, sprite2s: c.Sprite2_array, index: c_uint) void {
    blit_sprite2_generic(surface, x, y, sprite2s, index, .generic);
}
export fn blit_sprite2_blend(surface: *c.SDL_Surface, x: c_int, y: c_int, sprite2s: c.Sprite2_array, index: c_uint) void {
    blit_sprite2_generic(surface, x, y, sprite2s, index, .blend);
}
export fn blit_sprite2_darken(surface: *c.SDL_Surface, x: c_int, y: c_int, sprite2s: c.Sprite2_array, index: c_uint) void {
    blit_sprite2_generic(surface, x, y, sprite2s, index, .darken);
}
export fn blit_sprite2_filter(surface: *c.SDL_Surface, x: c_int, y: c_int, sprite2s: c.Sprite2_array, index: c_uint, filter: u8) void {
    blit_sprite2_generic(surface, x, y, sprite2s, index, .{ .filter = filter });
}

// fn copyPixel(src: *u8, dest: *u8, filter: ?u8) void {
//     _ = filter;
//     dest.* = src.*;
// }
// fn copyPixelBlend(src: *u8, dest: *u8, filter: ?u8) void {
//     _ = filter;
//     dest.* = (((src.* & 0x0f) + (dest.* & 0x0f)) / 2) | (src.* & 0xf0);
// }
// fn copyPixelDarken(src: *u8, dest: *u8, filter: ?u8) void {
//     _ = filter;
//     _ = src;
//     dest.* = ((dest.* & 0x0f) / 2) + (dest.* & 0xf0);
// }
// fn copyPixelFilter(src: *u8, dest: *u8, filter: ?u8) void {
//     _ = src;
//     dest.* = filter.? | (src.* & 0x0f);
// }
