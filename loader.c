#include <stdio.h>
#include <stdint.h>
#include <string.h>
#include "loader.h"

#define MAX_MEMORY 0xFFFFFFFF  // 4 GiB según tu diseño

// Carga un programa binario en memoria desde una dirección base
int loader_load_program(const char *filename, uint8_t *MEM, 
                        uint32_t base_addr, ProgramInfo *info) {
    
    printf("=== CARGADOR AETHER COMPUTER ===\n");
    printf("Cargando: %s\n", filename);
    printf("Dirección base: 0x%08X\n", base_addr);
    
    // Abrir archivo binario
    FILE *f = fopen(filename, "rb");
    if (!f) {
        fprintf(stderr, "ERROR: No se pudo abrir el archivo '%s'\n", filename);
        return -1;
    }
    
    // Obtener tamaño del archivo
    fseek(f, 0, SEEK_END);
    long file_size = ftell(f);
    fseek(f, 0, SEEK_SET);
    
    printf("Tamaño del archivo: %ld bytes\n", file_size);
    
    // Validar espacio en memoria
    if (loader_validate_memory(base_addr, file_size) != 0) {
        fclose(f);
        return -1;
    }
    
    // Cargar instrucciones en memoria
    uint32_t addr = base_addr;
    size_t bytes_read;
    uint64_t instr;
    int instr_count = 0;
    
    while ((bytes_read = fread(&instr, sizeof(uint64_t), 1, f)) == 1) {
        // Copiar instrucción a memoria
        memcpy(&MEM[addr], &instr, sizeof(uint64_t));
        
        printf("  [0x%08X] = 0x%016llX\n", addr, 
               (unsigned long long)instr);
        
        addr += 8;
        instr_count++;
    }
    
    fclose(f);
    
    // Llenar estructura de información
    info->base_address = base_addr;
    info->code_size = instr_count * 8;
    info->entry_point = base_addr;
    
    // Configurar sección de datos después del código
    info->data_address = base_addr + info->code_size;
    info->data_size = 0;  // Por ahora sin datos iniciales
    
    // Stack crece hacia abajo desde el final de la memoria
    info->stack_pointer = 0x7FFFFFFF;  // Ejemplo: 2GB
    
    printf("\nPrograma cargado exitosamente\n");
    printf("  Instrucciones cargadas: %d\n", instr_count);
    printf("  Bytes totales: %u\n", info->code_size);
    
    return 0;
}


// Inicializa la CPU con la información del programa cargado
int loader_init_cpu(CPU *cpu, ProgramInfo *info) {
    printf("\n=== INICIALIZANDO CPU ===\n");
    
    // Limpiar toda la estructura CPU
    memset(cpu, 0, sizeof(CPU));
    
    // Configurar registros especiales
    cpu->PC = info->entry_point;
    cpu->REG[31] = info->stack_pointer;  // R31 como SP (stack pointer)
    cpu->FLAGS = 0;  // Todos los flags en 0
    
    printf("  PC = 0x%08llX (punto de entrada)\n", (unsigned long long)cpu->PC);
    printf("  R31 (SP) = 0x%08llX (inicio de pila)\n", (unsigned long long)cpu->REG[31]);
    printf("  Registros R0-R30 = 0\n");
    printf("  FLAGS = 0x%02X (Z=0, N=0, C=0, V=0)\n", cpu->FLAGS);
    
    printf("✓ CPU inicializada\n\n");
    
    return 0;
}

// Imprime información detallada del programa cargado
void loader_print_info(ProgramInfo *info) {
    printf("\n=== INFORMACIÓN DEL PROGRAMA ===\n");
    printf("Sección de CÓDIGO:\n");
    printf("  Dirección base: 0x%08X\n", info->base_address);
    printf("  Tamaño:         %u bytes (%u instrucciones)\n", 
           info->code_size, info->code_size / 8);
    printf("  Rango:          0x%08X - 0x%08X\n",
           info->base_address, 
           info->base_address + info->code_size - 1);
    
    printf("\nSección de DATOS:\n");
    printf("  Dirección:      0x%08X\n", info->data_address);
    printf("  Tamaño:         %u bytes\n", info->data_size);
    
    printf("\nConfiguración de EJECUCIÓN:\n");
    printf("  Punto de entrada: 0x%08X\n", info->entry_point);
    printf("  Puntero de pila:  0x%08X\n", info->stack_pointer);
    printf("================================\n\n");
}

// Valida que hay suficiente espacio en memoria
int loader_validate_memory(uint32_t base_addr, uint32_t size) {
    // Verificar desbordamiento
    if (base_addr + size > MAX_MEMORY) {
        fprintf(stderr, "ERROR: Programa excede el espacio de memoria\n");
        fprintf(stderr, "  Dirección base: 0x%08X\n", base_addr);
        fprintf(stderr, "  Tamaño: %u bytes\n", size);
        fprintf(stderr, "  Dirección final: 0x%08X\n", base_addr + size);
        return -1;
    }
    
    // Verificar alineación (direcciones múltiplos de 8)
    if (base_addr % 8 != 0) {
        fprintf(stderr, "ADVERTENCIA: Dirección base no alineada a 8 bytes\n");
        fprintf(stderr, "  Se recomienda usar direcciones alineadas\n");
    }
    
    return 0;
}