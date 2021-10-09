const std = @import("std");
const builtin = std.builtin;
const mem = std.mem;
const fs = std.fs;
const math = std.math;

const File = fs.File;

const native_endian = std.Target.current.cpu.arch.endian();

const c = @cImport({
    @cInclude("episodes.h");
    @cInclude("file.h");
    @cInclude("lvllib.h");
});

// Main Weapons Data
// extern var weapons: [c.WEAP_NUM + 1]c.JE_WeaponType;
// extern var weaponPort: c.JE_WeaponPortType;

// Items
// extern var powerSys: c.JE_PowerType;
// extern var ships: c.JE_ShipType;
// extern var options: [c.OPTION_NUM + 1]c.JE_OptionType;
// extern var shields: c.JE_ShieldType;
// extern var special: c.JE_SpecialType;

// Enemy data
// extern var enemyDat: c.JE_EnemyDatType;

// EPISODE variables */
// const initial_episode_num: c.JE_byte = undefined;
// extern var episodeNum: c.JE_byte;
// const episodeAvail = [EPISODE_MAX]JE_boolean{}; //* [1..episodemax] */
// const episode_file = [13]char{};
// const cube_file = [13]char{};

// extern var episode1DataLoc: c.JE_longint;

// extern const lvlPos: c.JE_LvlPosType;
// extern var levelFile: [:0]u8;
// extern const lvlNum: c.JE_word;

