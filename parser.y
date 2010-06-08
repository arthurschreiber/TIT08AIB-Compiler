%{
//Prologue
#include "symbol_table.h"
#include "quadruple.h"
#include "jumplist.h"
#include "expression.h"
#include "statement.h"
	
#include "y.tab.h"

#include <stdlib.h>
#include <string.h>
	
symtabEntry * scope;

%}

//Bison declarations
%union
{
	int number;
	char * string;
	symtabEntryType type;
	quadruple * quad;
	statement * stmt;
	expression * exp;
}

%token INT FLOAT VOID INC_OP DEC_OP LOG_AND LOG_OR NOT_EQUAL EQUAL
%token GREATER_OR_EQUAL LESS_OR_EQUAL SHIFTLEFT U_PLUS U_MINUS CONSTANT
%token IDENTIFIER IF ELSE DO WHILE RETURN

%type<string> IDENTIFIER id CONSTANT
%type<number> declaration_list declaration parameter_list function_body
%type<type> var_type

%type<quad> marker

%type<exp> expression assignment
%type<stmt> unmatched_statement statement matched_statement statement_list

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

marker: /* empty */ {
	$$ = get_next_quad();
};

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
: statement {
	$$ = new_statement();
	$$->nextlist = $1->nextlist;
}
| statement_list marker statement  {
	backpatch($1->nextlist, $2);
	
	$$ = new_statement();
	$$->nextlist = $3->nextlist;
}
;

statement
: matched_statement
| unmatched_statement
;

matched_statement
: IF '(' assignment ')' marker matched_statement ELSE marker matched_statement {
	$$ = new_statement();
	$$->nextlist = merge($6->nextlist, $9->nextlist);
		
	backpatch($3->truelist, $5);
	backpatch($3->falselist, $8);
}
| assignment ';' {
	$$ = new_statement();
}
| RETURN ';' {
	new_quadruple("", Q_RETURN, NULL, NULL);
	$$ = new_statement();
}
| RETURN assignment ';' {
	new_quadruple($2->sym, Q_RETURN, NULL, NULL);
	$$ = new_statement();
}
| WHILE '(' marker assignment ')' marker matched_statement {
	$$ = new_statement();
	backpatch($4->truelist, $6);
	
	$$->nextlist = $4->falselist;
	backpatch($7->nextlist, $3);
		
	quadruple * quad = new_quadruple("", Q_GOTO, NULL, NULL);
	quad->goto_next = $3;
}
| DO marker statement WHILE '(' marker assignment ')' ';' {
	$$ = new_statement();
	backpatch($7->truelist, $2);
	
	$$->nextlist = $7->falselist;
}
| '{' statement_list '}' { $$ = $2; }
| '{' '}' {
	$$ = new_statement();
}
;

unmatched_statement
: IF '(' assignment ')' marker statement {
	$$ = new_statement();
	
	backpatch($3->truelist, $5);
	$$->nextlist = merge($6->nextlist, $3->falselist);
	
}
| WHILE '(' marker assignment ')' marker unmatched_statement {
	$$ = new_statement();
	backpatch($4->truelist, $6);
	
	$$->nextlist = $4->falselist;
	backpatch($7->nextlist, $3);
	
	quadruple * quad = new_quadruple("", Q_GOTO, NULL, NULL);
	quad->goto_next = $3;
}
| IF '(' assignment ')' marker matched_statement ELSE marker unmatched_statement {
	$$ = new_statement();
	$$->nextlist = merge($6->nextlist, $9->nextlist);
	
	backpatch($3->truelist, $5);
	backpatch($3->falselist, $8);
}
;

assignment
: expression                 
| id '=' expression {
	new_quadruple(strdup($1), Q_ASSIGNMENT, $3->sym, NULL);

	$$ = new_expression();
	$$->sym = strdup($1);
}
;

