	%{
		#include "semantic_type.h"
		#include <stdio.h>
		#include <ctype.h>
		#define _OPEN_SYS_ITOA_EXT
		#include <stdarg.h>
		#include "translated_code_utilities.h"
	
		extern FILE *yyin;
		int yylex();
		void yyerror(char *s);

		int fresh_counter = 0;
		int label_counter = 0;
		char* tmp();
		bool checkVar(char* var_name);
		void gen(int arg_count, ...);
		char* newLabel();
		FILE* out3AC;
%}

%define api.value.type {struct semantic_type}

%token DECLARE AS ASSIGN_OP P_TYPE PRINT ENDFILE ID NUMBER REL_OP AND OR NOT TRUE FALSE LOOP DO IF 

%left  '+' '-'   
%left  '*' '/'
%precedence THEN
%precedence ELSE
%right UMINUS
%left OR
%left AND
%right NOT
%%

Prog    : Stms ENDFILE {return 0;}

Stms    : Stms Stm    {gen(2,$1.next,": ;"); $$.next = newLabel();}
		| /* empty */ {$$.next = newLabel();}
		;

Stm     : ID ASSIGN_OP Aexpr  ';' 	{getVar($1.lexeme); gen(6,"setVar(\"",$1.lexeme,"\",",$3.addr,")",";");}
		| DECLARE ID AS Type  ';'  	{addVar($2.lexeme); gen(4,"addVar(\"",$2.lexeme,"\")",";");}  
		| PRINT '(' Aexpr ')' ';'   {gen(4,"printf(\"%i\\n\"",",",$3.addr,");");}
		| BO Stms BC
		| LOOP L Bexpr O DO P Stm   {gen(3,"goto ",$2.begin,";");}
		| IF Bexpr THEN M Stm 		{gen(4,$4.b_false,": ;\n goto ",$4.next,";");}
		| IF Bexpr THEN M Stm ELSE N Stm
		;

M		: 	{$$.next = $-3.next; $$.b_false = newLabel(); gen(5,"if (!",$-1.addr, ") goto ",$$.b_false,";" );}

N 		:   {$$.next = $-6.next; $$.b_false = $-2.b_false; gen(3,"goto ",$$.next,";" ); gen(2,$$.b_false,": ;");}

L		: 	{$$.begin = newLabel(); gen(2,$$.begin,": ;");}

O		:	{gen(5,"if (!",$0.addr, ") goto ",$-3.next,";");}

P		:	{$$.next = $-5.next;}

BO      :   '{' {push(); gen(2,"push()",";");}
	    ;

BC      :   '}' {pop(); gen(2,"pop()",";");}
		;        

Type    : P_TYPE
		;

Aexpr   : Aexpr '+' Aexpr 		 {$$.addr = tmp(); gen(7,"int ",$$.addr, " = ", $1.addr, " + ", $3.addr, ";");}
		| Aexpr '-' Aexpr 		 {$$.addr = tmp(); gen(7,"int ",$$.addr, " = ", $1.addr, " - ", $3.addr, ";");}
		| Aexpr '*' Aexpr 		 {$$.addr = tmp(); gen(7,"int ",$$.addr, " = ", $1.addr, " * ", $3.addr, ";");}
		| Aexpr '/' Aexpr 		 {$$.addr = tmp(); gen(7,"int ",$$.addr, " = ", $1.addr, " / ", $3.addr, ";");}
		| '(' Aexpr ')'   		 {$$.addr = $2.addr;}
		| '-' Aexpr %prec UMINUS {$$.addr = tmp(); gen(6,"int ",$$.addr, " = ", "- ", $2.addr, ";");}
		| NUMBER 				 {$$.addr = tmp(); gen(5,"int ",$$.addr," = ",$1.lexeme, ";");}
		| ID 					 {getVar($1.lexeme);$$.addr = tmp(); gen(6,"int ",$$.addr," = getVar(\"",$1.lexeme,"\")", ";");}
		;

Bexpr	: Bexpr OR Bexpr  		{$$.addr = tmp(); gen(7,"int ",$$.addr, " = ", $1.addr, " OR ", $3.addr, ";");}
		| Bexpr AND Bexpr 		{$$.addr = tmp(); gen(7,"int ",$$.addr, " = ", $1.addr, " AND ", $3.addr, ";");}
		| NOT Bexpr 			{$$.addr = tmp(); gen(6,"int ",$$.addr, " = ", "!", $2.addr, ";");}
		| Aexpr REL_OP Aexpr 	{$$.addr = tmp(); gen(7,"int ",$$.addr," = ", $1.addr, $2.rel_op, $3.addr, ";");}
		| TRUE 					{$$.addr = "true";}
		| FALSE 				{$$.addr = "false";}
		| '(' Bexpr ')' 		{$$.addr = $2.addr;}
		;
%%

int main(int argc, char** argv) {
		stack = malloc(sizeof *stack);
		stack->symbol_table=NULL;
		stack->prec=NULL;
		if (argc > 1) yyin = fopen(argv[1], "r");
		if (argc > 2) out3AC = fopen(argv[2], "w");
		else   out3AC = stdout;
		gen(1,"#include \"translated_code_utilities.h\"");
		gen(1,"#include <stdio.h>");
		gen(1,"int main() {");
		gen(1,"stack = malloc(sizeof *stack);");
		gen(1,"stack->symbol_table=NULL;");
		gen(1,"stack->prec=NULL;");
		if (yyparse() != 0)
				printf("Abnormal exit\n");
		gen(1,"return 0;");
		gen(1,"}");
		if (stack->symbol_table != NULL) free(stack->symbol_table);
		free(stack);
		return 0;
}

void yyerror(char *s) {}

char* tmp() {      
				char* var_name = malloc(10 * sizeof *var_name);
				do{     
								snprintf(var_name,10,"t%i",fresh_counter);
								fresh_counter++; 
				} while (!checkVar(var_name));
				return var_name;
}

void gen(int arg_count, ...){
				va_list ap; 
				va_start(ap, arg_count); 
				
				for (int i = 0; i < arg_count; i++) 
								fprintf(out3AC,"%s",va_arg(ap, char*));
				fprintf(out3AC,"\n");
}

char* newLabel(){
	char* label = malloc(10 * sizeof *label);
	snprintf(label,10,"L%i",label_counter);
	label_counter++;
	return label; 
}
