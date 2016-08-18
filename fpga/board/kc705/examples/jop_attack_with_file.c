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

#define read_csr(reg) ({ unsigned long __tmp; \
  asm volatile ("csrr %0, " #reg : "=r"(__tmp)); \
  __tmp; })

int main(int argc, char** argv, char** envp) 
{
  FILE *rm;
  int res;
  char string[256];
  struct foo *f = malloc(sizeof(*f));
  f->function_pointer = &valid_function;

  int debug_tag = 0;
  asm volatile ("ltag %0, 0(%1)":"=r"(debug_tag):"r"((string)));
  printf("String tag before scanf %x\n", debug_tag);

  printf("plase type some string\n");
  printf("CSR is %x\n", read_csr(0x800));
 rm = fopen("jop_input_hex.txt", "r");
if (rm != NULL) {
    while (!feof(rm)) {
        res = fread(string, 1, (sizeof string)-1, rm);
        string[res] = 0;
        printf("%s", string);
    }
    fclose(rm);
}
   printf("CSR is %x\n", read_csr(0x800));
  printf("Read  %s form IO\n", string);
  printf("Lenght  %d \n", strlen(string));
  asm volatile ("ltag %0, 0(%1)":"=r"(debug_tag):"r"((string)));
  printf("String tag after scanf %x\n", debug_tag);

asm volatile ("ltag %0, 0(%1)":"=r"(debug_tag):"r"((f->buffer)));
printf("\nf-buffer before strcpy %x\n", debug_tag);

  printf("Function pointer value before %x\n", f->function_pointer);
  asm volatile ("ltag %0, 0(%1)":"=r"(debug_tag):"r"(&(f->function_pointer)));
  printf("\nFunction pointer tag before %x\n", debug_tag);

  strcpy(f->buffer, string);
   printf("Function pointer value after %x\n", f->function_pointer);
   asm volatile ("ltag %0, 0(%1)":"=r"(debug_tag):"r"(&(f->function_pointer)));
   printf("\nFunction pointer tag after %x\n", debug_tag);

  //strcpy(f->buffer, argv[1]); //Variant with arguments passed

  asm volatile ("ltag %0, 0(%1)":"=r"(debug_tag):"r"((f->buffer)));
  printf("\nf-buffer after strcpy %x\n", debug_tag);
  asm volatile ("ltag %0, 0(%1)":"=r"(debug_tag):"r"((f->buffer + 8)));

  printf("\n\n");

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

