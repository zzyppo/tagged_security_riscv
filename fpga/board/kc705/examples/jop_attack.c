// A hello world stack ret adress attack program

#include <stdlib.h>
#include <string.h>
#include <stdio.h>

#define write_csr(reg, val) \
  asm volatile ("csrw " #reg ", %0" :: "r"(val))


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
  char string[256];
  int debug_tag = 0;


   write_csr(0x800, 0x7); //Switch on the checks

  if(argc == 2 || argc == 3)
  {
    if(!strcmp(argv[1], "off"))
      write_csr(0x800, 0x0); //Switch off the checks
  }

  f->function_pointer = &valid_function;

  printf("Function pointer value before strcpy: %x\n", f->function_pointer);
  asm volatile ("ltag %0, 0(%1)":"=r"(debug_tag):"r"(&(f->function_pointer)));
  printf("\nFunction pointer tag before strcpy: %x\n", debug_tag);

  if(argc > 2)
      strcpy(f->buffer, argv[2]); //Variant with arguments passed
  else
  {
      printf("Please type some string---------------------------------------\n");
      scanf( "%s" , &string[0]);
      printf("Read  %s form IO\n", string);
      strcpy(f->buffer, string);
  }

  printf("Function pointer value after strcpy: %x\n", f->function_pointer);
  asm volatile ("ltag %0, 0(%1)":"=r"(debug_tag):"r"(&(f->function_pointer)));
  printf("\nFunction pointer tag after strcpy: %x\n", debug_tag);

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

