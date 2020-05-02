%{
    #include <stdio.h>
    #include <ctype.h>
    #include "uthash.h"
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
%}

%union {
        int value;
        char* identifier;
}


%token <identifier> ID //Bison declaration to declare token(s) without specifying precedence.
%token <value> NUMBER
%token DECLARE AS ASSIGN_OP P_TYPE PRINT ENDFILE
%type <value> Aexpr

%left  '+' '-'   
%left  '*' '/'
%right UMINUS

%%

Prog    : Stms ENDFILE {return 0;} 

Stms    : Stms Stm
        |/* empty */ 
        ;

Stm     : ID ASSIGN_OP Aexpr ';' {setVar($1, $3);} 
        | DECLARE ID AS Type ';'  {addVar($2);}  
        | PRINT '(' Aexpr ')' ';'  {printf("%d\n",($3));}
        | BO Stms BC 
        ;

BO      : '{' {push(); printf("stack %p\n",stack);}
        ;

BC      : '}' {pop();printf("stack %p\n",stack);}
        ;        

Type    : P_TYPE
        ;

Aexpr   : Aexpr '+' Aexpr {$$ = $1 + $3;}
        | Aexpr '-' Aexpr {$$ = $1 - $3;}
        | Aexpr '*' Aexpr {$$ = $1 * $3;}
        | Aexpr '/' Aexpr {$$ = $1 / $3;}
        | '(' Aexpr ')'   {$$ = $2;}
        | '-' Aexpr %prec UMINUS {$$ = -$2;}
        | NUMBER
        | ID {$$ = getVar($1);}
        ;


%%

int main(int argc, char** argv) {
    stack = (struct stackEl*) malloc(sizeof(struct stackEl));
    stack->symbol_table=NULL;
    stack->prec=NULL;
    if (argc > 1) yyin = fopen(argv[1], "r");
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
