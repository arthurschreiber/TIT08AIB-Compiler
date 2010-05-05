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

typedef enum a_exp_type {
	EXP_INT, EXP_FLOAT, EXP_SYMBOL
} exp_type;

typedef struct a_exp {
	symtabEntry * symbol;
	exp_type type;
	char * value;
} exp;

typedef enum a_quad_type {
	Q_ASSIGNMENT
} quad_type;

typedef struct a_quadruple {
	quad_type type;
	char * operand_1;
	char * operand_2;
	char * operation;
	symtabEntry * symbol;
} quadruple;

exp * new_exp();
exp * new_exp_symbol(char * name);
exp * new_exp_constant(char * constant);

symtabEntry * new_variable(char * name, symtabEntryType type, symtabEntry * scope);
symtabEntry * new_param_variable(char * name, symtabEntryType type, symtabEntry * scope, int parameter);
symtabEntry * new_helper_variable(symtabEntryType type, symtabEntry * scope);

quadruple * new_quadruple();
symtabEntry * find_symbol_in_scope(char * name, symtabEntry * scope);

void append_to_symbol_table(symtabEntry * new_symbol);
symtabEntry * new_symbol();

symtabEntry * append_new_symbol(char *, symtabEntryType, symtabEntryType, int, symtabEntry *, int);

void update_and_append_scope(symtabEntry * scope, char * name, symtabEntryType type, int parameter_count);



void genquad(char * quad_code);

void getSymbolTypePrintout(symtabEntryType type, char * writeIn);
void writeSymboltable (symtabEntry * Symboltable, FILE * outputFile);
void yyerror(char *);

#endif /*GLOBAL_H_*/
