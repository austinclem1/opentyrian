const std = @import("std");
const debug = std.debug;
const fs = std.fs;
const mem = std.mem;

const c = @import("sprite.h");

const Allocator = mem.Allocator;
const File = fs.File;

pub fn JE_loadMainShapeTables(shpfile: [:0]const u8) void {
    const SHP_NUM: usize = 12;

    const data_dir: Dir = fs.openDir(c.data_dir(), .{});
    defer data_dir.close();
    const f: File = data_dir.openFile(shpfile, .{});
    defer f.close();
    // FILE *f = dir_fopen_die(data_dir(), shpfile, "rb");

    // JE_word shpNumb;
    // JE_longint shpPos[SHP_NUM + 1]; // +1 for storing file length

    // fread_u16_die(&shpNumb, 1, f);
    // assert(shpNumb + 1u == COUNTOF(shpPos));

    // fread_s32_die(shpPos, shpNumb, f);

    var shpNumb: u16 = f.readInt(u16, .little);
    debug.assert((shpNumb + 1) == shpPos.len);
    var shpPos: [SHP_NUM + 1]u32 = undefined; // +1 for storing file length
    {
        var i: usize = 0;
        while (i < shpNumb) : (i += 1) {
            shpPos[i] = f.readInt(u32, .little);
        }
    }
    shpPos[shpNumb + 1] = f.getEndPos();

    // fseek(f, 0, SEEK_END);
    // for (unsigned int i = shpNumb; i < COUNTOF(shpPos); ++i)
    // 	shpPos[i] = ftell(f);

    // int i;
    // fonts, interface, option sprites
    // for (i = 0; i < 7; i++)
    // {
    // 	fseek(f, shpPos[i], SEEK_SET);
    // 	load_sprites(i, f);
    // }
    var posIndex: usize = 0;
    while (posIndex < 7) : (posIndex += 1) {
        f.seekTo(shpPos[posIndex]);
        load_sprites(posIndex, f);
    }

    // player shot sprites

    shapesC1.size = shpPos[posIndex + 1] - shpPos[posIndex];
    JE_loadCompShapesB(&shapesC1, f);
    posIndex += 1;

    // player ship sprites
    shapes9.size = shpPos[posIndex + 1] - shpPos[posIndex];
    JE_loadCompShapesB(&shapes9, f);
    posIndex += 1;

    // power-up sprites
    eShapes[5].size = shpPos[posIndex + 1] - shpPos[posIndex];
    JE_loadCompShapesB(&eShapes[5], f);
    posIndex += 1;

    // coins, datacubes, etc sprites
    eShapes[4].size = shpPos[posIndex + 1] - shpPos[posIndex];
    JE_loadCompShapesB(&eShapes[4], f);
    posIndex += 1;

    // more player shot sprites
    shapesW2.size = shpPos[posIndex + 1] - shpPos[posIndex];
    JE_loadCompShapesB(&shapesW2, f);
}

fn JE_loadCompShapesB(allocator: *Allocator, sprite2s: *Sprite2_array, f: File) void {
    free_sprite2s(allocator, sprite2s);

    // sprite2s->data = malloc(sprite2s->size);
    // fread_u8_die(sprite2s->data, sprite2s->size, f);
    sprite2s.data = f.readAllAlloc(allocator, sprite2s.size);
}

fn free_sprite2s(allocator: *Allocator, sprite2s: *Sprite2_array) void {
    allocator.free(sprite2s.data);
    sprite2s.data = null;
}

fn load_sprites(allocator: *Allocator, table: usize, f: File) void {
    free_sprites(allocator, table);

    sprite_table[table].count = f.readInt(u16, .little);

    debug.assert(sprite_table[table].count <= SPRITES_PER_TABLE_MAX);

    // for (unsigned int i = 0; i < sprite_table[table].count; ++i)
    // {
    // 	Sprite * const cur_sprite = sprite(table, i);

    // 	bool populated;
    // 	fread_bool_die(&populated, f);
    // 	if (!populated) // sprite is empty
    // 		continue;

    // 	fread_u16_die(&cur_sprite->width,  1, f);
    // 	fread_u16_die(&cur_sprite->height, 1, f);
    // 	fread_u16_die(&cur_sprite->size,   1, f);

    // 	cur_sprite->data = malloc(cur_sprite->size);

    // 	fread_u8_die(cur_sprite->data, cur_sprite->size, f);
    // }
    {
        var i: usize = 0;
        while (i < sprite_table[table].count) : (i += 1) {
            const cur_sprite: *Sprite = sprite(table, i);

            const populated: bool = f.readVarInt(u1, .little);
            if (!populated) continue;

            cur_sprite.width = f.readInt(u16, .little);
            cur_sprite.height = f.readInt(u16, .little);
            cur_sprite.size = f.readInt(u16, .little);

            cur_sprite.data = f.readAllAlloc(allocator, cur_sprite.size);
        }
    }
}
