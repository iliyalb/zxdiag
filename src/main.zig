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

        // Draw tabs at top left
        const tab_spacing = 5;
        const tab_x = 10;
        const tab_y = 10;

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

        // Sound tab
        if (current_tab == .sound) {
            c.DrawRectangle(tab_x + TAB_WIDTH + tab_spacing, tab_y, TAB_WIDTH, TAB_HEIGHT, c.LIGHTGRAY);
        }
        if (c.GuiButton(.{
            .x = tab_x + TAB_WIDTH + tab_spacing,
            .y = tab_y,
            .width = TAB_WIDTH,
            .height = TAB_HEIGHT,
        }, "Sound")) {
            current_tab = .sound;
        }

        // Draw tab content
        switch (current_tab) {
            .system => {
                // System tab content will go here
                c.DrawText("System Information", tab_x, tab_y + TAB_HEIGHT + 20, 20, c.BLACK);
            },
            .sound => {
                // Sound tab content will go here
                c.DrawText("Sound Information", tab_x, tab_y + TAB_HEIGHT + 20, 20, c.BLACK);
            },
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
            // Save functionality will be implemented later
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