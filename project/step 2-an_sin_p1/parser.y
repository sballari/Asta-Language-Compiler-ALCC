%{
    #define YYSTYPE int
    #include <stdio.h>
    int yylex();
    void yyerror(char *s);
%}

%token NUMBER
%left  '+' '-'   
%left  '*' '/'
%right UMINUS

%%


lines   : lines AEXPR '\n' {printf("%i \n",$2);}
        | lines '\n'
        |
        ;

AEXPR   : AEXPR '+' AEXPR {$$ = $1 + $3;}
        | AEXPR '-' AEXPR {$$ = $1 - $3;}
        | AEXPR '*' AEXPR {$$ = $1 * $3;}
        | AEXPR '/' AEXPR {$$ = $1 / $3;}
        | '(' AEXPR ')'   {$$ = $2;}
        | '-' AEXPR %prec UMINUS {$$ = -$2;}
        | NUMBER
        ;
%%

int main() {
    if (yyparse() != 0)
        printf("Abnormal exit\n");
    return 0;
}
void yyerror(char *s) {}