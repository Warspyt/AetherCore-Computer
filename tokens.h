#ifndef TOKENS_H
#define TOKENS_H

/* Definición de tipos de token */
typedef enum {
    /* ========== INSTRUCCIONES ENSAMBLADOR ========== */
    // Instrucciones de carga/movimiento
    OPCODE_LOADI = 256, OPCODE_MOV,
    
    // Aritmética (enteros)
    OPCODE_ADD, OPCODE_SUB, OPCODE_MULT, OPCODE_DIV,
    
    // Aritmética (flotantes)
    OPCODE_ADDF, OPCODE_SUBF, OPCODE_MULTF, OPCODE_DIVF,
    
    // Instrucciones de salto
    OPCODE_BR, OPCODE_BRNEG, OPCODE_BRZERO, OPCODE_BREQ,
    OPCODE_BRLT, OPCODE_BRLE, OPCODE_BRGT, OPCODE_BRGE,
    
    // Comparación
    OPCODE_CMP,
    
    // Incremento/Decremento
    OPCODE_INC, OPCODE_DEC,
    
    // Operaciones de memoria
    OPCODE_LOAD, OPCODE_STORE, OPCODE_LOADA, OPCODE_LOADR, OPCODE_STORER,
    
    // Operaciones lógicas
    OPCODE_AND, OPCODE_OR, OPCODE_NOT,
    
    // Especiales
    OPCODE_NOP, OPCODE_HALT,
    
    /* ========== PALABRAS RESERVADAS DE LENGUAJE DE ALTO NIVEL ========== */
    // Control de flujo
    IF, ELSE, WHILE, FOR, DO, BREAK, CONTINUE, RETURN,
    
    // Tipos de datos
    INT, FLOAT, BOOL, STRING_TYPE, VOID, STRUCT, ARRAY,
    
    // Literales
    TRUE, FALSE, NULL_LITERAL,
    
    // Declaraciones
    VAR, CONST, FUNCTION, PROC,
    
    // Entrada/Salida
    READ, WRITE,
    
    /* ========== OPERADORES ========== */
    // Operadores aritméticos
    PLUS, MINUS, MULT, DIV_OP, MOD, POWER,
    
    // Operadores relacionales
    EQ, NE, LT, LE, GT, GE,
    
    // Operadores lógicos
    AND, OR, NOT,
    
    // Operadores de asignación
    ASSIGN, PLUS_ASSIGN, MINUS_ASSIGN, MULT_ASSIGN, DIV_ASSIGN,
    
    // Operadores de incremento/decremento
    INC, DEC,
    
    /* ========== DELIMITADORES ========== */
    SEMICOLON, COMMA, COLON, DOT,
    LPAREN, RPAREN, LBRACKET, RBRACKET, LBRACE, RBRACE,
    
    /* ========== LITERALES ========== */
    INT_LITERAL, FLOAT_LITERAL, STRING_LITERAL,
    
    /* ========== REGISTROS ========== */
    REGISTER,  // R0, R1, R2, ... R31
    
    /* ========== IDENTIFICADORES ========== */
    ID,  // Variables, etiquetas, nombres de funciones
    
    /* ========== ESPECIALES ========== */
    END_OF_FILE,
    ERROR
} TokenType;

/* Estructura de Token */
typedef struct {
    TokenType type;     // Tipo de token
    char *lexeme;       // Texto asociado al token
    int line;           // Línea del archivo donde aparece
    int column;         // Columna del archivo donde aparece
    union {
        int int_val;       // Para enteros y números de registro
        double float_val;  // Para flotantes
        char *str_val;     // Para cadenas
    };
} Token;

/* Declaraciones de funciones externas */
extern void create_token(int type, char* lexeme, int line, int col);
extern Token* get_current_token();
extern void print_symbol_table();
extern void free_symbol_table();

/* Nombres de los tokens (solo declaración) */
extern const char* token_names[];

#endif /* TOKENS_H */

