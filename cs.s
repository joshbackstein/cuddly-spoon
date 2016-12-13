.set STDOUT, 1

@ For getting the file size.
.set STAT, 106

.set EXIT, 1
.set WRITE, 4
.set MMAP2, 192
.set MUNMAP, 91

.set PROC_READ, 1
.set PROC_WRITE, 2

.set MAP_PRIVATE, 2
.set MAP_ANONYMOUS, 32


.data
.balign 4
pointer:
	.word 0
.balign 4
length:
	.word 4096
.balign 4
filename:
  @.asciz "/home/pi/cuddly-spoon/output.dat"
  @ output.dat can be created by running:
  @   touch output.dat
  @   truncate -s <file size in bytes> output.dat
  @ For testing differnt file sizes, this might be nice.
  .asciz "/home/pi/cuddly-spoon/tmp.txt"

@ Struct for stat is 88 bytes long.
.balign 4
statStruct:
  .skip 88
@ Reference the file size within the struct.
.set fileSize, statStruct+20


.text
.global _start
_start:
  push {lr}
  bl main

main:
  @ Get the file size.
  mov r7, #STAT
  ldr r0, =filename
  ldr r1, =statStruct
  svc #0
  @ Store it in r4.
  @ldr r4, =statStruct + 20
  ldr r4, =fileSize
  ldr r4, [r4]

  @ Map the file to memory.
  mov r7, #MMAP2
  /*
	mov r7, #MMAP2
	mov r0, #0
	mov r1, #4096
	mov r2, #(PROC_READ | PROC_WRITE)
	mov r3, #(MAP_PRIVATE | MAP_ANONYMOUS)
	mov r4, #-1
	mov r5, #0
	svc #0
	ldr r1, =pointer
	str r0, [r1]

	mov r4, r0
  ldr r0, [r1]


.Loop:
	strb r0, [r4], #1
	add r0, r0, #1

.Loop_condition:
	cmp r0, #('z' + 1)
	blt .Loop

	mov r0, #STDOUT
	ldr r1, =pointer
	ldr r1, [r1]
	sub r2, r4, r1
	mov r7, #WRITE
	svc #0

	mov r7, #MUNMAP
	ldr r0, =pointer
	ldr r0, [r0]
	ldr r1, =length
	ldr r1, [r1]
	svc #0
  */

  pop {lr}
	mov r7, #EXIT
	svc #0
