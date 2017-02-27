%{
  #include <stdlib.h>
  #include <stdio.h>
  #include <string.h>

  typedef enum {
    KEY_PROGRAM=257,
    KEY_VAR,
    KEY_ARRAY,
    KEY_OF,
    KEY_INTEGER,
    KEY_REAL,
    KEY_FUNCTION,
    KEY_PROCEDURE,
    KEY_BEGIN,
    KEY_END,
    KEY_IF,
    KEY_THEN,
    KEY_ELSE,
    KEY_WHILE,
    KEY_DO,
    KEY_NOT,
    IDENTIFIER,
    NUMBER,
    OPS_REL,
    OPS_ADD,
    OPS_MULT,
    OPS_ASSIGN
  } token;

  typedef enum {
    OPS_REL_EQ,
    OPS_REL_NE,
    OPS_REL_LT,
    OPS_REL_LTE,
    OPS_REL_GTE,
    OPS_REL_GT
  } ops_rel_aux;

  typedef enum {
    OPS_ADD_PLUS,
    OPS_ADD_MINUS,
    OPS_ADD_OR
  } ops_add_aux;

  typedef enum {
    OPS_MULT_STAR,
    OPS_MULT_SLASH,
    OPS_MULT_DIV,
    OPS_MULT_MOD,
    OPS_MULT_AND
  } ops_mult_aux;

  typedef union Yystype_Union {
    int i;
    char *s;
  } ltype;
  ltype yylval;

  char **id_table=NULL;
  int id_table_size=0;
  char **num_table=NULL;
  int num_table_size=0;

  char* install_in_table (char ***table, int *table_size, char *string);
%}

/** Lex Options **/
%option noinput
%option nounput

/** Regular Definitions **/

/* whitespace */
delim  [ \t\n]
ws     {delim}+

/* comments */
comment  \{[^\{]*\}

/* basis */
letter  [a-zA-Z]
digit   [0-9]

/* identifier */
id  {letter}({letter}|{digit})*

/* number */
digits    {digit}+
fraction  \.{digits}
exponent  E[+-]?{digits}
num       {digits}({fraction})?({exponent})?

/* special characters */
special  [\(\)\[\]\.,;:]

%%

{ws}       {}
{comment}  {}

program    {return(KEY_PROGRAM);}
var        {return(KEY_VAR);}
array      {return(KEY_ARRAY);}
of         {return(KEY_OF);}
integer    {return(KEY_INTEGER);}
real       {return(KEY_REAL);}
function   {return(KEY_FUNCTION);}
procedure  {return(KEY_PROCEDURE);}
begin      {return(KEY_BEGIN);}
end        {return(KEY_END);}
if         {return(KEY_IF);}
then       {return(KEY_THEN);}
else       {return(KEY_ELSE);}
while      {return(KEY_WHILE);}
do         {return(KEY_DO);}
not        {return(KEY_NOT);}

{id}       {yylval.s=install_in_table(&id_table, &id_table_size, yytext); return(IDENTIFIER);}
{num}      {yylval.s=install_in_table(&num_table, &num_table_size, yytext); return(NUMBER);}

"="        {yylval.i=OPS_REL_EQ; return(OPS_REL);}
"<>"       {yylval.i=OPS_REL_NE; return(OPS_REL);}
"<"        {yylval.i=OPS_REL_LT; return(OPS_REL);}
"<="       {yylval.i=OPS_REL_LTE; return(OPS_REL);}
">="       {yylval.i=OPS_REL_GTE; return(OPS_REL);}
">"        {yylval.i=OPS_REL_GT; return(OPS_REL);}

"+"        {yylval.i=OPS_ADD_PLUS; return(OPS_ADD);}
"-"        {yylval.i=OPS_ADD_MINUS; return(OPS_ADD);}
or         {yylval.i=OPS_ADD_OR; return(OPS_ADD);}

"*"        {yylval.i=OPS_MULT_STAR; return(OPS_MULT);}
"/"        {yylval.i=OPS_MULT_SLASH; return(OPS_MULT);}
div        {yylval.i=OPS_MULT_DIV; return(OPS_MULT);}
mod        {yylval.i=OPS_MULT_MOD; return(OPS_MULT);}
and        {yylval.i=OPS_MULT_AND; return(OPS_MULT);}

":="       {return(OPS_ASSIGN);}

{special}  {return((int) yytext[0]);}

%%

int main (void) {
  int token;
  int cols = 0;
  const int MAX_COLS = 3;
  int lexeme_string_capacity = 11;
  char *lexeme_string = calloc(lexeme_string_capacity, sizeof(char));
  char token_string[7];

  while ((token = yylex())) {
    /* Create String for Lexeme (Left Side) */
    if (yyleng >= lexeme_string_capacity) {
      lexeme_string_capacity = yyleng+1;
      lexeme_string = realloc(lexeme_string, lexeme_string_capacity);
    }
    strcpy(lexeme_string, yytext);
    if (yy_flex_strlen(lexeme_string) > 10) { /* if long entry */
      printf("\n");                          /* print on own line */
      cols = MAX_COLS;
    }

    /* Create String for Token (Right Side) */
    if (token == OPS_REL || token == OPS_ADD || token == OPS_MULT)
      sprintf(token_string, "%d(%d)", token, yylval.i);
    else
      sprintf(token_string, "%d", token);

    /* Print Entry */
    printf("%-10s %6s", lexeme_string, token_string);

    /* Print Separators */
    if (cols < MAX_COLS) {
      printf(" | ");
      cols++;
    }
    else {
      printf("\n");
      cols = 0;
    }
  }

  printf("\n");

  /* Print Tables (for testing) */
  /* printf("\n"); */
  /* for (cols=0; cols<id_table_size; cols++) */
  /*   printf("ID: %s\n", id_table[cols]); */
  /* for (cols=0; cols<num_table_size; cols++) */
  /*   printf("NUM: %s\n", num_table[cols]); */

  free(lexeme_string);
  free(id_table);
  free(num_table);

  return 0;
}


char* install_in_table (char ***table, int *table_size, char *string) {
  int i; /* iterator */

  /* Check if the String is Already in the Table */
  for (i=0; i<*table_size; i++)
    if (strcmp((*table)[i], string) == 0)
      return id_table[i];

  /* Add the String to the Table */
  (*table_size)++;
  *table = realloc(*table, sizeof(char*)*(*table_size));
  (*table)[(*table_size)-1] = calloc(yy_flex_strlen(string), sizeof(char));
  strcpy((*table)[(*table_size)-1], yytext);
  return (*table)[(*table_size)-1];
}


int yywrap (void) {
  return 1;
}


