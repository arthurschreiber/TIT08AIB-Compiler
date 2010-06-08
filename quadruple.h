/*
 *  quadruple.h
 *  compilerbau
 *
 *  Created by Arthur Schreiber on 07.06.10.
 *  Copyright 2010 -/-. All rights reserved.
 *
 */

#ifndef QUADRUPLE_H
#define QUADRUPLE_H


typedef enum a_quad_type {
	Q_NOP, Q_ASSIGNMENT, Q_INC, Q_DEC, Q_SHIFT,
	Q_MULTIPLY, Q_DIVIDE, Q_MOD,
	Q_PLUS, Q_MINUS,
	
	Q_GREATER_OR_EQUAL, Q_LESS_OR_EQUAL, Q_EQUAL, Q_NOT_EQUAL, Q_GREATER, Q_LESS,
	Q_GOTO, Q_RETURN
} quad_type;

struct a_jump;

typedef struct a_quadruple {
	quad_type type;
	char * operand_1;
	char * operand_2;
	quad_type operator;
	char * result;
	int line;
	
	struct a_jump * truelist;
	struct a_jump * falselist;
	struct a_jump * nextlist;
	
	struct a_quadruple * next;
	struct a_quadruple * goto_next;
} quadruple;

quadruple * new_quadruple(char * result, quad_type operator, char * operand_1, char* operand_2);
void compile_quadruplecode();
void append_quadrupel(quadruple * quad);
void init_quadruples();

quadruple * get_next_quad();

quadruple * next_quad;

#endif