%{
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include "tokens.h"

/* Variables globales para rastrear la posición */
int line_num = 1;
int col_num = 1;

/* Variable global para almacenar el token actual */
Token *current_token = NULL;

/* Tabla de símbolos simple para identificadores y etiquetas */
typedef struct SymbolEntry {
    char *name;
    int address;
    struct SymbolEntry *next;
} SymbolEntry;

SymbolEntry *symbol_table = NULL;

/* Función para agregar símbolo si no existe */
void add_symbol(char *name) {
    SymbolEntry *current = symbol_table;
    while (current != NULL) {
        if (strcmp(current->name, name) == 0) {
            return;
        }
        current = current->next;
    }
    SymbolEntry *new_entry = (SymbolEntry*)malloc(sizeof(SymbolEntry));
    new_entry->name = strdup(name);
    new_entry->address = -1;
    new_entry->next = symbol_table;
    symbol_table = new_entry;
}

/* Función para crear token y almacenarlo en variable global */
void create_token(int type, char* lexeme, int line, int col);

/* Macro para crear token y devolver tipo */
#define TOKEN(type) { create_token(type, yytext, line_num, col_num - yyleng); return type; }

/* Actualiza la columna */
#define YY_USER_ACTION col_num += yyleng;
%}

/* Definiciones */
DIGIT           [0-9]
LETTER          [a-zA-Z]
LETTER_UNDER    [a-zA-Z_]
ALPHANUMERIC    [a-zA-Z0-9_]
INTEGER         -?{DIGIT}+
FLOAT           -?{DIGIT}+\.{DIGIT}+
ID              {LETTER_UNDER}{ALPHANUMERIC}*
WHITESPACE      [ \t\r]
STRING          \"[^\"]*\"|\'[^\']*\'
REGISTER        R{DIGIT}+

/* Opciones de Flex */
%option noyywrap
%option yylineno

%%

    /* ========== COMENTARIOS ========== */
"##".*                  { /* Comentario estilo Python */ }
"//".*                  { /* Comentario estilo C */ }
"/*"([^*]|\*+[^*/])*\*+"/"  { 
                            for(int i = 0; i < yyleng; i++) {
                                if(yytext[i] == '\n') {
                                    line_num++;
                                    col_num = 1;
                                }
                            }
                        }

    /* ========== INSTRUCCIONES ENSAMBLADOR ========== */
"LOADI"                 TOKEN(OPCODE_LOADI)
"MOV"                   TOKEN(OPCODE_MOV)
"ADD"                   TOKEN(OPCODE_ADD)
"SUB"                   TOKEN(OPCODE_SUB)
"MULT"                  TOKEN(OPCODE_MULT)
"DIV"                   TOKEN(OPCODE_DIV)
"ADDF"                  TOKEN(OPCODE_ADDF)
"SUBF"                  TOKEN(OPCODE_SUBF)
"MULTF"                 TOKEN(OPCODE_MULTF)
"DIVF"                  TOKEN(OPCODE_DIVF)
"BR"                    TOKEN(OPCODE_BR)
"BRNEG"                 TOKEN(OPCODE_BRNEG)
"BRZERO"                TOKEN(OPCODE_BRZERO)
"BREQ"                  TOKEN(OPCODE_BREQ)
"BRLT"                  TOKEN(OPCODE_BRLT)
"BRLE"                  TOKEN(OPCODE_BRLE)
"BRGT"                  TOKEN(OPCODE_BRGT)
"BRGE"                  TOKEN(OPCODE_BRGE)
"CMP"                   TOKEN(OPCODE_CMP)
"INC"                   TOKEN(OPCODE_INC)
"DEC"                   TOKEN(OPCODE_DEC)
"LOAD"                  TOKEN(OPCODE_LOAD)
"STORE"                 TOKEN(OPCODE_STORE)
"LOADA"                 TOKEN(OPCODE_LOADA)
"LOADR"                 TOKEN(OPCODE_LOADR)
"STORER"                TOKEN(OPCODE_STORER)
"AND"                   TOKEN(OPCODE_AND)
"OR"                    TOKEN(OPCODE_OR)
"NOT"                   TOKEN(OPCODE_NOT)
"NOP"                   TOKEN(OPCODE_NOP)
"HALT"                  TOKEN(OPCODE_HALT)

    /* ========== PALABRAS RESERVADAS DE ALTO NIVEL ========== */
"if"                    TOKEN(IF)
"else"                  TOKEN(ELSE)
"while"                 TOKEN(WHILE)
"for"                   TOKEN(FOR)
"do"                    TOKEN(DO)
"break"                 TOKEN(BREAK)
"continue"              TOKEN(CONTINUE)
"return"                TOKEN(RETURN)
"int"                   TOKEN(INT)
"float"                 TOKEN(FLOAT)
"bool"                  TOKEN(BOOL)
"string"                TOKEN(STRING_TYPE)
"void"                  TOKEN(VOID)
"struct"                TOKEN(STRUCT)
"array"                 TOKEN(ARRAY)
"true"                  TOKEN(TRUE)
"false"                 TOKEN(FALSE)
"null"                  TOKEN(NULL_LITERAL)
"var"                   TOKEN(VAR)
"const"                 TOKEN(CONST)
"function"              TOKEN(FUNCTION)
"proc"                  TOKEN(PROC)
"read"                  TOKEN(READ)
"write"                 TOKEN(WRITE)

    /* ========== OPERADORES DE 2 CARACTERES ========== */
