#include <stdio.h>
#include <stdint.h>
#include <stdlib.h>
#include <string.h>
#include "cpu.h"

// Convierte una línea de texto a una instrucción binaria
uint64_t assemble_line(char *line) {
    char instr[16];
    int rd, rs, rt, imm;

    // Intentar leer cada formato
    if (sscanf(line, "%s %d %d %d", instr, &rd, &rs, &rt) == 4) {
        if (strcmp(instr, "ADD") == 0)
            return make_instr_R(OPCODE_ADD, rd, rs, rt);
        else if (strcmp(instr, "SUB") == 0)
            return make_instr_R(OPCODE_SUB, rd, rs, rt);
	    else if (strcmp(instr, "AND") == 0)
            return make_instr_R(OPCODE_AND, rd, rs, rt);
        else if (strcmp(instr, "OR") == 0)
            return make_instr_R(OPCODE_OR, rd, rs, rt);
        else if (strcmp(instr, "MULT") == 0)
            return make_instr_R(OPCODE_MULT, rd, rs, rt);
        else if (strcmp(instr, "DIV") == 0)
            return make_instr_R(OPCODE_DIV, rd, rs, rt);
    } 
    else if (sscanf(line, "%s %d %d", instr, &rd, &imm) == 3) {
        if (strcmp(instr, "LOADI") == 0)
            return make_instr_I(OPCODE_LOADI, rd, imm);
        else if (strcmp(instr, "MOV") == 0)
            return make_instr_R(OPCODE_MOV, rd, imm, 0);
    	else if (strcmp(instr, "NOT") == 0)
            return make_instr_R(OPCODE_NOT, rd, rs, 0);
        else if (strcmp(instr, "CMP") == 0)
            return make_instr_R(OPCODE_CMP, 0, rd, imm); 
        else if (strcmp(instr, "LOAD") == 0)
            return make_instr_I(OPCODE_LOAD, rd, imm);
        else if (strcmp(instr, "STORE") == 0)
            return make_instr_I(OPCODE_STORE, rd, imm);
        else if (strcmp(instr, "LOADA") == 0)
            return make_instr_I(OPCODE_LOADA, rd, imm);
        else if (strcmp(instr, "LOADR") == 0)
            return make_instr_R(OPCODE_LOADR, rd, rs, 0);
        else if (strcmp(instr, "STORER") == 0)
            return make_instr_R(OPCODE_STORER, rd, rs, 0);
    }
     else if (sscanf(line, "%s %d", instr, &imm) == 2) {
        if (strcmp(instr, "INC") == 0)
            return make_instr_I(OPCODE_INC, imm, 0);
        else if (strcmp(instr, "DEC") == 0)
            return make_instr_I(OPCODE_DEC, imm, 0);
        else if (strcmp(instr, "BRNEG") == 0) 
            return make_instr_B(OPCODE_BRNEG, imm);
        else if (strcmp(instr, "BRZERO") == 0)
            return make_instr_B(OPCODE_BRZERO, imm);
        else if (strcmp(instr, "BR") == 0)
            return make_instr_B(OPCODE_BR, imm);
        else if (strcmp(instr, "BREQ") == 0)
            return make_instr_B(OPCODE_BREQ, imm);
        else if (strcmp(instr, "BRLT") == 0)
            return make_instr_B(OPCODE_BRLT, imm);
        else if (strcmp(instr, "BRLE") == 0)
            return make_instr_B(OPCODE_BRLE, imm);
        else if (strcmp(instr, "BRGT") == 0)
            return make_instr_B(OPCODE_BRGT, imm);
        else if (strcmp(instr, "BRGE") == 0)
            return make_instr_B(OPCODE_BRGE, imm);
    }
    else if (sscanf(line, "%s", instr) == 1) {
        if (strcmp(instr, "HALT") == 0)
            return make_instr_I(OPCODE_HALT, 0, 0);
        else if (strcmp(instr, "NOP") == 0)
            return make_instr_I(OPCODE_NOP, 0, 0);
    }

    printf("Instrucción inválida: %s\n", line);
    exit(1);
}

int main(int argc, char *argv[]) {
    if (argc < 3) {
        printf("Uso: %s <input.txt> <output.bin>\n", argv[0]);
        return 1;
    }

    FILE *fin = fopen(argv[1], "r");
    if (!fin) {
        perror("Error abriendo input");
        return 1;
    }

    FILE *fout = fopen(argv[2], "wb");
    if (!fout) {
        perror("Error creando output");
        fclose(fin);
        return 1;
    }

    char line[128];
    while (fgets(line, sizeof(line), fin)) {
        // Quitar salto de línea
        line[strcspn(line, "\n")] = 0;
        if (strlen(line) == 0) continue;

        uint64_t instr = assemble_line(line);
        fwrite(&instr, sizeof(uint64_t), 1, fout);
    }

    fclose(fin);
    fclose(fout);

    printf("Compilación completada: %s -> %s\n", argv[1], argv[2]);
    return 0;
}