export fn JE_loadItemDat() void {
    // fn JE_loadItemDat() callconv(.C) void {
    // var weapons2 = @extern([*]c.JE_WeaponType, .{ .name = "weapons" })[0 .. c.WEAP_NUM + 1];
    var weapons2 = @extern(*[c.WEAP_NUM + 1]c.JE_WeaponType, .{ .name = "weapons" })[0..];
    // std.io.getStdOut().writer().print("{s}\n", .{@typeInfo(@TypeOf(weapons2))}) catch unreachable;
    std.io.getStdOut().writer().print("{s}\n", .{@TypeOf(c.weapons)}) catch unreachable;
    // std.io.getStdOut().writer().print("{s}\n", .{@TypeOf(c.levelFile[0..])}) catch unreachable;
    // std.io.getStdOut().writer().print("{s}\n", .{@TypeOf(mem.span(c.levelFile[0..]))}) catch unreachable;
    // std.io.getStdOut().writer().print("{s}\n", .{@TypeOf(mem.span(&c.levelFile))}) catch unreachable;
    // Tells the game whether the level currently loaded is a bonus level. */
    // const bonusLevel: c.JE_boolean = undefined;

    // Tells if the game jumped back to Episode 1 */
    // const jumpBackToEpisode1: c.JE_boolean = undefined;

    var f: File = undefined;

    var data_dir = fs.openDirAbsoluteZ(c.data_dir(), .{}) catch unreachable;
    defer data_dir.close();
    if (c.episodeNum <= 3) {
        f = data_dir.openFile("tyrian.hdt", .{}) catch unreachable;
        c.episode1DataLoc = f.reader().readInt(i32, .Little) catch unreachable;
        f.seekTo(@intCast(usize, c.episode1DataLoc)) catch unreachable;
    } else {
        // episode 4 stores item data in the level file
        f = data_dir.openFileZ(@ptrCast([*:0]const u8, &c.levelFile), .{}) catch unreachable;
        f.seekTo(@intCast(usize, c.lvlPos[c.lvlNum - 1])) catch unreachable;
    }

    defer f.close();

    var itemNum = [_]c.JE_word{undefined} ** 7; //* [1..7] */
    readIntMultiple(f, u16, itemNum[0..7], .Little) catch unreachable;

    {
        var i: usize = 0;
        while (i < c.weapons.len) : (i += 1) {
            weapons2[i].drain = f.reader().readInt(u16, .Little) catch unreachable;
            weapons2[i].shotrepeat = f.reader().readInt(u8, .Little) catch unreachable;
            c.weapons[i].multi = f.reader().readInt(u8, .Little) catch unreachable;
            c.weapons[i].weapani = f.reader().readInt(u16, .Little) catch unreachable;
            c.weapons[i].max = f.reader().readInt(u8, .Little) catch unreachable;
            c.weapons[i].tx = f.reader().readInt(u8, .Little) catch unreachable;
            c.weapons[i].ty = f.reader().readInt(u8, .Little) catch unreachable;
            c.weapons[i].aim = f.reader().readInt(u8, .Little) catch unreachable;
            readIntMultiple(f, u8, c.weapons[i].attack[0..8], .Little) catch unreachable;
            readIntMultiple(f, u8, c.weapons[i].del[0..8], .Little) catch unreachable;
            readIntMultiple(f, i8, c.weapons[i].sx[0..8], .Little) catch unreachable;
            readIntMultiple(f, i8, c.weapons[i].sy[0..8], .Little) catch unreachable;
            readIntMultiple(f, i8, c.weapons[i].bx[0..8], .Little) catch unreachable;
            readIntMultiple(f, i8, c.weapons[i].by[0..8], .Little) catch unreachable;
            readIntMultiple(f, u16, c.weapons[i].sg[0..8], .Little) catch unreachable;
            c.weapons[i].acceleration = f.reader().readInt(i8, .Little) catch unreachable;
            c.weapons[i].accelerationx = f.reader().readInt(i8, .Little) catch unreachable;
            c.weapons[i].circlesize = f.reader().readInt(u8, .Little) catch unreachable;
            c.weapons[i].sound = f.reader().readInt(u8, .Little) catch unreachable;
            c.weapons[i].trail = f.reader().readInt(u8, .Little) catch unreachable;
            c.weapons[i].shipblastfilter = f.reader().readInt(u8, .Little) catch unreachable;
        }
    }

    {
        var i: usize = 0;
        while (i < c.weaponPort.len) : (i += 1) {
            var nameLen = f.reader().readInt(u8, .Little) catch unreachable;
            _ = f.readAll(c.weaponPort[i].name[0..30]) catch unreachable;
            c.weaponPort[i].name[math.min(nameLen, 30)] = 0;
            c.weaponPort[i].opnum = f.reader().readInt(u8, .Little) catch unreachable;
            readIntMultiple(f, u16, c.weaponPort[i].op[0][0..11], .Little) catch unreachable;
            readIntMultiple(f, u16, c.weaponPort[i].op[1][0..11], .Little) catch unreachable;
            c.weaponPort[i].cost = f.reader().readInt(u16, .Little) catch unreachable;
            c.weaponPort[i].itemgraphic = f.reader().readInt(u16, .Little) catch unreachable;
            c.weaponPort[i].poweruse = f.reader().readInt(u16, .Little) catch unreachable;
        }
    }

    {
        var i: usize = 0;
        while (i < c.special.len) : (i += 1) {
            var nameLen = f.reader().readInt(u8, .Little) catch unreachable;
            _ = f.readAll(c.special[i].name[0..30]) catch unreachable;
            c.special[i].name[math.min(nameLen, 30)] = 0;
            c.special[i].itemgraphic = f.reader().readInt(u16, .Little) catch unreachable;
            c.special[i].pwr = f.reader().readInt(u8, .Little) catch unreachable;
            c.special[i].stype = f.reader().readInt(u8, .Little) catch unreachable;
            c.special[i].wpn = f.reader().readInt(u16, .Little) catch unreachable;
        }
    }

    {
        var i: usize = 0;
        while (i < c.powerSys.len) : (i += 1) {
            var nameLen = f.reader().readInt(u8, .Little) catch unreachable;
            _ = f.readAll(c.powerSys[i].name[0..30]) catch unreachable;
            c.powerSys[i].name[math.min(nameLen, 30)] = 0;
            c.powerSys[i].itemgraphic = f.reader().readInt(u16, .Little) catch unreachable;
            c.powerSys[i].power = f.reader().readInt(u8, .Little) catch unreachable;
            c.powerSys[i].speed = f.reader().readInt(i8, .Little) catch unreachable;
            c.powerSys[i].cost = f.reader().readInt(u16, .Little) catch unreachable;
        }
    }

    {
        var i: usize = 0;
        while (i < c.ships.len) : (i += 1) {
            var nameLen = f.reader().readInt(u8, .Little) catch unreachable;
            _ = f.readAll(c.ships[i].name[0..30]) catch unreachable;
            c.ships[i].name[math.min(nameLen, 30)] = 0;
            c.ships[i].shipgraphic = f.reader().readInt(u16, .Little) catch unreachable;
            c.ships[i].itemgraphic = f.reader().readInt(u16, .Little) catch unreachable;
            c.ships[i].ani = f.reader().readInt(u8, .Little) catch unreachable;
            c.ships[i].spd = f.reader().readInt(i8, .Little) catch unreachable;
            c.ships[i].dmg = f.reader().readInt(u8, .Little) catch unreachable;
            c.ships[i].cost = f.reader().readInt(u16, .Little) catch unreachable;
            c.ships[i].bigshipgraphic = f.reader().readInt(u8, .Little) catch unreachable;
        }
    }

    {
        var i: usize = 0;
        while (i < c.options.len) : (i += 1) {
            var nameLen = f.reader().readInt(u8, .Little) catch unreachable;
            _ = f.readAll(c.options[i].name[0..30]) catch unreachable;
            c.options[i].name[math.min(nameLen, 30)] = 0;
            c.options[i].pwr = f.reader().readInt(u8, .Little) catch unreachable;
            c.options[i].itemgraphic = f.reader().readInt(u16, .Little) catch unreachable;
            c.options[i].cost = f.reader().readInt(u16, .Little) catch unreachable;
            c.options[i].tr = f.reader().readInt(u8, .Little) catch unreachable;
            c.options[i].option = f.reader().readInt(u8, .Little) catch unreachable;
            c.options[i].opspd = f.reader().readInt(i8, .Little) catch unreachable;
            c.options[i].ani = f.reader().readInt(u8, .Little) catch unreachable;
            readIntMultiple(f, u16, c.options[i].gr[0..20], .Little) catch unreachable;
            c.options[i].wport = f.reader().readInt(u8, .Little) catch unreachable;
            c.options[i].wpnum = f.reader().readInt(u16, .Little) catch unreachable;
            c.options[i].ammo = f.reader().readInt(u8, .Little) catch unreachable;
            c.options[i].stop = f.reader().readByte() catch unreachable != 0;
            c.options[i].icongr = f.reader().readInt(u8, .Little) catch unreachable;
        }
    }

    {
        var i: usize = 0;
        while (i < c.shields.len) : (i += 1) {
            var nameLen = f.reader().readInt(u8, .Little) catch unreachable;
            _ = f.readAll(c.shields[i].name[0..30]) catch unreachable;
            c.shields[i].name[math.min(nameLen, 30)] = 0;
            c.shields[i].tpwr = f.reader().readInt(u8, .Little) catch unreachable;
            c.shields[i].mpwr = f.reader().readInt(u8, .Little) catch unreachable;
            c.shields[i].itemgraphic = f.reader().readInt(u16, .Little) catch unreachable;
            c.shields[i].cost = f.reader().readInt(u16, .Little) catch unreachable;
        }
    }

    {
        var i: usize = 0;
        while (i < c.enemyDat.len) : (i += 1) {
            c.enemyDat[i].ani = f.reader().readInt(u8, .Little) catch unreachable;
            readIntMultiple(f, u8, c.enemyDat[i].tur[0..3], .Little) catch unreachable;
            readIntMultiple(f, u8, c.enemyDat[i].freq[0..3], .Little) catch unreachable;
            c.enemyDat[i].xmove = f.reader().readInt(i8, .Little) catch unreachable;
            c.enemyDat[i].ymove = f.reader().readInt(i8, .Little) catch unreachable;
            c.enemyDat[i].xaccel = f.reader().readInt(i8, .Little) catch unreachable;
            c.enemyDat[i].yaccel = f.reader().readInt(i8, .Little) catch unreachable;
            c.enemyDat[i].xcaccel = f.reader().readInt(i8, .Little) catch unreachable;
            c.enemyDat[i].ycaccel = f.reader().readInt(i8, .Little) catch unreachable;
            c.enemyDat[i].startx = f.reader().readInt(i16, .Little) catch unreachable;
            c.enemyDat[i].starty = f.reader().readInt(i16, .Little) catch unreachable;
            c.enemyDat[i].startxc = f.reader().readInt(i8, .Little) catch unreachable;
            c.enemyDat[i].startyc = f.reader().readInt(i8, .Little) catch unreachable;
            c.enemyDat[i].armor = f.reader().readInt(u8, .Little) catch unreachable;
            c.enemyDat[i].esize = f.reader().readInt(u8, .Little) catch unreachable;
            readIntMultiple(f, u16, c.enemyDat[i].egraphic[0..20], .Little) catch unreachable;
            c.enemyDat[i].explosiontype = f.reader().readInt(u8, .Little) catch unreachable;
            c.enemyDat[i].animate = f.reader().readInt(u8, .Little) catch unreachable;
            c.enemyDat[i].shapebank = f.reader().readInt(u8, .Little) catch unreachable;
            c.enemyDat[i].xrev = f.reader().readInt(i8, .Little) catch unreachable;
            c.enemyDat[i].yrev = f.reader().readInt(i8, .Little) catch unreachable;
            c.enemyDat[i].dgr = f.reader().readInt(u16, .Little) catch unreachable;
            c.enemyDat[i].dlevel = f.reader().readInt(i8, .Little) catch unreachable;
            c.enemyDat[i].dani = f.reader().readInt(i8, .Little) catch unreachable;
            c.enemyDat[i].elaunchfreq = f.reader().readInt(u8, .Little) catch unreachable;
            c.enemyDat[i].elaunchtype = f.reader().readInt(u16, .Little) catch unreachable;
            c.enemyDat[i].value = f.reader().readInt(i16, .Little) catch unreachable;
            c.enemyDat[i].eenemydie = f.reader().readInt(u16, .Little) catch unreachable;
        }
    }
}

// const ReadIntMultipleError = error{StreamEndedEarly};

fn readIntMultiple(file: File, comptime T: type, buffer: []T, endian: builtin.Endian) !void {
    comptime {
        _ = @divExact(@typeInfo(T).Int.bits, 8); // Throws error if T bits isn't divisible by 8
    }
    const bytes_to_read = @sizeOf(T) * buffer.len;
    const bytes_read = try file.reader().readAll(mem.sliceAsBytes(buffer));
    if (bytes_read < bytes_to_read) {
        return error.StreamEndedEarly;
    }
    if (endian != native_endian) {
        for (buffer) |*val| {
            val.* = @byteSwap(T, val.*);
        }
    }
}

// fn getCStringLength(string: [*c]const u8) usize {
//     var len: usize = 0;
//     while (string[len] != 0) : (len += 1) {}
//     return len;
// }
// comptime {
//     @export(JE_loadItemDat, .{ .name = "JE_loadItemDat" });
// }
