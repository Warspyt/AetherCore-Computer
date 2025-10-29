%{
/*
 assembler.l
 Ensamblador simple en FLEX (two-pass) que produce program.obj (binario)
 y program.sym (tabla de símbolos en texto).
 Uso: ./assembler <entrada.asm>
*/
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <stdint.h>
#include "cpu.h"

#define MAX_INSTR 100000

typedef struct {
    char *name;
    int64_t addr; /* dirección en bytes */
} Symbol;

Symbol *symtab = NULL;
int symcount = 0;

uint64_t instrs[MAX_INSTR];
int instr_count = 0;

/* util */
static char *strtrim(char *s) {
    while(*s && (*s == ' ' || *s == '\t')) s++;
    char *end = s + strlen(s) - 1;
    while(end > s && (*end == ' ' || *end == '\t' || *end == '\r' || *end == '\n')) { *end = 0; end--; }
    return s;
}

void add_symbol_once(const char *name, int64_t addr) {
    for (int i=0;i<symcount;i++) if (strcmp(symtab[i].name, name)==0) return;
    symtab = realloc(symtab, sizeof(Symbol)*(symcount+1));
    symtab[symcount].name = strdup(name);
    symtab[symcount].addr = addr;
    symcount++;
}

void set_symbol_addr(const char *name, int64_t addr) {
    for (int i=0;i<symcount;i++) if (strcmp(symtab[i].name, name)==0) { symtab[i].addr = addr; return; }
    add_symbol_once(name, addr);
}

int64_t get_symbol_addr(const char *name) {
    for (int i=0;i<symcount;i++) if (strcmp(symtab[i].name, name)==0) return symtab[i].addr;
    return -1;
}

/* Construcción de instrucciones (mismas posiciones que cpu.c) */
uint64_t make_I(uint16_t opcode, uint8_t rd, uint32_t imm) {
    uint64_t instr = 0;
    instr |= ((uint64_t)(opcode & 0x3FF)) << 54;
    instr |= ((uint64_t)(rd & 0x1F)) << 49;
    instr |= ((uint64_t)imm & 0xFFFFFFFF);
    return instr;
}
uint64_t make_R(uint16_t opcode, uint8_t rd, uint8_t rs, uint8_t rt) {
    uint64_t instr = 0;
    instr |= ((uint64_t)(opcode & 0x3FF)) << 54;
    instr |= ((uint64_t)(rd & 0x1F)) << 49;
    instr |= ((uint64_t)(rs & 0x1F)) << 44;
    instr |= ((uint64_t)(rt & 0x1F)) << 39;
    return instr;
}
uint64_t make_B(uint16_t opcode, uint32_t imm) {
    uint64_t instr = 0;
    instr |= ((uint64_t)(opcode & 0x3FF)) << 54;
    instr |= ((uint64_t)imm & 0xFFFFFFFF);
    return instr;
}

/* Proceso de línea: parsea instrucción y añade a instrs[].
   Soporta números de registro en formato decimal (ej: LOADI 0 48) y branch con inmediatos,
   además de etiquetas (labels) en la misma línea. */
void process_line_firstpass(char *line); /* forward */
void process_line_secondpass(char *line); /* forward */

/* Helpers para parsear tokens: */
int parse_int_or_label_as_imm(const char *tok, int32_t *out) {
    /* Si es número, parsea. Si es etiqueta, busca su dirección y devuelve (addr/8)?? No: la ISA usa immediatos directos,
       el programa de ejemplo usa BR -4 y BRZERO 7 (ya son offsets relativos). Entonces asumimos el ensamblador
       recibe números inmediatos relativos. Si tok es label, hacemos imm = (label_addr - next_instr_addr)/8 (offset en instrucciones). */
    char *endptr;
    long v = strtol(tok, &endptr, 0);
    if (endptr && *endptr == '\0') { *out = (int32_t)v; return 1; }
    /* label: buscar */
    int64_t addr = get_symbol_addr(tok);
    if (addr >= 0) {
        /* offset relativo en instrucciones: (label_addr - next_instr_addr)/8  -> pero en primera pasada no conocemos next_instr; el caller sabrá si hay que resolver */
        *out = (int32_t)addr; /* segurar: caller ajustará si requiere */
        return 1;
    }
    return 0;
}

/* Pasada 1: detecta labels y cuenta instrucciones (calcula direcciones). */
void process_line_firstpass(char *line) {
    char copy[512];
    strncpy(copy, line, sizeof(copy)-1);
    copy[sizeof(copy)-1] = 0;
    char *s = strtrim(copy);
    if (s[0] == 0) return;
    /* strip comments (// or ##) */
    char *cpos = strstr(s, "##"); if (!cpos) cpos = strstr(s, "//"); if (cpos) *cpos = 0;
    s = strtrim(s);
    if (s[0]==0) return;

    /* label check: <ID>: */
    char label[256];
    if (sscanf(s, "%255[^:]:%*[ \t]%n", label, (int[]){0}) >= 0) {
        /* safer parse: find ':' manually */
        char *col = strchr(s, ':');
        if (col) {
            int len = col - s;
            char lblname[256]; strncpy(lblname, s, len); lblname[len]=0;
            char *lbltrim = strtrim(lblname);
            add_symbol_once(lbltrim, instr_count * 8); /* la dirección actual en bytes */
            /* remainder after ':' */
            char *rest = strtrim(col+1);
            if (rest && rest[0] != 0) {
                /* there's an instruction after the label */
                instr_count++; /* cuenta una instrucción */
            }
            return;
        }
    }

    /* otherwise it's an instruction line */
    instr_count++;
}

/* Pasada 2: codifica instrucciones ya con tabla de símbolos (para labels usados como immediatos) */
void process_line_secondpass(char *line) {
    char copy[512];
    strncpy(copy, line, sizeof(copy)-1);
    copy[sizeof(copy)-1] = 0;
    char *s = strtrim(copy);
    if (s[0] == 0) return;
    /* strip comments */
    char *cpos = strstr(s, "##"); if (!cpos) cpos = strstr(s, "//"); if (cpos) *cpos = 0;
    s = strtrim(s);
    if (s[0]==0) return;

    /* skip label if present */
    if (strchr(s, ':')) {
        char *col = strchr(s, ':');
        s = strtrim(col+1);
        if (s[0]==0) return;
    }
    /* Now s begins with instruction mnemonic */
    char op[32];
    int matched = sscanf(s, "%31s", op);
    if (matched != 1) return;
    /* rest of line */
    char *rest = s + strlen(op);
    rest = strtrim(rest);

    /* Parse according to opcode */
    uint64_t instr = 0;
    if (strcasecmp(op, "LOADI")==0) {
        int rd; long imm;
        if (sscanf(rest, "%d %ld", &rd, &imm) < 2) { fprintf(stderr,"Error: LOADI espera 'LOADI rd imm' -> %s\n", s); exit(1); }
        instr = make_I(OPCODE_LOADI, (uint8_t)rd, (uint32_t)imm);
    } else if (strcasecmp(op, "MOV")==0) {
        int rd, rs;
        if (sscanf(rest, "%d %d", &rd, &rs) < 2) { fprintf(stderr,"Error: MOV rd rs -> %s\n", s); exit(1); }
        instr = make_R(OPCODE_MOV, (uint8_t)rd, (uint8_t)rs, 0);
    } else if (strcasecmp(op, "ADD")==0) {
        int rd, rs, rt;
        if (sscanf(rest, "%d %d %d", &rd, &rs, &rt) < 3) { fprintf(stderr,"Error: ADD rd rs rt -> %s\n", s); exit(1); }
        instr = make_R(OPCODE_ADD, (uint8_t)rd, (uint8_t)rs, (uint8_t)rt);
    } else if (strcasecmp(op, "SUB")==0) {
        int rd, rs, rt;
        if (sscanf(rest, "%d %d %d", &rd, &rs, &rt) < 3) { fprintf(stderr,"Error: SUB rd rs rt -> %s\n", s); exit(1); }
        instr = make_R(OPCODE_SUB, (uint8_t)rd, (uint8_t)rs, (uint8_t)rt);
    } else if (strcasecmp(op, "MULT")==0) {
        int rd, rs, rt; if (sscanf(rest, "%d %d %d", &rd, &rs, &rt) < 3) { fprintf(stderr,"Error MULT\n"); exit(1); }
        instr = make_R(OPCODE_MULT, (uint8_t)rd, (uint8_t)rs, (uint8_t)rt);
    } else if (strcasecmp(op, "DIV")==0) {
        int rd, rs, rt; if (sscanf(rest, "%d %d %d", &rd, &rs, &rt) < 3) { fprintf(stderr,"Error DIV\n"); exit(1); }
        instr = make_R(OPCODE_DIV, (uint8_t)rd, (uint8_t)rs, (uint8_t)rt);
    } else if (strcasecmp(op, "CMP")==0) {
        int rs, rt; if (sscanf(rest, "%d %d", &rs, &rt) < 2) { fprintf(stderr,"Error CMP\n"); exit(1); }
        instr = make_R(OPCODE_CMP, 0, (uint8_t)rs, (uint8_t)rt);
    } else if (strcasecmp(op, "BR")==0 || strcasecmp(op, "BRNEG")==0 || strcasecmp(op, "BRZERO")==0 ||
               strcasecmp(op, "BREQ")==0 || strcasecmp(op, "BRLT")==0 || strcasecmp(op, "BRLE")==0 ||
               strcasecmp(op, "BRGT")==0 || strcasecmp(op, "BRGE")==0) {
        int imm;
        if (sscanf(rest, "%d", &imm) < 1) {
            /* maybe a label -> compute relative offset in instructions */
            char lbl[256]; if (sscanf(rest, "%255s", lbl) < 1) { fprintf(stderr,"Error: branch espera inmediato o etiqueta -> %s\n", s); exit(1); }
            int64_t label_addr = get_symbol_addr(lbl);
            if (label_addr < 0) { fprintf(stderr,"Error: etiqueta no encontrada %s\n", lbl); exit(1); }
            /* offset relativo en instrucciones: (label_addr - next_instr_addr)/8 */
            int64_t next_instr_addr = (int64_t)instr_count * 8; /* instr_count here is index of next instr, but we need a running index; we'll maintain a separate counter for second pass */
            /* We'll compute imm as (label_addr - next_instr_addr)/8  BUT we don't know next_instr_addr here if we don't track current index.
               To get it, we temporarily track current second-pass index via a global variable second_idx which increases as we append. */
        }
        /* We'll handle below with an approach using second_pass_index */
        /* placeholder */
    } else if (strcasecmp(op, "INC")==0) {
        int rd; if (sscanf(rest, "%d", &rd) < 1) { fprintf(stderr,"Error INC\n"); exit(1); }
        instr = make_I(OPCODE_INC, (uint8_t)rd, 0);
    } else if (strcasecmp(op, "DEC")==0) {
        int rd; if (sscanf(rest, "%d", &rd) < 1) { fprintf(stderr,"Error DEC\n"); exit(1); }
        instr = make_I(OPCODE_DEC, (uint8_t)rd, 0);
    } else if (strcasecmp(op, "LOAD")==0) {
        int rd; long addr; if (sscanf(rest, "%d %ld", &rd, &addr) < 2) { fprintf(stderr,"Error LOAD\n"); exit(1); }
        instr = make_I(OPCODE_LOAD, (uint8_t)rd, (uint32_t)addr);
    } else if (strcasecmp(op, "STORE")==0) {
        int rs; long addr; if (sscanf(rest, "%d %ld", &rs, &addr) < 2) { fprintf(stderr,"Error STORE\n"); exit(1); }
        instr = make_I(OPCODE_STORE, (uint8_t)rs, (uint32_t)addr);
    } else if (strcasecmp(op, "LOADA")==0) {
        int rd; long addr; if (sscanf(rest, "%d %ld", &rd, &addr) < 2) { fprintf(stderr,"Error LOADA\n"); exit(1); }
        instr = make_I(OPCODE_LOADA, (uint8_t)rd, (uint32_t)addr);
    } else if (strcasecmp(op, "LOADR")==0) {
        int rd, rs; if (sscanf(rest, "%d %d", &rd, &rs) < 2) { fprintf(stderr,"Error LOADR\n"); exit(1); }
        instr = make_R(OPCODE_LOADR, (uint8_t)rd, (uint8_t)rs, 0);
    } else if (strcasecmp(op, "STORER")==0) {
        int rd, rs; if (sscanf(rest, "%d %d", &rd, &rs) < 2) { fprintf(stderr,"Error STORER\n"); exit(1); }
        instr = make_R(OPCODE_STORER, (uint8_t)rd, (uint8_t)rs, 0);
    } else if (strcasecmp(op, "AND")==0) {
        int rd, rs, rt; if (sscanf(rest, "%d %d %d", &rd, &rs, &rt) < 3) { fprintf(stderr,"Error AND\n"); exit(1); }
        instr = make_R(OPCODE_AND, (uint8_t)rd, (uint8_t)rs, (uint8_t)rt);
    } else if (strcasecmp(op, "OR")==0) {
        int rd, rs, rt; if (sscanf(rest, "%d %d %d", &rd, &rs, &rt) < 3) { fprintf(stderr,"Error OR\n"); exit(1); }
        instr = make_R(OPCODE_OR, (uint8_t)rd, (uint8_t)rs, (uint8_t)rt);
    } else if (strcasecmp(op, "NOT")==0) {
        int rd, rs; if (sscanf(rest, "%d %d", &rd, &rs) < 2) { fprintf(stderr,"Error NOT\n"); exit(1); }
        instr = make_R(OPCODE_NOT, (uint8_t)rd, (uint8_t)rs, 0);
    } else if (strcasecmp(op, "NOP")==0) {
        instr = make_I(OPCODE_NOP, 0, 0);
    } else if (strcasecmp(op, "HALT")==0) {
        instr = make_I(OPCODE_HALT, 0, 0);
    } else {
        fprintf(stderr,"Error: instrucción desconocida '%s'\n", op);
        exit(1);
    }

    instrs[instr_count++] = instr;
}

/* For branch opcodes we need to know the current instruction index during second pass.
   So we implement a second pass that re-parses the file and computes branch immediates using
   label addresses and the index of the branch instruction. */

int second_index = 0;

/* We'll implement a more specific second pass that handles branches properly. */
void process_line_secondpass_branches(char *line) {
    char copy[512];
    strncpy(copy, line, sizeof(copy)-1);
    copy[sizeof(copy)-1] = 0;
    char *s = strtrim(copy);
    if (s[0] == 0) return;
    /* strip comments */
    char *cpos = strstr(s, "##"); if (!cpos) cpos = strstr(s, "//"); if (cpos) *cpos = 0;
    s = strtrim(s);
    if (s[0]==0) return;

    /* skip label */
    if (strchr(s, ':')) {
        char *col = strchr(s, ':');
        s = strtrim(col+1);
        if (s[0]==0) return;
    }
    char op[32]; if (sscanf(s, "%31s", op) < 1) return;
    char *rest = s + strlen(op); rest = strtrim(rest);

    uint64_t instr = 0;

    /* Branches & branch-like */
    if (strcasecmp(op, "BR")==0 ||
        strcasecmp(op, "BRNEG")==0 ||
        strcasecmp(op, "BRZERO")==0 ||
        strcasecmp(op, "BREQ")==0 ||
        strcasecmp(op, "BRLT")==0 ||
        strcasecmp(op, "BRLE")==0 ||
        strcasecmp(op, "BRGT")==0 ||
        strcasecmp(op, "BRGE")==0) {

        int imm;
        char tok[256];
        if (sscanf(rest, "%255s", tok) < 1) { fprintf(stderr,"Error: branch sin operando\n"); exit(1); }

        char *endptr; long v = strtol(tok, &endptr, 0);
        if (endptr && *endptr == '\0') {
            imm = (int)v;
        } else {
            /* it's a label: compute relative offset in number of instructions:
               imm = (label_addr - next_instr_addr) / 8
               next_instr_addr = (second_index + 1)*8 in bytes
            */
            int64_t label_addr = get_symbol_addr(tok);
            if (label_addr < 0) { fprintf(stderr,"Error: etiqueta no encontrada %s\n", tok); exit(1); }
            int64_t next_instr_addr = ((int64_t)second_index + 1) * 8;
            imm = (int)((label_addr - next_instr_addr) / 8);
        }

        uint16_t opc = OPCODE_BR;
        if (strcasecmp(op,"BRNEG")==0) opc = OPCODE_BRNEG;
        else if (strcasecmp(op,"BRZERO")==0) opc = OPCODE_BRZERO;
        else if (strcasecmp(op,"BREQ")==0) opc = OPCODE_BREQ;
        else if (strcasecmp(op,"BRLT")==0) opc = OPCODE_BRLT;
        else if (strcasecmp(op,"BRLE")==0) opc = OPCODE_BRLE;
        else if (strcasecmp(op,"BRGT")==0) opc = OPCODE_BRGT;
        else if (strcasecmp(op,"BRGE")==0) opc = OPCODE_BRGE;
        instr = make_B(opc, (uint32_t)imm);
        instrs[second_index++] = instr;
        return;
    }

    /* For non-branch instructions, reuse process_line_secondpass but we need to store at position second_index */
    /* We'll call a small helper that encodes without touching global instr_count */
    /* Simpler: re-run the generic encoder but write into instrs[second_index] and increment second_index. */
    /* To avoid duplication, we temporarily set a global used_index to second_index, call encoder that uses it. */
    /* For brevity, we'll parse common cases here (a subset already handled above). */
    if (strcasecmp(op, "LOADI")==0) {
        int rd; long imm;
        if (sscanf(rest, "%d %ld", &rd, &imm) < 2) { fprintf(stderr,"Error: LOADI espera 'LOADI rd imm' -> %s\n", s); exit(1); }
        instrs[second_index++] = make_I(OPCODE_LOADI, (uint8_t)rd, (uint32_t)imm);
        return;
    } else if (strcasecmp(op, "MOV")==0) {
        int rd, rs; if (sscanf(rest, "%d %d", &rd, &rs) < 2) { fprintf(stderr,"Error MOV\n"); exit(1); }
        instrs[second_index++] = make_R(OPCODE_MOV, (uint8_t)rd, (uint8_t)rs, 0);
        return;
    } else if (strcasecmp(op, "ADD")==0) {
        int rd, rs, rt; if (sscanf(rest, "%d %d %d", &rd, &rs, &rt) < 3) { fprintf(stderr,"Error ADD\n"); exit(1); }
        instrs[second_index++] = make_R(OPCODE_ADD, (uint8_t)rd, (uint8_t)rs, (uint8_t)rt);
        return;
    } else if (strcasecmp(op, "SUB")==0) {
        int rd, rs, rt; if (sscanf(rest, "%d %d %d", &rd, &rs, &rt) < 3) { fprintf(stderr,"Error SUB\n"); exit(1); }
        instrs[second_index++] = make_R(OPCODE_SUB, (uint8_t)rd, (uint8_t)rs, (uint8_t)rt);
        return;
    } else if (strcasecmp(op, "MULT")==0) {
        int rd, rs, rt; if (sscanf(rest, "%d %d %d", &rd, &rs, &rt) < 3) { fprintf(stderr,"Error MULT\n"); exit(1); }
        instrs[second_index++] = make_R(OPCODE_MULT, (uint8_t)rd, (uint8_t)rs, (uint8_t)rt);
        return;
    } else if (strcasecmp(op, "DIV")==0) {
        int rd, rs, rt; if (sscanf(rest, "%d %d %d", &rd, &rs, &rt) < 3) { fprintf(stderr,"Error DIV\n"); exit(1); }
        instrs[second_index++] = make_R(OPCODE_DIV, (uint8_t)rd, (uint8_t)rs, (uint8_t)rt);
        return;
    } else if (strcasecmp(op, "CMP")==0) {
        int rs, rt; if (sscanf(rest, "%d %d", &rs, &rt) < 2) { fprintf(stderr,"Error CMP\n"); exit(1); }
        instrs[second_index++] = make_R(OPCODE_CMP, 0, (uint8_t)rs, (uint8_t)rt);
        return;
    } else if (strcasecmp(op, "INC")==0) {
        int rd; if (sscanf(rest, "%d", &rd) < 1) { fprintf(stderr,"Error INC\n"); exit(1); }
        instrs[second_index++] = make_I(OPCODE_INC, (uint8_t)rd, 0);
        return;
    } else if (strcasecmp(op, "DEC")==0) {
        int rd; if (sscanf(rest, "%d", &rd) < 1) { fprintf(stderr,"Error DEC\n"); exit(1); }
        instrs[second_index++] = make_I(OPCODE_DEC, (uint8_t)rd, 0);
        return;
    } else if (strcasecmp(op, "LOAD")==0) {
        int rd; long addr; if (sscanf(rest, "%d %ld", &rd, &addr) < 2) { fprintf(stderr,"Error LOAD\n"); exit(1); }
        instrs[second_index++] = make_I(OPCODE_LOAD, (uint8_t)rd, (uint32_t)addr);
        return;
    } else if (strcasecmp(op, "STORE")==0) {
        int rs; long addr; if (sscanf(rest, "%d %ld", &rs, &addr) < 2) { fprintf(stderr,"Error STORE\n"); exit(1); }
        instrs[second_index++] = make_I(OPCODE_STORE, (uint8_t)rs, (uint32_t)addr);
        return;
    } else if (strcasecmp(op, "LOADA")==0) {
        int rd; long addr; if (sscanf(rest, "%d %ld", &rd, &addr) < 2) { fprintf(stderr,"Error LOADA\n"); exit(1); }
        instrs[second_index++] = make_I(OPCODE_LOADA, (uint8_t)rd, (uint32_t)addr);
        return;
    } else if (strcasecmp(op, "LOADR")==0) {
        int rd, rs; if (sscanf(rest, "%d %d", &rd, &rs) < 2) { fprintf(stderr,"Error LOADR\n"); exit(1); }
        instrs[second_index++] = make_R(OPCODE_LOADR, (uint8_t)rd, (uint8_t)rs, 0);
        return;
    } else if (strcasecmp(op, "STORER")==0) {
        int rd, rs; if (sscanf(rest, "%d %d", &rd, &rs) < 2) { fprintf(stderr,"Error STORER\n"); exit(1); }
        instrs[second_index++] = make_R(OPCODE_STORER, (uint8_t)rd, (uint8_t)rs, 0);
        return;
    } else if (strcasecmp(op, "AND")==0) {
        int rd, rs, rt; if (sscanf(rest, "%d %d %d", &rd, &rs, &rt) < 3) { fprintf(stderr,"Error AND\n"); exit(1); }
        instrs[second_index++] = make_R(OPCODE_AND, (uint8_t)rd, (uint8_t)rs, (uint8_t)rt);
        return;
    } else if (strcasecmp(op, "OR")==0) {
        int rd, rs, rt; if (sscanf(rest, "%d %d %d", &rd, &rs, &rt) < 3) { fprintf(stderr,"Error OR\n"); exit(1); }
        instrs[second_index++] = make_R(OPCODE_OR, (uint8_t)rd, (uint8_t)rs, (uint8_t)rt);
        return;
    } else if (strcasecmp(op, "NOT")==0) {
        int rd, rs; if (sscanf(rest, "%d %d", &rd, &rs) < 2) { fprintf(stderr,"Error NOT\n"); exit(1); }
        instrs[second_index++] = make_R(OPCODE_NOT, (uint8_t)rd, (uint8_t)rs, 0);
        return;
    } else if (strcasecmp(op, "NOP")==0) {
        instrs[second_index++] = make_I(OPCODE_NOP, 0, 0);
        return;
    } else if (strcasecmp(op, "HALT")==0) {
        instrs[second_index++] = make_I(OPCODE_HALT, 0, 0);
        return;
    } else {
        /* unknown -> ignore */
    }
}

/* Entradas de flex: usaremos flex sólo para leer líneas cómodamente; implementamos nuestro propio main */
%}

