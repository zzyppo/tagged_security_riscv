#include "bbl.h"
#include "vm.h"
#include "driver/uart.h"
volatile int elf_loaded;

static void enter_entry_point()
{

    write_csr(mepc, current.entry);
     uart_send_string("Perform eret to linux\n");
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
   uart_send_string("supervisor init + mb done\n");
  elf_loaded = 1;
   uart_send_string("enter entry point\n");
  enter_entry_point();
}

void boot_other_hart()
{
  while (!elf_loaded)
    ;
  mb();
  enter_entry_point();
}
