// A hello world stack ret adress attack program

#include <stdlib.h>
#include <string.h>
#include <stdio.h>

int attack_sucessful(int value)
{
  printf("Attack Function!  (should not reach this point) %d\n", value);
  return 1;
}

int valid_function(int value)
{
  printf("Normal function! %d\n", value);

  return 0;
}

struct foo {
  char buffer[4];
  int (*function_pointer)(int);
};

int main(int argc, char** argv, char** envp) 
{
  struct foo *f = malloc(sizeof(*f));
  f->function_pointer = &valid_function;

  char string[256];
  scanf( "%s" , string );
  printf("Read  %s form IO\n");

  strcpy(f->buffer, string);
  //strcpy(f->buffer, argv[1]); //Variant with arguments passed

  int testvar = 5;
  int ret = 0;
  ret = f->function_pointer(testvar);

  if(ret == 0)
  {
    printf("Normal function executed\n");
  }
  else
  {
    printf("Attack Successful\n");
  }

  return 0;
}

