#ifndef UT
#define UT
#include <stdlib.h>
#include <stdbool.h>
#include "uthash.h"
#include <stdio.h>

typedef struct variable {
						const char* var_name;
						int value;
						UT_hash_handle hh;
} variable;

struct stackEl {
				variable* symbol_table;
				struct stackEl*  prec;
};

struct stackEl* stack;

void push();
void pop();
void delete_all();
void addVar (char *var_name);
void setVar (char *var_name, int value);
int getVar (char *var_name);
bool checkVar(char* var_name);


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
								//printf("tmp set :=(%p,%p)\n",current_stack,tmp);
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

#endif