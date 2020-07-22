# Syntax
```
Stm : ID <- Aexpr ; 	
    | declare ID as Int ;  	
    | print ( Aexpr ) ;   
    | { Stms }
    | loop Bexpr do Stm   
    | if Bexpr then Stm 		
    | if Bexpr then Stm else Stm
    ;
    
Aexpr : Aexpr + Aexpr 		 
      | Aexpr - Aexpr 		 
      | Aexpr * Aexpr 		 
      | Aexpr / Aexpr 		 
      | ( Aexpr )   		 
      | - Aexpr  
      | NUMBER 				 
      | ID 		
      ; 
      
Bexpr : Bexpr || Bexpr  		
      | Bexpr && Bexpr 		
      | ! Bexpr 			
      | Aexpr REL_OP Aexpr 	
      | true 					
      | false 				
      | ( Bexpr ) 		
      ; 
   
REL_OP: <= | >= | < | > | =
ID:     {char}({char}|{char})*
NUMBER: {digit}+
char:   [a-zA-Z]
digit:  [0-9]
```

# How to generate 3AC C code
```
./dependencies.sh
./compile.sh
./parser source_path output.c /*if output.c is missing then stdout is used*/
gcc output.c
```
# Parsing example
example.alcc
```
declare x as Int; 
{x <- 2;} 
loop (x < 6) do {
     x <- x+2;
} 
print(x);
```
example.c
```
#include "symbol_table_utilities.h"
#include <stdio.h>
int main() { 
stack = malloc(sizeof *stack);
stack->symbol_table=NULL; 
stack->prec=NULL; addVar("x");
L0: ;
push();
int t0 = 2;
setVar("x",t0);
L2: ;
pop();
L1: ;
L5: ;
int t1 = getVar("x");
int t2 = 6; 
int t3 = t1<t2;
if (!t3) goto L4;
push();
int t4 = getVar("x");
int t5 = 2;
int t6 = t4 + t5;
setVar("x",t6);
L6: ; pop();
goto L5;
L4: ;
int t7 = getVar("x");
printf("%i\n",t7);
L8: ;
return 0;
} 
```

# Project Short Review (ITA)
https://docs.google.com/document/d/e/2PACX-1vSfIj61alMfsbo-M-qtigczfFlOTfdjSyWZM0tAr4IUGSrY_smq3qzdhaUXvEdOyHc8VDQLV1egDRtk/pub
