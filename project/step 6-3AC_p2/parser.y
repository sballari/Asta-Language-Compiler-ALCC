	%{
		#include "semantic_type.h"
		#include <stdio.h>
		#include <ctype.h>
		#include "uthash.h"
		#include <stdbool.h>
		#define _OPEN_SYS_ITOA_EXT
		#include <stdlib.h>
		#include <stdarg.h>
	

		extern FILE *yyin;
		int yylex();
		void yyerror(char *s);

		typedef struct variable {
						const char* var_name;
						int value;
						UT_hash_handle hh;
		} variable;

		struct stackEl {
						variable* symbol_table;
						struct stackEl*  prec;
		};

		struct stackEl* stack = NULL;
		void push();
		void pop();
		void delete_all();

		void addVar (char *var_name);
		void setVar (char *var_name, int value);
		int getVar (char *var_name);

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

Stms    : Stms Stm    {gen(2,$1.next,":\n"); $$.next = newLabel();}
		| /* empty */ {$$.next = newLabel();}
		;

Stm     : ID ASSIGN_OP Aexpr  ';' 	{getVar($1.lexeme); gen(6,"setVar(\"",$1.lexeme,"\",",$3.addr,")",";\n");}
		| DECLARE ID AS Type  ';'  	{addVar($2.lexeme);gen(4,"addVar(\"",$2.lexeme,"\")",";\n");}  
		| PRINT '(' Aexpr ')' ';'   {gen(4,"printf(getVar(\"",$3.addr,"\"))",";\n");}
		| BO Stms BC
		| LOOP L Bexpr O DO P Stm   {gen(3,"goto ",$2.begin,"\n");}
		| IF Bexpr THEN M Stm 		{gen(4,$4.b_false,":\n goto ",$4.next,"\n");}
		| IF Bexpr THEN M Stm ELSE N Stm
		;

M		: 	{$$.next = $-3.next; $$.b_false = newLabel(); gen(5,"ifFalse ",$-1.addr, " goto ",$$.b_false,";\n" );}

N 		:   {$$.next = $-6.next; $$.b_false = $-2.b_false; gen(3,"goto ",$$.next,";\n" ); gen(2,$$.b_false,":\n");}

L		: 	{$$.begin = newLabel(); gen(2,$$.begin,":\n");}

O		:	{gen(5,"ifFalse ",$0.addr, " goto ",$-3.next,";\n");}

P		:	{$$.next = $-5.next;}

BO      :   '{' {push(); gen(2,"push()",";\n");}
	    ;

BC      :   '}' {pop(); gen(2,"pop()",";\n");}
		;        

Type    : P_TYPE
		;

Aexpr   : Aexpr '+' Aexpr 		 {$$.addr = tmp(); gen(6,$$.addr, " = ", $1.addr, " + ", $3.addr, ";\n");}
		| Aexpr '-' Aexpr 		 {$$.addr = tmp(); gen(6,$$.addr, " = ", $1.addr, " - ", $3.addr, ";\n");}
		| Aexpr '*' Aexpr 		 {$$.addr = tmp(); gen(6,$$.addr, " = ", $1.addr, " * ", $3.addr, ";\n");}
		| Aexpr '/' Aexpr 		 {$$.addr = tmp(); gen(6,$$.addr, " = ", $1.addr, " / ", $3.addr, ";\n");}
		| '(' Aexpr ')'   		 {$$.addr = $2.addr;}
		| '-' Aexpr %prec UMINUS {$$.addr = tmp(); gen(5,$$.addr, " = ", "- ", $2.addr, ";\n");}
		| NUMBER 				 {$$.addr = tmp(); gen(4,$$.addr," = ",$1.lexeme, ";\n");}
		| ID 					 {getVar($1.lexeme);$$.addr = tmp(); gen(5,$$.addr," = getVar(\"",$1.lexeme,"\")", ";\n");}
		;

Bexpr	: Bexpr OR Bexpr  		{$$.addr = tmp(); gen(6,$$.addr, " = ", $1.addr, " OR ", $3.addr, ";\n");}
		| Bexpr AND Bexpr 		{$$.addr = tmp(); gen(6,$$.addr, " = ", $1.addr, " AND ", $3.addr, ";\n");}
		| NOT Bexpr 			{$$.addr = tmp(); gen(5,$$.addr, " = ", "! ", $2.addr, ";\n");}
		| Aexpr REL_OP Aexpr 	{$$.addr = tmp(); gen(6,$$.addr," = ", $1.addr, $2.rel_op, $3.addr, ";\n");}
		| TRUE 					{$$.addr = "true";}
		| FALSE 				{$$.addr = "false";}
		| '(' Bexpr ')' 		{$$.addr = $2.addr;}
		;
%%

int main(int argc, char** argv) {
		stack = (struct stackEl*) malloc(sizeof(struct stackEl));
		stack->symbol_table=NULL;
		stack->prec=NULL;
		if (argc > 1) yyin = fopen(argv[1], "r");
		if (argc > 2) out3AC = fopen(argv[2], "w");
		else   out3AC = stdout;
		if (yyparse() != 0)
				printf("Abnormal exit\n");
		if (stack->symbol_table != NULL) free(stack->symbol_table);
		free(stack);
		return 0;
}
void yyerror(char *s) {}

void addVar(char* var_name){
				variable *tmp;
				HASH_FIND_STR(stack->symbol_table, var_name, tmp);
				if (tmp==NULL) {
								tmp = (variable*) malloc(sizeof(variable));
								tmp->var_name = var_name;
								tmp->value = 0;
								HASH_ADD_KEYPTR(hh,stack->symbol_table,tmp->var_name,strlen(tmp->var_name),tmp);
								//printf("tmp add := (%p,%p)\n",stack,tmp);
				}
				else {
								fprintf(stderr, "ERROR: multiple declaration of variable %s.\n",var_name);
								exit(-1);
				}
}

void setVar(char* var_name, int value){
				variable *tmp=NULL;
				const struct stackEl* current_stack = stack;
				while (current_stack != NULL && tmp == NULL) {
								HASH_FIND_STR(current_stack->symbol_table, var_name, tmp);
								printf("tmp set :=(%p,%p)\n",current_stack,tmp);
								current_stack = current_stack->prec;
								
				}
				if (tmp==NULL) {
								fprintf(stderr, "ERROR: variable %s is not defined.\n",var_name); 
								exit(-1);
				} else tmp->value = value;
}

int getVar(char* var_name){
				variable *tmp=NULL;
				const struct stackEl* current_stack = stack;
				while (current_stack != NULL && tmp == NULL) {
								HASH_FIND_STR(current_stack->symbol_table, var_name, tmp);
								//printf("tmp get := (%p,%p)\n",current_stack,tmp);
								current_stack = current_stack->prec;
				}
				if (tmp==NULL) {
								fprintf(stderr, "ERROR: variable %s is not defined.\n",var_name); 
								exit(-1);
				}
				return tmp->value;
}

bool checkVar(char* var_name){
				variable *tmp=NULL;
				const struct stackEl* current_stack = stack;
				while (current_stack != NULL && tmp == NULL) {
								HASH_FIND_STR(current_stack->symbol_table, var_name, tmp);
								//printf("tmp check := (%p,%p)\n",current_stack,tmp);
								current_stack = current_stack->prec;
				}
				return (tmp==NULL);
}

void push() {
				struct stackEl* El = (struct stackEl*) malloc(sizeof(struct stackEl));
				El->prec=stack;
				El->symbol_table=NULL;
				stack = El;
}

void pop() {
				if (stack->symbol_table != NULL) delete_all();
				struct stackEl* tmp = stack;
				stack = tmp->prec;
				free(tmp);
}

/* delete symbol table on top of the stack*/
void delete_all() {
  struct variable *iter, *tmp;

  HASH_ITER(hh, stack->symbol_table, iter, tmp) {
    HASH_DEL(stack->symbol_table,iter);  /* delete; iter advances to next */
    free(iter);            /* optional- if you want to free  */
  }
}

char* tmp() {      
				char* var_name = (char*) malloc(10*sizeof(char));
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
}

char* newLabel(){
	char* label = (char*) malloc(10*sizeof(char));
	snprintf(label,10,"L%i",label_counter);
	label_counter++;
	return label; 
}