expression
: INC_OP expression {
	new_quadruple($2->sym, Q_INC, $2->sym, NULL);
	$$ = $2;
} 
| DEC_OP expression {
	new_quadruple($2->sym, Q_DEC, $2->sym, NULL);
	$$ = $2;
} 
| expression LOG_OR marker expression {
}
| expression LOG_AND marker expression {
}
| expression NOT_EQUAL expression {
	$$ = new_expression();
	$$->boolean = true;
	
	$$->truelist = new_jumplist(get_next_quad());
	new_quadruple("", Q_NOT_EQUAL, $1->sym, $3->sym);
	
	$$->falselist = new_jumplist(get_next_quad());
	new_quadruple("", Q_GOTO, NULL, NULL);
}
| expression EQUAL expression {
	$$ = new_expression();
	$$->boolean = true;
	
	$$->truelist = new_jumplist(get_next_quad());
	new_quadruple("", Q_EQUAL, $1->sym, $3->sym);
	
	$$->falselist = new_jumplist(get_next_quad());
	new_quadruple("", Q_GOTO, NULL, NULL);
}
| expression GREATER_OR_EQUAL expression {
	$$ = new_expression();
	$$->boolean = true;
	
	$$->truelist = new_jumplist(get_next_quad());
	new_quadruple("", Q_GREATER_OR_EQUAL, $1->sym, $3->sym);
	
	$$->falselist = new_jumplist(get_next_quad());
	new_quadruple("", Q_GOTO, NULL, NULL);
}
| expression LESS_OR_EQUAL expression {
	$$ = new_expression();
	$$->boolean = true;

	$$->truelist = new_jumplist(get_next_quad());
	new_quadruple("", Q_LESS_OR_EQUAL, $1->sym, $3->sym);

	$$->falselist = new_jumplist(get_next_quad());
	new_quadruple("", Q_GOTO, NULL, NULL);
}
| expression '>' expression {
	$$ = new_expression();
	$$->boolean = true;
	
	$$->truelist = new_jumplist(get_next_quad());
	new_quadruple("", Q_GREATER, $1->sym, $3->sym);
	
	$$->falselist = new_jumplist(get_next_quad());
	new_quadruple("", Q_GOTO, NULL, NULL);
}
| expression '<' expression {
	$$ = new_expression();
	$$->boolean = true;
	
	$$->truelist = new_jumplist(get_next_quad());
	new_quadruple("", Q_LESS, $1->sym, $3->sym);
	
	$$->falselist = new_jumplist(get_next_quad());
	new_quadruple("", Q_GOTO, NULL, NULL);
}
| expression SHIFTLEFT expression {
	symtabEntry * sym = new_helper_variable(INTEGER, scope);
	quadruple * quad = new_quadruple(sym->name, Q_SHIFT, $1->sym, $3->sym);
	
	$$ = new_expression();
	$$->sym = quad->result;
} 
| expression '+' expression {
	symtabEntry * sym = new_helper_variable(INTEGER, scope);
	quadruple * quad = new_quadruple(sym->name, Q_PLUS, $1->sym, $3->sym);
	
	$$ = new_expression();
	$$->sym = quad->result;
} 
| expression '-' expression {
	symtabEntry * sym = new_helper_variable(INTEGER, scope);
	quadruple * quad = new_quadruple(sym->name, Q_MINUS, $1->sym, $3->sym);
	
	$$ = new_expression();
	$$->sym = quad->result;
} 
| expression '*' expression {
	symtabEntry * sym = new_helper_variable(INTEGER, scope);
	quadruple * quad = new_quadruple(sym->name, Q_MULTIPLY, $1->sym, $3->sym);
	
	$$ = new_expression();
	$$->sym = quad->result;
} 
| expression '/' expression {
	symtabEntry * sym = new_helper_variable(INTEGER, scope);
	quadruple * quad = new_quadruple(sym->name, Q_DIVIDE, $1->sym, $3->sym);
	
	$$ = new_expression();
	$$->sym = quad->result;
} 
| expression '%' expression {
	symtabEntry * sym = new_helper_variable(INTEGER, scope);
	quadruple * quad = new_quadruple(sym->name, Q_MOD, $1->sym, $3->sym);
	
	$$ = new_expression();
	$$->sym = quad->result;
}
| '!' expression {
	$$ = new_expression();
	$$->truelist = $2->falselist;
	$$->falselist = $2->truelist;
}
| '+' expression %prec U_PLUS {
	$$ = $2;
}
| '-' expression %prec U_MINUS {
	symtabEntry * sym = new_helper_variable(INTEGER, scope);
	quadruple * quad = new_quadruple(sym->name, Q_MINUS, "0", $2->sym);
	
	$$ = new_expression();
	$$->sym = quad->result;
}
| CONSTANT {
	$$ = new_expression();
	$$->sym = strdup($1);
}
| '(' expression ')' {
	$$ = $2;
}
| id '(' exp_list ')' {
	$$ = new_expression();
	$$->sym = "func(args)";
}
| id '('  ')' {
	$$ = new_expression();
	$$->sym = "func(args)";
}
| id { 
	$$ = new_expression();
	$$->sym = strdup($1);
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