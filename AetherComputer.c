#include <stdio.h>
#include <stdint.h>
#include "cpu.h"
#include "loader.h"

// Memoria global
uint8_t MEM[MEM_SIZE];

int main(int argc, char *argv[]) {
    CPU cpu;
    ProgramInfo prog_info;
    
    // Dirección base configurable (por defecto 0x00100000)
    uint32_t base_addr = 0x00100000;
    const char *filename = "program.bin";
    
    // Permitir especificar archivo y dirección por línea de comandos
    if (argc > 1) {
        filename = argv[1];
    }
    if (argc > 2) {
        sscanf(argv[2], "%x", &base_addr);
    }
    
    // FASE 1: CARGA (LOADER)
    if (loader_load_program(filename, MEM, base_addr, &prog_info) != 0) {
        fprintf(stderr, "Error al cargar el programa\n");
        return 1;
    }
    
    // Mostrar información del programa
    loader_print_info(&prog_info);
    
    // FASE 2: INICIALIZACIÓN
    if (loader_init_cpu(&cpu, &prog_info) != 0) {
        fprintf(stderr, "Error al inicializar CPU\n");
        return 1;
    }
    
// FASE 3: EJECUCIÓN
    printf("=== INICIANDO EJECUCIÓN ===\n\n");
    run(&cpu, MEM);
    
    // FASE 4: RESULTADOS
    printf("\n=== EJECUCIÓN FINALIZADA ===\n");
    printf("Resultado final: R0 = %lld\n", (long long)cpu.REG[0]);
    printf("PC final: 0x%08llX\n", (unsigned long long)cpu.PC);
    
    // Leer flags usando las funciones y máscaras correctas
    printf("Flags: Z=%d N=%d C=%d V=%d\n", 
           read_flag(&cpu, ZERO_FLAG) ? 1 : 0,
           read_flag(&cpu, NEGATIVE_FLAG) ? 1 : 0,
           read_flag(&cpu, CARRY_FLAG) ? 1 : 0,
           read_flag(&cpu, OVERFLOW_FLAG) ? 1 : 0);
    
    return 0;
}