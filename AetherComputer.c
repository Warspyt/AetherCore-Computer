#include <stdio.h>
#include <stdint.h>
#include <string.h>
#include "cpu.h"

// Declaración de load_program desde memory.c
void load_program(uint64_t program[], int n, int base_addr, uint8_t *MEM);

// Memoria global
uint8_t MEM[MEM_SIZE];

// Función para cargar un archivo binario en memoria
int load_from_file(const char *filename, uint8_t *MEM, int base_addr) {
    FILE *f = fopen(filename, "rb");
    if (!f) {
        perror("Error al abrir el archivo");
        return -1;
    }

    int addr = base_addr;
    size_t bytes_read;
    uint64_t instr;

    while ((bytes_read = fread(&instr, sizeof(uint64_t), 1, f)) == 1) {
        memcpy(&MEM[addr], &instr, sizeof(uint64_t));
        addr += 8;
    }

    fclose(f);
    return 0;
}

int main() {
    CPU cpu = {0};
    cpu.PC = 0;

    // Cargar programa desde archivo
    if (load_from_file("program.bin", MEM, 0) != 0) {
        return 1;
    }

    // Ejecutar
    run(&cpu, MEM);

    printf("Resultado final: R0 = %llu\n", (unsigned long long)cpu.REG[0]);

    return 0;
}
