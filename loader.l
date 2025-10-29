%{
/*
 loader.l
 Linker / Loader simple en FLEX que toma program.obj y escribe program.bin
 Uso: ./loader [program.obj] [base_addr_bytes]
 Ejemplos:
   ./loader           -> usa program.obj y base 0
   ./loader program.obj 64  -> carga en base 64 (bytes)
*/
#include <stdio.h>
#include <stdlib.h>
#include <stdint.h>
#include <string.h>

%}

%option noyywrap

%%

.*\n    { /* noop, no usamos scanner para procesar */ }
.      { }

%%

int main(int argc, char **argv) {
    const char *objname = "program.obj";
    long base = 0;
    if (argc >= 2) objname = argv[1];
    if (argc >= 3) base = strtol(argv[2], NULL, 0);

    FILE *in = fopen(objname, "rb");
    if (!in) { perror("fopen obj"); return 1; }

    uint32_t n;
    if (fread(&n, sizeof(uint32_t), 1, in) != 1) { fprintf(stderr,"Formato .obj inválido (no pudo leer contador)\n"); fclose(in); return 1; }

    uint64_t *instrs = malloc(sizeof(uint64_t) * n);
    if (!instrs) { perror("malloc"); fclose(in); return 1; }
    if (fread(instrs, sizeof(uint64_t), n, in) != n) { fprintf(stderr,"Error leyendo instrucciones\n"); free(instrs); fclose(in); return 1; }
    fclose(in);

    FILE *out = fopen("program.bin", "wb");
    if (!out) { perror("fopen program.bin"); free(instrs); return 1; }

    /* write zeros until base */
    if (base > 0) {
        size_t zero_block = 4096;
        char *zeros = calloc(1, zero_block);
        long remaining = base;
        while (remaining > 0) {
            size_t towrite = (remaining > (long)zero_block) ? zero_block : (size_t)remaining;
            fwrite(zeros, 1, towrite, out);
            remaining -= towrite;
        }
        free(zeros);
    }

    /* write instructions */
    for (uint32_t i=0;i<n;i++) {
        fwrite(&instrs[i], sizeof(uint64_t), 1, out);
    }
    fclose(out);
    free(instrs);

    printf("Loaded %u instrucciones en program.bin (base=%ld bytes)\n", n, base);
    return 0;
}

