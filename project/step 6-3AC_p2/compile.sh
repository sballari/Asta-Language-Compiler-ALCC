
bison -d -v -o parser.c  parser.y
flex -o scanner.c scanner.fl 
gcc -o parser parser.c scanner.c