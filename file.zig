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

export fn JE_loadItemDat() void {
    // MAIN Weapons Data
    const weaponPort = @extern(*c.JE_WeaponPortType, .{ .name = "weaponPort" });
    // export const weapons = [WEAP_NUM + 1]JE_WeaponType{};
    const weapons = @extern(*[c.WEAP_NUM + 1]c.JE_WeaponType, .{ .name = "weapons" });

    // Items
    const powerSys = @extern(*c.JE_PowerType, .{ .name = "powerSys" });
    const ships = @extern(*c.JE_ShipType, .{ .name = "ships" });
    // export const options = [OPTION_NUM + 1]JE_OptionType{};
    const options = @extern(*[c.OPTION_NUM + 1]c.JE_OptionType, .{ .name = "options" });
    const shields = @extern(*c.JE_ShieldType, .{ .name = "shields" });
    const special = @extern(*c.JE_SpecialType, .{ .name = "special" });

    // Enemy data */
    const enemyDat = @extern(*c.JE_EnemyDatType, .{ .name = "enemyDat" });

    // EPISODE variables */
    // const initial_episode_num: c.JE_byte = undefined;
    const episodeNum = @extern(*c.JE_byte, .{ .name = "episodeNum" });
    // const episodeAvail = [EPISODE_MAX]JE_boolean{}; //* [1..episodemax] */
    // const episode_file = [13]char{};
    // const cube_file = [13]char{};

    var episode1DataLoc = @extern(*c.JE_longint, .{ .name = "episode1DataLoc" });

    // Tells the game whether the level currently loaded is a bonus level. */
    // const bonusLevel: c.JE_boolean = undefined;

    // Tells if the game jumped back to Episode 1 */
    // const jumpBackToEpisode1: c.JE_boolean = undefined;

    const levelFile = @extern([*c]const u8, .{ .name = "levelFile" });
    const lvlPos = @extern(*c.JE_LvlPosType, .{ .name = "lvlPos" });
    const lvlNum = @extern(*c.JE_word, .{ .name = "lvlNum" });

    var f: File = undefined;

    const data_dir_len = getCStringLength(c.data_dir());
    const data_dir_path = c.data_dir()[0..data_dir_len];

    var data_dir = fs.openDirAbsolute(data_dir_path, .{}) catch unreachable;
    defer data_dir.close();
    if (episodeNum.* <= 3) {
        f = data_dir.openFile("tyrian.hdt", .{}) catch unreachable;
        episode1DataLoc.* = f.reader().readInt(i32, .Little) catch unreachable;
        // fseek(f, episode1DataLoc.*, SEEK_SET);
        f.seekTo(@intCast(usize, episode1DataLoc.*)) catch unreachable;
    } else {
        // episode 4 stores item data in the level file
        const level_file_path_len = getCStringLength(levelFile);
        const level_file_path = levelFile[0..level_file_path_len];
        f = data_dir.openFile(level_file_path, .{}) catch unreachable;
        // fseek(f, lvlPos.*[lvlNum.* - 1], SEEK_SET);
        f.seekTo(@intCast(usize, lvlPos.*[lvlNum.* - 1])) catch unreachable;
    }

    defer f.close();

    var itemNum = [_]c.JE_word{undefined} ** 7; //* [1..7] */
    readIntMultiple(f, u16, itemNum[0..7], .Little) catch unreachable;

    {
        var i: usize = 0;
        while (i < c.WEAP_NUM + 1) : (i += 1) {
            weapons.*[i].drain = f.reader().readInt(u16, .Little) catch unreachable;
            weapons.*[i].shotrepeat = f.reader().readInt(u8, .Little) catch unreachable;
            weapons.*[i].multi = f.reader().readInt(u8, .Little) catch unreachable;
            weapons.*[i].weapani = f.reader().readInt(u16, .Little) catch unreachable;
            weapons.*[i].max = f.reader().readInt(u8, .Little) catch unreachable;
            weapons.*[i].tx = f.reader().readInt(u8, .Little) catch unreachable;
            weapons.*[i].ty = f.reader().readInt(u8, .Little) catch unreachable;
            weapons.*[i].aim = f.reader().readInt(u8, .Little) catch unreachable;
            readIntMultiple(f, u8, weapons[i].attack[0..8], .Little) catch unreachable;
            readIntMultiple(f, u8, weapons[i].del[0..8], .Little) catch unreachable;
            readIntMultiple(f, i8, weapons[i].sx[0..8], .Little) catch unreachable;
            readIntMultiple(f, i8, weapons[i].sy[0..8], .Little) catch unreachable;
            readIntMultiple(f, i8, weapons[i].bx[0..8], .Little) catch unreachable;
            readIntMultiple(f, i8, weapons[i].by[0..8], .Little) catch unreachable;
            readIntMultiple(f, u16, weapons[i].sg[0..8], .Little) catch unreachable;
            weapons.*[i].acceleration = f.reader().readInt(i8, .Little) catch unreachable;
            weapons.*[i].accelerationx = f.reader().readInt(i8, .Little) catch unreachable;
            weapons.*[i].circlesize = f.reader().readInt(u8, .Little) catch unreachable;
            weapons.*[i].sound = f.reader().readInt(u8, .Little) catch unreachable;
            weapons.*[i].trail = f.reader().readInt(u8, .Little) catch unreachable;
            weapons.*[i].shipblastfilter = f.reader().readInt(u8, .Little) catch unreachable;
        }
    }

    {
        var i: usize = 0;
        while (i < c.PORT_NUM + 1) : (i += 1) {
            var nameLen = f.reader().readInt(u8, .Little) catch unreachable;
            _ = f.readAll(weaponPort.*[i].name[0..30]) catch unreachable;
            weaponPort.*[i].name[math.min(nameLen, 30)] = 0;
            weaponPort.*[i].opnum = f.reader().readInt(u8, .Little) catch unreachable;
            readIntMultiple(f, u16, weaponPort.*[i].op[0][0..11], .Little) catch unreachable;
            readIntMultiple(f, u16, weaponPort.*[i].op[1][0..11], .Little) catch unreachable;
            weaponPort.*[i].cost = f.reader().readInt(u16, .Little) catch unreachable;
            weaponPort.*[i].itemgraphic = f.reader().readInt(u16, .Little) catch unreachable;
            weaponPort.*[i].poweruse = f.reader().readInt(u16, .Little) catch unreachable;
        }
    }

    {
        var i: usize = 0;
        while (i < c.SPECIAL_NUM + 1) : (i += 1) {
            var nameLen = f.reader().readInt(u8, .Little) catch unreachable;
            _ = f.readAll(special[i].name[0..30]) catch unreachable;
            special[i].name[math.min(nameLen, 30)] = 0;
            special[i].itemgraphic = f.reader().readInt(u16, .Little) catch unreachable;
            special[i].pwr = f.reader().readInt(u8, .Little) catch unreachable;
            special[i].stype = f.reader().readInt(u8, .Little) catch unreachable;
            special[i].wpn = f.reader().readInt(u16, .Little) catch unreachable;
        }
    }

    {
        var i: usize = 0;
        while (i < c.POWER_NUM + 1) : (i += 1) {
            var nameLen = f.reader().readInt(u8, .Little) catch unreachable;
            _ = f.readAll(powerSys.*[i].name[0..30]) catch unreachable;
            powerSys.*[i].name[math.min(nameLen, 30)] = 0;
            powerSys.*[i].itemgraphic = f.reader().readInt(u16, .Little) catch unreachable;
            powerSys.*[i].power = f.reader().readInt(u8, .Little) catch unreachable;
            powerSys.*[i].speed = f.reader().readInt(i8, .Little) catch unreachable;
            powerSys.*[i].cost = f.reader().readInt(u16, .Little) catch unreachable;
        }
    }

    {
        var i: usize = 0;
        while (i < c.SHIP_NUM + 1) : (i += 1) {
            var nameLen = f.reader().readInt(u8, .Little) catch unreachable;
            _ = f.readAll(ships.*[i].name[0..30]) catch unreachable;
            ships.*[i].name[math.min(nameLen, 30)] = 0;
            ships.*[i].shipgraphic = f.reader().readInt(u16, .Little) catch unreachable;
            ships.*[i].itemgraphic = f.reader().readInt(u16, .Little) catch unreachable;
            ships.*[i].ani = f.reader().readInt(u8, .Little) catch unreachable;
            ships.*[i].spd = f.reader().readInt(i8, .Little) catch unreachable;
            ships.*[i].dmg = f.reader().readInt(u8, .Little) catch unreachable;
            ships.*[i].cost = f.reader().readInt(u16, .Little) catch unreachable;
            ships.*[i].bigshipgraphic = f.reader().readInt(u8, .Little) catch unreachable;
        }
    }

    {
        var i: usize = 0;
        while (i < c.OPTION_NUM + 1) : (i += 1) {
            var nameLen = f.reader().readInt(u8, .Little) catch unreachable;
            _ = f.readAll(options.*[i].name[0..30]) catch unreachable;
            options.*[i].name[math.min(nameLen, 30)] = 0;
            options.*[i].pwr = f.reader().readInt(u8, .Little) catch unreachable;
            options.*[i].itemgraphic = f.reader().readInt(u16, .Little) catch unreachable;
            options.*[i].cost = f.reader().readInt(u16, .Little) catch unreachable;
            options.*[i].tr = f.reader().readInt(u8, .Little) catch unreachable;
            options.*[i].option = f.reader().readInt(u8, .Little) catch unreachable;
            options.*[i].opspd = f.reader().readInt(i8, .Little) catch unreachable;
            options.*[i].ani = f.reader().readInt(u8, .Little) catch unreachable;
            readIntMultiple(f, u16, options.*[i].gr[0..20], .Little) catch unreachable;
            options.*[i].wport = f.reader().readInt(u8, .Little) catch unreachable;
            options.*[i].wpnum = f.reader().readInt(u16, .Little) catch unreachable;
            options.*[i].ammo = f.reader().readInt(u8, .Little) catch unreachable;
            options.*[i].stop = f.reader().readByte() catch unreachable != 0;
            options.*[i].icongr = f.reader().readInt(u8, .Little) catch unreachable;
        }
    }

    {
        var i: usize = 0;
        while (i < c.SHIELD_NUM + 1) : (i += 1) {
            var nameLen = f.reader().readInt(u8, .Little) catch unreachable;
            _ = f.readAll(shields.*[i].name[0..30]) catch unreachable;
            shields.*[i].name[math.min(nameLen, 30)] = 0;
            shields.*[i].tpwr = f.reader().readInt(u8, .Little) catch unreachable;
            shields.*[i].mpwr = f.reader().readInt(u8, .Little) catch unreachable;
            shields.*[i].itemgraphic = f.reader().readInt(u16, .Little) catch unreachable;
            shields.*[i].cost = f.reader().readInt(u16, .Little) catch unreachable;
        }
    }

    {
        var i: usize = 0;
        while (i < c.ENEMY_NUM + 1) : (i += 1) {
            enemyDat[i].ani = f.reader().readInt(u8, .Little) catch unreachable;
            readIntMultiple(f, u8, enemyDat[i].tur[0..3], .Little) catch unreachable;
            readIntMultiple(f, u8, enemyDat[i].freq[0..3], .Little) catch unreachable;
            enemyDat[i].xmove = f.reader().readInt(i8, .Little) catch unreachable;
            enemyDat[i].ymove = f.reader().readInt(i8, .Little) catch unreachable;
            enemyDat[i].xaccel = f.reader().readInt(i8, .Little) catch unreachable;
            enemyDat[i].yaccel = f.reader().readInt(i8, .Little) catch unreachable;
            enemyDat[i].xcaccel = f.reader().readInt(i8, .Little) catch unreachable;
            enemyDat[i].ycaccel = f.reader().readInt(i8, .Little) catch unreachable;
            enemyDat[i].startx = f.reader().readInt(i16, .Little) catch unreachable;
            enemyDat[i].starty = f.reader().readInt(i16, .Little) catch unreachable;
            enemyDat[i].startxc = f.reader().readInt(i8, .Little) catch unreachable;
            enemyDat[i].startyc = f.reader().readInt(i8, .Little) catch unreachable;
            enemyDat[i].armor = f.reader().readInt(u8, .Little) catch unreachable;
            enemyDat[i].esize = f.reader().readInt(u8, .Little) catch unreachable;
            readIntMultiple(f, u16, enemyDat[i].egraphic[0..20], .Little) catch unreachable;
            enemyDat[i].explosiontype = f.reader().readInt(u8, .Little) catch unreachable;
            enemyDat[i].animate = f.reader().readInt(u8, .Little) catch unreachable;
            enemyDat[i].shapebank = f.reader().readInt(u8, .Little) catch unreachable;
            enemyDat[i].xrev = f.reader().readInt(i8, .Little) catch unreachable;
            enemyDat[i].yrev = f.reader().readInt(i8, .Little) catch unreachable;
            enemyDat[i].dgr = f.reader().readInt(u16, .Little) catch unreachable;
            enemyDat[i].dlevel = f.reader().readInt(i8, .Little) catch unreachable;
            enemyDat[i].dani = f.reader().readInt(i8, .Little) catch unreachable;
            enemyDat[i].elaunchfreq = f.reader().readInt(u8, .Little) catch unreachable;
            enemyDat[i].elaunchtype = f.reader().readInt(u16, .Little) catch unreachable;
            enemyDat[i].value = f.reader().readInt(i16, .Little) catch unreachable;
            enemyDat[i].eenemydie = f.reader().readInt(u16, .Little) catch unreachable;
        }
    }
}

const ReadIntMultipleError = error{StreamEndedEarly};

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

fn getCStringLength(string: [*c]const u8) usize {
    var len: usize = 0;
    while (string[len] != 0) : (len += 1) {}
    return len;
}
