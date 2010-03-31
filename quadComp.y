%{
//Prologue
#include "quadComp.tab.h"
#include "global.h"

symtabEntry * scope = 0;

%}
//Bison declarations

%union
{
	int number;
	char * string;
}

%token INT FLOAT VOID INC_OP DEC_OP LOG_AND LOG_OR NOT_EQUAL EQUAL
%token GREATER_OR_EQUAL LESS_OR_EQUAL SHIFTLEFT U_PLUS U_MINUS CONSTANT
%token IDENTIFIER IF ELSE DO WHILE RETURN

%type<string> IDENTIFIER id
%type<number> declaration_list declaration parameter_list function_body

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
    : var_type id '(' parameter_list ')' ';' { scope = add_function_symbol($2, yyget_lineno(), $4, 0); printf("Entering bla\n"); }
    | var_type id '(' parameter_list ')' function_body { scope = add_function_symbol($2, yyget_lineno(), $4, $6); printf("Entering bla\n"); }
    ;

function_body
    : '{' statement_list '}' { $$ = 0; scope = 0; printf("Exiting bla\n"); }
    | '{' declaration_list statement_list '}' { $$ = $2; scope = 0; printf("Exiting bla\n"); }
    ;

declaration_list
    : declaration ';'
    | declaration_list declaration ';'
    ;

declaration
    : INT id { $$ = 4; add_integer_symbol($2, yyget_lineno(), scope); }
    | FLOAT id { $$ = 4; add_real_symbol($2, yyget_lineno(), scope); }
    | declaration ',' id { $$ = $1 + 4; }
    ;

parameter_list
    : INT id { $$ = 1; add_integer_param_symbol($2, yyget_lineno(), scope, $$); }
    | FLOAT id { $$ = 1; add_real_param_symbol($2, yyget_lineno(), scope, $$); }
    | parameter_list ',' INT id { $$ = $1 + 1; add_integer_param_symbol($4, yyget_lineno(), scope, $$); }
    | parameter_list ',' FLOAT id { $$ = $1 + 1; add_integer_param_symbol($4, yyget_lineno(), scope, $$); }
    | VOID { $$ = 0; }
    |      { $$ = 0; }         
    ;

var_type
    : INT 
    | VOID
    | FLOAT
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
    | id '='          expression 
    ;

expression
    : INC_OP expression                        
    | DEC_OP expression                        
    | expression LOG_OR           expression   
    | expression LOG_AND          expression   
    | expression NOT_EQUAL        expression   
    | expression EQUAL            expression   
    | expression GREATER_OR_EQUAL expression   
    | expression LESS_OR_EQUAL    expression   
    | expression '>'              expression   
    | expression '<'              expression   
    | expression SHIFTLEFT        expression   
    | expression '+'              expression   
    | expression '-'              expression   
    | expression '*'              expression   
    | expression '/'              expression   
    | expression '%'              expression   
    | '!' expression                           
    | '+' expression %prec U_PLUS              
    | '-' expression %prec U_MINUS             
    | CONSTANT                                 
    | '(' expression ')'                       
    | id '(' exp_list ')'                      
    | id '('  ')'                              
    | id
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