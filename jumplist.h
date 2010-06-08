/*
 *  jumplist.h
 *  compilerbau
 *
 *  Created by Arthur Schreiber on 07.06.10.
 *  Copyright 2010 -/-. All rights reserved.
 *
 */

#ifndef JUMPLIST_H
#define JUMPLIST_H

#include "quadruple.h"

typedef struct a_jump {
	quadruple * quad;
	struct a_jump * next;
} jump;

void backpatch(jump * list, quadruple * quad);
jump * new_jumplist(quadruple * target);
jump * merge(jump * list1, jump * list2);

#endif