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

void append_to_symbol_table(symtabEntry * new_symbol);
symtabEntry * new_symbol();

symtabEntry * append_new_symbol(char *, symtabEntryType, symtabEntryType, int, symtabEntry *, int);

symtabEntry * add_integer_param_symbol(char * name, symtabEntry * parent, int parameter);
symtabEntry * add_integer_symbol(char * name, symtabEntry * parent);

symtabEntry * add_real_param_symbol(char * name, symtabEntry * parent, int parameter);
symtabEntry * add_real_symbol(char * name, symtabEntry * parent);

symtabEntry * add_variable_declaration(char * name, symtabEntryType type, symtabEntry * parent);

symtabEntry * add_function_symbol(char * name, symtabEntryType type, int parameters, int body_offsets);

void update_and_append_scope(symtabEntry * scope, char * name, symtabEntryType type, int parameter_count);

void getSymbolTypePrintout(symtabEntryType type, char * writeIn);
void writeSymboltable (symtabEntry * Symboltable, FILE * outputFile);
void yyerror(char *);

#endif /*GLOBAL_H_*/
