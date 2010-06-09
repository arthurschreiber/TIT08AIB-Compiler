%{
//Prologue
#include "symbol_table.h"
#include "quadruple.h"
#include "jumplist.h"
#include "expression.h"
#include "statement.h"
#include "parameter_queue.h"
	
#include "y.tab.h"
	
#include <stdlib.h>
#include <stdbool.h>
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
	parameter_queue * param;
}

%token INT FLOAT VOID INC_OP DEC_OP LOG_AND LOG_OR NOT_EQUAL EQUAL
%token GREATER_OR_EQUAL LESS_OR_EQUAL SHIFTLEFT U_PLUS U_MINUS CONSTANT
%token IDENTIFIER IF ELSE DO WHILE RETURN

%type<string> IDENTIFIER id CONSTANT
%type<number> declaration_list declaration parameter_list function_body
%type<type> var_type

%type<quad> marker

%type<exp> expression assignment
%type<stmt> unmatched_statement statement goto_end matched_statement statement_list
%type<param> exp_list

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

add_return: /* empty */ {
	new_quadruple("", Q_RETURN, NULL, NULL);
}

function
: var_type id '(' parameter_list ')' ';' {
	update_and_append_scope(scope, $2, $1, $4);
	scope = new_symbol();
}
| var_type id '(' parameter_list ')' function_body add_return {
	update_and_append_scope(scope, $2, $1, $4);
	scope = new_symbol();
	// Generate a return quad here, so we can
	// handle the case of an if ... else as the last statement
	// in a function_body.
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
| statement_list marker statement  {
	backpatch($1->nextlist, $2);
	
	$$ = new_statement();
	$$->nextlist = $3->nextlist;
	backpatch($3->nextlist, get_next_quad());
}
;

goto_end: /* empty */ {
	$$ = new_statement();
	$$->nextlist = new_jumplist(get_next_quad());
	new_quadruple("", Q_GOTO, NULL, NULL);
};

statement
: matched_statement
| unmatched_statement
;

matched_statement
: IF '(' start_bool assignment end_bool ')' marker matched_statement goto_end ELSE marker matched_statement {
	$$ = new_statement();
	$$->nextlist = merge($9->nextlist, merge($8->nextlist, $12->nextlist));
		
	backpatch($4->truelist, $7);
	backpatch($4->falselist, $11);
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
| IF '(' start_bool assignment end_bool ')' marker matched_statement goto_end ELSE marker unmatched_statement {
	$$ = new_statement();
	$$->nextlist = merge($9->nextlist, merge($8->nextlist, $12->nextlist));
	
	backpatch($4->truelist, $7);
	backpatch($4->falselist, $11);
}
;

assignment
: expression {
	if (in_boolean_context) {
		$$ = new_expression();
		
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
	$$->type = INTEGER;
	
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
	$$->type = INTEGER;
	
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
	$$->type = INTEGER;
	
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
	$$->type = INTEGER;
	
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
	$$->type = INTEGER;
	
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
	$$->type = INTEGER;
	
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
	$$->type = INTEGER;
	
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
	$$->type = INTEGER;
	
	quadruple * true_quad, * false_quad;
	
	true_quad = new_quadruple("", Q_LESS, $1->sym, $3->sym);
	false_quad = new_quadruple("", Q_GOTO, NULL, NULL);
	true_quad->goto_next = new_quadruple(sym->name, Q_ASSIGNMENT, "1", NULL);
	false_quad->goto_next = get_next_quad();
}
| expression SHIFTLEFT expression {
	symtabEntry * sym = new_helper_variable($1->type, scope);
	symtabEntry * i = new_helper_variable(INTEGER, scope);
	
	new_quadruple(i->name, Q_ASSIGNMENT, $3->sym, "");
	new_quadruple(sym->name, Q_ASSIGNMENT, $1->sym, "");
	
	quadruple * quad = new_quadruple(NULL, Q_NOT_EQUAL, i->name, "0");
	quadruple * goto_quad = new_quadruple(NULL, Q_GOTO, NULL, NULL);
	quadruple * multiply_quad = new_quadruple(sym->name, Q_MULTIPLY, sym->name, "2");
	new_quadruple(i->name, Q_DEC, i->name, NULL);
	quadruple * back_quad = new_quadruple(NULL, Q_GOTO, NULL, NULL);
	
	quad->goto_next = multiply_quad;
	back_quad->goto_next = quad;
	goto_quad->goto_next = get_next_quad();
	
	$$ = new_expression();
	$$->sym = sym->name;
	$$->type = INTEGER;
} 
| expression '+' expression {
	symtabEntry * sym = new_helper_variable(REAL, scope);
	quadruple * quad = new_quadruple(sym->name, Q_PLUS, $1->sym, $3->sym);
	
	$$ = new_expression();
	$$->sym = quad->result;
	if ($1->type == $3->type) {
		$$->type = $1->type;
	} else {
		$$->type = REAL;
	}
} 
| expression '-' expression {
	symtabEntry * sym = new_helper_variable(REAL, scope);
	quadruple * quad = new_quadruple(sym->name, Q_MINUS, $1->sym, $3->sym);
	
	$$ = new_expression();
	$$->sym = quad->result;
	if ($1->type == $3->type) {
		$$->type = $1->type;
	} else {
		$$->type = REAL;
	}
} 
| expression '*' expression {
	symtabEntry * sym = new_helper_variable(REAL, scope);
	quadruple * quad = new_quadruple(sym->name, Q_MULTIPLY, $1->sym, $3->sym);
	
	$$ = new_expression();
	$$->sym = quad->result;
	if ($1->type == $3->type) {
		$$->type = $1->type;
	} else {
		$$->type = REAL;
	}
} 
| expression '/' expression {
	symtabEntry * sym = new_helper_variable(REAL, scope);
	quadruple * quad = new_quadruple(sym->name, Q_DIVIDE, $1->sym, $3->sym);
	
	$$ = new_expression();
	$$->sym = quad->result;
	if ($1->type == $3->type) {
		$$->type = $1->type;
	} else {
		$$->type = REAL;
	}
} 
| expression '%' expression {
	symtabEntry * sym = new_helper_variable($1->type, scope);
	quadruple * quad = new_quadruple(sym->name, Q_MOD, $1->sym, $3->sym);
	
	$$ = new_expression();
	$$->sym = quad->result;
	if ($1->type == $3->type) {
		$$->type = $1->type;
	} else {
		$$->type = REAL;
	}

}
| '!' expression {
	symtabEntry * sym = new_helper_variable(INTEGER, scope);
	new_quadruple(sym->name, Q_ASSIGNMENT, "0", NULL);
	
	$$ = new_expression();
	$$->sym = sym->name;
	$$->type = INTEGER;
	
	quadruple * true_quad, * false_quad;
	
	true_quad = new_quadruple("", Q_EQUAL, $2->sym, "0");
	false_quad = new_quadruple("", Q_GOTO, NULL, NULL);
	true_quad->goto_next = new_quadruple(sym->name, Q_ASSIGNMENT, "1", NULL);
	false_quad->goto_next = get_next_quad();
}
| '+' expression %prec U_PLUS {
	$$ = $2;
}
| '-' expression %prec U_MINUS {
	symtabEntry * sym = new_helper_variable($2->type, scope);
	quadruple * quad = new_quadruple(sym->name, Q_MINUS, "0", $2->sym);
	
	$$ = new_expression();
	$$->sym = quad->result;
}
| CONSTANT {
	$$ = new_expression();
	$$->sym = strdup($1);
	
	if (strchr($1, '.')) {
		$$->type = REAL;
	} else {
		$$->type = INTEGER;
	}
}
| '(' expression ')' {
	$$ = $2;
}
| id '(' exp_list ')' {
	int param_count = 0;
	parameter_queue * start = $3;
	
	while (start != NULL) {
		new_quadruple(NULL, Q_PARAM, start->sym, NULL);
		start = start->next;
		param_count++;
	}

	function_and_parameter_check($1, param_count);
	
	char * call = (char *) malloc(sizeof(char) * 100);
	sprintf(call, "CALL %s, %i", $1, param_count);

	symtabEntry * sym = new_helper_variable(INTEGER, scope);
	new_quadruple(sym->name, Q_ASSIGNMENT, call, NULL);
	
	$$ = new_expression();
  $$->sym = sym->name;
	$$->type = get_function_type($1);
}
| id '('  ')' {
	function_and_parameter_check($1, 0);
	
	char * call = (char *) malloc(sizeof(char) * 100);
	sprintf(call, "CALL %s, 0", $1);
	
	symtabEntry * sym = new_helper_variable(INTEGER, scope);
	new_quadruple(sym->name, Q_ASSIGNMENT, call, NULL);
	
	$$ = new_expression();
  $$->sym = sym->name;
	$$->type = get_function_type($1);
}
| id {
	variable_check($1, scope);
	
	$$ = new_expression();
	$$->sym = strdup($1);
	$$->type = get_variable_type($1, scope);
}
;

exp_list
: expression { $$ = new_parameter_queue($1->sym); }
| exp_list ',' expression	{ $$ = $1; add_param($1, $3->sym); }
;

id
: IDENTIFIER
;

%%
//Epilogue