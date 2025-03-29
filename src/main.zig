const std = @import("std");
const c = @cImport({
    @cInclude("raylib.h");
    @cInclude("raygui.h");
});

const WINDOW_WIDTH = 800;
const WINDOW_HEIGHT = 600;
const TAB_HEIGHT = 30;
const BUTTON_HEIGHT = 30;
const BUTTON_WIDTH = 120;
const TAB_WIDTH = 100;
const FRAME_PADDING = 20;
const LINE_HEIGHT = 25;
const MAX_TEXT_WIDTH = WINDOW_WIDTH - (FRAME_PADDING * 4);
const SCROLL_SPEED = 30;

const Tab = enum {
    system,
    display,
    sound,
    input,
};

fn drawTextLine(text: []const u8, x: i32, y: i32) void {
    var buf: [1024]u8 = undefined;
    const len = @min(text.len, buf.len - 1);
    @memcpy(buf[0..len], text[0..len]);
    buf[len] = 0;

    // Measure text width
    const text_width = c.MeasureText(&buf, 20);
    if (text_width > MAX_TEXT_WIDTH) {
        // If text is too long, truncate it and add "..."
        var truncated_len = len;
        while (truncated_len > 0) {
            truncated_len -= 1;
            @memcpy(buf[0..truncated_len], text[0..truncated_len]);
            buf[truncated_len] = 0;
            if (c.MeasureText(&buf, 20) + c.MeasureText("...", 20) <= MAX_TEXT_WIDTH) {
                buf[truncated_len] = '.';
                buf[truncated_len + 1] = '.';
                buf[truncated_len + 2] = '.';
                buf[truncated_len + 3] = 0;
                break;
            }
        }
    }
    c.DrawText(&buf, x, y, 20, c.BLACK);
}

fn drawScrollableContent(content: []const u8, content_x: i32, content_y: i32, content_height: i32, scroll_offset: i32) i32 {
    var y: i32 = content_y + FRAME_PADDING - scroll_offset;
    var lines = std.mem.split(u8, content, "\n");
    var total_height: i32 = 0;

    // Draw only visible lines
    while (lines.next()) |line| {
        if (line.len > 0) {
            if (y + LINE_HEIGHT >= content_y and y <= content_y + content_height) {
                drawTextLine(line, content_x + FRAME_PADDING, y);
            }
            y += LINE_HEIGHT;
            total_height += LINE_HEIGHT;
        }
    }

    return total_height;
}

