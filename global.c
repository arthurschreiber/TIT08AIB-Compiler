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
		symbol = new_symbol(name, type, internType, offset, line, index1, index2, vater, parameter);
	}

	return symbol;
}

symtabEntry * new_symbol(char * name, symtabEntryType type, symtabEntryType internType,
		int offset, int line, int index1, int index2, symtabEntry * vater, int parameter) {

	printf("Creating %s \n", name);

	symtabEntry * symbol = (symtabEntry *) malloc(sizeof(symtabEntry));

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
 * Appends the passed `new_symbol` to the global symbol table.
**/
void append_to_symbol_table(symtabEntry * new_symbol) {
	if (!theSymboltable) {
		theSymboltable = new_symbol;
		new_symbol->number = 0;
	} else {
		symtabEntry * current_symbol = theSymboltable;
		while (current_symbol->next) {
			current_symbol = current_symbol->next;
		}
		current_symbol->next = new_symbol;
		new_symbol->number = current_symbol->number + 1;
	}
}

symtabEntry * add_integer_param_symbol(char * name, int line, symtabEntry * parent, int parameter) {
	return find_or_create_symbol(name, INTEGER, NOP, 4, line, 0, 0, parent, 0);
}

symtabEntry * add_integer_symbol(char * name, int line, symtabEntry * parent) {
	return find_or_create_symbol(name, INTEGER, NOP, 4, line, 0, 0, parent, 0);
}

symtabEntry * add_real_param_symbol(char * name, int line, symtabEntry * parent, int parameter) {
	return find_or_create_symbol(name, REAL, NOP, 4, line, 0, 0, parent, 0);
}

symtabEntry * add_real_symbol(char * name, int line, symtabEntry * parent) {
	return find_or_create_symbol(name, REAL, NOP, 4, line, 0, 0, parent, 0);
}

symtabEntry * add_function_symbol(char * name, int line, int parameters, int body_offset) {
	return find_or_create_symbol(name, FUNC, NOP, parameters * 4 + body_offset, line, 0, 0, 0, parameters);
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
