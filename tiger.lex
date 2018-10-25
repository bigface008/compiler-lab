%{
/* Lab2 Attention: You are only allowed to add code in this file and start at Line 26.*/
#include <string.h>
#include "util.h"
#include "symbol.h"
#include "absyn.h"
#include "y.tab.h"
#include "errormsg.h"

int charPos=1;

int yywrap(void)
{
 charPos=1;
 return 1;
}

void adjust(void)
{
 EM_tokPos=charPos;
 charPos+=yyleng;
}

/*
* Please don't modify the lines above.
* You can add C declarations of your own below.
*/

/* @function: getstr
 * @input: a string literal
 * @output: the string value for the input which has all the escape sequences
 * translated into their meaning.
 */
char *getstr(const char *str)
{
    //optional: implement this function if you need it
    return NULL;
}

/* Part added by 516030910460 */
#define STRING_RECORD_UNIT_LEN 32
char *string_recorder;
int string_recorder_max_len = STRING_RECORD_UNIT_LEN;
int string_recorder_len = 0;
int string_token_pos = 0;
int comment_counter = 0;
int if_string = 0;

void initStringRecorder() {
    string_recorder_max_len = STRING_RECORD_UNIT_LEN;
    string_recorder_len = 0;
    string_recorder = (char *)malloc(string_recorder_max_len);
    memset(string_recorder, 0, string_recorder_max_len);
    string_token_pos = EM_tokPos;
}

void addToStringRecorder(const char *new_text, int new_text_len) {
//    printf("new text %s\n", new_text);
//    printf("string record %s\n", string_recorder);
    while (string_recorder_len + new_text_len >= string_recorder_max_len) {
        string_recorder_max_len += STRING_RECORD_UNIT_LEN;
    }
    char *temp_str = (char *)malloc(string_recorder_max_len);
    memset(temp_str, 0, string_recorder_max_len);
    memcpy(temp_str, string_recorder, string_recorder_len);
    memcpy(temp_str + string_recorder_len, new_text, new_text_len);
    string_recorder_len += new_text_len;
    free(string_recorder);
    string_recorder = temp_str;
}

%}
/* You can add lex definitions here. */
digits  [0-9]+
letters [a-zA-Z]+
whitespace [ \t\n]+
any [^ ]|[ ]
%Start COMMENT T_STRING ESCAPE
%%
  /*
  * Below is an example, which you can wipe out
  * and write reguler expressions and actions of your own.
  */
<INITIAL>{whitespace}        {adjust();}

<INITIAL>"array"             {adjust(); return ARRAY;}
<INITIAL>"if"                {adjust(); return IF;}
<INITIAL>"then"              {adjust(); return THEN;}
<INITIAL>"else"              {adjust(); return ELSE;}
<INITIAL>"while"             {adjust(); return WHILE;}
<INITIAL>"for"               {adjust(); return FOR;}
<INITIAL>"to"                {adjust(); return TO;}
<INITIAL>"do"                {adjust(); return DO;}
<INITIAL>"let"               {adjust(); return LET;}
<INITIAL>"in"                {adjust(); return IN;}
<INITIAL>"end"               {adjust(); return END;}
<INITIAL>"of"                {adjust(); return OF;}
<INITIAL>"break"             {adjust(); return BREAK;}
<INITIAL>"nil"               {adjust(); return NIL;}
<INITIAL>"function"          {adjust(); return FUNCTION;}
<INITIAL>"var"               {adjust(); return VAR;}
<INITIAL>"type"              {adjust(); return TYPE;}

<INITIAL>":="                {adjust(); return ASSIGN;}
<INITIAL>","                 {adjust(); return COMMA;}
<INITIAL>":"                 {adjust(); return COLON;}
<INITIAL>";"                 {adjust(); return SEMICOLON;}
<INITIAL>"("                 {adjust(); return LPAREN;}
<INITIAL>")"                 {adjust(); return RPAREN;}
<INITIAL>"["                 {adjust(); return LBRACK;}
<INITIAL>"]"                 {adjust(); return RBRACK;}
<INITIAL>"{"                 {adjust(); return LBRACE;}
<INITIAL>"}"                 {adjust(); return RBRACE;}
<INITIAL>"."                 {adjust(); return DOT;}
<INITIAL>"+"                 {adjust(); return PLUS;}
<INITIAL>"-"                 {adjust(); return MINUS;}
<INITIAL>"*"                 {adjust(); return TIMES;}
<INITIAL>"/"                 {adjust(); return DIVIDE;}
<INITIAL>"="                 {adjust(); return EQ;}
<INITIAL>"<>"                {adjust(); return NEQ;}
<INITIAL>"<="                {adjust(); return LE;}
<INITIAL>"<"                 {adjust(); return LT;}
<INITIAL>">="                {adjust(); return GE;}
<INITIAL>">"                 {adjust(); return GT;}
<INITIAL>"&"                 {adjust(); return AND;}
<INITIAL>"|"                 {adjust(); return OR;}

<INITIAL>"\""                {
                                 adjust();
                                 initStringRecorder();
                                 BEGIN T_STRING;
                             }
<T_STRING>"\\n"              {adjust(); addToStringRecorder("\n", 1);}
<T_STRING>"\\t"              {adjust(); addToStringRecorder("\t", 1);}
<T_STRING>"\\"\^[A-Za-z@\[\]\^_\\] {
                                 adjust();
                                 char *temp_str = (char *)malloc(2);
                                 temp_str[0] = yytext[2] - 64;
                                 temp_str[1] = 0;
                                 addToStringRecorder(temp_str, 1);
                                 free(temp_str);
                             }
<T_STRING>"\\"[0-9]{3}       {
                                 adjust();
                                 char *temp_str = (char *)malloc(2);
                                 temp_str[0] = atoi(yytext + 1);
                                 temp_str[1] = 0;
                                 addToStringRecorder(temp_str, 1);
                                 free(temp_str);
                             }
<T_STRING>"\\\""             {adjust(); addToStringRecorder("\"", 1);}
<T_STRING>"\\\\"             {adjust(); addToStringRecorder("\\", 1);}
<T_STRING>"\\"[ \t\n\f]+"\\" {adjust();}
<T_STRING>[^"\\\n]*          {adjust(); addToStringRecorder(yytext, yyleng);}
<T_STRING>"\""               {
                                 adjust();
                                 if (string_recorder_len == 0)
                                     yylval.sval = 0;
                                 else
                                     yylval.sval = String(string_recorder);
                                 EM_tokPos = string_token_pos;
                                 free(string_recorder);
                                 BEGIN INITIAL;
                                 return STRING;
                             }
<T_STRING>{any}              {adjust(); EM_error(charPos, "illegl character");}

<INITIAL>"/*"                {adjust(); comment_counter++; BEGIN COMMENT;}
<COMMENT>"/*"                {adjust(); comment_counter++;}
<COMMENT>"*/"                {
                                 adjust();
                                 comment_counter--;
                                 if (comment_counter == 0)
                                     BEGIN INITIAL;
                                 else if (comment_counter < 0)
                                     EM_error(charPos, "wrong comment");
                                 else
                                     continue;
                             }
<COMMENT>{any}               {adjust();}

<INITIAL>[0-9]+              {
                                 adjust();
                                 yylval.ival = atoi(yytext);
                                 return INT;
                             }
<INITIAL>{letters}[_a-zA-Z0-9]* {
                                    adjust();
                                    yylval.sval = String(yytext);
                                    return ID;
                                }
<INITIAL>{any}               {adjust(); EM_error(charPos, "illegal character");}
%%