fn getSystemInfo() !std.ArrayList(u8) {
    var info = std.ArrayList(u8).init(std.heap.page_allocator);
    var buf: [1024]u8 = undefined;

    // Get current date/time
    const now = std.time.timestamp();
    const datetime = std.time.epoch.EpochSeconds{ .secs = @intCast(now) };
    const seconds_in_day = @rem(datetime.secs, 86400);
    const hours = @divFloor(seconds_in_day, 3600);
    const minutes = @divFloor(@rem(seconds_in_day, 3600), 60);
    const seconds = @rem(seconds_in_day, 60);
    const days_since_epoch = @divFloor(datetime.secs, 86400);
    const days_in_400_years = 146097;
    const days_in_100_years = 36524;
    const days_in_4_years = 1461;
    const days_in_year = 365;

    var remaining_days = @rem(days_since_epoch, days_in_400_years);
    const year_400 = @divFloor(days_since_epoch, days_in_400_years) * 400 + 1970;
    const century = @divFloor(remaining_days, days_in_100_years);
    remaining_days = @rem(remaining_days, days_in_100_years);
    const year_4 = @divFloor(remaining_days, days_in_4_years);
    remaining_days = @rem(remaining_days, days_in_4_years);
    const year_1 = @divFloor(remaining_days, days_in_year);
    remaining_days = @rem(remaining_days, days_in_year);

    const year = year_400 + century * 100 + year_4 * 4 + year_1;
    const month = @as(u8, 1); // TODO: Calculate month
    const day = @as(u8, 1); // TODO: Calculate day

    const datetime_str = try std.fmt.bufPrint(&buf, "{d:0>4}-{d:0>2}-{d:0>2}T{d:0>2}:{d:0>2}:{d:0>2}Z", .{
        year, month, day, hours, minutes, seconds,
    });
    try info.appendSlice("Current Date/Time: ");
    try info.appendSlice(datetime_str);
    try info.appendSlice("\n");

    // Get computer name
    const hostname = std.fs.cwd().readFileAlloc(std.heap.page_allocator, "/etc/hostname", 1024) catch "N/A";
    defer if (!std.mem.eql(u8, hostname, "N/A")) std.heap.page_allocator.free(hostname);
    try info.appendSlice("Computer Name: ");
    try info.appendSlice(std.mem.trim(u8, hostname, "\n"));
    try info.appendSlice("\n");

    // Get OS info
    const os_release = std.fs.cwd().readFileAlloc(std.heap.page_allocator, "/etc/os-release", 1024 * 1024) catch "PRETTY_NAME=N/A";
    defer if (!std.mem.eql(u8, os_release, "PRETTY_NAME=N/A")) std.heap.page_allocator.free(os_release);
    var os_lines = std.mem.split(u8, os_release, "\n");
    var os_name: []const u8 = "N/A";
    while (os_lines.next()) |line| {
        if (std.mem.startsWith(u8, line, "PRETTY_NAME=")) {
            os_name = std.mem.trim(u8, line["PRETTY_NAME=".len..], "\"\t ");
            break;
        }
    }

    // Get kernel version
    const uname = std.fs.cwd().readFileAlloc(std.heap.page_allocator, "/proc/version", 1024 * 1024) catch "N/A";
    defer if (!std.mem.eql(u8, uname, "N/A")) std.heap.page_allocator.free(uname);
    try info.appendSlice("Operating System: ");
    try info.appendSlice(os_name);
    if (!std.mem.eql(u8, uname, "N/A")) {
        try info.appendSlice(" (");
        try info.appendSlice(std.mem.trim(u8, uname, "\n"));
        try info.appendSlice(")");
    }
    try info.appendSlice("\n");

    // Get system language
    const locale_conf = std.fs.cwd().readFileAlloc(std.heap.page_allocator, "/etc/locale.conf", 1024) catch "LANG=N/A";
    defer if (!std.mem.eql(u8, locale_conf, "LANG=N/A")) std.heap.page_allocator.free(locale_conf);
    var locale_lines = std.mem.split(u8, locale_conf, "\n");
    var lang: []const u8 = "N/A";
    while (locale_lines.next()) |line| {
        if (std.mem.startsWith(u8, line, "LANG=")) {
            lang = std.mem.trim(u8, line["LANG=".len..], "\"\t ");
            break;
        }
    }
    try info.appendSlice("Language: ");
    try info.appendSlice(lang);
    try info.appendSlice("\n");

    // Get CPU info
    const cpu_info = std.fs.cwd().readFileAlloc(std.heap.page_allocator, "/proc/cpuinfo", 1024 * 1024) catch "N/A";
    defer if (!std.mem.eql(u8, cpu_info, "N/A")) std.heap.page_allocator.free(cpu_info);
    var cpu_lines = std.mem.split(u8, cpu_info, "\n");
    var cpu_model: []const u8 = "N/A";
    var cpu_speed: []const u8 = "N/A";
    while (cpu_lines.next()) |line| {
        if (std.mem.startsWith(u8, line, "model name")) {
            if (std.mem.indexOf(u8, line, ":")) |colon_idx| {
                cpu_model = std.mem.trim(u8, line[colon_idx + 1..], " \t");
            }
        } else if (std.mem.startsWith(u8, line, "cpu MHz")) {
            if (std.mem.indexOf(u8, line, ":")) |colon_idx| {
                cpu_speed = std.mem.trim(u8, line[colon_idx + 1..], " \t");
            }
        }
    }
    try info.appendSlice("Processor: ");
    try info.appendSlice(cpu_model);
    try info.appendSlice("\n");
    try info.appendSlice("CPU Speed: ");
    try info.appendSlice(cpu_speed);
    try info.appendSlice(" MHz\n");

    // Get GPU info
    const gpu_info = try std.process.Child.run(.{
        .allocator = std.heap.page_allocator,
        .argv = &[_][]const u8{"sh", "-c", "lspci -v | grep -A 1 -i vga"},
    });
    try info.appendSlice("GPU: ");
    if (gpu_info.term.Exited == 0 and gpu_info.stdout.len > 0) {
        var gpu_lines = std.mem.split(u8, gpu_info.stdout, "\n");
        if (gpu_lines.next()) |line| {
            if (std.mem.indexOf(u8, line, ":")) |colon_idx| {
                const full_desc = std.mem.trim(u8, line[colon_idx + 1..], " \t");
                
                // Try to extract the brand and model
                var gpu_name: []const u8 = "N/A";
                
                if (std.mem.indexOf(u8, full_desc, "AMD")) |_| {
                    if (std.mem.indexOf(u8, full_desc, "Radeon")) |radeon_idx| {
                        var words = std.mem.split(u8, full_desc[radeon_idx..], " ");
                        _ = words.next(); // Skip "Radeon"
                        var model_parts = std.ArrayList(u8).init(std.heap.page_allocator);
                        defer model_parts.deinit();
                        
                        // Collect up to 3 parts after "Radeon" to get full model number
                        var part_count: u8 = 0;
                        while (words.next()) |part| : (part_count += 1) {
                            if (part_count > 0) {
                                try model_parts.appendSlice(" ");
                            }
                            // Skip common non-model words
                            if (!std.mem.eql(u8, part, "Graphics") and
                                !std.mem.eql(u8, part, "Corporation") and
                                !std.mem.eql(u8, part, "Advanced") and
                                !std.mem.eql(u8, part, "Technologies") and
                                !std.mem.eql(u8, part, "Inc.") and
                                !std.mem.eql(u8, part, "[AMD/ATI]") and
                                !std.mem.eql(u8, part, "AMD") and
                                !std.mem.eql(u8, part, "ATI")) {
                                try model_parts.appendSlice(part);
                                if (part_count >= 2) break; // Get up to 3 parts (RX 6900 XT)
                            } else {
                                part_count -= 1; // Don't count skipped words
                            }
                        }
                        
                        if (model_parts.items.len > 0) {
                            gpu_name = try std.fmt.allocPrint(std.heap.page_allocator, "AMD Radeon {s}", .{model_parts.items});
                        } else {
                            gpu_name = "AMD Radeon";
                        }
                    } else {
                        gpu_name = "AMD";
                    }
                } else if (std.mem.indexOf(u8, full_desc, "NVIDIA")) |_| {
                    if (std.mem.indexOf(u8, full_desc, "GeForce")) |geforce_idx| {
                        var words = std.mem.split(u8, full_desc[geforce_idx..], " ");
                        _ = words.next(); // Skip "GeForce"
                        if (words.next()) |model| {
                            gpu_name = try std.fmt.allocPrint(std.heap.page_allocator, "NVIDIA GeForce {s}", .{model});
                        } else {
                            gpu_name = "NVIDIA GeForce";
                        }
                    } else {
                        gpu_name = "NVIDIA";
                    }
                } else if (std.mem.indexOf(u8, full_desc, "Intel")) |_| {
                    if (std.mem.indexOf(u8, full_desc, "HD Graphics")) |_| {
                        gpu_name = "Intel HD Graphics";
                    } else if (std.mem.indexOf(u8, full_desc, "UHD Graphics")) |_| {
                        gpu_name = "Intel UHD Graphics";
                    } else if (std.mem.indexOf(u8, full_desc, "Iris")) |_| {
                        gpu_name = "Intel Iris";
                    } else {
                        var words = std.mem.split(u8, full_desc, " ");
                        while (words.next()) |word| {
                            if (std.mem.indexOf(u8, word, "Graphics")) |_| {
                                gpu_name = try std.fmt.allocPrint(std.heap.page_allocator, "Intel {s}", .{word});
                                break;
                            }
                        }
                    }
                }
                
                try info.appendSlice(gpu_name);
                if (!std.mem.eql(u8, gpu_name, "N/A")) {
                    if (std.mem.indexOf(u8, gpu_name, "allocPrint")) |_| {
                        std.heap.page_allocator.free(gpu_name);
                    }
                }
            } else {
                try info.appendSlice("N/A");
            }
        } else {
            try info.appendSlice("N/A");
        }
    } else {
        try info.appendSlice("N/A");
    }
    try info.appendSlice("\n");

    // Get GPU VRAM
    const gpu_vram = try std.process.Child.run(.{
        .allocator = std.heap.page_allocator,
        .argv = &[_][]const u8{"sh", "-c", "glxinfo | grep 'Video memory' || glxinfo | grep 'Dedicated video memory'"},
    });
    try info.appendSlice("GPU VRAM: ");
    if (gpu_vram.term.Exited == 0 and gpu_vram.stdout.len > 0) {
        var vram_lines = std.mem.split(u8, gpu_vram.stdout, "\n");
        if (vram_lines.next()) |line| {
            if (std.mem.indexOf(u8, line, ":")) |colon_idx| {
                try info.appendSlice(std.mem.trim(u8, line[colon_idx + 1..], " \t"));
            } else {
                try info.appendSlice(line);
            }
        } else {
            try info.appendSlice("N/A");
        }
    } else {
        try info.appendSlice("N/A");
    }
    try info.appendSlice("\n");

    // Get memory info
    const mem_info = std.fs.cwd().readFileAlloc(std.heap.page_allocator, "/proc/meminfo", 1024 * 1024) catch "N/A";
    defer if (!std.mem.eql(u8, mem_info, "N/A")) std.heap.page_allocator.free(mem_info);
    var mem_lines = std.mem.split(u8, mem_info, "\n");
    var total_kb: u64 = 0;
    while (mem_lines.next()) |line| {
        if (std.mem.startsWith(u8, line, "MemTotal")) {
            if (std.mem.indexOf(u8, line, ":")) |colon_idx| {
                const total_str = std.mem.trim(u8, line[colon_idx + 1..], " \tkB");
                total_kb = std.fmt.parseInt(u64, total_str, 10) catch 0;
                break;
            }
        }
    }
    const total_mb = total_kb / 1024;
    try info.appendSlice("Memory: ");
    try std.fmt.format(info.writer(), "{d} MB\n", .{total_mb});

    // Get OpenGL info
    try info.appendSlice("OpenGL: ");
    const gl_info = try std.process.Child.run(.{
        .allocator = std.heap.page_allocator,
        .argv = &[_][]const u8{"sh", "-c", "glxinfo | grep 'OpenGL version'"},
    });
    if (gl_info.term.Exited == 0) {
        var gl_lines = std.mem.split(u8, gl_info.stdout, "\n");
        if (gl_lines.next()) |line| {
            if (std.mem.indexOf(u8, line, ":")) |colon_idx| {
                try info.appendSlice(std.mem.trim(u8, line[colon_idx + 1..], " \t"));
            } else {
                try info.appendSlice(line);
            }
        } else {
            try info.appendSlice("N/A");
        }
    } else {
        try info.appendSlice("N/A");
    }
    try info.appendSlice("\n");

    // Check for Vulkan support
    const vulkan = try std.process.Child.run(.{
        .allocator = std.heap.page_allocator,
        .argv = &[_][]const u8{"vulkaninfo", "--summary"},
    });
    try info.appendSlice("Vulkan: ");
    try info.appendSlice(if (vulkan.term.Exited == 0) "Available" else "Not available");
    try info.appendSlice("\n");

    return info;
}

