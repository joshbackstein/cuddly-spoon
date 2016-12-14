@ Include system calls.
.include "syscalls.asmh"

@ For opening and closing a file descriptor for the file.
.set O_RDWR, 2

@ For mapping the file to memory.
.set PROC_READ, 1
.set PROC_WRITE, 2
.set MAP_SHARED, 1

@ For reading and writing from and to the console.
.set STDIN, 0
.set STDOUT, 1


.data
@ Message for prompting for file name.
.balign 4
filenamePrompt:
  .asciz "Please enter the name of the file you'd like to convert: "

.balign 4
fileSizeLabel:
  .asciz "File size: "

.balign 4
endl:
  .asciz "\n"

@ Path to file to access.
.balign 4
filename:
  .skip 256
.balign 4
filenameLength:
  .word 256

@ The file descriptor. We want this so we can close it when we're done.
.balign 4
fileDescriptor:
  .word 0

@ Struct for stat is 88 bytes long.
.balign 4
statStruct:
  .skip 88
@ Reference the file size within the struct.
.set fileSize, statStruct+20

@ Pointer to the file in memory.
.balign 4
filePointer:
	.word 0
@ Pointer to the first byte past the end of the file.
.balign 4
fileEnd:
  .word 0

@ Message to let us know we're done.
.balign 4
doneMessage:
  .ascii "Done.\n"
.set doneMessageLength, . -doneMessage


.text
.global _start
_start:
  push {lr}
  bl main

main:
PromptFilename:
  ldr r0, =filenamePrompt
  bl printString

GetFilename:
  mov r7, #READ
  mov r0, #STDIN
  ldr r1, =filename
  ldr r2, =filenameLength
  ldr r2, [r2]
  svc #0
  @ Terminate string with null character.
  @ The read() system call returns the length of the input in r0.
  ldr r2, =filenameLength
  @ Upon pressing enter, the line feed character is the last character,
  @ so we want to trim it off of the end the string.
  sub r0, #1
  str r0, [r2]
  @ Store the pointer to the end of the string in r1.
  ldr r1, =filename
  add r1, r0
  @ Put a null character at the end of the string.
  mov r0, #0
  strb r0, [r1]

GetFileSize:
  @ Get the file size.
  mov r7, #STAT
  ldr r0, =filename
  ldr r1, =statStruct
  svc #0

PrintFileSize:
  ldr r0, =fileSizeLabel
  bl printString
  ldr r0, =fileSize
  ldr r0, [r0]
  bl printUInt
  ldr r0, =endl
  bl printString

GetFileDescriptor:
  @ Get file descriptor.
  mov r7, #OPEN
  ldr r0, =filename
  mov r1, #(O_RDWR)
  svc #0
  @ Store it in memory.
  ldr r1, =fileDescriptor
  str r0, [r1]

MapFileToMemory:
  @ Map the file to memory.
  mov r7, #MMAP2
  @ Fill in arguments.
  @ addr
  mov r0, #0
  @ length
  ldr r1, =fileSize
  ldr r1, [r1]
  @ memory protection
  mov r2, #(PROC_READ | PROC_WRITE)
  @ mapping options and flags
  mov r3, #(MAP_SHARED)
  @ file descriptor
  ldr r4, =fileDescriptor
  ldr r4, [r4]
  @ offset - must be a multiple of the page size
  mov r5, #0
  svc #0
  @ Store pointer to memory where file is mapped.
  ldr r1, =filePointer
  str r0, [r1]
  @ Store pointer to first byte past the end of the file.
  ldr r1, =fileSize
  ldr r1, [r1]
  add r0, r1
  ldr r1, =fileEnd
  str r0, [r1]

FindOffset:
  @ Get pointer to the beginning of the bitmap array.
  ldr r5, =filePointer
  ldr r5, [r5]
  @ 0xA contains the offset for where the bitmap array begins. 
  add r0, r5, #0xA
  ldr r0, [r0]
  @ Move our pointer to the beginning of the bitmap array.
  add r5, r0
  @ Get the first byte past the end of the file so we know
  @ how far to go.
  ldr r6, =fileEnd
  ldr r6, [r6]

LoopSetup:
  @ Set length in FPSCR to allow vector math on 3 registers.
  @ FPSCR length counts from 0 up, where 0 == 1.
  mov r0, #2
  bl setVFPLEN

LoopRun:
  @ Start looping through the values. They are stored as BGR.
  @ Load blue.
  ldrb r2, [r5]
  @ Load green.
  ldrb r1, [r5, #1]
  @ Load red.
  ldrb r0, [r5, #2]

  @ Convert to grayscale.
  bl convert
  strb r0, [r5], #1
  strb r0, [r5], #1
  strb r0, [r5], #1

  @ Have we reached the end of the file?
  cmp r5, r6
  @ If the address stored in r5 is less than the address in r6,
  @ we haven't reached the end of the file yet.
  blt LoopRun
  
LoopTeardown:
  @ Put length in FPSCR back to length of 1.
  @ FPSCR length counts from 0 up, where 0 == 1.
  mov r0, #0
  bl setVFPLEN

WriteChangesToFile:
  @ Write any changes to the file.
  mov r7, #WRITE
  @ file descriptor
  ldr r0, =fileDescriptor
  ldr r0, [r0]
  @ file pointer
  ldr r1, =filePointer
  ldr r1, [r1]
  @ length
  ldr r2, =fileSize
  ldr r2, [r2]
  svc #0

UnmapFileFromMemory:
  @ Unmap file from memory.
  mov r7, #MUNMAP
  ldr r0, =filePointer
  ldr r0, [r0]
  ldr r1, =fileSize
  ldr r1, [r1]
  svc #0

CloseFile:
  @ Close the file descriptor.
  mov r7, #CLOSE
  ldr r0, =fileDescriptor
  ldr r0, [r0]
  svc #0

ShowDoneMessage:
  mov r7, #WRITE
  mov r0, #STDOUT
  ldr r1, =doneMessage
  mov r2, #doneMessageLength
  svc #0

exit:
  pop {lr}
	mov r7, #EXIT
  mov r0, #0
	svc #0
