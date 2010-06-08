#include <stdlib.h>
#include <stdio.h>
#include <string.h>

#include "symbol_table.h"
#include "quadruple.h"
#include "jumplist.h"

void yyerror(char *);

// GLOBAL VARIABLES:
symtabEntry * theSymboltable = 0;    //pointer as a entry to the Symboltable, which is a linked list

extern int yyget_lineno (void);
extern FILE * yyin;

void yyerror(char * str) {
	printf("ERROR on Line #%i: %s \n", yyget_lineno(), str);
}

int yyparse(void);

extern symtabEntry * scope;

void start_debug() {

}

int main (void){
	init_quadruples();
	
	// Stop eclipse console from buffering output...
	setvbuf(stdout, NULL, _IONBF, 0);
	
	scope = new_symbol();
	
	if ((yyin = fopen("./input.code", "r")) != 0) {
		yyparse();
	} else {
		puts("No input file found!");
		return 1;
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
	
	compile_quadruplecode();
	
	return 1;
}