fn getSoundInfo() !std.ArrayList(u8) {
    var info = std.ArrayList(u8).init(std.heap.page_allocator);

    // Check for PipeWire
    const pipewire = try std.process.Child.run(.{
        .allocator = std.heap.page_allocator,
        .argv = &[_][]const u8{"pgrep", "pipewire"},
    });
    const pipewire_running = pipewire.term.Exited == 0;

    // Check for PulseAudio
    const pulseaudio = try std.process.Child.run(.{
        .allocator = std.heap.page_allocator,
        .argv = &[_][]const u8{"pgrep", "pulseaudio"},
    });
    const pulse_running = pulseaudio.term.Exited == 0;

    if (pipewire_running) {
        try info.appendSlice("Audio Server: PipeWire\n");
    } else if (pulse_running) {
        try info.appendSlice("Audio Server: PulseAudio\n");
    } else {
        try info.appendSlice("Audio Server: N/A\n");
    }

    // Get audio devices
    const devices = std.fs.cwd().readFileAlloc(std.heap.page_allocator, "/proc/asound/cards", 1024 * 1024) catch "N/A";
    defer if (!std.mem.eql(u8, devices, "N/A")) std.heap.page_allocator.free(devices);
    try info.appendSlice("\nAudio Devices:\n");
    if (!std.mem.eql(u8, devices, "N/A")) {
        var device_lines = std.mem.split(u8, devices, "\n");
        while (device_lines.next()) |line| {
            if (line.len > 0) {
                try info.appendSlice(std.mem.trim(u8, line, " \t"));
                try info.appendSlice("\n");
            }
        }
    } else {
        try info.appendSlice("N/A\n");
    }

    return info;
}

