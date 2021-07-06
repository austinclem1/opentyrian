const std = @import("std");
const builtin = std.builtin;
const fs = std.fs;
const math = std.math;

const File = fs.File;

const c = @cImport({
    @cInclude("episodes.h");
});

// MAIN Weapons Data
export const weaponPort: c.JE_WeaponPortType = undefined;
export const weapons = [WEAP_NUM + 1]JE_WeaponType{};

// Items
export const powerSys: c.JE_PowerType = undefined;
export const ships: c.JE_ShipType = undefined;
export const options = [OPTION_NUM + 1]JE_OptionType{};
export const shields: c.JE_ShieldType = undefined;
export const special: c.JE_SpecialType = undefined;

// Enemy data */
export const enemyDat: c.JE_EnemyDatType = undefined;

// EPISODE variables */
// const initial_episode_num: c.JE_byte = undefined;
const episodeNum: c.JE_byte = 0;
// const episodeAvail = [EPISODE_MAX]JE_boolean{}; //* [1..episodemax] */
// const episode_file = [13]char{};
// const cube_file = [13]char{};

const episode1DataLoc: c.JE_longint = undefined;

// Tells the game whether the level currently loaded is a bonus level. */
// const bonusLevel: c.JE_boolean = undefined;

// Tells if the game jumped back to Episode 1 */
// const jumpBackToEpisode1: c.JE_boolean = undefined;