"=="                    TOKEN(EQ)
"!="                    TOKEN(NE)
"<="                    TOKEN(LE)
">="                    TOKEN(GE)
"&&"                    TOKEN(AND)
"||"                    TOKEN(OR)
"++"                    TOKEN(INC)
"--"                    TOKEN(DEC)
"+="                    TOKEN(PLUS_ASSIGN)
"-="                    TOKEN(MINUS_ASSIGN)
"*="                    TOKEN(MULT_ASSIGN)
"/="                    TOKEN(DIV_ASSIGN)

    /* ========== OPERADORES DE 1 CARÁCTER ========== */
"+"                     TOKEN(PLUS)
"-"                     TOKEN(MINUS)
"*"                     TOKEN(MULT)
"/"                     TOKEN(DIV_OP)
"%"                     TOKEN(MOD)
"^"                     TOKEN(POWER)
"<"                     TOKEN(LT)
">"                     TOKEN(GT)
"="                     TOKEN(ASSIGN)
"!"                     TOKEN(NOT)

    /* ========== DELIMITADORES ========== */
";"                     TOKEN(SEMICOLON)
","                     TOKEN(COMMA)
":"                     TOKEN(COLON)
"."                     TOKEN(DOT)
"("                     TOKEN(LPAREN)
")"                     TOKEN(RPAREN)
"["                     TOKEN(LBRACKET)
"]"                     TOKEN(RBRACKET)
"{"                     TOKEN(LBRACE)
"}"                     TOKEN(RBRACE)

    /* ========== REGISTROS ========== */
{REGISTER}              {
                            create_token(REGISTER, yytext, line_num, col_num - yyleng);
                            current_token->int_val = atoi(yytext + 1);
                            return REGISTER;
                        }

    /* ========== LITERALES ========== */
{STRING}                {
                            create_token(STRING_LITERAL, yytext, line_num, col_num - yyleng);
                            char *str = (char*)malloc(strlen(yytext) - 1);
                            strncpy(str, yytext + 1, strlen(yytext) - 2);
                            str[strlen(yytext) - 2] = '\0';
                            current_token->str_val = str;
                            return STRING_LITERAL;
                        }
{FLOAT}                 { 
                            create_token(FLOAT_LITERAL, yytext, line_num, col_num - yyleng);
                            current_token->float_val = atof(yytext);
                            return FLOAT_LITERAL;
                        }
{INTEGER}               { 
                            create_token(INT_LITERAL, yytext, line_num, col_num - yyleng);
                            current_token->int_val = atoi(yytext);
                            return INT_LITERAL;
                        }

    /* ========== IDENTIFICADORES ========== */
{ID}                    { 
                            add_symbol(yytext);
                            create_token(ID, yytext, line_num, col_num - yyleng);
                            return ID;
                        }

    /* ========== ESPACIOS EN BLANCO ========== */
{WHITESPACE}+           { /* Ignorar espacios en blanco */ }
\n                      { line_num++; col_num = 1; }

    /* ========== ERROR LÉXICO ========== */
.                       { 
                            fprintf(stderr, "Error léxico en línea %d, columna %d: carácter no reconocido '%s'\n", 
                                    line_num, col_num - yyleng, yytext);
                            create_token(ERROR, yytext, line_num, col_num - yyleng);
                            return ERROR;
                        }

%%

/* ========== FUNCIONES AUXILIARES ========== */

void create_token(int type, char* lexeme, int line, int col) {
    if (current_token != NULL) {
        if (current_token->lexeme) free(current_token->lexeme);
        free(current_token);
    }
    
    current_token = (Token*)malloc(sizeof(Token));
    current_token->type = type;
    current_token->lexeme = strdup(lexeme);
    current_token->line = line;
    current_token->column = col;
    current_token->int_val = 0;
    current_token->float_val = 0.0;
    current_token->str_val = NULL;
}

Token* get_current_token() {
    return current_token;
}

void print_symbol_table() {
    printf("\n=== TABLA DE SÍMBOLOS ===\n");
    SymbolEntry *current = symbol_table;
    int count = 0;
    while (current != NULL) {
        printf("  %3d. %-20s", ++count, current->name);
        if (current->address >= 0) {
            printf(" @ dirección %d", current->address);
        }
        printf("\n");
        current = current->next;
    }
    printf("Total de símbolos: %d\n", count);
}

void free_symbol_table() {
    SymbolEntry *current = symbol_table;
    while (current != NULL) {
        SymbolEntry *next = current->next;
        free(current->name);
        free(current);
        current = next;
    }
}
