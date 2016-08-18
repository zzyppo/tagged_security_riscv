// A hello world stack ret adress attack program

#include <stdio.h>
#include <string.h>


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
int y = 4;
  y += var;
  long x[10];
  nix();
  x[12] =  &attack_sucessful;;
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
  return y;
}

int attackPartialCopy(int var)
{
  char test;
  int y = 4;
  y += var;
  long x[10];
  nix();
  //Assemble return adress out of valid return adress bytes
  test = (*(char*)(x + 12));
  *(((char*)(x + 12)) + 1) = test;
  *(((char*)(x + 12)) + 2) = test;
  return y;
}

#define write_csr(reg, val) \
  asm volatile ("csrw " #reg ", %0" :: "r"(val))

int main(int argc, char** argv, char** envp)
{
  long a[2];
  int test_tag = 0;
  int attack_mode = ATTACK_BYTE_WRITE;

  write_csr(0x800, 0x7); //Switch on the checks

  if(argc == 2)
  {
    if(!strcmp(argv[1], "off"))
      write_csr(0x800, 0x0); //Switch off the checks
  }

  printf("----------------------\n");
  printf("Chose Attack Mode: \n");
  printf("0: overwrite ra fully\n");
  printf("1: Byte write to ra\n");
  printf("2: partial copy create ra\n");

  scanf("%d", &attack_mode);

  printf("Try To perform RET attack!\n");

  switch(attack_mode)
  {
    case ATTACK_DOUBLE_WORD:
      attackDoubleWord(1111);
      break;

    case ATTACK_BYTE_WRITE:
      attackByteOverwrite(1111);
      break;

    case ATTACK_PARTIAL_COPY:
      attackPartialCopy(1111);
      break;

    default:
      printf("Unknown attack type\n");
  }

  printf("No attack performed\n");
  return 0;
}

