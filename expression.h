/*
 *  expression.h
 *  compilerbau
 *
 *  Created by Arthur Schreiber on 08.06.10.
 *  Copyright 2010 -/-. All rights reserved.
 *
 */

#ifndef EXPRESSION_H
#define EXPRESSION_H

#include <stdlib.h>
#include "jumplist.h"
#include "symbol_table.h"

typedef struct a_exp {
	char * sym;
	struct a_jump * truelist;
	struct a_jump * falselist;
} expression;

expression * new_expression();

#endif
