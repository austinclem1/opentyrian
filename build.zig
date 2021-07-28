const std = @import("std");
const LibExeObjStep = std.build.LibExeObjStep;
const CrossTarget = std.zig.CrossTarget;

pub fn build(b: *std.build.Builder) !void {
    // Standard target options allows the person running `zig build` to choose
    // what target to build for. Here we do not override the defaults, which
    // means any target is allowed, and the default is native. Other options
    // for restricting supported target set are available.
    const target = b.standardTargetOptions(.{});

    // Standard release options allow the person running `zig build` to select
    // between Debug, ReleaseSafe, ReleaseFast, and ReleaseSmall.
    const mode = b.standardReleaseOptions();

    const objs = [_]*LibExeObjStep{ b.addObject("sprite", "src/zig/sprite.zig"), b.addObject("file", "src/zig/file.zig") };
    for (objs) |obj| {
        obj.addIncludeDir("src");
        addDepPaths(obj, target);
    }

    const exe = b.addExecutable("opentyrian", null);
    addDepPaths(exe, target);

    switch (target.cpu_arch orelse std.builtin.cpu.arch) {
        .x86_64 => {
            switch (target.os_tag orelse std.builtin.os.tag) {
                .windows => {
                    exe.defineCMacro("TYRIAN_DIR", "\"C:/TYRIAN\"");
                    exe.defineCMacro("TARGET_WIN32", "1");
                    for (objs) |obj| {
                        linkLibsWindowsAny(obj);
                    }
                    linkLibsWindowsAny(exe);
                },
                .linux => {
                    exe.defineCMacro("TYRIAN_DIR", "\"/usr/local/share/games/tyrian\"");
                    exe.defineCMacro("TARGET_UNIX", "1");
                    for (objs) |obj| {
                        linkLibsLinuxAny(obj);
                    }
                    linkLibsLinuxAny(exe);
                },
                else => {
                    const tag = target.os_tag orelse std.builtin.os.tag;
                    std.debug.print("Unsupported OS: {s}\n", .{@tagName(tag)});
                    return;
                },
            }
        },
        else => {
            const arch = target.cpu_arch orelse std.builtin.cpu.arch;
            std.debug.print("Unsupported architecture: {s}\n", .{@tagName(arch)});
            return;
        },
    }
    // exe.defineCMacro("WITH_NETWORK", "1");

    // exe.addCSourceFile("src/opentyr.c", &[_][]const u8{ "-std=c99", "--subsystem" });
    exe.addCSourceFiles(&[_][]const u8{ "src/animlib.c", "src/arg_parse.c", "src/backgrnd.c", "src/config.c", "src/config_file.c", "src/destruct.c", "src/editship.c", "src/episodes.c", "src/file.c", "src/font.c", "src/fonthand.c", "src/game_menu.c", "src/helptext.c", "src/joystick.c", "src/jukebox.c", "src/keyboard.c", "src/lds_play.c", "src/loudness.c", "src/lvllib.c", "src/lvlmast.c", "src/mainint.c", "src/menus.c", "src/mouse.c", "src/mtrand.c", "src/musmast.c", "src/network.c", "src/nortsong.c", "src/nortvars.c", "src/opentyr.c", "src/opl.c", "src/palette.c", "src/params.c", "src/pcxload.c", "src/pcxmast.c", "src/picload.c", "src/player.c", "src/scroller.c", "src/setup.c", "src/shots.c", "src/sizebuf.c", "src/sndmast.c", "src/sprite.c", "src/starlib.c", "src/std_support.c", "src/tyrian2.c", "src/varz.c", "src/vga256d.c", "src/vga_palette.c", "src/video.c", "src/video_scale.c", "src/video_scale_hqNx.c", "src/xmas.c" }, &[_][]const u8{"-std=c99"});

    for (objs) |obj| {
        obj.setTarget(target);
        obj.setBuildMode(mode);
        exe.addObject(obj);
    }

    exe.setTarget(target);
    exe.setBuildMode(mode);

    exe.install();

    const run_cmd = exe.run();
    run_cmd.step.dependOn(b.getInstallStep());
    if (b.args) |args| {
        run_cmd.addArgs(args);
    }

    const run_step = b.step("run", "Run the app");
    run_step.dependOn(&run_cmd.step);
}

fn linkLibsWindowsAny(artifact: *LibExeObjStep) void {
    artifact.linkSystemLibrary("c");
    artifact.linkSystemLibrary("SDL2");
    artifact.linkSystemLibrary("SDL2_net");
    artifact.linkSystemLibrary("SDL2main");
    artifact.linkSystemLibrary("kernel32");
    artifact.linkSystemLibrary("user32");
    artifact.linkSystemLibrary("gdi32");
    artifact.linkSystemLibrary("winspool");
    artifact.linkSystemLibrary("comdlg32");
    artifact.linkSystemLibrary("advapi32");
    artifact.linkSystemLibrary("shell32");
    artifact.linkSystemLibrary("ole32");
    artifact.linkSystemLibrary("oleaut32");
    // exe.linkSystemLibrary("uuid");
    // exe.linkSystemLibrary("odbc32");
    // exe.linkSystemLibrary("odbccp32");
}

