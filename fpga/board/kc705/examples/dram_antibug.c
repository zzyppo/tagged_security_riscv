// A dram test program

#include <stdio.h>
#include <stdlib.h>
#include "uart.h"
#include "memory.h"

volatile uint32_t *uart_base = (uint32_t *)(UART_BASE);
//#define IS_SIMULATION


unsigned long long lfsr64(unsigned long long d) {
  // x^64 + x^63 + x^61 + x^60 + 1

  unsigned long long bit =
    (d >> (64-64)) ^
    (d >> (64-63)) ^
    (d >> (64-61)) ^
    (d >> (64-60)) ^
    1;
  return (d >> 1) | (bit << 63);


  //return 0x1234567890ABCDEF;
}


#define STEP_SIZE 1024 / 8
//#define STEP_SIZE 32
//#define STEP_SIZE 1024*16
//#define VERIFY_DISTANCE 1
#define VERIFY_DISTANCE 16


int main() {
  unsigned long waddr = 0;
  unsigned long raddr = 0;
  unsigned long long wkey = 0x1111111111111111;
  unsigned long long rkey = 0x1111111111111111;
  unsigned int i = 0;
  unsigned int error_cnt = 0;
  unsigned distance = 0;
  unsigned char* error = "ERROR";
int temp = 0;
  long array[2];

#ifndef IS_SIMULATION
  uart_init();
  //printf("DRAM test program.\n");
  #endif

  long loop_cnt = 0;
  while(1) {
	loop_cnt++;
	#ifndef IS_SIMULATION
    //printf("Write block @%lx using key %llx\n", waddr, wkey);
    #endif

    for(i=0; i<STEP_SIZE; i++) {
      *(((uint64_t *)0x40000000) + waddr) = wkey;
       asm volatile ("stag %0, 0(%1)" ::"r"(wkey & 0xF), "r"((get_ddr_base() + waddr)));
      waddr = (waddr + 0x01) & 0x3ffffff;
      wkey = lfsr64(wkey);
	
    }

    if(distance < VERIFY_DISTANCE) distance++;

    if(distance == VERIFY_DISTANCE) {
  	//asm volatile ("ltag %0, 0(%1)":"=r"(temp):"r"(array));
     // printf("Check block @%lx \n", raddr);

      for(i=0; i<STEP_SIZE; i++) {
        unsigned long long rd = *(get_ddr_base() + raddr);
        unsigned int tag = 0;
         asm volatile ("ltag %0, 0(%1)":"=r"(tag):"r"((((uint64_t *)0x40000000) + raddr)));
        // printf("Tag is %llx, key is %llx\n", tag, rd );

        if((rkey != rd)) {
         printf("Error! key %llx stored @%lx does not match with %llx\n", rd, raddr, rkey);
	     printf("Error! i== %d\n", loop_cnt);


	        error_cnt++;
            exit(1);
        }

        if( (tag != (rkey & 0xF)))
        {
           printf("Error! tag %llx stored @%lx does not match with %llx\n", tag, raddr, (rkey & 0x0F));
           printf("Error! i== %d\n", loop_cnt);
            error_cnt++;
          exit(1);
        }
        raddr = (raddr + 0x01) & 0x3ffffff;
        rkey = lfsr64(rkey);
      }
    }
  }
}

