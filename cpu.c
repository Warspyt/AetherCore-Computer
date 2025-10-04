#include <stdio.h>
#include <stdint.h>
#include <string.h>
#include "cpu.h"

void run(CPU *cpu, uint8_t *MEM) {
    while (1) {

        // Fetch
        memcpy(&cpu->IR, &MEM[cpu->PC], sizeof(uint64_t));
        cpu->PC += 8;

        // Decode
        uint16_t opcode = (cpu->IR >> 54) & 0x3FF;
        uint8_t rd = (cpu->IR >> 49) & 0x1F;
        uint8_t rs = (cpu->IR >> 44) & 0x1F;
        uint8_t rt = (cpu->IR >> 39) & 0x1F;
        int32_t imm = cpu->IR & 0xFFFFFFFF;

        // Execute
        switch (opcode) {
            case OPCODE_LOADI:
                cpu->REG[rd] = imm;
                break;
            case OPCODE_MOV:
                cpu->REG[rd] = cpu->REG[rs];
                break;
            case OPCODE_ADD:
                cpu->REG[rd] = cpu->REG[rs] + cpu->REG[rt];
                break;
            case OPCODE_SUB:
                cpu->REG[rd] = cpu->REG[rs] - cpu->REG[rt];

                reset_flags(cpu);
                if (cpu->REG[rd] < 0) {
                    set_flag(cpu, NEGATIVE_FLAG);
                } else if (cpu->REG[rd] == 0) {
                    set_flag(cpu, ZERO_FLAG);
                }

                break;
            case OPCODE_BRNEG:
                // TODO: add error handling in case the PC ends in an invalid memory address (negative or bigger than
                // the machine's memory)
                if (read_flag(cpu, NEGATIVE_FLAG)) {
                    cpu->PC += 8 * imm;
                }
                break;
            case OPCODE_HALT:
                printf("HALT alcanzado.\n");
                return;
            default:
                printf("Opcode desconocido: %d\n", opcode);
                return;
        }

        // Mostrar estado de la CPU
        printf("PC=%llu | R0=%lld R1=%lld R2=%lld | Z=%d N=%d C=%d V=%d\n",
               (long long)cpu->PC,
               (long long)cpu->REG[0],
               (long long)cpu->REG[1],
               (long long)cpu->REG[2],
               (int)read_flag(cpu, ZERO_FLAG),
               (int)read_flag(cpu, NEGATIVE_FLAG),
               (int)read_flag(cpu, CARRY_FLAG),
               (int)read_flag(cpu, OVERFLOW_FLAG));
    }
}

// Construcción de instrucciones tipo I
uint64_t make_instr_I(uint16_t opcode, uint8_t rd, uint32_t imm) {
    uint64_t instr = 0;
    instr |= ((uint64_t)opcode & 0x3FF) << 54;
    instr |= ((uint64_t)rd & 0x1F) << 49;
    instr |= ((uint64_t)imm & 0xFFFFFFFF);
    return instr;
}

// Construcción de instrucciones tipo R
uint64_t make_instr_R(uint16_t opcode, uint8_t rd, uint8_t rs, uint8_t rt) {
    uint64_t instr = 0;
    instr |= ((uint64_t)opcode & 0x3FF) << 54;
    instr |= ((uint64_t)rd & 0x1F) << 49;
    instr |= ((uint64_t)rs & 0x1F) << 44;
    instr |= ((uint64_t)rt & 0x1F) << 39;
    return instr;
}

// Type B instructions (branches)
uint64_t make_instr_B(uint16_t opcode, uint32_t imm) {
    uint64_t instr = 0;
    instr |= ((uint64_t)opcode & 0x3FF) << 54;
    instr |= ((uint64_t)imm & 0xFFFFFFFF);
    return instr;
}

bool read_flag(CPU *cpu, enum CPU_FLAG f) {
    return (cpu->FLAGS & f) > 0;
}

void set_flag(CPU *cpu, enum CPU_FLAG f) {
    cpu->FLAGS |= f;
}

void reset_flags(CPU *cpu) {
    cpu->FLAGS &= 0x00;
}