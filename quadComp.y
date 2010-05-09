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
	quadruple * quad;
}

%token INT FLOAT VOID INC_OP DEC_OP LOG_AND LOG_OR NOT_EQUAL EQUAL
%token GREATER_OR_EQUAL LESS_OR_EQUAL SHIFTLEFT U_PLUS U_MINUS CONSTANT
%token IDENTIFIER IF ELSE DO WHILE RETURN

%type<string> IDENTIFIER id CONSTANT
%type<number> declaration_list declaration parameter_list function_body
%type<type> var_type
%type<quad> expression assignment unmatched_statement statement matched_statement statement_list

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
    : '{' statement_list '}' { $$ = 0; }
    | '{' declaration_list statement_list '}' { $$ = $2; }
    | '{' declaration_list '}' { $$ = 2; }
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
    | statement_list statement  {
    	backpatch($1->nextlist, $2);

		$$ = new_quadruple("", Q_NOP, NULL, NULL);
		$$->nextlist = $2->nextlist;
    }
    ;

statement
    : matched_statement
    | unmatched_statement
    ;

matched_statement
    : IF '(' assignment ')' matched_statement ELSE matched_statement {
    	backpatch($3->truelist, $5);
    	backpatch($3->falselist, $7);
    }
    | assignment ';'                                                
    | RETURN ';'                                                 	{
    	$$ = new_quadruple("", Q_RETURN, NULL, NULL);
    }
    | RETURN assignment ';'                                         {
    	$$ = new_quadruple($2->result, Q_RETURN, NULL, NULL);
    }
    | WHILE '(' assignment ')' matched_statement                    {
    	backpatch($3->truelist, $5);
    	backpatch($5->nextlist, $3);

		char * line = malloc(10 * sizeof(char));
		sprintf(line, "%i", $3->line);

		new_quadruple(line, Q_GOTO, NULL, NULL);
		
		$$ = new_quadruple("", Q_NOP, NULL, NULL);
		$$->nextlist = $3->falselist;
    }
    | DO statement WHILE '(' assignment ')' ';'                              
    | '{' statement_list '}'                                        {
    	$$ = $2;
    }
    | '{' '}'                                                                                                                                                                                       
    ;

unmatched_statement
    : IF '(' assignment ')' statement                       {
   		backpatch($3->truelist, $5);
    	
    	$$ = new_quadruple("", Q_NOP, NULL, NULL);
		$$->nextlist = merge($5->nextlist, $3->falselist);    	
    }
    | WHILE '(' assignment ')' unmatched_statement          
    | IF '(' assignment ')' matched_statement ELSE unmatched_statement 
    ;


assignment
    : expression                 
    | id '='          expression {
	    new_quadruple($1, Q_ASSIGNMENT, $3->result, NULL);
    	$$ = $3;
    }
    ;

