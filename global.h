#ifndef GLOBAL_H_
#define GLOBAL_H_

#include <stdlib.h>
#include <stdio.h>
#include <string.h>

typedef enum symtab_EntryType {INTEGER, REAL, BOOL, PROC, NOP, ARR, FUNC, PROG, PRG_PARA}
	symtabEntryType;

typedef struct a_symtabEntry{
	char * name;
	symtabEntryType type;
	symtabEntryType internType;
	int offset;
	int line;
	int index1;
	int index2;
	struct a_symtabEntry * vater;
	int parameter;
	int number;
	float value;
	struct a_symtabEntry * next;
} symtabEntry;

typedef enum a_quad_type {
	Q_NOP, Q_ASSIGNMENT, Q_INC, Q_DEC, Q_SHIFT,
	Q_MULTIPLY, Q_DIVIDE, Q_MOD,
	Q_PLUS, Q_MINUS,

	Q_GREATER_OR_EQUAL, Q_LESS_OR_EQUAL, Q_EQUAL, Q_NOT_EQUAL, Q_GREATER, Q_LESS,
	Q_GOTO, Q_RETURN
} quad_type;

struct a_jump;

typedef struct a_quadruple {
	quad_type type;
	char * operand_1;
	char * operand_2;
	quad_type operator;
	char * result;
	int line;

	struct a_jump * truelist;
	struct a_jump * falselist;
	struct a_jump * nextlist;

	struct a_quadruple * next;
} quadruple;

typedef struct a_jump {
	quadruple * quad;
	struct a_jump * next;
} jump;


quadruple * new_quadruple();
void compile_quadruplecode();

symtabEntry * new_variable(char * name, symtabEntryType type, symtabEntry * scope);
symtabEntry * new_param_variable(char * name, symtabEntryType type, symtabEntry * scope, int parameter);
symtabEntry * new_helper_variable(symtabEntryType type, symtabEntry * scope);
symtabEntry * find_symbol_in_scope(char * name, symtabEntry * scope);

void append_to_symbol_table(symtabEntry * new_symbol);
symtabEntry * new_symbol();

symtabEntry * append_new_symbol(char *, symtabEntryType, symtabEntryType, int, symtabEntry *, int);

void update_and_append_scope(symtabEntry * scope, char * name, symtabEntryType type, int parameter_count);

void getSymbolTypePrintout(symtabEntryType type, char * writeIn);
void writeSymboltable (symtabEntry * Symboltable, FILE * outputFile);
void yyerror(char *);

#endif /*GLOBAL_H_*/
