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

    variable* symbol_table = NULL;
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
%token DECLARE AS ASSIGN_OP P_TYPE PRINT
%type <value> Aexpr

%precedence ENDFILE //Bison declaration to assign a precedence to a specific rule.
%left  ';'
%left  '+' '-'   
%left  '*' '/'
%right UMINUS

%%


Prog    : Stm ';' Prog
        | /*empty*/
        | Prog ENDFILE {return 0;}
        ; 

Stm     : ID ASSIGN_OP Aexpr  {setVar($1, $3);}
        | DECLARE ID AS Type  {addVar($2);}  
        | PRINT '(' Aexpr ')' {printf("%d\n",($3));}
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
    if (argc > 1) yyin = fopen(argv[1], "r");
    if (yyparse() != 0)
        printf("Abnormal exit\n");
    return 0;
}
void yyerror(char *s) {}

void addVar(char* var_name){
        variable *tmp;
        HASH_FIND_STR(symbol_table, var_name, tmp);
        if (tmp==NULL) {
                tmp = (variable*) malloc(sizeof(variable));
                tmp->var_name = var_name;
                tmp->value = 0;
                HASH_ADD_KEYPTR(hh,symbol_table,tmp->var_name,strlen(tmp->var_name),tmp);
        }
        else {
                fprintf(stderr, "ERROR: multiple declaration of variable %s.\n",var_name);
                exit(-1);
        }
}

void setVar(char* var_name, int value){
        variable *tmp;
        HASH_FIND_STR(symbol_table, var_name, tmp);
        if (tmp==NULL) {
                fprintf(stderr, "ERROR: variable %s is not defined.\n",var_name); 
                exit(-1);
        } else tmp->value = value;
}

int getVar(char* var_name){
        variable *tmp;
        HASH_FIND_STR(symbol_table, var_name, tmp);
        if (tmp==NULL) {
                fprintf(stderr, "ERROR: variable %s is not defined.\n",var_name); 
                exit(-1);
        }
        return tmp->value;
}