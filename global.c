#include "global.h"
#include <string.h>

// GLOBAL VARIABLES:
symtabEntry * theSymboltable = 0;    //pointer as a entry to the Symboltable, which is a linked list

extern int yyget_lineno (void);
extern FILE * yyin;

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

symtabEntry * find_or_create_symbol(char * name, symtabEntryType type, symtabEntryType internType,
		int offset, int line, int index1, int index2, symtabEntry * vater, int parameter) {

	symtabEntry * symbol = find_symbol(name, vater);

	if (symbol != NULL) {
		symbol->offset = offset;
		symbol->line = line;
	} else {
		symbol = append_new_symbol(name, type, internType, offset, line, index1, index2, vater, parameter);
	}

	return symbol;
}

symtabEntry * new_symbol() {
	symtabEntry * symbol = (symtabEntry *) malloc(sizeof(symtabEntry));

	symbol->name 		= strdup("");
	symbol->type 		= NOP;
	symbol->internType 	= NOP;
	symbol->offset 		= 0;
	symbol->line 		= 0;
	symbol->index1 		= 0;
	symbol->index2 		= 0;
	symbol->vater 		= 0;
	symbol->parameter 	= 0;
	symbol->next 		= 0;

	return symbol;
}

symtabEntry * append_new_symbol(char * name, symtabEntryType type, symtabEntryType internType,
		int offset, int line, int index1, int index2, symtabEntry * vater, int parameter) {

	printf("Creating %s \n", name);

	symtabEntry * symbol = new_symbol();

	// allocates the memory for the new symtabEntry
	symbol->name 		= strdup(name);
	symbol->type 		= type;
	symbol->internType 	= internType;
	symbol->offset 		= offset;
	symbol->line 		= line;
	symbol->index1 		= index1;
	symbol->index2 		= index2;
	symbol->vater 		= vater;
	symbol->parameter 	= parameter;
	symbol->next 		= 0;

	append_to_symbol_table(symbol);

	return symbol;
}

/**
 * Appends the passed `append_new_symbol` to the global symbol table.
**/
void append_to_symbol_table(symtabEntry * append_new_symbol) {
	if (!theSymboltable) {
		theSymboltable = append_new_symbol;
		append_new_symbol->number = 0;
	} else {
		symtabEntry * current_symbol = theSymboltable;
		while (current_symbol->next) {
			current_symbol = current_symbol->next;
		}
		current_symbol->next = append_new_symbol;
		append_new_symbol->number = current_symbol->number + 1;
	}
}

symtabEntry * add_integer_param_symbol(char * name, int line, symtabEntry * parent, int parameter) {
	return find_or_create_symbol(name, INTEGER, NOP, 4, line, 0, 0, parent, parameter);
}

symtabEntry * add_integer_symbol(char * name, int line, symtabEntry * parent) {
	return find_or_create_symbol(name, INTEGER, NOP, 4, line, 0, 0, parent, 0);
}

symtabEntry * add_variable_declaration(char * name, symtabEntryType type, int line, symtabEntry * parent) {
	switch (type) {
		case INTEGER:
			return add_integer_symbol(name, line, parent);
		case REAL:
			return add_real_symbol(name, line, parent);
		default:
			return NULL;
	}
}

symtabEntry * add_real_param_symbol(char * name, int line, symtabEntry * parent, int parameter) {
	return find_or_create_symbol(name, REAL, NOP, 4, line, 0, 0, parent, parameter);
}

symtabEntry * add_real_symbol(char * name, int line, symtabEntry * parent) {
	return find_or_create_symbol(name, REAL, NOP, 4, line, 0, 0, parent, 0);
}

symtabEntry * add_function_symbol(char * name, symtabEntryType type, int line, int parameters, int body_offset) {
	symtabEntryType function_type = (type == NOP) ? PROC : FUNC;
	return find_or_create_symbol(name, function_type, type, parameters * 4 + body_offset, line, 0, 0, 0, parameters);
}

void yyerror(char * str) {
	printf("ERROR on Line #%i: %s \n", yyget_lineno(), str);
}

int yyparse(void);

int main (void){
	if ((yyin = fopen("./input.c", "r")) != 0) {
		yyparse();
	}
	fclose(yyin);
	
	//sample for a valid symboltable
//	addSymboltableEntry(theSymboltable,"If_Demo"  , PROG,  		NOP, 18, 0, 0, 0, 0, 0 );
//	addSymboltableEntry(theSymboltable,"wert"     , INTEGER,	NOP,  0, 0, 0, 0, 0, 0 );
//	addSymboltableEntry(theSymboltable,"d"        , INTEGER,  	NOP,  4, 0, 0, 0, 0, 0 );
//	addSymboltableEntry(theSymboltable,"H0"       , BOOL,  		NOP,  8, 0, 0, 0, 0, 0 );
//	addSymboltableEntry(theSymboltable,"H1"       , BOOL,  		NOP,  9, 0, 0, 0, 0, 0 );
//	addSymboltableEntry(theSymboltable,"H2"       , BOOL,  		NOP, 10, 0, 0, 0, 0, 0 );
//	addSymboltableEntry(theSymboltable,"H3"       , BOOL,  		NOP, 11, 0, 0, 0, 0, 0 );
//	addSymboltableEntry(theSymboltable,"H4"       , BOOL,  		NOP, 12, 0, 0, 0, 0, 0 );
//	addSymboltableEntry(theSymboltable,"H5"       , BOOL,  		NOP, 13, 0, 0, 0, 0, 0 );
//	addSymboltableEntry(theSymboltable,"H6"       , BOOL,  		NOP, 14, 0, 0, 0, 0, 0 );
//	addSymboltableEntry(theSymboltable,"H7"       , BOOL,  		NOP, 15, 0, 0, 0, 0, 0 );
//	addSymboltableEntry(theSymboltable,"H8"       , BOOL,  		NOP, 16, 0, 0, 0, 0, 0 );
//	addSymboltableEntry(theSymboltable,"H9"       , BOOL,  		NOP, 17, 0, 0, 0, 0, 0 );
	
	FILE * outputFile;
	if((outputFile = fopen ("./Symboltable.txt","w")) != 0)
		writeSymboltable(theSymboltable, outputFile);
	fclose(outputFile);
	
	return 1;
}

