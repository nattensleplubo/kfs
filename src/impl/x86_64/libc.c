#include "print.h"

size_t  strlen(char *str) {
    for (size_t i = 0; 1; i++) {
        char character = (uint8_t) str[i];
        if (character == '\0')
            return (i);
    }
}

int strcmp(const char *s1, const char *s2) {
    while (*s1 && (*s1 == *s2)) {
        s1++;
        s2++;
    }
    return (*(const unsigned char*)s1 - *(const unsigned char*)s2);
}

char *strcpy(char *dest, const char *src) {
    char *d = dest;
    while ((*d++ = *src++));
    return dest;
}