fn getDisplayInfo() !std.ArrayList(u8) {
    var info = std.ArrayList(u8).init(std.heap.page_allocator);

    // Get compositor information
    try info.appendSlice("Display Server: ");
    const wayland_display = std.process.getEnvVarOwned(std.heap.page_allocator, "WAYLAND_DISPLAY") catch null;
    if (wayland_display) |display| {
        defer std.heap.page_allocator.free(display);
        try info.appendSlice("Wayland");
        try info.appendSlice("\n");
    } else {
        const x11_display = std.process.getEnvVarOwned(std.heap.page_allocator, "DISPLAY") catch null;
        if (x11_display) |display| {
            defer std.heap.page_allocator.free(display);
            try info.appendSlice("X11");
            // Try to get compositor info for X11
            const compositor = try std.process.Child.run(.{
                .allocator = std.heap.page_allocator,
                .argv = &[_][]const u8{"sh", "-c", "ps aux | grep -E 'picom|compton|xcompmgr|compiz' | grep -v grep || true"},
            });
            if (compositor.stdout.len > 0) {
                var comp_lines = std.mem.split(u8, compositor.stdout, "\n");
                if (comp_lines.next()) |line| {
                    if (std.mem.indexOf(u8, line, "picom")) |_| {
                        try info.appendSlice(" (Picom)");
                    } else if (std.mem.indexOf(u8, line, "compton")) |_| {
                        try info.appendSlice(" (Compton)");
                    } else if (std.mem.indexOf(u8, line, "xcompmgr")) |_| {
                        try info.appendSlice(" (Xcompmgr)");
                    } else if (std.mem.indexOf(u8, line, "compiz")) |_| {
                        try info.appendSlice(" (Compiz)");
                    }
                }
            }
            try info.appendSlice("\n");
        } else {
            try info.appendSlice("N/A\n");
        }
    }
    try info.appendSlice("\n");

    // Get monitor count
    const monitor_count = c.GetMonitorCount();
    try std.fmt.format(info.writer(), "Number of Monitors: {d}\n\n", .{monitor_count});

    // Get information for each monitor
    var i: i32 = 0;
    while (i < monitor_count) : (i += 1) {
        const monitor_name = c.GetMonitorName(i);
        const monitor_width = c.GetMonitorWidth(i);
        const monitor_height = c.GetMonitorHeight(i);
        const refresh_rate = c.GetMonitorRefreshRate(i);
        const position = c.GetMonitorPosition(i);

        try std.fmt.format(info.writer(), "Monitor {d}:\n", .{i + 1});
        try std.fmt.format(info.writer(), "  Name: {s}\n", .{monitor_name});
        try std.fmt.format(info.writer(), "  Resolution: {d}x{d}\n", .{ monitor_width, monitor_height });
        try std.fmt.format(info.writer(), "  Refresh Rate: {d}Hz\n", .{refresh_rate});
        try std.fmt.format(info.writer(), "  Position: ({d}, {d})\n", .{ position.x, position.y });
        try info.appendSlice("\n");
    }

    // Get OpenGL info
    try info.appendSlice("Graphics API: ");
    const gl_info = try std.process.Child.run(.{
        .allocator = std.heap.page_allocator,
        .argv = &[_][]const u8{"sh", "-c", "glxinfo | grep 'OpenGL version'"},
    });
    if (gl_info.term.Exited == 0) {
        var gl_lines = std.mem.split(u8, gl_info.stdout, "\n");
        if (gl_lines.next()) |line| {
            if (std.mem.indexOf(u8, line, ":")) |colon_idx| {
                try info.appendSlice(std.mem.trim(u8, line[colon_idx + 1..], " \t"));
            } else {
                try info.appendSlice(line);
            }
        } else {
            try info.appendSlice("N/A");
        }
    } else {
        try info.appendSlice("N/A");
    }
    try info.appendSlice("\n");

    return info;
}

