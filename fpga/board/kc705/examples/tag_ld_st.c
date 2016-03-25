// See LICENSE for license details.

#include <stdio.h>
#include <stdlib.h>
#include "memory.h"

#define VECT_SIZE 1<<10
#define TAG_WIDTH 4

int main() {
  long a[VECT_SIZE];
  long i;
  printf("Tag load and store tests starts.\n");
  for(i=0; i<VECT_SIZE; i++) {
    *(a+i) = rand();
   asm volatile ("stag %0, 0(%1)" ::"r"(*(a+i)), "r"((a+i)));
  }
  
  for(i=0; i<VECT_SIZE; i++) {
    int value = *(a+i);
    int tag;
    asm volatile ("ltag %0, 0(%1)":"=r"(tag):"r"((a+i)));
  //  int tag = load_tag(a+i);
    if((value % (1 << TAG_WIDTH)) != tag) {
    printf("Error! Wrong tag readed from a[%d], expecting %x but read %x\n",
          i, value % (1 << TAG_WIDTH), tag);
    return -1;
    }
  }
  printf("Tag load and store tests passed.\n");
return 0;
}