export fn JE_loadItemDat() void {
    var f: File = undefined;

    if (episodeNum <= 3) {
        dir = fs.openDir(data_dir(), .{}) catch unreachable;
        f = dir.openFile("tyrian.hdt", .{}) catch unreachable;
        episode1DataLoc = f.readInt(i32, .little) catch unreachable;
        fseek(f, episode1DataLoc, SEEK_SET);
    } else {
        // episode 4 stores item data in the level file
        f = dir_fopen_die(data_dir(), levelFile, "rb");
        fseek(f, lvlPos[lvlNum - 1], SEEK_SET);
    }

    defer f.close();

    var itemNum = [7]c.JE_word; //* [1..7] */
    f.readIntMultiple(u16, itemNum, 7, .little) catch unreachable;

    while (i < WEAP_NUM + 1) : (i += 1) {
        weapons[i].drain = f.readInt(u16, .little) catch unreachable;
        weapons[i].shotrepeat = f.readInt(u8, .little) catch unreachable;
        weapons[i].multi = f.readInt(u8, .little) catch unreachable;
        weapons[i].weapani = f.readInt(u16, .little) catch unreachable;
        weapons[i].max = f.readInt(u8, .little) catch unreachable;
        weapons[i].tx = f.readInt(u8, .little) catch unreachable;
        weapons[i].ty = f.readInt(u8, .little) catch unreachable;
        weapons[i].aim = f.readInt(u8, .little) catch unreachable;
        f.readIntMultiple(u8, weapons[i].attack, 8, .little) catch unreachable;
        f.readIntMultiple(u8, weapons[i].del, 8, .little) catch unreachable;
        f.readIntMultiple(i8, weapons[i].sx, 8, .little) catch unreachable;
        f.readIntMultiple(i8, weapons[i].sy, 8, .little) catch unreachable;
        f.readIntMultiple(i8, weapons[i].bx, 8, .little) catch unreachable;
        f.readIntMultiple(i8, weapons[i].by, 8, .little) catch unreachable;
        f.readIntMultiple(u16, weapons[i].sg, 8, .little) catch unreachable;
        weapons[i].acceleration = f.readInt(i8, .little) catch unreachable;
        weapons[i].accelerationx = f.readInt(i8, .little) catch unreachable;
        weapons[i].circlesize = f.readInt(u8, .little) catch unreachable;
        weapons[i].sound = f.readInt(u8, .little) catch unreachable;
        weapons[i].trail = f.readInt(u8, .little) catch unreachable;
        weapons[i].shipblastfilter = f.readInt(u8, .little) catch unreachable;
    }

    while (i < PORT_NUM + 1) : (i += 1) {
        var nameLen = f.readInt(u8, .little) catch unreachable;
        f.readAll(weaponPort[i].name[0..30]) catch unreachable;
        weaponPort[i].name[math.min(nameLen, 30)] = 0;
        weaponPort[i].opnum = f.readInt(u8, .little) catch unreachable;
        f.readIntMultiple(u16, weaponPort[i].op[0], 11, .little) catch unreachable;
        f.readIntMultiple(u16, weaponPort[i].op[1], 11, .little) catch unreachable;
        weaponPort[i].cost = f.readInt(u16, .little) catch unreachable;
        weaponPort[i].itemgraphic = f.readInt(u16, .little) catch unreachable;
        weaponPort[i].poweruse = f.readInt(u16, .little) catch unreachable;
    }

    while (i < SPECIAL_NUM + 1) : (i += 1) {
        var nameLen = f.readInt(u8, .little) catch unreachable;
        f.readAll(special[i].name[0..30]) catch unreachable;
        special[i].name[math.min(nameLen, 30)] = 0;
        special[i].itemgraphic = f.readInt(u16, .little) catch unreachable;
        special[i].pwr = f.readInt(u8, .little) catch unreachable;
        special[i].stype = f.readInt(u8, .little) catch unreachable;
        special[i].wpn = f.readInt(u16, .little) catch unreachable;
    }

    while (i < POWER_NUM + 1) : (i += 1) {
        var nameLen = f.readInt(u8, .little) catch unreachable;
        f.readAll(powerSys[i].name[0..30]) catch unreachable;
        powerSys[i].name[math.min(nameLen, 30)] = 0;
        powerSys[i].itemgraphic = f.readInt(u16, .little) catch unreachable;
        powerSys[i].power = f.readInt(u8, .little) catch unreachable;
        powerSys[i].speed = f.readInt(i8, .little) catch unreachable;
        powerSys[i].cost = f.readInt(u16, .little) catch unreachable;
    }

    while (i < SHIP_NUM + 1) : (i += 1) {
        var nameLen = f.readInt(u8, .little) catch unreachable;
        f.readAll(ships[i].name[0..30]) catch unreachable;
        ships[i].name[math.min(nameLen, 30)] = 0;
        ships[i].shipgraphic = f.readInt(u16, .little) catch unreachable;
        ships[i].itemgraphic = f.readInt(u16, .little) catch unreachable;
        ships[i].ani = f.readInt(u8, .little) catch unreachable;
        ships[i].spd = f.readInt(i8, .little) catch unreachable;
        ships[i].dmg = f.readInt(u8, .little) catch unreachable;
        ships[i].cost = f.readInt(u16, .little) catch unreachable;
        ships[i].bigshipgraphic = f.readInt(u8, .little) catch unreachable;
    }

    while (i < OPTION_NUM + 1) : (i += 1) {
        var nameLen = f.readInt(u8, .little) catch unreachable;
        f.readAll(options[i].name[0..30]) catch unreachable;
        options[i].name[math.min(nameLen, 30)] = 0;
        options[i].pwr = f.readInt(u8, .little) catch unreachable;
        options[i].itemgraphic = f.readInt(u16, .little) catch unreachable;
        options[i].cost = f.readInt(u16, .little) catch unreachable;
        options[i].tr = f.readInt(u8, .little) catch unreachable;
        options[i].option = f.readInt(u8, .little) catch unreachable;
        options[i].opspd = f.readInt(i8, .little) catch unreachable;
        options[i].ani = f.readInt(u8, .little) catch unreachable;
        f.readIntMultiple(u16, options[i].gr, 20, .little) catch unreachable;
        options[i].wport = f.readInt(u8, .little) catch unreachable;
        options[i].wpnum = f.readInt(u16, .little) catch unreachable;
        options[i].ammo = f.readInt(u8, .little) catch unreachable;
        fread_bool_die(&options[i].stop, f);
        options[i].icongr = f.readInt(u8, .little) catch unreachable;
    }

    while (i < SHIELD_NUM + 1) : (i += 1) {
        var nameLen = f.readInt(u8, .little) catch unreachable;
        f.readAll(shields[i].name[0..30]) catch unreachable;
        shields[i].name[math.min(nameLen, 30)] = 0;
        shields[i].tpwr = f.readInt(u8, .little) catch unreachable;
        shields[i].mpwr = f.readInt(u8, .little) catch unreachable;
        shields[i].itemgraphic = f.readInt(u16, .little) catch unreachable;
        shields[i].cost = f.readInt(u16, .little) catch unreachable;
    }

    while (i < ENEMY_NUM + 1) : (i += 1) {
        enemyDat[i].ani = f.readInt(u8, .little) catch unreachable;
        f.readIntMultiple(u8, enemyDat[i].tur, 3, .little) catch unreachable;
        f.readIntMultiple(u8, enemyDat[i].freq, 3, .little) catch unreachable;
        enemyDat[i].xmove = f.readInt(i8, .little) catch unreachable;
        enemyDat[i].ymove = f.readInt(i8, .little) catch unreachable;
        enemyDat[i].xaccel = f.readInt(i8, .little) catch unreachable;
        enemyDat[i].yaccel = f.readInt(i8, .little) catch unreachable;
        enemyDat[i].xcaccel = f.readInt(i8, .little) catch unreachable;
        enemyDat[i].ycaccel = f.readInt(i8, .little) catch unreachable;
        enemyDat[i].startx = f.readInt(i16, .little) catch unreachable;
        enemyDat[i].starty = f.readInt(i16, .little) catch unreachable;
        enemyDat[i].startxc = f.readInt(i8, .little) catch unreachable;
        enemyDat[i].startyc = f.readInt(i8, .little) catch unreachable;
        enemyDat[i].armor = f.readInt(u8, .little) catch unreachable;
        enemyDat[i].esize = f.readInt(u8, .little) catch unreachable;
        f.readIntMultiple(u16, enemyDat[i].egraphic, 20, .little) catch unreachable;
        enemyDat[i].explosiontype = f.readInt(u8, .little) catch unreachable;
        enemyDat[i].animate = f.readInt(u8, .little) catch unreachable;
        enemyDat[i].shapebank = f.readInt(u8, .little) catch unreachable;
        enemyDat[i].xrev = f.readInt(i8, .little) catch unreachable;
        enemyDat[i].yrev = f.readInt(i8, .little) catch unreachable;
        enemyDat[i].dgr = f.readInt(u16, .little) catch unreachable;
        enemyDat[i].dlevel = f.readInt(i8, .little) catch unreachable;
        enemyDat[i].dani = f.readInt(i8, .little) catch unreachable;
        enemyDat[i].elaunchfreq = f.readInt(u8, .little) catch unreachable;
        enemyDat[i].elaunchtype = f.readInt(u16, .little) catch unreachable;
        enemyDat[i].value = f.readInt(i16, .little) catch unreachable;
        enemyDat[i].eenemydie = f.readInt(u16, .little) catch unreachable;
    }
}

fn readIntMultiple(file: File, comptime T: type, dest: [*]T, count: usize, endian: builtin.Endian) !void {
    var i = 0;
    while (i < count) : (i += 1) {
        dest[i] = try file.reader().readInt(T, endian);
    }
}