%option noyywrap

%%

.*\n    { /* cada linea es devuelta por el scanner en yytext */ 
            /* no hacemos nada en reglas: usaremos fgets en main en su lugar */
          }
.      { /* catch all */ }

%%

/* Implementamos main aquí y usamos fgets para más control (evitamos usar el scanner para todo) */
int main(int argc, char **argv) {
    if (argc < 2) {
        fprintf(stderr,"Uso: %s <archivo.asm>\n", argv[0]);
        return 1;
    }

    FILE *f = fopen(argv[1],"r");
    if (!f) { perror("fopen"); return 1; }

    /* Primera pasada: contar instrucciones y recolectar etiquetas */
    instr_count = 0;
    char line[512];
    while (fgets(line, sizeof(line), f)) {
        char copy[512]; strncpy(copy, line, sizeof(copy)-1); copy[sizeof(copy)-1]=0;
        char *s = strtrim(copy);
        /* eliminar comentarios */
        char *cpos = strstr(s, "##"); if (!cpos) cpos = strstr(s, "//"); if (cpos) *cpos = 0;
        s = strtrim(s);
        if (s[0]==0) continue;
        /* label check */
        char *col = strchr(s, ':');
        if (col) {
            int len = col - s;
            char lbl[256]; strncpy(lbl, s, len); lbl[len]=0;
            char *lbltrim = strtrim(lbl);
            set_symbol_addr(lbltrim, instr_count * 8);
            /* remainder */
            char *rest = strtrim(col+1);
            if (rest && rest[0] != 0) instr_count++;
        } else {
            instr_count++;
        }
    }

    /* We'll allocate instrs buffer sized appropriately */
    uint64_t *saved_instrs = malloc(sizeof(uint64_t) * instr_count);
    memset(saved_instrs, 0, sizeof(uint64_t)*instr_count);

    /* Segunda pasada: codificar instrucciones. Necesitamos re-abrir el archivo. */
    rewind(f);
    second_index = 0;
    while (fgets(line, sizeof(line), f)) {
        char copy[512]; strncpy(copy, line, sizeof(copy)-1); copy[sizeof(copy)-1]=0;
        char *s = strtrim(copy);
        char *cpos = strstr(s, "##"); if (!cpos) cpos = strstr(s, "//"); if (cpos) *cpos = 0;
        s = strtrim(s);
        if (s[0]==0) continue;
        /* if contains label and instruction on same line, keep only the instruction part */
        char *col = strchr(s, ':');
        if (col) s = strtrim(col+1);
        if (s[0]==0) continue;

        /* detect if instruction is a branch (handled by dedicated function) */
        char op[32]; if (sscanf(s, "%31s", op) < 1) continue;
        if (strcasecmp(op, "BR")==0 || strcasecmp(op, "BRNEG")==0 || strcasecmp(op, "BRZERO")==0 ||
            strcasecmp(op, "BREQ")==0 || strcasecmp(op, "BRLT")==0 || strcasecmp(op, "BRLE")==0 ||
            strcasecmp(op, "BRGT")==0 || strcasecmp(op, "BRGE")==0) {
            /* parse operand */
            char rest[256]; rest[0]=0;
            sscanf(s + strlen(op), "%255s", rest);
            if (rest[0]==0) { fprintf(stderr,"Error: branch sin operando en linea: %s\n", s); exit(1); }
            int imm;
            char *endptr; long v = strtol(rest, &endptr, 0);
            if (endptr && *endptr == '\0') {
                imm = (int)v;
            } else {
                int64_t label_addr = get_symbol_addr(rest);
                if (label_addr < 0) { fprintf(stderr,"Error: etiqueta no encontrada %s\n", rest); exit(1); }
                int64_t next_instr_addr = ((int64_t)second_index + 1) * 8;
                imm = (int)((label_addr - next_instr_addr) / 8);
            }
            uint16_t opc = OPCODE_BR;
            if (strcasecmp(op,"BRNEG")==0) opc = OPCODE_BRNEG;
            else if (strcasecmp(op,"BRZERO")==0) opc = OPCODE_BRZERO;
            else if (strcasecmp(op,"BREQ")==0) opc = OPCODE_BREQ;
            else if (strcasecmp(op,"BRLT")==0) opc = OPCODE_BRLT;
            else if (strcasecmp(op,"BRLE")==0) opc = OPCODE_BRLE;
            else if (strcasecmp(op,"BRGT")==0) opc = OPCODE_BRGT;
            else if (strcasecmp(op,"BRGE")==0) opc = OPCODE_BRGE;
            saved_instrs[second_index++] = make_B(opc, (uint32_t)imm);
            continue;
        }

        /* non-branch -> handle many cases simply using sscanf patterns */
        if (strcasecmp(op, "LOADI")==0) {
            int rd; long imm; if (sscanf(s + strlen(op), "%d %ld", &rd, &imm) < 2) { fprintf(stderr,"Error LOADI\n"); exit(1); }
            saved_instrs[second_index++] = make_I(OPCODE_LOADI, (uint8_t)rd, (uint32_t)imm);
        } else if (strcasecmp(op, "MOV")==0) {
            int rd, rs; if (sscanf(s + strlen(op), "%d %d", &rd, &rs) < 2) { fprintf(stderr,"Error MOV\n"); exit(1); }
            saved_instrs[second_index++] = make_R(OPCODE_MOV, (uint8_t)rd, (uint8_t)rs, 0);
        } else if (strcasecmp(op, "ADD")==0) {
            int rd, rs, rt; if (sscanf(s + strlen(op), "%d %d %d", &rd, &rs, &rt) < 3) { fprintf(stderr,"Error ADD\n"); exit(1); }
            saved_instrs[second_index++] = make_R(OPCODE_ADD, (uint8_t)rd, (uint8_t)rs, (uint8_t)rt);
        } else if (strcasecmp(op, "SUB")==0) {
            int rd, rs, rt; if (sscanf(s + strlen(op), "%d %d %d", &rd, &rs, &rt) < 3) { fprintf(stderr,"Error SUB\n"); exit(1); }
            saved_instrs[second_index++] = make_R(OPCODE_SUB, (uint8_t)rd, (uint8_t)rs, (uint8_t)rt);
        } else if (strcasecmp(op, "MULT")==0) {
            int rd, rs, rt; if (sscanf(s + strlen(op), "%d %d %d", &rd, &rs, &rt) < 3) { fprintf(stderr,"Error MULT\n"); exit(1); }
            saved_instrs[second_index++] = make_R(OPCODE_MULT, (uint8_t)rd, (uint8_t)rs, (uint8_t)rt);
        } else if (strcasecmp(op, "DIV")==0) {
            int rd, rs, rt; if (sscanf(s + strlen(op), "%d %d %d", &rd, &rs, &rt) < 3) { fprintf(stderr,"Error DIV\n"); exit(1); }
            saved_instrs[second_index++] = make_R(OPCODE_DIV, (uint8_t)rd, (uint8_t)rs, (uint8_t)rt);
        } else if (strcasecmp(op, "CMP")==0) {
            int rs, rt; if (sscanf(s + strlen(op), "%d %d", &rs, &rt) < 2) { fprintf(stderr,"Error CMP\n"); exit(1); }
            saved_instrs[second_index++] = make_R(OPCODE_CMP, 0, (uint8_t)rs, (uint8_t)rt);
        } else if (strcasecmp(op, "INC")==0) {
            int rd; if (sscanf(s + strlen(op), "%d", &rd) < 1) { fprintf(stderr,"Error INC\n"); exit(1); }
            saved_instrs[second_index++] = make_I(OPCODE_INC, (uint8_t)rd, 0);
        } else if (strcasecmp(op, "DEC")==0) {
            int rd; if (sscanf(s + strlen(op), "%d", &rd) < 1) { fprintf(stderr,"Error DEC\n"); exit(1); }
            saved_instrs[second_index++] = make_I(OPCODE_DEC, (uint8_t)rd, 0);
        } else if (strcasecmp(op, "LOAD")==0) {
            int rd; long addr; if (sscanf(s + strlen(op), "%d %ld", &rd, &addr) < 2) { fprintf(stderr,"Error LOAD\n"); exit(1); }
            saved_instrs[second_index++] = make_I(OPCODE_LOAD, (uint8_t)rd, (uint32_t)addr);
        } else if (strcasecmp(op, "STORE")==0) {
            int rs; long addr; if (sscanf(s + strlen(op), "%d %ld", &rs, &addr) < 2) { fprintf(stderr,"Error STORE\n"); exit(1); }
            saved_instrs[second_index++] = make_I(OPCODE_STORE, (uint8_t)rs, (uint32_t)addr);
        } else if (strcasecmp(op, "LOADA")==0) {
            int rd; long addr; if (sscanf(s + strlen(op), "%d %ld", &rd, &addr) < 2) { fprintf(stderr,"Error LOADA\n"); exit(1); }
            saved_instrs[second_index++] = make_I(OPCODE_LOADA, (uint8_t)rd, (uint32_t)addr);
        } else if (strcasecmp(op, "LOADR")==0) {
            int rd, rs; if (sscanf(s + strlen(op), "%d %d", &rd, &rs) < 2) { fprintf(stderr,"Error LOADR\n"); exit(1); }
            saved_instrs[second_index++] = make_R(OPCODE_LOADR, (uint8_t)rd, (uint8_t)rs, 0);
        } else if (strcasecmp(op, "STORER")==0) {
            int rd, rs; if (sscanf(s + strlen(op), "%d %d", &rd, &rs) < 2) { fprintf(stderr,"Error STORER\n"); exit(1); }
            saved_instrs[second_index++] = make_R(OPCODE_STORER, (uint8_t)rd, (uint8_t)rs, 0);
        } else if (strcasecmp(op, "AND")==0) {
            int rd, rs, rt; if (sscanf(s + strlen(op), "%d %d %d", &rd, &rs, &rt) < 3) { fprintf(stderr,"Error AND\n"); exit(1); }
            saved_instrs[second_index++] = make_R(OPCODE_AND, (uint8_t)rd, (uint8_t)rs, (uint8_t)rt);
        } else if (strcasecmp(op, "OR")==0) {
            int rd, rs, rt; if (sscanf(s + strlen(op), "%d %d %d", &rd, &rs, &rt) < 3) { fprintf(stderr,"Error OR\n"); exit(1); }
            saved_instrs[second_index++] = make_R(OPCODE_OR, (uint8_t)rd, (uint8_t)rs, (uint8_t)rt);
        } else if (strcasecmp(op, "NOT")==0) {
            int rd, rs; if (sscanf(s + strlen(op), "%d %d", &rd, &rs) < 2) { fprintf(stderr,"Error NOT\n"); exit(1); }
            saved_instrs[second_index++] = make_R(OPCODE_NOT, (uint8_t)rd, (uint8_t)rs, 0);
        } else if (strcasecmp(op, "NOP")==0) {
            saved_instrs[second_index++] = make_I(OPCODE_NOP, 0, 0);
        } else if (strcasecmp(op, "HALT")==0) {
            saved_instrs[second_index++] = make_I(OPCODE_HALT, 0, 0);
        } else {
            fprintf(stderr,"Instrucción no soportada o malformada: '%s'\n", s);
            exit(1);
        }
    }

    fclose(f);

    /* write program.obj: format:
       uint32_t num_instructions
       followed by num_instructions x uint64_t words (little endian via fwrite)
    */
    FILE *out = fopen("program.obj", "wb");
    if (!out) { perror("fopen out"); return 1; }
    uint32_t n = (uint32_t)second_index;
    fwrite(&n, sizeof(uint32_t), 1, out);
    for (uint32_t i=0;i<n;i++) {
        uint64_t w = saved_instrs[i];
        fwrite(&w, sizeof(uint64_t), 1, out);
    }
    fclose(out);

    /* write symbol table readable */
    FILE *symf = fopen("program.sym","w");
    if (symf) {
        for (int i=0;i<symcount;i++) {
            fprintf(symf, "%s %lld\n", symtab[i].name, (long long) symtab[i].addr);
        }
        fclose(symf);
    }

    printf("Assembling complete: %u instrucciones -> program.obj\n", n);
    return 0;
}

