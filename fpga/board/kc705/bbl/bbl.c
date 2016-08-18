#include "bbl.h"
#include "vm.h"
#include "driver/uart.h"
volatile int elf_loaded;

static void enter_entry_point()
{

    //long tag_reg = 0x0;
    write_csr(mepc, current.entry);
    write_csr(0x800, 0x7); //IO incalid tag generation and both checks on
    uart_send_string("Start Linux\n");
    asm volatile("eret");
    __builtin_unreachable();
}

void run_loaded_program()
{

 uart_send_string("Running loaded program\n");
  if (!current.is_supervisor)
    panic("bbl can't run user binaries");

  supervisor_vm_init();
  mb();
  elf_loaded = 1;
  enter_entry_point();
}

void boot_other_hart()
{
  while (!elf_loaded)
    ;
  mb();
  enter_entry_point();
}
