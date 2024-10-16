#ifndef KERNEL_H

# define KERNEL_H

# include "types.h"
# include <stdarg.h>

extern unsigned char keyboard_map[128];

// DEFINES
#define KEY_PRESSED 0x60
#define KEY_STATUS 0x64
#define MAX_COMMAND_LENGTH 256
#define GDT_ADDRESS 0x00000800
#define GDT_ENTRIES 3  // Adjust based on how many entries you need
extern struct gdt_entry *const gdt;

// STRUCTS
struct gdt_entry {
    uint16_t limit_low;
    uint16_t base_low;
    uint8_t base_middle;
    uint8_t access;
    uint8_t granularity;
    uint8_t base_high;
} __attribute__((packed));

struct gdt_ptr {
    uint16_t limit;
    uint32_t base;
} __attribute__((packed));

// MAIN FUNCTIONS
void kernel_main(void);

// LIBC FUNCTIONS
size_t strlen(const char *str);
int strcmp(const char *s1, const char *s2);
char *strcpy(char *dest, const char *src);
unsigned char *memcpy(unsigned char *destptr, const unsigned char *srcptr, int size);
void *memset(void *bufptr, int value, int size);

// ASM FUNCTIONS
extern char in_port(unsigned short port);
extern void outw(unsigned short port, unsigned short value);

// PRINTING FUNCTIONS
void terminal_putstr(const char *str);
void terminal_putchar(char c);
void terminal_putentryat(char c, uint8_t color, size_t x, size_t y);
void    int_to_str(int num, char *str, int base);

// GDT FUNCTIONS
void gdt_set_gate(int num, uint32_t base, uint32_t limit, uint8_t access, uint8_t gran);
void gdt_install();
extern void gdt_flush();


// GLOBALS
extern unsigned int command_index;

#endif