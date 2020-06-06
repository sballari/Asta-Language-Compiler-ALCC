#ifndef ST
#define ST

typedef struct semantic_type {
    char* lexeme;
    char* addr;
    char* b_true;
    char* b_false;
    char* rel_op;
    char* next;
}semantic_type;

#endif