%{
    #include <stdio.h>
    #include <ctype.h>
    #include "uthash.h"
    #include <stdbool.h>
    #define _OPEN_SYS_ITOA_EXT
    #include <stdlib.h>

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


    void addVar (char *var_name);
    void setVar (char *var_name, int value);
    int getVar (char *var_name);

    int fresh_counter = 0;
    char* tmp();
    bool checkVar(char* var_name);
    void gen(char* a=NULL, char* b=NULL, char* c=NULL,char* d=NULL, char* e=NULL);
    FILE* out3AC = stdout;
%}

%union{
        
                char* lexema;
                char* addr;
        
}

%token DECLARE AS ASSIGN_OP P_TYPE PRINT ENDFILE

%token <lexema> ID //Bison declaration to declare token(s) without specifying precedence.
%token <lexema> NUMBER
%type <addr> Aexpr


%left  '+' '-'   
%left  '*' '/'
%right UMINUS

%%

Prog    : Stms ENDFILE {return 0;} 

Stms    : Stms Stm
        |/* empty */ 
        ;

Stm     : ID ASSIGN_OP Aexpr ';' {getVar($1.lexema); gen("setVar(\"",$1.lexema,"\",",$3.addr,")");}
        | DECLARE ID AS Type ';'  {addVar($2.lexema);gen("addVar(\"",$2.lexema,"\")");}  
        | PRINT '(' Aexpr ')' ';'  {gen("printf(getVar(\" ",$3.addr,"\")");}
        | BO Stms BC 
        ;

BO      : '{' {push(); gen("push()");}
        ;

BC      : '}' {pop(); gen("pop()");}
        ;        

Type    : P_TYPE
        ;

Aexpr   : Aexpr '+' Aexpr {$$.addr = tmp(); gen($$.addr, "=", $1.addr, "+", $3.addr);}
        | Aexpr '-' Aexpr {$$.addr = tmp(); gen($$.addr, "=", $1.addr, "-", $3.addr);}
        | Aexpr '*' Aexpr {$$.addr = tmp(); gen($$.addr, "=", $1.addr, "*", $3.addr);}
        | Aexpr '/' Aexpr {$$.addr = tmp(); gen($$.addr, "=", $1.addr, "/", $3.addr);}
        | '(' Aexpr ')'   {$$.addr = $2.addr;}
        | '-' Aexpr %prec UMINUS {$$.addr = tmp(); gen($$.addr, "=", "-", $2.addr);}
        | NUMBER {$$.addr = tmp(); gen($$.addr,"=",$1.lexema);}
        | ID {getVar($1.lexema);$$.addr = tmp(); gen($$.addr,"= getVar(\"",$1.lexema,"\")");}
        ;


%%

int main(int argc, char** argv) {
    stack = (struct stackEl*) malloc(sizeof(struct stackEl));
    stack->symbol_table=NULL;
    stack->prec=NULL;
    if (argc > 1) yyin = fopen(argv[1], "r");
    if (argc > 2) out3AC = fopen(argv[2], "w");
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
                printf("tmp add := (%p,%p)\n",stack,tmp);
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
                printf("tmp get := (%p,%p)\n",current_stack,tmp);
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
                printf("tmp get := (%p,%p)\n",current_stack,tmp);
                current_stack = current_stack->prec;
        }
        return (tmp!=NULL);
}

void push() {
        struct stackEl* El = (struct stackEl*) malloc(sizeof(struct stackEl));
        El->prec=stack;
        El->symbol_table=NULL;
        stack = El;
}

void pop() {
        struct stackEl* tmp = stack;
        stack = tmp->prec;
        if (tmp->symbol_table != NULL) free(tmp->symbol_table); //TODO, come pulire symbol table ricorsivamente
        free(tmp);
}

char* tmp() {      
        char* var_name = (char*) malloc(10*sizeof(char));
        do{     
                snprintf(var_name,10,"t%i",fresh_counter);
                fresh_counter++; 
        } while (!checkVar(var_name));
        return var_name;
}
void gen(const char* a,const char* b,const char* c,const char* d,const char* e){
        if (a!=NULL) fprintf{out3AC,"%s ",a}
        if (b!=NULL) fprintf{out3AC,"%s ",b}
        if (c!=NULL) fprintf{out3AC,"%s ",c}
        if (d!=NULL) fprintf{out3AC,"%s ",d}
        if (e!=NULL) fprintf{out3AC,"%s ",e}
        fprintf{out3AC,";\n"}

}
