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
		int offset, symtabEntry * vater, int parameter) {

	symtabEntry * symbol = find_symbol(name, vater);

	if (symbol != NULL) {
		symbol->offset = offset;
	} else {
		symbol = append_new_symbol(name, type, internType, offset, vater, parameter);
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

/**
 *  Hängt `symbol` an das Ende von `target`.
**/
void append_symbol(symtabEntry * symbol, symtabEntry * target) {
	while (target->next) {
		target = target->next;
	}
	target->next = symbol;
	symbol->number = target->number + 1;
}

symtabEntry * append_new_symbol(char * name, symtabEntryType type, symtabEntryType internType,
		int offset, symtabEntry * vater, int parameter) {

	printf("Creating %s \n", name);

	symtabEntry * symbol = new_symbol();

	// allocates the memory for the new symtabEntry
	symbol->name 		= strdup(name);
	symbol->type 		= type;
	symbol->internType 	= internType;
	symbol->offset 		= offset;
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
        append_symbol(append_new_symbol, theSymboltable);
	}
}

symtabEntry * add_integer_param_symbol(char * name, symtabEntry * parent, int parameter) {
    symtabEntry * symbol = new_symbol();
    
    symbol->name 		= strdup(name);
	symbol->type 		= INTEGER;
	symbol->vater 		= parent;
	symbol->parameter 	= parameter;

    append_symbol(symbol, parent);
    
    return symbol;
}

symtabEntry * add_integer_symbol(char * name, symtabEntry * parent) {
	return find_or_create_symbol(name, INTEGER, NOP, 4, parent, 0);
}

symtabEntry * add_variable_declaration(char * name, symtabEntryType type, symtabEntry * parent) {
	switch (type) {
		case INTEGER:
			return add_integer_symbol(name, parent);
		case REAL:
			return add_real_symbol(name, parent);
		default:
			return NULL;
	}
}

symtabEntry * add_real_param_symbol(char * name, symtabEntry * parent, int parameter) {
	return find_or_create_symbol(name, REAL, NOP, 4, parent, parameter);
}

symtabEntry * add_real_symbol(char * name, symtabEntry * parent) {
	return find_or_create_symbol(name, REAL, NOP, 4, parent, 0);
}

symtabEntry * add_function_symbol(char * name, symtabEntryType type, int parameters, int body_offset) {
	symtabEntryType function_type = (type == NOP) ? PROC : FUNC;
	return find_or_create_symbol(name, function_type, type, parameters * 4 + body_offset, 0, parameters);
}



symtabEntry * find_parameter_symbol(symtabEntry * vater, int parameter_number) {
	symtabEntry * current_symbol = theSymboltable;
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

	do {
		if (current_symbol == symbol) {
			*current_symbol = *(current_symbol->next);
			return;
		}
	} while ((current_symbol = current_symbol->next));
}

void update_and_append_scope(symtabEntry * scope, char * name, symtabEntryType type, int parameter_count) {
	int i;

	printf("Searching for existing entries of %s\n", name);
	symtabEntry * existing = find_symbol(name, 0);

	if (existing != NULL) {
		if (parameter_count != existing->parameter) {
			yyerror("Parameter count not matched.\n");
		} else {
			for (i = 0; i < parameter_count; ++i) {
				printf("-- Searching for parameter %i\n", i + 1);
				symtabEntry * param1 = find_parameter_symbol(scope, i + 1);
				symtabEntry * param2 = find_parameter_symbol(existing, i + 1);

				if (param1->type != param2->type) {
					yyerror("Parameters of prototype do not match actual function definition in `__test__`\n");
				}
			}
		}

		for (i = 0; i < existing->parameter; ++i) {
			delete_symbol(find_parameter_symbol(existing, i + 1));
		}
		delete_symbol(find_symbol(name, 0));

		printf("Found \n");
	} else {
		printf("Found none\n");
	}


	scope->name      = strdup(name);
	scope->type      = type;
	scope->parameter = parameter_count;

    append_to_symbol_table(scope);
}

void yyerror(char * str) {
	printf("ERROR on Line #%i: %s \n", yyget_lineno(), str);
}

int yyparse(void);

extern symtabEntry * scope;

int main (void){
	// Stop eclipse console from buffering output...
	setvbuf(stdout, NULL, _IONBF, 0);

	scope = new_symbol();

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

