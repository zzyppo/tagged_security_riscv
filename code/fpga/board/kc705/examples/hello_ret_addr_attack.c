// A hello world program

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
//  uart_init();
  //printf("Hello World!\n");
  test(1111);
  return 0;
}

