// A hello world stack ret adress attack program

#include <stdio.h>
#include "uart.h"

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
//  uart_init();
  //printf("Hello World!\n");
  test(1111);
  asm volatile ("ltag %0, 0(%1)":"=r"(test_tag):"r"((a)));
  return 0;
}

