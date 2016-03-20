// A hello world stack ret adress attack program

#include <stdio.h>
#include "uart.h"

#define SYS_set_tagctrl 0x3100
extern long syscall(long num, long arg0, long arg1, long arg2);

void nix()
{
  int x = 5;
}

int test(int var)
{
int y = 4;
  y += var;
  long x[10];
  nix();
  x[12] =  (0xdeadbeef);
  return y;
}

int main() {
long a[2];
int test_tag = 0;

asm volatile ("ltag %0, 0(%1)":"=r"(test_tag):"r"((a)));
   //syscall(SYS_set_tagctrl, 0x0000001, 0x0, 0x0); //Switch on the tag control
   syscall(SYS_set_tagctrl, 0x0000000, 0x0, 0x0); //Switch off the tag control
  uart_init();
 // printf("Hello World!\n");
  test(1111);
  asm volatile ("ltag %0, 0(%1)":"=r"(test_tag):"r"((a)));
  return 0;
}