/* Definición del arreglo con nombres de tokens */
#ifdef TOKEN_NAMES_IMPLEMENTATION
const char* token_names[] = {
    /* Instrucciones ensamblador */
    [OPCODE_LOADI] = "OPCODE_LOADI", [OPCODE_MOV] = "OPCODE_MOV",
    [OPCODE_ADD] = "OPCODE_ADD", [OPCODE_SUB] = "OPCODE_SUB",
    [OPCODE_MULT] = "OPCODE_MULT", [OPCODE_DIV] = "OPCODE_DIV",
    [OPCODE_ADDF] = "OPCODE_ADDF", [OPCODE_SUBF] = "OPCODE_SUBF",
    [OPCODE_MULTF] = "OPCODE_MULTF", [OPCODE_DIVF] = "OPCODE_DIVF",
    [OPCODE_BR] = "OPCODE_BR", [OPCODE_BRNEG] = "OPCODE_BRNEG",
    [OPCODE_BRZERO] = "OPCODE_BRZERO", [OPCODE_BREQ] = "OPCODE_BREQ",
    [OPCODE_BRLT] = "OPCODE_BRLT", [OPCODE_BRLE] = "OPCODE_BRLE",
    [OPCODE_BRGT] = "OPCODE_BRGT", [OPCODE_BRGE] = "OPCODE_BRGE",
    [OPCODE_CMP] = "OPCODE_CMP",
    [OPCODE_INC] = "OPCODE_INC", [OPCODE_DEC] = "OPCODE_DEC",
    [OPCODE_LOAD] = "OPCODE_LOAD", [OPCODE_STORE] = "OPCODE_STORE",
    [OPCODE_LOADA] = "OPCODE_LOADA", [OPCODE_LOADR] = "OPCODE_LOADR",
    [OPCODE_STORER] = "OPCODE_STORER",
    [OPCODE_AND] = "OPCODE_AND", [OPCODE_OR] = "OPCODE_OR", [OPCODE_NOT] = "OPCODE_NOT",
    [OPCODE_NOP] = "OPCODE_NOP", [OPCODE_HALT] = "OPCODE_HALT",
    
    /* Palabras reservadas */
    [IF] = "IF", [ELSE] = "ELSE", [WHILE] = "WHILE", [FOR] = "FOR",
    [DO] = "DO", [BREAK] = "BREAK", [CONTINUE] = "CONTINUE", [RETURN] = "RETURN",
    [INT] = "INT", [FLOAT] = "FLOAT", [BOOL] = "BOOL", 
    [STRING_TYPE] = "STRING_TYPE", [VOID] = "VOID",
    [STRUCT] = "STRUCT", [ARRAY] = "ARRAY", 
    [TRUE] = "TRUE", [FALSE] = "FALSE", [NULL_LITERAL] = "NULL_LITERAL",
    [VAR] = "VAR", [CONST] = "CONST", [FUNCTION] = "FUNCTION", [PROC] = "PROC",
    [READ] = "READ", [WRITE] = "WRITE",
    
    /* Operadores */
    [PLUS] = "PLUS", [MINUS] = "MINUS", [MULT] = "MULT", 
    [DIV_OP] = "DIV_OP", [MOD] = "MOD", [POWER] = "POWER",
    [EQ] = "EQ", [NE] = "NE", [LT] = "LT", [LE] = "LE", [GT] = "GT", [GE] = "GE",
    [AND] = "AND", [OR] = "OR", [NOT] = "NOT",
    [ASSIGN] = "ASSIGN", [PLUS_ASSIGN] = "PLUS_ASSIGN", 
    [MINUS_ASSIGN] = "MINUS_ASSIGN", [MULT_ASSIGN] = "MULT_ASSIGN", 
    [DIV_ASSIGN] = "DIV_ASSIGN",
    [INC] = "INC", [DEC] = "DEC",
    
    /* Delimitadores */
    [SEMICOLON] = "SEMICOLON", [COMMA] = "COMMA", [COLON] = "COLON", [DOT] = "DOT",
    [LPAREN] = "LPAREN", [RPAREN] = "RPAREN",
    [LBRACKET] = "LBRACKET", [RBRACKET] = "RBRACKET",
    [LBRACE] = "LBRACE", [RBRACE] = "RBRACE",
    
    /* Literales */
    [INT_LITERAL] = "INT_LITERAL", [FLOAT_LITERAL] = "FLOAT_LITERAL",
    [STRING_LITERAL] = "STRING_LITERAL",
    
    /* Otros */
    [REGISTER] = "REGISTER",
    [ID] = "ID",
    [END_OF_FILE] = "EOF", [ERROR] = "ERROR"
};
#endif /* TOKEN_NAMES_IMPLEMENTATION */


