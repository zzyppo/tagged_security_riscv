// A dram test program

#include <stdio.h>
#include <stdlib.h>
#include "uart.h"
#include "memory.h"

volatile uint32_t *uart_base = (uint32_t *)(UART_BASE);
//#define IS_SIMULATION

void printBuffer(unsigned char* buffer, unsigned int len)
{
  int i = 0;
  for(i = 0; i < len; i++)
  {
   while(! (*(uart_base + UART_LSR) & 0x40u));
    *(uart_base + UART_THR) = buffer[i];
  }


}


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

#define STEP_SIZE 32
//#define STEP_SIZE 1024*16
#define VERIFY_DISTANCE 16
//#define VERIFY_DISTANCE 16


int main() {
  unsigned long waddr = 0;
  unsigned long raddr = 0;
  unsigned long long wkey = 0;
  unsigned long long rkey = 0;
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
  //waddr = 0xb0;
  //raddr = 0xb0;
  while(1) {
	loop_cnt++;
    //wkey = lfsr64(wkey);
    //rkey = lfsr64(rkey);
	#ifndef IS_SIMULATION
    //printf("Write block @%lx using key %llx\n", waddr, wkey);
    #endif

    for(i=0; i<STEP_SIZE; i++) {
      *(get_ddr_base() + waddr) = wkey;
      waddr = (waddr + 0x1) & 0x3ffffff;
      wkey = lfsr64(wkey);
    }
    
    if(distance < VERIFY_DISTANCE) distance++;

    if(distance == VERIFY_DISTANCE) {
  	asm volatile ("ltag %0, 0(%1)":"=r"(temp):"r"(array));
  	#ifndef IS_SIMULATION
       // while(! (*(uart_base + UART_LSR) & 0x40u));
       // *(uart_base + UART_THR) = 'Y';
      //printf("Check block @%lx \n", raddr);
      printf("Z\n");
      #endif

      for(i=0; i<STEP_SIZE; i++) {
        unsigned long long rd = *(get_ddr_base() + raddr);
        //printf("rd %llx\n", rd);
        if(rkey != rd) {
        asm volatile ("ltag %0, 0(%1)":"=r"(temp):"r"(array));
        #ifdef IS_SIMULATION
            asm volatile ("ltag %0, 0(%1)":"=r"(temp):"r"(array));
	        uart_init();
	        printf("Error! key %llx stored @%lx does not match with %llx\n", rd, raddr, rkey);
	    #endif
        #ifndef IS_SIMULATION
            printBuffer(error, sizeof(error));
	        //printf("Error! i== %d\n", loop_cnt);

            //*(uart_base + UART_THR) = (uint8_t)loop_cnt;
	        //while(1);
	    #endif
	        error_cnt++;
            exit(1);
        }
        raddr = (raddr + 0x1) & 0x3ffffff;
        rkey = lfsr64(rkey);
        if(error_cnt > 10) exit(1);
      }
    }
   //if(loop_cnt == 20)  
   //{
     // uart_init();
     //    printf("Tests Done\n");
    //  exit(0);
   //}
  }
}

