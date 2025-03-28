const std = @import("std");
const c = @cImport({
    @cInclude("raylib.h");
    @cInclude("raygui.h");
});

const WINDOW_WIDTH = 800;
const WINDOW_HEIGHT = 600;
const TAB_HEIGHT = 40;
const BUTTON_HEIGHT = 30;

const Tab = enum {
    system,
    sound,
};

pub fn main() void {
    // Initialize window
    c.InitWindow(WINDOW_WIDTH, WINDOW_HEIGHT, "zxdiag");
    c.SetTargetFPS(60);

    var current_tab: Tab = .system;
    var exit_requested = false;

    // Main game loop
    while (!c.WindowShouldClose() and !exit_requested) {
        c.BeginDrawing();
        c.ClearBackground(c.RAYWHITE);

        // Draw tabs
        const tab_width = WINDOW_WIDTH / 2;
        if (c.GuiButton(.{
            .x = 0,
            .y = 0,
            .width = tab_width,
            .height = TAB_HEIGHT,
        }, "System")) {
            current_tab = .system;
        }
        if (c.GuiButton(.{
            .x = tab_width,
            .y = 0,
            .width = tab_width,
            .height = TAB_HEIGHT,
        }, "Sound")) {
            current_tab = .sound;
        }

        // Draw tab content
        switch (current_tab) {
            .system => {
                // System tab content will go here
                c.DrawText("System Information", 10, TAB_HEIGHT + 10, 20, c.BLACK);
            },
            .sound => {
                // Sound tab content will go here
                c.DrawText("Sound Information", 10, TAB_HEIGHT + 10, 20, c.BLACK);
            },
        }

        // Draw buttons at the bottom
        const button_width = 150;
        const button_spacing = 20;
        const total_buttons_width = (button_width * 2) + button_spacing;
        const start_x = (WINDOW_WIDTH - total_buttons_width) / 2;

        if (c.GuiButton(.{
            .x = start_x,
            .y = WINDOW_HEIGHT - BUTTON_HEIGHT - 20,
            .width = button_width,
            .height = BUTTON_HEIGHT,
        }, "Save Information")) {
            // Save functionality will be implemented later
        }

        if (c.GuiButton(.{
            .x = start_x + button_width + button_spacing,
            .y = WINDOW_HEIGHT - BUTTON_HEIGHT - 20,
            .width = button_width,
            .height = BUTTON_HEIGHT,
        }, "Exit")) {
            exit_requested = true;
        }

        c.EndDrawing();
    }

    c.CloseWindow();
} 