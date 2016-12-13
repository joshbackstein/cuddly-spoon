AS = as
AS_FLAGS = -mfpu=vfpv4
CC = gcc
CC_FLAGS = -w -g

EXEC = grayscale 
SOURCES := $(wildcard *.s)
OBJECTS = $(SOURCES:.s=.o)

link: $(OBJECTS)
	ld -o $(EXEC) $(OBJECTS) 

%.o: %.s
	$(AS) $(AS_FLAGS) -c $< -o $@

clean:
	rm -f $(EXEC) $(OBJECTS)
