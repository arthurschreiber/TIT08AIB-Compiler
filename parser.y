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
bool in_boolean_context = false;

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

start_bool: /* empty */ {
	in_boolean_context = true;
};

end_bool: /* empty */ {
	in_boolean_context = false;
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
: IF '(' start_bool assignment end_bool ')' marker matched_statement ELSE marker matched_statement {
	$$ = new_statement();
	$$->nextlist = merge($8->nextlist, $11->nextlist);
		
	backpatch($4->truelist, $7);
	backpatch($4->falselist, $10);
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
| WHILE '(' marker start_bool assignment end_bool ')' marker matched_statement {
	$$ = new_statement();
	backpatch($5->truelist, $8);
	
	$$->nextlist = $5->falselist;
	backpatch($9->nextlist, $3);
		
	quadruple * quad = new_quadruple("", Q_GOTO, NULL, NULL);
	quad->goto_next = $3;
}
| DO marker statement WHILE '(' marker start_bool assignment end_bool ')' ';' {
	$$ = new_statement();
	backpatch($8->truelist, $2);
	
	$$->nextlist = $8->falselist;
}
| '{' statement_list '}' { $$ = $2; }
| '{' '}' {
	$$ = new_statement();
}
;

unmatched_statement
: IF '(' start_bool assignment end_bool ')' marker statement {
	$$ = new_statement();
	
	backpatch($4->truelist, $7);
	$$->nextlist = merge($8->nextlist, $4->falselist);
	
}
| WHILE '(' marker start_bool assignment end_bool ')' marker unmatched_statement {
	$$ = new_statement();
	backpatch($5->truelist, $8);
	
	$$->nextlist = $5->falselist;
	backpatch($9->nextlist, $3);
	
	quadruple * quad = new_quadruple("", Q_GOTO, NULL, NULL);
	quad->goto_next = $3;
}
| IF '(' start_bool assignment end_bool ')' marker matched_statement ELSE marker unmatched_statement {
	$$ = new_statement();
	$$->nextlist = merge($8->nextlist, $11->nextlist);
	
	backpatch($4->truelist, $7);
	backpatch($4->falselist, $10);
}
;

assignment
: expression {
	if (in_boolean_context && $1->boolean == false) {
		$$ = new_expression();
		$$->boolean = true;
		
		$$->truelist = new_jumplist(get_next_quad());
		new_quadruple("", Q_NOT_EQUAL, $1->sym, "0");
		
		$$->falselist = new_jumplist(get_next_quad());
		new_quadruple("", Q_GOTO, NULL, NULL);
	} else {
		$$ = $1;
	}

}
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
	symtabEntry * sym = new_helper_variable(INTEGER, scope);
	new_quadruple(sym->name, Q_ASSIGNMENT, "1", NULL);
	
	$$ = new_expression();
	$$->sym = sym->name;
	
	quadruple * first_quad, * second_quad;
	
	first_quad = new_quadruple("", Q_NOT_EQUAL, $1->sym, "0");
	second_quad = new_quadruple("", Q_NOT_EQUAL, $4->sym, "0");
	new_quadruple(sym->name, Q_ASSIGNMENT, "0", NULL);
	first_quad->goto_next = second_quad->goto_next = get_next_quad();
}
| expression LOG_AND marker expression {
	symtabEntry * sym = new_helper_variable(INTEGER, scope);
	new_quadruple(sym->name, Q_ASSIGNMENT, "0", NULL);
	
	$$ = new_expression();
	$$->sym = sym->name;
	
	quadruple * first_quad, * second_quad;
	
	first_quad = new_quadruple("", Q_EQUAL, $1->sym, "0");
	second_quad = new_quadruple("", Q_EQUAL, $4->sym, "0");
	new_quadruple(sym->name, Q_ASSIGNMENT, "1", NULL);
	first_quad->goto_next = second_quad->goto_next = get_next_quad();
}
| expression NOT_EQUAL expression {
	symtabEntry * sym = new_helper_variable(INTEGER, scope);
	new_quadruple(sym->name, Q_ASSIGNMENT, "0", NULL);
	
	$$ = new_expression();
	$$->sym = sym->name;
	
	quadruple * true_quad, * false_quad;
	
	true_quad = new_quadruple("", Q_NOT_EQUAL, $1->sym, $3->sym);
	false_quad = new_quadruple("", Q_GOTO, NULL, NULL);
	true_quad->goto_next = new_quadruple(sym->name, Q_ASSIGNMENT, "1", NULL);
	false_quad->goto_next = get_next_quad();
}
| expression EQUAL expression {
	symtabEntry * sym = new_helper_variable(INTEGER, scope);
	new_quadruple(sym->name, Q_ASSIGNMENT, "0", NULL);
	
	$$ = new_expression();
	$$->sym = sym->name;
	
	quadruple * true_quad, * false_quad;
	
	true_quad = new_quadruple("", Q_EQUAL, $1->sym, $3->sym);
	false_quad = new_quadruple("", Q_GOTO, NULL, NULL);
	true_quad->goto_next = new_quadruple(sym->name, Q_ASSIGNMENT, "1", NULL);
	false_quad->goto_next = get_next_quad();
}
| expression GREATER_OR_EQUAL expression {
	symtabEntry * sym = new_helper_variable(INTEGER, scope);
	new_quadruple(sym->name, Q_ASSIGNMENT, "0", NULL);
	
	$$ = new_expression();
	$$->sym = sym->name;
	
	quadruple * true_quad, * false_quad;
	
	true_quad = new_quadruple("", Q_GREATER_OR_EQUAL, $1->sym, $3->sym);
	false_quad = new_quadruple("", Q_GOTO, NULL, NULL);
	true_quad->goto_next = new_quadruple(sym->name, Q_ASSIGNMENT, "1", NULL);
	false_quad->goto_next = get_next_quad();
}
| expression LESS_OR_EQUAL expression {
	symtabEntry * sym = new_helper_variable(INTEGER, scope);
	new_quadruple(sym->name, Q_ASSIGNMENT, "0", NULL);
	
	$$ = new_expression();
	$$->sym = sym->name;

	quadruple * true_quad, * false_quad;
	
	true_quad = new_quadruple("", Q_LESS_OR_EQUAL, $1->sym, $3->sym);
	false_quad = new_quadruple("", Q_GOTO, NULL, NULL);
	true_quad->goto_next = new_quadruple(sym->name, Q_ASSIGNMENT, "1", NULL);
	false_quad->goto_next = get_next_quad();
}
| expression '>' expression {
	symtabEntry * sym = new_helper_variable(INTEGER, scope);
	new_quadruple(sym->name, Q_ASSIGNMENT, "0", NULL);
	
	$$ = new_expression();
	$$->sym = sym->name;
	
	quadruple * true_quad, * false_quad;
	
	true_quad = new_quadruple("", Q_GREATER, $1->sym, $3->sym);
	false_quad = new_quadruple("", Q_GOTO, NULL, NULL);
	true_quad->goto_next = new_quadruple(sym->name, Q_ASSIGNMENT, "1", NULL);
	false_quad->goto_next = get_next_quad();
}
| expression '<' expression {
	symtabEntry * sym = new_helper_variable(INTEGER, scope);
	new_quadruple(sym->name, Q_ASSIGNMENT, "0", NULL);
	
	$$ = new_expression();
	$$->sym = sym->name;
	
	quadruple * true_quad, * false_quad;
	
	true_quad = new_quadruple("", Q_LESS, $1->sym, $3->sym);
	false_quad = new_quadruple("", Q_GOTO, NULL, NULL);
	true_quad->goto_next = new_quadruple(sym->name, Q_ASSIGNMENT, "1", NULL);
	false_quad->goto_next = get_next_quad();
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