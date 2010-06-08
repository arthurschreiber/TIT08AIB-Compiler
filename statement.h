/*
 *  statement.h
 *  compilerbau
 *
 *  Created by Arthur Schreiber on 08.06.10.
 *  Copyright 2010 -/-. All rights reserved.
 *
 */
#ifndef STATEMENT_H
#define STATEMENT_H

#include <stdlib.h>
#include "jumplist.h"

typedef struct a_stmt {
	struct a_jump * nextlist;
} statement;

statement * new_statement();

#endif