fn linkLibsLinuxAny(artifact: *LibExeObjStep) void {
    artifact.linkSystemLibrary("c");
    artifact.linkSystemLibrary("SDL2");
    artifact.linkSystemLibrary("SDL2_net");
    artifact.linkSystemLibrary("SDL2main");
}

fn addDepPaths(artifact: *LibExeObjStep, target: CrossTarget) void {
    if (std.builtin.os.tag == .windows) {
        artifact.addVcpkgPaths(.static) catch {};
    }
    switch (target.cpu_arch orelse std.builtin.cpu.arch) {
        .x86_64 => {
            switch (target.os_tag orelse std.builtin.os.tag) {
                .windows => {
                    switch (target.abi orelse std.builtin.abi) {
                        .msvc => {
                            addIncludesx86WindowsMsvc(artifact);
                            addLibPathsx86WindowsMsvc(artifact);
                        },
                        .gnu => {
                            // addIncludesx86WindowsGnu(artifact);
                            // addLibPathsx86WindowsGnu(artifact);
                        },
                        else => {
                            const abi = target.abi orelse std.builtin.abi;
                            std.debug.print("Unsupported ABI: {s}\n", .{@tagName(abi)});
                            return;
                        },
                    }
                },
                .linux => {
                    switch (target.abi orelse std.builtin.abi) {
                        .gnu => {
                            addIncludesx86LinuxGnu(artifact);
                            addLibPathsx86LinuxGnu(artifact);
                        },
                        else => {
                            const abi = target.abi orelse std.builtin.abi;
                            std.debug.print("Unsupported ABI: {s}\n", .{@tagName(abi)});
                            return;
                        },
                    }
                },
                else => {
                    const tag = target.os_tag orelse std.builtin.os.tag;
                    std.debug.print("Unsupported OS: {s}\n", .{@tagName(tag)});
                    return;
                },
            }
        },
        else => {
            const arch = target.cpu_arch orelse std.builtin.cpu.arch;
            std.debug.print("Unsupported architecture: {s}\n", .{@tagName(arch)});
            return;
        },
    }
}

fn addIncludesx86WindowsMsvc(artifact: *LibExeObjStep) void {
    artifact.addIncludeDir("../SDL2/include");
    artifact.addIncludeDir("../SDL2_net/include");
    // artifact.addIncludeDir("C:/Program Files (x86)/Microsoft Visual Studio/2019/BuildTools/VC/Tools/MSVC/14.29.30037/include");
    // artifact.addIncludeDir("C:/Program Files (x86)/Microsoft Visual Studio/2019/BuildTools/VC/Tools/MSVC/14.29.30037/atlmfc/include");
    // artifact.addIncludeDir("C:/Program Files (x86)/Windows Kits/10/Include/10.0.18362.0/ucrt");
    // artifact.addIncludeDir("C:/Program Files (x86)/Windows Kits/10/include/10.0.18362.0/shared");
    // artifact.addIncludeDir("C:/Program Files (x86)/Windows Kits/10/include/10.0.18362.0/um");
    // artifact.addIncludeDir("C:/Program Files (x86)/Windows Kits/10/include/10.0.18362.0/winrt");
}

fn addLibPathsx86WindowsMsvc(artifact: *LibExeObjStep) void {
    artifact.addLibPath("../SDL2/lib/x64");
    artifact.addLibPath("../SDL2_net/lib/x64");
}

fn addIncludesx86WindowsGnu(artifact: *LibExeObjStep) void {
    artifact.addIncludeDir("C:/Users/Austin/Documents/Programming/SDL2_net-2.0.1/x86_64-w64-mingw32/include/SDL2");
    artifact.addIncludeDir("C:/Users/Austin/Documents/Programming/SDL2-2.0.14-mingw/x86_64-w64-mingw32/include/SDL2");
}

fn addLibPathsx86WindowsGnu(artifact: *LibExeObjStep) void {
    artifact.addLibPath("C:/Users/Austin/Documents/Programming/SDL2-2.0.14-mingw/x86_64-w64-mingw32/lib");
    artifact.addLibPath("C:/Users/Austin/Documents/Programming/SDL2_net-2.0.1/x86_64-w64-mingw32/lib");
}

fn addIncludesx86LinuxGnu(artifact: *LibExeObjStep) void {
    artifact.addSystemIncludeDir("C:/Users/Austin/Documents/Programming/linux_dev_libs/usr/include/x86_64-linux-gnu");
    artifact.addSystemIncludeDir("C:/Users/Austin/Documents/Programming/linux_dev_libs/usr/include/SDL2");
}

fn addLibPathsx86LinuxGnu(artifact: *LibExeObjStep) void {
    artifact.addLibPath("C:/Users/Austin/Documents/Programming/linux_dev_libs/usr/lib/x86_64-linux-gnu");
}
