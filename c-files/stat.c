#include <stdio.h>
#include <sys/stat.h>
int main() {
  printf("%d\n", sizeof(struct stat));
  return 0;
}
