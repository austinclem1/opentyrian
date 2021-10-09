const std = @import("std");

const fmt = std.fmt;

const Macro = struct {
    name: []const u8,
    value: ?[]const u8,
};

pub fn build(b: *std.build.Builder) !void {
    // Standard target options allows the person running `zig build` to choose
    // what target to build for. Here we do not override the defaults, which
    // means any target is allowed, and the default is native. Other options
    // for restricting supported target set are available.
    const target = b.standardTargetOptions(.{});

    // Standard release options allow the person running `zig build` to select
    // between Debug, ReleaseSafe, ReleaseFast, and ReleaseSmall.
    const mode = b.standardReleaseOptions();

    var c_flags = std.ArrayList([]const u8).init(b.allocator);
    defer c_flags.deinit();

    try c_flags.append("-std=c99");
    // try c_flags.append("-fno-sanitize-trap=undefined");
    if (mode == .Debug) try c_flags.append("-O0");

    // Macros start
    var macros = std.ArrayList(Macro).init(b.allocator);
    defer macros.deinit();

    {
        const tyrian_dir = b.option([]const u8, "tyrian-dir", "Path to Tyrian Installation") orelse switch (target.getOsTag()) {
            .windows => "\"C:/TYRIAN\"",
            .linux => "\"/usr/local/share/games/tyrian\"",
            else => @panic("Unsupported OS"),
        };
        try macros.append(.{ .name = "TYRIAN_DIR", .value = tyrian_dir });

        if (b.option(bool, "net-capable", "Include online multiplayer capabilities")) |_| {
            try macros.append(.{ .name = "WITH_NETWORK", .value = null });
        }

        switch (target.getOsTag()) {
            .windows => {
                try macros.append(.{ .name = "TARGET_WIN32", .value = null });
            },
            .linux => {
                try macros.append(.{ .name = "TARGET_UNIX", .value = null });
            },
            else => {},
        }
    }
    // Macros end

    const exe = b.addExecutable("opentyrian", "src/opentyr.c");
    exe.setTarget(target);
    exe.setBuildMode(mode);
    exe.setOutputDir(try fmt.allocPrint(b.allocator, "zig-out/{s}-{s}", .{ try target.linuxTriple(b.allocator), @tagName(mode) }));
    exe.addIncludeDir("include");
    linkLibs(exe);
    exe.subsystem = b.option(std.Target.SubSystem, "subsystem", "Target subsystem (Console or Windows)");

    exe.addCSourceFiles(&[_][]const u8{ "src/animlib.c", "src/arg_parse.c", "src/backgrnd.c", "src/config.c", "src/config_file.c", "src/destruct.c", "src/editship.c", "src/episodes.c", "src/file.c", "src/font.c", "src/fonthand.c", "src/game_menu.c", "src/helptext.c", "src/joystick.c", "src/jukebox.c", "src/keyboard.c", "src/lds_play.c", "src/loudness.c", "src/lvllib.c", "src/lvlmast.c", "src/mainint.c", "src/menus.c", "src/mouse.c", "src/mtrand.c", "src/musmast.c", "src/network.c", "src/nortsong.c", "src/nortvars.c", "src/opl.c", "src/palette.c", "src/params.c", "src/pcxload.c", "src/pcxmast.c", "src/picload.c", "src/player.c", "src/scroller.c", "src/setup.c", "src/shots.c", "src/sizebuf.c", "src/sndmast.c", "src/sprite.c", "src/starlib.c", "src/std_support.c", "src/tyrian2.c", "src/varz.c", "src/vga256d.c", "src/vga_palette.c", "src/video.c", "src/video_scale.c", "src/video_scale_hqNx.c", "src/xmas.c" }, c_flags.items);

    const zig_objs = [_]*std.build.LibExeObjStep{ b.addObject("sprite", "src/zig/sprite.zig"), b.addObject("episodes", "src/zig/episodes.zig") };
    for (zig_objs) |obj| {
        exe.addObject(obj);
        obj.setTarget(target);
        obj.setBuildMode(mode);
        obj.addIncludeDir("src");
        obj.addIncludeDir("include");
        obj.linkSystemLibrary("c");
    }

    // Define macros
    for (macros.items) |macro| {
        exe.defineCMacro(macro.name, macro.value);
        for (zig_objs) |obj| {
            obj.defineCMacro(macro.name, macro.value);
        }
    }

    exe.install();

    const run_cmd = exe.run();
    run_cmd.step.dependOn(b.getInstallStep());
    if (b.args) |args| {
        run_cmd.addArgs(args);
    }

    const run_step = b.step("run", "Run the app");
    run_step.dependOn(&run_cmd.step);
}

// Other windows libs (may be necessary for msvc abi)
// artifact.linkSystemLibrary("kernel32");
// artifact.linkSystemLibrary("user32");
// artifact.linkSystemLibrary("gdi32");
// artifact.linkSystemLibrary("winspool");
// artifact.linkSystemLibrary("comdlg32");
// artifact.linkSystemLibrary("advapi32");
// artifact.linkSystemLibrary("shell32");
// artifact.linkSystemLibrary("ole32");
// artifact.linkSystemLibrary("oleaut32");
// exe.linkSystemLibrary("uuid");
// exe.linkSystemLibrary("odbc32");
// exe.linkSystemLibrary("odbccp32");

fn linkLibs(artifact: *std.build.LibExeObjStep) void {
    const target = artifact.target;

    switch (target.getOsTag()) {
        .windows => {
            switch (target.getAbi()) {
                .msvc => {
                    artifact.addLibPath("../SDL2/lib/x64");
                    artifact.addLibPath("../SDL2_net/lib/x64");
                },
                .gnu => {
                    artifact.addLibPath("C:/Users/Austin/Documents/Programming/SDL2-2.0.14-mingw/x86_64-w64-mingw32/lib");
                    artifact.addLibPath("C:/Users/Austin/Documents/Programming/SDL2_net-2.0.1/x86_64-w64-mingw32/lib");
                },
                else => @panic("Unsupported abi for windows"),
            }
        },
        .linux => {
            switch (target.getAbi()) {
                .gnu => {
                    artifact.addLibPath("C:/Users/Austin/Documents/Programming/linux_dev_libs/usr/lib/x86_64-linux-gnu");
                },
                else => @panic("Unsupported abi for linux"),
            }
        },
        else => @panic("Unsupported OS"),
    }

    artifact.linkSystemLibrary("c");
    artifact.linkSystemLibrary("SDL2");
    artifact.linkSystemLibrary("SDL2_net");
    artifact.linkSystemLibrary("SDL2main");
}
