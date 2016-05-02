// A hello world stack ret adress attack program

#include <stdio.h>
#include <string.h>
#include "uart.h"
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

void foo()
{
  int x = 5;
}

int test(int var)
{
  int y = 4;
  y += var;
  long x[10];
  foo();
  x[12] =  &attack_sucessful;

  return y;
}

#define write_csr(reg, val) \
  asm volatile ("csrw " #reg ", %0" :: "r"(val))

int main() {
  long a[2];
  uart_init();
  printf("Try To perform RET attack!\n");
  write_csr(0x400, 7); //atack should be performed
  test(1111);
  printf("No attack performed\n");
  return 0;
}


