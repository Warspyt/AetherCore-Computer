#include <stdint.h>
#include <string.h>

// Función para cargar programa en memoria
void load_program(uint64_t program[], int n, int base_addr, uint8_t *MEM) {
    for (int i = 0; i < n; i++) {
        memcpy(&MEM[base_addr + i * 8], &program[i], sizeof(uint64_t));
    }
}
