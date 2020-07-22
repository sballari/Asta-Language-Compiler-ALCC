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

# How to generate the 3AC code
```
./dependencies.sh
./compile.sh
./parser source_path output.c /*if output.c is missing then stdout is used*/
gcc output.c
```
# Project Short Review (ITA)
https://docs.google.com/document/d/e/2PACX-1vSfIj61alMfsbo-M-qtigczfFlOTfdjSyWZM0tAr4IUGSrY_smq3qzdhaUXvEdOyHc8VDQLV1egDRtk/pub
