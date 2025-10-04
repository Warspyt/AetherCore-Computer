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
    } 
    else if (sscanf(line, "%s %d %d", instr, &rd, &imm) == 3) {
        if (strcmp(instr, "LOADI") == 0)
            return make_instr_I(OPCODE_LOADI, rd, imm);
        else if (strcmp(instr, "MOV") == 0)
            return make_instr_R(OPCODE_MOV, rd, imm, 0);
    }
    else if (sscanf(line, "%s %d", instr, &imm) == 2) {
        if (strcmp(instr, "BRNEG") == 0) {
            return make_instr_B(OPCODE_BRNEG, imm);
        }
    }
    else if (sscanf(line, "%s", instr) == 1) {
        if (strcmp(instr, "HALT") == 0)
            return make_instr_I(OPCODE_HALT, 0, 0);
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
