/*
 *  expression.c
 *  compilerbau
 *
 *  Created by Arthur Schreiber on 08.06.10.
 *  Copyright 2010 -/-. All rights reserved.
 *
 */

#include "expression.h"

expression * new_expression() {
	expression * exp = (expression *) malloc(sizeof(expression));

	exp->sym = NULL;
	exp->falselist = NULL;
	exp->truelist = NULL;
	
	exp->boolean = false;

	return exp;
}
