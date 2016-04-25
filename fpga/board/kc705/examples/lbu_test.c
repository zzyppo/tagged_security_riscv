// A hello world stack ret adress attack program

#include <stdio.h>
//#include "uart.h"
/*
extern void asm_set_tagctrl(long tag_ctrl);

#define SYS_soft_reset 617
#define SYS_set_tagctrl 0x3100
extern long syscall(long num, long arg0, long arg1, long arg2);
*/

int used = 0;
char buffer[100];


typedef struct {
  unsigned long dev;
  unsigned long cmd;
  unsigned long data;
  unsigned long sbi_private_data;
} sbi_device_message;

//__attribute__((always_inline)) 
__attribute__((always_inline)) static int test_func(unsigned char ch)
{
   int test_tag = 0;
   unsigned long temp = 0;
   temp = ch;
   *(buffer + used) = ch;
   used++;
   asm volatile ("ltag %0, 0(%1)":"=r"(test_tag):"r"((&temp)));

   if(used == 100)
     used = 0;
   return 0;
}

void transmitt(sbi_device_message* msg)
{
   test_func(msg->data);
  
}



#define write_csr(reg, val) \
  asm volatile ("csrw " #reg ", %0" :: "r"(val))

int main() {
  //long a[2];
  int test_tag = 0;
  unsigned long uart_data = 0;
  write_csr(0x400,0xF);

  sbi_device_message m;
  
 // uart_data = *(((unsigned long *)0x80000000));
   uart_data = 0x0f;
   asm volatile ("stag %0, 0(%1)" ::"r"(1), "r"(&uart_data));

  m.data = uart_data;
 
  asm volatile ("ltag %0, 0(%1)":"=r"(test_tag):"r"((&(m.data))));

   int bla = 0x12;
  char test1 = 0xa;
  char test2 = 0xb;
  char test3 = 0xc;
 
  while(1)
    transmitt(&m);
  
  return 0;
}