fn getNetworkInfo() !std.ArrayList(u8) {
    var info = std.ArrayList(u8).init(std.heap.page_allocator);

    // Get network interfaces
    const interfaces = std.fs.cwd().readFileAlloc(std.heap.page_allocator, "/proc/net/dev", 1024 * 1024) catch "N/A";
    defer if (!std.mem.eql(u8, interfaces, "N/A")) std.heap.page_allocator.free(interfaces);

    try info.appendSlice("Network Interfaces:\n");
    if (!std.mem.eql(u8, interfaces, "N/A")) {
        var lines = std.mem.split(u8, interfaces, "\n");
        var skip_count: u32 = 0;
        while (lines.next()) |line| {
            // Skip header lines
            if (skip_count < 2) {
                skip_count += 1;
                continue;
            }
            if (line.len > 0) {
                if (std.mem.indexOf(u8, line, ":")) |colon_idx| {
                    const iface = std.mem.trim(u8, line[0..colon_idx], " \t");
                    if (iface.len > 0) {
                        try info.appendSlice("  ");
                        try info.appendSlice(iface);
                        try info.appendSlice("\n");

                        // Get IP address for this interface
                        const ip = try std.process.Child.run(.{
                            .allocator = std.heap.page_allocator,
                            .argv = &[_][]const u8{"sh", "-c", try std.fmt.allocPrint(std.heap.page_allocator, "ip addr show {} | grep 'inet ' | awk '{{print $2}}'", .{iface})},
                        });
                        if (ip.term.Exited == 0 and ip.stdout.len > 0) {
                            try info.appendSlice("    IP: ");
                            try info.appendSlice(std.mem.trim(u8, ip.stdout, " \n"));
                            try info.appendSlice("\n");
                        }
                    }
                }
            }
        }
    } else {
        try info.appendSlice("  N/A\n");
    }

    return info;
}

