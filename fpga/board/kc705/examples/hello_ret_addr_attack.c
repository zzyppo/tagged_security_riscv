// A hello world stack ret adress attack program

#include <stdio.h>
//#include "uart.h"
/*
extern void asm_set_tagctrl(long tag_ctrl);

#define SYS_soft_reset 617
#define SYS_set_tagctrl 0x3100
extern long syscall(long num, long arg0, long arg1, long arg2);
*/
void attack_sucessful()
{
  printf("Attack Sucessful!\n");
 return;
}

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
  //x[12] =  (0xdeadbeef);
  x[12] =  &attack_sucessful;

  return y;
}

#define write_csr(reg, val) \
  asm volatile ("csrw " #reg ", %0" :: "r"(val))

int main() {
  long a[2];
  int test_tag = 0;
  //printf("Try To perform RET attack!\n");
  asm volatile ("ltag %0, 0(%1)":"=r"(test_tag):"r"((a)));
 // write_csr(0x400, 3); //atack should be performed
  //asm_set_tagctrl(7);
  //syscall(SYS_soft_reset, 0, 0, 0);                      /* soft reset */
 //syscall(SYS_set_tagctrl, 0x0000001, 0x0, 0x0); //Switch on the tag control
  // syscall(SYS_set_tagctrl, 0x0000000, 0x0, 0x0); //Switch off the tag control
 // uart_init();
   //printf("Hello World!\n");
  test(1111);
  asm volatile ("ltag %0, 0(%1)":"=r"(test_tag):"r"((a)));
  return 0;
}

