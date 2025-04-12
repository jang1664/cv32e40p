#include <stdio.h>
#include <stdlib.h>

int main(int argc, char *argv[]) {
  int a=(1<<16) + 1;
  int b=(2<<16) + 2;
  int c=(3<<16) + 3;
  float d = (float)c + 1.0f;

  __asm__ volatile (
    "set_addr_cfg.0 %0, %1, %2"
    :
    : "r"(a), "r"(b), "r"(c)
    : "memory"
  );

  __asm__ volatile (
    "set_addr_cfg.1 %0, %1, %2"
    :
    : "r"(a), "r"(b), "r"(c)
    : "memory"
  );

  __asm__ volatile (
    "set_addr_cfg.2 %0, %1, %2"
    :
    : "r"(a), "r"(b), "r"(c)
    : "memory"
  );

  __asm__ volatile (
    "set_cood_cfg.0 %0, %1, %2"
    :
    : "r"(a), "r"(b), "r"(c)
    : "memory"
  );

  __asm__ volatile (
    "set_cood_cfg.1 %0, %1, %2"
    :
    : "r"(a), "r"(b), "r"(c)
    : "memory"
  );

  __asm__ volatile (
    "set_cood_cfg.2 %0, %1, %2"
    :
    : "r"(a), "r"(b), "r"(c)
    : "memory"
  );

  __asm__ volatile (
    "bge %0, %0, 8"
    :
    : "r"(a)
  );

  __asm__ volatile (
    "wait_sync 3"
    :
    :
    : "memory"
  );

  __asm__ volatile (
    "set_sync 3"
    :
    :
    : "memory"
  );

  __asm__ volatile (
    "vmask_set %0"
    :
    : "r"(a)
    : "memory"
  );

  printf("Finished\n");

  return 0;
}