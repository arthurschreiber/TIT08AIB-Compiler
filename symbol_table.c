/*
 *  symbol_table.c
 *  compilerbau
 *
 *  Created by Arthur Schreiber on 07.06.10.
 *  Copyright 2010 -/-. All rights reserved.
 *
 */

#include <stdlib.h>
#include <stdio.h>
#include <string.h>
#include "symbol_table.h"
#include "quadruple.h"

extern symtabEntry * theSymboltable;

void writeSymboltable (symtabEntry * Symboltable, FILE * outputFile){
	//writes the Symboltable in the outFile formated in a table view 
	
	fprintf (outputFile, "Symboltabelle\n");
	fprintf (outputFile, "Nr\tName                    Type    Int_Typ Offset\tLine\tIndex1\tIndex2\tVater\tParameter\n");
	fprintf (outputFile, "---------------------------------------------------------------------------------------------\n");
	
	
	//variables
	symtabEntry * currentEntry;  	//pointer for the current Symboltable entry for walking through the list
	int j;							//help variable, to build a string with the same length
	char helpString[21];			//string for formatted output
	
	
	currentEntry = Symboltable;
	do{
		//walks through the Symboltable
		fprintf(outputFile, "%d:\t",currentEntry->number); 
		
		
		strncpy(helpString,currentEntry->name,20);
		for(j=19;j>=strlen(currentEntry->name);j--){
			//loop for formating the output to file 
			helpString[j]=' ';
		}
		helpString[20]=0;
		fprintf(outputFile, "%s\t",helpString);
		
		getSymbolTypePrintout(currentEntry->type,helpString);
		fprintf(outputFile, "%s",helpString);
		
		getSymbolTypePrintout(currentEntry->internType,helpString);
		fprintf(outputFile, "%s",helpString);
		
		fprintf(outputFile, "%d\t\t",currentEntry->offset);
		fprintf(outputFile, "%d\t\t",currentEntry->line);
		fprintf(outputFile, "%d\t\t",currentEntry->index1);
		fprintf(outputFile, "%d\t\t",currentEntry->index2);
		if(currentEntry->vater){
			fprintf(outputFile, "%d\t\t",currentEntry->vater->number);
		}else{
			fprintf(outputFile, "0\t\t");
		}
		fprintf(outputFile, "%d\t\t\n",currentEntry->parameter);
		
		fflush(outputFile);
		
		currentEntry=currentEntry->next;
	}while(currentEntry);
	
}


void getSymbolTypePrintout(symtabEntryType  type, char * writeIn){
	//puts the printout for a given SymbolEntrytype to the given string
	switch(type){
		case PROG:     strcpy(writeIn,"Prg     ")  ;break;
		case NOP :     strcpy(writeIn,"None    ")  ;break;
		case REAL:     strcpy(writeIn,"Real    ")  ;break;
		case BOOL: 	   strcpy(writeIn,"Bool    ")  ;break;
		case INTEGER : strcpy(writeIn,"Int     ")  ;break;
		case ARR :     strcpy(writeIn,"Array   ")  ;break;
		case FUNC:     strcpy(writeIn,"Func    ")  ;break;
		case PROC:     strcpy(writeIn,"Proc    ")  ;break;
		case PRG_PARA: strcpy(writeIn,"P.Prmtr ")  ;break;
		default:       strcpy(writeIn,"        ")  ;break;
	}
}

symtabEntry * find_symbol_in_scope(char * name, symtabEntry * scope) {
	symtabEntry * current_symbol = scope;
	if (current_symbol == NULL) return NULL;
	
	do  {
		if (strcmp(current_symbol->name, name) == 0) {
			return current_symbol;
		}
	} while (current_symbol->next && (current_symbol = current_symbol->next));
	
	return NULL;
}

symtabEntry * find_symbol(char * name, symtabEntry * vater) {
	symtabEntry * current_symbol = theSymboltable;
	if (current_symbol == NULL) return NULL;
	
	do  {
		if (current_symbol->vater == vater) {
			if (strcmp(current_symbol->name, name) == 0) {
				return current_symbol;
			}
		}
	} while (current_symbol->next && (current_symbol = current_symbol->next));
	
	return NULL;
}

