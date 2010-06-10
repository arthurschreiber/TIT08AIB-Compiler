/*
 *  parameter_queue.h
 *  compilerbau
 *
 *  Created by Arthur Schreiber on 09.06.10.
 *  Copyright 2010 -/-. All rights reserved.
 *
 */

#ifndef PARAMETER_QUEUE_H
#define PARAMETER_QUEUE_H

typedef struct a_parameter_queue {
	char * sym;
	struct a_parameter_queue * next;
} parameter_queue;

parameter_queue * new_parameter_queue(char * sym);
void add_param(parameter_queue * start, char * sym);

#endif