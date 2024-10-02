#ifndef KERNEL_H

# define KERNEL_H

# include "types.h"

extern unsigned char keyboard_map[128];

// DEFINES
#define KEY_PRESSED 0x60
#define KEY_STATUS 0x64
#define MAX_COMMAND_LENGTH 256

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



// GLOBALS
extern unsigned int command_index;

#endif