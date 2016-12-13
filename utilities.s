.include "syscalls.asmh"
.text
.global svcExit
.global gccExit

svcExit:
mov r7, #EXIT
svc #0

gccExit:
pop {pc}