fn getInputInfo() !std.ArrayList(u8) {
    var info = std.ArrayList(u8).init(std.heap.page_allocator);

    // Mouse information
    try info.appendSlice("Mouse:\n");
    try std.fmt.format(info.writer(), "  Position: ({d}, {d})\n", .{ c.GetMouseX(), c.GetMouseY() });
    try std.fmt.format(info.writer(), "  Wheel: {d}\n", .{c.GetMouseWheelMove()});
    try info.appendSlice("  Buttons: ");
    if (c.IsMouseButtonDown(c.MOUSE_BUTTON_LEFT)) try info.appendSlice("Left ");
    if (c.IsMouseButtonDown(c.MOUSE_BUTTON_RIGHT)) try info.appendSlice("Right ");
    if (c.IsMouseButtonDown(c.MOUSE_BUTTON_MIDDLE)) try info.appendSlice("Middle ");
    try info.appendSlice("\n\n");

    // Keyboard information
    try info.appendSlice("Keyboard:\n");
    try info.appendSlice("  Layout: ");
    const layout = try std.process.Child.run(.{
        .allocator = std.heap.page_allocator,
        .argv = &[_][]const u8{"sh", "-c", "setxkbmap -query | grep layout | awk '{print $2}'"},
    });
    if (layout.term.Exited == 0) {
        try info.appendSlice(std.mem.trim(u8, layout.stdout, " \n"));
    } else {
        try info.appendSlice("N/A");
    }
    try info.appendSlice("\n");

    // Get input devices from /proc/bus/input/devices
    const devices = std.fs.cwd().readFileAlloc(std.heap.page_allocator, "/proc/bus/input/devices", 1024 * 1024) catch "N/A";
    defer if (!std.mem.eql(u8, devices, "N/A")) std.heap.page_allocator.free(devices);

    try info.appendSlice("\nInput Devices:\n");
    if (!std.mem.eql(u8, devices, "N/A")) {
        var lines = std.mem.split(u8, devices, "\n");
        var current_name: []const u8 = "";
        while (lines.next()) |line| {
            if (std.mem.startsWith(u8, line, "N: Name=")) {
                current_name = std.mem.trim(u8, line["N: Name=".len..], "\"");
                try info.appendSlice("  ");
                try info.appendSlice(current_name);
                try info.appendSlice("\n");
            }
        }
    } else {
        try info.appendSlice("  N/A\n");
    }

    return info;
}

