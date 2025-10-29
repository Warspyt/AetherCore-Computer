#ifndef CPU_H
#define CPU_H

#include <stdint.h>
#include <stdbool.h>

// Definir tamaño de la memoria (1 MB)
#define MEM_SIZE 1024 * 1024

// Opcodes
#define OPCODE_LOADI 0x01
#define OPCODE_MOV   0x02
// Arithmetic and logic operations with integers
#define OPCODE_ADD   0x10
#define OPCODE_SUB   0x11
#define OPCODE_MULT  0x12 // Not implemented yet
#define OPCODE_DIV   0x13 // Not implemented yet
// Arithmetic operations with floats
#define OPCODE_ADDF  0x20 // Not implemented yet
#define OPCODE_SUBF  0x21 // Not implemented yet
#define OPCODE_MULTF 0x22 // Not implemented yet
#define OPCODE_DIVF  0x23 // Not implemented yet
// Branch instructions
#define OPCODE_BR     0x30
#define OPCODE_BRNEG 0x31
#define OPCODE_BRZERO 0x32
#define OPCODE_BREQ  0x33
#define OPCODE_BRLT  0x34
#define OPCODE_BRLE  0x35
#define OPCODE_BRGT  0x36
#define OPCODE_BRGE  0x37
// Compare instructions
#define OPCODE_CMP    0x40
//Increment and decrement
#define OPCODE_INC    0x50
#define OPCODE_DEC    0x51
// Memory operations
#define OPCODE_LOAD   0x60  // Cargar de memoria a registro
#define OPCODE_STORE  0x61  // Almacenar de registro a memoria
#define OPCODE_LOADA  0x62  // Cargar dirección (Load Address)
#define OPCODE_LOADR  0x63  // Load usando registro como dirección
#define OPCODE_STORER 0x64  // Store usando registro como dirección
// Logical operations
#define OPCODE_AND   0x70
#define OPCODE_OR    0x71
#define OPCODE_NOT   0x72

#define OPCODE_NOP    0x00
#define OPCODE_HALT  0xFF


// CPU
typedef struct {
    int64_t REG[32];  // Registros R0..R31
    uint64_t PC;       // Program Counter
    uint64_t IR;       // Instruction Register
    uint8_t FLAGS;    // Z, N, C, V
} CPU;

// Storing every flag as its corresponding mask makes reading and setting flags very easy
enum CPU_FLAG {
    ZERO_FLAG = 1 << 7,
    NEGATIVE_FLAG = 1 << 6,
    CARRY_FLAG = 1 << 5,
    OVERFLOW_FLAG = 1 << 4,
};

// Funciones
void run(CPU *cpu, uint8_t *MEM);
uint64_t make_instr_I(uint16_t opcode, uint8_t rd, uint32_t imm);
uint64_t make_instr_R(uint16_t opcode, uint8_t rd, uint8_t rs, uint8_t rt);
uint64_t make_instr_B(uint16_t opcode, uint32_t imm);
bool read_flag(CPU *cpu, enum CPU_FLAG f);
void set_flag(CPU *cpu, enum CPU_FLAG f);
void reset_flags(CPU *cpu);

#endif
