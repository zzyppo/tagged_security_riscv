// See LICENSE for license details.

#include <stdio.h>
#include "diskio.h"
#include "ff.h"
#include "uart.h"
#include "elf.h"
#include "memory.h"
#include "spi.h"

FATFS FatFs;   /* Work area (file system object) for logical drive */

// 4K size read burst
#define SD_READ_SIZE 4096

#define SYS_soft_reset 617
#define SYS_set_iobase 0x12200
#define SYS_set_membase 0x2100
#define SYS_set_tagctrl 0x3100

#define write_csr(reg, val) \
  asm volatile ("csrw " #reg ", %0" :: "r"(val))

extern long syscall(long num, long arg0, long arg1, long arg2);

int main (void)
{
  FIL fil;                /* File object */
  FRESULT fr;             /* FatFs return code */
  uint8_t *boot_file_buf = (uint8_t *)(get_ddr_base()) + 0x38000000; // 0x8000000 (128M)
  uint8_t *memory_base = (uint8_t *)(get_ddr_base());

  //Modify tag control register (testing purpose)
  write_csr(0x400,3); //Checks on / io invalid tag generation off

  // map DDR3 to IO
  syscall(SYS_set_membase, 0x0, 0x3fffffff, 0x0); /* BRAM, 0x00000000 - 0x3fffffff */
  syscall(SYS_set_membase+5, 0, 0, 0);            /* update memory space */

  syscall(SYS_set_iobase, 0x80000000, 0x7fffffff, 0);   /* IO devices, 0x80000000 - 0xffffffff */
  syscall(SYS_set_iobase+1, 0x40000000, 0x3fffffff, 0); /* DDR3, 0x40000000 - 0x7fffffff */
  syscall(SYS_set_iobase+5, 0, 0, 0);                   /* update io space */

  uart_init();

  printf("lowRISC boot program\n=====================================\n");


  //Dram output of tag partition
 /*
  printf("Content of Tag Partition\n");
  for (uint32_t i = 0x7c000000; i < 0x7fffffff; i++)
       printf("%x,", (*(uint8_t*)i));
  printf("\n");
*/

 //Delete Tag partition
 printf("Formatting Tag partition in DRAM\n");
 unsigned long waddr = 0;
 for (waddr = 0x0; waddr < 0x3fffff; waddr++)
    *(((uint64_t *)0x7C000000) + waddr) = 0x0;


 //REMOVE
 //asm volatile ("ltag %0, 0(%1)":"=r"(debug_tag):"r"((&memory_base)));
/*
  uint8_t dat[10];
  //for(int i=0; i<1; i++)
    boot_file_buf[0] = *(((uint64_t *)0x80010000));
  load_elf(memory_base, boot_file_buf, 2);
    dat[0] = 5;

  memset(*((uint64_t *)0x40000000), 0, 20);

  while(1);
*/
  /* Register work area to the default drive */
  if(f_mount(&FatFs, "", 1)) {
    printf("Fail to mount SD driver!\n");
    return 1;
  }

  /* Open a text file */
  printf("Load boot into memory\n");
  fr = f_open(&fil, "boot", FA_READ);
  if (fr) {
    printf("Failed to open boot!\n");
    return (int)fr;
  }

  /* Read file into memory */
  uint8_t *buf = boot_file_buf;
    //TAG DEBUG
   // long tag_debug[2];
    int debug_tag = 0;
    asm volatile ("ltag %0, 0(%1)":"=r"(debug_tag):"r"((memory_base)));
    printf("Tag memory base %x\n", debug_tag);
    asm volatile ("ltag %0, 0(%1)":"=r"(debug_tag):"r"((boot_file_buf)));
    printf("Tag boot_file_buf %x\n", debug_tag);

  uint32_t br;                  /* Read count */
  do {
    fr = f_read(&fil, buf, SD_READ_SIZE, &br);  /* Read a chunk of source file */
    buf += br;
  } while(!(fr || br == 0));

  printf("Load %0x bytes to memory.\n", fil.fsize);


  asm volatile ("ltag %0, 0(%1)":"=r"(debug_tag):"r"((&memory_base)));
  printf("Tag memory base %x\n", debug_tag);
  asm volatile ("ltag %0, 0(%1)":"=r"(debug_tag):"r"((&boot_file_buf)));
  printf("Tag boot_file_buf %x\n", debug_tag);
    asm volatile ("ltag %0, 0(%1)":"=r"(debug_tag):"r"(&(fil.fsize)));
    printf("Tag fil.fsize %x\n", debug_tag);

   //  asm volatile ("ltag %0, 0(%1)":"=r"(debug_tag):"r"(&(fil.fsize)));
     debug_tag = 0;
     asm volatile ("stag %0, 0(%1)" ::"r"(debug_tag), "r"(&(fil.fsize)));

         asm volatile ("ltag %0, 0(%1)":"=r"(debug_tag):"r"(&(fil.fsize)));
         printf("Tag fil.fsize %x\n", debug_tag);


  /* read elf */
  printf("Read boot and load elf to DDR memory\n");
  if(br = load_elf(memory_base, boot_file_buf, fil.fsize))
    printf("elf read failed with code %0d", br);


  /* Close the file */
  if(f_close(&fil)) {
    printf("fail to close file!");
    return 1;
  }
  if(f_mount(NULL, "", 1)) {         /* unmount it */
    printf("fail to umount disk!");
    return 1;
  }

  spi_disable();


  // remap DDR3 to memory space
  syscall(SYS_set_membase, 0x0, 0x7fffffff, 0x0); /* BRAM, 0x00000000 - 0x3fffffff */
  syscall(SYS_set_membase+5, 0, 0, 0);            /* update memory space */

  syscall(SYS_set_iobase, 0x80000000, 0x7fffffff, 0); /* IO devices, 0x80000000 - 0xffffffff */
  syscall(SYS_set_iobase+1, 0, 0, 0);                 /* clear prevvious mapping */
  syscall(SYS_set_iobase+5, 0, 0, 0);                 /* update io space */


  printf("Boot the loaded program...\n");
  // map DDR3 to address 0
  syscall(SYS_set_membase, 0x0, 0x3fffffff, 0x40000000); /* map DDR to 0x0 */
  syscall(SYS_soft_reset, 0, 0, 0);                      /* soft reset */

}
