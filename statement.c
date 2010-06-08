/*
 *  statement.c
 *  compilerbau
 *
 *  Created by Arthur Schreiber on 08.06.10.
 *  Copyright 2010 -/-. All rights reserved.
 *
 */

#include "statement.h"

statement * new_statement() {
	statement * stmt = (statement *) malloc(sizeof(statement));

	stmt->nextlist = NULL;

	return stmt;
}