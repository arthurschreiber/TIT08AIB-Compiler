all:
	bison -v -d -y parser.y
	flex -o scanner.yy.c scanner.l 
	gcc -Wall expression.c jumplist.c main.c quadruple.c statement.c symbol_table.c parameter_queue.c y.tab.c scanner.yy.c -o compiler

clean : 
	rm -f scanner.yy.c compiler y.tab.h y.tab.c	