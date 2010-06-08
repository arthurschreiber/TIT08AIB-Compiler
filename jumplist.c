/*
 *  jumplist.c
 *  compilerbau
 *
 *  Created by Arthur Schreiber on 07.06.10.
 *  Copyright 2010 -/-. All rights reserved.
 *
 */

#include <stdlib.h>
#include <stdio.h>
#include "jumplist.h"

void backpatch(jump * list, quadruple * quad) {
	if (list == NULL) { return; }
	
	do {
		if (list->quad != NULL) {
			list->quad->goto_next = quad;
		}
	} while ((list = list->next) != NULL);
}


jump * new_jumplist(quadruple * target) {
	jump * list = (jump *) malloc(sizeof(jump));
	list->quad = target;
	list->next = NULL;
	return list;
}

jump * merge(jump * list1, jump * list2) {
	if (list1 == NULL) {
		return list2;
	}
	
	jump * new_list = NULL;
	
	do {
		if (list1 == NULL) {
			break;
		}
		
		if (new_list == NULL) {
			new_list = new_jumplist(list1->quad);
		} else {
			new_list->next = new_jumplist(list1->quad);
		}
	} while ((list1 = list1->next) != NULL);
	
	do {
		if (list2 == NULL) {
			break;
		}
		
		if (new_list == NULL) {
			new_list = new_jumplist(list2->quad);
		} else {
			new_list->next = new_jumplist(list2->quad);
		}
	} while ((list2 = list2->next) != NULL);
	
	return new_list;
}