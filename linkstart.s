.text
.global _start
_start:
mov r0, #2
bl setVFPLEN

mov r0, #0xFF
mov r1, #0x0
mov r2, #0x0
bl loadPixelToVFP
bl convert

bl loadPixelFromVFP

mov r0, #0
bl setVFPLEN
bl svcExit
