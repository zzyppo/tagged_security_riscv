// A dram test program

#include <stdio.h>
#include <stdlib.h>
#include "uart.h"

unsigned long long lfsr64(unsigned long long d) {
  // x^64 + x^63 + x^61 + x^60 + 1
  unsigned long long bit = 
    (d >> (64-64)) ^
    (d >> (64-63)) ^
    (d >> (64-61)) ^
    (d >> (64-60)) ^
    1;
  return (d >> 1) | (bit << 63);
}

//Test
//#define STEP_SIZE 4
#define STEP_SIZE 1024*16
//#define VERIFY_DISTANCE 2
#define VERIFY_DISTANCE 16

long array[600];

int main() {
  unsigned int i = 0;
int temp = 0;
  asm volatile ("ltag %0, 0(%1)":"=r"(temp):"r"(array));
 // uart_init();
  //printf("Memory RW test program.\n");

  for(i = 0; i < 300; i++)
  { 
     array[i] = i + 0x11110000;
  }
  asm volatile ("ltag %0, 0(%1)":"=r"(temp):"r"(array));

  for(i = 0; i < 300; i++)
  { 
     if(array[i] != (i + 0x11110000))
	{
	  return -1;
	}
  }
  asm volatile ("ltag %0, 0(%1)":"=r"(temp):"r"(array));

  return 0;

}