fn saveInformation(system_info: []const u8, display_info: []const u8, sound_info: []const u8, input_info: []const u8) !void {
    var buf: [1024]u8 = undefined;

    // Get current date/time for filename
    const now = std.time.timestamp();
    const datetime = std.time.epoch.EpochSeconds{ .secs = @intCast(now) };
    const seconds_in_day = @rem(datetime.secs, 86400);
    const hours = @divFloor(seconds_in_day, 3600);
    const minutes = @divFloor(@rem(seconds_in_day, 3600), 60);
    const seconds = @rem(seconds_in_day, 60);
    const days_since_epoch = @divFloor(datetime.secs, 86400);
    const days_in_400_years = 146097;
    const days_in_100_years = 36524;
    const days_in_4_years = 1461;
    const days_in_year = 365;

    var remaining_days = @rem(days_since_epoch, days_in_400_years);
    const year_400 = @divFloor(days_since_epoch, days_in_400_years) * 400 + 1970;
    const century = @divFloor(remaining_days, days_in_100_years);
    remaining_days = @rem(remaining_days, days_in_100_years);
    const year_4 = @divFloor(remaining_days, days_in_4_years);
    remaining_days = @rem(remaining_days, days_in_4_years);
    const year_1 = @divFloor(remaining_days, days_in_year);
    remaining_days = @rem(remaining_days, days_in_year);

    const year = year_400 + century * 100 + year_4 * 4 + year_1;
    const month = @as(u8, 1); // TODO: Calculate month
    const day = @as(u8, 1); // TODO: Calculate day

    const filename = try std.fmt.bufPrint(&buf, "zxdiag-{d:0>4}{d:0>2}{d:0>2}-{d:0>2}{d:0>2}{d:0>2}.log", .{
        year, month, day, hours, minutes, seconds,
    });

    // Open file dialog using zenity
    const zenity = try std.process.Child.run(.{
        .allocator = std.heap.page_allocator,
        .argv = &[_][]const u8{
            "zenity",
            "--file-selection",
            "--save",
            "--filename",
            filename,
            "--title",
            "Save System Information",
            "--file-filter",
            "Log files (*.log) | *.log",
        },
    });

    if (zenity.term.Exited == 0) {
        const save_path = std.mem.trim(u8, zenity.stdout, " \n\r\t");
        var file = try std.fs.cwd().createFile(save_path, .{});
        defer file.close();

        // Write all information to file
        try file.writeAll("=== System Information ===\n\n");
        try file.writeAll(system_info);
        try file.writeAll("\n=== Display Information ===\n\n");
        try file.writeAll(display_info);
        try file.writeAll("\n=== Sound Information ===\n\n");
        try file.writeAll(sound_info);
        try file.writeAll("\n=== Input Information ===\n\n");
        try file.writeAll(input_info);
    }
}

