#ifndef LOADER_H
#define LOADER_H

#include <stdint.h>
#include "cpu.h"

// Estructura de información del programa cargado
typedef struct {
    uint32_t base_address;      // Dirección donde inicia el código
    uint32_t code_size;         // Tamaño de la sección de código
    uint32_t data_address;      // Dirección de inicio de datos
    uint32_t data_size;         // Tamaño de la sección de datos
    uint64_t entry_point;       // Punto de entrada (PC inicial) - cambiado a uint64_t
    uint64_t stack_pointer;     // Valor inicial del SP - cambiado a uint64_t
} ProgramInfo;

// Funciones principales del cargador
int loader_load_program(const char *filename, uint8_t *MEM, 
                        uint32_t base_addr, ProgramInfo *info);

int loader_init_cpu(CPU *cpu, ProgramInfo *info);

void loader_print_info(ProgramInfo *info);

int loader_validate_memory(uint32_t base_addr, uint32_t size);

#endif