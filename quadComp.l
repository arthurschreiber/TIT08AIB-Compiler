%option noyywrap
%option nodefault

%{

#include <string.h>
#include "global.h"
#include "quadComp.tab.h"

%}


%%


int { return INT; }
float { return FLOAT; }
void { return VOID; }

\+\+ { return INC_OP; }
\-\- { return DEC_OP; }
&&   { return LOG_AND; }
\|\|   { return LOG_OR; }
\!\=   { return NOT_EQUAL; }
\=\=   { return EQUAL; }
\>\=   { return GREATER_OR_EQUAL; }
\<\=   { return LESS_OR_EQUAL; }
\<\<   { return SHIFTLEFT; }
\+   { return U_PLUS; }
\-   { return U_MINUS; }

if     { return IF; }
else   { return ELSE; }
do     { return DO; }
while  { return WHILE; }
return { return RETURN; }

(([1-9][0-9]*)|0)(\.[0-9]+)? { return CONSTANT; }
[a-z_A-Z][a-zA-Z_0-9]* { yylval.string = strdup(yytext); return IDENTIFIER; }

(\/\*(.*)\*\/)|\/\/(.*) { /* COMMENTS */ }

\n { yylineno++; }
([ ]|\t)* { }

[();,{}=/<*!] { return yytext[0]; }

. { printf("mystery character '%s'\n", yytext); return yytext[0]; }

%%