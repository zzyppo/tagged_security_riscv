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
  unsigned long waddr = 0;
  unsigned long raddr = 0;
  unsigned long long wkey = 0;
  unsigned long long rkey = 0;
  unsigned int i = 0;
  unsigned int error_cnt = 0;
  unsigned distance = 0;

 // uart_init();
  //printf("Memory RW test program.\n");

  for(i = 0; i < 300; i++)
  { 
     array[i] = i + 0xFFBB0000;
  }

  for(i = 0; i < 300; i++)
  { 
     if(array[i] != (i + 0xFFBB0000))
	{
	  return -1;
	}
  }

  return 0;

}