expression
    : INC_OP expression                        {
    	$$ = new_quadruple($2->result, Q_INC, $2->result, NULL);
	} 
    | DEC_OP expression                        {
    	$$ = new_quadruple($2->result, Q_DEC, $2->result, NULL);
	} 
    | expression LOG_OR           expression   {
    	backpatch($1->falselist, $3);
    	
    	$$ = new_quadruple("", Q_NOP, NULL, NULL);
    	$$->truelist = merge($1->truelist, $3->truelist);
    	$$->falselist = $3->falselist;
    }
    | expression LOG_AND          expression   {
        backpatch($1->truelist, $3);
    	
    	$$ = new_quadruple("", Q_NOP, NULL, NULL);
    	$$->falselist = merge($1->falselist, $3->falselist);
    	$$->truelist = $3->truelist;
    }
    | expression NOT_EQUAL        expression   {
    	$$ = new_quadruple("", Q_NOP, NULL, NULL);
    	$$->truelist = new_jumplist(
    		new_quadruple("", Q_NOT_EQUAL, $1->result, $3->result)
    	);
		$$->falselist = new_jumplist(
			new_quadruple("", Q_GOTO, NULL, NULL)
		);
    }
    | expression EQUAL            expression   {
    	$$ = new_quadruple("", Q_NOP, NULL, NULL);
    	$$->truelist = new_jumplist(
    		new_quadruple("", Q_EQUAL, $1->result, $3->result)
    	);
		$$->falselist = new_jumplist(
			new_quadruple("", Q_GOTO, NULL, NULL)
		);
    }
    | expression GREATER_OR_EQUAL expression   {
    	$$ = new_quadruple("", Q_NOP, NULL, NULL);
    	$$->truelist = new_jumplist(
    		new_quadruple("", Q_GREATER_OR_EQUAL, $1->result, $3->result)
    	);
		$$->falselist = new_jumplist(
			new_quadruple("", Q_GOTO, NULL, NULL)
		);
    }
    | expression LESS_OR_EQUAL    expression   {
    	$$ = new_quadruple("", Q_NOP, NULL, NULL);
    	$$->truelist = new_jumplist(
    		new_quadruple("", Q_LESS_OR_EQUAL, $1->result, $3->result)
    	);
		$$->falselist = new_jumplist(
			new_quadruple("", Q_GOTO, NULL, NULL)
		);
    }
    | expression '>'              expression   	 {
    	$$ = new_quadruple("", Q_NOP, NULL, NULL);
    	$$->truelist = new_jumplist(
    		new_quadruple("", Q_GREATER, $1->result, $3->result)
    	);
		$$->falselist = new_jumplist(
			new_quadruple("", Q_GOTO, NULL, NULL)
		);
    }
    | expression '<'              expression   	{
    	$$ = new_quadruple("", Q_NOP, NULL, NULL);
    	$$->truelist = new_jumplist(
    		new_quadruple("", Q_LESS, $1->result, $3->result)
    	);
		$$->falselist = new_jumplist(
			new_quadruple("", Q_GOTO, NULL, NULL)
		);
    }
    | expression SHIFTLEFT        expression     {
		symtabEntry * sym = new_helper_variable(INTEGER, scope);
		$$ = new_quadruple(sym->name, Q_SHIFT, $1->result, $3->result);
    } 
    | expression '+'              expression {
		symtabEntry * sym = new_helper_variable(INTEGER, scope);
		$$ = new_quadruple(sym->name, Q_PLUS, $1->result, $3->result);
    } 
    | expression '-'              expression   {
		symtabEntry * sym = new_helper_variable(INTEGER, scope);
		$$ = new_quadruple(sym->name, Q_MINUS, $1->result, $3->result);
    } 
    | expression '*'              expression   {
		symtabEntry * sym = new_helper_variable(INTEGER, scope);
		$$ = new_quadruple(sym->name, Q_MULTIPLY, $1->result, $3->result);
    } 
    | expression '/'              expression   {
		symtabEntry * sym = new_helper_variable(INTEGER, scope);
		$$ = new_quadruple(sym->name, Q_DIVIDE, $1->result, $3->result);
    } 
    | expression '%'              expression   {
		symtabEntry * sym = new_helper_variable(INTEGER, scope);
		$$ = new_quadruple(sym->name, Q_MOD, $1->result, $3->result);
	}
    | '!' expression                           {
		$$ = new_quadruple("", Q_NOP, NULL, NULL);
    	$$->truelist = $2->falselist;
    	$$->falselist = $2->truelist;
    }
    | '+' expression %prec U_PLUS               {
		$$ = $2;
    }
    | '-' expression %prec U_MINUS              {
		symtabEntry * sym = new_helper_variable(INTEGER, scope);
		$$ = new_quadruple(sym->name, Q_MINUS, "0", $2->result);
    }
    | CONSTANT                                  {
		$$ = new_quadruple($1, Q_NOP, NULL, NULL);
    }
    | '(' expression ')'                        {
    	$$ = $2;
    }
    | id '(' exp_list ')'                       {
		$$ = new_quadruple("func(args)", Q_NOP, NULL, NULL);
    }
    | id '('  ')'                               {
		$$ = new_quadruple("func()", Q_NOP, NULL, NULL);
    }
    | id 										{ 
		$$ = new_quadruple($1, Q_NOP, NULL, NULL);
    }
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