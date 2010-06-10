/*
 *  parameter_queue.c
 *  compilerbau
 *
 *  Created by Arthur Schreiber on 09.06.10.
 *  Copyright 2010 -/-. All rights reserved.
 *
 */

#include <stdlib.h>
#include "parameter_queue.h"

parameter_queue * new_parameter_queue(char * sym) {
	parameter_queue * param = (parameter_queue *) malloc(sizeof(parameter_queue));
	param->sym = sym;
	param->next = NULL;
	return param;
}

void add_param(parameter_queue * start, char * sym) {
	while (start->next != NULL) {
		start = start->next;
	}
	start->next = new_parameter_queue(sym);
}