pub fn main() void {
    // Initialize window
    c.InitWindow(WINDOW_WIDTH, WINDOW_HEIGHT, "zxdiag");
    c.SetTargetFPS(60);

    var current_tab: Tab = .system;
    var exit_requested = false;
    var scroll_offset: i32 = 0;

    // Get system and sound information
    var system_info = getSystemInfo() catch |err| {
        std.debug.print("Error getting system info: {}\n", .{err});
        return;
    };
    defer system_info.deinit();

    var display_info = getDisplayInfo() catch |err| {
        std.debug.print("Error getting display info: {}\n", .{err});
        return;
    };
    defer display_info.deinit();

    var sound_info = getSoundInfo() catch |err| {
        std.debug.print("Error getting sound info: {}\n", .{err});
        return;
    };
    defer sound_info.deinit();

    var input_info = getInputInfo() catch |err| {
        std.debug.print("Error getting input info: {}\n", .{err});
        return;
    };
    defer input_info.deinit();

    // Main game loop
    while (!c.WindowShouldClose() and !exit_requested) {
        // Update input info every frame
        input_info.clearRetainingCapacity();
        input_info = getInputInfo() catch |err| {
            std.debug.print("Error updating input info: {}\n", .{err});
            continue;
        };

        // Handle scrolling
        const wheel_move = c.GetMouseWheelMove();
        if (wheel_move != 0) {
            scroll_offset -= @as(i32, @intFromFloat(wheel_move * SCROLL_SPEED));
            if (scroll_offset < 0) scroll_offset = 0;
        }

        c.BeginDrawing();
        c.ClearBackground(c.RAYWHITE);

        // Draw tabs at top left
        const tab_spacing = 5;
        const tab_x = 10;
        const tab_y = 10;

        // Reset scroll offset when changing tabs
        const old_tab = current_tab;

        // System tab
        if (current_tab == .system) {
            c.DrawRectangle(tab_x, tab_y, TAB_WIDTH, TAB_HEIGHT, c.LIGHTGRAY);
        }
        if (c.GuiButton(.{
            .x = tab_x,
            .y = tab_y,
            .width = TAB_WIDTH,
            .height = TAB_HEIGHT,
        }, "System")) {
            current_tab = .system;
        }

        // Display tab
        if (current_tab == .display) {
            c.DrawRectangle(tab_x + TAB_WIDTH + tab_spacing, tab_y, TAB_WIDTH, TAB_HEIGHT, c.LIGHTGRAY);
        }
        if (c.GuiButton(.{
            .x = tab_x + TAB_WIDTH + tab_spacing,
            .y = tab_y,
            .width = TAB_WIDTH,
            .height = TAB_HEIGHT,
        }, "Display")) {
            current_tab = .display;
        }

        // Sound tab
        if (current_tab == .sound) {
            c.DrawRectangle(tab_x + (TAB_WIDTH + tab_spacing) * 2, tab_y, TAB_WIDTH, TAB_HEIGHT, c.LIGHTGRAY);
        }
        if (c.GuiButton(.{
            .x = tab_x + (TAB_WIDTH + tab_spacing) * 2,
            .y = tab_y,
            .width = TAB_WIDTH,
            .height = TAB_HEIGHT,
        }, "Sound")) {
            current_tab = .sound;
        }

        // Input tab
        if (current_tab == .input) {
            c.DrawRectangle(tab_x + (TAB_WIDTH + tab_spacing) * 3, tab_y, TAB_WIDTH, TAB_HEIGHT, c.LIGHTGRAY);
        }
        if (c.GuiButton(.{
            .x = tab_x + (TAB_WIDTH + tab_spacing) * 3,
            .y = tab_y,
            .width = TAB_WIDTH,
            .height = TAB_HEIGHT,
        }, "Input")) {
            current_tab = .input;
        }

        // If tab changed, reset scroll
        if (old_tab != current_tab) {
            scroll_offset = 0;
        }

        // Draw tab content
        const content_x = tab_x;
        const content_y = tab_y + TAB_HEIGHT + 20;
        const content_width = WINDOW_WIDTH - (content_x * 2);
        const content_height = WINDOW_HEIGHT - content_y - (BUTTON_HEIGHT + 40);

        // Draw frame
        c.DrawRectangleLinesEx(.{
            .x = content_x,
            .y = content_y,
            .width = content_width,
            .height = content_height,
        }, 2, c.GRAY);

        // Enable scissor test to clip content
        c.BeginScissorMode(content_x, content_y, content_width, content_height);

        // Draw content
        const total_height = switch (current_tab) {
            .system => drawScrollableContent(system_info.items, content_x, content_y, content_height, scroll_offset),
            .display => drawScrollableContent(display_info.items, content_x, content_y, content_height, scroll_offset),
            .sound => drawScrollableContent(sound_info.items, content_x, content_y, content_height, scroll_offset),
            .input => drawScrollableContent(input_info.items, content_x, content_y, content_height, scroll_offset),
        };

        // Limit scroll offset based on content height
        const max_scroll = @max(0, total_height - content_height + FRAME_PADDING * 2);
        if (scroll_offset > max_scroll) scroll_offset = max_scroll;

        c.EndScissorMode();

        // Draw scroll bar if needed
        if (total_height > content_height) {
            const scroll_bar_width = 10;
            const scroll_bar_height = @as(f32, @floatFromInt(content_height)) * @as(f32, @floatFromInt(content_height)) / @as(f32, @floatFromInt(total_height));
            const scroll_bar_y = content_y + @as(i32, @intFromFloat(@as(f32, @floatFromInt(scroll_offset)) * @as(f32, @floatFromInt(content_height)) / @as(f32, @floatFromInt(total_height))));

            c.DrawRectangle(
                content_x + content_width - scroll_bar_width - 2,
                scroll_bar_y,
                scroll_bar_width,
                @as(i32, @intFromFloat(scroll_bar_height)),
                c.GRAY,
            );
        }

        // Draw buttons at bottom right
        const button_spacing = 10;
        const button_y = WINDOW_HEIGHT - BUTTON_HEIGHT - 20;
        const save_x = WINDOW_WIDTH - (BUTTON_WIDTH * 2) - button_spacing - 20;
        const exit_x = WINDOW_WIDTH - BUTTON_WIDTH - 20;

        if (c.GuiButton(.{
            .x = save_x,
            .y = button_y,
            .width = BUTTON_WIDTH,
            .height = BUTTON_HEIGHT,
        }, "Save Information")) {
            saveInformation(system_info.items, display_info.items, sound_info.items, input_info.items) catch |err| {
                std.debug.print("Error saving information: {}\n", .{err});
            };
        }

        if (c.GuiButton(.{
            .x = exit_x,
            .y = button_y,
            .width = BUTTON_WIDTH,
            .height = BUTTON_HEIGHT,
        }, "Exit")) {
            exit_requested = true;
        }

        c.EndDrawing();
    }

    c.CloseWindow();
} 