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
                break;
            case OPCODE_HALT:
                printf("HALT alcanzado.\n");
                return;
            default:
                printf("Opcode desconocido: %d\n", opcode);
                return;
        }

        // Mostrar estado de la CPU
        printf("PC=%llu | R0=%llu R1=%llu R2=%llu\n",
               (unsigned long long)cpu->PC,
               (unsigned long long)cpu->REG[0],
               (unsigned long long)cpu->REG[1],
               (unsigned long long)cpu->REG[2]);
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
