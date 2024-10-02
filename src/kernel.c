#include "kernel.h"

enum vga_color {
	VGA_COLOR_BLACK = 0,
	VGA_COLOR_BLUE = 1,
	VGA_COLOR_GREEN = 2,
	VGA_COLOR_CYAN = 3,
	VGA_COLOR_RED = 4,
	VGA_COLOR_MAGENTA = 5,
	VGA_COLOR_BROWN = 6,
	VGA_COLOR_LIGHT_GREY = 7,
	VGA_COLOR_DARK_GREY = 8,
	VGA_COLOR_LIGHT_BLUE = 9,
	VGA_COLOR_LIGHT_GREEN = 10,
	VGA_COLOR_LIGHT_CYAN = 11,
	VGA_COLOR_LIGHT_RED = 12,
	VGA_COLOR_LIGHT_MAGENTA = 13,
	VGA_COLOR_LIGHT_BROWN = 14,
	VGA_COLOR_WHITE = 15,
};

static const size_t VGA_WIDTH = 80;
static const size_t VGA_HEIGHT = 25;

size_t terminal_row;
size_t terminal_col;
uint8_t terminal_color;
uint16_t *terminal_buffer;
unsigned int command_index;

char command_buffer[MAX_COMMAND_LENGTH];

// ########## LIBC DUPES ##########

void *memset(void *bufptr, int value, int size) {
    unsigned char *buffer = (unsigned char *)bufptr;
    for (int i = 0; i < size; i++) {
        buffer[i] = (unsigned char)value;
    }
    return bufptr;
}

unsigned char *memcpy(unsigned char *destptr, const unsigned char *srcptr, int size) {
    unsigned char *dst = (unsigned char *)destptr;
    const unsigned char *src = (const unsigned char*)srcptr;
    for (int i = 0; i < size; i++) {
        dst[i] = src[i];
    }
    return destptr;
}

size_t strlen(const char *str) {
    size_t len = 0;
    while (str[len])
        len++;
    return len;
}

int strcmp(const char *s1, const char *s2) {
    while (*s1 && (*s1 == *s2)) {
        s1++;
        s2++;
    }
    return *(const unsigned char*)s1 - *(const unsigned char*)s2;
}

char *strcpy(char *dest, const char *src) {
    char *d = dest;
    while ((*d++ = *src++));
    return dest;
}

// ########## VGA FUNCTIONS ##########

static inline uint8_t vga_entry_color(enum vga_color fg, enum vga_color bg) 
{
	return fg | bg << 4;
}

static inline uint16_t vga_entry(unsigned char uc, uint8_t color) 
{
	return (uint16_t) uc | (uint16_t) color << 8;
}

// ########## KERNEL PUTSTR FUNCTIONS ##########

void terminal_setcolor(uint8_t color) {
    terminal_color = color;
}

void terminal_putentryat(char c, uint8_t color, size_t x, size_t y) {
    const size_t index = y * VGA_WIDTH + x;
    terminal_buffer[index] = vga_entry(c, color);
}

void terminal_putchar(char c) {
    if (c == '\n') {
        terminal_row++;
        terminal_col = 0;
    }
    else {
        terminal_putentryat(c, terminal_color, terminal_col, terminal_row);
        if (++terminal_col == VGA_WIDTH) {
            terminal_col = 0;
            if (++terminal_row == VGA_HEIGHT)
                terminal_row = 0;
        }
    }
}

void terminal_putstr(const char *str) {
    size_t size = strlen(str);
    for (size_t i = 0; i < size; i++)
        terminal_putchar(str[i]);
}
// ########## KERNEL KEYBOARD FUNCTIONS ##########

void process_command() {
    if (strcmp(command_buffer, "help") == 0)
        terminal_putstr("\nAvailable commands: help, version\n");
    else if (strcmp(command_buffer, "exit") == 0) {
        terminal_putstr("\nBye bye...\n");
        outw(0x604, 0x2000);
    }
    else if (strcmp(command_buffer, "version") == 0)
        terminal_putstr("\nNathouOs version 0.1\n");
    else {
        terminal_putstr("\nUnknown command: ");
        terminal_putstr(command_buffer);
        terminal_putstr("\n");
    }
}

void terminal_shell(char c) {
    if (terminal_col == 0)
        terminal_putstr("$> ");
    if (c == '\b') { //backspace
        if (command_index > 0) {
            command_index--;
            command_buffer[command_index] = ' ';
            terminal_col--;
            terminal_putchar(' ');
            terminal_col--;
        }
    }
    else if (c == '\n') { // enter
        command_buffer[command_index] = '\0';
        process_command();
        command_index = 0;
        terminal_row++;
        terminal_col = 0;
        terminal_putstr("$> ");
    }
    else if (command_index < MAX_COMMAND_LENGTH - 1) {
        command_buffer[command_index++] = c;
        terminal_putchar(c);
    }
}

void keyboard_routine(void) {
    unsigned char scancode;
    char keycode;

    if (terminal_row > VGA_HEIGHT) {
        terminal_row = 0;
        for (size_t y = 0; y < VGA_HEIGHT; y++) {
            for (size_t x = 0; x < VGA_WIDTH; x++) {
                const size_t index = y * VGA_WIDTH + x;
                terminal_buffer[index] = vga_entry(' ', terminal_color);
            }
        }
    }
    scancode = in_port(KEY_STATUS);
    if (scancode & 0x01) {
        keycode = in_port(KEY_PRESSED);
        if (keycode < 0)
            return;
        else {
            terminal_shell(keyboard_map[keycode]);
        }
    }
}

// ########## KERNEL MAIN FUNCTIONS ##########

void terminal_init(void) {
    terminal_row = 0;
    terminal_col = 0;
    command_index = 0;
    terminal_color = vga_entry_color(VGA_COLOR_LIGHT_BLUE, VGA_COLOR_BLACK);
    terminal_buffer = (uint16_t*)0xB8000;
    for (size_t y = 0; y < VGA_HEIGHT; y++) {
        for (size_t x = 0; x < VGA_WIDTH; x++) {
            const size_t index = y * VGA_WIDTH + x;
            terminal_buffer[index] = vga_entry(' ', terminal_color);
        }
    }
    for (int i = 0; i < MAX_COMMAND_LENGTH - 1; i++)
        command_buffer[i] = ' ';
    command_buffer[MAX_COMMAND_LENGTH - 1] = '\0';
}

void kernel_main(void) {
    terminal_init();
    terminal_putstr(" _   ___     \n| |_|  _|___ \n| '_|  _|_ -|\n|_,_|_| |___|42\n             \n");
    terminal_putstr("/// Welcome to NathouOs \\\\\\\n\n$> ");
    terminal_color = vga_entry_color(VGA_COLOR_WHITE, VGA_COLOR_BLACK);
    while (1)
        keyboard_routine();
} 
