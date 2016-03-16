// A hello world program

#include <stdio.h>
#include "uart.h"
//A simple test
int main() {
long a[2];
int test_tag = 0;
  uart_init();
  uint8_t temp = 'F';
 uart_send(temp);
  //printf("H\n");
    asm volatile ("ltag %0, 0(%1)":"=r"(test_tag):"r"((a)));
    return 0;
}

