%{
//Prologue
#include "global.h"
#include "quadComp.tab.h"

symtabEntry * scope;

%}
//Bison declarations

%union
{
	int number;
	char * string;
	symtabEntryType type;
	exp * exp;
}

%token INT FLOAT VOID INC_OP DEC_OP LOG_AND LOG_OR NOT_EQUAL EQUAL
%token GREATER_OR_EQUAL LESS_OR_EQUAL SHIFTLEFT U_PLUS U_MINUS CONSTANT
%token IDENTIFIER IF ELSE DO WHILE RETURN

%type<string> IDENTIFIER id CONSTANT
%type<number> declaration_list declaration parameter_list function_body
%type<type> var_type
%type<exp> expression

%left LOG_AND LOG_OR
%left LESS_OR_EQUAL GREATER_OR_EQUAL NOT_EQUAL EQUAL '<' '>'
%left SHIFTLEFT
%left '-' '+'
%left '/' '*' '%'
%left U_PLUS U_MINUS INC_OP DEC_OP '!'

%%


programm
    : function                  
    | programm function         
    ;

function
    : var_type id '(' parameter_list ')' ';' {
	    update_and_append_scope(scope, $2, $1, $4);
    	scope = new_symbol();
    }
    | var_type id '(' parameter_list ')' function_body {
    	update_and_append_scope(scope, $2, $1, $4);
    	scope = new_symbol();
    }
    ;

function_body
    : '{' statement_list '}' { $$ = 0; printf("Exiting bla\n"); }
    | '{' declaration_list statement_list '}' { $$ = $2; printf("Exiting bla\n"); }
    | '{' declaration_list '}' { $$ = 2; printf("Exiting bla\n"); }
    ;

declaration_list
    : declaration ';'
    | declaration_list declaration ';'
    ;

declaration
    : INT id { $$ = INTEGER; new_variable($2, INTEGER, scope); }
    | FLOAT id { $$ = REAL; new_variable($2, REAL, scope); }
    | declaration ',' id { $$ = $1; new_variable($3, $1, scope); }
    ;

parameter_list
    : INT id { $$ = 1; new_param_variable($2, INTEGER, scope, $$); }
    | FLOAT id { $$ = 1; new_param_variable($2, REAL, scope, $$); }
    | parameter_list ',' INT id { $$ = $1 + 1; new_param_variable($4, INTEGER, scope, $$); }
    | parameter_list ',' FLOAT id { $$ = $1 + 1; new_param_variable($4, REAL, scope, $$); }
    | VOID { $$ = 0; }
    |      { $$ = 0; }
    ;

var_type
    : INT { $$ = INTEGER; }
    | VOID { $$ = NOP; }
    | FLOAT { $$ = REAL; }
    ;



statement_list
    : statement
    | statement_list statement  
    ;

statement
    : matched_statement
    | unmatched_statement
    ;

matched_statement
    : IF '(' assignment ')' matched_statement ELSE matched_statement
    | assignment ';'                                                
    | RETURN ';'                                                 
    | RETURN assignment ';'                                                  
    | WHILE '(' assignment ')' matched_statement                             
    | DO statement WHILE '(' assignment ')' ';'                              
    | '{' statement_list '}'                                                 
    | '{' '}'                                                                                                                                                                                       
    ;

unmatched_statement
    : IF '(' assignment ')' statement                       
    | WHILE '(' assignment ')' unmatched_statement          
    | IF '(' assignment ')' matched_statement ELSE unmatched_statement 
    ;


assignment
    : expression                 
    | id '='          expression {
    	if ($3->type == EXP_INT || $3->type == EXP_FLOAT) {
			printf("Genquad: %s := %s\n", $1, $3->value);
    	} else if ($3->type == EXP_SYMBOL) {
	    	printf("Genquad: %s := %s\n", $1, $3->value);
    	}
    }
    ;

expression
    : INC_OP expression                        {
		printf("Genquad: %s := %s + 1\n", $2->value, $2->value);
		$$ = $2;
	} 
    | DEC_OP expression                        {
		printf("Genquad: %s := %s - 1\n", $2->value, $2->value);
		$$ = $2;
	} 
    | expression LOG_OR           expression   
    | expression LOG_AND          expression
    | expression NOT_EQUAL        expression   
    | expression EQUAL            expression   
    | expression GREATER_OR_EQUAL expression   
    | expression LESS_OR_EQUAL    expression   
    | expression '>'              expression   
    | expression '<'              expression   
    | expression SHIFTLEFT        expression     {
		symtabEntry * sym = new_helper_variable(INTEGER, scope);
		
		printf("Genquad: %s := %s << %s\n", sym->name, $1->value, $3->value);
		
		$$ = new_exp_symbol(sym->name);
    } 
    | expression '+'              expression {
		symtabEntry * sym = new_helper_variable(INTEGER, scope);
		
		printf("Genquad: %s := %s + %s\n", sym->name, $1->value, $3->value);
		
		$$ = new_exp_symbol(sym->name);
    } 
    | expression '-'              expression   {
		symtabEntry * sym = new_helper_variable(INTEGER, scope);
		
		printf("Genquad: %s := %s - %s\n", sym->name, $1->value, $3->value);
		
		$$ = new_exp_symbol(sym->name);
    } 
    | expression '*'              expression   {
		symtabEntry * sym = new_helper_variable(INTEGER, scope);
		
		printf("Genquad: %s := %s * %s\n", sym->name, $1->value, $3->value);
		
		$$ = new_exp_symbol(sym->name);
    } 
    | expression '/'              expression   {
		symtabEntry * sym = new_helper_variable(INTEGER, scope);
		
		printf("Genquad: %s := %s / %s\n", sym->name, $1->value, $3->value);
		
		$$ = new_exp_symbol(sym->name);
    } 
    | expression '%'              expression   
    | '!' expression                           
    | '+' expression %prec U_PLUS              
    | '-' expression %prec U_MINUS             
    | CONSTANT                                  { $$ = new_exp_constant($1); }
    | '(' expression ')'                       
    | id '(' exp_list ')'                      
    | id '('  ')'                              
    | id 										{ $$ = new_exp_symbol($1); }
    ;

exp_list
    : expression
    | exp_list ',' expression	
    ;

id
    : IDENTIFIER
    ;
    
%%
//Epilogue