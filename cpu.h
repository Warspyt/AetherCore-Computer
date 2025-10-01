#ifndef CPU_H
#define CPU_H

#include <stdint.h>

// Definir tamaño de la memoria
#define MEM_SIZE 1024

// Opcodes
#define OPCODE_LOADI 0x01
#define OPCODE_MOV   0x02
#define OPCODE_ADD   0x05
#define OPCODE_SUB   0x06
#define OPCODE_HALT  0x11

// CPU
typedef struct {
    uint64_t REG[32];  // Registros R0..R31
    uint64_t PC;       // Program Counter
    uint64_t IR;       // Instruction Register
    uint64_t FLAGS;    // Z, N, C, V
} CPU;

// Funciones
void run(CPU *cpu, uint8_t *MEM);
uint64_t make_instr_I(uint16_t opcode, uint8_t rd, uint32_t imm);
uint64_t make_instr_R(uint16_t opcode, uint8_t rd, uint8_t rs, uint8_t rt);

#endif
