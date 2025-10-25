%{
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#define MAX_DEFINES 100
#define MAX_NAME_LEN 64
#define MAX_VALUE_LEN 256
#define MAX_INCLUDE_DEPTH 10

typedef struct {
    char name[MAX_NAME_LEN];
    char value[MAX_VALUE_LEN];
} Define;

Define defines[MAX_DEFINES];
int define_count = 0;

/* Stack to manage nested includes */
struct include_stack {
    YY_BUFFER_STATE buffer;
    FILE *file;
    char filename[256];
    int lineno;
} include_stack[MAX_INCLUDE_DEPTH];

int include_stack_ptr = 0;

void add_define(const char *name, const char *value);
const char* get_define(const char *name);
int process_include(const char *filename);
%}

%option noyywrap
%option yylineno

IDENTIFIER  [a-zA-Z_][a-zA-Z0-9_]*
WHITESPACE  [ \t]+
NEWLINE     \n

%x DEFINE_STATE
%x DEFINE_VALUE_STATE

%%

    /* Handle #define directive */
^[ \t]*#define{WHITESPACE}  { BEGIN(DEFINE_STATE); }

<DEFINE_STATE>{IDENTIFIER}  {
    /* Store the identifier name temporarily */
    static char def_name[MAX_NAME_LEN];
    strncpy(def_name, yytext, MAX_NAME_LEN - 1);
    def_name[MAX_NAME_LEN - 1] = '\0';
    
    /* Now look for the value */
    char value[MAX_VALUE_LEN] = "";
    int c;
    int i = 0;
    
    /* Skip whitespace */
    while ((c = input()) == ' ' || c == '\t');
    
    /* Read until newline */
    while (c != '\n' && c != EOF && i < MAX_VALUE_LEN - 1) {
        value[i++] = c;
        c = input();
    }
    value[i] = '\0';
    
    /* Trim trailing whitespace */
    while (i > 0 && (value[i-1] == ' ' || value[i-1] == '\t')) {
        value[--i] = '\0';
    }
    
    add_define(def_name, value);
    
    if (c == '\n') {
        fprintf(yyout, "\n");
    }
    
    BEGIN(INITIAL);
}



    /* Handle #include directive - actually include the file */
^[ \t]*#include[ \t]*\"([^\"]+)\"[ \t]*\n  {
    char filename[256];
    /* Extract filename from quotes */
    sscanf(yytext, "#include \"%[^\"]\"", filename);
    
    if (!process_include(filename)) {
        fprintf(stderr, "Error: Could not include file '%s'\n", filename);
    }
}

^[ \t]*#include[ \t]*\<([^\>]+)\>[ \t]*\n  {
    char filename[256];
    /* Extract filename from angle brackets */
    sscanf(yytext, "#include <%[^>]>", filename);
    
    if (!process_include(filename)) {
        fprintf(stderr, "Error: Could not include file '%s'\n", filename);
    }
}

<<EOF>>  {
    if (include_stack_ptr > 0) {
        /* Pop back to previous file */
        include_stack_ptr--;
        fclose(yyin);
        yy_delete_buffer(YY_CURRENT_BUFFER);
        yy_switch_to_buffer(include_stack[include_stack_ptr].buffer);
        yyin = include_stack[include_stack_ptr].file;
        yylineno = include_stack[include_stack_ptr].lineno;
    } else {
        yyterminate();
    }
}

    /* Replace identifiers with their defined values */
{IDENTIFIER}  {
    const char *value = get_define(yytext);
    if (value != NULL) {
        fprintf(yyout, "%s", value);
    } else {
        fprintf(yyout, "%s", yytext);
    }
}

    /* Pass through everything else */
.           { fprintf(yyout, "%s", yytext); }
\n          { fprintf(yyout, "\n"); }

%%

void add_define(const char *name, const char *value) {
    if (define_count >= MAX_DEFINES) {
        fprintf(stderr, "Error: Too many defines\n");
        return;
    }
    
    /* Check if already defined - update it */
    for (int i = 0; i < define_count; i++) {
        if (strcmp(defines[i].name, name) == 0) {
            strncpy(defines[i].value, value, MAX_VALUE_LEN - 1);
            defines[i].value[MAX_VALUE_LEN - 1] = '\0';
            return;
        }
    }
    
    /* Add new define */
    strncpy(defines[define_count].name, name, MAX_NAME_LEN - 1);
    defines[define_count].name[MAX_NAME_LEN - 1] = '\0';
    strncpy(defines[define_count].value, value, MAX_VALUE_LEN - 1);
    defines[define_count].value[MAX_VALUE_LEN - 1] = '\0';
    define_count++;
}

const char* get_define(const char *name) {
    for (int i = 0; i < define_count; i++) {
        if (strcmp(defines[i].name, name) == 0) {
            return defines[i].value;
        }
    }
    return NULL;
}

int process_include(const char *filename) {
    if (include_stack_ptr >= MAX_INCLUDE_DEPTH) {
        fprintf(stderr, "Error: Includes nested too deeply (max %d)\n", MAX_INCLUDE_DEPTH);
        return 0;
    }
    
    FILE *file = fopen(filename, "r");
    if (!file) {
        return 0;
    }
    
    /* Save current state */
    include_stack[include_stack_ptr].buffer = YY_CURRENT_BUFFER;
    include_stack[include_stack_ptr].file = yyin;
    include_stack[include_stack_ptr].lineno = yylineno;
    strncpy(include_stack[include_stack_ptr].filename, filename, 255);
    include_stack[include_stack_ptr].filename[255] = '\0';
    include_stack_ptr++;
    
    /* Switch to new file */
    yyin = file;
    yylineno = 1;
    yy_switch_to_buffer(yy_create_buffer(yyin, YY_BUF_SIZE));
    
    return 1;
}

int main(int argc, char **argv) {
    if (argc > 1) {
        yyin = fopen(argv[1], "r");
        if (!yyin) {
            fprintf(stderr, "Error: Could not open file %s\n", argv[1]);
            return 1;
        }
    }
    
    if (argc > 2) {
        yyout = fopen(argv[2], "w");
        if (!yyout) {
            fprintf(stderr, "Error: Could not open output file %s\n", argv[2]);
            return 1;
        }
    }
    
    yylex();
    
    if (yyin != stdin) fclose(yyin);
    if (yyout != stdout) fclose(yyout);
    
    return 0;
}