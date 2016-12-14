#include <stdio.h>
#include <sys/types.h>
#include <sys/stat.h>
#include <fcntl.h>
int main() {
  int fd = open("test.txt", O_RDWR);
  printf("fd = %d\n", fd);
  printf("O_RDONLY = %d\n", O_RDONLY);
  printf("O_WRONLY = %d\n", O_WRONLY);
  printf("O_RDWR = %d\n", O_RDWR);
  close(fd);
  return 0;
}

