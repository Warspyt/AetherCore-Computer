#include <stdio.h>
#include <stdlib.h>

#define TOKEN_NAMES_IMPLEMENTATION
#include "tokens.h"

/* Funciones externas generadas por Flex */
extern int yylex();
extern FILE *yyin;
extern char *yytext;
extern int line_num;
extern int col_num;
extern Token* get_current_token();
extern void print_symbol_table();
extern void free_symbol_table();

/* Función auxiliar para imprimir la información de un token */
void print_token(Token *token) {
    if (!token) return;
    
    printf("%-15s | %-20s | Línea: %3d, Columna: %3d", 
           token_names[token->type],
           token->lexeme,
           token->line,
           token->column);
    
    /* Imprimir el valor si es un literal */
    switch(token->type) {
        case INT_LITERAL:
            printf(" | Valor: %d", token->int_val);
            break;
        case FLOAT_LITERAL:
            printf(" | Valor: %.6f", token->float_val);
            break;
        case STRING_LITERAL:
            printf(" | Valor: \"%s\"", token->str_val);
            break;
        case REGISTER:
            printf(" | Registro: R%d", token->int_val);
            break;
        default:
            break;
    }
    
    printf("\n");
}

int main(int argc, char *argv[]) {
    /* Verificar argumentos de línea de comandos */
    if (argc < 2) {
        fprintf(stderr, "Uso: %s <archivo_entrada>\n", argv[0]);
        fprintf(stderr, "Ejemplo: %s test_lexer.txt\n", argv[0]);
        return 1;
    }

    /* Abrir archivo de entrada */
    yyin = fopen(argv[1], "r");
    if (!yyin) {
        perror("Error al abrir el archivo de entrada");
        return 1;
    }

    printf("=================================================\n");
    printf("           RESULTADOS DEL ANÁLISIS LÉXICO\n");
    printf("=================================================\n");
    printf("%-15s | %-20s | Posición\n", "TOKEN", "LEXEMA");
    printf("-------------------------------------------------\n");

    /* Analizar los tokens del archivo */
    int token_type;
    int token_count = 0;
    int error_count = 0;

    while ((token_type = yylex()) != 0) {
        Token *token = get_current_token();
        
        if (token_type == ERROR) {
            error_count++;
        } else {
            token_count++;
        }
        
        print_token(token);
    }

    printf("=================================================\n");
    printf("  Tokens procesados: %d\n", token_count);
    printf("  Errores encontrados: %d\n", error_count);
    printf("=================================================\n");

    /* Imprimir la tabla de símbolos */
    print_symbol_table();
    
    /* Liberar recursos */
    fclose(yyin);
    free_symbol_table();

    return (error_count > 0) ? 1 : 0;
}
