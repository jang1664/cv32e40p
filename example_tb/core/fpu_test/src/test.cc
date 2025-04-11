#include <stdio.h>
#include <stdlib.h>

int main(int argc, char *argv[]) {
  int a=1;
  int b=2;
  int c = a + b;
  float d = (float)c + 1.0f;
  printf("Hello World\n");
  printf("%f\n", d);
  return 0;
}