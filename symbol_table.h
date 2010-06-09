/*
 *  symbol_table.h
 *  compilerbau
 *
 *  Created by Arthur Schreiber on 07.06.10.
 *  Copyright 2010 -/-. All rights reserved.
 *
 */

#ifndef SYMBOL_TABLE_H
#define SYMBOL_TABLE_H

#include <stdio.h>

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

symtabEntry * new_variable(char * name, symtabEntryType type, symtabEntry * scope);
symtabEntry * new_param_variable(char * name, symtabEntryType type, symtabEntry * scope, int parameter);
symtabEntry * new_helper_variable(symtabEntryType type, symtabEntry * scope);
symtabEntry * find_symbol_in_scope(char * name, symtabEntry * scope);

void append_to_symbol_table(symtabEntry * new_symbol);
symtabEntry * new_symbol();

symtabEntry * append_new_symbol(char *, symtabEntryType, symtabEntryType, int, symtabEntry *, int);

void update_and_append_scope(symtabEntry * scope, char * name, symtabEntryType type, int parameter_count);

void function_and_parameter_check(char * name, int param_count);
void variable_check(char * name, symtabEntry * scope);

void getSymbolTypePrintout(symtabEntryType type, char * writeIn);
void writeSymboltable (symtabEntry * Symboltable, FILE * outputFile);

#endif