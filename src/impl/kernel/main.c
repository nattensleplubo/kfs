#include "print.h"

void    keyboard_routine(void) {
    unsigned char scancode;
    char keycode;

    scancode = in_port(KEY_STATUS);
    if (scancode & 0x01) {
        keycode = in_port(KEY_PRESSED);
        if (keycode < 0)
            return;
        else
            print_clear();
    }
}

void kernel_main() {
    print_set_color(PRINT_COLOR_BLUE, PRINT_COLOR_WHITE);
    print_clear();
    print_str("        :::     :::::::: \n");
    print_str("      :+:     :+:    :+: \n");
    print_str("    +:+ +:+        +:+   \n");
    print_str("  +#+  +:+      +#+      \n");
    print_str("+#+#+#+#+#+  +#+         \n");
    print_str("     #+#   #+#           \n");
    print_str("    ###  ##########      \n");
    print_str("Welcome to KFS           \n");
    while (1) {
        keyboard_routine();
    }
}
