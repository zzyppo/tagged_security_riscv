// A hello world program

#include <stdio.h>
#include "uart.h"
//A simple test
int main() {
  uart_init();
  printf("Hello World!\n");
}