symtabEntry * new_symbol() {
	symtabEntry * symbol = (symtabEntry *) malloc(sizeof(symtabEntry));
	
	symbol->name 		= strdup("");
	symbol->type 		= NOP;
	symbol->internType 	= NOP;
	symbol->offset 		= 0;
	symbol->line 		= current_quad_line - 1;
	symbol->index1 		= 0;
	symbol->index2 		= 0;
	symbol->vater 		= 0;
	symbol->parameter 	= 0;
	symbol->next 		= 0;
	symbol->number		= 0;
	
	return symbol;
}

/**
 *  Hängt `symbol` an das Ende von `target`.
 **/
void append_symbol(symtabEntry * symbol, symtabEntry * target) {
	while (target->next) {
		target = target->next;
	}
	target->next = symbol;
	
	int i = target->number;
	
	do {
		symbol->number = (i += 1);
	} while ((symbol = symbol->next));
}

symtabEntry * new_variable(char * name, symtabEntryType type, symtabEntry * scope) {
	symtabEntry * symbol = new_symbol();
	
	symbol->name 		= strdup(name);
	symbol->offset 		= scope->offset;
	symbol->type 		= type;
	symbol->vater 		= scope;
	
	if (type == INTEGER) {
		scope->offset += 4;
	} else if (type == REAL) {
		scope->offset += 8;
	}
	
	append_symbol(symbol, scope);
	
	return symbol;
}

symtabEntry * new_param_variable(char * name, symtabEntryType type, symtabEntry * scope, int parameter) {
	symtabEntry * symbol = new_variable(name, type, scope);
 	symbol->parameter = parameter;
 	return symbol;
}

int unique_helper_id = 1;
symtabEntry * new_helper_variable(symtabEntryType type, symtabEntry * scope) {
	char * name = (char *) malloc(sizeof(char) * 10);
	sprintf(name, "H%i", unique_helper_id++);
	return new_variable(name, type, scope);
}

/**
 * Appends the passed `append_new_symbol` to the global symbol table.
 **/
void append_to_symbol_table(symtabEntry * append_new_symbol) {
	if (!theSymboltable) {
		theSymboltable = append_new_symbol;
	} else {
		append_symbol(append_new_symbol, theSymboltable);
	}
}

symtabEntry * find_parameter_symbol(symtabEntry * vater, int parameter_number, symtabEntry * current_symbol) {
	if (current_symbol == NULL) return NULL;
	
	do  {
		if (current_symbol->vater == vater) {
			if (current_symbol->parameter == parameter_number) {
				return current_symbol;
			}
		}
	} while (current_symbol->next && (current_symbol = current_symbol->next));
	
	return NULL;
}


void delete_symbol(symtabEntry * symbol) {
	symtabEntry * current_symbol = theSymboltable;
	if (current_symbol == NULL) return;
	
	if (current_symbol == symbol) {
		theSymboltable = symbol->next;
	}
	
	while (current_symbol) {
		if (current_symbol->next == symbol) {
			current_symbol->next = symbol->next;
		}
		
		if (current_symbol->number >= symbol->number) {
			current_symbol->number--;
		}
		current_symbol = current_symbol->next;
	}
}

void update_and_append_scope(symtabEntry * scope, char * name, symtabEntryType type, int parameter_count) {
	int i;
	
	symtabEntry * existing = find_symbol(name, 0);
	
	if (existing != NULL) {
		if (parameter_count != existing->parameter) {
			puts("Parameter count not matched.\n");
		} else {
			for (i = 0; i < parameter_count; ++i) {
				symtabEntry * param1 = find_parameter_symbol(scope, i + 1, scope);
				symtabEntry * param2 = find_parameter_symbol(existing, i + 1, theSymboltable);
				
				if (param1 == NULL) {
					puts("Could not find the parameter in the current scope");
				} else if (param2 == NULL) {
					puts("Could not find the parameter in the existing symbol table");
				} else if (param1->type != param2->type) {
					puts("Parameters of prototype do not match actual function definition in `__test__`\n");
				}
			}
		}
		
		for (i = 0; i < existing->parameter; ++i) {
			delete_symbol(find_parameter_symbol(existing, i + 1, theSymboltable));
		}
		delete_symbol(find_symbol(name, 0));
	}
	
	scope->name      = strdup(name);
	
	if (strcmp(scope->name, "main") == 0) {
		scope->type       = PROG;
	} else if (type == NOP) {
		scope->type       = PROC;
	} else {
		scope->type       = FUNC;
		scope->internType = type;
	}
	
	scope->parameter = parameter_count;
	
	append_to_symbol_table(scope);
}