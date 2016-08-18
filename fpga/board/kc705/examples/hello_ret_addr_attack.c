// A hello world stack ret adress attack program

#include <stdio.h>
#include <string.h>
//#include "uart.h"
/*
extern void asm_set_tagctrl(long tag_ctrl);

#define SYS_soft_reset 617
#define SYS_set_tagctrl 0x3100
extern long syscall(long num, long arg0, long arg1, long arg2);
*/

#define ATTACK_DOUBLE_WORD 0
#define ATTACK_BYTE_WRITE 1
#define ATTACK_PARTIAL_COPY 2



void attack_sucessful()
{
  printf("Attack Sucessful!\n");
 return;
}

void nix()
{
  int x = 5;
}

int attackDoubleWord(int var)
{
  //char test[2];
  //test[0] = 0xdE;
  //test[1] = 0xBF;
int y = 4;
  y += var;
  long x[10];
  nix();
  x[12] =  (0xdeadbeef);
 // memcpy(x + 12, test, sizeof(char) * 2);
  //x[12] =  bla;

 // x[12] =  &attack_sucessful;

  return y;
}


int attackByteOverwrite(int var)
{
  char test[2];
  test[0] = 0xdE;
  test[1] = 0xBF;
  int y = 4;
  y += var;
  long x[10];
  nix();
  //Bytewise overwrite the return address -> Trap shall trigger
  (*(char*)(x + 12)) = test[0];
  //memcpy(x + 12, test, sizeof(char) * 2);
  return y;
}

int attackPartialCopy(int var)
{
  char test;
  int y = 4;
  y += var;
  long x[10];
  nix();
  asm volatile ("stag %0, 0(%1)" ::"r"(0xF), "r"(x+12));
  //Assemble return adress out of valid return adress bytes
  test = (*(char*)(x + 12));
  *(((char*)(x + 12)) + 1) = test;
  *(((char*)(x + 12)) + 2) = test;
  return y;
}

#define write_csr(reg, val) \
  asm volatile ("csrw " #reg ", %0" :: "r"(val))

int main() {
  long a[2];
  int test_tag = 0;

  int attack_mode = ATTACK_BYTE_WRITE;



  write_csr(0x800, 7);

  switch(attack_mode)
  {
    case ATTACK_DOUBLE_WORD:
      asm volatile ("ltag %0, 0(%1)":"=r"(test_tag):"r"((a)));
      attackDoubleWord(1111);
      break;

    case ATTACK_BYTE_WRITE:
      asm volatile ("ltag %0, 0(%1)":"=r"(test_tag):"r"((a)));
      attackByteOverwrite(1111);
      break;

    case ATTACK_PARTIAL_COPY:
      asm volatile ("ltag %0, 0(%1)":"=r"(test_tag):"r"((a)));
      attackPartialCopy(1111);
      break;
  }


  asm volatile ("ltag %0, 0(%1)":"=r"(test_tag):"r"((a)));
  return 0;
}

