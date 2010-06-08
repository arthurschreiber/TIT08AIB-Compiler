/*
 *  quadruple.c
 *  compilerbau
 *
 *  Created by Arthur Schreiber on 07.06.10.
 *  Copyright 2010 -/-. All rights reserved.
 *
 */

#include <stdlib.h>
#include <stdio.h>
#include "quadruple.h"

quadruple * new_empty_quad() {
	quadruple * quad = (quadruple *) malloc(sizeof(quadruple));

	quad->operand_1 = NULL;
	quad->operand_2 = NULL;
	quad->operator = Q_NOP;
	quad->result = NULL;
	quad->next = NULL;
	quad->goto_next = NULL;
	quad->line = 0;
	
	quad->truelist = NULL;
	quad->falselist = NULL;
	quad->nextlist = NULL;

	return quad;
}

void init_quadruples() {
	next_quad = new_empty_quad();
}


quadruple * get_next_quad() {
	return next_quad;
}

quadruple * new_quadruple(char * result, quad_type operator, char * operand_1, char* operand_2) {
	quadruple * quad = next_quad;
	
	quad->operand_1 = operand_1;
	quad->operand_2 = operand_2;
	quad->operator = operator;
	quad->result = result;
	
	append_quadrupel(quad);

	next_quad = new_empty_quad();
	
	return quad;
}

quadruple * quadList = NULL;
void append_quadrupel(quadruple * quad) {
	if (quadList == NULL) {
		quadList = quad;
	} else {
		quadruple * current_quad = quadList;
		while (current_quad->next) {
			current_quad = current_quad->next;
		}
		current_quad->next = quad;
	}
}

void compile_quadruplecode() {
	quadruple * current_quad = quadList;
	
	printf("--- Quadruplecode:\n");
	
	if (current_quad == NULL) {
		printf("Nothing to generate\n");
		return;
	}
	
	int curr_line = 0;
	do {
		if (current_quad->operator != Q_NOP) {
			current_quad->line = curr_line++;
		} else {
			current_quad->line = curr_line;
		}

	} while ((current_quad = current_quad->next) != NULL);
	
	current_quad = quadList;
	
	do {
		if (current_quad->operator == Q_NOP) {
			continue;
		}
		
		printf("%i: ", current_quad->line);
		switch (current_quad->operator) {
			case Q_ASSIGNMENT:
				printf("%s := %s \n", current_quad->result, current_quad->operand_1);
				break;
			case Q_INC:
				printf("%s := %s + 1\n", current_quad->result, current_quad->operand_1);
				break;
			case Q_DEC:
				printf("%s := %s - 1\n", current_quad->result, current_quad->operand_1);
				break;
			case Q_SHIFT:
				printf("%s := %s << %s\n", current_quad->result, current_quad->operand_1, current_quad->operand_2);
				break;
			case Q_MULTIPLY:
				printf("%s := %s * %s\n", current_quad->result, current_quad->operand_1, current_quad->operand_2);
				break;
			case Q_DIVIDE:
				printf("%s := %s / %s\n", current_quad->result, current_quad->operand_1, current_quad->operand_2);
				break;
			case Q_MOD:
				printf("%s := %s %% %s\n", current_quad->result, current_quad->operand_1, current_quad->operand_2);
				break;
			case Q_PLUS:
				printf("%s := %s + %s\n", current_quad->result, current_quad->operand_1, current_quad->operand_2);
				break;
			case Q_MINUS:
				printf("%s := %s - %s\n", current_quad->result, current_quad->operand_1, current_quad->operand_2);
				break;
			case Q_GREATER_OR_EQUAL:
				printf("if %s >= %s GOTO %i\n", current_quad->operand_1, current_quad->operand_2, current_quad->goto_next->line);
				break;
			case Q_LESS_OR_EQUAL:
				printf("if %s <= %s GOTO %i\n", current_quad->operand_1, current_quad->operand_2, current_quad->goto_next->line);
				break;
			case Q_GREATER:
				printf("if %s > %s GOTO %i\n", current_quad->operand_1, current_quad->operand_2, current_quad->goto_next->line);
				break;
			case Q_LESS:
				printf("if %s < %s GOTO %i\n", current_quad->operand_1, current_quad->operand_2, current_quad->goto_next->line);
				break;
			case Q_NOT_EQUAL:
				printf("if %s != %s GOTO %i\n", current_quad->operand_1, current_quad->operand_2, current_quad->goto_next->line);
				break;
			case Q_EQUAL:
				printf("if %s == %s GOTO %i\n", current_quad->operand_1, current_quad->operand_2, current_quad->goto_next->line);
				break;
			case Q_GOTO:
				if (current_quad->goto_next != NULL) {
					printf("GOTO %i\n", current_quad->goto_next->line);
				} else {
					printf("GOTO somewhere\n");
				}

				break;
			case Q_RETURN:
				printf("RETURN %s\n", current_quad->result);
			case Q_NOP:
				// Do nothing
				break;
			default:
				printf("Invalid operation!\n");
				break;
		}
		
	} while ((current_quad = current_quad->next) != NULL);
	
	printf("---");
}